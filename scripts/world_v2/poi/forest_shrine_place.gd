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
##   1. **RIEN DU BÂTI NE DÉPASSE 2,4 m.** Le plus haut moignon monte à
##      2,34 m, l'autel à 1,13 m, le moignon couché à 1,32 m. Seuls les
##      troncs montent (7,4 et 8,0 m) — et c'est précisément le contraste
##      voulu : ce qui dépasse est du bois, ce qui est bâti reste sous
##      l'herbe haute. C'est le seul lieu du lot dont toute la maçonnerie
##      tienne sous la hauteur d'un héros et demi.
##   2. **UN RIDEAU SUR L'ARC SUD**, entre le sanctuaire et la route :
##      fougères et buissons à 4,5-6,0 m, SANS collider — ils masquent
##      sans rien fermer, et le filet des routes ne compte que les corps
##      solides (`ROUTE_CLEAR_M = 1,2 m` autour de chaque échantillon).
##      Les trois troncs, eux, vont au nord et à l'ouest : un tronc porte
##      un collider, et un collider à 7 m d'une route est un pari inutile.
##
## LA GRAMMAIRE EST CELLE DU VESTIGE (§2 du contrat : « plus ancien que la
## ruine : masses tombées, racines, céramique ivoire »), et le motif est
## celui du monde : un ANNEAU INCOMPLET (`VISUAL_ASSET_BIBLE` §2.3). Cinq
## moignons de quatre hauteurs différentes, à pas irréguliers, dont un
## COUCHÉ en travers — la plus grande brèche de l'anneau regarde le nord,
## à l'opposé de la route, pour qu'on découvre le lieu en y entrant et non
## en passant à côté.
##
## POURQUOI PAS UNE CHAPELLE. Le hameau bûcheron est à 38,8 m et le camp
## des pillards à 47,1 m : tout ce qui aurait un mur, un toit ou une
## enceinte doublerait l'un des deux. Ici, aucun mur — une table, un
## anneau rompu, et le bois qui reprend.
class_name ForestShrinePlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")

## Pierre du vestige : plus grise et plus sourde que celle des ruines — ce
## bâti-là est de plusieurs siècles leur aîné.
const TONE_ANCIENNE: Color = Color(0.70, 0.70, 0.64)
## Céramique ivoire de la bible §1.4 (`#D8C8A1`), la matière isolante du
## monde. C'est le seul accent clair du lieu, et il tient dans une tablette
## de 0,90 m — un vestige n'a pas de vitrine.
const TONE_IVOIRE: Color = Color(0.85, 0.78, 0.63)
## Mousse : le dallage et les moignons ont pris le bois par en dessous.
const TONE_MOUSSE: Color = Color(0.62, 0.68, 0.55)

## Hauteur du dessus de l'autel, dans le repère du lieu.
const AUTEL_Y: float = 0.95


func default_place_id() -> StringName:
	return &"valley.poi.forest_shrine.01"


func _build() -> void:
	_autel()
	_anneau_rompu()
	_dallage_avale()
	_rideau_sud()
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
	# L'épice rare est POSÉE SUR L'AUTEL : c'est une offrande laissée là,
	# pas une plante qui aurait poussé. On y arrive par la brèche nord.
	RewardAnchor.attach(self, default_place_id(),
		RewardAnchor.Kind.INGREDIENT,
		_seated(0.0, 0.0) + Vector3(0.0, AUTEL_Y + 0.16, 0.0),
		Vector3(0.6, 0.0, -2.6))


