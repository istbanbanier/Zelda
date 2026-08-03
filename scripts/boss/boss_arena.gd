## ARÈNE DU GARDIEN DE L'ORAGE (MASTER_SPEC §16.1, §16.6).
##
## | §16.1 / §16.6 | ici |
## |---|---|
## | arène circulaire de 32 à 42 m | disque de **38 m** de diamètre (rayon 19), sol et mur bâtis en cercle, pas en boîte |
## | quatre pylônes de mise à la terre | quatre `GroundingPylon` à 45°, 135°, 225°, 315° — de VRAIS nœuds du graphe électrique, reliés au rail de terre |
## | zones de sol distinctes | trois couronnes lisibles : dalle du noyau (0-6 m), anneau de combat (6-14 m), marge de terre (14-19 m) |
## | aucun pilier bloquant durablement la caméra | rien au-dessus du sol entre le centre et le mur, sauf les quatre pylônes — étroits (1,6 m de fourreau) et loin (14 m) |
## | boss ne pousse pas le joueur à travers les murs | le mur est un anneau statique continu, et le Gardien est un `CharacterBody3D` qui GLISSE contre le joueur au lieu de le pousser |
## | nav/steering garde le boss dans l'arène | mur continu **et** rappel doux `arena_center`/`arena_radius` côté boss |
## | caméra élargit distance/FOV progressivement | `CameraRig.set_boss_framing()`, interpolé, tant que le Gardien vit |
## | checkpoint juste avant | l'antichambre l'écrit (§19.5) ; l'arène le RELIT et rééquipe le joueur |
## | retry en moins de 20 s | « Réessayer » recharge cette scène (`world_scene_path`), pas la vallée |
## | zone de retour sûre après une esquive | la marge de terre (14-19 m) est une RESPIRATION : hors de portée d'arc tant que le Gardien tient le centre. Il se déplace, donc ce n'est pas un sanctuaire — et c'est voulu |
##
## **Le rail de terre est un vrai circuit** (§16.3 : « les pylônes utilisent
## le MÊME système électrique que le donjon »). Un anneau fermé de câbles
## à 14 m, alimenté par le puits de terre au nord : c'est donc un CYCLE, le
## cas que §15.2 pt. 5 exige de supporter sans récursion infinie. Dresser
## un pylône le raccorde au rail ; son noyau s'allume. Deux noyaux allumés,
## et la prochaine décharge du Gardien part dans la terre.
class_name BossArena
extends DungeonRoom

signal boss_defeated()

const ANTECHAMBER: String = "res://scenes/dungeon/rooms/Antechamber.tscn"
const GUARDIAN: String = "res://scenes/boss/StormGuardian.tscn"
const FINAL_CHEST: String = "res://scenes/interactables/Chest.tscn"
const VICTORY: String = "res://scenes/ui/VictoryScreen.tscn"
## §16.8 : « courte cinématique passable ». Elle ne prend pas la main : le
## joueur peut marcher, ouvrir le coffre, regarder le ciel. Passé ce délai
## — ou dès qu'il ouvre le coffre — l'écran de victoire arrive.
const CONCLUSION_TIME: float = 12.0
## Durée de l'apaisement du ciel (§16.8).
const CALM_TIME: float = 6.0
const CALM_SKY: Color = Color(0.42, 0.52, 0.60)
const CALM_SUN: Color = Color(1.0, 0.84, 0.62)
const CALM_AMBIENT: Color = Color(0.52, 0.50, 0.46)

## §16.1 : « arène circulaire de 32-42 m ». 38 m de diamètre.
const ARENA_RADIUS: float = 19.0
const WALL_RADIUS: float = 19.6
const WALL_HEIGHT: float = 13.0
const WALL_SEGMENTS: int = 24
## Rail de terre : anneau fermé au pied des pylônes.
const RAIL_RADIUS: float = 14.0
const RAIL_Y: float = 0.2
const RAIL_SEGMENTS: int = 24
## Indices d'anneau occupés par les pylônes — 45°, 135°, 225°, 315°.
const PYLON_INDICES: Array[int] = [3, 9, 15, 21]
## Puits de terre, au nord, derrière le Gardien.
const EARTH_INDEX: int = 12
## Bornes des trois zones de sol (§16.1).
const CORE_ZONE: float = 6.0
const RING_ZONE: float = 14.0
## §16.6 : supplément de cadrage pendant le combat. Mesuré sur la
## silhouette : 6,4 m de long à 4,3 m de recul sortent du cadre.
const BOSS_FRAMING_DISTANCE: float = 2.2
const BOSS_FRAMING_FOV: float = 6.0
const BOSS_SPAWN: Vector3 = Vector3(0, 0.2, -7.0)

