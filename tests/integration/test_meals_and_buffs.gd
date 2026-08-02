## E.2a — plats et buffs CÂBLÉS (§13.4, §13.5, §8.5 « Plat rapide ») : la
## touche consomme le plus ancien plat (soin immédiat + buff majeur), les
## multiplicateurs se propagent PAR SIGNAL aux composants consommateurs
## (dégâts infligés, dégâts reçus, régénération), et plats + buff restant
## survivent au rechargement de la vallée. Mesuré sur le vrai joueur.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const SLOT: String = "slot0"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _setup() -> void:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = Vector3(0, 0.1, 0)
	_world.add_child(_player)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	await _settle(3)


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	await _settle(1)


func _meat_stew() -> Dictionary:
	## Vraie recette depuis les vraies définitions : 2 viandes (attack) + 1
	## fruit → Ragoût du guerrier, soin 55, durée 60+30×2 = 120 s.
	var meat: IngredientDefinition = load(
		"res://resources/ingredients/meat.tres") as IngredientDefinition
	var fruit: IngredientDefinition = load(
		"res://resources/ingredients/heal_fruit.tres") as IngredientDefinition
	var picks: Array[IngredientDefinition] = [meat, meat, fruit]
	return RecipeRules.cook(picks)


func _clear_save() -> void:
	var system: Node = _tree().root.get_node_or_null("/root/SaveSystem")
	if system == null:
		return
	var path: String = String(system.call("slot_path", SLOT))
	for candidate: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(candidate):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))


func _cleanup_valley(valley: Node) -> void:
	_tree().root.remove_child(valley)
	valley.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


func test_the_quick_meal_heals_buffs_and_is_consumed_once() -> void:
	## §8.5/§13.4 : la touche mange le plat le plus ancien — soin immédiat,
	## buff appliqué, plat retiré. Un second appui sans plat ne fait RIEN.
	await _setup()
	var inventory: InventoryComponent = _player.inventory()
	check(inventory.add_meal(_meat_stew()), "le ragoût entre en réserve")
	check_equal(inventory.meal_count(), 1, "un plat en réserve")

	var blow: DamageEvent = DamageEvent.new()
	blow.amount = 60.0
	blow.attack_id = HitboxComponent.next_attack_id()
	_player.health().take_damage(blow)
	await _settle(2)
	check_approx(_player.health().current(), 40.0, 0.01, "préalable : 40 PV")

	_intent.meal_pressed = true
	await _settle(2)
	check_approx(_player.health().current(), 95.0, 0.01,
		"soin du ragoût appliqué (40 + 55)")
	check_equal(String(_player.status().active_effect()), "attack",
		"le buff d'attaque est actif")
	check_equal(inventory.meal_count(), 0, "le plat est CONSOMMÉ")

	var before: float = _player.health().current()
	_intent.meal_pressed = true
	await _settle(2)
	check_approx(_player.health().current(), before, 0.01,
		"sans plat : aucun soin fantôme")
	await _teardown()


func test_the_multipliers_propagate_by_signal_and_fall_back_on_expiry() -> void:
	## §13.5 : attaque ×1.25 sur la hitbox, défense ×0.75 sur la hurtbox,
	## endurance ×1.6 sur la régénération — posés AU SIGNAL, retombés à
	## l'expiration. Les dégâts reçus sont mesurés sur la vraie santé.
	await _setup()
	var hitbox: HitboxComponent = _player.get_node("VisualRoot/WeaponHitbox") \
		as HitboxComponent
	var hurtbox: HurtboxComponent = _player.get_node("Hurtbox") as HurtboxComponent
	var status: StatusEffectComponent = _player.status()

	status.apply_buff(&"attack", 2.0, 30.0)
	check_approx(hitbox.damage_multiplier, 1.25, 0.001,
		"buff d'attaque : la hitbox frappe ×1.25")
	check_approx(hurtbox.damage_taken_multiplier, 1.0, 0.001,
		"…sans toucher la défense")

	status.apply_buff(&"defense", 1.0, 30.0)
	check_approx(hitbox.damage_multiplier, 1.0, 0.001,
		"remplacement : l'attaque retombe")
	check_approx(hurtbox.damage_taken_multiplier, 0.75, 0.001,
		"…la défense prend (×0.75)")
	var blow: DamageEvent = DamageEvent.new()
	blow.amount = 20.0
	blow.attack_id = HitboxComponent.next_attack_id()
	hurtbox.receive_hit(blow)
	await _settle(2)
	check_approx(_player.health().current(), 85.0, 0.01,
		"20 de dégâts deviennent 15 sous le buff de défense")

	status.apply_buff(&"stamina", 1.0, 30.0)
	check_approx(_player.stamina().regen_multiplier, 1.6, 0.001,
		"buff d'endurance : régénération ×1.6")
	status._process(31.0)   # expiration pilotée, déterministe
	check_equal(String(status.active_effect()), "", "préalable : buff expiré")
	check_approx(_player.stamina().regen_multiplier, 1.0, 0.001,
		"…tous les multiplicateurs retombent à l'expiration")
	check_approx(hitbox.damage_multiplier, 1.0, 0.001, "…hitbox neutre")
	check_approx(hurtbox.damage_taken_multiplier, 1.0, 0.001, "…hurtbox neutre")
	await _teardown()


