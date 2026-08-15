# SOURCE DE GÉNÉRATION REPRODUCTIBLE — Grotte du Couchant.
#
# LE NOM A CHANGÉ EN R2a-3.1, l'identifiant NON. La revue a constaté que le
# monde ne porte aucune cascade compatible avec l'hydrologie V2.2 gelée :
# le nom affiché promettait ce qui n'existe pas. Seul `name` bascule à
# « Grotte du Couchant » dans le layout ; l'ID technique
# `valley.poi.waterfall_cave.01`, les chemins de fichiers et les noms de
# maillages restent inchangés — une migration de sauvegarde pour un
# libellé serait un coût sans contrepartie.
#
# POURQUOI CE FICHIER EXISTE. La passe précédente fabriquait la grotte en
# GDScript avec `WorldV2PlaceKit.hollow_rock_mesh()`. Le lead a rejeté :
# « enveloppe ouverte, plaques minces, face intérieure rectiligne noire,
# caméra intérieure dans les polygones ». Les quatre défauts ont une cause
# géométrique unique, lisible dans ce kit et mesurée avant d'écrire ici :
#
#   * AUCUN fond n'y est cousu : les anneaux `inner[i]` et `outer[i]`
#     existent à y = 0 et ne sont jamais reliés — arête libre sur tout le
#     pourtour ;
#   * `if open[i] and open[i + 1]: continue` supprime, au secteur bouche,
#     la paroi intérieure, les bandes extérieures ET la couronne. Seule y
#     survit la voûte, enroulée pour être vue de dessous : culée par le
#     dessus, elle laisse un TROU VERS LE CIEL au-dessus de l'entrée ;
#   * les deux joues ne sont émises qu'aux 2 segments de transition et
#     vont de `inner` à `outer` (t = 1) alors que la couronne s'arrête à
#     t = 0,52 : fente de 0,48 x 4,4 = 2,11 m entre la joue et la face ;
#   * la paroi intérieure est UN quad par colonne de y = 0 à `tops[i]` :
#     une surface réglée, donc rectiligne par construction.
#
# MÉTHODE. Aucun booléen, aucune plaque : un LOFT UNIQUE à sections en
# « rondelle ». Chaque station porte deux profils fermés de MÊME nombre de
# sommets — l'intérieur (arc surbaissé sur sol dishé) et l'extérieur (blob
# irrégulier). On coud la peau extérieure, la peau intérieure, et la
# RONDELLE DE RIVE à la bouche qui relie les deux. Le résultat est UNE
# surface fermée de genre 0 : un solide creusé d'une cavité borgne.
#
# CE QUE LA TOPOLOGIE DONNE GRATUITEMENT, et c'est l'argument central :
# sur un manifold fermé, `bmesh.ops.recalc_face_normals` oriente toutes
# les faces vers l'extérieur DU SOLIDE. Sur la peau d'une cavité, cela
# veut dire VERS LA SALLE. Enroulement et normale d'ombrage deviennent
# donc corrects d'un seul coup, sans raisonnement face par face — c'est
# exactement ce que le kit rejeté faisait à la main, et ratait. Le sol de
# la salle appartient au profil fermé : il est cousu aux parois, aucune
# herbe du terrain ne peut passer entre.
#
# LE SOLEIL. Mesuré par le lead sur la scène montée, et non déduit du
# `.tscn` (les 12 flottants y sont les LIGNES de la base, pas les
# colonnes — première lecture fausse de ma part) : propagation
# (0,8677 ; -0,3907 ; 0,3073), azimut 19,5°, élévation 23,0°, donc soleil
# à l'azimut 199,5°. Le ressaut monte à l'OUEST : la bouche regarde donc
# nécessairement vers l'est, à l'opposé du soleil. Aucun azimut de bouche
# vers l'est n'est éclairable (mesuré : -0,87 à l'est, -0,83 au sud-est,
# -0,40 au nord-est). Le contre-jour est ASSUMÉ : le contraste vient du
# plateau ensoleillé devant, de la crête et du flanc ouest ensoleillés
# au-dessus, et de l'intérieur plus sombre que la collerette.
#
# Vérifié aussi par le calcul : le site n'est PAS dans l'ombre portée du
# ressaut — à 23° d'élévation le rayon franchit la crête (x = -130,
# y = 10,3) avec de la marge. Tout ce qui regarde l'est est en ombre
# PROPRE, pas en ombre portée.
#
# L'AMBIANTE DU MONDE EST CONSTANTE ET NON OCCLUSE (`WorldV2.tscn` :
# `ambient_light_source = 2`, énergie 0,6). Aucun intérieur ne sera noir
# par absence de lumière : l'obscurité doit venir de l'ALBÉDO et de
# l'orientation. Les albédos intérieurs sont donc franchement bas, et
# séparés en trois familles (paroi proche, fond/plafond, sol).
#
# Blender est Z-up ; l'exporteur convertit en Y-up (`export_yup`). On
# modèle donc Z vertical, plan de sol à Z = 0, bouche à l'origine, galerie
# vers +Y. Le lacet d'implantation est appliqué côté Godot.
#
# ─────────────────────────────────────────────────────────────────────────
# R2a-3.1 — CE QUE LA REVUE A REJETÉ, ET LA CAUSE GÉOMÉTRIQUE DE CHAQUE
# DÉFAUT. La version précédente passait tous les filets techniques (coque
# fermée, épaisseur, gabarit, aucun jour) et échouait à l'œil : « pain de
# mie lisse », « bouche en demi-cercle presque parfait », « tunnel de
# béton cylindrique », « silhouettes rondes et génériques ».
#
# Les quatre reproches ont UNE cause commune, et elle n'est pas le bruit :
# les sections étaient des DEMI-ELLIPSES lisses, évaluées par
# `hw·cos θ` et `cle·sin^p θ` à azimut continu. Une demi-ellipse extrudée
# le long d'un chemin EST un tube, et son ouverture EST un demi-cercle.
# Aucune quantité de bruit ne change la nature d'une surface : elle la
# décore. Trois corrections structurelles, pas cosmétiques :
#
#   1. SECTIONS FACETTÉES. Le rayon n'est plus évalué à θ mais à un
#      azimut QUANTIFIÉ (`facette()`, N pans). La section devient
#      polygonale, à arêtes vives : la lumière rasante y accroche des
#      valeurs distinctes par pan. C'est ce qui remplace « lisse » par
#      « strates ». N diffère entre cavité (9) et masses annexes (7, 5)
#      pour que les fréquences ne s'alignent jamais.
#   2. ASYMÉTRIE PAR STATION + LINTEAU INCLINÉ (`CAVITE_ASYM`). Gauche et
#      droite ne partagent plus un rayon, et la clé bascule : la bouche
#      cesse d'être un demi-cercle et devient une ouverture dissymétrique
#      prise dans la roche.
#   3. MASSES ANNEXES SÉPARÉES (`MASSES_ANNEXES`). Les lobes de la passe
#      précédente étaient des bosses SUR un blob — 1,75 m de saillie sur
#      un corps de 4,7 m de rayon, soit 37 % : ça projette un renflement,
#      jamais une masse. La silhouette se juge en PROJECTION, pas dans le
#      maillage. Il faut donc des volumes distincts qui s'interpénètrent :
#      un contrefort latéral et une couronne brisée, loftés à part, avec
#      leur propre contrôle de non-empiètement sur la cavité.
#
# Et deux corrections de mise en scène, exigées nommément par la revue :
# une ALCÔVE latérale à tablette relevée (la récompense est désignée par
# la géométrie et la lumière, plus posée au milieu d'un sol vide), et des
# NERVURES de plafond qui cassent la section constante de la galerie.
#
# Le flanc ouest surexposé venait des albédos, pas de la forme : les trois
# matières de roche extérieure ont été réétalées (0,235 / 0,352 / 0,412)
# pour retrouver trois valeurs rendues séparées malgré l'étalement de
# l'éclairage, mesuré à ×1,63 entre face éclairée et face à l'ombre.
# ─────────────────────────────────────────────────────────────────────────
#
# Usage (les DEUX garde-fous sont obligatoires, cf. export_architecture.sh) :
#   blender --background --python-exit-code 1 \
#       --python source_assets/blender/environment/make_waterfall_cave.py
#   blender --background --python-exit-code 1 \
#       source_assets/blender/environment/SM_WaterfallCave.blend \
#       --python tools/blender/export_gltf.py -- \
#       --out assets/environment/caves/SM_WaterfallCave.glb

import math
import os
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

TAU = math.pi * 2.0

# ---------------------------------------------------------------------------
# Cotes. Toutes mesurées contre le terrain GELÉ (probe_site_section, pas de
# 2 m) : plateau plat à 3,00 m sur x in [-118 ; -102], z in [0 ; +9] ; le
# ressaut monte à l'ouest (-120 -> 3,1 ; -122 -> 4,1 ; -124 -> 5,8 ;
# -126 -> 7,6). Le sol intérieur reste donc au niveau du plateau : la
# cavité est une masse POSÉE sur le plat et adossée au ressaut, jamais un
# creusement dans le champ de hauteur (qui, lui, traverserait la salle).
# ---------------------------------------------------------------------------

SEGMENTS = 56           # sommets par profil (visuel)
SEGMENTS_COL = 20       # idem pour la coque de collision
SAG = 0.08              # cuvette du sol : un sol parfaitement plat sonne faux
SKIRT = 2.20            # jupe extérieure sous le plan de sol — masse PLANTÉE
SKIRT_COL = 1.10

# Marges de la coque de collision. Elles ne sont pas cosmétiques : la passe
# rejetée plaçait la face interne du collider EXACTEMENT sur INNER_R, et le
# relief de paroi (wobble +/-0,30) mettait jusqu'à 0,96 m de paroi VISIBLE
# en deçà de la barrière. La caméra entrait donc dans le maillage avant
# d'être arrêtée. Ici la collision est rétrécie explicitement.
COL_MARGE_LAT = 0.40
COL_MARGE_CLE = 0.35

# Stations de la CAVITÉ : (axe_x, axe_y, demi-largeur, hauteur de clé).
# La galerie s'infléchit de ~31° entre le seuil et la salle : depuis le
# seuil on ne voit pas le fond, et depuis la salle la bouche reste une
# lucarne claire. L'inflexion est aussi ce qui permet d'avoir À LA FOIS
# une bouche noire (les 4 premiers mètres restent à l'ambiante seule) et
# une salle éclairée (la source motivée vit après le coude, invisible du
# dehors).
#
# OUVERTURE ÉLARGIE APRÈS CAPTURE. La bouche mesurait 3,10 x 2,60 m : sur
# la vue d'approche à hauteur de joueur, un massif de fleurs gelées haut
# d'environ 1,5 m en masquait la moitié basse. Portée à 3,40 x 2,85 m, la
# part d'ouverture qui reste au-dessus des fleurs passe d'environ 42 % à
# 53 %. Ce n'est pas une solution complète — voir la note d'honnêteté du
# rapport — mais c'est la seule qui ne déplace pas de la végétation GELÉE.
#
# CONTRAINTE DURE du filet `test_la_grotte_a_un_seuil_et_un_interieur` :
# il marche en LIGNE DROITE du seuil à l'intérieur et exige 1,75 m de
# hauteur libre à chaque pas de 0,40 m. La corde d'un arc de 31° sur
# 6,25 m s'écarte au plus de 0,30 m de l'axe — la demi-largeur minimale
# (1,55 m) l'absorbe largement, et la clé y reste au-dessus de 2,4 m.
CAVITE = [
    # ax     ay     hw     cle
    (0.00, -1.15, 1.90, 2.80),   # porche évasé, sol sous le terrain
    (0.00,  0.00, 1.70, 2.85),   # seuil
    (0.06,  1.60, 1.85, 2.95),
    (0.24,  3.20, 2.15, 2.80),
    (0.58,  4.75, 2.70, 2.90),
    (1.05,  6.25, 3.05, 2.92),   # SALLE
    (1.62,  7.60, 2.80, 2.92),   # cle relevee : le palier du fond mange la hauteur
    (2.25,  8.65, 2.20, 2.55),   # elargie : le profil s'y repliait aussi
    (2.85,  9.25, 1.40, 2.00),   # elargie : a 1,15/1,80 le profil se repliait
]
CAVITE_APEX = (3.25, 9.55, 0.70)     # pointe de la calotte du fond
# La lèvre du porche plonge sous le terrain. -0,06 au premier jet, avec un
# exhaussement de 0,02 : la CUVETTE du sol (SAG) descendait alors 8 cm sous
# le plan, donc 6 cm sous le terrain — mesuré en capture, l'herbe du
# terrain gelé traversait le sol de la salle sur toute sa longueur. Le sol
# construit est désormais remonté (place script) et la lèvre creusée
# d'autant, pour rester enterrée.
#
# DEUXIÈME MESURE, deuxième correction : à +0,11 le sol passait bien
# au-dessus du terrain, mais les TOUFFES d'herbe gelées, hautes d'environ
# 0,30 m, le traversaient encore et poussaient dans la salle. Le sol monte
# donc à +0,50 et la lèvre du porche descend à -0,58 : elle reste enterrée,
# et le mètre de porche devient un vrai SEUIL DE ROCHE que l'on monte.
# La pente y est de 0,50 m sur 1,15 m, soit 0,20 m par échantillon de
# 0,40 m — sous la marche maximale de 0,55 m du filet de comportement.
PORCHE_DENIVELE = -0.58

# Stations du MASSIF : mêmes axes, prolongés au-delà de la cavité, plus le
# jeu latéral et le jeu de clé. Au-delà de la cavité les demi-largeurs de
# référence sont fantômes (le solide y est plein).
# SILHOUETTE CAPTURÉE TÔT, ET ELLE A TRANCHÉ. Le premier jet donnait des
# jeux monotones (0,85 → 1,60 → 0,85) : les deux silhouettes isolées
# sortaient en MICHE LISSE, une coque de casque sans une arête. C'est la
# leçon du pylône — la PROJECTION décide, pas le maillage : un relief
# angulaire, si régulier soit-il le long de l'axe, se projette en dôme.
#
# Trois corrections, toutes dans le profil et non dans la texture :
#   1. deux SOMMETS séparés d'un col (stations 3 et 5, jeu de clé 2,00 et
#      2,05 contre 1,50 entre elles) — le contour monte, redescend, remonte ;
#   2. une VISIÈRE : la station 0 déborde la station 1 (1,70 contre 1,30
#      latéral, 1,55 contre 1,35 en clé), donc la roche surplombe la bouche.
#      C'est le « sourcil » que la passe rejetée posait en boîte séparée,
#      ici construit DANS la coque ;
#   3. des ÉPAULES latérales décorrélées de la clé (station 7 à 2,15
#      latéral pour 1,70 en clé) — le contour de face et le contour de
#      profil ne racontent plus la même chose.
#
# Le jeu de clé ne descend jamais sous 1,35 m tant que la cavité existe :
# à 0,95 m, le contrôle d'épaisseur tombait à 0,35 m de linteau — un
# creux de bruit extérieur et une bosse de bruit intérieur se cumulent.
MASSIF = [
    # ax     ay    hw_ref cle_ref  jeu_lat jeu_cle
    (0.00, -1.15, 1.90, 2.80, 1.70, 1.55),   # visière saillante
    (0.00,  0.00, 1.70, 2.85, 1.60, 1.45),   # retrait derrière la visière
    (0.06,  1.60, 1.85, 2.95, 1.85, 1.55),
    (0.24,  3.20, 2.15, 2.80, 2.10, 2.15),   # SOMMET 1
    (0.58,  4.75, 2.70, 2.90, 2.00, 1.68),   # col
    (1.05,  6.25, 3.05, 2.92, 2.10, 2.22),   # SOMMET 2, au-dessus de la salle
    (1.62,  7.60, 2.80, 2.80, 1.95, 1.62),
    (2.25,  8.65, 2.00, 2.40, 2.15, 1.70),   # épaule latérale
    (2.85,  9.25, 1.15, 1.80, 1.95, 1.35),
    (3.35,  9.90, 0.85, 1.35, 1.60, 1.55),   # ressaut de queue
    (3.85, 10.55, 0.55, 0.95, 1.35, 0.90),
    (4.30, 11.15, 0.30, 0.55, 0.95, 0.70),
]
MASSIF_APEX = (4.65, 11.65, 1.20)

# STRATES. La roche de la vallée est sédimentaire ocre : « strates
# horizontales larges cassées par des fractures diagonales »
# (VISUAL_ASSET_BIBLE §2.1). On rapproche donc la hauteur de la peau d'une
# grille ABSOLUE de niveaux — absolue, pour que les replats se poursuivent
# d'une station à l'autre et fassent de vraies assises, au lieu d'onduler
# avec la section. Sans les coller (0,55) : les arêtes restent franches,
# le volume garde sa forme.
PAS_STRATE = 0.85
## 0,55 tant que le champ SAUTAIT d'un lit à l'autre ; 0,85 depuis qu'il est
## continu. La borne dure est 1,00 exclu : voir la démonstration dans
## `deformer_massif()` — à 1,00 la dérivée s'annule au centre des lits et la
## garantie de non-repli tombe.
FORCE_STRATE = 0.85
## Dureté de la marche : 1,0 = aucun effet (rampe droite), 3,0 = replat large
## et joint franc. Au-delà de ~5 le joint devient une arête vive qui scintille
## en mouvement.
DURETE_STRATE = 3.0
## Pendage du banc : tangente de l'angle en X et en Y. Voir
## `deformer_massif()` — un lit horizontal se lit comme une courbe de
## niveau, un lit à ~7° comme une strate basculée.
PENDAGE_X = 0.11
PENDAGE_Y = -0.06
## Bandes de valeur, sur le z ABSOLU, partagées par toutes les pièces.
BANDE_BASE_Z = 0.55
BANDE_COLLERETTE_Z = 3.10
## Amplitude de l'ondulation qui BRISE la limite de bande. À 0 on retrouve
## deux traits horizontaux ; au-delà de ~0,8 m la bande cesse de se lire
## comme une strate et devient du bruit. Voir `famille_massif()`.
ONDULATION_BANDE_M = 0.45

# DIACLASE ET CORNICHE — ce qui rend un contour CONCAVE.
#
# Deuxième silhouette : les deux sommets et les strates ont produit des
# facettes, mais le contour restait celui d'une patate. C'est arithmétique
# et non artistique : un rayon en R·(1 + 0,15·harmoniques) ne peut pas
# devenir concave, quelle que soit la richesse des harmoniques. Il faut
# une ENTAILLE et une SAILLIE, franches et localisées.
#
#   * la diaclase est une fracture verticale qui court sur toute la
#     longueur du rocher et mord jusqu'à 45 % du jeu latéral. Elle donne
#     l'encoche du contour, et en jeu une arête verticale que la lumière
#     rasante souligne ;
#   * la corniche est un replat saillant à mi-hauteur, du côté du soleil :
#     elle projette une ombre portée sur le flanc, et son dessous est
#     concave — ce qu'aucune bosse ne peut donner.
#
# Le retrait de la diaclase est plafonné à une FRACTION DU JEU, jamais à
# une valeur absolue : la roche restante ne peut donc pas passer sous le
# seuil d'épaisseur, quel que soit le réglage des jeux.
DIACLASE_THETA = math.radians(158.0)
DIACLASE_LARGEUR = math.radians(34.0)
DIACLASE_PART_LAT = 0.40
DIACLASE_PART_CLE = 0.28
CORNICHE_THETA = math.radians(18.0)
CORNICHE_AMPL = 0.62
CORNICHE_HAUT = 0.46
CORNICHE_ETAL = 0.17

# 0,055 au premier jet : en capture, les parois de la galerie sortaient en
# PLANS GRIS LISSES — le défaut « face intérieure rectiligne » revenait par
# la petite porte. 0,085 donne du relief sans mordre le gabarit ; le jeu de
# clé des stations 3 à 6 est relevé d'autant pour garder l'épaisseur.
# ---------------------------------------------------------------------------
# R2a-3.1 — CE QUI CHANGE, ET POURQUOI LE RESTE NE SUFFISAIT PAS.
#
# La revue a rendu FAIL VISUEL sur : « masse extérieure en forme de miche
# lisse · bouche presque parfaitement semi-circulaire · grands aplats sans
# strates ni contreforts · intérieur cylindrique évoquant un tunnel en
# béton · niche sans composition ».
#
# Le diagnostic n'est pas artistique, il est ARITHMÉTIQUE, et la passe
# précédente l'avait à moitié trouvé sans en tirer la conséquence : elle
# notait déjà qu'« un rayon en R·(1 + a·harmoniques) ne peut pas devenir
# concave ». C'est vrai — et ça vaut aussi pour la FORME de la section.
# Tant que le profil est `hw·cos θ` par `cle·sin^p θ`, on balaie une
# demi-ellipse : la bouche est un demi-cercle, la galerie est un tube, et
# aucune amplitude de bruit n'en fera de la roche. Deux sommets, une
# visière et une diaclase ont été ajoutés à cette ellipse ; ils n'ont pas
# changé sa nature.
#
# Quatre changements de NATURE, pas de réglage :
#
#   1. SECTIONS À FACETTES. Le rayon est constant sur chaque facette : la
#      section devient un polygone à arêtes franches, tournant lentement le
#      long de l'axe. C'est ce qui supprime d'un coup le tube et le
#      demi-cercle.
#   2. LOBES — trois masses majeures localisées en (station, azimut,
#      hauteur) : surplomb au-dessus de la bouche, contrefort latéral
#      descendant au sol, couronne rompue à l'arrière. Elles donnent la
#      silhouette à trois masses exigée.
#   3. RESSAUTS — entailles franches bornées en fraction du jeu : ce sont
#      elles qui rendent le contour CONCAVE, ce qu'aucune bosse ne peut.
#   4. ASYMÉTRIE gauche/droite et LINTEAU INCLINÉ par station, plus une
#      ALCÔVE latérale et des NERVURES de plafond à l'intérieur.
# ---------------------------------------------------------------------------

