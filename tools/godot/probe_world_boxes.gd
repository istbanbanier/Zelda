## SONDE DE BOÎTES ENGLOBANTES — mesurer au lieu de juger à l'œil.
##
## La leçon de la passe d'orientation : une correction posée « parce que ça
## semblait mieux » s'est révélée sur le mauvais axe ; seul le relevé de
## sommets a tranché. Cette sonde monte la vallée réelle, puis rend la boîte
## englobante MONDE de toute pièce dont le nom correspond à un motif, et
## signale celles qui FLOTTENT — dessous à plus de `--float` mètres du sol
## trouvé par rayon vertical sous leur centre.
##
##   godot --headless --path . --script tools/godot/probe_world_boxes.gd -- \
##     --match=Crate --region=-60,-30,60,60 --float=0.4
##
## Options :
##   --match=A,B    motifs de nom (sous-chaîne, sans casse) ; défaut : tout
##   --region=x0,z0,x1,z1  n'examine que ce rectangle monde
##   --float=M      seuil de flottement en mètres (défaut 0.35)
##   --limit=N      nombre maximal de lignes (défaut 120)
##   --sweep        MODE BALAYAGE : n'imprime que les flottantes, les plus
##                  hautes d'abord, et ajoute un décompte par zone
##   --exempt=A,B   motifs exemptés (voir ci-dessous)
##
## ---------------------------------------------------------------------------
## MODE BALAYAGE — pourquoi il a fallu l'ajouter
##
## Les trois défauts de la passe « arcade / caisse claire / arche » ont tous été
## trouvés À LA MAIN, secteur par secteur. La sonde pouvait les trouver seule,
## mais pas sous cette forme : elle imprime CHAQUE pièce et coupe à `--limit`.
## Sur la vallée entière, les quelques flottantes réelles seraient noyées dans
## des centaines de lignes correctes, ou tronquées avant d'apparaître — le
## compteur les voyait, la sortie non.
##
##   godot --headless --path . --script tools/godot/probe_world_boxes.gd -- \
##     --sweep --float=0.3
##
## ---------------------------------------------------------------------------
## CE QUE LA SONDE NE PEUT PAS DÉCIDER
##
## Un écart au sol n'est pas un défaut : il faut savoir si la pièce est CENSÉE
## reposer sur le sol. Une nappe d'eau, un tablier de pont, une toiture, une
## lanterne accrochée, un pont magnétique en lévitation flottent tous
## légitimement. La sonde produit donc des CANDIDATS, pas un verdict — comme
## `test_roofs_are_supported.gd`, qui exempte les toitures tombées au sol après
## les avoir vues, jamais avant.
##
## `--exempt` reste donc VIDE par défaut, et toute entrée qu'on y ajoutera devra
## porter sa raison en commentaire ici. On n'exempte pas ce qu'on n'a pas
## regardé : c'est ainsi qu'un vrai défaut se fait taire pour toujours.
extends SceneTree

