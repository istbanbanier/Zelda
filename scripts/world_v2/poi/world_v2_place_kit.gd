## Outillage commun des lieux V2.3 — poser une pièce de kit CC0 avec le
## MÊME langage painterly que la végétation V2.2, sans rien télécharger.
##
## Règles portées ici (docs/WORLD_V2_POI_CONTRACTS.md §4) :
##  - résolution par NOM canonique sur les dossiers importés (village,
##    dungeon, props, cliffs, rocks, foliage) — `AssetRegistry.model()`
##    n'indexe pas village/ ni cliffs/, d'où le résolveur local ;
##  - toute pièce passe par `KitScale.factor()` (échelles fautives
##    mesurées) puis `KitPlacement.seat()` (origines fautives mesurées) ;
##  - matériaux DUPLIQUÉS et mis en cache par (matériau, teinte) :
##    roughness ≥ 0,95, spéculaire 0,1, teinte par catégorie — jamais de
##    mutation d'une ressource partagée ;
##  - chaque pièce reçoit un NOM explicite (Godot rebaptise les homonymes
##    en `@Node3D@366`, et plus aucun test ne peut les désigner).
class_name WorldV2PlaceKit
extends RefCounted

const MODULE_DIRS: Array[String] = [
	"res://assets/environment/village",
	"res://assets/environment/dungeon",
	"res://assets/environment/props",
	"res://assets/environment/cliffs",
	"res://assets/environment/rocks",
	"res://assets/environment/foliage",
]

## Teintes painterly par matière (cohérentes avec `_category_tone` de la
## végétation V2.2 : arbres olive, roches ocre).
const TONE_WOOD: Color = Color(0.86, 0.74, 0.58)
const TONE_STONE: Color = Color(0.95, 0.88, 0.78)
const TONE_PLANT: Color = Color(0.60, 0.63, 0.50)
const TONE_CLOTH: Color = Color(0.88, 0.66, 0.48)
const TONE_DARK_STONE: Color = Color(0.62, 0.58, 0.55)
const TONE_CHARRED: Color = Color(0.30, 0.27, 0.25)

## ISS-059 — PLAFOND DE RÉTENTION DES `PackedScene` DE KIT.
##
## Mesuré le 2026-08-20 : les six dossiers portent 212 modèles au total, dont
## 89 distincts sont réellement posés par le monde entier (compte indépendant :
## `KitPlacement._base_cache`, dont la clé est le NOM du modèle et non un
## identifiant d'instance — c'est pourquoi lui reste stable). Leur géométrie
## (`.gltf` + `.bin`) pèse 15 Mo pour les 212 — les textures, elles, sont des
## ressources séparées déjà retenues par les matériaux teintés du cache
## ci-dessous, donc cette rétention n'en ajoute aucune.
##
## Le plafond est donc au-dessus de tout ce qui peut exister aujourd'hui : la
## branche de vidage est une soupape, pas un chemin courant. Et c'est
## VOULU — vider ce cache relâcherait les `PackedScene`, ferait renaître des
## matériaux de base aux identifiants neufs, et rouvrirait exactement la fuite
## que `tests/world_v2/test_world_v2_iss059_cache_kit.gd` verrouille.
const SCENE_CACHE_MAX: int = 256

static var _index: Dictionary = {}
static var _material_cache: Dictionary = {}
## ISS-059 — ON GARDE LA RÉFÉRENCE, pour la même raison qu'`AssetRegistry`
## la garde (voir le commentaire de `AssetRegistry.model()`), plus une seconde
## qui est la cause de la fuite mesurée.
##
## Sans cette rétention, l'appelant instancie puis jette la `PackedScene` ; son
## compteur tombe à zéro, la ressource SORT du cache du moteur avec ses
## sous-ressources, et le montage suivant du même module recrée des matériaux
## de base NEUFS. Or `_material_cache` ci-dessus — et `_cache_teintes` du
## hameau, qui teinte les modules posés ici — indexent sur
## `base.get_instance_id()`. Une clé bâtie sur une identité plus courte que le
## cache ne peut jamais retomber juste : le cache est `static`, donc jamais
## vidé, et chaque remontage y déposait une génération de matériaux de plus.
##
## Mesuré avant correction (`evidence/world_v2/v2_3_r2b3/iss059/`), croissance
## LINÉAIRE et sans palier sur vingt cycles : +27 entrées par montage de la
## ferme seule, +4 pour l'arbre, +202 pour le monde entier.
static var _scene_cache: Dictionary = {}


