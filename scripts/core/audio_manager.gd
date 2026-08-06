## Autoload — bus audio et volumes (MASTER_SPEC §18.1).
##
## Crée les bus au démarrage s'ils n'existent pas, plutôt que de dépendre d'un
## `default_bus_layout.tres` binaire : la configuration reste lisible en diff,
## vérifiable par un test, et reproductible sur une machine neuve.
##
## Portée à la Phase A : la **structure** des bus et le réglage des volumes. Les
## pools de lecture, la musique adaptative et les zones de réverbération (§18.4,
## §18.5) arrivent avec le contenu qu'ils doivent servir.
##
## Note d'environnement : le conteneur de développement n'a aucun périphérique
## audio (KNOWN_ISSUES ISS-004). Godot bascule sur le pilote muet ; la structure
## des bus reste créée et testable, mais **aucun mixage réel n'a été écouté**.
extends Node

## Ordre significatif : chaque bus est routé vers `Master`, sauf `Master` lui-même.
const BUSES: Array[String] = [
	"Master",
	"Music",
	"Ambience",
	"SFX",
	"UI",
	"Voice",
]

signal volume_changed(bus_name: String, linear: float)

## Sons courts du jeu (TESTS.md, bug 1 : « le jeu entier est muet »). Des
## placeholders GÉNÉRÉS par `tools/audio/make_placeholder_sfx.py` — leur rôle
## est qu'aucune action ne soit muette (§18.2), pas de sonner final. La
## variation de pitch (§18.2 : « aucun effet mitraillette ») est bornée ici.
const SFX_DIR: String = "res://assets/audio/sfx"
const SFX_PLAYERS: int = 8
const PITCH_JITTER: float = 0.07

var _sfx_streams: Dictionary = {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_next: int = 0


func _ready() -> void:
	_ensure_buses()
	_build_sfx_pool()
	_restore_saved_volumes()


## Les volumes étaient ÉCRITS dans `settings.cfg` et relus uniquement pour
## peindre la position des curseurs — jamais pour régler les bus. Un joueur qui
## coupait la musique la retrouvait à fond au lancement suivant, avec un
## curseur affichant zéro : le réglage semblait cassé, et il l'était. La
## sensibilité souris et l'inversion, elles, étaient bien rechargées ; le son
## avait simplement été oublié.
func _restore_saved_volumes() -> void:
	for bus_name: String in ["Master", "Music", "SFX"]:
		if has_bus(bus_name):
			set_volume(bus_name, UserSettings.load_volume(bus_name))


## Joue un son court par nom (`hit_land`, `refuse`, `ui_move`, …).
## Silencieusement sans effet si le fichier n'existe pas : un son manquant ne
## doit jamais casser une action de gameplay — il se voit dans les tests.
func play_sfx(sound: StringName, bus: String = "SFX") -> void:
	var stream: AudioStream = _sfx_stream(sound)
	if stream == null:
		return
	var player: AudioStreamPlayer = _sfx_pool[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_pool.size()
	player.bus = bus if has_bus(bus) else "Master"
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-PITCH_JITTER, PITCH_JITTER)
	player.play()


func has_sfx(sound: StringName) -> bool:
	return _sfx_stream(sound) != null


func _sfx_stream(sound: StringName) -> AudioStream:
	if _sfx_streams.has(sound):
		return _sfx_streams[sound] as AudioStream
	var path: String = "%s/%s.wav" % [SFX_DIR, String(sound)]
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	_sfx_streams[sound] = stream
	return stream


func _build_sfx_pool() -> void:
	for i: int in range(SFX_PLAYERS):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxVoice%d" % i
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)


func _ensure_buses() -> void:
	for bus_name: String in BUSES:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		var index: int = AudioServer.get_bus_count()
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")


func has_bus(bus_name: String) -> bool:
	return AudioServer.get_bus_index(bus_name) != -1


## Volume en échelle **linéaire** (0.0 à 1.0) : c'est ce qu'attend une option de
## menu. La conversion en décibels est faite ici, une fois, plutôt que dispersée
## dans l'interface.
func set_volume(bus_name: String, linear: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index == -1:
		push_error("[audio] bus inconnu : %s" % bus_name)
		return
	var clamped: float = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(clamped) if clamped > 0.0 else -80.0)
	AudioServer.set_bus_mute(index, clamped <= 0.0)
	volume_changed.emit(bus_name, clamped)


func get_volume(bus_name: String) -> float:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index == -1:
		return 0.0
	if AudioServer.is_bus_mute(index):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(index)), 0.0, 1.0)
