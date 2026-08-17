## ETENDUE REELLE de l'ouverture. Grossier puis raffine, avec partitionnement
## spatial — sans lui, 120 000 colonnes x 7 000 triangles tourne des heures.
##
## PIEGE QUE JE VIENS DE COMMETTRE : une emprise qui touche le bord de la
## fenetre mesure LA FENETRE, pas le defaut. On elargit jusqu'a ce qu'elle ne
## le touche plus, et on le DIT dans tous les cas.
import sys, math
from collections import defaultdict
sys.path.insert(0, "/home/user/Zelda/tools")
from cave_void_connectivity import charger_triangles, intersections_verticales

Z = 1.50

def balayer(tris, x0, x1, y0, y1, pas):
    nx = int(round((x1-x0)/pas))+1; ny = int(round((y1-y0)/pas))+1
    seaux = defaultdict(list)
    for t in tris:
        tx=[p[0] for p in t]; ty=[p[1] for p in t]
        i0=max(0,int((min(tx)-x0)/pas)); i1=min(nx-1,int((max(tx)-x0)/pas)+1)
        j0=max(0,int((min(ty)-y0)/pas)); j1=min(ny-1,int((max(ty)-y0)/pas)+1)
        if i1<0 or j1<0 or i0>nx-1 or j0>ny-1: continue
        for i in range(i0,i1+1):
            for j in range(j0,j1+1): seaux[(i,j)].append(t)
    trou=[]
    for i in range(nx):
        for j in range(ny):
            p=seaux.get((i,j))
            if not p: continue
            ax=x0+i*pas; ay=y0+j*pas
            zs=intersections_verticales(p,ax,ay)
            haut=[z for z in zs if z>Z]; bas=[z for z in zs if z<=Z]
            if bas and not haut: trou.append((ax,ay))
    return trou, nx*ny

def rapport(nom, trou, x0,x1,y0,y1, pas):
    aire = len(trou)*(pas*100)**2
    print("  %-22s %6d colonnes   aire %9.1f cm2" % (nom, len(trou), aire))
    if not trou: return None
    xs=[p[0] for p in trou]; ys=[p[1] for p in trou]
    bx = (min(xs)-x0 < pas*1.5) or (x1-max(xs) < pas*1.5)
    by = (min(ys)-y0 < pas*1.5) or (y1-max(ys) < pas*1.5)
    print("      emprise x [%.3f ; %.3f]  y [%.3f ; %.3f]" % (min(xs),max(xs),min(ys),max(ys)))
    print("      TOUCHE UN BORD DE FENETRE : x=%s  y=%s  %s"
          % (bx, by, "<<< MESURE TRONQUEE" if (bx or by) else "-> emprise complete"))
    return (min(xs),max(xs),min(ys),max(ys),bx,by)

for chemin, nom in [
    ("/home/user/zelda-r2a354/socle/assets/environment/caves/SM_WaterfallCave.glb", "candidat cc3596c5"),
    ("/home/user/zelda-r2a354/a_percee/assets/environment/caves/SM_WaterfallCave.glb", "agent A c184c8dc"),
    ("/home/user/zelda-r2a354/reference/SM_WaterfallCave_R2a34.glb", "R2a-3.4 livree"),
]:
    tris = charger_triangles(chemin)
    print("=== %s ===" % nom)
    ## grossier, tres large
    X0,X1,Y0,Y1,P = -6.0, 6.0, 2.0, 10.0, 0.05
    trou,_ = balayer(tris, X0,X1,Y0,Y1, P)
    rapport("grossier 50 mm", trou, X0,X1,Y0,Y1, P)
