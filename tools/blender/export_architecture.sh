#!/usr/bin/env bash
# Chaîne contrôlée des HERO ASSETS d'architecture : source Python -> .blend
# -> .glb -> inspection hors moteur. Une commande, un verdict.
#
# POURQUOI CE SCRIPT EXISTE. Le pylône de R2a-4 a été généré et exporté à la
# main, invocation par invocation. Ça a marché, et ça ne prouve rien : la
# séquence n'était écrite nulle part, et la passe suivante — pont, grotte,
# hameau — l'aurait retapée de mémoire. Le lead demande de « rejouer
# l'export contrôlé » ; il faut donc qu'il existe quelque chose à rejouer.
#
# LES DEUX GARDE-FOUS SONT REPRIS DE `run_export.sh`, et ils ne sont pas
# décoratifs (mesuré le 2026-08-14) :
#   * `--python-exit-code 1` — sans lui, `blender --background` rend 0 même
#     quand le script Python lève. La chaîne se déclarait VERTE sans avoir
#     rien exporté, tant que numpy manquait.
#   * jeton de fraîcheur — un `.glb` intact n'est pas un `.glb` produit.
#     Sans cette comparaison de mtime, l'étape d'inspection revalide le
#     fichier DÉJÀ versionné et annonce un succès qui appartient à hier.
#
# Usage :
#   tools/blender/export_architecture.sh              # tous les sujets
#   tools/blender/export_architecture.sh pylon        # un seul
set -uo pipefail

cd "$(dirname "$0")/../.."
BLENDER="${BLENDER_BIN:-blender}"
LOG_DIR="${LOG_DIR:-evidence/pipeline}"
mkdir -p "$LOG_DIR"

command -v "$BLENDER" >/dev/null 2>&1 || { echo "ÉCHEC: Blender absent" >&2; exit 2; }

# id | source de génération | .blend | .glb
SUJETS=(
  "pylon|source_assets/blender/architecture/make_pylon_resonance.py|source_assets/blender/architecture/SM_Pylon_Resonance.blend|assets/architecture/pylon/SM_Pylon_Resonance.glb"
  "stone_bridge|source_assets/blender/architecture/make_stone_bridge.py|source_assets/blender/architecture/SM_StoneBridge_Arch.blend|assets/architecture/stone_bridge/SM_StoneBridge_Arch.glb"
  "waterfall_cave|source_assets/blender/environment/make_waterfall_cave.py|source_assets/blender/environment/SM_WaterfallCave.blend|assets/environment/caves/SM_WaterfallCave.glb"
)

DEMANDE="${1:-}"
FAIL=0
echo "=== Blender: $("$BLENDER" --version 2>/dev/null | head -1) ==="

JETON="$LOG_DIR/.jeton_architecture"
: > "$JETON"

for ligne in "${SUJETS[@]}"; do
  IFS='|' read -r ID SRC BLEND GLB <<< "$ligne"
  [ -n "$DEMANDE" ] && [ "$DEMANDE" != "$ID" ] && continue

  echo
  echo "--- $ID : génération de la source ---"
  "$BLENDER" --background --python-exit-code 1 --python "$SRC" \
    > "$LOG_DIR/architecture_${ID}_make.log" 2>&1 || FAIL=1
  grep "^\[$ID\]" "$LOG_DIR/architecture_${ID}_make.log" | sed 's/^/  /'
  if [ $FAIL -ne 0 ]; then
    echo "  ÉCHEC: la génération a rendu non-zéro — voir $LOG_DIR/architecture_${ID}_make.log" >&2
    tail -12 "$LOG_DIR/architecture_${ID}_make.log" | sed 's/^/  | /' >&2
    continue
  fi

  echo "--- $ID : export .glb ---"
  mkdir -p "$(dirname "$GLB")"
  "$BLENDER" --background --python-exit-code 1 "$BLEND" \
    --python tools/blender/export_gltf.py -- --out "$GLB" \
    > "$LOG_DIR/architecture_${ID}_export.log" 2>&1 || FAIL=1
  grep '^\[export_gltf\]' "$LOG_DIR/architecture_${ID}_export.log" | sed 's/^/  /'

  if [ ! -f "$GLB" ]; then
    echo "  ÉCHEC: $GLB absent" >&2; FAIL=1; continue
  fi
  if [ "$GLB" -ot "$JETON" ]; then
    echo "  ÉCHEC: $GLB n'a PAS été réécrit (plus ancien que le jeton)." >&2
    FAIL=1; continue
  fi
  echo "  frais: $GLB ($(stat -c%s "$GLB") octets)"

  echo "--- $ID : inspection glTF hors moteur ---"
  python3 tools/gltf_inspect.py "$GLB" \
    | tee "$LOG_DIR/architecture_${ID}_inspect.log" | sed 's/^/  /' || FAIL=1
done

printf '\n=== EXPORT ARCHITECTURE : %s ===\n' "$([ $FAIL -eq 0 ] && echo VERT || echo ROUGE)"
exit $FAIL
