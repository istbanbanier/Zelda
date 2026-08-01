## ART-P0 — l'Épée usée de production, de l'import au gameplay.
##
## Mesuré, jamais décoratif : l'import porte un vrai maillage UV-mappé (pas
## une boîte), les données .tres de gameplay sont INCHANGÉES au chiffre près,
## l'arme équipée porte le modèle (et le repli boîte reste contrôlé pour les
## armes sans modèle), l'usure sous 25 % ternit l'instance SANS toucher la
## ressource partagée, le pickup expose le modèle, l'icône est un rendu réel
## transparent, et AUCUN asset de test n'est référencé par une scène de jeu.
extends GateTestCase

const GLB: String = "res://assets/weapons/SM_WornSword.glb"
const MODEL_SCENE: String = "res://scenes/weapons/WornSword.tscn"
const SWORD_TRES: String = "res://resources/weapons/worn_sword.tres"
const PLAYER: String = "res://scenes/player/Player.tscn"
const PICKUP: String = "res://scenes/interactables/WeaponPickup.tscn"

var _world: Node3D = null
var _player: PlayerController = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _setup_player() -> void:
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
	for i: int in range(120):
		if _player.is_on_floor():
			break
		await _tree().physics_frame


func _teardown() -> void:
	if _world != null and is_instance_valid(_world):
		_world.get_parent().remove_child(_world)
		_world.queue_free()
	_world = null
	_player = null


func _hand_model() -> Node3D:
	var pivot: Node3D = _player.find_children("WeaponPivot", "Node3D", true, false)[0] \
		as Node3D
	var models: Array[Node] = pivot.find_children("*", "WeaponModel", false, false)
	return models[0] as Node3D if not models.is_empty() else null


func _hand_box() -> MeshInstance3D:
	return _player.find_children("WeaponMesh", "MeshInstance3D", true, false)[0] \
		as MeshInstance3D


func test_the_glb_imports_a_real_uv_mapped_mesh_not_a_box() -> void:
	## L'import réel : un maillage triangulé travaillé (une boîte extrudée en
	## ferait 12), avec UV — le refus « simple boîte » du gate est mesurable.
	var packed: PackedScene = load(GLB) as PackedScene
	check_not_null(packed, "le .glb importe")
	var instance: Node = packed.instantiate()
	var meshes: Array[Node] = instance.find_children("*", "MeshInstance3D", true, false)
	check_equal(meshes.size(), 1, "un seul MeshInstance3D")
	var mesh: Mesh = (meshes[0] as MeshInstance3D).mesh
	var triangles: int = 0
	for surface: int in range(mesh.get_surface_count()):
		triangles += mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size() / 3
		check(mesh.surface_get_arrays(surface)[Mesh.ARRAY_TEX_UV] != null,
			"la surface %d est UV-mappée" % surface)
	check(triangles >= 300 and triangles <= 5000,
		"%d triangles : travaillé, dans le budget prop §7.10 (une boîte = 12)"
		% triangles)
	check_equal(mesh.get_surface_count(), 1, "un matériau unique (atlas)")
	instance.free()


func test_the_tres_gameplay_data_is_untouched_and_now_carries_the_model() -> void:
	## Le branchement du visuel ne change AUCUN chiffre de gameplay (§11.1).
	var definition: WeaponDefinition = load(SWORD_TRES) as WeaponDefinition
	check_equal(String(definition.id), "worn_sword", "id inchangé")
	check_approx(definition.base_damage, 12.0, 0.001, "dégâts 12")
	check_approx(definition.reach_m, 1.7, 0.001, "portée 1,7 m")
	check_equal(definition.max_durability, 24, "durabilité 24")
	check_approx(definition.conductivity, 0.85, 0.001, "conductivité 0,85")
	check_not_null(definition.mesh_scene, "…et le modèle de production est branché")
	check_not_null(definition.icon, "…avec son icône")
	check(definition.icon.resource_path.begins_with("res://assets/weapons/"),
		"icône RENDUE depuis le modèle, versionnée dans assets/weapons/")


func test_the_equipped_sword_wears_the_model_and_others_fall_back_to_the_box() -> void:
	## En main : le modèle remplace la boîte pour l'Épée usée ; la lance (sans
	## modèle) garde la boîte graybox — le repli est CONTRÔLÉ, pas un trou.
	await _setup_player()
	await _settle(3)
	var model: Node3D = _hand_model()
	check_not_null(model, "l'Épée usée équipée porte le modèle de production")
	check(not _hand_box().visible, "…et la boîte graybox est rangée")

	var inventory: InventoryComponent = _player.inventory()
	inventory.add_weapon(WeaponInstance.create(
		load("res://resources/weapons/spear.tres") as WeaponDefinition))
	inventory.equip_next()
	await _settle(2)
	check(_hand_model() == null, "la lance n'a pas de modèle : le sien est libéré")
	check(_hand_box().visible, "…et la boîte graybox revient (repli contrôlé)")

	inventory.equip_next()   # retour à l'épée
	await _settle(2)
	check_not_null(_hand_model(), "le modèle revient avec l'épée")
	_teardown()


