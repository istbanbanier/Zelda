## Coffre (MASTER_SPEC §11.4, §14.2) — version graybox de D.0 : identifiant
## stable dès aujourd'hui (§19.3, format `zone.category.name.index`), état
## ouvert/fermé, loot garanti versé UNE fois — « jamais de second loot ».
## La persistance à travers sauvegarde/chargement arrive avec `SaveSystem`
## (Phase E) : l'ID est déjà là pour elle.
##
## Si l'arme du loot ne rentre pas (inventaire plein), l'ouverture est REFUSÉE
## entière : le coffre reste fermé, rien n'est perdu ni dupliqué — la règle
## d'atomicité de §13.2 (« l'objet ne disparaît qu'après succès de l'ajout »),
## appliquée au loot.
class_name Chest
extends StaticBody3D

signal opened(chest_id: StringName)

## §19.3 : `valley.chest.camp.01` — un validateur d'unicité arrive avec les
## huit coffres de la vallée.
@export var chest_id: StringName
@export var weapon_loot: WeaponDefinition
@export var arrows_loot: int = 0

var _opened: bool = false

@onready var _lid: Node3D = get_node_or_null("Lid") as Node3D


func _ready() -> void:
	add_to_group("interactable")


func is_opened() -> bool:
	return _opened


## Contrat des interactables : `false` = refusé (déjà ouvert, ou loot impossible).
func interact(player: PlayerController) -> bool:
	if _opened or player == null or player.inventory() == null:
		return false
	var inventory: InventoryComponent = player.inventory()
	if weapon_loot != null:
		if not inventory.add_weapon(WeaponInstance.create(weapon_loot)):
			return false  # plein : le coffre reste fermé, loot intact
	if arrows_loot > 0:
		inventory.add_arrows(arrows_loot)
	_opened = true
	# Graybox : le couvercle bascule — assez pour que l'état se VOIE (§15.4,
	# même principe : chaque activation a une conséquence visible).
	if _lid != null:
		_lid.rotation.x = -1.2
	opened.emit(chest_id)
	return true
