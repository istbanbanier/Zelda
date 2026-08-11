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
## Repli si le maillage n'est pas un cylindre : moitié de `height = 40.0`
## dans ValleyWorld.tscn. Voir `_half_height`, mesuré au démarrage.
const HALF_HEIGHT: float = 20.0

var _time: float = 0.0
var _base_height: float = 0.0
## Abscisse d'ancrage : la compensation de pivot écrit `position.x` à chaque
## frame, elle doit repartir de la position posée dans la scène, pas de zéro.
var _base_x: float = 0.0
## Distance de l'origine du nœud à la BASE du maillage. `CylinderMesh` est
## centré : l'origine est à mi-hauteur, pas au pied. C'est cette distance qui
## sert à ramener le pivot du cisaillement sur le pied (voir `_process`).
var _half_height: float = HALF_HEIGHT


func _ready() -> void:
	_base_height = position.y
	_base_x = position.x
	# Mesuré sur le maillage réel plutôt que codé en dur : si la hauteur de la
	# colonne change dans la scène, la compensation de pivot suit toute seule.
	var cylinder: CylinderMesh = mesh as CylinderMesh
	if cylinder != null:
		_half_height = cylinder.height * 0.5


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
	# Le commentaire d'en-tête promettait « le PIED reste ancré au feu », mais le
	# cisaillement pivote autour de l'ORIGINE du nœud, qui est à mi-hauteur du
	# cylindre. Mesuré : un sommet de la base est en local (0, -_half_height, 0),
	# son image est (-_half_height * breathe * sin(lean), -_half_height * cos(lean), 0)
	# — à 6° et 20 m de demi-hauteur, le pied balayait ±2,09 m de terrain toutes
	# les deux secondes, en sortant du foyer. On translate donc le nœud de
	# l'exact opposé : le pied redevient immobile, seule la tête dérive.
	# `breathe` est obligatoire dans la composante X : `Basis.scaled` multiplie
	# la RANGÉE X, donc la part de cisaillement portée par X est mise à l'échelle.
	position.x = _base_x + _half_height * sin(lean) * breathe
	position.y = _base_height - _half_height * (1.0 - cos(lean))
