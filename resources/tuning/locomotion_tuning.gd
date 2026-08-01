## Réglages de locomotion (MASTER_SPEC §8.2, §8.3).
##
## §5.4 : « l'équilibrage vit dans des `Resource` sous `resources/tuning/`, jamais
## dans une scène de niveau ». Une valeur codée en dur dans le contrôleur serait
## introuvable au moment de l'ajuster, et invisible en revue.
##
## Ces nombres sont les **points de départ** de §8.2, à tester et ajuster en
## conservant l'intention — pas des constantes sacrées.
class_name LocomotionTuning
extends Resource

@export_group("Vitesses (m/s)")
## Atteinte à faible inclinaison de stick. Le clavier, tout ou rien, ne la produit
## jamais : c'est une nuance que seule la manette apporte.
@export var walk_speed: float = 3.5
@export var run_speed: float = 6.0
@export var sprint_speed: float = 9.0

@export_group("Accélérations (m/s²)")
@export var ground_acceleration: float = 24.0
@export var ground_deceleration: float = 30.0
@export var air_acceleration: float = 8.4
## Part du contrôle directionnel conservée en l'air (§8.2 : 35 %).
@export_range(0.0, 1.0) var air_control: float = 0.35

@export_group("Saut et gravité")
@export var gravity: float = 24.0
## 8,2 m/s sous 24 m/s² donne un apex d'environ 1,40 m.
@export var jump_velocity: float = 8.2
## Saut encore accepté après avoir quitté le sol (§8.2).
@export var coyote_time: float = 0.12
## Saut mémorisé avant d'avoir touché le sol (§8.2).
@export var jump_buffer: float = 0.12

@export_group("Contact au sol")
## §8.2 : pente franchissable d'environ 46°.
@export var max_floor_angle_deg: float = 46.0
## Longueur d'accroche au sol : évite de décoller sur une bosse ou en descente.
@export var floor_snap_length: float = 0.4

@export_group("Franchissement de marche (§8.2)")
## Hauteur de marche franchie sans saut (§8.2 : 0,30–0,38 m).
##
## `move_and_slide()` ne monte **aucune** marche par lui-même — mesuré : une marche
## de 0,32 m arrête net le personnage, `is_on_wall()` vrai, sans progression. Le
## franchissement est donc un shape cast explicite, pas un effet de bord du moteur.
@export var step_height: float = 0.34
## Distance sondée devant le personnage, une fois surélevé, pour trouver le dessus
## de la marche. Doit dépasser le rayon de la capsule, sinon la sonde retombe sur
## la face verticale que l'on cherche justement à franchir.
@export var step_forward_probe: float = 0.40

@export_group("Rotation du personnage")
## Le corps ne tourne pas ; seule la représentation visuelle s'oriente. Vitesse de
## rotation en tours par seconde, pour rester indépendante du framerate.
@export var visual_turn_speed: float = 12.0

@export_group("Caméra (§8.3)")
@export var camera_distance: float = 4.3
## Hauteur du point visé, mesurée depuis les pieds.
@export var camera_target_height: float = 1.45
## Décalage d'épaule : sort la caméra de l'axe pour dégager la vue.
@export var camera_shoulder_offset: float = 0.32
@export var camera_fov: float = 70.0
@export var camera_fov_sprint: float = 76.0
## Vitesse d'interpolation du FOV, en unités par seconde : §8.3 interdit tout snap.
@export var camera_fov_speed: float = 4.0
@export var camera_pitch_min_deg: float = -65.0
@export var camera_pitch_max_deg: float = 45.0
## Rayon de la sonde du bras de caméra. §8.3 exige « zéro traversée » : un rayon
## simple arrête la caméra **sur** la surface — mesuré à 0,8 mm du mur dans le bac
## à sable — et le plan proche finit par la traverser au moindre mouvement. Une
## sonde volumique conserve un dégagement réel, égal à ce rayon. `SpringArm3D.margin`
## ne remplace pas ce réglage : mesuré sans effet sur le moteur installé.
@export var camera_probe_radius: float = 0.35
## Sensibilité du stick droit, en radians par seconde à pleine inclinaison.
@export var camera_stick_speed: float = 3.0


## Vitesse cible pour une inclinaison de stick et un état de sprint donnés.
##
## Le clavier produit toujours 1.0 : il court. La manette peut demander la marche.
## Le contrôleur n'a donc aucune branche par périphérique — la nuance vient de
## l'amplitude, pas du matériel (D-013).
func target_speed(input_magnitude: float, sprinting: bool) -> float:
	if input_magnitude <= 0.0:
		return 0.0
	if sprinting:
		return sprint_speed
	if input_magnitude < 0.6:
		return walk_speed
	return run_speed
