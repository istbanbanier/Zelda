# SOURCE DE GÉNÉRATION REPRODUCTIBLE — Vestige du sanctuaire forestier
# (V2.3-B LOT 1.R, voie B).
#
# POURQUOI CE FICHIER EXISTE. Le gate visuel a rejeté le sanctuaire bâti en
# modules de kit : « les murs beige rectangulaires restent du graybox ». La
# cause est nommée et mesurée : l'anneau était fait de `SM_Dungeon_PillarStub`
# (moignons à faces planes) et l'autel d'un `SM_Dungeon_ArchBlock` (un cube),
# et cette famille de trimsheet rend TERRACOTTA/BEIGE sous la lumière de ce
# monde. Aucune teinte ne répare une forme de cube : il faut d'autres formes.
#
# CE QUE LE GLB PORTE. Les neuf pièces de pierre du vestige, chacune modélisée
# sur SON origine, base à z = 0, sans implantation : le seuil (deux montants
# franchement inégaux et une marche enfoncée), trois socles rompus de profils
# tous différents, la pierre couchée qui barre la nef, la table d'offrande
# FENDUE avec ses deux dés, et la pierre de chevet. Le lieu
# (`forest_shrine_place.gd`) pose chaque pièce sur SON sol, déclare ses appuis
# et garde les contrats — seul le langage de forme change.
#
# LA COMPOSITION EST « LA NEF AVALÉE » (compo B, arbitrée par le lead) : un
# AXE court nord→sud, pas un anneau. Ce choix est aussi une décision D3 : le
# cercle de pierres levées INTACT appartient à `watchers_circle` (lot futur),
# et la voie C fabrique en ce moment des stèles pâles et penchées pour la
# Porte du champ. Les pierres d'ici sont donc grises-vertes, moussues, BASSES
# et couchées pour la plupart, et leur seule verticale (le chevet) est un
# DOSSIER derrière une table, jamais un jalon planté dans le vide.
#
# REPÈRES. Blender est Z-up ; l'export convertit en Y-up : Blender (x, y, z)
# devient Godot (x, z, -y). Chaque pièce est modélisée debout et centrée ;
# c'est le lieu qui l'oriente.
#
# BUDGET VERROUILLÉ AVANT MODÉLISATION (brief voie B) : sanctuaire ≤ 6 000
# triangles. Le générateur REFUSE d'enregistrer au-delà.
#
# PLAFOND D'IDENTITÉ. « Invisible depuis la route » impose que rien du bâti ne
# dépasse 2,4 m. Le générateur refuse toute pièce au-delà de 2,20 m : les
# 20 cm restants sont la marge de terrain, et le lieu imprime la marge RÉELLE
# mesurée sur le nœud posé.
#
# MATÉRIAUX. Deux : `MAT_Shrine_Stone` et `MAT_Shrine_Moss`. La couleur plate
# n'est pas la matière finale — le lieu applique un aplat painterly calibré
# sur CAPTURE RENDUE (gain de lumière non linéaire ≈ 1,8, scripts/CLAUDE.md).
# La mousse est posée ici par une RÈGLE DE NATURE et non à la main : toute
# face tournée vers le haut au-dessous d'une cote donnée est moussue. C'est
# pour cela que les socles bas et la pierre couchée verdissent pendant que le
# chevet reste sec en haut.
#
# Usage :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/architecture/make_forest_shrine.py

import math
import os
import sys

import bmesh
import bpy

BUDGET_TRIS = 6000
PLAFOND_IDENTITE = 2.20
BASE_TOL_DESSOUS = 0.005
BASE_TOL_DESSUS = 0.05

MATERIAUX = {
    "MAT_Shrine_Stone": (0.470, 0.470, 0.445, 0.96),
    "MAT_Shrine_Moss": (0.300, 0.360, 0.235, 0.98),
}
IDX_PIERRE = 0
IDX_MOUSSE = 1
ORDRE_MATERIAUX = ("MAT_Shrine_Stone", "MAT_Shrine_Moss")

