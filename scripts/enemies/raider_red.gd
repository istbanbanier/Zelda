## Pillard braise — `raider_red` (MASTER_SPEC §12.1, §12.7).
##
## Le tutoriel vivant : perception lente, télégraphe long (0,65-0,95 s —
## le startup de son `AttackDefinition`), UN coup, recul après une esquive
## réussie du joueur (sa propre hitbox le lui apprend), et FUITE de 2-4 s
## quand un allié meurt à portée d'ouïe (§12.1 — D-EN.0). Ses nombres
## vivent dans `EnemyTuning` (§5.4), sa tuyauterie dans `EnemyBase`
## (D-EN.0) — ce fichier ne contient QUE ce qui fait du braise le braise.
class_name RaiderRed
extends EnemyBase

@onready var _hitbox: HitboxComponent = $Pivot/ClubHitbox


func _family_ready() -> void:
	telegraph_color = Color(0.95, 0.2, 0.12)
	# §12.1 : il recule après une esquive réussie. Un coup confirmé sur une
	# cible invulnérable est un coup esquivé.
	_hitbox.hit_confirmed.connect(_on_own_hit_confirmed)
	# Gourdin visible (PT-D1-03 : « aucune arme visible »).
	var club: MeshInstance3D = MeshInstance3D.new()
	club.name = "ClubMesh"
	var club_box: BoxMesh = BoxMesh.new()
	club_box.size = Vector3(0.11, 0.11, 0.7)
	club.mesh = club_box
	var club_material: StandardMaterial3D = StandardMaterial3D.new()
	club_material.albedo_color = Color(0.4, 0.26, 0.14)
	club.material_override = club_material
	club.position = Vector3(0.35, 1.0, 0.35)
	_pivot.add_child(club)


## Le gourdin graybox rejoint la main animée du modèle monté : même
## grammaire de prise que l'épée du joueur.
func _family_visual_mounted() -> void:
	var club: MeshInstance3D = _pivot.get_node_or_null("ClubMesh") \
		as MeshInstance3D
	if club == null:
		return
	var socket: BoneAttachment3D = _visual.weapon_socket()
	if socket == null:
		return
	var grip: Node3D = Node3D.new()
	grip.name = "ClubGrip"
	socket.add_child(grip)
	grip.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	grip.position = Vector3(0.0, 0.05, 0.0)
	club.get_parent().remove_child(club)
	grip.add_child(club)
	club.position = Vector3(0.0, 0.0, 0.22)
	club.rotation = Vector3.ZERO


## §12.1 : coup confirmé sur cible invulnérable = esquive réussie du
## joueur → il recule. Sa hitbox le sait sans câblage vers le joueur.
func _on_own_hit_confirmed(_event: DamageEvent, target: HurtboxComponent) -> void:
	if _state == State.DEAD:
		return
	var target_health: HealthComponent = target.health()
	if target_health != null and target_health.is_invulnerable():
		_attack.cancel()
		_enter(State.RETREAT)


## §12.1 : « peut fuir 2-4 s après la mort d'un allié » — le braise est LA
## famille qui fuit ; il abandonne sa cible et détale dos au corps.
func _family_on_ally_death(position: Vector3) -> void:
	if _state in [State.STAGGERED, State.ATTACK]:
		return   # une action engagée se termine — la fuite n'interrompt pas
	_target = null
	start_flee(position)
