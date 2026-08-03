#!/usr/bin/env bash
# Reconstruit un personnage : source Blender -> .glb -> contrôle de CONTINUITÉ.
#
# La boucle de réparation d'ISS-018 a besoin d'être courte. Sans ce script,
# chaque essai demandait quatre commandes recopiées à la main, et l'oubli de
# l'une d'elles faisait contrôler un .glb périmé — c'est-à-dire mesurer le
# défaut d'avant la correction.
#
# Usage :
#   tools/blender/rebuild_characters.sh troll|hunter|creatures|guardian|raiders|all
set -uo pipefail

cd "$(dirname "$0")/../.."
BLENDER="${BLENDER_BIN:-blender}"
LOG_DIR="${LOG_DIR:-evidence/pipeline}"
GAP="${GAP:-0.02}"
mkdir -p "$LOG_DIR"

FAIL=0

# make <script> : régénère les sources .blend
make_sources() {
  local script="$1" name="$2"
  echo "--- source : $name"
  "$BLENDER" --background --python "tools/blender/$script" \
    > "$LOG_DIR/make_$name.log" 2>&1 || FAIL=1
  grep -E '^\[make_' "$LOG_DIR/make_$name.log" | sed 's/^/    /'
}

# ship <blend> <glb> : exporte puis contrôle la continuité du LIVRABLE
ship() {
  local blend="$1" glb="$2" label="$3"
  echo "--- export : $label"
  "$BLENDER" --background "$blend" --python tools/blender/export_gltf.py -- \
    --out "$glb" > "$LOG_DIR/export_$label.log" 2>&1 || FAIL=1
  grep -E '^\[export_gltf\]' "$LOG_DIR/export_$label.log" | sed 's/^/    /'
  python3 tools/gltf_inspect.py "$glb" --expect-skin \
    > "$LOG_DIR/inspect_$label.log" 2>&1 || FAIL=1
  tail -1 "$LOG_DIR/inspect_$label.log" | sed 's/^/    /'
  "$BLENDER" --background --python tools/blender/check_continuity.py -- \
    --glb "$glb" --label "$label" --gap "$GAP" --report "${REPORT:-0}" \
    > "$LOG_DIR/continuity_$label.log" 2>&1 || FAIL=1
  grep -E '^\[continuité\]' "$LOG_DIR/continuity_$label.log" | sed 's/^/    /'
}

case "${1:-all}" in
  troll|hunter|creatures)
    make_sources make_creatures.py creatures
    ship source_assets/blender/creatures/SK_RavineTroll.blend \
         assets/characters/creatures/SK_RavineTroll.glb colosse
    ship source_assets/blender/creatures/SK_CentaurHunter.blend \
         assets/characters/creatures/SK_CentaurHunter.glb chasseur
    ;;
  guardian)
    make_sources make_storm_guardian.py storm_guardian
    ship source_assets/blender/creatures/SK_StormGuardian.blend \
         assets/characters/boss/SK_StormGuardian.glb gardien
    ;;
  raiders)
    make_sources make_raiders.py raiders
    for family in Red Blue Black; do
      ship "source_assets/blender/characters/SK_Raider$family.blend" \
           "assets/characters/enemies/SK_Raider$family.glb" \
           "raider_$(echo "$family" | tr 'A-Z' 'a-z')"
    done
    ;;
  all)
    "$0" creatures
    "$0" guardian
    "$0" raiders
    ;;
  *)
    echo "cible inconnue : $1" >&2
    exit 2
    ;;
esac

printf '\n=== RECONSTRUCTION : %s ===\n' \
  "$([ $FAIL -eq 0 ] && echo VERTE || echo ROUGE)"
exit $FAIL
