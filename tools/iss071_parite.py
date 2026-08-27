#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ISS-071 — le contrat de parité éditeur/export, rendu EXÉCUTABLE.

CE QUE CE SCRIPT EST
--------------------
L'exécutant de `docs/contrats/iss071_parite_resolveurs.md`. Ce contrat énonce
neuf invariants et une table de gate ; en prose, ils se dégradent en silence.
Ici, chacun est une assertion qui rougit.

CE QU'IL N'EST PAS
------------------
Il ne lance rien, n'exporte rien et ne juge pas une image. Il lit trois
artefacts produits par d'autres — le manifeste ÉDITEUR, le manifeste EXPORT et
le journal du jeu exporté — et rend un verdict. C'est
`tools/gate_export_parite.sh` qui les produit.

LES TROIS RÈGLES DE RÉDACTION QUI GOUVERNENT TOUT CE FICHIER
-----------------------------------------------------------
1. COMPARER DES COUPLES, JAMAIS DES TAILLES (invariant I3). Deux index de même
   cardinal et de contenus différents DOIVENT rougir. Un `len(a) == len(b)` est
   une non-comparaison qui a l'air d'une comparaison.

2. PUBLIER LA TAILLE DE CE QUI A ÉTÉ EXAMINÉ. Le dépôt a déjà vu un
   « IDENTIQUE » imprimé sur deux fichiers absents (`tools/CLAUDE.md`, piège
   `diff`). Un « aucune différence » sans « sur N couples » ne prouve rien, et
   c'est exactement la forme que prend un contrôle aveugle.

3. UN FICHIER ABSENT, VIDE OU INCOHÉRENT SORT EN 3 (BLOQUÉ), JAMAIS EN 0.
   `.claude/rules/evidence.md` : une étape sautée n'est pas une étape réussie.

Codes de sortie : 0 = VERT · 1 = ROUGE · 3 = BLOQUÉ.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

# --------------------------------------------------------------------------
# Les quatre familles d'erreur du défaut, avec la regex qui en extrait le NOM
# du modèle. Les libellés sont ceux des `push_error` / `push_warning` du code
# de production.
#
# Attention : « modèle végétal introuvable » est un push_WARNING, pas un
# push_error. Un filtre sur les lignes commençant par « ERROR: » en perdrait
# 631 sur 1 094, soit la majorité du défaut.
# --------------------------------------------------------------------------
FAMILLES: dict[str, re.Pattern[str]] = {
    "kit : modèle inconnu": re.compile(r"kit\s*:\s*modèle inconnu\s+(\S+)"),
    "modèle végétal introuvable": re.compile(
        r"modèle végétal introuvable\s*:\s*(\S+)"),
    "flower_field : modèle inconnu": re.compile(
        r"\[flower_field\]\s+modèle inconnu\s+(\S+)"),
    "flower_field : modèle de dalle inconnu": re.compile(
        r"\[flower_field\]\s+modèle de dalle inconnu\s+(\S+)"),
}

# Jalon écrit par `WorldV2Root` juste avant le vidage du manifeste. Sans lui,
# le monde n'a pas fini de se monter et TOUS les compteurs sont partiels : un
# zéro y signifierait « pas encore demandé », pas « rien ne manque ».
JALON_MONDE = "fondation V2 vérifiée"

# I8 — durées de vie de cache épinglées sur des LITTÉRAUX. Le correctif
# d'ISS-071 touche les deux résolveurs ; il n'a aucune raison de toucher ces
# bornes, et les toucher rouvrirait la fuite verrouillée par ISS-059.
PINS_SOURCE: list[tuple[str, str, str]] = [
    ("scripts/world_v2/poi/world_v2_place_kit.gd",
     "const SCENE_CACHE_MAX: int = 256",
     "plafond de rétention des PackedScene de kit (ISS-059)"),
    ("scripts/core/asset_registry.gd",
     "const MODEL_CACHE_MAX: int = 48",
     "plafond de rétention des PackedScene du registre (ISS-059)"),
]


class Rapport:
    """Accumule les constats. Le verdict est le PLUS FAIBLE d'entre eux, jamais
    leur moyenne (PROMPT4_METHOD §12)."""

    def __init__(self) -> None:
        self.constats: list[dict[str, Any]] = []

    def note(self, code: str, verdict: str, examine: str,
             mesure: str) -> None:
        self.constats.append({
            "controle": code, "verdict": verdict,
            "examine": examine, "mesure": mesure,
        })
        print(f"[{verdict:12s}] {code}\n"
              f"               examiné : {examine}\n"
              f"               mesure  : {mesure}", flush=True)

    # C4 (contre-revue) : un « NON VÉRIFIÉ » n'est PAS un vert. PROMPT4_METHOD
    # §12 : « tout critère non testé est NON VÉRIFIÉ, jamais implicitement
    # réussi », et le verdict d'un gate est le PLUS FAIBLE de ses critères.
    # Jusqu'ici ce statut n'affectait NI le verdict NI le code de sortie : le
    # portail pouvait rendre 0 en n'ayant rien mesuré, ce qui est exactement le
    # « test qui ne peut pas échouer » que ce dépôt traque depuis ISS-018.
    ORDRE_DU_PIRE: tuple[str, ...] = ("BLOQUÉ", "ROUGE", "NON VÉRIFIÉ")
    CODES: dict[str, int] = {"VERT": 0, "ROUGE": 1,
                             "BLOQUÉ": 3, "NON VÉRIFIÉ": 3}

    def verdict(self) -> str:
        v = {c["verdict"] for c in self.constats}
        for pire in self.ORDRE_DU_PIRE:
            if pire in v:
                return pire
        return "VERT"

    def code_sortie(self) -> int:
        return self.CODES[self.verdict()]


