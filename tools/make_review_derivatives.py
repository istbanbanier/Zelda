#!/usr/bin/env python3
"""Produit les dérivés de revue d'un dossier de captures : vignette 320x180
et niveaux de gris (protocole VISUAL_ASSET_BIBLE §30.1, points 1-2).

Usage : python3 tools/make_review_derivatives.py <dossier_png> [dossier_sortie]

Les dérivés vont dans <dossier_sortie>/vignettes et /gris (par défaut à côté
des sources). Jamais de réécriture des sources.
"""
import sys
from pathlib import Path

from PIL import Image


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    src = Path(sys.argv[1])
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else src
    if not src.is_dir():
        print(f"BLOQUÉ : dossier introuvable : {src}")
        return 3
    vign = out / "vignettes"
    grey = out / "gris"
    vign.mkdir(parents=True, exist_ok=True)
    grey.mkdir(parents=True, exist_ok=True)
    count = 0
    for png in sorted(src.glob("*.png")):
        with Image.open(png) as im:
            im.convert("RGB").resize((320, 180)).save(vign / png.name)
            im.convert("L").save(grey / png.name)
        count += 1
    print(f"OK : {count} captures -> {vign} et {grey}")
    return 0 if count else 1


if __name__ == "__main__":
    sys.exit(main())