# Cote au-dessous de laquelle une face tournée vers le haut est moussue.
# 1,00 m : la mousse d'un sous-bois monte à hauteur de genou, pas au sommet
# d'un menhir battu par la pluie.
# 1,15 et non 1,00, et la chaussette de pied passe de 0,17 à 0,30 de la
# hauteur : l'audit a mesuré « cinq plaques grises verticales, sans mousse »,
# et l'intention de l'addendum est « une construction absorbée par arbres et
# MOUSSE ». Une règle de nature trop timide donne des pierres propres.
MOUSSE_Z_DEFAUT = 1.15
MOUSSE_NORMALE_MIN = 0.45


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
    """Bruit déterministe sans dépendance : sin d'entiers, dans [-0,5 ; 0,5].

    Même fonction que `make_watchtower_ruin.py` — deux générateurs de la même
    voie doivent produire deux fois la même pierre s'ils reçoivent la même
    graine, sinon une régression visuelle compare deux mondes.
    """
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
JETON_LIEU = "forest_shrine"


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
        # Les marches sont MÉLANGÉES à l'onde continue (65 / 35) : à
        # contraste plein, une quantification pure sortait en blocs clairs et
        # sombres — de l'ombrage en escalier, pas un lit de pierre. Le
        # mélange garde le BORD de la strate et lui rend son épaisseur.
        marche = 0.65 * (round(onde * 2.0) / 2.0) + 0.35 * onde
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
# LA PIERRE LEVÉE ROMPUE — la brique unique de tout ce vestige
# ---------------------------------------------------------------------------
def pierre_rompue(bm, hauteur, rx, ry, graine, cotes=7, brisure=0.30,
                  fuseau=0.20, rotation=(0.0, 0.0, 0.0), centre=(0.0, 0.0, 0.0)):
    """Un fût de pierre à `cotes` pans, cassé net en haut.

    Trois propriétés portent la lecture, et aucune n'est décorative :
      * `cotes` impair (5 ou 7) — un nombre pair rend des pans opposés
        parallèles, et deux pans parallèles relisent « boîte » de profil ;
      * `fuseau` — le fût se resserre vers le haut, comme une pierre dressée
        que l'on a plantée par son gros bout ;
      * `brisure` — le sommet n'est PAS un couvercle : chaque sommet du
        dernier anneau reçoit sa propre cote, et l'éventail se referme sur un
        point plus bas que le plus haut d'entre eux. On lit une CASSURE.
    """
    k = max(5, int(cotes))
    anneaux = (0.0, 0.19, 0.42, 0.66, 0.86, 1.0)
    grilles = []
    for niveau, t in enumerate(anneaux):
        conique = 1.0 - fuseau * t
        anneau = []
        for i in range(k):
            a = 2.0 * math.pi * i / k \
                + _graine(graine * 3.1 + i * 1.7 + niveau * 0.9) * (1.1 / k)
            # 0,27 et non 0,19 : à 0,19 les fûts sortaient en dalles LISSES,
            # et la capture les a montrés comme des blocs de béton pâle. Le
            # jitter de rayon est ce qui donne aux pans leur inégalité, donc
            # à la lumière rasante quelque chose à accrocher.
            r = conique * (1.0 + _graine(graine * 2.3 + i * 2.9
                                         + niveau * 1.3) * 0.27)
            z = t * hauteur
            if niveau == len(anneaux) - 1:
                # LA CASSURE : plan incliné + dents. L'inclinaison suit
                # `graine`, donc deux pierres ne cassent jamais pareil.
                pente = _graine(graine * 5.9)
                a_pente = 2.0 * math.pi * _graine(graine * 4.3)
                z -= hauteur * brisure * (
                    0.45
                    + 0.55 * (0.5 + 0.5 * math.cos(a - a_pente)) * (0.6 + pente)
                    + 0.28 * abs(_graine(graine * 7.1 + i * 5.3)))
            anneau.append((math.cos(a) * rx * r, math.sin(a) * ry * r, z))
        grilles.append(anneau)

    def poser(p):
        q = _rotation_xyz(p, rotation)
        return bm.verts.new((centre[0] + q[0], centre[1] + q[1],
                             centre[2] + q[2]))

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
    cx = sum(p[0] for p in haut) / k + _graine(graine * 6.7) * rx * 0.25
    cy = sum(p[1] for p in haut) / k + _graine(graine * 8.1) * ry * 0.25
    coeur = poser((cx, cy, z_moyen - hauteur * brisure * 0.22))
    for i in range(k):
        j = (i + 1) % k
        faces.append(bm.faces.new((verts[-1][i], verts[-1][j], coeur)))
    for f in faces:
        f.material_index = IDX_PIERRE
    return faces


