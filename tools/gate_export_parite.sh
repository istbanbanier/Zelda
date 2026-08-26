#!/usr/bin/env bash
# =============================================================================
# tools/gate_export_parite.sh — LE PORTAIL D'EXPORT D'ISS-071
#
# POURQUOI CE PORTAIL EXISTE
# --------------------------
# Le défaut d'ISS-071 n'existe QUE dans une build exportée : `DirAccess.get_files()`
# ne rend pas les fichiers sources d'un PCK, seulement leurs `<nom>.gltf.import`.
# Aucune suite du dépôt ne pouvait le voir — toutes tournent en exécution
# éditeur. 1 094 appels de placement échouaient sans que le jeu plante, et le
# propriétaire jouait ce monde amputé depuis au moins le 24 août.
#
# Un correctif écrit sans ce portail refermerait le même angle mort. Le rouge
# n'est atteignable que sur une build AUTONOME LANCÉE : un test exécuté dans
# l'éditeur ne constitue PAS la preuve rouge d'ISS-071.
#
# CE QUE LE PORTAIL FAIT, DANS L'ORDRE
# ------------------------------------
#   1. verrou canonique + cloison `user://`          (RC testé : 3 si perdu)
#   2. import                                        (obligatoire : arbre neuf)
#   3. manifeste ÉDITEUR
#   4. export Linux vers un chemin HORS de l'arbre
#   5. lancement de la build sous Xvfb, `user://` VIERGE
#   6. pilotage clavier par le FOCUS X
#   7. attente du jalon de montage PUIS de l'effacement de l'écran de chargement
#   8. récupération du manifeste EXPORT
#   9. comptage des familles d'erreur
#  10. `tools/iss071_parite.py`, dont le code est propagé
#  11. jeton `RC=<code>` en dernière ligne
#
# Codes : 0 = VERT · 1 = ROUGE · 3 = BLOQUÉ (une étape n'a pas pu tourner).
# Un portail ne rend JAMAIS 0 sur une étape sautée (`.claude/rules/evidence.md`).
#
# Usage :
#   tools/gate_export_parite.sh [--sortie <dir hors arbre>] [--display :NN]
#   # TOUJOURS rediriger, jamais `| tail` : un tube masque le code retour.
#   nohup tools/gate_export_parite.sh > /chemin/gate.log 2>&1 &
#   until grep -q '^RC=' /chemin/gate.log; do sleep 20; done
# =============================================================================
set -u -o pipefail

ARBRE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# PIÈGE MESURÉ : un sous-agent démarre dans l'arbre PRINCIPAL, pas dans le
# sien. `godot_racine()` et `--path .` résolvent contre le cwd — sans ce `cd`,
# le portail mesurerait un autre arbre et RIEN dans sa sortie ne le crierait.
cd "$ARBRE" || { echo "BLOQUÉ: cd $ARBRE impossible" >&2; echo "RC=3"; exit 3; }
SORTIE="${GATE_SORTIE:-/home/user/wt-a-out}"
DISPLAY_NUM="${GATE_DISPLAY:-:91}"
LARGEUR=1024
HAUTEUR=768
TITRE_FENETRE="Eclats d'Orage"

# Repères MESURÉS le 2026-08-25 sur cette même build (`identify -format
# '%[fx:mean]'`) : écran de chargement 0,0027 · monde affiché 0,52. Photographier
# pendant le chargement rend six images identiques et fait rougir « caméra » et
# « déplacement » pour une raison qui n'est pas la leur.
# Surchargeable UNIQUEMENT pour le contrôle négatif n° 9 : porter le seuil
# au-delà de ce qu'aucune image réelle n'atteint doit faire REFUSER le portail
# de bout en bout. Toute surcharge est publiée dans `contexte.json`.
SEUIL_LUMINANCE="${GATE_SEUIL_LUMINANCE:-0.02}"

