## HARNAIS DE PLAYTEST EN BOÎTE NOIRE.
##
## Fait jouer le jeu RÉEL par une entité extérieure — un agent — qui ne voit
## que ce qu'un joueur voit : l'écran. Aucune téléportation, aucun appel de
## méthode de victoire, aucune lecture d'état interne pour trouver une
## solution.
##
## Comment l'entrée reste VRAIE. `PlayerInputReader` est le seul point du
## gameplay qui consulte l'InputMap (D-013) : il lit des ACTIONS, jamais des
## touches. Injecter une action par `Input.action_press` et
## `Input.parse_input_event` traverse donc exactement le même chemin qu'un
## clavier : lecteur → `InputIntent` → contrôleur → physique. Ce harnais ne
## court-circuite rien ; il remplace le doigt, pas le jeu.
##
## Ce que le harnais écrit :
##
##   * `<out>/shot_NNN_<nom>.png` — ce que le joueur VOIT. C'est tout ce que
##     l'agent joueur reçoit ;
##   * `<out>/journal.jsonl` — une ligne par pas : temps, action, et les
##     NOTIFICATIONS affichées à l'écran depuis le pas précédent. Rien qu'un
##     joueur ne pourrait lire ;
##   * `<out>/trace.jsonl` — position, scène, vie, arme. RÉSERVÉ à
##     l'intégrateur pour diagnostiquer ; un agent joueur n'y a pas accès.
##
## Plan d'actions (JSON) :
##
##   [{"do": "press",  "action": "interact"},
##    {"do": "hold",   "action": "move_forward", "seconds": 2.5},
##    {"do": "look",   "dx": 220, "dy": 0},
##    {"do": "wait",   "seconds": 1.0},
##    {"do": "shot",   "name": "devant_la_porte"}]
##
## Usage :
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --script tools/godot/playtest_session.gd -- \
##     --plan=<plan.json> --out=evidence/playtest/<session>
extends SceneTree

const BOOT: String = "res://scenes/boot/Boot.tscn"
## Plafond de frames pour une attente : garde-fou si le temps de jeu n'avance
## plus (fenêtre perdue, scène bloquée).
const MAX_FRAMES: int = 6000
## Une capture au moins toutes les N secondes, même sans pas « shot » : un
## joueur regarde l'écran en continu, pas seulement quand il agit.
const AUTO_SHOT_SECONDS: float = 4.0

var _out_dir: String = "evidence/playtest/session"
var _plan_path: String = ""
var _width: int = 1280
var _height: int = 720

var _shot_index: int = 0
var _elapsed: float = 0.0
var _last_auto: float = 0.0
var _notices: Array[String] = []
var _journal: FileAccess = null
var _trace: FileAccess = null


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--plan="):
			_plan_path = argument.substr(7)
		elif argument.begins_with("--out="):
			_out_dir = argument.substr(6)
		elif argument.begins_with("--size="):
			var parts: PackedStringArray = argument.substr(7).split("x")
			if parts.size() == 2:
				_width = int(parts[0])
				_height = int(parts[1])
	DisplayServer.window_set_size(Vector2i(_width, _height))
	root.content_scale_size = Vector2i(_width, _height)

	var plan: Array = _read_plan()
	if plan.is_empty():
		push_error("[playtest] plan vide ou illisible : %s" % _plan_path)
		quit(2)
		return

	DirAccess.make_dir_recursive_absolute(_absolute(_out_dir))
	_journal = FileAccess.open(_absolute("%s/journal.jsonl" % _out_dir),
		FileAccess.WRITE)
	_trace = FileAccess.open(_absolute("%s/trace.jsonl" % _out_dir),
		FileAccess.WRITE)

	# Le jeu démarre par SON entrée, comme chez le joueur : Boot, puis le menu.
	var packed: PackedScene = load(BOOT) as PackedScene
	if packed == null:
		push_error("[playtest] Boot introuvable")
		quit(2)
		return
	root.add_child(packed.instantiate())
	# Les notifications de l'`EventBus` sont ce que le joueur LIT à l'écran :
	# les collecter, c'est retranscrire le HUD, pas espionner l'état interne.
	var bus: Node = root.get_node_or_null("EventBus")
	if bus != null and bus.has_signal("gameplay_notification"):
		bus.connect("gameplay_notification", func(text: String) -> void:
			_notices.append(text))
	await _wait(2.0)   # boot -> menu principal
	await _shoot("depart")

	for step: Variant in plan:
		await _run(step as Dictionary)

	await _shoot("fin")
	if _journal != null:
		_journal.close()
	if _trace != null:
		_trace.close()
	print("[playtest] %d capture(s), %.1f s jouées" % [_shot_index, _elapsed])
	quit(0)


