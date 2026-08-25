## LE BELVÉDÈRE DU GUETTEUR (`valley.poi.overlook_summit.01`, r07) — le
## point haut de l'est. On y monte, et la montée DONNE L'ARC.
##
## CE LIEU EST BÂTI AUTOUR D'UN VIDE, pas d'un volume. Deux formations
## rocheuses ouvrent entre elles une brèche tournée vers l'ouest-sud-ouest :
## on la franchit, et la vallée entière s'ouvre d'un coup sur la crête de
## départ. Le lieu ne se lit donc pas comme un objet posé sur une butte —
## il se lit comme un passage.
##
## REWORK V2.3-B LOT 1.R (voie A). Le verdict Codex a rejeté la version
## précédente : « les plaques terracotta rectangulaires sont refusées » —
## les modules `SM_Dungeon_CaveWallTop/CaveWallHalf/CaveRock` rendaient des
## panneaux dressés orange (capture :
## `evidence/world_v2/v2_3_b/lot1/poi/overlook_summit_identite.png`).
## La famille `SM_Dungeon_*` est donc BANNIE de ce lieu. La matière vient
## du kit falaise (`cliff_*`, `rock_large*`, `rock_smallB` — le même
## ocre-gris froid que les falaises V2.2 gelées) : masses PENCHÉES et
## FONDUES entre elles, pieds enterrés de 0,35 à 0,60 m, jamais un panneau.
##
## TROIS CONTRAINTES MESURÉES ONT DÉCIDÉ DE L'IMPLANTATION, et aucune n'est
## négociable :
##
##  1. `cam05_belvedere_crete` EST POSÉE ICI. Elle vit à (166 ; 54), soit
##     2,83 m du site, et vise (0, 26, 170). Sa direction locale vaut
##     (−0,82 ; +0,573) : tout point local à x > 0 lui est DERRIÈRE
##     (produit scalaire négatif). Toute la masse va donc à l'est, et la
##     brèche s'ouvre à l'ouest-sud-ouest — ce qui est exactement le
##     « regard de retour » que le layout demande à ce lieu.
##  2. LA ROUTE 2 TRAVERSE LE SOMMET. `heights_route` porte le waypoint
##     littéral [168, 52], entre [158, 42] au nord-ouest et [190, 30] au
##     nord-est. Le filet des lieux échantillonne la route au mètre et
##     refuse tout collider dont l'emprise XZ passe à moins de 1,2 m
##     (`ROUTE_CLEAR_M` du TEST — 1,2 m, et non les 2,3 m de la
##     végétation). Les distances perpendiculaires à la diagonale
##     (0,0) → (+22,−22) sont donc calculées, pas estimées : crête 8,7 m
##     (marge collider ≈ 4,6 m), épaulement 8,8 m (marge ≈ 6,4 m),
##     avant-poste 8,5 m (marge ≈ 6,0 m), épaule 6,4 m (marge ≈ 3,5 m).
##  3. LA BUTTE SE MONTE À PIED. `world_v2_heightmap.gd` porte la trace de
##     l'incident : à rayon 22, l'anneau du belvédère tombait de 5 m en
##     quelques mètres et « le parcours réel y restait cloué ». Le rayon a
##     été porté à 30 et le fondu à 12 m. Profils mesurés depuis le
##     centre : plat jusqu'à r ≈ 10, puis −3,2 m à 15 m au sud-sud-est et
##     −6,1 m à 20 m à l'ouest-sud-ouest. L'ancre de récompense déclare
##     donc `requires_traversal = false` : prétendre qu'il faut grimper
##     serait faux, et un filet qui exige alors un scénario physique
##     rougirait pour une raison inventée.
##
## LA COMPOSITION EST BIMODALE, et ça se mesure : crête centrale autour de
## (8 ; 5), avant-poste DÉTACHÉ autour de (18 ; −6), du ciel entre les
## deux sur les deux axes de lecture. C'est elle qui tient le PASS D3
## contre la Grotte du couchant (une seule masse triangulaire) — corrigé le
## 2026-08-23 sur verdict R-D3, conservé tel quel par le rework : seuils
## IoU 0,493 / 0,491 / 0,546 aux distances 30 / 80 / 160 m.
##
## LA BRÈCHE ÉTAIT DÉCLARÉE, PAS RENDUE — mesuré, pas supposé (lot 1.R, v7).
## Le détecteur R-D3 rejoué sur les silhouettes du rework a rendu FAIL :
## belvédère × source à 30 m, IoU 0,511 contre un seuil de 0,493 ; et le
## belvédère passait à 0,0011 du seuil contre le Pont de pierre à 80 m. La
## cause se lit sur `silhouette_overlook_summit_090.png` du même commit :
## les deux masses s'y touchent par un PONT MINCE — le `rock_smallB` posé à
## (11,8 ; −2,8) tombait pile dans l'intervalle, et la dalle de pied de
## l'avant-poste remontait jusqu'à z ≈ −0,4, donc dans l'emprise en Z de la
## crête. En aplat noir le lieu ne lisait pas « deux dents et un creux »
## mais « un tas de rochers », comme la moitié du corpus.
##
## Trois déplacements ouvrent le vide POUR DE BON, sur les DEUX axes de
## lecture — et c'est l'élément héroïque du brief de conception qui y gagne,
## pas seulement un seuil :
##   * la crête recule vers le sud (z 3,0 → 4,6) et GRANDIT (×2,2 → ×2,55) :
##     son bord nord passe de z ≈ −0,8 à z ≈ +0,2 ;
##   * l'avant-poste part au nord-est, (15,2 ; −2,6) → (17,8 ; −5,8), et sa
##     dalle de pied le suit, réduite (×0,9 → ×0,75) ;
##   * l'éclat qui faisait le pont quitte l'intervalle pour le flanc
##     extérieur de l'avant-poste, (11,8 ; −2,8) → (19,6 ; −7,2).
## Vides visés : ≈ 2,5 m en X et ≈ 2,3 m en Z — du ciel entre les deux
## masses sous les deux angles de silhouette. Simulation hors moteur avant
## engagement ; le verdict qui compte est le détecteur rejoué, dans
## `evidence/world_v2/v2_3_b/lot1/controles/verdict_repetition.json`.
##
## AUCUN CAIRN. Empiler des blocs pour marquer un sommet est précisément
## « l'empilement de blocs » reproché deux fois par le lead. La marque du
## sommet est une masse unique et penchée, plus haute que tout ce qui
## l'entoure, plus un vide qui la traverse.
## LOT 1.R — DEUXIÈME CORRECTIVE (agent A). LA MATIÈRE DU KIT A ÉTÉ ÉCARTÉE
## DES DEUX MASSES, sur mesure au pixel et non sur impression.
##
## Mesuré sur les captures de `evidence/world_v2/v2_3_b/lot1r/final/` (commit
## 7c58573, llvmpipe, lumière du monde gelée) :
##
##   masse au soleil    RGB(155 ; 149 ; 138)  H = 40°  S = 0,11  V = 0,61
##   avant-poste        RGB(149 ; 147 ; 135)  H = 50°  S = 0,10  V = 0,59
##   falaise V2.2 fond  RGB(161 ; 144 ; 132)  H = 26°  S = 0,18  V = 0,63
##
## Deux constats, et chacun condamne un aspect de la version précédente :
##  1. la formation rendait CHAUD (H 40°) là où le contrat du lot exige
##     « minéral FROID — gris bleuté, ardoise, pierre désaturée » ;
##  2. elle rendait PLUS CLAIRE que la falaise du fond — donc elle ne se
##     détachait pas en masse, elle s'y diluait.
## Et sur `overlook_gros_crete.png`, la forme lit « des oreillers de pierre » :
## `Rock_Medium_*` est une famille de GALETS ARRONDIS à coiffe de mousse.
## Aucune valeur d'albédo ne fabrique une strate sur un galet : c'est une loi
## de FORME, pas une couleur — le même verdict conditionnel que celui qui a
## donné les stèles du champ de fleurs.
##
## D'où les deux changements de cette passe :
##  * les deux masses deviennent un GLB dédié (`SM_OverlookCrags.glb`,
##    générateur `source_assets/blender/environment/make_overlook_crags.py`) :
##    des piles de BANCS — paroi verticale + vire horizontale — au PENDAGE
##    PARTAGÉ (azimut 209°, 13,5°). Deux rochers voisins sont deux objets ;
##    deux masses au même pendage sont une formation rompue en deux. La
##    crête monte à 6,96 m (contre ~4,6 m visibles avant) : « l'échelle
##    géologique » du contrat est une hauteur, pas une intention ;
##  * une ASSISE ROCHEUSE runtime (`AssiseCrocs`) épouse le terrain autour
##    de chaque pied. « Roches posées SUR le sol sans racine » est l'une des
##    trois causes de rejet écrites au contrat : le remède est que le pied
##    de la formation soit de la ROCHE, et que l'herbe la rencontre sur un
##    bord irrégulier, pas sur la ligne nette d'une pièce déposée.
##
## L'assise est faite de DEUX LOBES DISJOINTS, jamais d'une nappe continue :
## une dalle qui relierait les deux pieds refermerait au sol la brèche que
## toute la composition existe pour ouvrir.
class_name OverlookSummitPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")
## Les deux masses. Un seul GLB, deux objets : on instancie deux fois et on
## ne garde que l'objet voulu (recette des stèles du champ).
const CROCS_GLB: String = "res://assets/environment/rocks/SM_OverlookCrags.glb"

