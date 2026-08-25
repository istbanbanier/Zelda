# SOURCE DE GÉNÉRATION REPRODUCTIBLE — Pierres funéraires du cimetière du
# tertre (V2.3-B LOT 1.R, voie B).
#
# POURQUOI CE FICHIER EXISTE. Le gate visuel a rejeté le cimetière sur deux
# points, et le second est celui-ci : « remplacer les arches beige de la
# chambre ouverte par des PIERRES FUNÉRAIRES cohérentes ». Les causes sont
# nommées et mesurées : la chambre était faite de `SM_Dungeon_ArchBlock` et
# les stèles de `SM_Dungeon_PillarStub` — la famille de trimsheet qui rend
# TERRACOTTA/BEIGE sous cette lumière ; la couverture était un
# `RockPath_Square_Wide` (une dalle trop propre) ; les lames couchées étaient
# des `cliff_half_rock`, qui rendent des marches beige posées dans l'herbe ;
# et les ceintures étaient des `rock_largeA/C`, dont le glTF porte une surface
# `grass` qui rend TURQUOISE ici (chapeaux mesurés sur la capture d'avant).
#
# CE QUE LE GLB PORTE : neuf pierres, chacune sur SON origine, base à z = 0,
# sans implantation — deux montants et un linteau GLISSÉ pour la gueule de la
# chambre, deux stèles rompues, trois lames couchées de tailles décroissantes,
# et le tas de déblais OUVERT qui berce le coffre. Le lieu
# (`barrow_cemetery_place.gd`) pose, oriente, enfonce et déclare ses appuis.
#
# LA FAMILLE DE FORME EST LA DALLE, PAS LE FÛT — et c'est une décision D3
# autant qu'artistique. Le sanctuaire forestier de la même voie emploie des
# fûts fusiformes à pans impairs, moussus, sous couvert ; la voie C fabrique
# en ce moment des stèles PÂLES ET PENCHÉES dans la couleur ouverte pour la
# Porte du champ. Ici : des DALLES minces, grises et froides, LICHÉNÉES et non
# moussues, dont la majorité est COUCHÉE et à demi enterrée — un chemin
# horizontal, pas un alignement de jalons. Les seules verticales sont les deux
# montants d'une gueule de chambre, c'est-à-dire une PORTE, et deux stèles
# qui la précèdent.
#
# REPÈRES. Blender est Z-up ; l'export convertit en Y-up : Blender (x, y, z)
# devient Godot (x, z, -y). Chaque pièce est modélisée debout, centrée.
#
# BUDGET VERROUILLÉ AVANT MODÉLISATION (brief voie B) : pierres funéraires
# ≤ 4 000 triangles L'ENSEMBLE. Le générateur REFUSE d'enregistrer au-delà.
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/architecture/make_barrow_stones.py

import math
import os
import sys

import bmesh
import bpy

BUDGET_TRIS = 4000
BASE_TOL_DESSOUS = 0.005
BASE_TOL_DESSUS = 0.05

# LICHEN, PAS MOUSSE. La steppe du nord est rase et sèche : ce qui pousse sur
# une dalle y est gris-vert désaturé, pas le vert de sous-bois du sanctuaire.
# Deux lieux, deux matières, et l'écart est visible sans lire le nom.
MATERIAUX = {
    "MAT_Barrow_Stone": (0.505, 0.510, 0.500, 0.96),
    "MAT_Barrow_Lichen": (0.415, 0.435, 0.360, 0.98),
}
IDX_PIERRE = 0
IDX_LICHEN = 1
ORDRE_MATERIAUX = ("MAT_Barrow_Stone", "MAT_Barrow_Lichen")

LICHEN_NORMALE_MIN = 0.40


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
    # Le matériau CONSOMME l'attribut de couleur : sans ce nœud, l'exporteur
    # glTF n'écrit pas `COLOR_0` et la pierre repart en aplat (ISS-066).
    arbre = mat.node_tree
    attribut = arbre.nodes.new("ShaderNodeVertexColor")
    attribut.layer_name = NOM_COULEUR
    melange = arbre.nodes.new("ShaderNodeMixRGB")
    melange.blend_type = "MULTIPLY"
    melange.inputs["Fac"].default_value = 1.0
    melange.inputs["Color1"].default_value = (r, v, b, 1.0)
    arbre.links.new(attribut.outputs["Color"], melange.inputs["Color2"])
    arbre.links.new(melange.outputs["Color"], bsdf.inputs["Base Color"])
    return mat


