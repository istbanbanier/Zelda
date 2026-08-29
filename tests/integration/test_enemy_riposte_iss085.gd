## ISS-085 — UN GARDE FRAPPÉ DE LOIN N'EST PAS UN MANNEQUIN.
##
## LE DÉFAUT, et la fiche le décrivait de façon INEXACTE. Elle disait « aucune
## réaction du tout » ; la lecture du code dit autre chose, et c'est pire :
## `_on_hit_received` émet un bruit d'impact À SA PROPRE POSITION
## (enemy_base.gd, `NoiseEvents.emit(..., global_position, ...)`), et
## `NoiseEvents.emit` n'exclut PAS l'émetteur. Le garde s'entend donc
## lui-même, à distance zéro, et entre bel et bien en SUSPICIOUS — mais avec
## `_last_known` égal à SA PROPRE POSITION.
##
## La réaction existe et elle est DÉGÉNÉRÉE : `_process_suspicious` oriente
## vers `_last_known - global_position`, c'est-à-dire le vecteur NUL ; `_face`
## sort immédiatement ; INVESTIGATE est déjà arrivé ; RETURN est déjà chez
## lui. Trois changements d'état, zéro rotation, zéro pas. Le garde encaisse
## flèche après flèche en regardant ailleurs.
##
## CE QUE CE FICHIER EXIGE, et les deux exigences se tiennent :
##   B1 une réaction OBSERVABLE — il se tourne vers l'agresseur ET il bouge ;
##   B2 jamais hors du territoire — la réaction s'arrête à la frontière ;
##   B3 jamais de poursuite — ni CHASE ni ATTACK ;
##   B4 non vacuité — dans le territoire, le coup acquiert toujours ;
##   B5 la vallée V1 n'a rien perdu ;
##   B6 aucune invulnérabilité inventée — le coup fait toujours ses dégâts.
##
## CE QU'IL NE PRÉTEND PAS FERMER. Tant que « aucune poursuite hors
## territoire » tient, un archer patient reste hors d'atteinte : le garde vient
## à sa frontière et s'y arrête. Les deux exigences sont en tension, et c'est
## la borne de territoire qui gagne. Ce qui change : le garde n'est plus
## immobile, il FAIT FACE, et ses voisins convergent — le joueur doit entrer
## dans le territoire pour finir, et il y entre contre une garnison éveillée
## qui le regarde. Le reste est consigné, pas prétendu.
extends GateTestCase

const RAIDER: String = "res://scenes/enemies/RaiderRed.tscn"
const VALLEY_V1_SCENE: String = "res://scenes/world/valley/ValleyWorld.tscn"
## `max_pursuit_distance` du tuning court utilisé ici — recopié à dessein :
## un test qui lirait la constante suivrait aussi son affaiblissement.
const POURSUITE: float = 12.0

var _world: Node3D = null
var _player: CharacterBody3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _short_tuning() -> EnemyTuning:
	var t: EnemyTuning = EnemyTuning.new()
	t.max_pursuit_distance = POURSUITE
	return t


func _monter(joueur: Vector3) -> void:
	_world = Node3D.new()
	_tree().root.add_child(_world)
	var sol: StaticBody3D = StaticBody3D.new()
	sol.collision_layer = 1
	var forme: CollisionShape3D = CollisionShape3D.new()
	var boite: BoxShape3D = BoxShape3D.new()
	boite.size = Vector3(200, 1, 200)
	forme.shape = boite
	forme.position = Vector3(0, -0.5, 0)
	sol.add_child(forme)
	_world.add_child(sol)

	_player = (load("res://scenes/player/Player.tscn") as PackedScene) \
		.instantiate() as CharacterBody3D
	_world.add_child(_player)
	_player.global_position = joueur
	await _tree().physics_frame


func _pillard(at: Vector3) -> EnemyBase:
	var e: EnemyBase = (load(RAIDER) as PackedScene).instantiate() as EnemyBase
	e.tuning = _short_tuning()
	_world.add_child(e)
	e.global_position = at
	return e


func _settle(n: int) -> void:
	for _i: int in range(n):
		await _tree().physics_frame


func _demonter() -> void:
	if _world == null:
		return
	var monde: Node3D = _world
	_world = null
	_player = null
	_tree().root.remove_child(monde)
	monde.queue_free()
	for _i: int in range(4):
		await _tree().process_frame


