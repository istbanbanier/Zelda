## La face que le solveur supprime est-elle la face DEGENEREE ?
## Pur Python sur le GLB : aucune dependance a Blender, donc un chemin de
## mesure independant de celui qui a produit le constat.
import sys, math
sys.path.insert(0, "/home/user/zelda-r2a354/a_percee/tools")
from cave_void_connectivity import charger_triangles
CIBLE = (-1.504, -3.099, -0.639)   # centroide de la face supprimee par le booleen
for nom, ch in (
    ("3 decime", "evidence/world_v2/v2_3_r2a/grotte/r2a354_percee/etapes/etape_3_decime.glb"),
    ("4 soustrait", "evidence/world_v2/v2_3_r2a/grotte/r2a354_percee/etapes/etape_4_soustrait.glb"),
    ("cc3596c5", "/tmp/ref354/SM_WaterfallCave_cc3596c5.glb"),
    ("c184c8dc", "assets/environment/caves/SM_WaterfallCave.glb"),
    ("R2a-3.4", "/home/user/zelda-r2a354/reference/SM_WaterfallCave_R2a34.glb"),
):
    tris = charger_triangles(ch)
    petites = []
    for a, b, c in tris:
        u = [b[i] - a[i] for i in range(3)]
        v = [c[i] - a[i] for i in range(3)]
        n = (u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0])
        aire = 0.5 * math.sqrt(sum(t*t for t in n))
        if aire < 1e-9:
            ce = tuple(sum(p[i] for p in (a, b, c))/3.0 for i in range(3))
            petites.append((aire, ce))
    print("%-12s %6d triangles, %d d'aire < 1e-9" % (nom, len(tris), len(petites)))
    for aire, ce in sorted(petites)[:4]:
        d = math.dist(ce, CIBLE)
        print("      aire %.3e  centre (%.3f, %.3f, %.3f)  distance a la face "
              "supprimee : %.4f m%s" % (aire, ce[0], ce[1], ce[2], d,
                                        "   <-- MEME FACE" if d < 1e-3 else ""))
