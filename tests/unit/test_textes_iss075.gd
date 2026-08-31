## ISS-075 voie B — LES TROIS DÉFAUTS MESURÉS, ET LA MIGRATION DU HUD.
##
## Ce fichier garde dix propriétés que rien ne gardait — trois défauts mesurés,
## l'interdiction du chemin par frame, et six garanties nées de la migration
## elle-même (dont deux d'un ROUGE non planifié, §4 et §8 du journal) :
##
##   B1 un chargement RATÉ ne se mémorise pas en succès (forme d'ISS-071) ;
##   B2 `brut()` ne construit pas un `Dictionary` à chaque appel ;
##   B3 les étiquettes rafraîchies en boucle passent par la garde `_set_label` ;
##   B4 le chemin PAR FRAME ne gagne aucun `Textes.t()` ;
##   B5 le français rendu est OCTET POUR OCTET celui d'avant migration, et
##      aucun échappement GDScript n'a traversé la génération de la table ;
##   B6 toute clé citée par le HUD existe réellement dans la table source ;
##   B7 les tables de libellés portent des CLÉS, pas du texte ;
##   B8 aucun tag de reprise ne peut être traduit par accident ;
##   B9 les deux étiquettes de compte s'affichent vraiment, de la clé au Label ;
##   B10 le français qui RESTE ne reste que là où traduire est interdit.
##
## POURQUOI CERTAINS CAS LISENT LE CODE SOURCE. B2, B3, B4 et B7 portent sur
## des propriétés qu'aucune observation d'exécution ne distingue : une
## allocation de `Dictionary` jetée aussitôt, une écriture de `Label` redondante
## et un appel de traduction à 60 Hz produisent exactement le même écran que
## leur version correcte. Ce qu'ils changent est le COÛT, pas le rendu. Un test
## qui prétendrait les mesurer par chronométrage serait une tolérance qui
## absout (tests/CLAUDE.md, mode 3). Le contrat porte donc sur la FORME du code,
## et il est nommé comme tel — pas déguisé en test de comportement.
##
## LIMITE ASSUMÉE, écrite ici plutôt que découverte plus tard : B1 vérifie que
## le chemin d'échec ne produit rien (exécution) et que le drapeau n'est pas
## posé avant le travail (source). Provoquer un vrai `DirAccess.open` nul
## demanderait de casser le dépôt ; le couple des deux cas couvre le défaut,
## aucun des deux seul ne le couvre.
extends GateTestCase

const SHELL_GD: String = "res://scripts/ui/gameplay_shell.gd"
const TEXTES_GD: String = "res://scripts/localisation/textes.gd"
const FR_JSON: String = "res://resources/localisation/fr.json"

## Le français attendu, TRANSCRIT À LA MAIN depuis l'état d'avant migration.
##
## C'est le seul bras qui prouve quelque chose. La table `fr.json` a été
## GÉNÉRÉE depuis les littéraux d'origine ; comparer une génération à sa propre
## source serait l'auto-comparaison décrite dans `tests/CLAUDE.md` — verte quoi
## qu'il arrive. Ces quatorze valeurs sont donc une TROISIÈME copie, écrite
## séparément, choisie parmi celles dont un autre test dépend déjà et celles
## qu'un remaniement abîmerait sans bruit.
const FRANCAIS_ATTENDU: Dictionary = {
	"hud.invite.gabarit": "E — %s",
	"hud.arme.mains_nues": "Mains nues",
	"hud.inventaire.titre": "INVENTAIRE",
	"hud.fleches.compte": "Flèches : %d",
	"menu.pause.commandes": "Commandes",
	"cuisine.action.cuisiner": "Cuisiner",
	"cuisine.reserve_pleine": "Réserve de plats pleine",
	"cuisine.apercu.instable": "\n(mélange instable : le soin est fortement réduit)",
	"buff.endurance.nom": "Endurance",
	"boss.nom": "GARDIEN DE L'ORAGE",
	"boss.phase.dead": "Silence",
	"boss.phase.overload": "SURCHARGE — le métal renvoie",
	"resonance.refus.trop_loin": "Les deux ports sont trop écartés",
	"resonance.pulse.aucune_cible": "Impulsion — aucune cible à portée",
}

