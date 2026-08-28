#!/usr/bin/env bash
# =============================================================================
# tools/gate_export_t1.sh — LA REPRISE DE PARTIE, DANS LA BUILD EXPORTÉE
#
# POURQUOI CE PORTAIL EXISTE
# --------------------------
# Les dix contrats `--filter=t1_persistance` prouvent la persistance DANS
# L'ÉDITEUR. ISS-071 a montré ce que vaut cet angle seul : un défaut qui
# n'existe QUE dans une build exportée est invisible de toute suite d'éditeur.
# Ce portail lance donc le BINAIRE AUTONOME, six fois, contre des profils
# `user://` contrôlés, et lit ce que le jeu dit de lui-même :
#
#     [world_v2] arrivée      : spawn | sauvegarde
#     [world_v2] héros posé   : (x, y, z) lacet=r
#     [flow] transition vers : res://…
#
# CE QU'IL NE PROUVE PAS, dit d'avance pour qu'aucun vert ne le laisse croire :
#   - la MARCHE jusqu'au donjon (ISS-072 : l'horloge de jeu de ce conteneur est
#     découplée du mur d'un facteur 17-76 — 380 m y sont infaisables) ;
#   - la mort puis « Réessayer » (aucune source de dégâts atteignable en V2 —
#     ISS-074 : zéro adversaire) — prouvé en éditeur par C7 ;
#   - le retour donjon → monde en export (même raison que la marche).
# Ces trois-là sont ÉDITEUR-SEULEMENT, et le verdict final le répète.
#
# Le binaire est celui de `tools/gate_export_parite.sh` : ce portail ne
# réexporte rien, il MESURE l'artefact bâti, et refuse un SHA périmé.
#
# Codes : 0 = VERT · 1 = ROUGE · 3 = BLOQUÉ.
# Usage : tools/gate_export_t1.sh [--sortie <dir>] [--display :NN]
#         # TOUJOURS rediriger : un tube masque le code retour.
# =============================================================================
set -u -o pipefail

ARBRE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ARBRE" || { echo "BLOQUÉ: cd $ARBRE impossible" >&2; echo "RC=3"; exit 3; }
SORTIE="${GATE_SORTIE:-/home/user/wt-a-out}"
DISPLAY_NUM="${GATE_DISPLAY:-:94}"
LARGEUR=1024
HAUTEUR=768
TITRE_FENETRE="Eclats d'Orage"
DELAI_FENETRE=120
DELAI_JALON=900
# Marche tenue au mur : avec le découplage 17-76x, 90 s de mur donnent
# environ 1 à 5 s de jeu — soit 6 à 30 m de course. Le seuil de déplacement
# est volontairement bas (1 m) : on prouve que l'AVATAR BOUGE et que la
# position ÉCRITE bouge avec lui, pas une performance.
MARCHE_MUR_S=90
DEPLACEMENT_MIN_M=1.0
TOLERANCE_REPRISE_M=2.0

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
ECHECS=0
etape() { echo; echo "### $*"; }
info()  { echo "    $*"; }
fini()  { CODE="$1"; exit "$CODE"; }
constat() {
  if [ "$2" -eq 0 ]; then echo "    [PASS] $1"
  else echo "    [FAIL] $1"; ECHECS=$((ECHECS + 1)); fi
}

tuer_jeu() {
  # JAMAIS de pkill global (2026-08-11) : PID enregistré, mort vérifiée.
  if [ -n "$PID_JEU" ] && kill -0 "$PID_JEU" 2>/dev/null; then
    kill -TERM "$PID_JEU" 2>/dev/null || true
    for _ in $(seq 1 20); do kill -0 "$PID_JEU" 2>/dev/null || break; sleep 1; done
    kill -0 "$PID_JEU" 2>/dev/null && kill -KILL "$PID_JEU" 2>/dev/null || true
  fi
  PID_JEU=""
}

menage() {
  tuer_jeu
  if [ -n "$PID_XVFB" ] && kill -0 "$PID_XVFB" 2>/dev/null; then
    kill -TERM "$PID_XVFB" 2>/dev/null || true
    sleep 1
    kill -0 "$PID_XVFB" 2>/dev/null && kill -KILL "$PID_XVFB" 2>/dev/null || true
  fi
  echo
  echo "=== VERDICT PORTAIL EXPORT T1 : code $CODE"
  mkdir -p "$SORTIE" 2>/dev/null || true
  printf 'RC=%s\n' "$CODE" > "$SORTIE/VERDICT_T1" 2>/dev/null || true
  printf 'RC=%s\n' "$CODE"
}
trap 'menage' EXIT
trap 'CODE=130; exit 130' INT
trap 'CODE=143; exit 143' TERM

