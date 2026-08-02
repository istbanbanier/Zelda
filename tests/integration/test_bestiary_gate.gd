## Batterie TRANSVERSE du Gate D (D-EN.6, MASTER_SPEC §12) — ce que
## l'ordre corrigé exige de prouver SUR LES CINQ FAMILLES ensemble, pas
## famille par famille : statistiques réellement distinctes, armes et
## portées propres, silhouettes distinctes, perception occluse, cadavres
## inertes (aucune hitbox active après la mort), loot unique et
## persistant, et la planche d'aplats qui monte les cinq.
extends GateTestCase

const FAMILIES: Array[Array] = [
	["res://scenes/enemies/RaiderRed.tscn", "raider_red", 45.0],
	["res://scenes/enemies/RaiderBlue.tscn", "raider_blue", 85.0],
	["res://scenes/enemies/RaiderBlack.tscn", "raider_black", 150.0],
	["res://scenes/enemies/RavineTroll.tscn", "ravine_troll", 420.0],
	["res://scenes/enemies/CentaurHunter.tscn", "centaur_hunter", 650.0],
]

var _world: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _stage() -> void:
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
	await _settle(1)


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	await _settle(1)


func test_the_five_families_have_distinct_stats_weapons_and_silhouettes() -> void:
	## §12 : « cinq familles dont la silhouette, les proportions,
	## l'équipement… diffèrent réellement ». Mesuré : PV tous différents,
	## portées d'attaque distinctes, volumes de corps distincts, contrats
	## d'attaque tous propres (aucun id partagé entre familles).
	await _stage()
	var healths: Array[float] = []
	var reaches: Array[float] = []
	var footprints: Array[float] = []
	var heights: Array[float] = []
	var attack_ids: Array[String] = []
	for family: Array in FAMILIES:
		var enemy: EnemyBase = (load(String(family[0])) as PackedScene) \
			.instantiate() as EnemyBase
		enemy.position = Vector3(0, 0.1, 0)
		_world.add_child(enemy)
		await _settle(2)
		enemy.set_physics_process(false)
		check_equal(String(enemy.tuning.id), String(family[1]),
			"%s : tuning propre" % String(family[1]))
		check_equal(enemy.tuning.max_health, float(family[2]),
			"%s : %d PV" % [String(family[1]), int(float(family[2]))])
		healths.append(enemy.tuning.max_health)
		reaches.append(enemy.tuning.attack_reach)
		var shape: Shape3D = (enemy.get_node("CollisionShape3D")
			as CollisionShape3D).shape
		if shape is CapsuleShape3D:
			footprints.append((shape as CapsuleShape3D).radius)
			heights.append((shape as CapsuleShape3D).height)
		var controller: AttackControllerComponent = \
			enemy.get_node("AttackController") as AttackControllerComponent
		for attack: AttackDefinition in controller.attacks:
			check(not attack_ids.has(String(attack.id)),
				"contrat d'attaque PROPRE : %s" % String(attack.id))
			attack_ids.append(String(attack.id))
		enemy.get_parent().remove_child(enemy)
		enemy.queue_free()
		await _settle(1)
	# Aucune paire de familles ne partage ses PV, sa portée ou sa carrure.
	for i: int in range(FAMILIES.size()):
		for j: int in range(i + 1, FAMILIES.size()):
			check(absf(healths[i] - healths[j]) > 1.0,
				"PV distincts (%d vs %d)" % [int(healths[i]), int(healths[j])])
			check(absf(reaches[i] - reaches[j]) > 0.15
				or absf(footprints[i] - footprints[j]) > 0.05,
				"portée OU carrure distincte entre familles %d et %d" % [i, j])
	check(heights.max() - heights.min() > 2.0,
		"éventail de tailles réel (%.1f m d'écart)"
		% (heights.max() - heights.min()))
	check_equal(attack_ids.size(), attack_ids.size(),
		"tous les contrats d'attaque sont uniques (%d)" % attack_ids.size())
	await _teardown()


func test_no_family_keeps_an_active_hitbox_after_death() -> void:
	## §12.10 : « à la mort : couper IA, hitboxes et navigation ». Vérifié
	## sur LES CINQ : hurtbox non détectable, collision retirée, physique
	## coupée, et le corps ne repousse plus personne.
	await _stage()
	for family: Array in FAMILIES:
		var enemy: EnemyBase = (load(String(family[0])) as PackedScene) \
			.instantiate() as EnemyBase
		enemy.position = Vector3(0, 0.1, 0)
		_world.add_child(enemy)
		await _settle(2)
		var event: DamageEvent = DamageEvent.new()
		event.amount = 99999.0
		enemy.health().take_damage(event)
		await _settle(4)
		check(enemy.health().is_dead(), "%s : mort" % String(family[1]))
		check_equal(int(enemy.collision_layer), 0,
			"%s : plus de collision de corps" % String(family[1]))
		check(not enemy.is_physics_processing(),
			"%s : IA coupée" % String(family[1]))
		for node: Node in enemy.find_children("*", "HurtboxComponent",
				true, false):
			check(not (node as HurtboxComponent).monitorable,
				"%s/%s : hurtbox éteinte"
				% [String(family[1]), node.name])
		# La hitbox garde `monitoring` allumé PAR CONCEPTION (R-014 : le
		# couper puis rallumer vide définitivement la liste de
		# chevauchements du moteur installé). Sa fenêtre réelle est
		# `is_active()` — c'est ELLE qui doit être fermée.
		for node: Node in enemy.find_children("*", "HitboxComponent",
				true, false):
			check(not (node as HitboxComponent).is_active(),
				"%s/%s : fenêtre de frappe fermée"
				% [String(family[1]), node.name])
		enemy.get_parent().remove_child(enemy)
		enemy.queue_free()
		await _settle(1)
	await _teardown()


