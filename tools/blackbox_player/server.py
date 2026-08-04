"""Serveur MCP « joueur en boîte noire » — le jeu vu par un agent, rien d'autre.

Pourquoi ce serveur existe. Un plan d'actions écrit à l'avance, exécuté puis
commenté, reste un test scénarisé : il ne peut ni se tromper de chemin, ni
hésiter, ni revenir en arrière — précisément ce qu'un playtest mesure. Ici,
l'agent ne reçoit qu'une IMAGE et doit choisir lui-même l'action suivante.

L'API Computer Use d'Anthropic n'est pas accessible depuis ce conteneur :
aucune clé `ANTHROPIC_API_KEY`, aucun SDK `anthropic`. On implémente donc la
seconde option — un serveur MCP stdio local, dont les outils sont les seuls que
le joueur possède. La séparation est TECHNIQUE : le sous-agent joueur n'a ni
shell, ni lecture de fichier, ni accès au dépôt. Il ne peut pas lire le code
même s'il le voulait.

Entrées RÉELLES. `xdotool` envoie des événements au serveur X ; Godot les
reçoit comme ceux d'un clavier et d'une souris, passe par son InputMap, son
`PlayerInputReader` puis son `InputIntent`. Rien n'est injecté dans le moteur,
aucune méthode de gameplay n'est appelée, aucune téléportation n'existe.

Verrouillage par pas. Le modèle met plusieurs secondes à regarder une image ;
pendant ce temps le jeu continuerait à tuer le joueur. Le processus Godot est
donc SUSPENDU (SIGSTOP) après chaque capture et repris (SIGCONT) le temps de
l'action. La suspension est extérieure au jeu : elle ne lui apprend rien et ne
révèle aucun état privé.

Outils exposés — et rien d'autre :
    game_observe   regarder l'écran
    game_act       touches maintenues + mouvement de souris + durée
    game_click     clic à une position de l'écran
    game_wait      laisser le temps passer
    game_note      écrire dans sa propre mémoire de joueur

Toute la trajectoire est enregistrée sur disque pour l'intégrateur — jamais
pour le joueur, qui n'a aucun moyen de la lire.

SDK : `mcp` 2.0, API `MCPServer` (`@server.tool()`). L'API `Server` +
`@server.list_tools()` des versions 1.x n'existe plus ici ; la vérifier avant
d'y croire fait partie des règles du projet.
"""

from __future__ import annotations

import asyncio
import json
import os
import signal
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

from mcp.server.mcpserver import MCPServer
from mcp.server.mcpserver.utilities.types import Image

PROJECT = Path(os.environ.get("ECLATS_PROJECT", "/home/user/Zelda"))
GODOT = os.environ.get("GODOT_BIN", "/usr/local/bin/godot")
DISPLAY_NUM = os.environ.get("ECLATS_DISPLAY", ":77")
SESSION = os.environ.get("ECLATS_SESSION", datetime.now(timezone.utc)
                         .strftime("session_%Y%m%d_%H%M%S"))
OUT_DIR = PROJECT / "evidence" / "blackbox_player" / SESSION
SHOT_DIR = OUT_DIR / "captures"

# XGA, comme l'implémentation officielle Anthropic : au-delà, l'image est
# redimensionnée côté modèle et les coordonnées deviennent fausses.
WIDTH, HEIGHT = 1024, 768

# Bornes de durée. Un joueur n'envoie pas trente secondes de mouvement sans
# regarder ; et une action de moins de 80 ms n'est pas un geste humain.
MIN_MS, MAX_MS = 80, 2500
# ATTENDRE n'est pas AGIR. Plafonner l'attente à 2,5 s a forcé le premier
# joueur à prendre huit « décisions » consécutives pendant un simple écran de
# chargement, ce qui l'a conduit à soupçonner un blocage inexistant. Un humain
# devant un fondu attend, il ne décide pas.
MAX_WAIT_MS = 8000

