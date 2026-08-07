## TERRAIN D'ENTRAÎNEMENT — la base saine demandée au playtest.
##
## Pourquoi cette scène existe (playtest PT-BRACELET-01/02) :
##
##   1. « on ne comprend pas à quoi servent les pouvoirs ni comment les
##      utiliser » — la vallée enseigne le Bracelet à trois écoles distantes
##      de 60 à 120 m, sans une ligne de texte. Ici les CINQ épreuves sont
##      côte à côte, dans l'ordre d'apprentissage, chacune avec son panneau
##      qui dit la touche, le POURQUOI et le COMMENT.
##   2. « quand on les utilise rien ne l'affiche » — chaque épreuve porte une
##      LAMPE DE RÉUSSITE branchée sur le signal réel de l'opération. Le
##      viseur du HUD (`GameplayShell`) fait le reste.
##   3. « beaucoup de modèles sont étranges, maisons sans murs, bois qui
##      flotte » — cause trouvée : le kit `village/` ne contient AUCUNE pièce
##      de mur (uniquement sols, toits, débords, escaliers) ; les murs vivent
##      dans `dungeon/`. Une maison assemblée depuis le seul kit village ne
##      peut donc pas avoir de murs. La maison de référence posée ici est
##      assemblée COMPLÈTE, murs compris, et tout repose à y = 0.
##
## Règle de composition, opposée à celle de la vallée : ici tout est ALIGNÉ
## sur une grille de 2 m, rien n'est dispersé, rien n'est décoratif. La
## vallée reste inchangée — cette scène s'ajoute, elle ne remplace rien.
class_name TrainingGrounds
extends Node3D

const PLAYER_SCENE: String = "res://scenes/player/Player.tscn"
const SHELL_SCENE: String = "res://scenes/ui/GameplayShell.tscn"
const METAL_PROFILE: String = "res://resources/materials/MAT_PROFILE_metal.tres"
const EARTH_PROFILE: String = "res://resources/materials/MAT_PROFILE_terre_conductrice.tres"

## Pièces du kit, résolues par RECHERCHE et non par chemin figé : déplacer un
## asset d'un lot à l'autre ne doit pas casser le terrain en silence.
const KIT_DIRS: Array[String] = [
	"res://assets/environment/village/%s.gltf",
	"res://assets/environment/dungeon/%s.gltf",
	"res://assets/environment/props/%s.gltf",
	"res://assets/environment/foliage/%s.gltf",
	"res://assets/environment/rocks/%s.gltf",
]

## Grille : tout se pose sur un multiple de 2 m. C'est ce qui rend le terrain
## lisible d'un coup d'œil, par opposition au scatter de la vallée.
const GRID: float = 2.0
## Écart entre deux épreuves — assez pour ne pas se marcher dessus, assez peu
## pour toutes les voir depuis le seuil.
const STATION_SPACING: float = 16.0
const STATION_Z: float = 0.0
## Rangée de référence : DERRIÈRE les épreuves. Devant, elle masquerait les
## cinq panneaux depuis le seuil — l'inverse du but.
const SHOWCASE_Z: float = -24.0
## Emprise de la fosse d'Arc Step, en monde. Le dash est HORIZONTAL (il vise
## le point d'arrivée à la hauteur du joueur) : une plateforme surélevée
## serait injouable. Il faut donc un vrai trou dans le sol.
const PIT_MIN: Vector2 = Vector2(28.0, -10.0)
const PIT_MAX: Vector2 = Vector2(36.0, -6.0)
## Le joueur apparaît dos au portique, face aux cinq épreuves.
const SPAWN: Vector3 = Vector3(0.0, 1.0, 34.0)

const CYAN: Color = Color(0.133, 0.851, 0.925)
const GOLD: Color = Color(0.847, 0.702, 0.416)
const IVORY: Color = Color(0.93, 0.91, 0.85)
const SLAB: Color = Color(0.52, 0.48, 0.42)

