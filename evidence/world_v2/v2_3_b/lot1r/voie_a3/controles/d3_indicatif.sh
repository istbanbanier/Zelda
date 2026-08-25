#!/usr/bin/env bash
# D3 INDICATIF — pas un verdict. On recopie le jeu de silhouettes de la
# candidate, on y REMPLACE les deux sujets de l'agent A par ceux qui viennent
# d'etre captures, et on rejoue le detecteur. Les quatre autres lieux du lot
# sont ceux de la candidate : d'autres agents les reconstruisent en ce moment
# meme, donc ce resultat dit quelque chose de MA paire contre le corpus gele,
# et rien de definitif sur le lot.
set -uo pipefail
cd /home/user/wt1r1-a
SRC=evidence/world_v2/v2_3_b/lot1r/candidate/silhouettes
NEW=evidence/world_v2/v2_3_b/lot1r/voie_a3/silhouettes
DST=/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad/d3_mix
rm -rf "$DST"; cp -r "$SRC" "$DST"
n=0
for f in "$NEW"/*overlook_summit* "$NEW"/*turquoise_spring*; do
  [ -f "$f" ] || { echo "ECHEC: silhouette absente ($f)"; exit 2; }
  cp "$f" "$DST/"; n=$((n+1))
done
echo "$n fichier(s) remplaces dans le jeu de comparaison"
python3 tools/lot1_repetition.py --manifestes "$DST" \
  --out "$DST/verdict_indicatif.json"
echo "RC_D3=$?"
