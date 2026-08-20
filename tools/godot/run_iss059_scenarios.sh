#!/usr/bin/env bash
# ISS-059 — pilote des scénarios d'instrumentation matériaux.
#
# PIÈGE (tools/CLAUDE.md) : `flock -w N` qui expire rend 1 SANS exécuter la
# commande. Le RC est donc testé après CHAQUE prise, et la boucle s'arrête au
# premier échec plutôt que d'imprimer l'en-tête suivant sur du vide.
set -u
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ETIQUETTE="${1:?usage: run_iss059_scenarios.sh <etiquette> [cycles]}"
CYCLES="${2:-3}"
OUT="evidence/world_v2/v2_3_r2b3/iss059"
mkdir -p "$PROJECT_DIR/$OUT/journaux"

for SC in temoin ferme arbre ferme_arbre monde; do
  echo "### scenario=$SC cycles=$CYCLES etiquette=$ETIQUETTE"
  LOG="$PROJECT_DIR/$OUT/journaux/${ETIQUETTE}_${SC}_c${CYCLES}.log"
  flock -w 3600 /tmp/godot.lock timeout 3000 "$GODOT_BIN" --headless \
    --path "$PROJECT_DIR" --script tools/godot/instrumente_materiaux.gd -- \
    "--scenario=$SC" "--cycles=$CYCLES" \
    "--sortie=res://$OUT/${ETIQUETTE}_${SC}_c${CYCLES}.json" > "$LOG" 2>&1
  RC=$?
  if [ "$RC" -ne 0 ]; then
    echo "BLOQUE: scenario=$SC RC=$RC — verrou non obtenu ou exécution échouée," >&2
    echo "        RIEN n'a été écrit pour ce scénario ni pour les suivants." >&2
    exit 3
  fi
  grep -E "^cycle |^état initial" "$LOG" | sed 's/^/    /'
  if grep -qE "leaked|still in use" "$LOG"; then
    echo "    SIGNATURE DE FUITE PRÉSENTE en fin de processus :"
    grep -E "leaked|still in use" "$LOG" | sed 's/^/      /'
  else
    echo "    (aucune ligne de fuite en fin de processus)"
  fi
done
echo "TOUS LES SCÉNARIOS OK"
