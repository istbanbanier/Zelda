## SONDE des emplacements de récompense.
##
## Le problème que cet outil résout : choisir 31 positions à la main, dans neuf
## fichiers, revient à écrire 31 hypothèses. La première tentative l'a prouvé —
## des coffres « plausibles » posés au centre du volume, dont plusieurs dans un
## mur. Une position n'est pas une opinion : elle se mesure.
##
## Ce script monte la vallée réelle, puis, autour de chaque lieu, éprouve
## physiquement une couronne de candidats :
##
##  1. un rayon vertical doit toucher un sol à portée raisonnable ;
##  2. une capsule au gabarit du joueur doit tenir debout au point de station ;
##  3. le sol ne doit pas être une pente absurde entre le lieu et le candidat.
##
## Il imprime, pour chaque lieu, le meilleur candidat exprimé dans le repère du
## LIEU — donc directement collable dans le fichier du bâtisseur.
##
##   godot --headless --path . --script tools/godot/probe_reward_anchors.gd
extends SceneTree

const BODY_RADIUS: float = 0.35
const BODY_HEIGHT: float = 1.7
const PROBE_UP: float = 3.0
const MAX_DROP: float = 1.2
## Rayons essayés autour du centre du lieu, du plus proche au plus lointain :
## une récompense doit rester DANS son lieu.
const RADII: Array[float] = [0.0, 1.4, 2.0, 3.0, 4.0, 5.0, 6.5, 8.0, 10.0]
const ANGLES: int = 16
## Écart de cote toléré entre le centre du lieu et le sol trouvé. Sans lui, le
## rayon vertical d'une grotte traverserait la voûte et proposerait un ancrage
## SUR la colline — sol réel, dégagement réel, et lieu manqué.
const SAME_LEVEL: float = 3.0
## Distance supplémentaire du point d'approche, au-delà du candidat.
const APPROACH_EXTRA: float = 3.0

## Corps des récompenses déjà posées, exclus de toutes les sondes.
var _excluded: Array[RID] = []


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/world/valley/ValleyWorld.tscn") \
		as PackedScene
	if packed == null:
		push_error("[sonde] ValleyWorld introuvable")
		quit(2)
		return
	var world: Node3D = packed.instantiate() as Node3D
	root.add_child(world)
	await _settle(20)

	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	# Les récompenses DÉJÀ posées sont exclues des sondes. Sans cela, la sonde
	# rencontre le couvercle du coffre qu'elle a elle-même fait poser au tour
	# précédent, le prend pour le sol, et propose un ancrage 70 cm plus haut —
	# une dérive qui monterait d'un cran à chaque exécution.
	_excluded.clear()
	for node: Node in world.find_children("*", "RewardAnchor", true, false):
		_excluded.append_array((node as RewardAnchor).own_bodies())
	var found: int = 0
	var missing: Array[String] = []
	print("=== SONDE DES ANCRAGES ===")
	for node: Node in world.find_children("*", "PointOfInterest", true, false):
		var poi: PointOfInterest = node as PointOfInterest
		if String(poi.poi_id).is_empty():
			continue
		var host: Node3D = poi.get_parent() as Node3D
		if host == null:
			continue
		# Le CENTRE horizontal vient du volume du lieu, la COTE de la racine du
		# lieu. Prendre la cote du volume mènerait à chercher un sol à hauteur
		# de poitrine, voire à trois mètres au-dessus du sol pour un lieu dont
		# le volume englobe une tour : la sonde ne trouvait alors rien, non
		# parce que le lieu flottait, mais parce qu'elle regardait trop haut.
		var center: Vector3 = Vector3(poi.global_position.x,
			host.global_position.y, poi.global_position.z)
		var result: Dictionary = _search(space, center)
		if result.is_empty():
			missing.append(String(poi.poi_id))
			print("%-44s AUCUN emplacement sain trouvé" % String(poi.poi_id))
			continue
		found += 1
		var at: Vector3 = host.to_local(result["at"] as Vector3)
		var approach: Vector3 = host.to_local(result["approach"] as Vector3)
		print("%-44s at=(%.2f, %.2f, %.2f)  approche=(%.2f, %.2f, %.2f)  hote=%s"
			% [String(poi.poi_id), at.x, at.y, at.z,
				approach.x, approach.y, approach.z, host.name])
	print("=== %d emplacement(s) trouvé(s), %d sans solution ==="
		% [found, missing.size()])
	quit(0 if missing.is_empty() else 1)


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await physics_frame


