#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""LE VIDE CIBLÉ REJOINT-IL LA SALLE SANS PASSER PAR LA PERCÉE ?

LA QUESTION, ET POURQUOI L'INONDATION ORDINAIRE NE PEUT PAS Y RÉPONDRE
=====================================================================

Sur un maillage PERCÉ, l'air intérieur et l'air extérieur ne forment
qu'une seule composante — par la percée elle-même. Constater que « ce vide
est relié à la galerie » ne prouve donc rien du tout : l'extérieur entier
l'est aussi, et par le trou. C'est un raisonnement circulaire, et il a été
tenu dans cette passe avant d'être défait.

Le critère qui décide, lui, est net :

  > Le volume ciblé doit soit être RÉELLEMENT REMPLI DE ROCHE, soit RESTER
  > RELIÉ à l'intérieur canonique par un CHEMIN INDÉPENDANT de l'ancienne
  > percée. Un simple bouchon transformant le défaut en bulle interne ne
  > constitue pas une correction.

DEUX INTERDICTIONS DE CHEMIN, ET ELLES SONT LE CŒUR DE L'OUTIL
==============================================================

1. **PLAFOND DE GRILLE.** On n'inonde qu'en dessous de `--zcap`. La percée
   du candidat vit à `z ∈ [1,45 ; 1,60]` selon la colonne ; à `zcap = 1,20`
   elle est hors grille, donc INUTILISABLE comme chemin. Ce n'est pas un
   filtre de confort : c'est ce qui rend la réponse non circulaire.

2. **BARRIÈRE DE BOUCHE, D'ÉPAISSEUR NULLE.** On refuse l'adjacence entre
   deux colonnes que sépare le plan `y = --ybouche`. Une TRANCHE PLEINE de
   cellules amputerait la cavité au lieu de la fermer — c'est le défaut
   `C4` observé en R2a-3.5.3, et le contrat l'interdit nommément (§2.1).

Sans la barrière, le tour par l'extérieur rendrait tout connecté ; sans le
plafond, la percée le ferait. Il faut les deux, et l'outil VÉRIFIE que
l'extérieur est bien resté dehors — un témoin extérieur qui se retrouverait
dans la composante de la salle invaliderait la mesure, et l'outil le dit
au lieu de conclure.

LA LECTURE DE COLONNE S'ÉCRIT UNE FOIS
======================================

`segments_air()`, et rien d'autre ne relit une liste de croisements. La
parité est licite ici — le maillage est fermé, établi par
`cave_topology_check.py` — et un compte IMPAIR est signalé, jamais lu comme
s'il était pair.

Usage :
    python3 tools/cave_fix_connexite_interne.py <glb> [--pas 0.06]
        [--zcap 1.20] [--ybouche -1.155]
