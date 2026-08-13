## V2.2R — FILET du maillage d'eau : aucun quad de torsion aux coudes.
##
## Défaut constaté par la revue visuelle du lead (autorité : capture
## `vue_couture_chunks.png`) : jonction anguleuse et superposition dans
## l'eau. Cause réelle : l'ancien ruban émettait, à chaque waypoint
## intérieur, un quad DÉGÉNÉRÉ (longueur nulle le long du fil) qui TORD la
## bande de l'orientation du segment sortant vers celle du segment entrant —
## il chevauche ses deux voisins et double l'alpha.
##
## Les données de maillage (ArrayMesh) sont lisibles en headless — ce filet
## mesure le MAILLAGE réel, pas un plan. Écrit ROUGE d'abord contre le
## ruban par segments ; le ruban MITRÉ le rend vert.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
## En dessous de cet avancement le long du fil, un quad est dégénéré.
const MIN_QUAD_ADVANCE_M: float = 0.05

var _world: Node3D = null


func test_les_rubans_d_eau_n_ont_aucun_quad_de_torsion() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	loop.root.add_child(_world)
	await loop.process_frame
	await loop.physics_frame

	var faults: Array[String] = []
	var quads_seen: int = 0
	for ribbon_name: String in ["MainCourseWater", "TributaryWater"]:
		var instance: MeshInstance3D = _world.get_node_or_null(
			"Water/" + ribbon_name) as MeshInstance3D
		if instance == null or instance.mesh == null:
			faults.append("%s absent" % ribbon_name)
			continue
		var arrays: Array = instance.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		# Soupe de triangles, 6 sommets par quad :
		# [0]=gauche_prec [1]=droite_cour [2]=droite_prec
		# [3]=gauche_prec [4]=gauche_cour [5]=droite_cour
		var quad_count: int = vertices.size() / 6
		for q: int in range(quad_count):
			quads_seen += 1
			var base: int = q * 6
			var prev_mid: Vector3 = (vertices[base] + vertices[base + 2]) * 0.5
			var cur_mid: Vector3 = (vertices[base + 4] + vertices[base + 1]) * 0.5
			var advance: float = Vector2(cur_mid.x - prev_mid.x,
				cur_mid.z - prev_mid.z).length()
			if advance < MIN_QUAD_ADVANCE_M:
				faults.append("%s : quad de torsion en (%.0f, %.0f)"
					% [ribbon_name, cur_mid.x, cur_mid.z])
	check(quads_seen > 60, "les rubans portent bien des quads à mesurer (%d)"
		% quads_seen)
	var shown: Array[String] = faults.slice(0, 6)
	if faults.size() > 6:
		shown.append("… et %d autres" % (faults.size() - 6))
	check(faults.is_empty(), "aucun quad dégénéré aux coudes (%d) — %s"
		% [faults.size(), " ; ".join(shown)])

	var clean: bool = await restore_root()
	check(clean, "démontage propre (eau) — %s" % restore_root_reason())
	restore_saves()
