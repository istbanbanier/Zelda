#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""MARGE DISPONIBLE pour la masse corrective — combien de roche peut-on ajouter
sans toucher à la composition ?

LE RAISONNEMENT, ET IL EST CONSTRUCTIF
======================================

Le profil de silhouette est un MAXIMUM de `z` par colonne d'écran. Donc :

    toute matière ajoutée dont le sommet reste STRICTEMENT SOUS le profil
    existant laisse le profil INCHANGÉ, et `controle_amas` avec lui.

Ce n'est pas une espérance, c'est une propriété du max. Elle transforme la
question « la masse va-t-elle casser la composition ? », qui ne se tranche
qu'après coup, en une contrainte de conception vérifiable AVANT de modeler :
un plafond `z` par point du sol.

L'azimut 100° a déjà consommé sa marge — la proéminence du col y est
passée de 1,21 à 1,06 m pour un portail à 0,90, soit 0,16 m de reste. C'est
précisément pourquoi on mesure le plafond au lieu de l'estimer.

CE QU'IL PUBLIE
===============

Pour chaque colonne du sol, dans l'emprise du défaut :

  `plafond_cav`  plafond de la cavité (le haut du vide intérieur) ;
  `sommet`       sommet actuel du massif ;
  `exige`        `plafond_cav + EPAISSEUR_MIN + marge` — ce qu'il FAUT ;
  `permis`       le plus petit profil de silhouette aux trois azimuts,
                 moins un retrait de sécurité — ce qu'on PEUT ;
  `jeu`          `permis − exige`. Négatif = aucune masse conforme à cet
                 endroit, et il faut le savoir tout de suite.

Usage :
    python3 tools/cave_fix_marge.py <glb> [--marge 0.60] [--retrait 0.35]
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cave_void_connectivity import charger_triangles, intersections_verticales

EPAISSEUR_MIN_M = 0.80          # le seuil du contrat, jamais modifié ici
AZIMUTS = (55.0, 100.0, 225.0)
PAS_PROFIL = 0.08               # colonne d'écran, comme `controle_amas`

X0, X1 = -1.20, 3.40
Y0, Y1 = 3.80, 7.40
PAS = 0.20


def axe_silhouette(azimut_deg):
    """Axe horizontal de l'image de silhouette, en repère modèle.

    Recopié de `_axe_silhouette()` du générateur, à l'identique, parce que
    deux définitions divergentes d'un même axe rendraient les deux mesures
    incomparables sans que rien ne le crie.
    """
    a = math.radians(azimut_deg)
    k = math.sqrt(0.5)
    return (k * (math.sin(a) + math.cos(a)), k * (math.cos(a) - math.sin(a)))


def profil(triangles, ux, uy):
    """Profil EXACT `z_max` par colonne d'écran, par intersection de triangle.

    Par intersection et non par échantillonnage de sommets : une colonne de
    8 cm ne contient souvent aucun sommet, et un profil bâti sur les
    sommets invente des encoches. Le générateur a payé ce défaut — il y
    rendait 5 masses là où la version exacte en rend 3.
    """
    proj = [[(ux * p[0] + uy * p[1], p[2]) for p in t] for t in triangles]
    lo = min(min(q[0] for q in t) for t in proj)
    hi = max(max(q[0] for q in t) for t in proj)
    n = int(math.ceil((hi - lo) / PAS_PROFIL)) + 1
    env = [None] * n
    for tri in proj:
        x0 = min(q[0] for q in tri)
        x1 = max(q[0] for q in tri)
        ka = max(0, int(math.ceil((x0 - lo) / PAS_PROFIL)))
        kb = min(n - 1, int(math.floor((x1 - lo) / PAS_PROFIL)))
        for q in range(ka, kb + 1):
            x = lo + q * PAS_PROFIL
            haut = None
            for pa, pb in ((tri[0], tri[1]), (tri[1], tri[2]), (tri[2], tri[0])):
                if (pa[0] - x) * (pb[0] - x) <= 0.0 and pa[0] != pb[0]:
                    f = (x - pa[0]) / (pb[0] - pa[0])
                    z = pa[1] + f * (pb[1] - pa[1])
                    if haut is None or z > haut:
                        haut = z
            if haut is not None and (env[q] is None or haut > env[q]):
                env[q] = haut
    return lo, env


def lire(env, lo, s):
    k = (s - lo) / PAS_PROFIL
    i = int(math.floor(k))
    if i < 0 or i + 1 >= len(env):
        return None
    a, b = env[i], env[i + 1]
    if a is None or b is None:
        return a if b is None else b
    return a + (b - a) * (k - i)


