## ResonanceLab (P2 §14.2) — vitrine jouable des cinq opérations du Bracelet.
## Lancement : godot --path . scenes/tests/ResonanceLab.tscn
##
## Contrôles : A = Pulse · G tenu + molette + clic G = focus/cycle/confirmer
## (ancrage → Arc Step, port → lien en deux temps, bloc métal → Polarité,
## sprint tenu = repousser) · T = Ground direct sur l'objet chargé le plus
## proche. Tout est construit ici, par code : géométrie de test uniquement.
##
## Retours visuels de LAB (pas la passe VFX finale) : émission cyan pilotée
## par les états réels — charge, révélation, alimentation — via les signaux
## des composants, jamais par sondage par frame.
class_name ResonanceLab
extends Node3D

const CYAN: Color = Color(0.133, 0.851, 0.925)
const PLAYER_SCENE: String = "res://scenes/player/Player.tscn"

## Le bloc de Polarité perd sa charge (décroissance des lois) : le lab la
## réamorce périodiquement pour rester exerçable — commodité de laboratoire,
## documentée, jamais présente en jeu.
const RECHARGE_INTERVAL: float = 6.0

var _recharge_timer: float = 0.0
var _rechargeable: Array[MaterialStateComponent] = []


func _ready() -> void:
	_build_floor()
	_build_pulse_zone()
	_build_link_zone()
	_build_polarity_zone()
	_build_arc_step_zone()
	_build_ground_zone()
	_spawn_player()
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -30.0, 0.0)
	add_child(sun)
	var overlay: LabOverlay = LabOverlay.new()
	overlay.top_left = Vector2(480.0, 12.0)
	add_child(overlay)


func _physics_process(delta: float) -> void:
	_recharge_timer -= delta
	if _recharge_timer > 0.0:
		return
	_recharge_timer = RECHARGE_INTERVAL
	for state: MaterialStateComponent in _rechargeable:
		if is_instance_valid(state) and not state.is_charged():
			state.add_charge(5.0)


## --- Construction ---

func _build_floor() -> void:
	# Sol principal, puis une fosse : la traversée de la fosse est la démo
	# d'Arc Step — le sol s'arrête à z=-14, reprend à z=-18.
	_static_box(Vector3(0.0, -0.5, 3.0), Vector3(44.0, 1.0, 34.0))
	_static_box(Vector3(0.0, -0.5, -21.0), Vector3(44.0, 1.0, 6.0))


func _build_pulse_zone() -> void:
	# Trois cibles : deux à découvert, une derrière un muret (le Pulse la
	# refuse — démonstration de la LOS).
	_pulse_target(Vector3(-6.0, 0.8, -4.0))
	_pulse_target(Vector3(-8.0, 0.8, 0.0))
	_static_box(Vector3(-10.0, 1.5, -3.0), Vector3(3.0, 3.0, 0.4))
	_pulse_target(Vector3(-10.0, 0.8, -5.0))


func _build_link_zone() -> void:
	var graph: ElectricGraph = ElectricGraph.new()
	add_child(graph)
	var source: ElectricNode = _electric(ElectricNode.Kind.SOURCE,
		&"lab.resonance.source.01", Vector3(6.0, 0.6, -6.0))
	var receiver: ElectricNode = _electric(ElectricNode.Kind.RECEIVER,
		&"lab.resonance.receiver.01", Vector3(12.0, 0.6, -6.0))
	_port_marker(source)
	_port_marker(receiver)
	_lamp_for(source, Color(1.0, 0.75, 0.3))
	_lamp_for(receiver, CYAN)


func _build_polarity_zone() -> void:
	var block: RigidBody3D = _metal_block(Vector3(8.0, 0.6, 4.0))
	var marker: ResonanceTargetComponent = ResonanceTargetComponent.new()
	marker.kind = &"polarity"
	block.add_child(marker)


