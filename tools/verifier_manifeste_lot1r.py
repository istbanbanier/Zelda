#!/usr/bin/env python3
"""Contrôle d'intégrité des lignes du lot 1.R dans ASSET_MANIFEST.csv.

POURQUOI CET OUTIL EXISTE. Le journal de cueillette affirmait que les quatre
lignes du lot avaient été écrites « avec les valeurs relues par le lead sur
l'arbre intégré ». C'était vrai pour deux d'entre elles. Pour la tour, le
sha256 recopié du rapport de voie (`8d1b56bf…`) ne correspondait à AUCUNE
version du GLB dans l'histoire — le seul blob existant vaut `d7c710e9…`. Pour
le cimetière, la note ANNONÇAIT un sha256 recalculé sans jamais l'écrire.

Aucun test ne lit ce fichier : c'est exactement la panne silencieuse d'ISS-066
appliquée au manifeste. Cet outil rend la vérification exécutable.

CE QU'IL VÉRIFIE, pour chaque ligne visée : le fichier d'export existe, son
sha256 commence bien par le préfixe inscrit dans les notes, et l'éventuel
nombre d'octets annoncé correspond à la taille réelle.

PIÈGE ÉVITÉ (PROMPT4_METHOD §2) : ne jamais comparer une valeur à elle-même.
Une ligne sans sha inscrit est un ÉCHEC, pas un succès silencieux — la
première version de ce contrôle affichait « OK » quand les deux côtés valaient
« — », et aurait donc validé n'importe quoi.

Usage : python3 tools/verifier_manifeste_lot1r.py
Codes : 0 = toutes conformes · 1 = au moins un écart · 3 = manifeste illisible
"""

from __future__ import annotations

import csv
import hashlib
import os
import re
import sys

MANIFESTE = "docs/assets/ASSET_MANIFEST.csv"
LIGNES_LOT1R = (
    "SM_Watchtower_Ruin",
    "SM_Shrine_Vestige",
    "SM_Barrow_Stones",
    "SM_FlowerField_Steles",
)


def main() -> int:
    if not os.path.exists(MANIFESTE):
        print(f"BLOQUÉ: manifeste absent — {MANIFESTE}", file=sys.stderr)
        return 3
    with open(MANIFESTE, encoding="utf-8") as fichier:
        lignes = list(csv.reader(fichier))
    entete = lignes[0]

    vus: dict[str, list[str]] = {}
    ecarts: list[str] = []
    for ligne in lignes[1:]:
        if not ligne or ligne[0] not in LIGNES_LOT1R:
            continue
        champs = dict(zip(entete, ligne))
        chemin = champs.get("export", "")
        notes = champs.get("notes", "")
        vus[ligne[0]] = [chemin, notes]

        if not chemin or not os.path.exists(chemin):
            ecarts.append(f"{ligne[0]}: export introuvable — {chemin!r}")
            continue
        octets_reels = os.path.getsize(chemin)
        with open(chemin, "rb") as binaire:
            empreinte = hashlib.sha256(binaire.read()).hexdigest()

        trouve = re.search(r"sha256\s+([0-9a-f]{8,64})", notes)
        if trouve is None:
            ecarts.append(f"{ligne[0]}: aucun sha256 inscrit dans les notes")
        elif not empreinte.startswith(trouve.group(1)):
            ecarts.append(
                f"{ligne[0]}: sha256 inscrit {trouve.group(1)} ≠ disque "
                f"{empreinte[:len(trouve.group(1))]}")
        else:
            print(f"  OK    {ligne[0]:24s} sha256 {trouve.group(1)} · "
                  f"{octets_reels} o")

        # LE DERNIER nombre d'octets fait foi, pas le premier. Une note du lot
        # cite d'abord la valeur PÉRIMÉE du rapport de voie, puis la valeur
        # juste (« le rapport annonçait 91 592 octets ; les valeurs justes
        # sont … 91 588 octets »). Le premier jet de ce contrôle prenait la
        # première occurrence et rougissait sur une ligne CORRECTE — un
        # garde-fou qui rougit à tort finit désactivé dans l'heure.
        octets_dits = re.findall(r"([0-9][0-9  ]{3,})\s*octets", notes)
        if octets_dits:
            annonce = int(re.sub(r"[^0-9]", "", octets_dits[-1]))
            if annonce != octets_reels:
                ecarts.append(
                    f"{ligne[0]}: {annonce} octets annoncés ≠ "
                    f"{octets_reels} réels")

    manquantes = [nom for nom in LIGNES_LOT1R if nom not in vus]
    for nom in manquantes:
        ecarts.append(f"{nom}: ligne absente du manifeste")

    print(f"-> {len(vus)}/{len(LIGNES_LOT1R)} lignes examinées, "
          f"{len(ecarts)} écart(s)")
    for message in ecarts:
        print(f"  ÉCART {message}", file=sys.stderr)
    return 1 if ecarts else 0


if __name__ == "__main__":
    sys.exit(main())