## `PackedScene` d'une pièce de kit par nom canonique, ou null.
static func scene_for(model_name: StringName) -> PackedScene:
	if _index.is_empty():
		for dir_path: String in MODULE_DIRS:
			var dir: DirAccess = DirAccess.open(dir_path)
			if dir == null:
				continue
			for file: String in dir.get_files():
				var lower: String = file.to_lower()
				if lower.ends_with(".gltf") or lower.ends_with(".glb"):
					if not _index.has(StringName(file.get_basename())):
						_index[StringName(file.get_basename())] = \
							dir_path + "/" + file
	var cached: Variant = _scene_cache.get(model_name)
	if cached != null:
		return cached as PackedScene
	var path: String = String(_index.get(model_name, ""))
	var scene: PackedScene = null
	if path.is_empty():
		scene = AssetRegistry.model(model_name)
	else:
		scene = load(path) as PackedScene
	if scene != null:
		if _scene_cache.size() >= SCENE_CACHE_MAX:
			_scene_cache.clear()
		_scene_cache[model_name] = scene
	return scene


## Pose une pièce de kit : échelle corrigée, assise corrigée, teinte
## painterly, nom explicite. Rend null (et signale) si le modèle manque.
static func module(parent: Node3D, model_name: StringName, local_pos: Vector3,
		rot_y_deg: float = 0.0, extra_scale: float = 1.0,
		tone: Color = Color.WHITE) -> Node3D:
	var packed: PackedScene = scene_for(model_name)
	if packed == null:
		push_error("[world_v2] kit : modèle inconnu %s" % model_name)
		return null
	var node: Node3D = packed.instantiate() as Node3D
	node.name = "%s_%d" % [model_name, parent.get_child_count()]
	var factor: float = KitScale.factor(String(model_name)) * extra_scale
	node.scale = Vector3.ONE * factor
	node.rotation.y = deg_to_rad(rot_y_deg)
	node.position = local_pos
	parent.add_child(node)
	KitPlacement.seat(node, String(model_name))
	if tone != Color.WHITE:
		apply_tone(node, tone)
	return node


## Teinte painterly : matériau actif DUPLIQUÉ (cache par matériau+teinte),
## albédo multiplié, roughness ≥ 0,95, spéculaire réduit.
static func apply_tone(root: Node3D, tone: Color) -> void:
	var targets: Array[Node] = root.find_children("*", "MeshInstance3D",
		true, false)
	if root is MeshInstance3D:
		targets.append(root)
	for node: Node in targets:
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var active: Material = instance.get_active_material(surface)
			var base: StandardMaterial3D = active as StandardMaterial3D
			if base == null:
				continue
			var key: String = "%d|%s" % [base.get_instance_id(), tone]
			var tinted: StandardMaterial3D = \
				_material_cache.get(key) as StandardMaterial3D
			if tinted == null:
				tinted = base.duplicate() as StandardMaterial3D
				tinted.albedo_color = Color(
					base.albedo_color.r * tone.r, base.albedo_color.g * tone.g,
					base.albedo_color.b * tone.b, base.albedo_color.a)
				tinted.roughness = maxf(tinted.roughness, 0.95)
				tinted.metallic_specular = 0.1
				_material_cache[key] = tinted
			instance.set_surface_override_material(surface, tinted)


## Matériau plein painterly (géométrie procédurale des lieux).
static func flat_material(albedo: Color, emission: Color = Color.BLACK,
		emission_energy: float = 0.0) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.96
	material.metallic_specular = 0.1
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	return material


