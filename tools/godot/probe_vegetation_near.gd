## Sonde : que pose la VÉGÉTATION GELÉE (V2.2) autour d'un point ?
##
## Née d'une question qu'aucune capture ne tranche : le lead a écrit
## « l'arbre noir entouré de fleurs jaunes ». Ces fleurs viennent-elles du
## lieu (que je peux retirer) ou du semis de la prairie (gelé, intouchable) ?
## Répondre à l'œil sur une image, c'est deviner. On compte les instances.
##
## Usage :
##   godot --headless --path . --script tools/godot/probe_vegetation_near.gd \
##     -- --center=-92,132 --radius=8
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"


func _initialize() -> void:
	var center: Vector2 = Vector2.ZERO
	var radius: float = 8.0
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--center="):
			var parts: PackedStringArray = argument.substr(9).split(",")
			center = Vector2(float(parts[0]), float(parts[1]))
		elif argument.begins_with("--radius="):
			radius = float(argument.substr(9))
	var world: Node = (load(WORLD) as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	print("centre=(%.1f, %.1f) rayon=%.1f m" % [center.x, center.y, radius])
	var counts: Dictionary = {}
	_walk(world, center, radius, counts)
	var names: Array = counts.keys()
	names.sort()
	var total: int = 0
	for key: Variant in names:
		var n: int = int(counts[key])
		total += n
		print("  %-44s %d" % [String(key), n])
	var sans_plan: int = int(counts.get(&"__SANS_PLAN__", 0))
	if sans_plan > 0:
		printerr("[vegetation] BLOQUÉ : %d cellule(s) sans méta `instance_origins` — "
			% sans_plan + "le plan de plantation est absent et un compte serait faux")
		quit(3)
		return
	print("TOTAL instances de végétation dans le rayon : %d" % total)
	quit(0)


## LA SONDE LISAIT LE MAUVAIS CÔTÉ, et rendait des comptes faux avec aplomb.
##
## Signalé par l'agent grotte le 2026-08-14 : ses 21 instances « proches »
## remontaient toutes au même point, (−112,0 ; 16,0). Vérifié ici par un
## balayage de rayon, qui est le test qui tranche :
##
##   rayon  3 m -> 0 instance
##   rayon  6 m -> 0 instance
##   rayon 12 m -> 180 instances
##
## Une marche d'escalier, pas une croissance. C'est la signature du défaut :
## la cellule entière bascule d'un coup quand l'origine de son nœud passe
## sous le rayon (elle est à 10,2 m du centre sondé). Un compte « dans 8 m »
## ne mesurait donc que la distance à un point unique.
##
## La cause était DÉJÀ écrite dans `world_v2_vegetation_builder.gd` §
## matérialisation : en mode headless `--script`, le renderer DUMMY jette
## les données d'instance de MultiMesh — `_multimesh_instance_set_transform`
## est un no-op et le `get` rend l'IDENTITÉ. Le bâtisseur écrit pour cette
## raison son PLAN DE PLANTATION en méta `instance_origins`, depuis les
## mêmes valeurs et dans la même boucle que l'écriture moteur.
##
## On lit donc la méta. Et s'il n'y en a pas, on sort en BLOQUÉ (3) plutôt
## que de compter des identités : une sonde qui ne peut pas mesurer doit le
## DIRE, jamais rendre 0 (`tools/CLAUDE.md`).
func _walk(node: Node, center: Vector2, radius: float, counts: Dictionary) -> void:
	var multi: MultiMeshInstance3D = node as MultiMeshInstance3D
	if multi != null and multi.multimesh != null:
		if not multi.has_meta(&"instance_origins"):
			counts[&"__SANS_PLAN__"] = int(counts.get(&"__SANS_PLAN__", 0)) + 1
		else:
			var origines: PackedVector3Array = multi.get_meta(&"instance_origins")
			var vers_monde: Transform3D = multi.global_transform
			for point_local: Vector3 in origines:
				var point: Vector3 = vers_monde * point_local
				if Vector2(point.x, point.z).distance_to(center) <= radius:
					var key: String = multi.name
					counts[key] = int(counts.get(key, 0)) + 1
	for child: Node in node.get_children():
		_walk(child, center, radius, counts)
