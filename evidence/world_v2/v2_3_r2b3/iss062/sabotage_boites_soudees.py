#!/usr/bin/env python3
"""SABOTAGE ISS-062 — remplace les deux tas de la ferme par des BOÎTES DROITES
SOUDÉES PAR LES COINS, c'est-à-dire le contre-exemple exact qui traverse le
portail de boîtitude sans être vu.

CE QU'IL FABRIQUE, ET POURQUOI CETTE FORME PRÉCISE
--------------------------------------------------
Par tas : NEUF composantes, chacune faite de DEUX pavés droits axés qui ne se
touchent QUE par un sommet — le coin (o+s, o+s, o+s) est partagé à l'octet
près, donc soudé, donc les deux pavés ne forment qu'UNE composante connexe.

Conséquence recherchée, et c'est tout le ticket :
  * `mesure_boititude.py` juge PAR COMPOSANTE. Une paire, c'est 24 triangles et
    15 sommets soudés : ni `hexa` (12 tris / 8 sommets), ni `pave6` (6 plans /
    8 coins — la paire en porte 12 et 15). Verdict : 0,00 % de liant.
  * `mesure_rectangularite.py` juge des PLAQUES PLANES connexes PAR ARÊTE. Les
    deux pavés ne partagent aucune arête : chaque face reste un carré isolé.
    Verdict : 100 % rectangulaire, 100 % orthogonal.

LES NEUF PLANCHERS SONT TENUS À DESSEIN — c'est un contrôle à variable unique.
Le sabotage ne doit faire tomber QUE la rectangularité :
  * 9 composantes par tas          (plancher 1 : >= 9)
  * 216 triangles par tas          (plancher 6 : <= 600)
  * aire totale largement au-dessus du plancher, médiane de composante idem
  * aucune arête sous 2 mm         (plancher 4 : aire fine = 0 %)
  * emprise reconstruite sur les bornes EXACTES du tas d'origine
  * quatre primitives conservées, mêmes matériaux, UV0 émises
  * budget de la ferme : 2 228 -> 2 264 triangles, dans [1900, 4500]

INTERDITS RESPECTÉS : aucun bruit sous-pixel, aucun débris supprimé ni dilué,
aucun seuil déplacé. La géométrie d'origine n'est pas altérée : elle est
REMPLACÉE, et le fichier est restauré à l'octet près après la démonstration.

Usage :
    python3 sabotage_boites_soudees.py <entree.glb> <sortie.glb>
"""

import json
import struct
import sys

GLB_MAGIC = 0x46546C67
CHUNK_JSON = 0x4E4F534A
CHUNK_BIN = 0x004E4942

# Bornes POSITION relevées sur le GLB d'origine (sha256 ead79105…), repère
# local du mesh — les nœuds SM_Farm_Debris_A/B ne portent aucune transformation.
TAS = {
    "SM_Farm_Debris_A": ((-0.7934, 0.0, -0.5258), (0.7110, 0.6841, 0.6936)),
    "SM_Farm_Debris_B": ((-0.6003, 0.0, -0.4456), (0.5800, 0.6883, 0.5087)),
}

# Neuf paires. Les fractions couvrent 0,0 ET 1,0 sur X comme sur Z : l'emprise
# reconstruite touche donc exactement les deux bornes d'origine.
FRAC_X = [0.00, 1.00, 0.50, 0.20, 0.80, 0.35, 0.65, 0.10, 0.90]
FRAC_Z = [0.00, 0.55, 1.00, 0.30, 0.70, 0.15, 0.85, 0.45, 0.60]
# La paire 0 fait toute la hauteur : le Y du tas est conservé au millième.
HAUTEUR = [1.00, 0.86, 0.74, 0.92, 0.68, 0.80, 0.62, 0.96, 0.56]

# Répartition des paires sur les quatre primitives d'origine, pour conserver
# quatre surfaces et les quatre matériaux du mesh.
LOTS = [[0, 1, 2], [3, 4], [5, 6], [7, 8]]

_FACES = [   # (axe, signe) -> 4 coins en ordre direct, et les deux axes d'UV
    (0, -1), (0, +1), (1, -1), (1, +1), (2, -1), (2, +1),
]


def _pave(ox, oy, oz, s):
    """24 sommets (4 par face, normales plates) et 36 indices."""
    pos, nor, uv, idx = [], [], [], []
    for axe, signe in _FACES:
        u_ax = (axe + 1) % 3
        v_ax = (axe + 2) % 3
        n = [0.0, 0.0, 0.0]
        n[axe] = float(signe)
        coins = []
        for (a, b) in ((0, 0), (1, 0), (1, 1), (0, 1)):
            p = [0.0, 0.0, 0.0]
            p[axe] = 1.0 if signe > 0 else 0.0
            p[u_ax] = float(a)
            p[v_ax] = float(b)
            coins.append(p)
        if signe < 0:
            coins.reverse()
        base = len(pos)
        for k, p in enumerate(coins):
            pos.append((ox + p[0] * s, oy + p[1] * s, oz + p[2] * s))
            nor.append(tuple(n))
            uv.append((float(k in (1, 2)), float(k in (2, 3))))
        idx += [base, base + 1, base + 2, base, base + 2, base + 3]
    return pos, nor, uv, idx