DELAI_IMPORT=2400
DELAI_MANIFESTE_EDITEUR=1800
DELAI_EXPORT=1800
DELAI_FENETRE=120
DELAI_JALON=900
DELAI_MANIFESTE_EXPORT=180
DELAI_AFFICHAGE="${GATE_DELAI_AFFICHAGE:-300}"

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

etape()  { echo; echo "### $*"; }
info()   { echo "    $*"; }
# Toute sortie anticipée passe par ici : le jeton RC= est écrit une seule fois,
# en dernier, et le ménage a lieu avant. Sans jeton, une boucle d'attente
# extérieure dort pour toujours (piège mesuré, `tools/CLAUDE.md`).
fini() {
  CODE="$1"
  exit "$CODE"
}

menage() {
  # JAMAIS de `pkill` global : le 2026-08-11, un pkill a laissé trois godot
  # vivants qui ont fabriqué huit échecs de sauvegarde inexistants. On tue par
  # PID enregistré, et on vérifie la mort.
  if [ -n "$PID_JEU" ] && kill -0 "$PID_JEU" 2>/dev/null; then
    kill -TERM "$PID_JEU" 2>/dev/null || true
    for _ in $(seq 1 20); do
      kill -0 "$PID_JEU" 2>/dev/null || break
      sleep 1
    done
    kill -0 "$PID_JEU" 2>/dev/null && kill -KILL "$PID_JEU" 2>/dev/null || true
  fi
  if [ -n "$PID_XVFB" ] && kill -0 "$PID_XVFB" 2>/dev/null; then
    kill -TERM "$PID_XVFB" 2>/dev/null || true
    sleep 1
    kill -0 "$PID_XVFB" 2>/dev/null && kill -KILL "$PID_XVFB" 2>/dev/null || true
  fi
  echo
  echo "=== VERDICT PORTAIL EXPORT ISS-071 : code $CODE"
  mkdir -p "$SORTIE" 2>/dev/null || true
  printf 'RC=%s\n' "$CODE" > "$SORTIE/VERDICT" 2>/dev/null || true
  # DERNIÈRE ligne du journal, toujours. C'est le seul jeton sur lequel une
  # attente extérieure peut s'appuyer sans dépendre du nom du processus.
  printf 'RC=%s\n' "$CODE"
}
trap 'menage' EXIT
trap 'CODE=130; exit 130' INT
trap 'CODE=143; exit 143' TERM

echo "=============================================================================="
echo "PORTAIL D'EXPORT ISS-071 — parité de résolution éditeur / build exportée"
echo "arbre   : $ARBRE"
echo "sortie  : $SORTIE   (HORS de l'arbre : un export dans l'arbre le salirait)"
echo "date    : $(date -Is)"
echo "=============================================================================="

# --------------------------------------------------------------------------
etape "0. état du dépôt — une preuve vient d'un arbre COMMITTÉ"
SHA="$(git -C "$ARBRE" rev-parse HEAD 2>/dev/null || echo INCONNU)"
SALE="$(git -C "$ARBRE" status --porcelain 2>/dev/null | wc -l)"
info "SHA testé      : $SHA"
info "fichiers sales : $SALE"
git -C "$ARBRE" status --porcelain 2>/dev/null | sed 's/^/      /' || true

# --------------------------------------------------------------------------
etape "1. verrou canonique et cloison user://"
# shellcheck source=lib/godot_env.sh
. "$ARBRE/tools/lib/godot_env.sh"
if ! godot_cloison_arbre; then
  echo "BLOQUÉ: cloison user:// impossible — RIEN N'A TOURNÉ." >&2
  fini 3
fi
info "XDG_DATA_HOME (étapes éditeur) = $XDG_DATA_HOME"
# `flock -w N` expire en rendant 1 SANS exécuter la commande. Un RC non testé
# est un résultat perdu qui ressemble à un résultat : deux vues ont déjà été
# perdues ainsi le 2026-08-19.
if ! godot_verrou_prendre 8 3600; then
  echo "BLOQUÉ: verrou non obtenu — aucune étape n'a été exécutée." >&2
  fini 3
