#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""PLAQUE ou BORD — la distinction sans laquelle le balayage vertical ment.

LE PROBLÈME, ET IL EST GÉOMÉTRIQUE, PAS NUMÉRIQUE
=================================================

Un rayon vertical qui mesure « la roche au-dessus d'un vide » rend une
valeur qui tend vers ZÉRO partout où un vide se termine latéralement. Au
bord exact d'un porche, d'un surplomb ou d'une salle, l'épaisseur verticale
de la roche EST nulle : c'est la définition d'un bord, pas un défaut.

Mesuré sur les trois géométries, le minimum du domaine complet tombe
toujours sur un tel bord — y compris sur la géométrie LIVRÉE R2a-3.4, qui
rend 0,006 m. Prendre ce nombre pour « une lame de roche » condamnerait
n'importe quelle grotte jamais modélisée, y compris celle qui est en
production depuis des semaines.

LE CRITÈRE
==========

Une colonne mince est une **plaque** si le vide qualifiant continue autour
d'elle : on exige qu'au moins `--voisins` de ses 8 voisins, au pas du
balayage, présentent eux aussi un vide qualifiant. Une colonne mince dont
les voisins n'ont pas de vide est un **bord** : le vide s'y termine.

Ce n'est pas une excuse pour ignorer les minces. Les deux populations sont
comptées et publiées séparément, avec leur minimum respectif. Le lead
tranche ensuite en connaissance de cause — ce que personne ne pouvait faire
tant qu'un seul nombre mélangeait les deux.

Usage :
    python3 tools/cave_roof_plaques.py <glb> [--x a:b] [--y a:b] [--pas .]
                                       [--vide 1.0] [--seuil 0.80]
                                       [--voisins 6]
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cave_roof_glb import (charger,                           # noqa: E402
                           toit_au_dessus_d_un_vide,
                           toit_cumule_au_dessus_d_un_vide)
from cave_roof_scan import _pas_de, _plage                    # noqa: E402

## DEUX MESURES, ET ELLES NE REPONDENT PAS A LA MEME QUESTION.
##
## `premiere` : l'epaisseur du PREMIER banc de roche surmontant un vide
##   qualifiant. Elle repond a « y a-t-il une plaque mince quelque part »,
##   qui est la lettre du contrat (« nulle part une plaque »).
##
## `cumul`    : TOUTE la roche separant du ciel le vide qualifiant le plus
##   haut. Elle repond a « combien de roche separe la galerie du dehors »,
##   qui est la definition que `controle_epaisseur` se donne a lui-meme.
##
## Elles divergent des qu'une colonne porte PLUSIEURS bancs separes par un
## vide non qualifiant. Mesure sur R2a-3.4 en (-0,20 ; -2,60) :
##     roche 0,957 | vide 0,471 | roche 0,020 | vide 2,768 | roche 2,602
## Le vide de 0,471 m ne qualifie pas : `premiere` enjambe donc le banc
## epais et tombe sur la lame de 2 cm ; `cumul` additionne 0,957 + 0,020 =
## 0,977 m et passe le seuil. La lame de 2 cm est REELLE — verifiee dans
## huit directions independantes — et elle est plus mince que le defaut qui
## a arrete la passe precedente.
##
## Aucune des deux n'est « la bonne » : on publie LES DEUX, et l'arbitrage
## appartient au lead.
MESURES = {"premiere": toit_au_dessus_d_un_vide,
           "cumul": toit_cumule_au_dessus_d_un_vide}


def balayer(grille, xs, ys, vide_min, mesure):
    mini, carte, qualifiantes = None, {}, 0
    for ay in ys:
        for ax in xs:
            trouve = mesure(grille.impacts(ax, ay), vide_min)
            carte[(round(ax, 4), round(ay, 4))] = trouve
            if trouve is None:
                continue
            qualifiantes += 1
            if mini is None or trouve[0] < mini["epaisseur"]:
                mini = dict(epaisseur=trouve[0], ax=ax, ay=ay)
    return mini, carte, qualifiantes


