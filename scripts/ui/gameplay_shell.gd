## Coquille de gameplay — capture souris, pause, réglages, HUD, inventaire
## (jalon correctif D.1R, constats PT-D1-01/-03/-11).
##
## Instanciée dans chaque scène JOUABLE. `process_mode = ALWAYS` : elle reste
## vivante quand l'arbre est en pause — c'est elle qui suspend et reprend le
## monde ; le gameplay (PAUSABLE par défaut) gèle réellement.
##
## HUD (§17.2) : santé, endurance, flèches, arme et durabilité, verrouillage,
## réticule en visée, invite d'interaction unique, notifications courtes. Tout
## reflète les COMPOSANTS réels — aucune valeur recopiée à la main.
##
## LIMITE MESURÉE : en headless le serveur d'affichage refuse
## `MOUSE_MODE_CAPTURED` (relu : VISIBLE). L'état VOULU est exposé et testé ;
## la capture effective se vérifie sur un poste avec écran.
class_name GameplayShell
extends CanvasLayer

signal pause_toggled(paused: bool)

## Scène rechargée par « Réessayer » — le checkpoint de D.1R (le monde jouable
## principal), posé par la scène qui instancie la coquille.
@export var world_scene_path: String = "res://scenes/world/valley/ValleyWorld.tscn"

## Rythme de rafraîchissement des textes du HUD (§5.4 : pas d'allocation de
## chaînes à chaque frame pour des valeurs qui bougent rarement).
const HUD_TEXT_REFRESH: float = 0.1
const NOTIFICATION_LIFETIME: float = 3.0
const MAX_NOTIFICATIONS: int = 4

@onready var _pause_panel: Control = %PausePanel
@onready var _resume_button: Button = %ResumeButton
@onready var _sensitivity_slider: HSlider = %SensitivitySlider
@onready var _sensitivity_value: Label = %SensitivityValue
@onready var _quit_button: Button = %QuitButton
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _stamina_bar: ProgressBar = %StaminaBar
@onready var _arrows_label: Label = %ArrowsLabel
@onready var _weapon_label: Label = %WeaponLabel
@onready var _lock_label: Label = %LockLabel
@onready var _reticle: Control = %Reticle
@onready var _prompt_label: Label = %PromptLabel
@onready var _notifications: VBoxContainer = %Notifications
@onready var _inventory_panel: Control = %InventoryPanel
@onready var _slot_list: VBoxContainer = %SlotList
@onready var _equip_button: Button = %EquipButton
@onready var _move_up_button: Button = %MoveUpButton
@onready var _move_down_button: Button = %MoveDownButton
@onready var _close_inventory_button: Button = %CloseInventoryButton
@onready var _death_panel: Control = %DeathPanel
@onready var _retry_button: Button = %RetryButton
@onready var _death_quit_button: Button = %DeathQuitButton
@onready var _fade_rect: ColorRect = %RescueFade

var _mouse_captured_wanted: bool = true
var _player: PlayerController = null
var _hud_refresh_accumulator: float = 0.0
var _selected_slot: int = 0
## Lecteur des sons d'interface (LOT 9 — Kenney CC0, voir HudStyle.UI_SOUND_PATHS).
var _ui_audio: AudioStreamPlayer = null

## Habillage V4.4 (réf. 03) — construits en code par `_apply_v4_style()`.
const RUBY_SHARDS: int = 5
const DURABILITY_SEGMENTS: int = 4
var _ruby_shards: Array[ProgressBar] = []
var _durability_segments: Array[ProgressBar] = []
var _lock_plaque: PanelContainer = null
var _lock_target_bar: ProgressBar = null
var _lock_health: HealthComponent = null
var _prompt_panel: PanelContainer = null
var _controls_button: Button = null
var _controls_panel: OptionsPanel = null
var _meals_label: Label = null
## Inventaire V4.5 (réf. 04) — grille de cartes + détail aux données réelles.
var _inventory_grid: GridContainer = null
var _detail_name: Label = null
var _detail_stats: Label = null
var _detail_conductivity: ProgressBar = null
var _detail_icon: TextureRect = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_panel.visible = false
	_inventory_panel.visible = false
	_prompt_label.text = ""
	_lock_label.visible = false
	_reticle.visible = false
	_death_panel.visible = false
	_fade_rect.modulate.a = 0.0
	_resume_button.pressed.connect(_on_resume)
	_quit_button.pressed.connect(_on_quit_to_menu)
	_retry_button.pressed.connect(_on_retry)
	_death_quit_button.pressed.connect(_on_quit_to_menu)
	_equip_button.pressed.connect(_on_equip_selected)
	_move_up_button.pressed.connect(func() -> void: _move_selected(-1))
	_move_down_button.pressed.connect(func() -> void: _move_selected(1))
	_close_inventory_button.pressed.connect(toggle_inventory)
	_sensitivity_slider.min_value = UserSettings.MIN_MOUSE_SENSITIVITY
	_sensitivity_slider.max_value = UserSettings.MAX_MOUSE_SENSITIVITY
	_sensitivity_slider.step = 0.0001
	_sensitivity_slider.value = UserSettings.load_mouse_sensitivity()
	_sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	_refresh_sensitivity_label(_sensitivity_slider.value)
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.connect("gameplay_notification", _on_notification)
	# AVANT _apply_v4_style() : les boutons y câblent leurs retours sonores.
	_ui_audio = HudStyle.attach_ui_audio(self)
	_apply_v4_style()
	# E.2b : les interactables (feu de camp) trouvent la coquille par groupe.
	add_to_group("gameplay_shell")
	_build_cooking_panel()
	_build_buff_label()
	_build_boss_bar()
	_build_controls_button()
	_build_resonance_hud()
	_set_mouse_captured(true)
	# Le joueur peut entrer dans l'arbre après la coquille : liaison différée.
	_bind_player.call_deferred()


## ---------------------------------------------------------------------------
## Habillage V4.4 (réf. 03/05) — ardoise, or pâle, rubis, turquoise.
## La LOGIQUE D.1R n'est pas reconstruite : les mêmes signaux alimentent des
## contrôles restylés ; chaque valeur affichée vient d'un composant réel.
## ---------------------------------------------------------------------------

