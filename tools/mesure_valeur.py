#!/usr/bin/env python3
"""Profil de luminance sur une ligne, ou statistiques sur un rectangle.

POURQUOI CET OUTIL. L'audit contradictoire du lot 1.R a établi son constat
central — « l'aplat de valeur » — avec une mesure unique et reproductible : un
profil de luminance en travers d'une face, à une ligne donnée. « 141 constant
sur 48 px » n'est pas une impression, c'est un nombre. Reproduire le geste
exige un outil, sinon chaque passe le refait à la main autrement et les
chiffres cessent d'être comparables.

Deux modes, et le second existe pour une raison précise : une réserve de revue
peut porter sur la VALEUR RENDUE d'une masse (« les tumuli sont très bruns et
sombres »), qui est une statistique de zone, pas un profil de ligne.

  python3 tools/mesure_valeur.py ligne  <png> <y> <x0> <x1>
  python3 tools/mesure_valeur.py zone   <png> <x0> <y0> <x1> <y1>

La luminance est celle de Rec. 709 sur les octets sRGB tels qu'ils sont dans
le fichier — c'est ce que l'œil lit à l'écran, et c'est l'unité qu'emploie
l'audit. Ce n'est PAS une mesure linéaire : ne pas s'en servir pour calculer
un albédo.
"""
import sys
from PIL import Image


def lum(p):
    return 0.2126 * p[0] + 0.7152 * p[1] + 0.0722 * p[2]


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    mode, chemin = argv[1], argv[2]
    im = Image.open(chemin).convert("RGB")
    px = im.load()
    if mode == "ligne":
        y, x0, x1 = int(argv[3]), int(argv[4]), int(argv[5])
        vals = [lum(px[x, y]) for x in range(x0, x1)]
        uniques = sorted(set(round(v) for v in vals))
        print("%s  y=%d  x %d..%d  (%d px)" % (chemin, y, x0, x1, len(vals)))
        print("  min %.1f  max %.1f  ETENDUE %.1f  moyenne %.1f"
              % (min(vals), max(vals), max(vals) - min(vals),
                 sum(vals) / len(vals)))
        print("  %d valeurs entieres distinctes : %s"
              % (len(uniques), uniques[:24]))
        return 0
    if mode == "zone":
        x0, y0, x1, y1 = (int(a) for a in argv[3:7])
        vals = [lum(px[x, y]) for y in range(y0, y1) for x in range(x0, x1)]
        vals.sort()
        n = len(vals)
        q = lambda f: vals[min(n - 1, int(f * n))]
        rs = [px[x, y] for y in range(y0, y1) for x in range(x0, x1)]
        moy = tuple(sum(c[i] for c in rs) / n for i in range(3))
        print("%s  zone %d,%d..%d,%d  (%d px)" % (chemin, x0, y0, x1, y1, n))
        print("  luminance p10 %.1f  p50 %.1f  p90 %.1f  etendue p10-p90 %.1f"
              % (q(0.10), q(0.50), q(0.90), q(0.90) - q(0.10)))
        print("  RVB moyen (%.0f, %.0f, %.0f)" % moy)
        return 0
    print("mode inconnu : ligne | zone")
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
