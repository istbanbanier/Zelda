## ANCRAGES ET RÉCOMPENSES DES 31 LIEUX.
##
## Ce fichier existe à cause d'un échec précis : la première pose de
## récompenses a mis 31 coffres identiques dans la vallée, dont 23 « au centre
## du lieu » faute d'ancrage — des positions plausibles, jamais éprouvées,
## certaines dans un mur. Le test qui existait alors était vert : il comptait.
##
## On ne compte plus. On fait MARCHER un corps.
extends GateTestCase


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


## `user://slot0` SURVIT d'une exécution à l'autre, et la vallée l'applique au
## chargement. Sans cet effacement, un test qui ramasse une arme la retirait du
## monde pour toutes les exécutions suivantes : le compte d'armes au sol
## baissait tout seul, et le test finissait par échouer sur son propre passé.
func _wipe_save() -> void:
	var save_system: Node = _tree().root.get_node_or_null("SaveSystem")
	if save_system == null:
		return
	var path: String = String(save_system.call("slot_path", ValleyWorld.SAVE_SLOT))
	if not path.is_empty() and FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _open_valley() -> ValleyWorld:
	_wipe_save()
	return await _mount_valley()


## Rouvre la vallée SANS effacer la sauvegarde — c'est le geste du joueur qui
## clique « Continuer ».
func _reopen_valley() -> ValleyWorld:
	return await _mount_valley()


func _mount_valley() -> ValleyWorld:
	var valley: ValleyWorld = (load("res://scenes/world/valley/ValleyWorld.tscn")
		as PackedScene).instantiate() as ValleyWorld
	_tree().root.add_child(valley)
	await _settle(12)
	return valley


func _close(valley: Node) -> void:
	valley.get_parent().remove_child(valley)
	valley.queue_free()
	await _settle(2)


## Chaque lieu déclaré porte UN ancrage, et chaque ancrage nomme un lieu réel.
## Les deux sens comptent : un ancrage orphelin poserait une récompense là où
## aucun lieu ne promet rien.
func test_every_place_carries_exactly_one_anchor() -> void:
	var valley: ValleyWorld = await _open_valley()

	var places: Dictionary = {}
	for node: Node in valley.find_children("*", "PointOfInterest", true, false):
		var poi: PointOfInterest = node as PointOfInterest
		if not String(poi.poi_id).is_empty():
			places[poi.poi_id] = true

	var anchors: Dictionary = {}
	var orphans: Array[String] = []
	for node: Node in valley.find_children("*", "RewardAnchor", true, false):
		var anchor: RewardAnchor = node as RewardAnchor
		check(not anchors.has(anchor.place_id),
			"ancrage unique pour %s" % anchor.place_id)
		anchors[anchor.place_id] = anchor
		if not places.has(anchor.place_id):
			orphans.append(String(anchor.place_id))

	var missing: Array[String] = []
	for place: StringName in places:
		if not anchors.has(place):
			missing.append(String(place))

	check(places.size() >= 31,
		"%d lieux déclarés (cible : 31)" % places.size())
	check(missing.is_empty(),
		"aucun lieu sans ancrage — manquants : %s" % ", ".join(missing))
	check(orphans.is_empty(),
		"aucun ancrage orphelin — orphelins : %s" % ", ".join(orphans))

	# Un point d'approche non déclaré rendrait l'audit complaisant : il
	# partirait de l'ancrage lui-même et prouverait un trajet de zéro mètre.
	var undeclared: Array[String] = []
	for place: StringName in anchors:
		if not (anchors[place] as RewardAnchor).has_declared_approach():
			undeclared.append(String(place))
	check(undeclared.is_empty(),
		"chaque ancrage déclare d'où l'on vient — sans approche : %s"
		% ", ".join(undeclared))

	await _close(valley)


## LE test du contrat : sol réel, dégagement au gabarit, on y arrive, on en
## repart. Les défauts sont NOMMÉS un par un — « 4 ancrages en échec » n'aide
## personne à réparer quoi que ce soit.
func test_a_body_reaches_every_reward_and_leaves_again() -> void:
	var valley: ValleyWorld = await _open_valley()
	var verdicts: Array[RewardAnchor.Verdict] = \
		await RewardAnchorAudit.audit_all(_tree(), valley)

	check(verdicts.size() >= 31,
		"%d ancrage(s) audité(s)" % verdicts.size())
	var broken: Array[String] = []
	for verdict: RewardAnchor.Verdict in verdicts:
		if not verdict.ok():
			broken.append(verdict.describe())
	if not broken.is_empty():
		for line: String in broken:
			print("[ancrage] %s" % line)
	check(broken.is_empty(),
		"les %d ancrages sont sains (%d en défaut)"
		% [verdicts.size(), broken.size()])

	await _close(valley)