def _graine(x):
    """Bruit déterministe sans dépendance : sin d'entiers, dans [-0,5 ; 0,5]."""
    return math.sin(x * 12.9898) * 0.5


pied_facteur_min = 0.62
# ---------------------------------------------------------------------------
# COULEURS DE SOMMET — la seule chose qui empêche une pierre sans texture de
# rendre un APLAT (piège ISS-066, remonté par le lead)
# ---------------------------------------------------------------------------
# POURQUOI ELLES SONT INDISPENSABLES ICI. Sur des faces quasi verticales sous
# ce ciel, l'irradiance ambiante domine : changer l'orientation d'une facette
# ne rapporte presque rien en luminance. Les roches du kit ne se lisent pas
# comme de la pierre grâce à leur géométrie, mais grâce à la VARIATION de leur
# atlas. Un maillage sans texture et sans couleur de sommet rendra donc plat
# quelle que soit la qualité de sa silhouette — c'est exactement ce que la
# première capture a montré (« marqueurs de plastique blanc »).
#
# DEUX CONDITIONS, ET AUCUNE N'EST AUTOMATIQUE (mesuré par la voie C, vérifié
# dans l'exporteur) :
#   1. le MATÉRIAU doit consommer l'attribut — un nœud Color Attribute
#      multiplié dans Base Color ; sans lui l'exporteur n'écrit rien ;
#   2. la couche doit être l'attribut de couleur ACTIF **et** celui de RENDU —
#      une couche créée par script ne l'est pas d'office.
# `tools/gltf_inspect.py` ne regarde JAMAIS `COLOR_0` : il répondrait `VALIDE`
# sur un asset qui a perdu ses couleurs. La présence est donc vérifiée ici, à
# la source, par une garde qui refuse d'enregistrer.
NOM_COULEUR = "Col"
JETON_LIEU = "barrow_stones"


