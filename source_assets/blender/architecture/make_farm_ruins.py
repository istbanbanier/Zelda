# SOURCE DE GÉNÉRATION REPRODUCTIBLE — Ruine de toiture de la ferme
# abandonnée (V2.3-A.R2B, agent B).
#
# POURQUOI CE FICHIER EXISTE. Le lead a rejeté la charpente procédurale de
# la fermette : « de longues planches plantées dans le bâtiment et dans
# l'arbre ». Le défaut était structurel — des `stone_block` posés un par un
# ne partagent aucune logique porteuse : les chevrons ne touchaient ni la
# faîtière ni les murs, et chaque bloc pouvait flotter seul. Ici la
# charpente est UN objet : la faîtière cassée en deux, ses chevrons
# SOLIDAIRES (générés du même trait, du faîte à l'arase), les sablières qui
# reposent sur les murs. Rien ne peut se désolidariser par construction.
#
# QUATRE FAMILLES D'OBJETS, UN SEUL GLB (même pratique que
# make_village_wall.py, deux objets dans SM_Village_Wall.glb) :
#   * `SM_Farm_Truss`          — charpente : faîtière rompue, chevrons,
#                                sablières ; base Z=0 à l'ARASE des murs
#                                (3,12 m mesurés, probe_kit_seating) ;
#   * `SM_Farm_RoofPan_Intact` — pan de couverture À PLAT (~3,6 × 6,8 m),
#                                posé par le lieu à 22° sur le versant
#                                ouest ; rangées de tuiles à recouvrement ;
#   * `SM_Farm_RoofPan_Fallen` — pan PLIÉ en deux segments, un bout au
#                                sol : la géométrie porte la chute, le lieu
#                                ne fait que le poser ;
#   * `SM_Farm_Debris_A/B`     — gravats fusionnés : éclats de tuiles et
#                                bouts de chevrons, base Z=0.
#
# BUDGET VERROUILLÉ AVANT MODÉLISATION (arbitrage R2B) : ferme ≤ 4 500
# triangles au total, 3 matériaux, sRGB converti en linéaire explicitement.
# Le générateur REFUSE d'enregistrer au-delà — le budget se vérifie à
# l'export, pas dans un rapport.
#
# Blender est Z-up ; l'export convertit en Y-up : Blender (x, y, z) devient
# Godot (x, z, -y). La faîtière court selon Blender Y, donc Godot Z ; le
# versant intact est en Blender/Godot -X (ouest) ; l'effondrement regarde
# Godot +Z (sud), soit Blender -Y.
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/architecture/make_farm_ruins.py

import math
import os
import sys

import bmesh
import bpy

# ---------------------------------------------------------------------------
# Cotes — mesurées sur le bâti réel, jamais devinées.
# probe_kit_seating (2026-08-19) : Wall_UnevenBrick_* fait 2,00 × 3,12 ×
# 0,41, pivot min-Y — l'arase est donc à 3,12 m au-dessus du plancher des
# murs, et la charpente pose son Z=0 sur ce plan.
# ---------------------------------------------------------------------------
DEMI_PORTEE = 3.05      # du faîte à l'aplomb du mur (murs à ±3,0)
PENTE_DEG = 22.0
FAITE_Z = DEMI_PORTEE * math.tan(math.radians(PENTE_DEG))   # ≈ 1,232

CHEVRON_SECTION = (0.09, 0.14)
SABLIERE_SECTION = (0.16, 0.14)
FAITIERE_SECTION = (0.14, 0.20)

PAN_PENTE_M = 3.55      # longueur de versant du pan intact
PAN_LONG_M = 6.80       # le long du faîte
PAN_RANGS = 6           # rangées de tuiles à recouvrement

BUDGET_TRIS = 4500
# La base est « au sol » si RIEN ne perce le sol (‑5 mm) et si le point
# bas reste à moins de 5 cm du plan : un assemblage de plaques inclinées
# n'a pas de face inférieure exactement plane, exiger 0,000 pousserait à
# tricher sur la géométrie plutôt qu'à poser juste.
BASE_TOL_DESSOUS = 0.005
BASE_TOL_DESSUS = 0.05

