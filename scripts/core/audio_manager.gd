## Autoload — bus audio et volumes (MASTER_SPEC §18.1).
##
## Crée les bus au démarrage s'ils n'existent pas, plutôt que de dépendre d'un
## `default_bus_layout.tres` binaire : la configuration reste lisible en diff,
## vérifiable par un test, et reproductible sur une machine neuve.
##
## Portée à la Phase A : la **structure** des bus et le réglage des volumes. Les
## pools de lecture, la musique adaptative et les zones de réverbération (§18.4,
## §18.5) arrivent avec le contenu qu'ils doivent servir.
##
## Note d'environnement : le conteneur de développement n'a aucun périphérique
## audio (KNOWN_ISSUES ISS-004). Godot bascule sur le pilote muet ; la structure
## des bus reste créée et testable, mais **aucun mixage réel n'a été écouté**.
extends Node

## Ordre significatif : chaque bus est routé vers `Master`, sauf `Master` lui-même.
const BUSES: Array[String] = [
	"Master",
	"Music",
	"Ambience",
	"SFX",
	"UI",
	"Voice",
]

signal volume_changed(bus_name: String, linear: float)

## Sons courts du jeu (TESTS.md, bug 1 : « le jeu entier est muet »). Des
## placeholders GÉNÉRÉS par `tools/audio/make_placeholder_sfx.py` — leur rôle
## est qu'aucune action ne soit muette (§18.2), pas de sonner final. La
## variation de pitch (§18.2 : « aucun effet mitraillette ») est bornée ici.
const SFX_DIR: String = "res://assets/audio/sfx"
const SFX_PLAYERS: int = 8
const PITCH_JITTER: float = 0.07

