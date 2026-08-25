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
                  fuseau=0.20, rotation=(0.0, 0.0, 0.0), centre=(0.0, 0.0, 0.0),
                  anneaux=None):
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
    # `anneaux` réduit délibérément pour les blocs d'un muret : sept blocs à
    # six anneaux mangeaient 2 038 triangles pour un seul pan de mur, et le
    # budget de 6 000 est VERROUILLÉ AVANT MODÉLISATION — on ne le relève pas
    # pour faire entrer ce qu'on vient de dessiner.
    if anneaux is None:
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
# LE MURET ROMPU — LOT 1.R.1, ce qui remplace les six socles et les quatre
# marques d'angle
# ---------------------------------------------------------------------------
# CE QUE LE VERDICT DIT, ET CE QU'IL NE DIT PAS. Codex rejette le lieu parce
# que « dans la caméra joueur, l'arbre central masque le lieu ». C'est un
# problème de plan, traité côté `forest_shrine_place.gd`. Mais l'exigence de
# niveau qui l'accompagne — « une petite ruine brisée, moussue, ENRACINÉE :
# blocs irréguliers solidaires », « pas de cercle de pierres, pas d'amas
# décoratif » — est un problème de VOCABULAIRE, et il est ici.
#
# Dix pièces isolées et dressées, quel que soit leur profil, se lisent comme un
# semis de pierres levées. Une enceinte de ruine, elle, est faite de blocs
# LIÉS : ils se touchent, ils partagent une assise, leur crête est rompue, et
# elle s'interrompt là où le mur est tombé. Trois murets remplacent donc les
# dix pièces — sept modules RENDUS au budget D7, qui était à 40 pile.
#
# Le second effet est la hiérarchie, et il est mesurable : le plus haut socle
# faisait 1,13 m contre 2,01 m pour le cœur, soit un rapport de 1,8. Les
# murets plafonnent à 0,85 m : le rapport passe à 2,4, et le cœur domine.
def muret_rompu(bm, longueur, hauteur, graine, n=5):
    """Un pan de muret : `n` blocs LIÉS sur une assise commune, crête rompue.

    Les blocs se recouvrent d'un quart de leur largeur — c'est ce qui fait
    « solidaire » plutôt que « posé à côté ». Un bloc de la file est
    volontairement arasé au tiers : c'est la brèche, et sans elle un muret de
    crête irrégulière reste un mur, pas une ruine.
    """
    pas = longueur / float(n)
    creux = 1 + int(abs(_graine(graine * 5.3)) * 4.0) % max(1, n - 2)
    for i in range(n):
        t = (i + 0.5) / n
        x = -longueur * 0.5 + longueur * t
        y = _graine(graine * 2.1 + i * 1.7) * 0.17
        h = hauteur * (0.60 + 0.40 * (0.5 + 0.5 * math.cos(
            (t - 0.26) * 5.1 + _graine(graine) * 3.0)))
        h *= 1.0 + _graine(graine * 3.3 + i * 2.9) * 0.24
        if i == creux:
            h *= 0.34
        pierre_rompue(bm, max(0.16, h), pas * 0.64,
                      0.20 + 0.07 * abs(_graine(graine * 1.9 + i)),
                      graine * 1.31 + i * 3.7,
                      cotes=5, brisure=0.36, fuseau=0.12,
                      rotation=(0.0, 0.0, _graine(graine * 4.7 + i) * 0.55),
                      centre=(x, y, 0.0), anneaux=(0.0, 0.34, 0.70, 1.0))
    # Deux blocs tombés au pied, du côté où la crête est la plus basse : la
    # pierre qui manque en haut est celle qui est par terre.
    for k, (dx, dy, hh) in enumerate(((-0.18, 0.34, 0.19),
                                      (0.26, -0.31, 0.15))):
        pierre_rompue(bm, hh, 0.26, 0.21, graine * 2.7 + k * 5.9,
                      cotes=5, brisure=0.48, fuseau=0.06,
                      rotation=(math.radians(90.0), 0.0,
                                _graine(graine + k) * 1.2),
                      centre=(-longueur * 0.5 + longueur * (creux + 0.5) / n
                              + dx, dy, 0.0),
                      anneaux=(0.0, 0.38, 1.0))