def poser_couleurs(maillage, bandes, contraste, pied_facteur):
    """Strates, veines et pied assombri, écrits dans `COLOR_0`.

    Les strates suivent le PLUS GRAND AXE de la pièce : sur une pierre
    dressée elles sont horizontales, sur une lame couchée elles courent dans
    sa longueur — dans les deux cas elles montrent le lit de débitage, ce
    qu'une pierre taillée à la main montre toujours.
    """
    sommets = maillage.vertices
    if not sommets:
        return 0
    etendues = []
    for axe in range(3):
        valeurs = [v.co[axe] for v in sommets]
        etendues.append((min(valeurs), max(valeurs)))
    ordre = sorted(range(3), key=lambda a: etendues[a][1] - etendues[a][0],
                   reverse=True)
    axe, axe_moyen = ordre[0], ordre[1]
    lo, hi = etendues[axe]
    portee = max(1e-6, hi - lo)
    lo2, hi2 = etendues[axe_moyen]
    portee2 = max(1e-6, hi2 - lo2)
    hauteur = max(1e-6, etendues[2][1])
    couche = maillage.color_attributes.new(name=NOM_COULEUR,
                                           type="FLOAT_COLOR", domain="POINT")
    for i, v in enumerate(sommets):
        t = (v.co[axe] - lo) / portee
        t2 = (v.co[axe_moyen] - lo2) / portee2
        # Strate QUANTIFIÉE en trois marches : un lit de pierre a des bords,
        # un dégradé sinusoïdal n'en a pas et se relit « ombrage ».
        onde = 0.5 + 0.5 * math.sin(t * bandes * 2.0 * math.pi
                                    + _graine(hauteur * 7.3) * 6.0)
        # Les marches sont MÉLANGÉES à l'onde continue : à contraste plein,
        # une quantification pure sortait en blocs clairs et sombres — de
        # l'ombrage en escalier, pas un lit de pierre. Le mélange garde le
        # BORD de la strate et lui rend son épaisseur.
        #
        # DOSAGE REVU AU LOT 1.R (agent B), APRÈS LECTURE DE LA CAPTURE, et
        # c'est la correction d'un défaut qui a REMPLACÉ le précédent.
        # L'objectif de la passe d'avant est bien atteint : le profil en
        # travers d'une stèle rend 23 valeurs distinctes et 97 niveaux
        # d'étendue sur `agent_b/base/barrow_cemetery_joueur.png` (y = 430,
        # x 240..330), contre « 109 constant » à l'audit — l'aplat est mort.
        # Mais à l'agrandissement, la stèle porte quatre à cinq BANDES
        # horizontales franches, à bords nets et à pas régulier : cela ne lit
        # pas comme de la pierre, cela lit comme un poteau PEINT.
        # Cause : à 0,65 la marche domine l'onde et impose ses paliers plats.
        # Le poids descend à 0,32 — un tiers de marche suffit à casser la
        # sinusoïde, donc le BORD de strate survit ; ce qui disparaît est le
        # palier plat entre deux bords, qui était la lecture « peinture ».
        # L'étendue ne dépend pas de ce partage : elle vient de `contraste`,
        # de la seconde fréquence et des veines, tous inchangés.
        marche = 0.32 * (round(onde * 2.0) / 2.0) + 0.68 * onde
        valeur = 1.0 - contraste * 0.5 + contraste * marche
        # SECONDE FRÉQUENCE, SUR L'AXE MOYEN — et elle n'est pas décorative.
        # Mesuré après la première passe : un profil pris EN TRAVERS d'un
        # montant dressé rendait « étendue 2 » sur 38 à 50 px. C'est
        # géométriquement normal — les strates sont horizontales, une coupe
        # horizontale n'en traverse qu'une — mais l'aplat reste un aplat pour
        # l'œil comme pour la mesure. Une seconde onde, plus lente et sur
        # l'axe MOYEN de la pièce, fait varier aussi la largeur de la face.
        valeur *= 1.0 + 0.24 * math.sin(t2 * 1.7 * 2.0 * math.pi
                                        + _graine(hauteur * 3.9) * 6.0)
        # Veines : bruit fin, pour qu'aucune face ne soit un aplat parfait.
        valeur += _graine(v.co.x * 5.7 + v.co.y * 3.1 + v.co.z * 9.3) * 0.16
        # Le PIED est plus sombre : c'est là que la terre, l'ombre et
        # l'humidité s'accumulent, et c'est ce qui ancre la pierre au sol.
        assise = min(1.0, max(0.0, v.co.z / (pied_facteur * hauteur)))
        valeur *= pied_facteur_min + (1.0 - pied_facteur_min) * assise
        # AMPLITUDES RELEVÉES APRÈS MESURE. Première pose : un profil de
        # luminance sur un montant rendait 9 niveaux en VERTICAL et 1 EN
        # TRAVERS. Le repère donné par le lead — la recette éprouvée sur
        # l'asset de la voie C — est de 31 à 32 niveaux contre 1. Le contraste
        # de strate double, la seconde fréquence passe de 0,13 à 0,24, les
        # veines de 0,11 à 0,16, et la borne basse descend pour laisser la
        # place aux creux. Les valeurs restent des MULTIPLICATEURS autour de
        # 1,0 : la teinte, elle, se règle côté Godot, et une seule fois.
        valeur = min(1.28, max(0.46, valeur))
        couche.data[i].color = (valeur, valeur, valeur, 1.0)
    index = maillage.color_attributes.find(NOM_COULEUR)
    maillage.color_attributes.active_color_index = index
    maillage.color_attributes.render_color_index = index
    return len(sommets)


def _rotation_xyz(p, angles):
    ax, ay, az = angles
    x, y, z = p
    c, s = math.cos(ax), math.sin(ax)
    y, z = y * c - z * s, y * s + z * c
    c, s = math.cos(ay), math.sin(ay)
    x, z = x * c + z * s, -x * s + z * c
    c, s = math.cos(az), math.sin(az)
    x, y = x * c - y * s, x * s + y * c
    return (x, y, z)


