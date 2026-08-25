#!/usr/bin/env python3
"""SIMULATION DE COMPOSITION v2 — peindre, TASSER, et exiger une marge.

Deux operations, parce que l'arbitrage en demande deux :
  peindre   : creuser une entaille / abaisser un rebord (on ne peut qu'OTER)
  tasser    : abaisser le sujet dans le MEME cadre. C'est exact ici, et ce
              n'est pas une approximation : `capture_silhouette.gd` cadre sur
              `max(size.y, largeur * H/W)`. La source fait 17,2 m de large pour
              5,9 m de haut, donc c'est la LARGEUR qui commande le cadre et il
              ne bouge pas quand la hauteur baisse. Le sujet se tasse dans un
              cadre inchange, ancre sur sa ligne de sol.
              `hauteur_m` du manifeste suit, car le detecteur s'en sert pour
              choisir sa resolution de sous-echantillonnage.

Verdict : on exige que TOUTE paire impliquant mes deux lieux ET le corpus
accepte passe SOUS le seuil avec une marge donnee. Une paire qui frole n'est
pas une paire qui passe.
"""
import json, shutil, subprocess, sys
from pathlib import Path
from PIL import Image

RACINE = Path("/home/user/wt1r1-a")
MIX = Path("/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad/d3_mix")
SIM = Path("/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad/d3_sim")
MIENS = {"valley.poi.overlook_summit.01", "valley.poi.turquoise_spring.01"}


def preparer():
    if SIM.exists():
        shutil.rmtree(SIM)
    shutil.copytree(MIX, SIM)
    for m in SIM.glob("manifest_silhouettes_*.json"):
        meta = json.loads(m.read_text(encoding="utf-8"))
        for v in meta.get("vues", []):
            src = Path(str(v["image"]))
            reel = src if src.is_absolute() else RACINE / src
            if reel.exists():
                shutil.copy(reel, SIM / src.name)
            v["image"] = src.name
        m.write_text(json.dumps(meta, ensure_ascii=False, indent=1), encoding="utf-8")


def boite_sujet(img):
    seuil = 118
    px = img.load()
    xs, ys = [], []
    for y in range(img.height):
        for x in range(0, img.width, 2):
            if px[x, y] < seuil:
                xs.append(x); ys.append(y)
    return min(xs), min(ys), max(xs), max(ys)


def peindre(nom, rects):
    from PIL import ImageDraw
    img = Image.open(SIM / nom).convert("L")
    d = ImageDraw.Draw(img)
    fond = img.getpixel((2, 2))
    for x0, x1, y0, y1 in rects:
        d.rectangle([x0 / 100 * img.width, y0 / 100 * img.height,
                     x1 / 100 * img.width, y1 / 100 * img.height], fill=fond)
    img.save(SIM / nom)


def tasser(nom, facteur):
    """Tasse le sujet verticalement d'un facteur, ancre sur sa ligne de sol."""
    img = Image.open(SIM / nom).convert("L")
    x0, y0, x1, y1 = boite_sujet(img)
    h = y1 - y0 + 1
    sujet = img.crop((0, y0, img.width, y1 + 1))
    neuve = sujet.resize((img.width, max(1, round(h * facteur))), Image.BOX)
    fond = img.getpixel((2, 2))
    sortie = Image.new("L", img.size, fond)
    sortie.paste(neuve, (0, y1 + 1 - neuve.height))
    sortie.save(SIM / nom)


def hauteur(sujet, valeur):
    m = SIM / ("manifest_silhouettes_%s.json" % sujet)
    meta = json.loads(m.read_text(encoding="utf-8"))
    e = meta["emprise_m"]
    meta["emprise_m"] = [e[0], valeur, e[2]]
    m.write_text(json.dumps(meta, ensure_ascii=False, indent=1), encoding="utf-8")


def verdict(marge_exigee):
    r = subprocess.run([sys.executable, "tools/lot1_repetition.py",
                        "--manifestes", str(SIM), "--out", str(SIM / "v.json")],
                       capture_output=True, text=True, cwd=str(RACINE))
    d = json.loads((SIM / "v.json").read_text(encoding="utf-8"))
    seuils = {float(k): v["S"] for k, v in d["seuils"].items()}
    pire = []
    for cle, paires in d["matrice"].items():
        S = seuils[float(cle)]
        for p in paires:
            a, b = p["a"], p["b"]
            if not ({a, b} & MIENS):
                continue
            pire.append((p["iou"] - S, p["iou"], S, float(cle), a, b))
    pire.sort(reverse=True)
    tete = pire[:4]
    ok = all(-x[0] >= marge_exigee for x in pire)
    for delta, iou, S, dist, a, b in tete:
        print("   %-38s %-38s %3.0f m  IoU %.4f  S %.4f  marge %+.4f"
              % (a.replace("valley.poi.", ""), b.replace("valley.poi.", ""),
                 dist, iou, S, -delta))
    print("   => %s (marge exigee %.3f)" % ("PASSE" if ok else "NE PASSE PAS",
                                            marge_exigee))
    return ok


if __name__ == "__main__":
    preparer()
    print("bac remis a l'etat capture")
