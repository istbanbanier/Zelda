#!/usr/bin/env bash
# Pyramide de validation, niveaux 1-3 (MASTER_SPEC §21.7). Quelques minutes max.
#   1. Parse/import smoke : le projet importe et quitte sans parse error.
#   2. Unit               : données, formules, graphes, sérialisation, règles pures.
#   3. Integration scene  : quelques systèmes raccordés dans une scène minimale.
#
# Code retour 0 = tout vert. Non nul = au moins un niveau rouge.
# Ce script n'exécute AUCUNE capture ni mesure de performance : voir validate_release.sh.
set -uo pipefail

cd "$(dirname "$0")/.."
PROJECT_DIR="$PWD"
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"
LOG_DIR="${LOG_DIR:-evidence/validate_fast}"
mkdir -p "$LOG_DIR"

FAIL=0
step() { printf '\n=== %s ===\n' "$1"; }
ok()   { echo "  [OK]   $1"; }
bad()  { echo "  [ÉCHEC] $1"; FAIL=1; }

if [ ! -x "$GODOT_BIN" ]; then
  echo "ÉCHEC BLOQUANT: binaire Godot absent ($GODOT_BIN). Lancer tools/setup_godot.sh." >&2
  exit 2
fi

# --- UNE SEULE SUITE À LA FOIS -------------------------------------------
# Le 2026-08-11, deux runners ont tourné EN MÊME TEMPS : une première suite
# tuée par pkill avait laissé un godot survivant (mesuré : 3 processus encore
# vivants 1 s après le kill), qui a continué pendant que la suivante
# démarrait. Les deux partageaient user://saves et 02_unit.log — résultat :
# 8 échecs de sauvegarde FABRIQUÉS (durabilité 24, flèches 8, joueur au
# spawn : la sauvegarde neuve de l'autre processus), une ligne de log coupée
# en plein mot, et deux lignes « === RÉSULTAT » que l'étape 4 a flaguées.
# C'est l'équivalent machine de la règle n°1 de COMMENT_TRAVAILLER_ENSEMBLE.
#
# DEUX couches, parce qu'elles n'attrapent pas la même chose :
#
#  1. le VERROU (flock) est atomique : deux validate_fast lancés dans la même
#     milliseconde ne peuvent pas tous deux le prendre — le pgrep seul avait
#     cette fenêtre. Pris sur un descripteur tenu par TOUT le script, libéré
#     par le noyau à la sortie quelle qu'elle soit (crash et kill compris :
#     c'est le descripteur qui meurt, pas un fichier à nettoyer). Par projet :
#     le fichier vit dans .git/, deux clones ne se gênent pas.
#  2. le pgrep attrape ce que le verrou ne voit pas : un runner SURVIVANT
#     lancé hors de ce script (gate_select, run à la main, orphelin d'un
#     kill) qui partagerait quand même user://saves.
#
# Sortie en 3 (BLOQUÉ), jamais en silence : .claude/rules/evidence.md.
# DANS UN ARBRE DE TRAVAIL GIT, `.git` EST UN FICHIER, PAS UN DOSSIER.
# Mesuré le 2026-08-19 depuis /home/user/zelda-r2b2/a_ferme :
#   .git/validate_fast.lock: Not a directory ; flock: 9: Bad file descriptor
#   -> BLOQUÉ (code 3) alors qu'aucune suite ne tournait.
# La règle du projet EXIGE un arbre de travail séparé par tâche (CLAUDE.md) :
# le verrou doit donc suivre le dépôt, pas le répertoire. `--git-common-dir`
# et non `--git-dir` : c'est le .git PARTAGÉ, et c'est bien ce qu'on veut —
# deux arbres de travail partagent `user://saves`, donc leurs suites doivent
# se sérialiser. Repli sur l'ancien chemin si git est absent.
LOCK_DIR="$(git -C "$PROJECT_DIR" rev-parse --git-common-dir 2>/dev/null || true)"
case "$LOCK_DIR" in
  "") LOCK_DIR="$PROJECT_DIR/.git" ;;
  /*) ;;
  *)  LOCK_DIR="$PROJECT_DIR/$LOCK_DIR" ;;
esac
LOCK_FILE="$LOCK_DIR/validate_fast.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "BLOQUÉ: une autre suite validate_fast détient le verrou ($LOCK_FILE)." >&2
  echo "        Attendre sa fin — deux suites concurrentes partagent" >&2
  echo "        user://saves et fabriquent des échecs de sauvegarde." >&2
  exit 3
fi
# ISS-063 — LE SECOND VERROU, ET LA CLOISON.
#
# Mesuré le 2026-08-20 (`evidence/world_v2/v2_3_r2b3_1/iss063/`) : ce script
# était le plus gros consommateur de moteur du dépôt — quatre invocations,
# ~20 min — et il ne prenait QUE `validate_fast.lock`. `lancer_godot.sh`, lui,
# ne prend que `heavy_tools.lock`. Deux invocations qui prennent chacune un
# verrou DIFFÉRENT ne se sérialisent pas : elles tournent en parallèle. Nommer
# un verrou n'est pas le prendre.
#
# Les deux sont désormais pris, imbriqués et dans cet ordre :
#   9 = validate_fast.lock  (flock -n : deux suites, échec IMMÉDIAT, c'est voulu)
#   8 = heavy_tools.lock    (flock -w : attendre une sonde ou un export en cours)
# Aucun cycle possible : `lancer_godot.sh` ne prend jamais que le second.
#
# Et la CLOISON, qui n'est pas un verrou : sans `XDG_DATA_HOME`, `user://` dérive
# de `application/config/name` — identique dans TOUS les arbres de travail. Deux
# suites y écrivaient la même sauvegarde. Ici on prend la cloison D'ARBRE, pas
# une éphémère : l'étape 3 relit ce que l'étape 2 a écrit.
# shellcheck source=lib/godot_env.sh
. "$PROJECT_DIR/tools/lib/godot_env.sh"
godot_cloison_arbre || exit 3
godot_verrou_prendre 8 3000 || exit 3

if pgrep -f "test_runner\.gd" >/dev/null 2>&1; then
  echo "BLOQUÉ: un test runner Godot tourne déjà (pgrep -f test_runner.gd)." >&2
  echo "        Il ne tient pas le verrou (lancé hors validate_fast), mais il" >&2
  echo "        partage user://saves. Attendre sa fin ou le tuer, PUIS" >&2
  echo "        vérifier qu'il est mort : pkill laisse des survivants (mesuré)." >&2
  exit 3
fi

step "0. Version du moteur"
VERSION="$("$GODOT_BIN" --version 2>&1 | tail -1)"
echo "  $VERSION"
case "$VERSION" in
  4.7.1.stable*) ok "Godot 4.7.1-stable confirmé" ;;
  *) bad "version inattendue — MASTER_SPEC §5.1 exige 4.7.1-stable" ;;
esac

step "0b. Gel V2.3-B"
# Placé AVANT tout ce qui coûte : quelques millisecondes, et il répond à la
# question qui rend inutile le reste si la réponse est mauvaise — « quelqu'un
# a-t-il touché un élément gelé ? ». Périmètre et raison : tools/gel_verifier.sh.
if tools/gel_verifier.sh; then
  ok "aucun élément gelé n'a bougé"
else
  bad "GEL ROMPU — voir docs/contrats/gel_v2_3_b.sha256 et la directive R2B.3.1 §4"
fi

step "1. Import des ressources (parse/import smoke)"
IMPORT_LOG="$LOG_DIR/01_import.log"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --import > "$IMPORT_LOG" 2>&1
IMPORT_RC=$?
# Godot renvoie 0 même avec des erreurs de script : filtrer explicitement le log.
if grep -qiE 'parse error|SCRIPT ERROR|Failed to load script|Cannot open file|res://.*\.gd:[0-9]+ - Parse Error' "$IMPORT_LOG"; then
  bad "erreurs détectées dans $IMPORT_LOG"
  grep -iE 'parse error|SCRIPT ERROR|Failed to load|Cannot open file' "$IMPORT_LOG" | head -20
elif [ $IMPORT_RC -ne 0 ]; then
  bad "code retour $IMPORT_RC (voir $IMPORT_LOG)"
else
  ok "import sans parse error (code retour 0)"
fi

step "1b. Parse de TOUS les scripts GDScript"
# N9 : l'import ne parse que les scripts atteignables depuis une ressource. Un
# script non référencé pouvait contenir une erreur de syntaxe sans que
# `validate_fast.sh` ne rougisse — la promesse « parse smoke » était fausse.
# Chaque .gd est donc vérifié individuellement avec --check-only.
PARSE_LOG="$LOG_DIR/01b_parse.log"
: > "$PARSE_LOG"
PARSE_FAILED=0
PARSE_COUNT=0
while IFS= read -r script; do
  PARSE_COUNT=$((PARSE_COUNT + 1))
  if ! "$GODOT_BIN" --headless --path "$PROJECT_DIR" --check-only --script "$script" \
       >> "$PARSE_LOG" 2>&1; then
    echo "PARSE ERROR: $script" >> "$PARSE_LOG"
    PARSE_FAILED=$((PARSE_FAILED + 1))
  fi
done < <(find "$PROJECT_DIR" -name '*.gd' -not -path '*/.godot/*' -printf 'res://%P\n' | sort)
if [ $PARSE_FAILED -eq 0 ]; then
  ok "$PARSE_COUNT script(s) GDScript parsés sans erreur"
else
  bad "$PARSE_FAILED script(s) en erreur de parsing sur $PARSE_COUNT (voir $PARSE_LOG)"
  grep -E 'PARSE ERROR|Parse Error' "$PARSE_LOG" | head -10 | sed 's/^/    /'
fi
# Limite honnête (B4) : --check-only vérifie la SYNTAXE et le typage statique, pas
# la résolution des appels dynamiques. `n.methode_inexistante()` passe ce niveau et
# ne plantera qu'à l'exécution. Ce niveau ne remplace donc pas des tests.

step "2. Tests unitaires"
UNIT_LOG="$LOG_DIR/02_unit.log"
# LA SUITE RESTE NON VERBEUSE, ET C'EST UNE DÉCISION MESURÉE.
# `--verbose` donnerait la composition objet par objet du résidu de sortie, ce
# que le portail A aimerait avoir. Mesuré le 2026-08-21 sur cette machine, et
# c'est une mesure, pas une estimation :
#   suite en --verbose ....... 914 tests en 1 590 s, 420 Mo de vidage, et elle
#                              n'avait pas fini a 1 841 s quand je l'ai arretee
#   suite sans --verbose ..... 11 tests/min en regime, soit ~85 min pour 949
# Le facteur exact n'est donc pas etabli — mais `--verbose` est mesurablement
# plus lent ET produit un vidage de plusieurs centaines de Mo. Un controle de ce
# prix a chaque tour finit contourne (PROMPT4_METHOD §0).
# La répartition retenue :
#   * à CHAQUE passe : le portail A sur la signature agrégée, comparée AU CHIFFRE
#     PRÈS au contrat committé. Bon marché, et strict : toute ressource du projet
#     qui survivrait déplacerait ces comptes.
#   * sur COMMANDE et en niveau release : `tools/gate_fuite_composition.sh`, qui
#     relance la suite en `--verbose` et énumère classe par classe.
"$GODOT_BIN" --headless --path "$PROJECT_DIR" \
  --script tools/godot/test_runner.gd > "$UNIT_LOG" 2>&1
UNIT_RC=$?
grep -E '^\s+(ok|ÉCHEC)|^=== RÉSULTAT' "$UNIT_LOG" | sed 's/^/  /'
if [ $UNIT_RC -eq 0 ]; then ok "suite unitaire verte"; else bad "suite unitaire rouge (code $UNIT_RC, voir $UNIT_LOG)"; fi

# Une erreur d'exécution GDScript (déréférencement nul, index hors bornes, format
# invalide) n'interrompt pas l'appel : le test serait compté « ok » et le runner
# sortirait 0. Le journal doit donc être inspecté séparément.
#
# N1 : la première version de ce filtre énumérait des messages précis et laissait
# passer tout `ERROR:` générique — ressource manquante, échec de chargement,
# `push_error` d'un invariant violé. Un asset supprimé laissait la suite verte.
# Le filtre couvre donc maintenant `ERROR:` comme le niveau 3.
# AUDIT 2026-08-09 : les fuites de FIN DE PROCESSUS étaient ignorées. Godot les
# imprime APRÈS le verdict interne du runner, et « ObjectDB instances were
# leaked » est un WARNING, pas une ERROR — le filtre passait donc à côté. Mesuré
# sur `--filter=boot_smoke` : 2 instances audio et `amb_valley.wav` encore
# référencées, parce que `AudioManager` est un autoload et que le test ne rendait
# pas le processus tel qu'il l'avait trouvé. La suite complète, elle, était
# propre — ajouter ces motifs ne masque donc aucune dette existante.
#
# CLÔTURE R2B.3.1 (2026-08-21) : les deux motifs de fuite ajoutés ce jour-là
# (`ObjectDB instances were leaked`, `resources still in use`) SONT RETIRÉS DE CE
# FILTRE — et remplacés par l'étape 2b, qui est STRICTEMENT PLUS SÉVÈRE. Ce n'est
# pas un affaiblissement, et voici pourquoi, vérifiable :
#
# CE QUI EST VRAI, ET CE QUI NE L'EST PAS. Une première rédaction de ce
# commentaire affirmait que le nouveau dispositif est « strictement plus
# sévère ». C'EST FAUX pour ce qui tourne ici, et la revue contradictoire l'a
# démontré par un contre-exemple exécuté. Écrit honnêtement :
#
#   ce filtre-ci        : grep sur deux comptes AGRÉGÉS. Rouge dès qu'un objet
#                         survit, quelle que soit sa nature — donc rouge en
#                         PERMANENCE, puisque le moteur en retient toujours.
#   l'étape 2b, ici     : compare ces mêmes comptes AU CHIFFRE PRÈS à un contrat
#                         committé, et vérifie les classes de RID. Elle ACCEPTE
#                         une enveloppe connue au lieu de rougir dessus. Sur
#                         l'enveloppe 138/74/3, elle est donc PLUS PERMISSIVE.
#   l'étape 2b, en mode composition (tools/gate_fuite_composition.sh) : énumère
#                         classe par classe et chemin par chemin, et exige que
#                         l'ensemble mesuré égale l'ensemble expliqué. CELLE-LÀ
#                         est plus sévère — mais elle n'est pas ici, elle coûte
#                         le triple d'une suite.
#
# Ce qui change est donc bien une SÉPARATION de deux domaines, et elle
# s'accompagne d'une permissivité assumée sur une enveloppe mesurée : un script
# retenu par `GDScriptCache` n'est corrigible par AUCUNE API GDScript (ISS-065)
# et ne peut pas porter un rouge permanent sans entraîner l'équipe à ignorer la
# ligne rouge. Ce que nous surveillons en échange, à chaque passe, c'est que
# cette enveloppe ne bouge pas d'une unité. Décision du lead, tracée dans
# `docs/KNOWN_ISSUES.md` ISS-059 et ISS-065.
UNIT_ERR_PATTERN='SCRIPT ERROR|^ERROR:|ASSERTION ÉCHOUÉE SANS REPORTER|Cannot call method|Invalid access|String formatting error|Out of bounds|Method not found|Cannot open file|Failed loading resource|Resource file not found'
# CHAQUE FAIT A UN SEUL JUGE. Les lignes de FIN DE PROCESSUS du moteur —
# ressources retenues, RID, ObjectDB, PagedAllocator — commencent par `ERROR:`
# et tombaient donc AUSSI dans ce filtre générique, alors que l'étape 2b les
# juge déjà AU CHIFFRE PRÈS contre le contrat committé. Résultat mesuré à la
# première exécution après la clôture : 949 tests verts, portail A VERT,
# télémétrie conforme — et cette étape-ci ROUGE sur les mêmes lignes, avec
# l'ancienne sémantique confondue que la directive supprime. Le même fait jugé
# deux fois par deux juges en désaccord n'est pas une double sécurité, c'est un
# verdict incohérent. Ces lignes RESTENT dans le journal (rien n'est masqué) ;
# elles sont simplement retirées du périmètre de CE juge-ci, parce que 2b est
# le leur. Les deux lignes PagedAllocator suivent le même domaine : ce sont les
# Variant des objets survivants (KNOWN_ISSUES, ISS-059), pas une cause propre.
FIN_DE_PROCESSUS='resources still in use at exit|RID allocations of type|ObjectDB instances were leaked|Pages in use exist at exit in PagedAllocator'
if grep -vE "$FIN_DE_PROCESSUS" "$UNIT_LOG" | grep -qE "$UNIT_ERR_PATTERN"; then
  bad "erreurs signalées pendant la suite de tests (voir $UNIT_LOG)"
  grep -vE "$FIN_DE_PROCESSUS" "$UNIT_LOG" | grep -E "$UNIT_ERR_PATTERN" | head -10 | sed 's/^/    /'
else
  ok "aucune erreur signalée dans le journal des tests (le résidu de sortie est jugé en 2b)"
fi

step "2b. Résidu de fin de processus — DEUX verdicts séparés"
# Pourquoi deux et pas un : voir l'explication de l'étape 2, `ISS-059` et
# `ISS-065`. En résumé — une ressource du PROJET qui survit est un défaut que
# nous pouvons corriger, donc bloquant ; un script retenu par le cache du MOTEUR
# n'est corrigible par aucune API GDScript, donc suivi mais non bloquant TANT
# QU'IL NE DÉRIVE PAS.
#
# Le portail se prouve avant de servir : son propre contrôle négatif tourne
# d'abord, en quelques millisecondes. Douze fixtures, douze verdicts attendus,
# dont huit défauts qui doivent rougir chacun pour sa raison propre. Sans ce
# contrôle, un portail cassé rendrait un vert silencieux — le mode de panne
# exact qu'il existe pour empêcher.
step_gate_ok=1
if ! tools/gate_fuite_controle_negatif.sh; then
  bad "le contrôle négatif du portail de fuite échoue — son verdict ne peut pas être cru"
  step_gate_ok=0
fi

GATE_LOG="$LOG_DIR/02b_fuite.log"
GATE_JSON="$LOG_DIR/02b_fuite.json"
CONTRAT_MOTEUR="docs/contrats/residu_cache_moteur.json"
if [ $step_gate_ok -eq 1 ]; then
  # Aucune ligne brute du moteur n'est masquée : elles sont extraites telles
  # quelles, puis CLASSÉES. L'extraction ne juge pas, elle sélectionne les lignes
  # que le moteur imprime sur le sujet.
  grep -E 'Leaked instance:|Resource still in use:|ObjectDB instances were leaked|resources still in use|RID allocations' \
    "$UNIT_LOG" > "$GATE_LOG" || true
  python3 tools/gate_fuite_ressources.py "$GATE_LOG" --mode=agregat \
    --racine "$PROJECT_DIR" --reference "$CONTRAT_MOTEUR" --json "$GATE_JSON" \
    | sed 's/^/  /'
  GATE_RC=${PIPESTATUS[0]}
  case $GATE_RC in
    0) ok "PROJECT_RESOURCE_LEAK_GATE vert ; télémétrie du cache moteur dans son enveloppe" ;;
    1) bad "PROJECT_RESOURCE_LEAK_GATE ROUGE — une ressource du projet survit (voir $GATE_LOG)" ;;
    2) bad "ENGINE_SCRIPT_CACHE_TELEMETRY EN DÉRIVE — l'enveloppe du cache moteur a bougé.
          Ce n'est PAS une fuite du projet ; si la dérive est attendue (un lot de lieux
          ajoute des scripts et des scènes), entériner le contrat avec
          tools/gate_fuite_composition.sh --entériner et justifier dans DECISIONS.md" ;;
    3) bad "BLOQUÉ — le journal ne permet pas de conclure sur le résidu (voir $GATE_LOG)" ;;
    *) bad "code retour inattendu $GATE_RC du portail de fuite" ;;
  esac
fi

step "2c. Croissance cumulative du résidu (deux cycles dans UN processus)"
# Un résidu STABLE est une empreinte ; un résidu qui CROÎT à chaque montage est
# une fuite. Les deux donnent la même ligne de fin de processus — seule la
# comparaison de deux cycles dans le MÊME processus les distingue, et c'est la
# condition n°3 du portail A. La sonde monte puis démonte `WorldV2.tscn`, la
# seule scène qui portait la signature (mesuré R2B.3.1 : 22 s, contre 97 s pour
# le trio initial).
CYCLE_LOG="$LOG_DIR/02c_cycles.log"
"$GODOT_BIN" --headless --path "$PROJECT_DIR" \
  --script tools/godot/sonde_iss059_proprietaire.gd -- \
  --scenes=worldv2 --cycles=2 --ablation=aucune > "$CYCLE_LOG" 2>&1
CYCLE_RC=$?
# LA SONDE A-T-ELLE VRAIMENT MONTÉ QUELQUE CHOSE ? Sans cette vérification,
# l'étape rendait VERT en ne faisant rien : la sonde replie silencieusement
# `--scenes=` sur « aucune » si l'argument n'arrive pas (un `--` disparu suffit),
# la boucle de montage ne fait alors rien, et deux mesures identiques et
# minuscules donnaient « résidu STABLE ». Un vert obtenu sans travail, sans un
# mot. Trouvé par la revue contradictoire.
MONTAGES=$(grep -cE 'cycle [0-9]+ : worldv2 monte puis demonte' "$CYCLE_LOG")
# Et une scène peut s'INSTANCIER en échouant à se construire — c'est exactement
# le visage du cache de classes périmé (tools/CLAUDE.md). Deux mesures
# identiques et vides passeraient aussi.
#
# EXCLUSION DES LIGNES DE FIN DE PROCESSUS, la même qu'à l'étape 2. La sonde
# TERMINE par le rapport de résidu du moteur — c'est structurel, tout processus
# Godot de ce dépôt l'imprime — et la première version de cette garde comptait
# ces lignes comme « erreurs pendant les cycles » : l'étape ne POUVAIT pas être
# verte. Mesuré à la première exécution : empreintes IDENTIQUES aux deux cycles
# (2876/862/23/0), sonde saine, verdict rouge quand même. Ce qu'on cherche ici,
# ce sont les erreurs PENDANT le montage, pas le constat de sortie.
CYCLE_ERR=$(grep -vE "$FIN_DE_PROCESSUS" "$CYCLE_LOG" | grep -cE 'SCRIPT ERROR|^ERROR:')
# `fin_cycle_` UNIQUEMENT. La sonde imprime aussi une mesure de référence
# `apres_autoloads_avant_tout_cycle`, dont le compte diffère forcément de celui
# d'après un montage : la compter donnerait deux empreintes distinctes sur un
# résidu parfaitement stable, donc un ROUGE FABRIQUÉ. Piège vérifié en lisant la
# sonde avant d'écrire ce filtre, pas après l'avoir vu échouer.
# La ligne ENTIÈRE : la sonde publie objets, ressources, noeuds ET orphelins ;
# n'en comparer que deux jetait deux signaux pour rien.
EMPREINTES=$(grep -oE 'MESURE fin_cycle_[0-9]+ \|.*$' "$CYCLE_LOG" \
  | sed 's/^MESURE fin_cycle_[0-9]* //' | sort -u)
CYCLES=$(printf '%s\n' "$EMPREINTES" | grep -c 'objets=')
NB_MESURES=$(grep -cE 'MESURE fin_cycle_[0-9]+' "$CYCLE_LOG")
grep -E 'MESURE fin_cycle_' "$CYCLE_LOG" | sed 's/^/    /'
if [ $CYCLE_RC -ne 0 ]; then
  bad "la sonde est sortie en $CYCLE_RC — sa mesure ne peut pas être crue (voir $CYCLE_LOG)"
elif [ "$MONTAGES" -lt 2 ]; then
  bad "$MONTAGES montage(s) de WorldV2 au lieu de 2 — la sonde n'a rien monté (voir $CYCLE_LOG)"
elif [ "$CYCLE_ERR" -gt 0 ]; then
  bad "$CYCLE_ERR erreur(s) pendant les cycles — la scène s'est montée en échouant (voir $CYCLE_LOG)"
elif [ "$NB_MESURES" -lt 2 ]; then
  bad "$NB_MESURES mesure(s) de fin de cycle au lieu de 2 — la sonde n'a pas mesuré (voir $CYCLE_LOG)"
elif [ "$CYCLES" = "1" ]; then
  ok "$MONTAGES montages, $NB_MESURES mesures, UNE empreinte — résidu STABLE"
else
  bad "$CYCLES empreintes différentes sur $NB_MESURES cycles — le résidu CROÎT (voir $CYCLE_LOG)"
fi

step "3. Scène d'intégration (lancement réel : Boot -> MainMenu)"
SCENE_LOG="$LOG_DIR/03_scene.log"
# Assez de frames pour que la transition de SceneFlow aboutisse réellement : le
# but de ce niveau est d'exercer le chemin de démarrage complet, pas seulement de
# constater que la première scène se charge.
"$GODOT_BIN" --headless --path "$PROJECT_DIR" --quit-after 90 > "$SCENE_LOG" 2>&1
SCENE_RC=$?
if grep -qiE 'SCRIPT ERROR|Failed to instantiate|Cannot open|ERROR:' "$SCENE_LOG"; then
  bad "erreurs au chargement de la scène (voir $SCENE_LOG)"
  grep -iE 'SCRIPT ERROR|ERROR:' "$SCENE_LOG" | head -10
elif [ $SCENE_RC -ne 0 ]; then
  bad "code retour $SCENE_RC (voir $SCENE_LOG)"
else
  ok "scène principale chargée et quittée proprement"
  grep '^\[boot\]' "$SCENE_LOG" | sed 's/^/    /'
fi

# Le démarrage doit réellement atteindre le menu. Sans ce contrôle, une
# transition cassée passerait inaperçue tant que Boot lui-même se charge.
if grep -q 'transition vers le menu principal' "$SCENE_LOG"; then
  ok "Boot atteint le menu principal"
else
  bad "Boot n'a pas enchaîné sur le menu principal (voir $SCENE_LOG)"
fi

step "3b. Continuité des personnages livrés (ISS-019)"
# ISS-018 : les créatures s'affichaient en pièces détachées alors que TOUS les
# tests étaient verts, parce qu'ils mesuraient des boîtes englobantes — et
# qu'une boîte englobante de maillage SKINNÉ décrit la pose de liaison, pas ce
# que le moteur dessine. Aucun assemblage n'était donc jamais vérifié.
#
# Ce niveau lit la géométrie du .glb LIVRÉ après évaluation du graphe de
# dépendances, donc APRÈS déformation par l'armature, et exige que chaque
# personnage forme UN SEUL corps solidaire. Il tourne en quelques secondes.
CONT_LOG="$LOG_DIR/03b_continuity.log"
: > "$CONT_LOG"
BLENDER_BIN="${BLENDER_BIN:-blender}"
if ! command -v "$BLENDER_BIN" >/dev/null 2>&1; then
  bad "Blender absent — la continuité des personnages n'est PAS vérifiée"
else
  CONT_FAILED=0
  CONT_COUNT=0
  while IFS='|' read -r label glb; do
    [ -f "$glb" ] || { bad "modèle absent : $glb"; continue; }
    CONT_COUNT=$((CONT_COUNT + 1))
    if ! "$BLENDER_BIN" --background --python tools/blender/check_continuity.py -- \
         --glb "$glb" --label "$label" >> "$CONT_LOG" 2>&1; then
      CONT_FAILED=$((CONT_FAILED + 1))
    fi
  done <<'MODELS'
colosse|assets/characters/creatures/SK_RavineTroll.glb
chasseur|assets/characters/creatures/SK_CentaurHunter.glb
gardien|assets/characters/boss/SK_StormGuardian.glb
raider_red|assets/characters/enemies/SK_RaiderRed.glb
raider_blue|assets/characters/enemies/SK_RaiderBlue.glb
raider_black|assets/characters/enemies/SK_RaiderBlack.glb
MODELS
  grep -E '^\[continuité\] .* : (UN SEUL|[0-9]+ (PIÈCE|GRAPPE))' "$CONT_LOG" \
    | sed 's/^/    /'
  if [ $CONT_FAILED -eq 0 ]; then
    ok "$CONT_COUNT personnage(s) : un seul corps solidaire, aucune pièce détachée"
  else
    bad "$CONT_FAILED personnage(s) en pièces détachées sur $CONT_COUNT (voir $CONT_LOG)"
  fi
fi

step "4. Plancher de couverture"
# B1 : renommer un fichier de test faisait disparaître 3 tests sans que rien ne
# rougisse. Le nombre de tests attendu est donc épinglé ; le baisser exige une
# modification explicite de ce fichier, visible en revue.
# Q3 (4e revue) : `head -1` prenait la PREMIÈRE ligne « === RÉSULTAT », qu'un test
# pouvait imprimer lui-même pour annoncer 99 réussites alors que 9 tests tournaient.
# On prend la dernière (celle du runner) et on refuse toute ligne en double.
# Le plancher est une constante du fichier : l'abaisser doit se voir en revue, il
# n'est donc pas surchargeable par l'environnement.
MIN_TESTS=586
RESULT_LINES=$(grep -cE '^=== RÉSULTAT: [0-9]+ réussi' "$UNIT_LOG")
ACTUAL_TESTS=$(grep -oE '^=== RÉSULTAT: [0-9]+ réussi' "$UNIT_LOG" | grep -oE '[0-9]+' | tail -1)
ACTUAL_TESTS="${ACTUAL_TESTS:-0}"
if [ "$RESULT_LINES" -gt 1 ]; then
  bad "$RESULT_LINES lignes « === RÉSULTAT » dans le journal — un test imprime-t-il un faux résumé ?"
elif [ "$ACTUAL_TESTS" -ge "$MIN_TESTS" ]; then
  ok "$ACTUAL_TESTS test(s) exécuté(s), plancher $MIN_TESTS respecté"
else
  bad "$ACTUAL_TESTS test(s) exécuté(s) pour un plancher de $MIN_TESTS — couverture perdue en silence ?"
fi

printf '\n=== VALIDATE_FAST : %s ===\n' "$([ $FAIL -eq 0 ] && echo VERT || echo ROUGE)"
echo "logs: $LOG_DIR"
exit $FAIL
