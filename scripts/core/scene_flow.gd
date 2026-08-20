## Autoload — transitions et chargements de scène (MASTER_SPEC §5.6, §6.1).
##
## §6.1 place `FadeLayer` et `LoadingUI` dans `Boot.tscn`. Ce serait un piège :
## `Boot.tscn` est déchargé au premier changement de scène, emportant le voile de
## fondu au moment précis où il sert. Le voile est donc créé et détenu par cet
## autoload, qui survit aux transitions. Voir `docs/DECISIONS.md` D-007.
##
## Portée à la Phase A : la transition elle-même (coupure des entrées, fondu,
## chargement, remise en marche). Le chargement en arrière-plan par
## `ResourceLoader.load_threaded_request` (§20.10) et l'écran de chargement
## arrivent en Phase I, quand il y aura des scènes assez lourdes pour le justifier
## et de quoi le mesurer.
extends Node

const FADE_DURATION: float = 0.25
const FADE_LAYER_INDEX: int = 128

signal transition_started(target_path: String)
signal transition_finished(target_path: String)
signal transition_failed(target_path: String, reason: String)

var _fade_layer: CanvasLayer = null
var _fade_rect: ColorRect = null
var _busy: bool = false
var _loading_root: Control = null
var _loading_bar: ColorRect = null
var _loading_label: Label = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade_layer()


## ISS-059 — EXTINCTION DU MOTEUR : on relâche les caches statiques.
##
## Un autoload quitte l'arbre quand la `SceneTree` est détruite, c'est-à-dire à
## l'extinction du processus et AVANT que le moteur ne compte ses fuites. C'est
## le seul point du projet où l'on sait que plus personne n'utilisera les caches
## de ressources — et ils n'avaient jusqu'ici aucun propriétaire pour le dire.
##
## Ce n'est pas un nettoyage de confort : sans lui, une seule montée de
## `WorldV2.tscn` laisse `281 DummyMaterial` et `214 DummyMesh` au rapport de
## sortie, alors que le nœud est bien libéré. Mesure et ablation à variable
## unique : `evidence/…/v2_3_r2b3_1/iss059/CHAINE_CAUSALE.md`.
##
## `SceneFlow` porte l'appel parce qu'il est l'autoload qui décide de ce qui est
## chargé et quand — c'est le propriétaire naturel de la fin de vie de ce qui
## a été chargé pour le monde.
func _exit_tree() -> void:
	StaticResourceCaches.liberer_tout()


func is_busy() -> bool:
	return _busy


## Décision de transition, isolée de son exécution et de sa journalisation.
##
## Séparer les deux permet aux tests de vérifier la règle sans déclencher le
## `push_error` de production : le niveau 2b de `validate_fast.sh` traite tout
## `ERROR:` du journal comme un échec, et il a raison — une erreur attendue par un
## test ne doit pas apprendre au harnais à ignorer les erreurs.
func can_go_to(target_path: String) -> bool:
	if _busy:
		return false
	return ResourceLoader.exists(target_path)


## Change de scène avec fondu. Idempotente vis-à-vis des appels concurrents : une
## seconde demande pendant une transition est refusée plutôt que superposée, ce
## qui laisserait deux scènes actives.
func go_to(target_path: String) -> bool:
	if not can_go_to(target_path):
		if _busy:
			push_warning("[flow] transition déjà en cours, demande ignorée : %s" % target_path)
		else:
			_fail(target_path, "scène introuvable")
		return false

	_busy = true
	transition_started.emit(target_path)

	get_tree().paused = true
	await _fade_to(1.0)

	# Une frame complète AVANT de changer de scène, toujours. `go_to()` est
	# souvent appelée depuis le `_ready()` de la scène courante : l'arbre est
	# alors en train d'ajouter des enfants et refuse `remove_child()`
	# (« Parent node is busy adding/removing children »). En mode headless le
	# fondu rend la main sans attendre, donc rien ne garantissait ce délai.
	await get_tree().process_frame

	var err: Error = await _load_and_swap(target_path)
	if err != OK:
		_hide_loading()
		get_tree().paused = false
		_busy = false
		_fail(target_path, "chargement de la scène a échoué (%d)" % err)
		return false

	# Laisser la nouvelle scène s'installer avant de lever le voile, sinon le
	# joueur voit une frame de scène non initialisée.
	await get_tree().process_frame
	_hide_loading()
	get_tree().paused = false
	await _fade_to(0.0)

	_busy = false
	transition_finished.emit(target_path)
	return true


