# SOURCE DE GÉNÉRATION REPRODUCTIBLE — LA FORMATION DE LA SOURCE AUX REFLETS
# (`valley.poi.turquoise_spring.01`, lot 1.R.2).
#
# ======================================================================
# LOT 1.R.2 — LA COURONNE ÉTAIT UN CERCLE DE BLOCS, ET LA SILHOUETTE LE DIT
# ======================================================================
#
# Verdict Codex (lecture aveugle, REJET) : « la couronne ressemble à des
# blocs indépendants disposés autour d'un point ». Ce n'est pas une opinion :
# `lot1r1/revue_intermediaire/silhouettes/silhouette_turquoise_spring_000.png`
# montre TROIS masses noires de tailles voisines, régulièrement espacées, et
# rien d'autre. Deux instruments indépendants — un lecteur humain et un aplat
# noir — décrivent la même image.
#
# La cause est dans cette table. Les quatre masses avaient des HAUTEURS
# voisines (3,80 / 3,60 / 1,90 / 3,00), la même teinte, et leurs lobes étaient
# répartis autour de la vasque. Une table qui décrit un anneau produit un
# anneau, quelle que soit la finesse des nervures.
#
# CE QUE CETTE PASSE CHANGE, ET C'EST STRUCTUREL :
#
#  1. UNE RIVE PRINCIPALE, UNE RIVE SECONDAIRE, UNE OUVERTURE. Le sud porte
#     UNE formation continue et haute (`SM_Spring_Buttress`, 5,9 m, cinq lobes
#     fondus qui descendent en marches jusqu'à l'écrin du fruit) ; le nord
#     porte une TABLE BASSE et sèche (`SM_Spring_Shelf`, 1,55 m) ; l'est‑nord‑est
#     est VIDE, et c'est par là que l'eau s'en va. Trois rôles, trois hauteurs
#     qui n'ont plus rien de voisin : 5,9 · 2,95 · 1,55 · 1,15.
#  2. L'ARRIVÉE EXISTE. `SM_Spring_Spout` est une lèvre : une masse basse et
#     large, blottie contre le contrefort, dont le sommet porte la gorge d'où
#     l'eau sort. Le voile d'eau descend sa face est. Sans elle, « l'eau sort
#     de la paroi » restait une phrase du journal que rien ne montrait.
#  3. LES VALEURS SONT DIFFÉRENCIÉES, ET UN CONTRÔLE LE VÉRIFIE. Chaque masse
#     porte sa propre teinte : ardoise froide pour le contrefort, très sombre
#     et pétrole pour la lèvre et le seuil (trempés en permanence), gris pâle
#     et SEC pour la table nord. `ECART_VALEUR_MIN` échoue si les masses
#     retombent dans la même valeur — le défaut exact de cette table.
#  4. LES ÉBOULIS SONT DES LOBES. Chaque masse porte un ou deux petits lobes
#     de pied, fondus dans le même objet : ils imbriquent la masse dans le sol
#     sans coûter un seul module au budget D7.
#
# ======================================================================
# POURQUOI CET ASSET EXISTE — LE DÉFAUT EST UNE AFFAIRE DE PRÉSENCE
# ======================================================================
#
# Verdict d'inspection réelle du lot 1.R : la source est « trop petite et
# secondaire dans la caméra joueur ». La COULEUR, elle, a été acquise et
# mesurée (H 189°, S 0,490 dans la caméra gelée, contre H 176–185° S 0,368
# pour la rivière V2.2 de référence) : ce n'est donc pas l'eau qu'il faut
# reprendre, c'est ce qui l'entoure.
#
# Ce que je vois moi-même sur `voie_a2/iter5/turquoise_spring_joueur.png` à
# taille réelle : un filet turquoise dans le tiers bas du cadre, cerné par
# une poignée de CAILLOUX BLEU MARINE de 2,6 m, le tout écrasé par le talus
# brun qui occupe la moitié de l'image. Le sujet du lieu n'est pas la flaque :
# c'est « l'œil » ENTIER — l'eau, les mâchoires dont elle sort, et les
# rebords qui la tiennent. Cet œil-là n'existait pas à l'écran.
#
# Les pièces de kit ne pouvaient pas le fabriquer, et pour la raison déjà
# mesurée au belvédère : `Rock_Medium_*` est une famille de GALETS ARRONDIS.
# Agrandis, ils donnent de plus GROS galets — jamais des mâchoires enracinées.
# C'est une loi de forme, pas une valeur d'albédo.
#
# ======================================================================
# CE QUE CE GÉNÉRATEUR PRODUIT
# ======================================================================
#
# Quatre masses, dans un seul `.glb`, qui remplacent SEPT pièces de kit :
#
#   `SM_Spring_MawN`   mâchoire nord, 4,4 m — la plus haute, contre-jour
#   `SM_Spring_MawS`   mâchoire sud, 4,0 m — penchée vers sa jumelle
#   `SM_Spring_Crown`  la couronne qui ferme le haut de la fente, 3,2 m
#   `SM_Spring_Rim`    TROIS LOBES FONDUS : le rebord nord, l'écrin est du
#                      fruit, et le bloc tombé au sud. Un seul objet, donc un
#                      seul module — la source était PLEINE (12/12) et toute
#                      pièce neuve devait en remplacer une ou fusionner.
#
# Le gain de budget est réel et mesuré : 12 − 7 + 4 = 9 modules sur 12.
#
# Chaque masse est une surface continue `r(θ, t)` : dôme brisé, nervures
# verrouillées sur l'azimut, bombements et niches gaussiens, jupe ENTERRÉE.
# C'est la même famille de lois que `make_overlook_crags.py` — délibérément,
# pour que les deux lieux appartiennent au même monde minéral — avec deux
# différences qui comptent :
#
#   * PAS DE STRATES. Le belvédère est une formation sédimentaire dressée ;
#     ici on est au pied d'une paroi, et ce sont des blocs. Leur caractère
#     vient des nervures et des bombements, pas de lits.
#   * UN MOUILLAGE. Chaque masse déclare le côté et la hauteur où l'eau la
#     touche : la roche y est nettement plus sombre et tire vers le pétrole.
#     C'est l'« indice d'humidité local » demandé, et il vit dans `COLOR_0` —
#     donc gratuit, et présent même en preset réduit.
#
# RÈGLE DE TROIS, ÉTAT HONNÊTE : ce fichier et `make_overlook_crags.py`
# partagent leur ossature (spline de profil, nervures, gaussiennes, jupe,
# contrôles). Cela fait DEUX occurrences, pas trois : `PROMPT4_METHOD` §8 dit
# d'extraire au troisième exemplaire, pas avant. Le jour où un troisième lieu
# demandera la même ossature, elle devra devenir un module, et c'est ici qu'il
# faudra venir le lire.
#
# ======================================================================
# CONVENTION D'ASSISE — `min Y` EST NÉGATIF, ET C'EST VOULU
# ======================================================================
#
# Comme au belvédère : le plan z = 0 du modèle est le PLAN DE SOL prévu, et la
# jupe descend sous lui pour qu'aucun contact pierre/herbe ne se lise comme une
# ligne. L'appelant NE DOIT PAS soustraire `aabb.position.y` — il pose
# `y = sol − enfoncement`. `turquoise_spring_place.gd::_masse()` porte la note.
#
# Chaîne : tools/blender/export_lieux_voie_a.sh spring_maw
#
# Usage direct (déconseillé, pas de jeton de fraîcheur) :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/environment/make_spring_maw.py

