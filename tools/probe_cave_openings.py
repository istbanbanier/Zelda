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

DOMAINE DE VALIDITÉ — la limite qui n'est pas un défaut mais une frontière
=========================================================================

`EXPLOITABLE DANS LA CAVITÉ DÉCLARÉE`. Toutes les mesures de ce fichier
s'ancrent sur `CAVITE` et `PALIER` : stations, normale locale, demi-largeur
de chaque côté. C'est ce qui les rend justes sur une galerie asymétrique et
infléchie — et c'est aussi ce qui borne leur portée.

`CAVITE` s'arrête à `ay = 3,17`. Mesure du 2026-08-16 sur `cc3596c5`, par
colonnes verticales et SANS station (`tools/cave_seal_oracle.py`) : du vide
connecté à la galerie court jusqu'à `y ≈ 7,0` au moins, et l'épaisseur de
roche au-dessus y tombe à **0,054 m** vers `(x 0,58 ; y 5,80)`, contre
`EPAISSEUR_MIN_M = 0,80`.

Cette zone n'est pas mal échantillonnée : elle est **hors du domaine**.
Aucun réglage de pas, aucune correction de placement ne l'y fera entrer.
Un `0 percée` de cette sonde signifie donc « zéro percée dans la cavité
déclarée », jamais « zéro percée dans le maillage ».

Ce qui regarde sans station, et qu'il faut croiser : `tools/cave_seal_oracle.py`
(classement de l'espace) et `tools/audit_cave_floor_columns.py` (colonnes
verticales).

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
## LA FAMILLE DE FAUTE QUI REVIENT — DÉCOMPTE TENU À JOUR, SANS « DERNIER ».
##
## Une seule erreur, commise dix fois : **employer un axe du MONDE là où le
## repère LOCAL de la section est requis** — décaler le long de X au lieu de
## la normale, ou appliquer une demi-largeur symétrique à une section qui ne
## l'est pas, ou attribuer une station par la seule coordonnée `y`.
##
## | # | endroit | ce que ça faussait |
## |---|---|---|
## | 1 | `dans_enveloppe` | localisation d'un trou |
## | 2 | `sort_par_la_bouche` | 1,05 m de roche pleine absous au porche |
## | 3 | `_emprise_noyau` | emprise du raster décalée |
## | 4 | `dans_le_noyau` | noyau débordant dans la roche |
## | 5 | `cle_au_lateral` | 16 percées de toit qui étaient la porte |
## | 6 | `points_interieurs` | 36 % du côté large jamais visité |
## | 7 | `carte_du_plancher` | **le rouge de plancher des stations 6 à 8** |
## | 8 | `carte_du_fond` | fenêtre arrière trop étroite à gauche, trop large à droite |
## | 9 | `surface_de_sortie` | percée attribuée au mauvais flanc |
## | 10 | `u_pour_y` sur point décalé | point réel de l'alcôve déclaré hors cavité |
##
## Le n° 7 a été trouvé par l'agent plancher, pas par cet outil, alors même
## que le n° 6 portait le mot « DERNIER ». C'est la raison d'être de ce
## tableau : il n'a pas de ligne finale, et une passe qui n'en ajoute aucune
## doit le dire plutôt que le supposer.
##
## Onzième défaut, de la même famille mais distinct : comparer la hauteur
## mesurée d'un point au sol ATTENDU d'une AUTRE station — voir
## `station_reelle_du_point`.
FAMILLE_REPERE_LOCAL = 10

CAVITE = [
    (0.00, -1.15, 1.90, 2.80),
    (0.00,  0.00, 1.70, 2.85),
    (0.22,  1.05, 1.75, 2.90),
    (1.00,  1.62, 2.10, 2.90),
    (1.82,  2.12, 2.60, 2.92),
    (2.62,  2.58, 3.00, 2.92),
    (3.10,  2.88, 2.50, 2.80),
    (3.40,  3.06, 1.85, 2.45),
    (3.58,  3.17, 1.30, 2.00),
]
PALIER = (0.00, 0.00, 0.02, 0.06, 0.10, 0.16, 0.34, 0.56, 0.70)
SAG = 0.08
PORCHE_DENIVELE = -0.58

## L'ASYMÉTRIE PAR STATION — `(gauche, droite, inclinaison)`, recopiée de
## `CAVITE_ASYM` du générateur.
##
## POURQUOI ELLE ARRIVE TARD, ET CE QU'ELLE RÉPARE.
##
## La sonde ne connaissait de l'asymétrie qu'un SCALAIRE : `asym = 1.34`, le
## facteur MAXIMAL de la table, appliqué des DEUX côtés. C'est la faute
## récurrente de cette passe — un seul nombre qui répond à une autre question
## que celle posée — et elle avait ici deux conséquences mesurables :
##
##   * `sort_par_la_bouche()` absolvait tout rayon sortant à moins de
##     1,34·hw de l'axe. Au porche, le côté DROIT ne va qu'à 0,79·hw : la
##     bande entre 0,79·hw et 1,34·hw est de la ROCHE PLEINE, et un trou qui
##     s'y trouvait était classé « sort par la bouche », donc absous. La
##     bouche déclarée était 70 % trop large de ce côté (1,34/0,79).
##   * `dans_enveloppe()` déclarait « encore dans la galerie » des points
##     situés dans le massif, ce qui déplace la localisation d'un trou.
##
## Le générateur applique `demi = hw · (gauche si u < 0 sinon droite)` avec
## `u = cos(azimut)` (`anneau_interieur`). Le côté est donc décidé par le
## SIGNE DE L'OFFSET NORMAL, et les deux côtés ne partagent aucun rayon.
CAVITE_ASYM = [
    (1.34, 0.79, -0.44),
    (1.30, 0.81, -0.40),
    (0.56, 1.15, -0.24),
    (0.97, 1.05, 0.10),
    (1.68, 0.41, 0.16),
    (1.69, 0.33, 0.08),
    (1.69, 0.25, -0.06),
    (1.65, 0.27, -0.12),
    (1.61, 0.25, -0.10),
]

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

## TREIZIÈME DÉFAUT, ET IL A FABRIQUÉ 101 PERCÉES.
##
## Ce seuil comptait une direction comme « enclose » dès que `impacts()`
## rendait quelque chose dans les 40 m. Ce n'est pas « je suis dans une
## grotte » : c'est « je vois de la roche quelque part ». Un point posé EN
## PLEIN AIR contre un massif de vingt mètres voit de la roche dans les
## trois quarts du ciel et passait donc un seuil de 0,50 sans difficulté.
##
## Mesuré sur `SM_WaterfallCave_BASE352.glb`, sur les origines des 101
## percées confirmées :
##
##   * **81 origines sur 150 ont au moins UNE direction cardinale qui ne
##     rencontre aucune roche** — vers le haut, ou vers +X, à l'infini ;
##   * 19 à 29 des 100 directions de sphère s'échappent sans rien toucher ;
##   * et l'enclosure mesurée valait pourtant 0,71 à 0,81.
##
## Un point d'où l'on voit le ciel n'est pas dans une grotte. Le critère est
## donc désormais : AUCUNE direction ne doit s'échapper — sauf par la
## bouche, qui est une ouverture légitime et que `sort_par_la_bouche` sait
## reconnaître. Le seuil monte en conséquence.
ENCLOSURE_MIN = 0.95

## Les six cardinales doivent TOUTES rencontrer de la roche ou sortir par la
## bouche. C'est le test qui sépare le plus franchement le dedans du dehors,
## et c'est celui qui manquait.
CARDINALES_ENCLOSES_EXIGEES = 6


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


def station_reelle_du_point(profil, point):
    """Station à laquelle ce point appartient VRAIMENT, et sa dérive.

    ONZIÈME DÉFAUT, ET C'EST CELUI QUI FABRIQUAIT LE ROUGE DE PLANCHER.

    Décaler un point le long de la normale ne le laisse PAS à sa station
    quand l'axe est courbe : sur le côté convexe d'un coude, la projection
    du point glisse le long de l'axe. Mesuré par l'agent plancher sur la
    géométrie livrée :

        u nominal 7,00, f = -0,60  ->  u réel 4,95   (dérive -2,05)

    Le sol attendu était donc lu à la station 7 — palier 0,56 — pendant que
    le point se trouvait à la station 5 — palier 0,16. Le palier monte de
    0,34 à 0,70 sur les derniers 0,56 m de galerie : deux mètres de dérive
    valent 0,45 m d'écart de sol, et 0,45 m dépasse la tolérance de 0,25 m.

    Neuf lignes sur trente-trois rougissaient ainsi. Le plancher n'avait
    rien : la sonde comparait la hauteur d'un endroit à celle d'un autre.

    Quatre contrôles correctement échantillonnés concordent sur l'absence de
    défaut — `controle_plancher` du générateur (54 points), le contrôle 1 sur
    `points_interieurs` corrigé (468 points), les rasters `plancher`
    (10 197 cases) et `fond` (3 762 cases), et cette carte une fois corrigée
    (écart max 0,03 m).
    """
    u = profil.u_projete(point)
    return u


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


def largeur_reelle_mesuree(grille, profil, u, signe,
                           hauteurs=(0.35, 0.90, 1.50)):
    """Distance de l'axe à la paroi RÉELLE, du côté `signe`, par rayon.

    POURQUOI LA LARGEUR NOMINALE NE SUFFIT PAS À DÉFINIR UNE COUVERTURE.
    ===================================================================

    `CAVITE` × `CAVITE_ASYM` donne la largeur VOULUE. La coque livrée est
    modelée, décimée, et s'écarte de ce profil dans les deux sens. Deux
    conséquences opposées, toutes deux mesurées sur `f3afa0e` :

      * là où la coque RENTRE, un échantillon posé juste en deçà de la
        paroi nominale tombe dans la roche. Il ne couvre rien, et le
        compter couvrant serait annoncer une couverture qu'on n'a pas ;
      * là où elle BOMBE, une bande d'air réelle n'est jamais visitée —
        angle mort qu'aucune fraction du nominal ne peut fermer, puisque
        le nominal ne sait pas qu'elle existe.

    La couverture se mesure donc contre la paroi RÉELLE : c'est elle qui
    borne l'air qu'on prétend avoir inspecté. Le nominal reste publié à
    côté ; l'écart entre les deux est lui-même une information utile.

    Rend `(largeur_m, hauteur)` ou `(None, hauteur)` quand un rayon ne
    rencontre AUCUNE roche. Ce cas n'est pas une largeur infinie, c'est une
    percée latérale, et il est rendu distinct pour être nommé comme telle.
    """
    ax, ay, _, _, _ = profil.station(u)
    nx, ny = profil.normale(u)
    direction = (signe * nx, signe * ny, 0.0)
    meilleure, hauteur = None, None
    for h in hauteurs:
        depart = (ax, ay, profil.sol(u, 0.0) + h)
        vide, _ = dans_le_vide(grille, depart)
        if not vide:
            continue
        liste = impacts(grille, depart, direction, 60.0)
        if not liste:
            return (None, round(h, 3))
        if meilleure is None or liste[0][0] > meilleure:
            meilleure, hauteur = liste[0][0], round(h, 3)
    return (meilleure, hauteur)


def offsets_lateraux(profil, u, pas_lateral_m, marge_paroi_m=0.05,
                     largeurs=None):
    """Offsets latéraux SIGNÉS, en mètres, couvrant les DEUX côtés.

    `largeurs` est un couple `(gauche, droite)` de demi-largeurs MESURÉES.
    Quand il est fourni, la bande échantillonnée s'étend jusqu'à la paroi
    réelle et non jusqu'à la nominale — voir `largeur_reelle_mesuree`. Sans
    lui, on retombe sur le nominal, ce qui reste le comportement correct
    pour un profil synthétique dont la coque EST le nominal.

    POURQUOI UN PAS MÉTRIQUE, ET PAS DES FRACTIONS.
    ==============================================

    Des fractions de la demi-largeur donnent un espacement PROPORTIONNEL à
    la largeur du côté. Mesuré à la station 8 de la géométrie courante :
    paroi gauche 2,09 m, paroi droite 0,33 m. Avec `f = ±0,30` l'espacement
    vaut 0,63 m à gauche et 0,10 m à droite — six fois plus lâche du côté
    LARGE, c'est-à-dire du côté de l'alcôve, c'est-à-dire là où la revue
    veut la preuve. Une fraction ne peut donc pas porter une garantie
    d'espacement, et sans garantie d'espacement il n'y a pas de couverture.

    Un pas en MÈTRES donne le même espacement partout, des deux côtés, à
    toutes les stations. C'est la seule forme sous laquelle « 100 % couvert »
    veut dire quelque chose de vérifiable : tout point de la bande est à
    moins de `pas/2` d'un échantillon.

    La marge de paroi est petite et ASSUMÉE : la coque réelle est modelée et
    rentre par endroits en deçà du profil nominal, donc un échantillon posé
    exactement sur la paroi nominale peut tomber dans la roche. Il n'est pas
    perdu pour autant — `dans_le_vide` l'écarte, et le rapport de couverture
    compte séparément ce qui a été VISÉ et ce qui a été effectivement SONDÉ.
    Cacher cet écart serait annoncer une couverture qu'on n'a pas.
    """
    sortie = [0.0]
    for indice, signe in ((0, -1.0), (1, 1.0)):
        nominale = profil.demi_largeur(u, signe)
        mesuree = largeurs[indice] if largeurs else None
        # ON ÉCHANTILLONNE JUSQU'AU PLUS LOIN DES DEUX. Prendre le minimum
        # laisserait l'air situé au-delà du nominal hors de portée, et c'est
        # exactement le genre de bande où un défaut se cache — celle dont le
        # profil déclaré ignore l'existence.
        # LA PAROI MESUREE FAIT FOI QUAND ELLE EXISTE.
        #
        # `max(nominale, mesuree)` visait a ne pas manquer l'air situe
        # au-dela du nominal. Sur ce maillage il fait l'inverse du bien
        # voulu : aux stations 4 a 6 le facteur `gauche` vaut 1,68 a 1,69
        # pour un `hw` de 2,60 a 3,00, soit une demi-largeur NOMINALE de
        # 4,4 a 5,1 m — bien au-dela de la cavite reelle. Les echantillons
        # sortaient du massif, et 101 percees « confirmees » en sont nees.
        #
        # La couverture de l'air situe au-dela du nominal n'est pas perdue :
        # `tools/cave_frame.py` mesure l'intervalle creux reel et sonde
        # jusqu'a ses bornes. C'est son travail, pas celui-ci.
        demi = mesuree if mesuree is not None else nominale
        limite = demi - marge_paroi_m
        if limite <= 0.0:
            continue
        n = int(math.floor(limite / pas_lateral_m))
        for i in range(1, n + 1):
            sortie.append(signe * i * pas_lateral_m)
        # LE DERNIER ÉCHANTILLON VA JUSQU'À LA PAROI. Sans lui, la bande
        # comprise entre `n·pas` et la paroi n'est jamais visitée, et sa
        # largeur peut valoir jusqu'à un pas entier — soit exactement le
        # trou de couverture que ce pas métrique est censé fermer.
        if abs(limite - n * pas_lateral_m) > 1e-6:
            sortie.append(signe * limite)
    return sorted(sortie)


