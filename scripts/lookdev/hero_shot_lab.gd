## `HeroShotLab` — micro-scène North Star 80×80 m (bible §29 passe V2,
## P2 §11.1). C'est ici que la recette visuelle se règle AVANT toute
## propagation : héros de dos, pente d'herbe et de fleurs, chemin, rivière
## en S, camp simplifié, pylône, proxy de citadelle, falaises
## d'encadrement, ciel, nuage d'orage local et caméra North Star.
##
## Les éléments lointains sont AUTORÉS EN CONTRAT D'ÉCRAN : `_world_at`
## inverse la projection de `VistaCamera_Hero01` — un anchor placé à
## (63,5 %, 61 %, 90 m) TOMBE à 63,5 %/61 % du cadre, par construction.
## `test_hero_shot_lab.gd` revérifie ces fenêtres par la projection
## directe, indépendamment. Corrections adversariales #3 (rivière en S)
## et #4 (camp dans le cadre, pylône 75-79 % X) intégrées comme contrats.
##
## Environnement : la capture llvmpipe sert la RÉGRESSION visuelle ; le
## score WOW réel attend la machine utilisateur (CLAUDE.md, limites).
class_name HeroShotLab
extends Node3D

## Caméra North Star (bible §3.1) : FOV VERTICAL 44° = 71,4° horizontal
## en 16:9 (KEEP_HEIGHT — entrer 68 en vertical est LE piège nommé §3.1).
const CAM_FOV: float = 44.0
const CAM_PITCH_DEG: float = -2.0
## Position relative aux pieds du héros (origine du lab), décalée pour
## poser le héros à ~41 % X. Lot 7 (AD-005) : la revue a mesuré le
## héros à ~51 % de hauteur visible contre 38-45 % (§1.1) — ce contrat
## d'IMAGE est incompatible avec la distance §3.1 (4,0-4,5 m) à ce FOV.
## Le contrat d'écran prime (c'est lui que la revue juge) : objectif à
## 1,75 m (borne §3.1) et recul à 5,0 m — calcul ET mesure donnent
## tête ~44,7 %, pieds ~89,3 %, hauteur visible ~44,6 % : les trois
## fenêtres §1.1 tenues. Seule la distance dévie, décision consignée.
const CAM_POSITION: Vector3 = Vector3(0.55, 1.75, 5.0)
const HERO_HEIGHT: float = 1.78

const COL_GRASS: Color = Color(0.365, 0.561, 0.239)      # #5D8F3D
const COL_GRASS_LIT: Color = Color(0.698, 0.784, 0.353)  # #B2C85A
## Lot 11 : l'albédo qui REND à l'ancre, mesuré et non deviné. Le sol
## partait de `COL_GRASS` et rendait #5BAC3A (saturation 66 % contre
## 55 % à l'ancre #B2C85A) : la lumière du soleil miel multiplie
## l'albédo et SATURE le vert. On remonte donc la chaîne — albédo ≈
## cible ÷ transfert mesuré — vers un kaki qui, éclairé, tombe sur
## l'herbe au soleil de la bible.
const COL_GRASS_ALBEDO: Color = Color(0.60, 0.60, 0.39)
const COL_EARTH: Color = Color(0.541, 0.353, 0.212)      # terre #8A5A36
const COL_ROCK: Color = Color(0.608, 0.408, 0.259)       # ocre #9B6842
## Passe de VALEURS v3 (§1.5, verdict du test en gris v2) : la rivière
## doit se lire EN GRIS (valeur ~40 %), pas seulement par son cyan.
const COL_WATER: Color = Color(0.13, 0.42, 0.46)         # turquoise sombre
const COL_WATER_BANK: Color = Color(0.30, 0.20, 0.13)    # berge sombre
const COL_CANVAS: Color = Color(0.45, 0.24, 0.17)        # toile sombre (v3)
const COL_STONE_COLD: Color = Color(0.298, 0.357, 0.459) # ombre froide
## Citadelle : masse 35-60 % (§1.5) — plus sombre que les montagnes
## pâles pour que le lointain S'ÉTAGE en valeurs, pas seulement en brume.
const COL_CITADEL: Color = Color(0.16, 0.20, 0.28)
const COL_COPPER: Color = Color(0.43, 0.46, 0.37)        # cuivre patiné
const COL_IVORY: Color = Color(0.847, 0.784, 0.631)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)

## Tracé de la rivière en CONTRAT D'ÉCRAN : (X %, Y %, distance m).
## Deux changements de direction horizontale = le S (correction #3).
## PHYSIQUE (leçons v0/v1) : un plateau à bord franc OCCULTE tout ce qui
## descend derrière lui (seuls les fanions du camp émergeaient de la
## ligne de visée). Le héros se tient donc sur une PENTE CONTINUE de 8°,
## toujours visible, dont la ligne de fuite apparente est à ~63 %
## (pitch −2° : horizon vrai à 54,3 %). Un ruban posé sur cette pente
## vit dans la bande 63-66 % : le S se lit en X (34 → 50 %), la
## profondeur par la convergence et l'amincissement.
## L'amorce entre par le BAS-GAUCHE, devant le héros (leçon v1 : à 40 %
## X elle passait derrière lui), puis le S remonte vers le centre.
const RIVER_SCREEN: Array[Vector3] = [
	# Lot 5 : l'entrée du ruban est PLUS PROCHE et plus basse dans le
	# cadre (§1.1 : « du bas-gauche/milieu vers le centre ») — le guide
	# était timide (défaut nommé aux évals v5 ET v8). Le S survit :
	# l'inflexion 36→31 reste.
	Vector3(36.0, 74.0, 13.0),
	Vector3(31.0, 67.0, 30.0),
	Vector3(34.0, 65.3, 44.0),
	Vector3(40.0, 64.3, 66.0),
	Vector3(48.0, 63.9, 100.0),
	Vector3(50.0, 63.7, 145.0),
	Vector3(49.0, 63.5, 205.0),
]
## Pente continue du premier plan : 8° (tan ≈ 0,1405).
const SLOPE_TAN: float = 0.1405
## Lot 2 : LE shader du style (décision verrouillée n°2) — validé sur
## trois PILOTES (rocher, touffe, héros) avant toute propagation.
const PAINTERLY: Shader = \
	preload("res://shaders/characters/SH_CharacterPainterly.gdshader")
## Déclinaison feuillage : mêmes ramps peintes + VENT au vertex — le
## dolly de stabilité a prouvé (diffs 0,00 en phase immobile) que
## l'herbe du lab était figée, contre §11.1.
const FOLIAGE_PAINTERLY: Shader = \
	preload("res://shaders/foliage/SH_FoliageWindPainterly.gdshader")
## Variante DÉCOUPE : cartes de feuilles — transparence respectée par
## seuil, faces des deux côtés (la peinture opaque dessinait des
## contours sombres sur les bords transparents, interdits §1.6).
const PAINTERLY_CUTOUT: Shader = \
	preload("res://shaders/characters/SH_CharacterPainterlyCutout.gdshader")

var _anchors: Dictionary[StringName, Node3D] = {}
var _river_local: Array[Vector3] = []
var _grass_cells: int = 0


func _ready() -> void:
	_build_camera()
	_build_hero()
	_build_terrain()
	_build_river()
	_build_camp()
	_build_pylon()
	_build_citadel_proxy()
	_build_storm()
	_build_dressing()
	_build_riverside()
	_build_light()


