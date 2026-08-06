## Habillage de la coque des salles du donjon (bible §12.2, §12.3).
##
## POURQUOI CE FICHIER EXISTE. Le vestibule de la citadelle est le seul intérieur
## réussi du jeu : il monte 31 instances du kit CC0 sur ses murs et ses colonnes.
## Les six salles du donjon, elles, sont bâties à 100 % de `BoxMesh` — un mur de
## 26 m est UN SEUL bloc. Elles ne référencent jamais `AssetRegistry`, alors que
## `assets/environment/dungeon/` contient 42 modules importés, attribués, et
## déjà employés… pour décorer la vallée. C'est tout l'écart visuel entre le
## vestibule et les salles.
##
## CE QUE FAIT CETTE PASSE, ET CE QU'ELLE NE FAIT PAS.
## Elle POSE un habillage devant la coque existante. Elle ne touche à aucune
## collision, ne déplace rien, ne supprime rien : les boîtes restent en place et
## restent l'autorité de gameplay (règle ART-P0). Si un module manque, la salle
## reste exactement ce qu'elle était — l'habillage est un bonus, jamais une
## dépendance.
##
## AD-008 est respectée : la LUMIÈRE d'abord, la matière ensuite. Cette passe
## remonte l'ambiante et allume les ombres AVANT de poser la moindre brique,
## parce qu'une salle déjà trop sombre (ISS-025) ne supporte pas qu'on
## l'assombrisse encore.
class_name RoomDressing
extends RefCounted

## Modules du kit, mesurés par `tools/gltf_inspect.py` :
##   Wall_UnevenBrick_Straight : 2,00 × 3,12 m, origine au pied, face vers +Z
##   Floor_Brick / Floor_UnevenBrick : dalle 2 × 2 m, origine au centre
##   Corner_Exterior_Brick : 3,01 m de haut — sert de pilastre
const WALL_MODULE: StringName = &"Wall_UnevenBrick_Straight"
const FLOOR_MODULES: Array[StringName] = [&"Floor_Brick", &"Floor_UnevenBrick"]
const PILASTER_MODULE: StringName = &"Corner_Exterior_Brick"

const WALL_W: float = 2.0
const WALL_H: float = 3.1227
const TILE: float = 2.0
## Deux rangs de briques = 6,25 m. Au-delà, la coque sombre tient lieu de
## hauteur : un mur qui s'assombrit en montant se lit plus haut qu'il n'est.
const WALL_ROWS: int = 2
## Un pilastre tous les 6 m casse la répétition du même module (§7.3).
const PILASTER_EVERY: float = 6.0
## Les modules répétés sont fusionnés en `MultiMeshInstance3D` (bible §26.3) :
## une salle de 20 × 26 m demande 130 dalles de sol, 130 de plafond et ~180
## panneaux de mur. Posés un par un, ce serait 440 appels de rendu pour de la
## brique. Groupés, c'est un appel par module — et le budget cesse d'exister.

## Noms de coque reconnus. Tout le reste — mécanismes, socles, rails, portes —
## est laissé intact : l'habillage ne doit JAMAIS masquer un télégraphe de jeu.
const SHELL_PREFIXES: Array[String] = [
	"Floor", "Ceiling", "Wall", "Corridor", "Shaft", "Vault", "Platform",
]


static func _is_shell(node_name: String) -> bool:
	for prefix: String in SHELL_PREFIXES:
		if node_name.begins_with(prefix):
			return true
	return false


## Boîte de collision d'un corps de coque : centre local et dimensions.
static func _box_of(body: StaticBody3D) -> Dictionary:
	for child: Node in body.get_children():
		if child is CollisionShape3D:
			var shape: Shape3D = (child as CollisionShape3D).shape
			if shape is BoxShape3D:
				return {"size": (shape as BoxShape3D).size,
					"center": body.position}
	return {}


## Un lot de poses pour un même module : on accumule, on fusionne à la fin.
static func _push(batch: Dictionary, key: StringName, at: Vector3,
		yaw: float, scale_xyz: Vector3) -> void:
	if not batch.has(key):
		batch[key] = [] as Array[Transform3D]
	var basis: Basis = Basis(Vector3.UP, yaw).scaled(scale_xyz)
	(batch[key] as Array[Transform3D]).append(Transform3D(basis, at))


