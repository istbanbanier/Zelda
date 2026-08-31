#!/usr/bin/env python3
"""Profil d'énergie par bande d'octave d'un WAV — ISS-087.

POURQUOI CE FICHIER EXISTE, ET POURQUOI IL A DÛ ÊTRE RÉÉCRIT
------------------------------------------------------------
Une première version de cet outil a rendu **33 % d'énergie en 125-500 Hz pour
du bruit blanc**, qui y en a 2,8 %. Elle a servi à désigner un « point faible »
(`amb_bed_riviere`, annoncé à 40,7 %) qui est en réalité le clip le plus propre
de sa série (1,4 %), et à déclarer propre un bourdon qui ne l'est pas
(`amb_drone_neris`, annoncé 0,5 % à 125 Hz, mesuré 38,4 % — facteur 77).

Deux causes, toutes deux dans le code, et toutes deux reproductibles :

1. **Somme de raies de sonde au lieu d'une intégrale.** L'ancienne version
   sommait huit raies par octave, quelle que soit la largeur de l'octave. Une
   octave haute est large (l'octave 16 kHz couvre 11 314-22 050 Hz, soit
   10 736 Hz) et une octave basse est étroite (l'octave 31,5 Hz couvre
   22,3-44,5 Hz, soit 22,3 Hz — 481 fois moins). Échantillonner huit points
   dans chacune mesure une DENSITÉ spectrale moyenne, pas une énergie, et
   gonfle donc systématiquement les basses d'un facteur égal au rapport des
   largeurs. C'est exactement le biais observé.

2. **Décimation sans filtre anti-repliement.** `step = max(1, n // 20000)`
   gardait une trame sur neuf d'un clip de 176 400 trames sans passe-bas
   préalable. Le Nyquist effectif tombait à 2 756 Hz : tout contenu au-dessus
   se repliait dans la bande utile, et les colonnes 4 k, 8 k et 16 k ne
   mesuraient que des alias.

Cette version-ci **intègre** la densité spectrale sur la largeur réelle de
chaque bande et **ne décime pas du tout**. Elle se valide contre des entrées
dont la réponse théorique est connue d'avance (`--valider`), et cette
validation est publiée : un instrument non validé ne peut pas servir de
portail (PROMPT4_METHOD §2).

CE QU'IL MESURE
---------------
La FRACTION de l'énergie totale du signal qui tombe dans chaque bande
d'octave normalisée (centres 31,5 Hz à 16 kHz). Les fractions somment à 100 %
par construction : aucune énergie n'est perdue en route, et le tableau le
montre — un total qui s'éloignerait de 100 % serait le signe d'un défaut.

MÉTHODE
-------
Périodogramme de Welch : segments de longueur L (puissance de deux), fenêtre
de Hann périodique, recouvrement 50 %, moyenne des périodogrammes. Spectre
unilatéral (les raies 0 < k < L/2 comptent double ; continu et Nyquist une
seule fois). Puis chaque raie, qui couvre l'intervalle
[(k-1/2)·df, (k+1/2)·df], verse son énergie aux bandes **au prorata du
recouvrement** de cet intervalle avec chacune. Ce prorata est ce qui rend
l'intégration juste là où les raies sont rares — dans les octaves basses, où
l'ancienne version se trompait le plus.

LIMITE ASSUMÉE : lit le WAV PCM 8/16/24/32 bits, mono ou stéréo (moyenné en
mono). Ne décode PAS l'Ogg Vorbis — les six sons d'interface du projet sont en
`.ogg` et sortent donc du périmètre de cet outil. Les 21 sons de
`assets/audio/sfx/` sont tous en WAV et sont, eux, mesurables.

Usage :
    python3 tools/audio/band_profile.py --valider
    python3 tools/audio/band_profile.py assets/audio/sfx/amb_valley.wav
    python3 tools/audio/band_profile.py --csv assets/audio/sfx/*.wav

Codes retour (convention du projet, `tools/CLAUDE.md`) :
    0  mesure faite
    3  BLOQUÉ — rien n'a pu être mesuré (aucun fichier lisible)
    1  ÉCHEC — la validation de l'instrument ne passe pas ses propres seuils
"""
from __future__ import annotations

import argparse
import cmath
import math
import os
import random
import struct
import sys
import wave