func _apply_v4_style() -> void:
	var hud: Control = _health_bar.get_node("../..") as Control
	# 1. Vie en fragments de rubis (réf. 03) : la barre d'origine devient le
	# MODÈLE caché — mêmes signaux, seuls les éclats s'affichent. `hud_health()`
	# lit la SOMME des éclats : le seam mesure ce qui est réellement montré.
	_health_bar.visible = false
	var vitals: VBoxContainer = _health_bar.get_parent() as VBoxContainer
	var ruby_row: HBoxContainer = HBoxContainer.new()
	ruby_row.name = "RubyRow"
	ruby_row.add_theme_constant_override(&"separation", 4)
	var emblem: Label = Label.new()
	emblem.text = "❖"
	emblem.add_theme_color_override(&"font_color", HudStyle.GOLD)
	ruby_row.add_child(emblem)
	for i: int in range(RUBY_SHARDS):
		var shard: ProgressBar = ProgressBar.new()
		shard.custom_minimum_size = Vector2(30, 20)
		shard.show_percentage = false
		shard.max_value = 100.0 / float(RUBY_SHARDS)
		shard.value = shard.max_value
		shard.add_theme_stylebox_override(&"background",
			HudStyle.gauge_background(HudStyle.RUBY_DARK))
		shard.add_theme_stylebox_override(&"fill", HudStyle.gauge_fill(HudStyle.RUBY))
		ruby_row.add_child(shard)
		_ruby_shards.append(shard)
	vitals.add_child(ruby_row)
	vitals.move_child(ruby_row, 0)
	# 2. Endurance turquoise DISCRÈTE près du personnage, visible pendant
	# l'usage seulement (réf. 03) — sortie de la colonne haut-gauche.
	vitals.remove_child(_stamina_bar)
	hud.add_child(_stamina_bar)
	_stamina_bar.custom_minimum_size = Vector2(130, 7)
	_stamina_bar.show_percentage = false
	_stamina_bar.set_anchors_preset(Control.PRESET_CENTER)
	_stamina_bar.offset_left = 90.0
	_stamina_bar.offset_right = 220.0
	_stamina_bar.offset_top = 30.0
	_stamina_bar.offset_bottom = 37.0
	_stamina_bar.add_theme_stylebox_override(&"background",
		HudStyle.gauge_background(HudStyle.TURQUOISE_DARK))
	_stamina_bar.add_theme_stylebox_override(&"fill",
		HudStyle.gauge_fill(HudStyle.TURQUOISE))
	_stamina_bar.visible = false
	# 3. Plaque de cible verrouillée : nom sobre + vie RÉELLE de l'ennemi.
	_lock_plaque = PanelContainer.new()
	_lock_plaque.name = "LockPlaque"
	_lock_plaque.add_theme_stylebox_override(&"panel", HudStyle.plaque())
	var lock_column: VBoxContainer = VBoxContainer.new()
	_lock_label.get_parent().remove_child(_lock_label)
	_lock_label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	lock_column.add_child(_lock_label)
	_lock_target_bar = ProgressBar.new()
	_lock_target_bar.custom_minimum_size = Vector2(180, 9)
	_lock_target_bar.show_percentage = false
	_lock_target_bar.add_theme_stylebox_override(&"background",
		HudStyle.gauge_background(HudStyle.RUBY_DARK))
	_lock_target_bar.add_theme_stylebox_override(&"fill",
		HudStyle.gauge_fill(HudStyle.RUBY))
	lock_column.add_child(_lock_target_bar)
	_lock_plaque.add_child(lock_column)
	hud.add_child(_lock_plaque)
	_lock_plaque.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_lock_plaque.offset_left = -110.0
	_lock_plaque.offset_right = 110.0
	_lock_plaque.offset_top = 18.0
	_lock_plaque.visible = false
	# 4. Carte d'arme (réf. 03) : plaque bas-droite — nom, durabilité
	# SEGMENTÉE, flèches. Les labels existants y déménagent tels quels.
	var gear: VBoxContainer = _weapon_label.get_parent() as VBoxContainer
	var card: PanelContainer = PanelContainer.new()
	card.name = "WeaponCard"
	card.add_theme_stylebox_override(&"panel", HudStyle.plaque())
	hud.add_child(card)
	card.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	card.offset_left = -250.0
	card.offset_top = -110.0
	card.offset_right = -16.0
	card.offset_bottom = -16.0
	gear.get_parent().remove_child(gear)
	card.add_child(gear)
	_weapon_label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	_arrows_label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	var durability_row: HBoxContainer = HBoxContainer.new()
	durability_row.name = "DurabilityRow"
	durability_row.add_theme_constant_override(&"separation", 3)
	for i: int in range(DURABILITY_SEGMENTS):
		var segment: ProgressBar = ProgressBar.new()
		segment.custom_minimum_size = Vector2(28, 8)
		segment.show_percentage = false
		segment.max_value = 1.0
		segment.add_theme_stylebox_override(&"background",
			HudStyle.gauge_background(HudStyle.GOLD_DARK))
		segment.add_theme_stylebox_override(&"fill", HudStyle.gauge_fill(HudStyle.GOLD))
		durability_row.add_child(segment)
		_durability_segments.append(segment)
	gear.add_child(durability_row)
	gear.move_child(durability_row, 1)
	# Réserve de plats, sous les flèches : même colonne, même hiérarchie de
	# lecture. Masquée tant qu'on n'a rien cuisiné — §17.2 : le HUD cache ce
	# qui n'est pas utile.
	_meals_label = Label.new()
	_meals_label.name = "MealsLabel"
	_meals_label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	_meals_label.visible = false
	gear.add_child(_meals_label)
	# 5. Invite en cartouche (réf. 03 : chip de touche + verbe).
	_prompt_panel = PanelContainer.new()
	_prompt_panel.name = "PromptPanel"
	_prompt_panel.add_theme_stylebox_override(&"panel", HudStyle.chip())
	var prompt_anchor_top: float = _prompt_label.offset_top
	_prompt_label.get_parent().remove_child(_prompt_label)
	_prompt_label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	_prompt_panel.add_child(_prompt_label)
	hud.add_child(_prompt_panel)
	_prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_panel.offset_left = -110.0
	_prompt_panel.offset_right = 110.0
	_prompt_panel.offset_top = prompt_anchor_top
	_prompt_panel.visible = false
	# 6. Panneaux (pause, mort) : colonne posée sur une plaque d'ardoise, dim
	# adouci — le monde reste VISIBLE derrière (réf. 05 : jamais un écran noir).
	for panel_name: String in ["PausePanel", "DeathPanel", "InventoryPanel"]:
		var panel: Control = get_node("%" + panel_name) as Control
		var dim: ColorRect = panel.get_node("Dim") as ColorRect
		dim.color = Color(0.02, 0.03, 0.05, 0.45)
		var column: VBoxContainer = panel.get_node("Column") as VBoxContainer
		var plate: PanelContainer = PanelContainer.new()
		plate.name = "Plate"
		plate.add_theme_stylebox_override(&"panel", HudStyle.plaque(0.8))
		panel.remove_child(column)
		plate.add_child(column)
		# Centrage ROBUSTE (ART-P0 : la capture d'inventaire montrait la plaque
		# hors cadre avec des ancres calculées) : un CenterContainer plein
		# écran centre son contenu quelle que soit sa taille — mesurable, sans
		# arithmétique d'offsets.
		var centerer: CenterContainer = CenterContainer.new()
		centerer.name = "Centerer"
		panel.add_child(centerer)
		# ANCRES **ET OFFSETS** (ART-P0R.2) : `set_anchors_preset` seul
		# recalcule les offsets pour PRÉSERVER le rect courant — le conteneur
		# restait 0 × 0 en haut-gauche (mesuré sur la capture ART-P0). La
		# variante _and_offsets remplit réellement l'écran ; le centrage suit
		# ensuite chaque redimensionnement, sans position calculée au 1er frame.
		centerer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		centerer.add_child(plate)
		var title: Label = column.get_node_or_null("Title") as Label
		if title != null:
			title.add_theme_color_override(&"font_color", HudStyle.GOLD)
	# 7. Inventaire (réf. 04) : grille 2 × 4 de cartes + panneau de détail aux
	# données RÉELLES (définition + instance). Pas d'onglet OBJETS : il
	# n'existe pas encore — on n'affiche pas un système absent (§0.2).
	(_inventory_panel.get_node("Centerer/Plate/Column/Title") as Label).text = \
		Textes.t("inventaire.titre")
	var body: HBoxContainer = HBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override(&"separation", 18)
	_inventory_grid = GridContainer.new()
	_inventory_grid.name = "Cards"
	_inventory_grid.columns = 4
	_inventory_grid.add_theme_constant_override(&"h_separation", 6)
	_inventory_grid.add_theme_constant_override(&"v_separation", 6)
	body.add_child(_inventory_grid)
	var detail_plate: PanelContainer = PanelContainer.new()
	detail_plate.name = "Detail"
	detail_plate.add_theme_stylebox_override(&"panel", HudStyle.plaque(0.5))
	detail_plate.custom_minimum_size = Vector2(230, 0)
	var detail_column: VBoxContainer = VBoxContainer.new()
	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = Vector2(0, 110)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_column.add_child(_detail_icon)
	_detail_name = Label.new()
	_detail_name.add_theme_color_override(&"font_color", HudStyle.GOLD)
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_column.add_child(_detail_name)
	_detail_stats = Label.new()
	_detail_stats.add_theme_color_override(&"font_color", HudStyle.IVORY)
	detail_column.add_child(_detail_stats)
	var conductivity_title: Label = Label.new()
	conductivity_title.text = Textes.t("inventaire.conductivite")
	conductivity_title.add_theme_color_override(&"font_color", HudStyle.IVORY)
	detail_column.add_child(conductivity_title)
	_detail_conductivity = ProgressBar.new()
	_detail_conductivity.custom_minimum_size = Vector2(0, 10)
	_detail_conductivity.max_value = 1.0
	_detail_conductivity.show_percentage = false
	# Cyan : la conductivité EST une donnée de Résonance — seule exception
	# HUD à la règle « cyan réservé » (§17.1), déjà actée par la réf. 04.
	_detail_conductivity.add_theme_stylebox_override(&"background",
		HudStyle.gauge_background(HudStyle.TURQUOISE_DARK))
	_detail_conductivity.add_theme_stylebox_override(&"fill",
		HudStyle.gauge_fill(HudStyle.CYAN))
	detail_column.add_child(_detail_conductivity)
	detail_plate.add_child(detail_column)
	body.add_child(detail_plate)
	_slot_list.add_child(body)
	var hint: Label = Label.new()
	hint.name = "Hints"
	hint.text = Textes.t("inventaire.fermer")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override(&"font_color",
		Color(HudStyle.IVORY.r, HudStyle.IVORY.g, HudStyle.IVORY.b, 0.6))
	_slot_list.add_child(hint)
	for button_node: Button in [_resume_button, _quit_button, _retry_button,
			_death_quit_button, _equip_button, _move_up_button, _move_down_button,
			_close_inventory_button]:
		HudStyle.style_button(button_node)
		HudStyle.wire_button_feedback(button_node, _ui_audio)


