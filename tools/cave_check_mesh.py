#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""BRIQUE COMMUNE DE L'AGENT C — lecture GLB, soudure, graphe dual.

CE FICHIER N'EST PAS UN OUTIL. C'est le socle des `cave_check_*.py`, ecrit
pour que la verification de l'agent C ne partage AUCUN code avec l'oracle
principal. Si je reutilisais `cave_oracle_global.py` ou `cave_frame.py`, ma
verification ne vaudrait rien : deux instruments qui partagent leur coeur se
trompent ensemble, et c'est exactement le mecanisme qui a fait passer
`points_interieurs()` pour trois corroborations independantes.

CE QUE CE SOCLE N'EMPLOIE PAS, ET C'EST LA MOITIE DE SON INTERET
================================================================
Aucune grille. Aucun voxel. Aucune parite de rayon. Aucun EDT, aucun
chanfrein, aucun Dijkstra. Aucune station de `CAVITE`, aucun `ay`, aucune
distance a un axe. Les seules primitives sont : la soudure par position, le
graphe dual des faces, l'angle solide signe, et la distance exacte
point-triangle.

LE PIEGE DE LA SOUDURE, paye par deux agents independamment
===========================================================
Un GLB range sa geometrie PAR MATERIAU. Les sommets sont donc DUPLIQUES a
chaque couture de matiere. Compter les aretes sans souder par position rend
des milliers de faux bords libres. On soude, et on le dit.

LE PIEGE DU NOEUD, paye par l'agent A
=====================================
Le GLB porte DEUX maillages. `COL_WaterfallCave` est un proxy de collision
de ~880 faces qui REBOUCHE la galerie : le mesurer rend « 3,06 m de roche
continue » la ou il y en a 0,038. On filtre `SM_WaterfallCave`, et on LEVE
si le noeud est absent — jamais de repli silencieux sur « le premier venu ».

REPERE
======
On lit en repere glTF puis on publie en repere MODELE, celui que citent le
generateur et toutes les mesures de cette serie :

    ax = gx        ay = -gz        az = gy      (vertical = az)
"""

import json
import math
import struct
from collections import defaultdict

# Quantification de la soudure. 1e-6 m = 1 micron : tres au-dessous de toute
# tolerance geometrique du modele, tres au-dessus du bruit float32.
QUANT = 1e-6


# --------------------------------------------------------------------------
# Lecture GLB
# --------------------------------------------------------------------------

_COMPOSANT = {
    5120: ("b", 1),   # byte
    5121: ("B", 1),   # unsigned byte
    5122: ("h", 2),   # short
    5123: ("H", 2),   # unsigned short
    5125: ("I", 4),   # unsigned int
    5126: ("f", 4),   # float
}

_NB_COMPOSANTES = {
    "SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4,
    "MAT2": 4, "MAT3": 9, "MAT4": 16,
}


class ErreurGLB(Exception):
    pass


def _lire_chunks(chemin):
    with open(chemin, "rb") as f:
        data = f.read()
    if len(data) < 12:
        raise ErreurGLB("fichier trop court : %s" % chemin)
    magic, version, _total = struct.unpack_from("<III", data, 0)
    if magic != 0x46546C67:
        raise ErreurGLB("pas un GLB (magic=0x%08X) : %s" % (magic, chemin))
    if version != 2:
        raise ErreurGLB("GLB version %d, attendu 2 : %s" % (version, chemin))
    off = 12
    js = None
    binaire = b""
    while off + 8 <= len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        corps = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:      # 'JSON'
            js = json.loads(corps.decode("utf-8"))
        elif ctype == 0x004E4942:    # 'BIN\0'
            binaire = corps
        off += 8 + clen + ((4 - clen % 4) % 4 if clen % 4 else 0)
    if js is None:
        raise ErreurGLB("aucun chunk JSON : %s" % chemin)
    return js, binaire


def _accesseur(js, binaire, idx):
    """Rend la liste des valeurs d'un accesseur, en respectant le byteStride."""
    acc = js["accessors"][idx]
    nb = acc["count"]
    typ = acc["type"]
    ncomp = _NB_COMPOSANTES[typ]
    fmt, taille = _COMPOSANT[acc["componentType"]]
    if "bufferView" not in acc:
        return [tuple([0] * ncomp) for _ in range(nb)] if ncomp > 1 else [0] * nb
    bv = js["bufferViews"][acc["bufferView"]]
    base = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = bv.get("byteStride") or (taille * ncomp)
    sortie = []
    motif = "<" + fmt * ncomp
    for i in range(nb):
        vals = struct.unpack_from(motif, binaire, base + i * stride)
        sortie.append(vals if ncomp > 1 else vals[0])
    return sortie


