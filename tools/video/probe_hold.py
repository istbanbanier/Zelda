#!/usr/bin/env python3
"""Sonde vent/orage sur la PHASE IMMOBILE (frames 0-35) : sans
parallaxe, toute différence entre frames vient du vent, de la tempête
ou d'une instabilité de rendu."""
import glob
import sys
from PIL import Image, ImageChops, ImageStat

paths = sorted(glob.glob(sys.argv[1] + "*.png"))[:36]
if len(paths) < 30:
    print(f"ECHEC: {len(paths)} frames immobiles seulement")
    sys.exit(1)
# Vent : zone d'herbe bas-gauche, diffs entre frames espacées de 0,5 s.
diffs = []
for i in range(0, 30, 6):
    a = Image.open(paths[i]).convert("L").crop((0, 400, 400, 648))
    b = Image.open(paths[i + 6]).convert("L").crop((0, 400, 400, 648))
    diffs.append(ImageStat.Stat(ImageChops.difference(a, b)).mean[0])
print("vent (diffs herbe, pas de parallaxe) :",
      ", ".join(f"{d:.2f}" for d in diffs))
# Stabilité du reste de l'image (ciel + lointain, hors herbe) : doit
# être quasi nulle hors flash d'orage.
lumas = []
for p in paths:
    img = Image.open(p).convert("L").crop((300, 0, 900, 120))
    lumas.append(ImageStat.Stat(img).mean[0])
base = sorted(lumas)[len(lumas) // 2]
peaks = [i for i, l in enumerate(lumas) if l > base + 6]
print(f"ciel : médiane {base:.1f}, min {min(lumas):.1f}, "
      f"max {max(lumas):.1f}, frames en pic (+6) : {peaks}")
