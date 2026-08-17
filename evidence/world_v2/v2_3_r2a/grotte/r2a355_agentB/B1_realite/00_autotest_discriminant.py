# -*- coding: utf-8 -*-
"""Auto-test du discriminant exact : chaque cas a une reponse CONNUE."""
import sys
sys.path.insert(0, "tools")
from fractions import Fraction
from cave_exact_intersect import classer_paire

def F(*pts):
    return [tuple(Fraction(c) for c in p) for p in pts]

cas = [
    ("deux triangles tres loin",
     F((0,0,0),(1,0,0),(0,1,0)), F((10,10,10),(11,10,10),(10,11,10)),
     "DISJOINT"),
    ("croix franche (X traverse Y)",
     F((-1,0,0),(1,0,0),(0,0,1)), F((0,-1,0.25),(0,1,0.25),(0,0,0.75)),
     "PENETRATION"),
    ("arete commune, non coplanaires",
     F((0,0,0),(1,0,0),(0,1,0)), F((0,0,0),(1,0,0),(0,0,1)),
     "CONTACT"),
    ("sommet commun seulement",
     F((0,0,0),(1,0,0),(0,1,0)), F((0,0,0),(0,0,1),(-1,0,1)),
     "CONTACT"),
    ("tangence pointe sur face (touche sans entrer)",
     F((0,0,0),(2,0,0),(0,2,0)), F((0.5,0.5,0),(1,1,1),(0,1,1)),
     "CONTACT"),
    ("pointe qui ENTRE de 1 micron",
     F((0,0,0),(2,0,0),(0,2,0)), F((0.5,0.5,-0.000001),(1,1,1),(0,1,1)),
     "PENETRATION"),
    ("plans paralleles distincts",
     F((0,0,0),(1,0,0),(0,1,0)), F((0,0,1),(1,0,1),(0,1,1)),
     "DISJOINT"),   # attrape plus tot par la separation par plan — verdict correct
    ("coplanaires superposes",
     F((0,0,0),(2,0,0),(0,2,0)), F((0.2,0.2,0),(1,0.2,0),(0.2,1,0)),
     "COPLANAIRE"),
    ("triangle degenere (colineaire)",
     F((0,0,0),(1,0,0),(2,0,0)), F((0.5,-1,0),(0.5,1,0),(0.5,0,1)),
     "DEGENERE"),
    ("traversee franche coin dans coin",
     F((0,0,0),(1,0,0),(0,1,0)), F((0.2,0.2,-1),(0.2,0.2,1),(0.9,0.05,0)),
     "PENETRATION"),
]

echecs = 0
for nom, a, b, attendu in cas:
    obtenu, _ = classer_paire(a, b)
    ok = obtenu == attendu
    # symetrie : l'ordre des arguments ne doit rien changer
    inverse, _ = classer_paire(b, a)
    sym = inverse == obtenu
    if not ok or not sym:
        echecs += 1
    print("%-6s %-45s attendu %-20s obtenu %-20s symetrique %s"
          % ("OK" if (ok and sym) else "ECHEC", nom, attendu, obtenu,
             "oui" if sym else "NON (%s)" % inverse))
print("RC=%d" % (1 if echecs else 0))
sys.exit(1 if echecs else 0)
