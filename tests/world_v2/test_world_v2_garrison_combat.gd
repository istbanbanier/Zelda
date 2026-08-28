## ISS-074 — LA RENCONTRE EXISTE VRAIMENT : engagement, dégâts, victoire, mort.
##
## Le portail `test_world_v2_iss074_portail.gd` prouve que la garnison est
## POSÉE, gouvernée, atteignable et persistante. Il ne prouve pas qu'on peut
## SE BATTRE avec elle. Ce fichier-là s'en charge, et il le fait dans le monde
## réel — pas dans une arène de laboratoire — parce que c'est le placement
## réel, le terrain réel et la navigation réelle qui décident si une rencontre
## a lieu.
##
## POURQUOI CES PREUVES VIVENT ICI ET NON DANS LE PORTAIL D'EXPORT. Une build
## exportée, pilotée au clavier synthétique sous Xvfb, ne peut pas prouver un
## échange de coups de façon déterministe : elle prouve l'EMPAQUETAGE — que
## rien ne manque, que la persistance traverse un vrai redémarrage de
## processus. Le combat, lui, se prouve là où l'on peut lire des points de vie.
## Prétendre l'inverse produirait un portail lent, instable, et qui mentirait
## un jour sur deux.
##
## DEUX PIÈGES DÉJÀ PAYÉS AILLEURS, ÉVITÉS ICI. `test_creature_assets.gd`
## raconte le premier : appeler `AttackController.try_attack()` puis
## `update()` à la main fait partir un coup qui ne devient jamais actif — le
## socle `EnemyBase` n'avance l'attaque que dans l'état ATTACK, et le test
## mesure alors le harnais, pas le jeu. Ici, l'ennemi décide seul, et le
## joueur frappe par `InputIntent.attack_pressed`, exactement comme une touche.
## Le second : la perception ne tourne qu'un tick physique sur
## `PERCEPTION_INTERVAL = 6` — un test qui n'attend que trois images conclut à
## un ennemi aveugle qui ne l'est pas.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const SLOT: String = "slot0"
const CHAMP_MORTS: String = "enemies_slain"
## Six ticks pour une passe de perception ; on en laisse largement plus, et on
## sort dès que la condition est vraie plutôt que d'attendre le pire cas.
const TICKS_PERCEPTION: int = 90
const TICKS_ATTAQUE: int = 260
const DISTANCE_ENGAGEMENT_M: float = 6.0

var _world: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _monter() -> void:
	var gs: Node = _tree().root.get_node_or_null("GameState")
	if gs != null:
		gs.call("consume_pending_spawn")
	_world = (load(WORLD_V2_SCENE) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_world)
	await _tree().process_frame
	await _tree().physics_frame
	await _tree().physics_frame
	await _tree().process_frame
	await _tree().physics_frame


func _demonter() -> void:
	_world = null
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())


func _ennemis() -> Array[Node]:
	if _world == null:
		return []
	return _world.find_children("*", "EnemyBase", true, false)


func _joueur() -> PlayerController:
	if _world == null:
		return null
	var trouves: Array[Node] = _world.find_children("*", "PlayerController",
		true, false)
	return trouves[0] as PlayerController if not trouves.is_empty() else null


## Devant l'ennemi, dans son cône : l'avant d'un pivot est +Z (`_face()` fait
## `atan2(x, z)` et la perception lit `basis.z`).
func _devant(ennemi: Node3D, distance: float) -> Vector3:
	var pivot: Node3D = ennemi.get_node_or_null("Pivot") as Node3D
	var lacet: float = pivot.rotation.y if pivot != null else 0.0
	return ennemi.global_position \
		+ Vector3(sin(lacet), 0.0, cos(lacet)) * distance


func _poser_le_heros(joueur: PlayerController, ou: Vector3) -> void:
	joueur.velocity = Vector3.ZERO
	joueur.global_position = ou
	joueur.reset_physics_interpolation()


## Attend qu'une condition devienne vraie, sans dépasser un plafond de ticks.
## Rendre le nombre de ticks consommés permet au message d'échec de dire
## « jamais » plutôt que « pas encore ».
func _attendre(condition: Callable, plafond: int) -> int:
	for tick: int in range(plafond):
		if bool(condition.call()):
			return tick
		await _tree().physics_frame
	return -1


func _lire_slot() -> Dictionary:
	var system: Node = _tree().root.get_node_or_null("SaveSystem")
	if system == null or not bool(system.call("has_save", SLOT)):
		return {}
	return system.call("load_slot", SLOT) as Dictionary


func _ecrire_slot(payload: Dictionary) -> bool:
	var system: Node = _tree().root.get_node_or_null("SaveSystem")
	return false if system == null else bool(system.call("save_slot", SLOT,
		payload))


