# SOURCE DE GÉNÉRATION REPRODUCTIBLE — LES DEUX CROCS FROIDS DU BELVÉDÈRE
# (`valley.poi.overlook_summit.01`, lot 1.R, voie A).
#
# POURQUOI CET ASSET EXISTE — LA CAUSE EST GÉOMÉTRIQUE, MESURÉE SUR CAPTURE.
#
# L'état de départ (de43152) posait la crête et l'éperon avec la famille
# `Rock_Medium_*` du kit. Mesuré au pixel sur
# `evidence/world_v2/v2_3_b/lot1r/final/gros_plans/overlook_gros_crete.png`
# et `.../ab13/overlook_summit_identite.png` :
#
#   * la masse rend H=40° S=0,11 V=0,61 — une teinte CHAUDE, et une valeur
#     PLUS CLAIRE que la falaise V2.2 du fond (H=25° V=0,63). Le contrat du
#     lot demande « minéral FROID — gris bleuté, ardoise, pierre
#     désaturée » : la matière posée dit exactement le contraire ;
#   * la forme est un GALET ARRONDI FACETTÉ, coiffé de mousse pâle. À dix
#     mètres la lecture est « des oreillers de pierre », pas « une
#     formation ». Aucune valeur d'albédo ne fabrique une strate sur un
#     galet : c'est une loi de forme, pas une couleur.
#
# C'est le même verdict conditionnel que celui des stèles du champ
# (`make_flower_field_steles.py`) : l'essai en kit a été fait, la capture a
# rendu « rocher posé », donc le GLB dédié.
#
# CE QUE FAIT CE GÉNÉRATEUR, ET POURQUOI CHAQUE GESTE
#
#  1. UNE PILE DE STRATES, PAS UN GALET. Chaque banc est un prisme lobé :
#     une PAROI verticale (le nu du banc) puis une VIRE horizontale (le
#     replat). C'est l'alternance paroi/vire qui fait lire « sédimentaire »
#     à toute distance — c'est le seul trait que la famille du kit ne peut
#     pas produire.
#  2. LE PENDAGE EST PARTAGÉ PAR LES DEUX MASSES. Les bancs sont cisaillés
#     d'un même azimut et d'un même angle sur la crête ET sur l'éperon.
#     Deux rochers voisins sont deux objets ; deux masses au MÊME pendage
#     sont une formation rompue en deux. C'est ce qui répond à « les deux
#     crocs », et non leur simple voisinage.
#  3. LES DIACLASES SONT VERROUILLÉES SUR L'AZIMUT. Le relief radial est
#     une fonction de l'ANGLE seul : le même creux se retrouve banc après
#     banc et devient une fracture filante verticale. (Leçon reprise des
#     stèles, elle-même reprise de l'arbre foudroyé où un relief tiré par
#     anneau donnait « du bruit, pas des cannelures ».)
#  4. LE PIED S'ÉVASE. Le banc du bas déborde de ~18 % : enterré côté
#     Godot, il donne un contact franc et large au lieu d'une ligne nette
#     entre pierre et herbe. « Roches posées SUR le sol sans racine » est
#     une des trois causes de rejet écrites au contrat.
#  5. LA COURONNE EST ROMPUE. Le dernier banc est tronqué par un plan
#     incliné : une crête vive d'un côté, un écroulement de l'autre. Pas de
#     chapeau plat — un chapeau plat se relit comme un empilement de boîtes.
#  6. LA MATIÈRE EST DANS `COLOR_0`, PAS DANS LES NORMALES. Chiffré sur les
#     stèles : une face quasi verticale rendait UNE SEULE valeur (p10-p90 =
#     1 niveau) alors que le maillage portait 465 normales distinctes. Sous
#     ce ciel, l'irradiance ambiante domine et l'orientation ne rapporte
#     presque rien. Sans texture, la seule variation gratuite est la couleur
#     de sommet : bandes de bancs alternées, creux de diaclase assombris,
#     dessous de vire plus froid, pied plus sombre et plus vert. Un contrôle
#     final mesure l'étendue et REFUSE d'écrire si elle est trop faible.
#
# CONTRÔLES QUE LE GÉNÉRATEUR S'IMPOSE (il rend 2 et n'écrit rien) :
#   * base à z = 0 (donc min Y ≈ 0 après export yup) ;
#   * hauteurs dans leur fourchette ;
#   * budget de triangles ;
#   * étendue de couleur de sommet suffisante ;
#   * couleur de sommet ≤ 1 (au-delà, l'export écrête EN SILENCE) ;
#   * nombre de VIRES réellement produites — c'est le trait qui définit
#     l'asset, et un contrôle qui ne le mesure pas laisserait passer un
#     cylindre lisse sans que rien ne bronche ;
#   * pendage IDENTIQUE sur les deux masses.
#
# Chaîne : tools/blender/export_lieux_voie_a.sh overlook_crags
#
# Usage direct (déconseillé, pas de jeton de fraîcheur) :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/environment/make_overlook_crags.py

