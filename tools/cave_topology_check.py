#!/usr/bin/env python3
"""Le maillage de la grotte est-il FERME, ou ouvert par le dessous ?

POURQUOI CE FICHIER EXISTE. J'ai ecrit dans `docs/CODEX_HANDOFF.md` §30.1, et
dans `evidence/.../r2a352_toit_mince/LISEZMOI.md`, que mes deux inondations 3D
s'echappaient « par le DESSOUS OUVERT du modele, qui est ouvert par conception —
un rocher plante dans le terrain ». L'agent C mesure le contraire : 0 bord
libre sur les trois geometries.

Si l'agent a raison, ma phrase est fausse dans un document versionne, et la
conclusion qui en decoulait — « joignabilite INDETERMINEE » — reposait sur une
mauvaise cause. Je ne reprends donc pas sa mesure : je la refais.

LE PIEGE A EVITER, ET IL EST GROS
=================================
Un GLB range la geometrie par MATERIAU : six primitives ici. Les sommets sont
DUPLIQUES a chaque couture de materiau. Compter les aretes primitive par
primitive rendrait des milliers de « bords libres » qui n'en sont pas.

Il faut donc SOUDER PAR POSITION avant de compter. C'est exactement la
precaution que l'agent B a nommee de son cote pour son sabotage — deux agents
ont trouve la meme contrainte independamment, ce qui est le meilleur signe
qu'elle est reelle.

Sortie : par noeud, aretes a 1 face (bord libre), a >2 faces (non-manifold),
nombre de composantes connexes, et caracteristique d'Euler V-E+F.
"""

import json
import struct
import sys
from collections import defaultdict


def lire_glb(chemin):
    with open(chemin, "rb") as f:
        data = f.read()
    magic, version, _ = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67, "pas un GLB"
    off = 12
    js = None
    bindata = None
    while off < len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        corps = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:
            js = json.loads(corps.decode("utf-8"))
        elif ctype == 0x004E4942:
            bindata = corps
        off += 8 + clen + ((4 - clen % 4) % 4 if clen % 4 else 0)
    return js, bindata


TAILLE = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
FMT = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I", 5126: "f"}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def accesseur(js, bin_, idx):
    acc = js["accessors"][idx]
    n = acc["count"]
    nc = NCOMP[acc["type"]]
    ct = acc["componentType"]
    vue = js["bufferViews"][acc["bufferView"]]
    base = vue.get("byteOffset", 0) + acc.get("byteOffset", 0)
    pas = vue.get("byteStride") or TAILLE[ct] * nc
    out = []
    for i in range(n):
        o = base + i * pas
        out.append(struct.unpack_from("<" + FMT[ct] * nc, bin_, o))
    return out


def analyser(chemin, etiquette):
    js, bin_ = lire_glb(chemin)
    print(f"\n=== {etiquette} ===")
    print(f"    {chemin}")

    for noeud in js.get("nodes", []):
        if "mesh" not in noeud:
            continue
        nom = noeud.get("name", "?")
        mesh = js["meshes"][noeud["mesh"]]

        ## SOUDURE PAR POSITION — sans elle, chaque couture de materiau
        ## compterait comme un bord libre.
        cle_de = {}
        faces = []
        for prim in mesh["primitives"]:
            pos = accesseur(js, bin_, prim["attributes"]["POSITION"])
            idx = [i[0] for i in accesseur(js, bin_, prim["indices"])]
            local = []
            for p in pos:
                k = (round(p[0], 6), round(p[1], 6), round(p[2], 6))
                if k not in cle_de:
                    cle_de[k] = len(cle_de)
                local.append(cle_de[k])
            for t in range(0, len(idx), 3):
                faces.append((local[idx[t]], local[idx[t + 1]], local[idx[t + 2]]))

        ## MEME fonction que le banc — sinon le banc eprouverait un chemin de
        ## code que la lecture GLB n'emprunte pas, et son vert ne dirait rien
        ## de ce qui est mesure ici. Defaut commis puis corrige le 2026-08-16.
        V, E, F, libres, nonman, khi = _topologie(faces)

        ## Si des sommets soudes n'apparaissent dans AUCUNE face, les deux
        ## comptes divergent. On le DIT au lieu d'en choisir un en silence.
        isoles = len(cle_de) - V
        if isoles:
            print(f"    [ATTENTION] {isoles} sommet(s) soude(s) sans face")

        aretes = set()
        for a, b, c in faces:
            for u, v in ((a, b), (b, c), (c, a)):
                aretes.add((min(u, v), max(u, v)))

        ## composantes connexes, union-find sur les sommets vus dans les faces
        parent = list(range(len(cle_de)))

        def trouver(x):
            while parent[x] != x:
                parent[x] = parent[parent[x]]
                x = parent[x]
            return x

        for (u, v) in aretes:
            ru, rv = trouver(u), trouver(v)
            if ru != rv:
                parent[ru] = rv
        comp = len({trouver(s) for f in faces for s in f})

        ## genre valable seulement si ferme, orientable, sans non-manifold
        genre = (2 * comp - khi) / 2 if libres == 0 and nonman == 0 else None
        print(f"  noeud {nom}")
        print(f"    V={V}  E={E}  F={F}   composantes={comp}")
        print(f"    aretes a 1 face  (BORD LIBRE)   : {libres}")
        print(f"    aretes a >2 faces (NON-MANIFOLD): {nonman}")
        print(f"    khi = V-E+F = {khi}" + (f"   ->  genre {genre:g}" if genre is not None else "   (genre non defini)"))


