## Bâtisseur d'ATMOSPHÈRE V2.2-C — nuage d'orage local et éclair.
##
## Directive §15 : l'orage n'assombrit QUE la zone de la citadelle (acquis
## V4 de l'ART_BIBLE) et le nuage n'est pas une soucoupe — il se construit
## en COUCHES irrégulières (bible §9.2 : base sombre aplatie, masse dense,
## bords plus clairs côté soleil, nappes périphériques décalées). L'éclair
## est un ÉVÉNEMENT à cœur blanc/halo cyan, invisible par défaut, cadencé
## par un Timer (aucun traitement par frame) et déclenchable pour capture.
##
## Le proxy de citadelle et les silhouettes lointaines restent whitebox :
## seule l'ATMOSPHÈRE de la zone est posée ici. Tout est TEMPORAIRE V2.2
## au sens de la directive — aucun de ces meshes n'est déclaré final.
class_name WorldV2AtmosphereBuilder
extends RefCounted

const SEED: int = 20260813
## Le nuage couronne la citadelle (ancre §3.3 : donjon vers (0, 34, -210)).
const CLOUD_CENTER: Vector3 = Vector3(0.0, 84.0, -212.0)
const FLASH_PERIOD_S: float = 11.0
const FLASH_DURATION_S: float = 0.18

var _heightmap: WorldV2Heightmap = null


func _init(heightmap: WorldV2Heightmap) -> void:
	_heightmap = heightmap


func build(parent: Node3D) -> void:
	parent.add_child(_storm_cloud())
	var bolt: MeshInstance3D = _lightning_bolt()
	parent.add_child(bolt)
	var timer: Timer = Timer.new()
	timer.name = "StormFlashTimer"
	timer.wait_time = FLASH_PERIOD_S
	timer.autostart = true
	# Flash bref : visible, puis re-caché par un second timer one-shot.
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(bolt):
			return
		bolt.visible = true
		var off: SceneTreeTimer = bolt.get_tree().create_timer(FLASH_DURATION_S)
		off.timeout.connect(func() -> void:
			if is_instance_valid(bolt):
				bolt.visible = false))
	parent.add_child(timer)


## Nuage en couches : base large et sombre, masse centrale, nappes décalées,
## bords supérieurs plus clairs CÔTÉ soleil (ouest). Chaque couche est une
## sphère aplatie déformée par graine fixe — jamais un disque régulier.
func _storm_cloud() -> Node3D:
	var cloud: Node3D = Node3D.new()
	cloud.name = "StormCloud"
	cloud.position = CLOUD_CENTER
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED
	# PREMIÈRE PASSE MESURÉE À LA CAPTURE : six couches presque concentriques
	# fusionnaient en SOUCOUPE lisse — exactement l'interdit. La masse se
	# construit désormais en MEUTE de blobs dispersés : une base sombre
	# large, des masses moyennes décalées, des têtes plus claires côté
	# soleil — le contour se casse à chaque échelle.
	# TROISIÈME PASSE : même dispersés, des sphères lisses restent des
	# ellipses — famille soucoupe. Le contour se casse au niveau du MAILLAGE
	# (déplacement radial bruité), et une frange basse enfonce le ventre
	# vers l'horizon.
	var blob_count: int = 15
	for i: int in range(blob_count):
		var tier: float = float(i) / float(blob_count - 1)
		var blob: MeshInstance3D = MeshInstance3D.new()
		blob.name = "CloudMass%d" % i
		var radius: float = lerpf(42.0, 14.0, tier) * rng.randf_range(0.75, 1.2)
		var material: StandardMaterial3D = StandardMaterial3D.new()
		# Bas sombre bleu-violet, têtes plus claires légèrement chaudes
		# (bord solaire §9.2) — jamais de noir bouché.
		var base_dark: Color = Color(0.175, 0.175, 0.225)
		var top_light: Color = Color(0.42, 0.38, 0.42)
		material.albedo_color = base_dark.lerp(top_light,
			tier * rng.randf_range(0.75, 1.0))
		material.roughness = 1.0
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		# La brume délavait la couronne en crêpe rose pâle (mesuré) : l'orage
		# est l'accent SOMBRE de sa zone — il perce le voile atmosphérique.
		material.set_flag(BaseMaterial3D.FLAG_DISABLE_FOG, true)
		blob.mesh = _blob_mesh(radius, rng.randf_range(0.18, 0.32),
			rng.randi(), material)
		blob.position = Vector3(rng.randf_range(-40.0, 40.0),
			lerpf(-14.0, 14.0, tier) + rng.randf_range(-3.0, 3.0),
			rng.randf_range(-26.0, 26.0))
		blob.scale = Vector3(rng.randf_range(0.7, 1.35), 1.0,
			rng.randf_range(0.6, 1.2))
		blob.rotation.y = rng.randf() * TAU
		cloud.add_child(blob)
	return cloud


## Masse nuageuse GRUMELEUSE : sphère basse résolution déplacée radialement
## par un bruit à graine fixe, puis aplatie — le contour n'est jamais une
## ellipse propre.
func _blob_mesh(radius: float, flatten: float, noise_seed: int,
		material: Material) -> ArrayMesh:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 16
	sphere.rings = 7
	var arrays: Array = sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.9
	noise.seed = noise_seed
	for i: int in range(vertices.size()):
		var v: Vector3 = vertices[i]
		var bump: float = noise.get_noise_3dv(v.normalized() * 2.2)
		var r: float = radius * (1.0 + bump * 0.38)
		vertices[i] = Vector3(v.x * r, v.y * r * flatten, v.z * r)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	return mesh


## Éclair : trajet IRRÉGULIER du ventre du nuage vers la flèche de la
## citadelle, cœur blanc, invisible par défaut (§9.3 bible — 2-4 branches
## viendront avec le VFX complet d'une phase ultérieure).
func _lightning_bolt() -> MeshInstance3D:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED + 7
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# MESURÉ À LA CAPTURE : le premier trajet visait une flèche de 90 m qui
	# n'existe pas dans le whitebox — l'éclair vivait ENTIÈREMENT DANS le
	# nuage, invisible. Il frappe désormais du ventre du nuage vers le
	# plateau de la porte (y = 34, ancre §3.3).
	var from: Vector3 = CLOUD_CENTER + Vector3(4.0, -10.0, 2.0)
	var to: Vector3 = Vector3(0.0, 36.0, -206.0)
	var segments: int = 7
	var previous: Vector3 = from
	for i: int in range(1, segments + 1):
		var t: float = float(i) / float(segments)
		var point: Vector3 = from.lerp(to, t)
		if i < segments:
			point += Vector3(rng.randf_range(-3.5, 3.5), 0.0,
				rng.randf_range(-3.5, 3.5))
		var side: Vector3 = Vector3(0.35, 0.0, 0.35)
		st.add_vertex(previous - side)
		st.add_vertex(previous + side)
		st.add_vertex(point + side)
		st.add_vertex(previous - side)
		st.add_vertex(point + side)
		st.add_vertex(point - side)
		previous = point
	var mesh: ArrayMesh = st.commit()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.95, 1.0, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.55, 0.9, 0.95)
	material.emission_energy_multiplier = 2.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.set_flag(BaseMaterial3D.FLAG_DISABLE_FOG, true)
	mesh.surface_set_material(0, material)
	var bolt: MeshInstance3D = MeshInstance3D.new()
	bolt.name = "StormBolt"
	bolt.mesh = mesh
	bolt.visible = false
	return bolt
