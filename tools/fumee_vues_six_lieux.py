#!/usr/bin/env python3
"""§10 — vues des six lieux gelés, DEPUIS LA BUILD EXPORTÉE.

Ce script ne rejuge rien de l'art : le verdict visuel de Codex sur les six
lieux reste acquis et n'est pas rouvert (directive S1 §1). Il produit une
preuve d'EMPAQUETAGE : les mêmes six caméras, lancées depuis l'exécutable
installé en environnement propre, montrent-elles bien le même monde monté que
les six vues éditeur archivées — et non un écran de chargement, une salle
vide, un modèle manquant ou un voile de transition ?

Il s'appuie sur les drapeaux posés dans `world_v2_root.gd`, qui lisent
`OS.get_cmdline_user_args()` — donc utilisables sur une build release, qui
n'accepte PAS `--script`. C'est pourquoi l'appareil de mesure vit dans le jeu.

CE QUE LA CONTRE-REVUE A IMPOSÉ (passe S1, trois vérificateurs adverses) :
- le jeu est lancé sous `stdbuf -oL -eL` : une build RELEASE ne vide pas son
  tampon stdout (`flush_stdout_on_print` est faux hors debug) et Godot n'a
  aucun handler SIGTERM — sans stdbuf, le `terminate()` du chemin nominal
  détruisait les jalons déjà imprimés et le harnais rougissait « jalon
  ABSENT » sur une exécution verte ;
- `--rendering-driver opengl3` est épinglé : ce conteneur n'a aucun pilote
  Vulkan, et le repli automatique est un chemin qu'aucune preuve verte du
  dépôt n'a jamais éprouvé ;
- l'appui « Nouvelle partie » n'est envoyé qu'après le jalon « menu
  principal » lu dans le journal (rendu lisible en direct par stdbuf), avec
  fenêtre cherchée `--onlyvisible` et budget aligné sur le portail ;
- la mort du binaire est détectée immédiatement (`poll()`), le rouge de
  mesure et le BLOQUÉ d'environnement rendent des codes distincts (1 / 3) ;
- les dimensions de chaque vue sont vérifiées ÉGALES aux références éditeur
  avant toute comparaison, et la comparaison A/B (RMSE normalisé) est faite
  ici même, vue par vue, valeurs publiées.

Codes retour : 0 = tout vert · 1 = au moins un FAIL de mesure · 3 = BLOQUÉ
(environnement : build absente, Xvfb impossible… — rien n'a été mesuré).
"""
from __future__ import annotations

import hashlib
import json
import os
import select
import shutil
import subprocess
import sys
import time
from pathlib import Path

# Racine du dépôt DE CE SCRIPT — pas le cwd, pas l'arbre principal : lancé
# depuis un worktree, le harnais doit lire les plans de CET arbre
# (contre-revue S1 ; même famille que le piège « --path . résout contre le
# cwd » de tools/CLAUDE.md).
RACINE = Path(__file__).resolve().parent.parent

BUILD = (Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(
    "/home/user/smoke_lot1r2/build/EclatsDOrage.x86_64"))
OUT = (Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else Path(
    "/home/user/smoke_lot1r2/resultat_s1"))
PROFIL = Path("/home/user/smoke_lot1r2/profil_vues")
DISPLAY = ""   # attribué par demarrer_xvfb() — jamais codé en dur
# Titre de la fenêtre du jeu, celui que xdotool cherche. Son ABSENCE dans la
# première version faisait planter le harnais en NameError avant même l'appui
# sur « Nouvelle partie » — défaut relevé par le propriétaire, passe S1.
TITRE = "Eclats d'Orage"
# 1920x1080 : MÊME résolution que les six vues éditeur archivées, sinon la
# comparaison mesurerait un rééchantillonnage et non le monde.
W, H = 1920, 1080
PLANS = RACINE / "evidence/world_v2/v2_3_b/iss071/shots_six_lieux_export.json"
REFERENCES = RACINE / "evidence/world_v2/v2_3_b/iss071/apres/vues_editeur"
# Marqueur de propriété du répertoire de sortie : sans lui, un mauvais
# argv[2] ferait effacer un dossier qui ne nous appartient pas.
MARQUEUR_OUT = ".fumee_s1_out"
# Seuil A/B : même monde, même caméra, même renderer logiciel — l'écart
# attendu est quasi nul. La valeur mesurée est TOUJOURS publiée à côté du
# verdict ; un dépassement se lit, il ne se devine pas.
SEUIL_RMSE = 0.05

