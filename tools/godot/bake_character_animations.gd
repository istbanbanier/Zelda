## Cuit les bibliothèques d'animations des personnages (ART-Q1/Q2) depuis
## les deux bibliothèques Quaternius UAL importées — versions IN-PLACE
## uniquement (`UAL*_Standard.glb`, jamais `*_RM`).
##
## Pour chaque état des douze exigés : copie du clip, bouclage EXPLICITE
## (jamais hérité en silence), et AUDIT du root motion — dérive horizontale
## du pelvis entre début et fin + amplitude maximale, échantillonnées sur la
## vraie piste. Une dérive hors seuil fait ÉCHOUER la cuisson : garde-fou
## contre un fichier root-motion pris par erreur. Les chiffres partent dans
## `evidence/` : « neutralisé et documenté par animation », pas déclaré.
##
## Usage :
##   godot --headless --path . --script tools/godot/bake_character_animations.gd
extends SceneTree

const UAL1: String = "res://assets/animations/UAL1_Standard.glb"
const UAL2: String = "res://assets/animations/UAL2_Standard.glb"
const PELVIS_PATH: String = "Armature/Skeleton3D:pelvis"
## Une BOUCLE in-place doit se refermer : dérive pelvis début→fin ~0. Un
## fichier root-motion (_RM) fait dériver Walk/Jog/Sprint de plusieurs
## mètres — ce seuil serré est le vrai détecteur de mauvais fichier source.
const MAX_LOOP_DRIFT_M: float = 0.05
## Un ONE-SHOT déplace légitimement le pelvis DANS la pose (Death01 : le
## corps s'allonge, ~0,8 m ; Sword_Regular_A finit en fente, la récupération
## étant le clip _Rec séparé). Ce n'est pas du root motion — le seuil ne
## garde que contre un vrai clip à déplacement (_RM : roll ≈ 1,5-2 m).
const MAX_ONESHOT_DRIFT_M: float = 1.2

## Une bibliothèque par personnage : état → { source, clip (nom APRÈS
## import : le suffixe _Loop est consommé par l'importeur, converti en flag
## de bouclage), loop }.
const BAKES: Dictionary = {
	"res://assets/animations/AL_HeroStates.res": {
		"audit": "res://evidence/artQ1/hero_anim_audit.json",
		"selection": {
			&"idle": {"source": UAL1, "clip": &"Idle", "loop": true},
			&"walk": {"source": UAL1, "clip": &"Walk", "loop": true},
			&"run": {"source": UAL1, "clip": &"Jog_Fwd", "loop": true},
			&"sprint": {"source": UAL1, "clip": &"Sprint", "loop": true},
			&"jump": {"source": UAL1, "clip": &"Jump_Start", "loop": false},
			&"fall": {"source": UAL1, "clip": &"Jump", "loop": true},
			&"land": {"source": UAL1, "clip": &"Jump_Land", "loop": false},
			&"dodge": {"source": UAL1, "clip": &"Roll", "loop": false},
			&"attack_light": {"source": UAL2, "clip": &"Sword_Regular_A",
				"loop": false},
			&"attack_heavy": {"source": UAL2, "clip": &"Sword_Heavy_Combo",
				"loop": false},
			&"hurt": {"source": UAL1, "clip": &"Hit_Chest", "loop": false},
			&"death": {"source": UAL1, "clip": &"Death01", "loop": false},
			# V4 lot 14 — états OPTIONNELS (hors contrat des douze) : mantle
			# réel, geste d'interaction, geste de consommation (E.2b cuisine).
			&"mantle": {"source": UAL2, "clip": &"ClimbUp_1m", "loop": false},
			&"interact": {"source": UAL1, "clip": &"Interact", "loop": false},
			&"consume": {"source": UAL2, "clip": &"Consume", "loop": false},
		},
	},
	# ART-Q2 — pillard braise : gourdin (crochet de mêlée), marche de
	# patrouille/repli, jog de poursuite. Les états aériens réutilisent les
	# clips de saut : l'IA ne saute pas aujourd'hui, mais le contrat des
	# douze états reste plein — jamais un trou silencieux.
	"res://assets/animations/AL_RaiderStates.res": {
		"audit": "res://evidence/artQ2/raider_anim_audit.json",
		"selection": {
			&"idle": {"source": UAL1, "clip": &"Idle", "loop": true},
			&"walk": {"source": UAL1, "clip": &"Walk", "loop": true},
			&"run": {"source": UAL1, "clip": &"Jog_Fwd", "loop": true},
			&"sprint": {"source": UAL1, "clip": &"Jog_Fwd", "loop": true},
			&"jump": {"source": UAL1, "clip": &"Jump_Start", "loop": false},
			&"fall": {"source": UAL1, "clip": &"Jump", "loop": true},
			&"land": {"source": UAL1, "clip": &"Jump_Land", "loop": false},
			&"dodge": {"source": UAL1, "clip": &"Roll", "loop": false},
			&"attack_light": {"source": UAL2, "clip": &"Melee_Hook",
				"loop": false},
			&"attack_heavy": {"source": UAL2, "clip": &"OverhandThrow",
				"loop": false},
			&"hurt": {"source": UAL1, "clip": &"Hit_Chest", "loop": false},
			&"death": {"source": UAL1, "clip": &"Death01", "loop": false},
		},
	},
}


