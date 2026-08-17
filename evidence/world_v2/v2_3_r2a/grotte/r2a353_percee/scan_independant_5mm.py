## GARDE-FOU : « 0 traversee montante » peut aussi vouloir dire « ce point est
## deja AU-DESSUS du massif », ce qui n'est pas un trou. On exige donc qu'il y
## ait de la roche EN DESSOUS : une colonne sans croisement ni au-dessus ni en
## dessous est hors du solide et ne prouve rien.
import sys
sys.path.insert(0, "/home/user/Zelda/tools")
from cave_void_connectivity import charger_triangles, intersections_verticales

for chemin, nom in [
    ("/home/user/zelda-r2a353/socle/assets/environment/caves/SM_WaterfallCave.glb", "candidat cc3596c5"),
    ("/home/user/zelda-r2a353/socle/assets/environment/caves/prototypes/SM_WaterfallCave_BASE352.glb", "BASE352"),
    ("/home/user/zelda-r2a353/reference/SM_WaterfallCave_R2a34.glb", "R2a-3.4 livree"),
]:
    tris = charger_triangles(chemin)
    seau = [t for t in tris
            if min(p[0] for p in t) < 1.4 and max(p[0] for p in t) > -0.2
            and min(p[1] for p in t) < 6.8 and max(p[1] for p in t) > 5.0]
    trou, dalle, hors, autres = [], 0, 0, 0
    Z = 1.50
    for i in range(61):
        for j in range(61):
            ax = 0.468 + i * 0.005
            ay = 5.745 + j * 0.005
            zs = intersections_verticales(seau, ax, ay)
            haut = [z for z in zs if z > Z]
            bas = [z for z in zs if z <= Z]
            if not bas:
                hors += 1                      # colonne hors du solide : ecartee
            elif len(haut) == 0:
                trou.append((ax, ay))          # roche dessous, ciel dessus
            elif len(haut) == 2:
                dalle += 1
            else:
                autres += 1
    print("=== %s ===  3721 colonnes, pas 5 mm, depart z=%.2f" % (nom, Z))
    print("   TROU  (roche dessous, 0 traversee au-dessus) : %d" % len(trou))
    print("   dalle (2 traversees au-dessus)               : %d" % dalle)
    print("   ecartees, hors du solide                     : %d" % hors)
    print("   autre nombre de traversees                   : %d" % autres)
    if trou:
        xs = [p[0] for p in trou]; ys = [p[1] for p in trou]
        print("   >>> EMPRISE : x [%.3f ; %.3f]  y [%.3f ; %.3f]  =  %.0f x %.0f mm"
              % (min(xs), max(xs), min(ys), max(ys),
                 (max(xs)-min(xs))*1000 + 5, (max(ys)-min(ys))*1000 + 5))
