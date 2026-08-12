## OUTIL JETABLE DE DIAGNOSTIC — repeint des nœuds désignés en couleurs
## impossibles puis capture depuis une caméra nommée. C'est la méthode que
## `tools/CLAUDE.md` impose quand une emprise écran ne suffit pas à désigner
## un nœud : « le repeindre d'une couleur impossible, recapturer, mesurer le
## pixel ». Usage :
##
##   godot --headless --path . --script tools/godot/debug_paint_suspects.gd -- \
##       --camera=GateCamera_NorthRoad --out=/tmp/suspects.png \
##       --paint=Terrain/BorderNorth/BorderNorthMesh:magenta \
##       --paint=Terrain/WallSkirts/Skirt0_4:yellow
##
## Couleurs admises : magenta, yellow, green, cyan, red, blue, orange.
## Aucune preuve ne sort de cet outil : il sert au diagnostic, jamais au gate.
extends SceneTree

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const PALETTE: Dictionary = {
	"magenta": Color(1.0, 0.0, 1.0),
	"yellow": Color(1.0, 1.0, 0.0),
	"green": Color(0.0, 1.0, 0.0),
	"cyan": Color(0.0, 1.0, 1.0),
	"red": Color(1.0, 0.0, 0.0),
	"blue": Color(0.0, 0.2, 1.0),
	"orange": Color(1.0, 0.5, 0.0),
}


func _init() -> void:
	var camera_name: String = "GateCamera_NorthRoad"
	var out_path: String = "/tmp/suspects.png"
	var paints: Array[Array] = []
	var picks: Array[Vector2] = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--camera="):
			camera_name = arg.trim_prefix("--camera=")
		elif arg.begins_with("--out="):
			out_path = arg.trim_prefix("--out=")
		elif arg.begins_with("--pick="):
			var xy: PackedStringArray = arg.trim_prefix("--pick=").split(",")
			if xy.size() == 2:
				picks.append(Vector2(xy[0].to_float(), xy[1].to_float()))
		elif arg.begins_with("--paint="):
			var spec: PackedStringArray = arg.trim_prefix("--paint=").rsplit(":", true, 1)
			if spec.size() == 2 and PALETTE.has(spec[1]):
				paints.append([spec[0], PALETTE[spec[1]] as Color])
	await process_frame
	var world: Node3D = (load(VALLEY) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	await process_frame
	await process_frame
	var camera: Camera3D = world.find_child(camera_name, true, false) as Camera3D
	if camera == null:
		push_error("caméra introuvable : %s" % camera_name)
		quit(1)
		return
	camera.make_current()
	for paint: Array in paints:
		var node: Node = world.get_node_or_null(NodePath(paint[0] as String))
		if node == null:
			node = world.find_child((paint[0] as String).get_file(), true, false)
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh == null:
			print("[paint] INTROUVABLE : %s" % paint[0])
			continue
		var flat: StandardMaterial3D = StandardMaterial3D.new()
		flat.albedo_color = paint[1] as Color
		flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = flat
		print("[paint] %s -> %s" % [paint[0], (paint[1] as Color).to_html(false)])
	root.get_window().size = Vector2i(1920, 1080)
	for i: int in range(30):
		await process_frame
	# --pick=px,py : énumère les géométries dont l'AABB MONDE coupe le rayon
	# de ce pixel, triées par distance d'entrée. Ne dépend d'aucune collision —
	# c'est ce qui permet de désigner un DÉCOR (l'écueil exact du rayon
	# physique). L'AABB déborde la forme réelle : le premier nom est un
	# candidat, pas un verdict — le verdict reste la repeinture.
	for pick: Vector2 in picks:
		var origin: Vector3 = camera.project_ray_origin(pick)
		var direction: Vector3 = camera.project_ray_normal(pick)
		var hits: Array[Array] = []
		var stack: Array[Node] = [world]
		while not stack.is_empty():
			var current: Node = stack.pop_back()
			stack.append_array(current.get_children())
			var geometry: GeometryInstance3D = current as GeometryInstance3D
			if geometry == null or not geometry.visible:
				continue
			var aabb: AABB = geometry.global_transform * geometry.get_aabb()
			var entry: Variant = aabb.intersects_ray(origin, direction)
			if entry != null:
				hits.append([origin.distance_to(entry as Vector3),
					String(world.get_path_to(geometry))])
		hits.sort()
		print("[pick] pixel (%d, %d) — %d AABB coupées :" % [int(pick.x),
			int(pick.y), hits.size()])
		for i: int in range(mini(10, hits.size())):
			print("    %7.1f m  %s" % [hits[i][0] as float, hits[i][1] as String])
	var image: Image = root.get_viewport().get_texture().get_image()
	image.save_png(out_path)
	print("[paint] capture : %s" % out_path)
	quit(0)
