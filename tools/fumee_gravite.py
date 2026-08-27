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
# AMENDEMENT 2 : échantillonnage par battement. L'appareil ne peut pas placer
# un marqueur à un instant CHOISI du vol (cadence mesurée 1,03 s contre
# 0,683 s de vol) ; on échantillonne donc BEAUCOUP, à une période
# incommensurable avec celle des sauts. Fraction de vol attendue :
# 0,683 / 1,5 = 45,5 % ; seuil posé à 25 %, très au-dessus de zéro.
T_SAUT_S = 1.5
MARQUEURS_PAR_CAMPAGNE = 26
FRACTION_ELEVEE_MIN = 0.25

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


def campagne(saut: bool, sol: float | None = None) -> None:
    """Campagne de battement. `saut=False` = contrôle négatif.

    Deux fils de commande qui ne se synchronisent pas : les `Espace` toutes
    les T_SAUT_S, les `F4` aussi vite que l'appareil les accepte (~1,03 s
    mesurées). Les deux périodes dérivent, donc les marqueurs échantillonnent
    la phase de vol proportionnellement à sa durée."""
    fin = time.time() + MARQUEURS_PAR_CAMPAGNE * 1.10
    prochain_saut = time.time()
    poses = 0
    while poses < MARQUEURS_PAR_CAMPAGNE and time.time() < fin + 20:
        if saut and time.time() >= prochain_saut:
            xdo("key", "space")
            prochain_saut = time.time() + T_SAUT_S
        xdo("key", "F4")
        poses += 1
        time.sleep(0.05)


def repos(n: int) -> None:
    """`n` marqueurs sans AUCUNE entrée : mesure du bruit de l'appareil."""
    for _ in range(n):
        xdo("key", "F4")
        time.sleep(0.05)


def juger_repos(lot: list[dict], titre: str) -> tuple[bool, float]:
    """Critères 1 et 4 : bruit au repos, et état du héros. Rend (ok, Y_sol)."""
    if len(lot) < 2:
        note(titre, "BLOQUÉ", f"{len(lot)} marqueur(s) au repos, 2 minimum")
        return False, 0.0
    ys = [float(m["y"]) for m in lot]
    etats = [str(m.get("etat", "?")) for m in lot]
    bruit = max(ys) - min(ys)
    sol = min(ys)
    etat_ok = all(e == ETAT_ATTENDU for e in etats)
    ok = bruit <= BRUIT_MAX_M and etat_ok
    note(titre, "PASS" if ok else "FAIL",
         f"{len(lot)} marqueur(s) sans entrée ; Y de {min(ys):.1f} à "
         f"{max(ys):.1f} m ; bruit={bruit:.1f} (≤{BRUIT_MAX_M}) ; "
         f"états={sorted(set(etats))}")
    return ok, sol


def juger_campagne(lot: list[dict], sol: float, titre: str,
                   attend_saut: bool) -> bool:
    """Critères 2a/2b : fraction de marqueurs au-dessus du sol."""
    if len(lot) < MARQUEURS_PAR_CAMPAGNE * 0.7:
        note(titre, "BLOQUÉ",
             f"{len(lot)} marqueur(s), moins de 70 % des "
             f"{MARQUEURS_PAR_CAMPAGNE} demandés — campagne incomplète")
        return False
    ys = [float(m["y"]) for m in lot]
    eleves = [y for y in ys if (y - sol) >= EXCURSION_MIN_M]
    fraction = len(eleves) / len(ys)
    hauteur_max = max(ys) - sol
    if attend_saut:
        ok = fraction >= FRACTION_ELEVEE_MIN
    else:
        ok = len(eleves) == 0
    note(titre, "PASS" if ok else "FAIL",
         f"{len(eleves)}/{len(ys)} marqueur(s) à ≥{EXCURSION_MIN_M} m "
         f"au-dessus du sol ({fraction:.0%}"
         + (f", seuil ≥{FRACTION_ELEVEE_MIN:.0%}" if attend_saut
            else ", exigé EXACTEMENT 0")
         + f") ; excursion max={hauteur_max:.1f} m ; Y sol={sol:.1f} m")
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
        repos(4)                           # bruit, aucune entrée
        for _ in range(REPETITIONS):
            campagne(saut=True)
            time.sleep(3.0)                # retour au sol entre campagnes
            repos(2)                       # retour au sol, critère 3
        campagne(saut=False)               # contrôle négatif, en dernier
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

    # Découpage : 4 repos, puis (campagne + 2 repos) x REPETITIONS, puis la
    # campagne négative. On tranche sur les COMPTES demandés, jamais sur une
    # heuristique de valeurs — sinon le découpage lirait sa réponse chez le
    # sujet.
    i = 0
    repos_initial = marques[i:i + 4]
    i += 4
    repos_ok, sol = juger_repos(repos_initial,
                                "critère 1 — bruit au repos, aucune entrée")
    tous_ok = repos_ok
    for r in range(REPETITIONS):
        lot = marques[i:i + MARQUEURS_PAR_CAMPAGNE]
        i += MARQUEURS_PAR_CAMPAGNE
        tous_ok &= juger_campagne(
            lot, sol, f"critère 2a — campagne {r + 1}/{REPETITIONS} : sauts "
            "répétés, échantillonnage par battement", attend_saut=True)
        apres_lot = marques[i:i + 2]
        i += 2
        if len(apres_lot) == 2:
            retour = abs(float(apres_lot[-1]["y"]) - sol)
            ok_r = retour <= RETOUR_MAX_M
            tous_ok &= ok_r
            note(f"critère 3 — retour au sol après la campagne {r + 1}",
                 "PASS" if ok_r else "FAIL",
                 f"Y={float(apres_lot[-1]['y']):.1f} m contre sol {sol:.1f} m "
                 f"; écart={retour:.1f} (≤{RETOUR_MAX_M})")
        else:
            note(f"critère 3 — retour au sol après la campagne {r + 1}",
                 "BLOQUÉ", "marqueurs de repos manquants")
            tous_ok = False
    negatif_ok = juger_campagne(
        marques[i:i + MARQUEURS_PAR_CAMPAGNE], sol,
        "critère 2b — contrôle négatif : AUCUN saut demandé",
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
