## Régression du bug 5 et de l'absence 2.4 de TESTS.md (§10.2, §10.6).
##
## Le contrat d'attaque DÉCLARAIT `knockback` (2,0-4,5) et `hit_stop`
## (0,045-0,085 s) depuis C.1 — et personne ne les consommait : l'ennemi
## touché ne bougeait pas d'un centimètre, aucun corps ne se figeait. Ces
## tests mesurent la CONSOMMATION : un coup déplace la cible, un contact
## fige les deux corps pendant la durée que l'attaque annonce.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const RAIDER: String = "res://scenes/enemies/RaiderRed.tscn"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _setup(player_at: Vector3, raider_at: Vector3) -> RaiderRed:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(120, 1, 120)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = player_at
	_world.add_child(_player)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	var raider: RaiderRed = (load(RAIDER) as PackedScene).instantiate() as RaiderRed
	raider.position = raider_at
	_world.add_child(raider)
	await _settle(4)
	return raider


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_tree().root.remove_child(_world)
		_world.queue_free()
	_world = null
	await _settle(2)


func _hit(raider: RaiderRed, knockback: float, hit_stop: float) -> void:
	## Le coup passe par le VRAI canal — `receive_hit` de la hurtbox — avec un
	## événement construit comme la hitbox le fait, direction du joueur vers
	## la cible.
	var event: DamageEvent = DamageEvent.new()
	event.team = &"player"
	event.amount = 5.0
	event.knockback = knockback
	event.hit_stop = hit_stop
	var flat: Vector3 = raider.global_position - _player.global_position
	flat.y = 0.0
	event.direction = flat.normalized()
	(raider.get_node("Hurtbox") as HurtboxComponent).receive_hit(event)


func test_a_hit_shoves_the_enemy_back() -> void:
	## Bug 5 : `event.knockback` était ignoré — le pillard flashait sans
	## bouger d'un centimètre. Le critère du plan de test : « attaquant et
	## cible se séparent visiblement à chaque impact ».
	var raider: RaiderRed = await _setup(Vector3(0, 1, 0), Vector3(2.0, 0.5, 0))
	var before: Vector3 = raider.global_position

	_hit(raider, 4.0, 0.0)
	await _settle(20)

	var pushed: float = (raider.global_position - before).dot(Vector3.RIGHT)
	check(pushed > 0.25,
		"le coup doit repousser la cible dans sa direction (déplacement : %.2f m)"
		% pushed)
	await _teardown()


func test_hit_stop_freezes_the_victim_for_the_declared_time() -> void:
	## Absence 2.4 : `hit_stop` était déclaré et jamais consommé. Pendant le
	## gel, le corps ne se déplace PAS malgré le recul reçu — c'est la
	## micro-pause qui donne le poids ; le recul part APRÈS.
	var raider: RaiderRed = await _setup(Vector3(0, 1, 0), Vector3(2.0, 0.5, 0))
	var before: Vector3 = raider.global_position

	# 0,10 s de gel = 6 ticks à 60 Hz. Pendant les 4 premiers ticks, la cible
	# gelée n'a pas le droit d'avoir bougé, knockback pourtant reçu.
	_hit(raider, 4.0, 0.10)
	await _settle(4)
	var during_freeze: float = (raider.global_position - before).length()
	check(during_freeze < 0.05,
		"pendant le hit-stop la cible reste figée (a bougé de %.3f m)"
		% during_freeze)

	# Après la fenêtre, le recul déclaré s'exprime. Mesure à la FIN de la
	# fenêtre de recul (gel restant ~2 ticks + poussée ~11 ticks) : attendre
	# plus laisserait le pillard re-poursuivre le joueur et regagner le
	# terrain mesuré — la première version de ce test a rougi exactement
	# ainsi, 0,22 m au lieu de 0,25 constatés.
	await _settle(14)
	var after: float = (raider.global_position - before).dot(Vector3.RIGHT)
	check(after > 0.25,
		"après le gel, le recul déclaré s'applique (déplacement : %.2f m)"
		% after)
	await _teardown()
