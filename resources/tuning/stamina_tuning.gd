## Réglages d'endurance (MASTER_SPEC §9.1).
##
## §5.4 : l'équilibrage vit dans une `Resource`, jamais dans une scène ni en dur
## dans un composant. Séparée de `LocomotionTuning` parce que l'endurance est
## consommée par l'escalade (§9.2), l'esquive et l'attaque lourde (§10.2) autant
## que par le sprint : la rattacher à la locomotion la rendrait introuvable depuis
## le combat.
##
## Les coûts déclarés ici ne sont pas tous câblés — voir le commentaire de chacun.
## Un coût déclaré et non consommé est une **intention documentée**, pas une
## fonctionnalité : `docs/STATUS.md` dit lequel est réellement actif.
class_name StaminaTuning
extends Resource

@export_group("Réserve")
@export var max_stamina: float = 100.0

@export_group("Consommation continue (par seconde)")
## Câblé en B.2.
@export var sprint_drain: float = 12.0
## Déclaré pour B.3 (§9.2) — l'escalade n'existe pas encore.
@export var climb_drain: float = 18.0
## Déclaré pour B.3 (§9.2) — déplacement latéral sur paroi.
@export var climb_lateral_drain: float = 16.0

@export_group("Consommation instantanée (par action)")
## Déclaré pour B.3 (§9.2).
@export var climb_jump_cost: float = 20.0
## Déclaré pour la Phase C (§10.2).
@export var dodge_cost: float = 15.0
## Déclaré pour la Phase C (§10.2).
@export var heavy_attack_cost: float = 20.0

@export_group("Régénération")
## Délai d'inactivité avant que la régénération démarre (§9.1).
@export var regen_delay: float = 1.0
## Vitesse de régénération à plein régime, par seconde (§9.1).
@export var regen_rate: float = 22.0
## « Reprise progressive » de §9.1 : la régénération monte à son régime sur cette
## durée au lieu de démarrer d'un coup. Sans elle, la jauge repartirait par un
## à-coup visible juste après un effort.
@export var regen_ramp: float = 0.20

@export_group("Épuisement")
## §9.1 : « 0,45 s avant action consommatrice » une fois la jauge à zéro.
@export var exhaustion_lockout: float = 0.45
## Réserve à retrouver avant qu'un effort **continu** redevienne possible.
##
## §9.1 ne fixe pas cette valeur, et son absence est un défaut mesuré : en levant
## l'épuisement dès la première unité régénérée, un sprint maintenu repartait pour
## un seul tick puis s'épuisait de nouveau — **7 cycles en 15 secondes**, soit un
## bégaiement, pas une reprise. Le seuil impose des rafales utilisables :
## 20 unités à 12/s font environ 1,7 s de sprint (D-016).
@export var exhaustion_recovery_threshold: float = 20.0
