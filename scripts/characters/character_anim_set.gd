## Correspondance état gameplay → clip d'animation (ordre de nuit §6 :
## pipeline d'animation, et §7 : « centralise la correspondance des
## animations »).
##
## Ressource IMMUABLE (règle projet) : une par personnage/rig. Les DOUZE états
## obligatoires de l'ordre ont chacun leur clip nommé ; le validateur mesure
## ce qui manque VRAIMENT dans un AnimationPlayer donné — le branchement d'un
## rig se prouve, il ne se déclare pas.
class_name CharacterAnimSet
extends Resource

## Les douze états exigés par l'ordre de nuit (idle → mort).
const REQUIRED_STATES: Array[StringName] = [
	&"idle", &"walk", &"run", &"sprint", &"jump", &"fall", &"land",
	&"dodge", &"attack_light", &"attack_heavy", &"hurt", &"death",
]

@export var idle: StringName = &""
@export var walk: StringName = &""
@export var run: StringName = &""
@export var sprint: StringName = &""
@export var jump: StringName = &""
@export var fall: StringName = &""
@export var land: StringName = &""
@export var dodge: StringName = &""
@export var attack_light: StringName = &""
@export var attack_heavy: StringName = &""
@export var hurt: StringName = &""
@export var death: StringName = &""
## États OPTIONNELS (V4 lot 14) — hors du contrat des douze : un vide ici
## n'est pas un trou, le pilote garde sa lecture de repli (mantle → jump).
@export var mantle: StringName = &""
@export var interact: StringName = &""
@export var consume: StringName = &""
## Os du squelette portant l'arme (BoneAttachment3D) — vide = pas de socket
## squelette, le pivot procédural du contrôleur reste l'attache.
@export var weapon_bone: StringName = &""


func clip_for(state: StringName) -> StringName:
	match state:
		&"idle": return idle
		&"walk": return walk
		&"run": return run
		&"sprint": return sprint
		&"jump": return jump
		&"fall": return fall
		&"land": return land
		&"dodge": return dodge
		&"attack_light": return attack_light
		&"attack_heavy": return attack_heavy
		&"hurt": return hurt
		&"death": return death
		&"mantle": return mantle
		&"interact": return interact
		&"consume": return consume
	return &""


## États sans clip DÉCLARÉ (trous de la correspondance elle-même).
func undeclared_states() -> Array[StringName]:
	var missing: Array[StringName] = []
	for state: StringName in REQUIRED_STATES:
		if clip_for(state) == &"":
			missing.append(state)
	return missing


## États dont le clip déclaré N'EXISTE PAS dans le lecteur fourni — mesuré
## contre le vrai AnimationPlayer importé, jamais supposé.
func missing_clips(player: AnimationPlayer) -> Array[StringName]:
	var missing: Array[StringName] = []
	for state: StringName in REQUIRED_STATES:
		var clip: StringName = clip_for(state)
		if clip == &"" or not player.has_animation(clip):
			missing.append(state)
	return missing
