## Arc (MASTER_SPEC §10.4).
##
## Tire des flèches poolées depuis la POITRINE du tireur. L'origine n'avance
## jamais d'un centimètre dans la direction du tir : c'est la garantie
## anti-tir-à-travers-mur de §10.4 — le balayage de la flèche part de l'intérieur
## du corps (RID exclus) et rencontre donc TOUT obstacle entre le tireur et la
## cible, y compris le mur qu'on étreint. Avancer l'origine « pour faire joli »
## ferait apparaître la flèche de l'autre côté d'une paroi mince.
##
## La direction, elle, vient de la caméra, corrigée vers l'origine (§10.4 :
## « point caméra corrigé vers origine arc ») — c'est l'appelant qui la calcule.
class_name BowComponent
extends Node3D

signal arrow_fired(arrow: ArrowProjectile)

@export var tuning: BowTuning

var _pool: Array[ArrowProjectile] = []
var _cooldown: float = 0.0


func _ready() -> void:
	if tuning == null:
		tuning = BowTuning.new()
		push_warning("[bow] aucun BowTuning assigné — valeurs par défaut utilisées.")
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown = 0.0
		set_physics_process(false)


## Tire si la cadence le permet. `exclude` doit contenir le corps ET la hurtbox
## du tireur — le balayage part de l'intérieur de sa capsule.
func try_fire(origin: Vector3, direction: Vector3, team: StringName,
		instigator: Node, exclude: Array[RID]) -> bool:
	if _cooldown > 0.0 or tuning == null:
		return false
	var arrow: ArrowProjectile = _acquire_arrow()
	if arrow == null:
		return false  # pool épuisé : §20.6 interdit d'instancier en rafale
	arrow.launch(origin, direction, tuning.arrow_speed, tuning.arrow_gravity,
		tuning.base_damage, team, instigator, exclude, tuning.lifetime)
	_cooldown = tuning.shot_cooldown
	set_physics_process(true)
	arrow_fired.emit(arrow)
	return true


## Réutilise une flèche inactive ; n'instancie qu'à concurrence du pool (§10.4).
func _acquire_arrow() -> ArrowProjectile:
	for arrow: ArrowProjectile in _pool:
		if not arrow.is_active():
			return arrow
	if _pool.size() >= tuning.pool_size:
		return null
	var fresh: ArrowProjectile = ArrowProjectile.new()
	_pool.append(fresh)
	add_child(fresh)
	return fresh


## Exposés pour les tests et le futur HUD de munitions (§17.2).
func pool_count() -> int:
	return _pool.size()


func active_arrows() -> Array[ArrowProjectile]:
	var active: Array[ArrowProjectile] = []
	for arrow: ArrowProjectile in _pool:
		if arrow.is_active():
			active.append(arrow)
	return active