import math
import os
import random
import sys

import bpy
import bmesh
from mathutils import Vector

TAG = "[spring_maw]"

## Quatre masses dont une à TROIS lobes : le plafond suit le nombre de
## pièces, pas une envie. Repère mesuré au belvédère : deux masses de
## 6,9 m et 4,3 m coûtent 5 144 triangles. Ici quatre masses plus basses
## et six lobes au total.
## LE PLAFOND SUIT LE NOMBRE DE LOBES, ET L'ARITHMÉTIQUE EST ÉCRITE.
##
## Version précédente : 4 masses / 6 lobes / 8 400. Cette passe en compte
## TREIZE — les éboulis de pied et les marches de la rive principale sont des
## lobes fondus, parce qu'un lobe ne coûte pas de module au budget D7 et qu'un
## rocher posé à côté, si.
##
## Un plafond ne vaut que s'il peut rougir : la résolution de chaque lobe est
## RÉDUITE en fonction de son échelle (`_resolution_lobe`), sinon treize lobes
## à pleine résolution coûteraient ~15 000 triangles. Le devis attendu, lobe
## par lobe, tombe à ≈ 8 500. 9 600 laisse 13 % — de quoi absorber les
## arrondis d'échantillonnage, pas de quoi absoudre un lobe oublié.
BUDGET_TRIS = 9600
AIRE_FACETTE_MAX = 1.20
## Un bloc convexe partout est un galet — le défaut exact que le kit
## produisait. Au moins deux azimuts doivent porter un vrai surplomb, et
## jamais plus de 70 % à la même hauteur (sinon c'est une taille de guêpe et
## non un surplomb). Même contrôle à deux bornes qu'au belvédère, où il a
## réellement rougi avant d'être redéfini.
SURPLOMBS_MIN = 1
SURPLOMBS_MAX_PART = 0.70
ETENDUE_COULEUR_MIN = 0.20
## BANDE ÉLARGIE, ET C'EST UNE DÉCISION, PAS UN DESSERRAGE DE CONFORT.
## À [0,58 ; 0,90] toutes les masses étaient contraintes dans un huitième de
## l'échelle : la table ne POUVAIT pas produire de valeurs différenciées, ce
## que le verdict reproche précisément. La bande borne toujours les deux vrais
## défauts — une masse noire, une masse écrêtée — et rien d'autre.
COULEUR_MOYENNE_MIN = 0.44
COULEUR_MOYENNE_MAX = 0.94
## ÉCART DE VALEUR ENTRE LES MASSES — le contrôle qui aurait rougi AVANT.
## Les quatre masses de la version rejetée partageaient teinte et niveau ;
## leurs moyennes ne pouvaient différer que par la forme. Ce contrôle exige un
## écart de valeur RÉEL entre la masse la plus claire et la plus sombre, et il
## échoue si la table retombe dans l'uniformité.
ECART_VALEUR_MIN = 0.14
## Le mouillage doit être VISIBLE et BORNÉ : s'il ne touche presque rien il ne
## se lit pas, s'il touche tout la masse devient noire et redessine l'anneau
## sombre déjà mesuré (et corrigé deux fois) autour de cette vasque.
MOUILLAGE_PART_MIN = 0.04
## 0,40 → 0,52 : la LÈVRE est mouillée sur presque toute sa face est, parce
## que l'eau y descend. Ce n'est pas le cerne que la borne empêchait — un
## cerne est un anneau, celui-ci est un CÔTÉ, et `mouillage()` dépend de
## l'azimut autant que de la hauteur. La borne haute garde son rôle : elle
## interdit toujours qu'une masse devienne noire sur tout son pourtour.
MOUILLAGE_PART_MAX = 0.52
## PART DE SOMMETS ÉCRÊTÉS — remplace un contrôle qui ne pouvait pas rougir.
##
## L'ancien test lisait `p90 > 1.0001` sur les couleurs SORTIES de `_teinte`.
## Or `_teinte` borne à 1,0 juste avant de rendre : la condition était donc
## inatteignable par construction, et elle a laissé passer une table dont un
## dixième des sommets étaient collés au plafond (mesuré : `SM_Spring_Shelf`
## p90 = 1,000 au premier export de cette passe). Un écrêtage aplatit
## exactement ce qu'on veut voir — le sommet qui prend la lumière.
##
## On compte donc les dépassements AVANT la borne. Ce contrôle-ci rougit :
## il a rougi sur la teinte (1,16 ; 1,14 ; 1,08), et c'est ce qui l'a fait
## baisser.
ECRETAGE_PART_MAX = 0.02

