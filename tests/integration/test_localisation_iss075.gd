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
##   A8 la loi : aucune porte `notify` ne gagne de texte joueur cru ;
##   A9 le détecteur général : les textes joueur écrits en dur, TOUTES portes
##      confondues, sont comptés par fichier et « ça ne monte pas ».
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

	var rendu: String = Textes.t(fantome)
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
## REFONTE 2026-08-30 (contre-mesure de revue). L'ancien comptage lisait la
## ligne à la main et laissait passer DEUX contournements : un littéral entre
## apostrophes SIMPLES (`call("notify", 'Texte')` — il exigeait un guillemet
## double), et un littéral portant un \" échappé (contenu tronqué au premier
## guillemet). Le comptage passe désormais par le lexer d'A9, qui ferme les
## deux. Mesuré avant refonte : les comptes restent EXACTEMENT égaux aux
## plafonds — aucun contournement n'était en service. L'appel réparti sur
## deux lignes reste un angle mort DÉCLARÉ (docs/LOCALISATION.md) : le
## littéral porte alors une ligne d'ouverture sans « notify », et c'est A9
## qui l'attrape par son contenu.
static func compter_notify(source: String) -> int:
	var n: int = 0
	for lit: Dictionary in extraire_litteraux(source):
		var texte: String = String(lit["texte"])
		if texte == "notify":
			continue
		var ctx: String = String(lit["contexte"])
		if not (ctx.contains("\"notify\"") or ctx.contains("'notify'")):
			continue
		# `call("notify", "…")` — le littéral SUIT une virgule.
		if String(lit["precede"]) != ",":
			continue
		# UNE CLÉ N'EST PAS DU TEXTE. Sans cette distinction, migrer un site
		# le laisserait compté et la loi punirait le travail qu'elle demande
		# — trouvé par le passage vert partiel, pas par relecture.
		if Textes.ressemble_a_une_cle(texte):
			continue
		n += 1
	return n


func test_aucune_nouvelle_porte_notify_ne_porte_de_texte_ecrit_en_dur() -> void:
	# NON-VACUITÉ PAR CONTRÔLE NÉGATIF JOUÉ, plus par compte non nul :
	# l'ancienne assertion `compte.size() > 0` rendait la loi ROUGE le jour
	# où la dette tomberait à zéro — elle punissait son propre achèvement.
	check_equal(compter_notify("bus.call(\"notify\", \"Un texte tout neuf.\")"),
		1, "A8 — contrôle : un littéral cru sur la porte compte un")
	check_equal(compter_notify("bus.call(\"notify\", 'Entre apostrophes.')"),
		1, "A8 — contrôle : les apostrophes simples ne contournent plus")
	check_equal(
		compter_notify("bus.call(\"notify\", \"a dit \\\"stop\\\" — fin.\")"),
		1, "A8 — contrôle : un guillemet échappé ne tronque plus le littéral")
	check_equal(compter_notify("bus.call(\"notify\", \"cle.deja.migree\")"),
		0, "A8 — contrôle : une clé migrée ne compte pas")
	check_equal(compter_notify("bus.call(\"notify\", message)"),
		0, "A8 — contrôle : le littéral porté par variable relève d'A9")

	var compte: Dictionary = {}
	for chemin: String in _scripts():
		var n: int = compter_notify(_lire(chemin))
		if n > 0:
			compte[chemin.trim_prefix("res://")] = n

	for fichier: String in compte.keys():
		var plafond: int = int(PLAFOND_NOTIFY.get(fichier, 0))
		check(int(compte[fichier]) <= plafond,
			"A8 — « %s » porte %d texte(s) joueur écrit(s) en dur pour un "
			% [fichier, int(compte[fichier])]
			+ "plafond de %d. Un texte joueur neuf passe par une CLÉ : " % plafond
			+ "ajoutez-la dans resources/localisation/fr.json et appelez "
			+ "Textes.t(). Si le plafond doit vraiment monter, c'est une "
			+ "décision de revue, pas une modification de test")