# ---------------------------------------------------------------------------
# LA BORDURE DE NEF — LOT 1.R.2, CE QUI REND L'AXE VISIBLE
# ---------------------------------------------------------------------------
# CE QUE CODEX A VU : « le seuil et l'axe rituel ne sont pas immédiatement
# lisibles ». Pour l'axe, la cause était nommable et elle n'était pas une
# affaire de composition : l'axe existait UNIQUEMENT sous forme de dallage au
# sol (neuf `Floor_UnevenBrick` enfoncés de 7 à 14 cm). Or un sol PLAT ne se
# voit pas depuis une caméra qui rase l'herbe à 10 m — l'herbe du semis V2.2
# monte plus haut que les dalles. La capture héritée le montre : sur
# `lot1r1/revue_intermediaire/vues/forest_shrine_joueur.png`, pas une seule
# dalle n'est discernable, alors que neuf sont posées.
#
# CE QUI SE VOIT DANS L'HERBE, C'EST CE QUI EN DÉPASSE. L'axe devient donc
# deux rangées de bornes basses — 0,46 m au seuil, 0,26 m au cœur — au lieu
# d'un pavage. Trois propriétés portent la lecture :
#
#   * elles DÉCROISSENT du seuil vers le cœur. Une rangée de hauteur
#     constante, vue en enfilade, plonge d'autant plus vite qu'elle s'éloigne
#     et se referme sur le sol ; une rangée qui décroît lentement garde une
#     ligne franche jusqu'au cœur, et cette ligne EST l'axe ;
#   * elles sont LIÉES par une assise plate à demi enterrée. C'est la leçon
#     déjà payée sur l'enceinte (« blocs irréguliers solidaires », pas un
#     semis) : quatre bornes posées à côté restent quatre cailloux ;
#   * elles sont modélisées le long de Blender +y, donc de Godot −z : le lieu
#     les pose avec le lacet de nef, et le gros bout regarde le seuil.
#
# Une rangée = UNE pièce, donc un module. Huit bornes éparses en auraient
# coûté huit au budget D7, qui plafonne à 40 pour un vestige.
def bordure_de_nef(bm, longueur, graine, n=4, h_seuil=0.46, h_coeur=0.26):
    """Une rangée de bornes basses liées par une assise, décroissante."""
    # L'ASSISE — plate, large comme les bornes, enterrée aux deux tiers par le
    # lieu. Sans elle la rangée n'a pas de ligne de pied et se lit en pièces.
    demi = longueur * 0.5
    assise = []
    # DEUX POINTS PAR CÔTÉ — UN QUAD, ET C'EST LE BUDGET QUI L'A DIT, TROIS
    # FOIS DE SUITE. Le générateur a refusé d'enregistrer à neuf points
    # (6 338 tris pour 6 000), puis à trois points avec quatre anneaux
    # (6 108), puis à trois points avec trois anneaux (6 004 — quatre
    # triangles). Le budget est verrouillé AVANT modélisation et ne se relève
    # pas pour faire entrer ce qu'on vient de dessiner : c'est l'assise qui
    # cède, parce qu'elle est enterrée aux deux tiers par le lieu et que
    # personne n'a jamais vu son contour.
    pas_a = 2
    for i in range(pas_a):
        t = i / float(pas_a - 1)
        assise.append((0.17 + _graine(graine * 1.7 + i * 2.3) * 0.05,
                       -demi + longueur * t))
    for i in range(pas_a):
        t = 1.0 - i / float(pas_a - 1)
        assise.append((-0.17 + _graine(graine * 2.9 + i * 3.1) * 0.05,
                       -demi + longueur * t))
    _prisme_plan(bm, assise, 0.0, 0.11, IDX_PIERRE)
    # LES BORNES. `y` va du cœur (−demi) au seuil (+demi) : la plus haute est
    # au seuil, et c'est ce qui donne à la rangée sa pente lisible.
    for i in range(n):
        t = (i + 0.5) / n
        y = -demi + longueur * t
        h = h_coeur + (h_seuil - h_coeur) * t
        h *= 1.0 + _graine(graine * 3.7 + i * 1.9) * 0.18
        pierre_rompue(bm, h, 0.21 + 0.05 * abs(_graine(graine * 2.3 + i)),
                      0.18 + 0.04 * abs(_graine(graine * 4.1 + i)),
                      graine * 1.7 + i * 4.3,
                      cotes=5, brisure=0.40, fuseau=0.16,
                      rotation=(0.0, 0.0, _graine(graine * 5.1 + i) * 0.7),
                      centre=(_graine(graine * 6.3 + i) * 0.09, y, 0.06),
                      # TROIS ANNEAUX. À quatre, le générateur a refusé une
                      # SECONDE fois (6 108 pour 6 000). Une borne de 0,30 m
                      # vue à 8 m sous-tend 37 pixels de haut : le quatrième
                      # anneau n'y était visible par personne.
                      anneaux=(0.0, 0.45, 1.0))


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



