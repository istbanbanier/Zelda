#!/usr/bin/env bash
# Capture AVANT/APRÈS à réglages identiques, l'avant étant rendu depuis un
# WORKTREE SÉPARÉ placé sur le commit de base.
#
# Volé à `pr-screenshots` de levy-street/world-of-claudecraft, dont la leçon
# n'est pas « automatiser le jugement » — leur propre documentation dit
# « There is no automated visual validation; human judgment determines
# acceptability » — mais « poser devant l'humain une comparaison HONNÊTE » :
# même scène, même caméra, même résolution, même nombre de frames, même
# renderer, et seule la modification a changé.
#
# Cet outil NE JUGE PAS. Il produit deux images comparables et un manifeste.
# Le verdict appartient à un œil sur un vrai écran (ISS-002).
#
# Usage :
#   tools/capture_ab.sh --scene=res://scenes/tests/HeroShotLab.tscn \
#       --label=heroshot_v7 [--base=HEAD~1] [--size=2560x1440] [--frames=30] \
#       [--call=methode] [--out-dir=evidence/ab/<label>] [--allow-dirty]
#
# Sorties dans <out-dir>/ :
#   avant.png + avant.json     manifeste portant le commit DE BASE
#   apres.png + apres.json     manifeste portant le commit COURANT
#   comparison.json            les deux commits, les réglages communs, les écarts
#
# Le worktree est retiré dans tous les cas, y compris en cas d'échec (trap).
# L'arbre de travail courant n'est JAMAIS touché : ni stash, ni checkout.
# C'est délibéré — la règle 1 de docs/COMMENT_TRAVAILLER_ENSEMBLE.md a coûté
# une session entière le 2026-08-07.

set -euo pipefail

GODOT_BIN="${GODOT_BIN:-/usr/local/bin/godot}"
REPO_ROOT="$(git rev-parse --show-toplevel)"

# ISS-063 — verrou canonique + cloison `user://`. Inventaire et mesure :
# evidence/world_v2/v2_3_r2b3_1/iss063/. Un correctif qui vit dans
# `tools/lancer_godot.sh` ne protège que ceux qui appellent le lanceur.
# shellcheck source=lib/godot_env.sh
. "$REPO_ROOT/tools/lib/godot_env.sh"
godot_cloison_arbre || exit 3
godot_verrou_prendre 8 3000 || exit 3

SCENE=""
LABEL=""
BASE="HEAD~1"
SIZE="2560x1440"
FRAMES="30"
CALL=""
OUT_DIR=""
ALLOW_DIRTY=0

for arg in "$@"; do
  case "$arg" in
    --scene=*)     SCENE="${arg#*=}" ;;
    --label=*)     LABEL="${arg#*=}" ;;
    --base=*)      BASE="${arg#*=}" ;;
    --size=*)      SIZE="${arg#*=}" ;;
    --frames=*)    FRAMES="${arg#*=}" ;;
    --call=*)      CALL="${arg#*=}" ;;
    --out-dir=*)   OUT_DIR="${arg#*=}" ;;
    --allow-dirty) ALLOW_DIRTY=1 ;;
    -h|--help)     sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "argument inconnu : $arg" >&2; exit 2 ;;
  esac
done

[ -n "$SCENE" ] || { echo "ERREUR: --scene est obligatoire" >&2; exit 2; }
[ -n "$LABEL" ] || { echo "ERREUR: --label est obligatoire" >&2; exit 2; }
OUT_DIR="${OUT_DIR:-evidence/ab/$LABEL}"

# --- Refus d'un arbre sale -------------------------------------------------
# .claude/rules/evidence.md : « Toute capture de preuve se fait APRÈS le commit
# du code qu'elle prouve. » Un APRÈS rendu depuis un arbre sale porte
# repo_dirty:true et ne se rattache à rien ; comparé à un AVANT propre, il
# ment sur ce qui a changé.
if [ "$ALLOW_DIRTY" -eq 0 ] && [ -n "$(git -C "$REPO_ROOT" status --porcelain --untracked-files=no)" ]; then
  cat >&2 <<'EOF'
ERREUR: arbre de travail sale.

Une comparaison avant/après suppose que l'APRÈS soit rattachable à un commit.
Commiter d'abord, puis relancer. Pour une itération jetable, non versable
comme preuve : --allow-dirty (la comparaison sera marquée jetable).
EOF
  exit 1
fi

BASE_SHA="$(git -C "$REPO_ROOT" rev-parse --verify "${BASE}^{commit}" 2>/dev/null)" || {
  echo "ERREUR: commit de base introuvable : $BASE" >&2; exit 2; }
HEAD_SHA="$(git -C "$REPO_ROOT" rev-parse --verify HEAD)"

if [ "$BASE_SHA" = "$HEAD_SHA" ]; then
  echo "ERREUR: la base et HEAD sont le même commit — il n'y a rien à comparer." >&2
  exit 2
fi

# --- Rendu logiciel : même invocation que validate_release.sh ---------------
RUN() {
  if [ -n "${DISPLAY:-}" ]; then "$@"
  else xvfb-run -a -s "-screen 0 ${SIZE}x24" "$@"; fi
}

