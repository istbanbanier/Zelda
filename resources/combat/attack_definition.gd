## Définition d'attaque (MASTER_SPEC §5.9, §10.6).
##
## §10.6 : « chaque action est une ressource de données inspectable, pas une
## collection de nombres cachés dans l'animation ». Startup, actif, recovery et
## fenêtres vivent ICI — l'animation (Phase H) se calera sur ce contrat, elle ne
## le redéfinira jamais.
##
## Ressource **immuable** (§5.4) : l'état d'exécution (phase courante, temps
## écoulé, cibles touchées) vit dans `AttackControllerComponent` et dans la
## hitbox, jamais ici. Deux attaquants partageant cette définition ne partagent
## rien d'autre.
class_name AttackDefinition
extends Resource

@export var id: StringName

@export_group("Dégâts (§10.3)")
## Terme « attack » de la formule : multiplie la base de l'arme.
@export var damage_multiplier: float = 1.0
@export var poise_damage: float = 10.0
## Impulsion de recul transmise à la victime, en m/s.
@export var knockback: float = 2.0
@export var element: StringName = &""

@export_group("Timing (§10.6 : anticipation / actif / recovery)")
## Anticipation : la hitbox n'est PAS active. C'est la lisibilité de §10.5 —
## un coup sans startup serait illisible pour l'adversaire.
@export var startup: float = 0.12
## Fenêtre active : la hitbox frappe, une fois par cible (§10.1).
@export var active: float = 0.10
## Récupération : la hitbox est éteinte, le personnage est engagé.
@export var recovery: float = 0.30

@export_group("Fenêtres d'entrée (§10.2, §10.6)")
## Durée de mémorisation d'un appui d'attaque (§10.2 : « attaque 0,15 s »).
@export var input_buffer: float = 0.15
## §10.2 : « combo dans les derniers 25–35 % ». LECTURE ASSUMÉE : fraction
## finale de la **recovery** pendant laquelle un appui mémorisé enchaîne le coup
## suivant, en annulant le reste de la récupération. Si cette lecture est fausse,
## c'est ce champ qu'il faut corriger, pas la logique.
@export_range(0.0, 1.0) var combo_window_fraction: float = 0.30

@export_group("Feedback (§10.2, §10.7) — déclaré, consommé en C.2")
## Hit-stop léger 0,035–0,055 s (§10.2). Aucun système de gel de frame n'existe
## encore : la valeur est déclarée pour que le contrat soit complet, `STATUS.md`
## dit ce qui est réellement actif.
@export var hit_stop: float = 0.045


## Durée totale de l'action, hors enchaînement anticipé.
func total_duration() -> float:
	return startup + active + recovery


## Instant (depuis le début de l'attaque) où la fenêtre d'enchaînement s'ouvre.
func combo_open_time() -> float:
	return startup + active + recovery * (1.0 - combo_window_fraction)