## Les étiquettes réécrites en boucle. Les deux premières à `HUD_TEXT_REFRESH`
## (dix fois par seconde) ; la troisième l'était aussi et n'était nommée nulle
## part — trouvée en lisant `_process`, pas en lisant le brief.
const RAFRAICHIES_EN_BOUCLE: Array[String] = [
	"_refresh_weapon_text", "_refresh_buff_label", "_refresh_boss_bar",
]

## Racine du chemin par frame. `_process` l'appelle SANS accumulateur.
const RACINE_PAR_FRAME: String = "_refresh_resonance_hud"


func _lire(chemin: String) -> String:
	var f: FileAccess = FileAccess.open(chemin, FileAccess.READ)
	return "" if f == null else f.get_as_text()


## Le corps d'une fonction : de sa signature jusqu'à la prochaine déclaration
## au niveau module. Suffisant ici, et volontairement simple.
func _corps(source: String, nom: String) -> String:
	var lignes: PackedStringArray = source.split("\n")
	var dedans: bool = false
	var out: PackedStringArray = PackedStringArray()
	for l: String in lignes:
		if l.begins_with("func " + nom + "(") \
				or l.begins_with("static func " + nom + "("):
			dedans = true
			continue
		if dedans:
			if l != "" and not l.begins_with("\t") and not l.begins_with(" "):
				break
			out.append(l)
	return "\n".join(out)


## Les fonctions appelées depuis `nom`, transitivement, dans ce fichier.
func _cloture(source: String, nom: String) -> Array[String]:
	var vus: Array[String] = []
	var pile: Array[String] = [nom]
	while not pile.is_empty():
		var f: String = pile.pop_back()
		if vus.has(f):
			continue
		vus.append(f)
		var corps: String = _corps(source, f)
		if corps == "":
			continue
		for autre: String in _noms_de_fonctions(source):
			if not vus.has(autre) and corps.contains(autre + "("):
				pile.append(autre)
	return vus


func _noms_de_fonctions(source: String) -> Array[String]:
	var out: Array[String] = []
	for l: String in source.split("\n"):
		var nu: String = l
		if nu.begins_with("static func "):
			nu = nu.substr(12)
		elif nu.begins_with("func "):
			nu = nu.substr(5)
		else:
			continue
		var p: int = nu.find("(")
		if p > 0:
			out.append(nu.substr(0, p))
	return out


# --------------------------------------------------------------------------
# B1 — un chargement raté ne se mémorise PAS en succès
# --------------------------------------------------------------------------
## LA FORME EXACTE D'ISS-071. La première rédaction posait `_charge = true`
## AVANT le balayage : si `DirAccess.open` rendait `null`, le drapeau restait
## vrai pour tout le processus, `_tables` restait vide, RIEN NE PLANTAIT, et
## chaque `t()` rendait `⟦clé⟧` jusqu'à la fermeture du jeu. Un échec mémoïsé
## en succès ne se distingue plus d'un succès.
func test_un_chargement_rate_ne_produit_aucune_table() -> void:
	# Le dossier absent fait crier `_charger_depuis` À DESSEIN — même règle que
	# l'A3 du contrat de localisation : l'étape 2 de validate_fast rejette tout
	# `ERROR:` du journal, on éteint l'impression LE TEMPS de l'appel voulu,
	# valeur sauvegardée puis restaurée.
	var imprimait_b1: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	var vide: Dictionary = Textes._charger_depuis("res://ce_dossier_n_existe_pas/")
	Engine.print_error_messages = imprimait_b1
	check(vide.is_empty(),
		"B1 — le chemin d'échec doit rendre une table VIDE, pas une table "
		+ "partielle : c'est ce vide qui fait que le drapeau ne se pose pas. "
		+ "Reçu : %s" % [vide])
	# L'autre bras, sans lequel le premier ne prouverait rien : le chemin
	# NORMAL, lui, produit bien quelque chose. Sans ce cas, un `_charger_depuis`
	# cassé rendrait vide partout et le test ci-dessus resterait vert.
	var plein: Dictionary = Textes._charger_depuis(Textes.DOSSIER)
	check(not plein.is_empty(),
		"préalable NON VACUITÉ : le dossier réel produit des tables — sinon "
		+ "le cas ci-dessus serait vert pour la mauvaise raison")
	check(Textes.t("camp.braise.libere") != "",
		"B1 — et la résolution marche toujours après avoir visé un dossier "
		+ "absent : l'échec n'a rien acquis, donc rien perdu")