const WORLD: String = "res://scenes/world/valley/ValleyWorld.tscn"


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var patterns: PackedStringArray = PackedStringArray()
	var region: Rect2 = Rect2(-1e6, -1e6, 2e6, 2e6)
	var float_threshold: float = 0.35
	var limit: int = 120
	var sweep: bool = false
	var exempt: PackedStringArray = PackedStringArray()
	for arg: String in args:
		if arg.begins_with("--match="):
			patterns = arg.substr(8).to_lower().split(",", false)
		elif arg.begins_with("--region="):
			var v: PackedStringArray = arg.substr(9).split(",", false)
			if v.size() == 4:
				region = Rect2(float(v[0]), float(v[1]),
					float(v[2]) - float(v[0]), float(v[3]) - float(v[1]))
		elif arg.begins_with("--float="):
			float_threshold = float(arg.substr(8))
		elif arg.begins_with("--limit="):
			limit = int(arg.substr(8))
		elif arg.begins_with("--exempt="):
			exempt = arg.substr(9).to_lower().split(",", false)
		elif arg == "--sweep":
			sweep = true

	var scene: PackedScene = load(WORLD) as PackedScene
	var world: Node = scene.instantiate()
	root.add_child(world)
	await process_frame
	await physics_frame
	await physics_frame
	var space: PhysicsDirectSpaceState3D = \
		(world as Node3D).get_world_3d().direct_space_state

	print("=== BOÎTES MONDE  motifs=%s  région=%s  seuil=%.2f%s ==="
		% [", ".join(patterns), region, float_threshold,
			"  MODE BALAYAGE" if sweep else ""])
	var shown: int = 0
	var floaters: int = 0
	var exempted: int = 0
	# En balayage on collecte d'abord : trier par écart décroissant n'a de sens
	# qu'une fois tout mesuré, et c'est le tri qui rend la sortie exploitable.
	var rows: Array[Dictionary] = []
	for node: Node in root.find_children("*", "Node3D", true, false):
		var spatial: Node3D = node as Node3D
		if spatial == null or not spatial.is_inside_tree():
			continue
		if not _matches(spatial.name, patterns):
			continue
		# ISS-018, la leçon la plus chère du projet : la boîte englobante d'un
		# maillage SKINNÉ décrit sa pose de LIAISON, pas ce que le moteur
		# dessine. Les créatures s'affichaient en pièces détachées alors que
		# tous les tests étaient verts, parce qu'ils mesuraient ces boîtes-là.
		# Ici, le premier balayage remontait des dizaines de « flottantes » du
		# type `Skeleton3D/RaiderRed_Hard` — du bruit pur, mesuré sur une pose
		# qui n'est pas affichée. La sonde ne peut rien en dire : elle passe.
		if _is_skinned_part(spatial):
			continue
		var box: AABB = _world_box(spatial)
		if box.size == Vector3.ZERO:
			continue
		var centre: Vector3 = box.get_center()
		if not region.has_point(Vector2(centre.x, centre.z)):
			continue
		# Une pièce d'un sous-arbre déjà listé (`Model/X`, `X/Mesh`) a la même
		# boîte que son parent : on ne la répète pas.
		if _same_box_as_parent(spatial, box):
			continue
		# Sol sous le centre. Le rayon part LÉGÈREMENT AU-DESSUS du dessous de
		# la boîte : partir en dessous le ferait démarrer À L'INTÉRIEUR de la
		# dalle porteuse, qu'il traverserait alors sans la voir — c'est ce qui
		# a fait passer les caisses du camp (posées sur la terrasse à y = 6)
		# pour des flottantes de 4 m au premier essai.
		var ground: float = NAN
		var query: PhysicsRayQueryParameters3D = \
			PhysicsRayQueryParameters3D.create(
				Vector3(centre.x, box.position.y + 0.40, centre.z),
				Vector3(centre.x, box.position.y - 80.0, centre.z), 1)
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			ground = (hit["position"] as Vector3).y
		var gap: float = (box.position.y - ground) if not is_nan(ground) else NAN
		var is_floater: bool = not is_nan(gap) and gap > float_threshold
		# `_matches` retourne VRAI sur une liste vide : c'est la bonne sémantique
		# pour `--match` (pas de filtre = tout passe), et exactement l'inverse de
		# celle qu'il faut ici. Réutilisé tel quel au premier jet, il a exempté
		# les 704 pièces du premier balayage — soit un rapport parfaitement vide
		# et parfaitement faux. Une liste d'exemption vide n'exempte RIEN.
		var is_exempt: bool = is_floater and not exempt.is_empty() \
			and _matches(spatial.name, exempt)
		if is_floater and not is_exempt:
			floaters += 1
		elif is_exempt:
			exempted += 1

		if sweep:
			if is_floater and not is_exempt:
				rows.append({
					"path": _path_tail(spatial), "zone": _zone_of(spatial),
					"gap": gap, "ground": ground, "box": box,
				})
			continue

		var flag: String = ""
		if is_floater:
			flag = "  <<< FLOTTE de %.2f m%s" % [gap, "  (exempté)" if is_exempt else ""]
		if shown < limit:
			print("  %-42s  x %7.2f..%7.2f  y %7.2f..%7.2f  z %7.2f..%7.2f  sol %s%s"
				% [_path_tail(spatial), box.position.x, box.end.x,
					box.position.y, box.end.y, box.position.z, box.end.z,
					("%.2f" % ground) if not is_nan(ground) else "aucun", flag])
			shown += 1

	if sweep:
		rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a["gap"]) > float(b["gap"]))
		var by_zone: Dictionary = {}
		for row: Dictionary in rows:
			var zone: String = String(row["zone"])
			by_zone[zone] = int(by_zone.get(zone, 0)) + 1
		print("--- %d CANDIDATE(S), la plus haute d'abord ---" % rows.size())
		for row: Dictionary in rows:
			if shown >= limit:
				print("  ... %d de plus (relancer avec --limit)" % (rows.size() - shown))
				break
			var box: AABB = row["box"] as AABB
			print("  %6.2f m  %-42s  [%s]  y %7.2f..%7.2f  sol %7.2f"
				% [float(row["gap"]), String(row["path"]), String(row["zone"]),
					box.position.y, box.end.y, float(row["ground"])])
			shown += 1
		print("--- par zone ---")
		var zones: Array = by_zone.keys()
		zones.sort()
		for zone: String in zones:
			print("  %-28s %d" % [zone, int(by_zone[zone])])
		print("--- %d exemptée(s) par --exempt ---" % exempted)
		print("RAPPEL : ce sont des CANDIDATES. Un écart au sol n'est un défaut "
			+ "que si la pièce est CENSÉE reposer dessus.")
	else:
		print("--- %d pièce(s) listée(s), %d flottante(s), %d exemptée(s) ---"
			% [shown, floaters, exempted])
	quit(0)


