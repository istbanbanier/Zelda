"""Contrôle de plomberie CAMÉRA — la souris tourne-t-elle vraiment la vue ?

Le premier joueur en boîte noire a écrit : « bouger la souris pour tourner la
caméra : aucune réaction, à aucun moment de la session ». Un joueur privé de
caméra ne peut ni chercher, ni viser, ni comprendre l'espace : tous ses
constats de navigation deviennent suspects.

Ce script ne juge pas le jeu. Il vérifie une seule chose, mesurable : après une
entrée souris, l'image du jeu change-t-elle *plus* qu'après une entrée nulle ?

Il n'entre dans le monde que par le menu, en cliquant « Nouvelle partie » comme
un joueur — aucune méthode de gameplay, aucun chargement forcé.

    python3 tools/blackbox_player/check_camera.py
"""

from __future__ import annotations

import base64
import hashlib
import json
import os
import subprocess
import sys
import time
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[2]
SESSION = "camcheck_" + time.strftime("%H%M%S")


class Client:
    def __init__(self) -> None:
        env = dict(os.environ, ECLATS_SESSION=SESSION,
                   ECLATS_PROJECT=str(PROJECT))
        self.proc = subprocess.Popen(
            [sys.executable, str(PROJECT / "tools/blackbox_player/server.py")],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, env=env, text=True, bufsize=1)
        self.next_id = 0

    def send(self, method: str, params: dict | None = None,
             notify: bool = False):
        message: dict = {"jsonrpc": "2.0", "method": method}
        if params is not None:
            message["params"] = params
        if not notify:
            self.next_id += 1
            message["id"] = self.next_id
        self.proc.stdin.write(json.dumps(message) + "\n")
        self.proc.stdin.flush()
        if notify:
            return None
        while True:
            line = self.proc.stdout.readline()
            if not line:
                raise RuntimeError("serveur muet:\n%s"
                                   % self.proc.stderr.read()[-1500:])
            try:
                reply = json.loads(line)
            except json.JSONDecodeError:
                continue
            if reply.get("id") == self.next_id:
                return reply

    def call(self, name: str, args: dict) -> bytes:
        reply = self.send("tools/call", {"name": name, "arguments": args})
        for block in reply.get("result", {}).get("content", []):
            if block.get("type") == "image":
                return base64.b64decode(block["data"])
        return b""

    def close(self) -> None:
        self.proc.terminate()


def differing_pixels(a: Path, b: Path) -> int:
    """Nombre de pixels qui diffèrent, mesuré par ImageMagick."""
    out = subprocess.run(
        ["compare", "-metric", "AE", str(a), str(b), "null:"],
        capture_output=True, text=True)
    text = (out.stderr or out.stdout).strip().split()[0]
    try:
        return int(float(text.replace(",", ".")))
    except ValueError:
        return -1


def main() -> int:
    client = Client()
    shots = PROJECT / "evidence/blackbox_player" / SESSION / "captures"
    try:
        client.send("initialize", {"protocolVersion": "2024-11-05",
                                   "capabilities": {},
                                   "clientInfo": {"name": "cam", "version": "0"}})
        client.send("notifications/initialized", {}, notify=True)

        print("1. démarrage et menu…")
        client.call("game_observe", {})
        print("2. « Nouvelle partie » (clic, comme un joueur)")
        client.call("game_click", {"button": 1, "x": 511, "y": 387})
        print("3. attente du chargement…")
        for _ in range(12):
            client.call("game_wait", {"duration_ms": 8000})
        base = sorted(shots.glob("*.png"))[-1]

        print("4. TÉMOIN : une attente sans entrée")
        client.call("game_wait", {"duration_ms": 400})
        still = sorted(shots.glob("*.png"))[-1]
        idle = differing_pixels(base, still)

        print("5. ESSAI : un mouvement de souris de 400 px vers la droite")
        client.call("game_act", {"mouse_delta": [400, 0], "duration_ms": 400})
        turned = sorted(shots.glob("*.png"))[-1]
        moved = differing_pixels(still, turned)
    finally:
        client.close()

    total = 1024 * 768
    print()
    print("   témoin  (rien fait)   : %7d pixels changés (%.1f %%)"
          % (idle, 100.0 * idle / total))
    print("   essai   (souris 400)  : %7d pixels changés (%.1f %%)"
          % (moved, 100.0 * moved / total))
    print()
    if moved < 0 or idle < 0:
        print("ÉCHEC : comparaison impossible")
        return 1
    if moved > max(idle * 3, total // 20):
        print("CAMÉRA OK — la souris fait bien tourner la vue.")
        return 0
    print("ÉCHEC : la souris ne tourne pas la vue plus que ne le fait "
          "l'écoulement du temps. Le joueur serait aveugle.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
