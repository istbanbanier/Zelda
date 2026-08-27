#!/usr/bin/env python3
"""S1.1 — la gravité jugée sur la POSITION Y RÉELLE du joueur.

Contrat préenregistré : `docs/contrats/s1_1_gravite.md`. Les seuils y sont
écrits AVANT toute exécution et sont importés d'ici sous forme de littéraux :
ce fichier ne les redérive pas, il les applique.

POURQUOI CET OUTIL EXISTE. `fumee_build_exportee.py` jugeait la gravité en
comparant trois captures d'écran — avant le saut, +0,35 s, +3,0 s. Sur la
build publiée : rmse(avant,air)=0,0602, rmse(avant,après)=0,1064. Le second
étant plus grand, le critère rendait PARTIAL. La cause n'était pas le sol mais
le DÉLAI : en 3,35 s le tapis de fleurs animé dérive plus que le saut ne
déplace la vue. Le critère mesurait le vent.

CE QUI LE REMPLACE, ET POURQUOI C'EST HONNÊTE. Le jeu publié embarque
l'autoload `DevMode` — sans aucun bridage de build — dont `F3` démarre un
enregistrement et `F4` pose un marqueur qui fusionne `_player_snapshot()` :

    data["y"] = snappedf(body.global_position.y, 0.1)
    data["etat"] = <nom du mode du contrôleur>

écrits en JSONL dans `user://dev_sessions/<horodatage>/journal.jsonl`. On lit
donc l'altitude du CORPS DU JOUEUR, produite par le binaire de la release
lui-même, sans modifier le jeu d'un octet.

L'exigence « exclure les fleurs et autres zones animées » est satisfaite PAR
CONSTRUCTION et non par recadrage : aucun pixel n'entre dans le verdict. Il
faut le dire ainsi, et ne pas prétendre avoir découpé une zone.

Codes retour : 0 = PASS · 1 = PARTIAL/FAIL de mesure · 3 = BLOQUÉ
(environnement, empreinte du binaire, télémétrie absente — rien n'a été
mesuré, et c'est différent d'un échec).
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

RACINE = Path(__file__).resolve().parent.parent

# On prend l'ARCHIVE publiée, pas un binaire déjà déballé : la chaîne de
# possession part de ce que la release publie réellement.
ZIP = (Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(
    "/home/user/smoke_lot1r2/retelechargement"
    "/EclatsDOrage_Linux_x86_64_05d0760.zip"))
OUT = (Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else Path(
    "/home/user/smoke_lot1r2/resultat_gravite"))
PROFIL = Path("/home/user/smoke_lot1r2/profil_gravite")

# Empreinte de l'ARTEFACT PUBLIÉ — celle qu'annonce la release lot 1.R.2 et que
# la directive nomme. C'est bien le hash du ZIP : le binaire qu'il contient a
# le sien, dérivé, qu'on publie aussi mais qui n'est l'ancre de rien.
# Vérifier AVANT de lancer : mesurer un binaire dont on n'a pas prouvé
# l'identité, c'est prouver quelque chose sur un inconnu.
SHA256_ZIP_ATTENDU = ("302643c7a5b59418d767121641f798ef0728d8358d6c0b8b"
                      "efec2e1241a8f91e")
NOM_BINAIRE = "EclatsDOrage.x86_64"

DISPLAY = ""     # attribué par demarrer_xvfb(), jamais codé en dur
TITRE = "Eclats d'Orage"
W, H = 1024, 768
JALON = "fondation V2 vérifiée"

# ---- SEUILS PRÉENREGISTRÉS (docs/contrats/s1_1_gravite.md) ----------------
# Quantum de la télémétrie : snappedf(..., 0.1). Tous les seuils en sont des
# multiples entiers, et aucun n'a été touché après la première exécution.
QUANTUM_M = 0.1
BRUIT_MAX_M = 0.10        # 1 quantum : un héros immobile ne dérive pas
EXCURSION_MIN_M = 0.50    # 5 quanta ; apex nominal 1,401 m, soit 2,8x
RETOUR_MAX_M = 0.20       # 2 quanta
ETAT_ATTENDU = "locomotion"
REPETITIONS = 3

constats: list[dict] = []
PROCS_POSSEDES: list[subprocess.Popen] = []


def note(cle: str, verdict: str, mesure: str) -> None:
    constats.append({"point": cle, "verdict": verdict, "mesure": mesure})
    print(f"[{verdict:8s}] {cle} — {mesure}", flush=True)


CODES: dict[str, int] = {"PASS": 0, "PARTIAL": 1, "FAIL": 1,
                         "NON VÉRIFIÉ": 3, "BLOQUÉ": 3}


def code_sortie() -> int:
    v = {c["verdict"] for c in constats}
    inconnus = v - set(CODES)
    if inconnus:
        print(f"BLOQUÉ: verdict(s) inconnu(s) : {sorted(inconnus)}", flush=True)
        return 3
    if "BLOQUÉ" in v or "NON VÉRIFIÉ" in v:
        return 3
    if "FAIL" in v or "PARTIAL" in v:
        return 1
    return 0


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
    """Xvfb POSSÉDÉ, sur un display qu'il choisit lui-même (`-displayfd`) :
    aucun `pkill`, aucun verrou X d'autrui effacé."""
    lecteur, ecrivain = os.pipe()
    try:
        proc = subprocess.Popen(
            ["Xvfb", "-displayfd", str(ecrivain), "-screen", "0",
             f"{w}x{h}x24"], pass_fds=(ecrivain,),
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
    return (proc, f":{numero}") if numero else (None, "")


def xdo(*args: str) -> None:
    subprocess.run(["xdotool", *args], capture_output=True,
                   env=dict(os.environ, DISPLAY=DISPLAY), timeout=30)


def empreinte(chemin: Path) -> str:
    h = hashlib.sha256()
    with chemin.open("rb") as f:
        for bloc in iter(lambda: f.read(1 << 20), b""):
            h.update(bloc)
    return h.hexdigest()


def attendre_motif(journal: Path, motif: str, secondes: float) -> bool:
    fin = time.time() + secondes
    while time.time() < fin:
        if journal.exists():
            texte = journal.read_text(encoding="utf-8", errors="replace")
            if motif in texte:
                return True
        time.sleep(1.0)
    return False


def marqueurs_du_journal(racine_user: Path) -> list[dict]:
    """Marqueurs F4, dans l'ordre de `numero`, lus au JSONL du recorder."""
    sessions = sorted(racine_user.glob("dev_sessions/*/journal.jsonl"))
    if not sessions:
        return []
    marques: list[dict] = []
    for ligne in sessions[-1].read_text(encoding="utf-8",
                                        errors="replace").splitlines():
        try:
            evt = json.loads(ligne)
        except json.JSONDecodeError:
            continue
        # Le recorder enveloppe : on accepte les deux formes plutôt que de
        # supposer laquelle, et on ne retient que ce qui porte un `y`.
        corps = evt.get("data", evt)
        if not isinstance(corps, dict):
            continue
        genre = str(evt.get("kind", evt.get("type", "")))
        if "marqueur" in genre or ("numero" in corps and "y" in corps):
            if "y" in corps:
                marques.append(corps)
    marques.sort(key=lambda m: int(m.get("numero", 0)))
    return marques


def sequence(saut: bool) -> None:
    """Une séquence de 5 marqueurs. `saut=False` = contrôle négatif.

    Les appuis sont groupés dans UN SEUL appel xdotool : son `sleep` interne
    est bien plus régulier qu'un aller-retour de processus par touche, et le
    contrat tolère de toute façon 250 ms de retard (à t=0,55 s l'altitude vaut
    encore 0,88 m, soit 1,76 x le seuil d'excursion)."""
    xdo("key", "F4")                       # M1 — sol
    time.sleep(0.5)
    xdo("key", "F4")                       # M2 — sol, sans aucune entrée
    if saut:
        xdo("key", "space", "sleep", "0.12", "key", "F4",
            "sleep", "0.18", "key", "F4")  # M3 (+0,12 s), M4 (+0,30 s)
    else:
        xdo("sleep", "0.12", "key", "F4", "sleep", "0.18", "key", "F4")
    time.sleep(1.7)
    xdo("key", "F4")                       # M5 — +2,00 s
    time.sleep(1.5)


def juger(lot: list[dict], titre: str, attend_saut: bool) -> bool:
    """Applique les critères 1 à 4 du contrat à un lot de 5 marqueurs."""
    if len(lot) != 5:
        note(titre, "BLOQUÉ",
             f"{len(lot)} marqueur(s) au lieu de 5 — séquence incomplète, "
             "rien n'a pu être jugé")
        return False
    y = [float(m["y"]) for m in lot]
    etats = [str(m.get("etat", "?")) for m in lot]
    bruit = abs(y[1] - y[0])
    excursion = max(y[2], y[3]) - y[0]
    retour = abs(y[4] - y[0])
    etat_ok = etats[0] == ETAT_ATTENDU and etats[4] == ETAT_ATTENDU

    mesure = (f"Y sol={y[0]:.1f} · repos={y[1]:.1f} · +0,12s={y[2]:.1f} · "
              f"+0,30s={y[3]:.1f} · +2,00s={y[4]:.1f} m ; "
              f"bruit={bruit:.1f} (≤{BRUIT_MAX_M}) · "
              f"excursion={excursion:.1f} ({'≥' if attend_saut else '<'}"
              f"{EXCURSION_MIN_M}) · retour={retour:.1f} "
              f"(≤{RETOUR_MAX_M}) ; états={etats[0]}/{etats[4]}")

    if attend_saut:
        ok = (bruit <= BRUIT_MAX_M and excursion >= EXCURSION_MIN_M
              and retour <= RETOUR_MAX_M and etat_ok)
    else:
        # Contrôle négatif : SANS saut, l'excursion doit rester sous le seuil.
        ok = excursion < EXCURSION_MIN_M and bruit <= BRUIT_MAX_M
    note(titre, "PASS" if ok else "FAIL", mesure)
    return ok


def main() -> int:
    if not ZIP.exists():
        note("archive de la release présente", "BLOQUÉ", f"{ZIP} absente")
        return 3

    reel_zip = empreinte(ZIP)
    conforme = reel_zip == SHA256_ZIP_ATTENDU
    note("empreinte de l'ARCHIVE publiée", "PASS" if conforme else "BLOQUÉ",
         f"sha256 mesuré {reel_zip}"
         + ("" if conforme else f" ≠ attendu {SHA256_ZIP_ATTENDU}"))
    if not conforme:
        return 3

    for d in (OUT, PROFIL):
        if d.exists():
            shutil.rmtree(d)
        d.mkdir(parents=True)
    note("profil user:// vierge", "PASS", f"{PROFIL} recréé vide")

    # Le binaire éprouvé est EXTRAIT de l'archive qu'on vient de vérifier —
    # pas ramassé à côté. Sans cela, « le ZIP est conforme » et « j'ai lancé
    # ce binaire » seraient deux affirmations sans lien.
    deballe = OUT / "binaire"
    deballe.mkdir(parents=True, exist_ok=True)
    r = subprocess.run(["unzip", "-o", "-q", str(ZIP), "-d", str(deballe)],
                       capture_output=True, text=True)
    build = deballe / NOM_BINAIRE
    if r.returncode != 0 or not build.exists():
        note("extraction du binaire", "BLOQUÉ",
             f"unzip RC={r.returncode} ; {build} absent")
        return 3
    build.chmod(0o755)
    note("binaire extrait de l'archive vérifiée", "PASS",
         f"{NOM_BINAIRE}, sha256 dérivé {empreinte(build)}")

    global DISPLAY
    xvfb, DISPLAY = demarrer_xvfb(W, H)
    if xvfb is None:
        note("serveur X virtuel", "BLOQUÉ", "Xvfb n'a pas démarré")
        return 3
    note("serveur X virtuel possédé", "PASS",
         f"Xvfb pid {xvfb.pid} sur {DISPLAY} choisi par -displayfd")

    journal = OUT / "jeu_stdout.log"
    env = dict(os.environ, DISPLAY=DISPLAY, HOME=str(PROFIL),
               XDG_DATA_HOME=str(PROFIL / "data"),
               XDG_CONFIG_HOME=str(PROFIL / "config"))
    # `stdbuf` : une build RELEASE ne vide pas son tampon stdout, et Godot n'a
    # aucun handler SIGTERM — sans lui, l'arrêt détruit les jalons imprimés.
    with journal.open("wb") as fh:
        proc = subprocess.Popen(
            ["stdbuf", "-oL", "-eL", str(build), "--rendering-driver",
             "opengl3"], stdout=fh, stderr=subprocess.STDOUT, env=env)
        PROCS_POSSEDES.append(proc)

        fenetre = ""
        for _ in range(30):
            time.sleep(2)
            if proc.poll() is not None:
                note("le jeu tourne", "BLOQUÉ",
                     f"le binaire s'est arrêté seul (code {proc.returncode})")
                return 3
            r = subprocess.run(["xdotool", "search", "--onlyvisible", "--name",
                                TITRE], capture_output=True, text=True,
                               env=dict(os.environ, DISPLAY=DISPLAY))
            ids = [x for x in r.stdout.split() if x.strip()]
            if ids:
                fenetre = ids[-1]
                break
        if not fenetre:
            note("fenêtre du jeu", "BLOQUÉ", "aucune fenêtre visible trouvée")
            return 3
        note("fenêtre du jeu", "PASS", f"xdotool -> {fenetre}")

        xdo("windowfocus", "--sync", fenetre)
        xdo("windowraise", fenetre)
        time.sleep(2)
        if not attendre_motif(journal, "menu principal", 90):
            note("menu principal atteint", "BLOQUÉ", "jalon de menu absent")
            return 3
        xdo("key", "Return")               # « Nouvelle partie »
        if not attendre_motif(journal, JALON, 300):
            note("monde monté", "BLOQUÉ", f"jalon « {JALON} » absent en 300 s")
            return 3
        note("monde monté dans la build exportée", "PASS",
             f"jalon « {JALON} » présent")
        # L'écran de chargement s'efface APRÈS le jalon ; on laisse le monde
        # se poser avant de demander un saut au héros.
        time.sleep(12)

        xdo("windowfocus", "--sync", fenetre)
        xdo("key", "F3")                   # démarre l'enregistrement DevMode
        time.sleep(2)
        for _ in range(REPETITIONS):
            sequence(saut=True)
        sequence(saut=False)               # contrôle négatif, en dernier
        xdo("key", "F3")                   # arrête et ferme le journal
        time.sleep(3)

    nettoyer_processus()

    racine_user = PROFIL / "data" / "godot" / "app_userdata" / "Eclats d'Orage"
    if not racine_user.exists():
        racine_user = PROFIL / ".local" / "share" / "godot" / \
            "app_userdata" / "Eclats d'Orage"
    marques = marqueurs_du_journal(racine_user)
    note("télémétrie DevMode produite par le jeu", "PASS" if marques
         else "BLOQUÉ",
         f"{len(marques)} marqueur(s) F4 lus dans dev_sessions/*/journal.jsonl"
         + ("" if marques else f" — rien sous {racine_user}"))
    if not marques:
        return 3

    attendus = 5 * (REPETITIONS + 1)
    if len(marques) != attendus:
        note("nombre de marqueurs", "BLOQUÉ",
             f"{len(marques)} au lieu de {attendus} — l'appareil n'a pas "
             "capté toute la séquence, aucun verdict n'est tiré")
        return 3

    tous_ok = True
    for i in range(REPETITIONS):
        lot = marques[i * 5:(i + 1) * 5]
        tous_ok &= juger(lot, f"répétition {i + 1}/{REPETITIONS} — saut",
                         attend_saut=True)
    negatif_ok = juger(marques[REPETITIONS * 5:],
                       "contrôle négatif — AUCUN saut demandé",
                       attend_saut=False)

    note("verdict de gravité (3 répétitions + contrôle négatif)",
         "PASS" if tous_ok and negatif_ok else "FAIL",
         f"{REPETITIONS}/{REPETITIONS} répétitions conformes"
         if tous_ok else "au moins une répétition hors tolérance")

    (OUT / "constats.json").write_text(
        json.dumps({"archive_sha256": reel_zip,
                    "binaire_sha256": empreinte(build), "seuils": {
            "bruit_max_m": BRUIT_MAX_M, "excursion_min_m": EXCURSION_MIN_M,
            "retour_max_m": RETOUR_MAX_M, "quantum_m": QUANTUM_M},
            "marqueurs": marques, "constats": constats},
            ensure_ascii=False, indent=2), encoding="utf-8")
    for src in racine_user.glob("dev_sessions/*/journal.jsonl"):
        shutil.copy(src, OUT / "journal_devmode.jsonl")

    code = code_sortie()
    comptes = {v: sum(1 for x in constats if x["verdict"] == v) for v in CODES}
    detail = " · ".join(f"{n} {v}" for v, n in comptes.items() if n)
    print(f"\n=== {len(constats)} point(s) : {detail} — code {code} ===",
          flush=True)
    return code


if __name__ == "__main__":
    code = 3
    try:
        code = main()
    finally:
        nettoyer_processus()
    print(f"RC={code}", flush=True)
    sys.exit(code)