func test_le_drapeau_de_cache_se_pose_apres_le_travail_jamais_avant() -> void:
	var corps: String = _corps(_lire(TEXTES_GD), "_charger")
	check(corps != "", "préalable : `_charger` est bien lue dans la source")
	var pose: int = corps.find("_charge = true")
	var travail: int = corps.find("_charger_depuis")
	check(pose > 0 and travail > 0,
		"préalable : les deux repères existent dans `_charger` (pose=%d, "
		% pose + "travail=%d)" % travail)
	check(travail < pose,
		"B1 — `_charge = true` doit venir APRÈS `_charger_depuis`. Posé avant, "
		+ "un dossier illisible se mémorise en succès et le joueur lit ⟦clé⟧ "
		+ "jusqu'à ce qu'il relance le jeu")
	check(corps.contains("is_empty()"),
		"B1 — et la pose est CONDITIONNÉE à un chargement non vide : sans la "
		+ "condition, l'ordre seul ne suffirait pas")


# --------------------------------------------------------------------------
# B2 — `brut()` ne construit pas un Dictionary par appel
# --------------------------------------------------------------------------
## `_tables.get(demandee, {})` : le littéral `{}` est une EXPRESSION, pas une
## valeur repliée. GDScript le compile en `OPCODE_CONSTRUCT_DICTIONARY` et
## l'évalue AVANT l'appel — donc à chaque appel, y compris les 99 % où la
## locale existe et où le défaut ne sert à rien. `brut()` est sous `t()`,
## elle-même sous chaque libellé du HUD : cette passe vient de multiplier ses
## appelants par vingt.
func test_brut_ne_construit_pas_un_dictionnaire_a_chaque_appel() -> void:
	var corps: String = _corps(_lire(TEXTES_GD), "brut")
	check(corps != "", "préalable : `brut` est bien lue dans la source")
	check(not corps.contains(", {})"),
		"B2 — `brut()` ne doit plus porter un littéral `{}` comme valeur par "
		+ "défaut d'un `get` : il est CONSTRUIT à chaque appel. Le test "
		+ "d'appartenance (`has`) ne construit rien")
	check(corps.contains("has("),
		"B2 — et le remplacement est bien un test d'appartenance")
	# Le comportement, lui, ne bouge pas d'un pouce.
	check_equal(Textes.brut("camp.braise.libere", &"locale_inexistante"), "",
		"B2 — une locale inconnue rend toujours le vide, sans bruit")
	check(Textes.brut("camp.braise.libere", Textes.LOCALE_SOURCE) != "",
		"B2 — et une locale connue rend toujours son texte")


# --------------------------------------------------------------------------
# B3 — les étiquettes rafraîchies en boucle passent par la garde
# --------------------------------------------------------------------------
## Écrire `Label.text` invalide la mise en forme et redemande un rendu, que le
## texte ait changé ou non. Trois étiquettes étaient réécrites dix fois par
## seconde avec une valeur presque toujours identique. `_set_label` porte la
## garde ; un appelant qui écrit `.text` directement la contourne sans qu'on
## le voie — c'est CE contournement que ce cas interdit.
func test_les_etiquettes_rafraichies_en_boucle_passent_par_la_garde() -> void:
	var source: String = _lire(SHELL_GD)
	for nom: String in RAFRAICHIES_EN_BOUCLE:
		var corps: String = _corps(source, nom)
		check(corps != "", "préalable : `%s` est bien lue dans la source" % nom)
		check(corps.contains("_set_label("),
			"B3 — `%s` court en boucle : elle doit écrire par `_set_label`" % nom)
		for l: String in corps.split("\n"):
			var nu: String = l.strip_edges()
			if nu.begins_with("#"):
				continue
			check(not nu.contains(".text = "),
				"B3 — `%s` écrit un `.text` sans passer par la garde, ce qui "
				% nom + "annule la garde des autres lignes : « %s »" % nu)
	# Et la garde fait bien ce qu'elle annonce.
	var garde: String = _corps(source, "_set_label")
	check(garde.contains("label.text != text"),
		"B3 — `_set_label` compare AVANT d'écrire : sans la comparaison, y "
		+ "router les appelants ne changerait rien. Reçu : « %s »" % garde.strip_edges())


