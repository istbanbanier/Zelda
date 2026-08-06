## Citadelle de l'Œil-Tempête — ANTICHAMBRE du boss (§15.10).
##
## | §15.10 | ici |
## |---|---|
## | checkpoint | l'entrée SAUVEGARDE : position sûre, inventaire, circuits ; c'est le checkpoint de §19.5 « antichambre du boss » |
## | coffre garanti | `Chest` avec une lame conductrice et des flèches — pas une table de butin, un contenu certain |
## | feu ou station de cuisine | `Campfire` : l'atelier de §13.3 s'ouvre ici |
## | baies électriques | quatre `storm_berry` sur la corniche — de quoi cuisiner la résistance électrique de §13.5 |
## | possibilité de revenir | la porte sud rouvre sur la salle centrale, et rien ne la verrouille |
## | fresque bois isolant / métal conducteur | deux panneaux côte à côte : le bâton de bois laisse la ligne éteinte, la barre de métal la laisse passer — l'enseignement de §14.4 sans une ligne de texte |
## | aperçu de l'arène | une baie vitrée au nord donne sur l'arène et ses quatre pylônes |
## | aucune cinématique non passable | il n'y en a aucune |
class_name Antechamber
extends DungeonRoom

const HALL: String = "res://scenes/dungeon/rooms/CentralHall.tscn"
const ARENA: String = "res://scenes/boss/BossArena.tscn"
const WIRE_Y: float = 0.12

var _chest: Chest = null
var _campfire: Campfire = null
var _berries: Array[IngredientPickup] = []
var _checkpoint_saved: bool = false

@onready var _player: PlayerController = get_node_or_null("Player") \
	as PlayerController


func _ready() -> void:
	room_id = &"dungeon.room.antechamber.06"
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 3)  # GameState.Flow.DUNGEON
	var spawn_tag: StringName = consume_spawn_tag()
	_build_shell()
	_build_fresco()
	_build_supplies()
	_setup_lighting()
	var graph_node: ElectricGraph = ElectricGraph.new()
	graph_node.name = "Graph"
	add_child(graph_node)
	set_graph(graph_node)
	# §15.11 : outil de debug des IDs, ports, voisins et états. Il se
	# RETIRE de lui-même dans un build non-debug.
	var debug_overlay: ElectricDebugOverlay = ElectricDebugOverlay.new()
	debug_overlay.name = "ElectricDebug"
	debug_overlay.graph_path = NodePath("../Graph")
	add_child(debug_overlay)
	place_player_at_spawn(_player, spawn_tag, {
		&"antechamber_from_hall": Vector3(0, 0.3, 8.0),
		# §15.11 : on ressort de l'arène DEVANT son seuil, pas au spawn.
		&"antechamber_from_arena": Vector3(6.0, 0.3, -8.0),
	})
	# §19.5 : le checkpoint est POSÉ en entrant, pas promis.
	call_deferred("_write_checkpoint")


