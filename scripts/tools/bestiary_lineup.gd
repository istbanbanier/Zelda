## Alignement du BESTIAIRE (D-EN.6, MASTER_SPEC §12, §7.18) — les cinq
## familles côte à côte À LA MÊME ÉCHELLE, en matière ou en APLATS NOIRS
## (BESTIARY_FLAT=1). C'est la scène où se juge l'exigence « cinq
## familles réellement distinctes » : si deux silhouettes se confondent
## en aplat, la différence n'est pas assez profonde.
##
## Les ennemis sont montés SANS IA active (physique coupée) : c'est une
## planche de silhouettes, pas un combat.
class_name BestiaryLineup
extends Node3D

const FAMILIES: Array[Array] = [
	["res://scenes/enemies/RaiderRed.tscn", "Pillard braise"],
	["res://scenes/enemies/RaiderBlue.tscn", "Pillard azur"],
	["res://scenes/enemies/RaiderBlack.tscn", "Briseur d'obsidienne"],
	["res://scenes/enemies/RavineTroll.tscn", "Colosse des ravins"],
	["res://scenes/enemies/CentaurHunter.tscn", "Chasseur quadrupède"],
]
## Espacement suffisant pour la carrure du colosse (2,2 m) et la
## longueur du chasseur (3,0 m), assez serré pour que les cinq
## remplissent le cadre de la planche.
const SPACING: float = 3.7

var mounted_families: int = 0


func _ready() -> void:
	var flat: bool = OS.get_environment("BESTIARY_FLAT") == "1"
	_build_stage(flat)
	for i: int in range(FAMILIES.size()):
		var packed: PackedScene = load(String(FAMILIES[i][0])) as PackedScene
		if packed == null:
			push_warning("[bestiaire] scène absente : %s" % String(FAMILIES[i][0]))
			continue
		var enemy: Node3D = packed.instantiate() as Node3D
		enemy.name = "Family_%d" % i
		enemy.position = Vector3(
			(float(i) - float(FAMILIES.size() - 1) * 0.5) * SPACING, 0, 0)
		add_child(enemy)
		mounted_families += 1
		# Planche de silhouettes : aucune IA ne tourne ici.
		enemy.set_physics_process(false)
		if flat:
			_flatten(enemy)
		else:
			var label: Label3D = Label3D.new()
			label.text = String(FAMILIES[i][1])
			label.font_size = 28
			label.modulate = Color(0.15, 0.13, 0.1)
			label.position = enemy.position + Vector3(0, 4.9, 0)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			add_child(label)


func _build_stage(flat: bool) -> void:
	var backdrop: MeshInstance3D = MeshInstance3D.new()
	backdrop.name = "Backdrop"
	var backdrop_mesh: QuadMesh = QuadMesh.new()
	backdrop_mesh.size = Vector2(26, 11)
	var backdrop_material: StandardMaterial3D = StandardMaterial3D.new()
	backdrop_material.albedo_color = Color(0.94, 0.93, 0.90) if flat \
		else Color(0.72, 0.74, 0.76)
	backdrop_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	backdrop_mesh.material = backdrop_material
	backdrop.mesh = backdrop_mesh
	backdrop.position = Vector3(0, 3.4, -4.0)
	add_child(backdrop)
	if not flat:
		var floor_mesh: MeshInstance3D = MeshInstance3D.new()
		floor_mesh.name = "Floor"
		var plane: PlaneMesh = PlaneMesh.new()
		plane.size = Vector2(26, 12)
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
	camera.name = "BestiaryCamera"
	# Cadrage mesuré : 5 familles espacées de 3,7 m (span ~18 m avec les
	# carrures) — à 14,5 m et 46° de champ vertical, la vue couvre ~22 m,
	# le chasseur n'est plus coupé au bord.
	camera.position = Vector3(0, 2.2, 14.5)
	camera.rotation_degrees = Vector3(-2.0, 0, 0)
	camera.fov = 46.0
	camera.current = true
	add_child(camera)


## Aplat noir par surcharge de NŒUD : elle prime sur les matériaux de
## surface sans les toucher.
func _flatten(enemy: Node3D) -> void:
	var black: StandardMaterial3D = StandardMaterial3D.new()
	black.albedo_color = Color.BLACK
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for node: Node in enemy.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_override = black
