## VIDÉO JOUEUR lot 1.R — un parcours RÉEL aux VRAIS contrôles, enregistré
## par le MovieMaker natif de Godot 4 (`--write-movie <f.avi> --fixed-fps 30`).
##
## CE QUE CE SCRIPT S'INTERDIT, et qui rendrait la vidéo mensongère
## (mêmes règles que `tests/playthrough/test_physical_run.gd`) :
##   - écrire `global_position` pour AVANCER (une seule écriture : la mise
##     en place au départ du parcours, suivie de reset_physics_interpolation
##     — c'est un spawn, pas un déplacement) ;
##   - une caméra volante : l'image vient du CameraRig du joueur, piloté
##     par `InputIntent.look_mouse` comme une souris ;
##   - un montage : la vidéo est UNE exécution continue — si le pilote
##     échoue, le script sort en échec et on recommence, on ne coupe pas.
##
## Tout passe par `InputIntent` et le `PlayerController` (D-013) : `move`
## pour marcher, `look_mouse` pour regarder. Le gameplay ne peut pas savoir
## que c'est un pilote.
##
## Usage (via tools/lot1r_video.sh, qui ajoute verrou + xvfb + MovieMaker) :
##   godot --path . --write-movie <out.avi> --fixed-fps 30 \
##     --script tools/godot/lot1r_video.gd -- \
##     --scene=res://scenes/world_v2/WorldV2.tscn \
##     --parcours=<parcours.json> [--budget-s=90]
##
## `parcours.json` :
##   {"place_id": "...", "etapes": [
##      {"pos": [x, z], "regard": [x, y, z], "pause_s": 2.0, "sprint": false,
##       "allure": 0.6},
##      ...]}
##
## `allure` est la NORME de l'intention de déplacement (0-1) : §8.2 fait de
## la norme une vitesse continue (marche ≈ 0,55-0,65, course = 1,0). Le
## premier enregistrement mesurait 12,8 s de jeu — un pilote qui COURT un
## parcours contemplatif le rend trop court (contrat addendum : 20-40 s).
##
## Codes : 0 = parcours joué en entier · 1 = jalon manqué (vidéo partielle,
## à REJETER) · 3 = BLOQUÉ (pas de MovieMaker, scène/parcours absents).
extends SceneTree

const ARRIVE_M: float = 1.6
const ETAPE_BUDGET_S: float = 25.0
## Vitesse maximale du regard, rad/tick (30 t/s → ~2,6 rad/s : un coup
## d'œil humain, pas un fouet).
const REGARD_PAS_RAD: float = 0.085
const STALL_TRIGGER_S: float = 1.2
const SIDESTEP_S: float = 0.9
const SIDESTEP_ANGLE: float = 1.15

var _scene_path: String = ""
var _parcours_path: String = ""
var _budget_s: float = 90.0
var _build_frames: int = 45


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--scene="):
			_scene_path = argument.trim_prefix("--scene=")
		elif argument.begins_with("--parcours="):
			_parcours_path = argument.trim_prefix("--parcours=")
		elif argument.begins_with("--budget-s="):
			_budget_s = argument.trim_prefix("--budget-s=").to_float()
		elif argument.begins_with("--build-frames="):
			_build_frames = maxi(1, argument.trim_prefix("--build-frames=").to_int())
	# Sans MovieMaker, tout « réussirait » sans produire une seule image :
	# le vert obtenu en ne faisant rien est le mode de panne le plus
	# dangereux du dépôt. On refuse.
	if not OS.has_feature("movie"):
		printerr("[video] BLOQUÉ : lancé sans --write-movie — aucune image "
			+ "ne serait écrite. Passer par tools/lot1r_video.sh.")
		quit(3)
		return
	if _scene_path.is_empty() or _parcours_path.is_empty():
		printerr("[video] BLOQUÉ : --scene= et --parcours= requis")
		quit(3)
		return
	_run()


