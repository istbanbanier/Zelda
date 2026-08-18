#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""EPAISSEUR DE ROCHE DE LA COQUE DE COLLISION, sommet par sommet.

CONVENTION DE CODES RETOUR — R2a-3.5.7, ICI SEULEMENT
=====================================================
    0 = PASS      1 = FAIL (epaisseur negative quelque part)
    3 = BLOQUE    >=4 = erreur d'outil

POURQUOI CE FICHIER EXISTE
==========================
Le generateur controle `EPAISSEUR_MIN_M = 0,80` sur le maillage VISIBLE.
`COL_WaterfallCave` n'y passe pas : c'est une autre coque, batie avec
d'autres marges (`COL_MARGE_LAT`, `COL_MARGE_CLE`), et personne ne mesurait
la roche qui lui reste entre sa peau de cavite et sa peau d'enveloppe.

Un compte de penetrations dit QU'IL Y A un defaut. Il ne dit pas de combien
il s'en est fallu ailleurs. Sans le champ d'epaisseur, corriger revient a
pousser une bosse en esperant qu'elle ne ressorte pas a cote — et la marge
restante apres correction reste inconnue, donc invalidable.

CE QU'IL MESURE
===============
Pour chaque sommet de la peau de cavite, la distance au triangle
d'enveloppe le plus proche, SIGNEE par un test d'appartenance au solide :

    epaisseur > 0  le sommet est dans la roche, valeur = roche restante
    epaisseur < 0  le sommet est SORTI de l'enveloppe

La bouche (stations 0 et 1) est declaree hors sujet et signalee comme
telle : la rondelle de rive y joint les deux peaux, la cavite y touche donc
la frontiere du solide par construction, et un test de parite n'y a pas de
reponse. Ce n'est pas une exception de confort — c'est la definition de la
piece, et l'outil le DIT plutot que de publier un nombre qui n'a pas de sens.

CE QU'IL NE FAIT PAS
====================
Il ne corrige rien et ne lit aucune marge de passage.
"""

import argparse
import json
import math
import sys


def dist_point_triangle(p, a, b, c):
    """Distance euclidienne exacte d'un point a un triangle plein."""
    ab = [b[k] - a[k] for k in range(3)]
    ac = [c[k] - a[k] for k in range(3)]
    ap = [p[k] - a[k] for k in range(3)]
    d1 = sum(ab[k] * ap[k] for k in range(3))
    d2 = sum(ac[k] * ap[k] for k in range(3))
    if d1 <= 0.0 and d2 <= 0.0:
        return math.dist(p, a)
    bp = [p[k] - b[k] for k in range(3)]
    d3 = sum(ab[k] * bp[k] for k in range(3))
    d4 = sum(ac[k] * bp[k] for k in range(3))
    if d3 >= 0.0 and d4 <= d3:
        return math.dist(p, b)
    vc = d1 * d4 - d3 * d2
    if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
        t = d1 / (d1 - d3) if (d1 - d3) else 0.0
        q = [a[k] + t * ab[k] for k in range(3)]
        return math.dist(p, q)
    cp = [p[k] - c[k] for k in range(3)]
    d5 = sum(ab[k] * cp[k] for k in range(3))
    d6 = sum(ac[k] * cp[k] for k in range(3))
    if d6 >= 0.0 and d5 <= d6:
        return math.dist(p, c)
    vb = d5 * d2 - d1 * d6
    if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
        t = d2 / (d2 - d6) if (d2 - d6) else 0.0
        q = [a[k] + t * ac[k] for k in range(3)]
        return math.dist(p, q)
    va = d3 * d6 - d5 * d4
    if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
        den = (d4 - d3) + (d5 - d6)
        t = (d4 - d3) / den if den else 0.0
        q = [b[k] + t * (c[k] - b[k]) for k in range(3)]
        return math.dist(p, q)
    den = va + vb + vc
    if den == 0.0:
        return math.dist(p, a)
    v, w = vb / den, vc / den
    q = [a[k] + ab[k] * v + ac[k] * w for k in range(3)]
    return math.dist(p, q)


