## Profil de matériau — les LOIS durables d'une matière (P2 §4.1).
##
## Resource IMMUABLE (règle CLAUDE.md : définitions en Resource, état mutable
## séparé — l'état d'instance vit dans `MaterialStateComponent`). Ne pas
## confondre avec le matériau de RENDU : plusieurs matériaux visuels partagent
## une même loi.
class_name MaterialProfile
extends Resource

## Identifiant stable (`bois`, `metal`, `pierre`, `ceramique`, `eau`,
## `terre_conductrice`, `organique`, `isolant`).
@export var id: StringName = &""

## Conductivité 0-1 — même échelle que `ElectricNode.conductivity` (§14.4),
## pour que la migration P2-5 du donjon soit un branchement, pas une traduction.
@export_range(0.0, 1.0) var conductivity: float = 0.0

## Charge stockable (unités d'énergie logiques). 0 = ne retient rien : le
## courant le traverse ou l'ignore, il ne s'y accumule pas.
@export var charge_capacity: float = 0.0

## Inflammabilité 0-1. 0 = ne brûle jamais (pierre, métal, céramique).
@export_range(0.0, 1.0) var flammability: float = 0.0

## Fragilité 0-1 : 0 = incassable par impact. Le seuil de fracture est
## `fracture_threshold` en unités cinétiques du paquet.
@export_range(0.0, 1.0) var fragility: float = 0.0
@export var fracture_threshold: float = 12.0

## Masse logique (kg indicatifs) — bornera la Polarité (P2 §3.4).
@export var logical_mass: float = 10.0

## L'eau s'y accumule-t-elle ? (le métal ruisselle : mouillé bref ; le bois
## absorbe : mouillé long). Pilote la durée de l'état `Wet`.
@export var absorbs_water: bool = false

## Tags libres (P2 §14.4 : `metal`, `wet`, `wood`, `ceramic`, `insulated`…).
@export var tags: Array[StringName] = []


func has_tag(tag: StringName) -> bool:
	return tag in tags
