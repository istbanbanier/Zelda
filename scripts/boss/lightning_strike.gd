## Éclair marqué au sol (MASTER_SPEC §16.5 : « éclairs marqués au sol
## 0,7-1,0 s AVANT impact »).
##
## La marque est la promesse, l'impact est la conséquence. Entre les deux
## il y a une fenêtre RÉELLE, mesurable — c'est ce qui sépare une attaque
## difficile d'une attaque injuste. La marque grandit et pulse : on la
## voit du coin de l'œil, sans lire un texte.
class_name LightningStrike
extends Node3D

signal struck(position: Vector3)

const COL_WARN: Color = Color(0.98, 0.55, 0.18)
const COL_CYAN: Color = Color(0.133, 0.851, 0.925)

## Délai avant impact. §16.5 : 0,7 à 1,0 s — borné ici, pas subi.
@export var telegraph: float = 0.85
@export var radius: float = 3.0
@export var damage: float = 26.0
@export var target_position: Vector3 = Vector3.ZERO

var _elapsed: float = 0.0
var _fired: bool = false
var _mark: MeshInstance3D = null
var _material: StandardMaterial3D = null
var _area: Area3D = null


func _ready() -> void:
	telegraph = clampf(telegraph, 0.7, 1.0)
	_build()
	set_physics_process(true)


func _build() -> void:
	_mark = MeshInstance3D.new()
	_mark.name = "Mark"
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.08
	_mark.mesh = cylinder
	_material = StandardMaterial3D.new()
	_material.albedo_color = COL_WARN
	_material.emission_enabled = true
	_material.emission = COL_WARN
	_material.emission_energy_multiplier = 1.2
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.albedo_color.a = 0.55
	_mark.material_override = _material
	_mark.position = Vector3(0, 0.05, 0)
	add_child(_mark)

	_area = Area3D.new()
	_area.name = "Blast"
	_area.collision_layer = 0
	_area.collision_mask = 2   # Player
	_area.monitoring = false
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	shape.position = Vector3(0, 1.0, 0)
	_area.add_child(shape)
	add_child(_area)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if not _fired:
		var ratio: float = clampf(_elapsed / maxf(0.01, telegraph), 0.0, 1.0)
		_material.emission_energy_multiplier = 1.2 + 3.0 * ratio
		_material.albedo_color = COL_WARN.lerp(COL_CYAN, ratio)
		_material.albedo_color.a = 0.45 + 0.4 * ratio
		if _elapsed >= telegraph:
			_strike()
		return
	if _elapsed >= telegraph + 0.35:
		queue_free()


func _strike() -> void:
	_fired = true
	_area.monitoring = true
	_material.albedo_color = COL_CYAN
	_material.emission_energy_multiplier = 6.0
	# Un seul relevé : l'impact est un instant, pas une zone qui persiste.
	await get_tree().physics_frame
	if not is_instance_valid(self):
		return
	for body: Node3D in _area.get_overlapping_bodies():
		var hurtboxes: Array[Node] = body.find_children("*",
			"HurtboxComponent", true, false)
		if hurtboxes.is_empty():
			continue
		var event: DamageEvent = DamageEvent.new()
		event.instigator = self
		event.team = &"enemies"
		event.damage_type = &"electric"
		event.element = &"electric"
		event.amount = damage
		event.direction = (body.global_position - global_position).normalized()
		event.position = global_position
		event.knockback = 4.0
		(hurtboxes[0] as HurtboxComponent).receive_hit(event)
	struck.emit(global_position)


func has_struck() -> bool:
	return _fired


func remaining_telegraph() -> float:
	return maxf(0.0, telegraph - _elapsed)
