#!/usr/bin/env bash
# Chaîne complète Blender -> .glb -> validation, exécutable d'une commande.
# Prouve la moitié « source » du pipeline d'assets (MASTER_SPEC §7.15).
#
# --python-exit-code 1 N'EST PAS DÉCORATIF. Mesuré le 2026-08-14 :
#   blender --background <blend> --python export_gltf.py -- --out /proc/…
#     -> code retour 0, avec DEUX lignes de traceback dans le journal.
#   la même commande avec --python-exit-code 1
#     -> code retour 1.
# Sans lui, un export qui plante rend 0 ; l'étape 3 revalide alors les .glb
# DÉJÀ versionnés, et ce script annonce « VERT » sans avoir rien exporté.
# C'est exactement ce qui s'est passé tant que numpy manquait : l'exporteur
# glTF de Blender en dépend, il levait ModuleNotFoundError, et la chaîne
# se déclarait verte.
#
# Second garde-fou : l'étape 2 compare le mtime du .glb à un jeton posé
# avant l'export. Un fichier intact n'est pas un fichier produit.
set -uo pipefail

cd "$(dirname "$0")/../.."
BLENDER="${BLENDER_BIN:-blender}"
LOG_DIR="${LOG_DIR:-evidence/pipeline}"
mkdir -p "$LOG_DIR" assets/environment/props assets/characters/hero

command -v "$BLENDER" >/dev/null 2>&1 || { echo "ÉCHEC: Blender absent" >&2; exit 2; }

FAIL=0
echo "=== Blender: $("$BLENDER" --version 2>/dev/null | head -1) ==="

echo
echo "--- 1. Sources de test ---"
# Blender ne réécrit pas un .blend octet pour octet à l'identique : régénérer
# systématiquement salissait l'arbre git à chaque exécution. Les sources ne sont
# donc reconstruites que si elles manquent, ou sur demande explicite.
if [ "${REGEN_SOURCES:-0}" = "1" ] \
   || [ ! -f source_assets/blender/props/SM_TestCube.blend ] \
   || [ ! -f source_assets/blender/props/SK_TestRigAnim.blend ]; then
  "$BLENDER" --background --python-exit-code 1 --python tools/blender/make_test_assets.py \
    > "$LOG_DIR/blender_make.log" 2>&1 || FAIL=1
  grep '^\[make_test_assets\]' "$LOG_DIR/blender_make.log" | sed 's/^/  /'
else
  echo "  sources déjà présentes, régénération ignorée (REGEN_SOURCES=1 pour forcer)"
fi

echo
echo "--- 2. Export .glb ---"
# Jeton de fraîcheur : tout .glb attendu doit être PLUS RÉCENT que lui.
JETON="$LOG_DIR/.jeton_export"
: > "$JETON"

exige_frais() {
  # $1 = chemin du .glb attendu
  if [ ! -f "$1" ]; then
    echo "  ÉCHEC: $1 absent" >&2; FAIL=1; return
  fi
  if [ "$1" -ot "$JETON" ]; then
    echo "  ÉCHEC: $1 n'a PAS été réécrit (plus ancien que le jeton) —" >&2
    echo "         la chaîne aurait validé un fichier déjà versionné." >&2
    FAIL=1; return
  fi
  echo "  frais: $1 ($(stat -c%s "$1") octets)"
}
"$BLENDER" --background --python-exit-code 1 source_assets/blender/props/SM_TestCube.blend \
  --python tools/blender/export_gltf.py -- \
  --out assets/environment/props/SM_TestCube.glb \
  > "$LOG_DIR/blender_export_cube.log" 2>&1 || FAIL=1
grep '^\[export_gltf\]' "$LOG_DIR/blender_export_cube.log" | sed 's/^/  /'

"$BLENDER" --background --python-exit-code 1 source_assets/blender/props/SK_TestRigAnim.blend \
  --python tools/blender/export_gltf.py -- \
  --out assets/characters/hero/SK_TestRigAnim.glb --animations \
  > "$LOG_DIR/blender_export_rig.log" 2>&1 || FAIL=1
grep '^\[export_gltf\]' "$LOG_DIR/blender_export_rig.log" | sed 's/^/  /'

exige_frais assets/environment/props/SM_TestCube.glb
exige_frais assets/characters/hero/SK_TestRigAnim.glb

echo
echo "--- 3. Validation glTF hors moteur ---"
python3 tools/gltf_inspect.py assets/environment/props/SM_TestCube.glb \
  | tee "$LOG_DIR/inspect_cube.log" | sed 's/^/  /' || FAIL=1
python3 tools/gltf_inspect.py assets/characters/hero/SK_TestRigAnim.glb \
  --expect-anim --expect-skin \
  | tee "$LOG_DIR/inspect_rig.log" | sed 's/^/  /' || FAIL=1

printf '\n=== PIPELINE BLENDER->glTF : %s ===\n' "$([ $FAIL -eq 0 ] && echo VERT || echo ROUGE)"
exit $FAIL