SHA="$(git rev-parse HEAD)"
BINAIRE="$SORTIE/build/EclatsDOrage.x86_64"
JOURNAUX="$SORTIE/journaux"; mkdir -p "$JOURNAUX"
JOURNAL_JEU=""
PROFIL=""
FENETRE=""

# ---------------------------------------------------------------- helpers ---
sauvegarde_du_profil() { echo "$1/godot/app_userdata/Eclats d'Orage/saves/slot0.json"; }

# Fabrique un slot par la MÊME enveloppe que SaveSystem — schéma 4 exact.
fabriquer_slot() {  # $1 = profil, $2 = JSON du payload `data`
  local fichier; fichier="$(sauvegarde_du_profil "$1")"
  mkdir -p "$(dirname "$fichier")"
  python3 - "$fichier" "$2" <<'PYEOF'
import json, sys
fichier, data = sys.argv[1], json.loads(sys.argv[2])
enveloppe = {"schema_version": 4, "slot": "slot0",
             "saved_at_utc": "2026-08-28T00:00:00", "data": data}
open(fichier, "w", encoding="utf-8").write(json.dumps(enveloppe, indent="  "))
PYEOF
}

lire_champ_slot() {  # $1 = profil, $2 = expression python sur d (le payload)
  python3 - "$(sauvegarde_du_profil "$1")" "$2" <<'PYEOF'
import json, sys
try:
    d = json.load(open(sys.argv[1]))["data"]
    print(eval(sys.argv[2], {"d": d}))
except Exception as e:
    print("ERREUR_LECTURE:%s" % type(e).__name__)
PYEOF
}

lancer_jeu() {  # $1 = profil ; pose PID_JEU, JOURNAL_JEU, FENETRE
  PROFIL="$1"
  JOURNAL_JEU="$JOURNAUX/t1_$(basename "$PROFIL").log"
  rm -f "$JOURNAL_JEU"
  # stdbuf : une build release ne vide pas stdout, et l'arrêt détruirait les
  # jalons déjà imprimés (leçon du portail ISS-073).
  DISPLAY="$DISPLAY_NUM" XDG_DATA_HOME="$PROFIL" HOME="$PROFIL" \
    stdbuf -oL -eL "$BINAIRE" \
      --rendering-driver opengl3 \
      --resolution "${LARGEUR}x${HAUTEUR}" --windowed \
    > "$JOURNAL_JEU" 2>&1 &
  PID_JEU=$!
  FENETRE=""
  for _ in $(seq 1 "$DELAI_FENETRE"); do
    if ! kill -0 "$PID_JEU" 2>/dev/null; then
      echo "BLOQUÉ: le jeu s'est arrêté avant sa fenêtre ($PROFIL)" >&2
      tail -30 "$JOURNAL_JEU" >&2; return 1
    fi
    FENETRE="$(DISPLAY="$DISPLAY_NUM" xdotool search --onlyvisible \
      --name "$TITRE_FENETRE" 2>/dev/null | tail -1)"
    [ -n "$FENETRE" ] && break
    sleep 1
  done
  [ -n "$FENETRE" ] || { echo "BLOQUÉ: fenêtre introuvable" >&2; return 1; }
  # Le clavier passe par le FOCUS X — `--window` est ignoré sans erreur.
  DISPLAY="$DISPLAY_NUM" xdotool windowfocus --sync "$FENETRE" 2>/dev/null || true
  DISPLAY="$DISPLAY_NUM" xdotool windowraise "$FENETRE" 2>/dev/null || true
  sleep 3
  DISPLAY="$DISPLAY_NUM" xdotool windowfocus --sync "$FENETRE" 2>/dev/null || true
  return 0
}

attendre_motif() {  # $1 = motif fixe attendu dans le journal
  local trouve=0
  for _ in $(seq 1 "$DELAI_JALON"); do
    if grep -qF "$1" "$JOURNAL_JEU" 2>/dev/null; then trouve=1; break; fi
    kill -0 "$PID_JEU" 2>/dev/null || break
    sleep 1
  done
  [ "$trouve" -eq 1 ]
}

fermer_fenetre() {
  # La CROIX de la fenêtre — le geste C9. WM_DELETE_WINDOW → close request →
  # autosave → quit. On attend la mort réelle du processus.
  DISPLAY="$DISPLAY_NUM" xdotool windowclose "$FENETRE" 2>/dev/null || true
  for _ in $(seq 1 30); do kill -0 "$PID_JEU" 2>/dev/null || break; sleep 1; done
  if kill -0 "$PID_JEU" 2>/dev/null; then return 1; fi
  PID_JEU=""
  return 0
}