## Inverse de la projection de la caméra North Star : un point d'écran
## (X %, Y % — origine haut-gauche) à `distance` mètres devient un point
## LOCAL du lab. Autorer ici = tomber dans la fenêtre, par construction.
func _world_at(x_pct: float, y_pct: float, distance: float) -> Vector3:
	var tan_v: float = tan(deg_to_rad(CAM_FOV) * 0.5)
	var tan_h: float = tan_v * 16.0 / 9.0
	var x_ndc: float = (x_pct / 100.0 - 0.5) * 2.0
	var y_ndc: float = (0.5 - y_pct / 100.0) * 2.0
	var local: Vector3 = Vector3(x_ndc * tan_h * distance,
		y_ndc * tan_v * distance, -distance)
	var rot: Basis = Basis(Vector3.RIGHT, deg_to_rad(CAM_PITCH_DEG))
	return CAM_POSITION + rot * local


func anchor(anchor_name: StringName) -> Node3D:
	return _anchors.get(anchor_name, null)


func vista_camera() -> Camera3D:
	return get_node_or_null("VistaCamera_Hero01") as Camera3D


func river_points() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for local: Vector3 in _river_local:
		points.append(to_global(local))
	return points


func grass_cell_count() -> int:
	return _grass_cells


## État de capture (`--call=capture_north_star`, outil §21.5) : active la
## caméra North Star et TIENT l'éclair majeur (§3.2 : « un éclair majeur
## simultané dans la vue d'ouverture » — `hold_flash` est fait pour ça,
## le jeu garde sa cadence irrégulière).
func capture_north_star() -> void:
	var camera: Camera3D = vista_camera()
	if camera != null:
		camera.current = true
	var storm: StormCell = get_node_or_null("Storm") as StormCell
	if storm != null:
		storm.hold_flash()


func _mark(anchor_name: StringName, at: Vector3) -> Node3D:
	var marker: Marker3D = Marker3D.new()
	marker.name = String(anchor_name).to_pascal_case()
	marker.position = at
	add_child(marker)
	_anchors[anchor_name] = marker
	return marker


func _build_camera() -> void:
	var camera: Camera3D = Camera3D.new()
	camera.name = "VistaCamera_Hero01"
	camera.position = CAM_POSITION
	camera.rotation_degrees = Vector3(CAM_PITCH_DEG, 0.0, 0.0)
	camera.fov = CAM_FOV
	camera.current = false
	add_child(camera)


func _build_hero() -> void:
	_mark(&"hero_feet", Vector3.ZERO)
	_mark(&"hero_head", Vector3(0.0, HERO_HEIGHT, 0.0))
	# Le hero asset de la Phase H, DE DOS (il regarde la vallée, -Z).
	var scene: PackedScene = load(
		"res://assets/characters/hero/Male_Ranger.gltf") as PackedScene
	if scene != null:
		var hero: Node3D = scene.instantiate() as Node3D
		hero.name = "Hero"
		hero.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		add_child(hero)
		# Le glTF n'embarque AUCUNE animation (sondé) : sortir de la
		# T-pose se fait à l'os — bras posés le long du corps.
		var skeleton: Skeleton3D = null
		for node: Node in hero.find_children("*", "Skeleton3D", true, false):
			skeleton = node as Skeleton3D
		if skeleton != null:
			_lower_arm(skeleton, "upperarm_l", -70.0)
			_lower_arm(skeleton, "upperarm_r", 70.0)
			# Doigts : repli léger des phalanges — la main de bind pose
			# aux doigts écartés trahissait le mannequin (leçon v4).
			for side: String in ["l", "r"]:
				for finger: String in ["index", "middle", "ring", "pinky"]:
					for joint: int in [1, 2, 3]:
						_lower_arm(skeleton, "%s_0%d_%s"
							% [finger, joint, side], 22.0)
			# Passe V3 : les cinq signes de dos (§13.1) — mantelet,
			# épaulière, Bracelet, arc, carquois.
			HeroSigns.attach(skeleton, hero)
			# Lot 2 : le héros ENTIER porte le painterly — en gardant sa
			# texture (le shader grade la lumière, il n'efface pas la peau).
			_apply_painterly_to_hero(hero)
	else:
		var proxy: MeshInstance3D = MeshInstance3D.new()
		proxy.name = "Hero"
		var capsule: CapsuleMesh = CapsuleMesh.new()
		capsule.height = HERO_HEIGHT
		capsule.radius = 0.3
		proxy.mesh = capsule
		proxy.position = Vector3(0.0, HERO_HEIGHT * 0.5, 0.0)
		add_child(proxy)


