## Lot 3 — dolly de stabilité temporelle (§30.1 : « vidéo 10-20 s avec
## marche, sprint et rotation caméra », jamais produite — manque nommé
## par l'éval sévère v5, domaine mouvement 2/10).
##
## Cette scène monte le HeroShotLab et déplace SA caméra le long d'une
## timeline fixe de 15 s : marche (0-6 s, 3,5 m/s), sprint (6-10 s,
## 9 m/s), puis balayage de rotation (10-15 s, ±35°). Elle est faite
## pour le mode Movie Maker (`--write-movie frames.png --fixed-fps 12`),
## vérifié dans la source 4.7.1 (main.cpp, movie_writer_pngwav.cpp) :
## le pas de temps FIXE échantillonne le vent/TIME correctement quel
## que soit le débit réel de llvmpipe.
##
## HONNÊTETÉ (ISS-002) : la séquence sert au jugement SPATIAL et
## temporel de l'image (pop, cohérence du vent, stabilité du grade
## painterly) — jamais à une mesure de fluidité.
extends Node3D

const LAB_SCENE: String = "res://scenes/lookdev/HeroShotLab.tscn"
const WALK_END: float = 6.0
const SPRINT_END: float = 10.0
const TOTAL: float = 15.0
const WALK_SPEED: float = 3.5
const SPRINT_SPEED: float = 9.0
const YAW_MAX_DEG: float = 35.0
## X du chemin du lab : la caméra s'y glisse pour passer À CÔTÉ du
## héros, pas à travers lui.
const PATH_X: float = 2.2

var _camera: Camera3D = null
var _elapsed: float = 0.0
var _eye_offset: float = 0.0
var _start_x: float = 0.0


func _ready() -> void:
	var lab: HeroShotLab = (load(LAB_SCENE) as PackedScene).instantiate() \
		as HeroShotLab
	add_child(lab)
	_camera = lab.vista_camera()
	if _camera == null:
		push_error("[dolly] caméra du lab introuvable")
		get_tree().quit(1)
		return
	_camera.current = true
	_start_x = _camera.position.x
	# Hauteur d'œil constante AU-DESSUS de la pente continue du lab.
	_eye_offset = _camera.position.y \
		- _camera.position.z * HeroShotLab.SLOPE_TAN


func _process(delta: float) -> void:
	if _camera == null:
		return
	_elapsed += delta
	if _elapsed >= TOTAL:
		get_tree().quit(0)
		return
	var position: Vector3 = _camera.position
	if _elapsed < WALK_END:
		position.z -= WALK_SPEED * delta
		# Glissement latéral vers le chemin pendant les 3 premières
		# secondes (pour contourner le héros).
		var drift: float = clampf(_elapsed / 3.0, 0.0, 1.0)
		position.x = lerpf(_start_x, PATH_X, drift)
	elif _elapsed < SPRINT_END:
		position.z -= SPRINT_SPEED * delta
		position.x = PATH_X
	else:
		# Balayage de rotation : 0 → +35° → 0 → −35° → 0 sur 5 s.
		var u: float = (_elapsed - SPRINT_END) / (TOTAL - SPRINT_END)
		_camera.rotation_degrees.y = YAW_MAX_DEG * sin(u * TAU)
	position.y = position.z * HeroShotLab.SLOPE_TAN + _eye_offset
	_camera.position = position
