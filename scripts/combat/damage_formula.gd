## Formule de dégâts (MASTER_SPEC §10.3) — fonction pure, testée en unitaire.
##
## §10.3 : « base × weapon × attack × buff × weak_point × resistance − armor,
## clampé ». La formule est UNE fonction, appelée par la hitbox au moment du
## contact — jamais recopiée ailleurs. §21.2 en exige le test unitaire.
##
## Découpage attaquant / défenseur : `base × weapon × attack × buff` ne dépend
## que de l'attaquant — c'est le paramètre `attacker_damage`, calculé par lui.
## `weak_point`, `resistance` et `armor` ne dépendent que de la victime, connus
## seulement au contact. La hitbox n'a donc jamais besoin de connaître l'arme du
## défenseur, ni la hurtbox celle de l'attaquant.
class_name DamageFormula
extends RefCounted


## `attacker_damage` : base × weapon × attack × buff, déjà multipliés côté
## attaquant. `weak_point` ≥ 1 amplifie (dos du colosse), `resistance` ∈ [0 ; 1]
## réduit (buff défensif, résistance élémentaire), `armor` se soustrait en
## dernier. Le résultat n'est jamais négatif : une armure épaisse annule un coup
## faible, elle ne soigne pas.
static func compute(attacker_damage: float, weak_point: float = 1.0,
		resistance: float = 1.0, armor: float = 0.0) -> float:
	return maxf(0.0, attacker_damage * weak_point * resistance - armor)
