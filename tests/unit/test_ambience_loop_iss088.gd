## ISS-088 — LA BORNE DE BOUCLE D'AMBIANCE ÉTAIT COMPTÉE EN OCTETS COMPRESSÉS.
##
## `AudioManager.play_ambience()` posait `wav.loop_end = wav.data.size() / 2`,
## en supposant du PCM 16 bits mono. Or chaque `.wav.import` du projet porte
## `compress/mode=2` : la ressource chargée est du QOA, et `data` contient des
## octets COMPRESSÉS. Mesuré sur cet arbre (sonde moteur, ce worktree) :
## `amb_valley.wav` décodé fait 176 400 trames (4,0 s à 44,1 kHz), son `data`
## QOA fait 71 408 octets — la borne posée valait 35 704, et l'ambiance livrée
## REBOUCLAIT à 0,81 s d'un clip de 4,0 s. Aucun test ne le voyait : le contrat
## ISS-086 vérifie que la boucle est POSÉE, jamais OÙ elle est posée.
##
## L'UNITÉ DE `loop_end`, LUE DANS LA SOURCE DU MOTEUR (`~/src/godot`, tag
## `4.7.1-stable`), pas supposée :
##
##   - `set_loop_end(int p_frame)` — la borne est en TRAMES par canal
##     (scene/resources/audio_stream_wav.h:145) ;
##   - `_mix_internal` compte `len` en trames : PCM 16 bits `data_bytes / 2`
##     (audio_stream_wav.cpp:231-232), QOA `qoa.desc.samples * channels`
##     (cpp:238) puis `/= 2` si stéréo (cpp:242-243) — et `qoa_desc.samples`
##     est « samples per channel in this file » (thirdparty/misc/qoa.h:33) ;
##   - la lecture reboucle à `offset >= loop_end` (cpp:307), où `offset` est en
##     trames (`seek` : `offset = p_time * mix_rate`, cpp:91) ;
##   - `get_length()` rend trames/mix_rate POUR TOUS LES FORMATS — la branche
##     QOA décode l'en-tête au lieu de compter les octets (cpp:489-512).
##
## `data.size() / 2` et la vraie borne coïncident donc UNIQUEMENT en PCM 16
## bits mono. C'est pourquoi ce contrat épingle deux fixtures au contenu PCM
## IDENTIQUE AU BIT PRÈS (sha256 égaux à la génération, 22 050 échantillons
## écrits — le littéral TRAMES ci-dessous vient de la GÉNÉRATION, pas d'une
## API qu'on comparerait à elle-même) : l'une importée PCM (`compress/mode=0`),
## l'autre QOA (`compress/mode=2`). Même durée décodée, poids de `data` sans
## rapport (44 100 contre 8 952 octets) : la borne correcte est la même.
##
## VÉRIFICATION INDÉPENDANTE du littéral TRAMES (D-067) — sans confiance dans
## l'API testée ni dans la prose de cet en-tête :
##   python3 -c "import wave; print(wave.open('tests/fixtures/audio/iss088_boucle_pcm.wav').getnframes())"  -> 22050
##   côté QOA, l'en-tête `qoaf` du `data` importé porte le même compte en
##   grand-boutiste (octets 4..7). Mesuré à l'écriture de cette recette :
##   PCM 44100 Hz mono 16 bits, sinus de période 100 échantillons (~441 Hz),
##   amplitude crête 16383.
##
## SECOND DÉFAUT DU MÊME GESTE : la mutation frappait l'exemplaire PARTAGÉ —
## celui du cache `_sfx_streams` ET du ResourceCache de `load()` — que
## `play_sfx` réutilise. Le contrat exige une COPIE locale pour la boucle et un
## cache qui reste vierge. La copie reste SANS `resource_path` — non par
## danger : une repose par `set_path_cache()` serait inoffensive, car
## `~Resource()` ne désinscrit du ResourceCache que l'entrée qui pointe CE
## MÊME objet, et le commentaire moteur nomme explicitement les clones
## `CACHE_IGNORE` (core/io/resource.cpp:790-802 ; mesuré, journal
## rouge_T3_contre_v1 : chemin reposé sans erreur ni dégât de cache) — mais
## parce qu'AUCUN contrat n'en dépend : l'identité du flux joué est
## l'INTENTION déclarée du gestionnaire, `ambience_id()` — le mécanisme que le
## contrat ISS-086 lit, et que le cas T épingle ici.
##
## TROISIÈME DÉFAUT, mesuré par le contre-analyste de phase 2 : un OFF-BY-ONE
## d'une trame sur la borne — voir le commentaire de `BORNE`.
##
## CE QUE CE FICHIER NE PEUT PAS MESURER : le résidu de fin de processus
## (« Leaked instance ») n'existe que dans le rapport de SORTIE du moteur,
## comme pour ISS-086. Chaque cas rend donc le silence et laisse au serveur
## audio sa fenêtre de recyclage (temps RÉEL, voir RECYCLAGE_AUDIO_MS du
## contrat ISS-086). Le VERDICT de résidu, lui, se rend à l'étape 2b de la
## suite complète (`validate_fast`), qui juge le rapport de sortie — JAMAIS
## sur le journal d'une course filtrée : mesuré, une course filtrée sort
## avant la fenêtre de recyclage du serveur audio et affiche un faux résidu
## de harnais (en-tête du contrat ISS-086, « artefact de HARNAIS »).
##
## Les fixtures vivent dans `tests/fixtures/audio/`, hors de `assets/` : ce ne
## sont pas des assets du build. `play_ambience` résout ses noms contre
## `SFX_DIR`, une constante ; le SEUL point d'entrée d'un flux de test est donc
## le cache `_sfx_streams` — la couture exacte que `play_ambience` lit en
## premier. L'ensemencer exerce le vrai chemin de code à partir de la ligne qui
## suit la résolution du nom. Précédent d'accès à un membre privé depuis un
## test : `test_main_menu.gd` (`flow.set("_busy", …)`).
extends GateTestCase

