#!/usr/bin/env bash
# CONTRÔLE NÉGATIF du gate BOOT-TO-FUN.
#
# Un gate qui n'a jamais échoué ne prouve rien : il peut être vert parce que le
# jeu va bien, ou parce qu'il ne regarde rien. Ce script tranche, en cassant
# volontairement le jeu et en exigeant que le gate le VOIE.
#
# Protocole, pour chaque sabotage :
#   1. l'appliquer sur une copie de travail ISOLÉE (git worktree) ;
#   2. lancer le gate ;
#   3. exiger un ÉCHEC — un vert ici est une faille du gate, pas une bonne
#      nouvelle ;
#   4. détruire la copie.
#
# L'arbre principal n'est JAMAIS modifié : le sabotage vit et meurt dans le
# worktree. C'est la règle 1 de docs/COMMENT_TRAVAILLER_ENSEMBLE.md.
#
# Usage :  tools/gate_negative_control.sh
# Codes  :  0 = le gate sait rougir sur TOUS les sabotages
#           1 = au moins un sabotage est passé inaperçu (faille du gate)
set -uo pipefail

cd "$(dirname "$0")/.."
REPO="$PWD"
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"
FILTER="${FILTER:-boot_smoke}"

WT=""
cleanup() {
  [ -n "$WT" ] && { git -C "$REPO" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"; }
  git -C "$REPO" worktree prune >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# Chaque sabotage : étiquette | fichier | motif sed
# Ils visent des ÉTAPES DIFFÉRENTES du parcours, pour qu'un gate qui ne
# regarderait qu'un bout soit démasqué.
SABOTAGES=(
  "le bouton « Nouvelle partie » ne mène plus à la vallée|scripts/ui/main_menu.gd|s|^const VALLEY_SCENE.*|const VALLEY_SCENE: String = \"res://scenes/ui/MainMenu.tscn\"|"
  # ATTENTION — viser la RESSOURCE, pas la valeur par défaut du script.
  # `locomotion_tuning.gd` déclare `@export var gravity: float = 24.0`, mais
  # `locomotion_default.tres` porte la valeur réellement chargée et l'écrase.
  # Saboter le script ne changeait donc RIEN, et le vert du gate était correct
  # pendant que ce fichier criait « faille ». Troisième faux témoin de la
  # journée : l'équilibrage de ce dépôt vit dans des Resource (§5.4).
  "le héros ne se pose plus (gravité annulée)|resources/tuning/locomotion_default.tres|s|^gravity = .*|gravity = 0.0|"
)

FAILURES=0
INDEX=0
for entry in "${SABOTAGES[@]}"; do
  INDEX=$((INDEX + 1))
  LABEL="${entry%%|*}"
  REST="${entry#*|}"
  FILE="${REST%%|*}"
  SED="${REST#*|}"

  echo "=== Sabotage $INDEX : $LABEL ==="
  if [ ! -f "$FILE" ]; then
    echo "  [IGNORÉ] fichier absent : $FILE"
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
    FAILURES=$((FAILURES + 1)); cleanup; WT=""; continue
  fi
  if ! sed -i "$SED" "$WT/$FILE" 2>/dev/null; then
    echo "  [ÉCHEC] le sabotage n'a pas pu être appliqué"
    FAILURES=$((FAILURES + 1)); cleanup; WT=""; continue
  fi
  if git -C "$WT" diff --quiet -- "$FILE"; then
    echo "  [ÉCHEC] le sabotage n'a RIEN changé : le motif ne correspond plus."
    echo "          Un contrôle négatif qui ne casse rien est un faux témoin."
    FAILURES=$((FAILURES + 1)); cleanup; WT=""; continue
  fi

  RAW="$("$GODOT_BIN" --headless --path "$WT" --script tools/godot/test_runner.gd -- \
        "--filter=$FILTER" 2>&1 || true)"
  OUT="$(printf '%s' "$RAW" | grep -E 'RÉSULTAT|ÉCHEC' | head -4)"
  echo "$OUT" | sed 's/^/    /'
  if echo "$OUT" | grep -q 'ÉCHEC'; then
    echo "  [OK]   le gate a VU le sabotage."
  else
    echo "  [FAILLE DU GATE] le jeu est cassé et le gate reste vert."
    FAILURES=$((FAILURES + 1))
  fi
  cleanup; WT=""
done

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "=== CONTRÔLE NÉGATIF : le gate sait rougir sur ${INDEX} sabotage(s) ==="
  exit 0
fi
echo "=== CONTRÔLE NÉGATIF : $FAILURES sabotage(s) passé(s) inaperçu(s) ==="
echo "Le gate ne peut pas être considéré comme un garde-fou tant que c'est vrai."
exit 1
