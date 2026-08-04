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

step "1b. Parse de TOUS les scripts GDScript"
# N9 : l'import ne parse que les scripts atteignables depuis une ressource. Un
# script non référencé pouvait contenir une erreur de syntaxe sans que
# `validate_fast.sh` ne rougisse — la promesse « parse smoke » était fausse.
# Chaque .gd est donc vérifié individuellement avec --check-only.
PARSE_LOG="$LOG_DIR/01b_parse.log"
: > "$PARSE_LOG"
PARSE_FAILED=0
PARSE_COUNT=0
while IFS= read -r script; do
  PARSE_COUNT=$((PARSE_COUNT + 1))
  if ! "$GODOT_BIN" --headless --path "$PROJECT_DIR" --check-only --script "$script" \
       >> "$PARSE_LOG" 2>&1; then
    echo "PARSE ERROR: $script" >> "$PARSE_LOG"
    PARSE_FAILED=$((PARSE_FAILED + 1))
  fi
done < <(find "$PROJECT_DIR" -name '*.gd' -not -path '*/.godot/*' -printf 'res://%P\n' | sort)
if [ $PARSE_FAILED -eq 0 ]; then
  ok "$PARSE_COUNT script(s) GDScript parsés sans erreur"
else
  bad "$PARSE_FAILED script(s) en erreur de parsing sur $PARSE_COUNT (voir $PARSE_LOG)"
  grep -E 'PARSE ERROR|Parse Error' "$PARSE_LOG" | head -10 | sed 's/^/    /'
fi
# Limite honnête (B4) : --check-only vérifie la SYNTAXE et le typage statique, pas
# la résolution des appels dynamiques. `n.methode_inexistante()` passe ce niveau et
# ne plantera qu'à l'exécution. Ce niveau ne remplace donc pas des tests.

step "2. Tests unitaires"
UNIT_LOG="$LOG_DIR/02_unit.log"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --script tools/godot/test_runner.gd > "$UNIT_LOG" 2>&1
UNIT_RC=$?
grep -E '^\s+(ok|ÉCHEC)|^=== RÉSULTAT' "$UNIT_LOG" | sed 's/^/  /'
if [ $UNIT_RC -eq 0 ]; then ok "suite unitaire verte"; else bad "suite unitaire rouge (code $UNIT_RC, voir $UNIT_LOG)"; fi

# Une erreur d'exécution GDScript (déréférencement nul, index hors bornes, format
# invalide) n'interrompt pas l'appel : le test serait compté « ok » et le runner
# sortirait 0. Le journal doit donc être inspecté séparément.
#
# N1 : la première version de ce filtre énumérait des messages précis et laissait
# passer tout `ERROR:` générique — ressource manquante, échec de chargement,
# `push_error` d'un invariant violé. Un asset supprimé laissait la suite verte.
# Le filtre couvre donc maintenant `ERROR:` comme le niveau 3.
UNIT_ERR_PATTERN='SCRIPT ERROR|^ERROR:|ASSERTION ÉCHOUÉE SANS REPORTER|Cannot call method|Invalid access|String formatting error|Out of bounds|Method not found|Cannot open file|Failed loading resource|Resource file not found'
if grep -qE "$UNIT_ERR_PATTERN" "$UNIT_LOG"; then
  bad "erreurs signalées pendant la suite de tests (voir $UNIT_LOG)"
  grep -E "$UNIT_ERR_PATTERN" "$UNIT_LOG" | head -10 | sed 's/^/    /'
else
  ok "aucune erreur signalée dans le journal des tests"
fi

step "3. Scène d'intégration (lancement réel : Boot -> MainMenu)"
SCENE_LOG="$LOG_DIR/03_scene.log"
# Assez de frames pour que la transition de SceneFlow aboutisse réellement : le
# but de ce niveau est d'exercer le chemin de démarrage complet, pas seulement de
# constater que la première scène se charge.
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --quit-after 90 > "$SCENE_LOG" 2>&1
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

# Le démarrage doit réellement atteindre le menu. Sans ce contrôle, une
# transition cassée passerait inaperçue tant que Boot lui-même se charge.
if grep -q 'transition vers le menu principal' "$SCENE_LOG"; then
  ok "Boot atteint le menu principal"
else
  bad "Boot n'a pas enchaîné sur le menu principal (voir $SCENE_LOG)"
