## ISS-086 — L'AMBIANCE DE LA VALLÉE DOIT MOURIR AVEC LA VALLÉE.
##
## Ce que le moteur dit en fin de processus dès qu'une suite monte
## `ValleyWorld.tscn` sans rien reprendre (mesuré au SHA 2cb48dd6, journal
## `evidence/world_v2/iss086/etape1_attribution_2cb48dd6.log`) :
##
##     WARNING: 2 ObjectDB instances were leaked at exit
##     Leaked instance: AudioStreamPlaybackWAV:… - Reference count: 1
##     Leaked instance: AudioStreamWAV:… - Reference count: 1
##     Resource still in use: res://assets/audio/sfx/amb_valley.wav
##
## LA MÉCANIQUE, LUE DANS LA SOURCE DU MOTEUR, présente dans ce conteneur
## (`/opt/src/godot`, tag `4.7.1-stable`) — et ma première rédaction de ce
## fichier se trompait sur ce point, il faut le dire :
##
##   `AudioStreamPlayerInternal::stop_basic` vide `stream_playbacks` de façon
##   synchrone, mais `AudioServer::stop_playback_stream` ne libère RIEN : il
##   pose l'état `FADE_OUT_TO_DELETION`. Le `unref` réel vit dans la lambda de
##   `AudioServer::_delete_stream_playback_list_node`, déclenchée par un pas de
##   mixage puis par `AudioServer::_cleanup_lists`. Le porteur qui fuit est donc
##   `AudioServer::playback_list` → `AudioStreamPlaybackWAV::base`, un
##   `Ref<AudioStreamWAV>` : exactement le couple de deux objets du rapport.
##
##   Conséquence honnête : `stop()` SEUL suffit à fermer la fuite, pourvu qu'il
##   soit appelé assez tôt pour qu'un pas de mixage suive. Le `stream = null`
##   du correctif est de l'hygiène — il rend une référence qui serait morte avec
##   le lecteur — pas la moitié porteuse.
##
## CE QUE CE CONTRAT MESURE, ET CE QU'IL NE PEUT PAS MESURER.
## GDScript ne sait pas énumérer l'ObjectDB : la ligne « Leaked instance »
## n'existe que dans le rapport de SORTIE du moteur. Ce contrat mesure donc
## l'état du LECTEUR — arrêté, sans lecture, sans flux — c'est-à-dire la
## condition à l'endroit où elle se décide, pas le résidu lui-même.
##
## ET IL FAUT DIRE POURQUOI CE PROXY EST NÉCESSAIRE PLUTÔT QUE CONFORTABLE :
## quatorze fichiers de la suite appellent `stop_ambience()` dans leur
## nettoyage, et `tests/unit/test_audio_sfx.gd` balaie même TOUS les lecteurs
## enfants de l'autoload. La suite complète efface donc en partie sa propre
## trace de sortie. Le contrôle apparié qui juge le rapport est la course
## `--filter=phase_e_chain --verbose` — le reproducteur exact de l'étape 1 —
## rejouée sur l'arbre corrigé, plus `tools/gate_fuite_composition.sh`.
##
## Toutes les attentes sont bornées en TEMPS DE JEU et s'arrêtent au succès
## (ISS-038) : ce contrat n'exige jamais que la machine soit rapide.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const MENU: String = "res://scenes/ui/MainMenu.tscn"
const BOOT: String = "res://scenes/boot/Boot.tscn"
## La ressource que le rapport de sortie nomme.
const AMB: String = "res://assets/audio/sfx/amb_valley.wav"
## Grâce accordée, en temps de jeu. Ce n'est pas une tolérance sur le RÉSULTAT :
## l'assertion re-mesure ensuite, quoi qu'il arrive. C'est le délai au-delà
## duquel on cesse d'attendre.
const BUDGET_S: float = 3.0
const CYCLES: int = 3


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


func _audio() -> Node:
	return _tree().root.get_node_or_null("/root/AudioManager")


## Le lecteur d'ambiance est un enfant de l'AUTOLOAD, nommé par
## `AudioManager.play_ambience()`. C'est tout le problème : il survit à la scène
## qui l'a demandé.
func _lecteur() -> AudioStreamPlayer:
	var audio: Node = _audio()
	if audio == null:
		return null
	return audio.get_node_or_null("Ambience") as AudioStreamPlayer


