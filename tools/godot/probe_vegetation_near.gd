## Sonde : que pose la VÉGÉTATION GELÉE (V2.2) autour d'un point ?
##
## Née d'une question qu'aucune capture ne tranche : le lead a écrit
## « l'arbre noir entouré de fleurs jaunes ». Ces fleurs viennent-elles du
## lieu (que je peux retirer) ou du semis de la prairie (gelé, intouchable) ?
## Répondre à l'œil sur une image, c'est deviner. On compte les instances.
##
## Deux modes.
##
## **Autour d'un point** — le mode d'origine :
##   … -- --center=-92,132 --radius=8
##
## **Contre l'emprise d'un lieu** — celui qu'exige une question
## d'intersection. Compter des instances « à moins de N mètres » ne dit pas
## si une touffe TRAVERSE un plancher : il faut confronter chaque position
## de semis aux emprises réelles des maillages du lieu.
##   … -- --place=valley.poi.riverside_village.01 [--margin=0.35]
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"

## Une pièce de lieu plus grande que ça n'est pas un bâti mais un sol, un
## pavage ou une jupe : une touffe qui la « traverse » pousse simplement à
## côté. On les écarte du verdict d'intersection, en les listant à part.
const EMPRISE_BATI_MAX_M: float = 14.0
## Sous cette hauteur, une pièce est une dalle ou une bordure : pas un
## volume dans lequel une plante peut se retrouver enfermée.
const HAUTEUR_BATI_MIN_M: float = 0.80


func _initialize() -> void:
	var center: Vector2 = Vector2.ZERO
	var radius: float = 8.0
	var place_id: String = ""
	var margin: float = 0.35
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--center="):
			var parts: PackedStringArray = argument.substr(9).split(",")
			center = Vector2(float(parts[0]), float(parts[1]))
		elif argument.begins_with("--radius="):
			radius = float(argument.substr(9))
		elif argument.begins_with("--place="):
			place_id = argument.substr(8)
		elif argument.begins_with("--margin="):
			margin = float(argument.substr(9))
	var world: Node = (load(WORLD) as PackedScene).instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	if not place_id.is_empty():
		_rapport_lieu(world, place_id, margin)
		return

	print("centre=(%.1f, %.1f) rayon=%.1f m" % [center.x, center.y, radius])
	var counts: Dictionary = {}
	_walk(world, center, radius, counts)
	var names: Array = counts.keys()
	names.sort()
	var total: int = 0
	for key: Variant in names:
		var n: int = int(counts[key])
		total += n
		print("  %-44s %d" % [String(key), n])
	var sans_plan: int = int(counts.get(&"__SANS_PLAN__", 0))
	if sans_plan > 0:
		printerr("[vegetation] BLOQUÉ : %d cellule(s) sans méta `instance_origins` — "
			% sans_plan + "le plan de plantation est absent et un compte serait faux")
		quit(3)
		return
	print("TOTAL instances de végétation dans le rayon : %d" % total)
	quit(0)