LIEUX = ["barrow_cemetery", "flower_field", "forest_shrine",
         "overlook_summit", "turquoise_spring", "watchtower_ruin"]

constats: list[dict] = []

# PROPRIÉTÉ STRICTE DES PROCESSUS (correction demandée par le propriétaire,
# passe S1) : tout Popen créé ici est enregistré, et SEULS eux sont nettoyés,
# dans un finally au niveau de l'appelant — donc sur tous les chemins. Aucun
# pkill, aucun verrou X effacé : ces gestes globaux peuvent tuer le serveur
# d'un autre travail en cours (COMMENT_TRAVAILLER_ENSEMBLE §4).
PROCS_POSSEDES: list[subprocess.Popen] = []


def note(cle: str, verdict: str, mesure: str) -> None:
    constats.append({"point": cle, "verdict": verdict, "mesure": mesure})
    print(f"[{verdict:8s}] {cle} — {mesure}", flush=True)


def ecrire_constats() -> None:
    """Appelée aussi depuis le finally de __main__ : un échec PRÉCOCE laisse
    quand même sa trace JSON (contre-revue S1)."""
    if OUT.exists():
        (OUT / "constats.json").write_text(
            json.dumps(constats, ensure_ascii=False, indent=2),
            encoding="utf-8")


def nettoyer_processus() -> None:
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
    """Xvfb POSSÉDÉ sur un display choisi par LUI (`-displayfd`) : le premier
    display libre, écrit sur le descripteur — aucun conflit, rien d'étranger
    à tuer. Lecture bornée à 15 s : un Xvfb gelé rend un échec expliqué, pas
    un harnais figé (contre-revue S1)."""
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
    prets, _, _ = select.select([lecteur], [], [], 15)
    if not prets:
        os.close(lecteur)
        return None, ""
    with os.fdopen(lecteur) as flux:
        numero = flux.readline().strip()
    if not numero:
        return None, ""
    return proc, f":{numero}"


def sh(argv: list[str]) -> str:
    r = subprocess.run(argv, capture_output=True, text=True, timeout=30,
                       env=dict(os.environ, DISPLAY=DISPLAY))
    return r.stdout.strip()


def lire(journal: Path) -> str:
    return journal.read_text(encoding="utf-8", errors="replace") \
        if journal.exists() else ""


def attendre_motif(journal: Path, motif: str, secondes: float,
                   proc: subprocess.Popen) -> bool:
    fin = time.monotonic() + secondes
    while time.monotonic() < fin:
        if motif in lire(journal):
            return True
        if proc.poll() is not None:
            return motif in lire(journal)
        time.sleep(1.0)
    return motif in lire(journal)


def dimensions(p: Path) -> str:
    return sh(["identify", "-format", "%wx%h", str(p)])


def moyenne(p: Path) -> float:
    try:
        return float(sh(["identify", "-format", "%[fx:mean]", str(p)]))
    except ValueError:
        return -1.0


def rmse_normalise(a: Path, b: Path) -> float:
    """`compare -metric RMSE` écrit « brut (normalisé) » sur STDERR."""
    r = subprocess.run(["compare", "-metric", "RMSE", str(a), str(b),
                        "null:"], capture_output=True, text=True, timeout=120)
    texte = r.stderr.strip()
    try:
        return float(texte[texte.index("(") + 1:texte.index(")")])
    except (ValueError, IndexError):
        return -1.0


