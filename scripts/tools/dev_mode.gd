## MODE DÉVELOPPEMENT — tout voir, tout enregistrer, sans rien changer au jeu.
##
## Éteint par défaut. Trois touches, et rien d'autre à savoir :
##
##   F3  ouvre/ferme le panneau et DÉMARRE/ARRÊTE l'enregistrement
##   F4  pose un MARQUEUR (« ce que je viens de voir ne va pas ») + capture
##   F5  capture d'écran seule
##
## Ce qu'il enregistre : la scène, la position et l'état du héros, sa vie et
## son endurance, les changements de scène, les notifications du jeu, les
## chutes de fluidité, les marqueurs posés, et l'environnement matériel. Tout
## part dans `user://dev_sessions/<horodatage>/`, sur cette machine seulement.
##
## Ce qu'il ne fait PAS, et c'est délibéré : il ne triche pas, ne téléporte
## pas, ne rend pas invincible, ne modifie aucune valeur de jeu. Une session
## enregistrée reste une session honnête — sinon elle ne prouverait rien.
##
## Il survit à la pause (`PROCESS_MODE_ALWAYS`) : un défaut se voit souvent
## justement quand le jeu est figé.
## Pas de `class_name` ici : le nom de l'autoload (`DevMode`) EST déjà un
## identifiant global, et Godot refuse qu'une classe le masque. On l'atteint
## donc par le singleton, comme les autres autoloads du projet.
extends CanvasLayer

## Au-dessus du HUD (couche 1 par défaut), sous rien.
const LAYER: int = 90
## Cadence d'échantillonnage de l'état du héros, en secondes.
const SAMPLE_INTERVAL: float = 1.0
## Une image qui dépasse ce temps est une saccade digne d'être consignée.
const HITCH_MS: float = 100.0

var recorder: DevRecorder = DevRecorder.new()

var _panel: PanelContainer = null
var _label: Label = null
var _sample_accumulator: float = 0.0
var _frames: int = 0
var _fps_accumulator: float = 0.0
var _fps: float = 0.0
var _worst_frame_ms: float = 0.0
var _markers: int = 0
var _shots: int = 0


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_panel()
	set_visible_panel(false)
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.connect("gameplay_notification", _on_game_notification)
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow != null and flow.has_signal("transition_finished"):
		flow.connect("transition_finished", _on_scene_changed)


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.name = "DevPanel"
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.07, 0.82)
	style.set_content_margin_all(10.0)
	style.set_corner_radius_all(4)
	_panel.add_theme_stylebox_override(&"panel", style)
	_label = Label.new()
	_label.add_theme_font_size_override(&"font_size", 16)
	_label.add_theme_color_override(&"font_color", Color(0.85, 0.93, 0.98))
	_panel.add_child(_label)
	add_child(_panel)
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.offset_left = 14.0
	_panel.offset_top = 70.0


func set_visible_panel(value: bool) -> void:
	if _panel != null:
		_panel.visible = value


func is_panel_visible() -> bool:
	return _panel != null and _panel.visible


## Bascule complète : le panneau ET l'enregistrement. Une seule touche, parce
## qu'une personne qui découvre un défaut n'a pas le temps d'en apprendre deux.
func toggle() -> void:
	if recorder.is_recording():
		var folder: String = recorder.stop("arrêt par F3")
		set_visible_panel(false)
		_notify("Enregistrement terminé — dossier : %s" % folder)
		return
	if recorder.start():
		set_visible_panel(true)
		_notify("Enregistrement démarré (F4 pour signaler un problème)")


## Marqueur : le geste central du mode. La personne n'a rien à écrire — elle
## appuie au moment où quelque chose cloche, et l'horodatage fait le reste.
func mark(note: String = "") -> void:
	if not recorder.is_recording():
		return
	_markers += 1
	var data: Dictionary = {"numero": _markers, "note": note}
	data.merge(_player_snapshot())
	recorder.record(&"marqueur", data)
	capture_screenshot("marqueur_%02d" % _markers)
	_notify("Problème signalé (marqueur %d)" % _markers)


func marker_count() -> int:
	return _markers


func capture_screenshot(name_hint: String = "") -> String:
	if not recorder.is_recording():
		return ""
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return ""
	var texture: ViewportTexture = viewport.get_texture()
	if texture == null:
		return ""
	var image: Image = texture.get_image()
	if image == null:
		return ""
	_shots += 1
	var hint: String = name_hint if not name_hint.is_empty() \
		else "capture_%02d" % _shots
	var path: String = "%s/%s.png" % [recorder.directory(), hint]
	if image.save_png(path) != OK:
		return ""
	recorder.record(&"capture", {"fichier": hint + ".png"})
	return path


