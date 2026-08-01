## Réaction de dégât du joueur (MASTER_SPEC §8.1 « Hurt », §10.5).
##
## §10.5 exige une « brève protection anti-stunlock » : après une réaction, une
## fenêtre de grâce pendant laquelle les coups suivants BLESSENT toujours mais ne
## reprennent plus le contrôle — sans elle, deux attaquants en cadence
## verrouilleraient le joueur jusqu'à la mort. La grâce protège le CONTRÔLE,
## jamais les points de vie : une invulnérabilité déguisée serait un autre bug.
class_name HurtTuning
extends Resource

## Durée de la perte de contrôle après un coup encaissé.
@export var reaction_duration: float = 0.25
## Fenêtre anti-stunlock (§10.5), mesurée depuis le DÉBUT de la réaction : les
## coups reçus dedans blessent sans re-déclencher la réaction.
@export var stunlock_grace: float = 0.85
## Décélération du recul pendant la réaction (m/s²).
@export var knockback_decay: float = 14.0