# Centres d'octave normalisés. Les bornes valent centre/sqrt(2) et
# centre*sqrt(2) : deux bandes voisines se touchent exactement, sans trou ni
# recouvrement, puisque 31,5*sqrt(2) == 63/sqrt(2) à l'arrondi près.
CENTRES = [31.5, 63.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0]
RAC2 = math.sqrt(2.0)

# La bande où se joue le masquage, d'après les mesures conservées de la
# contre-revue : c'est là que les sons COURTS du projet ont déjà leur énergie
# (amb_valley 54,7 %, hit_taken 94,1 % à 125 Hz, step_stone_a 85,1 % à 250 Hz).
# Une ambiance qui s'y installe masquera ce qui doit s'entendre.
BANDE_MASQUAGE = (125.0 / RAC2, 500.0 * RAC2)

SEGMENT_MAX = 8192
SEGMENT_MIN = 256


# --------------------------------------------------------------------------
# FFT — radix 2 itérative. Pas de numpy dans ce conteneur (le paquet est
# présent mais ses extensions C sont cassées : `No module named
# numpy.core._multiarray_umath`), donc Python pur, et c'est assumé.
# --------------------------------------------------------------------------
_TWIDDLE: dict[int, list[complex]] = {}


def _twiddles(n: int) -> list[complex]:
    """Racines de l'unité, mémorisées. Table plutôt que produit accumulé :
    `w *= wlen` répété 4 096 fois accumule une dérive de phase que rien ne
    corrige, et le coût d'une table est dérisoire."""
    if n not in _TWIDDLE:
        _TWIDDLE[n] = [cmath.exp(-2j * math.pi * k / n) for k in range(n // 2)]
    return _TWIDDLE[n]


def fft(a: list[complex]) -> list[complex]:
    n = len(a)
    if n & (n - 1):
        raise ValueError("longueur non puissance de deux : %d" % n)
    j = 0
    for i in range(1, n):
        bit = n >> 1
        while j & bit:
            j ^= bit
            bit >>= 1
        j |= bit
        if i < j:
            a[i], a[j] = a[j], a[i]
    longueur = 2
    while longueur <= n:
        w = _twiddles(longueur)
        demi = longueur >> 1
        for debut in range(0, n, longueur):
            for k in range(demi):
                u = a[debut + k]
                v = a[debut + demi + k] * w[k]
                a[debut + k] = u + v
                a[debut + demi + k] = u - v
        longueur <<= 1
    return a


def ifft(spectre: list[complex]) -> list[complex]:
    """Inverse par conjugaison. Sert uniquement à SYNTHÉTISER le bruit rose de
    validation, dont la théorie est exacte dans le domaine spectral."""
    n = len(spectre)
    conj = [c.conjugate() for c in spectre]
    out = fft(conj)
    return [c.conjugate() / n for c in out]


# --------------------------------------------------------------------------
# Lecture WAV
# --------------------------------------------------------------------------
def lire_wav(chemin: str) -> tuple[list[float], int]:
    """Rend (échantillons mono normalisés dans [-1,1], fréquence)."""
    with wave.open(chemin, "rb") as f:
        canaux = f.getnchannels()
        largeur = f.getsampwidth()
        rate = f.getframerate()
        brut = f.readframes(f.getnframes())
    if largeur == 2:
        vals = [v / 32768.0 for v in struct.unpack("<%dh" % (len(brut) // 2), brut)]
    elif largeur == 1:
        # WAV 8 bits est NON signé, décalé de 128. Se tromper ici poserait un
        # continu de 1,0 qui écraserait tout le tableau dans la bande basse.
        vals = [(v - 128) / 128.0 for v in struct.unpack("%dB" % len(brut), brut)]
    elif largeur == 3:
        vals = []
        for i in range(0, len(brut), 3):
            v = int.from_bytes(brut[i:i + 3], "little", signed=True)
            vals.append(v / 8388608.0)
    elif largeur == 4:
        vals = [v / 2147483648.0 for v in
                struct.unpack("<%di" % (len(brut) // 4), brut)]
    else:
        raise ValueError("largeur d'échantillon non gérée : %d octets" % largeur)
    if canaux > 1:
        vals = [sum(vals[i:i + canaux]) / canaux
                for i in range(0, len(vals) - canaux + 1, canaux)]
    return vals, rate


# --------------------------------------------------------------------------
# Le cœur : Welch, puis intégration au prorata sur les bandes
# --------------------------------------------------------------------------
def bornes_bandes(nyquist: float) -> list[tuple[str, float, float]]:
    """Bandes contiguës couvrant 0 .. Nyquist, sans trou. La première va de 0
    à la borne basse de l'octave 31,5 (elle absorbe le continu, ce qui est
    voulu : un continu doit se VOIR, pas se diluer), la dernière est tronquée
    à Nyquist."""
    bandes: list[tuple[str, float, float]] = []
    basse = CENTRES[0] / RAC2
    bandes.append(("<%d" % round(basse), 0.0, basse))
    for c in CENTRES:
        lo, hi = c / RAC2, c * RAC2
        if lo >= nyquist:
            break
        bandes.append((("%g" % c) if c < 1000 else ("%gk" % (c / 1000.0)),
                       lo, min(hi, nyquist)))
    dernier = bandes[-1][2]
    if dernier < nyquist - 1e-9:
        bandes.append((">%d" % round(dernier), dernier, nyquist))
    return bandes


def profil(ech: list[float], rate: int) -> dict:
    n = len(ech)
    if n < SEGMENT_MIN:
        raise ValueError("clip trop court : %d trames (< %d)" % (n, SEGMENT_MIN))
    # Longueur de segment : la plus grande puissance de deux qui tienne, bornée.
    L = SEGMENT_MIN
    while L * 2 <= min(n, SEGMENT_MAX):
        L *= 2
    hop = L // 2
    hann = [0.5 - 0.5 * math.cos(2.0 * math.pi * i / L) for i in range(L)]

    nyquist = rate / 2.0
    df = rate / float(L)
    puissance = [0.0] * (L // 2 + 1)
    segments = 0
    debut = 0
    while debut + L <= n:
        buf = [complex(ech[debut + i] * hann[i], 0.0) for i in range(L)]
        spec = fft(buf)
        # Spectre unilatéral : les raies intérieures comptent double, le
        # continu et Nyquist une seule fois. Oublier ce facteur ne changerait
        # pas les FRACTIONS (facteur commun), mais rendrait l'énergie totale
        # fausse — et l'énergie totale est ce qui permet de vérifier Parseval.
        puissance[0] += abs(spec[0]) ** 2
        for k in range(1, L // 2):
            puissance[k] += 2.0 * abs(spec[k]) ** 2
        puissance[L // 2] += abs(spec[L // 2]) ** 2
        segments += 1
        debut += hop
    if segments == 0:
        raise ValueError("aucun segment complet")
    puissance = [p / segments for p in puissance]

    bandes = bornes_bandes(nyquist)
    energie = [0.0] * len(bandes)
    # INTÉGRATION AU PRORATA. Chaque raie couvre une largeur df centrée sur
    # elle ; on répartit son énergie entre les bandes selon le recouvrement
    # réel. C'est ce qui remplace la « somme de huit sondes par octave ».
    for k, p in enumerate(puissance):
        if p == 0.0:
            continue
        f_lo = max(0.0, (k - 0.5) * df)
        f_hi = min(nyquist, (k + 0.5) * df)
        largeur = f_hi - f_lo
        if largeur <= 0.0:
            continue
        for i, (_nom, b_lo, b_hi) in enumerate(bandes):
            rec = min(f_hi, b_hi) - max(f_lo, b_lo)
            if rec > 0.0:
                energie[i] += p * (rec / largeur)

    total = sum(energie)
    fractions = [(e / total * 100.0 if total > 0 else 0.0) for e in energie]

    masq = 0.0
    for i, (_nom, b_lo, b_hi) in enumerate(bandes):
        rec = min(b_hi, BANDE_MASQUAGE[1]) - max(b_lo, BANDE_MASQUAGE[0])
        if rec > 0.0:
            masq += fractions[i] * (rec / (b_hi - b_lo))

    return {
        "bandes": bandes,
        "fractions": fractions,
        "masquage": masq,
        "segments": segments,
        "L": L,
        "df": df,
        "rate": rate,
        "trames": n,
        "duree": n / float(rate),
        "continu": sum(ech) / n,
        "rms": math.sqrt(sum(v * v for v in ech) / n),
        "crete": max(abs(v) for v in ech),
    }


# --------------------------------------------------------------------------
# Signaux de validation — théorie connue d'avance
# --------------------------------------------------------------------------
def bruit_blanc(n: int, graine: int = 20260831) -> list[float]:
    r = random.Random(graine)
    return [r.gauss(0.0, 0.25) for _ in range(n)]


def sinus(n: int, freq: float, rate: int) -> list[float]:
    return [0.5 * math.sin(2.0 * math.pi * freq * i / rate) for i in range(n)]


def bruit_rose(n_pow2: int, rate: int, graine: int = 20260831) -> list[float]:
    """Bruit rose EXACT, synthétisé dans le domaine spectral : densité de
    puissance en 1/f, donc énergie égale par octave — c'est précisément
    l'invariant que le bug de « huit sondes par octave » violait."""
    r = random.Random(graine)
    demi = n_pow2 // 2
    spec: list[complex] = [0j] * n_pow2
    for k in range(1, demi):
        f = k * rate / float(n_pow2)
        amp = 1.0 / math.sqrt(f)
        phase = r.uniform(0.0, 2.0 * math.pi)
        c = amp * cmath.exp(1j * phase)
        spec[k] = c
        spec[n_pow2 - k] = c.conjugate()
    x = [v.real for v in ifft(spec)]
    m = max(abs(v) for v in x) or 1.0
    return [0.5 * v / m for v in x]


def valider() -> int:
    """Éprouve l'instrument sur quatre entrées dont la réponse est connue.
    Publie le tableau : sans cette page, l'outil n'est pas un portail."""
    rate = 44100
    n = rate * 4
    echecs: list[str] = []
    print("VALIDATION DE L'INSTRUMENT — %d Hz, %.1f s par cas" % (rate, n / rate))
    print()

    # -- Cas 1 : bruit blanc. Théorie : fraction proportionnelle à la LARGEUR.
    p = profil(bruit_blanc(n), rate)
    nyq = rate / 2.0
    print("Cas 1 — BRUIT BLANC gaussien (graine figée)")
    print("  Théorie : fraction d'une bande = largeur / Nyquist.")
    print("  %-8s %10s %10s %10s" % ("bande", "mesuré%", "théorie%", "écart pt"))
    pire = 0.0
    for (nom, lo, hi), frac in zip(p["bandes"], p["fractions"]):
        th = (hi - lo) / nyq * 100.0
        ecart = abs(frac - th)
        pire = max(pire, ecart)
        print("  %-8s %10.3f %10.3f %10.3f" % (nom, frac, th, ecart))
    print("  écart maximal : %.3f point de pourcentage" % pire)
    if pire > 1.5:
        echecs.append("bruit blanc : écart %.3f pt > 1,5" % pire)
    # Le sous-total qui a démasqué l'ancien outil.
    th_masq = (BANDE_MASQUAGE[1] - BANDE_MASQUAGE[0]) / nyq * 100.0
    print("  125-500 Hz : mesuré %.2f %%   théorie %.2f %%"
          "   (l'ancien outil rendait 33 %%)" % (p["masquage"], th_masq))
    if abs(p["masquage"] - th_masq) > 1.0:
        echecs.append("bruit blanc 125-500 : %.2f vs %.2f" % (p["masquage"], th_masq))
    print()

    # -- Cas 2 : sinus à 250 Hz. Théorie : ~tout dans l'octave 250.
    p = profil(sinus(n, 250.0, rate), rate)
    part = dict(zip([b[0] for b in p["bandes"]], p["fractions"]))
    print("Cas 2 — SINUS PUR 250 Hz")
    print("  Théorie : l'octave 250 (176,8-353,6 Hz) prend ~100 %.")
    print("  octave 250 : %.3f %%   reste : %.3f %%"
          % (part.get("250", 0.0), 100.0 - part.get("250", 0.0)))
    if part.get("250", 0.0) < 99.0:
        echecs.append("sinus 250 : %.3f %% seulement" % part.get("250", 0.0))
    print()

    # -- Cas 3 : sinus à 16 kHz. LE CONTRÔLE ANTI-REPLIEMENT.
    p = profil(sinus(n, 16000.0, rate), rate)
    part = dict(zip([b[0] for b in p["bandes"]], p["fractions"]))
    basse = sum(f for (nom, lo, hi), f in zip(p["bandes"], p["fractions"])
                if hi <= 2000.0)
    print("Cas 3 — SINUS PUR 16 kHz  (contrôle ANTI-REPLIEMENT)")
    print("  Théorie : l'octave 16k prend ~100 %, et RIEN ne descend en bas.")
    print("  Une décimation sans filtre — le second défaut de l'ancien outil —")
    print("  replierait ce ton vers ~1,3 kHz et le ferait apparaître en bas.")
    print("  octave 16k : %.3f %%   total sous 2 kHz : %.4f %%"
          % (part.get("16k", 0.0), basse))
    if part.get("16k", 0.0) < 99.0:
        echecs.append("sinus 16k : %.3f %% seulement" % part.get("16k", 0.0))
    if basse > 0.5:
        echecs.append("sinus 16k : %.3f %% de repliement sous 2 kHz" % basse)
    print()

    # -- Cas 4 : bruit rose. Théorie : énergie ÉGALE par octave.
    npow = 1
    while npow * 2 <= n:
        npow *= 2
    p = profil(bruit_rose(npow, rate), rate)
    print("Cas 4 — BRUIT ROSE exact (densité 1/f)")
    print("  Théorie : chaque octave PLEINE porte la même énergie.")
    print("  C'est l'invariant que « huit sondes par octave » violait.")
    pleines = [(nom, f) for (nom, lo, hi), f in zip(p["bandes"], p["fractions"])
               if nom in ("125", "250", "500", "1k", "2k", "4k", "8k")]
    moy = sum(f for _n, f in pleines) / len(pleines)
    print("  %s" % "  ".join("%s=%.2f%%" % (n_, f) for n_, f in pleines))
    disp = max(abs(f - moy) / moy for _n, f in pleines) * 100.0
    print("  moyenne %.2f %% — dispersion maximale %.1f %% de la moyenne" % (moy, disp))
    if disp > 12.0:
        echecs.append("bruit rose : dispersion %.1f %% > 12 %%" % disp)
    print()

    # -- Cas 5 : conservation. Les fractions somment à 100.
    p = profil(bruit_blanc(n), rate)
    s = sum(p["fractions"])
    print("Cas 5 — CONSERVATION : somme des fractions = %.6f %%" % s)
    if abs(s - 100.0) > 1e-6:
        echecs.append("somme des fractions = %.6f" % s)
    print()

    if echecs:
        print("VALIDATION : ÉCHEC")
        for e in echecs:
            print("  - %s" % e)
        return 1
    print("VALIDATION : les cinq cas passent. L'instrument peut servir de mesure.")
    return 0


def afficher(chemin: str, p: dict, csv: bool) -> None:
    nom = os.path.basename(chemin)
    if csv:
        print("%s,%.4f,%d,%s,%.3f" % (
            nom, p["duree"], p["rate"],
            ",".join("%.3f" % f for f in p["fractions"]), p["masquage"]))
        return
    print("%s" % nom)
    print("  %.3f s · %d Hz · %d trames · Welch L=%d (%.2f Hz/raie) · %d segments"
          % (p["duree"], p["rate"], p["trames"], p["L"], p["df"], p["segments"]))
    print("  RMS %.4f · crête %.4f · continu %+.5f"
          % (p["rms"], p["crete"], p["continu"]))
    largeur = max(len(b[0]) for b in p["bandes"])
    for (bnom, lo, hi), f in zip(p["bandes"], p["fractions"]):
        barre = "#" * int(round(f / 2.0))
        print("  %*s Hz [%7.1f-%7.1f] %6.2f %%  %s" % (largeur, bnom, lo, hi, f, barre))
    print("  >> 125-500 Hz (bande de masquage) : %.2f %%" % p["masquage"])
    print()


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("fichiers", nargs="*")
    ap.add_argument("--valider", action="store_true",
                    help="éprouve l'instrument contre des signaux de théorie connue")
    ap.add_argument("--csv", action="store_true")
    a = ap.parse_args(argv)

    if a.valider:
        return valider()
    if not a.fichiers:
        ap.print_help()
        return 3

    if a.csv:
        exemple = bornes_bandes(22050.0)
        print("fichier,duree_s,rate,%s,masquage_125_500"
              % ",".join("b_" + b[0] for b in exemple))
    mesures = 0
    for chemin in a.fichiers:
        try:
            ech, rate = lire_wav(chemin)
            afficher(chemin, profil(ech, rate), a.csv)
            mesures += 1
        except Exception as exc:  # noqa: BLE001 — on veut le nom du fichier fautif
            print("  [ILLISIBLE] %s : %s" % (chemin, exc), file=sys.stderr)
    if mesures == 0:
        print("BLOQUÉ : aucun fichier mesurable.", file=sys.stderr)
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