## Roche des hauteurs. JUGÉ SUR CAPTURE (v1, commit 63af918), pas sur
## l'albédo (gain ≈ 1,8, non linéaire — `scripts/CLAUDE.md`) :
##  - `Rock_Medium_*` (atlas Rocks) rend gris-vert froid — multiplicateurs
##    quasi neutres, variés pièce à pièce pour casser la répétition ;
##  - les pièces Kenney (`rock_large*`, `rock_smallB`) rendent CRÈME avec
##    une coiffe « grass » MENTHE VIF — re-teintées PAR SURFACE : corps
##    vers l'ocre-gris poussiéreux des falaises V2.2, coiffe rabattue en
##    ocre sec (r07 « minérale, herbes sèches » — pas de menthe, pas de
##    cyan hors Résonance).
## RECETTE V2.2 (v3) : mesuré sur capture v2, `K.apply_tone` laisse les
## COULEURS DE SOMMET de l'atlas Rocks allumées et les boulders rendent
## PISTACHE au soleil. Le bâtisseur de végétation V2.2, lui, les assagit :
## `vertex_color_use_as_albedo = false` + teinte (0,95 ; 0,88 ; 0,78)
## (`world_v2_vegetation_builder.gd::_model_mesh`). `_teinter()` reprend
## cette recette — la continuité avec les boulders gelés du champ est de
## construction. Multiplicateurs (Rock_Medium, atlas texturé) :
## v4 — mesuré sur capture v3 : à (0,95;0,88;0,78) la masse rendait
## (168,163,112), plus claire et plus JAUNE que les boulders V2.2 du champ
## (149,148,119, même image). Correction dérivée du rapport des deux
## mesures : ×(0,89;0,91;1,07) sur le rendu, appliquée à l'albédo.
## v5 mesurait (141,139,130) pour une cible (149,148,119) — léger voile
## lilas : v6 ramène le bleu de 0,95 à 0,89. Trois itérations mesurées
## (v3 168,163,112 → v4 135,137,99 → v5 141,139,130 → cible).
## (Les quatre multiplicateurs `TONE_CREST_*` / `TONE_LEDGE` de la première
## corrective ont disparu avec les masses de kit qu'ils habillaient. Leur
## histoire de mesure — v3 (168,163,112) → v4 (135,137,99) → v5 (141,139,130)
## — reste consignée ci-dessus : elle documente le PIÈGE (teinter un atlas
## texturé se fait par multiplication, et le gain n'est pas linéaire), et ce
## piège s'applique encore aux pièces de kit qui restent.
## LA FAMILLE KENNEY `rock_*` A QUITTÉ LE LIEU (v7b) — mesure, pas goût.
## `tools/gltf_inspect.py assets/environment/cliffs/rock_largeC.glb` :
## **72 triangles, 0 texture, 2 matériaux à couleur plate**. Aucun réglage
## d'albédo ne peut faire lire « roche » à un solide de 72 faces sans
## texture : quelle que soit la teinte, il rend un COIN À FACES PLANES, et
## c'est ce que le troisième passage d'audit a relevé au pied du gros bloc
## (« deux coins tan à arêtes droites, famille de teinte étrangère »). Les
## quatre pièces Kenney sont donc remplacées par la famille Rocks
## (`Rock_Medium_*`, 244–522 triangles, atlas texturé) et la tablette par
## `RockPath_Square_Small_1` (783 triangles, atlas PathRocks) — la seule
## dalle VRAIMENT plate et texturée du corpus.
## Le paramètre `absolu` de `_teinter()` reste : il documente le piège
## (multiplier un matériau à couleur plate rend saumon) même si plus aucune
## pièce d'ici ne l'emprunte.
## La tablette suit elle aussi le froid : c'était la « petite pièce pâle
## isolée » relevée à quatre passages d'audit, et une dalle chaude au milieu
## d'une ardoise bleue la rend encore plus isolée.
const TONE_DALLE: Color = Color(0.62, 0.66, 0.80)
## Herbe sèche du sommet : le vert de la prairie n'y monte pas.
##
## REVERT DOCUMENTÉ (itération 6). J'ai assombri cette teinte de 29 % pour
## corriger « l'objet le plus CLAIR de la caméra joueur » — une tache ocre à
## V 0,683 dans une herbe à 0,407, seule au milieu du pré. La capture a
## infirmé la correction : **le pixel visé n'a pas bougé d'un centième**
## (RGB 170,7 / 174,2 / 131,1 avant comme après). Mesuré ensuite sur toutes
## les captures de la passe, il est IDENTIQUE depuis l'état de départ
## `7c58573` — il n'a bronché ni quand les deux masses ont été remplacées, ni
## quand les pièces de kit ont été refroidies.
##
## Cet objet n'appartient donc pas à ce lieu : c'est le semis de végétation
## V2.2, gelé, et la règle transversale nº 1 du contrat interdit d'y toucher.
## Mon diagnostic était faux, et il l'était pour la raison exacte qui a déjà
## produit deux fenêtres de mesure fausses dans cette passe : j'ai attribué
## l'objet à `TONE_DRY` sur la seule foi de sa COULEUR (ocre jaune-vert, comme
## cette constante), sans jamais vérifier que c'était bien lui. La méthode qui
## tranche vraiment est écrite dans `tools/CLAUDE.md` — repeindre le nœud
## d'une couleur impossible, recapturer, mesurer le pixel — et je ne l'ai pas
## appliquée. La valeur revient donc à ce qu'elle était : aucune mesure ne
## demande de la changer.
const TONE_DRY: Color = Color(0.74, 0.70, 0.48)

