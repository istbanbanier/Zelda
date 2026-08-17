#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""OU SE TROUVE L'ARGMIN D'EPAISSEUR, ET QUEL GENERATEUR Y POSE LA ROCHE.

Cet outil ne juge rien. Il LOCALISE. `tools/cave_check_hull.py` rend un
verdict et un point ; celui-ci prend ce point et repond aux trois questions
qu'un verdict ne repond pas :

  1. DANS QUELLE DIRECTION la roche manque-t-elle ? (zenith ou flanc)
  2. OU tombe le point sur le chemin de la cavite, en LONGUEUR D'ARC ?
  3. QUEL APPEL du generateur pose — ou ne pose pas — la matiere la ?

TROIS PIEGES DE CE DEPOT, TRAITES EXPLICITEMENT
===============================================

1. DEUX MAILLAGES DANS LE GLB. `SM_WaterfallCave` est le visuel ;
   `COL_WaterfallCave` est une coque de collision, un tube plein qui bouche
   la galerie. Les mesurer ensemble a deja fait conclure qu'un defaut
   n'existait pas. On charge donc `SM_WaterfallCave` NOMMEMENT, et le nom
   est imprime.

2. `u` EST UN INDICE DE STATION, PAS UNE DISTANCE. `station_de_cavite(u)`
   interpole entre `CAVITE[floor(u)]` et le suivant : deux stations
   consecutives peuvent etre a 0,35 m ou a 1,15 m l'une de l'autre. Toute
   abscisse publiee ici est donc une LONGUEUR D'ARC `s` en metres, mesuree
   le long de la polyligne depuis la station « seuil » (indice 1), negative
   vers l'exterieur. Les bornes de la calotte sont converties par la MEME
   integration, jamais comparees a une coordonnee.

3. `station_de_cavite` ECRETE : `i = max(0, min(len(CAVITE)-1, floor(u)))`.
   Une demande hors de `[0 ; len-1]` rend silencieusement la station
   extreme. Toute projection qui tombe sur une EXTREMITE de la polyligne est
   donc signalee comme telle, avec le depassement en metres — jamais
   presentee comme une projection ordinaire.

AUCUNE COTE N'EST RECOPIEE
==========================

Le generateur importe `bpy` au niveau module, et Blender n'est pas
necessaire pour ce que l'on mesure ici : `station_de_cavite`,
`normale_de_cavite`, `inclinaison_de_cavite`, `bruit`, `fenetre`,
`le_long`, `phases` et `rochers_calotte_nord` sont des fonctions PURES. On
l'importe donc derriere des bouchons, ce qui garantit que `CAVITE`,
`CAVITE_ASYM`, `ALCOVE`, `MODULES` et les `CALOTTE_*` sont lus a leur
source. Si un bouchon devenait insuffisant, l'import echouerait bruyamment
— jamais en silence sur une valeur perimee.

USAGE
=====
    python3 tools/cave_argmin_localiser.py <fichier.glb> [options]
      --h=0.10          rayon de couverture de l'echantillonnage
      --masque=2.00     emprise geodesique du masque de bouche (m)
      --point=x,y,z     localiser CE point au lieu de chercher l'argmin
      --pas-balayage=0.05
      --profil-module   n'imprime QUE le profil du module de calotte
      --familles        n imprime QUE le balayage des familles de pose
      --autour=x,y,z,r  n imprime QUE le certificat local autour de ce point
      --simuler-azimuts n imprime QUE la prediction par nombre d azimuts
                        (en memoire ; aucun fichier ecrit, aucun seuil touche)

Codes retour : 0 mesure faite · 3 impossible (maillage ouvert, graine dans
la roche, argmin introuvable).
"""

import math
import os
import sys
import types
from collections import deque

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RACINE, "tools"))

import cave_check_mesh as M          # noqa: E402
import cave_check_hull as H          # noqa: E402


# ==========================================================================
# Import du generateur sans Blender — par bouchons, jamais par recopie
# ==========================================================================

def charger_generateur():
    """Importe `make_waterfall_cave` hors Blender.

    Les bouchons ne fournissent que ce que l'IMPORT touche. Rien de ce qui
    suit n'appelle une fonction de Blender : si c'etait le cas, l'erreur
    serait immediate et visible, ce qui est le comportement voulu.
    """
    for nom in ("bpy", "bmesh", "mathutils", "mathutils.bvhtree"):
        if nom in sys.modules:
            continue
        mod = types.ModuleType(nom)
        sys.modules[nom] = mod
    sys.modules["mathutils"].Matrix = object
    sys.modules["mathutils"].Vector = object
    sys.modules["mathutils"].bvhtree = sys.modules["mathutils.bvhtree"]
    sys.modules["mathutils.bvhtree"].BVHTree = object
    sys.modules["bpy"].ops = types.SimpleNamespace()
    sys.modules["bpy"].data = types.SimpleNamespace()
    sys.modules["bpy"].context = types.SimpleNamespace()

    chemin = os.path.join(RACINE, "source_assets", "blender", "environment")
    sys.path.insert(0, chemin)
    import importlib
    gen = importlib.import_module("make_waterfall_cave")
    return gen


# ==========================================================================
# Longueur d'arc le long du chemin de la cavite
# ==========================================================================

class Chemin:
    """La polyligne des stations de `CAVITE`, et son abscisse curviligne.

    `s` a pour origine la station « seuil » (indice `I_SEUIL`), la seule qui
    soit IDENTIQUE entre R2a-3.4 et R2a-3.5.x — donc la seule origine qui
    permette de comparer deux revisions sans comparer un indice a une
    coordonnee. `s` est negatif vers l'exterieur.
    """

    I_SEUIL = 1

    def __init__(self, gen):
        self.gen = gen
        self.pts = [(st[0], st[1]) for st in gen.CAVITE]
        self.n = len(self.pts)
        # longueur cumulee depuis la station 0
        self.cum = [0.0]
        for i in range(1, self.n):
            a, b = self.pts[i - 1], self.pts[i]
            self.cum.append(self.cum[-1] + math.dist(a, b))
        self.s0 = self.cum[self.I_SEUIL]

    def s_de_u(self, u):
        """Abscisse curviligne d'un indice de station eventuellement
        fractionnaire. Rend `(s, ecrete)` : `ecrete` dit que `u` sortait de
        `[0 ; n-1]` et a ete ramene — le contraire d'un silence."""
        ecrete = u < 0.0 or u > self.n - 1
        uu = max(0.0, min(float(self.n - 1), u))
        i = int(math.floor(uu))
        i = min(i, self.n - 2)
        t = uu - i
        s = self.cum[i] + t * (self.cum[i + 1] - self.cum[i]) - self.s0
        return s, ecrete

    def projeter(self, p2):
        """Projete `(x, y)` sur la polyligne.

        Rend un dict : segment, `t` local, `u`, `s`, distance, point
        projete, cote (signe le long de la normale), et surtout
        `sur_extremite` — vrai quand le pied de projection tombe sur une
        extremite de la polyligne, c'est-a-dire quand le point est HORS de
        l'emprise longitudinale du chemin.
        """
        best = None
        for i in range(self.n - 1):
            a, b = self.pts[i], self.pts[i + 1]
            abx, aby = b[0] - a[0], b[1] - a[1]
            l2 = abx * abx + aby * aby
            if l2 <= 0.0:
                continue
            t_libre = ((p2[0] - a[0]) * abx + (p2[1] - a[1]) * aby) / l2
            t = max(0.0, min(1.0, t_libre))
            q = (a[0] + t * abx, a[1] + t * aby)
            d = math.dist(p2, q)
            if best is None or d < best["d"]:
                best = dict(seg=i, t=t, t_libre=t_libre, q=q, d=d)
        u = best["seg"] + best["t"]
        s, ecrete = self.s_de_u(u)
        nx, ny = self.gen.normale_de_cavite(u)
        cote = (p2[0] - best["q"][0]) * nx + (p2[1] - best["q"][1]) * ny
        # Le pied tombe-t-il sur une extremite de la POLYLIGNE (et non d'un
        # segment interne) ? C'est cela, « hors de l'emprise longitudinale ».
        sur_ext = ((best["seg"] == 0 and best["t"] <= 1e-9)
                   or (best["seg"] == self.n - 2 and best["t"] >= 1.0 - 1e-9))
        best.update(u=u, s=s, ecrete=ecrete, cote=cote, sur_extremite=sur_ext)
        return best


