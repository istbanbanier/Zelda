## SANCTUAIRE FORESTIER (`valley.poi.forest_shrine.01`, r06) — petit, bas,
## sous couvert. La seule chose du lot qu'on puisse manquer.
##
## SON IDENTITÉ EST UNE CONTRAINTE, PAS UNE DÉCORATION. Le layout dit
## « la curiosité seule y mène » ; le terrain et la route disent comment
## l'obtenir. Le site est une soucoupe : plat jusqu'à r ≈ 10 m, puis le sol
## tombe de 2,5 à 4,9 m à 16-20 m DANS TOUTES LES DIRECTIONS. Et la route
## 2 passe à **7,3 m au sud-sud-ouest, exactement à la même altitude**
## (point (84,2 ; 81,1), sol 7,00 comme le site — il est encore dans le pad
## plat). L'invisibilité ne peut donc venir ni de la distance ni du
## dénivelé : elle vient de deux décisions mesurables —
##
##   1. **RIEN DU BÂTI NE DÉPASSE 2,4 m.** La pierre de chevet, la seule
##      verticale du lieu, monte à 2,05 m sur son maillage ; la marge réelle
##      sur le nœud POSÉ est mesurée par `tools/godot/probe_sanctuaire.gd` et
##      reportée dans `RAPPORT_VOIE.md` — jamais déduite.
##   2. **UN RIDEAU SUR L'ARC SUD**, entre le sanctuaire et la route :
##      fougères et buissons à 2,2-6,2 m, SANS collider — ils masquent
##      sans rien fermer, et le filet des routes ne compte que les corps
##      solides (`ROUTE_CLEAR_M = 1,2 m` autour de chaque échantillon).
##      Les trois troncs, eux, vont au nord et à l'ouest : un tronc porte
##      un collider, et un collider à 7 m d'une route est un pari inutile.
##
## ---------------------------------------------------------------------------
## LOT 1.R — CORRECTIVE VISUELLE, COMPOSITION B « LA NEF AVALÉE ».
##
## Le gate visuel a rejeté la version en modules de kit : « les murs beige
## rectangulaires restent du graybox ». Cause mesurée, et elle n'est pas une
## affaire de teinte : l'anneau était fait de `SM_Dungeon_PillarStub` (des
## moignons à faces planes) et l'autel d'un `SM_Dungeon_ArchBlock` (un cube),
## et cette famille de trimsheet rend TERRACOTTA/BEIGE sous la lumière de ce
## monde. Aucun albédo ne répare une forme de cube.
##
## La maçonnerie du vestige est donc désormais un GLB dédié
## (`SM_Shrine_Vestige.glb`, générateur `make_forest_shrine.py`, 878 tris pour
## un budget de 6 000) : neuf pierres à pans impairs, fuseau et sommet CASSÉ,
## une mousse posée par règle de nature (faces tournées vers le haut + la
## chaussette de pied), et une table d'offrande FENDUE dont une moitié a
## glissé de 0,21 m.
##
## ET LA COMPOSITION CHANGE, pas seulement la matière. L'anneau devient un
## AXE court nord→sud : le seuil (deux montants franchement inégaux, 1,57 et
## 1,24 m, plus une marche enfoncée), deux rangées basses qui CONVERGENT vers
## le cœur, la pierre couchée qui barre à demi la nef, la table, et derrière
## elle la seule verticale — le chevet. Trois raisons, dans cet ordre :
##
##   * l'intention imposée (ADDENDUM_DA §4) demande « un seuil, un centre
##     rituel, une lumière ou une ouverture qui guide le regard » : un anneau
##     fait TOURNER le regard autour du centre, un axe l'y CONDUIT ;
##   * D3 par construction : le cercle de pierres levées INTACT appartient à
##     `watchers_circle` (lot futur), et la voie C fabrique en ce moment des
##     stèles PÂLES ET PENCHÉES dans la couleur ouverte pour la Porte du
##     champ. Ici les pierres sont grises-vertes, moussues, basses, sous
##     couvert, et la seule verticale est un DOSSIER derrière une table —
##     jamais un jalon planté dans le vide ;
##   * les trois caméras du plan gelé arrivent toutes du NORD (local z ≈ −9,5
##     à −15) : l'axe de la nef est exactement leur axe de visée, et la
##     composition se lit donc dans les cadres qui la jugent.
##
## L'implantation du SITE, la récompense et son genre, le `poi_id` et le rayon
## de découverte ne changent pas. Ce qui change : la position VERTICALE de
## l'ancre de récompense, qui suit le dessus de la nouvelle table (0,89 m au
## lieu de 0,95 m) — une offrande qui flotte au-dessus de sa table est
## précisément le défaut que l'audit a relevé chez une autre voie.
class_name ForestShrinePlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")
const VESTIGE_SCENE: PackedScene = preload(
	"res://assets/architecture/shrine/SM_Shrine_Vestige.glb")