func test_wear_under_25_percent_dulls_the_instance_not_the_shared_resource() -> void:
	## §11.2 + ART-P0 : sous 25 %, le modèle TERNIT — par instance. La
	## ressource partagée (définition, matériaux du .glb) reste intacte : un
	## second exemplaire neuf reste éclatant.
	await _setup_player()
	await _settle(3)
	var inventory: InventoryComponent = _player.inventory()
	var sword: WeaponInstance = inventory.equipped()
	inventory.add_weapon(WeaponInstance.create(
		load("res://resources/weapons/wood_club.tres") as WeaponDefinition))
	sword.current_durability = 5   # 5/24 < 25 %
	inventory.equip_next()
	inventory.equip_previous()     # ré-équipe l'épée usée → rafraîchit l'usure
	await _settle(2)
	var model: Node3D = _hand_model()
	check(bool(model.call("is_worn")), "sous 25 % : le modèle passe en état USÉ")

	var fresh: Node3D = (load(MODEL_SCENE) as PackedScene).instantiate() as Node3D
	_world.add_child(fresh)
	await _settle(1)
	check(not bool(fresh.call("is_worn")),
		"un exemplaire NEUF de la même scène reste neuf — rien de partagé n'a été terni")
	fresh.queue_free()
	_teardown()


func test_the_ground_pickup_presents_the_model_and_still_hands_it_over() -> void:
	## Au sol : le modèle remplace la boîte du pickup, et le ramassage RÉEL
	## verse toujours l'arme (le visuel n'a pas cassé l'interaction).
	await _setup_player()
	var pickup: WeaponPickup = (load(PICKUP) as PackedScene).instantiate() as WeaponPickup
	pickup.definition = load(SWORD_TRES) as WeaponDefinition
	pickup.pickup_id = &"test.pickup.worn_sword.01"
	pickup.position = Vector3(0, 0, 1.5)
	_world.add_child(pickup)
	await _settle(3)
	check_not_null(pickup.get_node_or_null("ProductionModel"),
		"le pickup expose le modèle de production")
	check(not (pickup.get_node("Mesh") as MeshInstance3D).visible,
		"…et sa boîte graybox est cachée")
	var before: int = _player.inventory().weapon_count()
	check(pickup.interact(_player), "le ramassage fonctionne toujours")
	check_equal(_player.inventory().weapon_count(), before + 1,
		"…et verse bien l'exemplaire")
	_teardown()


func test_the_icon_is_a_real_transparent_render_and_no_test_asset_ships() -> void:
	## L'icône : un rendu 256×256 avec de VRAIS pixels transparents (prouve le
	## rendu détouré, pas un aplat). Et aucune scène de JEU ne référence les
	## assets de test du pipeline.
	var icon: Texture2D = (load(SWORD_TRES) as WeaponDefinition).icon
	var image: Image = icon.get_image()
	check_equal(image.get_width(), 256, "icône 256 px")
	var transparent: int = 0
	var opaque: int = 0
	for y: int in range(0, 256, 8):
		for x: int in range(0, 256, 8):
			if image.get_pixel(x, y).a < 0.05:
				transparent += 1
			elif image.get_pixel(x, y).a > 0.95:
				opaque += 1
	check(transparent > 200, "fond majoritairement transparent (%d)" % transparent)
	check(opaque > 30, "silhouette d'épée réellement présente (%d)" % opaque)

	var offenders: Array[String] = []
	for scene_path: String in _game_scene_files("res://scenes"):
		var text: String = FileAccess.get_file_as_string(scene_path)
		if text.contains("SM_TestCube") or text.contains("SK_TestRigAnim"):
			offenders.append(scene_path)
	check(offenders.is_empty(),
		"aucun asset de TEST référencé par une scène de jeu : %s" % str(offenders))


func _game_scene_files(root: String) -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(root)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var path: String = root + "/" + entry
		if dir.current_is_dir():
			if entry != "tests" and not entry.begins_with("."):
				found.append_array(_game_scene_files(path))
		elif entry.ends_with(".tscn"):
			found.append(path)
		entry = dir.get_next()
	dir.list_dir_end()
	return found