## L'AUTEL — deux dés, une dalle, une tablette. Une TABLE basse, jamais un
## cube : c'est l'horizontale qui distingue un vestige d'une ruine, et
## c'est elle qui donne au lieu sa première masse.
##
## `SM_Dungeon_ArchBlock` mesure 0,93 × 1,01 × 0,93 m, base à 0 ;
## `RockPath_Square_Wide` mesure 2,05 × 0,176 × 1,99 m, pivot centré. La
## dalle repose donc à 0,95 m, un peu moins que la hauteur des dés — elle
## MORD sur eux de six centimètres au lieu d'affleurer. Une dalle qui
## affleure se lit posée ; une dalle qui mord se lit scellée.
func _autel() -> void:
	var socle: Vector3 = _seated(0.0, 0.0)
	declare_support(socle)
	var autel: Node3D = Node3D.new()
	autel.name = "Autel"
	add_child(autel)
	autel.position = socle
	K.module(autel, &"SM_Dungeon_ArchBlock", Vector3(-0.78, 0.0, -0.34),
		17.0, 1.0, TONE_ANCIENNE)
	K.module(autel, &"SM_Dungeon_ArchBlock", Vector3(0.78, 0.0, 0.34),
		-41.0, 1.0, TONE_ANCIENNE)
	var dalle: Node3D = K.module(autel, &"RockPath_Square_Wide",
		Vector3(0.0, AUTEL_Y, 0.0), 24.0, 1.0, TONE_ANCIENNE)
	if dalle != null:
		# La dalle a glissé : elle ne repose plus d'aplomb sur ses dés. Deux
		# degrés suffisent — au-delà, elle tomberait.
		dalle.rotation.z = deg_to_rad(-2.4)
	# LA TABLETTE DE CÉRAMIQUE IVOIRE : `Floor_Brick` réduit à 0,45, soit
	# 0,90 m de côté pour deux centimètres d'épaisseur. C'est la matière
	# isolante du monde, et le seul objet clair du sanctuaire.
	K.module(autel, &"Floor_Brick", Vector3(-0.12, AUTEL_Y + 0.12, 0.08),
		-9.0, 0.45, TONE_IVOIRE)


## L'ANNEAU ROMPU — cinq moignons, quatre hauteurs, cinq azimuts
## irréguliers, et un COUCHÉ. La plus grande brèche (≈ 100°) regarde le
## nord, à l'opposé de la route : on entre par là.
##
## `SM_Dungeon_PillarStub` fait 1,00 × 1,31 × 1,00 m ; les facteurs
## ci-dessous donnent 0,85 / 1,35 / 1,95 / 2,35 m. Aucun n'est d'aplomb :
## un anneau de moignons verticaux et réguliers redeviendrait un cercle de
## pierres levées, ce qui appartient à un autre lieu du layout
## (`watchers_circle`), et se lirait « bâti hier ».
func _anneau_rompu() -> void:
	var debout: Array[Array] = [
		[3.40, -1.60, 1.79, 26.0, -5.5],
		[1.40, -3.50, 0.65, -63.0, 4.0],
		[-1.90, -3.30, 1.03, 108.0, -3.0],
		[-3.60, -0.60, 1.49, -22.0, 6.5],
	]
	for spec: Array in debout:
		var at: Vector3 = _seated(float(spec[0]), float(spec[1]))
		var moignon: Node3D = K.module(self, &"SM_Dungeon_PillarStub", at,
			float(spec[3]), float(spec[2]), TONE_ANCIENNE)
		if moignon != null:
			moignon.rotation.z = deg_to_rad(float(spec[4]))
		declare_support(at)
	# LE CINQUIÈME EST TOMBÉ, en travers du sud-ouest — vers la route, comme
	# si on l'avait poussé de l'intérieur. Couché, son diamètre devient sa
	# hauteur : 1,2 m au sol, une masse qu'on enjambe.
	var chute: Vector3 = _seated(-2.4, 2.6)
	var couche: Node3D = K.module(self, &"SM_Dungeon_PillarStub", chute,
		34.0, 1.20, TONE_ANCIENNE)
	_coucher(couche, 83.0, 0.06)
	declare_support(chute)


