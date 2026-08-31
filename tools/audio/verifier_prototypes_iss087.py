#!/usr/bin/env python3
"""Vérification MESURÉE des huit prototypes d'ambiance — ISS-087.

Rejoue, chiffre à chiffre, les bornes arbitrées pour le lot des prototypes
(`docs/audio/PROTOTYPES_AMBIANCE.md`, arbitrages du lead) :

  1. Format : 22 050 Hz natif, mono, 16 bits, durées EXACTES en trames.
     (Le « rien au-dessus de 11 025 Hz » des lits est structurel : c'est le
     Nyquist d'un fichier à 22 050 Hz — vérifier le taux suffit.)
  2. RMS des QUATRE lits : égaux à ±0,5 dB entre eux (écart max ≤ 0,5 dB) et
     chacun ≤ −27 dBFS.
  3. Marge anti-masquage ≥ 11 dB : chaque lit sous le RMS de la banque SFX
     existante, RE-MESURÉE ici (moyenne énergétique des RMS par fichier des
     sons courts, `amb_*` exclus — ce sont les ambiances qu'on remplace).
  4. Crête des événements ≤ crête minimale des lits +3 dB, et ≤ 0,85.
  5. Raccord de boucle des lits : |delta| au raccord ≤ p95 des deltas internes.
  6. Stabilité RMS des lits par fenêtre de 0,5 s (pas 0,25 s) : écart ≤ 6 dB.
  7. Spectre, par l'instrument VALIDÉ `band_profile.py` (six cas de théorie
     connue) : lits ≥ 60 % de l'énergie dans 707-2 828 Hz (octaves 1k + 2k)
     et ≤ 8 % dans 125-500 Hz ; événements ≤ 10 % dans 125-500 Hz.
     Les seuils 60/8/10 sont l'ENCODAGE de « énergie dans la bande creuse,
     creux délibéré en 125-500 » — posés ici, datés du 2026-08-31.
  8. Coût QOA exact par fichier (modèle `qoa_cost.py`, 0 octet d'écart vérifié
     sur `amb_valley`) : publié, et les totaux par prototype épinglés aux
     budgets du document (267 728 / 267 744 / 267 808 octets).

Codes retour (convention `tools/CLAUDE.md`) :
    0  huit fichiers mesurés, toutes les bornes tiennent
    1  ÉCHEC — première borne violée (le tableau complet est publié avant)
    3  BLOQUÉ — un fichier attendu manque ou ne se lit pas

Usage :
    python3 tools/audio/verifier_prototypes_iss087.py
    python3 tools/audio/verifier_prototypes_iss087.py --sortie <dossier>
"""
from __future__ import annotations

import argparse
import glob
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import band_profile  # noqa: E402 — l'instrument validé du dépôt
from qoa_cost import taille_qoa  # noqa: E402 — le modèle de coût exact

RACINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
SFX = os.path.join(RACINE, "assets", "audio", "sfx")

RATE_ATTENDU = 22050
LITS = {
    "amb_p1_lit": 30.0,
    "amb_p2_ouvert": 15.0,
    "amb_p2_ferme": 15.0,
    "amb_p3_lit": 20.0,
}
EVENEMENTS = {"amb_evt_%d" % i: 2.5 for i in range(1, 5)}

RMS_LIT_MAX_DBFS = -27.0
ECART_LITS_MAX_DB = 0.5
MARGE_MASQUAGE_DB = 11.0
CRETE_EVT_MAX = 0.85
CRETE_EVT_SUR_LIT_DB = 3.0
STABILITE_MAX_DB = 6.0
FENETRE_S = 0.5
PAS_S = 0.25
BANDE_CREUSE_MIN_PCT = 60.0
MASQUAGE_LIT_MAX_PCT = 8.0
MASQUAGE_EVT_MAX_PCT = 10.0
## Budgets du document (§1 de PROTOTYPES_AMBIANCE.md), en octets QOA.
BUDGETS_PROTO = {"P1": 267728, "P2": 267744, "P3": 267808}


