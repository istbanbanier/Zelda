#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CONTROLE NEGATIF du desamorcage — le correctif mord-il, et POURQUOI ?

« Un controle qui n'a jamais rougi n'est pas un controle. » Et, leçon de la
passe precedente : un rouge obtenu pour une AUTRE cause que celle annoncee
rend le verdict entierement faux.

CE QUI EST EPROUVE
==================
Le correctif `_desamorcer_ngones_colineaires()` affirme trois choses :

  1. le maillage Blender apres soustraction ne porte AUCUNE face d'aire
     nulle, mais porte un n-gone a triplet consecutif colineaire ;
  2. c'est la TRIANGULATION D'EXPORT qui fabrique le triangle plat ;
  3. trianguler ce n-gone en amont supprime la possibilite meme.

Le controle negatif doit donc rejouer l'etat SANS correctif et retrouver le
triangle plat A LA MEME POSITION. Un rouge ailleurs ne prouverait rien.

PROTOCOLE
=========
  a. charger le .blend produit par la chaine CORRIGEE ;
  b. mesurer : 0 face d'aire nulle attendu, 0 n-gone colineaire attendu ;
  c. RETABLIR la condition fautive en refusionnant le n-gone desamorce —
     on ne peut pas defaire une triangulation a l'identique, donc on
     procede autrement, voir plus bas ;
  d. exporter, mesurer, obtenir le ROUGE a la position annoncee ;
  e. restaurer, obtenir le VERT.

POURQUOI ON NE « DEFAIT » PAS LA TRIANGULATION
==============================================
Refusionner des triangles en n-gone ne redonne pas l'ordre de sommets
d'origine, et l'exportateur triangule selon cet ordre. Un tel controle
negatif testerait ma capacite a reconstruire un n-gone, pas la cause.

On procede donc a l'envers, et c'est plus honnete : on prend le .blend
NON corrige — celui de reference, produit par le socle intact — et on
verifie que l'export en tire le triangle plat a la position annoncee. C'est
la meme demonstration, mais avec un temoin reel au lieu d'un temoin
reconstruit.
"""

import argparse
import os
import sys
from fractions import Fraction

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ICI)

from cave_exact_intersect import (aire_double_carree, en_fractions,  # noqa
                                  lire_glb, maillage_par_nom, souder)

## La position annoncee du triangle plat, en repere GLB (Y-up).
POSITION_ANNONCEE = (-1.5044, -0.6392, 3.0989)
RAYON = 0.05


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("glb")
    ap.add_argument("--attendu", choices=("rouge", "vert"), required=True,
                    help="rouge = on EXIGE le triangle plat a la position "
                         "annoncee ; vert = on exige son absence")
    args = ap.parse_args()

    gltf, blob = lire_glb(args.glb)
    positions, triangles = maillage_par_nom(gltf, blob)["SM_WaterfallCave"]
    sommets, tris = souder(positions, triangles)
    frac = en_fractions(sommets)

    nulles = []
    for indice, tri in enumerate(tris):
        if aire_double_carree([frac[i] for i in tri]) == 0:
            pts = [sommets[i] for i in tri]
            centre = tuple(sum(p[k] for p in pts) / 3.0 for k in range(3))
            nulles.append((indice, centre))

    print("[negatif] %s" % args.glb)
    print("[negatif] triangles d'aire EXACTEMENT nulle : %d" % len(nulles))
    a_la_position = []
    for indice, centre in nulles:
        proche = all(abs(centre[k] - POSITION_ANNONCEE[k]) <= RAYON
                     for k in range(3))
        print("[negatif]   face %d en (%.4f, %.4f, %.4f)%s"
              % ((indice,) + centre + (" <-- POSITION ANNONCEE" if proche
                                       else " (AILLEURS)",)))
        if proche:
            a_la_position.append(indice)

    if args.attendu == "rouge":
        if a_la_position:
            print("[negatif] ROUGE OBTENU, ET A LA CAUSE ANNONCEE : %d "
                  "triangle(s) plat(s) en %s" % (len(a_la_position),
                                                 (POSITION_ANNONCEE,)))
            return 0
        if nulles:
            print("[negatif] ECHEC DU CONTROLE : il y a du rouge, mais PAS a "
                  "la position annoncee. Un rouge obtenu pour une autre "
                  "cause ne compte pas.")
            return 1
        print("[negatif] ECHEC DU CONTROLE : aucun triangle plat, alors que "
              "le temoin non corrige devait en porter un.")
        return 1

    if nulles:
        print("[negatif] ECHEC : le correctif devait rendre 0 triangle plat")
        return 1
    print("[negatif] VERT : aucun triangle d'aire nulle")
    return 0


if __name__ == "__main__":
    sys.exit(main())
