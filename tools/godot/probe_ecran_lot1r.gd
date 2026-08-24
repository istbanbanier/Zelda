## SONDE D'IDENTIFICATION ÉCRAN — « quel nœud occupe ce rectangle de pixels ? »
##
## Outil de session (lot 1.R, voie B). Il ne remplace pas la méthode qui tranche
## vraiment (repeindre d'une couleur impossible, `tools/CLAUDE.md`) : il la
## PRÉCÈDE, en réduisant les suspects de deux mille nœuds à trois.
##
## POURQUOI IL NE SE SERT PAS DE `unproject_position` : en exécution `--script`
## la viewport n'a pas le rapport d'aspect de la capture, et l'axe Y ment
## (`tools/CLAUDE.md`, ISS-037 — deux itérations perdues sur un mauvais nœud).
## La projection est donc refaite ICI, à partir des seuls paramètres du plan de
## capture (from / look / fov vertical / taille), qui sont connus et écrits.
##
## Il énumère par `GeometryInstance3D` — la végétation V2.2 est en
## `MultiMeshInstance3D`, et une sonde qui ne collecte que des `MeshInstance3D`
## la déclare absente EN SILENCE (même source). L'AABB d'un MultiMesh sous
## renderer headless est toujours (0,0,0) : les instances sont donc lues
## côté CPU, une par une.
##
## Usage :
##   tools/lancer_godot.sh --path . --script tools/godot/probe_ecran_lot1r.gd \
##     -- --from=-154.5,27.7,40.5 --look=-160,27.2,40 --fov=65 \
##        --rect=905,510,1085,580 --rect=790,365,840,385
extends SceneTree

const WORLD: String = "res://scenes/world_v2/WorldV2.tscn"

var _from: Vector3 = Vector3.ZERO
var _look: Vector3 = Vector3.FORWARD
var _fov: float = 65.0
var _largeur: int = 1280
var _hauteur: int = 720
var _rects: Array[Rect2i] = []


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--from="):
			_from = _vec(arg.trim_prefix("--from="))
		elif arg.begins_with("--look="):
			_look = _vec(arg.trim_prefix("--look="))
		elif arg.begins_with("--fov="):
			_fov = arg.trim_prefix("--fov=").to_float()
		elif arg.begins_with("--size="):
			var p: PackedStringArray = arg.trim_prefix("--size=").split("x")
			if p.size() == 2:
				_largeur = p[0].to_int()
				_hauteur = p[1].to_int()
		elif arg.begins_with("--rect="):
			var r: PackedStringArray = arg.trim_prefix("--rect=").split(",")
			if r.size() == 4:
				_rects.append(Rect2i(r[0].to_int(), r[1].to_int(),
					r[2].to_int() - r[0].to_int(),
					r[3].to_int() - r[1].to_int()))
	var world: Node3D = (load(WORLD) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	for i: int in range(30):
		await process_frame
	print("[ecran] from=%s look=%s fov=%.1f %dx%d — %d rect(s)"
		% [_from, _look, _fov, _largeur, _hauteur, _rects.size()])
	var vue: Transform3D = Transform3D().looking_at(_look - _from, Vector3.UP)
	vue.origin = _from
	var inverse: Transform3D = vue.affine_inverse()
	var tan_demi: float = tan(deg_to_rad(_fov) * 0.5)
	var aspect: float = float(_largeur) / float(_hauteur)

	var trouves: Array[Array] = []
	for noeud: Node in root.find_children("*", "GeometryInstance3D", true, false):
		var gi: GeometryInstance3D = noeud as GeometryInstance3D
		if not gi.visible or not gi.is_visible_in_tree():
			continue
		for boite: AABB in _boites_monde(gi):
			var ecran: Rect2i = _projeter(boite, inverse, tan_demi, aspect)
			if ecran.size.x < 0:
				continue
			for r: Rect2i in _rects:
				if ecran.intersects(r):
					trouves.append([gi.global_position.distance_to(_from),
						String(gi.get_path()), boite, ecran, r])
					break
	trouves.sort_custom(func(a: Array, b: Array) -> bool:
		return float(a[0]) < float(b[0]))
	for t: Array in trouves:
		print("[ecran] %6.1f m  ecran=%s  aabb_pos=%s taille=%s\n          %s"
			% [t[0], t[3], (t[2] as AABB).position, (t[2] as AABB).size, t[1]])
	print("[ecran] %d occupant(s)" % trouves.size())
	quit(0)


## Les AABB MONDE d'une instance : une seule pour un maillage ordinaire, une
## par instance pour un MultiMesh (dont l'AABB agrégée est nulle en headless).
func _boites_monde(gi: GeometryInstance3D) -> Array[AABB]:
	var sortie: Array[AABB] = []
	var mm: MultiMeshInstance3D = gi as MultiMeshInstance3D
	if mm != null and mm.multimesh != null and mm.multimesh.mesh != null:
		var locale: AABB = mm.multimesh.mesh.get_aabb()
		var n: int = mini(mm.multimesh.instance_count, 4096)
		for i: int in range(n):
			var t: Transform3D = mm.global_transform \
				* mm.multimesh.get_instance_transform(i)
			sortie.append(t * locale)
		return sortie
	var mi: MeshInstance3D = gi as MeshInstance3D
	if mi != null and mi.mesh != null:
		sortie.append(mi.global_transform * mi.mesh.get_aabb())
	return sortie


## Emprise pixel de l'AABB. Rend une taille négative si tout est derrière la
## caméra — un point derrière l'œil projette une position PLAUSIBLE et fausse,
## c'est le piège classique de ce calcul.
func _projeter(boite: AABB, inverse: Transform3D, tan_demi: float,
		aspect: float) -> Rect2i:
	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF
	var devant: int = 0
	for i: int in range(8):
		var coin: Vector3 = inverse * boite.get_endpoint(i)
		if coin.z >= -0.05:
			continue
		devant += 1
		var ndc_x: float = (coin.x / -coin.z) / (tan_demi * aspect)
		var ndc_y: float = (coin.y / -coin.z) / tan_demi
		var px: float = (ndc_x * 0.5 + 0.5) * float(_largeur)
		var py: float = (0.5 - ndc_y * 0.5) * float(_hauteur)
		min_x = minf(min_x, px)
		max_x = maxf(max_x, px)
		min_y = minf(min_y, py)
		max_y = maxf(max_y, py)
	if devant == 0:
		return Rect2i(0, 0, -1, -1)
	return Rect2i(int(min_x), int(min_y),
		int(max_x - min_x) + 1, int(max_y - min_y) + 1)


func _vec(texte: String) -> Vector3:
	var p: PackedStringArray = texte.split(",")
	if p.size() != 3:
		return Vector3.ZERO
	return Vector3(p[0].to_float(), p[1].to_float(), p[2].to_float())
