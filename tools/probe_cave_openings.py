#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""SONDE DE CONTINUITÉ DE LA GROTTE DU COUCHANT — plancher, jours, ligne de vue.

POURQUOI CET OUTIL EXISTE, ET CE QU'IL RÉPARE.

La revue R2a-3.3 a rendu FAIL VISUEL sur le seuil : « surfaces vertes à
travers la poche », « sol visuellement disloqué ». Neuf contrôles du
générateur étaient verts. Ils ne pouvaient pas voir le défaut, et la raison
est une CIRCULARITÉ dans la chaîne, vérifiable en deux lignes de
`source_assets/blender/environment/make_waterfall_cave.py` :

  * `controle_epaisseur()` exclut les rayons descendants —
    `if math.sin(theta) < -0.30: continue` — en justifiant que « le plancher
    est garanti autrement : par `controle_aucun_jour` » ;
  * `controle_aucun_jour()` ne tire que `Vector((0.0, 0.0, 1.0))`,
    c'est-à-dire VERS LE HAUT.

Rien n'a donc jamais regardé le sol. Ce n'est pas une opinion : c'est le
texte des deux fonctions.

Deux autres angles morts, du même ordre :

  * `controle_epaisseur` saute `if i >= len(CAVITE) - 2` et
    `controle_aucun_jour` boucle sur `range(2, len(CAVITE) - 2)` : les
    stations **0, 1, 7 et 8** ne sont mesurées par AUCUN des deux — c'est-à-
    dire le porche, le seuil, et tout le fond où vit l'alcôve ;
  * `controle_epaisseur` tire `Vector((cos θ, 0, sin θ))`, donc dans le plan
    perpendiculaire à l'axe : **aucun rayon ne pointe le long de la galerie**,
    ni vers la calotte du fond, ni vers le fond de l'alcôve.

CE QUE CETTE SONDE FAIT, ET CE QU'ELLE NE FAIT PAS.

Elle mesure le GLB LIVRÉ — `assets/environment/caves/SM_WaterfallCave.glb` —
en Python pur : ni Blender, ni Godot, ni GPU, donc aucun verrou d'outil
lourd et aucune dépendance à une machine de rendu. Elle ne juge rien
d'artistique. Elle répond à trois questions géométriques, et à elles seules.

  1. PLANCHER — depuis l'intérieur de la galerie, un rayon vers le BAS
     rencontre-t-il de la matière, et à la hauteur attendue ?
  2. JOUR — depuis l'intérieur, un rayon dans N'IMPORTE QUELLE direction
     de la sphère (±Y et vers le bas compris) ressort-il par un trou ?
  3. LIGNE DE VUE — depuis la caméra de preuve, un pixel visant la bouche
     montre-t-il de la roche, ou ce qui se trouve DERRIÈRE la grotte ?

Le contrôle 3 applique la règle du moteur lui-même : Godot rend en
`cull_back`, donc le pixel affiche le premier triangle FACE AVANT. S'il n'y
en a aucun, le pixel montre le monde derrière — c'est la définition d'un
jour, exprimée dans les termes du rendu et non dans les miens.

LES TROIS CONTRÔLES SONT SÉPARÉS, ET LE RESTENT. Le plancher a son propre
verdict et son propre compte. C'est délibéré : un correctif qui épaissirait
la gaine ferait verdir les parois sans toucher au sol, et un verdict global
le masquerait. Chaque section nomme son défaut par (station, azimut, z) ou
par (x, y) — de quoi écrire une consigne de correction, pas seulement un
rouge.

