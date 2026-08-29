## Socle commun des familles d'ennemis (D-EN.0, MASTER_SPEC §12.6-§12.10).
##
## Extrait de `raider_red` (Gate C/D.1) et GÉNÉRALISÉ : perception par
## cadence (distance → cône → raycasts de LOS torse ET tête, jamais par
## frame), chemin navmesh par requêtes directes (leçon D-022), séparation
## locale, feedback matière (télégraphe/flash/mort), mort §12.10 (IA,
## hitbox et collision coupées UNE fois).
##
## États communs de §12.7 portés ici : Idle, Patrol, Suspicious,
## Investigate, Chase, Attack, Retreat, Staggered, Flee, Return, Dead —
## plus Reposition, réservé aux familles qui tournent autour de la cible.
## `Alert` est l'INSTANT d'acquisition (`_acquire_target`), pas un état
## persistant ; `Recover` est la phase RECOVERY du contrat d'attaque
## (`AttackController.Phase`) — mappings documentés, pas des trous.
##
## NOUVEAU au socle (réouverture du Gate D, correctif d'autorité) :
## - MÉMOIRE de dernière position (§12.7) : cible perdue de vue →
##   poursuite de mémoire `memory_duration` s, puis INVESTIGATE de la
##   dernière position, recherche courte, RETURN ;
## - TERRITOIRE (§12.9) : origine au spawn + distance maximale de
##   poursuite — aucune poursuite infinie ; le retour re-perçoit ;
## - OUÏE (§12.7) : `hear_noise()` — sprint, impact, rupture, flèche ;
##   un bruit dans l'audition rend SUSPICIOUS (pause orientée) puis
##   INVESTIGATE vers la position du bruit ;
## - FUITE (§12.1, consommée par le braise) : `witness_ally_death()` —
##   la famille décide si la mort d'un allié proche la fait fuir ;
## - ALERTE (§12.2, consommée par l'azur) : `alert_radius` > 0 partage
##   la cible acquise avec les alliés proches ;
## - PATROUILLE : points optionnels autour de l'origine, sens en éveil.
##
## Chaque famille est une SOUS-CLASSE mince : son arme, ses attaques,
## ses états propres, son rythme — le contrat §12 (« pas de simples
## recolorations ») vit dans ces différences.
class_name EnemyBase
extends CharacterBody3D

signal died()
signal state_changed(state: StringName)

enum State {
	IDLE, PATROL, SUSPICIOUS, INVESTIGATE, CHASE, REPOSITION,
	ATTACK, RETREAT, STAGGERED, FLEE, RETURN, DEAD,
}

## Cadences §12.9 : jamais de perception ni de pathfinding par frame.
const PERCEPTION_INTERVAL: int = 6
const REPATH_INTERVAL: int = 15
## Fenêtre et décroissance du recul (§10.2) : assez pour se LIRE (l'attaquant
## et la cible « se séparent visiblement »), assez court pour ne pas devenir
## un stun déguisé — le stagger, lui, appartient à la poise.
const KNOCKBACK_TIME: float = 0.18
const KNOCKBACK_DECAY: float = 22.0
const GRAVITY: float = 24.0
const SEPARATION_RADIUS: float = 1.7
const SEPARATION_WEIGHT: float = 0.9
## Pause orientée avant d'aller voir (état SUSPICIOUS).
const SUSPICION_PAUSE: float = 0.6
## ISS-085 — part du territoire qu'une riposte bornée s'autorise à parcourir.
## Ce n'est pas un ornement : `_process_investigate` n'a AUCUNE garde de
## distance, contrairement à `_process_chase` qui abandonne au-delà de
## `max_pursuit_distance`. Le seul rempart qui empêche la riposte de sortir
## du territoire est ce clamp — il doit garder de la marge, pas viser la
## frontière au millimètre.
const AVANCE_TERRITOIRE: float = 0.6
## Désaxement maximal pour DÉCLENCHER une attaque (D-EN.2).
const ATTACK_FACING_DEG: float = 30.0

@export var tuning: EnemyTuning
## Points de patrouille RELATIFS à l'origine du territoire — vide = poste
## fixe (IDLE). La perception reste active en patrouille.
@export var patrol_offsets: Array[Vector3] = []

@onready var _health: HealthComponent = $HealthComponent
@onready var _poise: PoiseComponent = $PoiseComponent
@onready var _attack: AttackControllerComponent = $AttackController
@onready var _pivot: Node3D = $Pivot
## Hurtbox PRINCIPALE, cherchée par nom dans tout le sous-arbre : une
## anatomie peut exiger de la porter sous le pivot (le point faible
## DORSAL du colosse doit tourner avec lui) — mesuré en D-EN.4.
@onready var _hurtbox: HurtboxComponent = _find_primary_hurtbox()


func _find_primary_hurtbox() -> HurtboxComponent:
	var found: Array[Node] = find_children("Hurtbox", "HurtboxComponent",
		true, false)
	return found[0] as HurtboxComponent if not found.is_empty() else null

