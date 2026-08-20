#!/usr/bin/env bash
# CONTRÔLE NÉGATIF du gate BOOT-TO-FUN.
#
# Un gate qui n'a jamais échoué ne prouve rien : il peut être vert parce que le
# jeu va bien, ou parce qu'il ne regarde rien. Ce script tranche, en cassant
# volontairement le jeu et en exigeant que le gate le VOIE — et qu'il le voie
# POUR LA BONNE RAISON.
#
# Protocole, pour chaque sabotage :
#   1. l'appliquer sur une copie de travail ISOLÉE (git worktree) ;
#   2. lancer le gate ;
#   3. exiger un échec dont le libellé CORRESPOND à la signature attendue —
#      un échec de parsing, un fichier manquant ou une panne sans rapport ne
#      compte PAS comme une réussite du contrôle ;
#   4. détruire la copie.
#
# L'arbre principal n'est JAMAIS modifié : le sabotage vit et meurt dans le
# worktree. C'est la règle 1 de docs/COMMENT_TRAVAILLER_ENSEMBLE.md.
#
# DURCISSEMENTS EXIGÉS PAR L'AUDIT DU 2026-08-09 :
#   - un fichier de sabotage ABSENT fait échouer le script (avant : « ignoré ») ;
#   - un sabotage NON APPLIQUÉ fait échouer ;
#   - chaque sabotage porte une SIGNATURE d'échec attendue et spécifique ;
#   - une erreur de parsing ou un ÉCHEC sans rapport ne vaut pas succès ;
#   - la cause n'est plus tronquée par `head -4` ;
#   - le résumé compte séparément exécutés, ignorés et validés ;
#   - zéro sabotage ignoré est exigé.
#
# Usage :  tools/gate_negative_control.sh
# Codes  :  0 = tous les sabotages exécutés ET vus pour la bonne raison
#           1 = au moins un sabotage inaperçu, ignoré, ou vu pour autre chose
set -uo pipefail

cd "$(dirname "$0")/.."
REPO="$PWD"
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"

# ISS-063 — verrou canonique + cloison `user://`.
# Mesuré le 2026-08-20 : 13 fichiers et 35 sites lancent le moteur dans ce
# dépôt, et 11 fichiers ne prenaient NI verrou NI cloison. Un correctif qui vit
# dans `tools/lancer_godot.sh` ne protège que ceux qui appellent le lanceur.
# Détail et inventaire : evidence/world_v2/v2_3_r2b3_1/iss063/.
# shellcheck source=lib/godot_env.sh
. "$PWD/tools/lib/godot_env.sh"
godot_cloison_arbre || exit 3
godot_verrou_prendre 8 3000 || exit 3
FILTER="${FILTER:-boot_smoke}"