const PCM_PATH: String = "res://tests/fixtures/audio/iss088_boucle_pcm.wav"
const QOA_PATH: String = "res://tests/fixtures/audio/iss088_boucle_qoa.wav"
const PCM_KEY: StringName = &"iss088_boucle_pcm"
const QOA_KEY: StringName = &"iss088_boucle_qoa"
## Trames par canal des DEUX fixtures — épinglé à la GÉNÉRATION : 22 050
## échantillons 16 bits mono à 44 100 Hz écrits derrière un en-tête WAV de
## 44 octets (le fichier fait 44 144 octets). Pas relu d'une API du moteur.
const TRAMES: int = 22050
## BORNE de boucle attendue : la DERNIÈRE TRAME, incluse — pas le compte.
## Le moteur lit jusqu'à `loop_end` COMPRIS (`aux = (limit - offset) /
## increment + 1`, audio_stream_wav.cpp:344) : borné au COMPTE de trames, il
## lirait une trame au-delà du tampon à chaque tour de boucle. L'importeur du
## moteur pose d'ailleurs `frames - 1` (sondé sur cet arbre : 22049 sur ces
## fixtures de 22050 trames, 176399 sur amb_valley, 176400 trames). Dérivée
## du littéral de GÉNÉRATION ci-dessus, pas relue d'une API.
## LIMITE ASSUMÉE : `roundi` (contre `floori`/`ceili`) n'est épinglé par
## aucune fixture à durée NON RONDE — les deux fixtures font 0,5 s pile à
## 44,1 kHz, où toutes les formules d'arrondi coïncident.
const BORNE: int = TRAMES - 1
## Même fenêtre de recyclage que le contrat ISS-086, même justification : le
## fil de mixage muet avance en temps RÉEL (~93 ms par pas), et une course
## filtrée qui sort trop vite montre un faux résidu de harnais.
const RECYCLAGE_AUDIO_MS: int = 400


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _audio() -> Node:
	return _tree().root.get_node_or_null("/root/AudioManager")


func _lecteur() -> AudioStreamPlayer:
	var audio: Node = _audio()
	if audio == null:
		return null
	return audio.get_node_or_null("Ambience") as AudioStreamPlayer


func _flux_joue() -> AudioStreamWAV:
	var joueur: AudioStreamPlayer = _lecteur()
	if joueur == null:
		return null
	return joueur.stream as AudioStreamWAV


func _settle(ticks: int) -> void:
	for i: int in range(ticks):
		await _tree().physics_frame


## Décrit l'état mesuré dans le message d'échec — un verdict qui dit seulement
## « faux » envoie chercher la panne au mauvais endroit (motif ISS-086).
func _etat() -> String:
	var wav: AudioStreamWAV = _flux_joue()
	if wav == null:
		return "aucun flux joué"
	return "loop_mode=%d, loop_begin=%d, loop_end=%d, data=%d o, chemin=%s" \
		% [wav.loop_mode, wav.loop_begin, wav.loop_end, wav.data.size(),
			wav.resource_path if not wav.resource_path.is_empty() else "<sans chemin>"]


