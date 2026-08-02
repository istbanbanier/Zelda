## Définition d'ingrédient (MASTER_SPEC §5.9, §13.1) — IMMUABLE, comme toute
## définition du projet : l'état (compte en inventaire) vit ailleurs.
##
## §13.1 : ID, nom, soin, tags d'effet, puissance, rareté, maximum de stack.
## L'icône et l'audio de collecte arrivent avec leurs phases (§17, §18) ; la
## couleur graybox rend chaque ingrédient distinct dès maintenant (§13.1 :
## « visuellement distincts »).
class_name IngredientDefinition
extends Resource

@export var id: StringName
@export var display_name: String = ""
## Soin appliqué immédiatement à la consommation (sommé en cuisine, §13.4).
@export var heal_amount: float = 0.0
## Famille d'effet majeur (§13.5) : `attack`, `defense`, `stamina`,
## `elec_resist` — vide pour un ingrédient de soin pur.
@export var effect_tag: StringName = &""
## Puissance cumulée pour départager l'effet dominant (§13.4).
@export var potency: float = 0.0
## Épice rare (§13.4) : allonge la durée SANS changer la famille d'effet.
@export var is_spice: bool = false
@export var rarity: int = 0
@export var max_stack: int = 10
## Couleur graybox du pickup — la distinction visuelle de §13.1, version 0.1.
@export var color: Color = Color(0.8, 0.8, 0.8)