func _input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	# Touches BRUTES, volontairement hors InputMap : le mode dev ne doit pas
	# ajouter d'actions au jeu livré, ni entrer en conflit avec un remappage.
	match key.keycode:
		KEY_F3:
			toggle()
			get_viewport().set_input_as_handled()
		KEY_F4:
			mark()
			get_viewport().set_input_as_handled()
		KEY_F5:
			capture_screenshot()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_frames += 1
	_fps_accumulator += delta
	if delta * 1000.0 > _worst_frame_ms:
		_worst_frame_ms = delta * 1000.0
	if delta * 1000.0 > HITCH_MS and recorder.is_recording():
		recorder.record(&"saccade", {"ms": snappedf(delta * 1000.0, 0.1)})
	if _fps_accumulator >= 0.5:
		_fps = float(_frames) / _fps_accumulator
		_frames = 0
		_fps_accumulator = 0.0
	if not recorder.is_recording():
		return
	_sample_accumulator += delta
	if _sample_accumulator >= SAMPLE_INTERVAL:
		_sample_accumulator = 0.0
		var snapshot: Dictionary = _player_snapshot()
		snapshot["fps"] = snappedf(_fps, 0.1)
		recorder.record(&"position", snapshot)
	if is_panel_visible():
		_refresh_panel()


## Instantané du héros, sans jamais supposer qu'il existe : le mode dev tourne
## aussi dans le menu, dans un laboratoire ou pendant un chargement.
func _player_snapshot() -> Dictionary:
	var data: Dictionary = {"scene": _scene_name()}
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		return data
	var body: Node3D = players[0] as Node3D
	if body == null or not is_instance_valid(body):
		return data
	data["x"] = snappedf(body.global_position.x, 0.1)
	data["y"] = snappedf(body.global_position.y, 0.1)
	data["z"] = snappedf(body.global_position.z, 0.1)
	if body.has_method("mode"):
		# `PlayerController.Mode` : on écrit le NOM, pas le nombre — un journal
		# relu dans six mois ne doit pas exiger de connaître l'ordre d'un enum.
		var names: Array[String] = ["locomotion", "escalade", "retablissement",
			"attaque", "esquive", "blesse", "mort"]
		var index: int = int(body.call("mode"))
		data["etat"] = names[index] if index >= 0 and index < names.size() \
			else str(index)
	var health: Node = body.get_node_or_null("Components/HealthComponent")
	if health != null and health.has_method("current"):
		data["vie"] = snappedf(float(health.call("current")), 0.1)
	var stamina: Node = body.get_node_or_null("Components/StaminaComponent")
	if stamina != null and stamina.has_method("current"):
		data["endurance"] = snappedf(float(stamina.call("current")), 0.1)
	return data


func _scene_name() -> String:
	var current: Node = get_tree().current_scene
	return current.name if current != null else "(aucune)"


func _refresh_panel() -> void:
	var snapshot: Dictionary = _player_snapshot()
	var lines: Array[String] = []
	lines.append("● ENREGISTREMENT  —  F3 arrêter · F4 signaler · F5 capture")
	lines.append("Scène : %s" % String(snapshot.get("scene", "?")))
	if snapshot.has("x"):
		lines.append("Position : %.0f, %.0f, %.0f"
			% [snapshot["x"], snapshot["y"], snapshot["z"]])
	if snapshot.has("etat"):
		lines.append("État : %s" % String(snapshot["etat"]))
	if snapshot.has("vie"):
		lines.append("Vie : %.0f    Endurance : %.0f"
			% [snapshot["vie"], snapshot.get("endurance", 0.0)])
	lines.append("Images/s : %.0f   (pire image : %.0f ms)"
		% [_fps, _worst_frame_ms])
	lines.append("Événements : %d   Problèmes signalés : %d"
		% [recorder.event_count(), _markers])
	_label.text = "\n".join(lines)


func _on_game_notification(text: String) -> void:
	recorder.record(&"message", {"texte": text})


func _on_scene_changed(path: String) -> void:
	recorder.record(&"scene", {"chemin": path})


func _notify(text: String) -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.call("notify", text)
	print("[dev] %s" % text)


func _exit_tree() -> void:
	if recorder.is_recording():
		recorder.stop("fermeture du jeu")