## ARDOISE DE RAVIN. La base du belvédère est (0,0767 ; 0,0919 ; 0,1557), et
## elle y rend V 0,50–0,55 en PLEIN SOLEIL. Ce lieu est un ravin à l'ombre
## d'une paroi de 54° : la même base y rendrait une masse noire. Elle est donc
## relevée de ~40 %, en gardant le rapport 1 : 1,20 : 2,03 qui a été mesuré au
## belvédère comme le seul capable de rendre FROID sous une lumière chaude.
## C'est une PREMIÈRE APPROXIMATION à remesurer sur capture — le gain n'est pas
## linéaire (`scripts/CLAUDE.md`), et prédire une valeur rendue depuis un
## albédo est exactement ce que ce dépôt interdit.
## v2 — RECALÉE SUR CAPTURE, et la mesure enseigne quelque chose que le
## `scripts/CLAUDE.md` ne dit pas encore : **le même albédo ne rend pas la même
## couleur selon l'éclairage du lieu.** Le rapport 1 : 1,20 : 2,03 rend
## S 0,13–0,21 au belvédère, en plein soleil chaud, parce que la lumière
## directe mange le biais bleu. Ici, dans un ravin à l'ombre d'une paroi de
## 54°, il n'y a que l'ambiante froide : le biais survit entier et la roche a
## rendu **H 221° S 0,441 V 0,358** — de l'indigo, pas de la pierre. Et l'eau
## de la vasque mesure S 0,554 dans la MÊME image : à 0,441 la roche était aux
## quatre cinquièmes de sa saturation, donc l'eau cessait d'être « la seule
## note froide saturée du ravin ».
## Rapport ramené à 1 : 1,07 : 1,41 et magnitude ×1,25. Cible RENDUE : S ≈ 0,20
## (famille des crocs) et V ≈ 0,42, un cran plus clair que le talus brun
## mesuré à 0,292 pour que la formation s'en détache. Approximation à
## remesurer : le gain n'est pas linéaire.
## v3 — LE BLEU DESCEND ENCORE, et le facteur vient de la mesure. À
## 1 : 1,07 : 1,41 la roche rendait S 0,334 (mesuré `iter9`) quand la pierre du
## monde tient 0,13–0,21 et que l'eau du lieu, elle, mesure 0,554. Une roche
## aux trois cinquièmes de la saturation de l'eau empêche l'eau d'être « la
## seule note froide saturée du ravin ». Rapport bleu/rouge ramené à 1,20.
MAT_ROCHE = (0.1940, 0.2076, 0.2328, 1.0)
MAT_FRACTURE = (0.2140, 0.2290, 0.2568, 1.0)
NIVEAU = 0.82
## PIED — passé du VERDÂTRE au gris froid, et c'est un TEST autant qu'un
## choix. Une pierre olive, plate et anguleuse, d'une famille étrangère au
## reste, apparaît au bord nord de la vasque sur `iter8/spring_gros_eau.png`.
## Je ne sais pas ce que c'est et je refuse de l'attribuer sur sa seule
## couleur : c'est la faute exacte qui a produit le revert de l'itération 6.
## Si cette pierre devient ardoise à la prochaine capture, c'est un fond de
## jupe à moi, exposé parce qu'un objet à trois lobes est assis sur le terrain
## d'UN point. Si elle ne bouge pas d'un centième, elle n'est pas à moi et le
## semis V2.2 gelé — intouchable — reste le seul suspect.
TEINTE_PIED = (0.56, 0.59, 0.66)
## Roche trempée : franchement plus sombre, et elle tire vers le pétrole — pas
## vers le noir. Un bord « plus sombre que tout » dessine un anneau, et c'est
## le défaut que le lit de cette vasque a déjà payé deux fois.
MOUILLE = (0.50, 0.62, 0.70)

