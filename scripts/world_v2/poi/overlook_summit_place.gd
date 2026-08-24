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
class_name OverlookSummitPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

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
const TONE_CREST_A: Color = Color(0.82, 0.77, 0.89)
const TONE_CREST_B: Color = Color(0.75, 0.72, 0.83)
const TONE_CREST_C: Color = Color(0.71, 0.69, 0.80)
const TONE_LEDGE: Color = Color(0.79, 0.75, 0.82)
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
const TONE_SOCLE: Color = Color(0.78, 0.76, 0.82)
const TONE_DALLE: Color = Color(0.86, 0.84, 0.82)
## Herbe sèche du sommet : le vert de la prairie n'y monte pas.
const TONE_DRY: Color = Color(0.74, 0.70, 0.48)


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
	var strate_at: Vector3 = _seated(5.0, 5.4)
	var strate: Node3D = _roche(&"Rock_Medium_3", 5.0, 5.4, 24.0, 0.0, 1.55,
		2.20)
	_teinter(strate, TONE_SOCLE, TONE_SOCLE, false)
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
	_teinter(_roche(&"Rock_Medium_3", 8.0, 4.6, 205.0, 6.0, 2.26, 1.25),
		TONE_CREST_A, TONE_CREST_A, false)
	declare_support(masse_at)
	var epaulement_at: Vector3 = _seated(4.2, 8.2)
	_teinter(_roche(&"Rock_Medium_1", 4.2, 8.2, 152.0, -7.0, 1.45, 0.50),
		TONE_CREST_B, TONE_CREST_B, false)
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
	_teinter(_roche(&"Rock_Medium_2", 17.8, -5.8, 30.0, -8.0, 1.75, 0.45),
		TONE_CREST_C, TONE_CREST_C, false)
	declare_support(poste_at)
	# La dalle de pied suit son rocher et RÉTRÉCIT (×0,9 → ×0,75) : à
	# l'ancienne taille elle remontait jusqu'à z ≈ −0,4 et rebouchait en Z
	# le vide que l'avant-poste venait d'ouvrir en X.
	var pied_at: Vector3 = _seated(16.7, -4.0)
	var pied: Node3D = _roche(&"Rock_Medium_2", 16.7, -4.0, -38.0, 0.0, 0.95,
		0.60)
	_teinter(pied, TONE_SOCLE, TONE_SOCLE, false)
	declare_support(pied_at)

	# — L'ÉPAULE : deux blocs DEMI-ENTERRÉS au bord de la rupture sud, qui
	# forment une marche puis une tablette. Le sol est encore plat à 8,8 m
	# (mesuré) et casse deux mètres plus loin : la tablette est donc juste
	# au bord, et l'arc y est posé face au vide.
	var marche: Vector3 = _seated(1.0, 6.2)
	_teinter(K.module(self, &"Rock_Medium_1",
		marche + Vector3(0.0, -0.90, 0.0), 200.0, 1.0, Color.WHITE),
		TONE_LEDGE, TONE_LEDGE, false)
	declare_support(marche)
	var socle: Vector3 = _seated(2.6, 8.4)
	_teinter(K.module(self, &"Rock_Medium_2",
		socle + Vector3(0.0, -0.75, 0.0), 41.0, 1.0, Color.WHITE),
		TONE_LEDGE, TONE_LEDGE, false)
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
		Color.WHITE), TONE_CREST_C, TONE_CREST_C, false)
	_teinter(K.module(self, &"Rock_Medium_1",
		_seated(5.4, 9.6) + Vector3(0.0, -0.30, 0.0), -62.0, 0.42,
		Color.WHITE), TONE_CREST_B, TONE_CREST_B, false)
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
	K.collider_box(self, "Belvedere_crete",
		_seated(7.3, 5.0) + Vector3(0.0, 2.5, 0.0), Vector3(5.6, 5.0, 4.8),
		20.0)
	K.collider_box(self, "Belvedere_epaulement",
		_seated(4.2, 8.2) + Vector3(0.0, 1.2, 0.0), Vector3(3.6, 2.4, 3.0),
		152.0)
	K.collider_box(self, "Belvedere_poste",
		_seated(17.8, -5.8) + Vector3(0.0, 1.3, 0.0), Vector3(4.0, 2.6, 3.2),
		30.0)
	K.collider_box(self, "Belvedere_epaule",
		_seated(1.8, 7.3) + Vector3(0.0, 0.55, 0.0), Vector3(4.6, 1.1, 3.6),
		24.0)


## POSER UNE ROCHE PENCHÉE, RECENTRÉE SUR SA VRAIE EMPRISE, PIED ENTERRÉ.
##
## Deux défauts mesurés du kit imposent ce détour (brief commun, piège 4) :
## `cliff_half_rock` a son origine sur une ARÊTE (bbox z ∈ [0,0815 ; 0,500])
## — posé « à (x ; z) », son centre visuel part 2 m plus loin ; et
## `KitPlacement.seat()` mesure AVANT le roulis ajouté ici — une pièce
## penchée ensuite flotte ou s'enterre au hasard de sa forme.
##
## On ne devine donc pas : on pose, on penche, on REMESURE l'emprise dans
## le repère du parent, on recentre le milieu de l'emprise sur (x ; z)
## voulu et on enfonce de la profondeur VOULUE sous le sol de ce point.
## Les distances de route et la bimodalité D3 calculées dans l'en-tête
## portent sur ces centres d'emprise — le recentrage les rend vraies.
## (Même famille que `_coucher()` des lieux de la voie B ; troisième
## emploi → candidat `world_v2_place_kit.gd`, déjà remonté au lead.)
func _roche(modele: StringName, x: float, z: float, yaw_deg: float,
		roulis_deg: float, extra: float, enfoncement: float) -> Node3D:
	var piece: Node3D = K.module(self, modele, Vector3(x, 0.0, z), yaw_deg,
		extra, Color.WHITE)
	if piece == null:
		return null
	piece.rotation.z = deg_to_rad(roulis_deg)
	var boite: AABB = Transform3D(piece.transform.basis, Vector3.ZERO) \
		* KitPlacement.local_aabb(piece)
	var centre: Vector3 = boite.get_center()
	piece.position.x = x - centre.x
	piece.position.z = z - centre.z
	piece.position.y = ground_local_y(x, z) - boite.position.y - enfoncement
	return piece


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
