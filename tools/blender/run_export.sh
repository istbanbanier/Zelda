#!/usr/bin/env bash
# Chaîne complète Blender -> .glb -> validation, exécutable d'une commande.
# Prouve la moitié « source » du pipeline d'assets (MASTER_SPEC §7.15).
set -uo pipefail

cd "$(dirname "$0")/../.."
BLENDER="${BLENDER_BIN:-blender}"
LOG_DIR="${LOG_DIR:-evidence/pipeline}"
mkdir -p "$LOG_DIR" assets/environment/props assets/characters/hero

command -v "$BLENDER" >/dev/null 2>&1 || { echo "ÉCHEC: Blender absent" >&2; exit 2; }

FAIL=0
echo "=== Blender: $("$BLENDER" --version 2>/dev/null | head -1) ==="

echo
echo "--- 1. Génération des sources de test ---"
"$BLENDER" --background --python tools/blender/make_test_assets.py \
  > "$LOG_DIR/blender_make.log" 2>&1 || FAIL=1
grep '^\[make_test_assets\]' "$LOG_DIR/blender_make.log" | sed 's/^/  /'

echo
echo "--- 2. Export .glb ---"
"$BLENDER" --background source_assets/blender/props/SM_TestCube.blend \
  --python tools/blender/export_gltf.py -- \
  --out assets/environment/props/SM_TestCube.glb \
  > "$LOG_DIR/blender_export_cube.log" 2>&1 || FAIL=1
grep '^\[export_gltf\]' "$LOG_DIR/blender_export_cube.log" | sed 's/^/  /'

"$BLENDER" --background source_assets/blender/props/SK_TestRigAnim.blend \
  --python tools/blender/export_gltf.py -- \
  --out assets/characters/hero/SK_TestRigAnim.glb --animations \
  > "$LOG_DIR/blender_export_rig.log" 2>&1 || FAIL=1
grep '^\[export_gltf\]' "$LOG_DIR/blender_export_rig.log" | sed 's/^/  /'

echo
echo "--- 3. Validation glTF hors moteur ---"
python3 tools/gltf_inspect.py assets/environment/props/SM_TestCube.glb \
  | tee "$LOG_DIR/inspect_cube.log" | sed 's/^/  /' || FAIL=1
python3 tools/gltf_inspect.py assets/characters/hero/SK_TestRigAnim.glb \
  --expect-anim --expect-skin \
  | tee "$LOG_DIR/inspect_rig.log" | sed 's/^/  /' || FAIL=1

printf '\n=== PIPELINE BLENDER->glTF : %s ===\n' "$([ $FAIL -eq 0 ] && echo VERT || echo ROUGE)"
exit $FAIL
