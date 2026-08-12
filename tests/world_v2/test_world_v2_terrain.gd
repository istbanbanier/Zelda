## V2.1 — le TERRAIN est vrai : 64 chunks raccordés, relief continu, pas de dalles.
##
## Ce que chaque garde empêche :
##   - un chunk manquant ou mal nommé = un trou de monde silencieux ;
##   - une couture décalée = le joueur tombe entre deux chunks (contrôle
##     négatif A : décaler une frontière doit faire rougir CE test) ;
##   - un monde re-plat = la V1 refaite sous un autre nom (ISS-045 : 96,8 %
##     de plat) ;
##   - une marche verticale sur le chemin = un mur invisible de fait.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
## Littéraux de la grille contractuelle (V2.0 §11) — indépendants du code.
const EXPECTED_CHUNKS: int = 64
const EXPECTED_GRID: int = 8
const CHUNK_M: float = 64.0
const WORLD_MIN: float = -256.0
## Plat toléré (<1° de pente) dans le rayon jouable : mesuré 13,6 % à la
## conception — 30 % laisse de la marge SANS retomber dans une V1 plate.
const MAX_FLAT_RATIO: float = 0.30
## Aucune marche verticale artificielle le long du trajet principal.
const MAX_STEP_PER_METRE: float = 1.3

var _world: Node3D = null


func _mount_world() -> Node3D:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	var packed: PackedScene = load(WORLD_V2_SCENE) as PackedScene
	_world = packed.instantiate() as Node3D
	loop.root.add_child(_world)
	return _world


func test_le_monde_porte_exactement_64_chunks_raccordes() -> void:
	var loop: SceneTree = Engine.get_main_loop() as SceneTree
	remember_saves()
	remember_root()
	var world: Node3D = _mount_world()
	await loop.process_frame

	# --- 64 chunks, nommés par la grille, chacun avec collision ET visuel.
	var chunks: Array[Node] = loop.get_nodes_in_group(&"world_v2_terrain")
	check_equal(chunks.size(), EXPECTED_CHUNKS, "le monde porte 64 chunks")
	var seen: Dictionary = {}
	for chunk: Node in chunks:
		seen[String(chunk.name)] = chunk
	for row: int in range(EXPECTED_GRID):
		for col: int in range(EXPECTED_GRID):
			var wanted: String = "c%dr%d" % [col, row]
			check(seen.has(wanted), "le chunk %s existe" % wanted)
	var sample: StaticBody3D = seen.get("c3r3") as StaticBody3D
	check_not_null(sample, "chunk central inspectable")
	if sample != null:
		check(sample.get_node_or_null("GroundCollision") != null,
			"chaque chunk porte sa collision")
		check(sample.get_node_or_null("GroundMesh") != null,
			"chaque chunk porte son visuel")

	# --- Emprise : les chunks d'angle couvrent bien ±256.
	var corner: StaticBody3D = seen.get("c0r0") as StaticBody3D
	if corner != null:
		check_approx(corner.position.x, WORLD_MIN + CHUNK_M * 0.5, 0.01,
			"le chunk c0r0 commence à l'origine -256")
	var far_corner: StaticBody3D = seen.get("c7r7") as StaticBody3D
	if far_corner != null:
		check_approx(far_corner.position.x, -WORLD_MIN - CHUNK_M * 0.5, 0.01,
			"le chunk c7r7 finit à +256")

	# --- Coutures : les DONNÉES DE COLLISION de chunks voisins partagent
	# leur frontière échantillon par échantillon. C'est la vérité physique,
	# pas la promesse de la fonction (contrôle négatif A : un décalage
	# volontaire d'un chunk doit rougir ICI en nommant la frontière).
	var seam_faults: Array[String] = []
	var samples: int = int(CHUNK_M) + 1
	for pair: Array in [["c3r3", "c4r3", "est"], ["c3r3", "c3r4", "sud"],
			["c0r0", "c1r0", "est"], ["c6r7", "c7r7", "est"], ["c4r5", "c4r6", "sud"]]:
		var left: StaticBody3D = seen.get(pair[0]) as StaticBody3D
		var right: StaticBody3D = seen.get(pair[1]) as StaticBody3D
		if left == null or right == null:
			seam_faults.append("paire %s/%s absente" % [pair[0], pair[1]])
			continue
		var left_map: PackedFloat32Array = _map_of(left)
		var right_map: PackedFloat32Array = _map_of(right)
		for i: int in range(samples):
			var left_value: float = 0.0
			var right_value: float = 0.0
			if String(pair[2]) == "est":
				left_value = left_map[i * samples + (samples - 1)]
				right_value = right_map[i * samples]
			else:
				left_value = left_map[(samples - 1) * samples + i]
				right_value = right_map[i]
			if absf(left_value - right_value) > 0.001:
				seam_faults.append("frontière %s de %s : écart %.3f à l'échantillon %d"
					% [pair[2], pair[0], absf(left_value - right_value), i])
				break
	check(seam_faults.is_empty(),
		"les frontières de chunks sont IDENTIQUES — %s" % " ; ".join(seam_faults))

	var clean: bool = await restore_root()
	check(clean, "démontage propre — %s" % restore_root_reason())
	restore_saves()


