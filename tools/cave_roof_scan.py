#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Balayage du TOIT d'un `.glb` de grotte — reproduction indépendante.

Répond à une seule question, et la publie entièrement : **quelle est
l'épaisseur de la première roche surmontant un vide d'au moins `--vide`
mètres, et où ?**

Indépendant de Blender (donc du verrou d'outil lourd) et de sa BVH : si ce
balayage et celui de l'intégrateur tombent sur le même 0,038 m, le chiffre
ne dépend plus d'une implémentation. S'ils divergent, c'est un résultat en
soi et il faut s'arrêter là.

Toutes les coordonnées publiées sont en repère MODÈLE (ax, ay, z), le même
que `CAVITE` et que la cartographie du défaut.

Usage :
    python3 tools/cave_roof_scan.py <fichier.glb> [--x -2:3] [--y 4:7]
                                    [--pas 0.10] [--vide 1.00]
                                    [--carte] [--point ax,ay] [--json out]
"""

import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cave_roof_glb import (charger, colonne_depuis_impacts,   # noqa: E402
                           colonne_par_parite,
                           toit_au_dessus_d_un_vide, EPS_ECAILLE_M)

LECTURES = {"enlacement": colonne_depuis_impacts, "parite": colonne_par_parite}


def _plage(texte):
    lo, hi = texte.split(":")
    return float(lo), float(hi)


def _pas_de(lo, hi, pas):
    n = int(round((hi - lo) / pas))
    return [lo + i * pas for i in range(n + 1)]


def balayer(grille, xs, ys, vide_min, lecture=colonne_depuis_impacts):
    """Rend (minimum, carte, compte de colonnes ayant un vide qualifiant)."""
    mini = None
    carte = {}
    qualifiantes = 0
    for ay in ys:
        for ax in xs:
            impacts = grille.impacts(ax, ay)
            trouve = toit_au_dessus_d_un_vide(impacts, vide_min,
                                              lecture=lecture)
            carte[(round(ax, 4), round(ay, 4))] = trouve
            if trouve is None:
                continue
            qualifiantes += 1
            epaisseur, z_haut, vide = trouve
            if mini is None or epaisseur < mini["epaisseur"]:
                mini = dict(epaisseur=epaisseur, ax=ax, ay=ay,
                            z_haut=z_haut, vide=vide,
                            impacts=len(impacts))
    return mini, carte, qualifiantes


def detail_colonne(grille, ax, ay, lecture=colonne_depuis_impacts):
    impacts = grille.impacts(ax, ay)
    tranches, dans_roche = lecture(impacts)
    return impacts, tranches, dans_roche


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("glb")
    ap.add_argument("--x", default="-2:3")
    ap.add_argument("--y", default="4:7")
    ap.add_argument("--pas", type=float, default=0.10)
    ap.add_argument("--vide", type=float, default=1.00)
    ap.add_argument("--carte", action="store_true")
    ap.add_argument("--point", default=None,
                    help="ax,ay : detaille UNE colonne, tranche par tranche")
    ap.add_argument("--json", default=None)
    ap.add_argument("--lecture", default="enlacement",
                    choices=sorted(LECTURES),
                    help="enlacement (juste) ou parite (l'ancienne, pour "
                         "reproduire le chiffre conteste)")
    ap.add_argument("--comparer", action="store_true",
                    help="publie les deux lectures cote a cote")
    args = ap.parse_args()
    lecture = LECTURES[args.lecture]

    grille, empreinte, n_tris = charger(args.glb)
    print("fichier   : %s" % args.glb)
    print("sha256    : %s" % empreinte)
    print("triangles : %d" % n_tris)
    print("emprise   : ax [%.2f ; %.2f]  ay [%.2f ; %.2f]  z [%.2f ; %.2f]"
          % (grille.xmin, grille.xmax, grille.ymin, grille.ymax,
             grille.zmin, grille.zmax))
    print("ecaille   : les intervalles de roche < %.3f m ne sont pas des "
          "parois" % EPS_ECAILLE_M)

    if args.point:
        ax, ay = [float(v) for v in args.point.split(",")]
        impacts, tranches, dans_roche = detail_colonne(grille, ax, ay,
                                                       lecture)
        print()
        print("== colonne (%.2f ; %.2f), lecture %s : %d impact(s), "
              "finit %s ==" % (ax, ay, args.lecture, len(impacts),
                 "DANS LA ROCHE" if dans_roche else "dans l'AIR"))
        for nature, haut, bas in tranches:
            print("   %-5s  z %7.3f -> %7.3f   %.3f m"
                  % (nature, haut, bas, haut - bas))
        trouve = toit_au_dessus_d_un_vide(impacts, args.vide,
                                          lecture=lecture)
        if trouve:
            print("   -> toit %.3f m au-dessus d'un vide de %.3f m (z %.3f)"
                  % (trouve[0], trouve[2], trouve[1]))
        else:
            print("   -> aucune roche au-dessus d'un vide >= %.2f m"
                  % args.vide)
        return 0

    xs = _pas_de(*_plage(args.x), pas=args.pas)
    ys = _pas_de(*_plage(args.y), pas=args.pas)
    print("balayage  : x %s  y %s  pas %.2f m  -> %d colonnes"
          % (args.x, args.y, args.pas, len(xs) * len(ys)))
    print("vide qualifiant : >= %.2f m" % args.vide)

    mini, carte, qualifiantes = balayer(grille, xs, ys, args.vide, lecture)
    print()
    print("lecture   : %s" % args.lecture)
    print("colonnes avec un vide qualifiant : %d" % qualifiantes)
    if mini is None:
        print("TOIT MINIMAL : aucun (pas une seule colonne qualifiante)")
    else:
        print("TOIT MINIMAL %.3f m  en (%.2f ; %.2f)   vide dessous %.3f m   "
              "sommet z %.3f   %d impacts"
              % (mini["epaisseur"], mini["ax"], mini["ay"], mini["vide"],
                 mini["z_haut"], mini["impacts"]))

    if args.carte:
        print()
        print("== carte de l'epaisseur du toit (m), '.' = pas de vide "
              "qualifiant ==")
        entete = "   y  |" + "".join("%8.2f" % x for x in xs)
        print(entete)
        for ay in ys:
            ligne = "%6.2f |" % ay
            for ax in xs:
                t = carte[(round(ax, 4), round(ay, 4))]
                ligne += "%8s" % ("." if t is None else "%.3f" % t[0])
            print(ligne)

    if args.comparer:
        autre = "parite" if args.lecture == "enlacement" else "enlacement"
        m2, _, q2 = balayer(grille, xs, ys, args.vide, LECTURES[autre])
        print()
        print("== les deux lectures, meme geometrie, meme balayage ==")
        for nom, m, q in ((args.lecture, mini, qualifiantes), (autre, m2, q2)):
            if m is None:
                print("   %-11s  %4d colonne(s) qualifiante(s)  aucun toit"
                      % (nom, q))
            else:
                print("   %-11s  %4d colonne(s) qualifiante(s)  TOIT MINIMAL "
                      "%.3f m en (%.2f ; %.2f), vide %.3f m"
                      % (nom, q, m["epaisseur"], m["ax"], m["ay"], m["vide"]))

    if args.json:
        with open(args.json, "w", encoding="utf-8") as flux:
            json.dump(dict(glb=args.glb, sha256=empreinte, triangles=n_tris,
                           x=args.x, y=args.y, pas=args.pas, vide=args.vide,
                           colonnes_qualifiantes=qualifiantes,
                           minimum=mini), flux, indent=1)
        print("json -> %s" % args.json)
    return 0


if __name__ == "__main__":
    sys.exit(main())
