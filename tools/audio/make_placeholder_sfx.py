#!/usr/bin/env python3
"""Sons de remplacement GÉNÉRÉS — bug 1 de TESTS.md : le jeu entier était muet.

Huit sons courts, synthétisés ici même (sinus, bruit, enveloppes), écrits en
WAV PCM 16 bits mono 44,1 kHz dans `assets/audio/sfx/`. Aucun échantillon
externe : la provenance est CE script, versionné — licence triviale (CC0 de
fait), entrée correspondante dans ATTRIBUTIONS.md.

Ce sont des PLACEHOLDERS honnêtes (§18 exige à terme variation de pitch et
échantillons par matière) : leur rôle est que plus aucune action ne soit
muette, pas de sonner « final ». STATUS.md dit ce qui est réellement actif.

Usage :  python3 tools/audio/make_placeholder_sfx.py
"""
from __future__ import annotations

import math
import os
import random
import struct
import wave

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "sfx")


def write(name: str, samples: list[float]) -> None:
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
            for s in samples)
        f.writeframes(frames)
    print("  %-18s %5.0f ms" % (name + ".wav", 1000.0 * len(samples) / RATE))


def env(n: int, attack: float, decay: float) -> list[float]:
    """Enveloppe attaque/décroissance exponentielle, sans clic."""
    out = []
    a = max(1, int(attack * RATE))
    for i in range(n):
        if i < a:
            out.append(i / a)
        else:
            out.append(math.exp(-(i - a) / (decay * RATE)))
    return out


def tone(n: int, freq: float, slide: float = 0.0) -> list[float]:
    out, phase = [], 0.0
    for i in range(n):
        f = freq + slide * (i / n)
        phase += 2.0 * math.pi * f / RATE
        out.append(math.sin(phase))
    return out


def noise(n: int, lowpass: float = 1.0) -> list[float]:
    rng = random.Random(42)
    out, prev = [], 0.0
    for _ in range(n):
        prev = prev * (1.0 - lowpass) + rng.uniform(-1, 1) * lowpass
        out.append(prev)
    return out


def mix(*layers: tuple[list[float], float]) -> list[float]:
    n = max(len(s) for s, _ in layers)
    out = [0.0] * n
    for s, gain in layers:
        for i, v in enumerate(s):
            out[i] += v * gain
    peak = max(1e-6, max(abs(v) for v in out))
    return [v * 0.85 / peak for v in out]


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    ms = lambda t: int(RATE * t / 1000.0)

    # Coup PORTÉ : claquement mat, bruit filtré + corps grave bref.
    n = ms(110)
    e = env(n, 0.002, 0.030)
    write("hit_land", mix(
        ([a * b for a, b in zip(noise(n, 0.35), e)], 0.8),
        ([a * b for a, b in zip(tone(n, 180, -60), e)], 0.6)))

    # Coup REÇU : plus grave, plus long — la douleur descend.
    n = ms(160)
    e = env(n, 0.002, 0.055)
    write("hit_taken", mix(
        ([a * b for a, b in zip(tone(n, 130, -70), e)], 0.9),
        ([a * b for a, b in zip(noise(n, 0.25), e)], 0.4)))

    # Sifflement d'un swing : bruit passe-bas balayé, court.
    n = ms(140)
    e = env(n, 0.030, 0.045)
    write("swing", mix(([a * b for a, b in zip(noise(n, 0.15), e)], 1.0)))

    # REFUS : deux coups sourds descendants — « non ».
    n = ms(150)
    e1 = env(ms(60), 0.002, 0.020) + [0.0] * (n - ms(60))
    e2 = [0.0] * ms(70) + env(ms(80), 0.002, 0.025)
    write("refuse", mix(
        ([a * b for a, b in zip(tone(n, 160), e1)], 0.8),
        ([a * b for a, b in zip(tone(n, 110), e2)], 0.8)))

    # Coffre : deux tons montants, bois puis éclat.
    n = ms(320)
    e1 = env(ms(140), 0.004, 0.060) + [0.0] * (n - ms(140))
    e2 = [0.0] * ms(120) + env(n - ms(120), 0.004, 0.080)
    write("chest_open", mix(
        ([a * b for a, b in zip(tone(n, 330), e1)], 0.7),
        ([a * b for a, b in zip(tone(n, 495, 40), e2)], 0.7)))

    # Ramassage : blip clair, une quinte montante très courte.
    n = ms(120)
    e = env(n, 0.002, 0.045)
    write("pickup", mix(([a * b for a, b in zip(tone(n, 660, 220), e)], 1.0)))

    # Mort : descente lente et sombre.
    n = ms(600)
    e = env(n, 0.010, 0.220)
    write("death", mix(
        ([a * b for a, b in zip(tone(n, 220, -140), e)], 0.9),
        ([a * b for a, b in zip(noise(n, 0.10), e)], 0.3)))

    # Navigation d'interface : tic discret.
    n = ms(45)
    e = env(n, 0.001, 0.012)
    write("ui_move", mix(([a * b for a, b in zip(tone(n, 880), e)], 0.6)))

    # Validation d'interface : toc, un ton en dessous, un peu plus long.
    n = ms(80)
    e = env(n, 0.001, 0.025)
    write("ui_accept", mix(([a * b for a, b in zip(tone(n, 587), e)], 0.7)))


if __name__ == "__main__":
    main()