## Vrai en jeu. Coupé par les tests, et pour une raison précise :
## `SceneFlow.go_to()` met l'arbre en pause et appelle
## `change_scene_to_file()`, ce qui détruirait la scène courante du runner.
## Ce que les tests prouvent à la place est ce qui compte : QUAND la
## conclusion se termine (`conclusion_is_over()`), et VERS QUOI elle mène
## (`VICTORY`, dont l'existence est vérifiée). Le même partage que le
## bouton « Réessayer » de la coquille.
@export var auto_show_victory: bool = true

var _pylons: Array[GroundingPylon] = []
var _rail: Array[ElectricNode] = []
var _earth: ElectricNode = null
var _boss: StormGuardian = null
var _victory_written: bool = false
var _checkpoint_restored: bool = false
var _final_chest: Chest = null
var _calming: bool = false
var _conclusion_elapsed: float = 0.0
var _victory_shown: bool = false

@onready var _player: PlayerController = get_node_or_null("Player") \
	as PlayerController


func _ready() -> void:
	room_id = &"boss.arena.storm.01"
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 4)  # GameState.Flow.BOSS_ARENA
	var spawn_tag: StringName = consume_spawn_tag()
	_build_floor()
	_build_wall()
	_build_ground_rail()
	_build_pylons()
	_setup_lighting()
	var graph_node: ElectricGraph = ElectricGraph.new()
	graph_node.name = "Graph"
	add_child(graph_node)
	set_graph(graph_node)
	var debug_overlay: ElectricDebugOverlay = ElectricDebugOverlay.new()
	debug_overlay.name = "ElectricDebug"
	debug_overlay.graph_path = NodePath("../Graph")
	add_child(debug_overlay)
	place_player_at_spawn(_player, spawn_tag, {
		&"arena_from_antechamber": Vector3(0, 0.3, 16.5),
	})
	_restore_checkpoint()
	_spawn_boss()
	set_physics_process(true)


## §16.1 : le sol est un DISQUE, et il porte trois zones lisibles. La
## couronne extérieure dit « ici l'arc du centre ne t'atteint pas » sans
## un mot de texte.
func _build_floor() -> void:
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.name = "ArenaFloor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = ARENA_RADIUS
	cylinder.height = 1.0
	shape.shape = cylinder
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, 0)
	add_child(floor_body)

	_floor_zone("ZoneOuter", ARENA_RADIUS, 0.0, Color(0.29, 0.28, 0.31))
	_floor_zone("ZoneRing", RING_ZONE, 0.01, Color(0.23, 0.22, 0.26))
	_floor_zone("ZoneCore", CORE_ZONE, 0.02, Color(0.17, 0.17, 0.21))
	# Quatre rainures de terre : elles vont du noyau à chaque pylône, et
	# disent où le courant partira quand le pylône sera dressé.
	for i: int in range(PYLON_INDICES.size()):
		var angle: float = _ring_angle(PYLON_INDICES[i])
		var groove: MeshInstance3D = decor("Groove%d" % i,
			Vector3(sin(angle) * 8.5, 0.03, cos(angle) * 8.5),
			Vector3(0.4, 0.02, 13.0), Color(0.36, 0.26, 0.16))
		groove.rotation.y = angle


func _floor_zone(zone_name: String, radius: float, height: float,
		color: Color) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = zone_name
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.04
	mesh.mesh = cylinder
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh.material_override = material
	mesh.position = Vector3(0, height, 0)
	add_child(mesh)
	return mesh


