## ISS-084 — ON NE CUISINE PAS AU FOYER D'UN CAMP QU'ON N'A PAS PRIS.
##
## LE DÉFAUT, tel que la contre-revue l'a trouvé. Le camp braise éteint son
## foyer tant que la garnison le tient : c'est la transformation qui rend la
## victoire visible (C6). Mais « éteindre » ne masque que le `CampfireProp` ;
## le `Campfire` INTERACTIF, `FeuDeCuisine`, reste dans le groupe
## `interactable` et fonctionne. Le joueur ouvre donc l'atelier de cuisine au
## milieu d'un camp ennemi, devant un foyer qu'il ne voit pas.
##
## POURQUOI LE MASQUAGE NE SUFFIT PAS, et c'est le fait qui gouverne tout le
## reste : `player_controller.gd::_select_interactable()` ne teste NI la
## visibilité NI `prompt_verb()`. Un nœud invisible reste sélectionnable, et
## `E` l'active. Le seul levier qui supprime l'invite sans quitter le groupe
## est un `prompt_verb()` VIDE — filtré par `_refresh_interact_focus()` et
## par le HUD.
##
## CE QUE LE CONTRAT NE PEUT PAS DEMANDER. `camp_checkpoint_place.gd` est
## GELÉ, et `test_world_v2_places_behavior.gd` exige un `Campfire` dans le
## groupe `interactable` — c'est un contrat de checkpoint, pas de décor. Le
## foyer ne sera donc ni démonté, ni déplacé, ni désinscrit. Ce fichier
## vérifie un ÉTAT, jamais une absence.
extends GateTestCase

const WORLD_V2_SCENE: String = "res://scenes/world_v2/WorldV2.tscn"
const VALLEY_V1_SCENE: String = "res://scenes/world/valley/ValleyWorld.tscn"
const DONNEES: String = "res://resources/world_v2/world_v2_camp_liberation.json"
const SLOT: String = "slot0"
const CAMP_ID: String = "camp.ember_terrace"
const GARNISON: String = "garrison.ember_camp"
const VERBE_ATTENDU: String = "Cuisiner"

var _world: Node3D = null


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _donnees() -> Dictionary:
	var brut: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(DONNEES))
	if not (brut is Dictionary):
		return {}
	for entree: Variant in ((brut as Dictionary).get("camps", []) as Array):
		var camp: Dictionary = entree as Dictionary
		if String(camp.get("id", "")) == CAMP_ID:
			return camp
	return {}


func _semer(payload: Dictionary) -> void:
	var base: Dictionary = {"schema": 4, "world_version": "neris_v2",
		"checkpoint": "world_v2.valley"}
	base.merge(payload, true)
	_tree().root.get_node_or_null("/root/SaveSystem").call("save_slot", SLOT, base)


func _tous_les_morts() -> Array:
	var ids: Array = []
	for suffixe: String in ["red.01", "red.02", "red.03", "blue.01"]:
		ids.append("%s.%s" % [GARNISON, suffixe])
	return ids


