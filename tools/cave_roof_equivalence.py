#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""PREUVE que l'accumulation verticale vaut l'enlacement multi-directionnel.

Le balayage du toit lit chaque colonne avec UN rayon vertical et accumule
les traversées signées. C'est mille fois moins cher que de calculer un
enlacement dans huit directions pour chaque altitude — mais ce n'est
légitime que si les deux donnent le même dedans/dehors.

Ce script tire des points au hasard dans un volume, calcule les deux, et
échoue si un seul point diverge. Sans lui, le balayage rapide serait une
commodité qu'on croit sur parole ; avec lui, c'est une méthode vérifiée.

Il fait aussi son propre contrôle de pertinence : si l'échantillon ne
contient pas À LA FOIS des points dans la matière et des points dans le
vide, l'accord ne prouve rien et le script sort en 3 (BLOQUÉ). Un test qui
ne peut pas échouer est le mode de panne nommé par `PROMPT4_METHOD` §2.

Usage :
    python3 tools/cave_roof_equivalence.py <glb> [--n 150] [--graine 7]
                                           [--x -2:3] [--y 4:7] [--z -1:5]
"""

import argparse
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cave_roof_glb import (charger, triangles_modele,        # noqa: E402
                           colonne_depuis_impacts)
from cave_roof_winding import enlacement                     # noqa: E402


def occupation_verticale(grille, ax, ay, z):
    """Dedans/dehors en (ax, ay, z) par la seule colonne verticale."""
    tranches, _ = colonne_depuis_impacts(grille.impacts(ax, ay))
    for nature, haut, bas in tranches:
        if bas <= z <= haut:
            return nature == "roche"
    return False            # au-dessus du sommet ou sous la base : dehors


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("glb")
    ap.add_argument("--n", type=int, default=150)
    ap.add_argument("--graine", type=int, default=7)
    ap.add_argument("--x", default="-2:3")
    ap.add_argument("--y", default="4:7")
    ap.add_argument("--z", default="-1:5")
    args = ap.parse_args()

    grille, empreinte, n_tris = charger(args.glb)
    tris = triangles_modele(args.glb)
    x0, x1 = [float(v) for v in args.x.split(":")]
    y0, y1 = [float(v) for v in args.y.split(":")]
    z0, z1 = [float(v) for v in args.z.split(":")]

    print("fichier   : %s" % args.glb)
    print("sha256    : %s" % empreinte)
    print("triangles : %d" % n_tris)
    print("echantillon : %d points, graine %d, dans x[%s] y[%s] z[%s]"
          % (args.n, args.graine, args.x, args.y, args.z))

    alea = random.Random(args.graine)
    dedans = dehors = 0
    divergences, indecis = [], []
    for _ in range(args.n):
        ax = alea.uniform(x0, x1)
        ay = alea.uniform(y0, y1)
        z = alea.uniform(z0, z1)
        val, accord, votes = enlacement(tris, (ax, ay, z))
        if not accord:
            indecis.append((ax, ay, z, votes))
            continue
        ref = (val >= 1)
        obt = occupation_verticale(grille, ax, ay, z)
        if ref:
            dedans += 1
        else:
            dehors += 1
        if ref != obt:
            divergences.append((ax, ay, z, val, obt))

    print()
    print("points dans la matiere : %d" % dedans)
    print("points dans le vide    : %d" % dehors)
    print("points indecis (desaccord entre directions) : %d" % len(indecis))
    for ax, ay, z, votes in indecis[:5]:
        print("   (%.3f ; %.3f ; %.3f) votes %s" % (ax, ay, z, votes))
    print("divergences colonne verticale <-> enlacement : %d"
          % len(divergences))
    for ax, ay, z, val, obt in divergences[:10]:
        print("   (%.3f ; %.3f ; %.3f) enlacement %+d, colonne dit %s"
              % (ax, ay, z, val, "roche" if obt else "vide"))

    if dedans == 0 or dehors == 0:
        print()
        print("BLOQUE: l'echantillon ne contient pas les deux etats "
              "(%d dedans, %d dehors) — l'accord ne prouve rien"
              % (dedans, dehors))
        return 3
    if divergences:
        print()
        print("ROUGE: %d divergence(s) — le balayage rapide n'est PAS "
              "equivalent, il ne doit pas etre utilise" % len(divergences))
        return 1
    print()
    print("VERT: les deux methodes s'accordent sur %d points couvrant les "
          "deux etats ; le balayage vertical rapide est legitime"
          % (dedans + dehors))
    return 0


if __name__ == "__main__":
    sys.exit(main())
