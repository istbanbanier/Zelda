#!/usr/bin/env python3
"""Dérive une planche NIVEAUX DE GRIS des captures couleur, sans re-rendre.

POURQUOI. Le §7 de R2B.2 demande une « silhouette en niveaux de gris » pour la
ferme et pour l'arbre. Une conversion depuis la capture couleur est la seule
forme HONNÊTE de cette planche ici : elle porte exactement les mêmes pixels que
la vue jugée, à la caméra imposée, sans introduire un second rendu qui pourrait
différer. `VISUAL_ASSET_BIBLE` §30.1 le demande d'ailleurs ainsi — « la même
caméra, la même seed, la même exposition ».

Luminance Rec. 709 : 0,2126 R + 0,7152 V + 0,0722 B. Ce n'est pas une moyenne
naïve — le vert pèse sept fois le bleu, et sur une prairie verte une moyenne
naïve mentirait sur les valeurs.

Usage :
  python3 planche_niveaux_de_gris.py <sortie.png> <image1.png> [image2.png ...]
"""
import sys
from PIL import Image

MARGE = 8
FOND = (24, 24, 26)


def gris(chemin):
    im = Image.open(chemin).convert("RGB")
    px = im.load()
    L, H = im.size
    out = Image.new("L", (L, H))
    op = out.load()
    for x in range(L):
        for y in range(H):
            r, v, b = px[x, y]
            op[x, y] = int(0.2126 * r + 0.7152 * v + 0.0722 * b)
    return out.convert("RGB")


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    sortie, sources = argv[0], argv[1:]
    vignettes = [gris(s) for s in sources]
    lignes = (len(vignettes) + 2) // 3
    cols = min(3, len(vignettes))
    l, h = vignettes[0].size
    l2, h2 = l // 2, h // 2
    planche = Image.new("RGB",
                        (cols * l2 + (cols + 1) * MARGE,
                         lignes * h2 + (lignes + 1) * MARGE), FOND)
    for i, v in enumerate(vignettes):
        c, r = i % 3, i // 3
        planche.paste(v.resize((l2, h2), Image.LANCZOS),
                      (MARGE + c * (l2 + MARGE), MARGE + r * (h2 + MARGE)))
    planche.save(sortie)
    print("planche %d vue(s) -> %s (%dx%d)"
          % (len(vignettes), sortie, planche.size[0], planche.size[1]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
