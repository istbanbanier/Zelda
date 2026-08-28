#!/usr/bin/env bash
# ISS-074 §6.6 — le coût CPU de la garnison, mesuré dans DEUX processus.
#
# Pourquoi deux : mesurer les deux mondes dans un seul processus a donné, le
# 2026-08-28, un monde SANS garnison plus lent de 8,8 ms que le monde AVEC —
# le second payait la destruction du premier. Un chiffre précis et absurde.
set -u -o pipefail
cd "$(dirname "$0")/.."
SORTIE="${1:-evidence/world_v2/iss074}"
mkdir -p "$SORTIE"
for MODE in avec sans; do
  tools/lancer_godot.sh --path . --script tools/godot/probe_camp_cpu_profile.gd \
    -- "--$MODE" > "$SORTIE/profil_cpu_$MODE.log" 2>&1
  RC=$?
  grep -q "FIN NOMINALE" "$SORTIE/profil_cpu_$MODE.log" || {
    echo "BLOQUÉ: la mesure « $MODE » n'a pas abouti (RC=$RC)" >&2; exit 3; }
done
python3 - "$SORTIE" <<'PYEOF'
import re, sys
d = sys.argv[1]
def lire(mode):
    t = open("%s/profil_cpu_%s.log" % (d, mode), encoding="utf-8", errors="replace").read()
    v = {}
    for cle in ("physique_ms_moyen", "physique_ms_p95", "process_ms_moyen",
                "noeuds", "gardes vivants"):
        m = re.search(r"\[profil\] %s\s*:\s*([0-9.]+)" % re.escape(cle), t)
        if m: v[cle] = float(m.group(1))
    return v
a, s = lire("avec"), lire("sans")
print("== COÛT CPU DE LA GARNISON — deux processus, mêmes réglages ==")
print("   Conteneur headless sans GPU, rendu logiciel. PAS un budget de frame.")
print("   %-20s %10s %10s %10s" % ("grandeur", "avec", "sans", "delta"))
for cle in ("physique_ms_moyen", "physique_ms_p95", "process_ms_moyen", "noeuds"):
    if cle in a and cle in s:
        print("   %-20s %10.3f %10.3f %+10.3f" % (cle, a[cle], s[cle], a[cle] - s[cle]))
print("   gardes vivants       %10.0f %10.0f" % (a.get("gardes vivants", -1),
                                                 s.get("gardes vivants", -1)))
PYEOF
