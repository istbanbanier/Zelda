#!/usr/bin/env bash
# CONTRÔLE NÉGATIF du lot 1 (V2.3-B) — un contrôle par famille de défaut D1..D8.
#
# Un filet qui n'a jamais rougi ne prouve rien : il peut être vert parce que le
# lot va bien, ou parce qu'il ne regarde rien. C'est ISS-018, mot pour mot —
# les créatures s'affichaient en pièces détachées avec TOUS les tests verts.
# Ce script tranche : il casse volontairement quelque chose et exige que le
# filet le VOIE, et qu'il le voie SUR SON PROPRE CRITÈRE.
#
# Protocole, repris de `tools/gate_negative_control.sh` (déjà accepté) :
#   1. le sabotage vit dans un worktree ISOLÉ, jamais dans l'arbre de travail ;
#   2. on lance le filet ;
#   3. on exige un échec dont le libellé CORRESPOND à la signature attendue —
#      une erreur de parsing ou un échec sans rapport ne compte PAS ;
#   4. on détruit la copie.
#
# ─────────────────────────────────────────────────────────────────────────────
# DEUX MODES, ET POURQUOI. Le filet `test_world_v2_lot1_defauts.gd` juge les SIX
# lieux du lot. Tant que les voies A et B ne les ont pas livrés, D1 à D7 ne
# peuvent PAS être éprouvés sur leurs vrais sujets : les saboter reviendrait à
# saboter des fichiers qui n'existent pas.
#
#   --temoin  (aujourd'hui) sabote les INSTRUMENTS eux-mêmes et les éléments
#             gelés. Il prouve qu'un compteur dégradé, une mesure remplacée par
#             la mauvaise propriété, ou un octet changé dans le gel FONT ROUGIR.
#             C'est exactement la leçon d'ISS-018 : la panne dangereuse n'est
#             pas le lieu raté, c'est l'instrument aveugle.
#   --lot1    (défaut) sabote les six lieux, cibles RÉSOLUES depuis le REGISTRY
#             au moment du lancement — jamais un nom de fichier deviné, parce
#             que les voies A et B choisissent leurs noms. Un sujet absent rend
#             `BLOQUÉ`, pas « ignoré » : un sabotage qu'on n'a pas pu jouer
#             n'est pas un sabotage réussi.
#
# Usage :  tools/gate_negatif_lot1.sh [--temoin|--lot1] [--seulement=D1,D8]
# Codes :  0 = tous les sabotages joués ET vus pour la bonne raison
#          1 = au moins un inaperçu, non joué, ou vu pour autre chose
#          3 = BLOQUÉ (moteur absent, ou sujets du lot non construits)
set -uo pipefail

cd "$(dirname "$0")/.."
REPO="$PWD"
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"
FILTER="lot1_defauts"

# ISS-063 — verrou canonique + cloison `user://`.
# shellcheck source=lib/godot_env.sh
. "$PWD/tools/lib/godot_env.sh"
godot_cloison_arbre || exit 3
godot_verrou_prendre 8 3000 || exit 3

MODE="lot1"
SEULEMENT=""
for arg in "$@"; do
  case "$arg" in
    --temoin) MODE="temoin" ;;
    --lot1)   MODE="lot1" ;;
    --seulement=*) SEULEMENT="${arg#*=}" ;;
    -h|--help) sed -n '2,40p' "$0"; exit 0 ;;
    *) echo "argument inconnu : $arg" >&2; exit 2 ;;
  esac
done

command -v "$GODOT_BIN" >/dev/null 2>&1 || {
  echo "BLOQUÉ: moteur absent ($GODOT_BIN)" >&2; exit 3; }

FILET="tests/world_v2/test_world_v2_lot1_defauts.gd"
JOURNAUX="evidence/world_v2/v2_3_b/lot1/controles"
mkdir -p "$JOURNAUX"