pos_posee() {  # lit « héros posé : (x, y, z) » du journal courant → "x y z"
  grep -F "[world_v2] héros posé" "$JOURNAL_JEU" | head -1 \
    | sed -n 's/.*(\(-\{0,1\}[0-9.]*\), \(-\{0,1\}[0-9.]*\), \(-\{0,1\}[0-9.]*\)).*/\1 \2 \3/p'
}

# ------------------------------------------------------------------ étapes --
etape "1. l'artefact mesuré est-il CELUI du commit courant ?"
[ -x "$BINAIRE" ] || { echo "BLOQUÉ: binaire absent : $BINAIRE (lancer gate_export_parite.sh)" >&2; fini 3; }
SHA_ENREG="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['sha_git_teste'])" \
  "$SORTIE/contexte.json" 2>/dev/null || echo "")"
if [ "$SHA_ENREG" != "$SHA" ]; then
  echo "BLOQUÉ: binaire bâti sur « $SHA_ENREG », HEAD est « $SHA » (ISS-018)." >&2
  fini 3
fi
info "sha    : $SHA"
info "sha256 : $(sha256sum "$BINAIRE" | cut -d' ' -f1)"

command -v Xvfb >/dev/null    || { echo "BLOQUÉ: Xvfb absent" >&2; fini 3; }
command -v xdotool >/dev/null || { echo "BLOQUÉ: xdotool absent" >&2; fini 3; }
rm -f "/tmp/.X${DISPLAY_NUM#:}-lock"
Xvfb "$DISPLAY_NUM" -screen 0 "${LARGEUR}x${HAUTEUR}x24" \
  > "$JOURNAUX/t1_xvfb.log" 2>&1 &
PID_XVFB=$!
sleep 3
kill -0 "$PID_XVFB" 2>/dev/null || { echo "BLOQUÉ: Xvfb mort" >&2; fini 3; }
info "Xvfb PID $PID_XVFB sur $DISPLAY_NUM"

# --- PHASE 1 : partie neuve, mouvement réel, fermeture par la croix (C9) ----
etape "P1. partie NEUVE : spawn, marche tenue, puis la CROIX de la fenêtre"
P1="$SORTIE/profil_t1_p1"; rm -rf "$P1"; mkdir -p "$P1"
lancer_jeu "$P1" || fini 3
DISPLAY="$DISPLAY_NUM" xdotool key Return
info "Return envoyé (partie neuve — le focus est sur « Nouvelle partie »)"
attendre_motif "fondation V2 vérifiée" || { echo "BLOQUÉ: monde jamais monté" >&2; tail -40 "$JOURNAL_JEU" >&2; fini 3; }
grep -aqE "\[world_v2\] arrivée +: spawn" "$JOURNAL_JEU"
constat "une partie neuve arrive au point d'apparition" $?
POS0="$(pos_posee)"
info "posé à : ${POS0:-<illisible>}"
[ -n "$POS0" ]; constat "le jalon « héros posé » est lisible" $?
DISPLAY="$DISPLAY_NUM" import -window root "$SORTIE/t1_p1_monde.png" 2>/dev/null || true
info "marche : W physique tenu ${MARCHE_MUR_S}s de mur (ISS-072 borne ce qu'on en attend)"
DISPLAY="$DISPLAY_NUM" xdotool windowfocus --sync "$FENETRE" 2>/dev/null || true
DISPLAY="$DISPLAY_NUM" xdotool keydown w
sleep "$MARCHE_MUR_S"
DISPLAY="$DISPLAY_NUM" xdotool keyup w
sleep 2
fermer_fenetre
constat "la croix ferme le jeu (le processus meurt tout seul)" $?
FICHIER_P1="$(sauvegarde_du_profil "$P1")"
[ -f "$FICHIER_P1" ]; constat "C9 en export : la fermeture a ÉCRIT une sauvegarde" $?
if [ -f "$FICHIER_P1" ]; then
  SIGNE="$(lire_champ_slot "$P1" "d.get('world_version','')")"
  [ "$SIGNE" = "neris_v2" ]; constat "la sauvegarde est signée neris_v2" $?
  CHECK="$(lire_champ_slot "$P1" "d.get('checkpoint','')")"
  [ "$CHECK" = "world_v2.valley" ]; constat "le lieu de reprise est world_v2.valley" $?
  DELTA="$(python3 - "$FICHIER_P1" $POS0 <<'PYEOF'