## Dessus de la table d'offrande, mesuré sur le maillage exporté
## (`SM_Shrine_Table`, Z 0,000..0,890). Ce n'est pas un choix : c'est une cote
## lue dans le journal de la chaîne Blender, et si le générateur change, ce
## nombre doit être relu et non deviné.
const TABLE_DESSUS: float = 0.89

## TEINTES DU VESTIGE — albédos ABSOLUS, pas des multiplicateurs.
##
## Le générateur pose déjà une couleur de base, mais elle n'est pas la matière
## finale : ces deux constantes-ci sont le seul endroit à toucher pour
## recalibrer, sans repasser par Blender. Et elles se jugent sur CAPTURE
## RENDUE, jamais sur leur valeur : le gain de lumière de ce monde vaut 1,4 à
## 1,8 et n'est pas linéaire (`scripts/CLAUDE.md`). Cible de la bande §1.5,
## sous couvert : pierre 0,32-0,45 rendu, mousse 0,26-0,34.
## RECALÉ SUR CAPTURE (apres/forest_shrine_joueur.png + shrine_gp_nef.png) :
## à 0,455 la pierre RENDAIT 0,39-0,42, c'est-à-dire PLUS CLAIRE que le
## sous-bois qui l'entoure (0,351 mesuré) — le vestige sortait en dalles
## pâles et lisses, exactement la lecture dont le lead a demandé de
## s'écarter (les stèles de la voie C sont pâles, en couleur ouverte).
## Descendue à 0,375 : la pierre passe sous la valeur de l'herbe et se lit
## avalée par le bois, ce qui est l'intention du lieu.
const TEINTES_VESTIGE: Dictionary = {
	"MAT_Shrine_Stone": Color(0.375, 0.378, 0.358),
	"MAT_Shrine_Moss": Color(0.232, 0.278, 0.182),
}

## Mousse du dallage avalé — le sol du sanctuaire existait, le bois l'a repris.
const TONE_MOUSSE: Color = Color(0.62, 0.68, 0.55)

static var _cache_vestige: Dictionary = {}


func default_place_id() -> StringName:
	return &"valley.poi.forest_shrine.01"


func _build() -> void:
	_seuil()
	_nef()
	_coeur()
	_dallage_avale()
	_rideau_sud()
	_sous_bois()
	_couvert()
	_collisions()

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Sanctuaire forestier"
	poi.region = &"r06_bois_du_levant"
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Decouverte_forme"
	var sphere: SphereShape3D = SphereShape3D.new()
	# 9 m : le rayon du plat. Au-delà le sol tombe et on n'est plus dans la
	# clairière — un volume de découverte plus large annoncerait le lieu
	# depuis la route, ce que ce sanctuaire doit précisément éviter.
	sphere.radius = 9.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	# L'épice rare est POSÉE SUR LA TABLE : c'est une offrande laissée là,
	# pas une plante qui aurait poussé. On arrive par le seuil, au nord.
	# L'ALTITUDE DE L'ANCRE APPARTIENT AU LIEU (arbitrage du lead) : le VISUEL
	# de la récompense vient d'une ressource partagée, mais la cote à laquelle
	# il se pose est une décision d'implantation. `IngredientPickup` dessine sa
	# tige depuis SON origine et la baie 0,22 m plus haut ; à +0,10 au-dessus
	# du dessus de table, la baie flottait donc 0,32 m au-dessus de la dalle —
	# mesuré par l'audit sur `apres/shrine_gp_nef.png`. À −0,05 la tige mord
	# la dalle de cinq centimètres et l'offrande est POSÉE.
	RewardAnchor.attach(self, default_place_id(),
		RewardAnchor.Kind.INGREDIENT,
		_seated(0.0, 0.0) + Vector3(0.0, TABLE_DESSUS - 0.05, 0.0),
		Vector3(0.45, 0.0, -2.40))
	var ancre: Node = get_node_or_null("AncrageRecompense")
	if ancre != null:
		ancre.child_entered_tree.connect(_sur_recompense)