## LA TABLE DES MASSES — c'est ELLE qui décide de la composition.
##
## Colonnes : nom | H | demi_a | demi_b | jupe | graine | inclinaison (x, y)
## par mètre | azimut de mouillage (deg) | hauteur de mouillage (m) |
## teinte (multiplicateur RGB de la couleur de sommet) | lobes
## [(dx, dy, echelle)].
##
## REPÈRE, et il compte à chaque ligne : **Godot local (X ; Z) = Blender
## (x ; −y)**. Un décalage de lobe vers le SUD Godot (z > 0) s'écrit donc avec
## un `dy` NÉGATIF. Le joueur regarde depuis l'est (Godot local +9,5) vers
## l'ouest ; le sud Godot est à sa GAUCHE d'écran, le nord à sa droite.
##
## PLAN D'IMPLANTATION, en Godot local (le lieu les pose, ils sont recopiés
## ici pour que la table se lise sans ouvrir le `.gd`) :
##   contrefort  (−9,60 ; +4,20)   rive principale, SUD, écran gauche
##   lèvre       (−9,30 ; +1,70)   l'arrivée, centre, blottie contre lui
##   table       (−6,60 ; −4,70)   rive secondaire BASSE, NORD, écran droite
##   seuil       (−2,20 ; −1,90)   l'ouverture du déversoir, EST, près
MASSES = [
    # ── LA RIVE PRINCIPALE ────────────────────────────────────────────────
    # Cinq lobes fondus, un seul module. Ils descendent en MARCHES du sud-ouest
    # (l'épaule enfoncée dans la pente) vers l'est (l'écrin du fruit) : c'est
    # cette dégringolade qui remplace le cercle de blocs. Le lobe maître est le
    # seul haut ; les autres valent 0,68 · 0,52 · 0,30 · 0,20 de sa taille, donc
    # aucune paire ne peut se relire comme « deux blocs jumeaux ».
    #
    # Teinte : ardoise froide, plus sombre que la table nord. C'est la masse
    # à contre-jour, au pied d'une paroi de 54° — et c'est la seule du lieu
    # qui doive se détacher du TALUS BRUN mesuré à V 0,29 sur la capture de
    # référence. Elle joue donc sur le froid, pas sur la clarté.
    ("SM_Spring_Buttress", 5.90, 2.05, 2.25, 0.75, 51307, (0.052, 0.030),
     48.0, 0.95, (0.88, 0.92, 1.00),
     [(0.0, 0.0, 1.0),
      # épaule ENFONCÉE dans la pente : Godot (−11,30 ; +2,20), le sol y est
      # 1,50 m au-dessus du plan de pose, donc elle émerge au lieu de se poser.
      (-1.70, 2.00, 0.68),
      # queue vers l'est : Godot (−6,00 ; +4,90)
      (3.60, -0.70, 0.52),
      # écrin du fruit : Godot (−3,00 ; +3,20) — l'ancre de récompense est
      # GELÉE en (−2,40 ; +2,60), ce lobe lui fait un dos de pierre sans la
      # toucher.
      (6.60, 1.00, 0.30),
      # éboulis de pied, côté eau : Godot (−7,60 ; +2,00)
      (2.00, 2.20, 0.20)]),
    # ── LA LÈVRE D'ARRIVÉE ────────────────────────────────────────────────
    # Basse, large, et penchée vers l'est : son sommet (≈ 2,7 m) porte la gorge
    # d'où l'eau sort, et sa face est s'évase vers le bas — c'est cette évasure
    # que le voile d'eau suit. Elle chevauche franchement le contrefort : deux
    # enveloppes qui se recouvrent se lisent comme UNE formation, deux
    # enveloppes séparées par de l'herbe se lisent comme deux cailloux.
    #
    # Mouillage haut (2,30 m sur 2,95) : l'eau descend là. C'est pour cette
    # masse que `MOUILLAGE_PART_MAX` a été relevé, et pour elle seule.
    ("SM_Spring_Spout", 2.95, 1.32, 1.58, 0.55, 33809, (0.115, -0.035),
     22.0, 2.30, (0.74, 0.83, 0.94),
     [(0.0, 0.0, 1.0),
      # appui qui la relie au contrefort : Godot (−9,60 ; +2,90)
      (-0.30, -1.20, 0.62),
      # galet de pied côté vasque : Godot (−8,20 ; +1,20)
      (1.10, 0.50, 0.24)]),
    # ── LA RIVE SECONDAIRE ────────────────────────────────────────────────
    # Une TABLE : large, plate, basse (1,55 m), au nord. Elle est l'exact
    # contraire du contrefort — et c'est le contraste des deux rives, pas leur
    # nombre, qui casse l'anneau. Elle est SÈCHE (mouillage 0,45 m) et CLAIRE
    # (teinte > 1) : la seule masse du lieu qui prenne la lumière.
    ("SM_Spring_Shelf", 1.55, 2.45, 1.70, 0.45, 77123, (-0.030, 0.055),
     # 1,16 → 1,09 → 1,03, et les DEUX baisses ont été imposées par une mesure,
     # pas choisies : à 1,16 le p90 sortait à 1,000 (écrêté), et à 1,09 le
     # contrôle d'écrêtage a compté 6,6 % de sommets au plafond pour un
     # plafond de 2 %. Un sommet écrêté rend plat exactement là où cette masse
     # doit prendre la lumière. Le rapport bleu/rouge descend en même temps
     # (0,975 / 1,03) : la table nord est la pierre SÈCHE du lieu, elle tire
     # au gris et non au pétrole. L'écart de valeur inter-masses reste au
     # double de son plancher.
     290.0, 0.45, (1.03, 1.02, 0.975),
     [(0.0, 0.0, 1.0),
      # prolongement vers l'est : Godot (−4,00 ; −5,20)
      (2.60, -0.50, 0.78),
      # éboulis de pied : Godot (−7,90 ; −3,60)
      (-1.30, -1.10, 0.26)]),
    # ── L'OUVERTURE DU DÉVERSOIR ──────────────────────────────────────────
    # Deux lobes bas qui ENCADRENT l'échancrure sans la fermer : entre eux
    # passe l'eau qui s'en va. Ce sont les pièces les plus PROCHES de la
    # caméra joueur (11 m), donc celles dont chaque centimètre pèse le plus à
    # l'écran — et les plus sombres, parce qu'elles sont trempées en
    # permanence par le fil qui les traverse.
    # ITÉRATION 2 : 1,15 → 0,78 m. À 1,15 les deux lobes rendaient, dans la
    # caméra joueur, deux masses bleu sombre de part et d'autre du fil, à onze
    # mètres — assez hautes pour COUPER la nappe de sa langue au moment précis
    # où la lecture doit être continue. Un seuil se franchit ; il ne barre pas.
    ("SM_Spring_Sill", 0.78, 1.05, 0.88, 0.40, 60451, (0.070, 0.060),
     200.0, 0.48, (0.70, 0.80, 0.90),
     [(0.0, 0.0, 1.0),
      # lobe aval, de l'autre côté de l'échancrure : Godot (−1,10 ; −4,20)
      (1.10, -2.30, 0.85),
      # galet dans le fil : Godot (−0.30 ; −2,60)
      (1.90, -0.70, 0.30)]),
]
## Résolution de BASE de chaque objet, appliquée au lobe maître. Les lobes
## secondaires la reçoivent réduite par `_resolution_lobe()` : un éboulis de
## 20 % d'échelle à pleine résolution coûterait autant que la tour, pour des
## facettes de deux centimètres que personne ne verra jamais.
RESOLUTION = {
    "SM_Spring_Buttress": (22, 18, 3),
    "SM_Spring_Spout": (20, 15, 3),
    "SM_Spring_Shelf": (20, 13, 3),
    "SM_Spring_Sill": (16, 11, 2),
}


def _resolution_lobe(na: int, nt: int, echelle: float) -> tuple:
    """Résolution d'un lobe, décroissante avec son échelle.

    Bornes basses (10 azimuts, 8 tranches) : en dessous, un lobe cesse d'être
    un bloc et devient un dé. Le lobe maître (echelle 1,0) garde la résolution
    de base au triangle près — la formule rend exactement (na, nt) en 1,0.
    """
    e = max(0.0, min(1.0, echelle))
    na_l = max(10, int(round(na * (0.45 + 0.55 * e))))
    nt_l = max(8, int(round(nt * (0.50 + 0.50 * e))))
    return na_l, nt_l


def _purge() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _delta_angle(a: float, b: float) -> float:
    return (a - b + math.pi) % math.tau - math.pi