# --------------------------------------------------------------------------
# B4 — le chemin PAR FRAME ne gagne aucune traduction
# --------------------------------------------------------------------------
## INTERDICTION DURE. `_refresh_resonance_hud` court à CHAQUE frame. Un
## `Textes.t()` sur ce chemin ferait soixante résolutions par seconde et par
## libellé — pour un texte qui ne change qu'au changement d'état. La clôture
## est CALCULÉE ici plutôt qu'écrite à la main : une liste écrite à la main
## dirait la même chose aujourd'hui et se périmerait en silence au premier
## appel déplacé.
func test_le_chemin_par_frame_ne_porte_aucune_traduction() -> void:
	var source: String = _lire(SHELL_GD)
	var cloture: Array[String] = _cloture(source, RACINE_PAR_FRAME)
	check(cloture.size() >= 3,
		"préalable NON VACUITÉ : la clôture depuis `%s` porte %d fonction(s) "
		% [RACINE_PAR_FRAME, cloture.size()]
		+ "— une clôture d'une seule entrée signalerait un lecteur cassé, pas "
		+ "un chemin propre : %s" % [cloture])
	check(cloture.has("_resonance_action_line") \
			and cloture.has("_resonance_state_line"),
		"préalable ÉPINGLÉ : la clôture attrape bien les deux fabricants de "
		+ "libellés. Si elle les rate, le cas ci-dessous ne garde RIEN : %s"
		% [cloture])
	for nom: String in cloture:
		var corps: String = _corps(source, nom)
		check(not corps.contains("Textes.t("),
			"B4 — `%s` est atteinte depuis `%s`, donc courue à chaque frame : "
			% [nom, RACINE_PAR_FRAME] + "elle ne peut pas appeler `Textes.t()`. "
			+ "Résoudre au changement de valeur, pas à chaque affichage")


# --------------------------------------------------------------------------
# B5 — le français rendu est octet pour octet celui d'avant migration
# --------------------------------------------------------------------------
func test_le_francais_rendu_est_inchange() -> void:
	check(Textes.definir_locale(Textes.LOCALE_SOURCE),
		"préalable : la locale est remise à la source. Le runner trie les "
		+ "chemins res:// COMPLETS, donc un fichier antérieur a pu basculer la "
		+ "locale et la laisser ainsi (tests/CLAUDE.md, couplage par l'ordre)")
	for cle: String in FRANCAIS_ATTENDU.keys():
		check_equal(Textes.t(cle), String(FRANCAIS_ATTENDU[cle]),
			"B5 — « %s » doit rendre EXACTEMENT le texte d'avant migration. "
			% cle + "Une différence, fût-elle un espace, casse les pins "
			+ "d'affichage des autres suites")


## ROUGE NON PLANIFIÉ, ARCHIVÉ. Ce cas est né d'un échec réel, pas d'une
## relecture. La table `fr` a été GÉNÉRÉE depuis les littéraux du fichier
## d'origine — et un littéral GDScript porte ses ÉCHAPPEMENTS : `"\n(mélange…"`
## est une séquence de deux caractères dans la source, que le moteur décode en
## un saut de ligne. Recopiée telle quelle dans du JSON, elle redevenait deux
## caractères, et trois libellés — dont tout le panneau de détail d'une arme —
## affichaient un `\n` visible au joueur. Le pin transcrit à la main l'a
## attrapé ; une comparaison de la table à sa propre source ne l'aurait jamais
## vu, parce que les deux auraient porté la même erreur.
func test_aucune_valeur_ne_porte_un_echappement_non_decode() -> void:
	var brut: String = _lire(FR_JSON)
	var table: Variant = JSON.parse_string(brut)
	check(table is Dictionary, "préalable : fr.json est un objet JSON lisible")
	var vues: int = 0
	for cle: Variant in (table as Dictionary).keys():
		var nom: String = String(cle)
		if nom.begins_with("_"):
			continue
		vues += 1
		var valeur: String = String((table as Dictionary)[cle])
		# Un vrai saut de ligne s'écrit `\n` en JSON et se PARSE en UN
		# caractère. En trouver deux signifie qu'un échappement GDScript a
		# traversé la génération sans être décodé.
		check(not valeur.contains("\\n") and not valeur.contains("\\t"),
			"B5 — « %s » porte un échappement non décodé : le joueur lirait "
			% nom + "les deux caractères au lieu du saut de ligne. Valeur : %s"
			% valeur)
	check(vues >= 30,
		"préalable NON VACUITÉ : %d valeur(s) inspectée(s) dans fr.json" % vues)