## BLOC DE PIERRE TAILLÉ — maillage irrégulier, pas une `BoxMesh`.
##
## Le lead a rejeté « des primitives » : une boîte parfaite se lit comme
## une primitive à toute distance. Ce bloc porte huit sommets déplacés par
## une graine, des faces PLATES (arêtes franches de taille) et une teinte
## variée par bloc — un appareil de pierre s'assemble alors avec des
## joints visibles, de l'usure et aucune répétition mécanique.
static func stone_block(parent: Node3D, block_name: String, at: Vector3,
		size: Vector3, yaw_deg: float, tone: Color, seed_value: int,
		jitter: float = 0.05) -> MeshInstance3D:
	var block: MeshInstance3D = MeshInstance3D.new()
	block.name = block_name
	block.mesh = irregular_box_mesh(size, jitter, seed_value)
	var shade: float = 1.0 + (float((seed_value * 37) % 100) / 100.0 - 0.5) * 0.16
	block.material_override = flat_material(
		Color(tone.r * shade, tone.g * shade, tone.b * shade))
	block.position = at
	block.rotation.y = deg_to_rad(yaw_deg)
	parent.add_child(block)
	return block


## Boîte à sommets déplacés, faces plates — la brique de tout appareil.
static func irregular_box_mesh(size: Vector3, jitter: float,
		seed_value: int) -> ArrayMesh:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var half: Vector3 = size * 0.5
	var corners: Array[Vector3] = []
	for i: int in range(8):
		var corner: Vector3 = Vector3(
			half.x * (1.0 if (i & 1) != 0 else -1.0),
			half.y * (1.0 if (i & 2) != 0 else -1.0),
			half.z * (1.0 if (i & 4) != 0 else -1.0))
		corners.append(corner + Vector3(
			rng.randf_range(-jitter, jitter) * size.x,
			rng.randf_range(-jitter, jitter) * size.y,
			rng.randf_range(-jitter, jitter) * size.z))
	# Six faces, chacune en deux triangles à normale plate.
	var faces: Array[Array] = [
		[0, 2, 3, 1], [4, 5, 7, 6], [0, 1, 5, 4],
		[2, 6, 7, 3], [0, 4, 6, 2], [1, 3, 7, 5],
	]
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Array in faces:
		var a: Vector3 = corners[int(face[0])]
		var b: Vector3 = corners[int(face[1])]
		var c: Vector3 = corners[int(face[2])]
		var d: Vector3 = corners[int(face[3])]
		var normal: Vector3 = (b - a).cross(c - a).normalized()
		for triangle: Array in [[a, b, c], [a, c, d]]:
			for point: Variant in triangle:
				st.set_normal(normal)
				st.add_vertex(point as Vector3)
	return st.commit()


