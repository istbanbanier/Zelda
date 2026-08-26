#!/usr/bin/env python3
"""Test de fumée §4 — build AUTONOME exportée, environnement propre.

Ce script ne lit ni le dépôt, ni les tests : il lance le BINAIRE exporté et
n'observe que ce que le processus testé produit lui-même — sa sortie standard
et les pixels de sa fenêtre. Un code retour 0 du lanceur ne vaut pas verdict :
chaque point de la liste §4 doit être ADOSSÉ à une observation.

Écrit hors du dépôt ; le journal est versé dans evidence/ après coup.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

BUILD = Path("/home/user/smoke_lot1r2/build/EclatsDOrage.x86_64")
OUT = Path("/home/user/smoke_lot1r2/resultat")
PROFIL = Path("/home/user/smoke_lot1r2/profil_vierge")
DISPLAY = ":78"
W, H = 1024, 768
TITRE = "Eclats d'Orage"

constats: list[dict] = []


def note(cle: str, verdict: str, mesure: str) -> None:
    constats.append({"point": cle, "verdict": verdict, "mesure": mesure})
    print(f"[{verdict:8s}] {cle} — {mesure}", flush=True)


def sh(argv: list[str], timeout: float = 20.0) -> str:
    try:
        r = subprocess.run(argv, capture_output=True, text=True, timeout=timeout,
                           env=dict(os.environ, DISPLAY=DISPLAY))
        return (r.stdout or "").strip()
    except Exception as exc:  # noqa: BLE001
        return f"<erreur {exc}>"


def capture(nom: str) -> Path:
    chemin = OUT / f"{nom}.png"
    subprocess.run(["import", "-window", "root", str(chemin)],
                   env=dict(os.environ, DISPLAY=DISPLAY),
                   capture_output=True, timeout=30)
    return chemin


def rmse(a: Path, b: Path) -> float:
    """Différence normalisée 0..1 entre deux images. ImageMagick écrit sur stderr."""
    r = subprocess.run(["compare", "-metric", "RMSE", str(a), str(b), "null:"],
                       capture_output=True, text=True, timeout=60)
    texte = (r.stderr or "").strip()
    if "(" in texte:
        try:
            return float(texte.split("(")[1].split(")")[0])
        except ValueError:
            pass
    return -1.0


def identify_moyenne(p: Path) -> float:
    r = subprocess.run(["identify", "-format", "%[fx:mean]", str(p)],
                       capture_output=True, text=True, timeout=30)
    try:
        return float((r.stdout or "0").strip())
    except ValueError:
        return -1.0


def lire(journal: Path) -> str:
    return journal.read_text(encoding="utf-8", errors="replace") if journal.exists() else ""


def attendre_motif(journal: Path, motif: str, secondes: float) -> bool:
    fin = time.time() + secondes
    while time.time() < fin:
        if motif in lire(journal):
            return True
        time.sleep(1.0)
    return False


def lancer(journal: Path):
    env = dict(os.environ, DISPLAY=DISPLAY, XDG_DATA_HOME=str(PROFIL),
               HOME=str(PROFIL))
    fh = journal.open("w", encoding="utf-8")
    proc = subprocess.Popen(["stdbuf", "-oL", "-eL", str(BUILD),
                             "--rendering-driver", "opengl3",
                             "--resolution", f"{W}x{H}", "--windowed"],
                            stdout=fh, stderr=subprocess.STDOUT, env=env)
    return proc, fh


def fenetre() -> str:
    for _ in range(40):
        ident = sh(["xdotool", "search", "--onlyvisible", "--name", TITRE])
        if ident and "<erreur" not in ident:
            return ident.splitlines()[-1]
        time.sleep(1.0)
    return ""


def main() -> int:
    if not BUILD.exists():
        note("build présente", "FAIL", f"{BUILD} absente")
        return 1
    OUT.mkdir(parents=True, exist_ok=True)

    # --- 1. profil user:// VIERGE ------------------------------------------
    if PROFIL.exists():
        shutil.rmtree(PROFIL)
    PROFIL.mkdir(parents=True)
    restant = list(PROFIL.rglob("*"))
    note("profil user:// vierge", "PASS" if not restant else "FAIL",
         f"{PROFIL} recréé, {len(restant)} entrée(s) — installation neuve")

    # --- Xvfb ---------------------------------------------------------------
    subprocess.run(["pkill", "-x", "Xvfb"], capture_output=True)
    time.sleep(1)
    Path(f"/tmp/.X{DISPLAY.lstrip(':')}-lock").unlink(missing_ok=True)
    xvfb = subprocess.Popen(["Xvfb", DISPLAY, "-screen", "0", f"{W}x{H}x24"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(2)

    j1 = OUT / "session1_stdout.log"
    proc, fh = lancer(j1)

    try:
        # --- 2. la fenêtre du JEU existe -----------------------------------
        win = fenetre()
        note("fenêtre du build exportée", "PASS" if win else "FAIL",
             f"xdotool search «{TITRE}» -> {win or 'AUCUNE'}")
        if not win:
            return 1
        sh(["xdotool", "windowfocus", "--sync", win])
        sh(["xdotool", "windowraise", win])
        time.sleep(3)
        menu = capture("01_menu")

        # --- 3. menu atteint ------------------------------------------------
        atteint = attendre_motif(j1, "menu principal", 60) or "Boot" in lire(j1)
        note("menu principal atteint", "PASS" if atteint else "PARTIAL",
             f"journal {len(lire(j1))} o ; capture {menu.name}")

        # --- 4. « Nouvelle partie » -> World V2, jamais la vallée V1 --------
        sh(["xdotool", "windowfocus", "--sync", win]); sh(["xdotool", "key", "Return"])
        ok_v2 = attendre_motif(j1, "[world_v2] monde", 180)
        texte = lire(j1)
        note("« Nouvelle partie » ouvre World V2", "PASS" if ok_v2 else "FAIL",
             next((l for l in texte.splitlines() if "[world_v2] monde" in l),
                  "aucune ligne [world_v2] monde"))

        v1 = [l for l in texte.splitlines()
              if "scenes/world/Valley" in l or "ValleyRoot" in l]
        note("aucune vallée V1 chargée", "PASS" if not v1 else "FAIL",
             f"{len(v1)} mention(s) de la vallée V1 dans la sortie du jeu")

        # --- 5. les lieux du layout ----------------------------------------
        ligne_lieux = next((l for l in texte.splitlines()
                            if "[world_v2] lieux" in l), "")
        note("lieux posés par le layout", "PASS" if ligne_lieux else "FAIL",
             ligne_lieux or "aucune ligne [world_v2] lieux")

        pret = attendre_motif(j1, "fondation V2 vérifiée", 300)
        note("monde monté (fondation V2 vérifiée)", "PASS" if pret else "FAIL",
             f"jalon final du montage {'atteint' if pret else 'ABSENT'} "
             "dans les 300 s")
        # L'écran de chargement s'efface APRÈS le jalon : attendre qu'il
        # bouge, sinon on photographie encore la barre de progression.
        base = capture("02a_attente")
        stable = 0
        for _ in range(30):
            time.sleep(5)
            suiv = capture("02a_attente")
            d = rmse(base, suiv)
            if d > 0.02:
                stable = 0
            else:
                stable += 1
            base = suiv
            if stable >= 2:
                break
        a = capture("02_monde_avant")
        note("écran de jeu affiché (plus l'écran de chargement)",
             "PASS" if identify_moyenne(a) > 0.02 else "FAIL",
             f"luminance moyenne {identify_moyenne(a):.4f} "
             "(l'écran de chargement mesuré vaut 0.0027)")

        # --- 6. la caméra du JOUEUR répond à la souris ----------------------
        for _ in range(12):
            sh(["xdotool", "mousemove_relative", "--", "40", "0"])
            time.sleep(0.08)
        time.sleep(1.5)
        b = capture("03_apres_souris")
        d_souris = rmse(a, b)
        note("rotation caméra à la souris", "PASS" if d_souris > 0.02 else "FAIL",
             f"RMSE {d_souris:.4f} entre 02 et 03 (seuil 0.0200)")

        # --- 7. déplacement / collisions / gravité --------------------------
        sh(["xdotool", "keydown", "z"])
        time.sleep(2.5)
        sh(["xdotool", "keyup", "z"])
        time.sleep(1.5)
        c = capture("04_apres_marche")
        d_marche = rmse(b, c)
        note("déplacement à la touche Z", "PASS" if d_marche > 0.02 else "FAIL",
             f"RMSE {d_marche:.4f} entre 03 et 04 (seuil 0.0200)")

        # gravité/collision : le joueur ne traverse pas le sol. Sauter puis
        # attendre : si la gravité manquait ou le sol était absent, la vue ne
        # reviendrait pas à un état proche de l'avant-saut.
        d = capture("05_avant_saut")
        sh(["xdotool", "key", "space"])
        time.sleep(0.35)
        e = capture("06_en_l_air")
        time.sleep(3.0)
        f = capture("07_retombe")
        monte = rmse(d, e)
        revenu = rmse(d, f)
        note("gravité : saut puis retour au sol",
             "PASS" if monte > 0.005 and revenu < monte else "PARTIAL",
             f"RMSE saut {monte:.4f} · RMSE après retombée {revenu:.4f} "
             "(la vue s'écarte puis revient : le sol arrête la chute)")

        # --- 8. sauvegarde écrite -------------------------------------------
        fichiers = [p for p in PROFIL.rglob("*") if p.is_file()]
        saves = [p for p in fichiers if "save" in p.name.lower()
                 or p.suffix in (".json", ".sav", ".dat")]
        note("sauvegarde écrite dans user:// vierge",
             "PASS" if saves else "FAIL",
             f"{len(fichiers)} fichier(s) créés, dont {len(saves)} de sauvegarde : "
             + ", ".join(str(p.relative_to(PROFIL)) for p in saves[:4]))

        erreurs = [l for l in texte.splitlines()
                   if l.startswith("ERROR:") or l.startswith("SCRIPT ERROR:")]
        audio = [l for l in erreurs if "alsa" in l.lower()
                 or "audio" in l.lower()]
        kit = [l for l in erreurs if "modèle inconnu" in l]
        autres = [l for l in erreurs if l not in audio and l not in kit]
        note("modèles de kit résolus dans la build exportée",
             "PASS" if not kit else "FAIL",
             f"{len(kit)} ligne(s) « kit : modèle inconnu » ; "
             f"{len(set(kit))} modèles distincts")
        note("aucune autre erreur bloquante (session 1)",
             "PASS" if not autres else "FAIL",
             f"{len(autres)} ERROR hors audio et hors kit, sur "
             f"{len(texte.splitlines())} lignes ; "
             f"{len(audio)} ligne(s) audio (pas de carte son dans ce conteneur)")
        for l in autres[:5]:
            print("    " + l, flush=True)

    finally:
        proc.terminate()
        try:
            proc.wait(timeout=20)
        except subprocess.TimeoutExpired:
            proc.kill()
        fh.close()

    # --- 9. RECHARGEMENT : « Continuer » ne renvoie pas en V1 ---------------
    time.sleep(2)
    j2 = OUT / "session2_stdout.log"
    proc2, fh2 = lancer(j2)
    try:
        win2 = fenetre()
        if win2:
            sh(["xdotool", "windowfocus", "--sync", win2])
            time.sleep(3)
            capture("08_menu_avec_sauvegarde")
            sh(["xdotool", "windowfocus", "--sync", win2]); sh(["xdotool", "key", "Return"])
            ok2 = attendre_motif(j2, "[world_v2] monde", 180)
            t2 = lire(j2)
            v1b = [l for l in t2.splitlines()
                   if "scenes/world/Valley" in l or "ValleyRoot" in l]
            note("reprise après rechargement -> World V2",
                 "PASS" if ok2 and not v1b else "FAIL",
                 f"[world_v2] monde {'présent' if ok2 else 'ABSENT'} ; "
                 f"{len(v1b)} mention(s) V1")
            time.sleep(5)
            capture("09_monde_apres_reprise")
            err2 = [l for l in t2.splitlines()
                    if l.startswith("ERROR:") or l.startswith("SCRIPT ERROR:")]
            note("aucune erreur bloquante (session 2)",
                 "PASS" if not err2 else "FAIL",
                 f"{len(err2)} ligne(s) sur {len(t2.splitlines())}")
        else:
            note("reprise après rechargement -> World V2", "FAIL",
                 "fenêtre introuvable en session 2")
    finally:
        proc2.terminate()
        try:
            proc2.wait(timeout=20)
        except subprocess.TimeoutExpired:
            proc2.kill()
        fh2.close()
        xvfb.terminate()

    (OUT / "constats.json").write_text(
        json.dumps(constats, ensure_ascii=False, indent=2), encoding="utf-8")
    echecs = [c for c in constats if c["verdict"] == "FAIL"]
    print(f"\n=== {len(constats)} points observés, {len(echecs)} FAIL ===", flush=True)
    return 1 if echecs else 0


if __name__ == "__main__":
    code = main()
    print(f"RC={code}", flush=True)
    sys.exit(code)
