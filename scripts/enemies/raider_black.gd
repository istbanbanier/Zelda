## Briseur d'obsidienne — `raider_black` (MASTER_SPEC §12.3).
##
## Le mur qui s'ouvre : 150 PV, MASSE LOURDE en combo de 2-3 coups,
## GARDE frontale à jauge (les coups de face sont amortis jusqu'à la
## rupture — l'ouverture §12.3), résistance au stagger élevée (poise 60),
## silhouette LARGE ET BASSE. Rare, gardien d'une forte récompense.
## Ses nombres vivent dans `raider_black_default.tres` (§5.4).
class_name RaiderBlack
extends EnemyBase

## Garde frontale (§12.3) : jauge, arc, amorti, recharge.
const GUARD_MAX: float = 12.0
const GUARD_ARC_DEG: float = 60.0
const GUARD_DAMAGE_FACTOR: float = 0.25
const GUARD_REGEN_DELAY: float = 5.0
const GUARD_REGEN_RATE: float = 4.0

var _guard: float = GUARD_MAX
var _guard_regen_timer: float = 0.0
var _combo_left: int = 0


func _family_ready() -> void:
	telegraph_color = Color(0.6, 0.2, 0.7)
	# Masse lourde visible.
	var mace: MeshInstance3D = MeshInstance3D.new()
	mace.name = "MaceMesh"
	var head: BoxMesh = BoxMesh.new()
	head.size = Vector3(0.24, 0.24, 0.9)
	mace.mesh = head
	var mace_material: StandardMaterial3D = StandardMaterial3D.new()
	mace_material.albedo_color = Color(0.18, 0.16, 0.2)
	mace.material_override = mace_material
	mace.position = Vector3(0.42, 1.0, 0.4)
	_pivot.add_child(mace)


func _family_visual_mounted() -> void:
	var mace: MeshInstance3D = _pivot.get_node_or_null("MaceMesh") \
		as MeshInstance3D
	if mace == null:
		return
	var socket: BoneAttachment3D = _visual.weapon_socket()
	if socket == null:
		return
	var grip: Node3D = Node3D.new()
	grip.name = "MaceGrip"
	socket.add_child(grip)
	grip.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	grip.position = Vector3(0.0, 0.05, 0.0)
	mace.get_parent().remove_child(mace)
	grip.add_child(mace)
	mace.position = Vector3(0.0, 0.0, 0.3)
	mace.rotation = Vector3.ZERO


## Combo 2-3 coups (§12.3) : le premier coup arme 1 ou 2 enchaînements
## (déterministe par position de spawn) ; le chaînage passe par la vraie
## fenêtre de combo du contrat d'attaque, jamais par un timer parallèle.
func _family_try_attack(_distance: float) -> bool:
	if not _attack.try_attack():
		return false
	_combo_left = 1 + int(absf(_territory_origin.x * 3.0)) % 2
	return true


func _process_family_state(delta: float) -> bool:
	_update_guard(delta)
	if _state != State.ATTACK:
		return false
	# ATTACK aux mains de la famille : le combo s'enchaîne dans la fenêtre
	# du contrat ; le DERNIER coup laisse l'ouverture (recovery long).
	velocity.x = 0.0
	velocity.z = 0.0
	if _combo_left > 0 and _target_valid():
		var distance: float = global_position.distance_to(
			_target.global_position)
		if distance <= tuning.attack_reach + 0.7 and _attack.try_attack():
			_combo_left -= 1
	if not _attack.update(delta):
		_attack_cooldown = tuning.attack_cooldown
		# §12.8 : la sortie d'attaque REND le token — cette famille
		# réécrit la sortie, elle doit donc la rendre elle-même.
		_release_attack_token()
		_enter(State.CHASE)
	return true


## Garde frontale à jauge (§12.3) : ÉVALUÉE PAR TICK — l'unique attaquant
## est le joueur ; s'il est dans l'arc frontal pendant que la garde tient,
## la hurtbox amortit (multiplicateur), et chaque coup encaissé la drains.
## Rompue : STAGGER (l'ouverture), recharge après une accalmie.
func _update_guard(delta: float) -> void:
	_guard_regen_timer = maxf(0.0, _guard_regen_timer - delta)
	if _guard_regen_timer <= 0.0 and _guard < GUARD_MAX:
		_guard = minf(GUARD_MAX, _guard + GUARD_REGEN_RATE * delta)
	_hurtbox.damage_taken_multiplier = GUARD_DAMAGE_FACTOR \
		if is_guarding() else 1.0


func is_guarding() -> bool:
	if _guard <= 0.0 or _state in [State.STAGGERED, State.DEAD]:
		return false
	# La garde tient pendant l'ANNONCE de son propre coup — l'ouverture de
	# §12.3 est APRÈS le combo (actif/recovery) ou à la rupture, jamais
	# pendant le télégraphe (sinon frapper l'annonce ignorerait le mur).
	if _state == State.ATTACK \
			and _attack.phase() != AttackControllerComponent.Phase.STARTUP:
		return false
	# Le mur se dresse face à la MENACE réelle (le joueur), aggro ou pas —
	# un briseur au poste garde sa masse levée.
	var player: PlayerController = _find_player()
	if player == null:
		return false
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var forward: Vector3 = _pivot.global_transform.basis.z
	forward.y = 0.0
	if to_player.length_squared() < 0.0001 \
			or forward.length_squared() < 0.0001:
		return false
	return rad_to_deg(forward.normalized().angle_to(to_player.normalized())) \
		<= GUARD_ARC_DEG


func guard_gauge() -> float:
	return _guard


func _on_hit_received(event: DamageEvent) -> void:
	# Un coup pendant la garde la DRAINS ; la rupture ouvre (§12.3).
	if is_guarding():
		_guard = maxf(0.0, _guard - event.amount)
		_guard_regen_timer = GUARD_REGEN_DELAY
		if _guard <= 0.0:
			_attack.cancel()
			_enter(State.STAGGERED)
	super(event)
