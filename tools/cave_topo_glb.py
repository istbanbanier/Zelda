#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""TOPOLOGIE D'UN GLB — bords libres, non-manifold, composantes, genre.

POURQUOI CE FICHIER EXISTE PLUTOT QUE `cave_topology_check.py`
==============================================================
`cave_topology_check.py` portait, au socle de cette passe, des chemins
absolus vers un worktree supprime. Il a ete repare au tronc, mais le tronc
est POSTERIEUR a mon socle et fusionner pour un controle de non-regression
melangerait ce que je mesure avec ce que je n'ai pas mesure.

Celui-ci prend son chemin en argument, n'a aucun defaut, et ne depend que
du GLB. Il soude par POSITION avant de compter : un GLB stocke une primitive
PAR MATERIAU — six pour la grotte — et compter les aretes sans souder
rendrait des bords libres partout ou il n'y en a aucun.
"""

import argparse
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from cave_exact_intersect import lire_glb, maillage_par_nom, souder  # noqa


def analyser(nom, sommets, triangles):
    aretes = defaultdict(int)
    for a, b, c in triangles:
        for u, v in ((a, b), (b, c), (c, a)):
            aretes[(u, v) if u < v else (v, u)] += 1
    bords = sum(1 for n in aretes.values() if n == 1)
    non_manifold = sum(1 for n in aretes.values() if n > 2)

    # composantes connexes par union-find sur les sommets reellement utilises
    parent = {}

    def racine(x):
        parent.setdefault(x, x)
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for a, b, c in triangles:
        ra, rb, rc = racine(a), racine(b), racine(c)
        parent[rb] = ra
        parent[racine(rc)] = ra
    composantes = len({racine(x) for x in parent})

    V = len({i for tri in triangles for i in tri})
    E = len(aretes)
    F = len(triangles)
    khi = V - E + F
    print("[topo] %s" % nom)
    print("[topo]   V=%d  E=%d  F=%d" % (V, E, F))
    print("[topo]   aretes de bord libre : %d" % bords)
    print("[topo]   aretes non-manifold  : %d" % non_manifold)
    print("[topo]   composantes connexes : %d" % composantes)
    print("[topo]   khi = %d" % khi)
    if bords == 0 and non_manifold == 0:
        genre = (2 * composantes - khi) / 2
        print("[topo]   genre = %.1f  (khi = 2*C - 2g)" % genre)
    else:
        print("[topo]   genre NON DEFINI : la surface n'est pas fermee "
              "manifold")
    return bords, non_manifold, composantes, khi


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("glb")
    args = ap.parse_args()
    gltf, blob = lire_glb(args.glb)
    print("[topo] fichier %s" % args.glb)
    for nom, (positions, triangles) in sorted(maillage_par_nom(gltf,
                                                               blob).items()):
        sommets, tris = souder(positions, triangles)
        analyser(nom, sommets, tris)
    return 0


if __name__ == "__main__":
    sys.exit(main())
