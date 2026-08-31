#!/usr/bin/env python3
"""Huit WAV de prototype d'ambiance — ISS-087, D-066.

Produit les sources des trois prototypes de `docs/audio/PROTOTYPES_AMBIANCE.md` :

    amb_p1_lit.wav      30,0 s   lit unique (P1)
    amb_p2_ouvert.wav   15,0 s   lit « plein air » (P2)
    amb_p2_ferme.wav    15,0 s   lit « couvert/encaissé » (P2)
    amb_p3_lit.wav      20,0 s   lit de P3
    amb_evt_1..4.wav     2,5 s   événements rares de P3

Règles héritées de mesures, pas de goûts :

- **22 050 Hz natif, mono 16 bits.** Jamais de ré-échantillonnage par
  `force/max_rate` dans un `.import` : le moteur abandonne un échantillon sur
  deux au rapport 2:1 et replie tout ce qui dépasse 11 025 Hz à pleine
  amplitude (INVENTAIRE_SONORE §4.1, quatre tons mesurés à 0,00 dB
  d'atténuation).
- **Énergie dans 707-2 828 Hz**, la seule bande creuse de la banque (§3.2) ;
  creux délibéré en 125-500 Hz, où dix des vingt sons courts vivent. Rien
  au-dessus de 11 025 Hz : c'est le Nyquist, la garantie est structurelle.
- **Graines dérivées du NOM** (crc32) : chaque fichier est reproductible à
  l'octet près, indépendamment des autres fichiers du dépôt.
- **Dither TPDF de 1 LSB** avant quantification : la troncature nue fabrique
  des raies d'intermodulation corrélées au signal (mesuré sur l'arbre de
  recherche ISS-087).
- **Enveloppes à plancher** (`VMIN` ≥ 0,4 exigé ; 0,65 posé) : une respiration
  bornée à zéro rend des fenêtres muettes qui s'entendent comme des trous.
- **Boucle par fondu circulaire** puis rotation au plus petit delta : le
  raccord de boucle est un delta INTERNE du signal, jamais un point de couture.
- **RMS des lits fixé à −27,5 dBFS** (constante, pas re-mesure) : la borne
  liante est ≤ −27 dBFS ; la marge anti-masquage exigée (≥ 11 dB sous le RMS
  de la banque courte, mesuré à −14,04 dBFS le 2026-08-31) est alors de
  13,5 dB. Le vérificateur re-mesure la banque réelle à chaque passage —
  cette constante n'est pas un pin de la banque, c'est ce qui garde la
  génération reproductible à l'octet sans dépendre d'autres fichiers.
- **Crête des événements** : min(0,85 ; crête minimale des lits +2,5 dB), sous
  le plafond exigé de +3 dB, calculée depuis les lits générés — déterministe.

Provenance : ce script, versionné (même statut que `make_placeholder_sfx.py`,
entrée `ATTRIBUTIONS.md`). Vérification : `verifier_prototypes_iss087.py`.

Usage :  python3 tools/audio/generer_prototypes_iss087.py
"""
from __future__ import annotations

import math
import os
import random
import struct
import wave
import zlib

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "sfx")

## Plancher d'enveloppe (exigence : ≥ 0,4). 0,65 tient la stabilité RMS par
## fenêtre sous 6 dB : 20·log10(1/0,65) = 3,7 dB de balancement d'enveloppe,
## plus le résidu de granularité — mesuré ~4,5 dB au vérificateur.
VMIN = 0.65
## Cible RMS des quatre lits, en dBFS. Voir l'en-tête.
LIT_RMS_DBFS = -27.5
## Fondu circulaire du raccord de boucle.
FADE_BOUCLE_S = 1.0

LITS = [
    ("amb_p1_lit", 30.0, "ouvert"),
    ("amb_p2_ouvert", 15.0, "ouvert"),
    ("amb_p2_ferme", 15.0, "ferme"),
    ("amb_p3_lit", 20.0, "ouvert"),
]
EVENEMENTS = ["amb_evt_1", "amb_evt_2", "amb_evt_3", "amb_evt_4"]
DUREE_EVT = 2.5