import math
import os
import random
import sys

import bpy
import bmesh
from mathutils import Vector

TAG = "[overlook_crags]"

COTES = 24
BUDGET_TRIS = 3600
ETENDUE_COULEUR_MIN = 0.20
## Une crête de 7 m porte forcément des facettes plus grandes qu'une stèle
## de 2 m : le seuil suit l'échelle, il ne la copie pas. Repère : la face
## plane de `rock_largeA` qui a fait rejeter l'essai en kit du champ mesure
## ~0,8 m² sur une pierre de 2 m ; à l'échelle d'ici l'équivalent serait
## ~10 m². Le plafond est posé bien en dessous.
AIRE_FACETTE_MAX = 1.60
## Nombre minimal de vires (replats horizontaux entre deux bancs) par masse.
VIRES_MIN = 4

## PENDAGE PARTAGÉ — azimut (degrés, sens trigonométrique dans le plan XY de
## Blender) et angle. Les deux masses le portent à l'identique : c'est ce
## qui les fait lire comme une seule formation rompue.
PENDAGE_AZIMUT = 209.0
PENDAGE_DEG = 13.5

## ARDOISE FROIDE. Base linéaire du matériau ; la couleur de sommet la
## module autour de `NIVEAU`. Valeur volontairement PLUS SOMBRE que la
## falaise V2.2 du fond (rendue V=0,63) : la formation doit se détacher en
## masse sombre et bleue, jamais rivaliser de clarté avec l'arrière-plan.
## Bleu > vert > rouge : c'est la seule façon d'obtenir une teinte au-delà
## de 190° une fois la lumière chaude du monde appliquée.
## v2 — RECALÉ SUR CAPTURE, et la première valeur était FAUSSE de loin.
## À (0,355 ; 0,395 ; 0,462) la face au soleil rendait **RGB(255,255,255)**,
## c'est-à-dire ÉCRÊTÉE : la crête sortait en tour blanche (mesuré sur
## `voie_a2/iter1/overlook_gros_crete.png`, face au soleil V=0,999, face à
## l'ombre V=0,853). Deux enseignements, tous deux mesurés :
##  * `baseColorFactor` glTF est LINÉAIRE. Une valeur qui « a l'air » d'un
##    gris moyen y est en fait claire, et la lumière du monde la pousse
##    au-delà de 1. C'est le piège d'albédo de `scripts/CLAUDE.md`, dans sa
##    version glTF ;
##  * la LUMIÈRE EST CHAUDE. À l'écrêtage, la face rendait (255,255,255) et
##    même à l'ombre (217,218,211) : le rapport bleu/rouge de l'albédo se
##    faisait manger. Pour rendre FROID sous un soleil miel, il faut un
##    biais bleu bien plus fort que la teinte visée.
## La cible est mesurée dans la MÊME image : les boulders de kit refroidis
## du même lieu rendent RGB(103 ; 112 ; 138), H=223°, S=0,254, V=0,540 —
## c'est exactement l'ardoise froide voulue, et c'est la seule façon que les
## deux familles appartiennent au même lieu. Rapport visé 1 : 1,07 : 1,47.
## v3 — LA VALEUR ÉTAIT BONNE, LE FROID N'Y ÉTAIT PAS. Mesuré sur
## `voie_a2/iter3` : la masse rend RGB(137 ; 133 ; 133) au loin et
## (123 ; 122 ; 126) en gros plan, soit V ≈ 0,50–0,54 (juste) mais
## **S = 0,02 à 0,04** — un gris parfaitement neutre. La lumière chaude du
## monde mange un biais bleu de 1 : 1,07 : 1,47. La cible reste celle
## mesurée dans la même image (boulders de kit refroidis, RGB 103/112/138,
## B/R = 1,34) : il faut donc un rapport d'albédo de **1 : 1,20 : 2,03**,
## obtenu en BAISSANT le rouge et le vert plutôt qu'en montant le bleu — le
## bleu tient déjà la valeur, et le monter écrêterait de nouveau.
MAT_ARDOISE = (0.0568, 0.0681, 0.1153, 1.0)
## Le nu de fracture fraîche : à peine plus clair, franchement plus froid.
MAT_FRACTURE = (0.0659, 0.0785, 0.1329, 1.0)
## v4 — 0,90 → 0,82 pour laisser de la place aux rehauts ajoutés dans
## `_teinte_banc` sans écrêter la couleur de sommet (au-delà de 1, l'export
## écrête EN SILENCE). Les trois couleurs de matériau sont remontées de
## 0,90/0,82 : l'albédo EFFECTIF est inchangé, donc la mesure de couleur
## obtenue en iter4 (croc RGB 102/107/125, H=226°, contre la cible
## 103/112/138) reste valable.
NIVEAU = 0.82
## Pied : plus sombre, un rien plus vert — la roche rejoint la terre.
TEINTE_PIED = (0.62, 0.68, 0.60)