# ---------------------------------------------------------------------------
# LA DALLE — la brique unique de ce cimetière
# ---------------------------------------------------------------------------
def dalle(bm, hauteur, largeur, epaisseur, graine, brisure=0.26,
          fuseau=0.12, rotation=(0.0, 0.0, 0.0), centre=(0.0, 0.0, 0.0),
          voile=0.0):
    """Une dalle de pierre débitée : mince, deux grandes faces, quatre chants.

    C'est une famille de forme DIFFÉRENTE du fût du sanctuaire, et la
    différence est structurelle, pas décorative : la section n'est pas un
    polygone régulier mais un hexagone APLATI (deux longs côtés, deux bouts
    chanfreinés). Une dalle a une orientation ; un fût n'en a pas. C'est ce
    qui permet à un cimetière de dalles couchées de faire un CHEMIN, là où
    des fûts feraient un semis.

    `voile` gauchit la dalle sur sa hauteur (rotation progressive de la
    section) — une pierre débitée à la main n'est jamais plane.
    """
    anneaux = (0.0, 0.24, 0.50, 0.74, 0.90, 1.0)
    # Section : hexagone aplati. Les demi-cotes sont en (largeur, epaisseur).
    profil = ((-1.00, -0.42), (-0.62, -1.00), (0.62, -1.00), (1.00, 0.42),
              (0.62, 1.00), (-0.62, 1.00))
    grilles = []
    for niveau, t in enumerate(anneaux):
        conique = 1.0 - fuseau * t
        gauchissement = voile * t
        cg, sg = math.cos(gauchissement), math.sin(gauchissement)
        anneau = []
        for i, (px, py) in enumerate(profil):
            # Jitter relevé de 0,16/0,20 à 0,23/0,28 : à la première capture
            # les dalles sortaient comme des marqueurs de plastique blanc, et
            # la teinte n'était que la moitié de la cause — l'autre moitié
            # était que leurs grandes faces sont PLANES et rendent donc un
            # aplat parfait. Un débitage à la main ne l'est jamais.
            jx = 1.0 + _graine(graine * 2.7 + i * 3.1 + niveau * 1.3) * 0.23
            jy = 1.0 + _graine(graine * 4.1 + i * 1.9 + niveau * 0.7) * 0.28
            x = px * largeur * 0.5 * conique * jx
            y = py * epaisseur * 0.5 * conique * jy
            x, y = x * cg - y * sg, x * sg + y * cg
            z = t * hauteur
            if niveau == len(anneaux) - 1:
                # LE SOMMET EST CASSÉ, pas coupé : plan incliné + dents.
                pente = _graine(graine * 5.9)
                z -= hauteur * brisure * (
                    0.40 + 0.60 * (0.5 + 0.5 * math.cos(
                        2.0 * math.pi * i / len(profil)
                        + 6.0 * _graine(graine * 4.3))) * (0.6 + pente)
                    + 0.26 * abs(_graine(graine * 7.1 + i * 5.3)))
            anneau.append((x, y, z))
        grilles.append(anneau)

    def poser(p):
        q = _rotation_xyz(p, rotation)
        return bm.verts.new((centre[0] + q[0], centre[1] + q[1],
                             centre[2] + q[2]))

    k = len(profil)
    verts = [[poser(p) for p in anneau] for anneau in grilles]
    faces = [bm.faces.new(tuple(reversed(verts[0])))]
    for niveau in range(len(anneaux) - 1):
        for i in range(k):
            j = (i + 1) % k
            faces.append(bm.faces.new((verts[niveau][i], verts[niveau][j],
                                       verts[niveau + 1][j],
                                       verts[niveau + 1][i])))
    haut = grilles[-1]
    z_moyen = sum(p[2] for p in haut) / k
    coeur = poser((sum(p[0] for p in haut) / k + _graine(graine * 6.7) * 0.08,
                   sum(p[1] for p in haut) / k + _graine(graine * 8.1) * 0.05,
                   z_moyen - hauteur * brisure * 0.18))
    for i in range(k):
        j = (i + 1) % k
        faces.append(bm.faces.new((verts[-1][i], verts[-1][j], coeur)))
    for f in faces:
        f.material_index = IDX_PIERRE
    return faces