def dedans(p, tris, positions, directions):
    """Vote de parite sur plusieurs directions : une seule direction peut
    frôler une arete et se tromper ; trois qui s'accordent, non."""
    votes = 0
    for d in directions:
        n = 0
        for (ia, ib, ic) in tris:
            A, B, C = positions[ia], positions[ib], positions[ic]
            e1 = [B[k] - A[k] for k in range(3)]
            e2 = [C[k] - A[k] for k in range(3)]
            h = [d[1] * e2[2] - d[2] * e2[1],
                 d[2] * e2[0] - d[0] * e2[2],
                 d[0] * e2[1] - d[1] * e2[0]]
            det = sum(e1[k] * h[k] for k in range(3))
            if abs(det) < 1e-13:
                continue
            inv = 1.0 / det
            s = [p[k] - A[k] for k in range(3)]
            u = inv * sum(s[k] * h[k] for k in range(3))
            if u < 0.0 or u > 1.0:
                continue
            q = [s[1] * e1[2] - s[2] * e1[1],
                 s[2] * e1[0] - s[0] * e1[2],
                 s[0] * e1[1] - s[1] * e1[0]]
            v = inv * sum(d[k] * q[k] for k in range(3))
            if v < 0.0 or u + v > 1.0:
                continue
            t = inv * sum(e2[k] * q[k] for k in range(3))
            if t > 1e-9:
                n += 1
        votes += n % 2
    return votes * 2 > len(directions)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--atlas", required=True)
    parser.add_argument("--seuil", type=float, default=0.0,
                        help="epaisseur en dessous de laquelle on echoue")
    args = parser.parse_args()

    try:
        with open(args.atlas, "r", encoding="utf-8") as flux:
            atlas = json.load(flux)
    except OSError as err:
        print("[epai] BLOQUE: atlas illisible : %s" % err)
        return 3

    P = atlas["positions"]
    pieces = atlas["pieces"]
    stations = atlas["stations"]
    azimuts = atlas["azimuts"]

    tris = []
    for f in atlas["faces"]:
        pcs = {pieces[i] for i in f}
        ## La frontiere du solide = peau du massif + rondelle de rive. La
        ## rive melange les deux peaux ; elle EST la frontiere a la bouche.
        if "cav" in pcs and "env" not in pcs:
            continue
        if len(f) == 3:
            tris.append((f[0], f[1], f[2]))
        else:
            tris.append((f[0], f[1], f[2]))
            tris.append((f[0], f[2], f[3]))

    directions = [(0.31234, 0.73117, 0.60531),
                  (0.81237, -0.23113, 0.53537),
                  (-0.41231, 0.60113, -0.68537)]

    lignes = []
    pire = None
    for i, p in enumerate(P):
        if pieces[i] != "cav" or stations[i] < 0:
            continue
        d = min(dist_point_triangle(p, P[a], P[b], P[c]) for a, b, c in tris)
        signe = 1.0 if dedans(p, tris, P, directions) else -1.0
        lignes.append((stations[i], azimuts[i], i, signe * d, p))
        if stations[i] >= 2 and (pire is None or signe * d < pire[3]):
            pire = lignes[-1]

    print("[epai] epaisseur de roche de COL_WaterfallCave, peau de cavite")
    print("[epai] stations 0 et 1 = BOUCHE : la rondelle de rive y joint les")
    print("[epai]   deux peaux, la cavite touche la frontiere par")
    print("[epai]   construction. Valeurs affichees pour memoire, HORS SUJET.")
    print("      %-4s %-4s %-5s %10s   position (glTF)"
          % ("st", "az", "idx", "epais_m"))
    for s, a, i, e, p in lignes:
        marque = "  (bouche)" if s < 2 else ("  <<< SORTI" if e < 0 else "")
        print("      %-4d %-4d %-5d %10.4f   (%7.3f,%7.3f,%7.3f)%s"
              % (s, a, i, e, p[0], p[1], p[2], marque))

    corps = [l for l in lignes if l[0] >= 2]
    negatifs = [l for l in corps if l[3] < 0.0]
    print("[epai] --- resume, stations 2 et au-dela ---")
    print("[epai]   %d sommets ; epaisseur minimale %.4f m a la station %d "
          "azimut %d (idx %d)"
          % (len(corps), pire[3], pire[0], pire[1], pire[2]))
    print("[epai]   %d sommet(s) SORTI(S) de l'enveloppe" % len(negatifs))
    par_station = {}
    for s, a, i, e, p in corps:
        if s not in par_station or e < par_station[s][0]:
            par_station[s] = (e, a)
    print("[epai]   minimum par station :")
    for s in sorted(par_station):
        e, a = par_station[s]
        print("      station %-2d : %8.4f m (azimut %d)" % (s, e, a))
    print("FIN NOMINALE")
    if negatifs or pire[3] < args.seuil:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