## Les cinq épreuves, dans l'ORDRE D'APPRENTISSAGE de P2 §3.7 : lire d'abord,
## agir ensuite. Chaque entrée est un contrat de panneau — titre, touche,
## pourquoi, comment.
const TRIALS: Array[Dictionary] = [
	{
		"id": &"pulse", "title": "1 — PULSE", "key": "Touche  A",
		"why": "Lire avant d'agir. Le Pulse révèle ce qui réagit au Bracelet.",
		"how": "Appuie sur A. Portée 10 m, À VUE : il ne traverse pas les murs.\n"
			+ "La troisième cible est derrière le muret — elle ne s'allumera pas.",
	},
	{
		"id": &"ground", "title": "2 — MISE À LA TERRE", "key": "Touche  T",
		"why": "Vider une charge. C'est la réponse à tout ce qui est chargé.",
		"how": "Approche à moins de 3 m du cœur, pieds au sol, appuie sur T\n"
			+ "et NE BOUGE PAS pendant l'amorce.",
	},
	{
		"id": &"polarity", "title": "3 — POLARITÉ", "key": "G  +  clic",
		"why": "Déplacer un métal chargé sans le toucher : appui, pont, projectile.",
		"how": "Tiens G, vise la caisse, clic gauche pour l'ATTIRER,\n"
			+ "Maj gauche + clic gauche pour la REPOUSSER jusqu'au carré.",
	},
	{
		"id": &"link", "title": "4 — ARC LINK", "key": "G  +  2 clics",
		"why": "Transporter un courant qui existe déjà. Il n'en crée jamais.",
		"how": "Tiens G. Clic sur la SOURCE (elle est retenue), puis, SANS\n"
			+ "LÂCHER G, clic sur le RÉCEPTEUR. Lâcher G annule le premier port.",
	},
	{
		"id": &"arc_step", "title": "5 — ARC STEP", "key": "G  +  clic",
		"why": "Franchir un vide vers un ancrage. Coûte 20 d'endurance.",
		"how": "Tiens G, vise le cône cyan de l'autre côté de la fosse,\n"
			+ "clic gauche. Portée 10 m : avance jusqu'au bord.",
	},
]

var _player: PlayerController = null
var _resonance: ResonanceController = null
var _mount: Mount = null
var _fly: DevFlyMode = null
## Lampes de réussite, par identifiant d'épreuve.
var _lamps: Dictionary[StringName, StandardMaterial3D] = {}
## Épreuves déjà réussies — une lampe ne s'éteint jamais, la progression se voit.
var _passed: Dictionary[StringName, bool] = {}
## Assets du kit qui n'ont pas pu être résolus : signalés UNE fois, jamais
## remplacés en silence par un trou.
var _missing: Dictionary[String, bool] = {}
var _built: int = 0


func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_showcase()
	_build_trials()
	_spawn_player()
	_spawn_shell()
	_spawn_mount()
	_spawn_dev_fly()


## --- Décor minimal, lisible, sans effet coûteux -----------------------------

func _build_environment() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Soleil"
	# Même direction que la vallée (§22.1) : ouest, 22° — les volumes se lisent.
	sun.rotation_degrees = Vector3(-22.0, -35.0, 0.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var world: WorldEnvironment = WorldEnvironment.new()
	world.name = "Ambiance"
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky: Sky = Sky.new()
	var sky_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.42, 0.60, 0.74)
	sky_material.sky_horizon_color = Color(0.78, 0.83, 0.84)
	sky_material.ground_bottom_color = Color(0.35, 0.36, 0.34)
	sky_material.ground_horizon_color = Color(0.66, 0.68, 0.66)
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	world.environment = env
	add_child(world)


