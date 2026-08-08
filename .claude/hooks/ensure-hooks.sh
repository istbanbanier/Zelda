#!/usr/bin/env bash
# Pointe `core.hooksPath` de ce clone vers `.githooks`, afin que le plancher
# déterministe de pre-push tourne réellement. Exécuté au démarrage de session.
#
# Idempotent, et n'agit QUE si personne ne possède déjà le chemin de hooks : il ne
# doit jamais écraser une configuration existante (husky ou réglage personnel).
set -uo pipefail

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$dir" 2>/dev/null || exit 0
command -v git >/dev/null 2>&1 || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
[ -d .githooks ] || exit 0

current=$(git config --get core.hooksPath 2>/dev/null || true)
if [ -z "$current" ]; then
  git config core.hooksPath .githooks 2>/dev/null || true
fi
exit 0
