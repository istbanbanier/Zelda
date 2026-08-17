#!/bin/sh
# PLAN B DU TRIPTYQUE — DIAGNOSTIC, arbre SALE par construction.
#
# A : geometrie R2a-3.4 + lampes anciennes  (tronc, committe propre) -> PREUVE
# B : geometrie R2a-3.4 + lampes NOUVELLES  (ici, arbre sale)        -> DIAGNOSTIC
# C : geometrie cc3596c5 + lampes nouvelles (tronc integre)          -> PREUVE
#
# A -> B isole l'ECLAIRAGE. B -> C isole la GEOMETRIE. Sans ce plan
# intermediaire, la vue 10 compare geometrie ET eclairage a la fois, et ne
# peut pas repondre a la question qu'elle pose (« ce surplomb cree-t-il une
# poche ou une ombre parasite ? »).
#
# DEUX LIGNES DE LAMPE, PAS QUATRE. Les deux autres lignes deplacees par le
# meme diff — `voisin` et `MODELE_NICHE` — sont des champignons poses par
# `_habiller()`, dont celui de la RECOMPENSE. Les appliquer deplacerait la
# recompense et detruirait l'isolation cherchee.
#
# Cet arbre est SALE et le restera : c'est voulu, et le manifeste le dit.
# Le plan B n'est verse comme preuve d'aucune livraison.
set -u

V=/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad/r2a352/visuel
L=/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad/r2a352/eclats_godot_blender.lock
ARBRE=/home/user/Zelda
W=/home/user/zelda-r2a352/visuel_diag
BASE=1152c92d70c1f718b71e4d6fd9f53d92ed59bbe4
SORTIE="$V/diag_plan_b"
F="$W/scripts/world_v2/poi/waterfall_cave_place.gd"

mkdir -p "$SORTIE/perspectives" "$SORTIE/journaux"

# Un worktree oublie pourrit le depot en silence (CLAUDE.md) : filet de retrait.
nettoyer() { git -C "$ARBRE" worktree remove --force "$W" 2>/dev/null || true; }
trap nettoyer EXIT INT TERM

git -C "$ARBRE" worktree add --detach "$W" "$BASE" \
  > "$SORTIE/journaux/00_worktree.log" 2>&1 || {
  echo "BLOQUE : creation du worktree" >&2; exit 3; }

# --- les DEUX lignes de lampe -------------------------------------------
# `str.replace` silencieux est interdit ici (tools/CLAUDE.md) : on verifie la
# presence AVANT, et on relit l'endroit exact APRES. Un motif absent ne fait
# rien et ne dit rien.
for motif in \
  'seuil.position = Vector3(0.20, 1.50, -2.60)' \
  'salle.position = Vector3(0.20, 1.90, -7.20)' ; do
  n=$(grep -cF "$motif" "$F")
  if [ "$n" != "1" ]; then
    echo "BLOQUE : motif attendu 1 fois, trouve $n : $motif" >&2
    exit 3
  fi
done

sed -i \
  -e 's/seuil\.position = Vector3(0\.20, 1\.50, -2\.60)/seuil.position = Vector3(0.15, 1.50, -1.20)/' \
  -e 's/salle\.position = Vector3(0\.20, 1\.90, -7\.20)/salle.position = Vector3(2.70, 1.90, -3.35)/' \
  "$F"

# Relire l'endroit exact, pas chercher une valeur ailleurs dans le fichier.
{
  echo "=== lignes de lampe apres application ==="
  grep -n 'seuil\.position\|salle\.position' "$F"
  echo "=== diff du worktree (doit etre 1 fichier, 2 lignes) ==="
  git -C "$W" diff --stat
  git -C "$W" diff
} > "$SORTIE/journaux/01_patch.log" 2>&1

lignes=$(git -C "$W" diff --numstat | awk '{a+=$1; b+=$2} END {print a"/"b}')
fichiers=$(git -C "$W" diff --name-only | wc -l)
if [ "$fichiers" != "1" ] || [ "$lignes" != "2/2" ]; then
  echo "BLOQUE : diff inattendu — $fichiers fichier(s), $lignes ligne(s)" >&2
  exit 3
fi
echo "patch OK — 1 fichier, 2 lignes ajoutees / 2 retirees"

# --- import OBLIGATOIRE : worktree neuf, aucun `.godot/` -----------------
J0="$SORTIE/journaux/02_import.log"
flock "$L" sh -c "godot --headless --path '$W' --import > '$J0' 2>&1; echo \"RC=\$?\" >> '$J0'"

# --- captures, memes cameras, meme resolution, meme exposition -----------
J1="$SORTIE/journaux/03_perspectives.log"
flock "$L" sh -c "xvfb-run -a --server-args='-screen 0 1280x720x24' \
  godot --path '$W' --rendering-driver opengl3 \
  --script tools/godot/capture_poi_batch.gd -- \
  --scene=res://scenes/world_v2/WorldV2.tscn \
  --shots='$V/plans/shots_r2a352.json' \
  --out-dir='$SORTIE/perspectives' --size=1280x720 \
  --provenance=geometrie:assets/environment/caves/SM_WaterfallCave.glb,lieu:scripts/world_v2/poi/waterfall_cave_place.gd \
  > '$J1' 2>&1; echo \"RC=\$?\" >> '$J1'"

# --- manifeste : SALE par construction, et on le dit ---------------------
python3 "$V/outils/enrichir_manifeste.py" --arbre "$W" \
  --manifeste "$SORTIE/perspectives/manifest.json" \
  --sortie "$SORTIE/perspectives/manifest_enrichi.json" \
  --cote "B — DIAGNOSTIC : geometrie R2a-3.4 (8bf1a1b3) + lampes R2a-3.5.2. ARBRE SALE par construction, NON PROBANT comme livrable." \
  --tolerer-sale \
  > "$SORTIE/journaux/04_manifeste.log" 2>&1
echo "RC=$?" >> "$SORTIE/journaux/04_manifeste.log"

python3 "$V/outils/planche_lecture.py" \
  "$SORTIE/perspectives/10_visiere_dessous.png" --gamma=2.2 \
  --out-dir="$SORTIE/lecture" > "$SORTIE/journaux/05_lecture.log" 2>&1
echo "RC=$?" >> "$SORTIE/journaux/05_lecture.log"

echo "RC=0" >> "$SORTIE/journaux/TERMINE.log"