## Racine de la scène du shell, puis recherche descendante. `owner` est
## renseigné pour un shell instancié dans un `.tscn` ; sinon le parent
## direct fait office de racine.
func _find_player_in_own_scene() -> PlayerController:
	var scene_root: Node = owner if owner != null else get_parent()
	if scene_root == null:
		return null
	for node: Node in scene_root.find_children("*", "PlayerController",
			true, false):
		var player: PlayerController = node as PlayerController
		if player != null:
			return player
	return null


## Lie le shell au joueur de SA scène.
##
## Défaut mesuré (F.6) : la liaison prenait le premier nœud du groupe
## `player` — donc, dès que deux mondes coexistent (transition de scène,
## suite de tests, monde préchargé), le shell d'une scène servait le
## joueur d'une AUTRE. Conséquence observée : la MORT MANQUÉE — le
## panneau de mort n'apparaissait jamais parce que le shell écoutait la
## santé d'un joueur qui, lui, ne mourait pas. On cherche donc d'abord
## dans sa propre scène ; le groupe ne sert plus que de repli.
func _bind_player() -> void:
	_player = _find_player_in_own_scene()
	if _player == null:
		for node: Node in get_tree().get_nodes_in_group("player"):
			var player: PlayerController = node as PlayerController
			if player != null:
				_player = player
				break
	if _player == null:
		return
	var health: HealthComponent = _player.health()
	if health != null:
		health.health_changed.connect(_on_health_changed)
		_on_health_changed(health.current(), health.maximum())
	var stamina: StaminaComponent = _player.stamina()
	if stamina != null:
		stamina.changed.connect(_on_stamina_changed)
		_on_stamina_changed(stamina.current(), stamina.maximum())
	var inventory: InventoryComponent = _player.inventory()
	if inventory != null:
		inventory.arrows_changed.connect(_on_arrows_changed)
		_on_arrows_changed(inventory.arrows())
		inventory.meals_changed.connect(_on_meals_changed)
		_on_meals_changed(inventory.meal_count())
		inventory.weapon_equipped.connect(_on_weapon_changed)
	_player.interact_focus_changed.connect(_on_interact_focus_changed)
	if health != null:
		health.died.connect(_on_player_died)
	var lock: LockOnComponent = _player.lock_component()
	if lock != null:
		lock.target_acquired.connect(_on_lock_acquired)
		lock.target_released.connect(_on_lock_released)
	_bind_resonance()
	_refresh_weapon_text()


## Plaque de cible (V4.4, réf. 03) : la vie de l'ennemi verrouillé, depuis SON
## HealthComponent — connectée à l'acquisition, déconnectée au relâchement
## (règle CLAUDE.md : déconnecter les signaux dynamiques).
func _on_lock_acquired(target: Node3D) -> void:
	_lock_label.visible = true
	_lock_plaque.visible = true
	_disconnect_lock_health()
	if target.has_method("health"):
		_lock_health = target.call("health") as HealthComponent
	if _lock_health != null:
		_lock_health.health_changed.connect(_on_lock_target_health)
		_on_lock_target_health(_lock_health.current(), _lock_health.maximum())
		_lock_target_bar.visible = true
	else:
		_lock_target_bar.visible = false


func _on_lock_released(_reason: StringName) -> void:
	_lock_label.visible = false
	_lock_plaque.visible = false
	_disconnect_lock_health()


func _disconnect_lock_health() -> void:
	if _lock_health != null and is_instance_valid(_lock_health) \
			and _lock_health.health_changed.is_connected(_on_lock_target_health):
		_lock_health.health_changed.disconnect(_on_lock_target_health)
	_lock_health = null


func _on_lock_target_health(current: float, maximum: float) -> void:
	_lock_target_bar.max_value = maximum
	_lock_target_bar.value = current


func _notification(what: int) -> void:
	# Reprise de focus : ré-appliquer l'état voulu — perdre puis reprendre le
	# focus ne doit jamais laisser une caméra morte (PT-D1-02).
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_apply_mouse_mode()


func _input(event: InputEvent) -> void:
	# L'écran de mort est MODAL (QA-D1R-03) : ni pause ni inventaire par-dessus,
	# et jamais de recapture souris sous une UI à cliquer. Ses propres boutons
	# (Réessayer / Menu, focus posé) restent la seule issue — clavier compris.
	if _death_panel.visible:
		return
	if event.is_action_pressed("pause", false, true):
		# Ordre du plus imbriqué au moins imbriqué : Échap ferme d'abord ce qui
		# est OUVERT PAR-DESSUS. Sans ces deux premières branches, la cuisine et
		# la table des commandes étaient des culs-de-sac au clavier — l'arbre
		# est en pause mais le panneau de pause est caché, donc `toggle_pause()`
		# ne trouvait aucune branche vraie et ne faisait rien. Seul un clic à la
		# souris sortait de là ; un joueur pouvait croire le jeu planté.
		if is_controls_open():
			_on_controls_closed()
		elif is_cooking_open():
			close_cooking()
		elif _inventory_panel.visible:
			toggle_inventory()
		else:
			toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("inventory", false, true):
		if not _pause_panel.visible:
			toggle_inventory()
			get_viewport().set_input_as_handled()
		return
	# Clic dans la fenêtre pendant le jeu : recapture (curseur échappé).
	if not is_paused() and _mouse_captured_wanted \
			and event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_apply_mouse_mode()


func _process(delta: float) -> void:
	if _fade_rect.modulate.a > 0.0:
		_fade_rect.modulate.a = maxf(0.0, _fade_rect.modulate.a - delta * 1.6)
	if _player == null or not is_instance_valid(_player):
		return
	_reticle.visible = _player.is_aiming()
	# Le viseur de Résonance suit la visée : rafraîchi CHAQUE frame, contrairement
	# aux textes du HUD. Le tracé, lui, n'est refait qu'au changement d'état.
	_refresh_resonance_hud(delta)
	_hud_refresh_accumulator += delta
	if _hud_refresh_accumulator >= HUD_TEXT_REFRESH:
		_hud_refresh_accumulator = 0.0
		_refresh_weapon_text()
		_refresh_buff_label()
		_refresh_boss_bar()


## ---------------------------------------------------------------------------
## Pause et inventaire — les deux suspendent le monde
## ---------------------------------------------------------------------------

func toggle_pause() -> void:
	if _death_panel.visible:
		return  # modal (QA-D1R-03) — la garde tient aussi hors du chemin _input
	if is_paused() and _pause_panel.visible:
		_on_resume()
	elif not is_paused():
		get_tree().paused = true
		_pause_panel.visible = true
		HudStyle.play_ui(_ui_audio, &"open")
		_set_mouse_captured(false)
		_resume_button.grab_focus()
		var game_state: Node = get_node_or_null("/root/GameState")
		if game_state != null:
			game_state.call("set_paused", true)
		pause_toggled.emit(true)


## ---------------------------------------------------------------------------
## Commandes accessibles EN PARTIE (friction de playtest : « j'ai oublié la
## touche de l'inventaire »).
##
## La table des commandes existait déjà — dans `OptionsPanel`, que seul le menu
## principal instanciait. Un joueur qui lançait directement une partie n'avait
## donc aucun moyen d'apprendre qu'il existe un saut, une esquive, un
## inventaire ou un plat rapide : l'information qui débloque était derrière la
## porte que le blocage empêche d'atteindre. On rouvre cette porte sans
## dupliquer une seule ligne de contenu.
## ---------------------------------------------------------------------------

func _build_controls_button() -> void:
	var column: Node = _resume_button.get_parent()
	if column == null:
		return
	_controls_button = Button.new()
	_controls_button.name = "ControlsButton"
	_controls_button.text = Textes.t("menu.pause.commandes")
	_controls_button.custom_minimum_size = Vector2(320, 44)
	# Même livrée que ses voisins de colonne — il était le seul bouton gris.
	HudStyle.style_button(_controls_button)
	HudStyle.wire_button_feedback(_controls_button, _ui_audio)
	_controls_button.pressed.connect(open_controls)
	column.add_child(_controls_button)
	# Juste sous « Reprendre » : c'est la deuxième chose qu'on cherche quand on
	# ouvre la pause, avant les réglages.
	column.move_child(_controls_button, _resume_button.get_index() + 1)


func open_controls() -> void:
	if _controls_panel != null and is_instance_valid(_controls_panel):
		return
	_controls_panel = OptionsPanel.new()
	_controls_panel.name = "ControlsPanel"
	_controls_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_controls_panel.closed.connect(_on_controls_closed)
	# Ajouté en dernier enfant de la coquille : il passe au-dessus du panneau de
	# pause sans introduire un second CanvasLayer à ordonner.
	add_child(_controls_panel)


func is_controls_open() -> bool:
	return _controls_panel != null and is_instance_valid(_controls_panel)


func _on_controls_closed() -> void:
	if _controls_panel != null and is_instance_valid(_controls_panel):
		_controls_panel.queue_free()
	_controls_panel = null
	# Le joueur revient sur la pause : lui rendre le focus, sinon le clavier et
	# la manette n'ont plus de propriétaire et ne répondent plus.
	if _pause_panel.visible and _resume_button != null:
		_resume_button.grab_focus()


