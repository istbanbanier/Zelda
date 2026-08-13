## Bâtisseur des LIMITES du monde V2.1 — fermeture physique sans mur nu.
##
## L'anneau de relief (fonction de hauteur) ferme déjà visuellement le monde,
## mais D-019 rend toute pente raide ESCALADABLE : sans garde-fous, le joueur
## grimperait l'anneau et sortirait du monde. La ceinture de crêtes whitebox
## (masses simples autorisées par le prompt §9) porte donc le groupe
## `unclimbable` : visible, épaisse, EMBARQUÉE dans la montée de l'anneau —
## jamais une paroi invisible exposée. Les segments se recouvrent : aucune
## brèche. Au-delà, des silhouettes visuelles sans collision (hors d'atteinte).
class_name WorldV2BordersBuilder
extends RefCounted

const GUARD_SEGMENTS: int = 36
const GUARD_RADIUS: float = 246.0
const GUARD_HEIGHT: float = 34.0
const GUARD_THICKNESS: float = 6.0
## Longueur avec RECOUVREMENT : périmètre/36 ≈ 42,9 m — 50 m ferme les joints.
const GUARD_LENGTH: float = 50.0
const FAR_SILHOUETTES: int = 12
const FAR_RADIUS: float = 276.0

var _heightmap: WorldV2Heightmap = null


func _init(heightmap: WorldV2Heightmap) -> void:
	_heightmap = heightmap


func build(parent: Node3D) -> void:
	var ring: Node3D = Node3D.new()
	ring.name = "BorderGuards"
	parent.add_child(ring)
	for i: int in range(GUARD_SEGMENTS):
		var azimuth: float = TAU * float(i) / float(GUARD_SEGMENTS)
		var x: float = cos(azimuth) * GUARD_RADIUS
		var z: float = sin(azimuth) * GUARD_RADIUS
		var ground: float = _heightmap.height_at(x, z)
		var guard: StaticBody3D = StaticBody3D.new()
		guard.name = "BorderGuard%02d" % i
		guard.collision_layer = 1
		guard.collision_mask = 0
		guard.add_to_group(&"unclimbable")
		guard.add_to_group(&"world_v2_border_guards")
		# Crête variable par segment : des cols, pas un anneau plat (§9).
		var crest: float = GUARD_HEIGHT + 8.0 * sin(azimuth * 8.0 + 1.3)
		guard.position = Vector3(x, ground + crest * 0.5 - 6.0, z)
		guard.rotation = Vector3(0.0, -azimuth, 0.0)
		# V2.2-C : le VISUEL devient une crête déchiquetée — la COLLISION
		# reste la boîte V2.1 exacte (le test des 72 azimuts lit la
		# collision, jamais le maillage).
		var visual: MeshInstance3D = MeshInstance3D.new()
		visual.name = "GuardMesh"
		visual.mesh = _ridge_mesh(crest, i, 1.0, Color(0.355, 0.31, 0.29))
		guard.add_child(visual)
		# Contrefort SUPERPOSÉ : une seconde masse décalée, plus basse et
		# plus sombre — « masses rocheuses superposées, variations de
		# profondeur » (V2.2R famille A). Visuel pur, aucune collision.
		var buttress: MeshInstance3D = MeshInstance3D.new()
		buttress.name = "GuardButtress"
		buttress.mesh = _ridge_mesh(crest * 0.72, i + 100, 0.8,
			Color(0.30, 0.265, 0.255))
		buttress.position = Vector3(-4.5 if (i % 2 == 0) else 4.5,
			-crest * 0.16, 11.0 if (i % 3 == 0) else -9.0)
		guard.add_child(buttress)
		var shape: BoxShape3D = BoxShape3D.new()
		# La boîte V2.1 EXACTE — la fermeture physique ne bouge pas d'un mètre.
		shape.size = Vector3(GUARD_THICKNESS, crest, GUARD_LENGTH)
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.name = "GuardCollision"
		collision.shape = shape
		guard.add_child(collision)
		ring.add_child(guard)

	# Silhouettes lointaines : VISUEL SEULEMENT, hors de portée (au-delà des
	# gardes) — elles habillent l'horizon whitebox, elles ne bloquent rien.
	var far: Node3D = Node3D.new()
	far.name = "FarSilhouettes"
	parent.add_child(far)
	# Bleu-gris : les pics lointains s'enfoncent dans la brume (§9.4 :
	# montagnes éclaircies, refroidies, simplifiées). V2.2R famille A,
	# 2e passe (mesuré cam04) : le cône déplacé restait un « chapeau de
	# papier » — apex net, matière unie. On réutilise la crête déchiquetée
	# à strates qui a fait ses preuves sur l'anneau gardien, en plus large.
	for i: int in range(FAR_SILHOUETTES):
		var azimuth: float = TAU * (float(i) + 0.5) / float(FAR_SILHOUETTES)
		var x: float = cos(azimuth) * FAR_RADIUS
		var z: float = sin(azimuth) * FAR_RADIUS
		var peak: MeshInstance3D = MeshInstance3D.new()
		peak.name = "FarPeak%02d" % i
		var height: float = 62.0 + 16.0 * sin(azimuth * 3.0 + 2.1)
		# Ton PIERRE en brume — le bleu-blanc (0.35,0.39,0.46) lisait
		# « papier » (rejet V2.2R.1) ; gris chaud, la brume refroidit déjà.
		peak.mesh = _ridge_mesh(height, 400 + i * 7, 2.6, Color(0.36, 0.34, 0.34))
		peak.position = Vector3(x, height * 0.5 + 18.0, z)
		peak.rotation = Vector3(0.0, -azimuth, 0.0)
		far.add_child(peak)