def geometrie_tas(lo, hi):
    """Neuf paires de pavés soudés par un coin, dans l'emprise (lo, hi)."""
    lots = [([], [], [], []) for _ in LOTS]
    ou = {}
    for i, membres in enumerate(LOTS):
        for k in membres:
            ou[k] = i
    hauteur_tas = hi[1] - lo[1]
    for k in range(9):
        # côté du pavé : la PAIRE fait 2*s de haut, donc s = h/2
        s = 0.5 * hauteur_tas * HAUTEUR[k]
        ox = lo[0] + (hi[0] - lo[0] - 2.0 * s) * FRAC_X[k]
        oz = lo[2] + (hi[2] - lo[2] - 2.0 * s) * FRAC_Z[k]
        oy = lo[1]
        # LE COIN PARTAGÉ : la seconde origine EST le coin maximal du premier
        # pavé, calculé par la même expression, donc identique bit à bit.
        second = (ox + s, oy + s, oz + s)
        pos, nor, uv, idx = lots[ou[k]]
        for origine in ((ox, oy, oz), second):
            p, n, t, i = _pave(origine[0], origine[1], origine[2], s)
            idx += [j + len(pos) for j in i]
            pos += p
            nor += n
            uv += t
    return lots


def lire(chemin):
    blob = open(chemin, "rb").read()
    gltf, binaire, pos = None, b"", 12
    while pos + 8 <= len(blob):
        ln, genre = struct.unpack_from("<II", blob, pos)
        corps = blob[pos + 8:pos + 8 + ln]
        if genre == CHUNK_JSON:
            gltf = json.loads(corps.decode("utf-8"))
        elif genre == CHUNK_BIN:
            binaire = corps
        pos += 8 + ln + ((4 - ln % 4) % 4 if ln % 4 else 0)
    return gltf, bytearray(binaire)


def ajouter(gltf, binaire, donnees, compte, genre_comp, genre, mini, maxi,
            cible=None):
    while len(binaire) % 4:
        binaire.append(0)
    offset = len(binaire)
    binaire += donnees
    vue = {"buffer": 0, "byteOffset": offset, "byteLength": len(donnees)}
    if cible is not None:
        vue["target"] = cible
    gltf["bufferViews"].append(vue)
    acc = {"bufferView": len(gltf["bufferViews"]) - 1, "componentType":
           genre_comp, "count": compte, "type": genre}
    if mini is not None:
        acc["min"] = mini
        acc["max"] = maxi
    gltf["accessors"].append(acc)
    return len(gltf["accessors"]) - 1


def main():
    if len(sys.argv) != 3:
        sys.stderr.write(__doc__)
        return 2
    gltf, binaire = lire(sys.argv[1])
    noms = {m.get("name"): m for m in gltf["meshes"]}
    for nom, (lo, hi) in TAS.items():
        mesh = noms.get(nom)
        if mesh is None:
            sys.stderr.write("BLOQUÉ : mesh %s absent\n" % nom)
            return 2
        materiaux = [p.get("material") for p in mesh["primitives"]]
        if len(materiaux) != len(LOTS):
            sys.stderr.write("BLOQUÉ : %s a %d primitives, %d attendues\n"
                             % (nom, len(materiaux), len(LOTS)))
            return 2
        nouvelles = []
        for i, (pos, nor, uv, idx) in enumerate(geometrie_tas(lo, hi)):
            bp = b"".join(struct.pack("<3f", *p) for p in pos)
            bn = b"".join(struct.pack("<3f", *p) for p in nor)
            bt = b"".join(struct.pack("<2f", *p) for p in uv)
            bi = b"".join(struct.pack("<H", j) for j in idx)
            mn = [min(p[k] for p in pos) for k in range(3)]
            mx = [max(p[k] for p in pos) for k in range(3)]
            a_pos = ajouter(gltf, binaire, bp, len(pos), 5126, "VEC3",
                            mn, mx, 34962)
            a_nor = ajouter(gltf, binaire, bn, len(nor), 5126, "VEC3",
                            None, None, 34962)
            a_uv = ajouter(gltf, binaire, bt, len(uv), 5126, "VEC2",
                           None, None, 34962)
            a_idx = ajouter(gltf, binaire, bi, len(idx), 5123, "SCALAR",
                            None, None, 34963)
            prim = {"attributes": {"POSITION": a_pos, "NORMAL": a_nor,
                                   "TEXCOORD_0": a_uv},
                    "indices": a_idx, "mode": 4}
            if materiaux[i] is not None:
                prim["material"] = materiaux[i]
            nouvelles.append(prim)
        mesh["primitives"] = nouvelles

    gltf["buffers"][0]["byteLength"] = len(binaire)
    js = json.dumps(gltf, separators=(",", ":")).encode("utf-8")
    js += b" " * ((4 - len(js) % 4) % 4)
    while len(binaire) % 4:
        binaire.append(0)
    total = 12 + 8 + len(js) + 8 + len(binaire)
    with open(sys.argv[2], "wb") as h:
        h.write(struct.pack("<III", GLB_MAGIC, 2, total))
        h.write(struct.pack("<II", len(js), CHUNK_JSON))
        h.write(js)
        h.write(struct.pack("<II", len(binaire), CHUNK_BIN))
        h.write(bytes(binaire))
    sys.stderr.write("écrit : %s (%d octets)\n" % (sys.argv[2], total))
    return 0


if __name__ == "__main__":
    sys.exit(main())