func test_le_relief_n_est_pas_un_assemblage_de_dalles() -> void:
	var layout: Dictionary = WorldV2Layout.load_layout()
	var heightmap: WorldV2Heightmap = WorldV2Heightmap.new(layout)

	# --- Déterminisme : deux instances de la fonction rendent le même monde.
	var second: WorldV2Heightmap = WorldV2Heightmap.new(layout)
	var determinism_ok: bool = true
	for probe: Array in [[0, 170], [45, 65], [-120, -30], [96, 16], [200, 200]]:
		if absf(heightmap.height_at(float(probe[0]), float(probe[1]))
				- second.height_at(float(probe[0]), float(probe[1]))) > 0.000001:
			determinism_ok = false
	check(determinism_ok, "la fonction de hauteur est déterministe")

	# --- Plat borné dans le rayon jouable (ISS-045 : la V1 était à 96,8 %).
	var flat: int = 0
	var total: int = 0
	for z: int in range(-230, 231, 6):
		for x: int in range(-230, 231, 6):
			if Vector2(float(x), float(z)).length() >= WorldV2Heightmap.PLAYABLE_RADIUS_M:
				continue
			total += 1
			if heightmap.slope_deg_at(float(x), float(z)) < 1.0:
				flat += 1
	var ratio: float = float(flat) / float(maxi(total, 1))
	check(ratio <= MAX_FLAT_RATIO,
		"le plat (<1°) reste borné : %.1f %% mesuré, plafond %.0f %%"
			% [ratio * 100.0, MAX_FLAT_RATIO * 100.0])
	check(ratio > 0.005,
		"il reste des replats jouables — un monde 100 %% pentu serait suspect")

	# --- Le relief a de VRAIES collines : écart-type des hauteurs de la
	# cuvette sud loin des pads.
	var plains_heights: Array[float] = []
	for z: int in range(70, 131, 5):
		for x: int in range(-70, 11, 5):
			plains_heights.append(heightmap.height_at(float(x), float(z)))
	var mean: float = 0.0
	for h: float in plains_heights:
		mean += h
	mean /= float(plains_heights.size())
	var variance: float = 0.0
	for h: float in plains_heights:
		variance += (h - mean) * (h - mean)
	variance /= float(plains_heights.size())
	check(sqrt(variance) >= 0.7,
		"la cuvette sud ondule réellement (écart-type %.2f m ≥ 0,7)" % sqrt(variance))

	# --- Aucune marche verticale sur le trajet principal (échantillon au mètre).
	var worst_step: float = 0.0
	var worst_at: Vector2 = Vector2.ZERO
	var route: Dictionary = (layout.get("routes", {}) as Dictionary) \
		.get("main_path", {}) as Dictionary
	var waypoints: Array = route.get("waypoints_xz", []) as Array
	for i: int in range(waypoints.size() - 1):
		var a: Vector2 = Vector2(float((waypoints[i] as Array)[0]),
			float((waypoints[i] as Array)[1]))
		var b: Vector2 = Vector2(float((waypoints[i + 1] as Array)[0]),
			float((waypoints[i + 1] as Array)[1]))
		var steps: int = maxi(2, int(a.distance_to(b)))
		var previous: float = heightmap.height_at(a.x, a.y)
		for s: int in range(1, steps + 1):
			var p: Vector2 = a.lerp(b, float(s) / float(steps))
			var h: float = heightmap.height_at(p.x, p.y)
			if absf(h - previous) > worst_step:
				worst_step = absf(h - previous)
				worst_at = p
			previous = h
	check(worst_step <= MAX_STEP_PER_METRE,
		"aucune marche verticale sur le trajet principal (pire : %.2f m/m en %.0f,%.0f)"
			% [worst_step, worst_at.x, worst_at.y])


func _map_of(chunk: StaticBody3D) -> PackedFloat32Array:
	var collision: CollisionShape3D = chunk.get_node("GroundCollision") as CollisionShape3D
	return (collision.shape as HeightMapShape3D).map_data
