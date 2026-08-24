# SOURCE DE GÉNÉRATION REPRODUCTIBLE — LES DEUX PIERRES DE LA PORTE DES
# FLEURS (`valley.poi.flower_field.01`, lot 1.R, voie C).
#
# POURQUOI CET ASSET EXISTE. La composition B « la Porte des fleurs » a été
# arbitrée par le lead avec une condition écrite : « premier essai en
# Rock_Medium rescalé autorisé, MAIS si la capture rend "galet étiré" ou
# "rocher posé", tu fais le GLB dédié ». L'essai en kit a été fait
# (`rock_largeA` dressé sur chant, habillé par surface) et la capture a
# rendu son verdict, mesuré par le lead sur `apres/flower_field_joueur.png` :
#
#   * la PETITE rend un BLANC PLAT presque sans matière — « éclat de
#     papier » ;
#   * la GRANDE reste l'objet le plus SOMBRE près du centre du cadre — la
#     famille exacte du défaut qui a fait rejeter le lieu au départ (« un
#     gros rocher sombre vole la lecture »).
#
# LA CAUSE EST GÉOMÉTRIQUE, PAS COLORIMÉTRIQUE, et c'est ce qui condamne
# l'essai en kit. `rock_largeA` est une dalle à TRÈS PEU DE GRANDES FACES
# PLANES. Dressée sur chant, une seule de ces faces occupe presque toute la
# silhouette. Sous une lumière directionnelle, cette face unique est soit
# face au soleil — et elle brûle en aplat blanc — soit tournée vers le ciel
# bleu — et elle s'effondre en gris-bleu sombre. Le MÊME albédo (0,58) a
# produit les deux défauts opposés sur les deux pierres : ce n'est pas une
# teinte à corriger, c'est une loi de forme à remplacer. Aucune valeur
# d'albédo ne répare une face plane de 2 m.
#
# CE QUE FAIT CE GÉNÉRATEUR, et pourquoi chaque geste :
#
#   1. SECTION ÉLANCÉE, PAS UN GALET. Ellipse aplatie qui s'effile vers le
#      haut : de loin la silhouette est une stèle, pas un caillou étiré —
#      c'est le second mot du verdict conditionnel du lead.
#   2. CANNELURES VERROUILLÉES SUR L'AZIMUT. Le relief radial est une
#      fonction de l'ANGLE, pas un tirage par anneau : il survit d'un anneau
#      au suivant et devient une arête filante. (Leçon reprise de
#      `make_thunderstruck_tree.py` R2B.2, où le relief tiré par anneau
#      donnait « du bruit, pas des cannelures ».)
#   3. PHASE D'ÉCHANTILLONNAGE TOURNANTE. Les arêtes longitudinales cessent
#      d'être des méridiens exacts et chaque quad se vrille.
#   4. GAUCHISSEMENT. La section tourne lentement avec la hauteur. La DÉRIVE
#      de l'axe, en revanche, reste FAIBLE et volontairement bornée : mesuré
#      sur la première capture, une dérive de 0,23 m annulait presque
#      entièrement l'inclinaison de 11,5° appliquée côté Godot (penché
#      mesuré : 5 px pour 62 attendus). L'inclinaison doit rester lisible ;
#      la matière ne doit pas la manger.
#   5. SOMMET ROMPU. Le dernier anneau est coupé par un plan incliné, et le
#      chapeau est une surface de FRACTURE (matériau distinct, plus froid) —
#      une pierre ancienne se lit à sa cassure.
#   6. LA MATIÈRE EST DANS LA COULEUR DE SOMMET, PAS DANS LES NORMALES.
#      C'est la leçon de la première capture de cet asset, et elle est
#      chiffrée : la face de la stèle rendait UNE SEULE valeur — luminance
#      175, étendue p10-p90 = 1 niveau sur 58 px de large — alors que le
#      maillage portait 465 directions de normale distinctes. Sur des faces
#      quasi verticales, sous ce ciel, l'irradiance ambiante domine et la
#      variation d'orientation ne rapporte presque rien. Les roches du kit
#      ne se lisent pas comme de la pierre grâce à leur géométrie : elles
#      s'en sortent grâce à la VARIATION DE LEUR ATLAS. Sans texture, la
#      seule variation gratuite est `COLOR_0` : strates horizontales,
#      mouchetage verrouillé sur l'azimut, creux des cannelures assombris,
#      et un pied plus sombre et plus vert. Le contrôle final du générateur
#      mesure cette étendue et REFUSE d'écrire si elle est trop faible —
#      un aplat ne peut plus sortir d'ici sans être vu.
#
# CONTRÔLES QUE LE GÉNÉRATEUR S'IMPOSE (il rend 2 et n'écrit rien s'ils
# échouent — un asset qui sort hors contrat coûte une passe de capture) :
#   * base à z = 0 (min Y ≈ 0 après export yup) ;
#   * hauteurs dans leurs fourchettes ;
#   * budget total ≤ 2 000 triangles (plafond posé par le lead) ;
#   * aucune facette ne dépasse un seuil d'aire — le contrôle qui aurait
#     rougi sur `rock_largeA` dressé, et qui est la raison d'être du fichier ;
#   * élancement (hauteur / plus grande largeur de base) ≥ 2,4.
#
# Un seul GLB, deux objets : `SM_Stele_Grande` et `SM_Stele_Petite`.
# Deux matériaux seulement : le corps pâle et la patine de fracture.

