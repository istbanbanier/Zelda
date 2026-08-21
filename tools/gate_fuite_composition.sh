#!/usr/bin/env bash
# ÉNUMÉRATION COMPLÈTE du résidu de fin de processus — le mode cher.
#
# `validate_fast` juge la SIGNATURE AGRÉGÉE, au chiffre près, pour quelques
# millisecondes. Ce script-ci juge la COMPOSITION : classe par classe, chemin par
# chemin, et il vérifie que l'ensemble mesuré égale l'ensemble expliqué.
#
# LE PRIX, mesuré le 2026-08-21 sur cette machine et non supposé :
#   suite sans --verbose ...... ~400 s,   journal de quelques Mo
#   suite avec --verbose ...... 1 249 s,  vidage de 420 Mo
# soit près du triple. C'est pourquoi il n'est PAS dans validate_fast : un
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