## Mur circulaire continu. §16.6 : il tient le Gardien dedans et empêche
## qu'il pousse le joueur dehors ; il n'ajoute AUCUN pilier au milieu.
func _build_wall() -> void:
	var segment_width: float = TAU * WALL_RADIUS / float(WALL_SEGMENTS) * 1.06
	for i: int in range(WALL_SEGMENTS):
		var angle: float = TAU * float(i) / float(WALL_SEGMENTS)
		var at: Vector3 = Vector3(sin(angle) * WALL_RADIUS, WALL_HEIGHT * 0.5,
			cos(angle) * WALL_RADIUS)
		# Le seuil du sud reste ouvert : on entre et on peut ressortir.
		if i == 0:
			continue
		var segment: StaticBody3D = box("Wall%02d" % i, at,
			Vector3(segment_width, WALL_HEIGHT, 1.2), COL_STONE)
		segment.rotation.y = angle
		segment.add_to_group("unclimbable")
	# Encadrement du seuil sud, et la porte de retour vers l'antichambre.
	box("ThresholdWest", Vector3(-3.6, WALL_HEIGHT * 0.5, WALL_RADIUS - 0.4),
		Vector3(2.6, WALL_HEIGHT, 1.2), COL_STONE)
	box("ThresholdEast", Vector3(3.6, WALL_HEIGHT * 0.5, WALL_RADIUS - 0.4),
		Vector3(2.6, WALL_HEIGHT, 1.2), COL_STONE)
	box("ThresholdLintel", Vector3(0, 8.0, WALL_RADIUS - 0.4),
		Vector3(4.6, 8.0, 1.2), COL_BRONZE)
	# §15.11 s'applique jusqu'ici : on n'enferme personne. Le joueur peut
	# repartir cuisiner à l'antichambre et revenir.
	scene_door("DoorAntechamber", "Retourner à l'antichambre", ANTECHAMBER,
		&"antechamber_from_arena", Vector3(0, 2.5, WALL_RADIUS + 0.2),
		Vector3(4.2, 5.0, 0.4))


## Anneau de terre : `RAIL_SEGMENTS` câbles dont les ports se touchent deux
## à deux le long du cercle. Aux quatre indices de pylône, le câble devient
## un CONNECTEUR portant un port supplémentaire en son centre — c'est là
## que descend le port du pylône. Le puits de terre remplace l'indice nord.
func _build_ground_rail() -> void:
	var half_arc: float = TAU * RAIL_RADIUS / float(RAIL_SEGMENTS) * 0.5
	for i: int in range(RAIL_SEGMENTS):
		var angle: float = _ring_angle(i)
		var at: Vector3 = Vector3(sin(angle) * RAIL_RADIUS, RAIL_Y,
			cos(angle) * RAIL_RADIUS)
		var tangent: Vector3 = Vector3(cos(angle), 0.0, -sin(angle))
		var ports: Array[Vector3] = [tangent * -half_arc, tangent * half_arc]
		var is_pylon_seat: bool = PYLON_INDICES.has(i)
		if is_pylon_seat:
			ports.append(Vector3.ZERO)
		var kind: ElectricNode.Kind = ElectricNode.Kind.CABLE
		if i == EARTH_INDEX:
			kind = ElectricNode.Kind.SOURCE
		elif is_pylon_seat:
			kind = ElectricNode.Kind.CONNECTOR
		var node: ElectricNode = make_node(
			StringName("boss.node.arena_rail.%02d" % (i + 1)), kind, at,
			ports, 0.55)
		node.name = "Rail%02d" % (i + 1)
		var size: Vector3 = Vector3(0.24, 0.16, half_arc * 2.0)
		var visual_mesh: MeshInstance3D = MeshInstance3D.new()
		visual_mesh.name = "Mesh"
		var box_mesh: BoxMesh = BoxMesh.new()
		box_mesh.size = size
		visual_mesh.mesh = box_mesh
		visual_mesh.rotation.y = angle
		node.add_child(visual_mesh)
		var visual: ElectricVisual = ElectricVisual.new()
		visual.name = "Visual"
		visual.node_path = NodePath("..")
		visual.mesh_path = NodePath("../Mesh")
		visual.pulse = (i == EARTH_INDEX)
		node.add_child(visual)
		if i == EARTH_INDEX:
			_earth = node
			box("EarthWell", at + Vector3(0, 0.6, 0), Vector3(2.4, 1.6, 2.4),
				COL_BRONZE)
		_rail.append(node)