import math
import os
import random
import sys

import bpy
import bmesh
from mathutils import Vector

TAG = "[flower_field_steles]"

COTES = 18
ANNEAUX = 14
BUDGET_TRIS = 2000
## Aire maximale d'un triangle, en m². Une face plane de `rock_largeA`
## dressée mesurait ~0,8 m² : le seuil est là pour que ce mode de panne ne
## puisse pas revenir par la petite porte.
AIRE_FACETTE_MAX = 0.075
ELANCEMENT_MIN = 2.4
## Étendue de couleur de sommet exigée sur le corps, en fraction de la
## valeur moyenne. Le contrôle qui interdit le retour de l'aplat mesuré
## (p10-p90 = 1 niveau de luminance sur la face rendue).
ETENDUE_COULEUR_MIN = 0.20

## Corps : calcaire pâle et chaud, MODULÉ par `COLOR_0` (voir le point 6
## ci-dessus). La valeur d'albédo seule ne sauve pas une face plate — c'est
## la couleur de sommet qui porte la matière.
MAT_CORPS = (0.790, 0.772, 0.730, 1.0)
## Niveau moyen de la couleur de sommet (voir `_teinte_pierre`).
NIVEAU = 0.835
## Fracture : plus froide et à peine plus sombre. L'essai en kit descendait
## à 0,435 et creusait un trou de valeur dans la silhouette.
MAT_FRACTURE = (0.560, 0.575, 0.565, 1.0)
## Pied moussu : la stèle sort de l'herbe au lieu d'être posée dessus.
TEINTE_PIED = (0.74, 0.80, 0.66)

## id | hauteur m | demi-largeur base m | demi-profondeur base m | graine
## Rapport largeur/profondeur ramené de 2,13 à ~1,65 : à 2,13 le tiers avant
## de la section est presque un plan, et un plan pâle vertical est
## exactement ce qui rend « éclat de papier ».
STELES = [
    ("SM_Stele_Grande", 2.16, 0.305, 0.186, 40721),
    ("SM_Stele_Petite", 1.24, 0.214, 0.129, 91043),
]


def _purge() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _cannelures(graine: int):
    """Relief radial VERROUILLÉ SUR L'AZIMUT.

    Trois harmoniques de phases fixes : la fonction ne dépend que de
    l'angle, donc le même creux se retrouve à chaque hauteur et devient une
    rainure verticale continue. Amplitude bornée à ±9 % du rayon — au-delà
    la section cesse de se lire comme une pierre taillée.
    """
    rng = random.Random(graine)
    harmoniques = []
    # Amplitudes DOUBLÉES par rapport au premier jet : à ±9 % du rayon les
    # cannelures ne creusaient rien de perceptible. La somme des poids sert
    # aussi à normaliser le creux pour la couleur de sommet.
    for k, poids in ((3, 0.075), (5, 0.052), (8, 0.030)):
        harmoniques.append((k, poids, rng.uniform(0.0, math.tau)))
    amplitude = sum(h[1] for h in harmoniques)

    def relief(angle: float) -> float:
        somme = 0.0
        for k, poids, phase in harmoniques:
            somme += poids * math.cos(k * angle + phase)
        return somme

    return relief, amplitude