## Ensemence le cache privé avec une fixture et rend l'exemplaire PARTAGÉ —
## celui-là même que `play_sfx` servirait, et que le contrat exige vierge.
func _semer(key: StringName, path: String) -> AudioStreamWAV:
	var audio: Node = _audio()
	if audio == null:
		return null
	var shared: AudioStreamWAV = load(path) as AudioStreamWAV
	var cache: Dictionary = audio.get("_sfx_streams") as Dictionary
	cache[key] = shared
	return shared


## Rend le processus tel qu'on l'a trouvé : cache désensemencé, silence rendu,
## fenêtre de recyclage laissée au serveur audio (temps réel, borné).
func _cloturer(keys: Array[StringName], owners: Array[Node]) -> void:
	var audio: Node = _audio()
	if audio != null:
		var cache: Dictionary = audio.get("_sfx_streams") as Dictionary
		for key: StringName in keys:
			cache.erase(key)
		audio.call("stop_ambience")
	var joueur: AudioStreamPlayer = _lecteur()
	if joueur != null:
		joueur.stream = null
	for owner: Node in owners:
		if is_instance_valid(owner):
			owner.free()
	await _settle(2)
	var depart: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - depart < RECYCLAGE_AUDIO_MS:
		await _tree().process_frame


## ---------------------------------------------------------------------------
## P — PCM : la borne est la dernière trame décodée
## ---------------------------------------------------------------------------
##
## HONNÊTETÉ SUR LA NON-VACUITÉ : en PCM 16 bits mono, `data.size() / 2` rend
## le COMPTE de trames — depuis la borne INCLUSIVE (`BORNE` = compte − 1),
## même ici l'ancienne formule est fausse, d'exactement une trame : P4 rougit
## désormais sous l'ablation qui la remet (sabotage A v3). Le discriminant de
## PRINCIPE reste Q — ici l'écart est d'une trame, là d'un ordre de grandeur.
## Ce cas rougit aussi si la boucle n'est plus posée du tout (borne 0 — le
## moteur coupe la lecture, audio_stream_wav.cpp:249), si la borne était
## comptée en OCTETS (44 100), en secondes (0), ou posée sur le mauvais
## exemplaire.
func test_pcm_la_borne_de_boucle_est_la_derniere_trame() -> void:
	var audio: Node = _audio()
	if audio == null:
		check(false, "P0 — AudioManager absent")
		return
	var shared: AudioStreamWAV = _semer(PCM_KEY, PCM_PATH)
	# Non-vacuités BLOQUANTES : si l'import n'a pas produit le format attendu,
	# les assertions suivantes mesureraient un autre défaut que le leur.
	var forme_ok: bool = shared != null \
		and shared.format == AudioStreamWAV.FORMAT_16_BITS \
		and not shared.stereo \
		and shared.data.size() == 2 * TRAMES \
		and shared.loop_mode == AudioStreamWAV.LOOP_DISABLED
	check(forme_ok, "P1 — la fixture PCM est bien du 16 bits mono de %d trames, "
		% TRAMES + "boucle non posée au départ")
	if not forme_ok:
		await _cloturer([PCM_KEY], [])
		return

	var owner: Node = Node.new()
	audio.call("play_ambience", PCM_KEY, owner)
	await _settle(1)
	var joue: AudioStreamWAV = _flux_joue()
	check(joue != null and joue.loop_mode == AudioStreamWAV.LOOP_FORWARD,
		"P2 — le flux joué boucle en avant (%s)" % _etat())
	check(joue != null and joue.loop_begin == 0,
		"P3 — la boucle part de la trame 0 (%s)" % _etat())
	check(joue != null and joue.loop_end == BORNE,
		"P4 — la borne PCM est la dernière trame décodée INCLUSE, %d (%s)"
		% [BORNE, _etat()])
	await _cloturer([PCM_KEY], [owner])


