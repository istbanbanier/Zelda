#!/usr/bin/env python3
"""Reproduit les mesures dérivées d'ISS-087. Lancer depuis la racine du dépôt :
    python3 evidence/world_v2/iss087/reproduire_mesures.py
Dépend de tools/audio/band_profile.py (instrument validé, cf. INSTRUMENT_BANDES.md)."""
import importlib.util, math, csv, io, sys
spec = importlib.util.spec_from_file_location("bp", "tools/audio/band_profile.py")
bp = importlib.util.module_from_spec(spec); spec.loader.exec_module(bp)

def cubic(a, b, pre, post, w):
    return 0.5*((a*2.0) + (-pre+b)*w + (2.0*pre - 5.0*a + 4.0*b - post)*(w*w)
                + (-pre + 3.0*a - 3.0*b + post)*(w*w*w))

def resample_moteur(data, rate, limit_hz):
    """Réplique EXACTE de AudioStreamWAV::load_from_file, branche `limit_rate`
    (scene/resources/audio_stream_wav.cpp) : interpolation cubique, AUCUN
    filtre anti-repliement."""
    frames = len(data); n = int(frames * float(limit_hz) / float(rate))
    out = [0.0]*n; frac = 0.0; ipos = 0
    for i in range(n):
        y0 = data[max(0, ipos-1)]; y1 = data[ipos]
        y2 = data[min(frames-1, ipos+1)]; y3 = data[min(frames-1, ipos+2)]
        out[i] = cubic(y1, y2, y0, y3, frac)
        frac += float(rate)/float(limit_hz); t = math.floor(frac)
        ipos += int(t); frac -= t
    return out

def part_au_dessus(p, seuil):
    tot = 0.0
    for (nom, lo, hi), f in zip(p["bandes"], p["fractions"]):
        rec = max(0.0, hi - max(lo, seuil))
        if rec > 0: tot += f * rec/(hi-lo)
    return tot

print("=" * 72)
print("MESURE 1 — REPLIEMENT DE `force/max_rate` DANS L'IMPORTATEUR GODOT")
print("=" * 72)
print("Sinus pur 16 000 Hz à 44,1 kHz, passé dans l'algorithme du moteur vers 22,05 kHz.")
print("Nyquist réduit = 11 025 Hz. Repliement théorique : 22 050 - 16 000 = 6 050 Hz.")
src = bp.sinus(44100*2, 16000.0, 44100)
for titre, ech, r in (("AVANT  (44,1 kHz)", src, 44100),
                      ("APRÈS  (22,05 kHz, algorithme du moteur)",
                       resample_moteur(src, 44100, 22050), 22050)):
    p = bp.profil(ech, r)
    dom = max(zip(p["bandes"], p["fractions"]), key=lambda t: t[1])
    print("  %-42s octave %-4s : %6.2f %%  [%.0f-%.0f Hz]"
          % (titre, dom[0][0], dom[1], dom[0][1], dom[0][2]))
print("  Un ré-échantillonnage correct rendrait ~0 %% : le ton est au-dessus du")
print("  nouveau Nyquist, il doit DISPARAÎTRE, pas descendre.")

print()
print("=" * 72)
print("MESURE 2 — CE QUE 22,05 kHz MET HORS D'ATTEINTE DU MASQUAGE")
print("=" * 72)
print("Un flux à 22,05 kHz ne porte aucune énergie au-dessus de 11 025 Hz.")
print()
print("  ESTIMATEUR : FFT PLEIN CLIP, pas le périodogramme de Welch de")
print("  band_profile. Welch redistribue au prorata par-dessus la frontière")
print("  d'octave 8k/16k, qui tombe à 11 314 Hz et non à 11 025 : il rendait")
print("  0,7 point de plus, et le document publiait l'autre chiffre. Les deux")
print("  estimateurs ne peuvent pas cohabiter dans le dossier de preuve.")
print("  La colonne pondérée A applique la courbe d'IEC 61672 — une fonction")
print("  normalisée, qui n'est TOUJOURS PAS un verdict d'écoute (ISS-004).")
print()

def _poids_a(f):
    if f <= 0.0:
        return 0.0
    f2 = f * f
    num = (12194.0 ** 2) * (f2 ** 2)
    den = ((f2 + 20.6 ** 2)
           * math.sqrt((f2 + 107.7 ** 2) * (f2 + 737.9 ** 2))
           * (f2 + 12194.0 ** 2))
    return (10.0 ** ((20.0 * math.log10(num / den) + 2.00) / 20.0)) ** 2