REPÈRE. Le GLB est Y-up (converti à l'export) ; le générateur travaille en
Z-up Blender, galerie vers +Y, bouche à l'origine ouvrant vers -Y, plan de
sol à z = 0. La sonde ramène tout en repère MODÈLE BLENDER, parce que c'est
là que vivent `CAVITE` et `PALIER`, donc là que « station 5, azimut 180° »
veut dire quelque chose. Conversion : x_bl = X_glb, y_bl = -Z_glb,
z_bl = Y_glb. Les deux changements de repère sont des rotations pures
(déterminant +1), donc l'enroulement des faces est préservé et le test de
face avant reste valide.

Usage :
    python3 tools/probe_cave_openings.py assets/environment/caves/SM_WaterfallCave.glb \\
        [--manifeste evidence/.../manifest.json] [--json sortie.json] [--rapide]

Codes de sortie : 0 = aucun défaut · 1 = défaut mesuré · 3 = BLOQUÉ
(fichier absent ou illisible). Jamais 0 sur une étape sautée
(`.claude/rules/evidence.md`, `tools/CLAUDE.md`).
"""

import argparse
import json
import math
import os
import struct
import sys

GLB_MAGIC = 0x46546C67
CHUNK_JSON = 0x4E4F534A
CHUNK_BIN = 0x004E4942

# ---------------------------------------------------------------------------
# LES COTES SONT RECOPIÉES DU GÉNÉRATEUR, ET C'EST UN CHOIX ASSUMÉ.
#
# Les importer exigerait `bpy` (le module fait `import bpy` en tête). La
# sonde perdrait alors son mérite principal : tourner sans outil lourd.
# Elles sont donc recopiées, et `controle_coherence_cotes()` vérifie à
# chaque exécution qu'elles correspondent encore au fichier source, par
# lecture textuelle. Une divergence est un ÉCHEC, pas un avertissement :
# une sonde qui mesure des stations périmées ment plus qu'elle n'informe.
# ---------------------------------------------------------------------------
CAVITE = [
    (0.00, -1.15, 1.90, 2.80),
    (0.00, 0.00, 1.70, 2.85),
    (0.06, 1.60, 1.85, 2.95),
    (0.24, 3.20, 2.15, 2.80),
    (0.58, 4.75, 2.70, 2.90),
    (1.05, 6.25, 3.05, 2.92),
    (1.62, 7.60, 2.80, 2.92),
    (2.25, 8.65, 2.20, 2.55),
    (2.85, 9.25, 1.40, 2.00),
]
PALIER = (0.00, 0.00, 0.04, 0.10, 0.16, 0.26, 0.50, 0.78, 0.92)
SAG = 0.08
PORCHE_DENIVELE = -0.58

## Tolérance sur la hauteur du premier impact vers le bas. Le sol de la
## galerie est une facette de la cavité soustraite ; entre deux sommets de
## section (9 facettes) la corde s'écarte du profil théorique, et la
## décimation déplace encore des sommets. 0,25 m couvre les deux sans
## couvrir un trou : le vide sous le plancher, lui, fait au moins 0,47 m
## (écart entre le sommet de l'assise, z = -0,55, et le sol au seuil).
PLANCHER_TOLERANCE_M = 0.25

## En deçà, deux impacts successifs sont le même pli de surface vu deux
## fois, pas deux parois. Repris de `EPAISSEUR_ECAILLE_M` du générateur.
ECAILLE_M = 0.05

## Décalage d'avancement après un impact, pour ne pas re-toucher la même
## face. Deux ordres de grandeur sous l'arête la plus fine voulue.
EPSILON_MARCHE = 1e-4

## Nombre maximal d'impacts comptés sur un rayon. Au-delà, la géométrie
## est pathologique et on le dit au lieu de boucler.
IMPACTS_MAX = 64

## Part minimale de la sphère qui doit rencontrer de la roche pour qu'un
## point d'échantillonnage compte comme « dans la cavité ». Voir le
## commentaire de `controle_jour` : 0,50 ne peut pas absoudre un trou, il
## écarte seulement les points qui ne sont plus dans une grotte du tout.
ENCLOSURE_MIN = 0.50


# ---------------------------------------------------------------------------
# Lecture du GLB. Volontairement autonome : `tools/gltf_inspect.py` lit le
# JSON mais ne décode pas les accessors, et l'importer créerait un couplage
# qui n'apporte rien.
# ---------------------------------------------------------------------------

TYPE_COMPOSANTES = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4,
                    "MAT4": 16}
TYPE_COMPOSANT = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2),
                  5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}


class Blocage(Exception):
    """Obstacle externe : le contrôle ne peut pas s'exécuter. Sortie 3."""


def lire_glb(chemin):
    if not os.path.isfile(chemin):
        raise Blocage("fichier absent : %s" % chemin)
    with open(chemin, "rb") as poignee:
        blob = poignee.read()
    if len(blob) < 12:
        raise Blocage("fichier trop court pour un GLB : %s" % chemin)
    magic, version, _ = struct.unpack_from("<III", blob, 0)
    if magic != GLB_MAGIC:
        raise Blocage("en-tete GLB invalide : 0x%08X" % magic)
    if version != 2:
        raise Blocage("glTF version %d, attendu 2" % version)
    offset, gltf, binaire = 12, None, b""
    while offset + 8 <= len(blob):
        longueur, genre = struct.unpack_from("<II", blob, offset)
        charge = blob[offset + 8: offset + 8 + longueur]
        if genre == CHUNK_JSON:
            gltf = json.loads(charge.decode("utf-8"))
        elif genre == CHUNK_BIN:
            binaire = charge
        offset += 8 + longueur + ((4 - longueur % 4) % 4)
    if gltf is None:
        raise Blocage("chunk JSON absent")
    return gltf, binaire


def lire_accessor(gltf, binaire, index):
    """Décode un accessor en liste de tuples (ou de scalaires)."""
    acc = gltf["accessors"][index]
    nb = TYPE_COMPOSANTES[acc["type"]]
    code, taille = TYPE_COMPOSANT[acc["componentType"]]
    compte = acc["count"]
    vue = gltf["bufferViews"][acc["bufferView"]]
    base = vue.get("byteOffset", 0) + acc.get("byteOffset", 0)
    foulee = vue.get("byteStride") or (nb * taille)
    motif = "<" + code * nb
    sortie = []
    for i in range(compte):
        valeurs = struct.unpack_from(motif, binaire, base + i * foulee)
        sortie.append(valeurs[0] if nb == 1 else valeurs)
    return sortie


def triangles_du_glb(chemin, noeud_voulu="SM_WaterfallCave"):
    """Triangles du maillage RENDU, en repère modèle Blender.

    `COL_WaterfallCave` est écarté explicitement : c'est un proxy de
    collision, jamais rendu, et un loft entièrement distinct du maillage
    visible. Les mesurer ensemble reviendrait à prouver la continuité d'une
    surface que personne ne voit — exactement l'erreur que
    `tools/measure_module_relief.py` a déjà commise sur ce même asset.
    """
    gltf, binaire = lire_glb(chemin)
    noms = [n.get("name", "") for n in gltf.get("nodes", [])]
    if noeud_voulu not in noms:
        raise Blocage("noeud %s absent du GLB (presents : %s)"
                      % (noeud_voulu, ", ".join(noms)))
    for noeud in gltf["nodes"]:
        if noeud.get("name") != noeud_voulu:
            continue
        for cle in ("matrix", "rotation", "scale", "translation"):
            if cle in noeud:
                raise Blocage(
                    "le noeud %s porte une transformation (%s) : la sonde "
                    "suppose l'identite, elle refuse de mesurer a cote"
                    % (noeud_voulu, cle))
        maillage = gltf["meshes"][noeud["mesh"]]
        break
    materiaux = [m.get("name", "?") for m in gltf.get("materials", [])]
    tris = []
    par_matiere = {}
    for prim in maillage["primitives"]:
        if prim.get("mode", 4) != 4:
            raise Blocage("primitive de mode %d : la sonde n'accepte que "
                          "des triangles" % prim.get("mode"))
        positions = lire_accessor(gltf, binaire, prim["attributes"]["POSITION"])
        if "indices" in prim:
            indices = lire_accessor(gltf, binaire, prim["indices"])
        else:
            indices = list(range(len(positions)))
        nom_mat = materiaux[prim["material"]] if prim.get("material") is not None \
            else "(sans matiere)"
        debut = len(tris)
        for i in range(0, len(indices) - 2, 3):
            sommets = []
            for j in range(3):
                x, y, z = positions[indices[i + j]]
                # GLB Y-up -> modele Blender Z-up. Rotation pure : det = +1,
                # donc l'enroulement des faces survit au changement.
                sommets.append((x, -z, y))
            tris.append((sommets[0], sommets[1], sommets[2]))
        par_matiere[nom_mat] = par_matiere.get(nom_mat, 0) + (len(tris) - debut)
    return tris, par_matiere


# ---------------------------------------------------------------------------
# Accélérateur. Une grille uniforme, pas un BVH : le maillage tient dans
# 16 x 12 x 16 m et compte ~21 000 triangles, la grille suffit largement et
# elle se relit en dix minutes. Un BVH ici serait de la complexité sans
# mesure — exactement ce que le projet reproche par ailleurs.
# ---------------------------------------------------------------------------

class Grille(object):
    def __init__(self, tris, cote=0.40):
        self.tris = tris
        lo = [min(s[k] for t in tris for s in t) for k in range(3)]
        hi = [max(s[k] for t in tris for s in t) for k in range(3)]
        marge = cote
        self.lo = [v - marge for v in lo]
        self.hi = [v + marge for v in hi]
        self.cote = cote
        self.dim = [max(1, int(math.ceil((self.hi[k] - self.lo[k]) / cote)))
                    for k in range(3)]
        self.cases = {}
        for indice, tri in enumerate(tris):
            mn = [min(s[k] for s in tri) for k in range(3)]
            mx = [max(s[k] for s in tri) for k in range(3)]
            i0 = [self._case(mn[k], k) for k in range(3)]
            i1 = [self._case(mx[k], k) for k in range(3)]
            for ix in range(i0[0], i1[0] + 1):
                for iy in range(i0[1], i1[1] + 1):
                    for iz in range(i0[2], i1[2] + 1):
                        self.cases.setdefault((ix, iy, iz), []).append(indice)

    def _case(self, valeur, axe):
        i = int((valeur - self.lo[axe]) / self.cote)
        return min(max(i, 0), self.dim[axe] - 1)

    def aabb(self):
        return tuple(self.lo), tuple(self.hi)

    def candidats(self, origine, direction, portee):
        """Indices de triangles le long du rayon, par parcours DDA.

        Le parcours est ORDONNÉ par case : on peut donc s'arrêter au
        premier impact sans balayer toute la scène. Les doublons sont
        filtrés — un triangle appartient à plusieurs cases.
        """
        vus = set()
        # Point d'entrée dans la boîte de la grille.
        t0, t1 = 0.0, portee
        for k in range(3):
            if abs(direction[k]) < 1e-12:
                if origine[k] < self.lo[k] or origine[k] > self.hi[k]:
                    return
                continue
            a = (self.lo[k] - origine[k]) / direction[k]
            b = (self.hi[k] - origine[k]) / direction[k]
            if a > b:
                a, b = b, a
            t0 = max(t0, a)
            t1 = min(t1, b)
        if t0 > t1:
            return
        point = [origine[k] + direction[k] * (t0 + 1e-6) for k in range(3)]
        case = [self._case(point[k], k) for k in range(3)]
        pas = [0, 0, 0]
        suivant = [float("inf")] * 3
        delta = [float("inf")] * 3
        for k in range(3):
            if direction[k] > 1e-12:
                pas[k] = 1
                bord = self.lo[k] + (case[k] + 1) * self.cote
                suivant[k] = t0 + (bord - point[k]) / direction[k]
                delta[k] = self.cote / direction[k]
            elif direction[k] < -1e-12:
                pas[k] = -1
                bord = self.lo[k] + case[k] * self.cote
                suivant[k] = t0 + (bord - point[k]) / direction[k]
                delta[k] = -self.cote / direction[k]
        garde = 0
        while garde < 4096:
            garde += 1
            lot = self.cases.get((case[0], case[1], case[2]))
            if lot:
                for indice in lot:
                    if indice not in vus:
                        vus.add(indice)
                        yield indice
            axe = 0
            if suivant[1] < suivant[axe]:
                axe = 1
            if suivant[2] < suivant[axe]:
                axe = 2
            if suivant[axe] > t1 or pas[axe] == 0:
                return
            case[axe] += pas[axe]
            if case[axe] < 0 or case[axe] >= self.dim[axe]:
                return
            suivant[axe] += delta[axe]


def croiser_triangle(origine, direction, tri):
    """Möller–Trumbore. Rend (distance, produit normale·direction) ou None.

    Le second membre porte l'ORIENTATION : négatif, le rayon aborde la face
    par l'avant (c'est ce que le moteur affiche en `cull_back`) ; positif,
    il l'aborde par le dos. C'est toute la différence entre « je vois de la
    roche » et « je regarde à travers ».
    """
    a, b, c = tri
    e1 = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    e2 = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    p = (direction[1] * e2[2] - direction[2] * e2[1],
         direction[2] * e2[0] - direction[0] * e2[2],
         direction[0] * e2[1] - direction[1] * e2[0])
    det = e1[0] * p[0] + e1[1] * p[1] + e1[2] * p[2]
    if abs(det) < 1e-12:
        return None
    inv = 1.0 / det
    s = (origine[0] - a[0], origine[1] - a[1], origine[2] - a[2])
    u = (s[0] * p[0] + s[1] * p[1] + s[2] * p[2]) * inv
    if u < -1e-9 or u > 1.0 + 1e-9:
        return None
    q = (s[1] * e1[2] - s[2] * e1[1],
         s[2] * e1[0] - s[0] * e1[2],
         s[0] * e1[1] - s[1] * e1[0])
    v = (direction[0] * q[0] + direction[1] * q[1] + direction[2] * q[2]) * inv
    if v < -1e-9 or u + v > 1.0 + 1e-9:
        return None
    t = (e2[0] * q[0] + e2[1] * q[1] + e2[2] * q[2]) * inv
    if t <= 1e-7:
        return None
    n = (e1[1] * e2[2] - e1[2] * e2[1],
         e1[2] * e2[0] - e1[0] * e2[2],
         e1[0] * e2[1] - e1[1] * e2[0])
    return t, n[0] * direction[0] + n[1] * direction[1] + n[2] * direction[2]


def impacts(grille, origine, direction, portee=200.0):
    """Tous les impacts le long d'un rayon, triés par distance.

    On collecte puis on trie, plutôt que de s'arrêter au premier : la
    PARITÉ est ce qui distingue une paroi d'un jour, et elle exige de
    compter jusqu'au bout. Les impacts distants de moins d'une écaille
    sont fusionnés — la décimation laisse des coquilles millimétriques que
    le générateur documente déjà (`EPAISSEUR_ECAILLE_M`).
    """
    bruts = []
    for indice in grille.candidats(origine, direction, portee):
        r = croiser_triangle(origine, direction, grille.tris[indice])
        if r is not None:
            bruts.append(r)
    bruts.sort(key=lambda e: e[0])
    fusionnes = []
    for t, orientation in bruts:
        if fusionnes and t - fusionnes[-1][0] < ECAILLE_M * 0.2:
            continue
        fusionnes.append((t, orientation))
        if len(fusionnes) >= IMPACTS_MAX:
            break
    return fusionnes


# ---------------------------------------------------------------------------
# Géométrie de la cavité, recopiée du générateur.
# ---------------------------------------------------------------------------

def station_interpolee(u):
    """Station continue le long de l'axe. u ∈ [0, len(CAVITE) - 1]."""
    i = min(int(math.floor(u)), len(CAVITE) - 2)
    f = u - i
    a, b = CAVITE[i], CAVITE[i + 1]
    pa, pb = PALIER[i], PALIER[i + 1]
    return (a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f,
            a[2] + (b[2] - a[2]) * f, a[3] + (b[3] - a[3]) * f,
            pa + (pb - pa) * f)


def sol_attendu(u, lateral):
    """Hauteur théorique du sol, en repère modèle.

    Reprend `anneau_interieur` : `z = sag * v + PALIER[indice]` pour la
    moitié basse du profil, plus `PORCHE_DENIVELE` à la station 0. La
    cuvette est prise au plus profond (v = -1) sur l'axe et remonte vers
    les bords ; on borne donc la tolérance sur l'enveloppe des deux.
    """
    _, _, _, _, palier = station_interpolee(u)
    denivele = PORCHE_DENIVELE * max(0.0, 1.0 - u) if u < 1.0 else 0.0
    creux = -SAG * (1.0 - min(1.0, abs(lateral)))
    return palier + creux + denivele


def points_interieurs(pas_long, fractions_lat, hauteurs):
    """Points d'échantillonnage DANS le vide de la galerie.

    Les stations 0, 1, 7 et 8 sont incluses — c'est précisément ce que les
    contrôles du générateur sautent, et c'est là que la revue a vu le
    défaut.
    """
    sortie = []
    u = 0.0
    while u <= len(CAVITE) - 1 + 1e-9:
        ax, ay, hw, cle, palier = station_interpolee(u)
        for f in fractions_lat:
            sol = sol_attendu(u, f)
            for h in hauteurs:
                z = sol + h
                if z > palier + cle * 0.80:
                    continue
                sortie.append(dict(u=u, station=int(round(u)), lateral=f,
                                   hauteur=h,
                                   p=(ax + f * hw, ay, z),
                                   sol_attendu=sol, hw=hw, cle=cle))
        u += pas_long
    return sortie


AXES = [(1.0, 0.0, 0.0), (-1.0, 0.0, 0.0), (0.0, 1.0, 0.0),
        (0.0, -1.0, 0.0), (0.0, 0.0, 1.0), (0.0, 0.0, -1.0)]


def dans_le_vide(grille, point):
    """Le point est-il hors de la matière ?

    Parité sur six axes, vote majoritaire. Un point du vide donne un compte
    PAIR dans toutes les directions ; un point noyé dans la roche donne un
    compte impair. Le vote absorbe le cas rasant où un rayon effleure une
    arête. Rend (verdict, nombre de directions paires).
    """
    paires = 0
    for direction in AXES:
        if len(impacts(grille, point, direction)) % 2 == 0:
            paires += 1
    return paires >= 4, paires


def directions_sphere(nb_anneaux=7, nb_azimuts=14):
    """Directions couvrant la sphère ENTIÈRE, pôles compris.

    Le générateur ne tire que dans le plan perpendiculaire à l'axe et
    seulement vers le haut. Ici : élévations de -90° à +90°, azimuts sur
    360°. Le fond de la galerie (±Y) et le sol (-Z) sont donc couverts,
    et ce sont eux qui manquaient.
    """
    sortie = [(0.0, 0.0, -1.0), (0.0, 0.0, 1.0)]
    for i in range(1, nb_anneaux + 1):
        elevation = -math.pi / 2.0 + math.pi * i / (nb_anneaux + 1)
        for j in range(nb_azimuts):
            azimut = TAU * j / nb_azimuts
            sortie.append((math.cos(elevation) * math.cos(azimut),
                           math.cos(elevation) * math.sin(azimut),
                           math.sin(elevation)))
    return sortie


TAU = math.pi * 2.0


# ---------------------------------------------------------------------------
# CONTRÔLE 1 — LE PLANCHER. Celui qu'aucune fonction du générateur ne fait.
# ---------------------------------------------------------------------------

def controle_plancher(grille, echantillons):
    """Depuis l'intérieur, un rayon vers le BAS.

    Trois façons d'échouer, distinguées parce qu'elles n'appellent pas la
    même correction :

      * `aucun_impact`   — il n'y a rien du tout sous ce point : le
                           plancher est ABSENT, on voit le terrain gelé ;
      * `parite_impaire` — le rayon sort par un trou après avoir traversé
                           un bord de dalle ;
      * `sol_trop_bas`   — il y a bien un sol, mais plus bas que le profil
                           de la cavité : le rayon est tombé PAR un trou et
                           a atterri sur l'assise enterrée ou sur le fond
                           de la formation.

    Le troisième est le plus traître : un contrôle qui se contenterait de
    « quelque chose est touché » le déclarerait vert.
    """
    fautes = []
    testes = 0
    for ech in echantillons:
        vide, _ = dans_le_vide(grille, ech["p"])
        if not vide:
            continue          # point noyé dans la roche : hors sujet ici
        testes += 1
        liste = impacts(grille, ech["p"], (0.0, 0.0, -1.0))
        attendu = ech["p"][2] - ech["sol_attendu"]
        if not liste:
            fautes.append(dict(genre="aucun_impact", station=ech["station"],
                               u=round(ech["u"], 2), x=round(ech["p"][0], 2),
                               y=round(ech["p"][1], 2), z=round(ech["p"][2], 2),
                               lateral=ech["lateral"], impacts=0,
                               chute_attendue_m=round(attendu, 3)))
            continue
        premier = liste[0][0]
        if len(liste) % 2 != 0:
            fautes.append(dict(genre="parite_impaire", station=ech["station"],
                               u=round(ech["u"], 2), x=round(ech["p"][0], 2),
                               y=round(ech["p"][1], 2), z=round(ech["p"][2], 2),
                               lateral=ech["lateral"], impacts=len(liste),
                               chute_reelle_m=round(premier, 3),
                               chute_attendue_m=round(attendu, 3)))
        elif premier - attendu > PLANCHER_TOLERANCE_M:
            fautes.append(dict(genre="sol_trop_bas", station=ech["station"],
                               u=round(ech["u"], 2), x=round(ech["p"][0], 2),
                               y=round(ech["p"][1], 2), z=round(ech["p"][2], 2),
                               lateral=ech["lateral"], impacts=len(liste),
                               chute_reelle_m=round(premier, 3),
                               chute_attendue_m=round(attendu, 3),
                               ecart_m=round(premier - attendu, 3)))
    return testes, fautes


# ---------------------------------------------------------------------------
# CONTRÔLE 2 — LE JOUR, sur la sphère entière.
# ---------------------------------------------------------------------------

def sort_par_la_bouche(origine, direction):
    """Le rayon quitte-t-il la cavité par l'OUVERTURE, et non par un trou ?

    SANS CE FILTRE LA SONDE MENT. Un premier jet signalait 61 « percées » à
    la station 0, azimuts 252 à 324° : ce sont les rayons qui sortent par la
    bouche, c'est-à-dire le fonctionnement normal d'une grotte. Un contrôle
    qui appelle « défaut » la porte d'entrée finit désactivé, et à raison.

    Critère : le rayon traverse le plan du porche (y = -1,15) vers l'avant,
    et son point de passage tombe dans la section de la station 0.

    L'ouverture est prise GÉNÉREUSEMENT — demi-largeur majorée du facteur
    d'asymétrie maximal de `CAVITE_ASYM` (1,34), clé majorée de 5 %. C'est
    un arbitrage explicite : un trou situé exactement sur le pourtour de la
    bouche serait absous. L'inverse — un faux positif à chaque rayon
    sortant — noierait les vraies percées sous soixante bruits.
    """
    ax, ay, hw, cle = CAVITE[0]
    if direction[1] >= -1e-9:
        return False                      # ne va pas vers la bouche
    t = (ay - origine[1]) / direction[1]
    if t <= 0.0:
        return False                      # le porche est derrière le point
    px = origine[0] + direction[0] * t
    pz = origine[2] + direction[2] * t
    sol = PORCHE_DENIVELE - SAG
    return (abs(px - ax) <= hw * 1.34
            and sol - 0.10 <= pz <= cle * 1.05)


def dans_enveloppe(point):
    """Le point est-il dans l'enveloppe NOMINALE de la cavité ?

    Enveloppe analytique, calculée depuis `CAVITE`/`PALIER` — pas depuis le
    maillage. Elle sert à dire OÙ un rayon quitte la galerie, ce que le
    maillage ne peut pas dire quand justement il n'y a rien à cet endroit.
    Majorée du facteur d'asymétrie maximal de `CAVITE_ASYM` (1,34).
    """
    y = point[1]
    if y < CAVITE[0][1] or y > CAVITE[-1][1]:
        return False
    u = 0.0
    for i in range(len(CAVITE) - 1):
        if CAVITE[i][1] <= y <= CAVITE[i + 1][1]:
            span = CAVITE[i + 1][1] - CAVITE[i][1]
            u = i + ((y - CAVITE[i][1]) / span if span else 0.0)
            break
    ax, _, hw, cle, palier = station_interpolee(u)
    sol = palier - SAG - (PORCHE_DENIVELE if u < 1.0 else 0.0) * 0.0
    if u < 1.0:
        sol += PORCHE_DENIVELE * (1.0 - u)
    return (abs(point[0] - ax) <= hw * 1.34
            and sol - 0.30 <= point[2] <= palier + cle * 1.10)


def sortie_de_cavite(origine, direction, portee=40.0, pas=0.10):
    """Dernier point du rayon encore dans l'enveloppe de cavité.

    C'est la LOCALISATION DU TROU : l'endroit où le rayon quitte la
    galerie sans avoir rencontré de roche. Le rendre en (station, azimut)
    donne une consigne de correction, là où un simple compte de percées
    ne donne qu'un rouge.
    """
    dernier = None
    t = 0.0
    while t <= portee:
        p = tuple(origine[k] + direction[k] * t for k in range(3))
        if dans_enveloppe(p):
            dernier = p
        elif dernier is not None:
            break
        t += pas
    return dernier


def controle_jour(grille, echantillons, directions):
    """Aucun rayon parti du vide de la galerie ne doit sortir par un trou.

    Critère : compte d'impacts PAIR et >= 2, SAUF si le rayon sort par la
    bouche. C'est le critère de `controle_aucun_jour`, appliqué aux
    directions qu'il ne tire pas — vers le bas, le long de l'axe, et aux
    stations 0, 1, 7, 8.
    """
    fautes = []
    hors_cavite = []
    testes = 0
    bouche = 0
    ecartes = 0
    for ech in echantillons:
        # LE PORCHE EST OUVERT PAR CONSTRUCTION, et le juger fabriquerait
        # des percées. La station 0 (y = -1,15) est la transition entre la
        # cavité et l'air libre : un rayon qui y part vers le haut-avant
        # sort par-dessus la lèvre, ce qui est le comportement voulu. Le
        # contrôle commence donc au SEUIL, station 1, y = 0,00. Le plancher,
        # lui, reste jugé au porche — et il y passe.
        if ech["p"][1] < CAVITE[1][1] - 1e-9:
            ecartes += 1
            continue
        vide, _ = dans_le_vide(grille, ech["p"])
        if not vide:
            continue
        # LE POINT DOIT ÊTRE DANS LA CAVITÉ, PAS SIMPLEMENT DANS LE VIDE.
        #
        # Sans ce garde-fou, un échantillon tombé HORS de la formation — au
        # ras d'une paroi, ou au-delà de la calotte du fond où le profil
        # théorique cesse d'être creux — passe `dans_le_vide` et fabrique
        # cent percées d'un coup. C'est le mode d'échec qui décrédibilise
        # une sonde : un rouge massif, plausible, et entièrement faux.
        #
        # Critère : la part de directions qui rencontrent de la roche. Une
        # galerie fermée à bouche unique enferme largement plus de la
        # moitié de la sphère ; un point en plein air, beaucoup moins. Le
        # seuil est bas EXPRÈS — il ne peut pas absoudre un vrai trou, car
        # un trou qui ouvrirait plus de la moitié du ciel ne serait plus un
        # trou mais le dehors.
        rencontres = sum(1 for d in directions
                         if impacts(grille, ech["p"], d, 40.0))
        part = rencontres / float(len(directions))
        if part < ENCLOSURE_MIN:
            hors_cavite.append(dict(station=ech["station"],
                                    x=round(ech["p"][0], 2),
                                    y=round(ech["p"][1], 2),
                                    z=round(ech["p"][2], 2),
                                    part_enclose=round(part, 3)))
            continue
        for direction in directions:
            if sort_par_la_bouche(ech["p"], direction):
                bouche += 1
                continue
            testes += 1
            liste = impacts(grille, ech["p"], direction)
            if len(liste) >= 2 and len(liste) % 2 == 0:
                continue
            azimut = math.degrees(math.atan2(direction[1], direction[0])) % 360.0
            elevation = math.degrees(math.asin(max(-1.0, min(1.0, direction[2]))))
            # Le point de SORTIE est ce qui distingue un vrai trou d'un
            # echantillonnage fautif : un vrai trou fait converger les
            # percees vers une meme region de la coque, un mauvais point
            # les disperse partout.
            sortie = sortie_de_cavite(ech["p"], direction) or ech["p"]
            fautes.append(dict(station=ech["station"], u=round(ech["u"], 2),
                               x=round(ech["p"][0], 2), y=round(ech["p"][1], 2),
                               z=round(ech["p"][2], 2),
                               azimut=round(azimut, 1),
                               elevation=round(elevation, 1),
                               impacts=len(liste),
                               sortie=[round(c, 2) for c in sortie]))
    return testes, bouche, ecartes, hors_cavite, fautes


def carte_du_plancher(grille, pas_long, fractions):
    """Où le plancher existe-t-il, et où manque-t-il ?

    Le contrôle 1 rend une liste de fautes ; celle-ci rend la CARTE, parce
    qu'une consigne de correction se formule en intervalle (« absent de tel
    y à tel y »), pas en nuage de points. Pour chaque abscisse le long de
    l'axe, on compte les positions latérales qui ont un sol à la hauteur
    attendue.
    """
    lignes = []
    u = 0.0
    while u <= len(CAVITE) - 1 + 1e-9:
        ax, ay, hw, cle, palier = station_interpolee(u)
        presents, absents = 0, 0
        pires = []
        zs = []
        for f in fractions:
            sol = sol_attendu(u, f)
            depart = (ax + f * hw, ay, sol + 0.90)
            vide, _ = dans_le_vide(grille, depart)
            if not vide:
                continue
            liste = impacts(grille, depart, (0.0, 0.0, -1.0))
            if not liste:
                absents += 1
                pires.append(99.0)
                continue
            ecart = liste[0][0] - 0.90
            if ecart > PLANCHER_TOLERANCE_M:
                absents += 1
                # LE Z ABSOLU DE L'IMPACT EST L'ARGUMENT DÉCISIF. S'il se
                # groupe autour du sommet de l'assise enterrée (z = -0,55),
                # alors ce que le joueur prend pour le sol de la galerie est
                # le dessus du pavé enterré, et non le profil de la cavité.
                zs.append(depart[2] - liste[0][0])
            else:
                presents += 1
            pires.append(ecart)
        lignes.append(dict(u=round(u, 2), y=round(ay, 2),
                           station=int(round(u)), presents=presents,
                           absents=absents,
                           z_impact_trou=round(sum(zs) / len(zs), 3) if zs else None,
                           ecart_max_m=round(max(pires), 3) if pires else None))
        u += pas_long
    return lignes


# ---------------------------------------------------------------------------
# CONTRÔLE 3 — LA LIGNE DE VUE, avec la règle du moteur.
# ---------------------------------------------------------------------------

def _normaliser(v):
    n = math.sqrt(sum(c * c for c in v))
    return tuple(c / n for c in v)


def _croix(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])


