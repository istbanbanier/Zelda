## ISS-087 §6 — LE BUS `Ambience` DOIT ÊTRE RESTAURÉ AU DÉMARRAGE.
##
## `AudioManager::_restore_saved_volumes()` ne parcourait que `Master`,
## `Music` et `SFX` : un joueur qui baissait l'ambiance la retrouvait à son
## niveau par défaut au lancement suivant, curseur affichant le contraire —
## exactement le défaut qu'ISS-085 avait corrigé pour les trois autres bus,
## laissé incomplet. Sans cette restauration, aucun prototype d'essai n'est
## réglable par le joueur, ce qui invalide en partie le protocole d'écoute.
##
## ÉCRIT AVANT LA CORRECTION, ET VU ROUGE D'ABORD (PROMPT4_METHOD §2) :
## journal `~/.cache/team-final/impl/rouge_bus_ambience.log` — l'assertion B
## rend 1,0 au lieu de 0,37 sur l'arbre non corrigé.
##
## PÉRIMÈTRE VOULU : `Ambience` seulement. `UI` et `Voice` restent hors
## restauration — hors périmètre ISS-091, ne pas les ajouter ici sans
## décision.
extends GateTestCase

const BUS_SUIVIS: Array[String] = ["Master", "Music", "SFX", "Ambience"]


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _audio() -> Node:
	return _tree().root.get_node_or_null("/root/AudioManager")


func test_le_volume_du_bus_ambience_est_restaure() -> void:
	var audio: Node = _audio()
	if audio == null:
		check(false, "A0 — AudioManager absent")
		return
	# Ce que le processus portait avant le test : la valeur SAUVÉE d'Ambience,
	# et le volume VIF des quatre bus — `_restore_saved_volumes` réapplique la
	# sauvegarde de Master/Music/SFX au passage, il faut donc tout rendre.
	var sauvee_avant: float = UserSettings.load_volume("Ambience")
	var vifs_avant: Dictionary[String, float] = {}
	for bus: String in BUS_SUIVIS:
		vifs_avant[bus] = float(audio.call("get_volume", bus))

	# NON-VACUITÉ : le bus vit à 1,0 et la sauvegarde dit 0,37. Si la
	# restauration ne parcourt pas `Ambience`, la relecture rend 1,0 — le
	# test ne peut pas passer par accident.
	audio.call("set_volume", "Ambience", 1.0)
	check(UserSettings.save_volume("Ambience", 0.37),
		"A1 — la valeur 0,37 est écrite dans settings.cfg")

	audio.call("_restore_saved_volumes")
	var relue: float = float(audio.call("get_volume", "Ambience"))
	check_approx(relue, 0.37, 0.01,
		"B — après _restore_saved_volumes, le bus Ambience porte la valeur "
		+ "sauvée (0,37), pas son défaut")

	# Un test rend le processus tel qu'il l'a trouvé.
	UserSettings.save_volume("Ambience", sauvee_avant)
	for bus: String in BUS_SUIVIS:
		audio.call("set_volume", bus, vifs_avant[bus])
