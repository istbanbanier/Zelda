## ISS-075 (tranche gameplay_shell) — LE DÉTECTEUR ÉPROUVÉ SUR PIÈCES.
##
## Le détecteur A9 de `test_localisation_iss075.gd` est lui-même du code, et
## un garde-fou qui n'a jamais rougi ne prouve rien. Chaque cas ci-dessous est
## une SOURCE SYNTHÉTIQUE : ce que le détecteur doit compter, et — aussi
## important — ce qu'il doit refuser de compter. Les cas « qui échappaient »
## sont exactement les cinq formes mesurées sur gameplay_shell.gd, celles qui
## faisaient dire 39 au compteur officiel quand le fichier en portait 76.
##
## Contrats couverts ici : C11 (un texte joueur NEUF codé en dur est détecté)
## et C12 (le détecteur n'est pas contournable par une table).
extends GateTestCase

const SCANNER: GDScript = preload("res://tests/integration/test_localisation_iss075.gd")


func _compte(source: String) -> int:
	return SCANNER.compter_joueur(source)


# --------------------------------------------------------------------------
# D1 — les formes qui échappaient à l'ancien compteur sont comptées (C11)
# --------------------------------------------------------------------------
func test_les_formes_qui_echappaient_au_compteur_sont_comptees() -> void:
	var cas: Array[Array] = [
		["label.text = \"Cuisiner\"", 1,
			"mot unique SANS accent sur une porte d'affichage"],
		["label.text = \"Tout nouveau texte joueur\"", 1,
			"un texte joueur NEUF codé en dur est détecté (C11)"],
		["x.text = \"\"\"Un texte\nsur deux lignes\"\"\"", 1,
			"chaîne triple-quotes multiligne"],
		["var m: String = 'Reprendre la partie'", 1,
			"chaîne entre apostrophes droites (simples quotes)"],
		["var m: String = \"l’arme est prête\"", 1,
			"apostrophe typographique comme seul signal"],
		["var m: String = \"Port retenu — vise\"", 1,
			"tiret cadratin comme seul signal"],
		["label.text = \"Flèches : %d\" % n", 1,
			"chaîne interpolée (%d)"],
		["var message: String = \"Le camp est libéré.\"\n"
			+ "bus.call(\"notify\", message)", 1,
			"littéral posé dans une variable puis affiché — la porte A8 le "
			+ "comptait zéro"],
		["func prompt_verb() -> String:\n\treturn \"ouvrir\"", 1,
			"un verbe d'invite est du texte joueur même nu, sans accent ni "
			+ "majuscule — angle mort déclaré de la porte A8"],
	]
	for c: Array in cas:
		check_equal(_compte(String(c[0])), int(c[1]), "D1 — %s" % String(c[2]))
	check(cas.size() >= 9,
		"préalable NON VACUITÉ : %d forme(s) éprouvée(s)" % cas.size())


# --------------------------------------------------------------------------
# D2 — le détecteur n'est pas contournable par une table (C12)
# --------------------------------------------------------------------------
func test_une_table_ne_contourne_pas_le_detecteur() -> void:
	check_equal(_compte("const T: Dictionary = {\n\t&\"a\": \"Attaque\",\n}"), 1,
		"D2 — une valeur de table StringName→String est du texte joueur : "
		+ "c'est la forme EXACTE des 35 entrées des quatre tables du HUD")
	check_equal(_compte("var t: Dictionary = {&\"a\": \"Trop\"}"), 1,
		"D2 — une table `var` ne contourne pas plus qu'une `const`")
	check_equal(_compte("const T: Dictionary = {\n"
		+ "\t&\"k\": \"Texte de table à plusieurs mots\",\n}"), 1,
		"D2 — valeur multi-mots de table")
	check_equal(_compte("const T: Dictionary = {\n"
		+ "\t&\"k\": &\"Cible perdue\",\n}"), 1,
		"D2 — préfixer la valeur par & (StringName) n'est pas une défense")
	# L'autre bras : les CLÉS de table restent des identifiants.
	check_equal(_compte("const T: Dictionary = {\n"
		+ "\t\"attack\": 12.0,\n\t\"defense\": 3.0,\n}"), 0,
		"D2 — les clés techniques d'une table de réglage ne comptent pas : "
		+ "un détecteur qui les compterait serait désarmé à la première revue")


