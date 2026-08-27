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


def altitudes(evts: list[dict]) -> list[dict]:
    """Tous les échantillons portant une altitude, marqueurs ET positions
    automatiques, dans l'ordre du temps. Prendre les deux double la densité
    sans rien coûter — et les `position` sont gratuits, eux."""
    lot = [e for e in evts
           if genre(e) in ("marqueur", "position") and "y" in e]
    lot.sort(key=lambda e: float(e.get("t", 0.0)))
    return lot


# --------------------------------------------------------------------------
def juger(evts: list[dict], constats: list[dict], source: str) -> None:
    if not evts:
        note(constats, "journal lisible", "BLOQUÉ",
             f"{source} : aucun événement exploitable")
        return
    note(constats, "journal lisible", "PASS",
         f"{source} : {len(evts)} événement(s)")

    # --- 1. L'HORLOGE D'ABORD, elle décide s'il est licite de juger ---------
    positions = [e for e in evts if genre(e) == "position"]
    horodates = [float(e["t"]) for e in evts if "t" in e]
    mural = (max(horodates) - min(horodates)) if horodates else 0.0
    moteur = len(positions) * SAMPLE_INTERVAL_JEU
    if mural <= 0.0:
        note(constats, "cohérence de l'horloge du moteur", "BLOQUÉ",
             "durée murale nulle ou horodatages absents")
        horloge_ok = False
    else:
        rapport = moteur / mural
        horloge_ok = RAPPORT_MIN <= rapport <= RAPPORT_MAX
        fps = sorted({float(e["fps"]) for e in positions if "fps" in e})
        note(constats, "cohérence de l'horloge du moteur",
             "PASS" if horloge_ok else "BLOQUÉ",
             f"{len(positions)} échantillon(s) automatique(s) = {moteur:.0f} s "
             f"de temps moteur pour {mural:.0f} s de temps mural ; "
             f"rapport={rapport:.3f} (attendu {RAPPORT_MIN}–{RAPPORT_MAX})"
             + (f" ; FPS annoncés {fps}" if fps else "")
             + ("" if horloge_ok else " — voir ISS-072 : aucune inférence "
                "balistique n'est fondée sur une horloge décrochée"))

    # --- 2. Altitudes -------------------------------------------------------
    lot = altitudes(evts)
    if len(lot) < 4:
        note(constats, "échantillons d'altitude", "BLOQUÉ",
             f"{len(lot)} échantillon(s) portant `y`, 4 minimum — le mode "
             f"développement enregistrait-il bien (F3) ?")
        return
    note(constats, "échantillons d'altitude", "PASS",
         f"{len(lot)} échantillon(s) portant `y` et `etat`")

    ys = [float(e["y"]) for e in lot]
    etats = sorted({str(e.get("etat", "?")) for e in lot})
    sol = min(ys)
    haut = max(ys)
    excursion = haut - sol

    # --- 3. État du héros ---------------------------------------------------
    ok_etat = etats == [ETAT_ATTENDU]
    note(constats, "critère 4 — état du contrôleur",
         "PASS" if ok_etat else "FAIL",
         f"états observés {etats} ; attendu uniquement « {ETAT_ATTENDU} » — "
         f"le sujet doit être un héros debout, ni mort, ni blessé, ni en "
         f"escalade")

    # --- 4. Excursion -------------------------------------------------------
    ok_exc = excursion >= EXCURSION_MIN_M
    note(constats, "critère 2 — excursion verticale",
         "PASS" if ok_exc else "FAIL",
         f"sol={sol:.1f} m, sommet={haut:.1f} m, excursion={excursion:.2f} m "
         f"(seuil ≥{EXCURSION_MIN_M}) ; apex nominal {APEX_NOMINAL_M} m")

    # --- 5 & 6. Fronts : montées ACHEVÉES, et hauteur restée en l'air -------
    # Un aller-retour = une montée au-dessus du seuil SUIVIE d'un retour au
    # sol. On compte les FRONTS, pas les échantillons élevés : sinon un seul
    # saut longuement échantillonné compterait pour trois.
    #
    # Le retour au sol se juge sur le DERNIER FRONT, pas sur le dernier
    # échantillon du fichier. C'est un piège mesuré : les `position`
    # automatiques sont émises tout du long, donc le dernier échantillon du
    # journal est souvent une position au sol qui MASQUE un héros resté en
    # l'air. Lire `ys[-1]` rendait alors PASS sur un cas où le héros ne
    # redescend jamais — un faux vert de plus, attrapé par son sabotage.
    seuil = sol + EXCURSION_MIN_M
    plancher = sol + BRUIT_MAX_M
    fronts_ouverts = 0      # montées observées
    fronts_clos = 0         # montées SUIVIES d'un retour au sol
    en_l_air = False
    for y in ys:
        if not en_l_air and y >= seuil:
            en_l_air = True
            fronts_ouverts += 1
        elif en_l_air and y <= plancher:
            en_l_air = False
            fronts_clos += 1

    ok_ret = fronts_ouverts > 0 and fronts_clos == fronts_ouverts
    note(constats, "critère 3 — chaque montée est SUIVIE d'un retour au sol",
         "PASS" if ok_ret else "FAIL",
         f"{fronts_ouverts} montée(s) au-dessus de {seuil:.1f} m, dont "
         f"{fronts_clos} redescendue(s) sous {plancher:.1f} m"
         + ("" if fronts_ouverts else " — aucune montée : rien à faire "
            "retomber, donc rien de prouvé")
         + ("" if ok_ret or not fronts_ouverts
            else f" — {fronts_ouverts - fronts_clos} montée(s) SANS retour : "
                 f"le sol n'a pas arrêté la chute"))

    ok_rep = fronts_clos >= SAUTS_MIN
    note(constats, "critère 5 — répétitions",
         "PASS" if ok_rep else ("PARTIAL" if fronts_clos else "FAIL"),
         f"{fronts_clos} aller(s)-retour(s) COMPLET(s) ; {SAUTS_MIN} demandés")

    # --- 7. Bruit au repos --------------------------------------------------
    # Les échantillons au sol ne doivent pas dériver : sinon le « sol » n'est
    # pas un sol, et le critère 2 mesurerait du bruit.
    au_sol = [y for y in ys if y <= sol + BRUIT_MAX_M]
    bruit = (max(au_sol) - min(au_sol)) if au_sol else 0.0
    note(constats, "critère 1 — bruit au repos",
         "PASS" if bruit <= BRUIT_MAX_M else "FAIL",
         f"{len(au_sol)} échantillon(s) au sol ; dispersion={bruit:.2f} m "
         f"(≤{BRUIT_MAX_M})")

    # --- 8. L'horloge décrochée DÉCLASSE tout jugement temporel -------------
    if not horloge_ok:
        note(constats, "verdict de gravité", "BLOQUÉ",
             "l'horloge du moteur a décroché du temps mural : les critères "
             "ci-dessus sont publiés pour information, mais ni réussite ni "
             "échec de la gravité n'est démontrable à partir d'eux")