# ---------------------------------------------------------------------------
# LE CŒUR RITUEL — UNE SILHOUETTE À LUI, ET C'EST TOUTE LA CORRECTION
# ---------------------------------------------------------------------------
# POURQUOI CETTE PIÈCE REMPLACE LA TABLE **ET** LE CHEVET.
#
# Constat que j'ai fait moi-même sur `agent_b/it/t2/shrine_gp_nef.png`, et que
# le lead a retenu comme cause de rejet : « neuf pièces sur neuf sont le même
# prisme dressé ». Le lieu ne peut donc pas lire « seuil → enceinte → cœur » :
# trois RÔLES sont dessinés avec une SEULE forme, et à trois secondes l'œil
# répond « des pierres », pas « un sanctuaire ». Ce n'était pas un défaut de
# valeur ni d'implantation — les deux passes précédentes l'ont prouvé en les
# corrigeant sans que la lecture change.
#
# La table et le chevet fusionnent donc en UNE masse : une dalle fendue posée
# sur deux dés, deux contreforts bas qui l'épaulent, et un DOSSIER de pierre
# qui monte derrière elle. La silhouette résultante est une enclume — large et
# horizontale en bas, une verticale rompue décalée en haut. Aucune autre pièce
# du lieu n'a cette forme, et c'est précisément ce qu'on lui demande.
#
# LA HAUTEUR N'EST PAS LE LEVIER, ET NE PEUT PAS L'ÊTRE. Le contrat
# d'invisibilité depuis la route plafonne le bâti à 2,40 m, le générateur à
# 2,20 m, et le rideau sud a déjà dû gagner un sixième buisson parce que le
# chevet de 2,05 m dépassait de trente centimètres. Le dossier reste donc à la
# hauteur du chevet qu'il remplace ; ce qui change est la MASSE et la FORME.
#
# Le dessus de dalle reste à 0,89 m — cote lue dans le journal de la chaîne et
# dont dépend l'ancre de récompense. L'élargir en XZ ne la touche pas.
def coeur_rituel(bm):
    """Dalle fendue + dossier + contreforts, en une seule masse."""
    # Les deux dés qui portent la dalle, écartés pour la nouvelle largeur.
    pierre_rompue(bm, 0.86, 0.36, 0.30, 21.7, cotes=5, brisure=0.16,
                  fuseau=0.10, centre=(-0.80, -0.11, 0.0))
    pierre_rompue(bm, 0.82, 0.33, 0.29, 33.1, cotes=5, brisure=0.14,
                  fuseau=0.10, centre=(0.75, 0.13, 0.0))
    # LES DEUX CONTREFORTS — bas, larges, épaulant la dalle par ses bouts.
    # Ce sont eux qui donnent au cœur son assise visuelle : sans eux la dalle
    # flotte sur deux dés et la masse se lit encore « table de camping ».
    pierre_rompue(bm, 0.56, 0.40, 0.35, 53.9, cotes=7, brisure=0.38,
                  fuseau=0.06, centre=(-1.31, 0.34, 0.0))
    pierre_rompue(bm, 0.47, 0.36, 0.33, 61.3, cotes=5, brisure=0.44,
                  fuseau=0.06, centre=(1.26, -0.30, 0.0))

    # LA DALLE FENDUE, élargie : 2,00 × 1,32 m d'emprise au lieu de 1,60 × 1,08.
    # LOT 1.R.1 — LA DALLE S'ÉLARGIT ENCORE, ET C'EST DE LA HIÉRARCHIE, PAS
    # DU CONFORT. Dans le cadre joueur recomposé, le montant du seuil est à
    # 7,0 m et le cœur à 10,0 m : à hauteur égale le montant SEMBLE plus grand.
    # La seule variable qui rétablisse l'ordre sans toucher au plafond
    # d'invisibilité est l'EMPRISE — 2,00 × 1,32 m → 2,52 × 1,60 m de dalle,
    # soit ≈ 3,3 m avec les contreforts. Surface apparente du cœur ≈ 20 700 px²
    # contre ≈ 6 300 px² pour le montant : le rapport passe de 1,0 à 3,3.
    contour = _contour_ellipse(1.26, 0.80, 16, 9.3)
    n = len(contour)
    a0, a1 = 2, 2 + n // 2
    fente = []
    p0, p1 = contour[a0 % n], contour[a1 % n]
    for i in (1, 2, 3):
        t = i / 4.0
        fente.append((
            p0[0] + (p1[0] - p0[0]) * t + _graine(9.3 * i + 4.1) * 0.19,
            p0[1] + (p1[1] - p0[1]) * t + _graine(9.3 * i + 7.7) * 0.15))
    moitie_a = [contour[i % n] for i in range(a0, a1 + 1)] \
        + list(reversed(fente))
    moitie_b = [contour[i % n] for i in range(a1, a0 + n + 1)] + fente
    _prisme_plan(bm, moitie_a, 0.0, 0.13, IDX_PIERRE, centre=(0.0, 0.0, 0.76))
    _prisme_plan(bm, moitie_b, 0.0, 0.13, IDX_PIERRE,
                 rotation=(0.0, math.radians(4.5), math.radians(-3.0)),
                 centre=(0.03, -0.02, 0.72))

    # LE DOSSIER — la verticale du cœur, décalée du centre pour que la
    # silhouette soit une enclume et non un T symétrique. Il monte DERRIÈRE la
    # dalle, côté route : il donne son fond au cœur et une masse de plus entre
    # l'offrande et le chemin.
    # `centre` en y NÉGATIF : Blender +y = Godot −z, et le dossier doit se
    # tenir au SUD de la dalle, côté route — c'est la position qu'occupait le
    # chevet, et elle a deux fonctions dont une n'est pas visuelle : il donne
    # son fond au cœur, et il ajoute une masse entre l'offrande et le chemin.
    # LOT 1.R.2 — LE DOSSIER S'ÉLARGIT, ET C'EST LA « MASSE CENTRALE » QUE LE
    # verdict réclame. À 0,54 × 0,26 de rayons il faisait 1,08 m de large pour
    # 2,03 m de haut : une PLAQUE, plus étroite que le montant de seuil qui la
    # précède de trois mètres, donc écrasée par lui en perspective. À
    # 0,80 × 0,32 il fait 1,60 m — la moitié de l'emprise de la dalle, ce qui
    # le lie à elle au lieu de la surmonter. La HAUTEUR ne bouge pas d'un
    # centimètre : le plafond d'identité (2,40 m au lieu, 2,20 m ici) est la
    # contrainte d'invisibilité depuis la route, et l'élargissement est
    # justement le seul levier qui ne l'entame pas.
    pierre_rompue(bm, 2.32, 0.80, 0.32, 37.7, cotes=7, brisure=0.30,
                  fuseau=0.30, rotation=(math.radians(5.0), 0.0, 0.0),
                  centre=(0.16, -0.86, 0.0))