func _build_shell() -> void:
	box("Floor", Vector3(0, -0.5, 0), Vector3(18, 1, 20), COL_FLOOR)
	box("Ceiling", Vector3(0, 8.5, 0), Vector3(18, 1, 20), COL_STONE)
	box("WallWest", Vector3(-9.25, 4, 0), Vector3(0.5, 8, 20), COL_STONE)
	box("WallEast", Vector3(9.25, 4, 0), Vector3(0.5, 8, 20), COL_STONE)
	box("WallSouthWest", Vector3(-5.8, 4, 10.25), Vector3(6.4, 8, 0.5),
		COL_STONE)
	box("WallSouthEast", Vector3(5.8, 4, 10.25), Vector3(6.4, 8, 0.5),
		COL_STONE)
	box("WallSouthLintel", Vector3(0, 6.5, 10.25), Vector3(5.2, 3, 0.5),
		COL_STONE)
	# Nord : une baie vitrée sur l'arène (aperçu de §15.10) de x = -4 à 4,
	# fermée par un appui — on REGARDE — et, à sa droite, le seuil qui mène
	# vraiment à l'arène, de x = 4,5 à 7,5.
	box("WallNorthWest", Vector3(-6.6, 4, -10.25), Vector3(5.3, 8, 0.5),
		COL_STONE)
	box("WallNorthPier", Vector3(0, 4, -10.25), Vector3(1.2, 8, 0.5), COL_STONE)
	box("WallNorthSill", Vector3(0, 0.6, -10.25), Vector3(8, 1.2, 0.5),
		COL_STONE)
	box("WallNorthHead", Vector3(0, 6.6, -10.25), Vector3(8, 3.8, 0.5),
		COL_BRONZE)
	box("WallNorthMullion", Vector3(4.25, 4, -10.25), Vector3(0.5, 8, 0.5),
		COL_STONE)
	box("WallNorthEast", Vector3(8.4, 4, -10.25), Vector3(1.7, 8, 0.5),
		COL_STONE)
	_build_arena_preview()

	scene_door("DoorBack", "Revenir à la salle centrale", HALL,
		&"hall_from_antechamber", Vector3(0, 2.5, 10.4), Vector3(4.2, 5.0, 0.4))
	scene_door("DoorArena", "Entrer dans l'arène", ARENA,
		&"arena_from_antechamber", Vector3(6.0, 2.5, -10.4),
		Vector3(3.0, 5.0, 0.4))


## §15.10 : « aperçu de l'arène ». Derrière la baie, l'arène existe pour de
## bon — cercle, quatre pylônes de mise à la terre, ciel d'orage. Ce n'est
## pas une image peinte : c'est la géométrie que la Phase G reprendra.
func _build_arena_preview() -> void:
	box("ArenaFloor", Vector3(0, -0.7, -26.0), Vector3(38, 1, 32), COL_STONE)
	for i: int in range(4):
		var angle: float = TAU * float(i) / 4.0 + PI * 0.25
		var at: Vector3 = Vector3(sin(angle) * 13.0, 0, -26.0 + cos(angle) * 11.0)
		box("ArenaPylon%d" % i, at + Vector3(0, 3.0, 0),
			Vector3(1.4, 6.0, 1.4), COL_BRONZE)
		decor("ArenaPylonCore%d" % i, at + Vector3(0, 6.4, 0),
			Vector3(0.8, 0.8, 0.8), COL_CYAN, true)
	decor("ArenaCore", Vector3(0, 2.2, -26.0), Vector3(2.2, 4.4, 2.2),
		Color(0.18, 0.20, 0.24))
	var glow: OmniLight3D = OmniLight3D.new()
	glow.name = "ArenaGlow"
	glow.light_color = Color(0.5, 0.9, 0.95)
	glow.light_energy = 3.0
	glow.omni_range = 30.0
	glow.position = Vector3(0, 8.0, -24.0)
	add_child(glow)