def monde_vers_modele(point, origine_monde, lacet_deg):
    """Monde Godot -> repère modèle Blender.

    L'ouvrage est posé sans échelle, avec un seul lacet autour de Y
    (`waterfall_cave_place.gd` : `ouvrage.rotation.y = deg_to_rad(45)`), et
    le lieu lui-même n'a AUCUNE rotation (`world_v2_places_builder.gd` :
    `place.position = Vector3(...)` et rien d'autre). La transformation est
    donc une translation suivie d'une rotation, et son inverse s'écrit sans
    matrice.
    """
    dx = point[0] - origine_monde[0]
    dy = point[1] - origine_monde[1]
    dz = point[2] - origine_monde[2]
    a = math.radians(-lacet_deg)
    lx = dx * math.cos(a) + dz * math.sin(a)
    lz = -dx * math.sin(a) + dz * math.cos(a)
    return (lx, -lz, dy)          # local Godot Y-up -> modele Blender Z-up


def direction_monde_vers_modele(direction, lacet_deg):
    a = math.radians(-lacet_deg)
    lx = direction[0] * math.cos(a) + direction[2] * math.sin(a)
    lz = -direction[0] * math.sin(a) + direction[2] * math.cos(a)
    return (lx, -lz, direction[1])


def carte_du_fond(grille, pas=0.25):
    """L'ouverture ARRIÈRE, cartographiée face au fond de la galerie.

    Le contrôle 2 dit qu'il y a des percées et d'où elles partent ; celle-ci
    dit la FORME et l'EMPRISE du trou, vues de derrière. Un rayon part de
    y = +14 (hors emprise, le maillage s'arrête à y = +10,64) vers -Y : s'il
    dépasse le fond de la galerie sans rien toucher, la case est ouverte.

    Le balayage est borné à l'emprise de la DERNIÈRE station, majorée : au
    delà on ne mesure plus la grotte mais l'air à côté du rocher, et compter
    cet air comme un trou serait un faux positif.
    """
    ax, ay, hw, cle = CAVITE[-1]
    x0, x1 = ax - hw * 1.34, ax + hw * 1.34
    z0, z1 = PALIER[-1] - SAG - 0.20, PALIER[-1] + cle * 1.05
    ouvertes, total, lignes = [], 0, []
    z = z1
    while z >= z0:
        ligne, x = "", x0
        while x <= x1:
            liste = impacts(grille, (x, 14.0, z), (0.0, -1.0, 0.0))
            premier = 14.0 - liste[0][0] if liste else -99.0
            total += 1
            if premier < ay - 1.0:
                ligne += "O"
                ouvertes.append((round(x, 2), round(z, 2)))
            else:
                ligne += "."
            x += pas
        lignes.append((round(z, 2), ligne))
        z -= pas
    return dict(x0=round(x0, 2), x1=round(x1, 2), lignes=lignes,
                cases_ouvertes=len(ouvertes), cases=total,
                ouvertes=ouvertes)


