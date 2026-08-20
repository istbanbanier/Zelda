#!/usr/bin/env python3
"""INDICATEUR DESCRIPTIF, NON LIANT : part d'aire dont la normale est PLATE.

Un pave pose a plat presente de grandes faces horizontales ; un fragment
fracture bascule sur trois axes n'en presente presque pas. Ce nombre decrit
donc, en geometrie, ce que le lead juge a l'oeil — et il ne le remplace pas.

Il n'est PAS un plancher : il est calcule apres coup, sur le meme code, pour
les trois etats (avant / apres / sabotage). Un critere calibre sur son propre
sujet ne serait pas un critere.
"""
import math
import sys
sys.path.insert(0, "tools")
from mesure_boititude import lire_glb, lire_accessor

SEUIL_DEG = 12.0
CIBLES = ("SM_Farm_Debris_A", "SM_Farm_Debris_B")


def mesure(chemin):
    gltf, binaire = lire_glb(chemin)
    out = []
    for mesh in gltf.get("meshes", []):
        if mesh.get("name") not in CIBLES:
            continue
        plate = 0.0
        total = 0.0
        dirs = []
        for prim in mesh.get("primitives", []):
            att = prim["attributes"]
            pos = lire_accessor(gltf, binaire, att["POSITION"])
            idx = [i[0] for i in lire_accessor(gltf, binaire, prim["indices"])]
            for t in range(0, len(idx) - 2, 3):
                a, b, c = pos[idx[t]], pos[idx[t + 1]], pos[idx[t + 2]]
                u = [b[i] - a[i] for i in range(3)]
                v = [c[i] - a[i] for i in range(3)]
                n = (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2],
                     u[0] * v[1] - u[1] * v[0])
                norme = math.sqrt(sum(q * q for q in n))
                if norme <= 0.0:
                    continue
                aire = 0.5 * norme
                total += aire
                # GLB : Y est la verticale.
                if abs(n[1] / norme) >= math.cos(math.radians(SEUIL_DEG)):
                    plate += aire
                d = tuple(round(q / norme, 2) for q in n)
                if d not in dirs:
                    dirs.append(d)
        out.append((mesh["name"], 100.0 * plate / total if total else 0.0,
                    total, len(dirs)))
    return out


for chemin in sys.argv[1:]:
    print("--- %s" % chemin)
    for nom, pct, aire, dirs in mesure(chemin):
        print("    %-20s aire %.4f m²  part PLATE (±%.0f° de l'horizontale) "
              "%5.1f %%   %d directions de normale distinctes"
              % (nom, aire, SEUIL_DEG, pct, dirs))