## HABILLAGE LOCAL DE LA RÉCOMPENSE (autorisé par le lead, lot 1.R). L'audit
## a mesuré la baie à (255, 255, 113) : saturée au maximum, et donc le point
## le plus lumineux d'un lieu dont l'intention est « calme, mystère, respect ».
## Le MODÈLE est partagé et ne se remplace pas ; la surface, elle, s'habille
## sur une COPIE, pour cette instance seulement.
##
## Le réglage est plus doux que celui du coffre du cimetière (35 % de
## désaturation contre 55 %) et volontairement : l'épice est le SEUL point
## chaud voulu de ce sanctuaire (conception, « aucun accent saturé sauf
## l'offrande »). On veut qu'elle attire, pas qu'elle crève l'image.
func _sur_recompense(noeud: Node) -> void:
	if noeud.is_node_ready():
		_habiller_recompense(noeud)
	else:
		noeud.ready.connect(_habiller_recompense.bind(noeud), CONNECT_ONE_SHOT)


func _habiller_recompense(racine: Node) -> void:
	if racine == null or not is_instance_valid(racine):
		return
	var cibles: Array[Node] = racine.find_children("*", "MeshInstance3D",
		true, false)
	if racine is MeshInstance3D:
		cibles.append(racine)
	for noeud: Node in cibles:
		var instance: MeshInstance3D = noeud as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var base: StandardMaterial3D = instance.get_active_material(
				surface) as StandardMaterial3D
			if base == null:
				continue
			var mat: StandardMaterial3D = base.duplicate() as StandardMaterial3D
			var c: Color = mat.albedo_color
			var gris: float = c.get_luminance()
			mat.albedo_color = Color(
				lerpf(c.r, gris, 0.35) * 0.86,
				lerpf(c.g, gris, 0.35) * 0.84,
				lerpf(c.b, gris, 0.35) * 0.86, c.a)
			mat.roughness = maxf(mat.roughness, 0.92)
			mat.metallic_specular = 0.1
			# `material_override` PRIME sur les surcharges de surface : écrire
			# une surcharge sur une instance qui en porte un ne ferait RIEN,
			# en silence.
			if instance.material_override != null:
				instance.material_override = mat
			else:
				instance.set_surface_override_material(surface, mat)


## LE SEUIL — deux montants FRANCHEMENT inégaux et une marche enfoncée.
##
## L'inégalité n'est pas un caprice : deux montants jumeaux se lisent
## « portique », donc bâti et symétrique, donc récent. 1,57 contre 1,24 m,
## deux fruits différents, deux cassures différentes — on lit une porte qui a
## vieilli de travers. La marche est le seul élément encore à peu près à sa
## place, et c'est elle qui dit « on entre ICI » sans un mot.
func _seuil() -> void:
	var a: Vector3 = _seated(-0.94, -3.52)
	_piece_vestige("SM_Shrine_Montant_A", a,
		Vector3(0.0, deg_to_rad(24.0), deg_to_rad(5.0)))
	declare_support(a)
	var b: Vector3 = _seated(0.82, -3.74)
	_piece_vestige("SM_Shrine_Montant_B", b,
		Vector3(0.0, deg_to_rad(-58.0), deg_to_rad(-8.0)))
	declare_support(b)
	# Enfoncée de 8 cm : une dalle qui affleure l'herbe se lit neuve.
	var marche: Vector3 = _seated(-0.05, -3.00)
	_piece_vestige("SM_Shrine_Step", marche + Vector3(0.0, -0.08, 0.0),
		Vector3(0.0, deg_to_rad(9.0), 0.0))
	declare_support(marche)