def controle_ligne_de_vue(grille, prise, origine_monde, lacet_deg, pas_px):
    """Pour chaque pixel visé, le premier triangle FACE AVANT existe-t-il ?

    Godot rend en `cull_back` : le pixel affiche le premier triangle dont
    la normale regarde la caméra. Aucun ? Alors le pixel montre ce qui est
    DERRIÈRE la grotte — terrain, végétation, ciel. C'est le défaut vu par
    la revue, exprimé dans les termes du moteur.

    On ne signale QUE les pixels qui traversent réellement la cavité : un
    pixel qui vise le ciel à côté de la formation n'a évidemment aucun
    impact, et le compter serait un faux positif — le genre de faux positif
    qui fait désactiver un garde-fou.
    """
    camera = prise["from"]
    cible = prise["look"]
    fov = prise["fov"]
    largeur, hauteur = prise["taille"]

    avant = _normaliser((cible[0] - camera[0], cible[1] - camera[1],
                         cible[2] - camera[2]))
    axe_z = (-avant[0], -avant[1], -avant[2])
    axe_x = _normaliser(_croix((0.0, 1.0, 0.0), axe_z))
    axe_y = _croix(axe_z, axe_x)
    # `Camera3D.keep_aspect` vaut KEEP_HEIGHT par défaut : `fov` est donc
    # l'angle VERTICAL. VISUAL_ASSET_BIBLE §3.1 prévient explicitement du
    # contresens ; on ne le refait pas.
    demi_v = math.tan(math.radians(fov) * 0.5)
    demi_h = demi_v * largeur / float(hauteur)

    origine_modele = monde_vers_modele(camera, origine_monde, lacet_deg)
    lo, hi = grille.aabb()
    percees = []
    traversants = 0
    for py in range(0, hauteur, pas_px):
        for px in range(0, largeur, pas_px):
            ndc_x = (px + 0.5) / largeur * 2.0 - 1.0
            ndc_y = 1.0 - (py + 0.5) / hauteur * 2.0
            monde = (avant[0] + ndc_x * demi_h * axe_x[0] + ndc_y * demi_v * axe_y[0],
                     avant[1] + ndc_x * demi_h * axe_x[1] + ndc_y * demi_v * axe_y[1],
                     avant[2] + ndc_x * demi_h * axe_x[2] + ndc_y * demi_v * axe_y[2])
            direction = _normaliser(direction_monde_vers_modele(
                _normaliser(monde), lacet_deg))
            liste = impacts(grille, origine_modele, direction)
            if not liste:
                continue          # ne vise pas la formation : hors sujet
            traversants += 1
            if any(orientation < 0.0 for _, orientation in liste):
                continue          # de la roche est affichée : rien à dire
            sortie = [origine_modele[k] + direction[k] * liste[-1][0]
                      for k in range(3)]
            percees.append(dict(px=px, py=py, impacts=len(liste),
                                sortie=[round(c, 2) for c in sortie]))
    return traversants, percees


