## ISS-083 — un adversaire n'adopte pas une cible qui n'est pas dans son
## territoire, quelle que soit la PORTE par laquelle elle arrive.
##
## CE QUI ÉTAIT FAUX. `EnemyBase._acquire_target()` a exactement trois
## appelants (`scripts/enemies/enemy_base.gd`) :
##
##   `_tick_perception()`  — la vision      : GARDÉ par `max_pursuit_distance`
##   `receive_alert()`     — le cri d'allié : NON gardé
##   `_on_hit_received()`  — le coup reçu   : NON gardé
##
## La même question — « cette cible est-elle dans mon territoire ? » — recevait
## donc deux réponses opposées selon le chemin emprunté. Une flèche tirée de
## loin, ou un allié qui crie, faisait prendre une cible que la vision venait
## de refuser. Ce qui bornait réellement la chasse était l'ABANDON en
## poursuite, jamais l'acquisition.
##
## Le contrat de `docs/contrats/iss074_peuplement_world_v2.md` promettait
## l'inverse, dans la phrase même qui se présentait comme « le verrou réel » —
## c'est cette prose fausse qui a fait naître ISS-083.
##
## CE QUE CE FICHIER MESURE. Les trois portes, dans les deux sens : hors
## territoire elles refusent, dans le territoire elles acquièrent. Sans la
## seconde moitié, on « corrigerait » ISS-083 en rendant les adversaires
## sourds et aveugles, et les trois premiers cas resteraient verts.
## PIÈGE MESURÉ EN ÉCRIVANT CE FICHIER. `restore_root()` est une coroutine :
## appelée sans `await`, elle continue de tourner APRÈS la fin du cas et
## recharge la racine pendant que le cas SUIVANT monte son monde — d'où
## « Cannot call method 'add_child' on a previously freed instance » dans un
## helper parfaitement correct. Ces cas ne changent pas la scène courante :
## ils ajoutent leur propre monde à la racine et le retirent. Le couple
## remember_root/restore_root n'a donc rien à y faire, et l'a prouvé.
extends GateTestCase

const RAIDER: String = "res://scenes/enemies/RaiderRed.tscn"
const PLAYER: String = "res://scenes/player/Player.tscn"

## Le territoire de référence de ces cas. `EnemyTuning` par défaut voit à 22 m
## dans un demi-cône de 47,5° : la portée de POURSUITE est donc bien plus
## courte que la portée de VUE, et c'est exactement ce qui rend le défaut
## observable.
const POURSUITE: float = 12.0

var _world: Node3D = null
var _player: CharacterBody3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for _i: int in range(ticks):
		await _tree().physics_frame


func _tuning() -> EnemyTuning:
	var tuning: EnemyTuning = EnemyTuning.new()
	tuning.id = &"raider_red"
	tuning.memory_duration = 0.4
	tuning.search_duration = 0.3
	tuning.max_pursuit_distance = POURSUITE
	tuning.flee_duration = 0.5
	# Aucun allié à alerter dans ces cas, sauf celui qu'on pose exprès.
	tuning.alert_radius = 0.0
	return tuning


func _monter(joueur_a: Vector3) -> void:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var sol: StaticBody3D = StaticBody3D.new()
	sol.collision_layer = 1
	var forme: CollisionShape3D = CollisionShape3D.new()
	var boite: BoxShape3D = BoxShape3D.new()
	boite.size = Vector3(200, 1, 200)
	forme.shape = boite
	sol.add_child(forme)
	sol.position = Vector3(0, -0.5, 0)
	_world.add_child(sol)
	_player = (load(PLAYER) as PackedScene).instantiate() as CharacterBody3D
	_player.position = joueur_a
	_world.add_child(_player)
	await _settle(4)


## Position AVANT `add_child` : `_territory_origin` est capturé dans `_ready()`
## et n'a pas de setter (piège mesuré à ISS-074).
func _pillard(a: Vector3, tuning: EnemyTuning = null) -> EnemyBase:
	var pillard: EnemyBase = (load(RAIDER) as PackedScene).instantiate() as EnemyBase
	pillard.tuning = tuning if tuning != null else _tuning()
	pillard.position = a
	_world.add_child(pillard)
	return pillard


func _demonter() -> void:
	if _world == null:
		return
	_tree().root.remove_child(_world)
	_world.queue_free()
	_world = null
	_player = null
	await _settle(2)


func _chasse(e: EnemyBase) -> bool:
	return e.state() == EnemyBase.State.CHASE \
		or e.state() == EnemyBase.State.ATTACK \
		or e.state() == EnemyBase.State.REPOSITION


