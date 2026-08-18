#!/usr/bin/env python3
"""Empreinte sha256 de GEOMETRIE par noeud d'un GLB — l'instrument du gate
« visuel inchange » de R2a-3.5.8.

POURQUOI CE FICHIER EXISTE. Le mecanisme a servi en R2a-3.5.7 (sha_avant.txt /
sha_apres.txt de l'agent A : SM_ identique pendant que COL_ change) mais
c'etait un script de session, perdu avec elle. Le gate de la passe 3.5.8 —
« le collider change, le visuel ne change PAS » — a besoin d'un instrument
NOMME et re-executable, sinon la comparaison avant/apres repose sur des
chiffres cites au lieu de chiffres mesures. Un sha256 de fichier entier ne
suffit pas : le GLB embarque les DEUX noeuds, donc tout correctif de collider
change le hash global sans dire si le visuel a bouge.

CE QUI EST HACHE, EXACTEMENT — et rien d'autre :
  - par noeud portant un mesh, primitives dans l'ORDRE du glTF ;
  - par primitive : b"P" + u32(nombre de sommets) + les POSITION repackes
    en float32 petit-boutiste '<3f' (bit-exacts : unpack->repack de f32 est
    sans perte), puis b"I" + u32(nombre d'indices) + les indices repackes
    canoniquement en u32 '<I' (canonique : le hash ne depend pas de la
    largeur u16/u32 de stockage).
  Les prefixes de longueur empechent toute ambiguite de frontiere entre
  primitives. NI les normales, NI les UV, NI les materiaux, NI les noms
  n'entrent dans le hash : deux exports qui ne different que par la
  triangulation ou les positions different ; deux exports qui ne different
  que par le shading ou les noms rendent le MEME hash. C'est voulu : la
  cible du gate est la geometrie dessinee.

ATTENTION (heritee de la correction du lead, 2026-08-18) : un outil qui
serialise autrement (ordre des primitives, format des flottants) rend
d'autres valeurs. Comparer UNIQUEMENT des valeurs produites par le MEME
outil des deux cotes — mesure-contre-mesure, jamais mesure-contre-cite.

usage : cave_sha256_geom.py <fichier.glb> [<fichier.glb> ...]
"""

import hashlib
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cave_topology_check import lire_glb, accesseur  # noqa: E402


def empreintes(chemin):
    js, bin_ = lire_glb(chemin)
    resultats = []
    for noeud in js.get("nodes", []):
        if "mesh" not in noeud:
            continue
        nom = noeud.get("name", "?")
        mesh = js["meshes"][noeud["mesh"]]
        h = hashlib.sha256()
        n_pos = 0
        n_idx = 0
        for prim in mesh["primitives"]:
            pos = accesseur(js, bin_, prim["attributes"]["POSITION"])
            idx = [i[0] for i in accesseur(js, bin_, prim["indices"])]
            h.update(b"P" + struct.pack("<I", len(pos)))
            for p in pos:
                h.update(struct.pack("<3f", p[0], p[1], p[2]))
            h.update(b"I" + struct.pack("<I", len(idx)))
            for i in idx:
                h.update(struct.pack("<I", i))
            n_pos += len(pos)
            n_idx += len(idx)
        resultats.append((nom, len(mesh["primitives"]), n_pos, n_idx // 3,
                          h.hexdigest()))
    return resultats


def main(argv):
    chemins = [a for a in argv[1:] if not a.startswith("-")]
    if not chemins:
        print(__doc__.strip().splitlines()[0])
        print("usage : cave_sha256_geom.py <fichier.glb> [...]")
        return 2
    rc = 0
    for chemin in chemins:
        if not os.path.exists(chemin):
            print("ABSENT : %s" % chemin)
            rc = 2
            continue
        with open(chemin, "rb") as f:
            entier = hashlib.sha256(f.read()).hexdigest()
        print("=== %s ===" % chemin)
        print("    fichier entier : %s (%d octets)"
              % (entier, os.path.getsize(chemin)))
        for nom, nprim, npos, ntri, hx in empreintes(chemin):
            print("    %-22s prim=%d sommets=%d tris=%d" % (nom, nprim, npos, ntri))
            print("      sha256_geom = %s  (prefixe %s)" % (hx, hx[:16]))
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv))