# --- Contrôles négatifs -----------------------------------------------------
# Un protocole qu'on ne peut pas faire échouer ne prouve rien. Ces deux
# interrupteurs servent UNIQUEMENT à vérifier que le joueur regarde vraiment
# l'image ; ils sont éteints par défaut et n'ont aucun effet en session
# normale. Voir docs/BLACKBOX_PLAYER_PROTOCOL.md.
#
#   ECLATS_NC_STALE=1   toutes les captures renvoient la PREMIÈRE image, gelée.
#                       Un joueur qui continue de raconter une progression
#                       cohérente n'observe pas : il improvise.
#   ECLATS_SCENE=<res>  démarre sur une scène précise au lieu du Boot, pour
#                       placer le joueur devant un écran qu'il ne connaît pas.
STALE = os.environ.get("ECLATS_NC_STALE") == "1"
START_SCENE = os.environ.get("ECLATS_SCENE", "")

# Touches acceptées, exprimées comme un joueur les nomme. Rien d'autre ne
# passe : le serveur ne doit pas devenir une porte vers des capacités qu'un
# joueur n'a pas.
KEYMAP = {
    "z": "z", "q": "q", "s": "s", "d": "d",
    "space": "space", "shift": "shift", "ctrl": "ctrl",
    "e": "e", "r": "r", "c": "c", "x": "x", "v": "v", "f": "f",
    "tab": "Tab", "escape": "Escape", "enter": "Return",
    "up": "Up", "down": "Down", "left": "Left", "right": "Right",
}

server: MCPServer = MCPServer("eclats-blackbox-player")

_state: dict = {
    "xvfb": None,
    "godot": None,
    "window": None,
    "step": 0,
    "suspended": False,
    "started_at": None,
    "frozen": None,
}


# --- Environnement ----------------------------------------------------------

def _log(entry: dict) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    entry["t_reel"] = round(time.time() - (_state["started_at"] or time.time()), 2)
    with (OUT_DIR / "trajectory.jsonl").open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(entry, ensure_ascii=False) + "\n")


def _run(args: list[str], timeout: float = 20.0) -> subprocess.CompletedProcess:
    env = dict(os.environ, DISPLAY=DISPLAY_NUM)
    return subprocess.run(args, env=env, capture_output=True, text=True,
                          timeout=timeout)


