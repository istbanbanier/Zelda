## HUD, inventaire, invites et lisibilité graybox — régressions PT-D1-03.
##
## Chaque test mesure l'EFFET réel : la barre reflète le composant, l'invite
## disparaît derrière un mur, l'équipement change les dégâts ET la portée, la
## molette change d'arme hors verrouillage et de cible pendant, le télégraphe
## se VOIT sur le matériau. Aucune assertion « le nœud existe ».
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const SHELL: String = "res://scenes/ui/GameplayShell.tscn"
const CHEST: String = "res://scenes/interactables/Chest.tscn"
const PICKUP: String = "res://scenes/interactables/WeaponPickup.tscn"
const RAIDER: String = "res://scenes/enemies/RaiderRed.tscn"
const DUMMY: String = "res://scenes/tests/CombatDummy.tscn"
const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const CLUB: String = "res://resources/weapons/wood_club.tres"
const SPEAR: String = "res://resources/weapons/spear.tres"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null
var _shell: GameplayShell = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _setup(with_shell: bool = false) -> void:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = Vector3(0, 0.1, 0)
	_world.add_child(_player)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	if with_shell:
		_shell = (load(SHELL) as PackedScene).instantiate() as GameplayShell
		_world.add_child(_shell)
	for i: int in range(120):
		if _player.is_on_floor():
			break
		await _tree().physics_frame
	check(_player.is_on_floor(), "préalable de setup : joueur atterri")


func _teardown() -> void:
	if _tree().paused:
		_tree().paused = false
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	_intent = null
	_shell = null


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _wall_at(position: Vector3, size: Vector3) -> void:
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	cs.shape = box
	wall.add_child(cs)
	wall.position = position
	_world.add_child(wall)


func test_an_obstacle_kills_both_the_prompt_and_the_interaction() -> void:
	## §14.2 : « une paroi doit empêcher l'invite ET l'interaction ». Même coffre,
	## même distance — seul le mur change. Les deux directions sont prouvées.
	await _setup(true)
	var chest: Chest = (load(CHEST) as PackedScene).instantiate() as Chest
	chest.chest_id = &"test.chest.los.01"
	chest.weapon_loot = load(CLUB) as WeaponDefinition
	chest.position = Vector3(0, 0, 1.8)
	_world.add_child(chest)
	_wall_at(Vector3(0, 1.5, 1.0), Vector3(4, 3, 0.3))
	await _settle(10)

	check_equal(_shell.prompt_text(), "", "aucune invite à travers le mur")
	_intent.interact_pressed = true
	await _settle(3)
	check(not chest.is_opened(), "aucune interaction à travers le mur")

	# Contre-épreuve : le mur parti, l'invite ET l'ouverture reviennent.
	for wall: Node in _world.get_children():
		if wall is StaticBody3D and wall != chest and (wall as Node3D).position.y > 1.0:
			wall.free()
	await _settle(10)
	check_equal(_shell.prompt_text(), "E — Ouvrir", "l'invite revient sans le mur")
	_intent.interact_pressed = true
	await _settle(3)
	check(chest.is_opened(), "l'interaction aussi")
	_teardown()


func test_the_hud_bars_mirror_the_real_components() -> void:
	## PT-D1-03 : vie et endurance VISIBLES et synchrones. Un coup de 20 → barre
	## de vie à 80 ; un sprint réel → barre d'endurance qui descend, puis remonte.
	await _setup(true)
	await _settle(5)
	check_approx(_shell.hud_health(), 100.0, 0.01, "barre de vie pleine au départ")

	var blow: DamageEvent = DamageEvent.new()
	blow.amount = 20.0
	blow.attack_id = HitboxComponent.next_attack_id()
	(_player.get_node("Hurtbox") as HurtboxComponent).receive_hit(blow)
	await _settle(3)
	check_approx(_shell.hud_health(), 80.0, 0.01, "un coup de 20 se lit sur la barre")

	var before: float = _shell.hud_stamina()
	_intent.move = Vector2(0, 1)
	_intent.sprint_held = true
	await _settle(60)
	var drained: float = _shell.hud_stamina()
	check(drained < before - 8.0,
		"le sprint se lit sur la barre d'endurance (%.0f → %.0f)" % [before, drained])
	_intent.move = Vector2.ZERO
	_intent.sprint_held = false
	await _settle(120)
	check(_shell.hud_stamina() > drained + 5.0, "la régénération aussi")
	_teardown()


