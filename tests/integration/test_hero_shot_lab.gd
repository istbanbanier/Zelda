## Cycle 3, tranche 1 — `HeroShotLab` (bible §29 passe V2, P2 §11.1) : la
## micro-scène 80×80 m que la revue du Gate H a nommée comme JAMAIS
## construite. Fail-first : écrit avant l'implémentation.
##
## Le contrat de composition de la bible §1.1 devient des ASSERTIONS : les
## ancres (héros, camp, pylône, citadelle, rivière) sont projetées à
## travers la caméra North Star (16:9) et doivent tomber dans leurs
## fenêtres d'écran. Les corrections adversariales #3 (rivière en S) et
## #4 (camp dans le cadre, pylône 75-79 % X) sont des contrats ici — pas
## des intentions. La projection est de la GÉOMÉTRIE : aucun rendu requis,
## le score visuel réel attend la machine utilisateur.
extends GateTestCase

const LAB: String = "res://scenes/lookdev/HeroShotLab.tscn"

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


func _open() -> HeroShotLab:
	_root = Node3D.new()
	_tree().root.add_child(_root)
	var lab: HeroShotLab = (load(LAB) as PackedScene).instantiate() \
		as HeroShotLab
	_root.add_child(lab)
	await _settle(6)
	return lab


## Projection d'un point monde en pourcentages d'écran 16:9, origine en
## haut à gauche (bible §1.1) — pure géométrie, indépendante du viewport.
func _screen_pct(camera: Camera3D, world: Vector3) -> Vector2:
	var local: Vector3 = camera.global_transform.affine_inverse() * world
	if local.z >= -0.01:
		return Vector2(-9.0, -9.0)   # derrière la caméra : hors contrat
	var tan_half_v: float = tan(deg_to_rad(camera.fov) * 0.5)
	var tan_half_h: float = tan_half_v * (16.0 / 9.0)
	var x_pct: float = 0.5 + (local.x / -local.z) / tan_half_h * 0.5
	var y_pct: float = 0.5 - (local.y / -local.z) / tan_half_v * 0.5
	return Vector2(x_pct * 100.0, y_pct * 100.0)


func _in_window(pct: Vector2, x_min: float, x_max: float, y_min: float,
		y_max: float, label: String) -> void:
	check(pct.x >= x_min and pct.x <= x_max,
		"%s : X %.1f %% dans [%.0f-%.0f]" % [label, pct.x, x_min, x_max])
	check(pct.y >= y_min and pct.y <= y_max,
		"%s : Y %.1f %% dans [%.0f-%.0f]" % [label, pct.y, y_min, y_max])


func test_the_lab_exists_with_the_mandated_elements() -> void:
	var lab: HeroShotLab = await _open()
	check(lab != null, "HeroShotLab.tscn existe et s'instancie")
	if lab == null:
		await _teardown()
		return
	# §11.1 : la liste des éléments essentiels, comme PRÉSENCE réelle.
	for wanted: StringName in [&"hero_feet", &"hero_head", &"camp_center",
			&"pylon_base", &"pylon_top", &"citadel_center", &"citadel_spire"]:
		check(lab.anchor(wanted) != null, "ancre %s présente" % wanted)
	check(lab.vista_camera() != null, "VistaCamera_Hero01 présente")
	check(lab.get_node_or_null("Storm") != null,
		"le nuage d'orage local est là (StormCell)")
	check(lab.grass_cell_count() >= 4,
		"l'herbe du premier plan existe en cellules (%d)"
		% lab.grass_cell_count())
	check(lab.river_points().size() >= 6,
		"la rivière expose son tracé (%d points)" % lab.river_points().size())
	await _teardown()


func test_the_camera_honours_the_north_star_contract() -> void:
	## Bible §3.1 : 4,0-4,5 m derrière le héros, objectif 1,55-1,75 m
	## au-dessus des pieds, FOV HORIZONTAL 65-72° — soit 39,4-44,5°
	## vertical en KEEP_HEIGHT : entrer 68 en vertical est LE piège nommé.
	var lab: HeroShotLab = await _open()
	var camera: Camera3D = lab.vista_camera()
	var feet: Node3D = lab.anchor(&"hero_feet")
	check(camera != null and feet != null, "caméra et héros présents")
	if camera == null or feet == null:
		await _teardown()
		return
	check(camera.fov >= 39.4 and camera.fov <= 44.5,
		"FOV vertical %.1f° dans [39,4-44,5] (65-72° horizontal)" % camera.fov)
	var flat: Vector3 = camera.global_position - feet.global_position
	var height: float = flat.y
	flat.y = 0.0
	check(flat.length() >= 3.6 and flat.length() <= 4.7,
		"caméra à %.2f m derrière le héros (cible 4,0-4,5)" % flat.length())
	check(height >= 1.45 and height <= 1.85,
		"objectif à %.2f m au-dessus des pieds (cible 1,55-1,75)" % height)
	await _teardown()


