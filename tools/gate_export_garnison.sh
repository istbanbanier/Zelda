#!/usr/bin/env bash
# ISS-074 — LE PORTAIL D'EXPORT DE LA GARNISON.
#
# CE QUE CE PORTAIL PROUVE, ET CE QU'IL NE PROUVE PAS. C'est la première
# chose à lire, et elle est délibérée.
#
# Une build exportée, pilotée au clavier synthétique sous Xvfb en rendu
# logiciel, ne peut pas prouver un ÉCHANGE DE COUPS de façon déterministe :
# le résultat dépendrait de la cadence d'un conteneur partagé. Un portail qui
# prétendrait le contraire serait lent, instable, et mentirait un jour sur
# deux. Le combat — engagement, dégâts dans les deux sens, victoire, mort et
# « Réessayer » — est donc prouvé EN MOTEUR par
# `tests/world_v2/test_world_v2_garrison_combat.gd`, où l'on peut lire des
# points de vie.
#
# Ce portail-ci prouve ce que SEUL un export peut casser :
#   G2  aucun modèle ni ressource manquant dans le PCK (la famille ISS-071 :
#       en éditeur zéro, dans un PCK 534 « modèle inconnu ») ;
#   G3  l'arrivée RÉELLE au camp — le héros marche, et la garnison le voit ;
#   G4  aucune duplication d'une relance à l'autre ;
#   G5  une mort persistée traverse un VRAI redémarrage de processus ;
#   G6  l'inventaire de l'antichambre survit à la reprise (ISS-080) ;
#   G7  le balayage de ressources porte sur TOUS les journaux du run, donjon
#       compris — n'en balayer qu'un laissait l'antichambre hors du filet.
#
# Il sort en 3 (BLOQUÉ) sur toute étape impossible, jamais en 0.
set -u -o pipefail

ARBRE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SORTIE="${GATE_SORTIE:-/home/user/wt-a-out}"
DISPLAY_NUM="${GATE_DISPLAY:-:95}"
LARGEUR=1024
HAUTEUR=768
TITRE_FENETRE="Eclats d'Orage"
DELAI_FENETRE=120
DELAI_JALON=900
DELAI_FERMETURE=180
# L'horodatage SEMÉ dans chaque slot de départ. Il vit ici, en un seul
# endroit : G6 prouve qu'une écriture a eu lieu en constatant que le slot
# ne le porte PLUS. Deux littéraux qui divergeraient un jour rendraient
# cette garde aveugle, en silence.
HORODATAGE_SEME="2026-08-28T00:00:00"
MARCHE_MUR_S="${GATE_MARCHE_S:-70}"

PID_JEU=""
PID_XVFB=""
LANCEMENT=0
JOURNAUX_JEU=""
PREMIER_JOURNAL=""
CODE=3
ECHECS=0
PROFIL=""
JOURNAL_JEU=""
FENETRE=""

BINAIRE="$SORTIE/build/EclatsDOrage.x86_64"
JOURNAUX="$SORTIE/journaux"; mkdir -p "$JOURNAUX"

ok()   { echo "  PASS  $*"; }
ko()   { echo "  FAIL  $*"; ECHECS=$((ECHECS + 1)); }
etape(){ echo; echo "== $* =="; }
fini() {
  [ -n "$PID_JEU" ] && kill "$PID_JEU" 2>/dev/null
  [ -n "$PID_XVFB" ] && kill "$PID_XVFB" 2>/dev/null
  exit "$1"
}
trap 'fini 3' INT TERM

sauvegarde_du_profil() { echo "$1/godot/app_userdata/Eclats d'Orage/saves/slot0.json"; }

fabriquer_slot() {  # $1 = profil, $2 = JSON du payload `data`
  local fichier; fichier="$(sauvegarde_du_profil "$1")"
  mkdir -p "$(dirname "$fichier")"
  python3 - "$fichier" "$2" "$HORODATAGE_SEME" <<'PYEOF'
import json, sys
fichier, data, SEME = sys.argv[1], json.loads(sys.argv[2]), sys.argv[3]
enveloppe = {"schema_version": 4, "slot": "slot0",
             "saved_at_utc": SEME, "data": data}
open(fichier, "w", encoding="utf-8").write(json.dumps(enveloppe, indent="  "))
PYEOF
}

