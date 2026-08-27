#!/usr/bin/env python3
"""§10 — vues des six lieux gelés, DEPUIS LA BUILD EXPORTÉE.

Ce script ne rejuge rien de l'art : le verdict visuel de Codex sur les six
lieux reste acquis et n'est pas rouvert (directive S1 §1). Il produit une
preuve d'EMPAQUETAGE : les mêmes six caméras, lancées depuis l'exécutable
installé en environnement propre, montrent-elles bien un monde monté et non un
écran de chargement, une salle vide ou un modèle manquant ?

Il s'appuie sur les drapeaux déjà posés dans `world_v2_root.gd`, qui lisent
`OS.get_cmdline_user_args()` — donc utilisables sur une build release, qui
n'accepte PAS `--script`. C'est précisément pourquoi l'appareil de mesure vit
dans le jeu et non dans un outil.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

BUILD = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
    "/home/user/smoke_lot1r2/build/EclatsDOrage.x86_64")
OUT = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(
    "/home/user/smoke_lot1r2/resultat_s1")
PROFIL = Path("/home/user/smoke_lot1r2/profil_vues")
DISPLAY = ":79"
# 1920x1080 : MÊME résolution que les six vues éditeur archivées, sinon la
# comparaison mesurerait un rééchantillonnage et non le monde.
W, H = 1920, 1080
PLANS = Path("/home/user/Zelda/evidence/world_v2/v2_3_b/iss071/shots_six_lieux_export.json")

LIEUX = ["barrow_cemetery", "flower_field", "forest_shrine",
         "overlook_summit", "turquoise_spring", "watchtower_ruin"]

constats: list[dict] = []


def note(cle: str, verdict: str, mesure: str) -> None:
    constats.append({"point": cle, "verdict": verdict, "mesure": mesure})
    print(f"[{verdict:8s}] {cle} — {mesure}", flush=True)


def moyenne(p: Path) -> float:
    r = subprocess.run(["identify", "-format", "%[fx:mean]", str(p)],
                       capture_output=True, text=True, timeout=30)
    try:
        return float(r.stdout.strip())
    except ValueError:
        return -1.0


def main() -> int:
    if not BUILD.exists():
        note("build présente", "FAIL", f"{BUILD} absente")
        return 1
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    if PROFIL.exists():
        shutil.rmtree(PROFIL)
    PROFIL.mkdir(parents=True)
    note("profil user:// vierge", "PASS", f"{PROFIL} recréé vide")

    subprocess.run(["pkill", "-x", "Xvfb"], capture_output=True)
    time.sleep(1)
    Path(f"/tmp/.X{DISPLAY.lstrip(':')}-lock").unlink(missing_ok=True)
    xvfb = subprocess.Popen(["Xvfb", DISPLAY, "-screen", "0", f"{W}x{H}x24"],
                            stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL)
    time.sleep(2)

    vues = OUT / "vues_export"
    vues.mkdir(parents=True, exist_ok=True)
    manifeste = OUT / "manifeste_export.json"
    journal = OUT / "jeu_exporte_stdout.log"

    env = dict(os.environ, DISPLAY=DISPLAY, HOME=str(PROFIL),
               XDG_DATA_HOME=str(PROFIL / "data"),
               XDG_CONFIG_HOME=str(PROFIL / "config"))
    # `--iss071-vues=` attend le FICHIER DE PLANS, pas un booléen : les
    # transforms viennent des preuves déjà acceptées, à l'identique. Aucun
    # drapeau de sortie n'existe — le jeu est arrêté quand les six vues et le
    # manifeste sont écrits.
    argv = [str(BUILD), "--", f"--iss071-vues={PLANS}",
            f"--iss071-vues-out={vues}", f"--iss071-dump={manifeste}",
            "--iss071-chargeabilite=1"]
    print("commande :", " ".join(argv), flush=True)
    with journal.open("wb") as fh:
        proc = subprocess.Popen(argv, stdout=fh, stderr=subprocess.STDOUT,
                                env=env)
        fini = False
        for _ in range(120):          # 10 min max
            time.sleep(5)
            if proc.poll() is not None:
                fini = True
                break
            if manifeste.exists() and len(list(vues.glob("*.png"))) >= 6:
                time.sleep(5)
                break
        if not fini and proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=20)
            except subprocess.TimeoutExpired:
                proc.kill()

    texte = journal.read_text(encoding="utf-8", errors="replace")
    jalon = "fondation V2 vérifiée" in texte
    note("monde monté dans la build exportée", "PASS" if jalon else "FAIL",
         "jalon « fondation V2 vérifiée » "
         + ("présent" if jalon else "ABSENT — les vues seraient partielles"))

    note("manifeste écrit par la build", "PASS" if manifeste.exists()
         else "FAIL", f"{manifeste} "
         f"({manifeste.stat().st_size if manifeste.exists() else 0} o)")

    for lieu in LIEUX:
        trouve = sorted(vues.glob(f"*{lieu}*.png"))
        if not trouve:
            note(f"vue exportée — {lieu}", "FAIL", "aucune image produite")
            continue
        p = trouve[0]
        m = moyenne(p)
        # 0.0027 est la luminance mesurée de l'écran de chargement. Une vue
        # au-dessus de 0.02 prouve qu'un monde est rendu, pas une barre de
        # progression — c'est le piège qui a rougi la passe précédente.
        note(f"vue exportée — {lieu}",
             "PASS" if m > 0.02 else "FAIL",
             f"{p.name}, luminance moyenne {m:.4f} "
             f"(écran de chargement = 0.0027)")

    images = sorted(vues.glob("*.png"))
    empreintes = {p.name: subprocess.run(
        ["sha256sum", str(p)], capture_output=True, text=True
    ).stdout.split()[0] for p in images}
    distinctes = len(set(empreintes.values()))
    note("les six vues sont DISTINCTES",
         "PASS" if distinctes == len(images) and len(images) >= 6 else "FAIL",
         f"{len(images)} image(s), {distinctes} empreinte(s) distincte(s) — "
         "six images identiques signaleraient une photo de l'écran de "
         "chargement, pas six lieux")

    (OUT / "constats.json").write_text(
        json.dumps(constats, ensure_ascii=False, indent=2), encoding="utf-8")
    (OUT / "empreintes_vues.json").write_text(
        json.dumps(empreintes, ensure_ascii=False, indent=2), encoding="utf-8")
    xvfb.terminate()
    echecs = [c for c in constats if c["verdict"] == "FAIL"]
    print(f"\n=== {len(constats)} points observés, {len(echecs)} FAIL ===",
          flush=True)
    return 1 if echecs else 0


if __name__ == "__main__":
    sys.exit(main())