## LE DALLAGE AVALÉ — trois dalles enfoncées de huit centimètres et
## quelques galets. Le sol du sanctuaire existait ; le bois l'a repris.
## Enfoncées, jamais posées : une dalle qui affleure l'herbe se lit neuve.
func _dallage_avale() -> void:
	for spec: Array in [[-1.60, 1.40, 31.0], [1.50, 1.70, -18.0],
			[0.20, -2.00, 57.0]]:
		K.module(self, &"Floor_UnevenBrick",
			_seated(float(spec[0]), float(spec[1]))
				+ Vector3(0.0, -0.08, 0.0), float(spec[2]), 1.0, TONE_MOUSSE)
	for spec: Array in [[2.30, 0.90, &"Pebble_Round_3"],
			[-0.90, 3.10, &"Pebble_Square_1"],
			[-3.10, 1.90, &"Pebble_Round_5"]]:
		K.module(self, spec[2] as StringName,
			_seated(float(spec[0]), float(spec[1])), 0.0, 1.0, TONE_MOUSSE)


## LE RIDEAU SUD — ce qui rend le lieu invisible depuis la route, à 7,3 m.
## Fougères et buissons, AUCUN collider : ils masquent, ils ne ferment pas,
## et le filet des routes ne compte que les corps solides.
##
## `Fern_1` mesure 9,05 m de large en natif ; `KitScale` le ramène à 0,62 m
## de haut (facteur 0,2306), soit 2,09 m d'envergure — la bonne échelle
## pour une frange, et la raison pour laquelle il n'en faut que quatre.
func _rideau_sud() -> void:
	for spec: Array in [[-2.60, 4.90, 41.0, 1.00], [0.90, 5.40, -27.0, 1.15],
			[3.60, 4.20, 66.0, 0.90], [-4.80, 3.40, 12.0, 1.05]]:
		K.module(self, &"Fern_1", _seated(float(spec[0]), float(spec[1])),
			float(spec[2]), float(spec[3]), K.TONE_PLANT)
	for spec: Array in [[-1.20, 6.40, 74.0, 0.95], [2.60, 6.10, -38.0, 1.10],
			[5.10, 3.90, 21.0, 0.80]]:
		K.module(self, &"Bush_Common", _seated(float(spec[0]), float(spec[1])),
			float(spec[2]), float(spec[3]), K.TONE_PLANT)
	# Ce qui pousse à l'ombre d'un vestige : trois champignons et deux
	# plantes basses, au pied des moignons et de l'autel.
	K.module(self, &"Mushroom_Common", _seated(-3.10, -1.80), 0.0, 1.0,
		K.TONE_PLANT)
	K.module(self, &"Mushroom_Common", _seated(2.90, -2.60), 90.0, 0.85,
		K.TONE_PLANT)
	K.module(self, &"Mushroom_Laetiporus", _seated(-4.20, 1.20), -55.0, 0.75,
		K.TONE_PLANT)
	K.module(self, &"Plant_7", _seated(1.90, 3.20), 23.0, 1.0, K.TONE_PLANT)
	K.module(self, &"Plant_7", _seated(-2.20, -4.40), -71.0, 1.0, K.TONE_PLANT)


## LE COUVERT — trois troncs, tous au NORD et à l'OUEST, jamais au sud.
##
## Deux raisons, et la seconde décide : au sud passe la route, et un tronc
## porte un collider ; à 7,3 m d'un échantillon de route, l'emprise XZ d'un
## corps de 0,9 m plus la marge de 1,2 m entre dans la fenêtre du filet. On
## ne place pas un collider à cette distance pour un effet qu'un buisson
## sans collider obtient aussi bien.
##
## À VÉRIFIER SOUS MOTEUR : la végétation V2.2 gelée n'exclut PAS les sites
## de POI (lecture de `world_v2_vegetation_builder.gd` : elle n'écarte que
## routes, gués, checkpoints et caméras). La note du layout « clairière
## calme garantie » n'est donc appliquée par aucun code. Si
## `probe_vegetation_near` montre des troncs gelés dans ces rayons, ce sont
## CES trois-là qui sautent, pas les gelés.
func _couvert() -> void:
	for spec: Array in [[-7.50, -6.50, 33.0, 1.00, &"Pine_3"],
			[8.00, -5.50, -47.0, 0.90, &"Pine_3"],
			[-9.00, -1.00, 15.0, 0.85, &"CommonTree_3"]]:
		var at: Vector3 = _seated(float(spec[0]), float(spec[1]))
		K.module(self, spec[4] as StringName, at, float(spec[2]),
			float(spec[3]), K.TONE_PLANT)
		declare_support(at)