lire_champ_slot() {  # $1 = profil, $2 = expression python sur d
  python3 - "$(sauvegarde_du_profil "$1")" "$2" <<'PYEOF'
import json, sys
try:
    d = json.load(open(sys.argv[1]))["data"]
    print(eval(sys.argv[2], {"d": d}))
except Exception as e:
    print("ERREUR_LECTURE:%s" % type(e).__name__)
PYEOF
}

lancer_jeu() {  # $1 = profil
  PROFIL="$1"
  # UN JOURNAL PAR LANCEMENT. G4 relance sur le profil de G2/G3 : un nom de
  # journal dérivé du seul profil faisait `rm -f` sur la preuve brute de
  # l'étape précédente, et seul le stdout du portail en réchappait.
  LANCEMENT=$((LANCEMENT + 1))
  JOURNAL_JEU="$JOURNAUX/garnison_${LANCEMENT}_$(basename "$PROFIL").log"
  JOURNAUX_JEU="$JOURNAUX_JEU $JOURNAL_JEU"
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
    # VISER PAR LE PID, jamais `tail -1`. Quand une étape précédente a
    # laissé un processus en cours d'arrêt, sa fenêtre est encore visible :
    # `tail -1` pouvait la désigner, la demande de fermeture partait au
    # mauvais jeu, et l'étape échouait en accusant le bon.
    for w in $(DISPLAY="$DISPLAY_NUM" xdotool search --onlyvisible \
        --name "$TITRE_FENETRE" 2>/dev/null); do
      if [ "$(DISPLAY="$DISPLAY_NUM" xdotool getwindowpid "$w" 2>/dev/null)" \
           = "$PID_JEU" ]; then FENETRE="$w"; break; fi
    done
    [ -n "$FENETRE" ] && break
    sleep 1
  done
  [ -n "$FENETRE" ] || { echo "BLOQUÉ: fenêtre introuvable" >&2; return 1; }
  DISPLAY="$DISPLAY_NUM" xdotool windowfocus --sync "$FENETRE" 2>/dev/null || true
  DISPLAY="$DISPLAY_NUM" xdotool windowraise "$FENETRE" 2>/dev/null || true
  sleep 3
  DISPLAY="$DISPLAY_NUM" xdotool windowfocus --sync "$FENETRE" 2>/dev/null || true
  return 0
}

attendre_motif() {
  local trouve=0
  for _ in $(seq 1 "$DELAI_JALON"); do
    if grep -qF "$1" "$JOURNAL_JEU" 2>/dev/null; then trouve=1; break; fi
    kill -0 "$PID_JEU" 2>/dev/null || break
    sleep 1
  done
  [ "$trouve" -eq 1 ]
}

fermer_fenetre() {
  # Le seul geste fidèle est le ClientMessage WM_PROTOCOLS/WM_DELETE_WINDOW :
  # `xdotool windowclose` DÉTRUIT la fenêtre et le jeu ne reçoit jamais la
  # demande (mesuré, portail T1 run 1).
  #
  # COMBIEN DE TEMPS ATTENDRE, ET POURQUOI CE N'EST PAS 30 s. Mesuré le
  # 2026-08-28, scénario G5 seul sur la machine : sur un profil au cache de
  # shaders FROID, le premier rendu llvmpipe d'une vallée complète occupe la
  # boucle principale, et l'événement X n'est lu qu'ensuite. Le jeu a mis
  # **32 s** à mourir — deux secondes de plus que l'ancien budget de 30 s. Le
  # MÊME scénario, cache chaud, meurt en 2 s. Un budget serré ne mesurait donc
  # pas la fermeture : il mesurait la compilation des shaders, et rendait le
  # portail rouge pour une raison qui n'a rien à voir avec ce qu'il prouve.
  # On publie l'attente RÉELLE à chaque appel : le jour où elle dérive, on le
  # lira au lieu de le subir.
  local t0=$SECONDS
  DISPLAY="$DISPLAY_NUM" python3 "$ARBRE/tools/x11_fermer_fenetre.py" \
    "$FENETRE" || true
  for _ in $(seq 1 "$DELAI_FERMETURE"); do
    kill -0 "$PID_JEU" 2>/dev/null || break
    sleep 1
  done
  if kill -0 "$PID_JEU" 2>/dev/null; then
    # NE JAMAIS LAISSER D'ORPHELIN. Un jeu resté vivant garde llvmpipe à fond
    # ET sa fenêtre visible : l'étape suivante hérite d'une machine chargée et
    # d'une fenêtre parasite. C'est ainsi que G5 a fait tomber G6 le
    # 2026-08-28 — deux échecs affichés pour une seule cause.
    echo "        (fermeture refusée après ${DELAI_FERMETURE}s — processus tué)"
    kill "$PID_JEU" 2>/dev/null
    for _ in $(seq 1 20); do kill -0 "$PID_JEU" 2>/dev/null || break; sleep 1; done
    kill -9 "$PID_JEU" 2>/dev/null
    wait "$PID_JEU" 2>/dev/null
    PID_JEU=""
    return 1
  fi
  echo "        (fermeture honorée en $((SECONDS - t0)) s)"
  PID_JEU=""
  return 0
}