def graine(nom: str) -> int:
    """Graine stable dérivée du nom — `hash()` de Python est salé, crc32 non."""
    return zlib.crc32(nom.encode("utf-8"))


# ---------------------------------------------------------------------------
# Filtres — biquads RBJ (Audio EQ Cookbook), forme directe II transposée.
# ---------------------------------------------------------------------------
def _biquad(x: list[float], b0: float, b1: float, b2: float,
            a1: float, a2: float) -> list[float]:
    y = [0.0] * len(x)
    z1 = 0.0
    z2 = 0.0
    for i, v in enumerate(x):
        w = b0 * v + z1
        z1 = b1 * v - a1 * w + z2
        z2 = b2 * v - a2 * w
        y[i] = w
    return y


def _coeffs(genre: str, f0: float, q: float = 0.70710678) -> tuple:
    w0 = 2.0 * math.pi * f0 / RATE
    alpha = math.sin(w0) / (2.0 * q)
    cw = math.cos(w0)
    if genre == "pb":       # passe-bas
        b0, b1, b2 = (1.0 - cw) / 2.0, 1.0 - cw, (1.0 - cw) / 2.0
    else:                    # passe-haut
        b0, b1, b2 = (1.0 + cw) / 2.0, -(1.0 + cw), (1.0 + cw) / 2.0
    a0 = 1.0 + alpha
    return (b0 / a0, b1 / a0, b2 / a0, (-2.0 * cw) / a0, (1.0 - alpha) / a0)


def passe_bande(x: list[float], f_bas: float, f_haut: float,
                ordres: int = 2) -> list[float]:
    """`ordres` biquads passe-haut à `f_bas` puis autant de passe-bas à
    `f_haut` : pentes de 12·ordres dB/oct de chaque côté."""
    ph = _coeffs("ph", f_bas)
    pb = _coeffs("pb", f_haut)
    for _ in range(ordres):
        x = _biquad(x, *ph)
    for _ in range(ordres):
        x = _biquad(x, *pb)
    return x


def bruit(n: int, rng: random.Random) -> list[float]:
    return [rng.uniform(-1.0, 1.0) for _ in range(n)]


# ---------------------------------------------------------------------------
# Enveloppes
# ---------------------------------------------------------------------------
def houle(n: int, rng: random.Random, periodes_s: list[float],
          plancher: float) -> list[float]:
    """Respiration lente : somme de sinus à phases tirées, remise à l'échelle
    dans [plancher, 1]. Les périodes sont longues devant la fenêtre de mesure
    (0,5 s) : la stabilité RMS suit l'amplitude de l'enveloppe, connue."""
    phases = [rng.uniform(0.0, 2.0 * math.pi) for _ in periodes_s]
    poids = [1.0, 0.6, 0.35][: len(periodes_s)]
    total = sum(poids)
    out = []
    for i in range(n):
        t = i / float(RATE)
        v = sum(w * math.sin(2.0 * math.pi * t / p + ph)
                for w, p, ph in zip(poids, periodes_s, phases)) / total
        out.append(plancher + (1.0 - plancher) * (0.5 + 0.5 * v))
    return out


def granularite(n: int, rng: random.Random, freq_hz: float,
                profondeur: float) -> list[float]:
    """Texture lente : bruit passé très bas (deux pôles à `freq_hz`), gain
    autour de 1, profondeur bornée pour ne pas manger la stabilité RMS."""
    prev1 = 0.0
    prev2 = 0.0
    a = math.exp(-2.0 * math.pi * freq_hz / RATE)
    brut = []
    for _ in range(n):
        e = rng.uniform(-1.0, 1.0)
        prev1 = a * prev1 + (1.0 - a) * e
        prev2 = a * prev2 + (1.0 - a) * prev1
        brut.append(prev2)
    crete = max(abs(v) for v in brut) or 1.0
    return [1.0 + profondeur * (v / crete) for v in brut]


def attaque_retombee(n: int, attaque_s: float, retombee_s: float) -> list[float]:
    """Enveloppe d'ÉVÉNEMENT : cosinus surélevé aux deux bouts, tenue au
    milieu. Un one-shot retombe à zéro — le plancher `VMIN` ne concerne que
    les respirations des lits."""
    a = int(attaque_s * RATE)
    r = int(retombee_s * RATE)
    out = [1.0] * n
    for i in range(min(a, n)):
        out[i] = 0.5 - 0.5 * math.cos(math.pi * i / a)
    for i in range(min(r, n)):
        out[n - 1 - i] = min(out[n - 1 - i], 0.5 - 0.5 * math.cos(math.pi * i / r))
    return out


