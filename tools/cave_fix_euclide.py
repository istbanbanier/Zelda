#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ÉPAISSEUR PAR DISTANCE POINT-TRIANGLE — une SECONDE opinion, sans rayon.

POURQUOI UNE SECONDE MESURE, ET POURQUOI CELLE-CI
=================================================

Tout le reste de mon appareil lit des COLONNES VERTICALES : `carte_toit`,
`percee_scan`, `controle_epaisseur_domaine`. Ils partagent donc la même
primitive, la même convention de lecture, et — c'est le point — le même
angle mort. Deux instruments qui se trompent ensemble donnent une
« convergence » qui ne vaut rien ; la passe précédente l'a payé avec deux
sondes de collerette biaisées en sens contraires dont l'accord à quatre
décimales était une coïncidence.

Celui-ci ne tire aucun rayon et n'a aucune notion de parité. Il calcule la
distance euclidienne exacte d'un point aux triangles, par la formule
point-triangle, et prend le minimum. C'est la grandeur que
`docs/CONTRAT_COQUE_STRUCTURELLE.md` §2.6 retient, et pour ses raisons :
elle ne dépend d'aucune convention de direction et elle MINORE l'épaisseur
selon n'importe quelle direction.

CE QU'IL MESURE EXACTEMENT, ET UNE PREMIÈRE VERSION QUI ÉTAIT FAUSSE
====================================================================

Depuis un point `P` pris DANS l'air intérieur, il rend la distance au
triangle le plus proche de la PEAU EXTÉRIEURE DU DESSUS.

Première version : « tout triangle dont le centroïde est au-dessus de `P` ».
Elle rendait **0,065 m** là où la colonne verticale en lisait **2,159**, et
le chiffre n'était pas une erreur de calcul : elle attrapait la PAROI
LATÉRALE DE LA CAVITÉ, qui passe à six centimètres et qui est une surface
INTÉRIEURE. Mesurer la distance à la surface la plus proche, quand on
cherche l'épaisseur d'une coque, désigne l'autre face du même vide.

Le séparateur retenu est purement LOCAL et sans rayon : sur un maillage
fermé à normales sortantes, la peau du dessus regarde vers le HAUT
(`nz > 0`) et le plafond de la cavité regarde vers le BAS (`nz < 0`), parce
qu'il fait face au vide. On retient donc les triangles à `nz >= NZ_MIN`
dont le centroïde est au-dessus de `P`. La convention de normale n'est pas
supposée : le volume signé du maillage est calculé et publié — positif =
normales sortantes — et l'outil sort en BLOQUÉ s'il est négatif.

Ce n'est pas la coque structurelle du contrat, qui se définit
topologiquement et dont l'instrument appartient à un autre agent. C'est une
seconde opinion, publiée en regard, jamais le verdict.

Usage :
    python3 tools/cave_fix_euclide.py <glb> [--x 0.55 --y 5.95] [--dz 0.10]
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cave_void_connectivity import charger_triangles, intersections_verticales

MARGE_TOIT_M = 0.05
## Composante verticale minimale de la normale pour qu'un triangle compte
## comme peau du dessus. 0,20 laisse passer des pentes jusqu'à ~78°, ce qui
## est nécessaire : le flanc d'une roche de calotte est raide.
NZ_MIN = 0.20


