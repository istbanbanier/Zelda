# SOURCE DE GÉNÉRATION REPRODUCTIBLE — L'Arbre foudroyé, hero asset de la
# prairie aux mille fleurs (V2.3-A.R2B, agent B).
#
# POURQUOI CE FICHIER EXISTE. Deux passes procédurales rejetées par le
# lead : « deux modules DeadTree teintés en noir » puis « un empilement de
# blocs ». Un tronc n'est pas une pile de boîtes — c'est UNE surface
# continue dont les deux moitiés partagent la même souche. Ici l'arbre est
# un LOFT DE PROFILS FERMÉS (même méthode que make_village_wall.py) : la
# souche est un anneau unique, la fourche fait diverger deux lofts, la
# fente a de vraies JOUES (l'entonnoir du col descend entre les moitiés),
# la cicatrice est un RETRAIT du profil (la foudre a chassé l'écorce), et
# la couronne d'échardes de la moitié morte est DANS le maillage.
#
# QUATRE OBJETS, UN SEUL GLB :
#   * `SM_ThunderstruckTree_Bark`    — souche + deux moitiés + moignons +
#                                      échardes, écorce carbonisée ;
#   * `SM_ThunderstruckTree_Heart`   — le bois MIS À NU : coin de la fente,
#                                      ruban de cicatrice logé dans le
#                                      retrait, cœurs d'échardes, bouts de
#                                      moignons, cassures des branches ;
#   * `SM_ThunderstruckTree_BranchA` — branche arrachée au sol (cassure
#   * `SM_ThunderstruckTree_BranchB`   vers l'arbre), posées par le GLB.
#
# C'est le COUPLE écorce sombre / cœur pâle qui porte la lecture en
# niveaux de gris (rejet du lead : « en niveaux de gris il ne restait
# qu'une tache ») — le cœur est un objet séparé pour que sa valeur ne se
# dilue jamais dans celle de l'écorce.
#
# BUDGET VERROUILLÉ AVANT MODÉLISATION (arbitrage R2B) : ≤ 6 000
# triangles. LE GÉNÉRATEUR REFUSE D'ENREGISTRER si la hauteur totale sort
# de [10 ; 12] m ou si la base n'est pas à Z = 0 — ce sont les termes du
# plan approuvé, vérifiés ici et re-vérifiés par le filet moteur
# (test_world_v2_r2b_farm_tree.gd).
#
# Blender est Z-up ; l'export convertit en Y-up : Blender (x, y, z) devient
# Godot (x, z, -y). La moitié vivante penche vers +X (est), la morte vers
# -X (ouest) — mêmes orientations que la version procédurale qu'il
# remplace, pour que les caméras de captures_v23ar restent justes.
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/environment/make_thunderstruck_tree.py

import math
import os
import sys

import bmesh
import bpy

# ---------------------------------------------------------------------------
# Cotes du plan approuvé
# ---------------------------------------------------------------------------
SOUCHE_LARGEUR = 2.1        # au sol, lobes de contrefort compris
FOURCHE_Z = 2.2             # le tronc est UN jusqu'ici
VIVANT_SOMMET = 10.8        # moitié vivante
MORT_SOMMET = 5.4           # moitié morte, rompue net
HAUTEUR_MIN, HAUTEUR_MAX = 10.0, 12.0
BUDGET_TRIS = 6000
BASE_TOL = 0.005

ANNEAU_SOUCHE = 14
ANNEAU_MOITIE = 12

# La cicatrice : une bande de 0,45 rad qui DESCEND en spirale du départ de
# la fourche jusqu'au pied, sur la face de la moitié vivante.
CICATRICE_HAUT = 7.4
CICATRICE_BAS = 0.35
CICATRICE_DEMI_ANGLE = 0.42
CICATRICE_RETRAIT = 0.80    # rayon × 0,80 au droit de la bande
CICATRICE_TOURS_RAD = 3.4

