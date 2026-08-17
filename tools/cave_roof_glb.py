#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Lecture d'un `.glb` et lancer de rayons VERTICAUX, sans Blender ni numpy.

POURQUOI CE MODULE EXISTE
=========================

Le défaut du toit a été cartographié avec la BVH de Blender. Le reproduire
avec le MÊME instrument ne prouverait que la reproductibilité de cet
instrument. Ce module lit les octets du `.glb` livré et lance ses propres
rayons : si les deux tombent sur 0,038 m, le chiffre ne dépend plus d'une
implémentation.

Il ne dépend ni de `bpy` (donc pas du verrou d'outil lourd, donc pas de
l'attente derrière les agents B et C) ni de numpy — qui est cassé dans ce
conteneur :

    ModuleNotFoundError: No module named 'numpy.core._multiarray_umath'

REPÈRE. Le `.glb` est Y-up, le générateur Blender est Z-up. La convention
du projet est `godot = (ax, z, -ay)`. On revient donc au repère MODÈLE par
`ax = gx`, `ay = -gz`, `z = gy`, et TOUTES les coordonnées publiées par ce
module sont en repère modèle — le même que `CAVITE`, le même que la
cartographie du défaut.

LA LECTURE DEDANS/DEHORS S'ÉCRIT UNE FOIS. `tools/CLAUDE.md` consigne trois
verdicts faux d'affilée nés de sa redérivation branche par branche. Elle vit
ici dans `colonne_depuis_impacts()`, et nulle part ailleurs.

MAIS CE N'EST PLUS LA PARITÉ, ET C'EST LE RÉSULTAT PRINCIPAL DE R2a-3.5.3
=========================================================================

La règle de parité de `tools/CLAUDE.md` a une hypothèse tacite : **le
maillage ne se traverse pas lui-même**. Celui-ci se traverse — le générateur
le mesure et le TOLÈRE (`controle_repli`, `REPLI_LIVRABLE_MAX_M`). Mesuré,
la colonne verticale en (0,50 ; 5,80) rend la séquence de normales

    entree, entree, sortie, sortie, entree, entree, sortie, sortie

qui n'alterne pas. Une lecture par parité y compte une région COUVERTE DEUX
FOIS comme si elle était vide, et rend « 3,8 cm de roche au-dessus d'un vide
de 1,41 m ». Le nombre d'enlacement, vérifié dans huit directions
indépendantes (`tools/cave_roof_winding.py`), rend au même endroit **3,06 m
de roche continue au-dessus d'un vide de 0,30 m**.

On accumule donc les traversées SIGNÉES depuis le ciel : +1 quand le rayon
descendant entre, -1 quand il sort. Enlacement >= 1 = matière, 0 = vide.
L'équivalence de cette accumulation verticale avec l'enlacement multi-
directionnel est vérifiée par `tools/cave_roof_equivalence.py`, et c'est
elle qui autorise à balayer des milliers de colonnes pour le prix d'un
rayon.

`colonne_par_parite()` conserve l'ancienne lecture — non pour l'utiliser,
mais pour pouvoir REPRODUIRE le chiffre de la cartographie et montrer d'où
il vient.
"""

import json
import math
import os
import struct

## Deux impacts plus proches que cela sont le MÊME passage de surface, vu
## deux fois parce que le rayon a frôlé une arête partagée. Les fusionner
## est indispensable : un doublon inverse la parité, et la parité décide
## de tout ce qui suit.
EPS_FUSION_M = 1e-4

## Sous cette épaisseur, un intervalle de matière est une écaille de
## décimation et non une paroi. Même intention que `EPAISSEUR_ECAILLE_M`
## du générateur, mais ce module ne l'importe pas : il doit rester lisible
## seul. La valeur est publiée dans chaque rapport.
EPS_ECAILLE_M = 0.005

COMPOSANTES = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2),
               5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
CARDINAL = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4,
            "MAT2": 4, "MAT3": 9, "MAT4": 16}


# --------------------------------------------------------------------------
# 1. Lecture du conteneur
# --------------------------------------------------------------------------

def _lire_glb(chemin):
    """Rend (json, memoryview du chunk BIN)."""
    with open(chemin, "rb") as flux:
        octets = flux.read()
    magique, _version, longueur = struct.unpack_from("<III", octets, 0)
    if magique != 0x46546C67:
        raise RuntimeError("%s : ce n'est pas un .glb (magique %#x)"
                           % (chemin, magique))
    if longueur != len(octets):
        raise RuntimeError("%s : longueur annoncee %d, reelle %d"
                           % (chemin, longueur, len(octets)))
    tete, binaire, curseur = None, None, 12
    while curseur + 8 <= len(octets):
        taille, genre = struct.unpack_from("<II", octets, curseur)
        corps = octets[curseur + 8:curseur + 8 + taille]
        if genre == 0x4E4F534A:
            tete = json.loads(corps.decode("utf-8"))
        elif genre == 0x004E4942:
            binaire = corps
        curseur += 8 + taille + ((4 - taille % 4) % 4 if taille % 4 else 0)
    if tete is None:
        raise RuntimeError("%s : chunk JSON absent" % chemin)
    return tete, binaire


def _accesseur(tete, binaire, indice):
    """Rend la liste des éléments d'un accesseur (tuples ou scalaires)."""
    acc = tete["accessors"][indice]
    fmt, taille = COMPOSANTES[acc["componentType"]]
    card = CARDINAL[acc["type"]]
    compte = acc["count"]
    depart = acc.get("byteOffset", 0)
    if "bufferView" not in acc:
        return [(0.0,) * card if card > 1 else 0] * compte
    vue = tete["bufferViews"][acc["bufferView"]]
    base = vue.get("byteOffset", 0) + depart
    pas = vue.get("byteStride") or (taille * card)
    motif = "<" + fmt * card
    sortie = []
    for i in range(compte):
        valeurs = struct.unpack_from(motif, binaire, base + i * pas)
        sortie.append(valeurs if card > 1 else valeurs[0])
    return sortie


def _matrice_noeud(noeud):
    if "matrix" in noeud:
        m = noeud["matrix"]          # colonne-majeur
        return [[m[0], m[4], m[8], m[12]],
                [m[1], m[5], m[9], m[13]],
                [m[2], m[6], m[10], m[14]],
                [m[3], m[7], m[11], m[15]]]
    t = noeud.get("translation", [0.0, 0.0, 0.0])
    r = noeud.get("rotation", [0.0, 0.0, 0.0, 1.0])
    s = noeud.get("scale", [1.0, 1.0, 1.0])
    x, y, z, w = r
    rot = [[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
           [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
           [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]]
    return [[rot[i][j] * s[j] for j in range(3)] + [t[i]] for i in range(3)] \
        + [[0.0, 0.0, 0.0, 1.0]]


def _produit(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)]
            for i in range(4)]


def _applique(m, p):
    return (m[0][0] * p[0] + m[0][1] * p[1] + m[0][2] * p[2] + m[0][3],
            m[1][0] * p[0] + m[1][1] * p[1] + m[1][2] * p[2] + m[1][3],
            m[2][0] * p[0] + m[2][1] * p[1] + m[2][2] * p[2] + m[2][3])


def noms_de_maillages(chemin):
    """Les noms des noeuds porteurs de maillage. À REGARDER AVANT DE MESURER."""
    tete, _ = _lire_glb(chemin)
    return [n.get("name", "?") for n in tete.get("nodes", []) if "mesh" in n]


def triangles_modele(chemin, noeud=None):
    """Les triangles du `.glb`, en repère MODÈLE (ax, ay, z).

    `noeud` FILTRE PAR NOM, et ce paramètre n'est pas un confort : il répare
    une faute que j'ai commise et mesurée.

    Le `.glb` de la grotte contient DEUX maillages — `SM_WaterfallCave`, le
    visuel, et `COL_WaterfallCave`, la coque de collision. Sans filtre, ce
    lecteur les additionnait. Or la coque de collision est un TUBE PLEIN le
    long de la galerie : elle rebouche le vide qu'on cherche à mesurer. Les
    colonnes rendaient alors « 3,06 m de roche continue » là où le maillage
    visuel n'a qu'un feuillet, et la séquence de normales non alternée
    (entree, entree, sortie, sortie) qui m'a fait accuser la parité n'était
    pas une auto-intersection : c'étaient les deux coques imbriquées.

    Un fichier au bon nom n'est pas une preuve de contenu — `tools/CLAUDE.md`
    le dit pour les empreintes ; cela vaut aussi pour ce qu'il y a DEDANS.

    Rend une liste de (A, B, C), chaque sommet étant un triplet de flottants.
    """
    tete, binaire = _lire_glb(chemin)
    identite = [[1.0 if i == j else 0.0 for j in range(4)] for i in range(4)]
    tris = []

    def parcourir(indice, parent):
        courant = tete["nodes"][indice]
        monde = _produit(parent, _matrice_noeud(courant))
        if "mesh" in courant and (noeud is None
                                  or courant.get("name") == noeud):
            for prim in tete["meshes"][courant["mesh"]].get("primitives", []):
                if prim.get("mode", 4) != 4:
                    continue        # on ne mesure que des TRIANGLES
                pos = _accesseur(tete, binaire, prim["attributes"]["POSITION"])
                pts = [_applique(monde, p) for p in pos]
                if "indices" in prim:
                    idx = _accesseur(tete, binaire, prim["indices"])
                else:
                    idx = list(range(len(pts)))
                for i in range(0, len(idx) - 2, 3):
                    a, b, c = pts[idx[i]], pts[idx[i + 1]], pts[idx[i + 2]]
                    # glTF Y-up -> modele Z-up : ax = gx, ay = -gz, z = gy
                    tris.append(((a[0], -a[2], a[1]),
                                 (b[0], -b[2], b[1]),
                                 (c[0], -c[2], c[1])))
        for fils in courant.get("children", []):
            parcourir(fils, monde)

    scene = tete.get("scenes", [{}])[tete.get("scene", 0)]
    racines = scene.get("nodes")
    if racines is None:
        racines = list(range(len(tete.get("nodes", []))))
    for r in racines:
        parcourir(r, identite)
    return tris


# --------------------------------------------------------------------------
# 2. Accélérateur : grille 2D sur (ax, ay) — les rayons sont verticaux
# --------------------------------------------------------------------------

class GrilleVerticale(object):
    """Range les triangles par cellule XY. Sans elle, 20 000 triangles x
    1 500 rayons en Python pur prennent des minutes ; avec elle, moins
    d'une seconde. Elle ne change AUCUN résultat : c'est un filtre
    conservateur par boîte englobante, pas une approximation.
    """

    def __init__(self, triangles, cellule=0.50):
        self.tris = triangles
        self.cellule = cellule
        self.xmin = min(min(t[0][0], t[1][0], t[2][0]) for t in triangles)
        self.ymin = min(min(t[0][1], t[1][1], t[2][1]) for t in triangles)
        self.xmax = max(max(t[0][0], t[1][0], t[2][0]) for t in triangles)
        self.ymax = max(max(t[0][1], t[1][1], t[2][1]) for t in triangles)
        self.zmin = min(min(t[0][2], t[1][2], t[2][2]) for t in triangles)
        self.zmax = max(max(t[0][2], t[1][2], t[2][2]) for t in triangles)
        self.cases = {}
        for n, t in enumerate(triangles):
            i0 = int(math.floor((min(t[0][0], t[1][0], t[2][0]) - self.xmin)
                                / cellule))
            i1 = int(math.floor((max(t[0][0], t[1][0], t[2][0]) - self.xmin)
                                / cellule))
            j0 = int(math.floor((min(t[0][1], t[1][1], t[2][1]) - self.ymin)
                                / cellule))
            j1 = int(math.floor((max(t[0][1], t[1][1], t[2][1]) - self.ymin)
                                / cellule))
            for i in range(i0, i1 + 1):
                for j in range(j0, j1 + 1):
                    self.cases.setdefault((i, j), []).append(n)

    def impacts(self, ax, ay):
        """Toutes les altitudes z où la verticale (ax, ay) coupe la surface.

        Rend une liste de (z, delta) triée du HAUT vers le BAS, où `delta`
        vaut +1 si la face regarde vers le haut — le rayon descendant ENTRE
        dans la matière — et -1 si elle regarde vers le bas (il en SORT).
        `delta` est directement l'incrément d'enlacement, pour qu'aucune
        conversion de signe ne se glisse chez l'appelant.

        Les doublons d'arête partagée sont fusionnés.
        """
        i = int(math.floor((ax - self.xmin) / self.cellule))
        j = int(math.floor((ay - self.ymin) / self.cellule))
        bruts = []
        for n in self.cases.get((i, j), ()):
            a, b, c = self.tris[n]
            # Coordonnées barycentriques dans le plan XY.
            d = ((b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1]))
            if abs(d) < 1e-12:
                continue            # triangle vertical : pas d'impact franc
            u = ((b[1] - c[1]) * (ax - c[0]) + (c[0] - b[0]) * (ay - c[1])) / d
            v = ((c[1] - a[1]) * (ax - c[0]) + (a[0] - c[0]) * (ay - c[1])) / d
            w = 1.0 - u - v
            if u < 0.0 or v < 0.0 or w < 0.0:
                continue
            z = u * a[2] + v * b[2] + w * c[2]
            # Normale géométrique ; son signe en z dit si la face regarde
            # vers le haut. `d` est le double de l'aire signée projetée :
            # son signe EST celui de la composante z de la normale. Face
            # tournée vers le haut => le rayon descendant entre => +1.
            bruts.append((z, +1 if d > 0.0 else -1))
        bruts.sort(key=lambda h: -h[0])
        fusion = []
        for z, delta in bruts:
            if fusion and abs(fusion[-1][0] - z) < EPS_FUSION_M \
                    and fusion[-1][1] == delta:
                continue
            fusion.append((z, delta))
        return fusion


