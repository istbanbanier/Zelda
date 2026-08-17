# CARTE DU SOMMET DE L'ENVELOPPE — z du toit, colonne par colonne.
#
# COMPAGNON de `probe_envelope_vs_centerline.py`. Celle-ci dit SI une
# station passe ; celle-ci dit OÙ se trouve la roche haute, ce qui est la
# seule information qui permette de replacer une galerie au lieu de la
# tâtonner. Rayon DESCENDANT depuis z = +50, pas de 1 m, repère Blender.
#
# Lecture : une case sous 3,5 m ne peut porter aucune galerie, la clé de
# la centerline valant 2,85 à 3,08 m et un toit utile commençant vers 1 m.
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python tools/blender/probe_envelope_topmap.py
import sys, os, math
sys.path.insert(0, os.path.abspath("tools/blender"))
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
import probe_envelope_vs_centerline as P

bvh, lo, hi, nf = P._charger(os.path.abspath(
    "assets/environment/caves/prototypes/SM_CaveEnvelope_ProtoA.glb"))
def zsom(x, y):
    d = P._distance(bvh, Vector((x, y, 50.0)), Vector((0.0, 0.0, -1.0)))
    return None if d < 0 else 50.0 - d
print("[carte] sommet de l'enveloppe proto A, pas de 1 m (repere Blender)")
print("     y=  " + " ".join("%5.1f" % y for y in range(-2, 12)))
for xi in range(-6, 9):
    ligne = []
    for y in range(-2, 12):
        z = zsom(float(xi), float(y))
        ligne.append("    ." if z is None else "%5.1f" % z)
    print("x=%3d  %s" % (xi, " ".join(ligne)))
print("")
print("[carte] cle de galerie : ~2,85 a 3,08 m. Une case sous 3,5 ne porte pas de galerie.")
for nom, lignes in (("ANCIENNE", P.TEMOIN), ("NOUVELLE", P.CENTERLINE)):
    vals = []
    for ax, ay, hw, cle, pal in lignes:
        z = zsom(ax, ay)
        vals.append(-99.0 if z is None else z - (pal + cle))
    print("[carte] toit sur proto A, centerline %s : %s" % (
        nom, "  ".join("%+.2f" % v for v in vals)))
