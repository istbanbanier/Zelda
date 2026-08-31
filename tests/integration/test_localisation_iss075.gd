## ISS-075 — LA FONDATION DE LOCALISATION, ET CE QU'ELLE PROUVE VRAIMENT.
##
## Une table de textes est facile à simuler : on peut écrire un `Dictionary`
## français, l'appeler « localisation », et n'avoir RIEN construit — le texte
## reste écrit en dur, à un niveau d'indirection près. Ce fichier existe pour
## rendre cette simulation impossible.
##
##   A1 la FORME d'une clé sépare vraiment clés et textes — vérifié sur les
##      littéraux réels du dépôt, pas sur des exemples choisis ;
##   A2 toute clé de la source résout ;
##   A3 une clé absente de la source ÉCHOUE, visiblement et de façon comptée ;
##   A4 la locale témoin change RÉELLEMENT le texte rendu ;
##   A5 le repli d'une locale incomplète est du français, compté, non fatal ;
##   A6 les textes du camp sont des CLÉS dans la donnée ;
##   A7 le HUD résout la clé, et laisse passer le texte brut hérité ;
##   A8 la loi : aucune porte `notify` ne gagne de texte joueur cru.
extends GateTestCase

const CAMP_JSON: String = "res://resources/world_v2/world_v2_camp_liberation.json"
const SHELL: String = "res://scenes/ui/GameplayShell.tscn"
const TEMOIN: StringName = &"en"
## La clé volontairement absente de la locale témoin (voir `en.json`, `_doc_trou`).
const TROU_TEMOIN: String = "menu.options.sous_titre"

## PLAFOND PAR FICHIER des textes joueur ÉCRITS EN DUR dans un appel `notify`.
## Ce n'est pas un idéal, c'est une DETTE MESURÉE le 2026-08-29 : 12 littéraux
## sur 6 fichiers, après migration de deux d'entre eux. La loi est « ça ne
## monte pas ». Descendre est libre ; un fichier absent de cette table doit
## valoir zéro.
##
## La porte choisie est `call("notify", "…")` parce qu'elle est INDISCUTABLE :
## tout ce qui la franchit finit sur l'écran du joueur. Les autres portes
## (`prompt_verb`, `.text` posé en scène, `display_name` des `.tres`) restent
## NON COUVERTES et comptées dans `docs/LOCALISATION.md` — un garde-fou qui
## devinerait produirait des faux rouges, et un garde-fou à faux rouges finit
## désarmé (PROMPT4 §1.2).
const PLAFOND_NOTIFY: Dictionary = {
	"scripts/interaction/chest.gd": 2,
	"scripts/interaction/ingredient_pickup.gd": 2,
	"scripts/interaction/story_fragment.gd": 1,
	"scripts/interaction/weapon_pickup.gd": 2,
	"scripts/player/player_controller.gd": 4,
	"scripts/world/valley_world.gd": 1,
}


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _lire(chemin: String) -> String:
	var f: FileAccess = FileAccess.open(chemin, FileAccess.READ)
	return "" if f == null else f.get_as_text()


func _json(chemin: String) -> Dictionary:
	var v: Variant = JSON.parse_string(_lire(chemin))
	return v as Dictionary if v is Dictionary else {}


## Tous les `.gd` de `scripts/`, chemins relatifs au projet.
func _scripts() -> Array[String]:
	var out: Array[String] = []
	var pile: Array[String] = ["res://scripts"]
	while not pile.is_empty():
		var d: String = pile.pop_back()
		var acces: DirAccess = DirAccess.open(d)
		if acces == null:
			continue
		for sous: String in acces.get_directories():
			pile.append(d + "/" + sous)
		for f: String in acces.get_files():
			if f.ends_with(".gd"):
				out.append(d + "/" + f)
	out.sort()
	return out


