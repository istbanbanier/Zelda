## Intention d'entrée — ce que le joueur *veut*, sans dire d'où ça vient.
##
## Raison d'être (D-013) : le gameplay ne doit jamais savoir si l'ordre provient
## d'un clavier, d'une manette ou d'un test. La Phase B se développe au clavier
## alors que la manette n'est pas encore testée (CONTROLLER-001) ; sans cette
## séparation, du code finirait par *supposer* un clavier et la dette deviendrait
## impayable sans réécriture.
##
## C'est un porteur de données pur : aucune lecture de périphérique ici. Il est
## rempli par `PlayerInputReader` en jeu, et directement par les tests en headless
## — ce qui rend la locomotion vérifiable sans simuler la moindre touche.
class_name InputIntent
extends RefCounted

## Direction voulue dans le plan horizontal, **repère caméra** : x = droite,
## y = avant. Norme ≤ 1. Une manette donne une norme continue, un clavier donne
## des paliers ; le gameplay ne doit pas pouvoir faire la différence.
var move: Vector2 = Vector2.ZERO

## États maintenus.
var sprint_held: bool = false
var aim_held: bool = false

## Fronts montants, consommés par le contrôleur dans le tick où ils sont vrais.
var jump_pressed: bool = false
var dodge_pressed: bool = false
var interact_pressed: bool = false
var attack_pressed: bool = false
var heavy_pressed: bool = false
var shoot_pressed: bool = false
var lock_pressed: bool = false
var target_next_pressed: bool = false
var target_prev_pressed: bool = false

## Regard voulu (souris ou stick droit), en unités déjà normalisées par le lecteur.
## Regard au stick : axe sans unité (-1..1), converti en vitesse angulaire par
## la caméra (× vitesse × delta).
var look_analog: Vector2 = Vector2.ZERO
## Regard à la souris : déjà en RADIANS (pixels × sensibilité), appliqué tel
## quel — JAMAIS re-multiplié par un delta (constat PT-D1-01 : le mélange des
## deux unités divisait la rotation souris par ~25).
var look_mouse: Vector2 = Vector2.ZERO


func has_move() -> bool:
	return move.length_squared() > 0.0


## Remet à zéro les fronts après lecture. Les états maintenus survivent : ce sont
## des niveaux, pas des événements.
func consume_edges() -> void:
	jump_pressed = false
	dodge_pressed = false
	interact_pressed = false
	attack_pressed = false
	heavy_pressed = false
	shoot_pressed = false
	lock_pressed = false
	target_next_pressed = false
	target_prev_pressed = false


func clear() -> void:
	move = Vector2.ZERO
	look_analog = Vector2.ZERO
	look_mouse = Vector2.ZERO
	sprint_held = false
	aim_held = false
	consume_edges()


func duplicate_intent() -> InputIntent:
	var copy: InputIntent = InputIntent.new()
	copy.move = move
	copy.look_analog = look_analog
	copy.look_mouse = look_mouse
	copy.sprint_held = sprint_held
	copy.aim_held = aim_held
	copy.jump_pressed = jump_pressed
	copy.dodge_pressed = dodge_pressed
	copy.interact_pressed = interact_pressed
	copy.attack_pressed = attack_pressed
	copy.lock_pressed = lock_pressed
	copy.heavy_pressed = heavy_pressed
	copy.shoot_pressed = shoot_pressed
	copy.target_next_pressed = target_next_pressed
	copy.target_prev_pressed = target_prev_pressed
	return copy
