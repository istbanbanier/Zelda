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
import select
import shutil
import subprocess
import sys
import time
from pathlib import Path

BUILD = Path("/home/user/smoke_lot1r2/build/EclatsDOrage.x86_64")
OUT = Path("/home/user/smoke_lot1r2/resultat")
PROFIL = Path("/home/user/smoke_lot1r2/profil_vierge")
DISPLAY = ""   # attribué par demarrer_xvfb() — jamais codé en dur
W, H = 1024, 768
TITRE = "Eclats d'Orage"

constats: list[dict] = []

# PROPRIÉTÉ STRICTE DES PROCESSUS (correction demandée par le propriétaire,
# passe S1). Tout Popen créé par ce script est enregistré ici, et UNIQUEMENT
# eux sont nettoyés — dans un finally au niveau de l'appelant, donc sur tous
# les chemins, exception comprise. L'ancienne version faisait `pkill -x Xvfb`
# et effaçait le verrou X d'un display fixe : deux gestes GLOBAUX capables de
# tuer le serveur d'un AUTRE travail en cours — l'interdit exact de
# COMMENT_TRAVAILLER_ENSEMBLE §4, la prudence va du côté de l'automatique.
PROCS_POSSEDES: list[subprocess.Popen] = []


def nettoyer_processus() -> None:
    """Termine les processus de PROCS_POSSEDES, ordre inverse de création,
    avec attente réelle : pas de zombie, pas de PID étranger."""
    for proc in reversed(PROCS_POSSEDES):
        if proc is None or proc.poll() is not None:
            continue
        proc.terminate()
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()