func _partie_en_cours() -> Dictionary:
	return {
		"schema": 4,
		"world_version": String(WorldIds.V2_WORLD_ID),
		"checkpoint": "world_v2.valley",
		"playtime_seconds": 120.0,
		"boss_defeated": false,
	}


# --------------------------------------------------------------------------
# L'ENGAGEMENT — l'ennemi décide seul de poursuivre
# --------------------------------------------------------------------------
func test_un_garde_engage_le_heros_de_lui_meme() -> void:
	remember_saves()
	remember_root()
	await _monter()
	var ennemis: Array[Node] = _ennemis()
	var joueur: PlayerController = _joueur()
	check(ennemis.size() >= 1, "la garnison est posée")
	check_not_null(joueur, "le héros est dans le monde")
	if ennemis.is_empty() or joueur == null:
		await _demonter()
		restore_saves()
		return

	var garde: EnemyBase = ennemis[0] as EnemyBase
	check_equal(garde.state_name(), &"idle",
		"le garde est au repos AVANT que le héros n'arrive — sinon la suite "
		+ "ne prouverait rien")
	_poser_le_heros(joueur, _devant(garde, DISTANCE_ENGAGEMENT_M))
	var ticks: int = await _attendre(
		func() -> bool: return garde.state_name() == &"chase",
		TICKS_PERCEPTION)
	check(ticks >= 0,
		"le garde PASSE de lui-même en poursuite quand le héros entre dans "
		+ "son cône à %.0f m — état atteint : %s après %d tick(s)"
			% [DISTANCE_ENGAGEMENT_M, garde.state_name(), TICKS_PERCEPTION])
	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# LES DÉGÂTS, DANS LES DEUX SENS
# --------------------------------------------------------------------------
## LE PREMIER ROUGE DE CE CAS A APPRIS QUELQUE CHOSE, et il est gardé ici.
## Les deux sens étaient d'abord mesurés dans UNE seule fonction : le héros
## posé à 1,3 m, on pressait l'attaque et on attendait. Le garde blessait bien
## le héros — mais le héros ne blessait jamais le garde, 45,0 pv au départ,
## 45,0 après 260 ticks. La cause n'est pas le harnais : `_process_input()`
## n'engage une attaque légère QUE `if _mode == Mode.LOCOMOTION and
## intent.attack_pressed and is_on_floor()`. Or le garde, lui, avait déjà
## engagé — le héros passait donc l'essentiel de son temps en HURT, mode dans
## lequel le jeu REFUSE l'attaque. Le test mesurait une règle de game design
## en croyant mesurer une hitbox.
##
## D'où deux cas séparés, chacun dans son monde : le héros frappe pendant que
## les gardes sont encore au repos, puis, dans un monde neuf, il encaisse.
func test_le_heros_blesse_un_garde() -> void:
	remember_saves()
	remember_root()
	await _monter()
	var ennemis: Array[Node] = _ennemis()
	var joueur: PlayerController = _joueur()
	check(not ennemis.is_empty() and joueur != null,
		"garnison et héros présents")
	if ennemis.is_empty() or joueur == null:
		await _demonter()
		restore_saves()
		return

	var garde: EnemyBase = ennemis[0] as EnemyBase
	var pv_avant: float = garde.health().current()
	var intention: InputIntent = InputIntent.new()
	joueur.set_intent_source(intention)
	_poser_le_heros(joueur, _devant(garde, 1.3))
	# Le héros doit d'abord RETROUVER LE SOL : `is_on_floor()` découle du
	# dernier `move_and_slide()`, et une attaque lancée en l'air est refusée.
	var au_sol: int = await _attendre(
		func() -> bool: return joueur.is_on_floor(), 40)
	check(au_sol >= 0, "le héros a repris pied avant de frapper")

	# ET IL DOIT REGARDER LE GARDE. La hitbox d'arme pend sous `VisualRoot`
	# (`hitbox_path = "../../VisualRoot/WeaponHitbox"`), et c'est `VisualRoot`
	# seul qui tourne — « le corps ne tourne jamais », dit la scène. Un héros
	# posé à bonne distance mais orienté ailleurs frappe donc dans le vide, et
	# c'est EXACTEMENT ce que le premier rouge montrait : attaque en phase
	# RECOVERY, garde intact. L'avant de `VisualRoot` est +Z, comme celui du
	# pivot d'un ennemi.
	var visuel: Node3D = joueur.get_node("VisualRoot") as Node3D
	var vers_garde: Vector3 = garde.global_position - joueur.global_position
	var lacet: float = atan2(vers_garde.x, vers_garde.z)
	var touche: int = await _attendre(
		func() -> bool:
			visuel.rotation.y = lacet
			intention.attack_pressed = true
			return garde.health().current() < pv_avant,
		TICKS_ATTAQUE)
	check(touche >= 0,
		"le héros BLESSE le garde par sa hitbox d'arme — %.1f pv au départ, "
			% pv_avant
		+ "%.1f après %d tick(s) (au sol : %s, phase d'attaque : %d)"
			% [garde.health().current(), TICKS_ATTAQUE,
				str(joueur.is_on_floor()),
				int(joueur.attack_controller().phase())])
	await _demonter()
	restore_saves()


