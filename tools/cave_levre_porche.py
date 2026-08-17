#!/usr/bin/env python3
"""L'ÉPAISSEUR DE LA LÈVRE DU PORCHE — la géométrie LIVRÉE l'a-t-elle aussi ?

POURQUOI CET OUTIL EXISTE
=========================
Le gate de coque à deux seuils place son argmin en `(-2,465 ; -1,798 ; -0,586)`,
soit 0,65 m DEVANT la lèvre du porche et 0,18 m au-delà de la bouche dérivée. Il
y lit une épaisseur de quelques centimètres et rend `FAIL`.

Or l'instrument précédent portait déjà la phrase juste : « au REBORD MÊME de la
bouche l'épaisseur tend vers zéro : c'est une arête, pas un défaut ». Là où la
peau intérieure et la peau extérieure se rejoignent, leur distance tend vers 0
par géométrie. Un critère qui l'ignore condamne toute grotte pourvue d'une
bouche.

LA SEULE QUESTION QUI TRANCHE — et c'est celle qui a déjà résolu le contrôle de
domaine, dont les 326 plaques sur la référence contre 167 sur le sujet l'avaient
disqualifié comme juge :

    **La géométrie LIVRÉE et visuellement validée porte-t-elle la même lèvre
    mince que le candidat ?**

Si oui, le critère condamne la référence plus fort que le sujet et ne peut pas
décider seul. Si non, le candidat porte un vrai défaut.

CE QUE CET OUTIL MESURE, ET CE QU'IL NE MESURE PAS
==================================================
Il ne refait pas le gate. Il mesure une grandeur **locale, bornée et comparable**
entre deux maillages : pour chaque sommet situé dans une boîte autour du porche,
la distance à la face NON ADJACENTE la plus proche. Sur une lèvre, cette distance
est l'épaisseur de la lèvre ; ailleurs, elle majore l'épaisseur locale.

Ce n'est PAS la distance euclidienne à la peau extérieure du contrat : elle ne
distingue pas intérieur et extérieur, et elle peut lire la corde d'un pli plutôt
qu'une épaisseur. **Elle ne sert donc à aucun verdict.** Elle sert à comparer
deux maillages sur la MÊME grandeur, dans la MÊME boîte, ce qui est exactement ce
qu'il faut pour savoir si un critère condamne sa propre référence.

LE PIÈGE DU GLB, déjà payé deux fois dans cette série
=====================================================
Un GLB range par matériau : les sommets sont dupliqués aux coutures. Sans
soudure par position, deux faces cousues paraîtraient « non adjacentes » et
rendraient une épaisseur nulle partout. On soude donc d'abord.

Et le fichier porte DEUX maillages : `SM_WaterfallCave` (visuel) et
`COL_WaterfallCave` (coque de collision, un tube plein). Les mesurer ensemble a
déjà fait conclure qu'un défaut n'existait pas. On ne prend que le visuel, et on
le dit.
"""

import json
import math
import os
import struct
import sys
from collections import defaultdict

TAILLE = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
FMT = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I", 5126: "f"}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def lire_glb(chemin):
    with open(chemin, "rb") as f:
        data = f.read()
    magic, _, _ = struct.unpack_from("<III", data, 0)
    if magic != 0x46546C67:
        raise SystemExit("pas un GLB : %s" % chemin)
    off, js, bin_ = 12, None, None
    while off < len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        corps = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:
            js = json.loads(corps.decode("utf-8"))
        elif ctype == 0x004E4942:
            bin_ = corps
        off += 8 + clen + ((4 - clen % 4) % 4 if clen % 4 else 0)
    return js, bin_


def accesseur(js, bin_, idx):
    acc = js["accessors"][idx]
    nc = NCOMP[acc["type"]]
    ct = acc["componentType"]
    vue = js["bufferViews"][acc["bufferView"]]
    base = vue.get("byteOffset", 0) + acc.get("byteOffset", 0)
    pas = vue.get("byteStride") or TAILLE[ct] * nc
    return [struct.unpack_from("<" + FMT[ct] * nc, bin_, base + i * pas)
            for i in range(acc["count"])]


def charger(chemin, nom_noeud):
    """Sommets soudés par position + faces, pour UN noeud nommé."""
    js, bin_ = lire_glb(chemin)
    cible = None
    for n in js.get("nodes", []):
        if "mesh" in n and n.get("name") == nom_noeud:
            cible = n
    if cible is None:
        noms = [n.get("name") for n in js.get("nodes", []) if "mesh" in n]
        raise SystemExit("noeud %r absent ; presents : %s" % (nom_noeud, noms))
    cle_de, sommets, faces = {}, [], []
    for prim in js["meshes"][cible["mesh"]]["primitives"]:
        pos = accesseur(js, bin_, prim["attributes"]["POSITION"])
        idx = [i[0] for i in accesseur(js, bin_, prim["indices"])]
        local = []
        for p in pos:
            k = (round(p[0], 6), round(p[1], 6), round(p[2], 6))
            if k not in cle_de:
                cle_de[k] = len(sommets)
                sommets.append((p[0], p[1], p[2]))
            local.append(cle_de[k])
        for t in range(0, len(idx), 3):
            faces.append((local[idx[t]], local[idx[t + 1]], local[idx[t + 2]]))
    return sommets, faces