# ==========================================================================
# Geometrie de la coque — on emprunte le chemin de `cave_check_hull`
# ==========================================================================

def point_sur_triangle(p, a, b, c):
    """Point du triangle `abc` le plus proche de `p` (Ericson).

    Ce n'est PAS une seconde mesure de distance : `cave_check_hull` reste
    seul juge du minimum. On a seulement besoin du PIED de la distance pour
    en publier la DIRECTION.
    """
    ab = tuple(b[k] - a[k] for k in range(3))
    ac = tuple(c[k] - a[k] for k in range(3))
    ap = tuple(p[k] - a[k] for k in range(3))
    d1 = sum(ab[k] * ap[k] for k in range(3))
    d2 = sum(ac[k] * ap[k] for k in range(3))
    if d1 <= 0.0 and d2 <= 0.0:
        return a
    bp = tuple(p[k] - b[k] for k in range(3))
    d3 = sum(ab[k] * bp[k] for k in range(3))
    d4 = sum(ac[k] * bp[k] for k in range(3))
    if d3 >= 0.0 and d4 <= d3:
        return b
    vc = d1 * d4 - d3 * d2
    if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
        v = d1 / (d1 - d3) if d1 != d3 else 0.0
        return tuple(a[k] + v * ab[k] for k in range(3))
    cp = tuple(p[k] - c[k] for k in range(3))
    d5 = sum(ab[k] * cp[k] for k in range(3))
    d6 = sum(ac[k] * cp[k] for k in range(3))
    if d6 >= 0.0 and d5 <= d6:
        return c
    vb = d5 * d2 - d1 * d6
    if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
        w = d2 / (d2 - d6) if d2 != d6 else 0.0
        return tuple(a[k] + w * ac[k] for k in range(3))
    va = d3 * d6 - d5 * d4
    if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
        den = (d4 - d3) + (d5 - d6)
        w = (d4 - d3) / den if den != 0.0 else 0.0
        return tuple(b[k] + w * (c[k] - b[k]) for k in range(3))
    den = va + vb + vc
    v, w = vb / den, vc / den
    return tuple(a[k] + ab[k] * v + ac[k] * w for k in range(3))


def coque(chemin_glb, h, masque_m, pas_bal):
    """Reconstruit la peau interieure/exterieure par le chemin du contrat.

    Rend un dict, ou leve `RuntimeError` si le contrat impose `BLOQUE`.
    """
    sommets, triangles = M.charger(chemin_glb, "SM_WaterfallCave",
                                   repere="modele")
    positions, faces, _stats = M.souder(sommets, triangles)
    tab = M.aretes(faces)
    adj = M.graphe_dual(faces, tab)

    bl = sum(1 for inc in tab.values() if len(inc) == 1)
    nm = sum(1 for inc in tab.values() if len(inc) > 2)
    print("  maillage : %d faces, %d sommets soudes, "
          "%d bord libre, %d non-manifold" % (len(faces), len(positions),
                                              bl, nm))
    if bl:
        raise RuntimeError("maillage OUVERT : aucune notion de dedans")

    for nom, p in (("MODELE_SALLE", H.SALLE), ("MODELE_NICHE", H.NICHE)):
        w = H.enroulement(positions, faces, p)
        etat = "ROCHE" if abs(w) > 0.5 else "AIR"
        print("  %-13s (%.3f ; %.3f ; %.3f)  enroulement %+.4f -> %s"
              % (nom, p[0], p[1], p[2], w, etat))
        if etat == "ROCHE":
            raise RuntimeError("graine dans la roche — provenance en defaut")

    (x0, y0, z0), (x1, y1, z1) = M.boite(positions)
    hach_tout = H.Hachage(positions, faces, range(len(faces)), 0.5)
    temoins = H.faces_du_dehors(positions, faces)
    _d, f_salle = hach_tout.plus_proche(H.SALLE)
    _d, f_niche = hach_tout.plus_proche(H.NICHE)

    aire_face = [M.aire_triangle(positions[faces[i][0]], positions[faces[i][1]],
                                 positions[faces[i][2]])
                 for i in range(len(faces))]
    aire_totale = sum(aire_face)

    candidats = []
    s = y0 + 0.02
    fin = min(y0 + 9.0, y1 - 0.02)
    while s <= fin:
        for ct in H.contours_du_plan(positions, faces, tab, 1, s):
            ok, cote = H.separe_graine_ciel(adj, ct["aretes"], tab,
                                            f_salle, temoins)
            if not ok or f_niche not in cote:
                continue
            a_int = sum(aire_face[i] for i in cote)
            if a_int >= aire_totale - a_int:
                continue
            candidats.append((a_int, s, ct, cote))
        s += pas_bal
    if not candidats:
        raise RuntimeError("aucune barriere de bouche valide : coque trouee")
    a_int, s_bouche, ct, cote = max(candidats, key=lambda t: t[0])
    print("  bouche derivee : ay = %.3f, perimetre %.3f m, "
          "peau interieure %.2f m2" % (s_bouche, ct["perimetre"], a_int))

    interieur = sorted(cote)
    dedans = set(interieur)
    exterieur = [i for i in range(len(faces)) if i not in dedans]

    bord = set()
    for a in ct["aretes"]:
        for f in tab[a]:
            if f in dedans:
                bord.add(f)
    centres = {i: M.centroide(positions[faces[i][0]], positions[faces[i][1]],
                              positions[faces[i][2]]) for i in interieur}
    dist_g = {f: 0.0 for f in bord}
    file = deque(bord)
    while file:
        f = file.popleft()
        for g in adj[f]:
            if g not in dedans:
                continue
            d = dist_g[f] + math.dist(centres[f], centres[g])
            if d < dist_g.get(g, float("inf")):
                dist_g[g] = d
                file.append(g)

    ech = H.echantillonner(positions, faces, interieur, h)
    hach_ext = H.Hachage(positions, faces, exterieur, 0.5)
    print("  %d echantillons sur la peau interieure (couverture <= h = %.4f)"
          % (len(ech), h))

    meilleur = None
    sous = []
    for (p, fi) in ech:
        dg = dist_g.get(fi, float("inf"))
        if dg < masque_m:
            continue
        d, fe = hach_ext.plus_proche(p)
        if d < H.EPAISSEUR_MIN_M:
            sous.append((d, p, dg))
        if meilleur is None or d < meilleur[0]:
            meilleur = (d, p, fi, fe)
    if meilleur is None:
        raise RuntimeError("le masque a tout ecarte")
    return dict(positions=positions, faces=faces, interieur=interieur,
                sous=sous,
                exterieur=exterieur, hach_ext=hach_ext, argmin=meilleur,
                sous_seuil=len(sous), bouche=s_bouche, dist_g=dist_g)


# ==========================================================================
# La calotte nord, rejouee — QUI pose la roche a cet endroit
# ==========================================================================

