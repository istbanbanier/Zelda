#!/usr/bin/env bash
# Matrice de scénarios ISS-059 exigée par la directive R2B.3.1 §1 :
# témoin · chacune des trois scènes isolément · toutes les paires · les trois
# ensemble · deux cycles consécutifs dans le même processus.
#
# Chaque invocation passe par tools/lancer_godot.sh : verrou canonique du
# dépôt + XDG_DATA_HOME isolé (ISS-063). Le RC est relevé et publié — un RC
# non nul veut dire RIEN MESURÉ, jamais « zéro fuite ».
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2
SORTIE="${1:?usage: matrice_iss059.sh <dossier_sortie> [cycles] [ablation]}"
CYCLES="${2:-1}"
ABLATION="${3:-aucune}"
mkdir -p "$SORTIE"

mesurer() {
  local nom="$1" scenes="$2"
  local log="$SORTIE/${nom}.log"
  local t0 t1
  t0=$(date +%s)
  tools/lancer_godot.sh --attente=3000 --headless --path . \
    --script tools/godot/sonde_iss059_proprietaire.gd -- \
    "--scenes=${scenes}" "--cycles=${CYCLES}" "--ablation=${ABLATION}" --detail=oui \
    > "$log" 2>&1
  local rc=$?
  t1=$(date +%s)
  local rcg
  rcg=$(grep -o 'RC_GODOT=[0-9]*' "$log" | tail -1)
  local fini
  fini=$(grep -c '^=== SONDE TERMINEE ===' "$log")
  printf '%-22s rc_env=%-3s %-12s termine=%s duree=%ss\n' \
    "$nom" "$rc" "${rcg:-RC_GODOT=?}" "$fini" "$((t1 - t0))"
}

echo "### matrice ISS-059 — cycles=$CYCLES ablation=$ABLATION"
mesurer temoin            aucune
mesurer seul_worldv2      worldv2
mesurer seul_bootstrap    bootstrap
mesurer seul_pylone       pylone
mesurer paire_wv_boot     worldv2+bootstrap
mesurer paire_wv_pyl      worldv2+pylone
mesurer paire_boot_pyl    bootstrap+pylone
mesurer trio              worldv2+bootstrap+pylone
