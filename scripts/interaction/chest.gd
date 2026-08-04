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
## ART-Q3 : lecteur d'animation du modèle de production (prop.chest) —
## le coffre Quaternius embarque ses clips Chest_Open/Chest_Opened. Null en
## repli graybox : le couvercle bascule comme avant.
var _model_anim: AnimationPlayer = null

@onready var _lid: Node3D = get_node_or_null("Lid") as Node3D


func _ready() -> void:
	add_to_group("interactable")
	# ART-Q3 : modèle de production. La COLLISION du coffre ne change pas —
	# le modèle est un visuel, comme l'arme du joueur (règle ART-P0).
	var packed: PackedScene = AssetRegistry.resolve(&"prop.chest")
	if packed == null:
		return
	var model: Node3D = packed.instantiate() as Node3D
	add_child(model)
	var players: Array[Node] = model.find_children("*", "AnimationPlayer",
		true, false)
	_model_anim = players[0] as AnimationPlayer if not players.is_empty() else null
	for graybox_name: String in ["BodyMesh", "Lid"]:
		var node: Node3D = get_node_or_null(graybox_name) as Node3D
		if node != null:
			node.visible = false
	# L'état a pu être appliqué AVANT _ready (§19.4, ordre chargement/ready
	# indifférent) : un coffre déjà ouvert monte ouvert.
	if _opened and _model_anim != null \
			and _model_anim.has_animation(&"Chest_Opened"):
		_model_anim.play(&"Chest_Opened")


func is_opened() -> bool:
	return _opened


## Application d'une sauvegarde (§19.4, §11.4 : « jamais de second loot après
## chargement ») : l'état s'applique SANS loot, sans signal, idempotent (§6.4).
func mark_opened_silently() -> void:
	_opened = true
	if _model_anim != null and _model_anim.has_animation(&"Chest_Opened"):
		_model_anim.play(&"Chest_Opened")   # pose ouverte, sans geste
	elif _lid != null:
		_lid.rotation.x = -1.2


## Invite contextuelle (§14.2). Un coffre déjà ouvert n'invite plus.
func prompt_verb() -> String:
	if _opened:
		return ""
	return "Ouvrir"


## Contrat des interactables : `false` = refusé (déjà ouvert, ou loot impossible).
func interact(player: PlayerController) -> bool:
	if _opened or player == null or player.inventory() == null:
		return false
	var inventory: InventoryComponent = player.inventory()
	var bus: Node = get_node_or_null("/root/EventBus")
	if weapon_loot != null:
		if not inventory.add_weapon(WeaponInstance.create(weapon_loot)):
			if bus != null:
				bus.call("notify", "Inventaire plein (8 armes) — le coffre reste fermé")
			return false  # plein : le coffre reste fermé, loot intact
	if arrows_loot > 0:
		inventory.add_arrows(arrows_loot)
	_opened = true
	# L'état se VOIT (§15.4 : chaque activation a une conséquence visible) :
	# le clip d'ouverture du modèle, ou la bascule du couvercle graybox.
	if _model_anim != null and _model_anim.has_animation(&"Chest_Open"):
		_model_anim.play(&"Chest_Open")   # LOOP_NONE : la pose ouverte tient
	elif _lid != null:
		_lid.rotation.x = -1.2
	if bus != null:
		var parts: Array[String] = []
		if weapon_loot != null:
			parts.append(weapon_loot.display_name)
		if arrows_loot > 0:
			parts.append("%d flèches" % arrows_loot)
		bus.call("notify", "Coffre ouvert : " + " + ".join(parts))
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("play_sfx", &"chest_open")
	opened.emit(chest_id)
	return true
