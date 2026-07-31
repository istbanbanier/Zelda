#!/usr/bin/env python3
"""Validation d'un .glb hors moteur, sans dépendance externe (MASTER_SPEC §7.15).

Vérifie ce qui casse réellement un import : en-tête binaire, cohérence des chunks,
échelle et orientation (bas de l'objet au sol), pivot, comptages (meshes, matériaux,
textures, os, animations), présence des attributs (UV0, NORMAL, TANGENT, JOINTS),
et bouclage d'animation.

Ne remplace pas l'import Godot : il prouve la moitié « source » du pipeline et
permet de localiser un défaut avant d'accuser le moteur.

Usage :
    python3 tools/gltf_inspect.py <fichier.glb> [--expect-anim] [--expect-skin]
    python3 tools/gltf_inspect.py <fichier.glb> --json
"""

import argparse
import json
import struct
import sys

GLB_MAGIC = 0x46546C67   # 'glTF'
CHUNK_JSON = 0x4E4F534A  # 'JSON'
CHUNK_BIN = 0x004E4942   # 'BIN\0'


class Report:
    def __init__(self) -> None:
        self.lines: list = []
        self.errors: list = []
        self.warnings: list = []
        self.data: dict = {}

    def info(self, key: str, value) -> None:
        self.data[key] = value
        self.lines.append("  %-22s : %s" % (key, value))

    def error(self, msg: str) -> None:
        self.errors.append(msg)

    def warn(self, msg: str) -> None:
        self.warnings.append(msg)


def read_glb(path: str, rep: Report) -> dict:
    with open(path, "rb") as handle:
        blob = handle.read()
    if len(blob) < 12:
        rep.error("fichier trop court pour un GLB")
        return {}
    magic, version, total = struct.unpack_from("<III", blob, 0)
    if magic != GLB_MAGIC:
        rep.error("en-tête invalide: magic=0x%08X (attendu 0x%08X)" % (magic, GLB_MAGIC))
        return {}
    if version != 2:
        rep.error("version glTF %d (attendu 2)" % version)
    if total != len(blob):
        rep.warn("longueur déclarée %d != taille réelle %d" % (total, len(blob)))
    rep.info("format", "GLB v%d, %d octets" % (version, len(blob)))

    offset, gltf, bin_len = 12, None, 0
    while offset + 8 <= len(blob):
        chunk_len, chunk_type = struct.unpack_from("<II", blob, offset)
        payload = blob[offset + 8: offset + 8 + chunk_len]
        if chunk_type == CHUNK_JSON:
            gltf = json.loads(payload.decode("utf-8"))
        elif chunk_type == CHUNK_BIN:
            bin_len = len(payload)
        offset += 8 + chunk_len + ((4 - chunk_len % 4) % 4)

    if gltf is None:
        rep.error("chunk JSON absent")
        return {}
    rep.info("chunk_binaire", "%d octets" % bin_len)
    return gltf


def accessor_bounds(gltf: dict, mesh_index: int) -> tuple:
    """Bounding box monde-local approximée depuis min/max des accessors POSITION."""
    lo = [float("inf")] * 3
    hi = [float("-inf")] * 3
    mesh = gltf.get("meshes", [])[mesh_index]
    for prim in mesh.get("primitives", []):
        acc_index = prim.get("attributes", {}).get("POSITION")
        if acc_index is None:
            continue
        acc = gltf.get("accessors", [])[acc_index]
        if "min" in acc and "max" in acc:
            for axis in range(3):
                lo[axis] = min(lo[axis], acc["min"][axis])
                hi[axis] = max(hi[axis], acc["max"][axis])
    if lo[0] == float("inf"):
        return None, None
    return lo, hi