## ---------------------------------------------------------------------------
## Q — QOA : la borne est la dernière trame décodée, PAS un compte d'octets
## ---------------------------------------------------------------------------
##
## C'est LE cas qui accuse ISS-088 : mêmes 22 050 trames décodées que P, mais
## `data` contient 8 952 octets QOA — l'ancienne formule posait 4 476, et la
## lecture rebouclait au cinquième du clip. Q1 verrouille que l'ancienne
## formule est FAUSSE ici (`data.size() / 2 != TRAMES`) : sans ce verrou, une
## régénération de fixture qui redeviendrait PCM rendrait Q4 vert par
## coïncidence, et ce contrat ne discriminerait plus rien.
func test_qoa_la_borne_de_boucle_est_la_derniere_trame() -> void:
	var audio: Node = _audio()
	if audio == null:
		check(false, "Q0 — AudioManager absent")
		return
	var shared: AudioStreamWAV = _semer(QOA_KEY, QOA_PATH)
	var forme_ok: bool = shared != null \
		and shared.format == AudioStreamWAV.FORMAT_QOA \
		and not shared.stereo \
		and shared.data.size() / 2 != TRAMES \
		and shared.loop_mode == AudioStreamWAV.LOOP_DISABLED
	check(forme_ok, "Q1 — la fixture QOA est bien compressée : data/2 (%d) n'a "
		% (0 if shared == null else shared.data.size() / 2)
		+ "aucun rapport avec les %d trames décodées" % TRAMES)
	if not forme_ok:
		await _cloturer([QOA_KEY], [])
		return

	var owner: Node = Node.new()
	audio.call("play_ambience", QOA_KEY, owner)
	await _settle(1)
	var joue: AudioStreamWAV = _flux_joue()
	check(joue != null and joue.loop_mode == AudioStreamWAV.LOOP_FORWARD,
		"Q2 — le flux joué boucle en avant (%s)" % _etat())
	check(joue != null and joue.loop_begin == 0,
		"Q3 — la boucle part de la trame 0 (%s)" % _etat())
	check(joue != null and joue.loop_end == BORNE,
		"Q4 — la borne QOA est la dernière trame DÉCODÉE incluse, %d — jamais "
		% BORNE + "un compte d'octets compressés (%s)" % _etat())
	await _cloturer([QOA_KEY], [owner])


## ---------------------------------------------------------------------------
## R — même durée décodée, poids compressés sans rapport : MÊME borne
## ---------------------------------------------------------------------------
##
## Les deux fixtures portent le même contenu PCM au bit près ; seule la
## compression d'import diffère. Si la borne dépendait du poids de `data`,
## R3 et R4 ne pourraient pas être vrais ensemble — c'est l'indépendance
## demandée par le contrat, démontrée sur le vrai chemin de `play_ambience`.
func test_meme_duree_decodee_meme_borne_quel_que_soit_le_poids() -> void:
	var audio: Node = _audio()
	if audio == null:
		check(false, "R0 — AudioManager absent")
		return
	var pcm: AudioStreamWAV = _semer(PCM_KEY, PCM_PATH)
	var qoa: AudioStreamWAV = _semer(QOA_KEY, QOA_PATH)
	# Non-vacuité BLOQUANTE : si les poids ne différaient pas réellement, la
	# « même borne » ne démontrerait aucune indépendance.
	var poids_ok: bool = pcm != null and qoa != null \
		and pcm.format != qoa.format \
		and pcm.data.size() != qoa.data.size()
	check(poids_ok, "R1 — les deux fixtures ont des formats et des poids de "
		+ "data réellement différents (%d contre %d octets)"
		% [0 if pcm == null else pcm.data.size(),
			0 if qoa == null else qoa.data.size()])
	if not poids_ok:
		await _cloturer([PCM_KEY, QOA_KEY], [])
		return

	var owner: Node = Node.new()
	audio.call("play_ambience", PCM_KEY, owner)
	await _settle(1)
	var joue: AudioStreamWAV = _flux_joue()
	var borne_pcm: int = -1 if joue == null else joue.loop_end
	audio.call("stop_ambience")
	await _settle(1)

	audio.call("play_ambience", QOA_KEY, owner)
	await _settle(1)
	joue = _flux_joue()
	var borne_qoa: int = -1 if joue == null else joue.loop_end
	check(borne_pcm == BORNE,
		"R3 — borne PCM : %d attendu, obtenu %d" % [BORNE, borne_pcm])
	check(borne_qoa == BORNE,
		"R4 — borne QOA : %d attendu, obtenu %d — même durée décodée, même "
		% [BORNE, borne_qoa] + "borne, quel que soit le poids compressé")
	await _cloturer([PCM_KEY, QOA_KEY], [owner])


