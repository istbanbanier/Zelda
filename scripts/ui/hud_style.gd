## Style d'interface V4.4 (réf. 03/04/05 du pack V4, §17.1) — LA source unique
## des plaques, chips et couleurs de l'UI : ardoise sombre translucide, filet
## d'or pâle, ivoire, rubis pour la vie, turquoise pour l'endurance, cyan très
## limité. Constructeurs statiques : chaque panneau demande son StyleBox ici,
## aucun style recopié à la main.
class_name HudStyle
extends RefCounted

const IVORY: Color = Color(0.93, 0.91, 0.85)
## Ivoire estompé — texte secondaire (indications, notes) : même teinte, alpha
## réduit, pour que la hiérarchie ne repose pas sur une taille seule.
const IVORY_MUTED: Color = Color(0.93, 0.91, 0.85, 0.6)
const GOLD: Color = Color(0.847, 0.702, 0.416)        # #D8B36A
## Fond des jauges d'or (durabilité) — l'assiette sombre du même métal.
const GOLD_DARK: Color = Color(0.16, 0.14, 0.10, 0.9)
const SLATE: Color = Color(0.075, 0.085, 0.11, 0.82)  # plaque translucide
const SLATE_SOLID: Color = Color(0.09, 0.10, 0.13, 0.95)
## Fond OPAQUE des écrans plein cadre (options, chargement) : assez sombre pour
## asseoir l'or pâle, jamais un gris neutre de panneau debug.
const BACKDROP: Color = Color(0.045, 0.055, 0.085, 1.0)
const RUBY: Color = Color(0.78, 0.20, 0.26)
const RUBY_DARK: Color = Color(0.24, 0.09, 0.11, 0.85)
const TURQUOISE: Color = Color(0.086, 0.561, 0.608)   # #168F9B
const TURQUOISE_DARK: Color = Color(0.05, 0.15, 0.17, 0.8)
## Cyan électrique (#22D9EC) et son cœur clair — RÉSERVÉS à la Résonance
## active (P3 §1.4 : « moins de 5 % de cyan saturé simultanément à l'écran »).
## Aucun autre élément de HUD ne doit les employer.
const CYAN: Color = Color(0.133, 0.851, 0.925)
const CYAN_CORE: Color = Color(0.925, 1.0, 1.0)


## Plaque d'ardoise au filet d'or — le fond de tout élément de HUD.
static func plaque(border_alpha: float = 0.55) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = SLATE
	style.border_color = Color(GOLD.r, GOLD.g, GOLD.b, border_alpha)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


## Chip de touche (« E », « Tab ») : petit cartouche au bord ivoire.
static func chip() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = SLATE_SOLID
	style.border_color = IVORY
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 7.0
	style.content_margin_right = 7.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 2.0
	return style


