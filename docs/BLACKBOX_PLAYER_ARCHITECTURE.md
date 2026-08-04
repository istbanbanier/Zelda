# Joueur visuel en boîte noire — architecture

## Le problème qu'on corrige

Les deux premières générations de « playtest » de ce projet n'en étaient pas.

**Génération 1** — `tools/godot/playtest_session.gd` : un plan d'actions écrit
à l'avance, exécuté, puis commenté par un agent qui regardait les captures. Un
plan écrit d'avance ne peut ni se tromper de chemin, ni hésiter, ni revenir en
arrière. C'est exactement ce qu'un playtest mesure. C'était un test scénarisé.

**Génération 2** — `tools/godot/playtest_live.gd` : le jeu s'arrête et attend
un fichier de décision. La boucle est fermée, mais la décision venait de
l'intégrateur, c'est-à-dire de quelqu'un qui a lu le code, connaît la carte et
sait où sont les coffres. Un joueur qui connaît la solution ne mesure rien.

**Génération 3**, décrite ici : la décision vient d'un processus séparé qui n'a
jamais vu le dépôt et ne peut pas le voir.

## L'option écartée, et pourquoi

L'API Computer Use d'Anthropic (`computer_20251124`) est la voie la plus
directe. Elle est **indisponible ici** : ni `ANTHROPIC_API_KEY`, ni
`ANTHROPIC_AUTH_TOKEN`, ni SDK `anthropic` installé. Vérifié, pas supposé. On
implémente donc la seconde option : un serveur MCP local.

## Les quatre pièces

```
   ┌──────────────────────────┐
   │ processus « joueur »     │   claude -p, contexte NEUF
   │ claude 2.1.220 headless  │   outils : les cinq de blackbox, plus rien
   └────────────┬─────────────┘
                │ MCP stdio (JSON-RPC)
   ┌────────────▼─────────────┐
   │ tools/blackbox_player/   │   Python, SDK mcp 2.0
   │ server.py                │   SIGSTOP/SIGCONT, xdotool, import
   └────────────┬─────────────┘
                │ protocole X11
   ┌────────────▼─────────────┐
   │ Xvfb :77  1024×768×24    │   un affichage dédié
   └────────────┬─────────────┘
                │
   ┌────────────▼─────────────┐
   │ godot --rendering-driver │   XDG_DATA_HOME isolé par session
   │ opengl3, fenêtre 1024×768│   sauvegarde propre à ce joueur
   └──────────────────────────┘
```

### 1. Le processus joueur

Lancé par `tools/blackbox_player/play.sh`. C'est un `claude -p` neuf, donc :

- son contexte ne contient rien de cette session de développement ;
- ses outils sont **imposés par la ligne de commande**, pas par une consigne :

```
--allowedTools    ToolSearch, mcp__blackbox__game_{observe,act,click,wait,note}
--disallowedTools Read Write Edit MultiEdit NotebookEdit Bash Grep Glob
                  WebFetch WebSearch Task Agent TodoWrite Skill Artifact
                  SendUserFile Workflow ReportFindings
```

Il n'a donc **aucun** moyen de lire un fichier, d'exécuter une commande, de
chercher dans le dépôt ou d'atteindre le réseau. La séparation est technique.
S'il voulait tricher, il ne le pourrait pas.

Son texte de consignes est le corps de `.claude/agents/blackbox-player.md`,
repris tel quel : un seul texte à maintenir, que le joueur soit invoqué comme
sous-agent ou comme processus.

### 2. Le serveur MCP

`tools/blackbox_player/server.py`, SDK `mcp` 2.0 (`MCPServer`, `@server.tool()`
— l'API `Server` + `@server.list_tools()` des versions 1.x n'existe plus, ce
qui a fait échouer la première écriture).

Cinq outils, et rien d'autre :

| Outil | Effet |
|---|---|
| `game_observe` | capture l'écran et la renvoie comme bloc image |
| `game_act` | maintient des touches, déplace la souris, pendant 80–2500 ms |
| `game_click` | clique, éventuellement après un déplacement absolu |
| `game_wait` | laisse le temps passer |
| `game_note` | écrit dans `player_memory.json` |

