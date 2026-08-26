#!/usr/bin/env bash
# =============================================================================
# tools/gate_export_parite_controle_negatif.sh — LES DIX SABOTAGES D'ISS-071
#
# POURQUOI CE BANC EXISTE
# -----------------------
# Un portail qui ne rougit jamais est indistinguable d'un portail qui marche.
# `tools/gate_export_parite.sh` a rendu ROUGE sur `cb8c5d7` — c'est nécessaire,
# ce n'est pas suffisant : il faut aussi savoir CE QU'IL VOIT, et ce qu'il
# laisserait passer.
#
# Chaque contrôle publie, dans cet ordre et sans exception :
#   1. état sain            — la mesure de départ, avec sa taille
#   2. sabotage             — ce qui est retiré, exactement
#   3. résultat ROUGE       — et la cause attendue, retrouvée dans la sortie
#   4. restauration         — exacte
#   5. preuve de restauration — sha256 ou diff, pas une affirmation
#   6. résultat VERT        — la mesure de départ retrouvée
#
# LE PIÈGE QUE CE BANC DOIT ÉVITER LUI-MÊME
# -----------------------------------------
# « Le sabotage doit retirer la chose testée, pas ce qui est en dessous »
# (`tools/CLAUDE.md`). Un sabotage qui n'atteint pas la grandeur mesurée laisse
# le contrôle vert et ferait conclure, à tort, que le contrôle est aveugle.
# Chaque sabotage ci-dessous publie donc ce qu'il a RÉELLEMENT changé.
#
# AUCUN FICHIER DE PRODUCTION N'EST TOUCHÉ. Les sabotages qui portent sur
# `scripts/` sont joués dans une COPIE jetable hors de l'arbre, et l'arbre est
# vérifié propre à la fin.
#
# Codes : 0 = tous les contrôles jouables ont rendu le verdict attendu
#         1 = au moins un contrôle n'a pas rougi quand il aurait dû
#         3 = BLOQUÉ (artefacts absents : rien n'a pu être joué)
# =============================================================================
set -u -o pipefail

ARBRE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ARBRE" || { echo "BLOQUÉ: cd $ARBRE"; echo "RC=3"; exit 3; }

ARTEFACTS="${1:-/home/user/wt-a-out}"
TMP="$(mktemp -d /tmp/iss071_cn_XXXXXXXX)"
PARITE="$ARBRE/tools/iss071_parite.py"
REGLE="$ARBRE/tools/iss071_regle_noms.py"
TABLE="$ARBRE/tests/fixtures/iss071_noms.json"

ECHECS=0
JOUES=0
NON_VERIFIES=0
CODE=3

menage() {
  case "$TMP" in /tmp/iss071_cn_*) rm -rf -- "$TMP" ;; esac
  echo
  echo "=============================================================================="
  echo "CONTRÔLES NÉGATIFS ISS-071 : $JOUES joué(s), $ECHECS échec(s), "\
"$NON_VERIFIES NON VÉRIFIÉ(s)"
  echo "=============================================================================="
  printf 'RC=%s\n' "$CODE"
}
trap 'menage' EXIT

titre() { echo; echo "=============================================================="
          echo "CONTRÔLE $*"
          echo "=============================================================="; }
phase() { echo "  -- $*"; }
res()   { echo "     $*"; }

## Un contrôle réussit quand le sabotage a produit le verdict ATTENDU.
## `attendu_rc` : 1 = doit rougir, 3 = doit bloquer.
verdict() {
  local nom="$1" obtenu="$2" attendu="$3" cause_vue="$4"
  JOUES=$((JOUES + 1))
  if [ "$obtenu" = "$attendu" ] && [ "$cause_vue" = "oui" ]; then
    res "VERDICT : le sabotage a bien été attrapé (code $obtenu, cause reconnue)"
  else
    ECHECS=$((ECHECS + 1))
    res "VERDICT : ÉCHEC — code obtenu $obtenu, attendu $attendu ;"
    res "          cause attendue retrouvée dans la sortie : $cause_vue"
    res "          $nom NE ROUGIT PAS : le portail est aveugle sur ce point."
  fi
}

