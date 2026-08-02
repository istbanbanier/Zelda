## Règles de cuisine (MASTER_SPEC §13.4) — logique PURE, sans nœud ni UI :
## la même fonction sert l'aperçu, la confirmation et les tests unitaires
## exigés par §21.2 (« recettes compatibles/incompatibles »).
##
## Règles, au chiffre près :
## - soin = somme des soins, clampé à MAX_HEAL ;
## - effet dominant = LA famille d'effet majeur présente ; DEUX familles
##   majeures différentes → « ragoût instable » (soin réduit, aucun effet) ;
## - durée = 60 s + 30 s par ingrédient COMPATIBLE (porteur de la famille),
##   +45 s par épice (D-027 : l'épice « augmente la durée sans changer la
##   famille », valeur de départ choisie et consignée), maximum 300 s ;
## - 1 à 5 ingrédients, sinon résultat vide.
class_name RecipeRules
extends RefCounted

const MAX_HEAL: float = 100.0
const BASE_DURATION: float = 60.0
const DURATION_PER_COMPATIBLE: float = 30.0
const DURATION_PER_SPICE: float = 45.0
const MAX_DURATION: float = 300.0
const UNSTABLE_HEAL_FACTOR: float = 0.3

const EFFECT_NAMES: Dictionary = {
	&"attack": "Ragoût du guerrier",
	&"defense": "Potée du rempart",
	&"stamina": "Sauté du grimpeur",
	&"elec_resist": "Confit paratonnerre",
}


## Résultat : { valid, name, heal, effect, potency, duration, unstable }.
## Dictionnaire de PRIMITIVES : il se sauvegarde tel quel (§19.2).
static func cook(ingredients: Array[IngredientDefinition]) -> Dictionary:
	if ingredients.is_empty() or ingredients.size() > 5:
		return {"valid": false}
	var heal: float = 0.0
	var families: Dictionary = {}
	var spices: int = 0
	for ingredient: IngredientDefinition in ingredients:
		if ingredient == null:
			return {"valid": false}
		heal += ingredient.heal_amount
		if ingredient.is_spice:
			spices += 1
		elif ingredient.effect_tag != &"":
			families[ingredient.effect_tag] = \
				float(families.get(ingredient.effect_tag, 0.0)) + ingredient.potency
	heal = minf(heal, MAX_HEAL)

	# Deux familles MAJEURES différentes : instable (§13.4) — soin réduit,
	# aucun effet, jamais une punition cachée.
	if families.size() >= 2:
		return {"valid": true, "name": "Ragoût instable",
			"heal": heal * UNSTABLE_HEAL_FACTOR, "effect": &"",
			"potency": 0.0, "duration": 0.0, "unstable": true}

	if families.is_empty():
		return {"valid": true, "name": "Plat simple", "heal": heal,
			"effect": &"", "potency": 0.0, "duration": 0.0, "unstable": false}

	var effect: StringName = (families.keys()[0]) as StringName
	var compatible: int = 0
	for ingredient: IngredientDefinition in ingredients:
		if ingredient.effect_tag == effect:
			compatible += 1
	var duration: float = minf(BASE_DURATION
		+ DURATION_PER_COMPATIBLE * float(compatible)
		+ DURATION_PER_SPICE * float(spices), MAX_DURATION)
	return {"valid": true,
		"name": String(EFFECT_NAMES.get(effect, "Plat mijoté")),
		"heal": heal, "effect": effect,
		"potency": float(families[effect]), "duration": duration,
		"unstable": false}
