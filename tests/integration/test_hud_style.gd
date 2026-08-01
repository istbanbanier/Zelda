## Habillage HUD V4.4 (réf. 03) — rubis, endurance contextuelle, plaque de
## cible, durabilité segmentée. Chaque test mesure l'EFFET : les éclats se
## vident dans l'ordre et leur somme EST la santé affichée, la jauge
## n'apparaît que pendant l'usage, la plaque suit la vraie vie de l'ennemi,
## les segments suivent la vraie durabilité. Aucun compteur décoratif.
extends GateTestCase

const PLAYER: String = "res://scenes/player/Player.tscn"
const SHELL: String = "res://scenes/ui/GameplayShell.tscn"
const DUMMY: String = "res://scenes/tests/CombatDummy.tscn"

var _world: Node3D = null
var _player: PlayerController = null
var _intent: InputIntent = null
var _shell: GameplayShell = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _setup() -> void:
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


func test_health_shows_as_ruby_shards_that_drain_in_order() -> void:
	## Réf. 03 : cinq fragments, le dernier entamé se vide partiellement.
	## 100 PV → [20,20,20,20,20] ; un coup de 30 → [20,20,20,10,0], somme 70.
	await _setup()
	await _settle(3)
	check_equal(_shell.ruby_shard_values().size(), 5, "cinq éclats de rubis")
	check_approx(_shell.hud_health(), 100.0, 0.01, "pleine vie : somme 100")

	var blow: DamageEvent = DamageEvent.new()
	blow.amount = 30.0
	blow.attack_id = HitboxComponent.next_attack_id()
	(_player.get_node("Hurtbox") as HurtboxComponent).receive_hit(blow)
	await _settle(3)
	var shards: Array[float] = _shell.ruby_shard_values()
	check_approx(_shell.hud_health(), 70.0, 0.01,
		"la somme AFFICHÉE suit le composant (70)")
	check_approx(shards[3], 10.0, 0.01, "le 4e éclat est ENTAMÉ (10/20)")
	check_approx(shards[4], 0.0, 0.01, "le 5e est vide")
	check_approx(shards[0], 20.0, 0.01, "les premiers restent pleins")
	_teardown()


func test_the_stamina_gauge_appears_only_while_working() -> void:
	## Réf. 03 : « près du personnage pendant son utilisation » — invisible à
	## pleine jauge, visible dès que l'endurance travaille, disparaît une fois
	## régénérée. Mesuré sur un VRAI sprint.
	await _setup()
	await _settle(3)
	check(not _shell.is_stamina_gauge_visible(), "pleine jauge : invisible")

	_intent.move = Vector2(0, 1)
	_intent.sprint_held = true
	await _settle(30)
	check(_shell.is_stamina_gauge_visible(), "en plein sprint : visible")
	check(_shell.hud_stamina() < 95.0, "…et la valeur baisse réellement")

	_intent.move = Vector2.ZERO
	_intent.sprint_held = false
	var hidden_again: bool = false
	for i: int in range(400):   # délai 1 s + régénération 22/s
		await _tree().physics_frame
		if not _shell.is_stamina_gauge_visible():
			hidden_again = true
			break
	check(hidden_again, "régénérée : la jauge se retire")
	_teardown()


func test_the_lock_plaque_shows_the_real_enemy_health() -> void:
	## Réf. 03 : « cible et vie de l'ennemi lorsque le verrouillage est
	## actif ». La plaque suit le HealthComponent de la CIBLE — un coup sur
	## elle bouge la barre ; relâcher ferme la plaque.
	await _setup()
	var dummy: CombatDummy = (load(DUMMY) as PackedScene).instantiate() as CombatDummy
	dummy.position = Vector3(0, 0, -6)
	_world.add_child(dummy)
	await _settle(3)
	check(not _shell.is_lock_plaque_visible(), "sans verrouillage : pas de plaque")

	_intent.lock_pressed = true
	await _settle(2)
	check_equal(_player.lock_target(), dummy, "préalable : verrouillé")
	check(_shell.is_lock_plaque_visible(), "verrouillé : la plaque apparaît")
	var shown_before: float = _shell.lock_target_health_shown()
	check(shown_before > 0.0, "…avec la vie réelle de la cible")

	var blow: DamageEvent = DamageEvent.new()
	blow.amount = 10.0
	blow.attack_id = HitboxComponent.next_attack_id()
	(dummy.find_children("*", "HurtboxComponent", true, false)[0] \
		as HurtboxComponent).receive_hit(blow)
	await _settle(2)
	check_approx(_shell.lock_target_health_shown(), shown_before - 10.0, 0.01,
		"un coup sur la CIBLE bouge la plaque")

	_intent.lock_pressed = true
	await _settle(2)
	check(not _shell.is_lock_plaque_visible(), "relâché : la plaque se ferme")
	_teardown()


func test_the_inventory_grid_shows_eight_cards_and_a_truthful_detail() -> void:
	## Réf. 04 : HUIT cartes toujours visibles (les vides estompées — la
	## capacité réelle ne se cache pas), et un panneau de détail dont CHAQUE
	## valeur vient de la définition sélectionnée — comparée ici à la vraie
	## ressource, pas à une constante recopiée.
	await _setup()
	var spear: WeaponDefinition = load("res://resources/weapons/spear.tres") \
		as WeaponDefinition
	_player.inventory().add_weapon(WeaponInstance.create(spear))
	_shell.toggle_inventory()
	await _settle(3)
	check(_shell.is_inventory_open(), "préalable : inventaire ouvert")
	check_equal(_shell.inventory_card_count(), 8,
		"HUIT cartes affichées, vides comprises (§11.3)")

	_shell.equip_slot(1)   # la lance, derrière l'épée de départ
	await _settle(2)
	check_equal(_shell.detail_name_text(), spear.display_name.to_upper(),
		"le détail nomme l'arme sélectionnée")
	check_approx(_shell.detail_conductivity_shown(), spear.conductivity, 0.001,
		"conductivité affichée = définition (%.2f)" % spear.conductivity)
	check(_shell.detail_stats_text().contains("%.1f" % spear.reach_m),
		"la portée affichée vient de la définition")
	check(_shell.detail_stats_text().contains("%.0f" % spear.base_damage),
		"les dégâts affichés aussi")
	_shell.toggle_inventory()
	await _settle(2)
	_teardown()


func test_the_weapon_card_segments_follow_real_durability() -> void:
	## Réf. 03/04 : durabilité SEGMENTÉE depuis l'instance réelle — 24/24 →
	## 4 crans pleins ; 6/24 → un seul. Aucune valeur recopiée à la main.
	await _setup()
	await _settle(3)
	var full: Array[float] = _shell.durability_segment_values()
	check_equal(full.size(), 4, "quatre crans")
	check(full[0] > 0.99 and full[3] > 0.99, "arme neuve : tous pleins")

	_player.inventory().equipped().current_durability = 6
	await _settle(20)   # rafraîchi par le tick HUD (0,1 s)
	var worn: Array[float] = _shell.durability_segment_values()
	check_approx(worn[0], 1.0, 0.01, "6/24 : le premier cran tient")
	check_approx(worn[1], 0.0, 0.01, "…le deuxième est vide")
	check_approx(worn[3], 0.0, 0.01, "…le dernier aussi")
	_teardown()
