#!/usr/bin/env python3
"""Distinguer « écran de chargement LENT » de « écran de chargement BLOQUÉ ».

Un seul verdict tiré de trente secondes d'observation confondrait les deux.
On entre dans le monde puis on photographie toutes les 20 s pendant 6 min, et
on publie la SUITE des empreintes : si elle change, le jeu avance ; si elle est
constante sur toute la fenêtre, il est arrêté. On dit aussi combien de temps a
été observé — un « rien n'a bougé » sans durée ne prouve rien.

Paramètre : chemin du binaire à observer.
"""
from __future__ import annotations
import hashlib, os, subprocess, sys, time
from pathlib import Path

BUILD = Path(sys.argv[1])
OUT = Path(sys.argv[2]); OUT.mkdir(parents=True, exist_ok=True)
PROFIL = Path(str(OUT) + "_profil")
DISPLAY = ":79"
W, H = 1024, 768
DUREE = float(sys.argv[3]) if len(sys.argv) > 3 else 360.0

def sh(a, t=20.0):
    try:
        return subprocess.run(a, capture_output=True, text=True, timeout=t,
                              env=dict(os.environ, DISPLAY=DISPLAY)).stdout.strip()
    except Exception as e:
        return f"<{e}>"

def cap(nom):
    p = OUT / f"{nom}.png"
    subprocess.run(["import", "-window", "root", str(p)],
                   env=dict(os.environ, DISPLAY=DISPLAY), capture_output=True, timeout=40)
    return p

def main() -> int:
    import shutil
    if PROFIL.exists(): shutil.rmtree(PROFIL)
    PROFIL.mkdir(parents=True)
    subprocess.run(["pkill", "-x", "Xvfb"], capture_output=True); time.sleep(1)
    Path(f"/tmp/.X{DISPLAY.lstrip(':')}-lock").unlink(missing_ok=True)
    xv = subprocess.Popen(["Xvfb", DISPLAY, "-screen", "0", f"{W}x{H}x24"],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(2)
    jr = OUT / "stdout.log"; fh = jr.open("w", encoding="utf-8")
    proc = subprocess.Popen(["stdbuf", "-oL", "-eL", str(BUILD),
                             "--rendering-driver", "opengl3",
                             "--resolution", f"{W}x{H}", "--windowed"],
                            stdout=fh, stderr=subprocess.STDOUT,
                            env=dict(os.environ, DISPLAY=DISPLAY,
                                     XDG_DATA_HOME=str(PROFIL), HOME=str(PROFIL)))
    win = ""
    for _ in range(60):
        r = sh(["xdotool", "search", "--onlyvisible", "--name", "Eclats d'Orage"])
        if r and "<" not in r: win = r.splitlines()[-1]; break
        time.sleep(1)
    print(f"fenêtre : {win or 'AUCUNE'}", flush=True)
    time.sleep(5)
    sh(["xdotool", "windowfocus", "--sync", win]); sh(["xdotool", "key", "Return"])
    print("« Nouvelle partie » envoyé", flush=True)

    debut = time.time(); precedent = None; distinctes = 0
    while time.time() - debut < DUREE:
        t = int(time.time() - debut)
        p = cap(f"t{t:04d}")
        h = hashlib.sha256(p.read_bytes()).hexdigest()[:12]
        change = "CHANGE" if h != precedent else "identique"
        if h != precedent: distinctes += 1
        print(f"  t+{t:4d}s  {h}  {change}  vivant={proc.poll() is None}", flush=True)
        precedent = h
        time.sleep(20)

    texte = jr.read_text(encoding="utf-8", errors="replace")
    print(f"\nobservé {int(time.time()-debut)} s · {distinctes} image(s) distincte(s) "
          f"sur {len(list(OUT.glob('t*.png')))} prises", flush=True)
    print(f"journal : {len(texte.splitlines())} lignes ; "
          f"{sum(1 for l in texte.splitlines() if 'modèle inconnu' in l)} « modèle inconnu » ; "
          f"{sum(1 for l in texte.splitlines() if 'modèle végétal introuvable' in l)} « modèle végétal introuvable »",
          flush=True)
    proc.terminate()
    try: proc.wait(timeout=20)
    except subprocess.TimeoutExpired: proc.kill()
    fh.close(); xv.terminate()
    return 0

if __name__ == "__main__":
    c = main(); print(f"RC={c}", flush=True); sys.exit(c)