var _state: State = State.IDLE
var _target: Node3D = null
var _perception_tick: int = 0
var _repath_tick: int = 0
var _state_timer: float = 0.0
var _attack_cooldown: float = 0.0
var _path: PackedVector3Array = PackedVector3Array()
var _path_index: int = 0
var _path_goal: Vector3 = Vector3.INF

## Mémoire (§12.7), territoire (§12.9), patrouille, fuite.
var _territory_origin: Vector3 = Vector3.ZERO
var _last_known: Vector3 = Vector3.ZERO
var _memory_timer: float = 0.0
var _patrol_index: int = 0
var _flee_from: Vector3 = Vector3.ZERO

## Feedback matière : graybox OU matériaux par instance du modèle monté.
var _body_material: StandardMaterial3D = null
var _base_color: Color = Color.WHITE
var _feedback_materials: Array[BaseMaterial3D] = []
var _feedback_bases: Array[Color] = []
var _visual: CharacterVisual = null
var _model_mounted: bool = false
var _flash_timer: float = 0.0
## Gel d'impact (§10.2), consommé depuis `event.hit_stop` — la valeur que
## l'attaque DÉCLARE depuis C.1 et que personne ne lisait (TESTS.md, abs. 2.4).
var _hitstop_timer: float = 0.0
## Recul reçu (§10.2). Sans cette fenêtre dédiée, le steering réécrivait la
## vélocité au tick suivant et `event.knockback` (2,0-4,5 dans les données)
## ne déplaçait JAMAIS la cible (TESTS.md, bug 5).
var _knockback_impulse: Vector3 = Vector3.ZERO
var _knockback_timer: float = 0.0
## Couleur d'annonce — chaque famille pose la sienne (lisibilité §10.5).
var telegraph_color: Color = Color(0.95, 0.2, 0.12)


func _ready() -> void:
	if tuning == null:
		tuning = EnemyTuning.new()
		push_warning("[%s] aucun EnemyTuning assigné — valeurs par défaut."
			% name)
	_territory_origin = global_position
	_health.max_health = tuning.max_health
	_health.revive()
	_poise.max_poise = tuning.poise
	_health.died.connect(_on_died)
	_poise.poise_broken.connect(_on_poise_broken)
	_hurtbox.hit_received.connect(_on_hit_received)
	_setup_graybox_material()
	_family_ready()
	_mount_visual()


## Matériau graybox dédoublé : le télégraphe de l'un ne rougit jamais les
## autres (§5.4).
func _setup_graybox_material() -> void:
	var body_mesh: MeshInstance3D = _pivot.get_node_or_null("BodyMesh") \
		as MeshInstance3D
	if body_mesh == null:
		return
	var base: StandardMaterial3D = \
		body_mesh.get_surface_override_material(0) as StandardMaterial3D
	if base == null and body_mesh.mesh != null:
		base = body_mesh.mesh.surface_get_material(0) as StandardMaterial3D
	if base != null:
		_body_material = base.duplicate() as StandardMaterial3D
		_base_color = _body_material.albedo_color
		body_mesh.set_surface_override_material(0, _body_material)
	if _body_material != null:
		_feedback_materials = [_body_material]
		_feedback_bases = [_base_color]


## Montage du modèle riggé si la famille en a un (CharacterVisual sous le
## pivot) — graybox masqué, matériaux par instance collectés.
func _mount_visual() -> void:
	_visual = _pivot.get_node_or_null("CharacterVisual") as CharacterVisual
	if _visual == null or _visual.is_fallback_active():
		return
	_model_mounted = true
	# TOUS les maillages graybox enfants DIRECTS du pivot disparaissent, pas
	# seulement `BodyMesh` : le chasseur en porte deux (corps + torse), et
	# n'en masquer qu'un laissait une boîte plantée dans le modèle. Le
	# modèle riggé, lui, vit sous `CharacterVisual` — il n'est jamais
	# atteint par cette boucle.
	for child: Node in _pivot.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = false
	_collect_model_materials()
	state_changed.connect(_on_state_changed_visual)
	_visual.play_state(&"idle")
	_family_visual_mounted()


func _collect_model_materials() -> void:
	_feedback_materials.clear()
	_feedback_bases.clear()
	for node: Node in _visual.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node as MeshInstance3D
		var surfaces: int = mesh.mesh.get_surface_count() if mesh.mesh != null else 0
		for surface: int in range(surfaces):
			var material: BaseMaterial3D = \
				mesh.get_surface_override_material(surface) as BaseMaterial3D
			if material == null:
				# REPLI — sans lui, le Colosse et le Chasseur n'avaient AUCUN
				# retour visuel : ni télégraphe d'attaque, ni flash de dégât,
				# ni assombrissement du cadavre. Leurs scènes visuelles ne
				# posent pas de matériau d'override (contrairement aux trois
				# pillards, qui passent par `character_model_sockets.gd`), et
				# tout le retour de combat sortait tôt sur
				# `if _feedback_materials.is_empty(): return`. Un rocher de
				# quatre mètres partait donc sans le moindre avertissement.
				#
				# On duplique le matériau ACTIF du modèle et on l'installe en
				# override : la copie est propre à cet exemplaire, donc frapper
				# un colosse n'allume pas son voisin.
				var active: BaseMaterial3D = \
					mesh.get_active_material(surface) as BaseMaterial3D
				if active != null:
					material = active.duplicate() as BaseMaterial3D
					mesh.set_surface_override_material(surface, material)
			if material != null and not _feedback_materials.has(material):
				_feedback_materials.append(material)
				_feedback_bases.append(material.albedo_color)