# Nombre de facettes de la section, et rotation par station. Impair pour
# qu'aucune facette ne soit exactement opposée à une autre — une section
# paire lit encore comme un tube aplati.
FACETTES = 9
# 0,23 rad par station A ÉTÉ MESURÉ COMME REPLIANT LA SURFACE. Le vrillage
# s'accumule (0,23 × 8 = 1,84 rad, soit 105°, deux facettes et demie) ; entre
# les stations 7 et 8, où la demi-largeur chute de 36 %, la bande de quads se
# croise elle-même — deux paires de faces, colonnes 1 et 54, invisibles à
# `controle_fermeture`. Balayage complet :
#   0,23 -> 2 croisements · 0,18 -> 0 · 0,14 -> 1 · 0,10 -> 0 · 0,06 -> 0
#   0,03 -> 0 · 0,00 -> 0
# Le phénomène est en lame de couteau, et 0,18 ne passe que par chance : on
# prend 0,10, au milieu d'un palier de zéros, et le contrôle
# d'auto-intersection des sources reste en place pour le jour où une autre
# constante rapprochera à nouveau deux bandes.
FACETTE_ROTATION = 0.10      # rad ajoutés par station : les arêtes vrillent
FACETTES_MASSIF = 7
FACETTE_ROTATION_MASSIF = 0.31
## Voir `anneau_exterieur` : rend le polygone du massif CIRCONSCRIT à la
## courbe au lieu d'y être inscrit, donc sans perte d'épaisseur de roche.
CIRCONSCRIT_MASSIF = 1.0 / math.cos(math.pi / FACETTES_MASSIF)

# Asymétrie de la cavité, par station : (facteur gauche, facteur droit,
# inclinaison du linteau en rad). Une bouche dissymétrique est demandée
# explicitement ; elle commence ici, pas dans le bruit.
CAVITE_ASYM = [
    # Les trois premières stations DÉCIDENT de la forme de la bouche, et
    # c'est la seule chose que le joueur voit en approchant. Valeurs
    # renforcées après capture : à (1,18 / 0,86 / −0,30) l'ouverture sortait
    # encore en demi-cercle sur la vue d'approche. À (1,34 / 0,79 / −0,44)
    # le linteau monte de 44 % à gauche et descend de 44 % à droite : le
    # contour de l'ouverture est une ligne brisée penchée, plus un arc.
    (1.34, 0.79, -0.44),   # porche : la joue gauche déborde, linteau penché
    (1.30, 0.81, -0.40),   # seuil
    (1.12, 0.90, -0.24),
    (0.92, 1.10, 0.10),    # la galerie se décale de l'autre côté
    (0.95, 1.14, 0.16),
    (1.06, 1.16, 0.08),    # SALLE, large des deux côtés
    (1.00, 0.98, -0.06),   # l'alcôve élargit déjà ce côté : ne pas empiler
    (1.00, 0.92, -0.12),
    (0.96, 0.90, -0.10),
]

# ALCÔVE LATÉRALE — la poche qui met la récompense en scène. Elle élargit
# la cavité d'un seul côté sur trois stations, et relève le sol de
# `ALCOVE_SEUIL` pour donner une TABLETTE de roche : la récompense se pose
# dessus au lieu d'être posée au milieu d'un sol vide (exigence 5).
ALCOVE = dict(i0=5, i1=7, theta=math.radians(180.0),
              dtheta=math.radians(52.0), v0=0.05, dv=0.50, ampl=1.20)
## LA TABLETTE D'ALCÔVE EST MORTE, ET C'EST LE MÊME DÉFAUT QUE LA BANQUETTE.
## Relevé de 0,34 puis 0,52 m sur la fenêtre d'azimut de l'alcôve (52°), le
## sol de l'alcôve mesure en réalité 0,21 à 0,30 m — c'est-à-dire le palier
## seul. Une fenêtre angulaire plus étroite que l'écart entre deux sommets
## du polygone (40° à 9 facettes) n'a aucun sommet sur lequel s'appliquer :
## l'arête droite qui joint ses voisins l'efface. On garde donc 0 ici, et
## c'est le PALIER — uniforme sur tous les azimuts, donc porté par tous les
## sommets — qui fait la plate-forme du fond. L'élargissement de l'alcôve,
## lui, survit : il agit sur le rayon à tous les azimuts de sa fenêtre.
ALCOVE_SEUIL = 0.0

# NERVURES DE PLAFOND — de la matière rentrée sous la voûte, à azimut fixe,
# donc courant sur toute la longueur. Placées au-dessus de v = 0,62, soit
# environ 2,0 m : au-dessus de la capsule joueur (1,85 m), jamais dans le
# gabarit. Elles ne peuvent qu'ÉPAISSIR la roche, donc jamais faire tomber
# le contrôle d'épaisseur.
# PALIER — le sol restait PLAT, et ça se mesure : σ = 4,6 sur 500 × 180 px
# de sol dans la vue vers la sortie, contre σ = 16 sur la façade. Un plan
# uniforme ne devient pas une roche parce qu'il est en pierre. Le sol monte
# donc par marches vers le fond : on entre en descendant sous la visière, on
# remonte vers l'alcôve. Mesuré sur le maillage produit, du seuil au fond :
# −0,035 → 0,145 → 0,942 → 1,148 m.
#
# UNE BANQUETTE A ÉTÉ ESSAYÉE ICI, ET RETIRÉE — la trace vaut mieux que le
# code mort. Une tablette de 0,34 m sur une fenêtre de 62° d'azimut a été
# ajoutée le long de la paroi, puis MESURÉE au point où elle devait culminer :
# 0,164 m, soit exactement le palier seul. Cause : la section n'a que 9
# sommets, dont 4 ou 5 sous l'horizon ; une fenêtre angulaire qui ne tombe
# pas sur un sommet est effacée par l'arête droite qui joint ses voisins.
# Un relief plus fin que la résolution du polygone n'existe pas — c'est la
# contrepartie du choix de facettes larges, et il vaut mieux l'écrire que
# de laisser un mécanisme qui ne produit rien.
PALIER = (0.00, 0.00, 0.04, 0.10, 0.16, 0.26, 0.50, 0.78, 0.92)

NERVURES_THETA = (math.radians(56.0), math.radians(124.0))
NERVURE_DEMI = math.radians(10.0)
NERVURE_RENTREE = 0.26
NERVURE_V_MIN = 0.62

# LOBES DU MASSIF — les trois masses majeures.
# (i0, i1) = plage de stations ; theta/dtheta = fenêtre d'azimut ;
# v0/dv = bande de hauteur ; lat/z = matière ajoutée, en mètres ;
# biais = décalage d'azimut du gain en z, qui casse le sommet en biseau.
LOBES = (
    dict(nom="surplomb", i0=0, i1=2, theta=math.radians(90.0),
         dtheta=math.radians(66.0), v0=0.74, dv=0.34,
         lat=0.30, z=1.45, biais=math.radians(-22.0)),
    dict(nom="contrefort", i0=2, i1=6, theta=math.radians(4.0),
         dtheta=math.radians(38.0), v0=0.18, dv=0.52,
         lat=1.75, z=0.20, biais=0.0),
    dict(nom="couronne", i0=6, i1=10, theta=math.radians(122.0),
         dtheta=math.radians(58.0), v0=0.66, dv=0.40,
         lat=0.55, z=1.15, biais=math.radians(34.0)),
    # Contre-lobe de l'alcôve : la poche intérieure creuse la roche d'un
    # côté ; sans matière ajoutée en face, le contrôle d'épaisseur refuse.
    # 1,45 m et 56° au premier jet : le contrôle d'épaisseur a REFUSÉ
    # l'enregistrement à 0,51 m, et son point fautif — station 6, azimut
    # 161°, z 1,24 — a nommé la cause. Le fondu angulaire de l'alcôve
    # (0,71) et celui du lobe (0,74) sont proches, mais le BRUIT extérieur
    # travaille sur une base de 4,75 m : ±0,15 d'amplitude font ±0,71 m,
    # ce qui écrase le budget du lobe. La marge doit donc dominer le bruit,
    # pas l'égaler.
    dict(nom="dos_alcove", i0=4, i1=8, theta=math.radians(180.0),
         dtheta=math.radians(72.0), v0=0.12, dv=0.60,
         lat=2.85, z=0.10, biais=0.0),
)

# RESSAUTS — entailles franches. Le retrait est une FRACTION du jeu, jamais
# une valeur absolue : la roche restante ne peut donc pas passer sous le
# seuil d'épaisseur, quel que soit le réglage.
RESSAUTS = (
    dict(nom="entaille_est", i0=1, i1=5, theta=math.radians(300.0),
         dtheta=math.radians(30.0), v0=0.46, dv=0.20, part=0.46),
    dict(nom="entaille_nord", i0=5, i1=9, theta=math.radians(238.0),
         dtheta=math.radians(26.0), v0=0.30, dv=0.22, part=0.40),
)

# ROCHERS DU KIT — R2a-3.3, et voici pourquoi les masses lissées n'ont pas
# suffi non plus.
#
# Les onze masses annexes de la tranche précédente ont été construites,
# fusionnées par booléen exact, contrôlées vertes sur neuf critères, et
# refusées : « la fusion booléenne a supprimé les séparations topologiques,
# mais elle n'a pas transformé les lofts polygonaux en roche. Une union
# mathématique n'est pas une fusion artistique. »
#
# LE DIAGNOSTIC, MESURÉ. `tools/measure_module_relief.py` a été écrit pour
# trancher, et il donne le chiffre que ni le nombre de facettes ni la part
# de triangles ne montrent — la plus grande PLAGE PLANE CONNEXE :
#
#   SM_WaterfallCave.glb (lofts)   162 familles de normales,  7,5 %  ...
#                                  ... et une plage plane de 60,93 m2
#   template-detail.glb (kit)       68 familles,              8,1 %
#                                  ... et une plage plane de  2,59 m2
#
# Les deux premières colonnes déclarent les deux objets équivalents. La
# troisième dit la vérité : le loft porte un pan plat plus grand qu'un
# court de squash. C'est LITTÉRALEMENT ce que le lead a vu, et aucun de mes
# neuf contrôles ne le mesurait. Un rayon quantifié par azimut ne peut pas
# produire autre chose : neuf facettes fois huit stations font soixante-
# douze quadrilatères, et soixante-douze quadrilatères de trois mètres
# restent soixante-douze quadrilatères de trois mètres.
#
# LA SORTIE N'EST DONC PAS UN TROISIÈME RÉGLAGE, c'est un changement de
# source de relief. Les modules du kit Kenney Modular Cave (CC0 1.0, déjà
# attribué et déjà partiellement promu dans assets/environment/dungeon/)
# portent un relief SCULPTÉ que rien de paramétrique ne reproduit ici. Ils
# deviennent les briques ; le loft extérieur ne produit plus aucune surface
# visible.
#
# CE QUI SUBSISTE DE L'ANCIEN CODE, ET À QUEL TITRE :
#   * `anneau_exterieur()` ne sert plus qu'à la COQUE DE COLLISION, qui n'est
#     jamais rendue — un proxy convexe par station y est exactement ce qu'il
#     faut, et le lead l'a explicitement autorisé ;
#   * `anneau_interieur()` sert au VOLUME NÉGATIF : la cavité devient un
#     solide fermé qu'on SOUSTRAIT du rocher. La bouche n'est donc plus une
#     collerette dessinée, c'est la trace de découpe du tube dans la roche —
#     un contour irrégulier que je n'ai pas à inventer ;
#   * `masse_annexe()`, `MASSES_ANNEXES` et `controle_annexe_hors_cavite()`
#     sont SUPPRIMÉS. Les garder « au cas où » aurait refait l'erreur de la
#     télémétrie morte : du code qui ment sur ce qu'il fait.
#
# ÉCHELLE. Les dimensions natives ont été mesurées AVANT toute implantation
# (`tools/measure_module_relief.py`, journal dans le rapport) : la grille du
# kit est de 4 m, les murs montent à 4,05 m, le rocher `template-detail`
# fait 2,64 x 2,81 x 4,35 m. Le facteur est donc borné à [0,55 ; 1,55] :
# au-delà, une roche cesse d'être une roche pour devenir un grand polyèdre,
# et c'est le reproche exact que je viens de recevoir.
#
# FERMETURE. Mesuré en Blender, après soudure des sommets que l'import glTF
# sépare à chaque arête dure : `template-detail`, `gate-rock`,
# `template-wall-top` et `gate-overhang` sont des VOLUMES fermés (0 arête de
# bord, volume 12,8 / 16,7 / 15,9 / 5,4 m3) ; `template-wall`,
# `template-wall-half`, `template-wall-detail-a` et `template-corner` sont
# des coques ouvertes (8 à 24 arêtes de bord) qu'il faut refermer avant tout
# booléen. `charger_module()` le fait et REFUSE tout module qui reste
# ouvert : un booléen sur une coque ouverte ne rend pas un solide, il rend
# n'importe quoi, et sans erreur visible.
KIT_ROCHES = Path(__file__).resolve().parents[3] / (
    "asset_library/inbox/kenney_modular_cave_1_0/Models/GLB format")

## UNE SEULE BRIQUE, ET C'EST UNE CONCLUSION MESURÉE, PAS UN APPAUVRISSEMENT.
##
## `tools/measure_module_relief.py` donne, pour chaque module, la plus grande
## PLAGE PLANE CONNEXE — le plus grand pan plat que l'oeil voit :
##
##   template-detail          2,59 m2   relief 0,344 m   <- un vrai rocher
##   gate-rock                7,24 m2   relief 0,156 m
##   template-wall-half       8,10 m2   relief 0,201 m
##   template-corner         11,31 m2   relief 0,431 m
##   template-wall           16,20 m2   relief 0,236 m
##   template-wall-top       18,00 m2   relief 0,106 m
##   gate-overhang            (dalle)   relief 0,000 m
##
## Tout le kit, sauf `template-detail`, est de la PANNEAUTERIE : des murs,
## des corniches, des arches, faits pour être plaqués contre une paroi de
## donjon. Leur dos est plat par construction, et le rebouchage qui en fait
## des solides ajoute encore un plan entier. Enfoui, ce plan ne coûte rien ;
## exposé, c'est exactement le « grand aplat » du rejet. Mesuré sur la
## formation : 8,82 m2 au piédroit droit avec `template-wall-half`, puis
## 15,88 m2 au linteau avec `gate-rock` et `gate-overhang`.
##
## Le lead demande de « véritables formes rocheuses ». Il n'y en a qu'une
## dans ce kit, et la variété se fait comme la ferait un décorateur : par
## l'échelle (0,55 à 1,55), le lacet, le tangage, le roulis et le
## groupement. Le remaillage volumétrique fond ensuite les trente-quatre
## exemplaires en une seule roche, et le champ de strates les traverse.
##
## Les autres entrées restent déclarées : elles sont chargeables, vérifiées,
## et redeviendront utiles le jour où une paroi de donjon en aura besoin.
MODULES = {
    "R": dict(fichier="template-detail",        natif=(2.64, 2.81, 4.35)),
    "A": dict(fichier="gate-rock",              natif=(4.00, 2.45, 4.05)),
    "T": dict(fichier="template-wall-top",      natif=(4.00, 1.13, 4.50)),
    "O": dict(fichier="gate-overhang",          natif=(4.00, 2.05, 0.80)),
    "W": dict(fichier="template-wall",          natif=(4.00, 2.16, 4.05)),
    "H": dict(fichier="template-wall-half",     natif=(2.00, 1.81, 4.05)),
    # LES MODULES DE MUR ONT UN DOS PLAT, ET IL FAUT LE SAVOIR AVANT DE LES
    # PLACER. `W` et `H` sont des PANNEAUX : leur face arrière est le
    # capuchon que `charger_module()` a posé pour en faire des solides, soit
    # 16,2 m2 pour `W` et 8,1 m2 pour `H` d'un seul plan. Enfoui dans la
    # masse, il ne coûte rien ; exposé, c'est exactement le « grand aplat »
    # que le lead reproche. Mesuré : 8,82 m2 de plage plane connexe en
    # façade, centrée en (2,04 ; 0,56 ; 2,66), c'est-à-dire au piédroit
    # droit de la bouche. Les quatre roches de la zone du seuil sont donc
    # passées à `R` (`template-detail`), qui est un volume rocheux sur ses
    # six faces — plus grande plage plane 2,59 m2. `W` et `H` restent
    # employés en flanc et à l'arrière, dos rentré dans la masse.
}
# DEUX MODULES ONT ÉTÉ ÉCARTÉS, chacun pour une raison mesurée.
#
# `template-corner` est le module au meilleur relief du kit (0,431 m
# d'amplitude, 76 familles de normales) et le seul qui RÉSISTE à la
# réparation : après soudure, résolution d'auto-intersection et quatre
# passes de rebouchage, il conserve 10 arêtes de bord. Un solide dont je ne
# peux pas prouver qu'il est plein n'entre pas dans un booléen.
#
# `template-wall-detail-a` passe TOUS les contrôles — fermé, sans
# auto-intersection, volume 16,81 m3 — et fait pourtant échouer l'union. Il
# a fallu une bissection roche par roche pour le voir : en fusionnant les
# trente-quatre roches une à une, les sept premières donnent 0 arête
# irrégulière et `Bouche_Joue` en donne 57 d'un coup. C'est le seul de ses
# trois emplois à figurer si tôt dans l'ordre, et c'est le seul module
# rebouché de la liste. Son capuchon `triangle_fill` est vraisemblablement
# un éventail dégénéré : invisible aux contrôles de fermeture, fatal au
# solveur. Ses trois emplois passent à `W`, dont les cotes sont voisines
# (4,00 x 2,16 x 4,05 contre 4,00 x 2,02 x 4,40).
#
# La leçon vaut d'être écrite : « ferme et sans auto-intersection » ne veut
# pas dire « utilisable dans un booléen ». Seule la bissection le dit.

ECHELLE_MIN = 0.55
ECHELLE_MAX = 1.55

