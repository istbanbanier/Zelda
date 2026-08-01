## Instrument de latence d'entrée (MASTER_SPEC §10.6, §23.1).
##
## §23.1 exige « entrée mouvement visible au tick physique suivant et latence
## d'action instrumentée ». Cet instrument mesure, en **ticks physiques** puis en
## millisecondes, le délai entre l'arrivée d'une intention et son premier effet
## observable sur le corps. Il pilote le contrôleur par `InputIntent` injectée
## (D-013) : il mesure donc le pipeline intention → mouvement, pas le périphérique.
##
## CE QU'IL NE MESURE PAS, et qu'aucun code headless ne mesurera : la latence
## périphérique → intention (matériel, OS, pompe d'événements) et la latence
## écran. §10.6 les exclut d'ailleurs explicitement (« hors latence
## écran/périphérique »). L'affichage debug à l'écran viendra avec le
## `CombatLab` (Phase C) ; ici l'instrument est la partie mesurante, réutilisable
## telle quelle par cet affichage.
class_name LatencyInstrument
extends RefCounted

## Nombre de ticks au-delà duquel un essai est déclaré perdu — une intention qui
## ne produit aucun effet en une demi-seconde n'est pas « lente », elle est cassée.
const TIMEOUT_TICKS: int = 30

## Résultat d'une campagne de mesure.
class Report extends RefCounted:
	var trials: int = 0
	var min_ticks: int = 0
	var max_ticks: int = 0
	var mean_ticks: float = 0.0
	## Vrai si au moins un essai a dépassé `TIMEOUT_TICKS`.
	var timed_out: bool = false

	## Conversion en millisecondes au tick réellement configuré — pas à un 60 Hz
	## supposé. Si quelqu'un change le tick, la conversion suit.
	func ticks_to_ms(ticks: float) -> float:
		return ticks * 1000.0 / float(Engine.physics_ticks_per_second)

	func summary() -> String:
		return "%d essai(s) : min %d, max %d, moyenne %.2f tick(s) (%.1f ms à %d Hz)" % [
			trials, min_ticks, max_ticks, mean_ticks,
			ticks_to_ms(mean_ticks), Engine.physics_ticks_per_second]


## Attend que le corps soit réellement au repos au sol. Mesurer depuis un corps
## encore en mouvement compterait la fin du mouvement précédent, pas la latence.
static func _wait_for_rest(tree: SceneTree, player: PlayerController,
		intent: InputIntent) -> bool:
	intent.clear()
	for i: int in range(120):
		await tree.physics_frame
		if player.is_on_floor() and player.horizontal_speed() < 0.005 \
				and absf(player.velocity.y) < 0.005:
			return true
	return false


## Mesure le délai entre la pose d'une intention de déplacement — entre deux ticks,
## comme le ferait un périphérique — et la première vitesse horizontale mesurable.
static func measure_move(tree: SceneTree, player: PlayerController,
		intent: InputIntent, trials: int) -> Report:
	return await _measure(tree, player, intent, trials,
		func() -> void: intent.move = Vector2(1.0, 0.0),
		func() -> bool: return player.horizontal_speed() > 0.01)


## Mesure le délai entre la demande de saut et la première vitesse verticale.
static func measure_jump(tree: SceneTree, player: PlayerController,
		intent: InputIntent, trials: int) -> Report:
	return await _measure(tree, player, intent, trials,
		func() -> void: intent.jump_pressed = true,
		func() -> bool: return player.velocity.y > 0.1)


static func _measure(tree: SceneTree, player: PlayerController, intent: InputIntent,
		trials: int, arm: Callable, responded: Callable) -> Report:
	var report: Report = Report.new()
	var total: int = 0
	for t: int in range(trials):
		if not await _wait_for_rest(tree, player, intent):
			report.timed_out = true
			return report
		# L'intention est posée ICI, entre deux ticks : exactement la position
		# temporelle d'un événement de périphérique relayé par le lecteur.
		arm.call()
		var ticks: int = 0
		while ticks < TIMEOUT_TICKS:
			await tree.physics_frame
			ticks += 1
			if responded.call():
				break
		if ticks >= TIMEOUT_TICKS:
			report.timed_out = true
			return report
		report.trials += 1
		report.min_ticks = ticks if t == 0 else mini(report.min_ticks, ticks)
		report.max_ticks = maxi(report.max_ticks, ticks)
		total += ticks
	if report.trials > 0:
		report.mean_ticks = float(total) / float(report.trials)
	return report