def _stele(nom: str, hauteur: float, demi_a: float, demi_b: float,
           graine: int, mat_corps, mat_fracture):
    rng = random.Random(graine)
    relief, creux_amplitude = _cannelures(graine)
    # Mouchetage minéral verrouillé sur l'azimut : une VEINE verticale, pas
    # un bruit par sommet. Même loi que les cannelures, phases différentes.
    veines = [(k, rng.uniform(0.0, math.tau)) for k in (4, 7, 11)]
    # Strates : deux fréquences, l'une à ~0,30 m (le lit sédimentaire),
    # l'autre à ~0,95 m (le grand banc). Une seule fréquence ferait une
    # rayure régulière.
    strate_p1 = rng.uniform(0.0, math.tau)
    strate_p2 = rng.uniform(0.0, math.tau)

    # Phases d'échantillonnage : marche irrégulière de somme quasi nulle.
    # Sans elle, les arêtes longitudinales sont des méridiens exacts et la
    # facette devient une bande réglée courant toute la hauteur.
    pas_phase = [rng.uniform(-0.075, 0.075) for _ in range(ANNEAUX)]
    moyenne = sum(pas_phase) / len(pas_phase)
    pas_phase = [p - moyenne for p in pas_phase]

    # Dérive de l'axe BORNÉE (voir le point 4 de l'en-tête : à 0,23 m elle
    # annulait l'inclinaison appliquée dans Godot) et rotation lente de la
    # section : la pierre gauchit sans se redresser.
    derive_x = rng.uniform(0.016, 0.032) * (1.0 if rng.random() < 0.5 else -1.0)
    derive_y = rng.uniform(-0.018, 0.018)
    vrille = rng.uniform(0.16, 0.28) * (1.0 if rng.random() < 0.5 else -1.0)

    # Plan de fracture du sommet : incliné, orienté au hasard.
    az_fracture = rng.uniform(0.0, math.tau)
    creux_fracture = hauteur * rng.uniform(0.055, 0.085)

    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()

    anneaux = []
    couleurs = []
    phase = 0.0
    for i in range(ANNEAUX):
        t = i / float(ANNEAUX - 1)
        phase += pas_phase[i]
        # Effilement : rapide en bas (le pied s'évase), lent ensuite.
        effile = 1.0 - 0.46 * t - 0.10 * (t ** 2)
        # Léger renflement au tiers : une stèle taillée n'est pas un cône.
        effile += 0.035 * math.sin(math.pi * min(1.0, t / 0.62))
        a = demi_a * effile
        b = demi_b * effile
        cx = derive_x * (t ** 1.35) * hauteur
        cy = derive_y * (t ** 1.35) * hauteur
        rot = vrille * t
        z_base = hauteur * t

        sommets = []
        couleurs_anneau = []
        for j in range(COTES):
            angle = math.tau * j / COTES + phase
            r = 1.0 + relief(angle)
            # Bruit de plan basse fréquence : la section n'est pas une
            # ellipse parfaite, mais elle reste cohérente d'un anneau à
            # l'autre (le bruit dépend de l'angle, pas du tirage).
            r *= 1.0 + 0.030 * math.sin(2.0 * angle + 1.7)
            px = a * math.cos(angle) * r
            py = b * math.sin(angle) * r
            x = cx + px * math.cos(rot) - py * math.sin(rot)
            y = cy + px * math.sin(rot) + py * math.cos(rot)
            z = z_base
            if i == ANNEAUX - 1:
                # Sommet rompu : le dernier anneau descend d'un côté.
                z -= creux_fracture * (0.5 + 0.5 * math.cos(angle - az_fracture))
            sommets.append(bm.verts.new(Vector((x, y, z))))
            couleurs_anneau.append(
                _teinte_pierre(angle, z, t, relief, creux_amplitude, veines,
                               strate_p1, strate_p2))
        anneaux.append(sommets)
        couleurs.append(couleurs_anneau)

    bm.verts.ensure_lookup_table()
    faces_corps = []
    for i in range(ANNEAUX - 1):
        bas = anneaux[i]
        haut = anneaux[i + 1]
        for j in range(COTES):
            k = (j + 1) % COTES
            faces_corps.append(bm.faces.new((bas[j], bas[k], haut[k], haut[j])))

    # Chapeau de fracture et semelle : deux éventails autour d'un sommet
    # central. La semelle est plate à z = 0 (l'asset s'assied sans calcul).
    centre_haut = bm.verts.new(Vector((
        sum(v.co.x for v in anneaux[-1]) / COTES,
        sum(v.co.y for v in anneaux[-1]) / COTES,
        sum(v.co.z for v in anneaux[-1]) / COTES + creux_fracture * 0.22)))
    faces_fracture = []
    for j in range(COTES):
        k = (j + 1) % COTES
        faces_fracture.append(
            bm.faces.new((anneaux[-1][j], anneaux[-1][k], centre_haut)))

    centre_bas = bm.verts.new(Vector((
        sum(v.co.x for v in anneaux[0]) / COTES,
        sum(v.co.y for v in anneaux[0]) / COTES, 0.0)))
    for j in range(COTES):
        k = (j + 1) % COTES
        faces_corps.append(
            bm.faces.new((anneaux[0][k], anneaux[0][j], centre_bas)))

    for face in faces_fracture:
        face.material_index = 1

    # COULEUR DE SOMMET. Portée par une couche de couleur de BOUCLE (par
    # coin de face) : c'est ce que l'exporter glTF écrit en `COLOR_0`, et
    # c'est ce qui donne à la pierre sa matière indépendamment de la
    # lumière. Posée AVANT la triangulation pour que chaque coin hérite de
    # la teinte de son sommet d'anneau.
    # `float_color` et non `color` : une couche de couleur d'OCTETS est
    # interprétée en sRGB par Blender, une couche flottante est linéaire —
    # et glTF/Godot attendent du linéaire. Passer par les octets
    # décalerait toutes les valeurs sans que rien ne le signale.
    couche = bm.loops.layers.float_color.new("Col")
    bm.verts.index_update()
    index_couleur = {}
    for i, anneau in enumerate(anneaux):
        for j, sommet in enumerate(anneau):
            index_couleur[sommet.index] = couleurs[i][j]
    # Chapeau : la fracture est plus pâle et plus froide que le corps.
    index_couleur[centre_haut.index] = (0.98, 0.99, 1.00)
    index_couleur[centre_bas.index] = tuple(c * NIVEAU for c in TEINTE_PIED)
    for face in bm.faces:
        for boucle in face.loops:
            teinte = index_couleur.get(boucle.vert.index, (1.0, 1.0, 1.0))
            boucle[couche] = (teinte[0], teinte[1], teinte[2], 1.0)

    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.normal_update()
    bm.to_mesh(maillage)
    bm.free()

    # La couche doit être l'attribut de couleur ACTIF et celui de RENDU :
    # l'exporter glTF 4.0 n'écrit `COLOR_0` que pour celui-là. Créée par
    # bmesh, elle ne l'est pas d'office — et le `.glb` sortait sans couleur.
    if "Col" in maillage.color_attributes:
        maillage.color_attributes.active_color_index = \
            maillage.color_attributes.find("Col")
        maillage.color_attributes.render_color_index = \
            maillage.color_attributes.find("Col")

    maillage.materials.append(mat_corps)
    maillage.materials.append(mat_fracture)
    objet = bpy.data.objects.new(nom, maillage)
    bpy.context.scene.collection.objects.link(objet)
    return objet