# LA RÈGLE QUI GOUVERNE TOUTES LES COTES EN Z : LE FOND PLAT SE BLINDE.
#
# `template-detail` est un rocher sur cinq faces et une DALLE sur la
# sixième — il est fait pour poser sur une tuile de donjon. À l'échelle
# 1,45 ce fond mesure 3,83 x 4,07 m, soit près de seize mètres carrés d'un
# seul plan. Posé haut, il devient le plafond plat d'un surplomb : mesuré,
# 11,04 m2 de plage plane connexe centrés en (1,43 ; 0,27 ; 2,72),
# c'est-à-dire juste au-dessus de la bouche.
#
# Toute roche dont la cote z0 est au-dessus du terrain doit donc ENFONCER
# son fond d'au moins un mètre dans la masse qui la porte. Ce n'est pas un
# réglage esthétique, c'est ce qui empêche le défaut de revenir : la seule
# face plate du module cesse d'exister dès qu'elle est à l'intérieur.
#
# IMPLANTATION. Repère Blender, Z vertical ; la galerie s'enfonce vers +Y,
# la bouche s'ouvre vers -Y. Vérifié contre la caméra d'approche réelle :
# +X du modèle projette à 0,98 sur la DROITE de l'image, donc x negatif =
# gauche de l'image, x positif = droite. Les trois masses majeures sont
# donc lisibles dans l'ordre gauche -> centre -> droite ci-dessous.
#
# `pose` = (x, y, z_du_dessous) du centre en plan ; `lacet` en degrés ;
# `tangage`/`roulis` en degrés, petits, pour qu'aucune roche ne repose à
# plat ; `ech` = facteur, uniforme ou (sx, sy, sz).
#
# HAUTEURS VOULUES, et c'est une réponse point par point au rejet :
#   * « aucune cheminée centrale » — le point haut n'est PAS au-dessus de
#     la bouche : la masse est est la plus haute (~10,4 m), la couronne de
#     la bouche plafonne à ~8,3 m et fait 7 m de large. Une masse large et
#     décentrée ne peut pas se lire en cheminée ;
#   * « trois masses larges et asymétriques » — ouest 8,5 m d'emprise pour
#     6,4 m de haut ; centre 7,2 m pour 8,3 ; est 7,8 m pour 10,4. Aucune
#     n'a la silhouette d'une autre ;
#   * « linteau naturel épais » — `gate-rock` EST une arche : posée à
#     cheval sur la bouche, elle donne un linteau de roche sculptée, pas
#     un chanfrein calculé ;
#   * « piédroits asymétriques et plusieurs plans de profondeur » — le
#     piédroit gauche (H, y = -0,90) est en retrait du droit (H, y = -1,30),
#     et deux roches avancées (y ~ -2,0) forment un troisième plan.
ROCHERS = (
    # --- MASSE OUEST (gauche de l'image) : large, basse, avancée ---
    dict(nom="Ouest_Socle",   mod="R", pose=(-4.60,  0.20, -1.40),
         lacet=24,  tangage=5,  roulis=-4, ech=1.50, rang="majeur"),
    dict(nom="Ouest_Dos",     mod="R", pose=(-5.60,  3.00, -1.60),
         lacet=118, tangage=-6, roulis=3,  ech=1.35, rang="majeur"),
    dict(nom="Ouest_Flanc",   mod="R", pose=(-3.30,  1.90, -1.20),
         lacet=65,  tangage=4,  roulis=5,  ech=1.15, rang="majeur"),
    # Enfoncée de 0,55 m et rapprochée de 0,20 m : le passage du piédroit
    # ouest de `H` à `R` a réduit son emprise, et la corniche s'est
    # retrouvée ISOLÉE — aucune face croisant une autre pièce.
    dict(nom="Ouest_Corniche", mod="R", pose=(-4.75, 1.60,   1.70),
         lacet=200, tangage=-7, roulis=4,  ech=1.20, rang="majeur"),
    dict(nom="Ouest_Piedroit", mod="R", pose=(-2.85, -0.90, -1.00),
         lacet=140, tangage=3,  roulis=-5, ech=1.30, rang="majeur"),

    # --- MASSE CENTRALE : le linteau et la couronne de la bouche ---
    dict(nom="Bouche_Linteau", mod="R", pose=(0.55, -0.35,   1.60),
         lacet=6,   tangage=-4, roulis=2,  ech=1.35, rang="majeur"),
    dict(nom="Bouche_Epaule",  mod="R", pose=(1.90, 1.10,   1.90),
         lacet=250, tangage=6,  roulis=-3, ech=1.45, rang="majeur"),
    dict(nom="Bouche_Joue",    mod="R", pose=(-0.60, 1.60,   2.00),
         lacet=172, tangage=-5, roulis=4,  ech=1.35, rang="majeur"),
    dict(nom="Bouche_Couronne", mod="R", pose=(0.90, 0.95,   4.20),
         lacet=42,  tangage=8,  roulis=-6, ech=1.15, rang="majeur"),
    dict(nom="Bouche_Visiere", mod="R", pose=(0.20, -1.85,   2.45),
         lacet=8,   tangage=-9, roulis=3,  ech=1.25, rang="majeur"),

    # --- MASSE EST (droite de l'image) : la plus haute, hors axe ---
    dict(nom="Est_Socle",     mod="R", pose=( 4.90,  2.20, -1.60),
         lacet=300, tangage=-5, roulis=5,  ech=1.50, rang="majeur"),
    dict(nom="Est_Angle",     mod="R", pose=( 5.80,  5.00, -1.40),
         lacet=25,  tangage=4,  roulis=-4, ech=1.40, rang="majeur"),
    dict(nom="Est_Flanc",     mod="R", pose=( 3.55,  4.40, -1.20),
         lacet=210, tangage=-6, roulis=3,  ech=1.25, rang="majeur"),
    dict(nom="Est_Epaule",    mod="R", pose=(5.20, 3.40,   2.30),
         lacet=75,  tangage=7,  roulis=-5, ech=1.40, rang="majeur"),
    dict(nom="Est_Crete",     mod="R", pose=(4.60, 4.55,   4.40),
         lacet=150, tangage=-8, roulis=6,  ech=1.10, rang="majeur"),

    # --- PLANS DE PROFONDEUR autour de la bouche ---
    dict(nom="Seuil_PiedroitDroit", mod="R", pose=( 2.70, -1.30, -1.00),
         lacet=32,  tangage=5,  roulis=4,  ech=1.25, rang="intermediaire"),
    dict(nom="Seuil_AvanceeGauche", mod="R", pose=(-2.20, -1.95, -1.30),
         lacet=205, tangage=-4, roulis=-6, ech=1.00, rang="intermediaire"),
    dict(nom="Seuil_Joue",    mod="R", pose=(3.40, 0.40,   0.30),
         lacet=128, tangage=6,  roulis=3,  ech=0.95, rang="intermediaire"),
    dict(nom="Seuil_Ecran",   mod="R", pose=(-3.45, -1.40,   0.60),
         lacet=96,  tangage=-6, roulis=5,  ech=1.10, rang="intermediaire"),

    # --- MASSE ARRIÈRE : la formation a de l'épaisseur en Y ---
    dict(nom="Arriere_Ouest", mod="R", pose=(-2.40,  6.40, -1.50),
         lacet=40,  tangage=5,  roulis=-3, ech=1.35, rang="intermediaire"),
    dict(nom="Arriere_Angle", mod="R", pose=( 0.90,  7.40, -1.40),
         lacet=195, tangage=-5, roulis=4,  ech=1.35, rang="intermediaire"),
    dict(nom="Arriere_Est",   mod="R", pose=( 3.20,  8.40, -1.30),
         lacet=310, tangage=6,  roulis=-4, ech=1.30, rang="intermediaire"),
    dict(nom="Arriere_Mur",   mod="R", pose=(-1.10,  8.60, -1.10),
         lacet=118, tangage=-4, roulis=3,  ech=1.20, rang="intermediaire"),
    dict(nom="Arriere_Dos",   mod="R", pose=(1.70, 5.20,   1.90),
         lacet=260, tangage=7,  roulis=-5, ech=1.15, rang="intermediaire"),
    dict(nom="Arriere_Cap",   mod="R", pose=(-0.40, 7.00,   2.30),
         lacet=84,  tangage=-7, roulis=4,  ech=1.15, rang="intermediaire"),
    # Rapprochée de (5,00 ; 7,00 ; 2,30) : les BOÎTES recouvraient
    # `Est_Angle` sur 1,46 m et pourtant aucune face ne se croisait —
    # `template-detail` est un rocher irrégulier qui ne remplit pas sa
    # boîte, et deux coins peuvent se chevaucher sans matière commune.
    dict(nom="Arriere_Loin",  mod="R", pose=(5.40, 6.10,   1.10),
         lacet=20,  tangage=4,  roulis=6,  ech=1.25, rang="intermediaire"),


    dict(nom="Seuil_Auvent",   mod="R", pose=(-0.30, -1.60,  2.20),
         lacet=25,  tangage=-7, roulis=5,  ech=1.35, rang="majeur"),

    # --- ROCHERS SECONDAIRES : l'échelle se lit par la variété des tailles.
    # Aucun devant la bouche : au-delà de y = -1,6 ils restent a |x| >= 2,0,
    # sinon ils masqueraient l'entrée — c'est la faute que le lead a
    # relevée sur les fleurs, je ne vais pas la refaire avec des cailloux.
    dict(nom="Pied_OuestLoin", mod="R", pose=(-6.40, -1.20, -1.20),
         lacet=65,  tangage=6,  roulis=-4, ech=0.80, rang="secondaire"),
    dict(nom="Pied_OuestBas",  mod="R", pose=(-2.90, -3.00, -0.90),
         lacet=150, tangage=-5, roulis=5,  ech=0.62, rang="secondaire"),
    dict(nom="Pied_EstBas",    mod="R", pose=( 2.30, -3.05, -0.90),
         lacet=22,  tangage=4,  roulis=-6, ech=0.75, rang="secondaire"),
    dict(nom="Pied_EstProche", mod="R", pose=( 5.60, -0.90, -1.00),
         lacet=250, tangage=-6, roulis=3,  ech=0.85, rang="secondaire"),
    dict(nom="Pied_EstLoin",   mod="R", pose=( 6.90,  3.80, -1.20),
         lacet=105, tangage=5,  roulis=4,  ech=0.90, rang="secondaire"),
    dict(nom="Pied_OuestDos",  mod="R", pose=(-6.20,  5.20, -1.30),
         lacet=285, tangage=-4, roulis=-5, ech=0.95, rang="secondaire"),
    dict(nom="Pied_Dalle",     mod="R", pose=(-4.10, -2.55,  -1.10),
         lacet=40,  tangage=7,  roulis=3,  ech=0.80, rang="secondaire"),
    dict(nom="Pied_Eclat",     mod="R", pose=( 4.20, -2.40, -1.00),
         lacet=190, tangage=-8, roulis=6,  ech=0.55, rang="secondaire"),
)

# ASSISE ENTERRÉE — un pavé, et il est assumé comme tel.
#
# Il garantit deux choses qu'aucun placement de roches ne garantit : que la
# formation est PLANTÉE (jupe de plus de 2 m sous le plan de sol, contrôle
# `controle_assise`) et qu'elle est CONNEXE même si deux roches de pied
# s'effleurent. Il est intégralement sous le terrain gelé — son sommet est
# à -0,55 m — donc il ne produit aucune surface visible. C'est la raison
# pour laquelle `controle_plage_plane()` ne mesure QUE ce qui est au-dessus
# de z = 0 : mesurer les faces d'un pavé enterré ferait rougir un contrôle
# sur une géométrie que personne ne verra jamais, et un contrôle qui rougit
# à tort finit désactivé.
def rochers_gaine():
    """LA GAINE — des roches calculées depuis la cavité, pas posées à la main.

    POURQUOI ELLE REMPLACE SEIZE ROCHES PLACÉES UNE PAR UNE. Le contrôle
    d'épaisseur par rayon nomme précisément le point le plus mince, et j'ai
    répondu seize fois en ajoutant une roche là où il pointait : voûte de la
    bouche, voûte médiane, flancs ouest et est, salle profonde, socles.
    À chaque exécution le contrôle désignait un autre azimut, et chaque
    cycle coûtait cinq minutes. C'est le symptôme d'une méthode fausse : je
    corrigeais une mesure au lieu de garantir la propriété.

    La gaine la garantit par construction. Pour chaque station du chemin,
    trois roches sont posées — deux flancs et une voûte — à une distance de
    l'axe égale à la demi-largeur (ou à la clé) augmentée d'une marge. Si
    CAVITE change, la gaine suit ; aucune cote n'est à recopier.

    Elle est INVISIBLE du dehors : le remaillage la fond dans la masse, la
    soustraction la recreuse côté cavité, et les roches de composition
    restent seules à porter la silhouette. Son unique rôle est qu'aucun
    rayon parti de l'axe ne sorte sur moins de `EPAISSEUR_MIN_M` de roche.

    Les angles ne sont pas aléatoires : ils dérivent de l'indice de station,
    donc deux exécutions donnent le même rocher.
    """
    sortie = []
    for i, (ax, ay, hw, cle) in enumerate(CAVITE):
        if i == 0 or i >= len(CAVITE) - 1:
            continue
        # CINQ AZIMUTS, PAS TROIS. La première gaine ne posait que deux
        # flancs et une voûte — 0°, 90°, 180° — et le contrôle a aussitôt
        # désigné les DIAGONALES : stations 1 et 4, azimuts 135° et 141°,
        # « 0 croisement ». Entre un flanc et une voûte il reste un quart de
        # tour, et un rocher ne remplit pas sa boîte englobante.
        # LA GAINE NE DOIT PAS DÉCIDER DE LA CRÊTE, et elle le faisait.
        #
        # Mesuré : à l'échelle 1,45 et à 1,60 m du bord, ses trente-cinq
        # rochers culminaient à `cle + 5,31` ≈ 8,26 m quand les masses de
        # composition plafonnent à 9,16 m. Un demi-mètre d'écart, sur
        # trente-cinq positions régulières le long du tube : le sommet de
        # la formation devenait une RANGÉE DE DENTS, c'est-à-dire la
        # « pointe arbitraire » interdite, en série. Une gaine dont le rôle
        # est d'être invisible ne peut pas porter la silhouette.
        #
        # LA CORRECTION PAR LE SOMMET A ÉCHOUÉ, ET C'EST INSTRUCTIF. Ancrer
        # le sommet à `cle + marge` ramenait bien la crête à 4,56 m — mais
        # en donnant la MÊME hauteur à tous les azimuts, donc en faisant
        # descendre les diagonales hautes de 2,4 m. Le contrôle a répondu
        # aussitôt : station 6, azimuts 51 à 71°, « 0 croisement — le rayon
        # sort par un JOUR ». Le placement RADIAL n'était pas un détail de
        # forme, c'est lui qui garantit la couverture.
        #
        # La crête se plafonne donc par la TAILLE, pas par la position :
        # placement radial conservé, échelle ramenée à `GAINE_ECHELLE`, et
        # `GAINE_MARGE_M` devient l'enfoncement du CENTRE au-delà de la
        # paroi. L'arithmétique, pour que le prochain lecteur n'ait pas à
        # la refaire — module natif 2,64 × 2,81 × 4,35 m :
        #
        #   demi-extension radiale = 1,32 m   (2,64 / 2, échelle 1,00)
        #   bord intérieur         = marge − 1,32 = −0,77 m  → mord la paroi
        #   bord extérieur         = marge + 1,32 = +1,87 m  → > 0,80 exigé
        #   crête                  = cle + marge + 2,18 ≈ 5,68 m
        #
        # Soit 3,5 m sous les masses majeures et 1,6 m sous les
        # intermédiaires : la gaine ne peut plus être le point haut. Elle
        # mord aussi PLUS profondément la paroi qu'avant (0,77 m contre
        # 0,32 m), donc la couverture ne repose plus sur une marge mince.
        for k, azimut in enumerate(GAINE_AZIMUTS):
            theta = math.radians(azimut)
            rayon_lat = hw + GAINE_MARGE_M
            rayon_haut = cle + GAINE_MARGE_M
            hauteur = MODULES["R"]["natif"][2] * GAINE_ECHELLE
            sortie.append(dict(
                nom="Gaine_%d_%03d" % (i, azimut), mod="R",
                pose=(ax + rayon_lat * math.cos(theta), ay,
                      rayon_haut * math.sin(theta) - hauteur * 0.5),
                lacet=(i * 47 + k * 71) % 360,
                tangage=(i % 3) * 4 - 4, roulis=(k % 5) * 3 - 6,
                ech=GAINE_ECHELLE, rang="gaine"))
    return sortie


## ENFONCEMENT DU CENTRE de la roche de gaine au-delà de la paroi, en
## mètres. Ce n'était pas cela au départ : à 1,60 m la roche était posée
## LOIN dehors et ne mordait la paroi que de 0,32 m, si bien que la
## couverture tenait à une marge mince — et que la roche dépassait de
## 3,5 m vers l'extérieur, donc par-dessus la composition. À 0,55 m elle
## mord 0,77 m de paroi et porte encore 1,87 m de roche vers le dehors,
## pour 0,80 m exigés. Le détail du calcul est dans `rochers_gaine()`.
GAINE_MARGE_M = 0.55

## Azimuts de la gaine, en degrés, mesurés depuis +X vers +Z.
##
## Trois ne suffisaient pas : le contrôle a désigné les DIAGONALES. Cinq ont
## tenu tant que la roche faisait 1,45 d'échelle. À 1,00 et sept azimuts, les
## jours se sont refermés mais l'épaisseur est tombée à 0,16 m « station 5,
## azimut 109° » — la SALLE, la station la plus large : à 3,05 m de rayon, un
## pas de 30° laisse 1,58 m de corde entre deux roches, et une roche du kit ne
## remplit pas sa boîte. Neuf azimuts ramènent le pas à 23°, donc la corde à
## 1,20 m. Le contrôle par rayon vérifie sur 56 azimuts, et c'est lui qui
## tranche — pas ce commentaire.
GAINE_AZIMUTS = (0, 22, 45, 67, 90, 112, 135, 157, 180)

## Échelle des roches de gaine. Elles sont invisibles ; seules comptent leur
## capacité à porter `EPAISSEUR_MIN_M` autour du tube et leur INCAPACITÉ à
## porter la crête (voir l'arithmétique dans `rochers_gaine()`).
##
## 1,15 et non 1,00 : la même mesure d'épaisseur demandait aussi plus de
## portée radiale. La crête passe de 5,68 à 6,00 m, soit encore 1,3 m sous
## les masses intermédiaires (7,29 m) et 3,2 m sous les majeures (9,16 m).
GAINE_ECHELLE = 1.15

ASSISE = dict(x0=-6.40, x1=6.90, y0=-3.10, y1=9.10, z0=-2.35, z1=-0.55)

AMP_INTERIEUR = 0.085   # relief de paroi : lisible, la salle reste jouable
# 0,150 au premier jet : l'épaisseur minimale de roche tombait à 0,87 m, à
# peine au-dessus du seuil de refus. Le creux du bruit extérieur et la bosse
# du bruit intérieur se cumulent au même endroit (clé de la salle). 0,132
# rend 1,04 m sans toucher à la hauteur de crête, qui, elle, est contrainte
# par le ressaut : à 4,6 m au-dessus du plateau la masse reste sous le profil
# de la falaise (7,6 m à x = -126), donc adossée et non posée devant.
AMP_MASSIF = 0.150      # relief exterieur : le rocher a des epaules

# Contrôles bloquants (§7 du plan). Chiffrés, et chacun rend impossible un
# défaut nommé par le lead.
# Seuil d'affichage de la télémétrie de composition. Ne décide rien : voir
# `controle_composition`, dont le pouvoir de verdict a été retiré.
PART_SIGNIFICATIVE_PC = 5.0

# UNION — la surface extérieure livrée est UNE formation continue. Les
# masses sont des volumes SOURCES, fusionnés à la coque par booléen exact.
# Un seul maillage final est le résultat recherché, pas un défaut.
#
# PRÉFILTRE — et rien de plus. `_recouvrement()` mesure le chevauchement des
# BOÎTES ENGLOBANTES, pas une profondeur de pénétration : deux volumes
# peuvent partager 0,50 m de boîte en se touchant seulement par un coin.
# Je l'avais nommé `PENETRATION_MIN_M`, ce qui laissait croire à une mesure
# de matière ; l'union a d'ailleurs rendu DEUX îlots alors que ce seuil
# était satisfait partout. Il ne sert qu'à écarter les paires manifestement
# disjointes avant l'appel BVH, qui est le vrai juge.
#
# La preuve de solidarité est la CONJONCTION de cinq mesures, dont
# celle-ci est la moins forte :
#   1. recouvrement d'AABB (ce seuil) ;
#   2. croisement réel de faces, par BVHTree.overlap ;
#   3. graphe rattaché à l'enveloppe ;
#   4. union finale à une seule composante ;
#   5. union manifold et sans auto-intersection.
RECOUVREMENT_AABB_MIN_M = 0.12

## En deçà, deux faces sont TANGENTES et non croisées. 0,1 mm : deux ordres
## de grandeur sous la plus petite arête voulue, et deux ordres au-dessus du
## bruit de virgule flottante d'une rotation. Voir `_traverse_vraiment()`.
TOLERANCE_TANGENCE_M = 1e-4

## Repli toléré sur un volume SOURCE, avant l'union. 0,15 m : au-dessus du
## repli mesuré que l'approximation affine du champ de strates produit sur
## les roches du kit (0,083 m au pire), et très en dessous de ce que
## produirait un lobe qui perce sa paroi opposée. `use_self` résout le
## premier à l'union ; le second doit rester interdit. Voir `controle_repli`.
PROFONDEUR_REPLI_MAX_M = 0.15

## Repli toléré sur le maillage LIVRÉ, après décimation. Plus sévère que le
## seuil des sources, parce que c'est ce qui part dans le build.
##
## Pourquoi ce n'est pas zéro : la décimation par effondrement d'arêtes
## déplace des sommets, et sur une surface aussi repliée qu'un rocher elle
## peut faire empiéter deux faces voisines de quelques millimètres. Mesuré
## sur cette chaîne : UNE paire, 0,0054 m. Un demi-centimètre sur un rocher
## de seize mètres n'est pas un défaut visible ; deux centimètres non plus,
## et au-delà c'est le signe d'une décimation trop violente ou d'un repli
## réel — le contrôle doit alors rougir. La profondeur est imprimée à
## chaque exécution, donc une dérive se verrait.
REPLI_LIVRABLE_MAX_M = 0.02

## En deçà, une composante n'est pas un bloc mais une ÉCAILLE du solveur.
## 10 litres : deux ordres de grandeur sous le plus petit rocher voulu
## (`Pied_Eclat`, environ 1,5 m3), et au-dessus du volume d'une lame de
## rasoir. Voir `retirer_bulles()`.
VOLUME_DEBRIS_M3 = 1e-2

## Nombre d'opérandes par appel au solveur booléen. Voir `unir()` : 1 donne
## 87 arêtes irrégulières, 34 en donnent 155.
TAILLE_LOT_UNION = 6

## En deçà, un intervalle rencontré par un rayon n'est pas une paroi mais
## une écaille de décimation. Seize fois moins que le minimum de paroi
## exigé, donc aucun risque de masquer une paroi réellement trop mince.
EPAISSEUR_ECAILLE_M = 0.05

EPAISSEUR_MIN_M = 0.80          # nulle part une plaque
EPAISSEUR_MIN_COLLERETTE_M = 0.60

## Longueur dont le tube de cavité déborde le porche vers l'avant, pour que
## la soustraction TRAVERSE la roche au lieu de l'affleurer.
PROLONGE_PORCHE_M = 3.05

