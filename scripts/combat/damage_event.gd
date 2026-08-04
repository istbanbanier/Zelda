## Événement de dégâts (MASTER_SPEC §10.3).
##
## §10.3 : « chaque événement transporte instigateur, équipe, type, quantité,
## direction, stagger, point, élément et attack ID ». C'est le **paquet** qui
## traverse le pipeline de §10.1 — la hitbox le construit, la hurtbox le remet à
## la santé, l'UI et l'audio s'y abonneront. Aucune de ces couches ne redemande
## un chiffre à une autre : tout est dans l'événement, calculé une fois.
##
## `amount` est le résultat FINAL de la formule de §10.3, défenseur compris.
## Un événement ne se recalcule pas en chemin — sinon deux couches pourraient
## appliquer deux montants différents pour le même coup.
class_name DamageEvent
extends RefCounted

## Qui frappe. Peut être nul (danger environnemental) ; toujours vérifier
## `is_instance_valid()` avant usage — l'instigateur peut mourir avant que
## l'événement ne soit consommé (règles GDScript, durée de vie).
var instigator: Node = null
## Équipe de l'attaquant (`player`, `enemies`, §5.7). Le refus du tir ami se
## décide à la hitbox, mais l'équipe voyage pour l'IA et les logs.
var team: StringName = &""
## Type de dégâts (`melee`, `arrow`, `electric`, …). Piloté par données en C.1+.
var damage_type: StringName = &""
## Quantité finale, formule de §10.3 déjà appliquée. Jamais négative.
var amount: float = 0.0
## Direction de l'impact, normalisée — pour le recul et les réactions
## directionnelles (§7.12). Nulle si indéterminée.
var direction: Vector3 = Vector3.ZERO
## Dégâts de poise (§10.3 « stagger »). La jauge de poise arrive en C.2.
var poise_damage: float = 0.0
## Impulsion de recul, en m/s à appliquer à la victime.
var knockback: float = 0.0
## Gel d'impact (§10.2, §10.6 : « hit-stop attaquant/cible ») — durée en
## secondes pendant laquelle les DEUX corps se figent au contact. Portée par
## l'événement pour que chaque camp lise LA MÊME valeur, celle de l'attaque.
var hit_stop: float = 0.0
## Point d'impact approximatif, pour les VFX et les décals (§7.13).
var position: Vector3 = Vector3.ZERO
## Élément (`electric`, …). Vide pour un coup neutre.
var element: StringName = &""
## Identifiant unique du swing (§10.1, §10.8). Deux victimes du même swing
## partagent cet ID ; deux swings successifs ne le partagent jamais.
var attack_id: int = 0