## Fusionne un lot en `MultiMeshInstance3D`, un par maillage du module.
## Un module du kit peut contenir plusieurs `MeshInstance3D` (bois, plâtre,
## brique) : chacun devient son propre MultiMesh, avec sa transform relative.
static func _bake(parent: Node3D, packed: PackedScene,
		placements: Array[Transform3D], label: String) -> int:
	if packed == null or placements.is_empty():
		return 0
	var sample: Node3D = packed.instantiate() as Node3D
	if sample == null:
		return 0
	var made: int = 0
	var index: int = 0
	for node: Node in sample.find_children("*", "MeshInstance3D", true, false):
		var source: MeshInstance3D = node as MeshInstance3D
		if source == null or source.mesh == null:
			continue
		var relative: Transform3D = KitPlacement._relative_transform(sample, source)
		var multi: MultiMesh = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = source.mesh
		multi.instance_count = placements.size()
		for i: int in range(placements.size()):
			multi.set_instance_transform(i, placements[i] * relative)
		var holder: MultiMeshInstance3D = MultiMeshInstance3D.new()
		holder.name = "%s_%d" % [label, index]
		holder.multimesh = multi
		if source.material_override != null:
			holder.material_override = source.material_override
		holder.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		parent.add_child(holder)
		made += placements.size()
		index += 1
	sample.queue_free()
	return made


## Habille une salle entière. Renvoie un compte-rendu chiffré : les tests
## s'appuient dessus, et il rend la passe vérifiable au lieu d'être crue.
static func dress(room: Node3D) -> Dictionary:
	var report: Dictionary = {
		"floors": 0, "walls": 0, "pilasters": 0, "lights_shadowed": 0,
		"environment": false, "skipped": "",
	}
	if room == null or not room.is_inside_tree():
		report["skipped"] = "salle hors de l'arbre"
		return report

	# 1. LA LUMIÈRE D'ABORD (AD-008). Sans cela, poser de la brique sombre
	#    sur des murs déjà sombres aggrave ISS-025 au lieu de l'améliorer.
	report["environment"] = _tune_environment(room)
	report["lights_shadowed"] = _tune_lights(room)

	var scenes: Dictionary = {}
	for id: StringName in ([WALL_MODULE, PILASTER_MODULE] as Array[StringName]) + FLOOR_MODULES:
		var packed: PackedScene = AssetRegistry.model(id)
		if packed != null:
			scenes[id] = packed
	if scenes.is_empty():
		report["skipped"] = "kit indisponible"
		return report
	var floor_ids: Array[StringName] = []
	for id: StringName in FLOOR_MODULES:
		if scenes.has(id):
			floor_ids.append(id)

	# 2. On COLLECTE toutes les poses avant d'en fabriquer une seule : les
	#    modules répétés finiront en MultiMesh, pas en centaines de nœuds.
	var batch: Dictionary = {}
	for child: Node in room.get_children():
		if not (child is StaticBody3D) or not _is_shell(child.name):
			continue
		var box: Dictionary = _box_of(child as StaticBody3D)
		if box.is_empty():
			continue
		var size: Vector3 = box["size"] as Vector3
		var centre: Vector3 = box["center"] as Vector3
		var thin: int = 0
		if size.y <= size.x and size.y <= size.z:
			thin = 1
		elif size.z <= size.x and size.z <= size.y:
			thin = 2
		if thin == 1:
			if not floor_ids.is_empty():
				_plan_horizontal(batch, floor_ids, child.name, centre, size, report)
		elif scenes.has(WALL_MODULE):
			_plan_wall(batch, scenes.has(PILASTER_MODULE), centre, size, thin, report)

	# 3. Cuisson : un MultiMesh par maillage de module.
	var dressing: Node3D = Node3D.new()
	dressing.name = "ShellDressing"
	room.add_child(dressing)
	for id: StringName in batch.keys():
		_bake(dressing, scenes[id] as PackedScene,
			batch[id] as Array[Transform3D], String(id))
	return report


## Sol ou plafond : dalles de 2 × 2 m sur la face tournée vers la salle.
static func _plan_horizontal(batch: Dictionary, ids: Array[StringName],
		body_name: String, centre: Vector3, size: Vector3,
		report: Dictionary) -> void:
	var is_ceiling: bool = body_name.begins_with("Ceiling") \
		or body_name.ends_with("Ceiling")
	var y: float = centre.y - size.y * 0.5 - 0.012 if is_ceiling \
		else centre.y + size.y * 0.5 + 0.012
	var cols: int = int(floor(size.x / TILE))
	var rows: int = int(floor(size.z / TILE))
	if cols <= 0 or rows <= 0:
		return
	var x0: float = centre.x - float(cols) * TILE * 0.5 + TILE * 0.5
	var z0: float = centre.z - float(rows) * TILE * 0.5 + TILE * 0.5
	var placed: int = 0
	for i: int in range(cols):
		for j: int in range(rows):
			# Damier de deux dalles + quart de tour : sans cela, 130 dalles
			# identiques alignées produisent une grille qui saute aux yeux.
			var id: StringName = ids[(i + j) % ids.size()]
			var yaw: float = PI * 0.5 * float((i * 3 + j) % 4)
			# La dalle est symétrique en Y : la retourner ne déplaçait rien et
			# ne faisait qu'inverser le sens des triangles — plafonds noirs.
			var tilt: Vector3 = Vector3.ONE
			_push(batch, id, Vector3(x0 + float(i) * TILE, y,
				z0 + float(j) * TILE), yaw, tilt)
			placed += 1
	report["floors"] = (report["floors"] as int) + placed