## Décrit l'état mesuré dans le message d'échec. Un verdict qui dit seulement
## « faux » envoie chercher la panne au mauvais endroit.
func _etat() -> String:
	var joueur: AudioStreamPlayer = _lecteur()
	if joueur == null:
		return "aucun lecteur d'ambiance"
	var flux: String = "null"
	if joueur.stream != null:
		flux = joueur.stream.resource_path
		if flux.is_empty():
			flux = "<ressource sans chemin>"
	return "playing=%s, stream=%s, playback=%s" \
		% [joueur.playing, flux, joueur.has_stream_playback()]


func _libere() -> bool:
	var joueur: AudioStreamPlayer = _lecteur()
	if joueur == null:
		return true
	return not joueur.playing \
		and not joueur.has_stream_playback() \
		and joueur.stream == null


func _attendre_liberation() -> void:
	var ecoule: float = 0.0
	while ecoule <= BUDGET_S:
		if _libere():
			return
		await _tree().process_frame
		ecoule += _tree().root.get_process_delta_time()


func _ambiance_de_la_vallee_joue() -> bool:
	var joueur: AudioStreamPlayer = _lecteur()
	return joueur != null \
		and joueur.playing \
		and joueur.stream != null \
		and joueur.stream.resource_path == AMB


## `playing` est FAUX pendant toute pause de l'arbre — `SceneFlow.go_to()` met
## `paused = true` le temps de la transition, et `await_scene()` rend la main
## dès que le nœud paraît, donc possiblement avant la remise en marche. Lire
## `playing` sans attente produirait un rouge qui n'est pas le défaut, sur une
## machine lente. Trouvé par l'audit de couverture, pas par moi.
func _attendre_lecture() -> void:
	var ecoule: float = 0.0
	while ecoule <= BUDGET_S:
		if _ambiance_de_la_vallee_joue():
			return
		await _tree().process_frame
		ecoule += _tree().root.get_process_delta_time()


## LA BOUCLE EST PORTEUSE, et elle n'est pas dans l'asset.
## `amb_valley.wav.import` porte `edit/loop_mode=0` et le clip dure ~4,0 s. La
## seule chose qui l'empêche de finir toute seule est une ligne DU CODE SOUS
## TEST (`play_ambience` force `LOOP_FORWARD`). Sans cette assertion, le temps
## d'une transition dépasse 4 s, le flux finirait naturellement, et « plus rien
## ne joue » deviendrait vrai alors que la fuite persiste.
func _la_boucle_est_posee() -> bool:
	var joueur: AudioStreamPlayer = _lecteur()
	if joueur == null:
		return false
	var wav: AudioStreamWAV = joueur.stream as AudioStreamWAV
	return wav != null and wav.loop_mode != AudioStreamWAV.LOOP_DISABLED


func _monter_la_vallee() -> Node3D:
	var monde: Node3D = (load(VALLEY) as PackedScene).instantiate() as Node3D
	_tree().root.add_child(monde)
	await _settle(6)
	return monde


func _demonter_la_vallee(monde: Node3D) -> void:
	_tree().paused = false
	monde.get_parent().remove_child(monde)
	monde.queue_free()
	await _settle(2)


func _remettre_le_flux_a_zero() -> void:
	var etat: Node = _tree().root.get_node_or_null("/root/GameState")
	if etat != null:
		etat.call("set_flow", 0)
		etat.call("consume_pending_spawn")


## UN TEST REND LE PROCESSUS TEL QU'IL L'A TROUVÉ. Sans ce nettoyage, ce
## fichier-ci fabriquerait exactement la fuite qu'il dénonce. L'écriture directe
## de `stream = null` est un geste de TEST, pas la correction.
func _rendre_le_silence() -> void:
	var audio: Node = _audio()
	if audio != null and audio.has_method("stop_ambience"):
		audio.call("stop_ambience")
	var joueur: AudioStreamPlayer = _lecteur()
	if joueur != null:
		joueur.stream = null
	await _settle(2)


func _cloturer() -> void:
	_remettre_le_flux_a_zero()
	await restore_root()
	await _rendre_le_silence()
	restore_saves()