# ---------------------------------------------------------------------------
# Boucle et niveaux
# ---------------------------------------------------------------------------
def fondu_circulaire(x: list[float], n: int, fade: int) -> list[float]:
    """`x` porte n + fade trames : la queue est fondue dans la tête. Le signal
    devient CIRCULAIRE — continu partout, raccord compris."""
    out = list(x[:n])
    for i in range(fade):
        w = 0.5 - 0.5 * math.cos(math.pi * i / fade)
        out[i] = out[i] * w + x[n + i] * (1.0 - w)
    return out


def tourner_au_plus_petit_delta(x: list[float]) -> list[float]:
    """Le signal est circulaire : on choisit comme POINT DE DÉPART l'endroit du
    plus petit delta entre trames voisines. Le delta du raccord de fichier est
    alors le minimum de la distribution — jamais un tirage à 5 % au-dessus du
    p95 qu'exige le vérificateur."""
    n = len(x)
    k = min(range(n), key=lambda i: abs(x[i] - x[i - 1]))
    return x[k:] + x[:k]


def normaliser_rms(x: list[float], cible_dbfs: float) -> list[float]:
    r = math.sqrt(sum(v * v for v in x) / len(x))
    gain = (10.0 ** (cible_dbfs / 20.0)) / r
    return [v * gain for v in x]


def normaliser_crete(x: list[float], cible: float) -> list[float]:
    crete = max(abs(v) for v in x) or 1.0
    return [v * cible / crete for v in x]