# ---------------------------------------------------------------------------
# Matériaux — sRGB converti en linéaire. Les valeurs viennent du fichier
# de lieu rejeté (BARK 0,26/0,21/0,17 ; HEARTWOOD 0,84/0,74/0,55) : la
# palette avait été validée, c'est la GÉOMÉTRIE qui était condamnée.
# §1.6 : jamais de noir pur — l'écorce carbonisée reste une valeur sombre
# lisible, pas une silhouette bouchée.
# ---------------------------------------------------------------------------
MATERIAUX = {
    "MAT_Tree_CharredBark": (0.26, 0.21, 0.17, 0.96),
    "MAT_Tree_Heartwood": (0.84, 0.74, 0.55, 0.88),
}


def srgb_vers_lineaire(canal):
    if canal <= 0.04045:
        return canal / 12.92
    return ((canal + 0.055) / 1.055) ** 2.4


def materiau(nom):
    if nom in bpy.data.materials:
        return bpy.data.materials[nom]
    r, v, b, rugosite = MATERIAUX[nom]
    r, v, b = (srgb_vers_lineaire(c) for c in (r, v, b))
    mat = bpy.data.materials.new(nom)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (r, v, b, 1.0)
    bsdf.inputs["Roughness"].default_value = rugosite
    bsdf.inputs["Metallic"].default_value = 0.0
    return mat


def _graine(x):
    return math.sin(x * 12.9898) * 0.5


# ---------------------------------------------------------------------------
# La spirale de cicatrice — UNE définition, partagée par le retrait de
# l'écorce ET par le ruban de cœur : deux codes qui redérivent la même
# spirale finissent par diverger (tools/CLAUDE.md, « chercher les AUTRES
# endroits qui font la même mesure »).
# ---------------------------------------------------------------------------
def angle_cicatrice(z):
    t = (CICATRICE_HAUT - z) / (CICATRICE_HAUT - CICATRICE_BAS)
    return -0.55 + t * CICATRICE_TOURS_RAD


def dans_cicatrice(z, angle):
    if z > CICATRICE_HAUT or z < CICATRICE_BAS:
        return False
    ecart = (angle - angle_cicatrice(z) + math.pi) % (2.0 * math.pi) - math.pi
    return abs(ecart) < CICATRICE_DEMI_ANGLE


# ---------------------------------------------------------------------------
# Loft d'anneaux fermés
# ---------------------------------------------------------------------------
def anneau(centre, rayon, n, z, lobes=0.0, graine=0.0, aplati=None,
           applique_cicatrice=True):
    """Un anneau fermé : `lobes` module le rayon (contreforts de souche),
    `aplati` = (angle, force) écrase la face qui regarde la fente, et la
    bande de cicatrice CREUSE le profil — le retrait est dans l'écorce,
    pas plaqué dessus."""
    points = []
    for i in range(n):
        a = 2.0 * math.pi * i / n
        r = rayon * (1.0 + _graine(graine + i * 1.7) * 0.10)
        if lobes > 0.0:
            r *= 1.0 + lobes * max(0.0, math.sin(a * 3.0 + 0.7)) ** 2
        if aplati is not None:
            ecart = (a - aplati[0] + math.pi) % (2.0 * math.pi) - math.pi
            if abs(ecart) < 1.05:
                r *= 1.0 - aplati[1] * (1.0 - abs(ecart) / 1.05)
        if applique_cicatrice and dans_cicatrice(z, a):
            r *= CICATRICE_RETRAIT
        points.append((centre[0] + math.cos(a) * r,
                       centre[1] + math.sin(a) * r, z))
    return points