# ---------------------------------------------------------------------------
# Matériaux — sRGB converti en linéaire (glTF stocke du linéaire, Godot
# réencode en sRGB : écrire 0,40 tel quel rendrait 0,67).
#
# Hiérarchie de valeur visée sous l'éclairage du monde : murs de brique
# teintés ≈ 0,45 rendu ; les TUILES restent SOUS les murs (0,36), le BOIS
# de charpente encore dessous (0,28), et le bois ROMPU (cœur frais) porte
# le seul accent clair — c'est lui qui raconte la cassure récente.
# Recalage obligatoire sur la capture : un albédo n'est pas une valeur
# rendue (scripts/CLAUDE.md).
# ---------------------------------------------------------------------------
MATERIAUX = {
    "MAT_Farm_Wood": (0.285, 0.225, 0.155, 0.95),
    "MAT_Farm_Tiles": (0.380, 0.270, 0.205, 0.92),
    "MAT_Farm_BrokenWood": (0.720, 0.620, 0.460, 0.90),
}
IDX_BOIS = 0
IDX_TUILES = 1
IDX_CASSURE = 2


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


# ---------------------------------------------------------------------------
# Briques de construction bmesh
# ---------------------------------------------------------------------------
def _graine(x):
    """Petit bruit déterministe sans dépendance : sin d'entiers."""
    return math.sin(x * 12.9898) * 0.5


def poutre(bm, depart, arrivee, largeur, hauteur, materiau_idx,
           jitter=0.006, roulis=0.0):
    """Une poutre du point `depart` au point `arrivee` (axes Blender),
    section largeur × hauteur perpendiculaire à son axe. Huit sommets,
    six faces — rien de plus. Le léger `jitter` casse le parallélisme
    parfait qui se lit comme une primitive.
    """
    dx = [arrivee[i] - depart[i] for i in range(3)]
    longueur = math.sqrt(sum(c * c for c in dx))
    axe = [c / longueur for c in dx]
    # Repère orthogonal : `cote` horizontal, `haut` le plus vertical possible.
    if abs(axe[2]) < 0.99:
        cote = [-axe[1], axe[0], 0.0]
        norme = math.sqrt(sum(c * c for c in cote)) or 1.0
        cote = [c / norme for c in cote]
    else:
        cote = [1.0, 0.0, 0.0]
    haut = [axe[1] * cote[2] - axe[2] * cote[1],
            axe[2] * cote[0] - axe[0] * cote[2],
            axe[0] * cote[1] - axe[1] * cote[0]]
    if roulis:
        c, s = math.cos(roulis), math.sin(roulis)
        cote, haut = ([c * cote[i] + s * haut[i] for i in range(3)],
                      [-s * cote[i] + c * haut[i] for i in range(3)])
    sommets = []
    for extremite, point in ((0.0, depart), (1.0, arrivee)):
        for sc, sh in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
            j = _graine(extremite * 7.1 + sc * 2.3 + sh * 4.7) * jitter
            sommets.append(bm.verts.new((
                point[0] + cote[0] * (largeur * 0.5 * sc + j)
                + haut[0] * hauteur * 0.5 * sh,
                point[1] + cote[1] * (largeur * 0.5 * sc + j)
                + haut[1] * hauteur * 0.5 * sh,
                point[2] + cote[2] * (largeur * 0.5 * sc + j)
                + haut[2] * hauteur * 0.5 * sh)))
    a = sommets[:4]
    b = sommets[4:]
    faces = [bm.faces.new((a[0], a[1], a[2], a[3])),
             bm.faces.new((b[3], b[2], b[1], b[0]))]
    for i in range(4):
        j = (i + 1) % 4
        faces.append(bm.faces.new((a[i], b[i], b[j], a[j])))
    for f in faces:
        f.material_index = materiau_idx
    return faces


def echarde(bm, base, direction, longueur, largeur, materiau_idx):
    """Un coin déchiré : quatre sommets de base, une pointe — le bout d'une
    pièce ROMPUE, en bois clair, jamais une coupe de scie."""
    perp = [-direction[1], direction[0], 0.0]
    n = math.sqrt(sum(c * c for c in perp)) or 1.0
    perp = [c / n for c in perp]
    b0 = bm.verts.new((base[0] + perp[0] * largeur * 0.5,
                       base[1] + perp[1] * largeur * 0.5, base[2]))
    b1 = bm.verts.new((base[0] - perp[0] * largeur * 0.5,
                       base[1] - perp[1] * largeur * 0.5, base[2]))
    b2 = bm.verts.new((base[0], base[1], base[2] + largeur * 0.6))
    pointe = bm.verts.new((base[0] + direction[0] * longueur,
                           base[1] + direction[1] * longueur,
                           base[2] + direction[2] * longueur))
    for tri in ((b0, b1, pointe), (b1, b2, pointe), (b2, b0, pointe),
                (b0, b2, b1)):
        f = bm.faces.new(tri)
        f.material_index = materiau_idx
    return 4