## LA NEF — deux rangées qui CONVERGENT, et la pierre couchée qui barre.
##
## Les socles passent de |x| = 1,34 au seuil à |x| = 0,82 devant la table :
## le couloir se resserre de 2,68 m à 1,64 m d'entraxe. C'est la perspective
## forcée des nefs, et c'est ce qui fait que le regard arrive au cœur au lieu
## d'errer. Les hauteurs alternent (0,97 / 0,60 / 0,81 à l'ouest, 0,81 / 0,97 /
## 0,60 à l'est) pour qu'aucune rangée ne réponde à l'autre.
##
## LA PIERRE COUCHÉE est un montant tombé — même famille, même matière. Elle
## barre la nef en travers et n'émerge que de 0,32 m.
##
## ELLE PORTE UN CORPS, ET C'EST LA SONDE QUI L'A EXIGÉ. Première version :
## aucun collider, au motif que 0,32 m passe sous la hauteur de marche du
## héros (0,30-0,38 m, §8.2) — le raisonnement du kit pour les cailloux. Mais
## `probe_sanctuaire.gd` a mesuré « plus grande marche 0,000 m sur 32 appuis » :
## sans corps, le rayon traverse la pierre, le héros aussi, et « on l'enjambe »
## n'était pas une cote mais un espoir. Le corps fait donc 0,30 m de haut —
## juste SOUS la hauteur de marche : on monte dessus d'un pas et on redescend,
## ce qui est exactement enjamber. La sonde le mesure désormais pour de vrai.
const SOCLES: Array[Array] = [
	["SM_Shrine_Socle_A", -1.34, -2.52, 37.0, -4.0],
	["SM_Shrine_Socle_C", -1.06, -1.70, -68.0, 3.0],
	["SM_Shrine_Socle_B", -0.83, -0.96, 121.0, 6.0],
	["SM_Shrine_Socle_B", 1.30, -2.36, -21.0, 5.0],
	["SM_Shrine_Socle_A", 1.00, -1.58, 92.0, -7.0],
	["SM_Shrine_Socle_C", 0.82, -0.90, -134.0, 2.0],
]
## Enfoncement de la pierre couchée. 0,19 m sous le sol : son maillage fait
## 0,51 m d'épaisseur apparente, il n'en émerge donc que 0,32 m.
const COUCHEE_ENFONCEMENT: float = 0.19


func _nef() -> void:
	for index: int in range(SOCLES.size()):
		var spec: Array = SOCLES[index]
		var at: Vector3 = _seated(float(spec[1]), float(spec[2]))
		_piece_vestige(String(spec[0]), at,
			Vector3(0.0, deg_to_rad(float(spec[3])),
				deg_to_rad(float(spec[4]))),
			"Socle_%d" % index)
		declare_support(at)
	var couchee: Vector3 = _seated(-0.10, -2.10)
	_piece_vestige("SM_Shrine_Fallen",
		couchee + Vector3(0.0, -COUCHEE_ENFONCEMENT, 0.0),
		Vector3(0.0, deg_to_rad(82.0), deg_to_rad(3.0)))
	declare_support(couchee)


## LE CŒUR — la table fendue et son chevet.
##
## La table est l'élément héroïque du lieu : une dalle cassée en deux dont une
## moitié a GLISSÉ de 0,21 m, posée sur deux dés inégaux, et l'épice rare
## dessus. C'est le seul endroit du lot où la récompense EST la narration —
## quelqu'un dépose encore une offrande sur une table brisée.
##
## Le chevet est la seule verticale du sanctuaire, et c'est un DOSSIER : il se
## tient derrière la table, du côté de la route, à 0,95 m. Deux fonctions dans
## la même pierre — il donne au cœur son fond, et il ajoute une masse de plus
## entre la table et la route.
func _coeur() -> void:
	var table: Vector3 = _seated(0.0, 0.0)
	_piece_vestige("SM_Shrine_Table", table,
		Vector3(0.0, deg_to_rad(12.0), 0.0))
	declare_support(table)
	var chevet: Vector3 = _seated(0.16, 0.95)
	_piece_vestige("SM_Shrine_Chevet", chevet,
		Vector3(0.0, deg_to_rad(-34.0), deg_to_rad(6.0)))
	declare_support(chevet)


## LE DALLAGE AVALÉ — trois dalles enfoncées de huit centimètres, dans l'axe
## de la nef. Le sol du sanctuaire existait ; le bois l'a repris.
func _dallage_avale() -> void:
	for spec: Array in [[-0.35, -1.25, 31.0], [0.45, -2.35, -18.0],
			[-0.20, -0.35, 57.0]]:
		K.module(self, &"Floor_UnevenBrick",
			_seated(float(spec[0]), float(spec[1]))
				+ Vector3(0.0, -0.08, 0.0), float(spec[2]), 1.0, TONE_MOUSSE)