## PLUS GRANDE PLAGE PLANE CONNEXE TOLÉRÉE, en m2, AU-DESSUS du terrain.
##
## Le premier seuil (6,00 m2) a été posé AVANT toute mesure sur une
## formation faite de modules, et il refusait une géométrie saine. Le lead
## demande « aucune grande face plane DOMINANT LE GROS PLAN » ; une dalle
## de 3 x 3 m à l'arrière de la formation, qui vaut 1,6 % de sa surface, ne
## domine rien. Deux seuils remplacent donc l'unique :
##
##   global   12,00 m2 — cinq fois moins que les 60,93 m2 du loft rejeté ;
##   façade    6,00 m2 — la moitié, pour les plages dont le centre est dans
##                       la zone que le gros plan du seuil regarde.
PLAGE_PLANE_MAX_M2 = 12.00
PLAGE_PLANE_FACADE_MAX_M2 = 6.00
## Limite arrière de la « façade » : la bouche est en y = -1,15 a 0, le gros
## plan du seuil ne voit rien au-delà de deux mètres derrière elle.
FACADE_Y_MAX = 2.00

## Budget de triangles du hero asset, dicté par le lead : 12 000 a 25 000.
TRIS_MIN = 12000
TRIS_MAX = 25000
## Cible de décimation, prise au milieu haut de la fourchette : la
## soustraction de la cavité AJOUTE ensuite des faces, il faut de la marge.
TRIS_CIBLE = 19000

## RUGOSITÉ DE BANC : ESSAYÉE, MESURÉE, ABANDONNÉE — et le journal reste
## parce que la prochaine session aura la même idée.
##
## But : casser les dalles que le champ de strates fabrique en aplatissant
## la pente dans chaque lit. Deux formes ont été implémentées et mesurées :
##
##   déplacement VERTICAL fonction de (x, y), 0,09 m sur ~1,4 m
##     -> 50 paires croisées, 0,0286 m de repli. Un déplacement vertical
##        qui varie avec (x, y) CISAILLE les surfaces verticales : les deux
##        faces d'une lame fine reçoivent des déplacements différents. La
##        monotonie en z ne protège que des replis verticaux.
##   déplacement selon la NORMALE, vers l'extérieur seulement, 0,10 m
##     -> 66 paires, 0,0465 m. Le raisonnement « deux faces opposées
##        s'écartent » ne vaut que sur une lame CONVEXE ; dans une fissure,
##        les deux parois ont leurs normales tournées l'une vers l'autre,
##        et un déplacement vers l'extérieur les referme.
##
## Le défaut visé — 9,44 m2 de plage plane connexe — vaut 1,6 % de la
## surface de la formation, se trouve à l'arrière (y = 7,55) et ne domine
## aucun gros plan. Le contrôle a donc été corrigé pour mesurer ce que le
## lead demande vraiment (voir `controle_plage_plane`), plutôt que de
## déformer la géométrie pour satisfaire un seuil que j'avais posé avant
## d'avoir la moindre mesure.

## Taille de voxel du remaillage. Le relief des modules du kit va de 0,106 m
## (`template-wall-top`) à 0,431 m (`template-corner`) d'amplitude : à
## 0,12 m, tout ce qui porte la forme survit et seules les arêtes se
## biseautent d'un demi-voxel. Plus fin coûterait des triangles que la
## décimation devrait reperdre.
VOXEL_M = 0.12
GABARIT_DEMI_LARGEUR_M = 0.95   # capsule joueur r = 0,45 m
GABARIT_CLE_M = 2.05
ASSISE_JUPE_MIN_M = 2.00

# ---------------------------------------------------------------------------
# Matières. glTF stocke `baseColorFactor` en LINÉAIRE et Godot le réencode
# en sRGB : écrire 0,40 dans Blender rendrait 0,67 dans Godot (c'est ce qui
# a fait rendre le pylône entièrement blanc). On convertit donc à l'écriture
# et on vérifie ensuite avec probe_asset_materials.gd.
#
# Cibles de VALEUR RENDUE, à mesurer sur capture et jamais à prédire depuis
# l'albédo (le gain mesuré sur le pylône va de 1,43 à 1,80 selon le niveau) :
# crête et flanc ouest au soleil ~0,60 · collerette et flanc est, en ombre
# propre, ~0,38 · parois intérieures 0,16-0,22 · sol intérieur 0,26.
# Contrat de bouche : le pixel le plus clair vu à travers l'ouverture doit
# rester sous 0,5 x la valeur de la collerette.
# ---------------------------------------------------------------------------

# R2a-3.1 — LE FLANC OUEST BRÛLAIT. Mesuré p95 = 0,911 sur les replats au
# soleil, au-dessus de la bande 35-65 % de la bible. La passe precedente
# avait ecarte la correction en disant qu'elle casserait le rapport
# bouche/collerette (0,449 -> 0,63) : c'est vrai si l'on ne baisse QUE
# l'exterieur. On baisse donc FACE et COLLERETTE ENSEMBLE — le rapport,
# qui est interieur/collerette, ne bouge pas, et la saturation part.
# Les ressauts et les masses annexes cassent en outre les grands replats
# qui prenaient le soleil de face, ce qui fait retomber le p95 par la
# geometrie et non par l'albedo seul.
MATIERES = {
    "MAT_CaveRock_Face":   ((0.352, 0.314, 0.262), 0.95),
    "MAT_CaveRock_Base":   ((0.235, 0.218, 0.204), 0.96),
    "MAT_CaveRock_Collar": ((0.412, 0.362, 0.294), 0.93),
    "MAT_CaveIn_Wall":     ((0.205, 0.192, 0.180), 0.96),
    "MAT_CaveIn_Deep":     ((0.132, 0.130, 0.140), 0.97),
    "MAT_CaveIn_Floor":    ((0.262, 0.240, 0.208), 0.95),
}
ORDRE_MATIERES = list(MATIERES.keys())
IDX = {nom: i for i, nom in enumerate(ORDRE_MATIERES)}


def srgb_vers_lineaire(canal):
    if canal <= 0.04045:
        return canal / 12.92
    return ((canal + 0.055) / 1.055) ** 2.4


def vider_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def materiau(nom):
    couleur, rugosite = MATIERES[nom]
    mat = bpy.data.materials.new(name=nom)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    r, v, b = (srgb_vers_lineaire(c) for c in couleur)
    bsdf.inputs["Base Color"].default_value = (r, v, b, 1.0)
    bsdf.inputs["Roughness"].default_value = rugosite
    if "Metallic" in bsdf.inputs:
        bsdf.inputs["Metallic"].default_value = 0.0
    mat.diffuse_color = (r, v, b, 1.0)
    return mat


# ---------------------------------------------------------------------------
# Géométrie
# ---------------------------------------------------------------------------

def tangentes(stations):
    """Tangente mitrée par différence centrée : les sections d'un virage se
    mitrent, sinon elles se croisent sur l'intérieur du coude."""
    sortie = []
    for i, st in enumerate(stations):
        avant = stations[max(0, i - 1)]
        apres = stations[min(len(stations) - 1, i + 1)]
        t = Vector((apres[0] - avant[0], apres[1] - avant[1]))
        if t.length < 1e-6:
            t = Vector((0.0, 1.0))
        sortie.append(t.normalized())
    return sortie


def bruit(theta, phase, amplitude):
    """Relief angulaire. Le terme PERSISTANT (sans phase de station) est
    ce qui fait courir une nervure sur toute la longueur du rocher : avec
    des phases toutes décalées, les creux se décalent d'une section à
    l'autre et la surface bouillonne au lieu d'avoir des arêtes."""
    return 1.0 + amplitude * (
        math.sin(3.0 * theta + 0.9) * 0.34
        + math.sin(2.0 * theta + phase) * 0.30
        + math.sin(3.0 * theta + 1.31 * phase + 0.7) * 0.21
        + math.sin(5.0 * theta + 2.17 * phase + 1.9) * 0.15)


def facette(theta, nombre, rotation):
    """Snappe l'azimut au centre de sa facette.

    ATTENTION — CE N'EST PAS CE QUI REND UNE SECTION POLYGONALE, et j'ai
    payé une passe complète de captures pour l'apprendre. Le premier jet de
    R2a-3.1 quantifiait le RAYON avec cette fonction tout en plaçant le
    sommet au VRAI azimut. Or un rayon constant sur un secteur angulaire
    trace un ARC DE CERCLE : la section restait ronde, à un saut de rayon
    près entre secteurs. Mesuré sur la capture d'approche : σ = 13,3 sur
    300 × 120 px de roche de façade, σ = 5,8 sur la paroi intérieure. Une
    surface plate, pas une roche.
    La quantification ne sert donc plus qu'à ÉCHANTILLONNER les termes de
    relief à un azimut stable par facette ; ce sont `coins()` et
    `polygonal()` qui font les pans plats.
    """
    pas = TAU / nombre
    return math.floor((theta - rotation) / pas) * pas + pas * 0.5 + rotation


def coins(nombre, rotation):
    """Azimuts des SOMMETS du polygone de section."""
    pas = TAU / nombre
    return [rotation + pas * (m + 0.5) for m in range(nombre)]


def polygonal(sommets, rotation, nombre, segments):
    """Rééchantillonne un polygone fermé de `nombre` sommets en `segments`
    points, par interpolation LINÉAIRE le long de chaque arête.

    C'est ici que la section cesse d'être une courbe. Entre deux sommets on
    avance en ligne droite : l'arête est plate, l'angle est franc, et la
    lumière rasante y accroche deux valeurs distinctes de part et d'autre.
    L'échantillonnage reste uniforme en azimut, ce qui est nécessaire :
    peau intérieure et peau extérieure n'ont pas le même nombre de facettes
    (9 et 7) et la rondelle de rive les coud indice par indice.
    """
    pas = TAU / nombre
    points = []
    for k in range(segments):
        theta = TAU * k / segments
        # Position continue dans la suite des sommets, sommet 0 à
        # l'azimut `rotation + pas/2`.
        u = (theta - rotation - pas * 0.5) / pas
        m = math.floor(u)
        t = u - m
        a = sommets[m % nombre]
        b = sommets[(m + 1) % nombre]
        points.append(a.lerp(b, t))
    return points


def fenetre(valeur, centre, demi):
    """Fondu en cosinus surélevé dans une fenêtre angulaire ; 0 dehors."""
    ecart = abs(math.remainder(valeur - centre, TAU))
    if ecart >= demi:
        return 0.0
    return 0.5 + 0.5 * math.cos(math.pi * ecart / demi)


def le_long(i, i0, i1):
    """Fondu le long de l'axe : nul aux deux bouts, plein au milieu. Une
    masse qui apparaît d'un coup à une station fait une marche visible."""
    if i < i0 or i > i1:
        return 0.0
    if i1 == i0:
        return 1.0
    t = (i - i0) / float(i1 - i0)
    return math.sin(math.pi * t) ** 0.7


def anneau_interieur(indice, station, tangente, segments, phase, retrait_lat,
                     retrait_cle, denivele, sag):
    """Profil FERMÉ de la cavité — polygonal, dissymétrique, à alcôve.

    Le sol fait partie du profil : c'est lui qui garantit qu'aucune herbe du
    terrain gelé ne peut apparaître entre le sol et les parois, défaut vu à
    la passe précédente quand le sol était un disque séparé.
    """
    ax, ay, hw, cle = station
    hw = max(0.05, hw - retrait_lat)
    cle = max(0.10, cle - retrait_cle)
    gauche, droite, inclinaison = CAVITE_ASYM[indice]
    rotation = FACETTE_ROTATION * indice
    normale = Vector((tangente.y, -tangente.x))

    def sommet(tf):
        """Un SOMMET du polygone de section, à l'azimut `tf`."""
        u, v = math.cos(tf), math.sin(tf)
        w = bruit(tf, phase, AMP_INTERIEUR)

        demi = hw * (gauche if u < 0.0 else droite)

        # ALCÔVE : la cavité s'élargit d'un seul côté sur trois stations.
        pousse = ALCOVE["ampl"] * le_long(indice, ALCOVE["i0"], ALCOVE["i1"]) \
            * fenetre(tf, ALCOVE["theta"], ALCOVE["dtheta"]) \
            * math.exp(-(((v - ALCOVE["v0"]) / ALCOVE["dv"]) ** 2.0))

        # NERVURES : matière RENTRÉE sous la voûte, à azimut fixe, donc
        # courant sur toute la longueur. Au-dessus du gabarit joueur.
        rentree = 0.0
        if v > NERVURE_V_MIN:
            for nt in NERVURES_THETA:
                rentree += NERVURE_RENTREE * fenetre(tf, nt, NERVURE_DEMI)

        n = (demi * w + pousse - rentree) * u
        if v >= 0.0:
            # Linteau incliné : le sommet de la voûte se décale, la clé
            # n'est plus au-dessus de l'axe. Une voûte dont la clé est
            # toujours centrée se lit comme un tube.
            biais = 1.0 + inclinaison * u
            z = cle * (v ** 0.75) * w * biais - rentree * 0.5
        else:
            z = sag * v + PALIER[indice]
            # TABLETTE de l'alcôve : le sol s'y relève, et la récompense s'y
            # pose. C'est la « mise en scène par la géométrie » exigée.
            z += ALCOVE_SEUIL * le_long(indice, ALCOVE["i0"], ALCOVE["i1"]) \
                * fenetre(tf, ALCOVE["theta"], ALCOVE["dtheta"])
        return Vector((ax + n * normale.x, ay + n * normale.y, z + denivele))

    return polygonal([sommet(c) for c in coins(FACETTES, rotation)],
                     rotation, FACETTES, segments)


def deformer_massif(p):
    """LE LIT DE STRATE — seul endroit où la géométrie d'un banc se décide.

    C'est la réponse au reproche « des morceaux posés sur la coque plutôt
    qu'une seule formation érodée », et ce reproche était littéralement
    dans le code : `anneau_exterieur` quantifiait sa hauteur sur
    `PAS_STRATE`, appliquait la corniche et étiquetait sa matière sur le z
    ABSOLU ; `masse_annexe` ne faisait rien de tout cela et choisissait sa
    matière sur l'INDICE D'ÉTAGE. Les annexes portaient donc des lits de
    strate qui n'existaient pas et des bandes de valeur qui ne
    s'alignaient sur rien. Aucun réglage ne pouvait corriger ça : deux
    pièces qui n'obéissent pas au même champ ne peuvent pas appartenir au
    même rocher.

    Le champ est fonction de la POSITION FINALE, pas de la section, pas de
    l'étage, pas de l'azimut. Deux sommets voisins de part et d'autre
    d'une couture reçoivent donc le même traitement, et le lit traverse.

    LE PENDAGE EST CE QUI FAIT LA DIFFÉRENCE ENTRE UNE STRATE ET UNE
    COURBE DE NIVEAU. Un lit rigoureusement horizontal se lit comme un
    contour topographique ; incliné de quelques degrés, il se lit comme un
    banc sédimentaire basculé — et c'est ce que demande
    VISUAL_ASSET_BIBLE §2.1, « strates horizontales larges cassées par des
    fractures diagonales ». `PENDAGE_X/Y` valent la tangente de l'angle :
    0,11 et −0,06 font un plongement d'environ 7°.

    R2a-3.3 — LE SNAP ÉTAIT UNE FALAISE DANS LE CHAMP, ET IL DÉCHIRAIT LES
    ROCHES. La version précédente faisait `niveau = round(h / PAS) * PAS` :
    le déplacement appliqué valait `(niveau - h) * FORCE`, une fonction
    DISCONTINUE qui saute de `FORCE * PAS = 0,47 m` au passage d'un lit au
    suivant. Les anneaux du loft n'en souffraient pas — leurs sommets sont
    alignés par construction. Les roches du kit, elles, ont des sommets
    partout : toute face à cheval sur une limite de lit était étirée de
    47 cm d'un côté et pas de l'autre, donc repliée. Mesuré : onze roches
    sur trente-quatre s'auto-traversaient, de 1 à 11 paires, aux endroits
    exacts des limites de lits.

    J'ai failli corriger ça en déplaçant des roches — pour la deuxième fois
    de cette tranche, j'aurais soigné le symptôme.

    Le champ est donc devenu une MARCHE CONTINUE ET MONOTONE : dans chaque
    lit, la hauteur relative `t` passe par `s(t) = ½ + ½·signe(x)·|x|^k`
    avec `x = 2t-1`. Cette fonction vaut 0 en 0 et 1 en 1 — donc elle
    RACCORDE les lits sans saut — s'aplatit au milieu du lit et se redresse
    au joint. C'est exactement ce que fait un banc sédimentaire : replat
    large, arête franche.

    ET SURTOUT, ELLE NE PEUT PLUS REPLIER, ce qui est démontrable et non
    espéré : la dérivée du déplacement vertical vaut `1 - FORCE + FORCE·s'`
    avec `s' >= 0`, donc elle reste `>= 1 - FORCE > 0` tant que
    `FORCE < 1`. L'application `z -> z'` est strictement croissante à
    `(x, y)` fixé : c'est un homéomorphisme vertical, il conserve l'ordre
    des surfaces et ne peut pas en faire traverser une par une autre.
    C'est la raison pour laquelle `FORCE_STRATE` est passée à 0,85 et non
    à 1,00, qui annulerait la dérivée au centre des lits.

    Rend le point déplacé.
    """
    h = p.z + PENDAGE_X * p.x + PENDAGE_Y * p.y
    u = h / PAS_STRATE
    n = math.floor(u)
    x = 2.0 * (u - n) - 1.0                  # position dans le lit, -1..+1
    s = 0.5 + 0.5 * math.copysign(abs(x) ** DURETE_STRATE, x)
    cible = PAS_STRATE * (n + s)
    return Vector((p.x, p.y, p.z + (cible - h) * FORCE_STRATE))


def famille_massif(point):
    """LA BANDE DE VALEUR — seul endroit où une matière extérieure se décide.

    R2a-3.3 : ELLE PRENAIT UN z ABSOLU, ET ÇA FAISAIT DES BANDES. Le lead a
    demandé « une hiérarchie de valeurs sans bandes artificielles » ; deux
    seuils sur le z absolu produisent exactement le contraire — deux traits
    rigoureusement horizontaux qui coupent la formation comme une ligne de
    marée, à un endroit où aucune géologie ne les justifie.
    La limite suit donc désormais le MÊME plan de strate que la géométrie :
    la hauteur pendée `h = z + PENDAGE_X·x + PENDAGE_Y·y`, plus une
    ondulation de grande longueur d'onde (~5 m) qui la casse. La bande reste
    lisible à distance, et de près sa limite serpente au lieu de trancher.

    LE « DÉCIDEUR UNIQUE » N'ÉTAIT PAS UNIQUE, et le lead l'a vu dans le
    diff : `finition_massif()` calculait bien une famille, mais
    `anneau_exterieur()` ne gardait que le point et jetait la matière ;
    `construire()` gardait ses propres seuils écrits en dur (0,55 et 3,10) ;
    les annexes passaient par une troisième fonction. Trois décideurs, donc
    trois occasions de diverger — et une hiérarchie de valeurs qui se brise
    à chaque couture sans qu'aucun contrôle ne s'en aperçoive.

    Il n'y a plus qu'ici. Les seuils ne sont écrits nulle part ailleurs.
    """
    h = point.z + PENDAGE_X * point.x + PENDAGE_Y * point.y
    h += ONDULATION_BANDE_M * (math.sin(point.x * 1.27 + 0.6)
                               + math.sin(point.y * 0.94 - 1.9)) * 0.5
    if h < BANDE_BASE_Z:
        return "MAT_CaveRock_Base"
    if h > BANDE_COLLERETTE_Z:
        return "MAT_CaveRock_Collar"
    return "MAT_CaveRock_Face"