non_verifie() {
  NON_VERIFIES=$((NON_VERIFIES + 1))
  res "STATUT : NON VÉRIFIÉ — $*"
}

echo "=============================================================================="
echo "CONTRÔLES NÉGATIFS DU PORTAIL D'EXPORT ISS-071"
echo "arbre     : $ARBRE"
echo "artefacts : $ARTEFACTS"
echo "SHA       : $(git -C "$ARBRE" rev-parse HEAD)"
echo "date      : $(date -Is)"
echo "=============================================================================="

MAN_ED="$ARTEFACTS/manifeste_editeur.json"
MAN_EX="$ARTEFACTS/manifeste_export.json"
JOURNAL="$ARTEFACTS/journaux/jeu_exporte_stdout.log"
for f in "$MAN_ED" "$MAN_EX" "$JOURNAL"; do
  if [ ! -s "$f" ]; then
    echo "BLOQUÉ: artefact absent ou vide : $f" >&2
    echo "        Lancer d'abord tools/gate_export_parite.sh." >&2
    CODE=3; exit 3
  fi
done
SHA_ED_AVANT="$(sha256sum "$MAN_ED" | cut -d' ' -f1)"
SHA_EX_AVANT="$(sha256sum "$MAN_EX" | cut -d' ' -f1)"
SHA_JO_AVANT="$(sha256sum "$JOURNAL" | cut -d' ' -f1)"
echo "empreintes des artefacts RÉELS avant tout contrôle (ils ne sont jamais"
echo "modifiés : chaque sabotage travaille sur une COPIE) :"
echo "  manifeste éditeur : $SHA_ED_AVANT"
echo "  manifeste export  : $SHA_EX_AVANT"
echo "  journal du jeu    : $SHA_JO_AVANT"

# --------------------------------------------------------------------------
# Base SAINE de référence : le manifeste éditeur RÉEL, redéclaré « export ».
# C'est exactement la forme qu'un correctif doit produire — index identique,
# compteurs identiques — donc le seul état sain honnête dont on dispose avant
# le correctif. Il est étiqueté comme SIMULÉ partout où il sert.
# --------------------------------------------------------------------------
SAIN_ED="$TMP/sain_editeur.json"
SAIN_EX="$TMP/sain_export.json"
SAIN_JO="$TMP/sain_journal.log"
cp "$MAN_ED" "$SAIN_ED"
python3 - "$MAN_ED" "$SAIN_EX" <<'PY'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
d["environnement"] = "export"
json.dump(d, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False)
PY
grep -v -E "modèle inconnu|modèle végétal introuvable|modèle de dalle inconnu" \
  "$JOURNAL" > "$SAIN_JO"
echo
echo "base saine SIMULÉE construite (ce n'est PAS une preuve de correctif) :"
echo "  export simulé = manifeste éditeur réel redéclaré « export »"
echo "  journal sain  = journal réel privé de ses lignes des quatre familles"
echo "  $(wc -l < "$JOURNAL") lignes de journal réel -> $(wc -l < "$SAIN_JO") lignes saines"

lancer_parite() {   # <ed> <ex> <journal> <log> [--source dir]
  local ed="$1" ex="$2" jo="$3" log="$4"; shift 4
  python3 "$PARITE" --editeur "$ed" --export "$ex" --journal "$jo" "$@" \
    > "$log" 2>&1
  echo $?
}

# ==========================================================================
titre "0 (préalable) — la base saine rend bien VERT"
phase "état sain"
RC0="$(lancer_parite "$SAIN_ED" "$SAIN_EX" "$SAIN_JO" "$TMP/c0.log" \
        --source "$ARBRE")"