## LES PIÈCES DE KIT QUI RESTENT SUIVENT LES CROCS DANS LE FROID, sinon elles
## font tache à côté d'eux. Le multiplicateur n'est pas choisi au jugé : il
## est DÉRIVÉ de la mesure. Rendu actuel (155 ; 149 ; 138) sous les tons
## (0,82 ; 0,77 ; 0,89) ; cible (110 ; 120 ; 132), soit un rapport
## (0,71 ; 0,81 ; 0,96) → tons (0,58 ; 0,62 ; 0,85). Le gain n'étant pas
## linéaire (`scripts/CLAUDE.md`), c'est une PREMIÈRE APPROXIMATION à
## remesurer sur capture, pas une prédiction.
const TONE_KIT_FROID: Color = Color(0.58, 0.62, 0.85)
## La coiffe « grass » du kit rend menthe si on la laisse : rabattue en
## olive sombre — de l'herbe rase brûlée par le vent, pas de la mousse.
const TONE_KIT_COIFFE: Color = Color(0.46, 0.50, 0.44)
## Assise rocheuse : ardoise mouillée d'ombre au contact de la pierre,
## terre-olive au bord pour mourir dans l'herbe. Le piège mesuré ici est
## celui du lit de la source — un bord plus sombre que tout dessine un
## ANNEAU NOIR, et l'assise se relit comme une flaque.
## v2 — RECALÉ SUR CAPTURE. À (0,34 ; 0,36 ; 0,40) l'assise rendait
## RGB(153 ; 159 ; 148), soit V=0,624 et H=93° : plus CLAIRE que l'herbe
## (V=0,463) et VERTE. Elle lisait « dalle de béton », pas « roche
## affleurante » — et une dalle claire au pied d'une masse est précisément
## ce qui fait lire « posé ». Descendue et refroidie ; le bord tire
## désormais vers la terre humide, pas vers le vert.
## v3 — entre les deux essais mesurés. À (0,34…) elle rendait V=0,62 et
## VERTE (dalle de béton) ; à (0,19…) elle passait sous l'herbe et se
## confondait avec l'ombre portée de la masse — une assise qu'on ne
## distingue pas d'une ombre n'enracine rien. Posée au-dessus de l'ombre et
## sous l'herbe, en gris neutre légèrement froid.
const TONE_ASSISE: Color = Color(0.25, 0.255, 0.275)
const ASSISE_COEUR: Color = Color(0.92, 0.95, 1.02)
## Le bord tire vers la terre humide, jamais vers le vert : c'est le canal
## VERT qui faisait lire « dalle » à la première mesure.
const ASSISE_BORD: Color = Color(1.22, 1.12, 0.98)