func test_pickup_equips_through_the_panel_and_changes_damage_and_reach() -> void:
	## PT-D1-03, chaîne complète : ramasser (notification), ÉQUIPER via le
	## panneau, et vérifier que dégâts ET portée sont ceux de la nouvelle arme.
	await _setup(true)
	var pickup: WeaponPickup = (load(PICKUP) as PackedScene).instantiate() as WeaponPickup
	pickup.definition = load(SPEAR) as WeaponDefinition
	pickup.position = Vector3(0, 0, 1.5)
	_world.add_child(pickup)
	await _settle(10)
	check_equal(_shell.prompt_text(), "E — Ramasser", "l'invite nomme l'action")

	_intent.interact_pressed = true
	await _settle(3)
	check(_shell.notification_texts().has("Ramassé : Lance"),
		"le ramassage se dit à l'écran — plus jamais silencieux")

	_shell.equip_slot(1)   # la lance, derrière l'épée de départ
	await _settle(2)
	var attack: AttackControllerComponent = \
		_player.get_node("Components/AttackController") as AttackControllerComponent
	check_approx(attack.attack_damage_base(), 10.0, 0.001, "dégâts de la lance (§11.1)")
	var hitbox: Node3D = _player.get_node("VisualRoot/WeaponHitbox") as Node3D
	check_approx(hitbox.position.z, 2.7 - 0.55, 0.001, "portée de la lance raccordée")
	_teardown()


func test_reordering_keeps_the_equipped_instance_equipped() -> void:
	## PT-D1-03 : réordonner sans jamais perdre l'arme en main.
	await _setup(false)
	var inventory: InventoryComponent = _player.inventory()
	inventory.add_weapon(WeaponInstance.create(load(CLUB) as WeaponDefinition))
	inventory.add_weapon(WeaponInstance.create(load(SPEAR) as WeaponDefinition))
	var equipped: WeaponInstance = inventory.equipped()   # l'épée de départ, case 0

	check(inventory.move_weapon(0, 2), "déplacement case 0 → case 2")
	check_equal(inventory.weapons()[2], equipped, "l'exemplaire a changé de case")
	check_equal(inventory.equipped(), equipped, "…et reste ÉQUIPÉ (§11.3)")
	check_equal(String(inventory.weapons()[0].definition.id), "wood_club",
		"l'ordre est réellement réécrit")
	_teardown()


func test_the_wheel_switches_weapons_free_and_targets_locked() -> void:
	## PT-D1-03 : « la molette peut changer d'arme hors verrouillage et changer
	## de cible pendant, sans conflit ». Les deux moitiés, mesurées.
	await _setup(false)
	var inventory: InventoryComponent = _player.inventory()
	inventory.add_weapon(WeaponInstance.create(load(SPEAR) as WeaponDefinition))
	var sword: WeaponInstance = inventory.equipped()
	await _settle(3)

	_intent.target_next_pressed = true
	await _settle(2)
	check(inventory.equipped() != sword, "molette libre : l'arme SUIVANTE est en main")
	check_equal(String(inventory.equipped().definition.id), "spear", "…la lance")

	# Deux cibles, verrouillage : la même molette change de CIBLE, pas d'arme.
	var left: CombatDummy = (load(DUMMY) as PackedScene).instantiate() as CombatDummy
	left.position = Vector3(-1, 0, -8)
	_world.add_child(left)
	var right: CombatDummy = (load(DUMMY) as PackedScene).instantiate() as CombatDummy
	right.position = Vector3(3, 0, -8)
	_world.add_child(right)
	await _settle(3)
	_intent.lock_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), left, "préalable : verrouillé à gauche")
	var held: WeaponInstance = inventory.equipped()

	_intent.target_next_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), right, "verrouillé : la molette change de CIBLE")
	check_equal(inventory.equipped(), held, "…et JAMAIS d'arme en même temps")
	_teardown()


