## Tuning de la garde et de la déviation parfaite (P2 §7.4).
## Resource immuable — l'état (garde tenue, Clarity) vit dans le contrôleur.
class_name GuardTuning
extends Resource

## Cône frontal de la garde, en degrés (P2 : 120-145°).
@export var front_angle_deg: float = 135.0
## Fenêtre de déviation parfaite depuis la levée de la garde (P2 : 0,08-0,16 s).
@export var parry_window: float = 0.12
## Part des dégâts qui traverse un blocage réussi (chip damage).
@export var block_damage_factor: float = 0.2
## Coût d'endurance d'un blocage : max(minimum, dégâts × facteur).
@export var block_cost_factor: float = 0.8
@export var block_cost_min: float = 6.0
## Recul résiduel d'un coup bloqué (part du recul original).
@export var block_knockback_factor: float = 0.4
## Durée de la fenêtre Clarity ouverte par une déviation parfaite.
@export var clarity_duration: float = 0.35
## Dégâts de poise infligés à l'attaquant dévié — assez pour briser la
## poise d'un pillard, pas celle d'un colosse (P2 : la déviation est
## « forte posture », pas un stagger universel).
@export var parry_poise_damage: float = 40.0