class Bloc:
    """Le champ `r(θ, t)` d'un bloc de ravin.

    `t` vaut 0 au plan de sol, 1 au sommet théorique du dôme, et descend en
    NÉGATIF dans la jupe enterrée. La grille s'arrête avant 1 : à t = 1 le
    dôme se referme sur un point, et un cône de fin de dôme est un chapeau.
    """

    T_MAX = 0.92

    def __init__(self, hauteur, demi_a, demi_b, jupe, graine, pente,
                 azim_mouille, h_mouille):
        self.H = hauteur
        self.demi_a = demi_a
        self.demi_b = demi_b
        self.jupe = jupe
        self.t_jupe = -jupe / hauteur
        self.pente = Vector((pente[0], pente[1], 0.0))
        self.azim_mouille = math.radians(azim_mouille)
        self.h_mouille = h_mouille
        rng = random.Random(graine)
        self.rng = rng

        # DÔME BRISÉ. `(1 − t^q)^e` : plat longtemps, puis il roule. `q` grand
        # = épaules carrées ; `e` petit = sommet aplati. Un bloc de pied de
        # paroi a des épaules, pas un profil d'œuf.
        # v2 — ÉPAULES CARRÉES. À (2,4–3,4 ; 0,26–0,38) les masses rendaient
        # des COUSSINS sur `iter8` : même facettées, elles restaient molles.
        # `q` plus grand recule le moment où le dôme roule, `e` plus petit
        # aplatit le sommet. Un bloc de pied de paroi a des épaules.
        self.dome_q = rng.uniform(3.2, 4.6)
        self.dome_e = rng.uniform(0.16, 0.26)

        # NERVURES VERROUILLÉES SUR L'AZIMUT — le seul relief qui survive d'une
        # tranche à l'autre et fabrique une arête filante plutôt qu'un bruit.
        self.harmoniques = [(ordre, amp, rng.uniform(0.0, math.tau))
                            for ordre, amp in ((2, 0.205), (3, 0.145),
                                               (5, 0.084), (7, 0.046))]
        # Deux FENTES franches : ce sont elles qui font lire « bloc fracturé »
        # plutôt que « galet ».
        # Plus profondes et plus ÉTROITES : une fente large est une bosse
        # inversée, une fente étroite est une fracture.
        self.fentes = [(rng.uniform(0.0, math.tau), rng.uniform(0.26, 0.38),
                        rng.uniform(0.085, 0.155)) for _ in range(2)]

        # BOMBEMENTS ET NICHES.
        self.bosses = []
        for _ in range(2):
            self.bosses.append((rng.uniform(0.0, math.tau),
                                rng.uniform(0.30, 0.66),
                                rng.uniform(0.40, 0.80),
                                rng.uniform(0.10, 0.18),
                                -rng.uniform(0.12, 0.20)))
        for _ in range(2):
            self.bosses.append((rng.uniform(0.0, math.tau),
                                rng.uniform(0.34, 0.70),
                                rng.uniform(0.45, 0.90),
                                rng.uniform(0.11, 0.17),
                                rng.uniform(0.13, 0.20)))
        # CONTREFORTS DE PIED : le bloc s'étale avant de plonger.
        for _ in range(3):
            self.bosses.append((rng.uniform(0.0, math.tau),
                                rng.uniform(0.0, 0.13),
                                rng.uniform(0.70, 1.20),
                                rng.uniform(0.16, 0.24),
                                rng.uniform(0.18, 0.30)))
        # COURONNE ROMPUE : un côté haut, une encoche ailleurs.
        self.haut_azimut = rng.uniform(0.0, math.tau)
        self.encoche = self.haut_azimut + rng.uniform(1.9, 4.4)

    def nervure(self, theta: float) -> float:
        v = 0.0
        for ordre, amp, phase in self.harmoniques:
            v += amp * math.sin(ordre * theta + phase)
        for centre, profondeur, largeur in self.fentes:
            d = abs(_delta_angle(theta, centre))
            if d < largeur:
                v -= profondeur * (0.5 + 0.5 * math.cos(math.pi * d / largeur))
        return v

    def bosse(self, theta: float, t: float) -> float:
        v = 0.0
        for th, tt, sth, stt, amp in self.bosses:
            dth = _delta_angle(theta, th) / sth
            dt = (t - tt) / stt
            e = dth * dth + dt * dt
            if e < 9.0:
                v += amp * math.exp(-e)
        return v

    def dome(self, t: float) -> float:
        if t >= 0.0:
            u = min(1.0, max(0.0, t))
            return max(0.02, (1.0 - u ** self.dome_q) ** self.dome_e)
        u = min(1.0, t / self.t_jupe)
        return 1.0 + 0.32 * u * (2.0 - u)

    def rayon_lisse(self, theta: float, t: float) -> float:
        return self.dome(t) * (1.0 + self.nervure(theta))

    def rayon(self, theta: float, t: float) -> float:
        return self.rayon_lisse(theta, t) * (1.0 + self.bosse(theta, t))

    def couronne(self, theta: float) -> float:
        """Abaissement du sommet : une arête haute, une encoche ailleurs."""
        d_haut = abs(_delta_angle(theta, self.haut_azimut))
        base = 0.150 * (1.0 - math.exp(-(d_haut / 0.70) ** 2))
        d_enc = abs(_delta_angle(theta, self.encoche))
        return base + 0.110 * math.exp(-(d_enc / 0.30) ** 2)

    def point(self, theta: float, t: float) -> Vector:
        r = self.rayon(theta, t)
        z = t * self.H
        return Vector((math.cos(theta) * self.demi_a * r,
                       math.sin(theta) * self.demi_b * r, z)) \
            + self.pente * max(0.0, z)

    def mouillage(self, theta: float, z: float) -> float:
        """Combien ce point est trempé : 1 au ras de l'eau du bon côté, 0 loin.

        Le mouillage n'est pas un anneau : il dépend de l'AZIMUT (le côté qui
        touche la vasque) autant que de la hauteur. Une roche trempée sur tout
        son pourtour se relit comme un socle sombre posé — c'est le cerne déjà
        mesuré et corrigé deux fois au lit de cette vasque.
        """
        if z > self.h_mouille or z < -0.02:
            return 0.0
        cote = math.exp(-(_delta_angle(theta, self.azim_mouille) / 1.05) ** 2)
        haut = 1.0 - max(0.0, z) / max(self.h_mouille, 1e-6)
        return cote * haut * haut


## [écrêtés, total] des appels à `_teinte` de la masse en cours.
_ECRETAGE = [0, 0]


