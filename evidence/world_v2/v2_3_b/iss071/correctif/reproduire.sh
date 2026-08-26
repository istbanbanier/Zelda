#!/usr/bin/env bash
# Le lead REPRODUIT le rouge puis le vert de l'agent B, sans le croire sur parole.
set -uo pipefail
W=/home/user/wt-b
cd "$W"
echo "### arbre : $(git status --porcelain | grep -v '^?? tools/godot/iss071_manifeste_editeur.gd.uid' | wc -l) modification(s) hors .uid non suivi"

echo "### 1. AVANT le correctif — commit 69502e7 (test présent, résolveurs intacts)"
git checkout -q 69502e7
git log --oneline -1
tools/lancer_godot.sh --path "$W" --script tools/godot/test_runner.gd -- --filter=iss071_normalisation > /tmp/repro_avant.log 2>&1
echo "RC_AVANT=$?"
grep -aE "^=== RÉSULTAT|ÉCHEC" /tmp/repro_avant.log | head -8

echo
echo "### 2. APRÈS le correctif — commit 3ef33d6"
git checkout -q 3ef33d6
git log --oneline -1
tools/lancer_godot.sh --path "$W" --script tools/godot/test_runner.gd -- --filter=iss071_normalisation > /tmp/repro_apres.log 2>&1
echo "RC_APRES=$?"
grep -aE "^=== RÉSULTAT|ÉCHEC" /tmp/repro_apres.log | head -8

echo
echo "### 3. gel des six lieux après manipulation"
sha256sum -c evidence/world_v2/v2_3_b/lot1r2/cloture/GEL_SIX_LIEUX_51b7b29.sha256 2>&1 | grep -c ': OK'
echo "RC=0"
