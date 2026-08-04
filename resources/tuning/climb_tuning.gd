## Réglages d'escalade et de mantle (MASTER_SPEC §9.2, §9.3).
##
## §9.2 donne des **fourchettes** : les valeurs ci-dessous sont des points de
## départ à l'intérieur de celles-ci, pas des constantes sacrées.
##
## LECTURE ASSUMÉE DE §9.2 : la spec écrit « accroche 0,55–0,80 m ; distance mur
## 0,38–0,48 m » sans définir les deux termes. Deux distances différentes pour un
## même contact n'ont de sens que si l'une est la **portée** à laquelle on peut
## saisir la paroi, l'autre la distance à laquelle le corps s'y **tient** une fois
## accroché. C'est cette lecture qui est implémentée, et elle est faillible : si
## elle est fausse, ce sont ces deux champs qu'il faut corriger, pas la logique.
class_name ClimbTuning
extends Resource

@export_group("Accroche (§9.2)")
## Portée à laquelle une paroi peut être saisie, mesurée depuis l'axe du corps.
@export var grab_reach_m: float = 0.70
## Distance à laquelle le corps se tient de la paroi une fois accroché.
@export var wall_distance_m: float = 0.42
## Une surface n'est une paroi que si elle est plus raide que le sol praticable
## (§8.2 : ~46°). En deçà, c'est une pente : on la gravit en marchant.
##
## Cette valeur doit rester **inférieure ou égale** à
## `LocomotionTuning.max_floor_angle_deg`. Un seuil plus haut ouvrirait une bande
## d'angles ni marchables ni escaladables, où le joueur glisserait sans pouvoir
## s'accrocher — un piège invisible en lecture, d'où le test qui verrouille la
## relation entre les deux ressources.
@export var min_wall_angle_deg: float = 46.0
## Durée pendant laquelle il faut POUSSER vers une paroi, pieds au sol, avant de
## s'y accrocher (D-017).
##
## D-017 avait nommé le risque en l'adoptant : « une paroi longeant un chemin
## s'accroche sans qu'on l'ait demandé », et fixé d'avance la réponse — « un
## seuil d'intention (durée de poussée), pas une touche dédiée ». Un playtest
## externe indépendant l'a confirmé : courir contre un arbre, une maison ou un
## mur du donjon déclenchait l'escalade, le héros restait suspendu et la caméra
## traversait le tronc ou le toit.
##
## 0,22 s : au-dessus du bruit d'un frôlement en courant, sous le seuil où une
## escalade voulue paraîtrait poussive. Ne s'applique QU'AU SOL — en l'air,
## attendre ferait manquer le rebord qu'on visait, et personne ne saute vers un
## mur par accident.
@export var grab_intent_delay_s: float = 0.22

@export_group("Sondes (§9.2)")
## Hauteurs des trois sondes, mesurées depuis les pieds. §9.2 : « sondes tête /
## torse / pieds ». La sonde de tête qui rate alors que les autres touchent
## signale un rebord — c'est ce qui déclenche la recherche de mantle.
@export var probe_foot_height: float = 0.35
@export var probe_chest_height: float = 1.10
@export var probe_head_height: float = 1.70

@export_group("Déplacement sur paroi (§9.2)")
@export var climb_speed_up: float = 2.0
@export var climb_speed_lateral: float = 1.65
## Durée de lissage de la normale : sans elle, une paroi irrégulière ferait
## tressauter l'orientation du personnage à chaque aspérité.
@export var normal_smoothing: float = 0.12
## Hauteur du saut d'escalade (§9.2 : 0,75–1,0 m).
@export var climb_jump_height: float = 0.9

@export_group("Mantle (§9.3)")
## Distance au-dessus de la tête où l'on cherche le dessus du rebord.
@export var ledge_search_height: float = 2.30
## Profondeur de surface praticable exigée au-delà du rebord : un rebord plus
## étroit que la capsule ne se franchit pas, il fait tomber.
@export var ledge_depth_m: float = 0.55
## Durée du franchissement. §9.3 exige « aucun snap visible » : c'est cette durée,
## et le plafond de correction ci-dessous, qui l'assurent.
@export var mantle_duration: float = 0.45
## Correction maximale tolérée pour un franchissement (§7.12 : « correction
## plafonnée »). Au-delà, l'action est refusée plutôt que de téléporter le joueur.
@export var mantle_max_correction_m: float = 2.60
