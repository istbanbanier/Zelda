## Lot 9 — habillage du HeroShotLab avec les VRAIS modèles du dépôt
## (Quaternius CC0, déjà attribués — AD-001 : aucun téléchargement).
## Fail-first : écrit avant l'implémentation.
##
## Contrats : le lab porte un nœud `Dressing` avec de vrais modèles
## (arbres d'au moins deux espèces, rochers, props de camp) ; chaque
## surface habillée est PEINTE (le painterly du Lot 2) en gardant sa
## vraie texture ; les poses varient (§7.3 : « une simple rotation de
## 90° ne suffit pas ») ; et les fenêtres §1.1 restent tenues (le test
## des anchors le garantit déjà — on vérifie ici que l'habillage ne
## s'est pas posé DEVANT le héros, le camp, le pylône ou la citadelle).
extends GateTestCase

const LAB: String = "res://scenes/lookdev/HeroShotLab.tscn"
const PAINTERLY: String = \
	"res://shaders/characters/SH_CharacterPainterly.gdshader"
const PAINTERLY_CUTOUT: String = \
	"res://shaders/characters/SH_CharacterPainterlyCutout.gdshader"

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null
	await _settle(3)


func _open_lab() -> HeroShotLab:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var lab: HeroShotLab = (load(LAB) as PackedScene).instantiate() \
		as HeroShotLab
	_root.add_child(lab)
	await _settle(6)
	return lab


func test_the_lab_wears_real_models_from_the_repo() -> void:
	var lab: HeroShotLab = await _open_lab()
	var dressing: Node3D = lab.get_node_or_null("Dressing") as Node3D
	check(dressing != null, "le nœud Dressing existe")
	if dressing == null:
		await _teardown()
		return
	var trees: int = 0
	var species: Dictionary = {}
	var rocks: int = 0
	var props: int = 0
	for child: Node in dressing.get_children():
		var item: String = String(child.name)
		if item.contains("Tree") or item.contains("Pine"):
			trees += 1
			species[item.rstrip("0123456789_")] = true
		elif item.contains("Rock"):
			rocks += 1
		elif item.contains("Banner") or item.contains("Crate") \
				or item.contains("Barrel") or item.contains("Cauldron"):
			props += 1
	check(trees >= 5 and species.size() >= 2,
		"au moins 5 arbres de 2 espèces et plus (%d arbres, %d espèces)"
		% [trees, species.size()])
	check(rocks >= 4, "au moins 4 rochers réels (%d)" % rocks)
	check(props >= 3, "au moins 3 props de camp réels (%d)" % props)
	await _teardown()


func test_the_dressing_is_painted_and_varied() -> void:
	var lab: HeroShotLab = await _open_lab()
	var dressing: Node3D = lab.get_node_or_null("Dressing") as Node3D
	if dressing == null:
		check(false, "pas de Dressing")
		await _teardown()
		return
	var painted: int = 0
	var textured: int = 0
	var bare: Array[String] = []
	for node: Node in dressing.find_children("*", "MeshInstance3D",
			true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.mesh == null:
			continue
		for s: int in range(mesh.mesh.get_surface_count()):
			var material: ShaderMaterial = \
				mesh.get_surface_override_material(s) as ShaderMaterial
			if material == null or material.shader == null \
					or material.shader.resource_path not in \
						[PAINTERLY, PAINTERLY_CUTOUT]:
				bare.append("%s/s%d" % [mesh.name, s])
				continue
			painted += 1
			var texture: Variant = \
				material.get_shader_parameter("albedo_texture")
			if texture is Texture2D \
					and (texture as Texture2D).get_size().x > 1.0:
				textured += 1
	check(bare.is_empty(),
		"chaque surface habillée est peinte — nues : %s"
		% ", ".join(bare.slice(0, 8)))
	check(painted >= 10, "l'habillage est réellement peint (%d surfaces)"
		% painted)
	check(textured >= 5,
		"les modèles GARDENT leurs vraies textures (%d > 1 px)" % textured)
	# §7.3 : variation des poses — rotations et échelles pas toutes
	# identiques.
	var yaws: Dictionary = {}
	var scales: Dictionary = {}
	for child: Node in dressing.get_children():
		var item: Node3D = child as Node3D
		if item == null:
			continue
		yaws[snappedf(item.rotation_degrees.y, 1.0)] = true
		scales[snappedf(item.scale.x, 0.05)] = true
	check(yaws.size() >= 4 and scales.size() >= 3,
		"les poses VARIENT (%d rotations, %d échelles distinctes)"
		% [yaws.size(), scales.size()])
	await _teardown()


func test_the_dressing_never_blocks_the_contract_windows() -> void:
	var lab: HeroShotLab = await _open_lab()
	var camera: Camera3D = lab.vista_camera()
	var dressing: Node3D = lab.get_node_or_null("Dressing") as Node3D
	if camera == null or dressing == null:
		check(false, "caméra ou Dressing absent")
		await _teardown()
		return
	# Les fenêtres protégées §1.1 : héros (39-43 % X), camp (61-66),
	# pylône (75-79), citadelle (48-53). Aucun élément d'habillage ne
	# projette son ORIGINE dans ces bandes en étant plus proche que la
	# cible qu'il masquerait.
	var guarded: Array[Array] = [
		[36.0, 46.0, 5.5],      # héros (jusqu'à la caméra)
		[59.0, 68.0, 88.0],     # camp à ~90 m
		[73.0, 81.0, 130.0],    # pylône à ~140 m
		[46.0, 55.0, 315.0],    # citadelle
	]
	var violations: Array[String] = []
	for child: Node in dressing.get_children():
		var item: Node3D = child as Node3D
		if item == null:
			continue
		var world: Vector3 = item.global_position + Vector3(0, 1.5, 0)
		if camera.is_position_behind(world):
			continue
		var screen: Vector2 = camera.unproject_position(world)
		var viewport: Vector2 = camera.get_viewport().get_visible_rect().size
		var x_pct: float = screen.x / viewport.x * 100.0
		var depth: float = camera.global_position.distance_to(world)
		for window: Array in guarded:
			if x_pct > float(window[0]) and x_pct < float(window[1]) \
					and depth < float(window[2]):
				violations.append("%s (X %.0f %%, %.0f m)"
					% [item.name, x_pct, depth])
	check(violations.is_empty(),
		"aucun habillage devant une focale §1.1 — en faute : %s"
		% ", ".join(violations.slice(0, 6)))
	await _teardown()