# --------------------------------------------------------------------------
# A1 — la forme d'une clé sépare vraiment
# --------------------------------------------------------------------------
func test_la_forme_d_une_cle_ne_peut_pas_attraper_un_texte_joueur() -> void:
	for cle: String in Textes.cles_source():
		check(Textes.ressemble_a_une_cle(cle),
			"A1 — « %s » est une clé de la table et doit être reconnue comme "
			% cle + "telle, sinon le HUD ne la traduirait jamais")
	check(Textes.cles_source().size() >= 5,
		"préalable NON VACUITÉ : la table source porte %d clés — une table "
		% Textes.cles_source().size() + "vide rendrait la boucle ci-dessus muette")

	# L'autre bras, celui qui compte : AUCUN texte français ne doit passer.
	var textes: Array[String] = [
		"Le camp est libéré. Le feu se rallume.",
		"Rien à portée — approchez-vous et faites face.",
		"Coffre ouvert : ",
		"%s cassée !",
		"Cuisiner", "Ouvrir", "…", "...", "0.5", "res://a.tscn",
	]
	for t: String in textes:
		check(not Textes.ressemble_a_une_cle(t),
			"A1 — « %s » est du TEXTE, pas une clé : le confondre ferait "
			% t + "chercher une traduction pour une phrase entière")


# --------------------------------------------------------------------------
# A2 — toute clé de la source résout
# --------------------------------------------------------------------------
func test_chaque_cle_de_la_source_rend_un_texte() -> void:
	for cle: String in Textes.cles_source():
		var valeur: String = Textes.t(cle)
		check(valeur != "" and not valeur.begins_with("⟦"),
			"A2 — « %s » doit rendre du texte, pas le marqueur d'absence (%s)"
			% [cle, valeur])
	check_equal(Textes.absentes_source().size(), 0,
		"A2 — aucune clé de la table n'a été signalée absente d'elle-même")


# --------------------------------------------------------------------------
# A3 — une clé manquante échoue VISIBLEMENT
# --------------------------------------------------------------------------
## C'est l'exigence que la directive nomme « échec explicite ». Le contraire —
## `tr()` de Godot, qui rend la clé nue et se tait — est exactement ce qu'on
## refuse : sur un écran, `camp.braise.libere` ressemble à un choix de mise en
## page, et personne ne le remonte.
func test_une_cle_absente_de_la_source_est_signalee_et_visible() -> void:
	Textes.oublier_diagnostic()
	var fantome: String = "cle.qui.n.existe.pas.du.tout"
	check(Textes.ressemble_a_une_cle(fantome),
		"préalable : la clé fantôme a bien la FORME d'une clé — sinon le HUD "
		+ "la laisserait passer et ce cas ne prouverait rien")
	check_equal(Textes.brut(fantome), "",
		"A3 — la résolution nue rend le vide, sans bruit : c'est la brique "
		+ "qui permet de CONSTATER une absence sans la provoquer")

	# A3 exerce le chemin d'erreur À DESSEIN : `t()` doit crier. Mais l'étape 2
	# de validate_fast traite tout `ERROR:` du journal comme un échec, et elle
	# a raison de le faire. On fait donc taire l'impression LE TEMPS de l'appel
	# — on n'annule pas l'erreur, on l'empêche de polluer le journal d'un juge
	# qui ne peut pas savoir qu'elle est voulue. Valeur SAUVEGARDÉE puis
	# restaurée, jamais `true` en dur : un autre test peut l'avoir éteinte.
	var imprimait: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	var rendu: String = Textes.t(fantome)
	Engine.print_error_messages = imprimait
	check(rendu.contains(fantome) and rendu.begins_with("⟦"),
		"A3 — le joueur voit un texte manifestement cassé : %s" % rendu)
	check(Textes.absentes_source().has(fantome),
		"A3 — et l'absence est COMPTÉE, pas seulement affichée : %s"
		% [Textes.absentes_source()])
	Textes.oublier_diagnostic()


