## Flèche (MASTER_SPEC §10.4, §5.3).
##
## Balistique **par balayage** : à chaque tick, un rayon couvre exactement le
## segment parcouru — le CCD que §5.3 exige pour les projectiles rapides, sans
## tunneling possible, quelle que soit la vitesse. Une `RigidBody3D` aurait le
## CCD mais ne détecterait pas les hurtbox (`Area3D`) ; le rayon fait les deux
## (`collide_with_areas`).
##
## Poolée (§10.4, §20.6) : `BowComponent` la réutilise, elle ne s'instancie
## jamais en rafale. `top_level` : sa position est mondiale, pas relative à
## l'arc qui la porte.
class_name ArrowProjectile
extends Node3D

signal arrow_hit(event: DamageEvent, target: HurtboxComponent)

## Couches balayées : décor (1) + hurtbox (32).
const SWEEP_MASK: int = 1 | 32

var _velocity: Vector3 = Vector3.ZERO
var _gravity: float = 12.0
var _damage: float = 9.0
var _team: StringName = &""
var _instigator: Node = null
var _exclude: Array[RID] = []
var _lifetime: float = 0.0
var _remaining: float = 0.0
var _active: bool = false


func _ready() -> void:
	top_level = true
	visible = false
	set_physics_process(false)


func launch(origin: Vector3, direction: Vector3, speed: float, gravity: float,
		damage: float, team: StringName, instigator: Node,
		exclude: Array[RID], lifetime: float) -> void:
	global_position = origin
	_velocity = direction.normalized() * speed
	_gravity = gravity
	_damage = damage
	_team = team
	_instigator = instigator
	_exclude = exclude
	_lifetime = lifetime
	_remaining = lifetime
	_active = true
	visible = true
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		deactivate()
		return

	# §10.4 : « gravité modérée » — la trajectoire tombe, l'arc se compense.
	_velocity.y -= _gravity * delta
	var from: Vector3 = global_position
	var to: Vector3 = from + _velocity * delta

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		from, to, SWEEP_MASK, _exclude)
	query.collide_with_areas = true
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = to
		return

	global_position = hit["position"]
	var hurtbox: HurtboxComponent = hit.get("collider") as HurtboxComponent
	if hurtbox != null and hurtbox.team != _team:
		var event: DamageEvent = DamageEvent.new()
		event.instigator = _instigator
		event.team = _team
		event.damage_type = &"arrow"
		# Côté défenseur au contact, comme la hitbox (§10.3) : le point faible du
		# troll se touchera à l'arc aussi.
		event.amount = DamageFormula.compute(_damage, hurtbox.weak_point_multiplier)
		event.knockback = 1.0
		event.attack_id = HitboxComponent.next_attack_id()
		event.position = global_position
		var flat: Vector3 = _velocity
		flat.y = 0.0
		event.direction = flat.normalized() if flat.length_squared() > 0.0001 else Vector3.ZERO
		hurtbox.receive_hit(event)
		arrow_hit.emit(event, hurtbox)
	# Mur comme chair : la flèche s'arrête au premier contact. Une flèche ne
	# traverse jamais sa première victime (§10.1 par construction : elle meurt).
	deactivate()


func deactivate() -> void:
	_active = false
	visible = false
	set_physics_process(false)


func is_active() -> bool:
	return _active


## Exposé pour les tests : la trajectoire est observable.
func velocity() -> Vector3:
	return _velocity
