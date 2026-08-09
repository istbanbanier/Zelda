## LA PORTE DU DONJON RÉPOND AU CENTRE DU BATTANT — RÉGRESSION DE P9c.
##
## Défaut mesuré le 2026-08-09 par `test_physical_run.gd` : debout à 0,75 m de
## `DungeonDoor`, parfaitement en face (`cos = 1,00`), au sol, en locomotion, la
## porte bien dans le groupe `interactable`, `_select_interactable()` ne rendait
## RIEN. Le rayon de `_has_interact_los()` — couche 1 — était coupé par
## `SealedSeam`, une veine cyan décorative construite en `StaticBody3D` à
## `z = −12,50`, devant le battant à `z = −12,75`.
##
## Un pas de côté suffisait à ouvrir. C'est précisément ce qui rend le défaut
## méchant : il n'empêche rien, il rend la porte MUETTE à l'endroit exact où un
## joueur se place. Le playtest humain du 2026-08-07 a montré la suite — le
## joueur appuie sur `E`, n'obtient rien, conclut que la touche ne marche pas et
## cesse d'essayer.
##
## Ce cas éprouve la correction ET ses effets de bord : la veine doit rester
## visible, la porte garder sa collision, et le décor cesser d'être un obstacle
## de couche 1. Il échoue si l'un des trois régresse.
extends GateTestCase

const VESTIBULE: String = "res://scenes/world/citadel/CitadelVestibule.tscn"
## Là où un joueur s'arrête : franchement dans la portée de 2,2 m, sans coller
## au battant.
const STAND_OFF: float = 0.75

var _vestibule: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _open() -> void:
	remember_root()
	_vestibule = (load(VESTIBULE) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_vestibule)
	await _settle(8)


func _close() -> void:
	if _vestibule != null and is_instance_valid(_vestibule):
		_vestibule.get_parent().remove_child(_vestibule)
		_vestibule.queue_free()
		_vestibule = null
	await restore_root()
	var game_state: Node = _tree().root.get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_flow", 0)
		game_state.call("consume_pending_spawn")
	await _settle(2)


func _seam() -> Node3D:
	var found: Array[Node] = _vestibule.find_children("SealedSeam", "", true, false)
	return found[0] as Node3D if not found.is_empty() else null


func _door() -> Node3D:
	var found: Array[Node] = _vestibule.find_children("DungeonDoor", "", true, false)
	return found[0] as Node3D if not found.is_empty() else null


## Place le héros À 75 cm DEVANT le battant, tourné vers lui.
##
## Poser puis orienter est légitime ici : ce cas juge la SÉLECTION, pas le
## trajet. Le trajet à pied est prouvé par `test_physical_run.gd`, qui arrive au
## même endroit sans qu'on le déplace.
func _stand_in_front(player: PlayerController, door: Node3D) -> void:
	var front: Vector3 = door.global_position + Vector3(0.0, 0.0, STAND_OFF)
	front.y = _vestibule.global_position.y
	player.global_position = Vector3(front.x, player.global_position.y, front.z)
	var visual: Node3D = player.get_node_or_null("VisualRoot") as Node3D
	if visual != null:
		var to_door: Vector3 = door.global_position - player.global_position
		visual.rotation.y = atan2(to_door.x, to_door.z)
	await _settle(6)


func test_the_cyan_seam_is_decor_and_never_an_interaction_obstacle() -> void:
	await _open()
	var seam: Node3D = _seam()
	check(seam != null, "la veine cyan EXISTE toujours dans le vestibule")
	if seam == null:
		await _close()
		return
	# Elle doit rester VISIBLE : la correction ne devait rien supprimer.
	var mesh: MeshInstance3D = seam as MeshInstance3D
	if mesh == null:
		var inner: Array[Node] = seam.find_children("*", "MeshInstance3D", true, false)
		mesh = inner[0] as MeshInstance3D if not inner.is_empty() else null
	check(mesh != null and mesh.visible and mesh.mesh != null,
		"…avec une géométrie visible (%s)" % (seam.get_class()))
	var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D \
		if mesh != null else null
	check(material != null and material.emission_enabled,
		"…et son émission cyan (émissive=%s)"
			% (str(material.emission_enabled) if material != null else "sans matériau"))
	# Et elle ne doit PLUS être un corps de collision.
	check(not (seam is CollisionObject3D),
		"…mais ce n'est PLUS un corps de collision (classe : %s)" % seam.get_class())
	var shapes: Array[Node] = seam.find_children("*", "CollisionShape3D", true, false)
	check(shapes.is_empty(),
		"…et elle ne porte aucune forme de collision (trouvées : %d)" % shapes.size())
	await _close()