Chaque appel renvoie **la nouvelle image**. Le joueur ne peut donc pas agir
deux fois sans regarder : l'observation lui est imposée par la forme même du
protocole.

### 3. Les entrées sont réelles

`xdotool keydown/keyup/mousemove_relative/click` parle au serveur X. Godot
reçoit ces événements comme ceux d'un clavier et d'une souris, les fait passer
par son `InputMap`, puis par `PlayerInputReader` — le seul script de gameplay
autorisé à lire l'InputMap (D-013) — puis par `InputIntent`.

Rien n'est injecté dans le moteur. Aucune méthode de gameplay n'est appelée.
Aucune téléportation n'existe. Le joueur ne peut pas faire ce qu'un humain au
clavier ne pourrait pas faire.

Le dictionnaire `KEYMAP` est une **liste blanche** : une touche inconnue est
refusée et signalée au joueur, elle n'atteint jamais le jeu.

### 4. Le verrouillage par pas

Le modèle met plusieurs secondes à regarder une image. Pendant ce temps, un
jeu qui continue tue le joueur pour une raison qui n'a rien à voir avec le
jeu. Le processus Godot est donc arrêté par `SIGSTOP` après chaque capture et
repris par `SIGCONT` pendant l'action.

Le choix de SIGSTOP est délibéré : il est **extérieur au jeu**. Godot ne sait
pas qu'il est suspendu, aucun état privé ne fuit vers le joueur, et rien dans
le code du jeu ne change pour l'occasion. Une pause interne aurait exigé de
modifier le jeu pour le mesurer.

Contrepartie honnête : la durée perçue par le joueur n'est pas la durée réelle.
Un enchaînement jugé confortable sous verrouillage doit être rejoué **sans**
suspension avant qu'on affirme qu'il est jouable. C'est le rôle du contrôle de
rejouabilité (`replay_report.md`), qui est un contrôle de faisabilité, pas un
nouveau playtest.

## Résolution : 1024×768, et pourquoi pas 1920×1080

XGA, comme l'implémentation officielle d'Anthropic. Au-delà, l'image est
redimensionnée côté modèle et les coordonnées d'un clic ne correspondent plus à
ce qu'il voit. Un menu cliqué « à côté » ferait conclure à tort que l'interface
ne répond pas.

## Isolation des sauvegardes

`XDG_DATA_HOME` et `XDG_CONFIG_HOME` pointent vers
`evidence/blackbox_player/<session>/user_home/`. Deux joueurs ne partagent donc
ni sauvegarde, ni options. Un joueur n'hérite jamais de la partie d'un autre —
sinon le deuxième « découvrirait » un monde déjà déverrouillé.

Cette isolation lève aussi la contrainte historique du projet — jamais deux
Godot en même temps, car ils partagent `user://slot0`. Elle ne lève pas la
contrainte matérielle : en rendu logiciel, deux instances se disputent le
processeur et faussent les durées. `play.sh` tue donc tout Godot et tout Xvfb
avant de démarrer.

## Ce que l'architecture ne garantit pas

- Elle ne rend pas le jugement du joueur exact. Un agent peut décrire
  faussement ce qu'il voit ; les rapports restent des **observations, pas des
  diagnostics** (règle adoptée après trois surinterprétations vérifiées et
  réfutées, cf. `QUALITATIVE_MULTI_AGENT_REVIEW.md`).
- Elle ne mesure ni la fluidité, ni le frame pacing : rendu logiciel, sans GPU.
- Elle ne mesure rien du son : aucun périphérique audio dans ce conteneur.
- Elle ne remplace pas un humain réel.

## Limite de chargement, constatée

`.mcp.json` et `.claude/agents/*.md` sont lus au **démarrage** de Claude Code.
Créés en cours de session, ils ne sont pas pris en compte : vérifié deux fois —
`ToolSearch` ne trouvait aucun `mcp__blackbox__*`, et l'agent `blackbox-player`
était introuvable. C'est la raison pour laquelle le joueur est lancé comme
processus `claude -p` séparé, qui les charge, lui. Les deux fichiers restent au
dépôt : une session ouverte après ce commit disposera du sous-agent directement.