# ─── Résolution des cibles du lot, depuis le REGISTRY et le layout ───────────
# Jamais un nom de fichier deviné : les voies A et B nomment leurs scènes, et
# une cible périmée produirait « fichier absent », donc un contrôle qui se tait.
resoudre() {  # $1 = place_id ; imprime "scene<TAB>script<TAB>x<TAB>z"
  python3 - "$1" <<'PY'
import json, re, sys
pid = sys.argv[1]
reg = open("scripts/world_v2/poi/world_v2_places_builder.gd", encoding="utf-8").read()
m = re.search(r'&"' + re.escape(pid) + r'"\s*:\s*\n?\s*"([^"]+)"', reg)
scene = m.group(1).replace("res://", "") if m else ""
script = ""
if scene:
    try:
        txt = open(scene, encoding="utf-8").read()
        s = re.search(r'\[ext_resource type="Script"[^\]]*path="res://([^"]+)"', txt)
        script = s.group(1) if s else ""
    except OSError:
        scene = ""
x = z = ""
lay = json.load(open("resources/world_v2/world_v2_layout.json", encoding="utf-8"))
for poi in lay.get("pois", []):
    if poi.get("id") == pid:
        x, z = f"{poi['v2_site'][0]:g}", f"{poi['v2_site'][2]:g}"
print("\t".join([scene, script, x, z]))
PY
}

# ─── Les tableaux PARALLÈLES (jamais des champs collés par un séparateur : la
# version d'origine de `gate_negative_control.sh` a payé une découpe ambiguë) ─
LABELS=(); CIBLES=(); ACTIONS=(); SIGNATURES=(); FAMILLES=()

ajouter() { FAMILLES+=("$1"); LABELS+=("$2"); CIBLES+=("$3"); ACTIONS+=("$4"); SIGNATURES+=("$5"); }

if [ "$MODE" = "temoin" ]; then
  # T1 — le compteur de collisions retombe sur le CORPS au lieu de la FORME.
  # C'est l'erreur exacte que porte `probe_place_metrics.gd` aujourd'hui, et
  # celle qu'un budget de « 6 collisions » ne verrait jamais.
  ajouter "D7" "le compteur de collisions regarde le corps et non la forme" \
    "$FILET" \
    's#find_children("\*", "CollisionShape3D", true, false).size()#find_children("*", "StaticBody3D", true, false).size()#' \
    "témoin — le compteur voit les FORMES de collision"
  # T2 — l'emprise retombe sur MeshInstance3D : le MultiMesh disparaît.
  ajouter "D2" "l'emprise visuelle redevient aveugle au MultiMesh" \
    "$FILET" \
    's#for noeud: Node in lieu.find_children("\*", "VisualInstance3D", true, false):#for noeud: Node in lieu.find_children("*", "MeshInstance3D", true, false):#' \
    "témoin — l'emprise visuelle voit un MultiMesh"
  # T3 — le prédicat de boîtitude cesse de reconnaître un pavé. Personne ne
  # ferait ça de mauvaise foi : on le ferait en croyant corriger les normales
  # séparées (24 sommets dans le tampon, 8 après soudage). D'où le témoin.
  ajouter "D1" "le prédicat hexa ne reconnaît plus un pavé" \
    "$FILET" \
    's#if nb == 12 and nv == 8:#if nb == 12 and nv == 24:#' \
    "témoin — un pavé rend 100 %"
  # T4 — un élément GELÉ change d'un octet.
  ajouter "D8" "un fichier gelé reçoit un commentaire" \
    "scripts/world_v2/world_v2_heightmap.gd" \
    '$a\## sabotage du contrôle négatif' \
    "D8 gel|D8 régression sur le gel"
  # T5 — le manifeste de gel est vidé de ses lignes. Sans le plancher, D8
  # deviendrait vert ET MUET : c'est le mode de panne le plus dangereux.
  ajouter "D8b" "le manifeste de gel est vidé" \
    "docs/contrats/gel_v2_3_b.sha256" \
    '/^[0-9a-f]\{64\}  /d' \
    "fichier\(s\) gelé\(s\) réellement recalculé"