## ---------------------------------------------------------------------------
## Crochets de famille — la sous-classe EST la famille (§12).
## ---------------------------------------------------------------------------

func _family_ready() -> void:
	pass


func _family_visual_mounted() -> void:
	pass


## À portée et hors cooldown : la famille CHOISIT et lance son attaque.
func _family_try_attack(_distance: float) -> bool:
	return _attack.try_attack()


## États PROPRES à la famille (garde, escarmouche, charge…). Vrai si
## l'état a été traité — sinon le socle traite les états communs.
func _process_family_state(_delta: float) -> bool:
	return false


## La mort d'un allié s'est vue/entendue — chaque famille décide (§12.1 :
## le braise peut fuir 2-4 s ; les autres ignorent par défaut).
func _family_on_ally_death(_position: Vector3) -> void:
	pass


func _on_state_changed_visual(state: StringName) -> void:
	match state:
		&"idle": _visual.play_state(&"idle")
		&"patrol": _visual.play_state(&"walk")
		&"suspicious": _visual.play_state(&"idle")
		&"investigate": _visual.play_state(&"walk")
		&"chase": _visual.play_state(&"run")
		&"reposition": _visual.play_state(&"walk")
		&"return": _visual.play_state(&"walk")
		&"retreat": _visual.play_state(&"walk")
		&"flee": _visual.play_state(&"run")
		&"attack": _visual.play_state(&"attack_light", true)
		&"staggered": _visual.play_state(&"hurt", true)
		&"dead": _visual.play_state(&"death")


func _family_state_name(_state: State) -> StringName:
	return &"?"