def grouper_pixels(percees, pas_px):
    """Boîtes de pixels connexes — lisible à côté de la capture."""
    restants = {(p["px"], p["py"]): p for p in percees}
    boites = []
    while restants:
        depart = next(iter(restants))
        pile = [depart]
        amas = []
        del restants[depart]
        while pile:
            cle = pile.pop()
            amas.append(cle)
            for dx, dy in ((pas_px, 0), (-pas_px, 0), (0, pas_px), (0, -pas_px)):
                voisin = (cle[0] + dx, cle[1] + dy)
                if voisin in restants:
                    del restants[voisin]
                    pile.append(voisin)
        xs = [c[0] for c in amas]
        ys = [c[1] for c in amas]
        boites.append(dict(pixels=len(amas), x0=min(xs), x1=max(xs) + pas_px - 1,
                           y0=min(ys), y1=max(ys) + pas_px - 1))
    boites.sort(key=lambda b: -b["pixels"])
    return boites


# ---------------------------------------------------------------------------
# Cohérence des cotes recopiées.
# ---------------------------------------------------------------------------

## Exhaussement du sol construit au-dessus du terrain gelé, recopié de
## `waterfall_cave_place.gd`. Le terrain se trouve donc à `-EXHAUSSEMENT` en
## repère modèle, PAR CONSTRUCTION : le script de lieu pose l'ouvrage à
## `terrain + EXHAUSSEMENT`.
EXHAUSSEMENT = 0.50
## Hauteur des touffes d'herbe gelées, mesurée et consignée dans les
## commentaires de `make_waterfall_cave.py` (« hautes d'environ 0,30 m »).
HERBE_M = 0.30