def _matrice_noeud(n):
    """Matrice 4x4 du noeud, en liste de 16 (colonne-majeur comme glTF)."""
    if "matrix" in n:
        return list(n["matrix"])
    t = n.get("translation", [0.0, 0.0, 0.0])
    r = n.get("rotation", [0.0, 0.0, 0.0, 1.0])
    s = n.get("scale", [1.0, 1.0, 1.0])
    x, y, z, w = r
    rot = [
        1 - 2 * (y * y + z * z), 2 * (x * y + z * w), 2 * (x * z - y * w),
        2 * (x * y - z * w), 1 - 2 * (x * x + z * z), 2 * (y * z + x * w),
        2 * (x * z + y * w), 2 * (y * z - x * w), 1 - 2 * (x * x + y * y),
    ]
    m = [0.0] * 16
    for c in range(3):
        for l in range(3):
            m[c * 4 + l] = rot[c * 3 + l] * s[c]
    m[12], m[13], m[14] = t
    m[15] = 1.0
    return m


def _mul(a, b):
    """Produit de deux matrices colonne-majeur 4x4 : rend a o b."""
    out = [0.0] * 16
    for c in range(4):
        for l in range(4):
            out[c * 4 + l] = sum(a[k * 4 + l] * b[c * 4 + k] for k in range(4))
    return out


def _applique(m, p):
    x, y, z = p
    return (
        m[0] * x + m[4] * y + m[8] * z + m[12],
        m[1] * x + m[5] * y + m[9] * z + m[13],
        m[2] * x + m[6] * y + m[10] * z + m[14],
    )


def noeuds_disponibles(chemin):
    js, _ = _lire_chunks(chemin)
    return [n.get("name", "<sans nom>") for n in js.get("nodes", [])
            if "mesh" in n]


def charger(chemin, nom_noeud="SM_WaterfallCave", repere="modele"):
    """Charge un noeud nomme et rend (sommets, triangles) en repere demande.

    LEVE si le noeud est absent. Pas de repli silencieux : mesurer
    `COL_WaterfallCave` a la place rendrait un resultat plausible et faux.
    """
    js, binaire = _lire_chunks(chemin)
    noeuds = js.get("nodes", [])

    # Matrices monde : parcours de la hierarchie depuis les racines.
    monde = {}
    scene = js.get("scenes", [{}])[js.get("scene", 0)]
    pile = [(i, [1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0])
            for i in scene.get("nodes", range(len(noeuds)))]
    while pile:
        i, parent = pile.pop()
        m = _mul(parent, _matrice_noeud(noeuds[i]))
        monde[i] = m
        for c in noeuds[i].get("children", []):
            pile.append((c, m))

    cible = None
    for i, n in enumerate(noeuds):
        if n.get("name") == nom_noeud and "mesh" in n:
            cible = i
            break
    if cible is None:
        dispo = [n.get("name", "<sans nom>") for n in noeuds if "mesh" in n]
        raise ErreurGLB(
            "noeud '%s' ABSENT de %s. Noeuds a maillage : %s. "
            "On ne se rabat pas sur un autre : mesurer la coque de collision "
            "rendrait un resultat plausible et faux."
            % (nom_noeud, chemin, dispo))

    m = monde.get(cible, [1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 1.0])
    mesh = js["meshes"][noeuds[cible]["mesh"]]

    sommets = []
    triangles = []
    for prim in mesh.get("primitives", []):
        if prim.get("mode", 4) != 4:
            continue
        base = len(sommets)
        pos = _accesseur(js, binaire, prim["attributes"]["POSITION"])
        for p in pos:
            sommets.append(_applique(m, p))
        if "indices" in prim:
            idx = _accesseur(js, binaire, prim["indices"])
        else:
            idx = list(range(len(pos)))
        for k in range(0, len(idx) - 2, 3):
            triangles.append((base + idx[k], base + idx[k + 1], base + idx[k + 2]))

    if repere == "modele":
        # ax = gx ; ay = -gz ; az = gy
        sommets = [(p[0], -p[2], p[1]) for p in sommets]
    elif repere != "gltf":
        raise ValueError("repere inconnu : %s" % repere)

    return sommets, triangles