# --------------------------------------------------------------------------
# B6 — toute clé citée par le HUD existe dans la table source
# --------------------------------------------------------------------------
## Le filet anti-régression de la migration : une clé mal orthographiée ne
## plante pas, elle affiche ⟦clé⟧ à un joueur. Ici elle rougit.
func test_chaque_cle_citee_par_le_hud_resout() -> void:
	var source: String = _lire(SHELL_GD)
	var vues: int = 0
	var i: int = source.find("Textes.t(\"")
	while i >= 0:
		var debut: int = i + 10
		var fin: int = source.find("\"", debut)
		var cle: String = source.substr(debut, fin - debut)
		vues += 1
		check(Textes.ressemble_a_une_cle(cle),
			"B6 — « %s » est passée à `Textes.t()` mais n'a pas la FORME "
			% cle + "d'une clé : elle ne sera jamais cherchée dans la table")
		check(Textes.brut(cle, Textes.LOCALE_SOURCE) != "",
			"B6 — « %s » est citée par le HUD mais absente de fr.json : le "
			% cle + "joueur lirait ⟦%s⟧" % cle)
		i = source.find("Textes.t(\"", fin)
	check(vues >= 30,
		"préalable NON VACUITÉ : %d clé(s) citée(s) par le HUD. Un compte bas "
		% vues + "signalerait un lecteur cassé, pas une migration finie")


# --------------------------------------------------------------------------
# B7 — les tables de libellés portent des clés, pas du texte
# --------------------------------------------------------------------------
## D-065. Une table `const` est évaluée au chargement du script, donc AVANT
## qu'une bascule de langue ait pu avoir lieu : y mettre du français résolu
## figerait la langue. Et surtout, c'est le SITE D'USAGE qui sait s'il a le
## droit d'appeler `t()` — voir B4.
func test_les_tables_de_libelles_portent_des_cles() -> void:
	var source: String = _lire(SHELL_GD)
	var tables: Array[String] = [
		"BUFF_LABELS", "BOSS_PHASE_LABELS", "RESONANCE_REFUSALS",
	]
	for nom: String in tables:
		var debut: int = source.find("const " + nom)
		check(debut > 0, "préalable : la table `%s` existe" % nom)
		var fin: int = source.find("\n}", debut)
		var bloc: String = source.substr(debut, fin - debut)
		var valeurs: int = 0
		for l: String in bloc.split("\n"):
			var nu: String = l.strip_edges()
			if not nu.contains(": \""):
				continue
			var v: String = nu.substr(nu.find(": \"") + 3)
			v = v.substr(0, v.find("\""))
			valeurs += 1
			check(Textes.ressemble_a_une_cle(v),
				"B7 — `%s` doit porter des CLÉS : « %s » n'en est pas une"
				% [nom, v])
			check(Textes.brut(v, Textes.LOCALE_SOURCE) != "",
				"B7 — et la clé « %s » de `%s` doit exister dans fr.json"
				% [v, nom])
		check(valeurs >= 3,
			"préalable NON VACUITÉ : `%s` porte %d valeur(s) lue(s)"
			% [nom, valeurs])
	# Le REPLI est conservé : une entrée absente rend l'identifiant brut, et
	# `test_resonance_hud.gd` en dépend pour un verdict inédit.
	check(_corps(source, "_libelle").contains("String(id)"),
		"B7 — `_libelle` doit conserver le repli sur l'identifiant brut : le "
		+ "perdre afficherait une plaque vide au lieu d'un diagnostic")