## ---------------------------------------------------------------------------
## S — l'exemplaire PARTAGÉ du cache reste vierge ; le flux JOUÉ porte tout
## ---------------------------------------------------------------------------
##
## `_sfx_streams` et le ResourceCache servent le MÊME exemplaire à `play_sfx` :
## le muter pour la boucle d'ambiance, c'est faire boucler tous les usages
## futurs du même son. S2 rougit avant correction (l'exemplaire partagé ÉTAIT
## l'exemplaire joué, muté LOOP_FORWARD) ; S4 est sa non-vacuité — la boucle
## est bien posée QUELQUE PART, sinon un gestionnaire qui ne poserait plus
## rien rendrait S2 vert sans rien protéger.
func test_le_cache_partage_reste_vierge() -> void:
	var audio: Node = _audio()
	if audio == null:
		check(false, "S0 — AudioManager absent")
		return
	var shared: AudioStreamWAV = _semer(QOA_KEY, QOA_PATH)
	var forme_ok: bool = shared != null \
		and shared.loop_mode == AudioStreamWAV.LOOP_DISABLED
	check(forme_ok, "S1 — départ : l'exemplaire partagé est vierge")
	if not forme_ok:
		await _cloturer([QOA_KEY], [])
		return

	var owner: Node = Node.new()
	audio.call("play_ambience", QOA_KEY, owner)
	await _settle(1)
	# Relire par les DEUX portes que `play_sfx` emprunte : le cache privé
	# (couture ensemencée) et `load()` (ResourceCache) rendent le même objet.
	var du_cache: AudioStreamWAV = \
		(audio.get("_sfx_streams") as Dictionary).get(QOA_KEY) as AudioStreamWAV
	var du_load: AudioStreamWAV = load(QOA_PATH) as AudioStreamWAV
	check(du_cache == shared and du_load == shared,
		"S2a — les deux portes du partage rendent toujours le même exemplaire")
	check(shared.loop_mode == AudioStreamWAV.LOOP_DISABLED \
		and shared.loop_end == 0,
		"S2 — APRÈS play_ambience, l'exemplaire partagé reste vierge : "
		+ "loop_mode=%d, loop_end=%d" % [shared.loop_mode, shared.loop_end])
	var joue: AudioStreamWAV = _flux_joue()
	check(joue != null and joue != shared,
		"S3 — le flux joué est un exemplaire DISTINCT du partagé (%s)" % _etat())
	check(joue != null and joue.loop_mode == AudioStreamWAV.LOOP_FORWARD \
		and joue.loop_end == BORNE,
		"S4 — et c'est LUI qui porte la boucle, bornée à %d (%s)"
		% [BORNE, _etat()])
	await _cloturer([QOA_KEY], [owner])


## ---------------------------------------------------------------------------
## T — la copie jouée : mécanisme épinglé, chemin vide, identité par INTENTION
## ---------------------------------------------------------------------------
##
## Le contrat ISS-086 identifie le flux joué ; toute identité par
## `resource_path` casse dès que la copie joue — mesuré : un `duplicate()` nu
## rougissait A2/D1.1/E1/F3 d'ISS-086 en annonçant « ne joue pas » pendant que
## ça jouait (journal sabotage_C). L'identité RETENUE est l'INTENTION du
## gestionnaire, `ambience_id()` — c'est elle qu'ISS-086 lit ; T4 l'épingle
## POSÉE par la demande, T5 VIDÉE par la libération (une identité qui survit
## à l'arrêt ferait dire « la vallée joue » au silence). T2 épingle le
## MÉCANISME de copie par égalité d'octets — le seul endroit du contrat où
## les octets font foi, parce qu'ils testent la copie elle-même, pas « qui
## joue ». T3 épingle le chemin VIDE : une repose par `set_path_cache()`
## serait inoffensive (resource.cpp:790-802, journal rouge_T3_contre_v1),
## mais aucun contrat n'en dépend — sa réapparition doit rougir ici pour
## forcer une décision consciente. T3 rougit aussi avant correction (le flux
## joué était alors l'exemplaire partagé, avec son chemin) : l'autre face
## de S3.
func test_lidentite_de_la_copie_survit_sans_chemin() -> void:
	var audio: Node = _audio()
	if audio == null:
		check(false, "T0 — AudioManager absent")
		return
	var shared: AudioStreamWAV = _semer(QOA_KEY, QOA_PATH)
	var owner: Node = Node.new()
	audio.call("play_ambience", QOA_KEY, owner)
	await _settle(1)
	var joue: AudioStreamWAV = _flux_joue()
	# Non-vacuité : le flux joué existe, boucle, et est un exemplaire DISTINCT
	# — sinon « l'identité tient » serait vrai de l'identité d'un même objet.
	var actif: bool = joue != null and shared != null and joue != shared \
		and joue.loop_mode == AudioStreamWAV.LOOP_FORWARD
	check(actif, "T1 — un flux joué, bouclé et DISTINCT du partagé existe (%s)"
		% _etat())
	check(joue != null and shared != null and joue.data == shared.data,
		"T2 — le mécanisme de copie tient : même data que l'exemplaire "
		+ "canonique (%s)" % _etat())
	check(joue != null and joue.resource_path.is_empty(),
		"T3 — la copie est honnêtement SANS chemin : aucune repose manuelle "
		+ "(%s)" % _etat())
	check(StringName(audio.call("ambience_id")) == QOA_KEY,
		"T4 — l'identité par INTENTION est posée : ambience_id() rend le nom "
		+ "demandé (obtenu « %s »)" % String(StringName(audio.call("ambience_id"))))
	audio.call("stop_ambience")
	await _settle(1)
	check(StringName(audio.call("ambience_id")) == StringName(),
		"T5 — rendue, l'ambiance n'a plus d'identité : la libération VIDE "
		+ "ambience_id() (obtenu « %s »)"
		% String(StringName(audio.call("ambience_id"))))
	await _cloturer([QOA_KEY], [owner])