func default_place_id() -> StringName:
	return &"valley.poi.overlook_summit.01"


func _build() -> void:
	# — LA CRÊTE CENTRALE : trois pièces FONDUES en une seule formation.
	# Une strate basse demi-enterrée fait le pied ; une masse penchée fait
	# le sommet (~4,6 m visibles — c'est elle qui se voit d'en bas et donne
	# envie de monter) ; un épaulement plus bas la rattache à l'épaule sud.
	# Trois familles, trois azimuts, trois roulis : rien de rectangulaire,
	# rien de répété.
	#
	# CHOIX DE FAMILLE JUGÉ SUR CAPTURE (v1, commit 63af918) : les grandes
	# pièces `cliff_*` de Kenney rendent des COINS BEIGES à faces planes
	# (le « tente de cirque » de la v1) — refusées pour les masses. La
	# famille `Rock_Medium_*` (atlas Rocks) rend les seuls VRAIS rochers
	# du corpus : gris-vert froids, facettés, coiffe de mousse. Les masses
	# sont donc des Rock_Medium agrandis ; les pièces Kenney ne restent
	# qu'en strates basses, re-teintées PAR SURFACE (`_teinte_kenney`) —
	# leur coiffe « grass » rend MENTHE VIF sinon, mesuré en v1.
	#
	# Dimensions calculées AVANT la pose (Rock_Medium sans correction
	# KitScale ; `rock_largeA` ×4,23, `rock_largeC` ×4,83) :
	#   strate      Rock_Medium_3 ×1,55 → 5,3 × 3,6 × 5,4 m, enterrée 2,20
	#   masse       Rock_Medium_3 ×2,2 → 7,5 × 5,1 × 7,6 m, enterrée 0,50
	#   épaulement  Rock_Medium_1 ×1,45 → 4,7 × 3,3 × 4,3 m, enterré 0,50
	# v5 — jugé sur la capture de la brèche (v4) : la strate concentrique
	# sous la masse la faisait lire PERCHÉE sur un socle (champignon). La
	# strate part vers le sud-ouest (une marche vers l'épaule), la masse
	# s'enterre de 0,9 m : sa partie la plus large touche le sol.
	#
	# CE QUI A CHANGÉ À LA DEUXIÈME CORRECTIVE : les trois pièces fondues
	# deviennent UNE masse stratifiée, et le pied de la formation devient de
	# la roche. Les points d'appui déclarés ne bougent pas — ce sont eux que
	# le filet lit, et la composition arbitrée (crête à (8 ; 4,6),
	# avant-poste à (17,8 ; −5,8), brèche entre les deux) est conservée.
	var strate_at: Vector3 = _seated(5.0, 5.4)
	declare_support(strate_at)
	# Enfoncement 1,25 et roulis ramené à 6° : l'audit v5 relevait une
	# « fente d'ombre » sous le surplomb côté joueur — le contact doit être
	# franc sur TOUTES les faces, pas seulement au point bas de l'AABB.
	# z 3,0 → 4,6 (v7) : le bord nord de la masse remonte à z ≈ +0,2 et
	# dégage l'intervalle où l'avant-poste vient de partir. Distance à la
	# diagonale de route |x+z|/√2 = 8,9 m — la marge AUGMENTE.
	#
	# ×2,2 → ×2,55 (v7b), et ce n'est pas une surenchère. Deux raisons
	# mesurées : (1) le brief de conception notait déjà le point faible de
	# la composition arbitrée — « le sommet culmine à ~4,6 m au lieu de
	# 6,3 », donc le vertige repose sur le vide seul ; les captures v6 le
	# confirment, la crête y lit « trois rochers » et non « une dent » ;
	# (2) après ouverture de la brèche, le détecteur R-D3 signalait
	# belvédère × ferme abandonnée à 30 m (IoU 0,504 pour un seuil de
	# 0,493) — deux compositions « grande masse + satellite » de MÊME
	# proportion (H ÷ emprise : 0,284 ici, 0,255 à la ferme). Grandir la
	# masse porte la proportion du lieu à ≈ 0,33 et l'éloigne de cette
	# bande. La forme suit ici l'intention, elle ne la contredit pas.
	var masse_at: Vector3 = _seated(8.0, 4.6)
	# YAW 0 : le pendage du générateur (azimut 209° en repère Blender) sort à
	# (−0,875 ; +0,485) en local Godot, soit presque exactement la direction
	# de visée de `cam05` (−0,82 ; +0,573). Les VIRES regardent donc le
	# panorama : elles se lisent comme des lignes horizontales depuis le seul
	# endroit d'où on juge ce lieu. Toute rotation les mettrait de profil.
	# ENFONCEMENT RAMENÉ DE 0,85 À 0,25 (lot 1.R.1), et ce n'est pas un
	# relâchement : la jupe enterrée du générateur descend maintenant 0,85 m
	# sous le plan de sol du modèle. Garder l'ancien enfoncement enfouirait
	# 1,70 m de roche et rendrait la crête plus BASSE qu'avant, alors que la
	# revue demande de la présence. 0,25 suffit à garantir que le plan de sol
	# reste sous le terrain là où il ondule ; la jupe fait le reste.
	_croc(&"SM_Overlook_Crest", "Croc_crete", 8.0, 4.6, 0.0, 0.18)
	declare_support(masse_at)
	var epaulement_at: Vector3 = _seated(4.2, 8.2)
	declare_support(epaulement_at)

	# — L'AVANT-POSTE DÉTACHÉ (17 ; −5) : un rocher penché et sa dalle de
	# pied, à l'écart de la crête. Ce détachement est la BIMODALITÉ qui
	# tient le PASS D3 (voir l'en-tête) : du ciel entre les deux masses
	# (emprises calculées : crête x ≤ 12,4 et z ≥ +0,2 ; avant-poste
	# x ≥ 14,9 et z ≤ −2,1 — un vide sur CHACUN des deux axes, ce que la
	# version précédente n'avait pas).
	# Distance refaite au calcul : |17,8 − 5,8|/√2 = 8,5 m de la diagonale
	# de route (seuil 1,2 ; marge collider ≈ 6,0 m), et x > 0 donc toujours
	# DERRIÈRE cam05.
	var poste_at: Vector3 = _seated(17.8, -5.8)
	# 7° et pas davantage : au-delà, le pendage de l'éperon cesse d'être
	# celui de la crête et les deux masses redeviennent deux objets voisins.
	# La variété vient des formes (graines différentes), pas de l'azimut.
	_croc(&"SM_Overlook_Spur", "Croc_poste", 17.8, -5.8, 7.0, 0.15)
	declare_support(poste_at)
	var pied_at: Vector3 = _seated(16.7, -4.0)
	declare_support(pied_at)

	# — L'ASSISE. Deux lobes DISJOINTS de roche affleurante, un par masse,
	# qui épousent le terrain sommet par sommet. Sans eux, la formation
	# rencontre l'herbe sur une ligne nette et se relit « posée » — c'est
	# la cause de rejet nº 2 du contrat. Le bord est haché et s'ÉCLAIRCIT
	# vers l'extérieur : un bord plus sombre que tout dessinerait l'anneau
	# noir déjà mesuré (et corrigé) au lit de la source.
	_assise()

	# — L'ÉPAULE : deux blocs DEMI-ENTERRÉS au bord de la rupture sud, qui
	# forment une marche puis une tablette. Le sol est encore plat à 8,8 m
	# (mesuré) et casse deux mètres plus loin : la tablette est donc juste
	# au bord, et l'arc y est posé face au vide.
	# Les deux blocs de l'épaule REJOIGNENT LE FROID des crocs : à côté d'une
	# ardoise bleutée, un galet chaud du kit fait tache et ramène exactement
	# le défaut mesuré. Ils s'enfoncent aussi d'un cran de plus (−0,90 →
	# −1,15 ; −0,75 → −1,00) : une marche est une arête qui affleure, pas un
	# caillou déposé.
	var marche: Vector3 = _seated(1.0, 6.2)
	_teinter(K.module(self, &"Rock_Medium_1",
		marche + Vector3(0.0, -0.75, 0.0), 200.0, 1.0, Color.WHITE),
		TONE_KIT_FROID, TONE_KIT_COIFFE, false)
	declare_support(marche)
	var socle: Vector3 = _seated(2.6, 8.4)
	_teinter(K.module(self, &"Rock_Medium_2",
		socle + Vector3(0.0, -0.65, 0.0), 41.0, 1.0, Color.WHITE),
		TONE_KIT_FROID, TONE_KIT_COIFFE, false)
	declare_support(socle)
	# La tablette proprement dite : une dalle plate coincée entre la crête
	# et l'épaule. C'est le seul plan horizontal du lieu, donc le seul
	# endroit où poser une arme sans qu'elle ait l'air tombée.
	var tablette: Vector3 = _seated(3.8, 5.6)
	# v7b — la tablette quitte elle aussi la famille Kenney. Elle était le
	# « petite pièce pâle isolée » relevé à QUATRE passages d'audit : un
	# disque de 72 triangles à couleur plate, plus clair que tout ce qui
	# l'entoure, sans contact lisible avec l'herbe.
	# `RockPath_Square_Small_1` mesure 1,019 × 0,150 × 0,974 m (relevé
	# `gltf_inspect`), aucune correction KitScale, `bbox_min.y = −0,0086`
	# donc `KitPlacement.seat()` ne la déplace PAS (elle ne flotte pas :
	# la règle ne descend qu'un modèle dont la géométrie commence au-dessus
	# de son ancrage). ×1,75 → 1,78 × 0,26 × 1,70 m, et son sommet tombe à
	# `0,1412 × 1,75 = 0,247` m au-dessus de l'assise. C'est ce nombre-là,
	# et pas une estimation, qui donne la hauteur d'ancre de l'arc.
	var dalle: Node3D = K.module(self, &"RockPath_Square_Small_1",
		tablette, 74.0, 1.75, Color.WHITE)
	_teinter(dalle, TONE_DALLE, TONE_DALLE, false)
	declare_support(tablette)

	# — LES ÉCLATS ET L'HERBE SÈCHE. Peu, et jamais au centre : le sommet
	# doit rester dégagé, on y arrive par la route et on en repart par elle.
	# (Les deux Grass_Wispy_Tall d'avant ont cédé leur place au budget D7 :
	# la crête est passée de 2 à 3 pièces et l'avant-poste de 1 à 2 — le
	# semis V2.2 porte déjà l'herbe du sommet.)
	# (11,8 ; −2,8) → (18,8 ; −6,8) : cet éclat tombait DANS la brèche et la
	# refermait par un pont mince, visible en aplat noir sur la silhouette
	# à 90°. Il passe au flanc extérieur de l'avant-poste, où il prolonge la
	# masse au lieu de la relier à l'autre.
	_teinter(K.module(self, &"Rock_Medium_3",
		_seated(19.6, -7.2) + Vector3(0.0, -0.15, 0.0), 37.0, 0.50,
		Color.WHITE), TONE_KIT_FROID, TONE_KIT_COIFFE, false)
	_teinter(K.module(self, &"Rock_Medium_1",
		_seated(5.4, 9.6) + Vector3(0.0, -0.30, 0.0), -62.0, 0.42,
		Color.WHITE), TONE_KIT_FROID, TONE_KIT_COIFFE, false)
	K.module(self, &"Bush_Common", _seated(7.8, 8.4), 22.0, 0.62, TONE_DRY)
	K.module(self, &"Bush_Common", _seated(18.8, -3.8), -48.0, 0.5, TONE_DRY)

	_collisions()

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Belvédère du guetteur"
	poi.region = &"r07_hauteurs_de_l_orient"
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Decouverte_forme"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 15.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	# L'arc est POSÉ SUR LA TABLETTE, pas jeté dans l'herbe : une arme qu'on
	# a laissée à un poste de guet a été déposée. L'approche vient de la
	# brèche, c'est-à-dire de l'ouest-sud-ouest. +0,25 : le SOMMET MESURÉ de
	# la nouvelle dalle (0,1412 × 1,75 = 0,247) — `WeaponPickup` rassoit le
	# modèle à sa BASE sur l'ancre, l'arc touche donc la pierre.
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.WEAPON,
		tablette + Vector3(0.0, 0.25, 0.0), Vector3(1.4, 0.0, 3.4))


