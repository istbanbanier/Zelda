#!/usr/bin/env bash
# =============================================================================
# tools/lot1r_video.sh — VIDÉO JOUEUR lot 1.R : parcours réel, vrais contrôles,
# MovieMaker natif (--write-movie, MJPEG + PCM dans un .avi).
#
# Enveloppe fine au-dessus de tools/lancer_godot.sh (verrou canonique partagé
# + cloison user:// + xvfb) : AUCUN moteur nu ici.
#
# AVANT toute vidéo : l'import doit être frais (worktree neuf, merge, nouveau
# GLB) — `tools/lancer_godot.sh --path . --import`. Une vidéo d'un cache
# d'import périmé montrerait la géométrie PRÉCÉDENTE, et serait crédible.
#
# Rendu llvmpipe : compter 5 à 15 minutes de mur pour ~30 s de film. La prise
# de verrou attend son tour derrière les suites — c'est normal, ne rien tuer.
#
# Usage :
#   tools/lot1r_video.sh <parcours.json> <sortie.avi> [budget_s]
# Exemple :
#   tools/lot1r_video.sh \
#     evidence/world_v2/v2_3_b/lot1r/voie_c/parcours_flower_field.json \
#     evidence/world_v2/v2_3_b/lot1r/voie_c/video_flower_field.avi 90
#
# Codes : celui du pilote (0 = parcours entier, 1 = jalon manqué → vidéo à
# REJETER, 3 = BLOQUÉ) ; 2 = entrée absente.
# =============================================================================
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PARCOURS="${1:?usage: tools/lot1r_video.sh <parcours.json> <sortie.avi> [budget_s]}"
SORTIE="${2:?usage: tools/lot1r_video.sh <parcours.json> <sortie.avi> [budget_s]}"
BUDGET="${3:-90}"

if [ ! -f "$REPO/$PARCOURS" ] && [ ! -f "$PARCOURS" ]; then
	echo "ECHEC: parcours absent — $PARCOURS" >&2
	exit 2
fi
case "$SORTIE" in
	*.avi) : ;;
	*) echo "ECHEC: la sortie doit être un .avi (MJPEG natif du MovieMaker) — $SORTIE" >&2
	   exit 2 ;;
esac
mkdir -p "$(dirname "$REPO/$SORTIE")" 2>/dev/null || true

"$REPO/tools/lancer_godot.sh" --rendu --path "$REPO" \
	--write-movie "$SORTIE" --fixed-fps 30 --audio-driver Dummy \
	--script tools/godot/lot1r_video.gd -- \
	--scene=res://scenes/world_v2/WorldV2.tscn \
	--parcours="$PARCOURS" --budget-s="$BUDGET"
RC=$?

# Une vidéo absente ou vide avec RC=0 serait un vert obtenu en ne faisant
# rien — publier la taille de ce qu'on a produit, et échouer sinon.
FICHIER="$REPO/$SORTIE"
[ -f "$FICHIER" ] || FICHIER="$SORTIE"
if [ "$RC" -eq 0 ]; then
	if [ ! -s "$FICHIER" ]; then
		echo "ECHEC: RC=0 mais vidéo absente ou vide — $SORTIE" >&2
		exit 2
	fi
	echo "VIDEO: $SORTIE ($(du -h "$FICHIER" | cut -f1)) — parcours entier"
else
	echo "VIDEO: échec RC=$RC — toute vidéo partielle est à rejeter" >&2
fi
exit "$RC"
