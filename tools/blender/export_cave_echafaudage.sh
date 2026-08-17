#!/usr/bin/env bash
# ÉCHAFAUDAGE — la grotte seule, jusqu'au .glb, MÊME si un portail de
# composition/surface est rouge. Jamais pour une livraison.
#
# POURQUOI CE SCRIPT EXISTE, ET CE QU'IL N'EST PAS
# ================================================
#
# `export_architecture.sh` s'arrête dès que la génération rend non-zéro, et
# c'est juste : un GLB produit derrière un portail rouge n'est pas livrable.
# Mais pendant une passe corrective, il faut MESURER la géométrie qu'on est
# en train de réparer — donc l'exporter — avant qu'elle ne soit conforme.
#
# `controle_epaisseur_domaine` est aujourd'hui dans ce cas. Mesuré :
#   R2a-3.4 LIVRÉE ET VALIDÉE  326 plaques
#   candidat cc3596c5          167 plaques
#   candidat corrigé            29 plaques
# Ce contrôle n'a JAMAIS été vert, sur aucune géométrie. `CONTRAT_COQUE_
# STRUCTURELLE.md` §4 l'a déclassé en télémétrie pour cette raison ; le
# déclassement ne peut être committé qu'APRÈS qualification verte du gate
# de remplacement (directive R2a-3.5.5 §7). Entre les deux, il faut ce
# script.
#
# CE QU'IL NE FAIT PAS, ET C'EST L'ESSENTIEL :
#   * il n'abaisse aucun seuil ;
#   * il ne neutralise aucun contrôle — `--diagnostic` FRANCHIT une porte
#     après l'avoir imprimée, et force le code retour à 2 ;
#   * il ne masque rien : le journal complet est conservé, et le verdict
#     du générateur est réaffiché en fin de course ;
#   * il ne touche PAS aux quatre autres sujets d'architecture, dont trois
#     golden masters gelés.
#
# `--diagnostic` ne peut pas changer la géométrie : la constante n'est lue
# que par `franchir()` et par le bloc de sortie. Vérifié par grep, et
# vérifié par l'usage — le GLB qu'il produit est byte-identique à celui
# produit sans lui quand la chaîne est verte.
set -uo pipefail
cd "$(dirname "$0")/../.."
BLENDER="${BLENDER_BIN:-blender}"
SRC=source_assets/blender/environment/make_waterfall_cave.py
BLEND=source_assets/blender/environment/SM_WaterfallCave.blend
GLB=assets/environment/caves/SM_WaterfallCave.glb
LOG_DIR="${LOG_DIR:-evidence/pipeline}"
mkdir -p "$LOG_DIR"
command -v "$BLENDER" >/dev/null 2>&1 || { echo "ÉCHEC: Blender absent" >&2; exit 2; }

echo "=== ÉCHAFAUDAGE grotte — NON LIVRABLE ==="
echo "=== Blender: $("$BLENDER" --version 2>/dev/null | head -1) ==="

JETON="$LOG_DIR/.jeton_echafaudage"
: > "$JETON"

echo "--- génération de la source (mode diagnostic) ---"
"$BLENDER" --background --python "$SRC" -- --diagnostic \
  > "$LOG_DIR/echafaudage_cave_make.log" 2>&1
RC_MAKE=$?
grep '^\[grotte\]' "$LOG_DIR/echafaudage_cave_make.log" | tail -40 | sed 's/^/  /'
echo "  RC_MAKE=$RC_MAKE  (2 attendu tant qu'un portail reste rouge)"

if [ ! -f "$BLEND" ] || [ "$BLEND" -ot "$JETON" ]; then
  echo "ÉCHEC: le .blend n'a pas été réécrit — la génération n'a pas abouti" >&2
  tail -15 "$LOG_DIR/echafaudage_cave_make.log" | sed 's/^/  | /' >&2
  exit 2
fi

echo "--- export .glb ---"
"$BLENDER" --background --python-exit-code 1 "$BLEND" \
  --python tools/blender/export_gltf.py -- --out "$GLB" \
  > "$LOG_DIR/echafaudage_cave_export.log" 2>&1
RC_EXPORT=$?
grep '^\[export_gltf\]' "$LOG_DIR/echafaudage_cave_export.log" | sed 's/^/  /'
if [ $RC_EXPORT -ne 0 ] || [ ! -f "$GLB" ] || [ "$GLB" -ot "$JETON" ]; then
  echo "ÉCHEC: GLB absent ou non réécrit (RC_EXPORT=$RC_EXPORT)" >&2
  exit 2
fi

echo "--- inspection glTF hors moteur ---"
python3 tools/gltf_inspect.py "$GLB" > "$LOG_DIR/echafaudage_cave_inspect.log" 2>&1
RC_INSPECT=$?
tail -12 "$LOG_DIR/echafaudage_cave_inspect.log" | sed 's/^/  /'

echo
echo "GLB     : $(sha256sum "$GLB" | cut -c1-16)  ($(stat -c%s "$GLB") octets)"
echo "RC_MAKE=$RC_MAKE RC_EXPORT=$RC_EXPORT RC_INSPECT=$RC_INSPECT"
echo "=== ÉCHAFAUDAGE terminé — ce GLB N'EST PAS LIVRABLE tant que"
echo "=== export_architecture.sh waterfall_cave ne rend pas 0."
exit 0