# --------------------------------------------------------------------------
# Soudure par position
# --------------------------------------------------------------------------

def souder(sommets, triangles):
    """Fusionne les sommets coincidents et retire les triangles degeneres.

    Rend (positions, faces, stats). `stats` porte le nombre de doublons
    fusionnes et de faces degenerees retirees — deux chiffres qu'il faut
    publier, parce qu'une soudure muette est indistinguable d'une absence de
    soudure.
    """
    carte = {}
    positions = []
    remap = [0] * len(sommets)
    for i, p in enumerate(sommets):
        cle = (round(p[0] / QUANT), round(p[1] / QUANT), round(p[2] / QUANT))
        j = carte.get(cle)
        if j is None:
            j = len(positions)
            carte[cle] = j
            positions.append(p)
        remap[i] = j

    faces = []
    degenerees = 0
    for (a, b, c) in triangles:
        ra, rb, rc = remap[a], remap[b], remap[c]
        if ra == rb or rb == rc or ra == rc:
            degenerees += 1
            continue
        faces.append((ra, rb, rc))

    stats = {
        "sommets_bruts": len(sommets),
        "sommets_soudes": len(positions),
        "doublons_fusionnes": len(sommets) - len(positions),
        "triangles_bruts": len(triangles),
        "triangles_retenus": len(faces),
        "triangles_degeneres": degenerees,
    }
    return positions, faces, stats


# --------------------------------------------------------------------------
# Aretes et graphe dual
# --------------------------------------------------------------------------

def aretes(faces):
    """Table arete -> liste des indices de faces incidentes."""
    tab = defaultdict(list)
    for fi, (a, b, c) in enumerate(faces):
        for u, v in ((a, b), (b, c), (c, a)):
            tab[(u, v) if u < v else (v, u)].append(fi)
    return tab


def graphe_dual(faces, tab_aretes):
    """Adjacence face->faces par les aretes MANIFOLD (exactement 2 faces).

    Les aretes non-manifold sont EXCLUES de l'adjacence : une arete a trois
    faces ne definit pas un voisinage, et les inclure ferait fusionner des
    nappes qui ne se touchent que le long d'une singularite.
    """
    adj = [[] for _ in faces]
    for _a, incidentes in tab_aretes.items():
        if len(incidentes) == 2:
            f, g = incidentes
            adj[f].append(g)
            adj[g].append(f)
    return adj


def composantes_faces(faces, adj):
    """Etiquette chaque face par sa composante connexe dans le graphe dual."""
    etiq = [-1] * len(faces)
    nb = 0
    for depart in range(len(faces)):
        if etiq[depart] != -1:
            continue
        pile = [depart]
        etiq[depart] = nb
        while pile:
            f = pile.pop()
            for g in adj[f]:
                if etiq[g] == -1:
                    etiq[g] = nb
                    pile.append(g)
        nb += 1
    return etiq, nb


# --------------------------------------------------------------------------
# Geometrie de base
# --------------------------------------------------------------------------

def aire_triangle(p, q, r):
    ux, uy, uz = q[0] - p[0], q[1] - p[1], q[2] - p[2]
    vx, vy, vz = r[0] - p[0], r[1] - p[1], r[2] - p[2]
    cx = uy * vz - uz * vy
    cy = uz * vx - ux * vz
    cz = ux * vy - uy * vx
    return 0.5 * math.sqrt(cx * cx + cy * cy + cz * cz)


def centroide(p, q, r):
    return ((p[0] + q[0] + r[0]) / 3.0,
            (p[1] + q[1] + r[1]) / 3.0,
            (p[2] + q[2] + r[2]) / 3.0)


def normale(p, q, r):
    ux, uy, uz = q[0] - p[0], q[1] - p[1], q[2] - p[2]
    vx, vy, vz = r[0] - p[0], r[1] - p[1], r[2] - p[2]
    cx = uy * vz - uz * vy
    cy = uz * vx - ux * vz
    cz = ux * vy - uy * vx
    n = math.sqrt(cx * cx + cy * cy + cz * cz)
    if n == 0.0:
        return (0.0, 0.0, 0.0)
    return (cx / n, cy / n, cz / n)


def boite(positions):
    xs = [p[0] for p in positions]
    ys = [p[1] for p in positions]
    zs = [p[2] for p in positions]
    return (min(xs), min(ys), min(zs)), (max(xs), max(ys), max(zs))