func _read_plan() -> Array:
	if _plan_path.is_empty():
		return []
	var file: FileAccess = FileAccess.open(_absolute(_plan_path), FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed as Array if parsed is Array else []


func _absolute(path: String) -> String:
	if path.begins_with("/"):
		return path
	return ProjectSettings.globalize_path("res://%s" % path)


## Attente en TEMPS DE JEU, pas en frames.
##
## La première version comptait des frames en supposant 60 par seconde. En
## rendu logiciel une frame dure dix fois plus, et chacune fait avancer
## plusieurs ticks physiques : « marcher trois secondes » a envoyé le joueur à
## plus de cent mètres, jusque dans la rivière. Un playtest dont les durées
## mentent ne mesure rien — et c'est le harnais qui mentait, pas le jeu.
func _wait(seconds: float) -> void:
	var spent: float = 0.0
	var frames: int = 0
	while spent < seconds and frames < MAX_FRAMES:
		await process_frame
		spent += root.get_process_delta_time()
		frames += 1
	_elapsed += spent


## Quelques frames, quand ce qu'on attend est un RENDU et non une durée.
func _settle(frames: int) -> void:
	for i: int in range(frames):
		await process_frame


## Exécute un pas. Chaque pas dure un temps RÉALISTE : un joueur ne traverse
## pas une vallée en une frame, et une action instantanée masquerait les
## défauts de réponse qu'on cherche justement à voir.
func _run(step: Dictionary) -> void:
	var kind: String = String(step.get("do", ""))
	match kind:
		"press":
			var action: String = String(step.get("action", ""))
			_fire(action, true)
			await _settle(3)
			_fire(action, false)
			await _wait(maxf(0.25, float(step.get("after", 0.35))))
			_note({"do": "press", "action": action})
		"hold":
			var held: String = String(step.get("action", ""))
			var seconds: float = float(step.get("seconds", 1.0))
			Input.action_press(held, 1.0)
			await _wait(seconds)
			Input.action_release(held)
			await _settle(6)
			_note({"do": "hold", "action": held, "seconds": seconds})
		"look":
			# La souris : un déplacement en pixels, étalé pour que la caméra
			# amortisse comme elle le ferait sous une vraie main.
			var dx: float = float(step.get("dx", 0.0))
			var dy: float = float(step.get("dy", 0.0))
			var slices: int = 12
			for i: int in range(slices):
				var motion: InputEventMouseMotion = InputEventMouseMotion.new()
				motion.relative = Vector2(dx / float(slices), dy / float(slices))
				Input.parse_input_event(motion)
				await _wait(0.05)
			_note({"do": "look", "dx": dx, "dy": dy})
		"move_look":
			# Marcher EN regardant : le cas normal, et celui qui casse les
			# caméras. Le séparer en deux pas ne l'éprouverait pas.
			var walk: String = String(step.get("action", "move_forward"))
			var turn: float = float(step.get("dx", 0.0))
			var span: float = float(step.get("seconds", 2.0))
			var slices: int = 24
			Input.action_press(walk, 1.0)
			for i: int in range(slices):
				if turn != 0.0:
					var motion: InputEventMouseMotion = InputEventMouseMotion.new()
					motion.relative = Vector2(turn / float(slices), 0.0)
					Input.parse_input_event(motion)
				await _wait(span / float(slices))
			Input.action_release(walk)
			await _settle(6)
			_note({"do": "move_look", "action": walk, "dx": turn,
				"seconds": span})
		"wait":
			await _wait(float(step.get("seconds", 1.0)))
			_note({"do": "wait"})
		"shot":
			await _shoot(String(step.get("name", "vue")))
		_:
			_note({"do": "inconnu", "step": step})
	if _elapsed - _last_auto >= AUTO_SHOT_SECONDS:
		await _shoot("auto")


## Envoie une ACTION, comme le ferait une touche. `InputEventAction` satisfait
## `event.is_action_pressed()` du lecteur : les fronts ne sont pas perdus.
func _fire(action: String, pressed: bool) -> void:
	if action.is_empty():
		return
	var event: InputEventAction = InputEventAction.new()
	event.action = StringName(action)
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)
	if pressed:
		Input.action_press(action, 1.0)
	else:
		Input.action_release(action)


func _shoot(label: String) -> void:
	await _settle(4)
	var image: Image = root.get_texture().get_image()
	if image == null:
		return
	_shot_index += 1
	_last_auto = _elapsed
	var name: String = "shot_%03d_%s.png" % [_shot_index, label]
	image.save_png(_absolute("%s/%s" % [_out_dir, name]))
	_note({"do": "shot", "png": name})


## Une ligne de journal : ce que le joueur a fait, et ce que l'écran lui a dit.
## Puis une ligne de TRACE, réservée à l'intégrateur.
func _note(entry: Dictionary) -> void:
	entry["t"] = snappedf(_elapsed, 0.1)
	if not _notices.is_empty():
		entry["ecran"] = _notices.duplicate()
		_notices.clear()
	if _journal != null:
		_journal.store_line(JSON.stringify(entry))
	if _trace == null:
		return
	var facts: Dictionary = {"t": snappedf(_elapsed, 0.1)}
	var world: Node = root.get_node_or_null("Boot")
	var player: Node = _find_player()
	if player != null:
		var body: Node3D = player as Node3D
		facts["pos"] = [snappedf(body.global_position.x, 0.1),
			snappedf(body.global_position.y, 0.1),
			snappedf(body.global_position.z, 0.1)]
	facts["scene"] = current_scene.name if current_scene != null else "?"
	if world != null:
		facts["boot"] = true
	_trace.store_line(JSON.stringify(facts))


func _find_player() -> Node:
	var found: Array = root.get_tree().get_nodes_in_group("player") \
		if root.get_tree() != null else []
	return found[0] if not found.is_empty() else null