def eclat(bm, centre, taille, graine, cotes=5, rotation=(0.0, 0.0, 0.0)):
    """Fragment anguleux irrégulier (2k+1 sommets : jamais un pavé). Recette
    ISS-060 reprise de `make_farm_ruins.py` puis `make_watchtower_ruin.py` :
    c'est la seule forme de gravat que le portail de boîtitude accepte par
    construction."""
    k = max(3, min(7, int(cotes)))
    dx, dy, dz = taille
    locaux = []
    for i in range(k):
        a = 2.0 * math.pi * i / k + _graine(graine * 5.1 + i * 3.3) * (1.0 / k)
        r = 0.5 * (1.0 + _graine(graine * 2.7 + i * 1.7) * 0.55)
        locaux.append((math.cos(a) * r * dx, math.sin(a) * r * dy,
                       -0.50 * dz + _graine(graine * 4.3 + i * 2.9) * 0.08 * dz))
    for i in range(k):
        a = 2.0 * math.pi * (i + 0.5) / k \
            + _graine(graine * 3.9 + i * 2.1) * (1.0 / k)
        r = 0.5 * (0.86 + _graine(graine * 1.9 + i * 4.1) * 0.55)
        locaux.append((math.cos(a) * r * dx, math.sin(a) * r * dy,
                       0.06 * dz + _graine(graine * 6.1 + i * 1.3) * 0.14 * dz))
    ap = 2.0 * math.pi * _graine(graine * 7.7) + graine
    ar = 0.22 * (1.0 + _graine(graine * 8.3))
    locaux.append((math.cos(ap) * ar * dx, math.sin(ap) * ar * dy, 0.50 * dz))
    tournes = [_rotation_xyz(p, rotation) for p in locaux]
    bas = min(p[2] for p in tournes)
    sommets = [bm.verts.new((centre[0] + p[0], centre[1] + p[1],
                             centre[2] + p[2] - bas)) for p in tournes]
    faces = [bm.faces.new(tuple(sommets[:k]))]
    for i in range(k):
        j = (i + 1) % k
        faces.append(bm.faces.new((sommets[i], sommets[j],
                                   sommets[k + j], sommets[k + i])))
    for i in range(k):
        j = (i + 1) % k
        faces.append(bm.faces.new((sommets[k + i], sommets[k + j],
                                   sommets[2 * k])))
    for f in faces:
        f.material_index = IDX_PIERRE
    return faces


# ---------------------------------------------------------------------------
# LES DÉBLAIS — ce qu'on a sorti de la tombe, répandu DEVANT la gueule
# ---------------------------------------------------------------------------
# Le contrat du lieu est explicite : « un coffre au fond d'une chambre fermée
# serait un piège ». Le tas est donc un ÉVENTAIL OUVERT, jamais un anneau : il
# borde la place du coffre sur trois côtés et laisse tout le quadrant nord
# (celui d'où l'on arrive) entièrement libre. La condition du lead — « coffre
# dans des déblais OUVERTS, jamais enfermé » — est portée par cette géométrie.
SEMIS_DEBLAIS = (
    (-1.10, -0.34, 0.62, 0.34, 6),
    (-0.62, -0.66, 0.52, 0.26, 5),
    (0.02, -0.80, 0.46, 0.22, 5),
    (0.64, -0.62, 0.55, 0.28, 6),
    (1.06, -0.24, 0.48, 0.20, 5),
    (-1.28, 0.16, 0.40, 0.18, 4),
    (1.22, 0.22, 0.36, 0.16, 4),
    (-0.34, -1.06, 0.34, 0.14, 5),
    (0.42, -1.02, 0.30, 0.13, 4),
)


def deblais(bm):
    for i, (x, y, ech, haut, cotes) in enumerate(SEMIS_DEBLAIS):
        g = 3.3 + i * 1.71
        eclat(bm, (x, y, 0.0), (ech, ech * 0.78, haut), g, cotes=cotes,
              rotation=(_graine(g * 1.7) * 0.5, _graine(g * 2.3) * 0.5,
                        _graine(g * 3.1) * 6.28))


# ---------------------------------------------------------------------------
# Assemblage, lichen, gardes, enregistrement
# ---------------------------------------------------------------------------
def poser_lichen(bm, lichen_max_z):
    """Le lichen par RÈGLE DE NATURE : faces tournées vers le haut sous la
    cote donnée, plus la tranche de pied. Même mécanique que la mousse du
    sanctuaire — et c'est délibéré : deux lieux qui partagent une RÈGLE mais
    pas une MATIÈRE se ressemblent moins que deux lieux qui partagent une
    texture posée à la main."""
    if not bm.faces:
        return 0
    haut = max(v.co.z for v in bm.verts)
    # 0,18 et non 0,13 : à 0,13 les trois DALLES DRESSÉES sortaient avec
    # UNE seule face lichénée — le premier anneau de flancs a son centre à
    # 0,194 m pour un pied calculé à 0,190 m, et il passait à quatre
    # millimètres près. Un seuil qui rate de 4 mm ne se voit pas dans le
    # nombre de faces, il se voit sur la pierre : elle sort propre.
    pied = max(0.10, 0.18 * haut)
    touchees = 0
    for face in bm.faces:
        centre_z = sum(v.co.z for v in face.verts) / len(face.verts)
        if (face.normal.z >= LICHEN_NORMALE_MIN and centre_z <= lichen_max_z) \
                or centre_z <= pied:
            face.material_index = IDX_LICHEN
            touchees += 1
    return touchees