## ---------------------------------------------------------------------------
## U — trois démarrages/arrêts : rien ne s'accumule, rien ne survit
## ---------------------------------------------------------------------------
##
## Garde ISS-086 au niveau de l'API : une libération qui ne marche qu'une fois
## n'est pas une libération, et un lecteur recréé à chaque demande finirait par
## peupler l'autoload. Chaque cycle porte sa non-vacuité (l'ambiance a VRAIMENT
## joué) — sans elle, « plus rien ne joue » serait vrai d'un gestionnaire qui
## ne démarre jamais rien.
##
## U*.1b, à CHAQUE cycle : depuis la duplication, la garde `LOOP_DISABLED` du
## gestionnaire est vraie à chaque appel — l'ancienne version ne posait la
## boucle qu'UNE fois par processus, sur l'exemplaire partagé muté. Trois
## démarrages successifs du même son doivent produire trois copies bornées
## juste ; une régression qui ne poserait la boucle qu'au premier appel, ou
## qui re-bornerait depuis un état résiduel, rougit au cycle 2 ou 3.
func test_trois_cycles_sans_fuite_ni_accumulation() -> void:
	var audio: Node = _audio()
	if audio == null:
		check(false, "U0 — AudioManager absent")
		return
	var _shared: AudioStreamWAV = _semer(QOA_KEY, QOA_PATH)
	var owner: Node = Node.new()
	var enfants_apres_1: int = -1
	for cycle: int in range(1, 4):
		audio.call("play_ambience", QOA_KEY, owner)
		await _settle(1)
		check(bool(audio.call("is_ambience_playing")),
			"U%d.1 — cycle %d : l'ambiance joue vraiment (%s)"
			% [cycle, cycle, _etat()])
		var joue: AudioStreamWAV = _flux_joue()
		check(joue != null and joue.loop_mode == AudioStreamWAV.LOOP_FORWARD \
			and joue.loop_end == BORNE,
			"U%d.1b — cycle %d : la boucle est posée et bornée à %d, à CHAQUE "
			% [cycle, cycle, BORNE] + "démarrage (%s)" % _etat())
		audio.call("stop_ambience")
		await _settle(2)
		var joueur: AudioStreamPlayer = _lecteur()
		check(joueur != null and not joueur.playing \
			and not joueur.has_stream_playback() and joueur.stream == null,
			"U%d.2 — cycle %d : arrêté, zéro lecture survivante, zéro flux "
			% [cycle, cycle] + "retenu")
		if cycle == 1:
			enfants_apres_1 = audio.get_child_count()
		else:
			check(audio.get_child_count() == enfants_apres_1,
				"U%d.3 — cycle %d : aucun lecteur ne s'accumule sous "
				% [cycle, cycle] + "l'autoload (%d enfants, %d au cycle 1)"
				% [audio.get_child_count(), enfants_apres_1])
	await _cloturer([QOA_KEY], [owner])


