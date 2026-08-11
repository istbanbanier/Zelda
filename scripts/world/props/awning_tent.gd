## AUVENT DE CAMP — asset livré, plus un repli graybox.
##
## POURQUOI IL EXISTE. `AssetRegistry` réservait `prop.tent` depuis ART-Q0 avec
## la mention « ABSENT des sept packs » ; l'audit du 2026-08-11 l'a relevé comme
## défaut P0 : « `prop.tent` et `prop.campfire` pointent vers des scènes
## absentes », donc « le camp ne peut pas franchir son gate lieu habité ». En
## attendant, la terrasse posait trois `PrismMesh` — des tentes en cône, c'est
## à dire exactement la forme que `VISUAL_ASSET_BIBLE` §10.2 interdit :
## « Aucun tipi ou camp fantasy générique copié : utiliser des auvents
## asymétriques à trois points et des paravents tressés. »
##
## CE QUE C'EST. Un auvent en appentis, monté sur TROIS appuis de hauteurs
## différentes — deux devant (l'un plus haut que l'autre), un derrière. La
## toile descend en biais, le bord bas frôle le sol, deux haubans partent vers
## des piquets. Rien n'est symétrique : ni les mâts, ni la toile, ni les
## haubans. C'est la règle de §2.2 pour le camp, et c'est aussi ce qui
## distingue une construction bricolée d'un objet de catalogue.
##
## COLLISION. Le corps qui porte cet auvent lui demande son enveloppe par
## `collision_points()` : la coque convexe de la toile et des pieds, pas une
## boîte. La leçon vient de la revue V4 sur les tentes en prisme — une boîte de
## 3,6 x 2,4 x 3,2 sur un volume en coin imposait 1,36 m de mur invisible de
## chaque côté à hauteur de tête.
##
## AUCUN ASSET EXTERNE : géométrie construite ici, matériaux de la palette
## §3.4. Rien à attribuer, rien à télécharger.
class_name AwningTent
extends Node3D

## Cotes de l'auvent, en mètres. Réglées pour tenir dans l'emprise qu'occupaient
## les prismes remplacés (3,8 x 2,6 x 3,4) : la composition du camp, ses
## passages et son triangle fonctionnel ne bougent pas.
const FRONT_TALL: float = 2.45
const FRONT_SHORT: float = 2.05
const BACK_POST: float = 1.15
const WIDTH: float = 3.4
const DEPTH: float = 3.0
const POST_RADIUS: float = 0.075

## Toile : ocre chaud usé, jamais saturé. §1.4 « toile terre/rouge sourd ».
const COL_CANVAS: Color = Color(0.455, 0.238, 0.170)
const COL_CANVAS_UNDER: Color = Color(0.300, 0.168, 0.126)
const COL_WOOD: Color = Color(0.352, 0.216, 0.135)
const COL_ROPE: Color = Color(0.470, 0.408, 0.290)

## Sommets de l'enveloppe, en repère LOCAL. Calculés une fois dans `_ready()`.
var _hull: PackedVector3Array = PackedVector3Array()


func _ready() -> void:
	_build()


## Enveloppe convexe pour le corps porteur. Appelée AVANT ou APRÈS `_ready()`
## indifféremment : elle construit à la demande si besoin.
func collision_points() -> PackedVector3Array:
	if _hull.is_empty():
		_compute_hull()
	return _hull


func _compute_hull() -> void:
	var half_w: float = WIDTH * 0.5
	var front_z: float = DEPTH * 0.5
	var back_z: float = -DEPTH * 0.5
	# Toile : deux arêtes hautes de hauteurs différentes devant, une arête
	# basse derrière. Plus les quatre pieds au sol.
	_hull = PackedVector3Array([
		Vector3(-half_w, FRONT_TALL, front_z),
		Vector3(half_w, FRONT_SHORT, front_z),
		Vector3(-half_w * 0.82, BACK_POST, back_z),
		Vector3(half_w * 0.82, BACK_POST * 0.92, back_z),
		Vector3(-half_w, 0.0, front_z),
		Vector3(half_w, 0.0, front_z),
		Vector3(-half_w * 0.82, 0.0, back_z),
		Vector3(half_w * 0.82, 0.0, back_z),
	])


