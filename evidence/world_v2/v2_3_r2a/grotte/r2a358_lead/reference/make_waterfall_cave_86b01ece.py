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
import random
import os
import sys
from fractions import Fraction
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
# CENTERLINE R2a-3.5 — établie par l'agent galerie, mesurée par la sonde
# `probe_envelope_vs_centerline.py`, et validée AVANT d'être posée ici :
# sous l'enveloppe actuelle elle a plus de toit que l'ancienne (+2,60 à
# +6,51 contre +1,98 à +5,14) ; sous l'enveloppe proto A v2 elle a +1,36
# (linteau) à +5,39. Les deux mesures sont dans
# `evidence/.../r2a35_fusion/`.
#
# CE QUI CHANGE ET POURQUOI. L'ancienne galerie filait vers +y sur 10,4 m
# et passait SOUS LES DEUX COLS de la silhouette — c'est le conflit que
# trois passes ont payé : épaissir pour la roche et creuser pour les
# masses tiraient sur la même pierre. La nouvelle tient en 5,05 m, coude
# de 42° à la station 2 puis cap tenu à 31° ± 1° : elle quitte l'axe des
# cols et se range sous la masse dominante.
#
# Le porche et le seuil ne bougent pas d'un millimètre : la bouche est
# figée, et c'est elle que le joueur voit.
CAVITE = [
    # ax     ay     hw     cle
    (0.00, -1.15, 1.90, 2.80),   # porche évasé, sol sous le terrain
    (0.00,  0.00, 1.70, 2.85),   # seuil — INCHANGÉ
    (0.22,  1.05, 1.75, 2.90),   # fin du vestibule : 1,07 m
    (1.00,  1.62, 2.10, 2.90),   # LE COUDE, 42°
    (1.82,  2.12, 2.60, 2.92),
    (2.62,  2.58, 3.00, 2.92),   # SALLE, sous la dominante
    (3.10,  2.88, 2.50, 2.80),
    (3.40,  3.06, 1.85, 2.45),   # alcôve / niche
    (3.58,  3.17, 1.30, 2.00),   # calotte du fond
]
CAVITE_APEX = (3.72, 3.25, 0.70)     # pointe de la calotte du fond
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
# MASSIF ne sert plus qu'au PROXY DE COLLISION (voir `construire()`), et il
# doit donc envelopper la NOUVELLE cavité. Ses stations suivent désormais la
# centerline, avec le même jeu latéral et de clé qu'avant ; les trois
# dernières prolongent la queue enterrée au nord-est, où la formation se
# perd dans le ressaut.
# R2a-3.5.6 — LE TRACÉ DU MASSIF NE SUIT PLUS CELUI DE LA CAVITÉ, ET C'EST
# LA CORRECTION DE 40 AUTO-INTERSECTIONS DE COLLISION.
#
# MESURÉ. `COL_WaterfallCave` portait 40 pénétrations exactes `enveloppe ×
# enveloppe`, dont l'enfoncement maximal de 0,457 m — 23 fois le seuil du
# livrable. Attribution : elles naissent INTÉGRALEMENT dans `construire()`
# (l'empreinte de la coque est identique aux sept étapes de la chaîne), et
# pas une seule ne vient de la peau de cavité, qui mesure `cav×cav = 0`.
#
# LA CAUSE EST INTRINSÈQUE, PAS ACCIDENTELLE. Le rayon latéral de
# l'enveloppe vaut `hw + jeu_lat`, soit 3,30 m à la station 1 et 3,60 m à la
# station 2. Le rayon de courbure du tracé y valait 2,37 m et 2,26 m. Un
# tube plus large que le virage qu'il suit SE TRAVERSE NÉCESSAIREMENT : le
# bord intérieur recule quand l'axe avance. Aucune subdivision ne le corrige.
# R2a-3.4 tenait ce rapport à 0,11 et 0,20 parce que sa galerie filait droit
# sur 10,4 m ; la galerie courte de R2a-3.5 l'a fait passer au-dessus de 1.
#
# POURQUOI ON PEUT LISSER SANS RIEN COÛTER. `MASSIF` porte ses PROPRES
# `ax, ay`, et `anneau_exterieur()` — son unique consommateur — n'a qu'un
# appelant : `construire()`. Cette table ne décrit donc QUE la coque de
# collision, jamais une surface rendue. Elle n'a pas à épouser la centerline
# de la cavité : elle doit seulement l'ENVELOPPER, et il lui reste pour cela
# 1,30 m de marge latérale minimale après lissage (mesurée à la station 1).
#
# CE QUI A ÉTÉ FAIT : lissage laplacien des positions, λ = 0,8, trois passes,
# stations 1 à 10. La visière (station 0) et la pointe de queue (station 11)
# ne bougent pas d'un millimètre ; le déplacement maximal est de 0,53 m, à la
# station 2. `hw`, `cle`, `jeu_lat` et `jeu_cle` sont INCHANGÉS — seul le
# chemin est adouci.
#
# RÉSULTAT MESURÉ, `evidence/.../r2a356_agentB/B6_reparation/` :
#   env×env  40 -> 0     cav×cav  0 -> 0     cav×env  28 -> 10
#   enfoncement maximal  0,457 m -> 0,228 m
#   rapport rayon/courbure maximal  2,73 -> 1,15
# Le zéro sur `env×env` tient sur un PLATEAU (λ de 0,6 à 1,0, 3 à 20 passes) :
# ce n'est pas un réglage en équilibre instable.
#
# Les 10 `cav×env` restants ne se corrigent pas ici : ils demandent
# d'épaissir l'enveloppe vers l'extérieur, ce qui est un autre périmètre.
MASSIF = [
    # ax     ay    hw_ref cle_ref  jeu_lat jeu_cle
    (0.00, -1.15, 1.90, 2.80, 1.70, 1.55),   # visière saillante — INCHANGÉE
    (0.25, -0.17, 1.70, 2.85, 1.60, 1.45),   # retrait derrière la visière
    (0.63,  0.71, 1.75, 2.90, 1.85, 1.55),
    (1.14,  1.44, 2.10, 2.90, 2.10, 2.15),
    (1.77,  2.01, 2.60, 2.92, 2.00, 1.68),
    (2.37,  2.44, 3.00, 2.92, 2.10, 2.22),   # au-dessus de la salle
    (2.90,  2.77, 2.50, 2.80, 1.95, 1.62),
    (3.31,  3.04, 1.85, 2.45, 2.15, 1.70),
    (3.66,  3.33, 1.30, 2.00, 1.95, 1.35),
    (3.99,  3.64, 0.90, 1.45, 1.60, 1.55),   # ressaut de queue
    (4.34,  4.00, 0.60, 1.00, 1.35, 0.90),
    (4.70,  4.40, 0.35, 0.60, 0.95, 0.70),   # pointe — INCHANGÉE
]
MASSIF_APEX = (5.00, 4.75, 1.20)

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
    # R2a-3.5.1 — À PARTIR D'ICI LA SECTION EST FRANCHEMENT DISSYMÉTRIQUE, ET
    # CE N'EST PAS UN CHOIX DE DESSIN : c'est la roche disponible qui la
    # dicte. Voir le pavé « L'ASYMÉTRIE EST DÉRIVÉE » sous cette table.
    (0.56, 1.15, -0.24),   # fin du vestibule : ici c'est le côté -n qui manque
    (0.97, 1.05, 0.10),    # LE COUDE, largeur totale inchangée (4,24 m)
    (1.68, 0.41, 0.16),    # le vide bascule côté -n, largeur totale inchangée
    (1.69, 0.33, 0.08),    # SALLE, déportée sous la masse et non centrée
    (1.69, 0.25, -0.06),   # l'alcôve élargit déjà ce côté : elle s'y ajoute
    (1.65, 0.27, -0.12),
    (1.61, 0.25, -0.10),
]

