## Alignement d'action (MASTER_SPEC §7.12, §5.8).
##
## §7.12 le désigne comme « substitut ciblé au motion warping » : capture d'un
## transform **validé**, interpolation de racine, correction **plafonnée**,
## annulation si la capsule est bloquée, verrouillage temporaire. Il sert au
## mantle (§9.3), et servira aux coffres, à la cuisine et au pylône.
##
## Ce qu'il n'est pas : une téléportation habillée. La différence tient à deux
## règles — la cible est refusée si la correction dépasse un plafond, et le
## déplacement est réparti sur une durée, donc observable image par image. §9.3
## exige « aucun snap visible » ; c'est ici que cette exigence est tenue, et
## `test_action_alignment.gd` mesure le plus grand pas effectué.
class_name ActionAlignmentComponent
extends Node

signal finished()
signal cancelled(reason: StringName)

var _active: bool = false
var _points: PackedVector3Array = PackedVector3Array()
## Distances cumulées le long de la polyligne, pour avancer à vitesse maîtrisée
## plutôt que par segment — sans quoi un segment court serait parcouru aussi
## longtemps qu'un long, ce qui se voit.
var _cumulative: PackedFloat32Array = PackedFloat32Array()
var _length: float = 0.0
var _duration: float = 0.0
var _elapsed: float = 0.0


## Capture la cible. Retourne `false` — sans rien démarrer — si la correction
## dépasse `max_correction` ou si la durée est nulle : mieux vaut une action qui
## n'a pas lieu qu'un personnage déplacé d'un bond.
func begin(from: Vector3, to: Vector3, duration: float, max_correction: float) -> bool:
	return begin_path(PackedVector3Array([from, to]), duration, max_correction)


## Variante par **chemin**. Une interpolation directe convient à un recentrage,
## pas à un franchissement : la droite qui relie le pied d'un rebord à son dessus
## traverse le rebord lui-même. Le mantle passe donc par un point haut — monter,
## puis avancer (§9.3, « mantle bas/haut »). Le plafond de correction reste mesuré
## de bout en bout : c'est le déplacement net qui doit rester raisonnable, pas la
## longueur du trajet emprunté pour l'obtenir.
func begin_path(points: PackedVector3Array, duration: float, max_correction: float) -> bool:
	if duration <= 0.0 or points.size() < 2:
		return false
	if points[0].distance_to(points[points.size() - 1]) > max_correction:
		return false

	_cumulative = PackedFloat32Array()
	_cumulative.resize(points.size())
	_cumulative[0] = 0.0
	var total: float = 0.0
	for i: int in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
		_cumulative[i] = total
	if total <= 0.0:
		return false

	_points = points
	_length = total
	_duration = duration
	_elapsed = 0.0
	_active = true
	return true


## Avance d'un tick et retourne la position de racine à appliquer. Le propriétaire
## reste responsable de la valider : §7.12 impose l'annulation si la capsule se
## retrouve bloquée en cours de route.
func advance(delta: float) -> Vector3:
	if not _active:
		return target()
	_elapsed += delta
	var t: float = clampf(_elapsed / _duration, 0.0, 1.0)
	# Accélération puis décélération : un déplacement à vitesse constante démarre
	# et s'arrête net, ce qui se lit comme un à-coup même sans dépassement.
	var eased: float = t * t * (3.0 - 2.0 * t)
	var position: Vector3 = _sample_path(eased * _length)
	if t >= 1.0:
		_active = false
		finished.emit()
	return position


## Point du chemin à `distance` mètres de son départ.
func _sample_path(distance: float) -> Vector3:
	if _points.size() < 2:
		return Vector3.ZERO
	if distance <= 0.0:
		return _points[0]
	for i: int in range(1, _points.size()):
		if distance <= _cumulative[i]:
			var span: float = _cumulative[i] - _cumulative[i - 1]
			if span <= 0.0:
				return _points[i]
			var local: float = (distance - _cumulative[i - 1]) / span
			return _points[i - 1].lerp(_points[i], local)
	return _points[_points.size() - 1]


## Interruption propre (§7.12). L'appelant décide où replacer le personnage ; ce
## composant se contente de rendre la main et de dire pourquoi.
func cancel(reason: StringName) -> void:
	if not _active:
		return
	_active = false
	cancelled.emit(reason)


func is_active() -> bool:
	return _active


## Fraction parcourue, 0–1. Utile au debug et aux tests.
func progress() -> float:
	if _duration <= 0.0:
		return 1.0
	return clampf(_elapsed / _duration, 0.0, 1.0)


func target() -> Vector3:
	if _points.is_empty():
		return Vector3.ZERO
	return _points[_points.size() - 1]