## id | hauteur m | demi-largeur base m | demi-profondeur base m | bancs | graine
CROCS = [
    ("SM_Overlook_Crest", 6.60, 2.95, 2.35, 7, 51703),
    ("SM_Overlook_Spur", 4.15, 1.90, 1.62, 6, 28841),
]


def _purge() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _diaclases(graine: int):
    """Relief radial VERROUILLÉ SUR L'AZIMUT — trois harmoniques de phase
    fixe, plus deux entailles profondes. La fonction ne dépend que de
    l'angle : le creux se retrouve à chaque banc et devient une fracture
    filante, au lieu d'un bruit qui change d'étage en étage."""
    # v3 — AMPLITUDES PRESQUE TRIPLÉES, et c'est le correctif de fond.
    # Aux amplitudes d'origine (7 %, 5 %, 3 %) chaque banc était un anneau
    # quasi circulaire : une fois la valeur juste, la pile lisait « tambours
    # empilés » encore plus nettement qu'en blanc (capture iter3). Un relief
    # radial fort produit des CÔTES verticales qui traversent tous les bancs
    # — une falaise se lit à ses contreforts autant qu'à ses strates. Et
    # trois entailles franches, plus étroites, font de vraies diaclases.
    rng = random.Random(graine)
    harmoniques = []
    for ordre, amplitude in ((2, 0.185), (3, 0.130), (5, 0.075),
                             (8, 0.042)):
        harmoniques.append((ordre, amplitude, rng.uniform(0.0, math.tau)))
    entailles = [(rng.uniform(0.0, math.tau), rng.uniform(0.22, 0.31),
                  rng.uniform(0.14, 0.24)) for _ in range(3)]

    def relief(angle: float) -> float:
        v = 0.0
        for ordre, amplitude, phase in harmoniques:
            v += amplitude * math.sin(ordre * angle + phase)
        for centre, profondeur, largeur in entailles:
            d = abs((angle - centre + math.pi) % math.tau - math.pi)
            if d < largeur:
                v -= profondeur * (0.5 + 0.5 * math.cos(math.pi * d / largeur))
        return v

    return relief


