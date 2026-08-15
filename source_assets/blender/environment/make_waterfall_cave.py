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

import bpy
import bmesh
from mathutils import Vector
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
    (2.25,  8.65, 2.00, 2.40),
    (2.85,  9.25, 1.15, 1.80),
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
FORCE_STRATE = 0.55

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
FACETTE_ROTATION = 0.23      # rad ajoutés par station : les arêtes vrillent
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

# MASSES ANNEXES — et voici pourquoi les lobes n'ont pas suffi.
#
# Les lobes ci-dessus ont été construits, générés et CAPTURÉS en silhouette
# isolée. Résultat : encore une miche, facettée sur les bords mais ronde de
# contour. C'est arithmétique. Un lobe de 1,75 m sur un corps de 4,7 m de
# rayon est une BOSSE de 37 % : il se projette en renflement, jamais en
# masse. C'est exactement la leçon des trois pieds du pylône — trois
# volumes séparés dans le maillage ne font pas trois masses à l'œil, c'est
# la PROJECTION qui décide — et je viens de la repayer.
#
# Une silhouette « composée de trois masses distinctes » exige donc de
# VRAIS volumes qui débordent le corps principal, pas des modulations de
# son rayon. Le contrefort et la couronne sont des lofts autonomes, fermés,
# facettés, qui interpénètrent le massif : c'est ainsi que se lisent les
# affleurements rocheux réels, et ce n'est ni une plaque ni un BoxMesh.
#
# (x, y) base · (x, y) sommet · z0 · z1 · demi-largeur base/sommet ·
# profondeur base/sommet · facettes · rotation · biseau du sommet
MASSES_ANNEXES = (
    dict(nom="SM_WaterfallCave_Contrefort",
         base=(6.30, 4.30), sommet=(5.10, 4.90), z0=-2.40, z1=4.35,
         demi0=1.70, demi1=0.90, prof0=2.35, prof1=1.15,
         facettes=7, rotation=0.4, biseau=0.55, etages=7,
         matiere_bas="MAT_CaveRock_Base", matiere_haut="MAT_CaveRock_Face"),
    dict(nom="SM_WaterfallCave_Couronne",
         base=(1.60, 9.00), sommet=(0.55, 10.35), z0=2.95, z1=7.40,
         demi0=1.95, demi1=0.70, prof0=2.20, prof1=0.85,
         facettes=5, rotation=1.1, biseau=1.30, etages=6,
         matiere_bas="MAT_CaveRock_Face", matiere_haut="MAT_CaveRock_Collar"),
    # LES DEUX MASSES SUIVANTES SONT DU CÔTÉ DE L'APPROCHE, et elles sont
    # nées d'une capture, pas d'une intention. Contrefort et couronne sont
    # tous deux au NORD ; la vue d'approche du joueur vient du sud-est et
    # ne montrait donc qu'un dôme nu. Une silhouette « à trois masses »
    # qui n'existe que vu de dos ne remplit pas l'exigence : c'est la face
    # que le joueur regarde qui doit la porter.
    dict(nom="SM_WaterfallCave_Visiere",
         base=(1.30, -1.90), sommet=(0.30, -2.85), z0=3.10, z1=5.55,
         demi0=2.05, demi1=1.05, prof0=1.45, prof1=0.80,
         facettes=6, rotation=0.75, biseau=1.05, etages=5,
         matiere_bas="MAT_CaveRock_Collar", matiere_haut="MAT_CaveRock_Face"),
    dict(nom="SM_WaterfallCave_Eperon",
         base=(-4.55, -0.60), sommet=(-3.60, -1.40), z0=-1.60, z1=3.05,
         demi0=1.55, demi1=0.85, prof0=1.85, prof1=1.00,
         facettes=5, rotation=2.35, biseau=0.75, etages=5,
         matiere_bas="MAT_CaveRock_Base", matiere_haut="MAT_CaveRock_Face"),
)
# Marge minimale entre une masse annexe et l'enveloppe de la cavité. Une
# masse qui mord la cavité y entrerait comme un bloc parasite, ce que le
# lead a rejeté deux fois sous le nom de « plaques ».
MARGE_ANNEXE_CAVITE_M = 0.35

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
EPAISSEUR_MIN_M = 0.80          # nulle part une plaque
EPAISSEUR_MIN_COLLERETTE_M = 0.60
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
            niveau = round(z / PAS_STRATE) * PAS_STRATE
            z += (niveau - z) * FORCE_STRATE
            # Corniche : saillie latérale dans une bande de hauteur, du
            # côté du soleil. N'ajoute que de la matière — elle ne peut
            # donc jamais amincir la roche.
            portee = max(0.0, math.cos(tf - CORNICHE_THETA)) ** 3.0
            bande_c = math.exp(-(((v ** 0.85) - CORNICHE_HAUT)
                                 / CORNICHE_ETAL) ** 2.0)
            n += CORNICHE_AMPL * portee * bande_c * (1.0 if u >= 0.0 else -1.0)
        else:
            z = jupe * v * (0.85 + 0.3 * w) * CIRCONSCRIT_MASSIF
        return Vector((ax + n * normale.x, ay + n * normale.y, z + denivele))

    return polygonal([sommet(c) for c in coins(FACETTES_MASSIF, rotation)],
                     rotation, FACETTES_MASSIF, segments)