func _monter(scene: String) -> void:
	var gs: Node = _tree().root.get_node_or_null("GameState")
	if gs != null:
		gs.call("consume_pending_spawn")
	_world = (load(scene) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(_world)
	await _tree().process_frame
	# Deux vidages de file différés : le bâtisseur de garnisons, puis les
	# nœuds qui l'observent.
	for _i: int in range(3):
		await _tree().physics_frame
		await _tree().process_frame


func _demonter() -> void:
	_world = null
	var propre: bool = await restore_root()
	check(propre, "démontage propre — %s" % restore_root_reason())


## DÉMONTAGE LÉGER, entre deux montages d'un MÊME cas.
##
## DÉFAUT MESURÉ AU PREMIER PASSAGE ROUGE, et il valait la peine : appeler
## `restore_root()` DEUX fois pour un seul `remember_root()` a fait
## DISPARAÎTRE les six autoloads de la racine — GameState, EventBus,
## SaveSystem, AudioManager, SceneFlow, DevMode. Le balayage restaure vers
## l'état mémorisé ; le second passage l'a pris pour du résidu.
##
## Entre deux reprises, on retire donc le monde à la main, et on ne balaie
## qu'UNE fois, à la fin.
func _demonter_leger() -> void:
	if _world == null:
		return
	var monde: Node3D = _world
	_world = null
	_tree().root.remove_child(monde)
	monde.queue_free()
	for _i: int in range(4):
		await _tree().process_frame


## Le foyer INTERACTIF du camp, par son chemin de donnée — jamais par une
## recherche de classe, qui ramènerait aussi le feu de la vallée V1.
func _foyer_cuisine() -> Node:
	if _world == null:
		return null
	var chemin: String = String(_donnees().get("foyer_cuisine", ""))
	check(chemin != "",
		"préalable : la donnée du camp nomme son foyer de cuisine "
		+ "(champ `foyer_cuisine`) — sans lui ce fichier ne sait pas quoi viser")
	if chemin == "":
		return null
	return _world.get_node_or_null(chemin)


func _vivants() -> int:
	if _world == null:
		return -1
	var n: int = 0
	for e: Node in _world.find_children("*", "EnemyBase", true, false):
		var sante: Node = e.call("health") as Node
		if sante != null and not bool(sante.call("is_dead")):
			n += 1
	return n


# --------------------------------------------------------------------------
# A1 + A2 — camp TENU : aucun faux prompt, et la cuisine refuse
# --------------------------------------------------------------------------
func test_camp_tenu_le_foyer_ne_propose_rien_et_refuse_de_cuisiner() -> void:
	remember_saves()
	remember_root()
	_semer({})
	await _monter(WORLD_V2_SCENE)

	check_equal(_vivants(), 4,
		"préalable : les quatre gardes tiennent le camp — sans eux ce cas "
		+ "mesurerait un camp libéré")

	var foyer: Node = _foyer_cuisine()
	check_not_null(foyer, "le foyer de cuisine du camp existe (lieu GELÉ)")
	if foyer == null:
		await _demonter()
		restore_saves()
		return

	# Le contrat de checkpoint tient : ni démonté, ni désinscrit.
	check(foyer.is_in_group("interactable"),
		"le foyer reste dans le groupe `interactable` — "
		+ "test_world_v2_places_behavior.gd l'exige, c'est un contrat de "
		+ "checkpoint et non de décor")
	check(foyer is Campfire, "et il reste un Campfire")

	check_equal(String(foyer.call("prompt_verb")), "",
		"A1 — AUCUN faux prompt : le verbe est vide tant que les pillards "
		+ "tiennent le camp. C'est le SEUL levier qui efface l'invite sans "
		+ "quitter le groupe (`_refresh_interact_focus`, HUD)")

	check(not bool(foyer.call("interact", null)),
		"A2 — et la cuisine REFUSE : `interact()` rend faux avant même de "
		+ "chercher l'atelier. Un verbe vide seul ne suffirait pas — "
		+ "`_select_interactable()` ne le lit pas, donc `E` passerait encore")

	# A2bis — LE REFUS N'EST PAS MUET, et c'est ce qui manquait au premier
	# passage d'ISS-084. `interact()` rendait faux EN SILENCE : le joueur
	# appuyait sur `E` devant le feu et n'obtenait rien — exactement le défaut
	# nº1 du playtest du 2026-08-07, revenu par une autre porte. Le foyer dit
	# maintenant POURQUOI, par une clé de localisation (ISS-075), et c'est le
	# joueur qui porte la cadence anti-spam.
	var refus: String = String(foyer.call("refus_cle"))
	check(refus != "",
		"A2bis — le foyer tenu a une raison à donner, pas seulement un refus")
	check(Textes.ressemble_a_une_cle(refus),
		"A2bis — et cette raison est une CLÉ (« %s »), pas du texte écrit en "
		% refus + "dur : c'est la règle posée par ISS-075")
	check(Textes.brut(refus, Textes.LOCALE_SOURCE) != "",
		"A2bis — clé résoluble en français, sinon le joueur lirait ⟦%s⟧"
		% refus)

	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# A3 — camp LIBÉRÉ : la cuisine redevient ce qu'elle était
# --------------------------------------------------------------------------
func test_camp_libere_le_foyer_redevient_utilisable() -> void:
	remember_saves()
	remember_root()
	_semer({"enemies_slain": _tous_les_morts(), "camps_liberes": [CAMP_ID]})
	await _monter(WORLD_V2_SCENE)

	check_equal(_vivants(), 0,
		"préalable : la garnison persistée ne revient pas")

	var foyer: Node = _foyer_cuisine()
	check_not_null(foyer, "le foyer existe toujours")
	if foyer == null:
		await _demonter()
		restore_saves()
		return

	check_equal(String(foyer.call("prompt_verb")), VERBE_ATTENDU,
		"A3 — le camp pris, le foyer redit « %s ». NON VACUITÉ de A1 : si le "
		% VERBE_ATTENDU + "verbe était vide partout, A1 passerait sans rien "
		+ "prouver")

	await _demonter()
	restore_saves()


# --------------------------------------------------------------------------
# A4 — l'état survit à la sauvegarde et à la reprise
# --------------------------------------------------------------------------
## Deux montages successifs, deux slots différents, un seul verdict : l'état
## du foyer se DÉDUIT du monde à chaque reprise, il ne se mémorise pas dans le
## nœud. C'est le cas qui attrape un drapeau figé au premier `_ready()`.
func test_l_etat_du_foyer_se_deduit_a_chaque_reprise() -> void:
	remember_saves()
	remember_root()

	# Reprise 1 : partie neuve, camp tenu.
	_semer({})
	await _monter(WORLD_V2_SCENE)
	var tenu: String = String(_foyer_cuisine().call("prompt_verb")) \
		if _foyer_cuisine() != null else "<absent>"
	await _demonter_leger()

	# Reprise 2 : même session, slot d'une partie où le camp est tombé.
	_semer({"enemies_slain": _tous_les_morts()})
	await _monter(WORLD_V2_SCENE)
	var libere: String = String(_foyer_cuisine().call("prompt_verb")) \
		if _foyer_cuisine() != null else "<absent>"
	await _demonter()

	check_equal(tenu, "",
		"A4 — à la reprise d'une partie où le camp est TENU, le foyer se tait")
	check_equal(libere, VERBE_ATTENDU,
		"A4 — à la reprise d'une partie où le camp est TOMBÉ, il propose de "
		+ "cuisiner. Les deux dans la MÊME session : l'état est déduit, pas "
		+ "mémorisé")

	restore_saves()


# --------------------------------------------------------------------------
# A5 — NON-RÉGRESSION : les autres foyers du jeu ne sont jamais bloqués
# --------------------------------------------------------------------------
## Trois `Campfire` existent dans le dépôt : celui du camp V2, celui de la
## vallée V1 (`valley_world.gd`), celui de l'antichambre du boss. Les deux
## derniers n'ont AUCUNE garnison. Une condition qui les bloquerait retirerait
## la cuisine du reste du jeu — le genre de régression qu'on ne voit qu'en
## jouant, donc jamais ici.
func test_le_foyer_de_la_vallee_v1_reste_utilisable() -> void:
	remember_saves()
	remember_root()
	_semer({})
	await _monter(VALLEY_V1_SCENE)

	var foyers: Array[Node] = _world.find_children("*", "Campfire", true, false)
	check(foyers.size() > 0,
		"préalable NON VACUITÉ : la vallée V1 porte bien un feu de cuisine — "
		+ "%d trouvé(s). Sans lui la boucle ci-dessous serait vide" % foyers.size())

	for f: Node in foyers:
		check_equal(String(f.call("prompt_verb")), VERBE_ATTENDU,
			"A5 — le feu « %s » de la vallée V1 propose toujours de cuisiner : "
			% f.name + "la condition du camp doit être INERTE par défaut")

	await _demonter()
	restore_saves()