# --------------------------------------------------------------------------
# B10 — le français qui RESTE ne reste que là où traduire est interdit
# --------------------------------------------------------------------------
## CE CAS EST NÉ D'UN DÉFAUT RÉEL DE LA MIGRATION, pas d'une relecture. La carte
## clé→littéral était indexée par NUMÉRO DE LIGNE, et une ligne en portait DEUX :
##
##     _on_notification("Cuisiné : %s" % String(result.get("name", "Plat")))
##
## Le second littéral écrasait le premier dans la carte. Résultat : la clé
## `cuisine.plat_cuisine` a reçu « Plat », et le vrai gabarit du message est
## resté écrit en dur. Rien ne rougissait — la clé existait, elle résolvait,
## `B5` ne l'épinglait pas et `B6` ne vérifie que l'existence.
##
## Le contrat qui manquait est celui-ci, et il n'est pas une liste gelée : il
## DÉRIVE l'autorisation. Du français peut rester dans ce fichier, mais
## seulement là où `B4` interdit précisément de le traduire — le chemin par
## frame. Partout ailleurs, un littéral français est du travail non fait.
##
## LIMITE NOMMÉE : le détecteur ne voit que le français ACCENTUÉ ou deux mots
## séparés par une espace. « Mains nues » serait vu, « Silence » ne le serait
## pas. C'est un fil de détente, pas un classeur ; le classement vit dans
## `tools/classer_textes_joueur.py` et son inventaire.
func test_le_francais_restant_est_confine_au_chemin_par_frame() -> void:
	var source: String = _lire(SHELL_GD)
	var cloture: Array[String] = _cloture(source, RACINE_PAR_FRAME)
	# Une table `const` est « par frame » si son nom paraît dans le corps d'une
	# fonction de la clôture. Les CANDIDATES sont lues dans le fichier, pas
	# écrites ici : une liste de noms gelée dirait la même chose aujourd'hui et
	# raterait la table suivante sans que personne ne le voie.
	var candidates: Array[String] = []
	for ligne_c: String in source.split("\n"):
		if ligne_c.begins_with("const "):
			candidates.append(_premier_mot(ligne_c.substr(6)))
	var tables_par_frame: Array[String] = []
	for nom: String in cloture:
		var corps: String = _corps(source, nom)
		for t: String in candidates:
			if corps.contains(t) and not tables_par_frame.has(t):
				tables_par_frame.append(t)

	var portee: String = ""
	var restes: int = 0
	var confines: int = 0
	for ligne: String in source.split("\n"):
		var nu: String = ligne.strip_edges()
		if ligne.begins_with("func ") or ligne.begins_with("static func "):
			portee = ligne.substr(ligne.find("func ") + 5)
			portee = portee.substr(0, portee.find("("))
		elif ligne.begins_with("const "):
			portee = _premier_mot(ligne.substr(6))
		if nu.begins_with("#"):
			continue
		for texte: String in _litteraux(ligne):
			if not _sent_le_francais(texte):
				continue
			restes += 1
			var autorise: bool = cloture.has(portee) or tables_par_frame.has(portee)
			if autorise:
				confines += 1
			check(autorise,
				"B10 — « %s » (portée `%s`) est du français écrit en dur HORS "
				% [texte, portee] + "du chemin par frame : c'est une migration "
				+ "non faite, pas une exception. Ajoutez la clé dans "
				+ "resources/localisation/fr.json et appelez `Textes.t()`")
	check(restes >= 5,
		"préalable NON VACUITÉ : %d littéral(aux) français trouvé(s). Zéro "
		% restes + "signalerait un lecteur cassé, pas un fichier propre — le "
		+ "bloc Résonance par frame en porte forcément")
	check_equal(confines, restes,
		"B10 — tout le français restant (%d) doit être confiné au chemin par "
		% restes + "frame")


## Le nom qui ouvre une déclaration : `RESONANCE_ACTIONS: Dictionary[…]` ->
## `RESONANCE_ACTIONS`. Coupe au PREMIER délimiteur, pas au dernier — la
## première rédaction prenait `maxi(find(":"), find(" "))` et gardait le
## deux-points, si bien qu'aucune portée `const` ne se reconnaissait.
func _premier_mot(reste: String) -> String:
	var fin: int = reste.length()
	for d: String in [":", " ", "="]:
		var p: int = reste.find(d)
		if p >= 0 and p < fin:
			fin = p
	return reste.substr(0, fin)


## Les littéraux d'une ligne. Suffisant ici : aucun `\"` échappé dans ce fichier.
func _litteraux(ligne: String) -> Array[String]:
	var out: Array[String] = []
	var parts: PackedStringArray = ligne.split("\"")
	var i: int = 1
	while i < parts.size():
		out.append(parts[i])
		i += 2
	return out