def distance_point_triangle(p, tri):
    """Distance euclidienne EXACTE d'un point à un triangle (Ericson).

    Traite les sept régions — face, trois arêtes, trois sommets. Une
    projection sur le plan seule serait fausse dès que le pied tombe hors
    du triangle, et c'est le cas usuel près d'une arête de silhouette.
    """
    a, b, c = tri
    ab = [b[i] - a[i] for i in range(3)]
    ac = [c[i] - a[i] for i in range(3)]
    ap = [p[i] - a[i] for i in range(3)]
    d1 = sum(ab[i] * ap[i] for i in range(3))
    d2 = sum(ac[i] * ap[i] for i in range(3))
    if d1 <= 0.0 and d2 <= 0.0:
        return math.dist(p, a)
    bp = [p[i] - b[i] for i in range(3)]
    d3 = sum(ab[i] * bp[i] for i in range(3))
    d4 = sum(ac[i] * bp[i] for i in range(3))
    if d3 >= 0.0 and d4 <= d3:
        return math.dist(p, b)
    vc = d1 * d4 - d3 * d2
    if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
        v = d1 / (d1 - d3) if d1 != d3 else 0.0
        q = [a[i] + ab[i] * v for i in range(3)]
        return math.dist(p, q)
    cp = [p[i] - c[i] for i in range(3)]
    d5 = sum(ab[i] * cp[i] for i in range(3))
    d6 = sum(ac[i] * cp[i] for i in range(3))
    if d6 >= 0.0 and d5 <= d6:
        return math.dist(p, c)
    vb = d5 * d2 - d1 * d6
    if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
        w = d2 / (d2 - d6) if d2 != d6 else 0.0
        q = [a[i] + ac[i] * w for i in range(3)]
        return math.dist(p, q)
    va = d3 * d6 - d5 * d4
    if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
        w = (d4 - d3) / ((d4 - d3) + (d5 - d6)) \
            if (d4 - d3) + (d5 - d6) != 0 else 0.0
        q = [b[i] + (c[i] - b[i]) * w for i in range(3)]
        return math.dist(p, q)
    den = va + vb + vc
    v, w = vb / den, vc / den
    q = [a[i] + ab[i] * v + ac[i] * w for i in range(3)]
    return math.dist(p, q)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        print("usage: cave_fix_euclide.py <glb> [--x .. --y .. --dz ..]")
        return 3
    opt = dict(x=0.55, y=5.95, dz=0.10)
    for k, a in enumerate(sys.argv[1:]):
        if a.startswith("--") and a[2:] in opt:
            opt[a[2:]] = float(sys.argv[k + 2])
    chemin = args[0]
    if not os.path.isfile(chemin):
        print("BLOQUE: fichier absent : %s" % chemin)
        return 3

    tris = charger_triangles(chemin)
    ax, ay = opt["x"], opt["y"]
    seau = [t for t in tris
            if min(p[0] for p in t) < ax + 4.0 and max(p[0] for p in t) > ax - 4.0
            and min(p[1] for p in t) < ay + 4.0 and max(p[1] for p in t) > ay - 4.0]

    # Le point de départ : le PLAFOND du vide intérieur, descendu de `dz`
    # pour être franchement dans l'air et non sur la peau.
    zs = sorted(intersections_verticales(seau, ax, ay), reverse=True)
    if len(zs) < 4 or len(zs) % 2:
        print("BLOQUE: colonne (%.2f ; %.2f) illisible — %d croisement(s) %s"
              % (ax, ay, len(zs), " ".join("%.3f" % z for z in zs)))
        return 3
    plafond = None
    for k in range(len(zs) // 2 - 1):
        haut, bas = zs[2 * k + 1], zs[2 * k + 2]
        if haut - bas >= 0.30:
            plafond = haut
            break
    if plafond is None:
        print("BLOQUE: aucun vide >= 0,30 m sous (%.2f ; %.2f)" % (ax, ay))
        return 3
    p = (ax, ay, plafond - opt["dz"])

    # Volume signé du maillage complet : il fixe la convention de normale,
    # au lieu de la supposer.
    vol = 0.0
    for a, b, c in tris:
        vol += (a[0] * (b[1] * c[2] - c[1] * b[2])
                - a[1] * (b[0] * c[2] - c[0] * b[2])
                + a[2] * (b[0] * c[1] - c[0] * b[1])) / 6.0
    if vol <= 0.0:
        print("BLOQUE: volume signe %.2f m3 <= 0 — les normales ne sont pas "
              "sortantes, le separateur nz serait inverse" % vol)
        return 3

    def nz_de(t):
        a, b, c = t
        ux, uy, uz = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
        vx, vy, vz = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
        nx_, ny_, nz_ = (uy * vz - uz * vy, uz * vx - ux * vz,
                         ux * vy - uy * vx)
        n = math.sqrt(nx_ * nx_ + ny_ * ny_ + nz_ * nz_)
        return nz_ / n if n > 1e-12 else 0.0

    toit = [t for t in seau
            if sum(q[2] for q in t) / 3.0 >= p[2] + MARGE_TOIT_M
            and nz_de(t) >= NZ_MIN]
    if not toit:
        print("BLOQUE: aucun triangle de PEAU DU DESSUS au-dessus de %s"
              % (p,))
        return 3
    d = min(distance_point_triangle(p, t) for t in toit)
    # LA COMPARAISON DOIT PARTIR DU MÊME POINT, ET LA PREMIÈRE VERSION NE
    # LE FAISAIT PAS. Elle opposait la distance euclidienne mesurée depuis
    # `P` — soit `dz` sous le plafond — à l'épaisseur `sommet − plafond`.
    # Sur le fichier saboté cela rendait « euclidien 0,652 > vertical 0,552 »
    # et donc « la distance euclidienne NE minore PAS la verticale », une
    # anomalie entièrement fabriquée par les deux origines différentes.
    # L'homologue correct de la distance depuis `P` est `sommet − P.z`.
    vertical = zs[0] - p[2]
    epaisseur = zs[0] - plafond
    print("=== distance euclidienne point-triangle — %s" % chemin)
    print("    point interieur P = (%.3f ; %.3f ; %.3f)  "
          "[plafond %.3f, descendu de %.2f]" % (p + (plafond, opt["dz"])))
    print("    volume signe du maillage : %+.2f m3 (positif = normales "
          "sortantes, separateur nz valide)" % vol)
    print("    %d triangle(s) de PEAU DU DESSUS (nz >= %.2f) retenus sur %d "
          "dans le seau" % (len(toit), NZ_MIN, len(seau)))
    print("    DISTANCE EUCLIDIENNE au toit : %.4f m" % d)
    print("    (colonne verticale au meme point : sommet %.3f, plafond "
          "%.3f -> epaisseur de toit %.4f m ; hauteur au-dessus de P %.4f m)"
          % (zs[0], plafond, epaisseur, vertical))
    print("    la distance euclidienne MINORE la verticale : %s"
          % ("oui" if d <= vertical + 1e-6 else
             "NON — anomalie, l'une des deux mesures est fausse"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
