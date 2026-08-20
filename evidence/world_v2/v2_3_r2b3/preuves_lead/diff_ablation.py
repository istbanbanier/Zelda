#!/usr/bin/env python3
"""Combien de pixels un objet dessine-t-il RÉELLEMENT dans une vue donnée ?

Compare deux lots capturés aux MÊMES caméras — l'un complet, l'autre avec des
maillages éteints — et rend, par vue, la part de l'image qui change.

C'est la seule façon honnête d'attribuer un défaut à un objet. En R2B.2, deux
attributions faites à l'œil se sont révélées fausses : une aile sombre imputée
au jupon de racines appartenait à une branche, et une « plaque crème sans
matière » était de l'herbe verte. L'ablation ne se trompe pas de coupable.

Sort aussi la boîte englobante des pixels modifiés : elle dit OÙ l'objet est
visible dans le cadre, ce qu'un pourcentage seul ne dit pas.

Usage :
    python3 diff_ablation.py <dir_complet> <dir_ablate> [seuil]
"""

import os
import sys

from PIL import Image

SEUIL_DEFAUT = 8   # écart par canal au-delà duquel un pixel a « changé »


def main():
    if len(sys.argv) < 3:
        sys.stderr.write(__doc__)
        return 2
    d_plein, d_abl = sys.argv[1], sys.argv[2]
    seuil = int(sys.argv[3]) if len(sys.argv) > 3 else SEUIL_DEFAUT

    noms = sorted(n[:-4] for n in os.listdir(d_abl) if n.endswith(".png"))
    if not noms:
        sys.stderr.write("ECHEC : aucun PNG dans %s\n" % d_abl)
        return 1
    print("%-20s %9s %9s  %s" % ("vue", "pixels", "part", "boîte des pixels changés"))
    total_part = 0.0
    for nom in noms:
        pa = os.path.join(d_plein, "%s.png" % nom)
        pb = os.path.join(d_abl, "%s.png" % nom)
        if not os.path.exists(pa):
            print("%-20s %9s  (absente du lot complet)" % (nom, "-"))
            continue
        a = Image.open(pa).convert("RGB")
        b = Image.open(pb).convert("RGB")
        if a.size != b.size:
            sys.stderr.write("ECHEC : %s tailles %s vs %s\n" % (nom, a.size, b.size))
            return 1
        w, h = a.size
        pa_px, pb_px = a.load(), b.load()
        n = 0
        x0, y0, x1, y1 = w, h, -1, -1
        for y in range(h):
            for x in range(w):
                ca, cb = pa_px[x, y], pb_px[x, y]
                if (abs(ca[0] - cb[0]) > seuil or abs(ca[1] - cb[1]) > seuil
                        or abs(ca[2] - cb[2]) > seuil):
                    n += 1
                    if x < x0: x0 = x
                    if y < y0: y0 = y
                    if x > x1: x1 = x
                    if y > y1: y1 = y
        part = 100.0 * n / (w * h)
        total_part += part
        boite = ("x %d–%d  y %d–%d" % (x0, x1, y0, y1)) if n else "—"
        print("%-20s %9d %8.2f%%  %s" % (nom, n, part, boite))
    print("seuil par canal : %d" % seuil)
    return 0


if __name__ == "__main__":
    sys.exit(main())