## Crête de montagne : une boîte subdivisée PINCÉE vers le sommet et
## déchiquetée au bruit à graine fixe — l'enroulement vient de BoxMesh, il
## n'est jamais réécrit à la main (leçon V2.1 : l'enroulement se prouve à
## la capture).
##
## V2.2R famille A (revue du lead : « grandes faces rectangulaires unies,
## lamelles de ciel ») : le bruit touche désormais TOUTES les faces (les
## flancs restaient des plans), les bouts s'effilent et plongent (aucun
## chant rectangulaire ne coupe le voisin), le recouvrement s'élargit
## au-delà de la boîte de collision (visuel pur), et la matière porte des
## STRATES + un mottling en couleurs de sommet — plus aucune face unie.
func _ridge_mesh(crest: float, ridge_seed: int, width_scale: float,
		base_tone: Color) -> ArrayMesh:
	var box: BoxMesh = BoxMesh.new()
	# +16 %% de longueur VISUELLE : les crêtes voisines s'interpénètrent.
	box.size = Vector3(GUARD_THICKNESS, crest, GUARD_LENGTH * 1.16)
	box.subdivide_width = 4
	box.subdivide_height = 8
	box.subdivide_depth = 20
	var arrays: Array = box.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colors: PackedColorArray = PackedColorArray()
	colors.resize(vertices.size())
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.055
	noise.seed = 20260813 + ridge_seed
	var half_h: float = crest * 0.5
	var half_l: float = box.size.z * 0.5
	# Amplitude latérale du bruit : les masses LARGES (pics lointains,
	# width_scale 2,6) gardaient un bruit absolu devenu relativement lisse —
	# des « chapeaux de papier » (rejet V2.2R.1). Elle suit l'échelle.
	var crag: float = 1.0 + (width_scale - 1.0) * 0.7
	for i: int in range(vertices.size()):
		var v: Vector3 = vertices[i]
		var t: float = clampf((v.y + half_h) / crest, 0.0, 1.0)
		# Bouts effilés et plongeants : le chant ne coupe jamais le voisin.
		var end: float = smoothstep(0.62, 1.0, absf(v.z) / half_l)
		v.x *= lerpf(2.6, 0.22, t) * width_scale * (1.0 - 0.55 * end)
		v.y -= end * crest * 0.30
		# Le bruit vit sur TOUTES les faces, pas seulement la crête. La
		# 2e octave varie EN HAUTEUR : sans elle, le flanc ne bougeait que
		# le long de la crête et restait un plan de 20 m lisible de près
		# (mesuré sur la capture dédiée r11, V2.2R famille A).
		v.y += noise.get_noise_2d(v.z, 13.7) * crest * 0.30 * (0.25 + 0.75 * t)
		v.x += noise.get_noise_2d(v.z * 0.7, 41.2) * 3.0 * crag * (0.45 + 0.55 * t)
		v.x += noise.get_noise_2d(v.y * 0.9, v.z * 0.35 + 57.3) * 2.4 * crag
		v.z += noise.get_noise_2d(v.x * 1.3, 77.9) * 2.2 * crag
		# JUPE D'ENFOUISSEMENT (V2.2R.1 famille A — « plaques suspendues,
		# dessous sombres, fentes entre les couches, masses qui flottent »,
		# region_r06/r07/r11) : la base plonge PROFONDÉMENT sous le terrain
		# qui la supporte — le terrain sous les 58 m d'un segment varie de
		# plus que les 6 m d'enfoncement V2.1, et chaque creux ouvrait une
		# fente sous la plaque. Visuel pur : la boîte de collision ne bouge pas.
		var burial: float = smoothstep(0.18, 0.0, t)
		v.y -= burial * (crest * 0.35 + 12.0)
		v.x *= 1.0 + burial * 0.25
		vertices[i] = v
		# Matière : strates horizontales larges + mottling — arête un peu
		# plus chaude, creux plus froids (§6.3), jamais un aplat.
		var strata: float = sin((v.y + half_h) * 0.55
			+ noise.get_noise_2d(v.z * 0.4, 5.0) * 2.0) * 0.5 + 0.5
		var mottle: float = noise.get_noise_2d(v.z * 1.8, v.y * 1.8) * 0.5 + 0.5
		var shade: float = 0.82 + strata * 0.22 + (mottle - 0.5) * 0.18
		colors[i] = Color(base_tone.r * shade * (1.0 + t * 0.10),
			base_tone.g * shade, base_tone.b * shade * (1.0 - t * 0.06))
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var displaced: ArrayMesh = ArrayMesh.new()
	displaced.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# RECALCULER les normales : après déplacement, celles de la boîte sont
	# PÉRIMÉES — la lumière ignorait tout le relief et chaque flanc restait
	# un aplat éclairé uniformément, quel que soit le bruit (cause réelle
	# des « grandes faces unies » vues de près — mesuré, capture r11).
	var st: SurfaceTool = SurfaceTool.new()
	st.create_from(displaced, 0)
	st.generate_normals()
	var mesh: ArrayMesh = st.commit()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color.WHITE
	material.roughness = 1.0
	material.metallic_specular = 0.05
	mesh.surface_set_material(0, material)
	return mesh