## Mur : deux rangs de briques sur la face intérieure, plus des pilastres.
static func _plan_wall(batch: Dictionary, with_pilaster: bool, centre: Vector3,
		size: Vector3, thin: int, report: Dictionary) -> void:
	# La face intérieure est celle tournée vers le centre de la salle.
	var normal: Vector3 = Vector3.ZERO
	var span: float = 0.0
	var along: Vector3 = Vector3.ZERO
	if thin == 0:
		var sx: float = -signf(centre.x) if not is_zero_approx(centre.x) else 1.0
		normal = Vector3(sx, 0, 0)
		span = size.z
		along = Vector3(0, 0, 1)
	else:
		var sz: float = -signf(centre.z) if not is_zero_approx(centre.z) else 1.0
		normal = Vector3(0, 0, sz)
		span = size.x
		along = Vector3(1, 0, 0)
	var half: float = (size.x if thin == 0 else size.z) * 0.5
	var face: Vector3 = centre + normal * (half + 0.02)
	var foot: float = centre.y - size.y * 0.5
	var yaw: float = atan2(normal.x, normal.z)

	# La portée est carrelée EN ENTIER : `floor()` laissait un bout de mur nu
	# quand la longueur n'était pas un multiple de 2 m. On répartit et on
	# étire très légèrement chaque panneau au lieu de tronquer.
	var count: int = maxi(1, int(round(span / WALL_W)))
	var step: float = span / float(count)
	var start: float = -span * 0.5 + step * 0.5
	var placed: int = 0
	for row: int in range(WALL_ROWS):
		var y: float = foot + float(row) * WALL_H
		if y + WALL_H > centre.y + size.y * 0.5 + 0.6:
			break
		for i: int in range(count):
			var at: Vector3 = face + along * (start + float(i) * step)
			at.y = y
			_push(batch, WALL_MODULE, at, yaw,
				Vector3(step / WALL_W, 1.0, 1.0))
			placed += 1
	report["walls"] = (report["walls"] as int) + placed

	if not with_pilaster:
		return
	var every: int = maxi(1, int(round(PILASTER_EVERY / step)))
	var pilasters: int = 0
	for i: int in range(count):
		if i % every != 0:
			continue
		var at: Vector3 = face + along * (start + float(i) * step) \
			+ normal * 0.16
		at.y = foot
		_push(batch, PILASTER_MODULE, at, yaw, Vector3(1.5, 2.0, 1.5))
		pilasters += 1
	report["pilasters"] = (report["pilasters"] as int) + pilasters


## Environnement de salle : la bible §12.1 veut « aucun couloir noir ».
## On remonte le plancher lumineux et on rend la matière lisible AVANT
## d'ajouter de la brique — c'est l'ordre imposé par AD-008.
static func _tune_environment(room: Node3D) -> bool:
	for child: Node in room.get_children():
		if not (child is WorldEnvironment):
			continue
		var env: Environment = (child as WorldEnvironment).environment
		if env == null:
			continue
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_white = 6.0
		# Plancher lumineux ambre très bas : les creux cessent d'être noirs
		# sans que la salle devienne grise.
		if env.ambient_light_energy < 0.22:
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.ambient_light_color = Color(0.34, 0.27, 0.20)
			env.ambient_light_energy = 0.26
		# Le cyan des circuits est la seule couleur saturée du donjon : le
		# glow le fait exister au lieu de le laisser plat (§12.1).
		env.glow_enabled = true
		env.glow_intensity = 0.5
		env.glow_bloom = 0.05
		env.glow_hdr_threshold = 1.05
		env.ssao_enabled = true
		env.ssao_radius = 1.4
		env.ssao_intensity = 1.5
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.06
		env.adjustment_saturation = 1.04
		return true
	return false


## Ombres portées : sans elles, une colonne ne pose rien au sol et la salle
## reste plate. On les réserve aux sources qui structurent réellement l'espace
## (l'ombre d'une omni est chère) et on les cadre pour ne pas ronger la lumière.
static func _tune_lights(room: Node3D) -> int:
	var lights: Array[OmniLight3D] = []
	for node: Node in room.find_children("*", "OmniLight3D", true, false):
		lights.append(node as OmniLight3D)
	lights.sort_custom(func(a: OmniLight3D, b: OmniLight3D) -> bool:
		return a.light_energy * a.omni_range > b.light_energy * b.omni_range)
	var lit: int = 0
	for light: OmniLight3D in lights:
		if lit >= 4:
			break
		if light.light_energy < 0.6:
			continue
		light.shadow_enabled = true
		light.shadow_bias = 0.06
		light.shadow_normal_bias = 1.4
		light.distance_fade_enabled = false
		lit += 1
	return lit
