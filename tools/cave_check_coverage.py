#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""FIXTURE ADVERSE — la borne `lecture - h` tient-elle sur un triangle OBTUS ?

POURQUOI CE FICHIER EXISTE
==========================
`cave_check_hull.py` publie une borne garantie `borne = lecture - h`. Cette
borne ne vaut que si `h` est une VRAIE borne de couverture : tout point de
la coque doit etre a au plus `h` d'un echantillon. Sinon la borne promet
plus qu'elle ne tient — et elle se trompe dans le sens dangereux.

Ma premiere construction subdivisait « jusqu'a circonradius <= h ». Elle est
FAUSSE, et ce fichier le demontre au lieu de l'affirmer.

LES DEUX DEFAUTS DU CIRCONRADIUS
================================
1. Le circoncentre SORT du triangle des qu'il est obtus. Un echantillon
   place la n'appartient meme pas a la surface qu'on pretend mesurer.
2. Le circonradius ne majore pas la distance d'un point de la face au
   centroide. Contre-exemple minimal, meme pas exotique :

       triangle rectangle isocele (0,0) (1,0) (0,1)
       circonradius            R = 0,707107
       max_i |V_i - centroide|   = 0,745356

   Pour `h = 0,72`, le critere naif ACCEPTE ce triangle sans le subdiviser,
   alors que le sommet (1,0) est a 0,745 du seul echantillon.

LA CONSTRUCTION RETENUE, ET SA PREUVE
=====================================
Echantillon = CENTROIDE du sous-triangle ; il est toujours DANS la face.
Rayon de couverture = `max_i |V_i - G|`, et c'est une EGALITE :

    `p -> |p - G|` est convexe ; le maximum d'une fonction convexe sur une
    enveloppe convexe est atteint en un point extreme, donc en un sommet.
    Donc max_{p dans T} |p - G| = max_i |V_i - G|.

Subdivision par MILIEUX D'ARETES : les quatre sous-triangles sont semblables
au parent, de rapport 1/2. Comme

    |G - V_1| = |(V_2 - V_1) + (V_3 - V_1)| / 3  <=  (2/3) x arete_max

le rayon de couverture est divise par deux a chaque niveau, QUELLE QUE SOIT
la forme. Un triangle obtus converge exactement aussi vite qu'un equilateral.

CE QUE CE FICHIER MESURE
========================
Pour chaque triangle temoin et chaque construction, on echantillonne la face
DENSEMENT et on mesure la vraie couverture

    couverture = max_{p dense} min_{s echantillon} |p - s|

puis on la compare a `h`. `couverture > h` = la borne est violee.

USAGE :  python3 tools/cave_check_coverage.py
Codes retour : 0 la construction retenue couvre partout · 1 violation.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cave_check_hull as H  # noqa: E402


