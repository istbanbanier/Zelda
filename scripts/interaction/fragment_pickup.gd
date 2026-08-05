## Fragment de Résonance ramassable (P2-4e, bible §5) — un éclat posé au
## POI-école dont il prolonge la leçon : Flux à l'autel de terre, Élan au
## pont magnétique, Écho au bassin conducteur.
##
## Même contrat que WeaponPickup : groupe `interactable`, `interact(player)`,
## identifiant persistant §19.3 (sans lui, « Continuer » le ferait
## réapparaître et l'unicité des Fragments n'aurait plus de sens).
class_name FragmentPickup
extends Node3D

signal picked_up(fragment_id: StringName)

@export var fragment_id: StringName = &""
@export var pickup_id: StringName = &""


func _ready() -> void:
	add_to_group("interactable")
	# Éclat visible : un petit prisme dressé, cœur cyan — la présentation
	# finale arrive avec la passe visuelle, la silhouette suffit ici.
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var prism: PrismMesh = PrismMesh.new()
	prism.size = Vector3(0.28, 0.5, 0.28)
	mesh.mesh = prism
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.93, 0.95)
	material.emission_enabled = true
	material.emission = Color(0.133, 0.851, 0.925)
	material.emission_energy_multiplier = 1.4
	mesh.material_override = material
	mesh.position = Vector3(0.0, 0.6, 0.0)
	add_child(mesh)


func interact(player: Node) -> bool:
	var controller: PlayerController = player as PlayerController
	if controller == null:
		return false
	var resonance: ResonanceController = controller.get_node_or_null(
		"Components/ResonanceController") as ResonanceController
	if resonance == null or not resonance.grant_fragment(fragment_id):
		# Déjà détenu ou identifiant invalide : l'éclat reste, rien n'est
		# consommé — jamais de perte silencieuse.
		return false
	picked_up.emit(fragment_id)
	queue_free()
	return true

## Suppression silencieuse au chargement (même contrat que WeaponPickup) :
## l'éclat déjà ramassé ne réapparaît jamais.
func mark_taken_silently() -> void:
	queue_free()