else
  # ── MODE LOT 1 : cibles résolues, une par famille de défaut ────────────────
  SUJET_D1="valley.poi.barrow_cemetery.01"
  SUJET_D2="valley.poi.watchtower_ruin.01"
  SUJET_D4="valley.poi.overlook_summit.01"
  SUJET_D5="valley.poi.forest_shrine.01"
  SUJET_D7="valley.poi.turquoise_spring.01"
  for sujet in "$SUJET_D1" "$SUJET_D2" "$SUJET_D4" "$SUJET_D5" "$SUJET_D7"; do
    IFS=$'\t' read -r sc sp _ _ <<< "$(resoudre "$sujet")"
    if [ -z "$sc" ] || [ -z "$sp" ]; then
      echo "BLOQUÉ: $sujet n'a ni scène ni script dans le REGISTRY."
      echo "        Le lot 1 n'est pas construit : ce contrôle ne peut RIEN prouver."
      echo "        Relancer après la livraison des voies A et B, ou --temoin."
      exit 3
    fi
  done
  IFS=$'\t' read -r _ SC_D1 _ _ <<< "$(resoudre "$SUJET_D1")"
  IFS=$'\t' read -r _ SC_D2 _ _ <<< "$(resoudre "$SUJET_D2")"
  IFS=$'\t' read -r _ SC_D4 _ _ <<< "$(resoudre "$SUJET_D4")"
  IFS=$'\t' read -r _ SC_D5 X_D5 Z_D5 <<< "$(resoudre "$SUJET_D5")"
  IFS=$'\t' read -r _ SC_D7 _ _ <<< "$(resoudre "$SUJET_D7")"

  # D1 — l'empilement de blocs revient. Quatre pavés runtime : 48 triangles,
  # 100 % hexa, au-dessus du plancher de significativité et du plafond de 25 %.
  ajouter "D1" "un empilement de pavés runtime est ajouté au lieu" "$SC_D1" \
    '$a\
\
func _ready() -> void:\
\treturn _sabotage_pave()\
\
\
func _sabotage_pave() -> void:\
\tsuper._ready()\
\tfor i: int in range(4):\
\t\tvar pave: MeshInstance3D = MeshInstance3D.new()\
\t\tpave.name = "SabotagePave%d" % i\
\t\tpave.mesh = BoxMesh.new()\
\t\tpave.position = Vector3(float(i), 0.5, 0.0)\
\t\tadd_child(pave)' \
    "D1 .*boîtitude hexa"
  # D2 — le lieu entier est soulevé de deux mètres.
  ajouter "D2" "le lieu est soulevé de 2 m au-dessus du sol gelé" "$SC_D2" \
    '$a\
\
func _ready() -> void:\
\tsuper._ready()\
\tposition.y += 2.0' \
    "D2 .*(racine à|appui)"
  # D3 — deux lieux du lot pointent vers la même scène (le copier-coller).
  ajouter "D3" "deux lieux du lot partagent la même PackedScene" \
    "scripts/world_v2/poi/world_v2_places_builder.gd" \
    "s#\"res://$SC_D4\"#\"res://$SC_D2\"#" \
    "D3 .*signature de composition IDENTIQUE"
  # D4 — le site part dans la bande creusée du cours principal.
  ajouter "D4" "le lieu est déplacé dans le lit de la rivière" "$SC_D4" \
    '$a\
\
func _ready() -> void:\
\tsuper._ready()\
\tglobal_position = Vector3(0.0, global_position.y, 10.0)' \
    "D4 .*(bande creusée|posé en)"
  # D5 — la position du site entre en dur dans le script du lieu.
  ajouter "D5" "le site du layout est recopié en dur dans le script" "$SC_D5" \
    "\$a\\