WT=""
cleanup() {
  [ -n "$WT" ] && { git -C "$REPO" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"; }
  git -C "$REPO" worktree prune >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# Quatre tableaux PARALLÈLES, et non des enregistrements empaquetés.
#
# La version précédente collait les champs avec `|`, séparateur que `sed` et les
# alternatives `grep -E` utilisent aussi : la découpe se trompait dès qu'une
# signature contenait une alternative. Un contrôle négatif dont l'analyseur est
# ambigu est un faux témoin de plus.
#
# La SIGNATURE est la moitié utile du contrôle. Sans elle, un sabotage qui casse
# le parsing du projet produit « des échecs », et le script conclut que le gate a
# vu le défaut de gameplay — alors qu'il n'a vu qu'une erreur de syntaxe. Chaque
# sabotage doit rougir SUR SON PROPRE CRITÈRE.
SAB_LABELS=(
  "le bouton « Nouvelle partie » ne mène plus à la vallée"
  "le héros ne se pose plus (gravité annulée)"
)
SAB_FILES=(
  "scripts/ui/main_menu.gd"
  # ATTENTION — viser la RESSOURCE, pas la valeur par défaut du script.
  # `locomotion_tuning.gd` déclare `@export var gravity: float = 24.0`, mais
  # `locomotion_default.tres` porte la valeur réellement chargée et l'écrase.
  # Saboter le script ne changeait donc RIEN, et le vert du gate était correct
  # pendant que ce fichier criait « faille ». Troisième faux témoin de la
  # journée : l'équilibrage de ce dépôt vit dans des Resource (§5.4).
  "resources/tuning/locomotion_default.tres"
)
SAB_SEDS=(
  's#^const VALLEY_SCENE.*#const VALLEY_SCENE: String = "res://scenes/ui/MainMenu.tscn"#'
  's#^gravity = .*#gravity = 0.0#'
)
SAB_SIGNATURES=(
  "B4 — presser « Nouvelle partie » ouvre RÉELLEMENT la vallée"
  "(qui se pose sur un sol valide|B7b — soulevé de 3 m)"
)

DECLARED="${#SAB_LABELS[@]}"
if [ "${#SAB_FILES[@]}" -ne "$DECLARED" ] \
   || [ "${#SAB_SEDS[@]}" -ne "$DECLARED" ] \
   || [ "${#SAB_SIGNATURES[@]}" -ne "$DECLARED" ]; then
  echo "[ÉCHEC] tableaux de sabotage désalignés : un champ manque quelque part."
  exit 1
fi

EXECUTED=0
SKIPPED=0
VALIDATED=0
INDEX=0
for i in "${!SAB_LABELS[@]}"; do
  INDEX=$((INDEX + 1))
  LABEL="${SAB_LABELS[$i]}"
  FILE="${SAB_FILES[$i]}"
  SED="${SAB_SEDS[$i]}"
  SIGNATURE="${SAB_SIGNATURES[$i]}"

  echo "=== Sabotage $INDEX : $LABEL ==="
  echo "    signature attendue : $SIGNATURE"
  if [ ! -f "$FILE" ]; then
    # ÉCHEC, pas « ignoré ». Un fichier de sabotage disparu veut dire que le
    # contrôle ne contrôle plus rien : le silence serait un faux témoin.
    echo "  [ÉCHEC] fichier de sabotage ABSENT : $FILE"
    echo "          Le contrôle ne peut pas prouver ce qu'il prétend ; corriger la cible."
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  WT="$(mktemp -d -t zelda-neg-XXXXXX)"
  git -C "$REPO" worktree add --detach --quiet "$WT" HEAD
  # Le cache d'import est indispensable et long à reconstruire : on le copie
  # plutôt que de le régénérer, le sabotage ne touche que du GDScript.
  cp -r "$REPO/.godot" "$WT/.godot" 2>/dev/null || true

  # Le worktree doit CONTENIR le test qu'on prétend éprouver. Sans ce
  # contrôle, un test non commité donne « aucun test exécuté », que le script
  # comptait comme un échec — donc comme un succès du gate. Faux témoin exact
  # que ce fichier prétend refuser. Constaté au premier passage.
  # NE PAS piper vers grep : `set -o pipefail` prend alors le code retour de
  # GODOT, qui sort non nul sur une simple fuite de ressources en fin de
  # process. Le garde-fou concluait « aucun test » alors que la sortie disait
  # « 1 réussi ». Même famille que le piège `cmd | tail` de tools/CLAUDE.md :
  # un tube change ce que `$?` raconte. On capture, puis on inspecte.
  PROBE="$("$GODOT_BIN" --headless --path "$WT" --script tools/godot/test_runner.gd -- \
          "--filter=$FILTER" 2>&1 || true)"
  if ! printf '%s' "$PROBE" | grep -q 'RÉSULTAT: [1-9]'; then
    echo "  [ÉCHEC] le filtre « $FILTER » ne sélectionne AUCUN test dans le worktree."
    echo "          Commiter le test avant d'éprouver le gate avec."
    SKIPPED=$((SKIPPED + 1)); cleanup; WT=""; continue
  fi
  if ! sed -i "$SED" "$WT/$FILE" 2>/dev/null; then
    echo "  [ÉCHEC] le sabotage n'a pas pu être appliqué (sed a refusé)"
    SKIPPED=$((SKIPPED + 1)); cleanup; WT=""; continue
  fi
  if git -C "$WT" diff --quiet -- "$FILE"; then
    echo "  [ÉCHEC] le sabotage n'a RIEN changé : le motif ne correspond plus."
    echo "          Un contrôle négatif qui ne casse rien est un faux témoin."
    SKIPPED=$((SKIPPED + 1)); cleanup; WT=""; continue
  fi

  EXECUTED=$((EXECUTED + 1))
  RAW="$("$GODOT_BIN" --headless --path "$WT" --script tools/godot/test_runner.gd -- \
        "--filter=$FILTER" 2>&1 || true)"
  # Pas de `head` : tronquer la cause, c'est perdre exactement la ligne qui
  # dirait que l'échec vient d'ailleurs.
  OUT="$(printf '%s' "$RAW" | grep -E 'RÉSULTAT|ÉCHEC|SCRIPT ERROR|Parse Error' || true)"
  printf '%s\n' "$OUT" | sed 's/^/    /'

  # Un sabotage de GAMEPLAY ne doit pas casser le PARSING : si le projet ne se
  # charge plus, le gate n'a rien constaté du tout.
  if printf '%s' "$RAW" | grep -qE 'Parse Error|SCRIPT ERROR'; then
    echo "  [ÉCHEC] le projet ne se charge plus (parse/erreur de script) :"
    echo "          l'échec du gate ne prouve alors RIEN sur le gameplay."
    cleanup; WT=""; continue
  fi
  if ! printf '%s' "$RAW" | grep -q 'ÉCHEC'; then
    echo "  [FAILLE DU GATE] le jeu est cassé et le gate reste vert."
    cleanup; WT=""; continue
  fi
  if ! printf '%s' "$RAW" | grep -qE "ÉCHEC.*($SIGNATURE)"; then
    echo "  [ÉCHEC] le gate rougit, mais PAS sur le critère attendu."
    echo "          attendu : $SIGNATURE"
    echo "          Un échec sans rapport ne prouve pas que ce sabotage est vu."
    cleanup; WT=""; continue
  fi
  echo "  [OK]   le gate a VU le sabotage, sur SON critère."
  VALIDATED=$((VALIDATED + 1))
  cleanup; WT=""
done

echo
echo "=== CONTRÔLE NÉGATIF — sabotages : $DECLARED déclaré(s), $EXECUTED exécuté(s), $SKIPPED ignoré(s), $VALIDATED validé(s) ==="
if [ "$SKIPPED" -ne 0 ]; then
  echo "Un sabotage ignoré n'est pas un sabotage réussi : zéro ignoré est exigé."
  exit 1
fi
if [ "$VALIDATED" -ne "$DECLARED" ]; then
  echo "Le gate ne peut pas être considéré comme un garde-fou tant que c'est vrai."
  exit 1
fi
echo "Le gate sait rougir, et sur le bon critère, pour chacun des $DECLARED sabotages."
exit 0