# ---------------------------------------------------------------------------
# SM_Farm_Truss — la charpente rompue, d'un seul trait
# ---------------------------------------------------------------------------
def charpente(bm):
    z_faite = FAITE_Z + CHEVRON_SECTION[1] * 0.5

    # Sablières : elles POSENT la charpente sur l'arase des murs. Ouest
    # (-X) entière ; est (+X) rompue — il n'en reste que le tronçon nord,
    # comme le mur en dessous (le segment sud du mur est n'existe plus).
    poutre(bm, (-3.0, -3.15, SABLIERE_SECTION[1] * 0.5),
           (-3.0, 3.15, SABLIERE_SECTION[1] * 0.5),
           SABLIERE_SECTION[0], SABLIERE_SECTION[1], IDX_BOIS)
    poutre(bm, (3.0, 0.4, SABLIERE_SECTION[1] * 0.5),
           (3.0, 3.15, SABLIERE_SECTION[1] * 0.5),
           SABLIERE_SECTION[0], SABLIERE_SECTION[1], IDX_BOIS)
    echarde(bm, (3.0, 0.4, SABLIERE_SECTION[1] * 0.5), (0.0, -1.0, 0.05),
            0.34, SABLIERE_SECTION[0], IDX_CASSURE)

    # Faîtière en DEUX tronçons : le nord tient, le sud a plié — son bout
    # libre plonge de 0,55 m vers le vide laissé par le mur est.
    poutre(bm, (0.0, 0.55, z_faite), (0.0, 3.35, z_faite),
           FAITIERE_SECTION[0], FAITIERE_SECTION[1], IDX_BOIS)
    poutre(bm, (0.0, 0.30, z_faite - 0.04), (0.12, -3.05, z_faite - 0.58),
           FAITIERE_SECTION[0] * 0.95, FAITIERE_SECTION[1], IDX_BOIS,
           roulis=math.radians(9.0))
    # Les deux bouts de la rupture, cœur clair déchiré.
    echarde(bm, (0.0, 0.55, z_faite + 0.03), (0.05, -1.0, -0.12), 0.42,
            0.16, IDX_CASSURE)
    echarde(bm, (0.0, 0.30, z_faite - 0.02), (-0.03, 1.0, 0.10), 0.36,
            0.15, IDX_CASSURE)

    # Chevrons SOLIDAIRES : chaque paire part du faîte et descend à
    # l'arase. Côté nord (faîtière intacte) : trois paires complètes.
    for i, y in enumerate((0.9, 1.9, 2.9)):
        for cote in (-1, 1):
            devers = _graine(i * 3.1 + cote) * 0.05
            poutre(bm, (cote * 0.06, y + devers, z_faite - 0.02),
                   (cote * DEMI_PORTEE, y + devers, CHEVRON_SECTION[1] * 0.5),
                   CHEVRON_SECTION[0], CHEVRON_SECTION[1], IDX_BOIS)
    # Côté sud : la faîtière a plié — les chevrons ouest suivent sa chute
    # (toujours ACCROCHÉS à elle : même point de départ), les chevrons est
    # sont rompus court, bout déchiré.
    for i, y in enumerate((-0.6, -1.7, -2.7)):
        t = (0.30 - y) / 3.35          # position le long du tronçon plié
        z_depart = (z_faite - 0.04) - 0.54 * t
        x_depart = 0.12 * t
        poutre(bm, (x_depart - 0.06, y, z_depart),
               (-DEMI_PORTEE, y, CHEVRON_SECTION[1] * 0.5),
               CHEVRON_SECTION[0], CHEVRON_SECTION[1], IDX_BOIS)
        if i != 1:
            longueur_rompue = 1.15 + _graine(y) * 0.3
            pente = (z_depart - CHEVRON_SECTION[1] * 0.5) / DEMI_PORTEE
            poutre(bm, (x_depart + 0.06, y, z_depart),
                   (x_depart + longueur_rompue, y,
                    z_depart - pente * longueur_rompue - 0.10),
                   CHEVRON_SECTION[0], CHEVRON_SECTION[1], IDX_BOIS)
            echarde(bm, (x_depart + longueur_rompue, y,
                         z_depart - pente * longueur_rompue - 0.10),
                    (1.0, 0.0, -0.25), 0.30, CHEVRON_SECTION[0], IDX_CASSURE)

    # Un entrait au nord : la triangulation qui dit « charpente », pas
    # « planches posées ».
    poutre(bm, (-2.1, 1.9, 0.44), (2.1, 1.9, 0.44), 0.10, 0.13, IDX_BOIS)