## LE RIDEAU SUD — ce qui rend le lieu invisible depuis la route, à 7,3 m.
##
## RENFORCÉ pour le lot 1.R, et pour une raison mesurable : la composition B
## dresse au sud du cœur une pierre de 2,05 m là où l'ancienne version n'avait
## qu'un moignon de 1,32 m. Le rideau avance donc de 4,5-6,0 m à 2,2-6,2 m et
## gagne en hauteur. Toujours AUCUN collider : ils masquent, ils ne ferment
## pas, et le filet des routes ne compte que les corps solides.
##
## `Fern_1` mesure 9,05 m de large en natif ; `KitScale` le ramène à 0,62 m de
## haut (facteur 0,2306), soit 2,09 m d'envergure. `Bush_Common` est la seule
## masse du kit qui monte assez pour couvrir un chevet vu de 7 m.
func _rideau_sud() -> void:
	# LE SIXIÈME BUISSON EST UNE MESURE, PAS UNE DÉCORATION. La capture
	# `apres2/shrine_gp_route_p1.png` — prise depuis la route, au point P1
	# (84, 7, 81), regard nord — montre le rideau faisant son travail SAUF sur
	# une bande : le chevet dépasse d'une trentaine de centimètres au-dessus
	# des buissons, en (630-690, 285-390). La ligne P1 → chevet passe par le
	# local (−0,93 ; 4,0) ; c'est là que va le buisson manquant, et les deux
	# voisins montent d'un cran. Aucun collider, comme tout le rideau : il
	# masque, il ne ferme pas.
	for spec: Array in [[-2.20, 2.95, 41.0, 1.40], [1.45, 3.35, -27.0, 1.55],
			[-0.40, 4.55, 66.0, 1.55], [3.15, 3.75, 12.0, 1.15],
			[-3.55, 4.15, -74.0, 1.25], [-0.95, 3.95, 28.0, 1.62]]:
		K.module(self, &"Bush_Common", _seated(float(spec[0]), float(spec[1])),
			float(spec[2]), float(spec[3]), K.TONE_PLANT)
	for spec: Array in [[-1.60, 2.25, 41.0, 1.10], [0.90, 2.55, -27.0, 1.20],
			[2.40, 2.90, 66.0, 1.00], [-3.05, 2.70, 12.0, 1.05]]:
		K.module(self, &"Fern_1", _seated(float(spec[0]), float(spec[1])),
			float(spec[2]), float(spec[3]), K.TONE_PLANT)
	# Le bord sud du rideau porte l'emprise visuelle du lieu vers le sud : il
	# DÉCLARE donc son assise, sinon le tiers haut de l'axe Z n'aurait aucun
	# appui et D2 aurait raison de le dire.
	declare_support(_seated(-0.40, 4.55))
	declare_support(_seated(-3.55, 4.15))


## Ce qui pousse à l'ombre d'un vestige. Les champignons vont au PIED des
## pierres, jamais au milieu du passage : ils accompagnent la masse, ils ne
## meublent pas le vide.
func _sous_bois() -> void:
	K.module(self, &"Mushroom_Common", _seated(-1.62, -2.72), 0.0, 1.0,
		K.TONE_PLANT)
	K.module(self, &"Mushroom_Common", _seated(1.55, -1.42), 90.0, 0.85,
		K.TONE_PLANT)
	K.module(self, &"Mushroom_Laetiporus", _seated(-1.10, 0.55), -55.0, 0.75,
		K.TONE_PLANT)
	K.module(self, &"Pebble_Round_3", _seated(0.95, -3.35), 24.0, 1.0,
		TONE_MOUSSE)
	K.module(self, &"Pebble_Square_1", _seated(-1.80, -0.25), -61.0, 1.0,
		TONE_MOUSSE)