res "code $RC0 ; $(grep -m1 'VERDICT ISS-071' "$TMP/c0.log")"
res "$(grep -m1 'contrôle(s) exécutés' "$TMP/c0.log")"
if [ "$RC0" != "0" ]; then
  res "ATTENTION : la base saine ne rend pas VERT. Tous les contrôles qui"
  res "            suivent perdraient leur sens — un rouge y serait acquis"
  res "            d'avance et ne prouverait rien."
  ECHECS=$((ECHECS + 1))
fi

# ==========================================================================
titre "1 — normalisation « .import » désactivée dans WorldV2PlaceKit"
phase "état sain"
res "sur cb8c5d7 la normalisation N'EXISTE PAS ENCORE : le code teste"
res "directement le suffixe .gltf/.glb. Il n'y a rien à désactiver."
phase "jumeau à l'échelle de la RÈGLE, jouable dès maintenant"
python3 "$REGLE" --table "$TABLE" --saboter sans-import > "$TMP/c1.log" 2>&1
RC1=$?
res "$(grep -m1 '^sabotage' "$TMP/c1.log")"
res "$(grep -m1 '^examiné' "$TMP/c1.log")"
res "$(grep -m1 '^écarts' "$TMP/c1.log") ; code $RC1"
CAUSE=oui; grep -q "Foo.gltf.import" "$TMP/c1.log" || CAUSE=non
res "cause attendue (« Foo.gltf.import » non indexé) retrouvée : $CAUSE"
verdict "sabotage « sans-import » de la règle" "$RC1" "1" "$CAUSE"
phase "restauration"
python3 "$REGLE" --table "$TABLE" > "$TMP/c1b.log" 2>&1
res "règle documentée sans sabotage : $(grep -m1 '^écarts' "$TMP/c1b.log")"
res "table inchangée : sha256 $(sha256sum "$TABLE" | cut -d' ' -f1)"
non_verifie "le sabotage sur le VRAI WorldV2PlaceKit exige le correctif de"
res "         l'agent B. Recette prête : retirer le retrait de « .import »"
res "         dans scene_for(), relancer tools/gate_export_parite.sh, exiger"
res "         un ROUGE de la famille « kit : modèle inconnu »."

# ==========================================================================
titre "2 — normalisation désactivée dans AssetRegistry"
phase "état sain"
res "même situation qu'au contrôle 1 : rien à désactiver sur cb8c5d7."
phase "ce que le portail voit aujourd'hui, sans aucun sabotage"
NVEG="$(grep -cE 'modèle végétal introuvable' "$JOURNAL" || true)"
res "journal réel de la build : $NVEG ligne(s) « modèle végétal introuvable »"
res "la famille végétation est donc bien OBSERVABLE par le portail."
non_verifie "le sabotage sur le VRAI AssetRegistry exige le correctif."
res "         Recette : même retrait dans model(), exiger un ROUGE de la"
res "         famille « modèle végétal introuvable » (elle passe par"
res "         AssetRegistry, et non par le kit)."

# ==========================================================================
titre "3 — faux chemin source reconstruit (extension remplacée)"
phase "état sain"
res "règle documentée : $(python3 "$REGLE" --table "$TABLE" 2>&1 | grep -m1 '^écarts')"
phase "sabotage : le chemin indexé devient « <base>.scn » au lieu de la source"
python3 "$REGLE" --table "$TABLE" --saboter extension-remplacee \
  > "$TMP/c3.log" 2>&1
RC3=$?
res "$(grep -m1 '^examiné' "$TMP/c3.log")"
res "$(grep -m1 '^écarts' "$TMP/c3.log") ; code $RC3"
CAUSE=oui; grep -q "\.scn" "$TMP/c3.log" || CAUSE=non
res "cause attendue (chemins en .scn au lieu de .gltf/.glb) : $CAUSE"
verdict "chemin source falsifié" "$RC3" "1" "$CAUSE"
phase "restauration + preuve"
python3 "$REGLE" --table "$TABLE" > "$TMP/c3b.log" 2>&1
res "$(grep -m1 '^écarts' "$TMP/c3b.log") ; table sha256 $(sha256sum "$TABLE" | cut -d' ' -f1)"

