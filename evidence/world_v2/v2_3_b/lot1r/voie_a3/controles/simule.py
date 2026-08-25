#!/usr/bin/env python3
"""SIMULER UN GESTE DE COMPOSITION SUR LE MASQUE, sans rendre le moteur.

PIÈGE MESURÉ ET CONTOURNÉ : le manifeste porte le CHEMIN de l'image, et
`charger()` le résout depuis le cwd. Peindre une COPIE ne change donc rien —
le détecteur rouvre l'original et rend exactement le même verdict, ce qui
ressemble parfaitement à « le geste ne sert à rien ». On réécrit donc le
manifeste pour ne garder que le NOM du fichier : le chemin relatif n'existe
plus depuis le cwd, la solution de repli `manifeste.parent / nom` s'applique,
et le détecteur lit enfin le masque simulé.

  simule.py <sujet> <angle> x0% x1% y0% y1% [x0% x1% y0% y1% ...]
  simule.py --raz     remet le bac de simulation à l'état capturé
"""
import json, shutil, subprocess, sys
from pathlib import Path
from PIL import Image, ImageDraw

MIX = Path("/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad/d3_mix")
SIM = Path("/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad/d3_sim")

def preparer():
    if SIM.exists():
        shutil.rmtree(SIM)
    shutil.copytree(MIX, SIM)
    for m in SIM.glob("manifest_silhouettes_*.json"):
        meta = json.loads(m.read_text(encoding="utf-8"))
        for v in meta.get("vues", []):
            src = Path(str(v["image"]))
            reel = Path("/home/user/wt1r1-a") / src if not src.is_absolute() else src
            if reel.exists():
                shutil.copy(reel, SIM / src.name)
            v["image"] = src.name
        m.write_text(json.dumps(meta, ensure_ascii=False, indent=1), encoding="utf-8")

if "--raz" in sys.argv:
    preparer(); print("bac remis a l'etat capture"); sys.exit(0)
if not SIM.exists() or not (SIM / "manifest_silhouettes_overlook_summit.json").exists():
    preparer()

sujet, angle = sys.argv[1], sys.argv[2]
coords = [float(v) for v in sys.argv[3:]]
nom = "silhouette_%s_%s.png" % (sujet, angle)
img = Image.open(SIM / nom).convert("L")
d = ImageDraw.Draw(img)
fond = img.getpixel((2, 2))
for k in range(0, len(coords), 4):
    x0, x1, y0, y1 = coords[k:k+4]
    d.rectangle([x0/100*img.width, y0/100*img.height,
                 x1/100*img.width, y1/100*img.height], fill=fond)
img.save(SIM / nom)
r = subprocess.run([sys.executable, "tools/lot1_repetition.py", "--manifestes",
                    str(SIM)], capture_output=True, text=True, cwd="/home/user/wt1r1-a")
for ligne in r.stdout.splitlines():
    if "VERDICT" in ligne:
        print(ligne)
print("RC=%d" % r.returncode)