"""

import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cave_void_connectivity import charger_triangles, intersections_verticales

## Repères de gameplay, en repère MODÈLE, tels que mesurés par la chaîne
## (`controle_sol_repere`) : (x, y, z du SOL). On sème au-dessus du sol.
SALLE = (2.62, 2.58, 0.084)
NICHE = (2.78, 4.09, 0.492)
CIBLE = (0.55, 5.95)          # le centre de l'ancienne percée
GRAINE_HAUTEUR_M = 0.55       # au-dessus du sol, franchement dans l'air
## Le témoin extérieur n'est PAS une constante : il est dérivé à
## l'exécution (voir plus bas). Une version antérieure le posait en dur
## à (7,20 ; 5,00) — hors de la grille — et sa garde ne pouvait donc
## jamais se déclencher.

## LA GRILLE DOIT DÉBORDER LE MASSIF, et cela a été appris en la voyant
## refuser de conclure. Première emprise : x [-4,20 ; 6,20], y [-2,60 ; 9,20]
## — entièrement CONTENUE dans l'empreinte du massif (x [-8,77 ; 8,17],
## y [-3,23 ; 11,90]). Résultat : « 0 colonne sans aucun triangle », donc
## aucun témoin extérieur, donc BLOQUÉ. Le refus était juste ; c'est la
## grille qui était trop petite pour porter la preuve qu'on lui demandait.
X0, X1 = -10.20, 10.20
Y0, Y1 = -5.20, 13.60


def segments_air(tris, ax, ay, z_bas, z_cap):
    """Segments d'AIR de la verticale, bornés à `[z_bas ; z_cap]`.

    Rend `(segments, impair)`. Parité depuis le ciel : le premier
    croisement entre dans la roche, le deuxième en sort, etc. Au-dessus du
    plus haut croisement on est dans l'air par construction.
    """
    zs = sorted(intersections_verticales(tris, ax, ay), reverse=True)
    if len(zs) % 2:
        return [], True
    bornes = [z_cap] + zs + [z_bas]
    segs = []
    # air : au-dessus de zs[0], puis entre zs[1] et zs[2], zs[3] et zs[4]...
    paires = [(z_cap, zs[0] if zs else z_bas)]
    for k in range(1, len(zs) - 1, 2):
        paires.append((zs[k], zs[k + 1]))
    if zs:
        paires.append((zs[-1], z_bas))
    for haut, bas in paires:
        h, b = min(haut, z_cap), max(bas, z_bas)
        if h - b > 1e-9:
            segs.append((h, b))
    return segs, False


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = dict(pas=0.06, zcap=1.20, ybouche=-1.155, zbas=-1.00)
    for k, a in enumerate(sys.argv[1:]):
        if a.startswith("--") and a[2:] in opt:
            opt[a[2:]] = float(sys.argv[k + 2])
    if not args:
        print("usage: cave_fix_connexite_interne.py <glb> [--pas .. --zcap ..]")
        return 3
    chemin = args[0]
    if not os.path.isfile(chemin):
        print("BLOQUE: fichier absent : %s" % chemin)
        return 3

    pas, zcap, ybouche, zbas = (opt["pas"], opt["zcap"], opt["ybouche"],
                                opt["zbas"])
    tris = charger_triangles(chemin)

    # Index spatial : sans lui, chaque colonne teste 20 000 triangles.
    cell = 0.50
    index = defaultdict(list)
    for t in tris:
        i0 = int((min(p[0] for p in t) - X0) // cell)
        i1 = int((max(p[0] for p in t) - X0) // cell)
        j0 = int((min(p[1] for p in t) - Y0) // cell)
        j1 = int((max(p[1] for p in t) - Y0) // cell)
        for i in range(i0, i1 + 1):
            for j in range(j0, j1 + 1):
                index[(i, j)].append(t)

    nx = int((X1 - X0) / pas) + 1
    ny = int((Y1 - Y0) / pas) + 1
    print("=== connexite INTERNE — %s" % chemin)
    print("    pas %.3f m, plafond de grille z <= %.2f, barriere de bouche "
          "y = %.3f (epaisseur nulle), plancher z >= %.2f"
          % (pas, zcap, ybouche, zbas))
    print("    grille %d x %d colonnes sur x [%.2f ; %.2f] y [%.2f ; %.2f]"
          % (nx, ny, X0, X1, Y0, Y1))

    cols, impairs = {}, 0
    for j in range(ny):
        ay = Y0 + j * pas
        for i in range(nx):
            ax = X0 + i * pas
            seau = index.get((int((ax - X0) // cell), int((ay - Y0) // cell)), [])
            if not seau:
                cols[(i, j)] = [(zcap, zbas)]      # colonne entierement dehors
                continue
            segs, imp = segments_air(seau, ax, ay, zbas, zcap)
            if imp:
                impairs += 1
                continue
            cols[(i, j)] = segs
    print("    colonnes lues %d ; colonnes a compte IMPAIR (ecartees) %d"
          % (len(cols), impairs))

    # Graphe de segments : deux segments voisins communiquent si leurs
    # intervalles z se chevauchent. La barriere coupe l'adjacence en y.
    noeuds = []
    ref = {}
    for (i, j), segs in cols.items():
        for s, (h, b) in enumerate(segs):
            ref[(i, j, s)] = len(noeuds)
            noeuds.append((i, j, h, b))
    adj = defaultdict(list)
    for (i, j, s), n in ref.items():
        h, b = noeuds[n][2], noeuds[n][3]
        for di, dj in ((1, 0), (0, 1)):
            if (i + di, j + dj) not in cols:
                continue
            if dj:
                ya, yb = Y0 + j * pas, Y0 + (j + dj) * pas
                if (ya - ybouche) * (yb - ybouche) < 0.0:
                    continue          # la barriere separe ces deux colonnes
            for s2, (h2, b2) in enumerate(cols[(i + di, j + dj)]):
                if min(h, h2) - max(b, b2) > 1e-9:
                    m = ref[(i + di, j + dj, s2)]
                    adj[n].append(m)
                    adj[m].append(n)

    vu = [-1] * len(noeuds)
    comps = []
    for n in range(len(noeuds)):
        if vu[n] >= 0:
            continue
        c = len(comps)
        pile, taille, vol = [n], 0, 0.0
        vu[n] = c
        while pile:
            q = pile.pop()
            taille += 1
            vol += (noeuds[q][2] - noeuds[q][3]) * pas * pas
            for m in adj[q]:
                if vu[m] < 0:
                    vu[m] = c
                    pile.append(m)
        comps.append((taille, vol))
    print("    composantes d'AIR sous le plafond : %d" % len(comps))
    for c, (taille, vol) in sorted(enumerate(comps), key=lambda e: -e[1][1])[:6]:
        print("      composante %d : %d segment(s), %.2f m3" % (c, taille, vol))

    def ou(ax, ay, az, nom):
        i = int(round((ax - X0) / pas))
        j = int(round((ay - Y0) / pas))
        if (i, j) not in cols:
            print("      %-16s (%.2f ; %.2f ; %.2f) : colonne ECARTEE"
                  % (nom, ax, ay, az))
            return None
        for s, (h, b) in enumerate(cols[(i, j)]):
            if b - 1e-9 <= az <= h + 1e-9:
                c = vu[ref[(i, j, s)]]
                print("      %-16s (%.2f ; %.2f ; %.2f) : AIR, composante %d"
                      % (nom, ax, ay, az, c))
                return c
        print("      %-16s (%.2f ; %.2f ; %.2f) : DANS LA ROCHE"
              % (nom, ax, ay, az))
        return "roche"

    print("    classement des temoins :")
    c_salle = ou(SALLE[0], SALLE[1], SALLE[2] + GRAINE_HAUTEUR_M, "MODELE_SALLE")
    c_niche = ou(NICHE[0], NICHE[1], NICHE[2] + GRAINE_HAUTEUR_M, "MODELE_NICHE")
    c_cible = ou(CIBLE[0], CIBLE[1], 0.80, "VIDE CIBLE")

    # LE TÉMOIN EXTÉRIEUR EST DÉRIVÉ, ET C'EST UNE CORRECTION DE CET OUTIL.
    #
    # Première version : un témoin en dur à `(7,20 ; 5,00)`. Il tombait HORS
    # DE LA GRILLE (`i = 190` pour `nx = 174`), `ou()` rendait `None`, et la
    # garde `if c_dehors == c_salle` ne pouvait donc JAMAIS se déclencher.
    # Le tour de passe-passe est celui que `PROMPT4_METHOD` §2 nomme : une
    # assertion qui ne rougirait pas en cas de régression. Elle a imprimé
    # « l'exterieur est bien SEPARE » sans avoir rien vérifié.
    #
    # On prend donc pour témoin une colonne DONT ON SAIT qu'elle est dehors :
    # une colonne sans un seul triangle dans sa cellule. Si aucune n'existe,
    # la séparation n'est pas démontrable et l'outil sort en BLOQUÉ au lieu
    # de conclure.
    dehors = [(i, j) for (i, j) in cols
              if not index.get((int((X0 + i * pas - X0) // cell),
                                int((Y0 + j * pas - Y0) // cell)))]
    print("    colonnes SANS aucun triangle (donc hors du solide) : %d"
          % len(dehors))
    c_dehors = None
    if dehors:
        # La plus éloignée du centre du massif, pour ne pas prendre une
        # colonne coincée dans un repli de la surface.
        i, j = max(dehors, key=lambda e: abs(X0 + e[0] * pas) + abs(Y0 + e[1] * pas))
        c_dehors = ou(X0 + i * pas, Y0 + j * pas, 1.00, "temoin DEHORS")

    print("    " + "-" * 66)
    if c_salle is None or c_salle == "roche":
        print("    BLOQUE : la graine de salle n'est pas dans l'air — une "
              "graine dans la roche rendrait n'importe quoi sans rien prouver")
        return 3
    if c_dehors is None:
        print("    BLOQUE : aucun temoin exterieur exploitable dans la "
              "grille — la separation interieur/exterieur n'est pas "
              "demontree, et un verdict pose dessus ne vaudrait rien")
        return 3
    if c_dehors == c_salle:
        print("    BLOQUE : le temoin EXTERIEUR est dans la composante de la "
              "salle — la barriere ou le plafond ne tiennent pas, la mesure "
              "ne prouve rien")
        return 3
    print("    l'exterieur (composante %s) est bien SEPARE de la salle "
          "(composante %s) sous ce plafond : la mesure est exploitable"
          % (c_dehors, c_salle))
    if c_cible == "roche":
        print("    VERDICT : le vide cible est REMPLI DE ROCHE — correction "
              "par remplissage")
        return 0
    if c_cible is None:
        print("    VERDICT : NON VERIFIE — colonne cible ecartee")
        return 3
    if c_cible == c_salle:
        print("    VERDICT : le vide cible REJOINT LA SALLE par un chemin "
              "SOUS le plafond, donc independant de l'ancienne percee")
        return 0
    print("    VERDICT : le vide cible est une POCHE ISOLEE (composante %s, "
          "salle en %s) — un bouchon, PAS une correction"
          % (c_cible, c_salle))
    return 1


if __name__ == "__main__":
    sys.exit(main())
