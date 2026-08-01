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
	# `clampf(nan, …)` retourne nan : un non-nombre DOIT retomber sur le défaut,
	# sinon la caméra gèle sans message (QA-D1R-02).
	if not is_finite(value):
		return DEFAULT_MOUSE_SENSITIVITY
	return clampf(value, MIN_MOUSE_SENSITIVITY, MAX_MOUSE_SENSITIVITY)


static func load_mouse_sensitivity() -> float:
	var config: ConfigFile = ConfigFile.new()
	if config.load(PATH) != OK:
		return DEFAULT_MOUSE_SENSITIVITY
	# Fichier éditable à la main : la valeur peut être n'importe quel Variant.
	# Tout ce qui n'est pas un nombre fini vaut le défaut — jamais 0 (souris
	# morte), jamais nan, jamais un crash de constructeur (QA-D1R-02).
	var raw: Variant = config.get_value(SECTION, "mouse_sensitivity",
		DEFAULT_MOUSE_SENSITIVITY)
	if typeof(raw) != TYPE_FLOAT and typeof(raw) != TYPE_INT:
		return DEFAULT_MOUSE_SENSITIVITY
	return clamp_sensitivity(float(raw))


static func save_mouse_sensitivity(value: float) -> bool:
	var config: ConfigFile = ConfigFile.new()
	config.load(PATH)  # conserve les autres sections si le fichier existe
	config.set_value(SECTION, "mouse_sensitivity", clamp_sensitivity(value))
	return config.save(PATH) == OK