func is_paused() -> bool:
	return get_tree().paused


func _on_resume() -> void:
	get_tree().paused = false
	_pause_panel.visible = false
	HudStyle.play_ui(_ui_audio, &"back")
	_set_mouse_captured(true)
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_paused", false)
	pause_toggled.emit(false)


## Inventaire (§11.3, §13.4 : le monde est réellement en pause pendant qu'on y
## navigue — aucune minuterie de gameplay ne court).
func toggle_inventory() -> void:
	if _death_panel.visible:
		return  # modal (QA-D1R-03)
	if _inventory_panel.visible:
		_inventory_panel.visible = false
		HudStyle.play_ui(_ui_audio, &"back")
		get_tree().paused = false
		_set_mouse_captured(true)
	elif not is_paused():
		_selected_slot = 0
		_rebuild_inventory_panel()
		_inventory_panel.visible = true
		HudStyle.play_ui(_ui_audio, &"open")
		get_tree().paused = true
		_set_mouse_captured(false)


func is_inventory_open() -> bool:
	return _inventory_panel.visible


func _on_quit_to_menu() -> void:
	# Dépauser AVANT la transition : SceneFlow gère sa propre pause de fondu.
	get_tree().paused = false
	_set_mouse_captured(false)
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow != null and bool(flow.call("can_go_to", "res://scenes/ui/MainMenu.tscn")):
		flow.call("go_to", "res://scenes/ui/MainMenu.tscn")


## ---------------------------------------------------------------------------
## Panneau d'inventaire (PT-D1-03 : équiper, sélectionner, réordonner)
## ---------------------------------------------------------------------------

## Grille 2 × 4 (réf. 04) : huit cartes, cases vides VISIBLES avec emblème
## estompé — jamais une liste tronquée qui cacherait la capacité réelle.
func _rebuild_inventory_panel() -> void:
	for child: Node in _inventory_grid.get_children():
		child.queue_free()
	if _player == null or _player.inventory() == null:
		return
	var inventory: InventoryComponent = _player.inventory()
	var weapons: Array[WeaponInstance] = inventory.weapons()
	_selected_slot = clampi(_selected_slot, 0, maxi(0, weapons.size() - 1))
	for i: int in range(InventoryComponent.MAX_WEAPONS):
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(168, 64)
		button.toggle_mode = true
		# Livrée générique D'ABORD, spécificités de carte ENSUITE — dans l'autre
		# ordre, style_button écraserait l'état « sélectionné » de la grille.
		HudStyle.style_button(button)
		HudStyle.wire_button_feedback(button, _ui_audio)
		button.add_theme_stylebox_override(&"normal", HudStyle.plaque(0.3))
		var selected_style: StyleBoxFlat = HudStyle.plaque(1.0)
		selected_style.border_color = HudStyle.GOLD
		selected_style.set_border_width_all(2)
		button.add_theme_stylebox_override(&"pressed", selected_style)
		if i < weapons.size():
			var weapon: WeaponInstance = weapons[i]
			var definition: WeaponDefinition = weapon.definition
			var marker: String = "▶ " if weapon == inventory.equipped() else ""
			button.text = "%s%s\n%d/%d" % [marker, definition.display_name,
				weapon.current_durability, definition.max_durability]
			if definition.icon != null:
				# ART-P0 : icône RENDUE depuis le vrai modèle (jamais dessinée).
				button.icon = definition.icon
				button.expand_icon = true
				button.add_theme_constant_override(&"icon_max_width", 44)
			var slot: int = i
			button.pressed.connect(func() -> void:
				_selected_slot = slot
				_refresh_slot_selection())
		else:
			button.text = "◇"
			button.disabled = true
		_inventory_grid.add_child(button)
	_refresh_slot_selection()
	# Sans propriétaire de focus, Godot n'a rien à déplacer : les flèches du
	# clavier et la manette restent MORTES tant qu'on n'a pas cliqué à la
	# souris. Le panneau de pause, lui, posait bien son focus — l'inventaire
	# l'avait simplement oublié.
	var first: Node = _inventory_grid.get_child(0) if _inventory_grid.get_child_count() > 0 else null
	var focusable: Button = first as Button
	if focusable != null and not focusable.disabled:
		focusable.grab_focus()


func _refresh_slot_selection() -> void:
	var buttons: Array[Node] = _inventory_grid.get_children()
	for i: int in range(buttons.size()):
		var button: Button = buttons[i] as Button
		if button != null and not button.is_queued_for_deletion():
			button.button_pressed = i == _selected_slot
	_refresh_detail()


## Panneau de détail (réf. 04) : chaque valeur vient de la DÉFINITION et de
## l'INSTANCE sélectionnées — rien n'est recopié en dur dans l'interface.
func _refresh_detail() -> void:
	if _player == null or _player.inventory() == null:
		return
	var weapons: Array[WeaponInstance] = _player.inventory().weapons()
	if _selected_slot < 0 or _selected_slot >= weapons.size():
		_detail_name.text = "—"
		_detail_stats.text = ""
		_detail_conductivity.value = 0.0
		_detail_icon.texture = null
		return
	var weapon: WeaponInstance = weapons[_selected_slot]
	var definition: WeaponDefinition = weapon.definition
	_detail_icon.texture = definition.icon
	_detail_icon.visible = definition.icon != null
	_detail_name.text = definition.display_name.to_upper()
	_detail_stats.text = Textes.t("inventaire.detail.stats") % [
		definition.base_damage, definition.reach_m,
		weapon.current_durability, definition.max_durability]
	_detail_conductivity.value = definition.conductivity


func _on_equip_selected() -> void:
	if _player == null or _player.inventory() == null:
		return
	_player.inventory().equip_index(_selected_slot)
	_rebuild_inventory_panel()
	_refresh_weapon_text()


func _move_selected(offset: int) -> void:
	if _player == null or _player.inventory() == null:
		return
	var target: int = _selected_slot + offset
	if _player.inventory().move_weapon(_selected_slot, target):
		_selected_slot = target
		_rebuild_inventory_panel()


## Seam de test : équipe une case comme si le bouton avait été pressé.
func equip_slot(index: int) -> void:
	_selected_slot = index
	_on_equip_selected()


## ---------------------------------------------------------------------------
## HUD — les composants parlent, la coquille affiche
## ---------------------------------------------------------------------------

func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	# Fragments de rubis (V4.4) : chaque éclat porte une part égale du maximum,
	# le dernier entamé se vide partiellement (réf. 03).
	var per_shard: float = maximum / float(RUBY_SHARDS)
	for i: int in range(_ruby_shards.size()):
		_ruby_shards[i].max_value = per_shard
		_ruby_shards[i].value = clampf(current - per_shard * float(i), 0.0, per_shard)


func _on_stamina_changed(current: float, maximum: float) -> void:
	_stamina_bar.max_value = maximum
	_stamina_bar.value = current
	# Réf. 03 : « près du personnage PENDANT son utilisation » — la jauge
	# n'occupe l'écran que quand l'endurance travaille.
	_stamina_bar.visible = current < maximum - 0.5


func _on_arrows_changed(count: int) -> void:
	_arrows_label.text = Textes.t("hud.fleches") % count


## Réserve de plats. Elle n'était affichée NULLE PART : on pouvait cuisiner,
## lire « Cuisiné : Confit paratonnerre », puis ne plus jamais retrouver le
## plat ni deviner qu'une touche le mange. La touche est rappelée dans la
## ligne elle-même — c'est la seule place du HUD où elle peut être vue au
## moment où elle sert.
func _on_meals_changed(count: int) -> void:
	if _meals_label == null or not is_instance_valid(_meals_label):
		return
	_meals_label.text = Textes.t("hud.plats") % count
	_meals_label.visible = count > 0


func _on_weapon_changed(_weapon: WeaponInstance) -> void:
	_refresh_weapon_text()
	if _inventory_panel.visible:
		_rebuild_inventory_panel()


func _refresh_weapon_text() -> void:
	if _player == null or _player.inventory() == null:
		return
	var weapon: WeaponInstance = _player.inventory().equipped()
	if weapon == null or weapon.definition == null:
		_weapon_label.text = Textes.t("hud.arme.mains_nues")
		for segment: ProgressBar in _durability_segments:
			segment.value = 0.0
		return
	_weapon_label.text = "%s  %d/%d" % [weapon.definition.display_name,
		weapon.current_durability, weapon.definition.max_durability]
	# Durabilité SEGMENTÉE (réf. 03) : fraction réelle répartie sur 4 crans.
	var fraction: float = float(weapon.current_durability) \
		/ float(weapon.definition.max_durability) * float(DURABILITY_SEGMENTS)
	for i: int in range(_durability_segments.size()):
		_durability_segments[i].value = clampf(fraction - float(i), 0.0, 1.0)