def controle_garde_au_terrain():
    """Le profil DÉCLARÉ garde-t-il assez d'air au-dessus du terrain gelé ?

    CE CONTRÔLE FERME UN CONTOURNEMENT, IL NE MESURE PAS UN DÉFAUT.

    Les contrôles 1 à 3 vérifient que le sol RÉALISÉ correspond au profil
    DÉCLARÉ (`PALIER`, `SAG`, `PORCHE_DENIVELE`). Cette formulation a un
    angle mort, et il faut le dire avant que quelqu'un tombe dedans :
    ABAISSER le profil déclaré jusqu'au niveau de l'assise enterrée ferait
    passer le contrôle 1 au vert sans rien réparer. Le sol de la galerie
    serait simplement descendu d'un demi-mètre, les touffes d'herbe gelées
    continueraient de le traverser, et la mesure dirait « conforme ».

    On vérifie donc, sur les CONSTANTES seules et sans aucun maillage, que
    le profil déclaré laisse plus que la hauteur de l'herbe au-dessus du
    terrain gelé.

    La station 0 est exclue : la lèvre du porche est enterrée à dessein
    (`PORCHE_DENIVELE`), et c'est ce qui fait du mètre de porche un seuil
    de roche que l'on monte.
    """
    fautes = []
    for i in range(1, len(CAVITE)):
        sol = PALIER[i] - SAG
        garde = sol + EXHAUSSEMENT
        if garde < HERBE_M:
            fautes.append(dict(station=i, sol_declare=round(sol, 3),
                               garde_m=round(garde, 3)))
    return fautes