# --------------------------------------------------------------------------
# Chargement — toute anomalie de lecture est un BLOCAGE, pas un échec de
# parité. Confondre les deux ferait passer « je n'ai pas pu mesurer » pour
# « ça rate », et un correctif serait écrit contre un fantôme.
# --------------------------------------------------------------------------
def charger_manifeste(chemin: Path, role: str,
                      rapport: Rapport) -> dict[str, Any] | None:
    if not chemin.exists():
        rapport.note(f"lecture du manifeste {role}", "BLOQUÉ",
                     str(chemin), "fichier ABSENT — rien n'a été comparé")
        return None
    octets = chemin.stat().st_size
    if octets == 0:
        rapport.note(f"lecture du manifeste {role}", "BLOQUÉ",
                     str(chemin), "fichier VIDE (0 octet)")
        return None
    try:
        data = json.loads(chemin.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        rapport.note(f"lecture du manifeste {role}", "BLOQUÉ",
                     f"{chemin} ({octets} o)", f"JSON illisible : {exc}")
        return None
    if not isinstance(data, dict) or "resolveurs" not in data:
        rapport.note(f"lecture du manifeste {role}", "BLOQUÉ",
                     f"{chemin} ({octets} o)",
                     "structure inattendue : clé « resolveurs » absente")
        return None

    # Garde contre l'erreur la plus silencieuse possible : comparer un
    # manifeste avec lui-même, ou intervertir les deux. Les deux donneraient un
    # vert parfait sans avoir rien prouvé.
    attendu = {"editeur": "editeur", "export": "export"}[role]
    trouve = str(data.get("environnement", "?"))
    if trouve != attendu:
        rapport.note(f"lecture du manifeste {role}", "BLOQUÉ",
                     f"{chemin} ({octets} o)",
                     f"ce manifeste se déclare « {trouve} » alors qu'il est "
                     f"fourni comme « {attendu} » — fichiers intervertis ou "
                     "manifeste comparé avec lui-même")
        return None
    rapport.note(f"lecture du manifeste {role}", "VERT",
                 f"{chemin} ({octets} o)",
                 f"environnement « {trouve} », godot "
                 f"{data.get('godot', '?')}, monde {data.get('monde', '?')}")
    return data


def charger_journal(chemin: Path, rapport: Rapport) -> list[str] | None:
    if not chemin.exists():
        rapport.note("lecture du journal du jeu", "BLOQUÉ", str(chemin),
                     "fichier ABSENT — aucune ligne d'erreur n'a été comptée")
        return None
    texte = chemin.read_text(encoding="utf-8", errors="replace")
    lignes = texte.splitlines()
    if not lignes:
        rapport.note("lecture du journal du jeu", "BLOQUÉ", str(chemin),
                     "journal VIDE (0 ligne)")
        return None
    if JALON_MONDE not in texte:
        # Zéro erreur dans un journal où le monde n'est jamais monté est le
        # faux vert le plus facile à fabriquer de tout ce portail.
        rapport.note("lecture du journal du jeu", "BLOQUÉ",
                     f"{chemin} ({len(lignes)} lignes)",
                     f"jalon « {JALON_MONDE} » ABSENT : le monde n'a pas fini "
                     "de se monter, les compteurs seraient partiels")
        return None
    rapport.note("lecture du journal du jeu", "VERT",
                 f"{chemin} ({len(lignes)} lignes)",
                 f"jalon « {JALON_MONDE} » présent")
    return lignes


# --------------------------------------------------------------------------
# Comparaisons
# --------------------------------------------------------------------------
def _couples(index: dict[str, Any]) -> dict[str, str]:
    return {str(k): str(v) for k, v in index.items()}


def comparer_index(nom_res: str, ed: dict[str, Any], ex: dict[str, Any],
                   rapport: Rapport) -> None:
    """I1, I2, I3 — les seuls contrôles qui voient réellement le défaut."""
    a, b = _couples(ed.get("index", {})), _couples(ex.get("index", {}))
    cles_a, cles_b = set(a), set(b)
    seulement_ed = sorted(cles_a - cles_b)
    seulement_ex = sorted(cles_b - cles_a)
    communes = sorted(cles_a & cles_b)

    # I1 — différence symétrique des CLÉS.
    diff = len(seulement_ed) + len(seulement_ex)
    # C6 (contre-revue) : « 0 différence entre deux index VIDES » est le même
    # vert-sur-rien que `diff` sur deux fichiers absents. Doctrine déjà
    # appliquée à I2/I3 plus bas ; elle vaut ici aussi.
    if not cles_a and not cles_b:
        verdict_i1 = "NON VÉRIFIÉ"
    elif diff == 0:
        verdict_i1 = "VERT"
    else:
        verdict_i1 = "ROUGE"
    rapport.note(
        f"I1 index {nom_res} — mêmes noms canoniques indexés",
        verdict_i1,
        f"{len(cles_a)} clés éditeur contre {len(cles_b)} clés export, "
        f"union {len(cles_a | cles_b)}",
        f"{diff} différence(s) : {len(seulement_ed)} seulement en éditeur, "
        f"{len(seulement_ex)} seulement en export"
        + (f" — ex. éditeur seul : {', '.join(seulement_ed[:5])}"
           if seulement_ed else "")
        + (f" — ex. export seul : {', '.join(seulement_ex[:5])}"
           if seulement_ex else ""))

    # I2 + I3 — égalité des COUPLES sur les clés communes. C'est ce contrôle,
    # et lui seul, qui rougit quand deux index ont la même taille et des
    # contenus différents.
    divergents = [(c, a[c], b[c]) for c in communes if a[c] != b[c]]
    # « 0 divergence sur 0 couple » est un vert obtenu en n'examinant RIEN —
    # la forme exacte du piège `diff` sur deux fichiers absents. Sans clé
    # commune, ce contrôle n'a pas de résultat : il est NON VÉRIFIÉ.
    if not communes:
        verdict_i2 = "NON VÉRIFIÉ"
    elif divergents:
        verdict_i2 = "ROUGE"
    else:
        verdict_i2 = "VERT"
    rapport.note(
        f"I2/I3 index {nom_res} — même chemin source pour un même nom",
        verdict_i2,
        f"{len(communes)} couple(s) nom→chemin comparés un à un "
        "(comparaison de couples, jamais de cardinaux)",
        f"{len(divergents)} couple(s) divergent(s)"
        + ("" if not divergents else " : " + " · ".join(
            f"{c} : éditeur={p} / export={q}"
            for c, p, q in divergents[:5])))

    if len(communes) == 0 and (cles_a or cles_b):
        rapport.note(
            f"I3 index {nom_res} — la comparaison a porté sur quelque chose",
            "ROUGE",
            f"{len(cles_a)} clés éditeur, {len(cles_b)} clés export",
            "AUCUNE clé commune : les deux index sont disjoints, la "
            "comparaison de couples n'a rien pu examiner")


def comparer_repertoires(nom_res: str, ed: dict[str, Any], ex: dict[str, Any],
                         rapport: Rapport) -> None:
    """I7 — l'ORDRE des répertoires porte la priorité entre chemins homonymes.
    Le comparer comme un ensemble laisserait passer une inversion de priorité.
    """
    a = [str(x) for x in ed.get("repertoires", [])]
    b = [str(x) for x in ex.get("repertoires", [])]
    # C6 (contre-revue) : deux listes vides sont « identiques » sans rien
    # prouver — le manifeste n'aurait alors simplement pas publié les
    # répertoires balayés.
    rapport.note(
        f"I7 {nom_res} — ordre des répertoires inchangé",
        "NON VÉRIFIÉ" if not a and not b else ("VERT" if a == b else "ROUGE"),
        f"{len(a)} répertoire(s) éditeur, {len(b)} export, comparés "
        "position par position",
        "listes identiques dans le même ordre" if a == b
        else f"éditeur={a} / export={b}")


def comparer_collisions(nom_res: str, ed: dict[str, Any], ex: dict[str, Any],
                        rapport: Rapport) -> None:
    """I6 — une collision peut exister ; ce qui est interdit, c'est qu'elle
    soit résolue SANS ÊTRE PUBLIÉE, ou publiée différemment d'un environnement
    à l'autre."""
    a = [json.dumps(c, sort_keys=True, ensure_ascii=False)
         for c in ed.get("collisions", [])]
    b = [json.dumps(c, sort_keys=True, ensure_ascii=False)
         for c in ex.get("collisions", [])]
    egales = sorted(a) == sorted(b)
    rapport.note(
        f"I6 {nom_res} — collisions publiées à l'identique",
        "VERT" if egales else "ROUGE",
        f"{len(a)} collision(s) publiée(s) en éditeur, {len(b)} en export",
        "mêmes collisions des deux côtés" if egales
        else "les listes diffèrent : "
             f"éditeur seul={sorted(set(a) - set(b))[:3]} · "
             f"export seul={sorted(set(b) - set(a))[:3]}")


def comparer_compteurs(nom_res: str, ed: dict[str, Any], ex: dict[str, Any],
                       rapport: Rapport) -> int:
    """Table de gate §4, partie « demandés / chargés / manqués ».
    Rend le total des manques des deux côtés."""
    dem_a, dem_b = set(ed.get("demandes", {})), set(ex.get("demandes", {}))
    res_a, res_b = set(ed.get("resolus", {})), set(ex.get("resolus", {}))
    man_a = {str(k): int(v) for k, v in ed.get("manques", {}).items()}
    man_b = {str(k): int(v) for k, v in ex.get("manques", {}).items()}

    d = sorted(dem_a ^ dem_b)
    # C6 (contre-revue) : si PERSONNE n'a rien demandé des deux côtés, la
    # différence est nulle sans qu'aucun résolveur ait travaillé. C'est une
    # absence de mesure, pas une parité.
    rapport.note(
        f"§4 {nom_res} — différence des modèles DEMANDÉS",
        "NON VÉRIFIÉ" if not dem_a and not dem_b
        else ("VERT" if not d else "ROUGE"),
        f"{len(dem_a)} nom(s) demandés en éditeur, {len(dem_b)} en export",
        f"{len(d)} différence(s)" + (f" : {', '.join(d[:8])}" if d else ""))

    r = sorted(res_a ^ res_b)
    rapport.note(
        f"§4 {nom_res} — différence des modèles CHARGÉS",
        "NON VÉRIFIÉ" if not res_a and not res_b
        else ("VERT" if not r else "ROUGE"),
        f"{len(res_a)} nom(s) chargés en éditeur, {len(res_b)} en export",
        f"{len(r)} différence(s)" + (f" : {', '.join(r[:8])}" if r else ""))

    total = sum(man_a.values()) + sum(man_b.values())
    rapport.note(
        f"§4 {nom_res} — modèle DEMANDÉ mais NON CHARGÉ",
        "VERT" if total == 0 else "ROUGE",
        f"table « manques » des deux manifestes : {len(man_a)} nom(s) "
        f"distincts en éditeur, {len(man_b)} en export",
        f"{sum(man_a.values())} appel(s) manqué(s) en éditeur, "
        f"{sum(man_b.values())} en export"
        + ("" if not man_b else " — ex. export : " + ", ".join(
            f"{k}×{v}" for k, v in sorted(
                man_b.items(), key=lambda kv: -kv[1])[:6])))
    return total


def comparer_positif(cle: str, valeur_ed: Any, valeur_ex: Any,
                     rapport: Rapport, libelle: str) -> None:
    """Table de gate §4 : « > 0 ET identique des deux côtés ».

    POURQUOI CE CONTRÔLE EXISTE : la disparition des messages d'erreur ne prouve
    rien. Un résolveur qui ne résout plus rien du tout n'imprime aucune erreur
    non plus. Seul un compteur POSITIF prouve que du travail a eu lieu."""
    try:
        a, b = int(valeur_ed), int(valeur_ex)
    except (TypeError, ValueError):
        rapport.note(f"§4 {libelle} — positif et identique", "BLOQUÉ",
                     f"clé « {cle} »",
                     f"valeur non numérique : éditeur={valeur_ed!r} "
                     f"export={valeur_ex!r}")
        return
    ok = a > 0 and b > 0 and a == b
    rapport.note(
        f"§4 {libelle} — positif et identique",
        "VERT" if ok else "ROUGE",
        f"clé « {cle} » des deux manifestes",
        f"éditeur={a}, export={b}"
        + ("" if ok else " — exigé : strictement > 0 des deux côtés ET égaux"))


def compter_familles(lignes: list[str], rapport: Rapport
                     ) -> tuple[int, dict[str, list[str]]]:
    """Table de gate §4, partie journal. Rend (total des lignes, noms par
    famille). Compte des LIGNES et publie aussi les noms DISTINCTS : un même
    modèle manquant 300 fois est un seul défaut, 300 fois visible."""
    total = 0
    noms: dict[str, list[str]] = {}
    for famille, motif in FAMILLES.items():
        trouves = [m.group(1) for ligne in lignes
                   for m in [motif.search(ligne)] if m]
        noms[famille] = trouves
        total += len(trouves)
        distincts = sorted(set(trouves))
        rapport.note(
            f"§4 journal — lignes « {famille} »",
            "VERT" if not trouves else "ROUGE",
            f"{len(lignes)} ligne(s) de journal balayées",
            f"{len(trouves)} ligne(s), {len(distincts)} modèle(s) distinct(s)"
            + ((f" : {', '.join(distincts[:8])}"
                + (" …" if len(distincts) > 8 else "")) if distincts else ""))
    return total, noms


def controle_i9(manques_total: int, lignes_journal: int,
                rapport: Rapport) -> None:
    """I9 — aucun modèle manquant remplacé SILENCIEUSEMENT.

    On ne peut pas exiger l'égalité stricte : un manque de kit compte dans les
    DEUX résolveurs (`scene_for` retombe sur `AssetRegistry.model`, qui compte
    à son tour). Ce qui est exigible, c'est la co-occurrence : des manques sans
    aucune ligne au journal seraient des remplacements muets."""
    muet = manques_total > 0 and lignes_journal == 0
    fantome = manques_total == 0 and lignes_journal > 0
    verdict = "ROUGE" if (muet or fantome) else "VERT"
    rapport.note(
        "I9 — aucun manque silencieux",
        verdict,
        f"{manques_total} manque(s) comptés aux manifestes contre "
        f"{lignes_journal} ligne(s) d'erreur au journal",
        "compteurs et journal concordent (tous deux nuls, ou tous deux "
        "positifs)" if verdict == "VERT"
        else ("des manques ne laissent AUCUNE trace au journal — "
              "remplacement muet" if muet
              else "des lignes d'erreur sans aucun manque compté — "
                   "l'appareil de mesure ne voit pas ce que le jeu signale"))


def controle_i4_i5(manifeste: dict[str, Any], role: str,
                   rapport: Rapport) -> None:
    """I4/I5 — chargeabilité de chaque chemin indexé.

    C7 (contre-revue) : ce contrôle n'était appelé que sur le manifeste
    d'EXPORT, alors que la preuve écrite affirmait « des deux côtés ». Un
    chemin devenu non chargeable en ÉDITEUR — une régression de sens inverse —
    serait passé inaperçu. Il prend donc désormais le rôle en argument et est
    appelé une fois par environnement.

    HONNÊTETÉ : le manifeste ne porte PAS la chargeabilité des chemins jamais
    demandés. Ce contrôle couvre donc les noms réellement demandés (via
    « manques ») et déclare le reste NON VÉRIFIÉ. Le déclarer vert par
    déduction serait exactement l'interdit de PROMPT4_METHOD §12."""
    for nom_res, res in manifeste.get("resolveurs", {}).items():
        index = set(_couples(res.get("index", {})))
        demandes = set(res.get("demandes", {}))
        # ISS-071, complément du lead : quand le monde a été monté avec
        # `--iss071-chargeabilite`, le manifeste porte le résultat d'un VRAI
        # `load()` sur CHAQUE chemin indexé, pas seulement sur ceux qu'un lieu
        # a demandés. Le contrôle cesse alors d'être partiel.
        #
        # `ResourceLoader.exists()` seul ne suffirait pas :
        # `ResourceFormatImporter::exists()` rend vrai dès qu'un
        # `<chemin>.import` existe, sans regarder le type demandé — un `.png`
        # y passe. Seul `load()` tranche, et c'est lui qui est compté ici.
        charge = res.get("chargeabilite")
        if isinstance(charge, dict) and int(charge.get("chemins", 0)) > 0:
            total = int(charge["chemins"])
            reussis = int(charge.get("load_reussi", 0))
            defaillants = list(charge.get("defaillants", []))
            # C5 (contre-revue) : sans cette égalité, une régression qui
            # n'éprouverait QU'UN SEUL chemin rendrait « 1/1 chargés », donc
            # vert, en n'ayant presque rien mesuré. La couverture est exigée
            # sur la TOTALITÉ de l'index publié, pas sur un échantillon.
            complet = total == len(index)
            ok = complet and reussis == total and not defaillants
            rapport.note(
                f"I4/I5 {role}/{nom_res} — chemins indexés réellement chargeables",
                "VERT" if ok else "ROUGE",
                f"{total} chemin(s) éprouvés par un vrai load(), pour "
                f"{len(index)} chemin(s) publiés dans l'index",
                (f"{reussis}/{total} chargés"
                 + ("" if complet else
                    f" — COUVERTURE PARTIELLE : {total} éprouvé(s) contre "
                    f"{len(index)} indexé(s), la mesure ne porte pas sur "
                    "tout l'index")
                 + ("" if not defaillants
                    else " — défaillants : " + ", ".join(defaillants[:6]))))
            continue
        couverts = index & demandes
        non_couverts = index - demandes
        # Index vide : il n'y a pas « 0 chemin non couvert », il n'y a
        # AUCUNE couverture. Un vert ici serait un vert obtenu en ne faisant
        # rien — le défaut que ce dépôt traque depuis ISS-018.
        if not index:
            verdict_i45 = "ROUGE"
        elif non_couverts:
            verdict_i45 = "NON VÉRIFIÉ"
        else:
            verdict_i45 = "VERT"
        rapport.note(
            f"I4/I5 {role}/{nom_res} — chemins indexés réellement chargeables",
            verdict_i45,
            f"{len(index)} chemin(s) indexés, dont {len(couverts)} "
            "effectivement demandés au montage du monde",
            ("INDEX VIDE : aucun chemin n'a pu être éprouvé — ce n'est pas "
             "une couverture parfaite, c'est une absence de couverture"
             if not index else
             f"{len(couverts)} chemin(s) éprouvés par un vrai load() ; "
             f"{len(non_couverts)} chemin(s) indexés mais jamais demandés — "
             "le manifeste ne porte pas leur chargeabilité ; relancer le "
             "montage avec --iss071-chargeabilite=1 pour les éprouver"))


def controle_i8(racine: Path | None, rapport: Rapport) -> None:
    """I8 — aucune durée de vie de cache modifiée. Épinglé sur des LITTÉRAUX :
    un test qui relit la constante depuis le fichier et la compare à elle-même
    passerait toujours (PROMPT4_METHOD §2, « le test qui ne peut pas
    échouer »)."""
    if racine is None:
        rapport.note("I8 — durées de vie de cache inchangées", "NON VÉRIFIÉ",
                     "aucune racine de sources fournie (--source)",
                     "les littéraux de cache n'ont pas été relus")
        return
    for rel, litteral, quoi in PINS_SOURCE:
        chemin = racine / rel
        if not chemin.exists():
            rapport.note("I8 — durées de vie de cache inchangées", "BLOQUÉ",
                         str(chemin), "fichier source ABSENT")
            continue
        source = chemin.read_text(encoding="utf-8", errors="replace")
        present = litteral in source
        rapport.note(
            f"I8 — {quoi}",
            "VERT" if present else "ROUGE",
            f"{rel} ({len(source.splitlines())} lignes) cherché pour le "
            f"littéral « {litteral} »",
            "littéral présent, à l'identique" if present
            else "LITTÉRAL ABSENT : la borne de rétention a été modifiée, "
                 "ce qui rouvre la fuite verrouillée par ISS-059")


# --------------------------------------------------------------------------
def analyser(ed: dict[str, Any], ex: dict[str, Any], lignes: list[str],
             racine: Path | None, rapport: Rapport,
             inventaire: Path | None = None) -> None:
    res_ed = ed.get("resolveurs", {})
    res_ex = ex.get("resolveurs", {})
    noms_res = sorted(set(res_ed) | set(res_ex))
    if not noms_res:
        rapport.note("résolveurs présents aux manifestes", "BLOQUÉ",
                     "clé « resolveurs »", "aucun résolveur des deux côtés")
        return
    manquants = sorted(set(res_ed) ^ set(res_ex))
    if manquants:
        rapport.note("résolveurs présents aux manifestes", "ROUGE",
                     f"{len(res_ed)} côté éditeur, {len(res_ex)} côté export",
                     f"absent d'un des deux côtés : {', '.join(manquants)}")

    manques_total = 0
    for nom in noms_res:
        a, b = res_ed.get(nom, {}), res_ex.get(nom, {})
        comparer_repertoires(nom, a, b, rapport)
        comparer_index(nom, a, b, rapport)
        comparer_collisions(nom, a, b, rapport)
        manques_total += comparer_compteurs(nom, a, b, rapport)

    # Compteurs qui doivent être POSITIFS et égaux (contrat §3).
    comparer_positif("modules_instancies",
                     res_ed.get("WorldV2PlaceKit", {}).get(
                         "modules_instancies", 0),
                     res_ex.get("WorldV2PlaceKit", {}).get(
                         "modules_instancies", 0),
                     rapport, "modules_instancies")
    veg_ed = ed.get("vegetation", {})
    veg_ex = ex.get("vegetation", {})
    comparer_positif("cellules_emises", veg_ed.get("cellules_emises", 0),
                     veg_ex.get("cellules_emises", 0), rapport,
                     "cellules_emises")
    cm_a = int(veg_ed.get("cellules_manquees", 0) or 0)
    cm_b = int(veg_ex.get("cellules_manquees", 0) or 0)
    rapport.note(
        "§4 cellules_manquees — nulles des deux côtés",
        "VERT" if cm_a == 0 and cm_b == 0 else "ROUGE",
        "clé « vegetation.cellules_manquees » des deux manifestes",
        f"éditeur={cm_a}, export={cm_b} — une cellule manquée est une cellule "
        "de MultiMesh sautée ENTIÈRE, donc bien plus d'objets absents que "
        "d'appels manqués")
    lp_a, lp_b = ed.get("lieux_poses"), ex.get("lieux_poses")
    # Contre-revue S1 : les manifestes ARCHIVÉS d'avant D-054 portent 16 (le
    # compte incluait le nœud utilitaire « Recompenses ») ; toute mesure
    # postérieure dit 15. Apparier les deux générations rougirait ce contrôle
    # pour le correctif de compteur, pas pour l'empaquetage — l'indice le dit.
    indice = ""
    if {lp_a, lp_b} == {15, 16}:
        indice = (" — INDICE : 15 contre 16 est la signature de deux "
                  "GÉNÉRATIONS de manifeste (avant/après D-054), pas d'un "
                  "défaut d'empaquetage ; re-mesurer les deux côtés sur le "
                  "même arbre")
    rapport.note(
        "§3 lieux_poses — positif et identique",
        "VERT" if isinstance(lp_a, int) and lp_a > 0 and lp_a == lp_b
        else "ROUGE",
        "clé « lieux_poses » des deux manifestes",
        f"éditeur={lp_a}, export={lp_b}{indice}")

    total_lignes, noms = compter_familles(lignes, rapport)
    controle_i9(manques_total, total_lignes, rapport)
    controle_i4_i5(ed, "editeur", rapport)
    controle_i4_i5(ex, "export", rapport)
    controle_i8(racine, rapport)

    if inventaire is not None:
        tous: dict[str, int] = {}
        for famille, liste in noms.items():
            for n in liste:
                tous[n] = tous.get(n, 0) + 1
        lignes_inv = [
            "# ISS-071 — inventaire NOMINATIF des modèles absents de la build",
            f"# {total_lignes} ligne(s) d'erreur, {len(tous)} modèle(s) "
            "distinct(s)", ""]
        for famille, liste in noms.items():
            d = sorted(set(liste))
            lignes_inv.append(f"## {famille} — {len(liste)} ligne(s), "
                              f"{len(d)} distinct(s)")
            lignes_inv += [f"  {n}  x{liste.count(n)}" for n in d]
            lignes_inv.append("")
        lignes_inv.append(f"## union des familles — {len(tous)} distinct(s)")
        lignes_inv += [f"  {n}  x{c}" for n, c in sorted(tous.items())]
        inventaire.parent.mkdir(parents=True, exist_ok=True)
        inventaire.write_text("\n".join(lignes_inv) + "\n", encoding="utf-8")
        print(f"\ninventaire nominatif écrit : {inventaire} "
              f"({len(tous)} modèle(s) distinct(s))", flush=True)


# --------------------------------------------------------------------------
# CONTRÔLE NÉGATIF DE CE SCRIPT LUI-MÊME (directive §7, points 6 et 10).
#
# Un comparateur qui ne rougit jamais est indistinguable d'un comparateur qui
# marche. Ces scénarios lui présentent des cas dont la réponse est connue
# d'avance, et le mode échoue si l'un d'eux ne rend pas le verdict attendu.
# --------------------------------------------------------------------------
def _manifeste_synthetique(env: str, index: dict[str, str],
                           demandes: dict[str, int] | None = None,
                           manques: dict[str, int] | None = None,
                           collisions: list[dict[str, str]] | None = None,
                           modules: int = 10, cellules: int = 20,
                           repertoires: list[str] | None = None
                           ) -> dict[str, Any]:
    demandes = demandes if demandes is not None else {k: 1 for k in index}
    resolus = {k: v for k, v in demandes.items() if k not in (manques or {})}
    bloc = {
        "repertoires": repertoires or ["res://a", "res://b"],
        "index": dict(index), "collisions": collisions or [],
        "demandes": dict(demandes), "resolus": resolus,
        "manques": dict(manques or {}),
    }
    kit = dict(bloc, resolveur="WorldV2PlaceKit", modules_instancies=modules)
    reg = dict(bloc, resolveur="AssetRegistry")
    return {
        "environnement": env, "godot": "4.7.1-stable", "monde": "neris_v2",
        "resolveurs": {"WorldV2PlaceKit": kit, "AssetRegistry": reg},
        "vegetation": {"cellules_emises": cellules, "cellules_manquees": 0},
        # 15 = le compte RÉEL des scènes posées par le layout. L'ancienne
        # fixture disait 16 parce que la mesure du jeu comptait aussi le nœud
        # utilitaire « Recompenses » — défaut corrigé dans world_v2_root.gd
        # (passe S1) ; le contrôle n'exige que « positif et identique ».
        "lieux_poses": 15,
    }


def autotest() -> int:
    journal_sain = [f"ligne {i}" for i in range(50)] + [
        f"[world_v2] {JALON_MONDE} — vallée whitebox prête."]
    base = {"Foo": "res://a/Foo.gltf", "Bar": "res://b/Bar.glb"}
    # C4 (contre-revue) : le scénario « état sain » passait `source=None`, donc
    # I8 rendait NON VÉRIFIÉ — et l'autotest le déclarait VERT. Il ratifiait
    # ainsi le défaut qu'il était censé interdire. La racine est désormais
    # déduite de l'emplacement du script, pas du répertoire courant.
    racine = Path(__file__).resolve().parent.parent
    # (racine, verdict attendu) : le dernier scénario prouve que NON VÉRIFIÉ
    # bloque réellement, ce qui n'était pas le cas avant la contre-revue.
    scenarios: list[tuple[str, dict, dict, list[str], Path | None, str]] = [
        ("état sain : index identiques, journal propre",
         _manifeste_synthetique("editeur", base),
         _manifeste_synthetique("export", base), journal_sain,
         racine, "VERT"),

        ("MÊME TAILLE, contenus différents (I3) — doit ROUGIR",
         _manifeste_synthetique("editeur", base),
         _manifeste_synthetique("export", {"Foo": "res://a/Foo.gltf",
                                           "Baz": "res://b/Baz.glb"}),
         journal_sain, racine, "ROUGE"),

        ("même taille, MÊMES clés, chemins différents (I2) — doit ROUGIR",
         _manifeste_synthetique("editeur", base),
         _manifeste_synthetique("export", {"Foo": "res://a/Foo.gltf",
                                           "Bar": "res://AUTRE/Bar.glb"}),
         journal_sain, racine, "ROUGE"),

        ("index export VIDE (le défaut d'ISS-071) — doit ROUGIR",
         _manifeste_synthetique("editeur", base),
         _manifeste_synthetique("export", {}, demandes={"Foo": 3},
                                manques={"Foo": 3}, modules=0, cellules=0),
         journal_sain + ["ERROR: [world_v2] kit : modèle inconnu Foo"],
         racine, "ROUGE"),

        ("JOURNAL FILTRÉ : plus une seule ligne d'erreur, mais index export "
         "vide et compteurs à zéro — doit ROUGIR quand même (point 10)",
         _manifeste_synthetique("editeur", base),
         _manifeste_synthetique("export", {}, demandes={}, modules=0,
                                cellules=0),
         journal_sain, racine, "ROUGE"),

        ("ordre des répertoires inversé (I7) — doit ROUGIR",
         _manifeste_synthetique("editeur", base,
                                repertoires=["res://a", "res://b"]),
         _manifeste_synthetique("export", base,
                                repertoires=["res://b", "res://a"]),
         journal_sain, racine, "ROUGE"),

        ("collision publiée d'un seul côté (I6) — doit ROUGIR",
         _manifeste_synthetique("editeur", base),
         _manifeste_synthetique("export", base, collisions=[
             {"nom": "Foo", "retenu": "res://a/Foo.gltf",
              "ignore": "res://b/Foo.gltf"}]),
         journal_sain, racine, "ROUGE"),

        ("modules_instancies = 0 des deux côtés — doit ROUGIR (un vert obtenu "
         "en ne faisant rien n'est pas un vert)",
         _manifeste_synthetique("editeur", base, modules=0),
         _manifeste_synthetique("export", base, modules=0),
         journal_sain, racine, "ROUGE"),

        ("journal sans le jalon de montage — doit BLOQUER",
         _manifeste_synthetique("editeur", base),
         _manifeste_synthetique("export", base),
         ["une ligne quelconque"], racine, "BLOQUÉ"),

        ("manifestes intervertis — doit BLOQUER",
         _manifeste_synthetique("export", base),
         _manifeste_synthetique("editeur", base), journal_sain,
         racine, "BLOQUÉ"),

        # C4 — filet de régression de la contre-revue. Tout est parfait SAUF
        # qu'un contrôle n'a pas pu être exécuté (pas de racine → I8 non relu).
        # Avant la correction, ce cas rendait VERT et code 0 : le portail
        # déclarait la parité atteinte en n'ayant pas tout mesuré.
        ("un seul contrôle NON VÉRIFIÉ, tout le reste vert — ne doit PAS "
         "rendre VERT (PROMPT4_METHOD §12 : jamais implicitement réussi)",
         _manifeste_synthetique("editeur", base),
         _manifeste_synthetique("export", base), journal_sain,
         None, "NON VÉRIFIÉ"),
    ]

    echecs = 0
    for titre, ed, ex, journal, racine_sc, attendu in scenarios:
        rapport = Rapport()
        # On rejoue le chemin réel, gardes de lecture comprises.
        ok_ed = str(ed.get("environnement")) == "editeur"
        ok_ex = str(ex.get("environnement")) == "export"
        if not (ok_ed and ok_ex):
            rapport.note("lecture des manifestes", "BLOQUÉ", "synthétique",
                         "environnements intervertis")
        elif JALON_MONDE not in "\n".join(journal):
            rapport.note("lecture du journal", "BLOQUÉ", "synthétique",
                         "jalon absent")
        else:
            analyser(ed, ex, journal, racine_sc, rapport)
        obtenu = rapport.verdict()
        # Le code de sortie fait partie du contrat : un verdict non-VERT qui
        # rendrait 0 laisserait passer le portail dans gate_export_parite.sh.
        code = rapport.code_sortie()
        bon = obtenu == attendu and (code == 0) == (attendu == "VERT")
        echecs += 0 if bon else 1
        print(f"\n=== AUTOTEST [{'OK ' if bon else 'ÉCHEC'}] {titre}\n"
              f"    attendu {attendu}, obtenu {obtenu} (code {code}) "
              f"(sur {len(rapport.constats)} contrôles)", flush=True)
    print(f"\n=== AUTOTEST : {len(scenarios)} scénarios, {echecs} échec(s)",
          flush=True)
    return 1 if echecs else 0


# --------------------------------------------------------------------------
def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        description="ISS-071 — vérifie la parité de résolution des modèles "
                    "entre l'exécution éditeur et la build exportée.")
    p.add_argument("--editeur", type=Path,
                   help="manifeste JSON produit en exécution éditeur")
    p.add_argument("--export", type=Path,
                   help="manifeste JSON produit par la build exportée")
    p.add_argument("--journal", type=Path,
                   help="stdout+stderr du jeu exporté")
    p.add_argument("--source", type=Path, default=None,
                   help="racine du dépôt, pour épingler les littéraux (I8)")
    p.add_argument("--rapport", type=Path, default=None,
                   help="où écrire le rapport JSON")
    p.add_argument("--inventaire", type=Path, default=None,
                   help="où écrire l'inventaire nominatif des modèles absents")
    p.add_argument("--autotest", action="store_true",
                   help="contrôle négatif du comparateur lui-même")
    a = p.parse_args(argv)

    if a.autotest:
        return autotest()

    absents = [n for n, v in (("--editeur", a.editeur), ("--export", a.export),
                              ("--journal", a.journal)) if v is None]
    if absents:
        print(f"BLOQUÉ : argument(s) manquant(s) : {', '.join(absents)}",
              file=sys.stderr)
        return 3

    print("=" * 78)
    print("ISS-071 — CONTRÔLE DE PARITÉ ÉDITEUR / EXPORT")
    print("contrat : docs/contrats/iss071_parite_resolveurs.md")
    print("=" * 78, flush=True)

    rapport = Rapport()
    ed = charger_manifeste(a.editeur, "editeur", rapport)
    ex = charger_manifeste(a.export, "export", rapport)
    lignes = charger_journal(a.journal, rapport)
    if ed is not None and ex is not None and lignes is not None:
        analyser(ed, ex, lignes, a.source, rapport, a.inventaire)

    verdict = rapport.verdict()
    code = rapport.code_sortie()
    rouges = [c for c in rapport.constats if c["verdict"] == "ROUGE"]
    bloques = [c for c in rapport.constats if c["verdict"] == "BLOQUÉ"]
    non_verifies = [c for c in rapport.constats
                    if c["verdict"] == "NON VÉRIFIÉ"]
    print("\n" + "=" * 78)
    print(f"VERDICT ISS-071 : {verdict}  (code {code})")
    print(f"  {len(rapport.constats)} contrôle(s) exécutés · "
          f"{len(rouges)} ROUGE · {len(bloques)} BLOQUÉ · "
          f"{len(non_verifies)} NON VÉRIFIÉ")
    for c in bloques + rouges:
        print(f"  - [{c['verdict']}] {c['controle']} :: {c['mesure']}")
    print("=" * 78, flush=True)

    if a.rapport is not None:
        a.rapport.parent.mkdir(parents=True, exist_ok=True)
        a.rapport.write_text(json.dumps({
            "verdict": verdict, "code": code,
            "editeur": str(a.editeur), "export": str(a.export),
            "journal": str(a.journal),
            "constats": rapport.constats,
        }, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"rapport JSON : {a.rapport}", flush=True)
    return code


if __name__ == "__main__":
    sys.exit(main())