# --------------------------------------------------------------------------
# 3. LA PARITÉ, ÉCRITE UNE FOIS
# --------------------------------------------------------------------------

def colonne_depuis_impacts(impacts):
    """Traduit une colonne d'impacts en tranches roche/vide — PAR ENLACEMENT.

    Rend (tranches, finit_dans_la_roche) où `tranches` est une liste de
    (nature, z_haut, z_bas), nature valant "roche" ou "vide", ordonnée du
    haut vers le bas et **fusionnée** : deux tranches de même nature qui se
    touchent n'en font qu'une, sans quoi un pli interne découperait une
    roche continue en fausses lames.

    LA RÈGLE, et elle ne se redérive nulle part ailleurs :

        on part du ciel avec un enlacement de 0 ; chaque impact ajoute son
        `delta` (+1 en entrant, -1 en sortant) ; l'intervalle est de la
        ROCHE si l'enlacement y est >= 1, du VIDE s'il y est <= 0.

    Elle englobe la parité comme cas particulier : sur un maillage qui ne se
    traverse pas, l'enlacement alterne 0,1,0,1 et les deux lectures
    coïncident. Sur celui-ci, elles diffèrent d'un facteur quatre-vingts.

    `finit_dans_la_roche` reste vrai quand l'enlacement final est >= 1 —
    solide ouvert par le bas, un rocher planté dans le terrain.
    """
    brut = []
    enlacement = 0
    for k in range(len(impacts) - 1):
        enlacement += impacts[k][1]
        nature = "roche" if enlacement >= 1 else "vide"
        brut.append((nature, impacts[k][0], impacts[k + 1][0]))
    final = enlacement + (impacts[-1][1] if impacts else 0)
    tranches = []
    for nature, haut, bas in brut:
        if tranches and tranches[-1][0] == nature:
            tranches[-1] = (nature, tranches[-1][1], bas)
        else:
            tranches.append((nature, haut, bas))
    return tranches, (final >= 1)