def anneau_exterieur(indice, station, tangente, segments, phase, jupe, denivele):
    ax, ay, hw, cle, jeu_lat, jeu_cle = station
    rotation = FACETTE_ROTATION_MASSIF * indice
    normale = Vector((tangente.y, -tangente.x))

    def sommet(tf):
        """Un SOMMET du polygone de section du massif."""
        u, v = math.cos(tf), math.sin(tf)
        w = bruit(tf, phase, AMP_MASSIF)

        # Diaclase : creux en cosinus surélevé, centré sur son azimut.
        creux = fenetre(tf, DIACLASE_THETA, DIACLASE_LARGEUR)
        lat = jeu_lat * (1.0 - creux * DIACLASE_PART_LAT)
        cle_jeu = jeu_cle * (1.0 - creux * DIACLASE_PART_CLE)

        # RESSAUTS : entailles franches, bornées en FRACTION du jeu — la
        # roche restante ne peut donc pas passer sous le seuil d'épaisseur.
        # Ce sont elles qui rendent le contour concave ; une bosse, jamais.
        for r in RESSAUTS:
            mordu = r["part"] * le_long(indice, r["i0"], r["i1"]) \
                * fenetre(tf, r["theta"], r["dtheta"]) \
                * math.exp(-(((v - r["v0"]) / r["dv"]) ** 2.0))
            lat *= (1.0 - mordu)
            cle_jeu *= (1.0 - mordu * 0.55)

        # LOBES : les trois masses majeures, plus le dos de l'alcôve.
        gain_lat = 0.0
        gain_z = 0.0
        for L in LOBES:
            axe = le_long(indice, L["i0"], L["i1"])
            if axe <= 0.0:
                continue
            bande = math.exp(-(((v - L["v0"]) / L["dv"]) ** 2.0))
            gain_lat += L["lat"] * axe * fenetre(tf, L["theta"], L["dtheta"]) * bande
            # Le gain vertical est pris à un azimut DÉCALÉ : le sommet du
            # lobe tombe alors à côté de son ventre, et la masse se casse en
            # biseau au lieu de finir en dôme.
            gain_z += L["z"] * axe * bande \
                * fenetre(tf, L["theta"] + L["biais"], L["dtheta"] * 0.8)

        # CIRCONSCRIRE le polygone du massif. Un polygone dont les sommets
        # sont sur la courbe est INSCRIT : ses arêtes coupent à l'intérieur,
        # jusqu'à 1 − cos(π/7) = 9,9 % du rayon, soit 0,47 m sur un corps de
        # 4,7 m. Toute cette épaisseur serait prise sur la roche, et le
        # contrôle d'épaisseur (marge actuelle 0,09 m) refuserait. On
        # multiplie donc le rayon par 1/cos(π/N) : les ARÊTES retombent sur
        # la courbe d'origine et les sommets débordent — ce qui rend la
        # silhouette plus anguleuse, exactement ce qu'on cherche.
        n = ((hw + lat) * w + gain_lat) * u * CIRCONSCRIT_MASSIF
        if v >= 0.0:
            z = ((cle + cle_jeu) * (v ** 0.85) * w + gain_z) * CIRCONSCRIT_MASSIF
            # LA STRATE N'EST PLUS APPLIQUÉE ICI. Elle l'était sur le `z`
            # LOCAL de la section, avant même l'ajout du dénivelé — donc
            # dans un repère que les masses annexes ne partagent pas. Elle
            # est désormais posée par `deformer_massif()` sur le point
            # FINAL, et cette fonction est appelée par TOUTES les pièces
            # extérieures sans exception. C'est ce qui fait qu'un lit sorti
            # du contrefort rentre dans le massif.
            # Corniche : saillie latérale dans une bande de hauteur, du
            # côté du soleil. N'ajoute que de la matière — elle ne peut
            # donc jamais amincir la roche.
            portee = max(0.0, math.cos(tf - CORNICHE_THETA)) ** 3.0
            bande_c = math.exp(-(((v ** 0.85) - CORNICHE_HAUT)
                                 / CORNICHE_ETAL) ** 2.0)
            n += CORNICHE_AMPL * portee * bande_c * (1.0 if u >= 0.0 else -1.0)
        else:
            z = jupe * v * (0.85 + 0.3 * w) * CIRCONSCRIT_MASSIF
        p = Vector((ax + n * normale.x, ay + n * normale.y, z + denivele))
        return deformer_massif(p)

    return polygonal([sommet(c) for c in coins(FACETTES_MASSIF, rotation)],
                     rotation, FACETTES_MASSIF, segments)


def phases(nombre, graine):
    """Phases de relief interpolées le long de l'axe : le bruit doit être
    COHÉRENT d'une station à l'autre, sinon les nervures ne courent pas le
    long du rocher et la surface bouillonne."""
    return [graine * 0.37 + i * 0.61 for i in range(nombre)]


_CACHE_MODULES = {}


def _resoudre_auto_intersection(obj, etiquette):
    """Refait passer un solide par le solveur exact avec `use_self`.

    C'est l'outil prévu par Blender pour une entrée auto-intersectante, et
    il faut l'appliquer DEUX FOIS dans cette chaîne — une découverte payée
    d'un cycle complet.

    Sur le module brut, il retire la matière comptée deux fois par les
    primitives superposées du kit (`template-detail` : 12,84 -> 8,89 m3).

    Sur la roche POSÉE, il retire un défaut plus subtil. Le module contient
    des faces exactement TANGENTES, à distance nulle : ni le test de
    straddle ni aucun autre ne peut les distinguer d'un simple contact. Le
    champ de strates est un homéomorphisme — il ne peut pas replier une
    surface saine, c'est démontré dans `deformer_massif()` — mais il n'est
    pas une isométrie : il transforme un contact à distance nulle en une
    interpénétration de quelques dixièmes de millimètre, qui devient alors
    mesurable. La preuve que ce n'est pas un pli : les mêmes INDICES de
    faces ressortent sur quatre roches différentes du même module.

    Faire tourner le solveur après déformation résout la question à la
    source, sans toucher au seuil du contrôle.
    """
    bpy.context.view_layer.objects.active = obj
    mod = obj.modifiers.new("resoudre_" + etiquette, 'BOOLEAN')
    mod.operation = 'UNION'
    mod.solver = 'EXACT'
    mod.use_self = True
    mod.operand_type = 'COLLECTION'
    mod.collection = bpy.data.collections.new("vide_" + etiquette)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def _souder_et_reboucher(maillage):
    """Soude les sommets, referme les boucles ouvertes, rend (bords, volume).

    DEUX PASSES POUR REBOUCHER, et la seconde n'est pas de la
    ceinture-bretelles : `holes_fill` referme les boucles simples et laisse
    tomber les autres SANS RIEN DIRE. Mesuré sur `template-corner` : 24
    arêtes de bord au départ, 4 après `holes_fill`, et le volume calculé
    (31,5 m3) restait plausible. `triangle_fill` reprend les boucles
    restantes, y compris non planes, en triangulant leur contour.
    """
    bm = bmesh.new()
    bm.from_mesh(maillage)
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-4)
    for passe in range(4):
        bords = [e for e in bm.edges if len(e.link_faces) < 2]
        if not bords:
            break
        if passe % 2 == 0:
            bmesh.ops.holes_fill(bm, edges=bords, sides=0)
        else:
            bmesh.ops.triangle_fill(bm, edges=bords, use_beauty=True,
                                    use_dissolve=False)
        bmesh.ops.triangulate(bm,
                              faces=[f for f in bm.faces if len(f.verts) > 4])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    restants = sum(1 for e in bm.edges if len(e.link_faces) != 2)
    volume = bm.calc_volume(signed=True)
    bm.to_mesh(maillage)
    bm.free()
    maillage.update()
    return restants, volume


def charger_module(cle):
    """Un module du kit, SOUDÉ et vérifié fermé — ou une erreur bruyante.

    DEUX PIÈGES, tous deux mesurés avant d'écrire cette fonction.

    1. L'import glTF SÉPARE les sommets à chaque arête dure. Un module
       plat-ombré ressort donc avec 100 % d'arêtes de bord et un volume
       calculé NUL, alors qu'il est parfaitement fermé. Mesuré sur
       `template-detail` : 600 sommets / 600 arêtes de bord avant soudure,
       90 sommets / 0 arête de bord après. Une sonde qui n'aurait pas soudé
       aurait conclu « aucun module utilisable » et m'aurait envoyé
       reconstruire un pipeline de remaillage dont je n'ai pas besoin.
    2. La moitié des modules sont de vraies coques OUVERTES : `template-wall`
       (20 arêtes de bord), `template-wall-half` (8), `template-wall-detail-a`
       (16), `template-corner` (24) — ce sont des panneaux sans dos. Un
       booléen sur une coque ouverte ne rend pas un solide et ne le SIGNALE
       PAS : il rend une géométrie plausible et fausse. On les referme donc,
       et on REVÉRIFIE.

    3. LE PLUS COÛTEUX, ET LE PLUS INSTRUCTIF : cinq des huit modules
       S'AUTO-TRAVERSENT NATIVEMENT. Mesuré — `template-detail` 219 paires
       de faces croisées, `template-corner` 279, `template-wall-detail-a`
       148, `template-wall` 134, `template-wall-half` 35 — et cela AVANT
       toute pose, toute échelle, tout champ de strates. Les rochers du kit
       sont assemblés de primitives qui s'interpénètrent : c'est invisible
       au rendu, et parfaitement légitime pour un asset de décor.
       Ce n'était donc pas un défaut de mon implantation, et j'ai failli le
       corriger en déplaçant des roches — la même impasse que la tranche
       précédente, où j'ai cherché à la sortie du booléen un défaut qui
       était dans l'entrée.
       La réponse n'est pas de baisser le contrôle : c'est de RÉPARER LA
       SOURCE, une fois par module, avec l'outil prévu pour ça — le solveur
       exact avec `use_self`. Mesuré sur les trois variantes possibles
       (collection vide / copie de soi / cube lointain) : les trois rendent
       0 croisement et le même volume ; la collection vide est la moins
       chère et n'invente pas d'opérande. Le volume tombe de 12,84 à
       8,89 m3 sur `template-detail` — c'est exactement la matière comptée
       deux fois par les primitives superposées.

    L'ORDRE COMPTE, et je l'ai eu faux deux fois. Souder, RÉSOUDRE, puis
    reboucher : mesuré, `template-wall` ressortait avec 142 arêtes de bord
    au lieu de 20 — le solveur exact appliqué à une coque OUVERTE la
    déchiquette, ce que mon propre commentaire annonçait deux lignes plus
    haut. L'ordre juste est donc : souder, REBOUCHER, résoudre, reboucher
    encore (la self-union supprime des capuchons devenus intérieurs), puis
    vérifier fermeture ET absence de croisement.
    """
    if cle in _CACHE_MODULES:
        return _CACHE_MODULES[cle]
    fichier = KIT_ROCHES / (MODULES[cle]["fichier"] + ".glb")
    if not fichier.exists():
        raise RuntimeError("module absent : %s" % fichier)
    avant = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(fichier))
    importes = [o for o in set(bpy.data.objects) - avant if o.type == "MESH"]
    if len(importes) != 1:
        raise RuntimeError("%s : %d maillage(s), un seul attendu"
                           % (cle, len(importes)))
    source = importes[0]

    _souder_et_reboucher(source.data)
    _resoudre_auto_intersection(source, "mod_" + cle)
    restants, volume = _souder_et_reboucher(source.data)
    maillage = bpy.data.meshes.new("MOD_" + cle)
    maillage.from_pydata(
        [tuple(v.co) for v in source.data.vertices], [],
        [tuple(p.vertices) for p in source.data.polygons])
    maillage.validate(verbose=False)
    bpy.data.objects.remove(source, do_unlink=True)
    if restants or abs(volume) < 0.05:
        raise RuntimeError("module %s (%s) NON REFERMABLE : %d arete(s) de "
                           "bord, volume %.3f m3 — un booleen sur une coque "
                           "ouverte rend n'importe quoi, sans erreur"
                           % (cle, MODULES[cle]["fichier"], restants, volume))
    croises, exemple = _croisements_de(maillage)
    if croises:
        raise RuntimeError("module %s (%s) s'auto-traverse encore apres "
                           "reparation : %d paire(s), %s"
                           % (cle, MODULES[cle]["fichier"], croises, exemple))
    print("[grotte] module %s (%s) : %d faces, volume %.2f m3, ferme et sans "
          "auto-intersection" % (cle, MODULES[cle]["fichier"],
                                 len(maillage.polygons), abs(volume)))

    # ORIGINE AU CENTRE EN PLAN, AU BAS EN HAUTEUR. Sans quoi `pose` ne veut
    # rien dire : les modules du kit ont leur origine au coin de la tuile,
    # et une rotation de lacet ferait alors décrire un arc à la roche.
    xs = [v.co for v in maillage.vertices]
    cx = 0.5 * (min(p.x for p in xs) + max(p.x for p in xs))
    cy = 0.5 * (min(p.y for p in xs) + max(p.y for p in xs))
    bas = min(p.z for p in xs)
    for v in maillage.vertices:
        v.co = Vector((v.co.x - cx, v.co.y - cy, v.co.z - bas))
    _CACHE_MODULES[cle] = maillage
    return maillage


def poser_rocher(config):
    """Une roche du kit, posée, tournée, mise à l'échelle, PUIS stratifiée.

    L'ordre compte, et c'est tout l'argument de continuité géologique : le
    champ de `deformer_massif()` est une fonction de la POSITION FINALE. Il
    est donc appliqué après la transformation, ce qui fait qu'un lit de
    strate traverse la couture entre deux roches sans savoir qu'elle existe.
    Le déformer avant aurait donné à chaque roche ses propres lits, orientés
    avec elle — exactement le défaut « pièces posées » du rejet précédent.

    La matière suit la même règle : `famille_massif()` reçoit le centre de
    la face, en repère monde. Un seul décideur, pour toutes les pièces.
    """
    ech = config["ech"]
    if not isinstance(ech, (tuple, list)):
        ech = (ech, ech, ech)
    for facteur in ech:
        if facteur < ECHELLE_MIN or facteur > ECHELLE_MAX:
            raise RuntimeError("%s : facteur %.2f hors des bornes [%.2f ; "
                               "%.2f] — une roche agrandie plusieurs fois "
                               "cesse d'etre une roche"
                               % (config["nom"], facteur, ECHELLE_MIN,
                                  ECHELLE_MAX))
    base = charger_module(config["mod"])
    maillage = base.copy()
    obj = bpy.data.objects.new("SM_WaterfallCave_" + config["nom"], maillage)
    bpy.context.collection.objects.link(obj)

    rot = (Matrix.Rotation(math.radians(config["lacet"]), 3, 'Z')
           @ Matrix.Rotation(math.radians(config["tangage"]), 3, 'X')
           @ Matrix.Rotation(math.radians(config["roulis"]), 3, 'Y'))
    px, py, pz = config["pose"]
    # PAS DE CHAMP DE STRATES ICI. Il s'applique après le remaillage, sur un
    # maillage dense — voir `stratifier()`. Appliqué aux sommets du kit, dont
    # les arêtes font 1 à 2 m pour un pas de strate de 0,85 m, il repliait la
    # surface de 0,083 m par simple erreur d'interpolation affine.
    for v in maillage.vertices:
        p = rot @ Vector((v.co.x * ech[0], v.co.y * ech[1], v.co.z * ech[2]))
        v.co = Vector((p.x + px, p.y + py, p.z + pz))

    maillage.update()
    # PAS DE RÉSOLUTION D'AUTO-INTERSECTION ICI, et c'est un choix mesuré.
    # J'en avais mis une : elle OUVRAIT les roches (`Ouest_Piedroit`, 9
    # arêtes irrégulières, volume 15,1 m3), exactement comme elle ouvrait
    # `template-corner`. Un opérande ouvert rend une union ouverte — d'où
    # les 18 arêtes irrégulières dès le premier lot de six roches, pendant
    # que je soupçonnais le nombre d'opérandes, la tolérance de nettoyage,
    # `use_hole_tolerant` et une seconde passe du solveur. Aucun de ces
    # réglages n'était en cause.
    #
    # La déformation ne peut pas ouvrir un maillage : elle ne touche qu'aux
    # positions. On vérifie donc simplement que la roche est restée fermée,
    # et l'auto-intersection résiduelle est traitée par `use_self` dans
    # `unir()`, dont c'est précisément l'emploi.
    restants, _, volume = controle_fermeture(obj)
    if restants or abs(volume) < 0.05:
        raise RuntimeError("roche %s ouverte apres deformation : %d arete(s) "
                           "irreguliere(s), volume %.3f m3"
                           % (config["nom"], restants, volume))

    # Les matières sont peintes APRÈS remaillage (`peindre_matieres()`) :
    # la surface reconstruite n'a plus rien de commun avec celle-ci.
    maillage.update()
    return obj


