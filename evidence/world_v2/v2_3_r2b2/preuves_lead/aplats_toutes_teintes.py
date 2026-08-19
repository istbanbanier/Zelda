#!/usr/bin/env python3
"""Meme predicat de PLATITUDE que tools/mesure_aplats.py, SANS le filtre beige.

Question posee : l'instrument d'aplats ne voit que le beige chaud
(est_beige exige r > v > b et 18 < r-b < 110). Une dalle grise plate lui est
INVISIBLE. Combien de surface plate non-beige y a-t-il reellement ?
"""
import sys
from collections import deque
from PIL import Image

RAYON, SEUIL, MIN_COMPOSANTE = 3, 18, 1500


def est_beige(c):
    r, v, b = c
    return r > 60 and r > v > b and 18 < (r - b) < 110


def famille(c):
    r, v, b = c
    if est_beige(c):
        return "beige"
    if max(c) - min(c) <= 16:
        return "gris/neutre"
    if v > r and v > b:
        return "vert"
    if b >= r and b >= v:
        return "bleu"
    if r > v > b:
        return "chaud hors beige"
    return "autre"


def mesure(chemin):
    im = Image.open(chemin).convert("RGB")
    L, H = im.size
    px = im.load()
    plat = [[False] * H for _ in range(L)]
    for x in range(RAYON, L - RAYON):
        for y in range(RAYON, H - RAYON):
            c = px[x, y]
            uni = True
            for dx, dy in ((RAYON, 0), (-RAYON, 0), (0, RAYON), (0, -RAYON)):
                n = px[x + dx, y + dy]
                if abs(c[0]-n[0]) + abs(c[1]-n[1]) + abs(c[2]-n[2]) > SEUIL:
                    uni = False
                    break
            plat[x][y] = uni
    vu = [[False] * H for _ in range(L)]
    comps = []
    for x in range(RAYON, L - RAYON):
        for y in range(RAYON, H - RAYON):
            if not plat[x][y] or vu[x][y]:
                continue
            q = deque([(x, y)]); vu[x][y] = True
            taille = 0; fams = {}
            while q:
                cx, cy = q.popleft(); taille += 1
                f = famille(px[cx, cy]); fams[f] = fams.get(f, 0) + 1
                for nx, ny in ((cx+1, cy), (cx-1, cy), (cx, cy+1), (cx, cy-1)):
                    if (RAYON <= nx < L-RAYON and RAYON <= ny < H-RAYON
                            and plat[nx][ny] and not vu[nx][ny]):
                        vu[nx][ny] = True; q.append((nx, ny))
            if taille >= MIN_COMPOSANTE:
                dom = max(fams.items(), key=lambda kv: kv[1])[0]
                comps.append((taille, dom))
    comps.sort(reverse=True)
    pix = L * H
    print(f"\n=== {chemin}  ({L}x{H}) ===")
    par_fam = {}
    for t, f in comps:
        par_fam[f] = par_fam.get(f, 0) + t
    print(f"  composantes plates >= {MIN_COMPOSANTE} px : {len(comps)}")
    for f, t in sorted(par_fam.items(), key=lambda kv: -kv[1]):
        marque = "   <-- VU par mesure_aplats.py" if f == "beige" else "   <-- INVISIBLE"
        print(f"    {f:18s} {100.0*t/pix:6.2f} %{marque}")
    print(f"    {'TOTAL':18s} {100.0*sum(t for t,_ in comps)/pix:6.2f} %")
    print("  cinq plus grandes composantes :")
    for t, f in comps[:5]:
        print(f"    {100.0*t/pix:6.2f} %   {f}")


for p in sys.argv[1:]:
    mesure(p)