## ---------------------------------------------------------------------------
## Boucle
## ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	# Hit-stop (§10.2) : le corps se FIGE — ni décision, ni déplacement, ni
	# décompte. C'est le poids du coup ; 0,045-0,085 s selon l'attaque.
	if _hitstop_timer > 0.0:
		_hitstop_timer = maxf(0.0, _hitstop_timer - delta)
		return
	_state_timer += delta
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_poise.update(delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	_update_feedback(delta)

	# Recul (§10.2) : pendant la poussée, l'impulsion gouverne — pas le
	# steering. Décroissance vers zéro, puis la machine à états reprend.
	if _knockback_timer > 0.0:
		_knockback_timer = maxf(0.0, _knockback_timer - delta)
		velocity.x = _knockback_impulse.x
		velocity.z = _knockback_impulse.z
		_knockback_impulse = _knockback_impulse.move_toward(
			Vector3.ZERO, KNOCKBACK_DECAY * delta)
		move_and_slide()
		return

	if not _process_family_state(delta):
		match _state:
			State.IDLE:
				velocity.x = 0.0
				velocity.z = 0.0
				_tick_perception()
				if _state == State.IDLE and not patrol_offsets.is_empty():
					_enter(State.PATROL)
			State.PATROL:
				_process_patrol(delta)
			State.SUSPICIOUS:
				_process_suspicious(delta)
			State.INVESTIGATE:
				_process_investigate(delta)
			State.CHASE:
				_process_chase(delta)
			State.ATTACK:
				velocity.x = 0.0
				velocity.z = 0.0
				if not _attack.update(delta):
					_attack_cooldown = tuning.attack_cooldown
					_release_attack_token()
					_enter(State.CHASE)
			State.RETREAT:
				_process_retreat(delta)
			State.STAGGERED:
				velocity.x = 0.0
				velocity.z = 0.0
				if _state_timer >= tuning.stagger_duration:
					_poise.recover()
					_enter(State.CHASE)
			State.FLEE:
				_process_flee(delta)
			State.RETURN:
				_process_return(delta)
			_:
				pass

	move_and_slide()


func _process_patrol(delta: float) -> void:
	_tick_perception()
	if _state != State.PATROL:
		return
	if patrol_offsets.is_empty():
		_enter(State.IDLE)
		return
	var goal: Vector3 = _territory_origin + patrol_offsets[_patrol_index]
	var to_goal: Vector3 = goal - global_position
	to_goal.y = 0.0
	if to_goal.length() <= 0.7:
		_patrol_index = (_patrol_index + 1) % patrol_offsets.size()
		return
	_face(to_goal, delta)
	var direction: Vector3 = _pursuit_direction_toward(
		goal, to_goal, to_goal.length())
	velocity.x = direction.x * tuning.patrol_speed
	velocity.z = direction.z * tuning.patrol_speed


## §12.7 « Suspicious » : pause ORIENTÉE vers le bruit, puis aller voir.
func _process_suspicious(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	var toward: Vector3 = _last_known - global_position
	toward.y = 0.0
	_face(toward, delta)
	_tick_perception()   # voir la cible pendant la pause = aggro direct
	if _state == State.SUSPICIOUS and _state_timer >= SUSPICION_PAUSE:
		_enter(State.INVESTIGATE)


## §12.7 : « mémoire de dernière position, recherche courte, puis retour ».
func _process_investigate(delta: float) -> void:
	_tick_perception()   # re-voir la cible pendant la recherche ré-aggro
	if _state != State.INVESTIGATE:
		return
	# ISS-085 (2e passe) — LA GARDE VIT AU POINT OÙ LA QUESTION EST POSÉE.
	#
	# Trouvé par la contre-revue à contexte frais, contre ma propre fermeture :
	# j'avais bordé le chemin du COUP et écrit « jamais hors du territoire ».
	# Faux. `hear_noise()` écrit `_last_known` SANS clamp, et cette boucle
	# marchait vers ce point SANS garde de distance — contrairement à
	# `_process_chase`, qui abandonne au-delà de `max_pursuit_distance`.
	# Mesuré : un bruit de rupture à 13,5 m emmenait le garde à 12,70 m d'un
	# territoire de 12. Répétable, donc un joueur promenait la garnison.
	#
	# La leçon est celle d'ISS-083, à la lettre : borner la DESTINATION ici,
	# une fois, plutôt que recopier un clamp sur chaque chemin qui écrit
	# `_last_known` — le bruit, la riposte, l'alerte, la mémoire. Une porte de
	# plus s'ajoutera un jour ; elle héritera de la garde sans que personne y
	# pense.
	var but: Vector3 = _but_dans_le_territoire(_last_known)
	var to_spot: Vector3 = but - global_position
	to_spot.y = 0.0
	if to_spot.length() > 0.8:
		_face(to_spot, delta)
		var direction: Vector3 = _pursuit_direction_toward(
			but, to_spot, to_spot.length())
		velocity.x = direction.x * tuning.patrol_speed
		velocity.z = direction.z * tuning.patrol_speed
		return
	velocity.x = 0.0
	velocity.z = 0.0
	if _state_timer >= tuning.search_duration:
		_enter(State.RETURN)


## Ramène un point d'investigation À L'INTÉRIEUR du territoire, sur le rayon
## qui y mène. Le point INCHANGÉ s'il y est déjà : un bruit légitime à
## l'intérieur doit rester atteignable, sans quoi on corrigerait une sortie en
## fabriquant une inertie.
##
## Borne : `max_pursuit_distance`, la vraie frontière — et non la marge
## `AVANCE_TERRITOIRE` de la riposte. Celle-ci est une intention de
## COMPORTEMENT (« avancer sans camper sur la frontière ») ; celle-là est la
## LOI (§12.9). Les confondre rétrécirait le territoire de 40 % pour tous les
## bruits ordinaires.
func _but_dans_le_territoire(point: Vector3) -> Vector3:
	var vers: Vector3 = point - _territory_origin
	vers.y = 0.0
	var d: float = vers.length()
	if d <= tuning.max_pursuit_distance or d < 0.001:
		return point
	var ramene: Vector3 = _territory_origin \
		+ vers.normalized() * tuning.max_pursuit_distance
	ramene.y = point.y
	return ramene


func _process_chase(delta: float) -> void:
	if not _target_valid():
		_target = null
		_enter(State.IDLE)
		return
	# Territoire (§12.9) : au-delà de la distance maximale, l'ennemi
	# ABANDONNE et rentre — aucune poursuite infinie.
	if global_position.distance_to(_territory_origin) \
			> tuning.max_pursuit_distance:
		_target = null
		_enter(State.RETURN)
		return
	# Mémoire (§12.7) : la vue est re-testée par cadence ; perdue trop
	# longtemps, la cible devient une DERNIÈRE POSITION à investiguer.
	_memory_timer += delta
	_perception_tick += 1
	if _perception_tick % PERCEPTION_INTERVAL == 0 and _has_los(_target):
		_last_known = _target.global_position
		_memory_timer = 0.0
	if _memory_timer > tuning.memory_duration:
		_target = null
		_enter(State.INVESTIGATE)
		return

	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	_face(to_target, delta)

	if distance <= tuning.attack_reach:
		velocity.x = 0.0
		velocity.z = 0.0
		# On n'attaque qu'EN FACE (mesuré D-EN.2 : acquis de dos, le
		# briseur frappait le vide sans s'être retourné) — à portée mais
		# désaxé, l'ennemi PIVOTE d'abord ; le _face ci-dessus travaille.
		if _attack_cooldown <= 0.0 \
				and _facing_angle_deg(to_target) <= ATTACK_FACING_DEG:
			# §12.8 : le TOKEN d'attaque avant le coup — refusé, l'ennemi
			# ENCERCLE (menace mobile) au lieu de s'empiler sur la cible.
			if not _request_attack_token():
				var orbit: Vector3 = direction_or_zero(to_target) \
					.cross(Vector3.UP)
				velocity.x = orbit.x * tuning.patrol_speed
				velocity.z = orbit.z * tuning.patrol_speed
				return
			if _family_try_attack(distance):
				_enter(State.ATTACK)
		return

	var direction: Vector3 = _pursuit_direction_toward(
		_target.global_position, to_target, distance)
	var steered: Vector3 = direction + _separation_push() * SEPARATION_WEIGHT
	if steered.length_squared() > 0.0001:
		steered = steered.normalized()
	var desired: Vector3 = _family_chase_velocity(steered, distance)
	velocity.x = desired.x
	velocity.z = desired.z


## La famille MODÈLE son approche (contournement de l'azur, bande de
## distance…) : reçoit la direction d'approche normalisée (chemin +
## séparation) et la distance, renvoie la vitesse XZ désirée.
func _family_chase_velocity(direction: Vector3, _distance: float) -> Vector3:
	return direction * tuning.pursuit_speed


func _process_retreat(delta: float) -> void:
	if not _target_valid():
		_enter(State.IDLE)
		return
	var away: Vector3 = global_position - _target.global_position
	away.y = 0.0
	# Reculer EN FAISANT FACE : prise de distance, pas une fuite.
	_face(-away, delta)
	if away.length() > 0.001:
		away = away.normalized()
	velocity.x = away.x * tuning.retreat_speed
	velocity.z = away.z * tuning.retreat_speed
	if _state_timer >= tuning.retreat_duration:
		_enter(State.CHASE)


## §12.1 : fuite courte (dos au danger), puis retour aux sens normaux.
func _process_flee(delta: float) -> void:
	var away: Vector3 = global_position - _flee_from
	away.y = 0.0
	if away.length() > 0.001:
		away = away.normalized()
	_face(away, delta)
	velocity.x = away.x * tuning.pursuit_speed
	velocity.z = away.z * tuning.pursuit_speed
	if _state_timer >= tuning.flee_duration:
		_enter(State.RETURN)


func _process_return(delta: float) -> void:
	_tick_perception()   # rentrer n'aveugle pas : re-visible = ré-aggro
	if _state != State.RETURN:
		return
	var home: Vector3 = _territory_origin - global_position
	home.y = 0.0
	if home.length() <= 1.0:
		velocity.x = 0.0
		velocity.z = 0.0
		_enter(State.IDLE)
		return
	_face(home, delta)
	var direction: Vector3 = _pursuit_direction_toward(
		_territory_origin, home, home.length())
	velocity.x = direction.x * tuning.patrol_speed
	velocity.z = direction.z * tuning.patrol_speed


## Chemin navmesh vers un BUT quelconque (cible, dernière position,
## territoire) — requêtes directes, recalcul par cadence et seulement si
## le but a bougé (§12.9). Ligne directe sans carte.
func _pursuit_direction_toward(goal: Vector3, to_goal: Vector3,
		distance: float) -> Vector3:
	if distance <= 0.001:
		return Vector3.ZERO
	var map: RID = _navigation_map()
	_repath_tick += 1
	if _path.is_empty() or (_repath_tick % REPATH_INTERVAL == 1
			and _path_goal.distance_to(goal) > 1.5):
		_path = NavigationServer3D.map_get_path(
			map, global_position, goal, true)
		_path_index = 0
		_path_goal = goal
	if _path.size() < 2:
		return to_goal.normalized()
	while _path_index < _path.size() - 1:
		var reached: Vector3 = _path[_path_index]
		if Vector2(reached.x - global_position.x,
				reached.z - global_position.z).length() < 0.6:
			_path_index += 1
		else:
			break
	var waypoint: Vector3 = _path[_path_index]
	var direction: Vector3 = Vector3(
		waypoint.x - global_position.x, 0.0, waypoint.z - global_position.z)
	if direction.length_squared() < 0.0001:
		return to_goal.normalized()
	return direction.normalized()


## §12.9 : la carte de navigation de MA carrure. Les grandes familles
## empruntent la carte dédiée (`LargeNavigation` dans le monde) ; sans
## elle (labo, arène de test), la carte du monde fait office — le
## pathfinding retombe alors sur la ligne directe, jamais sur un chemin
## impraticable, car la physique reste l'arbitre final.
func _navigation_map() -> RID:
	if tuning != null and tuning.uses_large_navmesh:
		for node: Node in get_tree().get_nodes_in_group("large_navigation"):
			var region: NavigationRegion3D = node as NavigationRegion3D
			if region != null:
				return region.get_navigation_map()
	return get_world_3d().navigation_map


func _separation_push() -> Vector3:
	var push: Vector3 = Vector3.ZERO
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node == self:
			continue
		var other: Node3D = node as Node3D
		if other == null:
			continue
		if other.has_method("health"):
			var other_health: HealthComponent = other.call("health") as HealthComponent
			if other_health != null and other_health.is_dead():
				continue  # un cadavre ne repousse personne
		var away: Vector3 = global_position - other.global_position
		away.y = 0.0
		var gap: float = away.length()
		if gap >= SEPARATION_RADIUS or gap < 0.001:
			continue
		push += away / gap * (1.0 - gap / SEPARATION_RADIUS)
	return push


## ---------------------------------------------------------------------------
## Perception (§12.6-§12.7) — vue, ouïe, alerte, mort d'allié
## ---------------------------------------------------------------------------

func _tick_perception() -> void:
	_perception_tick += 1
	if _perception_tick % PERCEPTION_INTERVAL != 0:
		return
	var player: PlayerController = _find_player()
	if player == null:
		return
	var player_health: HealthComponent = player.health()
	if player_health != null and player_health.is_dead():
		return
	# Une cible DÉJÀ hors du territoire ne m'intéresse pas : sans cette
	# garde, RETURN et CHASE oscilleraient tant que le joueur reste
	# visible depuis la frontière (§12.9 — l'abandon doit tenir).
	if player.global_position.distance_to(_territory_origin) \
			> tuning.max_pursuit_distance:
		return
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > tuning.vision_range:
		return
	var forward: Vector3 = _pivot.global_transform.basis.z
	forward.y = 0.0
	if to_player.length() > 0.001 and forward.length() > 0.001:
		var angle: float = rad_to_deg(
			forward.normalized().angle_to(to_player.normalized()))
		if angle > tuning.vision_half_angle_deg:
			return
	if not _has_los(player):
		return
	_acquire_target(player)


## L'instant « Alert » de §12.7 : acquisition + partage éventuel (§12.2).
##
## ISS-083 — LA GARDE DE TERRITOIRE VIT ICI, ET NULLE PART AILLEURS.
## Elle ne gardait que le chemin de la VISION (`_tick_perception`), tandis que
## `receive_alert()` et l'acquisition sur coup reçu l'ignoraient : la même
## question — « cette cible est-elle dans mon territoire ? » — recevait deux
## réponses opposées selon la porte empruntée. Un joueur tirait une flèche de
## loin, ou se faisait crier dessus par un allié, et emmenait la garnison
## entière hors de sa région. Ce qui bornait réellement la chasse était
## l'ABANDON en poursuite, jamais l'acquisition — donc trop tard.
##
## Une porte de plus s'ajoutera un jour ; elle héritera de la garde sans que
## personne ait à y penser. C'est tout l'intérêt de la placer au point de
## convergence plutôt que chez chaque appelant.
func _acquire_target(target: Node3D) -> void:
	if not is_instance_valid(target):
		return
	if target.global_position.distance_to(_territory_origin) \
			> tuning.max_pursuit_distance:
		return
	_target = target
	_last_known = target.global_position
	_memory_timer = 0.0
	_enter(State.CHASE)
	if tuning.alert_radius > 0.0:
		_alert_allies(target)


## §12.2 : « alerte les alliés dans un rayon limité » — les receveurs
## endormis adoptent la cible.
func _alert_allies(target: Node3D) -> void:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not node.has_method("receive_alert"):
			continue
		var ally: Node3D = node as Node3D
		if ally.global_position.distance_to(global_position) \
				<= tuning.alert_radius:
			ally.call("receive_alert", target)


func receive_alert(target: Node3D) -> void:
	if _state in [State.IDLE, State.PATROL, State.SUSPICIOUS,
			State.INVESTIGATE, State.RETURN] and is_instance_valid(target):
		_acquire_target(target)


## Ouïe (§12.7) : un bruit dans MON audition ET dans le rayon du bruit
## rend suspicieux — pause orientée puis investigation de la position.
## Un ennemi déjà en chasse/combat n'est pas distrait.
func hear_noise(position: Vector3, radius: float, _kind: StringName) -> void:
	if _state in [State.CHASE, State.ATTACK, State.RETREAT,
			State.STAGGERED, State.FLEE, State.DEAD]:
		return
	var distance: float = global_position.distance_to(position)
	if distance > minf(radius, tuning.hearing_range):
		return
	_last_known = position
	_enter(State.SUSPICIOUS)


## Mort d'un allié : diffusée par le socle à la mort (§12.1 — le braise
## peut fuir). Vue OU entendue : rayon d'audition.
func witness_ally_death(position: Vector3) -> void:
	if _state == State.DEAD:
		return
	if global_position.distance_to(position) > tuning.hearing_range:
		return
	_family_on_ally_death(position)


## LOS torse PUIS tête (correctif : « raycast vers torse et tête ») —
## voir l'un des deux suffit ; aucune vision à travers mur.
func _has_los(target: Node3D) -> bool:
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for target_height: float in [1.0, 1.6]:
		var query: PhysicsRayQueryParameters3D = \
			PhysicsRayQueryParameters3D.create(
				global_position + Vector3.UP * 1.2,
				target.global_position + Vector3.UP * target_height,
				1, [get_rid()])
		if space.intersect_ray(query).is_empty():
			return true
	return false


func _find_player() -> PlayerController:
	for node: Node in get_tree().get_nodes_in_group("player"):
		if node is PlayerController:
			return node as PlayerController
	return null


func _target_valid() -> bool:
	if _target == null or not is_instance_valid(_target):
		return false
	if _target.has_method("health"):
		var target_health: HealthComponent = _target.call("health") as HealthComponent
		if target_health != null and target_health.is_dead():
			return false
	return true


func _face(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.0001:
		return
	var target_yaw: float = atan2(direction.x, direction.z)
	var weight: float = 1.0 - exp(-tuning.turn_speed * delta)
	_pivot.rotation.y = lerp_angle(_pivot.rotation.y, target_yaw, weight)


## ---------------------------------------------------------------------------
## Tokens d'attaque (§12.8) — coordination par groupe, implicite en solo
## ---------------------------------------------------------------------------

## Sans coordinateur dans la scène : accordé d'office (duels, labos).
func _request_attack_token() -> bool:
	var coordinator: CombatCoordinator = _find_coordinator()
	if coordinator == null:
		return true
	return coordinator.request_token(self, _attack_token_kind())


func _release_attack_token() -> void:
	var coordinator: CombatCoordinator = _find_coordinator()
	if coordinator != null:
		coordinator.release_token(self)


## Les familles lourdes (colosse, chasseur) demanderont &"heavy".
func _attack_token_kind() -> StringName:
	return &"melee"


func _find_coordinator() -> CombatCoordinator:
	for node: Node in get_tree().get_nodes_in_group("combat_coordinator"):
		return node as CombatCoordinator
	return null


func direction_or_zero(direction: Vector3) -> Vector3:
	return direction.normalized() \
		if direction.length_squared() > 0.0001 else Vector3.ZERO


## Angle (degrés) entre le regard du pivot et une direction XZ.
func _facing_angle_deg(direction: Vector3) -> float:
	var forward: Vector3 = _pivot.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001 \
			or direction.length_squared() < 0.0001:
		return 180.0
	return rad_to_deg(forward.normalized().angle_to(direction.normalized()))


## ---------------------------------------------------------------------------
## Dégâts, stagger, mort (§12.10)
## ---------------------------------------------------------------------------

func _on_hit_received(event: DamageEvent) -> void:
	if _state == State.DEAD:
		return
	_flash_timer = 0.12
	# §10.2, enfin consommés : gel d'impact et recul viennent DES DONNÉES de
	# l'attaque, portées par l'événement — aucune constante locale inventée.
	_hitstop_timer = maxf(_hitstop_timer, event.hit_stop)
	if event.knockback > 0.0 and event.direction.length_squared() > 0.0001:
		var shove: Vector3 = Vector3(event.direction.x, 0.0, event.direction.z)
		_knockback_impulse = shove.normalized() * event.knockback
		_knockback_timer = KNOCKBACK_TIME
	_poise.take_poise_damage(event)
	# L'impact est un événement sonore (§12.7) : les voisins l'entendent.
	NoiseEvents.emit(get_tree(), global_position, NoiseEvents.IMPACT_RADIUS,
		&"impact")
	# Être frappé révèle l'attaquant, même hors du cône.
	if _target == null and event != null and is_instance_valid(event.instigator):
		var attacker: Node3D = event.instigator as Node3D
		if attacker != null and _state in [State.IDLE, State.PATROL,
				State.SUSPICIOUS, State.INVESTIGATE, State.RETURN]:
			# ISS-085 — deux issues, jamais une seule. Dans le territoire,
			# le coup acquiert comme avant. HORS du territoire,
			# `_acquire_target` refuse (garde ISS-083) et sortait SANS RIEN
			# FAIRE : il ne restait que le bruit d'impact que le garde
			# s'entend à lui-même, donc `_last_known` = sa propre position,
			# donc un `_face` sur le vecteur nul. Immobile, de dos, sous les
			# flèches. La riposte bornée remplace ce silence.
			if attacker.global_position.distance_to(_territory_origin) \
					<= tuning.max_pursuit_distance:
				_acquire_target(attacker)
			else:
				_riposte_bornee(attacker)


## ISS-085 — LA RIPOSTE D'UN GARDE QU'ON HARCÈLE DE TROP LOIN.
##
## Elle ne poursuit pas et ne prétend pas le faire : la borne de territoire
## (§12.9, ISS-083) gagne, et un archer patient reste hors d'atteinte. Ce qui
## change est ce que le joueur VOIT — le garde se tourne vers la menace,
## avance jusqu'au bord de son sol, et son voisinage a entendu l'impact.
##
## Le mécanisme est celui de la suspicion ordinaire, avec une DERNIÈRE
## POSITION honnête au lieu de la sienne propre : un point sur le rayon qui
## va de son poste vers l'agresseur, RAMENÉ à l'intérieur du territoire.
func _riposte_bornee(attacker: Node3D) -> void:
	var vers: Vector3 = attacker.global_position - _territory_origin
	vers.y = 0.0
	if vers.length() < 0.001:
		return
	# CODE MORT RETIRÉ (contre-revue) : un `minf(vers.length(), …)` prétendait
	# « jamais au-delà de l'agresseur ». Cette fonction n'est appelée QUE
	# lorsque l'agresseur est au-delà de `max_pursuit_distance` ; le minimum
	# choisissait donc toujours l'autre terme. Une garde qui ne peut pas
	# mordre se lit comme une garde, et c'est pire que pas de garde.
	var portee: float = tuning.max_pursuit_distance * AVANCE_TERRITOIRE
	_last_known = _territory_origin + vers.normalized() * portee
	_last_known.y = global_position.y
	# Posé APRÈS `NoiseEvents.emit` : ce bruit d'impact revient au garde
	# lui-même — `NoiseEvents.emit` n'exclut pas l'émetteur — et `hear_noise`
	# écrase `_last_known` avec sa propre position. L'ordre est le correctif.
	_enter(State.SUSPICIOUS)


func _on_poise_broken() -> void:
	if _state == State.DEAD:
		return
	_attack.cancel()
	_release_attack_token()
	_enter(State.STAGGERED)


func _on_died(_event: DamageEvent) -> void:
	_attack.cancel()
	_release_attack_token()
	_enter(State.DEAD)
	# TOUTES les hurtbox s'éteignent, pas seulement la principale : le
	# point faible dorsal du colosse restait frappable après sa mort
	# (§12.10, défaut mesuré par la batterie transverse du Gate D).
	for node: Node in find_children("*", "HurtboxComponent", true, false):
		(node as HurtboxComponent).set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	if not _model_mounted:
		_pivot.rotation.x = -1.45
	for i: int in range(_feedback_materials.size()):
		_feedback_materials[i].albedo_color = _feedback_bases[i].darkened(0.5)
		_feedback_materials[i].emission_enabled = false
	set_physics_process(false)
	# §12.1 : la mort d'un allié se voit — les familles proches décident.
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if node != self and node.has_method("witness_ally_death"):
			node.call("witness_ally_death", global_position)
	died.emit()


## ---------------------------------------------------------------------------
## Feedback matière — piloté par l'ÉTAT, jamais l'inverse (§10.6)
## ---------------------------------------------------------------------------

func _update_feedback(delta: float) -> void:
	if _feedback_materials.is_empty():
		return
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)
	var flash_on: bool = _flash_timer > 0.0
	var telegraphing: bool = _is_telegraphing()
	for i: int in range(_feedback_materials.size()):
		var material: BaseMaterial3D = _feedback_materials[i]
		if flash_on and not material.emission_enabled:
			material.emission_enabled = true
			material.emission = Color(1, 1, 1)
			material.emission_energy_multiplier = 1.6
		elif not flash_on and material.emission_enabled:
			material.emission_enabled = false
		if telegraphing:
			material.albedo_color = telegraph_color
		elif _state != State.DEAD:
			material.albedo_color = _feedback_bases[i]
	if _model_mounted:
		return
	if _state == State.STAGGERED:
		_pivot.rotation.x = 0.4
	elif _state != State.DEAD:
		_pivot.rotation.x = 0.0


## L'annonce par défaut : startup de l'attaque courante (« Recover » de
## §12.7 = phase RECOVERY du même contrat). Les familles élargissent.
func _is_telegraphing() -> bool:
	return _state == State.ATTACK \
		and _attack.phase() == AttackControllerComponent.Phase.STARTUP


func telegraph_materials() -> Array[BaseMaterial3D]:
	return _feedback_materials


## ---------------------------------------------------------------------------
## Plomberie d'état
## ---------------------------------------------------------------------------

func _enter(state: State) -> void:
	if _state == state:
		return
	_state = state
	_state_timer = 0.0
	state_changed.emit(state_name())


func state() -> State:
	return _state


func state_name() -> StringName:
	match _state:
		State.IDLE: return &"idle"
		State.PATROL: return &"patrol"
		State.SUSPICIOUS: return &"suspicious"
		State.INVESTIGATE: return &"investigate"
		State.CHASE: return &"chase"
		State.REPOSITION: return &"reposition"
		State.ATTACK: return &"attack"
		State.RETREAT: return &"retreat"
		State.STAGGERED: return &"staggered"
		State.FLEE: return &"flee"
		State.RETURN: return &"return"
		State.DEAD: return &"dead"
	return _family_state_name(_state)


## Conventions des cibles verrouillables et des tests.
func health() -> HealthComponent:
	return _health


func territory_origin() -> Vector3:
	return _territory_origin


func last_known_position() -> Vector3:
	return _last_known


## Sortie de combat PROPRE avant un gel par le plafond d'IA (§12.9) :
## l'attaque en cours est annulée — donc sa fenêtre de frappe fermée
## (§12.10) — et le token rendu à la file (§12.8). Sans cela, une IA
## gelée en pleine attaque garderait une hitbox armée et un token
## confisqué à jamais (défaut mesuré par la revue du Gate D).
func sleep_for_activity_cap() -> void:
	if _state == State.DEAD:
		return
	_attack.cancel()
	_release_attack_token()
	if _state == State.ATTACK:
		_enter(State.CHASE)


## Seam de test : forcer une fuite depuis une position donnée.
func start_flee(from_position: Vector3) -> void:
	_flee_from = from_position
	_enter(State.FLEE)
