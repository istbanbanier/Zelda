#!/bin/bash
# $1 = etiquette  $2 = mode  $3 = timeout  $4 = "verbose"|""  $5 = extra arg (ex --limite=40)
set -u
cd /home/user/Zelda
OUT=evidence/world_v2/v2_3_r2b3/iss059/bissection
LBL="$1"; MODE="$2"; TMO="$3"; VRB="${4:-}"; EXTRA_ARG="${5:-}"
LOG="$OUT/${LBL}.log"
V=""; [ "$VRB" = "verbose" ] && V="--verbose"
T0=$(date +%s)
XDG_DATA_HOME=/tmp/ud_bissect \
  flock -w 3000 "$PWD/.git/heavy_tools.lock" \
  timeout "$TMO" /usr/local/bin/godot $V --headless --path . \
    --script tools/godot/probe_iss059_charge.gd -- --mode="$MODE" $EXTRA_ARG > "$LOG" 2>&1
RC=$?
T1=$(date +%s)
echo "=== $LBL RC=$RC wall=$((T1-T0))s mode='$MODE' verbose='$VRB' extra='$EXTRA_ARG' $(date -u +%H:%M:%SZ)" | tee -a "$OUT/journal.txt"