# --------------------------------------------------------------------------
# A4 — la locale témoin change réellement le texte
# --------------------------------------------------------------------------
## Sans ce cas, une table « française » écrite en dur passerait pour de la
## localisation. Ce qui est prouvé ici est l'INDIRECTION elle-même.
func test_la_locale_temoin_change_le_texte_rendu() -> void:
	check(Textes.locales().has(TEMOIN),
		"préalable : la locale témoin « %s » existe — sinon rien ci-dessous "
		% TEMOIN + "ne serait vérifiable : %s" % [Textes.locales()])
	var cle: String = "camp.braise.libere"
	var en_fr: String = Textes.t(cle)

	check(Textes.definir_locale(TEMOIN), "bascule vers la locale témoin")
	var en_temoin: String = Textes.t(cle)
	check(Textes.definir_locale(Textes.LOCALE_SOURCE), "retour au français")

	check(en_temoin != "" and not en_temoin.begins_with("⟦"),
		"A4 — la locale témoin rend un vrai texte pour « %s »" % cle)
	check(en_temoin != en_fr,
		"A4 — et ce texte DIFFÈRE du français (« %s » contre « %s ») : c'est "
		% [en_temoin, en_fr] + "la seule preuve que la clé traverse une table")
	check_equal(Textes.t(cle), en_fr,
		"A4 — le retour à la source rend exactement le texte de départ")


# --------------------------------------------------------------------------
# A5 — le repli d'une locale incomplète : français, compté, non fatal
# --------------------------------------------------------------------------
func test_une_traduction_manquante_retombe_sur_le_francais_sans_echouer() -> void:
	var manquantes: Array[String] = Textes.cles_sans_traduction(TEMOIN)
	check(manquantes.has(TROU_TEMOIN),
		"préalable ÉPINGLÉ : « %s » est absente de la locale témoin À DESSEIN "
		% TROU_TEMOIN + "(voir en.json, `_doc_trou`) — c'est ce trou qui fait "
		+ "courir le chemin de repli. Reçu : %s" % [manquantes])
	var attendu_fr: String = Textes.t(TROU_TEMOIN)

	Textes.oublier_diagnostic()
	check(Textes.definir_locale(TEMOIN), "bascule vers la locale témoin")
	var replie: String = Textes.t(TROU_TEMOIN)
	check(Textes.definir_locale(Textes.LOCALE_SOURCE), "retour au français")

	check_equal(replie, attendu_fr,
		"A5 — le joueur lit le français, pas un crochet : une traduction "
		+ "absente n'est pas un texte absent")
	check_equal(Textes.absentes_source().size(), 0,
		"A5 — et ce n'est PAS compté comme une faute : %s"
		% [Textes.absentes_source()])
	Textes.oublier_diagnostic()


# --------------------------------------------------------------------------
# A6 — le camp parle par clés, dans la DONNÉE
# --------------------------------------------------------------------------
## `world_v2_camp_liberation.gd` est GELÉ, et son propre commentaire disait :
## « le jour où une localisation arrive, c'est le JSON qu'elle remplace, pas
## cette ligne ». C'est ce que ce cas vérifie.
func test_les_textes_du_camp_sont_des_cles_qui_resolvent() -> void:
	var camps: Array = _json(CAMP_JSON).get("camps", []) as Array
	check(camps.size() > 0, "préalable : la donnée du camp est lisible")
	var vus: int = 0
	for c: Variant in camps:
		var textes: Dictionary = (c as Dictionary).get("textes", {}) as Dictionary
		for nom: Variant in textes.keys():
			# Le JSON documente ses propres champs par des entrées `doc` /
			# `*_doc` — c'est la convention du dépôt, et ce sont des notes de
			# revue, jamais du texte affiché. Le premier passage rouge les
			# comptait : un test qui exige une clé de traduction pour un
			# commentaire ne mesure pas ce qu'il annonce.
			var champ: String = String(nom)
			if champ == "doc" or champ.ends_with("_doc"):
				continue
			var valeur: String = String(textes[nom])
			vus += 1
			check(Textes.ressemble_a_une_cle(valeur),
				"A6 — `textes/%s` doit porter une CLÉ, pas du texte : « %s »"
				% [nom, valeur])
			check(Textes.brut(valeur, Textes.LOCALE_SOURCE) != "",
				"A6 — et la clé « %s » doit exister dans la table source" % valeur)
	check(vus >= 2,
		"préalable NON VACUITÉ : %d texte(s) de camp inspecté(s)" % vus)


