#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""LOCALISER LES ANSES — le genre dit qu'il y en a, jamais OU.

POURQUOI
========

`cave_oracle_global.py` mesure que le candidat est de genre **1** et la
geometrie R2a-3.4 livree de genre **2**. Une grotte a une seule bouche est
topologiquement une bosselure, donc de genre **0** : il existe donc une, puis
deux anses a expliquer, et les deux hypotheses ne se valent pas du tout.

  * ARCHE — une boucle de matiere (visiere, pied, orteil formant un pont).
    Legitime, et coherente avec la composition voulue.
  * PERCEE — un trou traversant entre la cavite et le dehors. Ce serait un
    defaut que toutes les sondes annoncent a zero.

Le genre ne les distingue pas : une arche et un trou traversant sont
EXACTEMENT le meme invariant. Seule une mesure d'espace tranche, et c'est
ce que fait ce fichier. Il traite l'hypothese PERCEE comme une hypothese a
REFUTER, pas a confirmer.

METHODE
=======

L'anse d'un solide se voit par son TROU : un passage d'air qui traverse la
matiere. On balaie donc des tranches perpendiculaires a chaque axe et on
cherche, dans chaque tranche, les regions d'AIR **encerclees par la roche a
l'interieur de la tranche**. Une region encerclee dans une tranche est soit :

  * la cavite elle-meme, qu'on ECARTE explicitement en la reconnaissant a sa
    composante 3D (celle de la graine, bouche barree) ;
  * le trou d'une anse — ce qu'on cherche ;
  * un simple surplomb vu en coupe, qui n'apparait que sur tres peu de
    tranches consecutives et jamais sur les trois axes.

On publie la position et l'etendue de chaque region retenue. La lecture
finale reste humaine : ce fichier localise, il ne juge pas.

Usage :
    python3 tools/cave_oracle_anses.py <glb> [--pas 0.15] [--axe y]

