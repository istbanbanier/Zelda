# shellcheck shell=bash
# =============================================================================
# tools/lib/godot_env.sh — LA définition unique du verrou et de la cloison.
#
# POURQUOI CE FICHIER EXISTE (ISS-063, R2B.3.1)
# ---------------------------------------------
# `tools/lancer_godot.sh` faisait déjà les deux gestes correctement. Il ne
# suffisait pas : l'inventaire du 2026-08-20
# (`evidence/world_v2/v2_3_r2b3_1/iss063/INVENTAIRE_POINTS_ENTREE.md`) a compté
# **13 fichiers et 35 sites** qui lancent le moteur, dont **11 fichiers ne
# passaient par aucun des deux**. Un correctif qui vit dans un lanceur ne
# protège que ceux qui appellent le lanceur.
#
# Les deux gestes sont DIFFÉRENTS et aucun ne remplace l'autre :
#
#   VERROU   sérialise dans le TEMPS. Empêche deux moteurs de saturer la
#            machine et de se disputer `.godot/imported`.
#   CLOISON  sépare dans l'ESPACE. `user://` ne dérive PAS du répertoire de
#            travail mais de `application/config/name` : sans
#            `XDG_DATA_HOME`, tous les arbres de travail écrivent dans le même
#            `~/.local/share/godot/app_userdata/Eclats d'Orage`. Deux runners
#            y ont déjà FABRIQUÉ huit échecs de sauvegarde qui n'existaient
#            pas (2026-08-11, `tools/CLAUDE.md`).
#
# Le verrou seul ne protège pas d'un survivant lancé hors verrou ; la cloison,
# si. La cloison seule ne protège pas de la contention CPU ; le verrou, si.
#
# DEUX DURÉES DE VIE DE CLOISON, ET C'EST VOULU
# ---------------------------------------------
#   ÉPHÉMÈRE  (`godot_cloison_ephemere`) : un `user://` neuf par invocation,
#             effacé à la sortie. C'est ce qu'il faut pour une MESURE : un
#             résidu de l'exécution précédente fausserait la suivante.
#   D'ARBRE   (`godot_cloison_arbre`) : un `user://` stable par arbre de
#             travail. C'est ce qu'il faut pour une SUITE en plusieurs étapes,
#             dont une étape écrit ce qu'une autre relit (sauvegardes,
#             captures). Isolé des autres arbres, conservé entre les étapes.
#
# USAGE
#   . "$(dirname "$0")/lib/godot_env.sh"       # depuis tools/
#   . "$(dirname "$0")/../lib/godot_env.sh"    # depuis tools/godot/
#   godot_cloison_arbre                        # exporte XDG_DATA_HOME
#   godot_verrou_prendre 8 3000                # descripteur 8, attente 3000 s
#
# Le descripteur est un ARGUMENT parce que `validate_fast.sh` en tient déjà un
# autre sur 9 : deux verrous imbriqués ne peuvent pas partager un descripteur.
# =============================================================================

## Racine de l'arbre de travail courant, ou le répertoire courant si git est
## absent. Jamais un chemin relatif.
godot_racine() {
  local r
  r="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$r" ] || r="$PWD"
  printf '%s\n' "$r"
}