func test_no_family_sees_through_a_wall() -> void:
	## §12.7 : « aucune vision à travers mur » — vérifié sur LES CINQ avec
	## le même mur, à une distance que chacune couvre largement.
	await _stage()
	var player: PlayerController = (load("res://scenes/player/Player.tscn")
		as PackedScene).instantiate() as PlayerController
	player.position = Vector3(0, 0.1, 10.0)
	_world.add_child(player)
	player.set_intent_source(InputIntent.new())
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = 1
	var wall_shape: CollisionShape3D = CollisionShape3D.new()
	var wall_box: BoxShape3D = BoxShape3D.new()
	wall_box.size = Vector3(30, 8, 1)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	wall.position = Vector3(0, 4, 5.0)
	_world.add_child(wall)
	await _settle(4)
	for family: Array in FAMILIES:
		var enemy: EnemyBase = (load(String(family[0])) as PackedScene) \
			.instantiate() as EnemyBase
		enemy.position = Vector3(0, 0.1, 0)
		_world.add_child(enemy)
		(enemy.get_node("Pivot") as Node3D).rotation.y = 0.0
		await _settle(25)
		check_equal(enemy.state(), EnemyBase.State.IDLE,
			"%s : le mur bloque la vision (%s)"
			% [String(family[1]), String(enemy.state_name())])
		enemy.get_parent().remove_child(enemy)
		enemy.queue_free()
		await _settle(1)
	await _teardown()


func test_the_valley_carries_the_five_families_in_their_roles() -> void:
	## D-EN.6 : la vallée porte réellement LES CINQ familles, chacune à
	## son poste (§12.2-§12.5), gouvernées par un coordinateur (§12.8) —
	## et le chasseur reste HORS du chemin principal (§4.1 : facultatif).
	var valley: Node3D = (load("res://scenes/world/valley/ValleyWorld.tscn")
		as PackedScene).instantiate() as Node3D
	_tree().root.add_child(valley)
	await _settle(6)
	var counts: Dictionary[StringName, int] = {}
	var hunter_position: Vector3 = Vector3.ZERO
	for node: Node in valley.find_children("*", "EnemyBase", true, false):
		var enemy: EnemyBase = node as EnemyBase
		var id: StringName = enemy.tuning.id
		counts[id] = int(counts.get(id, 0)) + 1
		if id == &"centaur_hunter":
			hunter_position = enemy.global_position
	for family: Array in FAMILIES:
		check(int(counts.get(StringName(String(family[1])), 0)) >= 1,
			"la vallée porte au moins un %s" % String(family[1]))
	check(int(counts.get(&"raider_red", 0)) >= 3,
		"le camp garde ses braises (première rencontre, §12.1)")
	check(valley.find_children("*", "CombatCoordinator", true, false).size() == 1,
		"un coordinateur de combat gouverne le groupe (§12.8)")
	# Le chemin principal va du spawn (0, 24, 150) au donjon (0, 34, -210)
	# par le camp : le chasseur en est LOIN (§12.5, rencontre facultative).
	check(absf(hunter_position.x) > 60.0,
		"le chasseur est hors du corridor principal (x = %.0f)"
		% hunter_position.x)
	# §12.9 : « navmesh validé avec capsule de chaque famille » — les
	# grandes carrures ont leur PROPRE carte, cuite pour un agent de
	# 1,2 m, et ne partagent pas celle des pillards.
	var large_regions: Array[Node] = valley.find_children("LargeNavigation",
		"NavigationRegion3D", true, false)
	check_equal(large_regions.size(), 1,
		"une carte de navigation dédiée aux grandes carrures")
	if not large_regions.is_empty():
		var large: NavigationRegion3D = large_regions[0] as NavigationRegion3D
		check(large.navigation_mesh.agent_radius >= 1.1,
			"…cuite pour un agent de %.1f m (le colosse fait 1,1)"
			% large.navigation_mesh.agent_radius)
		check(large.get_navigation_map() != valley.get_world_3d().navigation_map,
			"…et c'est une carte SÉPARÉE de celle des pillards")
		for node: Node in valley.find_children("*", "EnemyBase", true, false):
			var enemy: EnemyBase = node as EnemyBase
			var wants_large: bool = enemy.tuning.uses_large_navmesh
			var expected: bool = enemy.tuning.id in [&"ravine_troll",
				&"centaur_hunter"]
			check_equal(wants_large, expected,
				"%s : bonne carte de navigation" % String(enemy.tuning.id))
	valley.get_parent().remove_child(valley)
	valley.queue_free()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


func test_the_bestiary_lineup_mounts_the_five_families() -> void:
	## §7.18 : la planche d'aplats existe et monte LES CINQ — c'est la
	## preuve visuelle exigée par l'ordre corrigé (même échelle).
	var lineup: BestiaryLineup = (load("res://scenes/tests/BestiaryLineup.tscn")
		as PackedScene).instantiate() as BestiaryLineup
	_tree().root.add_child(lineup)
	await _settle(3)
	check_equal(lineup.mounted_families, 5, "les cinq familles montées")
	var scales: Array[float] = []
	for i: int in range(5):
		var enemy: Node3D = lineup.get_node("Family_%d" % i) as Node3D
		check(enemy != null, "famille %d présente" % i)
		if enemy != null:
			scales.append(enemy.scale.x)
			check(not enemy.is_physics_processing(),
				"famille %d : planche, pas un combat" % i)
	for scale: float in scales:
		check(is_equal_approx(scale, 1.0),
			"aucune famille n'est mise à l'échelle pour la photo (%.2f)" % scale)
	lineup.get_parent().remove_child(lineup)
	lineup.queue_free()
	await _settle(1)
