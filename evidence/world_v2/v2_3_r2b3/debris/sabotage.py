#!/usr/bin/env python3
"""SABOTAGE — controle negatif de R2B.3.

Remplace les fragments `eclat()` par des BOITES DROITES axialement alignees et
neutralise le garde du generateur, pour que le .glb soit reellement reecrit
avec le defaut. Le filet Godot doit alors ROUGIR en nommant le motif.

Le sabotage doit retirer LA CHOSE TESTEE, pas ce qui est en dessous
(tools/CLAUDE.md). Il echoue BRUYAMMENT si un motif est absent : un
str.replace() qui ne trouve rien ne fait rien et ne dit rien.
"""
import sys

CHEMIN = "/home/user/wt_r2b3_a_debris/source_assets/blender/architecture/make_farm_ruins.py"

ANCRE_ECLAT = """    k = max(3, min(7, int(cotes)))
    dx, dy, dz = taille
    locaux = []"""

BOITE = '''    # ---- SABOTAGE : BOITE DROITE, 8 sommets / 12 triangles ----
    dx, dy, dz = taille
    coins = [(sx * dx * 0.5, sy * dy * 0.5, sz * dz * 0.5)
             for sx, sy, sz in ((-1, -1, -1), (1, -1, -1), (1, 1, -1),
                                (-1, 1, -1), (-1, -1, 1), (1, -1, 1),
                                (1, 1, 1), (-1, 1, 1))]
    sommets = [bm.verts.new((centre[0] + p[0], centre[1] + p[1],
                             centre[2] + p[2] + dz * 0.5 + pose))
               for p in coins]
    bas, haut = sommets[:4], sommets[4:]
    faces = [bm.faces.new(tuple(reversed(bas))), bm.faces.new(tuple(haut))]
    for i in range(4):
        j = (i + 1) % 4
        faces.append(bm.faces.new((bas[i], bas[j], haut[j], haut[i])))
    for f in faces:
        f.material_index = materiau_idx
    return faces
    # ---- FIN SABOTAGE ----
''' + ANCRE_ECLAT

ANCRE_GARDE = "            ecarts.extend(controle_gravats(obj))"
GARDE_NEUTRE = ("            controle_gravats(obj)   # SABOTAGE : mesure "
                "publiee, garde neutralise")


def main():
    src = open(CHEMIN, encoding="utf-8").read()
    for motif in (ANCRE_ECLAT, ANCRE_GARDE):
        if motif not in src:
            sys.stderr.write("ECHEC: motif absent, sabotage NON applique\n")
            return 2
    src = src.replace(ANCRE_ECLAT, BOITE, 1)
    src = src.replace(ANCRE_GARDE, GARDE_NEUTRE, 1)
    open(CHEMIN, "w", encoding="utf-8").write(src)
    # RELIRE pour verifier : une modification qu'on n'a pas relue n'en est pas une.
    relu = open(CHEMIN, encoding="utf-8").read()
    ok = ("---- SABOTAGE : BOITE DROITE" in relu
          and "garde neutralise" in relu
          and "ecarts.extend(controle_gravats" not in relu)
    print("SABOTAGE APPLIQUE ET RELU: %s" % ok)
    return 0 if ok else 2


if __name__ == "__main__":
    sys.exit(main())