def loft(bm, anneaux, mat_idx=0, fermer_bas=False, fermer_haut=False):
    rangs = [[bm.verts.new(p) for p in a] for a in anneaux]
    faces = []
    for e in range(len(rangs) - 1):
        bas, haut = rangs[e], rangs[e + 1]
        n = len(bas)
        for i in range(n):
            j = (i + 1) % n
            faces.append(bm.faces.new((bas[i], bas[j], haut[j], haut[i])))
    if fermer_bas:
        faces.append(bm.faces.new(tuple(reversed(rangs[0]))))
    if fermer_haut:
        faces.append(bm.faces.new(tuple(rangs[-1])))
    for f in faces:
        f.material_index = mat_idx
    return rangs


# ---------------------------------------------------------------------------
# SM_ThunderstruckTree_Bark
# ---------------------------------------------------------------------------
def chemin_vivant(t):
    """Centre et rayon de la moitié vivante à t ∈ [0;1]."""
    return ((0.34 + t * 1.75, 0.05 + t * 0.28,
             FOURCHE_Z + t * (VIVANT_SOMMET - FOURCHE_Z)),
            0.50 - t * 0.34)


def chemin_mort(t):
    return ((-0.30 - t * 1.20, -0.04 - t * 0.20,
             FOURCHE_Z + t * (MORT_SOMMET - FOURCHE_Z)),
            0.46 - t * 0.15)


def ecorce(bm):
    # --- la souche : UN anneau, des lobes de contrefort qui s'estompent.
    souche = []
    for k, z in enumerate((0.0, 0.45, 1.05, 1.65, FOURCHE_Z)):
        t = z / FOURCHE_Z
        souche.append(anneau((0.0, 0.0), 0.86 - t * 0.22, ANNEAU_SOUCHE, z,
                             lobes=0.30 * (1.0 - t), graine=k * 3.3))
    rangs = loft(bm, souche, fermer_bas=True)

    # --- le col : l'entonnoir qui descend ENTRE les moitiés — les joues de
    # la fente. Le sommet de souche se referme vers un centre ABAISSÉ : vu
    # de l'extérieur, la paroi plonge dans le tronc, et le coin de cœur
    # (objet Heart) en tapisse le fond.
    haut = rangs[-1]
    col = bm.verts.new((0.0, 0.0, 1.58))
    for i in range(ANNEAU_SOUCHE):
        j = (i + 1) % ANNEAU_SOUCHE
        f = bm.faces.new((haut[j], haut[i], col))
        f.material_index = 0

    # --- moitié vivante : loft continu jusqu'à 10,8 m, face de fente
    # aplatie vers -X, cicatrice creusée dans le profil.
    vivant = []
    for k in range(10):
        t = k / 9.0
        centre, rayon = chemin_vivant(t)
        vivant.append(anneau(centre, rayon, ANNEAU_MOITIE, centre[2],
                             graine=40.0 + k * 2.1,
                             aplati=(math.pi, 0.30 * (1.0 - t))))
    rangs_vivant = loft(bm, vivant, fermer_haut=False)
    # cime : un chicot court, pas une coupe nette
    cime_centre, _ = chemin_vivant(1.0)
    cime = bm.verts.new((cime_centre[0] + 0.06, cime_centre[1] - 0.04,
                         cime_centre[2] + 0.22))
    dessus = rangs_vivant[-1]
    for i in range(ANNEAU_MOITIE):
        j = (i + 1) % ANNEAU_MOITIE
        f = bm.faces.new((dessus[i], dessus[j], cime))
        f.material_index = 0

    # --- moitié morte : loft court, face de fente aplatie vers +X, et la
    # COURONNE D'ÉCHARDES dans le maillage : le dernier anneau part en
    # pointes inégales au lieu de se refermer à plat.
    mort = []
    for k in range(6):
        t = k / 5.0
        centre, rayon = chemin_mort(t)
        mort.append(anneau(centre, rayon, ANNEAU_MOITIE, centre[2],
                           graine=80.0 + k * 1.9, aplati=(0.0, 0.28 * (1.0 - t))))
    rangs_mort = loft(bm, mort)
    sommet = rangs_mort[-1]
    centre_mort, rayon_mort = chemin_mort(1.0)
    fond = bm.verts.new((centre_mort[0], centre_mort[1], centre_mort[2] - 0.35))
    hauteurs = (1.30, 0.22, 0.78, 0.16, 1.05, 0.30, 0.62, 0.14,
                0.92, 0.26, 0.48, 0.18)
    for i in range(ANNEAU_MOITIE):
        j = (i + 1) % ANNEAU_MOITIE
        a = sommet[i].co
        b = sommet[j].co
        pointe = bm.verts.new((
            (a.x + b.x) * 0.5 + (a.x - centre_mort[0]) * 0.35,
            (a.y + b.y) * 0.5 + (a.y - centre_mort[1]) * 0.35,
            max(a.z, b.z) + hauteurs[i]))
        for tri in ((sommet[i], sommet[j], pointe),
                    (sommet[j], sommet[i], fond)):
            f = bm.faces.new(tri)
            f.material_index = 0

    # --- moignons : trois branches arrachées encore accrochées à la
    # moitié vivante, générées du MÊME chemin de tronc — jamais plantées à
    # côté (le défaut « cicatrice qui flotte » mesuré sur la version
    # procédurale).
    for z, yaw, longueur in ((4.6, 1.9, 1.30), (6.9, -2.4, 1.05),
                             (8.9, 2.0, 0.85)):
        t = (z - FOURCHE_Z) / (VIVANT_SOMMET - FOURCHE_Z)
        centre, rayon = chemin_vivant(t)
        direction = (math.cos(yaw), math.sin(yaw), 0.42)
        base = (centre[0] + direction[0] * rayon * 0.8,
                centre[1] + direction[1] * rayon * 0.8, z)
        anneaux_moignon = []
        for e in range(3):
            te = e / 2.0
            c = (base[0] + direction[0] * longueur * te,
                 base[1] + direction[1] * longueur * te,
                 base[2] + direction[2] * longueur * te)
            anneaux_moignon.append(anneau(
                (c[0], c[1]), (0.17 - te * 0.075) * rayon / 0.35, 7, c[2],
                graine=z * 4.1 + e, applique_cicatrice=False))
        loft(bm, anneaux_moignon, fermer_haut=True)


