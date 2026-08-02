## Chasseur quadrupède — `centaur_hunter` (MASTER_SPEC §12.5).
##
## Le duel FACULTATIF : ~650 PV, créature centauroïde ORIGINALE (corps
## bas quadrupède allongé + torse haut — la silhouette la plus large et
## la plus longue du bestiaire), territoire dangereux SIGNALÉ dont il
## n'INTERDIT pas la sortie : à la frontière, il abandonne (le socle).
##
## Quatre comportements propres :
## - CRI d'annonce (§12.5) avant toute attaque majeure — pause sonore et
##   visuelle qui prévient le joueur ;
## - CHARGE rapide EN LIGNE, télégraphiée, qui s'arrête au contact, au
##   mur ou en bout de course ;
## - SALVE d'arc à cadence PLAFONNÉE (3 flèches espacées, puis un long
##   repos) ;
## - REPOSITIONNEMENT CIRCULAIRE à moyenne distance (il tourne autour de
##   sa proie au lieu de foncer).
class_name CentaurHunter
extends EnemyBase

## Cri : durée de l'annonce avant une attaque majeure (charge/salve).
const ROAR_TIME: float = 0.8
## Charge : bande d'engagement, vitesse, durée maximale, cadence.
const CHARGE_MIN: float = 6.0
const CHARGE_MAX: float = 22.0
const CHARGE_SPEED: float = 15.0
const CHARGE_MAX_TIME: float = 1.6
const CHARGE_COOLDOWN: float = 7.0
const CHARGE_DAMAGE: float = 26.0
const CHARGE_HIT_RADIUS: float = 2.0
## Salve d'arc : bande, nombre, espacement, repos (cadence plafonnée).
const VOLLEY_MIN: float = 10.0
const VOLLEY_MAX: float = 30.0
const VOLLEY_ARROWS: int = 3
const VOLLEY_SPACING: float = 0.45
const VOLLEY_COOLDOWN: float = 5.0
const ARROW_SPEED: float = 34.0
const ARROW_GRAVITY: float = 6.0
const ARROW_DAMAGE: float = 12.0
## Orbite : bande où il TOURNE autour de la proie.
const ORBIT_MIN: float = 4.0
const ORBIT_MAX: float = 9.0
const ORBIT_BLEND: float = 0.8

enum Move { NONE, ROAR_CHARGE, CHARGE, ROAR_VOLLEY, VOLLEY }

var _move: Move = Move.NONE
var _move_timer: float = 0.0
var _charge_cooldown: float = 0.0
var _volley_cooldown: float = 0.0
var _charge_direction: Vector3 = Vector3.ZERO
var _charge_hit: bool = false
var _arrows_left: int = 0
var _arrow_timer: float = 0.0
var _orbit_side: float = 1.0
var _arrows: Array[ArrowProjectile] = []
var _arrow_index: int = 0


func _family_ready() -> void:
	telegraph_color = Color(1.0, 0.75, 0.15)
	_orbit_side = 1.0 if int(absf(global_position.z * 5.0)) % 2 == 0 else -1.0
	# Pool de flèches (§10.4, §20.6) : jamais d'instanciation en rafale.
	for i: int in range(VOLLEY_ARROWS + 1):
		var arrow: ArrowProjectile = ArrowProjectile.new()
		arrow.name = "HunterArrow%d" % i
		add_child(arrow)
		var mesh: MeshInstance3D = MeshInstance3D.new()
		var shaft: BoxMesh = BoxMesh.new()
		shaft.size = Vector3(0.05, 0.05, 0.7)
		mesh.mesh = shaft
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(0.85, 0.78, 0.55)
		mesh.material_override = material
		arrow.add_child(mesh)
		_arrows.append(arrow)


func _attack_token_kind() -> StringName:
	return &"heavy"


## Les manœuvres majeures ont la MAIN : cri, charge, salve. Hors
## manœuvre, l'orbite remplace l'approche frontale à moyenne distance.
func _process_family_state(delta: float) -> bool:
	_charge_cooldown = maxf(0.0, _charge_cooldown - delta)
	_volley_cooldown = maxf(0.0, _volley_cooldown - delta)
	if _move != Move.NONE:
		_process_move(delta)
		return true
	if _state != State.CHASE or not _target_valid():
		return false
	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	# Salve à longue distance, charge à moyenne : deux annonces distinctes.
	if distance >= VOLLEY_MIN and distance <= VOLLEY_MAX \
			and _volley_cooldown <= 0.0:
		_begin_move(Move.ROAR_VOLLEY)
		return true
	if distance >= CHARGE_MIN and distance <= CHARGE_MAX \
			and _charge_cooldown <= 0.0:
		_begin_move(Move.ROAR_CHARGE)
		return true
	return false


func _begin_move(move: Move) -> void:
	_move = move
	_move_timer = ROAR_TIME
	velocity.x = 0.0
	velocity.z = 0.0


func _process_move(delta: float) -> void:
	_move_timer -= delta
	match _move:
		Move.ROAR_CHARGE, Move.ROAR_VOLLEY:
			# Cri : immobile, ORIENTÉ vers la proie — le joueur a le temps
			# de lire l'annonce (§12.5).
			velocity.x = 0.0
			velocity.z = 0.0
			if _target_valid():
				var to_target: Vector3 = _target.global_position - global_position
				to_target.y = 0.0
				_face(to_target, delta)
			if _move_timer <= 0.0:
				if _move == Move.ROAR_CHARGE:
					_start_charge()
				else:
					_start_volley()
		Move.CHARGE:
			_process_charge(delta)
		Move.VOLLEY:
			_process_volley(delta)


