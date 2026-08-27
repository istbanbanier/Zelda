#!/usr/bin/env python3
"""ANALYSEUR HORS LIGNE d'un journal DevMode — juge la gravité sans le jeu.

À QUOI CET OUTIL SERT. Le conteneur de développement ne peut pas mesurer la
gravité : son horloge moteur est décrochée du temps mural d'un facteur 17 à 76
(ISS-072, mesuré deux fois, avec ET sans capture d'écran). La mesure appartient
donc à une VRAIE machine. Cet outil est le pont : il lit le journal que le mode
développement écrit tout seul, et rend un verdict contre les seuils
PRÉENREGISTRÉS de `docs/contrats/s1_1_gravite.md`.

CE QU'IL LIT. `user://dev_sessions/<horodatage>/journal.jsonl`, une ligne JSON
par événement, produit par `scripts/tools/dev_mode.gd` :

  - `marqueur`  — posé par F4, porte `y` (altitude du héros) et `etat`
  - `position`  — automatique, une par seconde de temps MOTEUR, même charge
  - `saccade`   — image au-delà de 100 ms

Les deux premiers portent `_player_snapshot()`, donc l'altitude RÉELLE du corps
du joueur. Aucun pixel n'entre dans le verdict : l'exigence « exclure les
fleurs et autres zones animées » est satisfaite PAR CONSTRUCTION, pas par
recadrage — et il faut le dire ainsi.

CE QU'IL VÉRIFIE D'ABORD, ET QUI PEUT TOUT ARRÊTER. La cohérence de l'horloge :
le nombre d'événements `position` mesure le temps que le moteur croit avoir
vécu ; le champ `t` mesure le temps mural. S'ils divergent, aucune inférence
balistique n'est fondée, et le verdict est BLOQUÉ — jamais FAIL. Un FAIL
imputerait au JEU un défaut de l'APPAREIL.

Codes : 0 = PASS · 1 = PARTIAL/FAIL · 3 = BLOQUÉ / NON VÉRIFIÉ / vide.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lib.verdict import note, publier_verdict  # noqa: E402

# --- SEUILS PRÉENREGISTRÉS — docs/contrats/s1_1_gravite.md ------------------
# Recopiés, jamais redérivés. Les toucher ici serait déplacer un seuil pour
# obtenir un vert, ce que le dépôt interdit.
QUANTUM_M = 0.1          # snappedf(y, 0.1) dans dev_mode.gd
BRUIT_MAX_M = 0.10       # 1 quantum : un héros immobile ne dérive pas
EXCURSION_MIN_M = 0.50   # 5 quanta ; 2,8x sous l'apex nominal de 1,401 m
RETOUR_MAX_M = 0.20      # 2 quanta
ETAT_ATTENDU = "locomotion"
SAUTS_MIN = 3            # trois répétitions
REPOS_INITIAL = 3        # marqueurs au repos AVANT le premier saut,
#                          dont la MÉDIANE donne le sol de référence
# Apex nominal, dérivé de resources/tuning/locomotion_default.tres :
#   jump_velocity = 8.2 ; gravity = 24.0 ; apex = v^2/2g
APEX_NOMINAL_M = 1.401
# Bande de cohérence temps moteur / temps mural. Large à dessein : on ne
# mesure pas la fluidité, on détecte qu'une horloge a décroché de l'autre.
RAPPORT_MIN, RAPPORT_MAX = 0.5, 2.0
SAMPLE_INTERVAL_JEU = 1.0   # SAMPLE_INTERVAL dans dev_mode.gd


def lire(chemin: Path) -> list[dict]:
    """Événements du journal, tolérant aux lignes tronquées (un enregistrement
    interrompu par une fermeture brutale se termine souvent par une ligne
    partielle : la jeter vaut mieux que refuser tout le fichier)."""
    evts: list[dict] = []
    for ligne in chemin.read_text(encoding="utf-8",
                                  errors="replace").splitlines():
        ligne = ligne.strip()
        if not ligne:
            continue
        try:
            obj = json.loads(ligne)
        except json.JSONDecodeError:
            continue
        if isinstance(obj, dict):
            evts.append(obj.get("data", obj) if "data" in obj
                        and isinstance(obj.get("data"), dict)
                        and "type" not in obj.get("data", {}) else obj)
    return evts


def genre(e: dict) -> str:
    return str(e.get("kind", e.get("type", "")))


def marqueurs(evts: list[dict]) -> list[dict]:
    """Les marqueurs F4 SEULS, dans l'ordre de `numero`.

    POURQUOI PAS LES `position` AUTOMATIQUES. Ils tombent toutes les secondes
    de temps moteur, et le vol nominal dure **0,683 s** — ils ratent donc les
    sauts la plupart du temps, et rien ne signale qu'ils les ont ratés. Un
    verdict tiré d'eux serait un tirage au sort. Les marqueurs, eux, sont
    posés DÉLIBÉRÉMENT aux instants qui comptent : c'est le protocole qui les
    place, pas le hasard d'un échantillonneur."""
    lot = [e for e in evts if genre(e) == "marqueur" and "y" in e]
    lot.sort(key=lambda e: int(e.get("numero", 0)))
    return lot


