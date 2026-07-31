#!/usr/bin/env bash
# Rapport d'environnement — versions exactes, capacités d'exécution et de capture.
# Sortie : stdout + evidence/<dir>/env_report.txt si $1 est fourni.
# Ne jamais annoncer une capacité que ce script n'a pas confirmée.
set -uo pipefail

GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"
OUT="${1:-}"

report() {
  echo "=== RAPPORT D'ENVIRONNEMENT ==="
  echo "date_utc            : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "hote                : $(uname -srm)"
  echo "distribution        : $(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")"
  echo "cpu_coeurs          : $(nproc)"
  echo "ram_totale          : $(free -h | awk '/^Mem:/{print $2}')"
  echo "disque_dispo        : $(df -h . | awk 'NR==2{print $4}')"
  echo
  echo "--- Godot ---"
  if [ -x "$GODOT_BIN" ]; then
    echo "godot_bin           : $GODOT_BIN"
    echo "godot_version       : $("$GODOT_BIN" --version 2>&1 | tail -1)"
    echo "godot_headless_ok   : $("$GODOT_BIN" --headless --quit >/dev/null 2>&1 && echo oui || echo non)"
  else
    echo "godot_bin           : ABSENT ($GODOT_BIN) — lancer tools/setup_godot.sh"
  fi
  echo
  echo "--- Blender / pipeline glTF ---"
  if command -v blender >/dev/null 2>&1; then
    echo "blender_version     : $(blender --version 2>/dev/null | head -1)"
    echo "blender_python      : $(blender --background --python-expr 'import sys;print(sys.version.split()[0])' 2>/dev/null | grep -m1 -E '^[0-9]+\.')"
    echo "gltf_exporter       : $(blender --background --python-expr 'import addon_utils;print([m.bl_info.get("version") for m,_ in [(m,None) for m in addon_utils.modules()] if m.__name__=="io_scene_gltf2"])' 2>/dev/null | grep -m1 '\[')"
  else
    echo "blender             : ABSENT"
  fi
  echo
  echo "--- Capacité de rendu / capture ---"
  echo "DISPLAY             : ${DISPLAY:-<vide>}"
  echo "gpu_dri             : $(ls /dev/dri 2>/dev/null | tr '\n' ' ' || echo '<aucun /dev/dri>')"
  echo "xvfb                : $(command -v xvfb-run || echo ABSENT)"
  echo "mesa_llvmpipe       : $(ls /usr/lib/x86_64-linux-gnu/dri/swrast_dri.so 2>/dev/null || echo ABSENT)"
  echo
  echo "--- Outils annexes ---"
  echo "git                 : $(git --version 2>/dev/null)"
  echo "git_lfs             : $(git lfs version 2>/dev/null || echo ABSENT)"
  echo "python3             : $(python3 --version 2>&1)"
  echo "scons               : $(scons --version 2>/dev/null | grep -m1 'SCons: v' | sed 's/^\s*//')"
  echo "gcc                 : $(gcc --version 2>/dev/null | head -1)"
  echo
  echo "--- Dépôt ---"
  echo "branche             : $(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  echo "commit              : $(git rev-parse HEAD 2>/dev/null || echo '<aucun commit>')"
  echo "arbre_propre        : $(test -z "$(git status --porcelain 2>/dev/null)" && echo oui || echo non)"
}

if [ -n "$OUT" ]; then
  mkdir -p "$(dirname "$OUT")"
  report | tee "$OUT"
else
  report
fi
