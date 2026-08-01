## Alignement d'action (MASTER_SPEC §7.12) — logique pure, delta piloté à la main.
##
## L'enjeu tient en une phrase de §9.3 : « aucun snap visible ». Un composant qui
## poserait le personnage à destination dès la première image satisferait tous les
## tests de position finale et raterait l'exigence. On mesure donc le **plus grand
## pas** effectué, pas seulement l'arrivée.
extends GateTestCase

const TICK: float = 1.0 / 60.0


## `ActionAlignmentComponent` est un `Node` (§5.8) : il n'est pas compté par
## référence. Un composant créé pour un test et jamais libéré reste orphelin, et
## le moteur signale « resources still in use at exit » — que `validate_fast.sh`
## traite en rouge, à raison. Chaque test libère donc le sien.
func _make() -> ActionAlignmentComponent:
	return ActionAlignmentComponent.new()


func test_begin_refuses_a_correction_beyond_the_cap() -> void:
	## §7.12 : « correction plafonnée ». Au-delà, l'action ne doit pas avoir lieu —
	## amortir un bond de dix mètres resterait une téléportation, juste plus lente.
	var a: ActionAlignmentComponent = _make()
	var started: bool = a.begin(Vector3.ZERO, Vector3(0, 10, 0), 0.45, 2.6)
	check(not started, "une correction de 10 m doit être refusée sous un plafond de 2,6 m")
	check(not a.is_active(), "un refus ne doit rien démarrer")
	a.free()


func test_begin_accepts_a_correction_within_the_cap() -> void:
	var a: ActionAlignmentComponent = _make()
	check(a.begin(Vector3.ZERO, Vector3(0, 1.5, 0), 0.45, 2.6),
		"une correction de 1,5 m doit être acceptée sous un plafond de 2,6 m")
	check(a.is_active(), "l'alignement doit être actif après acceptation")
	a.free()


func test_begin_refuses_a_null_duration() -> void:
	## Une durée nulle est un snap déguisé.
	var a: ActionAlignmentComponent = _make()
	check(not a.begin(Vector3.ZERO, Vector3(0, 1.0, 0), 0.0, 2.6),
		"une durée nulle doit être refusée")
	a.free()


func test_advance_reaches_the_target_exactly() -> void:
	var a: ActionAlignmentComponent = _make()
	var target: Vector3 = Vector3(1.0, 1.5, -0.8)
	a.begin(Vector3.ZERO, target, 0.45, 2.6)
	var last: Vector3 = Vector3.ZERO
	for i: int in range(60):
		last = a.advance(TICK)
	check(last.distance_to(target) < 0.001,
		"la position finale doit être la cible : écart %.4f m" % last.distance_to(target))
	check(not a.is_active(), "l'alignement doit s'être terminé")
	a.free()


func test_no_single_step_is_a_snap() -> void:
	## Le test qui porte l'exigence. Sur 0,45 s, une correction de 1,96 m — celle
	## d'un franchissement réel — ne doit jamais avancer d'un bond : le pas maximal
	## reste borné par la vitesse moyenne, adoucissement compris.
	var a: ActionAlignmentComponent = _make()
	var target: Vector3 = Vector3(0.0, 1.7, -0.97)
	var duration: float = 0.45
	a.begin(Vector3.ZERO, target, duration, 2.6)

	var previous: Vector3 = Vector3.ZERO
	var largest: float = 0.0
	for i: int in range(60):
		var next: Vector3 = a.advance(TICK)
		largest = maxf(largest, previous.distance_to(next))
		previous = next

	# Vitesse moyenne = distance / durée. L'adoucissement culmine à 1,5× cette
	# moyenne ; on tolère 2× pour ne pas transformer ce test en verrou de courbe.
	var average_step: float = target.length() / duration * TICK
	check(largest < average_step * 2.0,
		"pas maximal %.4f m contre une moyenne de %.4f m — un snap ferait %.4f m"
		% [largest, average_step, target.length()])
	check(largest > 0.0, "le composant doit tout de même avancer")
	a.free()


func test_motion_starts_and_ends_gently() -> void:
	## Un déplacement à vitesse constante démarre et s'arrête net : lisible comme un
	## à-coup même sans dépassement. Les premiers et derniers pas doivent être plus
	## courts que ceux du milieu.
	var a: ActionAlignmentComponent = _make()
	a.begin(Vector3.ZERO, Vector3(0, 1.8, 0), 0.6, 2.6)
	var steps: Array[float] = []
	var previous: Vector3 = Vector3.ZERO
	for i: int in range(36):
		var next: Vector3 = a.advance(1.0 / 60.0)
		steps.append(previous.distance_to(next))
		previous = next
	check(steps.size() >= 30, "assez d'échantillons pour comparer")
	check(steps[0] < steps[int(steps.size() / 2.0)],
		"le premier pas (%.4f) doit être plus court que celui du milieu (%.4f)"
		% [steps[0], steps[int(steps.size() / 2.0)]])
	check(steps[steps.size() - 1] < steps[int(steps.size() / 2.0)],
		"le dernier pas (%.4f) doit être plus court que celui du milieu (%.4f)"
		% [steps[steps.size() - 1], steps[int(steps.size() / 2.0)]])
	a.free()


func test_finished_is_emitted_once() -> void:
	var a: ActionAlignmentComponent = _make()
	var count: Array[int] = [0]
	a.finished.connect(func() -> void: count[0] += 1)
	a.begin(Vector3.ZERO, Vector3(0, 1.0, 0), 0.2, 2.6)
	for i: int in range(60):
		a.advance(TICK)
	check_equal(count[0], 1, "nombre d'émissions de finished")
	a.free()


func test_cancel_reports_the_reason_and_stops() -> void:
	## §7.12 : « annulation si capsule bloquée ». La raison remonte : un test comme
	## un journal de debug doit savoir *pourquoi* le franchissement s'est interrompu.
	var a: ActionAlignmentComponent = _make()
	var reasons: Array[StringName] = []
	a.cancelled.connect(func(reason: StringName) -> void: reasons.append(reason))
	a.begin(Vector3.ZERO, Vector3(0, 1.5, 0), 0.45, 2.6)
	a.advance(TICK)
	a.cancel(&"blocked")
	check(not a.is_active(), "l'alignement doit s'arrêter")
	check_equal(reasons.size(), 1, "nombre d'annulations")
	check_equal(reasons[0], &"blocked", "raison rapportée")
	a.free()


func test_cancelling_an_inactive_component_is_silent() -> void:
	## Sans cette garde, une annulation défensive émettrait un signal fantôme et le
	## propriétaire annulerait deux fois une action déjà terminée.
	var a: ActionAlignmentComponent = _make()
	var count: Array[int] = [0]
	a.cancelled.connect(func(_r: StringName) -> void: count[0] += 1)
	a.cancel(&"blocked")
	check_equal(count[0], 0, "aucune annulation sur un composant inactif")

	a.begin(Vector3.ZERO, Vector3(0, 1.0, 0), 0.2, 2.6)
	for i: int in range(30):
		a.advance(TICK)
	a.cancel(&"blocked")
	check_equal(count[0], 0, "aucune annulation après achèvement normal")
	a.free()