## Sol plat, d'un seul niveau — le terrain d'entraînement ne teste pas la
## traversée, il teste la COMPRÉHENSION. Une seule discontinuité : la fosse de
## l'épreuve 5, découpée en quatre dalles autour d'elle (patron éprouvé de
## `ResonanceLab`, dont le test d'Arc Step passe sur cette géométrie).
func _build_ground() -> void:
	var tone: Color = Color(0.44, 0.52, 0.34)
	# Au nord de la fosse, sur toute la largeur : c'est là qu'on atterrit.
	_slab(Vector3(0.0, -0.5, -19.0), Vector3(120.0, 1.0, 18.0), tone, "SolNord")
	# Au sud de la fosse : le seuil, la rangée d'épreuves et le spawn.
	_slab(Vector3(0.0, -0.5, 19.0), Vector3(120.0, 1.0, 50.0), tone, "SolSud")
	# La bande à hauteur de fosse, de part et d'autre du trou.
	var strip_z: float = (PIT_MIN.y + PIT_MAX.y) * 0.5
	var strip_depth: float = PIT_MAX.y - PIT_MIN.y
	var west: float = PIT_MIN.x - (-60.0)
	_slab(Vector3(-60.0 + west * 0.5, -0.5, strip_z),
		Vector3(west, 1.0, strip_depth), tone, "SolOuest")
	var east: float = 60.0 - PIT_MAX.x
	_slab(Vector3(PIT_MAX.x + east * 0.5, -0.5, strip_z),
		Vector3(east, 1.0, strip_depth), tone, "SolEst")


## --- Rangée de référence : ce à quoi un asset CORRECT ressemble -------------

## Un exemplaire propre de chaque famille, aligné sur la grille, posé au sol.
## La maison est assemblée ENTIÈRE — quatre murs, une arche, un toit — pour
## servir de comparaison au défaut observé en vallée.
func _build_showcase() -> void:
	var row: Node3D = _node("RangeeDeReference", Vector3(0.0, 0.0, SHOWCASE_Z))
	_sign(row, Vector3(0.0, 0.0, 4.0), "RANGÉE DE RÉFÉRENCE", "",
		"Un exemplaire correct de chaque famille, aligné sur une grille de 2 m.",
		"La maison est assemblée entière : murs, arche et toit. Tout repose au sol.")
	_reference_house(row, Vector3(-16.0, 0.0, 0.0))
	# Les autres familles, une par emplacement de grille, strictement alignées.
	var line: Array[Array] = [
		["CommonTree_2", Vector3(-4.0, 0.0, 0.0), 5.0],
		["Pine_2", Vector3(0.0, 0.0, 0.0), 5.0],
		["Chest_Wood", Vector3(4.0, 0.0, 0.0), 1.0],
		["Barrel", Vector3(8.0, 0.0, 0.0), 1.0],
		["Crate_Wooden", Vector3(12.0, 0.0, 0.0), 1.0],
		["Rock_Medium_1", Vector3(16.0, 0.0, 0.0), 1.0],
	]
	for entry: Array in line:
		var at: Vector3 = entry[1] as Vector3
		_piece(String(entry[0]), at, 0.0, row)
		_pedestal(row, at, float(entry[2]))


## Petit socle sous chaque pièce : il MONTRE que rien ne flotte, et donne au
## regard la grille de 2 m.
func _pedestal(parent: Node3D, at: Vector3, reach: float) -> void:
	var side: float = maxf(reach, 1.6)
	_slab(at + Vector3(0.0, 0.02, 0.0), Vector3(side, 0.06, side), SLAB,
		"Socle", parent)


## Maison de référence 4 × 4 m : quatre murs, une arche au sud, un toit. La
## recette est celle du tombeau de `ValleyRelics`, déjà éprouvée par ses tests.
func _reference_house(parent: Node3D, at: Vector3) -> void:
	var house: Node3D = _node("MaisonDeReference", at, parent)
	var half: float = 2.0
	var slots: Array[float] = [-1.0, 1.0]
	for x: float in slots:
		for z: float in slots:
			_piece("Floor_Brick", Vector3(x, 0.02, z), 0.0, house)
	_collider(house, Vector3(0.0, -0.25, 0.0), Vector3(4.4, 0.5, 4.4))
	# Nord, est, ouest : pleins. Sud : l'arche, seule ouverture.
	for x: float in slots:
		_wall(house, Vector3(x, 0.0, -half), 180.0)
	for z: float in slots:
		_wall(house, Vector3(-half, 0.0, z), 90.0)
		_wall(house, Vector3(half, 0.0, z), 270.0)
	_piece("Wall_Arch", Vector3(0.0, 0.0, half), 0.0, house)
	_piece("DoorFrame_Round_Brick", Vector3(0.0, 0.0, half - 0.05), 0.0, house)
	for side: float in [-1.0, 1.0]:
		_collider(house, Vector3(side * 1.5, 1.56, half), Vector3(1.0, 3.12, 0.4))
	_collider(house, Vector3(0.0, 2.77, half), Vector3(4.0, 0.7, 0.4))
	_piece("Roof_RoundTiles_4x4", Vector3(0.1, 3.12, -0.1), 0.0, house)


