## Paquet d'interaction — ce qu'une attaque, un contact ou un mécanisme
## TRANSMET à une cible (P2 §4.3). Données pures, aucune logique de résolution :
## l'arbitre est `ReactionSystem`.
##
## La chaîne causale (`chain`) transporte les instance_id déjà touchés par
## cette action : c'est l'anti-boucle de §4.3/§4.4 — un cycle métal→eau→métal
## s'arrête net, un même swing ne touche jamais deux fois la même cible.
class_name ElementPacket
extends RefCounted

var kinetic: float = 0.0
var electric: float = 0.0
var heat: float = 0.0
var wetness: float = 0.0
var noise: float = 0.0

## Identifiant d'action unique (attaque ID, décharge ID). Deux paquets de la
## même action partagent cet ID — la cible n'encaisse qu'une fois.
var action_id: StringName = &""
## instance_id de l'instigateur (0 = environnement).
var source_id: int = 0
var team: StringName = &""
var position: Vector3 = Vector3.ZERO
var normal: Vector3 = Vector3.UP
## instance_id déjà visités par la chaîne de propagation de cette action.
var chain: Array[int] = []


func is_empty() -> bool:
	return kinetic <= 0.0 and electric <= 0.0 and heat <= 0.0 \
		and wetness <= 0.0 and noise <= 0.0


## Copie pour propagation : même action, même chaîne (référence partagée
## VOULUE — le set de visite est commun à toute la chaîne), énergie atténuée.
func attenuated(factor: float) -> ElementPacket:
	var copy: ElementPacket = ElementPacket.new()
	copy.kinetic = kinetic * factor
	copy.electric = electric * factor
	copy.heat = heat * factor
	copy.wetness = wetness * factor
	copy.noise = noise * factor
	copy.action_id = action_id
	copy.source_id = source_id
	copy.team = team
	copy.position = position
	copy.normal = normal
	copy.chain = chain
	return copy


static func electric_burst(amount: float, action: StringName, source: int = 0) -> ElementPacket:
	var packet: ElementPacket = ElementPacket.new()
	packet.electric = amount
	packet.action_id = action
	packet.source_id = source
	return packet


static func impact(amount: float, action: StringName, source: int = 0) -> ElementPacket:
	var packet: ElementPacket = ElementPacket.new()
	packet.kinetic = amount
	packet.action_id = action
	packet.source_id = source
	return packet
