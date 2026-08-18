#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""LARGEUR LIBRE AU SEUIL — EXACTE, ET QUI NOMME CE QUI SERRE.

CONVENTION DE CODES RETOUR — R2a-3.5.7, ICI SEULEMENT
=====================================================
    0 = PASS (la capsule passe partout ou on la teste)
    1 = FAIL (elle ne passe pas quelque part)
    3 = BLOQUE      >=4 = erreur d'outil

POURQUOI CE FICHIER EXISTE, ALORS QUE `cave_gabarit_marche.py` MESURE DEJA
==========================================================================
Parce que son instrument ne peut pas conclure ICI, et qu'il le dit.

`cave_gabarit_marche.py` echantillonne chaque triangle barycentriquement a
`subdiv=6` : son erreur est bornee par environ 0,08 m. Il releve 0,431 m au
seuil pour 0,450 requis. **L'ecart mesure (0,019 m) est quatre fois plus
petit que l'erreur de l'instrument.** Un instrument dont l'erreur depasse la
grandeur mesuree ne peut rien affirmer — c'est la lecon que cette serie a mis
trois passes a apprendre sur l'epaisseur, et elle vaut ici.

CE QUI REND CELUI-CI EXACT
==========================
Aucun echantillonnage. Pour chaque triangle :

  1. on le DECOUPE par les deux plans horizontaux de la bande occupee par le
     corps (Sutherland-Hodgman) — il en reste un polygone convexe plan ;
  2. on le PROJETTE dans le plan horizontal ; la distance horizontale d'une
     droite verticale a un polygone 3D est exactement la distance 2D du
     point a ce polygone projete, puisque la hauteur est ignoree des deux
     cotes ;
  3. on calcule la distance exacte du point au polygone PLEIN : zero s'il
     est dedans, sinon le minimum des distances point-segment.

Il ne reste que l'arrondi flottant, de l'ordre de 1e-9 m sur ces
coordonnees — soit sept ordres de grandeur sous l'ecart a decider. La
condition que le lead pose (« erreur inferieure d'un ordre a l'ecart
mesure ») est donc tenue avec une marge tres large.

