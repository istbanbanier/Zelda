#!/usr/bin/env python3
"""VÉRIFICATION CROISÉE de `diff_paires.py` — chemin de code indépendant.

Ne remplace pas `diff_paires.py`, qui reste l'outil de référence. Il existe
parce que ce dossier a déjà produit trois chiffres crédibles et faux : un
nombre rendu par un seul instrument non contrôlé n'est pas une mesure.

Différences volontaires avec l'outil de référence :
  - passe par `ImageChops.difference` + `point()` (C) au lieu d'une double
    boucle Python, donc un chemin de code entièrement distinct ;
  - balaie PLUSIEURS seuils, parce qu'un compte donné à un seul seuil ne dit
    pas s'il est robuste ou s'il vit sur le bord du seuil.

Un désaccord avec `diff_paires.py` au seuil 8 est un défaut à instruire,
jamais à moyenner.

Usage : python3 verif_croisee_diff.py <dossier> [seuil1,seuil2,...]
"""

import os
import sys

from PIL import Image, ImageChops


def compte(a, b, seuil):
    """Pixels dont AU MOINS un canal s'écarte de plus de `seuil`."""
    diff = ImageChops.difference(a, b)
    # Un pixel compte si max(|dR|,|dG|,|dB|) > seuil — même règle que l'outil
    # de référence, qui teste les trois canaux par un OU.
    bandes = diff.split()
    fusion = bandes[0]
    for bande in bandes[1:]:
        fusion = ImageChops.lighter(fusion, bande)
    binaire = fusion.point(lambda v: 255 if v > seuil else 0)
    n = sum(binaire.histogram()[255:])
    return n, binaire


def main():
    if len(sys.argv) < 2:
        sys.stderr.write(__doc__)
        return 2
    d = sys.argv[1]
    seuils = [int(s) for s in sys.argv[2].split(",")] if len(sys.argv) > 2 else [4, 8, 16]
    noms = sorted(n[:-9] for n in os.listdir(d) if n.endswith("_avec.png"))
    if not noms:
        sys.stderr.write("ECHEC : aucune paire *_avec.png dans %s\n" % d)
        return 1
    entete = "%-20s" % "vue" + "".join("%14s" % ("seuil %d" % s) for s in seuils)
    print(entete)
    print("-" * len(entete))
    total_px = None
    for nom in noms:
        a = Image.open(os.path.join(d, "%s_avec.png" % nom)).convert("RGB")
        b = Image.open(os.path.join(d, "%s_sans.png" % nom)).convert("RGB")
        if a.size != b.size:
            sys.stderr.write("ECHEC : %s tailles differentes\n" % nom)
            return 1
        w, h = a.size
        total_px = w * h
        ligne = "%-20s" % nom
        boite = "—"
        for s in seuils:
            n, binaire = compte(a, b, s)
            ligne += "%9d %3.2f%%" % (n, 100.0 * n / (w * h))
            if s == seuils[len(seuils) // 2]:
                bb = binaire.getbbox()
                if bb:
                    boite = "x %d-%d  y %d-%d" % (bb[0], bb[2] - 1, bb[1], bb[3] - 1)
        print(ligne + "   " + boite)
    print("\n%d paires, %d pixels par image ; boite donnee au seuil %d"
          % (len(noms), total_px, seuils[len(seuils) // 2]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