Codes de sortie : 0 = mesure faite · 3 = BLOQUE.
"""

import argparse
import hashlib
import os
import sys
from collections import defaultdict, deque

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import probe_cave_openings as P                                # noqa: E402
import cave_oracle_global as O                                 # noqa: E402

AXES = {"x": 0, "y": 1, "z": 2}


def regions_encerclees(espace, axe, indice, interdits):
    """Regions d'AIR encerclees par la roche DANS la tranche `indice`.

    Rendu : liste de listes de cases `(i, j, k)`. Une region touchant le
    bord de la tranche est ecartee : elle communique lateralement et n'est
    donc pas le trou d'une anse vue en coupe.
    """
    nx, ny, nz = espace.dim
    u, v = [k for k in range(3) if k != axe]
    dim_u, dim_v = espace.dim[u], espace.dim[v]

    def case(a, b):
        idx = [0, 0, 0]
        idx[axe] = indice
        idx[u] = a
        idx[v] = b
        return tuple(idx)

    # une case de la tranche est « libre » si elle appartient a une
    # composante d'AIR et n'est pas dans l'ensemble interdit (la cavite).
    libre = bytearray(dim_u * dim_v)
    for a in range(dim_u):
        for b in range(dim_v):
            c = case(a, b)
            s = espace.rang_segment[espace.rang(*c)]
            if espace.seg_est_air[s] and c not in interdits:
                libre[a * dim_v + b] = 1

    masques = {0: espace.bx, 1: espace.by}
    vus = bytearray(dim_u * dim_v)
    sorties = []
    for a0 in range(dim_u):
        for b0 in range(dim_v):
            n0 = a0 * dim_v + b0
            if not libre[n0] or vus[n0]:
                continue
            file = deque([(a0, b0)])
            vus[n0] = 1
            lot = []
            bord = False
            while file:
                a, b = file.popleft()
                lot.append(case(a, b))
                if a == 0 or a == dim_u - 1 or b == 0 or b == dim_v - 1:
                    bord = True
                for da, db in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    a2, b2 = a + da, b + db
                    if a2 < 0 or a2 >= dim_u or b2 < 0 or b2 >= dim_v:
                        continue
                    n2 = a2 * dim_v + b2
                    if vus[n2] or not libre[n2]:
                        continue
                    # adjacence bloquee ? le masque porte le blocage de la
                    # case INFERIEURE vers la suivante.
                    axe_dep = u if da else v
                    if axe_dep == 2:
                        # blocage vertical : il est deja encode par la
                        # coupure des segments, deux cases voisines en z
                        # dans des segments differents sont separees.
                        c1 = case(a, b)
                        c2 = case(a2, b2)
                        if espace.rang_segment[espace.rang(*c1)] != \
                           espace.rang_segment[espace.rang(*c2)]:
                            continue
                    else:
                        m = masques[axe_dep]
                        bas = case(a, b) if (da > 0 or db > 0) \
                            else case(a2, b2)
                        if m[espace.rang(*bas)]:
                            continue
                    vus[n2] = 1
                    file.append((a2, b2))
            if not bord:
                sorties.append(lot)
    return sorties


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("glb")
    ap.add_argument("--noeud", default=O.NOEUD_DEFAUT)
    ap.add_argument("--pas", type=float, default=0.15)
    ap.add_argument("--y-bouche", type=float, default=O.Y_BOUCHE_DEFAUT)
    ap.add_argument("--axe", default="y", choices=sorted(AXES))
    ap.add_argument("--min-cases", type=int, default=4)
    args = ap.parse_args()

    if not os.path.isfile(args.glb):
        print("BLOQUE : maillage introuvable : %s" % args.glb)
        return 3
    sha = hashlib.sha256(open(args.glb, "rb").read()).hexdigest()
    tris, _ = P.triangles_du_glb(args.glb, args.noeud)
    racine = O.racine_depot(os.path.dirname(os.path.abspath(__file__)))
    reperes = O.lire_reperes(racine)
    salle = reperes.get("MODELE_SALLE")
    if salle is None:
        print("BLOQUE : MODELE_SALLE illisible")
        return 3
    graine = (salle[0], salle[1], salle[2] + O.GRAINE_HAUTEUR_M)

    print("maillage : %s" % args.glb)
    print("sha256   : %s" % sha)
    print("noeud    : %s   pas %.3f m   axe de coupe %s"
          % (args.noeud, args.pas, args.axe))
    topo = O.topologie(tris)
    g = topo["detail_composantes"][0]["genre"]
    print("genre    : %s" % ("indefini" if g is None else g))
    print()

    espace = O.Espace(tris, args.pas)
    trouver, groupes = espace.composantes(j_barriere=None)
    # nature de chaque segment, memorisee pour la lecture en tranche
    espace.seg_est_air = bytearray(len(espace.segments))
    for racine_c, lot in groupes.items():
        nat, _, _ = espace.nature(lot)
        if nat == "AIR":
            for s in lot:
                espace.seg_est_air[s] = 1

    # la cavite : composante de la graine, bouche barree. On l'ECARTE.
    j_bar = None
    for j in range(espace.dim[1] - 1):
        if espace.centre(j, 1) < args.y_bouche <= espace.centre(j + 1, 1):
            j_bar = j
            break
    interdits = set()
    if j_bar is not None:
        seg = espace.segment_du_point(graine)
        tr2, gr2 = espace.composantes(j_barriere=j_bar)
        for s in gr2[tr2(seg)]:
            i, jj, k0, k1 = espace.segments[s]
            for k in range(k0, k1 + 1):
                interdits.add((i, jj, k))
    print("cavite ecartee : %d case(s) (composante de la graine, bouche "
          "barree)" % len(interdits))
    print()

    axe = AXES[args.axe]
    print("tranches perpendiculaires a %s portant une region d'AIR "
          "ENCERCLEE (hors cavite) :" % args.axe.upper())
    total = 0
    for indice in range(espace.dim[axe]):
        for lot in regions_encerclees(espace, axe, indice, interdits):
            if len(lot) < args.min_cases:
                continue
            total += 1
            lo = [min(espace.centre(c[k], k) for c in lot) for k in range(3)]
            hi = [max(espace.centre(c[k], k) for c in lot) for k in range(3)]
            print("   %s=%7.3f : %4d case(s)  x[%6.2f %6.2f] y[%6.2f %6.2f] "
                  "z[%6.2f %6.2f]"
                  % (args.axe, espace.centre(indice, axe), len(lot),
                     lo[0], hi[0], lo[1], hi[1], lo[2], hi[2]))
    if not total:
        print("   aucune.")
    print()
    print("total : %d region(s) encerclee(s) de %d case(s) ou plus."
          % (total, args.min_cases))
    return 0


if __name__ == "__main__":
    sys.exit(main())
