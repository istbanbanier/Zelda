#!/usr/bin/env bash
# Chaîne contrôlée des GLB dédiés de la VOIE A du lot 1.R (belvédère, source).
#
# POURQUOI UN SCRIPT SÉPARÉ ET NON DEUX LIGNES DANS `export_architecture.sh` :
# ce dernier est PARTAGÉ, et sans argument il régénère QUATRE golden masters
# gelés (piège mesuré, `tools/CLAUDE.md`). Trois voies qui y ajoutent chacune
# leurs sujets fabriqueraient trois conflits de fusion. Même forme que
# `export_lieux_voie_b.sh`, mêmes garde-fous, tous mesurés :
#   * `--python-exit-code 1` + jeton de fraîcheur mtime (un .glb intact n'est
#     pas un .glb produit) ;
#   * sujet inconnu ou absent = BLOQUÉ (3), jamais un vert obtenu en ne
#     faisant rien ;
#   * `FIN NOMINALE` exigée dans le log — `blender --background` rend 0 même
#     quand le script lève ;
#   * inspection glTF hors moteur après export.
#
# Usage :
#   tools/blender/export_lieux_voie_a.sh <sujet>     # argument OBLIGATOIRE
set -uo pipefail

cd "$(dirname "$0")/../.."
BLENDER="${BLENDER_BIN:-blender}"
LOG_DIR="${LOG_DIR:-evidence/world_v2/v2_3_b/lot1r/voie_a/pipeline}"
mkdir -p "$LOG_DIR"

command -v "$BLENDER" >/dev/null 2>&1 || { echo "ÉCHEC: Blender absent" >&2; exit 2; }

SUJETS=(
  "overlook_crags|source_assets/blender/environment/make_overlook_crags.py|source_assets/blender/environment/SM_OverlookCrags.blend|assets/environment/rocks/SM_OverlookCrags.glb"
  "spring_maw|source_assets/blender/environment/make_spring_maw.py|source_assets/blender/environment/SM_SpringMaw.blend|assets/environment/rocks/SM_SpringMaw.glb"
)

DEMANDE="${1:-}"
if [ -z "$DEMANDE" ]; then
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
JETON="$LOG_DIR/.jeton_voie_a"
: > "$JETON"
FAIL=0

for ligne in "${SUJETS[@]}"; do
  IFS='|' read -r ID SRC BLEND GLB <<< "$ligne"
  [ "$DEMANDE" != "$ID" ] && continue

  echo; echo "--- $ID : génération de la source ---"
  "$BLENDER" --background --python-exit-code 1 --python "$SRC" \
    > "$LOG_DIR/voie_a_${ID}_make.log" 2>&1 || FAIL=1
  grep "^\[" "$LOG_DIR/voie_a_${ID}_make.log" | sed 's/^/  /'
  if ! grep -q "FIN NOMINALE" "$LOG_DIR/voie_a_${ID}_make.log"; then
    echo "  ÉCHEC: jeton FIN NOMINALE absent — la génération n'a PAS abouti," >&2
    echo "  quel que soit le code retour (tools/CLAUDE.md)." >&2
    tail -15 "$LOG_DIR/voie_a_${ID}_make.log" | sed 's/^/  | /' >&2
    FAIL=1; continue
  fi
  [ $FAIL -ne 0 ] && { echo "  ÉCHEC: génération non-zéro" >&2; continue; }

  echo "--- $ID : export .glb ---"
  mkdir -p "$(dirname "$GLB")"
  "$BLENDER" --background --python-exit-code 1 "$BLEND" \
    --python tools/blender/export_gltf.py -- --out "$GLB" \
    > "$LOG_DIR/voie_a_${ID}_export.log" 2>&1 || FAIL=1
  grep '^\[export_gltf\]' "$LOG_DIR/voie_a_${ID}_export.log" | sed 's/^/  /'

  [ -f "$GLB" ] || { echo "  ÉCHEC: $GLB absent" >&2; FAIL=1; continue; }
  if [ "$GLB" -ot "$JETON" ]; then
    echo "  ÉCHEC: $GLB n'a PAS été réécrit (plus ancien que le jeton)." >&2
    FAIL=1; continue
  fi
  echo "  frais: $GLB ($(stat -c%s "$GLB") octets)"

  echo "--- $ID : inspection glTF hors moteur ---"
  python3 tools/gltf_inspect.py "$GLB" \
    | tee "$LOG_DIR/voie_a_${ID}_inspect.log" | sed 's/^/  /' || FAIL=1
  echo "--- $ID : COLOR_0 réellement présent ? (ISS-066) ---"
  python3 - "$GLB" <<'PY' | tee -a "$LOG_DIR/voie_a_${ID}_inspect.log" | sed 's/^/  /' || FAIL=1
import json, struct, sys
data = open(sys.argv[1], 'rb').read()
n = struct.unpack('<I', data[12:16])[0]
gltf = json.loads(data[20:20+n])
manque = []
for m in gltf.get('meshes', []):
    for p in m.get('primitives', []):
        attrs = sorted(p['attributes'])
        print("mesh %-24s attributs %s" % (m.get('name'), attrs))
        if 'COLOR_0' not in attrs:
            manque.append(m.get('name'))
if manque:
    print("ECHEC: COLOR_0 absent de %s" % manque); sys.exit(2)
print("COLOR_0 present sur toutes les primitives")
PY
done

printf '\n=== EXPORT VOIE A : %s ===\n' "$([ $FAIL -eq 0 ] && echo VERT || echo ROUGE)"
exit $FAIL
