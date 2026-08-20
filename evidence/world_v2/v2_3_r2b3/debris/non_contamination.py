#!/usr/bin/env python3
"""Preuve de NON-CONTAMINATION : les douze meshes qui ne sont pas les deux tas
de débris doivent rendre un compte de triangles ET une emprise POSITION
RIGOUREUSEMENT identiques avant et après régénération.

Pourquoi cet outil existe : `export_architecture.sh` sans argument régénère
tous les sujets, et une retouche de `gravats()` n'a aucune raison de bouger la
charpente. Un seul écart ailleurs que sur `SM_Farm_Debris_A/B` invalide la voie.

Le verdict PUBLIE LA TAILLE DE CE QU'IL A EXAMINÉ (tools/CLAUDE.md) : un
« aucune différence » sans « sur N meshes » ne prouve rien.

Usage : python3 non_contamination.py <avant.json> <apres.json>
"""
import json
import sys

DEBRIS = ("SM_Farm_Debris_A", "SM_Farm_Debris_B")


def main():
    avant = {m["mesh"]: m for m in json.load(open(sys.argv[1]))}
    apres = {m["mesh"]: m for m in json.load(open(sys.argv[2]))}
    noms = sorted(set(avant) | set(apres))
    ecarts = 0
    print("%-24s %-28s %-28s %s" % ("mesh", "AVANT tris / emprise",
                                    "APRÈS tris / emprise", "verdict"))
    for nom in noms:
        a, b = avant.get(nom), apres.get(nom)
        if a is None or b is None:
            print("%-24s %-28s %-28s DISPARU/APPARU" % (nom, bool(a), bool(b)))
            ecarts += 1
            continue
        fa = "%4d  %.4f %.4f %.4f" % (a["triangles"], *a["emprise"])
        fb = "%4d  %.4f %.4f %.4f" % (b["triangles"], *b["emprise"])
        if nom in DEBRIS:
            verdict = "PÉRIMÈTRE (changement attendu)"
        elif a["triangles"] == b["triangles"] and a["emprise"] == b["emprise"] \
                and a["min"] == b["min"]:
            verdict = "identique"
        else:
            verdict = "ÉCART — CONTAMINATION"
            ecarts += 1
        print("%-24s %-28s %-28s %s" % (nom, fa, fb, verdict))
    hors = [n for n in noms if n not in DEBRIS]
    print("\n%d mesh(es) comparé(s) hors périmètre, %d écart(s)"
          % (len(hors), ecarts))
    print("=== %s ===" % ("NON CONTAMINÉ" if ecarts == 0 else "CONTAMINÉ"))
    return 0 if ecarts == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