## La porte RÉELLE d'un coup : la hurtbox, jamais `health().take_damage()`.
## Piège déjà mesuré à ISS-083 : `_on_hit_received` est branché sur
## `_hurtbox.hit_received`, donc frapper la santé retire des points sans
## jamais révéler l'attaquant.
func _frapper(cible: EnemyBase, attaquant: Node3D) -> void:
	var evenement: DamageEvent = DamageEvent.new()
	evenement.amount = 1.0
	evenement.instigator = attaquant
	var boites: Array[Node] = cible.find_children(
		"Hurtbox", "HurtboxComponent", true, false)
	if boites.is_empty():
		return
	(boites[0] as HurtboxComponent).receive_hit(evenement)


## L'écart entre le regard du garde et une cible, lu OÙ LE CODE LE LIT :
## `_pivot.global_transform.basis.z`, c'est-à-dire +Z. Comparer à
## `Vector3.FORWARD` (−Z) donnerait l'angle supplémentaire, et un garde qui
## regarde EXACTEMENT sa cible mesurerait 180°.
func _ecart_regard_deg(garde: Node3D, cible: Vector3) -> float:
	var pivot: Node3D = garde.get_node_or_null("Pivot") as Node3D
	if pivot == null:
		return -1.0
	var avant: Vector3 = pivot.global_transform.basis.z
	avant = Vector3(avant.x, 0.0, avant.z).normalized()
	var vers: Vector3 = cible - garde.global_position
	vers = Vector3(vers.x, 0.0, vers.z).normalized()
	return rad_to_deg(avant.angle_to(vers))


## Oriente le garde À L'OPPOSÉ d'un point, avec la formule EXACTE qu'emploie
## `_face` : `atan2(direction.x, direction.z)`. Recopier la convention plutôt
## que de l'inventer est ce qui garantit que le test et le moteur s'accordent
## sur quel axe est « devant » — la même prudence que `_ecart_regard_deg`.
##
## Nécessaire parce que le pivot au repos vaut `rotation.y = 0`, donc +Z, donc
## DROIT sur un agresseur posé en +Z : le premier passage rouge a mesuré 0,5°
## d'écart avant le coup, et « il se tourne » n'aurait alors rien prouvé.
func _tourner_le_dos(garde: EnemyBase, point: Vector3) -> void:
	var pivot: Node3D = garde.get_node_or_null("Pivot") as Node3D
	if pivot == null:
		return
	var fuite: Vector3 = garde.global_position - point
	pivot.rotation.y = atan2(fuite.x, fuite.z)


func _poursuit(garde: EnemyBase) -> bool:
	return garde.state() in [EnemyBase.State.CHASE, EnemyBase.State.ATTACK]


# --------------------------------------------------------------------------
# B1 + B2 + B3 + B6 — la riposte : observable, bornée, sans poursuite
# --------------------------------------------------------------------------
func test_un_garde_frappe_de_loin_se_tourne_avance_et_reste_chez_lui() -> void:
	await _monter(Vector3(0, 0.1, 20.0))
	var garde: EnemyBase = _pillard(Vector3(0, 0.1, 0))
	await _settle(6)
	_tourner_le_dos(garde, _player.global_position)

	var origine: Vector3 = garde.global_position
	var d: float = origine.distance_to(_player.global_position)
	check(d > POURSUITE,
		"préalable : l'agresseur est HORS territoire (%.2f m > %.1f)"
		% [d, POURSUITE])
	check_equal(garde.state(), EnemyBase.State.IDLE, "préalable : il dort")
	var ecart_avant: float = _ecart_regard_deg(garde, _player.global_position)
	check(ecart_avant > 45.0,
		"préalable NON VACUITÉ : il ne regarde PAS déjà l'agresseur "
		+ "(%.1f°) — sinon « il se tourne » ne prouverait rien" % ecart_avant)
	var pv_avant: float = float(garde.health().call("current"))

	_frapper(garde, _player)
	await _settle(90)

	# B1a — il a changé d'état pour un état d'éveil.
	check(garde.state() in [EnemyBase.State.SUSPICIOUS,
			EnemyBase.State.INVESTIGATE, EnemyBase.State.RETURN],
		"B1 — le garde frappé s'éveille (état %d), il ne reste pas IDLE"
		% garde.state())

	# B1b — il REGARDE l'agresseur : c'est la moitié observable qui manquait.
	var ecart_apres: float = _ecart_regard_deg(garde, _player.global_position)
	check(ecart_apres < 45.0,
		"B1 — il FAIT FACE à l'agresseur : %.1f° après le coup contre %.1f° "
		% [ecart_apres, ecart_avant] + "avant. C'est exactement ce que la "
		+ "réaction dégénérée ne faisait pas — `_last_known` valait sa propre "
		+ "position, donc `_face` sortait sur un vecteur nul")

	# B1c — et il BOUGE : « aucun garde ne doit rester une cible immobile ».
	var parcouru: float = garde.global_position.distance_to(origine)
	check(parcouru > 0.5,
		"B1 — il a quitté son poste de %.2f m vers la menace : un garde qui "
		% parcouru + "encaisse sans bouger est un mannequin")

	# B2 — mais jamais hors de son territoire.
	check(garde.global_position.distance_to(origine) <= POURSUITE,
		"B2 — il reste dans son territoire (%.2f m ≤ %.1f)"
		% [garde.global_position.distance_to(origine), POURSUITE])

	# B3 — et il ne poursuit pas.
	check(not _poursuit(garde),
		"B3 — aucune poursuite : ni CHASE ni ATTACK. Sinon un joueur tire "
		+ "la garnison entière hors de sa région, ce qu'ISS-083 a fermé")

	# B6 — aucune invulnérabilité inventée.
	check(float(garde.health().call("current")) < pv_avant,
		"B6 — le coup a bien retiré des points de vie (%.1f -> %.1f) : la "
		% [pv_avant, float(garde.health().call("current"))]
		+ "riposte ne s'achète pas avec une armure secrète")

	await _demonter()