fi
info "verrou pris : ${GODOT_VERROU_PRIS:-?}"

GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"
if [ ! -x "$GODOT_BIN" ]; then
  echo "BLOQUÉ: binaire Godot introuvable : $GODOT_BIN" >&2
  fini 3
fi
info "godot : $("$GODOT_BIN" --version 2>/dev/null | head -1)"

mkdir -p "$SORTIE" || { echo "BLOQUÉ: mkdir $SORTIE" >&2; fini 3; }
JOURNAUX="$SORTIE/journaux"; mkdir -p "$JOURNAUX"
BUILD_DIR="$SORTIE/build"; mkdir -p "$BUILD_DIR"
BINAIRE="$BUILD_DIR/EclatsDOrage.x86_64"
MAN_EDITEUR="$SORTIE/manifeste_editeur.json"
MAN_EXPORT="$SORTIE/manifeste_export.json"
JOURNAL_JEU="$JOURNAUX/jeu_exporte_stdout.log"
PROFIL_VIERGE="$SORTIE/profil_vierge"

# --------------------------------------------------------------------------
# RÉUTILISATION DES ARTEFACTS LOURDS — STRICTEMENT RÉSERVÉE AUX CONTRÔLES
# NÉGATIFS. Elle saute l'import, le manifeste éditeur et l'export.
#
# C'est un raccourci DANGEREUX : mesurer un artefact périmé en croyant mesurer
# le code courant est la famille de fautes la plus coûteuse de ce dépôt
# (ISS-018, et l'export « au nom neuf, aux octets identiques » du 2026-08-16).
# Trois garde-fous, et aucun n'est facultatif : opt-in explicite, égalité du
# SHA enregistré avec le HEAD courant, et publication dans contexte.json.
REUTILISE=0
if [ "${GATE_REUTILISER_BUILD:-0}" = "1" ]; then
  SHA_ENREG="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))\
['sha_git_teste'])" "$SORTIE/contexte.json" 2>/dev/null || echo "")"
  if [ -x "$BINAIRE" ] && [ -s "$MAN_EDITEUR" ] && [ "$SHA_ENREG" = "$SHA" ]; then
    REUTILISE=1
    etape "2-4. RÉUTILISATION DES ARTEFACTS (contrôle négatif seulement)"
    info "!!! Ce n'est PAS une preuve de portail : import, manifeste éditeur"
    info "!!! et export ne sont PAS rejoués."
    info "SHA enregistré = SHA courant = $SHA"
    info "binaire réutilisé : $BINAIRE"
    info "sha256 : $(sha256sum "$BINAIRE" | cut -d' ' -f1)"
  else
    echo "BLOQUÉ: réutilisation demandée mais impossible (binaire, manifeste" >&2
    echo "        ou SHA discordant : enregistré « $SHA_ENREG » contre « $SHA »)." >&2
    fini 3
  fi
fi

if [ "$REUTILISE" -eq 0 ]; then
etape "2. import — obligatoire, et pas une formalité"
# Un arbre de travail neuf ne contient AUCUN `.godot/`. Sans cache de classes
# globales, le premier fichier qui cite un `class_name` porte le blâme et
# désigne un innocent (mesuré le 2026-08-16, `tools/CLAUDE.md`).
timeout "$DELAI_IMPORT" "$GODOT_BIN" --headless --path "$ARBRE" --import \
  > "$JOURNAUX/import.log" 2>&1
RC=$?
info "code retour import : $RC ($(wc -l < "$JOURNAUX/import.log") lignes)"
if [ "$RC" -ne 0 ]; then
  echo "BLOQUÉ: import échoué (RC=$RC) — tout ce qui suit mesurerait un" >&2
  echo "        projet à moitié importé. Voir $JOURNAUX/import.log" >&2
  tail -20 "$JOURNAUX/import.log" >&2
  fini 3
fi

