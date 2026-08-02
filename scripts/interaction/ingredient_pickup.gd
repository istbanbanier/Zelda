## Ingrédient récoltable (MASTER_SPEC §13.2) — geste court, ajout ATOMIQUE :
## l'objet ne disparaît QU'APRÈS le succès de l'ajout, et un verrou interne
## empêche la double collecte causée par plusieurs inputs ou signaux dans la
## même frame (§13.2). Un stack plein refuse : l'ingrédient reste au sol.
##
## Visuel graybox : petite sphère à la couleur de la définition (§13.1 :
## « visuellement distincts ») sur une pastille de tige — construit en code,
## une seule scène sert les sept ingrédients.
class_name IngredientPickup
extends Node3D

signal collected(definition: IngredientDefinition)

@export var definition: IngredientDefinition
## Identifiant persistant (§19.3) — un ingrédient récolté ne réapparaît pas
## au rechargement (politique v0.1 explicite, cf. valley_world).
@export var pickup_id: StringName = &""

var _collected: bool = false


func _ready() -> void:
	add_to_group("interactable")
	if definition == null:
		push_warning("[ingredient] pickup sans définition — inerte.")
		return
	var berry: MeshInstance3D = MeshInstance3D.new()
	berry.name = "Berry"
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.14
	sphere.height = 0.28
	berry.mesh = sphere
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = definition.color
	material.roughness = 0.7
	berry.material_override = material
	berry.position = Vector3(0, 0.22, 0)
	add_child(berry)
	var stem: MeshInstance3D = MeshInstance3D.new()
	stem.name = "Stem"
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.03
	cylinder.height = 0.14
	stem.mesh = cylinder
	var stem_material: StandardMaterial3D = StandardMaterial3D.new()
	stem_material.albedo_color = Color(0.30, 0.42, 0.22)
	stem.material_override = stem_material
	stem.position = Vector3(0, 0.07, 0)
	add_child(stem)


func prompt_verb() -> String:
	return "Récolter"


## Contrat des interactables : `false` = refusé, l'objet reste.
func interact(player: PlayerController) -> bool:
	if _collected or definition == null or player == null \
			or player.inventory() == null:
		return false
	var bus: Node = get_node_or_null("/root/EventBus")
	if not player.inventory().add_ingredient(definition):
		if bus != null:
			bus.call("notify", "%s : réserve pleine (%d)" % [
				definition.display_name, definition.max_stack])
		return false
	_collected = true   # verrou AVANT toute émission — §13.2, double collecte
	if bus != null:
		bus.call("notify", "Récolté : " + definition.display_name)
	collected.emit(definition)
	queue_free()
	return true


## Application d'état (§19.4) : déjà récolté dans la sauvegarde — retiré sans
## signal ni notification.
func mark_taken_silently() -> void:
	_collected = true
	remove_from_group("interactable")
	visible = false
	queue_free()