## Sept volumes : l'autel, les deux moignons qui montent assez haut pour
## qu'on s'y cogne, le moignon couché, et les trois troncs. Les deux petits
## moignons (0,85 m et 1,35 m) n'en reçoivent pas — on les enjambe, et un
## collider sur chacun ferait sept corps dans un cercle de sept mètres.
func _collisions() -> void:
	K.collider_box(self, "Sanctuaire_autel",
		_seated(0.0, 0.0) + Vector3(0.0, 0.56, 0.0), Vector3(2.2, 1.12, 2.1),
		24.0)
	K.collider_box(self, "Sanctuaire_moignon_est",
		_seated(3.40, -1.60) + Vector3(0.0, 1.18, 0.0),
		Vector3(0.95, 2.35, 0.95), 26.0)
	K.collider_box(self, "Sanctuaire_moignon_ouest",
		_seated(-3.60, -0.60) + Vector3(0.0, 0.98, 0.0),
		Vector3(0.85, 1.95, 0.85), -22.0)
	# Le moignon couché fait 1,32 m d'épaisseur apparente une fois basculé
	# de 83° (1,20 m de diamètre plus le reliquat de sa longueur) : au-dessus
	# de la hauteur de marche, donc il porte un corps.
	K.collider_box(self, "Sanctuaire_moignon_couche",
		_seated(-2.40, 2.60) + Vector3(0.0, 0.66, 0.0),
		Vector3(1.60, 1.32, 1.25), 34.0)
	for spec: Array in [[-7.50, -6.50], [8.00, -5.50], [-9.00, -1.00]]:
		K.collider_box(self, "Sanctuaire_tronc_%d" % get_child_count(),
			_seated(float(spec[0]), float(spec[1]))
				+ Vector3(0.0, 2.6, 0.0), Vector3(0.85, 5.2, 0.85))


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)

## COUCHER UNE PIÈCE, ET LA RÉASSEOIR SUR SA VRAIE EMPRISE.
##
## `KitPlacement.seat()` mesure AVANT que l'appelant n'ajoute un roulis ou un
## basculement — il ne peut donc rien pour une pièce qu'on couche ensuite. Et
## le décalage à rattraper n'est pas devinable : mesuré au glTF,
## `cliff_half_rock` a son épaisseur en +Z (bbox z ∈ [0,0815 ; 0,500]) et son
## origine sur une ARÊTE, si bien qu'un basculement de +86° l'envoie
## ENTIÈREMENT sous le sol — 11 cm visibles sur 1,06 m. `SM_Dungeon_PillarStub`
## est centré en X/Z et se comporte autrement, `Wall_UnevenBrick_Straight`
## autrement encore (z ∈ [−0,314 ; +0,092]).
##
## On ne devine donc pas : on bascule, on remesure l'emprise dans le repère du
## parent, et on enfonce de la fraction VOULUE. `enfoncement` est la profondeur
## en mètres sous le sol — zéro pose la pièce exactement dessus.
##
## (Troisième emploi dans ce lot : sa place serait `world_v2_place_kit.gd`
## selon la règle de trois. Il reste ici parce que ce fichier-là est partagé
## par les trois voies du lot et qu'une édition concurrente y coûte une fusion ;
## remonté au lead pour intégration.)
func _coucher(piece: Node3D, deg_x: float, enfoncement: float) -> void:
	if piece == null:
		return
	piece.rotation.x = deg_to_rad(deg_x)
	var boite: AABB = Transform3D(piece.transform.basis, Vector3.ZERO) \
		* KitPlacement.local_aabb(piece)
	piece.position.y -= boite.position.y + enfoncement