func _on_interact_focus_changed(target: Node3D) -> void:
	if target == null or not target.has_method("prompt_verb"):
		_prompt_label.text = ""
		_prompt_panel.visible = false
		return
	var verb: String = String(target.call("prompt_verb"))
	_prompt_label.text = "" if verb == "" \
		else Textes.t("hud.invite.format") % verb
	_prompt_panel.visible = _prompt_label.text != ""


## ISS-075 — LE SEUL ENDROIT OÙ UNE CLÉ DEVIENT DU FRANÇAIS.
##
## Placé ici et pas chez les émetteurs pour une raison concrète :
## le script qui libère le camp braise est GELÉ, donc son annonce ne peut pas
## appeler `Textes.t()`. Il publie la CLÉ sur EventBus, et la traduction se
## fait au dernier moment, devant l'écran.
##
## (Citation ABRÉGÉE à dessein : `test_aucune_reference_croisee_interdite` est
## un contrôle TEXTUEL — il refuse le mot lui-même dans un fichier V1, pas
## seulement la dépendance. Desserrer le contrôle pour faire passer mon propre
## changement serait le contournement de seuil qu'interdit PROMPT4_METHOD. Le
## précédent est `static_resource_caches.gd`, qui a abrégé pour la même
## raison.)
##
## `traduire_si_cle()` et non `t()` : les ~200 textes joueur encore écrits en
## dur passent inchangés. C'est ce qui rend la migration progressive au lieu
## d'un basculement d'un seul tenant que personne ne saurait relire.
func _on_notification(text: String) -> void:
	var label: Label = Label.new()
	label.text = Textes.traduire_si_cle(text)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	label.add_theme_stylebox_override(&"normal", HudStyle.plaque(0.35))
	_notifications.add_child(label)
	while _notifications.get_child_count() > MAX_NOTIFICATIONS:
		_notifications.get_child(0).free()
	var timer: Timer = Timer.new()
	timer.wait_time = NOTIFICATION_LIFETIME
	timer.one_shot = true
	timer.autostart = true
	label.add_child(timer)
	timer.timeout.connect(label.queue_free)


func notification_texts() -> Array[String]:
	var texts: Array[String] = []
	for child: Node in _notifications.get_children():
		var label: Label = child as Label
		if label != null and not label.is_queued_for_deletion():
			texts.append(label.text)
	return texts


func prompt_text() -> String:
	return _prompt_label.text


## Somme des éclats de rubis : le seam mesure ce qui est réellement AFFICHÉ
## (V4.4), pas le modèle caché.
func hud_health() -> float:
	var total: float = 0.0
	for shard: ProgressBar in _ruby_shards:
		total += shard.value
	return total


func ruby_shard_values() -> Array[float]:
	var values: Array[float] = []
	for shard: ProgressBar in _ruby_shards:
		values.append(shard.value)
	return values


func is_stamina_gauge_visible() -> bool:
	return _stamina_bar.visible


func is_lock_plaque_visible() -> bool:
	return _lock_plaque.visible


func lock_target_health_shown() -> float:
	return _lock_target_bar.value


func durability_segment_values() -> Array[float]:
	var values: Array[float] = []
	for segment: ProgressBar in _durability_segments:
		values.append(segment.value)
	return values


func inventory_card_count() -> int:
	var count: int = 0
	for child: Node in _inventory_grid.get_children():
		if not child.is_queued_for_deletion():
			count += 1
	return count


func detail_name_text() -> String:
	return _detail_name.text


func detail_stats_text() -> String:
	return _detail_stats.text


func detail_conductivity_shown() -> float:
	return _detail_conductivity.value


func hud_stamina() -> float:
	return _stamina_bar.value


## ---------------------------------------------------------------------------
## Mort et secours (D.1R.4, PT-D1-04)
## ---------------------------------------------------------------------------

## La mort affiche un vrai choix — plus jamais « fermer et relancer ».
func _on_player_died(_event: DamageEvent) -> void:
	# Petit délai : laisser la chute du corps se voir avant l'écran.
	var timer: Timer = Timer.new()
	timer.wait_time = 1.2
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(func() -> void:
		_death_panel.visible = true
		_set_mouse_captured(false)
		_retry_button.grab_focus()
		timer.queue_free())


## Seam de test : quel joueur ce shell sert-il réellement ?
func bound_player() -> PlayerController:
	return _player


func is_death_panel_open() -> bool:
	return _death_panel.visible


## Cible du bouton « Réessayer » — exposée pour les tests : la transition
## réelle s'exécute sur poste, le choix de la cible se prouve ici.
func retry_target() -> String:
	return world_scene_path


func _on_retry() -> void:
	get_tree().paused = false
	var game_state: Node = get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.call("set_pending_spawn", &"retry_checkpoint")
	var flow: Node = get_node_or_null("/root/SceneFlow")
	if flow != null and bool(flow.call("can_go_to", world_scene_path)):
		flow.call("go_to", world_scene_path)


## Fondu bref après un repêchage de chute (§14.3 : lisible, jamais punitif).
func play_rescue_fade() -> void:
	_fade_rect.modulate.a = 1.0


## ---------------------------------------------------------------------------
## Souris et sensibilité
## ---------------------------------------------------------------------------

func wants_mouse_captured() -> bool:
	return _mouse_captured_wanted


func _set_mouse_captured(captured: bool) -> void:
	# Ceinture et bretelles (QA-D1R-03) : tant que l'écran de mort est affiché,
	# AUCUN chemin ne peut avaler le curseur.
	_mouse_captured_wanted = captured and not _death_panel.visible
	_apply_mouse_mode()


func _apply_mouse_mode() -> void:
	var capture: bool = _mouse_captured_wanted and not get_tree().paused
	var was_captured: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if capture:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# LE PREMIER CLIC N'EST PLUS PERDU.
	#
	# Pendant la capture, le curseur système reste figé là où il se trouvait —
	# souvent contre un bord d'écran. En rendant la main, Godot le rend visible
	# À CET ENDROIT : le premier clic du joueur part donc dans le vide, loin du
	# panneau qui vient de s'ouvrir. Symptôme rapporté au playtest du
	# 2026-08-07 : « Slider sensibilité : ne réagit pas au 1er clic ». On repose
	# le curseur au centre de la fenêtre, où le panneau est effectivement.
	if was_captured:
		var window: Window = get_window()
		if window != null:
			window.warp_mouse(Vector2(window.size) * 0.5)


func _on_sensitivity_changed(value: float) -> void:
	UserSettings.save_mouse_sensitivity(value)
	_refresh_sensitivity_label(value)
	for node: Node in get_tree().get_nodes_in_group("player"):
		var player: PlayerController = node as PlayerController
		if player != null:
			var reader: PlayerInputReader = \
				player.get_node_or_null("Components/PlayerInputReader") as PlayerInputReader
			if reader != null:
				reader.set_mouse_sensitivity(value)


func _refresh_sensitivity_label(value: float) -> void:
	_sensitivity_value.text = Textes.t("menu.pause.sensibilite") % value


## Seam de test : applique une valeur comme si le curseur avait bougé.
func set_sensitivity(value: float) -> void:
	_sensitivity_slider.value = UserSettings.clamp_sensitivity(value)


## ---------------------------------------------------------------------------
## E.2b — Atelier de cuisine (§13.3) : sélection 1 à 5, aperçu honnête
## (nom de famille et soin — pas les valeurs secrètes), confirmation
## ATOMIQUE : place à plats et stocks revérifiés AVANT tout retrait,
## puis retrait complet et plat, ou rien du tout. Annuler ne coûte
## rien : la sélection n'est qu'un plan, rien n'est retiré avant la
## confirmation. L'UI est construite en code, comme le style V4.
## ---------------------------------------------------------------------------

const COOKING_MAX_SELECTION: int = 5
## ISS-075 : les valeurs sont des CLÉS de la table de textes, résolues à
## l'affichage — le français vit dans resources/localisation/fr.json.
const BUFF_LABELS: Dictionary[StringName, String] = {
	&"attack": "hud.buff.attaque",
	&"defense": "hud.buff.defense",
	&"stamina": "hud.buff.endurance",
	&"elec_resist": "hud.buff.resist_elec",
}

var _cooking_panel: PanelContainer = null
var _cooking_stock: VBoxContainer = null
var _cooking_selection_label: Label = null
var _cooking_preview: Label = null
var _cooking_confirm: Button = null
var _cooking_selection: Array[StringName] = []
var _buff_label: Label = null