func _run() -> void:
	var texte: String = FileAccess.get_file_as_string(_parcours_path)
	if texte.is_empty():
		printerr("[video] BLOQUÉ : parcours illisible — %s" % _parcours_path)
		quit(3)
		return
	var plan: Variant = JSON.parse_string(texte)
	if not (plan is Dictionary) or not ((plan as Dictionary).get("etapes") is Array):
		printerr("[video] BLOQUÉ : parcours sans `etapes` — %s" % _parcours_path)
		quit(3)
		return
	var etapes: Array = (plan as Dictionary)["etapes"] as Array
	if etapes.is_empty():
		printerr("[video] BLOQUÉ : parcours vide")
		quit(3)
		return

	var packed: PackedScene = load(_scene_path) as PackedScene
	if packed == null:
		printerr("[video] BLOQUÉ : scène introuvable — %s" % _scene_path)
		quit(3)
		return
	var monde: Node3D = packed.instantiate() as Node3D
	root.add_child(monde)
	if not monde.is_node_ready():
		await monde.ready
	for i: int in range(_build_frames):
		await process_frame

	var joueur: PlayerController = monde.call("player") as PlayerController
	if joueur == null:
		printerr("[video] BLOQUÉ : la scène ne porte pas de joueur")
		quit(3)
		return
	var intent: InputIntent = InputIntent.new()
	joueur.set_intent_source(intent)

	# Mise en place au DÉPART du parcours — la seule écriture de position.
	var premiere: Dictionary = etapes[0] as Dictionary
	var depart: Vector2 = _pos_de(premiere)
	var sol: float = _sol(monde, depart)
	joueur.global_position = Vector3(depart.x, sol + 0.6, depart.y)
	joueur.reset_physics_interpolation()
	var pose: float = 0.0
	while not joueur.is_on_floor() and pose < 6.0:
		await physics_frame
		pose += root.get_physics_process_delta_time()

	print("[video] parcours %s — %d étape(s), budget %.0f s"
		% [String((plan as Dictionary).get("place_id", "?")), etapes.size(),
			_budget_s])

	var horloge: float = 0.0
	var jouees: int = 0
	for index: int in range(etapes.size()):
		var etape: Dictionary = etapes[index] as Dictionary
		var but: Vector2 = _pos_de(etape)
		var regard: Vector3 = _regard_de(etape)
		var sprint: bool = bool(etape.get("sprint", false))
		var allure: float = clampf(float(etape.get("allure", 0.62)), 0.2, 1.0)
		var restant: float = _budget_s - horloge
		if restant <= 0.0:
			break
		var arrivee: bool = index == 0 or await _marcher(joueur, intent, but,
			regard, sprint, allure, minf(ETAPE_BUDGET_S, restant))
		horloge += _ecoule
		if not arrivee:
			intent.move = Vector2.ZERO
			printerr("[video] ÉCHEC : étape %d non atteinte (%.0f, %.0f) — "
				% [index + 1, but.x, but.y]
				+ "vidéo partielle, à rejeter")
			quit(1)
			return
		jouees += 1
		# Pause contemplative : le regard continue de se poser.
		var pause: float = float(etape.get("pause_s", 0.0))
		var attendu: float = 0.0
		intent.move = Vector2.ZERO
		intent.sprint_held = false
		while attendu < pause and horloge + attendu < _budget_s:
			_orienter(joueur, intent, regard)
			await physics_frame
			attendu += root.get_physics_process_delta_time()
		horloge += attendu
	intent.move = Vector2.ZERO
	print("[video] OK : %d/%d étape(s), %.1f s de jeu" % [jouees, etapes.size(),
		horloge])
	quit(0)


var _ecoule: float = 0.0


