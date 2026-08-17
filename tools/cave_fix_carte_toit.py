#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CARTE 2D du toit au-dessus du creux intérieur — hors Blender, hors moteur.

POURQUOI ELLE MANQUAIT
======================

Le profil de colonne à `x = 0,55` montre le pincement — 2,98 m à `ay 4,0`,
1,00 à 4,8, 0,52 à 5,2, 0,40 à 5,6, 0,075 à 6,0, puis 1,85 à 6,4 — mais UNE
colonne ne dit pas où poser une masse. Il faut l'emprise du creux et
l'emprise de la zone mince, en deux dimensions, sinon la correction est
posée au jugé et le défaut se contente de migrer de dix centimètres.

LA LECTURE DE COLONNE S'ÉCRIT UNE FOIS
======================================

`colonne_parite()`, et rien d'autre ne relit une liste d'impacts. Trois
verdicts faux ont été payés pour cette règle (`tools/CLAUDE.md`).

Ici la PARITÉ est licite, et ce n'est pas une commodité : le maillage livré
est fermé (0 arête de bord, établi par `cave_topology_check.py`), et au-
dessus du sommet du massif on est nécessairement dans l'air. On descend
donc en alternant air/roche. Le garde-fou est explicite : un nombre IMPAIR
de croisements signifie que le rayon FINIT DANS LA ROCHE — solide ouvert
par le bas — et la colonne est marquée, jamais lue comme si de rien n'était.

Vérifiée contre les impacts bruts en (0,55 ; 5,95) : `-2,613 · 0,111 ·
1,474 · 1,512` se lit roche 1,474→1,512, vide 0,111→1,474, roche
-2,613→0,111. C'est exactement ce que la sonde d'étape rend par enlacement
au même point.

Usage :
    python3 tools/cave_fix_carte_toit.py <glb> [--pas 0.10] [--vide 0.30]
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cave_void_connectivity import charger_triangles, intersections_verticales

## Emprise balayée, en repère MODÈLE. Elle déborde largement le creux connu
## pour que le bord de la carte ne soit jamais le bord du défaut.
X0, X1 = -2.60, 3.60
Y0, Y1 = 3.20, 8.60