\\
## sabotage : la position ne doit JAMAIS venir d'ici.\\
const SABOTAGE_SITE: Vector3 = Vector3($X_D5, 0.0, $Z_D5)" \
    "D5 .*littéral de site"
  # D6 — la récompense canonique change de contenu dans la table.
  ajouter "D6" "la table des récompenses change le contenu canonique" \
    "scripts/world/discovery_rewards.gd" \
    's#&"valley.poi.watchtower_ruin.01": {"arrows": 15}#\&"valley.poi.watchtower_ruin.01": {"arrows": 5}#' \
    "D6 .*récompense"
  # D7 — quarante formes de collision de plus sur un micro-POI (budget 6).
  ajouter "D7" "quarante formes de collision sont ajoutées à un micro-POI" "$SC_D7" \
    '$a\
\
func _ready() -> void:\
\tsuper._ready()\
\tvar corps: StaticBody3D = StaticBody3D.new()\
\tadd_child(corps)\
\tfor i: int in range(40):\
\t\tvar forme: CollisionShape3D = CollisionShape3D.new()\
\t\tforme.shape = BoxShape3D.new()\
\t\tcorps.add_child(forme)' \
    "D7 .*budget collisions"
  # D8 — un élément gelé change d'un octet.
  ajouter "D8" "un fichier gelé reçoit un commentaire" \
    "scripts/world_v2/world_v2_heightmap.gd" \
    '$a\## sabotage du contrôle négatif' \
    "D8 gel|D8 régression sur le gel"
fi

DECLARES="${#LABELS[@]}"
if [ "${#CIBLES[@]}" -ne "$DECLARES" ] || [ "${#ACTIONS[@]}" -ne "$DECLARES" ] \
   || [ "${#SIGNATURES[@]}" -ne "$DECLARES" ] || [ "${#FAMILLES[@]}" -ne "$DECLARES" ]; then
  echo "[ÉCHEC] tableaux de sabotage désalignés."
  exit 1
fi

