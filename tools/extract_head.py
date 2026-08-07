#!/usr/bin/env python3
"""Découpe une TÊTE réelle dans le corps de base Quaternius et l'exporte en .glb.

POURQUOI CET OUTIL EXISTE
-------------------------
Playtest humain du 2026-08-07 : « NI le héros NI les ennemis n'ont de tête. Le
capuchon du héros est CREUX et VIDE — on voit à l'intérieur, il n'y a rien. »
Vérifié dans les sources : `Male_Ranger.gltf` livre bien un maillage
`Male_Ranger_Head_Hood`, mais c'est la CAPUCHE seule ; aucun crâne n'est dedans.
`Male_Peasant.gltf` (les trois pillards) n'a même pas de capuche : Arms, Body,
Feet, Legs — et rien au-dessus du cou.

Le pack Quaternius contient pourtant une tête : `Superhero_Male_FullBody.gltf`.
Trois faits mesurés autorisent la greffe (voir `--verify`) :

  1. les deux squelettes ont les MÊMES 65 os, dans le MÊME ordre ;
  2. `Head` est à l'index 6 dans les deux ;
  3. la matrice de liaison inverse de `Head` est IDENTIQUE dans les deux
     fichiers — donc la tête extraite se pose exactement où le cou l'attend.

Ce script isole les triangles réellement pilotés par l'os `Head`, les ramène
dans le repère LOCAL de cet os, et écrit un `.glb` statique. Côté Godot, un
`BoneAttachment3D` sur `Head` le porte : pas de re-skinning, pas de dépendance
au rig d'animation, et le même fichier sert au héros et aux trois pillards.

Licence : Quaternius, CC0 1.0 — dérivation licite, consignée dans
ATTRIBUTIONS.md. Aucun contenu tiers sous copyright n'entre ici.

Usage :
    python3 tools/extract_head.py --verify
    python3 tools/extract_head.py --apply
"""

from __future__ import annotations

import argparse
import json
import os
import struct
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(REPO, "assets/characters/parts/Superhero_Male_FullBody.gltf")
RANGER = os.path.join(REPO, "assets/characters/hero/Male_Ranger.gltf")
OUT_DIR = os.path.join(REPO, "assets/characters/parts")
OUT_NAME = "SM_UniversalHead.glb"

HEAD_JOINT = 6          # index de l'os `Head`, identique dans tous les packs
NECK_JOINT = 5          # `neck_01` — sert de garde-fou, jamais de sélection
BODY_MESH = "Sphere.005_Retopology.004"

# Un triangle est retenu si le poids CUMULÉ de l'os `Head` sur ses trois
# sommets dépasse ce seuil. 0,5 coupe net sous la mâchoire : au-dessus on est
# dans le crâne, en dessous dans le cou et les épaules, qui appartiennent déjà
# au corps du Ranger et feraient doublon.
HEAD_WEIGHT_MIN = 0.5


# ---------------------------------------------------------------------------
# Lecture glTF
# ---------------------------------------------------------------------------

def load_gltf(path: str) -> tuple[dict, bytes]:
    """Retourne (json, tampon binaire) pour un .gltf externe ou un .glb."""
    if path.endswith(".glb"):
        blob = open(path, "rb").read()
        json_len = struct.unpack_from("<I", blob, 12)[0]
        doc = json.loads(blob[20:20 + json_len])
        rest = blob[20 + json_len:]
        bin_len = struct.unpack_from("<I", rest, 0)[0]
        return doc, rest[8:8 + bin_len]
    doc = json.load(open(path))
    uri = doc["buffers"][0]["uri"]
    return doc, open(os.path.join(os.path.dirname(path), uri), "rb").read()


COMPONENT = {
    5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2),
    5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4),
}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def read_accessor(doc: dict, data: bytes, index: int) -> list:
    acc = doc["accessors"][index]
    fmt, size = COMPONENT[acc["componentType"]]
    n = NCOMP[acc["type"]]
    view = doc["bufferViews"][acc["bufferView"]]
    base = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = view.get("byteStride") or (size * n)
    out = []
    for i in range(acc["count"]):
        out.append(struct.unpack_from("<" + fmt * n, data, base + i * stride))
    return out


def inverse_bind(doc: dict, data: bytes, joint: int) -> tuple:
    acc = doc["skins"][0]["inverseBindMatrices"]
    return read_accessor(doc, data, acc)[joint]


# ---------------------------------------------------------------------------
# Petite algèbre 4x4 (colonnes majeures, convention glTF)
# ---------------------------------------------------------------------------

