#!/usr/bin/env bash
# ÉNUMÉRATION COMPLÈTE du résidu de fin de processus — le mode cher.
#
# `validate_fast` juge la SIGNATURE AGRÉGÉE, au chiffre près, pour quelques
# millisecondes. Ce script-ci juge la COMPOSITION : classe par classe, chemin par
# chemin, et il vérifie que l'ensemble mesuré égale l'ensemble expliqué.
#
# LE PRIX, mesuré le 2026-08-21 sur cette machine et non supposé :
#   suite avec --verbose ...... 914 tests en 1 590 s, vidage de 420 Mo, et pas
#                                terminee a 1 841 s quand je l'ai arretee
#   suite sans --verbose ...... 11 tests/min en regime, mesure sur la meme
#                                machine le meme jour
# Le facteur exact n'est pas etabli ; ce qui l'est, c'est que --verbose est
# mesurablement plus lent et produit un vidage de plusieurs centaines de Mo. C'est pourquoi il n'est PAS dans validate_fast : un
# contrôle de ce prix à chaque tour finirait par être sauté (PROMPT4_METHOD §0).
#
# À lancer : avant une clôture de passe, avant une livraison, et chaque fois que
# le portail agrégé bouge sans explication.
#
#   tools/gate_fuite_composition.sh [--sortie <repertoire>] [--entériner]
#
# `--entériner` réécrit `docs/contrats/residu_cache_moteur.json` à partir de la
# mesure. À n'employer qu'avec une justification écrite : c'est le geste qui
# accepte une nouvelle enveloppe, pas celui qui fait taire un rouge.
set -uo pipefail
cd "$(dirname "$0")/.."
SORTIE="evidence/gate_fuite"
ENTERINER=0
for arg in "$@"; do
  case "$arg" in
    --sortie=*) SORTIE="${arg#--sortie=}" ;;
    --entériner|--enteriner) ENTERINER=1 ;;
  esac
done
mkdir -p "$SORTIE"

VIDAGE="$(mktemp "${TMPDIR:-/tmp}/composition_verbose.XXXXXX.log")"
trap 'rm -f "$VIDAGE"' EXIT

# L'IMPORT D'ABORD, ET CE N'EST PAS UNE PRÉCAUTION DE CONFORT.
# Mesuré le 2026-08-21 dans un conteneur neuf : lancer la suite SANS `--import`
# préalable produit des milliers de `SCRIPT ERROR: Invalid call. Nonexistent
# function 'seat' in base 'GDScript'` — 5 614 sur le seul `test_basin_placement`.
# Les classes globales (`KitPlacement`, `AssetRegistry`, `HudStyle`…) se
# résolvent en `GDScript` nu au lieu de leur type, parce que le cache de classes
# globales n'a pas été régénéré. `validate_fast` importe à son étape 1 et n'a
# donc jamais ce visage — mais un outil lancé seul, si. Mesurer un état dégradé
# et le publier comme la composition du dépôt serait une fausse preuve.
echo "=== import préalable (régénère le cache de classes globales) ==="
tools/lancer_godot.sh --attente=7200 --headless --path . --import \
  > "${TMPDIR:-/tmp}/composition_import.log" 2>&1
RC_IMPORT=$?
echo "  import : code $RC_IMPORT"
# IMPRIMER UN CODE N'EST PAS LE TESTER. Si `lancer_godot.sh` sort en 3 (verrou
# expiré), l'import n'a pas eu lieu, et la suite `--verbose` mesurerait
# exactement l'état dégradé que le commentaire ci-dessus décrit comme une fausse
# preuve. `tools/CLAUDE.md` porte déjà la règle : tester le RC après tout
# `flock`, s'arrêter au premier échec. Trouvé par la revue contradictoire.
if [ $RC_IMPORT -ne 0 ]; then
  echo "BLOQUÉ : l'import a échoué (code $RC_IMPORT) — sans lui, la composition" >&2
  echo "         mesurée serait celle d'un cache de classes périmé." >&2
  exit 3
fi

echo "=== suite complète en --verbose (comptez ~20 min) ==="
DEBUT=$(date +%s)
tools/lancer_godot.sh --attente=7200 --headless --path . --verbose \
  --script tools/godot/test_runner.gd > "$VIDAGE" 2>&1
RC_SUITE=$?
DUREE=$(( $(date +%s) - DEBUT ))
echo "  suite : code $RC_SUITE en ${DUREE}s, vidage $(stat -c%s "$VIDAGE") octets"
grep -E '^=== RÉSULTAT' "$VIDAGE" | sed 's/^/  /'

# Extraction SANS jugement : on sélectionne les lignes que le moteur imprime sur
# le sujet, on n'en retire aucune.
BRUT="$SORTIE/fuite_brute.log"
grep -E 'Leaked instance:|Resource still in use:|ObjectDB instances were leaked|resources still in use|RID allocations' \
  "$VIDAGE" > "$BRUT" || true
echo "  $(wc -l < "$BRUT") ligne(s) de rapport de fuite conservées : $BRUT"

# Le vidage complet ne survit pas : c'est sa DÉCOMPOSITION qui vaut d'être gardée.
ARGS=(--racine . --reference docs/contrats/residu_cache_moteur.json
      --json "$SORTIE/verdict.json")
[ $ENTERINER -eq 1 ] && ARGS+=(--ecrire-reference docs/contrats/residu_cache_moteur.json)
python3 tools/gate_fuite_ressources.py "$BRUT" "${ARGS[@]}" | tee "$SORTIE/verdict.txt"
RC=${PIPESTATUS[0]}

{
  echo
  echo "suite : code $RC_SUITE, ${DUREE}s"
  echo "portail : code $RC  (0 vert · 1 ressource du projet · 2 dérive télémétrie · 3 bloqué)"
} >> "$SORTIE/verdict.txt"
exit $RC