def _topologie(faces):
    """Coeur de mesure, partage par le banc et par la lecture GLB.

    Ecrit UNE fois, pas une fois par appelant : la lecon de parite consignee
    dans `tools/CLAUDE.md` est que redériver une lecture par branche, c'est se
    tromper dans une branche sur deux.
    """
    sommets = {s for f in faces for s in f}
    V = len(sommets)
    F = len(faces)
    aretes = defaultdict(int)
    for a, b, c in faces:
        for u, v in ((a, b), (b, c), (c, a)):
            aretes[(min(u, v), max(u, v))] += 1
    E = len(aretes)
    libres = sum(1 for n in aretes.values() if n == 1)
    nonman = sum(1 for n in aretes.values() if n > 2)
    return V, E, F, libres, nonman, V - E + F


def banc():
    """Le banc a reponse CONNUE — sans lui, cet outil ne peut pas echouer.

    Trois formes dont la topologie est un fait mathematique, pas une mesure :
    un tetraedre ferme (genre 0), le meme ampute d'une face (3 bords libres),
    et un tore (genre 1). Si l'outil ne les distingue pas, il ne distingue
    rien, et son « 0 bord libre » sur la grotte ne vaut rien.
    """
    ok = 0
    ko = 0

    def verifier(nom, faces, att_libres, att_khi):
        nonlocal ok, ko
        V, E, F, libres, nonman, khi = _topologie(faces)
        bon = (libres == att_libres) and (khi == att_khi)
        print("  %-28s V=%-5d E=%-5d F=%-5d libres=%-3d khi=%-3d  %s"
              % (nom, V, E, F, libres, khi, "OK" if bon else
                 "ECHEC (attendu libres=%d khi=%d)" % (att_libres, att_khi)))
        if bon:
            ok += 1
        else:
            ko += 1

    tetra = [(0, 1, 2), (0, 2, 3), (0, 3, 1), (1, 3, 2)]
    verifier("tetraedre ferme", tetra, 0, 2)
    verifier("tetraedre ampute d'1 face", tetra[:3], 3, 1)

    ## tore 8x8 : grille periodique dans les deux directions
    n = 8
    idx = lambda i, j: (i % n) * n + (j % n)
    tore = []
    for i in range(n):
        for j in range(n):
            a, b = idx(i, j), idx(i + 1, j)
            c, d = idx(i + 1, j + 1), idx(i, j + 1)
            tore += [(a, b, c), (a, c, d)]
    verifier("tore 8x8", tore, 0, 0)

    print("  banc : %d vert(s), %d rouge(s)" % (ok, ko))
    return 0 if ko == 0 else 1


if __name__ == "__main__":
    if "--banc" in sys.argv:
        print("=== BANC A REPONSE CONNUE ===")
        sys.exit(banc())

    for chemin, et in [
        ("/home/user/zelda-r2a353/socle/assets/environment/caves/SM_WaterfallCave.glb", "candidat cc3596c5"),
        ("/home/user/zelda-r2a353/socle/assets/environment/caves/prototypes/SM_WaterfallCave_BASE352.glb", "BASE352 8bc8b9f9"),
        ("/home/user/zelda-r2a353/reference/SM_WaterfallCave_R2a34.glb", "R2a-3.4 livree 8bf1a1b3"),
    ]:
        analyser(chemin, et)
