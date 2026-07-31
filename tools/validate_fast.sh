#!/usr/bin/env bash
# Pyramide de validation, niveaux 1-3 (MASTER_SPEC §21.7). Quelques minutes max.
#   1. Parse/import smoke : le projet importe et quitte sans parse error.
#   2. Unit               : données, formules, graphes, sérialisation, règles pures.
#   3. Integration scene  : quelques systèmes raccordés dans une scène minimale.
#
# Code retour 0 = tout vert. Non nul = au moins un niveau rouge.
# Ce script n'exécute AUCUNE capture ni mesure de performance : voir validate_release.sh.
set -uo pipefail

cd "$(dirname "$0")/.."
PROJECT_DIR="$PWD"
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"
LOG_DIR="${LOG_DIR:-evidence/validate_fast}"
mkdir -p "$LOG_DIR"

FAIL=0
step() { printf '\n=== %s ===\n' "$1"; }
ok()   { echo "  [OK]   $1"; }
bad()  { echo "  [ÉCHEC] $1"; FAIL=1; }

if [ ! -x "$GODOT_BIN" ]; then
  echo "ÉCHEC BLOQUANT: binaire Godot absent ($GODOT_BIN). Lancer tools/setup_godot.sh." >&2
  exit 2
fi

step "0. Version du moteur"
VERSION="$("$GODOT_BIN" --version 2>&1 | tail -1)"
echo "  $VERSION"
case "$VERSION" in
  4.7.1.stable*) ok "Godot 4.7.1-stable confirmé" ;;
  *) bad "version inattendue — MASTER_SPEC §5.1 exige 4.7.1-stable" ;;
esac

step "1. Import des ressources (parse/import smoke)"
IMPORT_LOG="$LOG_DIR/01_import.log"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --import > "$IMPORT_LOG" 2>&1
IMPORT_RC=$?
# Godot renvoie 0 même avec des erreurs de script : filtrer explicitement le log.
if grep -qiE 'parse error|SCRIPT ERROR|Failed to load script|Cannot open file|res://.*\.gd:[0-9]+ - Parse Error' "$IMPORT_LOG"; then
  bad "erreurs détectées dans $IMPORT_LOG"
  grep -iE 'parse error|SCRIPT ERROR|Failed to load|Cannot open file' "$IMPORT_LOG" | head -20
elif [ $IMPORT_RC -ne 0 ]; then
  bad "code retour $IMPORT_RC (voir $IMPORT_LOG)"
else
  ok "import sans parse error (code retour 0)"
fi

step "2. Tests unitaires"
UNIT_LOG="$LOG_DIR/02_unit.log"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --script tools/godot/test_runner.gd > "$UNIT_LOG" 2>&1
UNIT_RC=$?
grep -E '^\s+(ok|ÉCHEC)|^=== RÉSULTAT' "$UNIT_LOG" | sed 's/^/  /'
if [ $UNIT_RC -eq 0 ]; then ok "suite unitaire verte"; else bad "suite unitaire rouge (code $UNIT_RC, voir $UNIT_LOG)"; fi

step "3. Scène d'intégration (chargement réel de la scène principale)"
SCENE_LOG="$LOG_DIR/03_scene.log"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --quit-after 5 > "$SCENE_LOG" 2>&1
SCENE_RC=$?
if grep -qiE 'SCRIPT ERROR|Failed to instantiate|Cannot open|ERROR:' "$SCENE_LOG"; then
  bad "erreurs au chargement de la scène (voir $SCENE_LOG)"
  grep -iE 'SCRIPT ERROR|ERROR:' "$SCENE_LOG" | head -10
elif [ $SCENE_RC -ne 0 ]; then
  bad "code retour $SCENE_RC (voir $SCENE_LOG)"
else
  ok "scène principale chargée et quittée proprement"
  grep '^\[boot\]' "$SCENE_LOG" | sed 's/^/    /'
fi

printf '\n=== VALIDATE_FAST : %s ===\n' "$([ $FAIL -eq 0 ] && echo VERT || echo ROUGE)"
echo "logs: $LOG_DIR"
exit $FAIL
