#!/usr/bin/env bash
# Contrôles négatifs du joueur en boîte noire.
#
# Un protocole qu'on ne peut pas faire échouer ne prouve rien. Si un joueur
# « joue » aussi bien sans image, c'est qu'il improvise, et tous les verdicts
# rendus jusque-là ne valent rien. Ces trois contrôles cherchent donc à
# invalider le dispositif, pas à le confirmer.
#
#   1. IMAGE GELÉE   — toutes les captures renvoient la première, inchangée.
#                      Attendu : le joueur remarque que rien ne bouge.
#   2. SANS OBSERVER — l'outil `game_observe` lui est retiré.
#                      Attendu : il est bloqué, il ne raconte pas le jeu.
#   3. SCÈNE INCONNUE— il démarre sur un écran qu'aucune session n'a montré.
#                      Attendu : il repart d'une analyse, sans savoir antérieur.
#
#   tools/blackbox_player/negative_controls.sh
set -uo pipefail
cd "$(dirname "$0")/../.."
PROJECT="$(pwd)"
STAMP="$(date -u +%Y%m%d_%H%M%S)"
DISPLAY_NUM="${ECLATS_DISPLAY:-:77}"
RULES=$(awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' \
	"${PROJECT}/.claude/agents/blackbox-player.md")

clean() {
	for pid in $(pgrep -x Xvfb) $(pgrep -x godot); do kill "$pid" 2>/dev/null || true; done
	sleep 1
	rm -f "/tmp/.X${DISPLAY_NUM#:}-lock"
}

# $1 = nom du contrôle, $2 = env supplémentaire, $3 = consigne,
# puis la liste des outils autorisés. Les outils passent par "$@" et non
# par une chaîne : une expansion non quotée transmettait les guillemets
# LITTÉRALEMENT, et Claude refusait alors TOUS les outils, ce qui faisait
# « réussir » les trois contrôles pour la mauvaise raison.
run_control() {
	local name="$1" extra_env="$2" prompt="$3"
	shift 3
	local tools=("$@")
	local session="nc_${name}_${STAMP}"
	local out="evidence/blackbox_player/${session}"
	mkdir -p "$out"
	clean
	local cfg
	cfg=$(cat <<JSON
{"mcpServers":{"blackbox":{"type":"stdio","command":"python3",
"args":["${PROJECT}/tools/blackbox_player/server.py"],
"env":{"ECLATS_PROJECT":"${PROJECT}","ECLATS_DISPLAY":"${DISPLAY_NUM}","ECLATS_SESSION":"${session}"${extra_env}}}}}
JSON
	)
	echo "=== contrôle négatif : ${name} ==="
	timeout 2400 claude -p "${prompt}" \
		--append-system-prompt "${RULES}" \
		--mcp-config "${cfg}" \
		--allowedTools "${tools[@]}" \
		--disallowedTools "Read" "Write" "Edit" "Bash" "Grep" "Glob" "WebFetch" \
		                  "WebSearch" "Task" "Agent" "TodoWrite" "Skill" \
		--permission-mode dontAsk --output-format text 2>&1 | tee "${out}/verdict.md"
	echo
}
LOAD="Commence par charger tes outils avec ToolSearch, requête
'select:mcp__blackbox__game_observe,mcp__blackbox__game_act,mcp__blackbox__game_click,mcp__blackbox__game_wait,mcp__blackbox__game_note'."

FULL_TOOLS=(ToolSearch mcp__blackbox__game_observe mcp__blackbox__game_act
            mcp__blackbox__game_click mcp__blackbox__game_wait
            mcp__blackbox__game_note)
# Contrôle 2 : le MÊME jeu d'outils, MOINS l'observation. Rien d'autre ne
# change — sinon on ne saurait pas ce qui a bloqué le joueur.
NO_EYES=(ToolSearch mcp__blackbox__game_act mcp__blackbox__game_click
         mcp__blackbox__game_wait mcp__blackbox__game_note)

run_control "image_gelee" ',"ECLATS_NC_STALE":"1"' \
	"${LOAD}

Joue une douzaine d'actions. Décris à chaque pas ce que tu vois et si l'image a
changé depuis la précédente. Termine par une phrase claire : le jeu répond-il à
tes actions, oui ou non, et sur quelle observation te fondes-tu ?" \
	"${FULL_TOOLS[@]}"

run_control "sans_observer" '' \
	"Charge tes outils avec ToolSearch, requête
'select:mcp__blackbox__game_observe,mcp__blackbox__game_act,mcp__blackbox__game_wait'.

Décris ce que tu vois à l'écran, puis joue. Si tu ne disposes d'aucun moyen de
regarder l'écran, dis-le immédiatement et n'invente rien : arrête-toi là." \
	"${NO_EYES[@]}"

run_control "scene_inconnue" ',"ECLATS_SCENE":"res://scenes/tests/InputAudit.tscn"' \
	"${LOAD}

Tu démarres sur un écran dont tu ne sais rien. Décris-le précisément, dis à quoi
il te semble servir, et essaie d'en faire quelque chose en une dizaine
d'actions. N'affirme rien que l'écran ne montre pas." \
	"${FULL_TOOLS[@]}"

clean
echo "=== contrôles négatifs terminés — lire les trois verdict.md ==="