def mediane(valeurs: list[float]) -> float:
    """Médiane — jamais le minimum.

    Le minimum global est un piège : si le héros tombe une fois sous son
    niveau de départ, ce creux devient le « sol » et toutes les altitudes se
    mesurent depuis un plancher qui n'existe pas. Un saut de 1,4 m au-dessus
    d'un sol à 24 m paraîtrait alors une excursion de 5,4 m au-dessus d'un
    faux sol à 20 m — et le retour au sol, lui, paraîtrait raté. La médiane
    de trois relevés au repos ne bouge pas pour un accident."""
    t = sorted(valeurs)
    n = len(t)
    if n == 0:
        return 0.0
    return t[n // 2] if n % 2 else (t[n // 2 - 1] + t[n // 2]) / 2.0


# --------------------------------------------------------------------------
def juger_horloge(evts: list[dict], constats: list[dict]) -> bool:
    """GATE SÉPARÉ. Elle ne juge pas la gravité : elle dit si le temps du
    moteur ressemble au temps réel. Une horloge décrochée n'invalide pas les
    marqueurs — ils sont posés à la main, aux bons instants du JEU — mais elle
    reste publiée, parce qu'elle change ce qu'on peut conclure d'un délai."""
    positions = [e for e in evts if genre(e) == "position"]
    horodates = [float(e["t"]) for e in evts if "t" in e]
    if not horodates:
        note(constats, "horloge du moteur (gate séparé)", "BLOQUÉ",
             "aucun horodatage")
        return False
    mural = max(horodates) - min(horodates)
    moteur = len(positions) * SAMPLE_INTERVAL_JEU
    if mural <= 0.0:
        note(constats, "horloge du moteur (gate séparé)", "BLOQUÉ",
             "durée murale nulle")
        return False
    rapport = moteur / mural
    ok = RAPPORT_MIN <= rapport <= RAPPORT_MAX
    fps = sorted({float(e["fps"]) for e in positions if "fps" in e})
    note(constats, "horloge du moteur (gate séparé)",
         "PASS" if ok else "PARTIAL",
         f"{len(positions)} échantillon(s) automatique(s) = {moteur:.0f} s "
         f"moteur pour {mural:.0f} s mural ; rapport={rapport:.3f} "
         f"(attendu {RAPPORT_MIN}–{RAPPORT_MAX})"
         + (f" ; FPS {fps}" if fps else "")
         + ("" if ok else " — machine lente ou horloge décrochée (ISS-072). "
            "Les marqueurs restent jugeables : ils sont posés à la main aux "
            "instants du JEU, pas par un échantillonneur"))
    return ok


def juger(evts: list[dict], constats: list[dict], source: str) -> None:
    if not evts:
        note(constats, "journal lisible", "BLOQUÉ",
             f"{source} : aucun événement exploitable")
        return
    note(constats, "journal lisible", "PASS",
         f"{source} : {len(evts)} événement(s)")

    juger_horloge(evts, constats)

    # --- Les marqueurs, et le protocole qu'ils doivent suivre --------------
    m = marqueurs(evts)
    attendus = REPOS_INITIAL + 2 * SAUTS_MIN
    if len(m) < attendus:
        note(constats, "protocole de marqueurs suivi", "BLOQUÉ",
             f"{len(m)} marqueur(s) F4 pour {attendus} attendus "
             f"({REPOS_INITIAL} au repos, puis {SAUTS_MIN} paires "
             f"montée/sol) — la séquence de docs/PROTOCOLE_SAUT_ISTVAN.md "
             f"n'a pas été jouée en entier, rien n'est jugeable")
        return
    note(constats, "protocole de marqueurs suivi", "PASS",
         f"{len(m)} marqueur(s) F4 ; {attendus} exigés")

    # --- Le SOL : médiane des trois premiers, jamais un minimum -----------
    repos = m[:REPOS_INITIAL]
    ys_repos = [float(e["y"]) for e in repos]
    sol = mediane(ys_repos)
    plus_bas = min(float(e["y"]) for e in m)
    note(constats, "sol de référence", "PASS",
         f"médiane des {REPOS_INITIAL} marqueurs de repos = {sol:.2f} m "
         f"(relevés {[round(y, 2) for y in ys_repos]})"
         + (f" ; le point le plus bas du journal est {plus_bas:.2f} m et "
            f"n'est PAS pris pour sol" if plus_bas < sol - QUANTUM_M else ""))

    # --- Critère 1 — bruit au repos ---------------------------------------
    bruit = max(ys_repos) - min(ys_repos)
    note(constats, "critère 1 — bruit au repos",
         "PASS" if bruit <= BRUIT_MAX_M else "FAIL",
         f"dispersion des {REPOS_INITIAL} relevés = {bruit:.2f} m "
         f"(≤{BRUIT_MAX_M})")

    # --- Critère 4 — état du héros ----------------------------------------
    etats = sorted({str(e.get("etat", "?")) for e in m})
    note(constats, "critère 4 — état du contrôleur",
         "PASS" if etats == [ETAT_ATTENDU] else "FAIL",
         f"états sur les marqueurs : {etats} ; attendu « {ETAT_ATTENDU} »")

    # --- Les trois sauts, par PAIRES (montée, sol) -------------------------
    reussis = 0
    for i in range(SAUTS_MIN):
        haut = m[REPOS_INITIAL + 2 * i]
        bas = m[REPOS_INITIAL + 2 * i + 1]
        yh, yb = float(haut["y"]), float(bas["y"])
        exc = yh - sol
        ret = abs(yb - sol)
        ok_h = exc >= EXCURSION_MIN_M
        ok_b = ret <= RETOUR_MAX_M
        if ok_h and ok_b:
            reussis += 1
        note(constats, f"saut {i + 1}/{SAUTS_MIN}",
             "PASS" if (ok_h and ok_b) else "FAIL",
             f"montée Y={yh:.2f} m soit +{exc:.2f} "
             f"({'≥' if ok_h else '<'} {EXCURSION_MIN_M} exigé) ; "
             f"retour Y={yb:.2f} m soit écart {ret:.2f} "
             f"({'≤' if ok_b else '>'} {RETOUR_MAX_M} toléré)")

    note(constats, f"critère 5 — {SAUTS_MIN} sauts complets",
         "PASS" if reussis >= SAUTS_MIN else
         ("PARTIAL" if reussis else "FAIL"),
         f"{reussis}/{SAUTS_MIN} saut(s) conformes ; apex nominal "
         f"{APEX_NOMINAL_M} m d'après le tuning committé")

    note(constats, "verdict de gravité",
         "PASS" if reussis >= SAUTS_MIN else "FAIL",
         "les trois sauts montent puis retombent au sol de référence"
         if reussis >= SAUTS_MIN else
         f"{SAUTS_MIN - reussis} saut(s) hors tolérance")


def autotest() -> int:
    """Cas synthétiques et SABOTAGES. Chaque cas nomme le piège qu'il ferme.
    Un cas qui ne rougirait pas sans le correctif ne serait pas un test."""
    from lib.verdict import code_sortie

    SOL, HAUT = 24.0, 25.4
    n = [0]

    def mq(y: float, etat: str = ETAT_ATTENDU, t: float | None = None) -> dict:
        n[0] += 1
        return {"type": "marqueur", "numero": n[0], "y": y, "etat": etat,
                "t": float(n[0]) if t is None else t}

    def pos(ys: list[float], mural: float) -> list[dict]:
        """Échantillons automatiques — ils servent l'horloge, PAS le verdict."""
        k = len(ys)
        return [{"type": "position", "t": mural * i / max(k - 1, 1), "y": y,
                 "etat": ETAT_ATTENDU, "fps": 60.0} for i, y in enumerate(ys)]

    def sequence(sauts: list[tuple[float, float]],
                 repos: list[float] | None = None,
                 etat: str = ETAT_ATTENDU,
                 auto: list[float] | None = None,
                 mural: float = 30.0) -> list[dict]:
        """Le protocole complet : trois repos, puis (montée, sol) par saut."""
        n[0] = 0
        r = repos if repos is not None else [SOL] * REPOS_INITIAL
        evts = [mq(y, etat) for y in r]
        for h, b in sauts:
            evts.append(mq(h, etat))
            evts.append(mq(b, etat))
        evts += pos(auto if auto is not None else [SOL] * int(mural), mural)
        return evts

    TROIS = [(HAUT, SOL)] * 3

    cas: list[tuple[str, list[dict], int]] = [
        ("protocole complet, trois sauts nets", sequence(TROIS), 0),

        ("SABOTAGE — journal VIDE : ne rien lire n'est pas réussir", [], 3),

        ("SABOTAGE — les échantillons AUTOMATIQUES à 1 Hz ratent les trois "
         "sauts, mais les marqueurs les portent : le verdict doit rester VERT",
         sequence(TROIS, auto=[SOL] * 30), 0),

        ("SABOTAGE — le héros TOMBE sous son niveau initial : ce creux ne "
         "doit PAS devenir le sol",
         sequence([(HAUT, SOL), (HAUT, 20.0), (HAUT, SOL)]), 1),

        ("SABOTAGE — protocole INCOMPLET : deux sauts au lieu de trois",
         sequence([(HAUT, SOL), (HAUT, SOL)]), 3),

        ("SABOTAGE — aucun marqueur du tout, seulement l'automatique",
         pos([SOL, HAUT, SOL] * 10, 30.0), 3),

        ("SABOTAGE — AUCUN saut : les trois « montées » restent au sol",
         sequence([(SOL, SOL)] * 3), 1),

        ("SABOTAGE — le héros monte et NE REDESCEND PAS",
         sequence([(HAUT, HAUT)] * 3), 1),

        ("SABOTAGE — montée SOUS le seuil (0,3 m au lieu de 0,5)",
         sequence([(24.3, SOL)] * 3), 1),

        ("SABOTAGE — héros MORT pendant l'enregistrement",
         sequence(TROIS, etat="mort"), 1),

        ("SABOTAGE — le sol de repos DÉRIVE de 0,8 m : ce n'est pas un sol",
         sequence(TROIS, repos=[24.0, 24.4, 24.8]), 1),

        # Ce cas-ci est LE contrôle décisif entre médiane et minimum, et il
        # est construit pour que les deux lectures DIVERGENT en couleur.
        # Le héros ne saute JAMAIS : il oscille de 0,6 m entre 24,0 et 23,4.
        #   - sol = MINIMUM global 23,4 -> chaque « montée » à 24,0 vaut
        #     +0,6 m, donc ≥ 0,50 : les trois excursions passent ; chaque
        #     « retour » à 23,4 donne un écart nul : les trois retours
        #     passent. Verdict PASS. L'appareil déclarerait trois beaux
        #     sauts là où le héros n'a pas quitté le sol une seule fois.
        #   - sol = MÉDIANE des trois repos = 24,0 -> excursion 0,00 m,
        #     donc FAIL. Correct.
        ("SABOTAGE DÉCISIF — héros qui n'a JAMAIS sauté mais qui oscille de "
         "0,6 m : le minimum global le déclarerait vert, la médiane le "
         "refuse",
         sequence([(24.0, 23.4)] * 3), 1),

        ("un repos aberrant (24,0 / 24,0 / 20,0) ne déplace pas la médiane, "
         "mais le bruit au repos le signale — rouge par le BON critère",
         sequence(TROIS, repos=[24.0, 24.0, 20.0]), 1),

        ("horloge décrochée mais marqueurs bons : PARTIAL sur l'horloge, "
         "la gravité reste jugeable",
         sequence(TROIS, auto=[SOL, SOL], mural=150.0), 1),
    ]

    echecs = 0
    for titre, evts, attendu in cas:
        constats: list[dict] = []
        juger(evts, constats, "autotest")
        obtenu = code_sortie(constats)
        ok = obtenu == attendu
        echecs += 0 if ok else 1
        print(f"[{'OK  ' if ok else 'ÉCHEC'}] {titre} -> code {obtenu} "
              f"(attendu {attendu})", flush=True)

    print(f"\n=== AUTOTEST analyse_journal_devmode : {echecs} échec(s) ===",
          flush=True)
    return 1 if echecs else 0


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(
        description="Juge la gravité depuis un journal DevMode, hors ligne.")
    p.add_argument("journal", nargs="?", type=Path,
                   help="chemin d'un journal.jsonl, ou d'un dossier de session")
    p.add_argument("--autotest", action="store_true",
                   help="cas synthétiques et sabotages, sans aucun fichier")
    a = p.parse_args(argv)

    if a.autotest:
        return autotest()
    if a.journal is None:
        p.error("indiquer un journal, ou --autotest")

    chemin = a.journal
    if chemin.is_dir():
        trouves = sorted(chemin.rglob("journal.jsonl"))
        if not trouves:
            print(f"BLOQUÉ: aucun journal.jsonl sous {chemin}", flush=True)
            return 3
        chemin = trouves[-1]
    if not chemin.exists():
        print(f"BLOQUÉ: {chemin} absent", flush=True)
        return 3

    constats: list[dict] = []
    juger(lire(chemin), constats, str(chemin))
    return publier_verdict(constats, {
        "horloge du moteur": "horloge",
        "protocole de marqueurs": "protocole de marqueurs",
        "sol de référence": "sol de référence",
        "verdict de gravité": "verdict de gravité",
    })


if __name__ == "__main__":
    sys.exit(main())
