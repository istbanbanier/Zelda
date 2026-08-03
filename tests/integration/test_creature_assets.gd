## Phase H lots H.3 et H.4 — COLOSSE et CHASSEUR montés pour de bon.
##
## Les modèles existaient déjà au commit précédent, mais aucune scène ne les
## montait : en jeu, les deux ennemis restaient des boîtes. Ces tests
## vérifient qu'ils sont désormais RÉELLEMENT dans le jeu, aux cotes de
## VISUAL_ASSET_BIBLE §14.4 et §14.5, sans laisser un graybox planté dedans.
##
## Ce qu'ils ne prouvent pas, et qui reste un essai humain : la lisibilité
## des silhouettes en aplat noir à 25 m (§30.3 de la bible).
extends GateTestCase

const TROLL: String = "res://scenes/enemies/RavineTroll.tscn"
const HUNTER: String = "res://scenes/enemies/CentaurHunter.tscn"


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open(path: String) -> Node3D:
	var scene: Node3D = (load(path) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(scene)
	await _settle(8)
	return scene


func _close(scene: Node) -> void:
	scene.get_parent().remove_child(scene)
	scene.queue_free()
	await _settle(2)


## AABB des maillages VISIBLES seulement : un graybox masqué ne doit pas
## gonfler la mesure.
func _visible_bounds(root: Node) -> AABB:
	var bounds: AABB = AABB()
	var first: bool = true
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null or not mesh.visible:
			continue
		var world: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = world if first else bounds.merge(world)
		first = false
	return bounds


func test_the_colossus_is_a_real_body_not_a_capsule() -> void:
	var troll: Node3D = await _open(TROLL)
	var visual: CharacterVisual = troll.get_node("Pivot/CharacterVisual") \
		as CharacterVisual
	check_not_null(visual, "le colosse porte un CharacterVisual")
	check(not visual.is_fallback_active(),
		"le modèle est MONTÉ — plus de repli graybox")
	# Le graybox a disparu : aucune boîte plantée dans le modèle.
	for child: Node in troll.get_node("Pivot").get_children():
		if child is MeshInstance3D:
			check(not (child as MeshInstance3D).visible,
				"graybox %s masqué" % child.name)
	var bounds: AABB = _visible_bounds(visual)
	check(bounds.size.y >= 3.7 and bounds.size.y <= 4.3,
		"haut %.2f m (bible §14.4 : 3,7-4,3)" % bounds.size.y)
	# §12.4 : « silhouette massive ASYMÉTRIQUE ». Le modèle porte une
	# croissance rocheuse sur UN seul bras — les deux moitiés diffèrent.
	var names: Array[String] = []
	for node: Node in visual.find_children("*", "MeshInstance3D", true, false):
		names.append(node.name)
	check(" ".join(names).contains("TrollRock"),
		"les plaques et la croissance rocheuse sont une pièce à part")
	check(" ".join(names).contains("TrollNodule"),
		"le nodule minéral — point faible de §12.4 — est modélisé")
	await _close(troll)


## §12.4 : le point faible est DANS LE DOS. La hurtbox arrière (×2) doit
## donc se trouver du même côté que le nodule, pas en face.
func test_the_weak_point_nodule_sits_on_the_side_the_back_hurtbox_guards() -> void:
	var troll: Node3D = await _open(TROLL)
	var visual: CharacterVisual = troll.get_node("Pivot/CharacterVisual") \
		as CharacterVisual
	var nodule: MeshInstance3D = null
	for node: Node in visual.find_children("*", "MeshInstance3D", true, false):
		if node.name.contains("Nodule"):
			nodule = node as MeshInstance3D
			break
	check_not_null(nodule, "le nodule est là")
	var nodule_z: float = (nodule.global_transform * nodule.get_aabb()) \
		.get_center().z
	var back: Area3D = troll.get_node("Pivot/BackHurtbox") as Area3D
	var front: Area3D = troll.get_node("Pivot/Hurtbox") as Area3D
	check(signf(nodule_z) == signf(back.position.z),
		"le nodule (z = %+.2f) est du côté de la hurtbox ARRIÈRE (z = %+.2f)"
		% [nodule_z, back.position.z])
	check((back as HurtboxComponent).weak_point_multiplier
		> (front as HurtboxComponent).weak_point_multiplier,
		"…et c'est bien ce côté qui porte le multiplicateur de point faible")
	await _close(troll)


func test_the_hunter_is_a_quadruped_and_not_a_horse() -> void:
	var hunter: Node3D = await _open(HUNTER)
	var visual: CharacterVisual = hunter.get_node("Pivot/CharacterVisual") \
		as CharacterVisual
	check_not_null(visual, "le chasseur porte un CharacterVisual")
	check(not visual.is_fallback_active(), "le modèle est MONTÉ")
	# Le chasseur portait DEUX boîtes de graybox : les deux doivent partir.
	var hidden: int = 0
	for child: Node in hunter.get_node("Pivot").get_children():
		if child is MeshInstance3D:
			check(not (child as MeshInstance3D).visible,
				"graybox %s masqué" % child.name)
			hidden += 1
	check(hidden >= 2,
		"les DEUX boîtes du chasseur sont masquées (%d)" % hidden)

	var bounds: AABB = _visible_bounds(visual)
	check(bounds.size.y >= 3.0 and bounds.size.y <= 3.5,
		"haut %.2f m (bible §14.5 : 3,0-3,5)" % bounds.size.y)
	check(bounds.size.z >= 4.0 and bounds.size.z <= 4.8,
		"long %.2f m (bible §14.5 : 4,0-4,8)" % bounds.size.z)
	# §12.5 : « corps bas ALLONGÉ », pas un cheval. Il est nettement plus
	# long que large, et plus long que haut.
	check(bounds.size.z > bounds.size.x * 2.5,
		"le corps est ALLONGÉ : %.2f m de long pour %.2f m de large"
		% [bounds.size.z, bounds.size.x])
	check(bounds.size.z > bounds.size.y,
		"…et plus long que haut (%.2f contre %.2f)"
		% [bounds.size.z, bounds.size.y])
	await _close(hunter)


## Les deux créatures regardent le +Z du pivot, comme tous les ennemis :
## sinon elles frapperaient dans leur dos. Vérifié par la position du
## volume de frappe par rapport au corps.
func test_both_creatures_face_the_direction_they_strike() -> void:
	for entry: Array in [[TROLL, "Pivot/ArmHitbox"], [HUNTER, "Pivot/SlashHitbox"]]:
		var scene: Node3D = await _open(entry[0] as String)
		var visual: CharacterVisual = scene.get_node("Pivot/CharacterVisual") \
			as CharacterVisual
		var hitbox: Area3D = scene.get_node(entry[1] as String) as Area3D
		check(hitbox.position.z > 0.0,
			"%s : le volume de frappe est devant (+Z)"
			% (entry[0] as String).get_file())
		# La tête doit être du même côté que la frappe. On la cherche par le
		# maillage visible dont le centre est le plus haut ET le plus avancé.
		var head_z: float = 0.0
		var best: float = -999.0
		for node: Node in visual.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			if mesh.mesh == null or not mesh.visible:
				continue
			var centre: Vector3 = (mesh.global_transform * mesh.get_aabb()) \
				.get_center()
			var score: float = centre.y + centre.z
			if score > best:
				best = score
				head_z = centre.z
		check(head_z > -0.6,
			"%s : la masse haute et avancée est du côté de la frappe (z = %+.2f)"
			% [(entry[0] as String).get_file(), head_z])
		await _close(scene)


## Le point dur du montage : un modèle ne doit RIEN changer au combat.
## Ces deux tests laissent l'IA décider, comme en jeu — perception, choix,
## télégraphe, frappe — et vérifient que le joueur PERD DES POINTS DE VIE
## avec le hero asset monté. C'est ce qui distingue « le modèle s'affiche »
## de « le modèle est intégré ».
##
## Première version écartée : elle appelait `AttackController.try_attack()`
## puis `update()` à la main. Le socle `EnemyBase` n'avance l'attaque QUE
## dans l'état ATTACK — le coup partait sans jamais devenir actif, et le
## test mesurait mon harnais, pas le jeu.
const PLAYER: String = "res://scenes/player/Player.tscn"


func _arena_with(enemy_path: String, player_at: Vector3,
		enemy_at: Vector3) -> Array:
	var world: Node3D = Node3D.new()
	_tree().root.add_child(world)
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(160, 1, 160)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, 0)
	world.add_child(floor_body)
	var player: PlayerController = (load(PLAYER) as PackedScene) \
		.instantiate() as PlayerController
	player.position = player_at
	world.add_child(player)
	player.set_intent_source(InputIntent.new())
	var enemy: Node3D = (load(enemy_path) as PackedScene).instantiate() as Node3D
	enemy.position = enemy_at
	world.add_child(enemy)
	var to_player: Vector3 = player_at - enemy_at
	(enemy.get_node("Pivot") as Node3D).rotation.y = atan2(to_player.x,
		to_player.z)
	await _settle(2)
	for i: int in range(120):
		if player.is_on_floor():
			break
		await _tree().physics_frame
	return [world, player, enemy]