def colonne_vide(triangles, ax, ay):
    """(plafond du vide qualifiant le plus haut, sommet du massif) ou None.

    Parité depuis le ciel — licite ici, le maillage livré est fermé, et un
    nombre impair de croisements est signalé au lieu d'être lu.
    """
    zs = sorted(intersections_verticales(triangles, ax, ay), reverse=True)
    if not zs or len(zs) % 2:
        return None
    for k in range(len(zs) // 2 - 1):
        haut, bas = zs[2 * k + 1], zs[2 * k + 2]
        if haut - bas >= 0.30:
            return (haut, zs[0])
    return None


def main():
    args = sys.argv[1:]
    if not args:
        print("usage: cave_fix_marge.py <glb> [--marge m] [--retrait r]")
        return 3
    chemin = args[0]
    marge, retrait = 0.60, 0.35
    for k, a in enumerate(args):
        if a == "--marge":
            marge = float(args[k + 1])
        if a == "--retrait":
            retrait = float(args[k + 1])
    if not os.path.isfile(chemin):
        print("BLOQUE: fichier absent : %s" % chemin)
        return 3

    tris = charger_triangles(chemin)
    print("=== marge pour la masse corrective — %s" % chemin)
    print("    %d triangles ; seuil %.2f m + marge %.2f m ; retrait de "
          "silhouette %.2f m" % (len(tris), EPAISSEUR_MIN_M, marge, retrait))

    profils = {}
    for az in AZIMUTS:
        ux, uy = axe_silhouette(az)
        lo, env = profil(tris, ux, uy)
        profils[az] = (ux, uy, lo, env)
        connus = [v for v in env if v is not None]
        print("    profil %5.1f deg : %d colonnes, z de %.2f a %.2f m"
              % (az, len(env), min(connus), max(connus)))

    seau = [t for t in tris
            if min(p[0] for p in t) < X1 + 1.0
            and max(p[0] for p in t) > X0 - 1.0
            and min(p[1] for p in t) < Y1 + 1.0
            and max(p[1] for p in t) > Y0 - 1.0]

    nx = int(round((X1 - X0) / PAS)) + 1
    ny = int(round((Y1 - Y0) / PAS)) + 1
    print("    colonnes du sol : %d x %d, pas %.2f m" % (nx, ny, PAS))
    print("    legende : chiffre = jeu en dm (permis - exige), 'X' jeu < 0, "
          "'.' pas de vide, '=' deja conforme sans ajout")
    print("       " + "".join("%d" % (int(round((X0 + i * PAS) * 5)) % 10)
                              for i in range(nx)))
    pire = None
    besoins = []
    for j in range(ny):
        ay = Y0 + j * PAS
        ligne = []
        for i in range(nx):
            ax = X0 + i * PAS
            v = colonne_vide(seau, ax, ay)
            if v is None:
                ligne.append(".")
                continue
            plafond, sommet = v
            exige = plafond + EPAISSEUR_MIN_M + marge
            permis = None
            for az in AZIMUTS:
                ux, uy, lo, env = profils[az]
                h = lire(env, lo, ux * ax + uy * ay)
                if h is None:
                    continue
                h -= retrait
                permis = h if permis is None else min(permis, h)
            if permis is None:
                ligne.append("?")
                continue
            jeu = permis - exige
            if sommet - plafond >= EPAISSEUR_MIN_M + marge:
                ligne.append("=")
                continue
            besoins.append((ax, ay, plafond, sommet, exige, permis, jeu))
            if pire is None or jeu < pire[6]:
                pire = (ax, ay, plafond, sommet, exige, permis, jeu)
            ligne.append("X" if jeu < 0 else
                         str(min(9, int(jeu * 10))))
        print("%6.2f %s" % (ay, "".join(ligne)))

    print("    colonnes A CORRIGER (sommet - plafond < %.2f m) : %d"
          % (EPAISSEUR_MIN_M + marge, len(besoins)))
    if besoins:
        besoins.sort(key=lambda b: b[6])
        print("    les 10 plus contraintes :")
        for ax, ay, pl, so, ex, pe, je in besoins[:10]:
            print("      (%+.2f ; %.2f)  plafond %.2f  sommet %.2f  "
                  "exige %.2f  permis %.2f  jeu %+.2f"
                  % (ax, ay, pl, so, ex, pe, je))
        manque = [b for b in besoins if b[6] < 0.0]
        print("    colonnes SANS solution conforme (jeu < 0) : %d" % len(manque))
        haut = max(b[4] for b in besoins)
        print("    sommet le plus haut EXIGE par la correction : %.2f m" % haut)
    return 0


if __name__ == "__main__":
    sys.exit(main())
