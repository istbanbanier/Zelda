#!/bin/bash
# Une mesure ISS-059 : un filtre, un processus, un journal.
# $1 = etiquette   $2 = filtre   $3 = timeout secondes   $4 = "verbose" | ""
set -u
cd /home/user/Zelda
OUT=evidence/world_v2/v2_3_r2b3/iss059/bissection
LBL="$1"; FILT="$2"; TMO="$3"; VRB="${4:-}"
LOG="$OUT/${LBL}.log"
EXTRA=""
[ "$VRB" = "verbose" ] && EXTRA="--verbose"
T0=$(date +%s)
XDG_DATA_HOME=/tmp/ud_bissect \
  flock -w 3000 "$PWD/.git/heavy_tools.lock" \
  timeout "$TMO" /usr/local/bin/godot $EXTRA --headless --path . \
    --script tools/godot/test_runner.gd -- --filter="$FILT" > "$LOG" 2>&1
RC=$?
T1=$(date +%s)
echo "=== $LBL RC=$RC wall=$((T1-T0))s filtre='$FILT' verbose='$VRB' $(date -u +%H:%M:%SZ)" | tee -a "$OUT/journal.txt"
