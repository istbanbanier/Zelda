#!/usr/bin/env python3
"""Contribution réelle d'un objet à l'image, mesurée en PAIRES intra-processus.

Chaque vue existe en deux versions rendues à une trame d'écart dans le même
processus : `<vue>_avec.png` et `<vue>_sans.png`. La seule variable entre les
deux est la visibilité de l'objet — le vent n'a avancé que d'une trame.

POURQUOI PAS UN DIFF ENTRE DEUX EXÉCUTIONS. Mesuré le 2026-08-20 : deux
exécutions séparées du même code, sans rien éteindre, diffèrent déjà de 0,90 %
à 6,44 % des pixels — y compris sur des vues où l'objet visé n'apparaît pas.
La végétation animée ne se stabilise pas à la même phase. Un diff
inter-processus mesure le vent, pas l'objet.

Usage :
    python3 diff_paires.py <dir> [seuil]
"""

import os
import sys

from PIL import Image

SEUIL_DEFAUT = 8


def main():
    if len(sys.argv) < 2:
        sys.stderr.write(__doc__)
        return 2
    d = sys.argv[1]
    seuil = int(sys.argv[2]) if len(sys.argv) > 2 else SEUIL_DEFAUT
    noms = sorted(n[:-9] for n in os.listdir(d) if n.endswith("_avec.png"))
    if not noms:
        sys.stderr.write("ECHEC : aucune paire *_avec.png dans %s\n" % d)
        return 1
    print("%-20s %9s %8s  %s" % ("vue", "pixels", "part", "boîte des pixels de l'objet"))
    for nom in noms:
        a = Image.open(os.path.join(d, "%s_avec.png" % nom)).convert("RGB")
        b = Image.open(os.path.join(d, "%s_sans.png" % nom)).convert("RGB")
        if a.size != b.size:
            sys.stderr.write("ECHEC : %s tailles différentes\n" % nom)
            return 1
        w, h = a.size
        pa, pb = a.load(), b.load()
        n = 0
        x0, y0, x1, y1 = w, h, -1, -1
        for y in range(h):
            for x in range(w):
                ca, cb = pa[x, y], pb[x, y]
                if (abs(ca[0] - cb[0]) > seuil or abs(ca[1] - cb[1]) > seuil
                        or abs(ca[2] - cb[2]) > seuil):
                    n += 1
                    if x < x0: x0 = x
                    if y < y0: y0 = y
                    if x > x1: x1 = x
                    if y > y1: y1 = y
        boite = ("x %d–%d  y %d–%d" % (x0, x1, y0, y1)) if n else "—"
        print("%-20s %9d %7.2f%%  %s" % (nom, n, 100.0 * n / (w * h), boite))
    print("seuil par canal : %d" % seuil)
    return 0


if __name__ == "__main__":
    sys.exit(main())