def classer(carte, xs, ys, pas, seuil, voisins_min):
    """Rend (plaques, bords) : listes de (epaisseur, ax, ay, vide, n_voisins)."""
    def cle(ax, ay):
        return (round(ax, 4), round(ay, 4))

    plaques, bords = [], []
    for ay in ys:
        for ax in xs:
            trouve = carte.get(cle(ax, ay))
            if trouve is None or trouve[0] >= seuil:
                continue
            if len(trouve) > 3 and trouve[3] == 0:
                continue          # aucun banc : la bouche ou le ciel
            n = 0
            for dx in (-pas, 0.0, pas):
                for dy in (-pas, 0.0, pas):
                    if dx == 0.0 and dy == 0.0:
                        continue
                    if carte.get(cle(ax + dx, ay + dy)) is not None:
                        n += 1
            entree = (trouve[0], ax, ay, trouve[2], n)
            (plaques if n >= voisins_min else bords).append(entree)
    plaques.sort()
    bords.sort()
    return plaques, bords


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("glb")
    ap.add_argument("--x", default="-9:9")
    ap.add_argument("--y", default="-4:12.5")
    ap.add_argument("--pas", type=float, default=0.10)
    ap.add_argument("--vide", type=float, default=1.00)
    ap.add_argument("--seuil", type=float, default=0.80)
    ap.add_argument("--voisins", type=int, default=6)
    ap.add_argument("--mesure", default="premiere", choices=sorted(MESURES))
    args = ap.parse_args()

    grille, empreinte, n_tris = charger(args.glb)
    xs = _pas_de(*_plage(args.x), pas=args.pas)
    ys = _pas_de(*_plage(args.y), pas=args.pas)
    print("fichier   : %s" % args.glb)
    print("sha256    : %s" % empreinte)
    print("triangles : %d" % n_tris)
    print("balayage  : x %s  y %s  pas %.2f m  -> %d colonnes"
          % (args.x, args.y, args.pas, len(xs) * len(ys)))
    print("seuil de mince : %.2f m ; vide qualifiant >= %.2f m ; plaque si "
          ">= %d des 8 voisins ont un vide" % (args.seuil, args.vide,
                                               args.voisins))

    print("mesure    : %s" % args.mesure)
    mini, carte, qualifiantes = balayer(grille, xs, ys, args.vide,
                                        MESURES[args.mesure])
    plaques, bords = classer(carte, xs, ys, args.pas, args.seuil,
                             args.voisins)
    print()
    print("colonnes avec un vide qualifiant : %d" % qualifiantes)
    print("colonnes MINCES (< %.2f m) : %d, dont %d plaque(s) et %d bord(s)"
          % (args.seuil, len(plaques) + len(bords), len(plaques), len(bords)))
    print()
    if bords:
        e, ax, ay, v, n = bords[0]
        print("BORD le plus mince    : %.3f m en (%.2f ; %.2f), vide %.3f m, "
              "%d voisin(s) — terminaison laterale, pas une lame"
              % (e, ax, ay, v, n))
    if plaques:
        print("PLAQUE la plus mince  : %.3f m en (%.2f ; %.2f), vide %.3f m, "
              "%d voisin(s)" % (plaques[0][0], plaques[0][1], plaques[0][2],
                                plaques[0][3], plaques[0][4]))
        print()
        print("les 10 plaques les plus minces :")
        for e, ax, ay, v, n in plaques[:10]:
            print("   %.3f m  en (%6.2f ; %6.2f)  vide %.3f m  %d voisins"
                  % (e, ax, ay, v, n))
    else:
        print("PLAQUE la plus mince  : AUCUNE — toutes les colonnes minces "
              "sont des bords")
    return 0


if __name__ == "__main__":
    sys.exit(main())