func _initialize() -> void:
	var players: Dictionary = {}
	var roots: Array[Node] = []
	var all_green: bool = true
	for output: String in BAKES:
		if not _bake(output, BAKES[output], players, roots):
			all_green = false
	for root: Node in roots:
		root.free()
	quit(0 if all_green else 1)


func _bake(output: String, config: Dictionary, players: Dictionary,
		roots: Array[Node]) -> bool:
	var selection: Dictionary = config["selection"]
	var audit_path: String = String(config["audit"])
	var library: AnimationLibrary = AnimationLibrary.new()
	var audit: Dictionary = {}
	var failed: bool = false

	for state: StringName in selection:
		var entry: Dictionary = selection[state]
		var source: String = String(entry["source"])
		if not players.has(source):
			var scene: Node = (load(source) as PackedScene).instantiate()
			roots.append(scene)
			var found: Array[Node] = scene.find_children("*",
				"AnimationPlayer", true, false)
			players[source] = found[0] as AnimationPlayer \
				if not found.is_empty() else null
		var player: AnimationPlayer = players[source]
		var clip: StringName = entry["clip"] as StringName
		if player == null or not player.has_animation(clip):
			push_error("[bake] clip ABSENT : %s (%s) pour l'état %s"
				% [String(clip), source, String(state)])
			failed = true
			continue
		var animation: Animation = player.get_animation(clip).duplicate(true) \
			as Animation
		animation.loop_mode = Animation.LOOP_LINEAR if bool(entry["loop"]) \
			else Animation.LOOP_NONE
		var measures: Dictionary = _audit_root_motion(animation)
		measures["state"] = String(state)
		measures["source"] = source.get_file()
		measures["loop"] = bool(entry["loop"])
		audit[String(clip)] = measures
		var limit: float = MAX_LOOP_DRIFT_M if bool(entry["loop"]) \
			else MAX_ONESHOT_DRIFT_M
		if float(measures["drift_m"]) > limit:
			push_error("[bake] %s : dérive pelvis %.3f m > %.2f m — ce clip "
				% [String(clip), float(measures["drift_m"]), limit]
				+ "n'est pas in-place. Mauvais fichier source ?")
			failed = true
		if bool(measures["node_motion"]):
			push_error("[bake] %s : piste de POSITION sur un NŒUD (pas un os) "
				% String(clip) + "— root motion de nœud interdit (§ordre Q1)")
			failed = true
		if not library.has_animation(clip):
			library.add_animation(clip, animation)

	if failed:
		return false
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(audit_path).get_base_dir())
	var handle: FileAccess = FileAccess.open(audit_path, FileAccess.WRITE)
	handle.store_string(JSON.stringify({
		"commit": _commit(), "max_loop_drift_m": MAX_LOOP_DRIFT_M,
		"max_oneshot_drift_m": MAX_ONESHOT_DRIFT_M,
		"pelvis_path": PELVIS_PATH, "clips": audit,
	}, "  "))
	handle.close()
	var error: Error = ResourceSaver.save(library, output)
	if error != OK:
		push_error("[bake] échec d'écriture %s : %s" % [output, error])
		return false
	print("[bake] %d clips -> %s ; audit -> %s"
		% [library.get_animation_list().size(), output, audit_path])
	for clip: Variant in audit:
		var m: Dictionary = audit[clip]
		print("  %-18s drift %.4f m, amplitude %.4f m, %.2f s (%s)"
			% [String(clip), float(m["drift_m"]), float(m["range_m"]),
				float(m["length_s"]), String(m["state"])])
	return true


## Mesure la piste POSITION du pelvis : dérive horizontale début→fin et
## amplitude maximale horizontale, sur 32 échantillons réels. Détecte aussi
## toute piste de position visant un NŒUD (sous-nom vide = pas un os) : le
## root motion de nœud est interdit — la capsule reste l'autorité.
func _audit_root_motion(animation: Animation) -> Dictionary:
	var node_motion: bool = false
	for i: int in range(animation.get_track_count()):
		if animation.track_get_type(i) == Animation.TYPE_POSITION_3D \
				and animation.track_get_path(i).get_subname_count() == 0:
			node_motion = true
	var track: int = animation.find_track(NodePath(PELVIS_PATH),
		Animation.TYPE_POSITION_3D)
	if track < 0:
		return {"drift_m": 0.0, "range_m": 0.0, "length_s": animation.length,
			"pelvis_track": false, "node_motion": node_motion}
	var first: Vector3 = animation.position_track_interpolate(track, 0.0)
	var last: Vector3 = animation.position_track_interpolate(track,
		animation.length)
	var lo: Vector2 = Vector2(first.x, first.z)
	var hi: Vector2 = lo
	for i: int in range(33):
		var at: float = animation.length * float(i) / 32.0
		var sample: Vector3 = animation.position_track_interpolate(track, at)
		lo = lo.min(Vector2(sample.x, sample.z))
		hi = hi.max(Vector2(sample.x, sample.z))
	return {
		"drift_m": Vector2(last.x - first.x, last.z - first.z).length(),
		"range_m": (hi - lo).length(),
		"length_s": animation.length,
		"pelvis_track": true,
		"node_motion": node_motion,
	}


func _commit() -> String:
	var output: Array = []
	if OS.execute("git", ["rev-parse", "HEAD"], output) == 0 \
			and not output.is_empty():
		return String(output[0]).strip_edges()
	return "inconnu"
