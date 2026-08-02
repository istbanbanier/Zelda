## Cuit la bibliothèque d'animations du héros (ART-Q1) depuis les deux
## bibliothèques Quaternius UAL importées — versions IN-PLACE uniquement
## (`UAL*_Standard.glb`, jamais `*_RM`).
##
## Pour chaque état des douze exigés : copie du clip, bouclage EXPLICITE
## (jamais hérité en silence), et AUDIT du root motion — dérive horizontale
## du pelvis entre début et fin + amplitude maximale, échantillonnées sur la
## vraie piste. Une dérive > MAX_DRIFT_M fait ÉCHOUER la cuisson : c'est le
## garde-fou contre un fichier root-motion pris par erreur. Les chiffres
## partent dans `evidence/artQ1/hero_anim_audit.json` : « neutralisé et
## documenté par animation », pas déclaré.
##
## Usage :
##   godot --headless --path . --script tools/godot/bake_hero_animations.gd
extends SceneTree

const OUTPUT_PATH: String = "res://assets/animations/AL_HeroStates.res"
const AUDIT_PATH: String = "res://evidence/artQ1/hero_anim_audit.json"
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

## état → { source, clip (nom APRÈS import : le suffixe _Loop est consommé
## par l'importeur, qui le convertit en flag de bouclage), loop }.
const SELECTION: Dictionary = {
	&"idle": {"source": "res://assets/animations/UAL1_Standard.glb",
		"clip": &"Idle", "loop": true},
	&"walk": {"source": "res://assets/animations/UAL1_Standard.glb",
		"clip": &"Walk", "loop": true},
	&"run": {"source": "res://assets/animations/UAL1_Standard.glb",
		"clip": &"Jog_Fwd", "loop": true},
	&"sprint": {"source": "res://assets/animations/UAL1_Standard.glb",
		"clip": &"Sprint", "loop": true},
	&"jump": {"source": "res://assets/animations/UAL1_Standard.glb",
		"clip": &"Jump_Start", "loop": false},
	&"fall": {"source": "res://assets/animations/UAL1_Standard.glb",
		"clip": &"Jump", "loop": true},
	&"land": {"source": "res://assets/animations/UAL1_Standard.glb",
		"clip": &"Jump_Land", "loop": false},
	&"dodge": {"source": "res://assets/animations/UAL1_Standard.glb",
		"clip": &"Roll", "loop": false},
	&"attack_light": {"source": "res://assets/animations/UAL2_Standard.glb",
		"clip": &"Sword_Regular_A", "loop": false},
	&"attack_heavy": {"source": "res://assets/animations/UAL2_Standard.glb",
		"clip": &"Sword_Heavy_Combo", "loop": false},
	&"hurt": {"source": "res://assets/animations/UAL1_Standard.glb",
		"clip": &"Hit_Chest", "loop": false},
	&"death": {"source": "res://assets/animations/UAL1_Standard.glb",
		"clip": &"Death01", "loop": false},
}


func _initialize() -> void:
	var players: Dictionary = {}
	var roots: Array[Node] = []
	var library: AnimationLibrary = AnimationLibrary.new()
	var audit: Dictionary = {}
	var failed: bool = false

	for state: StringName in SELECTION:
		var entry: Dictionary = SELECTION[state]
		var source: String = String(entry["source"])
		if not players.has(source):
			var scene: Node = (load(source) as PackedScene).instantiate()
			roots.append(scene)
			var found: Array[Node] = scene.find_children("*", "AnimationPlayer",
				true, false)
			players[source] = found[0] as AnimationPlayer if not found.is_empty() \
				else null
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
		if library.has_animation(clip):
			continue   # même clip demandé par deux états : une seule copie
		library.add_animation(clip, animation)

	for root: Node in roots:
		root.free()
	if failed:
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(AUDIT_PATH).get_base_dir())
	var handle: FileAccess = FileAccess.open(AUDIT_PATH, FileAccess.WRITE)
	handle.store_string(JSON.stringify({
		"commit": _commit(), "max_loop_drift_m": MAX_LOOP_DRIFT_M,
		"max_oneshot_drift_m": MAX_ONESHOT_DRIFT_M,
		"pelvis_path": PELVIS_PATH, "clips": audit,
	}, "  "))
	handle.close()
	var error: Error = ResourceSaver.save(library, OUTPUT_PATH)
	if error != OK:
		push_error("[bake] échec d'écriture %s : %s" % [OUTPUT_PATH, error])
		quit(1)
		return
	print("[bake] %d clips -> %s ; audit -> %s"
		% [library.get_animation_list().size(), OUTPUT_PATH, AUDIT_PATH])
	for clip: Variant in audit:
		var m: Dictionary = audit[clip]
		print("  %-18s drift %.4f m, amplitude %.4f m, %.2f s (%s)"
			% [String(clip), float(m["drift_m"]), float(m["range_m"]),
				float(m["length_s"]), String(m["state"])])
	quit(0)


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