## §3 exige de la VARIÉTÉ. Trente et un coffres identiques satisfont la lettre
## et trahissent l'intention : le test refuse donc qu'une seule nature domine.
func test_the_rewards_are_varied_and_none_is_missing() -> void:
	var valley: ValleyWorld = await _open_valley()
	check_not_null(valley.rewards, "la vallée pose des récompenses")

	var placed: int = valley.rewards.placed_count()
	var skipped: Array[StringName] = valley.rewards.skipped_places()
	check(placed >= 31, "%d récompense(s) posée(s)" % placed)
	var names: Array[String] = []
	for place: StringName in skipped:
		names.append(String(place))
	check(skipped.is_empty(),
		"aucun lieu laissé sans récompense — manquants : %s" % ", ".join(names))

	var by_kind: Dictionary = valley.rewards.counts_by_kind()
	check(by_kind.size() >= 4,
		"%d natures de récompense distinctes (minimum 4)" % by_kind.size())
	var dominant: int = 0
	for kind: int in by_kind:
		dominant = maxi(dominant, int(by_kind[kind]))
	check(float(dominant) <= float(placed) * 0.45,
		"aucune nature ne dépasse 45%% du total (la plus fréquente : %d sur %d)"
		% [dominant, placed])

	# Ce que ce lot ne fait PAS doit rester visible, pas se dissoudre.
	var deferred: Array[StringName] = valley.rewards.deferred_gates()
	print("[récompenses] %d lieu(x) dont la condition d'ouverture reste à faire"
		% deferred.size())

	await _close(valley)


## Les identifiants persistants sont la seule chose qui empêche une récompense
## de se reprendre deux fois. Un doublon les rendrait indiscernables.
func test_reward_identifiers_are_unique_across_the_whole_valley() -> void:
	var valley: ValleyWorld = await _open_valley()
	var seen: Dictionary = {}
	var duplicates: Array[String] = []
	var total: int = 0

	for node: Node in valley.find_children("*", "Chest", true, false):
		total += 1
		var id: String = String((node as Chest).chest_id)
		if seen.has(id):
			duplicates.append(id)
		seen[id] = true
	for node: Node in valley.find_children("*", "WeaponPickup", true, false):
		total += 1
		var id: String = String((node as WeaponPickup).pickup_id)
		if seen.has(id):
			duplicates.append(id)
		seen[id] = true
	for node: Node in valley.find_children("*", "IngredientPickup", true, false):
		total += 1
		var id: String = String((node as IngredientPickup).pickup_id)
		if seen.has(id):
			duplicates.append(id)
		seen[id] = true
	for node: Node in valley.find_children("*", "StoryFragment", true, false):
		total += 1
		var id: String = String((node as StoryFragment).fragment_id)
		if seen.has(id):
			duplicates.append(id)
		seen[id] = true

	check(duplicates.is_empty(),
		"%d identifiants sur %d objets, aucun doublon — doublons : %s"
		% [seen.size(), total, ", ".join(duplicates)])
	check(not seen.has(""), "aucun objet de récompense sans identifiant")

	await _close(valley)


## Les armes au sol sont une nature à part entière, pas un coffre déguisé :
## elles se ramassent avec E, refusent proprement un inventaire plein, et ne
## reviennent pas après un rechargement.
func test_ground_weapons_are_real_pickups() -> void:
	var valley: ValleyWorld = await _open_valley()
	var pickups: Array[WeaponPickup] = []
	for node: Node in valley.find_children("*", "WeaponPickup", true, false):
		var pickup: WeaponPickup = node as WeaponPickup
		if String(pickup.pickup_id).contains(".pickup."):
			pickups.append(pickup)
	check(pickups.size() >= 3,
		"%d arme(s) posée(s) au sol par les lieux" % pickups.size())

	var player: PlayerController = valley.player()
	check_not_null(player, "la vallée a son joueur")
	var inventory: InventoryComponent = player.inventory()
	check_not_null(inventory, "le joueur a son inventaire")

	var target: WeaponPickup = pickups[0]
	check_not_null(target.definition, "l'arme au sol porte une définition")
	inventory.clear_weapons()
	var before: int = inventory.weapon_count()
	check(target.interact(player), "E ramasse l'arme au sol")
	check_equal(inventory.weapon_count(), before + 1,
		"…et l'arme entre réellement dans l'inventaire")

	# Inventaire PLEIN : l'arme reste au sol, rien n'est perdu (§11.3).
	var spare: WeaponPickup = pickups[1]
	while inventory.weapon_count() < 8:
		inventory.add_weapon(WeaponInstance.create(spare.definition))
	check_equal(inventory.weapon_count(), 8, "inventaire saturé à huit armes")
	check(not spare.interact(player),
		"un inventaire plein REFUSE le ramassage")
	check(is_instance_valid(spare),
		"…et l'arme refusée reste au sol, pas perdue")
	check_equal(inventory.weapon_count(), 8,
		"…et rien ne s'est ajouté en douce")

	await _close(valley)