def dist_point_triangle(p, a, b, c):
    """Distance exacte point -> triangle, régions de Voronoï.

    Écrite UNE fois : la leçon de parité de `tools/CLAUDE.md` est que redériver
    une lecture géométrique par branche, c'est se tromper dans une branche sur
    deux.
    """
    ab = [b[i] - a[i] for i in range(3)]
    ac = [c[i] - a[i] for i in range(3)]
    ap = [p[i] - a[i] for i in range(3)]
    d1 = sum(ab[i] * ap[i] for i in range(3))
    d2 = sum(ac[i] * ap[i] for i in range(3))
    if d1 <= 0 and d2 <= 0:
        return math.dist(p, a)
    bp = [p[i] - b[i] for i in range(3)]
    d3 = sum(ab[i] * bp[i] for i in range(3))
    d4 = sum(ac[i] * bp[i] for i in range(3))
    if d3 >= 0 and d4 <= d3:
        return math.dist(p, b)
    vc = d1 * d4 - d3 * d2
    if vc <= 0 <= d1 and d3 <= 0:
        t = d1 / (d1 - d3) if d1 != d3 else 0.0
        return math.dist(p, [a[i] + t * ab[i] for i in range(3)])
    cp = [p[i] - c[i] for i in range(3)]
    d5 = sum(ab[i] * cp[i] for i in range(3))
    d6 = sum(ac[i] * cp[i] for i in range(3))
    if d6 >= 0 and d5 <= d6:
        return math.dist(p, c)
    vb = d5 * d2 - d1 * d6
    if vb <= 0 <= d2 and d6 <= 0:
        t = d2 / (d2 - d6) if d2 != d6 else 0.0
        return math.dist(p, [a[i] + t * ac[i] for i in range(3)])
    va = d3 * d6 - d5 * d4
    if va <= 0 and (d4 - d3) >= 0 and (d5 - d6) >= 0:
        t = (d4 - d3) / ((d4 - d3) + (d5 - d6))
        return math.dist(p, [b[i] + t * (c[i] - b[i]) for i in range(3)])
    den = va + vb + vc
    v, w = vb / den, vc / den
    return math.dist(p, [a[i] + ab[i] * v + ac[i] * w for i in range(3)])


def _grille_xy(sommets, faces, pas):
    """Index (ix, iy) -> faces, pour les rayons verticaux de parite."""
    cases = defaultdict(list)
    for k, f in enumerate(faces):
        tri = [sommets[s] for s in f]
        x0 = min(t[0] for t in tri); x1 = max(t[0] for t in tri)
        y0 = min(t[1] for t in tri); y1 = max(t[1] for t in tri)
        for ix in range(int(math.floor(x0 / pas)), int(math.floor(x1 / pas)) + 1):
            for iy in range(int(math.floor(y0 / pas)), int(math.floor(y1 / pas)) + 1):
                cases[(ix, iy)].append(k)
    return cases


def dans_la_roche(p, sommets, faces, cases, pas):
    """Parite d'un rayon VERTICAL montant : impair -> le point est DANS la roche.

    La lecture de parite est ecrite UNE fois, ici, et pas redérivée par
    appelant : `tools/CLAUDE.md` consigne trois verdicts faux causes par
    exactement cette redérivation.
    """
    ix = int(math.floor(p[0] / pas)); iy = int(math.floor(p[1] / pas))
    n = 0
    for k in cases.get((ix, iy), ()):
        a, b, c = (sommets[s] for s in faces[k])
        ## intersection rayon +Z avec le triangle, en coordonnees
        ## barycentriques 2D sur (x, y)
        d = ((b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1]))
        if abs(d) < 1e-14:
            continue
        u = ((b[1] - c[1]) * (p[0] - c[0]) + (c[0] - b[0]) * (p[1] - c[1])) / d
        v = ((c[1] - a[1]) * (p[0] - c[0]) + (a[0] - c[0]) * (p[1] - c[1])) / d
        w = 1.0 - u - v
        if u < 0 or v < 0 or w < 0:
            continue
        z = u * a[2] + v * b[2] + w * c[2]
        if z > p[2]:
            n += 1
    return (n % 2) == 1