## Charge la scène EN ARRIÈRE-PLAN, en dessinant pendant ce temps.
##
## `change_scene_to_file()` est synchrone : elle bloque le thread principal
## pendant tout le chargement, donc aucune image ne peut être dessinée. Sur ce
## conteneur en rendu logiciel, la vallée met 25 à 65 s à se charger, et le
## joueur ne voyait qu'un écran NOIR muet, sans barre ni texte. Deux playtests
## successifs en boîte noire ont conclu au plantage et sont partis chercher des
## journaux d'erreur.
##
## `load_threaded_request()` (§20.10) rend la main à chaque frame : on peut donc
## afficher une progression réelle. `load_threaded_get()` n'est appelée qu'une
## fois la ressource PRÊTE — l'appeler plus tôt bloquerait, ce qui rendrait tout
## l'exercice inutile.
func _load_and_swap(target_path: String) -> Error:
	# En headless il n'y a rien à dessiner : le chemin synchrone est plus court
	# et n'allonge pas les tests.
	if DisplayServer.get_name() == "headless":
		return get_tree().change_scene_to_file(target_path)

	var err: Error = ResourceLoader.load_threaded_request(target_path)
	if err != OK:
		# Repli : mieux vaut un écran noir qu'une transition impossible.
		return get_tree().change_scene_to_file(target_path)

	_show_loading()
	var progress: Array = []
	while true:
		var status: ResourceLoader.ThreadLoadStatus = \
			ResourceLoader.load_threaded_get_status(target_path, progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if status == ResourceLoader.THREAD_LOAD_FAILED \
				or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			return ERR_CANT_OPEN
		if progress.size() > 0:
			_set_loading_progress(float(progress[0]))
		await get_tree().process_frame

	_set_loading_progress(1.0)
	var packed: PackedScene = ResourceLoader.load_threaded_get(target_path) as PackedScene
	if packed == null:
		return ERR_CANT_OPEN
	return get_tree().change_scene_to_packed(packed)


## L'écran de chargement vit sur le calque de fondu, AU-DESSUS du voile noir, et
## tourne en pause : sans `PROCESS_MODE_ALWAYS` il serait gelé avec l'arbre au
## moment précis où il doit informer.
func _build_loading_ui() -> void:
	_loading_root = Control.new()
	_loading_root.name = "LoadingUI"
	_loading_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_root.process_mode = Node.PROCESS_MODE_ALWAYS
	_loading_root.visible = false
	_fade_layer.add_child(_loading_root)

	_loading_label = Label.new()
	_loading_label.name = "LoadingLabel"
	_loading_label.text = "Chargement…"
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.anchor_left = 0.0
	_loading_label.anchor_right = 1.0
	_loading_label.anchor_top = 0.5
	_loading_label.anchor_bottom = 0.5
	_loading_label.offset_top = -64.0
	_loading_label.offset_bottom = -32.0
	_loading_label.modulate = Color(0.847, 0.702, 0.416)  # or pâle (§23.1)
	_loading_root.add_child(_loading_label)

	var track: ColorRect = ColorRect.new()
	track.name = "Track"
	track.color = Color(0.11, 0.12, 0.16, 1.0)
	track.anchor_left = 0.5
	track.anchor_right = 0.5
	track.anchor_top = 0.5
	track.anchor_bottom = 0.5
	track.offset_left = -220.0
	track.offset_right = 220.0
	track.offset_top = -6.0
	track.offset_bottom = 6.0
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_root.add_child(track)

	_loading_bar = ColorRect.new()
	_loading_bar.name = "Bar"
	_loading_bar.color = Color(0.133, 0.851, 0.925)  # cyan de Résonance
	_loading_bar.anchor_left = 0.0
	_loading_bar.anchor_top = 0.0
	_loading_bar.anchor_bottom = 1.0
	_loading_bar.anchor_right = 0.0
	_loading_bar.offset_right = 0.0
	_loading_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(_loading_bar)


func _show_loading() -> void:
	if _loading_root == null:
		return
	_set_loading_progress(0.0)
	_loading_root.visible = true


func _hide_loading() -> void:
	if _loading_root != null:
		_loading_root.visible = false


func _set_loading_progress(ratio: float) -> void:
	if _loading_bar == null:
		return
	var clamped: float = clampf(ratio, 0.0, 1.0)
	# La piste fait 440 px de large (±220 depuis le centre).
	_loading_bar.offset_right = 440.0 * clamped
	if _loading_label != null:
		_loading_label.text = "Chargement…  %d %%" % int(round(clamped * 100.0))


func _build_fade_layer() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = FADE_LAYER_INDEX
	_fade_layer.name = "FadeLayer"
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)

	# Après le voile, donc dessiné PAR-DESSUS lui.
	_build_loading_ui()


func _fade_to(alpha: float) -> void:
	if _fade_rect == null:
		return
	# En headless il n'y a pas de rendu : le fondu n'a rien à montrer et attendre
	# sa durée ne ferait qu'allonger les tests sans rien prouver.
	if DisplayServer.get_name() == "headless":
		_fade_rect.color.a = alpha
		return
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade_rect, "color:a", alpha, FADE_DURATION)
	await tween.finished


func _fail(target_path: String, reason: String) -> void:
	push_error("[flow] transition impossible vers « %s » : %s" % [target_path, reason])
	transition_failed.emit(target_path, reason)