## Teinte d'un sommet du corps, en MULTIPLICATEUR de l'albédo du matériau.
##
## Quatre apports, tous décrits au point 6 de l'en-tête :
##   * strates horizontales à deux fréquences — le lit sédimentaire ;
##   * veines verticales verrouillées sur l'azimut — pas un bruit par
##     sommet, qui se lirait comme du grain télé ;
##   * creux des cannelures assombris — c'est ce qui rend les cannelures
##     VISIBLES alors que l'ambiante écrase leur relief ;
##   * pied plus sombre et plus vert — la pierre sort de l'herbe.
def _teinte_pierre(angle, z, t, relief, creux_amplitude, veines,
                   strate_p1, strate_p2):
    strates = (0.062 * math.sin(z * math.tau / 0.30 + strate_p1)
               + 0.043 * math.sin(z * math.tau / 0.95 + strate_p2))
    veine = 0.0
    for k, phase in veines:
        veine += 0.021 * math.cos(k * angle + phase)
    creux = relief(angle) / max(creux_amplitude, 1e-6)
    # `NIVEAU` recentre la modulation sous 1,0 : `COLOR_0` MULTIPLIE
    # l'albédo, et une valeur > 1 serait écrêtée sans avertissement.
    # L'albédo du matériau est relevé d'autant (`MAT_CORPS`), donc la
    # valeur moyenne rendue ne bouge pas — seule l'étendue apparaît.
    valeur = NIVEAU * (1.0 + strates + veine + 0.135 * creux)
    rouge, vert, bleu = valeur, valeur, valeur * 0.985
    if t < 0.24:
        melange = ((0.24 - t) / 0.24) ** 1.4 * 0.85
        rouge += (TEINTE_PIED[0] - 1.0) * NIVEAU * melange
        vert += (TEINTE_PIED[1] - 1.0) * NIVEAU * melange
        bleu += (TEINTE_PIED[2] - 1.0) * NIVEAU * melange
    borne = lambda v: max(0.45, min(1.0, v))
    return (borne(rouge), borne(vert), borne(bleu))