def colonne_par_parite(impacts):
    """L'ANCIENNE lecture, conservée pour reproduire le chiffre contesté.

    Elle alterne roche/vide à chaque impact sans regarder les normales.
    Elle n'est utilisée par aucun contrôle : elle sert à montrer d'où vient
    le « 0,038 m » de la cartographie, et à mesurer l'écart entre les deux
    lectures sur la même géométrie.
    """
    tranches = []
    for k in range(len(impacts) - 1):
        tranches.append(("roche" if k % 2 == 0 else "vide",
                         impacts[k][0], impacts[k + 1][0]))
    return tranches, (len(impacts) % 2 == 1)


def toit_au_dessus_d_un_vide(impacts, vide_min_m, ecaille_m=EPS_ECAILLE_M,
                             lecture=colonne_depuis_impacts):
    """La PREMIÈRE roche surmontant un vide d'au moins `vide_min_m`.

    Rend (epaisseur, z_haut, hauteur_du_vide) ou None si la colonne n'en
    présente aucune. Les écailles de moins de `ecaille_m` ne sont pas des
    parois : elles sont fusionnées avec le vide qui les suit, faute de quoi
    une coquille de 2 mm de décimation se ferait passer pour un toit.

    `lecture` permet de rejouer la mesure sous l'ANCIENNE règle de parité
    (`colonne_par_parite`) pour comparer les deux — jamais pour juger.
    """
    tranches, _ = lecture(impacts)
    k = 0
    while k < len(tranches):
        if tranches[k][0] != "roche":
            k += 1
            continue
        epaisseur = tranches[k][1] - tranches[k][2]
        if epaisseur < ecaille_m:
            k += 2                      # écaille : on saute roche + vide
            continue
        if k + 1 < len(tranches):
            vide = tranches[k + 1][1] - tranches[k + 1][2]
            if vide >= vide_min_m:
                return (epaisseur, tranches[k][1], vide)
        k += 2
    return None