import json, sys, math
d = json.load(open(sys.argv[1]))["data"]
p = d.get("player_position", {})
x0, z0 = float(sys.argv[2]), float(sys.argv[4])
print("%.2f" % math.hypot(float(p.get("x", 0)) - x0, float(p.get("z", 0)) - z0))
PYEOF
)"
  info "déplacement écrit : ${DELTA} m (seuil ${DEPLACEMENT_MIN_M})"
  python3 -c "import sys; sys.exit(0 if float('$DELTA') >= $DEPLACEMENT_MIN_M else 1)"
  constat "l'avatar a réellement bougé et la position écrite a suivi" $?
fi

# --- PHASE 2 : Continuer → position ET orientation restaurées ---------------
etape "P2. relance sur le MÊME profil : « Continuer » restaure l'endroit"
POS_ATTENDUE="$(lire_champ_slot "$P1" "'%.1f %.1f %.1f' % (d['player_position']['x'], d['player_position']['y'], d['player_position']['z'])")"
LACET_ATTENDU="$(lire_champ_slot "$P1" "'%.2f' % d.get('player_yaw', 0.0)")"
info "attendu du fichier : pos=($POS_ATTENDUE) lacet=$LACET_ATTENDU"
lancer_jeu "$P1" || fini 3
DISPLAY="$DISPLAY_NUM" xdotool key Return
info "Return envoyé (le focus est sur « Continuer » — une sauvegarde existe)"
attendre_motif "fondation V2 vérifiée" || { echo "BLOQUÉ: monde jamais monté (P2)" >&2; tail -40 "$JOURNAL_JEU" >&2; fini 3; }
grep -aqE "\[world_v2\] arrivée +: sauvegarde" "$JOURNAL_JEU"
constat "la provenance du placement est « sauvegarde »" $?
POS2="$(pos_posee)"
info "posé à : ${POS2:-<illisible>}"
ECART="$(python3 -c "
import sys, math
a = '$POS_ATTENDUE'.split(); b = '$POS2'.split()
print('%.2f' % math.hypot(float(a[0])-float(b[0]), float(a[2])-float(b[2])) if len(a)==3 and len(b)==3 else 'nan')")"
info "écart horizontal : ${ECART} m (tolérance ${TOLERANCE_REPRISE_M})"
python3 -c "import sys,math; e=float('$ECART'); sys.exit(0 if not math.isnan(e) and e <= $TOLERANCE_REPRISE_M else 1)"
constat "la position est RESTAURÉE là où la partie s'était arrêtée" $?
LACET2="$(grep -F "héros posé" "$JOURNAL_JEU" | head -1 | sed -n 's/.*lacet=\(-\{0,1\}[0-9.]*\).*/\1/p')"
python3 -c "
import sys, math
a, b = float('$LACET_ATTENDU' or 'nan'), float('$LACET2' or 'nan')
d = abs(math.atan2(math.sin(a-b), math.cos(a-b)))
sys.exit(0 if d <= 0.25 else 1)"
constat "l'orientation est restaurée (écrit $LACET_ATTENDU, posé ${LACET2:-?})" $?
DISPLAY="$DISPLAY_NUM" import -window root "$SORTIE/t1_p2_reprise.png" 2>/dev/null || true
tuer_jeu

# --- PHASE 3 : checkpoint antichambre → « Continuer » route vers elle -------
etape "P3. un slot « arrêté dans l'antichambre » : le menu route vers ELLE"
P3="$SORTIE/profil_t1_p3"; rm -rf "$P3"; mkdir -p "$P3"
fabriquer_slot "$P3" '{"schema": 4, "checkpoint": "dungeon.antechamber", "world_version": "neris_v2", "playtime_seconds": 60.0, "boss_defeated": false}'
lancer_jeu "$P3" || fini 3
DISPLAY="$DISPLAY_NUM" xdotool key Return
attendre_motif "[flow] transition vers : res://scenes/dungeon/rooms/Antechamber.tscn"
constat "« Continuer » route vers l'antichambre, pas vers le monde ouvert" $?
sleep 10
NB_ERR="$(grep -acE "SCRIPT ERROR|Cannot open file" "$JOURNAL_JEU" || true)"
[ "${NB_ERR:-1}" -eq 0 ]; constat "l'antichambre monte à froid sans erreur de script ($NB_ERR)" $?
kill -0 "$PID_JEU" 2>/dev/null; constat "le processus est vivant dans l'antichambre" $?
DISPLAY="$DISPLAY_NUM" import -window root "$SORTIE/t1_p3_antichambre.png" 2>/dev/null || true
tuer_jeu