## ---------------------------------------------------------------------------
## V — transfert de propriété : l'ancien ne peut plus arrêter, le nouveau oui
## ---------------------------------------------------------------------------
##
## Garde ISS-086 : la deuxième demande remplace la première ET sa propriété.
## V2 mesure les DEUX faces du refus — le verdict (faux) et l'effet (rien ne
## s'est arrêté) : un arrêt qui rendrait faux tout en coupant le son passerait
## un contrôle du seul verdict.
func test_transfert_de_propriete() -> void:
	var audio: Node = _audio()
	if audio == null:
		check(false, "V0 — AudioManager absent")
		return
	var _shared: AudioStreamWAV = _semer(QOA_KEY, QOA_PATH)
	var ancien: Node = Node.new()
	var nouveau: Node = Node.new()
	audio.call("play_ambience", QOA_KEY, ancien)
	await _settle(1)
	var joue: bool = bool(audio.call("is_ambience_playing"))
	check(joue, "V1 — l'ancien propriétaire a bien démarré l'ambiance (%s)"
		% _etat())
	if not joue:
		await _cloturer([QOA_KEY], [ancien, nouveau])
		return

	audio.call("play_ambience", QOA_KEY, nouveau)
	await _settle(1)
	var refus: bool = not bool(audio.call("stop_ambience_owned_by", ancien))
	check(refus and bool(audio.call("is_ambience_playing")),
		"V2 — l'ANCIEN propriétaire ne peut plus arrêter : refus rendu ET "
		+ "l'ambiance joue encore (%s)" % _etat())
	var accord: bool = bool(audio.call("stop_ambience_owned_by", nouveau))
	await _settle(1)
	check(accord and not bool(audio.call("is_ambience_playing")),
		"V3 — le NOUVEAU propriétaire arrête : accord rendu ET plus rien ne "
		+ "joue (%s)" % _etat())
	await _cloturer([QOA_KEY], [ancien, nouveau])


## ---------------------------------------------------------------------------
## W — une ambiance sans propriétaire reste refusée
## ---------------------------------------------------------------------------
##
## Garde ISS-086/F au niveau de l'API, rejouée ici parce que la correction
## réécrit le corps de `play_ambience` : le refus du `null` doit survivre au
## remaniement. Non-vacuité W2 : la MÊME demande avec propriétaire démarre —
## sans elle, W1 serait vrai parce que rien ne marche.
func test_une_ambiance_sans_proprietaire_reste_refusee() -> void:
	var audio: Node = _audio()
	if audio == null:
		check(false, "W0 — AudioManager absent")
		return
	var _shared: AudioStreamWAV = _semer(QOA_KEY, QOA_PATH)
	audio.call("stop_ambience")
	await _settle(1)
	audio.call("play_ambience", QOA_KEY, null)
	await _settle(1)
	check(not bool(audio.call("is_ambience_playing")),
		"W1 — une demande SANS propriétaire ne démarre rien (%s)" % _etat())

	var owner: Node = Node.new()
	audio.call("play_ambience", QOA_KEY, owner)
	await _settle(1)
	check(bool(audio.call("is_ambience_playing")),
		"W2 — la MÊME demande, avec propriétaire, démarre bien (%s)" % _etat())
	check(bool(audio.call("stop_ambience_owned_by", owner)),
		"W3 — et son propriétaire peut la rendre")
	await _cloturer([QOA_KEY], [owner])