## MODE LIEU — la question n'est pas « combien », c'est « laquelle traverse
## quoi, et de combien ».
##
## Un compte « dans 8 m » ne répond pas : une touffe à 6 m est dehors, une
## touffe à 0,2 m d'un mur aussi. Ce qui décide, c'est l'appartenance à
## l'emprise d'une pièce BÂTIE. On confronte donc chaque position du semis
## aux AABB monde des maillages du lieu, et on imprime les positions et les
## distances — pas un total.
func _rapport_lieu(world: Node, place_id: String, margin: float) -> void:
	var lieu: Node3D = null
	for noeud: Node in world.get_tree().get_nodes_in_group(&"world_v2_places"):
		if String(noeud.get_meta("place_id", "")) == place_id:
			lieu = noeud as Node3D
			break
	if lieu == null:
		printerr("[vegetation] BLOQUÉ : lieu introuvable — %s" % place_id)
		quit(3)
		return

	# Emprises des pièces, séparées en bâti et en sol/pavage.
	var batis: Array[Dictionary] = []
	var emprise: AABB = AABB()
	var premier: bool = true
	for noeud: Node in lieu.find_children("*", "GeometryInstance3D", true, false):
		var gi: GeometryInstance3D = noeud as GeometryInstance3D
		var boite: AABB = gi.global_transform * gi.get_aabb()
		if premier:
			emprise = boite
			premier = false
		else:
			emprise = emprise.merge(boite)
		var large: bool = maxf(boite.size.x, boite.size.z) > EMPRISE_BATI_MAX_M
		if not large and boite.size.y >= HAUTEUR_BATI_MIN_M:
			batis.append({"nom": gi.name, "boite": boite})
	if premier:
		printerr("[vegetation] BLOQUÉ : le lieu ne porte aucun maillage")
		quit(3)
		return

	# Positions du semis GELÉ, lues dans la méta du plan de plantation.
	var plants: Array[Dictionary] = []
	var sans_plan: int = 0
	sans_plan = _collecter_plan(world, plants)
	if sans_plan > 0:
		printerr("[vegetation] BLOQUÉ : %d cellule(s) sans méta `instance_origins`"
			% sans_plan)
		quit(3)
		return

	print("[vegetation] lieu %s" % place_id)
	print("  emprise monde : x [%.1f ; %.1f]  z [%.1f ; %.1f]  y [%.1f ; %.1f]"
		% [emprise.position.x, emprise.end.x, emprise.position.z, emprise.end.z,
			emprise.position.y, emprise.end.y])
	print("  pièces bâties retenues : %d (emprise ≤ %.0f m, hauteur ≥ %.2f m)"
		% [batis.size(), EMPRISE_BATI_MAX_M, HAUTEUR_BATI_MIN_M])
	print("  instances de semis gelé dans le monde : %d" % plants.size())

	var dans_emprise: Array[Dictionary] = []
	var elargie: AABB = emprise.grow(margin)
	for plante: Dictionary in plants:
		var p: Vector3 = plante["p"]
		if p.x >= elargie.position.x and p.x <= elargie.end.x \
				and p.z >= elargie.position.z and p.z <= elargie.end.z:
			dans_emprise.append(plante)
	print("  instances dans l'emprise du lieu (marge %.2f m) : %d"
		% [margin, dans_emprise.size()])

	var fautes: Array[String] = []
	for plante: Dictionary in dans_emprise:
		var p: Vector3 = plante["p"]
		for bati: Dictionary in batis:
			var b: AABB = bati["boite"]
			if p.x < b.position.x - margin or p.x > b.end.x + margin:
				continue
			if p.z < b.position.z - margin or p.z > b.end.z + margin:
				continue
			# Une plante n'est « dans » le bâti que si son pied est sous son
			# arase : au-dessus, elle pousse sur un toit qui n'existe pas ;
			# au-dessous, elle est enterrée et invisible.
			if p.y < b.position.y - 0.05 or p.y > b.end.y:
				continue
			fautes.append("    %-30s (%.2f ; %.2f ; %.2f) DANS %s [x %.2f–%.2f, z %.2f–%.2f, y %.2f–%.2f]"
				% [plante["cellule"], p.x, p.y, p.z, bati["nom"],
					b.position.x, b.end.x, b.position.z, b.end.z,
					b.position.y, b.end.y])

	print("")
	if fautes.is_empty():
		print("  AUCUNE INTERSECTION : aucune instance de semis gelé ne tombe "
			+ "dans l'emprise d'une pièce bâtie.")
	else:
		print("  %d INTERSECTION(S) :" % fautes.size())
		for ligne: String in fautes:
			print(ligne)

	# Distance de la plante la plus proche à chaque pièce bâtie : c'est ce
	# qui dit si la marge tient, ou si elle tient par chance.
	print("")
	print("  distance de la plante la plus proche, par pièce bâtie :")
	var lignes: Array[String] = []
	for bati: Dictionary in batis:
		var b: AABB = bati["boite"]
		var mini: float = INF
		for plante: Dictionary in dans_emprise:
			var p: Vector3 = plante["p"]
			var dx: float = maxf(maxf(b.position.x - p.x, p.x - b.end.x), 0.0)
			var dz: float = maxf(maxf(b.position.z - p.z, p.z - b.end.z), 0.0)
			mini = minf(mini, sqrt(dx * dx + dz * dz))
		lignes.append("    %-30s %s" % [bati["nom"],
			"aucune plante dans l'emprise" if is_inf(mini) else "%.2f m" % mini])
	lignes.sort()
	for ligne: String in lignes:
		print(ligne)
	quit(1 if not fautes.is_empty() else 0)