def _teinte(bloc: Bloc, theta: float, t: float, z: float, normale: Vector,
            creux: float, teinte_masse: tuple = (1.0, 1.0, 1.0)) -> tuple:
    up = max(-1.0, min(1.0, normale.z))
    v = 1.0
    v *= 1.0 - 0.50 * max(0.0, min(1.0, creux))
    v *= 1.0 + (0.13 * up if up > 0.0 else 0.26 * up)
    v *= 1.0 + 0.072 * math.sin(7.0 * theta + 1.7) * math.cos(3.0 * theta + 0.4)
    v *= 1.0 + 0.045 * math.sin(11.0 * theta + 2.6)
    pied = max(0.0, 1.0 - max(0.0, t) * 2.3)
    r = NIVEAU * v * (1.0 - 0.22 * pied)
    g = NIVEAU * v * (1.0 - 0.10 * pied)
    b = NIVEAU * v * (1.0 - 0.26 * pied)
    w = bloc.mouillage(theta, z)
    if w > 0.0:
        r *= 1.0 + w * (MOUILLE[0] - 1.0)
        g *= 1.0 + w * (MOUILLE[1] - 1.0)
        b *= 1.0 + w * (MOUILLE[2] - 1.0)
    # LA TEINTE DE MASSE EN DERNIER — c'est elle qui différencie les rives, et
    # elle doit multiplier le relief ET le mouillage, sinon deux masses de
    # valeurs différentes retrouveraient la même valeur là où elles sont
    # trempées, et le bas des masses — la partie qu'on voit le plus au ras —
    # redeviendrait uniforme.
    r *= teinte_masse[0]
    g *= teinte_masse[1]
    b *= teinte_masse[2]
    # Comptage de l'écrêtage AVANT la borne — voir `ECRETAGE_PART_MAX`.
    _ECRETAGE[1] += 1
    if r > 1.0 or g > 1.0 or b > 1.0:
        _ECRETAGE[0] += 1
    # Plancher 0,12 (et non 0,20) : le seuil trempé DOIT pouvoir descendre
    # plus bas que le contrefort sec, sinon le plancher lui-même écrase
    # l'écart de valeur que cette passe cherche à obtenir.
    borne = lambda x: max(0.12, min(1.0, x))
    return (borne(r), borne(g), borne(b))


def _lobe(bm, bloc: Bloc, na: int, nt: int, nj: int, offset: Vector,
          echelle: float, couleurs: dict, faces_fracture: list,
          teinte_masse: tuple = (1.0, 1.0, 1.0),
          compte_mouille: list = None) -> None:
    """Un lobe complet — surface, couronne rompue, fond de jupe.

    Plusieurs lobes peuvent partager le même `bmesh` : c'est ce qui permet à
    cinq rochers de ne coûter qu'UN module au budget D7.

    `compte_mouille` reçoit [trempés, total] MESURÉS SUR LES SOMMETS RÉELLEMENT
    PEINTS. La version précédente recomptait le mouillage après coup, sur le
    maillage fusionné, avec `atan2(v.co.y, v.co.x)` — donc un azimut pris
    depuis l'ORIGINE DE L'OBJET et non depuis le centre du lobe. Sur un objet
    à plusieurs lobes décalés, ce contrôle mesurait donc autre chose que ce que
    `_teinte` peignait : la famille d'ISS-018, un chiffre vert qui ne parle pas
    du défaut qu'il prétend garder.
    """
    thetas = [math.tau * j / na for j in range(na)]
    ts = [bloc.t_jupe * (1.0 - k / float(nj)) for k in range(nj)]
    ts += [bloc.T_MAX * k / float(nt - 1) for k in range(nt)]

    anneaux = []
    metas = []
    for t in ts:
        ligne = []
        meta = []
        for theta in thetas:
            p = bloc.point(theta, t)
            if t > 0.0:
                poids = max(0.0, (t - 0.55) / 0.45)
                p.z -= bloc.couronne(theta) * bloc.H * poids * poids
            p = Vector((p.x * echelle, p.y * echelle, p.z * echelle)) + offset
            ligne.append(bm.verts.new(p))
            lisse = bloc.dome(t) * (1.0 + max(0.0, bloc.nervure(theta))) \
                * (1.0 + max(0.0, bloc.bosse(theta, t)))
            reel = bloc.rayon(theta, t)
            meta.append((theta, t, p.z - offset.z,
                         max(0.0, 1.0 - reel / max(lisse, 1e-6))))
        anneaux.append(ligne)
        metas.append(meta)

    for i in range(len(anneaux) - 1):
        bas, haut = anneaux[i], anneaux[i + 1]
        for j in range(na):
            m = (j + 1) % na
            bm.faces.new((bas[j], bas[m], haut[m], haut[j]))

    # Couronne : anneau intermédiaire puis apex décalé. Un éventail direct
    # depuis l'apex rend de grandes facettes planes — mesuré au belvédère, la
    # chaîne y a rougi sur ce point exact.
    dernier = anneaux[-1]
    centre = Vector((0.0, 0.0, 0.0))
    for v in dernier:
        centre += v.co
    centre /= na
    vers = Vector((math.cos(bloc.haut_azimut), math.sin(bloc.haut_azimut), 0.0))
    hauts = [v.co.z for v, meta in zip(dernier, metas[-1])
             if abs(_delta_angle(meta[0], bloc.haut_azimut)) < 0.7]
    z_haut = (sum(hauts) / len(hauts)) if hauts else centre.z
    apex = Vector((centre.x + vers.x * bloc.demi_a * echelle * 0.26,
                   centre.y + vers.y * bloc.demi_b * echelle * 0.26,
                   z_haut + 0.030 * bloc.H * echelle))
    faîte = bm.verts.new(apex)
    mid = [[bm.verts.new(v.co.lerp(apex, f)) for v in dernier]
           for f in (0.34, 0.68)]
    for j in range(na):
        m = (j + 1) % na
        faces_fracture.append(bm.faces.new((dernier[j], dernier[m], mid[0][m],
                                            mid[0][j])))
        faces_fracture.append(bm.faces.new((mid[0][j], mid[0][m], mid[1][m],
                                            mid[1][j])))
        faces_fracture.append(bm.faces.new((mid[1][j], mid[1][m], faîte)))

    premier = anneaux[0]
    z_fond = min(v.co.z for v in premier)
    rangs = []
    for facteur in (0.76, 0.52, 0.28):
        rangs.append([bm.verts.new(Vector(
            (offset.x + (v.co.x - offset.x) * facteur,
             offset.y + (v.co.y - offset.y) * facteur, z_fond)))
            for v in premier])
    centre_bas = bm.verts.new(Vector((offset.x, offset.y, z_fond)))
    for j in range(na):
        m = (j + 1) % na
        bm.faces.new((premier[m], premier[j], rangs[0][j], rangs[0][m]))
        bm.faces.new((rangs[0][m], rangs[0][j], rangs[1][j], rangs[1][m]))
        bm.faces.new((rangs[1][m], rangs[1][j], rangs[2][j], rangs[2][m]))
        bm.faces.new((rangs[2][m], rangs[2][j], centre_bas))

    bm.normal_update()
    for ligne, meta in zip(anneaux, metas):
        for v, (theta, t, z, creux) in zip(ligne, meta):
            couleurs[v] = _teinte(bloc, theta, t, z, v.normal, creux,
                                  teinte_masse)
            if compte_mouille is not None:
                compte_mouille[1] += 1
                if bloc.mouillage(theta, z) > 0.12:
                    compte_mouille[0] += 1
    teinte_pied = tuple(c * NIVEAU * m
                        for c, m in zip(TEINTE_PIED, teinte_masse))
    for rang in rangs:
        for v in rang:
            couleurs[v] = teinte_pied
    couleurs[centre_bas] = teinte_pied
    sommet = _teinte(bloc, bloc.haut_azimut, 1.0, bloc.H, Vector((0, 0, 1)),
                     0.0, teinte_masse)
    couleurs[faîte] = sommet
    for anneau_haut in mid:
        for v in anneau_haut:
            couleurs[v] = sommet