## ---------------------------------------------------------------------------
## X — un son manquant est TRACÉ au journal et reste sans dégât
## ---------------------------------------------------------------------------
##
## Audit export (consigne du lead) : aucun portail d'export ne peut
## « entendre », et `_sfx_stream` rendait null EN SILENCE — dans une build
## exportée, un asset audio absent du PCK était invisible de tous les
## journaux, que le balayage de la garnison greppe pourtant. `_sfx_stream`
## avertit désormais par `push_warning` — jamais `push_error`, l'étape 2b de
## validate_fast traite tout `ERROR:` comme un échec — une fois par nom
## (cache négatif). L'ÉMISSION ne se mesure pas d'ici : GDScript ne lit pas
## son propre journal ; elle se voit dans le journal de cette course, comme le
## refus d'owner null. Ce cas mesure le CONTRAT DE COMPORTEMENT : déclaré
## absent sans erreur, rien ne casse, et un `play_ambience` manquant ne vole
## ni ne coupe l'ambiance en cours — la promesse écrite dans le commentaire de
## `play_ambience` (« le propriétaire PRÉCÉDENT garde sa prise »), épinglée
## ici pour la première fois.
func test_un_son_manquant_est_trace_et_sans_degat() -> void:
	var audio: Node = _audio()
	if audio == null:
		check(false, "X0 — AudioManager absent")
		return
	# Ni fixture ni fichier de SFX_DIR : le premier contact déclenche le
	# warning (visible au journal) et un cache négatif que la clôture efface.
	check(not bool(audio.call("has_sfx", &"iss088_inexistant")),
		"X1 — un son manquant est déclaré absent, sans erreur")

	var _shared: AudioStreamWAV = _semer(QOA_KEY, QOA_PATH)
	var ancien: Node = Node.new()
	audio.call("play_ambience", QOA_KEY, ancien)
	await _settle(1)
	var joue: bool = bool(audio.call("is_ambience_playing"))
	check(joue, "X2 — départ : une ambiance joue, avec propriétaire (%s)" % _etat())
	if not joue:
		await _cloturer([QOA_KEY, &"iss088_inexistant"], [ancien])
		return

	# `play_sfx` d'un manquant est inoffensif : la preuve est que la suite du
	# cas s'exécute et que le journal de la course ne porte aucun `ERROR:`.
	audio.call("play_sfx", &"iss088_inexistant")
	var demandeur: Node = Node.new()
	audio.call("play_ambience", &"iss088_inexistant_2", demandeur)
	await _settle(1)
	check(bool(audio.call("is_ambience_playing")),
		"X3 — un play_ambience MANQUANT ne coupe pas l'ambiance en cours (%s)"
		% _etat())
	# Le retour « son introuvable » précède la pose de `_ambience_id` : le
	# manquant ne doit pas non plus VOLER L'IDENTITÉ — sans quoi le contrat
	# ISS-086, qui lit ambience_id(), dirait « la vallée ne joue plus »
	# pendant qu'elle joue.
	check(StringName(audio.call("ambience_id")) == QOA_KEY,
		"X3b — et n'en vole pas l'identité : ambience_id() rend toujours le "
		+ "son en cours (obtenu « %s »)"
		% String(StringName(audio.call("ambience_id"))))
	check(not bool(audio.call("stop_ambience_owned_by", demandeur)),
		"X4 — et ne vole pas la propriété : le demandeur du son manquant est "
		+ "refusé à l'arrêt")
	check(bool(audio.call("stop_ambience_owned_by", ancien)),
		"X5 — le propriétaire PRÉCÉDENT garde sa prise et peut rendre")
	await _cloturer(
		[QOA_KEY, &"iss088_inexistant", &"iss088_inexistant_2"],
		[ancien, demandeur])


## ---------------------------------------------------------------------------
## Y — un flux VIDE ne reçoit pas de boucle : la garde `trames > 0` est réelle
## ---------------------------------------------------------------------------
##
## Deux contre-analyses successives ont prouvé que cette garde n'était
## protégée par RIEN : la retirer laissait toute la suite verte. Sans elle,
## `play_ambience` dupliquerait un flux vide et lui poserait
## `loop_end = trames - 1 = -1` en LOOP_FORWARD. Ici : un
## `AudioStreamWAV.new()` sans données — `get_length()` rend 0 — et la garde
## doit laisser passer le flux TEL QUEL : pas de copie, pas de boucle,
## lecture unique, pas de crash. Le moteur sort du silence sur un `data` vide
## sans poser d'erreur (`_mix_internal` retourne avant tout accès,
## audio_stream_wav.cpp:218-224). La propriété et l'identité, elles, sont
## posées normalement : un son vide reste un son demandé, que son
## propriétaire doit pouvoir rendre.
func test_un_flux_vide_ne_recoit_pas_de_boucle() -> void:
	var audio: Node = _audio()
	if audio == null:
		check(false, "Y0 — AudioManager absent")
		return
	var vide: AudioStreamWAV = AudioStreamWAV.new()
	var cache: Dictionary = audio.get("_sfx_streams") as Dictionary
	cache[&"iss088_vide"] = vide
	check(vide.data.is_empty() \
		and roundi(vide.get_length() * vide.mix_rate) == 0,
		"Y1 — la fixture est bien un flux VIDE : zéro donnée, zéro trame")

	var owner: Node = Node.new()
	audio.call("play_ambience", &"iss088_vide", owner)
	await _settle(1)
	var joueur: AudioStreamPlayer = _lecteur()
	check(joueur != null and joueur.stream == vide,
		"Y2 — la garde a laissé passer le flux TEL QUEL : aucune copie d'un "
		+ "flux vide (%s)" % _etat())
	check(vide.loop_mode == AudioStreamWAV.LOOP_DISABLED and vide.loop_end == 0,
		"Y3 — aucune boucle posée : lecture unique, jamais de borne -1 (%s)"
		% _etat())
	check(StringName(audio.call("ambience_id")) == &"iss088_vide" \
		and bool(audio.call("stop_ambience_owned_by", owner)),
		"Y4 — propriété et identité posées quand même : un flux vide se rend "
		+ "comme un autre")
	await _cloturer([&"iss088_vide"], [owner])
