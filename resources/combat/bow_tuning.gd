## Réglages de l'arc (MASTER_SPEC §10.4, §11.1).
##
## §10.4 : vitesse 42–58 m/s, gravité modérée, pooling. §11.1 : arc simple,
## 9 de dégâts. Les flèches comptées (28 tirs de durabilité, inventaire) arrivent
## avec C.4 — d'ici là l'arc tire sans munitions, limite consignée dans STATUS.
class_name BowTuning
extends Resource

## §10.4 : 42–58 m/s.
@export var arrow_speed: float = 48.0
## « Gravité modérée » : moins que la gravité du monde (24), assez pour une chute
## d'arc lisible à distance.
@export var arrow_gravity: float = 12.0
## §11.1 : arc simple, 9.
@export var base_damage: float = 9.0
## Cadence minimale entre deux tirs.
@export var shot_cooldown: float = 0.6
## Taille du pool de flèches (§10.4, §20.6) — jamais d'instanciation en rafale.
@export var pool_size: int = 8
## Durée de vie d'une flèche qui ne touche rien.
@export var lifetime: float = 5.0