## Quatre volumes, et tous à ≥ 1,2 m (marges réelles 3,5-5,9 m, calculées
## dans l'en-tête) de la diagonale de route. L'épaule reçoit UN corps pour
## ses deux blocs : ils forment une marche continue, et deux boîtes
## accolées créeraient une arête où l'on se cogne. Les colliders sont plus
## étroits que les masses visuelles : le pied d'un rocher s'évase, on ne
## bute pas sur son évasement.
func _collisions() -> void:
	# Lot 1.R.1 : la crête mesure 6,90 m de GLB pour 8,15 m d'emprise VISIBLE
	# (mesures du générateur), enfoncée de 0,25 → ≈ 6,65 m au-dessus du sol.
	# Le volume suit la géométrie visible, en restant plus ÉTROIT qu'elle : le
	# pied d'une formation s'évase et se franchit à pied, on ne bute pas sur
	# son évasement, et la jupe est sous le terrain de toute façon.
	# Demi-largeur 2,8 m pour 8,9 m de la diagonale de route : marge 6,1 m,
	# très au-dessus du seuil de 1,2 m du filet.
	K.collider_box(self, "Belvedere_crete",
		_seated(8.0, 4.6) + Vector3(0.0, 3.0, 0.0), Vector3(5.0, 6.1, 4.2),
		0.0)
	K.collider_box(self, "Belvedere_epaulement",
		_seated(4.2, 8.2) + Vector3(0.0, 1.2, 0.0), Vector3(3.6, 2.4, 3.0),
		152.0)
	# L'avant-poste : 4,30 m de GLB, 6,41 m d'emprise visible, enfoncé de 0,20.
	# Demi-largeur 2,05 m pour 8,5 m de la diagonale de route : marge 6,4 m.
	K.collider_box(self, "Belvedere_poste",
		_seated(17.8, -5.8) + Vector3(0.0, 2.0, 0.0), Vector3(3.7, 4.2, 3.3),
		7.0)
	K.collider_box(self, "Belvedere_epaule",
		_seated(1.8, 7.3) + Vector3(0.0, 0.55, 0.0), Vector3(4.6, 1.1, 3.6),
		24.0)


