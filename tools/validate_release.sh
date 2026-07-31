#!/usr/bin/env bash
# Pyramide de validation, niveaux 4-7 (MASTER_SPEC §21.7) :
#   4. Golden path   5. Visual   6. Performance   7. Soak/export
#
# Ces niveaux exigent un rendu réel. Ce script REFUSE de s'exécuter — et sort en
# code 3 « BLOQUÉ » — si l'environnement ne peut pas produire d'image, plutôt que
# de renvoyer un faux vert. Un gate visuel ou de performance ne peut jamais être
# déclaré PASS via un chemin qui n'a pas rendu une seule frame.
set -uo pipefail

cd "$(dirname "$0")/.."
GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"
LOG_DIR="${LOG_DIR:-evidence/validate_release}"
mkdir -p "$LOG_DIR"

echo "=== Prérequis de rendu ==="
BLOCKERS=()
[ -x "$GODOT_BIN" ] || BLOCKERS+=("binaire Godot absent ($GODOT_BIN)")
if [ -z "${DISPLAY:-}" ] && ! command -v xvfb-run >/dev/null 2>&1; then
  BLOCKERS+=("aucun affichage et xvfb-run absent")
fi
if [ ! -d /dev/dri ]; then
  echo "  AVERTISSEMENT: aucun GPU (/dev/dri absent) — rendu logiciel llvmpipe au mieux."
  echo "  Les mesures de performance obtenues ainsi ne sont PAS représentatives et"
  echo "  ne doivent jamais être publiées comme budget de frame (MASTER_SPEC §20.1)."
  SOFTWARE_ONLY=1
else
  SOFTWARE_ONLY=0
fi

if [ ${#BLOCKERS[@]} -gt 0 ]; then
  echo
  echo "=== VALIDATE_RELEASE : BLOQUÉ ==="
  for b in "${BLOCKERS[@]}"; do echo "  - $b"; done
  echo "Consigner ce blocage dans docs/KNOWN_ISSUES.md. Ne déclarer aucun gate visuel"
  echo "ou de performance PASS tant qu'il subsiste."
  exit 3
fi

echo "  affichage : ${DISPLAY:-via xvfb-run}"
echo "  gpu       : $([ $SOFTWARE_ONLY -eq 1 ] && echo 'aucun (llvmpipe logiciel)' || ls /dev/dri | tr '\n' ' ')"

RUN() { if [ -n "${DISPLAY:-}" ]; then "$@"; else xvfb-run -a -s "-screen 0 2560x1440x24" "$@"; fi; }

echo
echo "=== 5. Capture de référence ==="
CAP_LOG="$LOG_DIR/05_capture.log"
# --audio-driver Dummy : les conteneurs CI n'ont pas de périphérique ALSA ; sans
# cela Godot journalise un ERR_CANT_OPEN trompeur avant de se rabattre tout seul.
RUN "$GODOT_BIN" --path . --rendering-driver opengl3 --audio-driver Dummy \
    --script tools/godot/capture_reference.gd -- \
    --scene=res://scenes/tests/PipelineLab.tscn \
    --out=evidence/captures/pipeline_lab.png --size=1920x1080 --frames=40 \
    --label=pipeline_lab > "$CAP_LOG" 2>&1
CAP_RC=$?
if [ $CAP_RC -ne 0 ]; then
  echo "  [ÉCHEC] capture impossible (code $CAP_RC) — voir $CAP_LOG"
  tail -20 "$CAP_LOG"
  exit 1
fi
echo "  [OK] voir $CAP_LOG et evidence/captures/"

echo
echo "=== 4/6/7. Golden path, performance, soak ==="
echo "  NON EXÉCUTÉS : ces niveaux exigent respectivement la boucle complète"
echo "  (Gate G), un matériel de référence documenté (§20.1) et un build exporté."
[ $SOFTWARE_ONLY -eq 1 ] && echo "  De plus, aucun GPU : toute mesure de performance serait invalide."

echo
echo "=== VALIDATE_RELEASE : BLOQUÉ (niveau 5 vert, niveaux 4/6/7 non exécutés) ==="
echo "  Le niveau 5 (capture) a réussi, mais un script qui saute des étapes ne"
echo "  retourne pas vert (.claude/rules/evidence.md). Code 3 = BLOQUÉ, à ne jamais"
echo "  interpréter comme un PASS de gate visuel ou de performance."
exit 3