## Chemin du verrou CANONIQUE. Il suit le DÉPÔT (`--git-common-dir`, le `.git`
## PARTAGÉ entre arbres de travail), pas le répertoire : deux arbres partagent
## `.godot/imported` et le `user://` par défaut, donc leurs moteurs doivent se
## sérialiser. Dans un arbre de travail, `.git` est un FICHIER — `flock` sur
## `.git/x.lock` y répond « Not a directory » puis « Bad file descriptor ».
godot_verrou_chemin() {
  local racine dir
  racine="$(godot_racine)"
  dir="$(git -C "$racine" rev-parse --git-common-dir 2>/dev/null || true)"
  case "$dir" in
    "") dir="$racine/.git" ;;
    /*) ;;
    *)  dir="$racine/$dir" ;;
  esac
  printf '%s\n' "$dir/heavy_tools.lock"
}


## Prend le verrou canonique sur le descripteur demandé. Sort en 3 — « rien n'a
## tourné » — si le verrou n'est pas obtenu.
##
## PIÈGE MESURÉ, ne pas simplifier : le verrou est pris SUR LE DESCRIPTEUR,
## séparément de la commande. Avec `flock -w N fichier commande`, un code 1 peut
## venir de l'expiration OU de la commande, et rien ne les distingue — deux vues
## ont déjà été perdues ainsi (2026-08-19). Et l'ouverture est enfermée dans un
## groupe : `exec 9>f 2>/dev/null` sans groupe éteint stderr pour TOUT LE RESTE
## du script, ce qui rend un blocage silencieux.
godot_verrou_prendre() {
  local fd="${1:?descripteur attendu}" attente="${2:-3000}" fichier
  fichier="$(godot_verrou_chemin)"
  if ! { eval "exec ${fd}>\"\$fichier\""; } 2>/dev/null; then
    echo "BLOQUÉ: impossible d'ouvrir le verrou « $fichier »." >&2
    echo "        Dans un arbre de travail, .git est un FICHIER : vérifier que" >&2
    echo "        git rev-parse --git-common-dir répond." >&2
    echo "        RIEN N'A TOURNÉ." >&2
    return 3
  fi
  if ! flock -w "$attente" "$fd"; then
    echo "BLOQUÉ: verrou « $fichier » non obtenu après ${attente} s." >&2
    echo "        RIEN N'A TOURNÉ : aucun fichier écrit, aucune mesure prise." >&2
    echo "        Un autre outil lourd le tient (une suite d'intégration le" >&2
    echo "        garde ~50 min) — attendre sa fin." >&2
    return 3
  fi
  export GODOT_VERROU_PRIS="$fichier"
  return 0
}


## Cloison STABLE par arbre de travail. Exporte `XDG_DATA_HOME`.
## `user://` devient `<arbre>/.godot_user/godot/app_userdata/Eclats d'Orage`.
## Ignoré par git (`.gitignore`) : c'est de l'état de machine, pas du dépôt.
godot_cloison_arbre() {
  local racine
  racine="$(godot_racine)"
  XDG_DATA_HOME="$racine/.godot_user"
  mkdir -p "$XDG_DATA_HOME" || {
    echo "BLOQUÉ: impossible de créer la cloison « $XDG_DATA_HOME »." >&2
    return 3
  }
  export XDG_DATA_HOME
}


## Cloison ÉPHÉMÈRE : un `user://` neuf, effacé par le `trap` posé ici même.
## À réserver aux mesures. Le garde-fou `case` refuse d'effacer autre chose que
## notre propre `mktemp` — un `rm -rf` sur une variable vide efface la racine.
godot_cloison_ephemere() {
  local dir
  dir="$(mktemp -d /tmp/godot_env_ud_XXXXXXXX)" || {
    echo "BLOQUÉ: mktemp -d a échoué, pas de user:// isolé possible." >&2
    return 3
  }
  GODOT_CLOISON_EPHEMERE="$dir"
  XDG_DATA_HOME="$dir"
  export XDG_DATA_HOME GODOT_CLOISON_EPHEMERE
  trap 'godot_cloison_menage' EXIT
  trap 'godot_cloison_menage; exit 130' INT
  trap 'godot_cloison_menage; exit 143' TERM
  trap 'godot_cloison_menage; exit 129' HUP
}


godot_cloison_menage() {
  case "${GODOT_CLOISON_EPHEMERE:-}" in
    /tmp/godot_env_ud_*) rm -rf -- "$GODOT_CLOISON_EPHEMERE" ;;
  esac
  GODOT_CLOISON_EPHEMERE=""
}