# ---------------------------------------------------------------------------
# LE LINTEAU TOMBÉ — ce qui fait qu'un seuil se lit comme un seuil
# ---------------------------------------------------------------------------
# Deux montants seuls se lisent « deux pierres ». Un linteau EN TRAVERS, à
# terre, dit qu'il y avait une porte et qu'elle est tombée — et il le dit sans
# un mot, ce que le contrat demande explicitement.
#
# IL EST DRESSÉ, ET C'EST LE POINT. Toutes les autres pièces du lieu sont des
# pierres de champ à pans impairs ; celle-ci est TAILLÉE — un bloc à faces
# planes, à arêtes droites sur trois côtés, rompu net au quatrième. C'est la
# seule pièce du sanctuaire qui porte une trace d'outil, et c'est ce qui la
# distingue d'un caillou tombé là. La rupture est l'unique bout irrégulier.
def linteau_tombe(bm):
    """Un bloc de linteau à terre, taillé sur trois faces, rompu au bout."""
    demi_l, demi_e = 0.98, 0.21
    contour = []
    # Trois côtés droits, très légèrement irréguliers (une pierre taillée à la
    # main n'est pas une pièce d'usine) ...
    for x, y in ((-demi_l, -demi_e), (-0.30, -demi_e), (0.34, -demi_e),
                 (demi_l * 0.78, -demi_e * 0.86)):
        contour.append((x + _graine(x * 7.3) * 0.012,
                        y + _graine(y * 5.1 + x) * 0.014))
    # ... puis LA CASSURE : quatre points en dents de scie au bout est.
    for i, t in enumerate((0.0, 0.34, 0.68, 1.0)):
        contour.append((demi_l * (0.78 + 0.22 * t)
                        + _graine(71.0 + i * 3.7) * 0.09,
                        -demi_e * 0.86 + 2.0 * demi_e * 0.86 * t
                        + _graine(79.0 + i * 2.9) * 0.07))
    for x, y in ((demi_l * 0.78, demi_e * 0.86), (0.34, demi_e),
                 (-0.30, demi_e), (-demi_l, demi_e)):
        contour.append((x + _graine(x * 6.1 + 3.0) * 0.012,
                        y + _graine(y * 4.7 + x) * 0.014))
    _prisme_plan(bm, contour, 0.0, 0.33, IDX_PIERRE,
                 rotation=(math.radians(2.5), math.radians(-3.5), 0.0))
    # Deux éclats détachés au pied de la cassure.
    pierre_rompue(bm, 0.16, 0.14, 0.12, 83.1, cotes=5, brisure=0.46,
                  fuseau=0.05, centre=(1.06, 0.24, 0.0))
    pierre_rompue(bm, 0.11, 0.11, 0.13, 89.7, cotes=5, brisure=0.50,
                  fuseau=0.05, centre=(0.92, -0.31, 0.0))


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

    LA CHAUSSETTE N'EST PLUS UNE LIGNE DE NIVEAU — LOT 1.R, agent B.

    Mesuré en ouvrant `agent_b/base/shrine_gp_nef.png` à taille réelle : chaque
    pierre porte une bande vert sombre à bord NET et HORIZONTAL, toutes à la
    même hauteur relative, sur les six socles comme sur les deux montants. Ce
    n'est pas de la mousse, c'est une pierre TREMPÉE DANS LA PEINTURE — et
    c'est la chose la plus artificielle de la vue rapprochée du lieu.

    La cause est littérale : `pied = 0,30 · haut` est une constante par pièce,
    donc une ligne de niveau. Deux termes la brisent, tous deux physiques :

      * L'OMBRE PORTÉE. La mousse monte plus haut du côté qui garde
        l'humidité. Le soleil de ce monde vient de l'ouest et du haut
        (`DirectionalLight3D`, §22.1) ; la face abritée est donc l'est —
        `+x` en repère Blender local. Une face tournée à l'est reçoit le
        coefficient plein, une face plein ouest le tiers.
      * LE GRAIN. Un bruit déterministe de position, pour qu'aucune pierre
        n'ait la même chaussette que sa voisine et qu'aucune face n'ait un
        bord parfaitement droit.
    """
    if not bm.faces:
        return 0
    haut = max(v.co.z for v in bm.verts)
    pied_moyen = max(0.16, 0.30 * haut)
    touchees = 0
    for face in bm.faces:
        centre_z = sum(v.co.z for v in face.verts) / len(face.verts)
        cx = sum(v.co.x for v in face.verts) / len(face.verts)
        cy = sum(v.co.y for v in face.verts) / len(face.verts)
        vers_le_haut = (face.normal.z >= MOUSSE_NORMALE_MIN
                        and centre_z <= mousse_max_z)
        # `face.normal.x` ∈ [−1, 1] : +1 plein est (abrité), −1 plein ouest.
        abri = 0.5 + 0.5 * face.normal.x
        grain = _graine(cx * 4.3 + cy * 3.1 + haut * 1.7)
        pied = pied_moyen * (0.42 + 0.96 * abri + 0.40 * grain)
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
    # SUBDIVISION DU PIED — le seul moyen d'adoucir la frontière de mousse
    # sans changer la façon dont elle est posée.
    #
    # Constat mesuré sur `agent_b/it/t2/shrine_gp_nef.png` : chaque pierre
    # portait une bande de mousse à BORD NET. Ma passe précédente avait bien
    # fait varier la HAUTEUR de la chaussette d'une pierre à l'autre, mais pas
    # la netteté du bord — et la cause est structurelle : la mousse est un
    # INDEX DE MATÉRIAU PAR FACE. Une face est moussue ou ne l'est pas ; sur
    # un fût de sept pans, le bord ne peut donc être qu'une arête franche.
    #
    # On ne change pas la règle, on change la GÉOMÉTRIE qu'elle décore :
    # les arêtes de la bande de transition sont coupées deux fois, ce qui
    # multiplie par trois le nombre de faces disponibles là où la frontière
    # passe. Le bord devient dentelé au lieu d'être droit — la mousse suit les
    # petites facettes au lieu de trancher le fût. Rien au-dessus de la bande
    # n'est touché : le budget va où sert la lecture.
    haut_brut = max((v.co.z for v in bm.verts), default=0.0)
    bande = max(0.24, 0.62 * max(haut_brut, 1e-6))
    a_couper = [e for e in bm.edges
                if (e.verts[0].co.z + e.verts[1].co.z) * 0.5 < bande]
    # DÉCOUPE ADAPTATIVE — LOT 1.R.1. `cuts=2` sur une pièce d'un seul fût
    # coûte quelques dizaines de triangles ; sur un muret de sept blocs il en
    # coûte 1 400, et le générateur a REFUSÉ D'ENREGISTRER (9 598 pour 6 000).
    # La règle de mousse ne change pas ; c'est la finesse de la géométrie
    # qu'elle décore qui s'adapte au nombre de faces déjà présentes.
    brut = len(bm.faces)
    coupes = 2 if brut < 90 else (1 if brut < 260 else 0)
    if a_couper and coupes > 0:
        bmesh.ops.subdivide_edges(bm, edges=a_couper, cuts=coupes,
                                  use_grid_fill=False)
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
        # LOT 1.R.1 — les montants BAISSENT (1,82 → 1,55 et 1,44 → 1,12).
        # Deux raisons, et la première décide : dans le cadre joueur recomposé
        # le seuil est à 7 m et le cœur à 10 m, donc à hauteur égale le seuil
        # écrase le cœur. La seconde est le contrat d'invisibilité : moins
        # haut, c'est moins de rideau à demander aux buissons.
        # LOT 1.R.2 — LES MONTANTS BAISSENT ENCORE (1,55 → 1,34 et 1,12 →
        # 0,98), et c'est de la hiérarchie mesurée, pas du goût. Dans le cadre
        # joueur, le montant A est à 7,4 m et le dossier du cœur à 10,3 m :
        # une pierre de 1,55 m à 7,4 m sous-tend 0,209 rad, le dossier de
        # 2,03 m à 10,3 m en sous-tend 0,197 — le SEUIL était donc plus grand
        # que le CŒUR à l'écran, ce qui est exactement l'inverse de ce qu'un
        # axe rituel doit dire. À 1,34 m le montant tombe à 0,181 rad et rend
        # au cœur son rang, sans cesser d'être une pierre à hauteur d'homme.
        objet_depuis("SM_Shrine_Montant_A",
                     lambda bm: pierre_rompue(bm, 1.34, 0.31, 0.23, 3.7,
                                              cotes=7, brisure=0.26,
                                              fuseau=0.24)),
        objet_depuis("SM_Shrine_Montant_B",
                     lambda bm: pierre_rompue(bm, 0.98, 0.26, 0.28, 11.3,
                                              cotes=5, brisure=0.42,
                                              fuseau=0.18)),
        objet_depuis("SM_Shrine_Step", marche_enfoncee),
        # LES TROIS MURETS — l'enceinte, en blocs LIÉS et non en pierres
        # levées. Longueurs et hauteurs franchement différentes, vérifiées
        # plus bas et non espérées.
        objet_depuis("SM_Shrine_Muret_A",
                     lambda bm: muret_rompu(bm, 2.55, 0.99, 5.1, n=5),
                     mousse_max_z=0.60),
        objet_depuis("SM_Shrine_Muret_B",
                     lambda bm: muret_rompu(bm, 2.05, 0.74, 17.9, n=4),
                     mousse_max_z=0.52),
        objet_depuis("SM_Shrine_Muret_C",
                     lambda bm: muret_rompu(bm, 1.60, 0.58, 23.3, n=4),
                     mousse_max_z=0.42),
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
        # LE CŒUR — dalle fendue, contreforts et dossier en UNE masse. Il
        # remplace `SM_Shrine_Table` ET `SM_Shrine_Chevet` : deux prismes de
        # moins dans un lieu dont le défaut nommé est d'en avoir neuf du même
        # gabarit, et une silhouette d'enclume que rien d'autre ne porte.
        objet_depuis("SM_Shrine_Coeur", coeur_rituel, mousse_max_z=0.62),
        # LE LINTEAU TOMBÉ — la seule pièce TAILLÉE du lieu, en travers du
        # seuil. C'est elle qui transforme deux montants en une porte.
        objet_depuis("SM_Shrine_Linteau", linteau_tombe, mousse_max_z=0.34),
        # LES DEUX BORDURES DE NEF — l'axe, rendu visible par ce qui dépasse
        # de l'herbe et non par un dallage que l'herbe recouvre. Longueurs
        # franchement inégales (2,55 et 2,20 m) et nombres de bornes
        # différents : deux rangées jumelles se reliraient « allée plantée »,
        # donc entretenue, donc récente — l'inverse d'un vestige avalé.
        # `mousse_max_z` très haut : ces pierres-là sont au ras du sol, dans
        # l'ombre du couvert, et doivent verdir sur toute leur hauteur.
        # LONGUEURS MESURÉES SUR LA NEF, PAS CHOISIES : entre le seuil (z de
        # nef −3,3, soit 2,64 m du cœur à l'échelle NEF_L = 0,80) et le bord
        # de la dalle (0,80 m de rayon dans l'axe), il reste 1,84 m d'axe
        # libre. Une bordure de 2,55 m entrerait DANS le cœur.
        objet_depuis("SM_Shrine_Bordure_G",
                     lambda bm: bordure_de_nef(bm, 1.75, 13.9, n=3,
                                               h_seuil=0.46, h_coeur=0.26),
                     mousse_max_z=0.55),
        objet_depuis("SM_Shrine_Bordure_D",
                     lambda bm: bordure_de_nef(bm, 1.45, 27.3, n=3,
                                               h_seuil=0.40, h_coeur=0.24),
                     mousse_max_z=0.55),
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
    socles = [o for o in pieces if o.name.startswith("SM_Shrine_Muret")]
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
    print("[forest_shrine] murets : %s"
          % ", ".join("%s h=%.2f aire=%.3f" % g for g in gabarits))

    # GARDE 3 — LA TABLE EST FENDUE, ET LA FENTE SE VOIT. Deux moitiés
    # distinctes séparées d'au moins 2 cm à hauteur de dalle : une fente que
    # l'on ne voit pas est un joint, et un joint n'est pas une histoire.
    # RECHERCHE PAR NOM, ET NON PAR INDEX. Cette garde lisait `pieces[7]`.
    # Ajouter une pièce à la liste l'aurait fait mesurer le mauvais maillage —
    # en silence, et avec un verdict parfaitement crédible. C'est la famille
    # d'ISS-018 : un chiffre juste sur un objet qui n'est pas celui qu'on croit.
    table = next((o for o in pieces if o.name == "SM_Shrine_Coeur"), None)
    if table is None:
        print("[forest_shrine] ERREUR: SM_Shrine_Coeur absent de la liste")
        return 2
    dalle = [v.co for v in table.data.vertices if 0.66 < v.co.z < 1.10]
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