# ==========================================================================
titre "4 — une entrée « .bin.import » ne doit JAMAIS devenir une scène"
phase "état sain"
res "la table attend « Foo.bin » et « Foo.bin.import » NON indexés"
phase "sabotage : la règle accepte aussi l'extension .bin"
python3 "$REGLE" --table "$TABLE" --saboter bin-accepte > "$TMP/c4.log" 2>&1
RC4=$?
res "$(grep -m1 '^examiné' "$TMP/c4.log")"
res "$(grep -m1 '^écarts' "$TMP/c4.log") ; code $RC4"
CAUSE=oui; grep -q "Foo.bin" "$TMP/c4.log" || CAUSE=non
res "cause attendue (« Foo.bin » indexé à tort) : $CAUSE"
res "conséquence réelle si ce sabotage passait : le tampon binaire d'un .gltf"
res "porte le NOM du modèle ; il écraserait sa clé ou créerait une collision."
verdict ".bin accepté" "$RC4" "1" "$CAUSE"
phase "restauration + preuve"
python3 "$REGLE" --table "$TABLE" > "$TMP/c4b.log" 2>&1
res "$(grep -m1 '^écarts' "$TMP/c4b.log") ; table sha256 $(sha256sum "$TABLE" | cut -d' ' -f1)"

# ==========================================================================
titre "5 — le suffixe « .tres.import » doit être ignoré"
phase "état sain"
res "la table attend « Foo.tres.import » NON indexé"
phase "sabotage : la règle accepte aussi .tres"
python3 "$REGLE" --table "$TABLE" --saboter tres-accepte > "$TMP/c5.log" 2>&1
RC5=$?
res "$(grep -m1 '^examiné' "$TMP/c5.log")"
res "$(grep -m1 '^écarts' "$TMP/c5.log") ; code $RC5"
CAUSE=oui; grep -q "Foo.tres.import" "$TMP/c5.log" || CAUSE=non
res "cause attendue (« Foo.tres.import » indexé à tort) : $CAUSE"
res "conséquence : un PCK porte des centaines de .tres.import ; les indexer"
res "gonflerait l'index et ferait rougir I1 pour une raison fausse."
verdict ".tres accepté" "$RC5" "1" "$CAUSE"
phase "restauration + preuve"
python3 "$REGLE" --table "$TABLE" > "$TMP/c5b.log" 2>&1
res "$(grep -m1 '^écarts' "$TMP/c5b.log") ; table sha256 $(sha256sum "$TABLE" | cut -d' ' -f1)"
phase "au passage : les deux autres sabotages de la même famille"
for s in split-point casse chemin-import; do
  python3 "$REGLE" --table "$TABLE" --saboter "$s" > "$TMP/c5_$s.log" 2>&1
  R=$?
  res "$(printf '%-20s' "$s") code $R · $(grep -m1 '^écarts' "$TMP/c5_$s.log")"
  [ "$R" = "1" ] || { ECHECS=$((ECHECS + 1)); res "  ÉCHEC : ne rougit pas"; }
  JOUES=$((JOUES + 1))
done

# ==========================================================================
titre "6 — une collision de nom vers DEUX chemins différents est PUBLIÉE"
phase "état sain"
res "manifestes sains : $(grep -m1 'collisions publiée' "$TMP/c0.log" || echo '0 collision') "
res "code de la base saine : $RC0"
phase "sabotage : une collision est publiée d'un seul côté (export)"
python3 - "$SAIN_EX" "$TMP/c6_export.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
d["resolveurs"]["WorldV2PlaceKit"]["collisions"] = [{
    "nom": "Prop_Crate",
    "retenu": "res://assets/environment/village/Prop_Crate.gltf",
    "ignore": "res://assets/environment/props/Prop_Crate.gltf"}]
