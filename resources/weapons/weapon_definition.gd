## Définition d'arme (MASTER_SPEC §5.9, §11.1).
##
## Ressource **immuable** (§5.4) : tout ce qui est vrai de TOUS les exemplaires
## d'une arme vit ici — dégâts, portée, durabilité maximale, conductivité. L'état
## d'un exemplaire précis — sa durabilité restante — vit dans `WeaponInstance`,
## jamais ici : « deux exemplaires d'une arme ne partagent jamais leur
## durabilité » est l'invariant central de CLAUDE.md, et une durabilité écrite
## dans cette ressource serait partagée par construction.
##
## Le nom affiché est une clé (§2 : noms pilotés par données) — la table de
## localisation arrive avec l'UI (§17).
class_name WeaponDefinition
extends Resource

@export var id: StringName
@export var display_name_key: StringName
## Nom affiché graybox (HUD, inventaire). La table de localisation par clé
## arrive avec l'UI complète (§17) — d'ici là, la donnée reste dans la donnée.
@export var display_name: String = ""

@export var weapon_type: StringName

@export_group("Table §11.1")
@export var base_damage: float = 1.0
@export var attack_speed: float = 1.0
## Portée en mètres — la face avant du volume de frappe. 0 pour l'arc (distance).
@export var reach_m: float = 1.5
## En nombre de coups QUI TOUCHENT (§11.2) ; en tirs pour l'arc (§11.1).
@export var max_durability: int = 10
## 0–1, consommée par le graphe électrique (Phase F).
@export_range(0.0, 1.0) var conductivity: float = 0.0
@export var rarity: int = 0

@export_group("Présentation (Phase H) et attaques")
@export var mesh_scene: PackedScene
@export var icon: Texture2D
## Chaîne du combo léger de cette arme. Pour la 0.1, toutes les armes de mêlée
## partagent le set d'épée — les « combos par arme » de §7.12 sont une passe
## d'animation, pas une donnée manquante.
@export var attack_set: Array[AttackDefinition] = []