def demarrer_xvfb(w: int, h: int) -> tuple[subprocess.Popen | None, str]:
    """Xvfb POSSÉDÉ, sur un display choisi par LUI (`-displayfd`).

    Xvfb prend le premier display libre et écrit son numéro sur le
    descripteur : aucun conflit possible avec un serveur existant, donc plus
    rien à tuer ni à déverrouiller qui ne soit à nous."""
    lecteur, ecrivain = os.pipe()
    try:
        proc = subprocess.Popen(
            ["Xvfb", "-displayfd", str(ecrivain),
             "-screen", "0", f"{w}x{h}x24"],
            pass_fds=(ecrivain,),
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except OSError:
        os.close(lecteur)
        os.close(ecrivain)
        return None, ""
    PROCS_POSSEDES.append(proc)
    os.close(ecrivain)
    # Borné : un Xvfb qui démarre mais n'écrit jamais figerait le harnais
    # sans message (contre-revue S1, démonstration T3 du vérificateur).
    prets, _, _ = select.select([lecteur], [], [], 15)
    if not prets:
        os.close(lecteur)
        return None, ""
    with os.fdopen(lecteur) as flux:
        numero = flux.readline().strip()
    if not numero:
        return None, ""
    return proc, f":{numero}"


def classer_erreurs(texte: str) -> tuple[list[str], list[str], list[str]]:
    """Range les ERROR en (audio, kit, autres).

    POURQUOI PAR PAIRES (correction §10, passe S1). Godot n'écrit PAS l'origine
    d'une erreur sur la ligne `ERROR:` : il l'écrit sur la ligne suivante,
    `   at: <fonction> (<fichier>:<ligne>)`. La version précédente classait sur
    le seul texte de la ligne `ERROR:`, et laissait donc passer

        ERROR: Condition "status < 0" is true. Returning: ERR_CANT_OPEN
           at: init_output_device (drivers/alsa/audio_driver_alsa.cpp:97)

    comme une erreur « autre », alors que c'est l'absence de carte son du
    conteneur — une limite déclarée dans CLAUDE.md, suivie de « All audio
    drivers failed, falling back to the dummy driver ».

    Ce n'est PAS un filtre de complaisance : rien n'est masqué. Les erreurs
    audio sont comptées, publiées et attribuées à leur cause réelle. Corriger
    une ATTRIBUTION fausse n'est pas abaisser un seuil.
    """
    lignes = texte.splitlines()
    audio: list[str] = []
    kit: list[str] = []
    autres: list[str] = []
    for i, l in enumerate(lignes):
        if not (l.startswith("ERROR:") or l.startswith("SCRIPT ERROR:")):
            continue
        suite = lignes[i + 1] if i + 1 < len(lignes) else ""
        contexte = (l + " " + suite).lower()
        if "modèle inconnu" in l:
            kit.append(l)
        elif ("alsa" in contexte or "audio" in contexte
              or "pulseaudio" in contexte):
            audio.append(f"{l}  |  {suite.strip()}")
        else:
            autres.append(f"{l}  |  {suite.strip()}")
    return audio, kit, autres


def note(cle: str, verdict: str, mesure: str) -> None:
    constats.append({"point": cle, "verdict": verdict, "mesure": mesure})
    print(f"[{verdict:8s}] {cle} — {mesure}", flush=True)


def ecrire_constats() -> None:
    """Appelée aussi depuis le finally de __main__ : une sortie PRÉCOCE
    (build absente, fenêtre introuvable) laisse quand même sa trace JSON
    (contre-revue S1)."""
    if OUT.exists():
        (OUT / "constats.json").write_text(
            json.dumps(constats, ensure_ascii=False, indent=2),
            encoding="utf-8")


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
    # Contre-revue S1 : sans cet enregistrement, le contrat du registre était
    # FAUX — une exception entre lancer() et l'entrée du try laissait le jeu
    # hors de tout nettoyage, le finally de __main__ ne connaissant que Xvfb.
    PROCS_POSSEDES.append(proc)
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
        # BLOQUÉ, pas FAIL : rien n'a été mesuré (.claude/rules/evidence.md).
        note("build présente", "BLOQUÉ", f"{BUILD} absente — rien mesuré")
        return 3
    OUT.mkdir(parents=True, exist_ok=True)

    # --- 1. profil user:// VIERGE ------------------------------------------
    if PROFIL.exists():
        shutil.rmtree(PROFIL)
    PROFIL.mkdir(parents=True)
    restant = list(PROFIL.rglob("*"))
    note("profil user:// vierge", "PASS" if not restant else "FAIL",
         f"{PROFIL} recréé, {len(restant)} entrée(s) — installation neuve")

    # --- Xvfb : display attribué, processus possédé -------------------------
    global DISPLAY
    xvfb, DISPLAY = demarrer_xvfb(W, H)
    if xvfb is None:
        note("serveur X virtuel", "BLOQUÉ",
             "Xvfb n'a pas démarré — rien n'a été observé")
        return 3
    note("serveur X virtuel possédé", "PASS",
         f"Xvfb pid {xvfb.pid} sur display {DISPLAY} choisi par -displayfd")

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
        # Contre-revue S1 : le repli « or "Boot" in lire(j1) » rendait ce
        # point incapable d'échouer — n'importe quelle ligne [boot] le
        # verdissait. Le motif seul décide.
        atteint = attendre_motif(j1, "menu principal", 60)
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

        audio, kit, autres = classer_erreurs(texte)
        for l in audio:
            print("    [audio, conteneur sans carte son] " + l, flush=True)
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
            proc.wait()
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
            audio2, kit2, autres2 = classer_erreurs(t2)
            for l in audio2:
                print("    [audio, conteneur sans carte son] " + l, flush=True)
            note("aucune erreur bloquante (session 2)",
                 "PASS" if not autres2 and not kit2 else "FAIL",
                 f"{len(autres2)} ERROR hors audio et hors kit, "
                 f"{len(kit2)} « modèle inconnu », sur "
                 f"{len(t2.splitlines())} lignes ; "
                 f"{len(audio2)} ligne(s) audio attribuées au pilote ALSA "
                 "(pas de carte son dans ce conteneur)")
        else:
            note("reprise après rechargement -> World V2", "FAIL",
                 "fenêtre introuvable en session 2")
    finally:
        proc2.terminate()
        try:
            proc2.wait(timeout=20)
        except subprocess.TimeoutExpired:
            proc2.kill()
            proc2.wait()
        fh2.close()

    (OUT / "constats.json").write_text(
        json.dumps(constats, ensure_ascii=False, indent=2), encoding="utf-8")
    echecs = [c for c in constats if c["verdict"] == "FAIL"]
    print(f"\n=== {len(constats)} points observés, {len(echecs)} FAIL ===", flush=True)
    return 1 if echecs else 0


if __name__ == "__main__":
    code = 3
    try:
        code = main()
    finally:
        # Sur TOUS les chemins — succès, FAIL, exception — seuls les
        # processus créés par ce script sont terminés, et ils le sont tous ;
        # et la trace JSON survit aux sorties précoces.
        nettoyer_processus()
        ecrire_constats()
    print(f"RC={code}", flush=True)
    sys.exit(code)
