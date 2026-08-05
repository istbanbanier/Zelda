## P2-3 — Garde et déviation parfaite (P2 §7.4). Fail-first : écrit avant
## l'implémentation.
##
## Contrats : la garde tenue BLOQUE un coup FRONTAL (dégâts réduits, endurance
## payée, aucune réaction HURT) ; un coup dans le DOS traverse entièrement ;
## la déviation PARFAITE (appui dans la fenêtre de 0,12 s avant l'impact)
## annule tout et ouvre Clarity ; à jauge vide, GuardBreak — tout passe, la
## réaction reprend ; un appui trop précoce redevient garde ordinaire.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"

var _root: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	_player = null
	_intent = null


func _setup() -> bool:
	var tree: SceneTree = _tree()
	if tree == null:
		return false
	_root = Node3D.new()
	tree.root.add_child(_root)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, 40.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	_root.add_child(floor_body)
	var player_scene: PackedScene = load(PLAYER) as PackedScene
	if player_scene == null:
		return false
	_player = player_scene.instantiate() as PlayerController
	_root.add_child(_player)
	_player.global_position = Vector3(0.0, 1.0, 0.0)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	return true


func _hurtbox() -> HurtboxComponent:
	return _player.get_node("Hurtbox") as HurtboxComponent


func _stamina() -> StaminaComponent:
	return _player.get_node("Components/StaminaComponent") as StaminaComponent


## Coup frontal : le modèle au repos fait face à +Z — l'attaquant est en +Z,
## le recul (attaquant→joueur) pointe donc vers -Z.
func _frontal_blow(amount: float) -> DamageEvent:
	var blow: DamageEvent = DamageEvent.new()
	blow.amount = amount
	blow.direction = Vector3(0.0, 0.0, -1.0)
	blow.knockback = 4.0
	blow.attack_id = HitboxComponent.next_attack_id()
	return blow


func _back_blow(amount: float) -> DamageEvent:
	var blow: DamageEvent = DamageEvent.new()
	blow.amount = amount
	blow.direction = Vector3(0.0, 0.0, 1.0)
	blow.knockback = 4.0
	blow.attack_id = HitboxComponent.next_attack_id()
	return blow


func test_a_held_guard_blocks_a_frontal_blow_without_hurt_reaction() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	for i: int in range(20):
		await tree.physics_frame
	# Garde installée depuis longtemps (hors fenêtre de parade).
	_intent.aim_held = true
	for i: int in range(20):
		await tree.physics_frame
	var health_before: float = _player.health().current()
	var stamina_before: float = _stamina().current()
	_hurtbox().receive_hit(_frontal_blow(20.0))
	await tree.physics_frame
	await tree.physics_frame
	var taken: float = health_before - _player.health().current()
	check(taken > 0.0 and taken <= 20.0 * 0.35,
		"coup bloqué : dégâts résiduels réduits (%.1f sur 20)" % taken)
	check(_stamina().current() < stamina_before,
		"le blocage coûte de l'endurance (%.0f → %.0f)" % [stamina_before, _stamina().current()])
	check(_player.mode() == PlayerController.Mode.LOCOMOTION,
		"aucune réaction HURT : la garde a tenu")
	_intent.aim_held = false
	_teardown()


func test_a_blow_in_the_back_passes_entirely() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	for i: int in range(20):
		await tree.physics_frame
	_intent.aim_held = true
	for i: int in range(20):
		await tree.physics_frame
	var health_before: float = _player.health().current()
	_hurtbox().receive_hit(_back_blow(20.0))
	await tree.physics_frame
	await tree.physics_frame
	check(_player.health().current() <= health_before - 19.0,
		"un coup dans le dos traverse la garde en entier")
	check(_player.mode() == PlayerController.Mode.HURT,
		"et la réaction HURT reprend ses droits")
	_intent.aim_held = false
	_teardown()


func test_a_perfect_deflect_cancels_everything_and_opens_clarity() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	for i: int in range(20):
		await tree.physics_frame
	var health_before: float = _player.health().current()
	var stamina_before: float = _stamina().current()
	# Appui DANS la fenêtre : garde levée un tick avant l'impact.
	_intent.aim_held = true
	await tree.physics_frame
	_hurtbox().receive_hit(_frontal_blow(20.0))
	await tree.physics_frame
	await tree.physics_frame
	check(_player.health().current() == health_before,
		"déviation parfaite : AUCUN dégât")
	check(_stamina().current() >= stamina_before - 0.5,
		"…et aucune endurance dépensée")
	check(_player.is_clarity_active(),
		"Clarity ouverte (~0,35 s de lecture, P2 §7.4)")
	for i: int in range(30):
		await tree.physics_frame
	check(not _player.is_clarity_active(), "Clarity expire d'elle-même")
	_intent.aim_held = false
	_teardown()


func test_an_empty_gauge_means_guard_break() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	for i: int in range(20):
		await tree.physics_frame
	_intent.aim_held = true
	for i: int in range(20):
		await tree.physics_frame
	var pool: StaminaComponent = _stamina()
	pool.try_spend(pool.current())
	var health_before: float = _player.health().current()
	_hurtbox().receive_hit(_frontal_blow(20.0))
	await tree.physics_frame
	await tree.physics_frame
	check(_player.health().current() <= health_before - 19.0,
		"GuardBreak : tout passe (P2 §7.4 — zéro endurance casse la garde)")
	check(_player.mode() == PlayerController.Mode.HURT,
		"la réaction HURT reprend — la garde est brisée")
	_intent.aim_held = false
	_teardown()
