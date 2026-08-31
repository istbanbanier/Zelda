#!/usr/bin/env python3
"""Prix EXACT d'un flux Quite OK Audio, sans lancer Godot — ISS-087.

POURQUOI : le budget audio de ce projet se compte en OCTETS, pas en voix
(11 voix simultanées sur 48 autorisées : la marge de voix ne mord jamais). Or
`compress/mode=2` dans les `.import` signifie QOA, à débit variable : on ne
pouvait chiffrer une ambiance qu'APRÈS l'avoir produite et importée.

Ce modèle la chiffre AVANT. Le format groupe 20 échantillons en une tranche de
8 octets, 256 tranches par trame QOA (5 120 échantillons), avec 8 octets
d'en-tête de trame et 16 octets d'état LMS par canal, plus 8 octets d'en-tête
de fichier.

VÉRIFIÉ : 176 400 trames mono -> 71 408 octets prédits, contre 71 408 mesurés
dans le moteur par ISS-088 (`data.size()` d'`amb_valley`). Zéro écart.
`--verifier` rejoue ce contrôle et sort en 1 s'il échoue.

Usage :
    python3 tools/audio/qoa_cost.py --verifier
    python3 tools/audio/qoa_cost.py 30 --rate 22050
"""
from __future__ import annotations

import argparse
import math
import sys

TAMPON_DECODAGE_PAR_VOIX = 10240
BANQUE_SONS_COURTS = 132144  # les 21 WAV importés, mesuré par ISS-088


def taille_qoa(trames: int, canaux: int = 1) -> int:
    total = 8
    reste = trames
    while reste > 0:
        f = min(5120, reste)
        total += 8 + 16 * canaux + 8 * canaux * math.ceil(f / 20)
        reste -= f
    return total


def verifier() -> int:
    attendu = 71408
    obtenu = taille_qoa(176400, 1)
    print("Contrôle : amb_valley, 176 400 trames mono 44,1 kHz")
    print("  prédit par ce modèle : %d octets" % obtenu)
    print("  mesuré dans le moteur (ISS-088) : %d octets" % attendu)
    print("  écart : %d" % (obtenu - attendu))
    if obtenu != attendu:
        print("ÉCHEC : le modèle ne reproduit plus la mesure.")
        return 1
    print("OK : le modèle est exact.")
    return 0


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("secondes", nargs="*", type=float)
    ap.add_argument("--rate", type=int, default=22050)
    ap.add_argument("--canaux", type=int, default=1)
    ap.add_argument("--verifier", action="store_true")
    a = ap.parse_args(argv)
    if a.verifier:
        return verifier()
    if not a.secondes:
        ap.print_help()
        return 3
    print("%9s %12s %10s %12s" % ("durée s", "octets", "x banque", "+ tampon"))
    for d in a.secondes:
        o = taille_qoa(int(d * a.rate), a.canaux)
        print("%9.2f %12d %10.2f %12d"
              % (d, o, o / BANQUE_SONS_COURTS, o + TAMPON_DECODAGE_PAR_VOIX))
    debit = taille_qoa(a.rate * 100, a.canaux) / 100.0
    print("débit : %.1f octets/s à %d Hz, %d canal/canaux" % (debit, a.rate, a.canaux))
    print("seuil d'égalité avec la banque des sons courts : %.2f s"
          % (BANQUE_SONS_COURTS / debit))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
