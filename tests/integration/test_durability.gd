## Durabilité en jeu (MASTER_SPEC §11.1, §11.2, §11.3) — l'usure au contact,
## jamais dans le vide ; la rupture qui coupe la hitbox, retire l'exemplaire et
## équipe la suivante ; la portée §11.1 raccordée au volume de frappe ; les
## flèches comptées qui conditionnent le tir.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const DUMMY: String = "res://scenes/tests/CombatDummy.tscn"
const CLUB: String = "res://resources/weapons/wood_club.tres"
const SPEAR: String = "res://resources/weapons/spear.tres"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _setup() -> void:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_player = (load(PLAYER) as PackedScene).instantiate() as PlayerController
	_player.position = Vector3(0, 0.1, 0)
	_world.add_child(_player)
	_intent = InputIntent.new()
	_player.set_intent_source(_intent)
	await _settle(2)
	for i: int in range(120):
		if _player.is_on_floor():
			break
		await _tree().physics_frame
	check(_player.is_on_floor(), "préalable de setup : joueur atterri")


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null
	_intent = null


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _spawn_dummy(at: Vector3) -> CombatDummy:
	var dummy: CombatDummy = (load(DUMMY) as PackedScene).instantiate() as CombatDummy
	dummy.position = at
	_world.add_child(dummy)
	return dummy


## Un coup léger complet : appui, puis attente de toute la durée de l'attaque.
func _swing() -> void:
	_intent.attack_pressed = true
	await _settle(40)


func test_swings_in_the_void_cost_no_durability() -> void:
	## §11.2 : « jamais dans le vide ». Deux moulinets sans personne devant —
	## l'épée de départ garde ses 24 points.
	await _setup()
	var sword: WeaponInstance = _player.inventory().equipped()
	check_not_null(sword, "l'épée usée de départ est en main")
	check_equal(sword.current_durability, 24, "neuve (§11.1)")

	await _swing()
	await _swing()

	check_equal(sword.current_durability, 24,
		"deux coups dans le vide n'usent RIEN")
	_teardown()


func test_a_connecting_hit_wears_the_weapon_and_uses_its_damage() -> void:
	## §11.2 + §11.1 : le coup qui touche coûte un point, et les dégâts viennent
	## de la DÉFINITION (épée usée : 12), plus d'un nombre posé sur le contrôleur.
	await _setup()
	var dummy: CombatDummy = _spawn_dummy(Vector3(0, 0, 1.3))
	var sword: WeaponInstance = _player.inventory().equipped()
	await _settle(3)

	await _swing()

	check_approx(dummy.health().current(), 45.0 - 12.0, 0.001,
		"les dégâts sont ceux de la définition (12)")
	check_equal(sword.current_durability, 23, "le coup qui touche coûte UN point")
	_teardown()


func test_damage_follows_the_equipped_weapon() -> void:
	## Changer d'arme change les dégâts : le gourdin (8) remplace l'épée (12).
	await _setup()
	var dummy: CombatDummy = _spawn_dummy(Vector3(0, 0, 1.3))
	var club: WeaponInstance = WeaponInstance.create(load(CLUB) as WeaponDefinition)
	var inventory: InventoryComponent = _player.inventory()
	check(inventory.add_weapon(club), "le gourdin entre")
	inventory.equip_next()
	check_equal(inventory.equipped(), club, "le gourdin est en main")
	await _settle(3)

	await _swing()

	check_approx(dummy.health().current(), 45.0 - 8.0, 0.001,
		"le gourdin frappe à 8 (§11.1)")
	_teardown()


func test_rupture_equips_the_next_weapon_then_bare_hands_still_fight() -> void:
	## §11.2 : à zéro — l'exemplaire est retiré, la SUIVANTE équipée ; sans
	## suivante, les mains nues restent un état de combat (D-023 : base 3).
	await _setup()
	var dummy: CombatDummy = _spawn_dummy(Vector3(0, 0, 1.3))
	var inventory: InventoryComponent = _player.inventory()
	var sword: WeaponInstance = inventory.equipped()
	var club: WeaponInstance = WeaponInstance.create(load(CLUB) as WeaponDefinition)
	inventory.add_weapon(club)
	sword.current_durability = 1   # à un coup de la fin
	await _settle(3)

	await _swing()   # 12 de dégâts, et l'épée casse

	check_equal(inventory.weapon_count(), 1, "l'exemplaire cassé est RETIRÉ")
	check_equal(inventory.equipped(), club, "la suivante est équipée d'office")

	club.current_durability = 1
	await _swing()   # 8 de dégâts, et le gourdin casse

	check(inventory.equipped() == null, "plus d'armes : mains nues")
	await _swing()   # 3 de dégâts, mains nues

	check_approx(dummy.health().current(), 45.0 - 12.0 - 8.0 - 3.0, 0.001,
		"épée 12, gourdin 8, mains nues 3 — chaque coup au tarif de son arme")
	_teardown()