# ---------------------------------------------------------------------------
# LA TABLE D'OFFRANDE FENDUE — l'élément héroïque du lieu
# ---------------------------------------------------------------------------
def _contour_ellipse(rx, ry, n, graine):
    points = []
    for i in range(n):
        a = 2.0 * math.pi * i / n + _graine(graine + i * 1.9) * (0.9 / n)
        r = 1.0 + _graine(graine * 2.7 + i * 3.1) * 0.14
        points.append((math.cos(a) * rx * r, math.sin(a) * ry * r))
    return points


def _prisme_plan(bm, contour, z_bas, epaisseur, materiau_idx,
                 rotation=(0.0, 0.0, 0.0), centre=(0.0, 0.0, 0.0)):
    """Extrude un contour horizontal (x, y) sur `epaisseur` en z."""
    def poser(p):
        q = _rotation_xyz(p, rotation)
        return bm.verts.new((centre[0] + q[0], centre[1] + q[1],
                             centre[2] + q[2]))

    haut = [poser((x, y, z_bas + epaisseur)) for x, y in contour]
    bas = [poser((x, y, z_bas)) for x, y in contour]
    faces = [bm.faces.new(tuple(haut)), bm.faces.new(tuple(reversed(bas)))]
    n = len(contour)
    for i in range(n):
        j = (i + 1) % n
        faces.append(bm.faces.new((haut[i], haut[j], bas[j], bas[i])))
    for f in faces:
        f.material_index = materiau_idx
    return faces


def table_fendue(bm):
    """Une dalle FENDUE en deux, dont une moitié a glissé.

    La fente n'est pas un trait droit : elle traverse la dalle par trois
    points intermédiaires décalés. Les deux moitiés sont deux solides
    distincts — c'est ce qui permet à l'une de basculer sans que la
    géométrie mente sur ce qui la porte.
    """
    # Deux dés de support, irréguliers, hauteurs légèrement différentes.
    pierre_rompue(bm, 0.86, 0.30, 0.26, 21.7, cotes=5, brisure=0.16,
                  fuseau=0.10, centre=(-0.50, -0.07, 0.0))
    pierre_rompue(bm, 0.82, 0.27, 0.25, 33.1, cotes=5, brisure=0.14,
                  fuseau=0.10, centre=(0.47, 0.09, 0.0))

    contour = _contour_ellipse(0.80, 0.54, 14, 9.3)
    n = len(contour)
    # Les deux bouts de la fente : deux sommets à peu près opposés.
    a0, a1 = 2, 2 + n // 2
    fente = []
    p0, p1 = contour[a0 % n], contour[a1 % n]
    for i in (1, 2, 3):
        t = i / 4.0
        fente.append((
            p0[0] + (p1[0] - p0[0]) * t + _graine(9.3 * i + 4.1) * 0.17,
            p0[1] + (p1[1] - p0[1]) * t + _graine(9.3 * i + 7.7) * 0.13))
    moitie_a = [contour[i % n] for i in range(a0, a1 + 1)] \
        + list(reversed(fente))
    moitie_b = [contour[i % n] for i in range(a1, a0 + n + 1)] + fente
    # La moitié A repose ; la moitié B a GLISSÉ : 4,5° de bascule et 4 cm
    # plus bas. Une dalle fendue dont les deux moitiés restent d'aplomb se
    # relit « joint de maçonnerie », pas « cassure ».
    _prisme_plan(bm, moitie_a, 0.0, 0.13, IDX_PIERRE, centre=(0.0, 0.0, 0.76))
    _prisme_plan(bm, moitie_b, 0.0, 0.13, IDX_PIERRE,
                 rotation=(0.0, math.radians(4.5), math.radians(-3.0)),
                 centre=(0.03, -0.02, 0.72))


