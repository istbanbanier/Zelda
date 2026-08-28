#!/usr/bin/env bash
# =============================================================================
# tools/gate_export_iss073.sh — LA BOUCLE, DANS LA BUILD EXPORTÉE
#
# POURQUOI CE PORTAIL EXISTE
# --------------------------
# Les deux suites `--filter=iss073` prouvent la boucle DANS L'ÉDITEUR. ISS-071
# a montré exactement ce que vaut cet angle : `DirAccess.get_files()` ne rend
# pas les sources d'un PCK, 1 094 placements échouaient sans planter, et
# AUCUNE suite du dépôt ne pouvait le voir. Un correctif validé en éditeur
# seul referme le même angle mort.
#
# Ce portail lance donc le BINAIRE AUTONOME, en installation neuve, appuie sur
# « Nouvelle partie » par le focus X, et lit ce que le jeu dit de lui-même :
#
#     [world_v2] porte donjon : posée au seuil §3.3
#     [world_v2] arrivée      : spawn
#     [world_v2] lieux        : 15 scène(s) posée(s) par le layout
#
# CE QU'IL NE PROUVE PAS, et qu'aucun verdict vert ne doit laisser croire :
# que le joueur MARCHE jusqu'à la porte. Ce conteneur rend en logiciel et son
# horloge de jeu est découplée du temps réel d'un facteur 17 à 76 (ISS-072) ;
# 380 m de marche y coûteraient des dizaines de minutes de mur pour une mesure
# qu'aucun budget ne rendrait crédible. La marche est prouvée en éditeur ; le
# PACKAGING est prouvé ici ; le PLAISIR n'est prouvé par ni l'un ni l'autre et
# attend l'essai d'Istvan.
#
# Le binaire est celui que `tools/gate_export_parite.sh` vient de produire :
# ce portail ne réexporte rien, il MESURE l'artefact déjà bâti, et refuse de
# tourner si son SHA enregistré n'est pas le HEAD courant.
#
# Codes : 0 = VERT · 1 = ROUGE · 3 = BLOQUÉ (une étape n'a pas pu tourner).
#
# Usage :
#   tools/gate_export_iss073.sh [--sortie <dir hors arbre>] [--display :NN]
#   # TOUJOURS rediriger : un tube masque le code retour.
# =============================================================================
set -u -o pipefail

ARBRE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ARBRE" || { echo "BLOQUÉ: cd $ARBRE impossible" >&2; echo "RC=3"; exit 3; }
SORTIE="${GATE_SORTIE:-/home/user/wt-a-out}"
DISPLAY_NUM="${GATE_DISPLAY:-:93}"
LARGEUR=1024
HAUTEUR=768
TITRE_FENETRE="Eclats d'Orage"
DELAI_FENETRE=120
DELAI_JALON=900
# Compte EXACT attendu, écrit ICI en littéral. Un oracle qui lit sa réponse
# chez le sujet ne peut pas échouer (PROMPT4_METHOD §2).
LIEUX_ATTENDUS=15

while [ $# -gt 0 ]; do
  case "$1" in
    --sortie)  SORTIE="$2"; shift 2 ;;
    --display) DISPLAY_NUM="$2"; shift 2 ;;
    *) echo "argument inconnu : $1" >&2; echo "RC=3"; exit 3 ;;
  esac
done

PID_JEU=""
PID_XVFB=""
CODE=3
etape() { echo; echo "### $*"; }
info()  { echo "    $*"; }
fini()  { CODE="$1"; exit "$CODE"; }

menage() {
  # JAMAIS de `pkill` global : le 2026-08-11 il a laissé trois godot vivants
  # qui ont fabriqué huit échecs de sauvegarde inexistants. On tue par PID
  # enregistré, et on vérifie la mort.
  if [ -n "$PID_JEU" ] && kill -0 "$PID_JEU" 2>/dev/null; then
    kill -TERM "$PID_JEU" 2>/dev/null || true
    for _ in $(seq 1 20); do kill -0 "$PID_JEU" 2>/dev/null || break; sleep 1; done
    kill -0 "$PID_JEU" 2>/dev/null && kill -KILL "$PID_JEU" 2>/dev/null || true
  fi
  if [ -n "$PID_XVFB" ] && kill -0 "$PID_XVFB" 2>/dev/null; then
    kill -TERM "$PID_XVFB" 2>/dev/null || true
    sleep 1
    kill -0 "$PID_XVFB" 2>/dev/null && kill -KILL "$PID_XVFB" 2>/dev/null || true
  fi
  echo
  echo "=== VERDICT PORTAIL EXPORT ISS-073 : code $CODE"
  mkdir -p "$SORTIE" 2>/dev/null || true
  printf 'RC=%s\n' "$CODE" > "$SORTIE/VERDICT_ISS073" 2>/dev/null || true
  printf 'RC=%s\n' "$CODE"
}
trap 'menage' EXIT
trap 'CODE=130; exit 130' INT
trap 'CODE=143; exit 143' TERM