func test_rupture_cuts_the_hitbox_before_the_next_victim() -> void:
	## §11.2 : « couper hitbox ». Deux mannequins côte à côte dans le même
	## volume de frappe. Arme à 1 point : UN SEUL est blessé — la rupture coupe
	## la fenêtre au milieu du tick, avant la cible suivante. Contre-épreuve dans
	## le même test : arme à 2 points, les DEUX sont blessés par le même coup.
	await _setup()
	var left: CombatDummy = _spawn_dummy(Vector3(-0.4, 0, 1.3))
	var right: CombatDummy = _spawn_dummy(Vector3(0.4, 0, 1.3))
	var sword: WeaponInstance = _player.inventory().equipped()
	sword.current_durability = 1
	await _settle(3)

	await _swing()

	var total: float = left.health().current() + right.health().current()
	check_approx(total, 90.0 - 12.0, 0.001,
		"arme cassée au premier contact : UNE seule victime (%.0f + %.0f)"
		% [left.health().current(), right.health().current()])
	_teardown()

	# Contre-épreuve : avec de la durabilité, le même coup touche les deux.
	await _setup()
	var left2: CombatDummy = _spawn_dummy(Vector3(-0.4, 0, 1.3))
	var right2: CombatDummy = _spawn_dummy(Vector3(0.4, 0, 1.3))
	await _settle(3)

	await _swing()

	var both: float = left2.health().current() + right2.health().current()
	check_approx(both, 90.0 - 24.0, 0.001,
		"avec de la durabilité, le même coup touche les DEUX (%.0f + %.0f)"
		% [left2.health().current(), right2.health().current()])
	_teardown()


func test_the_spear_outreaches_the_sword() -> void:
	## §11.1 : la portée est une donnée d'arme. Un mannequin à 2,4 m — hors de
	## portée de l'épée (1,7 m), dans celle de la lance (2,7 m). Même position,
	## même geste : seule l'arme change.
	await _setup()
	var dummy: CombatDummy = _spawn_dummy(Vector3(0, 0, 2.4))
	await _settle(3)

	await _swing()
	check_approx(dummy.health().current(), 45.0, 0.001,
		"l'épée (1,7 m) ne touche pas à 2,4 m")

	var inventory: InventoryComponent = _player.inventory()
	var spear: WeaponInstance = WeaponInstance.create(load(SPEAR) as WeaponDefinition)
	inventory.add_weapon(spear)
	inventory.equip_next()
	await _settle(3)

	await _swing()
	check_approx(dummy.health().current(), 45.0 - 10.0, 0.001,
		"la lance (2,7 m) touche, à 10 de dégâts (§11.1)")
	_teardown()


func test_arrows_are_consumed_and_gate_the_shot() -> void:
	## §11.3 : flèches comptées. La dotation de 8 en perd une par tir ; à zéro,
	## rien ne part — ni flèche en vol, ni dégât.
	await _setup()
	var dummy: CombatDummy = _spawn_dummy(Vector3(0, 0, -4.0))
	var inventory: InventoryComponent = _player.inventory()
	check_equal(inventory.arrows(), 8, "dotation de départ du bac à sable")
	await _settle(3)

	_intent.aim_held = true
	_intent.shoot_pressed = true
	await _settle(15)

	check_approx(dummy.health().current(), 45.0 - 9.0, 0.001, "le tir porte")
	check_equal(inventory.arrows(), 7, "une flèche consommée par tir")

	while inventory.consume_arrow():
		pass
	check_equal(inventory.arrows(), 0, "carquois vidé")

	# Purger la CADENCE (0,6 s) avant le tir à vide : sans cette attente, c'est
	# elle qui bloque le tir, pas le compteur — l'assertion serait verte pour la
	# mauvaise raison (C2-1). AA6 l'a démontré : portail retiré, elle restait verte.
	await _settle(40)

	_intent.aim_held = true
	_intent.shoot_pressed = true
	await _settle(15)

	check_approx(dummy.health().current(), 45.0 - 9.0, 0.001,
		"à zéro flèche, AUCUN tir ne part")
	var bow: BowComponent = _player.get_node("Components/BowComponent") as BowComponent
	check_equal(bow.active_arrows().size(), 0, "aucune flèche en vol")
	_teardown()
