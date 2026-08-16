#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""BALAYAGE 5 mm de la percée, sur une FENÊTRE AGRANDIE.

POURQUOI AGRANDIE, ET C'EST TOUT L'INTÉRÊT
==========================================

La fenêtre de R2a-3.5.3 fait 30 × 30 cm autour du défaut connu. Rejouée
telle quelle après correction, elle répond à « ce trou-là est-il bouché ? »
et à rien d'autre. Or la question qui compte après une correction est
« le défaut a-t-il DISPARU, ou s'est-il DÉPLACÉ de quarante centimètres ? »,
et une fenêtre calée sur l'ancienne position ne peut pas la poser.

On balaie donc 1,20 × 1,60 m au même pas de 5 mm — seize fois la surface —
centré sur l'ancien défaut et débordant largement des deux lobes minces
cartographiés par `tools/cave_fix_carte_toit.py`.

LE TEST, ET SES DEUX GARDE-FOUS PAYÉS PAR QUELQU'UN
==================================================

Depuis un point DANS le vide, compter les traversées en MONTANT. Zéro
traversée = on voit le ciel.

  1. Compter *tous* les croisements d'une verticale NE PEUT PAS voir une
     percée : le rayon traverse le trou puis coupe le plancher. On compte
     donc au-dessus, séparément.
  2. « Zéro traversée au-dessus » peut aussi vouloir dire « ce point est
     déjà au-dessus du massif ». On exige donc de la roche EN DESSOUS ; une
     colonne sans croisement des deux côtés est hors du solide et ne prouve
     rien. Le nombre de colonnes ainsi écartées est PUBLIÉ, jamais tu.

Le filtre `SM_WaterfallCave` de `charger_triangles()` lève si le nœud est
absent : la coque de collision `COL_WaterfallCave` rebouche la galerie et
rendrait « 3,06 m de roche continue » là où il y en a 0,038.

Usage :
    python3 tools/cave_fix_percee_scan.py <glb> [<glb> ...] [--z 1.50]
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cave_void_connectivity import charger_triangles, intersections_verticales

## Fenêtre AGRANDIE. La fenêtre d'origine faisait 30 × 30 cm et l'emprise
## qu'elle rendait — `x ∈ [0,468 ; 0,623]`, `ay ∈ [5,850 ; 6,045]` — TOUCHAIT
## DEUX DE SES BORDS : `x = 0,468` est son bord ouest et `ay = 6,045` son bord
## nord. Elle ne mesurait donc pas le trou, elle mesurait son intersection
## avec elle-même. Réglable en ligne de commande, et le fait qu'une emprise
## touche un bord est SIGNALÉ.
X0, X1 = -1.60, 1.60
Y0, Y1 = 4.60, 8.20
PAS = 0.005
## Départ du rayon : dans le vide de la galerie, comme la mesure d'origine.
Z_DEPART = 1.50