# L'ASYMÉTRIE EST DÉRIVÉE D'UNE MESURE, PAS RÉGLÉE À VUE.
#
# LE DÉFAUT. 385 percées confirmées par `tools/probe_cave_openings.py`,
# épaisseur de paroi 0,11 m pour 0,80 exigés, et la sonde de surfaces les
# attribue toutes à une seule d'entre elles : `paroi_plus_x`, 413 cases
# ouvertes sur 2470 quand `paroi_moins_x` en a 4 sur 2470. Le flanc `+normale`
# de la galerie sort de la formation ; l'autre est enterré sous 7 à 8,6 m.
#
# CE QUI A ÉTÉ ESSAYÉ AVANT, ET MESURÉ. Translater la galerie entière de
# 1,8 m vers `-normale` : trois indicateurs de bord s'améliorent (paroi
# 0,11 -> 0,37 · « le sol voit le ciel » 2 points -> 0 · plancher +0,956 ->
# +0,701) et les percées ne bougent pas — 385 -> 390. Déplacer une section
# SYMÉTRIQUE ne peut pas réconcilier deux flancs dont l'un a 0,07 m de marge
# et l'autre 7,63 : il faut que la section cesse d'être symétrique.
#
# LA MESURE QUI DÉCIDE. `tools/blender/probe_cave_asym_budget.py` reconstruit
# la roche AVANT soustraction et rejoue `controle_epaisseur()` par
# arithmétique d'intervalles. Le « avant soustraction » est le point : une
# mesure prise sur le maillage FINAL est confondue, parce que là où la galerie
# a percé, la peau extérieure a déjà été emportée et le rayon ne trouve plus
# rien. Un premier relevé pris de cette façon concluait « aucune roche du côté
# +normale aux stations 4 à 6, donc aucune réduction ne peut fermer » — et il
# était faux. Roche réellement disponible depuis l'axe, côté `+n` :
#
#     station 2  2,96 m      station 5  1,69 m
#     station 3  2,69 m      station 6  1,44 m
#     station 4  2,23 m      station 7  1,32 m
#
# Elle existe ; c'est le vide qui la dépassait — 3,48 m de demi-largeur à la
# station 5 pour 1,69 m de roche.
#
# LES DEUX RECHERCHES QUI ONT ÉCHOUÉ, ET CE QU'ELLES ONT APPRIS. Bissection
# par station : oscille. Les rayons du contrôle partent dans le plan MONDE
# `(cos θ, 0, sin θ)`, or près du coude la galerie file elle-même vers +x — un
# rayon d'azimut 0° parti de la station 2 descend LE LONG de la galerie et
# ressort par le flanc de la salle (mesuré : `r_in` = 3,99 m pour une
# demi-largeur propre de 1,58 m). Le minimum d'une station ne dépend donc pas
# de son propre facteur. Échelle globale unique : impossible des deux côtés,
# le côté mince demandant une réduction et le côté épais une réduction à la
# station 2 ET un élargissement ailleurs. Ce qui converge : tout au plancher —
# état dont on a MESURÉ qu'il est réalisable, 0,89 m côté `+n` — puis
# croissance gloutonne station par station contre le minimum GLOBAL. Réduire
# un facteur ne peut qu'ajouter de la roche : la croissance est monotone.
#
# CE QUI EST RETENU, ET LA RÈGLE QUI L'A TAILLÉ. Le côté mince n'est jamais
# élargi au-delà de sa valeur d'origine, et la largeur qu'on lui retire est
# rendue au côté épais. La largeur totale de la section est donc conservée :
#
#     st | demi-vide +n     | gauche       | largeur totale
#      2 | 1,57 -> 2,01 m   | 1,12 -> 0,56 | 3,54 -> 2,99 m
#      3 | 2,31 -> 2,21 m   | 0,92 -> 0,97 | 4,24 -> 4,24 m
#      4 | 2,96 -> 1,07 m   | 0,95 -> 1,68 | 5,43 -> 5,43 m
#      5 | 3,48 -> 0,99 m   | 1,06 -> 1,69 | 6,66 -> 6,06 m
#      6 | 2,45 -> 0,62 m   | 1,00 -> 1,69 | 4,95 -> 4,85 m
#      7 | 1,70 -> 0,50 m   | 1,00 -> 1,65 | 3,55 -> 3,55 m
#      8 | 1,17 -> 0,33 m   | 0,96 -> 1,61 | 2,42 -> 2,42 m
#
# La station 2 fait exception à la règle du côté mince, et pour une cause
# mesurée : là, la roche manque du côté `-n` (2,34 m seulement) et abonde du
# côté `+n` (2,96 m). C'est le PLAFOND qui bride la bande — le linteau y
# penche de -0,24 — et non la roche. Le vide y est donc rendu au côté `+n`
# jusqu'à ce que la bande du gabarit repasse le contrat : 1,70 -> 1,95 m.
#
# LA DEMI-LARGEUR DE 3,48 m N'ÉTAIT PAS LE GABARIT DU JOUEUR. La réduire du
# côté mince ne réduit donc pas le contrat de traversée : c'est la BANDE utile
# qui le porte, et `controle_gabarit()` la mesure désormais pour de bon —
# 1,95 à 4,00 m selon la station, pour 1,90 exigés.
#
# LES STATIONS 0 ET 1 NE BOUGENT PAS D'UN MILLIMÈTRE : la bouche est gelée,
# ancre et cadrage compris. Leur déficit propre est consigné tel quel dans le
# rapport de passe, il n'est pas corrigé ici.

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
PALIER = (0.00, 0.00, 0.02, 0.06, 0.10, 0.16, 0.34, 0.56, 0.70)

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
## Rapport maximal entre la plus grande et la plus petite composante de
## `ech`. Voir la démonstration dans `poser_rocher()` : c'est ce qui permet
## d'échapper au rapport hauteur/largeur unique du module sans étirer un
## rocher sculpté au point qu'il cesse de lire comme une roche.
ANISOTROPIE_MAX = 2.00

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
# R2a-3.4 — TROIS AMAS D'EMPRISES INÉGALES, ET LA CAUSE QU'ILS CORRIGENT.
#
# LE REJET : « les silhouettes 55° et 100° évoquent une forteresse crénelée ;
# les masses principales lisent comme des tours rocheuses répétées ;
# l'asymétrie de largeur recherchée n'existe pas ». Mesuré par
# `tools/measure_silhouette_masses.py` sur l'azimut réel d'approche : quatre
# sommets de largeur 1,07 · 1,12 · 1,12 · 1,26 m, coefficient de variation
# 0,06 — moins de 7 % d'écart entre eux.
#
# LA CAUSE, ET ELLE SE MESURE. La chaîne modèle → Godot (`export_yup`) →
# `LACET_DEG = 45` → caméra orthogonale de `capture_silhouette.gd` donne
# x_ecran = 0,9847·X − 0,1737·Y à 55°. À l'azimut d'approche, la silhouette
# lit donc presque exactement le X du modèle. En projetant les roches posées
# sur 200 colonnes, la formation rejetée donnait :
#
#     crête portée par UNE SEULE roche (2e à plus de 0,45 m dessous) : 81 %
#     porteurs du faîte de chaque masse : 1 · 1 · 1
#
# Et la mesure qui ferme le dossier : le faîte sculpté de `template-detail`
# fait **0,93 m de large à 0,60 m sous son sommet, quel que soit l'axe de
# projection** (mesuré sur ses 600 sommets, axes 0°, 45°, 90°). Tant qu'une
# roche porte seule un sommet, la largeur de ce sommet vaut 0,93 × son
# échelle. Comme l'échelle variait de 1,10 à 1,35, les quatre sommets ne
# POUVAIENT PAS différer de plus de 7 % : le cv 0,06 était arithmétique, et
# aucune repose ne l'aurait changé.
#
# TROIS DÉCOUVERTES ONT ÉTÉ NÉCESSAIRES, chacune après une mesure qui a
# contredit l'hypothèse précédente. Elles sont écrites ici parce que les
# deux premières se reprennent naturellement, et coûtent chacune une passe.
#
#   1. LE PAS DE LA RANGÉE SE MESURE EN X ÉCRAN, PAS EN MÈTRES MODÈLE.
#      Un faîte d'amas est l'union de plusieurs roches dont les sommets sont
#      à la même cote et dont les plateaux se chevauchent. Le chevauchement
#      tient si le pas projeté est inférieur à la largeur de faîte du module
#      (0,93 × ech). Le reste suit.
#
#   2. LES INCLINAISONS D'UNE MÊME RANGÉE DOIVENT ÊTRE DE MÊME SIGNE.
#      Premier jet : `tangage` et `roulis` alternés ±6°, pour la variété.
#      Mesuré — un roulis de ±6° sur une roche de 5,4 m déplace son sommet
#      de ±0,28 m ; deux voisines inclinées en sens opposés voient donc
#      l'écart entre leurs plateaux DOUBLER, et un creux de 1,05 m s'ouvre
#      là où le calcul en promettait 0,15. C'est ce creux qui coupait la
#      dominante en deux masses. Les rangées de faîte gardent désormais
#      `lacet` voisin de 0 et des inclinaisons toutes positives.
#
#   3. UNE SEULE DIRECTION DE RANGÉE SE PROJETTE PAREIL AUX DEUX AZIMUTS.
#      Une rangée de direction (dX, dY) se projette avec le facteur
#      |0,9847·dX − 0,1737·dY|/|d| à 55° et |0,5736·dX − 0,8192·dY|/|d| à
#      100°. Balayage :
#
#        (1 ;  0,00) → 0,985 / 0,574   écart 42 %
#        (1 ; −0,30) → 0,993 / 0,785   écart 21 %
#        (1 ; −0,64) → 0,924 / 0,924   écart  0 %
#        (1 ; −0,90) → 0,848 / 0,974   écart 13 %
#
#      L'épaule courait d'abord sur (1 ; −0,94) : régler la vue d'approche
#      dérégle le trois-quarts, et inversement — j'ai perdu quatre passes
#      là-dessus. La dominante et le contrefort sont posés sur la direction
#      invariante ; l'épaule reste légèrement hors d'elle, ce qui l'élargit
#      au trois-quarts (6,42 m contre 5,66) sans casser son col, et c'est
#      voulu : mettre les TROIS rangées sur la même droite ferait de la
#      formation un mur de 18 m de long et 4 m de large.
#
# LE LEVIER, ET IL NE DÉPLACE AUCUNE BORNE. `poser_rocher()` accepte déjà
# `ech` en triplet et vérifie chaque composante contre [0,55 ; 1,55]. Un
# triplet sort du rapport hauteur/largeur unique du module (1,65) sans
# ajouter de module au kit. Il sert ici à deux choses : élargir les roches
# de faîte, et surtout ENFONCER LEUR FOND. Mesuré : à `ez = 0,80` le fond
# plat d'une roche de faîte se retrouvait à 3,82 m, au-dessus du flanc de
# son socle, et pendait en surplomb — `controle_plage_plane` a rendu
# 12,05 m² centrés en (−5,52 ; 5,98 ; 3,77), pour un seuil de 12,00.
# À `ez = 1,25` le fond descend à 1,87 m, sous le flanc du socle (2,17 m).
# L'anisotropie est bornée à 2,0 dans `poser_rocher()`.
#
# CE QUE ÇA DONNE, MESURÉ AUX DEUX AZIMUTS ET AUX QUATRE ENTAILLES :
#
#                  emprises (m)        porteurs du faîte    cols (m)
#   avant  55°   1,14 · 1,07 · 1,14      1 · 1 · 1        1,98 / 10,39
#   après  55°   5,66 · 3,58 · 2,17      8 · 5 · 4         1,67 / 2,53
#   après 100°   6,42 · 3,64 · 2,22      8 · 5 · 4         1,51 / 2,47
#
# Trois masses à 0,60 · 0,90 · 1,20 · 1,50 m d'entaille : la lecture n'est
# pas sur le fil d'un seuil. Faîte dominant décentré de 14,2 % (55°) et
# 13,0 % (100°) du milieu de l'emprise, et il n'est plus au-dessus de la
# bouche — c'est ce qui l'empêche de lire en cheminée, davantage que sa
# largeur.
#
# CE QUI EST DÉLIBÉRÉMENT INCHANGÉ. Les roches qui encadrent la bouche
# (`Bouche_*`, `Seuil_*`, `Ouest_Piedroit`) gardent leur (x, y) au
# centimètre : une autre session travaille sur le seuil, et deux diffs sur
# les mêmes lignes coûtent une fusion. Les quatre roches arrière
# (`Arriere_Ouest/Angle/Est/Mur`) gardent aussi leur pose — elles remblaient
# l'arrière de l'alcôve, stations 5 à 8, azimut 180°, où la matière ne doit
# pas être réduite. `Arriere_Cap` y descend même de 2,30 à 1,17 : elle en
# ajoute sous la voûte, et n'en retire qu'au-dessus de 5,95 m.
ROCHERS = (
    # ============ AMAS 1 — ÉPAULE GAUCHE : basse et large ================
    # SEPT roches de faîte. Leur pas est calculé pour étaler l'amas SUR LES
    # DEUX vues à la fois, ce qui n'est pas automatique : un pas (dX, dY)
    # se projette en 0,985·dX − 0,174·dY à 55° et en 0,574·dX − 0,819·dY à
    # 100°, et un mauvais couple annule l'un en gagnant l'autre. Ici
    # (dX, dY) = (+0,767 ; −0,72) donne 0,88 m à 55° et 1,03 m à 100° —
    # tous deux sous la largeur de faîte du module (1,30 m à cette échelle),
    # donc les creux entre voisines restent sous 0,20 m et l'union est UN
    # plateau, pas sept dents.
    # `ech` = (1,40 ; 1,36 ; 0,80) : le rocher fait 3,70 × 3,82 × 3,48 m,
    # rapport hauteur/largeur 0,94 au lieu des 1,65 natifs. Aplatir ne sert
    # pas qu'à élargir — ça aplatit aussi le sommet, donc ça réduit le creux
    # entre deux voisines.
    dict(nom="EpauleG_Faite_1", mod="R", pose=( -6.47,  6.80,  1.87),
         lacet=4, tangage=3, roulis=2, ech=(1.40, 1.36, 1.25),
         rang="majeur", amas="epaule_gauche"),
    dict(nom="EpauleG_Faite_2", mod="R", pose=( -5.95,  6.31,  1.87),
         lacet=357, tangage=5, roulis=4, ech=(1.40, 1.36, 1.25),
         rang="majeur", amas="epaule_gauche"),
    dict(nom="EpauleG_Faite_3", mod="R", pose=( -5.42,  5.82,  1.87),
         lacet=6, tangage=4, roulis=3, ech=(1.40, 1.36, 1.25),
         rang="majeur", amas="epaule_gauche"),
    dict(nom="EpauleG_Faite_4", mod="R", pose=( -4.90,  5.33,  1.87),
         lacet=354, tangage=6, roulis=5, ech=(1.40, 1.36, 1.25),
         rang="majeur", amas="epaule_gauche"),
    dict(nom="EpauleG_Faite_5", mod="R", pose=( -4.38,  4.84,  1.87),
         lacet=8, tangage=3, roulis=2, ech=(1.40, 1.36, 1.25),
         rang="majeur", amas="epaule_gauche"),
    dict(nom="EpauleG_Faite_6", mod="R", pose=( -3.85,  4.34,  1.87),
         lacet=352, tangage=7, roulis=6, ech=(1.40, 1.36, 1.25),
         rang="majeur", amas="epaule_gauche"),
    dict(nom="EpauleG_Faite_7", mod="R", pose=( -3.33,  3.85,  1.87),
         lacet=3, tangage=4, roulis=3, ech=(1.40, 1.36, 1.25),
         rang="majeur", amas="epaule_gauche"),
    dict(nom="EpauleG_Faite_8", mod="R", pose=( -2.81,  3.36,  1.87),
         lacet=359, tangage=5, roulis=4, ech=(1.40, 1.36, 1.25),
         rang="majeur", amas="epaule_gauche"),
    # Socles enterrés. Faîte des socles 5,02 m, fond des roches de faîte
    # 3,82 m : enfoncement 1,20 m, au-dessus du mètre exigé pour que la
    # seule face plate du module reste intérieure.
    dict(nom="EpauleG_Socle_1", mod="R", pose=( -6.30,  6.55, -1.50),
         lacet=24, tangage=5, roulis=-4, ech=(1.45, 1.42, 1.50),
         rang="majeur", amas="epaule_gauche"),
    dict(nom="EpauleG_Socle_2", mod="R", pose=( -5.50,  5.80, -1.50),
         lacet=118, tangage=-6, roulis=3, ech=(1.45, 1.42, 1.50),
         rang="majeur", amas="epaule_gauche"),
    dict(nom="EpauleG_Socle_3", mod="R", pose=( -4.70,  5.05, -1.50),
         lacet=65, tangage=4, roulis=5, ech=(1.45, 1.42, 1.50),
         rang="majeur", amas="epaule_gauche"),
    dict(nom="EpauleG_Socle_4", mod="R", pose=( -3.90,  4.29, -1.50),
         lacet=200, tangage=-5, roulis=6, ech=(1.45, 1.42, 1.50),
         rang="majeur", amas="epaule_gauche"),
    dict(nom="EpauleG_Socle_5", mod="R", pose=( -3.10,  3.54, -1.50),
         lacet=142, tangage=6, roulis=-3, ech=(1.45, 1.42, 1.50),
         rang="majeur", amas="epaule_gauche"),

    # ============ AMAS 2 — DOMINANTE : haute, et DÉCENTRÉE ===============
    # CINQ roches de faîte, pour une emprise VOLONTAIREMENT plus étroite que
    # l'épaule : deux masses larges de même largeur ne sont pas « nettement
    # inégales », et c'est le reproche exact reçu.
    # Son pas (dX, dY) = (+0,867 ; −0,55) rend 0,95 m sur les DEUX azimuts :
    # le premier jet, qui suivait la galerie vers le fond, donnait 0,95 m à
    # 55° et −0,31 m à 100° — les cinq roches s'y superposaient en une
    # colonne de 0,9 m, et la dominante lisait en tour sur la seconde vue.
    # La hauteur ne vient PAS d'un rocher dressé mais de trois étages
    # enfouis (socle 5,02 · étage 7,35 · faîte 9,50), dont seul le dernier
    # affleure, et ce dernier est APLATI (ez = 0,78).
    dict(nom="Dominante_Faite_1", mod="R", pose=(  1.48,  3.20,  4.07),
         lacet=5, tangage=4, roulis=3, ech=(1.25, 1.20, 1.25),
         rang="majeur", amas="dominante"),
    dict(nom="Dominante_Faite_2", mod="R", pose=(  1.98,  2.88,  4.07),
         lacet=358, tangage=6, roulis=5, ech=(1.25, 1.20, 1.25),
         rang="majeur", amas="dominante"),
    dict(nom="Dominante_Faite_3", mod="R", pose=(  2.48,  2.57,  4.07),
         lacet=7, tangage=3, roulis=2, ech=(1.25, 1.20, 1.25),
         rang="majeur", amas="dominante"),
    dict(nom="Dominante_Faite_4", mod="R", pose=(  2.98,  2.25,  4.07),
         lacet=356, tangage=5, roulis=4, ech=(1.25, 1.20, 1.25),
         rang="majeur", amas="dominante"),
    dict(nom="Dominante_Faite_5", mod="R", pose=(  3.48,  1.93,  4.07),
         lacet=3, tangage=7, roulis=6, ech=(1.25, 1.20, 1.25),
         rang="majeur", amas="dominante"),
    dict(nom="Dominante_Etage_1", mod="R", pose=(  1.40,  3.30,  1.05),
         lacet=42, tangage=5, roulis=-6, ech=(1.30, 1.26, 1.45),
         rang="majeur", amas="dominante"),
    dict(nom="Dominante_Etage_2", mod="R", pose=(  2.14,  2.83,  1.05),
         lacet=310, tangage=-6, roulis=4, ech=(1.30, 1.26, 1.45),
         rang="majeur", amas="dominante"),
    dict(nom="Dominante_Etage_3", mod="R", pose=(  2.88,  2.36,  1.05),
         lacet=96, tangage=4, roulis=-5, ech=(1.30, 1.26, 1.45),
         rang="majeur", amas="dominante"),
    dict(nom="Dominante_Etage_4", mod="R", pose=(  3.62,  1.89,  1.05),
         lacet=250, tangage=-5, roulis=3, ech=(1.30, 1.26, 1.45),
         rang="majeur", amas="dominante"),
    dict(nom="Dominante_Appui_1", mod="R", pose=(  3.60,  1.90, -1.45),
         lacet=214, tangage=6, roulis=-3, ech=(0.95, 0.92, 1.30),
         rang="majeur", amas="dominante"),
    dict(nom="Dominante_Socle_1", mod="R", pose=(  1.60,  2.90, -1.50),
         lacet=150, tangage=-4, roulis=2, ech=(1.45, 1.42, 1.50),
         rang="majeur", amas="dominante"),
    dict(nom="Dominante_Socle_2", mod="R", pose=(  2.70,  2.20, -1.50),
         lacet=20, tangage=6, roulis=-3, ech=(1.45, 1.42, 1.50),
         rang="majeur", amas="dominante"),
    dict(nom="Dominante_Socle_3", mod="R", pose=(  3.80,  1.51, -1.50),
         lacet=286, tangage=-5, roulis=4, ech=(1.45, 1.42, 1.50),
         rang="majeur", amas="dominante"),

    # ========== AMAS 3 — CONTREFORT DROIT : petit et en retrait ==========
    # Trois roches : emprise 2,2 m, soit trois fois moins que l'épaule.
    # « En retrait » se lit par trois moyens cumulés, dont aucun n'est la
    # couleur — plus petit, plus bas de 2,45 m que la dominante, et séparé
    # d'elle par le plus profond des deux cols.
    dict(nom="ContrefortD_Faite_1", mod="R", pose=(  6.05,  0.55,  1.83),
         lacet=6, tangage=4, roulis=3, ech=(1.05, 1.02, 1.20),
         rang="majeur", amas="contrefort_droit"),
    dict(nom="ContrefortD_Faite_2", mod="R", pose=(  6.42,  0.31,  1.83),
         lacet=356, tangage=6, roulis=5, ech=(1.05, 1.02, 1.20),
         rang="majeur", amas="contrefort_droit"),
    dict(nom="ContrefortD_Faite_3", mod="R", pose=(  6.79,  0.08,  1.83),
         lacet=9, tangage=3, roulis=2, ech=(1.05, 1.02, 1.20),
         rang="majeur", amas="contrefort_droit"),
    dict(nom="ContrefortD_Faite_4", mod="R", pose=(  7.16, -0.16,  1.83),
         lacet=353, tangage=5, roulis=4, ech=(1.05, 1.02, 1.20),
         rang="majeur", amas="contrefort_droit"),
    dict(nom="ContrefortD_Socle_1", mod="R", pose=(  6.10,  0.40, -1.40),
         lacet=300, tangage=-5, roulis=5, ech=(1.25, 1.22, 1.38),
         rang="majeur", amas="contrefort_droit"),
    dict(nom="ContrefortD_Socle_2", mod="R", pose=(  6.70,  0.02, -1.40),
         lacet=110, tangage=6, roulis=-4, ech=(1.25, 1.22, 1.38),
         rang="majeur", amas="contrefort_droit"),
    dict(nom="ContrefortD_Socle_3", mod="R", pose=(  7.30, -0.37, -1.40),
         lacet=220, tangage=4, roulis=3, ech=(1.25, 1.22, 1.38),
         rang="majeur", amas="contrefort_droit"),

    # ================ LES DEUX COLS, À DES COTES DIFFÉRENTES =============
    # Un col n'est pas un vide : c'est une selle dont la COTE décide de la
    # proéminence des amas qui l'encadrent. Deux cols de même profondeur
    # donnent deux entailles semblables, et la silhouette redevient
    # régulière — c'est une part du « rythme de forteresse » reproché.
    #
    # COL OUEST à ~5,95 m, tenu par `Arriere_Cap` : 1,35 m sous l'épaule.
    # Sa pose ne change pas — elle remblaie l'arrière de l'alcôve — seule
    # son échelle est aplatie, ce qui ne retire de la matière qu'au-dessus
    # de z = 5,8 m, très loin de la cavité.
    dict(nom="Arriere_Cap",   mod="R", pose=(-0.40,  7.00,  1.17),
         lacet=84,  tangage=-7, roulis=4,  ech=(1.05, 1.00, 1.10),
         rang="intermediaire"),
    dict(nom="Col_Ouest",     mod="R", pose=(-0.82,  4.55,  1.39),
         lacet=126, tangage=5,  roulis=-4, ech=(1.15, 1.10, 1.05),
         rang="intermediaire"),
    dict(nom="Col_Est",       mod="R", pose=( 3.83,  1.59, -1.05),
         lacet=244, tangage=-4, roulis=5,  ech=(1.10, 1.05, 1.30),
         rang="intermediaire"),
    # COL EST à ~4,58 m, tenu par `Arriere_Loin` : 2,47 m sous le contrefort.
    # À son échelle précédente (1,25 uniforme) il culminait à 6,54 m et ne
    # laissait au contrefort que 0,46 m de proéminence — sous toute entaille
    # de lecture, donc pas une masse du tout.
    dict(nom="Arriere_Loin",  mod="R", pose=( 5.40,  6.10,  1.10),
         lacet=20,  tangage=4,  roulis=6,  ech=(1.10, 1.05, 0.80),
         rang="intermediaire"),

    # ============ BOUCHE ET SEUIL — (x, y) INCHANGÉS ====================
    # Une autre session travaille sur le seuil ; deux diffs sur les mêmes
    # lignes coûtent une fusion. Seules l'échelle et la cote z bougent, et
    # seulement là où la ligne de crête l'exige.
    dict(nom="Bouche_Linteau", mod="R", pose=(0.55, -0.35,   1.60),
         lacet=6,   tangage=-4, roulis=2,  ech=1.35,
         rang="majeur", amas="dominante"),
    # JOUE ABAISSÉE. À z = 2,00 et ech = 1,35 elle culminait à 7,87 m, en
    # plein dans le col ouest : elle le comblait et soudait l'épaule à la
    # dominante en une seule masse. Elle reste la joue de la bouche ; elle
    # ne décide plus de la crête.
    dict(nom="Bouche_Joue",    mod="R", pose=(-0.60, 1.60,   2.00),
         lacet=172, tangage=-5, roulis=4,  ech=(1.52, 1.46, 0.90),
         rang="intermediaire"),
    dict(nom="Bouche_Visiere", mod="R", pose=(0.20, -1.85,   2.45),
         lacet=8,   tangage=-9, roulis=3,  ech=1.25,
         rang="majeur", amas="dominante"),
    # AUVENT ABAISSÉ pour la même raison : à 8,07 m il débordait le faîte de
    # la dominante par la gauche et comblait le col ouest.
    # AUVENT : NE PAS L'ÉLARGIR. Essayé à (1,52 ; 1,46 ; 0,95) pour rendre
    # de la marge au linteau ; `controle_amas` a refusé — « azimut 100 : les
    # deux cols entaillent de 1,51 et 1,64 m ». À 100° il se projette en
    # x écran +1,14, c'est-à-dire en plein dans le col est, et son faîte à
    # 5,43 m le comblait. La joue, elle, se projette sous la dominante et
    # peut grandir sans risque.
    dict(nom="Seuil_Auvent",   mod="R", pose=(-0.30, -1.60,  1.30),
         lacet=25,  tangage=-7, roulis=5,  ech=(1.30, 1.25, 0.95),
         rang="intermediaire"),
    dict(nom="Seuil_PiedroitDroit", mod="R", pose=( 2.70, -1.30, -1.00),
         lacet=32,  tangage=5,  roulis=4,  ech=1.25, rang="intermediaire"),
    dict(nom="Seuil_AvanceeGauche", mod="R", pose=(-2.20, -1.95, -1.30),
         lacet=205, tangage=-4, roulis=-6, ech=1.00, rang="intermediaire"),
    dict(nom="Seuil_Joue",    mod="R", pose=(3.40, 0.40,   0.30),
         lacet=128, tangage=6,  roulis=3,  ech=0.95, rang="intermediaire"),
    dict(nom="Seuil_Ecran",   mod="R", pose=(-3.45, -1.40,   0.60),
         lacet=96,  tangage=-6, roulis=5,  ech=1.10, rang="intermediaire"),
    dict(nom="Ouest_Piedroit", mod="R", pose=(-2.85, -0.90, -1.00),
         lacet=140, tangage=3,  roulis=-5, ech=1.30, rang="intermediaire"),

    # ==== MASSE ARRIÈRE — poses INCHANGÉES : elles remblaient l'arrière de
    # l'alcôve (stations 5 à 7, azimut 180°), zone où la matière ne doit pas
    # être réduite.
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

# ---------------------------------------------------------------------------
# LES TROIS AMAS, ET LE CONTRÔLE QUI LES MESURE.
#
# CE QUE MESURAIT L'ANCIEN OUTIL, ET POURQUOI ÇA NE SUFFISAIT PAS.
# `tools/measure_silhouette_masses.py` compte les masses d'une silhouette par
# proéminence topographique. Sur la formation rejetée il rendait, à l'azimut
# réel d'approche : 4 sommets de largeur 1,07 · 1,12 · 1,12 · 1,26 m, cv 0,06.
# Le compteur voyait bien le défaut — mais il vit dans un PNG capturé après
# export, donc trois quarts d'heure après la faute, et il ne dit pas d'où
# elle vient.
#
# CE QUI SE MESURE ICI, EN SECONDES, SUR LES VOLUMES SOURCES. Les roches
# posées sont projetées sur l'axe écran de la silhouette — la chaîne modèle
# → Godot (`export_yup`) → `LACET_DEG = 45` → caméra orthogonale de
# `capture_silhouette.gd` donne, à l'azimut a :
#
#     x_ecran = 0,7071 · [ X·(sin a + cos a) + Y·(cos a − sin a) ]
#
# soit 0,9847·X − 0,1737·Y à 55° et 0,5736·X − 0,8192·Y à 100°. On calcule
# ensuite l'enveloppe supérieure EXACTE par intersection des triangles avec
# le plan de chaque colonne — et non par échantillonnage de sommets : un
# module réparé porte 90 sommets, une colonne de 8 cm n'en contient souvent
# aucun, et le profil inventerait alors des encoches qui n'existent pas.
#
# LA MESURE QUI NOMME LA CAUSE : `porteurs du faîte`. Pour chaque masse, le
# nombre de roches DISTINCTES qui portent la crête à moins de
# `BANDE_FAITE_M` sous son sommet. Avant / après, aux deux azimuts :
#
#            largeurs des masses            porteurs du faîte
#   avant    1,14 · 1,07 · 1,14 m           1 · 1 · 1
#   après    6,59 · 3,67 · 2,42 m           6 · 4 · 3
#
# Un porteur unique par sommet EST le défaut : le faîte sculpté de
# `template-detail` mesure 0,93 m de large à 0,60 m sous son sommet, quel que
# soit l'axe de projection. Tant qu'une roche porte seule un sommet, la
# largeur de ce sommet vaut 0,93 × son échelle — et comme l'échelle variait
# de 1,10 à 1,35, les quatre sommets ne pouvaient pas différer de plus de
# 7 %. Aucune repose ne l'aurait changé ; il fallait faire porter chaque
# faîte par PLUSIEURS volumes qui se chevauchent.
#
# LES SEUILS SONT DES PLANCHERS DE NON-RÉGRESSION, PAS UNE PREUVE D'ART.
# Ils ont été fixés APRÈS avoir mesuré la composition obtenue, et c'est
# l'honnêteté minimale de le dire : ils garantissent qu'une passe suivante ne
# ramènera pas le créneau, ils ne prononcent aucun gate visuel. Le compteur
# de proéminences reste une TÉLÉMÉTRIE ; le jugement appartient au lead.
AZIMUTS_SILHOUETTE = (55.0, 100.0)
## Azimut réel d'approche (dérivé de la caméra de `capture_poi_batch`) et le
## trois-quarts à +45°. Ce ne sont pas des angles choisis : ce sont ceux des
## deux silhouettes que la revue a jugées.
COLONNES_SILHOUETTE = 220
## Entaille de lecture. Le balayage complet est imprimé — 0,60 à 1,50 — pour
## qu'aucun seuil ne soit choisi après coup ; celui-ci sert au verdict.
ENTAILLE_LECTURE_M = 0.90
## Bande sous le sommet d'une masse dans laquelle on compte les porteurs.
BANDE_FAITE_M = 0.45

## RANG DE L'ENVELOPPE. Les masses loftées qui portent la silhouette
## (`SM_ProtoA_*`) le déclarent ; tout le reste — kit de roches, gaine,
## semelle, dos d'alcôve — est un DÉTAIL DE SURFACE au sens de la couche 4.
RANG_ENVELOPPE = "enveloppe"

AMAS = (
    dict(cle="epaule_gauche",    modules_faite_max=0, rang_largeur=1),
    dict(cle="dominante",        modules_faite_max=0, rang_largeur=2),
    dict(cle="contrefort_droit", modules_faite_max=0, rang_largeur=3),
)
## Ordre attendu de gauche à droite en x écran, et nombre minimal de roches
## portant chaque faîte. `rang_largeur` déclare l'ordre des emprises :
## l'épaule est la plus large, le contrefort la plus étroite.
LARGEUR_RATIO_MIN = 2.00        # entre la plus large et la plus étroite
LARGEUR_ECART_MIN = 1.20        # entre deux emprises consécutives
DOMINANTE_AU_DESSUS_M = 1.50    # de combien la haute domine ses deux voisines
COLS_RATIO_MIN = 1.25           # entre les profondeurs des deux cols
COLS_ECART_MIN_M = 0.40         # et leur écart absolu
DECENTREMENT_MIN = 0.08         # du faîte dominant, en fraction de l'emprise

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
    # LA DERNIÈRE STATION N'ÉTAIT PAS GAINÉE, ET C'EST UNE DES TROIS CAUSES
    # DU TROU DU FOND. `i >= len(CAVITE) - 1` écartait la station 8
    # (y = 9,25), c'est-à-dire précisément là où la sonde mesure une
    # ouverture de 1,50 × 1,25 m. La calotte au-delà (`CAVITE_APEX`,
    # y = 9,55) n'était couverte par rien du tout : ni gaine, ni assise
    # (`ASSISE["y1"]` s'arrêtait à 9,10). On gaine donc TOUTES les stations
    # sauf le porche — qui est ouvert par construction — et on ajoute un
    # anneau de calotte derrière la dernière.
    # TOUTES LES STATIONS, ET UN ANNEAU DE CALOTTE DERRIÈRE LA DERNIÈRE.
    # LE PORCHE RESTE NON GAINÉ, ET CE N'EST PAS UN OUBLI. Gainer `i == 0`
    # pour rendre de la marge à la collerette a été essayé : `controle_amas`
    # a refusé — « azimut 100 : les deux cols entaillent de 1,51 et 1,64 m ».
    # L'arithmétique le dit sans ambiguïté : à l'azimut 45° l'anneau du
    # porche culmine à 4,87 m et le col est de la composition est à 4,58.
    # La bouche se trouve sous ce col ; épaissir l'une comble l'autre.
    stations = [("%d" % i, s[0], s[1], s[2], s[3], i)
                for i, s in enumerate(CAVITE)]
    ax_a, ay_a, r_a = CAVITE_APEX
    stations.append(("apex", ax_a, ay_a, r_a, r_a, len(CAVITE)))
    for etiquette, ax, ay, hw, cle, i in stations:
        if i == 0:
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
            # L'ALCÔVE CREUSAIT SANS REMBLAI, ET LA GAINE NE LE SAVAIT PAS.
            #
            # `anneau_interieur()` élargit la cavité de `ALCOVE["ampl"]` aux
            # stations 5 à 7, azimut 180°. La gaine, elle, se posait à
            # `hw + marge` : à l'alcôve, elle se retrouvait DANS la cavité,
            # donc entièrement retirée par la soustraction. Il ne restait
            # rien derrière la poche.
            #
            # Le lobe compensateur existait pourtant — `dos_alcove` dans
            # `LOBES` — mais `LOBES` est consommé par `anneau_exterieur()`,
            # qui depuis le pivot R2a-3.3 ne fabrique plus que la coque de
            # collision, jamais rendue. Le creusement a survécu au pivot, le
            # remblai non. On rend donc à la gaine la MÊME formule que celle
            # qui creuse, au lieu d'ajouter une roche à la main : si
            # `ALCOVE` change, le remblai suit.
            pousse = (ALCOVE["ampl"]
                      * le_long(i, ALCOVE["i0"], ALCOVE["i1"])
                      * fenetre(theta, ALCOVE["theta"], ALCOVE["dtheta"]))
            rayon_lat = hw + pousse + GAINE_MARGE_M
            rayon_haut = cle + GAINE_MARGE_M
            hauteur = MODULES["R"]["natif"][2] * GAINE_ECHELLE
            # LE DÉCALAGE LATÉRAL RESTE EN X, ET C'EST MESURÉ.
            #
            # J'ai essayé de le poser sur la normale, comme la semelle : la
            # géométrie du tube le demande, la galerie s'infléchissant de
            # 31°. Le contrôle d'épaisseur a répondu tout de suite —
            # 0,60 m en paroi contre 1,09 avant, donc REFUS — parce que
            # `controle_epaisseur()` tire ses rayons dans le plan
            # `(cos θ, 0, sin θ)`, c'est-à-dire en X lui aussi : déplacer la
            # gaine sur la normale l'éloigne de là où l'épaisseur se mesure.
            #
            # Les deux conventions ne peuvent pas être satisfaites en
            # déplaçant les mêmes roches. La couverture se gagne donc par la
            # DENSITÉ le long du chemin (voir l'échantillonnage ci-dessus),
            # pas en déplaçant ce qui tient déjà l'épaisseur.
            sortie.append(dict(
                nom="Gaine_%s_%03d" % (etiquette, azimut), mod="R",
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
## R2a-3.5 : RESTE À 1,15, ET TROIS LEVIERS ONT ÉTÉ ESSAYÉS PUIS MESURÉS
## AVANT DE LE LAISSER TRANQUILLE. Chacun déplaçait ce qui tenait déjà.
##
##   * poser la gaine le long de la NORMALE au chemin, comme la semelle :
##     REFUSÉ, épaisseur de paroi 0,60 m contre 1,09. `controle_epaisseur()`
##     tire ses rayons dans le plan `(cos θ, 0, sin θ)`, donc en X : mettre
##     la gaine sur la normale l'éloigne de là où l'épaisseur se mesure ;
##   * densifier les couronnes le long du chemin (pas 0,85 m, 126 roches) :
##     REFUSÉ, 0,63 m — l'échantillonnage fractionnaire change aussi les
##     lacets, donc l'orientation, et un module du kit ne remplit pas sa
##     boîte ;
##   * porter l'échelle à 1,30 : REFUSÉ par `controle_amas`, « azimut 100 :
##     les deux cols entaillent de 1,18 et 1,37 m ». La crête de gaine passait
##     de 6,01 à 6,33 m et comblait les cols de la composition. C'est
##     précisément la régression que ce contrôle existe pour attraper.
##
## La couverture manquante se gagne donc par une DOUBLURE ajoutée
## (`rochers_doublure()`), qui ne déplace rien.
GAINE_ECHELLE = 1.15


# ---------------------------------------------------------------------------
# LE PROFIL DE SOL — UN SEUL DÉCIDEUR, ET C'EST LE DÉFAUT QUI L'IMPOSE.
#
# `TRANCHE3.md` a publié « sol : −0,416 » là où le profil en attend −0,040.
# Le générateur IMPRIMAIT la mesure du défaut le jour de la livraison, et
# elle était illisible parce que rien ne se tenait à côté pour dire ce
# qu'elle aurait dû valoir. Une télémétrie qui imprime une mesure sans son
# attendu n'est pas un contrôle (ISS-044).
#
# Cette fonction est donc la seule source de l'attendu. Elle recopie la
# moitié basse de `anneau_interieur()` — `z = sag·v + PALIER[i] + denivele`
# — et rien d'autre :
#
#   * la cuvette est au plus profond sur l'AXE (v = −1) et remonte vers les
#     parois (v = 0), donc `−SAG·(1 − |f|)` avec `f` la fraction de
#     demi-largeur ;
#   * `PORCHE_DENIVELE` ne s'applique qu'au porche et s'éteint à la
#     station 1.
#
# Elle sert à trois endroits, et c'est le point : la SEMELLE en dérive son
# altitude, `hauteur_du_sol()` en dérive son attendu, et le contrôle de
# semelle en dérive son verdict. Si `PALIER` ou `CAVITE` change, les trois
# suivent ensemble.
def sol_de_cavite(u, lateral=0.0):
    """Altitude théorique du sol de la galerie, en repère MODÈLE.

    `u` est un indice de station, éventuellement fractionnaire ; `lateral`
    une fraction de demi-largeur dans [-1 ; +1].
    """
    i = max(0, min(len(PALIER) - 1, int(math.floor(u))))
    j = min(len(PALIER) - 1, i + 1)
    t = max(0.0, min(1.0, u - i))
    palier = PALIER[i] * (1.0 - t) + PALIER[j] * t
    denivele = PORCHE_DENIVELE * max(0.0, 1.0 - u)
    return palier - SAG * (1.0 - min(1.0, abs(lateral))) + denivele


def station_de_cavite(u):
    """(ax, ay, hw, cle) à un indice de station éventuellement fractionnaire."""
    i = max(0, min(len(CAVITE) - 1, int(math.floor(u))))
    j = min(len(CAVITE) - 1, i + 1)
    t = max(0.0, min(1.0, u - i))
    a, b = CAVITE[i], CAVITE[j]
    return tuple(a[k] * (1.0 - t) + b[k] * t for k in range(4))


def facteur_lateral(u, fraction):
    """Facteur d'asymétrie du CÔTÉ visé, à l'indice de station `u`.

    R2a-3.5.1 — LA MÊME FAUTE QUE `normale_de_cavite` RÉPARAIT, D'UN CRAN
    PLUS LOIN. Cette fonction-là a corrigé « décaler le long de X au lieu de
    la normale ». Restait : décaler de `fraction · hw` alors que la section
    n'est PAS symétrique. `anneau_interieur()` pose sa demi-largeur à
    `hw · (gauche si u < 0 sinon droite)` ; un sondage à `+0,75 · hw` tombe
    donc DANS LA ROCHE dès que `droite < 0,75`.

    Mesuré : à `(1,69 ; 0,25)`, le contrôle de plancher est passé de 1 faute
    à 9, dont sept « AUCUN sol sous le rayon » — c'est-à-dire des rayons
    partis de la roche pleine. Aucune n'était un défaut du maillage ; toutes
    étaient l'instrument qui mesurait à côté de la cavité.

    La fraction reste donc une fraction DU CÔTÉ, pas de `hw` : la couverture
    du contrôle est inchangée, elle est seulement posée au bon endroit.
    """
    i = max(0, min(len(CAVITE_ASYM) - 1, int(math.floor(u))))
    j = min(len(CAVITE_ASYM) - 1, i + 1)
    t = max(0.0, min(1.0, u - i))
    k = 1 if fraction >= 0.0 else 0
    return CAVITE_ASYM[i][k] * (1.0 - t) + CAVITE_ASYM[j][k] * t


def inclinaison_de_cavite(u):
    """Inclinaison du linteau à l'indice `u` — la voûte n'est pas centrée."""
    i = max(0, min(len(CAVITE_ASYM) - 1, int(math.floor(u))))
    j = min(len(CAVITE_ASYM) - 1, i + 1)
    t = max(0.0, min(1.0, u - i))
    return CAVITE_ASYM[i][2] * (1.0 - t) + CAVITE_ASYM[j][2] * t


def normale_de_cavite(u):
    """Axe LATÉRAL de la section à l'indice `u`, dans le plan (x, y).

    `anneau_interieur()` place ses sommets à `ax + n·normale.x`,
    `ay + n·normale.y` avec `normale = (tangente.y, −tangente.x)`. Décaler
    le long de X au lieu de la normale paraît anodin tant que la galerie
    court droit — et devient faux dès qu'elle s'infléchit.

    MESURÉ, ET C'EST CE QUI M'A COÛTÉ DEUX PASSES. Entre les stations 7 et
    8 le chemin part en (0,707 ; 0,707) : la normale y est à 45° de X. Un
    point placé à `ax + f·hw` s'y retrouve hors de la cavité, dans la roche
    pleine — le contrôle de plancher y voyait « aucun sol » et le trace des
    impacts l'a dit en une ligne : un seul impact, à z = −2,75, normale
    −1,00, c'est-à-dire le DESSOUS du solide, touché de l'intérieur.
    """
    eps = 0.02
    a = station_de_cavite(max(0.0, u - eps))
    b = station_de_cavite(min(len(CAVITE) - 1.0, u + eps))
    tx, ty = b[0] - a[0], b[1] - a[1]
    n = math.hypot(tx, ty)
    if n < 1e-9:
        return (1.0, 0.0)
    return (ty / n, -tx / n)


# LA DOUBLURE A ÉTÉ CONSTRUITE PUIS RETIRÉE, ET LA TRACE VAUT MIEUX QUE LE
# CODE MORT. Objectif : fermer les treize percées dispersées que la sonde
# mesure encore dans le coude, où la gaine — décalée en X — s'écarte du
# flanc réel. Une seconde peau alignée sur la NORMALE, plus petite et plus
# serrée, ajoutait de la matière sans en déplacer.
#
# Quatre variantes, quatre refus, tous d'un contrôle MESURÉ et non d'une
# impression :
#   * gaine posée sur la normale        -> epaisseur de paroi 0,60 m (min 0,80)
#   * gaine densifiee, pas 0,85 m       -> 0,63 m
#   * gaine a l'echelle 1,30            -> cols 1,18 / 1,37 m, rapport 1,16
#   * doublure ajoutee, puis plafonnee  -> cols 1,51 / 1,64 m, rapport 1,08
#
# Le constat est structurel et mérite d'être écrit : la galerie passe au
# MILIEU de la formation, et les deux cols de la composition sont les points
# bas de la crête juste au-dessus d'elle. Toute matière ajoutée autour du
# tube remonte donc vers un col. Épaissir pour fermer les percées et creuser
# pour garder trois masses tirent sur la même roche, en sens contraires.
# Les treize percées restantes sont dispersées — aucune maille de 1,5 m n'en
# regroupe plus de deux, là où le trou du fond en faisait converger 27 — et
# elles sont livrées comme telles, mesurées, plutôt que fermées au prix
# d'une régression de composition.


def rochers_dos_alcove():
    """LE REMBLAI DE L'ALCÔVE — dérivé d'`ALCOVE`, pas posé à la main.

    CE QU'IL FERME, MESURÉ EN MODE COMPLET (jamais `--rapide`) :

        19 rayon(s) quittent la galerie en x~-0.23 y~+8.76 z~+1.32
        17 rayon(s) quittent la galerie en x~+0.21 y~+8.92 z~+1.37
         4 rayon(s) quittent la galerie en x~+0.65 y~+9.09 z~+1.48

    Quarante rayons dans une même zone, alimentée par six stations, quand
    toutes les autres mailles plafonnent à trois. Rapportées aux sections,
    les trois fuites tombent sur celle de la STATION 6 — écart hors section
    0,21 · 0,55 · 0,90 m, contre 1,4 à 2,5 m pour ses voisines — à l'azimut
    ~153°, au rayon ~2,8 m, à v ~ 0,45.

    POURQUOI LA GAINE NE LES COUVRE PAS, ALORS QU'ELLE PORTE DÉJÀ LA
    POUSSÉE D'ALCÔVE. Parce qu'elle se pose en X : `ax + rayon·cos θ`. À la
    station 6 la normale au chemin est à 26,6° de X, si bien qu'à 4,06 m de
    rayon la couronne est déplacée de 1,87 m par rapport au flanc réel.
    Poser la gaine ENTIÈRE sur la normale a été essayé et refusé —
    `controle_epaisseur` tombait de 1,09 à 0,60 m, parce que ce contrôle
    mesure lui aussi en X. On ne déplace donc rien : on ajoute, là où la
    poche creuse, une famille qui suit la vraie section.

    ELLE EST DÉRIVÉE, ET C'EST LA CONDITION. La position de chaque roche est
    le POINT DE PAROI que `anneau_interieur()` calcule pour l'alcôve — même
    `le_long`, même `fenetre`, même gaussienne en v, même normale. Si
    `ALCOVE` change, le remblai suit ; aucune cote n'est recopiée.

    ELLE NE PEUT PAS TOUCHER LA COMPOSITION. Son sommet est plafonné à
    `DOS_ALCOVE_PLAFOND_M` = 4,20 m, sous les deux cols mesurés (4,58 m à
    l'est, 5,65 m à l'ouest). C'est la leçon des quatre refus précédents :
    toute matière ajoutée autour du tube remonte vers un col, donc une
    famille qui n'a pas à monter se plafonne.
    """
    sortie = []
    hauteur = MODULES["R"]["natif"][2] * DOS_ALCOVE_ECHELLE[2]
    u = float(ALCOVE["i0"])
    rang = 0
    while u <= ALCOVE["i1"] + 1e-6:
        ax, ay, hw, cle = station_de_cavite(u)
        nx, ny = normale_de_cavite(u)
        i = max(0, min(len(CAVITE_ASYM) - 1, int(math.floor(u))))
        j = min(len(CAVITE_ASYM) - 1, i + 1)
        t = max(0.0, min(1.0, u - i))
        gauche = CAVITE_ASYM[i][0] * (1.0 - t) + CAVITE_ASYM[j][0] * t
        for k in range(DOS_ALCOVE_AZIMUTS):
            tf = math.radians(DOS_ALCOVE_THETA0
                              + k * (180.0 - DOS_ALCOVE_THETA0)
                              / max(1, DOS_ALCOVE_AZIMUTS - 1))
            v = math.sin(tf)
            # LE POINT DE PAROI, recopié de `anneau_interieur()`.
            pousse = (ALCOVE["ampl"]
                      * le_long(u, ALCOVE["i0"], ALCOVE["i1"])
                      * fenetre(tf, ALCOVE["theta"], ALCOVE["dtheta"])
                      * math.exp(-(((v - ALCOVE["v0"]) / ALCOVE["dv"]) ** 2.0)))
            if pousse < DOS_ALCOVE_POUSSEE_MIN_M:
                continue          # hors de l'influence de la poche
            n = (hw * gauche + pousse) * math.cos(tf)
            z_paroi = cle * (max(0.0, v) ** 0.75)
            base = min(z_paroi - hauteur * 0.45,
                       DOS_ALCOVE_PLAFOND_M - hauteur)
            sortie.append(dict(
                nom="DosAlcove_%d_%d" % (rang, k), mod="R",
                pose=(ax + n * nx, ay + n * ny, base),
                lacet=(rang * 43 + k * 67) % 360,
                tangage=(rang % 3) * 3 - 3, roulis=(k % 4) * 3 - 4,
                ech=DOS_ALCOVE_ECHELLE, rang="gaine"))
        rang += 1
        prochain = min(float(ALCOVE["i1"]), u + 0.05)
        avance = 0.0
        while prochain < ALCOVE["i1"] and avance < DOS_ALCOVE_PAS_M:
            a = station_de_cavite(u)
            b = station_de_cavite(prochain)
            avance = math.hypot(b[0] - a[0], b[1] - a[1])
            if avance < DOS_ALCOVE_PAS_M:
                prochain = min(float(ALCOVE["i1"]), prochain + 0.05)
        if prochain >= ALCOVE["i1"] and u >= ALCOVE["i1"]:
            break
        u = prochain
    return sortie


## Azimut de départ du balayage, en degrés, et nombre d'azimuts jusqu'à 180°.
## La fenêtre de l'alcôve fait ±52° ; on couvre la moitié haute, celle où la
## sonde mesure les fuites (v ~ 0,45 à 0,51). La moitié basse relève de la
## semelle.
DOS_ALCOVE_THETA0 = 130.0
DOS_ALCOVE_AZIMUTS = 5
## Poussée sous laquelle on ne pose rien : hors de l'influence de la poche,
## la gaine ordinaire suffit et une roche de plus ne ferait qu'épaissir là où
## `controle_epaisseur` mesure déjà 1,09 m.
DOS_ALCOVE_POUSSEE_MIN_M = 0.08
DOS_ALCOVE_PAS_M = 0.70
## La roche est centrée sur le point de paroi : elle en garde environ 1,8 m
## derrière (au-delà des 0,80 m exigés) et 1,8 m devant, que la soustraction
## retire. Anisotropie 1,50, sous le plafond de 2,00.
DOS_ALCOVE_ECHELLE = (1.35, 1.35, 0.90)
## Cote maximale du sommet. Les deux cols de la composition sont mesurés à
## 4,58 m (est) et 5,65 m (ouest) : à 4,20 m cette famille ne peut atteindre
## ni l'un ni l'autre, donc ne peut pas refaire la régression que
## `controle_amas` a refusée quatre fois.
DOS_ALCOVE_PLAFOND_M = 4.20


def rochers_calotte_nord():
    """LA CALOTTE NORD — la roche qui manquait AU-DESSUS de la joue nord.

    CE QU'ELLE FERME, ET LA CAUSE A ÉTÉ MAL NOMMÉE DEUX FOIS
    =======================================================

    Le candidat R2a-3.5.2 est PERCÉ SUR LE CIEL : 343 colonnes ouvertes sur
    3 721 au pas de 5 mm, 85,8 cm², en `x ∈ [0,468 ; 0,623]`,
    `ay ∈ [5,850 ; 6,045]`. Le trou est hérité de l'enveloppe — `BASE352` le
    porte aux mêmes 343 colonnes — et absent de la géométrie livrée R2a-3.4.

    Deux explications ont été avancées et RÉFUTÉES par la mesure, elles sont
    conservées parce qu'une cause écartée vaut un repère :

      1. « deux lentilles d'enveloppe qui se rencontrent sans se
         recouvrir ». Le profil de colonne à `x = 0,55` y invitait :
         2,98 m de toit à `ay 4,0`, puis 1,00 · 0,52 · 0,40 · 0,075, puis
         1,85 — un col qui se pince à zéro et remonte. Faux.
      2. « artefact de remaillage ou de décimation ». Faux également.

    `tools/cave_fix_etapes.py` mesure la même colonne après CHACUNE des cinq
    étapes. Résultat, en `(0,55 ; 5,95)` :

        joindre      15 impacts, aucun vide      -> massif PLEIN
        remaillage    2 impacts, aucun vide      -> massif PLEIN
        stratification 2 impacts, aucun vide     -> massif PLEIN
        décimation    2 impacts, aucun vide      -> massif PLEIN  [-2,613 ; 1,512]
        soustraction  4 impacts, vide 1,36 m     -> banc de 0,043 m

    Le vide n'existe à AUCUNE étape source. Il est CREUSÉ par le booléen.

    D'OÙ VIENT LE CREUSEMENT, ET C'EST UNE PROPRIÉTÉ DU GABARIT
    ===========================================================

    `tools/cave_fix_outil.py` mesure `OUTIL_Cavite` avant tout booléen :
    boîte `y ∈ [-4,200 ; +7,245]`, quand la dernière station de `CAVITE` est
    à `ay = 3,17` et `CAVITE_APEX` à `3,25`. Le tube déborde de 4,0 m vers
    le nord. Emprise en Y de chaque anneau :

        st4 (1,82 ; 2,12) gauche 1,68 -> y [+1,20 ; +5,63]
        st5 (2,62 ; 2,58) gauche 1,69 -> y [+1,71 ; +6,60]
        st6 (3,10 ; 2,88) gauche 1,69 -> y [+2,35 ; +7,24]   <- le maximum
        st7 (3,40 ; 3,06) gauche 1,65 -> y [+2,65 ; +5,69]

    La cause est mécanique et parfaitement voulue : `hw · gauche` vaut
    jusqu'à `2,50 × 1,69 = 4,23 m` de joue gauche, et la normale au chemin y
    est à ~85 % alignée avec −Y. La salle déportée et l'alcôve projettent
    donc leur flanc quatre mètres au nord de leur station. **C'est le
    gabarit intérieur**, et il ne se rabote pas : on ajoute la roche qui
    aurait dû le couvrir.

    ELLE EST DÉRIVÉE, ET C'EST LA CONDITION — comme `rochers_dos_alcove()`.
    Chaque roche est posée sur le POINT DE PAROI que `anneau_interieur()`
    calcule, avec la même normale, le même `gauche`, la même poussée
    d'alcôve, le même linteau incliné et le même relief angulaire. Si
    `CAVITE`, `CAVITE_ASYM` ou `ALCOVE` bougent, la calotte suit ; aucune
    cote n'est recopiée.

    ELLE NE PEUT PAS TOUCHER LA COMPOSITION, ET C'EST PROUVÉ AVANT D'ÊTRE
    MESURÉ. Le profil de silhouette est un MAXIMUM de `z` par colonne
    d'écran : toute matière dont le sommet reste sous le profil existant
    laisse ce profil, et `controle_amas` avec lui, rigoureusement inchangés.
    Le sommet suit donc le plafond de la cavité — `z_paroi +
    CALOTTE_COUVERTURE_M` — et non une cote absolue. `tools/cave_fix_marge.py`
    mesure le jeu restant, colonne par colonne, aux trois azimuts :

        colonnes à corriger                                   74
        colonnes SANS solution conforme (jeu < 0)              0
        la plus contrainte : (+1,00 ; 5,40) jeu +0,32 m
        sommet le plus haut exigé par la correction         3,88 m

    Le rang est **`gaine` À DESSEIN**, et c'est le choix le plus sévère :
    `controle_amas` refuse qu'une pièce de ce rang porte la crête dans
    l'emprise d'une masse. Si la calotte remontait dans un col, le portail
    rougirait au lieu de laisser passer. On se donne le juge, on ne s'en
    exempte pas.

    TROIS MAJORATIONS CONSERVATRICES, écrites parce qu'elles se paient :
    `w` (relief angulaire) est pris au MAXIMUM des deux stations voisines,
    le linteau incliné est appliqué, et la rentrée de nervure est ignorée.
    Les trois font poser la roche un peu plus haut et un peu plus dehors que
    la paroi réelle — jamais l'inverse, jamais un toit surestimé.
    """
    sortie = []
    hauteur = MODULES["R"]["natif"][2] * CALOTTE_ECHELLE[2]
    ph = phases(len(CAVITE), 7.0)      # même graine que `cavite_solide()`
    u = CALOTTE_U0
    rang = 0
    while u <= CALOTTE_U1 + 1e-6:
        ax, ay, hw, cle = station_de_cavite(u)
        nx, ny = normale_de_cavite(u)
        i = max(0, min(len(CAVITE_ASYM) - 1, int(math.floor(u))))
        j = min(len(CAVITE_ASYM) - 1, i + 1)
        t = max(0.0, min(1.0, u - i))
        gauche = CAVITE_ASYM[i][0] * (1.0 - t) + CAVITE_ASYM[j][0] * t
        inclinaison = inclinaison_de_cavite(u)
        for k in range(CALOTTE_AZIMUTS):
            tf = math.radians(CALOTTE_THETA0
                              + k * (CALOTTE_THETA1 - CALOTTE_THETA0)
                              / max(1, CALOTTE_AZIMUTS - 1))
            uc, v = math.cos(tf), math.sin(tf)
            pousse = (ALCOVE["ampl"]
                      * le_long(u, ALCOVE["i0"], ALCOVE["i1"])
                      * fenetre(tf, ALCOVE["theta"], ALCOVE["dtheta"])
                      * math.exp(-(((v - ALCOVE["v0"]) / ALCOVE["dv"]) ** 2.0)))
            # LE POINT DE PAROI, recopié de `anneau_interieur()`. `w` majoré
            # et `rentree` ignorée : voir le docstring.
            w = max(bruit(tf, ph[i], AMP_INTERIEUR),
                    bruit(tf, ph[j], AMP_INTERIEUR))
            n = (hw * gauche * w + pousse) * uc
            if abs(n) < CALOTTE_DEBORD_MIN_M:
                continue          # la joue ne déborde pas ici : rien à couvrir
            z_paroi = cle * (max(0.0, v) ** 0.75) * w * (1.0 + inclinaison * uc)
            haut = min(z_paroi + CALOTTE_COUVERTURE_M, CALOTTE_PLAFOND_M)
            base = min(haut - hauteur, z_paroi - CALOTTE_MORSURE_M)
            sortie.append(dict(
                nom="CalotteNord_%d_%d" % (rang, k), mod="R",
                pose=(ax + n * nx, ay + n * ny, base),
                lacet=(rang * 61 + k * 37) % 360,
                tangage=(rang % 3) * 3 - 3, roulis=(k % 4) * 3 - 4,
                ech=CALOTTE_ECHELLE, rang="gaine"))
        rang += 1
        # Avance d'environ `CALOTTE_PAS_M` LE LONG DU CHEMIN, et non d'un
        # pas fixe en `u` : les stations ne sont pas équidistantes, et un
        # pas en `u` laisserait un trou entre les deux plus écartées.
        prochain = min(CALOTTE_U1, u + 0.05)
        avance = 0.0
        while prochain < CALOTTE_U1 and avance < CALOTTE_PAS_M:
            a = station_de_cavite(u)
            b = station_de_cavite(prochain)
            avance = math.hypot(b[0] - a[0], b[1] - a[1])
            if avance < CALOTTE_PAS_M:
                prochain = min(CALOTTE_U1, prochain + 0.05)
        if prochain >= CALOTTE_U1 and u >= CALOTTE_U1:
            break
        u = prochain
    return sortie


## Bornes du balayage, en indices de station. La joue nord dépasse `ay = 4,3`
## des stations 4 à 7 (emprises mesurées par `tools/cave_fix_outil.py`) ; on
## déborde d'une demi-station de chaque côté pour que la couverture ne
## s'arrête pas au dernier point mesuré.
CALOTTE_U0 = 3.50
CALOTTE_U1 = 7.20
CALOTTE_PAS_M = 0.60
## Azimuts de la joue nord. 100° est juste au-dessus de l'horizontale du
## côté `-n` ; 176° est le point le plus extérieur, presque au niveau du
## sol. En deçà de 100° on est sur la voûte centrale, déjà couverte par
## 2,5 à 5 m de roche.
CALOTTE_THETA0 = 100.0
CALOTTE_THETA1 = 176.0
CALOTTE_AZIMUTS = 5
## Débord minimal sous lequel on ne pose rien : près de l'axe la voûte est
## déjà couverte, et une roche de plus n'y ajouterait qu'un risque de col.
CALOTTE_DEBORD_MIN_M = 0.60
## Roche visée AU-DESSUS du plafond de la cavité. Le seuil du contrat est
## 0,80 m ; on vise le double, parce que le remaillage à 0,12 m, la
## stratification et la décimation à 19 000 tris déplacent la surface, et
## que le verdict final se prononce sur une BORNE MINORANTE (`lecture − pas`)
## calculée par un autre instrument que celui-ci.
CALOTTE_COUVERTURE_M = 1.60
## Enfoncement minimal de la roche SOUS le point de paroi : sans lui la
## roche affleurerait le toit et le remaillage pourrait ne pas la souder.
CALOTTE_MORSURE_M = 0.40
## Garde-fou absolu, en plus du plafond glissant. Les faîtes de composition
## sont à 8,35 m (dominante), 4,85 m (épaule) et 4,49 m (contrefort) : à
## 4,00 m cette famille ne peut porter aucun d'eux. Ce n'est PAS le contrôle
## principal — c'est `CALOTTE_COUVERTURE_M`, qui suit le plafond de la
## cavité, qui garde la masse sous la silhouette. Celui-ci n'est qu'une
## butée si un réglage futur devenait déraisonnable.
CALOTTE_PLAFOND_M = 4.00
## Anisotropie 1,82, sous le plafond de 2,00. Hauteur 4,35 × 0,55 = 2,39 m :
## assez pour mordre 0,40 m dans le toit ET porter 1,60 m au-dessus.
CALOTTE_ECHELLE = (1.00, 1.00, 0.55)


def rochers_semelle():
    """LA SEMELLE — de la roche DÉRIVÉE sous le plancher de la galerie.

    CE QU'ELLE RÉPARE, MESURÉ PAR `tools/probe_cave_openings.py` sur le GLB
    livré : « plancher absent de y = +0,00 à y = +5,50 (stations 1 à 4) ».
    Sur ces six mètres, un rayon tiré vers le bas depuis l'intérieur tombait
    de 0,97 à 2,00 m au lieu de 0,60 à 1,40 — il traversait le sol annoncé
    et n'était arrêté que par le sommet de l'assise enterrée, à z ≈ −0,45.
    Le joueur marchait donc à soixante centimètres sous le profil déclaré.

    POURQUOI PERSONNE NE L'AVAIT VU. La chaîne était circulaire, et c'est
    écrit dans les deux fonctions : `controle_epaisseur()` écarte les rayons
    descendants (`if math.sin(theta) < -0.30: continue`) en renvoyant à
    `controle_aucun_jour()`, qui ne tire que vers le HAUT. Rien ne regardait
    le sol.

    POURQUOI UNE SEMELLE ET NON DES ROCHES POSÉES. L'emprise mesurée invite
    à rustiner jusqu'à l'emprise, et le docstring de `rochers_gaine()`
    raconte déjà ce que ça coûte : « j'ai répondu seize fois en ajoutant une
    roche là où il pointait […] je corrigeais une mesure au lieu de garantir
    la propriété ». La semelle garantit la propriété : pour CHAQUE station
    de `CAVITE` et CHAQUE position latérale de la demi-largeur, il existe de
    la matière continue entre le profil de sol et l'assise. Si `CAVITE` ou
    `PALIER` change, la semelle suit — aucune cote n'est recopiée.

    LA CONTINUITÉ SE DÉMONTRE, elle ne s'espère pas. Le faîte sculpté de
    `template-detail` mesure 0,93 × ech en largeur (mesuré sur ses 600
    sommets, tous axes confondus) : deux roches espacées de moins que cela
    ont leur plateau qui se recouvre, et le creux entre elles reste sous
    0,15 × ez. Les pas longitudinal et latéral sont donc bornés par
    `SEMELLE_PAS_M`, et `SEMELLE_MARGE_M` (0,60 m) domine largement ce
    creux. C'est la même arithmétique que celle des amas de R2a-3.4.

    Le sommet de chaque roche est à `sol + SEMELLE_MARGE_M` : la
    soustraction de la cavité vient ensuite y tailler le plancher réel, qui
    est donc EXACTEMENT le profil déclaré, et non la surface d'une roche.
    Le fond de chaque roche descend sous `ASSISE["z1"]`, si bien que la
    semelle et l'assise ne forment qu'une masse.
    """
    sortie = []
    u = 0.0
    rang_long = 0
    while u <= len(CAVITE) - 1 + 1e-6:
        ax, ay, hw, _ = station_de_cavite(u)
        nx, ny = normale_de_cavite(u)
        demi = hw * SEMELLE_PART_LAT
        n_lat = max(1, int(math.ceil(2.0 * demi / SEMELLE_PAS_M)))
        for k in range(n_lat + 1):
            f = (-1.0 + 2.0 * k / n_lat) if n_lat > 0 else 0.0
            sommet = sol_de_cavite(u, f * SEMELLE_PART_LAT) + SEMELLE_MARGE_M
            hauteur = MODULES["R"]["natif"][2] * SEMELLE_ECHELLE[2]
            sortie.append(dict(
                nom="Semelle_%02d_%d" % (rang_long, k), mod="R",
                pose=(ax + f * demi * nx, ay + f * demi * ny,
                      sommet - hauteur),
                lacet=(rang_long * 53 + k * 79) % 360,
                tangage=(rang_long % 3) * 3 - 3, roulis=(k % 4) * 3 - 4,
                ech=SEMELLE_ECHELLE, rang="semelle"))
        rang_long += 1
        # Pas d'avance converti en mètres le long de l'axe : deux stations
        # voisines sont distantes de 0,60 à 1,60 m, donc un pas fixe en
        # indice de station ne bornerait pas le pas en mètres.
        prochain = min(len(CAVITE) - 1.0, u + 0.05)
        avance = 0.0
        while prochain < len(CAVITE) - 1.0 and avance < SEMELLE_PAS_M:
            a = station_de_cavite(u)
            b = station_de_cavite(prochain)
            avance = math.hypot(b[0] - a[0], b[1] - a[1])
            if avance < SEMELLE_PAS_M:
                prochain = min(len(CAVITE) - 1.0, prochain + 0.05)
        if prochain >= len(CAVITE) - 1.0 and u >= len(CAVITE) - 1.0:
            break
        u = prochain
    return sortie


## Pas maximal, longitudinal ET latéral, entre deux roches de semelle. Borné
## par la largeur du faîte du module (0,93 × ech) pour que les plateaux se
## recouvrent : au-delà, le creux entre deux voisines dépasse la marge et un
## trou de plancher se rouvre.
SEMELLE_PAS_M = 1.25
## Fraction de la demi-largeur couverte, le long de la NORMALE au chemin.
## 1,05 et non 0,90 : `tools/probe_cave_openings.py` échantillonne, lui, le
## long de X (`p = (ax + f·hw, ay, z)`), si bien que ses points s'écartent de
## la normale là où la galerie s'infléchit. La bande couverte doit donc
## déborder la demi-largeur, sans quoi les deux instruments ne mesurent pas
## le même sol.
SEMELLE_PART_LAT = 1.05
## De combien le sommet de la semelle dépasse le profil de sol déclaré. La
## soustraction retaille ensuite le plancher au profil exact ; cette marge ne
## sert qu'à garantir qu'il reste de la matière à tailler, y compris dans le
## creux entre deux roches voisines.
SEMELLE_MARGE_M = 0.60
## Échelle des roches de semelle. LE PREMIER JET A ÉTÉ REFUSÉ PAR MA PROPRE
## BORNE, et c'est le contrôle qui a eu raison : (1,35 ; 1,35 ; 0,62) fait
## une anisotropie de 2,18 pour un plafond de 2,00. Desserrer le plafond
## aurait été le geste facile ; la semelle est certes invisible, mais une
## borne qu'on relâche pour le cas qui gêne ne borne plus rien.
##
## (1,45 ; 1,45 ; 0,75) tient à 1,93 et donne 3,26 m de hauteur : le fond
## descend de 2,66 m sous le profil de sol, donc sous `ASSISE["z1"]` (−0,55)
## à TOUTES les stations, et la semelle ne fait qu'une masse avec l'assise.
## Le plateau du module y mesure 0,93 × 1,45 = 1,35 m, ce qui autorise le pas
## de 1,25 m. Elles restent invisibles : la soustraction les ouvre côté
## galerie, la gaine les enferme côté flancs, l'assise côté dessous.
SEMELLE_ECHELLE = (1.45, 1.45, 0.75)

# `y1` ALLAIT À 9,10 ET S'ARRÊTAIT AVANT LA FIN DE LA CAVITÉ. La dernière
# station est à y = 9,25 et la calotte (`CAVITE_APEX`) à 9,55 : l'assise ne
# passait donc pas sous le fond de la galerie, et c'est l'une des trois
# causes du trou mesuré par la sonde en x[+0,97 ; +2,47] z[+1,02 ; +2,27].
# Portée à 10,60, elle dépasse l'apex de plus d'un mètre.
#
# `z1` NE BOUGE PAS, et ce n'est pas un oubli. L'assise couvre
# x[−6,40 ; 6,90] et y[−3,10 ; 10,60], soit bien plus large que la galerie :
# la remonter au-dessus du terrain (−0,50) ferait apparaître un plateau de
# roche plat tout autour de la formation — le défaut « grands aplats », en
# pire, parce qu'il serait horizontal et à hauteur d'œil.
ASSISE = dict(x0=-6.40, x1=6.90, y0=-3.10, y1=10.60, z0=-2.35, z1=-0.55)

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

## Tolérance entre le sol mesuré et le sol déclaré par `sol_de_cavite()`.
## Même valeur que `PLANCHER_TOLERANCE_M` dans `tools/probe_cave_openings.py`
## — les deux mesurent la même propriété, et deux tolérances différentes
## fabriqueraient un désaccord entre le générateur et la sonde.
SOL_TOLERANCE_M = 0.25
## Pas d'échantillonnage du plancher, en mètres le long de l'axe, et
## fractions latérales de la demi-largeur. Le contrôle tire un rayon vers le
## BAS depuis le vide de la galerie — la direction que ni
## `controle_epaisseur()` (qui écarte `sin θ < −0,30`) ni
## `controle_aucun_jour()` (qui ne tire que `+Z`) n'a jamais regardée.
PLANCHER_PAS_M = 0.75
PLANCHER_FRACTIONS = (-0.75, -0.45, -0.15, 0.15, 0.45, 0.75)
## Hauteur libre minimale sous laquelle un point latéral ne veut plus rien
## dire : la voûte y rejoint le sol, et un rayon vertical n'y mesure que
## l'épaisseur de la paroi. `controle_epaisseur()` s'en charge.
PLANCHER_HAUTEUR_MIN_M = 0.45

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
                     retrait_cle, denivele, sag, retrait_alcove=0.0):
    """Profil FERMÉ de la cavité — polygonal, dissymétrique, à alcôve.

    Le sol fait partie du profil : c'est lui qui garantit qu'aucune herbe du
    terrain gelé ne peut apparaître entre le sol et les parois, défaut vu à
    la passe précédente quand le sol était un disque séparé.

    R2a-3.5.7 — `retrait_alcove` : LA MARGE DE PASSAGE NE S'APPLIQUAIT PAS À
    L'ALCÔVE, ET C'EST LA CAUSE DES 16 PÉNÉTRATIONS `cav×env` RESTANTES.

    MESURÉ. `COL_WaterfallCave` porte 16 pénétrations exactes, toutes
    `cav×env`, toutes dans une boîte de 1,0 × 0,4 × 1,0 m. Localisées face
    par face contre l'atlas du générateur : peau de cavité stations 5 à 7,
    peau d'enveloppe stations 7 à 9, azimuts 9 à 11 — c'est-à-dire UN SEUL
    défaut, au centre de l'alcôve (`ALCOVE` : stations 5-7, θ = 180°, soit
    l'azimut 10 sur 20).

    LA CAUSE EST INTRINSÈQUE, ET ELLE EST DANS CETTE FONCTION. Le retrait
    de collision est soustrait de `hw` UNIQUEMENT :

        hw = max(0.05, hw - retrait_lat)        <- la marge s'applique ici
        ...
        n = (demi * w + pousse - rentree) * u   <- `pousse` y échappe

    `pousse` est l'élargissement d'alcôve, jusqu'à `ALCOVE["ampl"]` = 1,20 m,
    et il est ajouté APRÈS le retrait, à pleine amplitude. La cavité de
    collision respecte donc `COL_MARGE_LAT` sur toute la galerie SAUF dans
    l'alcôve, où elle affleure la paroi. Il y manque exactement une marge,
    et c'est là que la roche s'annule.

    LA MESURE LE DIT SANS AMBIGUÏTÉ — épaisseur de roche de la coque, minimum
    par station de cavité (`tools/cave_epaisseur_col.py`) :

        station     2      3      4      5      6      7      8
        avant     1,00   0,99   0,74   0,63  +0,09   0,13   0,70
        après     1,11   1,11   0,97   0,51  -0,04   0,32   0,76

    Une cuvette, centrée sur la station 6 azimut 10 — le centre exact de
    l'alcôve. Le lissage `MASSIF` de R2a-3.5.6 ne l'a PAS creusée : il a
    remonté toutes les autres stations et fait passer celle-là de +0,09 m à
    −0,04 m. Défaut chronique, pas régression : 0,09 m de roche n'est pas
    une marge, c'est un cheveu — et deux polygones facettés se croisent
    ENTRE leurs sommets bien avant que leurs sommets se touchent. C'est
    pourquoi des `cav×env` existaient déjà avant le lissage alors qu'aucun
    sommet n'était sorti de l'enveloppe.

    CE N'EST PAS LE MÉCANISME DE COURBURE. Le lissage `MASSIF` invoquait
    « un tube plus large que le virage qu'il suit ». Mesuré station par
    station (`tools/cave_ratio_courbure.py`) : les stations qui portent ces
    16 pénétrations ont les ratios les PLUS BAS de leurs tables — cavité
    0,13 / 0,08 / 0,04, massif 0,93 / 0,45 / 0,24. La seule station encore
    au-dessus de 1 est `MASSIF` 3 (1,086), et elle n'en porte aucune.
    L'hypothèse « résidu du même mécanisme » est donc RÉFUTÉE par la mesure.

    CE QUE FAIT LE PARAMÈTRE. Il retire `retrait_alcove` de l'AMPLITUDE de
    l'alcôve, pas de son profil : fenêtre d'azimut, bande en `v` et fondu le
    long de l'axe sont rigoureusement inchangés — la forme ne bouge pas et
    aucune marche n'apparaît. `construire()` lui passe `COL_MARGE_LAT`, la
    MÊME valeur que le reste de la galerie, pas une constante nouvelle. Il
    n'y a donc rien à régler ici, et la ligne se lit comme ce qu'elle est :
    la marge de passage s'applique enfin partout.

    POURQUOI LA VALEUR PAR DÉFAUT EST 0,0. Cette fonction a trois appelants
    et deux d'entre eux ne sont PAS le collider : `cavite_solide()` bâtit le
    volume négatif qui creuse le maillage VISIBLE, et `_section_de_station()`
    mesure la cavité livrée. Un défaut non nul changerait le rendu et
    fausserait le contrôle. `SM_WaterfallCave` doit rester identique au bit
    près, et c'est la prédiction falsifiable de ce lot.
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
        # L'amplitude — et elle seule — porte la marge de passage ; le profil
        # (fenêtre, bande, fondu) est inchangé, donc la forme aussi.
        #
        # LE RETRAIT EST MIS À LA MÊME ÉCHELLE QUE CELUI DE LA PAROI, et
        # c'est ce qui rend la marge cohérente au lieu d'approximative.
        # `retrait_lat` est soustrait de `hw` AVANT la multiplication par
        # l'asymétrie : le recul réel de la paroi vaut donc
        # `retrait_lat × asym`, soit 0,68 m au flanc de l'alcôve où
        # `CAVITE_ASYM[6]` porte 1,69 — et non 0,40. Retrancher 0,40 de
        # l'élargissement laissait l'alcôve reculer DEUX FOIS MOINS que la
        # paroi qu'elle prolonge. Mesuré : repli 0,2307 m à 0,40, et
        # 0,000000 m au retrait mis à l'échelle. Aucune constante nouvelle —
        # c'est `COL_MARGE_LAT` et `CAVITE_ASYM`, déjà là toutes les deux.
        asym = gauche if u < 0.0 else droite
        ampl_alcove = max(0.0, ALCOVE["ampl"] - retrait_alcove * asym)
        pousse = ampl_alcove * le_long(indice, ALCOVE["i0"], ALCOVE["i1"]) \
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
    # L'ANISOTROPIE EST LE LEVIER DE R2a-3.4, ET ELLE A UNE BORNE.
    #
    # Le rapport hauteur/largeur natif de `template-detail` vaut 4,35/2,64 =
    # 1,65, identique pour ses exemplaires tant que `ech` est uniforme. C'est
    # ce qui rendait le coefficient de variation des largeurs de sommet
    # arithmétiquement nul : un module dont le faîte mesure 0,93 m de large à
    # 0,60 m sous son sommet donne, à toute échelle UNIFORME, un sommet de
    # silhouette de même forme. Un triplet sort de ce rapport unique sans
    # toucher aux bornes [0,55 ; 1,55], et sans ajouter de module au kit.
    #
    # Mais un rocher SCULPTÉ étiré se voit : au-delà d'un rapport 2 entre la
    # plus grande et la plus petite composante, ses arêtes s'allongent
    # visiblement dans une direction et il cesse de lire comme une roche —
    # c'est le reproche déjà reçu sur les grandes échelles, transposé.
    if max(ech) / min(ech) > ANISOTROPIE_MAX:
        raise RuntimeError("%s : anisotropie %.2f (%.2f / %.2f / %.2f) "
                           "au-dela de %.2f — un rocher sculpte etire de plus "
                           "du double cesse de lire comme une roche"
                           % (config["nom"], max(ech) / min(ech), ech[0],
                              ech[1], ech[2], ANISOTROPIE_MAX))
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
    _desamorcer_ngones_colineaires(bm)
    bm.to_mesh(maillage)
    bm.free()
    maillage.update()
    for polygone in maillage.polygons:
        polygone.use_smooth = False
    return base


def _triplet_colineaire_exact(a, b, c):
    """Trois points sont-ils EXACTEMENT alignés ? Sans tolérance, exprès.

    `Fraction` représente un float sans perte : le produit vectoriel calculé
    ici est exact, et « nul » y signifie nul, pas « petit ». Un seuil
    rendrait ce test dépendant d'une échelle, alors que la question posée —
    ce triplet peut-il produire un triangle d'aire nulle — ne l'est pas.
    """
    u = [Fraction(b[k]) - Fraction(a[k]) for k in range(3)]
    v = [Fraction(c[k]) - Fraction(a[k]) for k in range(3)]
    return (u[1] * v[2] - u[2] * v[1] == 0
            and u[2] * v[0] - u[0] * v[2] == 0
            and u[0] * v[1] - u[1] * v[0] == 0)


def _desamorcer_ngones_colineaires(bm):
    """Retire à l'export la possibilité de fabriquer un triangle plat.

    POURQUOI CETTE FONCTION EXISTE, ET CE QU'ELLE CORRIGE VRAIMENT
    =============================================================
    Le livrable portait un triangle d'aire EXACTEMENT nulle en
    `(-1,504 ; -3,099 ; -0,639)`. L'attribution héritée le disait né à la
    soustraction. Mesuré en R2a-3.5.5, c'est faux, et l'écart compte :

      * après `soustraire()`, le maillage Blender contient ZÉRO face d'aire
        nulle — vérifié par produit vectoriel rationnel sur toutes les faces ;
      * il contient un n-gone à 13 côtés dont trois sommets CONSÉCUTIFS
        (9985, 9986, 9987) sont exactement colinéaires ;
      * l'exportateur glTF triangule ce n-gone et relie ces trois sommets :
        le triangle plat naît LÀ, à l'export.

    Le solveur booléen exact de Blender supprime ensuite cette face de
    lui-même, ce qui ouvre 3 bords libres sur un maillage par ailleurs
    fermé — c'est le symptôme qui avait été observé avec un cube à 500 m,
    sans la moindre intersection.

    POURQUOI ON NE DISSOUT PAS LE SOMMET DU MILIEU
    ==============================================
    Ce serait l'évidence, et c'est faux : le sommet médian est partagé par
    des quads voisins où il n'est PAS colinéaire — mesuré, `9986` appartient
    aussi aux faces 16933 et 16934. Le dissoudre déformerait ces faces.

    CE QU'ON FAIT À LA PLACE
    ========================
    On triangule UNIQUEMENT les n-gones porteurs d'un triplet consécutif
    colinéaire, puis on résout par BASCULE D'ARÊTE les triangles plats que
    la triangulation aurait quand même produits. Une bascule est purement
    topologique : elle échange la diagonale d'un quadrilatère, ne déplace
    aucun sommet, et ne change donc NI la surface, NI le volume, NI la
    silhouette. La forme visible est rigoureusement conservée.

    L'intervention est chirurgicale par construction : sur la géométrie de
    référence, un seul polygone sur 17 458 est concerné.
    """
    suspects = []
    for face in bm.faces:
        if len(face.verts) <= 3:
            continue
        points = [v.co for v in face.verts]
        n = len(points)
        for k in range(n):
            if _triplet_colineaire_exact(points[k], points[(k + 1) % n],
                                         points[(k + 2) % n]):
                suspects.append(face)
                break
    if not suspects:
        print("[grotte] n-gones colineaires : aucun — rien a desamorcer")
        return 0
    print("[grotte] n-gones colineaires : %d face(s) porteuse(s) d'un "
          "triplet consecutif exactement aligne" % len(suspects))
    bmesh.ops.triangulate(bm, faces=suspects, quad_method='BEAUTY',
                          ngon_method='BEAUTY')
    bm.faces.ensure_lookup_table()

    # Les triangles plats éventuellement produits sont résolus par bascule.
    # On borne les tours : une bascule qui ne fait pas décroître le compte
    # signalerait une configuration qu'on ne sait pas traiter, et il vaut
    # mieux le dire que tourner en rond.
    bascules = 0
    for _tour in range(8):
        plats = [f for f in bm.faces
                 if len(f.verts) == 3
                 and _triplet_colineaire_exact(f.verts[0].co, f.verts[1].co,
                                               f.verts[2].co)]
        if not plats:
            break
        pivotables = []
        for face in plats:
            # L'arête la plus longue d'un triangle plat est celle qui porte
            # les deux extrémités : c'est elle qu'il faut échanger.
            aretes = sorted(face.edges, key=lambda e: e.calc_length())
            candidate = aretes[-1]
            if len(candidate.link_faces) == 2 and candidate not in pivotables:
                pivotables.append(candidate)
        if not pivotables:
            print("[grotte] ATTENTION: %d triangle(s) plat(s) sans arete "
                  "basculable" % len(plats))
            break
        bmesh.ops.rotate_edges(bm, edges=pivotables, use_ccw=False)
        bascules += len(pivotables)
        bm.faces.ensure_lookup_table()
    restants = sum(1 for f in bm.faces
                   if len(f.verts) == 3
                   and _triplet_colineaire_exact(f.verts[0].co,
                                                 f.verts[1].co,
                                                 f.verts[2].co))
    print("[grotte] desamorcage : %d bascule(s) d'arete, %d triangle(s) "
          "d'aire nulle restant(s)" % (bascules, restants))
    return restants


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
        ## `retrait_alcove=retrait_lat` — LA MARGE DE PASSAGE S'APPLIQUE
        ## ENFIN À L'ALCÔVE AUSSI. Voir le pavé de `anneau_interieur()` : le
        ## retrait ne mordait que sur `hw`, et l'élargissement d'alcôve
        ## passait à côté. Ce n'est pas une valeur nouvelle — c'est
        ## `COL_MARGE_LAT`, la même que sur toute la galerie, transmise là
        ## où elle manquait. Les deux autres appelants gardent le défaut
        ## 0,0 : ils servent le maillage VISIBLE et son contrôle.
        cav_bases.append(ajouter_anneau(anneau_interieur(
            i, st, t_cav[i], segments, ph_c[i], retrait_lat, retrait_cle,
            denivele, sag, retrait_alcove=retrait_lat)))
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

# ---------------------------------------------------------------------------
# ENVELOPPE EXTÉRIEURE — R2a-3.5. C'est ELLE qui porte la silhouette.
#
# CE QUI CHANGE, ET C'EST L'ORDRE DU LEAD. Jusqu'à R2a-3.4 la silhouette
# était faite de copies de `template-detail` posées par `poser_rocher()`.
# Verdict : « trois tours verticales, sommets plats, forteresse crénelée ;
# la mesure ne remplace pas ce constat ». Les modules ne doivent plus
# porter la silhouette principale — ils peuvent casser des surfaces,
# jamais fabriquer des tours ni décider des sommets. Cette section est ce
# qui les remplace ; `controle_amas` a été inversé pour l'exiger.
#
# LA PIÈCE STRUCTURELLE est le RUBAN DE CRÊTE : le loft se termine sur une
# boucle dont la LARGEUR est donnée point par point. Il n'existe donc
# aucune valeur des paramètres qui rende un sommet plat — et aucune non
# plus qui le rende pointu, ce qui était l'échec opposé. Le profil de
# flanc suit sept points de contrôle alternant vires et murs : sans eux
# le flanc est une droite, et trois droites font trois triangles.
#
# LE PLAN EST CONTRAINT PAR LA GALERIE, pas choisi. La masse haute est un
# MASSIF centré sur le corridor, pas une arête : la direction de la
# galerie projette 0,070 m par mètre à l'azimut monde 100° contre 0,755 à
# 55°, si bien qu'une arête alignée sur elle serait large de face et pic
# étroit de trois quarts. Un massif projette sa girth partout.
#
# L'ÉPAULE ET LA DOMINANTE SONT DEUX LOFTS ET NON UN, et c'est une
# concession au contrôle, pas au dessin : `controle_amas` attribue chaque
# masse à UNE clé d'amas. Les deux se recouvrent franchement au col A et
# le remaillage voxel les refond ; la formation reste un seul volume.
# ---------------------------------------------------------------------------

RESSAUTS_ENV = [
    (0.00, 0.00), (0.13, 0.25), (0.36, 0.35), (0.46, 0.56),
    (0.70, 0.66), (0.82, 0.84), (1.00, 1.00),
]


def _bruit_env(graine, compte, amplitude):
    rng = random.Random(graine)
    return [1.0 + rng.uniform(-amplitude, amplitude) for _ in range(compte)]


def _rayon_ellipse_env(delta, demi_grand, demi_petit):
    c, sn = math.cos(delta), math.sin(delta)
    return (demi_grand * demi_petit) / math.sqrt(
        (demi_petit * c) ** 2 + (demi_grand * sn) ** 2)


def _densifier_env(points, compte):
    """Densifie SANS perdre un seul sommet d'origine.

    Un rééchantillonnage à pas constant rate les sommets de la polyligne :
    mesuré, il rabotait l'apex de 73 cm en silence. On n'insère donc que
    DANS les segments, en servant d'abord les plus longs.
    """
    if compte < len(points):
        raise RuntimeError("enveloppe : n trop petit pour %d sommets de crete"
                           % len(points))
    segments = len(points) - 1
    ajouts = [0] * segments
    longueurs = [math.dist(points[i][:3], points[i + 1][:3])
                 for i in range(segments)]
    for _ in range(compte - len(points)):
        cible = max(range(segments),
                    key=lambda i: longueurs[i] / (ajouts[i] + 1))
        ajouts[cible] += 1
    sortie = []
    for i in range(segments):
        sortie.append(tuple(points[i]))
        a, b = points[i], points[i + 1]
        for j in range(ajouts[i]):
            u = (j + 1) / (ajouts[i] + 1)
            sortie.append(tuple(a[d] + (b[d] - a[d]) * u for d in range(4)))
    sortie.append(tuple(points[-1]))
    return sortie


def _profil_env(t, decal_t, decal_f):
    n = len(RESSAUTS_ENV)
    for i in range(n - 1):
        t0, f0 = RESSAUTS_ENV[i]
        t1, f1 = RESSAUTS_ENV[i + 1]
        if i > 0:
            t0 += decal_t
            f0 += decal_f
        if i + 1 < n - 1:
            t1 += decal_t
            f1 += decal_f
        if t <= t1 or i == n - 2:
            if t1 - t0 <= 1e-9:
                return f1
            u = min(1.0, max(0.0, (t - t0) / (t1 - t0)))
            return f0 + (f1 - f0) * u
    return 1.0


def _ruban_env(crete, n):
    """Boucle fermée serrée autour de la crête, largeur donnée point par point."""
    demi = n // 2
    echant = _densifier_env(crete, demi)
    perp = []
    for i in range(demi):
        a = echant[max(0, i - 1)]
        b = echant[min(demi - 1, i + 1)]
        t = Vector((b[0] - a[0], b[1] - a[1]))
        t = t.normalized() if t.length > 1e-6 else Vector((1.0, 0.0))
        perp.append(Vector((-t.y, t.x)))
    cote_a, cote_b = [], []
    for pt, q in zip(echant, perp):
        demi_l = max(0.10, pt[3]) * 0.5
        cote_a.append(Vector((pt[0] + q.x * demi_l, pt[1] + q.y * demi_l, pt[2])))
        cote_b.append(Vector((pt[0] - q.x * demi_l, pt[1] - q.y * demi_l, pt[2])))
    return list(reversed(cote_a)) + cote_b


def masse_enveloppe(cfg):
    """Un volume d'enveloppe : polygone de sol -> ruban de crête incliné.

    Rend (sommets, faces, familles). La cape du dernier anneau est une
    BANDE de quads et non un n-gone : le ruban est une épingle, et un
    n-gone d'épingle se triangule en reliant des points éloignés — mesuré,
    cela recréait deux cornes et une encoche à fond plat, c'est-à-dire un
    créneau produit par la triangulation et non par la forme voulue.
    """
    crete = [tuple(pt) for pt in cfg["crete"]]
    n = cfg["n"]
    if n % 2:
        raise RuntimeError("enveloppe : n pair requis")
    axe = Vector((crete[-1][0] - crete[0][0], crete[-1][1] - crete[0][1]))
    psi = math.atan2(axe.y, axe.x) if axe.length > 1e-6 else 0.0
    biais_az = math.radians(cfg.get("biais_az", 270.0))
    biais = cfg.get("biais", 0.0)
    ruban = _ruban_env(crete, n)
    bruit_r = _bruit_env(cfg["graine"], n, 0.13)
    bruit_b = _bruit_env(cfg["graine"] + 97, n, 1.0)
    bruit_p = _bruit_env(cfg["graine"] + 41, n, 0.10)
    ancre = cfg["ancre"]

    base, dehors = [], []
    for k in range(n):
        a = psi + TAU * k / n
        r = _rayon_ellipse_env(a - psi, cfg["dg"], cfg["dp"]) * bruit_r[k]
        r *= 1.0 + biais * math.cos(a - biais_az)
        d = Vector((math.cos(a), math.sin(a)))
        dehors.append(d)
        base.append(Vector((ancre[0] + d.x * r, ancre[1] + d.y * r, -SKIRT_ENV)))

    dec_t = [0.040 * math.sin(TAU * k / n + cfg["graine"] * 0.7)
             + 0.022 * math.sin(2.0 * TAU * k / n + cfg["graine"] * 1.3)
             for k in range(n)]
    dec_f = [0.038 * math.sin(TAU * k / n + cfg["graine"] * 1.9 + 1.1)
             for k in range(n)]

    niveaux = cfg["niveaux"]
    sommets, anneaux = [], []
    for i in range(niveaux):
        t = i / (niveaux - 1)
        depart = len(sommets)
        for k in range(n):
            f = _profil_env(t, dec_t[k], dec_f[k])
            f = f ** max(0.55, cfg["p_flanc"] * bruit_p[k] * 1.45)
            g = cfg["bombement"] * bruit_b[k] * math.sin(math.pi * t)
            x = base[k].x + (ruban[k].x - base[k].x) * f + dehors[k].x * g
            y = base[k].y + (ruban[k].y - base[k].y) * f + dehors[k].y * g
            z = -SKIRT_ENV + (ruban[k].z + SKIRT_ENV) * t
            sommets.append(Vector((x, y, z)))
        anneaux.append(depart)

    faces, familles = [], []
    for i in range(niveaux - 1):
        a, b = anneaux[i], anneaux[i + 1]
        for k in range(n):
            k2 = (k + 1) % n
            faces.append((a + k, a + k2, b + k2, b + k))
            centre = 0.25 * (sommets[a + k] + sommets[a + k2]
                             + sommets[b + k] + sommets[b + k2])
            familles.append(famille_massif(centre))
    fond = anneaux[0]
    faces.append(tuple(reversed([fond + k for k in range(n)])))
    familles.append("MAT_CaveRock_Base")
    haut = anneaux[-1]
    demi = n // 2
    for st in range(demi - 1):
        faces.append((haut + demi - 1 - st, haut + demi - 2 - st,
                      haut + demi + st + 1, haut + demi + st))
        familles.append("MAT_CaveRock_Face")
    return sommets, faces, familles


## Jupe de l'enveloppe sous le plan de sol — masse PLANTÉE, jamais posée.
SKIRT_ENV = 1.35

ENVELOPPE = [
    # UN SEUL LOFT PORTE L'ÉPAULE ET LA DOMINANTE, et c'est mesuré.
    # Scindé en deux (pour donner une clé d'amas à chacune), le col A se
    # remplissait : deux bases elliptiques qui se chevauchent y cumulent
    # leurs bombements là où une crête unique creuse. Le compte de masses
    # tombait de 3 à 2 aux deux azimuts. Or ce compte est PUREMENT
    # géométrique — `_masses_du_profil()` ne lit aucun objet — donc la
    # scission dégradait la seule mesure qui était déjà juste, pour
    # satisfaire une attribution devenue sans objet (voir `controle_amas`).
    dict(nom="SM_Env_Corps", amas="corps", rang=RANG_ENVELOPPE,
         ancre=(-1.60, 4.00), dg=6.00, dp=5.20, n=52, niveaux=15, graine=11,
         p_flanc=0.62, bombement=0.22, biais=0.18, biais_az=252.0,
         crete=[
             (-7.90, 6.55, 0.55, 0.25), (-7.10, 6.35, 1.60, 0.45),
             (-6.55, 6.20, 1.75, 0.85), (-5.85, 5.95, 2.95, 0.50),
             (-5.35, 5.75, 3.15, 0.95), (-4.75, 5.50, 4.35, 0.55),
             (-4.30, 5.30, 4.85, 1.20), (-3.80, 5.05, 4.55, 0.70),
             # LE COL A EST RECULÉ DE 0,30 m LE LONG DE LA DIRECTION QUI
             # N'EXISTE PAS À 55°. Les axes écran sont (0,9848 ; -0,1736) à
             # 55° et (0,5736 ; -0,8192) à 100° : la droite dx = 0,1763·dy
             # est donc de x écran CONSTANT à 55° et rapporte -0,718 m par
             # mètre à 100°. Reculer le col déplace la frontière de bassin
             # entre l'épaule et la dominante vers la gauche À 100° SEULEMENT,
             # ce qui grossit la dominante sans rien changer à la vue
             # d'approche. Mesuré, à 100° : emprises 4,80 / 6,60 / 3,13 au
             # lieu de 5,06 / 6,33 / 3,13, donc rapport 2,09 au lieu de 2,02
             # — la clause qui franchissait de 1 % en franchit 4.
             # Les deux voisins suivent à mi-course, sinon la crête se casse
             # en angle vif au lieu de fléchir.
             (-3.32, 4.95, 3.85, 0.45), (-2.55, 4.65, 2.60, 0.55),
             (-1.87, 4.05, 3.95, 0.40), (-1.40, 3.55, 4.30, 0.75),
             (-0.70, 3.00, 5.90, 0.45), (-0.20, 2.60, 6.35, 0.70),
             (0.45, 2.20, 7.65, 0.90), (1.05, 1.95, 8.35, 1.30),
             (1.85, 1.95, 8.10, 1.45), (2.35, 2.20, 7.10, 1.05),
             (2.80, 2.55, 6.65, 1.15), (3.30, 3.00, 5.15, 0.55),
             (3.70, 3.35, 4.70, 0.85), (4.05, 3.70, 3.35, 0.50),
             (4.40, 4.05, 2.45, 0.35), (4.70, 4.35, 1.75, 0.30),
             (4.95, 4.60, 1.30, 0.25),
         ]),
    # LE CONTREFORT EST AVANCÉ DE 4,00 m, ET C'EST LE DÉFAUT « deux masses
    # à l'azimut 100 » QUI L'EXIGE. Le relevé par pièce le nomme sans
    # ambiguïté : à 100° le contrefort occupait l'écran de -2,84 à +1,72 et
    # le corps de -9,98 à +2,48 en le SURPLOMBANT PARTOUT — 6,18 puis 8,35
    # puis 2,31 m contre 4,60 au mieux. Il n'était pas « absorbé par
    # superposition » : il était intégralement sous l'enveloppe voisine, et
    # aucun creusement de col ne pouvait l'en sortir.
    #
    # POURQUOI 4,00 m ET PAS 3,27. La mesure de la passe précédente est
    # exacte et le balayage la reproduit au centième : à dy = -3,27 le
    # profil à 100° est INCHANGÉ (2 masses, emprises 6,05 / 9,46). Le seuil
    # de sortie est entre -3,27 et -4,00 ; en deçà le contrefort reste sous
    # le corps, au-delà il émerge. Une piste écartée à -3,27 n'était donc
    # pas la mauvaise piste, seulement la bonne piste trop courte.
    #
    # LA TRANSLATION SUIT dx = 0,1763·dy, la droite de x écran constant à
    # 55°. Conséquence mesurée : l'emprise à 55° reste 17,00 m et le
    # décentrement du faîte 10,0 % POUR TOUT dy — la contrainte
    # `DECENTREMENT_MIN`, qui n'avait que 0,60 m de marge à droite, n'est
    # jamais sollicitée. À 225° l'axe écran vaut (-1 ; 0) : y n'y intervient
    # pas du tout, et l'avancée y est gratuite par construction.
    #
    # LA CRÊTE TOURNE SON SOMMET VERS L'EST (le point haut passe de
    # l'indice 4 à l'indice 5, faîte 4,60 -> 4,49). Le pied rétrécit de
    # 2,10/2,15 à 1,90/1,95 : sa flanquée monte plus tard, le col se
    # déplace vers la droite, et les trois emprises s'écartent au lieu de
    # se ressembler. Aux trois azimuts le rapport d'emprises passe de
    # 2,02 / 1,56 / 1,90 à 2,13 / 2,09 / 2,16.
    #
    # CE QU'ON PERD, ET IL FAUT LE DIRE : le contrefort n'est plus reculé
    # dans la profondeur. Son ancre passe de y = 5,95 à y = 1,95, soit
    # 2,05 m EN AVANT de la dominante au lieu de 3,35 m derrière. C'est le
    # conflit que le calcul d'implantation de R2a-3.5 avait posé et tranché
    # dans l'autre sens ; il se tranche ici dans celui-ci, parce que le
    # recul et les trois masses à 100° ne sont pas simultanément tenables
    # avec un corps de ce diamètre.
    dict(nom="SM_Env_Contrefort", amas="contrefort_droit", rang=RANG_ENVELOPPE,
         ancre=(5.94, 1.95), dg=1.90, dp=1.95, n=22, niveaux=12, graine=37,
         p_flanc=0.70, bombement=0.16, biais=0.18, biais_az=300.0,
         crete=[
             (4.24, 1.05, 1.50, 0.25), (4.74, 1.18, 1.82, 0.29),
             (5.14, 1.28, 2.41, 0.37), (5.64, 1.41, 3.28, 0.67),
             (6.04, 1.51, 3.90, 0.82), (6.44, 1.62, 4.49, 0.74),
             (6.94, 1.74, 4.30, 0.86), (7.34, 1.85, 3.23, 0.58),
             (7.74, 1.95, 1.40, 0.25),
         ]),
    dict(nom="SM_Env_Talus", amas="talus", rang=RANG_ENVELOPPE,
         ancre=(-0.20, 3.70), dg=7.20, dp=4.70, n=28, niveaux=9, graine=53,
         p_flanc=0.56, bombement=0.28, biais=0.16, biais_az=250.0,
         # LA LARGEUR DU RUBAN ALTERNE FORTEMENT, ET C'EST LA CORRECTION DE
         # LA PLAGE PLANE EN FAÇADE. Le pan de 9,01 m² était centré en
         # (-4,68 ; 1,63 ; 2,24) avec une normale à (-0,00 ; -0,26 ; +0,97),
         # c'est-à-dire QUASI HORIZONTALE : ce n'était pas une paroi mais le
         # DESSUS de ce ruban, large de 1,1 à 1,6 m sur 5 m de long.
         #
         # POURQUOI `stratifier()` NE POUVAIT PAS LE CASSER, et c'est une
         # propriété du champ, pas un réglage : `deformer_massif` déplace
         # les sommets VERTICALEMENT en fonction de h = z + 0,11x - 0,06y,
         # et sa marche `s(t)` s'aplatit au MILIEU de chaque lit. Sur une
         # surface déjà presque horizontale il ne casse donc rien : il la
         # tire vers un replat, il en FABRIQUE un. Les points 2 et 3
         # avaient h = 1,852 et 1,783 — le même lit de 0,85 m — donc les
         # 2,7 m qui les séparent formaient une seule terrasse.
         #
         # ESSAYÉ ET MESURÉ, dans l'ordre : séparer les points d'un lit
         # entier en z rend la façade PIRE (11,37 m²) et casse les cols à
         # 100°, parce que le point 2 se projette en écran -5,01, soit
         # exactement sur le col A. C'est la LARGEUR seule qui travaille :
         # un segment étroit est une arête, un segment large une table, et
         # les alterner interdit qu'une table couvre cinq mètres. Le
         # basculement latéral du quadrilatère de cape passe de 10,1° —
         # sous le seuil de regroupement de 12° — à 19,7°.
         # Amplitude mesurée : 0,20 -> 14,18 m² ; 0,30 -> 6,17 ; 0,45 ->
         # 8,55. Le milieu n'est pas un compromis, c'est un optimum.
         crete=[
             (-8.30, 3.60, 0.95, 0.35), (-6.90, 2.85, 2.20, 0.60),
             (-5.60, 2.20, 2.60, 1.80), (-4.20, 1.75, 2.35, 0.80),
             (-2.90, 1.45, 2.10, 1.90), (-1.50, 1.30, 1.85, 0.90),
             (-0.10, 1.35, 2.15, 1.90), (1.30, 1.60, 2.45, 0.90),
             (2.70, 2.05, 2.30, 1.80), (4.10, 2.70, 1.60, 0.80),
             (5.40, 3.45, 1.30, 1.70), (6.80, 4.30, 1.35, 0.70),
             (8.10, 5.20, 0.75, 0.35),
         ]),
    # LA QUEUE RÉTRÉCIT AU LIEU D'AVANCER, ET C'EST UNE CORRECTION D'UNE
    # PREMIÈRE TENTATIVE QUI AVAIT ÉTÉ MESURÉE MAUVAISE.
    #
    # Ce qu'il fallait obtenir : c'est la queue qui tient le bord GAUCHE de
    # la silhouette à 100° — relevé par pièce, Queue[-11,11 .. -3,82] quand
    # le corps s'arrête à -9,98 — alors qu'à 55° elle occupe
    # [-6,26 .. 3,36] pour un bord à -9,25, et à 225° [-5,05 .. 4,98] pour
    # un bord à 8,83. Elle n'est extrême qu'à 100°, donc la retoucher n'y
    # coûte rien ailleurs. Une fois le contrefort sorti, la faute résiduelle
    # à 100° était « deux emprises à 1,02 % l'une de l'autre » : il fallait
    # remonter `lo`.
    #
    # PREMIÈRE TENTATIVE, AVANCER DE 1,20 m : la faute de silhouette passe,
    # mais la plage plane globale explose de 10,02 à 19,66 m² — une rampe
    # de 8,55 x 3,38 m inclinée à 36°, centrée en (0,53 ; 7,75 ; 2,25),
    # normale (+0,20 ; -0,55 ; +0,81). La cause est lisible : avancer la
    # queue referme le vallon qui la séparait du corps, et le remaillage
    # voxel fond les deux flancs en un seul plan continu.
    #
    # CE QUI MARCHE : la garder à sa place et réduire son demi-petit axe.
    # La direction écran à 100° tombe à 116,7° de son axe de crête, où le
    # rayon d'ellipse est pondéré 0,894 par `dp` et seulement 0,45 par
    # `dg` — c'est donc `dp` qui tient `lo`, et `ddg = -1,6` ne l'avait
    # déplacé que de 2 cm. Mesuré : dp 3,10 -> 2,50 rend le même effet de
    # silhouette (100° : ratio 2,02, consécutif 1,25) avec la plage globale
    # à 8,39 m², soit MIEUX que les 10,02 m² d'avant la passe.
    dict(nom="SM_Env_Queue", amas="queue", rang=RANG_ENVELOPPE,
         ancre=(-0.20, 8.50), dg=5.40, dp=2.50, n=18, niveaux=9, graine=71,
         p_flanc=0.60, bombement=0.22, biais=0.20, biais_az=90.0,
         crete=[
             (-4.10, 8.40, 2.90, 0.60), (-2.80, 9.00, 2.45, 1.40),
             (-1.50, 9.45, 2.35, 2.00), (-0.10, 9.75, 3.30, 1.60),
             (1.30, 9.90, 3.15, 1.80), (2.60, 9.80, 2.55, 1.20),
             (3.80, 9.55, 1.85, 0.40),
         ]),
    # LÈVRE — le linteau ET LES DEUX JAMBAGES. Sa crête est posée EN AVANT
    # de son pied : elle déverse au-dessus de la bouche au lieu de la
    # border. Sans elle le seuil n'a que 0,47 m de roche pour 0,90 exigés.
    #
    # ELLE S'ÉPAISSIT PARCE QUE LA MESURE L'EXIGE, PAS PAR GOÛT. Sonde de
    # portée depuis l'axe, station 1, dans le plan XZ à z = clé·0,45 =
    # 1,28 m — la même origine que `controle_epaisseur` :
    #
    #     azimut   120°   135°   150°   165°   180°     45°    60°
    #     avant    2,17   1,96   1,92   1,83   3,21    2,10   2,26
    #     après    3,20   3,47   3,45   3,61   3,73    3,20   2,91
    #
    # La cible est 2,86 m = 2,26 m de portée latérale de la cavité refondue
    # plus les 0,60 m de `EPAISSEUR_MIN_COLLERETTE_M`. Tous les azimuts
    # latéraux la franchissent désormais ; le minimum est 2,91 m à 60°.
    # C'est le défaut que la collerette signalait à 0,18 m, station 1,
    # azimut 129° — le JAMBAGE GAUCHE.
    #
    # POURQUOI LA CRÊTE, ET NON LE PIED. Le point à couvrir à 135° est
    # (-2,02 ; 0 ; 3,30) : il est AU-DESSUS de l'ancienne crête, qui ne
    # valait que 2,30 m à x = -1,85. Aucun élargissement de base ne
    # l'atteint — mesuré, `dg` de 2,60 à 4,30 avec bombement et p_flanc
    # poussés au maximum ne monte 165° que de 1,83 à 2,26. Il fallait
    # ALLONGER et RELEVER la crête vers -x. Les deux jambages sont
    # volontairement inégaux — gauche plus long et plus haut — ce qui est
    # aussi la cible écrite pour la bouche : « jambages non parallèles ».
    #
    # `dp` RESTE À 2,20, ET C'EST UN INTERDIT MESURÉ : à 2,70 la station 0
    # passe de « aucune matière » à 1,00–1,55 m de roche sur tout le tour.
    # Autrement dit la lèvre MURE LE PORCHE. On épaissit sur ±x, jamais
    # vers -y.
    dict(nom="SM_Env_Levre", amas="levre", rang=RANG_ENVELOPPE,
         ancre=(-0.35, 1.35), dg=4.00, dp=2.20, n=24, niveaux=12, graine=89,
         # `biais` RESTE A 0,30 : ESSAYE A 0,42, MESURE, REJETE. Pousser
         # la levre plus loin vers -y ameliore la portee brute au porche
         # (45° : 0,40 -> 1,09 m) mais fait tomber la collerette de 0,48 a
         # 0,08 m et deplace les percees vers 109-135°. La cause est
         # geometrique : la masse deversee devient une coquille mince que
         # le rayon traverse au lieu d'un jambage. Plus de porte-a-faux
         # n'est pas plus de roche.
         p_flanc=0.88, bombement=0.40, biais=0.30, biais_az=270.0,
         crete=[
             (-3.60, 1.15, 2.30, 0.40), (-2.85, 0.80, 3.40, 0.85),
             (-2.05, 0.52, 4.05, 1.15), (-1.05, 0.38, 4.30, 1.30),
             (0.05, 0.35, 4.25, 1.35), (1.10, 0.40, 4.05, 1.20),
             (2.10, 0.55, 3.70, 1.00), (3.00, 0.85, 2.95, 0.70),
             (3.75, 1.30, 2.05, 0.30),
         ]),
    # VISIÈRE — LE SURPLOMB DU PORCHE. C'est la pièce que R2a-3.4 avait et
    # que la nouvelle enveloppe n'avait pas : l'ancien `MASSIF` portait une
    # « visière saillante » à la station 0 (jeu latéral 1,70 contre 1,30,
    # jeu de clé 1,55 contre 1,35), et `MASSIF` ne sert plus qu'au proxy de
    # collision. Elle est reconstruite ici, dans l'enveloppe.
    #
    # LE DÉFAUT MESURÉ, ET IL N'ÉTAIT PAS CELUI QU'ON CROYAIT. Le journal
    # n'imprimait que `percees[:5]` : on a lu « cinq rayons sortent par un
    # jour » et « collerette 0,48 m pour 0,60 », donc un manque de trois
    # quarts de mètre sur un périmètre par ailleurs sain. En comptant TOUS
    # les rayons de la station 0 : 25 sur 33 sortent par un jour, azimuts
    # 39° à 193° SANS INTERRUPTION. Le 0,48 était le minimum des sept
    # rayons survivants — un nombre qui répond à une autre question. Sur
    # les trois quarts du périmètre du porche il n'y avait AUCUNE ROCHE.
    #
    # Carte d'occupation du plan y = -1,15 (le plan de la station 0), avant
    # cette pièce : au-dessus de z = 1,80 aucune roche entre x = -4 et
    # x = +4 ; le seul appui était un contrefort bas à droite,
    # x de 0,6 à 1,4. Le linteau ne commençait qu'à y = -0,90.
    #
    # CE QUI MANQUE EST UN SURPLOMB, ET LA MESURE LE DIT. Relevé du y le
    # plus AVANT portant de la roche, colonne x = 0 :
    #
    #     z      2,20   2,40   2,80   3,20   4,00
    #     front -1,00  -0,95  -0,85  -0,65  -0,35
    #
    # La façade PENCHE EN ARRIÈRE : plus on monte, plus la roche recule.
    # L'avance nécessaire n'est que de 0,20 à 0,75 m, dans la bande
    # x de -3,4 à +2,4 et z de 1,5 à 3,6 — et RIEN en dessous de z = 1,5,
    # là où vit la vue d'approche. On ne mure donc pas le porche : on lui
    # rend une lèvre au-dessus et sur les côtés, jamais devant.
    #
    # POURQUOI UNE PIÈCE ET NON UN DÉPLACEMENT DE LA CRÊTE DE LA LÈVRE.
    # Essayé d'abord, parce que c'était le geste le plus économe : avancer
    # la crête de `SM_Env_Levre` de 1,0 à 1,4 m ferme bien les 25 jours, et
    # coûte trois régressions mesurées —
    #
    #     paroi mini            0,87 -> 0,70 m (station 2, azimut 116°)
    #     masses a 100°         3 -> 2 a l'entaille 0,90
    #     plage plane facade    4,63 -> 8,21 m2 (seuil 6,00)
    #
    # La cause est structurelle et non un mauvais réglage : la crête de la
    # lèvre PORTE DÉJÀ la paroi de la station 2. La déplacer est un jeu à
    # somme nulle — ce qui arrive au porche part d'ailleurs. Une pièce
    # séparée ajoute sans retirer : mêmes silhouettes aux trois azimuts,
    # même paroi, façade améliorée.
    #
    # LA HAUTEUR N'EST PAS UN GOÛT, ELLE EST IMPOSÉE PAR LA COMPOSITION.
    # À l'azimut 100 l'axe écran vaut (0,5736 ; -0,8192), et le col entre
    # la dominante et le contrefort a son plancher à z = 3,28 (prominence
    # 1,21 sous un faîte à 4,49). Toute matière neuve dont l'écran tombe
    # dans ce col — c'est-à-dire 0,5736·x - 0,8192·y compris entre 0,3 et
    # 1,0 — doit rester SOUS 3,20 m, sinon elle comble le col et les trois
    # masses deviennent deux. À gauche (écran négatif) elle passe sous la
    # dominante, dont le faîte est à 8,35, et peut monter à 3,6.
    #
    # C'est cette contrainte, et elle seule, qui met le SOMMET DE LA
    # VISIÈRE À GAUCHE de l'axe de la bouche au lieu d'au-dessus. La
    # composition impose la forme, ce n'est pas un goût.
    #
    # ELLE EST DÉLIBÉRÉMENT DISSYMÉTRIQUE. Le contrefort gauche est plus
    # long, plus haut et plus avancé ; le droit est court, bas, et meurt
    # dans la pente. Cela suit ce que la cavité dit déjà d'elle-même :
    # `CAVITE_ASYM[0] = (1,34 ; 0,79 ; -0,44)`, joue gauche débordante et
    # linteau penché. C'est aussi le côté du déficit historique — « la
    # collerette la plus mince : station 1, azimut 129° », le jambage
    # gauche relevé.
    #
    # LES LARGEURS DE RUBAN ALTERNENT FORTEMENT, et c'est la recette
    # mesurée du Talus, pas une décoration : un segment étroit est une
    # arête, un segment large une table ; les alterner interdit qu'une
    # table couvre cinq mètres. Sans alternance, `deformer_massif` FABRIQUE
    # un replat sur toute surface déjà presque horizontale — sa marche
    # s'aplatit au milieu de chaque lit. Le dessous de la visière, lui,
    # n'est pas dessiné du tout : c'est la trace de découpe du tube
    # prolongé, donc irrégulier par construction, comme la bouche.
    #
    # ANCRE ET PIED. Le pied reste PLANTÉ DANS LA MASSE — l'ellipse de base
    # recouvre franchement `SM_Env_Levre` et `SM_Env_Corps`, donc
    # `controle_penetration` la voit solidaire et le remaillage voxel la
    # fond. Seule la crête est en avant de son pied : c'est ce qui déverse.
    # `amas="levre"` : elle appartient à l'amas du porche, elle n'ouvre pas
    # un quatrième amas.
    # LE PIED RESTE EN ARRIÈRE, SEULE LA CRÊTE VA EN AVANT — et c'est une
    # mesure, pas une préférence. Au premier jet, `dp = 1,60` et
    # `biais = 0,34` portaient l'ellipse de base à y = -2,04 : le rim de la
    # bouche descendait jusqu'à y = -3,10 (au lieu de -1,50), c'est-à-dire
    # que la roche marchait deux mètres devant le plan du porche AU NIVEAU
    # DU SOL. Deux conséquences mesurées :
    #
    #   * la sonde de collerette y trouvait une coquille de 0,32 m à
    #     (0,86 ; -1,68 ; 0,93) — le pied droit de la visière, une plaque
    #     que `controle_epaisseur` ne peut pas voir puisque ses rayons
    #     partent de l'axe dans le plan y = -1,15 ;
    #   * la plage plane en façade montait de 4,63 à 5,39 m2, centrée en
    #     (2,39 ; -0,79 ; 1,15) — le flanc bas de ce même pied.
    #
    # C'est exactement le défaut que `biais = 0,42` avait produit sur la
    # lèvre en R2a-3.5.1, et pour la même raison géométrique : une masse
    # déversée par le PIED devient une coquille mince que le rayon traverse,
    # pas un jambage. Le porte-à-faux doit venir de la CRÊTE.
    #
    # MAIS LE PIED NE PEUT PAS RECULER DES DEUX CÔTÉS, ET C'EST MESURÉ AUSSI.
    # `dp = 0,95` avec `biais = 0,16` à 270° recule le pied partout : la
    # façade tombe bien à 4,45 m2 et la coquille disparaît, mais SIX JOURS
    # ROUVRENT à la station 0, azimuts 154° à 186° — le flanc gauche. C'est
    # lui qui portait la roche : à l'azimut 180° le rayon traverse
    # l'ouverture jusqu'à x = -2,21 et n'a plus rien devant lui.
    #
    # Le pied est donc DISSYMÉTRIQUE, par `biais_az = 238°` : l'ellipse de
    # base est portée en avant ET À GAUCHE, jamais en avant à droite. Base
    # mesurée : y = -1,09 à l'azimut 210° et y = -1,36 à 250° (gauche, en
    # avant), contre y = -0,76 à 330° (droite, en retrait). C'est la même
    # dissymétrie que la bouche impose déjà — joue gauche débordante,
    # linteau penché — obtenue avec le levier que les quatre autres pièces
    # d'enveloppe emploient déjà (Corps 252°, Talus 250°, Contrefort 300°).
    dict(nom="SM_Env_Visiere", amas="levre", rang=RANG_ENVELOPPE,
         ancre=(-0.55, 0.20), dg=3.90, dp=2.00, n=22, niveaux=11, graine=131,
         p_flanc=0.74, bombement=0.22, biais=0.34, biais_az=238.0,
         # LE FLANC GAUCHE EST PORTÉ EN AVANT, ET C'EST LA DERNIÈRE ENCOCHE
         # QUI L'EXIGE. Au premier jet de cette pièce, les 25 jours étaient
         # fermés et la collerette valait 0,77 à 1,59 m partout SAUF entre
         # 148° et 161°, minimum 0,38 m à 154°, au point
         # (-1,93 ; -1,15 ; 2,19) : l'épaule gauche de la bouche, là où le
         # linteau incliné monte le plus haut. Les deux points de crête
         # x = -2,70 et x = -1,95 sont la réponse ; leur écran a 100° vaut
         # -1,26 et -0,30, donc a gauche du col, ou la hauteur est libre.
         #
         # LA HAUTEUR DE CRÊTE EST UN ARBITRAGE MESURÉ, ET IL SE PAIE.
         # Le dernier point mince ne sortait ni par le côté ni par le bas :
         # il sortait par LE TOIT. Colonne verticale en (-0,64 ; -0,54) :
         # plafond de galerie à z = 2,67, sommet de roche à z = 3,80, soit
         # 1,13 m à la verticale — mais 0,48 m seulement le long de la
         # NORMALE du plafond, qui pointe vers l'avant-haut et ressort par
         # la pente du toit à (-0,64 ; -0,83 ; 3,05). C'est le toit qu'il
         # fallait relever, pas le flanc.
         #
         # Relever la crête centrale de 3,18 à 3,45–3,50 donne, mesuré :
         #
         #     controle_epaisseur, collerette   0,80 -> 1,05 m
         #     sonde min(A, B) a la bouche      0,48 -> 0,68 m
         #     plage plane en facade            3,94 -> 3,08 m2
         #
         # ET IL COÛTE 0,15 m DE PROÉMINENCE AU COL DE 100°. La masse 3
         # (contrefort) passe de 1,21 à 1,06 m de proéminence : le portail
         # est à `ENTAILLE_LECTURE_M = 0,90`, donc la marge tombe de 0,31 à
         # 0,16 m. La ligne de télémétrie « entaille 1,20 » bascule de 3 à
         # 2 masses — mais elle passait avec 0,01 m (1,21 contre 1,20) :
         # ce n'était pas une marge, c'était une pièce en équilibre sur la
         # tranche. Le fait est écrit ici parce qu'il est réel, pas parce
         # qu'il est confortable.
         #
         # Balayage complet, pour que l'arbitrage soit relisible :
         #     crete centrale 3,18 -> min(A,B) 0,48 · 100° a 1,20 : 3 masses
         #                    3,34 -> min(A,B) 0,56 · 100° a 1,20 : 2 masses
         #                    3,45 -> min(A,B) 0,68 · 100° a 1,20 : 2 masses
         # Le palier intermédiaire perd la télémétrie SANS gagner la
         # collerette : il n'existe pas de réglage qui garde les deux.
         #
         # L'ORTEIL DROIT — ET C'EST UNE MESURE QUI M'A DONNÉ TORT.
         #
         # Ma sonde à sphère inscrite lisait 0,68 m et je l'ai crue. Un
         # troisième instrument, en transformée de distance sur une coupe
         # RASTÉRISÉE du plan de bouche, lisait 0,566 m. Vérification faite
         # avec une EDT euclidienne EXACTE au pas de 0,04 m et un goulot de
         # coupe minimale par union-find : **0,5657 m**, au (x 1,62 ;
         # z 0,34) du plan y = -1,15. Les deux concordent, et c'est le mien
         # qui était trop généreux.
         #
         # LA RAISON EST GÉOMÉTRIQUE, PAS NUMÉRIQUE : une sphère inscrite
         # en 3D peut S'ÉCHAPPER LE LONG DE Y, où le jambage est épais. La
         # collerette, elle, se mesure DANS LE PLAN de bouche — comme le
         # fait `controle_epaisseur`. Une mesure 3D est donc structurellement
         # optimiste ici. Une méthode sans direction n'est pas pour autant
         # sans biais, et le verdict reste le plus sévère des trois.
         #
         # LE DÉFAUT ÉTAIT RÉEL. Le jambage droit est un bandeau INCLINÉ
         # d'environ 36° : 0,70 m de large à l'horizontale, donc 0,566 m
         # perpendiculairement. La largeur horizontale n'est pas l'épaisseur
         # — c'est pour ça que la carte d'occupation ne suffisait pas.
         #
         # POURQUOI TROIS POINTS DE CRÊTE ET NON UN RÉGLAGE. Essayés et
         # mesurés, tous SANS LE MOINDRE EFFET sur le goulot (0,5657 m
         # inchangé au centième) : `dp` 1,30 -> 1,55 avec `biais_az` 238 ->
         # 254 ; puis `bombement` 0,22 -> 0,48. La cause : à cet endroit la
         # peau extérieure appartient à `SM_Env_Levre`, pas à la visière —
         # ni son pied ni son bombement n'y arrivent. Il fallait donner à la
         # visière un ORTEIL qui descende et avance de ce côté, plutôt que
         # de retoucher la lèvre, dont le coût est mesuré plus haut.
         #
         # Progression mesurée de l'orteil, goulot dans le plan de bouche :
         #     sans orteil                        0,566 m
         #     y -0,95 · ruban 1,10               0,609 m
         #     y -1,25 · ruban 1,60               0,645 m
         #     y -1,40 · ruban 2,05  <- retenu    0,720 m
         #     y -1,55 · ruban 2,35               0,720 m
         # Le dernier palier n'apporte rien pour plus de matière : un autre
         # goulot prend le relais. On garde le plus sobre à mesure égale.
         #
         # L'orteil est BAS (crête 1,85 m) et LARGE, quand l'épaule gauche
         # est HAUTE (3,55 m) et étroite : la dissymétrie ne disparaît pas,
         # elle change de nature d'un côté à l'autre.
         crete=[
             (-3.45, 0.15, 1.90, 0.30), (-2.75, -0.90, 2.90, 1.55),
             (-1.95, -1.30, 3.70, 0.70), (-1.10, -1.45, 3.50, 1.90),
             (-0.20, -1.30, 3.45, 0.80), (0.70, -0.95, 3.30, 1.75),
             (1.50, -0.55, 2.35, 0.55), (2.05, -1.40, 1.85, 2.05),
             (2.70, -0.60, 1.20, 0.55), (3.20, 0.40, 0.70, 0.25),
         ]),
]


def pieces_enveloppe():
    """Construit les volumes d'enveloppe et rend (objets, configs)."""
    objets, configs = [], []
    for cfg in ENVELOPPE:
        s, f, fam = masse_enveloppe(cfg)
        objets.append(objet(cfg["nom"], s, f, fam, True))
        configs.append(cfg)
    return objets, configs


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


## -------------------------------------------------------------------------
## R2a-3.5.3 — LE DOMAINE DU CONTRÔLE D'ÉPAISSEUR, ÉTENDU À TOUTE LA ROCHE
## -------------------------------------------------------------------------
## `controle_epaisseur()` ci-dessus tire ses rayons depuis les stations de
## `CAVITE`, dont la dernière est à `ay = 3,17`. Toute roche au-delà est
## HORS DE SON DOMAINE — pas mal mesurée : pas mesurée du tout. Le massif
## court jusqu'à `ay ≈ 11,9`.
##
## Ces constantes sont NOUVELLES. Aucun seuil existant n'est touché :
## `EPAISSEUR_MIN_M` vaut toujours 0,80 m et c'est lui qui juge.
PAS_DOMAINE_M = 0.10        # pas métrique du balayage, publié dans le rapport
MARGE_DOMAINE_M = 0.60      # dilatation de l'emprise : un bord doit être vu
VIDE_QUALIFIANT_M = 1.00    # sous 1 m, c'est une fissure, pas une salle
VOISINS_PLAQUE_MIN = 6      # >= 6 des 8 voisins ont un vide -> plaque


def _tranches_verticales(arbre, ax, ay, z_ciel, z_fond):
    """Colonne verticale en (ax, ay), lue PAR ENLACEMENT et non par parité.

    POURQUOI PAS LA PARITÉ, ET C'EST LE RÉSULTAT QUI A OUVERT R2a-3.5.3
    ==================================================================

    La règle de parité de `tools/CLAUDE.md` suppose que le maillage ne se
    traverse pas lui-même. Celui-ci se traverse — `controle_repli()` le
    mesure et le TOLÈRE jusqu'à `REPLI_LIVRABLE_MAX_M`. Mesuré sur le
    candidat `cc3596c5`, la colonne (0,50 ; 5,80) rend la séquence de
    normales

        entree, entree, sortie, sortie, entree, entree, sortie, sortie

    qui n'alterne pas. Lue par parité elle annonce « 0,038 m de roche
    au-dessus d'un vide de 1,41 m » — le défaut qui a arrêté la passe
    précédente. Lue par enlacement, et vérifiée dans huit directions
    indépendantes, elle rend **3,06 m de roche continue au-dessus d'un vide
    de 0,30 m**. Il n'y a pas de lame à cet endroit.

    On accumule donc les traversées signées depuis le ciel : +1 quand la
    face regarde vers le haut (le rayon descendant entre), -1 sinon.
    Enlacement >= 1 = matière. Les tranches de même nature qui se touchent
    sont fusionnées, sans quoi un pli interne découperait une roche
    continue en fausses lames.
    """
    depart = Vector((ax, ay, z_ciel))
    direction = Vector((0.0, 0.0, -1.0))
    portee = (z_ciel - z_fond)
    impacts = []
    parcouru = 0.0
    for _ in range(64):
        touche = arbre.ray_cast(depart, direction, portee - parcouru)
        if touche is None or touche[0] is None:
            break
        z = touche[0].z
        nz = touche[1].z
        if abs(nz) > 1e-6:
            delta = +1 if nz > 0.0 else -1
            if not impacts or abs(impacts[-1][0] - z) > 1e-4 \
                    or impacts[-1][1] != delta:
                impacts.append((z, delta))
        avance = (touche[0] - depart).length + 1e-4
        parcouru += avance
        depart = touche[0] + direction * 1e-4
        if parcouru >= portee:
            break
    brut, enlacement = [], 0
    for k in range(len(impacts) - 1):
        enlacement += impacts[k][1]
        brut.append(("roche" if enlacement >= 1 else "vide",
                     impacts[k][0], impacts[k + 1][0]))
    tranches = []
    for nature, haut, bas in brut:
        if tranches and tranches[-1][0] == nature:
            tranches[-1] = (nature, tranches[-1][1], bas)
        else:
            tranches.append((nature, haut, bas))
    return tranches


def _cumul_au_dessus_du_vide(tranches):
    """Toute la roche séparant du ciel le vide qualifiant le plus HAUT.

    LE CUMUL, ET NON « LA PREMIÈRE ROCHE ». C'est la définition que
    `controle_epaisseur()` se donne à lui-même vingt lignes plus haut :
    « La question posée est "combien de roche sépare la galerie du dehors",
    et sa réponse est la somme. »

    Mesuré en (1,70 ; 5,30) sur le candidat, la première roche au-dessus du
    vide fait 0,050 m — mais 0,135 m plus haut se tient un banc de 2,086 m.
    Le joueur est sous 2,14 m de pierre ; annoncer 5 cm désignerait un
    feuillet délaminé par la décimation comme s'il était le toit.

    MAIS LE CUMUL NE SUFFIT PAS, ET C'EST UNE CORRECTION DE R2a-3.5.3.
    ==================================================================

    Le cumul peut CACHER une lame derrière un banc épais. Mesuré sur la
    géométrie livrée R2a-3.4, en (-0,20 ; -2,60), la colonne vaut

        roche 0,957 | vide 0,471 | roche 0,020 | vide 2,768 | roche 2,602

    Le vide de 0,471 m ne qualifie pas ; le cumul additionne donc
    0,957 + 0,020 = 0,977 m et PASSE le seuil, alors qu'il y a bel et bien
    une lame de deux centimètres — vérifiée dans huit directions
    indépendantes, et plus mince que le défaut qui a arrêté la passe
    précédente.

    On rend donc LES DEUX : le cumul, qui répond à « combien de roche
    sépare du dehors », et l'épaisseur du premier banc surmontant le vide,
    qui répond à « y a-t-il une plaque », c'est-à-dire à la lettre du
    contrat. C'est la seconde qui juge ; la première est publiée à côté.

    Rend (cumul, premier_banc, hauteur_du_vide, nombre_de_bancs) ou None.
    """
    for k, (nature, haut, bas) in enumerate(tranches):
        if nature != "vide" or (haut - bas) < VIDE_QUALIFIANT_M:
            continue
        cumul, bancs, dernier = 0.0, 0, None
        for nature2, haut2, bas2 in tranches[:k]:
            if nature2 != "roche":
                continue
            e = haut2 - bas2
            if e >= EPAISSEUR_ECAILLE_M:
                cumul += e
                bancs += 1
                dernier = e
        return (cumul, dernier if dernier is not None else 0.0,
                haut - bas, bancs)
    return None


def controle_epaisseur_domaine(obj):
    """Épaisseur de roche sur TOUT le domaine, pas seulement aux stations.

    Trois états par colonne, et la distinction n'est pas cosmétique :

      * `aucune matiere` — un vide qualifiant sans un gramme de roche
        au-dessus. C'est la BOUCHE, ou le ciel au-dessus du terrain : la
        géométrie voulue, jamais une faute ;
      * `matiere pleine` — cumul >= `EPAISSEUR_MIN_M` ;
      * `lame mince`     — 0 < cumul < `EPAISSEUR_MIN_M`. La faute.

    Les lames sont ensuite séparées en PLAQUES et BORDS. Un rayon vertical
    rend une épaisseur qui tend vers zéro partout où un vide se termine
    latéralement : au bord d'un porche ou d'un surplomb, l'épaisseur
    verticale de la roche EST nulle, par définition du bord. Mesuré, le
    minimum du domaine complet tombe sur un tel bord sur les TROIS
    géométries, y compris la livrée R2a-3.4. Une colonne mince est donc
    tenue pour une plaque si au moins `VOISINS_PLAQUE_MIN` de ses huit
    voisins présentent eux aussi un vide qualifiant ; sinon c'est un bord.
    Les deux populations sont comptées et publiées séparément — on n'en
    cache aucune.

    LE CONTRÔLE DE COUVERTURE. Ce balayage n'a le droit d'annoncer un
    minimum que s'il a réellement vu tout le domaine. Il compare donc son
    emprise échantillonnée à l'emprise réelle du maillage, dilatée de
    `MARGE_DOMAINE_M`, et rend une faute de couverture s'il en manque un
    bout. Sans cela il répéterait exactement la panne qu'il corrige :
    publier un chiffre juste sur un domaine trop petit.

    Rend un dictionnaire de télémétrie, toujours — jamais None.
    """
    arbre = bvh_depuis(obj)
    xs_o = [v.co.x for v in obj.data.vertices]
    ys_o = [v.co.y for v in obj.data.vertices]
    zs_o = [v.co.z for v in obj.data.vertices]
    exige = (min(xs_o) - MARGE_DOMAINE_M, max(xs_o) + MARGE_DOMAINE_M,
             min(ys_o) - MARGE_DOMAINE_M, max(ys_o) + MARGE_DOMAINE_M)
    z_ciel, z_fond = max(zs_o) + 1.0, min(zs_o) - 1.0

    n_x = int(math.ceil((exige[1] - exige[0]) / PAS_DOMAINE_M)) + 1
    n_y = int(math.ceil((exige[3] - exige[2]) / PAS_DOMAINE_M)) + 1
    xs = [exige[0] + i * PAS_DOMAINE_M for i in range(n_x)]
    ys = [exige[2] + j * PAS_DOMAINE_M for j in range(n_y)]

    couvert = (xs[0], xs[-1], ys[0], ys[-1])
    manques = []
    if couvert[0] > exige[0] + 1e-9 or couvert[1] < exige[1] - 1e-9:
        manques.append("x couvert [%.2f ; %.2f], exige [%.2f ; %.2f]"
                       % (couvert[0], couvert[1], exige[0], exige[1]))
    if couvert[2] > exige[2] + 1e-9 or couvert[3] < exige[3] - 1e-9:
        manques.append("y couvert [%.2f ; %.2f], exige [%.2f ; %.2f]"
                       % (couvert[2], couvert[3], exige[2], exige[3]))
    if len(xs) * len(ys) != n_x * n_y:
        manques.append("compte de colonnes incoherent")

    vides = {}
    aucune, pleine, minces = 0, 0, []
    for j, ay in enumerate(ys):
        for i, ax in enumerate(xs):
            trouve = _cumul_au_dessus_du_vide(
                _tranches_verticales(arbre, ax, ay, z_ciel, z_fond))
            if trouve is None:
                continue
            vides[(i, j)] = trouve
            cumul, banc, hauteur, bancs = trouve
            if bancs == 0:
                aucune += 1
            elif banc >= EPAISSEUR_MIN_M:
                pleine += 1
            else:
                # LE BANC, PAS LE CUMUL : c'est lui qui dit « plaque ».
                minces.append((banc, ax, ay, hauteur, i, j, cumul))
    minces.sort()

    plaques, bords = [], []
    for banc, ax, ay, hauteur, i, j, cumul in minces:
        n = sum(1 for di in (-1, 0, 1) for dj in (-1, 0, 1)
                if (di or dj) and (i + di, j + dj) in vides)
        (plaques if n >= VOISINS_PLAQUE_MIN else bords).append(
            (banc, ax, ay, hauteur, n, cumul))

    return dict(pas=PAS_DOMAINE_M, couvert=couvert, exige=exige,
                colonnes=len(xs) * len(ys), qualifiantes=len(vides),
                manques=manques, aucune_matiere=aucune, matiere_pleine=pleine,
                plaques=plaques, bords=bords)


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



def controle_plancher(obj):
    """LE RAYON VERS LE BAS — la direction que rien ne regardait.

    LA CIRCULARITÉ, ÉCRITE DANS LE TEXTE DES DEUX FONCTIONS :

      * `controle_epaisseur()` écarte les rayons descendants —
        `if math.sin(theta) < -0.30: continue` — en justifiant que « le
        plancher est garanti autrement : par `controle_aucun_jour` » ;
      * `controle_aucun_jour()` ne tire que `Vector((0.0, 0.0, 1.0))`,
        c'est-à-dire vers le HAUT.

    Chacune renvoyait à l'autre. Le sol de la galerie n'a donc jamais été
    mesuré, et `tools/probe_cave_openings.py` — écrit hors du générateur,
    justement pour sortir du cercle — a trouvé le plancher ABSENT de
    y = +0,00 à y = +5,50 : le rayon tombait jusqu'au sommet de l'assise, à
    z ≈ −0,45, soixante centimètres sous le profil déclaré.

    Ce contrôle-ci ferme le cercle à l'intérieur du générateur, pour que la
    faute soit vue avant l'export et non trois quarts d'heure après. Il ne
    remplace pas la sonde : la sonde mesure le GLB LIVRÉ, ce qui vaut mieux,
    et couvre en plus la sphère entière et la ligne de vue.

    Le départ du rayon est pris au-dessus du sol déclaré, jamais à une
    hauteur fixe : un départ fixe tombe dans la roche aux stations dont le
    palier remonte, et rend alors une face de dessous pour un plancher.
    On ne retient que le premier impact dont la NORMALE regarde vers le
    haut — c'est la définition d'un sol.

    Rend (nombre de points sondés, liste de fautes).
    """
    bvh = bvh_depuis(obj)
    fautes = []
    sondes = 0
    u = 0.0
    while u <= len(CAVITE) - 1 + 1e-6:
        ax, ay, hw, cle = station_de_cavite(u)
        nx, ny = normale_de_cavite(u)
        for f in PLANCHER_FRACTIONS:
            attendu = sol_de_cavite(u, f)
            # LA FRACTION EST CELLE DU CÔTÉ, PAS DE `hw` — voir
            # `facteur_lateral()`. Sans ce terme, sept des neuf fautes de
            # plancher relevées en R2a-3.5.1 étaient des rayons partis de la
            # roche pleine, du côté que l'asymétrie venait de rétrécir.
            fac = facteur_lateral(u, f)
            x, yl = ax + f * hw * fac * nx, ay + f * hw * fac * ny
            # LA HAUTEUR DE DÉPART SE DÉRIVE DE LA SECTION, PAS D'UNE
            # CONSTANTE. Premier jet : départ à `attendu + cle · 0,45` quelle
            # que soit la position latérale. Mesuré — à la fraction ±0,75 de
            # la station 8, la voûte est déjà redescendue à 1,46 m et le
            # départ tombait à 1,80 : le rayon partait DANS la roche, ne
            # rencontrait aucune normale tournée vers le haut, et le contrôle
            # criait « aucun sol » là où il y avait de la roche pleine. Un
            # contrôle qui rougit à tort finit désactivé.
            #
            # On reprend donc la branche haute de `anneau_interieur()` —
            # `z = cle · v^0,75` — avec `v = sqrt(1 − f²)` sur la section.
            # Le linteau est INCLINÉ : `anneau_interieur()` multiplie la clé
            # par `1 + inclinaison·u`. Sans ce facteur, la voûte estimée est
            # trop haute du côté bas et le contrôle sonde dans la roche.
            voute = (cle * max(0.0, 1.0 - f * f) ** 0.375
                     * (1.0 + inclinaison_de_cavite(u) * f))
            libre = voute - attendu
            if libre < PLANCHER_HAUTEUR_MIN_M:
                continue          # trop près de la paroi pour vouloir dire quoi que ce soit
            depart = Vector((x, yl, attendu + 0.45 * libre))
            sondes += 1
            position = depart.copy()
            mesure = None
            trace = []
            for _ in range(12):
                r = bvh.ray_cast(position, Vector((0.0, 0.0, -1.0)), 8.0)
                if r is None or r[0] is None:
                    break
                trace.append((r[0].z, r[1].z if r[1] is not None else 0.0))
                if r[1] is not None and r[1].z > 0.30:
                    mesure = r[0].z
                    break
                position = r[0] - Vector((0.0, 0.0, 0.002))
            if mesure is None:
                fautes.append((u, f, x, yl, attendu, None, depart.z, trace))
            elif abs(mesure - attendu) > SOL_TOLERANCE_M:
                fautes.append((u, f, x, yl, attendu, mesure, depart.z, trace))
        prochain = min(len(CAVITE) - 1.0, u + 0.05)
        avance = 0.0
        while prochain < len(CAVITE) - 1.0 and avance < PLANCHER_PAS_M:
            a = station_de_cavite(u)
            b = station_de_cavite(prochain)
            avance = math.hypot(b[0] - a[0], b[1] - a[1])
            if avance < PLANCHER_PAS_M:
                prochain = min(len(CAVITE) - 1.0, prochain + 0.05)
        if prochain >= len(CAVITE) - 1.0 and u >= len(CAVITE) - 1.0:
            break
        u = prochain
    return sondes, fautes

## Pas d'échantillonnage latéral de la bande utile. 0,05 m : plus fin ne
## change pas le verdict (la section n'a que 9 facettes, interpolées sur 56
## segments), plus grossier raterait une bande juste au contrat.
GABARIT_PAS_M = 0.05


def _section_de_station(indice):
    """Le POLYGONE RÉEL de la section, tel que la soustraction le creuse.

    Mêmes arguments que `cavite_solide()` : c'est la seule façon d'être sûr
    que le contrôle mesure la cavité livrée et non une cavité idéalisée.
    """
    tangente = tangentes(CAVITE)[indice]
    denivele = PORCHE_DENIVELE if indice == 0 else 0.0
    return anneau_interieur(indice, CAVITE[indice], tangente, SEGMENTS,
                            phases(len(CAVITE), 7.0)[indice],
                            0.0, 0.0, denivele, SAG)


def bande_utile(indice):
    """Largeur de la bande CONTIGUË où la hauteur libre atteint le contrat.

    Le profil est ramené dans le plan (normale, z) de la station, puis
    balayé : à chaque abscisse latérale on prend le plafond et le plancher du
    polygone, et on cherche le plus long segment où leur écart atteint
    `GABARIT_CLE_M`.

    Plafond et plancher sont pris comme le MAXIMUM et le MINIMUM des
    intersections. Sur une section étoilée autour de l'axe — ce qu'elle est,
    par construction de `anneau_interieur()` — c'est l'enveloppe extérieure,
    donc la mesure est un MAJORANT si jamais une nervure venait à rendre le
    profil non étoilé. Aucune ne le fait aujourd'hui : `NERVURE_V_MIN` les
    tient au-dessus de la capsule.
    """
    pts = _section_de_station(indice)
    ax, ay = CAVITE[indice][0], CAVITE[indice][1]
    tangente = tangentes(CAVITE)[indice]
    normale = Vector((tangente.y, -tangente.x))

    def lateral(p):
        return (p.x - ax) * normale.x + (p.y - ay) * normale.y

    lats = [lateral(p) for p in pts]
    x = min(lats)
    fin = max(lats)
    meilleure, courante = 0.0, 0.0
    while x <= fin:
        zs = []
        for k in range(len(pts)):
            a, b = pts[k], pts[(k + 1) % len(pts)]
            da, db = lats[k], lats[(k + 1) % len(pts)]
            if (da - x) * (db - x) > 0.0 or abs(db - da) < 1e-12:
                continue
            u = (x - da) / (db - da)
            zs.append(a.z + (b.z - a.z) * u)
        libre = (max(zs) - min(zs)) if len(zs) >= 2 else -1.0
        if libre >= GABARIT_CLE_M:
            courante += GABARIT_PAS_M
            meilleure = max(meilleure, courante)
        else:
            courante = 0.0
        x += GABARIT_PAS_M
    return meilleure


def controle_gabarit():
    """Une capsule r = 0,45 m, h = 1,85 m passe partout sur le chemin.

    R2a-3.5.1 — CE CONTRÔLE ÉTAIT DEVENU FAUX, ET IL L'AURAIT DIT VERT.
    Il mesurait `hw * (1 - AMP_INTERIEUR)`, c'est-à-dire une DEMI-LARGEUR
    SYMÉTRIQUE, en ignorant `CAVITE_ASYM`. Tant que gauche ≈ droite l'erreur
    restait petite ; à `(1,69 ; 0,25)` elle est de 1 à 7 — le contrôle
    annonçait 2,74 m de demi-largeur à la station 5 quand le côté mince n'en
    offre que 0,99. Un contrôle qui ne voit pas l'asymétrie qu'on vient
    d'introduire est pire qu'inutile : il donne un vert qui interdit de
    chercher.

    Il ne mesure donc plus une demi-largeur mais LA BANDE UTILE : la largeur
    contiguë où la hauteur libre tient le contrat. C'est la question à
    laquelle la capsule répond réellement, et elle ne suppose rien sur la
    position de l'axe dans la section — ce qui est le point, puisque le vide
    est désormais franchement déporté d'un côté.

    Le contrat est inchangé : `2 × GABARIT_DEMI_LARGEUR_M` de large sous
    `GABARIT_CLE_M` de haut. Sur une section symétrique les deux formulations
    coïncident, et le maillage d'avant la passe passe le nouveau contrôle
    (2,60 à 4,55 m de bande) — ce n'est donc pas un durcissement rétroactif,
    c'est la même exigence enfin mesurée là où elle vit.
    """
    exigee = 2.0 * GABARIT_DEMI_LARGEUR_M
    faibles = []
    for i, (_, ay, hw, cle) in enumerate(CAVITE):
        if i >= len(CAVITE) - 2:
            continue          # les deux dernières stations FERMENT la calotte
        bande = bande_utile(i)
        # LE PALIER MONTE LE SOL, donc il MANGE la hauteur libre. Il est déjà
        # dans le profil (`anneau_interieur` pose `z = sag·v + PALIER[i]`) :
        # la bande le porte sans qu'on ait à le soustraire une seconde fois.
        if bande < exigee:
            faibles.append((i, ay, bande, exigee))
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
        nx, ny = normale_de_cavite(float(i))
        for lat in (-0.55, -0.25, 0.0, 0.25, 0.55):
            # DEUX FAUTES D'ÉCHANTILLONNAGE CORRIGÉES ICI, R2a-3.5.1, et les
            # deux étaient dans ce contrôle depuis l'origine :
            #
            #   * il décalait le long de X MONDE. La galerie s'infléchit de
            #     31° : c'est exactement ce que `normale_de_cavite()` a été
            #     écrite pour corriger ailleurs, et personne ne l'avait
            #     appliqué ici ;
            #   * il décalait de `lat · hw`, donc en supposant la section
            #     symétrique. Voir `facteur_lateral()` : à `droite = 0,25`,
            #     un point à `+0,55 · hw` est dans la roche, le rayon montant
            #     n'en sort qu'une fois, et « le sol voit le ciel » est
            #     prononcé sur du plein.
            #
            # L'origine SUIT le palier : partie d'une hauteur fixe, elle
            # serait sous le sol au fond de la galerie et compterait des
            # croisements qui ne veulent plus rien dire.
            fac = facteur_lateral(float(i), lat)
            px = ax + lat * hw * fac * nx
            py = ay + lat * hw * fac * ny
            origine = Vector((px, py, 0.35 + PALIER[i]))
            croisements, position, garde = 0, origine.copy(), 0
            while garde < 16:
                garde += 1
                r = bvh.ray_cast(position, Vector((0.0, 0.0, 1.0)), 100.0)
                if r is None or r[0] is None:
                    break
                croisements += 1
                position = r[0] + Vector((0.0, 0.0, 0.002))
            if croisements < 2 or croisements % 2 != 0:
                fautes.append((px, py, croisements))
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


def sol_attendu_en(x, y):
    """L'attendu de `hauteur_du_sol` au même point — indice et fraction.

    On retrouve la station la plus proche en projetant (x, y) sur la
    polyligne de l'axe, puis la fraction latérale par la distance à cet axe
    rapportée à la demi-largeur. L'altitude vient de `sol_de_cavite()`,
    seul décideur du profil.
    """
    meilleur = None
    n = 240
    for k in range(n + 1):
        u = (len(CAVITE) - 1.0) * k / n
        ax, ay, hw, _ = station_de_cavite(u)
        d = math.hypot(x - ax, y - ay)
        if meilleur is None or d < meilleur[0]:
            meilleur = (d, u, ax, ay, hw)
    _, u, ax, ay, hw = meilleur
    lateral = min(1.0, math.hypot(x - ax, y - ay) / max(0.05, hw))
    return sol_de_cavite(u, lateral), u, lateral


def controle_sol_repere(obj, reperes):
    """LE CONTRÔLE QUI MANQUAIT : la mesure imprimée AVEC son attendu.

    C'est le défaut le plus instructif de la passe précédente, et il ne
    tient pas à la géométrie mais à une ligne de `print`. `TRANCHE3.md` a
    publié « sol : −0,416 » là où le profil en attend −0,040 : le générateur
    IMPRIMAIT la mesure du défaut le jour même de la livraison, et personne
    n'a pu la lire, parce que rien ne se tenait à côté pour dire ce qu'elle
    aurait dû valoir.

    Une télémétrie qui imprime une mesure sans son attendu n'est pas un
    contrôle. Elle en a l'apparence, ce qui est pire que rien : elle occupe
    la place qu'aurait prise un vrai contrôle. Voir `ISS-044`.

    Rend (liste de lignes, liste de fautes).
    """
    lignes, fautes = [], []
    for nom, x, y in reperes:
        mesure = hauteur_du_sol(obj, x, y)
        attendu, u, lateral = sol_attendu_en(x, y)
        if mesure is None:
            lignes.append("[grotte] sol sous %-10s (%5.2f, %5.2f) : AUCUN — "
                          "hors cavite (attendu %+.3f m)" % (nom, x, y, attendu))
            fautes.append("%s (%.2f, %.2f) : aucun sol sous le rayon, "
                          "%+.3f m attendu" % (nom, x, y, attendu))
            continue
        ecart = mesure - attendu
        lignes.append("[grotte] sol sous %-10s (%5.2f, %5.2f) : mesure %+.3f m, "
                      "attendu %+.3f m (station %.2f, lateral %.2f), ecart "
                      "%+.3f m — tolerance %.2f"
                      % (nom, x, y, mesure, attendu, u, lateral, ecart,
                         SOL_TOLERANCE_M))
        if abs(ecart) > SOL_TOLERANCE_M:
            fautes.append("%s (%.2f, %.2f) : sol a %+.3f m pour %+.3f m "
                          "attendu, ecart %+.3f m" % (nom, x, y, mesure,
                                                      attendu, ecart))
    return lignes, fautes


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


## `_orient_exact()` A ÉTÉ RETIRÉE ICI — R2a-3.5.7.
##
## Elle était introduite par le lot `MASSIF` de R2a-3.5.6 et n'a jamais eu
## d'appelant : trouvée morte par AST, pas par `grep`. Son calcul — le signe
## du volume orienté d'un tétraèdre — est déjà fait en ligne dans
## `_penetration_exacte()`, par `_normale_frac()` puis `cote()`. La brancher
## aurait voulu dire refactorer un instrument de mesure vérifié et concordant
## avec `tools/cave_exact_intersect.py` ; on ne refactore pas un juge pour
## donner un emploi à un helper mort.
##
## Cette série a déjà payé le prix d'une fonction morte laissée en place
## (`rochers_gaine()`), qu'une passe ultérieure a dû mesurer et attribuer.


def _normale_frac(t):
    u = [Fraction(t[1][k]) - Fraction(t[0][k]) for k in range(3)]
    v = [Fraction(t[2][k]) - Fraction(t[0][k]) for k in range(3)]
    return (u[1] * v[2] - u[2] * v[1],
            u[2] * v[0] - u[0] * v[2],
            u[0] * v[1] - u[1] * v[0])


def _penetration_exacte(t1, t2):
    """Les INTÉRIEURS des deux triangles se rencontrent-ils ?

    C'est la définition topologique, et elle n'a pas de seuil. Deux faces
    partageant une arête se coupent le long de cette arête, qui appartient à
    la frontière des deux : ce n'est pas une pénétration, et aucune
    tolérance n'a besoin d'en décider.

    Rend (True/False, enfoncement, étendue de la couture).
    """
    n1 = _normale_frac(t1)
    n2 = _normale_frac(t2)
    if n1 == (0, 0, 0) or n2 == (0, 0, 0):
        return False, 0.0, 0.0

    def cote(points, normale, origine):
        o = [Fraction(c) for c in origine]
        return [sum(normale[k] * (Fraction(p[k]) - o[k]) for k in range(3))
                for p in points]

    d1 = cote(t1, n2, t2[0])
    d2 = cote(t2, n1, t1[0])
    if all(x > 0 for x in d1) or all(x < 0 for x in d1):
        return False, 0.0, 0.0
    if all(x > 0 for x in d2) or all(x < 0 for x in d2):
        return False, 0.0, 0.0

    direction = (n1[1] * n2[2] - n1[2] * n2[1],
                 n1[2] * n2[0] - n1[0] * n2[2],
                 n1[0] * n2[1] - n1[1] * n2[0])
    if direction == (0, 0, 0):
        # Coplanaires : un recouvrement de surface n'est pas une traversée.
        return False, 0.0, 0.0

    axe = 0 if direction[0] != 0 else (1 if direction[1] != 0 else 2)
    u, v = [k for k in range(3) if k != axe]
    c1 = sum(n1[k] * Fraction(t1[0][k]) for k in range(3))
    c2 = sum(n2[k] * Fraction(t2[0][k]) for k in range(3))
    det = n1[u] * n2[v] - n1[v] * n2[u]
    if det == 0:
        return False, 0.0, 0.0
    origine = [Fraction(0), Fraction(0), Fraction(0)]
    origine[u] = (c1 * n2[v] - c2 * n1[v]) / det
    origine[v] = (n1[u] * c2 - n2[u] * c1) / det

    def intervalle(triangle, normale):
        bas = haut = None
        for k in range(3):
            qi = [Fraction(c) for c in triangle[k]]
            qj = [Fraction(c) for c in triangle[(k + 1) % 3]]
            arete = [qj[m] - qi[m] for m in range(3)]
            delta = [origine[m] - qi[m] for m in range(3)]
            croix0 = (arete[1] * delta[2] - arete[2] * delta[1],
                      arete[2] * delta[0] - arete[0] * delta[2],
                      arete[0] * delta[1] - arete[1] * delta[0])
            croix1 = (arete[1] * direction[2] - arete[2] * direction[1],
                      arete[2] * direction[0] - arete[0] * direction[2],
                      arete[0] * direction[1] - arete[1] * direction[0])
            a0 = sum(croix0[m] * normale[m] for m in range(3))
            a1 = sum(croix1[m] * normale[m] for m in range(3))
            if a1 == 0:
                if a0 <= 0:
                    return None
                continue
            limite = -a0 / a1
            if a1 > 0:
                bas = limite if bas is None else max(bas, limite)
            else:
                haut = limite if haut is None else min(haut, limite)
        return bas, haut

    i1 = intervalle(t1, n1)
    i2 = intervalle(t2, n2)
    if i1 is None or i2 is None:
        return False, 0.0, 0.0
    bornes = [b for b in (i1[0], i2[0]) if b is not None]
    plafonds = [h for h in (i1[1], i2[1]) if h is not None]
    if not bornes or not plafonds:
        return False, 0.0, 0.0
    bas, haut = max(bornes), min(plafonds)
    if bas >= haut:
        return False, 0.0, 0.0

    norme_dir = float(sum(x * x for x in direction)) ** 0.5
    etendue = float(haut - bas) * norme_dir

    def enfoncement(points, normale, origine_plan):
        norme = float(sum(x * x for x in normale)) ** 0.5
        if norme == 0.0:
            return 0.0
        d = [float(x) / norme for x in cote(points, normale, origine_plan)]
        return min(max(d), -min(d))

    profondeur = min(enfoncement(t1, n2, t2[0]), enfoncement(t2, n1, t1[0]))
    return True, profondeur, etendue


def controle_penetration_exacte(obj):
    """Le contrôle d'auto-intersection qui regarde AU BON ENDROIT.

    POURQUOI IL REMPLACE `controle_repli()` SUR LE LIVRABLE
    ======================================================
    `controle_repli()` publiait « 2 paire(s) » là où une mesure exacte en
    trouve 6, et « 0 » sur la géométrie R2a-3.4 livrée et validée, qui en
    porte 10. Ce n'est pas un réglage trop lâche : `_straddle_points()` teste
    si les sommets sont de part et d'autre du **plan** de l'autre face. Deux
    triangles BORNÉS peuvent se pénétrer sans satisfaire ce test, et le
    satisfaire sans se toucher. Le compteur regardait à côté — c'est le mode
    de panne d'ISS-018 : vert sans rougir de rien.

    CE QUI CHANGE, ET CE QUI NE CHANGE PAS
    ======================================
    Le seuil `REPLI_LIVRABLE_MAX_M` n'est PAS touché, et la grandeur qu'il
    borne reste la même — l'enfoncement d'un triangle derrière le plan de
    l'autre. Le contrôle devient plus DISCRIMINANT : il compte les vraies
    pénétrations, et rien d'autre. Aucune tolérance n'a été relevée ; deux
    ont disparu, parce que le prédicat exact n'en a pas besoin.

    POURQUOI IL DUPLIQUE LES PRÉDICATS DE `tools/cave_exact_intersect.py`
    ====================================================================
    Volontairement. Cet outil-là est le JUGE INDÉPENDANT : il lit le GLB
    livré sans rien partager avec la chaîne qui le produit. Un juge qui
    importerait le code de l'accusé ne prouverait plus rien. Les deux
    implémentations doivent trouver le même nombre sur la même géométrie, et
    c'est cette concordance qui vaut preuve.

    LA TRIANGULATION EST CELLE DE L'EXPORT, ET C'EST DÉLIBÉRÉ
    ========================================================
    On mesure sur une copie triangulée en BEAUTY, comme l'exportateur glTF.
    Mesuré en R2a-3.5.5 : une triangulation en éventail des n-gones non
    convexes fabrique 109 pénétrations qui n'existent pas dans le livrable.
    On mesure donc ce qui part, pas une soupe intermédiaire.

    Rend (nombre, enfoncement maximal, étendue maximale, exemple).
    """
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.triangulate(bm, faces=bm.faces[:], quad_method='BEAUTY',
                          ngon_method='BEAUTY')
    bm.verts.ensure_lookup_table()
    bm.faces.ensure_lookup_table()
    sommets = [v.co.copy() for v in bm.verts]
    tris = [tuple(v.index for v in f.verts) for f in bm.faces]
    bm.free()

    arbre = BVHTree.FromPolygons(sommets, tris, all_triangles=True,
                                 epsilon=0.0)
    fautes = 0
    pire = 0.0
    pire_etendue = 0.0
    exemple = None
    for a, b in arbre.overlap(arbre):
        if a >= b:
            continue
        communs = set(tris[a]) & set(tris[b])
        if len(communs) >= 2:
            # Deux triangles partageant une arête et non coplanaires se
            # coupent EXACTEMENT le long de cette arête : l'intersection de
            # leurs plans est cette droite. Aucun point intérieur commun
            # n'est possible, et le cas coplanaire n'est pas une traversée.
            continue
        t1 = [sommets[i] for i in tris[a]]
        t2 = [sommets[i] for i in tris[b]]
        touche, profondeur, etendue = _penetration_exacte(t1, t2)
        if not touche:
            continue
        fautes += 1
        pire_etendue = max(pire_etendue, etendue)
        if profondeur > pire or exemple is None:
            pire = max(pire, profondeur)
            ca = sum(t1, Vector()) / 3.0
            cb = sum(t2, Vector()) / 3.0
            exemple = "faces %d/%d, centres (%.2f, %.2f, %.2f) et " \
                "(%.2f, %.2f, %.2f), enfoncement %.6f m, couture %.6f m" \
                % (a, b, ca.x, ca.y, ca.z, cb.x, cb.y, cb.z, profondeur,
                   etendue)
    return fautes, pire, pire_etendue, exemple


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



def _axe_silhouette(azimut_deg):
    """Vecteur de l'axe HORIZONTAL de l'image de silhouette, en repere modele.

    Derive, et non devine : le modele part en Y-up a l'export (`export_yup`,
    donc godot.x = X, godot.y = Z, godot.z = -Y), le lieu applique
    `LACET_DEG = 45` autour de Y, et `capture_silhouette.gd` place la camera
    en `centre + (cos a, 0, sin a)·d` avec `look_at(centre, UP)`. L'axe X de
    cette camera vaut donc (sin a, 0, -cos a), et le produit scalaire avec le
    point tourne donne l'expression ci-dessous.
    """
    a = math.radians(azimut_deg)
    k = math.sqrt(0.5)
    return (k * (math.sin(a) + math.cos(a)), k * (math.cos(a) - math.sin(a)))


def _enveloppe_silhouette(obj, ux, uy, lo, pas, n):
    """Le z maximal de la surface de `obj`, colonne par colonne.

    EXACT, par intersection de chaque triangle avec le plan de la colonne —
    pas par echantillonnage de sommets. Un module repare porte 90 sommets ;
    une colonne de 8 cm n'en contient souvent aucun, et un profil bati sur
    les sommets inventerait des encoches inexistantes. Mesure : sur la
    formation livree, la version par sommets rendait 5 masses la ou la
    version exacte en rend 3.
    """
    env = [None] * n
    sommets = obj.data.vertices
    proj = [(ux * v.co.x + uy * v.co.y, v.co.z) for v in sommets]
    for poly in obj.data.polygons:
        idx = list(poly.vertices)
        for t in range(1, len(idx) - 1):
            tri = (proj[idx[0]], proj[idx[t]], proj[idx[t + 1]])
            x0 = min(p[0] for p in tri)
            x1 = max(p[0] for p in tri)
            ka = max(0, int(math.ceil((x0 - lo) / pas)))
            kb = min(n - 1, int(math.floor((x1 - lo) / pas)))
            for q in range(ka, kb + 1):
                x = lo + q * pas
                haut = None
                for pa, pb in ((tri[0], tri[1]), (tri[1], tri[2]),
                               (tri[2], tri[0])):
                    if (pa[0] - x) * (pb[0] - x) <= 0.0 and pa[0] != pb[0]:
                        f = (x - pa[0]) / (pb[0] - pa[0])
                        z = pa[1] + f * (pb[1] - pa[1])
                        if haut is None or z > haut:
                            haut = z
                if haut is not None and (env[q] is None or haut > env[q]):
                    env[q] = haut
    return env


def _masses_du_profil(xs, hs, entaille):
    """Les masses d'un profil de crete, par PROEMINENCE topographique.

    Meme primitive que `tools/measure_silhouette_masses.py`, et pour la meme
    raison : une marche d'escalier a une proeminence nulle et ne peut donc
    pas etre comptee comme une masse. Rend, par masse retenue, ses indices de
    debut et de fin au niveau `sommet - entaille`, sa largeur, son sommet et
    sa proeminence.
    """
    n = len(hs)
    brut = []
    i = 0
    while i < n:
        j = i
        while j + 1 < n and hs[j + 1] == hs[i]:
            j += 1
        if not ((i == 0 or hs[i - 1] < hs[i])
                and (j == n - 1 or hs[j + 1] < hs[j])):
            i = j + 1
            continue
        col_g = hs[i]
        k = i - 1
        while k >= 0 and hs[k] <= hs[i]:
            col_g = min(col_g, hs[k])
            k -= 1
        if k < 0:
            col_g = min(col_g, hs[0])
        col_d = hs[j]
        k = j + 1
        while k < n and hs[k] <= hs[j]:
            col_d = min(col_d, hs[k])
            k += 1
        if k >= n:
            col_d = min(col_d, hs[n - 1])
        prom = hs[i] - max(col_g, col_d)
        if prom >= entaille:
            niveau = hs[i] - entaille
            a, b = i, j
            while a > 0 and hs[a - 1] >= niveau:
                a -= 1
            while b < n - 1 and hs[b + 1] >= niveau:
                b += 1
            brut.append(dict(i0=a, i1=b, larg=xs[b] - xs[a], som=hs[i],
                             prom=prom, col=max(col_g, col_d), pk=i))
        i = j + 1
    brut.sort(key=lambda m: -m["som"])
    gardes = []
    for m in brut:
        if not any(m["i0"] <= g["i1"] and g["i0"] <= m["i1"] for g in gardes):
            gardes.append(m)
    gardes.sort(key=lambda m: m["i0"])

    # EMPRISE — PARTITION TOPOGRAPHIQUE EN BASSINS, et c'est la troisième
    # définition essayée dans cette passe. Les deux premières répondaient
    # à côté, chacune à sa manière, et il faut le dire pour que personne
    # ne les réessaie :
    #
    #   1. `larg`, largeur au sommet mesurée `entaille` sous l'apex : un
    #      sommet PLAT y est large. Sur la géométrie rejetée elle valait
    #      5,58 / 3,60 / 2,18 m — le critère notait la platitude que le
    #      lead a condamnée, et il la notait bien.
    #   2. « étendue jusqu'au plus haut des deux cols » : dès qu'un col
    #      est bas, la masse déborde sur ses voisines. Mesuré, la
    #      dominante couvrait 16,77 m sur une formation de 17,5 — ce
    #      nombre mesurait la profondeur du col, pas la largeur.
    #
    # Le fil commun des deux erreurs : un seul nombre, choisi sans se
    # demander ce qu'il devient dans le cas dégénéré.
    #
    # ICI la frontière entre deux masses est la POSITION du col — l'argmin
    # du profil entre deux sommets retenus — et non son altitude. Les
    # bassins sont donc disjoints, exhaustifs, et leur somme vaut l'emprise
    # de la formation. Indépendants à la fois de la platitude du sommet et
    # de la profondeur du col.
    if gardes:
        frontieres = [0]
        for g, h in zip(gardes, gardes[1:]):
            a, b = g["pk"], h["pk"]
            creux = min(range(a, b + 1), key=lambda q: hs[q])
            frontieres.append(creux)
        frontieres.append(n - 1)
        for k, m in enumerate(gardes):
            m["f0"] = frontieres[k]
            m["f1"] = frontieres[k + 1]
            m["emp"] = xs[m["f1"]] - xs[m["f0"]]
    return gardes


def profil_silhouette(pieces, configs, azimut):
    """Profil de crete et proprietaire de chaque colonne, a un azimut."""
    ux, uy = _axe_silhouette(azimut)
    bornes = []
    for obj in pieces:
        for v in obj.data.vertices:
            bornes.append(ux * v.co.x + uy * v.co.y)
    lo, hi = min(bornes), max(bornes)
    n = COLONNES_SILHOUETTE
    pas = (hi - lo) / (n - 1)
    xs = [lo + q * pas for q in range(n)]
    hs = [None] * n
    qui = [None] * n
    for obj, cfg in zip(pieces, configs):
        env = _enveloppe_silhouette(obj, ux, uy, lo, pas, n)
        for q in range(n):
            if env[q] is not None and (hs[q] is None or env[q] > hs[q]):
                hs[q] = env[q]
                qui[q] = cfg
    plein = [q for q in range(n) if hs[q] is not None]
    return (xs, hs, qui, lo, hi, plein)


def controle_amas(pieces, configs):
    """LA COMPOSITION EN TROIS AMAS, MESUREE SUR LES VOLUMES SOURCES.

    Voir le commentaire de `AMAS` pour la cause qu'il attrape et les
    chiffres avant/apres. Rend (liste des fautes, lignes de telemetrie).
    """
    fautes = []
    lignes = []
    # L'AZIMUT 225 EST IMPRIMÉ, PAS BLOQUANT. La vue arrière est le point
    # bloquant du VERDICT du lead, et n'être aveugle dessus sert personne ;
    # mais ajouter un azimut à l'ensemble bloquant serait durcir un contrôle
    # dans la même passe où on en refond la mesure. On imprime, on ne juge
    # pas — et le journal le dit à chaque exécution.
    for azimut in tuple(AZIMUTS_SILHOUETTE) + (225.0,):
        telemetrie_seule = azimut not in AZIMUTS_SILHOUETTE
        if telemetrie_seule:
            lignes.append("[grotte] azimut %.0f — TELEMETRIE SEULE, ne bloque "
                          "pas" % azimut)
        xs, hs, qui, lo, hi, plein = profil_silhouette(pieces, configs, azimut)
        vx = [xs[q] for q in plein]
        vh = [hs[q] for q in plein]
        vq = [qui[q] for q in plein]
        lignes.append("[grotte] silhouette a %.0f deg : emprise %.2f m"
                      % (azimut, hi - lo))
        for entaille in (0.60, 0.90, 1.20, 1.50):
            ms = _masses_du_profil(vx, vh, entaille)
            larg = [m["larg"] for m in ms]
            moy = sum(larg) / len(larg) if larg else 0.0
            cv = 0.0
            if len(larg) > 1 and moy > 0.0:
                cv = (sum((x - moy) ** 2 for x in larg) / len(larg)) ** 0.5 / moy
            # LES DEUX NOMBRES, ET L'ATTENDU À CÔTÉ. Une télémétrie qui
            # imprime une mesure sans son attendu n'est pas un contrôle :
            # c'est ISS-044, et elle a coûté une livraison.
            emp = [m["emp"] for m in ms]
            lignes.append("[grotte]   entaille %.2f : %d masse(s) (%d exigees)"
                          "  sommets %s  emprises %s  cv %.2f (ratio emprises "
                          "%.2f, %.2f exige)"
                          % (entaille, len(ms), len(AMAS),
                             " ".join("%.2f" % x for x in larg),
                             " ".join("%.2f" % x for x in emp), cv,
                             (max(emp) / min(emp)) if emp and min(emp) > 0
                             else 0.0, LARGEUR_RATIO_MIN))

        ms = _masses_du_profil(vx, vh, ENTAILLE_LECTURE_M)
        if telemetrie_seule:
            for m in ms:
                lignes.append("[grotte]   (225) sommet %5.2f m  emprise %5.2f m"
                              "  proeminence %5.2f m  faite %5.2f m"
                              % (m["larg"], m["emp"], m["prom"], m["som"]))
            continue
        if len(ms) != len(AMAS):
            fautes.append("azimut %.0f : %d masse(s) a l'entaille %.2f, %d "
                          "attendues — la silhouette ne presente pas trois "
                          "amas" % (azimut, len(ms), ENTAILLE_LECTURE_M,
                                    len(AMAS)))
            continue

        detail = []
        for m, attendu in zip(ms, AMAS):
            seg = range(m["i0"], m["i1"] + 1)
            porteurs = {vq[q]["nom"] for q in seg
                        if m["som"] - vh[q] <= BANDE_FAITE_M}
            intrus = {vq[q]["nom"] for q in seg
                      if vq[q]["rang"] in ("gaine", "secondaire")}
            compte = {}
            for q in seg:
                cle = vq[q].get("amas")
                if cle:
                    compte[cle] = compte.get(cle, 0) + 1
            porte = "masse %d" % (len(detail) + 1)
            detail.append(dict(m=m, porteurs=porteurs, intrus=intrus,
                               porte=porte, attendu=attendu))
            lignes.append("[grotte]   %-8s sommet %5.2f m  emprise %5.2f m  "
                          "proeminence %5.2f m  faite %5.2f m"
                          % (porte, m["larg"], m["emp"], m["prom"], m["som"]))
            # L'IDENTITÉ D'UN AMAS EST DEVENUE POSITIONNELLE EN R2a-3.5,
            # et l'ancienne raison est conservée ici — c'est le second
            # contrôle refondu de cette passe, donc la trace compte double.
            #
            # AVANT : « la masse n est portée par « X », « Y » était
            #   attendu — l'ordre gauche → droite des amas n'est pas celui
            #   déclaré ». La silhouette ÉTAIT alors un assemblage de
            #   roches groupées par intention ; la clause attrapait le cas
            #   où le groupe voulu comme épaule finissait à droite.
            #
            # APRÈS : la silhouette est un loft continu. Il n'existe plus
            #   de groupe séparément intentionné, donc rien qui puisse
            #   atterrir du mauvais côté : la clause ne mesurait plus un
            #   défaut possible, elle exigeait seulement une découpe en
            #   objets que l'architecture n'a aucune raison d'avoir. Le
            #   rôle se lit désormais de la POSITION dans le profil, que
            #   `_masses_du_profil()` ordonne déjà de gauche à droite.
            #
            # Les vérifications de ces rôles n'ont pas bougé d'un
            # caractère : elles comparent `detail[0]` et `detail[-1]`, et
            # la plus haute doit être encadrée. Aucune valeur numérique
            # n'a baissé.
            # CETTE CLAUSE A ÉTÉ INVERSÉE EN R2a-3.5, ET SON ANCIENNE
            # RAISON EST CONSERVÉE ICI — un contrôle qui change de sens sans
            # laisser trace de son ancienne raison est indistinguable d'un
            # contrôle affaibli.
            #
            # AVANT (R2a-3.4) : « le faîte doit être porté par >= 3 roches ».
            #   La silhouette ÉTAIT alors faite de copies de
            #   `template-detail`, et un faîte porté par UNE roche avait la
            #   largeur du module, donc lisait en créneau. Exiger plusieurs
            #   porteurs élargissait le sommet.
            #
            # APRÈS (R2a-3.5) : « le faîte doit être porté par l'ENVELOPPE,
            #   et par ZÉRO module de détail ».
            #   La silhouette vient désormais d'une enveloppe loftée. La
            #   clause d'avant mesurerait exactement le contraire de ce
            #   qu'on veut : elle EXIGERAIT des modules dans la crête, alors
            #   que la consigne du lead est que les copies de
            #   `template-detail` ne portent plus la silhouette principale
            #   et ne décident jamais des sommets.
            #
            # La mesure ne change pas — mêmes porteurs, même bande
            # `BANDE_FAITE_M` sous le sommet. Seul l'attendu bascule.
            modules_faite = sorted(
                vq[q]["nom"] for q in seg
                if m["som"] - vh[q] <= BANDE_FAITE_M
                and vq[q]["rang"] != RANG_ENVELOPPE)
            enveloppe_faite = {vq[q]["nom"] for q in seg
                               if m["som"] - vh[q] <= BANDE_FAITE_M
                               and vq[q]["rang"] == RANG_ENVELOPPE}
            if not enveloppe_faite:
                fautes.append("azimut %.0f : le faite de « %s » n'appartient "
                              "a aucune piece d'enveloppe — la silhouette est "
                              "portee par autre chose qu'elle"
                              % (azimut, porte))
            if len(modules_faite) > attendu["modules_faite_max"]:
                fautes.append("azimut %.0f : le module « %s » remonte dans le "
                              "faite de « %s » (%d module(s) dans la bande de "
                              "%.2f m sous le sommet, %d tolere(s)) — il est "
                              "trop gros : un detail de surface casse une "
                              "surface, il ne decide pas d'un sommet"
                              % (azimut, modules_faite[0], porte,
                                 len(modules_faite), BANDE_FAITE_M,
                                 attendu["modules_faite_max"]))
            if intrus:
                fautes.append("azimut %.0f : « %s » de rang gaine/secondaire "
                              "porte la crete dans l'emprise de la masse "
                              "« %s » — l'invisible ne decide pas du visible"
                              % (azimut, sorted(intrus)[0], porte))

        # CES DEUX CLAUSES SONT PASSÉES DE LA LARGEUR AU SOMMET À
        # L'EMPRISE EN R2a-3.5. C'est le troisième contrôle refondu de la
        # passe, et l'ancienne version est conservée pour la même raison
        # que les deux autres.
        #
        # AVANT : `larg`, la largeur mesurée 0,90 m sous l'apex. Un sommet
        #   PLAT y est large, une crête vive y est étroite — le critère
        #   récompensait donc la platitude. La démonstration est dans les
        #   chiffres de la géométrie rejetée : 5,58 / 3,60 / 2,18 m, un
        #   rapport de 2,56 qui passait haut la main, et c'ÉTAIENT les
        #   tables horizontales que le lead a condamnées. Le même défaut
        #   avait déjà été trouvé et corrigé dans
        #   `tools/measure_silhouette_masses.py` ; il n'avait pas été
        #   propagé ici, et le chiffre condamné y servait encore de
        #   plancher.
        #
        # APRÈS : `emp`, l'étendue de la masse jusqu'au plus haut de ses
        #   deux cols. Elle mesure ce que « trois masses d'emprises
        #   inégales » veut dire, sans rien exiger du sommet.
        #
        # LES SEUILS NE BOUGENT PAS. Ils ont été calibrés sur la géométrie
        # rejetée ; les recalibrer sur l'enveloppe qu'on juge serait
        # calibrer sur le sujet. Un échec se rend en mesure.
        largeurs = sorted((d["m"]["emp"] for d in detail), reverse=True)
        if largeurs[0] / largeurs[-1] < LARGEUR_RATIO_MIN:
            fautes.append("azimut %.0f : emprises %s — rapport %.2f, il en "
                          "faut %.2f ; trois masses d'emprise voisine sont "
                          "le defaut « tours rocheuses repetees »"
                          % (azimut, " ".join("%.2f" % x for x in largeurs),
                             largeurs[0] / largeurs[-1], LARGEUR_RATIO_MIN))
        for a, b in zip(largeurs, largeurs[1:]):
            if a / b < LARGEUR_ECART_MIN:
                fautes.append("azimut %.0f : deux emprises a %.2f %% l'une de "
                              "l'autre (%.2f et %.2f m) — « nettement "
                              "inegales » demande au moins %.0f %%"
                              % (azimut, 100.0 * (a / b - 1.0), a, b,
                                 100.0 * (LARGEUR_ECART_MIN - 1.0)))

        haut = max(detail, key=lambda d: d["m"]["som"])
        # Positionnel : la dominante est la masse la plus haute, et elle
        # doit être ENCADRÉE. Une silhouette dont le point haut est à un
        # bout est une rampe, pas trois masses.
        if haut is detail[0] or haut is detail[-1]:
            fautes.append("azimut %.0f : la masse la plus haute est celle de "
                          "%s (faite %.2f m) — la dominante doit etre "
                          "encadree par l'epaule et le contrefort, sinon la "
                          "silhouette est une rampe"
                          % (azimut, "gauche" if haut is detail[0] else
                             "droite", haut["m"]["som"]))
        for d in detail:
            if d is haut:
                continue
            if haut["m"]["som"] - d["m"]["som"] < DOMINANTE_AU_DESSUS_M:
                fautes.append("azimut %.0f : la dominante ne surplombe « %s » "
                              "que de %.2f m (%.2f exiges)"
                              % (azimut, d["porte"],
                                 haut["m"]["som"] - d["m"]["som"],
                                 DOMINANTE_AU_DESSUS_M))
        gauche = detail[0]["m"]
        droite = detail[-1]["m"]
        if droite["larg"] > gauche["larg"] or droite["som"] > gauche["som"]:
            fautes.append("azimut %.0f : le contrefort droit (%.2f m de large, "
                          "faite %.2f) n'est pas plus petit ET plus bas que "
                          "l'epaule gauche (%.2f m, %.2f)"
                          % (azimut, droite["larg"], droite["som"],
                             gauche["larg"], gauche["som"]))

        cols = sorted((gauche["prom"], droite["prom"]))
        if cols[1] / cols[0] < COLS_RATIO_MIN or \
                cols[1] - cols[0] < COLS_ECART_MIN_M:
            fautes.append("azimut %.0f : les deux cols entaillent de %.2f et "
                          "%.2f m — rapport %.2f et ecart %.2f m ; deux "
                          "entailles semblables rendent la silhouette "
                          "reguliere" % (azimut, cols[0], cols[1],
                                         cols[1] / cols[0], cols[1] - cols[0]))

        centre = 0.5 * (vx[haut["m"]["i0"]] + vx[haut["m"]["i1"]])
        milieu = 0.5 * (lo + hi)
        part = abs(centre - milieu) / (hi - lo)
        lignes.append("[grotte]   decentrement du faite dominant : %.2f m = "
                      "%.1f %% de l'emprise" % (abs(centre - milieu),
                                                100.0 * part))
        if part < DECENTREMENT_MIN:
            fautes.append("azimut %.0f : le faite dominant est a %.1f %% du "
                          "milieu de l'emprise (%.0f %% exiges) — une masse "
                          "haute et centree lit en cheminee"
                          % (azimut, 100.0 * part, 100.0 * DECENTREMENT_MIN))
    return fautes, lignes

def controle_assise(obj):
    zs = [v.co.z for v in obj.data.vertices]
    seuil = [v.co.z for i, v in enumerate(obj.data.vertices)
             if len(CAVITE) * 0 <= i < 1]
    return min(zs), max(zs), (seuil[0] if seuil else 0.0)


## MODE DIAGNOSTIC — VOIR L'AVAL D'UN PORTAIL ROUGE, SANS L'AFFAIBLIR
##
## Un echec de composition arrete la chaine avant la soustraction. On perd
## alors trois informations qui n'ont RIEN A VOIR avec le defaut qui bloque :
## la cavite se soustrait-elle proprement, la sonde trouve-t-elle un jour,
## l'epaisseur s'effondre-t-elle quelque part. Rester aveugle dessus ne rend
## le portail ni plus severe ni plus juste.
##
## Ce drapeau ne touche AUCUN seuil, n'ignore AUCUNE faute — chacune est
## imprimee a l'identique — et ne change PAS le code retour : la chaine sort
## toujours en 2. Il laisse seulement la construction se poursuivre au-dela
## de la seule porte de COMPOSITION, pour qu'on puisse mesurer la suite.
##
## Toute autre porte reste un arret dur. Si une deuxieme rougit, on
## l'apprend la ou elle est.
##
## Le maillage ainsi produit N'EST PAS LIVRABLE et le journal le crie.
DIAGNOSTIC = "--diagnostic" in sys.argv
_PORTAIL_ROUGE = False


def franchir(nom):
    """Vrai si le mode diagnostic autorise a poursuivre au-dela de `nom`.

    N'IGNORE RIEN : la faute vient d'etre imprimee par l'appelant, et le
    code retour final reste 2. Cette fonction ne decide que d'une chose —
    continuer a MESURER, ou s'arreter aveugle.

    Deux familles de portes, et la distinction n'est pas de commodite :

      * COMPOSITION / SURFACE / PLACEMENT — amas, plage plane, epaisseur,
        gabarit, jour, reperes de sol, jupe. Une geometrie qui les rate
        reste un solide mesurable ; la soustraction, l'etancheite et les
        cotes ont encore un sens, et les mesurer renseigne sur des defauts
        SANS RAPPORT avec celui qui bloque ;
      * INTEGRITE — fermeture, connexite, auto-intersection, coques,
        budget de triangles. Elles disent que le solide n'est plus un
        solide. Continuer au-dela produirait des mesures sur un objet qui
        n'existe pas : du bruit presente comme de l'information.

    Seule la premiere famille appelle cette fonction.
    """
    if not DIAGNOSTIC:
        return False
    globals()["_PORTAIL_ROUGE"] = True
    print("[grotte] DIAGNOSTIC — porte « %s » ROUGE, franchie pour mesurer "
          "l'aval ; code retour final 2." % nom)
    return True



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
    # R2a-3.5 — L'ORDRE DES COUCHES DU LEAD EST ICI, ET IL EST LISIBLE.
    #   couche 1  l'enveloppe porte la silhouette ;
    #   couche 4  les modules du kit ne font que casser des surfaces.
    # `ROCHERS`, qui composait la silhouette jusqu'à R2a-3.4, ne fait plus
    # partie de l'implantation : sa fonction est reprise par `ENVELOPPE`,
    # et `controle_amas` refuse désormais qu'un module remonte dans un
    # faîte. Le kit subsiste par `rochers_gaine` (gaine de galerie),
    # `rochers_dos_alcove` et `rochers_semelle`, qui scellent et ne
    # composent pas.
    try:
        pieces = [assise_enterree()]
        env_objets, env_configs = pieces_enveloppe()
        pieces.extend(env_objets)
        implantation = list(env_configs)
        # LA GAINE EST RETIRÉE, et ce n'est pas un réglage.
        #
        # `rochers_gaine()` a été inventée en R2a-3.4 pour donner de
        # l'épaisseur de roche autour de la galerie quand la silhouette
        # ÉTAIT faite de roches : il n'y avait rien d'autre pour porter la
        # masse. Aujourd'hui l'enveloppe porte la masse ET la silhouette,
        # et la sonde de contenance le mesure station par station.
        #
        # Elle coûtait exactement ce qu'elle était censée éviter. Mesuré
        # par isolement, à l'azimut monde 55 :
        #     enveloppe seule            -> 3 masses, cols 1,36 / 0,74
        #     enveloppe + gaine + semelle -> 2 masses
        # Ses 84 roches, faîte 5,98 m, comblent le col A depuis le porche.
        # Baisser leur échelle de 1,15 à 0,92 ne déplace aucune largeur
        # d'un centimètre : ce n'est pas leur taille, c'est leur position.
        #
        # On retire, on mesure, et on ne réintroduit que ce que
        # `controle_epaisseur` exige — station par station, chiffre en
        # face. Si la mesure n'exige rien, la gaine disparaît.
        # LA CALOTTE NORD entre ici, et c'est le seul ajout de R2a-3.5.4.
        # Elle couvre la joue nord de la salle et de l'alcôve, que le tube
        # de cavité projette jusqu'à `ay = 7,24` alors que la dernière
        # station est à `3,17`. Sans elle, la soustraction ouvre le massif
        # sur le ciel — 85,8 cm². Voir `rochers_calotte_nord()`.
        rocs = (rochers_dos_alcove() + rochers_semelle()
                + rochers_calotte_nord())
        for config in rocs:
            pieces.append(poser_rocher(config))
        implantation.extend(rocs)
    except RuntimeError as erreur:
        print("[grotte] ERREUR: %s" % erreur)
        return 2
    compte = {}
    for config in implantation:
        compte[config["rang"]] = compte.get(config["rang"], 0) + 1
    print("[grotte] %d piece(s) : %s, plus l'assise enterree"
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

    # 2 bis. LA COMPOSITION EN TROIS AMAS. Mesurée ici, sur les volumes
    #        SOURCES, et non trois quarts d'heure plus tard sur un PNG :
    #        c'est le seul endroit où la faute est encore réparable sans
    #        relancer l'export. Voir le commentaire de `AMAS`.
    fautes, telemetrie = controle_amas(pieces[1:], implantation)
    for ligne in telemetrie:
        print(ligne)
    if fautes:
        for faute in fautes:
            print("[grotte] ERREUR: composition — %s" % faute)
        print("=" * 74)
        print("DIAGNOSTIC — LE PORTAIL EST ROUGE, CE MAILLAGE N'EST PAS "
              "LIVRABLE")
        print("=" * 74)
        if not franchir("composition (amas)"):
            return 2
    else:
        print("[grotte] composition : trois amas d'emprises inegales, faites "
              "portes par plusieurs roches, deux cols de profondeurs "
              "differentes")

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

    ## LES DEUX COMPTEURS SONT PUBLIÉS, ET C'EST VOULU. L'ancien reste
    ## imprimé comme télémétrie pour que l'écart soit lisible dans le
    ## journal : c'est lui qui a fait croire à « 0 auto-intersection » sur
    ## une géométrie qui en portait dix. Le verdict, lui, vient du contrôle
    ## exact.
    ancien, ancienne_prof, _ = controle_repli(grotte)
    croisements, profondeur, etendue, exemple = \
        controle_penetration_exacte(grotte)
    print("[grotte] auto-intersection du livrable (EXACT) : %d paire(s), "
          "enfoncement maximal %.6f m (seuil %.3f m), couture maximale "
          "%.6f m" % (croisements, profondeur, REPLI_LIVRABLE_MAX_M, etendue))
    print("[grotte]   ancien compteur (plans + tolerance %.0e) : %d paire(s), "
          "%.6f m — telemetrie, il SOUS-COMPTE"
          % (TOLERANCE_TANGENCE_M, ancien, ancienne_prof))
    if croisements:
        print("[grotte]   exemple : %s" % exemple)
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
        # QUELLES PORTES LE MODE DIAGNOSTIC LAISSE-T-IL FRANCHIR, ET POURQUOI
        # PAS LES AUTRES.
        #
        # Deux familles, et la distinction n'est pas de commodite :
        #
        #   * les portes de COMPOSITION et de SURFACE — amas, plage plane —
        #     jugent l'aspect. Une geometrie qui les rate reste un solide
        #     mesurable : la soustraction, l'etancheite et l'epaisseur ont
        #     encore un sens, et les mesurer renseigne sur des defauts qui
        #     n'ont aucun rapport avec l'aspect ;
        #   * les portes d'INTEGRITE — fermeture, connexite,
        #     auto-intersection, budget de triangles — disent que le solide
        #     n'est plus un solide. Continuer au-dela produirait des mesures
        #     sur un objet qui n'existe pas, c'est-a-dire du bruit presente
        #     comme de l'information.
        #
        # Seule la premiere famille est franchissable, et le code retour
        # reste 2 dans tous les cas.
        if not franchir("surface (plage plane)"):
            return 2

    # 9. ÉPAISSEUR, mesurée par rayon sur le maillage FINAL.
    mini, mini_collerette, percees = controle_epaisseur(grotte, SEGMENTS)
    if percees:
        for i, azimut, n in percees[:5]:
            print("[grotte] ERREUR: station %d, azimut %.0f° — %d croisement(s) "
                  "seulement : le rayon sort par un JOUR" % (i, azimut, n))
        if not franchir("epaisseur (jour au rayon)"):
            return 2
    if mini < EPAISSEUR_MIN_M or mini_collerette < EPAISSEUR_MIN_COLLERETTE_M:
        print("[grotte] ERREUR: epaisseur %.2f m en paroi, %.2f m en "
              "collerette (min %.2f / %.2f)"
              % (mini, mini_collerette, EPAISSEUR_MIN_M,
                 EPAISSEUR_MIN_COLLERETTE_M))
        if not franchir("epaisseur minimale"):
            return 2
    print("[grotte] epaisseur de roche : %.2f m en paroi, %.2f m au linteau "
          "(rayons lateraux et montants sur le maillage FINAL ; le plancher "
          "releve du terrain gele, voir controle_epaisseur)"
          % (mini, mini_collerette))

    # R2a-3.5.3 — LE MÊME CONTRAT, MAIS SUR TOUT LE DOMAINE. Le contrôle
    # ci-dessus s'arrête à la dernière station de CAVITE (ay = 3,17) ; le
    # massif court jusqu'à ay ~ 11,9. Celui-ci balaie la totalité, publie
    # les bornes qu'il a réellement couvertes, et REFUSE de conclure s'il
    # n'a pas tout vu.
    dom = controle_epaisseur_domaine(grotte)
    print("[grotte] domaine : pas %.2f m, %d colonnes, x [%.2f ; %.2f] "
          "y [%.2f ; %.2f]" % (dom["pas"], dom["colonnes"], dom["couvert"][0],
                               dom["couvert"][1], dom["couvert"][2],
                               dom["couvert"][3]))
    if dom["manques"]:
        for m in dom["manques"]:
            print("[grotte] ERREUR: COUVERTURE incomplete — %s" % m)
        print("[grotte] un minimum publie sur un domaine incomplet est "
              "exactement la panne que ce controle corrige")
        if not franchir("couverture du domaine"):
            return 2
    print("[grotte] domaine : %d colonne(s) a vide qualifiant (>= %.2f m) — "
          "%d sans aucune matiere au-dessus (bouche/ciel), %d en matiere "
          "pleine, %d lame(s) mince(s)"
          % (dom["qualifiantes"], VIDE_QUALIFIANT_M, dom["aucune_matiere"],
             dom["matiere_pleine"],
             len(dom["plaques"]) + len(dom["bords"])))
    if dom["bords"]:
        c, ax, ay, h, n, _cum = dom["bords"][0]
        print("[grotte] domaine : bord le plus mince %.3f m en (%.2f ; %.2f), "
              "vide %.2f m, %d voisin(s) — terminaison laterale d'un vide, "
              "pas une lame" % (c, ax, ay, h, n))
    if dom["plaques"]:
        for c, ax, ay, h, n, cum in dom["plaques"][:5]:
            print("[grotte] ERREUR: PLAQUE %.3f m en (%.2f ; %.2f) sous "
                  "%.2f m de vide, %d/8 voisins — moins que EPAISSEUR_MIN_M "
                  "= %.2f m (cumul de la colonne %.3f m)"
                  % (c, ax, ay, h, n, EPAISSEUR_MIN_M, cum))
        print("[grotte] domaine : %d plaque(s) sous le seuil, la plus mince "
              "%.3f m" % (len(dom["plaques"]), dom["plaques"][0][0]))
        if not franchir("epaisseur sur le domaine"):
            return 2
    else:
        print("[grotte] domaine : aucune plaque sous %.2f m ; les colonnes "
              "minces sont toutes des bords" % EPAISSEUR_MIN_M)

    faibles = controle_gabarit()
    print("[grotte] gabarit : bande utile par station (m) : %s"
          % ", ".join("%d:%.2f" % (i, bande_utile(i))
                      for i in range(len(CAVITE) - 2)))
    if faibles:
        for i, ay, bande, exigee in faibles:
            print("[grotte] ERREUR: station %d (y=%.2f) hors gabarit — bande "
                  "utile %.2f m sous %.2f m de hauteur libre, %.2f m exiges"
                  % (i, ay, bande, GABARIT_CLE_M, exigee))
        if not franchir("gabarit de station"):
            return 2
    print("[grotte] gabarit : capsule r=0,45 h=1,85 passe aux %d stations "
          "du chemin" % (len(CAVITE) - 2))

    sondes, fautes_sol_bas = controle_plancher(grotte)
    print("[grotte] plancher : %d point(s) sondes VERS LE BAS depuis le vide "
          "de la galerie, %d faute(s) (tolerance %.2f m)"
          % (sondes, len(fautes_sol_bas), SOL_TOLERANCE_M))
    if fautes_sol_bas:
        for u, f, x, y, attendu, mesure, z0, trace in fautes_sol_bas[:8]:
            print("[grotte] ERREUR: plancher station %.2f lateral %+.2f "
                  "(x %.2f, y %.2f) — depart z %+.3f, attendu %+.3f m, %s"
                  % (u, f, x, y, z0, attendu,
                     "AUCUN sol sous le rayon" if mesure is None
                     else "mesure %+.3f m (ecart %+.3f)" % (mesure,
                                                            mesure - attendu)))
            print("[grotte]          impacts (z, normale.z) : %s"
                  % (" ".join("%+.2f/%+.2f" % t for t in trace) or "aucun"))
        if not franchir("plancher de cavite"):
            return 2

    fautes = controle_aucun_jour(grotte, SEGMENTS)
    if fautes:
        for x, y, n in fautes[:5]:
            print("[grotte] ERREUR: le sol voit le ciel en (%.2f, %.2f) — "
                  "%d croisement(s)" % (x, y, n))
        if not franchir("aucun jour depuis le sol"):
            return 2
    print("[grotte] aucun jour : 25 rayons verticaux, croisements pairs et >= 2")

    # Hauteur du sol là où le script de lieu pose la récompense et la salle.
    # Ces deux chiffres sont la SEULE source correcte pour les constantes
    # `MODELE_NICHE.y` et `MODELE_SALLE.y` de `waterfall_cave_place.gd` :
    # elles vivent dans un autre fichier, et le sol vient de bouger.
    lignes_sol, fautes_sol = controle_sol_repere(grotte, (
        ("axe_seuil", 0.11, 0.52), ("salle", 2.62, 2.58),
        ("niche", 2.78, 4.09), ("voisin", 2.71, 3.39)))
    for ligne in lignes_sol:
        print(ligne)
    if fautes_sol:
        for faute in fautes_sol:
            print("[grotte] ERREUR: repere de sol — %s" % faute)
        if not franchir("reperes de sol"):
            return 2

    if -mini_z < ASSISE_JUPE_MIN_M:
        print("[grotte] ERREUR: jupe de %.2f m < %.2f m — masse posee, non "
              "plantee" % (-mini_z, ASSISE_JUPE_MIN_M))
        if not franchir("jupe d'assise"):
            return 2

    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                          "SM_WaterfallCave.blend")
    bpy.ops.wm.save_as_mainfile(filepath=sortie)
    print("[grotte] source enregistree -> %s" % sortie)

    if DIAGNOSTIC and _PORTAIL_ROUGE:
        print("=" * 74)
        print("DIAGNOSTIC — FIN. LE PORTAIL ETAIT ROUGE : sortie 2.")
        print("  Le maillage existe pour etre MESURE, pas pour etre livre.")
        print("=" * 74)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