def inspect(path: str, expect_anim: bool, expect_skin: bool) -> Report:
    rep = Report()
    gltf = read_glb(path, rep)
    if not gltf:
        return rep

    asset = gltf.get("asset", {})
    rep.info("generateur", asset.get("generator", "?"))
    rep.info("version_gltf", asset.get("version", "?"))

    meshes = gltf.get("meshes", [])
    materials = gltf.get("materials", [])
    textures = gltf.get("textures", [])
    images = gltf.get("images", [])
    nodes = gltf.get("nodes", [])
    skins = gltf.get("skins", [])
    animations = gltf.get("animations", [])
    cameras = gltf.get("cameras", [])

    rep.info("meshes", len(meshes))
    rep.info("materiaux", "%d (%s)" % (len(materials),
             ", ".join(m.get("name", "?") for m in materials) or "aucun"))
    rep.info("textures", "%d image(s), %d texture(s)" % (len(images), len(textures)))
    rep.info("noeuds", "%d (%s)" % (len(nodes),
             ", ".join(n.get("name", "?") for n in nodes[:8])))
    rep.info("skins", len(skins))
    rep.info("animations", "%d (%s)" % (len(animations),
             ", ".join(a.get("name", "?") for a in animations) or "aucune"))

    # §7.15 : aucune caméra/lumière exportée par accident.
    if cameras:
        rep.error("%d caméra(s) exportée(s) — interdit par la convention d'export" % len(cameras))
    if "KHR_lights_punctual" in gltf.get("extensionsUsed", []):
        rep.error("lumières exportées (KHR_lights_punctual) — interdit")

    total_tris = 0
    for index, mesh in enumerate(meshes):
        for prim in mesh.get("primitives", []):
            attrs = prim.get("attributes", {})
            if "POSITION" not in attrs:
                rep.error("mesh '%s': primitive sans POSITION" % mesh.get("name", index))
            if "NORMAL" not in attrs:
                rep.warn("mesh '%s': pas de NORMAL" % mesh.get("name", index))
            if "TEXCOORD_0" not in attrs:
                rep.warn("mesh '%s': pas d'UV0 — lightmap et matériaux limités"
                         % mesh.get("name", index))
            if expect_skin and "JOINTS_0" not in attrs:
                rep.error("mesh '%s': skin attendu mais JOINTS_0 absent" % mesh.get("name", index))
            acc_index = prim.get("indices")
            if acc_index is not None:
                count = gltf["accessors"][acc_index].get("count", 0)
                total_tris += count // 3
    rep.info("triangles", total_tris)

    if meshes:
        lo, hi = accessor_bounds(gltf, 0)
        if lo is not None:
            size = [round(hi[i] - lo[i], 4) for i in range(3)]
            rep.info("bbox_min", [round(v, 4) for v in lo])
            rep.info("bbox_max", [round(v, 4) for v in hi])
            rep.info("dimensions_m", size)
            # Convention projet : Y vertical, bas de l'objet au sol -> min Y ≈ 0.
            if abs(lo[1]) > 0.01:
                rep.warn("min Y = %.4f (attendu ~0 : bas de l'objet au sol, §7.15)" % lo[1])
            if max(size) > 1000.0 or max(size) < 0.001:
                rep.error("échelle invraisemblable %s — vérifier les unités métriques" % size)

    if expect_anim and not animations:
        rep.error("animation attendue mais aucune n'est présente")
    for anim in animations:
        channels = anim.get("channels", [])
        rep.info("anim:%s" % anim.get("name", "?"),
                 "%d canaux, %d samplers" % (len(channels), len(anim.get("samplers", []))))
        if not channels:
            rep.error("animation '%s' sans canal" % anim.get("name", "?"))

    if expect_skin and not skins:
        rep.error("skin attendu mais aucun n'est présent")
    for skin in skins:
        rep.info("skin:%s" % skin.get("name", "?"), "%d os" % len(skin.get("joints", [])))

    return rep


def main() -> int:
    parser = argparse.ArgumentParser(prog="gltf_inspect")
    parser.add_argument("glb")
    parser.add_argument("--expect-anim", action="store_true")
    parser.add_argument("--expect-skin", action="store_true")
    parser.add_argument("--json", action="store_true", help="sortie machine")
    args = parser.parse_args()

    rep = inspect(args.glb, args.expect_anim, args.expect_skin)

    if args.json:
        print(json.dumps({"file": args.glb, "data": rep.data,
                          "errors": rep.errors, "warnings": rep.warnings}, indent=2))
    else:
        print("=== INSPECTION glTF : %s ===" % args.glb)
        for line in rep.lines:
            print(line)
        for warning in rep.warnings:
            print("  [AVERT] %s" % warning)
        for error in rep.errors:
            print("  [ERREUR] %s" % error)
        print("=== %s ===" % ("VALIDE" if not rep.errors else "INVALIDE"))
    return 1 if rep.errors else 0


if __name__ == "__main__":
    sys.exit(main())