def colonne_parite(triangles, ax, ay, vide_min):
    """Lit une verticale et rend (toit, cumul, z_plafond, z_sommet, etat).

    `toit`   : épaisseur du PREMIER banc de roche surmontant le vide
               qualifiant le plus haut — c'est lui qui dit « plaque » ;
    `cumul`  : toute la roche au-dessus de ce vide — « combien sépare du
               dehors » ;
    `etat`   : `ok`, `sans_vide`, `ciel` (vide qualifiant sans un gramme de
               roche au-dessus : c'est la PERCÉE, ou le ciel hors massif),
               `impair` (le rayon finit dans la roche — non lisible).

    On publie les deux épaisseurs parce qu'un seul nombre choisit la
    réponse avant de mesurer.
    """
    zs = sorted(intersections_verticales(triangles, ax, ay), reverse=True)
    if not zs:
        return (None, None, None, None, "hors_solide")
    if len(zs) % 2:
        return (None, None, None, zs[0], "impair")
    # Depuis le ciel : zs[0] entre dans la roche, zs[1] en sort, etc.
    bancs = [(zs[2 * k], zs[2 * k + 1]) for k in range(len(zs) // 2)]
    vides = [(zs[2 * k + 1], zs[2 * k + 2]) for k in range(len(zs) // 2 - 1)]
    for i, (haut, bas) in enumerate(vides):
        if haut - bas < vide_min:
            continue
        au_dessus = bancs[:i + 1]
        cumul = sum(h - b for h, b in au_dessus)
        return (au_dessus[-1][0] - au_dessus[-1][1], cumul, haut, zs[0], "ok")
    return (None, None, None, zs[0], "sans_vide")


def main():
    args = sys.argv[1:]
    if not args:
        print("usage: cave_fix_carte_toit.py <glb> [--pas p] [--vide v]")
        return 3
    chemin = args[0]
    pas = 0.10
    vide_min = 0.30
    for k, a in enumerate(args):
        if a == "--pas":
            pas = float(args[k + 1])
        if a == "--vide":
            vide_min = float(args[k + 1])
    if not os.path.isfile(chemin):
        print("BLOQUE: fichier absent : %s" % chemin)
        return 3

    tris = charger_triangles(chemin)
    seau = [t for t in tris
            if min(p[0] for p in t) < X1 + 1.0
            and max(p[0] for p in t) > X0 - 1.0
            and min(p[1] for p in t) < Y1 + 1.0
            and max(p[1] for p in t) > Y0 - 1.0]
    print("=== carte du toit — %s" % chemin)
    print("    %d triangles, %d dans le seau ; pas %.2f m, vide qualifiant "
          "%.2f m" % (len(tris), len(seau), pas, vide_min))

    nx = int(round((X1 - X0) / pas)) + 1
    ny = int(round((Y1 - Y0) / pas)) + 1
    grille = {}
    compte = dict(ok=0, ciel=0, sans_vide=0, impair=0, hors_solide=0)
    for j in range(ny):
        ay = Y0 + j * pas
        for i in range(nx):
            ax = X0 + i * pas
            toit, cumul, plafond, sommet, etat = colonne_parite(
                seau, ax, ay, vide_min)
            if etat == "ok" and toit is not None and toit < 1e-6:
                etat = "ciel"
            compte[etat] = compte.get(etat, 0) + 1
            grille[(i, j)] = (toit, cumul, plafond, sommet, etat)

    print("    colonnes : %d ok, %d ciel, %d sans vide, %d impair, %d hors"
          % (compte["ok"], compte["ciel"], compte["sans_vide"],
             compte["impair"], compte["hors_solide"]))

    minces = sorted((v[0], X0 + i * pas, Y0 + j * pas, v[2], v[1])
                    for (i, j), v in grille.items()
                    if v[4] == "ok" and v[0] is not None and v[0] < 0.80)
    print("    toit < 0,80 m : %d colonne(s)" % len(minces))
    for t, ax, ay, plafond, cumul in minces[:12]:
        print("      %.3f m en (%+.2f ; %.2f)  plafond %.2f  cumul %.3f"
              % (t, ax, ay, plafond, cumul))
    if minces:
        xs = [m[1] for m in minces]
        ys = [m[2] for m in minces]
        print("    EMPRISE des colonnes minces : x [%+.2f ; %+.2f]  "
              "y [%.2f ; %.2f]" % (min(xs), max(xs), min(ys), max(ys)))

    # LA CARTE. Un caractère par colonne, pour VOIR la forme du pincement —
    # une liste triée ne montre pas où poser une masse.
    print("    carte (lignes = ay croissant vers le bas, colonnes = ax) :")
    print("      legende : '#' >= 2 m   '+' >= 0,80 m   'x' < 0,80 m   "
          "'!' percee   '.' pas de vide   ' ' hors solide")
    entete = "        " + "".join(
        "%d" % (int(round((X0 + i * pas) * 10)) % 10) for i in range(nx))
    print(entete)
    for j in range(ny):
        ligne = []
        for i in range(nx):
            toit, cumul, plafond, sommet, etat = grille[(i, j)]
            if etat == "ciel":
                ligne.append("!")
            elif etat in ("sans_vide", "impair"):
                ligne.append(".")
            elif etat == "hors_solide":
                ligne.append(" ")
            elif toit is None:
                ligne.append("?")
            elif toit >= 2.0:
                ligne.append("#")
            elif toit >= 0.80:
                ligne.append("+")
            else:
                ligne.append("x")
        print("  %5.2f %s" % (Y0 + j * pas, "".join(ligne)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
