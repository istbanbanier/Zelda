## Inventaire d'armes et de flèches (MASTER_SPEC §5.8, §11.3).
##
## §11.3 : huit armes maximum, flèches à part, « aucun doublon d'instance ».
## L'équipement fait partie de l'inventaire : c'est lui qui sait quelle arme est
## en main et qui « équipe la suivante » après une rupture (§11.2) — le porteur
## écoute `weapon_equipped` et raccorde dégâts et portée, il ne choisit pas.
##
## `null` équipé = mains nues : un état légitime (§11.2), pas une erreur.
## Les ingrédients et les plats (§11.3) arrivent avec la cuisine (Phase E).
class_name InventoryComponent
extends Node

## `weapon` vaut `null` pour les mains nues.
signal weapon_equipped(weapon: WeaponInstance)
signal weapon_added(weapon: WeaponInstance)
signal weapon_removed(weapon: WeaponInstance)
signal arrows_changed(count: int)
signal ingredients_changed(id: StringName, count: int)
signal meals_changed(count: int)

## §11.3 : « huit armes ».
const MAX_WEAPONS: int = 8

## Arme de départ, instanciée à l'initialisation — le flux « trouve un coffre et
## une arme » (§1) la remplacera par du butin réel en Phase D.
@export var default_weapon: WeaponDefinition
## Dotation de départ du bac à sable ; les flèches se gagnent en coffre (§11.4).
@export var starting_arrows: int = 0

var _weapons: Array[WeaponInstance] = []
var _equipped_index: int = -1
var _arrows: int = 0
## §11.3/§13 : ingrédients EMPILABLES, à part des armes — id → compte.
var _ingredients: Dictionary = {}
## E.2a — plats cuisinés (§13.4) : FIFO de dictionnaires de PRIMITIVES
## (résultat de RecipeRules.cook) — sérialisables tels quels (§19.2).
## §11.3 : « plats séparés » des ingrédients et des armes.
const MAX_MEALS: int = 6
var _meals: Array[Dictionary] = []


func _ready() -> void:
	_arrows = maxi(0, starting_arrows)
	if default_weapon != null:
		add_weapon(WeaponInstance.create(default_weapon))


## Refuse le plein (§11.3 : huit) et le doublon d'instance. La première arme
## ajoutée à mains nues est équipée d'office (§1 : trouver une arme, c'est la
## prendre en main).
func add_weapon(weapon: WeaponInstance) -> bool:
	if weapon == null or _weapons.size() >= MAX_WEAPONS:
		return false
	for held: WeaponInstance in _weapons:
		if held.instance_id == weapon.instance_id:
			return false  # §11.3 : aucun doublon d'instance
	_weapons.append(weapon)
	weapon_added.emit(weapon)
	if _equipped_index < 0:
		equip_index(_weapons.size() - 1)
	return true


## Retire l'exemplaire (rupture §11.2, ou dépôt plus tard). Si c'était l'arme en
## main : « équiper suivante ou mains nues ».
func remove_weapon(weapon: WeaponInstance) -> bool:
	var index: int = _weapons.find(weapon)
	if index < 0:
		return false
	var was_equipped: bool = index == _equipped_index
	_weapons.remove_at(index)
	if _equipped_index > index:
		_equipped_index -= 1
	weapon_removed.emit(weapon)
	if was_equipped:
		if _weapons.is_empty():
			_equipped_index = -1
			weapon_equipped.emit(null)
		else:
			# La « suivante » : l'arme qui occupe maintenant la place de la
			# disparue, ou la dernière si elle fermait la liste.
			_equipped_index = -1
			equip_index(mini(index, _weapons.size() - 1))
	return true


func equip_index(index: int) -> bool:
	if index < 0 or index >= _weapons.size() or index == _equipped_index:
		return false
	_equipped_index = index
	weapon_equipped.emit(_weapons[index])
	return true


## Sélection rapide (§11.3) — cycle vers l'arme suivante, en boucle.
func equip_next() -> void:
	if _weapons.size() < 2:
		return
	equip_index((_equipped_index + 1) % _weapons.size())


func equip_previous() -> void:
	if _weapons.size() < 2:
		return
	equip_index((_equipped_index - 1 + _weapons.size()) % _weapons.size())