# --------------------------------------------------------------------------
def autotest() -> int:
    """Cas synthétiques, sabotages compris. Chaque cas nomme le piège fermé."""
    from lib.verdict import code_sortie

    def piste(ys: list[float], etat: str = ETAT_ATTENDU,
              rapport: float = 1.0) -> list[dict]:
        """Une piste d'altitude COHÉRENTE, telle qu'un vrai journal la porte.

        Les `position` automatiques d'un vrai enregistrement portent `y` comme
        les marqueurs : les fixtures doivent en faire autant, sinon elles
        testent un journal qui n'existe pas. `rapport` règle le décrochage
        d'horloge — 1,0 = saine, 0,013 = celui mesuré en S1.1."""
        n = len(ys)
        mural = n / rapport if rapport else n * 1000.0
        return [{"type": "position", "t": mural * i / max(n - 1, 1),
                 "y": y, "etat": etat, "fps": 60.0}
                for i, y in enumerate(ys)]

    SOL, HAUT = 24.0, 25.4
    saut = [SOL, HAUT, SOL]

    cas: list[tuple[str, list[dict], int]] = [
        ("trois sauts nets, horloge saine",
         piste([SOL] + saut * 3 + [SOL]), 0),

        ("SABOTAGE — journal VIDE : ne rien lire n'est pas réussir", [], 3),

        ("SABOTAGE — horloge décrochée : BLOQUÉ, jamais FAIL",
         piste([SOL] + saut * 3 + [SOL], rapport=0.013), 3),

        ("SABOTAGE — AUCUN saut : excursion nulle, donc FAIL",
         piste([SOL] * 10), 1),

        ("SABOTAGE — le héros monte et NE REDESCEND PAS : critère 3 FAIL",
         piste([SOL, SOL, HAUT, HAUT, HAUT, HAUT, HAUT]), 1),

        ("SABOTAGE — DEUX sauts finissent, le troisième reste en l'air",
         piste([SOL] + saut * 2 + [SOL, HAUT, HAUT, HAUT]), 1),

        ("SABOTAGE — un SEUL saut au lieu de trois : PARTIAL, pas PASS",
         piste([SOL] + saut + [SOL, SOL]), 1),

        ("SABOTAGE — héros MORT pendant l'enregistrement : critère 4 FAIL",
         piste([SOL] + saut * 3 + [SOL], etat="mort"), 1),

        ("SABOTAGE — trop peu d'échantillons pour conclure",
         piste([SOL, HAUT, SOL]), 3),

        ("SABOTAGE — excursion SOUS le seuil (0,3 m) : ne doit pas passer",
         piste([SOL, 24.3, SOL, 24.3, SOL, 24.3, SOL, SOL]), 1),

        ("SABOTAGE — le « sol » DÉRIVE de 0,8 m : ce n'est pas un sol",
         piste([24.0, 24.4, 24.8, 24.4, 24.0, 24.4, 24.8]), 1),
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
        "cohérence de l'horloge": "horloge",
        "excursion verticale": "excursion",
        "retour au sol": "retour au sol",
    })


if __name__ == "__main__":
    sys.exit(main())