## Vrai si la pièce appartient à un squelette : sa boîte est celle de la pose
## de liaison, donc sans rapport avec ce qui est dessiné (ISS-018). On remonte
## la chaîne plutôt que de tester `skin`, parce que le maillage peut être un
## petit-enfant du `Skeleton3D` et non son enfant direct.
func _is_skinned_part(node: Node3D) -> bool:
	var current: Node = node
	while current != null and current != root:
		if current is Skeleton3D:
			return true
		current = current.get_parent()
	return false


## Zone de dressage porteuse, pour le décompte du balayage. À défaut, le
## premier ancêtre sous la racine du monde — assez pour regrouper.
func _zone_of(node: Node3D) -> String:
	var current: Node = node
	var last_named: String = String(node.name)
	while current != null and current != root:
		var name_text: String = String(current.name)
		if name_text.begins_with("DressZone"):
			return name_text
		if current.get_parent() != null and current.get_parent() != root:
			last_named = name_text
		current = current.get_parent()
	return last_named


func _matches(node_name: StringName, patterns: PackedStringArray) -> bool:
	if patterns.is_empty():
		return true
	var lower: String = String(node_name).to_lower()
	for pattern: String in patterns:
		if lower.contains(pattern):
			return true
	return false


## Boîte englobante MONDE, réunion de toutes les géométries du sous-arbre.
func _world_box(root_node: Node3D) -> AABB:
	var merged: AABB = AABB()
	var first: bool = true
	for node: Node in root_node.find_children("*", "VisualInstance3D", true, false):
		var visual: VisualInstance3D = node as VisualInstance3D
		if visual == null or not visual.is_inside_tree():
			continue
		if visual is MeshInstance3D and (visual as MeshInstance3D).mesh == null:
			continue
		var box: AABB = visual.global_transform * visual.get_aabb()
		if first:
			merged = box
			first = false
		else:
			merged = merged.merge(box)
	if root_node is VisualInstance3D:
		var self_visual: VisualInstance3D = root_node as VisualInstance3D
		var ok: bool = not (self_visual is MeshInstance3D) \
			or (self_visual as MeshInstance3D).mesh != null
		if ok:
			var own: AABB = self_visual.global_transform * self_visual.get_aabb()
			merged = own if first else merged.merge(own)
	return merged


func _same_box_as_parent(node: Node3D, box: AABB) -> bool:
	var parent: Node3D = node.get_parent() as Node3D
	if parent == null or not parent.is_inside_tree():
		return false
	var up: AABB = _world_box(parent)
	if up.size == Vector3.ZERO:
		return false
	return up.position.distance_to(box.position) < 0.01 \
		and up.size.distance_to(box.size) < 0.01


func _path_tail(node: Node3D) -> String:
	var parent: Node = node.get_parent()
	if parent == null:
		return String(node.name)
	return "%s/%s" % [parent.name, node.name]