## MASSE ROCHEUSE CREUSE — une enveloppe continue : parois irrégulières,
## plafond porté, et UNE ouverture (la bouche).
##
## Le lead a rejeté « un tas de rochers surdimensionnés » : des blocs
## posés côte à côte ne font jamais un volume. Ici la paroi est UN
## maillage fermé, généré par colonnes angulaires — rayon, hauteur et
## relief varient par une graine, la bouche est un secteur laissé ouvert,
## et le plafond est une voûte surbaissée cousue à la paroi intérieure.
##
## `mouth_center_deg` / `mouth_half_deg` définissent le secteur ouvert.
static func hollow_rock_mesh(inner_radius: float, wall_thickness: float,
		height: float, mouth_center_deg: float, mouth_half_deg: float,
		seed_value: int, segments: int = 40) -> ArrayMesh:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner: PackedVector3Array = PackedVector3Array()
	var outer: PackedVector3Array = PackedVector3Array()
	var tops: PackedFloat32Array = PackedFloat32Array()
	var open: Array[bool] = []
	for i: int in range(segments + 1):
		var t: float = float(i) / float(segments)
		var angle: float = TAU * t
		var degrees: float = rad_to_deg(angle)
		var delta: float = absf(wrapf(degrees - mouth_center_deg, -180.0, 180.0))
		open.append(delta < mouth_half_deg)
		# Relief : deux harmoniques + bruit de graine — jamais un cercle.
		var wobble: float = sin(angle * 3.0 + float(seed_value % 7)) * 0.16 \
			+ sin(angle * 5.0 + 1.7) * 0.09 + rng.randf_range(-0.05, 0.05)
		var r_in: float = inner_radius * (1.0 + wobble)
		var r_out: float = r_in + wall_thickness * (1.0 + wobble * 0.8)
		var top: float = height * (1.0 + sin(angle * 2.0 + 0.6) * 0.13
			+ rng.randf_range(-0.05, 0.05))
		inner.append(Vector3(cos(angle) * r_in, 0.0, sin(angle) * r_in))
		outer.append(Vector3(cos(angle) * r_out, 0.0, sin(angle) * r_out))
		tops.append(top)
	# Parois et couronne, sauf au secteur bouche.
	#
	# LA FACE EXTÉRIEURE SUIT UN PROFIL, elle n'est pas extrudée. Mesuré à
	# l'inspection du premier jet : une extrusion verticale + couronne
	# plate donne une BOÎTE beige, quelle que soit l'irrégularité du plan.
	# Le relief d'un rocher est d'abord dans son PROFIL — fruit vers le
	# haut, ressauts intermédiaires, crête irrégulière.
	var profile: Array[Vector2] = [
		Vector2(0.0, 1.0), Vector2(0.34, 0.90), Vector2(0.68, 0.74),
		Vector2(1.0, 0.52),
	]
	for i: int in range(segments):
		if open[i] and open[i + 1]:
			continue
		var i0: Vector3 = inner[i]
		var i1: Vector3 = inner[i + 1]
		var h0: float = tops[i]
		var h1: float = tops[i + 1]
		# Paroi intérieure : quasi verticale, et NETTEMENT plus sombre —
		# c'est ce qui creuse la poche à l'œil.
		_quad(st, i0 + Vector3(0, h0, 0), i1 + Vector3(0, h1, 0), i1, i0,
			0.42 + float(i % 3) * 0.03)
		# Paroi extérieure : une bande par palier de profil, chaque palier
		# décalé par le bruit — le rocher a des épaules, pas une façade.
		for p: int in range(profile.size() - 1):
			var lower: Vector2 = profile[p]
			var upper: Vector2 = profile[p + 1]
			var bump0: float = 1.0 + sin(float(i) * 0.7 + float(p) * 2.3) * 0.07
			var bump1: float = 1.0 + sin(float(i + 1) * 0.7 + float(p) * 2.3) * 0.07
			var a0: Vector3 = _shrink(inner[i], outer[i], lower.y * bump0) \
				+ Vector3(0, h0 * lower.x, 0)
			var a1: Vector3 = _shrink(inner[i + 1], outer[i + 1], lower.y * bump1) \
				+ Vector3(0, h1 * lower.x, 0)
			var b0: Vector3 = _shrink(inner[i], outer[i], upper.y * bump0) \
				+ Vector3(0, h0 * upper.x, 0)
			var b1: Vector3 = _shrink(inner[i + 1], outer[i + 1], upper.y * bump1) \
				+ Vector3(0, h1 * upper.x, 0)
			var band_shade: float = 1.06 - 0.14 * float(p) \
				+ float((i * 7 + p * 3) % 5) * 0.035
			_quad(st, a0, a1, b1, b0, band_shade)
		# Couronne : de la crête intérieure au sommet rétréci de la face.
		var top_out0: Vector3 = _shrink(inner[i], outer[i], profile[3].y) \
			+ Vector3(0, h0, 0)
		var top_out1: Vector3 = _shrink(inner[i + 1], outer[i + 1], profile[3].y) \
			+ Vector3(0, h1, 0)
		_quad(st, i0 + Vector3(0, h0, 0), top_out0, top_out1,
			i1 + Vector3(0, h1, 0), 0.88 + float(i % 4) * 0.04)
	# Les deux JOUES de la bouche : la paroi se referme sur son épaisseur.
	for i: int in range(segments):
		if open[i] == open[i + 1]:
			continue
		var edge: int = i + 1 if open[i + 1] else i
		_quad(st, inner[edge], outer[edge],
			outer[edge] + Vector3(0, tops[edge], 0),
			inner[edge] + Vector3(0, tops[edge], 0), 0.62)
	# PLAFOND : voûte surbaissée cousue à la crête intérieure.
	var apex: float = height * 1.28
	for i: int in range(segments):
		var a: Vector3 = inner[i] + Vector3(0, tops[i], 0)
		var b: Vector3 = inner[i + 1] + Vector3(0, tops[i + 1], 0)
		var mid_a: Vector3 = a * 0.45 + Vector3(0, apex - a.y, 0) * 0.0
		mid_a = Vector3(a.x * 0.45, apex * 0.92, a.z * 0.45)
		var mid_b: Vector3 = Vector3(b.x * 0.45, apex * 0.92, b.z * 0.45)
		# ENROULEMENT : la voûte se regarde par en DESSOUS. Au premier jet
		# elle était enroulée comme les parois — culée depuis l'extérieur,
		# elle laissait un TROU NOIR au sommet du rocher (vu en capture).
		_quad(st, mid_a, mid_b, b, a, 0.34 + float(i % 3) * 0.02)
		_triangle(st, Vector3(0.0, apex, 0.0), mid_b, mid_a, 0.30)
	return st.commit()


