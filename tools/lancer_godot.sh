#!/usr/bin/env bash
# =============================================================================
# tools/lancer_godot.sh — l'enveloppe UNIQUE par laquelle tout lancement de
# Godot passe dans ce dépôt.
#
# POURQUOI CE FICHIER EXISTE (ISS-063)
# ------------------------------------
# `user://` ne dérive PAS du répertoire de travail : il dérive de
# `application/config/name`, identique dans tous les arbres de travail. Mesuré
# dans ce conteneur, le 2026-08-20 :
#
#   sans XDG_DATA_HOME  -> /root/.local/share/godot/app_userdata/Eclats d'Orage
#   XDG_DATA_HOME=/tmp/ud_probe_A -> /tmp/ud_probe_A/godot/app_userdata/Eclats d'Orage
#
# Autrement dit : TOUS les worktrees partageaient un seul `user://`. Deux
# runners simultanés y écrivaient la même sauvegarde, et ont FABRIQUÉ un échec
# de sauvegarde qui n'existait pas — 8 échecs le 2026-08-11, alors que les
# mêmes tests passaient 6/6 isolément (tools/CLAUDE.md). Le défaut n'était pas
# dans le jeu : il était dans la façon de lancer le moteur.
#
# Il y a TROIS mutex distincts dans ce dépôt, et les confondre coûte une passe :
#
#   1. `validate_fast.lock`  — sérialise les suites complètes (flock -n, sort 3).
#   2. `heavy_tools.lock`    — sérialise TOUT usage lourd de Godot/Blender,
#                              quel que soit l'arbre. C'est celui d'ici.
#   3. XDG_DATA_HOME         — n'est PAS un verrou : c'est un CLOISON. Un verrou
#                              sérialise dans le temps, la cloison sépare dans
#                              l'espace. Le verrou seul ne protège pas d'un
#                              survivant lancé hors verrou ; la cloison, si.
#
# Les deux sont nécessaires, aucun ne remplace l'autre : le verrou empêche deux
# moteurs de saturer la machine, la cloison empêche le second de lire les restes
# du premier.
#
# CE QUE CE SCRIPT ATTRAPE, ET QUI A DÉJÀ COÛTÉ DU TEMPS
# ------------------------------------------------------
#   * `flock -w N` qui EXPIRE rend 1 et N'EXÉCUTE PAS la commande. Une boucle
#     qui ne teste pas ce code imprime l'en-tête suivant et ressemble
#     exactement à une progression normale : deux vues perdues sans un message
#     d'erreur (2026-08-19). Ici le verrou est pris sur un descripteur, SÉPARÉMENT
#     de la commande : un échec de verrou ne peut donc plus être confondu avec
#     un échec de la commande.
#   * dans un arbre de travail, `.git` est un FICHIER : `flock .git/x.lock` rend
#     « Not a directory » puis « Bad file descriptor », donc BLOQUÉ alors que
#     rien ne tourne. Le verrou suit le DÉPÔT (`--git-common-dir`, le .git
#     PARTAGÉ), jamais le répertoire.
#   * `--filtre=` n'existe pas : le runner lit `--filter=`. Un drapeau inconnu
#     est IGNORÉ EN SILENCE et la suite ENTIÈRE part (~1 h). Refusé ici.
#   * `--headless` DÉSACTIVE le rendu : toute capture doit passer par `--rendu`,
#     qui enveloppe dans xvfb-run et retire `--headless` s'il traîne.
#
# USAGE
# -----
#   tools/lancer_godot.sh [options de l'enveloppe] <arguments godot...>
#
# Les options de l'enveloppe viennent EN PREMIER. Le parsing s'arrête au premier
# argument inconnu : tout le reste part verbatim vers Godot, `--` compris — car
# `--` appartient à Godot (il sépare ses arguments de ceux du script) et
# l'enveloppe n'a pas le droit de le lui voler.
#
#   --rendu            xvfb-run + retrait de --headless (captures, screenshots)
#   --ecran=WxHxD      géométrie du serveur X virtuel (défaut 1280x720x24)
#   --attente=SEC      délai d'attente du verrou (défaut 3000 s ; une suite
#                      d'intégration tient le verrou ~50 min)
#   --garder-user      NE PAS effacer le user:// temporaire, et imprimer son
#                      chemin (à utiliser quand la preuve vit dans user://)
#   --aide             cette aide
#
# EXEMPLES
#   tools/lancer_godot.sh --path . --import
#   tools/lancer_godot.sh --path . --script tools/godot/test_runner.gd -- --filter=stamina
#   tools/lancer_godot.sh --rendu --path . --script tools/godot/capture_reference.gd
#
# CODES RETOUR
#   0..N  code retour de Godot (la commande A TOURNÉ ; jeton `RC_GODOT=` imprimé)
#   2     usage refusé par l'enveloppe (la commande N'A PAS tourné)
#   3     BLOQUÉ : verrou non obtenu (la commande N'A PAS tourné)
#
# Distinguer un blocage d'un échec ne se fait donc PAS au code retour seul —
# Godot peut lui aussi rendre 3. Le jeton `RC_GODOT=` est écrit par l'enveloppe
# uniquement quand le moteur a réellement été lancé ; son ABSENCE est la preuve
# que rien n'a tourné. Même discipline que le jeton `^RC=` et le
# « FIN NOMINALE » de tools/CLAUDE.md : la preuve de succès est écrite par la
# chose surveillée, jamais déduite de son enveloppe.
# =============================================================================