# --------------------------------------------------------------------------
# A7 — le HUD résout la clé, et laisse passer l'hérité
# --------------------------------------------------------------------------
func test_le_hud_traduit_une_cle_et_laisse_passer_un_texte_brut() -> void:
	var shell: CanvasLayer = (load(SHELL) as PackedScene).instantiate() as CanvasLayer
	_tree().root.add_child(shell)
	await _tree().process_frame

	var cle: String = "camp.braise.libere"
	var attendu: String = Textes.t(cle)
	var brut: String = "Un texte hérité, non migré — il doit passer tel quel."
	shell.call("_on_notification", cle)
	shell.call("_on_notification", brut)
	await _tree().process_frame

	var vus: Array[String] = []
	for l: Node in shell.find_children("*", "Label", true, false):
		vus.append((l as Label).text)
	check(vus.has(attendu),
		"A7 — le HUD affiche le FRANÇAIS « %s », pas la clé : %s"
		% [attendu, vus])
	check(not vus.has(cle),
		"A7 — et la clé nue n'apparaît nulle part à l'écran : %s" % [vus])
	check(vus.has(brut),
		"A7 — un texte non migré traverse inchangé : sans ce bras, la "
		+ "migration devrait être totale ou nulle. Reçu : %s" % [vus])

	_tree().root.remove_child(shell)
	shell.queue_free()
	await _tree().process_frame


# --------------------------------------------------------------------------
# A8 — la loi : aucune porte `notify` ne gagne de texte joueur cru
# --------------------------------------------------------------------------
func test_aucune_nouvelle_porte_notify_ne_porte_de_texte_ecrit_en_dur() -> void:
	var compte: Dictionary = {}
	for chemin: String in _scripts():
		var n: int = 0
		for ligne: String in _lire(chemin).split("\n"):
			var nu: String = ligne.strip_edges()
			if nu.begins_with("#"):
				continue
			var i: int = nu.find("\"notify\"")
			while i >= 0:
				var reste: String = nu.substr(i + 8).strip_edges()
				# `call("notify", "…` — un littéral SUIT la virgule.
				if reste.begins_with(","):
					var apres: String = reste.substr(1).strip_edges()
					if apres.begins_with("\""):
						# UNE CLÉ N'EST PAS DU TEXTE. Sans cette distinction,
						# migrer un site le laisserait compté et la loi
						# punirait le travail qu'elle demande — trouvé par le
						# passage vert partiel, pas par relecture.
						var fin: int = apres.find("\"", 1)
						var contenu: String = apres.substr(1, fin - 1) \
							if fin > 0 else ""
						if not Textes.ressemble_a_une_cle(contenu):
							n += 1
				i = nu.find("\"notify\"", i + 1)
		if n > 0:
			compte[chemin.trim_prefix("res://")] = n

	check(compte.size() > 0,
		"préalable NON VACUITÉ : la loi scanne bien quelque chose — %d "
		% compte.size() + "fichier(s) trouvé(s). Zéro signalerait un scanner "
		+ "cassé, pas un dépôt propre")

	for fichier: String in compte.keys():
		var plafond: int = int(PLAFOND_NOTIFY.get(fichier, 0))
		check(int(compte[fichier]) <= plafond,
			"A8 — « %s » porte %d texte(s) joueur écrit(s) en dur pour un "
			% [fichier, int(compte[fichier])]
			+ "plafond de %d. Un texte joueur neuf passe par une CLÉ : " % plafond
			+ "ajoutez-la dans resources/localisation/fr.json et appelez "
			+ "Textes.t(). Si le plafond doit vraiment monter, c'est une "
			+ "décision de revue, pas une modification de test")