## LE COUVERT — trois troncs, tous au NORD et à l'OUEST, jamais au sud.
##
## Deux raisons, et la seconde décide : au sud passe la route, et un tronc
## porte un collider ; on ne place pas un collider à cette distance pour un
## effet qu'un buisson sans collider obtient aussi bien.
##
## LOT 1.R — ILS SONT DÉPLACÉS, ET LA VÉRIFICATION EXIGÉE PAR LE LEAD EST
## FAITE DANS LE CODE : ces trois troncs-là sont posés PAR CE FICHIER, ligne
## ci-dessous, et n'appartiennent donc pas au semis V2.2 gelé (lequel est bâti
## par `world_v2_vegetation_builder.gd` sous `WorldV2/Vegetation`, un autre
## sous-arbre, que ce lieu ne touche jamais). Le gel reste intact : si un
## tronc GELÉ bloque encore l'approche nord, il reste où il est et la
## composition fait avec — c'est l'arbitrage du lead, et `probe_sanctuaire.gd`
## recense ce qui est gelé autour du site pour que le constat soit une mesure.
##
## Ils passent de r ≈ 7,5-9 m à r ≈ 4,5-6,5 m et se placent en FLANC de la
## nef, hors de l'axe de visée des trois caméras du plan (qui arrivent toutes
## du nord) : ils encadrent au lieu de masquer, et le couvert se referme sur
## les côtés pendant que le dessus du cœur reste ouvert.
func _couvert() -> void:
	# RECALÉS SUR CAPTURE : à (−4,60 ; −4,20) et (4,40 ; −3,60) les deux pins
	# tombaient SUR l'axe de visée de `forest_shrine_joueur_b` et de
	# `shrine_gp_nef` — un tronc en plein milieu de la nef, ce qui est
	# précisément le reproche « les arbres masquent au lieu de cadrer ». Les
	# lignes de visée des trois caméras gelées passent par le centre du lieu ;
	# à z ≈ −2 elles sont à |x| ≤ 1,3 m. Les pins vont donc à |x| ≈ 6 : ils
	# tiennent le bord du cadre et laissent la nef libre.
	for spec: Array in [[-5.90, -1.40, 33.0, 1.00, &"Pine_3"],
			[5.70, -2.20, -47.0, 0.90, &"Pine_3"],
			[-6.40, 1.20, 15.0, 0.85, &"CommonTree_3"]]:
		var at: Vector3 = _seated(float(spec[0]), float(spec[1]))
		K.module(self, spec[4] as StringName, at, float(spec[2]),
			float(spec[3]), K.TONE_PLANT)
		declare_support(at)


## LES COLLISIONS — onze volumes, et le choix de ce qui n'en reçoit PAS est
## aussi délibéré que celui de ce qui en reçoit.
##
## En reçoivent : la table, le chevet, les deux montants du seuil, les quatre
## socles d'au moins 0,80 m, les trois troncs. N'en reçoivent pas : les deux
## socles de 0,60 m et la pierre couchée (0,32 m d'émergence) — on les
## enjambe, et un corps sur chacun ferait treize volumes dans un cercle de
## sept mètres. Le rideau sud n'en a aucun, par contrat : il masque, il ne
## ferme pas.
##
## Le couloir libre entre les deux rangées vaut 1,64 m d'entraxe moins deux
## demi-emprises de 0,30 m, soit 1,04 m au plus étroit : la capsule du héros
## passe. Vérifié par sonde physique, pas par ce calcul.
func _collisions() -> void:
	K.collider_box(self, "Sanctuaire_table",
		_seated(0.0, 0.0) + Vector3(0.0, 0.45, 0.0), Vector3(1.70, 0.90, 1.20),
		12.0)
	K.collider_box(self, "Sanctuaire_chevet",
		_seated(0.16, 0.95) + Vector3(0.0, 1.02, 0.0),
		Vector3(1.00, 2.05, 0.55), -34.0)
	K.collider_box(self, "Sanctuaire_montant_ouest",
		_seated(-0.94, -3.52) + Vector3(0.0, 0.79, 0.0),
		Vector3(0.60, 1.57, 0.46), 24.0)
	K.collider_box(self, "Sanctuaire_montant_est",
		_seated(0.82, -3.74) + Vector3(0.0, 0.62, 0.0),
		Vector3(0.48, 1.24, 0.50), -58.0)
	for index: int in range(SOCLES.size()):
		var spec: Array = SOCLES[index]
		var hauteur: float = 0.97 if String(spec[0]).ends_with("_A") else \
			(0.81 if String(spec[0]).ends_with("_B") else 0.60)
		if hauteur < 0.80:
			continue
		K.collider_box(self, "Sanctuaire_socle_%d" % index,
			_seated(float(spec[1]), float(spec[2]))
				+ Vector3(0.0, hauteur * 0.5, 0.0),
			Vector3(0.60, hauteur, 0.55), float(spec[3]))
	# La pierre couchée : un corps de 0,30 m, sous la hauteur de marche. Voir
	# `_nef()` — sans lui la sonde mesurait une marche de 0,000 m, c'est-à-dire
	# une traversée.
	K.collider_box(self, "Sanctuaire_pierre_couchee",
		_seated(-0.10, -2.10) + Vector3(0.0, 0.15, 0.0),
		Vector3(1.85, 0.30, 0.58), 82.0)
	for spec: Array in [[-5.90, -1.40], [5.70, -2.20], [-6.40, 1.20]]:
		K.collider_box(self, "Sanctuaire_tronc_%d" % get_child_count(),
			_seated(float(spec[0]), float(spec[1]))
				+ Vector3(0.0, 2.6, 0.0), Vector3(0.85, 5.2, 0.85))