func test_the_door_keeps_its_body_and_its_look() -> void:
	await _open()
	var door: Node3D = _door()
	check(door != null, "la porte du donjon est là")
	if door == null:
		await _close()
		return
	# La correction visait le décor, pas la porte : elle garde tout.
	var body: StaticBody3D = door as StaticBody3D
	check(body != null and body.collision_layer == 1,
		"…et conserve son corps sur la couche 1 (couche = %d)"
			% (body.collision_layer if body != null else -1))
	var shapes: Array[Node] = door.find_children("*", "CollisionShape3D", true, false)
	check(not shapes.is_empty(),
		"…et sa forme de collision (trouvées : %d)" % shapes.size())
	var meshes: Array[Node] = door.find_children("*", "MeshInstance3D", true, false)
	check(not meshes.is_empty(),
		"…et son apparence (maillages : %d)" % meshes.size())
	await _close()


func test_the_player_selects_the_door_from_dead_centre() -> void:
	await _open()
	var player: PlayerController = _vestibule.call("player") as PlayerController \
		if _vestibule.has_method("player") else null
	var door: Node3D = _door()
	check(player != null and door != null,
		"préalable : un joueur et une porte dans le vestibule")
	if player == null or door == null:
		await _close()
		return
	await _stand_in_front(player, door)

	# 1. La portée du contrôleur, mesurée dans le plan horizontal comme lui.
	var flat: Vector3 = door.global_position - player.global_position
	flat.y = 0.0
	check(flat.length() <= PlayerController.INTERACT_RANGE,
		"distance ≤ %.2f m (mesurée : %.2f)"
			% [PlayerController.INTERACT_RANGE, flat.length()])

	# 2. Le cône, avec la MÊME convention que `_select_interactable()` : l'avant
	#    du héros est le +Z de son `VisualRoot`.
	var visual: Node3D = player.get_node_or_null("VisualRoot") as Node3D
	var facing: Vector3 = visual.global_transform.basis.z if visual != null else Vector3.ZERO
	facing.y = 0.0
	var dot: float = flat.normalized().dot(facing.normalized()) \
		if flat.length() > 0.01 and facing.length() > 0.01 else -9.0
	check(dot >= PlayerController.INTERACT_MIN_DOT,
		"cône valide : cos %.2f ≥ %.2f" % [dot, PlayerController.INTERACT_MIN_DOT])

	# 3. La ligne de vue, rejouée EXACTEMENT comme le contrôleur la trace.
	var exclude: Array[RID] = [player.get_rid()]
	var as_body: CollisionObject3D = door as CollisionObject3D
	if as_body != null:
		exclude.append(as_body.get_rid())
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		player.global_position + Vector3.UP * 1.2,
		door.global_position + Vector3.UP * 0.5, 1, exclude)
	var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
	var blocker: String = "libre"
	if not hit.is_empty():
		var who: Object = hit.get("collider")
		blocker = (who as Node).name if who is Node else str(who)
	check(hit.is_empty(),
		"ligne de vue LIBRE au centre du battant (obstacle : %s)" % blocker)

	# 4. Et la conclusion qui compte : le contrôleur DÉSIGNE cette porte, par
	#    identité — pas un homonyme, pas « quelque chose ».
	var picked: Node3D = player.call("current_interact_target") as Node3D
	if picked == null:
		# `current_interact_target()` est rafraîchie par cadence (1 tick sur 6) ;
		# on laisse passer une fenêtre complète plutôt que de conclure trop tôt.
		await _settle(12)
		picked = player.call("current_interact_target") as Node3D
	check(picked != null and picked.get_instance_id() == door.get_instance_id(),
		"le contrôleur DÉSIGNE `DungeonDoor` par identité (obtenu : %s)"
			% (picked.name if picked != null else "aucune cible"))
	await _close()
