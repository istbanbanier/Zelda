#!/usr/bin/env python3
"""Où tombe un point du lieu dans la CAMÉRA JOUEUR GELÉE — géométrie pure.

Cet outil ne prétend rien sur le rendu : il projette un point local du lieu
dans le repère écran de la caméra gelée `turquoise_spring_joueur`, avec la
convention de `Camera3D` (fov = angle VERTICAL, `KEEP_HEIGHT`). Il sert à
décider AVANT de bâtir quelle masse occupera quelle part du cadre — et à ne
pas découvrir après coup qu'un geste de composition sort du champ.

Il ne remplace pas la capture : une image reste la seule preuve de ce que le
moteur dessine.
"""
import json
import math
import sys
from pathlib import Path

SITE = (-136.0, 12.0, 40.0)
CAMS = {
    "joueur": ((-126.5, 13.7, 40.0), (-136.0, 13.2, 40.0), 65.0),
    "identite": ((-117.2, 20.0, 46.8), (-136.0, 14.0, 40.0), 55.0),
}
W, H = 1280, 720

_GRILLE = None


def sol(lx, lz):
    """Hauteur locale du sol gelé, interpolée dans la grille mesurée."""
    global _GRILLE
    if _GRILLE is None:
        p = Path(__file__).resolve().parent.parent / "sol_grille.json"
        d = json.loads(p.read_text())
        _GRILLE = {round(l["x"]): l["y"] for l in d["grille"]}
    x0 = math.floor(max(-18.0, min(11.0, lx)))
    z0 = math.floor(max(-12.0, min(11.0, lz)))
    fx, fz = lx - x0, lz - z0
    def v(x, z):
        return _GRILLE[x][int(z) + 12]
    a = v(x0, z0) * (1 - fz) + v(x0, z0 + 1) * fz
    b = v(x0 + 1, z0) * (1 - fz) + v(x0 + 1, z0 + 1) * fz
    return a * (1 - fx) + b * fx


def projeter(cam, local):
    """(px, py, distance) — px/py hors [0,W]×[0,H] = hors cadre."""
    (cx, cy, cz), (lx, ly, lz), fov = CAMS[cam]
    C = (cx - SITE[0], cy - SITE[1], cz - SITE[2])
    L = (lx - SITE[0], ly - SITE[1], lz - SITE[2])
    d = [L[i] - C[i] for i in range(3)]
    n = math.dist((0, 0, 0), d)
    f = [c / n for c in d]
    # Base de `Camera3D.look_at` avec UP = +Y, à la lettre :
    #   z_axe = -avant ; x_axe = UP × z_axe ; y_axe = z_axe × x_axe.
    z_ax = [-c for c in f]
    x_ax = [z_ax[2], 0.0, -z_ax[0]]
    m = math.dist((0, 0, 0), x_ax)
    x_ax = [c / m for c in x_ax]
    y_ax = [z_ax[1] * x_ax[2] - z_ax[2] * x_ax[1],
            z_ax[2] * x_ax[0] - z_ax[0] * x_ax[2],
            z_ax[0] * x_ax[1] - z_ax[1] * x_ax[0]]
    v = [local[i] - C[i] for i in range(3)]
    prof = sum(v[i] * f[i] for i in range(3))
    if prof <= 0.01:
        return None
    xc = sum(v[i] * x_ax[i] for i in range(3))
    yc = sum(v[i] * y_ax[i] for i in range(3))
    tv = math.tan(math.radians(fov) / 2.0)
    th = tv * W / H
    return (W * 0.5 * (1 + (xc / prof) / th),
            H * 0.5 * (1 - (yc / prof) / tv), prof)


if __name__ == "__main__":
    cam = sys.argv[1] if len(sys.argv) > 1 else "joueur"
    print("cam=%s  (px,py) origine haut-gauche, image %dx%d" % (cam, W, H))
    for ligne in sys.stdin:
        ligne = ligne.strip()
        if not ligne or ligne.startswith("#"):
            continue
        champs = ligne.split()
        nom = champs[0]
        x, z = float(champs[1]), float(champs[2])
        h = float(champs[3]) if len(champs) > 3 else 0.0
        y = sol(x, z) + h
        r = projeter(cam, (x, y, z))
        if r is None:
            print("%-22s DERRIÈRE LA CAMÉRA" % nom)
            continue
        print("%-22s local(%6.2f %6.2f %6.2f)  ecran(%7.1f %7.1f)  d=%5.1f m"
              % (nom, x, y, z, r[0], r[1], r[2]))