## --- Les cinq épreuves ------------------------------------------------------

func _build_trials() -> void:
	_sign(self, Vector3(0.0, 0.0, 26.0), "TERRAIN D'ENTRAÎNEMENT", "",
		"Cinq épreuves, de gauche à droite, dans l'ordre où on les apprend.",
		"Chaque panneau donne la touche, à quoi sert le pouvoir, et comment le faire.")
	for index: int in range(TRIALS.size()):
		var trial: Dictionary = TRIALS[index]
		var offset: float = (float(index) - 2.0) * STATION_SPACING
		var station: Node3D = _node("Epreuve_%s" % String(trial["id"]),
			Vector3(offset, 0.0, STATION_Z))
		# Dalle identique pour toutes : l'anatomie d'une épreuve s'apprend une
		# fois et se relit ensuite d'un coup d'œil.
		_slab(Vector3(0.0, 0.03, 0.0), Vector3(12.0, 0.06, 12.0), SLAB,
			"Dalle", station)
		# Le panneau se tient au BORD de la dalle, jamais entre le joueur et
		# l'appareil : on le lit en arrivant, puis on avance librement.
		_sign(station, Vector3(0.0, 0.0, 6.5), String(trial["title"]),
			String(trial["key"]), String(trial["why"]), String(trial["how"]))
		_lamp(station, String(trial["id"]))
		match StringName(String(trial["id"])):
			&"pulse":
				_build_pulse_trial(station)
			&"ground":
				_build_ground_trial(station)
			&"polarity":
				_build_polarity_trial(station)
			&"link":
				_build_link_trial(station)
			&"arc_step":
				_build_arc_step_trial(station)


## 1 — PULSE : deux cibles à découvert, une derrière un muret. La leçon est
## que la troisième ne s'allume PAS : la révélation ne traverse pas un mur.
func _build_pulse_trial(station: Node3D) -> void:
	_pulse_target(station, Vector3(-2.0, 1.0, -2.0))
	_pulse_target(station, Vector3(2.0, 1.0, -2.0))
	_slab(Vector3(0.0, 1.0, -3.6), Vector3(4.0, 2.0, 0.4),
		Color(0.36, 0.34, 0.33), "Muret", station)
	_pulse_target(station, Vector3(0.0, 1.0, -4.6))


## 2 — MISE À LA TERRE : un cœur pré-chargé sur son socle, à hauteur d'homme.
func _build_ground_trial(station: Node3D) -> void:
	_slab(Vector3(0.0, 0.5, -2.0), Vector3(1.2, 1.0, 1.2), SLAB, "Socle", station)
	var holder: Node3D = _node("CoeurCharge", Vector3(0.0, 1.24, -2.0), station)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var orb: SphereMesh = SphereMesh.new()
	orb.radius = 0.18
	orb.height = 0.36
	mesh.mesh = orb
	var material: StandardMaterial3D = _emissive(CYAN, 1.6)
	mesh.material_override = material
	holder.add_child(mesh)
	var state: MaterialStateComponent = MaterialStateComponent.new()
	state.name = "MaterialStateComponent"
	state.profile = load(EARTH_PROFILE) as MaterialProfile
	# Le cœur ATTEND le joueur : sans cela l'épreuve se vide toute seule.
	state.charge_decay_enabled = false
	holder.add_child(state)
	var marker: ResonanceTargetComponent = ResonanceTargetComponent.new()
	marker.kind = &"material"
	holder.add_child(marker)
	state.add_charge(4.0)
	# La charge se VOIT : l'émission suit l'état réel, jamais un minuteur.
	state.state_changed.connect(func(which: StringName, active: bool) -> void:
		if which == &"charged":
			material.emission_energy_multiplier = 1.6 if active else 0.0)