# ---------------------------------------------------------------------------
# Pans de couverture — rangées de tuiles à recouvrement
# ---------------------------------------------------------------------------
def pan(bm, profil, longueur, rangs, materiau_idx):
    """Un pan de toiture le long d'un `profil` [(s, z), …] : `s` est
    l'abscisse curviligne selon Blender X, `z` la hauteur. Chaque rang est
    une planche de tuiles qui RECOUVRE la précédente de 8 cm — c'est le
    recouvrement qui fait lire « couverture », pas une plaque.
    """
    total = profil[-1][0]
    pas = total / rangs
    for r in range(rangs):
        s0 = r * pas
        s1 = s0 + pas + (0.08 if r < rangs - 1 else 0.0)
        # hauteur du profil aux deux abscisses (interpolation linéaire)
        def z_de(s):
            for i in range(len(profil) - 1):
                a, b = profil[i], profil[i + 1]
                if s <= b[0] or i == len(profil) - 2:
                    if b[0] == a[0]:
                        return a[1]
                    t = max(0.0, min(1.0, (s - a[0]) / (b[0] - a[0])))
                    return a[1] + (b[1] - a[1]) * t
            return profil[-1][1]
        releve = 0.030 + r * 0.012      # chaque rang chevauche le précédent
        y0 = -longueur * 0.5 + abs(_graine(r * 1.7)) * 0.12
        y1 = longueur * 0.5 - abs(_graine(r * 2.9)) * 0.12
        epaisseur = 0.055
        coins_bas = [(s0, y0, z_de(s0) + releve), (s1, y0, z_de(s1) + releve),
                     (s1, y1, z_de(s1) + releve), (s0, y1, z_de(s0) + releve)]
        bas = [bm.verts.new(p) for p in coins_bas]
        haut = [bm.verts.new((p[0], p[1], p[2] + epaisseur))
                for p in coins_bas]
        faces = [bm.faces.new(tuple(reversed(bas))), bm.faces.new(tuple(haut))]
        for i in range(4):
            j = (i + 1) % 4
            faces.append(bm.faces.new((bas[i], bas[j], haut[j], haut[i])))
        for f in faces:
            f.material_index = materiau_idx
        # Trois liteaux sous le rang 0 seulement (le dessous se voit du sol
        # par le trou du toit).
        if r == 0:
            for y in (y0 + 0.5, 0.0, y1 - 0.5):
                poutre(bm, (0.02, y, z_de(0.02) + 0.032),
                       (total - 0.02, y, z_de(total - 0.02) + 0.032),
                       0.07, 0.06, IDX_BOIS)


def pan_intact(bm):
    # À PLAT : c'est le LIEU qui le pose à 22° sur les chevrons. Un pan
    # exporté déjà penché aurait une AABB diagonale et une assise fausse.
    pan(bm, [(0.0, 0.0), (PAN_PENTE_M, 0.0)], PAN_LONG_M, PAN_RANGS,
        IDX_TUILES)


def pan_tombe(bm):
    # PLIÉ : un segment couché (glissé au sol), un segment relevé contre le
    # mur. La géométrie PORTE la chute — le lieu n'a plus qu'à le poser.
    pan(bm, [(0.0, 0.0), (1.5, 0.22), (3.15, 2.05)], 2.6, 4, IDX_TUILES)
    # Deux tuiles échappées au pied du pli.
    for i, (x, y) in enumerate(((0.7, -1.55), (2.0, 1.5))):
        poutre(bm, (x - 0.22, y, 0.07), (x + 0.22, y + 0.1, 0.09),
               0.34, 0.05, IDX_TUILES, roulis=_graine(i) * 0.35)


def gravats(bm, graine, etendue):
    """Un tas fusionné : éclats de tuiles et bouts de chevrons, jamais un
    semis de cubes réguliers."""
    n = 9
    for i in range(n):
        angle = i * 2.399 + graine          # angle d'or : pas d'alignement
        rayon = etendue * (0.25 + 0.75 * abs(_graine(i * 1.3 + graine)))
        x = math.cos(angle) * rayon
        y = math.sin(angle) * rayon * 0.8
        taille = 0.22 + abs(_graine(i * 2.1 + graine)) * 0.30
        z = taille * 0.18
        if i % 3 == 0:
            poutre(bm, (x - taille, y, z), (x + taille, y + 0.15, z + 0.05),
                   0.11, 0.10, IDX_BOIS, roulis=_graine(i) * 0.9)
        else:
            poutre(bm, (x - taille * 0.7, y - 0.05, z),
                   (x + taille * 0.7, y + 0.08, z + 0.03),
                   taille * 1.1, 0.06, IDX_TUILES, roulis=_graine(i + 9) * 0.7)
    # Un chevron cassé émerge du tas — la cause au milieu des conséquences.
    poutre(bm, (-etendue * 0.5, 0.1, 0.05), (etendue * 0.7, -0.2, 0.55),
           CHEVRON_SECTION[0], CHEVRON_SECTION[1], IDX_BOIS)
    echarde(bm, (etendue * 0.7, -0.2, 0.55), (0.8, -0.3, 0.4), 0.26,
            CHEVRON_SECTION[0], IDX_CASSURE)


