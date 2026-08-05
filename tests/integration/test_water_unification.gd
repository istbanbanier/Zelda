## ISS-030 — l'eau de la VALLÉE parle les mêmes lois que celle du donjon
## (P2 §4.2 : « mêmes lois de matière partout »). Fail-first.
##
## Contrats : le bassin conducteur porte la matière `eau` sur son nœud
## (comme la nappe de la salle 4) ; il MOUILLE ce qui y entre même hors
## tension ; alimenté par un VRAI Arc Link (le geste de la leçon), il
## RELAIE l'électricité au métal baigné (couplage humide) sans jamais
## charger le bois ; et les deux eaux — donjon et vallée — passent par le
## MÊME composant (`WaterMatterComponent`) : l'unification est
## structurelle, pas une coïncidence de comportements.
extends GateTestCase

const METAL: String = "res://resources/materials/MAT_PROFILE_metal.tres"
const BOIS: String = "res://resources/materials/MAT_PROFILE_bois.tres"

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	await _settle(3)


func _open_basin() -> ConductiveBasin:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var basin: ConductiveBasin = ConductiveBasin.new()
	_root.add_child(basin)
	await _settle(6)
	return basin


func _prop(profile_path: String, at: Vector3) -> MaterialStateComponent:
	var body: RigidBody3D = RigidBody3D.new()
	body.freeze = true
	body.collision_layer = 128
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	shape.shape = box
	body.add_child(shape)
	var state: MaterialStateComponent = MaterialStateComponent.new()
	state.name = "MaterialState"
	state.profile = load(profile_path) as MaterialProfile
	body.add_child(state)
	body.position = at
	_root.add_child(body)
	return state


func test_the_basin_water_is_matter_and_wets_unpowered() -> void:
	var basin: ConductiveBasin = await _open_basin()
	var state: MaterialStateComponent = basin.water().get_node_or_null(
		"MaterialState") as MaterialStateComponent
	check(state != null and state.profile != null
		and state.profile.id == &"eau",
		"le bassin de la VALLÉE porte la matière eau — comme la salle 4")
	var metal: MaterialStateComponent = _prop(METAL,
		basin.to_global(Vector3(0.0, 0.4, 0.0)))
	await _settle(30)
	check(metal.is_wet(), "l'eau mouille MÊME hors tension — c'est de l'eau")
	check_equal(metal.charge(), 0.0, "…et ne relaie RIEN sans courant")
	await _teardown()


func test_a_real_link_makes_the_basin_relay_to_metal_never_wood() -> void:
	var basin: ConductiveBasin = await _open_basin()
	var player_scene: PackedScene = \
		load("res://scenes/player/Player.tscn") as PackedScene
	var player: PlayerController = player_scene.instantiate() as PlayerController
	player.position = basin.stand_point()
	_root.add_child(player)
	await _settle(4)
	var resonance: ResonanceController = player.get_node(
		"Components/ResonanceController") as ResonanceController
	var metal: MaterialStateComponent = _prop(METAL,
		basin.to_global(Vector3(0.6, 0.4, 0.0)))
	var wood: MaterialStateComponent = _prop(BOIS,
		basin.to_global(Vector3(-0.6, 0.4, 0.6)))
	await _settle(10)
	# Le GESTE de la leçon : un Arc Link source→eau alimente le circuit.
	var verdict: StringName = resonance.try_link(player, basin.source(),
		basin.water())
	check(verdict == &"linked", "Arc Link source→eau (obtenu %s)" % verdict)
	await _settle(80)
	check(basin.water().is_powered(), "l'eau est traversée par le courant")
	check(metal.charge() > 0.0,
		"le MÉTAL baigné se charge par le relais (%.2f)" % metal.charge())
	check(wood.is_wet() and wood.charge() == 0.0,
		"le BOIS est mouillé mais jamais chargé (%.2f)" % wood.charge())
	resonance.cancel_link()
	await _teardown()


func test_dungeon_and_valley_share_the_same_component() -> void:
	## L'unification est STRUCTURELLE : même classe des deux côtés.
	var basin: ConductiveBasin = await _open_basin()
	var basin_component: Node = null
	for child: Node in basin.find_children("*", "WaterMatterComponent",
			true, false):
		basin_component = child
	check(basin_component != null, "le bassin passe par WaterMatterComponent")
	await _teardown()
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var graph: ElectricGraph = ElectricGraph.new()
	_root.add_child(graph)
	var hazard: ElectricHazard = ElectricHazard.new()
	hazard.hazard_id = &"rig.unif.water"
	hazard.node_kind = ElectricNode.Kind.WATER_ZONE
	hazard.off_time = 0.0
	_root.add_child(hazard)
	await _settle(4)
	var hazard_component: Node = null
	for child: Node in hazard.find_children("*", "WaterMatterComponent",
			true, false):
		hazard_component = child
	check(hazard_component != null,
		"la nappe du donjon passe par le MÊME composant")
	await _teardown()
