## Bibliothèque de silhouettes (§7.18, bible §30.3) : les personnages de
## production côte à côte, en matière ou en APLATS NOIRS
## (SILHOUETTE_FLAT=1) — « reconnaître sa silhouette en aplats noir » se
## juge sur cette scène, à la capture, pas sur une intention.
##
## Phase H : SEPT sujets au lieu de quatre. La scène ne pouvait pas servir
## au test d'affordance de §30.3 — « les cinq familles à 10, 25 et 50 m ;
## le boss à 15, 25 et 40 m » — tant que le colosse, le chasseur et le
## Gardien en étaient absents. L'écart de taille est désormais réel : 1,42 m
## pour le pillard braise, 5,60 m pour le Gardien, et c'est précisément ce
## que la capture doit montrer.
class_name SilhouetteLineup
extends Node3D

## Sujet, nom affiché, largeur qu'il occupe sur la ligne. Les créatures
## lourdes prennent plus de place : les aligner à pas constant les faisait
## se chevaucher, ce qui rendait le test de silhouette illisible.
const CHARACTERS: Array[Array] = [
	[&"char.hero", "Héros", 1.8],
	[&"char.raider_red", "Pillard braise", 1.8],
	[&"char.raider_blue", "Pillard azur", 1.8],
	[&"char.raider_black", "Briseur d'obsidienne", 2.2],
	[&"char.ravine_troll", "Colosse des ravins", 4.6],
	[&"char.centaur_hunter", "Chasseur quadrupède", 2.6],
	[&"char.boss_guardian", "Gardien de l'Orage", 6.4],
]
const SPACING: float = 1.7

## Compteurs publics : le test mesure, il ne suppose pas.
var mounted_characters: int = 0


func _ready() -> void:
	var flat: bool = OS.get_environment("SILHOUETTE_FLAT") == "1"
	_build_stage(flat)
	# Chaque sujet prend SA largeur : le curseur avance de la demi-largeur
	# du précédent plus la demi-largeur du suivant.
	var total: float = 0.0
	for entry: Array in CHARACTERS:
		total += float(entry[2])
	var cursor: float = -total * 0.5
	for i: int in range(CHARACTERS.size()):
		var slot: float = float(CHARACTERS[i][2])
		var centre: float = cursor + slot * 0.5
		cursor += slot
		var packed: PackedScene = AssetRegistry.resolve(
			CHARACTERS[i][0] as StringName)
		if packed == null:
			push_warning("[lineup] absent : %s" % String(CHARACTERS[i][0]))
			continue
		var visual: Node3D = packed.instantiate() as Node3D
		visual.name = "Character_%d" % i
		visual.position = Vector3(centre, 0, 0)
		# Face du modèle = +Z (convention ART-Q1), caméra en +Z : de face
		# sans rotation. Le dos du héros, lui, se juge sur la vista.
		add_child(visual)
		mounted_characters += 1
		if flat:
			_flatten(visual)
		else:
			var label: Label3D = Label3D.new()
			label.text = String(CHARACTERS[i][1])
			label.font_size = 40
			label.modulate = Color(0.15, 0.13, 0.1)
			label.position = visual.position + Vector3(0, 6.4, 0)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			add_child(label)


func _build_stage(flat: bool) -> void:
	var backdrop: MeshInstance3D = MeshInstance3D.new()
	backdrop.name = "Backdrop"
	var backdrop_mesh: QuadMesh = QuadMesh.new()
	backdrop_mesh.size = Vector2(30, 14)
	var backdrop_material: StandardMaterial3D = StandardMaterial3D.new()
	backdrop_material.albedo_color = Color(0.94, 0.93, 0.90) if flat \
		else Color(0.72, 0.74, 0.76)
	backdrop_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	backdrop_mesh.material = backdrop_material
	backdrop.mesh = backdrop_mesh
	backdrop.position = Vector3(0, 5.0, -4.5)
	add_child(backdrop)
	if not flat:
		var floor_mesh: MeshInstance3D = MeshInstance3D.new()
		floor_mesh.name = "Floor"
		var plane: PlaneMesh = PlaneMesh.new()
		plane.size = Vector2(30, 10)
		var floor_material: StandardMaterial3D = StandardMaterial3D.new()
		floor_material.albedo_color = Color(0.5, 0.52, 0.5)
		plane.material = floor_material
		floor_mesh.mesh = plane
		add_child(floor_mesh)
		var sun: DirectionalLight3D = DirectionalLight3D.new()
		sun.name = "Sun"
		sun.rotation_degrees = Vector3(-38, 32, 0)
		sun.light_energy = 1.2
		add_child(sun)
	var camera: Camera3D = Camera3D.new()
	camera.name = "LineupCamera"
	# Reculée et relevée pour tenir la ligne entière — du pillard braise
	# (1,42 m) au Gardien (5,60 m) — sans couper personne.
	camera.position = Vector3(0, 3.1, 17.5)
	camera.rotation_degrees = Vector3(-3.5, 0, 0)
	camera.fov = 48.0
	camera.current = true
	add_child(camera)


## Aplat noir : surcharge de NŒUD (material_override), qui prime sur les
## matériaux de surface sans les toucher — le nettoyage EXIT_TREE des
## surcharges de SURFACE du modèle n'est pas concerné.
func _flatten(visual: Node3D) -> void:
	var black: StandardMaterial3D = StandardMaterial3D.new()
	black.albedo_color = Color.BLACK
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for node: Node in visual.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_override = black