def ecrire(nom: str, x: list[float]) -> None:
    """Quantification 16 bits avec dither TPDF de 1 LSB, graine dérivée du nom
    (indépendante de celle de la synthèse : le dither ne change pas si la
    recette évolue en amont)."""
    rng = random.Random(graine(nom + ".dither"))
    trames = bytearray()
    for v in x:
        tpdf = rng.random() - rng.random()          # triangulaire dans ±1 LSB
        q = int(round(v * 32767.0 + tpdf))
        trames += struct.pack("<h", max(-32768, min(32767, q)))
    chemin = os.path.join(OUT, nom + ".wav")
    with wave.open(chemin, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(bytes(trames))
    print("  %-18s %6.1f s  %8d trames" % (nom + ".wav", len(x) / RATE, len(x)))


# ---------------------------------------------------------------------------
# Recettes
# ---------------------------------------------------------------------------
def lit(nom: str, duree_s: float, caractere: str) -> list[float]:
    """Un lit : bruit borné à la bande creuse, respiration à plancher,
    granularité lente, boucle circulaire. « ouvert » et « fermé » partagent la
    MÊME bande (707-2 828 Hz) : le caractère vient du timbre — largeur de la
    nappe et vitesse de la texture — pas du volume, que la normalisation RMS
    égalise de toute façon."""
    rng = random.Random(graine(nom))
    n = int(duree_s * RATE)
    fade = int(FADE_BOUCLE_S * RATE)
    chauffe = 4096                      # transitoire des biquads, jeté
    total = chauffe + n + fade
    if caractere == "ouvert":
        # Souffle large : toute la bande creuse, granularité perceptible.
        x = passe_bande(bruit(total, rng), 780.0, 2600.0)
        texture = granularite(total, rng, 1.8, 0.12)
        respiration = houle(total, rng, [7.3, 4.1, 11.9], VMIN)
    else:
        # Nappe sombre/étouffée : mêmes octaves, moitié basse de la bande,
        # texture plus lente et plus discrète.
        x = passe_bande(bruit(total, rng), 760.0, 1500.0)
        texture = granularite(total, rng, 0.7, 0.08)
        respiration = houle(total, rng, [9.7, 5.9], VMIN + 0.05)
    x = [v * t * r for v, t, r in zip(x, texture, respiration)]
    x = x[chauffe:]
    x = fondu_circulaire(x, n, fade)
    x = tourner_au_plus_petit_delta(x)
    return normaliser_rms(x, LIT_RMS_DBFS)


def _sinus_glisse(n: int, f_debut: float, f_fin: float,
                  vibrato_hz: float = 0.0, vibrato_prof: float = 0.0) -> list[float]:
    out = []
    phase = 0.0
    for i in range(n):
        t = i / float(n)
        f = f_debut + (f_fin - f_debut) * t
        if vibrato_hz > 0.0:
            f *= 1.0 + vibrato_prof * math.sin(2.0 * math.pi * vibrato_hz * i / RATE)
        phase += 2.0 * math.pi * f / RATE
        out.append(math.sin(phase))
    return out


def evenement(nom: str) -> list[float]:
    """Quatre événements distincts. Rares (20-45 s d'intervalle dans P3), ils
    ont le DROIT de monter au-dessus de 2 828 Hz — c'est leur rareté qui paie
    ce droit — mais ils évitent 125-500 Hz comme les lits. Attaque et
    retombée douces : rien ne claque."""
    rng = random.Random(graine(nom))
    n = int(DUREE_EVT * RATE)
    if nom == "amb_evt_1":
        # Appel d'oiseau lointain : deux notes descendantes, vibrato léger.
        x = [0.0] * n
        for debut_s, f0, f1 in ((0.25, 2650.0, 1750.0), (1.25, 2350.0, 1600.0)):
            note = _sinus_glisse(int(0.55 * RATE), f0, f1, 5.5, 0.012)
            env = attaque_retombee(len(note), 0.12, 0.25)
            d = int(debut_s * RATE)
            for i, v in enumerate(note):
                x[d + i] += v * env[i]
        env = attaque_retombee(n, 0.15, 0.5)
        x = [v * e for v, e in zip(x, env)]
    elif nom == "amb_evt_2":
        # Grondement lointain de la citadelle : houle de bruit dans le bas de
        # la bande creuse. Pentes d'ordre 3 (36 dB/oct) : à l'ordre 2 et
        # coupé à 650 Hz, 13,2 % de l'énergie fuyait dans 125-500 Hz —
        # mesuré par le vérificateur, borne ≤ 10 %.
        x = passe_bande(bruit(n + 4096, rng), 800.0, 1400.0, 3)[4096:]
        env = attaque_retombee(n, 0.55, 1.1)
        x = [v * e for v, e in zip(x, env)]
    elif nom == "amb_evt_3":
        # Rafale de vent : nappe large qui monte haut, flutter lent.
        x = passe_bande(bruit(n + 4096, rng), 900.0, 6200.0)[4096:]
        texture = granularite(n, rng, 3.2, 0.35)
        env = attaque_retombee(n, 0.45, 0.9)
        x = [v * t * e for v, t, e in zip(x, texture, env)]
    else:
        # Stridulation d'insecte : impulsions de 4,2 kHz à 13 Hz.
        porteur = _sinus_glisse(n, 4200.0, 4150.0)
        x = []
        for i, v in enumerate(porteur):
            gate = 0.5 - 0.5 * math.cos(2.0 * math.pi * 13.0 * i / RATE)
            x.append(v * gate * gate)
        env = attaque_retombee(n, 0.4, 0.7)
        x = [v * e for v, e in zip(x, env)]
    return x


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    print("Prototypes d'ambiance ISS-087 — 22 050 Hz mono 16 bits, dither TPDF")
    lits: dict[str, list[float]] = {}
    for nom, duree, caractere in LITS:
        lits[nom] = lit(nom, duree, caractere)
        ecrire(nom, lits[nom])
    # Crête des événements : sous la crête minimale des lits +3 dB (exigence),
    # posée à +2,5 dB pour garder 0,5 dB de marge de quantification.
    crete_min_lits = min(max(abs(v) for v in x) for x in lits.values())
    cible_crete = min(0.85, crete_min_lits * (10.0 ** (2.5 / 20.0)))
    for nom in EVENEMENTS:
        ecrire(nom, normaliser_crete(evenement(nom), cible_crete))
    print("Vérification : python3 tools/audio/verifier_prototypes_iss087.py")


if __name__ == "__main__":
    main()
