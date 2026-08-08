#!/usr/bin/env bash
# Fournit Blender à une session neuve.
#
# POURQUOI CE SCRIPT EXISTE : le niveau 3b de `validate_fast.sh` (continuité des
# personnages, ISS-019) appelle Blender. Sans lui, la suite sort ROUGE en
# annonçant « la continuité des personnages n'est PAS vérifiée » — ce qui est le
# comportement correct, mais laisse un contrôle non exécuté à chaque session.
#
# `setup_godot.sh` fournissait le moteur ; rien ne fournissait Blender. Une
# session neuve devait donc le découvrir, puis trouver elle-même que le dépôt
# Ubuntu suffit (contournement D-002 d'ISS-001 : downloads.blender.org est
# bloqué par la politique de sortie réseau, apt ne l'est pas).
#
# Durée : ~2 min. Idempotent : ne réinstalle pas si déjà présent.
set -euo pipefail

BLENDER_BIN="${BLENDER_BIN:-blender}"

if command -v "$BLENDER_BIN" >/dev/null 2>&1; then
  echo "Blender déjà présent : $(command -v "$BLENDER_BIN")"
  "$BLENDER_BIN" --version | head -1
  exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "ERREUR: installation apt — relancer en root." >&2
  exit 1
fi

echo "== installation depuis le dépôt Ubuntu (D-002) =="
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q --no-install-recommends blender

command -v blender >/dev/null 2>&1 || {
  echo "ERREUR: blender absent après installation." >&2; exit 1; }
blender --version | head -1
echo "OK — le niveau 3b de validate_fast.sh peut désormais s'exécuter."
