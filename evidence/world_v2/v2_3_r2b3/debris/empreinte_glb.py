#!/usr/bin/env python3
"""Empreinte par mesh d'un .glb : triangles + emprise POSITION (min/max).

Sert la PREUVE DE NON-CONTAMINATION de R2B.3 (ISS-060) : après régénération,
tout mesh autre que les deux tas de débris doit rendre EXACTEMENT le même
compte de triangles et la même emprise qu'avant.

L'emprise est lue sur l'accessor POSITION, dans le repère LOCAL du mesh —
c'est la grandeur que l'instrument de boîtitude ne publie pas et dont les
planchers 5 (implantation) et la non-contamination ont besoin.

Usage : python3 empreinte_glb.py <fichier.glb> [--json]
"""
import json
import struct
import sys

sys.path.insert(0, "tools")
from mesure_boititude import lire_glb, lire_accessor  # noqa: E402


def empreintes(chemin):
    gltf, binaire = lire_glb(chemin)
    sortie = []
    for mesh in gltf.get("meshes", []):
        tris = 0
        lo = [float("inf")] * 3
        hi = [float("-inf")] * 3
        for prim in mesh.get("primitives", []):
            att = prim.get("attributes", {})
            if "POSITION" not in att:
                continue
            if "indices" in prim:
                n = gltf["accessors"][prim["indices"]]["count"]
            else:
                n = gltf["accessors"][att["POSITION"]]["count"]
            tris += n // 3
            for p in lire_accessor(gltf, binaire, att["POSITION"]):
                for k in range(3):
                    lo[k] = min(lo[k], p[k])
                    hi[k] = max(hi[k], p[k])
        sortie.append({
            "mesh": mesh.get("name", "?"),
            "triangles": tris,
            "min": [round(v, 6) for v in lo],
            "max": [round(v, 6) for v in hi],
            "emprise": [round(hi[k] - lo[k], 6) for k in range(3)],
        })
    return sortie


def main():
    chemin = sys.argv[1]
    res = empreintes(chemin)
    if "--json" in sys.argv:
        print(json.dumps(res, indent=2))
        return 0
    print("%-24s %6s  %-26s %-26s" % ("mesh", "tris", "emprise X Y Z (m)",
                                      "min X Y Z (m)"))
    for r in res:
        print("%-24s %6d  %7.4f %7.4f %7.4f    %7.4f %7.4f %7.4f" % (
            r["mesh"], r["triangles"], r["emprise"][0], r["emprise"][1],
            r["emprise"][2], r["min"][0], r["min"][1], r["min"][2]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
