## ISS-086 — L'AMBIANCE DE LA VALLÉE DOIT MOURIR AVEC LA VALLÉE.
##
## Ce que le moteur dit aujourd'hui, en fin de processus, dès qu'une suite monte
## `ValleyWorld.tscn` (mesuré au SHA 2cb48dd6, journal archivé sous
## `evidence/world_v2/iss086/etape1_attribution_2cb48dd6.log`) :
##
##     WARNING: 2 ObjectDB instances were leaked at exit
##     Leaked instance: AudioStreamPlaybackWAV:… - Reference count: 1
##     Leaked instance: AudioStreamWAV:… - Reference count: 1
##     Resource still in use: res://assets/audio/sfx/amb_valley.wav
##
## LA MÉCANIQUE, lue dans le code et non supposée. `ValleyWorld._ready()` demande
## `AudioManager.play_ambience(&"amb_valley")`. `AudioManager` est un AUTOLOAD :
## le lecteur `Ambience` qu'il crée est son propre enfant, pas celui de la
## vallée. La vallée disparaît, le lecteur reste, il joue toujours, et
## `AudioServer` conserve la lecture — donc la ressource. Rien dans
## `ValleyWorld._exit_tree()` ne reprend ce qu'il a demandé.
##
## CE QUE CE CONTRAT PEUT MESURER, ET CE QU'IL NE PEUT PAS.
## GDScript ne sait pas énumérer l'ObjectDB : la ligne « Leaked instance » n'est
## lisible que dans le rapport de SORTIE du moteur, donc hors de portée d'un test
## en cours de processus. Ce contrat mesure la CHAÎNE DE DÉTENTION que ce rapport
## nomme, à l'endroit exact où elle se forme :
##
##   « zéro AudioStreamPlaybackWAV »  ->  `has_stream_playback() == false` sur le
##       seul lecteur du projet qui en crée un pour cette ressource ;
##   « zéro amb_valley.wav survivante » -> `stream == null` sur ce même lecteur,
##       c'est-à-dire plus aucune référence depuis le graphe audio.
##
## Ce n'est pas un affaiblissement du critère : c'est le seul chaînon capable de
## retenir la ressource après la mort de la vallée, et c'est celui que le rapport
## de sortie désigne. Le rapport lui-même reste jugé par `PROJECT_RESOURCE_LEAK_GATE`
## et par la course `--verbose` — deux couches, deux prix, PROMPT4_METHOD §1.
##
## Les cinquante fichiers de test qui appellent `stop_ambience()` dans leur
## nettoyage ne sont pas la correction : ce sont les pansements que l'absence de
## correction a fait proliférer.
##
## Toutes les attentes sont bornées en TEMPS DE JEU et s'arrêtent au succès
## (ISS-038) : ce contrat n'exige jamais que la machine soit rapide.
extends GateTestCase

const VALLEY: String = "res://scenes/world/valley/ValleyWorld.tscn"
const MENU: String = "res://scenes/ui/MainMenu.tscn"
const BOOT: String = "res://scenes/boot/Boot.tscn"
## La ressource que le rapport de sortie nomme.
const AMB: String = "res://assets/audio/sfx/amb_valley.wav"
## Grâce accordée au lecteur pour s'arrêter, en temps de jeu. Ce n'est pas une
## tolérance sur le RÉSULTAT : l'assertion porte ensuite sur l'état mesuré, quoi
## qu'il arrive. C'est le délai au-delà duquel on cesse d'attendre.
const SILENCE_BUDGET_S: float = 3.0
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


## Vrai si le lecteur est réellement libéré : arrêté, sans lecture, sans flux.
func _libere() -> bool:
	var joueur: AudioStreamPlayer = _lecteur()
	if joueur == null:
		return true
	return not joueur.playing \
		and not joueur.has_stream_playback() \
		and joueur.stream == null