def boite_posee(gen, cfg):
    """Boite englobante MAJORANTE de la roche posee.

    `charger_module()` recentre l'origine « au centre en plan, au bas en
    hauteur » — c'est ecrit dans le generateur, et c'est ce qui donne un
    sens a `pose`. La boite native est donc
    `[-ex/2 ; +ex/2] x [-ey/2 ; +ey/2] x [0 ; ez]`, puis mise a l'echelle,
    puis tournee (lacet, tangage, roulis), puis translatee.

    On tourne les HUIT COINS et on prend leur englobante : le resultat
    MAJORE l'emprise reelle. C'est le sens utile — une boite majorante qui
    ne contient pas le point PROUVE que la roche ne le couvre pas, alors
    qu'une boite qui le contient ne prouve rien (le module ne remplit pas
    sa boite).
    """
    ex, ey, ez = (gen.MODULES["R"]["natif"][k] * gen.CALOTTE_ECHELLE[k]
                  for k in range(3))
    cl = math.radians(cfg["lacet"])
    tg = math.radians(cfg["tangage"])
    rl = math.radians(cfg["roulis"])
    # Meme ordre que `poser_rocher` : Rz @ Rx @ Ry.
    def rot(v):
        x, y, z = v
        # Ry
        x, z = x * math.cos(rl) + z * math.sin(rl), -x * math.sin(rl) + z * math.cos(rl)
        # Rx
        y, z = y * math.cos(tg) - z * math.sin(tg), y * math.sin(tg) + z * math.cos(tg)
        # Rz
        x, y = x * math.cos(cl) - y * math.sin(cl), x * math.sin(cl) + y * math.cos(cl)
        return (x, y, z)

    coins = [rot((sx * ex * 0.5, sy * ey * 0.5, sz * ez))
             for sx in (-1, 1) for sy in (-1, 1) for sz in (0, 1)]
    lo = [min(c[k] for c in coins) + cfg["pose"][k] for k in range(3)]
    hi = [max(c[k] for c in coins) + cfg["pose"][k] for k in range(3)]
    return lo, hi


def calotte_posee(gen):
    """Rejoue `rochers_calotte_nord()` et rend les roches avec leur boite."""
    roches = []
    for cfg in gen.rochers_calotte_nord():
        lo, hi = boite_posee(gen, cfg)
        roches.append(dict(nom=cfg["nom"], pose=cfg["pose"], lo=lo, hi=hi,
                           cfg=cfg))
    return roches


def rotation_de(gen, cfg):
    """La rotation de `poser_rocher()` : `Rz(lacet) @ Rx(tangage) @ Ry(roulis)`."""
    cl = math.radians(cfg["lacet"])
    tg = math.radians(cfg["tangage"])
    rl = math.radians(cfg["roulis"])

    def rot(v):
        x, y, z = v
        x, z = (x * math.cos(rl) + z * math.sin(rl),
                -x * math.sin(rl) + z * math.cos(rl))
        y, z = (y * math.cos(tg) - z * math.sin(tg),
                y * math.sin(tg) + z * math.cos(tg))
        x, y = (x * math.cos(cl) - y * math.sin(cl),
                x * math.sin(cl) + y * math.cos(cl))
        return (x, y, z)
    return rot


def module_recentre(gen, cle):
    """Le maillage du kit, charge et recentre COMME `charger_module()`.

    « Origine au centre en plan, au bas en hauteur » — c'est le generateur
    qui l'ecrit, et c'est ce qui donne un sens a `pose`.

    CE QUE CETTE LECTURE NE REFAIT PAS, et il faut le dire : `charger_module`
    soude, rebouche et resout l'auto-intersection par une self-union (volume
    12,84 -> 8,89 m3 sur ce module). La self-union retire la matiere comptee
    DEUX FOIS par des primitives superposees ; elle ne peut pas ajouter de
    surface exterieure. Le SOMMET a l'aplomb d'un point est donc inchange —
    c'est la seule grandeur qu'on lit ici.
    """
    chemin = os.path.join(str(gen.KIT_ROCHES),
                          gen.MODULES[cle]["fichier"] + ".glb")
    s, t = M.charger(chemin, gen.MODULES[cle]["fichier"], repere="modele")
    pos, faces, _st = M.souder(s, t)
    lo, hi = M.boite(pos)
    cx = 0.5 * (lo[0] + hi[0])
    cy = 0.5 * (lo[1] + hi[1])
    bas = lo[2]
    pos = [(p[0] - cx, p[1] - cy, p[2] - bas) for p in pos]
    return pos, faces


def sommet_a_l_aplomb(pos, faces, gen, cfg, x0, y0):
    """`z` le plus haut de la roche posee, sur la verticale `(x0, y0)`.

    Rend `None` si la verticale ne traverse aucun triangle : la roche
    n'apporte alors AUCUNE matiere au-dessus de ce point, ce qui est le
    resultat le plus interessant que cette fonction puisse rendre.
    """
    ech = gen.CALOTTE_ECHELLE
    rot = rotation_de(gen, cfg)
    px, py, pz = cfg["pose"]
    pts = []
    for (vx, vy, vz) in pos:
        q = rot((vx * ech[0], vy * ech[1], vz * ech[2]))
        pts.append((q[0] + px, q[1] + py, q[2] + pz))
    haut = None
    for (ia, ib, ic) in faces:
        a, b, c = pts[ia], pts[ib], pts[ic]
        d = ((b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1]))
        if abs(d) < 1e-12:
            continue
        l1 = ((b[1] - c[1]) * (x0 - c[0]) + (c[0] - b[0]) * (y0 - c[1])) / d
        l2 = ((c[1] - a[1]) * (x0 - c[0]) + (a[0] - c[0]) * (y0 - c[1])) / d
        l3 = 1.0 - l1 - l2
        if l1 < -1e-9 or l2 < -1e-9 or l3 < -1e-9:
            continue
        z = l1 * a[2] + l2 * b[2] + l3 * c[2]
        if haut is None or z > haut:
            haut = z
    return haut


def azimuts_calotte(gen):
    return [gen.CALOTTE_THETA0
            + k * (gen.CALOTTE_THETA1 - gen.CALOTTE_THETA0)
            / max(1, gen.CALOTTE_AZIMUTS - 1)
            for k in range(gen.CALOTTE_AZIMUTS)]


def paroi_au(gen, u, theta_deg):
    """Le POINT DE PAROI que `anneau_interieur()` calcule, au meme endroit
    et par le meme calcul que `rochers_calotte_nord()`. Sert a retrouver
    l'azimut d'un point mesure, jamais a en juger."""
    ax, ay, hw, cle = gen.station_de_cavite(u)
    nx, ny = gen.normale_de_cavite(u)
    i = max(0, min(len(gen.CAVITE_ASYM) - 1, int(math.floor(u))))
    j = min(len(gen.CAVITE_ASYM) - 1, i + 1)
    t = max(0.0, min(1.0, u - i))
    gauche = gen.CAVITE_ASYM[i][0] * (1.0 - t) + gen.CAVITE_ASYM[j][0] * t
    inclinaison = gen.inclinaison_de_cavite(u)
    ph = gen.phases(len(gen.CAVITE), 7.0)
    tf = math.radians(theta_deg)
    uc, v = math.cos(tf), math.sin(tf)
    pousse = (gen.ALCOVE["ampl"]
              * gen.le_long(u, gen.ALCOVE["i0"], gen.ALCOVE["i1"])
              * gen.fenetre(tf, gen.ALCOVE["theta"], gen.ALCOVE["dtheta"])
              * math.exp(-(((v - gen.ALCOVE["v0"]) / gen.ALCOVE["dv"]) ** 2.0)))
    w = max(gen.bruit(tf, ph[i], gen.AMP_INTERIEUR),
            gen.bruit(tf, ph[j], gen.AMP_INTERIEUR))
    n = (hw * gauche * w + pousse) * uc
    z = cle * (max(0.0, v) ** 0.75) * w * (1.0 + inclinaison * uc)
    return (ax + n * nx, ay + n * ny, z), n, z