# --------------------------------------------------------------------------
# D3 — le texte développeur et technique ne compte pas (faux positifs)
# --------------------------------------------------------------------------
func test_le_texte_developpeur_et_technique_ne_compte_pas() -> void:
	var cas: Array[Array] = [
		["push_error(\"le fichier est illisible — voir le journal\")", 0,
			"un journal moteur n'est PAS du texte joueur"],
		["problems.append(\"région EN DOUBLE : %s\" % id)", 0,
			"un collecteur d'audit non plus"],
		["var s: PackedScene = load(\"res://scenes/ui/MainMenu.tscn\")", 0,
			"un chemin de ressource"],
		["(x.get_node(\"Centerer/Plate/Column/Title\") as Label).text = \"TITRE\"",
			1, "le chemin de nœud ne compte pas ; le titre affiché, si"],
		["label.text = Textes.t(\"menu.pause.commandes\")", 0,
			"une clé migrée est une clé, pas un texte — la migration fait "
			+ "BAISSER le compte au lieu de le déplacer"],
		["label.text = \"%s  ×%d\" % [a, b]", 0,
			"un format sans mot n'a rien à traduire"],
		["_on_notification(\"Cuisiné : %s\" % String(result.get(\"name\", \"Plat\")))",
			2, "la clé de dictionnaire « name » ne compte pas ; le texte et "
			+ "son repli « Plat », si"],
		["match effect:\n\t\"attack\":\n\t\treturn 1", 0,
			"un bras de match est un identifiant"],
		["node.name = \"RubyRow\"", 0, "un nom de nœud"],
		["Input.is_action_pressed(\"resonance_pulse\")", 0,
			"une action d'InputMap"],
		["# label.text = \"Un texte joueur dans un commentaire\"", 0,
			"un commentaire n'affiche rien"],
	]
	for c: Array in cas:
		check_equal(_compte(String(c[0])), int(c[1]), "D3 — %s" % String(c[2]))


# --------------------------------------------------------------------------
# D4 — le lexer ne se laisse pas piéger
# --------------------------------------------------------------------------
func test_le_lexer_ne_se_laisse_pas_pieger() -> void:
	check_equal(_compte("label.text = \"Numéro 1 — prêt\""), 1,
		"D4 — préalable : la forme nue compte bien un")
	check_equal(_compte("label.text = \"Numéro #1 — prêt\""), 1,
		"D4 — un dièse DANS la chaîne n'ouvre pas un commentaire")
	check_equal(_compte("label.text = \"Il a dit \\\"va\\\" — allez\""), 1,
		"D4 — un guillemet échappé ne referme pas la chaîne (un seul littéral)")
	check_equal(_compte("var a: String = \"ok\" # \"Un texte joueur ?\""), 0,
		"D4 — un commentaire APRÈS du code reste un commentaire")
	check_equal(_compte("var a: String = 'Mot \"cité\" — fin'"), 1,
		"D4 — des guillemets doubles DANS une chaîne simple quote")


# --------------------------------------------------------------------------
# D5 — le détecteur retrouve la mesure de la tranche sur le VRAI fichier
# --------------------------------------------------------------------------
## Sans ce cas, les cas synthétiques pourraient tous passer pendant que le
## détecteur lit de travers un vrai fichier de 1 600 lignes. La valeur exacte
## vit dans A9 (`PLAFOND_TEXTES`) ; ici on épingle la propriété qui a justifié
## toute la tranche : le fichier migré ne porte plus RIEN, et le détecteur
## y voyait bien quelque chose avant (l'inventaire daté en fait foi).
func test_le_detecteur_lit_le_vrai_gameplay_shell() -> void:
	var f: FileAccess = FileAccess.open(
		"res://scripts/ui/gameplay_shell.gd", FileAccess.READ)
	check(f != null, "préalable : gameplay_shell.gd est lisible")
	if f == null:
		return
	var source: String = f.get_as_text()
	var litteraux: Array[Dictionary] = SCANNER.extraire_litteraux(source)
	check(litteraux.size() >= 100,
		"préalable NON VACUITÉ : le lexer voit %d littéraux dans le fichier "
		% litteraux.size() + "réel — un chiffre effondré signerait un lexer "
		+ "qui décroche en cours de route")
	check_equal(SCANNER.compter_joueur(source), 0,
		"D5 — la tranche est migrée : zéro texte joueur écrit en dur dans "
		+ "gameplay_shell.gd (inventaire du 2026-08-30 : il en portait 76)")
