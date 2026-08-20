#!/usr/bin/env bash
# Chaine + mesures + filet Godot sous UNE SEULE prise du verrou partage.
# Chaque etape ecrit son propre RC dans le journal : un RC non teste est un
# resultat perdu qui ressemble a un resultat (tools/CLAUDE.md).
set -uo pipefail
WT=/home/user/wt_r2b3_a_debris
E="$WT/evidence/world_v2/v2_3_r2b3/debris"
S=/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad
GLB=assets/architecture/farm/SM_Farm_Ruins.glb
JOURNAL="$1"
LOCK="$(git -C "$WT" rev-parse --git-common-dir)/heavy_tools.lock"
export GODOT_BIN=/usr/local/bin/godot
: > "$JOURNAL"

flock -w 3600 "$LOCK" bash -s <<'EOF' >> "$JOURNAL" 2>&1
set -uo pipefail
WT=/home/user/wt_r2b3_a_debris
E="$WT/evidence/world_v2/v2_3_r2b3/debris"
S=/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad
GLB=assets/architecture/farm/SM_Farm_Ruins.glb
GODOT_BIN=/usr/local/bin/godot
cd "$WT" || exit 90

echo "########## 1. CHAINE CONTROLEE (sujet OBLIGATOIRE) ##########"
tools/blender/export_architecture.sh farm_ruins > "$E/20_chaine_export.log" 2>&1
echo "RC_chaine=$?"
grep -E "gravats |total [0-9]|EXPORT ARCH|VALIDE|frais:" "$E/20_chaine_export.log"

echo; echo "########## 2. sha256 du GLB produit ##########"
sha256sum "$GLB"

echo; echo "########## 3. INSTRUMENT (noms COMPLETS) ##########"
python3 tools/mesure_boititude.py "$GLB" > "$E/21_instrument_vert.log" 2>&1
echo "RC_mesure=$?"
python3 tools/mesure_boititude.py "$GLB" \
    --mesh SM_Farm_Debris_A --mesh SM_Farm_Debris_B --plafond 25 \
    >> "$E/21_instrument_vert.log" 2>&1
echo "RC_plafond=$?"
tail -12 "$E/21_instrument_vert.log"

echo; echo "########## 4. gltf_inspect ##########"
python3 tools/gltf_inspect.py "$GLB" > "$E/22_gltf_inspect.log" 2>&1
echo "RC_inspect=$?"
grep -E "triangles|materiaux|VALIDE|AVERT|warn" "$E/22_gltf_inspect.log"

echo; echo "########## 4b. PREUVE DE PIPELINE VERSIONNEE — SEULEMENT LA FERME ##########"
# `test_world_v2_r2b_farm_tree.gd::test_le_pipeline_blender_est_frais_et_verifie`
# compare la taille inspectee du journal VERSIONNE au GLB du depot. Regenerer
# le GLB PERIME donc cette preuve : le filet a raison, le journal datait.
# On ne recopie QUE les trois journaux `farm_ruins` ; ceux de l'arbre
# appartiennent a un autre agent et ne sont pas touches.
PIPE="$WT/evidence/world_v2/v2_3_r2b/ferme_arbre/pipeline"
for f in make export inspect; do
  cp "evidence/pipeline/architecture_farm_ruins_${f}.log" \
     "$PIPE/architecture_farm_ruins_${f}.log" || echo "ECHEC copie $f"
done
cp "$E/20_chaine_export.log" "$PIPE/chaine_farm_ruins_VERT.log"
grep -m1 "octets" "$PIPE/architecture_farm_ruins_inspect.log"
ls -1 "$PIPE" | sed 's/^/  /'

echo; echo "########## 5. NON-CONTAMINATION ##########"
python3 "$E/empreinte_glb.py" "$GLB" --json > "$S/empreinte_apres.json" 2>&1
python3 "$E/non_contamination.py" "$S/empreinte_avant.json" \
    "$S/empreinte_apres.json" > "$E/23_non_contamination.log" 2>&1
echo "RC_contamination=$?"
tail -4 "$E/23_non_contamination.log"

echo; echo "########## 6. IMPORT GODOT (obligatoire apres regeneration) ##########"
"$GODOT_BIN" --headless --path . --import > "$S/import.log" 2>&1
echo "RC_import=$?"

echo; echo "########## 7. FILET GODOT ##########"
timeout 1200 "$GODOT_BIN" --headless --path . \
    --script tools/godot/test_runner.gd -- --filter=r2b3_debris \
    > "$E/24_test_vert.log" 2>&1
echo "RC_test=$?"
grep -E "r2b3_debris\]|=== RÉSULTAT|ÉCHEC:" "$E/24_test_vert.log"
EOF
RC=$?
echo "RC=$RC" >> "$JOURNAL"
echo "RC=$RC"
