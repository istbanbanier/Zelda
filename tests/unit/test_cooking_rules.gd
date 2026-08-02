## E.2 (fondations) — règles de cuisine (§13.4) et effets d'état (§13.5) :
## logique PURE, sans scène ni UI. §21.2 exige les tests « recettes
## compatibles/incompatibles » et « application/remplacement des buffs » —
## les voici, au chiffre près, AVANT le câblage joueur/feu de camp.
extends GateTestCase


func _ingredient(heal: float, tag: StringName = &"", potency: float = 0.0,
		spice: bool = false) -> IngredientDefinition:
	var definition: IngredientDefinition = IngredientDefinition.new()
	definition.heal_amount = heal
	definition.effect_tag = tag
	definition.potency = potency
	definition.is_spice = spice
	return definition


func test_cook_rejects_empty_oversized_and_null_selections() -> void:
	## §13.3 : 1 à 5 ingrédients — hors bornes, résultat invalide, jamais
	## un plat fantôme.
	var none: Array[IngredientDefinition] = []
	check(not bool(RecipeRules.cook(none).get("valid", true)), "0 ingrédient : invalide")
	var six: Array[IngredientDefinition] = []
	for i: int in range(6):
		six.append(_ingredient(5.0))
	check(not bool(RecipeRules.cook(six).get("valid", true)), "6 ingrédients : invalide")
	var with_hole: Array[IngredientDefinition] = [_ingredient(5.0), null]
	check(not bool(RecipeRules.cook(with_hole).get("valid", true)),
		"une définition nulle invalide le plat, pas de crash")


func test_heal_is_summed_and_clamped() -> void:
	## §13.4 : « soin = somme des valeurs de soin, avec clamp ».
	var simple: Array[IngredientDefinition] = [_ingredient(30.0), _ingredient(40.0)]
	var result: Dictionary = RecipeRules.cook(simple)
	check(bool(result.get("valid", false)), "deux soins purs : plat valide")
	check_equal(float(result.get("heal", 0.0)), 70.0, "soin sommé 30+40")
	check_equal(String(result.get("effect", "?")), "", "aucune famille : pas d'effet")
	check_equal(float(result.get("duration", -1.0)), 0.0, "…et durée nulle")
	var rich: Array[IngredientDefinition] = [_ingredient(60.0), _ingredient(60.0)]
	check_equal(float(RecipeRules.cook(rich).get("heal", 0.0)), RecipeRules.MAX_HEAL,
		"120 de soin clampé à %s" % RecipeRules.MAX_HEAL)


func test_a_compatible_recipe_carries_family_potency_and_duration() -> void:
	## §13.4 : effet dominant par tags compatibles, puissance CUMULÉE,
	## durée = 60 s + 30 s par ingrédient compatible.
	var meal: Array[IngredientDefinition] = [
		_ingredient(10.0, &"attack", 2.0),
		_ingredient(5.0, &"attack", 1.5),
		_ingredient(15.0),
	]
	var result: Dictionary = RecipeRules.cook(meal)
	check(bool(result.get("valid", false)), "recette compatible : valide")
	check_equal(String(result.get("effect", "")), "attack", "famille dominante attack")
	check_equal(float(result.get("potency", 0.0)), 3.5, "puissance cumulée 2.0+1.5")
	check_equal(float(result.get("duration", 0.0)), 120.0,
		"durée 60 + 30×2 compatibles = 120 s")
	check_equal(String(result.get("name", "")), "Ragoût du guerrier",
		"le plat porte son nom de famille")
	check(not bool(result.get("unstable", true)), "…et il est stable")


func test_spice_extends_duration_without_changing_the_family() -> void:
	## §13.4 + D-027 : l'épice ajoute 45 s SANS changer la famille ; seule,
	## elle ne crée aucune famille.
	var spiced: Array[IngredientDefinition] = [
		_ingredient(10.0, &"stamina", 1.0),
		_ingredient(2.0, &"", 0.0, true),
	]
	var result: Dictionary = RecipeRules.cook(spiced)
	check_equal(String(result.get("effect", "")), "stamina",
		"l'épice ne change pas la famille")
	check_equal(float(result.get("duration", 0.0)), 135.0, "durée 60 + 30 + 45 = 135 s")
	var maxed: Array[IngredientDefinition] = [_ingredient(10.0, &"attack", 1.0)]
	for i: int in range(4):
		maxed.append(_ingredient(2.0, &"", 0.0, true))
	check_equal(float(RecipeRules.cook(maxed).get("duration", 0.0)), 270.0,
		"cas extrême réel : 60 + 30 + 4×45 = 270 s (sous le plafond 300)")
	var alone: Array[IngredientDefinition] = [_ingredient(2.0, &"", 0.0, true)]
	check_equal(String(RecipeRules.cook(alone).get("name", "")), "Plat simple",
		"épice seule : plat simple, aucune famille inventée")