balayer_ressources() {  # $1 = journal  $2 = ce que ce journal a chargé
  # Zéro ressource manquante — la famille ISS-071, qui n'existe QUE dans un PCK.
  # `grep -c` sur un fichier absent rend vide, et `${:-0}` le transformerait en
  # « zéro manquant » : un journal disparu deviendrait une bonne nouvelle. Et
  # la branche « journal absent » ne doit PAS retomber sur un PASS affiché —
  # un verdict global rouge n'excuse pas une ligne verte fausse à l'écran.
  if [ ! -s "$1" ]; then
    ko "journal absent ou vide ($2) — impossible de conclure sur les ressources"
    return
  fi
  local n
  n="$(grep -cE "modèle inconnu|modèle végétal introuvable|Failed loading resource|No loader found|Resource file not found|Cannot open file" "$1" || true)"
  [ "${n:-0}" -eq 0 ] \
    && ok "aucun modèle ni ressource manquant dans le PCK — $2" \
    || ko "$n ligne(s) de ressource manquante dans le PCK — $2"
}

continuer() {  # presse « Continuer » du menu (premier bouton, focus par défaut)
  DISPLAY="$DISPLAY_NUM" xdotool key --clearmodifiers Return 2>/dev/null || true
  sleep 2
}

# ------------------------------------------------------------------ étapes --
etape "G1. l'artefact mesuré est-il CELUI du commit courant ?"
[ -x "$BINAIRE" ] || { echo "BLOQUÉ: binaire absent : $BINAIRE (lancer gate_export_parite.sh)" >&2; fini 3; }
SHA="$(cd "$ARBRE" && git rev-parse HEAD)"
SHA_ENREG="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['sha_git_teste'])" \
  "$SORTIE/contexte.json" 2>/dev/null || echo "")"
if [ "$SHA_ENREG" != "$SHA" ]; then
  echo "BLOQUÉ: la build vient de $SHA_ENREG, le dépôt est à $SHA." >&2
  echo "        Relancer gate_export_parite.sh pour exporter l'arbre courant." >&2
  fini 3
fi
# Le SHA seul ne suffit pas : une build exportée d'un arbre SALE porte quand
# même le SHA de HEAD, et « liée au commit courant » serait alors un titre
# mensonger. `gate_export_parite.sh` enregistre le compte de fichiers sales ;
# il faut le LIRE, pas seulement l'écrire.
SALES="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('fichiers_sales','?'))" \
  "$SORTIE/contexte.json" 2>/dev/null || echo "?")"
if [ "$SALES" != "0" ]; then
  echo "BLOQUÉ: la build vient d'un arbre SALE ($SALES fichier(s)) — le SHA ne" >&2
  echo "        décrit pas ce qui a été exporté. Relancer gate_export_parite.sh." >&2
  fini 3
fi
ok "build liée au commit courant ($SHA), arbre propre à l'export"

command -v Xvfb >/dev/null    || { echo "BLOQUÉ: Xvfb absent" >&2; fini 3; }
command -v xdotool >/dev/null || { echo "BLOQUÉ: xdotool absent" >&2; fini 3; }
# -noreset : sans lui, Xvfb se réinitialise quand son dernier client part et
# efface l'atome WM_DELETE_WINDOW ; Godot l'interne avec only_if_exists=true,
# donc la croix deviendrait physiquement inopérante (lu dans le source moteur).
Xvfb "$DISPLAY_NUM" -screen 0 "${LARGEUR}x${HAUTEUR}x24" -noreset \
  > "$JOURNAUX/xvfb_garnison.log" 2>&1 &