# ---------------------------------------------------------------------------
# Assemblage
# ---------------------------------------------------------------------------
def objet_depuis(nom, remplir):
    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()
    remplir(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(maillage)
    bm.free()
    # CHAQUE pièce se pose par son point bas : on cale min-Z à 0 ICI, une
    # fois, plutôt que de corriger à la main chaque éclat penché — la
    # troisième retouche du même millimètre est le signal qu'il faut caler
    # à la source. Le garde d'emprise reste : il attrape une pièce dont la
    # LOGIQUE de hauteur est fausse (faîte, portée), pas son arrondi.
    bas = min(v.co.z for v in maillage.vertices)
    for v in maillage.vertices:
        v.co.z -= bas
    obj = bpy.data.objects.new(nom, maillage)
    for nom_mat in ("MAT_Farm_Wood", "MAT_Farm_Tiles", "MAT_Farm_BrokenWood"):
        obj.data.materials.append(materiau(nom_mat))
    bpy.context.collection.objects.link(obj)
    return obj


def tris_de(obj):
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def emprise(obj):
    xs = [v.co.x for v in obj.data.vertices]
    ys = [v.co.y for v in obj.data.vertices]
    zs = [v.co.z for v in obj.data.vertices]
    return (min(xs), max(xs)), (min(ys), max(ys)), (min(zs), max(zs))


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    pieces = [
        objet_depuis("SM_Farm_Truss", charpente),
        objet_depuis("SM_Farm_RoofPan_Intact", pan_intact),
        objet_depuis("SM_Farm_RoofPan_Fallen", pan_tombe),
        objet_depuis("SM_Farm_Debris_A", lambda bm: gravats(bm, 0.4, 0.85)),
        objet_depuis("SM_Farm_Debris_B", lambda bm: gravats(bm, 2.9, 0.65)),
    ]

    total = 0
    for obj in pieces:
        n = tris_de(obj)
        total += n
        (x0, x1), (y0, y1), (z0, z1) = emprise(obj)
        print("[farm_ruins] %-24s %4d tris  X %.2f..%.2f  Y %.2f..%.2f  "
              "Z %.3f..%.2f" % (obj.name, n, x0, x1, y0, y1, z0, z1))
        # BASE À Z≈0 : chaque pièce se pose par son point bas. Une pièce
        # dont la base flotte se poserait faux partout.
        if z0 < -BASE_TOL_DESSOUS or z0 > BASE_TOL_DESSUS:
            print("[farm_ruins] ERREUR: base de %s à Z=%.3f (attendu "
                  "[-%.3f ; %.2f])" % (obj.name, z0, BASE_TOL_DESSOUS,
                                       BASE_TOL_DESSUS))
            return 2

    print("[farm_ruins] total %d triangles (budget %d)" % (total, BUDGET_TRIS))
    if total > BUDGET_TRIS:
        print("[farm_ruins] ERREUR: budget dépassé — le générateur REFUSE "
              "d'enregistrer")
        return 2

    # La charpente couvre la portée des murs (6,0 m à ±0,15) : plus courte,
    # elle flotterait entre les arases ; plus longue, elle les traverserait.
    (tx0, tx1), _, (_, tz1) = emprise(pieces[0])
    if abs((tx1 - tx0) - 2.0 * DEMI_PORTEE) > 0.30:
        print("[farm_ruins] ERREUR: portée de charpente %.2f, attendue %.2f"
              % (tx1 - tx0, 2.0 * DEMI_PORTEE))
        return 2
    if not (1.05 <= tz1 <= 1.55):
        print("[farm_ruins] ERREUR: faîte à %.2f m au-dessus de l'arase "
              "(attendu ~%.2f)" % (tz1, FAITE_Z))
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_Farm_Ruins.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[farm_ruins] source enregistrée -> %s" % sortie)
    print("FIN NOMINALE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
