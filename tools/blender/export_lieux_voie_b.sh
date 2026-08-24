#!/usr/bin/env bash
# Chaîne contrôlée des GLB dédiés de la VOIE B du lot 1.R (tour de guet,
# sanctuaire forestier, cimetière du tertre).
#
# POURQUOI UN SCRIPT SÉPARÉ ET NON TROIS LIGNES DANS `export_architecture.sh` :
# ce dernier est un fichier PARTAGÉ entre les trois voies de la corrective, et
# le brief interdit d'y toucher sans arbitrage du lead — trois voies qui y
# ajoutent chacune leurs sujets fabriqueraient trois conflits de fusion. Ce
# script reprend les MÊMES garde-fous (mesurés, pas décoratifs) :
#   * `--python-exit-code 1` + jeton de fraîcheur mtime (un .glb intact n'est
#     pas un .glb produit) ;
#   * sujet inconnu = BLOQUÉ (3), jamais un vert obtenu en ne faisant rien ;
#   * `FIN NOMINALE` exigée dans le log de génération — `blender --background`
#     rend 0 même quand le script lève (tools/CLAUDE.md) ;
#   * inspection glTF hors moteur après export.
# L'intégration éventuelle des sujets dans `export_architecture.sh` est
# remontée au lead (RAPPORT_VOIE.md).
#
# Usage :
#   tools/blender/export_lieux_voie_b.sh <sujet>     # l'argument est OBLIGATOIRE
set -uo pipefail

cd "$(dirname "$0")/../.."
BLENDER="${BLENDER_BIN:-blender}"
LOG_DIR="${LOG_DIR:-evidence/world_v2/v2_3_b/lot1r/voie_b/pipeline}"
mkdir -p "$LOG_DIR"

command -v "$BLENDER" >/dev/null 2>&1 || { echo "ÉCHEC: Blender absent" >&2; exit 2; }

SUJETS=(
  "watchtower_ruin|source_assets/blender/architecture/make_watchtower_ruin.py|source_assets/blender/architecture/SM_Watchtower_Ruin.blend|assets/architecture/watchtower/SM_Watchtower_Ruin.glb"
  "forest_shrine|source_assets/blender/architecture/make_forest_shrine.py|source_assets/blender/architecture/SM_Shrine_Vestige.blend|assets/architecture/shrine/SM_Shrine_Vestige.glb"
  "barrow_stones|source_assets/blender/architecture/make_barrow_stones.py|source_assets/blender/architecture/SM_Barrow_Stones.blend|assets/architecture/barrow/SM_Barrow_Stones.glb"
)

DEMANDE="${1:-}"
if [ -z "$DEMANDE" ]; then
  # L'ARGUMENT EST OBLIGATOIRE (piège mesuré : sans lui, export_architecture.sh
  # régénérait QUATRE golden masters gelés). Ici même règle, aucune exception.
  echo "BLOQUÉ: argument de sujet OBLIGATOIRE. Sujets connus :" >&2
  for ligne in "${SUJETS[@]}"; do echo "  ${ligne%%|*}" >&2; done
  exit 3
fi

CONNU=0
for ligne in "${SUJETS[@]}"; do
  [ "${ligne%%|*}" = "$DEMANDE" ] && CONNU=1
done
if [ $CONNU -eq 0 ]; then
  echo "BLOQUÉ: sujet inconnu « $DEMANDE ». Sujets connus :" >&2
  for ligne in "${SUJETS[@]}"; do echo "  ${ligne%%|*}" >&2; done
  exit 3
fi

echo "=== Blender: $("$BLENDER" --version 2>/dev/null | head -1) ==="

JETON="$LOG_DIR/.jeton_voie_b"
: > "$JETON"
FAIL=0

for ligne in "${SUJETS[@]}"; do
  IFS='|' read -r ID SRC BLEND GLB <<< "$ligne"
  [ "$DEMANDE" != "$ID" ] && continue

  echo
  echo "--- $ID : génération de la source ---"
  "$BLENDER" --background --python-exit-code 1 --python "$SRC" \
    > "$LOG_DIR/voie_b_${ID}_make.log" 2>&1 || FAIL=1
  grep "^\[" "$LOG_DIR/voie_b_${ID}_make.log" | sed 's/^/  /'
  if ! grep -q "FIN NOMINALE" "$LOG_DIR/voie_b_${ID}_make.log"; then
    echo "  ÉCHEC: jeton FIN NOMINALE absent — la génération n'a PAS abouti," >&2
    echo "  quel que soit le code retour (tools/CLAUDE.md)." >&2
    tail -12 "$LOG_DIR/voie_b_${ID}_make.log" | sed 's/^/  | /' >&2
    FAIL=1; continue
  fi
  if [ $FAIL -ne 0 ]; then
    echo "  ÉCHEC: génération non-zéro — voir $LOG_DIR/voie_b_${ID}_make.log" >&2
    continue
  fi

  echo "--- $ID : export .glb ---"
  mkdir -p "$(dirname "$GLB")"
  "$BLENDER" --background --python-exit-code 1 "$BLEND" \
    --python tools/blender/export_gltf.py -- --out "$GLB" \
    > "$LOG_DIR/voie_b_${ID}_export.log" 2>&1 || FAIL=1
  grep '^\[export_gltf\]' "$LOG_DIR/voie_b_${ID}_export.log" | sed 's/^/  /'

  if [ ! -f "$GLB" ]; then
    echo "  ÉCHEC: $GLB absent" >&2; FAIL=1; continue
  fi
  if [ "$GLB" -ot "$JETON" ]; then
    echo "  ÉCHEC: $GLB n'a PAS été réécrit (plus ancien que le jeton)." >&2
    FAIL=1; continue
  fi
  echo "  frais: $GLB ($(stat -c%s "$GLB") octets)"

  echo "--- $ID : inspection glTF hors moteur ---"
  python3 tools/gltf_inspect.py "$GLB" \
    | tee "$LOG_DIR/voie_b_${ID}_inspect.log" | sed 's/^/  /' || FAIL=1
done

printf '\n=== EXPORT VOIE B : %s ===\n' "$([ $FAIL -eq 0 ] && echo VERT || echo ROUGE)"
exit $FAIL