## ---------------------------------------------------------------------------
## A/B/C — le VRAI chemin de transition, aller et retour
## ---------------------------------------------------------------------------
##
## Entrer : `SceneFlow.go_to(ValleyWorld)`, ce que fait le menu.
## Sortir : `SceneFlow.go_to(MainMenu)`, ce que fait `gameplay_shell.gd` quand
## le joueur retourne au menu. Aucun raccourci de test.
##
## Les préconditions (menu atteint, `SceneFlow` présent) ne sont PAS des
## assertions : ce sont des autoloads et un flux dont l'absence rougirait
## ailleurs de toute façon, et une assertion qui ne peut pas échouer seule
## gonfle le compte sans rien prouver. Elles sortent, elles n'affirment pas.
func test_quitter_la_vallee_arrete_et_libere_son_ambiance() -> void:
	remember_saves()
	remember_root()

	var boot: Node = (load(BOOT) as PackedScene).instantiate()
	_tree().root.add_child(boot)
	var flow: Node = _tree().root.get_node_or_null("/root/SceneFlow")
	if not await await_scene("MainMenu") or flow == null:
		check(false, "A0 — préparation impossible : menu ou SceneFlow absent")
		await _cloturer()
		return

	await await_flow_idle()
	flow.call("go_to", VALLEY)
	var dans_la_vallee: bool = await await_scene("ValleyWorld")
	check(dans_la_vallee, "A1 — SceneFlow charge la vallée par le vrai chemin")
	await _settle(8)
	await _attendre_lecture()

	# NON-VACUITÉS BLOQUANTES. Si l'ambiance n'avait pas démarré, B et C
	# seraient vrais sans rien prouver — et un simple `check()` les laisserait
	# courir et compter des verts trompeurs à côté du rouge.
	var joue: bool = _ambiance_de_la_vallee_joue()
	check(joue, "A2 — la vallée montée, son ambiance JOUE vraiment (%s)" % _etat())
	var boucle: bool = _la_boucle_est_posee()
	check(boucle, "A2b — le flux BOUCLE : sa fin naturelle (~4 s) ne pourra pas "
		+ "passer pour une libération (%s)" % _etat())
	if not joue or not boucle:
		await _cloturer()
		return

	await await_flow_idle()
	flow.call("go_to", MENU)
	var revenu: bool = await await_scene("MainMenu")
	check(revenu, "A3 — retour au menu par le vrai chemin de transition")
	# Attendre la fin EFFECTIVE du lecteur, pas un nombre de frames décrété.
	await _attendre_liberation()

	var joueur: AudioStreamPlayer = _lecteur()
	check(joueur != null and not joueur.playing,
		"B — la vallée partie, plus aucune ambiance ne joue (%s)" % _etat())
	check(joueur != null and not joueur.has_stream_playback(),
		"C1 — zéro lecture survivante : has_stream_playback() est faux (%s)" % _etat())
	check(joueur != null and joueur.stream == null,
		"C2 — zéro amb_valley.wav survivante : le graphe audio ne la référence "
		+ "plus (%s)" % _etat())

	_remettre_le_flux_a_zero()
	var propre: bool = await restore_root()
	check(propre, "A4 — la racine est rendue telle qu'elle était (%s)"
		% restore_root_reason())
	await _rendre_le_silence()
	restore_saves()


## ---------------------------------------------------------------------------
## D — trois montages et démontages successifs
## ---------------------------------------------------------------------------
##
## Une libération qui ne marche qu'une fois n'est pas une libération : un
## correctif qui consommerait un drapeau, ou qui libérerait le lecteur au lieu
## de le rendre, passerait le cycle 1 et échouerait au cycle 2. Chaque cycle
## porte SA propre non-vacuité, et elle est BLOQUANTE.
func test_trois_cycles_ne_laissent_aucune_ambiance_derriere() -> void:
	remember_saves()
	remember_root()

	for cycle: int in range(1, CYCLES + 1):
		var monde: Node3D = await _monter_la_vallee()
		await _attendre_lecture()
		var joue: bool = _ambiance_de_la_vallee_joue() and _la_boucle_est_posee()
		check(joue, "D%d.1 — cycle %d : l'ambiance de la vallée joue et boucle (%s)"
			% [cycle, cycle, _etat()])
		if not joue:
			await _demonter_la_vallee(monde)
			await _cloturer()
			return
		await _demonter_la_vallee(monde)
		await _attendre_liberation()
		var joueur: AudioStreamPlayer = _lecteur()
		check(joueur != null and not joueur.playing,
			"D%d.2 — cycle %d : plus aucune ambiance ne joue (%s)"
			% [cycle, cycle, _etat()])
		check(joueur != null and not joueur.has_stream_playback(),
			"D%d.3 — cycle %d : zéro lecture survivante (%s)"
			% [cycle, cycle, _etat()])
		check(joueur != null and joueur.stream == null,
			"D%d.4 — cycle %d : zéro ressource survivante (%s)"
			% [cycle, cycle, _etat()])
		_remettre_le_flux_a_zero()

	var propre: bool = await restore_root()
	check(propre, "D5 — la racine est rendue telle qu'elle était (%s)"
		% restore_root_reason())
	await _rendre_le_silence()
	restore_saves()