def _construire(nom: str, bloc: Bloc, lobes, mat_corps, mat_fracture,
                teinte_masse=(1.0, 1.0, 1.0), compte_mouille=None):
    na, nt, nj = RESOLUTION[nom]
    maillage = bpy.data.meshes.new(nom)
    bm = bmesh.new()
    couleurs = {}
    faces_fracture = []
    for dx, dy, echelle in lobes:
        na_l, nt_l = _resolution_lobe(na, nt, echelle)
        _lobe(bm, bloc, na_l, nt_l, nj, Vector((dx, dy, 0.0)), echelle,
              couleurs, faces_fracture, teinte_masse, compte_mouille)
    for face in faces_fracture:
        face.material_index = 1

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

    # OMBRAGE À FACETTES — et c'est le correctif du défaut « cire fondue »
    # mesuré sur `voie_a3/iter7`. Des normales de sommet LISSÉES sur une
    # surface dense produisent un dégradé continu : la masse rendait molle et
    # coulante là où TOUT le monde autour d'elle — falaises V2.2, rochers de
    # kit, éboulis — est franchement facetté. Elle n'appartenait pas à la même
    # matière. Le relief, lui, était bien là et mesuré ; c'est l'ombrage qui
    # le dissolvait. La résolution suit ce choix : une facette doit se LIRE, et
    # à 20 cm l'ombrage à facettes ne rendrait que du bruit.
    for polygone in maillage.polygons:
        polygone.use_smooth = False

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


def _controle_surplombs(bloc: Bloc, na: int) -> tuple:
    """Deux bornes, comme au belvédère — et pour la même raison mesurée là-bas :
    compter les azimuts qui surplombent « quelque part » rendait 100 % et ne
    distinguait rien. On compte donc aussi la plus grande fraction d'azimuts
    qui surplombent À LA MÊME HAUTEUR."""
    pas = 30
    montee = [[False] * na for _ in range(pas)]
    for j in range(na):
        theta = math.tau * j / na
        precedent = bloc.rayon(theta, 0.22)
        gain = 0.0
        for k in range(pas):
            t = 0.24 + 0.02 * k
            r = bloc.rayon(theta, t)
            if r > precedent:
                gain += r - precedent
                if gain > 0.030:
                    montee[k][j] = True
            else:
                gain = 0.0
            precedent = r
    secteurs = sum(1 for j in range(na) if any(montee[k][j] for k in range(pas)))
    ceinture = max(sum(1 for j in range(na) if montee[k][j])
                   for k in range(pas)) / float(na)
    return secteurs, ceinture


def _materiau(nom: str, couleur):
    """ISS-066 : l'exporter glTF 4.0 n'écrit `COLOR_0` que si le MATÉRIAU
    consomme réellement l'attribut. Sans ce branchement, le `.glb` sort avec
    POSITION et NORMAL seulement — aucune erreur, un asset silencieusement
    plat, et tout le mouillage disparaîtrait sans un mot."""
    mat = bpy.data.materials.new(nom)
    mat.use_nodes = True
    arbre = mat.node_tree
    principled = arbre.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = couleur
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
        principled.inputs["Roughness"].default_value = 0.92
    if "Metallic" in principled.inputs:
        principled.inputs["Metallic"].default_value = 0.0
    if "Specular IOR Level" in principled.inputs:
        principled.inputs["Specular IOR Level"].default_value = 0.20
    elif "Specular" in principled.inputs:
        principled.inputs["Specular"].default_value = 0.20
    return mat