## Charge EN LIGNE : la direction est FIGÉE au départ (§12.5 « charge
## rapide en ligne lisible ») — elle ne suit pas la proie, on l'esquive.
func _start_charge() -> void:
	_move = Move.CHARGE
	_move_timer = CHARGE_MAX_TIME
	_charge_hit = false
	_charge_cooldown = CHARGE_COOLDOWN
	var to_target: Vector3 = Vector3.ZERO
	if _target_valid():
		to_target = _target.global_position - global_position
		to_target.y = 0.0
	_charge_direction = direction_or_zero(to_target)


## `delta` n'est pas consommé ici : le décompte de la charge se fait dans
## `_process_move`, ce corps ne pose que la vitesse et l'impact.
func _process_charge(_delta: float) -> void:
	velocity.x = _charge_direction.x * CHARGE_SPEED
	velocity.z = _charge_direction.z * CHARGE_SPEED
	if not _charge_hit and _target_valid():
		var flat: Vector3 = _target.global_position - global_position
		flat.y = 0.0
		if flat.length() <= CHARGE_HIT_RADIUS:
			_charge_hit = true
			_deal_charge_damage()
	# Fin : temps écoulé, ou mur (le corps ne progresse plus).
	if _move_timer <= 0.0 or (is_on_wall() and _move_timer < CHARGE_MAX_TIME - 0.1):
		_move = Move.NONE
		_attack_cooldown = tuning.attack_cooldown


func _deal_charge_damage() -> void:
	var hurtbox: HurtboxComponent = _target.get_node_or_null("Hurtbox") \
		as HurtboxComponent
	if hurtbox == null:
		return
	var event: DamageEvent = DamageEvent.new()
	event.amount = CHARGE_DAMAGE
	event.poise_damage = 30.0
	event.knockback = 6.0
	event.instigator = self
	event.team = &"enemies"
	var flat: Vector3 = _target.global_position - global_position
	flat.y = 0.0
	event.direction = direction_or_zero(flat)
	hurtbox.receive_hit(event)


## Salve : trois flèches ESPACÉES puis un long repos — la cadence est
## plafonnée par construction (§12.5 « salve d'arc avec cadence »).
func _start_volley() -> void:
	_move = Move.VOLLEY
	_arrows_left = VOLLEY_ARROWS
	_arrow_timer = 0.0
	_volley_cooldown = VOLLEY_COOLDOWN


func _process_volley(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if _target_valid():
		var to_target: Vector3 = _target.global_position - global_position
		to_target.y = 0.0
		_face(to_target, delta)
	_arrow_timer -= delta
	if _arrow_timer <= 0.0:
		_shoot_arrow()
		_arrows_left -= 1
		_arrow_timer = VOLLEY_SPACING
	if _arrows_left <= 0:
		_move = Move.NONE


func _shoot_arrow() -> void:
	if not _target_valid() or _arrows.is_empty():
		return
	var forward: Vector3 = _pivot.global_transform.basis.z
	forward.y = 0.0
	forward = direction_or_zero(forward)
	var origin: Vector3 = global_position + Vector3.UP * 1.9 + forward * 1.4
	var to_target: Vector3 = (_target.global_position + Vector3.UP * 1.0) \
		- origin
	var distance: float = to_target.length()
	var direction: Vector3 = (to_target
		+ Vector3.UP * (ARROW_GRAVITY * distance * distance)
			/ (2.0 * ARROW_SPEED * ARROW_SPEED)).normalized()
	var arrow: ArrowProjectile = _arrows[_arrow_index % _arrows.size()]
	_arrow_index += 1
	arrow.launch(origin, direction, ARROW_SPEED, ARROW_GRAVITY, ARROW_DAMAGE,
		&"enemies", self, [get_rid()], 3.0)


## §12.5 : « repositionnement circulaire » — dans sa bande d'orbite, il
## TOURNE autour de la proie plutôt que de foncer dessus.
func _family_chase_velocity(direction: Vector3, distance: float) -> Vector3:
	if distance >= ORBIT_MIN and distance <= ORBIT_MAX:
		var orbit: Vector3 = direction.cross(Vector3.UP) * _orbit_side
		var blended: Vector3 = direction * (1.0 - ORBIT_BLEND) \
			+ orbit * ORBIT_BLEND
		return direction_or_zero(blended) * tuning.pursuit_speed
	return direction * tuning.pursuit_speed


## Le cri et la charge rougeoient comme une annonce d'attaque (§10.5).
func _is_telegraphing() -> bool:
	return super() or _move == Move.ROAR_CHARGE or _move == Move.ROAR_VOLLEY


## Seams de test.
func current_move() -> Move:
	return _move


func is_roaring() -> bool:
	return _move == Move.ROAR_CHARGE or _move == Move.ROAR_VOLLEY


func arrows_left_in_volley() -> int:
	return _arrows_left


func volley_cooldown_left() -> float:
	return _volley_cooldown
