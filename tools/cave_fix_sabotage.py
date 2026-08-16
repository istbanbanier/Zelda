#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""CONTRÔLE NÉGATIF — amincir la coque SANS l'ouvrir, et vérifier que ça rougit.

UN CONTRÔLE QUI N'A JAMAIS ROUGI N'EST PAS UN CONTRÔLE
======================================================

`docs/CONTRAT_COQUE_STRUCTURELLE.md` §3. Après avoir fermé une percée, tout
mon appareil de mesure rend VERT. Un vert obtenu par un instrument qu'on
n'a jamais vu échouer ne vaut rien : il est indistinguable d'un instrument
aveugle. On fabrique donc le défaut, on exige le rouge, on restaure, on
exige le vert.

LE SABOTAGE DOIT LAISSER LE MAILLAGE FERMÉ, ET C'EST LA CONTRAINTE DURE
=======================================================================

`tools/CLAUDE.md` : « Retirer des triangles l'ouvre, la parité y devient
indéfinie, et tout vote rebouche le trou. Déplacer des sommets, jamais
amputer. » On ne touche donc QUE les positions, jamais la connectivité —
et on le prouve au lieu de l'affirmer, en rejouant le contrôle de genre des
deux côtés.

POURQUOI PATCHER LES FLOTTANTS EN PLACE
=======================================

Les positions du GLB sont des `float32` dans le chunk binaire. Les
réécrire en place laisse la longueur du fichier, les vues, les accesseurs
et les indices rigoureusement identiques. La restauration est alors la
copie des octets d'origine, et « byte-identique » n'est plus une intention
mais une propriété : le sha256 se compare, il ne se raconte pas.

Deux conséquences assumées, écrites parce qu'elles se paient :

  * les NORMALES ne sont pas recalculées. Aucun de mes instruments ne les
    lit — ils travaillent sur les positions des triangles — mais un rendu
    du fichier saboté serait faux. Ce fichier n'est pas fait pour être
    rendu, il est fait pour être mesuré, et il est détruit après ;
  * un même sommet est DUPLIQUÉ à chaque couture de matériau. On
    sélectionne donc PAR POSITION et non par indice : toutes les copies
    d'un même point reçoivent le même déplacement, sans quoi la couture
    s'ouvrirait et le maillage avec elle.

Usage :
    python3 tools/cave_fix_sabotage.py <glb_in> <glb_out> \\
        --x 0.55 --y 5.95 --rayon 0.60 --clamp 2.02
"""

import json
import math
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cave_void_connectivity import lire_glb

NOEUD = "SM_WaterfallCave"


def positions_accesseurs(js):
    """Indices des accesseurs POSITION des primitives du nœud visé."""
    sortie = []
    for noeud in js.get("nodes", []):
        if "mesh" not in noeud or noeud.get("name") != NOEUD:
            continue
        for prim in js["meshes"][noeud["mesh"]]["primitives"]:
            sortie.append(prim["attributes"]["POSITION"])
    if not sortie:
        raise SystemExit("BLOQUE: noeud '%s' absent — on n'invente pas un "
                         "maillage" % NOEUD)
    return sortie


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) < 2:
        print("usage: cave_fix_sabotage.py <glb_in> <glb_out> "
              "[--x .. --y .. --rayon .. --clamp ..]")
        return 3
    entree, sortie = args[0], args[1]
    opt = dict(x=0.55, y=5.95, rayon=0.60, clamp=2.02)
    for k, a in enumerate(sys.argv[1:]):
        if a.startswith("--") and a[2:] in opt:
            opt[a[2:]] = float(sys.argv[k + 2])

    with open(entree, "rb") as f:
        brut = bytearray(f.read())
    js, _ = lire_glb(entree)

    # Offset du chunk BIN dans le fichier — on patche `brut`, pas une copie.
    off, bin_off = 12, None
    while off < len(brut):
        clen, ctype = struct.unpack_from("<II", brut, off)
        if ctype == 0x004E4942:
            bin_off = off + 8
            break
        off += 8 + clen + ((4 - clen % 4) % 4 if clen % 4 else 0)
    if bin_off is None:
        print("BLOQUE: pas de chunk binaire")
        return 3

    cx, cy, r = opt["x"], opt["y"], opt["rayon"]
    bouges, vus = 0, 0
    zmin_vu, zmax_vu = None, None
    for idx in positions_accesseurs(js):
        acc = js["accessors"][idx]
        vue = js["bufferViews"][acc["bufferView"]]
        base = bin_off + vue.get("byteOffset", 0) + acc.get("byteOffset", 0)
        pas = vue.get("byteStride") or 12
        for i in range(acc["count"]):
            o = base + i * pas
            gx, gy, gz = struct.unpack_from("<fff", brut, o)
            # GLB -> MODELE : ax = gx, ay = -gz, az = gy.
            ax, ay, az = gx, -gz, gy
            vus += 1
            if math.hypot(ax - cx, ay - cy) > r:
                continue
            if az <= opt["clamp"]:
                continue
            # ÉCRÊTAGE, ET NON TRANSLATION. Abaisser en bloc de `d` mètres
            # ferait passer des sommets hauts SOUS des sommets bas restés en
            # place : la surface se replierait, et le « rouge » obtenu
            # viendrait de l'auto-traversée plutôt que de l'amincissement.
            # L'écrêtage est MONOTONE — il ne peut pas inverser deux
            # sommets — et il ne touche que ce qui dépasse le plafond visé.
            struct.pack_into("<fff", brut, o, ax, opt["clamp"], -ay)
            bouges += 1
            zmin_vu = az if zmin_vu is None else min(zmin_vu, az)
            zmax_vu = az if zmax_vu is None else max(zmax_vu, az)

    with open(sortie, "wb") as f:
        f.write(brut)
    print("[sabotage] cible (%.2f ; %.2f) rayon %.2f m, ECRETAGE a z = %.2f m"
          % (cx, cy, r, opt["clamp"]))
    print("[sabotage] %d sommet(s) DEPLACE(S) sur %d lus ; z d'origine des "
          "sommets touches : %s"
          % (bouges, vus,
             "aucun" if zmin_vu is None else "[%.3f ; %.3f]" % (zmin_vu,
                                                                zmax_vu)))
    print("[sabotage] taille %d -> %d octets (identique = seules les "
          "positions ont change)"
          % (os.path.getsize(entree), os.path.getsize(sortie)))
    if bouges == 0:
        # UN SABOTAGE QUI NE SABOTE RIEN NE REND PAS 0. C'est exactement le
        # « vert obtenu en ne faisant rien » déjà consigné dans
        # `tools/CLAUDE.md` pour `export_architecture.sh`.
        print("[sabotage] BLOQUE: aucun sommet deplace — le rouge qui "
              "suivrait ne prouverait rien")
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main())