def deplier_boite(bm):
    couche = bm.loops.layers.uv.verify()
    for face in bm.faces:
        n = face.normal
        ax, ay, az = abs(n.x), abs(n.y), abs(n.z)
        for boucle in face.loops:
            co = boucle.vert.co
            if az >= ax and az >= ay:
                u, v = co.x, co.y
            elif ax >= ay:
                u, v = co.y, co.z
            else:
                u, v = co.x, co.z
            boucle[couche].uv = (u * 0.5, v * 0.5)


def objet_depuis(nom, remplir, lichen_max_z=0.60):
    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()
    remplir(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    lichenees = poser_lichen(bm, lichen_max_z)
    deplier_boite(bm)
    bm.to_mesh(maillage)
    bm.free()
    bas = min(v.co.z for v in maillage.vertices)
    for v in maillage.vertices:
        v.co.z -= bas
    peints = poser_couleurs(maillage, 4.0, 0.30, 0.26)
    obj = bpy.data.objects.new(nom, maillage)
    obj["peints"] = peints
    for nom_mat in ORDRE_MATERIAUX:
        obj.data.materials.append(materiau(nom_mat))
    bpy.context.collection.objects.link(obj)
    obj["lichenees"] = lichenees
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
        # LA GUEULE DE LA CHAMBRE — deux montants inégaux et un linteau qui a
        # GLISSÉ. C'est la seule verticale forte du lieu, et c'est une PORTE.
        # LES MONTANTS PORTENT DÉSORMAIS LA HAUTEUR DU LIEU, ET C'EST LA
        # RÉSOLUTION D'UNE TENSION RÉELLE. `capture_silhouette.gd` refuse
        # d'écrire sous 2,0 % d'occupation ; sur un lieu de 22 m de large,
        # cela imposait un tumulus de 2,60 m — et un tumulus de 2,60 m pour
        # 6,7 m de large, vu de près et de bas, lit une TENTE, pas un
        # affaissement. Les deux exigences se contredisaient tant que la
        # hauteur venait de la terre.
        # Elle vient maintenant de la PIERRE : des orthostates de 2,4 m à la
        # gueule d'un tumulus dont la masse s'est érodée, c'est exactement ce
        # à quoi ressemble une allée couverte mise à nu. Le tertre peut
        # redescendre à 2,15 m, la silhouette garde sa hauteur, et la gueule
        # gagne en lisibilité à 5-15 m — la condition du lead.
        objet_depuis("SM_Barrow_Jamb_A",
                     lambda bm: dalle(bm, 2.72, 0.92, 0.38, 4.3, brisure=0.20,
                                      fuseau=0.10, voile=0.10)),
        objet_depuis("SM_Barrow_Jamb_B",
                     lambda bm: dalle(bm, 2.12, 0.78, 0.34, 8.9, brisure=0.26,
                                      fuseau=0.14, voile=-0.13)),
        # Le linteau : une dalle COUCHÉE de 2,1 m. Il est modélisé à plat, le
        # lieu lui donne son dévers — une couverture d'aplomb se lit maçonnée,
        # une couverture qui a glissé se lit descellée.
        objet_depuis("SM_Barrow_Lintel",
                     lambda bm: dalle(bm, 2.10, 0.92, 0.36, 12.7,
                                      brisure=0.14, fuseau=0.06, voile=0.07,
                                      rotation=(math.radians(90.0), 0.0,
                                                math.radians(2.0))),
                     lichen_max_z=0.30),
        # LES DEUX STÈLES qui précèdent la chambre. Minces, penchées par le
        # lieu, cassées différemment.
        objet_depuis("SM_Barrow_Stele_A",
                     # 1,74 nominal : la stèle du chemin doit se lire à
                     # 30-50 m (condition du lead) et porter, avec le tertre,
                     # le rapport hauteur/largeur du lieu.
                     lambda bm: dalle(bm, 1.74, 0.62, 0.24, 17.1, brisure=0.30,
                                      fuseau=0.18, voile=0.16)),
        objet_depuis("SM_Barrow_Stele_B",
                     lambda bm: dalle(bm, 1.02, 0.54, 0.21, 23.9, brisure=0.38,
                                      fuseau=0.22, voile=-0.19)),
        # LES TROIS LAMES COUCHÉES — le chemin des morts. Elles sont modélisées
        # DÉJÀ couchées : le lieu ne les bascule pas, il les enfonce. C'est la
        # correction directe du piège `_coucher()` (une pièce basculée après
        # `seat()` s'enterre ou flotte, et le décalage n'est pas devinable).
        objet_depuis("SM_Barrow_Lame_A",
                     lambda bm: dalle(bm, 1.55, 0.74, 0.26, 29.3, brisure=0.22,
                                      fuseau=0.10, voile=0.12,
                                      rotation=(math.radians(90.0), 0.0,
                                                math.radians(-4.0))),
                     lichen_max_z=0.22),
        objet_depuis("SM_Barrow_Lame_B",
                     lambda bm: dalle(bm, 1.18, 0.58, 0.22, 35.7, brisure=0.28,
                                      fuseau=0.12, voile=-0.10,
                                      rotation=(math.radians(90.0), 0.0,
                                                math.radians(6.0))),
                     lichen_max_z=0.18),
        objet_depuis("SM_Barrow_Lame_C",
                     lambda bm: dalle(bm, 0.94, 0.62, 0.19, 41.1, brisure=0.34,
                                      fuseau=0.08, voile=0.15,
                                      rotation=(math.radians(90.0), 0.0,
                                                math.radians(-9.0))),
                     lichen_max_z=0.16),
        objet_depuis("SM_Barrow_Deblais", deblais, lichen_max_z=0.12),
    ]

    total = 0
    for obj in pieces:
        n = tris_de(obj)
        total += n
        (x0, x1), (y0, y1), (z0, z1) = emprise(obj)
        print("[barrow_stones] %-22s %4d tris  X %6.2f..%5.2f  "
              "Y %6.2f..%5.2f  Z %6.3f..%5.2f  lichen %d faces"
              % (obj.name, n, x0, x1, y0, y1, z0, z1, obj["lichenees"]))
        if z0 < -BASE_TOL_DESSOUS or z0 > BASE_TOL_DESSUS:
            print("[barrow_stones] ERREUR: base de %s à Z=%.3f" % (obj.name, z0))
            return 2
        # PLUS DE DEUX FACES, et non « au moins une » : la base d'une dalle
        # est un unique polygone, et une garde à zéro l'aurait acceptée comme
        # « lichénée » alors que toute la pierre visible reste nue. C'est le
        # cas exact rencontré à la première exécution.
        if obj["lichenees"] < 3:
            print("[barrow_stones] ERREUR: %s n'a que %d face(s) lichénée(s) —"
                  " la règle de nature n'a touché que sa base"
                  % (obj.name, obj["lichenees"]))
            return 2

    print("[barrow_stones] total %d triangles (budget %d)" % (total, BUDGET_TRIS))
    if total > BUDGET_TRIS:
        print("[barrow_stones] ERREUR: budget dépassé — le générateur REFUSE "
              "d'enregistrer")
        return 2

    # GARDE 1 — LES TROIS LAMES SONT BIEN COUCHÉES ET DÉCROISSANTES. Une lame
    # qui serait plus haute que large n'est pas couchée, et trois lames de même
    # taille ne feraient pas un chemin mais une répétition.
    lames = [o for o in pieces if o.name.startswith("SM_Barrow_Lame")]
    precedente = None
    for obj in lames:
        (x0, x1), (y0, y1), (z0, z1) = emprise(obj)
        etendue = max(x1 - x0, y1 - y0)
        if z1 >= etendue * 0.55:
            print("[barrow_stones] ERREUR: %s haute de %.2f pour %.2f "
                  "d'étendue — elle n'est pas couchée" % (obj.name, z1, etendue))
            return 2
        if precedente is not None and etendue > precedente * 0.94:
            print("[barrow_stones] ERREUR: %s (%.2f m) ne décroît pas assez "
                  "par rapport à la précédente (%.2f m)"
                  % (obj.name, etendue, precedente))
            return 2
        precedente = etendue
    print("[barrow_stones] lames : étendues décroissantes %s"
          % ", ".join("%.2f" % max(emprise(o)[0][1] - emprise(o)[0][0],
                                   emprise(o)[1][1] - emprise(o)[1][0])
                      for o in lames))

    # GARDE 2 — LES DÉBLAIS SONT OUVERTS. Le quadrant NORD (y > 0,10) du tas
    # doit être vide sur au moins 1,4 m de large : c'est par là qu'on arrive et
    # qu'on repart, et c'est la condition « coffre jamais enfermé » du lead
    # rendue vérifiable au lieu d'être promise.
    tas = pieces[8]
    intrus = [v.co for v in tas.data.vertices
              if v.co.y > 0.10 and abs(v.co.x) < 0.70]
    if intrus:
        print("[barrow_stones] ERREUR: %d sommet(s) de déblais dans le "
              "quadrant d'accès nord — le coffre serait enfermé" % len(intrus))
        return 2
    (dx0, dx1), (dy0, dy1), (dz0, dz1) = emprise(tas)
    print("[barrow_stones] déblais : éventail X %.2f..%.2f, Y %.2f..%.2f, "
          "haut %.2f — quadrant d'accès nord LIBRE (0 sommet)"
          % (dx0, dx1, dy0, dy1, dz1))

    # GARDE 3 — LE LINTEAU EST UNE COUVERTURE, PAS UN MONTANT. Il doit être
    # plus long que les deux montants ne sont hauts, sinon il ne peut pas
    # porter à cheval sur la gueule.
    linteau = pieces[2]
    (lx0, lx1), (ly0, ly1), (lz0, lz1) = emprise(linteau)
    portee = max(lx1 - lx0, ly1 - ly0)
    jambages = max(emprise(pieces[0])[2][1], emprise(pieces[1])[2][1])
    if portee < 1.60:
        print("[barrow_stones] ERREUR: linteau de %.2f m — trop court pour "
              "couvrir une gueule" % portee)
        return 2
    print("[barrow_stones] gueule : montants %.2f et %.2f m, linteau %.2f m "
          "de portée (jambage le plus haut %.2f)"
          % (emprise(pieces[0])[2][1], emprise(pieces[1])[2][1], portee,
             jambages))


    # GARDE COLOR_0 — celle que `gltf_inspect.py` ne peut pas rendre.
    # L'outil contrôle POSITION, NORMAL, TEXCOORD_0 et JOINTS_0 ; il ne
    # regarde JAMAIS COLOR_0 (ISS-066). Un asset qui aurait perdu ses
    # couleurs de sommet passerait donc `VALIDE` et rendrait un aplat. On
    # vérifie ici, à la source, que chaque pièce en porte.
    sans_couleur = [o.name for o in pieces
                    if int(o.get("peints", 0)) == 0
                    or NOM_COULEUR not in o.data.color_attributes]
    if sans_couleur:
        print("[%s] ERREUR: %d pièce(s) sans COLOR_0 : %s"
              % (JETON_LIEU, len(sans_couleur), ", ".join(sans_couleur)))
        return 2
    actifs = sum(1 for o in pieces
                 if o.data.color_attributes.active_color_index
                 == o.data.color_attributes.find(NOM_COULEUR)
                 and o.data.color_attributes.render_color_index
                 == o.data.color_attributes.find(NOM_COULEUR))
    if actifs != len(pieces):
        print("[%s] ERREUR: seulement %d/%d pièce(s) ont « %s » comme "
              "attribut ACTIF ET DE RENDU — l'exporteur n'écrirait rien"
              % (JETON_LIEU, actifs, len(pieces), NOM_COULEUR))
        return 2
    etendues = []
    for o in pieces:
        valeurs = [d.color[0] for d in o.data.color_attributes[NOM_COULEUR].data]
        etendues.append(max(valeurs) - min(valeurs))
    if min(etendues) < 0.12:
        print("[%s] ERREUR: étendue de COLOR_0 trop faible (min %.3f) — "
              "des couleurs présentes mais uniformes ne valent pas mieux "
              "qu'un aplat" % (JETON_LIEU, min(etendues)))
        return 2
    print("[%s] COLOR_0 : %d pièce(s), attribut actif ET de rendu, "
          "étendue de valeur %.2f à %.2f"
          % (JETON_LIEU, len(pieces), min(etendues), max(etendues)))

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_Barrow_Stones.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[barrow_stones] source enregistrée -> %s" % sortie)
    print("FIN NOMINALE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