## Lot 9 — habillage avec les VRAIS modèles du dépôt (Quaternius CC0,
## déjà attribués ; AD-001 : aucun téléchargement). Placement
## composition-conscient : les arbres encadrent (bandes gauche < 36 % X
## et bord droit > 81 %), les rochers ponctuent le premier plan hors
## focales, les props vivent AU camp. Chaque modèle passe à la peinture
## en gardant sa vraie texture, et varie pose/échelle (§7.3).
## Lot 12 — la falaise gauche GUIDE au lieu de boucher (défaut nommé
## depuis l'éval v5). Vrais modules Kenney CC0 (ART-K1) montés en
## ESCALIER descendant vers la vallée : chaque palier est plus bas et
## plus loin que le précédent, ses arêtes éclairées menant l'œil du
## premier plan vers le camp. Échelle « tuile » corrigée par le point
## unique du projet (`KitScale`), jamais recopiée ici.
func _build_cliff_formation() -> void:
	var formation: Node3D = Node3D.new()
	formation.name = "CliffFormation"
	add_child(formation)
	# [modèle, x, z, yaw°, variation d'échelle]
	# Les modules vivent DEVANT la dalle-masse (x > -24) : posés
	# derrière, ils étaient purement et simplement occultés (capture
	# v19). Ils descendent vers la vallée en s'éloignant.
	var steps: Array[Array] = [
		["cliff_cornerLarge_rock", -19.5, -22.0, 18.0, 1.15],
		["cliff_large_rock", -21.0, -35.0, 8.0, 1.0],
		["cliff_blockSlope_rock", -22.5, -47.0, -6.0, 0.95],
		["cliff_half_rock", -24.0, -59.0, 22.0, 1.1],
		["cliff_corner_rock", -26.0, -75.0, 40.0, 0.85],
		["rock_largeC", -24.0, -24.0, 130.0, 1.2],
		["rock_largeA", -21.0, -17.0, 300.0, 1.0],
		["rock_smallB", -18.5, -13.0, 70.0, 1.0],
	]
	for step: Array in steps:
		var asset: String = step[0] as String
		var scene: PackedScene = load(
			"res://assets/environment/cliffs/%s.glb" % asset) as PackedScene
		if scene == null:
			push_warning("[falaise] modèle introuvable : %s" % asset)
			continue
		var model: Node3D = scene.instantiate() as Node3D
		model.name = asset.to_pascal_case()
		var z: float = step[2] as float
		model.position = Vector3(step[1] as float, _slope_height(z) - 0.6, z)
		model.rotation_degrees.y = step[3] as float
		model.scale = Vector3.ONE * KitScale.factor(asset) \
			* (step[4] as float)
		formation.add_child(model)
		_apply_painterly_to_model(model)
		# La roche du kit reçoit la surface stratifiée (AD-006 : la
		# couleur reste subordonnée, le relief monte).
		for node: Node in model.find_children("*", "MeshInstance3D",
				true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			if mesh.mesh == null:
				continue
			for s: int in range(mesh.mesh.get_surface_count()):
				var material: ShaderMaterial = \
					mesh.get_surface_override_material(s) as ShaderMaterial
				if material != null:
					# La palette du kit est un gris pâle et FROID : posé
					# tel quel, le module ne parlait pas la même géologie
					# que la falaise ocre voisine (capture v19). On le
					# teinte à l'ancre roche §1.4 — le modèle garde sa
					# forme et son relief, il rejoint notre monde.
					material.set_shader_parameter("albedo_color",
						COL_ROCK.lerp(Color(0.34, 0.24, 0.17), 0.35))
					_with_surface(material, "T_Rock_Strata", 3.5, 0.70, 1.0)


## Lot 13 — la RIVE vit : saules penchés vers l'eau, souche et tronc
## moussus, rochers de berge, buisson à baies (Quaternius CC0, ART-Q9).
## Le kit arrive en OBJ, qui s'importe en **Mesh** et non en scène :
## le chargeur monte donc lui-même le `MeshInstance3D`. Les positions
## suivent le tracé RÉEL de la rivière — une rive plantée au hasard
## n'est qu'une rangée d'arbres.
func _build_riverside() -> void:
	var riverside: Node3D = Node3D.new()
	riverside.name = "Riverside"
	add_child(riverside)
	if _river_local.is_empty():
		return
	# [modèle, index du point de rivière, décalage latéral, recul, yaw°]
	var plantings: Array[Array] = [
		["Willow_1", 1, -7.5, 2.0, 25.0],
		["Willow_3", 2, 8.0, -1.0, 200.0],
		["Willow_5", 4, -9.5, 3.0, 110.0],
		["TreeStump_Moss", 1, 5.0, 3.5, 60.0],
		["WoodLog_Moss", 2, -4.5, -2.5, 145.0],
		["Rock_Moss_2", 0, -3.5, 1.5, 20.0],   # gardé hors du couloir du camp
		["Rock_Moss_5", 3, -5.5, 0.0, 250.0],
		["BushBerries_1", 0, -6.0, 2.5, 300.0],
	]
	for planting: Array in plantings:
		var asset: String = planting[0] as String
		var mesh_resource: Mesh = load(
			"res://assets/environment/riverside/%s.obj" % asset) as Mesh
		if mesh_resource == null:
			push_warning("[rive] modèle introuvable : %s" % asset)
			continue
		var holder: Node3D = Node3D.new()
		holder.name = asset
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.name = "%sMesh" % asset
		instance.mesh = mesh_resource
		holder.add_child(instance)
		var anchor_point: Vector3 = _river_local[
			mini(planting[1] as int, _river_local.size() - 1)]
		var x: float = anchor_point.x + (planting[2] as float)
		var z: float = anchor_point.z + (planting[3] as float)
		holder.position = Vector3(x, minf(_slope_height(z), 0.0), z)
		holder.rotation_degrees.y = planting[4] as float
		holder.scale = Vector3.ONE * KitScale.factor(asset)
		riverside.add_child(holder)
		_apply_painterly_to_model(holder)
		# Écorce et pierre reçoivent leur matière ; le feuillage garde
		# la peinture seule (une écorce projetée sur des feuilles ne
		# veut rien dire).
		var family: String = "T_Bark_Tree" if asset.contains("Willow") \
			or asset.contains("Wood") or asset.contains("Stump") \
			else "T_Rock_Mossy"
		for node: Node in holder.find_children("*", "MeshInstance3D",
				true, false):
			var mesh_node: MeshInstance3D = node as MeshInstance3D
			if mesh_node.mesh == null:
				continue
			for s: int in range(mesh_node.mesh.get_surface_count()):
				var material: ShaderMaterial = \
					mesh_node.get_surface_override_material(s) \
					as ShaderMaterial
				if material == null:
					continue
				# Le feuillage garde la peinture SEULE : projeter une
				# écorce sur des feuilles ne veut rien dire.
				var is_foliage: bool = mesh_node.mesh \
					.surface_get_material(s) != null \
					and String(mesh_node.mesh.surface_get_material(s)
						.resource_name).to_lower().contains("green")
				if not is_foliage:
					_with_surface(material, family, 2.4, 0.55, 0.9)


func _build_dressing() -> void:
	var dressing: Node3D = Node3D.new()
	dressing.name = "Dressing"
	add_child(dressing)
	var camp: Vector3 = _anchors[&"camp_center"].position
	var f: String = "res://assets/environment/foliage/"
	var r: String = "res://assets/environment/rocks/"
	var p: String = "res://assets/environment/props/"
	# [chemin, nom, x, z, yaw°, échelle] — y suit la pente continue.
	var items: Array[Array] = [
		[f + "CommonTree_1.gltf", "TreeCommon1", -14.0, -48.0, 25.0, 1.0],
		[f + "CommonTree_3.gltf", "TreeCommon3", -19.0, -62.0, 130.0, 1.15],
		[f + "Pine_2.gltf", "TreePine2", -24.0, -78.0, 75.0, 1.05],
		[f + "TwistedTree_2.gltf", "TreeTwisted2", 26.0, -35.0, 210.0, 0.95],
		[f + "Pine_4.gltf", "TreePine4", 31.0, -58.0, 300.0, 1.2],
		[r + "Rock_Medium_1.gltf", "RockNearL", -8.0, -14.0, 40.0, 1.3],
		[r + "Rock_Medium_2.gltf", "RockNearL2", -4.0, -10.0, 155.0, 0.85],
		[r + "Rock_Medium_3.gltf", "RockPathR", 15.0, -28.0, 250.0, 1.0],
		[r + "Rock_Medium_1.gltf", "RockCliffBase", -27.0, -44.0, 310.0, 1.6],
		[p + "Banner_1.gltf", "CampBanner", camp.x - 2.0, camp.z + 2.0,
			160.0, 1.0],
		[p + "Crate_Wooden.gltf", "CampCrate", camp.x - 4.5, camp.z - 1.5,
			35.0, 1.0],
		[p + "Barrel.gltf", "CampBarrel", camp.x - 3.0, camp.z + 1.0,
			80.0, 1.0],
		[p + "Cauldron.gltf", "CampCauldron", camp.x - 4.0, camp.z + 3.0,
			10.0, 1.0],
	]
	for item: Array in items:
		var scene: PackedScene = load(item[0] as String) as PackedScene
		if scene == null:
			push_warning("[dressing] modèle introuvable : %s" % item[0])
			continue
		var model: Node3D = scene.instantiate() as Node3D
		model.name = item[1] as String
		var x: float = item[2] as float
		var z: float = item[3] as float
		var asset: String = (item[0] as String).get_file().get_basename()
		var factor: float = (item[5] as float) * KitScale.factor(asset)
		model.position = Vector3(x, minf(_slope_height(z), 0.0), z)
		model.rotation_degrees.y = item[4] as float
		model.scale = Vector3.ONE * factor
		dressing.add_child(model)
		_apply_painterly_to_model(model)
		# Cohérence de géologie : les rochers du kit sont gris-BLEU
		# froids, la falaise voisine est ocre — côte à côte, ils
		# racontaient deux mondes. On les ramène à l'ancre roche §1.4
		# (leur forme et leur relief ne changent pas).
		if (item[1] as String).contains("Rock"):
			for node: Node in model.find_children("*", "MeshInstance3D",
					true, false):
				var rock_mesh: MeshInstance3D = node as MeshInstance3D
				if rock_mesh.mesh == null:
					continue
				for s: int in range(rock_mesh.mesh.get_surface_count()):
					var rock_material: ShaderMaterial = \
						rock_mesh.get_surface_override_material(s) \
						as ShaderMaterial
					if rock_material == null:
						continue
					# Teinte CLAIRE : la texture du kit porte déjà sa
					# valeur sombre — une teinte foncée la doublait et
					# les rochers devenaient des trous noirs (v20).
					rock_material.set_shader_parameter("albedo_color",
						Color(1.85, 1.52, 1.16))
					_with_surface(rock_material, "T_Rock_Mossy", 2.2,
						0.70, 1.0)


## Passe TOUTES les surfaces d'un modèle au painterly, en extrayant la
## vraie texture d'albedo de chaque surface (même règle que le héros —
## la revue a prouvé qu'oublier une surface laisse deux langages de
## lumière cohabiter).
func _apply_painterly_to_model(model: Node3D) -> void:
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null:
			continue
		for s: int in range(mesh.mesh.get_surface_count()):
			var texture: Texture2D = null
			var cutout: bool = false
			# Sans texture, la COULEUR du matériau source est la seule
			# information de teinte qui existe : la jeter peignait les
			# saules OBJ en BLANC (capture v22 — des sculptures de
			# glace au bord de l'eau). On la reprend, et on la
			# REMONTE : la peinture module ensuite, elle n'éclaire pas.
			var tint: Color = Color.WHITE
			var active: StandardMaterial3D = \
				mesh.get_active_material(s) as StandardMaterial3D
			if active != null:
				texture = active.albedo_texture
				cutout = active.transparency \
					!= BaseMaterial3D.TRANSPARENCY_DISABLED \
					or active.cull_mode == BaseMaterial3D.CULL_DISABLED
				if texture == null:
					var source: Color = active.albedo_color
					# Les .mtl de ce kit sont très sombres (feuillage à
					# 0,07 de vert) : posés tels quels sous le soleil,
					# ils rendaient noir. On remonte la valeur en
					# gardant la TEINTE.
					var peak: float = maxf(source.r,
						maxf(source.g, source.b))
					if peak > 0.001:
						tint = source * (0.62 / peak)
						tint.a = 1.0
						# …puis un pas vers la palette : le vert franc
						# du kit ne parlait pas la même langue que
						# l'olive de la vallée (§1.4).
						if tint.g > tint.r and tint.g > tint.b:
							tint = tint.lerp(COL_GRASS_LIT * 0.7, 0.35)
							tint.a = 1.0
			var material: ShaderMaterial = \
				_painterly_material(tint, 0.85, texture)
			if cutout:
				material.shader = PAINTERLY_CUTOUT
			mesh.set_surface_override_material(s, material)


func _apply_painterly_to_hero(hero: Node3D) -> void:
	for node: Node in hero.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		# Les signes graybox gardent leur matière simple pour l'instant.
		if mesh.get_parent() is BoneAttachment3D \
				or mesh.get_parent().get_parent() is BoneAttachment3D:
			continue
		if mesh.mesh == null:
			continue
		# Revue contradictoire : TOUTES les surfaces — la peau des bras
		# (surface 1 de Male_Ranger_Arms) restait en PBR standard.
		for s: int in range(mesh.mesh.get_surface_count()):
			var texture: Texture2D = null
			var active: StandardMaterial3D = \
				mesh.get_active_material(s) as StandardMaterial3D
			if active != null:
				texture = active.albedo_texture
			mesh.set_surface_override_material(s,
				_painterly_material(Color.WHITE, 0.82, texture))


func _lower_arm(skeleton: Skeleton3D, bone: String, degrees: float) -> void:
	var index: int = skeleton.find_bone(bone)
	if index < 0:
		return
	var rest: Quaternion = skeleton.get_bone_rest(index).basis \
		.get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(index,
		rest * Quaternion(Vector3(0, 0, 1), deg_to_rad(degrees)))


## Matériau painterly : fondu ADOUCI explicite (le contrat du test le
## vérifie — toon dur interdit) ; texture optionnelle (le héros garde
## la sienne, un blanc 1×1 sinon — équivalent du hint_default_white).
## Lot 10 — grain PROCÉDURAL partagé : généré par le moteur
## (`FastNoiseLite`, AD-001 : aucune image téléchargée), donc
## reproductible depuis le dépôt sans poids binaire ni licence. Une
## seule ressource pour tout le lab : le grain doit UNIFIER la matière,
## pas donner un motif différent à chaque objet.
static var _grain: NoiseTexture2D = null


static func grain_texture() -> NoiseTexture2D:
	if _grain != null:
		return _grain
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	# §21.1 : GRANDES formes, jamais du microbruit qui scintille.
	noise.frequency = 0.012
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.42
	noise.seed = 20260806
	_grain = NoiseTexture2D.new()
	_grain.noise = noise
	_grain.width = 512
	_grain.height = 512
	# Sans raccord, la projection monde montrerait la couture du tuilage.
	_grain.seamless = true
	_grain.generate_mipmaps = true
	return _grain


func _painterly_material(colour: Color, rough: float,
		texture: Texture2D = null) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = PAINTERLY
	material.set_shader_parameter("albedo_color", colour)
	material.set_shader_parameter("roughness_value", rough)
	material.set_shader_parameter("ramp_soft", 0.16)
	material.set_shader_parameter("grain_texture", grain_texture())
	material.set_shader_parameter("grain_strength", 0.12)
	material.set_shader_parameter("grain_scale", 0.35)
	material.set_shader_parameter("grain_roughness", 0.18)
	if texture == null:
		var image: Image = Image.create(1, 1, false, Image.FORMAT_RGB8)
		image.fill(Color.WHITE)
		texture = ImageTexture.create_from_image(image)
	material.set_shader_parameter("albedo_texture", texture)
	return material


## Lot 11 — applique une SURFACE réelle (ambientCG CC0, ART-T1) à un
## matériau painterly. `tile_m` est la taille d'une tuile en MÈTRES :
## une roche se lit à 3-4 m, un sol à 5-6 m, une toile à 1 m. La force
## reste modérée — la bible interdit la texture photographique brute
## (§1.6) : on prend le relief et le modelé, pas la couleur.
func _with_surface(material: ShaderMaterial, family: String,
		tile_m: float, blend: float = 0.45,
		relief: float = 1.0) -> ShaderMaterial:
	var base: String = "res://assets/textures/surfaces/%s_" % family
	material.set_shader_parameter("surface_texture",
		load(base + "Albedo.jpg"))
	material.set_shader_parameter("surface_normal",
		load(base + "Normal.jpg"))
	material.set_shader_parameter("surface_rough",
		load(base + "Rough.jpg"))
	material.set_shader_parameter("surface_tile_m", tile_m)
	material.set_shader_parameter("surface_blend", blend)
	# AD-006 : la COULEUR photo reste subordonnée à la palette peinte,
	# le RELIEF monte franchement — une normal map est de la forme, pas
	# une couleur photographique, et c'est la forme qui nourrit la
	# lumière peinte (décision verrouillée n°2).
	material.set_shader_parameter("surface_normal_depth", relief)
	return material


func _foliage_material(colour: Color, blade_height: float = 0.55,
		sway_amplitude: float = 0.07) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = FOLIAGE_PAINTERLY
	material.set_shader_parameter("albedo_color", colour)
	material.set_shader_parameter("ramp_soft", 0.16)
	material.set_shader_parameter("blade_height", blade_height)
	material.set_shader_parameter("sway_amplitude", sway_amplitude)
	return material


## Lot 4 : la matière PAR DÉFAUT du lab est la peinture — toute surface
## mate passe par ici. Les émissifs justifiés (rivière-guide, flamme,
## couronne cyan) passent par `_emissive_material`.
func _material(colour: Color, rough: float = 0.9) -> ShaderMaterial:
	return _painterly_material(colour, rough)


func _emissive_material(colour: Color, rough: float,
		emission_colour: Color, energy: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = rough
	material.emission_enabled = true
	material.emission = emission_colour
	material.emission_energy_multiplier = energy
	return material


func _slab(slab_name: String, centre: Vector3, size: Vector3,
		colour: Color) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = slab_name
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(colour)
	mesh.position = centre
	add_child(mesh)


## Hauteur de la pente continue en un z donné (surface passant par les
## pieds du héros à l'origine, descendant vers −z).
func _slope_height(z: float) -> float:
	return z * SLOPE_TAN


func _build_terrain() -> void:
	# UNE pente continue de 8° (leçon v1 : un bord de plateau occulte la
	# vallée entière depuis une caméra presque horizontale). Le héros se
	# tient dessus à l'origine ; la surface passe par (0, 0).
	var slope: MeshInstance3D = MeshInstance3D.new()
	slope.name = "ValleySlope"
	var slope_box: BoxMesh = BoxMesh.new()
	slope_box.size = Vector3(130, 2, 168)
	slope.mesh = slope_box
	# La prairie ÉCLAIRÉE doit tendre vers l'ancre #B2C85A (§1.4), pas
	# vers un vert pur : mesuré à #5BAC3A (saturation 66 % contre 55 %
	# à l'ancre), le sol partait trop vert. La base monte donc vers
	# l'herbe au soleil ; la peinture garde le creux dans l'ombre.
	slope.material_override = _with_surface(
		_material(COL_GRASS_ALBEDO), "T_Grass_Field", 6.0, 0.65, 0.85)
	slope.position = Vector3(4, _slope_height(-68.0) - 1.0, -68)
	slope.rotation_degrees = Vector3(-8.0, 0, 0)
	add_child(slope)
	# Fond de vallée PLAT (~−21 m) : la pente s'y adoucit, la queue de la
	# rivière et le socle de la citadelle s'y posent.
	# Le sol LOINTAIN part du même kaki que la pente (sinon une coupure
	# nette séparait premier plan et fond), mais REFROIDI et assombri :
	# §1.3 exige que le lointain recule en contraste et en saturation.
	# Mesuré : à albédo identique, il rendait une bande jaune vif qui
	# tirait l'œil hors de la citadelle.
	_slab("ValleyFloor", Vector3(4, -22.0, -245), Vector3(240, 2, 210),
		COL_GRASS_ALBEDO.lerp(COL_STONE_COLD, 0.42))
	# Chemin de terre : il ÉPOUSE la pente (leçon v1).
	var path: MeshInstance3D = MeshInstance3D.new()
	path.name = "PathCrest"
	var path_box: BoxMesh = BoxMesh.new()
	path_box.size = Vector3(1.6, 0.06, 34)
	path.mesh = path_box
	# ISS-037 : `COL_EARTH` (#8A5A36) est une couleur PEINTE CIBLE, pas un
	# albédo. Le gain lumineux du labo vaut ≈ 1,8 (mesuré : un albédo bleu pur
	# ressort à B=255), donc un rouge d'albédo de 0,541 rendait 0,97 — le
	# chemin devenait l'objet le plus clair ET le plus saturé de l'image, et
	# tirait le regard hors de la citadelle, contre §1.2.
	# §1.5 veut « sol et roche moyens » entre 35 et 65 % de valeur : on vise
	# le milieu de bande, soit 0,55 / 1,8 ≈ 0,31 de rouge d'albédo.
	# Même leçon qu'aux rochers ligne ~425, dans l'autre sens.
	path.material_override = _with_surface(
		_material(COL_EARTH * 0.57), "T_Ground_Earth", 5.0, 0.78, 1.0)
	path.position = Vector3(2.2, _slope_height(-9.0) + 0.05, -9)
	path.rotation_degrees = Vector3(-8.0, 0, 0)
	add_child(path)
	# Falaises d'encadrement (§1.1), enracinées dans la pente — strates
	# décalées, tons rabattus (le mur plat orange est un échec nommé v0).
	# v3 : premier plan plus SOMBRE et chaud, lointain plus froid — c'est
	# l'étagement §1.3 en VALEURS (le gris v2 montrait tout fusionné).
	_slab("CliffLeftNear", Vector3(-26, _slope_height(-30.0) + 5.0, -30),
		Vector3(14, 10, 40), COL_ROCK.lerp(Color(0.30, 0.19, 0.12), 0.45))
	# Lot 2 : le ROCHER pilote passe au painterly.
	(get_node("CliffLeftNear") as MeshInstance3D).material_override = \
		_with_surface(_painterly_material(
			COL_ROCK.lerp(Color(0.30, 0.19, 0.12), 0.45), 0.88),
			"T_Rock_Strata", 4.0, 0.78, 1.0)
	_slab("CliffLeftLip", Vector3(-22.5, _slope_height(-34.0) + 10.6, -34),
		Vector3(9, 3.2, 34), COL_ROCK.lerp(COL_GRASS, 0.3))
	# Lot 8 (revue) : la falaise gauche BOUCHAIT sans guider — deux
	# strates intermédiaires descendent en escalier vers la vallée,
	# tournées vers le chemin (§6.1 : la descente CADRE le camp puis le
	# pylône ; leurs arêtes éclairées font la ligne du regard).
	_slab("CliffStepA", Vector3(-29, _slope_height(-52.0) + 7.5, -52),
		Vector3(16, 12, 26), COL_ROCK.lerp(COL_STONE_COLD, 0.15))
	var step_a: MeshInstance3D = get_node("CliffStepA") as MeshInstance3D
	step_a.rotation_degrees.y = 12.0
	_with_surface(step_a.material_override as ShaderMaterial,
		"T_Rock_Mossy", 4.5, 0.70, 1.0)
	_build_cliff_formation()
	_slab("CliffStepB", Vector3(-33, _slope_height(-72.0) + 6.5, -72),
		Vector3(18, 14, 30), COL_ROCK.lerp(COL_STONE_COLD, 0.25))
	var step_b: MeshInstance3D = get_node("CliffStepB") as MeshInstance3D
	step_b.rotation_degrees.y = 7.0
	_with_surface(step_b.material_override as ShaderMaterial,
		"T_Rock_Mossy", 5.0, 0.62, 0.9)
	_slab("CliffLeftFar", Vector3(-36, _slope_height(-95.0) + 6.0, -95),
		Vector3(20, 16, 70), COL_ROCK.lerp(COL_STONE_COLD, 0.35))
	# Décalée à droite (leçon v0 : à x 46 elle avalait le pylône).
	_slab("CliffRightFar", Vector3(62, _slope_height(-120.0) + 4.0, -120),
		Vector3(18, 13, 50), COL_ROCK.lerp(COL_STONE_COLD, 0.3))
	_build_mountains()
	_grass_foreground()


## Horizon montagneux (§1.1 : Y 24-43 %, contraste faible ; §3.3 :
## montagnes non jouables à 550-1 200 m). Il remplit aussi la bande
## 40-54 % : la part de ciel redescend vers les 38-48 % demandés —
## l'arbitrage v2 se fait par le DÉCOR, pas en cassant le cadrage héros.
func _build_mountains() -> void:
	var mountains: Array[Array] = [
		["MesaA", Vector3(-210, 12, -560), Vector3(200, 68, 60)],
		["MesaB", Vector3(-60, 20, -640), Vector3(180, 88, 70)],
		["MesaC", Vector3(120, 8, -600), Vector3(160, 62, 60)],
		["MesaD", Vector3(280, 16, -680), Vector3(220, 76, 70)],
		["MesaE", Vector3(30, 30, -760), Vector3(260, 104, 80)],
	]
	var pale: Color = COL_STONE_COLD.lerp(Color(0.70, 0.77, 0.84), 0.75)
	for mesa: Array in mountains:
		_slab(mesa[0] as String, mesa[1] as Vector3, mesa[2] as Vector3,
			pale)


## L'herbe du premier plan : cellules MultiMesh (§26.3 — jamais une seule
## nappe), organisées en « PHRASES » (§7.4) : grande touffe + moyennes +
## fleurs + VIDE, répétition irrégulière — un scatter uniforme est un
## échec nommé, même dense (leçon v1).
func _grass_foreground() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260805
	var blade: ArrayMesh = _blade_mesh()
	for cell_x: int in range(-2, 2):
		for cell_z: int in range(2):
			var origin: Vector3 = Vector3(float(cell_x) * 10.0 + 5.0, 0.0,
				-float(cell_z) * 10.0 - 2.0)
			# 5-7 touffes par cellule, tailles inégales — et le reste en
			# vide : la respiration fait la phrase.
			var clumps: Array[Vector3] = []
			var clump_scale: Array[float] = []
			for c: int in range(rng.randi_range(5, 7)):
				clumps.append(origin + Vector3(rng.randf_range(-4.2, 4.2),
					0.0, rng.randf_range(-4.2, 4.2)))
				clump_scale.append(rng.randf_range(0.8, 1.6))
			var cell: MultiMeshInstance3D = MultiMeshInstance3D.new()
			cell.name = "Grass_%d_%d" % [cell_x + 2, cell_z]
			var multimesh: MultiMesh = MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = blade
			multimesh.instance_count = 240
			for i: int in range(multimesh.instance_count):
				var pick: int = rng.randi_range(0, clumps.size() - 1)
				# Densité qui retombe du cœur vers le bord de la touffe.
				var radius: float = rng.randf_range(0.0, 2.4) * rng.randf()
				var angle: float = rng.randf_range(0.0, TAU)
				var spot: Vector3 = clumps[pick] + Vector3(
					cos(angle) * radius, 0.0, sin(angle) * radius)
				spot.y = minf(_slope_height(spot.z), 0.0)
				var closeness: float = 1.0 - radius / 2.4
				var basis: Basis = Basis(Vector3.UP,
					rng.randf_range(0.0, TAU))
				basis = basis.scaled(Vector3.ONE * clump_scale[pick]
					* rng.randf_range(0.55, 0.85 + 0.7 * closeness))
				multimesh.set_instance_transform(i,
					Transform3D(basis, spot))
			cell.multimesh = multimesh
			var tint: Color = COL_GRASS.lerp(COL_GRASS_LIT,
				rng.randf_range(0.2, 0.6))
			# Lot 3 : TOUTES les cellules au feuillage painterly VENTÉ
			# (le dolly a prouvé l'herbe figée — §11.1 exige le vent).
			cell.material_override = _foliage_material(tint)
			add_child(cell)
			_grass_cells += 1
			_flower_patch(rng, cell_x, cell_z, clumps)


## Fleurs en groupes AU BORD des touffes (§7.1 : blanches/jaunes, bleues
## rares), jamais un semis uniforme.
func _flower_patch(rng: RandomNumberGenerator, cell_x: int, cell_z: int,
		clumps: Array[Vector3]) -> void:
	var palette: Array[Color] = [Color(0.94, 0.89, 0.75),
		Color(1.0, 0.84, 0.54), Color(0.42, 0.51, 0.72)]
	var weights: Array[int] = [0, 0, 0, 1, 1, 2]   # le bleu reste rare
	var flowers: MultiMeshInstance3D = MultiMeshInstance3D.new()
	flowers.name = "Flowers_%d_%d" % [cell_x + 2, cell_z]
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var head: BoxMesh = BoxMesh.new()
	head.size = Vector3(0.09, 0.09, 0.09)
	multimesh.mesh = head
	multimesh.instance_count = 14
	for i: int in range(multimesh.instance_count):
		var clump: Vector3 = clumps[rng.randi_range(0, clumps.size() - 1)]
		var angle: float = rng.randf_range(0.0, TAU)
		var radius: float = rng.randf_range(1.6, 2.8)
		var spot: Vector3 = clump + Vector3(cos(angle) * radius, 0.0,
			sin(angle) * radius)
		spot.y = minf(_slope_height(spot.z), 0.0) \
			+ rng.randf_range(0.18, 0.4)
		multimesh.set_instance_transform(i,
			Transform3D(Basis.IDENTITY, spot))
	flowers.multimesh = multimesh
	# Revue : les fleurs restaient FIGÉES — même vent que l'herbe, en
	# flottement léger (têtes de 9 cm, demi-amplitude).
	flowers.material_override = _foliage_material(
		palette[weights[rng.randi_range(0, weights.size() - 1)]],
		0.09, 0.04)
	add_child(flowers)


func _blade_mesh() -> ArrayMesh:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.add_vertex(Vector3(-0.03, 0.0, 0.0))
	surface.add_vertex(Vector3(0.03, 0.0, 0.0))
	surface.add_vertex(Vector3(0.0, 0.55, 0.04))
	surface.generate_normals()
	return surface.commit()


## Correction #3 : le ruban turquoise en S, autoré en contrat d'écran.
func _build_river() -> void:
	_river_local.clear()
	for spec: Vector3 in RIVER_SCREEN:
		_river_local.append(_world_at(spec.x, spec.y, spec.z))
	var river: Node3D = Node3D.new()
	river.name = "River"
	add_child(river)
	for i: int in range(_river_local.size() - 1):
		var from_point: Vector3 = _river_local[i]
		var to_point: Vector3 = _river_local[i + 1]
		var segment: MeshInstance3D = MeshInstance3D.new()
		segment.name = "Segment%d" % i
		var box: BoxMesh = BoxMesh.new()
		var length: float = from_point.distance_to(to_point)
		# Large et légèrement SURÉLEVÉ (leçon v1 : un ruban affleurant
		# disparaît sous les brins d'herbe et le bord de pente).
		# Lot 5 : base élargie — le ruban-guide doit se lire (§1.1).
		box.size = Vector3(5.5 + float(i) * 1.9, 0.3, length + 3.0)
		segment.mesh = box
		# Revue : une émission à 0,35 « se cachait » dans l'exception sans
		# émettre vraiment — le ruban-guide assume désormais sa lumière.
		segment.material_override = _emissive_material(COL_WATER, 0.25,
			COL_WATER, 1.2)
		segment.position = (from_point + to_point) * 0.5 \
			+ Vector3(0.0, 0.3, 0.0)
		var flat: Vector3 = to_point - from_point
		segment.rotation.y = atan2(-flat.x, -flat.z)
		river.add_child(segment)
		# Berge sombre sous le lit (v3, §1.5) : le ruban se lit EN GRIS
		# par le contraste berge/eau, pas seulement par le cyan.
		var bank: MeshInstance3D = MeshInstance3D.new()
		bank.name = "Bank%d" % i
		var bank_box: BoxMesh = BoxMesh.new()
		bank_box.size = Vector3(box.size.x + 2.2, 0.22, box.size.z + 2.0)
		bank.mesh = bank_box
		bank.material_override = _material(COL_WATER_BANK)
		bank.position = segment.position - Vector3(0.0, 0.18, 0.0)
		bank.rotation.y = segment.rotation.y
		river.add_child(bank)


## Camp simplifié au plan moyen (61-66 % X — correction #4) : terrasse,
## feu, deux auvents, fumée fine. Lisible à 90 m (§10.1 de la bible).
func _build_camp() -> void:
	# Y 64,6 % : là où l'ancre TOMBE SUR la pente continue à 90 m — le
	# camp se pose au sol, pas dessous (leçons v0/v1).
	var centre: Vector3 = _world_at(63.5, 64.6, 90.0)
	_mark(&"camp_center", centre)
	_slab("CampTerrace", centre + Vector3(0, -0.8, 0), Vector3(24, 1.6, 20),
		COL_EARTH)
	_slab("CampFirePit", centre + Vector3(0, 0.2, 0), Vector3(1.4, 0.4, 1.4),
		COL_STONE_COLD)
	var flame: MeshInstance3D = MeshInstance3D.new()
	flame.name = "CampFlame"
	var flame_box: BoxMesh = BoxMesh.new()
	flame_box.size = Vector3(0.8, 1.2, 0.8)
	flame.mesh = flame_box
	# Revue : à énergie 4,0 la flamme CLIPPAIT en blanc — le feu-ancre
	# §1.2 doit se lire ORANGE à 90 m, pas comme un point blanc.
	flame.material_override = _emissive_material(Color(1.0, 0.604, 0.239),
		0.9, Color(1.0, 0.55, 0.20), 1.6)
	flame.position = centre + Vector3(0, 1.0, 0)
	add_child(flame)
	# Bible §10.1 : le camp se lit à 70-110 m par flamme, FUMÉE fine et
	# DEUX bannières — pas par ses petits props (leçon v1 : des tentes de
	# 28 px sans signal vertical n'existent pas à l'image).
	var smoke: MeshInstance3D = MeshInstance3D.new()
	smoke.name = "CampSmoke"
	var smoke_box: BoxMesh = BoxMesh.new()
	smoke_box.size = Vector3(1.1, 9.0, 1.1)
	smoke.mesh = smoke_box
	smoke.material_override = _material(Color(0.50, 0.52, 0.56), 1.0)
	smoke.position = centre + Vector3(0.4, 6.0, 0)
	add_child(smoke)
	for side: int in [-1, 1]:
		var tent: MeshInstance3D = MeshInstance3D.new()
		tent.name = "CampTent%s" % ("W" if side < 0 else "E")
		var prism: PrismMesh = PrismMesh.new()
		prism.size = Vector3(4.8, 3.6, 3.6)
		tent.mesh = prism
		tent.material_override = _with_surface(
			_material(COL_CANVAS), "T_Fabric_Canvas", 1.2, 0.62, 0.7)
		tent.position = centre + Vector3(6.5 * float(side), 1.8,
			-2.0 * float(side))
		tent.rotation_degrees = Vector3(0, 24.0 * float(side), 0)
		add_child(tent)
		var pole: MeshInstance3D = MeshInstance3D.new()
		pole.name = "CampBannerPole%s" % ("W" if side < 0 else "E")
		var pole_box: BoxMesh = BoxMesh.new()
		pole_box.size = Vector3(0.3, 6.5, 0.3)
		pole.mesh = pole_box
		pole.material_override = _material(Color(0.408, 0.251, 0.157))
		pole.position = centre + Vector3(3.2 * float(side), 3.25, 2.5)
		add_child(pole)
		var flag: MeshInstance3D = MeshInstance3D.new()
		flag.name = "CampBanner%s" % ("W" if side < 0 else "E")
		var flag_box: BoxMesh = BoxMesh.new()
		flag_box.size = Vector3(2.1, 1.3, 0.12)
		flag.mesh = flag_box
		flag.material_override = _material(Color(0.78, 0.30, 0.22))
		flag.position = centre + Vector3(3.2 * float(side) + 1.1, 5.6, 2.5)
		add_child(flag)


## Pylône au tiers droit (75-79 % X — correction #4). ~105 m : là où un
## asset de 34 m (§3 : 28-36 m) REMPLIT sa fenêtre verticale 17 → 57 %.
## À 140-190 m il faudrait 52 m — les fenêtres du cadre priment.
func _build_pylon() -> void:
	# Y 60 % : le pied émerge de la pente sur son éperon (~3,5 m) ; le
	# sommet (base + 34 m) retombe à ~19,6 % — les deux fenêtres tenues.
	var base: Vector3 = _world_at(77.0, 60.0, 105.0)
	_mark(&"pylon_base", base)
	_mark(&"pylon_top", base + Vector3(0, 34.0, 0))
	# Éperon rocheux (§6.1) sous le pylône.
	_slab("PylonSpur", base + Vector3(0, -4.0, 0), Vector3(16, 8, 16),
		COL_ROCK)
	var pylon: Node3D = Node3D.new()
	pylon.name = "Pylon"
	pylon.position = base
	add_child(pylon)
	# Fût effilé en trois segments, cuivre patiné + céramique.
	var heights: Array[float] = [10.0, 12.0, 8.0]
	var widths: Array[float] = [3.4, 2.5, 1.7]
	var y: float = 0.0
	for i: int in range(3):
		var segment: MeshInstance3D = MeshInstance3D.new()
		segment.name = "Shaft%d" % i
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(widths[i], heights[i], widths[i])
		segment.mesh = box
		segment.material_override = _material(
			COL_COPPER if i % 2 == 0 else COL_IVORY, 0.6)
		segment.position = Vector3(0, y + heights[i] * 0.5, 0)
		pylon.add_child(segment)
		y += heights[i]
	# Anneau incomplet et fourche terminale (§11.2), cœur cyan discret.
	var crown: MeshInstance3D = MeshInstance3D.new()
	crown.name = "Crown"
	var crown_box: BoxMesh = BoxMesh.new()
	crown_box.size = Vector3(4.6, 3.6, 1.2)
	crown.mesh = crown_box
	crown.material_override = _emissive_material(COL_COPPER, 0.5,
		COL_CYAN, 0.6)
	crown.position = Vector3(0, y + 1.6, 0)
	pylon.add_child(crown)


## Proxy de citadelle (bible §2.4) : socle très large, terrasses, deux
## épaules, spire — moins de vingt grandes formes, lisibles à 300 m.
func _build_citadel_proxy() -> void:
	var centre: Vector3 = _world_at(50.5, 43.0, 320.0)
	_mark(&"citadel_center", centre)
	var citadel: Node3D = Node3D.new()
	citadel.name = "CitadelProxy"
	citadel.position = centre
	add_child(citadel)
	# Lot 8 (§2.4) : la revue jugeait la silhouette « boîtes grises ».
	# 19 grandes formes < 20 : socle très large, terrasses successives à
	# ressauts, 4 contreforts, tours coupées de hauteurs DIFFÉRENTES
	# (dont une ruinée), épaulements asymétriques et 3 conduits de
	# cuivre patiné descendant de la couronne vers les flancs.
	var masses: Array[Array] = [
		["Socle", Vector3(0, -18, 0), Vector3(190, 26, 90)],
		["TerraceA", Vector3(-12, -2, 4), Vector3(130, 18, 66)],
		["TerraceA2", Vector3(26, 3, 8), Vector3(58, 10, 44)],
		["TerraceB", Vector3(8, 12, 0), Vector3(90, 16, 50)],
		["TerraceB2", Vector3(-22, 19, -2), Vector3(52, 9, 40)],
		["ShoulderW", Vector3(-46, 16, -4), Vector3(34, 30, 38)],
		["ShoulderE", Vector3(38, 10, 2), Vector3(30, 24, 34)],
		["Keep", Vector3(0, 28, -2), Vector3(48, 26, 36)],
		["ContrefortSW", Vector3(-72, -14, 24), Vector3(22, 34, 20)],
		["ContrefortSE", Vector3(68, -16, 26), Vector3(20, 30, 18)],
		["ContrefortNW", Vector3(-66, -12, -28), Vector3(18, 38, 16)],
		["ContrefortNE", Vector3(62, -14, -24), Vector3(16, 34, 14)],
		["TourW", Vector3(-34, 34, -10), Vector3(14, 34, 14)],
		["TourE", Vector3(28, 30, -8), Vector3(12, 26, 12)],
		["TourRuinee", Vector3(52, 14, -14), Vector3(11, 14, 11)],
	]
	for mass: Array in masses:
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = mass[0] as String
		var box: BoxMesh = BoxMesh.new()
		box.size = mass[2] as Vector3
		mesh.mesh = box
		mesh.material_override = _material(COL_CITADEL, 0.85)
		mesh.position = mass[1] as Vector3
		citadel.add_child(mesh)
	# Les trois lignes de Résonance §2.4 : cuivre PATINÉ non émissif —
	# plus de 95 % de la masse reste sans énergie visible.
	var conduits: Array[Array] = [
		["ConduitC", Vector3(2, 30, 18), Vector3(4, 60, 3)],
		["ConduitW", Vector3(-26, 18, 16), Vector3(3, 44, 3)],
		["ConduitE", Vector3(22, 14, 17), Vector3(3, 36, 3)],
	]
	for conduit: Array in conduits:
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = conduit[0] as String
		var box: BoxMesh = BoxMesh.new()
		box.size = conduit[2] as Vector3
		mesh.mesh = box
		mesh.material_override = _material(COL_COPPER, 0.6)
		mesh.position = conduit[1] as Vector3
		citadel.add_child(mesh)
	# La spire : elle capte l'orage (ancre au sommet).
	var spire: MeshInstance3D = MeshInstance3D.new()
	spire.name = "Spire"
	var spire_box: BoxMesh = BoxMesh.new()
	spire_box.size = Vector3(12, 46, 12)
	spire.mesh = spire_box
	spire.material_override = _material(COL_CITADEL, 0.8)
	spire.position = Vector3(0, 62, -2)
	citadel.add_child(spire)
	_mark(&"citadel_spire", centre + Vector3(0, 85, -2))


## Le nuage d'orage LOCAL au-dessus de la citadelle — la StormCell de la
## vallée, réutilisée telle quelle (éclair déterministe, localité testée).
func _build_storm() -> void:
	var storm: StormCell = StormCell.new()
	storm.name = "Storm"
	var spire: Node3D = _anchors.get(&"citadel_spire", null)
	if spire != null:
		# Lot 5 : nuage plus HAUT et frappe jusqu'au flanc de la flèche
		# (§1.1 : « trajets entre nuage, spire et flancs ») — à 316 m,
		# l'éclair court de 26 m se lisait comme un glyphe (éval v8).
		storm.position = spire.position + Vector3(0, 34, 0)
		storm.strike_offset = Vector3(2.5, -32.0, 1.0)
	add_child(storm)


func _build_light() -> void:
	# Fin d'après-midi (§22.1) : soleil ouest/haut-gauche, miel.
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color(1.0, 0.839, 0.541)
	sun.light_energy = 1.45
	# Lot 7 (revue) : l'ancien yaw +52° plaçait le soleil DERRIÈRE-DROITE
	# de la caméra — contraire à §22.1 (« ouest/haut-gauche ») et au ciel
	# symétrique mesuré (73,6 % des deux côtés). Le soleil passe DEVANT-
	# GAUCHE, 40° d'azimut (juste hors du demi-champ de 35,7°) et 23° de
	# hauteur (§22.1 : 18-28°) : sa lueur entre par le coin haut-gauche
	# (§1.1 : plus forte luminance X 8-34 %) et le héros devient
	# contre-jour, comme la référence.
	var to_sun: Vector3 = Vector3(
		-sin(deg_to_rad(40.0)) * cos(deg_to_rad(23.0)),
		sin(deg_to_rad(23.0)),
		-cos(deg_to_rad(40.0)) * cos(deg_to_rad(23.0)))
	sun.basis = Basis.looking_at(-to_sun)
	# Lot 8 : ombres portées — l'éval v9 notait « pas d'ombre de contact
	# sous le héros » ; §22.1 veut des ombres longues lisibles.
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky: Sky = Sky.new()
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.514, 0.663, 0.804)
	sky_material.sky_horizon_color = Color(0.843, 0.867, 0.902)
	sky_material.ground_bottom_color = Color(0.361, 0.443, 0.322)
	sky_material.ground_horizon_color = Color(0.749, 0.780, 0.702)
	# Lot 7 : halo solaire élargi — le disque reste hors champ, sa lueur
	# miel doit entrer par le coin haut-gauche (§1.1).
	sky_material.sun_angle_max = 62.0
	sky_material.sun_curve = 0.28
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.55
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.686, 0.784, 0.827)
	# 0,0022 : le point v3 — assez de brume pour l'étagement (§1.3),
	# assez peu pour que la citadelle garde une VALEUR §1.5 (35-60 %) —
	# à 0,0045 le brouillard plafonnait tout le lointain à ~65 %.
	environment.fog_density = 0.0022
	environment.fog_aerial_perspective = 0.5
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "LabEnvironment"
	world_environment.environment = environment
	add_child(world_environment)
