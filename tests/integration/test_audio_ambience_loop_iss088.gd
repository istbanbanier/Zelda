## ISS-088 — LA BORNE DE BOUCLE DE L'AMBIANCE SE COMPTE EN TRAMES, PAS EN OCTETS.
##
## CE QUE LE DÉFAUT FAISAIT, mesuré et non déduit. `play_ambience` posait
## `wav.loop_end = wav.data.size() / 2` sous le commentaire « 16 bits mono :
## deux octets par échantillon ». Ce commentaire décrit le fichier SOURCE.
## `assets/audio/sfx/amb_valley.wav.import` porte `compress/mode=2`, que
## `resource_importer_wav.cpp` énumère « PCM (Uncompressed), IMA ADPCM, Quite OK
## Audio » : la ressource importée contient des octets QOA, à débit variable.
## `data.size()` y vaut 71408 pour 176400 trames — la borne tombait à 35704, et
## l'ambiance rebouclait sur ses 0,8096 premières secondes d'un clip de 4,00 s.
##
## POURQUOI AUCUN FILET EXISTANT NE L'ATTRAPAIT. `loop_end`, `get_length` et
## `get_playback_position` n'apparaissaient NULLE PART dans `tests/`. La seule
## assertion de boucle du dépôt, `_la_boucle_est_posee()` du contrat ISS-086,
## lit `loop_mode != LOOP_DISABLED` — vraie avec une borne fausse. Ce fichier
## est donc le premier filet de cet axe.
##
## LE PIÈGE D'ORDRE, ET POURQUOI CE FICHIER LE NEUTRALISE EXPLICITEMENT.
## `tools/godot/test_runner.gd` trie les chemins `res://` complets, donc
## `…/test_ambience_ownership_iss086.gd` court AVANT ce fichier, et il joue
## l'ambiance. Tant que `play_ambience` mutait l'exemplaire PARTAGÉ, sa garde
## `loop_mode == LOOP_DISABLED` était fausse pour tous les appels suivants du
## processus : une assertion posée ici aurait mesuré un état produit par un
## AUTRE fichier, et serait restée verte même sans correctif. Le cas B remet
## donc `loop_mode` à `LOOP_DISABLED` sur l'exemplaire du cache avant de
## mesurer, et le dit dans son message.
##
## CE QUE LE CAS C N'EXIGE PAS. `AudioDriverDummy` mixe réellement
## (`use_threads = true`, son `thread_func` appelle `audio_server_process`),
## donc la position de lecture avance en headless. Mais son `thread_func` fait
## `delay_usec(buffer_frames / mix_rate)` SANS compenser le temps de traitement :
## il est structurellement plus lent que le temps réel. Le cas C sort donc de sa
## boucle DÈS que le recul est observé. Son plafond reste néanmoins un budget,
## et la contre-revue a eu raison de refuser la formule « jamais un budget de
## vitesse » : si le bouclage n'est pas vu en 25 s, `C3` rougit. La machine doit
## donc jouer 4,00 s d'audio en moins de 25 s de temps mur — un facteur 6 de
## marge, confortable mais pas infini. `C4`, l'assertion discriminante, n'a
## elle besoin que d'atteindre 1,10 s : c'est `C3` et `C5` qui achètent le
## reste du temps, et donc le risque d'intermittence (ISS-038).
extends GateTestCase

const AMB: String = "res://assets/audio/sfx/amb_valley.wav"

## Mesurés hors moteur par `python3 tools/gltf_inspect.py`-style sur l'en-tête
## QOA du `.sample` importé, et recoupés par `AudioStreamWAV::get_length`.
const AMB_TRAMES: int = 176400
const AMB_LOOP_END: int = 176399
const AMB_DUREE_S: float = 4.0
## Ce que l'ancienne formule rendait. Épinglé pour que le rouge soit lisible.
const ANCIENNE_BORNE: int = 35704

## Garde d'anti-blocage, PAS un budget : le cas C sort dès qu'il a vu le recul.
const ANTIHANG_S: float = 25.0
## Un recul de position ne peut venir que du bouclage : `_mix_internal` ne fait
## reculer `offset` que dans `if (loop_format != LOOP_DISABLED && offset >= loop_end)`.
const RECUL_MIN_S: float = 0.05
## Entre 0,8096 s (le défaut) et 4,00 s (la vérité). Un recul avant ce seuil
## prouve une borne trop petite.
const SEUIL_PRECOCE_S: float = 1.10


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _audio() -> Node:
	var t: SceneTree = _tree()
	if t == null:
		return null
	return t.root.get_node_or_null("AudioManager")


func _lecteur() -> AudioStreamPlayer:
	var a: Node = _audio()
	if a == null:
		return null
	return a.get_node_or_null("Ambience") as AudioStreamPlayer


## Un WAV construit ICI : ni cache, ni import, ni ordre d'exécution. C'est ce
## qui rend le cas A insensible à tout ce que les autres fichiers ont pu faire.
func _wav_synthetique(trames: int) -> AudioStreamWAV:
	var w: AudioStreamWAV = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 44100
	w.stereo = false
	var octets: PackedByteArray = PackedByteArray()
	octets.resize(trames * 2)
	w.data = octets
	return w


