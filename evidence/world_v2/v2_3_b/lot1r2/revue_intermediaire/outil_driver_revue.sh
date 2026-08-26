#!/usr/bin/env bash
# REVUE INTERMÉDIAIRE lot 1.R.2 — périmètre EXACT de la directive :
#   * 6 vues joueur : 3 GELÉES reprises octet pour octet, 3 recapturées ;
#   * 3 vues d'identité corrigées ;
#   * planche joueur anonyme numérotée, planche couleur, planche gris ;
#   * manifeste SHA unique + repo_dirty:false.
# PAS les A/B complets, PAS de grande campagne, PAS validate_fast, PAS de release.
set -u
R=/home/user/Zelda; BASE=/home/user/lot1r2_reprise
cd $R || exit 9
SHA=$(git rev-parse --short HEAD)
LOG="$BASE/revue_${SHA}.log"; TOK="$BASE/REVUE_${SHA}.token"
E=evidence/world_v2/v2_3_b/lot1r2/revue_intermediaire
GELEES=evidence/world_v2/v2_3_b/lot1r1/revue_intermediaire/vues
rm -f "$TOK"; mkdir -p "$E/vues"
echo "=== DÉBUT $(date -u +%FT%TZ) sur $SHA ===" > "$LOG"

# 1. Les 6 vues des trois sujets CORRIGÉS (joueur + identité), caméras GELÉES.
python3 - <<'PY'
import json
tous = json.load(open('evidence/world_v2/v2_3_b/lot1/poi/shots_lot1.json'))
noms = [f"{p}_{v}" for p in ('turquoise_spring','forest_shrine','barrow_cemetery')
        for v in ('joueur','identite')]
sel = [s for s in tous if s['name'] in noms]
assert len(sel) == 6, [s['name'] for s in sel]
json.dump(sel, open('/home/user/lot1r2_reprise/shots_revue.json','w'), indent=1)
PY
tools/lancer_godot.sh --rendu --path . --script tools/godot/capture_poi_batch.gd -- \
  --scene=res://scenes/world_v2/WorldV2.tscn \
  --shots=/home/user/lot1r2_reprise/shots_revue.json --out-dir=$E/vues >> "$LOG" 2>&1
RC_VUES=$?; echo "RC_VUES=$RC_VUES" >> "$LOG"

# 2. Les trois PASS visuels : images reprises OCTET POUR OCTET, jamais recapturées.
RC_COPIE=0
for n in overlook_summit watchtower_ruin flower_field; do
  cp "$GELEES/${n}_joueur.png" "$E/vues/${n}_joueur.png" || RC_COPIE=1
  cmp -s "$GELEES/${n}_joueur.png" "$E/vues/${n}_joueur.png" \
    && echo "gelée $n : identique octet pour octet" >> "$LOG" \
    || { echo "gelée $n : DIFFÈRE — ANOMALIE" >> "$LOG"; RC_COPIE=2; }
done
echo "RC_COPIE=$RC_COPIE" >> "$LOG"

# 3. Contrôle ciblé : les 23 empreintes des trois sujets gelés.
sha256sum -c evidence/world_v2/v2_3_b/lot1r2/GEL_VISUEL_3_SUJETS_529d767.sha256 \
  > "$E/controle_gel_3_sujets.log" 2>&1
RC_GEL=$?; echo "RC_GEL=$RC_GEL" >> "$LOG"

echo "=== FIN $(date -u +%FT%TZ) ===" >> "$LOG"
printf 'sha=%s\nvues=%s\ncopie=%s\ngel=%s\nfin=%s\n' \
  "$SHA" "$RC_VUES" "$RC_COPIE" "$RC_GEL" "$(date -u +%FT%TZ)" > "$TOK"
