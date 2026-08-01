## Définition d'esquive (MASTER_SPEC §10.2, §10.6).
##
## Même doctrine que `AttackDefinition` : les fenêtres sont des données
## inspectables, l'exécution obéit. §10.2 fixe les i-frames (0,22–0,27 s) et le
## buffer (0,12 s) ; le reste — durée, vitesse — est un point de départ à tester.
## Le coût d'endurance ne vit PAS ici : §9.1 le fixe dans `StaminaTuning`
## (`dodge_cost`, 15), déclaré depuis B.2 et enfin consommé.
class_name DodgeDefinition
extends Resource

@export var id: StringName = &"dodge_roll"
## Durée totale de l'esquive : le joueur reprend la main à la fin.
@export var duration: float = 0.42
## Vitesse de déplacement pendant l'esquive (m/s) — soit ~3,5 m parcourus.
@export var speed: float = 8.5
## Fenêtre d'invulnérabilité, en secondes depuis le début de l'esquive.
## §10.2 : la LONGUEUR (fin − début) doit tenir dans 0,22–0,27 s.
@export var iframes_start: float = 0.02
@export var iframes_end: float = 0.27
## §10.2 : « Buffers : esquive 0,12 s ».
@export var input_buffer: float = 0.12


func iframes_length() -> float:
	return iframes_end - iframes_start