## Matériau du corps : `Base Color = couleur × attribut de couleur « Col »`.
##
## LE BRANCHEMENT N'EST PAS COSMÉTIQUE. L'exporter glTF de Blender 4.0
## n'écrit `COLOR_0` que si le MATÉRIAU consomme réellement l'attribut
## (mode `export_vertex_color = MATERIAL`, sa valeur par défaut, et le
## preset partagé `tools/blender/export_gltf.py` ne la surcharge pas — je
## ne modifie pas un fichier partagé). Mesuré : sans ce branchement, le
## générateur produisait bien ses couleurs de sommet (étendue 30,5 %) et le
## `.glb` sortait avec `POSITION` et `NORMAL` seulement. Aucune erreur,
## aucun avertissement, un asset silencieusement plat.
def _materiau(nom: str, couleur, avec_couleur_sommet: bool = True):
    mat = bpy.data.materials.new(nom)
    mat.use_nodes = True
    arbre = mat.node_tree
    principled = arbre.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = couleur
    if avec_couleur_sommet:
        attribut = arbre.nodes.new("ShaderNodeVertexColor")
        attribut.layer_name = "Col"
        attribut.location = (-600, 200)
        melange = arbre.nodes.new("ShaderNodeMix")
        melange.data_type = "RGBA"
        melange.blend_type = "MULTIPLY"
        melange.location = (-300, 200)
        melange.inputs["Factor"].default_value = 1.0
        melange.inputs[6].default_value = couleur
        arbre.links.new(attribut.outputs["Color"], melange.inputs[7])
        arbre.links.new(melange.outputs[2], principled.inputs["Base Color"])
    if "Roughness" in principled.inputs:
        principled.inputs["Roughness"].default_value = 0.90
    if "Metallic" in principled.inputs:
        principled.inputs["Metallic"].default_value = 0.0
    if "Specular IOR Level" in principled.inputs:
        principled.inputs["Specular IOR Level"].default_value = 0.25
    elif "Specular" in principled.inputs:
        principled.inputs["Specular"].default_value = 0.25
    return mat