# Pas de `set -e` : on doit capturer le code retour de Godot nous-mêmes.
set -uo pipefail

JETON="LANCER_GODOT:"
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- options de l'enveloppe ---------------------------------------------------
RENDU=0
ECRAN="1280x720x24"
ATTENTE=3000
GARDER_USER=0

while [ $# -gt 0 ]; do
  case "$1" in
    --rendu)        RENDU=1; shift ;;
    --garder-user)  GARDER_USER=1; shift ;;
    --ecran=*)      ECRAN="${1#--ecran=}"; shift ;;
    --attente=*)    ATTENTE="${1#--attente=}"; shift ;;
    --aide|-h|--help)
      sed -n '2,80p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) break ;;
  esac
done

if ! printf '%s' "$ATTENTE" | grep -Eq '^[0-9]+$'; then
  echo "$JETON REFUS: --attente doit être un entier de secondes (reçu « $ATTENTE »)." >&2
  echo "$JETON        La commande N'A PAS tourné." >&2
  exit 2
fi

if [ $# -eq 0 ]; then
  echo "$JETON REFUS: aucun argument pour Godot. Voir --aide." >&2
  echo "$JETON        La commande N'A PAS tourné." >&2
  exit 2
fi

# --- refus n°1 : le drapeau qui part en silence --------------------------------
# `--filtre=` (français) n'est pas lu par tools/godot/test_runner.gd, qui attend
# `--filter=`. Un drapeau inconnu ne provoque AUCUNE erreur : le runner lance la
# suite ENTIÈRE (~1 h) et le journal ressemble à une suite normale. Faute réelle,
# une heure perdue. `--filter` sans `=` tombe dans le même trou : le runner
# compare le préfixe `--filter=`, donc un `--filter foo` est également ignoré.
for a in "$@"; do
  case "$a" in
    --filtre|--filtre=*)
      echo "$JETON REFUS: « $a » n'existe pas. Le runner lit --filter= (anglais, avec =)." >&2
      echo "$JETON        Un drapeau inconnu est IGNORÉ EN SILENCE et la suite" >&2
      echo "$JETON        ENTIÈRE part (~1 h) en ayant l'air normale." >&2
      echo "$JETON        La commande N'A PAS tourné." >&2
      exit 2 ;;
    --filter)
      echo "$JETON REFUS: « --filter » sans « = » est ignoré en silence par le runner," >&2
      echo "$JETON        qui compare le préfixe « --filter= ». Écrire --filter=motif." >&2
      echo "$JETON        La commande N'A PAS tourné." >&2
      exit 2 ;;
  esac
done

# --- cloison : un user:// neuf par invocation ---------------------------------
# `mktemp -d` sous /tmp, préfixe reconnaissable pour que le ménage soit sûr.
USER_DIR="$(mktemp -d /tmp/lancer_godot_ud_XXXXXXXX)" || {
  echo "$JETON REFUS: mktemp -d a échoué, pas de user:// isolé possible." >&2
  echo "$JETON        La commande N'A PAS tourné." >&2
  exit 2
}

MENAGE_FAIT=0
menage() {
  [ "$MENAGE_FAIT" -eq 1 ] && return 0
  MENAGE_FAIT=1
  if [ "$GARDER_USER" -eq 1 ]; then
    echo "$JETON USER_DIR_CONSERVÉ=$USER_DIR" >&2
    return 0
  fi
  # Garde-fou : ne jamais rm -rf autre chose que notre propre mktemp.
  case "$USER_DIR" in
    /tmp/lancer_godot_ud_*) rm -rf -- "$USER_DIR" ;;
    *) echo "$JETON ALERTE: chemin user:// inattendu, non effacé : $USER_DIR" >&2 ;;
  esac
}
# Un répertoire oublié pourrit le conteneur en silence : nettoyer sur TOUTES
# les sorties, y compris une interruption.
trap menage EXIT
trap 'menage; exit 130' INT
trap 'menage; exit 143' TERM
trap 'menage; exit 129' HUP