# --------------------------------------------------------------------------
etape "3. manifeste ÉDITEUR"
rm -f "$MAN_EDITEUR"
timeout "$DELAI_MANIFESTE_EDITEUR" "$GODOT_BIN" --headless --path "$ARBRE" \
  --script tools/godot/iss071_manifeste_editeur.gd \
  -- "--iss071-dump=$MAN_EDITEUR" \
  > "$JOURNAUX/manifeste_editeur.log" 2>&1
RC=$?
info "code retour : $RC"
if [ ! -s "$MAN_EDITEUR" ]; then
  echo "BLOQUÉ: aucun manifeste éditeur écrit (RC=$RC). Sans lui il n'y a" >&2
  echo "        pas de terme de comparaison : le portail ne peut RIEN dire." >&2
  tail -30 "$JOURNAUX/manifeste_editeur.log" >&2
  fini 3
fi
info "manifeste éditeur : $MAN_EDITEUR ($(stat -c%s "$MAN_EDITEUR") octets)"

# --------------------------------------------------------------------------
etape "4. export Linux vers un chemin HORS de l'arbre"
TEMPLATES="$ARBRE/.godot_user/godot/export_templates/4.7.1.stable"
if [ ! -d "$TEMPLATES" ]; then
  echo "BLOQUÉ: templates d'export absents : $TEMPLATES" >&2
  echo "        Ils ne sont pas téléchargeables ici (proxy) ; ils sont" >&2
  echo "        compilés depuis /opt/src/godot. Voir export_presets.cfg." >&2
  fini 3
fi
info "templates : $(ls "$TEMPLATES" | tr '\n' ' ')"
rm -f "$BINAIRE"
timeout "$DELAI_EXPORT" "$GODOT_BIN" --headless --path "$ARBRE" \
  --export-release "Linux x86_64" "$BINAIRE" \
  > "$JOURNAUX/export.log" 2>&1
RC=$?
info "code retour export : $RC ($(wc -l < "$JOURNAUX/export.log") lignes)"
if [ ! -x "$BINAIRE" ]; then
  echo "BLOQUÉ: binaire exporté absent ou non exécutable : $BINAIRE" >&2
  tail -30 "$JOURNAUX/export.log" >&2
  fini 3
fi
OCTETS="$(stat -c%s "$BINAIRE")"
if [ "$OCTETS" -lt 10000000 ]; then
  echo "BLOQUÉ: binaire exporté trop petit ($OCTETS o) — le PCK embarqué" >&2
  echo "        manque probablement. Lancer ce binaire ne prouverait rien." >&2
  fini 3
fi
fi   # fin du bloc « pas de réutilisation »
SHA_BIN="$(sha256sum "$BINAIRE" | cut -d' ' -f1)"
OCTETS="$(stat -c%s "$BINAIRE")"
info "binaire : $BINAIRE"
info "octets  : $OCTETS"
info "sha256  : $SHA_BIN"

# --------------------------------------------------------------------------
etape "5. lancement de la build AUTONOME, user:// VIERGE"
# Installation neuve : ni sauvegarde, ni option, ni cache d'une exécution
# précédente. Un résidu ferait démarrer le jeu sur « Continuer » au lieu de
# « Nouvelle partie », et le monde ne se monterait pas de la même façon.
rm -rf "$PROFIL_VIERGE"
mkdir -p "$PROFIL_VIERGE"
RESTANT="$(find "$PROFIL_VIERGE" -mindepth 1 | wc -l)"
info "profil vierge : $PROFIL_VIERGE ($RESTANT entrée(s) — 0 attendu)"
[ "$RESTANT" -eq 0 ] || { echo "BLOQUÉ: profil non vierge" >&2; fini 3; }

rm -f "/tmp/.X${DISPLAY_NUM#:}-lock"
Xvfb "$DISPLAY_NUM" -screen 0 "${LARGEUR}x${HAUTEUR}x24" \
  > "$JOURNAUX/xvfb.log" 2>&1 &
