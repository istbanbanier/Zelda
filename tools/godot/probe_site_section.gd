## Coupe d'un site : sol, eau et sol PHYSIQUE le long d'une grille —
## diagnostic seul (V2.3-A.R).
##
## Un lieu s'adapte au terrain GELÉ : le concevoir sans mesurer produit
## exactement les défauts rejetés (quai sur l'herbe, culées hors berge,
## bouche de grotte dans un talus). Cette sonde donne les nombres.
##
## Usage :
##   godot --headless --path . --script tools/godot/probe_site_section.gd -- \
##       --center=-10,22 --span=32 --step=2 [--axis=x|z]
extends SceneTree

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"

var _center: Vector2 = Vector2.ZERO
var _span: float = 32.0
var _step: float = 2.0


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--center="):
			var parts: PackedStringArray = argument.trim_prefix("--center=").split(",")
			_center = Vector2(parts[0].to_float(), parts[1].to_float())
		elif argument.begins_with("--span="):
			_span = argument.trim_prefix("--span=").to_float()
		elif argument.begins_with("--step="):
			_step = argument.trim_prefix("--step=").to_float()

	var world: Node3D = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i: int in range(12):
		await process_frame
	var heightmap: RefCounted = world.get("_heightmap") as RefCounted

	print("[coupe] centre (%.1f, %.1f), emprise %.0f m, pas %.1f m"
		% [_center.x, _center.y, _span, _step])
	print("[coupe] '~' = en eau ; hauteurs de la fonction de terrain GELÉE")
	var half: float = _span * 0.5
	var header: String = "     z\\x "
	var x: float = _center.x - half
	while x <= _center.x + half:
		header += "%7.0f" % x
		x += _step
	print(header)
	var z: float = _center.y - half
	while z <= _center.y + half:
		var line: String = "%8.0f " % z
		x = _center.x - half
		while x <= _center.x + half:
			var ground: float = float(heightmap.call("height_at", x, z))
			var wet: bool = bool(heightmap.call("is_in_water", x, z))
			line += "%6.1f%s" % [ground, "~" if wet else " "]
			x += _step
		print(line)
		z += _step
	quit(0)