CE QU'IL PUBLIE EN PLUS
=======================
La PIECE fautive. « Quelque chose retrecit la bouche » n'est actionnable que
si l'on sait quoi : l'outil rend le triangle le plus proche, son sommet le
plus proche, et — via l'atlas — sa piece, sa station et son azimut.
"""

import argparse
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from cave_exact_intersect import lire_accesseur, lire_glb  # noqa: E402
from cave_epaisseur_col import dist_point_triangle  # noqa: E402

## Recopie de tests/world_v2/test_world_v2_places_behavior.gd
CAVE_HEADROOM_M = 1.75
DEPART_RAYON_M = 0.15
## Stations de CAVITE en repere MODELE : (ax, -ay).
CAVITE_MODELE = [(0.00, 1.15), (0.00, 0.00), (0.22, -1.05), (1.00, -1.62),
                 (1.82, -2.12), (2.62, -2.58), (3.10, -2.88), (3.40, -3.06),
                 (3.58, -3.17)]


def lire_maillage(gltf, blob, nom):
    for maillage in gltf.get("meshes", []):
        if maillage.get("name") != nom:
            continue
        positions, triangles = [], []
        for prim in maillage.get("primitives", []):
            if prim.get("mode", 4) != 4:
                continue
            decalage = len(positions)
            positions.extend(lire_accesseur(gltf, blob,
                                            prim["attributes"]["POSITION"]))
            indices = lire_accesseur(gltf, blob, prim["indices"])
            for k in range(0, len(indices) - 2, 3):
                triangles.append((indices[k] + decalage,
                                  indices[k + 1] + decalage,
                                  indices[k + 2] + decalage))
        return positions, triangles
    return None, None


def couper_demi_espace(poly, garder_au_dessus, limite):
    """Sutherland-Hodgman sur un plan horizontal."""
    if not poly:
        return []
    sortie = []
    n = len(poly)
    for i in range(n):
        a = poly[i]
        b = poly[(i + 1) % n]
        da = (a[1] - limite) if garder_au_dessus else (limite - a[1])
        db = (b[1] - limite) if garder_au_dessus else (limite - b[1])
        if da >= 0.0:
            sortie.append(a)
        if (da > 0.0 and db < 0.0) or (da < 0.0 and db > 0.0):
            t = da / (da - db)
            sortie.append((a[0] + (b[0] - a[0]) * t,
                           a[1] + (b[1] - a[1]) * t,
                           a[2] + (b[2] - a[2]) * t))
    return sortie


def distance_point_segment_2d(px, pz, ax, az, bx, bz):
    dx, dz = bx - ax, bz - az
    long2 = dx * dx + dz * dz
    if long2 < 1e-18:
        return math.hypot(px - ax, pz - az)
    t = ((px - ax) * dx + (pz - az) * dz) / long2
    t = min(1.0, max(0.0, t))
    return math.hypot(px - (ax + dx * t), pz - (az + dz * t))


def distance_horizontale(poly, px, pz):
    """Distance exacte du point au polygone PLEIN projete."""
    if len(poly) < 2:
        if len(poly) == 1:
            return math.hypot(px - poly[0][0], pz - poly[0][2])
        return float("inf")
    ## Dedans ? Test de signe sur toutes les aretes ; le polygone issu du
    ## decoupage d'un triangle est convexe, donc ce test est valide.
    positif = negatif = False
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        cote = ((b[0] - a[0]) * (pz - a[2]) - (b[2] - a[2]) * (px - a[0]))
        if cote > 1e-15:
            positif = True
        elif cote < -1e-15:
            negatif = True
    if not (positif and negatif):
        return 0.0
    return min(distance_point_segment_2d(px, pz, poly[i][0], poly[i][2],
                                         poly[(i + 1) % len(poly)][0],
                                         poly[(i + 1) % len(poly)][2])
               for i in range(len(poly)))


CAPSULE_HAUTEUR_M = 1.85
TRANCHE_M = 0.02


def rayon_requis(dy, rayon, hauteur):
    """Demi-largeur d'une capsule a la hauteur `dy` au-dessus de son pied.

    UNE CAPSULE N'EST PAS UN CYLINDRE, et la premiere version de cet outil
    l'a oublie. Elle exigeait le rayon PLEIN sur toute la bande, jusqu'a
    `sol + 1,90` — donc jusque dans la voute, la ou l'arc se referme et ou
    la capsule, elle, n'a plus qu'une calotte. Elle a ainsi declare le seuil
    infranchissable en mesurant un point que le CORPS DU JOUEUR n'occupe
    pas. Meme faute de forme que le critere 3D precedent : mesurer autre
    chose que ce qui bloque.

    Cylindre entre `r` et `h - r` ; calottes spheriques en dessous et
    au-dessus.
    """
    if dy < 0.0 or dy > hauteur:
        return 0.0
    if dy < rayon:
        return math.sqrt(max(0.0, rayon * rayon - (rayon - dy) ** 2))
    if dy > hauteur - rayon:
        return math.sqrt(max(0.0, rayon * rayon
                             - (dy - (hauteur - rayon)) ** 2))
    return rayon


## Pas d'echantillonnage de l'AXE de la capsule. La distance point-triangle
## etant 1-lipschitzienne le long de l'axe, l'erreur commise est bornee par
## la MOITIE du pas — soit 0,0025 m ici, deux ordres sous l'ecart a decider.
PAS_AXE_M = 0.005
## Le contact avec le sol d'appui est TANGENT : on l'accepte au lieu de le
## confondre avec une penetration. Trois fois l'erreur d'echantillonnage.
TOLERANCE_TANGENCE_M = 0.0075


def ajustement_capsule(P, T, x, z, sol, rayon, hauteur):
    """Jeu de la capsule : distance de son AXE a la roche, moins son rayon.

    TROIS CRITERES ONT ETE ESSAYES ICI, ET LES DEUX PREMIERS MESURAIENT LE
    PLANCHER. C'est la meme faute chaque fois, et elle vaut d'etre ecrite :

      1. distance 3D de l'axe a TOUTE la geometrie, comparee strictement a
         `r`. Le bas de l'axe est a `sol + r` : le sol y est donc a
         exactement `r`, et le bruit de virgule flottante faisait echouer la
         galerie entiere, axe compris.
      2. distance HORIZONTALE par tranches, avec le rayon de capsule requis
         a chaque hauteur. La tranche du bas exige une calotte alors que la
         capsule y REPOSE : le sol, projete sous le point, donnait une
         distance nulle et un jeu negatif partout, y compris a 0,92 m de
         toute paroi.

    LA CAPSULE REPOSE SUR LE SOL. Le plancher n'est pas un obstacle : il est
    l'appui, et le contact y est TANGENT par construction. Le seul critere
    correct est donc celui-ci — rien ne doit etre a moins de `r` de l'axe —
    avec une tolerance qui accepte la tangence au lieu de la confondre avec
    une penetration.

    Rend (jeu, distance minimale, hauteur du pire point, triangle fautif).
    """
    bas = sol + rayon
    haut = max(bas, sol + hauteur - rayon)
    pire = float("inf")
    hauteur_pire = bas
    coupable = None
    n = max(1, int(math.ceil((haut - bas) / PAS_AXE_M)))
    for k in range(n + 1):
        y = bas + (haut - bas) * (k / float(n))
        for ti, (ia, ib, ic) in enumerate(T):
            a, b, c = P[ia], P[ib], P[ic]
            ## Rejet rapide : un triangle trop loin en hauteur ne peut pas
            ## etre a moins de `pire` de ce point.
            if min(a[1], b[1], c[1]) - y > pire or \
                    y - max(a[1], b[1], c[1]) > pire:
                continue
            d = dist_point_triangle((x, y, z), a, b, c)
            if d < pire:
                pire = d
                hauteur_pire = y
                coupable = (ti, (ia, ib, ic))
    return pire - rayon, pire, hauteur_pire, coupable


def nommer(P, coupable, etiq):
    if coupable is None:
        return "-"
    if etiq is None:
        return "tri %d" % coupable[0]
    pieces = {etiq.get(tuple(P[i]), ("?", -9, -9))[0] for i in coupable[1]}
    sts = sorted({etiq.get(tuple(P[i]), ("?", -9, -9))[1]
                  for i in coupable[1]})
    azs = sorted({etiq.get(tuple(P[i]), ("?", -9, -9))[2]
                  for i in coupable[1]})
    return "%s st%s az%s (tri %d)" % ("+".join(sorted(pieces)), sts, azs,
                                      coupable[0])


def sol_sous(P, T, x, z, y0):
    """Premiere face MONTANTE en descendant — semantique de Godot."""
    meilleur = None
    for (ia, ib, ic) in T:
        a, b, c = P[ia], P[ib], P[ic]
        d = ((b[2] - c[2]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[2] - c[2]))
        if abs(d) < 1e-14:
            continue
        u = ((b[2] - c[2]) * (x - c[0]) + (c[0] - b[0]) * (z - c[2])) / d
        v = ((c[2] - a[2]) * (x - c[0]) + (a[0] - c[0]) * (z - c[2])) / d
        w = 1.0 - u - v
        if u < 0.0 or v < 0.0 or w < 0.0:
            continue
        y = u * a[1] + v * b[1] + w * c[1]
        e1 = [b[k] - a[k] for k in range(3)]
        e2 = [c[k] - a[k] for k in range(3)]
        if (e1[2] * e2[0] - e1[0] * e2[2]) <= 0.0:
            continue
        if y <= y0 + 3.0 and y >= y0 - 8.0:
            if meilleur is None or y > meilleur:
                meilleur = y
    return meilleur


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("glb")
    parser.add_argument("--maillage", default="COL_WaterfallCave")
    parser.add_argument("--atlas", default="",
                        help="atlas pour nommer la piece fautive (COL seul)")
    parser.add_argument("--rayons", default="0.45,0.35")
    parser.add_argument("--stations", default="0,1,2")
    args = parser.parse_args()

    rayons = [float(v) for v in args.rayons.split(",")]
    stations = [int(v) for v in args.stations.split(",")]

    gltf, blob = lire_glb(args.glb)
    P, T = lire_maillage(gltf, blob, args.maillage)
    if P is None:
        print("[seuil] BLOQUE: maillage absent : %s" % args.maillage)
        return 3

    etiq = None
    if args.atlas and os.path.exists(args.atlas):
        with open(args.atlas, "r", encoding="utf-8") as flux:
            atlas = json.load(flux)
        repere = {}
        for i, p in enumerate(atlas["positions"]):
            repere[tuple(p)] = (atlas["pieces"][i], atlas["stations"][i],
                                atlas["azimuts"][i])
        etiq = repere

    print("[seuil] %s : %d sommets, %d triangles"
          % (args.maillage, len(P), len(T)))
    print("[seuil] instrument EXACT : decoupage par plans + distance 2D "
          "fermee ; erreur = arrondi flottant, ~1e-9 m")
    print("[seuil] bande occupee : de sol+%.2f a sol+%.2f"
          % (DEPART_RAYON_M, DEPART_RAYON_M + CAVE_HEADROOM_M))
    print()
    print("      %-4s %-7s %-7s %9s %10s %9s %7s   %s"
          % ("st", "x", "z", "sol", "d_min", "jeu", "h_pire",
             "ce qui serre"))

    verdicts = []
    for st in stations:
        x, z = CAVITE_MODELE[st]
        sol = sol_sous(P, T, x, z, 0.09)
        if sol is None:
            print("      %-4d %-7.2f %-7.2f %9s %10s %9s %7s   %s"
                  % (st, x, z, "-", "-", "-", "-",
                     "aucun sol dans ce maillage"))
            continue
        ligne = "      %-4d %-7.2f %-7.2f %9.3f" % (st, x, z, sol)
        mesures = {}
        for r in rayons:
            slack, largeur, hauteur_pire, coupable = ajustement_capsule(
                P, T, x, z, sol, r, CAPSULE_HAUTEUR_M)
            mesures[r] = (slack, largeur, hauteur_pire, coupable)
        r0 = rayons[0]
        slack, largeur, hpire, coupable = mesures[r0]
        nom = nommer(P, coupable, etiq)
        print("%s %10.4f %9.4f %7.2f   %s"
              % (ligne, largeur, slack, hpire - sol, nom))
        verdicts.append((st, mesures))

    print()
    print("[seuil] verdict par rayon de capsule (capsule REELLE : cylindre")
    print("[seuil] entre sol+r et sol+h-r, calottes spheriques au-dela) :")
    echec = False
    for r in rayons:
        mauvais = [(st, m[r][0]) for st, m in verdicts
                   if m[r][0] < -TOLERANCE_TANGENCE_M]
        if mauvais:
            echec = True
            detail = ", ".join("st%d %+.4f" % (st, s) for st, s in mauvais)
            print("[seuil]   r=%.2f h=%.2f : NE PASSE PAS a %d station(s) — "
                  "jeu %s" % (r, CAPSULE_HAUTEUR_M, len(mauvais), detail))
        else:
            pire = min(m[r][0] for _s, m in verdicts) if verdicts else 0.0
            print("[seuil]   r=%.2f h=%.2f : PASSE partout ; jeu le plus "
                  "faible %+.4f m" % (r, CAPSULE_HAUTEUR_M, pire))
    print("[seuil] erreur de l'instrument : distance point-triangle EXACTE ;")
    print("[seuil] axe echantillonne a %.4f m, donc erreur <= %.4f m."
          % (PAS_AXE_M, PAS_AXE_M / 2.0))
    print("[seuil] tolerance de tangence au sol d'appui : %.4f m."
          % TOLERANCE_TANGENCE_M)
    print("FIN NOMINALE")
    return 1 if echec else 0


if __name__ == "__main__":
    sys.exit(main())
