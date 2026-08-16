#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""BATTERIE DE CONTROLES NEGATIFS de `cave_oracle_global.py`.

Un oracle qu'on n'a pas essaye de tromper n'est pas un oracle : c'est une
opinion. Les deux instruments precedents ont ete condamnes non pas parce
qu'ils rendaient un mauvais verdict sur le candidat, mais parce que leurs
controles negatifs ne mordaient pas.

Cette batterie enchaine, pour CHAQUE sabotage, la sequence complete que le
cadrage exige — et elle refuse de conclure si une seule etape manque :

  1. FABRIQUER un sabotage FERME (booleen exact Blender, jamais un retrait
     de triangles) ;
  2. PROUVER la fermeture : 0 bord libre, 0 arete non-manifold. Un sabotage
     ouvert est declare INEXPLOITABLE et n'est PAS compte comme une reussite
     de l'oracle — c'est exactement l'erreur de la passe precedente, ou un
     vert obtenu sur un maillage ouvert avait ete lu comme un vert de
     l'instrument ;
  3. PROUVER qu'un chemin geometrique existe : rayon libre MESURE par rayons
     paralleles, et zero traversee restante sur l'axe. La largeur du cutter
     ne prouve rien ; seule la largeur qui reste ouverte compte ;
  4. obtenir ROUGE ;
  5. RESTAURER — obtenu par construction, la source n'etant jamais reecrite,
     et verifie par sha256 avant/apres ;
  6. obtenir VERT sur la source restauree.

Le `temoin` est le controle zero : un aller-retour glTF sans aucune
modification. Sans lui, un ROUGE pourrait venir de l'export plutot que du
sabotage, et toute la batterie ne prouverait rien.

Usage :
    python3 tools/cave_oracle_batterie.py --entree <glb> --travail <dir>
            [--pas 0.10] [--verrou <fichier>] [--types toit,poche]

