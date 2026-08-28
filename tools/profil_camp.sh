#!/usr/bin/env bash
# ISS-074 §6.6 — le coût CPU de la garnison, mesuré dans DEUX processus.
#
# Pourquoi deux : mesurer les deux mondes dans un seul processus a donné, le
# 2026-08-28, un monde SANS garnison plus lent de 8,8 ms que le monde AVEC —
# le second payait la destruction du premier. Un chiffre précis et absurde.
#
# Pourquoi un VERDICT, et pas seulement un tableau : jusqu'au 2026-08-28 cet
# outil ne pouvait pas échouer une fois les deux « FIN NOMINALE » présentes.
# Il imprimait n'importe quel delta, y compris absurde, et rendait 0. Le mode
# de panne ci-dessus serait donc revenu sous une autre cause sans que rien ne
# rougisse. Trois exigences le ferment, chacune capable de rougir seule.
set -u -o pipefail
cd "$(dirname "$0")/.."
SORTIE="${1:-evidence/world_v2/iss074}"
mkdir -p "$SORTIE"
# L'état du dépôt se lit AVANT la mesure : les deux journaux vivent sous
# evidence/, donc les écrire salirait l'arbre et le rapport dirait « 2 sales »
# en accusant sa propre sortie.
SHA="$(git rev-parse HEAD)"
SALES="$(git status --porcelain | wc -l)"
for MODE in avec sans; do
  tools/lancer_godot.sh --path . --script tools/godot/probe_camp_cpu_profile.gd \
    -- "--$MODE" > "$SORTIE/profil_cpu_$MODE.log" 2>&1
  RC=$?
  grep -q "FIN NOMINALE" "$SORTIE/profil_cpu_$MODE.log" || {
    echo "BLOQUÉ: la mesure « $MODE » n'a pas abouti (RC=$RC)" >&2; exit 3; }
done
python3 - "$SORTIE" "$SHA" "$SALES" <<'PYEOF'
import re, sys
d, sha, sales = sys.argv[1], sys.argv[2], sys.argv[3]
def lire(mode):
    t = open("%s/profil_cpu_%s.log" % (d, mode), encoding="utf-8", errors="replace").read()
    v = {}
    for cle in ("physique_ms_moyen", "physique_ms_p95", "process_ms_moyen",
                "noeuds", "gardes vivants", "echantillons", "echauffement"):
        m = re.search(r"\[profil\] %s\s*:\s*([0-9.]+)" % re.escape(cle), t)
        if m: v[cle] = float(m.group(1))
    return v
a, s = lire("avec"), lire("sans")
print("== COÛT CPU DE LA GARNISON — deux processus, mêmes réglages ==")
print("   Conteneur headless sans GPU, rendu logiciel. PAS un budget de frame.")
print("   commit %s, %s fichier(s) sale(s) dans l'arbre au moment de la mesure"
      % (sha[:12], sales))
print("   echantillons : %s par mode, apres %s d'echauffement"
      % (a.get("echantillons", "?"), a.get("echauffement", "?")))
print("   %-20s %10s %10s %10s" % ("grandeur", "avec", "sans", "delta"))
for cle in ("physique_ms_moyen", "physique_ms_p95", "process_ms_moyen", "noeuds"):
    if cle in a and cle in s:
        print("   %-20s %10.3f %10.3f %+10.3f" % (cle, a[cle], s[cle], a[cle] - s[cle]))
print("   gardes vivants       %10.0f %10.0f" % (a.get("gardes vivants", -1),
                                                 s.get("gardes vivants", -1)))
print("   Un seul run par mode, sequentiels sur conteneur partage : le p95")
print("   est du meme ordre que le delta. C'est un ECART de protocole, pas")
print("   une mesure de dispersion, et surtout pas un budget de frame.")

fautes = []
if a.get("gardes vivants") != 4.0:
    fautes.append("le monde « avec » ne porte pas 4 gardes : %r"
                  % a.get("gardes vivants"))
if s.get("gardes vivants") != 0.0:
    fautes.append("le monde temoin n'est pas vide : %r" % s.get("gardes vivants"))
for cle in ("physique_ms_moyen", "physique_ms_p95", "noeuds"):
    if cle not in a or cle not in s:
        fautes.append("grandeur absente d'un des deux journaux : %s" % cle)
    elif a[cle] < s[cle]:
        # Ajouter quatre gardes ne rend pas le monde MOINS cher. Un delta
        # negatif ne se discute pas : le protocole compare deux choses
        # differentes, comme le 2026-08-28 (deux mondes, un seul processus).
        fautes.append("delta NEGATIF sur %s (%.3f avec, %.3f sans) — le "
                      "protocole compare deux choses differentes"
                      % (cle, a[cle], s[cle]))
if fautes:
    print()
    for f in fautes:
        print("   FAUTE : %s" % f)
    print("VERDICT PROFIL : ROUGE (%d faute(s))" % len(fautes))
    sys.exit(1)
print("VERDICT PROFIL : VERT")
PYEOF
RC_VERDICT=$?
if [ "$RC_VERDICT" -ne 0 ]; then
  exit "$RC_VERDICT"
fi
