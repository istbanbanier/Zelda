#!/usr/bin/env python3
"""Triptyque R2B / R2B.1 / R2B.2 d'une vue, aux TROIS MÊMES caméras.

Les trois panneaux sortent d'un seul et même fichier de caméras
(`shots_r2b1.json`) : le panneau R2B vient du lot `avant/` de R2B.1, qui montre
la géométrie R2B capturée aux caméras R2B.1 — vérifié par le lead, `git diff`
vide sur `source_assets`, `assets` et `scripts/world_v2/poi` entre la base de
R2B.1 et le commit de ce lot. Le risque de substituer un cadrage favorable est
donc écarté par construction, et non par bonne volonté.

Usage :
  python3 compose_triptyques.py <dossier_r2b2> <dossier_sortie> vue1 [vue2 ...]
"""
import os
import sys
from PIL import Image, ImageDraw

R2B = "evidence/world_v2/v2_3_r2b1/avant"
R2B1 = "evidence/world_v2/v2_3_r2b1/apres_integre"
MARGE = 10
BANDEAU = 34
FOND = (22, 22, 24)
TEXTE = (232, 228, 220)


def compose(vue, dossier_r2b2, sortie):
    chemins = [(os.path.join(R2B, vue + ".png"), "R2B"),
               (os.path.join(R2B1, vue + ".png"), "R2B.1"),
               (os.path.join(dossier_r2b2, vue + ".png"), "R2B.2")]
    for c, _ in chemins:
        if not os.path.exists(c):
            print("ABSENT : %s" % c)
            return False
    ims = [Image.open(c).convert("RGB") for c, _ in chemins]
    l, h = ims[0].size
    for im in ims[1:]:
        if im.size != (l, h):
            print("TAILLES DIFFÉRENTES sur %s : %s" % (vue, [i.size for i in ims]))
            return False
    l2, h2 = l * 2 // 3, h * 2 // 3
    planche = Image.new("RGB", (3 * l2 + 4 * MARGE, h2 + 2 * MARGE + BANDEAU), FOND)
    d = ImageDraw.Draw(planche)
    for i, (im, (_, nom)) in enumerate(zip(ims, chemins)):
        x = MARGE + i * (l2 + MARGE)
        planche.paste(im.resize((l2, h2), Image.LANCZOS), (x, MARGE + BANDEAU))
        d.text((x + 4, MARGE + 8), "%s  /  %s" % (nom, vue), fill=TEXTE)
    chemin = os.path.join(sortie, "triptyque_%s.png" % vue)
    planche.save(chemin)
    print("%s  (%dx%d)" % (chemin, planche.size[0], planche.size[1]))
    return True


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    src, out, vues = argv[0], argv[1], argv[2:]
    os.makedirs(out, exist_ok=True)
    ok = sum(1 for v in vues if compose(v, src, out))
    print("%d/%d triptyques composés" % (ok, len(vues)))
    return 0 if ok == len(vues) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