## SOL DE ROCHE CONTINU — un disque irrégulier, jamais des dalles
## disjointes : mesuré à l'inspection, l'herbe du terrain gelé passait
## entre les dalles et une grotte au gazon ne lit pas comme une grotte.
static func rock_floor_mesh(radius: float, seed_value: int,
		segments: int = 26) -> ArrayMesh:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim: PackedVector3Array = PackedVector3Array()
	for i: int in range(segments + 1):
		var angle: float = TAU * float(i) / float(segments)
		var r: float = radius * (1.0 + sin(angle * 3.0) * 0.09
			+ rng.randf_range(-0.05, 0.05))
		rim.append(Vector3(cos(angle) * r, rng.randf_range(-0.05, 0.05),
			sin(angle) * r))
	for i: int in range(segments):
		_triangle(st, Vector3.ZERO, rim[i], rim[i + 1],
			0.86 + float(i % 4) * 0.05)
	return st.commit()


## Point entre la paroi intérieure et la paroi extérieure : `t = 1`
## donne l'extérieur plein, `t = 0` la paroi intérieure.
static func _shrink(inner_point: Vector3, outer_point: Vector3,
		t: float) -> Vector3:
	return inner_point.lerp(outer_point, t)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		d: Vector3, shade: float = 1.0) -> void:
	_triangle(st, a, b, c, shade)
	_triangle(st, a, c, d, shade)


## Un triangle à normale plate et à VALEUR propre. La valeur de sommet est
## ce qui distingue une roche d'un plastique : sans elle, une enveloppe
## irrégulière reste une masse beige uniforme (mesuré à l'inspection).
static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3,
		c: Vector3, shade: float = 1.0) -> void:
	var normal: Vector3 = (b - a).cross(c - a).normalized()
	for point: Vector3 in [a, b, c]:
		st.set_color(Color(shade, shade, shade, 1.0))
		st.set_normal(normal)
		st.add_vertex(point)


## Collider boîte simple (layer 1, mask 0 — même contrat que la
## végétation : le monde le porte, il ne sonde rien).
static func collider_box(parent: Node3D, box_name: String, local_pos: Vector3,
		size: Vector3, rot_y_deg: float = 0.0) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = box_name
	body.collision_layer = 1
	body.collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = box_name + "_forme"
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.rotation.y = deg_to_rad(rot_y_deg)
	body.position = local_pos
	parent.add_child(body)
	return body

## ISS-059 — fin de vie du cache statique. Inscrite au démarrage du
## script par `_static_init()`, appelée UNE fois à l'extinction du moteur
## par `SceneFlow._exit_tree()`. Sans elle, ces entrées vivent jusqu'à la
## mort du processus et sortent au rapport de fuite : mesure et ablation à
## variable unique, `evidence/…/v2_3_r2b3_1/iss059/CHAINE_CAUSALE.md`.
##
## Le sens de la dépendance est imposé : le porteur connaît le noyau, le
## noyau ne connaît aucun porteur (test_aucune_reference_croisee_interdite).
static func _static_init() -> void:
	StaticResourceCaches.enregistrer("WorldV2PlaceKit", liberer_caches)


static func liberer_caches() -> int:
	var n: int = _scene_cache.size() + _material_cache.size() + _index.size()
	_scene_cache.clear()
	_material_cache.clear()
	_index.clear()
	return n