capture() {  # $1 = racine du projet, $2 = chemin de sortie RELATIF à cette racine
  local root="$1" out="$2"
  local args=(--path "$root" --rendering-driver opengl3 --audio-driver Dummy
              --script tools/godot/capture_reference.gd --
              "--scene=$SCENE" "--out=$out" "--size=$SIZE"
              "--frames=$FRAMES" "--label=$LABEL")
  [ -n "$CALL" ] && args+=("--call=$CALL")
  [ "$ALLOW_DIRTY" -eq 1 ] && args+=(--allow-unknown-commit)
  RUN "$GODOT_BIN" "${args[@]}"
}

mkdir -p "$REPO_ROOT/$OUT_DIR"

# --- APRÈS : l'arbre courant ------------------------------------------------
echo "=== APRÈS  ($(git -C "$REPO_ROOT" rev-parse --short HEAD)) ==="
capture "$REPO_ROOT" "$OUT_DIR/apres.png"

# --- AVANT : un worktree détaché sur le commit de base ----------------------
# `git worktree` plutôt que stash/checkout : l'arbre courant n'est jamais
# modifié, donc une session parallèle ne peut pas être coupée sous les pieds.
WT="$(mktemp -d -t zelda-ab-XXXXXX)"
cleanup() {
  git -C "$REPO_ROOT" worktree remove --force "$WT" >/dev/null 2>&1 || rm -rf "$WT"
  git -C "$REPO_ROOT" worktree prune >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

echo "=== AVANT  ($(git -C "$REPO_ROOT" rev-parse --short "$BASE_SHA")) ==="
git -C "$REPO_ROOT" worktree add --detach --quiet "$WT" "$BASE_SHA"

# Un worktree neuf n'a pas de cache .godot : l'import est obligatoire, et il
# est long. C'est le prix de l'honnêteté — les ressources rendues doivent être
# celles du commit de base, pas celles d'aujourd'hui.
echo "--- import des ressources du commit de base (long) ---"
RUN "$GODOT_BIN" --headless --path "$WT" --import >/dev/null 2>&1 || {
  echo "ERREUR: import impossible sur le commit de base." >&2; exit 1; }

capture "$WT" "$OUT_DIR/avant.png"
cp "$WT/$OUT_DIR/avant.png"  "$REPO_ROOT/$OUT_DIR/avant.png"
cp "$WT/$OUT_DIR/avant.json" "$REPO_ROOT/$OUT_DIR/avant.json"

# --- Manifeste de comparaison ----------------------------------------------
# Les écarts de luminance et de couleurs distinctes sont des INDICATEURS, pas
# un verdict. Un écart nul signale surtout « la capture n'a peut-être rien
# capturé » ; un écart énorme ne dit pas si le changement est bon.
python3 - "$REPO_ROOT/$OUT_DIR" "$BASE_SHA" "$HEAD_SHA" "$SCENE" "$SIZE" \
         "$FRAMES" "$CALL" "$ALLOW_DIRTY" <<'PY'
import json, sys, pathlib
out, base, head, scene, size, frames, call, dirty = sys.argv[1:9]
d = pathlib.Path(out)
def load(name):
    p = d / name
    return json.loads(p.read_text()) if p.exists() else {}
a, b = load("avant.json"), load("apres.json")
def delta(k):
    if k not in a or k not in b:
        return None
    if isinstance(a[k], int) and isinstance(b[k], int):
        return b[k] - a[k]          # un compte reste un entier
    return round(float(b[k]) - float(a[k]), 4)
manifest = {
    "label": a.get("label") or b.get("label"),
    "jetable": dirty == "1",
    "commit_avant": base,
    "commit_apres": head,
    "reglages_identiques": {
        "scene": scene, "size": size, "frames": frames,
        "call": call or None,
        "engine_version": b.get("engine_version"),
        "rendering_method": b.get("rendering_method"),
        "rendering_driver": b.get("rendering_driver"),
    },
    "ecarts_indicatifs": {
        "luma_mean": delta("luma_mean"),
        "luma_stddev": delta("luma_stddev"),
        "distinct_colors_sampled": delta("distinct_colors_sampled"),
    },
    # Mesure du 2026-08-07 : DEUX captures du MEME commit, memes reglages,
    # HeroShotLab 1280x720/20 frames. Le rendu n'est pas reproductible au bit
    # pres. Sans ce plancher, on lit du bruit comme un changement.
    "bruit_de_fond_mesure": {
        "protocole": "2 captures du meme commit, HeroShotLab 1280x720, 20 frames, llvmpipe",
        "luma_mean": 0.0001,
        "luma_stddev": 0.0002,
        "distinct_colors_sampled": 3,
        "date": "2026-08-07",
    },
    "avertissement": (
        "Ces ecarts sont des indicateurs, pas un verdict. Un ecart inferieur "
        "au bruit de fond ci-dessus ne prouve RIEN, ni changement ni absence "
        "de changement. Le rendu est logiciel (llvmpipe, ISS-002) : ni les "
        "couleurs ni le filtrage ne sont ceux d'un GPU. Aucune note visuelle "
        "ne se derive d'ici."
    ),
}
(d / "comparison.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False))
print(json.dumps(manifest["ecarts_indicatifs"], indent=2))
PY

echo
echo "=== COMPARAISON PRÊTE ==="
echo "  $OUT_DIR/avant.png   ($(git -C "$REPO_ROOT" rev-parse --short "$BASE_SHA"))"
echo "  $OUT_DIR/apres.png   ($(git -C "$REPO_ROOT" rev-parse --short "$HEAD_SHA"))"
echo "  $OUT_DIR/comparison.json"
echo
echo "Le verdict appartient à un œil sur un vrai écran. Cet outil n'en rend aucun."