WT=""
menage() {
  [ -n "$WT" ] && { git -C "$REPO" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"; }
  git -C "$REPO" worktree prune >/dev/null 2>&1 || true
}
trap menage EXIT INT TERM

JOUES=0; IGNORES=0; VALIDES=0
HORODATE="$(date -u +%Y%m%dT%H%M%SZ)"
RESUME="$JOURNAUX/negatif_${MODE}_${HORODATE}.log"
: > "$RESUME"

for i in "${!LABELS[@]}"; do
  FAM="${FAMILLES[$i]}"; LAB="${LABELS[$i]}"; CIB="${CIBLES[$i]}"
  ACT="${ACTIONS[$i]}"; SIG="${SIGNATURES[$i]}"
  if [ -n "$SEULEMENT" ] && [[ ",$SEULEMENT," != *",$FAM,"* ]]; then continue; fi

  echo "=== $FAM — $LAB ===" | tee -a "$RESUME"
  echo "    cible     : $CIB" | tee -a "$RESUME"
  echo "    signature : $SIG" | tee -a "$RESUME"
  if [ ! -f "$CIB" ]; then
    # ÉCHEC, jamais « ignoré » : une cible disparue veut dire que le contrôle
    # ne contrôle plus rien, et le silence serait un faux témoin de plus.
    echo "  [ÉCHEC] cible ABSENTE — le contrôle ne peut rien prouver." | tee -a "$RESUME"
    IGNORES=$((IGNORES + 1)); continue
  fi

  WT="$(mktemp -d -t zelda-lot1-XXXXXX)"
  git -C "$REPO" worktree add --detach --quiet "$WT" HEAD
  cp -r "$REPO/.godot" "$WT/.godot" 2>/dev/null || true

  # Le worktree doit CONTENIR le filet qu'on prétend éprouver : un test non
  # commité donnerait « aucun test exécuté », que l'on compterait comme un
  # succès du filet. NE PAS piper vers grep — `pipefail` prendrait alors le
  # code de Godot, non nul sur une simple fuite de ressources en fin de
  # process. On capture, puis on inspecte.
  SONDE="$("$GODOT_BIN" --headless --path "$WT" --script tools/godot/test_runner.gd -- \
          "--filter=$FILTER" 2>&1 || true)"
  if ! printf '%s' "$SONDE" | grep -q 'RÉSULTAT: [1-9]'; then
    echo "  [ÉCHEC] le filtre « $FILTER » ne sélectionne AUCUN test dans le worktree." \
      | tee -a "$RESUME"
    echo "          Commiter le filet avant de l'éprouver." | tee -a "$RESUME"
    IGNORES=$((IGNORES + 1)); menage; WT=""; continue
  fi

  if ! sed -i "$ACT" "$WT/$CIB" 2>/dev/null; then
    echo "  [ÉCHEC] sabotage non appliqué (sed a refusé)" | tee -a "$RESUME"
    IGNORES=$((IGNORES + 1)); menage; WT=""; continue
  fi
  if git -C "$WT" diff --quiet -- "$CIB"; then
    echo "  [ÉCHEC] le sabotage n'a RIEN changé : le motif ne correspond plus." \
      | tee -a "$RESUME"
    echo "          Un contrôle négatif qui ne casse rien est un faux témoin." \
      | tee -a "$RESUME"
    IGNORES=$((IGNORES + 1)); menage; WT=""; continue
  fi

  JOUES=$((JOUES + 1))
  BRUT="$("$GODOT_BIN" --headless --path "$WT" --script tools/godot/test_runner.gd -- \
        "--filter=$FILTER" 2>&1 || true)"
  printf '%s\n' "$BRUT" | grep -E 'RÉSULTAT|ÉCHEC|SCRIPT ERROR|Parse Error' \
    | sed 's/^/    /' | tee -a "$RESUME"

  # Un sabotage de CONTENU ne doit pas casser le PARSING : si le projet ne se
  # charge plus, le filet n'a rien constaté du tout.
  if printf '%s' "$BRUT" | grep -qE 'Parse Error|SCRIPT ERROR'; then
    echo "  [ÉCHEC] le projet ne se charge plus : l'échec ne prouve RIEN." | tee -a "$RESUME"
    menage; WT=""; continue
  fi
  if ! printf '%s' "$BRUT" | grep -q 'ÉCHEC'; then
    echo "  [FAILLE DU FILET] le lot est cassé et le filet reste vert." | tee -a "$RESUME"
    menage; WT=""; continue
  fi
  if ! printf '%s' "$BRUT" | grep -qE "ÉCHEC.*($SIG)"; then
    echo "  [ÉCHEC] le filet rougit, mais PAS sur le critère attendu." | tee -a "$RESUME"
    echo "          attendu : $SIG" | tee -a "$RESUME"
    menage; WT=""; continue
  fi
  echo "  [OK]   le filet a VU le sabotage, sur SON critère." | tee -a "$RESUME"
  VALIDES=$((VALIDES + 1))
  menage; WT=""
done

{
  echo
  echo "=== CONTRÔLE NÉGATIF LOT 1 (mode $MODE) — $DECLARES déclaré(s), $JOUES joué(s), $IGNORES ignoré(s), $VALIDES validé(s) ==="
} | tee -a "$RESUME"
echo "journal : $RESUME"
if [ "$IGNORES" -ne 0 ]; then
  echo "Un sabotage ignoré n'est pas un sabotage réussi : zéro ignoré est exigé."
  exit 1
fi
if [ "$VALIDES" -ne "$JOUES" ] || [ "$JOUES" -eq 0 ]; then
  echo "Le filet ne peut pas être considéré comme un garde-fou tant que c'est vrai."
  exit 1
fi
if [ "$MODE" = "temoin" ]; then
  echo
  echo "MODE TÉMOIN — ce qui vient d'être prouvé, et ce qui ne l'est PAS :"
  echo "  PROUVÉ        les instruments savent rougir quand on les dégrade,"
  echo "                et le gel rougit sur un octet."
  echo "  NON VÉRIFIÉ   le raccordement de D1..D7 aux six sujets du lot, qui"
  echo "                n'existent pas encore. Relancer sans --temoin après la"
  echo "                livraison des voies A et B."
fi
exit 0