## Fil de détente, pas classeur : accent français, ou deux mots séparés d'une
## espace. Volontairement grossier, et sa limite est écrite au-dessus.
func _sent_le_francais(texte: String) -> bool:
	for c: String in ["à", "â", "é", "è", "ê", "ë", "î", "ï", "ô", "ö", "ù",
			"û", "ü", "ç", "É", "È", "Ê", "À", "Î", "Ô", "Û", "Ç"]:
		if texte.contains(c):
			return true
	var mots: PackedStringArray = texte.split(" ")
	if mots.size() < 2:
		return false
	for j: int in range(mots.size() - 1):
		if mots[j].length() >= 2 and _est_alpha(mots[j]) and mots[j + 1] != "" \
				and _est_alpha(mots[j + 1].substr(0, 1)):
			return true
	return false


func _est_alpha(s: String) -> bool:
	for i: int in range(s.length()):
		var c: String = s[i].to_lower()
		if c < "a" or c > "z":
			return false
	return true


# --------------------------------------------------------------------------
# B9 — les deux étiquettes de compte s'affichent VRAIMENT
# --------------------------------------------------------------------------
## `_arrows_label` n'avait AUCUN accesseur de test. La chaîne « Flèches : 8 »
## n'existait que dans un COMMENTAIRE d'en-tête de
## `test_bow_fires_on_left_click.gd`, ce qui ressemble à un pin sans en être
## un : le libellé pouvait changer, ou disparaître, sans que rien ne rougisse.
## Ce cas est le premier à le regarder — et il traverse la chaîne entière, de
## la clé au pixel logique : `fr.json` -> `Textes.t` -> `%` -> `Label.text`.
func test_les_comptes_de_fleches_et_de_plats_s_affichent() -> void:
	var arbre: SceneTree = Engine.get_main_loop() as SceneTree
	var shell: CanvasLayer = (load("res://scenes/ui/GameplayShell.tscn") \
		as PackedScene).instantiate() as CanvasLayer
	arbre.root.add_child(shell)
	await arbre.process_frame

	shell.call("_on_arrows_changed", 8)
	shell.call("_on_meals_changed", 3)
	await arbre.process_frame

	check_equal(String(shell.call("arrows_text")), "Flèches : 8",
		"B9 — le compte de flèches s'écrit en toutes lettres à l'écran")
	check_equal(String(shell.call("meals_text")), "Plats : 3  (F)",
		"B9 — et celui des plats aussi, avec sa touche de raccourci")

	# L'autre bras : le libellé SUIT la valeur. Sans lui, une étiquette figée
	# sur « Flèches : 8 » passerait le cas ci-dessus.
	shell.call("_on_arrows_changed", 0)
	await arbre.process_frame
	check_equal(String(shell.call("arrows_text")), "Flèches : 0",
		"B9 — et il suit la valeur plutôt que d'être figé")

	arbre.root.remove_child(shell)
	shell.queue_free()
	await arbre.process_frame


# --------------------------------------------------------------------------
# B8 — aucun tag de reprise ne peut être traduit par accident
# --------------------------------------------------------------------------
## `traduire_si_cle()` traduit TOUT ce qui a la forme d'une clé. Un tag de
## reprise qui prendrait cette forme partirait chercher une traduction et
## afficherait ⟦tag⟧, ou pire, un texte. Le tag actuel n'a pas de point, donc
## ne peut pas passer — mais rien ne le garantissait, et ce cas le garantit.
func test_aucun_tag_de_reprise_ne_ressemble_a_une_cle() -> void:
	var tags: Array[String] = [
		"retry_checkpoint", "camp_braise", "dungeon_entrance", "boss_arena",
		"valley_start", "antechamber",
	]
	for tag: String in tags:
		check(not Textes.ressemble_a_une_cle(tag),
			"B8 — le tag de reprise « %s » ne doit PAS avoir la forme d'une "
			% tag + "clé : `traduire_si_cle` le remplacerait par ⟦%s⟧" % tag)
	# L'autre bras : le test sait reconnaître une VRAIE clé, sinon il serait
	# vert même si `ressemble_a_une_cle` rendait toujours faux.
	check(Textes.ressemble_a_une_cle("boss.phase.dead"),
		"préalable : une vraie clé est bien reconnue — sans ce bras, le cas "
		+ "ci-dessus passerait avec une fonction cassée")