# --------------------------------------------------------------------------
# B2bis — sous le feu RÉPÉTÉ, la frontière tient
# --------------------------------------------------------------------------
## Un seul coup ne prouve pas la borne : c'est le harcèlement qui la teste.
func test_sous_le_feu_repete_le_garde_ne_franchit_jamais_sa_frontiere() -> void:
	await _monter(Vector3(0, 0.1, 20.0))
	var garde: EnemyBase = _pillard(Vector3(0, 0.1, 0))
	await _settle(6)
	_tourner_le_dos(garde, _player.global_position)
	var origine: Vector3 = garde.global_position

	var maximum: float = 0.0
	for _tir: int in range(8):
		_frapper(garde, _player)
		await _settle(24)
		maximum = maxf(maximum, garde.global_position.distance_to(origine))
		check(not _poursuit(garde),
			"B3 — toujours aucune poursuite après un tir de plus")

	check(maximum <= POURSUITE,
		"B2 — huit flèches, et l'écart maximal au poste reste %.2f m ≤ %.1f. "
		% [maximum, POURSUITE] + "Le harcèlement ne déplace pas la frontière")
	check(maximum > 0.5,
		"NON VACUITÉ : il s'est réellement déplacé (%.2f m). Sans ce préalable, "
		% maximum + "un garde parfaitement immobile passerait la borne ci-dessus")

	await _demonter()


# --------------------------------------------------------------------------
# B7 — le voisinage converge, et ce n'est pas une promesse d'en-tête
# --------------------------------------------------------------------------
## L'en-tête affirme « ses voisins convergent ». Une affirmation qu'aucune
## assertion ne tient est exactement ce que ce dépôt appelle NON VÉRIFIÉ, donc
## la voici tenue.
##
## Le mécanisme est ANTÉRIEUR à ISS-085 : `_on_hit_received` émet déjà un bruit
## d'impact (`NoiseEvents.IMPACT_RADIUS` = 10 m) que les voisins entendent avec
## leur propre `hearing_range`. Ce cas ne prouve pas un ajout ; il ÉPINGLE la
## seule raison pour laquelle harceler de loin coûte quelque chose au joueur.
## Sans lui, quelqu'un pourrait un jour faire taire cet impact et l'en-tête
## deviendrait faux en silence.
func test_l_impact_reveille_le_voisinage_sans_le_faire_sortir() -> void:
	await _monter(Vector3(0, 0.1, 20.0))
	var frappe: EnemyBase = _pillard(Vector3(0, 0.1, 0))
	var voisin: EnemyBase = _pillard(Vector3(5.0, 0.1, 0))
	await _settle(6)
	_tourner_le_dos(frappe, _player.global_position)
	_tourner_le_dos(voisin, _player.global_position)
	var poste_voisin: Vector3 = voisin.global_position

	var d: float = poste_voisin.distance_to(frappe.global_position)
	check(d < NoiseEvents.IMPACT_RADIUS,
		"préalable : le voisin est À PORTÉE de l'impact (%.2f m < %.1f)"
		% [d, NoiseEvents.IMPACT_RADIUS])
	check_equal(voisin.state(), EnemyBase.State.IDLE,
		"préalable NON VACUITÉ : le voisin dort AVANT le coup — sinon son "
		+ "éveil ne prouverait rien")

	_frapper(frappe, _player)
	await _settle(60)

	check(voisin.state() in [EnemyBase.State.SUSPICIOUS,
			EnemyBase.State.INVESTIGATE],
		"B7 — le voisin a ENTENDU l'impact et vient voir (état %d)"
		% voisin.state())
	check(not _poursuit(voisin),
		"B7 — mais il ne poursuit pas un agresseur qu'il n'a jamais vu")
	check(voisin.global_position.distance_to(poste_voisin) <= POURSUITE,
		"B7 — et il reste sur son propre sol (%.2f m ≤ %.1f)"
		% [voisin.global_position.distance_to(poste_voisin), POURSUITE])

	await _demonter()