## La règle du monde ouvert : « aucune seconde récompense après rechargement ».
## On marque l'objet pris comme le fait la sauvegarde, puis on vérifie qu'il ne
## rend plus rien.
func test_a_taken_reward_never_pays_twice() -> void:
	var valley: ValleyWorld = await _open_valley()
	var player: PlayerController = valley.player()
	var inventory: InventoryComponent = player.inventory()
	inventory.clear_weapons()

	# Un coffre encore FERMÉ : `user://slot0` survit d'une exécution à l'autre,
	# et prendre le premier venu revenait à tester un coffre que la sauvegarde
	# avait déjà rouvert — un échec qui n'apprenait rien sur le code.
	var chest: Chest = null
	for node: Node in valley.find_children("*", "Chest", true, false):
		var candidate: Chest = node as Chest
		if String(candidate.chest_id).contains(".chest.") \
				and not candidate.is_opened():
			chest = candidate
			break
	check_not_null(chest, "la vallée a un coffre de découverte encore fermé")
	check(chest.interact(player), "E ouvre le coffre")
	check(not chest.interact(player),
		"…et un coffre déjà ouvert ne redonne rien")

	# `mark_opened_silently` est le chemin exact qu'emprunte le chargement.
	var reloaded: Chest = null
	for node: Node in valley.find_children("*", "Chest", true, false):
		var candidate: Chest = node as Chest
		if candidate != chest and not candidate.is_opened() \
				and String(candidate.chest_id).contains(".chest."):
			reloaded = candidate
			break
	check_not_null(reloaded, "un second coffre de découverte existe")
	reloaded.mark_opened_silently()
	check(not reloaded.interact(player),
		"un coffre restauré « ouvert » par la sauvegarde ne redonne rien")

	await _close(valley)


## Un fragment d'histoire se lit, se relit, et n'annonce sa découverte
## qu'une fois — sinon le journal compterait deux fois le même lieu.
func test_story_fragments_are_read_once() -> void:
	var valley: ValleyWorld = await _open_valley()
	var fragment: StoryFragment = null
	for node: Node in valley.find_children("*", "StoryFragment", true, false):
		fragment = node as StoryFragment
		break
	check_not_null(fragment, "la vallée porte au moins un fragment d'histoire")
	check(not fragment.text.strip_edges().is_empty(),
		"le fragment a un texte à lire")

	var announced: Array[StringName] = []
	fragment.read_first_time.connect(func(id: StringName) -> void:
		announced.append(id))
	var player: PlayerController = valley.player()
	check(fragment.interact(player), "E lit le fragment")
	check(fragment.interact(player), "…et il se relit")
	check_equal(announced.size(), 1,
		"la découverte n'est annoncée qu'à la PREMIÈRE lecture")

	await _close(valley)


## L'ALLER-RETOUR complet par la sauvegarde : ouvrir un coffre, ramasser une
## arme, quitter la vallée, la rouvrir. Marquer un objet « déjà pris » à la
## main prouve que la restauration fonctionne ; seul ce test prouve que
## l'ÉCRITURE a eu lieu — et c'est elle qui manquait, les récompenses étant
## bâties après l'application de la sauvegarde.
func test_rewards_survive_a_real_save_and_reload() -> void:
	var valley: ValleyWorld = await _open_valley()
	var player: PlayerController = valley.player()
	player.inventory().clear_weapons()

	var chest_id: StringName = &""
	for node: Node in valley.find_children("*", "Chest", true, false):
		var chest: Chest = node as Chest
		if String(chest.chest_id).contains(".chest.") and not chest.is_opened():
			chest_id = chest.chest_id
			check(chest.interact(player), "E ouvre le coffre %s" % chest_id)
			break
	check(not String(chest_id).is_empty(), "un coffre de découverte a été ouvert")

	var pickup_id: StringName = &""
	for node: Node in valley.find_children("*", "WeaponPickup", true, false):
		var pickup: WeaponPickup = node as WeaponPickup
		if String(pickup.pickup_id).contains(".pickup."):
			pickup_id = pickup.pickup_id
			check(pickup.interact(player),
				"E ramasse l'arme %s" % pickup_id)
			break
	check(not String(pickup_id).is_empty(), "une arme de lieu a été ramassée")
	await _settle(4)
	await _close(valley)

	# « Continuer » : la sauvegarde est celle que le jeu vient d'écrire.
	var again: ValleyWorld = await _reopen_valley()
	var found_chest: Chest = null
	for node: Node in again.find_children("*", "Chest", true, false):
		if (node as Chest).chest_id == chest_id:
			found_chest = node as Chest
			break
	check_not_null(found_chest, "le coffre existe toujours après rechargement")
	check(found_chest.is_opened(),
		"…et il est TOUJOURS ouvert : pas de second butin")

	var still_there: bool = false
	for node: Node in again.find_children("*", "WeaponPickup", true, false):
		if (node as WeaponPickup).pickup_id == pickup_id:
			still_there = true
			break
	check(not still_there,
		"l'arme ramassée n'est pas revenue au sol (%s)" % pickup_id)

	await _close(again)
	_wipe_save()