def controle_coherence_cotes(source):
    """Les cotes de la sonde correspondent-elles encore au générateur ?

    Lecture TEXTUELLE, sans `bpy`. Si le générateur change ses stations et
    que la sonde garde les siennes, elle mesure une grotte qui n'existe
    plus — et le pire est qu'elle continuerait de rendre des chiffres
    plausibles. Une divergence est donc un blocage, pas un avertissement.
    """
    if not os.path.isfile(source):
        return ["source du generateur introuvable : %s" % source]
    texte = open(source, "r", encoding="utf-8").read()
    ecarts = []
    for nom, valeur in (("SAG", SAG), ("PORCHE_DENIVELE", PORCHE_DENIVELE)):
        marque = "\n%s = " % nom
        if marque not in texte:
            ecarts.append("constante %s absente du generateur" % nom)
            continue
        lu = texte.split(marque, 1)[1].split("\n", 1)[0].split("#")[0].strip()
        if abs(float(lu) - valeur) > 1e-9:
            ecarts.append("%s : generateur %s, sonde %s" % (nom, lu, valeur))
    if "PALIER = (" in texte:
        lu = texte.split("PALIER = (", 1)[1].split(")", 1)[0]
        valeurs = tuple(float(v) for v in lu.replace("\n", " ").split(",")
                        if v.strip())
        if valeurs != PALIER:
            ecarts.append("PALIER : generateur %s, sonde %s" % (valeurs, PALIER))
    if "CAVITE = [" in texte:
        bloc = texte.split("CAVITE = [", 1)[1].split("]", 1)[0]
        lignes = [l.split("#")[0].strip().strip(",")
                  for l in bloc.split("\n") if l.strip().startswith("(")]
        valeurs = []
        for ligne in lignes:
            valeurs.append(tuple(float(v) for v in
                                 ligne.strip("()").split(",") if v.strip()))
        if valeurs != [tuple(s) for s in CAVITE]:
            ecarts.append("CAVITE : %d station(s) au generateur, la sonde ne "
                          "correspond pas" % len(valeurs))
    return ecarts


# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(
        description="Sonde de continuite de la Grotte du Couchant "
                    "(plancher, jours, ligne de vue).")
    ap.add_argument("glb", nargs="?",
                    default="assets/environment/caves/SM_WaterfallCave.glb")
    ap.add_argument("--source",
                    default="source_assets/blender/environment/"
                            "make_waterfall_cave.py")
    ap.add_argument("--manifeste", default=None,
                    help="manifeste de capture ; active le controle 3")
    ap.add_argument("--origine-monde", default="-106.0,3.50,3.5",
                    help="origine monde de l'ouvrage (x,y,z). Deduite du "
                         "layout et de SEUIL_LOCAL ; le controle 3 verifie "
                         "lui-meme sa plausibilite.")
    ap.add_argument("--lacet", type=float, default=45.0)
    ap.add_argument("--pas-pixel", type=int, default=8)
    ap.add_argument("--json", default=None)
    ap.add_argument("--rapide", action="store_true",
                    help="echantillonnage reduit, pour iterer")
    args = ap.parse_args()

    print("=" * 74)
    print("SONDE DE CONTINUITE — Grotte du Couchant")
    print("=" * 74)

    try:
        ecarts = controle_coherence_cotes(args.source)
        if ecarts:
            for e in ecarts:
                print("BLOQUE: cotes divergentes — %s" % e)
            return 3
        print("cotes  : CAVITE, PALIER, SAG, PORCHE_DENIVELE conformes au "
              "generateur")
        garde = controle_garde_au_terrain()
        if garde:
            print("BLOQUE: le profil DECLARE du sol ne garde pas %.2f m "
                  "au-dessus du terrain gele — un profil abaisse ferait "
                  "verdir le controle 1 sans rien reparer :" % HERBE_M)
            for f in garde:
                print("        station %d : sol declare %+.3f, garde %.3f m"
                      % (f["station"], f["sol_declare"], f["garde_m"]))
            return 3
        print("garde  : le profil declare laisse au moins %.2f m au-dessus du "
              "terrain a toutes les stations (herbe %.2f m)"
              % (min(PALIER[i] - SAG + EXHAUSSEMENT
                     for i in range(1, len(CAVITE))), HERBE_M))
        tris, par_matiere = triangles_du_glb(args.glb)
    except Blocage as erreur:
        print("BLOQUE: %s" % erreur)
        return 3

    print("maillage rendu : %d triangles (COL_WaterfallCave ecarte)" % len(tris))
    for nom, compte in sorted(par_matiere.items(), key=lambda kv: -kv[1]):
        print("   %-22s %6d tris" % (nom, compte))
    grille = Grille(tris)
    lo, hi = grille.aabb()
    print("emprise modele : x[%.2f..%.2f] y[%.2f..%.2f] z[%.2f..%.2f]"
          % (lo[0], hi[0], lo[1], hi[1], lo[2], hi[2]))

    pas_long = 0.50 if args.rapide else 0.25
    fractions = (-0.45, 0.0, 0.45) if args.rapide else (-0.60, -0.30, 0.0, 0.30, 0.60)
    hauteurs = (0.60, 1.40) if args.rapide else (0.35, 0.90, 1.50)
    echantillons = points_interieurs(pas_long, fractions, hauteurs)
    print("echantillons interieurs : %d (stations 0 a 8, les quatre que le "
          "generateur saute comprises)" % len(echantillons))

    resultat = dict(glb=args.glb, triangles=len(tris),
                    triangles_par_matiere=par_matiere)
    rouge = False

    print()
    print("-" * 74)
    print("CONTROLE 1 — PLANCHER (rayon vers le BAS depuis l'interieur)")
    print("-" * 74)
    print("Aucune fonction du generateur ne fait ce controle :")
    print("  controle_epaisseur  : `if math.sin(theta) < -0.30: continue`")
    print("  controle_aucun_jour : `Vector((0.0, 0.0, 1.0))` — vers le HAUT")
    testes, fautes = controle_plancher(grille, echantillons)
    print("%d point(s) du vide sondes vers le bas, %d faute(s)"
          % (testes, len(fautes)))
    resultat["plancher"] = dict(points_testes=testes, fautes=fautes)
    if fautes:
        rouge = True
        genres = {}
        for f in fautes:
            genres[f["genre"]] = genres.get(f["genre"], 0) + 1
        for genre, compte in sorted(genres.items()):
            print("   %-16s %4d" % (genre, compte))
        ys = [f["y"] for f in fautes]
        stations = sorted(set(f["station"] for f in fautes))
        print("   emprise des fautes : y[%.2f .. %.2f], stations %s"
              % (min(ys), max(ys), ", ".join(str(s) for s in stations)))
        for f in sorted(fautes, key=lambda e: -e.get("ecart_m", 99))[:8]:
            print("   %-16s station %d  (x %6.2f, y %6.2f, z %6.2f)  "
                  "impacts %d  chute %s m (attendue %.2f)"
                  % (f["genre"], f["station"], f["x"], f["y"], f["z"],
                     f["impacts"],
                     ("%.2f" % f["chute_reelle_m"]) if "chute_reelle_m" in f
                     else "aucune", f["chute_attendue_m"]))
    else:
        print("   PASS — un sol existe sous chaque point sonde, a la hauteur "
              "attendue")

    print()
    print("   CARTE DU PLANCHER (positions laterales avec sol / sans sol) :")
    carte = carte_du_plancher(grille, pas_long, fractions)
    resultat["plancher"]["carte"] = carte
    manquants = [l for l in carte if l["absents"] > 0]
    for ligne in carte:
        barre = "#" * ligne["presents"] + "." * ligne["absents"]
        marque = "  <-- TROU" if ligne["absents"] else ""
        print("      y %+6.2f  station %d  %-8s %d/%d  ecart max %s m  z du fond %s%s"
              % (ligne["y"], ligne["station"], barre, ligne["presents"],
                 ligne["presents"] + ligne["absents"],
                 ("%.2f" % ligne["ecart_max_m"]) if ligne["ecart_max_m"] is not None
                 else "-",
                 ("%+.2f" % ligne["z_impact_trou"]) if ligne["z_impact_trou"]
                 is not None else "   -", marque))
    if manquants:
        rouge = True
        ys = [l["y"] for l in manquants]
        sts = sorted(set(l["station"] for l in manquants))
        resume = ("plancher absent de y = %+.2f a y = %+.2f (stations %s)"
                  % (min(ys), max(ys), " a ".join([str(sts[0]), str(sts[-1])])))
        print("   >>> %s" % resume)
        resultat["plancher"]["resume"] = resume

    print()
    print("-" * 74)
    print("CONTROLE 2 — JOUR (sphere entiere, stations 0 a 8)")
    print("-" * 74)
    directions = directions_sphere(5, 10) if args.rapide else directions_sphere(7, 14)
    print("%d direction(s) par point, elevations -90 a +90 : le fond (±Y) et "
          "le sol (-Z) sont couverts" % len(directions))
    testes_j, bouche_j, ecartes_j, hors_j, fautes_j = controle_jour(
        grille, echantillons, directions)
    print("%d point(s) du porche ecarte(s) (ouvert par construction)" % ecartes_j)
    print("%d point(s) ecarte(s) comme HORS CAVITE (enclosure < %.2f)"
          % (len(hors_j), ENCLOSURE_MIN))
    print("%d rayon(s) juges, %d ecarte(s) parce qu'ils sortent par la BOUCHE, "
          "%d percee(s)" % (testes_j, bouche_j, len(fautes_j)))
    resultat["jour"] = dict(rayons_testes=testes_j, rayons_par_la_bouche=bouche_j,
                            points_porche_ecartes=ecartes_j,
                            points_hors_cavite=hors_j, fautes=fautes_j)
    if fautes_j:
        rouge = True
        stations = {}
        for f in fautes_j:
            stations.setdefault(f["station"], []).append(f)
        for station in sorted(stations):
            lot = stations[station]
            azimuts = sorted(set(round(f["azimut"]) for f in lot))
            elevations = sorted(set(round(f["elevation"]) for f in lot))
            print("   station %d : %3d percee(s), azimuts %s, elevations %s"
                  % (station, len(lot),
                     "%d..%d" % (azimuts[0], azimuts[-1]),
                     "%d..%d" % (elevations[0], elevations[-1])))
        print("   OU LES RAYONS SORTENT (regroupe par maille de 1,5 m sur la "
              "coque) — un vrai trou fait converger, un mauvais point disperse :")
        amas = {}
        for f in fautes_j:
            cle = tuple(int(math.floor(c / 1.0)) for c in f["sortie"])
            amas.setdefault(cle, []).append(f)
        for cle, lot in sorted(amas.items(), key=lambda kv: -len(kv[1]))[:8]:
            xs = [f["sortie"][0] for f in lot]
            ys = [f["sortie"][1] for f in lot]
            zs2 = [f["sortie"][2] for f in lot]
            sts = sorted(set(f["station"] for f in lot))
            print("      %3d rayon(s) quittent la galerie en x~%+.2f y~%+.2f z~%+.2f "
                  " (stations de depart %s)"
                  % (len(lot), sum(xs) / len(xs), sum(ys) / len(ys),
                     sum(zs2) / len(zs2),
                     ",".join(str(s) for s in sts)))
        resultat["jour"]["amas_de_sortie"] = [
            dict(rayons=len(lot),
                 centre=[round(sum(f["sortie"][k] for f in lot) / len(lot), 2)
                         for k in range(3)],
                 stations=sorted(set(f["station"] for f in lot)))
            for cle, lot in sorted(amas.items(), key=lambda kv: -len(kv[1]))]
    else:
        print("   PASS — aucun rayon ne sort du vide de la galerie")

    print()
    print("   CARTE DU FOND (vue de derriere, emprise de la derniere station)")
    print("   'O' = le rayon traverse la galerie de part en part")
    fond = carte_du_fond(grille)
    resultat["jour"]["carte_du_fond"] = dict(
        x0=fond["x0"], x1=fond["x1"], cases_ouvertes=fond["cases_ouvertes"],
        cases=fond["cases"], lignes=[[z, l] for z, l in fond["lignes"]])
    for z, ligne in fond["lignes"]:
        print("      z %+5.2f  %s" % (z, ligne))
    print("      x de %+.2f a %+.2f, pas 0,25 m" % (fond["x0"], fond["x1"]))
    if fond["ouvertes"]:
        rouge = True
        xs = [c[0] for c in fond["ouvertes"]]
        zs = [c[1] for c in fond["ouvertes"]]
        resume_fond = ("fond de la galerie OUVERT : %d case(s) sur %d, "
                       "emprise x[%+.2f .. %+.2f] z[%+.2f .. %+.2f], "
                       "soit %.2f x %.2f m"
                       % (fond["cases_ouvertes"], fond["cases"], min(xs),
                          max(xs), min(zs), max(zs),
                          max(xs) - min(xs), max(zs) - min(zs)))
        print("   >>> %s" % resume_fond)
        resultat["jour"]["resume"] = resume_fond
    else:
        print("      aucune case ouverte : le fond de la galerie est plein")

    print()
    print("-" * 74)
    print("CONTROLE 3 — LIGNE DE VUE (regle du moteur : cull_back)")
    print("-" * 74)
    if args.manifeste is None:
        print("NON VERIFIE — aucun manifeste fourni (--manifeste)")
        resultat["ligne_de_vue"] = "NON VERIFIE"
    elif not os.path.isfile(args.manifeste):
        print("BLOQUE: manifeste introuvable : %s" % args.manifeste)
        return 3
    else:
        origine = tuple(float(v) for v in args.origine_monde.split(","))
        manifeste = json.load(open(args.manifeste, "r", encoding="utf-8"))
        taille = manifeste.get("size", "1280x720").split("x")
        taille = (int(taille[0]), int(taille[1]))
        print("origine monde de l'ouvrage : %s, lacet %.0f°"
              % (str(origine), args.lacet))
        lignes = []
        for prise in manifeste.get("shots", []):
            prise = dict(prise)
            prise["taille"] = taille
            traversants, percees = controle_ligne_de_vue(
                grille, prise, origine, args.lacet, args.pas_pixel)
            boites = grouper_pixels(percees, args.pas_pixel)
            etat = "PASS" if not percees else "FAIL"
            print("   %-26s %5d pixel(s) sur la formation, %4d percant(s)  %s"
                  % (prise["name"], traversants, len(percees), etat))
            for b in boites[:6]:
                print("        boite x[%4d..%4d] y[%4d..%4d]  %d pixel(s)"
                      % (b["x0"], b["x1"], b["y0"], b["y1"], b["pixels"]))
            if traversants == 0:
                print("        ATTENTION: aucun pixel ne touche la formation "
                      "— la transformation monde->modele est probablement "
                      "fausse, ce resultat ne prouve rien")
            lignes.append(dict(nom=prise["name"], pixels_formation=traversants,
                               pixels_percants=len(percees), boites=boites))
            if percees:
                rouge = True
        resultat["ligne_de_vue"] = lignes

    print()
    print("=" * 74)
    print("VERDICT : %s" % ("FAIL — defaut mesure" if rouge else "PASS"))
    print("=" * 74)

    if args.json:
        dossier = os.path.dirname(args.json)
        if dossier and not os.path.isdir(dossier):
            os.makedirs(dossier)
        resultat["verdict"] = "FAIL" if rouge else "PASS"
        with open(args.json, "w", encoding="utf-8") as poignee:
            json.dump(resultat, poignee, indent=1, sort_keys=True,
                      ensure_ascii=False)
        print("sortie brute : %s" % args.json)
    return 1 if rouge else 0


if __name__ == "__main__":
    sys.exit(main())