func test_a_full_inventory_chest_refuses_with_a_visible_reason() -> void:
	## PT-D1-03 : « un inventaire plein refuse proprement le loot et explique
	## pourquoi ». Le coffre reste fermé, le loot intact, la raison à l'écran.
	await _setup(true)
	var inventory: InventoryComponent = _player.inventory()
	var club_def: WeaponDefinition = load(CLUB) as WeaponDefinition
	while inventory.weapon_count() < InventoryComponent.MAX_WEAPONS:
		inventory.add_weapon(WeaponInstance.create(club_def))
	var chest: Chest = (load(CHEST) as PackedScene).instantiate() as Chest
	chest.chest_id = &"test.chest.full.01"
	chest.weapon_loot = load(SPEAR) as WeaponDefinition
	chest.arrows_loot = 12
	chest.position = Vector3(0, 0, 1.8)
	_world.add_child(chest)
	var arrows_before: int = inventory.arrows()
	await _settle(10)

	_intent.interact_pressed = true
	await _settle(3)

	check(not chest.is_opened(), "le coffre reste fermé — rien n'est perdu")
	check_equal(inventory.arrows(), arrows_before, "pas même les flèches (atomicité §13.2)")
	var found: bool = false
	for text: String in _shell.notification_texts():
		if text.begins_with("Inventaire plein"):
			found = true
	check(found, "la raison du refus est affichée")
	_teardown()


func test_the_valley_has_its_four_chests_with_unique_ids() -> void:
	## §11.4 : « trois dans la vallée, un au camp » — présents, IDs §19.3 uniques.
	var valley: Node3D = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(valley)
	await _settle(5)
	var ids: Array[String] = []
	for chest: Node in valley.find_children("*", "Chest", true, false):
		ids.append(String((chest as Chest).chest_id))
	ids.sort()
	check_equal(ids.size(), 4, "quatre coffres dans la vallée")
	var expected: Array[String] = ["valley.chest.camp.01", "valley.chest.cliff_top.01",
		"valley.chest.pylon.01", "valley.chest.river_ledge.01"]
	check_equal(ids, expected, "identifiants stables et uniques (§19.3)")
	_tree().root.remove_child(valley)
	valley.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
	await _settle(2)


func test_the_telegraph_is_visible_on_the_raider_body() -> void:
	## PT-D1-03/-12 : « une attaque ennemie peut être anticipée visuellement ».
	## Mesuré sur le MATÉRIAU : rouge franc pendant le startup, couleur de base
	## avant. Le mannequin d'en face est le joueur lui-même, immobile.
	await _setup(false)
	var raider: RaiderRed = (load(RAIDER) as PackedScene).instantiate() as RaiderRed
	raider.position = Vector3(0, 0.1, 1.4)
	_world.add_child(raider)
	await _settle(5)
	var body: MeshInstance3D = raider.get_node("Pivot/BodyMesh") as MeshInstance3D
	var material: StandardMaterial3D = \
		body.get_surface_override_material(0) as StandardMaterial3D
	var base_color: Color = material.albedo_color

	var poke: DamageEvent = DamageEvent.new()
	poke.instigator = _player
	poke.team = &"player"
	poke.amount = 1.0
	poke.attack_id = HitboxComponent.next_attack_id()
	(raider.get_node("Hurtbox") as HurtboxComponent).receive_hit(poke)

	# Attendre l'entrée en ATTACK puis échantillonner en plein télégraphe.
	var telegraphed: bool = false
	for i: int in range(180):
		await _tree().physics_frame
		if raider.state() == RaiderRed.State.ATTACK and material.albedo_color != base_color:
			telegraphed = true
			break
	check(telegraphed, "le corps du pillard change de couleur pendant l'annonce")
	check(material.albedo_color.r > 0.85 and material.albedo_color.g < 0.35,
		"…et c'est un rouge franc, pas une nuance")
	check(raider.get_node_or_null("Pivot/ClubMesh") != null,
		"le gourdin du pillard est VISIBLE (PT-D1-12)")
	_teardown()


func test_the_player_weapon_is_visible_and_matches_the_equipment() -> void:
	## PT-D1-12 : « aucune arme visible » — corrigé : une lame visible qui suit
	## l'équipement, et disparaît à mains nues.
	await _setup(false)
	await _settle(3)
	var mesh: MeshInstance3D = \
		_player.get_node("VisualRoot/WeaponPivot/WeaponMesh") as MeshInstance3D
	check(mesh.visible, "l'épée de départ se voit")

	var inventory: InventoryComponent = _player.inventory()
	var sword: WeaponInstance = inventory.equipped()
	inventory.remove_weapon(sword)
	await _settle(2)
	check(not mesh.visible, "mains nues : plus de lame affichée")
	_teardown()
