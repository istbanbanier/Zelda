#!/usr/bin/env python3
"""Quels vides du massif communiquent avec la GALERIE JOUABLE ?

POURQUOI CET OUTIL EXISTE
=========================
La passe R2a-3.5.3 mesure 167 « plaques » de roche sous 0,80 m sur le candidat,
232 sur BASE352 et davantage encore sur la geometrie LIVREE. Le seuil
`EPAISSEUR_MIN_M` est le meme pour toutes, et aucune ne le tient sur le domaine
complet.

Mais toutes ces plaques ne disent pas la meme chose :

  * une lame mince au-dessus d'un vide RELIE A LA GALERIE est a une decimation
    d'etre un trou dans un espace ou le joueur se tient ;
  * une lame mince au-dessus d'une BULLE ISOLEE dans le massif est un defaut de
    contrat qui ne peut produire aucun symptome visible.

Sans cette distinction, « 167 plaques » et « 326 plaques » sont des nombres qui
ne repondent a aucune question. Avec elle, l'arbitrage du niveau a viser devient
tractable.

CE QUI REND LA MESURE POSSIBLE AUJOURD'HUI, ET PAS HIER
=======================================================
`tools/cave_topology_check.py` etablit que les trois maillages sont FERMES —
zero arete de bord. J'avais ecrit le contraire au handoff §30.1, et cette erreur
servait d'excuse a l'indetermination. Sur un maillage ferme, la parite d'un
rayon est une lecture VALIDE de dedans/dehors, et la connexite se calcule.

DEUX PIEGES, TOUS DEUX PAYES PAR QUELQU'UN
==========================================
1. Le `.glb` contient DEUX maillages : `SM_WaterfallCave` (visuel) et
   `COL_WaterfallCave`, une coque de collision qui REBOUCHE la galerie. Mesurer
   les deux ensemble rend « 3,06 m de roche continue » la ou il y en a 0,038, et
   fait conclure que le defaut n'existe pas. C'est l'erreur que l'agent A a
   commise, tracee et publiee. On filtre.
2. La lecture de parite s'ecrit UNE fois, dans une fonction nommee. Trois
   verdicts faux avant un juste ont ete payes pour l'apprendre
   (`tools/CLAUDE.md`).

REPERE
======
On travaille dans le repere MODELE, celui que citent les mesures et le
generateur : `ax = gx`, `ay = -gz`, `az = gy`. Vertical = `az`.
"""

import json
import math
import os
import struct
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

PAS = 0.10               # pas de grille, metrique et documente
VIDE_QUALIFIANT = 1.00   # hauteur minimale pour qu'un vide compte, cf. agent A
EPS = 1e-9

## Reperes de gameplay, en coordonnees GODOT telles qu'ecrites dans
## `scripts/world_v2/poi/waterfall_cave_place.gd` a `c79341e`.
GODOT_SALLE = (2.62, 0.09, -2.58)
GODOT_NICHE = (2.78, 0.50, -4.09)


def godot_vers_modele(g):
    """(gx, gy, gz) -> (ax, ay, az). Inverse de (ax, az, -ay)."""
    return (g[0], -g[2], g[1])


# ---------------------------------------------------------------- lecture GLB

TAILLE = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}
FMT = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I", 5126: "f"}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def lire_glb(chemin):
    with open(chemin, "rb") as f:
        data = f.read()
    magic, _, _ = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67, "pas un GLB"
    off, js, binv = 12, None, None
    while off < len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        corps = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:
            js = json.loads(corps.decode("utf-8"))
        elif ctype == 0x004E4942:
            binv = corps
        off += 8 + clen + ((4 - clen % 4) % 4 if clen % 4 else 0)
    return js, binv


def accesseur(js, binv, idx):
    acc = js["accessors"][idx]
    nc, ct = NCOMP[acc["type"]], acc["componentType"]
    vue = js["bufferViews"][acc["bufferView"]]
    base = vue.get("byteOffset", 0) + acc.get("byteOffset", 0)
    pas = vue.get("byteStride") or TAILLE[ct] * nc
    return [struct.unpack_from("<" + FMT[ct] * nc, binv, base + i * pas)
            for i in range(acc["count"])]


