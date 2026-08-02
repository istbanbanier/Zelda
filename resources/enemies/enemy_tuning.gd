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

@export_group("Mémoire et territoire (D-EN.0, §12.7 et §12.9)")
## Temps pendant lequel une cible PERDUE DE VUE reste poursuivie avant de
## devenir une position à investiguer (§12.7 : 3-8 s selon le type).
@export var memory_duration: float = 4.0
## Recherche immobile sur la dernière position connue avant le retour.
@export var search_duration: float = 2.0
## Distance maximale de poursuite depuis l'origine du territoire (§12.9 :
## aucune poursuite infinie).
@export var max_pursuit_distance: float = 45.0
## Vitesse de patrouille/retour/investigation (marche, pas la poursuite).
@export var patrol_speed: float = 3.0
## §12.2 : rayon d'alerte des alliés à l'acquisition (0 = n'alerte pas).
@export var alert_radius: float = 0.0
## §12.1 : durée de la fuite (familles qui fuient — le braise : 2-4 s).
@export var flee_duration: float = 3.0
## §12.9 (D-EN.6) : cette famille emprunte le navmesh des GRANDES
## CARRURES — le colosse (rayon 1,1 m) et le chasseur (0,85 m) ne
## peuvent pas passer là où un pillard (0,38 m) passe.
@export var uses_large_navmesh: bool = false
