extends SceneTree
## Sonde : où se trouvent RÉELLEMENT, en coordonnées monde, les nœuds d'un lieu ?
##
## POURQUOI. Viser une caméra de gros plan « au jugé » a déjà coûté une passe :
## en R2B.1, cinq caméras de preuve posées de mémoire visaient deux fois sous le
## terrain et trois fois le pied au lieu du fût. Une caméra se calcule sur une
## emprise mesurée, pas sur une lecture du script de placement — la chaîne de
## transformations (ancre du layout + yaw de la maison + position locale de la
## pièce) est trop longue pour être refaite de tête sans se tromper.
##
## Usage :
##   godot --headless --path . --script tools/godot/sonde_aabb_lieu.gd -- \
##       --scene=res://scenes/world_v2/poi/AbandonedFarmPlace.tscn --motif=Debris

func _initialize() -> void:
	var scene_path: String = ""
	var motif: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			scene_path = arg.substr(8)
		elif arg.begins_with("--motif="):
			motif = arg.substr(8)
	if scene_path.is_empty():
		push_error("BLOQUÉ : --scene= requis")
		quit(3)
		return
	var paquet: PackedScene = load(scene_path) as PackedScene
	if paquet == null:
		push_error("BLOQUÉ : scène introuvable %s" % scene_path)
		quit(3)
		return
	var racine: Node = paquet.instantiate()
	root.add_child(racine)
	# Deux trames : certains lieux se construisent dans `_ready`, d'autres
	# attendent la première trame physique. Sonder trop tôt rend une scène vide
	# et un AABB nul qui ressemble à une mesure.
	await process_frame
	await process_frame
	var trouves: int = 0
	for node: Node in racine.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh == null:
			continue
		var chemin: String = String(racine.get_path_to(mi))
		if not motif.is_empty() and not chemin.contains(motif):
			continue
		var aabb: AABB = mi.global_transform * mi.mesh.get_aabb()
		trouves += 1
		print("%s | centre=(%.3f, %.3f, %.3f) | taille=(%.3f, %.3f, %.3f) | min_y=%.3f" % [
			chemin, aabb.get_center().x, aabb.get_center().y, aabb.get_center().z,
			aabb.size.x, aabb.size.y, aabb.size.z, aabb.position.y])
	print("SONDE : %d maillage(s) retenu(s)" % trouves)
	quit(0 if trouves > 0 else 1)