## ---------------------------------------------------------------------------
## E — CONTRÔLE NÉGATIF DU CORRECTIF : la sortie tardive ne coupe rien
## ---------------------------------------------------------------------------
##
## Ce cas ne rougit PAS avant la correction, et c'est voulu : il n'accuse pas le
## défaut, il interdit la correction paresseuse. Un `stop_ambience()` global
## posé dans `ValleyWorld._exit_tree()` réglerait A/B/C/D et casserait ceci.
##
## L'ORDRE DU MOTEUR EST LU, PAS SUPPOSÉ. `SceneTree::change_scene_to_node`
## retire la scène courante de façon SYNCHRONE, et `SceneTree::_flush_scene_change`
## n'ajoute la suivante qu'à la frame de traitement d'après : sur le chemin
## `SceneFlow`, `_exit_tree()` de l'ancienne précède TOUJOURS `_ready()` de la
## nouvelle, et un arrêt global y serait sans danger.
##
## Ce cas juge l'autre chemin : `queue_free()`, qui diffère la sortie d'arbre à
## la fin de la frame. C'est celui du harnais — `GateTestCase.restore_root()`
## restaure la racine, puis `_sweep()` libère les restes — et celui du jeu le
## jour où une seconde scène démarrera une ambiance (voir ISS-087 : il n'y en a
## aujourd'hui aucune). Mesuré par ablation, pas déduit : avec un arrêt global,
## `E4` rougit en `playing=false, stream=null`.
##
## La scène suivante réclame AVEC SON PROPRE PROPRIÉTAIRE, et pas anonymement :
## c'est le cas réaliste, et c'est le seul qui exerce la branche discriminante
## `get_ref() != owner`. Une implémentation qui comparerait des classes ou des
## noms passerait un contrôle anonyme sans être juste.
func test_une_sortie_tardive_ne_coupe_pas_lambiance_suivante() -> void:
	remember_saves()
	remember_root()

	var audio: Node = _audio()
	if audio == null or not audio.has_method("stop_ambience_owned_by"):
		check(false, "E0 — AudioManager n'expose pas l'arrêt par propriétaire")
		await _cloturer()
		return

	var monde: Node3D = await _monter_la_vallee()
	await _attendre_lecture()
	var joue: bool = _ambiance_de_la_vallee_joue()
	check(joue, "E1 — la vallée tient l'ambiance avant sa sortie (%s)" % _etat())
	if not joue:
		await _demonter_la_vallee(monde)
		await _cloturer()
		return

	# La scène suivante, incarnée par un nœud à elle. Elle réclame l'ambiance
	# pendant que la vallée est déjà condamnée mais pas encore sortie :
	# `queue_free()` diffère sa sortie d'arbre à la fin de la frame.
	var suivante: Node = Node.new()
	suivante.name = "SceneSuivante"
	_tree().root.add_child(suivante)
	_tree().paused = false
	monde.queue_free()
	audio.call("play_ambience", &"amb_valley", suivante)

	# ASSERTION DISCRIMINANTE : la propriété a bel et bien changé de mains.
	# `stop_ambience_owned_by` rend faux et n'arrête rien quand l'appelant
	# n'est plus propriétaire — c'est la branche que ce cas doit exercer.
	check(not bool(audio.call("stop_ambience_owned_by", monde)),
		"E2 — la vallée n'est PLUS propriétaire : son arrêt par propriété est "
		+ "refusé (%s)" % _etat())

	await _settle(4)
	# NON-VACUITÉ : si la vallée n'était pas réellement sortie, E4 serait vrai
	# sans rien prouver.
	check(not is_instance_valid(monde),
		"E3 — la vallée est réellement sortie de l'arbre APRÈS cette demande")
	check(_ambiance_de_la_vallee_joue(),
		"E4 — la sortie tardive de la vallée n'a PAS coupé l'ambiance de la "
		+ "scène suivante (%s)" % _etat())

	suivante.queue_free()
	_remettre_le_flux_a_zero()
	var propre: bool = await restore_root()
	check(propre, "E5 — la racine est rendue telle qu'elle était (%s)"
		% restore_root_reason())
	await _rendre_le_silence()
	restore_saves()