def marche_enfoncee(bm):
    """La marche du seuil : une dalle usée, plus large que haute, dont un
    coin s'est enfoncé. C'est le seul élément du vestige qui soit encore à
    peu près à sa place, et c'est ce qui fait lire « on entre ici »."""
    contour = _contour_ellipse(0.80, 0.46, 11, 15.9)
    _prisme_plan(bm, contour, 0.0, 0.22, IDX_PIERRE,
                 rotation=(math.radians(3.5), math.radians(-2.2), 0.0))
    # Deux éclats détachés au bord, comme un nez de marche usé.
    pierre_rompue(bm, 0.13, 0.19, 0.15, 41.3, cotes=5, brisure=0.42,
                  fuseau=0.05, centre=(0.62, -0.34, 0.0))
    pierre_rompue(bm, 0.10, 0.15, 0.13, 47.9, cotes=5, brisure=0.45,
                  fuseau=0.05, centre=(-0.71, 0.29, 0.0))


# ---------------------------------------------------------------------------
# Assemblage, mousse, gardes, enregistrement
# ---------------------------------------------------------------------------
def poser_mousse(bm, mousse_max_z):
    """La mousse par RÈGLE DE NATURE, en DEUX termes.

    Le premier seul ne suffisait pas, et c'est le générateur qui l'a dit :
    à la première exécution, `SM_Shrine_Montant_A` sortait avec ZÉRO face
    moussue. Un fût dressé n'a que des flancs verticaux (normale z ≈ 0) et
    une cassure à 1,39 m, au-dessus de la cote de mousse — la règle ne
    pouvait rien toucher. La garde a rougi au lieu de laisser passer une
    pierre nue ; c'est exactement ce qu'on lui demande.

      1. faces tournées VERS LE HAUT sous la cote donnée — la mousse des
         creux et des dessus de pierres basses ;
      2. la CHAUSSETTE DE PIED : la première tranche de hauteur de chaque
         pierre, quelle que soit l'orientation de la face. En sous-bois la
         mousse monte le long du fût depuis la litière ; sans ce terme, les
         verticales du sanctuaire resteraient de la pierre propre.
    """
    if not bm.faces:
        return 0
    haut = max(v.co.z for v in bm.verts)
    pied = max(0.16, 0.30 * haut)
    touchees = 0
    for face in bm.faces:
        centre_z = sum(v.co.z for v in face.verts) / len(face.verts)
        vers_le_haut = (face.normal.z >= MOUSSE_NORMALE_MIN
                        and centre_z <= mousse_max_z)
        if vers_le_haut or centre_z <= pied:
            face.material_index = IDX_MOUSSE
            touchees += 1
    return touchees


def deplier_boite(bm):
    """UV0 par projection boîte. Le lieu n'applique PAS de carte sur ce
    vestige (aplat painterly), mais un GLB sans UV0 se comporte mal à
    l'import et interdit tout habillage ultérieur : on les déplie."""
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