def _profil_bancs(nb: int, hauteur: float, graine: int):
    """Épaisseurs et retraits des bancs.

    Le retrait n'est PAS monotone : un banc peut DÉBORDER celui du dessous
    (corniche en surplomb). Une pile qui ne fait que rétrécir se relit comme
    un cône, et un cône régulier est précisément le défaut reproché ailleurs
    dans ce lot.
    """
    rng = random.Random(graine + 7)
    # v2 — ÉPAISSEURS BEAUCOUP PLUS INÉGALES. À (0,72 ; 1,35) les bancs
    # sortaient quasi identiques et la pile lisait « pile d'assiettes »
    # (capture iter1). Un banc mince entre deux gros est ce qui fait une
    # stratification crédible.
    epaisseurs = [rng.uniform(0.34, 1.90) for _ in range(nb)]
    somme = sum(epaisseurs)
    epaisseurs = [e * hauteur / somme for e in epaisseurs]
    facteurs = [1.10]  # le pied s'évase : point 4 de l'en-tête
    courant = 1.0
    for k in range(1, nb):
        # v3 — RETRAIT DIVISÉ PAR DEUX. À −0,07..−0,17 par banc, le sommet
        # tombait à ~0,40 du pied après sept bancs : un CÔNE, et un cône
        # régulier de disques est la « pièce montée » relevée sur capture.
        # Ici le sommet reste vers 0,70 : une masse qui garde son épaule.
        if rng.random() < 0.34 and k not in (1, nb - 1):
            pas = rng.uniform(0.02, 0.07)
        else:
            pas = -rng.uniform(0.04, 0.11)
        courant = max(0.45, courant + pas)
        facteurs.append(courant)
    # LE RETRAIT EST LOPSIDE, ET C'EST LE CORRECTIF PRINCIPAL DE LA v2.
    # En v1 chaque banc retirait de la même quantité sur TOUT son pourtour :
    # la vire faisait donc un anneau complet, et une pile d'anneaux complets
    # est une pièce montée, pas une falaise. Ici chaque banc reçoit une
    # amplitude et un azimut propres : d'un côté il est en retrait franc (une
    # large vire), de l'autre il affleure le banc du dessous (le mur reste
    # continu). Aucun replat ne fait plus le tour.
    amplitudes = [rng.uniform(0.18, 0.34) for _ in range(nb)]
    azimuts = [rng.uniform(0.0, math.tau) for _ in range(nb)]
    return epaisseurs, facteurs, amplitudes, azimuts


def _teinte_banc(k: int, nb: int, t_haut: float, creux: float,
                 dessous: bool, angle: float = 0.0,
                 t_local: float = 0.5) -> tuple:
    """Couleur de sommet d'un coin de banc.

    v4 — LA TROISIÈME HYPOTHÈSE, ET ELLE N'EST PAS GÉOMÉTRIQUE.

    Deux passes de géométrie (retrait lopside, puis diaclases profondes et
    retrait divisé par deux) ont chacune changé les pixels, et le défaut
    « pile de dalles » a persisté : les faces restent de GRANDS APLATS. La
    règle des deux échecs dit d'arrêter de régler des constantes et de
    changer d'hypothèse — c'est ce que fait cette passe.

    La cause est déjà écrite dans le dépôt, chiffrée par le générateur des
    stèles du champ : sur des faces quasi verticales, sous ce ciel,
    l'irradiance ambiante domine et l'orientation des normales ne rapporte
    presque rien (une face y rendait UNE seule valeur, p10-p90 = 1 niveau,
    pour 465 normales distinctes). Ce n'est donc pas plus de relief qu'il
    faut, c'est de la VALEUR dans la face.

    Six modulations désormais, dont trois neuves :
      * bande de banc (les strates alternent) ;
      * hauteur d'ensemble (le pied s'assombrit et verdit) ;
      * creux de diaclase, RENFORCÉ (0,30 → 0,45) ;
      * dessous de vire (une surface qui ne voit pas le ciel est plus froide) ;
      * **joint de banc** : le bas de chaque banc est nettement plus sombre
        — c'est le trait qui fait lire un lit sédimentaire, et il vit dans la
        valeur, pas dans la forme ;
      * **arête haute** et **mouchetage verrouillé sur l'azimut** : la face
        cesse d'être un aplat.
    """
    bande = 1.0 + (0.085 if k % 2 == 0 else -0.075)
    # `t_haut` 0 au pied, 1 au sommet : le pied s'assombrit et verdit.
    pied = max(0.0, 1.0 - t_haut * 2.4)
    ombre = 1.0 - 0.45 * max(0.0, creux)
    # Joint : sombre au pied du banc, remonte vite. Une strate se lit à son
    # ombre de lit autant qu'à son ressaut.
    ombre *= 0.70 + 0.30 * min(1.0, max(0.0, t_local) * 3.4)
    # Arête haute du banc, là où la lumière frise.
    if t_local > 0.86:
        ombre *= 1.0 + 0.06 * (t_local - 0.86) / 0.14
    # Mouchetage VERROUILLÉ SUR L'AZIMUT : il survit d'un banc au suivant et
    # devient une trace verticale, au lieu d'un bruit qui change d'étage.
    ombre *= 1.0 + 0.075 * math.sin(7.0 * angle + 2.1) \
        * math.cos(3.0 * angle + 0.7)
    r = NIVEAU * bande * ombre
    g = NIVEAU * bande * ombre
    b = NIVEAU * bande * ombre
    r *= (1.0 - 0.22 * pied)
    g *= (1.0 - 0.10 * pied)
    b *= (1.0 - 0.26 * pied)
    if dessous:
        r *= 0.82
        g *= 0.86
        b *= 0.94
    borne = lambda v: max(0.30, min(1.0, v))
    return (borne(r), borne(g), borne(b))