## Cherche autour de `center` un point qui porte une récompense ET devant
## lequel le joueur tient debout. Le premier rayon qui donne satisfaction
## gagne : une récompense doit être PRÈS du lieu qui la promet.
func _search(space: PhysicsDirectSpaceState3D, center: Vector3) -> Dictionary:
	for radius: float in RADII:
		for i: int in range(ANGLES):
			var angle: float = TAU * float(i) / float(ANGLES)
			var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
			var at: Vector3 = _ground(space, center + offset * radius)
			if at == Vector3.INF or absf(at.y - center.y) > SAME_LEVEL:
				continue
			var stand: Vector3 = _ground(space,
				center + offset * (radius + 1.2))
			if stand == Vector3.INF or absf(stand.y - center.y) > SAME_LEVEL:
				continue
			if absf(stand.y - at.y) > 0.9:
				continue   # marche trop haute entre la station et l'objet
			if not _clear(space, stand):
				continue
			# COULOIR : le point d'arrivée peut être dégagé et le chemin pour
			# y venir muré. Trois jalons entre l'approche et la station l'ont
			# montré — deux ancrages passaient la sonde et échouaient à
			# l'audit, le corps butant à 2,6 m.
			if not _corridor(space, center + offset * (radius + APPROACH_EXTRA),
					center + offset * (radius + 1.2)):
				continue
			# COHÉRENCE AVEC L'AUDIT : l'audit sonde depuis `ancrage + 1,2 m`,
			# la recherche depuis `centre + 1,2 m`. Un surplomb situé entre les
			# deux — un rocher bas d'un territoire — reste invisible ici et
			# fait conclure à l'audit que la récompense est enterrée sous lui.
			# On rejoue donc la sonde depuis la cote du candidat.
			var confirm: Vector3 = _ground(space, at)
			if confirm == Vector3.INF or absf(confirm.y - at.y) > 0.15:
				continue
			var approach: Vector3 = _ground(space,
				center + offset * (radius + APPROACH_EXTRA))
			if approach == Vector3.INF:
				approach = stand
			return {"at": at, "approach": approach}
	return {}


## Cote du sol sous `at`, ou INF si le rayon ne touche rien d'utile.
func _ground(space: PhysicsDirectSpaceState3D, at: Vector3) -> Vector3:
	# Le départ reste BAS : partir très haut ferait traverser la voûte d'une
	# grotte et rapporterait le dessus de la colline comme « sol ».
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		at + Vector3(0, 1.2, 0), at + Vector3(0, -PROBE_UP * 2.0, 0))
	query.collide_with_areas = false
	query.exclude = _excluded
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return Vector3.INF
	return hit["position"] as Vector3


## Le trajet `from` → `to` est-il franchissable debout ? Quatre jalons, chacun
## reposé sur son propre sol : une capsule flottante ne prouverait rien.
func _corridor(space: PhysicsDirectSpaceState3D, from: Vector3,
		to: Vector3) -> bool:
	for i: int in range(4):
		var t: float = float(i) / 3.0
		var at: Vector3 = from.lerp(to, t)
		var ground: Vector3 = _ground(space, at)
		if ground == Vector3.INF or not _clear(space, ground):
			return false
	return true


func _clear(space: PhysicsDirectSpaceState3D, ground: Vector3) -> bool:
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = BODY_RADIUS
	shape.height = BODY_HEIGHT
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY,
		ground + Vector3(0, BODY_HEIGHT * 0.5 + 0.06, 0))
	query.collide_with_areas = false
	query.exclude = _excluded
	return space.intersect_shape(query, 1).is_empty()
