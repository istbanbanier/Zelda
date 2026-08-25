#!/usr/bin/env python3
"""VOIR CE QUE LE DÉTECTEUR VOIT — les masques 96x96 à 30 m, en ASCII.

Un IoU est un nombre ; il ne dit pas POURQUOI deux formes se ressemblent.
Ici on regarde les masques eux-mêmes, à la résolution exacte du verdict.
"""
import importlib.util, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("d3", "/home/user/wt1r1-a/tools/lot1_repetition.py")
d3 = importlib.util.module_from_spec(spec); spec.loader.exec_module(d3)

dossier = Path(sys.argv[1])
cibles = sys.argv[2:]
vues = d3.charger(dossier)
groupes = d3.par_sujet(vues)
for cible in cibles:
    for v in groupes.get(cible, []):
        m, _ = v.masque(30.0)
        print("=== %s  angle %g  (H %.2f m) ===" % (cible, v.angle, v.hauteur_m))
        for y in range(0, d3.TOILE, 2):
            print("".join("#" if m[y*d3.TOILE+x] else "." for x in range(0, d3.TOILE, 1)))
        print()