def mat_apply_point(m: tuple, p: tuple) -> tuple:
    x, y, z = p
    return (
        m[0] * x + m[4] * y + m[8] * z + m[12],
        m[1] * x + m[5] * y + m[9] * z + m[13],
        m[2] * x + m[6] * y + m[10] * z + m[14],
    )


def mat_apply_dir(m: tuple, v: tuple) -> tuple:
    x, y, z = v
    return (
        m[0] * x + m[4] * y + m[8] * z,
        m[1] * x + m[5] * y + m[9] * z,
        m[2] * x + m[6] * y + m[10] * z,
    )


# ---------------------------------------------------------------------------
# Vérification des trois faits qui autorisent la greffe
# ---------------------------------------------------------------------------

def verify() -> bool:
    src_doc, src_bin = load_gltf(SOURCE)
    rng_doc, rng_bin = load_gltf(RANGER)

    def joint_names(doc: dict) -> list[str]:
        skin = doc["skins"][0]
        return [doc["nodes"][j].get("name", "?") for j in skin["joints"]]

    a, b = joint_names(src_doc), joint_names(rng_doc)
    ok = True

    same_names = a == b
    print(f"  1. mêmes os, même ordre ........ {len(a)} vs {len(b)} : "
          f"{'OUI' if same_names else 'NON'}")
    ok &= same_names

    idx_ok = (a.index("Head") == HEAD_JOINT and b.index("Head") == HEAD_JOINT)
    print(f"  2. `Head` à l'index {HEAD_JOINT} ......... "
          f"{'OUI' if idx_ok else 'NON'}")
    ok &= idx_ok

    m_src = inverse_bind(src_doc, src_bin, HEAD_JOINT)
    m_rng = inverse_bind(rng_doc, rng_bin, HEAD_JOINT)
    delta = max(abs(x - y) for x, y in zip(m_src, m_rng))
    bind_ok = delta < 1e-5
    print(f"  3. liaison inverse de `Head` ... écart max {delta:.2e} : "
          f"{'IDENTIQUE' if bind_ok else 'DIFFÉRENTE'}")
    ok &= bind_ok
    return ok


# ---------------------------------------------------------------------------
# Extraction
# ---------------------------------------------------------------------------

def extract() -> dict:
    doc, data = load_gltf(SOURCE)
    mesh_index = next(i for i, m in enumerate(doc["meshes"])
                      if m["name"] == BODY_MESH)
    prim = doc["meshes"][mesh_index]["primitives"][0]

    positions = read_accessor(doc, data, prim["attributes"]["POSITION"])
    normals = read_accessor(doc, data, prim["attributes"]["NORMAL"])
    uvs = read_accessor(doc, data, prim["attributes"]["TEXCOORD_0"])
    joints = read_accessor(doc, data, prim["attributes"]["JOINTS_0"])
    weights = read_accessor(doc, data, prim["attributes"]["WEIGHTS_0"])
    indices = [i[0] for i in read_accessor(doc, data, prim["indices"])]

    def head_weight(v: int) -> float:
        total = 0.0
        for slot in range(4):
            if joints[v][slot] == HEAD_JOINT:
                total += weights[v][slot]
        return total

    # Sélection par triangle : garder une face entière ou pas du tout, sinon
    # la découpe laisserait des trous le long de la mâchoire.
    kept: list[tuple[int, int, int]] = []
    for t in range(0, len(indices), 3):
        tri = (indices[t], indices[t + 1], indices[t + 2])
        mean = sum(head_weight(v) for v in tri) / 3.0
        if mean >= HEAD_WEIGHT_MIN:
            kept.append(tri)

    # Repère local de l'os `Head` : la matrice de liaison inverse fait
    # exactement ce transport (espace modèle -> espace os, à la pose de liaison).
    to_head = inverse_bind(doc, data, HEAD_JOINT)

    remap: dict[int, int] = {}
    out_pos: list[tuple] = []
    out_nrm: list[tuple] = []
    out_uv: list[tuple] = []
    out_idx: list[int] = []
    for tri in kept:
        for v in tri:
            if v not in remap:
                remap[v] = len(out_pos)
                out_pos.append(mat_apply_point(to_head, positions[v]))
                out_nrm.append(mat_apply_dir(to_head, normals[v]))
                out_uv.append(uvs[v])
            out_idx.append(remap[v])

    return {
        "positions": out_pos, "normals": out_nrm,
        "uvs": out_uv, "indices": out_idx,
        "triangles": len(kept), "source_triangles": len(indices) // 3,
    }


