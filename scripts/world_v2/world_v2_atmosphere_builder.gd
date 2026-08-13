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
	# HISTORIQUE MESURÉ : passes 1-2 = soucoupes (couches concentriques puis
	# sphères lisses) ; passe 3 = galette noire suspendue (verdict de la
	# revue du lead — base horizontale, quasi-noir, aucune épaisseur).
	# V2.2R : un CUMULONIMBUS — vraie ÉPAISSEUR VERTICALE (trois étages),
	# dessous en LOBES irréguliers, têtes bourgeonnantes plus claires,
	# jamais près-noir, et des COQUES translucides qui diffusent les bords
	# dans l'atmosphère. Aucune longue base horizontale : les lobes bas
	# descendent à des hauteurs différentes.
	var blob_count: int = 22
	for i: int in range(blob_count):
		var tier: float = float(i) / float(blob_count - 1)
		var blob: MeshInstance3D = MeshInstance3D.new()
		blob.name = "CloudMass%d" % i
		# Étages : lobes bas plus PETITS et sombres, corps moyen massif,
		# têtes hautes bourgeonnantes.
		var radius: float = (lerpf(14.0, 22.0, sin(tier * PI))
			+ rng.randf_range(-3.0, 5.0))
		var material: StandardMaterial3D = StandardMaterial3D.new()
		# Du gris-bleu orageux au gris chaud des crêtes — jamais de noir.
		# La lumière vient de l'OUEST : seules les têtes CÔTÉ soleil
		# s'éclairent — un clair uniforme lisait « boule pâle » (mesuré).
		var base_dark: Color = Color(0.255, 0.265, 0.335)
		var top_light: Color = Color(0.46, 0.43, 0.47)
		var west_x: float = rng.randf_range(-30.0, 30.0) * (1.0 - tier * 0.4)
		var sun_side: float = clampf(0.5 - west_x / 60.0, 0.0, 1.0)
		material.albedo_color = base_dark.lerp(top_light,
			tier * (0.25 + 0.75 * sun_side) * rng.randf_range(0.8, 1.0))
		material.roughness = 1.0
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.set_flag(BaseMaterial3D.FLAG_DISABLE_FOG, true)
		var flatten: float = lerpf(0.55, 0.8, rng.randf())
		blob.mesh = _blob_mesh(radius, flatten, rng.randi(), material)
		# Volume VERTICAL : -20 (lobes pendants) à +26 (têtes), resserré en
		# plan — une tour d'orage, pas une assiette.
		blob.position = Vector3(west_x,
			lerpf(-20.0, 26.0, tier) + rng.randf_range(-4.0, 4.0),
			rng.randf_range(-22.0, 22.0) * (1.0 - tier * 0.4))
		blob.scale = Vector3(rng.randf_range(0.85, 1.15), 1.0,
			rng.randf_range(0.8, 1.1))
		blob.rotation.y = rng.randf() * TAU
		cloud.add_child(blob)
		# Coque diffuse : seulement sur les lobes BAS (le ventre fond dans
		# l'atmosphère) — sur les têtes, elle délavait tout en boule pâle.
		if tier > 0.55:
			continue
		var shell: MeshInstance3D = MeshInstance3D.new()
		shell.name = "CloudShell%d" % i
		var shell_material: StandardMaterial3D = StandardMaterial3D.new()
		# Coque au TON de sa masse (à peine plus claire) : une coque blanche
		# délavait la cellule en chou-fleur lilas (mesuré cam01).
		shell_material.albedo_color = Color(material.albedo_color.r * 1.02,
			material.albedo_color.g * 1.02, material.albedo_color.b * 1.05, 0.16)
		shell_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shell_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		shell_material.cull_mode = BaseMaterial3D.CULL_BACK
		shell.mesh = _blob_mesh(radius * 1.3, flatten, rng.randi(), shell_material)
		shell.position = blob.position
		shell.scale = blob.scale
		shell.rotation.y = blob.rotation.y
		cloud.add_child(shell)
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
		var side: Vector3 = Vector3(0.55, 0.0, 0.55)
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
	material.emission_energy_multiplier = 3.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.set_flag(BaseMaterial3D.FLAG_DISABLE_FOG, true)
	mesh.surface_set_material(0, material)
	var bolt: MeshInstance3D = MeshInstance3D.new()
	bolt.name = "StormBolt"
	bolt.mesh = mesh
	bolt.visible = false
	return bolt