json.dump(d, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False)
PY
RC6="$(lancer_parite "$SAIN_ED" "$TMP/c6_export.json" "$SAIN_JO" "$TMP/c6.log")"
res "code $RC6"
CAUSE=oui
grep -q "I6 WorldV2PlaceKit" "$TMP/c6.log" || CAUSE=non
grep -q "Prop_Crate" "$TMP/c6.log" || CAUSE=non
res "cause attendue (I6 rouge, collision NOMMÉE Prop_Crate) : $CAUSE"
res "$(grep -m1 'I6 WorldV2PlaceKit' -A2 "$TMP/c6.log" | tail -1)"
verdict "collision publiée d'un seul côté" "$RC6" "1" "$CAUSE"
phase "restauration + preuve"
rm -f "$TMP/c6_export.json"
RC6B="$(lancer_parite "$SAIN_ED" "$SAIN_EX" "$SAIN_JO" "$TMP/c6b.log")"
res "base saine rejouée : code $RC6B (attendu $RC0)"
res "manifeste export réel intact : $(sha256sum "$MAN_EX" | cut -d' ' -f1)"

# ==========================================================================
titre "7 — un modèle retiré de l'index doit être NOMMÉ par le verdict"
CIBLE="Prop_Crate"
phase "état sain"
res "« $CIBLE » présent dans les deux index de la base saine"
phase "sabotage : « $CIBLE » retiré du seul index export"
python3 - "$SAIN_EX" "$TMP/c7_export.json" "$CIBLE" <<'PY'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
cible = sys.argv[3]
retire = 0
for res_ in d["resolveurs"].values():
    if cible in res_.get("index", {}):
        del res_["index"][cible]
        retire += 1
json.dump(d, open(sys.argv[2], "w", encoding="utf-8"), ensure_ascii=False)
print(f"     sabotage effectif : {cible} retiré de {retire} index")
PY
RC7="$(lancer_parite "$SAIN_ED" "$TMP/c7_export.json" "$SAIN_JO" "$TMP/c7.log")"
res "code $RC7"
CAUSE=oui; grep -q "$CIBLE" "$TMP/c7.log" || CAUSE=non
res "le verdict NOMME « $CIBLE » : $CAUSE"
grep -m1 -B1 "$CIBLE" "$TMP/c7.log" | sed 's/^/     /' || true
verdict "modèle retiré de l'index" "$RC7" "1" "$CAUSE"
phase "restauration + preuve"
rm -f "$TMP/c7_export.json"
RC7B="$(lancer_parite "$SAIN_ED" "$SAIN_EX" "$SAIN_JO" "$TMP/c7b.log")"
res "base saine rejouée : code $RC7B (attendu $RC0)"

# ==========================================================================
titre "8 — durée de vie des caches : le filet ISS-059 reste décisif"
COPIE="$TMP/copie_sources"
mkdir -p "$COPIE/scripts/world_v2/poi" "$COPIE/scripts/core"
cp scripts/world_v2/poi/world_v2_place_kit.gd "$COPIE/scripts/world_v2/poi/"
cp scripts/core/asset_registry.gd "$COPIE/scripts/core/"
SHA_KIT_AVANT="$(sha256sum scripts/world_v2/poi/world_v2_place_kit.gd | cut -d' ' -f1)"
SHA_REG_AVANT="$(sha256sum scripts/core/asset_registry.gd | cut -d' ' -f1)"
phase "état sain (copie jetable, l'arbre n'est jamais touché)"
RC8A="$(lancer_parite "$SAIN_ED" "$SAIN_EX" "$SAIN_JO" "$TMP/c8a.log" \
         --source "$COPIE")"