def _ensure_game() -> None:
    """Démarre Xvfb puis Godot, une seule fois, en fenêtre 1024x768.

    La sauvegarde est ISOLÉE par session (`XDG_DATA_HOME`) : deux joueurs ne
    doivent jamais se marcher dessus, et un joueur ne doit pas hériter de la
    partie d'un autre.
    """
    if _state["godot"] is not None:
        return
    _state["started_at"] = time.time()
    SHOT_DIR.mkdir(parents=True, exist_ok=True)
    display_id = DISPLAY_NUM.lstrip(":")
    Path(f"/tmp/.X{display_id}-lock").unlink(missing_ok=True)
    _state["xvfb"] = subprocess.Popen(
        ["Xvfb", DISPLAY_NUM, "-screen", "0", f"{WIDTH}x{HEIGHT}x24"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(2.0)

    home = OUT_DIR / "user_home"
    home.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, DISPLAY=DISPLAY_NUM, XDG_DATA_HOME=str(home),
               XDG_CONFIG_HOME=str(home))
    log = (OUT_DIR / "godot_stdout.log").open("w", encoding="utf-8")
    argv = [GODOT, "--path", str(PROJECT), "--rendering-driver", "opengl3",
            "--resolution", f"{WIDTH}x{HEIGHT}", "--position", "0,0"]
    if START_SCENE:
        argv.append(START_SCENE)
    _state["godot"] = subprocess.Popen(argv, env=env, stdout=log,
                                       stderr=subprocess.STDOUT)
    # Le premier import et la compilation des shaders prennent du temps en
    # rendu logiciel. On cherche la fenêtre PAR SON NOM : `--name "."` matche
    # n'importe quoi, y compris une fenêtre interne de Xvfb, et le serveur
    # rendait alors un écran noir de 233 octets en croyant le jeu prêt.
    title = "Eclats"
    for _ in range(120):
        time.sleep(1.0)
        found = _run(["xdotool", "search", "--onlyvisible", "--name", title])
        ids = [line for line in found.stdout.split() if line.strip()]
        if ids:
            _state["window"] = ids[-1]
            break
    if _state["window"]:
        _run(["xdotool", "windowactivate", "--sync", _state["window"]])
        _run(["xdotool", "windowfocus", _state["window"]])
    # Une fenêtre existante n'est pas une image dessinée. On attend que l'écran
    # cesse d'être uniforme : sinon le joueur reçoit du noir et « observe » du
    # vide sans que personne s'en aperçoive.
    drawn = False
    for _ in range(90):
        if _screen_variation() > 2.0:
            drawn = True
            break
        time.sleep(1.0)
    _log({"evenement": "demarrage", "display": DISPLAY_NUM,
          "resolution": [WIDTH, HEIGHT], "session": SESSION,
          "fenetre": _state["window"], "image_dessinee": drawn})


def _resume() -> None:
    proc = _state["godot"]
    if proc is not None and _state["suspended"]:
        os.kill(proc.pid, signal.SIGCONT)
        _state["suspended"] = False


def _suspend() -> None:
    """Suspend le jeu pendant que le modèle réfléchit.

    SIGSTOP est EXTÉRIEUR au jeu : Godot ne sait pas qu'il est arrêté, aucun
    état privé ne fuit, et le joueur ne meurt pas pendant une analyse d'image.
    """
    proc = _state["godot"]
    if proc is not None and not _state["suspended"]:
        os.kill(proc.pid, signal.SIGSTOP)
        _state["suspended"] = True


def _screen_variation() -> float:
    """Écart-type de l'écran, en pourcentage. Zéro = image uniforme."""
    try:
        out = _run(["import", "-window", "root", "-format",
                    "%[standard-deviation]", "info:"], timeout=15.0)
        value = out.stdout.strip().split()[0] if out.stdout.strip() else "0"
        return float(value) / 655.35
    except (subprocess.TimeoutExpired, ValueError, IndexError):
        return 0.0


def _shoot(label: str) -> Path:
    _state["step"] += 1
    path = SHOT_DIR / f"pas_{_state['step']:04d}_{label}.png"
    if STALE and _state["frozen"] is not None:
        return _state["frozen"]
    try:
        _run(["import", "-window", "root", str(path)])
    except subprocess.TimeoutExpired:
        pass
    if not path.exists():
        try:
            _run(["scrot", "-o", str(path)])
        except subprocess.TimeoutExpired:
            pass
    if STALE and _state["frozen"] is None and path.exists():
        _state["frozen"] = path
    return path


def _reply(label: str, note: str, extra: dict | None = None) -> list:
    path = _shoot(label)
    entry = {"pas": _state["step"], "outil": label,
             "capture": str(path.relative_to(PROJECT)) if path.exists() else None}
    if extra:
        entry.update(extra)
    _log(entry)
    blocks: list = [note]
    if path.exists() and path.stat().st_size > 0:
        blocks.append(Image(path=path))
    else:
        blocks[0] = note + " (aucune image : l'écran n'a pas pu être capturé)"
    return blocks


def _mouse(dx: float, dy: float) -> None:
    if not dx and not dy:
        return
    _run(["xdotool", "mousemove_relative", "--sync", "--",
          str(int(round(dx))), str(int(round(dy)))])


# --- Outils -----------------------------------------------------------------

@server.tool(
    description="Regarde l'écran du jeu et renvoie ce que tu vois. À appeler "
                "avant toute décision. Ne révèle aucune information interne : "
                "seulement l'image, comme un joueur devant son écran.")
async def game_observe() -> list:
    _ensure_game()
    _suspend()
    return _reply("observe", "Voici ce que tu vois maintenant.")


@server.tool(
    description="Agis : maintiens des touches et/ou bouge la souris pendant "
                "une durée, puis observe le résultat. Touches du clavier "
                "AZERTY du jeu : z q s d, space, shift, ctrl, e, r, c, x, v, "
                "f, tab, escape, enter, up, down, left, right. `mouse_delta` "
                "est un mouvement RELATIF en pixels [dx, dy] : positif vers la "
                "droite et vers le bas. Durée entre 80 et 2500 ms — un joueur "
                "regarde souvent.")
async def game_act(keys_down: list[str] | None = None,
                   mouse_delta: list[float] | None = None,
                   duration_ms: int = 500) -> list:
    _ensure_game()
    asked = list(keys_down or [])
    keys = [KEYMAP[k] for k in asked if k in KEYMAP]
    refused = [k for k in asked if k not in KEYMAP]
    delta = list(mouse_delta or [0, 0])
    ms = max(MIN_MS, min(MAX_MS, int(duration_ms)))
    _resume()
    try:
        for key in keys:
            _run(["xdotool", "keydown", key])
        slices = max(1, int(ms / 60))
        dx = float(delta[0]) / slices if len(delta) > 0 else 0.0
        dy = float(delta[1]) / slices if len(delta) > 1 else 0.0
        for _ in range(slices):
            _mouse(dx, dy)
            await asyncio.sleep(ms / 1000.0 / slices)
    finally:
        # Relâchement GARANTI : une touche restée enfoncée ferait courir le
        # personnage jusqu'à la fin de la session.
        for key in keys:
            _run(["xdotool", "keyup", key])
    _suspend()
    note = "Tu as tenu %s pendant %d ms." % (", ".join(asked) or "aucune touche", ms)
    if delta and (delta[0] or (len(delta) > 1 and delta[1])):
        note += " Souris déplacée de %s." % delta
    if refused:
        note += " Touches refusées (elles n'existent pas) : %s." % ", ".join(refused)
    return _reply("act", note, {"touches": keys, "souris": delta,
                                "duree_ms": ms, "refusees": refused})


@server.tool(
    description="Clique. `button` vaut 1 (gauche, attaque légère en jeu) ou 3 "
                "(droit, visée). Si `x` et `y` sont donnés, le curseur y va "
                "d'abord — utile dans les menus.")
async def game_click(button: int = 1, x: int | None = None,
                     y: int | None = None) -> list:
    _ensure_game()
    which = 3 if int(button) == 3 else 1
    _resume()
    if x is not None and y is not None:
        _run(["xdotool", "mousemove", "--sync", str(int(x)), str(int(y))])
    _run(["xdotool", "click", str(which)])
    await asyncio.sleep(0.45)
    _suspend()
    where = " en (%d, %d)" % (x, y) if x is not None and y is not None else ""
    return _reply("click", "Tu as cliqué%s (bouton %d)." % (where, which),
                  {"bouton": which, "x": x, "y": y})


@server.tool(
    description="Laisse le temps passer sans rien faire, puis observe. Utile "
                "pour voir une animation, un chargement ou une réaction. "
                "Jusqu'à 8000 ms : attendre n'est pas agir.")
async def game_wait(duration_ms: int = 500) -> list:
    _ensure_game()
    ms = max(MIN_MS, min(MAX_WAIT_MS, int(duration_ms)))
    _resume()
    await asyncio.sleep(ms / 1000.0)
    _suspend()
    return _reply("wait", "Tu as attendu %d ms." % ms, {"duree_ms": ms})


@server.tool(
    description="Écris dans ta mémoire de joueur : ce que tu as compris, tes "
                "hypothèses, tes objectifs, tes erreurs. N'y mets que ce que "
                "tu as VU à l'écran.")
async def game_note(text: str) -> str:
    memory_path = OUT_DIR / "player_memory.json"
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    memory = json.loads(memory_path.read_text(encoding="utf-8")) \
        if memory_path.exists() else []
    memory.append({"pas": _state["step"], "note": text.strip()})
    memory_path.write_text(json.dumps(memory, ensure_ascii=False, indent=2),
                           encoding="utf-8")
    _log({"pas": _state["step"], "outil": "game_note", "note": text.strip()})
    return "Noté."


def _shutdown() -> None:
    proc = _state.get("godot")
    if proc is not None:
        _resume()
        proc.terminate()
    xvfb = _state.get("xvfb")
    if xvfb is not None:
        xvfb.terminate()


if __name__ == "__main__":
    try:
        server.run()
    finally:
        _shutdown()
