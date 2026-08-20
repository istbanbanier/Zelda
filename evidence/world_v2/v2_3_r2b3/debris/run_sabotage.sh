#!/usr/bin/env bash
# CONTROLE NEGATIF puis RESTAURATION, sous UNE seule prise du verrou partage.
# Le sabotage doit retirer LA CHOSE TESTEE, pas ce qui est en dessous : les
# eclats redeviennent des BOITES DROITES et le garde du generateur est
# neutralise, sinon le .blend ne serait pas reecrit et le filet resterait vert
# sur l'ancienne geometrie — un vert qui ne prouverait rien.
set -uo pipefail
WT=/home/user/wt_r2b3_a_debris
E="$WT/evidence/world_v2/v2_3_r2b3/debris"
S=/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad
JOURNAL="$1"
LOCK="$(git -C "$WT" rev-parse --git-common-dir)/heavy_tools.lock"
: > "$JOURNAL"

flock -w 3600 "$LOCK" bash -s <<'EOF' >> "$JOURNAL" 2>&1
set -uo pipefail
WT=/home/user/wt_r2b3_a_debris
E="$WT/evidence/world_v2/v2_3_r2b3/debris"
S=/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad
GLB=assets/architecture/farm/SM_Farm_Ruins.glb
GODOT_BIN=/usr/local/bin/godot
cd "$WT" || exit 90

echo "########## SAIN — reference avant sabotage ##########"
sha256sum "$GLB"

echo; echo "########## A. APPLICATION DU SABOTAGE ##########"
python3 "$S/sabotage.py"
echo "RC_patch=$?"

echo; echo "########## B. REGENERATION SABOTEE ##########"
tools/blender/export_architecture.sh farm_ruins > "$S/sab_chaine.log" 2>&1
echo "RC_chaine=$?"
grep -E "gravats |total [0-9]|EXPORT ARCH" "$S/sab_chaine.log"

echo; echo "########## C. LE GLB A-T-IL REELLEMENT CHANGE ? ##########"
sha256sum "$GLB"

echo; echo "########## D. INSTRUMENT SUR LE GLB SABOTE ##########"
python3 tools/mesure_boititude.py "$GLB" \
    --mesh SM_Farm_Debris_A --mesh SM_Farm_Debris_B --plafond 25 2>&1 | tail -4
echo "RC_instrument=${PIPESTATUS[0]}"

echo; echo "########## E. FILET GODOT — DOIT ROUGIR ##########"
"$GODOT_BIN" --headless --path . --import > "$S/sab_import.log" 2>&1
echo "RC_import=$?"
timeout 1200 "$GODOT_BIN" --headless --path . \
    --script tools/godot/test_runner.gd -- --filter=r2b3_debris \
    > "$E/26_test_sabotage_ROUGE.log" 2>&1
echo "RC_test=$?"
grep -E "r2b3_debris\]|=== RÉSULTAT|ÉCHEC:" "$E/26_test_sabotage_ROUGE.log"

echo; echo "########## F. RESTAURATION ##########"
git checkout -- source_assets/blender/architecture/make_farm_ruins.py
echo "sabotage encore present ? $(grep -c 'SABOTAGE : BOITE DROITE' \
    source_assets/blender/architecture/make_farm_ruins.py)"
tools/blender/export_architecture.sh farm_ruins > "$S/rest_chaine.log" 2>&1
echo "RC_chaine_restauration=$?"
grep -E "gravats |EXPORT ARCH" "$S/rest_chaine.log"

echo; echo "########## G. RETOUR A L'OCTET PRES ? ##########"
sha256sum "$GLB"
echo "git status assets/ (vide = identique au commit) :"
git status --porcelain -- assets/
echo "[fin]"
EOF
RC=$?
echo "RC=$RC" >> "$JOURNAL"
echo "RC=$RC"
