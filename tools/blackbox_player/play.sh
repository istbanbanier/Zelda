#!/usr/bin/env bash
# Lance UN joueur en boîte noire — un processus Claude Code séparé, dont les
# seuls outils sont ceux du serveur MCP `blackbox`.
#
# Pourquoi un processus séparé plutôt qu'un sous-agent de la session courante :
# `.mcp.json` et `.claude/agents/*.md` sont lus au DÉMARRAGE de Claude Code.
# Créés en cours de session, ils ne sont pas chargés — vérifié, l'agent
# `blackbox-player` était introuvable et aucun outil `mcp__blackbox__*`
# n'existait. Un `claude -p` neuf les charge, lui. La séparation devient donc
# réellement technique : ce processus n'a ni Read, ni Bash, ni Grep, ni Glob,
# ni Edit, ni Web. Il ne PEUT pas lire le code, la trace ou les tests.
#
#   tools/blackbox_player/play.sh <profil> <parcours> [tours_max]
#
# Exemple :
#   tools/blackbox_player/play.sh decouverte A 60
#
# Les preuves atterrissent dans evidence/blackbox_player/<profil>_<parcours>_<horodatage>/
set -uo pipefail
cd "$(dirname "$0")/../.."
PROJECT="$(pwd)"

PROFILE="${1:?profil manquant : decouverte | experimente | occasionnel | explorateur | prudent | presse}"
COURSE="${2:?parcours manquant : A | B | C | D | E}"
TURNS="${3:-60}"
DISPLAY_NUM="${ECLATS_DISPLAY:-:77}"
SESSION="${PROFILE}_${COURSE}_$(date -u +%Y%m%d_%H%M%S)"
OUT="evidence/blackbox_player/${SESSION}"
mkdir -p "$OUT"

# Un seul jeu à la fois : deux instances de Godot se marchent dessus, et deux
# joueurs sur le même écran X se voleraient les touches.
for pid in $(pgrep -x Xvfb) $(pgrep -x godot); do kill "$pid" 2>/dev/null || true; done
sleep 1
rm -f "/tmp/.X${DISPLAY_NUM#:}-lock"

case "$PROFILE" in
  decouverte)
    PERSONA="Tu n'as presque jamais joué à un jeu d'aventure en 3D. Tu es curieux mais lent à comprendre ; tu essaies les touches une par une et tu dis franchement quand tu ne comprends pas." ;;
  experimente)
    PERSONA="Tu joues aux jeux d'action-aventure depuis quinze ans. Tu reconnais vite les conventions, tu testes les limites, et tu es exigeant sur la réactivité des commandes et la lisibilité du combat." ;;
  occasionnel)
    PERSONA="Tu joues une heure de temps en temps. Tu veux comprendre vite et t'amuser tout de suite ; si un jeu ne te dit pas quoi faire en une minute, tu le dis." ;;
  explorateur)
    PERSONA="Tu fouilles tout. Les coins, les hauteurs, les chemins de traverse t'intéressent plus que l'objectif principal. Tu remarques les endroits vides et les décors inachevés." ;;
  prudent)
    PERSONA="Tu avances lentement, tu observes beaucoup avant d'agir, tu évites le danger et tu reviens en arrière quand tu doutes." ;;
  presse)
    PERSONA="Tu fonces. Tu sautes les explications, tu cours vers ce qui brille, et tu râles quand le jeu ne suit pas." ;;
  *) echo "profil inconnu : $PROFILE" >&2; exit 2 ;;
esac

case "$COURSE" in
  A) GOAL="Découvre ce jeu, puis approche le campement que tu apercevras et affronte ce qui s'y trouve. Ton but : gagner un combat." ;;
  B) GOAL="Découvre ce que tu portes et ce que tu peux utiliser. Ouvre ton inventaire, change d'arme si tu peux, ramasse ce que tu trouves, et essaie de comprendre à quoi servent les objets." ;;
  C) GOAL="Trouve l'entrée du grand bâtiment au loin, entre à l'intérieur, et progresse aussi loin que tu peux dans ses salles." ;;
  D) GOAL="Va jusqu'au bout du bâtiment, affronte ce qui l'occupe, et essaie de terminer le jeu." ;;
  E) GOAL="Explore le monde. Va voir le plus d'endroits différents possible et décris chacun : ce qu'il contient, s'il vaut le détour, s'il te semble fini ou vide." ;;
  *) echo "parcours inconnu : $COURSE" >&2; exit 2 ;;
esac

MCP_CONFIG=$(cat <<JSON
{"mcpServers":{"blackbox":{"type":"stdio","command":"python3",
"args":["${PROJECT}/tools/blackbox_player/server.py"],
"env":{"ECLATS_PROJECT":"${PROJECT}","ECLATS_DISPLAY":"${DISPLAY_NUM}","ECLATS_SESSION":"${SESSION}"}}}}
JSON
)

# Les règles du joueur vivent dans la définition d'agent, pour qu'il n'y ait
# qu'un seul texte à corriger, qu'on passe par le sous-agent ou par ce script.
# On saute uniquement l'en-tête YAML.
RULES=$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' \
	"${PROJECT}/.claude/agents/blackbox-player.md")
if [ -z "${RULES}" ]; then
	echo "règles du joueur introuvables — refus de lancer un joueur sans consignes" >&2
	exit 2
fi

echo "=== joueur : ${PROFILE} — parcours ${COURSE} — session ${SESSION} ==="

timeout 5400 claude -p "${PERSONA}

${GOAL}

Commence par charger tes outils : appelle ToolSearch avec la requête
'select:mcp__blackbox__game_observe,mcp__blackbox__game_act,mcp__blackbox__game_click,mcp__blackbox__game_wait,mcp__blackbox__game_note'.
Puis joue, pas par pas, jusqu'à ${TURNS} actions environ, en respectant la
boucle observer → interpréter → décider → agir → comparer.

Termine par un compte rendu en français, structuré ainsi :
### Ce que j'ai fait
### Ce que j'ai compris, et grâce à quoi
### Ce que j'ai tenté sans résultat
### Où je me suis perdu
### Ce qui m'a donné envie de continuer, ou d'arrêter
### Ce qui m'a semblé cassé, vide ou inachevé
### Notes sur 10 : plaisir immédiat, compréhension, beauté, réactivité, envie de continuer" \
  --append-system-prompt "${RULES}" \
  --mcp-config "${MCP_CONFIG}" \
  --allowedTools "ToolSearch" "mcp__blackbox__game_observe" "mcp__blackbox__game_act" \
                 "mcp__blackbox__game_click" "mcp__blackbox__game_wait" "mcp__blackbox__game_note" \
  --disallowedTools "Read" "Write" "Edit" "NotebookEdit" "Bash" "Grep" "Glob" \
                    "WebFetch" "WebSearch" "Task" "Agent" "TodoWrite" "Skill" "Artifact" \
                    "SendUserFile" "Workflow" "ReportFindings" \
  --permission-mode dontAsk \
  --output-format text 2>&1 | tee "${OUT}/verdict.md"

status=$?
echo
echo "=== fin (${status}) — preuves dans ${OUT} ==="
for pid in $(pgrep -x Xvfb) $(pgrep -x godot); do kill "$pid" 2>/dev/null || true; done
exit "$status"
