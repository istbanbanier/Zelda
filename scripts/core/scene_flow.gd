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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade_layer()


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

	var err: Error = get_tree().change_scene_to_file(target_path)
	if err != OK:
		get_tree().paused = false
		_busy = false
		_fail(target_path, "change_scene_to_file a échoué (%d)" % err)
		return false

	# Laisser la nouvelle scène s'installer avant de lever le voile, sinon le
	# joueur voit une frame de scène non initialisée.
	await get_tree().process_frame
	get_tree().paused = false
	await _fade_to(0.0)

	_busy = false
	transition_finished.emit(target_path)
	return true


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
