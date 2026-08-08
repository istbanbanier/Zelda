#!/usr/bin/env bash
# Portail SÉLECTIF : ne rejoue que les tests liés au diff.
#
# Transposé de `scripts/gate_select.mjs` de levy-street/world-of-claudecraft, où
# c'est l'outil du quotidien : le portail complet sert avant de livrer, le
# portail sélectif sert pendant qu'on travaille. Chez eux il est ~3× plus
# rapide ; ici l'écart est bien plus grand, parce que la suite complète met une
# vingtaine de minutes et qu'un diff n'en touche presque jamais plus de cinq.
#
# CE QU'IL N'EST PAS : un remplacement de `validate_fast.sh`. Un portail
# sélectif ne peut pas voir une régression à distance — c'est sa limite par
# construction, et elle est réelle. Il sert à raccourcir la boucle
# écrire → vérifier, jamais à déclarer un jalon terminé.
#
# Usage :
#   tools/gate_select.sh                 # diff vs HEAD (travail en cours)
#   tools/gate_select.sh HEAD~3          # diff vs une base donnée
#   tools/gate_select.sh --dry           # montre la sélection, ne lance rien
#
# Codes retour : ceux du runner · 0 si la sélection est vide (rien à rejouer).
set -uo pipefail

cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"

DRY=0
BASE=""
for arg in "$@"; do
  case "$arg" in
    --dry) DRY=1 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) BASE="$arg" ;;
  esac
done

# Sans base explicite : le travail en cours (indexé + non indexé). Avec base :
# tout ce qui sépare la base de HEAD, plus le travail en cours.
if [ -n "$BASE" ]; then
  CHANGED=$( { git diff --name-only "$BASE"..HEAD; git diff --name-only HEAD; \
               git diff --name-only --cached; } | sort -u )
else
  CHANGED=$( { git diff --name-only HEAD; git diff --name-only --cached; \
               git ls-files --others --exclude-standard; } | sort -u )
fi

if [ -z "$CHANGED" ]; then
  echo "Aucun fichier changé — rien à rejouer."
  exit 0
fi

echo "=== Fichiers changés ==="
echo "$CHANGED" | sed 's/^/  /'

# --- Sélection ------------------------------------------------------------
# Deux règles, volontairement simples et lisibles :
#   1. un fichier de test changé se rejoue lui-même ;
#   2. un script changé entraîne les tests qui NOMMENT son `class_name` ou son
#      nom de fichier — c'est grossier, mais ça se vérifie à l'œil, et un
#      sur-ensemble est sans danger là où un sous-ensemble serait trompeur.
SELECTED=""
add() { SELECTED="$SELECTED $1"; }

while IFS= read -r file; do
  [ -n "$file" ] || continue
  case "$file" in
    tests/*test_*.gd)
      add "$(basename "$file" .gd)" ;;
    *.gd)
      stem=$(basename "$file" .gd)
      # `class_name` déclaré par ce script, s'il en a un.
      cname=$(grep -m1 '^class_name [A-Za-z_]' "$file" 2>/dev/null \
              | awk '{print $2}')
      for t in $(git ls-files 'tests/**/test_*.gd'); do
        if grep -qE "\b${stem}\b" "$t" 2>/dev/null \
           || { [ -n "$cname" ] && grep -qE "\b${cname}\b" "$t" 2>/dev/null; }; then
          add "$(basename "$t" .gd)"
        fi
      done ;;
    project.godot|*.tscn|*.tres)
      # Un réglage de projet ou une scène touchent potentiellement tout : on ne
      # devine pas, on le DIT et on renvoie vers le portail complet.
      echo
      echo "  « $file » peut affecter n'importe quoi : portail SÉLECTIF inadapté."
      echo "  Lancer tools/validate_fast.sh."
      exit 2 ;;
  esac
done <<< "$CHANGED"

FILTER=$(echo "$SELECTED" | tr ' ' '\n' | grep -v '^$' | sort -u | paste -sd, -)

echo
if [ -z "$FILTER" ]; then
  echo "Aucun test lié trouvé. Cela ne veut pas dire « rien à tester » :"
  echo "cela veut dire que la sélection ne sait pas relier ce diff. Lancer"
  echo "tools/validate_fast.sh avant de conclure quoi que ce soit."
  exit 0
fi
echo "=== Tests sélectionnés ==="
echo "$FILTER" | tr ',' '\n' | sed 's/^/  /'

[ "$DRY" -eq 1 ] && exit 0

echo
"$GODOT_BIN" --headless --path . --script tools/godot/test_runner.gd -- \
  "--filter=$FILTER"
RC=$?
echo
echo "Portail SÉLECTIF terminé (code $RC). Il ne remplace pas validate_fast.sh :"
echo "une régression hors du diff lui reste invisible."
exit $RC