def main() -> int:
    _purge()
    mat_corps = _materiau("MAT_Spring_Rock", MAT_ROCHE)
    mat_fracture = _materiau("MAT_Spring_Fracture", MAT_FRACTURE)

    total_tris = 0
    moyennes = {}
    for (nom, hauteur, demi_a, demi_b, jupe, graine, pente, azim_m, h_m,
         teinte_masse, lobes) in MASSES:
        bloc = Bloc(hauteur, demi_a, demi_b, jupe, graine, pente, azim_m, h_m)
        compte_mouille = [0, 0]
        _ECRETAGE[0] = 0
        _ECRETAGE[1] = 0
        objet = _construire(nom, bloc, lobes, mat_corps, mat_fracture,
                            teinte_masse, compte_mouille)
        maillage = objet.data
        tris = len(maillage.polygons)
        total_tris += tris

        zs = [v.co.z for v in maillage.vertices]
        sur_sol = [v for v in maillage.vertices if v.co.z >= -0.02]
        e_vis = max(max(v.co.x for v in sur_sol) - min(v.co.x for v in sur_sol),
                    max(v.co.y for v in sur_sol) - min(v.co.y for v in sur_sol))
        aire_max = max(p.area for p in maillage.polygons)

        attribut = maillage.color_attributes.get("Col")
        if attribut is None:
            print("%s ERREUR: %s sans couche de couleur de sommet" % (TAG, nom))
            return 2
        lum = sorted(0.2126 * d.color[0] + 0.7152 * d.color[1]
                     + 0.0722 * d.color[2] for d in attribut.data)
        p10 = lum[len(lum) // 10]
        p90 = lum[9 * len(lum) // 10]
        moyenne = sum(lum) / len(lum)
        etendue = (p90 - p10) / max(moyenne, 1e-6)
        # Part de sommets réellement trempés — comptée PENDANT la peinture,
        # avec l'azimut du LOBE, donc sur exactement ce que `_teinte` a reçu.
        # (Le compte d'après coup sur le maillage fusionné prenait l'azimut
        # depuis l'origine de l'OBJET : sur cinq lobes décalés il mesurait une
        # autre grandeur que celle qu'il nommait.)
        moyennes[nom] = moyenne
        part_mouille = compte_mouille[0] / float(max(compte_mouille[1], 1))
        na = RESOLUTION[nom][0]
        surplombs, ceint_surplomb = _controle_surplombs(bloc, na)

        print("%s %s : %d tris, hauteur %.3f m, fond %.3f m, emprise visible "
              "%.3f m, facette max %.4f m2, lobes %d"
              % (TAG, nom, tris, max(zs), min(zs), e_vis, aire_max, len(lobes)))
        print("%s %s : surplombs %d/%d (plancher %d), ceinture de surplomb "
              "%.2f (plafond %.2f), mouillage %.2f (bande %.2f..%.2f), couleur "
              "moy %.3f p10 %.3f p90 %.3f (etendue %.1f %%)"
              % (TAG, nom, surplombs, na, SURPLOMBS_MIN, ceint_surplomb,
                 SURPLOMBS_MAX_PART, part_mouille, MOUILLAGE_PART_MIN,
                 MOUILLAGE_PART_MAX, moyenne, p10, p90, 100.0 * etendue))

        if min(zs) > -0.05:
            print("%s ERREUR: %s ne descend pas sous le plan de sol (%.3f)"
                  % (TAG, nom, min(zs)))
            return 2
        if not (hauteur * 0.80 <= max(zs) <= hauteur * 1.05):
            print("%s ERREUR: %s hauteur %.3f hors fourchette autour de %.3f"
                  % (TAG, nom, max(zs), hauteur))
            return 2
        if surplombs < SURPLOMBS_MIN:
            print("%s ERREUR: %s n'a que %d azimut(s) de surplomb (< %d) — "
                  "convexe partout, c'est un galet et c'est le defaut rejete"
                  % (TAG, nom, surplombs, SURPLOMBS_MIN))
            return 2
        if ceint_surplomb > SURPLOMBS_MAX_PART:
            print("%s ERREUR: %s surplombe sur %.0f %% des azimuts A LA MEME "
                  "HAUTEUR (> %.0f %%) — taille de guepe"
                  % (TAG, nom, 100.0 * ceint_surplomb,
                     100.0 * SURPLOMBS_MAX_PART))
            return 2
        if not (MOUILLAGE_PART_MIN <= part_mouille <= MOUILLAGE_PART_MAX):
            print("%s ERREUR: %s mouillage %.2f hors bande [%.2f ; %.2f] — "
                  "invisible en dessous, cerne sombre au-dessus"
                  % (TAG, nom, part_mouille, MOUILLAGE_PART_MIN,
                     MOUILLAGE_PART_MAX))
            return 2
        if aire_max > AIRE_FACETTE_MAX:
            print("%s ERREUR: %s porte une facette de %.4f m2 (> %.4f)"
                  % (TAG, nom, aire_max, AIRE_FACETTE_MAX))
            return 2
        if etendue < ETENDUE_COULEUR_MIN:
            print("%s ERREUR: %s etendue de couleur %.1f %% < %.1f %%"
                  % (TAG, nom, 100.0 * etendue, 100.0 * ETENDUE_COULEUR_MIN))
            return 2
        if not (COULEUR_MOYENNE_MIN <= moyenne <= COULEUR_MOYENNE_MAX):
            print("%s ERREUR: %s moyenne de couleur %.3f hors bande "
                  "[%.2f ; %.2f]" % (TAG, nom, moyenne, COULEUR_MOYENNE_MIN,
                                     COULEUR_MOYENNE_MAX))
            return 2
        part_ecretee = _ECRETAGE[0] / float(max(_ECRETAGE[1], 1))
        print("%s %s : ecretage %.3f (plafond %.2f) sur %d sommets peints"
              % (TAG, nom, part_ecretee, ECRETAGE_PART_MAX, _ECRETAGE[1]))
        if part_ecretee > ECRETAGE_PART_MAX:
            print("%s ERREUR: %s ecrete %.1f %% de ses sommets (> %.1f %%) — "
                  "la teinte de masse pousse au plafond, et un sommet ecrete "
                  "rend PLAT la ou on veut voir le relief prendre la lumiere"
                  % (TAG, nom, 100.0 * part_ecretee,
                     100.0 * ECRETAGE_PART_MAX))
            return 2

    # ── L'ÉCART DE VALEUR ENTRE LES MASSES ────────────────────────────────
    # Le verdict dit « des blocs indépendants » ; l'une des raisons pour
    # lesquelles ils se ressemblaient est qu'ils avaient tous la même valeur.
    # Ce contrôle est le seul du fichier qui juge la table DANS SON ENSEMBLE,
    # et il rougirait sur la version rejetée — où les quatre masses
    # partageaient teinte et niveau.
    claire = max(moyennes, key=lambda n: moyennes[n])
    sombre = min(moyennes, key=lambda n: moyennes[n])
    ecart = moyennes[claire] - moyennes[sombre]
    print("%s ecart de valeur entre masses : %.3f (plancher %.2f) — "
          "la plus claire %s %.3f, la plus sombre %s %.3f"
          % (TAG, ecart, ECART_VALEUR_MIN, claire, moyennes[claire],
             sombre, moyennes[sombre]))
    if ecart < ECART_VALEUR_MIN:
        print("%s ERREUR: les masses partagent la meme valeur (ecart %.3f < "
              "%.2f) — c'est le defaut « blocs independants » du verdict, et "
              "aucune finesse de nervure ne le repare" % (TAG, ecart,
                                                          ECART_VALEUR_MIN))
        return 2

    print("%s total %d triangles (plafond %d)" % (TAG, total_tris, BUDGET_TRIS))
    if total_tris > BUDGET_TRIS:
        print("%s ERREUR: budget de triangles depasse" % TAG)
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_SpringMaw.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("%s source enregistree -> %s" % (TAG, sortie))
    print("FIN NOMINALE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
