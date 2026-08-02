#!/usr/bin/env python3
"""Promotion d'assets Quaternius : extraction → dépôt (ordre V4, §9).

Copie un modèle canonique (.gltf) ET ses dépendances exactes (.bin,
textures référencées par URI) vers un dossier d'assets du dépôt — à
l'octet près, textures partagées dédupliquées par dossier cible.

La SÉLECTION vit dans `docs/assets/PROMOTIONS.csv` (nom canonique →
dossier cible) : un clone qui extrait la Release et rejoue ce script
reconstruit exactement les assets runtime.

Usage :
    python3 tools/promote_quaternius.py <racine_extraite> [--apply]
    python3 tools/promote_quaternius.py <racine_extraite> --only Pine_1

Sans --apply : liste ce qui serait copié. Refuse d'écraser un fichier
existant DIFFÉRENT (le dépôt est l'autorité une fois promu).
"""

import argparse
import csv
import hashlib
import json
import os
import shutil
import sys
import urllib.parse

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROMOTIONS = os.path.join(REPO, "docs", "assets", "PROMOTIONS.csv")

# Défauts de nommage AMONT (revue V4 lot 16, point 8) : ces gltf
# référencent des textures sous un nom ABSENT de l'archive. Le fichier
# réel est copié SOUS le nom référencé — dérivation consignée dans
# ATTRIBUTIONS.md. Clé = nom référencé ; valeur = nom réel dans
# l'archive, présent dans le même dossier que le gltf.
UPSTREAM_RENAMES = {
    "T_Hair_1_Normal_png.png": "T_Hair_1_Normal.png",
    "T_Eye_Normal_png.png": "T_Eye_Normal.png",
}


def sha256_of(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def find_canonical(root: str, name: str) -> str:
    """Retrouve le .gltf canonique (préférence hors dossiers Unity/UE)."""
    hits = []
    for base, _dirs, files in os.walk(root):
        for f in files:
            if f == name + ".gltf":
                hits.append(os.path.join(base, f))
    if not hits:
        raise SystemExit("introuvable dans l'extraction : %s" % name)
    hits.sort(key=lambda p: ("unity" in p.lower() or "unreal" in p.lower(), p))
    return hits[0]


def dependencies(gltf_path: str) -> list:
    g = json.load(open(gltf_path, encoding="utf-8"))
    deps = []
    for b in g.get("buffers", []):
        if b.get("uri") and not b["uri"].startswith("data:"):
            deps.append(urllib.parse.unquote(b["uri"]))
    for i in g.get("images", []):
        if i.get("uri") and not i["uri"].startswith("data:"):
            deps.append(urllib.parse.unquote(i["uri"]))
    return deps


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--only", default="")
    args = parser.parse_args()

    with open(PROMOTIONS, encoding="utf-8") as handle:
        rows = [r for r in csv.DictReader(handle)
                if not r["nom"].startswith("#")]
    copied = 0
    skipped = 0
    total_bytes = 0
    for row in rows:
        name = row["nom"].strip()
        if args.only and name != args.only:
            continue
        dest_dir = os.path.join(REPO, row["dossier"].strip())
        src = find_canonical(args.root, name)
        src_dir = os.path.dirname(src)
        files = [name + ".gltf"] + dependencies(src)
        os.makedirs(dest_dir, exist_ok=True)
        for f in files:
            source = os.path.join(src_dir, f)
            target = os.path.join(dest_dir, f)
            if not os.path.isfile(source) and f in UPSTREAM_RENAMES:
                source = os.path.join(src_dir, UPSTREAM_RENAMES[f])
            if not os.path.isfile(source):
                raise SystemExit("dépendance manquante : %s" % source)
            if os.path.isfile(target):
                if sha256_of(source) == sha256_of(target):
                    skipped += 1
                    continue
                raise SystemExit(
                    "REFUS d'écraser un fichier différent : %s" % target)
            size = os.path.getsize(source)
            total_bytes += size
            if args.apply:
                shutil.copy2(source, target)
            print("%s %-40s -> %s (%d o)" % (
                "copie" if args.apply else "à copier", f,
                row["dossier"].strip(), size))
            copied += 1
    print("[promotion] %d fichier(s) %s, %d identiques ignorés, %.1f Mo" % (
        copied, "copiés" if args.apply else "à copier", skipped,
        total_bytes / 1e6))
    return 0


if __name__ == "__main__":
    sys.exit(main())
