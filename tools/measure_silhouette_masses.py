#!/usr/bin/env python3
"""Compte et MESURE les masses d'une silhouette, au lieu de les juger a l'oeil.

POURQUOI CET OUTIL. La consigne « trois masses majeures larges et
asymetriques » est verifiable, et elle ne l'etait pas : je regardais l'image
et j'ecrivais une impression. Or « trois masses larges » et « dix colonnes de
meme largeur » produisent tous deux une tache sombre compacte en vignette —
et la seconde est precisement le defaut reproche a la formation rocheuse
batie d'un seul module repete.

CE QU'IL MESURE. Sur une silhouette produite par `capture_silhouette.gd`
(deux populations de pixels, projection ORTHOGONALE, cadrage derive de
l'AABB), il lit le PROFIL SUPERIEUR — pour chaque colonne, le premier pixel
de sujet en partant du haut — puis decoupe ce profil aux ENTAILLES : les
creux d'au moins `--entaille` metres sous les deux sommets qui les
encadrent. Chaque segment entre deux entailles est une masse ; l'outil rend
sa largeur et sa hauteur, en metres.

  masses larges et asymetriques -> peu de segments, largeurs tres inegales
  picket de colonnes            -> beaucoup de segments, largeurs serrees

Le coefficient de variation des largeurs (`cv_largeurs`) chiffre cette
inegalite : proche de 0 = toutes les masses ont la meme largeur.

L'ECHELLE N'EST PAS DEVINEE. Elle est refaite depuis le manifeste, avec la
meme arithmetique que l'outil de capture :

    largeur_apparente = max(taille_x, taille_z)
    hauteur_requise   = max(taille_y, largeur_apparente * H / W)
    camera.size       = hauteur_requise * (1 + 2 * MARGE)
    metres_par_pixel  = camera.size / H

Une projection PERSPECTIVE rendrait ce calcul faux ; le manifeste porte
`projection`, et l'outil refuse de mesurer si ce n'est pas orthogonal.

Usage :
  python3 tools/measure_silhouette_masses.py <manifest_silhouettes.json>
                                             [--entaille=0.60]
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

from PIL import Image

## Marge du cadrage, identique a `MARGE` dans `capture_silhouette.gd`. Si
## l'une bouge sans l'autre, l'echelle est fausse en silence — d'ou le
## rappel ici plutot qu'un nombre nu dans la formule.
MARGE = 0.10

## Sous cette luminance un pixel appartient au SUJET. Meme seuil que le
## controle bimodal de l'outil de capture.
SEUIL_SUJET = 0.18


def _profil_superieur(image: Image.Image) -> list[int | None]:
    """Pour chaque colonne, la ligne du premier pixel de sujet, ou None."""
    gris = image.convert("L")
    largeur, hauteur = gris.size
    pixels = gris.load()
    seuil = SEUIL_SUJET * 255.0
    profil: list[int | None] = []
    for x in range(largeur):
        haut = None
        for y in range(hauteur):
            if pixels[x, y] <= seuil:
                haut = y
                break
        profil.append(haut)
    return profil


def _sommets(profil: list[int | None], entaille_px: float,
             hauteur_px: int) -> list[tuple]:
    """Les sommets du profil, retenus par PROEMINENCE.

    PREMIERE VERSION, ET POURQUOI ELLE ETAIT FAUSSE. J'avais decoupe le
    profil aux « creux profonds des deux cotes ». Sur un escalier
    descendant, chaque marche a bien un sommet plus haut a sa gauche et un
    autre plus haut a sa droite : toutes ont ete retenues, et l'outil a
    rendu des masses de 0,06 m. Une masse de six centimetres n'existe pas ;
    le critere etait bon, son implementation confondait « marche » et
    « col ».

    La proeminence topographique est la primitive correcte. Pour chaque
    maximum local, on descend a gauche jusqu'a rencontrer un point PLUS
    HAUT (ou le bord) en retenant le point le plus bas du trajet : c'est le
    col gauche. Idem a droite. La proeminence est la hauteur du sommet
    au-dessus du PLUS HAUT des deux cols. Une marche d'escalier a une
    proeminence nulle par construction — elle ne peut plus etre comptee.

    Rend, par sommet retenu : x de debut et de fin de son emprise au niveau
    `sommet - entaille`, sa largeur en pixels, sa hauteur en pixels.
    """
    xs = [x for x, y in enumerate(profil) if y is not None]
    if not xs:
        return []
    x0, x1 = xs[0], xs[-1]
    # Hauteur croissante vers le haut : plus lisible qu'une ligne d'image.
    haut = [hauteur_px - profil[x] if profil[x] is not None else 0
            for x in range(x0, x1 + 1)]
    n = len(haut)

    sortie = []
    i = 0
    while i < n:
        # Plateau maximal : [i ; j] de meme hauteur, strictement plus haut
        # que ses deux voisins immediats.
        j = i
        while j + 1 < n and haut[j + 1] == haut[i]:
            j += 1
        gauche_plus_bas = i == 0 or haut[i - 1] < haut[i]
        droite_plus_bas = j == n - 1 or haut[j + 1] < haut[j]
        if not (gauche_plus_bas and droite_plus_bas):
            i = j + 1
            continue

        col_g = haut[i]
        k = i - 1
        while k >= 0 and haut[k] <= haut[i]:
            col_g = min(col_g, haut[k])
            k -= 1
        if k < 0:
            col_g = min(col_g, haut[0])
        col_d = haut[j]
        k = j + 1
        while k < n and haut[k] <= haut[j]:
            col_d = min(col_d, haut[k])
            k += 1
        if k >= n:
            col_d = min(col_d, haut[n - 1])

        proeminence = haut[i] - max(col_g, col_d)
        if proeminence >= entaille_px:
            niveau = haut[i] - entaille_px
            a = i
            while a > 0 and haut[a - 1] >= niveau:
                a -= 1
            b = j
            while b < n - 1 and haut[b + 1] >= niveau:
                b += 1
            sortie.append((x0 + a, x0 + b, b - a + 1, haut[i], proeminence))
        i = j + 1

    # Deux sommets peuvent partager la meme emprise au niveau mesure ; on ne
    # garde alors que le plus haut, sans quoi une masse serait comptee deux
    # fois.
    sortie.sort(key=lambda s: -s[3])
    retenus: list[tuple] = []
    for s in sortie:
        if not any(s[0] <= r[1] and r[0] <= s[1] for r in retenus):
            retenus.append(s)
    retenus.sort(key=lambda s: s[0])
    return retenus


def mesurer(manifeste: Path, entaille_m: float) -> int:
    meta = json.loads(manifeste.read_text(encoding="utf-8"))
    if meta.get("projection") != "orthogonale":
        print("BLOQUÉ : projection « %s » — l'echelle ne se refait qu'en "
              "orthogonal" % meta.get("projection"))
        return 3
    taille = meta["size"].split("x")
    largeur_px, hauteur_px = int(taille[0]), int(taille[1])
    sx, sy, sz = (float(v) for v in meta["emprise_m"])
    largeur_apparente = max(sx, sz)
    hauteur_requise = max(sy, largeur_apparente * hauteur_px / largeur_px)
    camera_size = hauteur_requise * (1.0 + MARGE * 2.0)
    m_par_px = camera_size / hauteur_px
    entaille_px = entaille_m / m_par_px

    print("sujet %s — %.4f m/pixel, entaille %.2f m = %.1f px"
          % (meta.get("sujet", "?"), m_par_px, entaille_m, entaille_px))
    racine = manifeste.parent
    for vue in meta["vues"]:
        chemin = Path(vue["image"])
        if not chemin.exists():
            chemin = racine / Path(vue["image"]).name
        image = Image.open(chemin)
        profil = _profil_superieur(image)
        masses = _sommets(profil, entaille_px, hauteur_px)
        largeurs = [n * m_par_px for _, _, n, _, _ in masses]
        moyenne = sum(largeurs) / len(largeurs) if largeurs else 0.0
        if len(largeurs) > 1 and moyenne > 0.0:
            variance = sum((l - moyenne) ** 2 for l in largeurs) / len(largeurs)
            cv = math.sqrt(variance) / moyenne
        else:
            cv = 0.0
        print("  %-38s %2d masse(s), largeur moyenne %.2f m, cv %.2f"
              % (chemin.name, len(masses), moyenne, cv))
        for (a, b, n, sommet, prom), l in zip(masses, largeurs):
            print("      x %4d-%4d   largeur %5.2f m   proeminence %5.2f m"
                  % (a, b, l, prom * m_par_px))
    return 0


def main() -> int:
    entaille = 0.60
    args = []
    for a in sys.argv[1:]:
        if a.startswith("--entaille="):
            entaille = float(a.split("=", 1)[1])
        else:
            args.append(a)
    if not args:
        print(__doc__)
        return 2
    return mesurer(Path(args[0]), entaille)


if __name__ == "__main__":
    raise SystemExit(main())
