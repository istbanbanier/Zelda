#!/usr/bin/env python3
"""Décompose un journal Godot --verbose : classes fuitées, chemins de ressource.

Ne fabrique rien : si le journal ne contient pas de ligne « Leaked instance: »,
il l'écrit et sort. Un tableau vide est un résultat, pas un échec silencieux.
"""
import re
import sys
from collections import Counter

chemin = sys.argv[1]
classes = Counter()
chemins = Counter()
avec_chemin = 0
sans_chemin = 0
total = 0
res_en_usage = Counter()

rx = re.compile(r"^Leaked instance: ([A-Za-z0-9_]+):(\d+)(?: - (.*))?$")
rx_res = re.compile(r"^Resource still in use: (.*) \(([A-Za-z0-9_]+)\)$")

with open(chemin, encoding="utf-8", errors="replace") as fh:
    for ligne in fh:
        ligne = ligne.rstrip("\n")
        m = rx.match(ligne)
        if m:
            total += 1
            classes[m.group(1)] += 1
            extra = m.group(3) or ""
            if extra.startswith("Resource path: ") and extra[15:].strip():
                avec_chemin += 1
                chemins[extra[15:].strip()] += 1
            else:
                sans_chemin += 1
            continue
        m2 = rx_res.match(ligne)
        if m2:
            res_en_usage[m2.group(1)] += 1

print("lignes « Leaked instance » : %d" % total)
if total == 0:
    print("AUCUNE — soit le journal n'est pas en --verbose, soit rien n'a fui.")
print("avec resource_path : %d ; sans : %d" % (avec_chemin, sans_chemin))
print("\n-- par classe --")
for k, v in classes.most_common(40):
    print("%8d  %s" % (v, k))
print("\n-- top chemins de ressource fuités --")
for k, v in chemins.most_common(30):
    print("%8d  %s" % (v, k))
print("\n-- « Resource still in use » --")
for k, v in res_en_usage.most_common(40):
    print("%8d  %s" % (v, k))
