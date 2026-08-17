## SONDE DE MATÉRIAUX D'UN ASSET IMPORTÉ — ce que Godot porte VRAIMENT.
##
## Née d'un doute qu'aucune capture ne tranche : le pylône produit par
## Blender rendait ENTIÈREMENT BLANC alors que son `.glb` déclarait cinq
## matériaux nommés et des albédos allant de 0,14 à 0,62. Blanc ou beige
## clair, l'œil ne sait pas dire — et « le matériau est-il appliqué ? »
## n'est pas une question d'opinion.
##
## La sonde instancie la scène importée et imprime, pour chaque
## `MeshInstance3D` : le nom, le nombre de surfaces, et pour chaque
## surface le matériau réellement résolu — surcharge de nœud, surcharge de
## surface, ou matériau du maillage — avec sa classe et son albédo.
##
## Usage :
##   godot --headless --path . --script tools/godot/probe_asset_materials.gd -- \
##       --scene=res://assets/architecture/pylon/SM_Pylon_Resonance.glb
extends SceneTree


func _initialize() -> void:
	var chemin: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--scene="):
			chemin = argument.substr(8)
	if chemin.is_empty():
		printerr("[materiaux] BLOQUÉ : --scene=<res://…> requis")
		quit(3)
		return

	var packed: PackedScene = load(chemin) as PackedScene
	if packed == null:
		printerr("[materiaux] BLOQUÉ : scène introuvable — %s" % chemin)
		quit(3)
		return
	var racine: Node3D = packed.instantiate() as Node3D
	root.add_child(racine)
	await process_frame

	print("[materiaux] %s" % chemin)
	print("%-30s %3s  %-22s %-18s %s"
		% ["maillage", "srf", "matériau", "classe", "albédo"])
	var sans_materiau: int = 0
	for noeud: Node in racine.find_children("*", "MeshInstance3D", true, false):
		var visuel: MeshInstance3D = noeud as MeshInstance3D
		if visuel.mesh == null:
			continue
		var surfaces: int = visuel.mesh.get_surface_count()
		for surface: int in range(surfaces):
			# L'ordre de résolution de Godot : surcharge de nœud, puis
			# surcharge de surface, puis matériau porté par le maillage.
			var source: String = "maillage"
			var materiau: Material = visuel.material_override
			if materiau != null:
				source = "override"
			else:
				materiau = visuel.get_surface_override_material(surface)
				if materiau != null:
					source = "surface"
				else:
					materiau = visuel.mesh.surface_get_material(surface)
			if materiau == null:
				sans_materiau += 1
				print("%-30s %3d  %-22s %-18s %s"
					% [visuel.name, surface, "(AUCUN)", "—", "défaut blanc"])
				continue
			var standard: StandardMaterial3D = materiau as StandardMaterial3D
			var albedo: String = "—"
			if standard != null:
				albedo = "(%.2f, %.2f, %.2f) rug %.2f" % [
					standard.albedo_color.r, standard.albedo_color.g,
					standard.albedo_color.b, standard.roughness]
			print("%-30s %3d  %-22s %-18s %s"
				% [visuel.name, surface, materiau.resource_name if
					materiau.resource_name != "" else "(sans nom)",
					materiau.get_class() + " · " + source, albedo])
	print("")
	if sans_materiau > 0:
		printerr("[materiaux] %d surface(s) SANS matériau — elles rendent en blanc par défaut"
			% sans_materiau)
		quit(1)
		return
	print("[materiaux] toutes les surfaces portent un matériau.")
	quit(0)
