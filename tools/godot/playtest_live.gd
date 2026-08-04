## HARNAIS DE PLAYTEST EN BOUCLE FERMÉE.
##
## Le harnais précédent exécutait un plan écrit à l'avance, puis un agent
## commentait les captures. C'était un test scénarisé, pas un playtest : le
## joueur ne choisissait rien. La différence n'est pas de vocabulaire — un
## parcours écrit d'avance ne peut pas se tromper de chemin, hésiter, ni
## revenir en arrière, et c'est exactement ce qu'on veut mesurer.
##
## Ici, le jeu S'ARRÊTE et ATTEND. À chaque pas :
##
##   1. Godot rend l'écran et l'écrit en PNG ;
##   2. il écrit `attente.json` — le numéro du pas et le chemin de la capture ;
##   3. il attend l'apparition de `pas_NNN.json`, la décision de l'agent ;
##   4. il exécute les entrées demandées par le VRAI InputMap ;
##   5. il laisse le jeu avancer d'une durée humaine ;
##   6. il recommence.
##
## L'agent ne reçoit que la capture. Il n'a accès ni au code, ni à l'arbre de
## scène, ni au navmesh, ni aux coordonnées, ni à la trace. Celle-ci est écrite
## pour l'INTÉGRATEUR, qui la lit après coup pour diagnostiquer — jamais
## pendant la partie, jamais par le joueur.
##
## Entrées autorisées, et rien d'autre : déplacement, caméra, saut, sprint,
## esquive, verrouillage, attaques, arc, interaction, inventaire, plat rapide,
## pause, et la navigation des menus publics. Aucune téléportation, aucun appel
## de méthode de gameplay, aucune écriture de sauvegarde.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --script tools/godot/playtest_live.gd -- \
##     --out=evidence/playtest/live_01 --steps=40 --patience=900
extends SceneTree

const BOOT: String = "res://scenes/boot/Boot.tscn"
## Actions du jeu qu'un joueur peut réellement déclencher. Toute demande hors
## de cette liste est REFUSÉE et journalisée : le harnais ne doit pas devenir
## une porte dérobée vers des capacités qu'un joueur n'a pas.
const ALLOWED: Array[String] = [
	"move_forward", "move_back", "move_left", "move_right",
	"jump", "sprint", "dodge", "interact",
	"attack_light", "attack_heavy", "aim", "shoot",
	"lock_on", "target_next", "target_prev",
	"inventory", "quick_meal", "pause",
	"ui_accept", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right",
]
## Durée maximale d'un maintien : un joueur ne tient pas une touche une minute.
const MAX_HOLD: float = 6.0
const MAX_FRAMES: int = 6000

var _out_dir: String = "evidence/playtest/live"
var _width: int = 1280
var _height: int = 720
var _max_steps: int = 30
## Secondes d'attente d'une décision avant d'abandonner la session.
var _patience: float = 900.0

var _step: int = 0
var _elapsed: float = 0.0
var _notices: Array[String] = []
var _journal: FileAccess = null
var _trace: FileAccess = null


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			_out_dir = argument.substr(6)
		elif argument.begins_with("--steps="):
			_max_steps = int(argument.substr(8))
		elif argument.begins_with("--patience="):
			_patience = float(argument.substr(11))
		elif argument.begins_with("--size="):
			var parts: PackedStringArray = argument.substr(7).split("x")
			if parts.size() == 2:
				_width = int(parts[0])
				_height = int(parts[1])
	DisplayServer.window_set_size(Vector2i(_width, _height))
	root.content_scale_size = Vector2i(_width, _height)
	DirAccess.make_dir_recursive_absolute(_absolute(_out_dir))
	_journal = FileAccess.open(_absolute("%s/decisions.jsonl" % _out_dir),
		FileAccess.WRITE)
	_trace = FileAccess.open(_absolute("%s/trace.jsonl" % _out_dir),
		FileAccess.WRITE)

	var packed: PackedScene = load(BOOT) as PackedScene
	if packed == null:
		push_error("[live] Boot introuvable")
		quit(2)
		return
	root.add_child(packed.instantiate())
	var bus: Node = root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("gameplay_notification"):
		bus.connect("gameplay_notification", func(text: String) -> void:
			_notices.append(text))
	await _wait(2.0)

	while _step < _max_steps:
		_step += 1
		var shot: String = await _capture()
		var decision: Dictionary = await _ask(shot)
		if decision.is_empty():
			print("[live] aucune décision au pas %d — session close" % _step)
			break
		if bool(decision.get("stop", false)):
			print("[live] le joueur arrête au pas %d" % _step)
			_note(decision, shot, [])
			break
		var done: Array[String] = await _perform(decision.get("action", []) as Array)
		_note(decision, shot, done)

	await _capture()
	if _journal != null:
		_journal.close()
	if _trace != null:
		_trace.close()
	print("[live] %d pas joués, %.1f s de jeu" % [_step, _elapsed])
	quit(0)