PID_XVFB=$!
sleep 3
DISPLAY="$DISPLAY_NUM" python3 -c "
import Xlib.display
d = Xlib.display.Display()
d.intern_atom('WM_PROTOCOLS'); d.intern_atom('WM_DELETE_WINDOW'); d.sync()
" 2>/dev/null || true

# --- G2 + G3 : le héros marche jusqu'au camp, et la garnison le voit -------
etape "G2/G3. arrivée réelle au camp, et zéro ressource manquante"
P1="$SORTIE/profil_garnison_g3"; rm -rf "$P1"; mkdir -p "$P1"
# Une partie en cours, posée sur l'approche NORD du camp : le héros a encore
# du chemin à faire, et il le fera au clavier.
fabriquer_slot "$P1" '{"schema":4,"world_version":"neris_v2",
  "checkpoint":"world_v2.valley","playtime_seconds":300.0,
  "boss_defeated":false,
  "player_position":{"x":36.0,"y":8.0,"z":100.0},"player_yaw":3.14159}'
lancer_jeu "$P1" || fini 3
continuer
attendre_motif "[peuplement] garnison :" || { ko "la garnison n'est jamais bâtie"; }
LIGNE_POSE="$(grep -F "[peuplement] garnison :" "$JOURNAL_JEU" | head -1)"
echo "        $LIGNE_POSE"
case "$LIGNE_POSE" in
  *"4 posé(s), 0 déjà tombé(s)"*) ok "quatre gardes posés, aucun déjà tombé" ;;
  *) ko "compte de garnison inattendu : $LIGNE_POSE" ;;
esac

# Marche RÉELLE vers le sud (le camp), touche physique w = Z sur AZERTY.
DISPLAY="$DISPLAY_NUM" xdotool windowfocus --sync "$FENETRE" 2>/dev/null || true
DISPLAY="$DISPLAY_NUM" xdotool keydown w
sleep "$MARCHE_MUR_S"
DISPLAY="$DISPLAY_NUM" xdotool keyup w
sleep 3

if grep -qF "[peuplement] engagement :" "$JOURNAL_JEU"; then
  ok "un garde a VU le héros arriver : $(grep -F '[peuplement] engagement :' "$JOURNAL_JEU" | head -1 | sed 's/.*engagement : //')"
else
  ko "aucun engagement après ${MARCHE_MUR_S}s de marche — le héros n'est pas arrivé à portée"
fi

fermer_fenetre || { ko "le jeu n'a pas quitté sur la croix"; }
POS_APRES="$(lire_champ_slot "$P1" "d.get('player_position')")"
echo "        position sauvegardée : $POS_APRES"
DEPLACEMENT="$(python3 - "$P1" <<'PYEOF'
import json, sys, math
f = sys.argv[1] + "/godot/app_userdata/Eclats d'Orage/saves/slot0.json"
try:
    p = json.load(open(f))["data"].get("player_position")
    if not p: print("nan"); raise SystemExit
    print("%.2f" % math.dist((p["x"], p["z"]), (36.0, 100.0)))
except Exception:
    print("nan")
PYEOF
)"
if [ "$DEPLACEMENT" = "nan" ]; then
  ko "aucune position lisible après la croix"
else
  awk -v d="$DEPLACEMENT" 'BEGIN{exit !(d > 5.0)}' \
    && ok "le héros a RÉELLEMENT marché : ${DEPLACEMENT} m depuis son point de reprise" \
    || ko "déplacement de ${DEPLACEMENT} m seulement — la marche n'a pas eu lieu"
fi

balayer_ressources "$JOURNAL_JEU" "la vallée (G2/G3)"
PREMIER_JOURNAL="$JOURNAL_JEU"