## Attend la libération, s'arrête dès qu'elle survient, et rend la main au budget.
func _attendre_liberation(budget_s: float = SILENCE_BUDGET_S) -> void:
	var ecoule: float = 0.0
	while ecoule <= budget_s:
		if _libere():
			return
		await _tree().process_frame
		ecoule += _tree().root.get_process_delta_time()


## Vrai si l'ambiance de la VALLÉE joue vraiment. Sert de contrôle de
## non-vacuité : sans lui, « plus rien ne joue » serait vrai même si la vallée
## n'avait jamais rien démarré, et le contrat serait vert pour rien.
func _ambiance_de_la_vallee_joue() -> bool:
	var joueur: AudioStreamPlayer = _lecteur()
	return joueur != null \
		and joueur.playing \
		and joueur.stream != null \
		and joueur.stream.resource_path == AMB


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
## de `stream = null` est un geste de TEST, pas la correction : la correction
## doit venir de la vallée, et c'est ce que les cas ci-dessous exigent.
func _rendre_le_silence() -> void:
	var audio: Node = _audio()
	if audio != null and audio.has_method("stop_ambience"):
		audio.call("stop_ambience")
	var joueur: AudioStreamPlayer = _lecteur()
	if joueur != null:
		joueur.stream = null
	await _settle(2)


## ---------------------------------------------------------------------------
## A/B/C — le VRAI chemin de transition, aller et retour
## ---------------------------------------------------------------------------
##
## Entrer : `SceneFlow.go_to(ValleyWorld)`, ce que fait le menu.
## Sortir : `SceneFlow.go_to(MainMenu)`, ce que fait `gameplay_shell.gd` quand le
## joueur retourne au menu. Aucun raccourci de test : les deux bouts sont ceux du
## jeu.
func test_quitter_la_vallee_arrete_et_libere_son_ambiance() -> void:
	remember_saves()
	remember_root()

	var boot: Node = (load(BOOT) as PackedScene).instantiate()
	_tree().root.add_child(boot)
	var au_menu: bool = await await_scene("MainMenu")
	check(au_menu, "A0 — le démarrage mène au menu principal")
	var flow: Node = _tree().root.get_node_or_null("/root/SceneFlow")
	check(flow != null, "A0b — SceneFlow est disponible")
	if not au_menu or flow == null:
		await restore_root()
		await _rendre_le_silence()
		restore_saves()
		return

	await await_flow_idle()
	flow.call("go_to", VALLEY)
	var dans_la_vallee: bool = await await_scene("ValleyWorld")
	check(dans_la_vallee, "A1 — SceneFlow charge la vallée par le vrai chemin")
	await _settle(8)

	# NON-VACUITÉ. Si l'ambiance n'avait jamais démarré, B et C seraient vrais
	# sans rien prouver.
	check(_ambiance_de_la_vallee_joue(),
		"A2 — la vallée montée, son ambiance JOUE vraiment (%s)" % _etat())

	await await_flow_idle()
	flow.call("go_to", MENU)
	var revenu_au_menu: bool = await await_scene("MainMenu")
	check(revenu_au_menu, "A3 — retour au menu par le vrai chemin de transition")
	# Attendre la fin EFFECTIVE du lecteur, pas un nombre de frames décrété.
	await _attendre_liberation()

	var joueur: AudioStreamPlayer = _lecteur()
	check(joueur == null or not joueur.playing,
		"B — la vallée partie, plus aucune ambiance ne joue (%s)" % _etat())
	check(joueur == null or not joueur.has_stream_playback(),
		"C1 — zéro lecture survivante : has_stream_playback() est faux (%s)" % _etat())
	check(joueur == null or joueur.stream == null,
		"C2 — zéro amb_valley.wav survivante : le graphe audio ne la référence "
		+ "plus (%s)" % _etat())

	var propre: bool = await restore_root()
	check(propre, "A4 — la racine est rendue telle qu'elle était (%s)"
		% restore_root_reason())
	_remettre_le_flux_a_zero()
	await _rendre_le_silence()
	restore_saves()


