## Adaptateur visuel de personnage (ordre de nuit ART-Q1/Q2, infrastructure).
##
## Monté SOUS le VisualRoot d'un personnage : il tente de résoudre son modèle
## riggé via `AssetRegistry` et, s'il existe, le monte et pilote ses clips par
## `play_state()`. S'il MANQUE (packs pas encore livrés) : REPLI — l'adaptateur
## reste inerte et le graybox procédural existant garde toute l'autorité.
##
## Contrats durs (ordre §6) :
## - le déplacement reste piloté par le contrôleur : clips in-place, jamais de
##   root motion silencieux (le modèle est monté sous un Node3D fixe) ;
## - les fenêtres de combat existantes restent autoritaires — cet adaptateur
##   ne décide RIEN, il visualise l'état qu'on lui donne ;
## - le modèle n'est jamais la collision gameplay.
class_name CharacterVisual
extends Node3D

@export var model_id: StringName = &""
@export var anim_set: CharacterAnimSet

var _model: Node3D = null
var _player: AnimationPlayer = null
var _skeleton: Skeleton3D = null
var _socket: BoneAttachment3D = null
var _current_state: StringName = &""


func _ready() -> void:
	var packed: PackedScene = AssetRegistry.resolve(model_id)
	if packed == null:
		return   # repli : le graybox existant reste seul visible
	_model = packed.instantiate() as Node3D
	if _model == null:
		push_error("[visual] %s n'est pas un Node3D — repli graybox."
			% String(model_id))
		return
	add_child(_model)
	var players: Array[Node] = _model.find_children("*", "AnimationPlayer", true, false)
	_player = players[0] as AnimationPlayer if not players.is_empty() else null
	var skeletons: Array[Node] = _model.find_children("*", "Skeleton3D", true, false)
	_skeleton = skeletons[0] as Skeleton3D if not skeletons.is_empty() else null
	if anim_set != null and _skeleton != null and anim_set.weapon_bone != &"" \
			and _skeleton.find_bone(String(anim_set.weapon_bone)) >= 0:
		_socket = BoneAttachment3D.new()
		_socket.name = "WeaponSocket"
		_skeleton.add_child(_socket)
		_socket.bone_name = String(anim_set.weapon_bone)


## Vrai quand AUCUN modèle riggé n'est monté : le graybox reste l'autorité
## visuelle. Mesurable par test — c'est le contrat de repli de l'ordre.
func is_fallback_active() -> bool:
	return _model == null


## Joue le clip correspondant à l'état gameplay. Sans modèle ou sans clip :
## no-op silencieux — l'état est TOUJOURS accepté, jamais bloquant.
func play_state(state: StringName) -> void:
	_current_state = state
	if _player == null or anim_set == null:
		return
	var clip: StringName = anim_set.clip_for(state)
	if clip == &"" or not _player.has_animation(clip):
		return
	if _player.current_animation != String(clip):
		_player.play(clip)


func current_state() -> StringName:
	return _current_state


## Attache d'arme du squelette, ou null → l'appelant garde son pivot
## procédural (le WeaponPivot actuel du contrôleur).
func weapon_socket() -> BoneAttachment3D:
	return _socket


## Problèmes mesurés du branchement — pour la scène de calibration et les
## tests : jamais « ça a l'air bon », toujours une liste vérifiable.
func validate() -> Array[String]:
	var problems: Array[String] = []
	if _model == null:
		problems.append("modèle absent (%s) — repli graybox actif"
			% String(model_id))
		return problems
	if _player == null:
		problems.append("aucun AnimationPlayer dans le modèle")
	if _skeleton == null:
		problems.append("aucun Skeleton3D dans le modèle")
	if anim_set == null:
		problems.append("aucun CharacterAnimSet affecté")
	elif _player != null:
		for state: StringName in anim_set.missing_clips(_player):
			problems.append("clip manquant pour l'état : %s" % String(state))
	return problems
