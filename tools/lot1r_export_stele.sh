#!/usr/bin/env bash
# =============================================================================
# tools/lot1r_export_stele.sh — chaîne contrôlée du seul asset Blender du
# lot 1.R voie C : les deux pierres de la Porte des fleurs.
#
# POURQUOI UN SCRIPT À PART, et pas une ligne dans `export_architecture.sh`.
# Ce dernier est un fichier PARTAGÉ du dépôt (BRIEF_COMMUN : « ne PAS modifier
# un fichier partagé sans cause démontrée »), et il refuse — à raison — tout
# sujet absent de sa liste : `BLOQUÉ: sujet inconnu`. Ajouter mon sujet à sa
# table serait une modification partagée pour un asset d'une seule voie, que
# le lead devrait démêler au cherry-pick. Ce fichier est NOUVEAU, préfixé
# `lot1r_`, et il REPREND les deux garde-fous mesurés de l'original :
#
#   * `--python-exit-code 1` — sans lui, `blender --background` rend 0 même
#     quand le script Python lève : la chaîne se déclare verte sans avoir
#     rien exporté (mesuré le 2026-08-14 sur ce dépôt).
#   * jeton de fraîcheur — un `.glb` intact n'est pas un `.glb` produit. Sans
#     comparaison de mtime, l'inspection revalide le fichier DÉJÀ versionné
#     et annonce un succès qui appartient à hier.
#
# Il en ajoute un troisième, propre à ce sujet :
#   * `FIN NOMINALE` — le générateur ne l'imprime qu'après ses contrôles
#     (base à z=0, hauteurs, budget de triangles, aire de facette maximale,
#     élancement). Son absence est un échec même si le code retour est 0.
#
# Usage :
#   tools/lot1r_export_stele.sh
#
# Codes : 0 = GLB frais, contrôlé et inspecté · 1 = échec de la chaîne
#         · 2 = Blender absent.
# =============================================================================
set -uo pipefail

cd "$(dirname "$0")/.."
BLENDER="${BLENDER_BIN:-blender}"
LOG_DIR="${LOG_DIR:-evidence/pipeline}"
mkdir -p "$LOG_DIR"

SRC="source_assets/blender/environment/make_flower_field_steles.py"
BLEND="source_assets/blender/environment/SM_FlowerFieldSteles.blend"
GLB="assets/environment/rocks/SM_FlowerField_Steles.glb"

command -v "$BLENDER" >/dev/null 2>&1 || {
	echo "BLOQUÉ: Blender absent — tools/setup_blender.sh" >&2; exit 2; }
[ -f "$SRC" ] || { echo "ÉCHEC: source absente — $SRC" >&2; exit 1; }

echo "=== Blender: $("$BLENDER" --version 2>/dev/null | head -1) ==="

JETON="$LOG_DIR/.jeton_lot1r_stele"
: > "$JETON"
FAIL=0

echo "--- génération de la source ---"
"$BLENDER" --background --python-exit-code 1 --python "$SRC" \
	> "$LOG_DIR/lot1r_stele_make.log" 2>&1 || FAIL=1
grep '^\[flower_field_steles\]' "$LOG_DIR/lot1r_stele_make.log" | sed 's/^/  /'
if [ $FAIL -ne 0 ]; then
	echo "  ÉCHEC: génération non-zéro — $LOG_DIR/lot1r_stele_make.log" >&2
	tail -15 "$LOG_DIR/lot1r_stele_make.log" | sed 's/^/  | /' >&2
	exit 1
fi
if ! tail -3 "$LOG_DIR/lot1r_stele_make.log" | grep -q '^FIN NOMINALE$'; then
	echo "  ÉCHEC: jeton FIN NOMINALE absent — les contrôles du générateur" \
		"n'ont pas été atteints" >&2
	exit 1
fi

echo "--- export .glb ---"
mkdir -p "$(dirname "$GLB")"
"$BLENDER" --background --python-exit-code 1 "$BLEND" \
	--python tools/blender/export_gltf.py -- --out "$GLB" \
	> "$LOG_DIR/lot1r_stele_export.log" 2>&1 || FAIL=1
grep '^\[export_gltf\]' "$LOG_DIR/lot1r_stele_export.log" | sed 's/^/  /'
if [ $FAIL -ne 0 ] || [ ! -f "$GLB" ]; then
	echo "  ÉCHEC: export — $LOG_DIR/lot1r_stele_export.log" >&2
	tail -15 "$LOG_DIR/lot1r_stele_export.log" | sed 's/^/  | /' >&2
	exit 1
fi
if [ "$GLB" -ot "$JETON" ]; then
	echo "  ÉCHEC: $GLB n'a PAS été réécrit (plus ancien que le jeton)." >&2
	exit 1
fi
echo "  frais: $GLB ($(stat -c%s "$GLB") octets)"

echo "--- inspection glTF hors moteur ---"
python3 tools/gltf_inspect.py "$GLB" \
	| tee "$LOG_DIR/lot1r_stele_inspect.log" | sed 's/^/  /' || FAIL=1

printf '\n=== EXPORT STÈLES : %s ===\n' "$([ $FAIL -eq 0 ] && echo VERT || echo ROUGE)"
exit $FAIL