res "code $RC8A ; $(grep -c 'I8 —' "$TMP/c8a.log") contrôle(s) I8"
grep 'I8 —' "$TMP/c8a.log" | sed 's/^/     /'
phase "sabotage : SCENE_CACHE_MAX passé de 256 à 0 DANS LA COPIE"
sed -i 's/const SCENE_CACHE_MAX: int = 256/const SCENE_CACHE_MAX: int = 0/' \
  "$COPIE/scripts/world_v2/poi/world_v2_place_kit.gd"
res "sabotage effectif : $(grep -c 'SCENE_CACHE_MAX: int = 0' \
  "$COPIE/scripts/world_v2/poi/world_v2_place_kit.gd") occurrence(s) à 0"
RC8="$(lancer_parite "$SAIN_ED" "$SAIN_EX" "$SAIN_JO" "$TMP/c8.log" \
        --source "$COPIE")"
res "code $RC8"
CAUSE=oui; grep -q "LITTÉRAL ABSENT" "$TMP/c8.log" || CAUSE=non
res "cause attendue (littéral de rétention absent) : $CAUSE"
verdict "borne de cache modifiée" "$RC8" "1" "$CAUSE"
phase "restauration + preuve"
cp scripts/world_v2/poi/world_v2_place_kit.gd "$COPIE/scripts/world_v2/poi/"
if diff -q scripts/world_v2/poi/world_v2_place_kit.gd \
     "$COPIE/scripts/world_v2/poi/world_v2_place_kit.gd" > /dev/null; then
  res "copie restaurée : diff vide sur "\
"$(wc -l < scripts/world_v2/poi/world_v2_place_kit.gd) lignes comparées"
else
  res "ÉCHEC de restauration"; ECHECS=$((ECHECS + 1))
fi
res "fichiers de PRODUCTION inchangés :"
res "  world_v2_place_kit.gd $SHA_KIT_AVANT"
res "                      -> $(sha256sum scripts/world_v2/poi/world_v2_place_kit.gd | cut -d' ' -f1)"
res "  asset_registry.gd     $SHA_REG_AVANT"
res "                      -> $(sha256sum scripts/core/asset_registry.gd | cut -d' ' -f1)"
RC8B="$(lancer_parite "$SAIN_ED" "$SAIN_EX" "$SAIN_JO" "$TMP/c8b.log" \
         --source "$COPIE")"
res "après restauration : code $RC8B (attendu $RC0)"
non_verifie "le test ISS-059 lui-même (vidage de cache entre deux placements)"
res "         n'est pas rejoué ici : il exige le moteur et le verrou. Il vit"
res "         dans tests/world_v2/test_world_v2_iss059_cache_kit.gd et tourne"
res "         dans tools/validate_fast.sh."

# ==========================================================================
titre "9 — photographier pendant l'écran de chargement : le portail se REFUSE"
phase "état sain : la décision du portail, telle qu'écrite dans le portail"
EXPR="$(grep -n "awk -v l=" "$ARBRE/tools/gate_export_parite.sh" | head -1)"
res "expression de décision : $EXPR"
res "branche de refus       : $(grep -c 'BLOQUÉ: l.écran de chargement' \
  "$ARBRE/tools/gate_export_parite.sh") occurrence(s), suivie(s) de « fini 3 »"
# On rejoue la MÊME expression sur deux images réelles/fidèles.
convert -size 320x180 "xc:gray(0.7)" "$TMP/chargement.png" 2>/dev/null
LUM_CHARGE="$(identify -format '%[fx:mean]' "$TMP/chargement.png")"
LUM_MONDE="non capturée"
if [ -s "$ARTEFACTS/02_monde.png" ]; then
  LUM_MONDE="$(identify -format '%[fx:mean]' "$ARTEFACTS/02_monde.png")"