## Marche vers `but` en gardant le regard sur `regard`. Même logique de
## contournement que le parcours physique : quand la distance ne baisse
## plus, obliquer et sauter — de la poussée d'intention, jamais une
## écriture de position.
func _marcher(joueur: PlayerController, intent: InputIntent, but: Vector2,
		regard: Vector3, sprint: bool, allure: float, budget_s: float) -> bool:
	_ecoule = 0.0
	var progres: float = INF
	var enlise: float = 0.0
	var oblique: float = 0.0
	var signe: float = 1.0
	while _ecoule <= budget_s:
		var pas: float = root.get_physics_process_delta_time()
		var ici: Vector2 = Vector2(joueur.global_position.x, joueur.global_position.z)
		var vers: Vector2 = but - ici
		if vers.length() <= ARRIVE_M:
			intent.move = Vector2.ZERO
			return true
		if vers.length() < progres - 0.05:
			progres = vers.length()
			enlise = 0.0
		else:
			enlise += pas
		var souhait: Vector2 = vers.normalized()
		if oblique > 0.0:
			oblique -= pas
			souhait = souhait.rotated(SIDESTEP_ANGLE * signe)
		elif enlise > STALL_TRIGGER_S:
			oblique = SIDESTEP_S
			signe = -signe
			enlise = 0.0
			intent.jump_pressed = true
		_orienter(joueur, intent, regard)
		intent.move = _relatif_camera(joueur,
			Vector3(souhait.x, 0.0, souhait.y)) * allure
		intent.sprint_held = sprint
		await physics_frame
		_ecoule += pas
	intent.move = Vector2.ZERO
	return false


## Pousse le regard vers un point MONDE, en pas bornés — une souris, pas
## un snap. `CameraRig.apply_look` : yaw -= mouse.x ; pitch -= mouse.y.
func _orienter(joueur: PlayerController, intent: InputIntent,
		cible: Vector3) -> void:
	var rig: Node = joueur.camera_rig()
	var vers: Vector3 = cible - joueur.global_position
	var plat: Vector2 = Vector2(vers.x, vers.z)
	if plat.length_squared() < 0.01:
		intent.look_mouse = Vector2.ZERO
		return
	var yaw_voulu: float = atan2(-vers.x, -vers.z)
	var yaw: float = float(rig.get("_yaw"))
	var d_yaw: float = wrapf(yaw_voulu - yaw, -PI, PI)
	var pitch_voulu: float = atan2(vers.y - 1.4, plat.length())
	var pitch: float = float(rig.get("_pitch"))
	var d_pitch: float = pitch_voulu - pitch
	intent.look_mouse = Vector2(
		-clampf(d_yaw, -REGARD_PAS_RAD, REGARD_PAS_RAD),
		-clampf(d_pitch, -REGARD_PAS_RAD, REGARD_PAS_RAD))


## Direction MONDE → `InputIntent.move` (repère caméra, §8.2) — recopié du
## parcours physique : sans cette projection le pilote marche à l'envers.
func _relatif_camera(joueur: PlayerController, direction: Vector3) -> Vector2:
	var yaw_basis: Basis = joueur.camera_rig().get_yaw_basis()
	var avant: Vector3 = -yaw_basis.z
	var droite: Vector3 = yaw_basis.x
	avant.y = 0.0
	droite.y = 0.0
	var souhait: Vector3 = direction
	souhait.y = 0.0
	if souhait.length_squared() < 0.000001:
		return Vector2.ZERO
	souhait = souhait.normalized()
	return Vector2(souhait.dot(droite.normalized()),
		souhait.dot(avant.normalized())).normalized()


func _pos_de(etape: Dictionary) -> Vector2:
	var pos: Array = etape.get("pos", []) as Array
	return Vector2(float(pos[0]), float(pos[1])) if pos.size() >= 2 else Vector2.ZERO


func _regard_de(etape: Dictionary) -> Vector3:
	var regard: Array = etape.get("regard", []) as Array
	if regard.size() >= 3:
		return Vector3(float(regard[0]), float(regard[1]), float(regard[2]))
	return Vector3.ZERO


func _sol(monde: Node3D, ou: Vector2) -> float:
	var heightmap: Variant = monde.call("heightmap")
	if heightmap != null and (heightmap as Object).has_method("height_at"):
		return float((heightmap as Object).call("height_at", ou.x, ou.y))
	return 0.0
