## Bâtisseur des SIX FENÊTRES DE COMPOSITION V2.1 — caméras déterministes.
##
## Six caméras nommées sous `CaptureCameras`, chacune posée au-dessus du sol
## réel et orientée vers sa cible contractuelle (masterplan §6). À ce stade
## elles ne prouvent que des RELATIONS SPATIALES : ligne de vue, caméra hors
## sol, aucun mur contre l'objectif — jamais une qualité artistique.
## Les mêmes noms servent aux tests et aux captures.
class_name WorldV2CamerasBuilder
extends RefCounted

const EYE_HEIGHT: float = 2.4
const CAMERA_FOV: float = 60.0

## nom → [x, z, cible (x, y, z), ce que la fenêtre prouve]
const WINDOWS: Array[Array] = [
	["cam01_spawn_vista", 0.8, 153.4, Vector3(0, 26, -210),
		"spawn → citadelle/camp/rivière (la North Star)"],
	["cam02_camp_pylone", 36.0, 76.0, Vector3(115, 20, -25),
		"camp → pylône (anticipation du repère suivant)"],
	["cam03_pylone_marche", 112.0, -14.0, Vector3(0, 22, -160),
		"pylône → steppe/rampe (le chemin restant se lit)"],
	# À la LÈVRE du premier ressaut (la paroi tombe vers 110–117) : depuis
	# -132, 15 m en retrait sur le plateau, le rayon de visée rasait le sol
	# et butait à 2 m — mesuré par le test des fenêtres.
	["cam04_falaise_cuvette", -118.0, 64.0, Vector3(10, 6, 92),
		"sommet de falaise → cuvette sud (regard de retour)"],
	["cam05_belvedere_crete", 166.0, 54.0, Vector3(0, 26, 170),
		"belvédère oriental → crête de départ (regard de retour)"],
	# Au BORD du plateau : depuis -192, la lèvre sud (y=34) rasait le rayon de
	# visée — mesuré au calcul des lignes de vue, corrigé avant construction.
	["cam06_plateau_vallee", 0.0, -168.0, Vector3(0, 6, 60),
		"plateau du donjon → vallée entière (récompense spatiale)"],
]

var _heightmap: WorldV2Heightmap = null


func _init(heightmap: WorldV2Heightmap) -> void:
	_heightmap = heightmap


func build(parent: Node3D) -> void:
	for window: Array in WINDOWS:
		var camera: Camera3D = Camera3D.new()
		camera.name = String(window[0])
		camera.fov = CAMERA_FOV
		camera.far = 1600.0
		camera.current = false
		camera.add_to_group(&"world_v2_capture_cameras")
		camera.set_meta(&"proves", String(window[4]))
		camera.set_meta(&"target", window[3] as Vector3)
		var x: float = float(window[1])
		var z: float = float(window[2])
		camera.position = Vector3(x, _heightmap.height_at(x, z) + EYE_HEIGHT, z)
		parent.add_child(camera)
		# `look_at` exige d'être dans l'arbre — après add_child.
		camera.look_at(window[3] as Vector3, Vector3.UP)