func _build_cooking_panel() -> void:
	_cooking_panel = PanelContainer.new()
	_cooking_panel.name = "CookingPanel"
	_cooking_panel.visible = false
	_cooking_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_cooking_panel.add_theme_stylebox_override(&"panel", HudStyle.plaque(0.92))
	var column: VBoxContainer = VBoxContainer.new()
	column.custom_minimum_size = Vector2(430, 0)
	column.add_theme_constant_override(&"separation", 10)
	_cooking_panel.add_child(column)
	var title: Label = Label.new()
	title.text = Textes.t("cuisine.titre")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override(&"font_color", HudStyle.GOLD)
	title.add_theme_font_size_override(&"font_size", 26)
	column.add_child(title)
	_cooking_stock = VBoxContainer.new()
	_cooking_stock.name = "Stock"
	column.add_child(_cooking_stock)
	_cooking_selection_label = Label.new()
	column.add_child(_cooking_selection_label)
	_cooking_preview = Label.new()
	_cooking_preview.add_theme_color_override(&"font_color", HudStyle.GOLD)
	column.add_child(_cooking_preview)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	column.add_child(row)
	_cooking_confirm = Button.new()
	_cooking_confirm.name = "CookingConfirm"
	_cooking_confirm.text = Textes.t("cuisine.confirmer")
	HudStyle.style_button(_cooking_confirm)
	_cooking_confirm.pressed.connect(cooking_confirm)
	row.add_child(_cooking_confirm)
	var remove_button: Button = Button.new()
	remove_button.name = "CookingRemoveLast"
	remove_button.text = Textes.t("cuisine.retirer_dernier")
	HudStyle.style_button(remove_button)
	HudStyle.wire_button_feedback(remove_button, _ui_audio)
	remove_button.pressed.connect(cooking_remove_last)
	row.add_child(remove_button)
	var cancel: Button = Button.new()
	cancel.name = "CookingCancel"
	cancel.text = Textes.t("cuisine.reprendre")
	HudStyle.style_button(cancel)
	cancel.pressed.connect(close_cooking)
	row.add_child(cancel)
	add_child(_cooking_panel)
	_cooking_panel.set_anchors_preset(Control.PRESET_CENTER)


## Ouvre l'atelier — vrai si ouvert. Le monde est réellement en pause
## (§13.3 : aucune minuterie de gameplay ne court pendant la cuisine).
func open_cooking(_who: Node) -> bool:
	if _death_panel.visible or is_paused() or _player == null \
			or _player.inventory() == null:
		return false
	_cooking_selection.clear()
	_rebuild_cooking_panel()
	_cooking_panel.visible = true
	HudStyle.play_ui(_ui_audio, &"open")
	get_tree().paused = true
	_set_mouse_captured(false)
	return true


## Annuler rend toujours les ingrédients (§13.3) : rien n'a été retiré.
func close_cooking() -> void:
	_close_cooking(&"back")


## Fermeture partagée — le son dit l'ISSUE : retour (annulé) ou confirmation.
## Un seul lecteur d'UI : deux `play_ui` successifs se couperaient l'un l'autre.
func _close_cooking(sound: StringName) -> void:
	_cooking_selection.clear()
	_cooking_panel.visible = false
	HudStyle.play_ui(_ui_audio, sound)
	get_tree().paused = false
	_set_mouse_captured(true)


func is_cooking_open() -> bool:
	return _cooking_panel != null and _cooking_panel.visible


## Ajoute un ingrédient au plan de cuisson — refuse au-delà de 5 ou du
## stock réellement possédé.
func cooking_add(id: StringName) -> bool:
	if _cooking_selection.size() >= COOKING_MAX_SELECTION:
		return false
	if _player.inventory().ingredient_count(id) <= _cooking_selection.count(id):
		return false
	_cooking_selection.append(id)
	_rebuild_cooking_panel()
	return true


func cooking_remove_last() -> void:
	if not _cooking_selection.is_empty():
		_cooking_selection.pop_back()
		_rebuild_cooking_panel()


func cooking_preview_text() -> String:
	return _cooking_preview.text if _cooking_preview != null else ""


func cooking_selection_size() -> int:
	return _cooking_selection.size()


func cooking_confirm() -> void:
	if _cooking_selection.is_empty() or _player == null:
		return
	var inventory: InventoryComponent = _player.inventory()
	if inventory.meal_count() >= InventoryComponent.MAX_MEALS:
		_on_notification("cuisine.reserve_pleine")
		HudStyle.play_ui(_ui_audio, &"error")
		return
	var needed: Dictionary = {}
	for id: StringName in _cooking_selection:
		needed[id] = int(needed.get(id, 0)) + 1
	for id: StringName in needed:
		if inventory.ingredient_count(id) < int(needed[id]):
			_rebuild_cooking_panel()   # le stock a bougé : re-mesurer
			return
	var result: Dictionary = RecipeRules.cook(_cooking_definitions())
	if not bool(result.get("valid", false)):
		return
	for id: StringName in needed:
		inventory.consume_ingredients(id, int(needed[id]))
	inventory.add_meal(result)
	_on_notification(Textes.t("cuisine.fait") % _meal_display_name(result))
	_close_cooking(&"confirm")


func _cooking_definitions() -> Array[IngredientDefinition]:
	var definitions: Array[IngredientDefinition] = []
	for id: StringName in _cooking_selection:
		definitions.append(load("res://resources/ingredients/%s.tres"
			% String(id)) as IngredientDefinition)
	return definitions


## Nom affiché d'un plat cuisiné. Repli TRADUIT si le résultat ne porte pas
## de nom : RecipeRules nomme toujours ses plats aujourd'hui, mais un
## résultat hérité (sauvegarde, donnée future) ne doit jamais montrer une
## clé nue ni une ligne vide. Extrait du site de notification pour être
## pilotable — même motif que `_ingredient_display_name` ci-dessous.
func _meal_display_name(result: Dictionary) -> String:
	return String(result.get("name", Textes.t("cuisine.plat_defaut")))


## Nom lisible d'un ingrédient. Retombe sur l'identifiant si la ressource
## manque : mieux vaut un mot technique qu'une ligne vide.
func _ingredient_display_name(id: StringName) -> String:
	var definition: IngredientDefinition = load(
		"res://resources/ingredients/%s.tres" % String(id)) as IngredientDefinition
	if definition == null or definition.display_name.is_empty():
		return String(id)
	return definition.display_name


## Nom lisible d'une famille d'effet. Les clés viennent de `RecipeRules`, qui
## nomme les PLATS ; ici on nomme ce que le plat FAIT, ce qui est l'information
## dont le joueur a besoin pour décider.
func _effect_display_name(effect: String) -> String:
	match effect:
		"attack":
			return Textes.t("cuisine.effet.attack")
		"defense":
			return Textes.t("cuisine.effet.defense")
		"stamina":
			return Textes.t("cuisine.effet.stamina")
		"elec_resist":
			return Textes.t("cuisine.effet.elec_resist")
		_:
			return effect


func _rebuild_cooking_panel() -> void:
	for child: Node in _cooking_stock.get_children():
		child.queue_free()
	var inventory: InventoryComponent = _player.inventory()
	for id: StringName in inventory.ingredient_ids():
		var definition: IngredientDefinition = load(
			"res://resources/ingredients/%s.tres" % String(id)) \
			as IngredientDefinition
		if definition == null:
			continue
		var stock_row: Button = Button.new()
		stock_row.text = "%s  ×%d" % [definition.display_name,
			inventory.ingredient_count(id)]
		HudStyle.style_button(stock_row)
		HudStyle.wire_button_feedback(stock_row, _ui_audio)
		stock_row.pressed.connect(cooking_add.bind(id))
		_cooking_stock.add_child(stock_row)
	if _cooking_selection.is_empty():
		_cooking_selection_label.text = Textes.t("cuisine.choisir")
	else:
		var names: Array[String] = []
		for id: StringName in _cooking_selection:
			# Le nom AFFICHÉ, pas l'identifiant interne : la liste du stock,
			# juste au-dessus, dit « Baie de résistance » — la ligne de
			# sélection disait `storm_berry`. Deux vocabulaires pour un même
			# objet, dans le même panneau.
			names.append(_ingredient_display_name(id))
		_cooking_selection_label.text = Textes.t("cuisine.choisir_compte") % [
			_cooking_selection.size(), ", ".join(names)]
	var result: Dictionary = RecipeRules.cook(_cooking_definitions())
	if bool(result.get("valid", false)):
		# `cook()` calcule déjà l'effet, sa puissance et sa durée ; l'aperçu les
		# jetait et n'affichait que le soin. Le joueur lisait « soigne 5 PV »,
		# concluait que cuisiner ne sert à rien, et n'apprenait jamais que ce
		# plat est ce qui le protège de la foudre du boss. §13.3 demande la
		# CATÉGORIE de résultat avant confirmation : la voici.
		var line: String = Textes.t("cuisine.apercu.soin") % [
			String(result.get("name", "")), int(result.get("heal", 0.0))]
		var effect: String = String(result.get("effect", ""))
		var duration: float = float(result.get("duration", 0.0))
		if not effect.is_empty() and duration > 0.0:
			line += Textes.t("cuisine.apercu.effet") % [
				_effect_display_name(effect), int(round(duration))]
		if bool(result.get("unstable", false)):
			line += Textes.t("cuisine.apercu.instable")
		_cooking_preview.text = line
	else:
		_cooking_preview.text = "—"
	_cooking_confirm.disabled = _cooking_selection.is_empty()


