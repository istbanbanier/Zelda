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


# --- Options ajoutées après le playtest en boîte noire -----------------------
#
# Le joueur découverte, devant le menu principal : « Options est grisé, donc je
# n'ai ni sensibilité souris, ni volume, ni rappel des touches : je pars à
# l'aveugle ». §12.3 les exige, et elles se règlent avant de jouer, pas après.
#
# Même discipline que la sensibilité : tout ce qui n'est pas un nombre fini
# retombe sur le défaut. Le fichier est éditable à la main.

const SECTION_CAMERA: String = "camera"
const SECTION_AUDIO: String = "audio"

## Inversion de l'axe vertical du regard. Rien ne divise autant les joueurs, et
## personne n'accepte de jouer sans (§17.5).
static func load_invert_look_y() -> bool:
	var config: ConfigFile = ConfigFile.new()
	if config.load(PATH) != OK:
		return false
	return bool(config.get_value(SECTION_CAMERA, "invert_look_y", false))


static func save_invert_look_y(value: bool) -> bool:
	var config: ConfigFile = ConfigFile.new()
	config.load(PATH)
	config.set_value(SECTION_CAMERA, "invert_look_y", value)
	return config.save(PATH) == OK


## Volume d'un bus, en linéaire 0..1. Le nom du bus est celui d'`AudioManager`.
static func load_volume(bus: String) -> float:
	var config: ConfigFile = ConfigFile.new()
	if config.load(PATH) != OK:
		return 1.0
	var raw: Variant = config.get_value(SECTION_AUDIO, bus, 1.0)
	if typeof(raw) != TYPE_FLOAT and typeof(raw) != TYPE_INT:
		return 1.0
	return clamp_volume(float(raw))


static func save_volume(bus: String, value: float) -> bool:
	var config: ConfigFile = ConfigFile.new()
	config.load(PATH)
	config.set_value(SECTION_AUDIO, bus, clamp_volume(value))
	return config.save(PATH) == OK


static func clamp_volume(value: float) -> float:
	if not is_finite(value):
		return 1.0
	return clampf(value, 0.0, 1.0)
