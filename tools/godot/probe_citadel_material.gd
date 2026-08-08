## Sonde du matériau de la citadelle (test H-6) — diagnostic, sans verdict.
##
## Le test `test_h6_la_citadelle_parle_le_langage_de_resonance` exige
## `r − b >= 0,04` sur la pierre du donjon central et mesure `0.000`. Or
## `COL_STONE` vaut (0.285, 0.245, 0.205), soit r − b = 0,080 — la pierre EST
## chaude. Le `0.000` affiché est aussi ce que le test imprime quand le cast
## vers `StandardMaterial3D` rend null.
##
## Cette sonde imprime la CLASSE réelle du matériau et sa couleur, quelle que
## soit cette classe. Elle ne conclut rien : elle mesure.
extends SceneTree

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"


func _initialize() -> void:
	var valley: Node3D = (load(VALLEY) as PackedScene).instantiate() as Node3D
	root.add_child(valley)
	for i: int in range(10):
		await process_frame

	var citadel: Node3D = valley.get_node_or_null("Terrain/CitadelProxy") as Node3D
	if citadel == null:
		printerr("[citadelle] CitadelProxy absent")
		quit(1)
		return
	print("[citadelle] COL_STONE attendu : (0.285, 0.245, 0.205) -> r-b = 0.080")

	var keep: Node = citadel.get_node_or_null("Keep/KeepMesh")
	if keep == null:
		print("[citadelle] Keep/KeepMesh ABSENT — enfants de Keep :")
		var parent: Node = citadel.get_node_or_null("Keep")
		if parent != null:
			for child: Node in parent.get_children():
				print("    %s (%s)" % [child.name, child.get_class()])
		quit(0)
		return

	var mesh: MeshInstance3D = keep as MeshInstance3D
	var override: Material = mesh.material_override
	if override == null:
		print("[citadelle] material_override est NULL")
		print("            materiau de surface 0 : %s"
			% (mesh.get_active_material(0).get_class()
			if mesh.get_active_material(0) != null else "aucun"))
		quit(0)
		return

	print("[citadelle] material_override : %s" % override.get_class())
	var standard: StandardMaterial3D = override as StandardMaterial3D
	if standard != null:
		var c: Color = standard.albedo_color
		print("            albedo (%.3f, %.3f, %.3f) -> r-b = %.3f"
			% [c.r, c.g, c.b, c.r - c.b])
		print("            -> le cast du test REUSSIT ; la piste du materiau "
			+ "est fausse")
	else:
		print("            -> le cast vers StandardMaterial3D ECHOUE : c'est "
			+ "pourquoi le test lit 0.000")
		var shader_material: ShaderMaterial = override as ShaderMaterial
		if shader_material != null:
			var albedo: Variant = shader_material.get_shader_parameter(
				"albedo_color")
			print("            parametre albedo_color du shader : %s" % albedo)
	quit(0)