## ─────────────────────────────────────────────────────────────────────────────
## B13 — LES DEUX LISTES ÉPINGLÉES SONT DÉRIVÉES DE `_process`, PAS CRUES
##
## Ajouté après une contre-revue qui a REPRODUIT le trou plutôt que de le
## supposer : `RACINE_PAR_FRAME` et `RAFRAICHIES_EN_BOUCLE` étaient des
## constantes écrites à la main. En ajoutant à `_process`, HORS de la branche
## accumulée, un appel vers une fonction neuve portant une traduction, `B4`
## restait VERT. Il gardait UN chemin par frame, pas LE chemin par frame. Et une
## quatrième étiquette rafraîchie à 10 Hz serait née sans garde d'égalité, sans
## que `B3` la voie.
##
## Le geste est le même pour les deux listes parce que l'information est au même
## endroit : le corps de `_process` se coupe en deux à la ligne du `if` de
## l'accumulateur. Ce qui est appelé AVANT court à chaque frame ; ce qui est
## appelé DEDANS court à la cadence `HUD_TEXT_REFRESH`.
##
## ON NE REMPLACE PAS LES CONSTANTES PAR LE CALCUL : on exige qu'elles lui
## soient égales. Les remplacer aurait fait suivre le test au code en silence —
## exactement le défaut qu'on ferme. Épinglé PLUS dérivé PLUS comparé : la
## constante reste lisible dans les messages des autres cas, et la dérivation
## rougit dès que le code s'en écarte.
func test_les_listes_epinglees_sont_egales_a_ce_que_process_appelle() -> void:
	var source: String = _lire(SHELL_GD)
	check(source != "", "B13 préalable : la source du HUD se lit")
	if source == "":
		return
	var corps: String = _corps(source, "_process")
	check(corps != "", "B13 préalable : le corps de `_process` se lit")
	if corps == "":
		return

	# La coupure est reconnue par le NOM de la constante de cadence, jamais par
	# sa valeur ni par un numéro de ligne — les deux dérivent sans prévenir.
	var brutes: PackedStringArray = corps.split("\n")
	var lignes: Array[String] = []
	for l: String in brutes:
		var d: int = l.find("#")
		lignes.append(l if d < 0 else l.substr(0, d))
	var coupure: int = -1
	for i in lignes.size():
		if lignes[i].contains("HUD_TEXT_REFRESH"):
			coupure = i
			break
	check(coupure > 0,
		"B13 préalable ÉPINGLÉ : `_process` porte une branche accumulée "
		+ "reconnaissable à `HUD_TEXT_REFRESH`. Sans elle ce cas ne garde RIEN.")
	if coupure <= 0:
		return

	var avant: Array[String] = []
	var apres: Array[String] = []
	for i in lignes.size():
		for nom: String in _noms_de_fonctions(source):
			var d: int = lignes[i].find(nom + "(")
			# Frontière de mot à gauche : sans elle, « _hud( » serait trouvé à
			# l'intérieur de « _resonance_hud( ». Deux noms du fichier sont déjà
			# suffixes d'un autre — le faux positif n'est pas théorique.
			if d < 0:
				continue
			if d > 0:
				var p: String = lignes[i][d - 1]
				if p == "_" or (p.to_lower() != p.to_upper()) or p.is_valid_int():
					continue
			var cible: Array[String] = avant if i < coupure else apres
			if not cible.has(nom):
				cible.append(nom)

	avant.sort()
	apres.sort()
	var racine_attendue: Array[String] = [RACINE_PAR_FRAME]
	var boucle_attendue: Array[String] = RAFRAICHIES_EN_BOUCLE.duplicate()
	boucle_attendue.sort()

	check_equal(avant, racine_attendue,
		"B13 : ce que `_process` appelle HORS de la branche accumulée doit être "
		+ "exactement la racine par frame épinglée. Un appel neuf ici ferait "
		+ "courir du code à 60 Hz sans que `B4` le voie — scénario reproduit "
		+ "VERT par la contre-revue avant l'existence de ce cas.")
	check_equal(apres, boucle_attendue,
		"B13 : ce que `_process` appelle DANS la branche accumulée doit être "
		+ "exactement la liste des étiquettes rafraîchies à 10 Hz. Une "
		+ "quatrième naîtrait sans garde d'égalité et sans que `B3` la voie.")
