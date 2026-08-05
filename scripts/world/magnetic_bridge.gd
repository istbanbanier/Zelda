## Pont magnétique (P2-4, bible §3.4) — un tablier métallique chargé que la
## Polarité POUSSE en place : le premier raccourci gagné par une opération
## du Bracelet. Diorama autonome : il apporte ses deux rives et son vide —
## le placement dans la vallée n'exige qu'un sol plat.
##
## Verrouillage : quand le tablier entre dans la zone de travée, il gèle
## (plus un corps actif — l'alignement par transform est alors légitime),
## s'aligne sur la travée, SE MET À LA TERRE (sa charge se dissipe : le
## raccourci est définitif, la Polarité le refusera désormais) et signale
## UNE fois. Aucun sondage par frame : `body_entered` fait foi.
class_name MagneticBridge
extends Node3D

signal bridge_locked()

const CYAN: Color = Color(0.133, 0.851, 0.925)
## Demi-largeur du vide (le tablier de 3 m couvre un vide de 4 m).
const GAP_HALF: float = 2.0

var _deck: RigidBody3D = null
var _deck_state: MaterialStateComponent = null
var _locked: bool = false


func _ready() -> void:
	_bank(Vector3(-6.0, -0.5, 0.0))
	_bank(Vector3(6.0, -0.5, 0.0))
	_build_deck()
	_build_lock_zone()


func deck() -> RigidBody3D:
	return _deck


func is_locked() -> bool:
	return _locked


## Centre de la travée, en monde — là où le tablier finit sa course.
func span_center() -> Vector3:
	return to_global(Vector3.ZERO)


## Où se poster pour POUSSER (repousser) : derrière le tablier, dans l'axe.
func push_stand_point() -> Vector3:
	return to_global(Vector3(-8.5, 0.1, 0.0))


func _bank(at: Vector3) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(8.0, 1.0, 6.0)
	shape.shape = box
	body.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(8.0, 1.0, 6.0)
	mesh.mesh = box_mesh
	body.add_child(mesh)
	add_child(body)
	body.position = at


func _build_deck() -> void:
	_deck = RigidBody3D.new()
	_deck.name = "TablierMetal"
	_deck.mass = 60.0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(3.0, 0.3, 2.4)
	shape.shape = box
	_deck.add_child(shape)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(3.0, 0.3, 2.4)
	mesh.mesh = box_mesh
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.38, 0.37, 0.35)
	material.metallic = 0.75
	material.roughness = 0.5
	material.emission_enabled = true
	material.emission = CYAN
	material.emission_energy_multiplier = 1.6
	mesh.material_override = material
	_deck.add_child(mesh)
	_deck_state = MaterialStateComponent.new()
	_deck_state.name = "MaterialStateComponent"
	_deck_state.profile = load("res://resources/materials/MAT_PROFILE_metal.tres") \
		as MaterialProfile
	# Il attend le joueur : la charge ne s'évapore pas.
	_deck_state.charge_decay_enabled = false
	_deck.add_child(_deck_state)
	var marker: ResonanceTargetComponent = ResonanceTargetComponent.new()
	marker.kind = &"polarity"
	_deck.add_child(marker)
	add_child(_deck)
	_deck.position = Vector3(-6.5, 0.35, 0.0)
	_deck_state.add_charge(6.0)
	# La charge SE VOIT — même patron que le ResonanceLab.
	_deck_state.charge_changed.connect(func(amount: float) -> void:
		material.emission_energy_multiplier = clampf(amount * 0.3, 0.0, 1.8))


func _build_lock_zone() -> void:
	var zone: Area3D = Area3D.new()
	zone.name = "ZoneDeVerrouillage"
	zone.monitoring = true
	zone.monitorable = false
	zone.collision_layer = 0
	zone.collision_mask = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(2.5, 1.5, 3.0)
	shape.shape = box
	zone.add_child(shape)
	add_child(zone)
	zone.position = Vector3(0.0, 0.4, 0.0)
	zone.body_entered.connect(_on_body_entered_span)


func _on_body_entered_span(body: Node3D) -> void:
	if _locked or body != _deck:
		return
	_locked = true
	_deck.freeze = true
	_deck.linear_velocity = Vector3.ZERO
	_deck.angular_velocity = Vector3.ZERO
	# Gelé : plus un corps actif — l'alignement par transform est légitime
	# (la règle P2 §1.3 n'interdit le transform que sur un body ACTIF).
	_deck.global_position = to_global(Vector3(0.0, -0.15, 0.0))
	_deck.global_rotation = global_rotation
	# Mise à la terre : le pont dépense sa charge en se verrouillant — le
	# raccourci est définitif, la Polarité répondra `pas_charge`.
	_deck_state.ground()
	bridge_locked.emit()
