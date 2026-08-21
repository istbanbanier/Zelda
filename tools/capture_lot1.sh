#!/usr/bin/env bash
# CHAÎNE DE PREUVE du lot 1 (V2.3-B) — du plan de caméras au verdict D3.
#
# POURQUOI UN SEUL SCRIPT. Sept commandes enchaînées à la main, ce sont sept
# occasions de changer une taille, un renderer ou un nombre de frames sans s'en
# apercevoir, et une comparaison avant/après qui ne prouve plus rien. Ici les
# réglages sont écrits une fois ; ce qui change entre deux passes, c'est le
# code, pas la mesure.
#
# Ce qu'il produit, dans l'ordre :
#   1. le PLAN de caméras, DÉRIVÉ du layout et de l'emprise réelle des lieux
#      (`plan_captures_lot1.gd`) — jamais tapé à la main ;
#   2. trois vues par sujet, dont la VUE JOUEUR aux valeurs réelles du jeu ;
#   3. trois silhouettes en aplat noir par sujet ;
#   4. le VERDICT D3 (`lot1_repetition.py`), que le filet
#      `test_world_v2_lot1_defauts.gd` exige : verdict absent ⇒ suite rouge ;
#   5. la CARTE du lot ;
#   6. la PLANCHE de miniatures.
#
# ARBRE SALE : refusé par défaut. Une capture prise d'un arbre sale ne se
# rattache à aucun commit et ne vaut pas comme preuve
# (`.claude/rules/evidence.md`). Le manifeste doit porter `repo_dirty: false`.
# `--allow-dirty` existe pour itérer ; ses images ne sont PAS des preuves.
#
# Usage :
#   tools/capture_lot1.sh --out-dir=evidence/world_v2/v2_3_b/lot1 [--allow-dirty]
#
# Codes : 0 = tout est passé · 1 = au moins une étape a échoué
#         2 = usage · 3 = BLOQUÉ (moteur absent, arbre sale)
set -uo pipefail

cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"
SCENE="res://scenes/world_v2/WorldV2.tscn"

# ISS-063 — verrou canonique + cloison `user://`. Un correctif qui ne vit que
# dans `lancer_godot.sh` ne protège que ceux qui appellent le lanceur.
# shellcheck source=lib/godot_env.sh
. "$PWD/tools/lib/godot_env.sh"
godot_cloison_arbre || exit 3
godot_verrou_prendre 8 3000 || exit 3

OUT_DIR="evidence/world_v2/v2_3_b/lot1"
SIZE="1600x900"
ALLOW_DIRTY=0
for arg in "$@"; do
  case "$arg" in
    --out-dir=*) OUT_DIR="${arg#*=}" ;;
    --size=*)    SIZE="${arg#*=}" ;;
    --allow-dirty) ALLOW_DIRTY=1 ;;
    -h|--help)   sed -n '2,29p' "$0"; exit 0 ;;
    *) echo "argument inconnu : $arg" >&2; exit 2 ;;
  esac
done

command -v "$GODOT_BIN" >/dev/null 2>&1 || {
  echo "BLOQUÉ: moteur absent ($GODOT_BIN) — tools/setup_godot.sh" >&2; exit 3; }
if [ "$ALLOW_DIRTY" -eq 0 ] && \
   [ -n "$(git status --porcelain --untracked-files=no -- . ':!evidence' 2>/dev/null)" ]; then
  echo "BLOQUÉ: arbre de travail sale — commiter AVANT de capturer." >&2
  echo "        (.claude/rules/evidence.md ; --allow-dirty pour itérer sans preuve)" >&2
  exit 3
fi

PLANS="$OUT_DIR/plans"
VUES="$OUT_DIR/vues"
SILHOUETTES="$OUT_DIR/silhouettes"
CONTROLES="$OUT_DIR/controles"
mkdir -p "$PLANS" "$VUES" "$SILHOUETTES" "$CONTROLES"
FAILED=0

echo "=== 1/6 — plan de caméras dérivé du layout ==="
"$GODOT_BIN" --headless --path . \
  --script tools/godot/plan_captures_lot1.gd -- "--out-dir=$PLANS" \
  > "$PLANS/plan.log" 2>&1
if [ $? -ne 0 ] || [ ! -s "$PLANS/lot1_shots.json" ]; then
  echo "  [ÉCHEC] plan non produit — voir $PLANS/plan.log"
  # Sans plan, tout le reste capturerait des cadrages inventés : on s'arrête.
  exit 1
fi
echo "  [OK]    $PLANS/lot1_shots.json"

echo "=== 2/6 — vues (3 par sujet, dont la vue joueur) ==="
# Xvfb + llvmpipe : le conteneur n'a pas de GPU. Utilisable pour la régression
# VISUELLE, jamais pour une mesure de performance (limites de CLAUDE.md).
xvfb-run -a --server-args="-screen 0 ${SIZE}x24" \
  "$GODOT_BIN" --path . --rendering-driver opengl3 \
  --script tools/godot/capture_poi_batch.gd -- \
  "--scene=$SCENE" "--shots=$PLANS/lot1_shots.json" "--out-dir=$VUES" \
  "--size=$SIZE" \
  "--provenance=lieux:scripts/world_v2/poi,layout:resources/world_v2/world_v2_layout.json" \
  > "$VUES/capture.log" 2>&1 || { echo "  [ÉCHEC] voir $VUES/capture.log"; FAILED=1; }
