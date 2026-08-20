#!/usr/bin/env bash
# Fournit Godot 4.7.1-stable à une session neuve.
#
# POURQUOI UNE COMPILATION : dans l'environnement d'exécution actuel, la politique
# réseau bloque godotengine.org et downloads.godotengine.org (CONNECT -> 403), donc
# aucun binaire officiel ne peut être téléchargé. github.com reste accessible en
# lecture git, ce qui permet de construire la version exacte depuis la source.
# Sur un poste normal, PRÉFÉRER le binaire officiel et ignorer ce script.
#
# Durée : ~60-120 min sur 4 cœurs. Idempotent : ne recompile pas si déjà présent.
set -euo pipefail

GODOT_TAG="4.7.1-stable"
GODOT_COMMIT="a13da4feb8d8aefc283c3763d33a2f170a18d541"  # tag 4.7.1-stable, vérifié
SRC_DIR="${GODOT_SRC_DIR:-/opt/src/godot}"
DEST="${GODOT_BIN:-/usr/local/bin/godot}"
JOBS="${JOBS:-$(nproc)}"

# ISS-063 — CE SCRIPT EST LE PLUS DANGEREUX DU DÉPÔT, ET IL N'AVAIT AUCUN VERROU.
# Signalé par la contre-épreuve du 2026-08-20 : il compile ~90 min avec
# `scons -j$(nproc)`, puis REMPLACE le binaire par un lien symbolique — sous les
# pieds de tout moteur en cours d'exécution. L'exempter parce qu'il « ne touche
# pas user:// » aurait exempté le plus gros consommateur processeur du conteneur
# ET le seul écrivain du binaire.
#
# Le verrou est pris AVANT le test de version : ce test exécute déjà le binaire,
# et le binaire peut être en cours de remplacement par une autre invocation.
# Attente longue, à dessein : mieux vaut attendre une suite que compiler pendant
# qu'elle tourne.
# shellcheck source=lib/godot_env.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/godot_env.sh"
godot_verrou_prendre 8 7200 || exit 3

if [ -x "$DEST" ] && "$DEST" --version 2>&1 | grep -q '^4\.7\.1\.stable'; then
  echo "Godot 4.7.1-stable déjà présent : $DEST"
  "$DEST" --version
  exit 0
fi

echo "== 1/4 dépendances de build =="
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q --no-install-recommends \
  build-essential pkg-config scons \
  libx11-dev libxcursor-dev libxinerama-dev libxi-dev libxrandr-dev \
  libgl1-mesa-dev libglu1-mesa-dev libasound2-dev libpulse-dev libudev-dev \
  libwayland-dev libdbus-1-dev libspeechd-dev libfontconfig1-dev

echo "== 2/4 source =="
if [ ! -d "$SRC_DIR/.git" ]; then
  mkdir -p "$(dirname "$SRC_DIR")"
  git clone --depth 1 --branch "$GODOT_TAG" https://github.com/godotengine/godot.git "$SRC_DIR"
fi
cd "$SRC_DIR"
ACTUAL="$(git rev-parse HEAD)"
if [ "$ACTUAL" != "$GODOT_COMMIT" ]; then
  echo "ERREUR: commit $ACTUAL != attendu $GODOT_COMMIT — refus de construire une version non épinglée." >&2
  exit 1
fi
echo "commit vérifié : $ACTUAL"

echo "== 3/4 compilation (target=editor, -j$JOBS) =="
scons platform=linuxbsd target=editor arch=x86_64 debug_symbols=no -j"$JOBS"

echo "== 4/4 installation =="
BIN="$SRC_DIR/bin/godot.linuxbsd.editor.x86_64"
test -x "$BIN" || { echo "ERREUR: binaire absent après compilation" >&2; exit 1; }
ln -sf "$BIN" "$DEST"
"$DEST" --version
echo "OK -> $DEST"