def charger_triangles(chemin, noeud_voulu="SM_WaterfallCave"):
    """Triangles du SEUL maillage voulu, en repere MODELE.

    Le filtre n'est pas une option de confort : sans lui la coque de collision
    rebouche la galerie et toute mesure d'epaisseur devient fausse.
    """
    js, binv = lire_glb(chemin)
    tris = []
    trouve = False
    for noeud in js.get("nodes", []):
        if "mesh" not in noeud or noeud.get("name") != noeud_voulu:
            continue
        trouve = True
        for prim in js["meshes"][noeud["mesh"]]["primitives"]:
            pos = accesseur(js, binv, prim["attributes"]["POSITION"])
            idx = [i[0] for i in accesseur(js, binv, prim["indices"])]
            mod = [(p[0], -p[2], p[1]) for p in pos]     # GLB -> MODELE
            for t in range(0, len(idx), 3):
                tris.append((mod[idx[t]], mod[idx[t + 1]], mod[idx[t + 2]]))
    if not trouve:
        raise SystemExit("noeud '%s' absent de %s — on n'invente pas un maillage"
                         % (noeud_voulu, chemin))
    return tris


# ------------------------------------------------------- parite, ecrite UNE fois

def intersections_verticales(tris_cellule, ax, ay):
    """Altitudes `az` ou la verticale en (ax, ay) traverse un triangle.

    Rendues TRIEES. Pas de notion de dedans/dehors ici : cette fonction ne fait
    que compter des croisements, et c'est `intervalles()` qui les lit.
    """
    zs = []
    for (a, b, c) in tris_cellule:
        ## coordonnees barycentriques dans le plan (ax, ay)
        d = ((b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1]))
        if abs(d) < EPS:
            continue
        u = ((b[1] - c[1]) * (ax - c[0]) + (c[0] - b[0]) * (ay - c[1])) / d
        v = ((c[1] - a[1]) * (ax - c[0]) + (a[0] - c[0]) * (ay - c[1])) / d
        w = 1.0 - u - v
        if u < -1e-9 or v < -1e-9 or w < -1e-9:
            continue
        zs.append(u * a[2] + v * b[2] + w * c[2])
    zs.sort()
    return zs


def intervalles_de_vide(zs):
    """Intervalles d'AIR *interieurs au modele*, du haut vers le bas.

    LA LECTURE, ECRITE UNE FOIS. Le rayon descend depuis le ciel, donc il part
    dans l'air. Croisement 1 -> il ENTRE dans la roche. Croisement 2 -> il en
    sort. Donc, en indexant depuis le HAUT :

        [z0, z1] roche · [z1, z2] AIR · [z2, z3] roche · ...

    Un nombre IMPAIR de croisements signifie que la course finit DANS LA ROCHE
    — le cas d'un rocher plante dans le terrain, et le plus sur.
    """
    hauts = list(reversed(zs))            # du plus haut au plus bas
    vides = []
    for i in range(1, len(hauts) - 1, 2):
        bas, haut = hauts[i + 1], hauts[i]
        if haut - bas > EPS:
            vides.append((bas, haut))
    return vides


# --------------------------------------------------------------- programme