## PIÈGE MESURÉ, et il rendait DEUX cas muets. `_on_hit_received` n'est PAS
## branché sur `health().damaged` mais sur `_hurtbox.hit_received`
## (enemy_base.gd:129). Frapper par `health().take_damage()` retire donc bien
## des points de vie, mais ne révèle JAMAIS l'attaquant : le cas « hors
## territoire » passait sans rien prouver, et le cas « dans le territoire »
## échouait pour une raison qui n'était pas la sienne. La porte réelle est
## `HurtboxComponent.receive_hit()`, qui émet le signal PUIS applique les
## dégâts.
func _frapper(cible: EnemyBase, attaquant: Node3D) -> void:
	var evenement: DamageEvent = DamageEvent.new()
	evenement.amount = 1.0
	evenement.instigator = attaquant
	var hurtbox: HurtboxComponent = cible.find_children(
		"Hurtbox", "HurtboxComponent", true, false)[0] as HurtboxComponent
	hurtbox.receive_hit(evenement)


# --------------------------------------------------------------------------
# PORTE 1 — la vision. Déjà gardée : ce cas épingle l'acquis, il ne doit
#           jamais rougir, et sa présence rend le contrat lisible.
# --------------------------------------------------------------------------
func test_la_vision_n_acquiert_pas_au_dela_du_territoire() -> void:
	await _monter(Vector3(0, 0.1, 16.0))
	var garde: EnemyBase = _pillard(Vector3(0, 0.1, 0))
	await _settle(20)

	var d: float = garde.global_position.distance_to(_player.global_position)
	check(d > POURSUITE,
		"préalable : le joueur est HORS territoire (%.2f m > %.1f)" % [d, POURSUITE])
	check(d < garde.tuning.vision_range,
		"préalable NON VACUITÉ : il est pourtant DANS la portée de vue "
		+ "(%.2f m < %.1f) — sans quoi ce cas ne mesurerait rien"
		% [d, garde.tuning.vision_range])
	check(not _chasse(garde),
		"la vision refuse une cible hors territoire")
	await _demonter()


# --------------------------------------------------------------------------
# PORTE 2 — le cri d'allié. ROUGE avant la correction.
# --------------------------------------------------------------------------
func test_le_cri_d_un_allie_n_impose_pas_une_cible_hors_territoire() -> void:
	await _monter(Vector3(0, 0.1, 16.0))
	var loin: EnemyBase = _pillard(Vector3(0, 0.1, 0))
	await _settle(6)
	check_equal(loin.state(), EnemyBase.State.IDLE,
		"préalable : le garde éloigné dort")

	# On appelle `receive_alert` DIRECTEMENT : c'est la porte à éprouver, et
	# passer par un vrai guetteur ajouterait ses propres conditions.
	loin.call("receive_alert", _player)
	await _settle(4)

	var d: float = loin.global_position.distance_to(_player.global_position)
	check(d > POURSUITE,
		"préalable : la cible criée est hors territoire (%.2f m)" % d)
	check(not _chasse(loin),
		"un allié ne peut pas IMPOSER une cible que la vision de ce garde "
		+ "vient de refuser — la même question doit avoir la même réponse "
		+ "quelle que soit la porte")
	await _demonter()


# --------------------------------------------------------------------------
# PORTE 3 — le coup reçu. ROUGE avant la correction.
# --------------------------------------------------------------------------
func test_une_fleche_venue_de_loin_n_impose_pas_sa_cible() -> void:
	await _monter(Vector3(0, 0.1, 20.0))
	var garde: EnemyBase = _pillard(Vector3(0, 0.1, 0))
	await _settle(6)
	check_equal(garde.state(), EnemyBase.State.IDLE, "préalable : il dort")

	_frapper(garde, _player)
	await _settle(6)

	var d: float = garde.global_position.distance_to(_player.global_position)
	check(d > POURSUITE,
		"préalable : l'attaquant est hors territoire (%.2f m)" % d)
	check(not _chasse(garde),
		"être frappé de loin ne fait pas sortir un garde de son territoire — "
		+ "sinon un joueur kite la garnison entière hors de sa région")
	await _demonter()


