"""Contrôle de plomberie du serveur MCP — PAS un playtest.

Ce script parle le protocole MCP au serveur, exactement comme le ferait Claude
Code, et vérifie trois choses seulement :

  1. la poignée de main aboutit et le serveur annonce ses cinq outils ;
  2. `game_observe` démarre le jeu et renvoie une VRAIE image du framebuffer ;
  3. `game_act` envoie des touches par xdotool et l'image CHANGE.

Il ne prouve rien sur le jeu. Un plan écrit ici resterait un script : c'est le
rôle du sous-agent `blackbox-player` de choisir ses actions. On prouve
uniquement que le tuyau existe et transporte de vrais pixels — sinon un agent
« jouerait » à des images vides sans que personne s'en aperçoive.

    python3 tools/blackbox_player/smoke_test.py
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
SESSION = os.environ.get("ECLATS_SESSION", "smoke_" + time.strftime("%H%M%S"))


class Client:
    """Client MCP stdio minimal : JSON-RPC ligne par ligne."""

    def __init__(self) -> None:
        env = dict(os.environ, ECLATS_SESSION=SESSION,
                   ECLATS_PROJECT=str(PROJECT))
        self.proc = subprocess.Popen(
            [sys.executable, str(PROJECT / "tools/blackbox_player/server.py")],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, env=env, text=True, bufsize=1)
        self.next_id = 0

    def send(self, method: str, params: dict | None = None,
             notify: bool = False) -> dict | None:
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
                err = self.proc.stderr.read()
                raise RuntimeError("serveur muet. stderr:\n%s" % err[-2000:])
            try:
                reply = json.loads(line)
            except json.JSONDecodeError:
                continue
            if reply.get("id") == self.next_id:
                return reply

    def close(self) -> None:
        self.proc.terminate()


def image_of(reply: dict) -> bytes:
    for block in reply.get("result", {}).get("content", []):
        if block.get("type") == "image":
            return base64.b64decode(block["data"])
    return b""


def main() -> int:
    client = Client()
    failures: list[str] = []
    try:
        hello = client.send("initialize", {
            "protocolVersion": "2024-11-05",
            "capabilities": {},
            "clientInfo": {"name": "smoke", "version": "0"}})
        print("1. poignée de main :", hello.get("result", {})
              .get("serverInfo", {}).get("name", "?"))
        client.send("notifications/initialized", {}, notify=True)

        listed = client.send("tools/list", {})
        names = sorted(t["name"] for t in listed["result"]["tools"])
        print("2. outils annoncés :", ", ".join(names))
        expected = ["game_act", "game_click", "game_note", "game_observe",
                    "game_wait"]
        if names != expected:
            failures.append("outils inattendus : %s" % names)

        print("3. démarrage du jeu et première image (peut prendre 90 s)…")
        start = time.time()
        first = client.send("tools/call",
                            {"name": "game_observe", "arguments": {}})
        png = image_of(first)
        print("   %d octets en %.0f s" % (len(png), time.time() - start))
        if len(png) < 5000:
            failures.append("image absente ou trop petite (%d octets)"
                            % len(png))
        if not png.startswith(b"\x89PNG"):
            failures.append("ce n'est pas un PNG")

        print("4. une action réelle change-t-elle l'image ?")
        # Une touche, pas un mouvement de souris : sur un menu statique le
        # curseur ne repeint rien, et le contrôle passerait pour un échec du
        # tuyau alors que le tuyau va bien. `down` déplace le focus, ce qui
        # est visible — et traverse tout le chemin X → InputMap → UI.
        acted = client.send("tools/call", {
            "name": "game_act",
            "arguments": {"keys_down": ["down"], "duration_ms": 120}})
        after = image_of(acted)
        same = hashlib.sha256(png).hexdigest() == \
            hashlib.sha256(after).hexdigest()
        print("   avant %s, après %s — %s"
              % (hashlib.sha256(png).hexdigest()[:12],
                 hashlib.sha256(after).hexdigest()[:12],
                 "IDENTIQUES" if same else "différentes"))
        if same:
            failures.append("l'image n'a pas bougé : le tuyau ne transporte "
                            "peut-être aucune entrée")
    finally:
        client.close()

    print()
    if failures:
        for line in failures:
            print("ÉCHEC :", line)
        return 1
    print("PLOMBERIE OK — le serveur transporte de vrais pixels et de vraies "
          "entrées. Cela ne dit rien du jeu.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