## §16.1 : quatre pylônes. §16.3 : ce sont des nœuds du graphe, pas un
## compteur — le levier au pied les raccorde au rail, et leur noyau ne
## s'allume que si le courant y arrive VRAIMENT.
func _build_pylons() -> void:
	for i: int in range(PYLON_INDICES.size()):
		var angle: float = _ring_angle(PYLON_INDICES[i])
		var pylon: GroundingPylon = GroundingPylon.new()
		pylon.name = "Pylon%d" % (i + 1)
		pylon.pylon_id = StringName("boss.node.arena_pylon.%02d" % (i + 1))
		pylon.height = 6.0
		# Le sabot du mât déployé tombe pile sur le siège du rail : le
		# pylône est posé À 14 m, et `GroundingPylon.SEAT_Y` vaut `RAIL_Y`.
		pylon.node_port_reach = 0.5
		pylon.position = Vector3(sin(angle) * RAIL_RADIUS, 0.0,
			cos(angle) * RAIL_RADIUS)
		add_child(pylon)
		_pylons.append(pylon)


func _ring_angle(index: int) -> float:
	return TAU * float(index) / float(RAIL_SEGMENTS)


## Le Gardien naît au nord de l'arène, face au seuil : le joueur le voit
## entier en entrant, avant d'être à portée (§16.1, animation d'entrée).
func _spawn_boss() -> void:
	_boss = (load(GUARDIAN) as PackedScene).instantiate() as StormGuardian
	_boss.name = "StormGuardian"
	var paths: Array[NodePath] = []
	for pylon: GroundingPylon in _pylons:
		paths.append(NodePath("../%s" % pylon.name))
	_boss.pylon_paths = paths
	_boss.arena_center = Vector3.ZERO
	# Marge : le Gardien fait 3,2 m de large, il ne colle pas au mur.
	_boss.arena_radius = ARENA_RADIUS - 2.6
	_boss.position = BOSS_SPAWN
	add_child(_boss)
	if _player != null:
		_boss.set_target(_player)
	_boss.died.connect(_on_boss_died)


## §19.5 : le checkpoint de l'antichambre est le point de reprise. L'arène
## le RELIT — c'est ce qui rend le « Réessayer » de §16.6 honnête : on
## revient avec l'équipement du checkpoint, pas les mains vides.
func _restore_checkpoint() -> void:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null or _player == null \
			or not bool(save_system.call("has_save", SAVE_SLOT)):
		return
	var data: Dictionary = save_system.call("load_slot", SAVE_SLOT) as Dictionary
	if data.is_empty() or _player.inventory() == null:
		return
	var inventory: InventoryComponent = _player.inventory()
	if data.has("weapons"):
		inventory.clear_weapons()
		for entry: Variant in (data["weapons"] as Array):
			var weapon_data: Dictionary = entry as Dictionary
			var id: String = String(weapon_data.get("id", ""))
			var path: String = "res://resources/weapons/%s.tres" % id
			if not ResourceLoader.exists(path):
				push_warning("[arène] arme inconnue ignorée : %s" % id)
				continue
			var instance: WeaponInstance = WeaponInstance.create(
				load(path) as WeaponDefinition)
			instance.current_durability = int(weapon_data.get("durability",
				instance.current_durability))
			inventory.add_weapon(instance)
		inventory.equip_index(int(data.get("equipped_index", 0)))
	if data.has("arrows"):
		inventory.set_arrows(int(data["arrows"]))
	if data.has("ingredients"):
		inventory.set_ingredients(data["ingredients"] as Dictionary)
	if data.has("meals"):
		inventory.set_meals(data["meals"] as Array)
	# §19.5 : « santé minimale correcte » — on repart entier, jamais à 3 PV.
	if _player.health() != null:
		_player.health().revive(_player.health().maximum())
	_checkpoint_restored = true