## Remplissage de jauge (rubis, turquoise, or) sur fond assorti.
static func gauge_fill(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style


static func gauge_background(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(3)
	return style


## Applique la livrée complète d'un bouton du jeu : plaque d'ardoise au repos,
## filet d'or qui s'affirme au survol, bord plein à l'appui, version éteinte
## quand il est désactivé — et focus au filet d'or (§17.3 : « focus visible »).
## Quatre états VISIBLES au clavier comme à la souris ; sans cette fonction, un
## bouton garde le thème gris par défaut de Godot et trahit le panneau debug.
static func style_button(button: Button) -> void:
	button.add_theme_color_override(&"font_color", IVORY)
	button.add_theme_color_override(&"font_hover_color", GOLD)
	button.add_theme_color_override(&"font_focus_color", GOLD)
	button.add_theme_color_override(&"font_pressed_color", IVORY)
	button.add_theme_color_override(&"font_disabled_color",
		Color(IVORY.r, IVORY.g, IVORY.b, 0.35))
	button.add_theme_stylebox_override(&"normal", plaque(0.35))
	button.add_theme_stylebox_override(&"hover", plaque(0.75))
	var pressed: StyleBoxFlat = plaque(1.0)
	pressed.border_color = GOLD
	pressed.set_border_width_all(2)
	button.add_theme_stylebox_override(&"pressed", pressed)
	var disabled: StyleBoxFlat = plaque(0.15)
	disabled.bg_color = Color(SLATE.r, SLATE.g, SLATE.b, 0.4)
	button.add_theme_stylebox_override(&"disabled", disabled)
	var focus: StyleBoxFlat = plaque(1.0)
	focus.border_color = GOLD
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override(&"focus", focus)


## Titre de panneau : or pâle, taille au choix. Une seule définition pour que
## tous les écrans partagent la même voix typographique.
static func style_heading(label: Label, font_size: int = 26) -> void:
	label.add_theme_color_override(&"font_color", GOLD)
	label.add_theme_font_size_override(&"font_size", font_size)


## ---------------------------------------------------------------------------
## Sons d'interface (LOT 9) — six .ogg promus depuis la quarantaine
## `asset_library/inbox/kenney_interface_sounds_1_0` (Kenney, CC0 1.0).
## Journal de promotion : evidence/full_visual_finish_20260812/promotions_ui.md ;
## l'entrée ATTRIBUTIONS est centralisée par l'intégrateur.
##
## Chaque écran possède SON lecteur (`attach_ui_audio`) ; les flux sont chargés
## à la demande puis mis en cache — jamais de chargement par frame. Un fichier
## manquant rend l'action muette, jamais cassée (même règle qu'`AudioManager`).
## ---------------------------------------------------------------------------

const UI_SOUND_PATHS: Dictionary[StringName, String] = {
	&"click": "res://assets/audio/ui/ui_click.ogg",
	&"confirm": "res://assets/audio/ui/ui_confirm.ogg",
	&"back": "res://assets/audio/ui/ui_back.ogg",
	&"hover": "res://assets/audio/ui/ui_hover.ogg",
	&"error": "res://assets/audio/ui/ui_error.ogg",
	&"open": "res://assets/audio/ui/ui_open.ogg",
}
## L'UI ponctue, elle ne domine jamais le mix — volume retenu, réglable par le
## bus `UI` d'AudioManager sans toucher aux effets de gameplay.
const UI_SOUND_VOLUME_DB: float = -9.0

static var _ui_streams: Dictionary = {}


## Crée le lecteur de sons d'interface d'un écran et l'attache à `host`.
## `PROCESS_MODE_ALWAYS` : la pause et les panneaux modaux s'entendent aussi.
static func attach_ui_audio(host: Node) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = "UiSounds"
	player.bus = "UI" if AudioServer.get_bus_index("UI") != -1 else "Master"
	player.volume_db = UI_SOUND_VOLUME_DB
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	host.add_child(player)
	return player


static func play_ui(player: AudioStreamPlayer, kind: StringName) -> void:
	if player == null or not is_instance_valid(player):
		return
	var stream: AudioStream = _ui_stream(kind)
	if stream == null:
		return
	player.stream = stream
	player.play()


static func _ui_stream(kind: StringName) -> AudioStream:
	if _ui_streams.has(kind):
		return _ui_streams[kind] as AudioStream
	var path: String = String(UI_SOUND_PATHS.get(kind, ""))
	var stream: AudioStream = null
	if not path.is_empty() and ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	_ui_streams[kind] = stream
	return stream


## Retours standard d'un bouton, identiques au clavier et à la souris :
## le survol souris DONNE le focus (un seul état « courant », pas deux),
## le focus fait tic, l'appui fait clic. Un bouton désactivé reste muet.
static func wire_button_feedback(button: Button, player: AudioStreamPlayer) -> void:
	button.mouse_entered.connect(func() -> void:
		if not button.disabled and button.focus_mode != Control.FOCUS_NONE:
			button.grab_focus())
	button.focus_entered.connect(func() -> void: play_ui(player, &"hover"))
	button.pressed.connect(func() -> void: play_ui(player, &"click"))

## ISS-059 — fin de vie du cache statique. Inscrite au démarrage du
## script par `_static_init()`, appelée UNE fois à l'extinction du moteur
## par `SceneFlow._exit_tree()`. Sans elle, ces entrées vivent jusqu'à la
## mort du processus et sortent au rapport de fuite : mesure et ablation à
## variable unique, `evidence/…/v2_3_r2b3_1/iss059/CHAINE_CAUSALE.md`.
##
## Le sens de la dépendance est imposé : le porteur connaît le noyau, le
## noyau ne connaît aucun porteur (test_aucune_reference_croisee_interdite).
static func _static_init() -> void:
	StaticResourceCaches.enregistrer("HudStyle", liberer_caches)


static func liberer_caches() -> int:
	var n: int = _ui_streams.size()
	_ui_streams.clear()
	return n
