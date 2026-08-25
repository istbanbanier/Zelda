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



def oscillations(vals, seuil=6.0):
    """Compte les RENVERSEMENTS de pente d'un profil, au-dessus d'un seuil.

    POURQUOI CETTE MESURE EXISTE, et c'est un aveu. Le profil du dos d'un
    tumulus a été mesuré avant et après le passage aux normales lissées : p50
    68,4 -> 69,8, étendue p10-p90 identique à 59,1, nombre de valeurs
    distinctes 61 -> 62. Autrement dit : **rien**. Or l'image, ouverte à taille
    réelle, montre sans ambiguïté que les 48 bandes radiales ont disparu.

    La statistique était simplement AVEUGLE à ce qu'on jugeait. Une moyenne, un
    percentile et un compte de valeurs distinctes ignorent tous l'ARRANGEMENT
    SPATIAL ; or une bande est un motif, pas une amplitude. Une surface lisse
    et une surface rayée peuvent avoir exactement la même distribution.

    Le nombre de renversements de pente, lui, compte les bandes : un dégradé
    continu en a deux ou trois, une citrouille de 48 secteurs en a des dizaines.
    Le seuil évite de compter le bruit de quantification du PNG.

    C'est la leçon d'ISS-018 sous une autre forme : un chiffre vert sur une
    grandeur qui n'est pas celle qu'on croit mesurer.
    """
    n = 0
    direction = 0
    ancre = vals[0]
    for v in vals[1:]:
        delta = v - ancre
        if abs(delta) < seuil:
            continue
        d = 1 if delta > 0 else -1
        if direction != 0 and d != direction:
            n += 1
        direction = d
        ancre = v
    return n


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
        print("  RENVERSEMENTS de pente (>6 niveaux) : %d — c'est le compte de"
              " BANDES,\n  la seule des trois mesures qui voie un motif spatial"
              % oscillations(vals))
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