## ==========================================================================
## A9 — LE DÉTECTEUR GÉNÉRAL DE TEXTE JOUEUR (tranche gameplay_shell, 2026-08-30)
## ==========================================================================
## Pourquoi A8 ne suffisait pas, MESURÉ sur `scripts/ui/gameplay_shell.gd` :
## le compteur en prose de `docs/LOCALISATION.md` annonçait 39 littéraux
## joueur ; le détecteur ci-dessous en trouve 76. Les cinq formes qui
## échappaient au comptage (et à la porte A8) :
##   1. un texte SANS accent — « Cuisiner », « CUISINE », « Mains nues »,
##      « Arc Link » : l'ancien compteur exigeait un caractère accentué ;
##   2. une valeur de table StringName→String affichée telle quelle —
##      les quatre tables du HUD portaient 35 entrées comptées zéro ;
##   3. une chaîne entre apostrophes droites, ou triple-quotes multiligne ;
##   4. le tiret cadratin (—) ou l'apostrophe (droite entre lettres, ou
##      typographique ’) comme SEUL signal de français ;
##   5. le littéral posé dans une variable puis affiché deux lignes plus bas.
##
## Le détecteur est un petit lexer : il suit les chaînes (', ", triples,
## échappements), ignore les commentaires HORS chaîne, retient le caractère
## qui précède (une valeur de table suit « : »), la ligne d'ouverture (les
## portes d'affichage et les marqueurs de diagnostic s'y lisent) et la
## fonction englobante (`prompt_verb()` ne rend QUE du texte joueur).
##
## Ce qu'il assume de NE PAS attraper, dit franchement : un mot unique tout
## en minuscules sans accent hors porte d'affichage (« ouvrir » posé dans une
## variable), et une valeur de table écrite seule sur sa ligne, sous sa clé.
## Un garde-fou qui devinerait au-delà produirait des faux rouges, et un
## garde-fou à faux rouges finit désarmé (PROMPT4 §1.2).
##
## `tests/unit/test_localisation_iss075_detecteur.gd` éprouve chaque forme
## sur des sources synthétiques — y compris celles qui doivent compter ZÉRO.

const LETTRES_ACCENTUEES: String = "àâäéèêëîïôöùûüçœÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒ"
const MAJUSCULES_ACCENTUEES: String = "ÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒ"
## Un caractère qui n'existe pas dans un identifiant technique : sa seule
## présence signe un texte destiné à des yeux français.
const SIGNAUX_FRANCAIS: String = "àâäéèêëîïôöùûüçœÀÂÄÉÈÊËÎÏÔÖÙÛÜÇŒ«»…’—"
## Une ligne qui parle au développeur, jamais au joueur. Mêmes exclusions que
## l'inventaire officiel (`tools/inventaire_textes_joueur.py`), plus les
## collecteurs d'audit constatés dans le dépôt (`problems.append`, `_fail_*`).
const MARQUEURS_DIAGNOSTIC: Array[String] = [
	"push_error", "push_warning", "printerr", "print(", "printt(",
	"print_debug", "print_rich", "assert(", "check(", "check_equal(",
	"check_approx(", "problems.append", "problemes.append", "erreurs.append",
	"errors.append", "_fail_", "_fail(",
]
## Une ligne dont la destination est l'écran : un mot unique y suffit.
const PORTES_AFFICHAGE: Array[String] = [
	".text", "tooltip_text", "_on_notification(", "_announce_resonance(",
	"\"notify\"",
]