def _croc(nom: str, hauteur: float, demi_a: float, demi_b: float, nb_bancs: int,
          graine: int, mat_corps, mat_fracture):
    rng = random.Random(graine)
    relief = _diaclases(graine)
    epaisseurs, facteurs, amplis, azimuts = _profil_bancs(
        nb_bancs, hauteur, graine)

    dip = math.radians(PENDAGE_DEG)
    az = math.radians(PENDAGE_AZIMUT)
    # Cisaillement : chaque mètre de hauteur décale le banc de tan(pendage)
    # dans l'azimut du pendage. Les deux masses partagent az et dip.
    decal = Vector((math.cos(az), math.sin(az), 0.0)) * math.tan(dip)

    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()

    # Phase d'échantillonnage TOURNANTE : les arêtes longitudinales cessent
    # d'être des méridiens exacts, chaque quad se vrille légèrement.
    def anneau(z: float, facteur: float, phase: float, jitter: float,
               ampli: float = 0.0, azimut: float = 0.0):
        sommets = []
        infos = []
        for j in range(COTES):
            angle = math.tau * j / COTES + phase
            creux = -min(0.0, relief(angle))
            rayon = 1.0 + relief(angle)
            # Retrait LOPSIDE : le banc est plein d'un côté, retiré de
            # l'autre. C'est ce qui empêche la vire de faire le tour.
            rayon *= facteur * (1.0 + ampli * math.cos(angle - azimut))
            rayon *= (1.0 + rng.uniform(-jitter, jitter))
            x = math.cos(angle) * demi_a * rayon
            y = math.sin(angle) * demi_b * rayon
            p = Vector((x, y, z)) + decal * z
            sommets.append(bm.verts.new(p))
            infos.append(creux)
        return sommets, infos

    z = 0.0
    faces_corps = []
    faces_fracture = []
    vires = 0
    couleurs = {}
    bas_precedent = None
    for k in range(nb_bancs):
        haut = z + epaisseurs[k]
        phase = 0.11 * k
        # Le nu du banc : deux anneaux de MÊME rayon → paroi verticale.
        bas, creux_bas = anneau(z, facteurs[k], phase, 0.020, amplis[k],
                                azimuts[k])
        sommet, creux_haut = anneau(haut, facteurs[k] * 0.985, phase + 0.03,
                                    0.020, amplis[k], azimuts[k])
        for j in range(COTES):
            m = (j + 1) % COTES
            faces_corps.append(bm.faces.new((bas[j], bas[m], sommet[m],
                                             sommet[j])))
        t0 = z / hauteur
        t1 = haut / hauteur
        for j in range(COTES):
            az_j = math.tau * j / COTES + phase
            couleurs[bas[j]] = _teinte_banc(k, nb_bancs, t0, creux_bas[j],
                                            False, az_j, 0.0)
            couleurs[sommet[j]] = _teinte_banc(k, nb_bancs, t1, creux_haut[j],
                                               False, az_j, 1.0)
        # La VIRE : l'anneau horizontal qui rejoint le banc suivant. C'est
        # elle qui fait la strate — on la compte, et le contrôle final exige
        # un minimum.
        if k + 1 < nb_bancs:
            suivant, creux_s = anneau(haut, facteurs[k + 1], phase + 0.14,
                                      0.020, amplis[k + 1], azimuts[k + 1])
            surplomb = facteurs[k + 1] > facteurs[k]
            for j in range(COTES):
                m = (j + 1) % COTES
                faces_corps.append(bm.faces.new((sommet[j], sommet[m],
                                                 suivant[m], suivant[j])))
            for j in range(COTES):
                couleurs[suivant[j]] = _teinte_banc(
                    k + 1, nb_bancs, t1, creux_s[j], surplomb,
                    math.tau * j / COTES + phase + 0.14, 0.0)
            if not surplomb:
                vires += 1
            bas_precedent = suivant
        else:
            bas_precedent = sommet
        z = haut

    # LA COURONNE ROMPUE : le chapeau est coupé par un plan incliné. Un
    # sommet plat se relit comme le couvercle d'une boîte.
    pente = Vector((math.cos(az + 1.1), math.sin(az + 1.1), 0.0))
    centre_haut = Vector((0.0, 0.0, 0.0))
    for v in bas_precedent:
        centre_haut += v.co
    centre_haut /= COTES
    # v2 — l'apex se DÉCALE vers l'aval du pendage et monte davantage : en
    # v1 le chapeau était un cône presque symétrique, donc un couvercle.
    centre_haut.z += hauteur * 0.038
    centre_haut.x += pente.x * demi_a * 0.62
    centre_haut.y += pente.y * demi_b * 0.62
    for v in bas_precedent:
        # Un côté monte vers l'arête vive, l'autre s'écroule.
        d = (Vector((v.co.x, v.co.y, 0.0)) - Vector((centre_haut.x,
             centre_haut.y, 0.0))).normalized().dot(pente)
        v.co.z += hauteur * 0.090 * d
    faîte = bm.verts.new(centre_haut)
    for j in range(COTES):
        m = (j + 1) % COTES
        faces_fracture.append(bm.faces.new((bas_precedent[j],
                                            bas_precedent[m], faîte)))
    couleurs[faîte] = (0.98, 0.99, 1.00)

    # Fond plat à z = 0 : la pièce sera enterrée, mais un solide ouvert
    # laisserait voir l'intérieur au moindre écart d'assise.
    premier = [v for v in bm.verts if abs(v.co.z) < 1e-6]
    ordonne = sorted(premier, key=lambda v: math.atan2(v.co.y, v.co.x))
    teinte_pied = tuple(c * NIVEAU for c in TEINTE_PIED)
    # ANNEAU INTERMÉDIAIRE : un éventail direct depuis le centre sur un rayon
    # de 3,5 m rend des facettes de 1,9 m² — au-dessus du plafond, et c'est
    # exactement le mode de panne « grande face plane » que le contrôle existe
    # pour interdire. Deux couronnes, donc.
    milieu = []
    for v in ordonne:
        w = bm.verts.new(Vector((v.co.x * 0.45, v.co.y * 0.45, 0.0)))
        couleurs[w] = teinte_pied
        milieu.append(w)
    centre_bas = bm.verts.new(Vector((0.0, 0.0, 0.0)))
    couleurs[centre_bas] = teinte_pied
    n = len(ordonne)
    for j in range(n):
        m = (j + 1) % n
        faces_corps.append(bm.faces.new((ordonne[m], ordonne[j], milieu[j],
                                         milieu[m])))
        faces_corps.append(bm.faces.new((milieu[m], milieu[j], centre_bas)))

    for face in faces_fracture:
        face.material_index = 1

    # COULEUR DE SOMMET sur une couche de BOUCLE (par coin de face) — c'est
    # ce que l'exporter glTF écrit en `COLOR_0`. `float_color` et non
    # `color` : une couche d'OCTETS est interprétée en sRGB par Blender, une
    # couche flottante est linéaire, et glTF/Godot attendent du linéaire.
    couche = bm.loops.layers.float_color.new("Col")
    bm.verts.index_update()
    for face in bm.faces:
        for boucle in face.loops:
            t = couleurs.get(boucle.vert, (1.0, 1.0, 1.0))
            boucle[couche] = (t[0], t[1], t[2], 1.0)

    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.normal_update()
    bm.to_mesh(maillage)
    bm.free()

    # La couche doit être l'attribut de couleur ACTIF et celui de RENDU :
    # l'exporter glTF 4.0 n'écrit `COLOR_0` que pour celui-là (ISS-066).
    if "Col" in maillage.color_attributes:
        maillage.color_attributes.active_color_index = \
            maillage.color_attributes.find("Col")
        maillage.color_attributes.render_color_index = \
            maillage.color_attributes.find("Col")

    maillage.materials.append(mat_corps)
    maillage.materials.append(mat_fracture)
    objet = bpy.data.objects.new(nom, maillage)
    bpy.context.scene.collection.objects.link(objet)
    return objet, vires