fi

step "3b. Continuité des personnages livrés (ISS-019)"
# ISS-018 : les créatures s'affichaient en pièces détachées alors que TOUS les
# tests étaient verts, parce qu'ils mesuraient des boîtes englobantes — et
# qu'une boîte englobante de maillage SKINNÉ décrit la pose de liaison, pas ce
# que le moteur dessine. Aucun assemblage n'était donc jamais vérifié.
#
# Ce niveau lit la géométrie du .glb LIVRÉ après évaluation du graphe de
# dépendances, donc APRÈS déformation par l'armature, et exige que chaque
# personnage forme UN SEUL corps solidaire. Il tourne en quelques secondes.
CONT_LOG="$LOG_DIR/03b_continuity.log"
: > "$CONT_LOG"
BLENDER_BIN="${BLENDER_BIN:-blender}"
if ! command -v "$BLENDER_BIN" >/dev/null 2>&1; then
  bad "Blender absent — la continuité des personnages n'est PAS vérifiée"
else
  CONT_FAILED=0
  CONT_COUNT=0
  while IFS='|' read -r label glb; do
    [ -f "$glb" ] || { bad "modèle absent : $glb"; continue; }
    CONT_COUNT=$((CONT_COUNT + 1))
    if ! "$BLENDER_BIN" --background --python tools/blender/check_continuity.py -- \
         --glb "$glb" --label "$label" >> "$CONT_LOG" 2>&1; then
      CONT_FAILED=$((CONT_FAILED + 1))
    fi
  done <<'MODELS'
colosse|assets/characters/creatures/SK_RavineTroll.glb
chasseur|assets/characters/creatures/SK_CentaurHunter.glb
gardien|assets/characters/boss/SK_StormGuardian.glb
raider_red|assets/characters/enemies/SK_RaiderRed.glb
raider_blue|assets/characters/enemies/SK_RaiderBlue.glb
raider_black|assets/characters/enemies/SK_RaiderBlack.glb
MODELS
  grep -E '^\[continuité\] .* : (UN SEUL|[0-9]+ (PIÈCE|GRAPPE))' "$CONT_LOG" \
    | sed 's/^/    /'
  if [ $CONT_FAILED -eq 0 ]; then
    ok "$CONT_COUNT personnage(s) : un seul corps solidaire, aucune pièce détachée"
  else
    bad "$CONT_FAILED personnage(s) en pièces détachées sur $CONT_COUNT (voir $CONT_LOG)"
  fi
fi

step "4. Plancher de couverture"
# B1 : renommer un fichier de test faisait disparaître 3 tests sans que rien ne
# rougisse. Le nombre de tests attendu est donc épinglé ; le baisser exige une
# modification explicite de ce fichier, visible en revue.
# Q3 (4e revue) : `head -1` prenait la PREMIÈRE ligne « === RÉSULTAT », qu'un test
# pouvait imprimer lui-même pour annoncer 99 réussites alors que 9 tests tournaient.
# On prend la dernière (celle du runner) et on refuse toute ligne en double.
# Le plancher est une constante du fichier : l'abaisser doit se voir en revue, il
# n'est donc pas surchargeable par l'environnement.
MIN_TESTS=586
RESULT_LINES=$(grep -cE '^=== RÉSULTAT: [0-9]+ réussi' "$UNIT_LOG")
ACTUAL_TESTS=$(grep -oE '^=== RÉSULTAT: [0-9]+ réussi' "$UNIT_LOG" | grep -oE '[0-9]+' | tail -1)
ACTUAL_TESTS="${ACTUAL_TESTS:-0}"
if [ "$RESULT_LINES" -gt 1 ]; then
  bad "$RESULT_LINES lignes « === RÉSULTAT » dans le journal — un test imprime-t-il un faux résumé ?"
elif [ "$ACTUAL_TESTS" -ge "$MIN_TESTS" ]; then
  ok "$ACTUAL_TESTS test(s) exécuté(s), plancher $MIN_TESTS respecté"
else
  bad "$ACTUAL_TESTS test(s) exécuté(s) pour un plancher de $MIN_TESTS — couverture perdue en silence ?"
fi

printf '\n=== VALIDATE_FAST : %s ===\n' "$([ $FAIL -eq 0 ] && echo VERT || echo ROUGE)"
echo "logs: $LOG_DIR"
exit $FAIL