SHA="$(git rev-parse HEAD)"
BINAIRE="$SORTIE/build/EclatsDOrage.x86_64"
JOURNAUX="$SORTIE/journaux"; mkdir -p "$JOURNAUX"
JOURNAL_JEU="$JOURNAUX/iss073_jeu_exporte.log"
PROFIL_VIERGE="$SORTIE/profil_vierge_iss073"

etape "1. l'artefact mesuré est-il bien CELUI du commit courant ?"
if [ ! -x "$BINAIRE" ]; then
  echo "BLOQUÉ: binaire absent : $BINAIRE" >&2
  echo "        Lancer d'abord tools/gate_export_parite.sh." >&2
  fini 3
fi
SHA_ENREG="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['sha_git_teste'])" \
  "$SORTIE/contexte.json" 2>/dev/null || echo "")"
if [ "$SHA_ENREG" != "$SHA" ]; then
  echo "BLOQUÉ: le binaire présent a été bâti sur « $SHA_ENREG », le HEAD est" >&2
  echo "        « $SHA ». Mesurer un artefact périmé en croyant mesurer le" >&2
  echo "        code courant est la famille de fautes la plus coûteuse de ce" >&2
  echo "        dépôt (ISS-018)." >&2
  fini 3
fi
info "sha git    : $SHA"
info "binaire    : $BINAIRE"
info "octets     : $(stat -c%s "$BINAIRE")"
info "sha256     : $(sha256sum "$BINAIRE" | cut -d' ' -f1)"

etape "2. installation NEUVE — ni sauvegarde, ni option, ni cache"
rm -rf "$PROFIL_VIERGE"; mkdir -p "$PROFIL_VIERGE"
RESTANT="$(find "$PROFIL_VIERGE" -mindepth 1 | wc -l)"
info "profil vierge : $PROFIL_VIERGE ($RESTANT entrée(s), 0 attendu)"
[ "$RESTANT" -eq 0 ] || { echo "BLOQUÉ: profil non vierge" >&2; fini 3; }

etape "3. Xvfb + lancement de la build AUTONOME"
command -v Xvfb  >/dev/null || { echo "BLOQUÉ: Xvfb absent" >&2; fini 3; }
command -v xdotool >/dev/null || { echo "BLOQUÉ: xdotool absent" >&2; fini 3; }
rm -f "/tmp/.X${DISPLAY_NUM#:}-lock"
Xvfb "$DISPLAY_NUM" -screen 0 "${LARGEUR}x${HAUTEUR}x24" \
  > "$JOURNAUX/iss073_xvfb.log" 2>&1 &
PID_XVFB=$!
sleep 3
kill -0 "$PID_XVFB" 2>/dev/null || { echo "BLOQUÉ: Xvfb mort" >&2; fini 3; }
info "Xvfb PID $PID_XVFB sur $DISPLAY_NUM"

rm -f "$JOURNAL_JEU"
# `stdbuf -oL -eL` : une build RELEASE ne vide pas son tampon stdout
# (`flush_stdout_on_print` est faux hors debug) et Godot n'a aucun handler
# SIGTERM — sans stdbuf, l'arrêt DÉTRUIT les jalons déjà imprimés et le
# portail rougit sur une exécution verte.
DISPLAY="$DISPLAY_NUM" XDG_DATA_HOME="$PROFIL_VIERGE" HOME="$PROFIL_VIERGE" \
  stdbuf -oL -eL "$BINAIRE" \
    --rendering-driver opengl3 \
    --resolution "${LARGEUR}x${HAUTEUR}" --windowed \
  > "$JOURNAL_JEU" 2>&1 &
PID_JEU=$!
info "jeu PID $PID_JEU ; journal $JOURNAL_JEU"

etape "4. « Nouvelle partie » — par le FOCUS X, jamais par --window"
FENETRE=""
for _ in $(seq 1 "$DELAI_FENETRE"); do
  if ! kill -0 "$PID_JEU" 2>/dev/null; then
    echo "BLOQUÉ: le jeu s'est arrêté avant d'ouvrir sa fenêtre." >&2
    tail -40 "$JOURNAL_JEU" >&2
    fini 3
  fi
  FENETRE="$(DISPLAY="$DISPLAY_NUM" xdotool search --onlyvisible \
    --name "$TITRE_FENETRE" 2>/dev/null | tail -1)"
  [ -n "$FENETRE" ] && break
  sleep 1
done
[ -n "$FENETRE" ] || { echo "BLOQUÉ: fenêtre introuvable" >&2; tail -40 "$JOURNAL_JEU" >&2; fini 3; }
info "fenêtre : $FENETRE"
# Godot lit le clavier par le FOCUS X : `xdotool key --window <id>` est ignoré
# SANS AUCUNE ERREUR, et l'on chercherait le défaut ailleurs.
DISPLAY="$DISPLAY_NUM" xdotool windowfocus --sync "$FENETRE" 2>/dev/null || true
DISPLAY="$DISPLAY_NUM" xdotool windowraise "$FENETRE" 2>/dev/null || true
sleep 4
DISPLAY="$DISPLAY_NUM" import -window root "$SORTIE/iss073_01_menu.png" 2>/dev/null || true
DISPLAY="$DISPLAY_NUM" xdotool windowfocus --sync "$FENETRE" 2>/dev/null || true
DISPLAY="$DISPLAY_NUM" xdotool key Return
info "Return envoyé par le focus"

