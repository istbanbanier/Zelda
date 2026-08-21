#!/usr/bin/env python3
"""Deux verdicts SÉPARÉS sur le rapport de fuite de fin de processus de Godot.

Pourquoi deux et pas un
-----------------------
`validate_fast.sh` traitait « ObjectDB instances were leaked » et « resources
still in use » comme un seul motif rouge. Ce motif mélangeait deux propriétés
qui ne se mesurent pas de la même façon :

  * une ressource du PROJET (matériau, maillage, texture, flux audio, scène)
    qui survit est un défaut que nous pouvons corriger, et qui doit bloquer ;
  * un `GDScript` retenu par le cache de scripts du MOTEUR n'est pas corrigible
    depuis GDScript — aucune API ne purge `GDScriptCache`. Le confondre avec le
    premier revenait à porter un rouge permanent que personne ne peut lever,
    donc à entraîner l'équipe à ignorer la ligne rouge.

Décision du lead (directive de clôture R2B.3.1) : séparer les deux domaines.

  PORTAIL A — PROJECT_RESOURCE_LEAK_GATE ......... BLOQUANT
  TÉLÉMÉTRIE B — ENGINE_SCRIPT_CACHE_TELEMETRY ... WARN, tant qu'elle ne dérive pas

Ce n'est PAS une baisse de seuil : le portail A est STRICTEMENT PLUS SÉVÈRE que
l'ancien motif. L'ancien ne regardait que deux comptes agrégés ; celui-ci exige
l'énumération classe par classe et chemin par chemin, et rougit sur toute classe
non expliquée. La télémétrie B, elle, redevient bloquante à la moindre dérive.

Le principe est une LISTE BLANCHE : tout ce qui n'est pas explicitement attribué
au moteur appartient au projet, donc rougit. Un nouveau type de fuite est rouge
par défaut, jamais silencieux par oubli.

Aucune ligne brute du moteur n'est masquée : l'appelant continue de les
imprimer. Cet outil CLASSE, il ne filtre pas.

Codes retour
------------
  0  portail A vert ET télémétrie dans son enveloppe connue
  1  portail A ROUGE — une ressource du projet survit, ou l'ensemble mesuré
     diffère de l'ensemble expliqué
  2  portail A vert mais télémétrie B EN DÉRIVE — redevient bloquante
  3  BLOQUÉ — l'entrée ne permet pas de conclure (journal non `--verbose`)
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter

# --- Ce que le MOTEUR retient, et que GDScript ne peut pas libérer -----------
# `GDScript` et `GDScriptNativeClass` sont le cache de scripts du moteur : charger
# une `.tscn` épingle les scripts qu'elle attache. `Shader` n'est admis que s'il
# est DÉMONTRÉ comme constante `preload()` d'un script lui-même épinglé — voir
# `_justifier_shaders()`. Aucune classe n'est admise sans démonstration.
CLASSES_MOTEUR = frozenset({"GDScript", "GDScriptNativeClass"})
CLASSE_SHADER = "Shader"

# Extensions de ressource attribuables au cache de scripts.
EXT_SCRIPT = frozenset({".gd"})
EXT_SHADER = frozenset({".gdshader"})

# La seule classe de RID qu'un résidu de scripts peut produire sous `--headless` :
# un `Shader` vivant tient un RID `DummyShader` dans le serveur de rendu factice.
# Toute AUTRE classe de RID signale une ressource du projet — donc rouge.
RID_MOTEUR = frozenset({"DummyShader"})

RE_INSTANCE = re.compile(r"Leaked instance:\s*([A-Za-z_][A-Za-z0-9_]*):")
RE_RESSOURCE = re.compile(r"Resource still in use:\s*(\S+)")
RE_AGG_OBJETS = re.compile(r"(\d+)\s+ObjectDB instances were leaked")
RE_AGG_RESSOURCES = re.compile(r"(\d+)\s+resources still in use")
RE_AGG_RID = re.compile(r"(\d+)\s+RID allocations of type '([^']+)'")


def normaliser_classe_rid(brut: str) -> str:
    """Le moteur imprime le symbole C++ MANGLÉ, pas le nom lisible.

    Mesuré : la ligne réelle est
        RID allocations of type 'N13RendererDummy15MaterialStorage11DummyShaderE'
    et non `DummyShader`. Une première version de ce portail comparait le nom
    brut au contrat et déclarait ROUGE une signature parfaitement conforme —
    faux positif attrapé par sa propre fixture avant d'atteindre quiconque.

    Décodage Itanium d'un nom imbriqué : `N` puis une suite de
    `<longueur><identifiant>` puis `E`. Le dernier identifiant est la classe.
    Un nom déjà lisible traverse inchangé.
    """
    if not brut.startswith("N") or not brut.endswith("E"):
        return brut
    # Décodage SÉQUENTIEL, par position. Une première version le faisait par
    # expression régulière `(\d+)([A-Za-z_][A-Za-z0-9_]*)` : la classe de
    # caractères contenant `0-9`, le premier identifiant avalait les longueurs
    # suivantes et il ne restait qu'un composant. Un décodeur de longueur
    # préfixée se lit caractère par caractère, pas par motif gourmand.
    composants: list[str] = []
    i = 1
    while i < len(brut) and brut[i] != "E":
        j = i
        while j < len(brut) and brut[j].isdigit():
            j += 1
        if j == i:
            break
        taille = int(brut[i:j])
        composants.append(brut[j:j + taille])
        i = j + taille
    return composants[-1] if composants else brut


def lire(chemin: str) -> str:
    if chemin == "-":
        return sys.stdin.read()
    with open(chemin, encoding="utf-8", errors="replace") as f:
        return f.read()


def _justifier_shaders(shaders: list[str], scripts: list[str], racine: str) -> tuple[list[str], list[str]]:
    """Un shader survivant n'est admis QUE s'il est constante `preload()` d'un
    script lui-même retenu. C'est la démonstration « conséquence, pas cause » :
    une constante vit dans la table de constantes de son script ; tant que le
    script est épinglé, elle l'est aussi, et aucune libération de cache n'y peut
    rien — un cache vide des variables, jamais des constantes.

    Rend (justifiés, non_justifiés).
    """
    retenus = {s for s in scripts}
    justifies: list[str] = []
    orphelins: list[str] = []
    for sh in shaders:
        porteur_trouve = ""
        for script in sorted(retenus):
            rel = script[len("res://"):] if script.startswith("res://") else script
            disque = os.path.join(racine, rel)
            if not os.path.isfile(disque):
                continue
            try:
                with open(disque, encoding="utf-8", errors="replace") as f:
                    source = f.read()
            except OSError:
                continue
            if 'preload("%s")' % sh in source or "preload('%s')" % sh in source:
                porteur_trouve = script
                break
        if porteur_trouve:
            justifies.append("%s  <- preload de %s" % (sh, porteur_trouve))
        else:
            orphelins.append(sh)
    return justifies, orphelins


def analyser(texte: str, racine: str) -> dict:
    classes = Counter(RE_INSTANCE.findall(texte))
    ressources = RE_RESSOURCE.findall(texte)
    agg_objets = [int(m) for m in RE_AGG_OBJETS.findall(texte)]
    agg_ressources = [int(m) for m in RE_AGG_RESSOURCES.findall(texte)]
    rids = {normaliser_classe_rid(classe): int(n)
            for n, classe in RE_AGG_RID.findall(texte)}
    return {
        "classes": classes,
        "ressources": ressources,
        "agg_objets": agg_objets[-1] if agg_objets else None,
        "agg_ressources": agg_ressources[-1] if agg_ressources else None,
        "rids": rids,
        "racine": racine,
    }


def verdict(mesure: dict, reference: dict | None) -> dict:
    classes: Counter = mesure["classes"]
    ressources: list[str] = mesure["ressources"]
    rids: dict = mesure["rids"]

    rouges_a: list[str] = []
    derives_b: list[str] = []

    # --- Séparation des ressources par extension -----------------------------
    scripts = [r for r in ressources if os.path.splitext(r)[1] in EXT_SCRIPT]
    shaders = [r for r in ressources if os.path.splitext(r)[1] in EXT_SHADER]
    projet_res = [r for r in ressources
                  if os.path.splitext(r)[1] not in EXT_SCRIPT | EXT_SHADER]

    # PORTAIL A — condition 1 : une ressource du projet survit.
    if projet_res:
        rouges_a.append(
            "%d ressource(s) du PROJET survivent : %s"
            % (len(projet_res), ", ".join(sorted(projet_res)[:12])))

    # PORTAIL A — condition 1 bis : une classe d'objet non attribuée au moteur.
    justifies, orphelins = _justifier_shaders(shaders, scripts, mesure["racine"])
    admises = set(CLASSES_MOTEUR)
    if shaders and not orphelins:
        admises.add(CLASSE_SHADER)
    inconnues = {c: n for c, n in classes.items() if c not in admises}
    if inconnues:
        rouges_a.append(
            "classe(s) d'objet non attribuée(s) au moteur : %s"
            % ", ".join("%s=%d" % (c, n) for c, n in sorted(inconnues.items())))
    if orphelins:
        rouges_a.append(
            "shader(s) survivant(s) qu'aucun script retenu ne charge par preload : %s"
            % ", ".join(sorted(orphelins)))

    # PORTAIL A — condition 2 : une nouvelle classe de RID apparaît.
    rid_inconnus = {c: n for c, n in rids.items() if c not in RID_MOTEUR}
    if rid_inconnus:
        rouges_a.append(
            "classe(s) de RID appartenant au projet : %s"
            % ", ".join("%s=%d" % (c, n) for c, n in sorted(rid_inconnus.items())))

    # PORTAIL A — condition 5 : l'ensemble mesuré diffère de l'ensemble expliqué.
    total_classes = sum(classes.values())
    if mesure["agg_objets"] is None or total_classes == 0:
        return {"bloque": 3, "rouges_a": [], "derives_b": [],
                "motif_bloque": "journal sans énumération par instance — relancer avec --verbose",
                "mesure": mesure, "justifies": [], "scripts": [], "shaders": []}
    if total_classes != mesure["agg_objets"]:
        rouges_a.append(
            "ensemble mesuré ≠ ensemble expliqué : %d objets annoncés, %d énumérés"
            % (mesure["agg_objets"], total_classes))
    if mesure["agg_ressources"] is not None and len(ressources) != mesure["agg_ressources"]:
        rouges_a.append(
            "ensemble mesuré ≠ ensemble expliqué : %d ressources annoncées, %d énumérées"
            % (mesure["agg_ressources"], len(ressources)))
    n_shader_objets = classes.get(CLASSE_SHADER, 0)
    n_rid_shader = rids.get("DummyShader", 0)
    if n_rid_shader != n_shader_objets:
        rouges_a.append(
            "ensemble mesuré ≠ ensemble expliqué : %d RID DummyShader pour %d objets Shader"
            % (n_rid_shader, n_shader_objets))

    # --- TÉLÉMÉTRIE B — dérive par rapport au contrat committé ---------------
    if reference is not None:
        ref_classes = reference.get("classes", {})
        for classe, n in sorted(classes.items()):
            attendu = int(ref_classes.get(classe, 0))
            if n > attendu:
                derives_b.append(
                    "croissance : %s = %d, contrat = %d" % (classe, n, attendu))
        for classe in sorted(set(ref_classes) - set(classes)):
            derives_b.append(
                "classe du contrat DISPARUE (amélioration à entériner) : %s" % classe)
        ref_ext = reference.get("extensions", {})
        mes_ext = {".gd": len(scripts), ".gdshader": len(shaders)}
        for ext, n in sorted(mes_ext.items()):
            attendu = int(ref_ext.get(ext, 0))
            if n > attendu:
                derives_b.append(
                    "croissance : %s = %d, contrat = %d" % (ext, n, attendu))
        ref_prov = set(reference.get("provenances", []))
        if ref_prov:
            prov = {"/".join(s[len("res://"):].split("/")[:2]) for s in scripts}
            nouvelles = prov - ref_prov
            if nouvelles:
                derives_b.append(
                    "provenance(s) nouvelle(s) : %s" % ", ".join(sorted(nouvelles)))

    return {
        "bloque": 0,
        "rouges_a": rouges_a,
        "derives_b": derives_b,
        "mesure": mesure,
        "justifies": justifies,
        "scripts": scripts,
        "shaders": shaders,
        "projet_res": projet_res,
    }


def verdict_agregat(mesure: dict, reference: dict | None) -> dict:
    """Juge la SIGNATURE AGRÉGÉE seule, et le dit.

    Pourquoi ce mode existe : énumérer objet par objet impose `--verbose`, mesuré
    à près du triple de la durée de la suite et 412 Mo de vidage. Un contrôle de
    ce prix à chaque passe finirait contourné. La signature agrégée, elle, coûte
    un `grep` — et elle est loin d'être faible : les comptes sont comparés AU
    CHIFFRE PRÈS au contrat committé, et toute classe de RID autre que celle du
    résidu moteur connu rougit. Une ressource du projet qui survivrait
    déplacerait forcément l'un de ces nombres.

    Ce que ce mode NE peut PAS voir, et qu'il annonce plutôt que de le taire :
    une substitution à somme nulle — un `GDScript` de moins et un matériau de
    plus. D'où `tools/gate_fuite_composition.sh`, qui énumère vraiment.
    """
    rouges: list[str] = []
    rids: dict = mesure["rids"]

    if reference is None:
        return {"bloque": 3,
                "motif_bloque": ("mode agrégat sans contrat de référence — "
                                 "rien à comparer, donc rien à conclure"),
                "rouges_a": [], "derives_b": [], "mesure": mesure,
                "justifies": [], "scripts": [], "shaders": [], "projet_res": []}

    attendu_objets = reference.get("total_objets")
    attendu_res = reference.get("total_ressources")
    attendu_rids = reference.get("rids", {})

    if mesure["agg_objets"] != attendu_objets:
        rouges.append("objets fuités = %s, contrat = %s"
                      % (mesure["agg_objets"], attendu_objets))
    if mesure["agg_ressources"] != attendu_res:
        rouges.append("ressources retenues = %s, contrat = %s"
                      % (mesure["agg_ressources"], attendu_res))
    for classe, n in sorted(rids.items()):
        if classe not in RID_MOTEUR:
            rouges.append("classe de RID appartenant au projet : %s=%d" % (classe, n))
        elif int(attendu_rids.get(classe, -1)) != n:
            rouges.append("RID %s = %d, contrat = %s"
                          % (classe, n, attendu_rids.get(classe, "absent")))
    for classe, n in sorted(attendu_rids.items()):
        if classe not in rids:
            rouges.append("classe de RID du contrat ABSENTE de la mesure : %s=%s "
                          "— si c'est une amélioration, entériner le contrat "
                          "plutôt que la laisser dériver sans trace"
                          % (classe, n))
    return {"bloque": 0, "rouges_a": rouges, "derives_b": [], "mesure": mesure,
            "justifies": [], "scripts": [], "shaders": [], "projet_res": []}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("journal", help="journal Godot --verbose, ou '-' pour stdin")
    ap.add_argument("--reference", default="",
                    help="contrat JSON de l'enveloppe connue du cache moteur")
    ap.add_argument("--racine", default=".", help="racine du dépôt")
    ap.add_argument("--ecrire-reference", default="",
                    help="écrit le contrat mesuré à ce chemin (ne juge pas)")
    ap.add_argument("--json", default="", help="écrit le verdict structuré à ce chemin")
    ap.add_argument("--mode", default="composition", choices=["composition", "agregat"],
                    help=("composition : exige l'énumération objet par objet (journal "
                          "--verbose). agregat : ne juge que la signature agrégée, et "
                          "DIT qu'il n'a pas vu la composition."))
    args = ap.parse_args()

    texte = lire(args.journal)
    mesure = analyser(texte, args.racine)
    reference = None
    if args.reference and os.path.isfile(args.reference):
        with open(args.reference, encoding="utf-8") as f:
            reference = json.load(f)

    if args.mode == "agregat":
        v = verdict_agregat(mesure, reference)
    else:
        v = verdict(mesure, reference)

    if v["bloque"] == 3:
        print("BLOQUÉ — %s" % v["motif_bloque"])
        return 3

    classes: Counter = mesure["classes"]
    if args.mode == "agregat":
        print("=== RÉSIDU DE FIN DE PROCESSUS — SIGNATURE AGRÉGÉE ===")
        print("  objets fuités       : %s   (contrat %s)"
              % (mesure["agg_objets"], (reference or {}).get("total_objets")))
        print("  ressources retenues : %s   (contrat %s)"
              % (mesure["agg_ressources"], (reference or {}).get("total_ressources")))
        for classe, n in sorted(mesure["rids"].items()):
            print("  RID %-20s %d" % (classe, n))
        print("  NON VÉRIFIÉ ICI : la composition objet par objet. Elle exige")
        print("                    --verbose (mesuré : ~3x la durée de la suite).")
        print("                    Commande dédiée : tools/gate_fuite_composition.sh")
        print()
        if v["rouges_a"]:
            print("PROJECT_RESOURCE_LEAK_GATE : ROUGE")
            for r in v["rouges_a"]:
                print("    * %s" % r)
        else:
            print("PROJECT_RESOURCE_LEAK_GATE : VERT sur la signature agrégée")
        if v["rouges_a"]:
            print("ENGINE_SCRIPT_CACHE_TELEMETRY : non jugée — le portail A rougit, "
                  "la signature n'est pas celle du contrat")
        else:
            print("ENGINE_SCRIPT_CACHE_TELEMETRY : WARN — RÉSIDU MOTEUR CONNU, "
                  "signature conforme au contrat")
        if args.json:
            with open(args.json, "w", encoding="utf-8") as f:
                json.dump({
                    "mode": "agregat",
                    "portail_a": "ROUGE" if v["rouges_a"] else "VERT",
                    "motifs_a": v["rouges_a"],
                    "telemetrie_b": "WARN",
                    "agg_objets": mesure["agg_objets"],
                    "agg_ressources": mesure["agg_ressources"],
                    "rids": mesure["rids"],
                    "composition_verifiee": False,
                }, f, ensure_ascii=False, indent=2, sort_keys=True)
                f.write("\n")
        return 1 if v["rouges_a"] else 0

    print("=== RÉSIDU DE FIN DE PROCESSUS — DÉCOMPOSITION BRUTE ===")
    print("  objets annoncés     : %s" % mesure["agg_objets"])
    print("  objets énumérés     : %d" % sum(classes.values()))
    for classe, n in sorted(classes.items(), key=lambda kv: -kv[1]):
        print("      %-24s %d" % (classe, n))
    print("  ressources annoncées: %s" % mesure["agg_ressources"])
    print("  ressources énumérées: %d  (%d .gd + %d .gdshader + %d autres)"
          % (len(mesure["ressources"]), len(v["scripts"]), len(v["shaders"]),
             len(v["projet_res"])))
    for classe, n in sorted(mesure["rids"].items()):
        print("  RID %-20s %d" % (classe, n))
    for j in v["justifies"]:
        print("  shader justifié     : %s" % j)

    if args.ecrire_reference:
        prov = sorted({"/".join(s[len("res://"):].split("/")[:2])
                       for s in v["scripts"]})
        contrat = {
            "doc": ("Enveloppe CONNUE du résidu de cache de scripts du moteur. "
                    "Mesurée, jamais devinée. Toute croissance rend la télémétrie "
                    "bloquante."),
            "classes": dict(classes),
            "extensions": {".gd": len(v["scripts"]), ".gdshader": len(v["shaders"])},
            "provenances": prov,
            "rids": mesure["rids"],
            "total_objets": mesure["agg_objets"],
            "total_ressources": mesure["agg_ressources"],
        }
        with open(args.ecrire_reference, "w", encoding="utf-8") as f:
            json.dump(contrat, f, ensure_ascii=False, indent=2, sort_keys=True)
            f.write("\n")
        print("\ncontrat écrit : %s" % args.ecrire_reference)

    print()
    if v["rouges_a"]:
        print("PROJECT_RESOURCE_LEAK_GATE : ROUGE")
        for r in v["rouges_a"]:
            print("    * %s" % r)
    else:
        print("PROJECT_RESOURCE_LEAK_GATE : VERT — aucune ressource du projet ne survit")

    if v["derives_b"]:
        print("ENGINE_SCRIPT_CACHE_TELEMETRY : DÉRIVE — redevient BLOQUANTE")
        for d in v["derives_b"]:
            print("    * %s" % d)
    elif reference is None:
        print("ENGINE_SCRIPT_CACHE_TELEMETRY : sans contrat de référence — non jugée")
    else:
        print("ENGINE_SCRIPT_CACHE_TELEMETRY : WARN — RÉSIDU MOTEUR CONNU ET STABLE")

    if args.json:
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump({
                "portail_a": "ROUGE" if v["rouges_a"] else "VERT",
                "motifs_a": v["rouges_a"],
                "telemetrie_b": ("DERIVE" if v["derives_b"]
                                 else ("NON_JUGEE" if reference is None else "WARN")),
                "motifs_b": v["derives_b"],
                "classes": dict(classes),
                "ressources_gd": len(v["scripts"]),
                "ressources_gdshader": len(v["shaders"]),
                "ressources_projet": v["projet_res"],
                "rids": mesure["rids"],
            }, f, ensure_ascii=False, indent=2, sort_keys=True)
            f.write("\n")

    if v["rouges_a"]:
        return 1
    if v["derives_b"]:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