## ---------------------------------------------------------------------------
## E.2b — label de buff au HUD : famille + secondes restantes, rien sinon.
## ---------------------------------------------------------------------------

func _build_buff_label() -> void:
	_buff_label = Label.new()
	_buff_label.name = "BuffLabel"
	_buff_label.text = ""
	_buff_label.add_theme_color_override(&"font_color", HudStyle.GOLD)
	_buff_label.add_theme_font_size_override(&"font_size", 15)
	add_child(_buff_label)
	_buff_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_buff_label.offset_left = 26.0
	_buff_label.offset_top = 46.0


func _refresh_buff_label() -> void:
	if _buff_label == null or _player == null or _player.status() == null:
		return
	var effect: StringName = _player.status().active_effect()
	if effect == &"":
		_buff_label.text = ""
		return
	var nom: String = Textes.t(BUFF_LABELS[effect]) \
		if BUFF_LABELS.has(effect) else String(effect)
	_buff_label.text = Textes.t("hud.buff.format") % [nom,
		int(ceilf(_player.status().remaining()))]


func buff_label_text() -> String:
	return _buff_label.text if _buff_label != null else ""


## ---------------------------------------------------------------------------
## Barre de boss (§17.2 « barre de boss », §16.1 « barre de vie ORIGINALE »)
## ---------------------------------------------------------------------------
## Un bandeau bas, large, en ardoise et or pâle : la vie du Gardien en une
## seule veine cyan, et sous elle le nom de la phase en cours. Rien n'est
## recopié — la valeur vient du `HealthComponent` du boss, le texte de sa
## machine à états. Elle n'existe que quand un boss VIVANT est dans la
## scène : ailleurs, elle ne prend pas un pixel.

## ISS-075 : des CLÉS, résolues à l'affichage — le français vit dans fr.json.
const BOSS_PHASE_LABELS: Dictionary[StringName, String] = {
	&"intro": "boss.phase.intro",
	&"phase1": "boss.phase.phase1",
	&"grounded_stun": "boss.phase.grounded_stun",
	&"transition12": "boss.phase.transition12",
	&"phase2": "boss.phase.phase2",
	&"overload": "boss.phase.overload",
	&"transition23": "boss.phase.transition23",
	&"phase3": "boss.phase.phase3",
	&"stagger": "boss.phase.stagger",
	&"dead": "boss.phase.dead",
}

var _boss_panel: PanelContainer = null
var _boss_bar: ProgressBar = null
var _boss_phase_label: Label = null
var _boss_node: Node = null


func _build_boss_bar() -> void:
	_boss_panel = PanelContainer.new()
	_boss_panel.name = "BossPlaque"
	_boss_panel.add_theme_stylebox_override(&"panel", HudStyle.plaque())
	var column: VBoxContainer = VBoxContainer.new()
	var title: Label = Label.new()
	title.name = "BossName"
	title.text = Textes.t("boss.nom")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override(&"font_color", HudStyle.GOLD)
	title.add_theme_font_size_override(&"font_size", 18)
	column.add_child(title)
	_boss_bar = ProgressBar.new()
	_boss_bar.name = "BossBar"
	_boss_bar.custom_minimum_size = Vector2(520, 12)
	_boss_bar.show_percentage = false
	_boss_bar.add_theme_stylebox_override(&"background",
		HudStyle.gauge_background(HudStyle.TURQUOISE_DARK))
	_boss_bar.add_theme_stylebox_override(&"fill",
		HudStyle.gauge_fill(HudStyle.TURQUOISE))
	column.add_child(_boss_bar)
	_boss_phase_label = Label.new()
	_boss_phase_label.name = "BossPhase"
	_boss_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_phase_label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	_boss_phase_label.add_theme_font_size_override(&"font_size", 14)
	column.add_child(_boss_phase_label)
	_boss_panel.add_child(column)
	add_child(_boss_panel)
	_boss_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_boss_panel.offset_left = -280.0
	_boss_panel.offset_right = 280.0
	_boss_panel.offset_top = -96.0
	_boss_panel.offset_bottom = -24.0
	_boss_panel.visible = false


## Le boss est cherché dans LA SCÈNE DE CETTE COQUILLE, comme le joueur :
## deux scènes chargées côte à côte (tests, transitions) ne doivent pas se
## voler leur HUD.
func _find_boss() -> Node:
	if _boss_node != null and is_instance_valid(_boss_node):
		return _boss_node
	var scene_root: Node = owner if owner != null else get_parent()
	if scene_root == null:
		return null
	for node: Node in scene_root.find_children("*", "StormGuardian", true, false):
		_boss_node = node
		return node
	return null


func _refresh_boss_bar() -> void:
	if _boss_panel == null:
		return
	var boss: Node = _find_boss()
	if boss == null:
		_boss_panel.visible = false
		return
	var health: HealthComponent = boss.call("health") as HealthComponent
	if health == null:
		_boss_panel.visible = false
		return
	var phase: StringName = StringName(String(boss.call("state_name")))
	_boss_panel.visible = phase != &"intro"
	_boss_bar.max_value = health.maximum()
	_boss_bar.value = health.current()
	_boss_phase_label.text = Textes.t(BOSS_PHASE_LABELS[phase]) \
		if BOSS_PHASE_LABELS.has(phase) else String(phase)


## Seams de test : ce que la barre affiche RÉELLEMENT.
func is_boss_bar_visible() -> bool:
	return _boss_panel != null and _boss_panel.visible


func boss_bar_value() -> float:
	return _boss_bar.value if _boss_bar != null else 0.0


func boss_phase_text() -> String:
	return _boss_phase_label.text if _boss_phase_label != null else ""


## ---------------------------------------------------------------------------
## Bracelet de Résonance — viseur, cible retenue et raison du refus (P2 §3.8)
##
## PT-BRACELET-01 (playtest) : le Bracelet n'avait AUCUNE présentation. Rien
## n'écoutait `revealed` hors de `ResonanceLab`, la cible retenue par le focus
## était invisible, l'état « premier port retenu » d'un Arc Link en deux temps
## ne se voyait pas, et un refus partait muet dans la sonde de latence — un
## instrument de MESURE que seul un overlay de laboratoire affiche. Résultat :
## un joueur ne pouvait ni viser, ni comprendre un échec, ni distinguer « rien
## n'est parti » de « c'est parti et je n'ai pas vu la conséquence ».
##
## Ce bloc fournit le minimum exigé par P2 §3.8 : « source, port sélectionné et
## destination visuellement distincts », « ligne prévue avant confirmation »,
## « raison courte en cas de refus ». Il ne change AUCUNE règle du Bracelet :
## il lit un état déjà calculé et le montre.
## ---------------------------------------------------------------------------

## Ce que le clic gauche déclenchera, par nature de cible — la seule chose que
## le joueur ne peut pas deviner puisque la même touche sert les quatre.
## ISS-075 : des CLÉS, résolues à l'affichage — le français vit dans fr.json.
const RESONANCE_ACTIONS: Dictionary[StringName, String] = {
	&"port": "resonance.action.port",
	&"polarity": "resonance.action.polarity",
	&"material": "resonance.action.material",
	&"arc_anchor": "resonance.action.arc_anchor",
}

## Verdicts de `ResonanceController` traduits en une phrase courte. Un verdict
## absent de cette table s'affiche tel quel : mieux vaut un mot brut qu'un
## silence — c'est le silence qui a coûté le playtest.
const RESONANCE_REFUSALS: Dictionary[StringName, String] = {
	&"cooldown": "resonance.refus.cooldown",
	&"aucune_cible": "resonance.refus.aucune_cible",
	&"invalide": "resonance.refus.invalide",
	&"hors_portee": "resonance.refus.hors_portee",
	&"trop_loin": "resonance.refus.trop_loin",
	&"pas_de_vue": "resonance.refus.pas_de_vue",
	&"pas_metal": "resonance.refus.pas_metal",
	&"pas_charge": "resonance.refus.pas_charge",
	&"trop_lourd": "resonance.refus.trop_lourd",
	&"pas_de_charge": "resonance.refus.pas_de_charge",
	&"pas_au_sol": "resonance.refus.pas_au_sol",
	&"occupe": "resonance.refus.occupe",
	&"obstacle": "resonance.refus.obstacle",
	&"pas_de_sol": "resonance.refus.pas_de_sol",
	&"endurance": "resonance.refus.endurance",
	&"cible_perdue": "resonance.refus.cible_perdue",
	&"interrompu": "resonance.refus.interrompu",
}

