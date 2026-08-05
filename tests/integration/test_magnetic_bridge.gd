## P2-4 — Pont magnétique (bible §3.4, P3 §24.4) : un tablier métallique
## chargé, POUSSÉ en place par la Polarité (repousser) jusqu'à la zone de
## verrouillage — le premier raccourci gagné par une opération du Bracelet.
## Fail-first : écrit avant `MagneticBridge`.
##
## Contrats : le tablier est une cible Polarité légitime (métal, chargé,
## décroissance coupée — il attend le joueur) ; poussé dans la zone, il se
## VERROUILLE (gel, alignement sur la travée, signal UNE fois) et devient
## FRANCHISSABLE (un rayon au centre du vide le trouve) ; verrouillé, il
## se met à la terre — plus de charge, la Polarité le refuse (pas_charge) :
## le raccourci est définitif, jamais re-déplaçable par accident.
extends GateTestCase

var _root: Node3D = null
var _bridge: MagneticBridge = null
var _player: PlayerController = null
var _resonance: ResonanceController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	_bridge = null
	_player = null
	_resonance = null


func _setup() -> bool:
	var tree: SceneTree = _tree()
	if tree == null:
		return false
	_root = Node3D.new()
	tree.root.add_child(_root)
	_bridge = MagneticBridge.new()
	_root.add_child(_bridge)
	var player_scene: PackedScene = load("res://scenes/player/Player.tscn") as PackedScene
	_player = player_scene.instantiate() as PlayerController
	_root.add_child(_player)
	# Derrière le tablier, dans l'axe de la travée : REPOUSSER l'envoie
	# vers la zone de verrouillage.
	_player.global_position = _bridge.push_stand_point()
	_resonance = _player.get_node("Components/ResonanceController") as ResonanceController
	return true


func test_the_deck_is_a_patient_legitimate_polarity_target() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	for i: int in range(20):
		await tree.physics_frame
	var deck: RigidBody3D = _bridge.deck()
	check(deck != null, "le tablier existe")
	var state: MaterialStateComponent = null
	for child: Node in deck.get_children():
		if child is MaterialStateComponent:
			state = child as MaterialStateComponent
	check(state != null and state.is_charged(), "tablier chargé")
	check(state != null and not state.charge_decay_enabled,
		"…et il RETIENT sa charge (il attend le joueur)")
	check(not _bridge.is_locked(), "pas encore verrouillé")
	_teardown()


func test_pushed_into_the_lock_zone_the_deck_locks_aligns_and_carries() -> void:
	var tree: SceneTree = _tree()
	if not _setup():
		check(false, "mise en scène impossible")
		return
	var locked_count: Array[int] = [0]
	_bridge.bridge_locked.connect(func() -> void: locked_count[0] += 1)
	for i: int in range(20):
		await tree.physics_frame
	var deck: RigidBody3D = _bridge.deck()
	# REPOUSSER : le joueur est derrière le tablier, la zone devant.
	var verdict: StringName = _resonance.try_polarity(_player, deck, &"repousser")
	check(verdict == &"engaged", "Polarité engagée (obtenu %s)" % verdict)
	var locked: bool = false
	for i: int in range(240):
		await tree.physics_frame
		if _bridge.is_locked():
			locked = true
			break
		# L'engagement est borné (2,5 s) : ré-engager tant que la charge tient.
		if not _resonance.polarity_engaged():
			_resonance.try_polarity(_player, deck, &"repousser")
	check(locked, "le tablier atteint la zone et se verrouille")
	check(locked_count[0] == 1, "signal bridge_locked émis UNE fois")
	await tree.physics_frame
	check(deck.freeze, "verrouillé = gelé (plus un corps actif)")
	var span_center: Vector3 = _bridge.span_center()
	check(Vector2(deck.global_position.x - span_center.x,
		deck.global_position.z - span_center.z).length() < 0.6,
		"aligné sur la travée (écart %.2f m)" % Vector2(
			deck.global_position.x - span_center.x,
			deck.global_position.z - span_center.z).length())
	# FRANCHISSABLE : un rayon au centre du vide trouve le tablier.
	var space: PhysicsDirectSpaceState3D = _player.get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		span_center + Vector3.UP * 2.0, span_center + Vector3.DOWN * 2.0, 1)
	var hit: Dictionary = space.intersect_ray(query)
	check(not hit.is_empty() and (hit["collider"] as Node) == deck,
		"le vide est couvert : on marche sur le tablier")
	# Définitif : mis à la terre au verrouillage, la Polarité le refuse.
	check(_resonance.try_polarity(_player, deck, &"attirer") == &"pas_charge",
		"verrouillé = déchargé : le raccourci ne se re-déplace pas")
	_teardown()
