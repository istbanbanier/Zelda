## Viseur du Bracelet de Résonance (P2 §3.8) — le tracé, rien d'autre.
##
## Ce Control ne DÉCIDE rien : `GameplayShell` lui pousse un état déjà résolu
## par `apply_state()`, il le dessine. Il ne lit ni l'InputMap (D-013), ni le
## `ResonanceController`, ni la caméra.
##
## Règle de lisibilité (P3 §1.6, P2 §3.8) : **aucune information n'est portée
## par la seule couleur**. L'anneau est LARGEMENT OUVERT tant qu'aucune cible
## n'est retenue et se REFERME sur une cible ; le losange se DOUBLE quand un
## premier port est retenu ; un refus BARRE le viseur. Un joueur daltonien,
## ou une capture en niveaux de gris, lisent les mêmes trois états.
##
## Redessin seulement au CHANGEMENT d'état (règle CLAUDE.md : aucune
## allocation ni travail inutile par frame) — `apply_state` compare avant de
## demander `queue_redraw()`.
class_name ResonanceOverlay
extends Control

## Rayon du viseur central, en pixels à 1080p.
const RING_RADIUS: float = 15.0
## Demi-diagonale du losange posé sur la cible retenue.
const MARK_RADIUS: float = 9.0
## Écart du second losange — la marque « port A retenu ».
const MARK_PENDING_GAP: float = 4.0
const RING_WIDTH: float = 2.0

var _focus_active: bool = false
var _has_target: bool = false
var _target_on_screen: bool = false
var _target_screen: Vector2 = Vector2.ZERO
var _pending_link: bool = false
var _refused: bool = false


func _ready() -> void:
	# Le viseur ne prend jamais le clic : c'est le gameplay qui le reçoit.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## Pousse l'état à dessiner. Retourne `true` si le tracé a réellement changé —
## le seam qui prouve qu'on ne redessine pas pour rien.
func apply_state(focus_active: bool, has_target: bool, target_on_screen: bool,
		target_screen: Vector2, pending_link: bool, refused: bool) -> bool:
	var changed: bool = focus_active != _focus_active \
		or has_target != _has_target \
		or target_on_screen != _target_on_screen \
		or pending_link != _pending_link \
		or refused != _refused \
		or (target_on_screen and not target_screen.is_equal_approx(_target_screen))
	_focus_active = focus_active
	_has_target = has_target
	_target_on_screen = target_on_screen
	_target_screen = target_screen
	_pending_link = pending_link
	_refused = refused
	if changed:
		queue_redraw()
	return changed


func _draw() -> void:
	if not _focus_active:
		return
	var centre: Vector2 = _centre()
	_draw_ring(centre)
	if _has_target and _target_on_screen:
		_draw_mark(_target_screen)
	if _refused:
		_draw_barred(centre)


## Centre de l'écran. Repli sur le viewport tant que la mise en page n'a pas
## donné sa taille au Control : sans ce garde-fou, le viseur se dessinerait
## dans le coin haut-gauche à la toute première image.
func _centre() -> Vector2:
	if size.x < 1.0 or size.y < 1.0:
		return get_viewport_rect().size * 0.5
	return size * 0.5


## L'anneau incomplet — le motif de la technologie du monde (P3 §2.3). Quatre
## segments : très écartés quand rien n'est retenu, presque joints sur une
## cible. C'est l'ÉCART, pas la teinte, qui porte l'information.
func _draw_ring(centre: Vector2) -> void:
	var span: float = deg_to_rad(80.0) if _has_target else deg_to_rad(34.0)
	var tint: Color = HudStyle.CYAN if _has_target else HudStyle.GOLD
	for quadrant: int in range(4):
		var middle: float = deg_to_rad(45.0 + 90.0 * float(quadrant))
		draw_arc(centre, RING_RADIUS, middle - span * 0.5, middle + span * 0.5,
			12, tint, RING_WIDTH, true)
	if _has_target:
		# Cœur clair au centre : la cible est verrouillée, le clic agira.
		draw_circle(centre, 2.0, HudStyle.CYAN_CORE)


## Losange sur la cible retenue. Doublé lorsqu'un premier port attend son
## second — l'état invisible qui perdait les joueurs (PT-BRACELET-01).
func _draw_mark(at: Vector2) -> void:
	_draw_diamond(at, MARK_RADIUS, HudStyle.CYAN)
	if _pending_link:
		_draw_diamond(at, MARK_RADIUS + MARK_PENDING_GAP, HudStyle.CYAN_CORE)


func _draw_diamond(at: Vector2, radius: float, tint: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array([
		at + Vector2(0.0, -radius), at + Vector2(radius, 0.0),
		at + Vector2(0.0, radius), at + Vector2(-radius, 0.0),
		at + Vector2(0.0, -radius),
	])
	draw_polyline(points, tint, 1.5, true)


## Refus : une barre en travers du viseur. La plaque en dit la RAISON ; ce
## trait dit seulement « ça n'est pas parti », sans dépendre du rouge.
func _draw_barred(centre: Vector2) -> void:
	var reach: float = RING_RADIUS + 5.0
	draw_line(centre + Vector2(-reach, -reach), centre + Vector2(reach, reach),
		HudStyle.IVORY, RING_WIDTH, true)


## --- Seams de test : ce que le viseur montre RÉELLEMENT ---

func is_ring_closed() -> bool:
	return _focus_active and _has_target


func is_mark_doubled() -> bool:
	return _focus_active and _has_target and _target_on_screen and _pending_link


func is_barred() -> bool:
	return _focus_active and _refused


func mark_position() -> Vector2:
	return _target_screen
