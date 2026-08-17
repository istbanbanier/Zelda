#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""MASQUE DE BOUCHE CANONIQUE — `docs/ADDENDUM_MASQUE_BOUCHE.md` §2, execute.

CE QUE CE MODULE REMPLACE, ET POURQUOI
======================================
`tools/cave_check_hull.py` §2.5 ecarte un voisinage GEODESIQUE du contour de
bouche, mesure SUR la peau interieure. C'etait honnete faute de mieux — le
contrat §2.5 disait « la bouche masquee » sans donner d'emprise — mais un
rayon geodesique n'est pas un lieu : il epouse la peau, donc il s'allonge
quand la peau se deforme, et deux geometries n'ont pas la meme emprise pour
la meme valeur. L'addendum le remplace par un VOLUME defini sur le CHEMIN,
independant de la surface mesuree.

Et le masque ne retranche plus rien : il CLASSE. Voir §3 de l'addendum.

L'ABSCISSE EST UNE LONGUEUR, JAMAIS UN INDICE DE STATION
========================================================
`u` dans `station_de_cavite(u)` est un indice de station eventuellement
fractionnaire. Les tables `CAVITE` de R2a-3.4 et de R2a-3.5.x n'ont PAS les
memes stations : `u = 2` vaut `ay = 1,60` dans l'une et `ay = 1,05` dans
l'autre. Toute emprise s'exprime donc en `s`, longueur d'arc en metres
depuis la station « seuil » (`ay = 0`), identique dans les deux revisions et
donc origine commune. `s` est negatif vers l'exterieur. (Addendum §2.3.)