## §16.6, cadrage. La consigne dépend de la DISTANCE : hors combat la
## caméra reprend sa forme d'exploration ; au contact elle recule et
## s'ouvre. La progressivité est dans le rig, pas ici.
func _physics_process(delta: float) -> void:
	if _calming:
		_calm_the_storm(delta)
		_tick_conclusion(delta)
	if _player == null or not is_instance_valid(_player):
		return
	var rig: CameraRig = _player.camera_rig()
	if rig == null:
		return
	if _boss == null or not is_instance_valid(_boss) \
			or _boss.state() == StormGuardian.State.DEAD:
		rig.set_boss_framing(0.0, 0.0)
		return
	var distance: float = _player.global_position.distance_to(
		_boss.global_position)
	# Pleine ouverture au contact, retour progressif au-delà de 24 m.
	var weight: float = clampf(1.0 - (distance - 8.0) / 16.0, 0.0, 1.0)
	rig.set_boss_framing(BOSS_FRAMING_DISTANCE * weight,
		BOSS_FRAMING_FOV * weight)


## §16.8 — la conclusion, dans l'ordre exact du cahier des charges :
## « arrêter tous les hazards et projectiles ; animation de mort ; tempête
## qui se dissipe partiellement ; énergie cyan qui passe de violente à
## calme ; coffre final ; sauvegarde `boss_defeated` ; courte cinématique
## passable ; écran victoire ».
##
## Les hazards et l'animation de mort sont déjà coupés par le Gardien
## lui-même (`_on_died`). Ce qui reste est l'arène : le ciel, le cyan, le
## coffre, la sauvegarde, puis la main rendue au joueur.
func _on_boss_died() -> void:
	if _victory_written:
		return
	_victory_written = true
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system != null:
		var data: Dictionary = {}
		if bool(save_system.call("has_save", SAVE_SLOT)):
			data = save_system.call("load_slot", SAVE_SLOT) as Dictionary
		if data.is_empty():
			data = {"schema": 2}
		data["boss_defeated"] = true
		save_system.call("save_slot", SAVE_SLOT, data)
	# Le puits de terre se tait : plus une seule veine cyan dans l'arène.
	if _earth != null:
		_earth.enabled = false
	for pylon: GroundingPylon in _pylons:
		pylon.lower()
	if graph() != null:
		graph().mark_dirty()
		graph().recompute()
	_spawn_final_chest()
	_calming = true
	boss_defeated.emit()


## §16.8 : « coffre final ». Il naît au centre de l'arène, là où le
## Gardien s'est écroulé — on n'a pas à le chercher.
func _spawn_final_chest() -> void:
	if _final_chest != null:
		return
	_final_chest = (load(FINAL_CHEST) as PackedScene).instantiate() as Chest
	_final_chest.name = "FinalChest"
	_final_chest.chest_id = &"boss.chest.final.01"
	_final_chest.weapon_loot = load(
		"res://resources/weapons/conductive_blade.tres") as WeaponDefinition
	_final_chest.arrows_loot = 20
	_final_chest.position = Vector3(0, 0, -2.0)   # AVANT add_child (règle D.0)
	add_child(_final_chest)
	var halo: OmniLight3D = OmniLight3D.new()
	halo.name = "FinalChestGlow"
	halo.light_color = Color(0.28, 0.72, 0.72)
	halo.light_energy = 2.0
	halo.omni_range = 10.0
	halo.position = Vector3(0, 1.6, -2.0)
	add_child(halo)


## §16.8 : « tempête qui se dissipe PARTIELLEMENT », « énergie cyan qui
## passe de violente à calme ». Le ciel se réchauffe et s'éclaircit, le
## brouillard tombe — mais l'orage ne redevient pas un midi bleu : on
## reste dans la continuité dorée de §7.7.
func _calm_the_storm(delta: float) -> void:
	var weight: float = minf(1.0, delta / CALM_TIME)
	var light: DirectionalLight3D = get_node_or_null("StormLight") \
		as DirectionalLight3D
	if light != null:
		light.light_color = light.light_color.lerp(CALM_SUN, weight)
		light.light_energy = lerpf(light.light_energy, 2.0, weight)
	var world_environment: WorldEnvironment = get_node_or_null(
		"ArenaEnvironment") as WorldEnvironment
	if world_environment != null and world_environment.environment != null:
		var environment: Environment = world_environment.environment
		environment.background_color = environment.background_color.lerp(
			CALM_SKY, weight)
		environment.ambient_light_color = \
			environment.ambient_light_color.lerp(CALM_AMBIENT, weight)
		environment.fog_density = lerpf(environment.fog_density, 0.001, weight)
		environment.fog_light_color = environment.fog_light_color.lerp(
			CALM_SKY, weight)