func test_the_anchors_hit_their_frame_windows() -> void:
	## Bible §1.1 — les fenêtres deviennent des assertions. Corrections
	## adversariales #4 incluses : camp 61-66 % X, pylône 75-79 % X.
	var lab: HeroShotLab = await _open()
	var camera: Camera3D = lab.vista_camera()
	if camera == null:
		check(false, "pas de caméra — contrat impossible")
		await _teardown()
		return
	_in_window(_screen_pct(camera, lab.anchor(&"hero_feet").global_position),
		37.0, 45.0, 87.0, 94.0, "pieds du héros")
	_in_window(_screen_pct(camera, lab.anchor(&"hero_head").global_position),
		37.0, 45.0, 42.0, 50.0, "tête du héros")
	_in_window(_screen_pct(camera, lab.anchor(&"camp_center").global_position),
		61.0, 66.0, 56.0, 66.0, "camp")
	_in_window(_screen_pct(camera, lab.anchor(&"pylon_base").global_position),
		75.0, 79.0, 53.0, 61.0, "base du pylône")
	_in_window(_screen_pct(camera, lab.anchor(&"pylon_top").global_position),
		73.0, 81.0, 12.0, 22.0, "sommet du pylône")
	_in_window(_screen_pct(camera,
		lab.anchor(&"citadel_center").global_position),
		48.0, 53.0, 37.0, 49.0, "citadelle")
	_in_window(_screen_pct(camera,
		lab.anchor(&"citadel_spire").global_position),
		46.0, 55.0, 5.0, 15.0, "spire")
	await _teardown()


func test_the_river_draws_an_s_toward_the_center() -> void:
	## Correction adversariale #3 (bible §1.1) : « ruban en S du
	## bas-gauche/milieu vers le centre ». Le S est GÉOMÉTRIQUE : le tracé
	## projeté change au moins deux fois de direction horizontale, part du
	## bas et s'éloigne vers le centre de l'image.
	var lab: HeroShotLab = await _open()
	var camera: Camera3D = lab.vista_camera()
	var points: Array[Vector3] = lab.river_points()
	check(points.size() >= 6, "assez de points pour dessiner un S")
	if camera == null or points.size() < 6:
		await _teardown()
		return
	var screens: Array[Vector2] = []
	for point: Vector3 in points:
		var pct: Vector2 = _screen_pct(camera, point)
		if pct.x > -8.0:
			screens.append(pct)
	check(screens.size() >= 6, "le tracé est devant la caméra")
	var first: Vector2 = screens[0]
	var last: Vector2 = screens[screens.size() - 1]
	check(first.y > 62.0 and first.x < 52.0,
		"départ bas-gauche/milieu (%.0f %%, %.0f %%)" % [first.x, first.y])
	# Sur une pente continue vue presque à l'horizontale, le sol converge
	# vers SA ligne de fuite (~63 %) : l'éloignement se lit par une
	# remontée FAIBLE mais monotone vers elle, la convergence en X et
	# l'amincissement — pas par une chute de 12 points (leçon v1).
	check(last.y < first.y - 1.5,
		"le ruban s'éloigne vers sa ligne de fuite (Y %.1f → %.1f)"
		% [first.y, last.y])
	check(last.x >= 40.0 and last.x <= 58.0,
		"…et finit vers le centre (X %.0f %%)" % last.x)
	var direction_changes: int = 0
	var previous_dx: float = 0.0
	for i: int in range(1, screens.size()):
		var dx: float = screens[i].x - screens[i - 1].x
		if absf(dx) < 0.5:
			continue
		if previous_dx != 0.0 and signf(dx) != signf(previous_dx):
			direction_changes += 1
		previous_dx = dx
	check(direction_changes >= 2,
		"le tracé fait un S : %d changements de direction (≥ 2)"
		% direction_changes)
	await _teardown()


func test_three_depth_planes_are_real_distances() -> void:
	## Bible §1.3 : premier plan 0-35 m, plan moyen 35-200 m (camp
	## 70-110 m, pylône 140-190 m), arrière-plan 200 m et plus (citadelle
	## 300-420 m). Des proxies au loin, pas des maquettes collées au nez.
	var lab: HeroShotLab = await _open()
	var camera: Camera3D = lab.vista_camera()
	if camera == null:
		check(false, "pas de caméra")
		await _teardown()
		return
	var eye: Vector3 = camera.global_position
	var hero: float = eye.distance_to(lab.anchor(&"hero_feet").global_position)
	var camp: float = eye.distance_to(lab.anchor(&"camp_center").global_position)
	var pylon: float = eye.distance_to(lab.anchor(&"pylon_base").global_position)
	var citadel: float = eye.distance_to(
		lab.anchor(&"citadel_center").global_position)
	check(hero < 8.0, "héros au premier plan (%.1f m)" % hero)
	check(camp >= 60.0 and camp <= 120.0, "camp au plan moyen (%.0f m)" % camp)
	# 90-200 m et non les « 140-190 m » de la bible : un pylône d'asset
	# 28-36 m (§3) ne PEUT pas remplir sa fenêtre d'écran (14-20 % →
	# 55-59 %) à 140 m et plus — il faudrait ~52 m. Les fenêtres de cadre
	# priment (intention §1.1), les mètres sont « indicatifs ».
	check(pylon >= 90.0 and pylon <= 200.0,
		"pylône au plan moyen lointain (%.0f m)" % pylon)
	check(citadel >= 250.0 and citadel <= 450.0,
		"citadelle monumentale au fond (%.0f m)" % citadel)
	check(camp < pylon and pylon < citadel,
		"l'étagement héros → camp → pylône → citadelle est réel")
	await _teardown()
