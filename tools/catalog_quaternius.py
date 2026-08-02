#!/usr/bin/env python3
"""Catalogue EXHAUSTIF des sept packs Quaternius (ordre de nuit V4, §5-§7).

Traite 100 % des entrées extraites : chaque fichier reçoit un statut, les
assets logiques (modèles canoniques glTF) reçoivent des métriques réelles
(triangles, matériaux, squelette, animations, bbox TOUS meshes confondus)
et un score préliminaire sur 100 selon la grille imposée §7.

Le score automatique est un TRI préparatoire transparent (listes de
mots-clés lisibles ci-dessous) — le verdict artistique final reste humain.

Usage :
    python3 tools/catalog_quaternius.py <racine_extraite> \
        --json docs/assets/quaternius_catalog.json \
        --csv docs/assets/quaternius_catalog.csv \
        --report docs/assets/CATALOG_REPORT.md

Reproductible : un clone qui télécharge et extrait la Release
`asset-inbox-quaternius-free-v1` obtient le même catalogue.
"""

import argparse
import csv
import hashlib
import json
import os
import sys
import urllib.parse

# ---------------------------------------------------------------------------
# Statuts imposés par l'ordre §5
# ---------------------------------------------------------------------------
S_USED = "UTILISÉ_RUNTIME"
S_CANDIDATE = "CANDIDAT_RUNTIME"
S_GALLERY = "GALERIE"
S_DUP_FORMAT = "DOUBLON_FORMAT"
S_DUP_CONTENT = "DOUBLON_CONTENU"
S_ROOT_MOTION = "VARIANTE_ROOT_MOTION"
S_TECH = "SOURCE_TECHNIQUE"
S_INCOMPATIBLE = "INCOMPATIBLE"
S_REJECTED = "REJETÉ_ARTISTIQUEMENT"
S_ADAPT = "À_ADAPTER"

# Extensions purement techniques (jamais des assets logiques en soi).
TECH_EXT = {".bin", ".txt", ".ini", ".md", ".blend", ".blend1", ".mtl"}
# Formats alternatifs : doublons de format quand le canonique glTF existe.
ALT_MODEL_EXT = {".fbx", ".obj"}
CANON_MODEL_EXT = {".gltf", ".glb"}
TEXTURE_EXT = {".png", ".jpg", ".jpeg"}

# ---------------------------------------------------------------------------
# Grille de score §7 — composantes automatisables, listes TRANSPARENTES.
# v4_fit (25) : correspondance aux concepts V4 (vallée tempérée, camp,
# citadelle de pierre, orage cyan). utility (20) : zone/gameplay réel.
# ---------------------------------------------------------------------------
V4_FIT_HIGH = ["commontree", "birch", "pine", "bush", "grass", "flower",
    "fern", "clover", "rock", "cliff", "pebble", "stone", "mushroom",
    "willow", "petal", "wall", "arch", "pillar", "column", "stair", "door",
    "doorframe", "tower", "roof", "floor_", "chest", "barrel", "crate",
    "torch", "cauldron", "campfire", "tent", "log", "stump", "bench",
    "table", "lantern", "banner", "ranger", "peasant", "knight", "mage",
    "sword", "axe", "shield", "bow", "corner", "overhang", "window",
    "balcony", "bridge", "fence", "well", "cart", "wagon", "sack", "pouch",
    "bucket", "pot_", "anvil", "book", "candle", "bottle", "mug", "barrel"]
V4_FIT_LOW = ["cactus", "palm", "desert", "snow", "winter", "ice", "pistol",
    "gun", "driving", "car", "zombie", "phone", "modern", "dummy", "coin",
    "chandelier", "cage"]