## 3 — POLARITÉ : une caisse métallique chargée et un carré d'arrivée. La
## réussite est mesurée par l'ENTRÉE réelle de la caisse dans le carré.
func _build_polarity_trial(station: Node3D) -> void:
	var block: RigidBody3D = _metal_block(station, Vector3(0.0, 0.5, 0.0))
	var marker: ResonanceTargetComponent = ResonanceTargetComponent.new()
	marker.kind = &"polarity"
	block.add_child(marker)
	# Repère au sol, sans matière : la caisse doit y rouler, pas buter dessus.
	_slab(Vector3(0.0, 0.05, -4.0), Vector3(2.4, 0.04, 2.4), CYAN, "Carre",
		station, false)
	var goal: Area3D = Area3D.new()
	goal.name = "Arrivee"
	goal.collision_layer = 0
	goal.collision_mask = 0xFFFFFFFF
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2.4, 2.0, 2.4)
	shape.shape = box
	goal.add_child(shape)
	station.add_child(goal)
	goal.position = Vector3(0.0, 1.0, -4.0)
	goal.body_entered.connect(func(body: Node3D) -> void:
		if body == block:
			_pass_trial(&"polarity"))


## 4 — ARC LINK : source et récepteur, trop loin l'un de l'autre pour se
## toucher, assez près pour un lien. Exactement la leçon du bassin, mais lue.
func _build_link_trial(station: Node3D) -> void:
	var graph: ElectricGraph = ElectricGraph.new()
	station.add_child(graph)
	var source: ElectricNode = _electric(station, ElectricNode.Kind.SOURCE,
		&"training.link.source.01", Vector3(-3.0, 0.9, -2.0))
	_port_marker(source)
	_node_lamp(source, Color(1.0, 0.75, 0.3), 1.8)
	var receiver: ElectricNode = _electric(station, ElectricNode.Kind.RECEIVER,
		&"training.link.receiver.01", Vector3(3.0, 0.9, -2.0))
	_port_marker(receiver)
	_node_lamp(receiver, CYAN, 0.0)
	receiver.power_changed.connect(func(powered: bool, _power: float) -> void:
		if powered:
			_pass_trial(&"link"))


## 5 — ARC STEP : une fosse franchissable seulement par le dash, et une
## plateforme d'arrivée qui valide l'épreuve à l'arrivée RÉELLE du joueur.
func _build_arc_step_trial(station: Node3D) -> void:
	# La dalle de l'épreuve s'arrête au bord de la fosse (z = -6) ; le sol
	# reprend au-delà de z = -10. Le carré d'arrivée n'est qu'un repère POSÉ
	# sur ce sol — l'Arc Step vise à la hauteur du joueur, jamais plus haut.
	_slab(Vector3(0.0, 0.03, -13.0), Vector3(8.0, 0.06, 6.0),
		Color(0.18, 0.44, 0.48), "Arrivee", station, false)
	var holder: Node3D = _node("Ancrage", Vector3(0.0, 1.2, -13.0), station)
	var anchor: ResonanceTargetComponent = ResonanceTargetComponent.new()
	anchor.kind = &"arc_anchor"
	holder.add_child(anchor)
	var cone: MeshInstance3D = MeshInstance3D.new()
	var shape: CylinderMesh = CylinderMesh.new()
	shape.top_radius = 0.0
	shape.bottom_radius = 0.3
	shape.height = 1.6
	cone.mesh = shape
	cone.material_override = _emissive(CYAN, 1.6)
	holder.add_child(cone)
	var goal: Area3D = Area3D.new()
	goal.name = "Reussite"
	goal.collision_layer = 0
	goal.collision_mask = 0xFFFFFFFF
	var box_shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(8.0, 3.0, 6.0)
	box_shape.shape = box
	goal.add_child(box_shape)
	station.add_child(goal)
	goal.position = Vector3(0.0, 1.5, -13.0)
	goal.body_entered.connect(func(body: Node3D) -> void:
		if body is PlayerController:
			_pass_trial(&"arc_step"))