## Matériau : `Base Color = couleur × attribut « Col »`.
##
## LE BRANCHEMENT N'EST PAS COSMÉTIQUE (ISS-066) : l'exporter glTF de
## Blender 4.0 n'écrit `COLOR_0` que si le MATÉRIAU consomme réellement
## l'attribut. Sans lui, le `.glb` sort avec POSITION et NORMAL seulement —
## aucune erreur, aucun avertissement, un asset silencieusement plat.
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
        principled.inputs["Roughness"].default_value = 0.94
    if "Metallic" in principled.inputs:
        principled.inputs["Metallic"].default_value = 0.0
    if "Specular IOR Level" in principled.inputs:
        principled.inputs["Specular IOR Level"].default_value = 0.18
    elif "Specular" in principled.inputs:
        principled.inputs["Specular"].default_value = 0.18
    return mat


def main() -> int:
    _purge()
    mat_corps = _materiau("MAT_Crag_Slate", MAT_ARDOISE)
    mat_fracture = _materiau("MAT_Crag_Fracture", MAT_FRACTURE)

    total_tris = 0
    for nom, hauteur, demi_a, demi_b, nb_bancs, graine in CROCS:
        objet, vires = _croc(nom, hauteur, demi_a, demi_b, nb_bancs, graine,
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
        aire_max = max(p.area for p in maillage.polygons)

        attribut = maillage.color_attributes.get("Col")
        if attribut is None:
            print("%s ERREUR: %s sans couche de couleur de sommet" % (TAG, nom))
            return 2
        luminances = sorted(
            0.2126 * d.color[0] + 0.7152 * d.color[1] + 0.0722 * d.color[2]
            for d in attribut.data)
        p10 = luminances[len(luminances) // 10]
        p90 = luminances[9 * len(luminances) // 10]
        moyenne = sum(luminances) / len(luminances)
        etendue = (p90 - p10) / max(moyenne, 1e-6)

        print("%s %s : %d tris, hauteur %.3f m, base z %.4f, emprise %.3f m, "
              "vires %d, facette max %.4f m2, couleur p10 %.3f p90 %.3f "
              "(etendue %.1f %%)"
              % (TAG, nom, tris, haut_reel, base, largeur, vires, aire_max,
                 p10, p90, 100.0 * etendue))

        if abs(base) > 0.001:
            print("%s ERREUR: %s base a z=%.4f, pas 0" % (TAG, nom, base))
            return 2
        # `hauteur` est celle de la PILE DE BANCS ; la couronne rompue ajoute
        # par construction jusqu'à ~11 % (elle a été franchement dissymétrisée
        # en v2 pour cesser de lire « couvercle »). La fourchette dit donc
        # explicitement ce que le générateur fait, au lieu d'être ajustée en
        # douce après coup pour laisser passer un résultat.
        if not (hauteur * 0.92 <= haut_reel <= hauteur * 1.18):
            print("%s ERREUR: %s hauteur %.3f hors fourchette autour de %.3f"
                  % (TAG, nom, haut_reel, hauteur))
            return 2
        if vires < VIRES_MIN:
            print("%s ERREUR: %s n'a que %d vire(s) (< %d) — sans vire c'est "
                  "un galet, pas une strate ; c'est le defaut mesure"
                  % (TAG, nom, vires, VIRES_MIN))
            return 2
        if aire_max > AIRE_FACETTE_MAX:
            print("%s ERREUR: %s porte une facette de %.4f m2 (> %.4f)"
                  % (TAG, nom, aire_max, AIRE_FACETTE_MAX))
            return 2
        if etendue < ETENDUE_COULEUR_MIN:
            print("%s ERREUR: %s etendue de couleur %.1f %% < %.1f %% — "
                  "la face rendrait un aplat" % (TAG, nom, 100.0 * etendue,
                                                 100.0 * ETENDUE_COULEUR_MIN))
            return 2
        if p90 > 1.0001:
            print("%s ERREUR: %s couleur de sommet > 1 (%.3f) — ecretee a "
                  "l export sans avertissement" % (TAG, nom, p90))
            return 2

    print("%s pendage partage : azimut %.1f deg, angle %.1f deg"
          % (TAG, PENDAGE_AZIMUT, PENDAGE_DEG))
    print("%s total %d triangles (plafond %d)" % (TAG, total_tris, BUDGET_TRIS))
    if total_tris > BUDGET_TRIS:
        print("%s ERREUR: budget de triangles depasse" % TAG)
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_OverlookCrags.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("%s source enregistree -> %s" % (TAG, sortie))
    print("FIN NOMINALE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
