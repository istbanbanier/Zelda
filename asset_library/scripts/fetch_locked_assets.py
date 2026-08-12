#!/usr/bin/env python3
"""Télécharge et élague la bibliothèque CC0 verrouillée, hors build Godot."""

from __future__ import annotations

import csv
import hashlib
import os
from pathlib import Path, PurePosixPath
import shutil
import sys
import tempfile
import urllib.request
import zipfile


ROOT = Path(__file__).resolve().parents[2]
LOCK = ROOT / "asset_library" / "SOURCES.lock.csv"
INBOX = ROOT / "asset_library" / "inbox"
INVENTORY = ROOT / "asset_library" / "INVENTORY.csv"
ARCHIVES = ROOT / "asset_library" / "SOURCE_ARCHIVE_SHA256.csv"
SUMS = ROOT / "asset_library" / "SHA256SUMS.txt"
MAX_TOTAL = 120 * 1024 * 1024
MAX_FILE = 50 * 1024 * 1024
MAX_FILES = 6000

COMMON = {".txt", ".md", ".pdf"}
KEEP = {
    "model": {".glb", ".gltf", ".bin", ".png", ".jpg", ".jpeg"} | COMMON,
    "audio": {".ogg", ".wav"} | COMMON,
    "image": {".png"} | COMMON,
}
DOC_WORDS = ("license", "licence", "readme", "credit", "attribution", "authors")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def safe_members(archive: zipfile.ZipFile) -> list[zipfile.ZipInfo]:
    members: list[zipfile.ZipInfo] = []
    for info in archive.infolist():
        pure = PurePosixPath(info.filename)
        if pure.is_absolute() or ".." in pure.parts:
            raise RuntimeError(f"chemin dangereux dans l'archive: {info.filename}")
        if info.file_size > MAX_FILE:
            raise RuntimeError(f"fichier individuel trop lourd: {info.filename}")
        members.append(info)
    return members


def wanted(path: Path, policy: str) -> bool:
    lower = path.name.lower()
    if any(word in lower for word in DOC_WORDS):
        return True
    return path.suffix.lower() in KEEP[policy]


def copy_payload(extracted: Path, destination: Path, policy: str) -> int:
    files = [p for p in extracted.rglob("*") if p.is_file()]
    glb_exists = policy == "model" and any(p.suffix.lower() == ".glb" for p in files)
    count = 0
    for source in files:
        if not wanted(source, policy):
            continue
        # Un pack livré en GLB n'a pas besoin de sa seconde copie glTF + BIN.
        if glb_exists and source.suffix.lower() in {".gltf", ".bin"}:
            continue
        relative = source.relative_to(extracted)
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        count += 1
    return count


def write_provenance(destination: Path, row: dict[str, str], archive_hash: str) -> None:
    text = f"""# Provenance verrouillée

- Pack : {row['title']}
- Auteur : {row['author']}
- Page officielle : {row['official_page']}
- Transport automatisé : {row['transport_url']}
- Licence vérifiée : CC0 1.0 Universal
- Texte de licence : https://creativecommons.org/publicdomain/zero/1.0/
- SHA-256 de l'archive reçue : `{archive_hash}`

Ce dossier reste hors build. Le transport OpenGameArt est un miroir du pack publié
par Kenney ; l'autorité de provenance et de licence est la page officielle indiquée.
"""
    (destination / "PROVENANCE.md").write_text(text, encoding="utf-8")


def download(row: dict[str, str], temporary: Path) -> tuple[Path, str]:
    archive = temporary / f"{row['id']}.zip"
    request = urllib.request.Request(
        row["transport_url"], headers={"User-Agent": "Eclats-d-Orage-asset-courier/1.0"}
    )
    with urllib.request.urlopen(request, timeout=300) as response, archive.open("wb") as out:
        shutil.copyfileobj(response, out)
    if archive.stat().st_size < 10_000:
        raise RuntimeError(f"archive anormalement petite: {row['id']}")
    if not zipfile.is_zipfile(archive):
        raise RuntimeError(f"réponse non ZIP: {row['id']}")
    return archive, sha256(archive)


def build() -> None:
    with LOCK.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    if not rows:
        raise RuntimeError("SOURCES.lock.csv est vide")

    shutil.rmtree(INBOX, ignore_errors=True)
    INBOX.mkdir(parents=True)
    archive_rows: list[list[str]] = []

    with tempfile.TemporaryDirectory(prefix="zelda-assets-") as raw_tmp:
        temporary = Path(raw_tmp)
        for row in rows:
            print(f"[asset] {row['id']} <- {row['transport_url']}", flush=True)
            archive, archive_hash = download(row, temporary)
            extracted = temporary / f"extract-{row['id']}"
            extracted.mkdir()
            with zipfile.ZipFile(archive) as zipped:
                safe_members(zipped)
                zipped.extractall(extracted)
            destination = INBOX / row["id"]
            destination.mkdir()
            count = copy_payload(extracted, destination, row["keep_policy"])
            minimum = int(row["expected_min_payload"])
            if count < minimum:
                raise RuntimeError(
                    f"{row['id']}: seulement {count} fichiers utiles, minimum {minimum}"
                )
            write_provenance(destination, row, archive_hash)
            archive_rows.append(
                [row["id"], archive_hash, str(archive.stat().st_size), row["transport_url"]]
            )

    payload = sorted(p for p in INBOX.rglob("*") if p.is_file())
    if len(payload) > MAX_FILES:
        raise RuntimeError(f"trop de fichiers: {len(payload)} > {MAX_FILES}")
    total = sum(p.stat().st_size for p in payload)
    if total > MAX_TOTAL:
        raise RuntimeError(f"bibliothèque trop lourde: {total} > {MAX_TOTAL}")
    for path in payload:
        if path.stat().st_size > MAX_FILE:
            raise RuntimeError(f"fichier trop lourd après élagage: {path}")

    with ARCHIVES.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(["id", "archive_sha256", "archive_bytes", "transport_url"])
        writer.writerows(archive_rows)

    inventory_rows: list[list[str]] = []
    sum_lines: list[str] = []
    for path in payload:
        relative = path.relative_to(ROOT).as_posix()
        digest = sha256(path)
        pack = path.relative_to(INBOX).parts[0]
        inventory_rows.append([pack, relative, str(path.stat().st_size), digest, path.suffix.lower()])
        sum_lines.append(f"{digest}  {relative}")
    with INVENTORY.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(["pack", "path", "bytes", "sha256", "extension"])
        writer.writerows(inventory_rows)
    SUMS.write_text("\n".join(sum_lines) + "\n", encoding="utf-8")
    print(f"[asset] OK: {len(rows)} packs, {len(payload)} fichiers, {total} octets")


if __name__ == "__main__":
    try:
        build()
    except Exception as exc:  # le workflow doit rendre l'échec très visible
        print(f"[asset] ECHEC: {exc}", file=sys.stderr)
        raise