## --- Réussite ---------------------------------------------------------------

## Lampe d'épreuve : éteinte tant que l'épreuve n'est pas réussie, allumée
## ensuite et pour de bon. C'est le retour qui manquait au playtest.
func _lamp(station: Node3D, id: String) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "Lampe"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	mesh.mesh = box
	var material: StandardMaterial3D = _emissive(CYAN, 0.0)
	mesh.material_override = material
	station.add_child(mesh)
	# Au sommet du panneau : la lampe et le texte se lisent d'un même regard.
	mesh.position = Vector3(0.0, 4.2, 6.5)
	_lamps[StringName(id)] = material
	_passed[StringName(id)] = false


func _pass_trial(id: StringName) -> void:
	if is_trial_passed(id):
		return
	_passed[id] = true
	if _lamps.has(id):
		var material: StandardMaterial3D = _lamps[id]
		material.emission_energy_multiplier = 3.0
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("gameplay_notification"):
		bus.emit_signal("gameplay_notification", "Épreuve réussie : %s" % id)


## Épreuves réussies — seam de test et de progression.
func passed_trials() -> Array[StringName]:
	var done: Array[StringName] = []
	for id: StringName in _passed:
		if _passed[id]:
			done.append(id)
	return done


func is_trial_passed(id: StringName) -> bool:
	return _passed.has(id) and _passed[id]


## --- Joueur, coquille -------------------------------------------------------

func _spawn_player() -> void:
	var scene: PackedScene = load(PLAYER_SCENE) as PackedScene
	if scene == null:
		return
	_player = scene.instantiate() as PlayerController
	add_child(_player)
	_player.global_position = SPAWN
	_resonance = _player.resonance()
	if _resonance == null:
		return
	# Les épreuves de lecture n'ont pas de conséquence physique : elles se
	# valident sur le SIGNAL réel de l'opération, jamais par sondage.
	_resonance.pulse_fired.connect(func(revealed: int) -> void:
		if revealed > 0:
			_pass_trial(&"pulse"))
	_resonance.ground_completed.connect(func(_target: Node) -> void:
		_pass_trial(&"ground"))


func _spawn_shell() -> void:
	var scene: PackedScene = load(SHELL_SCENE) as PackedScene
	if scene == null:
		return
	add_child(scene.instantiate())


func player() -> PlayerController:
	return _player


## Monture d'essai, posée à droite du seuil avec son panneau. GRAYBOX assumé :
## aucun quadrupède n'existe dans les kits, la silhouette est en primitives.
func _spawn_mount() -> void:
	_mount = Mount.new()
	_mount.name = "Monture"
	add_child(_mount)
	_mount.global_position = Vector3(10.0, 0.6, 30.0)
	_sign(self, Vector3(10.0, 0.0, 34.0), "MONTURE", "Touche  E",
		"Se déplacer plus vite qu'à pied : le galop dépasse nettement le sprint.",
		"E pour monter, E pour descendre. Direction = tourner, avant = avancer,\n"
			+ "Maj = galop. On ne descend que si la place à côté est libre.")


## Vol libre de développement. Refusé dans un build exporté (voir
## `DevFlyMode.is_allowed`) : ce n'est pas une mécanique de jeu.
func _spawn_dev_fly() -> void:
	if _player == null:
		return
	_fly = DevFlyMode.new()
	_fly.name = "VolLibre"
	add_child(_fly)
	_fly.bind(_player)
	_sign(self, Vector3(-10.0, 0.0, 34.0), "VOL LIBRE (DEV)", "Touche  F2",
		"Outil de développement : survoler la carte pour l'inspecter.",
		"F2 pour entrer et sortir. Espace monte, Ctrl descend, Maj accélère.\n"
			+ "En sortant, le héros est reposé au sol si la place est libre.")


