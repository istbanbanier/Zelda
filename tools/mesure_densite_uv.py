#!/usr/bin/env python3
"""DENSITÉ UV RÉELLE d'un GLB, en tuiles UV par mètre, mesurée PAR AIRE.

POURQUOI CE FICHIER EXISTE, ET QUELLE ERREUR IL REMPLACE.
Le premier relevé d'échelle UV de la ferme (2026-08-19) divisait l'ÉTENDUE UV
d'une primitive par la plus grande dimension de sa BOÎTE ENGLOBANTE. Sur une
poutre de 6 m de long et 0,14 m de section, la composante V traverse la
section — 0,09 UV — et se trouvait divisée par 6 m : 0,015 UV/m, un chiffre
qui ne décrit rien. Le lead l'a relevé : « dix fois plus grossier que le kit ».
Il avait raison de douter du CHIFFRE ; l'erreur était dans l'instrument.

La grandeur juste est invariante par forme : pour chaque triangle, l'aire dans
l'espace UV et l'aire dans le monde. La densité vaut alors

    densite = sqrt( somme(aires_uv) / somme(aires_monde) )        [tuiles / m]

et se compare directement au kit. Référence mesurée sur
`Wall_UnevenBrick_Straight`, matériau `MI_UnevenBrick` : 1 tuile couvre 2,00 m
en U et 2,11 m en V, soit une densité de 0,487 tuile/m.

Usage : python3 tools/mesure_densite_uv.py <fichier.glb|.gltf> [autre...]
"""
import json
import math
import os
import struct
import sys


def _lire(d, bin0, acc, bv, idx, n, buf_ext):
    a = acc[idx]
    v = bv[a["bufferView"]]
    ct = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I",
          5126: "f"}[a["componentType"]]
    taille = {"b": 1, "B": 1, "h": 2, "H": 2, "I": 4, "f": 4}[ct]
    pas = v.get("byteStride") or taille * n
    source = d if buf_ext is None else buf_ext
    base = (bin0 if buf_ext is None else 0) + v.get("byteOffset", 0) \
        + a.get("byteOffset", 0)
    return [struct.unpack_from("<%d%s" % (n, ct), source, base + k * pas)
            for k in range(a["count"])]


def _aire2(a, b, c):
    return abs((b[0] - a[0]) * (c[1] - a[1])
               - (c[0] - a[0]) * (b[1] - a[1])) * 0.5


def _aire3(a, b, c):
    u = [b[i] - a[i] for i in range(3)]
    v = [c[i] - a[i] for i in range(3)]
    n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2],
         u[0] * v[1] - u[1] * v[0]]
    return math.sqrt(sum(x * x for x in n)) * 0.5


def inspecte(chemin):
    buf_ext = None
    if chemin.endswith(".glb"):
        d = open(chemin, "rb").read()
        ln = struct.unpack("<I", d[12:16])[0]
        j = json.loads(d[20:20 + ln])
        bin0 = 20 + ln + 8
    else:
        d = b""
        j = json.load(open(chemin))
        bin0 = 0
        buf_ext = open(os.path.join(os.path.dirname(chemin),
                                    j["buffers"][0]["uri"]), "rb").read()
    acc, bv = j["accessors"], j["bufferViews"]
    print("=== %s ===" % chemin)
    print("%-28s %-22s %10s %10s %9s" % ("piece", "materiau", "aire m2",
                                         "aire UV", "tuiles/m"))
    for m in j["meshes"]:
        for pr in m["primitives"]:
            mat = j["materials"][pr["material"]]["name"] \
                if "material" in pr else "(aucun)"
            if "TEXCOORD_0" not in pr["attributes"]:
                print("%-28s %-22s %10s %10s %9s"
                      % (m["name"], mat, "-", "-", "PAS D'UV0"))
                continue
            po = _lire(d, bin0, acc, bv, pr["attributes"]["POSITION"], 3,
                       buf_ext)
            uv = _lire(d, bin0, acc, bv, pr["attributes"]["TEXCOORD_0"], 2,
                       buf_ext)
            ix = [t[0] for t in _lire(d, bin0, acc, bv, pr["indices"], 1,
                                      buf_ext)]
            am = auv = 0.0
            for k in range(0, len(ix), 3):
                a, b, c = ix[k], ix[k + 1], ix[k + 2]
                am += _aire3(po[a], po[b], po[c])
                auv += _aire2(uv[a], uv[b], uv[c])
            dens = math.sqrt(auv / am) if am > 1e-9 else 0.0
            print("%-28s %-22s %10.3f %10.3f %9.3f"
                  % (m["name"], mat,
                     am, auv, dens))
    return 0


if __name__ == "__main__":
    for c in sys.argv[1:]:
        inspecte(c)