func _fight(enemy_path: String, label: String) -> void:
	var setup: Array = await _arena_with(enemy_path, Vector3(0, 0.1, 2.2),
		Vector3(0, 0.1, 0))
	var world: Node3D = setup[0]
	var player: PlayerController = setup[1]
	var enemy: Node3D = setup[2]
	var visual: CharacterVisual = enemy.get_node("Pivot/CharacterVisual") \
		as CharacterVisual
	check(not visual.is_fallback_active(), "%s : le modèle est monté" % label)
	var health: HealthComponent = player.health()
	var before: float = health.current()
	var attacked: bool = false
	for i: int in range(600):
		await _tree().physics_frame
		if String(enemy.call("state_name")) == "attack":
			attacked = true
		if health.current() < before:
			break
	check(attacked, "%s : l'IA a bien engagé une attaque" % label)
	check(health.current() < before,
		"%s : le coup PORTE avec le hero asset monté (%.0f → %.0f PV)"
		% [label, before, health.current()])
	world.get_parent().remove_child(world)
	world.queue_free()
	await _settle(2)


func test_the_colossus_still_lands_a_blow_with_the_model_mounted() -> void:
	await _fight(TROLL, "colosse")


func test_the_hunter_still_lands_a_blow_with_the_model_mounted() -> void:
	await _fight(HUNTER, "chasseur")
