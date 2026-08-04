## Colonne de fumée du camp — le signal de guidage principal de la vallée.
##
## Quatre playtests indépendants ont cherché le camp sans jamais le trouver :
## la colonne existait, mais son sommet (20,5 m) restait SOUS l'œil du joueur
## sur la crête (~27 m) — du gris immobile sur des falaises grises. Trois
## corrections, toutes visuelles : elle monte au-dessus de la ligne d'horizon
## (découpée sur le CIEL), elle contraste, et elle BOUGE — §2.2 (P2) : « la
## lumière, le son et le mouvement attirent ». L'œil humain accroche le
## mouvement en périphérie ; une colonne statique est un décor, une colonne
## qui ondule est un signal.
##
## Balancement en cisaillement (le PIED reste ancré au feu, la tête dérive
## comme poussée par le vent) — une rotation simple ferait osciller la base,
## trahissant le proxy. Amplitude et vitesses volontairement lentes : c'est
## de la fumée, pas un drapeau.
extends MeshInstance3D

const SWAY_DEG: float = 6.0
const SWAY_SPEED: float = 0.5
const BREATHE_SPEED: float = 0.31
const BREATHE_AMOUNT: float = 0.08

var _time: float = 0.0
var _base_height: float = 0.0


func _ready() -> void:
	_base_height = position.y


func _process(delta: float) -> void:
	_time += delta
	var lean: float = sin(_time * TAU * SWAY_SPEED) * deg_to_rad(SWAY_DEG)
	# Cisaillement : la tête penche, le pied reste au feu. `Basis` colonne par
	# colonne — l'axe Y gagne une composante X, X et Z restent droits.
	var sheared: Basis = Basis(
		Vector3(1, 0, 0),
		Vector3(sin(lean), cos(lean), 0),
		Vector3(0, 0, 1))
	var breathe: float = 1.0 + sin(_time * TAU * BREATHE_SPEED) * BREATHE_AMOUNT
	transform.basis = sheared.scaled(Vector3(breathe, 1.0, breathe))
	# Le pied ne bouge pas : la hauteur du centre suit l'ancrage d'origine.
	position.y = _base_height
