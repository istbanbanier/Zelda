## PT-BRACELET-02 — « du bois qui flotte ».
##
## Défaut mesuré en playtest, puis à la source : plusieurs bâtiments posaient
## UNE seule `Roof_Wooden_2x1_Center` au-dessus du vide. Cette pièce fait
## 2,00 × 1,21 × 1,50 m — c'est une TUILE DE RANGÉE, pas une toiture. Seule,
## à 3,12 m au-dessus d'un appentis de 4 × 6 m, elle n'en couvrait que 12 %
## et ne touchait aucun mur. La forge du village et la grange de la ferme
## étaient dans ce cas.
##
## Ce test ne vérifie pas deux corrections ponctuelles : il vérifie la RÈGLE
## dont elles découlent — une couverture doit couvrir une part significative
## de l'emprise qu'elle abrite. Un troisième bâtiment qui referait la même
## faute serait attrapé sans qu'on y pense.
##
## Il ne juge PAS l'esthétique : un appentis ouvert sur deux côtés reste
## légitime (la forge en est un). Ce qui est interdit, c'est la tuile isolée
## suspendue au-dessus du vide.
extends GateTestCase

## Part minimale de l'emprise des murs que la couverture doit couvrir.
const MIN_COVERAGE: float = 0.6

var _root: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _teardown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.get_parent().remove_child(_root)
		_root.queue_free()
	_root = null


func _open(scene_path: String) -> Node3D:
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		return null
	_root = scene.instantiate() as Node3D
	_tree().root.add_child(_root)
	for i: int in range(6):
		await _tree().physics_frame
	return _root


## Emprise horizontale (x/z) d'un ensemble de pièces, en coordonnées MONDE.
##
## Le monde plutôt que le local : un mur posé à 90° a la même AABB locale
## qu'un mur droit, et la mesurer sans sa rotation donnerait 2,0 m de large
## là où il n'en fait que 0,4 (défaut trouvé en écrivant ce test — la forge
## corrigée s'affichait à 53 % de couverture au lieu de 100 %). Murs et toits
## sont mesurés dans le même repère : seul leur RAPPORT est jugé.
func _footprint(building: Node3D, prefixes: Array[String],
		min_y: float = -INF) -> Rect2:
	var box: Rect2 = Rect2()
	var first: bool = true
	for child: Node in building.get_children():
		var node: Node3D = child as Node3D
		if node == null:
			continue
		var matched: bool = false
		for prefix: String in prefixes:
			if String(node.name).begins_with(prefix):
				matched = true
				break
		if not matched:
			continue
		if _lowest_y(node) < min_y:
			continue
		var here: Rect2 = _world_rect(node)
		if here.size.x <= 0.0 or here.size.y <= 0.0:
			continue
		if first:
			box = here
			first = false
		else:
			box = box.merge(here)
	return box


## Altitude du point le plus BAS d'une pièce, en monde — ce qui distingue une
## toiture posée en hauteur d'un cône tombé dans l'herbe.
func _lowest_y(node: Node3D) -> float:
	var lowest: float = INF
	var meshes: Array[Node] = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for entry: Node in meshes:
		var mesh: MeshInstance3D = entry as MeshInstance3D
		if mesh == null or mesh.mesh == null:
			continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		lowest = minf(lowest, box.position.y)
	return lowest


## Emprise monde d'une pièce, prise sur son AABB visuel RÉEL — mesurer plutôt
## que déduire d'un nom de fichier (« Roof_RoundTiles_4x4 » fait 5,51 m).
func _world_rect(node: Node3D) -> Rect2:
	var rect: Rect2 = Rect2()
	var first: bool = true
	var meshes: Array[Node] = node.find_children("*", "MeshInstance3D", true, false)
	if node is MeshInstance3D:
		meshes.append(node)
	for entry: Node in meshes:
		var mesh: MeshInstance3D = entry as MeshInstance3D
		if mesh == null or mesh.mesh == null:
			continue
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		var here: Rect2 = Rect2(Vector2(box.position.x, box.position.z),
			Vector2(box.size.x, box.size.z))
		if first:
			rect = here
			first = false
		else:
			rect = rect.merge(here)
	return rect


## Hauteur au-dessus de la base d'un bâtiment à partir de laquelle une pièce
## de toiture est considérée EN L'AIR, donc tenue de couvrir quelque chose.
const AIRBORNE_ABOVE: float = 1.5


## Vérifie un bâtiment : sa couverture EN L'AIR doit couvrir MIN_COVERAGE de
## l'emprise de ses murs.
##
## La distinction est celle qui compte, et la première version de ce test l'a
## ratée : la `TourDeGuet` est une ruine dont « le cône de toiture gît dans
## l'herbe » — 6 % de couverture, et c'est JUSTE. Un toit tombé ne prouve
## rien ; un toit suspendu à 3 m au-dessus du vide, si. Seules les pièces
## élevées sont donc jugées.
##
## Sans mur ni toiture élevée, le bâtiment est ignoré — d'où le compteur
## d'inspection, pour que ce test ne se croie pas vert en n'ayant rien vu.
func _check_building(building: Node3D, label: String) -> bool:
	var walls: Rect2 = _footprint(building, ["Wall_"] as Array[String])
	var roofs: Rect2 = _footprint(building, ["Roof_"] as Array[String],
		building.global_position.y + AIRBORNE_ABOVE)
	if walls.get_area() <= 0.01 or roofs.get_area() <= 0.01:
		return false
	var covered: float = roofs.intersection(walls).get_area() / walls.get_area()
	check(covered >= MIN_COVERAGE,
		"%s : la couverture abrite %.0f %% de l'emprise des murs (minimum %.0f %%)"
			% [label, covered * 100.0, MIN_COVERAGE * 100.0])
	return true


func test_village_and_farm_roofs_actually_cover_their_walls() -> void:
	var village: Node3D = await _open("res://scenes/world/valley/ValleyWorld.tscn")
	if village == null:
		check(false, "la vallée ne se charge pas")
		return
	var inspected: int = 0
	# Tous les bâtiments de la vallée, quel que soit le module qui les pose :
	# village de la rive, hameaux, ferme, ruines, territoires.
	for node: Node in _root.find_children("*", "Node3D", true, false):
		var building: Node3D = node as Node3D
		if building == null:
			continue
		if _check_building(building, String(building.name)):
			inspected += 1
	check(inspected > 0,
		"des bâtiments ont réellement été inspectés (%d) — sans quoi ce test "
			% inspected + "se croirait vert à vide")
	_teardown()
