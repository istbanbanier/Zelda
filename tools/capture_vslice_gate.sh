#!/usr/bin/env bash
# Capture les SIX caméras de gate de la tranche d'ouverture, en une passe.
#
# POURQUOI CE FICHIER. Le gate de la tranche verticale se juge sur six vues, et
# la seule règle qui rende une comparaison honnête est « exactement la même
# caméra, exactement les mêmes réglages, seul le code a changé ». Lancer six
# fois `capture_reference.gd` à la main, c'est six occasions de changer une
# taille, un nombre de frames ou un renderer sans s'en apercevoir — et une
# comparaison avant/après qui ne prouve plus rien.
#
# Les six caméras sont déclarées CÔTÉ JEU (`ValleyWorld.GATE_CAMERA_NAMES`) et
# choisies par `VALLEY_GATE=1..6`. Ce script ne connaît que leur numéro : il ne
# peut pas inventer un cadrage.
#
# Usage :
#   tools/capture_vslice_gate.sh --out-dir=evidence/vertical_slice_20260811/avant \
#       [--size=1920x1080] [--frames=40] [--only=1,4] [--allow-dirty]
#
# Chaque sortie porte son manifeste JSON (commit, moteur, renderer, taille,
# frames) écrit par `capture_reference.gd`, puis son paquet de revue (vignette
# 320x180, niveaux de gris, mesures) écrit par `make_review_pack.py`.
#
# ARBRE SALE : refusé par défaut. `.claude/rules/evidence.md` — une capture
# prise d'un arbre sale ne se rattache à aucun commit et ne vaut pas comme
# preuve. `--allow-dirty` existe pour l'itération de travail ; les images
# qu'il produit ne sont pas des preuves de lot.
#
# Codes retour : 0 les six ont été rendues · 1 au moins une a échoué ·
# 2 usage · 3 BLOQUÉ (arbre sale, ou moteur absent).
set -uo pipefail

cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"
SCENE="res://scenes/world/valley/ValleyWorld.tscn"

OUT_DIR=""
SIZE="1920x1080"
FRAMES="40"
ONLY=""
ALLOW_DIRTY=0

for arg in "$@"; do
  case "$arg" in
    --out-dir=*) OUT_DIR="${arg#*=}" ;;
    --size=*)    SIZE="${arg#*=}" ;;
    --frames=*)  FRAMES="${arg#*=}" ;;
    --only=*)    ONLY="${arg#*=}" ;;
    --allow-dirty) ALLOW_DIRTY=1 ;;
    -h|--help)   sed -n '2,26p' "$0"; exit 0 ;;
    *) echo "argument inconnu : $arg" >&2; exit 2 ;;
  esac
done

[ -n "$OUT_DIR" ] || { echo "ERREUR: --out-dir est obligatoire" >&2; exit 2; }
command -v "$GODOT_BIN" >/dev/null 2>&1 || {
  echo "BLOQUÉ: moteur absent ($GODOT_BIN) — tools/setup_godot.sh" >&2; exit 3; }

if [ "$ALLOW_DIRTY" -eq 0 ] && \
   [ -n "$(git status --porcelain --untracked-files=no -- . ':!evidence' 2>/dev/null)" ]; then
  echo "BLOQUÉ: arbre de travail sale — commiter le code AVANT de capturer." >&2
  echo "        (.claude/rules/evidence.md ; --allow-dirty pour itérer sans preuve)" >&2
  exit 3
fi

# Les six, dans l'ordre du parcours joué. Le libellé sert de nom de fichier et
# de `--label` : une preuve doit se lire sans ouvrir le manifeste.
LABELS=(
  "1:01_crete_vista"
  "2:02_descente"
  "3:03_camp"
  "4:04_gue"
  "5:05_route_nord"
  "6:06_approche_citadelle"
)

mkdir -p "$OUT_DIR"
FAILED=0
RENDERED=0

for entry in "${LABELS[@]}"; do
  index="${entry%%:*}"
  label="${entry#*:}"
  if [ -n "$ONLY" ] && [[ ",$ONLY," != *",$index,"* ]]; then
    continue
  fi
  png="$OUT_DIR/$label.png"
  echo "=== gate $index — $label ==="
  # Xvfb + llvmpipe : le conteneur n'a pas de GPU. C'est utilisable pour la
  # régression VISUELLE, jamais pour une mesure de performance (§ limites
  # connues de CLAUDE.md).
  VALLEY_GATE="$index" xvfb-run -a --server-args="-screen 0 ${SIZE/x/x}x24" \
    "$GODOT_BIN" --path . --rendering-driver opengl3 \
    --script tools/godot/capture_reference.gd -- \
    "--scene=$SCENE" "--out=$png" "--size=$SIZE" "--frames=$FRAMES" \
    "--label=vslice_$label" > "$OUT_DIR/$label.log" 2>&1
  rc=$?
  if [ "$rc" -ne 0 ] || [ ! -s "$png" ]; then
    echo "  [ÉCHEC] code $rc — voir $OUT_DIR/$label.log"
    FAILED=1
    continue
  fi
  RENDERED=$((RENDERED + 1))
  echo "  [OK]    $png"
done

if [ "$RENDERED" -gt 0 ]; then
  # Les dérivées vivent à côté des captures : sans ce filtre, une deuxième
  # passe fabrique le niveau de gris DU niveau de gris et mesure des images
  # qui n'ont jamais été rendues par le moteur.
  CAPTURES=()
  for png in "$OUT_DIR"/0*.png; do
    case "$png" in *_gris.png|*_vignette.png) continue ;; esac
    CAPTURES+=("$png")
  done
  echo
  echo "=== paquet de revue (vignette 320x180, niveaux de gris, mesures) ==="
  python3 tools/make_review_pack.py "${CAPTURES[@]}" || FAILED=1
  echo
  echo "=== hiérarchie des valeurs §1.5 (le sol ne peut pas être plus clair que le ciel) ==="
  for png in "${CAPTURES[@]}"; do
    python3 tools/check_value_bands.py "$png" > "${png%.png}_bandes.log" 2>&1
    rc=$?
    printf '  %-28s %s\n' "$(basename "$png")" \
      "$([ "$rc" -eq 0 ] && echo 'conforme' || echo "VIOLATION (code $rc)")"
  done
fi

exit "$FAILED"