def main():
    if len(sys.argv) < 2:
        raise SystemExit("usage: cave_void_connectivity.py <fichier.glb> [--pas P]")
    chemin = sys.argv[1]
    pas = PAS
    if "--pas" in sys.argv:
        pas = float(sys.argv[sys.argv.index("--pas") + 1])

    tris = charger_triangles(chemin)
    print("triangles (visuel seul) : %d" % len(tris))

    xs = [p[0] for t in tris for p in t]
    ys = [p[1] for t in tris for p in t]
    x0, x1 = math.floor(min(xs) / pas) * pas, math.ceil(max(xs) / pas) * pas
    y0, y1 = math.floor(min(ys) / pas) * pas, math.ceil(max(ys) / pas) * pas
    nx = int(round((x1 - x0) / pas)) + 1
    ny = int(round((y1 - y0) / pas)) + 1
    print("domaine  : ax [%.2f ; %.2f]  ay [%.2f ; %.2f]  pas %.2f  -> %d colonnes"
          % (x0, x1, y0, y1, pas, nx * ny))

    ## bucketing par cellule (ax, ay) : sans lui, 30 000 colonnes x 20 000
    ## triangles est irrealisable en Python pur
    seaux = defaultdict(list)
    for tri in tris:
        tx = [p[0] for p in tri]
        ty = [p[1] for p in tri]
        i0 = max(0, int((min(tx) - x0) / pas))
        i1 = min(nx - 1, int((max(tx) - x0) / pas) + 1)
        j0 = max(0, int((min(ty) - y0) / pas))
        j1 = min(ny - 1, int((max(ty) - y0) / pas) + 1)
        for i in range(i0, i1 + 1):
            for j in range(j0, j1 + 1):
                seaux[(i, j)].append(tri)

    ## intervalles de vide par colonne
    vides = {}
    for i in range(nx):
        for j in range(ny):
            paquet = seaux.get((i, j))
            if not paquet:
                continue
            ax, ay = x0 + i * pas, y0 + j * pas
            v = intervalles_de_vide(intersections_verticales(paquet, ax, ay))
            if v:
                vides[(i, j)] = v
    total = sum(len(v) for v in vides.values())
    print("colonnes portant du vide : %d   intervalles : %d" % (len(vides), total))

    ## union-find sur les intervalles : deux intervalles de colonnes 4-voisines
    ## sont relies s'ils se CHEVAUCHENT en altitude
    cle = {}
    for (i, j), lst in vides.items():
        for k in range(len(lst)):
            cle[(i, j, k)] = len(cle)
    parent = list(range(len(cle)))

    def trouver(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def unir(a, b):
        ra, rb = trouver(a), trouver(b)
        if ra != rb:
            parent[ra] = rb

    for (i, j), lst in vides.items():
        for di, dj in ((1, 0), (0, 1)):
            voisin = vides.get((i + di, j + dj))
            if not voisin:
                continue
            for k, (b1, h1) in enumerate(lst):
                for m, (b2, h2) in enumerate(voisin):
                    if min(h1, h2) - max(b1, b2) > EPS:
                        unir(cle[(i, j, k)], cle[(i + di, j + dj, m)])

    ## graine = l'intervalle qui contient la SALLE
    def localiser(nom, godot):
        ax, ay, az = godot_vers_modele(godot)
        i = int(round((ax - x0) / pas))
        j = int(round((ay - y0) / pas))
        for k, (b, h) in enumerate(vides.get((i, j), [])):
            if b - 0.05 <= az <= h + 0.05:
                print("  %-14s modele (%.2f ; %.2f ; %.2f) -> vide [%.2f ; %.2f]"
                      % (nom, ax, ay, az, b, h))
                return cle[(i, j, k)]
        print("  %-14s modele (%.2f ; %.2f ; %.2f) -> AUCUN vide a cette altitude"
              % (nom, ax, ay, az))
        return None

    ## Les reperes de gameplay ont ete RE-DERIVES a R2a-3.5.2 : les anciens
    ## tombent dans la roche sur la cavite neuve, et — symetriquement — les
    ## nouveaux tombent dans la roche sur la geometrie R2a-3.4. Il faut donc
    ## semer avec les reperes DE LA GEOMETRIE MESUREE. On ne devine pas.
    salle, niche = GODOT_SALLE, GODOT_NICHE
    if "--anciens-reperes" in sys.argv:
        salle, niche = (1.05, 0.22, -6.25), (-1.20, 0.43, -8.20)
        print("reperes de gameplay : jeu ANCIEN (avant re-derivation R2a-3.5.2)")
    else:
        print("reperes de gameplay : jeu COURANT (c79341e)")
    g_salle = localiser("MODELE_SALLE", salle)
    g_niche = localiser("MODELE_NICHE", niche)
    if g_salle is None:
        raise SystemExit("graine introuvable — on ne devine pas la galerie")
    racine_galerie = trouver(g_salle)
    if g_niche is not None:
        meme = trouver(g_niche) == racine_galerie
        print("  niche et salle dans la MEME composante : %s" % ("OUI" if meme else "NON"))

    tailles = defaultdict(int)
    for x in range(len(parent)):
        tailles[trouver(x)] += 1
    print("composantes de vide : %d   la galerie en contient %d intervalle(s)"
          % (len(tailles), tailles[racine_galerie]))

    ## classement des lames minces
    relie = mince_relie = mince_isole = 0
    pires_relie = []
    pires_isole = []
    for (i, j), lst in vides.items():
        ax, ay = x0 + i * pas, y0 + j * pas
        for k, (b, h) in enumerate(lst):
            if h - b < VIDE_QUALIFIANT:
                continue
            ## epaisseur de la roche AU-DESSUS de ce vide
            zs = intersections_verticales(seaux[(i, j)], ax, ay)
            au_dessus = [z for z in zs if z > h - EPS]
            if len(au_dessus) < 2:
                continue                      # ouvert au ciel : pas une lame
            ## DEUX mesures, publiees ensemble — parce qu'un seul nombre
            ## choisirait la reponse avant de mesurer (`tools/CLAUDE.md`).
            ##
            ##  * PREMIERE DALLE : la membrane immediate au-dessus du vide.
            ##    Repond a « y a-t-il une lame fine ici ».
            ##  * CUMUL : toute la roche au-dessus, dalles empilees additionnees.
            ##    Repond a « ce vide voit-il le ciel ». C'est la definition que
            ##    `controle_epaisseur` se donne a lui-meme.
            ##
            ## Les deux different des qu'il existe un second vide plus haut, et
            ## c'est precisement le cas qui distingue une membrane interne d'un
            ## trou vers le dehors.
            premiere = au_dessus[1] - au_dessus[0]
            cumul = sum(au_dessus[n + 1] - au_dessus[n]
                        for n in range(0, len(au_dessus) - 1, 2))
            dans = trouver(cle[(i, j, k)]) == racine_galerie
            if dans:
                relie += 1
            if premiere < 0.80 or cumul < 0.80:
                enr = (premiere, cumul, ax, ay, h - b)
                if dans:
                    mince_relie += 1
                    pires_relie.append(enr)
                else:
                    mince_isole += 1
                    pires_isole.append(enr)

    print()
    print("=== LAMES < 0,80 m AU-DESSUS D'UN VIDE >= %.2f m ===" % VIDE_QUALIFIANT)
    print("  RELIEES a la galerie jouable : %d" % mince_relie)
    print("  sur un vide ISOLE            : %d" % mince_isole)
    print()
    print("  --- LE CHIFFRE QUI DECIDE ---")
    print("  Une lame RELIEE dont le CUMUL tient 0,80 m est une membrane interne :")
    print("  il reste un banc de roche au-dessus. Une lame reliee dont le cumul")
    print("  NE tient pas est de la roche mince entre la galerie et le ciel.")
    rel_ciel = sum(1 for p, c, *_ in pires_relie if c < 0.80)
    rel_memb = sum(1 for p, c, *_ in pires_relie if c >= 0.80)
    iso_ciel = sum(1 for p, c, *_ in pires_isole if c < 0.80)
    print("    reliees, cumul < 0,80 m  (roche mince sur la galerie) : %d" % rel_ciel)
    print("    reliees, cumul >= 0,80 m (membrane interne)           : %d" % rel_memb)
    print("    isolees, cumul < 0,80 m  (bulle interne du massif)    : %d" % iso_ciel)
    for etiquette, lst in (("RELIEES", pires_relie), ("ISOLEES", pires_isole)):
        lst.sort()
        print("  les 6 plus minces %s (par PREMIERE dalle) :" % etiquette)
        for premiere, cumul, ax, ay, hv in lst[:6]:
            print("     premiere %.3f m   cumul %.3f m   en (%6.2f ; %6.2f)   vide %.3f m"
                  % (premiere, cumul, ax, ay, hv))
        if not lst:
            print("     (aucune)")
        else:
            sans_ciel = sum(1 for p, c, *_ in lst if c >= 0.80)
            print("     dont %d ou le CUMUL tient les 0,80 m — membrane interne,"
                  " pas un trou vers le ciel" % sans_ciel)
    return 0


if __name__ == "__main__":
    sys.exit(main())