def objet_depuis(nom, remplir, mousse_max_z=MOUSSE_Z_DEFAUT):
    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()
    remplir(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    moussues = poser_mousse(bm, mousse_max_z)
    deplier_boite(bm)
    bm.to_mesh(maillage)
    bm.free()
    bas = min(v.co.z for v in maillage.vertices)
    for v in maillage.vertices:
        v.co.z -= bas
    peints = poser_couleurs(maillage, 3.0, 0.26, 0.30)
    obj = bpy.data.objects.new(nom, maillage)
    obj["peints"] = peints
    for nom_mat in ORDRE_MATERIAUX:
        obj.data.materials.append(materiau(nom_mat))
    bpy.context.collection.objects.link(obj)
    obj["moussues"] = moussues
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
        # LE SEUIL — deux montants FRANCHEMENT inégaux (1,62 et 1,14 m) : une
        # porte se lit à l'inégalité, deux jumeaux se lisent « portique ».
        objet_depuis("SM_Shrine_Montant_A",
                     lambda bm: pierre_rompue(bm, 1.82, 0.29, 0.21, 3.7,
                                              cotes=7, brisure=0.24,
                                              fuseau=0.24)),
        objet_depuis("SM_Shrine_Montant_B",
                     lambda bm: pierre_rompue(bm, 1.44, 0.24, 0.26, 11.3,
                                              cotes=5, brisure=0.40,
                                              fuseau=0.18)),
        objet_depuis("SM_Shrine_Step", marche_enfoncee),
        # LES TROIS SOCLES — profils tous différents (nombre de pans, fuseau,
        # brisure), et c'est vérifié plus bas, pas espéré.
        objet_depuis("SM_Shrine_Socle_A",
                     lambda bm: pierre_rompue(bm, 1.13, 0.27, 0.23, 5.1,
                                              cotes=7, brisure=0.34,
                                              fuseau=0.26)),
        objet_depuis("SM_Shrine_Socle_B",
                     lambda bm: pierre_rompue(bm, 0.94, 0.32, 0.20, 17.9,
                                              cotes=5, brisure=0.46,
                                              fuseau=0.12)),
        objet_depuis("SM_Shrine_Socle_C",
                     lambda bm: pierre_rompue(bm, 0.70, 0.22, 0.30, 23.3,
                                              cotes=7, brisure=0.52,
                                              fuseau=0.08)),
        # LA PIERRE COUCHÉE — un fût de 1,95 m basculé de 90° : c'est la MÊME
        # famille que les montants, tombée. On l'enjambe pour approcher.
        objet_depuis("SM_Shrine_Fallen",
                     lambda bm: pierre_rompue(bm, 2.15, 0.30, 0.24, 29.1,
                                              cotes=7, brisure=0.28,
                                              fuseau=0.22,
                                              rotation=(math.radians(90.0),
                                                        0.0,
                                                        math.radians(6.0))),
                     mousse_max_z=0.45),
        objet_depuis("SM_Shrine_Table", table_fendue, mousse_max_z=0.62),
        # LE CHEVET — la SEULE verticale du lieu, et un dossier, pas un jalon.
        objet_depuis("SM_Shrine_Chevet",
                     lambda bm: pierre_rompue(bm, 2.33, 0.46, 0.24, 37.7,
                                              cotes=7, brisure=0.22,
                                              fuseau=0.30)),
    ]

    total = 0
    hauteur_max = 0.0
    for obj in pieces:
        n = tris_de(obj)
        total += n
        (x0, x1), (y0, y1), (z0, z1) = emprise(obj)
        hauteur_max = max(hauteur_max, z1)
        print("[forest_shrine] %-24s %4d tris  X %6.2f..%5.2f  "
              "Y %6.2f..%5.2f  Z %6.3f..%5.2f  mousse %d faces"
              % (obj.name, n, x0, x1, y0, y1, z0, z1, obj["moussues"]))
        if z0 < -BASE_TOL_DESSOUS or z0 > BASE_TOL_DESSUS:
            print("[forest_shrine] ERREUR: base de %s à Z=%.3f" % (obj.name, z0))
            return 2
        if obj["moussues"] == 0:
            print("[forest_shrine] ERREUR: %s n'a aucune face moussue — la "
                  "règle de nature n'a rien touché" % obj.name)
            return 2

    print("[forest_shrine] total %d triangles (budget %d)" % (total, BUDGET_TRIS))
    if total > BUDGET_TRIS:
        print("[forest_shrine] ERREUR: budget dépassé — le générateur REFUSE "
              "d'enregistrer")
        return 2

    # GARDE 1 — LE PLAFOND D'IDENTITÉ. « Invisible depuis la route » est une
    # contrainte, pas une décoration : aucune pièce au-dessus de 2,20 m, les
    # 20 cm restants étant la marge de terrain sous le plafond de 2,40 m.
    if hauteur_max > PLAFOND_IDENTITE:
        print("[forest_shrine] ERREUR: pièce la plus haute %.2f m > plafond "
              "%.2f m" % (hauteur_max, PLAFOND_IDENTITE))
        return 2
    print("[forest_shrine] pièce la plus haute : %.2f m (plafond générateur "
          "%.2f m, plafond d'identité du lieu 2,40 m)"
          % (hauteur_max, PLAFOND_IDENTITE))

    # GARDE 2 — LES PROFILS SONT VRAIMENT DIFFÉRENTS. Le reproche du gate est
    # la RÉPÉTITION ; trois socles au même gabarit la reproduiraient sous un
    # autre nom. On compare hauteur ET emprise au sol, deux à deux.
    socles = [o for o in pieces if o.name.startswith("SM_Shrine_Socle")]
    gabarits = []
    for obj in socles:
        (x0, x1), (y0, y1), (z0, z1) = emprise(obj)
        gabarits.append((obj.name, z1, (x1 - x0) * (y1 - y0)))
    for i in range(len(gabarits)):
        for j in range(i + 1, len(gabarits)):
            na, ha, aa = gabarits[i]
            nb, hb, ab = gabarits[j]
            dh = abs(ha - hb) / max(ha, hb)
            da = abs(aa - ab) / max(aa, ab)
            if dh < 0.12 and da < 0.12:
                print("[forest_shrine] ERREUR: %s et %s ont le même gabarit "
                      "(Δh %.1f %%, Δaire %.1f %%)" % (na, nb, dh * 100.0,
                                                       da * 100.0))
                return 2
    print("[forest_shrine] socles : %s"
          % ", ".join("%s h=%.2f aire=%.3f" % g for g in gabarits))

    # GARDE 3 — LA TABLE EST FENDUE, ET LA FENTE SE VOIT. Deux moitiés
    # distinctes séparées d'au moins 2 cm à hauteur de dalle : une fente que
    # l'on ne voit pas est un joint, et un joint n'est pas une histoire.
    table = pieces[7]
    dalle = [v.co for v in table.data.vertices if v.co.z > 0.66]
    if len(dalle) < 24:
        print("[forest_shrine] ERREUR: la dalle de la table est absente "
              "(%d sommets au-dessus de 0,66 m)" % len(dalle))
        return 2
    ecarts = [abs(a.z - b.z) for a in dalle for b in dalle
              if abs(a.x - b.x) < 0.09 and abs(a.y - b.y) < 0.09]
    glissement = max(ecarts) if ecarts else 0.0
    if glissement < 0.02:
        print("[forest_shrine] ERREUR: les deux moitiés de la table sont "
              "d'aplomb (glissement %.3f m) — la cassure ne se lit pas"
              % glissement)
        return 2
    print("[forest_shrine] table : %d sommets de dalle, glissement %.3f m"
          % (len(dalle), glissement))


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
                          "SM_Shrine_Vestige.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[forest_shrine] source enregistrée -> %s" % sortie)
    print("FIN NOMINALE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
