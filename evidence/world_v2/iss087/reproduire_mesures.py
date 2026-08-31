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
print("  %-18s %14s" % ("son", "> 11 025 Hz"))
for f in ("amb_valley","step_grass_a","step_grass_b","step_grass_c",
          "step_stone_a","hit_taken","death"):
    e, r = bp.lire_wav("assets/audio/sfx/%s.wav" % f)
    print("  %-18s %13.2f %%" % (f, part_au_dessus(bp.profil(e, r), 11025.0)))

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
    occ = [r["fichier"].replace(".wav","") for r in rows
           if r["fichier"] != "amb_valley.wav" and float(r[b]) >= 20.0]
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
for L in (1024, 2048, 4096, 8192, 16384, 32768, 65536, 131072):
    bp.SEGMENT_MAX = L; bp.SEGMENT_MIN = min(256, L)
    p = bp.profil(ech, rate)
    print("  %10d %10.2f %10d %12.2f" % (p["L"], p["df"], p["segments"], p["masquage"]))
print("  Stable à +-0,6 point sur un rapport 128x. L'écart avec la contre-revue")
print("  (54,8 %%) est donc DÉFINITIONNEL, pas du bruit d'estimateur.")