func _build() -> void:
	_compute_hull()
	var half_w: float = WIDTH * 0.5
	var front_z: float = DEPTH * 0.5
	var back_z: float = -DEPTH * 0.5
	# --- Toile ---------------------------------------------------------
	# Un quadrilatère GAUCHE (les quatre coins ne sont pas coplanaires,
	# puisque les deux mâts avant n'ont pas la même hauteur) : c'est
	# précisément ce qui donne à l'auvent son pli et sa lecture « tendu à la
	# main ». Deux triangles, doublés en sens inverse pour la face intérieure.
	var canvas: SurfaceTool = SurfaceTool.new()
	canvas.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a: Vector3 = Vector3(-half_w, FRONT_TALL, front_z)
	var b: Vector3 = Vector3(half_w, FRONT_SHORT, front_z)
	var c: Vector3 = Vector3(half_w * 0.82, BACK_POST * 0.92, back_z)
	var d: Vector3 = Vector3(-half_w * 0.82, BACK_POST, back_z)
	for triangle: Array in [[a, b, c], [a, c, d]]:
		for point: Vector3 in triangle:
			canvas.add_vertex(point)
	canvas.generate_normals()
	var canvas_mesh: MeshInstance3D = MeshInstance3D.new()
	canvas_mesh.name = "AwningCanvas"
	canvas.index()
	canvas_mesh.mesh = canvas.commit()
	var canvas_material: StandardMaterial3D = StandardMaterial3D.new()
	canvas_material.albedo_color = COL_CANVAS
	canvas_material.roughness = 0.92
	# Toile vue des DEUX faces : sans cela, l'intérieur de l'auvent est un
	# trou noir dès que la caméra passe dessous.
	canvas_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	canvas_mesh.material_override = canvas_material
	add_child(canvas_mesh)
	# Doublure plus sombre, décalée de 3 cm sous la toile : l'épaisseur se lit
	# en valeur, pas en géométrie.
	var lining: MeshInstance3D = MeshInstance3D.new()
	lining.name = "AwningLining"
	lining.mesh = canvas_mesh.mesh
	var lining_material: StandardMaterial3D = StandardMaterial3D.new()
	lining_material.albedo_color = COL_CANVAS_UNDER
	lining_material.roughness = 0.95
	lining_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	lining.material_override = lining_material
	lining.position = Vector3(0.0, -0.035, 0.0)
	add_child(lining)
	# --- Trois appuis ---------------------------------------------------
	var posts: Array[Array] = [
		["PostFrontTall", Vector3(-half_w, 0.0, front_z), FRONT_TALL, 0.06],
		["PostFrontShort", Vector3(half_w, 0.0, front_z), FRONT_SHORT, -0.05],
		["PostBack", Vector3(half_w * 0.82, 0.0, back_z), BACK_POST * 0.92, 0.09],
	]
	for post: Array in posts:
		var height: float = post[2]
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = String(post[0])
		var cylinder: CylinderMesh = CylinderMesh.new()
		cylinder.top_radius = POST_RADIUS * 0.8
		cylinder.bottom_radius = POST_RADIUS
		cylinder.height = height
		cylinder.radial_segments = 6
		mesh.mesh = cylinder
		mesh.material_override = _wood()
		mesh.position = (post[1] as Vector3) + Vector3(0.0, height * 0.5, 0.0)
		# Aucun mât parfaitement vertical : c'est un camp, pas une charpente.
		mesh.rotation.z = float(post[3])
		add_child(mesh)
	# --- Haubans --------------------------------------------------------
	var ropes: Array[Array] = [
		["GuyRopeWest", Vector3(-half_w, FRONT_TALL, front_z),
			Vector3(-half_w - 1.15, 0.02, front_z + 0.75)],
		["GuyRopeEast", Vector3(half_w, FRONT_SHORT, front_z),
			Vector3(half_w + 0.95, 0.02, front_z + 0.55)],
	]
	for rope: Array in ropes:
		var from: Vector3 = rope[1]
		var to: Vector3 = rope[2]
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = String(rope[0])
		var cylinder: CylinderMesh = CylinderMesh.new()
		cylinder.top_radius = 0.022
		cylinder.bottom_radius = 0.022
		cylinder.height = from.distance_to(to)
		cylinder.radial_segments = 4
		mesh.mesh = cylinder
		mesh.material_override = _flat(COL_ROPE)
		mesh.position = (from + to) * 0.5
		# `CylinderMesh` pousse selon +Y : on l'aligne sur la corde.
		var direction: Vector3 = (to - from).normalized()
		var axis: Vector3 = Vector3.UP.cross(direction)
		if axis.length_squared() > 0.0001:
			mesh.rotate(axis.normalized(), Vector3.UP.angle_to(direction))
		add_child(mesh)
		var peg: MeshInstance3D = MeshInstance3D.new()
		peg.name = String(rope[0]) + "Peg"
		var peg_mesh: CylinderMesh = CylinderMesh.new()
		peg_mesh.top_radius = 0.045
		peg_mesh.bottom_radius = 0.03
		peg_mesh.height = 0.34
		peg_mesh.radial_segments = 5
		peg.mesh = peg_mesh
		peg.material_override = _wood()
		peg.position = to + Vector3(0.0, 0.10, 0.0)
		peg.rotation.x = 0.34
		add_child(peg)
	# --- Tapis de sol ----------------------------------------------------
	var mat_mesh: MeshInstance3D = MeshInstance3D.new()
	mat_mesh.name = "GroundMat"
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(WIDTH * 0.78, DEPTH * 0.72)
	mat_mesh.mesh = plane
	mat_mesh.material_override = _flat(Color(0.286, 0.214, 0.158))
	mat_mesh.position = Vector3(0.0, 0.02, -0.15)
	mat_mesh.rotation.y = 0.12
	mat_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mat_mesh)


func _wood() -> StandardMaterial3D:
	return _flat(COL_WOOD)


func _flat(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.93
	return material