PID_XVFB=$!
sleep 3
if ! kill -0 "$PID_XVFB" 2>/dev/null; then
  echo "BLOQUÉ: Xvfb mort immédiatement (PID $PID_XVFB)" >&2
  tail -20 "$JOURNAUX/xvfb.log" >&2
  fini 3
fi
info "Xvfb PID $PID_XVFB sur $DISPLAY_NUM"

rm -f "$MAN_EXPORT" "$JOURNAL_JEU"
# `stdbuf -oL -eL` : redirigée, la sortie d'un processus est mise en tampon par
# blocs. Un arrêt du processus DÉTRUIT alors les jalons déjà imprimés, et le
# journal ment par omission.
DISPLAY="$DISPLAY_NUM" XDG_DATA_HOME="$PROFIL_VIERGE" HOME="$PROFIL_VIERGE" \
  stdbuf -oL -eL "$BINAIRE" \
    --rendering-driver opengl3 \
    --resolution "${LARGEUR}x${HAUTEUR}" --windowed \
    -- "--iss071-dump=$MAN_EXPORT" \
  > "$JOURNAL_JEU" 2>&1 &
PID_JEU=$!
info "jeu PID $PID_JEU ; journal $JOURNAL_JEU"
info "drapeau passé après « -- » : --iss071-dump=$MAN_EXPORT"

# --------------------------------------------------------------------------
etape "6. pilotage par le FOCUS X"
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
if [ -z "$FENETRE" ]; then
  echo "BLOQUÉ: fenêtre « $TITRE_FENETRE » introuvable après ${DELAI_FENETRE}s" >&2
  tail -40 "$JOURNAL_JEU" >&2
  fini 3
fi
info "fenêtre : $FENETRE"

DISPLAY="$DISPLAY_NUM" xdotool windowfocus --sync "$FENETRE" 2>/dev/null || true
DISPLAY="$DISPLAY_NUM" xdotool windowraise "$FENETRE" 2>/dev/null || true
sleep 4
DISPLAY="$DISPLAY_NUM" import -window root "$SORTIE/01_menu.png" 2>/dev/null || true

# JAMAIS `xdotool key --window <id>` : Godot lit le clavier par le FOCUS X, et
# un envoi ciblé sur la fenêtre est ignoré SANS AUCUNE ERREUR. Le journal
# n'aurait alors rien d'anormal, et l'on chercherait le défaut ailleurs.
DISPLAY="$DISPLAY_NUM" xdotool windowfocus --sync "$FENETRE" 2>/dev/null || true
DISPLAY="$DISPLAY_NUM" xdotool key Return
info "« Nouvelle partie » : Return envoyé par le focus, pas par --window"

# --------------------------------------------------------------------------
etape "7. attente du jalon de montage, PUIS de l'effacement du chargement"
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
if [ "$TROUVE" -ne 1 ]; then
  echo "BLOQUÉ: jalon « $JALON » absent après ${DELAI_JALON}s. Les compteurs" >&2
  echo "        seraient PARTIELS : un zéro y voudrait dire « pas encore" >&2
  echo "        demandé », pas « rien ne manque »." >&2
  tail -60 "$JOURNAL_JEU" >&2
  fini 3
fi
info "jalon atteint : $(grep -F "$JALON" "$JOURNAL_JEU" | head -1)"

# L'écran de chargement s'efface APRÈS le jalon. On le MESURE, on ne le suppose
# pas : repères 0,0027 (chargement) contre 0,52 (monde affiché).
LUM="-1"
AFFICHE=0
for _ in $(seq 1 "$DELAI_AFFICHAGE"); do
  DISPLAY="$DISPLAY_NUM" import -window root "$SORTIE/02_monde.png" 2>/dev/null || true
  if [ -s "$SORTIE/02_monde.png" ]; then
    LUM="$(identify -format '%[fx:mean]' "$SORTIE/02_monde.png" 2>/dev/null || echo -1)"
    if awk -v l="$LUM" -v s="$SEUIL_LUMINANCE" 'BEGIN{exit !(l>s)}'; then
      AFFICHE=1; break
    fi
  fi
  sleep 2