func mount() -> Mount:
	return _mount


func dev_fly() -> DevFlyMode:
	return _fly


## --- Briques ----------------------------------------------------------------

func _node(node_name: String, at: Vector3, parent: Node3D = null) -> Node3D:
	var node: Node3D = Node3D.new()
	node.name = node_name
	node.position = at
	(parent if parent != null else self).add_child(node)
	return node


## Volume plein : visuel + collision, d'un seul tenant. Rien ne flotte, rien
## n'est visuel sans matière.
## `solid` à `false` pose un volume PUREMENT visuel : une plaque de panneau
## solide barrerait le passage vers l'épreuve qu'elle explique — un mur
## invisible en travers du tutoriel serait le comble.
func _slab(at: Vector3, size: Vector3, tone: Color, slab_name: String,
		parent: Node3D = null, solid: bool = true) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "%s%03d" % [slab_name, _built]
	body.collision_layer = 1 if solid else 0
	body.collision_mask = 0
	if solid:
		var shape: CollisionShape3D = CollisionShape3D.new()
		var box: BoxShape3D = BoxShape3D.new()
		box.size = size
		shape.shape = box
		body.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = tone
	material.roughness = 0.92
	mesh.material_override = material
	body.add_child(mesh)
	(parent if parent != null else self).add_child(body)
	body.position = at
	_built += 1
	return body


