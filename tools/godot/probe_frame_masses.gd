## SONDE DE MASSES DANS LE CADRE — mesurer ce qui DOMINE une image, pas le deviner.
##
## POURQUOI ELLE EXISTE. L'audit du 2026-08-11 dit « des cubes dominent
## plusieurs plans » et le gate de sortie interdit « cube, dalle, mur-proxy ou
## fallback dominant visible ». Les deux phrases parlent de SURFACE À L'ÉCRAN.
## Or le dépôt ne savait mesurer qu'une chose : la boîte englobante MONDE
## (`probe_world_boxes.gd`). Une falaise de 60 m à 400 m pèse moins qu'une
## caisse de 2 m à 6 m, et aucune sonde ne le disait.
##
## Cette sonde monte la vallée réelle, se place sur une caméra de gate NOMMÉE,
## puis pour chaque `GeometryInstance3D` :
##   1. projette les 8 sommets de sa boîte englobante monde ;
##   2. rejette ce qui est entièrement derrière la caméra ou hors cadre ;
##   3. calcule l'emprise écran en pourcentage de l'image ;
##   4. classe par emprise décroissante.
##
## CE QU'ELLE NE DIT PAS. L'emprise d'une boîte englobante SURESTIME toujours
## la surface réellement peinte : un arbre remplit mal son AABB, un mur le
## remplit entièrement. C'est précisément l'asymétrie utile ici — les proxys
## cubiques sont exactement les pièces qui remplissent leur boîte. Elle ne dit
## pas non plus ce qui est OCCULTÉ : une masse peut être classée première et
## se trouver cachée derrière une autre. Le verdict reste à l'image.
##
##   godot --headless --path . --script tools/godot/probe_frame_masses.gd -- \
##     --camera=VistaCamera_Hero01 --size=1920x1080 --limit=25
extends SceneTree

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"


func _init() -> void:
	var camera_name: String = "VistaCamera_Hero01"
	var width: int = 1920
	var height: int = 1080
	var limit: int = 25
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--camera="):
			camera_name = arg.substr(9)
		elif arg.begins_with("--limit="):
			limit = int(arg.substr(8))
		elif arg.begins_with("--size="):
			var parts: PackedStringArray = arg.substr(7).split("x")
			if parts.size() == 2:
				width = int(parts[0])
				height = int(parts[1])

	var packed: PackedScene = load(VALLEY) as PackedScene
	if packed == null:
		printerr("scène introuvable : %s" % VALLEY)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var camera: Camera3D = world.find_child(camera_name, true, false) as Camera3D
	if camera == null:
		printerr("caméra introuvable : %s" % camera_name)
		quit(1)
		return

	# La projection dépend de la viewport ; on la force à la taille demandée
	# pour que les pourcentages correspondent à la capture de gate.
	var viewport: Viewport = root
	viewport.get_window().size = Vector2i(width, height)
	camera.current = true
	await process_frame

	var rows: Array[Dictionary] = []
	_collect(world, camera, Vector2(width, height), rows)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["area_pct"]) > float(b["area_pct"]))

	print("=== masses dans le cadre de %s (%dx%d) ===" % [camera_name, width, height])
	print("%-38s %8s %8s %9s  %s" % ["nœud", "emprise%", "dist_m", "taille_m", "chemin"])
	var shown: int = 0
	for row: Dictionary in rows:
		if shown >= limit:
			break
		print("%-38s %7.2f%% %8.0f %9s  %s" % [
			row["name"], row["area_pct"], row["distance"], row["size"], row["path"]])
		shown += 1
	quit(0)


func _collect(node: Node, camera: Camera3D, screen: Vector2,
		out: Array[Dictionary]) -> void:
	for child: Node in node.get_children():
		_collect(child, camera, screen, out)
	var geometry: GeometryInstance3D = node as GeometryInstance3D
	if geometry == null or not geometry.visible:
		return
	var aabb: AABB = geometry.get_aabb()
	if aabb.size == Vector3.ZERO:
		return
	var transform: Transform3D = geometry.global_transform
	var min_screen: Vector2 = Vector2(INF, INF)
	var max_screen: Vector2 = Vector2(-INF, -INF)
	var any_front: bool = false
	var centre: Vector3 = transform * aabb.get_center()
	for i: int in range(8):
		var corner: Vector3 = transform * aabb.get_endpoint(i)
		if camera.is_position_behind(corner):
			continue
		any_front = true
		var point: Vector2 = camera.unproject_position(corner)
		min_screen = min_screen.min(point)
		max_screen = max_screen.max(point)
	if not any_front:
		return
	# Recadrage sur l'image : une masse à moitié hors cadre ne compte que par
	# la part visible.
	var clipped_min: Vector2 = min_screen.max(Vector2.ZERO)
	var clipped_max: Vector2 = max_screen.min(screen)
	if clipped_max.x <= clipped_min.x or clipped_max.y <= clipped_min.y:
		return
	var area: float = (clipped_max.x - clipped_min.x) * (clipped_max.y - clipped_min.y)
	var pct: float = 100.0 * area / (screen.x * screen.y)
	if pct < 0.05:
		return
	var world_size: Vector3 = transform.basis * aabb.size
	out.append({
		"name": geometry.name,
		"area_pct": pct,
		"distance": camera.global_position.distance_to(centre),
		"size": "%.0fx%.0fx%.0f" % [absf(world_size.x), absf(world_size.y),
			absf(world_size.z)],
		"path": String(geometry.get_path()).replace("/root/ValleyWorld/", ""),
	})
