## Arme ramassable (MASTER_SPEC §11.4, §14.2) — le flux « il trouve une arme »
## de §1, version graybox : un volume au sol, l'interaction la verse dans
## l'inventaire (C.4) et l'objet disparaît. Un inventaire PLEIN refuse : l'arme
## reste au sol, rien n'est perdu (§11.3 : huit armes, pas une de plus).
##
## L'exemplaire est créé AU RAMASSAGE, jamais à l'avance : une arme au sol n'a
## pas de durabilité entamée à la 0.1 — le butin d'occasion viendra avec les
## tables de loot (§11.4).
class_name WeaponPickup
extends Node3D

signal picked_up(weapon: WeaponInstance)

@export var definition: WeaponDefinition
## Identifiant persistant (§19.3, format `zone.category.name.index`). Un pickup
## ramassé est consigné dans la sauvegarde : sans cet ID, il réapparaîtrait à
## chaque « Continuer » et dupliquerait son arme à l'infini (QA-D1R-01).
@export var pickup_id: StringName = &""


func _ready() -> void:
	add_to_group("interactable")
	if definition == null:
		push_warning("[pickup] arme au sol sans définition — inerte.")
		return
	# ART-P0 : si la définition porte un modèle de PRODUCTION, il remplace la
	# boîte graybox — posé à plat sur le sol, lame vers l'avant. Sans modèle :
	# repli contrôlé sur la boîte (normal tant que la bibliothèque est
	# incomplète).
	if definition.mesh_scene != null:
		var model: Node3D = definition.mesh_scene.instantiate() as Node3D
		if model == null:
			push_error("[pickup] mesh_scene de %s n'est pas un Node3D — repli boîte."
				% String(definition.id))
			return
		var box: Node = get_node_or_null("Mesh")
		if box != null:
			(box as MeshInstance3D).visible = false
		model.name = "ProductionModel"
		add_child(model)
		_pose(model)


## POSE au sol. Une épée d'un mètre couchée à plat se lit ; une lance de deux
## mètres, une hache de 1,43 m ou un arc de 1,52 m couchés dans l'axe du regard
## ne sont plus qu'un trait — les captures des récompenses l'ont montré, l'une
## d'elles ne montrait plus rien du tout.
##
## Les armes longues sont donc FICHÉES en terre, inclinées : la silhouette se
## lit de n'importe quelle direction, et c'est déjà le langage du monde (les
## armes brisées plantées du territoire du chasseur).
##
## La hauteur n'est jamais devinée : elle se déduit de la boîte englobante
## APRÈS rotation, pour que le point bas touche exactement le sol.
func _pose(model: Node3D) -> void:
	var extent: AABB = _model_bounds(model)
	var length: float = maxf(extent.size.z, extent.size.x)
	if length > 1.05:
		# Plantée : inclinée vers l'arrière, un quart de tour de biais pour ne
		# jamais présenter la tranche à celui qui arrive.
		model.rotation_degrees = Vector3(-62.0, 34.0, 0.0)
	else:
		model.rotation_degrees = Vector3(0.0, 25.0, 0.0)
	var posed: AABB = _model_bounds(model)
	model.position = Vector3(0.0, -posed.position.y, 0.0)


## Boîte englobante du modèle dans le repère du pickup, rotation comprise.
func _model_bounds(model: Node3D) -> AABB:
	var box: AABB = AABB()
	var first: bool = true
	# Les maillages sont ramenés dans le repère du MODÈLE, puis la transformée
	# du modèle est appliquée : passer par le global mêlerait la position du
	# pickup dans le monde, et la pose dépendrait de l'endroit où il est posé.
	var into_model: Transform3D = model.global_transform.affine_inverse()
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		var here: AABB = model.transform \
			* ((into_model * mesh.global_transform) * mesh.get_aabb())
		if first:
			box = here
			first = false
		else:
			box = box.merge(here)
	return box


func prompt_verb() -> String:
	return "Ramasser"


## Contrat des interactables : `false` = refusé, l'objet reste.
func interact(player: PlayerController) -> bool:
	if definition == null or player == null or player.inventory() == null:
		return false
	var bus: Node = get_node_or_null("/root/EventBus")
	var weapon: WeaponInstance = WeaponInstance.create(definition)
	if not player.inventory().add_weapon(weapon):
		if bus != null:
			bus.call("notify", "Inventaire plein (8 armes) — l'arme reste au sol")
		return false  # inventaire plein : l'arme reste au sol
	if bus != null:
		bus.call("notify", "Ramassé : " + definition.display_name)
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.call("play_sfx", &"pickup")
	picked_up.emit(weapon)
	queue_free()
	return true


## Application d'état (§19.4) : un pickup déjà ramassé disparaît sans signal ni
## notification — appliquer une sauvegarde n'est pas du gameplay. Rendu inerte
## immédiatement : `queue_free` ne prend effet qu'à la fin de la frame.
func mark_taken_silently() -> void:
	remove_from_group("interactable")
	definition = null
	visible = false
	queue_free()
