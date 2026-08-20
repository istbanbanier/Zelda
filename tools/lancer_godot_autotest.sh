#!/usr/bin/env bash
# =============================================================================
# tools/lancer_godot_autotest.sh — PROUVE que tools/lancer_godot.sh isole
# réellement `user://`, et que ses refus refusent.
#
# Pourquoi un auto-test et pas une relecture : ISS-063 est né d'un mécanisme
# qu'on croyait connaître. « XDG_DATA_HOME redirige user:// » est une phrase ;
# la preuve est que deux invocations n'aperçoivent pas le marqueur l'une de
# l'autre. La différence entre les deux a coûté un échec de sauvegarde fabriqué.
#
# CINQ ÉTAPES, dont un CONTRÔLE NÉGATIF :
#   1. refus de `--filtre=`                    (usage, code 2, rien n'a tourné)
#   2. verrou déjà tenu -> BLOQUÉ code 3       (et le jeton RC_GODOT ABSENT)
#   3. deux invocations : chacune ne voit QUE son marqueur   <- la mesure
#   4. CONTRÔLE NÉGATIF : le même sondage avec un user:// PARTAGÉ doit voir
#      DEUX marqueurs. Sans lui, l'étape 3 ne prouverait rien : un sondage qui
#      ne voit jamais rien passe aussi bien quand l'isolation marche que quand
#      la lecture est cassée (PROMPT4_METHOD §2, « le test qui ne peut pas
#      échouer »).
#   5. `--rendu` : xvfb, --headless RETIRÉ, et le moteur voit un vrai
#      affichage (X11) — avec, en contraste, un run sans --rendu qui doit
#      bien rester « headless ».
#   6. ménage : aucun /tmp/lancer_godot_ud_* ne survit au trap.
#
# Note honnête sur l'étape 3 : le verrou SÉRIALISE les deux invocations, elles
# ne tournent donc pas au même instant. Cela n'affaiblit pas la mesure, cela la
# renforce : avec un `user://` partagé, la seconde lirait les restes de la
# première — c'est exactement le mécanisme d'ISS-038/063, et c'est ce que
# l'étape 4 démontre.
#
# Sortie : 0 si tout passe, 1 si une étape échoue, 3 si BLOQUÉ (verrou de dépôt
# indisponible pour l'étape 4, qui a besoin du moteur).
# =============================================================================
set -uo pipefail

RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRAP="$RACINE/tools/lancer_godot.sh"
SONDE="tools/godot/autotest_marqueur_user.gd"
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"