## Extrait UNE pièce du GLB du vestige (recette `_piece_tour` de la tour) :
## l'instance est élaguée AVANT d'entrer dans l'arbre et porte un nom
## explicite — Godot rebaptise les homonymes en `@Node3D@366`, et six socles
## tirés de trois maillages en produiraient trois paires (`scripts/CLAUDE.md`).
func _piece_vestige(piece: String, at: Vector3, rot: Vector3,
		nom: String = "") -> Node3D:
	var instance: Node3D = VESTIGE_SCENE.instantiate() as Node3D
	instance.name = piece
	for enfant: Node in instance.get_children():
		if String(enfant.name) != piece:
			instance.remove_child(enfant)
			enfant.free()
		else:
			enfant.name = "%s_maille" % piece
	if not nom.is_empty():
		instance.name = nom
	add_child(instance)
	instance.position = at
	instance.rotation = rot
	_peindre_vestige(instance)
	return instance


## Aplat painterly sur les matériaux du GLB — matériaux DUPLIQUÉS et mis en
## cache, jamais de mutation d'une ressource importée (recette `_peindre_glb`
## de la ferme R2B.2 et de la tour).
##
## AUCUNE CARTE N'EST BRANCHÉE ICI, et c'est une leçon payée dans ce même lot :
## sur les pièces tombées de la tour, `T_UnevenBrick_BaseColor` box-projetée
## sur des facettes de 0,3 m échantillonne surtout le mortier peint et sort
## « chocolat glacé ». La famille qui s'intègre au terrain gelé est celle des
## falaises — aplat plus facettes. Un vestige moussu est de cette famille-là.
func _peindre_vestige(racine: Node3D) -> void:
	for node: Node in racine.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var base: StandardMaterial3D = instance.get_active_material(
				surface) as StandardMaterial3D
			if base == null:
				continue
			var famille: String = base.resource_name
			var cle: String = "sanctuaire|%d" % base.get_instance_id()
			var mat: StandardMaterial3D = \
				_cache_vestige.get(cle) as StandardMaterial3D
			if mat == null:
				mat = base.duplicate() as StandardMaterial3D
				mat.roughness = maxf(mat.roughness, 0.95)
				mat.metallic_specular = 0.1
				# LE MULTIPLICATEUR DE COULEUR DE SOMMET, sans quoi le
				# `COLOR_0` du GLB ne sert à rien : Godot ne l'active pas
				# forcément à l'import, et un aplat sans variation est
				# exactement ce que la première capture a montré (ISS-066).
				# L'albédo ci-dessous devient donc une TEINTE, et la variation
				# vient du maillage : strates, veines, pied assombri.
				mat.vertex_color_use_as_albedo = true
				if TEINTES_VESTIGE.has(famille):
					mat.albedo_color = TEINTES_VESTIGE[famille] as Color
				_cache_vestige[cle] = mat
			instance.set_surface_override_material(surface, mat)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)


## ISS-059 — fin de vie du cache statique. Inscrite au démarrage du script
## par `_static_init()`, appelée UNE fois à l'extinction du moteur par
## `SceneFlow._exit_tree()`. Sans elle, ces entrées vivent jusqu'à la mort du
## processus et sortent au rapport de fuite.
##
## AJOUTÉE au lot 1.R : ce lieu a gagné un cache statique en même temps que
## son GLB dédié, et l'invariant `test_tout_cache_statique_de_ressources_est_liberable`
## l'a vu — 960 tests verts, un seul rouge, et c'était celui-là.
##
## Le sens de la dépendance est imposé : le porteur connaît le noyau, le
## noyau ne connaît aucun porteur (test_aucune_reference_croisee_interdite).
static func _static_init() -> void:
	StaticResourceCaches.enregistrer("ForestShrinePlace", liberer_caches)


static func liberer_caches() -> int:
	var n: int = _cache_vestige.size()
	_cache_vestige.clear()
	return n
