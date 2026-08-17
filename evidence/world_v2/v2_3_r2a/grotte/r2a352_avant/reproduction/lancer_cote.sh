#!/bin/sh
# CAPTURE D'UN COTE DE L'A/B — outil unique, parametre.
#
# L'EMPREINTE ATTENDUE EST REDEVENUE UNE CONSTANTE, et c'est un retrait
# assume. Elle avait ete parametree pour que le meme script serve le cote
# APRES, dont le GLB aurait valu `cc3596c5`. **Le cote APRES est annule** :
# la passe s'arrete en PARTIAL, il n'y aura pas d'integration. Un parametre
# dont le seul appelant n'existera jamais est une piece morte, et une piece
# morte finit par etre appelee de travers.
#
# LE CONTROLE, LUI, RESTE. Il refuse de tourner si le tronc n'est pas
# exactement la base attendue, s'il est sale, ou si le GLB n'est pas la
# geometrie R2a-3.4. Sortie 3 (BLOQUE) dans les trois cas, jamais 0.
#
# Usage :
#   lancer_cote.sh --base <sha40> --cote "<libelle>" --sortie <dossier> [--nom <suffixe>]
set -u

V=/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad/r2a352/visuel
ARBRE=/home/user/Zelda
CHEMIN_GLB=assets/environment/caves/SM_WaterfallCave.glb

# Geometrie R2a-3.4, la baseline REJETEE — le seul cote qui sera capture.
GLB=8bf1a1b309aee79f92c77371f0f5137c3e6ceefc1ecf4842f038af4f48c77110

BASE=""; COTE=""; SORTIE=""; NOM=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base)   BASE="$2";   shift 2 ;;
    --cote)   COTE="$2";   shift 2 ;;
    --sortie) SORTIE="$2"; shift 2 ;;
    --nom)    NOM="$2";    shift 2 ;;
    *) echo "argument inconnu : $1" >&2; exit 2 ;;
  esac
done
for v in BASE COTE SORTIE; do
  eval "val=\$$v"
  [ -n "$val" ] || { echo "BLOQUE : --$(echo $v | tr 'A-Z' 'a-z') requis" >&2; exit 2; }
done
[ -n "$NOM" ] || NOM=grotte

# ------------------------------------------------------------------ pre-vol
tete=$(git -C "$ARBRE" rev-parse HEAD)
if [ "$tete" != "$BASE" ]; then
  echo "BLOQUE : tronc a $tete, base attendue $BASE" >&2
  exit 3
fi
sale=$(git -C "$ARBRE" status --porcelain --untracked-files=no)
if [ -n "$sale" ]; then
  echo "BLOQUE : arbre SALE — une capture d'arbre sale ne prouve rien" >&2
  echo "$sale" >&2
  exit 3
fi
empreinte=$(sha256sum "$ARBRE/$CHEMIN_GLB" | cut -d' ' -f1)
if [ "$empreinte" != "$GLB" ]; then
  echo "BLOQUE : GLB $empreinte, attendu $GLB (geometrie R2a-3.4)" >&2
  exit 3
fi
echo "pre-vol OK — base $tete, GLB $(echo $empreinte | cut -c1-16), arbre propre"

mkdir -p "$SORTIE/perspectives" "$SORTIE/silhouettes" "$SORTIE/journaux"

# --- import : `capture_silhouette.gd` n'a PAS de garde-fou de fraicheur ---
# Mesure du 2026-08-16 : celui de `capture_poi_batch.gd` a bloque en 3 sur
# trois prototypes d'enveloppe non importes. Ce n'est pas theorique.
J0="$SORTIE/journaux/00_import.log"
godot --headless --path "$ARBRE" --import > "$J0" 2>&1
echo "RC=$?" >> "$J0"

PROV=geometrie:$CHEMIN_GLB,lieu:scripts/world_v2/poi/waterfall_cave_place.gd,monde:scenes/world_v2/WorldV2.tscn

# --- 7 plans en perspective, 1280x720 -------------------------------------
J1="$SORTIE/journaux/01_perspectives.log"
xvfb-run -a --server-args="-screen 0 1280x720x24" \
  godot --path "$ARBRE" --rendering-driver opengl3 \
  --script tools/godot/capture_poi_batch.gd -- \
  --scene=res://scenes/world_v2/WorldV2.tscn \
  --shots="$V/plans/shots_r2a352.json" \
  --out-dir="$SORTIE/perspectives" --size=1280x720 \
  --provenance="$PROV" \
  > "$J1" 2>&1
echo "RC=$?" >> "$J1"

# --- 3 silhouettes, 1200x900 PAYSAGE --------------------------------------
# Arbitrage du lead : le sujet fait 23,65 m de large pour 10,14 m de haut ;
# en portrait 900x1200 la largeur commande le cadrage et le sujet n'occupe
# que 16 % de l'image. En paysage il occupe ~48 % de la hauteur. Le decalage
# d'echelle mesure entre les deux geometries est INCHANGE (+4,31 % contre
# +4,28 %) : la mesure ne bouge pas, seule la lisibilite gagne. Le format
# differe donc des planches `r2a351`, et la planche doit le dire.
J2="$SORTIE/journaux/02_silhouettes.log"
xvfb-run -a --server-args="-screen 0 1200x900x24" \
  godot --path "$ARBRE" --rendering-driver opengl3 \
  --script tools/godot/capture_silhouette.gd -- \
  --scene=res://scenes/world_v2/WorldV2.tscn \
  --place=valley.poi.waterfall_cave.01 \
  --name="$NOM" \
  --angles=55,100,225 --size=1200x900 --clip-below=3.0 \
  --out-dir="$SORTIE/silhouettes" \
  --provenance="$PROV" \
  > "$J2" 2>&1
echo "RC=$?" >> "$J2"

# --- manifestes enrichis : sha256 du GLB, exposition, convention de FOV ---
for paire in "perspectives:manifest.json" "silhouettes:manifest_silhouettes_$NOM.json"; do
  d=${paire%%:*}; f=${paire#*:}
  python3 "$V/outils/enrichir_manifeste.py" --arbre "$ARBRE" \
    --manifeste "$SORTIE/$d/$f" \
    --sortie "$SORTIE/$d/manifest_enrichi.json" \
    --cote "$COTE" \
    > "$SORTIE/journaux/03_manifeste_$d.log" 2>&1
  echo "RC=$?" >> "$SORTIE/journaux/03_manifeste_$d.log"
done

# --- derives de revue : vignette + niveaux de gris (outil du depot) -------
J5="$SORTIE/journaux/05_derives.log"
python3 "$ARBRE/tools/make_review_derivatives.py" \
  "$SORTIE/perspectives" "$SORTIE/perspectives" > "$J5" 2>&1
echo "RC=$?" >> "$J5"

# --- planche de LECTURE de la vue par-dessous, gamma documente ------------
# Derivee, jamais une capture. Mesure : rien n'est ecrete en bas (0,00 % de
# pixels <= 24/255) ; le defaut est une COMPRESSION DE CONTRASTE, la vue 10
# vivant entre 32 et 84, soit 20 % de la dynamique.
J6="$SORTIE/journaux/06_lecture.log"
python3 "$V/outils/planche_lecture.py" \
  "$SORTIE/perspectives/10_visiere_dessous.png" --gamma=2.2 \
  --out-dir="$SORTIE/lecture" > "$J6" 2>&1
echo "RC=$?" >> "$J6"

echo "RC=0" >> "$SORTIE/journaux/TERMINE.log"