# --- G4 : aucune duplication d'une relance à l'autre -----------------------
etape "G4. aucune duplication au redémarrage"
lancer_jeu "$P1" || fini 3
continuer
attendre_motif "[peuplement] garnison :" || ko "garnison absente à la relance"
NB_LIGNES="$(grep -cF "[peuplement] garnison :" "$JOURNAL_JEU")"
LIGNE2="$(grep -F "[peuplement] garnison :" "$JOURNAL_JEU" | head -1)"
echo "        $LIGNE2  (lignes de peuplement : $NB_LIGNES)"
case "$LIGNE2" in
  *"4 posé(s)"*) ok "quatre gardes, pas huit — aucune duplication" ;;
  *) ko "compte inattendu à la relance : $LIGNE2" ;;
esac
# Et UNE SEULE construction dans le processus : deux passages du bâtisseur
# afficheraient deux lignes « 4 posé(s) » — huit gardes dans le monde — sans
# que le test de contenu ci-dessus ne bronche.
[ "$NB_LIGNES" -eq 1 ] \
  && ok "le bâtisseur n'a construit QU'UNE fois dans ce processus" \
  || ko "$NB_LIGNES constructions dans un seul processus — duplication"
fermer_fenetre || ko "le jeu n'a pas quitté (G4)"

# --- G5 : une mort traverse un VRAI redémarrage de processus ---------------
etape "G5. une garnison tombée reste tombée après fermeture et « Continuer »"
P2="$SORTIE/profil_garnison_g5"; rm -rf "$P2"; mkdir -p "$P2"
fabriquer_slot "$P2" '{"schema":4,"world_version":"neris_v2",
  "checkpoint":"world_v2.valley","playtime_seconds":600.0,
  "boss_defeated":false,
  "enemies_slain":["garrison.ember_camp.red.01","garrison.ember_camp.blue.01"]}'
lancer_jeu "$P2" || fini 3
continuer
attendre_motif "[peuplement] garnison :" || ko "garnison absente (G5)"
LIGNE3="$(grep -F "[peuplement] garnison :" "$JOURNAL_JEU" | head -1)"
echo "        $LIGNE3"
case "$LIGNE3" in
  *"2 posé(s), 2 déjà tombé(s)"*) ok "deux gardes seulement : les deux morts du slot ne reviennent pas" ;;
  *) ko "les morts persistées ne sont pas honorées : $LIGNE3" ;;
esac
fermer_fenetre || ko "le jeu n'a pas quitté (G5)"
# LA MOITIÉ QUI MANQUAIT. Ci-dessus, on a prouvé que le jeu SAIT LIRE les
# morts du slot. On n'avait rien prouvé sur l'ÉCRITURE : la fermeture réécrit
# la sauvegarde (G2/G3 s'en sert pour relire la position), et une régression
# d'export qui perdrait `enemies_slain` à ce moment-là passait vert — pour
# ressusciter les quatre gardes au lancement suivant, chez le joueur.
MORTS_APRES="$(lire_champ_slot "$P2" "sorted(d.get('enemies_slain',[]))")"
echo "        enemies_slain après la croix : $MORTS_APRES"
case "$MORTS_APRES" in
  *"garrison.ember_camp.blue.01"*)
    case "$MORTS_APRES" in
      *"garrison.ember_camp.red.01"*)
        ok "les deux morts SURVIVENT à la réécriture de fermeture" ;;
      *) ko "red.01 a disparu du slot à la fermeture : $MORTS_APRES" ;;
    esac ;;
  *) ko "les morts n'ont pas survécu à la fermeture : $MORTS_APRES" ;;
esac

# --- G6 : l'inventaire de l'antichambre survit (ISS-080) -------------------
etape "G6. l'inventaire de l'antichambre survit à la reprise"
P3="$SORTIE/profil_garnison_g6"; rm -rf "$P3"; mkdir -p "$P3"
fabriquer_slot "$P3" '{"schema":4,"world_version":"neris_v2",
  "checkpoint":"dungeon.antechamber","playtime_seconds":900.0,
  "boss_defeated":false,
  "weapons":[{"id":"conductive_blade","durability":9},
             {"id":"heavy_axe","durability":17},
             {"id":"simple_bow","durability":25}],
  "equipped_index":1,"arrows":37,
  "ingredients":{"storm_berry":3,"heal_fruit":2},
  "meals":[{"valid":true,"heal":42,"effect":"electric_resist","duration":180.0}]}'
lancer_jeu "$P3" || fini 3
continuer
attendre_motif "[flow] transition vers : res://scenes/dungeon/rooms/Antechamber.tscn" \
  && ok "« Continuer » route vers l'antichambre" \
  || ko "le menu n'a pas routé vers l'antichambre"