## POSER UNE MASSE DU GLB DÉDIÉ, recentrée sur son emprise et enterrée.
##
## Le GLB porte les DEUX crocs à la même origine : on instancie, on ne garde
## que l'objet demandé, puis on recentre — un objet dont l'emprise n'est pas
## centrée sur son origine se pose ailleurs qu'où on croit, et toutes les
## distances de route et de brèche calculées dans l'en-tête porteraient sur
## un point qui n'existe pas.
##
## LA COULEUR DE SOMMET EST FORCÉE. La matière de ces masses vit dans leur
## `COLOR_0` ; si le matériau importé ne la consommait pas, l'ardoise
## redeviendrait un aplat — SANS erreur ni avertissement (ISS-066, et le
## même geste est déjà fait sur les stèles du champ). On force le drapeau
## sur une COPIE posée en override de surface : la ressource importée n'est
## jamais mutée.
##
## L'ASSISE NE SE CALCULE PLUS SUR LE BAS DE L'EMPRISE (lot 1.R.1). Le GLB a
## désormais un `min Y` NÉGATIF, volontairement : le générateur prolonge chaque
## masse SOUS son plan de sol par une jupe évasée, et c'est cette jupe qui
## supprime la ligne de contact pierre/herbe reprochée au lieu. Le plan y = 0
## du modèle EST le sol prévu.
##
## Soustraire `boite.position.y` comme le faisait la version précédente
## remonterait donc la masse de toute la hauteur de jupe et la reposerait sur
## l'herbe — exactement le défaut qu'on répare, obtenu en croyant le corriger.
## L'ancienne ligne était juste tant que `min Y` valait 0 ; elle est fausse
## maintenant, et rien dans le rendu ne le crierait : la pièce aurait
## simplement l'air « posée », comme avant.
func _croc(objet: StringName, nom: String, x: float, z: float,
		yaw_deg: float, enfoncement: float) -> Node3D:
	var packed: PackedScene = load(CROCS_GLB) as PackedScene
	if packed == null:
		push_error("[overlook] crocs introuvables — %s" % CROCS_GLB)
		return null
	var racine: Node3D = packed.instantiate() as Node3D
	racine.name = nom
	var garde: bool = false
	for enfant: Node in racine.get_children():
		if enfant.name == String(objet):
			garde = true
		else:
			racine.remove_child(enfant)
			enfant.queue_free()
	if not garde:
		push_error("[overlook] masse %s absente du GLB" % objet)
		racine.queue_free()
		return null
	racine.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)),
		Vector3(x, 0.0, z))
	for noeud: Node in racine.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = noeud as MeshInstance3D
		if instance.mesh == null:
			continue
		for s: int in range(instance.mesh.get_surface_count()):
			var actif: StandardMaterial3D = \
				instance.get_active_material(s) as StandardMaterial3D
			if actif == null:
				continue
			var copie: StandardMaterial3D = actif.duplicate() \
				as StandardMaterial3D
			copie.vertex_color_use_as_albedo = true
			copie.roughness = maxf(copie.roughness, 0.94)
			copie.metallic_specular = 0.1
			instance.set_surface_override_material(s, copie)
	add_child(racine)
	var boite: AABB = Transform3D(racine.transform.basis, Vector3.ZERO) \
		* KitPlacement.local_aabb(racine)
	var centre: Vector3 = boite.get_center()
	racine.position.x = x - centre.x
	racine.position.z = z - centre.z
	racine.position.y = ground_local_y(x, z) - enfoncement
	return racine