# --------------------------------------------------------------------------
# LA GARDE DE NON-VACUITÉ. Les trois portes doivent TOUJOURS fonctionner
# quand la cible EST dans le territoire. Sans ces trois cas, rendre les
# adversaires inertes ferait passer tout ce fichier.
# --------------------------------------------------------------------------
func test_dans_le_territoire_la_vision_acquiert_toujours() -> void:
	await _monter(Vector3(0, 0.1, 6.0))
	var garde: EnemyBase = _pillard(Vector3(0, 0.1, 0))
	await _settle(24)
	var d: float = garde.global_position.distance_to(_player.global_position)
	check(d < POURSUITE, "préalable : le joueur est DANS le territoire (%.2f m)" % d)
	check(_chasse(garde), "la vision acquiert normalement dans le territoire")
	await _demonter()


func test_dans_le_territoire_le_cri_d_un_allie_porte_toujours() -> void:
	await _monter(Vector3(0, 0.1, 6.0))
	# Ce garde regarde +Z depuis l'ouest : le joueur est DANS sa portée de
	# poursuite mais HORS de son demi-cône de 47,5° — il ne le voit donc pas
	# de lui-même, et seul le cri peut le réveiller.
	var sourd: EnemyBase = _pillard(Vector3(-8.0, 0.1, 2.0))
	await _settle(8)
	var d: float = sourd.global_position.distance_to(_player.global_position)
	var angle: float = _cone_ecart_deg(sourd, _player.global_position)
	check(angle >= 0.0, "préalable : le Pivot du garde est lisible")
	check(d < POURSUITE,
		"préalable : la cible est DANS son territoire (%.2f m)" % d)
	check(angle > sourd.tuning.vision_half_angle_deg,
		"préalable NON VACUITÉ : elle est HORS de son cône (%.1f° > %.1f°) — "
		% [angle, sourd.tuning.vision_half_angle_deg]
		+ "s'il la voyait, ce cas ne prouverait rien du cri")
	check_equal(sourd.state(), EnemyBase.State.IDLE,
		"préalable : il dort donc bel et bien")

	sourd.call("receive_alert", _player)
	await _settle(4)
	check(_chasse(sourd),
		"le partage de cible de §12.2 fonctionne toujours — la correction "
		+ "d'ISS-083 borne le territoire, elle ne supprime pas l'alerte")
	await _demonter()


func test_dans_le_territoire_un_coup_recu_revele_toujours_l_attaquant() -> void:
	await _monter(Vector3(0, 0.1, -6.0))
	# Le joueur est DERRIÈRE lui : hors cône, donc invisible. Seul le coup
	# peut le révéler — c'est l'intention de §12.7 et elle est préservée.
	var garde: EnemyBase = _pillard(Vector3(0, 0.1, 0))
	await _settle(8)
	check_equal(garde.state(), EnemyBase.State.IDLE,
		"préalable : il ne voit pas l'attaquant venu de derrière")

	_frapper(garde, _player)
	await _settle(6)
	var d: float = garde.global_position.distance_to(_player.global_position)
	check(d < POURSUITE,
		"préalable : l'attaquant est DANS son territoire (%.2f m)" % d)
	check(_chasse(garde),
		"« être frappé révèle l'attaquant, même hors du cône » reste vrai "
		+ "dans le territoire (§12.7)")
	await _demonter()


## L'AXE QUE REGARDE VRAIMENT UN ENNEMI, LU OÙ LE CODE LE LIT.
##
## DÉFAUT MESURÉ, ET IL RENDAIT LE PRÉALABLE INCAPABLE DE ROUGIR. La première
## rédaction comparait à `Vector3.FORWARD`, c'est-à-dire **−Z**. Or
## `enemy_base.gd::_tick_perception` lit `_pivot.global_transform.basis.z`,
## c'est-à-dire **+Z**. Les deux angles sont supplémentaires : une cible en
## PLEIN CENTRE du cône (0° réel) mesurait 180° contre −Z et passait donc pour
## « hors du cône ». Le préalable était vrai par accident sur la géométrie
## choisie, et faux sur le seul cas qu'il existe pour exclure.
##
## On lit désormais `Pivot`, le nœud même que la perception interroge : le
## préalable ne peut plus diverger de la règle qu'il vérifie.
func _cone_ecart_deg(garde: Node3D, cible: Vector3) -> float:
	var pivot: Node3D = garde.get_node_or_null("Pivot") as Node3D
	if pivot == null:
		return -1.0
	var avant: Vector3 = pivot.global_transform.basis.z
	avant = Vector3(avant.x, 0.0, avant.z).normalized()
	var vers: Vector3 = cible - garde.global_position
	vers = Vector3(vers.x, 0.0, vers.z).normalized()
	return rad_to_deg(avant.angle_to(vers))