func _rendre_le_silence() -> void:
	var a: Node = _audio()
	if a != null and a.has_method("stop_ambience"):
		a.call("stop_ambience")
	var j: AudioStreamPlayer = _lecteur()
	if j != null:
		j.stream = null
	# Recyclage ASYNCHRONE : `stop_playback_stream` ne pose que
	# `FADE_OUT_TO_DELETION` ; le `unref` attend un pas de mixage réel.
	var depart: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - depart < 400:
		await _tree().process_frame


# ── A ─ la formule, hors moteur, hors cache, hors ordre ────────────────────────
func test_la_borne_de_boucle_se_compte_en_trames_pas_en_octets() -> void:
	var a: Node = _audio()
	if a == null:
		check(false, "A0 : AudioManager absent, rien à mesurer")
		return
	check(a.has_method("loop_end_frame"), "A1 : `loop_end_frame()` est exposée")
	# GARDE DE SORTIE, ajoutée après contre-revue. Sans elle, `A3` appelait une
	# méthode inexistante sous ablation : GDScript avortait la méthode, `A4` à
	# `A8` n'étaient JAMAIS exécutées, et le runner ajoutait une ligne
	# `SCRIPT ERROR` au décompte. Le rouge de ce cas était donc « la méthode
	# n'existe pas », pas « la borne est fausse » — et `A6`, la seule assertion
	# qui oppose la production à la vraie ressource QOA, n'avait jamais été
	# observée rouge.
	if not a.has_method("loop_end_frame"):
		return

	# Un clip dont on connaît le compte de trames par construction.
	var w: AudioStreamWAV = _wav_synthetique(12345)
	check_approx(w.get_length(), 12345.0 / 44100.0, 0.0001,
		"A2 : le moteur rend bien la durée attendue pour le WAV construit ici")
	check_equal(a.call("loop_end_frame", w), 12344,
		"A3 : la borne est le DERNIER INDICE de trame, donc trames - 1")

	# La preuve que l'unité a changé : sur un 16 bits PCM, octets = 2 × trames,
	# donc l'ancienne formule tombait juste PAR ACCIDENT. Elle ne pouvait pas
	# tomber juste sur du QOA, où `data` n'a aucun rapport avec les trames.
	check_equal(w.data.size() / 2, 12345,
		"A4 : sur du PCM 16 bits, data.size()/2 vaut le compte de trames — "
		+ "c'est ce hasard qui a masqué le défaut jusqu'à l'import QOA")

	# La ressource réelle du jeu, elle, est QOA : le hasard n'y joue plus.
	var reelle: AudioStreamWAV = load(AMB) as AudioStreamWAV
	check_not_null(reelle, "A5 : `amb_valley` se charge")
	if reelle == null:
		return
	check_equal(a.call("loop_end_frame", reelle), AMB_LOOP_END,
		"A6 : sur la ressource IMPORTÉE, la borne juste vaut %d" % AMB_LOOP_END)
	check(reelle.data.size() / 2 != AMB_LOOP_END,
		"A7 : et l'ancienne formule en est LOIN — data.size()/2 = %d contre %d"
		% [reelle.data.size() / 2, AMB_LOOP_END])
	check_equal(reelle.data.size() / 2, ANCIENNE_BORNE,
		"A8 : la valeur exacte que le défaut posait, épinglée pour mémoire")