## L'ASSISE — deux lobes de roche affleurante, un par masse, qui épousent le
## terrain sommet par sommet (exemption D1a nommée, même titre que le lit de
## la source : une surface qui suit le sol, comme `SolBrule` de l'arbre
## foudroyé).
##
## POURQUOI DEUX LOBES ET PAS UNE NAPPE. Une dalle continue relierait les
## deux pieds au sol et refermerait la brèche que toute la composition
## existe pour ouvrir — le défaut exact que la version v7 avait corrigé en
## déplaçant un éclat hors de l'intervalle. Les lobes sont donc bornés, et
## l'écart entre leurs bords (2,5 m au calcul) reste de l'herbe.
##
## POURQUOI LE BORD S'ÉCLAIRCIT. Le lit de la vasque de la source a payé
## deux captures pour l'avoir appris : un bord plus sombre que ce qui
## l'entoure dessine un ANNEAU, et la surface se relit comme une flaque
## posée. Ici le cœur est de l'ardoise d'ombre, le bord tire vers l'olive
## du terrain, et le contour est haché — jamais un disque.
func _assise() -> void:
	set_meta(&"exemption_runtime", PackedStringArray(["AssiseCrocs"]))
	var assise: MeshInstance3D = MeshInstance3D.new()
	assise.name = "AssiseCrocs"
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# [centre x, centre z, rayon moyen, graine]
	# Rayons RÉDUITS en v3 : les crocs ont grossi (emprise 7,47 → 8,10 m et
	# 4,96 → 5,54 m après l'approfondissement des diaclases), et à 4,25/2,95
	# les deux lobes se seraient rejoints. L'écart entre leurs bords reste
	# de l'herbe, sur les deux axes.
	# LOBES RÉTRÉCIS (4,00 → 3,10 ; 2,80 → 2,20) : l'assise déborde les masses
	# et empiétait sur le VIDE entre elles. Ce vide est le trait qui distingue
	# le lieu en aplat noir — une assise qui le comble annule la composition
	# qu'elle est censée enraciner.
	_lobe(st, 8.0, 4.6, 3.10, 3.1)
	_lobe(st, 17.8, -5.8, 2.20, 11.7)
	assise.mesh = st.commit()
	var roche: StandardMaterial3D = K.flat_material(TONE_ASSISE)
	roche.vertex_color_use_as_albedo = true
	assise.mesh.surface_set_material(0, roche)
	add_child(assise)