Codes de sortie : 0 = toute la batterie conforme · 1 = au moins un controle
negatif n'a pas mordu, ou le candidat n'est pas vert · 3 = BLOQUE.
"""

import argparse
import hashlib
import json
import os
import subprocess
import sys
import time

ICI = os.path.dirname(os.path.abspath(__file__))

## Ce que chaque sabotage doit produire, et par quel axe le prouver.
## `axe` a None : le defaut n'est pas un tunnel, il se prouve par la
## topologie (composantes) et non par un rayon libre.
PLAN = [
    ("temoin",          None,             "VERT"),
    ("toit",            (0.0, 0.0, 1.0),  "ROUGE"),
    ("paroi_est",       (1.0, 0.0, 0.0),  "ROUGE"),
    ("paroi_ouest",     (-1.0, 0.0, 0.0), "ROUGE"),
    ("plancher",        (0.0, 0.0, -1.0), "ROUGE"),
    ("poche",           None,             "ROUGE"),
    ("roche_flottante", None,             "ROUGE"),
]


def sha256(chemin):
    return hashlib.sha256(open(chemin, "rb").read()).hexdigest()


def lancer(cmd, verrou=None, journal=None):
    """Execute, rend `(rc, sortie)`. Le tube ne masque JAMAIS le code retour.

    `tools/CLAUDE.md` : `cmd | tail` rend le code de TAIL. On capture donc
    sans tube, et `rc` est celui de la commande.
    """
    if verrou:
        # forme `flock FICHIER COMMANDE ARGS...`, sans `-c` : aucun shell
        # intermediaire, donc aucune citation a reussir. Un chemin porteur
        # d'espace casserait la forme `-c`, et `tools/CLAUDE.md` demande
        # explicitement que les scripts soient surs sur de tels chemins.
        cmd = ["flock", verrou] + cmd
    debut = time.time()
    proc = subprocess.run(cmd, capture_output=True, text=True, cwd=ICI + "/..")
    duree = time.time() - debut
    texte = proc.stdout + proc.stderr
    if journal:
        with open(journal, "w", encoding="utf-8") as f:
            f.write("$ %s\n" % " ".join(cmd))
            f.write(texte)
            f.write("\nRC=%d\n" % proc.returncode)
    return proc.returncode, texte, duree


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--entree", required=True)
    ap.add_argument("--travail", required=True)
    ap.add_argument("--pas", type=float, default=0.10)
    ap.add_argument("--rayon", type=float, default=0.30)
    ap.add_argument("--graine", default="2.62,2.58,0.99")
    ap.add_argument("--point", default="1.50,-0.40,2.00")
    ap.add_argument("--verrou", default="/home/user/Zelda/.git/heavy_tools.lock")
    ap.add_argument("--types", default=None)
    ap.add_argument("--json", default=None)
    args = ap.parse_args()

    entree = os.path.abspath(args.entree)
    if not os.path.isfile(entree):
        print("BLOQUE : entree introuvable : %s" % entree)
        return 3
    os.makedirs(args.travail, exist_ok=True)
    sha_source_debut = sha256(entree)

    voulus = set(args.types.split(",")) if args.types else None
    plan = [p for p in PLAN if voulus is None or p[0] in voulus]

    print("=" * 78)
    print("BATTERIE DE CONTROLES NEGATIFS")
    print("=" * 78)
    print("source        : %s" % entree)
    print("source sha256 : %s" % sha_source_debut)
    print("pas de grille : %.3f m     rayon de percement : %.2f m"
          % (args.pas, args.rayon))
    print("graine        : %s     point poche/bloc : %s"
          % (args.graine, args.point))
    print()

    resultats = []
    for nom, axe, attendu in plan:
        print("-" * 78)
        print("CONTROLE : %s     (attendu : %s)" % (nom, attendu))
        print("-" * 78)
        fiche = dict(nom=nom, attendu=attendu, axe=axe)

        # 1. fabriquer -----------------------------------------------------
        rc, txt, dt = lancer(
            ["python3", "tools/cave_oracle_sabotage.py",
             "--entree", entree, "--sortie", os.path.abspath(args.travail),
             "--type", nom, "--rayon", "%.4f" % args.rayon,
             "--graine", args.graine, "--point", args.point],
            verrou=args.verrou,
            journal=os.path.join(args.travail, "1_fabrique_%s.log" % nom))
        fiche["fabrique_rc"] = rc
        glb = os.path.join(os.path.abspath(args.travail),
                           "SABOTAGE_%s.glb" % nom)
        for ligne in txt.splitlines():
            if ligne.startswith("SABOTAGE-FACES") or \
               ligne.startswith("SABOTAGE-OUTIL"):
                print("   %s" % ligne)
        if rc != 0 or not os.path.isfile(glb):
            print("   BLOQUE : fabrication impossible (rc=%d)" % rc)
            fiche["etat"] = "BLOQUE"
            resultats.append(fiche)
            continue
        fiche["glb"] = glb
        fiche["sha256"] = sha256(glb)
        print("   fabrique en %.0f s   sha256 %s" % (dt, fiche["sha256"][:16]))

        # 2. fermeture -----------------------------------------------------
        rc, txt, _ = lancer(
            ["python3", "tools/cave_oracle_global.py", glb,
             "--topologie-seule"],
            journal=os.path.join(args.travail, "2_fermeture_%s.log" % nom))
        for ligne in txt.splitlines():
            if "bords libres" in ligne or "composante 0" in ligne or \
               "composante 1" in ligne:
                print("  %s" % ligne)
        ouvert = "bords libres 0" not in txt or \
                 "aretes non-manifold 0" not in txt
        fiche["ferme"] = not ouvert
        if ouvert:
            print("   INEXPLOITABLE : le sabotage a OUVERT le maillage.")
            print("   Un vert obtenu ici ne prouverait rien sur l'oracle —")
            print("   c'est exactement l'erreur de la passe precedente.")
            fiche["etat"] = "INEXPLOITABLE"
            resultats.append(fiche)
            continue

        # 3. chemin geometrique reel --------------------------------------
        if axe is not None:
            # `--vers=-1,0,0` et non `--vers -1,0,0` : argparse prend un
            # argument commencant par `-` pour une option et sort en 2.
            # Mesure du 2026-08-16 : `paroi_ouest` a ete rapporte « axe
            # encore barre » alors que le tunnel etait parfaitement perce
            # (outil x[-22,780 .. 3,220]). Le sabotage etait bon, l'appel
            # etait faux, et le journal accusait la geometrie.
            rc, txt, _ = lancer(
                ["python3", "tools/cave_oracle_percee.py", glb,
                 "--depuis=" + args.graine,
                 "--vers=%g,%g,%g" % axe],
                journal=os.path.join(args.travail, "3_percee_%s.log" % nom))
            for ligne in txt.splitlines():
                if "RAYON LIBRE" in ligne or "traversees restantes" in ligne \
                        or "AXE " in ligne:
                    print("   %s" % ligne)
            fiche["percee_rc"] = rc
            for ligne in txt.splitlines():
                if "RAYON LIBRE" in ligne:
                    fiche["rayon_libre_m"] = float(ligne.split(":")[1]
                                                   .split("m")[0])
            # UN ECHEC D'OUTIL N'EST PAS UN CONSTAT SUR LA GEOMETRIE.
            # `cave_oracle_percee.py` rend 1 quand l'axe est reellement
            # barre — un fait mesure — et 2 ou 3 quand il n'a pas pu
            # mesurer. Les confondre revient a faire accuser le maillage
            # par un bug d'appel, ce qui est arrive ici meme.
            if rc >= 2:
                print("   BLOQUE : la mesure de percee n'a pas pu s'executer "
                      "(rc=%d). Ce n'est PAS un constat sur la geometrie."
                      % rc)
                fiche["etat"] = "BLOQUE"
                resultats.append(fiche)
                continue
            if rc == 1:
                print("   INEXPLOITABLE : l'axe est encore barre (mesure).")
                fiche["etat"] = "INEXPLOITABLE"
                resultats.append(fiche)
                continue

        # 4. verdict de l'oracle ------------------------------------------
        rc, txt, dt = lancer(
            ["python3", "tools/cave_oracle_global.py", glb,
             "--pas", "%.3f" % args.pas],
            journal=os.path.join(args.travail, "4_oracle_%s.log" % nom))
        verdict = "ROUGE" if rc == 1 else ("VERT" if rc == 0 else "BLOQUE")
        fiche["oracle_rc"] = rc
        fiche["verdict"] = verdict
        motifs = [l.strip() for l in txt.splitlines()
                  if l.strip().startswith(("C1 :", "C2 :", "C3 :", "C4 :",
                                           "T1 :", "T2 :", "T3 :"))]
        fiche["motifs"] = motifs
        print("   oracle en %.0f s : %s   (RC=%d)" % (dt, verdict, rc))
        for m in motifs:
            print("      %s" % m)
        fiche["etat"] = "CONFORME" if verdict == attendu else "NON CONFORME"
        print("   -> %s" % fiche["etat"])
        resultats.append(fiche)
        print()

    # 5 et 6. restauration + vert sur la source ----------------------------
    print("-" * 78)
    print("RESTAURATION ET VERT SUR LA SOURCE")
    print("-" * 78)
    sha_source_fin = sha256(entree)
    print("   sha256 source AVANT batterie : %s" % sha_source_debut)
    print("   sha256 source APRES batterie : %s" % sha_source_fin)
    identique = sha_source_debut == sha_source_fin
    print("   -> %s" % ("BYTE-IDENTIQUE" if identique
                        else "LA SOURCE A ETE MODIFIEE !"))
    rc, txt, dt = lancer(
        ["python3", "tools/cave_oracle_global.py", entree,
         "--pas", "%.3f" % args.pas],
        journal=os.path.join(args.travail, "5_source_restauree.log"))
    verdict_source = "ROUGE" if rc == 1 else ("VERT" if rc == 0 else "BLOQUE")
    print("   oracle sur la source en %.0f s : %s   (RC=%d)"
          % (dt, verdict_source, rc))

    print()
    print("=" * 78)
    print("%-18s %-8s %-8s %-14s %s"
          % ("controle", "attendu", "obtenu", "etat", "rayon libre"))
    print("-" * 78)
    for f in resultats:
        rl = ("%.3f m" % f["rayon_libre_m"]) if "rayon_libre_m" in f else "-"
        print("%-18s %-8s %-8s %-14s %s"
              % (f["nom"], f["attendu"], f.get("verdict", "-"),
                 f["etat"], rl))
    print("-" * 78)
    mauvais = [f for f in resultats if f["etat"] != "CONFORME"]
    ok = (not mauvais) and identique and verdict_source == "VERT"
    print("BATTERIE : %s" % ("CONFORME" if ok else "NON CONFORME"))
    print("=" * 78)

    if args.json:
        json.dump(dict(source=entree, sha256_debut=sha_source_debut,
                       sha256_fin=sha_source_fin, pas=args.pas,
                       rayon=args.rayon, resultats=resultats,
                       verdict_source=verdict_source),
                  open(args.json, "w"), indent=2)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
