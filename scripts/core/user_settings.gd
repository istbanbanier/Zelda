## Réglages utilisateur (MASTER_SPEC §19.1 : « options utilisateur séparées »).
##
## Fichier `user://settings.cfg`, distinct des sauvegardes de partie : perdre
## une partie ne doit jamais perdre une sensibilité, et réciproquement.
## Fonctions statiques : aucun autoload de plus — les consommateurs (lecteur
## d'entrée, menu pause) lisent et écrivent à la demande, jamais par frame.
class_name UserSettings
extends RefCounted

const PATH: String = "user://settings.cfg"
const SECTION: String = "input"

## Sensibilité souris en radians par pixel. Défaut : ~0,086°/px — un tour
## complet en ≈ 25 cm de tapis à 400 dpi. Bornes du curseur de réglage.
const DEFAULT_MOUSE_SENSITIVITY: float = 0.0015
const MIN_MOUSE_SENSITIVITY: float = 0.0004
const MAX_MOUSE_SENSITIVITY: float = 0.005


static func clamp_sensitivity(value: float) -> float:
	return clampf(value, MIN_MOUSE_SENSITIVITY, MAX_MOUSE_SENSITIVITY)


static func load_mouse_sensitivity() -> float:
	var config: ConfigFile = ConfigFile.new()
	if config.load(PATH) != OK:
		return DEFAULT_MOUSE_SENSITIVITY
	var raw: float = float(config.get_value(SECTION, "mouse_sensitivity",
		DEFAULT_MOUSE_SENSITIVITY))
	return clamp_sensitivity(raw)


static func save_mouse_sensitivity(value: float) -> bool:
	var config: ConfigFile = ConfigFile.new()
	config.load(PATH)  # conserve les autres sections si le fichier existe
	config.set_value(SECTION, "mouse_sensitivity", clamp_sensitivity(value))
	return config.save(PATH) == OK