# ---------------------------------------------------------------------------
# SM_ThunderstruckTree_Heart — le bois mis à nu
# ---------------------------------------------------------------------------
def ruban(bm, points, demi_largeur, epaisseur):
    """Un ruban lofté le long d'une polyligne : section rectangulaire
    orientée vers l'extérieur du tronc (les points portent leur normale)."""
    anneaux_ruban = []
    for p, normale, tangente in points:
        cote = (tangente[0] * demi_largeur, tangente[1] * demi_largeur,
                tangente[2] * demi_largeur)
        dedans = (p[0] - normale[0] * epaisseur, p[1] - normale[1] * epaisseur,
                  p[2] - normale[2] * epaisseur)
        anneaux_ruban.append([
            (p[0] - cote[0], p[1] - cote[1], p[2] - cote[2]),
            (p[0] + cote[0], p[1] + cote[1], p[2] + cote[2]),
            (dedans[0] + cote[0], dedans[1] + cote[1], dedans[2] + cote[2]),
            (dedans[0] - cote[0], dedans[1] - cote[1], dedans[2] - cote[2]),
        ])
    loft(bm, anneaux_ruban, fermer_bas=True, fermer_haut=True)


def coeur(bm):
    # --- le coin de la fente : un wedge lofté qui tapisse le fond du col,
    # s'affine en montant entre les deux départs de moitiés.
    fente = []
    for k, (z, largeur, profondeur) in enumerate(((1.52, 0.74, 0.62),
                                                  (2.05, 0.58, 0.46),
                                                  (2.60, 0.34, 0.28))):
        fente.append([(-largeur * 0.5, -profondeur * 0.5, z),
                      (largeur * 0.5, -profondeur * 0.5, z),
                      (largeur * 0.5, profondeur * 0.5, z),
                      (-largeur * 0.5, profondeur * 0.5, z)])
    loft(bm, fente, fermer_bas=True, fermer_haut=True)

    # --- le ruban de cicatrice, logé DANS le retrait de l'écorce : même
    # spirale (angle_cicatrice), rayon entre le fond du retrait (×0,80) et
    # la pleine écorce — il affleure sans dépasser.
    etapes = []
    n = 9
    for k in range(n):
        z = CICATRICE_HAUT - 0.25 - (CICATRICE_HAUT - CICATRICE_BAS - 0.5) \
            * k / (n - 1)
        if z > FOURCHE_Z:
            t = (z - FOURCHE_Z) / (VIVANT_SOMMET - FOURCHE_Z)
            centre, rayon = chemin_vivant(t)
        else:
            centre = (0.0, 0.0, z)
            rayon = 0.86 - (z / FOURCHE_Z) * 0.22
        a = angle_cicatrice(z)
        r = rayon * (CICATRICE_RETRAIT + 0.075)
        p = (centre[0] + math.cos(a) * r, centre[1] + math.sin(a) * r, z)
        normale = (math.cos(a), math.sin(a), 0.0)
        etapes.append((p, normale, a))
    chemin = []
    for k in range(n):
        p, normale, a = etapes[k]
        p_suiv = etapes[min(k + 1, n - 1)][0]
        p_prec = etapes[max(k - 1, 0)][0]
        tangente = (p_suiv[0] - p_prec[0], p_suiv[1] - p_prec[1],
                    p_suiv[2] - p_prec[2])
        norme = math.sqrt(sum(c * c for c in tangente)) or 1.0
        tangente = tuple(c / norme for c in tangente)
        chemin.append((p, normale, tangente))
    ruban(bm, chemin, 0.115, 0.10)

    # --- cœurs d'échardes : trois pointes pâles au centre de la couronne
    # rompue — le bois frais que la rupture expose au ciel.
    centre_mort, _ = chemin_mort(1.0)
    for i, (dx, dy, h) in enumerate(((0.10, -0.06, 1.05), (-0.14, 0.10, 0.72),
                                     (0.02, 0.16, 0.55))):
        base_z = centre_mort[2] - 0.10
        b = (centre_mort[0] + dx, centre_mort[1] + dy, base_z)
        rangs_pointe = [
            [(b[0] - 0.09, b[1] - 0.09, b[2]), (b[0] + 0.09, b[1] - 0.09, b[2]),
             (b[0] + 0.09, b[1] + 0.09, b[2]), (b[0] - 0.09, b[1] + 0.09, b[2])],
            [(b[0] - 0.02 + dx * 0.4, b[1] - 0.02 + dy * 0.4, b[2] + h),
             (b[0] + 0.02 + dx * 0.4, b[1] - 0.02 + dy * 0.4, b[2] + h),
             (b[0] + 0.02 + dx * 0.4, b[1] + 0.02 + dy * 0.4, b[2] + h),
             (b[0] - 0.02 + dx * 0.4, b[1] + 0.02 + dy * 0.4, b[2] + h)],
        ]
        loft(bm, rangs_pointe, fermer_bas=True, fermer_haut=True)

    # --- bouts pâles des moignons (mêmes cotes que l'écorce).
    for z, yaw, longueur in ((4.6, 1.9, 1.30), (6.9, -2.4, 1.05),
                             (8.9, 2.0, 0.85)):
        t = (z - FOURCHE_Z) / (VIVANT_SOMMET - FOURCHE_Z)
        centre, rayon = chemin_vivant(t)
        direction = (math.cos(yaw), math.sin(yaw), 0.42)
        bout = (centre[0] + direction[0] * (rayon * 0.8 + longueur),
                centre[1] + direction[1] * (rayon * 0.8 + longueur),
                z + 0.42 * longueur)
        taille = 0.070 * rayon / 0.35
        rangs_bout = [
            [(bout[0] - taille, bout[1] - taille, bout[2] - taille),
             (bout[0] + taille, bout[1] - taille, bout[2] - taille),
             (bout[0] + taille, bout[1] + taille, bout[2] - taille),
             (bout[0] - taille, bout[1] + taille, bout[2] - taille)],
            [(bout[0] - taille * 0.5, bout[1] - taille * 0.5, bout[2] + taille),
             (bout[0] + taille * 0.5, bout[1] - taille * 0.5, bout[2] + taille),
             (bout[0] + taille * 0.5, bout[1] + taille * 0.5, bout[2] + taille),
             (bout[0] - taille * 0.5, bout[1] + taille * 0.5, bout[2] + taille)],
        ]
        loft(bm, rangs_bout, fermer_bas=True, fermer_haut=True)

    # --- cassures des branches au sol : la face pâle REGARDE l'arbre —
    # elles sont tombées d'ici, pas apportées par le vent.
    for bx, by, yaw, longueur in BRANCHES:
        vers_arbre = math.atan2(-by, -bx)
        bout = (bx + math.cos(vers_arbre) * longueur * 0.52,
                by + math.sin(vers_arbre) * longueur * 0.52, 0.16)
        rangs_cassure = [
            [(bout[0] - 0.10, bout[1] - 0.10, 0.04),
             (bout[0] + 0.10, bout[1] - 0.10, 0.04),
             (bout[0] + 0.10, bout[1] + 0.10, 0.04),
             (bout[0] - 0.10, bout[1] + 0.10, 0.04)],
            [(bout[0] - 0.04 + math.cos(vers_arbre) * 0.16,
              bout[1] - 0.04 + math.sin(vers_arbre) * 0.16, 0.30),
             (bout[0] + 0.04 + math.cos(vers_arbre) * 0.16,
              bout[1] - 0.04 + math.sin(vers_arbre) * 0.16, 0.30),
             (bout[0] + 0.04 + math.cos(vers_arbre) * 0.16,
              bout[1] + 0.04 + math.sin(vers_arbre) * 0.16, 0.30),
             (bout[0] - 0.04 + math.cos(vers_arbre) * 0.16,
              bout[1] + 0.04 + math.sin(vers_arbre) * 0.16, 0.30)],
        ]
        loft(bm, rangs_cassure, fermer_bas=True, fermer_haut=True)