func _collecter_plan(node: Node, plants: Array[Dictionary]) -> int:
	var sans_plan: int = 0
	var multi: MultiMeshInstance3D = node as MultiMeshInstance3D
	if multi != null and multi.multimesh != null:
		if not multi.has_meta(&"instance_origins"):
			sans_plan += 1
		else:
			var origines: PackedVector3Array = multi.get_meta(&"instance_origins")
			var vers_monde: Transform3D = multi.global_transform
			for point_local: Vector3 in origines:
				plants.append({"p": vers_monde * point_local, "cellule": multi.name})
	for child: Node in node.get_children():
		sans_plan += _collecter_plan(child, plants)
	return sans_plan


## LA SONDE LISAIT LE MAUVAIS CÔTÉ, et rendait des comptes faux avec aplomb.
##
## Signalé par l'agent grotte le 2026-08-14 : ses 21 instances « proches »
## remontaient toutes au même point, (−112,0 ; 16,0). Vérifié ici par un
## balayage de rayon, qui est le test qui tranche :
##
##   rayon  3 m -> 0 instance
##   rayon  6 m -> 0 instance
##   rayon 12 m -> 180 instances
##
## Une marche d'escalier, pas une croissance. C'est la signature du défaut :
## la cellule entière bascule d'un coup quand l'origine de son nœud passe
## sous le rayon (elle est à 10,2 m du centre sondé). Un compte « dans 8 m »
## ne mesurait donc que la distance à un point unique.
##
## La cause était DÉJÀ écrite dans `world_v2_vegetation_builder.gd` §
## matérialisation : en mode headless `--script`, le renderer DUMMY jette
## les données d'instance de MultiMesh — `_multimesh_instance_set_transform`
## est un no-op et le `get` rend l'IDENTITÉ. Le bâtisseur écrit pour cette
## raison son PLAN DE PLANTATION en méta `instance_origins`, depuis les
## mêmes valeurs et dans la même boucle que l'écriture moteur.
##
## On lit donc la méta. Et s'il n'y en a pas, on sort en BLOQUÉ (3) plutôt
## que de compter des identités : une sonde qui ne peut pas mesurer doit le
## DIRE, jamais rendre 0 (`tools/CLAUDE.md`).
func _walk(node: Node, center: Vector2, radius: float, counts: Dictionary) -> void:
	var multi: MultiMeshInstance3D = node as MultiMeshInstance3D
	if multi != null and multi.multimesh != null:
		if not multi.has_meta(&"instance_origins"):
			counts[&"__SANS_PLAN__"] = int(counts.get(&"__SANS_PLAN__", 0)) + 1
		else:
			var origines: PackedVector3Array = multi.get_meta(&"instance_origins")
			var vers_monde: Transform3D = multi.global_transform
			for point_local: Vector3 in origines:
				var point: Vector3 = vers_monde * point_local
				if Vector2(point.x, point.z).distance_to(center) <= radius:
					var key: String = multi.name
					counts[key] = int(counts.get(key, 0)) + 1
	for child: Node in node.get_children():
		_walk(child, center, radius, counts)