var _sfx_streams: Dictionary = {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_next: int = 0
## Lecteur unique de la boucle d'ambiance — voir `play_ambience()`.
var _ambience: AudioStreamPlayer = null
## ISS-086 — QUI a demandé l'ambiance en cours. Une référence FAIBLE : un
## propriétaire mort cesse de correspondre au lieu de garder une prise.
##
## Ma justification d'origine — « un identifiant d'instance peut être réattribué
## après libération » — est FAUSSE en Godot 4 : `ObjectDB::add_instance` compose
## l'identifiant d'un emplacement ET d'un compteur de validation monotone, dont
## le bouclage est hors de portée d'un processus de jeu. Le `WeakRef` reste le
## bon choix parce qu'il exprime la non-propriété, pas parce qu'il éviterait une
## collision. Corrigé après lecture de `core/object/object.cpp`.
var _ambience_owner: WeakRef = null
## ISS-088 — CE QUI joue, déclaré par l'INTENTION du gestionnaire, jamais
## déduit d'une propriété de ressource : le flux joué est une copie sans
## chemin (voir `play_ambience`), et une identité lue sur `resource_path`
## casse dès que la copie joue ; l'égalité d'octets, elle, décrit un CONTENU,
## pas une demande. Posé par `play_ambience` à côté du propriétaire, VIDÉ par
## `_release_ambience` : une ambiance rendue n'a plus d'identité.
var _ambience_id: StringName = &""
## Dernier instant de lecture par identifiant. Le tour de rôle du pool est
## DESTRUCTIF : sans cette garde, un balayage qui touche trois cibles rejoue
## le même son trois fois dans la même frame, et huit pas coupent la mort.
var _last_played: Dictionary = {}
const SFX_MIN_INTERVAL: float = 0.045


func _ready() -> void:
	_ensure_buses()
	_build_sfx_pool()
	_restore_saved_volumes()


## Boucle d'AMBIANCE. Le gestionnaire ne savait jouer que des sons courts :
## rien, dans tout le projet, ne pouvait faire tourner un flux continu. Les
## dossiers `ambience/`, `music/` et `combat/` étaient vides et inatteignables.
## Le silence total entre deux actions est ce qui fait « projet non fini »
## plus sûrement que n'importe quel placeholder visuel.
##
## Un seul lecteur, réutilisé : deux ambiances ne se superposent jamais.
## ISS-086 — `owner` est la scène qui REVENDIQUE cette ambiance. Elle seule
## pourra la reprendre en partant (`stop_ambience_owned_by`).
##
## LE PARAMÈTRE EST OBLIGATOIRE, ET CE N'EST PAS UN DÉTAIL D'API. Sa première
## version le rendait facultatif « pour ne pas couper le son d'autrui » ; la
## revue adverse a montré que cela reconduisait la fuite d'ISS-086 par un chemin
## non couvert — une ambiance sans propriétaire est une ambiance que PERSONNE ne
## peut plus rendre. Qui démarre doit pouvoir rendre.
func play_ambience(sound: StringName, owner: Object) -> void:
	# LA SIGNATURE NE SUFFIT PAS. Le seul appelant de production passe par
	# `Object.call()`, où le typage ne protège rien : un `null` y entrerait sans
	# broncher et fabriquerait l'ambiance que personne ne peut plus rendre —
	# ISS-086 par un chemin non couvert. La contre-revue à contexte frais l'a
	# nommé, et elle avait raison : D-062 déclarait la règle, le code la
	# tolérait. Un `push_warning`, jamais un `push_error` : l'étape 2b de
	# `validate_fast` traite tout `ERROR:` du journal comme un échec.
	if owner == null:
		push_warning("[audio] play_ambience(%s) sans propriétaire : refusé. "
			% String(sound) + "Qui démarre une ambiance doit pouvoir la rendre.")
		return
	var stream: AudioStream = _sfx_stream(sound)
	# Son introuvable : rien ne démarre, donc rien à revendiquer, et le
	# propriétaire PRÉCÉDENT garde sa prise — c'est voulu, il est le seul à
	# pouvoir encore rendre ce qui joue. L'appelant, lui, n'apprend rien —
	# même discrétion que `play_sfx`, et elle se voit dans les tests — mais le
	# JOURNAL, si : `_sfx_stream` avertit une fois par nom (ISS-088).
	if stream == null:
		return
	# Les WAV générés ne portent pas de boucle : on la pose ici. `loop_end`
	# DOIT être renseigné — laissé à 0, le moteur arrête la lecture
	# immédiatement (audio_stream_wav.cpp:249).
	#
	# ISS-088 — DEUX FAUTES DANS LE MÊME GESTE, corrigées ensemble.
	# 1) La borne était `data.size() / 2` — « 16 bits mono : deux octets par
	#    échantillon ». Or chaque `.wav.import` du projet porte
	#    `compress/mode=2` : `data` contient des octets QOA COMPRESSÉS, et
	#    `loop_end` se compte en TRAMES par canal (`set_loop_end(int p_frame)`,
	#    audio_stream_wav.h:145 ; le bouclage rejoue à `offset >= loop_end`,
	#    cpp:307). Mesuré : amb_valley décodé fait 176 400 trames, son `data`
	#    QOA 71 408 octets — l'ambiance livrée REBOUCLAIT à 0,81 s d'un clip
	#    de 4,0 s. La borne juste vient de la durée DÉCODÉE : `get_length()`
	#    rend trames/mix_rate pour TOUS les formats, la branche QOA décodant
	#    l'en-tête au lieu de compter les octets (cpp:489-512). Et la borne
	#    est INCLUSIVE (troisième défaut, off-by-one mesuré par la
	#    contre-analyse) : le moteur lit jusqu'à `loop_end` COMPRIS
	#    (`aux = (limit - offset) / increment + 1`, cpp:344) — bornée au
	#    COMPTE, la lecture déborderait d'une trame à chaque tour. C'est la
	#    convention de l'importeur du moteur lui-même, qui pose `frames - 1`
	#    (sondé : 22049 sur une fixture de 22050 trames, 176399 sur
	#    amb_valley, 176400 trames).
	# 2) La mutation frappait l'exemplaire PARTAGÉ du cache (`_sfx_streams` +
	#    ResourceCache) que `play_sfx` réutilise. On boucle donc une COPIE.
	#    La copie reste SANS `resource_path` — non par danger : une repose par
	#    `set_path_cache()` serait inoffensive, car `~Resource()` ne désinscrit
	#    du ResourceCache que l'entrée qui pointe CE MÊME objet, et la copie
	#    n'y est pas inscrite (core/io/resource.cpp:790-802 ; mesuré, journal
	#    rouge_T3_contre_v1 : chemin reposé sans erreur ni dégât de cache) —
	#    mais parce qu'AUCUN contrat n'en a besoin : l'identité du flux joué
	#    est l'INTENTION déclarée ici, `_ambience_id`, exposée par
	#    `ambience_id()`. Contrat : tests/unit/test_ambience_loop_iss088.gd
	#    (T3 épingle le chemin vide, T4/T5 l'intention posée puis vidée).
	var wav: AudioStreamWAV = stream as AudioStreamWAV
	if wav != null and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		# DISPENSE STÉRÉO, assumée : `get_length()` porte déjà la division par
		# canal pour tous les formats — c'est précisément pourquoi la borne
		# passe par lui. Toute formule PAR FORMAT écrite ici rendrait une
		# fixture stéréo obligatoire pour l'épingler ; il n'y en a aucune, et
		# il n'y a aucune formule.
		var trames: int = roundi(wav.get_length() * wav.mix_rate)
		# Un flux vide garderait une borne 0 — le moteur couperait net : on ne
		# pose alors pas de boucle, le flux joue une fois comme avant
		# (contrat : cas Y, jamais de borne -1 sur un flux vide).
		if trames > 0:
			var copie: AudioStreamWAV = wav.duplicate() as AudioStreamWAV
			copie.loop_mode = AudioStreamWAV.LOOP_FORWARD
			copie.loop_begin = 0
			# La DERNIÈRE TRAME, incluse — pas le compte (borne inclusive,
			# voir le point 1 ci-dessus).
			copie.loop_end = trames - 1
			stream = copie
	if _ambience == null or not is_instance_valid(_ambience):
		_ambience = AudioStreamPlayer.new()
		_ambience.name = "Ambience"
		_ambience.bus = "Ambience"
		add_child(_ambience)
	_ambience.stream = stream
	_ambience.play()
	# APRÈS `play()`, et sur la dernière demande reçue : deux ambiances ne se
	# superposent jamais, donc la dernière voix est la seule propriétaire —
	# et la seule identité.
	_ambience_owner = weakref(owner) if owner != null else null
	_ambience_id = sound


## Arrêt GLOBAL, sans condition de propriétaire. Réservé aux appelants qui savent
## qu'ils parlent pour tout le monde : un nettoyage de test, une fin de partie.
## Une SCÈNE qui part ne doit PAS l'appeler — voir `stop_ambience_owned_by()`.
func stop_ambience() -> void:
	_release_ambience()


## ISS-086 — arrête et LIBÈRE l'ambiance, mais seulement si `owner` est bien
## celui qui l'a demandée. Rend vrai si l'arrêt a eu lieu.
##
## Sans cette condition de propriété, une scène qui sort TARD — `queue_free()`
## diffère la sortie d'arbre à la fin de la frame — couperait l'ambiance que la
## scène suivante vient de démarrer. Le contrat
## `tests/integration/test_ambience_ownership_iss086.gd` construit ce cas
## exact et l'interdit.
func stop_ambience_owned_by(owner: Object) -> bool:
	if owner == null or _ambience_owner == null:
		return false
	if _ambience_owner.get_ref() != owner:
		return false
	_release_ambience()
	return true


## ISS-086 — CE QUI FERME LA FUITE, ET CE QUI EST DE L'HYGIÈNE.
##
## Rectification : mon message de commit d'origine disait que `stop()` seul
## n'aurait pas suffi. C'est FAUX, et la source du moteur le dit.
## `AudioStreamPlayerInternal::stop_basic` vide `stream_playbacks`, mais
## `AudioServer::stop_playback_stream` ne libère rien — il pose l'état
## `FADE_OUT_TO_DELETION`, et le `unref` réel vit dans la lambda de
## `AudioServer::_delete_stream_playback_list_node`, déclenchée par un pas de
## mixage puis `AudioServer::_cleanup_lists`. Le porteur qui fuyait était donc
## `AudioServer::playback_list` → `AudioStreamPlaybackWAV::base`, pas le
## `stream` du lecteur : ce dernier meurt avec l'autoload, bien avant le
## comptage de fin de processus (le rapport le prouve — « Reference count: 1 »,
## et l'autoload absent de la liste).
##
## `stop()` FERME la fuite, pourvu qu'il coure assez tôt pour qu'un pas de
## mixage suive. `stream = null` est de l'hygiène : il rend tout de suite une
## référence qui serait morte plus tard, et rend l'état lisible par un test en
## cours de processus. Il est gardé pour cela, pas pour une cause qu'il n'a pas.
func _release_ambience() -> void:
	_ambience_owner = null
	_ambience_id = &""
	if _ambience == null or not is_instance_valid(_ambience):
		return
	_ambience.stop()
	_ambience.stream = null


func is_ambience_playing() -> bool:
	return _ambience != null and is_instance_valid(_ambience) and _ambience.playing


## ISS-088 — l'identité de l'ambiance en cours : le NOM demandé à
## `play_ambience`, `&""` quand rien n'a été demandé ou que tout est rendu.
## C'est l'identité que le contrat ISS-086 lit pour dire « la vallée joue » ;
## un son introuvable ne la touche pas (retour avant la pose), une libération
## la vide toujours.
func ambience_id() -> StringName:
	return _ambience_id


## Les volumes étaient ÉCRITS dans `settings.cfg` et relus uniquement pour
## peindre la position des curseurs — jamais pour régler les bus. Un joueur qui
## coupait la musique la retrouvait à fond au lancement suivant, avec un
## curseur affichant zéro : le réglage semblait cassé, et il l'était. La
## sensibilité souris et l'inversion, elles, étaient bien rechargées ; le son
## avait simplement été oublié.
func _restore_saved_volumes() -> void:
	for bus_name: String in ["Master", "Music", "SFX"]:
		if has_bus(bus_name):
			set_volume(bus_name, UserSettings.load_volume(bus_name))


## Joue un son court par nom (`hit_land`, `refuse`, `ui_move`, …).
## Sans effet si le fichier n'existe pas : un son manquant ne doit jamais
## casser une action de gameplay — il se voit dans les tests, et depuis
## ISS-088 il se voit aussi dans le JOURNAL (`_sfx_stream` avertit une fois
## par nom : dans une build exportée, c'est la seule trace qu'un asset
## manque au PCK).
func play_sfx(sound: StringName, bus: String = "SFX") -> void:
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	var previous: float = float(_last_played.get(sound, -1.0))
	if previous >= 0.0 and now - previous < SFX_MIN_INTERVAL:
		return
	_last_played[sound] = now
	var stream: AudioStream = _sfx_stream(sound)
	if stream == null:
		return
	var player: AudioStreamPlayer = _sfx_pool[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_pool.size()
	player.bus = bus if has_bus(bus) else "Master"
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-PITCH_JITTER, PITCH_JITTER)
	player.play()


func has_sfx(sound: StringName) -> bool:
	return _sfx_stream(sound) != null


func _sfx_stream(sound: StringName) -> AudioStream:
	if _sfx_streams.has(sound):
		return _sfx_streams[sound] as AudioStream
	var path: String = "%s/%s.wav" % [SFX_DIR, String(sound)]
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	else:
		# ISS-088 (audit export) — le gameplay reste inoffensif, mais le
		# JOURNAL apprend : aucun portail d'export ne peut « entendre », et un
		# asset audio absent du PCK était invisible de tous les balayages. Un
		# `push_warning`, jamais `push_error` (l'étape 2b de validate_fast
		# traite tout `ERROR:` comme un échec — même règle que le refus de
		# propriétaire nul). Le cache négatif ci-dessous borne le bruit : une
		# seule ligne par nom et par processus.
		push_warning("[audio] son introuvable : %s" % path)
	_sfx_streams[sound] = stream
	return stream


func _build_sfx_pool() -> void:
	for i: int in range(SFX_PLAYERS):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxVoice%d" % i
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)


func _ensure_buses() -> void:
	for bus_name: String in BUSES:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		var index: int = AudioServer.get_bus_count()
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")


func has_bus(bus_name: String) -> bool:
	return AudioServer.get_bus_index(bus_name) != -1


## Volume en échelle **linéaire** (0.0 à 1.0) : c'est ce qu'attend une option de
## menu. La conversion en décibels est faite ici, une fois, plutôt que dispersée
## dans l'interface.
func set_volume(bus_name: String, linear: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index == -1:
		push_error("[audio] bus inconnu : %s" % bus_name)
		return
	var clamped: float = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(clamped) if clamped > 0.0 else -80.0)
	AudioServer.set_bus_mute(index, clamped <= 0.0)
	volume_changed.emit(bus_name, clamped)


func get_volume(bus_name: String) -> float:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index == -1:
		return 0.0
	if AudioServer.is_bus_mute(index):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(index)), 0.0, 1.0)