# ---------------------------------------------------------------------------
# Branches arrachées au sol — dans le MÊME GLB (plan approuvé) : la chute
# appartient à l'arbre, pas au lieu. Godot (x, z) = Blender (x, -y) : la
# branche A vise Godot (2,9 ; -1,7) donc Blender (2,9 ; +1,7).
# ---------------------------------------------------------------------------
BRANCHES = (
    (2.9, 1.7, 2.05, 3.1),      # x, y, yaw de pose, longueur
    (-3.4, 2.2, -0.75, 2.4),
)


def branche(bm, bx, by, yaw, longueur):
    rayon = 0.155
    perp = (-math.sin(yaw), math.cos(yaw))
    anneaux_branche = []
    for k in range(4):
        t = k / 3.0
        c = (bx + math.cos(yaw) * longueur * (t - 0.5),
             by + math.sin(yaw) * longueur * (t - 0.5))
        r = rayon * (1.0 - t * 0.35)
        # posée : centre à hauteur de rayon, léger fléchissement au milieu
        z = r + 0.05 * math.sin(t * math.pi)
        # section perpendiculaire à l'axe de la branche
        pts = []
        for i in range(8):
            a = 2.0 * math.pi * i / 8
            rr = r * (1.0 + _graine(k * 5.0 + i) * 0.12)
            pts.append((c[0] + perp[0] * math.cos(a) * rr,
                        c[1] + perp[1] * math.cos(a) * rr,
                        z + math.sin(a) * rr))
        anneaux_branche.append(pts)
    loft(bm, anneaux_branche, fermer_bas=True, fermer_haut=True)
    # un chicot latéral, pour que la branche ne soit pas un tube
    c_mid = (bx + math.cos(yaw) * longueur * 0.1,
             by + math.sin(yaw) * longueur * 0.1)
    rangs_chicot = [
        [(c_mid[0] - 0.06, c_mid[1] - 0.06, 0.18),
         (c_mid[0] + 0.06, c_mid[1] - 0.06, 0.18),
         (c_mid[0] + 0.06, c_mid[1] + 0.06, 0.18),
         (c_mid[0] - 0.06, c_mid[1] + 0.06, 0.18)],
        [(c_mid[0] - 0.03 + perp[0] * 0.5, c_mid[1] - 0.03 + perp[1] * 0.5, 0.55),
         (c_mid[0] + 0.03 + perp[0] * 0.5, c_mid[1] - 0.03 + perp[1] * 0.5, 0.55),
         (c_mid[0] + 0.03 + perp[0] * 0.5, c_mid[1] + 0.03 + perp[1] * 0.5, 0.55),
         (c_mid[0] - 0.03 + perp[0] * 0.5, c_mid[1] + 0.03 + perp[1] * 0.5, 0.55)],
    ]
    loft(bm, rangs_chicot, fermer_bas=True, fermer_haut=True)