def dbfs(v: float) -> float:
    return 20.0 * math.log10(v) if v > 0.0 else -140.0


def rms(x: list[float]) -> float:
    return math.sqrt(sum(v * v for v in x) / len(x))


def p95(valeurs: list[float]) -> float:
    tri = sorted(valeurs)
    return tri[min(len(tri) - 1, int(math.ceil(0.95 * len(tri))) - 1)]


def stabilite_fenetres_db(x: list[float], rate: int) -> float:
    fen = int(FENETRE_S * rate)
    pas = int(PAS_S * rate)
    vals = []
    for debut in range(0, len(x) - fen + 1, pas):
        seg = x[debut:debut + fen]
        vals.append(dbfs(rms(seg)))
    return max(vals) - min(vals)


def reference_banque() -> tuple[float, list[tuple[str, float]]]:
    """RMS de la banque courte existante : moyenne ÉNERGÉTIQUE des RMS par
    fichier, `amb_*` exclus (les ambiances ne sont pas ce que la marge doit
    protéger — ce sont les actions qu'un lit ne doit pas masquer)."""
    lignes = []
    for chemin in sorted(glob.glob(os.path.join(SFX, "*.wav"))):
        nom = os.path.basename(chemin)[:-4]
        if nom.startswith("amb_"):
            continue
        ech, _rate = band_profile.lire_wav(chemin)
        lignes.append((nom, dbfs(rms(ech))))
    if not lignes:
        raise RuntimeError("aucun son court mesurable dans %s" % SFX)
    moyenne = 10.0 * math.log10(
        sum(10.0 ** (d / 10.0) for _n, d in lignes) / len(lignes))
    return moyenne, lignes


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--sortie", default=None,
                    help="dossier où publier mesures_prototypes.csv/.md")
    a = ap.parse_args(argv)

    try:
        ref_db, banque = reference_banque()
    except Exception as exc:  # noqa: BLE001
        print("BLOQUÉ : banque SFX illisible — %s" % exc, file=sys.stderr)
        return 3

    mesures: dict[str, dict] = {}
    for nom, duree in {**LITS, **EVENEMENTS}.items():
        chemin = os.path.join(SFX, nom + ".wav")
        if not os.path.isfile(chemin):
            print("BLOQUÉ : %s absent — générer d'abord "
                  "(generer_prototypes_iss087.py)" % chemin, file=sys.stderr)
            return 3
        try:
            ech, rate = band_profile.lire_wav(chemin)
            p = band_profile.profil(ech, rate)
        except Exception as exc:  # noqa: BLE001
            print("BLOQUÉ : %s illisible — %s" % (nom, exc), file=sys.stderr)
            return 3
        part = dict(zip([b[0] for b in p["bandes"]], p["fractions"]))
        deltas = [abs(ech[i + 1] - ech[i]) for i in range(len(ech) - 1)]
        m = {
            "role": "lit" if nom in LITS else "evenement",
            "duree_attendue_s": duree,
            "trames": len(ech),
            "rate": rate,
            "rms_dbfs": dbfs(p["rms"]),
            "crete": p["crete"],
            "crete_dbfs": dbfs(p["crete"]),
            "delta_raccord": abs(ech[0] - ech[-1]),
            "p95_deltas": p95(deltas),
            "stabilite_db": stabilite_fenetres_db(ech, rate),
            "creuse_pct": part.get("1k", 0.0) + part.get("2k", 0.0),
            "masquage_pct": p["masquage"],
            "qoa_octets": taille_qoa(len(ech), 1),
        }
        mesures[nom] = m

    # ------------------------------------------------------------------ table
    entetes = ("fichier,role,trames,rate,rms_dbfs,crete,crete_dbfs,"
               "delta_raccord,p95_deltas,stabilite_fenetre_db,"
               "frac_707_2828_pct,frac_125_500_pct,qoa_octets")
    lignes_csv = [entetes]
    print("%-16s %-9s %8s %9s %7s %9s %9s %8s %8s %8s" % (
        "fichier", "rôle", "trames", "rms dBFS", "crête",
        "d_raccord", "p95_delta", "stab dB", "creuse%", "125-500%"))
    for nom in list(LITS) + list(EVENEMENTS):
        m = mesures[nom]
        print("%-16s %-9s %8d %9.2f %7.4f %9.6f %9.6f %8.2f %8.1f %8.2f" % (
            nom, m["role"], m["trames"], m["rms_dbfs"], m["crete"],
            m["delta_raccord"], m["p95_deltas"], m["stabilite_db"],
            m["creuse_pct"], m["masquage_pct"]))
        lignes_csv.append(
            "%s,%s,%d,%d,%.3f,%.5f,%.3f,%.7f,%.7f,%.3f,%.2f,%.2f,%d" % (
                nom, m["role"], m["trames"], m["rate"], m["rms_dbfs"],
                m["crete"], m["crete_dbfs"], m["delta_raccord"],
                m["p95_deltas"], m["stabilite_db"], m["creuse_pct"],
                m["masquage_pct"], m["qoa_octets"]))
    print("référence banque courte (%d fichiers, moyenne énergétique) : "
          "%.2f dBFS" % (len(banque), ref_db))
    couts = {
        "P1": mesures["amb_p1_lit"]["qoa_octets"],
        "P2": mesures["amb_p2_ouvert"]["qoa_octets"]
        + mesures["amb_p2_ferme"]["qoa_octets"],
        "P3": mesures["amb_p3_lit"]["qoa_octets"]
        + sum(mesures[n]["qoa_octets"] for n in EVENEMENTS),
    }
    for proto, octets in couts.items():
        print("coût QOA %s : %d octets (budget du document : %d)"
              % (proto, octets, BUDGETS_PROTO[proto]))

    # ------------------------------------------------------------- publication
    if a.sortie:
        os.makedirs(a.sortie, exist_ok=True)
        with open(os.path.join(a.sortie, "mesures_prototypes.csv"), "w",
                  encoding="utf-8") as f:
            f.write("\n".join(lignes_csv) + "\n")
        with open(os.path.join(a.sortie, "mesures_prototypes.md"), "w",
                  encoding="utf-8") as f:
            f.write("# Mesures des prototypes d'ambiance — ISS-087\n\n")
            f.write("Vérificateur : `tools/audio/verifier_prototypes_iss087.py`"
                    " (instrument spectral : `band_profile.py`, validé sur six"
                    " réponses théoriques).\n\n")
            f.write("Référence banque courte (%d sons, moyenne énergétique des"
                    " RMS, `amb_*` exclus) : **%.2f dBFS**. Marge exigée :"
                    " ≥ %.0f dB.\n\n" % (len(banque), ref_db, MARGE_MASQUAGE_DB))
            f.write("| fichier | rôle | trames | RMS dBFS | crête | raccord |"
                    " p95 deltas | stab. dB | 707-2 828 % | 125-500 % |"
                    " QOA o |\n|---|---|--:|--:|--:|--:|--:|--:|--:|--:|--:|\n")
            for nom in list(LITS) + list(EVENEMENTS):
                m = mesures[nom]
                f.write("| %s | %s | %d | %.2f | %.4f | %.6f | %.6f | %.2f |"
                        " %.1f | %.2f | %d |\n" % (
                            nom, m["role"], m["trames"], m["rms_dbfs"],
                            m["crete"], m["delta_raccord"], m["p95_deltas"],
                            m["stabilite_db"], m["creuse_pct"],
                            m["masquage_pct"], m["qoa_octets"]))
            f.write("\nCoûts QOA par prototype : %s.\n"
                    % ", ".join("%s = %d o (budget %d)"
                                % (p, couts[p], BUDGETS_PROTO[p])
                                for p in ("P1", "P2", "P3")))
            f.write("\nRMS par fichier de la banque courte :\n\n")
            for n, d in banque:
                f.write("- %s : %.2f dBFS\n" % (n, d))

    # ---------------------------------------------------------------- verdicts
    verifs: list[tuple[str, bool]] = []

    def v(nom_verif: str, ok: bool) -> None:
        verifs.append((nom_verif, ok))

    for nom, duree in {**LITS, **EVENEMENTS}.items():
        m = mesures[nom]
        v("%s : 22 050 Hz natif" % nom, m["rate"] == RATE_ATTENDU)
        v("%s : durée exacte %.1f s (%d trames)"
          % (nom, duree, int(duree * RATE_ATTENDU)),
          m["trames"] == int(duree * RATE_ATTENDU))
    rms_lits = [mesures[n]["rms_dbfs"] for n in LITS]
    v("lits : RMS ≤ %.1f dBFS (max mesuré %.2f)"
      % (RMS_LIT_MAX_DBFS, max(rms_lits)), max(rms_lits) <= RMS_LIT_MAX_DBFS)
    v("lits : égaux à ±0,5 dB (écart %.3f)" % (max(rms_lits) - min(rms_lits)),
      max(rms_lits) - min(rms_lits) <= ECART_LITS_MAX_DB)
    v("lits : marge ≥ %.0f dB sous la banque (%.2f dBFS ; pire lit %.2f)"
      % (MARGE_MASQUAGE_DB, ref_db, max(rms_lits)),
      max(rms_lits) <= ref_db - MARGE_MASQUAGE_DB)
    crete_min_lits_db = min(mesures[n]["crete_dbfs"] for n in LITS)
    for nom in EVENEMENTS:
        m = mesures[nom]
        v("%s : crête ≤ %.2f (mesurée %.4f)" % (nom, CRETE_EVT_MAX, m["crete"]),
          m["crete"] <= CRETE_EVT_MAX)
        v("%s : crête ≤ crête min des lits +%.0f dB (%.2f ≤ %.2f)"
          % (nom, CRETE_EVT_SUR_LIT_DB, m["crete_dbfs"],
             crete_min_lits_db + CRETE_EVT_SUR_LIT_DB),
          m["crete_dbfs"] <= crete_min_lits_db + CRETE_EVT_SUR_LIT_DB)
    for nom in LITS:
        m = mesures[nom]
        v("%s : raccord de boucle ≤ p95 des deltas (%.6f ≤ %.6f)"
          % (nom, m["delta_raccord"], m["p95_deltas"]),
          m["delta_raccord"] <= m["p95_deltas"])
        v("%s : stabilité RMS ≤ %.0f dB (%.2f)"
          % (nom, STABILITE_MAX_DB, m["stabilite_db"]),
          m["stabilite_db"] <= STABILITE_MAX_DB)
        v("%s : ≥ %.0f %% dans 707-2 828 Hz (%.1f)"
          % (nom, BANDE_CREUSE_MIN_PCT, m["creuse_pct"]),
          m["creuse_pct"] >= BANDE_CREUSE_MIN_PCT)
        v("%s : ≤ %.0f %% dans 125-500 Hz (%.2f)"
          % (nom, MASQUAGE_LIT_MAX_PCT, m["masquage_pct"]),
          m["masquage_pct"] <= MASQUAGE_LIT_MAX_PCT)
    for nom in EVENEMENTS:
        v("%s : ≤ %.0f %% dans 125-500 Hz (%.2f)"
          % (nom, MASQUAGE_EVT_MAX_PCT, mesures[nom]["masquage_pct"]),
          mesures[nom]["masquage_pct"] <= MASQUAGE_EVT_MAX_PCT)
    for proto in ("P1", "P2", "P3"):
        v("coût QOA %s = budget du document (%d = %d)"
          % (proto, couts[proto], BUDGETS_PROTO[proto]),
          couts[proto] == BUDGETS_PROTO[proto])

    print()
    reussies = 0
    for nom_verif, ok in verifs:
        if not ok:
            print("ÉCHEC à la vérification %d/%d : %s"
                  % (reussies + 1, len(verifs), nom_verif))
            print("(%d vérification(s) précédente(s) tenaient)" % reussies)
            return 1
        reussies += 1
    print("PASS : %d/%d vérifications tiennent sur les 8 fichiers." %
          (reussies, len(verifs)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