def points_interieurs(pas_long, fractions_lat, hauteurs, profil=None,
                      pas_lateral_m=None, marge_paroi_m=0.05, grille=None):
    """Points d'échantillonnage DANS le vide de la galerie.

    Les stations 0, 1, 7 et 8 sont incluses — c'est précisément ce que les
    contrôles du générateur sautent, et c'est là que la revue a vu le
    défaut.

    LES FRACTIONS SONT RELATIVES À LA PAROI DU CÔTÉ, PAS À `hw`.
    ===========================================================

    SIXIÈME ENDROIT DE LA MÊME FAUTE — ET IL N'ÉTAIT PAS LE DERNIER.

    Ce paragraphe a longtemps dit « SIXIÈME ET DERNIER ». C'était faux, et
    la fausseté a coûté une passe : `carte_du_plancher` portait exactement
    la même ligne, personne ne l'a cherchée puisqu'un commentaire affirmait
    que la chasse était close, et c'est elle qui a rendu le rouge de
    plancher des stations 6 à 8. Un commentaire qui proclame une
    exhaustivité qu'il n'a pas vérifiée est pire que pas de commentaire :
    il éteint la recherche.

    Le décompte tenu à jour vit désormais dans `FAMILLE_REPERE_LOCAL`, en
    tête de module, et il n'y a plus de « dernier ».

    Le placement s'écrivait
    `p = (ax + f·hw, ay, z)` : symétrique, et décalé le long de X. Cinq
    fonctions avaient déjà été corrigées (`dans_enveloppe`,
    `sort_par_la_bouche`, `_emprise_noyau`, `dans_le_noyau`,
    `cle_au_lateral`) ; celle-ci décide de l'ENDROIT D'OÙ TOUT PART, donc
    de ce que le contrôle 2 peut voir. Mesuré sur la géométrie A1 :

      * côté ÉTROIT, les échantillons DÉBORDENT. Aux stations 4 à 8 la
        paroi `droite` est à 0,33–1,07 m et `0,60·hw` tombe à 0,60·hw, au
        delà. 36 des 495 points étaient hors cavité. Ils ne fabriquent pas
        de fausse percée — `dans_le_vide` les rejette quand la roche est
        là — mais ils gaspillent l'échantillon ;
      * côté LARGE, et c'est le vrai dégât, la couverture s'arrête à
        **36 %** de la paroi aux stations 4 à 8 : l'alcôve porte à
        3,05–5,07 m, l'échantillonnage à 1,11–1,80 m. Près des deux tiers
        du côté large n'étaient JAMAIS visités.

    Un `0 percée` obtenu sur cette couverture ne serait pas une étanchéité,
    ce serait un angle mort — la faute de la passe une fois de plus, sous sa
    forme la plus coûteuse puisqu'elle clôturerait le gate.

    `f` vaut donc désormais une fraction de la demi-largeur RÉELLE du côté
    visé, et le point se place le long de la NORMALE de section. Sur un
    profil symétrique (`cavite_asym` plat), le placement est identique à
    l'ancien : la correction ne déplace rien là où il n'y avait rien à
    corriger.
    """
    profil = profil or PROFIL_GROTTE
    sortie = []
    u = 0.0
    while u <= len(profil.cavite) - 1 + 1e-9:
        ax, ay, hw, cle, palier = profil.station(u)
        nx, ny = profil.normale(u)
        if pas_lateral_m is not None:
            # Mode MÉTRIQUE : `f` n'est plus une fraction mais l'offset lui-
            # même. On le renormalise pour les champs qui attendent une
            # fraction (`sol`, `lateral`), afin que le reste de la sonde ne
            # change pas de contrat.
            #
            # LES PAROIS SONT MESURÉES quand une grille est fournie : c'est
            # ce qui empêche l'échantillonnage de sortir du massif là où le
            # profil déclaré est plus large que la roche.
            largeurs = None
            if grille is not None:
                largeurs = (largeur_reelle_mesuree(grille, profil, u, -1.0,
                                                   hauteurs)[0],
                            largeur_reelle_mesuree(grille, profil, u, 1.0,
                                                   hauteurs)[0])
            lateraux = offsets_lateraux(profil, u, pas_lateral_m,
                                        marge_paroi_m, largeurs)
        else:
            lateraux = None
        for f in (fractions_lat if lateraux is None else lateraux):
            # `demi_largeur` choisit le côté sur le SIGNE ; à f = 0 le point
            # est sur l'axe et le côté n'a aucune conséquence.
            if lateraux is None:
                demi = profil.demi_largeur(u, f)
                lateral_m = f * demi
            else:
                lateral_m = f
                demi = profil.demi_largeur(u, lateral_m)
                f = (lateral_m / demi) if demi else 0.0
            sol = profil.sol(u, f)
            # Le plafond suit le LINTEAU INCLINÉ : côté relevé il autorise
            # plus haut, côté abaissé moins. Un plafond symétrique
            # échantillonnait dans la roche d'un côté et s'arrêtait trop bas
            # de l'autre.
            toit_utile = palier + profil.cle_au_lateral(u, lateral_m) * 0.80
            for h in hauteurs:
                z = sol + h
                if z > toit_utile:
                    continue
                sortie.append(dict(u=u, station=int(round(u)), lateral=f,
                                   lateral_m=round(lateral_m, 4),
                                   hauteur=h,
                                   p=(ax + lateral_m * nx,
                                      ay + lateral_m * ny, z),
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

def sort_par_la_bouche(origine, direction, profil=None):
    """Le rayon quitte-t-il la cavité par l'OUVERTURE, et non par un trou ?

    SANS CE FILTRE LA SONDE MENT. Un premier jet signalait 61 « percées » à
    la station 0, azimuts 252 à 324° : ce sont les rayons qui sortent par la
    bouche, c'est-à-dire le fonctionnement normal d'une grotte. Un contrôle
    qui appelle « défaut » la porte d'entrée finit désactivé, et à raison.

    Critère : le rayon traverse le plan du porche (y = -1,15) vers l'avant,
    et son point de passage tombe dans la section de la station 0.

    L'ouverture est prise GÉNÉREUSEMENT en hauteur — clé majorée de 5 %.
    C'est un arbitrage explicite : un trou situé exactement sur le linteau
    serait absous. L'inverse — un faux positif à chaque rayon sortant —
    noierait les vraies percées sous soixante bruits.

    EN LARGEUR, ELLE NE L'EST PLUS. Elle l'a été, et c'était un trou dans le
    contrôle : la demi-largeur était majorée du facteur MAXIMAL (1,34) des
    DEUX côtés, alors que le porche vaut 1,34·hw à gauche et 0,79·hw à
    droite. Toute percée du flanc droit située entre 0,79·hw et 1,34·hw —
    c'est-à-dire dans 0,55·hw = 1,05 m de roche pleine — était classée
    « sort par la bouche » et disparaissait du verdict. La largeur est
    désormais lue PAR CÔTÉ, sur l'offset normal.
    """
    profil = profil or PROFIL_GROTTE
    ax, ay, hw, cle = profil.cavite[0]
    if direction[1] >= -1e-9:
        return False                      # ne va pas vers la bouche
    t = (ay - origine[1]) / direction[1]
    if t <= 0.0:
        return False                      # le porche est derrière le point
    px = origine[0] + direction[0] * t
    py = origine[1] + direction[1] * t
    pz = origine[2] + direction[2] * t
    lateral = profil.lateral((px, py, pz), 0.0)
    # DOUZIEME DEFAUT, ET C'EST UNE FIXTURE QUI L'A SORTI.
    #
    # Le sol de la bouche s'ecrivait `porche_denivele - sag`, sans le
    # PALIER de la station 0. Sur la Grotte du Couchant `PALIER[0]` vaut
    # 0,00, donc la faute etait exactement invisible — le nombre juste,
    # pour une raison fausse. Sur la premiere geometrie d'epreuve dont le
    # palier ne valait pas zero, la bouche s'est retrouvee 0,60 m trop
    # haut : tout rayon sortant par le BAS de l'ouverture cessait d'etre
    # excuse et devenait une percee. 1 513 rayons suspects sur un tunnel
    # sain.
    #
    # C'est l'argument entier des fixtures adversariales : un controle qui
    # n'a jamais menti sur la geometrie de production n'est pas pour autant
    # un controle juste.
    sol = profil.palier[0] + profil.porche_denivele - profil.sag
    # La voûte de la bouche est PENCHÉE : plafonner à `cle · 1,05` compte
    # comme percée du toit tout rayon sortant par le haut de l'ouverture du
    # côté relevé. Voir `Profil.cle_au_lateral`.
    plafond = profil.cle_au_lateral(0.0, lateral)
    return (abs(lateral) <= profil.demi_largeur(0.0, lateral)
            and sol - 0.10 <= pz <= plafond * 1.05)


def _entre_les_bouts(profil, point):
    """Le point est-il entre le plan de bouche et le plan de fond ?

    Les deux plans sont normaux a la TANGENTE de leur station, pas a un axe
    du monde : c'est la meme discipline que partout ailleurs dans ce
    fichier, et pour la meme raison — apres le coude, y ne dit plus ou l'on
    est le long de la galerie.
    """
    for u_bout, sens in ((0.0, -1.0),
                         (float(len(profil.cavite) - 1), 1.0)):
        ax, ay = profil.station(u_bout)[0], profil.station(u_bout)[1]
        nx, ny = profil.normale(u_bout)
        tx, ty = -ny, nx
        if ((point[0] - ax) * tx + (point[1] - ay) * ty) * sens > 0.0:
            return False
    return True


def dans_enveloppe(point, profil=None):
    """Le point est-il dans l'enveloppe NOMINALE de la cavité ?

    Enveloppe analytique, calculée depuis `CAVITE`/`PALIER`/`CAVITE_ASYM` —
    pas depuis le maillage. Elle sert à dire OÙ un rayon quitte la galerie,
    ce que le maillage ne peut pas dire quand justement il n'y a rien à cet
    endroit.

    La largeur est lue PAR CÔTÉ, sur l'offset NORMAL à l'axe. Les deux
    corrections sont indépendantes et toutes deux nécessaires :
    l'ancien `abs(point[0] - ax) <= hw · 1.34` se trompait de côté ET de
    direction de mesure (voir `Profil.normale`).
    """
    profil = profil or PROFIL_GROTTE
    # PROJECTION, pas inversion par y : voir `Profil.u_projete`. Un point
    # decale lateralement apres le coude change de y, et l'inversion le
    # rapportait a la mauvaise station — ou le rejetait tout net.
    #
    # MAIS LA PROJECTION BORNE, LA OU L'INVERSION REJETAIT — et c'est une
    # regression que l'epreuve `fond_perce` du selftest a attrapee en une
    # execution. `u_pour_y` rendait None au-dela des extremites ; `u_projete`
    # rend la station la plus proche, donc un point situe DERRIERE le fond
    # etait rapporte a la derniere station et pouvait passer pour « encore
    # dans la galerie ». `sortie_de_cavite` marchait alors trop loin et
    # localisait le trou a 1,36 m de son centre au lieu de 0,77 m.
    #
    # Les bornes sont donc explicites, et prises le long de la TANGENTE —
    # pas le long de y, qui est precisement l'axe monde dont on se defait.
    if not _entre_les_bouts(profil, point):
        return False
    u = profil.u_projete(point)
    _, _, _, cle, palier = profil.station(u)
    sol = palier - profil.sag
    if u < 1.0:
        sol += profil.porche_denivele * (1.0 - u)
    lateral = profil.lateral(point, u)
    return (abs(lateral) <= profil.demi_largeur(u, lateral)
            and sol - 0.30 <= point[2]
            <= palier + profil.cle_au_lateral(u, lateral) * 1.10)


def sortie_de_cavite(origine, direction, portee=40.0, pas=0.10, profil=None):
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
        if dans_enveloppe(p, profil):
            dernier = p
        elif dernier is not None:
            break
        t += pas
    return dernier


def controle_jour_profil(grille, echantillons, directions, profil):
    """`controle_jour`, mais sur un profil injecté.

    Existe pour que `tools/probe_cave_selftest.py` puisse soumettre à la
    MÊME fonction une géométrie dont il connaît la réponse. Un contrôle
    qu'on ne peut pas éprouver sur une réponse connue n'est pas un contrôle,
    c'est une opinion outillée.
    """
    return _controle_jour(grille, echantillons, directions, profil)


def controle_jour(grille, echantillons, directions):
    """Aucun rayon parti du vide de la galerie ne doit sortir par un trou.

    Critère : compte d'impacts PAIR et >= 2, SAUF si le rayon sort par la
    bouche. C'est le critère de `controle_aucun_jour`, appliqué aux
    directions qu'il ne tire pas — vers le bas, le long de l'axe, et aux
    stations 0, 1, 7, 8.
    """
    return _controle_jour(grille, echantillons, directions, PROFIL_GROTTE)


def _controle_jour(grille, echantillons, directions, profil):
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
        if ech["p"][1] < profil.cavite[1][1] - 1e-9:
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
        # UNE DIRECTION EST ACCEPTABLE SI ELLE RENCONTRE DE LA ROCHE **OU**
        # SI ELLE SORT PAR LA BOUCHE. Sans le second terme, tout point du
        # vestibule serait declare hors cavite, parce qu'une grotte a par
        # definition une ouverture. Avec le seul premier terme et un seuil
        # bas, un point du dehors passait. Il faut les deux.
        rencontres = sum(
            1 for d in directions
            if impacts(grille, ech["p"], d, 40.0)
            or sort_par_la_bouche(ech["p"], d, profil))
        part = rencontres / float(len(directions))
        cardinales = sum(
            1 for d in AXES
            if impacts(grille, ech["p"], d, 60.0)
            or sort_par_la_bouche(ech["p"], d, profil))
        if part < ENCLOSURE_MIN or cardinales < CARDINALES_ENCLOSES_EXIGEES:
            hors_cavite.append(dict(station=ech["station"],
                                    x=round(ech["p"][0], 2),
                                    y=round(ech["p"][1], 2),
                                    z=round(ech["p"][2], 2),
                                    part_enclose=round(part, 3),
                                    cardinales_encloses=cardinales))
            continue
        for direction in directions:
            if sort_par_la_bouche(ech["p"], direction, profil):
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
            sortie = sortie_de_cavite(ech["p"], direction, profil=profil) \
                or ech["p"]
            fautes.append(dict(station=ech["station"], u=round(ech["u"], 2),
                               x=round(ech["p"][0], 2), y=round(ech["p"][1], 2),
                               z=round(ech["p"][2], 2),
                               azimut=round(azimut, 1),
                               elevation=round(elevation, 1),
                               impacts=len(liste),
                               sortie=[round(c, 2) for c in sortie]))
    return testes, bouche, ecartes, hors_cavite, fautes


def carte_du_plancher(grille, pas_long, fractions, profil=None,
                      pas_lateral_m=None, marge_paroi_m=0.05,
                      grille_parois=None):
    """Où le plancher existe-t-il, et où manque-t-il ?

    Le contrôle 1 rend une liste de fautes ; celle-ci rend la CARTE, parce
    qu'une consigne de correction se formule en intervalle (« absent de tel
    y à tel y »), pas en nuage de points. Pour chaque abscisse le long de
    l'axe, on compte les positions latérales qui ont un sol à la hauteur
    attendue.

    SEPTIÈME ENDROIT DE LA MÊME FAUTE — ET LE PLUS COÛTEUX DES SEPT.
    ===============================================================

    Le départ s'écrivait `(ax + f·hw, ay, sol + 0,90)` : décalé le long de
    X, contre une demi-largeur SYMÉTRIQUE, et le sol lu par `sol_attendu()`
    — la fonction de module, celle qui ignore `CAVITE_ASYM`. Les six autres
    sites avaient été corrigés ; celui-ci ne l'avait pas été, et il ne
    figurait sur aucune liste parce qu'il n'avait jamais rougi à tort.

    Or c'est lui qui PORTE LE VERDICT. Le rouge « plancher absent de
    y = +2,88 à y = +3,09 » vient de cette carte, et de nulle part ailleurs.
    Mesuré sur `f3afa0e` : aux stations 6 à 8, sur les cinq fractions
    demandées, **une seule** tombait dans le vide — les quatre autres
    atterrissaient dans la roche et étaient silencieusement sautées par
    `dans_le_vide`. Le journal imprimait « 0/1 » et je lisais « trou » ; la
    vérité est qu'un seul point était interrogé sur cinq, à un endroit
    choisi par une formule fausse.

    Un rouge tiré d'un échantillon sur cinq mal placé n'est pas une mesure
    de plancher : c'est un tirage au sort. Le défaut de plancher aux
    stations terminales est peut-être réel — la passe est là pour ça — mais
    il devra être établi par un instrument qui vise la galerie.
    """
    profil = profil or PROFIL_GROTTE
    lignes = []
    u = 0.0
    while u <= len(profil.cavite) - 1 + 1e-9:
        ax, ay, hw, cle, palier = profil.station(u)
        nx, ny = profil.normale(u)
        if pas_lateral_m is not None:
            largeurs = None
            if grille_parois is not None:
                largeurs = (largeur_reelle_mesuree(grille_parois, profil, u,
                                                   -1.0)[0],
                            largeur_reelle_mesuree(grille_parois, profil, u,
                                                   1.0)[0])
            lateraux = offsets_lateraux(profil, u, pas_lateral_m,
                                        marge_paroi_m, largeurs)
        else:
            lateraux = [f * profil.demi_largeur(u, f) for f in fractions]
        presents, absents = 0, 0
        pires = []
        zs = []
        vises = len(lateraux)
        hors_vide = 0
        derives = []
        for lateral_m in lateraux:
            demi = profil.demi_largeur(u, lateral_m)
            fraction = (lateral_m / demi) if demi else 0.0
            # LE SOL ATTENDU SE LIT A LA STATION REELLE DU POINT, pas a la
            # station nominale. Voir `station_reelle_du_point` : sur le cote
            # convexe d'un coude, un offset lateral fait glisser la
            # projection de plus de deux stations, et comparer alors la
            # hauteur mesuree au palier de la station nominale fabrique
            # jusqu'a 0,45 m d'ecart la ou la roche est saine.
            provisoire = (ax + lateral_m * nx, ay + lateral_m * ny, 0.0)
            u_reel = station_reelle_du_point(profil, provisoire)
            derives.append(abs(u_reel - u))
            sol = profil.sol(u_reel, fraction)
            depart = (ax + lateral_m * nx, ay + lateral_m * ny, sol + 0.90)
            vide, _ = dans_le_vide(grille, depart)
            if not vide:
                hors_vide += 1
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
                           # CE QUI A ÉTÉ VISÉ, ET CE QUI A ÉTÉ SONDÉ. Sans
                           # ces deux nombres, « 0/1 » se lit comme un trou
                           # alors qu'il dit surtout qu'on n'a interrogé
                           # qu'un point. Un dénominateur muet est un
                           # mensonge par omission.
                           vises=vises, hors_vide=hors_vide,
                           derive_station_max=round(max(derives), 3)
                           if derives else 0.0,
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
    """Monde Godot -> repère modèle Blender. FORME FERMÉE, écrite à la main.

    L'ouvrage est posé sans échelle, avec un seul lacet autour de Y
    (`waterfall_cave_place.gd` : `ouvrage.rotation.y = deg_to_rad(45)`), et
    le lieu lui-même n'a AUCUNE rotation (`world_v2_places_builder.gd` :
    `place.position = Vector3(...)` et rien d'autre). La transformation est
    donc une translation suivie d'une rotation, et son inverse s'écrit sans
    matrice.

    CETTE FONCTION EST L'UN DES DEUX CHEMINS DE `Pose`. L'autre est la
    chaîne de matrices de `Pose.vers_monde()`, écrite indépendamment. Le
    contrôle d'aller-retour compare les deux ; si l'un des deux se trompe de
    signe ou d'axe, il rougit. Ne PAS réécrire l'un en appelant l'autre :
    l'aller-retour deviendrait un test qui ne peut pas échouer
    (`docs/PROMPT4_METHOD.md` §2).
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


# ---------------------------------------------------------------------------
# LA POSE — ce qui était `NON VÉRIFIÉ`, et pourquoi il l'était.
#
# L'origine monde de l'ouvrage était passée en OPTION (`--origine-monde
# -106.0,3.50,3.5`). Une valeur en ligne de commande n'est pas une mesure :
# elle est vraie tant que personne ne déplace le lieu, et fausse en silence
# le jour où quelqu'un le fait. La tentative de la valider en superposant
# une silhouette calculée à la capture a échoué — 52,4 % de concordance sur
# `t3_07`, et décaler l'origine de +3 m AMÉLIORAIT le score, ce qui
# disqualifie la mesure elle-même.
#
# La réparation n'est pas de mieux superposer. Elle est de ne plus deviner :
# la pose se DÉRIVE des mêmes fichiers que le jeu lit, et trois contrôles
# indépendants l'éprouvent.
#
#   1. DÉRIVATION      — `Pose.depuis_les_sources()` lit `v2_site` dans
#                        `world_v2_layout.json` et `SEUIL_LOCAL`,
#                        `LACET_DEG`, `EXHAUSSEMENT` dans
#                        `waterfall_cave_place.gd`. Aucun nombre n'est
#                        recopié ici. Un fichier qui change fait bouger la
#                        pose, ou fait sortir la sonde en 3 (BLOQUÉ).
#   2. ALLER-RETOUR    — deux implémentations indépendantes (chaîne de
#                        matrices contre forme fermée) doivent se rendre le
#                        même point à `TOLERANCE_ALLER_RETOUR_M` près.
#   3. CAS SYNTHÉTIQUE — `tools/probe_cave_selftest.py` fabrique une
#                        géométrie dont la pose est CONNUE, la regarde par
#                        une caméra monde, et exige que le trou apparaisse
#                        dans la boîte de pixels prédite. C'est ce qu'aucune
#                        superposition d'image ne pouvait établir.
#
# LE Y DU LIEU N'INTERVIENT PAS, et c'est une simplification réelle, pas une
# approximation. Le bâtisseur pose le lieu à `y = height_at(site)`, puis
# `ground_local_y()` retranche exactement ce même `global_position.y` :
#
#     assise      = height_at(seuil_monde) - height_at(site) + EXHAUSSEMENT
#     y_ouvrage   = height_at(site) + assise
#                 = height_at(seuil_monde) + EXHAUSSEMENT
#
# L'altitude du site s'annule. Il ne reste qu'UNE inconnue documentaire :
# la hauteur du terrain gelé SOUS LE SEUIL. Elle est déclarée séparément,
# son statut est dit, et `Pose.sensibilite_y` mesure ce qu'elle change.
# ---------------------------------------------------------------------------

## Tolérance de l'aller-retour monde -> modèle -> monde.
##
## POURQUOI CETTE VALEUR, ET PAS UNE AUTRE. Elle n'est pas un budget
## d'erreur géométrique : c'est un PLANCHER DE BRUIT NUMÉRIQUE.
##
##   * au-dessus du bruit : les coordonnées valent ~120 m, l'epsilon des
##     flottants 64 bits y vaut 1,4e-14 m, et la chaîne fait une dizaine
##     d'opérations. 1e-9 m est donc ~5 ordres de grandeur au-dessus du
##     bruit — l'aller-retour ne peut pas rougir pour une raison de
##     virgule flottante ;
##   * très en dessous de toute erreur réelle : un signe de lacet inversé
##     déplace un point de plusieurs mètres, un axe échangé aussi. Toute
##     faute de transformation vaut donc au moins 1e8 fois la tolérance.
##
## Autrement dit : entre « ça marche » et « c'est faux » il y a huit ordres
## de grandeur de marge, et le seuil est posé au milieu. Ce n'est pas un
## réglage à ajuster si un jour le test rougit — s'il rougit, la
## transformation est fausse.
TOLERANCE_ALLER_RETOUR_M = 1e-9

## Hauteur du terrain gelé sous le seuil, en monde. DOCUMENTAIRE, et dit
## comme tel : reprise des commentaires d'implantation de
## `waterfall_cave_place.gd` (« plateau plat à y = 3,00 sur x ∈ [-118 ;
## -102], z ∈ [0 ; +9] »), jamais relue par sonde. `Pose.sensibilite_y()`
## mesure ce qu'une erreur de ±1 m y changerait.
TERRAIN_SOUS_SEUIL_M = 3.00


def _mat_identite():
    return [[1.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0],
            [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0]]


def _mat_produit(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)]
            for i in range(4)]


def _mat_applique(m, p):
    return tuple(m[i][0] * p[0] + m[i][1] * p[1] + m[i][2] * p[2] + m[i][3]
                 for i in range(3))


def _mat_applique_direction(m, d):
    return tuple(m[i][0] * d[0] + m[i][1] * d[1] + m[i][2] * d[2]
                 for i in range(3))


class Pose(object):
    """Pose monde de l'ouvrage, DÉRIVÉE des sources que le jeu lit.

    `origine` est la position monde de l'origine du modèle ; `lacet_deg` le
    lacet autour de Y. `provenance` dit d'où vient chaque nombre, pour que
    le rapport n'ait pas à faire confiance à la sonde sur parole.
    """

    def __init__(self, origine, lacet_deg, provenance):
        self.origine = tuple(float(v) for v in origine)
        self.lacet_deg = float(lacet_deg)
        self.provenance = dict(provenance)
        self._chaine = self._construire_chaine()

    # -- CHEMIN A : chaîne de matrices, écrite comme Godot compose ---------
    def _construire_chaine(self):
        """`T(origine) · Ry(lacet) · S(axes)`, dans cet ordre.

        Chaque facteur est une matrice élémentaire écrite séparément, et le
        produit est fait par `_mat_produit`. Aucune formule fermée ici : ce
        chemin doit pouvoir contredire l'autre.

        `S(axes)` est le changement de repère MODÈLE BLENDER -> LOCAL GODOT.
        Il vaut `(x, y, z)_bl -> (x, z, -y)_gd`, ce que
        `tests/unit/test_grotte_sans_jour.gd::_vers_godot` applique déjà et
        que l'exportateur glTF réalise à l'écriture du fichier.
        """
        axes = _mat_identite()
        axes[0] = [1.0, 0.0, 0.0, 0.0]      # x_gd =  x_bl
        axes[1] = [0.0, 0.0, 1.0, 0.0]      # y_gd =  z_bl
        axes[2] = [0.0, -1.0, 0.0, 0.0]     # z_gd = -y_bl

        a = math.radians(self.lacet_deg)
        rot = _mat_identite()
        rot[0] = [math.cos(a), 0.0, math.sin(a), 0.0]
        rot[2] = [-math.sin(a), 0.0, math.cos(a), 0.0]

        trans = _mat_identite()
        for i in range(3):
            trans[i][3] = self.origine[i]

        return _mat_produit(trans, _mat_produit(rot, axes))

    def vers_monde(self, point_modele):
        return _mat_applique(self._chaine, point_modele)

    def direction_vers_monde(self, direction_modele):
        return _mat_applique_direction(self._chaine, direction_modele)

    # -- CHEMIN B : forme fermée, déjà écrite plus haut --------------------
    def vers_modele(self, point_monde):
        return monde_vers_modele(point_monde, self.origine, self.lacet_deg)

    def direction_vers_modele(self, direction_monde):
        return direction_monde_vers_modele(direction_monde, self.lacet_deg)

    # -- CONTRÔLE : les deux chemins se rendent-ils le même point ? --------
    def controle_aller_retour(self, points_modele=None):
        """Modèle -> monde (matrices) -> modèle (forme fermée) -> monde.

        Rend (ecart_max_m, details). Les points d'épreuve couvrent les huit
        coins d'une boîte de 20 m ET des points hors axe : un aller-retour
        éprouvé seulement sur l'origine passerait quelle que soit la
        rotation — c'est l'exemple canonique d'une assertion qui n'éprouve
        qu'un seul bras (`PROMPT4_METHOD` §2).
        """
        if points_modele is None:
            points_modele = []
            for sx in (-10.0, 10.0):
                for sy in (-10.0, 10.0):
                    for sz in (-10.0, 10.0):
                        points_modele.append((sx, sy, sz))
            points_modele += [(0.0, 0.0, 0.0), (1.05, 6.25, 0.22),
                              (0.0, -1.15, 0.0), (2.85, 9.25, 0.92),
                              (-3.7, 4.1, -0.6), (0.31, 7.77, 2.13)]
        pire = 0.0
        details = []
        for p in points_modele:
            monde = self.vers_monde(p)
            retour = self.vers_modele(monde)
            ecart = max(abs(retour[k] - p[k]) for k in range(3))
            pire = max(pire, ecart)
            if ecart > TOLERANCE_ALLER_RETOUR_M:
                details.append(dict(modele=[round(c, 4) for c in p],
                                    monde=[round(c, 4) for c in monde],
                                    retour=[round(c, 6) for c in retour],
                                    ecart_m=ecart))
        # Les DIRECTIONS aussi : un lacet correct sur les points mais
        # inversé sur les directions ferait viser à côté sans que
        # l'aller-retour des points s'en aperçoive.
        for d in ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0),
                  (0.577, 0.577, 0.577), (-0.6, 0.8, 0.0)):
            monde = self.direction_vers_monde(d)
            retour = self.direction_vers_modele(monde)
            ecart = max(abs(retour[k] - d[k]) for k in range(3))
            pire = max(pire, ecart)
            if ecart > TOLERANCE_ALLER_RETOUR_M:
                details.append(dict(direction=[round(c, 4) for c in d],
                                    retour=[round(c, 6) for c in retour],
                                    ecart_m=ecart))
        return pire, details

    def decalee(self, dx, dy, dz):
        """Même pose, origine déplacée. Sert aux balayages de sensibilité."""
        return Pose((self.origine[0] + dx, self.origine[1] + dy,
                     self.origine[2] + dz), self.lacet_deg,
                    dict(self.provenance, decalage=[dx, dy, dz]))

    # -- DÉRIVATION depuis les fichiers du jeu -----------------------------
    @staticmethod
    def depuis_les_sources(place_gd, layout_json, poi_id,
                           terrain_sous_seuil=TERRAIN_SOUS_SEUIL_M):
        """Lit `v2_site`, `SEUIL_LOCAL`, `LACET_DEG`, `EXHAUSSEMENT`.

        Lecture TEXTUELLE du GDScript, comme `controle_coherence_cotes` le
        fait déjà du générateur : la sonde reste en Python pur. Toute valeur
        introuvable est un BLOCAGE, jamais un défaut par défaut — une pose
        devinée est précisément ce que cette classe existe pour supprimer.
        """
        if not os.path.isfile(layout_json):
            raise Blocage("layout introuvable : %s" % layout_json)
        if not os.path.isfile(place_gd):
            raise Blocage("script de lieu introuvable : %s" % place_gd)
        layout = json.load(open(layout_json, "r", encoding="utf-8"))
        site = None
        for poi in layout.get("pois", []):
            if poi.get("id") == poi_id:
                site = poi.get("v2_site")
                break
        if site is None or len(site) != 3:
            raise Blocage("v2_site absent du layout pour %s" % poi_id)

        texte = open(place_gd, "r", encoding="utf-8").read()

        def _const(nom, motif):
            marque = "\nconst %s" % nom
            if marque not in texte:
                raise Blocage("constante %s absente de %s" % (nom, place_gd))
            ligne = texte.split(marque, 1)[1].split("\n", 1)[0]
            if motif not in ligne:
                raise Blocage("constante %s : forme inattendue (%s)"
                              % (nom, ligne.strip()))
            return ligne.split(motif, 1)[1]

        brut = _const("SEUIL_LOCAL", "Vector2(").split(")", 1)[0]
        seuil = [float(v) for v in brut.split(",")]
        lacet = float(_const("LACET_DEG", "=").split("#")[0].strip())
        exhaussement = float(_const("EXHAUSSEMENT", "=").split("#")[0].strip())

        origine = (site[0] + seuil[0],
                   terrain_sous_seuil + exhaussement,
                   site[2] + seuil[1])
        return Pose(origine, lacet, dict(
            v2_site=[float(v) for v in site], seuil_local=seuil,
            lacet_deg=lacet, exhaussement=exhaussement,
            terrain_sous_seuil=terrain_sous_seuil,
            terrain_statut="NON VERIFIE — documentaire, cf. commentaires "
                           "d'implantation de waterfall_cave_place.gd",
            layout=layout_json, script=place_gd))


def carte_du_fond(grille, pas=0.25):
    """L'ouverture ARRIÈRE, cartographiée face au fond de la galerie.

    Le contrôle 2 dit qu'il y a des percées et d'où elles partent ; celle-ci
    dit la FORME et l'EMPRISE du trou, vues de derrière. Un rayon part de
    y = +14 (hors emprise, le maillage s'arrête à y = +10,64) vers -Y : s'il
    dépasse le fond de la galerie sans rien toucher, la case est ouverte.

    Le balayage est borné à l'emprise de la DERNIÈRE station, majorée : au
    delà on ne mesure plus la grotte mais l'air à côté du rocher, et compter
    cet air comme un trou serait un faux positif.

    HUITIÈME ENDROIT DE LA MÊME FAUTE. L'emprise s'écrivait
    `ax ± hw·1,34` : le facteur MAJORANT appliqué symétriquement, le long de
    X. À la station 8 la paroi gauche vaut 1,61·hw et la droite 0,25·hw. La
    fenêtre était donc simultanément TROP ÉTROITE à gauche — 1,34 au lieu de
    1,61, soit 0,35 m d'alcôve hors champ, précisément le coin où vit la
    récompense — et TROP LARGE à droite de 1,42 m, dans du massif où toute
    case ouverte aurait été de l'air à côté du rocher.

    L'emprise est désormais construite le long de la NORMALE, côté par côté,
    avec une marge additive plutôt qu'un facteur : une marge multiplicative
    d'un côté étroit ne fabrique presque rien, et du côté large elle
    fabrique des mètres.
    """
    profil = PROFIL_GROTTE
    u_fin = float(len(profil.cavite) - 1)
    ax, ay, hw, cle, palier_fin = profil.station(u_fin)
    nx, ny = profil.normale(u_fin)
    MARGE_FOND_M = 0.40
    bords = [ax + signe * (profil.demi_largeur(u_fin, signe) + MARGE_FOND_M)
             * nx for signe in (-1.0, 1.0)]
    x0, x1 = min(bords), max(bords)
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


def controle_ligne_de_vue(grille, prise, origine_monde, lacet_deg, pas_px,
                          profil=None):
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
                # AUCUN IMPACT — ET C'EST LE CAS QUI COMPTE LE PLUS.
                #
                # La version precedente s'arretait ici en disant « ne vise
                # pas la formation ». C'est vrai pour un pixel de ciel, et
                # radicalement faux pour un pixel qui traverse un trou
                # FRANC : un rayon qui passe par une percee nette ne
                # rencontre justement AUCUN triangle. Le controle rangeait
                # donc le defaut le plus grave dans la case « hors sujet ».
                #
                # Mesure de l'ecart : sur le tunnel synthetique perce au
                # fond, l'ancien critere ne retenait que 10 pixels — le
                # liseré rasant du bord du trou — la ou le trou en occupe
                # une quarantaine de cote. Il voyait le contour, pas le
                # trou.
                #
                # Le rayon est donc percant s'il TRAVERSE le noyau de la
                # cavite sans rien rencontrer : le pixel montre alors ce
                # qu'il y a derriere la grotte.
                if profil is not None and _entree_noyau(
                        profil, origine_modele, direction, 400.0) is not None:
                    traversants += 1
                    percees.append(dict(px=px, py=py, impacts=0,
                                        genre="traversee_franche"))
                continue
            traversants += 1
            if any(orientation < 0.0 for _, orientation in liste):
                continue          # de la roche est affichée : rien à dire
            sortie = [origine_modele[k] + direction[k] * liste[-1][0]
                      for k in range(3)]
            percees.append(dict(px=px, py=py, impacts=len(liste),
                                genre="aucune_face_avant",
                                sortie=[round(c, 2) for c in sortie]))
    return traversants, percees


def _rayon_pixel(prise, pose, px, py):
    """Direction MODÈLE du rayon passant par le pixel (px, py).

    Extrait de `controle_ligne_de_vue` pour être réutilisable — la
    confirmation d'ouverture doit tirer exactement le même rayon que le
    contrôle, sans quoi elle mesurerait autre chose.
    """
    camera, cible, fov = prise["from"], prise["look"], prise["fov"]
    largeur, hauteur = prise["taille"]
    avant = _normaliser((cible[0] - camera[0], cible[1] - camera[1],
                         cible[2] - camera[2]))
    axe_z = (-avant[0], -avant[1], -avant[2])
    axe_x = _normaliser(_croix((0.0, 1.0, 0.0), axe_z))
    axe_y = _croix(axe_z, axe_x)
    demi_v = math.tan(math.radians(fov) * 0.5)
    demi_h = demi_v * largeur / float(hauteur)
    ndc_x = (px + 0.5) / largeur * 2.0 - 1.0
    ndc_y = 1.0 - (py + 0.5) / hauteur * 2.0
    monde = tuple(avant[k] + ndc_x * demi_h * axe_x[k]
                  + ndc_y * demi_v * axe_y[k] for k in range(3))
    return _normaliser(pose.direction_vers_modele(_normaliser(monde)))


def _penetration(grille, profil, pose, prise):
    """Longueur de vide parcourue DANS la galerie par le rayon central.

    Rend None si le rayon ne touche pas la formation. La mesure : on suit le
    rayon central de la caméra en repère modèle et on additionne les
    segments passés dans le noyau de la cavité, en s'arrêtant au premier
    triangle rencontré. Une pose juste donne plusieurs mètres ; une pose
    fausse de deux mètres heurte la coque avant d'entrer, ou manque le
    rocher — et rend zéro.
    """
    camera = pose.vers_modele(prise["from"])
    direction = _rayon_pixel(prise, pose, prise["taille"][0] / 2.0 - 0.5,
                             prise["taille"][1] / 2.0 - 0.5)
    liste = impacts(grille, camera, direction, 200.0)
    if not liste:
        return None
    limite = liste[0][0]
    parcouru, t, pas = 0.0, 0.0, 0.05
    while t < limite:
        p = tuple(camera[k] + direction[k] * t for k in range(3))
        if dans_le_noyau(profil, p):
            parcouru += pas
        t += pas
    return parcouru


def _dire_penetration(valeur):
    if valeur is None:
        return "le rayon central ne touche pas la formation"
    return "%.2f m de vide de galerie avant le premier triangle" % valeur


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
# LE PROFIL — les cotes de la cavité, rendues REMPLAÇABLES.
#
# Les contrôles 1 et 2 lisent les constantes de module `CAVITE`/`PALIER`.
# C'est correct pour la Grotte du Couchant et inutilisable pour prouver quoi
# que ce soit : on ne peut pas fabriquer une géométrie d'épreuve dont on
# connaît la réponse si le profil est câblé. Le `Profil` rend les mêmes
# cotes injectables — la grotte réelle en est une instance, le cas
# synthétique en est une autre.
# ---------------------------------------------------------------------------

class Profil(object):                                    # noqa: E302
    """Profil analytique d'une cavité : stations, sol, clé, noyau.

    `asym` est le facteur MAJORANT, conservé pour les profils synthétiques
    droits (`asym=1.0`) et pour les bornes grossières. `cavite_asym` est la
    table PAR STATION `(gauche, droite, inclinaison)` : c'est elle qui fait
    foi dès qu'elle est fournie. Quand elle est absente, on fabrique une
    table plate à partir du scalaire, de sorte qu'un profil droit se
    comporte exactement comme avant.

    LE CÔTÉ N'EST PAS UNE OPINION. Le générateur décide `gauche` / `droite`
    sur le signe de l'offset NORMAL à l'axe. Toute mesure qui parle de
    « côté » dans cette sonde passe par `lateral()`, jamais par x.
    """

    def __init__(self, cavite, palier, sag, porche_denivele, asym=1.34,
                 nom="grotte", cavite_asym=None):
        self.cavite = [tuple(s) for s in cavite]
        self.palier = tuple(palier)
        self.sag = float(sag)
        self.porche_denivele = float(porche_denivele)
        self.asym = float(asym)
        self.nom = nom
        if cavite_asym is None:
            self.cavite_asym = [(self.asym, self.asym, 0.0)] * len(self.cavite)
        else:
            self.cavite_asym = [tuple(a) for a in cavite_asym]
        if len(self.cavite_asym) != len(self.cavite):
            raise ValueError("cavite_asym : %d entrees pour %d stations"
                             % (len(self.cavite_asym), len(self.cavite)))

    # -- géométrie de section -------------------------------------------

    def asym_station(self, u):
        """`(gauche, droite, inclinaison)` interpolés à la station `u`.

        Même interpolation linéaire que le générateur (`dos_alcove`).
        """
        i = max(0, min(len(self.cavite_asym) - 1, int(math.floor(u))))
        j = min(len(self.cavite_asym) - 1, i + 1)
        t = max(0.0, min(1.0, u - i))
        a, b = self.cavite_asym[i], self.cavite_asym[j]
        return tuple(a[k] * (1.0 - t) + b[k] * t for k in range(3))

    def normale(self, u):
        """Axe LATÉRAL de la section en `u`, dans le plan (x, y).

        RECOPIÉ DE `normale_de_cavite()` DU GÉNÉRATEUR, dont le commentaire
        dit ce que ce détail a coûté : « Décaler le long de X au lieu de la
        normale paraît anodin tant que la galerie court droit — et devient
        faux dès qu'elle s'infléchit. MESURÉ, ET C'EST CE QUI M'A COÛTÉ DEUX
        PASSES. » Entre les stations 7 et 8 la normale est à 45° de X.

        La sonde commettait EXACTEMENT cette erreur : `dans_enveloppe()` et
        `sort_par_la_bouche()` comparaient `abs(point[0] - ax)`, une distance
        alignée sur X, à une demi-largeur mesurée le long de la normale.
        """
        eps = 0.02
        umax = float(len(self.cavite) - 1)
        a = self.station(max(0.0, u - eps))
        b = self.station(min(umax, u + eps))
        tx, ty = b[0] - a[0], b[1] - a[1]
        n = math.hypot(tx, ty)
        if n < 1e-9:
            return (1.0, 0.0)
        return (ty / n, -tx / n)

    def lateral(self, point, u):
        """Offset SIGNÉ du point le long de la normale de section.

        Négatif = côté `gauche` du générateur, positif = côté `droite`.
        C'est la seule définition de « côté » employée par cette sonde.
        """
        ax, ay = self.station(u)[0], self.station(u)[1]
        nx, ny = self.normale(u)
        return (point[0] - ax) * nx + (point[1] - ay) * ny

    def demi_largeur(self, u, lateral):
        """Demi-largeur admise à la station `u`, DU CÔTÉ de `lateral`."""
        hw = self.station(u)[2]
        gauche, droite, _ = self.asym_station(u)
        return hw * (gauche if lateral < 0.0 else droite)

    def cle_au_lateral(self, u, lateral):
        """Hauteur de voûte à l'offset latéral `lateral` — LINTEAU INCLINÉ.

        TROISIÈME DIMENSION DE LA MÊME FAUTE. L'asymétrie de `CAVITE_ASYM`
        ne joue pas que sur la largeur : sa troisième composante incline la
        clé. Le générateur écrit `biais = 1 + inclinaison·cos(theta)` et
        `z = cle · v^0,75 · w · biais` (`anneau_interieur`), donc la voûte
        monte d'un côté et descend de l'autre.

        MESURÉ sur la bouche de la géométrie A1 : `cle` nominale 2,80 m,
        `inclinaison` -0,44 — la voûte réelle atteint **4,03 m** au bord
        gauche et **1,57 m** au bord droit. `sort_par_la_bouche()` plafonnait
        à `cle·1,05 = 2,94 m` : tout rayon quittant la grotte par le HAUT de
        l'ouverture, entre 2,94 et 4,03 m, était compté comme une percée du
        TOIT. Seize sur les cinquante et une percées de toit de A1 étaient
        exactement cela — la porte d'entrée, prise pour un trou.
        """
        cle = self.station(u)[3]
        _, _, inclinaison = self.asym_station(u)
        demi = self.demi_largeur(u, lateral)
        ucos = max(-1.0, min(1.0, (lateral / demi) if demi else 0.0))
        return cle * (1.0 + inclinaison * ucos)

    @staticmethod
    def nom_du_cote(lateral):
        return "gauche" if lateral < 0.0 else "droite"

    def station(self, u):
        i = min(int(math.floor(u)), len(self.cavite) - 2)
        i = max(i, 0)
        f = u - i
        a, b = self.cavite[i], self.cavite[i + 1]
        pa, pb = self.palier[i], self.palier[i + 1]
        return (a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f,
                a[2] + (b[2] - a[2]) * f, a[3] + (b[3] - a[3]) * f,
                pa + (pb - pa) * f)

    def u_projete(self, point, pas=0.02):
        """Station continue dont l'axe est le PLUS PROCHE du point.

        DIXIÈME ENDROIT DE LA MÊME FAMILLE DE FAUTE, et il touche la
        localisation plutôt que le placement.

        `u_pour_y()` inverse l'axe par la seule coordonnée `y`. C'est exact
        tant que la galerie court le long de y — c'est-à-dire jusqu'au
        coude — et faux ensuite, parce que la NORMALE acquiert une
        composante en y. À la station 8 elle vaut `(0,521 ; -0,853)` : un
        offset latéral de 2 m y déplace le point de +1,71 m EN Y. Le point
        est alors rapporté à une station qui n'est pas la sienne, ou —
        quand y dépasse celui de la dernière station — déclaré HORS CAVITÉ.

        Mesuré sur `f3afa0e` : à la station 8, l'intégralité des offsets de
        l'alcôve, pourtant dans le vide, était rejetée par `dans_enveloppe`
        via ce chemin. Un point réel de la galerie classé hors galerie.

        La projection sur la polyligne d'axe n'a pas ce défaut : elle ne
        suppose rien de l'orientation. Elle coûte un balayage, ce qui est
        sans conséquence ici et vaut mieux qu'une inversion valable sur la
        moitié de l'ouvrage.
        """
        meilleur_u, meilleure_d = 0.0, None
        u = 0.0
        umax = float(len(self.cavite) - 1)
        while u <= umax + 1e-9:
            ax, ay = self.station(u)[0], self.station(u)[1]
            d = (point[0] - ax) ** 2 + (point[1] - ay) ** 2
            if meilleure_d is None or d < meilleure_d:
                meilleur_u, meilleure_d = u, d
            u += pas
        return meilleur_u

    def u_pour_y(self, y):
        """Station continue à l'abscisse `y`, ou None hors emprise.

        VALABLE SEULEMENT SUR UN POINT DE L'AXE. L'axe est monotone en y,
        donc l'inversion est exacte pour lui — et pour lui seul. Pour un
        point décalé latéralement, employer `u_projete` : voir le récit qui
        y est attaché.
        """
        if y < self.cavite[0][1] or y > self.cavite[-1][1]:
            return None
        for i in range(len(self.cavite) - 1):
            y0, y1 = self.cavite[i][1], self.cavite[i + 1][1]
            if y0 <= y <= y1:
                return i + ((y - y0) / (y1 - y0) if y1 > y0 else 0.0)
        return float(len(self.cavite) - 1)

    def sol(self, u, lateral):
        _, _, _, _, palier = self.station(u)
        denivele = self.porche_denivele * max(0.0, 1.0 - u) if u < 1.0 else 0.0
        creux = -self.sag * (1.0 - min(1.0, abs(lateral)))
        return palier + creux + denivele

    def toit(self, u):
        _, _, _, cle, palier = self.station(u)
        return palier + cle


## La Grotte du Couchant. `asym` conserve le facteur MAJORANT (1,34) pour
## les bornes grossières ; `cavite_asym` porte la vérité par station et par
## côté, et c'est elle qui décide des limites latérales.
PROFIL_GROTTE = Profil(CAVITE, PALIER, SAG, PORCHE_DENIVELE, 1.34, "grotte",
                       cavite_asym=CAVITE_ASYM)


## LE NOYAU — le volume où il DOIT y avoir de l'air, et rien d'autre.
##
## Les rasters de surface tirent depuis l'extérieur vers la cavité, et
## déclarent une case ouverte quand le rayon atteint le vide sans rencontrer
## de roche. « Le vide » ne peut pas être l'enveloppe NOMINALE : la coque
## réelle est modelée, elle rentre par endroits en deçà du profil théorique,
## et un rayon qui l'atteindrait serait compté ouvert à tort. On vise donc
## un noyau franchement intérieur — 55 % de la demi-largeur, 55 % de la clé,
## 0,15 m au-dessus du sol.
##
## Le biais est ASSUMÉ ET DIRECTIONNEL : un noyau réduit fait manquer des
## trous marginaux, il n'en fabrique jamais. Un raster de surface ne peut
## donc pas crier au loup ; il peut rester silencieux sur un trou qui
## n'ouvre que sur la marge. C'est pour cela que le raster ne décide de
## rien seul — il propose des candidats que la mesure d'ouverture confirme,
## et que le contrôle 2 (rayons partant de l'intérieur) double.
NOYAU_LARGEUR = 0.55
NOYAU_HAUTEUR = 0.55
NOYAU_MARGE_SOL = 0.15


def dans_le_noyau(profil, point):
    """Le point est-il dans le volume qui DOIT être de l'air ?

    CORRIGÉ POUR L'ASYMÉTRIE, ET C'ÉTAIT LE TROISIÈME ENDROIT.

    `dans_enveloppe()` et `sort_par_la_bouche()` avaient été corrigés ;
    celle-ci portait encore les deux mêmes fautes, et elle décide à elle
    seule de tout le contrôle 4 :

      * `demi = hw · 0,55` est SYMÉTRIQUE. Sur une section franchement
        dissymétrique, le noyau déborde du côté étroit. Mesuré sur la
        géométrie A1 : aux stations 4 à 8 le noyau symétrique dépasse la
        paroi `droite` de 0,36 à 0,75 m, c'est-à-dire qu'une partie du
        volume « qui doit être de l'air » est DANS LA ROCHE. Un rayon tiré
        du dehors y rencontre de la matière avant d'atteindre le noyau et
        la case est comptée fermée : le contrôle 4 se tait sur une paroi
        qu'il croit examiner ;
      * `abs(point[0] - ax)` mesure le long de X, pas de la normale — le
        piège que le générateur porte en commentaire depuis deux passes.

    Le biais du noyau reste assumé et directionnel (55 % : il fait manquer
    des trous marginaux, il n'en fabrique pas). Ce qui est réparé ici, ce
    n'est pas le biais, c'est le fait qu'il n'était plus centré sur la
    cavité.
    """
    if not _entre_les_bouts(profil, point):
        return False
    u = profil.u_projete(point)
    _, _, hw, cle, palier = profil.station(u)
    lateral = profil.lateral(point, u)
    demi = profil.demi_largeur(u, lateral) * NOYAU_LARGEUR
    if abs(lateral) > demi:
        return False
    largeur_cote = profil.demi_largeur(u, lateral)
    bas = profil.sol(u, (lateral / largeur_cote) if largeur_cote else 0.0) \
        + NOYAU_MARGE_SOL
    haut = palier + cle * NOYAU_HAUTEUR
    return bas <= point[2] <= haut


# ---------------------------------------------------------------------------
# CE QUE « PERCÉE CONFIRMÉE » VEUT DIRE.
#
# Le gate du lead est « 0 percée confirmée ». Le mot doit donc porter une
# définition mesurable, et une définition capable de me contredire.
#
#   RAYON SUSPECT     — un rayon parti du vide de la galerie et qui n'en
#                       ressort pas par la bouche avec une parité paire.
#                       C'est ce que comptait la version précédente, et
#                       c'est ce qu'elle appelait « percée ». Un rayon
#                       suspect ne prouve rien : il naît aussi bien d'un
#                       vrai trou que d'un rayon rasant une arête ou d'une
#                       fente de décimation d'un dixième de millimètre.
#
#   PERCÉE CONFIRMÉE  — il existe une direction `d` et un point `p` du vide
#                       tels que TOUS les rayons d'une grille de pas
#                       `PAS_OUVERTURE_M`, couvrant un CARRÉ de côté
#                       `OUVERTURE_CONFIRMEE_M` perpendiculaire à `d` et
#                       parallèles à `d`, sortent de la formation.
#                       Autrement dit : un carré de 10 cm de côté est
#                       INTÉGRALEMENT percé.
#
# POURQUOI UN CARRÉ, ET POURQUOI 10 cm.
#
#   * un carré, parce qu'une fente ne se voit pas. Une fissure de 0,3 mm de
#     large et d'un mètre de long produit des dizaines de rayons suspects et
#     n'est visible à aucune distance : à 4 m, 0,3 mm sous-tend 0,004°, soit
#     0,07 pixel dans les captures livrées. Exiger un carré la rejette,
#     exiger une surface ne suffirait pas ;
#   * 10 cm, parce que c'est le plus petit trou dont la visibilité est
#     DÉMONTRABLE plutôt que plaidée. Les captures de preuve font 1280x720
#     à 40–55° de champ, soit au mieux 0,058°/pixel. Un carré de 0,10 m vu
#     à la plus grande distance intérieure possible (~10,4 m, la longueur
#     de la galerie) sous-tend 0,55°, donc environ 9 pixels de côté : il est
#     dans l'image. Sous 10 cm, on ne peut plus l'affirmer ;
#   * 10 cm, aussi, parce que c'est le double de `EPAISSEUR_ECAILLE_M`
#     (0,05 m), l'épaisseur sous laquelle le générateur déclare lui-même que
#     deux impacts sont un pli vu deux fois. Une écaille ne peut donc pas
#     produire une percée confirmée.
#
# LE SEUIL EST UN RÉGLAGE (`--ouverture`), PAS UNE VÉRITÉ. Le baisser
# resserre le gate ; le monter le relâche. Ce qui n'est pas négociable, et
# ce que le lead a fixé, c'est la conséquence : UNE SEULE percée confirmée
# fait échouer la géométrie.
# ---------------------------------------------------------------------------

OUVERTURE_CONFIRMEE_M = 0.10
PAS_OUVERTURE_M = 0.025
## Demi-étendue du faisceau. 0,15 m, soit trois fois l'ouverture exigée :
## le carré de 10 cm est cherché N'IMPORTE OÙ dans le faisceau, jamais
## seulement en son centre. Sans cette marge, un trou de 12 cm dont le rayon
## suspect part de son bord serait déclaré non confirmé — la sonde
## sous-compterait, et un gate qui sous-compte ment dans le sens dangereux.
DEMI_FAISCEAU_M = 0.15


def _base_orthonormee(direction):
    d = _normaliser(direction)
    appui = (0.0, 0.0, 1.0) if abs(d[2]) < 0.9 else (1.0, 0.0, 0.0)
    u = _normaliser(_croix(d, appui))
    v = _croix(d, u)
    return u, v


def _plus_grand_carre(masque):
    """Côté (en cases) du plus grand carré plein du masque booléen.

    Programmation dynamique classique. Rend (cote, i, j) où (i, j) est le
    coin bas-droit du carré, ou (0, -1, -1).
    """
    n = len(masque)
    m = len(masque[0]) if n else 0
    meilleur, bi, bj = 0, -1, -1
    dp = [[0] * m for _ in range(n)]
    for i in range(n):
        for j in range(m):
            if not masque[i][j]:
                continue
            if i == 0 or j == 0:
                dp[i][j] = 1
            else:
                dp[i][j] = 1 + min(dp[i - 1][j], dp[i][j - 1],
                                   dp[i - 1][j - 1])
            if dp[i][j] > meilleur:
                meilleur, bi, bj = dp[i][j], i, j
    return meilleur, bi, bj


def mesurer_ouverture(grille, origine, direction, profil,
                      demi=DEMI_FAISCEAU_M, pas=PAS_OUVERTURE_M):
    """Côté, en mètres, du plus grand carré INTÉGRALEMENT percé.

    Un faisceau de rayons parallèles à `direction`, décalés latéralement sur
    une grille de pas `pas`, part de points voisins de `origine`. Un rayon
    compte comme sortant s'il quitte la formation — parité impaire ou aucun
    impact — et si son point de départ est bien dans le vide.

    LE CONTRÔLE DU VIDE N'EST PAS DÉCORATIF. Sans lui, un point de départ
    décalé qui tombe DANS la roche donne une parité impaire, donc un faux
    « sortant », donc une ouverture surestimée. C'est le seul biais de cette
    mesure qui irait dans le sens dangereux ; il est fermé.

    Rend (cote_m, sortants, total, centre_du_carre_ou_None).
    """
    u, v = _base_orthonormee(direction)
    n = int(round(demi / pas))
    masque = []
    sortants = 0
    total = 0
    for i in range(-n, n + 1):
        ligne = []
        for j in range(-n, n + 1):
            p = tuple(origine[k] + u[k] * (i * pas) + v[k] * (j * pas)
                      for k in range(3))
            total += 1
            vide, _ = dans_le_vide(grille, p)
            if not vide:
                ligne.append(False)
                continue
            if sort_par_la_bouche(p, direction, profil):
                ligne.append(False)
                continue
            liste = impacts(grille, p, direction)
            ouvert = (len(liste) == 0) or (len(liste) % 2 != 0)
            if ouvert:
                sortants += 1
            ligne.append(ouvert)
        masque.append(ligne)
    cote, bi, bj = _plus_grand_carre(masque)
    centre = None
    if cote > 0:
        ci = bi - (cote - 1) / 2.0 - n
        cj = bj - (cote - 1) / 2.0 - n
        centre = tuple(origine[k] + u[k] * (ci * pas) + v[k] * (cj * pas)
                       for k in range(3))
    return (max(0, cote - 1) * pas, sortants, total, centre)


def confirmer_percees(grille, suspects, profil, ouverture=OUVERTURE_CONFIRMEE_M,
                      plafond=None):
    """Promeut les rayons suspects en percées CONFIRMÉES, ou les écarte.

    Les suspects sont d'abord regroupés par point de sortie (maille de
    0,25 m) : dix rayons issus du même trou n'exigent pas dix mesures, et
    ne doivent pas compter pour dix percées. Une percée confirmée est un
    LIEU, pas un rayon.
    """
    amas = {}
    for f in suspects:
        cle = tuple(int(math.floor(c / 0.25)) for c in f["sortie"])
        amas.setdefault(cle, []).append(f)
    ordre = sorted(amas.items(), key=lambda kv: -len(kv[1]))
    if plafond is not None:
        ordre = ordre[:plafond]
    confirmees, ecartees = [], []
    for _, lot in ordre:
        # Le rayon le plus représentatif du groupe : celui dont la sortie
        # est la plus proche du centre de l'amas.
        centre = [sum(f["sortie"][k] for f in lot) / len(lot) for k in range(3)]
        lot = sorted(lot, key=lambda f: sum(
            (f["sortie"][k] - centre[k]) ** 2 for k in range(3)))
        temoin = lot[0]
        origine = (temoin["x"], temoin["y"], temoin["z"])
        azimut = math.radians(temoin["azimut"])
        elevation = math.radians(temoin["elevation"])
        direction = (math.cos(elevation) * math.cos(azimut),
                     math.cos(elevation) * math.sin(azimut),
                     math.sin(elevation))
        cote, sortants, total, milieu = mesurer_ouverture(
            grille, origine, direction, profil)
        fiche = dict(rayons_suspects=len(lot),
                     sortie=[round(c, 2) for c in centre],
                     depart=[round(c, 2) for c in origine],
                     azimut=temoin["azimut"], elevation=temoin["elevation"],
                     ouverture_m=round(cote, 4),
                     faisceau_sortant=sortants, faisceau_total=total,
                     surface=surface_de_sortie(profil, centre))
        if milieu is not None:
            fiche["centre_ouverture"] = [round(c, 2) for c in milieu]
        if cote >= ouverture - 1e-9:
            confirmees.append(fiche)
        else:
            ecartees.append(fiche)
    return confirmees, ecartees


def surface_de_sortie(profil, point):
    """Par QUELLE face de la cavité le rayon est-il sorti ?

    Le plafond n'était nommé nulle part : le contrôle 1 regarde le sol, la
    carte du fond regarde le fond, et le contrôle 2 tire bien vers le haut
    mais range ses fautes par station et azimut — on ne pouvait donc pas
    lire « le toit est percé » dans sa sortie. Cette fonction attribue à
    chaque sortie l'une des six faces, pour que le rapport nomme le défaut
    par son endroit.

    NEUVIÈME ENDROIT DE LA MÊME FAUTE. Trois lignes, trois fois la même :
    `(point[0] - ax)/hw` mesurait le long de X contre une demi-largeur
    symétrique, `dx = hw - abs(...)` aussi, et le côté se décidait sur
    `point[0] > ax`. Conséquence directe : une percée du flanc GAUCHE d'une
    section inclinée pouvait être nommée `paroi_plus_x`, et une percée de
    paroi être nommée `plancher` parce que la distance à la paroi était
    calculée dans la mauvaise direction. Le compte de percées ne changeait
    pas ; l'ADRESSE écrite dans la consigne de correction, si — et une
    consigne qui désigne le mauvais flanc envoie corriger de la roche saine.

    Les noms `paroi_moins_x` / `paroi_plus_x` sont CONSERVÉS pour ne pas
    casser `SURFACES` ni les rasters, mais ils désignent désormais les côtés
    `gauche` (offset normal négatif) et `droite`. Le libellé est un héritage,
    la mesure ne l'est plus.
    """
    u = profil.u_projete(point)
    # Au-dela de la derniere station le long de la TANGENTE, c'est le fond.
    axf = profil.station(float(len(profil.cavite) - 1))
    tx, ty = -profil.normale(float(len(profil.cavite) - 1))[1], \
        profil.normale(float(len(profil.cavite) - 1))[0]
    if (point[0] - axf[0]) * tx + (point[1] - axf[1]) * ty > 0.0:
        return "fond"
    ax0 = profil.station(0.0)
    tx0, ty0 = -profil.normale(0.0)[1], profil.normale(0.0)[0]
    if (point[0] - ax0[0]) * tx0 + (point[1] - ax0[1]) * ty0 < 0.0:
        return "bouche"
    _, _, hw, cle, palier = profil.station(u)
    lateral_m = profil.lateral(point, u)
    demi = profil.demi_largeur(u, lateral_m)
    fraction = (lateral_m / demi) if demi else 0.0
    dz_haut = (palier + profil.cle_au_lateral(u, lateral_m)) - point[2]
    dz_bas = point[2] - profil.sol(u, fraction)
    dlat = demi - abs(lateral_m)
    if min(dz_haut, dz_bas, dlat) == dz_haut:
        return "toit"
    if min(dz_bas, dlat) == dz_bas:
        return "plancher"
    return "paroi_plus_x" if lateral_m > 0.0 else "paroi_moins_x"


# ---------------------------------------------------------------------------
# LES CINQ SURFACES — plancher, toit, deux parois, fond.
#
# Le contrôle 2 tire depuis l'INTÉRIEUR ; ces rasters tirent depuis
# l'EXTÉRIEUR, une face à la fois, en visant le noyau. Deux méthodes
# indépendantes qui se contredisent valent mieux qu'une seule qui se
# confirme elle-même — et surtout, le raster répond à la question que le
# contrôle 2 ne pose pas : « quelle FACE est percée, et sur quelle
# emprise ? ». La version précédente n'avait de carte que pour le plancher
# et le fond ; le TOIT et les PAROIS n'étaient cartographiés nulle part.
#
# Le pas vaut la moitié de l'ouverture exigée : un trou de
# `OUVERTURE_CONFIRMEE_M` ne peut pas passer entre deux échantillons
# (Nyquist). Le raster ne CONCLUT pas — il désigne des candidats que
# `mesurer_ouverture` confirme ou écarte, avec la même définition que les
# rayons suspects du contrôle 2.
# ---------------------------------------------------------------------------

SURFACES = ("plancher", "toit", "paroi_moins_x", "paroi_plus_x", "fond")


_EMPRISE_CACHE = {}


def _emprise_noyau(profil, pas_u=0.05):
    """Boîte alignée sur les axes contenant le noyau.

    DEUX DÉFAUTS RÉPARÉS ICI.

    1. `cle` servait de CLÉ DE CACHE puis était écrasée par la hauteur de
       clé rendue par `station()`. L'écriture se faisait donc sous un
       flottant, jamais sous la clé lue — le cache ne servait jamais et le
       dictionnaire se remplissait d'entrées mortes. Silencieux, comme il
       se doit pour ce genre de faute.
    2. L'emprise était calculée le long de X et symétriquement. Sur une
       galerie qui s'infléchit, le noyau est décalé le long de la NORMALE :
       une emprise en X manque une partie du volume, et le raster n'a alors
       aucune case en face.
    """
    memo = (id(profil), pas_u)
    if memo in _EMPRISE_CACHE:
        return _EMPRISE_CACHE[memo]
    xs, ys, zs = [], [], []
    u = 1.0                      # depuis le SEUIL : le porche est ouvert
    while u <= len(profil.cavite) - 1 + 1e-9:
        ax, ay, _, cle_voute, palier = profil.station(u)
        nx, ny = profil.normale(u)
        for signe in (-1.0, 1.0):
            # `demi_largeur` attend un latéral SIGNÉ pour choisir le côté.
            demi = profil.demi_largeur(u, signe) * NOYAU_LARGEUR
            xs.append(ax + signe * demi * nx)
            ys.append(ay + signe * demi * ny)
        ys.append(ay)
        zs += [profil.sol(u, 0.0) + NOYAU_MARGE_SOL,
               palier + cle_voute * NOYAU_HAUTEUR]
        u += pas_u
    _EMPRISE_CACHE[memo] = ((min(xs), max(xs)), (min(ys), max(ys)),
                            (min(zs), max(zs)))
    return _EMPRISE_CACHE[memo]


def raster_surface(grille, profil, surface, pas=None):
    """Une face vue de l'extérieur : où la roche manque-t-elle ?

    Une case est OUVERTE quand le rayon, tiré du dehors vers la cavité,
    atteint le noyau sans avoir rencontré un seul triangle. Rend un masque,
    ses axes, et les points monde-modèle des cases ouvertes.
    """
    if pas is None:
        pas = OUVERTURE_CONFIRMEE_M / 2.0
    (x0, x1), (y0, y1), (z0, z1) = _emprise_noyau(profil)
    lo, hi = grille.aabb()
    marge = 2.0

    def _axe(a, b):
        n = max(1, int(math.ceil((b - a) / pas)) + 1)
        return [a + i * pas for i in range(n)]

    if surface in ("plancher", "toit"):
        axe_a, axe_b = _axe(x0, x1), _axe(y0, y1)
        if surface == "plancher":
            direction, base = (0.0, 0.0, 1.0), lo[2] - marge
        else:
            direction, base = (0.0, 0.0, -1.0), hi[2] + marge

        def _origine(a, b):
            return (a, b, base)
        noms = ("x", "y")
    elif surface in ("paroi_moins_x", "paroi_plus_x"):
        axe_a, axe_b = _axe(y0, y1), _axe(z0, z1)
        if surface == "paroi_moins_x":
            direction, base = (1.0, 0.0, 0.0), lo[0] - marge
        else:
            direction, base = (-1.0, 0.0, 0.0), hi[0] + marge

        def _origine(a, b):
            return (base, a, b)
        noms = ("y", "z")
    else:                        # fond
        axe_a, axe_b = _axe(x0, x1), _axe(z0, z1)
        direction, base = (0.0, -1.0, 0.0), hi[1] + marge

        def _origine(a, b):
            return (a, base, b)
        noms = ("x", "z")

    portee = max(hi[k] - lo[k] for k in range(3)) + 2.0 * marge
    masque, ouvertes = [], []
    for a in axe_a:
        ligne = []
        for b in axe_b:
            origine = _origine(a, b)
            t_noyau = _entree_noyau(profil, origine, direction, portee)
            if t_noyau is None:
                ligne.append(False)
                continue
            liste = impacts(grille, origine, direction, portee)
            ouvert = (not liste) or (liste[0][0] > t_noyau)
            ligne.append(ouvert)
            if ouvert:
                point = tuple(origine[k] + direction[k] * t_noyau
                              for k in range(3))
                ouvertes.append(dict(a=round(a, 3), b=round(b, 3),
                                     point=[round(c, 2) for c in point]))
        masque.append(ligne)
    return dict(surface=surface, pas=pas, axes=noms, axe_a=axe_a, axe_b=axe_b,
                masque=masque, ouvertes=ouvertes, direction=direction,
                base=base)


def _entree_noyau(profil, origine, direction, portee, pas=0.05):
    """Premier paramètre `t` où le rayon entre dans le noyau, ou None.

    Marche à pas fin. Les rayons de raster sont axiaux et le noyau est
    convexe en section, mais la galerie s'infléchit : une résolution
    analytique par axe serait un cas particulier de plus à maintenir, et
    la marche coûte moins d'une milliseconde.
    """
    # PRÉ-TEST DE BOÎTE. Sans lui, un rayon de ciel marche 8 000 pas pour
    # rien, et le contrôle 3 passe de quelques secondes à plusieurs minutes.
    # Mesuré : le pré-test ramène l'épreuve de ligne de vue sous la seconde.
    (bx0, bx1), (by0, by1), (bz0, bz1) = _emprise_noyau(profil)
    t0, t1 = 0.0, portee
    for k, (lo_k, hi_k) in enumerate(((bx0, bx1), (by0, by1), (bz0, bz1))):
        if abs(direction[k]) < 1e-12:
            if origine[k] < lo_k or origine[k] > hi_k:
                return None
            continue
        a = (lo_k - origine[k]) / direction[k]
        b = (hi_k - origine[k]) / direction[k]
        if a > b:
            a, b = b, a
        t0, t1 = max(t0, a), min(t1, b)
    if t0 > t1:
        return None
    t = max(0.0, t0 - pas)
    while t <= t1 + pas:
        p = (origine[0] + direction[0] * t, origine[1] + direction[1] * t,
             origine[2] + direction[2] * t)
        if dans_le_noyau(profil, p):
            return t
        t += pas
    return None


def candidats_du_raster(raster, ouverture=OUVERTURE_CONFIRMEE_M):
    """Blocs de cases ouvertes assez larges pour mériter une confirmation.

    Un bloc isolé de une ou deux cases ne peut pas porter un carré de
    `ouverture` : on ne dépense pas un faisceau dessus. Le raster propose,
    la mesure d'ouverture dispose.
    """
    masque = raster["masque"]
    cote_mini = max(2, int(round(ouverture / raster["pas"])) + 1)
    n, m = len(masque), len(masque[0]) if masque else 0
    vus = set()
    blocs = []
    for i in range(n):
        for j in range(m):
            if not masque[i][j] or (i, j) in vus:
                continue
            pile, amas = [(i, j)], []
            vus.add((i, j))
            while pile:
                ci, cj = pile.pop()
                amas.append((ci, cj))
                for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    vi, vj = ci + di, cj + dj
                    if 0 <= vi < n and 0 <= vj < m and (vi, vj) not in vus \
                            and masque[vi][vj]:
                        vus.add((vi, vj))
                        pile.append((vi, vj))
            ia = [c[0] for c in amas]
            ja = [c[1] for c in amas]
            large = (max(ia) - min(ia) + 1) >= cote_mini \
                and (max(ja) - min(ja) + 1) >= cote_mini
            blocs.append(dict(cases=len(amas),
                              a0=round(raster["axe_a"][min(ia)], 3),
                              a1=round(raster["axe_a"][max(ia)], 3),
                              b0=round(raster["axe_b"][min(ja)], 3),
                              b1=round(raster["axe_b"][max(ja)], 3),
                              centre=(raster["axe_a"][(min(ia) + max(ia)) // 2],
                                      raster["axe_b"][(min(ja) + max(ja)) // 2]),
                              assez_large=large))
    blocs.sort(key=lambda b: -b["cases"])
    return blocs


def controle_surfaces(grille, profil, pas=None, ouverture=OUVERTURE_CONFIRMEE_M):
    """Les cinq faces, rasterisées et confirmées.

    La BOUCHE n'est pas rasterisée : elle est ouverte par construction, et
    la juger fabriquerait un défaut — même arbitrage que le contrôle 2, et
    pour la même raison. Le PORCHE est exclu de l'emprise pour la même
    raison (`_emprise_noyau` part de la station 1).
    """
    sortie = {}
    for surface in SURFACES:
        raster = raster_surface(grille, profil, surface, pas)
        blocs = candidats_du_raster(raster, ouverture)
        confirmees = []
        for bloc in blocs:
            if not bloc["assez_large"]:
                continue
            a, b = bloc["centre"]
            direction = raster["direction"]
            # On mesure l'ouverture DEPUIS L'INTÉRIEUR, en tirant vers
            # l'extérieur : c'est la question du joueur, et cela réutilise
            # exactement la définition appliquée aux rayons suspects.
            t = _entree_noyau(profil, _origine_raster(raster, a, b), direction,
                              200.0)
            if t is None:
                continue
            origine = _origine_raster(raster, a, b)
            interieur = tuple(origine[k] + direction[k] * (t + 0.30)
                              for k in range(3))
            inverse = tuple(-c for c in direction)
            cote, sortants, total, milieu = mesurer_ouverture(
                grille, interieur, inverse, profil)
            fiche = dict(bloc_cases=bloc["cases"],
                         emprise={raster["axes"][0]: [bloc["a0"], bloc["a1"]],
                                  raster["axes"][1]: [bloc["b0"], bloc["b1"]]},
                         ouverture_m=round(cote, 4),
                         faisceau_sortant=sortants, faisceau_total=total,
                         depart=[round(c, 2) for c in interieur])
            if cote >= ouverture - 1e-9:
                confirmees.append(fiche)
        sortie[surface] = dict(
            cases=sum(len(l) for l in raster["masque"]),
            cases_ouvertes=sum(1 for l in raster["masque"] for c in l if c),
            blocs=blocs[:6], confirmees=confirmees, pas=raster["pas"],
            axes=list(raster["axes"]))
    return sortie


def _origine_raster(raster, a, b):
    """Point de départ d'un rayon de raster, aux coordonnées d'axe (a, b).

    Les deux axes du raster sont ceux que `raster_surface` a nommés ; le
    troisième est l'axe de tir, dont la coordonnée de départ est `base`.
    """
    direction = raster["direction"]
    base = raster["base"]
    if direction[2] != 0.0:                 # plancher / toit : tir en Z
        return (a, b, base)
    if direction[0] != 0.0:                 # parois : tir en X
        return (base, a, b)
    return (a, base, b)                     # fond : tir en Y


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


def _lire_table(texte, nom):
    """Table de tuples `NOM = [ (...), (...) ]` lue textuellement."""
    marque = "%s = [" % nom
    if marque not in texte:
        return None
    bloc = texte.split(marque, 1)[1].split("]", 1)[0]
    lignes = [l.split("#")[0].strip().strip(",")
              for l in bloc.split("\n") if l.strip().startswith("(")]
    return [tuple(float(v) for v in l.strip("()").split(",") if v.strip())
            for l in lignes]


def charger_les_cotes(source):
    """Rebinde les cotes de la sonde sur CELLES D'UN GÉNÉRATEUR DONNÉ.

    POURQUOI CETTE PORTE EXISTE, ET POURQUOI ELLE EST ÉTROITE.

    Les cotes de ce fichier décrivent UNE galerie. Mesurer un autre `.glb`
    avec elles reviendrait à promener un tube imaginaire dans de la roche
    réelle : chaque nombre sortirait plausible et aucun ne voudrait rien
    dire. C'est le mode de panne le plus coûteux de cette sonde, parce qu'il
    ne produit ni erreur ni silence — il produit un rapport.

    Mesuré : entre la galerie livrée (R2a-3.4) et celle de la passe en
    cours, l'axe passe de y ∈ [-1,15 ; 9,25] à y ∈ [-1,15 ; 3,17], et
    `PALIER` change à six stations sur neuf. Deux grottes différentes sous
    le même nom de fichier.

    On ne recopie donc rien : on LIT le générateur qui a produit le maillage
    qu'on s'apprête à mesurer, et on rebinde. `controle_coherence_cotes()`
    tourne ensuite contre CE MÊME fichier, donc il passe — ce n'est pas un
    contournement du garde-fou, c'est le garde-fou appliqué à la bonne
    référence.
    """
    global CAVITE, CAVITE_ASYM, PALIER, SAG, PORCHE_DENIVELE, PROFIL_GROTTE
    if not os.path.isfile(source):
        raise Blocage("source du generateur introuvable : %s" % source)
    texte = open(source, "r", encoding="utf-8").read()
    cavite = _lire_table(texte, "CAVITE")
    asym = _lire_table(texte, "CAVITE_ASYM")
    if not cavite:
        raise Blocage("CAVITE absente ou illisible dans %s" % source)
    if not asym:
        raise Blocage("CAVITE_ASYM absente ou illisible dans %s" % source)
    if len(asym) != len(cavite):
        raise Blocage("CAVITE (%d) et CAVITE_ASYM (%d) de longueurs "
                      "differentes dans %s" % (len(cavite), len(asym), source))
    scalaires = {}
    for nom in ("SAG", "PORCHE_DENIVELE"):
        marque = "\n%s = " % nom
        if marque not in texte:
            raise Blocage("constante %s absente de %s" % (nom, source))
        lu = texte.split(marque, 1)[1].split("\n", 1)[0].split("#")[0].strip()
        scalaires[nom] = float(lu)
    if "PALIER = (" not in texte:
        raise Blocage("PALIER absent de %s" % source)
    brut = texte.split("PALIER = (", 1)[1].split(")", 1)[0]
    palier = tuple(float(v) for v in brut.replace("\n", " ").split(",")
                   if v.strip())
    if len(palier) != len(cavite):
        raise Blocage("PALIER (%d) et CAVITE (%d) de longueurs differentes"
                      % (len(palier), len(cavite)))

    CAVITE = cavite
    CAVITE_ASYM = asym
    PALIER = palier
    SAG = scalaires["SAG"]
    PORCHE_DENIVELE = scalaires["PORCHE_DENIVELE"]
    PROFIL_GROTTE = Profil(CAVITE, PALIER, SAG, PORCHE_DENIVELE,
                           max(max(a[0], a[1]) for a in CAVITE_ASYM),
                           "grotte", cavite_asym=CAVITE_ASYM)
    return dict(source=source, stations=len(CAVITE),
                y_min=CAVITE[0][1], y_max=CAVITE[-1][1],
                palier=PALIER, sag=SAG, porche_denivele=PORCHE_DENIVELE)


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
    # `CAVITE` et `CAVITE_ASYM` se lisent pareil, mais `"CAVITE = ["` est un
    # préfixe de `"CAVITE_ASYM = ["`... non : c'est l'inverse qui menace, un
    # `split("CAVITE = [")` naïf trouverait aussi le début de `CAVITE_ASYM`
    # si la marque était `"CAVITE"` seule. Les marques portent donc ` = [`,
    # ce qui les rend disjointes.
    for nom, attendu in (("CAVITE", [tuple(s) for s in CAVITE]),
                         ("CAVITE_ASYM", [tuple(a) for a in CAVITE_ASYM])):
        marque = "%s = [" % nom
        if marque not in texte:
            ecarts.append("table %s absente du generateur" % nom)
            continue
        bloc = texte.split(marque, 1)[1].split("]", 1)[0]
        lignes = [l.split("#")[0].strip().strip(",")
                  for l in bloc.split("\n") if l.strip().startswith("(")]
        valeurs = []
        for ligne in lignes:
            valeurs.append(tuple(float(v) for v in
                                 ligne.strip("()").split(",") if v.strip()))
        if valeurs != attendu:
            # ON DIT OÙ. « ne correspond pas » envoie relire 9 lignes à la
            # main ; la station divergente est une consigne.
            detail = "%d station(s) au generateur, %d a la sonde" % (
                len(valeurs), len(attendu))
            for i in range(min(len(valeurs), len(attendu))):
                if valeurs[i] != attendu[i]:
                    detail = ("station %d : generateur %s, sonde %s"
                              % (i, valeurs[i], attendu[i]))
                    break
            ecarts.append("%s : %s" % (nom, detail))
    return ecarts


# ---------------------------------------------------------------------------

## LES MARQUEURS DE DÉFAUT, ET POURQUOI ILS SONT UNE LISTE ET NON UNE
## HABITUDE DE LECTURE.
##
## Mon journal de la passe précédente imprimait, textuellement :
##
##     y  +3.06  station 7  .   0/1  ecart max 0.45 m  z du fond +0.08  <-- TROU
##     ...
##     PASS — un sol existe sous chaque point sonde
##
## Les deux lignes disaient le contraire l'une de l'autre, à trente lignes
## d'intervalle, et la seconde a été recopiée dans un rapport. Le défaut
## n'est pas d'avoir mal lu : c'est qu'une machine acceptait d'imprimer les
## deux. La correction ne peut donc pas être « faire attention » — c'est
## exactement le genre de correction qui ne tient pas une passe.
##
## `Journal` enregistre chaque ligne. `dire_pass()` refuse d'émettre un
## acquittement tant qu'un marqueur de défaut a été vu, et le contrôle final
## `incoherences()` rebalaye TOUT le journal : un site futur qui imprimerait
## « PASS » sans passer par `dire_pass` serait attrapé quand même.
MARQUEURS_DEFAUT = ("<-- TROU", ">>> PERCEE CONFIRMEE", "BLOQUE:",
                    "PERCEE CONFIRMEE", "OUVERT :")

## Ce qui compte comme un acquittement dans une relecture rapide.
MARQUEURS_ACQUIT = ("PASS —", "PASS -", "VERDICT : PASS")


class Journal(object):
    """Sortie de la sonde, avec mémoire et interdiction mécanique.

    Une seule règle, et elle est structurelle : dans une même SECTION, un
    acquittement ne peut pas coexister avec un marqueur de défaut. Pas
    « ne devrait pas » — la fonction refuse d'imprimer.

    POURQUOI PAR SECTION, ET NON SUR LE JOURNAL ENTIER.
    ==================================================

    Une interdiction globale serait plus simple et serait FAUSSE : le
    contrôle 2 peut légitimement acquitter les parois pendant que la carte
    du plancher montre un trou. Ce sont deux questions, et les confondre
    referait au verdict ce que le défaut d'origine faisait au plancher —
    répondre à une autre question que celle posée.

    Ce qui a menti, c'est un acquittement de PLANCHER trente lignes sous un
    trou de PLANCHER. C'est cette coexistence-là, et elle seule, qui est
    rendue impossible.
    """

    def __init__(self):
        self.lignes = []                  # (section, texte)
        self.section_courante = "entete"
        self.acquits_refuses = []

    def __call__(self, texte=""):
        self.lignes.append((self.section_courante, texte))
        print(texte)

    def section(self, nom):
        self.section_courante = nom

    def defauts_vus(self, section=None):
        return [t for s, t in self.lignes
                if (section is None or s == section)
                and any(m in t for m in MARQUEURS_DEFAUT)]

    def dire_pass(self, texte):
        """Imprime un acquittement, ou explique pourquoi il est refusé."""
        vus = self.defauts_vus(self.section_courante)
        if vus:
            self("   ACQUITTEMENT REFUSE — la section « %s » porte deja %d "
                 "marqueur(s) de defaut." % (self.section_courante, len(vus)))
            self("      premier defaut : %s" % vus[0].strip())
            self("      texte refuse   : %s" % texte.strip())
            self.acquits_refuses.append(
                dict(section=self.section_courante, texte=texte.strip(),
                     defaut=vus[0].strip()))
            return False
        self(texte)
        return True

    def incoherences(self):
        """Acquittements coexistant, DANS LEUR SECTION, avec un défaut.

        Rebalaye le journal entier, y compris les lignes imprimées sans
        passer par `dire_pass`. C'est le filet qui rattrape le site futur —
        celui qu'on écrira dans six mois sans avoir lu ce commentaire.
        """
        trouvees = []
        sections = []
        for s, _ in self.lignes:
            if s not in sections:
                sections.append(s)
        for s in sections:
            defauts = self.defauts_vus(s)
            if not defauts:
                continue
            for sec, texte in self.lignes:
                if sec == s and any(m in texte for m in MARQUEURS_ACQUIT):
                    trouvees.append((s, texte, defauts[0]))
        return trouvees


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
    ap.add_argument("--place",
                    default="scripts/world_v2/poi/waterfall_cave_place.gd",
                    help="script de lieu d'ou la POSE est derivee")
    ap.add_argument("--layout",
                    default="resources/world_v2/world_v2_layout.json")
    ap.add_argument("--poi", default="valley.poi.waterfall_cave.01")
    ap.add_argument("--terrain-sous-seuil", type=float,
                    default=TERRAIN_SOUS_SEUIL_M,
                    help="hauteur monde du terrain gele sous le seuil. "
                         "DOCUMENTAIRE ; sa sensibilite est mesuree.")
    ap.add_argument("--pas-pixel", type=int, default=8)
    ap.add_argument("--ouverture", type=float, default=OUVERTURE_CONFIRMEE_M,
                    help="cote minimal, en metres, d'un carre integralement "
                         "perce pour qu'une percee soit CONFIRMEE")
    ap.add_argument("--pas-raster", type=float, default=None,
                    help="pas des rasters de surface (defaut : ouverture/2, "
                         "Nyquist)")
    ap.add_argument("--cotes-de", default=None,
                    help="generateur d'ou LIRE les cotes, au lieu de celles "
                         "recopiees dans cette sonde. Indispensable pour "
                         "mesurer un .glb produit par un autre generateur : "
                         "sans lui on promene un tube imaginaire dans de la "
                         "roche reelle et tous les chiffres sortent "
                         "plausibles. Implique --source.")
    ap.add_argument("--pas-lateral", type=float, default=0.20,
                    help="pas LATERAL en metres. Metrique et non fractionnaire "
                         "expres : une fraction de la demi-largeur espace six "
                         "fois plus les echantillons du cote large que du cote "
                         "etroit, donc ne peut porter aucune garantie de "
                         "couverture. Voir offsets_lateraux().")
    ap.add_argument("--json", default=None)
    ap.add_argument("--rapide", action="store_true",
                    help="echantillonnage reduit, pour iterer")
    args = ap.parse_args()

    ## TOUT le journal passe par l'enregistreur — c'est ce qui rend le
    ## contrôle de cohérence final exhaustif au lieu de sélectif. Le nom
    ## `print` est masqué localement : aucun site d'impression de `main()`
    ## n'échappe au filet, y compris ceux qui seront écrits demain.
    journal = Journal()
    print = journal                                        # noqa: A001

    print("=" * 74)
    print("SONDE DE CONTINUITE — Grotte du Couchant")
    print("=" * 74)

    if args.cotes_de:
        # LES COTES D'ABORD : tout ce qui suit en depend, y compris le
        # controle de coherence, qui doit porter sur CE generateur-la.
        try:
            charge = charger_les_cotes(args.cotes_de)
        except Blocage as erreur:
            print("BLOQUE: cotes illisibles — %s" % erreur)
            return 3
        args.source = args.cotes_de
        print("cotes  : LUES dans %s" % charge["source"])
        print("         %d stations, axe y de %+.2f a %+.2f, sag %.2f, "
              "denivele de porche %+.2f"
              % (charge["stations"], charge["y_min"], charge["y_max"],
                 charge["sag"], charge["porche_denivele"]))

    try:
        ecarts = controle_coherence_cotes(args.source)
        if ecarts:
            for e in ecarts:
                print("BLOQUE: cotes divergentes — %s" % e)
            return 3
        print("cotes  : CAVITE, CAVITE_ASYM, PALIER, SAG, PORCHE_DENIVELE "
              "conformes au generateur")
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
        pose = Pose.depuis_les_sources(args.place, args.layout, args.poi,
                                       args.terrain_sous_seuil)
    except Blocage as erreur:
        print("BLOQUE: %s" % erreur)
        return 3

    profil = PROFIL_GROTTE

    print()
    print("-" * 74)
    journal.section("controle_0_pose")
    print("CONTROLE 0 — LA POSE MONDE, DERIVEE ET EPROUVEE")
    print("-" * 74)
    print("origine   : (%.3f ; %.3f ; %.3f), lacet %.1f deg" %
          (pose.origine + (pose.lacet_deg,)))
    print("derivee de: %s -> v2_site %s" % (args.layout,
                                            pose.provenance["v2_site"]))
    print("            %s -> SEUIL_LOCAL %s, LACET_DEG %.1f, EXHAUSSEMENT %.2f"
          % (args.place, pose.provenance["seuil_local"],
             pose.provenance["lacet_deg"], pose.provenance["exhaussement"]))
    print("            terrain sous le seuil %.2f m — %s"
          % (pose.provenance["terrain_sous_seuil"],
             pose.provenance["terrain_statut"]))
    ecart_ar, details_ar = pose.controle_aller_retour()
    print("aller-retour modele->monde(matrices)->modele(forme fermee) :")
    print("   ecart max %.3e m sur 14 points et 5 directions, tolerance %.0e m"
          % (ecart_ar, TOLERANCE_ALLER_RETOUR_M))
    resultat_pose = dict(origine=[round(c, 4) for c in pose.origine],
                         lacet_deg=pose.lacet_deg,
                         provenance=pose.provenance,
                         aller_retour_ecart_m=ecart_ar,
                         aller_retour_tolerance_m=TOLERANCE_ALLER_RETOUR_M)
    if ecart_ar > TOLERANCE_ALLER_RETOUR_M:
        print("   BLOQUE — les deux implementations de la transformation ne "
              "se rendent pas le meme point :")
        for d in details_ar[:5]:
            print("      %s" % d)
        resultat_pose["verdict"] = "BLOQUE"
        if args.json:
            json.dump(dict(pose=resultat_pose, verdict="BLOQUE"),
                      open(args.json, "w", encoding="utf-8"), indent=1,
                      ensure_ascii=False)
        return 3
    print("   PASS — les deux chemins concordent")
    resultat_pose["verdict"] = "PASS"

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
    ## LE PAS LATÉRAL EST MÉTRIQUE, ET C'EST LE CŒUR DE LA COUVERTURE.
    ## Des fractions donnent un espacement proportionnel à la largeur, donc
    ## six fois plus lâche du côté large — c'est-à-dire du côté de l'alcôve.
    ## Voir `offsets_lateraux`.
    pas_lateral = args.pas_lateral
    echantillons = points_interieurs(pas_long, fractions, hauteurs, profil,
                                     pas_lateral_m=pas_lateral,
                                     grille=grille)
    print("echantillons interieurs : %d (stations 0 a 8, les quatre que le "
          "generateur saute comprises)" % len(echantillons))
    print("   pas longitudinal %.2f m, pas LATERAL METRIQUE %.2f m, hauteurs %s"
          % (pas_long, pas_lateral, ", ".join("%.2f" % h for h in hauteurs)))

    resultat = dict(glb=args.glb, triangles=len(tris),
                    triangles_par_matiere=par_matiere, pose=resultat_pose,
                    ouverture_confirmee_m=args.ouverture)
    rouge = False
    ## Le gate du lead : 0 PERCÉE CONFIRMÉE. Cette liste est ce qu'il
    ## compte ; `rouge` reste pour les autres classes de défaut (plancher
    ## trop bas, cotes divergentes), qui ne sont pas des percées.
    confirmees_totales = []

    print()
    print("-" * 74)
    journal.section("controle_1_plancher")
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
        # CE « PASS » NE PORTE QUE SUR LA HAUTEUR, et il s'imprimait juste
        # au-dessus d'une carte pouvant etre pleine de « TROU ». Deux
        # questions, une seule etiquette : la faute de cette passe, en
        # miniature, dans mon propre journal. `controle_plancher` compte les
        # points dont le sol est a la MAUVAISE HAUTEUR ; la carte, plus bas,
        # cherche les positions laterales SANS AUCUN sol, et c'est elle qui
        # decide du rouge.
        print("   sur le critere de HAUTEUR seulement : aucune faute")
        print("   (l'ABSENCE de sol est jugee par la carte ci-dessous, pas "
              "ici — ne pas lire cette ligne comme un plancher sain)")

    print()
    print("   CARTE DU PLANCHER (positions laterales avec sol / sans sol) :")
    print("   « vises » = positions demandees ; « hors vide » = positions")
    print("   tombees dans la ROCHE et donc jamais interrogees. Un denominateur")
    print("   de 1 sur 5 vises ne dit pas « trou », il dit « presque aveugle ».")
    carte = carte_du_plancher(grille, pas_long, fractions, profil,
                              pas_lateral_m=pas_lateral, grille_parois=grille)
    resultat["plancher"]["carte"] = carte
    manquants = [l for l in carte if l["absents"] > 0]
    for ligne in carte:
        barre = "#" * ligne["presents"] + "." * ligne["absents"]
        marque = "  <-- TROU" if ligne["absents"] else ""
        print("      y %+6.2f  st %d  %-14s %2d/%-2d sondes (%2d vises, %2d hors "
              "vide)  ecart max %s m  z fond %s%s"
              % (ligne["y"], ligne["station"], barre, ligne["presents"],
                 ligne["presents"] + ligne["absents"],
                 ligne["vises"], ligne["hors_vide"],
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
    journal.section("controle_2_jour")
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
          "%d RAYON(S) SUSPECT(S)" % (testes_j, bouche_j, len(fautes_j)))
    print("   « suspect » n'est pas « percee » : voir la definition en tete de")
    print("   OUVERTURE_CONFIRMEE_M. La confirmation est faite plus bas.")
    resultat["jour"] = dict(rayons_testes=testes_j, rayons_par_la_bouche=bouche_j,
                            points_porche_ecartes=ecartes_j,
                            points_hors_cavite=hors_j, fautes=fautes_j,
                            rayons_suspects=len(fautes_j))
    if fautes_j:
        stations = {}
        for f in fautes_j:
            stations.setdefault(f["station"], []).append(f)
        for station in sorted(stations):
            lot = stations[station]
            azimuts = sorted(set(round(f["azimut"]) for f in lot))
            elevations = sorted(set(round(f["elevation"]) for f in lot))
            print("   station %d : %3d rayon(s) suspect(s), azimuts %s, "
                  "elevations %s"
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
        journal.dire_pass("   PASS — aucun rayon ne sort du vide de la galerie")

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
    journal.section("controle_2b_confirmation")
    print("CONTROLE 2b — CONFIRMATION DES RAYONS SUSPECTS")
    print("-" * 74)
    print("Un rayon suspect n'est pas une percee. Une percee est CONFIRMEE")
    print("quand un carre de %.2f m de cote, perpendiculaire au rayon, est"
          % args.ouverture)
    print("INTEGRALEMENT perce — faisceau de pas %.3f m sur +/-%.2f m."
          % (PAS_OUVERTURE_M, DEMI_FAISCEAU_M))
    conf_j, ecart_j = confirmer_percees(grille, fautes_j, profil,
                                        args.ouverture)
    print("%d amas de sortie mesure(s) : %d CONFIRME(S), %d ecarte(s)"
          % (len(conf_j) + len(ecart_j), len(conf_j), len(ecart_j)))
    resultat["jour"]["percees_confirmees"] = conf_j
    resultat["jour"]["amas_ecartes"] = ecart_j
    if ecart_j:
        pire = max(e["ouverture_m"] for e in ecart_j)
        print("   la plus grande ouverture parmi les amas ecartes : %.3f m "
              "(seuil %.2f m)" % (pire, args.ouverture))
        for e in sorted(ecart_j, key=lambda x: -x["ouverture_m"])[:5]:
            print("      ouverture %.3f m  %2d rayon(s)  sortie %s  "
                  "faisceau %d/%d sortant  surface %s"
                  % (e["ouverture_m"], e["rayons_suspects"], e["sortie"],
                     e["faisceau_sortant"], e["faisceau_total"], e["surface"]))
    for c in conf_j:
        confirmees_totales.append(dict(c, origine="controle_2"))
        print("   >>> PERCEE CONFIRMEE  ouverture %.3f m  surface %-13s "
              "sortie %s  %d rayon(s)"
              % (c["ouverture_m"], c["surface"], c["sortie"],
                 c["rayons_suspects"]))
    if not conf_j:
        journal.dire_pass("   PASS — aucun amas ne porte un carre de %.2f m "
                          "integralement perce" % args.ouverture)

    print()
    print("-" * 74)
    journal.section("controle_4_surfaces")
    print("CONTROLE 4 — LES CINQ SURFACES (plancher, TOIT, parois, fond)")
    print("-" * 74)
    print("Rayons tires du DEHORS vers le noyau, une face a la fois. Methode")
    print("independante du controle 2, et la seule qui nomme le TOIT — que la")
    print("version precedente ne cartographiait nulle part.")
    print()
    print("  LIRE « 0 CONFIRMEE » ICI COMME « SAINE » EST UNE ERREUR, ET ELLE")
    print("  EST STRUCTURELLE. Ce controle vise le NOYAU (55 %% de la demi-")
    print("  largeur) par des rayons alignes sur les axes. Deux angles morts")
    print("  lui sont propres, mesures sur la geometrie A1_ASYM :")
    print("    * une percee qui ouvre sur la MARGE, entre le noyau et la")
    print("      paroi, n'est pas visee — 59 des 161 percees du controle 2")
    print("      partaient hors du noyau ;")
    print("    * une percee OBLIQUE peut avoir de la roche au zenith et rien")
    print("      sur sa propre direction — 16 cas, invisibles a un raster")
    print("      aligne sur les axes.")
    print("  Le controle 2 part de l'interieur et balaie la sphere entiere.")
    print("  Les deux ne se remplacent pas : le verdict est le PLUS SEVERE")
    print("  des deux, jamais le plus rassurant.")
    surfaces = controle_surfaces(grille, profil, args.pas_raster,
                                 args.ouverture)
    resultat["surfaces"] = surfaces
    for nom in SURFACES:
        s = surfaces[nom]
        larges = sum(1 for b in s["blocs"] if b["assez_large"])
        print("   %-14s pas %.3f m  %6d case(s), %4d ouverte(s), %d bloc(s) "
              "assez large(s), %d confirmee(s)"
              % (nom, s["pas"], s["cases"], s["cases_ouvertes"], larges,
                 len(s["confirmees"])))
        for b in s["blocs"][:3]:
            if b["cases"] <= 1 and not b["assez_large"]:
                continue
            print("        bloc %4d case(s)  %s[%.2f..%.2f] %s[%.2f..%.2f]%s"
                  % (b["cases"], s["axes"][0], b["a0"], b["a1"],
                     s["axes"][1], b["b0"], b["b1"],
                     "  ASSEZ LARGE" if b["assez_large"] else ""))
        for c in s["confirmees"]:
            confirmees_totales.append(dict(c, surface=nom, origine="controle_4"))
            print("        >>> PERCEE CONFIRMEE sur %s : ouverture %.3f m, "
                  "emprise %s" % (nom, c["ouverture_m"], c["emprise"]))
    if not any(surfaces[n]["confirmees"] for n in SURFACES):
        journal.dire_pass("   PASS — aucune des cinq faces ne porte une percee confirmee")

    print()
    print("-" * 74)
    journal.section("controle_3_ligne_de_vue")
    print("CONTROLE 3 — LIGNE DE VUE (regle du moteur : cull_back)")
    print("-" * 74)
    if args.manifeste is None:
        print("NON VERIFIE — aucun manifeste fourni (--manifeste)")
        resultat["ligne_de_vue"] = "NON VERIFIE"
    elif not os.path.isfile(args.manifeste):
        print("BLOQUE: manifeste introuvable : %s" % args.manifeste)
        return 3
    else:
        manifeste = json.load(open(args.manifeste, "r", encoding="utf-8"))
        taille = manifeste.get("size", "1280x720").split("x")
        taille = (int(taille[0]), int(taille[1]))
        prises = [dict(p, taille=taille) for p in manifeste.get("shots", [])]

        # -- LA POSE, EPROUVEE PAR UNE MESURE QUI POUVAIT LA CONTREDIRE ----
        #
        # La tentative precedente superposait une silhouette calculee a la
        # capture et comparait des luminances. Elle a echoue parce que le
        # fond est aussi sombre que la formation, et decaler l'origine de
        # +3 m AMELIORAIT le score : la mesure elle-meme etait plate.
        #
        # Ce controle-ci n'a besoin d'aucune image. Il pose une question
        # geometrique dont la reponse est piquee : le rayon central d'une
        # camera d'approche, transformee en repere modele, PENETRE-T-IL la
        # galerie ? Si la pose est juste, il entre par la bouche et parcourt
        # plusieurs metres de vide. Si elle est fausse de deux metres, il
        # heurte la coque du dehors ou manque le rocher.
        #
        # Le balayage de sensibilite est ce qui en fait une preuve et non
        # une coincidence : la penetration doit s'EFFONDRER de part et
        # d'autre. Un plateau plat signifierait que la mesure ne distingue
        # rien — exactement le defaut d'hier — et le controle le dirait.
        print("POSE — penetration du rayon central dans la galerie")
        base = [dict(nom=p["name"],
                     profondeur=_penetration(grille, profil, pose, p))
                for p in prises]
        for b in base:
            print("   %-26s %s" % (b["nom"], _dire_penetration(b["profondeur"])))
        reference = max((b["profondeur"] or 0.0) for b in base)

        # LE BALAYAGE SE FAIT DANS LE REPERE DE LA GALERIE, PAS DANS CELUI
        # DU MONDE. C'est une correction de methode, et elle a une raison
        # mesurable : avec un lacet de 45 deg, un decalage en z monde se
        # projette pour moitie SUR L'AXE de la galerie — or un decalage
        # axial ne sort pas le rayon du tunnel, donc la penetration ne
        # bouge presque pas. Mesure du premier jet, en axes monde :
        # dz +2 m rendait encore 5,7 m de penetration, et le maximum
        # tombait a dz +1 m. On aurait conclu « mesure plate » alors que
        # la mesure est simplement AVEUGLE sur cet axe-la, par
        # construction.
        #
        # Les trois axes de la galerie n'ont donc pas le meme pouvoir de
        # resolution, et chacun est rapporte avec le sien :
        #   * TRANSVERSE — resolution ~ la demi-largeur de la bouche ;
        #   * VERTICAL   — resolution ~ la demi-hauteur de la bouche ;
        #   * AXIAL      — AUCUNE resolution, et c'est attendu : glisser
        #                  l'ouvrage le long de son propre axe laisse le
        #                  rayon dans le tunnel. On le mesure quand meme,
        #                  pour que l'angle mort soit ecrit et non tu.
        axial = pose.direction_vers_monde((0.0, 1.0, 0.0))
        transverse = pose.direction_vers_monde((1.0, 0.0, 0.0))
        vertical = (0.0, 1.0, 0.0)
        axes = (("transverse", transverse), ("vertical", vertical),
                ("axial", axial))
        balayage = []
        for nom_axe, vecteur in axes:
            for delta in (-3.0, -2.0, -1.0, -0.5, 0.5, 1.0, 2.0, 3.0):
                autre = pose.decalee(*[vecteur[k] * delta for k in range(3)])
                pire = max((_penetration(grille, profil, autre, p) or 0.0)
                           for p in prises)
                balayage.append(dict(axe=nom_axe, delta_m=delta,
                                     penetration_max_m=round(pire, 2)))
        print("   balayage dans le repere de la galerie (penetration max) :")
        for nom_axe, _ in axes:
            ligne = " ".join(
                "%+0.1f:%5.2f" % (b["delta_m"], b["penetration_max_m"])
                for b in balayage if b["axe"] == nom_axe)
            print("      %-11s %+0.1f:%5.2f  <<  %s"
                  % (nom_axe, 0.0, reference, ligne))

        # CE QUE LE BALAYAGE MESURE, ET CE QU'IL NE MESURE PAS.
        #
        # Il ne « valide » pas la pose : il mesure son POUVOIR DE
        # RESOLUTION, axe par axe, puis borne la pose dans cette
        # resolution. La difference n'est pas rhetorique — c'est ce qui
        # separe cette mesure de celle d'hier, qui rendait un score sans
        # jamais dire ce qu'un score de 52 % excluait.
        #
        # Resolution d'un axe := le plus petit decalage qui fait tomber la
        # penetration sous le quart de la reference. Au-dela, l'hypothese
        # est refutee ; en deca, elle ne l'est pas et on le dit.
        resolutions = {}
        for nom_axe, _ in axes:
            effondres = [abs(b["delta_m"]) for b in balayage
                         if b["axe"] == nom_axe
                         and b["penetration_max_m"] < 0.25 * reference]
            resolutions[nom_axe] = min(effondres) if effondres else None
        for nom_axe in ("transverse", "vertical", "axial"):
            r = resolutions[nom_axe]
            print("   resolution %-11s : %s"
                  % (nom_axe,
                     "un ecart de %+.1f m est REFUTE" % r if r is not None
                     else "AUCUNE — cet axe n'est pas contraint par cette "
                          "mesure"))
        # Le critere : la pose doit etre bornee sur les deux axes
        # transversal et vertical, et la penetration de reference doit etre
        # franche. L'axe axial est EXCLU du critere parce que la mesure n'y
        # a pas de pouvoir — l'y inclure serait exiger d'une regle qu'elle
        # pese. Il est rapporte comme angle mort, pas passe sous silence.
        pique = (reference > 2.0
                 and resolutions["transverse"] is not None
                 and resolutions["vertical"] is not None)
        etat_pose = "PASS" if pique else "PARTIAL"
        print("   %s — pose bornee a moins de %s m (transverse) et %s m "
              "(vertical) ; axe AXIAL non contraint."
              % (etat_pose,
                 resolutions["transverse"], resolutions["vertical"]))
        print("        La preuve FINE de la transformation n'est pas ici :")
        print("        c'est tools/probe_cave_selftest.py, ou un trou connu")
        print("        tombe dans la boite de pixels predite a 2 pixels pres.")
        resultat["pose"]["resolutions_m"] = resolutions
        resultat["pose"]["penetration_m"] = round(reference, 2)
        resultat["pose"]["balayage"] = balayage
        resultat["pose"]["verdict_penetration"] = etat_pose
        resultat["pose"]["axe_non_eprouve"] = "axial"

        lignes = []
        for prise in prises:
            traversants, percees = controle_ligne_de_vue(
                grille, prise, pose.origine, pose.lacet_deg, args.pas_pixel,
                profil)
            boites = grouper_pixels(percees, args.pas_pixel)
            # Un pixel percant isole est un rayon SUSPECT, comme ailleurs.
            # La confirmation applique la meme definition : le pixel doit
            # porter un carre de `ouverture` integralement perce.
            conf_px = []
            camera_modele = pose.vers_modele(prise["from"])
            for b in boites:
                cx = (b["x0"] + b["x1"]) / 2.0
                cy = (b["y0"] + b["y1"]) / 2.0
                direction = _rayon_pixel(prise, pose, cx, cy)
                liste = impacts(grille, camera_modele, direction)
                if not liste:
                    continue
                dedans = tuple(camera_modele[k] + direction[k]
                               * (liste[0][0] + 0.30) for k in range(3))
                cote, sortants, total, _ = mesurer_ouverture(
                    grille, dedans, direction, profil)
                if cote >= args.ouverture - 1e-9:
                    conf_px.append(dict(boite=b, ouverture_m=round(cote, 4)))
            etat = "PASS" if not conf_px else "FAIL"
            print("   %-26s %5d pixel(s) sur la formation, %4d suspect(s), "
                  "%d confirmee(s)  %s"
                  % (prise["name"], traversants, len(percees), len(conf_px),
                     etat))
            for b in boites[:6]:
                print("        boite x[%4d..%4d] y[%4d..%4d]  %d pixel(s)"
                      % (b["x0"], b["x1"], b["y0"], b["y1"], b["pixels"]))
            if traversants == 0:
                print("        ATTENTION: aucun pixel ne touche la formation "
                      "— ce resultat ne prouve rien")
            lignes.append(dict(nom=prise["name"], pixels_formation=traversants,
                               pixels_suspects=len(percees),
                               percees_confirmees=conf_px, boites=boites))
            for c in conf_px:
                confirmees_totales.append(dict(c, surface="ligne_de_vue",
                                               origine="controle_3"))
        resultat["ligne_de_vue"] = lignes

    resultat["percees_confirmees_total"] = len(confirmees_totales)
    resultat["percees_confirmees"] = confirmees_totales

    print()
    print("=" * 74)
    journal.section("gate")
    print("GATE — 0 PERCEE CONFIRMEE")
    print("=" * 74)
    print("percees confirmees : %d  (seuil d'ouverture %.2f m)"
          % (len(confirmees_totales), args.ouverture))
    for c in confirmees_totales:
        print("   %-12s surface %-14s ouverture %.3f m"
              % (c.get("origine", "?"), c.get("surface", "?"),
                 c.get("ouverture_m", 0.0)))

    ## LE CONTRÔLE QUI REND LE MENSONGE MÉCANIQUEMENT IMPOSSIBLE.
    ##
    ## Rebalaye le journal ENTIER, à la recherche d'un acquittement
    ## coexistant avec un marqueur de défaut. C'est la faute exacte de la
    ## passe précédente — « PASS — un sol existe sous chaque point sonde »
    ## imprimé trente lignes sous une carte pleine de « <-- TROU » —
    ## transformée en défaut détecté plutôt qu'en règle de lecture.
    incoherences = journal.incoherences()
    resultat["journal"] = dict(
        lignes=len(journal.lignes),
        marqueurs_defaut=len(journal.defauts_vus()),
        acquits_refuses=journal.acquits_refuses,
        incoherences=[[s, a.strip(), d.strip()] for s, a, d in incoherences])
    if incoherences:
        print()
        print("INCOHERENCE DE JOURNAL — %d acquittement(s) coexistent, DANS "
              "LEUR SECTION, avec un marqueur de defaut :" % len(incoherences))
        for section, acquit, defaut in incoherences[:5]:
            print("   section: %s" % section)
            print("   acquit : %s" % acquit.strip())
            print("   defaut : %s" % defaut.strip())
        print("   Ce n'est pas un defaut de la geometrie, c'est un defaut du")
        print("   JOURNAL — et il compte comme un echec, sinon il reviendrait.")
    if journal.acquits_refuses:
        print("acquittements refuses par le journal : %d"
              % len(journal.acquits_refuses))

    echoue = rouge or bool(confirmees_totales) or bool(incoherences)
    if confirmees_totales:
        raison = "%d percee(s) confirmee(s)" % len(confirmees_totales)
    elif rouge:
        raison = "defaut de plancher ou de fond mesure"
    elif incoherences:
        raison = "journal incoherent (%d acquittement(s) sur defaut)" % len(
            incoherences)
    else:
        raison = ""
    print("VERDICT : %s" % ("FAIL — %s" % raison if echoue else "PASS"))
    print("=" * 74)
    rouge = echoue

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