def phases(nombre, graine):
    """Phases de relief interpolées le long de l'axe : le bruit doit être
    COHÉRENT d'une station à l'autre, sinon les nervures ne courent pas le
    long du rocher et la surface bouillonne."""
    return [graine * 0.37 + i * 0.61 for i in range(nombre)]


def masse_annexe(config):
    """Un loft autonome, fermé et facetté — une masse rocheuse à part.

    Rend (sommets, faces, familles). Section polygonale irrégulière,
    inclinée entre sa base et son sommet, et coupée en BISEAU au dernier
    étage : c'est ce qui donne la « couronne rompue » plutôt qu'un dôme.
    """
    bx, by = config["base"]
    sx, sy = config["sommet"]
    etages = config["etages"]
    nb = config["facettes"]
    sommets, faces, familles = [], [], []
    bases = []
    for e in range(etages):
        t = e / float(etages - 1)
        cx = bx + (sx - bx) * t
        cy = by + (sy - by) * t
        z = config["z0"] + (config["z1"] - config["z0"]) * t
        demi = config["demi0"] + (config["demi1"] - config["demi0"]) * t
        prof = config["prof0"] + (config["prof1"] - config["prof0"]) * t
        base = len(sommets)
        bases.append(base)
        for k in range(nb):
            theta = TAU * k / nb + config["rotation"] + 0.17 * e
            # Rayon irrégulier mais COHÉRENT le long de l'axe : le terme
            # sans dépendance en `e` fait courir l'arête d'un étage à
            # l'autre, sinon la masse bouillonne au lieu d'avoir des faces.
            r = 1.0 + 0.20 * math.sin(2.0 * theta + 0.8) \
                + 0.12 * math.sin(3.0 * theta + 1.9 + 0.25 * e)
            dz = 0.0
            if e == etages - 1:
                # Biseau : le sommet est tranché en pente, pas arrondi.
                dz = -config["biseau"] * (0.5 + 0.5 * math.cos(theta - 0.9))
            sommets.append(Vector((cx + demi * r * math.cos(theta),
                                   cy + prof * r * math.sin(theta),
                                   z + dz)))
    for e in range(etages - 1):
        a, b = bases[e], bases[e + 1]
        for k in range(nb):
            k2 = (k + 1) % nb
            faces.append((a + k, a + k2, b + k2, b + k))
            familles.append(config["matiere_bas"] if e < etages // 2
                            else config["matiere_haut"])
    faces.append(tuple(range(bases[0], bases[0] + nb)))
    familles.append(config["matiere_bas"])
    faces.append(tuple(range(bases[-1], bases[-1] + nb)))
    familles.append(config["matiere_haut"])
    return sommets, faces, familles