## Un lobe d'assise : éventail de triangles du centre vers un bord haché,
## chaque sommet posé sur le terrain gelé (+3 cm) — donc aucune arête vive
## contre le sol, quel que soit le relief.
func _lobe(st: SurfaceTool, cx: float, cz: float, rayon: float,
		graine: float) -> void:
	# 28 → 40 segments et hachage plus profond : en v1 le bord de
	# l'assise rendait un POLYGONE net (visible sur
	# `iter1/overlook_gros_crete.png`), donc une pièce déposée.
	var segments: int = 40
	var bord: PackedVector3Array = PackedVector3Array()
	var teintes: PackedColorArray = PackedColorArray()
	var brut: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(segments):
		brut.append(_alea(float(i) * 2.7 + graine))
	for i: int in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		# Lissé sur trois voisins : la modulation n'a plus de période, donc
		# pas de lobes réguliers — l'« étoile » payée par l'arbre foudroyé.
		var lisse: float = (brut[(i - 1 + segments) % segments] + brut[i]
			+ brut[(i + 1) % segments]) / 3.0
		var r: float = rayon * (0.62 + 0.58 * lisse)
		var px: float = cx + cos(angle) * r
		var pz: float = cz + sin(angle) * r
		bord.append(Vector3(px, ground_local_y(px, pz) + 0.03, pz))
		var v: float = 0.94 + 0.10 * _alea(float(i) * 5.3 + graine)
		teintes.append(Color(ASSISE_BORD.r * v, ASSISE_BORD.g * v,
			ASSISE_BORD.b * v, 1.0))
	# Le cœur est légèrement SOULEVÉ (+9 cm) : la roche affleure, elle ne
	# creuse pas. Un centre plus bas que son bord ferait une cuvette, donc
	# une flaque.
	# +0,12 → +0,06 : à douze centimètres le lobe faisait un léger
	# plateau, donc une estrade. La roche affleure, elle ne surélève pas.
	var centre: Vector3 = Vector3(cx, ground_local_y(cx, cz) + 0.06, cz)
	for i: int in range(segments):
		var j: int = (i + 1) % segments
		st.set_color(ASSISE_COEUR)
		st.set_normal(Vector3.UP)
		st.add_vertex(centre)
		st.set_color(teintes[i])
		st.set_normal(Vector3.UP)
		st.add_vertex(bord[i])
		st.set_color(teintes[j])
		st.set_normal(Vector3.UP)
		st.add_vertex(bord[j])


## Hachage déterministe dans [−1 ; 1]. Pas de `randf()` : la régression
## visuelle compare deux montages, ils doivent être identiques.
func _alea(graine: float) -> float:
	var v: float = sin(graine * 127.1 + 311.7) * 43758.5453
	return (v - floor(v)) * 2.0 - 1.0


## (`_roche()` — poser/pencher/remesurer/recentrer/enterrer — a quitté ce
## fichier avec les masses de kit. Le détour qu'il documentait reste VRAI et
## reste utilisé ailleurs : `KitPlacement.seat()` mesure AVANT le roulis, et
## certaines pièces ont leur origine sur une arête. Il vit encore dans
## `turquoise_spring_place.gd` et dans les lieux de la voie B ; c'est
## toujours un candidat `world_v2_place_kit.gd` par la règle de trois.)


## TEINTE PAR SURFACE, recette V2.2 — deux défauts mesurés sur capture :
## (v1) la coiffe « grass » Kenney rend MENTHE VIF ; (v2) `K.apply_tone`
## laisse `vertex_color_use_as_albedo` allumé et l'atlas Rocks rend
## PISTACHE au soleil, là où le bâtisseur de végétation V2.2 l'éteint
## (`_model_mesh`). Ici : couleurs de sommet COUPÉES, puis chaque surface
## reçoit SA teinte — « grass » (nom, ou albédo à dominante verte) vers
## `ton_coiffe`, le reste vers `ton_roche`. `absolu` POSE l'albédo
## (matériaux Kenney à couleur plate) au lieu de le multiplier (atlas
## texturés). Matériaux DUPLIQUÉS, jamais mutés — ils meurent avec la
## pièce, aucun cache statique (la fuite ISS-059 venait d'un cache).
func _teinter(piece: Node3D, ton_roche: Color, ton_coiffe: Color,
		absolu: bool) -> void:
	if piece == null:
		return
	var cibles: Array[Node] = piece.find_children("*", "MeshInstance3D",
		true, false)
	for noeud: Node in cibles:
		var instance: MeshInstance3D = noeud as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var actif: Material = instance.get_active_material(surface)
			var base: StandardMaterial3D = actif as StandardMaterial3D
			if base == null:
				continue
			var coiffe: bool = base.resource_name.to_lower().contains("grass") \
				or (base.albedo_color.g > base.albedo_color.r
					and base.albedo_color.g > base.albedo_color.b)
			var ton: Color = ton_coiffe if coiffe else ton_roche
			var copie: StandardMaterial3D = base.duplicate() \
				as StandardMaterial3D
			copie.vertex_color_use_as_albedo = false
			if absolu:
				copie.albedo_color = Color(ton.r, ton.g, ton.b,
					base.albedo_color.a)
			else:
				copie.albedo_color = Color(base.albedo_color.r * ton.r,
					base.albedo_color.g * ton.g, base.albedo_color.b * ton.b,
					base.albedo_color.a)
			copie.roughness = maxf(copie.roughness, 0.95)
			copie.metallic_specular = 0.1
			instance.set_surface_override_material(surface, copie)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