def main() -> int:
    _purge()
    mat_corps = _materiau("MAT_Stele_Pale", MAT_CORPS)
    mat_fracture = _materiau("MAT_Stele_Fracture", MAT_FRACTURE)

    total_tris = 0
    for nom, hauteur, demi_a, demi_b, graine in STELES:
        objet = _stele(nom, hauteur, demi_a, demi_b, graine,
                       mat_corps, mat_fracture)
        maillage = objet.data
        tris = len(maillage.polygons)
        total_tris += tris

        zs = [v.co.z for v in maillage.vertices]
        xs = [v.co.x for v in maillage.vertices]
        ys = [v.co.y for v in maillage.vertices]
        base = min(zs)
        haut_reel = max(zs)
        largeur = max(max(xs) - min(xs), max(ys) - min(ys))

        aire_max = 0.0
        for poly in maillage.polygons:
            aire_max = max(aire_max, poly.area)

        # ÉTENDUE DE COULEUR DE SOMMET — le contrôle qui interdit le retour
        # de l'aplat mesuré (face rendue à une seule valeur, p10-p90 = 1).
        attribut = maillage.color_attributes.get("Col")
        if attribut is None:
            print("%s ERREUR: %s sans couche de couleur de sommet" % (TAG, nom))
            return 2
        luminances = sorted(
            0.2126 * d.color[0] + 0.7152 * d.color[1] + 0.0722 * d.color[2]
            for d in attribut.data)
        p10 = luminances[len(luminances) // 10]
        p90 = luminances[9 * len(luminances) // 10]
        moyenne_lum = sum(luminances) / len(luminances)
        etendue = (p90 - p10) / max(moyenne_lum, 1e-6)

        print("%s %s : %d tris, hauteur %.3f m, base z %.4f, "
              "largeur max %.3f m, elancement %.2f, facette max %.4f m2, "
              "couleur p10 %.3f p90 %.3f (etendue %.1f %% de la moyenne)"
              % (TAG, nom, tris, haut_reel, base, largeur,
                 haut_reel / max(largeur, 1e-6), aire_max, p10, p90,
                 100.0 * etendue))
        if etendue < ETENDUE_COULEUR_MIN:
            print("%s ERREUR: %s etendue de couleur %.1f %% < %.1f %% — "
                  "la face rendrait un aplat, c'est le defaut mesure"
                  % (TAG, nom, 100.0 * etendue, 100.0 * ETENDUE_COULEUR_MIN))
            return 2
        if p90 > 1.0001:
            print("%s ERREUR: %s couleur de sommet > 1 (%.3f) — ecretee a "
                  "l export sans avertissement" % (TAG, nom, p90))
            return 2

        if abs(base) > 0.001:
            print("%s ERREUR: %s n'a pas sa base a z=0 (%.4f)"
                  % (TAG, nom, base))
            return 2
        if not (hauteur * 0.90 <= haut_reel <= hauteur * 1.02):
            print("%s ERREUR: %s hauteur %.3f hors de la fourchette autour "
                  "de %.3f" % (TAG, nom, haut_reel, hauteur))
            return 2
        if aire_max > AIRE_FACETTE_MAX:
            print("%s ERREUR: %s porte une facette de %.4f m2 (> %.4f) — "
                  "c'est le defaut de la dalle de kit qui revient"
                  % (TAG, nom, aire_max, AIRE_FACETTE_MAX))
            return 2
        elancement = haut_reel / max(largeur, 1e-6)
        if elancement < ELANCEMENT_MIN:
            print("%s ERREUR: %s elancement %.2f < %.2f — « galet etire »"
                  % (TAG, nom, elancement, ELANCEMENT_MIN))
            return 2

    print("%s total %d triangles (plafond %d)" % (TAG, total_tris, BUDGET_TRIS))
    if total_tris > BUDGET_TRIS:
        print("%s ERREUR: budget de triangles depasse" % TAG)
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_FlowerFieldSteles.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("%s source enregistree -> %s" % (TAG, sortie))
    print("FIN NOMINALE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