def controle_annexe_hors_cavite(config):
    """Une masse annexe ne doit pas mordre la cavité.

    Elle y entrerait comme un bloc parasite — exactement le défaut
    « plaques » rejeté deux fois. On compare chaque sommet de la masse à
    l'enveloppe de la cavité, interpolée le long de l'axe.
    """
    sommets, _, _ = masse_annexe(config)
    pire = 1e9
    for p in sommets:
        if p.z < -0.10:
            continue          # sous le plan de sol : la cavité n'y est pas
        for i in range(len(CAVITE) - 1):
            ax0, ay0, hw0, cle0 = CAVITE[i]
            ax1, ay1, hw1, cle1 = CAVITE[i + 1]
            d = Vector((ax1 - ax0, ay1 - ay0))
            if d.length < 1e-6:
                continue
            t = max(0.0, min(1.0, ((p.x - ax0) * d.x + (p.y - ay0) * d.y)
                             / d.length_squared))
            cx, cy = ax0 + d.x * t, ay0 + d.y * t
            hw = hw0 + (hw1 - hw0) * t
            cle = cle0 + (cle1 - cle0) * t
            if p.z > cle:
                continue      # au-dessus de la voûte : hors cavité
            pire = min(pire, math.hypot(p.x - cx, p.y - cy) - hw)
    return pire