# ---------------------------------------------------------------------------
# Assemblage
# ---------------------------------------------------------------------------
def objet_depuis(nom, remplir, nom_materiau, base_au_sol):
    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()
    remplir(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(maillage)
    bm.free()
    if base_au_sol:
        bas = min(v.co.z for v in maillage.vertices)
        for v in maillage.vertices:
            v.co.z -= bas
    obj = bpy.data.objects.new(nom, maillage)
    obj.data.materials.append(materiau(nom_materiau))
    bpy.context.collection.objects.link(obj)
    return obj


def tris_de(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def emprise(objets):
    xs, ys, zs = [], [], []
    for obj in objets:
        for v in obj.data.vertices:
            xs.append(v.co.x)
            ys.append(v.co.y)
            zs.append(v.co.z)
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pieces = [
        objet_depuis("SM_ThunderstruckTree_Bark", ecorce,
                     "MAT_Tree_CharredBark", True),
        objet_depuis("SM_ThunderstruckTree_Heart", coeur,
                     "MAT_Tree_Heartwood", False),
        objet_depuis("SM_ThunderstruckTree_BranchA",
                     lambda bm: branche(bm, *BRANCHES[0]),
                     "MAT_Tree_CharredBark", True),
        objet_depuis("SM_ThunderstruckTree_BranchB",
                     lambda bm: branche(bm, *BRANCHES[1]),
                     "MAT_Tree_CharredBark", True),
    ]

    total = 0
    for obj in pieces:
        n = tris_de(obj)
        total += n
        print("[thunderstruck_tree] %-28s %4d tris" % (obj.name, n))
    (x0, x1), (y0, y1), (z0, z1) = emprise(pieces)
    print("[thunderstruck_tree] emprise X %.2f..%.2f  Y %.2f..%.2f  "
          "Z %.3f..%.2f — %d tris (budget %d)"
          % (x0, x1, y0, y1, z0, z1, total, BUDGET_TRIS))

    # LES REFUS DU PLAN APPROUVÉ — le générateur n'enregistre pas un arbre
    # hors contrat, il ne le « signale » pas : il échoue.
    if not (HAUTEUR_MIN <= z1 <= HAUTEUR_MAX):
        print("[thunderstruck_tree] ERREUR: hauteur %.2f hors de [%.0f ; %.0f]"
              " — REFUS d'enregistrer" % (z1, HAUTEUR_MIN, HAUTEUR_MAX))
        return 2
    if abs(z0) > BASE_TOL:
        print("[thunderstruck_tree] ERREUR: base à Z=%.3f (attendu 0) — "
              "REFUS d'enregistrer" % z0)
        return 2
    if total > BUDGET_TRIS:
        print("[thunderstruck_tree] ERREUR: budget dépassé — REFUS "
              "d'enregistrer")
        return 2
    # La souche doit avoir sa largeur de plan (2,1 m ± 0,3 lobes compris).
    ecorce_obj = pieces[0]
    bas_xs = [v.co.x for v in ecorce_obj.data.vertices if v.co.z < 0.3]
    bas_ys = [v.co.y for v in ecorce_obj.data.vertices if v.co.z < 0.3]
    largeur_souche = max(max(bas_xs) - min(bas_xs), max(bas_ys) - min(bas_ys))
    if abs(largeur_souche - SOUCHE_LARGEUR) > 0.35:
        print("[thunderstruck_tree] ERREUR: souche large de %.2f m "
              "(attendu %.1f ± 0,35)" % (largeur_souche, SOUCHE_LARGEUR))
        return 2
    # La cicatrice est réellement CREUSÉE. Le contrôle se fait PAR SOMMET,
    # normalisé : chaque sommet du fût vivant est comparé au rayon nominal
    # de SON anneau (le fût s'affine), contre l'angle de la spirale à SON
    # z (la bande descend). Le premier jet de ce contrôle comparait tout à
    # un seul z de référence ET prenait pour témoin la face APLATIE de la
    # fente — il mesurait la joue, pas la cicatrice, et rougissait sur une
    # géométrie correcte (même famille que « mesurer la platitude » de
    # tools/CLAUDE.md : un chiffre juste au mauvais endroit est faux).
    ratios_dans, ratios_hors = [], []
    for v in ecorce_obj.data.vertices:
        z = v.co.z
        if not (3.4 <= z <= 6.8):
            continue    # fenêtre franche du fût vivant, loin fourche et cime
        t = (z - FOURCHE_Z) / (VIVANT_SOMMET - FOURCHE_Z)
        centre, rayon_nominal = chemin_vivant(t)
        distance = math.hypot(v.co.x - centre[0], v.co.y - centre[1])
        if distance > rayon_nominal * 1.10 or distance < rayon_nominal * 0.4:
            continue    # moignon ou bruit, pas la paroi du fût
        angle = math.atan2(v.co.y - centre[1], v.co.x - centre[0])
        ecart_joue = (angle - math.pi + math.pi) % (2 * math.pi) - math.pi
        if abs(ecart_joue) < 1.1:
            continue    # face aplatie de la fente : ni bande, ni témoin
        ecart = (angle - angle_cicatrice(z) + math.pi) % (2 * math.pi) - math.pi
        ratio = distance / rayon_nominal
        if abs(ecart) < CICATRICE_DEMI_ANGLE * 0.75:
            ratios_dans.append(ratio)
        elif abs(ecart) > CICATRICE_DEMI_ANGLE * 1.6:
            ratios_hors.append(ratio)
    if not ratios_dans or not ratios_hors:
        print("[thunderstruck_tree] ERREUR: contrôle de cicatrice sans "
              "échantillon (%d dans, %d hors)"
              % (len(ratios_dans), len(ratios_hors)))
        return 2
    moyen_dans = sum(ratios_dans) / len(ratios_dans)
    moyen_hors = sum(ratios_hors) / len(ratios_hors)
    creux = moyen_hors - moyen_dans
    print("[thunderstruck_tree] cicatrice : rayon relatif %.3f dans la bande "
          "(%d sommets), %.3f hors bande (%d) — creux %.3f"
          % (moyen_dans, len(ratios_dans), moyen_hors, len(ratios_hors),
             creux))
    if creux < 0.10:
        print("[thunderstruck_tree] ERREUR: la cicatrice n'est pas creusée")
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_ThunderstruckTree.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[thunderstruck_tree] source enregistrée -> %s" % sortie)
    print("FIN NOMINALE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
