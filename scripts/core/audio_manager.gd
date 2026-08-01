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


func _ready() -> void:
	_ensure_buses()


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
