#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""MESURE INDEPENDANTE DE LA PERCEE — le sabotage a-t-il vraiment ouvert ?

POURQUOI CETTE MESURE EST SEPAREE DU VERDICT
============================================

Echec du 2026-08-16, consigne dans `cave_seal_oracle.py` : un percement
retirait 39 triangles, la geometrie changeait pour de bon, et l'oracle
repondait ETANCHE. Le trou etait ouvert au sens de la geometrie et FERME au
sens de la grille — les triangles voisins couvraient encore l'ouverture.

Conclusion, et elle est generale : **un sabotage se prouve par la LARGEUR
qu'il ouvre, jamais par le nombre de triangles qu'il touche.** Cette mesure
doit donc exister a cote de l'oracle et non dedans : un instrument qui
mesurerait lui-meme la validite de sa propre epreuve ne prouverait rien.

CE QU'ELLE MESURE
=================

  `--rayon-libre`  On tire des rayons PARALLELES a l'axe, sur des cercles de
                   rayon croissant autour de lui. Le rayon libre est la plus
                   grande distance a laquelle AUCUN rayon ne rencontre plus
                   rien. C'est la largeur reellement traversante, pas la
                   largeur de l'outil qui a servi a percer.

  `--traversees`   La liste des cotes de traversee le long de l'axe, avec
                   leur orientation. Avant sabotage : une paire entree/sortie
                   par paroi. Apres : plus rien, si la percee est complete.

Repere : MODELE Blender. Le noeud mesure est `SM_WaterfallCave` sauf
`--noeud` explicite ; `COL_WaterfallCave` est le proxy de collision et n'est
jamais mesure par defaut.

Usage :
    python3 tools/cave_oracle_percee.py <glb> --depuis 2.62,2.58,0.99 \\
            --vers 0,0,1 [--rayon-max 1.20] [--pas 0.02]

Codes de sortie : 0 = axe TRAVERSANT (aucune traversee restante) ·
1 = axe encore barre · 3 = BLOQUE.
"""

import argparse
import hashlib
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import probe_cave_openings as P                                # noqa: E402
import cave_oracle_global as O                                 # noqa: E402


def base_orthonormale(direction):
    n = math.sqrt(sum(v * v for v in direction))
    if n < 1e-9:
        raise ValueError("direction nulle")
    d = tuple(v / n for v in direction)
    ref = (0.0, 0.0, 1.0) if abs(d[2]) < 0.9 else (1.0, 0.0, 0.0)
    u = (d[1] * ref[2] - d[2] * ref[1], d[2] * ref[0] - d[0] * ref[2],
         d[0] * ref[1] - d[1] * ref[0])
    nu = math.sqrt(sum(v * v for v in u)) or 1.0
    u = tuple(v / nu for v in u)
    w = (d[1] * u[2] - d[2] * u[1], d[2] * u[0] - d[0] * u[2],
         d[0] * u[1] - d[1] * u[0])
    return d, u, w


def rayon_libre(grille, origine, direction, rayon_max=1.20, pas=0.02,
                secteurs=16, portee=60.0):
    """Plus grand rayon ou AUCUN rayon parallele ne rencontre de face.

    `secteurs=16` et non 8 : un tunnel cylindrique perce par un booleen a
    64 segments laisse des aretes; huit directions peuvent toutes tomber
    entre deux aretes et surestimer l'ouverture.
    """
    d, u, w = base_orthonormale(direction)
    libre = 0.0
    r = 0.0
    while r <= rayon_max + 1e-9:
        propre = True
        for k in range(secteurs):
            a = 2.0 * math.pi * k / secteurs
            dep = tuple(origine[m] + r * (math.cos(a) * u[m]
                                          + math.sin(a) * w[m])
                        for m in range(3))
            if O.traversees(grille, dep, d, portee):
                propre = False
                break
        if not propre:
            break
        libre = r
        r += pas
    return libre


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("glb")
    ap.add_argument("--noeud", default=O.NOEUD_DEFAUT)
    ap.add_argument("--depuis", required=True, help="x,y,z repere MODELE")
    ap.add_argument("--vers", required=True, help="dx,dy,dz")
    ap.add_argument("--rayon-max", type=float, default=1.20)
    ap.add_argument("--pas", type=float, default=0.02)
    args = ap.parse_args()

    if not os.path.isfile(args.glb):
        print("BLOQUE : maillage introuvable : %s" % args.glb)
        return 3
    sha = hashlib.sha256(open(args.glb, "rb").read()).hexdigest()
    try:
        tris, _ = P.triangles_du_glb(args.glb, args.noeud)
    except Exception as exc:                                   # noqa: BLE001
        print("BLOQUE : %s" % exc)
        return 3

    origine = tuple(float(v) for v in args.depuis.split(","))
    direction = tuple(float(v) for v in args.vers.split(","))
    grille = P.Grille(tris)

    print("maillage : %s" % args.glb)
    print("sha256   : %s" % sha)
    print("noeud    : %s   triangles : %d" % (args.noeud, len(tris)))
    print("axe      : depuis (%.3f ; %.3f ; %.3f) vers (%.2f ; %.2f ; %.2f)"
          % (origine + direction))

    d, _, _ = base_orthonormale(direction)
    tr = O.traversees(grille, origine, d, 60.0)
    print("traversees restantes sur l'axe : %d" % len(tr))
    for t, s in tr:
        p = tuple(origine[k] + d[k] * t for k in range(3))
        print("   t=%7.3f m  %s  en (%.3f ; %.3f ; %.3f)"
              % (t, "ENTRE dans le solide" if s < 0 else "SORT du solide",
                 p[0], p[1], p[2]))

    libre = rayon_libre(grille, origine, d, args.rayon_max, args.pas)
    print("RAYON LIBRE MESURE : %.3f m   (diametre libre %.3f m)"
          % (libre, 2.0 * libre))

    if tr:
        print("AXE ENCORE BARRE : %d traversee(s) subsistent. Un sabotage "
              "qui n'ouvre pas ne prouve RIEN du verdict qu'il produit."
              % len(tr))
        return 1
    print("AXE TRAVERSANT : plus aucune face sur l'axe, de la graine "
          "jusqu'au dehors.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