# --------------------------------------------------------------------------
# B4 — NON VACUITÉ : dans le territoire, le coup acquiert toujours
# --------------------------------------------------------------------------
func test_dans_le_territoire_un_coup_acquiert_toujours_la_cible() -> void:
	await _monter(Vector3(0, 0.1, 6.0))
	var garde: EnemyBase = _pillard(Vector3(0, 0.1, 0))
	await _settle(6)

	# Dos tourné : sa vision ne peut pas l'acquérir, donc SEUL le coup le
	# peut. Sans ça, le garde verrait le joueur à 6 m et ce cas serait vide —
	# il prouverait la perception, pas la riposte.
	_tourner_le_dos(garde, _player.global_position)
	var d: float = garde.global_position.distance_to(_player.global_position)
	check(d < POURSUITE,
		"préalable : l'agresseur est DANS le territoire (%.2f m)" % d)

	_frapper(garde, _player)
	await _settle(10)

	check(_poursuit(garde),
		"B4 — dans le territoire, être frappé fait toujours chasser. Sans ce "
		+ "cas, on « corrigerait » ISS-085 en rendant les gardes inertes et "
		+ "tout ce fichier resterait vert")

	await _demonter()


# --------------------------------------------------------------------------
# B5 — LA VALLÉE V1 N'A RIEN PERDU
# --------------------------------------------------------------------------
## Les ennemis sont partagés : `EnemyBase` sert la vallée V1, World V2, le
## donjon et l'arène. Une riposte mal posée casserait un jeu qu'on ne joue
## plus ici. Ce cas monte la VRAIE vallée V1 et vérifie que ses adversaires
## sont toujours là, vivants, et dans leur état de veille — pas qu'ils
## ripostent, ce que les cas ci-dessus prouvent déjà sur le socle commun.
func test_la_vallee_v1_garde_ses_adversaires_au_repos() -> void:
	remember_saves()
	remember_root()
	var gs: Node = _tree().root.get_node_or_null("GameState")
	if gs != null:
		gs.call("consume_pending_spawn")
	var vallee: Node3D = (load(VALLEY_V1_SCENE) as PackedScene) \
		.instantiate() as Node3D
	_tree().root.add_child(vallee)
	await _tree().process_frame
	for _i: int in range(4):
		await _tree().physics_frame

	var ennemis: Array[Node] = vallee.find_children(
		"*", "EnemyBase", true, false)
	check(ennemis.size() > 0,
		"préalable NON VACUITÉ : la vallée V1 peuple bien ses adversaires — "
		+ "%d trouvé(s). Sans eux la boucle ci-dessous serait vide"
		% ennemis.size())

	var eveilles: int = 0
	for e: Node in ennemis:
		var etat: int = int((e as EnemyBase).state())
		if etat in [EnemyBase.State.CHASE, EnemyBase.State.ATTACK,
				EnemyBase.State.SUSPICIOUS, EnemyBase.State.INVESTIGATE]:
			eveilles += 1
	check_equal(eveilles, 0,
		"B5 — aucun des %d adversaires de la vallée V1 ne s'éveille tout "
		% ennemis.size() + "seul au montage : la riposte ne se déclenche que "
		+ "sur un coup reçu, et personne n'a frappé")

	vallee.queue_free()
	await _tree().process_frame
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())
	restore_saves()