def part_exacte(ech, rate, seuil):
    """Intégrale exacte, sans fenêtre : FFT du clip entier zéro-paddé."""
    n = 1
    while n < len(ech):
        n *= 2
    spec = bp.fft([complex(v, 0.0) for v in ech] + [0j] * (n - len(ech)))
    df = rate / float(n)
    haut = haut_a = tot = tot_a = 0.0
    for k in range(n // 2 + 1):
        p = abs(spec[k]) ** 2 * (2.0 if 0 < k < n // 2 else 1.0)
        f = k * df
        w = _poids_a(f)
        tot += p
        tot_a += p * w
        if f > seuil:
            haut += p
            haut_a += p * w
    return (100.0 * haut / tot if tot else 0.0,
            100.0 * haut_a / tot_a if tot_a else 0.0)

print("  %-18s %14s %16s" % ("son", "> 11 025 Hz", "pondérée A"))
for f in ("amb_valley","step_grass_a","step_grass_b","step_grass_c",
          "step_stone_a","hit_taken","death"):
    e, r = bp.lire_wav("assets/audio/sfx/%s.wav" % f)
    ex, ea = part_exacte(e, r, 11025.0)
    print("  %-18s %13.2f %% %15.2f %%" % (f, ex, ea))

print()
print("=" * 72)
print("MESURE 3 — OCCUPATION SPECTRALE DE LA BANQUE LIVRÉE")
print("=" * 72)
print("Un son « occupe » une bande s'il y met >= 20 %% de son énergie.")
buf = io.StringIO()
old = sys.stdout; sys.stdout = buf
bp.main(["--csv"] + ["assets/audio/sfx/%s" % n for n in sorted(__import__("os").listdir("assets/audio/sfx")) if n.endswith(".wav")])
sys.stdout = old
rows = list(csv.DictReader(io.StringIO(buf.getvalue())))
for b in [k for k in rows[0] if k.startswith("b_")]:
    # `r[b]` peut être VIDE depuis le 2026-08-31 : une bande au-dessus du
    # Nyquist du fichier n'a pas de valeur. Aucun des 21 assets n'est concerné
    # aujourd'hui — tous sont à 44,1 kHz — mais le premier fichier à 22,05 kHz
    # ferait lever un ValueError ici. Le garde coûte une condition.
    occ = [r["fichier"].replace(".wav","") for r in rows
           if r["fichier"] != "amb_valley.wav" and r[b] and float(r[b]) >= 20.0]
    print("  %-6s %2d   %s" % (b[2:], len(occ), ", ".join(occ) or "— libre —"))
lourds = [r for r in rows if r["fichier"] != "amb_valley.wav"
          and float(r["masquage_125_500"]) >= 75.0]
print("  Sons dont >= 75 %% de l'énergie tient dans 125-500 Hz : %d sur 20" % len(lourds))

print()
print("=" * 72)
print("MESURE 4 — SENSIBILITÉ DE L'ESTIMATEUR (amb_valley, 125-500 Hz)")
print("=" * 72)
ech, rate = bp.lire_wav("assets/audio/sfx/amb_valley.wav")
print("  %10s %10s %10s %12s" % ("segment", "Hz/raie", "segments", "125-500 %"))
# L'AMPLITUDE EST CALCULÉE, PAS RECOPIÉE. Elle était écrite en dur à
# « +-0,6 point » ; après la correction du recouvrement du 2026-08-31 la table
# n'en montre plus que 0,28, et la phrase était devenue fausse sous sa propre
# table. Un document cite des chemins et des symboles, jamais un nombre —
# CLAUDE.md, règle d'ancrage.
_vus = []
for L in (1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072):
    bp.SEGMENT_MAX = L; bp.SEGMENT_MIN = min(256, L)
    p = bp.profil(ech, rate)
    _vus.append(p["masquage"])
    print("  %10d %10.2f %10d %12.2f" % (p["L"], p["df"], p["segments"], p["masquage"]))
_amp = max(_vus) - min(_vus)
print("  Amplitude mesurée sur un rapport 128x de longueur de segment :")
print("  %.2f point (de %.2f à %.2f)." % (_amp, min(_vus), max(_vus)))
print("  L'écart avec la contre-revue (54,8 %%) vaut %.1fx cette amplitude :"
      % (abs(54.8 - sum(_vus) / len(_vus)) / _amp if _amp else float("inf")))
print("  il est DÉFINITIONNEL, pas du bruit d'estimateur.")