## Rend l'écran, l'écrit, et publie l'attente. Renvoie le nom du PNG.
func _capture() -> String:
	for i: int in range(4):
		await process_frame
	var image: Image = root.get_texture().get_image()
	var name: String = "pas_%03d.png" % _step
	if image != null:
		image.save_png(_absolute("%s/%s" % [_out_dir, name]))
	var waiting: Dictionary = {
		"pas": _step,
		"capture": "%s/%s" % [_out_dir, name],
		"temps_de_jeu": snappedf(_elapsed, 0.1),
		"ecran": _notices.duplicate(),
	}
	_notices.clear()
	var file: FileAccess = FileAccess.open(
		_absolute("%s/attente.json" % _out_dir), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(waiting, "  "))
		file.close()
	return name


## Attend la décision du joueur. C'est ICI que le harnais cesse d'être un
## script : rien ne se passe tant qu'une intelligence extérieure n'a pas
## regardé l'image et choisi.
func _ask(shot: String) -> Dictionary:
	var path: String = _absolute("%s/pas_%03d.json" % [_out_dir, _step])
	var waited: float = 0.0
	print("[live] pas %d : capture %s — j'attends une décision" % [_step, shot])
	while waited < _patience:
		if FileAccess.file_exists(path):
			# Petite pause : le fichier peut être en cours d'écriture.
			await _wait(0.15)
			var file: FileAccess = FileAccess.open(path, FileAccess.READ)
			if file == null:
				continue
			var text: String = file.get_as_text()
			file.close()
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Dictionary:
				return parsed as Dictionary
			print("[live] décision illisible au pas %d" % _step)
			return {}
		await _wait(0.25)
		waited += 0.25
	return {}


## Exécute les entrées demandées. Refuse tout ce qui n'est pas une action de
## joueur, et borne les durées : un maintien de dix minutes n'est pas humain.
func _perform(actions: Array) -> Array[String]:
	var done: Array[String] = []
	for entry: Variant in actions:
		var step: Dictionary = entry as Dictionary
		if step == null:
			continue
		var kind: String = String(step.get("input", ""))
		if kind == "look":
			var dx: float = float(step.get("x", 0.0)) * float(_width)
			var dy: float = float(step.get("y", 0.0)) * float(_height)
			var span: float = clampf(float(step.get("duration", 0.4)), 0.05, 2.0)
			var slices: int = 10
			for i: int in range(slices):
				var motion: InputEventMouseMotion = InputEventMouseMotion.new()
				motion.relative = Vector2(dx / float(slices), dy / float(slices))
				Input.parse_input_event(motion)
				await _wait(span / float(slices))
			done.append("look %.2f/%.2f" % [dx, dy])
			continue
		if not ALLOWED.has(kind):
			done.append("REFUSÉ %s" % kind)
			continue
		var seconds: float = clampf(float(step.get("duration", 0.0)), 0.0, MAX_HOLD)
		if seconds <= 0.05:
			var event: InputEventAction = InputEventAction.new()
			event.action = StringName(kind)
			event.pressed = true
			event.strength = 1.0
			Input.parse_input_event(event)
			Input.action_press(kind, 1.0)
			await _wait(0.08)
			var release: InputEventAction = InputEventAction.new()
			release.action = StringName(kind)
			release.pressed = false
			Input.parse_input_event(release)
			Input.action_release(kind)
			await _wait(0.30)
			done.append(kind)
		else:
			Input.action_press(kind, 1.0)
			await _wait(seconds)
			Input.action_release(kind)
			await _wait(0.1)
			done.append("%s %.1fs" % [kind, seconds])
	return done


func _wait(seconds: float) -> void:
	var spent: float = 0.0
	var frames: int = 0
	while spent < seconds and frames < MAX_FRAMES:
		await process_frame
		spent += root.get_process_delta_time()
		frames += 1
	_elapsed += spent


## Journal : la CHAÎNE DE DÉCISION, pas seulement les images. Sans elle, rien
## ne distingue une partie jouée d'un script rejoué.
func _note(decision: Dictionary, shot: String, done: Array[String]) -> void:
	if _journal != null:
		_journal.store_line(JSON.stringify({
			"pas": _step,
			"capture_recue": shot,
			"observation": decision.get("observation", ""),
			"objectif_suppose": decision.get("objectif_suppose", ""),
			"intention": decision.get("intention", ""),
			"resultat_attendu": decision.get("resultat_attendu", ""),
			"confiance": decision.get("confiance", null),
			"entrees_envoyees": done,
			"temps_de_jeu": snappedf(_elapsed, 0.1),
		}))
	if _trace == null:
		return
	var facts: Dictionary = {"pas": _step, "t": snappedf(_elapsed, 0.1)}
	var players: Array = root.get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var body: Node3D = players[0] as Node3D
		if body != null:
			facts["pos"] = [snappedf(body.global_position.x, 0.1),
				snappedf(body.global_position.y, 0.1),
				snappedf(body.global_position.z, 0.1)]
	facts["scene"] = current_scene.name if current_scene != null else "?"
	_trace.store_line(JSON.stringify(facts))


func _absolute(path: String) -> String:
	if path.begins_with("/"):
		return path
	return ProjectSettings.globalize_path("res://%s" % path)
