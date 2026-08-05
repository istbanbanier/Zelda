## Événements sonores de gameplay (MASTER_SPEC §12.7) — « sprint, impact,
## rupture, flèche et explosion produisent des bruits distincts ».
##
## Pas un bus audio : un fait de PERCEPTION. L'émetteur annonce position,
## rayon et nature ; chaque ennemi vivant du groupe `enemies` juge avec SA
## propre audition (`tuning.hearing_range`) — le rayon effectif est le
## minimum des deux. Aucun état global, aucune allocation par frame :
## l'appel n'a lieu qu'aux événements réels.
class_name NoiseEvents
extends RefCounted

## Rayons de départ (§12.7) — ajustés au level design, jamais en scène.
const SPRINT_RADIUS: float = 12.0
const IMPACT_RADIUS: float = 10.0
const BREAK_RADIUS: float = 14.0
const ARROW_RADIUS: float = 8.0


static func emit(tree: SceneTree, position: Vector3, radius: float,
		kind: StringName) -> void:
	for node: Node in tree.get_nodes_in_group("enemies"):
		if node.has_method("hear_noise"):
			node.call("hear_noise", position, radius, kind)
	# P2-4e (Écho) : les écouteurs déclarés entendent aussi — même fait de
	# perception, un groupe de plus, aucun état global.
	for node: Node in tree.get_nodes_in_group("noise_listeners"):
		if node.has_method("hear_noise"):
			node.call("hear_noise", position, radius, kind)