func test_meals_and_remaining_buff_survive_a_reload() -> void:
	## §19.1 (« plats et buff restant ») : cuisiner → autosave ; manger →
	## buff ; recharger → le plat restant est là, le buff court encore.
	_clear_save()
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var player: PlayerController = valley.player()
	var inventory: InventoryComponent = player.inventory()
	check(inventory.add_meal(_meat_stew()), "plat 1 en réserve (autosave)")
	check(inventory.add_meal(_meat_stew()), "plat 2 en réserve (autosave)")
	player.set_intent_source(InputIntent.new())
	player.current_intent().meal_pressed = true
	await _settle(3)
	check_equal(inventory.meal_count(), 1, "un plat mangé, un plat reste")
	check_equal(String(player.status().active_effect()), "attack",
		"le buff court avant rechargement")
	await _cleanup_valley(valley)

	var reloaded: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(reloaded)
	await _settle(5)
	var back: PlayerController = reloaded.player()
	check_equal(back.inventory().meal_count(), 1,
		"le plat restant survit au rechargement")
	check_equal(String(back.status().active_effect()), "attack",
		"le buff RESTANT court encore (§19.1)")
	check(back.status().remaining() > 0.0 and back.status().remaining() <= 120.0,
		"…avec un temps restant plausible (%.0f s)" % back.status().remaining())
	var hitbox: HitboxComponent = back.get_node("VisualRoot/WeaponHitbox") \
		as HitboxComponent
	check_approx(hitbox.damage_multiplier, 1.25, 0.001,
		"…et les multiplicateurs se sont RETENDUS à la restauration")
	await _cleanup_valley(reloaded)
	_clear_save()


func test_an_expired_buff_never_resurrects_after_a_reload() -> void:
	## Correctif V4 lot 1 : l'EXPIRATION doit aussi produire un instantané —
	## sans cela, le buff sauvegardé à l'application ressuscite au
	## rechargement avec tout son temps. Expiration pilotée (déterministe),
	## AUCUN autre événement de sauvegarde entre l'expiration et le
	## rechargement.
	_clear_save()
	var valley: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(5)
	var player: PlayerController = valley.player()
	player.status().apply_buff(&"attack", 2.0, 0.5)   # autosave : buff PRÉSENT
	await _settle(2)
	player.status()._process(1.0)   # expiration pilotée — buff_expired émis
	await _settle(2)
	check_equal(String(player.status().active_effect()), "", "préalable : expiré")
	await _cleanup_valley(valley)

	var reloaded: ValleyWorld = (load(VALLEY) as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(reloaded)
	await _settle(5)
	var back: PlayerController = reloaded.player()
	check_equal(String(back.status().active_effect()), "",
		"le buff expiré ne RESSUSCITE pas au rechargement")
	var hitbox: HitboxComponent = back.get_node("VisualRoot/WeaponHitbox") \
		as HitboxComponent
	check_approx(hitbox.damage_multiplier, 1.0, 0.001,
		"…aucun multiplicateur résiduel")
	await _cleanup_valley(reloaded)
	_clear_save()