echo "  $(ls -1 "$VUES"/*.png 2>/dev/null | wc -l) vue(s) écrite(s)"

echo "=== 3/6 — silhouettes en aplat noir (3 angles par sujet) ==="
while IFS='|' read -r place nom angles taille; do
  [ -n "$place" ] || continue
  xvfb-run -a --server-args="-screen 0 1000x1400x24" \
    "$GODOT_BIN" --path . --rendering-driver opengl3 \
    --script tools/godot/capture_silhouette.gd -- \
    "--scene=$SCENE" "--place=$place" "--name=$nom" \
    "--out-dir=$SILHOUETTES" "--angles=$angles" "--size=$taille" \
    "--provenance=lieux:scripts/world_v2/poi" \
    >> "$SILHOUETTES/capture.log" 2>&1
  if [ $? -ne 0 ]; then
    echo "  [ÉCHEC] silhouette $nom — voir $SILHOUETTES/capture.log"
    FAILED=1
  else
    echo "  [OK]    $nom"
  fi
done < <(python3 - "$PLANS/lot1_silhouettes.json" <<'PY'
import json, sys
for e in json.load(open(sys.argv[1], encoding="utf-8")):
    print("|".join([e["place_id"], e["nom"], e["angles"], e["taille"]]))
PY
)

echo "=== 4/6 — silhouettes du corpus ACCEPTÉ (la calibration R-D3) ==="
# Sans elles, le détecteur n'a pas de corpus, et son seuil ne peut pas être
# dérivé de sujets déjà validés : il rendrait BLOQUÉ (garde-fou R-D3c).
for entry in \
  "camp|camp" \
  "valley.poi.riverside_village.01|hameau" \
  "valley.poi.abandoned_farm.01|ferme" \
  "valley.poi.stone_bridge.01|pont" \
  "valley.poi.waterfall_cave.01|grotte" \
  "valley.poi.thunderstruck_tree.01|arbre" \
  "valley.poi.ember_raider_camps.01|braise" \
  "valley.poi.conductive_basin.01|bassin" \
  "pylon|pylone" ; do
  place="${entry%%|*}"; nom="${entry#*|}"
  xvfb-run -a --server-args="-screen 0 1000x1400x24" \
    "$GODOT_BIN" --path . --rendering-driver opengl3 \
    --script tools/godot/capture_silhouette.gd -- \
    "--scene=$SCENE" "--place=$place" "--name=$nom" \
    "--out-dir=$SILHOUETTES" "--angles=0,90,180" "--size=900x1200" \
    >> "$SILHOUETTES/capture.log" 2>&1 \
    && echo "  [OK]    $nom (corpus)" \
    || { echo "  [ÉCHEC] $nom (corpus)"; FAILED=1; }
done

echo "=== 5/6 — VERDICT D3 (règle R-D3, pré-enregistrée) ==="
python3 tools/lot1_repetition.py --manifestes "$SILHOUETTES" \
  --out "$CONTROLES/verdict_repetition.json" \
  | tee "$CONTROLES/repetition.log"
RC_D3=${PIPESTATUS[0]}
case "$RC_D3" in
  0) echo "  [PASS]   aucune paire signalée" ;;
  1) echo "  [FAIL]   au moins une paire dépasse le seuil calibré"; FAILED=1 ;;
  *) echo "  [BLOQUÉ] calibration ou corpus insuffisant"; FAILED=1 ;;
esac

echo "=== 6/6 — carte du lot et planche de miniatures ==="
xvfb-run -a --server-args="-screen 0 1400x1400x24" \
  "$GODOT_BIN" --path . --rendering-driver opengl3 \
  --script tools/godot/render_world_v2_maps.gd -- \
  "--out-dir=$OUT_DIR" "--label=v2_3_b_lot1" \
  > "$OUT_DIR/carte.log" 2>&1 \
  && echo "  [OK]    carte" || { echo "  [ÉCHEC] voir $OUT_DIR/carte.log"; FAILED=1; }

SOURCES="$(ls -1 "$VUES"/*.png 2>/dev/null | grep -v '_gris\.png$' \
  | grep -v '_vignette\.png$' | paste -sd, -)"
if [ -n "$SOURCES" ]; then
  xvfb-run -a --server-args="-screen 0 1600x1200x24" \
    "$GODOT_BIN" --path . --rendering-driver opengl3 \
    --script tools/godot/compose_contact_sheet.gd -- \
    "--sources=$SOURCES" "--out=$OUT_DIR/planche_miniatures_lot1.png" \
    "--columns=3" > "$OUT_DIR/planche.log" 2>&1 \
    && echo "  [OK]    planche" || { echo "  [ÉCHEC] voir $OUT_DIR/planche.log"; FAILED=1; }
else
  echo "  [ÉCHEC] aucune vue à monter en planche"
  FAILED=1
fi

echo
if [ "$FAILED" -ne 0 ]; then
  echo "=== CHAÎNE DE PREUVE INCOMPLÈTE — ne pas présenter ces images comme un lot prouvé ==="
  exit 1
fi
echo "=== CHAÎNE DE PREUVE COMPLÈTE — $OUT_DIR ==="
exit 0