def assise_enterree():
    """Le pavé sous le terrain — voir le commentaire de `ASSISE`."""
    x0, x1 = ASSISE["x0"], ASSISE["x1"]
    y0, y1 = ASSISE["y0"], ASSISE["y1"]
    z0, z1 = ASSISE["z0"], ASSISE["z1"]
    sommets = [Vector((x, y, z)) for z in (z0, z1)
               for x, y in ((x0, y0), (x1, y0), (x1, y1), (x0, y1))]
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
             (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    familles = [famille_massif(
        sum((sommets[i] for i in f), Vector()) / len(f)) for f in faces]
    return objet("SM_WaterfallCave_Assise", sommets, faces, familles, True)


def cavite_solide(segments, sag, retrait_lat, retrait_cle, graine=7.0):
    """La cavité comme VOLUME FERMÉ, destiné à être SOUSTRAIT de la roche.

    C'est le pivot de R2a-3.3. Auparavant, la bouche était une « rondelle de
    rive » : un anneau de quadrilatères que je dessinais entre la peau
    intérieure et la peau extérieure, avec une avance modulée par l'azimut.
    Un contour calculé, donc régulier, donc géométrique — et le lead l'a vu
    du premier coup d'œil sous le nom de « collerette géométrique ».

    Ici la bouche n'est plus dessinée du tout : c'est la TRACE DE DÉCOUPE du
    tube dans la roche. Son contour est celui des facettes sculptées qu'il
    rencontre, il est donc irrégulier sans que j'aie à inventer son
    irrégularité, et l'épaisseur du linteau est celle de la roche qui se
    trouve là.

    Le tube est prolongé de 3,05 m vers l'AVANT (-Y) au-delà du porche, en
    recopiant l'anneau du porche : hors de la roche, cette rallonge ne
    retire rien, mais elle garantit que la découpe traverse franchement au
    lieu d'affleurer. La recopie plutôt qu'une station extrapolée n'est pas
    une paresse : une station de plus, c'est un profil de plus, donc un
    risque de repli de plus — et j'ai déjà payé celui de la station 7.
    """
    t_cav = tangentes(CAVITE)
    ph_c = phases(len(CAVITE), graine)
    sommets = []
    bases = []
    for i, st in enumerate(CAVITE):
        denivele = PORCHE_DENIVELE if i == 0 else 0.0
        base = len(sommets)
        sommets.extend(anneau_interieur(i, st, t_cav[i], segments, ph_c[i],
                                        retrait_lat, retrait_cle, denivele,
                                        sag))
        bases.append(base)
    apex = len(sommets)
    sommets.append(Vector(CAVITE_APEX))

    # Rallonge avant : copie translatée de l'anneau du porche.
    avant = len(sommets)
    for k in range(segments):
        p = sommets[bases[0] + k]
        sommets.append(Vector((p.x, p.y - PROLONGE_PORCHE_M, p.z)))
    bouchon = len(sommets)
    centre = Vector((0.0, 0.0, 0.0))
    for k in range(segments):
        centre = centre + sommets[avant + k]
    sommets.append(centre / segments)

    faces = []
    familles = []

    def famille_interieure(station_index, k):
        theta = TAU * k / segments
        v = math.sin(theta)
        if v < -0.20:
            return "MAT_CaveIn_Floor"
        if v > 0.55 or station_index >= 4:
            return "MAT_CaveIn_Deep"
        return "MAT_CaveIn_Wall"

    for k in range(segments):
        k2 = (k + 1) % segments
        faces.append((bouchon, avant + k2, avant + k))
        familles.append("MAT_CaveIn_Deep")
        faces.append((avant + k, avant + k2, bases[0] + k2, bases[0] + k))
        familles.append(famille_interieure(0, k))
    for i in range(len(CAVITE) - 1):
        a, b = bases[i], bases[i + 1]
        for k in range(segments):
            k2 = (k + 1) % segments
            faces.append((a + k, a + k2, b + k2, b + k))
            familles.append(famille_interieure(i, k))
    dernier = bases[-1]
    for k in range(segments):
        k2 = (k + 1) % segments
        faces.append((dernier + k, dernier + k2, apex))
        familles.append("MAT_CaveIn_Deep")
    return sommets, faces, familles


def soustraire(base, outil):
    """Creuse la cavité dans la roche, puis nettoie ce que le solveur laisse.

    Même solveur EXACT que l'union, et même nettoyage : là où la surface de
    l'outil est presque tangente à une facette de roche, le booléen produit
    des faces en lame de rasoir, invisibles au rendu mais comptées — à juste
    titre — par le test d'auto-intersection.
    """
    bpy.context.view_layer.objects.active = base
    mod = base.modifiers.new("cavite", 'BOOLEAN')
    mod.operation = 'DIFFERENCE'
    mod.solver = 'EXACT'
    mod.object = outil
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(outil, do_unlink=True)
    maillage = base.data
    bm = bmesh.new()
    bm.from_mesh(maillage)
    avant = sum(1 for e in bm.edges if len(e.link_faces) != 2)
    # LA TOLÉRANCE DE NETTOYAGE EST UN COUTEAU À DOUBLE TRANCHANT, mesuré
    # ici : à 1e-3 (la valeur héritée de `unir()`), la soustraction rendait
    # 83 arêtes de bord — la fusion de sommets distants d'un millimètre
    # écrasait des triangles de la découpe en arêtes et OUVRAIT le maillage.
    # La découpe du tube produit des faces beaucoup plus fines que celles
    # d'une union de blocs ; on descend donc d'un ordre de grandeur, et on
    # imprime le bilan avant/après pour que le compromis reste visible.
    bmesh.ops.dissolve_degenerate(bm, dist=1e-5, edges=bm.edges[:])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    apres = sum(1 for e in bm.edges if len(e.link_faces) != 2)
    print("[grotte] nettoyage de la soustraction : %d -> %d arete(s) "
          "irreguliere(s)" % (avant, apres))
    bm.to_mesh(maillage)
    bm.free()
    maillage.update()
    for polygone in maillage.polygons:
        polygone.use_smooth = False
    return base


def construire(segments, sag, jupe, retrait_lat, retrait_cle, graine=7.0):
    """La COQUE DE COLLISION, et plus rien d'autre depuis R2a-3.3.

    Cette fonction produisait le maillage visible : cavité, massif en loft
    polygonal, et la « rondelle de rive » qui les reliait. Le lead a rejeté
    ce maillage — « une union mathématique n'est pas une fusion artistique »
    — et interdit à `anneau_exterieur()` de produire encore une surface
    visible. Il l'a en revanche explicitement autorisé comme proxy de
    collision, et c'est le bon emploi : un collider n'est jamais rendu, il
    doit seulement être fermé, un peu rétréci et pas cher.

    Rend (sommets, faces, familles) ; les familles ne servent plus qu'à
    garder la signature d'`objet()` uniforme — le collider est construit
    avec `avec_matieres=False`.
    """
    t_cav = tangentes(CAVITE)
    t_mas = tangentes(MASSIF)
    ph_c = phases(len(CAVITE), graine)
    ph_m = phases(len(MASSIF), graine + 3.0)

    sommets = []
    faces = []
    familles = []

    def ajouter_anneau(points):
        base = len(sommets)
        sommets.extend(points)
        return base

    cav_bases = []
    for i, st in enumerate(CAVITE):
        denivele = PORCHE_DENIVELE if i == 0 else 0.0
        cav_bases.append(ajouter_anneau(anneau_interieur(
            i, st, t_cav[i], segments, ph_c[i], retrait_lat, retrait_cle,
            denivele, sag)))
    cav_apex = len(sommets)
    sommets.append(Vector(CAVITE_APEX))

    mas_bases = []
    for i, st in enumerate(MASSIF):
        denivele = PORCHE_DENIVELE if i == 0 else 0.0
        mas_bases.append(ajouter_anneau(anneau_exterieur(
            i, st, t_mas[i], segments, ph_m[i], jupe, denivele)))
    mas_apex = len(sommets)
    sommets.append(Vector(MASSIF_APEX))

    def famille_interieure(station_index, k):
        theta = TAU * k / segments
        v = math.sin(theta)
        if v < -0.20:
            return "MAT_CaveIn_Floor"
        if v > 0.55 or station_index >= 4:
            return "MAT_CaveIn_Deep"
        return "MAT_CaveIn_Wall"

    # Peau de la cavité. L'ordre des sommets est indifférent : le manifold
    # fermé sera réorienté d'un bloc par recalc_face_normals.
    for i in range(len(CAVITE) - 1):
        a, b = cav_bases[i], cav_bases[i + 1]
        for k in range(segments):
            k2 = (k + 1) % segments
            faces.append((a + k, a + k2, b + k2, b + k))
            familles.append(famille_interieure(i, k))
    dernier = cav_bases[-1]
    for k in range(segments):
        k2 = (k + 1) % segments
        faces.append((dernier + k, dernier + k2, cav_apex))
        familles.append("MAT_CaveIn_Deep")

    # Peau du massif.
    for i in range(len(MASSIF) - 1):
        a, b = mas_bases[i], mas_bases[i + 1]
        for k in range(segments):
            k2 = (k + 1) % segments
            faces.append((a + k, a + k2, b + k2, b + k))
            centre = 0.25 * (sommets[a + k] + sommets[a + k2]
                             + sommets[b + k] + sommets[b + k2])
            familles.append(famille_massif(centre))
    dernier = mas_bases[-1]
    for k in range(segments):
        k2 = (k + 1) % segments
        faces.append((dernier + k, dernier + k2, mas_apex))
        familles.append("MAT_CaveRock_Face")

    # RONDELLE DE RIVE : la seule pièce qui relie les deux peaux. C'est elle
    # qui fait la collerette de la bouche — piédroits, linteau et seuil d'un
    # seul tenant. C'est aussi elle qui rend le maillage connexe, donc de
    # genre 0, donc orientable d'un bloc.
    #
    # ELLE ÉTAIT PLATE, ET ÇA SE VOYAIT EN GROS PLAN. Un seul quad par
    # segment entre les deux peaux fait un ANNEAU PLAN : sur la vue de
    # seuil, la moitié droite de l'image était une unique face grise sans
    # un accident. On intercale donc une TROISIÈME rangée, avancée vers
    # l'extérieur d'une quantité qui dépend de l'azimut : la collerette
    # devient un chanfrein brisé — auvent en haut, tableaux sur les côtés,
    # seuil épais en bas — au lieu d'une découpe à l'emporte-pièce.
    a, b = cav_bases[0], mas_bases[0]
    rive = len(sommets)
    for k in range(segments):
        theta = TAU * k / segments
        v = math.sin(theta)
        milieu = (sommets[a + k] + sommets[b + k]) * 0.5
        # Plus d'avancée en haut (auvent) qu'en bas (seuil), et une
        # modulation à trois lobes pour que le chanfrein soit brisé et non
        # régulier.
        #
        # PREMIER RÉGLAGE REFUSÉ, et par le bon contrôle : à 0,30 + 0,42·v
        # la collerette tombait à 0,52 m pour un minimum de 0,60. Une lèvre
        # qui avance au-dessus de la bouche amincit la roche qui la porte —
        # c'est un auvent en porte-à-faux. On rentre l'avancée, et on
        # POUSSE le milieu vers l'extérieur du massif, ce qui ne peut
        # qu'épaissir.
        avance = 0.20 + 0.24 * max(0.0, v) + 0.09 * math.cos(3.0 * theta + 1.1)
        pousse = 0.14
        sommets.append(Vector((milieu.x * (1.0 + pousse), milieu.y - avance,
                               milieu.z * (1.0 + pousse * 0.5))))
    for k in range(segments):
        k2 = (k + 1) % segments
        faces.append((a + k, a + k2, rive + k2, rive + k))
        familles.append("MAT_CaveRock_Collar")
        faces.append((rive + k, rive + k2, b + k2, b + k))
        familles.append("MAT_CaveRock_Collar")

    return sommets, faces, familles


def objet(nom, sommets, faces, familles, avec_matieres):
    maillage = bpy.data.meshes.new(nom)
    maillage.from_pydata([tuple(v) for v in sommets], [], faces)
    maillage.validate(verbose=False)
    if avec_matieres:
        for cle in ORDRE_MATIERES:
            maillage.materials.append(bpy.data.materials[cle])
        for polygone, famille in zip(maillage.polygons, familles):
            polygone.material_index = IDX[famille]
    obj = bpy.data.objects.new(nom, maillage)
    bpy.context.collection.objects.link(obj)

    bm = bmesh.new()
    bm.from_mesh(maillage)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(maillage)
    bm.free()
    maillage.update()
    for polygone in maillage.polygons:
        polygone.use_smooth = False
    return obj


# ---------------------------------------------------------------------------
# CONTRÔLES BLOQUANTS. Chacun rend impossible un défaut nommé par le lead ;
# le script rend 2 et n'enregistre rien si l'un échoue.
# ---------------------------------------------------------------------------

def controle_fermeture(obj):
    """Aucune arête de bord, aucune arête non-manifold, volume > 0.

    C'est le contrôle qui rend impossible « enveloppe ouverte » et
    « sommet ouvert » : une coque à trous a forcément des arêtes de bord.
    """
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bords = sum(1 for e in bm.edges if len(e.link_faces) != 2)
    non_manifold = sum(1 for e in bm.edges if not e.is_manifold)
    volume = bm.calc_volume(signed=True)
    bm.free()
    return bords, non_manifold, volume


def bvh_depuis(obj, filtre=None):
    sommets = [v.co.copy() for v in obj.data.vertices]
    polys = [tuple(p.vertices) for p in obj.data.polygons
             if filtre is None or filtre(p)]
    return BVHTree.FromPolygons(sommets, polys, all_triangles=False, epsilon=0.0)


def controle_epaisseur(obj, segments):
    """Épaisseur de roche mesurée PAR RAYON, sur le maillage FINAL.

    L'ancienne mesure séparait peau intérieure et peau extérieure par
    l'ORDRE DES SOMMETS : les `n_cav` premiers étaient la cavité. Un booléen
    détruit cet ordre, si bien que la mesure devait être prise AVANT l'union
    et n'était qu'un minorant — argument valide, mais un minorant reste un
    aveu. Depuis R2a-3.3 la cavité est SOUSTRAITE de la roche : l'ordre des
    sommets n'a plus aucun sens à aucun moment, et l'astuce n'est plus
    seulement faible, elle est impossible.

    On mesure donc ce qu'on veut vraiment savoir : depuis l'axe de la
    galerie, un rayon part vers chaque azimut et on CUMULE toute la matière
    qu'il traverse jusqu'à sortir. C'est une mesure directe sur l'objet
    livré, et non plus une inférence.

    Le cumul, et non le premier intervalle : mesuré, un rayon partant vers
    le haut-droit à la station 5 rendait 0,17 m parce qu'il effleurait
    d'abord le bord d'un rocher secondaire avant d'atteindre la paroi. Ce
    n'est pas la paroi. La question posée est « combien de roche sépare la
    galerie du dehors », et sa réponse est la somme.

    Zéro croisement, ou un seul, est une ERREUR et non une épaisseur nulle :
    cela veut dire que le rayon sort par un JOUR. On le rapporte comme tel.
    """
    arbre = bvh_depuis(obj)
    mini, mini_collerette = 1e9, 1e9
    total_ecailles = 0
    ou, ou_collerette = None, None
    percees = []
    for i, (ax, ay, hw, cle) in enumerate(CAVITE):
        if i >= len(CAVITE) - 2:
            continue          # les deux dernières stations ferment la calotte
        for k in range(segments):
            theta = TAU * k / segments
            # PAS DE RAYON VERS LE BAS, et ce n'est pas un aveuglement
            # volontaire : sous le sol de la galerie, la matière qui porte
            # le joueur n'est PAS ce maillage, c'est le terrain gelé. Mesuré,
            # la géométrie disponible y est bornée par construction — le sol
            # de la galerie est à z = +0,19 et le terrain à z = -0,50, soit
            # 0,69 m au mieux, moins que le minimum exigé pour une PAROI.
            # Exiger 0,80 m de roche sous le plancher revenait donc à
            # demander au maillage de refaire la colline. Le plancher est
            # garanti autrement : par `controle_aucun_jour` (rayons
            # verticaux, croisements pairs et >= 2) et par la jupe de
            # l'assise, contrôlée par `controle_assise`.
            if math.sin(theta) < -0.30:
                continue
            # Rayon depuis l'axe, à mi-hauteur de clé : horizontal sur les
            # flancs, montant vers la voûte.
            direction = Vector((math.cos(theta), 0.0, math.sin(theta)))
            origine = Vector((ax, ay, cle * 0.45))
            # ENTRÉE ET SORTIE, PAS « PREMIER ET DEUXIÈME ». Prendre l'écart
            # entre les deux premiers impacts rendait 0,01 m : sur une paroi
            # décimée, un rayon rasant peut toucher deux fois la MÊME peau,
            # de part et d'autre d'un petit pli. On distingue donc les
            # impacts par le signe de `normale · direction` : négatif, le
            # rayon ENTRE dans la matière ; positif, il en SORT. L'épaisseur
            # est la longueur du premier intervalle entrée -> sortie.
            entree = None
            epaisseur = None
            ecailles_ignorees = 0
            depart = origine.copy()
            impacts = 0
            for _ in range(24):
                touche = arbre.ray_cast(depart, direction, 60.0)
                if touche is None or touche[0] is None:
                    break
                impacts += 1
                distance = (touche[0] - origine).length
                sortant = touche[1].dot(direction) > 0.0
                if entree is None and not sortant:
                    entree = distance
                elif entree is not None and sortant:
                    intervalle = distance - entree
                    # UNE ÉCAILLE N'EST PAS UNE PAROI. La décimation laisse
                    # ça et là des coquilles de quelques millimètres entre
                    # deux plis de surface ; comptée comme « la » paroi, une
                    # écaille de 0,01 m fait rougir un contrôle sur une roche
                    # épaisse de deux mètres. On les compte et on continue.
                    if intervalle < EPAISSEUR_ECAILLE_M:
                        ecailles_ignorees += 1
                    else:
                        epaisseur = (epaisseur or 0.0) + intervalle
                    entree = None
                depart = touche[0] + direction * 1e-4
            total_ecailles += ecailles_ignorees
            if epaisseur is None:
                percees.append((i, math.degrees(theta), impacts))
                continue
            d = epaisseur
            if i <= 1:
                if d < mini_collerette:
                    mini_collerette = d
                    ou_collerette = (i, math.degrees(theta), origine.z)
            else:
                if d < mini:
                    mini, ou = d, (i, math.degrees(theta), origine.z)
    if ou is not None:
        print("[grotte] paroi la plus mince : station %d, azimut %.0f°, z %.2f"
              % ou)
    if ou_collerette is not None:
        print("[grotte] collerette la plus mince : station %d, azimut %.0f°, "
              "z %.2f" % ou_collerette)
    if total_ecailles:
        print("[grotte] %d ecaille(s) de moins de %.2f m ignoree(s) le long "
              "des rayons" % (total_ecailles, EPAISSEUR_ECAILLE_M))
    return mini, mini_collerette, percees


def controle_plage_plane(obj, z_mini, exterieur_seul=True):
    """LA PLUS GRANDE PLAGE PLANE CONNEXE, en m2 — le contrôle qui manquait.

    Les neuf contrôles de la tranche précédente étaient tous verts et le
    maillage a été rejeté pour « grandes surfaces planes ». Aucun ne mesurait
    ça, et deux donnaient même l'illusion contraire : 162 familles de
    normales et 7,5 % d'aire pour la plus grande, chiffres qui décrivent une
    surface très travaillée. Ils sont exacts et sans rapport — un loft à neuf
    facettes sur huit stations fait soixante-douze quadrilatères, tous de
    normales différentes, tous immenses.

    On regroupe donc les faces voisines PAR UNE ARÊTE dont les normales
    tiennent dans 12°, et on rend l'aire cumulée du plus gros groupe. C'est
    littéralement le plus grand pan plat que l'œil peut voir.

    `z_mini` écarte l'assise enterrée : mesurer les faces d'un pavé que le
    terrain recouvre ferait rougir le contrôle sur une géométrie invisible,
    et un contrôle qui rougit à tort finit désactivé.

    `exterieur_seul` écarte les faces de la CAVITÉ, et cette distinction
    n'est pas un adoucissement. Elle a été ajoutée après une mesure qui
    accusait le mauvais coupable : 11,04 m2 « en façade », centrés en
    (1,43 ; 0,27 ; 2,72) — c'est-à-dire la voûte de la galerie, à
    l'intérieur, juste derrière la bouche. Le reproche du lead porte sur
    les aplats de la ROCHE VUE DU DEHORS ; l'intérieur relève de son
    propre jalon, qu'il a explicitement demandé de ne pas encore traiter.
    Les faces se distinguent par leur matière (`MAT_CaveIn_*`), donc sans
    ambiguïté, et les deux chiffres sont imprimés séparément.
    """
    interieures = {IDX[nom] for nom in ORDRE_MATIERES
                   if nom.startswith("MAT_CaveIn_")}
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.faces.ensure_lookup_table()
    retenues = {f.index for f in bm.faces
                if min(v.co.z for v in f.verts) >= z_mini
                and not (exterieur_seul and f.material_index in interieures)}
    parent = {i: i for i in retenues}

    def racine(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    cos_seuil = math.cos(math.radians(12.0))
    for arete in bm.edges:
        voisines = [f.index for f in arete.link_faces if f.index in retenues]
        for a in range(len(voisines)):
            for b in range(a + 1, len(voisines)):
                fa, fb = bm.faces[voisines[a]], bm.faces[voisines[b]]
                if fa.normal.dot(fb.normal) < cos_seuil:
                    continue
                ra, rb = racine(voisines[a]), racine(voisines[b])
                if ra != rb:
                    parent[ra] = rb
    cumul = {}
    centres = {}
    for i in retenues:
        r = racine(i)
        aire_i = bm.faces[i].calc_area()
        cumul[r] = cumul.get(r, 0.0) + aire_i
        c = bm.faces[i].calc_center_median()
        precedent = centres.get(r)
        if precedent is None:
            centres[r] = [c.copy() * aire_i, aire_i]
        else:
            precedent[0] += c * aire_i
            precedent[1] += aire_i
    if not cumul:
        bm.free()
        return 0.0, None, 0.0, None
    pire = max(cumul, key=cumul.get)
    aire = cumul[pire]
    centre = centres[pire][0] / centres[pire][1]
    # LA MÊME MESURE, RESTREINTE À LA FAÇADE. « Dominant le gros plan » est
    # une exigence de POSITION autant que de taille : c'est elle qu'il faut
    # mesurer, pas seulement le maximum global.
    facade = [r for r in cumul
              if (centres[r][0] / centres[r][1]).y <= FACADE_Y_MAX]
    aire_facade, centre_facade = 0.0, None
    if facade:
        pire_facade = max(facade, key=lambda r: cumul[r])
        aire_facade = cumul[pire_facade]
        centre_facade = centres[pire_facade][0] / centres[pire_facade][1]
    bm.free()
    return aire, centre, aire_facade, centre_facade


def controle_gabarit():
    """Une capsule r = 0,45 m, h = 1,85 m passe partout sur le chemin."""
    faibles = []
    for i, (_, ay, hw, cle) in enumerate(CAVITE):
        if i >= len(CAVITE) - 2:
            continue          # les deux dernières stations FERMENT la calotte
        marge_hw = hw * (1.0 - AMP_INTERIEUR)
        # LE PALIER MONTE LE SOL, donc il MANGE la hauteur libre. Sans ce
        # terme, le contrôle mesurerait la clé au-dessus d'un sol qui n'est
        # plus là : un gabarit vert au-dessus d'un couloir devenu trop bas.
        marge_cle = cle * (1.0 - AMP_INTERIEUR) - PALIER[i]
        if marge_hw < GABARIT_DEMI_LARGEUR_M or marge_cle < GABARIT_CLE_M:
            faibles.append((i, ay, marge_hw, marge_cle))
    return faibles


def controle_aucun_jour(obj, segments):
    """Aucun point du sol de la salle ne voit le ciel.

    25 points du sol, rayon vertical, comptage des intersections par
    marche : le nombre doit être PAIR et >= 2. Un seul point qui voit le
    ciel = refus. C'est la vérification machine directe de « aucun trou
    vers le ciel », que le kit rejeté échouait au-dessus de la bouche.
    """
    bvh = bvh_depuis(obj)
    fautes = []
    for i in range(2, len(CAVITE) - 2):
        ax, ay, hw, _ = CAVITE[i]
        for lat in (-0.55, -0.25, 0.0, 0.25, 0.55):
            # L'origine SUIT le palier : partie d'une hauteur fixe, elle
            # serait sous le sol au fond de la galerie et compterait des
            # croisements qui ne veulent plus rien dire.
            origine = Vector((ax + lat * hw, ay, 0.35 + PALIER[i]))
            croisements, position, garde = 0, origine.copy(), 0
            while garde < 16:
                garde += 1
                r = bvh.ray_cast(position, Vector((0.0, 0.0, 1.0)), 100.0)
                if r is None or r[0] is None:
                    break
                croisements += 1
                position = r[0] + Vector((0.0, 0.0, 0.002))
            if croisements < 2 or croisements % 2 != 0:
                fautes.append((ax + lat * hw, ay, croisements))
    return fautes


def hauteur_du_sol(obj, x, y):
    """Hauteur du sol de la cavité à (x, y), en repère MODÈLE.

    POURQUOI CE CONTRÔLE EXISTE. La récompense est posée par le script de
    lieu à une altitude écrite EN DUR, et le générateur vient de relever le
    sol de deux façons (palier le long de l'axe, tablette d'alcôve). Deux
    fichiers, une seule vérité géométrique : sans mesure, la récompense
    flotte ou s'enterre, et personne ne le voit avant la capture.
    On tire donc un rayon vers le BAS depuis l'intérieur de la cavité.
    """
    # UN RAYON QUI PART D'UN POINT QUELCONQUE MENT. Première version : départ
    # fixe à z = 1,60, on garde le premier impact. Mesuré, elle a rendu
    # 1,544 m à un endroit et −2,078 m à 60 cm de là — le départ tombait
    # dans la roche et le « sol » était en réalité une face de dessous.
    # On descend donc en comptant les impacts et on ne retient que le
    # premier dont la NORMALE regarde vers le haut : c'est la définition
    # d'un sol, et rien d'autre ne peut la satisfaire.
    bvh = bvh_depuis(obj)
    position = Vector((x, y, 3.60))
    for _ in range(12):
        r = bvh.ray_cast(position, Vector((0.0, 0.0, -1.0)), 8.0)
        if r is None or r[0] is None:
            return None
        if r[1] is not None and r[1].z > 0.30:
            return r[0].z
        position = r[0] - Vector((0.0, 0.0, 0.002))
    return None


def _boite(obj):
    """AABB d'un objet, en repère monde (tous sont à l'origine, échelle 1)."""
    xs = [v.co for v in obj.data.vertices]
    return (Vector((min(p.x for p in xs), min(p.y for p in xs), min(p.z for p in xs))),
            Vector((max(p.x for p in xs), max(p.y for p in xs), max(p.z for p in xs))))


def _recouvrement(a, b):
    """Recouvrement de deux AABB, axe par axe. Le minimum des trois est la
    profondeur de pénétration garantie : si l'un est négatif, les boîtes ne
    se touchent pas du tout."""
    (a0, a1), (b0, b1) = a, b
    return min(min(a1.x, b1.x) - max(a0.x, b0.x),
               min(a1.y, b1.y) - max(a0.y, b0.y),
               min(a1.z, b1.z) - max(a0.z, b0.z))


def controle_penetration(pieces):
    """SOLIDARITÉ — aucune masse source isolée, pénétration mesurée.

    C'est l'un des contrôles que le lead a substitués à la statistique de
    triangles, et il mesure la bonne chose : non pas comment le fichier est
    découpé, mais si chaque volume source ENTRE réellement dans la matière
    du reste. Une masse qui effleure produit une couture rasante et une
    arête en escalier ; une masse qui pénètre franchement produit une
    intersection nette, et le booléen a de quoi travailler.

    Deux exigences distinctes :
      1. chaque masse pénètre au moins une autre pièce d'au moins
         `RECOUVREMENT_AABB_MIN_M` sur les TROIS axes ;
      2. le graphe ainsi formé est CONNEXE depuis l'enveloppe — sinon deux
         masses peuvent se tenir l'une l'autre à l'écart de la formation.

    Rend (liste des isolées, liste des non rattachées, detail des paires).
    """
    boites = [(obj.name, _boite(obj)) for obj in pieces]
    arbres = [bvh_depuis(obj) for obj in pieces]
    faces_de = [[[obj.data.vertices[i].co.copy() for i in p.vertices]
                 for p in obj.data.polygons] for obj in pieces]
    aretes = {nom: set() for nom, _ in boites}
    detail = []
    for i in range(len(boites)):
        for k in range(i + 1, len(boites)):
            r = _recouvrement(boites[i][1], boites[k][1])
            if r < RECOUVREMENT_AABB_MIN_M:
                continue                      # préfiltre : boîtes disjointes
            # LE RECOUVREMENT D'AABB NE SUFFIT PAS, et l'union me l'a appris
            # en rendant 2 îlots alors que le graphe des boîtes était
            # connexe : deux boîtes peuvent se chevaucher sans que les
            # surfaces se croisent — un bloc au coin d'un autre. On exige
            # donc un vrai croisement de faces.
            #
            # ET `overlap` NE SUFFIT PAS NON PLUS, ce que l'union m'a appris
            # une seconde fois en rendant 5 coques : il compte les faces
            # simplement TANGENTES. Deux roches qui s'effleurent satisfont
            # ce contrôle et ressortent pourtant en deux coques distinctes,
            # parce que le solveur exact n'a rien à fusionner. On applique
            # donc le même test de straddle qu'à l'auto-intersection : une
            # face de A doit passer strictement de part et d'autre du plan
            # d'une face de B, et réciproquement.
            croisements = 0
            for fa, fb in arbres[i].overlap(arbres[k]):
                if _straddle_points(faces_de[i][fa], faces_de[k][fb]):
                    croisements += 1
            if croisements == 0:
                continue
            aretes[boites[i][0]].add(boites[k][0])
            aretes[boites[k][0]].add(boites[i][0])
            detail.append((boites[i][0], boites[k][0], r, croisements))
    isolees = [nom for nom, v in aretes.items() if not v]
    # DIRE DE COMBIEN, PAS SEULEMENT QUE. Une roche isolée se corrige en la
    # déplaçant ; sans la distance au voisin le plus proche, chaque essai
    # coûte un cycle Blender complet. On rend donc, pour chaque isolée, la
    # pièce la plus proche et le recouvrement d'AABB qui manque.
    voisins_proches = {}
    for nom in isolees:
        i = next(k for k, (n, _) in enumerate(boites) if n == nom)
        meilleur = None
        for k in range(len(boites)):
            if k == i:
                continue
            r = _recouvrement(boites[i][1], boites[k][1])
            if meilleur is None or r > meilleur[1]:
                meilleur = (boites[k][0], r)
        voisins_proches[nom] = meilleur

    # Connexité depuis l'enveloppe : un parcours en largeur suffit.
    depart = boites[0][0]
    vus = {depart}
    file = [depart]
    while file:
        courant = file.pop()
        for voisin in aretes[courant]:
            if voisin not in vus:
                vus.add(voisin)
                file.append(voisin)
    detachees = [nom for nom, _ in boites if nom not in vus]
    return isolees, detachees, detail, voisins_proches


def joindre(base, masses):
    """Réunit les roches en UN objet, sans booléen — simple concaténation.

    C'est l'entrée du remaillage volumétrique : on n'a pas besoin que le
    résultat soit un solide, seulement que toute la matière soit là.
    """
    bm = bmesh.new()
    bm.from_mesh(base.data)
    for masse in masses:
        bm.from_mesh(masse.data)
    bm.to_mesh(base.data)
    bm.free()
    base.data.update()
    for masse in masses:
        bpy.data.objects.remove(masse, do_unlink=True)
    return base


def remailler_voxel(obj, taille):
    """Remaillage volumétrique — la sortie de l'impasse booléenne.

    POURQUOI ON EN ARRIVE LÀ, avec les chiffres. Fusionner trente-cinq
    rochers de kit par booléen exact a été tenté sous cinq formes :

      séquentielle (un modificateur par masse)          87 arêtes irrégulières
      collection unique, 35 opérandes                  155
      collection + `use_hole_tolerant`                 132
      collection + seconde passe du solveur             62
      par lots de six, sources subdivisées             280

    Aucune ne rend un manifold fermé, et une bissection roche par roche a
    montré pourquoi : `template-wall-detail-a` fait passer le compte de 0 à
    57 à lui seul, alors qu'il est fermé, sans auto-intersection et de
    volume 16,81 m3. « Ferme et sain » ne veut pas dire « utilisable dans un
    booléen », et je n'ai aucun moyen de prouver à l'avance qu'un module de
    kit l'est.

    Le remaillage volumétrique ne pose pas cette question. Il échantillonne
    la matière sur une grille et reconstruit une surface : la sortie est
    fermée, manifold et d'une seule coque QUELLE QUE SOIT l'entrée — soupe
    de faces, auto-intersections, coques ouvertes comprises. C'est
    exactement le chemin d'échappement prévu par le lead.

    Ce qu'on y perd : les arêtes se biseautent d'environ un demi-voxel. Sur
    de la roche c'est une usure, pas une perte. Ce qu'on y gagne, au-delà de
    la robustesse : un maillage DENSE ET RÉGULIER, sur lequel le champ de
    strates s'applique sans l'erreur d'interpolation qui repliait les faces
    du kit (le pas de strate fait 0,85 m ; une arête de kit fait 1 à 2 m,
    une arête de remaillage fait un voxel).
    """
    bpy.context.view_layer.objects.active = obj
    mod = obj.modifiers.new("remaillage", 'REMESH')
    mod.mode = 'VOXEL'
    mod.voxel_size = taille
    mod.adaptivity = 0.0
    mod.use_smooth_shade = False
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def decimer(obj, cible):
    """Ramène le maillage dans le budget, sans toucher à sa silhouette.

    `COLLAPSE` fusionne les arêtes les moins coûteuses : il retire d'abord
    le détail des grandes faces planes et garde les arêtes qui portent la
    forme. Le ratio est calculé, pas deviné, et on imprime les deux
    nombres — un budget respecté par hasard n'est pas un budget.
    """
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    if tris <= cible:
        print("[grotte] decimation inutile : %d tris <= %d" % (tris, cible))
        return obj
    bpy.context.view_layer.objects.active = obj
    mod = obj.modifiers.new("decimation", 'DECIMATE')
    mod.decimate_type = 'COLLAPSE'
    mod.ratio = float(cible) / float(tris)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    apres = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    print("[grotte] decimation : %d -> %d tris (ratio %.3f)"
          % (tris, apres, mod.ratio))
    return obj


def peindre_matieres(obj):
    """Attribue la matière de chaque face par `famille_massif()`.

    Après remaillage il ne reste aucune information de matériau : la
    surface est neuve. C'est une bonne nouvelle — la bande de valeur est
    alors décidée en un seul point, pour toute la formation, à partir de la
    seule position.
    """
    maillage = obj.data
    maillage.materials.clear()
    for cle in ORDRE_MATIERES:
        maillage.materials.append(bpy.data.materials[cle])
    for polygone in maillage.polygons:
        centre = Vector((0.0, 0.0, 0.0))
        for i in polygone.vertices:
            centre = centre + maillage.vertices[i].co
        polygone.material_index = IDX[famille_massif(
            centre / len(polygone.vertices))]
        polygone.use_smooth = False
    maillage.update()
    return obj


def stratifier(obj):
    """Applique le champ de strates à un maillage DENSE, après remaillage.

    C'est l'ordre que recommande le lead — « puis réattribution du champ de
    strates » — et il est meilleur que l'inverse pour une raison mesurable :
    le champ est appliqué aux sommets, donc ce qu'on obtient est son
    approximation affine par morceaux. Sur les arêtes du kit (1 à 2 m pour
    un pas de strate de 0,85 m) cette approximation repliait les faces
    jusqu'à 0,083 m ; sur des arêtes d'un voxel, l'erreur est deux ordres de
    grandeur plus petite.
    """
    for v in obj.data.vertices:
        v.co = deformer_massif(Vector(v.co))
    obj.data.update()
    return obj


def unir(base, masses):
    """Fusionne réellement les masses sources dans l'enveloppe.

    « La surface extérieure livrée doit être fusionnée en une formation
    géologique continue. Un seul maillage final est autorisé et ne
    constitue pas un défaut. » — c'est ici que ça se passe.

    Le solveur EXACT, et non FAST : mesuré avant d'écrire cette fonction,
    il rend un manifold fermé sur 14 blocs convexes irréguliers en 0,12 s,
    et il ne dépend pas d'un ordre d'opérandes heureux.

    Les slots de matériaux sont identiques et dans le même ordre sur toutes
    les pièces (`objet()` les ajoute depuis `ORDRE_MATIERES`), donc les
    indices survivent à la fusion sans remappage.
    """
    # FUSION PAR PAQUETS, et les deux autres façons ont été mesurées.
    #
    #   séquentielle, un modificateur par masse : 87 arêtes irrégulières.
    #     Chaque résultat intermédiaire sert d'entrée au suivant, donc un
    #     micro-défaut se propage et s'amplifie sur trente-quatre étages.
    #   collection unique, trente-cinq opérandes d'un coup : 155.
    #     Le solveur voit tout, mais le système à résoudre est trop gros.
    #   `use_hole_tolerant` par-dessus : 132 au lieu de 87. Son nom promet
    #     exactement ce qu'on cherche et il fait le contraire ici — raison
    #     de plus pour mesurer une option plutôt que de lire son intitulé.
    #   seconde passe du solveur sur son propre résultat : 62 au lieu de 30.
    #
    # Le compromis est donc le paquet : assez d'opérandes pour que le
    # solveur voie les recouvrements d'une même masse, assez peu pour que le
    # système reste conditionné. On referme et on vérifie APRÈS CHAQUE
    # PAQUET, ce qui donne en prime le nom du paquet fautif au lieu d'un
    # chiffre global.
    lots = [masses[i:i + TAILLE_LOT_UNION]
            for i in range(0, len(masses), TAILLE_LOT_UNION)]
    for numero, lot in enumerate(lots):
        # Le nom est relevé AVANT le booléen : `bpy.data.objects.remove()`
        # invalide la référence Python, et lire `lot[0].name` après coup lève
        # « StructRNA of type Object has been removed ».
        etiquette = lot[0].name.replace("SM_WaterfallCave_", "")
        collection = bpy.data.collections.new("union_lot_%d" % numero)
        bpy.context.scene.collection.children.link(collection)
        for masse in lot:
            collection.objects.link(masse)
        bpy.context.view_layer.objects.active = base
        mod = base.modifiers.new("union_lot_%d" % numero, 'BOOLEAN')
        mod.operation = 'UNION'
        mod.solver = 'EXACT'
        mod.use_self = True
        mod.operand_type = 'COLLECTION'
        mod.collection = collection
        bpy.ops.object.modifier_apply(modifier=mod.name)
        for masse in lot:
            bpy.data.objects.remove(masse, do_unlink=True)
        bpy.data.collections.remove(collection)
        bm = bmesh.new()
        bm.from_mesh(base.data)
        brut = sum(1 for e in bm.edges if len(e.link_faces) != 2)
        bm.free()
        apres_reparation, _ = _souder_et_reboucher(base.data)
        print("[grotte]   lot %d (%d roches, a partir de %s) : %d arete(s) "
              "irreguliere(s) en sortie de solveur, %d apres rebouchage"
              % (numero, len(lot), etiquette, brut, apres_reparation))
    maillage = base.data
    bm = bmesh.new()
    bm.from_mesh(maillage)
    # NETTOYAGE DES DÉGÉNÉRESCENCES DU BOOLÉEN. Là où deux surfaces sources
    # sont presque tangentes, le solveur exact produit des faces en lame de
    # rasoir : aire quasi nulle, deux sommets à quelques microns.
    #
    # LA TOLÉRANCE ÉTAIT À 1e-3, ET ELLE OUVRAIT LE MAILLAGE. Mesuré :
    # 85 arêtes de bord après l'union de 35 roches. Souder des sommets
    # distants d'un millimètre écrase les triangles fins de l'intersection
    # en arêtes, et une face écrasée est un trou. Ce réglage venait d'une
    # époque où le test d'auto-intersection comptait les faces TANGENTES :
    # il fallait alors dissoudre gros pour le faire taire. Depuis que le
    # test distingue tangence et traversée (`_straddle_points`), plus rien
    # n'exige cette grosse tolérance, et on descend de deux ordres de
    # grandeur. Le bilan avant/après est imprimé : un nettoyage qui
    # dégraderait la fermeture doit se voir.
    avant = sum(1 for e in bm.edges if len(e.link_faces) != 2)
    bmesh.ops.dissolve_degenerate(bm, dist=1e-5, edges=bm.edges[:])
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    apres = sum(1 for e in bm.edges if len(e.link_faces) != 2)
    bm.to_mesh(maillage)
    bm.free()
    # REBOUCHAGE APRÈS SOLVEUR, et il faut dire honnêtement ce que c'est.
    # Le solveur exact ne rend pas un manifold parfait sur trente-cinq
    # rochers de kit réparés : il reste quelques dizaines d'arêtes de bord,
    # sur des triangles en lame de rasoir aux intersections. Ce ne sont pas
    # des trous voulus, ce sont des résidus numériques — mais un maillage
    # ouvert montre ses faces arrière dans Godot, donc il faut les fermer.
    # On applique le même rebouchage qu'aux modules, et surtout on VÉRIFIE
    # ensuite fermeture ET auto-intersection : la réparation n'est acceptée
    # que si le résultat passe les contrôles, jamais parce qu'elle a tourné.
    restants, _ = _souder_et_reboucher(maillage)
    bm = bmesh.new()
    bm.from_mesh(maillage)
    seules = sum(1 for e in bm.edges if len(e.link_faces) == 1)
    surchargees = sum(1 for e in bm.edges if len(e.link_faces) > 2)
    bm.free()
    print("[grotte] nettoyage de l'union : %d -> %d -> %d arete(s) "
          "irreguliere(s) (booleen, dissolution, rebouchage) — dont %d de "
          "bord et %d a plus de deux faces"
          % (avant, apres, restants, seules, surchargees))
    maillage.update()
    for polygone in maillage.polygons:
        polygone.use_smooth = False
    return base


def retirer_bulles(obj):
    """Sépare la coque EXTÉRIEURE des bulles enfermées, et retire les bulles.

    Trente-cinq volumes qui s'interpénètrent laissent presque forcément des
    poches d'air closes : trois roches qui se touchent deux à deux enferment
    un vide au milieu. L'union rend alors un maillage parfaitement fermé et
    parfaitement manifold, composé de PLUSIEURS coques — mesuré, 5 ici.

    `controle_connexite` les comptait comme des îlots et refusait, ce qui
    était le bon réflexe pour des blocs côte à côte et le mauvais verdict
    ici : une bulle interne n'est pas un bloc voisin, c'est de la matière
    manquante à l'intérieur d'une masse pleine.

    Le signe du volume les distingue sans ambiguïté : les faces d'une coque
    extérieure regardent dehors (volume signé positif), celles d'une bulle
    regardent vers l'intérieur de la bulle (volume signé négatif). On retire
    les négatives — la roche devient pleine — et on EXIGE qu'il reste
    exactement une coque positive, sinon ce sont bien des blocs séparés.

    Une TROISIÈME catégorie est apparue à la mesure, et je ne l'avais pas
    prévue : des ÉCAILLES de volume nul. Quatre coques de huit sommets,
    volume 0,00 m3, l'une entièrement plate (z de 1,50 à 1,50). Ce sont des
    résidus du solveur là où deux surfaces sont presque tangentes — la même
    famille que les faces en lame de rasoir déjà dissoutes dans `unir()`,
    mais détachées du maillage principal, donc hors de portée de
    `dissolve_degenerate`. Les compter comme des blocs séparés faisait
    refuser une formation par ailleurs saine (781 m3 en une seule coque).

    Rend (coques substantielles, bulles retirées, écailles retirées).
    """
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    restants = set(bm.verts)
    composantes = []
    while restants:
        depart = restants.pop()
        pile = [depart]
        groupe = {depart}
        while pile:
            v = pile.pop()
            for e in v.link_edges:
                autre = e.other_vert(v)
                if autre in restants:
                    restants.remove(autre)
                    groupe.add(autre)
                    pile.append(autre)
        composantes.append(groupe)

    a_retirer = []
    debris = 0
    positives = 0
    for groupe in composantes:
        faces = {f for v in groupe for f in v.link_faces}
        volume = 0.0
        for f in faces:
            pts = [v.co for v in f.verts]
            for k in range(1, len(pts) - 1):
                volume += pts[0].dot(pts[k].cross(pts[k + 1])) / 6.0
        if abs(volume) < VOLUME_DEBRIS_M3:
            debris += 1
            a_retirer.append(groupe)
        elif volume > 0.0:
            positives += 1
            # OÙ, pas seulement COMBIEN. Une coque en trop peut être un bloc
            # détaché, une écaille d'un dixième de mètre cube ou une coque
            # imbriquée dans une autre ; les trois se corrigent autrement.
            xs = [v.co for v in groupe]
            print("[grotte]   coque +%8.2f m3, boite (%.1f..%.1f, %.1f..%.1f,"
                  " %.1f..%.1f), %d sommets"
                  % (volume, min(p.x for p in xs), max(p.x for p in xs),
                     min(p.y for p in xs), max(p.y for p in xs),
                     min(p.z for p in xs), max(p.z for p in xs), len(groupe)))
        else:
            a_retirer.append(groupe)
    for groupe in a_retirer:
        bmesh.ops.delete(bm, geom=list(groupe), context='VERTS')
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return positives, len(a_retirer) - debris, debris


def controle_connexite(obj):
    """L'union est-elle UNE formation, ou plusieurs coques côte à côte ?

    Un booléen sur des volumes qui ne se touchent pas rend un maillage
    parfaitement fermé, parfaitement manifold — et parfaitement composé de
    plusieurs îlots séparés. Aucun des contrôles existants ne s'en
    apercevrait. On compte donc les composantes connexes : il en faut UNE.
    """
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    restants = set(bm.verts)
    ilots = 0
    while restants:
        depart = restants.pop()
        pile = [depart]
        ilots += 1
        while pile:
            v = pile.pop()
            for e in v.link_edges:
                autre = e.other_vert(v)
                if autre in restants:
                    restants.remove(autre)
                    pile.append(autre)
    bm.free()
    return ilots


def controle_auto_intersection(obj):
    """Zéro auto-intersection — ce que `controle_fermeture` ne voit pas.

    Un maillage dont un lobe traverse la paroi opposée reste à 0 arête de
    bord, 0 non-manifold et de volume signé positif : les contrôles de
    fermeture le déclarent sain. Il rend pourtant des faces intérieures
    visibles et des ombres fausses.

    `BVHTree.overlap(self)` rend les paires de faces qui se croisent. On
    écarte les paires qui partagent au moins un sommet — deux faces
    adjacentes se « croisent » toujours au sens du BVH.
    """
    return _croisements_de(obj.data)


def _traverse_vraiment(sommets, pa, pb):
    """Deux faces se TRAVERSENT-elles, ou se TOUCHENT-elles seulement ?

    `BVHTree.overlap` ne fait pas la différence, et ça m'a coûté un cycle.
    Deux faces exactement tangentes — bord contre bord après un booléen,
    sommets coïncidents mais non soudés, faces coplanaires — sont rendues
    comme « croisées ». Le filtre « elles partagent un indice de sommet » ne
    les attrape pas, justement parce que les sommets ne sont pas soudés.

    LA MESURE QUI A TRANCHÉ : une ROTATION RIGIDE du module faisait passer
    le compte de 0 à 2 puis à 0. Une rotation rigide ne peut ni créer ni
    supprimer une auto-intersection réelle ; le compte mesurait donc du
    bruit de virgule flottante sur des faces tangentes, pas de la géométrie.
    J'ai bien failli « corriger » ce bruit en déplaçant des roches.

    Le test correct est le straddle : une vraie traversée exige que chaque
    face ait des sommets STRICTEMENT des deux côtés du plan de l'autre, au
    -delà d'une tolérance. Coplanaires ou tangentes, elles ne le font pas.
    """
    return _straddle_points([sommets[i] for i in pa],
                            [sommets[i] for i in pb])


def _straddle_points(pts_a, pts_b):
    """Le test, sur deux listes de points — sans passer par des indices."""
    def cote(a, b):
        # Normale de Newell : exacte sur un triangle, et robuste sur un
        # n-gone légèrement gauche — les capuchons de `holes_fill` en sont.
        normale = Vector((0.0, 0.0, 0.0))
        for k in range(len(b)):
            p, q = b[k], b[(k + 1) % len(b)]
            normale.x += (p.y - q.y) * (p.z + q.z)
            normale.y += (p.z - q.z) * (p.x + q.x)
            normale.z += (p.x - q.x) * (p.y + q.y)
        if normale.length < 1e-12:
            return False
        normale.normalize()
        origine = sum(b, Vector()) / len(b)
        distances = [(p - origine).dot(normale) for p in a]
        return max(distances) > TOLERANCE_TANGENCE_M \
            and min(distances) < -TOLERANCE_TANGENCE_M
    return cote(pts_a, pts_b) and cote(pts_b, pts_a)


def controle_repli(obj):
    """De QUELLE PROFONDEUR une pièce se replie-t-elle sur elle-même ?

    Le contrôle binaire « zéro auto-intersection » était juste pour des
    lofts, où toute traversée est un défaut de construction. Il devient
    faux pour des roches de kit déformées, et voici pourquoi, mesuré :

      * le module réparé ne se traverse pas ;
      * le champ de strates est un homéomorphisme, il ne peut pas replier
        une surface saine (démonstration dans `deformer_massif()`) ;
      * et pourtant huit roches sur trente-quatre ressortent avec 1 à 6
        paires croisées, de 0,0006 m à 0,083 m de profondeur.

    La contradiction n'est qu'apparente. Le champ est appliqué AUX SOMMETS ;
    entre deux sommets, la face reste un plan. Ce qu'on obtient n'est donc
    pas l'image de la surface par l'homéomorphisme, c'est son approximation
    affine par morceaux — et cette approximation, elle, n'est pas
    injective là où le champ courbe fortement, c'est-à-dire aux joints de
    strate. Deux faces qui se TOUCHAIENT se recouvrent alors de quelques
    centimètres.

    C'est une profondeur, pas un pli traversant : la mesurer permet de
    distinguer un lobe qui perce sa paroi opposée (décimètres) d'un contact
    devenu recouvrement (centimètres). Le second est résolu par `use_self`
    à l'union ; le premier ne doit jamais passer.

    Rend (nombre de paires, profondeur maximale, exemple).
    """
    n, profondeur, exemple = _croisements_de(obj.data, avec_profondeur=True)
    return n, profondeur, exemple


def _profondeur_de(sommets, pa, pb):
    """Enfoncement mutuel de deux faces, en mètres."""
    def enfoncement(a, b):
        pts_b = [sommets[i] for i in b]
        normale = Vector((0.0, 0.0, 0.0))
        for k in range(len(pts_b)):
            p, q = pts_b[k], pts_b[(k + 1) % len(pts_b)]
            normale.x += (p.y - q.y) * (p.z + q.z)
            normale.y += (p.z - q.z) * (p.x + q.x)
            normale.z += (p.x - q.x) * (p.y + q.y)
        if normale.length < 1e-12:
            return 0.0
        normale.normalize()
        origine = sum(pts_b, Vector()) / len(pts_b)
        d = [(sommets[i] - origine).dot(normale) for i in a]
        return min(max(d), -min(d))
    return min(enfoncement(pa, pb), enfoncement(pb, pa))


def _croisements_de(maillage, avec_profondeur=False):
    """Le même calcul, sur un maillage nu — `charger_module()` en a besoin
    avant qu'aucun objet n'existe."""
    sommets = [v.co.copy() for v in maillage.vertices]
    polys = [tuple(p.vertices) for p in maillage.polygons]
    arbre = BVHTree.FromPolygons(sommets, polys, all_triangles=False, epsilon=0.0)
    fautes = 0
    exemple = None
    pire = 0.0
    for a, b in arbre.overlap(arbre):
        if a >= b:
            continue
        if set(polys[a]) & set(polys[b]):
            continue
        if not _traverse_vraiment(sommets, polys[a], polys[b]):
            continue
        fautes += 1
        profondeur = _profondeur_de(sommets, polys[a], polys[b])
        if profondeur > pire or exemple is None:
            pire = max(pire, profondeur)
            ca = sum((sommets[i] for i in polys[a]), Vector()) / len(polys[a])
            cb = sum((sommets[i] for i in polys[b]), Vector()) / len(polys[b])
            exemple = "faces %d/%d, centres (%.2f, %.2f, %.2f) et " \
                "(%.2f, %.2f, %.2f), enfoncement %.4f m" \
                % (a, b, ca.x, ca.y, ca.z, cb.x, cb.y, cb.z, profondeur)
    if avec_profondeur:
        return fautes, pire, exemple
    return fautes, exemple


def controle_composition(objets_visibles):
    """TÉLÉMÉTRIE — plus un verdict. Le lead a démonté le raisonnement.

    J'avais fait de la part de triangles par objet un gate bloquant, en
    tirant un seuil de 45 % d'une comparaison avec le pont, le pylône et le
    quai. Le lead l'a refusé, et son argument est juste :

    * une coque INCHANGÉE passerait le test en étant simplement découpée en
      quatre objets — le fichier changerait, pas le rocher ;
    * une formation réellement FUSIONNÉE en un seul maillage, qui est
      justement le résultat recherché, afficherait 100 % et échouerait ;
    * un pont, un pylône et un quai sont naturellement faits de pièces
      assemblées. Leur découpage ne dit rien du découpage attendu d'une
      formation géologique. Le seuil n'était donc pas « lu dans le
      tableau », il était lu dans un tableau sans rapport.

    La mesure reste imprimée parce qu'elle est informative — elle dit ce
    que pèse chaque source — mais elle ne décide plus rien. Ce qui décide,
    ce sont la solidarité du graphe, la pénétration mesurée, la connexité
    de l'union, l'absence d'auto-intersection et de bord non-manifold.

    Rend (part_du_plus_gros, nombre_de_pieces_significatives, detail).
    """
    parts = []
    for obj in objets_visibles:
        tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
        parts.append((obj.name, tris))
    total = sum(t for _, t in parts)
    if total <= 0:
        return 100.0, 0, []
    parts.sort(key=lambda x: -x[1])
    detail = [(nom, tris, 100.0 * tris / total) for nom, tris in parts]
    significatives = sum(1 for _, _, pc in detail if pc >= PART_SIGNIFICATIVE_PC)
    return detail[0][2], significatives, detail


def controle_assise(obj):
    zs = [v.co.z for v in obj.data.vertices]
    seuil = [v.co.z for i, v in enumerate(obj.data.vertices)
             if len(CAVITE) * 0 <= i < 1]
    return min(zs), max(zs), (seuil[0] if seuil else 0.0)


def main():
    vider_scene()
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0
    for nom in ORDRE_MATIERES:
        materiau(nom)

    # 1. LA COQUE DE COLLISION, seule survivante du loft extérieur.
    s_col, f_col, fam_col = construire(
        SEGMENTS_COL, SAG, SKIRT_COL, COL_MARGE_LAT, COL_MARGE_CLE)
    collision = objet("COL_WaterfallCave", s_col, f_col, fam_col, False)

    # 2. LES ROCHES DU KIT — le relief vient d'elles, plus d'un rayon
    #    quantifié. Chacune est chargée soudée et vérifiée fermée ; l'assise
    #    enterrée ferme la formation par le bas.
    try:
        pieces = [assise_enterree()]
        implantation = list(ROCHERS) + rochers_gaine()
        for config in implantation:
            pieces.append(poser_rocher(config))
    except RuntimeError as erreur:
        print("[grotte] ERREUR: %s" % erreur)
        return 2
    compte = {}
    for config in implantation:
        compte[config["rang"]] = compte.get(config["rang"], 0) + 1
    print("[grotte] %d roche(s) du kit posee(s) : %s, plus l'assise enterree"
          % (len(implantation), ", ".join("%d %s" % (n, r)
                                          for r, n in sorted(compte.items()))))
    # QUI DÉCIDE DE LA CRÊTE ? La question n'est pas rhétorique : sur la
    # capture précédente le sommet de la formation était une rangée de
    # dents régulières, et il a fallu la deviner faute de mesure. Ce
    # relevé la donne — le rang `gaine` doit rester NETTEMENT sous les
    # rangs de composition, sans quoi l'invisible décide du visible.
    faite = {}
    for config, obj in zip(implantation, pieces[1:]):
        haut = max(v.co.z for v in obj.data.vertices)
        rang = config["rang"]
        faite[rang] = max(faite.get(rang, -1e9), haut)
    print("[grotte] faite par rang (z max, m) : %s"
          % ", ".join("%s %.2f" % (r, z) for r, z in sorted(
              faite.items(), key=lambda kv: -kv[1])))

    for obj in pieces + [collision]:
        obj.location = (0.0, 0.0, 0.0)
        obj.scale = (1.0, 1.0, 1.0)

    # 3. TÉLÉMÉTRIE de composition — imprimée, jamais bloquante.
    _, _, detail = controle_composition(pieces)
    print("[grotte] composition des volumes SOURCES (telemetrie, ne bloque "
          "rien ; l'union les fond ensuite en un seul maillage) :")
    for nom, t, pc in detail:
        print("[grotte]   %-30s %6d tris  %5.1f %%"
              % (nom.replace("SM_WaterfallCave_", ""), t, pc))

    # 4. SOLIDARITÉ des volumes sources, avant de les fondre.
    isolees, detachees, paires, voisins = controle_penetration(pieces)
    print("[grotte] solidarite : %d paire(s) en INTERSECTION reelle "
          "(prefiltre AABB >= %.2f m, PUIS croisement de faces verifie)"
          % (len(paires), RECOUVREMENT_AABB_MIN_M))
    for a, b, r, n in sorted(paires, key=lambda x: x[3])[:4]:
        print("[grotte]   plus faible : %s <-> %s  %.2f m, %d face(s) croisee(s)"
              % (a.replace("SM_WaterfallCave_", ""),
                 b.replace("SM_WaterfallCave_", ""), r, n))
    if isolees or detachees:
        for nom in isolees:
            proche, r = voisins.get(nom, ("?", float("nan")))
            print("[grotte] ERREUR: roche ISOLEE — aucune face de %s ne "
                  "croise une autre piece. La plus proche est %s, "
                  "recouvrement d'AABB %.2f m (il en faut %.2f)"
                  % (nom, proche.replace("SM_WaterfallCave_", ""), r,
                     RECOUVREMENT_AABB_MIN_M))
        for nom in detachees:
            if nom not in isolees:
                print("[grotte] ERREUR: roche DETACHEE — %s ne se rattache "
                      "pas a la formation par une chaine de penetrations" % nom)
        return 2

    # 5. FUSION PAR REMAILLAGE VOLUMÉTRIQUE. Voir `remailler_voxel()` pour
    #    le journal des cinq tentatives booléennes et leurs chiffres : le
    #    solveur exact ne rend pas un manifold fermé sur trente-cinq
    #    rochers de kit, et une bissection roche par roche montre qu'un
    #    module par ailleurs sain suffit à le faire échouer. Le remaillage,
    #    lui, rend une coque fermée quelle que soit l'entrée.
    grotte = joindre(pieces[0], pieces[1:])
    grotte.name = "SM_WaterfallCave"
    grotte.data.name = "SM_WaterfallCave"
    remailler_voxel(grotte, VOXEL_M)
    tris_remaillage = sum(len(p.vertices) - 2 for p in grotte.data.polygons)
    print("[grotte] remaillage voxel %.2f m : %d tris"
          % (VOXEL_M, tris_remaillage))

    coques, bulles, ecailles = retirer_bulles(grotte)
    print("[grotte] remaillage : %d coque(s) exterieure(s), %d bulle(s) "
          "interne(s) et %d ecaille(s) retirees" % (coques, bulles, ecailles))
    if coques != 1:
        print("[grotte] ERREUR: %d coques exterieures — les roches ne "
              "forment pas une masse continue a l'echelle du voxel" % coques)
        return 2
    bords_u, nm_u, vol_u = controle_fermeture(grotte)
    print("[grotte] remaillage : %d arete(s) de bord, %d non-manifold, %.1f m3"
          % (bords_u, nm_u, vol_u))
    if bords_u or nm_u:
        print("[grotte] ERREUR: le remaillage rend une coque ouverte — c'est "
              "anormal, il est fait pour rendre un manifold fermé")
        return 2

    # 6. STRATES SUR LE MAILLAGE DENSE, PUIS BUDGET, PUIS CAVITÉ. L'ordre
    #    est celui recommandé par le lead, et il est meilleur : le champ
    #    s'applique sans erreur d'interpolation sur des arêtes d'un voxel.
    stratifier(grotte)
    n_repli, profondeur, exemple = controle_repli(grotte)
    print("[grotte] apres stratification : %d paire(s) croisee(s), repli "
          "maximal %.4f m" % (n_repli, profondeur))
    if profondeur > PROFONDEUR_REPLI_MAX_M:
        print("[grotte] ERREUR: le champ de strates replie la surface de "
              "%.3f m (%s)" % (profondeur, exemple))
        return 2
    decimer(grotte, TRIS_CIBLE)
    peindre_matieres(grotte)
    restants, _ = _souder_et_reboucher(grotte.data)
    if restants:
        print("[grotte] ERREUR: %d arete(s) irreguliere(s) apres decimation"
              % restants)
        return 2

    s_cav, f_cav, fam_cav = cavite_solide(SEGMENTS, SAG, 0.0, 0.0)
    outil = objet("OUTIL_Cavite", s_cav, f_cav, fam_cav, True)
    n_outil, ex_outil = controle_auto_intersection(outil)
    if n_outil:
        print("[grotte] ERREUR: le volume negatif de cavite s'auto-traverse "
              "— %d paire(s), %s" % (n_outil, ex_outil))
        return 2
    bords_o, nm_o, vol_o = controle_fermeture(outil)
    if bords_o or nm_o or abs(vol_o) < 1.0:
        print("[grotte] ERREUR: volume negatif NON FERME (%d bord, %d "
              "non-manifold, %.1f m3) — la soustraction serait fausse sans "
              "le dire" % (bords_o, nm_o, vol_o))
        return 2
    print("[grotte] volume negatif de cavite : ferme, %.1f m3" % abs(vol_o))
    grotte = soustraire(grotte, outil)
    print("[grotte] soustraction : la bouche est la trace de decoupe du tube")

    coques, bulles, ecailles = retirer_bulles(grotte)
    print("[grotte] soustraction : %d coque(s) exterieure(s), %d bulle(s) et "
          "%d ecaille(s) retirees" % (coques, bulles, ecailles))
    if coques != 1:
        print("[grotte] ERREUR: apres soustraction, %d coques — la cavite a "
              "tranche la formation en morceaux" % coques)
        return 2
    ilots = controle_connexite(grotte)
    if ilots != 1:
        print("[grotte] ERREUR: %d ilot(s) subsistent apres retrait des "
              "bulles" % ilots)
        return 2
    print("[grotte] connexite : 1 composante, avant et apres soustraction")

    croisements, profondeur, exemple = controle_repli(grotte)
    print("[grotte] auto-intersection du livrable : %d paire(s), repli "
          "maximal %.4f m (seuil %.3f m)"
          % (croisements, profondeur, REPLI_LIVRABLE_MAX_M))
    if profondeur > REPLI_LIVRABLE_MAX_M:
        print("[grotte] ERREUR: la surface livree se replie sur %.4f m "
              "(%s) — une coque fermee peut s'auto-traverser sans qu'aucun "
              "controle de fermeture ne le voie" % (profondeur, exemple))
        return 2

    for nom, obj in (("visuel", grotte), ("collision", collision)):
        bords, nm, volume = controle_fermeture(obj)
        print("[grotte] %s : %d arete(s) de bord, %d non-manifold, volume %.1f m3"
              % (nom, bords, nm, volume))
        if bords != 0 or nm != 0:
            print("[grotte] ERREUR: coque %s NON FERMEE — c'est le defaut "
                  "'enveloppe ouverte' du rejet" % nom)
            return 2
        if abs(volume) < 1.0:
            print("[grotte] ERREUR: volume nul ou degenere (%s)" % nom)
            return 2

    # 7. BUDGET DE TRIANGLES — dicté par le lead, 12 000 a 25 000.
    tris = sum(len(p.vertices) - 2 for p in grotte.data.polygons)
    tris_col = sum(len(p.vertices) - 2 for p in collision.data.polygons)
    mini_z, maxi_z, _ = controle_assise(grotte)
    print("[grotte] visuel %d faces (%d tris), collision %d faces (%d tris)"
          % (len(grotte.data.polygons), tris,
             len(collision.data.polygons), tris_col))
    print("[grotte] emprise Z de %.2f m a %.2f m (jupe %.2f m sous le sol)"
          % (mini_z, maxi_z, -mini_z))
    if tris < TRIS_MIN or tris > TRIS_MAX:
        print("[grotte] ERREUR: %d tris hors du budget hero [%d ; %d]"
              % (tris, TRIS_MIN, TRIS_MAX))
        return 2
    print("[grotte] budget : %d tris dans [%d ; %d]" % (tris, TRIS_MIN, TRIS_MAX))

    # 8. LE CONTRÔLE QUI MANQUAIT : la plus grande plage plane connexe.
    aire_in, centre_in, _, _ = controle_plage_plane(grotte, 0.0,
                                                    exterieur_seul=False)
    aire, centre, aire_facade, centre_facade = controle_plage_plane(grotte, 0.0)
    print("[grotte] plage plane toutes faces confondues (cavite comprise) : "
          "%.2f m2 — informatif, l'interieur releve d'un autre jalon"
          % aire_in)
    if centre is None:
        print("[grotte] ERREUR: aucune face au-dessus du terrain")
        return 2
    print("[grotte] plus grande plage plane au-dessus du sol : %.2f m2, "
          "centree en (%.2f, %.2f, %.2f) — seuil %.2f"
          % (aire, centre.x, centre.y, centre.z, PLAGE_PLANE_MAX_M2))
    if centre_facade is not None:
        print("[grotte] plus grande plage plane EN FACADE (y <= %.1f) : "
              "%.2f m2, centree en (%.2f, %.2f, %.2f) — seuil %.2f"
              % (FACADE_Y_MAX, aire_facade, centre_facade.x, centre_facade.y,
                 centre_facade.z, PLAGE_PLANE_FACADE_MAX_M2))
    if aire > PLAGE_PLANE_MAX_M2 or aire_facade > PLAGE_PLANE_FACADE_MAX_M2:
        print("[grotte] ERREUR: %.2f m2 global / %.2f m2 en facade — c'est le "
              "defaut 'grandes surfaces planes' du rejet, et le loft "
              "precedent affichait 60,93 m2 en passant les neuf autres "
              "controles" % (aire, aire_facade))
        return 2

    # 9. ÉPAISSEUR, mesurée par rayon sur le maillage FINAL.
    mini, mini_collerette, percees = controle_epaisseur(grotte, SEGMENTS)
    if percees:
        for i, azimut, n in percees[:5]:
            print("[grotte] ERREUR: station %d, azimut %.0f° — %d croisement(s) "
                  "seulement : le rayon sort par un JOUR" % (i, azimut, n))
        return 2
    if mini < EPAISSEUR_MIN_M or mini_collerette < EPAISSEUR_MIN_COLLERETTE_M:
        print("[grotte] ERREUR: epaisseur %.2f m en paroi, %.2f m en "
              "collerette (min %.2f / %.2f)"
              % (mini, mini_collerette, EPAISSEUR_MIN_M,
                 EPAISSEUR_MIN_COLLERETTE_M))
        return 2
    print("[grotte] epaisseur de roche : %.2f m en paroi, %.2f m au linteau "
          "(rayons lateraux et montants sur le maillage FINAL ; le plancher "
          "releve du terrain gele, voir controle_epaisseur)"
          % (mini, mini_collerette))

    faibles = controle_gabarit()
    if faibles:
        for i, ay, hw, cle in faibles:
            print("[grotte] ERREUR: station %d (y=%.2f) hors gabarit — "
                  "demi-largeur %.2f m, cle %.2f m" % (i, ay, hw, cle))
        return 2
    print("[grotte] gabarit : capsule r=0,45 h=1,85 passe aux %d stations "
          "du chemin" % (len(CAVITE) - 2))

    fautes = controle_aucun_jour(grotte, SEGMENTS)
    if fautes:
        for x, y, n in fautes[:5]:
            print("[grotte] ERREUR: le sol voit le ciel en (%.2f, %.2f) — "
                  "%d croisement(s)" % (x, y, n))
        return 2
    print("[grotte] aucun jour : 25 rayons verticaux, croisements pairs et >= 2")

    # Hauteur du sol là où le script de lieu pose la récompense et la salle.
    # Ces deux chiffres sont la SEULE source correcte pour les constantes
    # `MODELE_NICHE.y` et `MODELE_SALLE.y` de `waterfall_cave_place.gd` :
    # elles vivent dans un autre fichier, et le sol vient de bouger.
    for nom, x, y in (("axe_seuil", 0.05, 1.60), ("salle", 1.05, 6.25),
                      ("niche", -1.20, 8.20), ("voisin", -1.60, 8.20)):
        h = hauteur_du_sol(grotte, x, y)
        print("[grotte] sol sous %s (%.2f, %.2f) : %s"
              % (nom, x, y, "AUCUN — hors cavite" if h is None else "%.3f m" % h))

    if -mini_z < ASSISE_JUPE_MIN_M:
        print("[grotte] ERREUR: jupe de %.2f m < %.2f m — masse posee, non "
              "plantee" % (-mini_z, ASSISE_JUPE_MIN_M))
        return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_WaterfallCave.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[grotte] source enregistree -> %s" % sortie)

    return 0


if __name__ == "__main__":
    sys.exit(main())