## DETTE MESURÉE le 2026-08-30 par ce détecteur même (346 littéraux, 66
## fichiers, `scripts/tools/` exclus — hors build joué). La loi est « ça ne
## monte pas » ; descendre est libre ; un fichier absent vaut ZÉRO.
## `gameplay_shell.gd` vaut 0 : c'est la tranche migrée d'ISS-075.
const PLAFOND_TEXTES: Dictionary = {
	"scripts/ai/utility_brain.gd": 1,
	"scripts/boss/boss_arena.gd": 2,
	"scripts/boss/grounding_pylon.gd": 1,
	"scripts/characters/character_model_sockets.gd": 1,
	"scripts/cooking/recipe_rules.gd": 7,
	"scripts/core/asset_registry.gd": 1,
	"scripts/core/audio_manager.gd": 1,
	"scripts/core/latency_probe.gd": 1,
	"scripts/core/scene_flow.gd": 2,
	"scripts/dungeon/antechamber.gd": 3,
	"scripts/dungeon/central_hall.gd": 5,
	"scripts/dungeon/dungeon_room.gd": 1,
	"scripts/dungeon/reset_button.gd": 1,
	"scripts/dungeon/room1_initiation.gd": 4,
	"scripts/dungeon/room2_vertical.gd": 6,
	"scripts/dungeon/room3_relays.gd": 5,
	"scripts/dungeon/room4_battery.gd": 6,
	"scripts/dungeon/room_dressing.gd": 2,
	"scripts/electricity/electric_debug_overlay.gd": 4,
	"scripts/enemies/raider_blue.gd": 3,
	"scripts/interaction/campfire.gd": 1,
	"scripts/interaction/chest.gd": 4,
	"scripts/interaction/ingredient_pickup.gd": 3,
	"scripts/interaction/story_fragment.gd": 2,
	"scripts/interaction/weapon_pickup.gd": 3,
	"scripts/player/player_controller.gd": 5,
	"scripts/save/save_merge_guard.gd": 1,
	"scripts/save/save_system.gd": 1,
	"scripts/ui/gameplay_shell.gd": 0,
	"scripts/ui/main_menu.gd": 5,
	"scripts/ui/options_panel.gd": 27,
	"scripts/ui/victory_screen.gd": 8,
	"scripts/world/citadel_vestibule.gd": 1,
	"scripts/world/discovery_rewards.gd": 14,
	"scripts/world/hamlets.gd": 2,
	"scripts/world/reward_anchor.gd": 6,
	"scripts/world/reward_anchor_audit.gd": 8,
	"scripts/world/riverside_village.gd": 1,
	"scripts/world/training_grounds.gd": 41,
	"scripts/world/valley_caves.gd": 3,
	"scripts/world/valley_landmarks.gd": 6,
	"scripts/world/valley_relics.gd": 6,
	"scripts/world/valley_ruins.gd": 4,
	"scripts/world/valley_territories.gd": 5,
	"scripts/world/valley_undergrounds.gd": 2,
	"scripts/world/valley_wonders.gd": 5,
	"scripts/world/valley_world.gd": 4,
	"scripts/world_v2/poi/abandoned_farm_place.gd": 1,
	"scripts/world_v2/poi/barrow_cemetery_place.gd": 1,
	"scripts/world_v2/poi/conductive_basin_place.gd": 1,
	"scripts/world_v2/poi/ember_raider_camp_place.gd": 1,
	"scripts/world_v2/poi/flower_field_place.gd": 1,
	"scripts/world_v2/poi/forest_shrine_place.gd": 1,
	"scripts/world_v2/poi/overlook_summit_place.gd": 1,
	"scripts/world_v2/poi/riverside_village_place.gd": 12,
	"scripts/world_v2/poi/stone_bridge_place.gd": 4,
	"scripts/world_v2/poi/thunderstruck_tree_place.gd": 1,
	"scripts/world_v2/poi/turquoise_spring_place.gd": 1,
	"scripts/world_v2/poi/watchtower_ruin_place.gd": 1,
	"scripts/world_v2/poi/waterfall_cave_place.gd": 1,
	"scripts/world_v2/poi/world_v2_place_kit.gd": 1,
	"scripts/world_v2/world_v2_cameras_builder.gd": 6,
	"scripts/world_v2/world_v2_camp_liberation.gd": 4,
	"scripts/world_v2/world_v2_dungeon_door.gd": 1,
	"scripts/world_v2/world_v2_encounters_builder.gd": 2,
	"scripts/world_v2/world_v2_root.gd": 4,
}