TEMOINS = [
    ("rectangle isocele (LE contre-exemple)",
     (0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0), 0.72),
    ("obtus 150 deg, tres etire",
     (0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (1.85, 0.22, 0.0), 0.40),
    ("obtus 170 deg, quasi degenere",
     (0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (2.40, 0.09, 0.0), 0.50),
    ("equilateral (temoin sain)",
     (0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (0.5, 0.8660254, 0.0), 0.40),
    ("aiguille : 2 cm sur 1,4 m",
     (0.0, 0.0, 0.0), (1.4, 0.0, 0.0), (0.7, 0.02, 0.0), 0.30),
]


def circonradius(a, b, c):
    la, lb, lc = math.dist(b, c), math.dist(a, c), math.dist(a, b)
    s = 0.5 * (la + lb + lc)
    aire = max(s * (s - la) * (s - lb) * (s - lc), 0.0) ** 0.5
    if aire <= 1e-15:
        return max(la, lb, lc) / 2.0
    return (la * lb * lc) / (4.0 * aire)


def circoncentre(a, b, c):
    ax, ay, az = a
    bx, by, bz = (b[k] - a[k] for k in range(3))
    cx, cy, cz = (c[k] - a[k] for k in range(3))
    nx = by * cz - bz * cy
    ny = bz * cx - bx * cz
    nz = bx * cy - by * cx
    n2 = nx * nx + ny * ny + nz * nz
    if n2 < 1e-20:
        return ((a[0] + b[0] + c[0]) / 3, (a[1] + b[1] + c[1]) / 3,
                (a[2] + b[2] + c[2]) / 3)
    b2 = bx * bx + by * by + bz * bz
    c2 = cx * cx + cy * cy + cz * cz
    ux = (b2 * (cy * nz - cz * ny) + c2 * (by * nz - bz * ny) * -1) / (2 * n2)
    uy = (b2 * (cz * nx - cx * nz) + c2 * (bz * nx - bx * nz) * -1) / (2 * n2)
    uz = (b2 * (cx * ny - cy * nx) + c2 * (bx * ny - by * nx) * -1) / (2 * n2)
    return (ax + ux, ay + uy, az + uz)


def dans_le_triangle(p, a, b, c):
    def aire(u, v, w):
        ux, uy, uz = (v[k] - u[k] for k in range(3))
        vx, vy, vz = (w[k] - u[k] for k in range(3))
        cx = uy * vz - uz * vy
        cy = uz * vx - ux * vz
        cz = ux * vy - uy * vx
        return 0.5 * math.sqrt(cx * cx + cy * cy + cz * cz)
    t = aire(a, b, c)
    if t <= 1e-15:
        return False
    s = aire(p, b, c) + aire(a, p, c) + aire(a, b, p)
    return abs(s - t) <= 1e-9 * max(1.0, t)


def naif(a, b, c, h):
    """Construction FAUSSE : subdivise jusqu'a circonradius <= h, echantillon
    au circoncentre."""
    pts = []
    pile = [(a, b, c)]
    while pile:
        p, q, r = pile.pop()
        if circonradius(p, q, r) <= h:
            pts.append(circoncentre(p, q, r))
            continue
        pq = tuple((p[k] + q[k]) / 2 for k in range(3))
        qr = tuple((q[k] + r[k]) / 2 for k in range(3))
        rp = tuple((r[k] + p[k]) / 2 for k in range(3))
        pile += [(p, pq, rp), (pq, q, qr), (rp, qr, r), (pq, qr, rp)]
    return pts


def naif_centroide(a, b, c, h):
    """LA CONSTRUCTION QUE J'AVAIS ECRITE, et le vrai bug.

    Critere de subdivision = circonradius <= h, mais echantillon au
    CENTROIDE. Le melange est incoherent : le circonradius majore la
    distance depuis le CIRCONCENTRE, jamais depuis le centroide. Sur le
    rectangle isocele, R = 0,7071 <= h = 0,72 fait accepter le triangle,
    et le sommet (1,0) est a 0,7454 du centroide — 3,5 % au-dela de `h`.

    La borne `lecture - h` promet alors plus qu'elle ne tient.
    """
    pts = []
    pile = [(a, b, c)]
    while pile:
        p, q, r = pile.pop()
        if circonradius(p, q, r) <= h:
            pts.append(((p[0] + q[0] + r[0]) / 3.0,
                        (p[1] + q[1] + r[1]) / 3.0,
                        (p[2] + q[2] + r[2]) / 3.0))
            continue
        pq = tuple((p[k] + q[k]) / 2 for k in range(3))
        qr = tuple((q[k] + r[k]) / 2 for k in range(3))
        rp = tuple((r[k] + p[k]) / 2 for k in range(3))
        pile += [(p, pq, rp), (pq, q, qr), (rp, qr, r), (pq, qr, rp)]
    return pts


def retenue(a, b, c, h):
    """Construction du contrat : centroide, rayon de couverture exact."""
    pts = []
    pile = [(a, b, c)]
    while pile:
        p, q, r = pile.pop()
        rc, g = H.rayon_de_couverture(p, q, r)
        if rc <= h:
            pts.append(g)
            continue
        pq = tuple((p[k] + q[k]) / 2 for k in range(3))
        qr = tuple((q[k] + r[k]) / 2 for k in range(3))
        rp = tuple((r[k] + p[k]) / 2 for k in range(3))
        pile += [(p, pq, rp), (pq, q, qr), (rp, qr, r), (pq, qr, rp)]
    return pts


def couverture_reelle(a, b, c, pts, n=140):
    """max sur la face de la distance a l'echantillon le plus proche."""
    pire = 0.0
    ou = None
    for i in range(n + 1):
        for j in range(n + 1 - i):
            u = i / n
            v = j / n
            w = 1.0 - u - v
            p = tuple(u * a[k] + v * b[k] + w * c[k] for k in range(3))
            d = min(math.dist(p, s) for s in pts)
            if d > pire:
                pire, ou = d, p
    return pire, ou


def main():
    print("=" * 78)
    print("FIXTURE ADVERSE — couverture d'echantillonnage sur triangles obtus")
    print("=" * 78)
    print("Regle : la couverture reelle doit rester <= h. Sinon `lecture - h`")
    print("n'est pas une borne, et le contrat exige alors BLOQUE.")
    print()
    faute_naive = 0
    faute_mienne = 0
    faute_retenue = 0
    for (nom, a, b, c, h) in TEMOINS:
        R = circonradius(a, b, c)
        rc, g = H.rayon_de_couverture(a, b, c)
        cc = circoncentre(a, b, c)
        dedans = dans_le_triangle(cc, a, b, c)
        print("-" * 78)
        print("%s      h = %.3f" % (nom, h))
        print("  circonradius        R = %.6f   circoncentre dans la face : %s"
              % (R, "oui" if dedans else "NON"))
        print("  rayon de couverture   = %.6f   (max_i |V_i - centroide|)" % rc)

        pn = naif(a, b, c, h)
        cn, oun = couverture_reelle(a, b, c, pn)
        okn = cn <= h + 1e-12
        print("  NAIVE   (circonradius/circoncentre) : %4d echantillon(s), "
              "couverture reelle %.6f  %s"
              % (len(pn), cn, "OK" if okn else "*** VIOLE h ***"))
        if not okn:
            faute_naive += 1
            print("          point non couvert : (%.4f ; %.4f ; %.4f), "
                  "depassement %.6f m (%.2f %%)"
                  % (oun[0], oun[1], oun[2], cn - h, 100.0 * (cn - h) / h))
        hors = sum(1 for s in pn if not dans_le_triangle(s, a, b, c))
        if hors:
            print("          %d echantillon(s) HORS de la face — ils ne sont"
                  " meme pas sur la surface mesuree" % hors)

        pm = naif_centroide(a, b, c, h)
        cm, oum = couverture_reelle(a, b, c, pm)
        okm = cm <= h + 1e-12
        print("  MON BUG (circonradius + centroide)  : %4d echantillon(s), "
              "couverture reelle %.6f  %s"
              % (len(pm), cm, "OK" if okm else "*** VIOLE h ***"))
        if not okm:
            faute_mienne += 1
            print("          point non couvert : (%.4f ; %.4f ; %.4f), "
                  "depassement %.6f m (%.2f %%)"
                  % (oum[0], oum[1], oum[2], cm - h, 100.0 * (cm - h) / h))

        pr = retenue(a, b, c, h)
        cr, our = couverture_reelle(a, b, c, pr)
        okr = cr <= h + 1e-12
        print("  RETENUE (centroide/couverture exacte): %4d echantillon(s), "
              "couverture reelle %.6f  %s"
              % (len(pr), cr, "OK" if okr else "*** VIOLE h ***"))
        if not okr:
            faute_retenue += 1
            print("          point non couvert : (%.4f ; %.4f ; %.4f)"
                  % (our[0], our[1], our[2]))
        hors_r = sum(1 for s in pr if not dans_le_triangle(s, a, b, c))
        print("          echantillons hors de la face : %d" % hors_r)
    print("-" * 78)
    print()
    print("BILAN")
    print("  construction NAIVE   : %d temoin(s) sur %d violent la couverture"
          % (faute_naive, len(TEMOINS)))
    print("  MON BUG d'origine    : %d temoin(s) sur %d violent la couverture"
          % (faute_mienne, len(TEMOINS)))
    print("  construction RETENUE : %d temoin(s) sur %d violent la couverture"
          % (faute_retenue, len(TEMOINS)))
    print()
    if faute_retenue:
        print("VERDICT : la construction retenue NE couvre pas. `lecture - h`")
        print("n'est pas une borne — le gate doit rendre BLOQUE.")
        return 1
    if not faute_mienne:
        print("VERDICT : la fixture n'a PAS mis en defaut la construction")
        print("fautive. Elle ne prouve donc rien — un controle qui n'a jamais")
        print("rougi n'est pas un controle.")
        return 1
    print("VERDICT : la construction fautive est prise en defaut, la retenue")
    print("couvre partout, et tous ses echantillons sont DANS la face.")
    print("`h` est donc une vraie borne de couverture, et `lecture - h` une")
    print("vraie borne inferieure.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