def main() -> int:
    if not BUILD.exists():
        # BLOQUÉ, pas FAIL : rien n'a été mesuré (.claude/rules/evidence.md —
        # une étape qui n'a pas pu tourner signale BLOQUÉ, jamais un rouge de
        # mesure).
        note("build présente", "BLOQUÉ", f"{BUILD} absente — rien mesuré")
        return 3
    if OUT.exists():
        if not (OUT / MARQUEUR_OUT).exists():
            note("répertoire de sortie", "BLOQUÉ",
                 f"{OUT} existe et ne porte pas notre marqueur "
                 f"{MARQUEUR_OUT} — refus de l'effacer (prudence du côté de "
                 "l'automatique)")
            return 3
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    (OUT / MARQUEUR_OUT).write_text("propriété du harnais fumee_vues_six_lieux\n",
                                    encoding="utf-8")
    if PROFIL.exists():
        shutil.rmtree(PROFIL)
    PROFIL.mkdir(parents=True)
    note("profil user:// vierge", "PASS", f"{PROFIL} recréé vide")
    if not PLANS.exists():
        note("plans de caméras", "BLOQUÉ", f"{PLANS} absent")
        return 3

    global DISPLAY
    xvfb, DISPLAY = demarrer_xvfb(W, H)
    if xvfb is None:
        note("serveur X virtuel", "BLOQUÉ",
             "Xvfb n'a pas démarré — rien n'a été observé")
        return 3
    note("serveur X virtuel possédé", "PASS",
         f"Xvfb pid {xvfb.pid} sur display {DISPLAY} choisi par -displayfd")

    vues = OUT / "vues_export"
    vues.mkdir(parents=True, exist_ok=True)
    manifeste = OUT / "manifeste_export.json"
    journal = OUT / "jeu_exporte_stdout.log"

    env = dict(os.environ, DISPLAY=DISPLAY, HOME=str(PROFIL),
               XDG_DATA_HOME=str(PROFIL / "data"),
               XDG_CONFIG_HOME=str(PROFIL / "config"))
    # `--iss071-vues=` attend le FICHIER DE PLANS : les transforms viennent
    # des preuves déjà acceptées, à l'identique. Chemins ABSOLUS exigés par
    # le lecteur côté jeu. Les drapeaux moteur (`--rendering-driver`,
    # `--resolution`, `--windowed`) précèdent `--` ; les nôtres le suivent.
    argv = ["stdbuf", "-oL", "-eL", str(BUILD),
            "--rendering-driver", "opengl3",
            "--resolution", f"{W}x{H}", "--windowed",
            "--", f"--iss071-vues={PLANS}",
            f"--iss071-vues-out={vues}", f"--iss071-dump={manifeste}",
            "--iss071-chargeabilite=1"]
    print("commande :", " ".join(argv), flush=True)
    with journal.open("w", encoding="utf-8") as fh:
        proc = subprocess.Popen(argv, stdout=fh, stderr=subprocess.STDOUT,
                                env=env)
        PROCS_POSSEDES.append(proc)

        # LE JEU DÉMARRE AU MENU, PAS DANS LE MONDE. Sans « Nouvelle
        # partie », WorldV2Root n'est jamais instancié et AUCUN drapeau
        # --iss071-* n'a d'effet. L'appui n'est envoyé qu'une fois le menu
        # réellement annoncé dans le journal — lisible en direct grâce à
        # stdbuf — et la fenêtre trouvée PAR --onlyvisible.
        if not attendre_motif(journal, "menu principal", 120, proc):
            mort = proc.poll()
            note("menu principal atteint", "FAIL",
                 "jalon jamais imprimé en 120 s"
                 + (f" — le binaire est MORT (code {mort})"
                    if mort is not None else ""))
            return 1
        win = ""
        fin = time.monotonic() + 120
        while time.monotonic() < fin:
            if proc.poll() is not None:
                note("fenêtre du build exportée", "FAIL",
                     f"le binaire est mort (code {proc.poll()}) avant "
                     "d'ouvrir une fenêtre visible")
                return 1
            ids = sh(["xdotool", "search", "--onlyvisible",
                      "--name", TITRE]).split()
            if ids:
                win = ids[-1]
                break
            time.sleep(2)
        note("fenêtre du build exportée", "PASS" if win else "FAIL",
             f"xdotool search --onlyvisible «{TITRE}» -> {win or 'AUCUNE'}")
        if not win:
            return 1
        sh(["xdotool", "windowfocus", "--sync", win])
        sh(["xdotool", "windowraise", win])
        time.sleep(3)
        sh(["xdotool", "key", "Return"])
        # Un Return peut se perdre (focus volé, frame de transition) : un
        # SEUL rappui, et uniquement si le monde n'a pas commencé à monter.
        if not attendre_motif(journal, "[world_v2] monde", 30, proc):
            sh(["xdotool", "windowfocus", "--sync", win])
            sh(["xdotool", "key", "Return"])
        ok_monde = attendre_motif(journal, "[world_v2] monde", 180, proc)
        note("« Nouvelle partie » ouvre World V2",
             "PASS" if ok_monde else "FAIL",
             next((l for l in lire(journal).splitlines()
                   if "[world_v2] monde" in l),
                  "aucune ligne [world_v2] monde"))
        if not ok_monde:
            return 1

        # Montage + chargeabilité + 6 rendus : budget large, sortie anticipée
        # dès que tout est sur disque ou que le processus meurt.
        fin = time.monotonic() + 900
        while time.monotonic() < fin:
            if proc.poll() is not None:
                break
            if manifeste.exists() and len(list(vues.glob("*.png"))) >= 6:
                time.sleep(5)
                break
            time.sleep(5)

    jalon = "fondation V2 vérifiée" in lire(journal)
    note("monde monté dans la build exportée", "PASS" if jalon else "FAIL",
         "jalon « fondation V2 vérifiée » "
         + ("présent" if jalon else "ABSENT — les vues seraient partielles"))
    note("manifeste écrit par la build",
         "PASS" if manifeste.exists() and manifeste.stat().st_size > 0
         else "FAIL",
         f"{manifeste} "
         f"({manifeste.stat().st_size if manifeste.exists() else 0} o)")

    attendu_dim = f"{W}x{H}"
    for lieu in LIEUX:
        trouve = sorted(vues.glob(f"*{lieu}*.png"))
        if not trouve:
            note(f"vue exportée — {lieu}", "FAIL", "aucune image produite")
            continue
        p = trouve[0]
        dim = dimensions(p)
        m = moyenne(p)
        ref = REFERENCES / p.name
        # 0.0027 est la luminance mesurée de l'écran de chargement. Une vue
        # au-dessus de 0.02 prouve qu'un monde est rendu — piège qui a rougi
        # la passe précédente. La DIMENSION est vérifiée avant l'A/B : à
        # résolutions différentes, le RMSE mesurerait un rééchantillonnage.
        if dim != attendu_dim:
            note(f"vue exportée — {lieu}", "FAIL",
                 f"{p.name} : {dim} au lieu de {attendu_dim} — la "
                 "comparaison aux références serait un rééchantillonnage")
            continue
        if m <= 0.02:
            note(f"vue exportée — {lieu}", "FAIL",
                 f"{p.name} : luminance moyenne {m:.4f} "
                 "(écran de chargement = 0.0027)")
            continue
        if not ref.exists():
            note(f"vue exportée — {lieu}", "FAIL",
                 f"référence éditeur absente : {ref}")
            continue
        ecart = rmse_normalise(p, ref)
        note(f"vue exportée — {lieu}",
             "PASS" if 0 <= ecart < SEUIL_RMSE else "FAIL",
             f"{p.name} : {dim}, luminance {m:.4f}, RMSE normalisé contre "
             f"la vue éditeur = {ecart:.5f} (seuil {SEUIL_RMSE})")

    images = sorted(vues.glob("*.png"))
    empreintes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                  for p in images}
    distinctes = len(set(empreintes.values()))
    note("les six vues sont DISTINCTES",
         "PASS" if distinctes == len(images) and len(images) >= 6 else "FAIL",
         f"{len(images)} image(s), {distinctes} empreinte(s) distincte(s) — "
         "six images identiques signaleraient une photo de l'écran de "
         "chargement, pas six lieux")

    (OUT / "empreintes_vues.json").write_text(
        json.dumps(empreintes, ensure_ascii=False, indent=2),
        encoding="utf-8")
    echecs = [c for c in constats if c["verdict"] == "FAIL"]
    bloques = [c for c in constats if c["verdict"] == "BLOQUÉ"]
    print(f"\n=== {len(constats)} points observés, {len(echecs)} FAIL, "
          f"{len(bloques)} BLOQUÉ ===", flush=True)
    if bloques:
        return 3
    return 1 if echecs else 0


if __name__ == "__main__":
    code = 3
    try:
        code = main()
    finally:
        # Tous les chemins, exception comprise ; seulement nos processus,
        # et la trace JSON même sur échec précoce.
        nettoyer_processus()
        ecrire_constats()
    sys.exit(code)