## §15.10 : la fresque enseigne §14.4 par la DÉMONSTRATION. Deux socles
## identiques, deux barreaux : le bois laisse la ligne éteinte, le métal la
## laisse passer. La source de la fresque est indépendante du reste.
func _build_fresco() -> void:
	box("FrescoPanel", Vector3(-8.9, 2.6, 2.0), Vector3(0.4, 3.6, 7.0),
		Color(0.20, 0.19, 0.22))
	var fresco_source: ElectricNode = make_node(
		&"dungeon.node.antechamber_fresco_source.01", ElectricNode.Kind.SOURCE,
		Vector3(-8.5, 1.2, -0.4), [Vector3(0, 0, 0.5)], 0.55)
	fresco_source.name = "FrescoSource"
	attach_visual(fresco_source, Vector3(0.4, 0.4, 0.4), Vector3.ZERO, true)
	# Voie MÉTAL : conductrice, la ligne va jusqu'au bout.
	cable_run("FrescoMetal", Vector3(-8.5, 1.2, 0.6), Vector3(-8.5, 1.2, 2.6),
		Vector3.BACK, 3)
	var metal_end: ElectricNode = make_node(
		&"dungeon.node.antechamber_fresco_metal.01",
		ElectricNode.Kind.RECEIVER, Vector3(-8.5, 1.2, 3.6),
		[Vector3(0, 0, -0.5)], 0.6)
	metal_end.name = "FrescoMetalEnd"
	attach_visual(metal_end, Vector3(0.4, 0.6, 0.4), Vector3.ZERO, false)
	# Voie BOIS : isolante (conductivité nulle), la ligne meurt au barreau.
	cable_run("FrescoWoodA", Vector3(-8.5, 3.4, 0.6), Vector3(-8.5, 3.4, 1.6),
		Vector3.BACK, 2)
	var wood: ElectricNode = make_node(
		&"dungeon.node.antechamber_fresco_wood.01", ElectricNode.Kind.CABLE,
		Vector3(-8.5, 3.4, 2.4), [Vector3(0, 0, -0.4), Vector3(0, 0, 0.4)], 0.55)
	wood.name = "FrescoWoodBar"
	wood.conductivity = 0.0    # §14.4 : le bois n'entre pas dans le circuit
	wood.add_to_group("insulated")
	var wood_visual: ElectricVisual = ElectricVisual.new()
	wood_visual.name = "Visual"
	wood_visual.node_path = NodePath("..")
	wood_visual.mesh_path = NodePath("../Mesh")
	wood_visual.insulator = true
	var wood_mesh: MeshInstance3D = MeshInstance3D.new()
	wood_mesh.name = "Mesh"
	var wood_box: BoxMesh = BoxMesh.new()
	wood_box.size = Vector3(0.3, 0.3, 0.9)
	wood_mesh.mesh = wood_box
	wood.add_child(wood_mesh)
	wood.add_child(wood_visual)
	cable_run("FrescoWoodB", Vector3(-8.5, 3.4, 3.2), Vector3(-8.5, 3.4, 4.2),
		Vector3.BACK, 2)
	var wood_end: ElectricNode = make_node(
		&"dungeon.node.antechamber_fresco_wood_end.01",
		ElectricNode.Kind.RECEIVER, Vector3(-8.5, 3.4, 5.0),
		[Vector3(0, 0, -0.3)], 0.6)
	wood_end.name = "FrescoWoodEnd"
	attach_visual(wood_end, Vector3(0.4, 0.6, 0.4), Vector3.ZERO, false)
	# La source ne touche QUE le départ des deux voies : le fait que la
	# ligne du haut s'éteigne au barreau de bois est la leçon.
	var riser: ElectricNode = make_node(
		&"dungeon.node.antechamber_fresco_riser.01", ElectricNode.Kind.CABLE,
		Vector3(-8.5, 2.3, 0.1), [Vector3(0, -1.1, 0), Vector3(0, 1.1, 0)], 0.6)
	riser.name = "FrescoRiser"
	attach_visual(riser, Vector3(0.18, 2.2, 0.18), Vector3.ZERO, false)


