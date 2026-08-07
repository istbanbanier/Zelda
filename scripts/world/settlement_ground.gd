## Le SOL des lieux habités — ce qui transforme des bâtiments posés en village.
##
## LE DÉFAUT QU'IL CORRIGE. Les maisons du kit sont bonnes ; leur implantation
## ne l'est pas. Elles sont posées directement sur l'herbe rase, sans place,
## sans chemin, sans seuil : le regard lit « des modèles alignés sur un pré »,
## pas « un endroit où des gens vivent ». C'est le constat de l'audit
## (« poser une empreinte de sol sous chaque implantation ») et celui du
## propriétaire, mot pour mot : « des assets random posés aléatoirement ».
##
## CE QU'UN VILLAGE A, ET QU'UN TAS DE MODÈLES N'A PAS :
##
##  1. une EMPRINTE : la terre est battue là où l'on marche, l'herbe s'arrête
##     au pied des murs ;
##  2. une PLACE : un centre vide, plus clair, vers lequel tout converge ;
##  3. des CHEMINS : chaque porte est reliée à la place, sinon les maisons se
##     tournent le dos ;
##  4. un BORD : la transition vers la nature est marquée — clôtures, souches,
##     tas de bois — au lieu d'une frontière nette ;
##  5. de la VIE : des objets d'usage posés là où l'on travaille.
##
## Cette passe est ADDITIVE. Elle ne déplace aucun bâtiment, n'en supprime
## aucun, ne touche à aucune collision et ne change aucun identifiant
## persistant. Elle ajoute un sol et de la vie autour de ce qui existe déjà :
## si elle échoue, le village reste exactement ce qu'il était.
class_name SettlementGround
extends RefCounted

## Marge autour de l'emprise bâtie : la terre battue déborde des murs.
const APRON_MARGIN: float = 2.2
## Épaisseur de la dalle de sol. Assez fine pour épouser le terrain plat,
## assez épaisse pour ne pas cligner contre lui (z-fighting).
const APRON_THICKNESS: float = 0.12
## Largeur des chemins qui relient les portes à la place.
const PATH_WIDTH: float = 2.6

const COL_EARTH: Color = Color(0.42, 0.31, 0.21)
const COL_SQUARE: Color = Color(0.52, 0.44, 0.33)
const COL_PATH: Color = Color(0.48, 0.37, 0.26)

## Props d'usage, par famille : ce qu'on trouve réellement dans une cour.
const YARD_PROPS: Array[StringName] = [
	&"Barrel", &"Crate_Wooden", &"Prop_Wagon", &"Prop_WoodenFence_Single",
	&"Prop_WoodenFence_Extension1", &"Prop_Support",
]


## Emprise au sol d'un sous-arbre, dans l'espace de `root`.
static func footprint(root: Node3D) -> AABB:
	var merged: AABB = AABB()
	var first: bool = true
	for node: Node in root.find_children("*", "VisualInstance3D", true, false):
		var visual: VisualInstance3D = node as VisualInstance3D
		if visual == null or not visual.is_inside_tree():
			continue
		if visual is MeshInstance3D and (visual as MeshInstance3D).mesh == null:
			continue
		var world: AABB = visual.global_transform * visual.get_aabb()
		if first:
			merged = world
			first = false
		else:
			merged = merged.merge(world)
	return merged


static func _slab(parent: Node3D, slab_name: String, centre: Vector3,
		size: Vector3, color: Color) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = slab_name
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	mesh.material_override = material
	mesh.position = centre
	# Décor pur : aucune collision, le sol réel reste celui du terrain.
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh


## Pose l'empreinte, la place et les chemins d'un lieu habité.
##
## `buildings` : les nœuds bâtis à relier (chacun donne un chemin vers la place).
## Renvoie un compte-rendu chiffré.
static func lay(host: Node3D, group_name: String, buildings: Array[Node3D],
		ground_y: float) -> Dictionary:
	var report: Dictionary = {"apron": false, "paths": 0, "props": 0}
	if host == null or not host.is_inside_tree() or buildings.is_empty():
		return report

	var box: AABB = AABB()
	var first: bool = true
	var doors: Array[Vector3] = []
	for building: Node3D in buildings:
		if building == null or not building.is_inside_tree():
			continue
		var b: AABB = footprint(building)
		if b.size == Vector3.ZERO:
			continue
		doors.append(Vector3(b.get_center().x, ground_y, b.get_center().z))
		if first:
			box = b
			first = false
		else:
			box = box.merge(b)
	if first or doors.size() < 2:
		return report

	var ground: Node3D = Node3D.new()
	ground.name = group_name
	host.add_child(ground)

	var centre: Vector3 = Vector3(box.get_center().x, ground_y, box.get_center().z)
	var span_x: float = box.size.x + APRON_MARGIN * 2.0
	var span_z: float = box.size.z + APRON_MARGIN * 2.0

	# 1. L'EMPREINTE, en plaques IRRÉGULIÈRES. Un seul grand rectangle de
	#    terre sur l'herbe produit exactement le défaut qu'on corrige : une
	#    forme géométrique posée sur un pré. On compose donc la cour de
	#    plusieurs plaques tournées et décalées, qui se recouvrent : le bord
	#    devient irrégulier, comme une terre usée par le passage.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(absf(centre.x) * 131.0 + absf(centre.z) * 17.0) + 7
	var patches: int = 7
	for i: int in range(patches):
		var angle: float = TAU * float(i) / float(patches) + rng.randf() * 0.5
		var reach: float = 0.22 + 0.17 * rng.randf()
		var at: Vector3 = centre + Vector3(cos(angle) * span_x * reach, 0.0,
			sin(angle) * span_z * reach)
		at.y = ground_y + APRON_THICKNESS * 0.5
		var patch: MeshInstance3D = _slab(ground, "Terre%d" % i, at,
			Vector3(span_x * (0.34 + 0.16 * rng.randf()), APRON_THICKNESS,
				span_z * (0.34 + 0.16 * rng.randf())),
			COL_EARTH.lerp(COL_SQUARE, rng.randf() * 0.45))
		patch.rotation.y = rng.randf() * TAU
	report["apron"] = true

	# 2. LA PLACE : un cœur plus clair, vers lequel tout converge. Un village
	#    sans centre n'est qu'un alignement de façades.
	var square: float = minf(span_x, span_z) * 0.30
	var plaza: MeshInstance3D = _slab(ground, "Place",
		centre + Vector3(0, APRON_THICKNESS * 0.9, 0),
		Vector3(square, APRON_THICKNESS * 0.6, square), COL_SQUARE)
	plaza.rotation.y = rng.randf() * TAU

	# 3. LES CHEMINS : de chaque bâtiment vers la place. C'est eux qui disent
	#    que les maisons se regardent au lieu de se tourner le dos.
	for door: Vector3 in doors:
		var to_centre: Vector3 = centre - door
		var length: float = to_centre.length()
		if length < 1.0:
			continue
		var mid: Vector3 = door + to_centre * 0.5
		var path: MeshInstance3D = _slab(ground, "Chemin%d" % report["paths"],
			mid + Vector3(0, APRON_THICKNESS * 0.8, 0),
			Vector3(PATH_WIDTH, APRON_THICKNESS * 0.5, length), COL_PATH)
		path.rotation.y = atan2(to_centre.x, to_centre.z)
		report["paths"] = (report["paths"] as int) + 1

	return report


## Pose des objets d'usage sur le pourtour de la place, de façon déterministe.
## Aucun hasard : une graine fixe, pour que deux exécutions donnent la même
## image et qu'une capture reste une preuve.
static func populate(host: Node3D, group_name: String, centre: Vector3,
		radius: float, count: int, seed_value: int) -> int:
	if host == null or not host.is_inside_tree() or count <= 0:
		return 0
	var yard: Node3D = host.get_node_or_null(NodePath(group_name)) as Node3D
	if yard == null:
		yard = Node3D.new()
		yard.name = group_name
		host.add_child(yard)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var placed: int = 0
	for i: int in range(count):
		var id: StringName = YARD_PROPS[i % YARD_PROPS.size()]
		var packed: PackedScene = AssetRegistry.model(id)
		if packed == null:
			continue
		var node: Node3D = packed.instantiate() as Node3D
		if node == null:
			continue
		# Répartis sur une couronne : le centre de la place reste LIBRE,
		# sinon la « place » devient un entrepôt.
		var angle: float = rng.randf() * TAU
		var distance: float = radius * (0.62 + 0.32 * rng.randf())
		node.position = centre + Vector3(cos(angle) * distance, 0.0,
			sin(angle) * distance)
		node.rotation.y = rng.randf() * TAU
		yard.add_child(node)
		KitPlacement.seat(node, node.scene_file_path)
		placed += 1
	return placed