static func _lettre(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") \
		or LETTRES_ACCENTUEES.contains(c)


## Deux lettres consécutives : « ok » est un mot, « %s » et « \n » n'en sont pas.
static func _a_mot(s: String) -> bool:
	var suite: int = 0
	for i: int in range(s.length()):
		suite = suite + 1 if _lettre(s[i]) else 0
		if suite >= 2:
			return true
	return false


static func _a_lettre(s: String) -> bool:
	for i: int in range(s.length()):
		if _lettre(s[i]):
			return true
	return false


static func _a_majuscule(s: String) -> bool:
	for i: int in range(s.length()):
		var c: String = s[i]
		if (c >= "A" and c <= "Z") or MAJUSCULES_ACCENTUEES.contains(c):
			return true
	return false


static func _signal_francais(s: String) -> bool:
	for i: int in range(s.length()):
		if SIGNAUX_FRANCAIS.contains(s[i]):
			return true
	# L'apostrophe DROITE entre deux lettres : l'axe, s'éveille, L'ORAGE.
	for i: int in range(1, s.length() - 1):
		if s[i] == "'" and _lettre(s[i - 1]) and _lettre(s[i + 1]):
			return true
	return false


## Le lexer. Rend, pour chaque littéral de chaîne du source : son texte BRUT
## (échappements non résolus — le classement n'en a pas besoin), sa ligne
## d'ouverture, le caractère non blanc qui le précède (`&` et `^` sautés :
## une StringName n'est pas une défense), le texte de sa ligne d'ouverture et
## la fonction englobante.
static func extraire_litteraux(source: String) -> Array[Dictionary]:
	var lignes: PackedStringArray = source.split("\n")
	var out: Array[Dictionary] = []
	var fonction: String = ""
	var dans_chaine: bool = false
	var guillemet: String = ""
	var triple: bool = false
	var contenu: String = ""
	var ligne_debut: int = 0
	var precede: String = ""
	for i: int in range(lignes.size()):
		var ligne: String = lignes[i]
		if not dans_chaine:
			var nu: String = ligne.strip_edges()
			if nu.begins_with("func "):
				fonction = nu.substr(5).split("(")[0].strip_edges()
		var col: int = 0
		while col < ligne.length():
			var c: String = ligne[col]
			if dans_chaine:
				if c == "\\":
					contenu += c
					if col + 1 < ligne.length():
						contenu += ligne[col + 1]
					col += 2
					continue
				if triple and ligne.substr(col, 3) == guillemet.repeat(3):
					out.append({"texte": contenu, "ligne": ligne_debut,
						"precede": precede, "contexte": lignes[ligne_debut],
						"fonction": fonction})
					dans_chaine = false
					col += 3
					continue
				if not triple and c == guillemet:
					out.append({"texte": contenu, "ligne": ligne_debut,
						"precede": precede, "contexte": lignes[ligne_debut],
						"fonction": fonction})
					dans_chaine = false
					col += 1
					continue
				contenu += c
				col += 1
				continue
			if c == "#":
				break
			if c == "\"" or c == "'":
				var j: int = col - 1
				while j >= 0 and (ligne[j] == "&" or ligne[j] == "^"
						or ligne[j] == " " or ligne[j] == "\t"):
					j -= 1
				precede = ligne[j] if j >= 0 else ""
				triple = ligne.substr(col, 3) == c.repeat(3)
				guillemet = c
				contenu = ""
				ligne_debut = i
				dans_chaine = true
				col += 3 if triple else 1
				continue
			col += 1
		if dans_chaine:
			if triple:
				contenu += "\n"
			else:
				# Chaîne simple non fermée en fin de ligne : source invalide —
				# refermer pour ne pas avaler le reste du fichier.
				dans_chaine = false
	return out


## -> &"joueur" | &"developpeur" | &"technique"
static func classer_litteral(texte: String, precede: String, contexte: String,
		fonction: String) -> StringName:
	if texte.begins_with("res://") or texte.begins_with("user://"):
		return &"technique"
	# Une clé migrée est une clé, pas un texte : c'est ce qui permet à la
	# migration de faire BAISSER le compte au lieu de le déplacer.
	if Textes.ressemble_a_une_cle(texte):
		return &"technique"
	if texte.contains("/") and not texte.contains(" "):
		return &"technique"  # chemin de nœud (« Centerer/Plate/… »)
	if not (_a_mot(texte) or (_signal_francais(texte) and _a_lettre(texte))):
		return &"technique"  # symboles (◇), formats purs (%s  ×%d), suffixes
	for marqueur: String in MARQUEURS_DIAGNOSTIC:
		if contexte.contains(marqueur):
			return &"developpeur"
	if _signal_francais(texte):
		return &"joueur"
	if texte.contains(" ") and _a_mot(texte):
		return &"joueur"
	if _a_mot(texte) and _a_majuscule(texte):
		for porte: String in PORTES_AFFICHAGE:
			if contexte.contains(porte):
				return &"joueur"
		if precede == ":":
			return &"joueur"  # valeur de table — « &"attack": "Attaque" »
	if _a_mot(texte) and fonction == "prompt_verb":
		# `prompt_verb()` ne rend QUE du texte d'invite : même « ouvrir » nu
		# y est du texte joueur. C'était un angle mort DÉCLARÉ de la porte A8.
		return &"joueur"
	# Un mot unique en minuscules sur une porte d'affichage reste du texte
	# joueur ; sans majuscule ni espace il est indiscernable d'un identifiant
	# (« name » dans result.get). Angle assumé, documenté en tête de section.
	if _a_mot(texte) and not _a_majuscule(texte):
		return &"technique"
	return &"technique"


static func compter_joueur(source: String) -> int:
	var n: int = 0
	for lit: Dictionary in extraire_litteraux(source):
		if classer_litteral(String(lit["texte"]), String(lit["precede"]),
				String(lit["contexte"]), String(lit["fonction"])) == &"joueur":
			n += 1
	return n


func test_aucun_nouveau_texte_joueur_ecrit_en_dur_dans_le_code() -> void:
	var compte: Dictionary = {}
	var total: int = 0
	for chemin: String in _scripts():
		if chemin.begins_with("res://scripts/tools/"):
			continue  # hors build joué — inventorié, pas gardé (comme A8)
		var n: int = compter_joueur(_lire(chemin))
		if n > 0:
			compte[chemin.trim_prefix("res://")] = n
			total += n
	check(compte.size() >= 10 and total >= 100,
		"préalable NON VACUITÉ : le détecteur voit %d littéral(aux) joueur "
		% total + "dans %d fichier(s) — un compte effondré signalerait un "
		% compte.size() + "détecteur cassé, pas un dépôt soudain propre")

	check_equal(int(compte.get("scripts/ui/gameplay_shell.gd", 0)), 0,
		"A9 — la tranche ISS-075 est migrée : gameplay_shell.gd ne porte "
		+ "plus AUCUN texte joueur écrit en dur ; un texte neuf passe par "
		+ "une clé de resources/localisation/fr.json")

	for fichier: String in compte.keys():
		var plafond: int = int(PLAFOND_TEXTES.get(fichier, 0))
		check(int(compte[fichier]) <= plafond,
			"A9 — « %s » porte %d texte(s) joueur écrit(s) en dur pour un "
			% [fichier, int(compte[fichier])]
			+ "plafond mesuré de %d. Un texte joueur neuf passe par une " % plafond
			+ "CLÉ (resources/localisation/fr.json + Textes.t()). Monter un "
			+ "plafond est une décision de revue, pas une retouche de test")