LOCK_DIR="$(git -C "$RACINE" rev-parse --git-common-dir 2>/dev/null || true)"
case "$LOCK_DIR" in
  "") LOCK_DIR="$RACINE/.git" ;;
  /*) ;;
  *)  LOCK_DIR="$RACINE/$LOCK_DIR" ;;
esac
LOCK_FILE="$LOCK_DIR/heavy_tools.lock"

TRAVAIL="$(mktemp -d /tmp/lancer_godot_autotest_XXXXXX)"
ECHECS=0
ETIQ="$$_$(date +%s)"

nettoyer() { rm -rf -- "$TRAVAIL" /tmp/lancer_godot_autotest_neg_"$ETIQ" 2>/dev/null || true; }
trap nettoyer EXIT

verdict() {  # verdict <PASS|FAIL> <nom> <detail>
  printf '%-6s %-34s %s\n' "$1" "$2" "$3"
  [ "$1" = "FAIL" ] && ECHECS=$((ECHECS + 1))
  return 0
}

echo "=== auto-test de tools/lancer_godot.sh ==="
echo "racine   : $RACINE"
echo "verrou   : $LOCK_FILE"
echo "cwd      : $(pwd)"
echo

# --- étape 1 : le refus de --filtre= ------------------------------------------
LOG1="$TRAVAIL/etape1.log"
"$WRAP" --path . --script "$SONDE" -- --filtre=machin > "$LOG1" 2>&1
RC1=$?
if [ "$RC1" -eq 2 ] && ! grep -q "RC_GODOT=" "$LOG1"; then
  verdict PASS "1 refus --filtre=" "RC=$RC1, jeton RC_GODOT absent (rien n'a tourné)"
else
  verdict FAIL "1 refus --filtre=" "RC=$RC1 (attendu 2), RC_GODOT présent ? $(grep -c 'RC_GODOT=' "$LOG1")"
fi

# --- étape 2 : verrou déjà tenu -> BLOQUÉ 3 -----------------------------------
# Le témoin prend le verrou et écrit un JETON. On attend le jeton, jamais un
# pgrep : une attente sur un motif se voit elle-même et dort pour toujours
# (tools/CLAUDE.md, une heure de verrou perdue).
JETON_PRIS="$TRAVAIL/verrou_pris"
( exec 8>"$LOCK_FILE"; flock -w 3000 8 || exit 3; : > "$JETON_PRIS"; sleep 12 ) &
TEMOIN=$!
ATT=0
while [ ! -f "$JETON_PRIS" ] && [ "$ATT" -lt 300 ]; do sleep 0.1; ATT=$((ATT + 1)); done

if [ ! -f "$JETON_PRIS" ]; then
  verdict FAIL "2 BLOQUÉ verrou tenu" "le témoin n'a jamais pris le verrou — étape non concluante"
else
  LOG2="$TRAVAIL/etape2.log"
  "$WRAP" --attente=1 --path . --script "$SONDE" > "$LOG2" 2>&1
  RC2=$?
  # Trois conditions, ÉVALUÉES SÉPARÉMENT. Un « et » logique dit qu'on a échoué,
  # jamais où : la première rédaction imprimait « RC=3 (attendu 3) », ce qui a
  # coûté une reproduction manuelle pour découvrir que le journal était VIDE
  # (stderr éteint par un `exec ... 2>/dev/null`, corrigé dans l'enveloppe).
  C_RC=0;  [ "$RC2" -eq 3 ] && C_RC=1
  C_TOK=0; grep -q "RC_GODOT=" "$LOG2" || C_TOK=1
  C_MSG=0; grep -q "N'A PAS TOURNÉ" "$LOG2" && C_MSG=1
  OCTETS=$(wc -c < "$LOG2")
  if [ "$C_RC" -eq 1 ] && [ "$C_TOK" -eq 1 ] && [ "$C_MSG" -eq 1 ]; then
    verdict PASS "2 BLOQUÉ verrou tenu" "RC=$RC2, RC_GODOT absent, message explicite ($OCTETS o)"
  else
    verdict FAIL "2 BLOQUÉ verrou tenu" \
      "RC=$RC2/3 ok=$C_RC | RC_GODOT absent=$C_TOK | message présent=$C_MSG | journal=$OCTETS o -> $LOG2"
  fi
fi
wait "$TEMOIN" 2>/dev/null

# --- étape 3 : LA MESURE — deux invocations, deux user:// -----------------------
NOM_A="A_$ETIQ"
NOM_B="B_$ETIQ"
LOGA="$TRAVAIL/etapeA.log"
LOGB="$TRAVAIL/etapeB.log"

AVANT_UD="$(ls -d /tmp/lancer_godot_ud_* 2>/dev/null | wc -l)"

"$WRAP" --path . --script "$SONDE" -- --marqueur="$NOM_A" > "$LOGA" 2>&1 &
PA=$!
"$WRAP" --path . --script "$SONDE" -- --marqueur="$NOM_B" > "$LOGB" 2>&1 &
PB=$!
wait "$PA"; RCA=$?
wait "$PB"; RCB=$?

lire() { grep -m1 "^MARQ $1=" "$2" 2>/dev/null | sed "s/^MARQ $1=//"; }

DIR_A="$(lire USER_DIR "$LOGA")"; DIR_B="$(lire USER_DIR "$LOGB")"
NB_A="$(lire NB_VUS   "$LOGA")";  NB_B="$(lire NB_VUS   "$LOGB")"
FIN_A="$(grep -c '^MARQ RC=0' "$LOGA")"; FIN_B="$(grep -c '^MARQ RC=0' "$LOGB")"

# Jeton de fin nominale : un RC=0 sans « MARQ RC=0 » est un succès qui n'a rien
# fait (même famille que blender --background qui rend 0 en ayant levé).
if [ "$RCA" -ne 0 ] || [ "$RCB" -ne 0 ] || [ "$FIN_A" -ne 1 ] || [ "$FIN_B" -ne 1 ]; then
  verdict FAIL "3 exécution des deux sondes" "RC A=$RCA B=$RCB ; fin nominale A=$FIN_A B=$FIN_B"
else
  verdict PASS "3 exécution des deux sondes" "RC A=$RCA B=$RCB ; jeton de fin présent des deux côtés"
fi

if [ -n "$DIR_A" ] && [ -n "$DIR_B" ] && [ "$DIR_A" != "$DIR_B" ]; then
  verdict PASS "3 user:// distincts" "A=$DIR_A"
  echo "                                          B=$DIR_B"
else
  verdict FAIL "3 user:// distincts" "A=«$DIR_A» B=«$DIR_B»"
fi

if [ "$NB_A" = "1" ] && [ "$NB_B" = "1" ] \
   && grep -q "^MARQ VU=$NOM_A\$" "$LOGA" && grep -q "^MARQ VU=$NOM_B\$" "$LOGB" \
   && ! grep -q "^MARQ VU=$NOM_B\$" "$LOGA" && ! grep -q "^MARQ VU=$NOM_A\$" "$LOGB"; then
  verdict PASS "3 ISOLATION (aucun marqueur vu)" "chacune voit 1 marqueur : le sien"
else
  verdict FAIL "3 ISOLATION (aucun marqueur vu)" "NB_VUS A=$NB_A B=$NB_B — fuite entre invocations"
fi

# --- étape 4 : CONTRÔLE NÉGATIF — un user:// partagé DOIT fuir ------------------
# Sans cette étape, l'étape 3 pourrait passer parce que la sonde ne sait pas
# lire. On force le partage et on EXIGE la fuite. On n'utilise PAS le vrai
# /root/.local/share : on démontre le mécanisme sans polluer le user:// réel,
# que d'autres agents partagent.
PARTAGE="/tmp/lancer_godot_autotest_neg_$ETIQ"
mkdir -p "$PARTAGE"
LOGN1="$TRAVAIL/neg1.log"; LOGN2="$TRAVAIL/neg2.log"
(
  exec 8>"$LOCK_FILE" || exit 3
  flock -w 3000 8 || exit 3
  XDG_DATA_HOME="$PARTAGE" timeout 600 "$GODOT_BIN" --headless --path "$RACINE" \
      --script "$SONDE" -- --marqueur="N1_$ETIQ" > "$LOGN1" 2>&1
  echo "RC=$?" >> "$LOGN1"
  XDG_DATA_HOME="$PARTAGE" timeout 600 "$GODOT_BIN" --headless --path "$RACINE" \
      --script "$SONDE" -- --marqueur="N2_$ETIQ" > "$LOGN2" 2>&1
  echo "RC=$?" >> "$LOGN2"
)
RCNEG=$?
NB_N2="$(lire NB_VUS "$LOGN2")"
if [ "$RCNEG" -eq 3 ]; then
  verdict FAIL "4 contrôle négatif (fuite exigée)" "BLOQUÉ : verrou de dépôt non obtenu, contrôle non exécuté"
elif [ "$NB_N2" = "2" ]; then
  verdict PASS "4 contrôle négatif (fuite exigée)" "user:// partagé -> la 2e sonde voit 2 marqueurs : la mesure sait rougir"
else
  verdict FAIL "4 contrôle négatif (fuite exigée)" "NB_VUS=«$NB_N2» (attendu 2) — l'étape 3 ne prouve alors RIEN"
fi

# --- étape 5 : --rendu enveloppe dans xvfb ET retire --headless ------------------
# On passe --headless EXPRÈS : l'enveloppe doit le retirer. Sinon la capture
# serait vide tout en ayant l'air d'avoir marché — le rendu est désactivé, pas
# en erreur. Le témoin est le nom du serveur d'affichage vu par le moteur.
LOG5="$TRAVAIL/etape5.log"
"$WRAP" --rendu --headless --path . --script "$SONDE" > "$LOG5" 2>&1
RC5=$?
AFF5="$(lire AFFICHAGE "$LOG5")"
RETIRE5=0; grep -q -- "--headless retiré" "$LOG5" && RETIRE5=1
if [ "$RC5" -eq 0 ] && [ "$RETIRE5" -eq 1 ] && [ -n "$AFF5" ] && [ "$AFF5" != "headless" ]; then
  verdict PASS "5 --rendu (xvfb, rendu ACTIF)" "affichage=$AFF5, --headless retiré, RC=$RC5"
else
  verdict FAIL "5 --rendu (xvfb, rendu ACTIF)" "RC=$RC5 | affichage=«$AFF5» (headless = rendu MORT) | retrait=$RETIRE5 -> $LOG5"
fi

# --- témoin de contraste : sans --rendu, l'affichage DOIT être headless --------
AFF3="$(lire AFFICHAGE "$LOGA")"
if [ "$AFF3" = "headless" ]; then
  verdict PASS "5 contraste sans --rendu" "affichage=$AFF3 (attendu : le rendu est bien désactivé)"
else
  verdict FAIL "5 contraste sans --rendu" "affichage=«$AFF3» (attendu headless)"
fi

# Le user:// partagé du contrôle négatif n'a plus d'usage : l'effacer ICI, au
# point d'usage, et non dans un trap de sortie. Sur le run rouge du 2026-08-20 il
# a survécu, parce que la voie d'échec conserve volontairement les journaux —
# un nettoyage qui dépend de la branche de sortie n'est pas un nettoyage.
rm -rf -- "$PARTAGE" 2>/dev/null || true

# --- étape 6 : le trap a bien nettoyé ------------------------------------------
APRES_UD="$(ls -d /tmp/lancer_godot_ud_* 2>/dev/null | wc -l)"
if [ "$APRES_UD" -le "$AVANT_UD" ]; then
  verdict PASS "6 ménage du user:// temporaire" "répertoires /tmp/lancer_godot_ud_* : $AVANT_UD -> $APRES_UD"
else
  verdict FAIL "6 ménage du user:// temporaire" "$((APRES_UD - AVANT_UD)) répertoire(s) oublié(s)"
fi

echo
echo "--- extraits mesurés ---"
echo "[A] $(grep '^MARQ ' "$LOGA" 2>/dev/null | tr '\n' ' ')"
echo "[B] $(grep '^MARQ ' "$LOGB" 2>/dev/null | tr '\n' ' ')"
echo "[NEG 2e sonde, user:// PARTAGÉ] $(grep '^MARQ ' "$LOGN2" 2>/dev/null | tr '\n' ' ')"
echo
if [ "$ECHECS" -eq 0 ]; then
  echo "AUTOTEST : VERT — isolation prouvée, et le contrôle négatif prouve qu'elle sait rougir."
  exit 0
fi
echo "AUTOTEST : ROUGE — $ECHECS étape(s) en échec. Journaux : $TRAVAIL (non effacés en cas d'échec)"
trap - EXIT
exit 1