UTILITY_ZONES = {
    "tree": ("foret", 20), "pine": ("hauteurs", 20), "bush": ("lisieres", 18),
    "grass": ("prairie", 18), "flower": ("prairie", 16), "rock": ("guidage", 20),
    "cliff": ("falaise", 20), "mushroom": ("foret", 14),
    "wall": ("citadelle", 20), "arch": ("citadelle", 18),
    "stair": ("citadelle", 20), "door": ("citadelle", 18),
    "floor": ("interieurs", 18), "roof": ("structures", 16),
    "chest": ("loot", 20), "barrel": ("camp", 16), "crate": ("camp", 16),
    "torch": ("eclairage", 18), "cauldron": ("cuisine", 20),
    "tent": ("camp", 20), "table": ("interieurs", 14), "bench": ("camp", 14),
    "sword": ("armes_decor", 12), "axe": ("armes_decor", 12),
    "shield": ("armes_decor", 12), "banner": ("citadelle", 14),
}


def sha256_of(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def gltf_metrics(path: str) -> dict:
    """Métriques réelles d'un modèle glTF/GLB : tris, bbox TOUS meshes,
    matériaux, images, squelette, animations."""
    try:
        if path.lower().endswith(".glb"):
            import struct
            blob = open(path, "rb").read()
            offset, gltf = 12, None
            while offset + 8 <= len(blob):
                length, kind = struct.unpack_from("<II", blob, offset)
                if kind == 0x4E4F534A:
                    gltf = json.loads(blob[offset + 8:offset + 8 + length])
                    break
                offset += 8 + length + ((4 - length % 4) % 4)
        else:
            gltf = json.load(open(path, "r", encoding="utf-8"))
    except (ValueError, OSError, KeyError):
        return {"error": "illisible"}
    if gltf is None:
        return {"error": "chunk JSON absent"}
    accessors = gltf.get("accessors", [])
    tris = 0
    lo = [float("inf")] * 3
    hi = [float("-inf")] * 3
    for mesh in gltf.get("meshes", []):
        for prim in mesh.get("primitives", []):
            idx = prim.get("indices")
            if idx is not None and idx < len(accessors):
                tris += accessors[idx].get("count", 0) // 3
            pos = prim.get("attributes", {}).get("POSITION")
            if pos is not None and pos < len(accessors):
                acc = accessors[pos]
                if "min" in acc and "max" in acc:
                    for axis in range(3):
                        lo[axis] = min(lo[axis], acc["min"][axis])
                        hi[axis] = max(hi[axis], acc["max"][axis])
    bbox = None
    if lo[0] != float("inf"):
        bbox = [round(hi[i] - lo[i], 3) for i in range(3)]
    skins = gltf.get("skins", [])
    return {
        "meshes": len(gltf.get("meshes", [])),
        "triangles": tris,
        "materials": [m.get("name", "?") for m in gltf.get("materials", [])],
        "images": [urllib.parse.unquote(i.get("uri", i.get("name", "?")))
                   for i in gltf.get("images", [])],
        "bones": len(skins[0].get("joints", [])) if skins else 0,
        "animations": [a.get("name", "?") for a in gltf.get("animations", [])],
        "bbox": bbox,
        "min_y": round(lo[1], 3) if bbox else None,
    }


def categorize(rel: str, name: str) -> str:
    low = (rel + "/" + name).lower()
    if "animation.library" in low or "ual" in low.split("/")[0].replace(".", ""):
        return "Animations"
    if "base.characters" in low or "mannequin" in low:
        return "Personnages" if "hair" not in low and "eyebrow" not in low \
            else "Coiffures"
    if "outfits" in low:
        return "Tenues"
    if "nature" in low:
        n = name.lower()
        if any(k in n for k in ["rock", "pebble", "cliff", "stone"]):
            return "Rochers"
        return "Nature"
    if "props" in low:
        return "Props"
    if "village" in low:
        return "Architecture"
    return "Autre"


def score_asset(name: str, category: str, metrics: dict) -> dict:
    """Grille §7 — heuristique transparente. Composantes sur 100."""
    n = name.lower()
    v4 = 8
    if any(k in n for k in V4_FIT_HIGH):
        v4 = 22
    if any(k in n for k in V4_FIT_LOW):
        v4 = 3
    utility = 6
    zone = ""
    for key, (z, pts) in UTILITY_ZONES.items():
        if key in n:
            utility, zone = pts, z
            break
    if category in ("Personnages", "Tenues", "Animations"):
        utility, zone = 18, "personnages"
    tris = int(metrics.get("triangles", 0) or 0)
    bbox = metrics.get("bbox") or [0, 0, 0]
    height = bbox[1] if len(bbox) > 1 else 0
    # Silhouette (15) : les éléments verticaux/structurants lisent de loin.
    silhouette = 11 if height >= 2.0 else (8 if height >= 0.8 else 5)
    if any(k in n for k in ["tree", "tower", "pine", "cliff", "pylon", "wall"]):
        silhouette = 14
    # Compatibilité modulaire (15) : kits + connecteurs.
    modular = 12 if category == "Architecture" else 8
    if any(k in n for k in ["corner", "straight", "half", "frame", "_l", "_r"]):
        modular = 14
    # Qualité proportion/matériau (10) : proxy — tris ni squelettique ni fou.
    quality = 8 if 50 <= tris <= 60000 else 4
    # Coût technique (10) : petit = bon marché.
    cost = 9 if tris <= 8000 else (7 if tris <= 20000 else
        (5 if tris <= 60000 else 2))
    # Collision/navigation (5).
    collision = 4 if category in ("Architecture", "Rochers", "Props") else 3
    total = v4 + utility + silhouette + modular + quality + cost + collision
    return {"v4_fit": v4, "utility": utility, "zone": zone,
            "silhouette": silhouette, "modular": modular, "quality": quality,
            "cost": cost, "collision": collision, "total": total}


def already_in_repo(repo_root: str) -> set:
    used = set()
    for base, _dirs, files in os.walk(os.path.join(repo_root, "assets")):
        for f in files:
            used.add(f.lower())
    return used


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root")
    parser.add_argument("--json", required=True)
    parser.add_argument("--csv", required=True)
    parser.add_argument("--report", required=True)
    args = parser.parse_args()

    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    used_files = already_in_repo(repo)

    entries = []
    hash_first = {}
    canon_stems = {}   # (pack, stem) -> chemin canonique gltf
    all_files = []
    for base, _dirs, files in os.walk(args.root):
        for f in sorted(files):
            all_files.append(os.path.join(base, f))
    # Première passe : recenser les canoniques par pack.
    for path in all_files:
        rel = os.path.relpath(path, args.root)
        pack = rel.split(os.sep)[0]
        stem, ext = os.path.splitext(os.path.basename(path))
        if ext.lower() in CANON_MODEL_EXT:
            key = (pack, stem.lower())
            prev = canon_stems.get(key)
            # préférer l'export Godot/générique au dossier Unity/UE.
            if prev is None or ("unity" in prev.lower()
                    or "unreal" in prev.lower()):
                canon_stems[key] = path

    for path in all_files:
        rel = os.path.relpath(path, args.root)
        pack = rel.split(os.sep)[0]
        name = os.path.basename(path)
        stem, ext = os.path.splitext(name)
        ext = ext.lower()
        digest = sha256_of(path)
        entry = {
            "path": rel, "pack": pack, "name": name, "ext": ext,
            "size": os.path.getsize(path), "sha256": digest[:16],
            "category": categorize(rel, name),
        }
        # -- statut --
        if digest in hash_first:
            entry["status"] = S_DUP_CONTENT
            entry["duplicate_of"] = hash_first[digest]
        elif ext in TECH_EXT:
            entry["status"] = S_TECH
        elif "_rm" in stem.lower():
            entry["status"] = S_ROOT_MOTION
        elif ext in ALT_MODEL_EXT:
            key = (pack, stem.lower())
            entry["status"] = S_DUP_FORMAT if key in canon_stems \
                else S_INCOMPATIBLE
        elif ext in CANON_MODEL_EXT:
            if canon_stems.get((pack, stem.lower())) != path:
                entry["status"] = S_DUP_FORMAT   # ex. copie Unity du même stem
            else:
                metrics = gltf_metrics(path)
                entry["metrics"] = metrics
                if "error" in metrics:
                    entry["status"] = S_INCOMPATIBLE
                else:
                    score = score_asset(stem, entry["category"], metrics)
                    entry["score"] = score
                    if name.lower() in used_files:
                        entry["status"] = S_USED
                    elif score["total"] >= 65:
                        entry["status"] = S_CANDIDATE
                    elif score["total"] >= 45:
                        entry["status"] = S_ADAPT
                    else:
                        entry["status"] = S_REJECTED
        elif ext in TEXTURE_EXT:
            entry["status"] = S_USED if name.lower() in used_files else S_GALLERY
        else:
            entry["status"] = S_TECH
        if digest not in hash_first:
            hash_first[digest] = rel
        entries.append(entry)

    # -- sorties --
    os.makedirs(os.path.dirname(args.json), exist_ok=True)
    stats = {}
    by_cat = {}
    for e in entries:
        stats[e["status"]] = stats.get(e["status"], 0) + 1
        by_cat[e["category"]] = by_cat.get(e["category"], 0) + 1
    logical = [e for e in entries if "score" in e]
    with open(args.json, "w", encoding="utf-8") as handle:
        json.dump({"root": os.path.basename(args.root),
                   "total_entries": len(entries), "status_counts": stats,
                   "category_counts": by_cat, "entries": entries},
                  handle, ensure_ascii=False, indent=1)
    with open(args.csv, "w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["path", "pack", "category", "status", "size",
                         "sha256_16", "triangles", "bones", "animations",
                         "score_total", "zone"])
        for e in entries:
            m = e.get("metrics", {})
            s = e.get("score", {})
            writer.writerow([e["path"], e["pack"], e["category"], e["status"],
                e["size"], e["sha256"], m.get("triangles", ""),
                m.get("bones", ""), len(m.get("animations", []))
                    if m.get("animations") is not None else "",
                s.get("total", ""), s.get("zone", "")])

    lines = ["# Catalogue Quaternius — rapport automatisé (V4 lot 2)", "",
        "Score = TRI préliminaire transparent (grille §7, mots-clés dans "
        "`tools/catalog_quaternius.py`) — le verdict artistique reste humain.",
        "", f"- Entrées traitées : **{len(entries)}** (100 %)",
        f"- Assets logiques scorés (modèles canoniques) : **{len(logical)}**",
        "", "## Statuts", ""]
    for status, count in sorted(stats.items(), key=lambda kv: -kv[1]):
        lines.append(f"| {status} | {count} |")
    lines.insert(len(lines) - len(stats), "| Statut | Entrées |")
    lines.insert(len(lines) - len(stats), "|---|---:|")
    lines += ["", "## Catégories", "", "| Catégorie | Entrées |", "|---|---:|"]
    for cat, count in sorted(by_cat.items(), key=lambda kv: -kv[1]):
        lines.append(f"| {cat} | {count} |")
    lines += ["", "## Meilleurs scores par catégorie (préliminaires)", ""]
    for cat in sorted(by_cat):
        top = sorted((e for e in logical if e["category"] == cat),
                     key=lambda e: -e["score"]["total"])[:12]
        if not top:
            continue
        lines.append(f"### {cat}")
        lines.append("")
        lines.append("| Modèle | Score | Tris | Statut |")
        lines.append("|---|---:|---:|---|")
        for e in top:
            lines.append(f"| {os.path.splitext(e['name'])[0]} "
                f"| {e['score']['total']} "
                f"| {e['metrics'].get('triangles', '?')} | {e['status']} |")
        lines.append("")
    with open(args.report, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")
    print(f"[catalogue] {len(entries)} entrées, {len(logical)} scorées "
          f"-> {args.json}, {args.csv}, {args.report}")
    for status, count in sorted(stats.items(), key=lambda kv: -kv[1]):
        print(f"  {status:24s} {count}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