LES TABLES SONT LUES, JAMAIS RECOPIEES
======================================
Une constante recopiee diverge en silence — c'est le ticket 1 de l'addendum,
`Y_BOUCHE_DEFAUT = -1,15` recopie dans cinq outils. On lit donc le texte du
generateur et on en extrait les affectations LITTERALES par `ast`, sans
executer le fichier (il importe `bpy`, absent d'un conteneur sans Blender).
La provenance — chemin ou objet git — est publiee avec les valeurs.

L'EXTRAPOLATION AU-DELA DU PORCHE, ET ELLE EST NECESSAIRE
=========================================================
`MODELE_SEUIL_DEHORS` vaut `ay = -1,60`, quand la premiere station de
`CAVITE` (la levre du porche) est a `ay = -1,15`. Le repere de gameplay est
donc 0,45 m DEVANT le debut du chemin tabule. `station_de_cavite()` clampe
`u` et ne saurait pas y aller. On prolonge donc le chemin par la TANGENTE de
son premier segment, ce que l'addendum §2.4 decrit exactement : « le porche
etant rectiligne en ax = 0 », `s_dehors` vaut alors -1,60 par construction.
Cette extrapolation est publiee, pas silencieuse.

USAGE
=====
    python3 tools/cave_masque_bouche.py <fichier.glb> [options]
      --generateur=<chemin>   source des tables (defaut : celle de l'arbre)
      --git=<objet>           lit les tables par `git show <objet>`
      --capsule               section a la capsule reelle 0,35 / 1,80
      --pas=0.05              pas du balayage de recherche de `s_enclos`
      --fin=3.00              `s` maximum explore
      --json=<chemin>         ecrit le resultat en JSON

Codes retour : 0 mesure faite · 3 BLOQUE.
"""

import ast
import hashlib
import json
import math
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cave_check_mesh as M  # noqa: E402

# Contour de section : 72 rayons, pas de 5 degres (addendum §2.5).
RAYONS_SECTION = 72
# Confirmation de l'enclos, en metres le long du chemin (addendum §2.5).
CONFIRMATION_M = 0.25
# Pas de balayage du volume et raffinement aux extremites (addendum §2.6).
PAS_BALAYAGE_M = 0.06
PAS_EXTREMITE_M = 0.005

# Capsule reelle de `scenes/player/Player.tscn`, publiee EN REGARD du
# gabarit contractuel. Addendum §2.2 : si les deux ne rendent pas le meme
# verdict, le resultat est BLOQUE.
CAPSULE_DEMI_LARGEUR_M = 0.35
CAPSULE_CLE_M = 1.80

NOMS_TABLES = ("CAVITE", "CAVITE_ASYM", "PALIER", "SAG", "PORCHE_DENIVELE",
               "GABARIT_DEMI_LARGEUR_M", "GABARIT_CLE_M")


def empreinte(chemin):
    h = hashlib.sha256()
    with open(chemin, "rb") as f:
        for bloc in iter(lambda: f.read(1 << 20), b""):
            h.update(bloc)
    return h.hexdigest()


# ==========================================================================
# Lecture des tables — par `ast`, sans executer le generateur
# ==========================================================================

def charger_tables(texte, origine):
    """Extrait les affectations litterales du generateur.

    On analyse l'arbre syntaxique et on ne retient que les affectations dont
    le membre droit est un LITTERAL. Aucune ligne du generateur n'est
    executee : il importe `bpy`, et surtout un instrument qui executerait le
    code qu'il mesure partagerait son coeur avec lui.
    """
    arbre = ast.parse(texte)
    trouve = {}
    for noeud in arbre.body:
        if not isinstance(noeud, ast.Assign):
            continue
        for cible in noeud.targets:
            if not isinstance(cible, ast.Name) or cible.id not in NOMS_TABLES:
                continue
            try:
                trouve[cible.id] = ast.literal_eval(noeud.value)
            except ValueError:
                pass
    manquants = [n for n in NOMS_TABLES if n not in trouve]
    if manquants:
        raise ValueError("tables absentes de %s : %s"
                         % (origine, ", ".join(manquants)))
    trouve["_origine"] = origine
    return trouve


def lire_repere_lieu(texte, nom):
    """Lit une constante `Vector3` du script de lieu, en repere MODELE.

    Meme discipline que pour les tables : on LIT, on ne recopie pas. Le
    script declare en repere Godot ; on convertit une fois, ici, avec la
    conversion du socle : ax = gx ; ay = -gz ; az = gy.
    """
    for ligne in texte.splitlines():
        if ligne.strip().startswith("const %s" % nom) and "Vector3(" in ligne:
            brut = ligne.split("Vector3(", 1)[1].split(")", 1)[0]
            gx, gy, gz = (float(v) for v in brut.split(","))
            return (gx, -gz, gy), (gx, gy, gz)
    raise ValueError("constante %s absente du script de lieu" % nom)


def texte_depuis_git(objet, racine):
    pr = subprocess.run(["git", "show", objet], capture_output=True,
                        text=True, cwd=racine)
    if pr.returncode != 0:
        raise ValueError("git show %s : %s" % (objet, pr.stderr.strip()))
    return pr.stdout


def tables_depuis_git(objet, racine):
    """Lit les tables d'une revision par `git show <objet>`.

    Sert au chemin CANONIQUE R2a-3.4, dont la table `CAVITE` n'est plus dans
    l'arbre de travail : `s_enclos` canonique se calcule sur SA geometrie ET
    SON chemin, jamais sur celui d'une revision ulterieure.
    """
    pr = subprocess.run(["git", "show", objet], capture_output=True,
                        text=True, cwd=racine)
    if pr.returncode != 0:
        raise ValueError("git show %s : %s" % (objet, pr.stderr.strip()))
    return charger_tables(pr.stdout, "git:%s" % objet)


# ==========================================================================
# Le chemin — polyligne des stations, abscisse curviligne en METRES
# ==========================================================================

class Chemin(object):
    """Chemin canonique de la cavite, parametre par la LONGUEUR D'ARC.

    L'origine `s = 0` est la station « seuil » (`ay = 0`), identique dans
    toutes les revisions et donc seule origine commune legitime.
    """

    # Indice de la station « seuil » dans `CAVITE`. Verifie a la
    # construction : c'est la station d'ordonnee nulle, pas un rang suppose.
    def __init__(self, tables):
        self.t = tables
        self.cavite = tables["CAVITE"]
        self.asym = tables["CAVITE_ASYM"]
        self.palier = tables["PALIER"]
        self.sag = tables["SAG"]
        self.denivele = tables["PORCHE_DENIVELE"]
        seuils = [i for i, st in enumerate(self.cavite) if abs(st[1]) < 1e-9]
        if len(seuils) != 1:
            raise ValueError("station « seuil » (ay = 0) non unique : %s"
                             % seuils)
        self.i_seuil = seuils[0]
        # Longueur cumulee depuis la station 0, dans le plan (ax, ay).
        self.cum = [0.0]
        for i in range(1, len(self.cavite)):
            a, b = self.cavite[i - 1], self.cavite[i]
            self.cum.append(self.cum[-1]
                            + math.hypot(b[0] - a[0], b[1] - a[1]))
        self.s0 = self.cum[self.i_seuil]      # decalage d'origine

    # -- conversions -------------------------------------------------------

    def s_de_u(self, u):
        """Longueur d'arc a l'indice de station `u`, origine au seuil.

        Extrapole lineairement hors du domaine tabule : le premier segment
        est prolonge vers l'exterieur (addendum §2.4), le dernier vers le
        fond. Sans cela `MODELE_SEUIL_DEHORS`, qui vit 0,45 m devant la
        levre du porche, n'aurait pas d'abscisse.
        """
        n = len(self.cavite)
        if u <= 0.0:
            pas = self.cum[1] - self.cum[0]
            return self.cum[0] + u * pas - self.s0
        if u >= n - 1:
            pas = self.cum[n - 1] - self.cum[n - 2]
            return self.cum[n - 1] + (u - (n - 1)) * pas - self.s0
        i = int(math.floor(u))
        t = u - i
        return self.cum[i] + t * (self.cum[i + 1] - self.cum[i]) - self.s0

    def u_de_s(self, s):
        """Indice de station a la longueur d'arc `s`. Reciproque exacte."""
        cible = s + self.s0
        n = len(self.cavite)
        if cible <= self.cum[0]:
            pas = self.cum[1] - self.cum[0]
            return (cible - self.cum[0]) / pas if pas > 0 else 0.0
        if cible >= self.cum[n - 1]:
            pas = self.cum[n - 1] - self.cum[n - 2]
            return (n - 1) + ((cible - self.cum[n - 1]) / pas
                              if pas > 0 else 0.0)
        for i in range(n - 1):
            if self.cum[i] <= cible <= self.cum[i + 1]:
                d = self.cum[i + 1] - self.cum[i]
                return i + ((cible - self.cum[i]) / d if d > 0 else 0.0)
        return float(n - 1)

    def projeter(self, point):
        """Abscisse `s` du projete de `point` sur le chemin, dans le plan
        (ax, ay).

        Le chemin est PROLONGE par ses segments extremes : sans cela
        `MODELE_SEUIL_DEHORS`, qui vit 0,45 m devant la levre du porche,
        n'aurait pas de projete. On balaie tous les segments et on retient
        le plus proche ; les deux segments extremes acceptent un parametre
        hors de [0 ; 1], les autres non.
        """
        px, py = point[0], point[1]
        n = len(self.cavite)
        meilleur = None
        for i in range(n - 1):
            a, b = self.cavite[i], self.cavite[i + 1]
            vx, vy = b[0] - a[0], b[1] - a[1]
            L2 = vx * vx + vy * vy
            if L2 < 1e-18:
                continue
            t = ((px - a[0]) * vx + (py - a[1]) * vy) / L2
            if i == 0:
                t = min(1.0, t)          # prolonge vers l'exterieur
            elif i == n - 2:
                t = max(0.0, t)          # prolonge vers le fond
            else:
                t = max(0.0, min(1.0, t))
            qx, qy = a[0] + t * vx, a[1] + t * vy
            d = math.hypot(px - qx, py - qy)
            if meilleur is None or d < meilleur[0]:
                meilleur = (d, self.s_de_u(i + t), i + t)
        return meilleur           # (distance a l'axe, s, u)

    # -- geometrie ---------------------------------------------------------

    def station(self, u):
        """(ax, ay, hw, cle) — meme interpolation que `station_de_cavite`,
        prolongee lineairement hors domaine pour la POSITION seulement."""
        n = len(self.cavite)
        if u < 0.0:
            a, b = self.cavite[0], self.cavite[1]
            return (a[0] + u * (b[0] - a[0]), a[1] + u * (b[1] - a[1]),
                    a[2], a[3])
        if u > n - 1:
            a, b = self.cavite[n - 2], self.cavite[n - 1]
            t = u - (n - 1)
            return (b[0] + t * (b[0] - a[0]), b[1] + t * (b[1] - a[1]),
                    b[2], b[3])
        i = max(0, min(n - 1, int(math.floor(u))))
        j = min(n - 1, i + 1)
        t = max(0.0, min(1.0, u - i))
        a, b = self.cavite[i], self.cavite[j]
        return tuple(a[k] * (1.0 - t) + b[k] * t for k in range(4))

    def normale(self, u):
        """Axe LATERAL de la section — jamais l'axe X.

        Copie fidele de `normale_de_cavite()` : `n = (ty, -tx)`. Le
        generateur documente lui-meme que decaler le long de X devient faux
        des que la galerie s'inflechit ; entre les stations 7 et 8 la
        normale est a 45 degres de X.
        """
        eps = 0.02
        a = self.station(u - eps)
        b = self.station(u + eps)
        tx, ty = b[0] - a[0], b[1] - a[1]
        n = math.hypot(tx, ty)
        if n < 1e-9:
            return (1.0, 0.0)
        return (ty / n, -tx / n)

    def facteurs_asym(self, u):
        """(gauche, droite, inclinaison) — clampe hors domaine, comme le
        generateur, qui indexe `CAVITE_ASYM` par station entiere clampee."""
        n = len(self.asym)
        i = max(0, min(n - 1, int(math.floor(u))))
        j = min(n - 1, i + 1)
        t = max(0.0, min(1.0, u - i))
        return tuple(self.asym[i][k] * (1.0 - t) + self.asym[j][k] * t
                     for k in range(3))

    def sol(self, u, lateral=0.0, denivele_fige=False):
        """Altitude du sol — copie fidele de `sol_de_cavite()`.

        `denivele_fige` gele le terme de porche a sa valeur en `u = 0` au
        lieu de le laisser croitre vers l'exterieur. La fonction du
        generateur ne clampe PAS ce terme ; la variante existe donc pour
        MESURER la sensibilite de la classification a ce point que
        l'addendum ne tranche pas, jamais pour le trancher ici.
        """
        n = len(self.palier)
        i = max(0, min(n - 1, int(math.floor(u))))
        j = min(n - 1, i + 1)
        t = max(0.0, min(1.0, u - i))
        palier = self.palier[i] * (1.0 - t) + self.palier[j] * t
        uu = max(0.0, u) if denivele_fige else u
        den = self.denivele * max(0.0, 1.0 - uu)
        return palier - self.sag * (1.0 - min(1.0, abs(lateral))) + den


# ==========================================================================
# La section balayee — gabarit contractuel, asymetrie appliquee
# ==========================================================================

class Gabarit(object):
    """Section de mesure : demi-largeur et cle, avec `CAVITE_ASYM`.

    Transposition litterale d'`anneau_interieur()` : la demi-largeur y vaut
    `hw * (gauche si u < 0 sinon droite)` avec `u = cos(azimut)`, et la cle
    y est multipliee par `biais = 1 + inclinaison * u`. Ici `hw` et `cle`
    sont remplacees par les deux constantes GELEES du gabarit de passage,
    et `u` devient la coordonnee laterale normalisee du contour — c'est la
    meme grandeur, nommee autrement.
    """

    def __init__(self, demi_largeur, cle, asym=True, linteau=True):
        self.dl = demi_largeur
        self.cle = cle
        self.asym = asym
        self.linteau = linteau

    def contour(self, chemin, s, n_pts=RAYONS_SECTION, denivele_fige=False):
        """Contour ferme de la section a l'abscisse `s`, en 3D modele.

        Le contour est le RECTANGLE du gabarit : sol en bas, cle en haut,
        demi-largeurs asymetriques a gauche et a droite. Il est echantillonne
        a `n_pts` azimuts reguliers depuis le centre de section, de sorte que
        le meme parametrage serve au balayage du volume et aux 72 rayons de
        l'enclos.
        """
        u = chemin.u_de_s(s)
        ax, ay, _hw, _cle = chemin.station(u)
        nx, ny = chemin.normale(u)
        g, d, incl = chemin.facteurs_asym(u)
        if not self.asym:
            g = d = 1.0
            incl = 0.0
        if not self.linteau:
            incl = 0.0
        z_sol = chemin.sol(u, 0.0, denivele_fige)
        demi_g = self.dl * g
        demi_d = self.dl * d
        # Centre de section : a mi-hauteur du gabarit, sur l'axe du chemin.
        cz = z_sol + 0.5 * self.cle
        pts = []
        for k in range(n_pts):
            th = 2.0 * math.pi * k / n_pts
            cu, cv = math.cos(th), math.sin(th)
            demi = demi_g if cu < 0.0 else demi_d
            # Hauteur disponible dans la direction visee, linteau incline.
            haut = 0.5 * self.cle * (1.0 + incl * cu)
            bas = 0.5 * self.cle
            # Intersection du rayon (cu, cv) avec le rectangle asymetrique.
            tl = abs(demi / cu) if abs(cu) > 1e-12 else float("inf")
            lim_v = haut if cv >= 0.0 else bas
            tv = abs(lim_v / cv) if abs(cv) > 1e-12 else float("inf")
            t = min(tl, tv)
            lat = t * cu
            vert = t * cv
            pts.append((ax + lat * nx, ay + lat * ny, cz + vert))
        return pts, (ax, ay, cz), (nx, ny)


# ==========================================================================
# Le volume MASQUE — maillage ferme, balaye entre deux abscisses
# ==========================================================================

def abscisses_balayage(s0, s1, pas=PAS_BALAYAGE_M, fin=PAS_EXTREMITE_M):
    """Abscisses du balayage : pas <= 0,06 m, raffine a 0,005 m aux bouts.

    Addendum §2.6. Le raffinement sert les deux extremites, ou la
    classification bascule et ou une marche de 6 cm se verrait.
    """
    vals = [s0]
    bord = min(0.10, 0.25 * (s1 - s0))
    s = s0
    while s < s1 - 1e-12:
        pres_du_bord = (s - s0) < bord or (s1 - s) < bord
        p = fin if pres_du_bord else pas
        s = min(s1, s + p)
        vals.append(s)
    return vals


def maillage_masque(chemin, gabarit, s0, s1, n_pts=RAYONS_SECTION,
                    denivele_fige=False):
    """Maillage FERME du volume masque : anneaux balayes + deux bouchons."""
    ss = abscisses_balayage(s0, s1)
    anneaux = [gabarit.contour(chemin, s, n_pts, denivele_fige)[0]
               for s in ss]
    positions = []
    for an in anneaux:
        positions.extend(an)
    faces = []
    for i in range(len(anneaux) - 1):
        b0 = i * n_pts
        b1 = (i + 1) * n_pts
        for k in range(n_pts):
            k2 = (k + 1) % n_pts
            faces.append((b0 + k, b0 + k2, b1 + k2))
            faces.append((b0 + k, b1 + k2, b1 + k))
    # Bouchons : un sommet central par extremite.
    for idx, (an, sens) in enumerate(((anneaux[0], -1),
                                      (anneaux[-1], +1))):
        c = tuple(sum(p[k] for p in an) / len(an) for k in range(3))
        positions.append(c)
        ic = len(positions) - 1
        base = 0 if idx == 0 else (len(anneaux) - 1) * n_pts
        for k in range(n_pts):
            k2 = (k + 1) % n_pts
            if sens < 0:
                faces.append((ic, base + k2, base + k))
            else:
                faces.append((ic, base + k, base + k2))
    return positions, faces, ss


# ==========================================================================
# §2.5 — « la premiere section entierement enfermee »
# ==========================================================================

def _impact(o, d, a, b, c):
    """Moller-Trumbore. Rend la distance le long de `d`, ou None."""
    e1 = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
    e2 = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
    p = (d[1] * e2[2] - d[2] * e2[1], d[2] * e2[0] - d[0] * e2[2],
         d[0] * e2[1] - d[1] * e2[0])
    det = e1[0] * p[0] + e1[1] * p[1] + e1[2] * p[2]
    if abs(det) < 1e-12:
        return None
    inv = 1.0 / det
    t = (o[0] - a[0], o[1] - a[1], o[2] - a[2])
    u = (t[0] * p[0] + t[1] * p[1] + t[2] * p[2]) * inv
    if u < 0.0 or u > 1.0:
        return None
    q = (t[1] * e1[2] - t[2] * e1[1], t[2] * e1[0] - t[0] * e1[2],
         t[0] * e1[1] - t[1] * e1[0])
    v = (d[0] * q[0] + d[1] * q[1] + d[2] * q[2]) * inv
    if v < 0.0 or u + v > 1.0:
        return None
    s = (e2[0] * q[0] + e2[1] * q[1] + e2[2] * q[2]) * inv
    return s if s > 1e-7 else None


def faces_du_plan(positions, faces, origine, normale):
    """Faces traversant le plan (`origine`, `normale`).

    PREFILTRE, et il est ce qui rend la mesure faisable. Les 72 rayons
    restent DANS le plan de section : seules les faces qui le coupent
    peuvent les arreter. On passe de ~20 000 faces a quelques centaines.
    """
    nx, ny, nz = normale
    d0 = origine[0] * nx + origine[1] * ny + origine[2] * nz
    gardees = []
    for fi, (a, b, c) in enumerate(faces):
        sa = (positions[a][0] * nx + positions[a][1] * ny
              + positions[a][2] * nz) - d0
        sb = (positions[b][0] * nx + positions[b][1] * ny
              + positions[b][2] * nz) - d0
        sc = (positions[c][0] * nx + positions[c][1] * ny
              + positions[c][2] * nz) - d0
        if (sa > 0.0) == (sb > 0.0) == (sc > 0.0):
            continue
        gardees.append(fi)
    return gardees


def section_enfermee(positions, faces, chemin, gabarit, s, diag,
                     denivele_fige=False):
    """La section a l'abscisse `s` est-elle ENTIEREMENT ENFERMEE ?

    Addendum §2.5 : depuis le contour du gabarit, 72 rayons repartis
    uniformement dans le plan de la section (pas de 5 degres) doivent TOUS
    rencontrer de la roche avant de sortir de la boite englobante.

    Rend (enfermee, nb_rayons_sortants, portees).
    """
    pts, centre, (nx, ny) = gabarit.contour(chemin, s, RAYONS_SECTION,
                                            denivele_fige)
    # Normale du plan de section = tangente du chemin.
    tang = (-ny, nx, 0.0)
    sous = faces_du_plan(positions, faces, centre, tang)
    sortants = 0
    portees = []
    for k, p in enumerate(pts):
        th = 2.0 * math.pi * k / RAYONS_SECTION
        cu, cv = math.cos(th), math.sin(th)
        d = (cu * nx, cu * ny, cv)
        o = (p[0] + d[0] * 1e-5, p[1] + d[1] * 1e-5, p[2] + d[2] * 1e-5)
        best = float("inf")
        for fi in sous:
            a, b, c = faces[fi]
            t = _impact(o, d, positions[a], positions[b], positions[c])
            if t is not None and t < best:
                best = t
        portees.append(best)
        if best > diag:
            sortants += 1
    return sortants == 0, sortants, portees


def balayer(positions, faces, chemin, gabarit, s_debut, s_fin, pas,
            denivele_fige=False):
    """Courbe COMPLETE du nombre de rayons sortants en fonction de `s`.

    ON PUBLIE LA COURBE ENTIERE, ET C'EST DELIBERE. L'addendum §2.5 definit
    `s_enclos` comme « le plus petit `s > s_dehors` » dont la section est
    enfermee. Mesure sur la geometrie canonique : cette lecture litterale
    rend `s = -1,50 m`, c'est-a-dire 10 cm apres `s_dehors` — parce que le
    gabarit extrapole sous le porche est ENTERRE (`PORCHE_DENIVELE = -0,58`
    non clampe, la levre plongeant volontairement sous le terrain), donc
    entoure de roche sans avoir rien traverse.

    L'addendum ne prevoit pas ce cas. On ne le tranche donc pas ici : on
    rend la courbe, et le lecteur voit exactement ou l'ouverture s'ouvre et
    ou elle se referme.
    """
    (x0, y0, z0), (x1, y1, z1) = M.boite(positions)
    diag = math.dist((x0, y0, z0), (x1, y1, z1))
    courbe = []
    s = s_debut
    while s <= s_fin + 1e-9:
        ok, sortants, portees = section_enfermee(positions, faces, chemin,
                                                 gabarit, s, diag,
                                                 denivele_fige)
        finis = sorted(p for p in portees if p != float("inf"))
        stat = (finis[0], finis[len(finis) // 2], finis[-1]) if finis \
            else (float("inf"),) * 3
        courbe.append((round(s, 6), sortants, ok, stat))
        s += pas
    return courbe


def enclos_litteral(courbe, pas):
    """Lecture A — la lettre de l'addendum §2.5.

    Plus petit `s` enferme, confirme a `s + 0,25 m`. Aucune interpretation.
    """
    saut = int(round(CONFIRMATION_M / pas))
    for k, ligne in enumerate(courbe):
        s, ok = ligne[0], ligne[2]
        if not ok:
            continue
        j = k + saut
        if j < len(courbe) and courbe[j][2]:
            return s
    return None


def enclos_apres_ouverture(courbe, pas):
    """Lecture B — l'intention : la roche se REFERME sur la galerie.

    Premier `s` enferme et confirme qui suit au moins une section NON
    enfermee. Traduit « on sort par la bouche, puis la roche se referme »,
    et ignore l'enfermement initial du gabarit enterre sous le porche.
    """
    saut = int(round(CONFIRMATION_M / pas))
    vu_ouvert = False
    for k, ligne in enumerate(courbe):
        s, ok = ligne[0], ligne[2]
        if not ok:
            vu_ouvert = True
            continue
        if not vu_ouvert:
            continue
        j = k + saut
        if j < len(courbe) and courbe[j][2]:
            return s
    return None


# ==========================================================================
# Pilote
# ==========================================================================

def opt(argv, nom, defaut):
    for a in argv:
        if a.startswith("--%s=" % nom):
            return a.split("=", 1)[1]
    return defaut


def racine_git(depart):
    pr = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                        capture_output=True, text=True, cwd=depart)
    return pr.stdout.strip() if pr.returncode == 0 else depart


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    if not args:
        print(__doc__)
        return 3
    glb = args[0]
    ici = os.path.dirname(os.path.abspath(__file__))
    racine = racine_git(ici)
    gen = opt(argv, "generateur",
              os.path.join(racine, "source_assets", "blender", "environment",
                           "make_waterfall_cave.py"))
    objet_git = opt(argv, "git", None)
    pas = float(opt(argv, "pas", "0.05"))
    fin = float(opt(argv, "fin", "3.00"))
    capsule = "--capsule" in argv
    sortie_json = opt(argv, "json", None)

    print("=" * 76)
    print("MASQUE DE BOUCHE — addendum §2, execute")
    print("=" * 76)
    print("GLB     : %s" % glb)
    print("sha256  : %s   <- lu AVANT toute mesure" % empreinte(glb))
    if objet_git:
        tables = tables_depuis_git(objet_git, racine)
    else:
        with open(gen, "r", encoding="utf-8") as f:
            tables = charger_tables(f.read(), gen)
    print("tables  : %s" % tables["_origine"])
    print()

    chemin = Chemin(tables)
    print("--- le chemin, et son origine d'abscisse ---")
    print("  station « seuil » : indice %d, ay = %.3f  (ay = 0 par definition)"
          % (chemin.i_seuil, chemin.cavite[chemin.i_seuil][1]))
    print("  %-4s %-9s %-9s %-9s %s" % ("u", "ax", "ay", "s (m)", "note"))
    for i, st in enumerate(chemin.cavite):
        print("  %-4d %-9.3f %-9.3f %-9.3f %s"
              % (i, st[0], st[1], chemin.s_de_u(float(i)),
                 "<- seuil, s = 0" if i == chemin.i_seuil else ""))
    print()

    dl = CAPSULE_DEMI_LARGEUR_M if capsule else tables[
        "GABARIT_DEMI_LARGEUR_M"]
    cle = CAPSULE_CLE_M if capsule else tables["GABARIT_CLE_M"]
    print("--- la section ---")
    print("  %s : demi-largeur %.3f m, cle %.3f m"
          % ("CAPSULE REELLE (Player.tscn)" if capsule
             else "GABARIT CONTRACTUEL", dl, cle))
    print("  asymetrie CAVITE_ASYM appliquee (gauche/droite/linteau)")
    gab = Gabarit(dl, cle)

    # s_dehors : projection de MODELE_SEUIL_DEHORS, MESUREE, pas recopiee.
    lieu = opt(argv, "lieu", os.path.join(
        racine, "scripts", "world_v2", "poi", "waterfall_cave_place.gd"))
    objet_lieu = opt(argv, "git-lieu", None)
    if objet_lieu:
        txt_lieu = texte_depuis_git(objet_lieu, racine)
        org_lieu = "git:%s" % objet_lieu
    else:
        with open(lieu, "r", encoding="utf-8") as f:
            txt_lieu = f.read()
        org_lieu = lieu
    seuil_mod, seuil_godot = lire_repere_lieu(txt_lieu, "MODELE_SEUIL_DEHORS")
    d_axe, s_dehors, u_deh = chemin.projeter(seuil_mod)
    print()
    print("--- §2.4 extremite exterieure ---")
    print("  script de lieu : %s" % org_lieu)
    print("  MODELE_SEUIL_DEHORS   Godot  (%.3f ; %.3f ; %.3f)" % seuil_godot)
    print("                        modele (%.3f ; %.3f ; %.3f)" % seuil_mod)
    print("  projete sur le chemin : u = %.4f, distance a l'axe %.4f m"
          % (u_deh, d_axe))
    print("  s_dehors = %.4f m   <- MESURE, pas recopie de l'addendum"
          % s_dehors)
    if u_deh < 0.0:
        print("  (u < 0 : le repere vit DEVANT la levre du porche ; le chemin")
        print("   est prolonge par la tangente de son premier segment, §2.4)")
    print()

    sommets, triangles = M.charger(glb, "SM_WaterfallCave", repere="modele")
    positions, faces, _st = M.souder(sommets, triangles)
    print("--- §2.5 recherche de `s_enclos` ---")
    print("  %d faces, %d sommets soudes" % (len(faces), len(positions)))
    print("  %d rayons par section, pas de %.1f degres, confirmation a +%.2f m"
          % (RAYONS_SECTION, 360.0 / RAYONS_SECTION, CONFIRMATION_M))
    fige = "--denivele-fige" in argv
    courbe = balayer(positions, faces, chemin, gab, s_dehors, fin, pas, fige)
    print("  sol du gabarit : %s"
          % ("denivele de porche FIGE a u = 0 (variante de sensibilite)"
             if fige else "denivele extrapole, fidele a `sol_de_cavite()`"))
    print()
    (bx0, by0, bz0), (bx1, by1, bz1) = M.boite(positions)
    print("  boite du modele : ax[%.2f %.2f] ay[%.2f %.2f] az[%.2f %.2f]"
          % (bx0, bx1, by0, by1, bz0, bz1))
    print()
    print("  LES PORTEES SONT PUBLIEES, et elles sont le vrai diagnostic :")
    print("  « rencontrer de la roche avant de sortir de la boite » est une")
    print("  condition FAIBLE — un rayon lateral finit toujours par frapper")
    print("  le massif d'en face. Une portee mediane de 0,5 m dit « paroi")
    print("  collee » ; une portee mediane de 6 m dit « salle », et la")
    print("  section n'est enfermee qu'au sens de la lettre.")
    print()
    print("  %-9s %-9s %-10s %-8s %-9s %-9s %s"
          % ("s (m)", "ay", "sortants", "enferme", "port.min", "port.med",
             "port.max"))
    for (s, sortants, ok, (pmin, pmed, pmax)) in courbe:
        u = chemin.u_de_s(s)
        print("  %-9.3f %-9.3f %-10d %-8s %-9.3f %-9.3f %.3f"
              % (s, chemin.station(u)[1], sortants, "OUI" if ok else "non",
                 pmin, pmed, pmax))
    print()

    s_a = enclos_litteral(courbe, pas)
    s_b = enclos_apres_ouverture(courbe, pas)
    print("--- les deux lectures de « la premiere section enfermee » ---")
    for etiq, val, expl in (
            ("A litterale", s_a, "plus petit s enferme, confirme a +0,25"),
            ("B apres ouverture", s_b, "premier s enferme SUIVANT une "
             "section ouverte")):
        if val is None:
            print("  %-18s : AUCUNE sur [%.2f ; %.2f]   (%s)"
                  % (etiq, s_dehors, fin, expl))
        else:
            print("  %-18s : s = %+.4f m, u = %+.4f, ay = %+.3f   (%s)"
                  % (etiq, val, chemin.u_de_s(val),
                     chemin.station(chemin.u_de_s(val))[1], expl))
    print()

    res = {
        "glb": glb, "sha256": empreinte(glb), "tables": tables["_origine"],
        "lieu": org_lieu, "denivele_fige": fige,
        "gabarit": {"demi_largeur": dl, "cle": cle, "capsule": capsule},
        "s_dehors": s_dehors, "pas": pas,
        "s_enclos_litteral": s_a, "s_enclos_apres_ouverture": s_b,
        "i_seuil": chemin.i_seuil,
        "courbe": [{"s": s, "sortants": n, "enferme": ok,
                    "portee_min": st[0], "portee_med": st[1],
                    "portee_max": st[2]}
                   for (s, n, ok, st) in courbe],
    }
    if sortie_json:
        with open(sortie_json, "w", encoding="utf-8") as f:
            json.dump(res, f, indent=1, ensure_ascii=False)
        print("  ecrit : %s" % sortie_json)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