def balayer(chemin, z_depart):
    tris = charger_triangles(chemin)
    # INDEX SPATIAL, ET IL N'EST PAS UN CONFORT. Sans lui chaque colonne
    # teste les 20 000 triangles du maillage : la première tentative sur
    # 3,20 × 3,20 m au pas de 5 mm — 410 881 colonnes — a dû être tuée avant
    # d'avoir imprimé sa première ligne de résultat.
    cell = 0.25
    index = {}
    for t in tris:
        if (min(p[0] for p in t) > X1 + 0.6 or max(p[0] for p in t) < X0 - 0.6
                or min(p[1] for p in t) > Y1 + 0.6
                or max(p[1] for p in t) < Y0 - 0.6):
            continue
        i0 = int((min(p[0] for p in t) - X0) // cell)
        i1 = int((max(p[0] for p in t) - X0) // cell)
        j0 = int((min(p[1] for p in t) - Y0) // cell)
        j1 = int((max(p[1] for p in t) - Y0) // cell)
        for i in range(i0, i1 + 1):
            for j in range(j0, j1 + 1):
                index.setdefault((i, j), []).append(t)

    nx = int(round((X1 - X0) / PAS)) + 1
    ny = int(round((Y1 - Y0) / PAS)) + 1
    trou, hors, impair = [], 0, 0
    histo = {}
    for j in range(ny):
        ay = Y0 + j * PAS
        jc = int((ay - Y0) // cell)
        for i in range(nx):
            ax = X0 + i * PAS
            seau = index.get((int((ax - X0) // cell), jc))
            if not seau:
                hors += 1        # aucune matiere dans la cellule : hors solide
                continue
            zs = intersections_verticales(seau, ax, ay)
            haut = [z for z in zs if z > z_depart]
            bas = [z for z in zs if z <= z_depart]
            if not bas:
                hors += 1                       # hors du solide : écartée
                continue
            n = len(haut)
            histo[n] = histo.get(n, 0) + 1
            # UN COMPTE IMPAIR EST UNE ANOMALIE, PAS UNE STATISTIQUE. Sur un
            # maillage fermé, un rayon parti de l'air et monté à l'infini
            # traverse un nombre PAIR de surfaces. Un compte impair signale
            # un rasant numérique ou une auto-traversée ; on le publie
            # séparément au lieu de le noyer dans un « autres ».
            if n % 2:
                impair += 1
            if n == 0:
                trou.append((ax, ay))           # roche dessous, ciel dessus
    return nx * ny, trou, hors, impair, histo


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    z_depart = Z_DEPART
    for k, a in enumerate(sys.argv[1:]):
        if a == "--z":
            z_depart = float(sys.argv[k + 2])
    if not args:
        print("usage: cave_fix_percee_scan.py <glb> [<glb> ...] [--z 1.50]")
        return 3
    rouge = 0
    print("=== balayage 5 mm, fenetre AGRANDIE %.2f x %.2f m, depart z=%.2f"
          % (X1 - X0, Y1 - Y0, z_depart))
    for chemin in args:
        if not os.path.isfile(chemin):
            print("BLOQUE: fichier absent : %s" % chemin)
            return 3
        n, trou, hors, impair, histo = balayer(chemin, z_depart)
        aire = len(trou) * (PAS * 100.0) ** 2
        print("--- %s" % chemin)
        print("    %d colonnes ; TROU %d (aire %.1f cm2) ; ecartees hors du "
              "solide %d ; comptes IMPAIRS %d"
              % (n, len(trou), aire, hors, impair))
        print("    traversees au-dessus de z=%.2f : %s" % (z_depart, ", ".join(
            "%d->%d" % (k, histo[k]) for k in sorted(histo))))
        if trou:
            rouge = 1
            xs = [p[0] for p in trou]
            ys = [p[1] for p in trou]
            print("    EMPRISE x [%.3f ; %.3f]  y [%.3f ; %.3f]  = %.0f x %.0f mm"
                  % (min(xs), max(xs), min(ys), max(ys),
                     (max(xs) - min(xs)) * 1000 + PAS * 1000,
                     (max(ys) - min(ys)) * 1000 + PAS * 1000))
            for nom, val, bord in (("x min", min(xs), X0), ("x max", max(xs), X1),
                                   ("y min", min(ys), Y0), ("y max", max(ys), Y1)):
                if abs(val - bord) < PAS * 1.5:
                    print("    AVERT: l'emprise touche le bord %s de la "
                          "fenetre (%.3f) — l'aire est MINOREE, la fenetre "
                          "coupe le trou" % (nom, bord))
            print("    VERDICT : ROUGE — le massif est ouvert sur le ciel")
        else:
            print("    VERDICT : VERT — aire ouverte EXACTEMENT 0 sur la "
                  "fenetre agrandie")
    return rouge


if __name__ == "__main__":
    sys.exit(main())
