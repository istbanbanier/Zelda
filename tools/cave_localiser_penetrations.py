#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""OU SONT LES PENETRATIONS ? — distribution le long du chemin de galerie.

POURQUOI CE FICHIER EXISTE
==========================
`COL_WaterfallCave` porte 62 penetrations reelles d'un enfoncement maximal
de 0,457 m, contre 7 a 0,020 m pour R2a-3.4. C'est une regression sur la
geometrie qui arrete le joueur, et « cause inconnue » est un statut honnete
mais peu utile.

L'hypothese a eprouver : la coque de collision sort d'un loft pilote par
`CAVITE`, et R2a-3.5.2 a coude la galerie de 42 degres a la station 3
(`ay = 1,62`) la ou R2a-3.4 etait quasi rectiligne. Un loft qui vire
brutalement replie ses sections A L'INTERIEUR du coude.

LE TEST, ET IL PEUT REFUTER
===========================
Si les penetrations se concentrent autour de la station 3, l'hypothese
tient et le ticket devient actionnable. Si elles sont dispersees le long du
chemin, l'hypothese TOMBE — et c'est un resultat, pas un echec.

On publie donc la distribution, pas un verdict : l'histogramme par station,
la position en `ay`, et l'enfoncement de chaque paire. Le lecteur voit la
forme de la distribution et juge lui-meme.

CE QU'IL NE FAIT PAS
====================
Il ne corrige rien. `COL_MARGE_LAT` et `COL_MARGE_CLE` sont des marges de
passage ; ce script ne les lit meme pas.
"""

import argparse
import math
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from cave_exact_intersect import (classer_paire, en_fractions,  # noqa
                                  lire_glb, maillage_par_nom,
                                  paires_candidates, profondeur_et_etendue,
                                  souder)

## Recopie de `CAVITE` du generateur — volontairement, pour que ce script
## reste lisible seul. Toute divergence se verrait immediatement : les
## stations ne tomberaient plus sur la geometrie.
CAVITE = [
    (0.00, -1.15, 1.90, 2.80),   # 0  porche evase
    (0.00, 0.00, 1.70, 2.85),    # 1  seuil
    (0.22, 1.05, 1.75, 2.90),    # 2  fin du vestibule
    (1.00, 1.62, 2.10, 2.90),    # 3  LE COUDE, 42 degres
    (1.82, 2.12, 2.60, 2.92),    # 4
    (2.62, 2.58, 3.00, 2.92),    # 5  salle
    (3.10, 2.88, 2.50, 2.80),    # 6
    (3.40, 3.06, 1.85, 2.45),    # 7  alcove / niche
    (3.58, 3.17, 1.30, 2.00),    # 8  calotte du fond
]


def vers_blender(point):
    """Le GLB est en Y-up : (x, y, z)_gltf = (x, z, -y)_blender.

    Donc l'inverse, celui dont on a besoin ici : (x, -z, y).
    """
    return (point[0], -point[2], point[1])


def station_la_plus_proche(x, y):
    """Indice de station fractionnaire le plus proche, et distance a l'axe.

    On projette sur chaque segment du polyligne (ax, ay) et on garde le
    meilleur. L'indice fractionnaire dit ou l'on se trouve entre deux
    stations nommees.
    """
    meilleur = (None, float("inf"))
    for i in range(len(CAVITE) - 1):
        ax0, ay0 = CAVITE[i][0], CAVITE[i][1]
        ax1, ay1 = CAVITE[i + 1][0], CAVITE[i + 1][1]
        dx, dy = ax1 - ax0, ay1 - ay0
        longueur2 = dx * dx + dy * dy
        if longueur2 == 0.0:
            continue
        t = ((x - ax0) * dx + (y - ay0) * dy) / longueur2
        t = max(0.0, min(1.0, t))
        px, py = ax0 + t * dx, ay0 + t * dy
        d = math.hypot(x - px, y - py)
        if d < meilleur[1]:
            meilleur = (i + t, d)
    return meilleur


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("glb")
    ap.add_argument("--maillage", default="COL_WaterfallCave")
    ap.add_argument("--pas", type=float, default=0.25)
    args = ap.parse_args()

    gltf, blob = lire_glb(args.glb)
    positions, triangles = maillage_par_nom(gltf, blob)[args.maillage]
    sommets, tris = souder(positions, triangles)
    frac = en_fractions(sommets)

    print("[ou] fichier   %s" % args.glb)
    print("[ou] maillage  %s : %d sommets, %d triangles"
          % (args.maillage, len(sommets), len(tris)))

    trouvailles = []
    for a, b in paires_candidates(sommets, tris, args.pas):
        verdict, details = classer_paire([frac[i] for i in tris[a]],
                                         [frac[i] for i in tris[b]])
        if verdict != "PENETRATION":
            continue
        point = tuple(float(c) for c in details[0])
        prof, etendue = profondeur_et_etendue(details)
        bx, by, bz = vers_blender(point)
        station, ecart = station_la_plus_proche(bx, by)
        trouvailles.append((station, ecart, bx, by, bz, prof, etendue))

    print("[ou] penetrations : %d" % len(trouvailles))
    if not trouvailles:
        return 0

    trouvailles.sort()
    print("[ou]")
    print("[ou] station  ay      ecart axe  enfoncement  couture   position "
          "Blender")
    for station, ecart, bx, by, bz, prof, etendue in trouvailles:
        print("[ou]  %5.2f  %+6.3f   %6.3f m   %9.6f m  %7.4f m  "
              "(%+.3f, %+.3f, %+.3f)"
              % (station, by, ecart, prof, etendue, bx, by, bz))

    paniers = defaultdict(list)
    for station, _e, _x, _y, _z, prof, _et in trouvailles:
        paniers[int(round(station))].append(prof)
    print("[ou]")
    print("[ou] HISTOGRAMME PAR STATION (le coude est la station 3, ay=1.62)")
    total = len(trouvailles)
    for i in range(len(CAVITE)):
        liste = paniers.get(i, [])
        barre = "#" * int(round(40.0 * len(liste) / max(1, total)))
        note = "  <-- LE COUDE, 42 deg" if i == 3 else ""
        print("[ou]   station %d (ax %.2f, ay %+.2f) : %3d  %-40s  "
              "enfoncement max %.6f m%s"
              % (i, CAVITE[i][0], CAVITE[i][1], len(liste), barre,
                 max(liste) if liste else 0.0, note))

    proches = [t for t in trouvailles if 2.5 <= t[0] <= 3.5]
    print("[ou]")
    print("[ou] concentration autour du coude (station 2.5 a 3.5) : "
          "%d sur %d, soit %.0f %%"
          % (len(proches), total, 100.0 * len(proches) / total))
    return 0


if __name__ == "__main__":
    sys.exit(main())
