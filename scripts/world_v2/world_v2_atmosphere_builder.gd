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


## Nuage d'orage V2.2R.1 : UNE SEULE MASSE OPAQUE fusionnée, colorée par
## SOMMET — plus aucune transparence imbriquée.
##
## HISTORIQUE MESURÉ : passes 1-2 = soucoupes ; passe 3 = galette noire
## (verdict du lead) ; passe 4 (V2.2R) = coques translucides superposées
## dont les intersections restaient lisibles à travers les volumes — une
## « énorme boule polyédrique translucide » (rejet V2.2R.1, region_r10).
## La cause : chaque lobe portait son propre mesh, et les coques alpha se
## voyaient l'une à travers l'autre. Ici tous les lobes fusionnent dans un
## SEUL ArrayMesh opaque (le z-buffer avale les recouvrements), la matière
## vit dans les couleurs de sommet : ventre sombre irrégulier, corps dense,
## têtes bourgeonnantes éclaircies côté soleil, bords secondaires.
func _storm_cloud() -> Node3D:
	var cloud: Node3D = Node3D.new()
	cloud.name = "StormCloud"
	cloud.position = CLOUD_CENTER
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var blob_count: int = 22
	for i: int in range(blob_count):
		var tier: float = float(i) / float(blob_count - 1)
		# Étages : lobes bas plus PETITS et sombres, corps moyen massif,
		# têtes hautes bourgeonnantes — volume vertical -20 à +26.
		var radius: float = (lerpf(14.0, 22.0, sin(tier * PI))
			+ rng.randf_range(-3.0, 5.0))
		var west_x: float = rng.randf_range(-30.0, 30.0) * (1.0 - tier * 0.4)
		var sun_side: float = clampf(0.5 - west_x / 60.0, 0.0, 1.0)
		var origin: Vector3 = Vector3(west_x,
			lerpf(-20.0, 26.0, tier) + rng.randf_range(-4.0, 4.0),
			rng.randf_range(-22.0, 22.0) * (1.0 - tier * 0.4))
		var stretch: Vector3 = Vector3(rng.randf_range(0.85, 1.15),
			lerpf(0.55, 0.8, rng.randf()), rng.randf_range(0.8, 1.1))
		_append_blob(st, origin, radius, stretch, rng.randi(), tier, sun_side)
	# Bords SECONDAIRES : trois petits lobes écartés à mi-hauteur — la
	# silhouette gagne des épaules, pas une boule.
	for k: int in range(3):
		var azimuth: float = TAU * (float(k) + 0.3) / 3.0
		var origin: Vector3 = Vector3(cos(azimuth) * 34.0,
			rng.randf_range(-2.0, 10.0), sin(azimuth) * 26.0)
		var sun_side: float = clampf(0.5 - origin.x / 60.0, 0.0, 1.0)
		_append_blob(st, origin, rng.randf_range(7.0, 10.5),
			Vector3(1.0, rng.randf_range(0.5, 0.7), 1.0), rng.randi(),
			0.45, sun_side)
	var mesh: ArrayMesh = st.commit()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color.WHITE
	material.roughness = 1.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.set_flag(BaseMaterial3D.FLAG_DISABLE_FOG, true)
	mesh.surface_set_material(0, material)
	var mass: MeshInstance3D = MeshInstance3D.new()
	mass.name = "CloudMass"
	mass.mesh = mesh
	cloud.add_child(mass)
	return cloud


## Ajoute un lobe GRUMELEUX à la masse fusionnée : sphère déplacée au bruit,
## couleur PAR SOMMET — ventre sombre, tête claire côté soleil, mottle.
func _append_blob(st: SurfaceTool, origin: Vector3, radius: float,
		stretch: Vector3, noise_seed: int, tier: float, sun_side: float) -> void:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 16
	sphere.rings = 7
	var arrays: Array = sphere.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.9
	noise.seed = noise_seed
	var base_dark: Color = Color(0.255, 0.265, 0.335)
	var top_light: Color = Color(0.47, 0.44, 0.48)
	var world: PackedVector3Array = PackedVector3Array()
	var tints: PackedColorArray = PackedColorArray()
	world.resize(vertices.size())
	tints.resize(vertices.size())
	for i: int in range(vertices.size()):
		var unit: Vector3 = vertices[i].normalized()
		var bump: float = noise.get_noise_3dv(unit * 2.2)
		var r: float = radius * (1.0 + bump * 0.38)
		world[i] = origin + Vector3(unit.x * r * stretch.x,
			unit.y * r * stretch.y, unit.z * r * stretch.z)
		# Ton : étage + hauteur DANS le lobe + soleil + mottle — le ventre
		# de chaque lobe reste sombre, seules les têtes ouest s'éclairent.
		var lift: float = clampf(tier * 0.8 + unit.y * 0.3, 0.0, 1.0)
		var tint: Color = base_dark.lerp(top_light,
			lift * (0.3 + 0.7 * sun_side))
		var belly: float = lerpf(0.84, 1.0, clampf(unit.y * 0.5 + 0.5, 0.0, 1.0))
		tints[i] = Color(tint.r * belly * (1.0 + bump * 0.08),
			tint.g * belly * (1.0 + bump * 0.08),
			tint.b * belly * (1.0 + bump * 0.06))
	for j: int in range(indices.size()):
		st.set_color(tints[indices[j]])
		st.add_vertex(world[indices[j]])