func _collider(parent: Node3D, at: Vector3, size: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = "Bloc%03d" % parent.get_child_count()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = at
	parent.add_child(body)


## Mur du kit + sa collision. Le kit est purement visuel : sans cette boîte,
## on traverse le mur — l'autre moitié du défaut « maison sans murs ».
func _wall(parent: Node3D, at: Vector3, yaw: float) -> void:
	_piece("Wall_UnevenBrick_Straight", at, yaw, parent)
	var along: Vector3 = Vector3(cos(deg_to_rad(yaw)), 0.0, -sin(deg_to_rad(yaw)))
	var thick: Vector3 = Vector3(absf(along.z), 0.0, absf(along.x)) * 0.4
	var span: Vector3 = along.abs() * GRID
	_collider(parent, at + Vector3(0.0, 1.56, 0.0),
		Vector3(maxf(span.x, thick.x), 3.12, maxf(span.z, thick.z)))


## Pièce du kit, résolue par recherche. Un asset absent est SIGNALÉ, jamais
## remplacé par un trou silencieux.
func _piece(asset: String, at: Vector3, yaw: float, parent: Node3D) -> Node3D:
	var packed: PackedScene = null
	for pattern: String in KIT_DIRS:
		var full: String = pattern % asset
		if ResourceLoader.exists(full):
			packed = load(full) as PackedScene
			if packed != null:
				break
	if packed == null:
		if not _missing.has(asset):
			_missing[asset] = true
			push_warning("[entraînement] pièce absente du kit : %s" % asset)
		return null
	var node: Node3D = packed.instantiate() as Node3D
	node.name = "%s_%03d" % [asset, _built]
	node.position = at
	node.rotation_degrees = Vector3(0.0, yaw, 0.0)
	# §3 : le kit végétal est importé sans normalisation — `KitScale` corrige
	# à la source unique, comme partout ailleurs dans le projet.
	var factor: float = KitScale.factor(asset)
	if not is_equal_approx(factor, 1.0):
		node.scale = Vector3.ONE * factor
	parent.add_child(node)
	_built += 1
	return node


## Assets du kit qui n'ont pas pu être résolus — seam de test : le terrain
## d'entraînement ne doit contenir AUCUN trou.
func missing_assets() -> Array[String]:
	var names: Array[String] = []
	for asset: String in _missing:
		names.append(asset)
	return names


func piece_count() -> int:
	return _built


## Panneau explicatif. Le POURQUOI et le COMMENT, en clair, dans le monde —
## pas un tutoriel bavard en surimpression qu'on ne peut pas relire.
func _sign(parent: Node3D, at: Vector3, title: String, key: String,
		why: String, how: String) -> Node3D:
	var post: Node3D = _node("Panneau", at, parent)
	_slab(Vector3(0.0, 1.1, 0.0), Vector3(0.24, 2.2, 0.24),
		Color(0.35, 0.29, 0.22), "Poteau", post)
	# La plaque ne porte AUCUNE collision : on lit le panneau, on ne se cogne
	# pas dedans en allant vers l'épreuve.
	_slab(Vector3(0.0, 2.6, -0.06), Vector3(7.2, 1.9, 0.12),
		Color(0.13, 0.14, 0.17), "Plaque", post, false)
	var heading: Label3D = Label3D.new()
	heading.name = "Titre"
	heading.text = title if key.is_empty() else "%s        %s" % [title, key]
	heading.font_size = 64
	heading.pixel_size = 0.0042
	heading.modulate = GOLD
	heading.outline_size = 10
	heading.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	heading.position = Vector3(0.0, 3.24, 0.02)
	post.add_child(heading)
	var body: Label3D = Label3D.new()
	body.name = "Corps"
	body.text = "%s\n%s" % [why, how]
	body.font_size = 44
	body.pixel_size = 0.0042
	body.modulate = IVORY
	body.outline_size = 8
	body.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.position = Vector3(0.0, 2.42, 0.02)
	post.add_child(body)
	return post


func _emissive(tint: Color, energy: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.35, 0.37, 0.4)
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = energy
	return material


func _pulse_target(station: Node3D, at: Vector3) -> void:
	var holder: Node3D = _node("CiblePulse", at, station)
	var target: ResonanceTargetComponent = ResonanceTargetComponent.new()
	target.kind = &"material"
	holder.add_child(target)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	mesh.mesh = sphere
	var material: StandardMaterial3D = _emissive(CYAN, 0.0)
	mesh.material_override = material
	holder.add_child(mesh)
	target.revealed.connect(func(_duration: float) -> void:
		material.emission_energy_multiplier = 2.4)
	target.reveal_ended.connect(func() -> void:
		material.emission_energy_multiplier = 0.0)


func _metal_block(parent: Node3D, at: Vector3) -> RigidBody3D:
	var block: RigidBody3D = RigidBody3D.new()
	block.name = "CaisseMetal"
	block.mass = 40.0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.9, 0.9, 0.9)
	shape.shape = box
	block.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(0.9, 0.9, 0.9)
	mesh.mesh = box_mesh
	var material: StandardMaterial3D = _emissive(CYAN, 2.0)
	mesh.material_override = material
	block.add_child(mesh)
	var state: MaterialStateComponent = MaterialStateComponent.new()
	state.profile = load(METAL_PROFILE) as MaterialProfile
	state.charge_decay_enabled = false
	block.add_child(state)
	parent.add_child(block)
	block.position = at
	state.add_charge(5.0)
	state.charge_changed.connect(func(amount: float) -> void:
		material.emission_energy_multiplier = clampf(amount * 0.4, 0.0, 2.0))
	return block


func _electric(parent: Node3D, kind: ElectricNode.Kind, id: StringName,
		at: Vector3) -> ElectricNode:
	var node: ElectricNode = ElectricNode.new()
	node.kind = kind
	node.node_id = id
	parent.add_child(node)
	node.position = at
	return node


func _port_marker(node: ElectricNode) -> void:
	var marker: ResonanceTargetComponent = ResonanceTargetComponent.new()
	marker.kind = &"port"
	node.add_child(marker)


func _node_lamp(node: ElectricNode, tint: Color, idle: float) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.6, 1.2, 0.6)
	mesh.mesh = box
	var material: StandardMaterial3D = _emissive(tint, idle)
	mesh.material_override = material
	node.add_child(mesh)
	node.power_changed.connect(func(powered: bool, _power: float) -> void:
		material.emission_energy_multiplier = 1.8 if powered else idle)