## Réordonne (PT-D1-03 : « possibilité de changer l'ordre des armes »). L'arme
## ÉQUIPÉE reste équipée : c'est l'exemplaire qui compte, pas sa case.
func move_weapon(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= _weapons.size() \
			or to_index < 0 or to_index >= _weapons.size() or from_index == to_index:
		return false
	var equipped_instance: WeaponInstance = equipped()
	var moved: WeaponInstance = _weapons[from_index]
	_weapons.remove_at(from_index)
	_weapons.insert(to_index, moved)
	if equipped_instance != null:
		_equipped_index = _weapons.find(equipped_instance)
	return true


func equipped() -> WeaponInstance:
	if _equipped_index < 0 or _equipped_index >= _weapons.size():
		return null
	return _weapons[_equipped_index]


func weapon_count() -> int:
	return _weapons.size()


func equipped_index() -> int:
	return _equipped_index


## Restauration de sauvegarde (§19.4) : repart d'un inventaire vide, sans
## émettre un signal par retrait — l'application d'état n'est pas du gameplay.
func clear_weapons() -> void:
	_weapons.clear()
	_equipped_index = -1


## Restauration : pose la valeur exacte, borne à zéro.
func set_arrows(count: int) -> void:
	_arrows = maxi(0, count)
	arrows_changed.emit(_arrows)


func weapons() -> Array[WeaponInstance]:
	return _weapons.duplicate()


## ---------------------------------------------------------------------------
## Flèches (§11.3 : à part des armes)
## ---------------------------------------------------------------------------

func arrows() -> int:
	return _arrows


func has_arrows() -> bool:
	return _arrows > 0


func add_arrows(count: int) -> void:
	if count <= 0:
		return
	_arrows += count
	arrows_changed.emit(_arrows)


## `false` à zéro : le tir n'a pas lieu — jamais de compteur négatif.
func consume_arrow() -> bool:
	if _arrows <= 0:
		return false
	_arrows -= 1
	arrows_changed.emit(_arrows)
	return true


## ---------------------------------------------------------------------------
## Ingrédients (§13.1, §13.2) — empilables, ajout ATOMIQUE
## ---------------------------------------------------------------------------

## Refuse au-delà du stack maximum de la DÉFINITION (§13.1) : l'appelant garde
## alors l'objet au sol — rien n'est jamais perdu (§13.2).
func add_ingredient(definition: IngredientDefinition, amount: int = 1) -> bool:
	if definition == null or amount <= 0:
		return false
	var current: int = int(_ingredients.get(definition.id, 0))
	if current + amount > definition.max_stack:
		return false
	_ingredients[definition.id] = current + amount
	ingredients_changed.emit(definition.id, current + amount)
	return true


func ingredient_count(id: StringName) -> int:
	return int(_ingredients.get(id, 0))


## Consommation (cuisine §13.3) : tout ou rien — jamais de compte négatif.
func consume_ingredients(id: StringName, amount: int) -> bool:
	var current: int = int(_ingredients.get(id, 0))
	if amount <= 0 or current < amount:
		return false
	if current == amount:
		_ingredients.erase(id)
	else:
		_ingredients[id] = current - amount
	ingredients_changed.emit(id, ingredient_count(id))
	return true


func ingredient_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: Variant in _ingredients.keys():
		ids.append(id as StringName)
	return ids


## Instantané pour la sauvegarde (clés String, §19.2 : primitives seulement).
func ingredients_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for id: Variant in _ingredients.keys():
		snapshot[String(id as StringName)] = int(_ingredients[id])
	return snapshot


## Restauration (§19.4) : pose l'état exact, silencieusement — l'application
## d'une sauvegarde n'est pas du gameplay.
func set_ingredients(snapshot: Dictionary) -> void:
	_ingredients.clear()
	for key: Variant in snapshot.keys():
		var count: int = int(snapshot[key])
		if count > 0:
			_ingredients[StringName(String(key))] = count


## ---------------------------------------------------------------------------
## Plats cuisinés (E.2a, §13.4) — FIFO bornée, primitives seulement
## ---------------------------------------------------------------------------

func add_meal(meal: Dictionary) -> bool:
	if not bool(meal.get("valid", false)) or _meals.size() >= MAX_MEALS:
		return false
	_meals.append(meal.duplicate())
	meals_changed.emit(_meals.size())
	return true


## Prélève le PREMIER plat (le plus ancien) — vide si aucun. Le plat quitte
## la réserve au moment du prélèvement : jamais consommé deux fois.
func take_first_meal() -> Dictionary:
	if _meals.is_empty():
		return {}
	var meal: Dictionary = _meals.pop_front()
	meals_changed.emit(_meals.size())
	return meal


func meal_count() -> int:
	return _meals.size()


func meals_snapshot() -> Array:
	var snapshot: Array = []
	for meal: Dictionary in _meals:
		snapshot.append(meal.duplicate())
	return snapshot


func set_meals(snapshot: Array) -> void:
	_meals.clear()
	for entry: Variant in snapshot:
		if entry is Dictionary and bool((entry as Dictionary).get("valid", false)):
			_meals.append((entry as Dictionary).duplicate())