## ---------------------------------------------------------------------------
## D — trois montages et démontages successifs
## ---------------------------------------------------------------------------
##
## Une libération qui ne marche qu'une fois n'est pas une libération : un
## correctif qui consommerait un drapeau, ou qui libérerait le lecteur au lieu de
## le rendre, passerait le cycle 1 et échouerait au cycle 2. Chaque cycle porte
## SA propre non-vacuité — l'ambiance doit avoir redémarré avant qu'on exige
## qu'elle s'arrête.
func test_trois_cycles_ne_laissent_aucune_ambiance_derriere() -> void:
	remember_saves()
	remember_root()

	for cycle: int in range(1, CYCLES + 1):
		var monde: Node3D = await _monter_la_vallee()
		check(_ambiance_de_la_vallee_joue(),
			"D%d.1 — cycle %d : l'ambiance de la vallée joue (%s)"
			% [cycle, cycle, _etat()])
		await _demonter_la_vallee(monde)
		await _attendre_liberation()
		var joueur: AudioStreamPlayer = _lecteur()
		check(joueur == null or not joueur.playing,
			"D%d.2 — cycle %d : plus aucune ambiance ne joue (%s)"
			% [cycle, cycle, _etat()])
		check(joueur == null or not joueur.has_stream_playback(),
			"D%d.3 — cycle %d : zéro lecture survivante (%s)"
			% [cycle, cycle, _etat()])
		check(joueur == null or joueur.stream == null,
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
## défaut, il interdit la correction paresseuse. Un `stop_ambience()` global posé
## dans `ValleyWorld._exit_tree()` réglerait A/B/C/D et casserait ceci — parce
## qu'une vallée `queue_free()`ée sort de l'arbre en FIN de frame, donc après que
## la scène suivante a pu réclamer l'ambiance. Le silence tomberait sur le dos de
## la scène qui n'a rien demandé.
##
## Je ne peux pas vérifier l'ordre exact des opérations dans la source du moteur :
## elle n'est pas présente dans ce conteneur. C'est précisément pourquoi la
## correction ne doit pas REPOSER sur cet ordre. Ce cas construit le pire cas et
## exige qu'il tienne quand même.
func test_une_sortie_tardive_ne_coupe_pas_lambiance_suivante() -> void:
	remember_saves()
	remember_root()

	var monde: Node3D = await _monter_la_vallee()
	check(_ambiance_de_la_vallee_joue(),
		"E1 — la vallée tient l'ambiance avant sa sortie (%s)" % _etat())

	# La vallée part, mais TARD : `queue_free()` diffère sa sortie d'arbre à la
	# fin de la frame. Entre-temps, la scène suivante réclame l'ambiance —
	# ici depuis le test, faute d'une seconde scène qui en demande une.
	_tree().paused = false
	monde.queue_free()
	var audio: Node = _audio()
	check(audio != null, "E2 — AudioManager est disponible")
	if audio != null:
		audio.call("play_ambience", &"amb_valley")
	check(_ambiance_de_la_vallee_joue(),
		"E3 — la scène suivante a bien démarré son ambiance (%s)" % _etat())

	await _settle(4)
	# NON-VACUITÉ : si la vallée n'était pas réellement sortie, E5 serait vrai
	# sans rien prouver.
	check(not is_instance_valid(monde),
		"E4 — la vallée est réellement sortie de l'arbre APRÈS cette demande")
	check(_ambiance_de_la_vallee_joue(),
		"E5 — la sortie tardive de la vallée n'a PAS coupé l'ambiance de la "
		+ "scène suivante (%s)" % _etat())

	_remettre_le_flux_a_zero()
	var propre: bool = await restore_root()
	check(propre, "E6 — la racine est rendue telle qu'elle était (%s)"
		% restore_root_reason())
	await _rendre_le_silence()
	restore_saves()