## Durée d'affichage d'un message de verdict. Assez long pour être lu en
## jouant, assez court pour ne pas rester en travers de l'écran.
const RESONANCE_MESSAGE_LIFETIME: float = 2.5

var _resonance_overlay: ResonanceOverlay = null
var _resonance_plaque: PanelContainer = null
var _resonance_action_label: Label = null
var _resonance_state_label: Label = null
var _resonance: ResonanceController = null
var _resonance_message: String = ""
var _resonance_message_timer: float = 0.0
var _resonance_message_refused: bool = false


func _build_resonance_hud() -> void:
	_resonance_overlay = ResonanceOverlay.new()
	_resonance_overlay.name = "ResonanceOverlay"
	add_child(_resonance_overlay)

	_resonance_plaque = PanelContainer.new()
	_resonance_plaque.name = "ResonancePlaque"
	_resonance_plaque.add_theme_stylebox_override(&"panel", HudStyle.plaque())
	_resonance_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column: VBoxContainer = VBoxContainer.new()
	_resonance_action_label = Label.new()
	_resonance_action_label.name = "ResonanceAction"
	_resonance_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resonance_action_label.add_theme_color_override(&"font_color", HudStyle.GOLD)
	_resonance_action_label.add_theme_font_size_override(&"font_size", 16)
	column.add_child(_resonance_action_label)
	_resonance_state_label = Label.new()
	_resonance_state_label.name = "ResonanceState"
	_resonance_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resonance_state_label.add_theme_color_override(&"font_color", HudStyle.IVORY)
	_resonance_state_label.add_theme_font_size_override(&"font_size", 14)
	column.add_child(_resonance_state_label)
	_resonance_plaque.add_child(column)
	add_child(_resonance_plaque)
	# Sous le viseur, jamais dessus : la plaque explique, elle ne masque pas.
	_resonance_plaque.set_anchors_preset(Control.PRESET_CENTER)
	_resonance_plaque.offset_left = -280.0
	_resonance_plaque.offset_right = 280.0
	_resonance_plaque.offset_top = 44.0
	_resonance_plaque.offset_bottom = 104.0
	_resonance_plaque.visible = false


## Branche les signaux que PERSONNE n'écoutait. Ils existaient déjà, typés, dans
## `ResonanceController` : ce sont eux la présentation promise par ses commentaires.
func _bind_resonance() -> void:
	if _player == null:
		return
	_player.resonance_verdict.connect(_on_resonance_verdict)
	_resonance = _player.resonance()
	if _resonance == null:
		return
	_resonance.pulse_fired.connect(_on_resonance_pulse)
	_resonance.link_dissolved.connect(_on_resonance_link_dissolved)
	_resonance.ground_completed.connect(_on_resonance_grounded)
	_resonance.ground_cancelled.connect(_on_resonance_ground_cancelled)


func _announce_resonance(message: String, refused: bool) -> void:
	_resonance_message = message
	_resonance_message_refused = refused
	_resonance_message_timer = RESONANCE_MESSAGE_LIFETIME
	# P2 §3.8 : « son unique par succès, incompatibilité… » — le refus
	# s'entend en plus de la barre du viseur ; jamais la couleur seule.
	if refused:
		HudStyle.play_ui(_ui_audio, &"error")


func _on_resonance_verdict(_action: StringName, verdict: StringName,
		executed: bool) -> void:
	if not executed:
		var reason: String = String(verdict)
		if RESONANCE_REFUSALS.has(verdict):
			reason = Textes.t(RESONANCE_REFUSALS[verdict])
		_announce_resonance(reason, true)
		return
	# `port_a` est une ÉTAPE, pas une fin : l'état permanent est porté par la
	# plaque (`link_pending`), pas par un message qui s'efface.
	match verdict:
		&"linked":
			_announce_resonance(Textes.t("resonance.message.lien_etabli"), false)
		&"engaged":
			_announce_resonance(
				Textes.t("resonance.message.polarite_engagee"), false)
		&"step":
			# SA clé, distincte de `resonance.action.arc_anchor` : même texte
			# français aujourd'hui, mais deux contextes d'affichage (ligne
			# d'action du viseur / verdict d'exécution) doivent pouvoir se
			# traduire séparément.
			_announce_resonance(Textes.t("resonance.message.arc_step"), false)


## Le Pulse ne montrait rien du tout hors du laboratoire : au moins dire
## combien de cibles il a réellement révélées.
func _on_resonance_pulse(revealed_count: int) -> void:
	if revealed_count <= 0:
		_announce_resonance(Textes.t("resonance.message.pulse_vide"), false)
		return
	# ISS-075 : le pluriel est porté par DEUX clés — coller un « s »
	# conditionnel dans le code serait intraduisible.
	var cle: String = "resonance.message.pulse_plusieurs" \
		if revealed_count > 1 else "resonance.message.pulse_une"
	_announce_resonance(Textes.t(cle) % revealed_count, false)


func _on_resonance_link_dissolved() -> void:
	_announce_resonance(Textes.t("resonance.message.lien_rompu"), false)


func _on_resonance_grounded(_target: Node) -> void:
	_announce_resonance(Textes.t("resonance.message.terre_effectuee"), false)


func _on_resonance_ground_cancelled(reason: StringName) -> void:
	var text: String = String(reason)
	if RESONANCE_REFUSALS.has(reason):
		text = Textes.t(RESONANCE_REFUSALS[reason])
	_announce_resonance(
		Textes.t("resonance.message.terre_annulee") % text, true)


## Caméra du joueur de CETTE coquille (même règle que `_find_boss`) : deux
## scènes chargées côte à côte ne doivent pas se voler leur projection.
func _resonance_camera() -> Camera3D:
	if _player == null or not is_instance_valid(_player):
		return null
	var rig: CameraRig = _player.camera_rig()
	return rig.get_camera() if rig != null else null


func _refresh_resonance_hud(delta: float) -> void:
	if _resonance_overlay == null:
		return
	_resonance_message_timer = maxf(0.0, _resonance_message_timer - delta)
	var showing_message: bool = _resonance_message_timer > 0.0
	var focus: bool = _resonance != null and _resonance.focus_active()
	var target: ResonanceTargetComponent = null
	var pending: bool = false
	if focus:
		target = _resonance.focus_selected()
		pending = _resonance.link_pending() != null
	var on_screen: bool = false
	var at: Vector2 = Vector2.ZERO
	if target != null:
		var anchor: Node3D = target.anchor()
		var camera: Camera3D = _resonance_camera()
		if anchor != null and camera != null \
				and not camera.is_position_behind(anchor.global_position):
			at = camera.unproject_position(anchor.global_position)
			on_screen = true
	_resonance_overlay.apply_state(focus, target != null, on_screen, at, pending,
		showing_message and _resonance_message_refused)
	_resonance_plaque.visible = focus or showing_message
	if not _resonance_plaque.visible:
		return
	_set_label(_resonance_action_label, _resonance_action_line(focus, target, pending))
	_set_label(_resonance_state_label,
		_resonance_state_line(focus, target, pending, showing_message))


## Écrire un `Label` seulement quand le texte change : le HUD se rafraîchit à
## chaque frame, pas la mise en page.
func _set_label(label: Label, text: String) -> void:
	if label != null and label.text != text:
		label.text = text


func _resonance_action_line(focus: bool, target: ResonanceTargetComponent,
		pending: bool) -> String:
	if not focus or target == null:
		return Textes.t("resonance.viseur.titre")
	var action: String = String(target.kind)
	if RESONANCE_ACTIONS.has(target.kind):
		action = Textes.t(RESONANCE_ACTIONS[target.kind])
	if target.kind == &"port" and pending:
		action = Textes.t("resonance.viseur.lier")
	return Textes.t("resonance.viseur.action") % action


func _resonance_state_line(focus: bool, target: ResonanceTargetComponent,
		pending: bool, showing_message: bool) -> String:
	# Le message de verdict prime : c'est la réponse à la dernière action.
	if showing_message:
		return _resonance_message
	if pending:
		return Textes.t("resonance.viseur.port_retenu")
	if not focus:
		return ""
	if target == null:
		return Textes.t("resonance.viseur.aucune_cible")
	return ""


## --- Seams de test : ce que le viseur montre RÉELLEMENT ---

func is_resonance_plaque_visible() -> bool:
	return _resonance_plaque != null and _resonance_plaque.visible


func resonance_action_text() -> String:
	return _resonance_action_label.text if _resonance_action_label != null else ""


func resonance_state_text() -> String:
	return _resonance_state_label.text if _resonance_state_label != null else ""


func resonance_overlay() -> ResonanceOverlay:
	return _resonance_overlay
