## Armes et inventaire — la couche de données (MASTER_SPEC §5.9, §11.1–§11.3).
##
## Le premier test est L'INVARIANT de CLAUDE.md : « deux exemplaires d'une arme
## ne partagent jamais leur durabilité ». Il garde les deux directions du bug :
## l'exemplaire jumeau ET la définition partagée doivent rester intacts quand un
## exemplaire s'use — une durabilité écrite dans la ressource rougit ici.
extends GateTestCase

const SWORD: String = "res://resources/weapons/worn_sword.tres"


func _sword() -> WeaponDefinition:
	return load(SWORD) as WeaponDefinition


func test_two_instances_never_share_durability() -> void:
	## L'invariant de CLAUDE.md, au mot près.
	var definition: WeaponDefinition = _sword()
	var first: WeaponInstance = WeaponInstance.create(definition)
	var second: WeaponInstance = WeaponInstance.create(definition)
	check(first.instance_id != second.instance_id,
		"deux exemplaires n'ont jamais le même identifiant")

	for i: int in range(5):
		first.apply_hit_wear()

	check_equal(first.current_durability, 19, "l'exemplaire usé a perdu 5 points")
	check_equal(second.current_durability, 24,
		"le jumeau est INTACT — sa durabilité n'est pas partagée")
	check_equal(definition.max_durability, 24,
		"la DÉFINITION est immuable — l'usure ne s'écrit jamais dans la ressource")


func test_the_six_definitions_match_the_spec_table() -> void:
	## §11.1, ligne à ligne : dégâts / durabilité / portée / conductivité. Une
	## mutation d'un `.tres` livré rougit ici (doctrine Y5 : épingler ET mesurer).
	var expected: Array[Array] = [
		["wood_club", 8.0, 18, 1.6, 0.05],
		["worn_sword", 12.0, 24, 1.7, 0.85],
		["spear", 10.0, 30, 2.7, 0.70],
		["heavy_axe", 22.0, 20, 1.9, 0.80],
		["simple_bow", 9.0, 28, 0.0, 0.20],
		["conductive_blade", 26.0, 16, 1.8, 1.00],
	]
	for row: Array in expected:
		var path: String = "res://resources/weapons/%s.tres" % row[0]
		var definition: WeaponDefinition = load(path) as WeaponDefinition
		check_not_null(definition, path)
		if definition == null:
			continue
		check_equal(String(definition.id), String(row[0]), "%s : id" % row[0])
		check_approx(definition.base_damage, row[1], 0.001, "%s : dégâts §11.1" % row[0])
		check_equal(definition.max_durability, row[2], "%s : durabilité §11.1" % row[0])
		check_approx(definition.reach_m, row[3], 0.001, "%s : portée §11.1" % row[0])
		check_approx(definition.conductivity, row[4], 0.001,
			"%s : conductivité §11.1" % row[0])
		if definition.weapon_type != &"bow":
			check(not definition.attack_set.is_empty(),
				"%s : une arme de mêlée déclare sa chaîne d'attaques" % row[0])


func test_the_warning_fires_once_at_a_quarter() -> void:
	## §11.2 : « à 25 % : avertissement bref [...] sans spam » — une seule fois.
	var weapon: WeaponInstance = WeaponInstance.create(_sword())
	var warnings: Array[int] = [0]
	weapon.durability_warned.connect(func() -> void: warnings[0] += 1)

	for i: int in range(18):   # 24 → 6 = exactement 25 %
		weapon.apply_hit_wear()
	check_equal(warnings[0], 1, "l'avertissement part au passage sous 25 %")

	weapon.apply_hit_wear()
	weapon.apply_hit_wear()
	check_equal(warnings[0], 1, "et jamais une deuxième fois — pas de spam")


func test_rupture_is_emitted_once_and_durability_never_negative() -> void:
	## §11.2 : rupture à zéro, une fois ; le compteur ne descend jamais sous zéro.
	var weapon: WeaponInstance = WeaponInstance.create(_sword())
	var broke_count: Array[int] = [0]
	weapon.broke.connect(func() -> void: broke_count[0] += 1)

	for i: int in range(30):   # 6 de plus que la durabilité
		weapon.apply_hit_wear()

	check_equal(broke_count[0], 1, "la rupture est émise une seule fois")
	check_equal(weapon.current_durability, 0, "le compteur s'arrête à zéro")
	check(weapon.is_broken(), "l'exemplaire est fini")


func test_inventory_refuses_overflow_and_duplicates() -> void:
	## §11.3 : « huit armes » et « aucun doublon d'instance ».
	var inventory: InventoryComponent = InventoryComponent.new()
	var definition: WeaponDefinition = _sword()
	for i: int in range(InventoryComponent.MAX_WEAPONS):
		check(inventory.add_weapon(WeaponInstance.create(definition)),
			"l'arme %d entre (limite : 8)" % (i + 1))
	check(not inventory.add_weapon(WeaponInstance.create(definition)),
		"la neuvième est refusée (§11.3)")
	check_equal(inventory.weapon_count(), 8, "le compte est plafonné")

	var lean: InventoryComponent = InventoryComponent.new()
	var instance: WeaponInstance = WeaponInstance.create(definition)
	check(lean.add_weapon(instance), "l'exemplaire entre une fois")
	check(not lean.add_weapon(instance), "le MÊME exemplaire est refusé — pas de doublon")
	check_equal(lean.weapon_count(), 1, "un seul exemplaire détenu")
	inventory.free()
	lean.free()


func test_removal_equips_the_next_weapon_then_bare_hands() -> void:
	## §11.2 : « équiper suivante ou mains nues ». La première arme ajoutée à
	## mains nues est prise en main d'office (§1 : trouver une arme, c'est la
	## prendre).
	var inventory: InventoryComponent = InventoryComponent.new()
	var definition: WeaponDefinition = _sword()
	var first: WeaponInstance = WeaponInstance.create(definition)
	var second: WeaponInstance = WeaponInstance.create(definition)
	var third: WeaponInstance = WeaponInstance.create(definition)
	inventory.add_weapon(first)
	inventory.add_weapon(second)
	inventory.add_weapon(third)
	check_equal(inventory.equipped(), first, "la première arme trouvée est en main")

	check(inventory.remove_weapon(first), "l'arme en main se retire (rupture)")
	check_equal(inventory.equipped(), second, "la SUIVANTE est équipée d'office")

	inventory.remove_weapon(third)
	check_equal(inventory.equipped(), second, "retirer une arme rangée ne change pas la main")

	inventory.remove_weapon(second)
	check(inventory.equipped() == null, "plus d'armes : mains nues, un état légitime")
	inventory.free()


func test_arrows_are_counted_and_never_negative() -> void:
	## §11.3 : flèches à part des armes ; le compteur ne devient jamais négatif.
	var inventory: InventoryComponent = InventoryComponent.new()
	check_equal(inventory.arrows(), 0, "vide au départ")
	inventory.add_arrows(3)
	check_equal(inventory.arrows(), 3, "ajout compté")
	check(inventory.consume_arrow(), "une flèche part")
	check(inventory.consume_arrow(), "une deuxième part")
	check(inventory.consume_arrow(), "la dernière part")
	check(not inventory.consume_arrow(), "à zéro, le tir est refusé")
	check_equal(inventory.arrows(), 0, "jamais négatif")
	inventory.free()
