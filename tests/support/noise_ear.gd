## Oreille factice pour les tests de bruit : enregistre chaque appel
## `hear_noise` reçu, comme le ferait un ennemi (§12.7).
extends Node3D

var heard: Array[Dictionary] = []


func hear_noise(at: Vector3, radius: float, kind: StringName) -> void:
	heard.append({ "position": at, "radius": radius, "kind": kind })