# --- verrou : il suit le DÉPÔT, pas le répertoire ------------------------------
LOCK_DIR="$(git -C "$RACINE" rev-parse --git-common-dir 2>/dev/null || true)"
case "$LOCK_DIR" in
  "")  LOCK_DIR="$RACINE/.git" ;;   # repli si git est absent
  /*)  ;;                            # déjà absolu
  *)   LOCK_DIR="$RACINE/$LOCK_DIR" ;;  # relatif : le préfixer par la racine
esac
LOCK_FILE="$LOCK_DIR/heavy_tools.lock"

# ATTENTION, piège mesuré ici même le 2026-08-20 par lancer_godot_autotest.sh :
#   if ! exec 9>"$LOCK_FILE" 2>/dev/null; then
# `exec` SANS commande applique ses redirections au SHELL COURANT, et de façon
# PERMANENTE. Le `2>/dev/null` ne couvrait donc pas l'ouverture : il éteignait
# stderr pour TOUT LE RESTE DU SCRIPT. Conséquence exacte observée : un blocage
# de verrou sortait bien en 3, mais SANS UN SEUL MESSAGE — le journal était vide,
# et « rien n'a tourné » devenait indiscernable de « rien n'a été écrit ».
# Le groupe `{ ...; }` limite la redirection à sa durée ; le descripteur 9, lui,
# survit au groupe (un groupe n'est pas un sous-shell). Vérifié dans les deux
# sens : stderr reste vivant après, et la branche d'échec est bien atteinte.
if ! { exec 9>"$LOCK_FILE"; } 2>/dev/null; then
  echo "$JETON BLOQUÉ: impossible d'ouvrir le verrou « $LOCK_FILE »." >&2
  echo "$JETON        Dans un arbre de travail, .git est un FICHIER : vérifier" >&2
  echo "$JETON        que git rev-parse --git-common-dir répond." >&2
  echo "$JETON        La commande N'A PAS tourné." >&2
  exit 3
fi

# Le verrou est pris SUR LE DESCRIPTEUR, séparément de la commande. C'est la
# correction du piège : avec `flock -w N fichier commande`, un 1 peut venir de
# l'expiration OU de la commande, et rien ne les distingue.
if ! flock -w "$ATTENTE" 9; then
  echo "$JETON BLOQUÉ: verrou « $LOCK_FILE » non obtenu après ${ATTENTE} s." >&2
  echo "$JETON        LA COMMANDE GODOT N'A PAS TOURNÉ. Aucun fichier n'a été" >&2
  echo "$JETON        écrit, aucune mesure n'a été prise : ne rien conclure de" >&2
  echo "$JETON        cette exécution. Un autre outil lourd tient le verrou (une" >&2
  echo "$JETON        suite d'intégration le garde ~50 min) — attendre sa fin." >&2
  exit 3
fi

# --- construction de la ligne de commande --------------------------------------
ARGS=("$@")
if [ "$RENDU" -eq 1 ]; then
  # --headless DÉSACTIVE le rendu : le retirer, sinon la capture serait vide
  # tout en ayant l'air d'avoir marché.
  FILTRE=()
  RETIRE=0
  for a in "${ARGS[@]}"; do
    if [ "$a" = "--headless" ]; then RETIRE=1; continue; fi
    FILTRE+=("$a")
  done
  ARGS=("${FILTRE[@]}")
  [ "$RETIRE" -eq 1 ] && echo "$JETON --headless retiré (--rendu : le rendu doit être ACTIF)." >&2
  CMD=(xvfb-run -a -s "-screen 0 $ECRAN" "$GODOT_BIN" "${ARGS[@]}")
else
  # Sans --rendu, un Godot sans --headless cherche un affichage inexistant.
  A_HEADLESS=0
  for a in "${ARGS[@]}"; do [ "$a" = "--headless" ] && A_HEADLESS=1; done
  if [ "$A_HEADLESS" -eq 0 ]; then
    ARGS=(--headless "${ARGS[@]}")
    echo "$JETON --headless ajouté (pas de --rendu : aucun affichage disponible)." >&2
  fi
  CMD=("$GODOT_BIN" "${ARGS[@]}")
fi

# Rien n'est caché : la ligne réellement exécutée est imprimée.
echo "$JETON VERROU=$LOCK_FILE" >&2
echo "$JETON XDG_DATA_HOME=$USER_DIR" >&2
echo "$JETON CWD=$(pwd)" >&2
echo "$JETON CMD=${CMD[*]}" >&2

XDG_DATA_HOME="$USER_DIR" "${CMD[@]}"
RC=$?

# Jeton écrit UNIQUEMENT si le moteur a réellement été lancé. Son absence prouve
# que rien n'a tourné ; c'est ce qui distingue un BLOQUÉ d'un échec.
echo "$JETON RC_GODOT=$RC"
exit "$RC"