## §16.8 : « courte cinématique passable » puis « écran victoire ». Ici la
## cinématique est le monde lui-même — on garde la main pendant que le ciel
## s'ouvre. Ouvrir le coffre final la PASSE : c'est le geste de quelqu'un
## qui a fini de regarder.
func _tick_conclusion(delta: float) -> void:
	if _victory_shown:
		return
	_conclusion_elapsed += delta
	if not conclusion_is_over():
		return
	_victory_shown = true
	if not auto_show_victory:
		return
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow == null or not bool(flow.call("can_go_to", VICTORY)):
		push_warning("[arène] écran de victoire injoignable : %s" % VICTORY)
		return
	flow.call("go_to", VICTORY)


## La cinématique est finie quand le joueur l'a regardée assez longtemps,
## OU quand il a ouvert le coffre — le geste de quelqu'un qui a fini de
## regarder. Prédicat pur : c'est lui que les tests interrogent.
func conclusion_is_over() -> bool:
	if _conclusion_elapsed >= CONCLUSION_TIME:
		return true
	return _final_chest != null and is_instance_valid(_final_chest) \
		and _final_chest.is_opened()


func _setup_lighting() -> void:
	# Ciel d'orage : la lumière vient d'en haut, froide, et les braseros du
	# pourtour tiennent le chaud/froid de §7.7 jusque dans le donjon.
	var storm: DirectionalLight3D = DirectionalLight3D.new()
	storm.name = "StormLight"
	storm.light_color = Color(0.62, 0.76, 0.88)
	storm.light_energy = 1.1
	storm.rotation = Vector3(deg_to_rad(-62.0), deg_to_rad(28.0), 0.0)
	add_child(storm)
	for i: int in range(4):
		var angle: float = _ring_angle(PYLON_INDICES[i]) + PI * 0.25
		var brazier: OmniLight3D = OmniLight3D.new()
		brazier.name = "Brazier%d" % i
		brazier.light_color = Color(1.0, 0.72, 0.38)
		brazier.light_energy = 2.4
		brazier.omni_range = 16.0
		brazier.position = Vector3(sin(angle) * 17.0, 2.6, cos(angle) * 17.0)
		add_child(brazier)
		box("BrazierStand%d" % i, brazier.position - Vector3(0, 1.6, 0),
			Vector3(0.8, 2.0, 0.8), COL_BRONZE)
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.06, 0.08, 0.12)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.28, 0.32, 0.38)
	environment.ambient_light_energy = 1.0
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.34, 0.40, 0.48)
	environment.fog_density = 0.006
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "ArenaEnvironment"
	world_environment.environment = environment
	add_child(world_environment)


## ---------------------------------------------------------------------------
## Seams — lecture seule, sauf `retry()` qui est le geste de §16.6.
## ---------------------------------------------------------------------------

func boss() -> StormGuardian:
	return _boss


func pylons() -> Array[GroundingPylon]:
	return _pylons


func rail() -> Array[ElectricNode]:
	return _rail


func earth_source() -> ElectricNode:
	return _earth


func player() -> PlayerController:
	return _player


func raised_pylons() -> int:
	var count: int = 0
	for pylon: GroundingPylon in _pylons:
		if pylon.is_raised():
			count += 1
	return count


func powered_pylons() -> int:
	var count: int = 0
	for pylon: GroundingPylon in _pylons:
		if pylon.is_powered():
			count += 1
	return count


func checkpoint_restored() -> bool:
	return _checkpoint_restored


func victory_written() -> bool:
	return _victory_written


func final_chest() -> Chest:
	return _final_chest


func is_calming() -> bool:
	return _calming


func conclusion_elapsed() -> float:
	return _conclusion_elapsed


func victory_shown() -> bool:
	return _victory_shown


## Cible de la conclusion — exposée pour les tests : la transition réelle
## s'exécute en jeu, le choix de la cible se prouve ici.
func victory_target() -> String:
	return VICTORY