func test_un_garde_blesse_le_heros() -> void:
	remember_saves()
	remember_root()
	await _monter()
	var ennemis: Array[Node] = _ennemis()
	var joueur: PlayerController = _joueur()
	check(not ennemis.is_empty() and joueur != null,
		"garnison et héros présents")
	if ennemis.is_empty() or joueur == null:
		await _demonter()
		restore_saves()
		return

	var garde: EnemyBase = ennemis[0] as EnemyBase
	var pv_avant: float = joueur.health().current()
	# Aucune intention : le héros ne fait RIEN. Tout ce qui suit est la
	# décision du garde — perception, poursuite, télégraphe, frappe.
	joueur.set_intent_source(InputIntent.new())
	_poser_le_heros(joueur, _devant(garde, DISTANCE_ENGAGEMENT_M))
	var touche: int = await _attendre(
		func() -> bool: return joueur.health().current() < pv_avant,
		TICKS_ATTAQUE)
	check(touche >= 0,
		"le garde BLESSE le héros de sa propre initiative — %.1f pv au "
			% pv_avant
		+ "départ, %.1f après %d tick(s) (état du garde : %s)"
			% [joueur.health().current(), TICKS_ATTAQUE, garde.state_name()])
	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# LA VICTOIRE — la garnison entière tombe, et chaque mort est inscrite
# --------------------------------------------------------------------------
func test_la_garnison_entiere_peut_tomber_et_chaque_mort_est_inscrite() -> void:
	remember_saves()
	check(_ecrire_slot(_partie_en_cours()), "une partie en cours existe")
	remember_root()
	await _monter()
	var ennemis: Array[Node] = _ennemis()
	check_equal(ennemis.size(), 4, "quatre gardes avant l'assaut")
	if ennemis.size() != 4:
		await _demonter()
		restore_saves()
		return

	for ennemi: Node in ennemis:
		var coup: DamageEvent = DamageEvent.new()
		coup.amount = 9999.0
		(ennemi as EnemyBase).health().take_damage(coup)
	for _i: int in range(12):
		await _tree().physics_frame

	var debout: int = 0
	for ennemi: Node in ennemis:
		if not (ennemi as EnemyBase).health().is_dead():
			debout += 1
	check_equal(debout, 0, "aucun garde ne reste debout")

	var morts: Array = _lire_slot().get(CHAMP_MORTS, []) as Array
	check_equal(morts.size(), 4,
		"les QUATRE morts sont inscrites une à une — obtenu %d" % morts.size())

	_world = null
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())
	remember_root()
	await _monter()
	check_equal(_ennemis().size(), 0,
		"le camp reste vide au remontage : la victoire tient")
	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# LA MORT DU HÉROS — elle ne ressuscite pas ce qu'il avait abattu
# --------------------------------------------------------------------------
func test_la_mort_du_heros_ne_ressuscite_pas_les_gardes_abattus() -> void:
	remember_saves()
	check(_ecrire_slot(_partie_en_cours()), "une partie en cours existe")
	remember_root()
	await _monter()
	var ennemis: Array[Node] = _ennemis()
	var joueur: PlayerController = _joueur()
	check_equal(ennemis.size(), 4, "quatre gardes au départ")
	if ennemis.size() != 4 or joueur == null:
		await _demonter()
		restore_saves()
		return

	var abattu: EnemyBase = ennemis[0] as EnemyBase
	var id_abattu: String = String(abattu.get_meta(&"encounter_id", &""))
	var coup: DamageEvent = DamageEvent.new()
	coup.amount = 9999.0
	abattu.health().take_damage(coup)
	for _i: int in range(8):
		await _tree().physics_frame

	# Puis le héros tombe à son tour.
	var fatal: DamageEvent = DamageEvent.new()
	fatal.amount = 9999.0
	joueur.health().take_damage(fatal)
	for _i: int in range(8):
		await _tree().physics_frame
	check(bool(joueur.health().is_dead()), "le héros est mort")

	# « Réessayer » repasse par un montage du monde : c'est ce qu'on rejoue.
	_world = null
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())
	remember_root()
	await _monter()
	var restants: Array[Node] = _ennemis()
	check_equal(restants.size(), 3,
		"trois gardes au retour : mourir ne rend pas au camp celui qu'on "
		+ "avait abattu — obtenu %d" % restants.size())
	var revenus: Array[String] = []
	for e: Node in restants:
		if String(e.get_meta(&"encounter_id", &"")) == id_abattu:
			revenus.append(id_abattu)
	check(revenus.is_empty(),
		"« %s » n'est pas revenu" % id_abattu)
	await _demonter()
	restore_saves()