done
info "luminance moyenne mesurée : $LUM (seuil $SEUIL_LUMINANCE ; chargement 0.0027)"
if [ "$AFFICHE" -ne 1 ]; then
  # Le portail se REFUSE : il ne conclut pas sur une image d'écran de
  # chargement. Conclure ici rougirait « caméra » et « déplacement » pour une
  # raison qui n'est pas la leur.
  echo "BLOQUÉ: l'écran de chargement n'a jamais disparu (luminance $LUM)." >&2
  echo "        Le portail REFUSE de conclure sur cette exécution." >&2
  fini 3
fi
info "monde affiché — capture $SORTIE/02_monde.png"

# --------------------------------------------------------------------------
etape "8. manifeste EXPORT écrit par le jeu lui-même"
for _ in $(seq 1 "$DELAI_MANIFESTE_EXPORT"); do
  [ -s "$MAN_EXPORT" ] && break
  sleep 1
done
if [ ! -s "$MAN_EXPORT" ]; then
  echo "BLOQUÉ: la build n'a écrit aucun manifeste à $MAN_EXPORT." >&2
  grep -n "iss071" "$JOURNAL_JEU" | tail -10 >&2 || true
  fini 3
fi
info "manifeste export : $MAN_EXPORT ($(stat -c%s "$MAN_EXPORT") octets)"
info "$(grep -F '[iss071]' "$JOURNAL_JEU" | tail -1)"

# Le jeu est arrêté MAINTENANT, avant toute annotation ou lecture définitive du
# journal : annoter un journal pendant qu'un processus y écrit efface
# l'annotation et rend un fichier propre, complet et faux (2026-08-17).
kill -TERM "$PID_JEU" 2>/dev/null || true
for _ in $(seq 1 20); do kill -0 "$PID_JEU" 2>/dev/null || break; sleep 1; done
kill -0 "$PID_JEU" 2>/dev/null && kill -KILL "$PID_JEU" 2>/dev/null || true
PID_JEU=""
sleep 1
info "jeu arrêté ; journal figé à $(wc -l < "$JOURNAL_JEU") lignes"

# --------------------------------------------------------------------------
etape "9. familles d'erreur au journal du jeu"
for motif in "kit : modèle inconnu" "modèle végétal introuvable" \
             "\[flower_field\] modèle inconnu" \
             "\[flower_field\] modèle de dalle inconnu"; do
  N="$(grep -cE "$motif" "$JOURNAL_JEU" || true)"
  info "$(printf '%6s' "$N") ligne(s)  ::  $motif"
done

# --------------------------------------------------------------------------
etape "10. comparateur de parité (tools/iss071_parite.py)"
python3 "$ARBRE/tools/iss071_parite.py" \
  --editeur "$MAN_EDITEUR" \
  --export "$MAN_EXPORT" \
  --journal "$JOURNAL_JEU" \
  --source "$ARBRE" \
  --rapport "$SORTIE/rapport_parite.json" \
  --inventaire "$SORTIE/inventaire_modeles_absents.txt"
RC_PARITE=$?
info "code retour du comparateur : $RC_PARITE"

cat > "$SORTIE/contexte.json" <<JSONEOF
{
  "sha_git_teste": "$SHA",
  "fichiers_sales": $SALE,
  "binaire_exporte": "$BINAIRE",
  "binaire_octets": $OCTETS,
  "binaire_sha256": "$SHA_BIN",
  "luminance_monde": "$LUM",
  "seuil_luminance": "$SEUIL_LUMINANCE",
  "artefacts_reutilises": $REUTILISE,
  "lignes_journal_jeu": $(wc -l < "$JOURNAL_JEU"),
  "code_parite": $RC_PARITE,
  "date": "$(date -Is)"
}
JSONEOF
info "contexte : $SORTIE/contexte.json"

fini "$RC_PARITE"