def sha256(chemin):
    import hashlib
    h = hashlib.sha256()
    with open(chemin, "rb") as flux:
        for bloc in iter(lambda: flux.read(1 << 20), b""):
            h.update(bloc)
    return h.hexdigest()


def charger(chemin, noeud="SM_WaterfallCave"):
    """Rend (grille, sha256, nombre de triangles). Prouve la provenance.

    `noeud` vaut par défaut le maillage VISUEL. Passer None additionne tous
    les maillages du fichier, coque de collision comprise — ce qui n'est
    presque jamais ce qu'on veut (voir `triangles_modele`).
    """
    if not os.path.isfile(chemin):
        raise RuntimeError("introuvable : %s" % chemin)
    tris = triangles_modele(chemin, noeud)
    if not tris:
        raise RuntimeError("aucun triangle pour le noeud %r dans %s ; "
                           "presents : %s"
                           % (noeud, chemin, noms_de_maillages(chemin)))
    return GrilleVerticale(tris), sha256(chemin), len(tris)


def toit_cumule_au_dessus_d_un_vide(impacts, vide_min_m,
                                    ecaille_m=EPS_ECAILLE_M,
                                    lecture=colonne_depuis_impacts):
    """TOUTE la roche qui sépare un vide du ciel — la mesure du contrat.

    POURQUOI ELLE REMPLACE « LA PREMIÈRE ROCHE »
    ============================================

    `controle_epaisseur` du générateur le dit déjà dans sa propre docstring,
    et c'est sa phrase, pas la mienne :

        « La question posée est "combien de roche sépare la galerie du
          dehors", et sa réponse est la SOMME. »

    Prendre la PREMIÈRE roche au-dessus d'un vide donne le contraire.
    Mesuré en (1,70 ; 5,30) sur le candidat : la première roche fait
    0,050 m — mais elle est surmontée, à 0,135 m au-dessus, d'un banc de
    2,086 m. Le joueur est sous 2,14 m de pierre et l'instrument annonce
    5 cm. Ce n'est pas une lame de roche, c'est un feuillet délaminé par la
    décimation sous un toit épais.

    On cumule donc toute la matière rencontrée entre le vide et le ciel, en
    ignorant les écailles de moins de `ecaille_m` comme le fait déjà le
    contrôle d'origine.

    Rend (cumul, z_du_vide, hauteur_du_vide, nombre_de_bancs) pour le vide
    qualifiant le plus HAUT de la colonne, ou None s'il n'y en a aucun.
    """
    tranches, _ = lecture(impacts)
    for k, (nature, haut, bas) in enumerate(tranches):
        if nature != "vide" or (haut - bas) < vide_min_m:
            continue
        cumul, bancs = 0.0, 0
        for nature2, haut2, bas2 in tranches[:k]:
            if nature2 != "roche":
                continue
            e = haut2 - bas2
            if e >= ecaille_m:
                cumul += e
                bancs += 1
        return (cumul, haut, haut - bas, bancs)
    return None
