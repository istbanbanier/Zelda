# -*- coding: utf-8 -*-
"""ISS-075 — sépare le texte JOUEUR du texte DIAGNOSTIC.
La distinction EST le livrable : traduire un log de moteur serait du bruit,
ne pas traduire un message d'écran serait le défaut."""
import io, os, re, collections, json
import sys
RACINE = sys.argv[1] if len(sys.argv) > 1 else \
    os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ACC = "àâäéèêëîïôöùûüçÀÂÄÉÈÊËÎÏÔÖÙÛÜÇ«»…’œ"
lit = re.compile(r'"([^"\\]*(?:\\.[^"\\]*)*)"')
acc = re.compile("[" + ACC + "]")
DIAG_LIGNE = re.compile(r"push_error|push_warning|printerr|\bprint\b|printt|"
                        r"assert\(|_erreur|problemes\.append|erreurs\.append|"
                        r"problems\.append|check\(|check_equal")
DIAG_TEXTE = re.compile(r"^\s*\[")
# Scènes/scripts qui ne partent jamais dans une partie jouée.
DEV = re.compile(r"^(scripts/tools/|scenes/tests/|tools/|tests/)")

def walk(d, ext):
    for r, _, fs in os.walk(os.path.join(RACINE, d)):
        if "/.godot" in r:
            continue
        for f in fs:
            if f.endswith(ext):
                yield os.path.join(r, f)

joueur = collections.defaultdict(list)
diag = collections.Counter()
dev = collections.Counter()
for ext, dirs in ((".gd", ["scripts"]), (".tscn", ["scenes"]),
                  (".tres", ["resources"])):
    for d in dirs:
        for p in walk(d, ext):
            rel = os.path.relpath(p, RACINE)
            for i, ligne in enumerate(io.open(p, encoding="utf-8"), 1):
                nu = ligne.strip()
                if nu.startswith("#"):
                    continue
                for m in lit.finditer(ligne):
                    s = m.group(1)
                    if len(s) < 3 or not acc.search(s):
                        continue
                    if s.startswith("res://") or s.startswith("user://"):
                        continue
                    if DEV.match(rel):
                        dev[rel] += 1
                    elif DIAG_LIGNE.search(ligne) or DIAG_TEXTE.match(s):
                        diag[rel] += 1
                    else:
                        joueur[rel].append((i, s))

nj = sum(len(v) for v in joueur.values())
print("TEXTE JOUEUR    : %4d littéraux, %d fichiers" % (nj, len(joueur)))
print("TEXTE DIAGNOSTIC: %4d littéraux, %d fichiers" % (sum(diag.values()), len(diag)))
print("HORS BUILD JOUÉ : %4d littéraux, %d fichiers" % (sum(dev.values()), len(dev)))
print()
print("=== TEXTE JOUEUR, par fichier ===")
for rel, v in sorted(joueur.items(), key=lambda kv: -len(kv[1])):
    print("%4d  %s" % (len(v), rel))
if len(sys.argv) > 2:
    json.dump({k: v for k, v in joueur.items()},
              io.open(sys.argv[2], "w", encoding="utf-8"),
              ensure_ascii=False, indent=1)