# ── B ─ le cache partagé n'est pas contaminé, et l'acquis ISS-086 tient ────────
func test_le_cache_partage_reste_intact_et_lambiance_a_sa_copie() -> void:
	var a: Node = _audio()
	if a == null:
		check(false, "B0 : AudioManager absent")
		return
	await _rendre_le_silence()

	var partage: AudioStreamWAV = load(AMB) as AudioStreamWAV
	check_not_null(partage, "B1 : l'exemplaire partagé du cache se charge")
	if partage == null:
		return
	# NEUTRALISATION DU PIÈGE D'ORDRE : un fichier trié plus tôt a pu jouer
	# cette ambiance et, AVANT correctif, muter cet exemplaire. On repart d'un
	# état connu pour mesurer ce que fait CE fichier, pas ce qu'un autre a laissé.
	partage.loop_mode = AudioStreamWAV.LOOP_DISABLED
	partage.loop_begin = 0
	partage.loop_end = 0

	var proprio: Node = Node.new()
	proprio.name = "ProprietaireDeTest"
	_tree().root.add_child(proprio)
	a.call("play_ambience", &"amb_valley", proprio)
	await _tree().process_frame

	var joueur: AudioStreamPlayer = _lecteur()
	check_not_null(joueur, "B2 : le lecteur d'ambiance existe")
	var joue: AudioStreamWAV = null
	if joueur != null:
		joue = joueur.stream as AudioStreamWAV
	check_not_null(joue, "B3 : et il porte bien un AudioStreamWAV")

	if joue != null:
		check(joue != partage,
			"B4 : le flux JOUÉ n'est pas l'exemplaire du cache — c'est une copie")
		check_equal(joue.loop_mode, AudioStreamWAV.LOOP_FORWARD,
			"B5 : la copie boucle")
		check_equal(joue.loop_end, AMB_LOOP_END,
			"B6 : et sa borne est en trames, pas en octets")
		# L'acquis ISS-086 : le contrat de propriété identifie l'ambiance par son
		# chemin. Une copie anonyme l'aurait rendu rouge.
		check_equal(joue.resource_path, AMB,
			"B7 : la copie porte le chemin de l'asset (acquis ISS-086)")

	# LA MÉMORISATION, épinglée après contre-revue. Sans cette assertion, retirer
	# `_ambience_streams` — donc re-dupliquer ~143 ko à CHAQUE appel — laissait
	# la totalité du contrat verte. Un second appel doit rendre le MÊME objet.
	a.call("play_ambience", &"amb_valley", proprio)
	await _tree().process_frame
	var joueur2: AudioStreamPlayer = _lecteur()
	var joue2: AudioStreamWAV = null
	if joueur2 != null:
		joue2 = joueur2.stream as AudioStreamWAV
	check(joue2 != null and joue2 == joue,
		"B11 : un second appel réutilise la MÊME copie, il n'en refabrique pas")

	# LE CŒUR DU CAS : l'exemplaire que `load()` rend à tout le monde, et que
	# `play_sfx` réutiliserait, n'a pas bougé.
	check_equal(partage.loop_mode, AudioStreamWAV.LOOP_DISABLED,
		"B8 : l'exemplaire PARTAGÉ du cache n'a pas été muté")
	check_equal(partage.loop_end, 0,
		"B9 : sa borne non plus")
	var relu: AudioStreamWAV = load(AMB) as AudioStreamWAV
	check(relu == partage,
		"B10 : et un `load()` ultérieur rend toujours l'ORIGINAL, pas la copie")

	await _rendre_le_silence()
	proprio.queue_free()
	await _tree().process_frame


# ── C ─ la lecture reboucle après la fin du clip, jamais avant ────────────────
func test_la_lecture_ne_reboucle_pas_avant_la_fin_du_clip() -> void:
	var a: Node = _audio()
	if a == null:
		check(false, "C0 : AudioManager absent")
		return
	await _rendre_le_silence()

	var partage: AudioStreamWAV = load(AMB) as AudioStreamWAV
	if partage != null:
		partage.loop_mode = AudioStreamWAV.LOOP_DISABLED
		partage.loop_end = 0

	var proprio: Node = Node.new()
	proprio.name = "ProprietaireObservation"
	_tree().root.add_child(proprio)
	a.call("play_ambience", &"amb_valley", proprio)

	var joueur: AudioStreamPlayer = _lecteur()
	check_not_null(joueur, "C1 : le lecteur existe")
	if joueur == null:
		return

	var maxi_vu: float = 0.0
	var recul_a: float = -1.0
	var releves: int = 0
	var depart: int = Time.get_ticks_msec()
	# Garde d'anti-blocage, pas un budget de vitesse : on SORT dès que le recul
	# est vu. Une machine lente met plus longtemps ; elle ne fait pas rougir.
	while Time.get_ticks_msec() - depart < int(ANTIHANG_S * 1000.0):
		await _tree().process_frame
		if not joueur.playing:
			continue
		var p: float = joueur.get_playback_position()
		releves += 1
		if p > maxi_vu:
			maxi_vu = p
		elif maxi_vu - p >= RECUL_MIN_S:
			recul_a = maxi_vu
			break

	check(releves > 10,
		"C2 : la position a réellement été échantillonnée (%d relevés)" % releves)
	check(recul_a >= 0.0,
		"C3 : un bouclage a été OBSERVÉ — la position est revenue en arrière")
	check(maxi_vu > SEUIL_PRECOCE_S,
		"C4 : la lecture a dépassé %.2f s avant de reboucler (vue : %.4f s). "
		% [SEUIL_PRECOCE_S, maxi_vu]
		+ "Sous le défaut, elle plafonnait à %.4f s." % (float(ANCIENNE_BORNE) / 44100.0))
	if recul_a >= 0.0:
		# BORNÉE DES DEUX CÔTÉS, corrigé après contre-revue. La rédaction
		# d'origine ne posait qu'un plancher (`>= AMB_DUREE_S - 0.5`), donc une
		# borne absurdement grande — un `mix_rate` appliqué deux fois, par
		# exemple — l'aurait satisfaite intégralement. Le message promettait
		# « à la FIN du clip » et ne prouvait que « au moins à 3,5 s ».
		check(absf(recul_a - AMB_DUREE_S) <= 0.5,
			"C5 : et le bouclage arrive bien À LA FIN du clip, ni avant ni "
			+ "après (%.4f s pour un clip de %.2f s)" % [recul_a, AMB_DUREE_S])

	await _rendre_le_silence()
	proprio.queue_free()
	await _tree().process_frame