func _build_arc_step_zone() -> void:
	# L'ancrage est de l'autre côté de la fosse (z=-14 → -18) : la seule
	# façon d'y aller sans détour est l'Arc Step.
	var holder: Node3D = Node3D.new()
	add_child(holder)
	holder.global_position = Vector3(0.0, 0.9, -20.0)
	var anchor: ResonanceTargetComponent = ResonanceTargetComponent.new()
	anchor.kind = &"arc_anchor"
	holder.add_child(anchor)
	var pylon: MeshInstance3D = MeshInstance3D.new()
	var cone: CylinderMesh = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.3
	cone.height = 1.6
	pylon.mesh = cone
	pylon.material_override = _emissive(CYAN, 1.6)
	holder.add_child(pylon)


func _build_ground_zone() -> void:
	var block: RigidBody3D = _metal_block(Vector3(-4.0, 0.6, 6.0))
	block.freeze = true


## --- Aides ---

func _spawn_player() -> void:
	var scene: PackedScene = load(PLAYER_SCENE) as PackedScene
	if scene == null:
		return
	var player: PlayerController = scene.instantiate() as PlayerController
	add_child(player)
	player.global_position = Vector3(0.0, 1.0, 8.0)


func _static_box(at: Vector3, size: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	body.add_child(mesh)
	add_child(body)
	body.global_position = at


func _pulse_target(at: Vector3) -> void:
	var holder: Node3D = Node3D.new()
	add_child(holder)
	holder.global_position = at
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
	# Révélé → la sphère s'allume le temps de la révélation ; retour à
	# l'extinction au signal de fin. Aucune interrogation par frame.
	target.revealed.connect(func(_duration: float) -> void:
		material.emission_energy_multiplier = 2.2)
	target.reveal_ended.connect(func() -> void:
		material.emission_energy_multiplier = 0.0)


func _electric(kind: ElectricNode.Kind, id: StringName, at: Vector3) -> ElectricNode:
	var node: ElectricNode = ElectricNode.new()
	node.kind = kind
	node.node_id = id
	add_child(node)
	node.global_position = at
	return node


func _port_marker(node: ElectricNode) -> void:
	var marker: ResonanceTargetComponent = ResonanceTargetComponent.new()
	marker.kind = &"port"
	node.add_child(marker)


func _lamp_for(node: ElectricNode, tint: Color) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(0.6, 1.2, 0.6)
	mesh.mesh = box
	var material: StandardMaterial3D = _emissive(tint,
		1.8 if node.kind == ElectricNode.Kind.SOURCE else 0.0)
	mesh.material_override = material
	node.add_child(mesh)
	node.power_changed.connect(func(powered: bool, _power: float) -> void:
		material.emission_energy_multiplier = 1.8 if powered else 0.0)


func _metal_block(at: Vector3) -> RigidBody3D:
	var block: RigidBody3D = RigidBody3D.new()
	block.mass = 40.0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.8, 0.8, 0.8)
	shape.shape = box
	block.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(0.8, 0.8, 0.8)
	mesh.mesh = box_mesh
	var material: StandardMaterial3D = _emissive(CYAN, 0.0)
	mesh.material_override = material
	block.add_child(mesh)
	var profile: MaterialProfile = load(
		"res://resources/materials/MAT_PROFILE_metal.tres") as MaterialProfile
	var state: MaterialStateComponent = MaterialStateComponent.new()
	state.profile = profile
	block.add_child(state)
	add_child(block)
	block.global_position = at
	state.add_charge(5.0)
	_rechargeable.append(state)
	# La charge se VOIT : émission proportionnelle à l'état réel.
	state.charge_changed.connect(func(amount: float) -> void:
		material.emission_energy_multiplier = clampf(amount * 0.4, 0.0, 2.0))
	material.emission_energy_multiplier = 2.0
	return block


func _emissive(tint: Color, energy: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.35, 0.37, 0.4)
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = energy
	return material
