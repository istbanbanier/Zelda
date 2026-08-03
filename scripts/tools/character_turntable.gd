## Planche d'INSPECTION d'un personnage, sous cinq angles (ISS-018).
##
## L'alignement du bestiaire montre les cinq familles de face, à 25 m : il
## répond à « les silhouettes se distinguent-elles ? », pas à « ce corps
## tient-il debout ? ». Une pièce détachée sur le flanc ou dans le dos y
## reste invisible — c'est exactement ainsi qu'ISS-018 a survécu à une
## capture.
##
## Cette scène présente UN personnage vu de face, de trois quarts, de
## profil, de dos et en aplat noir, à distance de lecture. Le personnage se
## choisit en ligne de commande :
##
##     --script tools/godot/capture_reference.gd -- \
##         --scene=res://scenes/tests/CharacterTurntable.tscn \
##         --out=… --creature=colosse
##
## Les identifiants disponibles sont les clés de `SUBJECTS`.
class_name CharacterTurntable
extends Node3D

## id -> [scène, nom affiché, espacement en mètres, hauteur de caméra]
const SUBJECTS: Dictionary = {
	"braise": ["res://scenes/enemies/RaiderRed.tscn", "Pillard braise", 1.5, 1.0],
	"azur": ["res://scenes/enemies/RaiderBlue.tscn", "Pillard azur", 1.6, 1.1],
	"briseur": ["res://scenes/enemies/RaiderBlack.tscn",
		"Briseur d'obsidienne", 1.9, 1.2],
	"colosse": ["res://scenes/enemies/RavineTroll.tscn",
		"Colosse des ravins", 3.6, 2.2],
	"chasseur": ["res://scenes/enemies/CentaurHunter.tscn",
		"Chasseur quadrupède", 4.6, 1.9],
	"gardien": ["res://scenes/boss/StormGuardian.tscn",
		"Gardien de l'Orage", 9.5, 3.2],
}

## Face, trois quarts, profil, dos — puis la même silhouette en aplat noir,
## où une pièce détachée ne peut plus se cacher derrière une couleur.
const ANGLES: Array[Array] = [
	[0.0, "face"],
	[45.0, "trois quarts"],
	[90.0, "profil"],
	[180.0, "dos"],
	[35.0, "aplat"],
]

var mounted_views: int = 0
var subject_id: String = "colosse"


func _ready() -> void:
	subject_id = _requested_subject()
	var entry: Array = SUBJECTS[subject_id] as Array
	var spacing: float = float(entry[2])
	var span: float = spacing * float(ANGLES.size() - 1)
	_build_stage(span, float(entry[3]), spacing)
	var packed: PackedScene = load(String(entry[0])) as PackedScene
	if packed == null:
		push_warning("[tourne] scène absente : %s" % String(entry[0]))
		return
	for i: int in range(ANGLES.size()):
		var view: Node3D = packed.instantiate() as Node3D
		view.name = "View_%d" % i
		view.position = Vector3((float(i) - float(ANGLES.size() - 1) * 0.5)
			* spacing, 0, 0)
		add_child(view)
		# Planche d'inspection : aucune IA ne tourne, aucune physique ne
		# déplace le sujet pendant la capture.
		view.set_physics_process(false)
		var pivot: Node3D = view.get_node_or_null("Pivot") as Node3D
		if pivot != null:
			pivot.rotation_degrees.y = float(ANGLES[i][0])
		if String(ANGLES[i][1]) == "aplat":
			_flatten(view)
		mounted_views += 1
		_label(String(ANGLES[i][1]), view.position, float(entry[3]))
	_label(String(entry[1]), Vector3.ZERO, float(entry[3]) * 2.0 + 0.6)


func _requested_subject() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--creature="):
			var wanted: String = arg.trim_prefix("--creature=")
			if SUBJECTS.has(wanted):
				return wanted
			push_warning("[tourne] sujet inconnu : %s" % wanted)
	return subject_id


func _label(text: String, at: Vector3, height: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = 26
	label.modulate = Color(0.15, 0.13, 0.1)
	label.position = at + Vector3(0, height * 1.9 + 0.4, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


func _build_stage(span: float, subject_height: float,
		spacing: float) -> void:
	var backdrop: MeshInstance3D = MeshInstance3D.new()
	backdrop.name = "Backdrop"
	var backdrop_mesh: QuadMesh = QuadMesh.new()
	backdrop_mesh.size = Vector2(span + 8.0, subject_height * 4.0 + 4.0)
	var backdrop_material: StandardMaterial3D = StandardMaterial3D.new()
	backdrop_material.albedo_color = Color(0.80, 0.81, 0.82)
	backdrop_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	backdrop_mesh.material = backdrop_material
	backdrop.mesh = backdrop_mesh
	backdrop.position = Vector3(0, subject_height * 1.4, -6.0)
	add_child(backdrop)

	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	floor_mesh.name = "Floor"
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(span + 8.0, 14)
	var floor_material: StandardMaterial3D = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.52, 0.53, 0.51)
	plane.material = floor_material
	floor_mesh.mesh = plane
	add_child(floor_mesh)

	# Deux sources : une clé chaude et un contre-jour froid. Une seule
	# lumière frontale aplatit les volumes et masque justement les jours
	# entre deux pièces.
	var key: DirectionalLight3D = DirectionalLight3D.new()
	key.name = "Key"
	key.rotation_degrees = Vector3(-34, 28, 0)
	key.light_energy = 1.25
	key.light_color = Color(1.0, 0.94, 0.84)
	add_child(key)
	var rim: DirectionalLight3D = DirectionalLight3D.new()
	rim.name = "Rim"
	rim.rotation_degrees = Vector3(-16, -132, 0)
	rim.light_energy = 0.55
	rim.light_color = Color(0.72, 0.80, 0.95)
	rim.shadow_enabled = false
	add_child(rim)

	var camera: Camera3D = Camera3D.new()
	camera.name = "TurntableCamera"
	# Recul calculé pour que les cinq vues tiennent dans le cadre quelle que
	# soit la taille du sujet : demi-portée / tan(champ horizontal / 2).
	var fov: float = 45.0
	# La marge doit valoir l'ENCOMBREMENT d'un sujet, pas trois mètres fixes :
	# vu de profil, le Gardien occupe ses 9,4 m de long, et les vues des deux
	# bords sortaient du cadre. L'espacement est déjà proportionnel au sujet,
	# on s'en sert comme mesure de son encombrement.
	var half_width: float = span * 0.5 + spacing * 0.80
	var aspect: float = 16.0 / 9.0
	var horizontal: float = 2.0 * atan(tan(deg_to_rad(fov) * 0.5) * aspect)
	camera.position = Vector3(0, subject_height * 1.25,
		half_width / tan(horizontal * 0.5) + 2.0)
	camera.fov = fov
	camera.current = true
	add_child(camera)


## Aplat noir par surcharge de NŒUD : elle prime sur les matériaux de
## surface sans les toucher.
func _flatten(subject: Node3D) -> void:
	var black: StandardMaterial3D = StandardMaterial3D.new()
	black.albedo_color = Color.BLACK
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for node: Node in subject.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh.visible:
			mesh.material_override = black