func test_two_major_families_make_an_unstable_stew() -> void:
	## §13.4 : « effets majeurs incompatibles → ragoût instable à faible
	## soin » — soin réduit, AUCUN effet, jamais une punition cachée.
	var clash: Array[IngredientDefinition] = [
		_ingredient(20.0, &"attack", 2.0),
		_ingredient(20.0, &"defense", 2.0),
	]
	var result: Dictionary = RecipeRules.cook(clash)
	check(bool(result.get("valid", false)), "le ragoût instable reste un plat valide")
	check(bool(result.get("unstable", false)), "…marqué instable")
	check_equal(String(result.get("name", "")), "Ragoût instable", "nom honnête")
	check_equal(float(result.get("heal", 0.0)), 40.0 * RecipeRules.UNSTABLE_HEAL_FACTOR,
		"soin réduit au facteur %s" % RecipeRules.UNSTABLE_HEAL_FACTOR)
	check_equal(String(result.get("effect", "?")), "", "aucun effet majeur")
	check_equal(float(result.get("duration", -1.0)), 0.0, "aucune durée")


func test_buff_applies_replaces_and_expires() -> void:
	## §13.4 : UN SEUL buff majeur — le nouveau REMPLACE l'ancien ; §13.5 :
	## les multiplicateurs de départ. L'expiration est mesurée en pilotant
	## `_process` à la main : déterministe, sans attente réelle.
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var status: StatusEffectComponent = StatusEffectComponent.new()
	tree.root.add_child(status)
	var applied: Array[StringName] = []
	var expired: Array[StringName] = []
	status.buff_applied.connect(func(effect: StringName, _p: float, _d: float) -> void:
		applied.append(effect))
	status.buff_expired.connect(func(effect: StringName) -> void:
		expired.append(effect))

	check(not status.is_processing(), "dormant : pas de _process (§5.4)")
	check_equal(status.attack_multiplier(), 1.0, "sans buff : ×1.0 partout")
	status.apply_buff(&"attack", 2.0, 10.0)
	check_equal(status.attack_multiplier(), StatusEffectComponent.ATTACK_MULTIPLIER,
		"buff attack : dégâts ×%s" % StatusEffectComponent.ATTACK_MULTIPLIER)
	check_equal(status.damage_taken_multiplier(), 1.0,
		"…sans toucher la défense")
	status.apply_buff(&"defense", 1.0, 8.0)
	check_equal(expired.size(), 1, "le remplacement a EXPIRÉ l'ancien buff")
	check_equal(String(expired[0]), "attack", "…celui d'attaque")
	check_equal(status.damage_taken_multiplier(),
		StatusEffectComponent.DAMAGE_TAKEN_MULTIPLIER,
		"le nouveau buff est actif : dégâts reçus ×%s"
		% StatusEffectComponent.DAMAGE_TAKEN_MULTIPLIER)
	check_equal(status.attack_multiplier(), 1.0, "l'ancien multiplicateur est retombé")

	status._process(7.9)
	check_equal(String(status.active_effect()), "defense", "à 7,9 s : encore actif")
	status._process(0.2)
	check_equal(String(status.active_effect()), "", "à 8,1 s : expiré")
	check_equal(expired.size(), 2, "signal d'expiration émis")
	check_equal(status.damage_taken_multiplier(), 1.0, "multiplicateur retombé")
	check(not status.is_processing(), "…et le composant se rendort")
	check_equal(applied.size(), 2, "deux applications au total, pas plus")
	tree.root.remove_child(status)
	status.free()


func test_buff_snapshot_and_restore() -> void:
	## §19.1 « buff restant » + §19.4 : le snapshot est un dictionnaire de
	## primitives, la restauration repasse par le chemin normal (signaux).
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var source: StatusEffectComponent = StatusEffectComponent.new()
	tree.root.add_child(source)
	check(source.snapshot().is_empty(), "sans buff : snapshot vide")
	source.apply_buff(&"elec_resist", 3.0, 42.0)
	var data: Dictionary = source.snapshot()
	check_equal(String(data.get("effect", "")), "elec_resist", "effet sérialisé")
	check_equal(float(data.get("remaining", 0.0)), 42.0, "temps restant sérialisé")
	for value: Variant in data.values():
		check(typeof(value) in [TYPE_STRING, TYPE_FLOAT, TYPE_INT],
			"primitive seulement (§19.2) : %s" % type_string(typeof(value)))

	var restored: StatusEffectComponent = StatusEffectComponent.new()
	tree.root.add_child(restored)
	var signaled: Array[StringName] = []
	restored.buff_applied.connect(func(effect: StringName, _p: float, _d: float) -> void:
		signaled.append(effect))
	restored.restore(data)
	check_equal(String(restored.active_effect()), "elec_resist", "buff restauré")
	check_equal(restored.elec_damage_multiplier(),
		StatusEffectComponent.ELEC_DAMAGE_MULTIPLIER,
		"multiplicateur électrique actif ×%s"
		% StatusEffectComponent.ELEC_DAMAGE_MULTIPLIER)
	check_equal(restored.remaining(), 42.0, "temps restant repris")
	check_equal(signaled.size(), 1,
		"la restauration passe par le signal normal — les consommateurs retendent")
	restored.restore({})
	check_equal(String(restored.active_effect()), "elec_resist",
		"restore({}) est neutre, il n'efface rien")
	tree.root.remove_child(source)
	source.free()
	tree.root.remove_child(restored)
	restored.free()
