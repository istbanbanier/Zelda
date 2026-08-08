## Sonde de valeurs de la vue North Star (§1.5) — outil de diagnostic.
##
## Usage :
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy \
##       --script tools/godot/probe_north_star_values.gd
##
## Monte `HeroShotLab`, se place sur `VistaCamera_Hero01`, puis PROJETTE la
## boîte englobante monde de chaque surface de sol vers l'écran. Cela répond à
## une question que l'oeil ne peut pas trancher sur une capture : quel NOEUD
## occupe telle bande de pixels.
##
## N'écrit aucun fichier et ne juge rien. Il imprime des coordonnées.
##
## LIMITE CONNUE, à lire avant de se fier à une sortie : l'axe Y des emprises
## écran est FAUX. Le rééchelonnage vers 1280×720 suppose que la viewport a le
## même rapport d'aspect, ce qui n'est pas le cas dans une exécution `--script`.
## Les emprises X sont utilisables, les Y ne le sont pas — sur ISS-037 elles ont
## désigné le mauvais nœud. Ce qui reste utile ici : l'énumération par CLASSE
## (`GeometryInstance3D` et non `MeshInstance3D`, sinon la végétation en
## MultiMesh est invisible). Pour identifier un nœud à coup sûr, la méthode qui
## a réellement tranché est ailleurs : repeindre le nœud suspect d'une couleur
## impossible, recapturer, mesurer le pixel.
extends SceneTree

const LAB: String = "res://scenes/lookdev/HeroShotLab.tscn"
## Les noeuds dont on veut savoir où ils atterrissent à l'écran.
const WATCHED: Array[String] = ["PathCrest", "ValleyFloor", "SlopeGround"]
const WIDTH: int = 1280
const HEIGHT: int = 720


func _initialize() -> void:
	var scene: Node3D = (load(LAB) as PackedScene).instantiate() as Node3D
	root.add_child(scene)
	if scene.has_method("capture_north_star"):
		scene.call("capture_north_star")
	for i: int in range(8):
		await process_frame

	var camera: Camera3D = _find_camera(scene)
	if camera == null:
		printerr("[sonde] aucune Camera3D courante")
		quit(1)
		return
	print("[sonde] camera : %s  fov=%.1f  keep_aspect=%d"
		% [camera.name, camera.fov, camera.keep_aspect])
	print("[sonde] ecran de reference : %dx%d" % [WIDTH, HEIGHT])

	# Emprise de la bande litigieuse, relevée sur la capture (ISS-037).
	var band: Rect2 = Rect2(680, 400, 580, 300)
	print("[sonde] bande litigieuse : x %.0f..%.0f  y %.0f..%.0f"
		% [band.position.x, band.end.x, band.position.y, band.end.y])
	# TOUT ce qui dessine, pas seulement MeshInstance3D : la v2 de cette sonde
	# ne trouvait rien parce que la végétation est en MultiMeshInstance3D.
	var drawn: Array[GeometryInstance3D] = []
	_collect(scene, drawn)
	print("[sonde] %d GeometryInstance3D visibles" % drawn.size())
	var found: Array[Array] = []
	for item: GeometryInstance3D in drawn:
		var box: Rect2 = _screen_box(item, camera)
		if box.size == Vector2.ZERO or not box.intersects(band):
			continue
		found.append([box.get_area(), item.name, item.get_class(), box])
	found.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var centre: Vector2 = Vector2(941, 606)
	print("[sonde] %d candidats ; « <<< » = contient le centroide %s"
		% [found.size(), centre])
	for row: Array in found:
		var box: Rect2 = row[3]
		print("  %-26s %-22s x %.0f..%.0f y %.0f..%.0f aire=%-9.0f%s"
			% [row[1], row[2], box.position.x, box.end.x, box.position.y,
			box.end.y, row[0], "  <<<" if box.has_point(centre) else ""])
	quit(0)


func _collect(node: Node, out: Array[GeometryInstance3D]) -> void:
	var item: GeometryInstance3D = node as GeometryInstance3D
	if item != null and item.visible:
		out.append(item)
	for child: Node in node.get_children():
		_collect(child, out)


## Emprise écran de la boîte monde. C'est une SUR-approximation (boîte alignée
## aux axes de l'écran) : elle sert à écarter des candidats, pas à prouver
## qu'un pixel appartient à un mesh.
func _screen_box(mesh: GeometryInstance3D, camera: Camera3D) -> Rect2:
	var aabb: AABB = mesh.get_aabb()
	var xform: Transform3D = mesh.global_transform
	var mn: Vector2 = Vector2(INF, INF)
	var mx: Vector2 = Vector2(-INF, -INF)
	var vp: Vector2 = camera.get_viewport().get_visible_rect().size
	var seen: int = 0
	for i: int in range(8):
		var corner: Vector3 = xform * aabb.get_endpoint(i)
		# Un SEUL coin derrière la caméra ne disqualifie pas le mesh : les
		# grandes surfaces de premier plan en ont toujours. Bug de la v1 de
		# cette sonde, qui les écartait toutes et ne trouvait donc rien.
		if camera.is_position_behind(corner):
			continue
		seen += 1
		var p: Vector2 = camera.unproject_position(corner)
		var f: Vector2 = Vector2(p.x / maxf(vp.x, 1.0) * float(WIDTH),
			p.y / maxf(vp.y, 1.0) * float(HEIGHT))
		mn = mn.min(f)
		mx = mx.max(f)
	if seen == 0:
		return Rect2()
	return Rect2(mn, mx - mn)


## Projette les huit coins de la boîte monde et rend l'emprise écran.
func _report(label: String, mesh: MeshInstance3D, camera: Camera3D) -> void:
	var aabb: AABB = mesh.get_aabb()
	var basis_xform: Transform3D = mesh.global_transform
	var min_x: float = INF
	var max_x: float = -INF
	var min_y: float = INF
	var max_y: float = -INF
	var any_front: bool = false
	for i: int in range(8):
		var corner: Vector3 = basis_xform * aabb.get_endpoint(i)
		if camera.is_position_behind(corner):
			continue
		any_front = true
		# `unproject_position` rend des pixels dans la taille de viewport
		# courante ; on ramene en fraction puis dans l'ecran de reference.
		var p: Vector2 = camera.unproject_position(corner)
		var vp: Vector2 = camera.get_viewport().get_visible_rect().size
		var fx: float = p.x / maxf(vp.x, 1.0) * float(WIDTH)
		var fy: float = p.y / maxf(vp.y, 1.0) * float(HEIGHT)
		min_x = minf(min_x, fx)
		max_x = maxf(max_x, fx)
		min_y = minf(min_y, fy)
		max_y = maxf(max_y, fy)
	if not any_front:
		print("  %-14s entierement derriere la camera" % label)
		return
	print("  %-14s ecran x %.0f..%.0f  y %.0f..%.0f"
		% [label, min_x, max_x, min_y, max_y])


func _find_camera(node: Node) -> Camera3D:
	var camera: Camera3D = node as Camera3D
	if camera != null and camera.current:
		return camera
	for child: Node in node.get_children():
		var found: Camera3D = _find_camera(child)
		if found != null:
			return found
	return null


func _find_by_name(node: Node, wanted: String) -> Node:
	if node.name == wanted:
		return node
	for child: Node in node.get_children():
		var found: Node = _find_by_name(child, wanted)
		if found != null:
			return found
	return null