## Coffre garanti, feu de cuisine, baies électriques (§15.10).
func _build_supplies() -> void:
	_chest = (load("res://scenes/interactables/Chest.tscn") as PackedScene) \
		.instantiate() as Chest
	_chest.name = "AntechamberChest"
	_chest.chest_id = &"dungeon.chest.antechamber.01"
	_chest.weapon_loot = load("res://resources/weapons/conductive_blade.tres") \
		as WeaponDefinition
	_chest.arrows_loot = 12
	_chest.position = Vector3(5.0, 0, 3.0)   # AVANT add_child (règle D.0)
	add_child(_chest)
	# Le checkpoint était écrit une seule fois, depuis `_ready()` — donc AVANT
	# que le joueur ait pu ouvrir ce coffre. L'arène restaurait ensuite cet
	# instantané en effaçant l'inventaire : la lame conductrice et les flèches
	# garanties juste ici disparaissaient au seuil du boss, et l'on affrontait
	# 560 points de vie avec l'épée de départ. On réécrit donc le checkpoint à
	# l'ouverture — ce que le test de parcours faisait à la main, sans qu'aucun
	# joueur ne puisse le faire.
	_chest.opened.connect(func(_id: StringName) -> void: _write_checkpoint())

	_campfire = Campfire.new()
	_campfire.name = "AntechamberCampfire"
	_campfire.campfire_id = &"dungeon.campfire.antechamber.01"
	_campfire.position = Vector3(-3.5, 0, 4.5)
	add_child(_campfire)
	box("CampfireRing", Vector3(-3.5, 0.25, 4.5), Vector3(1.6, 0.5, 1.6),
		Color(0.30, 0.22, 0.16))
	decor("CampfireCoals", Vector3(-3.5, 0.6, 4.5), Vector3(1.0, 0.3, 1.0),
		Color(0.98, 0.55, 0.18), true)
	var fire_light: OmniLight3D = OmniLight3D.new()
	fire_light.name = "CampfireGlow"
	fire_light.light_color = Color(1.0, 0.62, 0.28)
	fire_light.light_energy = 2.2
	fire_light.omni_range = 10.0
	fire_light.position = Vector3(-3.5, 1.4, 4.5)
	add_child(fire_light)

	var berry: IngredientDefinition = load(
		"res://resources/ingredients/storm_berry.tres") as IngredientDefinition
	for i: int in range(4):
		var pickup: IngredientPickup = IngredientPickup.new()
		pickup.name = "StormBerry%d" % i
		pickup.definition = berry
		pickup.pickup_id = StringName("dungeon.ingredient.antechamber.%02d"
			% (i + 1))
		pickup.position = Vector3(1.2 + 0.9 * float(i), 0.9, 6.2)
		add_child(pickup)
		_berries.append(pickup)
	box("BerryLedge", Vector3(2.55, 0.45, 6.2), Vector3(4.6, 0.9, 1.2),
		COL_STONE)


## §19.5 : checkpoint « antichambre du boss ». On écrit ce que le joueur
## PORTE, plus le point de reprise — jamais une position hasardeuse.
func _write_checkpoint() -> void:
	var save_system: Node = get_node_or_null("/root/SaveSystem")
	if save_system == null:
		return
	var data: Dictionary = {}
	if bool(save_system.call("has_save", SAVE_SLOT)):
		data = save_system.call("load_slot", SAVE_SLOT) as Dictionary
	if data.is_empty():
		data = {"schema": 2}
	data["checkpoint"] = "dungeon.antechamber"
	if _player != null and _player.inventory() != null:
		var inventory: InventoryComponent = _player.inventory()
		var weapons: Array[Dictionary] = []
		for weapon: WeaponInstance in inventory.weapons():
			weapons.append({
				"id": String(weapon.definition_id()),
				"durability": weapon.current_durability,
			})
		data["weapons"] = weapons
		data["equipped_index"] = inventory.equipped_index()
		data["arrows"] = inventory.arrows()
		data["ingredients"] = inventory.ingredients_snapshot()
		data["meals"] = inventory.meals_snapshot()
	_checkpoint_saved = bool(save_system.call("save_slot", SAVE_SLOT, data))


func _setup_lighting() -> void:
	for i: int in range(2):
		var warm: OmniLight3D = OmniLight3D.new()
		warm.name = "AnteGlow%d" % i
		warm.light_color = Color(1.0, 0.74, 0.42)
		warm.light_energy = 2.2
		warm.omni_range = 14.0
		warm.position = Vector3(-6.0 if i == 0 else 6.0, 3.6, 7.0)
		add_child(warm)
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.06, 0.09)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.26, 0.29, 0.34)
	environment.ambient_light_energy = 1.0
	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.name = "RoomEnvironment"
	world_environment.environment = environment
	add_child(world_environment)


func chest() -> Chest:
	return _chest


func campfire() -> Campfire:
	return _campfire


func berries() -> Array[IngredientPickup]:
	return _berries


func checkpoint_written() -> bool:
	return _checkpoint_saved


func player() -> PlayerController:
	return _player
