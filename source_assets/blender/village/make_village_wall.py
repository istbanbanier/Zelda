# SOURCE DE GÉNÉRATION REPRODUCTIBLE — Mur de soutènement du hameau.
#
# POURQUOI CE FICHIER EXISTE. Le lead a rejeté « le gros rectangle de
# fondation » dès la première passe ; la réponse d'alors fut vingt
# `K.stone_block` posés en pourtour, ce qui reproduit le même défaut à
# l'échelle du bloc — des boîtes juxtaposées ne font jamais un mur.
# Or le hameau a besoin d'un vrai soutènement : le sol MESURÉ passe de
# 1,7-2,0 (route) à 3,00 (terrasse) sur trois mètres, et c'est cette
# rupture qui porte les « trois hauteurs » demandées.
#
# MÉTHODE — volumes loftés, aucun booléen (voir make_pylon_resonance.py).
#
# LE JOINT EST DANS LE PROFIL, pas creusé après coup. C'est la leçon des
# canaux du pylône transposée : au lieu de juxtaposer des pierres, on
# fabrique UNE assise continue dont l'épaisseur chute sur des secteurs
# étroits. Le mur a donc de vrais joints avec des joues, il se lit en
# lumière rasante, et il ne peut par construction ni s'ouvrir ni se
# désolidariser.
#
# DEUX OBJETS, UN SEUL GLB :
#   * `SM_VillageWall_Course` — une ASSISE de 0,45 m, à empiler. Trois
#     assises font le soutènement de terrasse (1,35 m) ; une seule fait la
#     plinthe d'un bâtiment (le dénivelé sous les bâtis est ≤ 0,30 m
#     mesuré). Un module unique de 1,30 m aurait dû être écrasé en Z pour
#     servir de plinthe, ce qui aplatit visiblement les joints.
#   * `SM_VillageWall_Coping` — le couronnement, débordant de 7 cm.
#
# FRUIT. Le mur est plus épais en bas qu'en haut (0,80 -> 0,73 par assise).
# Un mur de soutènement à section constante se lit comme une plaque posée.
#
# Blender est Z-up ; l'export convertit en Y-up : Blender (x,y,z) devient
# Godot (x, z, -y). L'assise est donc longue selon Godot X.
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/village/make_village_wall.py

import math
import os
import sys

import bmesh
import bpy

# ---------------------------------------------------------------------------
# Cotes
# ---------------------------------------------------------------------------
ASSISE_L = 4.00        # Blender X -> Godot X
ASSISE_H = 0.45
DEMI_EP_PIED = 0.400
DEMI_EP_TETE = 0.365   # fruit

JOINTS = (0.80, 1.60, 2.40, 3.20)   # abscisses des joints verticaux
JOINT_DEMI = 0.035
JOINT_CREUX = 0.030
JOINT_FONDU = 0.018    # rampe entre pleine pierre et fond de joint

# Chaque panneau reçoit un léger retrait propre : deux pierres voisines ne
# sont jamais coplanaires dans un mur monté à la main.
PANNEAU_RETRAIT = (0.000, 0.014, 0.006, 0.018, 0.009)

COURONNEMENT_L = 4.14
COURONNEMENT_H = 0.16
COURONNEMENT_DEMI_EP = 0.470

CHANFREIN = 0.022