# ---------------------------------------------------------------------------
# Écriture .glb
# ---------------------------------------------------------------------------

def write_glb(mesh: dict, path: str) -> None:
    pos, nrm, uv, idx = (mesh["positions"], mesh["normals"],
                         mesh["uvs"], mesh["indices"])
    pos_b = b"".join(struct.pack("<3f", *p) for p in pos)
    nrm_b = b"".join(struct.pack("<3f", *n) for n in nrm)
    uv_b = b"".join(struct.pack("<2f", *t) for t in uv)
    idx_b = b"".join(struct.pack("<I", i) for i in idx)

    def pad4(b: bytes) -> bytes:
        return b + b"\x00" * (-len(b) % 4)

    chunks = [pad4(pos_b), pad4(nrm_b), pad4(uv_b), pad4(idx_b)]
    offsets, cursor = [], 0
    for c in chunks:
        offsets.append(cursor)
        cursor += len(c)
    blob = b"".join(chunks)

    def bounds(values: list[tuple], n: int) -> tuple[list, list]:
        lo = [min(v[i] for v in values) for i in range(n)]
        hi = [max(v[i] for v in values) for i in range(n)]
        return lo, hi

    pmin, pmax = bounds(pos, 3)
    doc = {
        "asset": {
            "version": "2.0",
            "generator": "tools/extract_head.py — dérivation CC0 Quaternius",
        },
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"name": "UniversalHead", "mesh": 0}],
        "meshes": [{
            "name": "UniversalHead",
            "primitives": [{
                "attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2},
                "indices": 3,
                "material": 0,
            }],
        }],
        "materials": [{
            "name": "MAT_UniversalHead",
            "pbrMetallicRoughness": {
                "baseColorFactor": [1.0, 1.0, 1.0, 1.0],
                "metallicFactor": 0.0,
                "roughnessFactor": 0.72,
            },
        }],
        "buffers": [{"byteLength": len(blob)}],
        "bufferViews": [
            {"buffer": 0, "byteOffset": offsets[0], "byteLength": len(pos_b), "target": 34962},
            {"buffer": 0, "byteOffset": offsets[1], "byteLength": len(nrm_b), "target": 34962},
            {"buffer": 0, "byteOffset": offsets[2], "byteLength": len(uv_b), "target": 34962},
            {"buffer": 0, "byteOffset": offsets[3], "byteLength": len(idx_b), "target": 34963},
        ],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": len(pos),
             "type": "VEC3", "min": pmin, "max": pmax},
            {"bufferView": 1, "componentType": 5126, "count": len(nrm), "type": "VEC3"},
            {"bufferView": 2, "componentType": 5126, "count": len(uv), "type": "VEC2"},
            {"bufferView": 3, "componentType": 5125, "count": len(idx), "type": "SCALAR"},
        ],
    }

    json_b = pad4(json.dumps(doc, separators=(",", ":")).encode("utf-8"))
    json_b = json_b.replace(b"\x00", b"\x20") if json_b[-1:] == b"\x00" else json_b
    while len(json_b) % 4:
        json_b += b" "
    out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(json_b) + 8 + len(blob))
    out += struct.pack("<II", len(json_b), 0x4E4F534A) + json_b
    out += struct.pack("<II", len(blob), 0x004E4942) + blob
    open(path, "wb").write(out)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true",
                        help="écrit le .glb (sinon : vérification seule)")
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()

    print("== Les trois faits qui autorisent la greffe ==")
    if not verify():
        print("REFUS : les squelettes ne correspondent pas.", file=sys.stderr)
        return 1

    mesh = extract()
    y = [p[1] for p in mesh["positions"]]
    z = [p[2] for p in mesh["positions"]]
    x = [p[0] for p in mesh["positions"]]
    print("\n== Découpe ==")
    print(f"  triangles retenus ............. {mesh['triangles']} "
          f"/ {mesh['source_triangles']}")
    print(f"  sommets ....................... {len(mesh['positions'])}")
    print(f"  taille (repère de l'os `Head`)  "
          f"{max(x) - min(x):.3f} x {max(y) - min(y):.3f} x {max(z) - min(z):.3f} m")

    if not args.apply:
        print("\n(vérification seule — relancer avec --apply pour écrire)")
        return 0

    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, OUT_NAME)
    write_glb(mesh, out_path)
    print(f"\nécrit : {os.path.relpath(out_path, REPO)} "
          f"({os.path.getsize(out_path)} octets)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