## Éclair : trajet IRRÉGULIER du ventre du nuage vers le plateau de la
## porte, invisible par défaut. V2.2R.1 (« nettement visible dans cam01 à
## l'exposition normale ») : à ~370 m, le ruban de 1,1 m de large faisait
## moins de 2 px — cœur ÉLARGI en quads CROISÉS (lisible sous tout azimut),
## émission renforcée, et UN halo translucide discret (une seule couche —
## jamais des transparences imbriquées).
func _lightning_bolt() -> MeshInstance3D:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = SEED + 7
	# MESURÉ À LA CAPTURE : le premier trajet visait une flèche de 90 m qui
	# n'existe pas dans le whitebox — l'éclair vivait ENTIÈREMENT DANS le
	# nuage, invisible. Il frappe du ventre du nuage vers le plateau (y=34).
	var from: Vector3 = CLOUD_CENTER + Vector3(4.0, -10.0, 2.0)
	var to: Vector3 = Vector3(0.0, 36.0, -206.0)
	var path: PackedVector3Array = PackedVector3Array()
	path.append(from)
	var segments: int = 7
	for i: int in range(1, segments + 1):
		var t: float = float(i) / float(segments)
		var point: Vector3 = from.lerp(to, t)
		if i < segments:
			point += Vector3(rng.randf_range(-3.5, 3.5), 0.0,
				rng.randf_range(-3.5, 3.5))
		path.append(point)

	var core_material: StandardMaterial3D = StandardMaterial3D.new()
	core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_material.albedo_color = Color(0.97, 1.0, 1.0)
	core_material.emission_enabled = true
	core_material.emission = Color(0.9, 0.98, 1.0)
	core_material.emission_energy_multiplier = 7.0
	core_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	core_material.set_flag(BaseMaterial3D.FLAG_DISABLE_FOG, true)
	var bolt: MeshInstance3D = MeshInstance3D.new()
	bolt.name = "StormBolt"
	bolt.mesh = _bolt_strip(path, 0.8, core_material)
	bolt.visible = false

	var halo_material: StandardMaterial3D = StandardMaterial3D.new()
	halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_material.albedo_color = Color(0.55, 0.9, 0.95, 0.30)
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.emission_enabled = true
	halo_material.emission = Color(0.35, 0.8, 0.9)
	halo_material.emission_energy_multiplier = 2.0
	halo_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	halo_material.set_flag(BaseMaterial3D.FLAG_DISABLE_FOG, true)
	var halo: MeshInstance3D = MeshInstance3D.new()
	halo.name = "StormBoltHalo"
	halo.mesh = _bolt_strip(path, 2.6, halo_material)
	bolt.add_child(halo)
	return bolt


## Ruban d'éclair en quads CROISÉS (deux plans en X par segment) : lisible
## sous n'importe quel azimut de caméra, jamais une lame vue par la tranche.
func _bolt_strip(path: PackedVector3Array, half_w: float,
		material: Material) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides: Array[Vector3] = [
		Vector3(half_w, 0.0, half_w) * 0.7071,
		Vector3(half_w, 0.0, -half_w) * 0.7071,
	]
	for i: int in range(path.size() - 1):
		var previous: Vector3 = path[i]
		var point: Vector3 = path[i + 1]
		for side: Vector3 in sides:
			st.add_vertex(previous - side)
			st.add_vertex(previous + side)
			st.add_vertex(point + side)
			st.add_vertex(previous - side)
			st.add_vertex(point + side)
			st.add_vertex(point - side)
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, material)
	return mesh
