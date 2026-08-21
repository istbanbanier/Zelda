#!/usr/bin/env bash
# Un ARBRE DE TRAVAIL SÉPARÉ PAR VOIE — CLAUDE.md « Démarrage de session ».
#
# Réponse structurelle au dégât du 2026-08-07 : cinq branches divergentes, aucune
# contenant plus de deux des six morceaux de travail. Le travail en cours d'une
# voie ne contamine jamais la branche d'une autre, et l'arbre principal ne bouge
# pas sous les pieds du lead pendant qu'il arbitre.
#
#   tools/worktree_lot.sh creer <base_sha> voie_a voie_b voie_c
#   tools/worktree_lot.sh lister
#   tools/worktree_lot.sh retirer voie_a
#
# Les arbres vivent HORS du dépôt (/home/user/wt-<voie>) pour qu'aucun outil du
# dépôt ne les prenne pour du contenu. Ils partagent `.git`, donc le verrou
# `heavy_tools.lock` et `validate_fast.lock` les sérialisent déjà — c'est voulu :
# trois Godot simultanés se disputeraient `user://`. La CLOISON `.godot_user`,
# elle, est par arbre : chacun écrit ses sauvegardes chez lui.
set -uo pipefail
cd "$(dirname "$0")/.."
RACINE_WT="${RACINE_WT:-/home/user}"

case "${1:-}" in
  creer)
    base="${2:?SHA de base requis}"
    shift 2
    [ $# -gt 0 ] || { echo "au moins une voie requise" >&2; exit 2; }
    if ! git rev-parse --verify "$base^{commit}" >/dev/null 2>&1; then
      echo "SHA de base introuvable : $base" >&2; exit 2
    fi
    for voie in "$@"; do
      cible="$RACINE_WT/wt-$voie"
      if [ -e "$cible" ]; then
        echo "  [DÉJÀ LÀ] $cible"; continue
      fi
      # --detach : la voie n'a PAS de branche à elle. Une branche invite à
      # pousser ; la directive interdit tout push d'agent. Le lead cueille les
      # commits par cherry-pick, sans merge commit.
      git worktree add --detach "$cible" "$base" >/dev/null 2>&1 \
        && echo "  [CRÉÉ] $cible sur ${base:0:8} (détaché)" \
        || echo "  [ÉCHEC] $cible"
    done
    ;;
  lister)
    git worktree list
    ;;
  retirer)
    for voie in "${@:2}"; do
      cible="$RACINE_WT/wt-$voie"
      git worktree remove --force "$cible" 2>/dev/null \
        && echo "  [RETIRÉ] $cible" || echo "  [ABSENT] $cible"
    done
    git worktree prune
    ;;
  *)
    echo "usage: $0 {creer <sha> <voie>...|lister|retirer <voie>...}" >&2
    exit 2
    ;;
esac
