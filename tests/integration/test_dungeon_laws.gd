## P2-5 tranche 3 — l'eau du donjon parle les LOIS COMMUNES (P2 §4.2,
## §9.2) : la nappe d'une `WATER_ZONE` porte la matière `eau`, MOUILLE ce
## qui y entre, et sous tension RELAIE l'électricité à la matière qu'elle
## baigne — même loi que le bassin de la vallée : l'eau traverse, elle ne
## stocke pas. Fail-first : écrit avant l'implémentation.
##
## Contrats : le métal baigné est mouillé PUIS chargé (couplage humide des
## lois) ; le bois est mouillé, jamais chargé ; une eau hors tension
## mouille mais ne relaie rien ; une eau mise à la terre SUSPEND le relais
## (dissipation) ; le chemin de dégâts du joueur (§13.5) est INTACT ; et
## la salle 4 réelle porte cette matière — pas seulement un banc.
extends GateTestCase

const EAU: String = "res://resources/materials/MAT_PROFILE_eau.tres"
const METAL: String = "res://resources/materials/MAT_PROFILE_metal.tres"
const BOIS: String = "res://resources/materials/MAT_PROFILE_bois.tres"
const ROOM4: String = "res://scenes/dungeon/rooms/Room4Battery.tscn"

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
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(3)


## Banc minimal : graphe + source (optionnelle) + nappe WATER_ZONE
## continue (off_time 0). Les ports source/nappe se touchent.
func _rig(powered: bool = true) -> ElectricHazard:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var graph: ElectricGraph = ElectricGraph.new()
	graph.name = "Graph"
	_root.add_child(graph)
	if powered:
		var source: ElectricNode = ElectricNode.new()
		source.name = "Source"
		source.node_id = &"rig.laws.source"
		source.kind = ElectricNode.Kind.SOURCE
		source.port_offsets = [Vector3(0, 0, 0.5)]
		source.port_reach = 0.55
		source.position = Vector3(0, 0, -1.0)
		_root.add_child(source)
	var water: ElectricHazard = ElectricHazard.new()
	water.name = "Water"
	water.hazard_id = &"rig.laws.water"
	water.node_kind = ElectricNode.Kind.WATER_ZONE
	water.on_time = 1.0
	water.off_time = 0.0
	water.damage = 6.0
	water.damage_interval = 0.2
	water.area_size = Vector3(4.0, 2.0, 4.0)
	water.area_offset = Vector3.ZERO
	water.node_port_offsets = [Vector3(0, 0, -0.5)]
	water.node_port_reach = 0.55
	_root.add_child(water)
	return water


func _prop(profile_path: String, at: Vector3) -> MaterialStateComponent:
	var body: RigidBody3D = RigidBody3D.new()
	body.freeze = true
	body.collision_layer = 128
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.6, 0.6, 0.6)
	shape.shape = box
	body.add_child(shape)
	var state: MaterialStateComponent = MaterialStateComponent.new()
	state.name = "MaterialState"
	state.profile = load(profile_path) as MaterialProfile
	body.add_child(state)
	body.position = at
	_root.add_child(body)
	return state


func test_powered_water_soaks_then_charges_metal_by_the_laws() -> void:
	var water: ElectricHazard = _rig(true)
	var metal: MaterialStateComponent = _prop(METAL, Vector3.ZERO)
	# Alimentation, décharge continue, entrée, puis ≥ 2 impulsions (0,2 s).
	await _settle(40)
	check(water.is_discharging(), "la nappe alimentée décharge en continu")
	check(metal.is_wet(), "le métal baigné est MOUILLÉ (l'eau mouille)")
	check(metal.charge() > 0.0,
		"…puis CHARGÉ par le relais des lois (%.2f)" % metal.charge())
	await _teardown()