etape "5. attente du jalon de montage"
JALON="fondation V2 vérifiée"
TROUVE=0
for _ in $(seq 1 "$DELAI_JALON"); do
  if grep -qF "$JALON" "$JOURNAL_JEU" 2>/dev/null; then TROUVE=1; break; fi
  if ! kill -0 "$PID_JEU" 2>/dev/null; then
    echo "BLOQUÉ: le jeu s'est arrêté avant le jalon « $JALON »." >&2
    tail -60 "$JOURNAL_JEU" >&2
    fini 3
  fi
  sleep 1
done
[ "$TROUVE" -eq 1 ] || {
  echo "BLOQUÉ: jalon « $JALON » absent après ${DELAI_JALON}s — les constats" >&2
  echo "        seraient PARTIELS, et un zéro y voudrait dire « pas encore" >&2
  echo "        monté », pas « rien ne manque »." >&2
  tail -60 "$JOURNAL_JEU" >&2
  fini 3
}
info "jalon : $(grep -F "$JALON" "$JOURNAL_JEU" | head -1)"
sleep 5
DISPLAY="$DISPLAY_NUM" import -window root "$SORTIE/iss073_02_monde.png" 2>/dev/null || true

etape "6. les constats ISS-073, lus dans ce que le jeu dit de LUI-MÊME"
ECHECS=0
constat() {  # $1 = libellé, $2 = 0/1
  if [ "$2" -eq 0 ]; then
    echo "    [PASS] $1"
  else
    echo "    [FAIL] $1"
    ECHECS=$((ECHECS + 1))
  fi
}

LIGNE_PORTE="$(grep -F "[world_v2] porte donjon" "$JOURNAL_JEU" | head -1 || true)"
info "ligne lue : ${LIGNE_PORTE:-<ABSENTE>}"
case "$LIGNE_PORTE" in
  *"posée au seuil"*) constat "la porte du donjon est POSÉE dans la build exportée" 0 ;;
  "")                 constat "la porte du donjon : ligne de jalon ABSENTE" 1 ;;
  *)                  constat "la porte du donjon est ABSENTE dans la build exportée" 1 ;;
esac

LIGNE_ARRIVEE="$(grep -F "[world_v2] arrivée" "$JOURNAL_JEU" | head -1 || true)"
info "ligne lue : ${LIGNE_ARRIVEE:-<ABSENTE>}"
case "$LIGNE_ARRIVEE" in
  *"spawn"*) constat "une partie NEUVE arrive bien au point d'apparition" 0 ;;
  "")        constat "provenance d'arrivée : ligne de jalon ABSENTE" 1 ;;
  *)         constat "provenance d'arrivée inattendue pour une partie neuve" 1 ;;
esac

LIGNE_LIEUX="$(grep -F "[world_v2] lieux" "$JOURNAL_JEU" | head -1 || true)"
NB_LIEUX="$(printf '%s' "$LIGNE_LIEUX" | grep -oE '[0-9]+' | head -1 || true)"
info "ligne lue : ${LIGNE_LIEUX:-<ABSENTE>}"
if [ "${NB_LIEUX:-x}" = "$LIEUX_ATTENDUS" ]; then
  constat "les $LIEUX_ATTENDUS lieux du layout sont posés (ISS-071 ne rechute pas)" 0
else
  constat "lieux posés : ${NB_LIEUX:-aucun} au lieu de $LIEUX_ATTENDUS" 1
fi

# La citadelle est le seul repère de la porte : si le monde ne la pose pas,
# le seuil est atteignable mais illisible.
if grep -qF "[world_v2] fondation V2 vérifiée" "$JOURNAL_JEU"; then
  constat "le monde s'est monté jusqu'au bout" 0
else
  constat "montage incomplet" 1
fi

# Aucune erreur de script pendant le montage : ISS-071 échouait EN SILENCE,
# donc l'absence de plantage ne suffit pas — on lit les erreurs.
NB_ERR="$(grep -cE "SCRIPT ERROR|Cannot open file|res://.*\.gltf.*ERROR" "$JOURNAL_JEU" || true)"
info "erreurs de script/ressource dans le journal : $NB_ERR"
if [ "${NB_ERR:-0}" -eq 0 ]; then
  constat "aucune erreur de script ni de ressource au montage" 0
else
  grep -E "SCRIPT ERROR|Cannot open file" "$JOURNAL_JEU" | head -10
  constat "$NB_ERR erreur(s) de script/ressource au montage" 1
fi

etape "7. verdict"
if [ "$ECHECS" -eq 0 ]; then
  info "tous les constats sont PASS"
  fini 0
fi
info "$ECHECS constat(s) en FAIL"
fini 1