# ---------------------------------------------------------------------------
# Matériaux — sRGB converti en linéaire (glTF stocke du linéaire, Godot
# réencode en sRGB : écrire 0,40 donnerait 0,67).
#
# CIBLE DE VALEUR RENDUE : le soutènement est la MASSE MOYENNE du hameau,
# ~0,50 rendu au soleil — entre le bois sombre du quai (~0,30) et l'enduit
# clair de l'auberge (~0,68). Ces trois bandes séparées d'environ 0,15
# sont la condition pour qu'une hiérarchie de matière survive à l'écart
# d'éclairement, mesuré à ×1,6 sur ce monde.
# Recalage obligatoire sur la capture : un albédo n'est pas une valeur
# rendue.
# ---------------------------------------------------------------------------
# RECALÉ SUR LA CAPTURE, pas sur l'intention — c'est la règle du briefing.
# À 0,335 / 0,392 le parapet rendait, en plein soleil sur `vue03`, plus
# CLAIR que l'enduit de l'auberge (luma mesurée ~0,66 contre 0,50) : le mur
# bas du premier plan volait la vedette au bâtiment, et sa surface lisse se
# lisait comme du béton. Descendu d'un tiers pour tenir la bande MOYENNE.
MATERIAUX = {
    "MAT_Village_WallStone": (0.232, 0.206, 0.172, 0.96),
    "MAT_Village_Coping":    (0.272, 0.244, 0.205, 0.94),
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


def loft(bm, anneaux, fermer_bas=True, fermer_haut=True):
    sommets = [[bm.verts.new(p) for p in anneau] for anneau in anneaux]
    for etage in range(len(sommets) - 1):
        bas, haut = sommets[etage], sommets[etage + 1]
        n = len(bas)
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((bas[i], bas[j], haut[j], haut[i]))
    if fermer_bas:
        bm.faces.new(tuple(reversed(sommets[0])))
    if fermer_haut:
        bm.faces.new(tuple(sommets[-1]))
    return sommets


# ---------------------------------------------------------------------------
# Le profil de l'assise : une boucle fermée dans le plan XY.
#
# On échantillonne DENSÉMENT autour des joints et grossièrement ailleurs :
# un pas uniforme assez fin pour résoudre un joint de 35 mm sur 4 m
# produirait des centaines de sommets pour rien.
# ---------------------------------------------------------------------------
def abscisses():
    xs = {0.0, ASSISE_L}
    for j in JOINTS:
        for d in (-JOINT_DEMI - JOINT_FONDU, -JOINT_DEMI, 0.0,
                  JOINT_DEMI, JOINT_DEMI + JOINT_FONDU):
            xs.add(min(max(j + d, 0.0), ASSISE_L))
    # milieux de panneaux, pour porter le retrait propre à chaque pierre
    bornes = [0.0] + list(JOINTS) + [ASSISE_L]
    for i in range(len(bornes) - 1):
        xs.add((bornes[i] + bornes[i + 1]) * 0.5)
    return sorted(xs)


def panneau_de(x):
    bornes = list(JOINTS)
    for i, b in enumerate(bornes):
        if x < b:
            return i
    return len(bornes)


def demi_epaisseur(x, demi_base):
    """Épaisseur locale : pleine pierre, creusée au droit des joints."""
    creux = 0.0
    for j in JOINTS:
        d = abs(x - j)
        if d <= JOINT_DEMI:
            creux = max(creux, JOINT_CREUX)
        elif d <= JOINT_DEMI + JOINT_FONDU:
            t = (JOINT_DEMI + JOINT_FONDU - d) / JOINT_FONDU
            creux = max(creux, JOINT_CREUX * t)
    retrait = PANNEAU_RETRAIT[panneau_de(x) % len(PANNEAU_RETRAIT)]
    return demi_base - creux - retrait


def anneau_assise(z, demi_base, tasse):
    """Boucle fermée : face avant (Y+), bout droit, face arrière, bout gauche.

    `tasse` rentre les quatre coins pour former les chanfreins horizontaux
    du dessus et du dessous.
    """
    xs = abscisses()
    points = []
    for x in xs:
        points.append((x, demi_epaisseur(x, demi_base) - tasse, z))
    points.append((ASSISE_L + tasse * 0.0, -demi_epaisseur(ASSISE_L, demi_base)
                   + tasse, z))
    for x in reversed(xs[:-1]):
        points.append((x, -demi_epaisseur(x, demi_base) + tasse, z))
    return points


def assise(bm):
    """Une assise : quatre étages pour casser les arêtes haute et basse.

    Le dessus ONDULE de ±12 mm : une assise à arase parfaitement plane se
    lit comme du béton, et l'assise suivante s'y pose sans joint visible.
    """
    c = CHANFREIN
    etages = (
        (0.0, DEMI_EP_PIED, c),
        (c, DEMI_EP_PIED, 0.0),
        (ASSISE_H - c, DEMI_EP_TETE, 0.0),
        (ASSISE_H, DEMI_EP_TETE, c),
    )
    anneaux = []
    for z, demi, tasse in etages:
        anneau = anneau_assise(z, demi, tasse)
        if z >= ASSISE_H - c:
            anneau = [(x, y, zz + math.sin(x * 2.1 + 0.6) * 0.012)
                      for x, y, zz in anneau]
        anneaux.append(anneau)
    loft(bm, anneaux)


def couronnement(bm):
    """Chapeau débordant, arêtes cassées, légère pente vers l'avant."""
    demi_l = COURONNEMENT_L * 0.5
    c = CHANFREIN
    def section(z, dx, dy):
        return [
            (-dx + c, dy, z), (dx - c, dy, z),
            (dx, dy - c, z), (dx, -dy + c, z),
            (dx - c, -dy, z), (-dx + c, -dy, z),
            (-dx, -dy + c, z), (-dx, dy - c, z),
        ]
    anneaux = [
        section(0.0, demi_l - c, COURONNEMENT_DEMI_EP - c),
        section(c, demi_l, COURONNEMENT_DEMI_EP),
        section(COURONNEMENT_H - c, demi_l, COURONNEMENT_DEMI_EP * 0.94),
        section(COURONNEMENT_H, demi_l - c, COURONNEMENT_DEMI_EP * 0.94 - c),
    ]
    # Recentre le couronnement sur l'assise (l'assise va de X 0 à 4).
    anneaux = [[(x + ASSISE_L * 0.5, y, z) for x, y, z in a] for a in anneaux]
    loft(bm, anneaux)


def objet_depuis(nom, remplir, nom_materiau):
    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()
    remplir(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(maillage)
    bm.free()
    obj = bpy.data.objects.new(nom, maillage)
    obj.data.materials.append(materiau(nom_materiau))
    bpy.context.collection.objects.link(obj)
    return obj


def emprise(objets):
    xs, ys, zs = [], [], []
    for obj in objets:
        for sommet in obj.data.vertices:
            xs.append(sommet.co.x)
            ys.append(sommet.co.y)
            zs.append(sommet.co.z)
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pieces = [
        objet_depuis("SM_VillageWall_Course", assise, "MAT_Village_WallStone"),
        objet_depuis("SM_VillageWall_Coping", couronnement,
                     "MAT_Village_Coping"),
    ]
    (x0, x1), (y0, y1), (z0, z1) = emprise(pieces)
    print("[mur] %d pièces, %d faces"
          % (len(pieces), sum(len(o.data.polygons) for o in pieces)))
    print("[mur] emprise Blender X %.2f..%.2f  Y %.2f..%.2f  Z %.2f..%.2f"
          % (x0, x1, y0, y1, z0, z1))

    if abs(z0) > 0.005:
        print("[mur] ERREUR: la base n'est pas à Z=0 (min %.3f)" % z0)
        return 2
    if abs((x1 - x0) - COURONNEMENT_L) > 0.02:
        print("[mur] ERREUR: longueur %.3f, attendue %.2f"
              % (x1 - x0, COURONNEMENT_L))
        return 2
    # Le fruit doit exister : une section constante se lirait comme une
    # plaque, ce qui est le défaut d'origine.
    if DEMI_EP_PIED - DEMI_EP_TETE < 0.02:
        print("[mur] ERREUR: fruit insuffisant")
        return 2
    # Les joints doivent être réellement creusés, sinon le mur est lisse.
    plein = demi_epaisseur(0.40, DEMI_EP_PIED)
    creuse = demi_epaisseur(JOINTS[0], DEMI_EP_PIED)
    print("[mur] joint : demi-épaisseur %.3f pleine contre %.3f au joint"
          % (plein, creuse))
    if plein - creuse < JOINT_CREUX * 0.8:
        print("[mur] ERREUR: les joints ne sont pas creusés")
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_Village_Wall.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[mur] source enregistrée -> %s" % sortie)
    return 0


if __name__ == "__main__":
    sys.exit(main())