def construire(segments, sag, jupe, retrait_lat, retrait_cle, graine=7.0):
    """Rend (sommets, faces, familles) — familles = étiquette par face."""
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
            z = 0.25 * (sommets[a + k].z + sommets[a + k2].z
                        + sommets[b + k].z + sommets[b + k2].z)
            # TROIS BANDES DE VALEUR, et ce n'est pas décoratif. La bouche
            # regardant l'est et le soleil étant à l'ouest, TOUT le flanc
            # visible depuis l'approche est en ombre propre : mesuré en
            # capture, la masse sortait d'un gris uniforme, sans pied ni
            # crête. L'éclairement ne peut donc pas fournir la hiérarchie —
            # c'est la MATIÈRE qui doit la porter (briefing §3.3). Le seuil
            # bas était à -0,10, c'est-à-dire SOUS le terrain : la bande
            # sombre n'était jamais visible.
            if z < 0.55:
                familles.append("MAT_CaveRock_Base")
            elif z > 3.10:
                familles.append("MAT_CaveRock_Collar")
            else:
                familles.append("MAT_CaveRock_Face")
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
    """Distance minimale entre peau intérieure et peau extérieure.

    On ne compare pas station à station (elles ne coïncident pas) : on
    construit un BVH de la SEULE peau du massif et on interroge chaque
    sommet de la cavité. C'est la vraie épaisseur de roche.
    """
    n_cav = len(CAVITE) * segments + 1
    peau_massif = bvh_depuis(obj, lambda p: all(i >= n_cav for i in p.vertices))
    mini, mini_collerette = 1e9, 1e9
    # OÙ, pas seulement COMBIEN. Un contrôle qui annonce « 0,51 m » sans dire
    # à quelle station ni à quel azimut oblige à deviner, et deviner coûte un
    # cycle Blender complet par hypothèse.
    ou, ou_collerette = None, None
    for i in range(n_cav):
        co = obj.data.vertices[i].co
        trouve = peau_massif.find_nearest(co)
        if trouve is None or trouve[0] is None:
            continue
        d = (trouve[0] - co).length
        station = i // segments
        azimut = math.degrees(TAU * (i % segments) / segments)
        if station <= 1:
            if d < mini_collerette:
                mini_collerette, ou_collerette = d, (station, azimut, co.z)
        else:
            if d < mini:
                mini, ou = d, (station, azimut, co.z)
    if ou is not None:
        print("[grotte] paroi la plus mince : station %d, azimut %.0f°, z %.2f"
              % ou)
    if ou_collerette is not None:
        print("[grotte] collerette la plus mince : station %d, azimut %.0f°, z %.2f"
              % ou_collerette)
    return mini, mini_collerette


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

    sommets, faces, familles = construire(
        SEGMENTS, SAG, SKIRT, 0.0, 0.0)
    grotte = objet("SM_WaterfallCave", sommets, faces, familles, True)

    s_col, f_col, fam_col = construire(
        SEGMENTS_COL, SAG, SKIRT_COL, COL_MARGE_LAT, COL_MARGE_CLE)
    collision = objet("COL_WaterfallCave", s_col, f_col, fam_col, False)

    # MASSES ANNEXES — voir le commentaire de `MASSES_ANNEXES` : les lobes
    # radiaux ont été construits, générés et capturés, et ils ne donnaient
    # encore qu'une miche. Une masse distincte doit être un volume distinct.
    annexes = []
    for config in MASSES_ANNEXES:
        marge = controle_annexe_hors_cavite(config)
        # NE PAS IMPRIMER UN FAUX CHIFFRE. Quand aucun sommet de la masse ne
        # tombe dans la bande de hauteur de la cavité, le contrôle n'a rien
        # comparé : il rendait « 1000000000.00 m », qui se lit comme une
        # marge énorme alors que c'est une NON-MESURE. La visière et la
        # couronne sont dans ce cas — entièrement au-dessus de la voûte —
        # et c'est un dégagement légitime, mais il doit se dire ainsi.
        if marge > 1e8:
            print("[grotte] %s : entierement hors de la bande de la cavite "
                  "(aucun sommet a comparer)" % config["nom"])
        else:
            print("[grotte] %s : %.2f m de la cavite au plus pres"
                  % (config["nom"], marge))
        if marge < MARGE_ANNEXE_CAVITE_M:
            print("[grotte] ERREUR: %s mord la cavite (%.2f m < %.2f m) — "
                  "elle y entrerait comme un bloc parasite"
                  % (config["nom"], marge, MARGE_ANNEXE_CAVITE_M))
            return 2
        s_a, f_a, fam_a = masse_annexe(config)
        annexes.append(objet(config["nom"], s_a, f_a, fam_a, True))

    for obj in [grotte, collision] + annexes:
        obj.location = (0.0, 0.0, 0.0)
        obj.scale = (1.0, 1.0, 1.0)

    tris = sum(len(p.vertices) - 2 for p in grotte.data.polygons)
    tris_col = sum(len(p.vertices) - 2 for p in collision.data.polygons)
    mini_z, maxi_z, _ = controle_assise(grotte)
    print("[grotte] visuel %d faces (%d tris), collision %d faces (%d tris)"
          % (len(grotte.data.polygons), tris,
             len(collision.data.polygons), tris_col))
    print("[grotte] emprise Z de %.2f m a %.2f m (jupe %.2f m sous le sol)"
          % (mini_z, maxi_z, -mini_z))

    for nom, obj in [("visuel", grotte), ("collision", collision)] \
            + [(o.name, o) for o in annexes]:
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

    mini, mini_col = controle_epaisseur(grotte, SEGMENTS)
    print("[grotte] epaisseur de roche : %.2f m en paroi, %.2f m en collerette"
          % (mini, mini_col))
    if mini < EPAISSEUR_MIN_M:
        print("[grotte] ERREUR: paroi de %.2f m < %.2f m — plaque vue par la "
              "tranche" % (mini, EPAISSEUR_MIN_M))
        return 2
    if mini_col < EPAISSEUR_MIN_COLLERETTE_M:
        print("[grotte] ERREUR: collerette de %.2f m < %.2f m"
              % (mini_col, EPAISSEUR_MIN_COLLERETTE_M))
        return 2

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
    # elles vivent dans un autre fichier, et le sol vient de bouger deux
    # fois (palier, tablette d'alcôve).
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