func test_wood_is_soaked_but_never_charged() -> void:
	var water: ElectricHazard = _rig(true)
	var wood: MaterialStateComponent = _prop(BOIS, Vector3.ZERO)
	await _settle(50)
	check(water.is_discharging(), "la nappe décharge")
	check(wood.is_wet(), "le bois est mouillé")
	check_equal(wood.charge(), 0.0,
		"…mais JAMAIS chargé (capacité nulle : il ne stocke pas)")
	await _teardown()


func test_unpowered_water_wets_but_relays_nothing() -> void:
	var water: ElectricHazard = _rig(false)
	var metal: MaterialStateComponent = _prop(METAL, Vector3.ZERO)
	await _settle(40)
	check(not water.is_discharging(), "sans source : pas de décharge")
	check(metal.is_wet(), "l'eau mouille MÊME hors tension — c'est de l'eau")
	check_equal(metal.charge(), 0.0, "…et ne relaie RIEN sans courant")
	await _teardown()


func test_grounded_water_pauses_the_relay() -> void:
	var water: ElectricHazard = _rig(true)
	var metal: MaterialStateComponent = _prop(METAL, Vector3.ZERO)
	await _settle(40)
	check(metal.charge() > 0.0, "le relais nourrit d'abord (%.2f)"
		% metal.charge())
	# ISS-030 : l'état de matière vit sur le NŒUD (unifié vallée/donjon).
	var water_state: MaterialStateComponent = water.node().get_node_or_null(
		"MaterialState") as MaterialStateComponent
	check(water_state != null, "la nappe PORTE la matière eau")
	if water_state == null:
		await _teardown()
		return
	water_state.ground()
	var before: float = metal.charge()
	# 0,5 s dans la fenêtre de terre (1,2 s) : aucune impulsion ne passe —
	# la décroissance naturelle du métal peut seulement faire BAISSER.
	await _settle(30)
	check(metal.charge() <= before,
		"terre : le relais est SUSPENDU (%.2f → %.2f)"
		% [before, metal.charge()])
	await _teardown()


func test_the_player_damage_path_is_untouched() -> void:
	var water: ElectricHazard = _rig(true)
	var victim: CharacterBody3D = CharacterBody3D.new()
	victim.collision_layer = 2
	victim.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	shape.shape = capsule
	victim.add_child(shape)
	var health: HealthComponent = HealthComponent.new()
	health.name = "Health"
	health.max_health = 100.0
	victim.add_child(health)
	var hurtbox: HurtboxComponent = HurtboxComponent.new()
	hurtbox.name = "Hurtbox"
	hurtbox.team = &"player"
	hurtbox.health_path = NodePath("../Health")
	victim.add_child(hurtbox)
	victim.position = Vector3.ZERO
	_root.add_child(victim)
	health.revive(100.0)
	await _settle(40)
	check(water.is_discharging(), "la nappe décharge")
	check(health.current() < 100.0,
		"le chemin de dégâts §13.5 est INTACT (%.1f PV)" % health.current())
	await _teardown()


func test_room4_water_carries_the_matter_of_the_laws() -> void:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var room: Room4Battery = (load(ROOM4) as PackedScene).instantiate() \
		as Room4Battery
	_root.add_child(room)
	await _settle(8)
	# ISS-030 : l'état de matière vit sur le NŒUD (unifié vallée/donjon).
	var water_state: MaterialStateComponent = room.water().node() \
		.get_node_or_null("MaterialState") as MaterialStateComponent
	check(water_state != null and water_state.profile != null \
		and water_state.profile.id == &"eau",
		"la nappe de la SALLE 4 porte la matière eau — pas seulement un banc")
	var plank_matter: MaterialStateComponent = room.plank().get_node_or_null(
		"MaterialState") as MaterialStateComponent
	check(plank_matter != null and plank_matter.profile != null \
		and plank_matter.profile.id == &"bois",
		"la planche est du BOIS aux yeux des lois")
	check(ReactionSystem.locate(_tree()) != null,
		"un arbitre des réactions EXISTE dans la salle")
	await _teardown()
