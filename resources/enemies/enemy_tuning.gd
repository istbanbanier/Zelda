## Réglages d'un type d'ennemi (MASTER_SPEC §12.1, §12.6).
##
## §5.4 : l'équilibrage vit en `Resource`, jamais dans un script ou une scène de
## niveau. La `EnemyDefinition` complète de §5.9 (mesh, loot, sons) arrivera avec
## les familles suivantes ; ce réglage couvre ce que le pillard braise consomme
## réellement en C.2.
class_name EnemyTuning
extends Resource

@export var id: StringName

@export_group("Vitalité (§12.1)")
@export var max_health: float = 45.0
## Jauge de poise : les dégâts de poise encaissés au-delà déclenchent un stagger.
@export var poise: float = 20.0
@export var stagger_duration: float = 0.8

@export_group("Perception (§12.6)")
@export var vision_range: float = 22.0
@export var vision_half_angle_deg: float = 47.5
## §12.6 donne aussi une audition (15 m) : elle réagit à des ÉVÉNEMENTS sonores
## (§12.7), qui n'existent pas encore — champ déclaré, non consommé.
@export var hearing_range: float = 15.0

@export_group("Déplacement et attaque")
## §12.6 : vitesse de poursuite du pillard braise.
@export var pursuit_speed: float = 5.2
@export var turn_speed: float = 8.0
## §11.1 : portée du gourdin bois.
@export var attack_reach: float = 1.6
## Pause entre deux attaques, pour laisser respirer (§10.5).
@export var attack_cooldown: float = 1.2

@export_group("Repli (§12.1 : « recule après une esquive réussie »)")
@export var retreat_speed: float = 3.5
@export var retreat_duration: float = 1.2