def mesurer(chemin, boite, anneau, pas_grille=0.5, RANGS=3,
            OPPOSITION=-0.30):
    sommets, faces = charger(chemin, "SM_WaterfallCave")
    cases_xy = _grille_xy(sommets, faces, 0.5)
    (x0, x1, y0, y1, z0, z1) = boite

    def dans(p):
        return x0 <= p[0] <= x1 and y0 <= p[1] <= y1 and z0 <= p[2] <= z1

    ## Faces retenues : celles dont au moins un sommet est dans la boîte
    ## ÉLARGIE de `anneau`, pour qu'un sommet du bord trouve bien son
    ## vis-à-vis. Sans cet anneau, l'épaisseur serait surestimée au bord de
    ## la boîte — et une boîte qui fabrique ses propres minima ne compare rien.
    gx0, gx1 = x0 - anneau, x1 + anneau
    gy0, gy1 = y0 - anneau, y1 + anneau
    gz0, gz1 = z0 - anneau, z1 + anneau

    def dans_large(p):
        return gx0 <= p[0] <= gx1 and gy0 <= p[1] <= gy1 and gz0 <= p[2] <= gz1

    f_ret = [f for f in faces if any(dans_large(sommets[s]) for s in f)]
    s_ret = [i for i, p in enumerate(sommets) if dans(p)]

    ## DEUX EXCLUSIONS, ET LA PREMIÈRE SEULE NE SUFFIT PAS — mesuré.
    ##
    ## Première version : n'écarter que les faces INCIDENTES au sommet. Elle
    ## rend une médiane de 0,098 m sur les deux maillages et « 321 sommets sur
    ## 321 sous 0,80 m » sur la géométrie LIVRÉE ET VALIDÉE. Ce n'était pas une
    ## épaisseur : c'était la LONGUEUR D'ARÊTE. Une face à deux triangles de là
    ## n'est pas incidente, et se trouve à une maille de distance.
    ##
    ## Il faut donc, ensemble :
    ##   * écarter un VOISINAGE TOPOLOGIQUE de `anneaux` rangs, pas seulement
    ##     les faces incidentes ;
    ##   * n'accepter qu'une face dont la normale S'OPPOSE à celle du sommet.
    ##     L'épaisseur, c'est la distance à la surface d'EN FACE ; une face
    ##     coplanaire ou faiblement inclinée est la même paroi vue de côté.
    ##
    ## Le second critère est le vrai discriminant : sans lui, un pli concave
    ## rendrait sa corde comme si c'était une lame.
    voisines = defaultdict(set)
    for k, f in enumerate(f_ret):
        for s in f:
            voisines[s].add(k)
    sommets_de = defaultdict(set)
    for k, f in enumerate(f_ret):
        for s in f:
            sommets_de[k].add(s)

    def anneau_de(si, rangs):
        vus = set(voisines.get(si, ()))
        front = set(vus)
        for _ in range(max(0, rangs - 1)):
            suivant = set()
            for k in front:
                for s in sommets_de[k]:
                    suivant |= voisines.get(s, set())
            suivant -= vus
            vus |= suivant
            front = suivant
        return vus

    def normale(tri):
        u = [tri[1][i] - tri[0][i] for i in range(3)]
        v = [tri[2][i] - tri[0][i] for i in range(3)]
        n = [u[1] * v[2] - u[2] * v[1],
             u[2] * v[0] - u[0] * v[2],
             u[0] * v[1] - u[1] * v[0]]
        m = math.sqrt(sum(c * c for c in n)) or 1.0
        return [c / m for c in n]

    n_face = [normale([sommets[s] for s in f]) for f in f_ret]
    n_sommet = {}
    for si in s_ret:
        acc = [0.0, 0.0, 0.0]
        for k in voisines.get(si, ()):
            for i in range(3):
                acc[i] += n_face[k][i]
        m = math.sqrt(sum(c * c for c in acc)) or 1.0
        n_sommet[si] = [c / m for c in acc]

    inc = {si: anneau_de(si, RANGS) for si in s_ret}

    cases = defaultdict(list)
    for k, f in enumerate(f_ret):
        tri = [sommets[s] for s in f]
        cx0 = min(t[0] for t in tri); cx1 = max(t[0] for t in tri)
        cy0 = min(t[1] for t in tri); cy1 = max(t[1] for t in tri)
        cz0 = min(t[2] for t in tri); cz1 = max(t[2] for t in tri)
        for ix in range(int(cx0 // pas_grille), int(cx1 // pas_grille) + 1):
            for iy in range(int(cy0 // pas_grille), int(cy1 // pas_grille) + 1):
                for iz in range(int(cz0 // pas_grille), int(cz1 // pas_grille) + 1):
                    cases[(ix, iy, iz)].append(k)

    resultats = []
    for si in s_ret:
        p = sommets[si]
        nv = n_sommet[si]
        interdit = inc.get(si, set())
        meilleure = float("inf")
        rayon = pas_grille
        while rayon <= anneau + pas_grille:
            vus = set()
            r = int(rayon // pas_grille) + 1
            bx, by, bz = (int(p[0] // pas_grille), int(p[1] // pas_grille),
                          int(p[2] // pas_grille))
            for ix in range(bx - r, bx + r + 1):
                for iy in range(by - r, by + r + 1):
                    for iz in range(bz - r, bz + r + 1):
                        vus.update(cases.get((ix, iy, iz), ()))
            for k in vus - interdit:
                ## la face doit REGARDER VERS NOUS : c'est ce qui distingue
                ## une surface d'en face d'une continuation de la meme paroi.
                if sum(n_face[k][i] * nv[i] for i in range(3)) > OPPOSITION:
                    continue
                tri = [sommets[s] for s in f_ret[k]]
                d = dist_point_triangle(p, *tri)
                if d >= meilleure:
                    continue
                ## LE TEST QUI REND LA MESURE DECISIVE : le segment doit
                ## traverser de la ROCHE, pas de l'air. Sans lui, deux parois
                ## qui se font face de part et d'autre d'une OUVERTURE
                ## rendraient la largeur du trou comme si c'etait une
                ## epaisseur. Mesure du 2026-08-17 : sans ce test, la
                ## geometrie livree rendait 321 sommets sur 321 sous 0,80 m.
                proche = None
                for fk in (0.5,):
                    milieu = [p[i] + fk * ((sum(t[i] for t in tri) / 3.0) - p[i])
                              for i in range(3)]
                    proche = dans_la_roche(milieu, sommets, faces, cases_xy, 0.5)
                if not proche:
                    continue
                meilleure = d
            ## On ne s'arrête que si le meilleur trouvé tient DANS le rayon
            ## déjà balayé : sinon un vis-à-vis plus proche pourrait vivre
            ## dans la couronne suivante.
            if meilleure <= rayon:
                break
            rayon += pas_grille
        if meilleure < float("inf"):
            resultats.append((meilleure, p))
    resultats.sort(key=lambda t: t[0])
    return resultats, len(s_ret), len(f_ret)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    if not args:
        print("usage : cave_levre_porche.py <a.glb> <b.glb> ...")
        print("        --boite=x0,x1,y0,y1,z0,z1   (defaut : le porche)")
        print("        --anneau=1.5   --pas=0.5   --montre=8")
        sys.exit(2)

    def opt(nom, defaut):
        for a in sys.argv[1:]:
            if a.startswith("--%s=" % nom):
                return a.split("=", 1)[1]
        return defaut

    boite = tuple(float(v) for v in opt(
        "boite", "-4.0,4.0,-2.6,0.2,-1.5,3.0").split(","))
    anneau = float(opt("anneau", "1.5"))
    pas = float(opt("pas", "0.5"))
    montre = int(opt("montre", "8"))
    rangs = int(opt("rangs", "3"))
    oppo = float(opt("opposition", "-0.30"))

    print("=== EPAISSEUR LOCALE DANS LA BOITE DU PORCHE ===")
    print("  boite   x [%.2f ; %.2f]  ay [%.2f ; %.2f]  z [%.2f ; %.2f]"
          % boite)
    print("  anneau de recherche %.2f m, grille %.2f m, %d rang(s) exclus,"
          " opposition de normale < %.2f" % (anneau, pas, rangs, oppo))
    print("  maillage mesure : SM_WaterfallCave SEUL (jamais COL_)")
    print("  NB : distance a la face NON ADJACENTE la plus proche. Sert a")
    print("       COMPARER deux maillages sur la meme grandeur, jamais a")
    print("       prononcer un verdict de contrat.")
    print()
    for chemin in args:
        if not os.path.exists(chemin):
            print("ABSENT : %s" % chemin)
            sys.exit(2)
        res, ns, nf = mesurer(chemin, boite, anneau, pas, rangs, oppo)
        print("--- %s" % os.path.basename(chemin))
        print("    %d sommet(s) dans la boite, %d face(s) retenues" % (ns, nf))
        if not res:
            print("    aucun sommet mesurable")
            continue
        print("    minimum %.4f m   median %.4f m   p90 %.4f m"
              % (res[0][0], res[len(res) // 2][0], res[int(len(res) * 0.9)][0]))
        sous = lambda s: sum(1 for d, _ in res if d < s)
        print("    sous 0,05 m : %d   sous 0,20 m : %d   sous 0,60 m : %d   "
              "sous 0,80 m : %d" % (sous(0.05), sous(0.20), sous(0.60),
                                    sous(0.80)))
        for d, p in res[:montre]:
            print("      %.4f m  en (%.3f ; %.3f ; %.3f)"
                  % (d, p[0], p[1], p[2]))
        print()
    sys.exit(0)