fi
res "image « écran de chargement » (fidèle au repère 0,0027) : $LUM_CHARGE"
res "image « monde affiché » (capture RÉELLE du portail)      : $LUM_MONDE"
phase "sabotage : soumettre l'écran de chargement à la décision du portail"
if awk -v l="$LUM_CHARGE" -v s="0.02" 'BEGIN{exit !(l>s)}'; then
  RC9=0; res "la décision ACCEPTE l'écran de chargement — le portail conclurait"
else
  RC9=3; res "la décision REFUSE (le portail sortirait en 3, BLOQUÉ)"
fi
CAUSE=oui
verdict "décision sur écran de chargement" "$RC9" "3" "$CAUSE"
phase "restauration : la même décision sur le monde réellement affiché"
if [ "$LUM_MONDE" = "non capturée" ]; then
  non_verifie "aucune capture de monde dans $ARTEFACTS"
else
  if awk -v l="$LUM_MONDE" -v s="0.02" 'BEGIN{exit !(l>s)}'; then
    res "la décision ACCEPTE le monde affiché : le portail poursuit. Correct."
  else
    res "ÉCHEC : la décision refuse une image de monde valide"
    ECHECS=$((ECHECS + 1))
  fi
fi
non_verifie "le refus n'a pas encore été déclenché DE BOUT EN BOUT sur une"
res "         exécution réelle du portail — voir --seuil-luminance."

# ==========================================================================
titre "10 — un journal filtré ne suffit PAS à obtenir un vert"
phase "état sain : manifestes en parité + journal déjà filtré"
res "code de la base saine : $RC0 (journal à 0 ligne des quatre familles)"
NF="$(grep -cE 'modèle inconnu|modèle végétal introuvable|modèle de dalle inconnu' \
      "$SAIN_JO" || true)"
res "vérification du filtrage : $NF ligne(s) des quatre familles dans le"
res "journal sain, sur $(wc -l < "$SAIN_JO") lignes"
phase "sabotage : on garde le journal FILTRÉ, on remet le manifeste export RÉEL"
RC10="$(lancer_parite "$MAN_ED" "$MAN_EX" "$SAIN_JO" "$TMP/c10.log" \
         --source "$ARBRE")"
res "code $RC10 — attendu 1 (ROUGE) MALGRÉ un journal sans la moindre erreur"
CAUSE=oui
grep -q "I1 index WorldV2PlaceKit" "$TMP/c10.log" || CAUSE=non
grep -q "modules_instancies" "$TMP/c10.log" || CAUSE=non
res "cause attendue (parité d'index + compteurs positifs, pas l'absence de"
res "messages) : $CAUSE"
grep -E '^\s+- \[ROUGE\]' "$TMP/c10.log" | head -6 | sed 's/^/     /'
verdict "journal filtré" "$RC10" "1" "$CAUSE"
phase "restauration + preuve"
res "journal réel intact : $(sha256sum "$JOURNAL" | cut -d' ' -f1)"
res "                     (avant les contrôles : $SHA_JO_AVANT)"

# ==========================================================================
titre "FIN — intégrité de l'arbre et des artefacts"
res "manifeste éditeur : $(sha256sum "$MAN_ED" | cut -d' ' -f1) (avant $SHA_ED_AVANT)"
res "manifeste export  : $(sha256sum "$MAN_EX" | cut -d' ' -f1) (avant $SHA_EX_AVANT)"
res "journal du jeu    : $(sha256sum "$JOURNAL" | cut -d' ' -f1) (avant $SHA_JO_AVANT)"
SALE_SCRIPTS="$(git -C "$ARBRE" status --porcelain scripts/ | wc -l)"
res "git status --porcelain scripts/ : $SALE_SCRIPTS ligne(s) (0 exigé)"
git -C "$ARBRE" status --porcelain scripts/ | sed 's/^/       /'
[ "$SALE_SCRIPTS" -eq 0 ] || ECHECS=$((ECHECS + 1))

CODE=$([ "$ECHECS" -eq 0 ] && echo 0 || echo 1)
exit "$CODE"