# --- PHASE 4 : boss_defeated survit à un autosave réel ----------------------
etape "P4. un slot riche (boss_defeated) : l'autosave de la croix le PRÉSERVE"
P4="$SORTIE/profil_t1_p4"; rm -rf "$P4"; mkdir -p "$P4"
fabriquer_slot "$P4" '{"schema": 4, "checkpoint": "world_v2.valley", "world_version": "neris_v2", "boss_defeated": true, "weapons": ["temoin_t1_export"], "player_position": {"x": 10.0, "y": 26.0, "z": 160.0}, "player_yaw": 1.5}'
lancer_jeu "$P4" || fini 3
DISPLAY="$DISPLAY_NUM" xdotool key Return
attendre_motif "fondation V2 vérifiée" || { echo "BLOQUÉ: monde jamais monté (P4)" >&2; fini 3; }
grep -aqE "\[world_v2\] arrivée +: sauvegarde" "$JOURNAL_JEU"
constat "le slot fabriqué est bien relu comme une reprise" $?
sleep 3
fermer_fenetre
constat "la croix ferme le jeu (P4)" $?
BOSS="$(lire_champ_slot "$P4" "d.get('boss_defeated')")"
[ "$BOSS" = "True" ]; constat "boss_defeated a SURVÉCU à l'autosave réel de la croix" $?
TEMOIN="$(lire_champ_slot "$P4" "d.get('weapons')")"
[ "$TEMOIN" = "['temoin_t1_export']" ]; constat "l'inventaire témoin a survécu à la fusion" $?

# --- PHASE 5 : une sauvegarde V1 n'est JAMAIS réappliquée -------------------
etape "P5. un slot V1 (sans signature) avec position plausible : IGNORÉ"
P5="$SORTIE/profil_t1_p5"; rm -rf "$P5"; mkdir -p "$P5"
fabriquer_slot "$P5" '{"schema": 4, "checkpoint": "valley.camp.start", "playtime_seconds": 120.0, "boss_defeated": false, "player_position": {"x": 45.0, "y": 6.0, "z": 65.0}, "player_yaw": 2.0}'
lancer_jeu "$P5" || fini 3
DISPLAY="$DISPLAY_NUM" xdotool key Return
attendre_motif "fondation V2 vérifiée" || { echo "BLOQUÉ: monde jamais monté (P5)" >&2; fini 3; }
grep -aqE "\[world_v2\] arrivée +: spawn" "$JOURNAL_JEU"
constat "position V1 dans les bornes V2 : provenance « spawn », jamais « sauvegarde »" $?
tuer_jeu

# --- PHASE 6 : slot corrompu → refus propre, fichier INTACT -----------------
etape "P6. un slot corrompu : refus lisible, aucun crash, fichier intact"
P6="$SORTIE/profil_t1_p6"; rm -rf "$P6"; mkdir -p "$P6"
FICHIER_P6="$(sauvegarde_du_profil "$P6")"
mkdir -p "$(dirname "$FICHIER_P6")"
printf '{"schema_version": 4, "data": {"player_pos' > "$FICHIER_P6"
AVANT_P6="$(sha256sum "$FICHIER_P6" | cut -d' ' -f1)"
lancer_jeu "$P6" || fini 3
DISPLAY="$DISPLAY_NUM" xdotool key Return
sleep 15
kill -0 "$PID_JEU" 2>/dev/null
constat "le processus survit à un « Continuer » sur slot corrompu" $?
# Le boot passe LUI-MÊME par SceneFlow pour atteindre le menu : une ligne
# [flow] est donc normale. Le refus se lit à l'absence de DEUXIÈME départ.
NB_FLOW="$(grep -ac "\[flow\] transition vers" "$JOURNAL_JEU" || true)"
info "transitions parties : ${NB_FLOW:-0} (1 = boot→menu, attendu)"
[ "${NB_FLOW:-9}" -le 1 ]; constat "aucune transition APRÈS le refus — le menu a refusé, pas planté" $?
fermer_fenetre || tuer_jeu
APRES_P6="$(sha256sum "$FICHIER_P6" | cut -d' ' -f1)"
[ "$AVANT_P6" = "$APRES_P6" ]; constat "C10 en export : le slot corrompu est INTACT au sha256" $?

etape "7. ce que ce portail déclare NON VÉRIFIÉ, et pourquoi"
info "NON VÉRIFIÉ — marche jusqu'au donjon et retour (ISS-072, horloge découplée)"
info "NON VÉRIFIÉ — mort puis « Réessayer » en export (ISS-074, aucun adversaire)"
info "Les deux sont prouvés en ÉDITEUR par la suite t1_persistance (C1..C10)."

etape "8. verdict"
info "constats en échec : $ECHECS"
if [ "$ECHECS" -eq 0 ]; then fini 0; else fini 1; fi