sleep 8
fermer_fenetre || ko "le jeu n'a pas quitté (G6)"
# LA GARDE QUI MANQUAIT, et c'est exactement le mode de panne que C11 avait
# refusé : si l'antichambre n'écrit RIEN — écriture cassée, refusée, ou
# fermeture avant le `call_deferred` — le slot semé reste intact, les quatre
# valeurs concordent, et ce gate serait vert en n'ayant rien prouvé. On exige
# donc d'abord la PREUVE qu'une écriture a eu lieu : `SaveSystem` réhorodate
# à chaque `save_slot`, et la graine porte un horodatage figé.
HORODATAGE="$(python3 - "$(sauvegarde_du_profil "$P3")" <<'PYEOF'
import json, sys
try:
    print(json.load(open(sys.argv[1])).get("saved_at_utc", "?"))
except Exception:
    print("ERREUR_LECTURE")
PYEOF
)"
if [ "$HORODATAGE" = "$HORODATAGE_SEME" ]; then
  ko "l'antichambre n'a RIEN écrit (horodatage inchangé) — la comparaison qui suit ne prouverait rien"
elif [ "$HORODATAGE" = "ERREUR_LECTURE" ]; then
  ko "slot illisible après la reprise antichambre"
else
  ok "une écriture a RÉELLEMENT eu lieu (horodatage : $HORODATAGE)"
fi
NB_ARMES="$(lire_champ_slot "$P3" "len(d.get('weapons',[]))")"
FLECHES="$(lire_champ_slot "$P3" "d.get('arrows')")"
BAIES="$(lire_champ_slot "$P3" "d.get('ingredients',{}).get('storm_berry')")"
PLATS="$(lire_champ_slot "$P3" "len(d.get('meals',[]))")"
echo "        armes=$NB_ARMES flèches=$FLECHES storm_berry=$BAIES plats=$PLATS"
if [ "$NB_ARMES" = "3" ] && [ "$FLECHES" = "37" ] && [ "$BAIES" = "3" ] && [ "$PLATS" = "1" ]; then
  ok "l'inventaire est INTACT après la reprise dans l'antichambre (ISS-080)"
else
  ko "l'inventaire a été altéré : armes=$NB_ARMES (3) flèches=$FLECHES (37) baies=$BAIES (3) plats=$PLATS (1)"
fi

# --- G7 : le PCK, sur TOUS les journaux, pas seulement celui de la vallée ---
# La famille ISS-071 est ce que le portail dit exister pour attraper. Ne
# balayer que le journal de G2/G3 laissait le DONJON hors du filet : une
# ressource d'antichambre absente du PCK serait passée verte. On balaie donc
# chaque journal produit par ce run, et on publie combien il y en avait —
# « aucune ressource manquante » sans « sur N journaux » ne prouve rien.
etape "G7. aucune ressource manquante — sur TOUS les journaux de ce run"
NB_JOURNAUX=0
for j in $JOURNAUX_JEU; do
  NB_JOURNAUX=$((NB_JOURNAUX + 1))
  [ "$j" = "$PREMIER_JOURNAL" ] && continue   # déjà balayé, nommé, en G2/G3
  balayer_ressources "$j" "$(basename "$j")"
done
echo "        $NB_JOURNAUX journal(aux) de jeu examiné(s) dans ce run"
[ "$NB_JOURNAUX" -ge 4 ] \
  || ko "seulement $NB_JOURNAUX journal(aux) — un lancement a manqué"

# ------------------------------------------------------------------ verdict --
echo
echo "NON VÉRIFIÉ ICI, ET PROUVÉ EN MOTEUR PAR test_world_v2_garrison_combat.gd :"
echo "  dégâts dans les deux sens · victoire de la garnison · mort du héros et"
echo "  « Réessayer ». Un clavier synthétique sous Xvfb en rendu logiciel ne"
echo "  peut pas en faire une mesure déterministe."
echo
if [ "$ECHECS" -eq 0 ]; then
  echo "GATE_EXPORT_GARNISON : VERT (0 échec)"
  CODE=0
else
  echo "GATE_EXPORT_GARNISON : ROUGE ($ECHECS échec(s))"
  CODE=1
fi
fini "$CODE"