def azimut_du_point(gen, u, p):
    """Azimut `theta` dont le point de paroi est le plus proche de `p`.

    Balayage a 0,25 degre sur [90 ; 180] — la joue nord. On rend l'ecart
    residuel : s'il est grand, le point n'est PAS sur la paroi de cavite et
    il faut le dire.
    """
    best = None
    th = 90.0
    while th <= 180.0001:
        q, n, z = paroi_au(gen, u, th)
        d = math.dist(p, q)
        if best is None or d < best[0]:
            best = (d, th, q, n, z)
        th += 0.25
    return best


# ==========================================================================

def opt(argv, nom, defaut):
    for a in argv:
        if a.startswith("--%s=" % nom):
            return float(a.split("=", 1)[1])
    return defaut


def profil_module(gen):
    """Hauteur du module de calotte en fonction de la distance a son axe.

    C'est la mesure qui explique tout le reste : le generateur promet une
    couverture egale a la HAUTEUR DE BOITE, et la roche ne remplit pas sa
    boite. Publier ce profil, c'est publier l'ecart entre la promesse et la
    matiere.
    """
    pos, faces = module_recentre(gen, "R")
    ech = gen.CALOTTE_ECHELLE
    print("  module %s a l'echelle de la calotte (%.2f ; %.2f ; %.2f)"
          % (gen.MODULES["R"]["fichier"], ech[0], ech[1], ech[2]))
    print("  hauteur de BOITE : %.3f m"
          % (gen.MODULES["R"]["natif"][2] * ech[2]))
    print("  %-8s %-10s %-10s %-10s" % ("rayon", "mediane", "min", "max"))
    r = 0.0
    while r <= 1.2001:
        hs = []
        for k in range(16):
            th = 2.0 * math.pi * k / 16
            faux = dict(lacet=0.0, tangage=0.0, roulis=0.0, pose=(0.0, 0.0, 0.0))
            z = sommet_a_l_aplomb(pos, faces, gen, faux,
                                  r * math.cos(th), r * math.sin(th))
            hs.append(z if z is not None else 0.0)
        hs.sort()
        print("  %-8.2f %-10.3f %-10.3f %-10.3f"
              % (r, hs[len(hs) // 2], hs[0], hs[-1]))
        r += 0.2


def rayon_de_demi_hauteur(gen):
    """Rayon, en unites de module NON mis a l'echelle, ou la hauteur mediane
    du module tombe sous la MOITIE de sa hauteur de boite.

    C'est le chiffre qui rend le defaut transposable d'une famille a
    l'autre : au-dela de ce rayon, poser une roche « de hauteur h » ne
    couvre plus que la moitie de h. La distance entre deux roches voisines
    doit donc rester sous le DOUBLE de ce rayon, sans quoi le point median
    tombe dans la chute.
    """
    pos, faces = module_recentre(gen, "R")
    hb = max(p[2] for p in pos)
    faux = dict(lacet=0.0, tangage=0.0, roulis=0.0, pose=(0.0, 0.0, 0.0))
    garde = gen.CALOTTE_ECHELLE
    gen.CALOTTE_ECHELLE = (1.0, 1.0, 1.0)
    try:
        r = 0.0
        while r <= 2.0:
            hs = []
            for k in range(16):
                th = 2.0 * math.pi * k / 16
                z = sommet_a_l_aplomb(pos, faces, gen, faux,
                                      r * math.cos(th), r * math.sin(th))
                hs.append(z if z is not None else 0.0)
            hs.sort()
            if hs[len(hs) // 2] < 0.5 * hb:
                return hb, r
            r += 0.05
        return hb, 2.0
    finally:
        gen.CALOTTE_ECHELLE = garde


def familles_de_roches(gen):
    """Toutes les familles de pose, et leur sous-echantillonnage.

    `tools/CLAUDE.md` : « quand un defaut de mesure est trouve dans un
    outil, chercher tout de suite les AUTRES endroits qui font la meme
    mesure ». La calotte n'a jamais recu le correctif d'azimuts de la
    gaine ; cette fonction demande qui d'autre ne l'a pas recu.

    Critere publie, et il est le meme pour toutes : la plus grande distance
    entre deux roches VOISINES d'un meme rang, comparee au DOUBLE du rayon
    de demi-hauteur du module a l'echelle de la famille. Au-dela, le point
    median entre deux roches tombe dans la chute du module.
    """
    hb, r50 = rayon_de_demi_hauteur(gen)
    print("  module R : hauteur de boite native %.3f m" % hb)
    print("  rayon ou la hauteur mediane tombe sous la moitie, a l'echelle"
          " 1,0 : %.3f m" % r50)
    print()
    print("  %-14s %-7s %-8s %-9s %-9s %s"
          % ("famille", "roches", "ech. xy", "2 x r50", "ecart max",
             "verdict"))
    for nom in ("rochers_gaine", "rochers_dos_alcove", "rochers_calotte_nord",
                "rochers_semelle"):
        cfgs = getattr(gen, nom)()
        if not cfgs:
            continue
        rangs = {}
        for cfg in cfgs:
            morceaux = cfg["nom"].rsplit("_", 2)
            cle = morceaux[1] if len(morceaux) == 3 else "0"
            rangs.setdefault(cle, []).append(cfg)
        pire = 0.0
        for _cle, lot in rangs.items():
            lot = sorted(lot, key=lambda c: c["nom"])
            for a, b in zip(lot, lot[1:]):
                pire = max(pire, math.dist(a["pose"][:2], b["pose"][:2]))
        ech = cfgs[0]["ech"]
        if not isinstance(ech, (tuple, list)):
            ech = (ech, ech, ech)
        limite = 2.0 * r50 * ech[0]
        verdict = "OK" if pire <= limite else "SOUS-ECHANTILLONNEE"
        print("  %-14s %-7d %-8.2f %-9.3f %-9.3f %s"
              % (nom.replace("rochers_", ""), len(cfgs), ech[0], limite,
                 pire, verdict))
    print()
    print("  LECTURE. L'ecart max est mesure entre roches VOISINES d'un meme")
    print("  rang, en plan. Il MAJORE le cas reel quand un rang saute une")
    print("  pose (debord sous le minimum) : a lire comme un signal, jamais")
    print("  comme un verdict. Le verdict appartient au portail.")


def simuler_azimuts(gen, cible):
    """Sommet apporte a l'aplomb de `cible` selon `CALOTTE_AZIMUTS`.

    PREDICTION, en memoire, sans ecrire un octet ni toucher un seuil. Les
    globales sont restaurees a l'identique.
    """
    pos, faces = module_recentre(gen, "R")
    garde = gen.CALOTTE_AZIMUTS
    print("  %-9s %-9s %-9s %-11s %-10s %s"
          % ("azimuts", "pas", "roches", "traversees", "sommet", "ep. vert."))
    try:
        for naz in (5, 7, 9, 11, 13):
            gen.CALOTTE_AZIMUTS = naz
            roches = gen.rochers_calotte_nord()
            haut, n = None, 0
            for cfg in roches:
                z = sommet_a_l_aplomb(pos, faces, gen, cfg,
                                      cible[0], cible[1])
                if z is None:
                    continue
                n += 1
                if haut is None or z > haut:
                    haut = z
            pas = ((gen.CALOTTE_THETA1 - gen.CALOTTE_THETA0)
                   / max(1, naz - 1))
            print("  %-9d %-9.2f %-9d %-11d %-10.3f %.3f m"
                  % (naz, pas, len(roches), n, haut if haut else -9.0,
                     (haut - cible[2]) if haut else 0.0))
    finally:
        gen.CALOTTE_AZIMUTS = garde


def detail_du_contour(glb, pas_bal):
    """Le contour de bouche retenu, decompose — boucles, longueurs, emprises.

    POURQUOI CET OUTIL EXISTE. Sur la MEME geometrie, `cave_check_hull.py`
    rend deux bouches selon son `--pas-balayage` :

        pas 0,250 -> ay = -1,615, perimetre 11,978 m, 175 aretes coupees
        pas 0,050 -> ay = -1,765, perimetre 53,756 m, 532 aretes coupees

    Les deux enferment EXACTEMENT 95,19 m2 de peau interieure. Le critere
    de selection — « la plus exterieure des barrieres valides, celle qui
    enferme le plus de cavite » — est donc DEGENERE ici : a aire egale, un
    pas fin decouvre un plan plus exterieur qui coupe le massif entier
    (13,3 x 7,3 m) au lieu de la bouche (4,0 x 3,0 m).

    CE QUE CELA CHANGE POUR LA MESURE : rien, et c'est ce que cet outil
    montre. La distance geodesique du masque ne part QUE des faces bordant
    la peau INTERIEURE (`if f in dedans`). Les aretes supplementaires du
    contour long bordent la peau exterieure et n'entrent jamais dans le
    front de propagation.
    """
    sommets, triangles = M.charger(glb, "SM_WaterfallCave", repere="modele")
    positions, faces, _st = M.souder(sommets, triangles)
    tab = M.aretes(faces)
    adj = M.graphe_dual(faces, tab)
    (x0, y0, z0), (x1, y1, z1) = M.boite(positions)
    hach = H.Hachage(positions, faces, range(len(faces)), 0.5)
    temoins = H.faces_du_dehors(positions, faces)
    _d, f_salle = hach.plus_proche(H.SALLE)
    _d, f_niche = hach.plus_proche(H.NICHE)
    aire_face = [M.aire_triangle(positions[faces[i][0]], positions[faces[i][1]],
                                 positions[faces[i][2]])
                 for i in range(len(faces))]
    aire_totale = sum(aire_face)

    retenu = None
    s = y0 + 0.02
    fin = min(y0 + 9.0, y1 - 0.02)
    while s <= fin:
        for ct in H.contours_du_plan(positions, faces, tab, 1, s):
            ok, cote = H.separe_graine_ciel(adj, ct["aretes"], tab,
                                            f_salle, temoins)
            if not ok or f_niche not in cote:
                continue
            a_int = sum(aire_face[i] for i in cote)
            if a_int >= aire_totale - a_int:
                continue
            if retenu is None or a_int > retenu[0]:
                retenu = (a_int, s, ct, cote)
        s += pas_bal
    if retenu is None:
        print("  aucune barriere valide.")
        return
    a_int, s_b, ct, cote = retenu
    dedans = set(cote)
    (b0, b1) = ct["boite"]
    print("  pas de balayage      : %.3f m" % pas_bal)
    print("  plan retenu          : ay = %.3f" % s_b)
    print("  perimetre publie     : %.3f m" % ct["perimetre"])
    print("  aretes coupees       : %d" % len(ct["aretes"]))
    print("  peau interieure      : %d faces, %.2f m2" % (len(cote), a_int))
    print("  emprise du contour   : x[%.3f ; %.3f]  az[%.3f ; %.3f]"
          % (b0[0], b1[0], b0[2], b1[2]))
    print("     soit %.2f m de large sur %.2f m de haut"
          % (b1[0] - b0[0], b1[2] - b0[2]))
    print()
    # DECOMPOSITION : quelles aretes touchent reellement la peau interieure ?
    bord_int = set()
    aretes_int = 0
    for a in ct["aretes"]:
        touche = [f for f in tab[a] if f in dedans]
        if touche:
            aretes_int += 1
            bord_int.update(touche)
    print("  DECOMPOSITION DES ARETES DU CONTOUR :")
    print("     bordant la peau INTERIEURE : %d  -> %d face(s) de depart"
          % (aretes_int, len(bord_int)))
    print("     bordant la peau EXTERIEURE seule : %d  -> IGNOREES par le"
          % (len(ct["aretes"]) - aretes_int))
    print("        front geodesique du masque, qui ne part que des faces")
    print("        `dedans`. C'est ce qui rend la mesure d'epaisseur")
    print("        INSENSIBLE au choix du contour.")
    print()
    # Emprise des seules faces de depart : la vraie bouche.
    pts = []
    for f in bord_int:
        for k in faces[f]:
            pts.append(positions[k])
    if pts:
        print("  emprise des FACES DE DEPART (la bouche effective) :")
        print("     x[%.3f ; %.3f]  ay[%.3f ; %.3f]  az[%.3f ; %.3f]"
              % (min(p[0] for p in pts), max(p[0] for p in pts),
                 min(p[1] for p in pts), max(p[1] for p in pts),
                 min(p[2] for p in pts), max(p[2] for p in pts)))
        print("     soit %.2f m de large sur %.2f m de haut"
              % (max(p[0] for p in pts) - min(p[0] for p in pts),
                 max(p[2] for p in pts) - min(p[2] for p in pts)))


def certificat_local(glb, centre, rayon, h, masque_m, pas_bal):
    """Epaisseur minimale AUTOUR d'un point, a un `h` fin.

    Pourquoi une mesure locale : un `h` de 0,05 m sur toute la peau coute
    quatre fois le budget d'un `h` de 0,10, pour une question qui ne porte
    que sur un voisinage. Le contrat le prevoit explicitement — « si la zone
    indecidable est petite, elle se raffine localement, bien moins couteux
    que de raffiner partout ».

    Le raffinement N'AFFAIBLIT AUCUN SEUIL : il resserre la borne, qui reste
    `lecture - h`. Un `h` plus petit rend la borne PLUS exigeante a lecture
    egale, jamais l'inverse.
    """
    c = coque(glb, h, masque_m, pas_bal)
    positions, faces = c["positions"], c["faces"]
    proches = []
    for (d, p, dg) in c["sous"]:
        if math.dist(p, centre) <= rayon:
            proches.append((d, p))
    # `sous` ne porte que les echantillons SOUS le seuil ; pour un certificat
    # il faut le minimum LOCAL, meme s'il est au-dessus. On rebalaie donc la
    # peau interieure du voisinage.
    hach_ext = c["hach_ext"]
    ech = H.echantillonner(positions, faces, c["interieur"], h)
    mini, arg = None, None
    n = 0
    for (p, fi) in ech:
        if math.dist(p, centre) > rayon:
            continue
        if c["dist_g"].get(fi, float("inf")) < masque_m:
            continue
        n += 1
        d, _fe = hach_ext.plus_proche(p)
        if mini is None or d < mini:
            mini, arg = d, p
    print("  centre  : (%.3f ; %.3f ; %.3f)   rayon %.2f m" % (centre + (rayon,)))
    print("  h       : %.4f m  (borne = lecture - h)" % h)
    print("  echantillons dans le voisinage : %d" % n)
    if mini is None:
        print("  >>> AUCUN echantillon : le voisinage est hors coque, ou")
        print("      entierement sous le masque de bouche.")
        return
    print("  lecture locale : %.4f m" % mini)
    print("  borne garantie : %.4f m" % (mini - h))
    print("  argmin local   : (%.3f ; %.3f ; %.3f)" % arg)
    print("  echantillons locaux sous %.2f m : %d"
          % (H.EPAISSEUR_MIN_M, len(proches)))
    print()
    print("  cible de robustesse de la passe : lecture >= 0,90 m et borne")
    print("  >= 0,85 m. Seuil CONTRACTUEL, inchange : 0,80 m.")
    if mini - h >= 0.85:
        print("  >>> CIBLE DE ROBUSTESSE ATTEINTE localement.")
    elif mini - h >= H.EPAISSEUR_MIN_M:
        print("  >>> seuil contractuel tenu localement, cible de robustesse")
        print("      NON atteinte : conforme mais fragile.")
    else:
        print("  >>> seuil contractuel NON tenu localement.")


def cartographier(sous, gen, ch, rayon=0.50):
    """Distribution des echantillons sous le seuil : groupes ou disperses ?

    « Corriger celui-ci decouvrira le suivant » est la difference entre
    reparer un point et reparer un defaut. Un nuage compact autour d'un
    meme sous-echantillonnage se corrige d'un coup ; une dispersion sur
    toute la coque est un autre probleme.

    Le groupement est une agglomeration simple : deux echantillons a moins
    de `rayon` l'un de l'autre sont du meme amas. On publie aussi la
    distance GEODESIQUE au contour de bouche de chaque amas — c'est la
    grandeur que l'addendum du masque utilise pour classer COLLERETTE
    (seuil 0,60) contre COQUE (seuil 0,80). On ne PRESUPPOSE aucune
    classification : on donne la matiere pour la croiser quand elle
    existera.
    """
    if not sous:
        print("  aucun echantillon sous le seuil.")
        return
    print("  %d echantillons sous %.2f m (en LECTURE)"
          % (len(sous), H.EPAISSEUR_MIN_M))
    print()
    print("  histogramme des lectures :")
    tranches = [(0.0, 0.2), (0.2, 0.4), (0.4, 0.6), (0.6, 0.7), (0.7, 0.8)]
    for lo, hi in tranches:
        n = sum(1 for (d, _p, _g) in sous if lo <= d < hi)
        barre = "#" * min(60, int(60.0 * n / max(1, len(sous))))
        print("     [%.2f ; %.2f)  %5d  %s" % (lo, hi, n, barre))
    print()
    xs = [p[0] for (_d, p, _g) in sous]
    ys = [p[1] for (_d, p, _g) in sous]
    zs = [p[2] for (_d, p, _g) in sous]
    print("  emprise : x[%.2f ; %.2f]  ay[%.2f ; %.2f]  az[%.2f ; %.2f]"
          % (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
    print()

    # Agglomeration par grille : deux echantillons a moins de `rayon` sont
    # du meme amas. La grille evite le O(n^2) sans changer le resultat.
    cell = rayon
    cases = {}
    for i, (_d, p, _g) in enumerate(sous):
        cle = tuple(int(math.floor(p[k] / cell)) for k in range(3))
        cases.setdefault(cle, []).append(i)
    parent = list(range(len(sous)))

    def trouver(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for cle, lot in cases.items():
        voisins = []
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                for dk in (-1, 0, 1):
                    voisins.extend(cases.get((cle[0] + di, cle[1] + dj,
                                              cle[2] + dk), ()))
        for i in lot:
            for j in voisins:
                if j <= i:
                    continue
                if math.dist(sous[i][1], sous[j][1]) <= rayon:
                    ri, rj = trouver(i), trouver(j)
                    if ri != rj:
                        parent[ri] = rj

    amas = {}
    for i in range(len(sous)):
        amas.setdefault(trouver(i), []).append(i)
    lots = sorted(amas.values(), key=len, reverse=True)
    print("  amas (agglomeration a %.2f m) : %d" % (rayon, len(lots)))
    print("  %-6s %-7s %-8s %-26s %-9s %s"
          % ("amas", "pts", "%", "centre (x ; ay ; az)", "min lect.",
             "geod. bouche"))
    couvert = 0
    for k, lot in enumerate(lots[:8]):
        cx = sum(sous[i][1][0] for i in lot) / len(lot)
        cy = sum(sous[i][1][1] for i in lot) / len(lot)
        cz = sum(sous[i][1][2] for i in lot) / len(lot)
        dmin = min(sous[i][0] for i in lot)
        gmin = min(sous[i][2] for i in lot)
        gmax = max(sous[i][2] for i in lot)
        couvert += len(lot)
        print("  %-6d %-7d %-8.1f (%6.2f ; %6.2f ; %6.2f)     %-9.4f "
              "%.2f-%.2f m"
              % (k, len(lot), 100.0 * len(lot) / len(sous), cx, cy, cz,
                 dmin, gmin, gmax))
    if len(lots) > 8:
        reste = len(sous) - couvert
        print("  ... %d amas de plus, %d points (%.1f %%)"
              % (len(lots) - 8, reste, 100.0 * reste / len(sous)))
    print()
    gros = 100.0 * len(lots[0]) / len(sous)
    print("  le plus gros amas porte %.1f %% des echantillons sous seuil."
          % gros)
    if gros > 60.0:
        print("  >>> GROUPES. Un seul defaut domine ; le corriger devrait")
        print("      emporter l'essentiel.")
    elif gros > 25.0:
        print("  >>> PARTIELLEMENT GROUPES. Un defaut dominant, et une")
        print("      queue qu'il faudra traiter separement.")
    else:
        print("  >>> DISPERSES. Corriger l'argmin ne reglera pas le fond.")
    print()
    print("  RAPPEL. Sous l'addendum du masque, les echantillons proches de")
    print("  la bouche relevent de la COLLERETTE et n'exigent que 0,60 m.")
    print("  La colonne « geod. bouche » est la grandeur du classement ;")
    print("  elle est publiee BRUTE, sans qu'aucun classement soit")
    print("  presuppose ici.")


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    if not args:
        print(__doc__)
        return 3
    glb = args[0]
    h = opt(argv, "h", 0.10)
    masque_m = opt(argv, "masque", 2.00)
    pas_bal = opt(argv, "pas-balayage", 0.05)
    point_force = None
    for a in argv:
        if a.startswith("--point="):
            point_force = tuple(float(v) for v in
                                a.split("=", 1)[1].split(","))

    print("=" * 76)
    print("LOCALISATION DE L'ARGMIN D'EPAISSEUR — projection, direction,")
    print("generateur responsable. Cet outil ne rend AUCUN verdict.")
    print("=" * 76)
    print("fichier : %s" % glb)
    print("sha256  : %s        <- lu AVANT la mesure" % H.empreinte(glb))
    print("maillage mesure : SM_WaterfallCave  (COL_WaterfallCave, la coque")
    print("   de collision qui BOUCHE la galerie, est exclue nommement)")
    print("h = %.4f m   masque = %.2f m   pas de balayage = %.3f m"
          % (h, masque_m, pas_bal))
    print()

    gen = charger_generateur()
    if "--profil-module" in argv:
        print("--- PROFIL DU MODULE DE CALOTTE ---")
        profil_module(gen)
        return 0
    if "--familles" in argv:
        print("--- LES FRERES : qui d'autre est sous-echantillonne ? ---")
        familles_de_roches(gen)
        return 0
    if "--contour" in argv:
        print("--- LE CONTOUR DE BOUCHE, DECOMPOSE ---")
        detail_du_contour(glb, pas_bal)
        return 0
    if any(a.startswith("--autour=") for a in argv):
        for a in argv:
            if a.startswith("--autour="):
                v = [float(x) for x in a.split("=", 1)[1].split(",")]
        print("--- CERTIFICAT LOCAL, h fin autour d'un point ---")
        certificat_local(glb, (v[0], v[1], v[2]),
                         v[3] if len(v) > 3 else 1.00, h, masque_m, pas_bal)
        return 0
    if any(a.startswith("--simuler-azimuts") for a in argv):
        cible = point_force or (1.036, 5.173, 2.316)
        print("--- SIMULATION (aucun fichier ecrit, aucun seuil touche) ---")
        print("  cible : (%.3f ; %.3f ; %.3f)" % cible)
        simuler_azimuts(gen, cible)
        return 0
    print("--- generateur charge hors Blender ---")
    print("  CAVITE : %d stations, de ay = %.2f a ay = %.2f"
          % (len(gen.CAVITE), gen.CAVITE[0][1], gen.CAVITE[-1][1]))
    print("  CALOTTE_U0 = %.2f   CALOTTE_U1 = %.2f   (INDICES de station)"
          % (gen.CALOTTE_U0, gen.CALOTTE_U1))
    print("  CALOTTE_THETA0 = %.1f deg  THETA1 = %.1f deg  AZIMUTS = %d"
          % (gen.CALOTTE_THETA0, gen.CALOTTE_THETA1, gen.CALOTTE_AZIMUTS))
    print()

    ch = Chemin(gen)
    print("--- le chemin, en LONGUEUR D'ARC ---")
    print("  origine s = 0 : station %d (le seuil), la seule identique"
          % ch.I_SEUIL)
    print("  %-4s %-9s %-9s %-9s" % ("u", "ax", "ay", "s (m)"))
    for i in range(ch.n):
        s, _e = ch.s_de_u(float(i))
        print("  %-4d %-9.3f %-9.3f %+9.3f" % (i, ch.pts[i][0], ch.pts[i][1], s))
    s_c0, e0 = ch.s_de_u(gen.CALOTTE_U0)
    s_c1, e1 = ch.s_de_u(gen.CALOTTE_U1)
    print("  emprise de la calotte, CONVERTIE (jamais comparee a un ay) :")
    print("     u = %.2f -> s = %+.3f m%s" % (gen.CALOTTE_U0, s_c0,
                                              "  ECRETE" if e0 else ""))
    print("     u = %.2f -> s = %+.3f m%s" % (gen.CALOTTE_U1, s_c1,
                                              "  ECRETE" if e1 else ""))
    print("     longueur couverte : %.3f m" % (s_c1 - s_c0))
    print()

    print("--- reconstruction de la coque (contrat §2.1-§2.5) ---")
    try:
        c = coque(glb, h, masque_m, pas_bal)
    except RuntimeError as e:
        print("BLOQUE : %s" % e)
        return 3
    print()

    d, p, fi, fe = c["argmin"]
    if point_force is not None:
        p = point_force
        d, fe = c["hach_ext"].plus_proche(p)
        print("  point IMPOSE par --point ; la face interieure n'est pas")
        print("  celle d'un echantillon.")
    positions, faces = c["positions"], c["faces"]
    a, b, cc = faces[fe]
    pied = point_sur_triangle(p, positions[a], positions[b], positions[cc])
    vec = tuple(pied[k] - p[k] for k in range(3))
    norme = math.dist(p, pied)

    print("=" * 76)
    print("1. L'ARGMIN, ET LA DIRECTION DANS LAQUELLE LA ROCHE MANQUE")
    print("=" * 76)
    print("  argmin (modele)     : (%.3f ; %.3f ; %.3f)   face int. %d"
          % (p[0], p[1], p[2], fi))
    print("  Godot equivalent    : (%.3f ; %.3f ; %.3f)   (gx=ax, gy=az,"
          " gz=-ay)" % (p[0], p[2], -p[1]))
    print("  lecture             : %.4f m   borne = lecture - h = %.4f m"
          % (d, d - h))
    print("  echantillons sous %.2f m en LECTURE : %d"
          % (H.EPAISSEUR_MIN_M, c["sous_seuil"]))
    print()
    print("  point EXTERIEUR le plus proche : (%.3f ; %.3f ; %.3f)  face %d"
          % (pied[0], pied[1], pied[2], fe))
    print("  vecteur argmin -> exterieur    : (%+.3f ; %+.3f ; %+.3f)"
          % vec)
    print("  norme %.4f m" % norme)
    if norme > 1e-9:
        ux, uy, uz = (vec[k] / norme for k in range(3))
        print("  unitaire                       : (%+.3f ; %+.3f ; %+.3f)"
              % (ux, uy, uz))
        print("  part VERTICALE   |z| = %.1f %%   (angle au zenith %.1f deg)"
              % (abs(uz) * 100.0, math.degrees(math.acos(max(-1.0,
                                                             min(1.0, uz))))))
        horiz = math.hypot(ux, uy)
        print("  part HORIZONTALE     = %.1f %%   dont +Y (nord) %+.1f %%"
              % (horiz * 100.0, uy * 100.0))
        verdict = ("ZENITH — couverture" if abs(uz) > 0.71 else
                   "FLANC — emprise laterale" if abs(uz) < 0.42 else
                   "MIXTE — ni franchement zenithal ni franchement lateral")
        print("  >>> DIRECTION DOMINANTE : %s" % verdict)
    print()

    print("=" * 76)
    print("2. PROJECTION SUR LE CHEMIN — en longueur d'arc, jamais en indice")
    print("=" * 76)
    pr = ch.projeter((p[0], p[1]))
    print("  segment le plus proche : stations %d -> %d"
          % (pr["seg"], pr["seg"] + 1))
    print("  parametre local t      : %.4f   (t libre non ecrete : %.4f)"
          % (pr["t"], pr["t_libre"]))
    print("  indice de station u    : %.4f" % pr["u"])
    print("  parametre CUMULE s     : %+.4f m depuis le seuil" % pr["s"])
    print("  pied de projection     : (%.3f ; %.3f)" % pr["q"])
    print("  distance a la courbe   : %.4f m en (x,y) ; %.4f m en 3D"
          % (pr["d"], math.dist(p, (pr["q"][0], pr["q"][1], p[2]))))
    print("  cote (le long de la normale) : %+.3f m  -> joue %s"
          % (pr["cote"], "DROITE (+n)" if pr["cote"] > 0 else "GAUCHE/NORD (-n)"))
    if pr["sur_extremite"]:
        print("  >>> HORS EMPRISE LONGITUDINALE : le pied tombe sur une")
        print("      EXTREMITE de la polyligne. Le point est au-dela de la")
        print("      fin du chemin, et cette projection n'est pas ordinaire.")
    else:
        print("  >>> DANS l'emprise longitudinale du chemin : le pied tombe")
        print("      a l'INTERIEUR du segment, l'ecart est LATERAL.")
    dedans_calotte = gen.CALOTTE_U0 <= pr["u"] <= gen.CALOTTE_U1
    print("  emprise de la calotte en s : [%+.3f ; %+.3f] m ; le point est"
          " a s = %+.3f  -> %s" % (s_c0, s_c1, pr["s"],
                                   "DEDANS" if dedans_calotte else "DEHORS"))
    print()

    print("=" * 76)
    print("3. LE GENERATEUR — qui pose la roche ici, et a quel azimut")
    print("=" * 76)
    dd, th, q, nn, zz = azimut_du_point(gen, pr["u"], p)
    print("  paroi de cavite la plus proche a u = %.4f :" % pr["u"])
    print("     azimut theta = %.2f deg   point (%.3f ; %.3f ; %.3f)"
          % (th, q[0], q[1], q[2]))
    print("     ecart au point mesure : %.4f m" % dd)
    print("     n (deport lateral) = %+.3f m   z de paroi = %.3f m" % (nn, zz))
    if dd < 0.35:
        print("     >>> le point mesure EST sur la paroi interieure de la")
        print("         cavite : c'est bien de la coque, pas du massif isole.")
    else:
        print("     >>> ECART IMPORTANT : le point n'est pas sur la paroi")
        print("         analytique. A interpreter avec prudence.")
    az = azimuts_calotte(gen)
    print("  azimuts REELLEMENT poses par la calotte : %s"
          % ", ".join("%.1f" % a for a in az))
    voisins = sorted(az, key=lambda a: abs(a - th))[:2]
    print("  les deux plus proches de %.2f deg : %.1f et %.1f  (ecarts %.2f"
          " et %.2f deg)" % (th, voisins[0], voisins[1],
                             abs(voisins[0] - th), abs(voisins[1] - th)))
    pas_az = (gen.CALOTTE_THETA1 - gen.CALOTTE_THETA0) / max(
        1, gen.CALOTTE_AZIMUTS - 1)
    corde = 2.0 * abs(nn) * math.sin(math.radians(pas_az) * 0.5)
    print("  pas d'azimut %.1f deg ; a |n| = %.2f m la CORDE entre deux"
          " roches vaut %.3f m" % (pas_az, abs(nn), corde))
    print()

    roches = calotte_posee(gen)
    ex, ey, ez = (gen.MODULES["R"]["natif"][k] * gen.CALOTTE_ECHELLE[k]
                  for k in range(3))
    print("  calotte rejouee : %d roches ; module a l'echelle "
          "%.2f x %.2f x %.2f m" % (len(roches), ex, ey, ez))
    couvrantes = []
    for r in roches:
        ecarts = [max(r["lo"][k] - p[k], p[k] - r["hi"][k]) for k in range(3)]
        couvrantes.append((max(ecarts), r, ecarts))
    couvrantes.sort(key=lambda t: t[0])
    dedans = [t for t in couvrantes if t[0] <= 0.0]
    print("  roches dont la BOITE MAJORANTE contient l'argmin : %d"
          % len(dedans))
    print("  %-22s %-9s %-9s %-9s %-9s" % ("les 6 plus proches", "ecart x",
                                           "ecart y", "ecart z", "pire"))
    for (pire, r, ec) in couvrantes[:6]:
        print("  %-22s %+9.3f %+9.3f %+9.3f %+9.3f"
              % (r["nom"], ec[0], ec[1], ec[2], pire))
    print()
    print("  RAPPEL : une boite qui contient le point ne prouve pas que la")
    print("  ROCHE le contient — le module ne remplit pas sa boite. Une")
    print("  boite MAJORANTE qui ne le contient PAS, elle, prouve l'absence.")
    print()

    print("--- ecretage de CALOTTE_PLAFOND_M : mord-il ? ---")
    mord = 0
    total = 0
    # Meme parcours que le generateur, pour compter les ecretages.
    u = gen.CALOTTE_U0
    while u <= gen.CALOTTE_U1 + 1e-6:
        for a in az:
            q2, n2, z2 = paroi_au(gen, u, a)
            if abs(n2) < gen.CALOTTE_DEBORD_MIN_M:
                continue
            total += 1
            if z2 + gen.CALOTTE_COUVERTURE_M > gen.CALOTTE_PLAFOND_M:
                mord += 1
        prochain = min(gen.CALOTTE_U1, u + 0.05)
        avance = 0.0
        while prochain < gen.CALOTTE_U1 and avance < gen.CALOTTE_PAS_M:
            aa = gen.station_de_cavite(u)
            bb = gen.station_de_cavite(prochain)
            avance = math.hypot(bb[0] - aa[0], bb[1] - aa[1])
            if avance < gen.CALOTTE_PAS_M:
                prochain = min(gen.CALOTTE_U1, prochain + 0.05)
        if prochain >= gen.CALOTTE_U1 and u >= gen.CALOTTE_U1:
            break
        u = prochain
    print("  CALOTTE_PLAFOND_M = %.2f m ; couverture visee %.2f m"
          % (gen.CALOTTE_PLAFOND_M, gen.CALOTTE_COUVERTURE_M))
    print("  poses ou le plafond ECRETE la couverture : %d sur %d"
          % (mord, total))
    if mord:
        print("  >>> la butee AGIT. Une butee qui agit sans le dire est")
        print("      exactement la famille de defaut qu'on debusque.")
    else:
        print("  >>> la butee n'agit nulle part : elle n'explique rien ici.")
    print("=" * 76)
    print("4. LA MATIERE EST-ELLE DANS LA SOURCE ? — sommet des roches de")
    print("   calotte a l'APLOMB de l'argmin, avant toute etape de chaine")
    print("=" * 76)
    mpos, mfaces = module_recentre(gen, "R")
    print("  module R (%s) : %d faces, boite %.3f x %.3f x %.3f m"
          % (gen.MODULES["R"]["fichier"], len(mfaces),
             max(q[0] for q in mpos) - min(q[0] for q in mpos),
             max(q[1] for q in mpos) - min(q[1] for q in mpos),
             max(q[2] for q in mpos) - min(q[2] for q in mpos)))
    sommets = []
    for r in roches:
        z = sommet_a_l_aplomb(mpos, mfaces, gen, r["cfg"], p[0], p[1])
        if z is not None:
            sommets.append((z, r["nom"], r["cfg"]["pose"]))
    sommets.sort(reverse=True)
    print("  roches dont la VERTICALE de l'argmin traverse la geometrie : %d"
          " (sur %d posees)" % (len(sommets), len(roches)))
    for (z, nom, pose) in sommets[:6]:
        print("     %-20s sommet a z = %.3f m   pose (%.2f ; %.2f ; %.2f)"
              % (nom, z, pose[0], pose[1], pose[2]))
    if sommets:
        zmax = sommets[0][0]
        print("  SOMMET LE PLUS HAUT apporte par la calotte : %.3f m" % zmax)
        print("  surface EXTERIEURE mesuree sur le GLB       : %.3f m"
              % pied[2])
        print("  argmin                                      : %.3f m" % p[2])
        print("  epaisseur que la SOURCE promet a la verticale : %.3f m"
              % (zmax - p[2]))
        print("  epaisseur MESUREE (euclidienne, toutes directions) : %.3f m"
              % d)
        if zmax - p[2] < H.EPAISSEUR_MIN_M:
            print("  >>> LA SOURCE NE POSE PAS ASSEZ. La chaine n'a rien")
            print("      rabote : la matiere n'a jamais ete la.")
        else:
            print("  >>> LA SOURCE POSE ASSEZ. Une etape de chaine retire")
            print("      donc la matiere — a attribuer sous Blender.")
    else:
        print("  >>> AUCUNE roche de calotte ne couvre cette verticale.")
        print("      La cause est un TROU DE POSE, pas une couverture mince.")
    print()
    print("=" * 76)
    print("5. LES %d ECHANTILLONS SOUS LE SEUIL — sont-ils GROUPES ou"
          % c["sous_seuil"])
    print("   DISPERSES ? Corriger un point n'est pas corriger un defaut.")
    print("=" * 76)
    cartographier(c["sous"], gen, ch)
    print()
    print("=" * 76)
    print("Mesure faite. Aucun verdict rendu ici — voir cave_check_hull.py.")
    print("=" * 76)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
