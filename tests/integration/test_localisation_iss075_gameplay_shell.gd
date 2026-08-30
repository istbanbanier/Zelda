## ISS-075, TRANCHE 2 — gameplay_shell.gd : 76 littéraux joueur migrés, et
## les contrats qui rendent la migration IRRÉVERSIBLE.
##
## Le danger d'une extraction de textes n'est pas d'échouer bruyamment, c'est
## de réussir EN CHANGEANT le jeu : un accent perdu dans un aller-retour JSON,
## un %d qui devient %s dans une langue, un « s » de pluriel oublié, une clé
## nue qui traverse jusqu'à l'écran. Chaque cas ci-dessous ferme un de ces
## chemins, et chacun porte sa non-vacuité : un compte qui prouverait que le
## test a bien inspecté quelque chose.
##
##   C1  le français rendu est l'octet-pour-octet HISTORIQUE (épinglé ici) ;
##   C2  la locale témoin couvre TOUTE la tranche, et diffère du français ;
##   C3  une clé absente de la source reste bruyante (⟦clé⟧) ;
##   C4  les paramètres de format sont identiques dans les deux langues ;
##   C5  le pluriel du Pulse est porté par les clés, plus par le code ;
##   C6  l'Unicode traverse la table intact (accents, ’, —, \n) ;
##   C7  aucune clé brute ne paraît à l'écran (état de construction) ;
##   C7bis les chemins d'EXÉCUTION — notifications, messages du viseur,
##       HUD dynamique, cuisine — ne montrent jamais une clé nue, et la
##       couverture est COMPTÉE (le trou démontré par la contre-revue :
##       C7 seul n'atteignait que les clés posées à la construction) ;
##   C8  le changement de langue à chaud change réellement l'écran ;
##   C9  les tables de localisation partent dans l'export ;
##   C10 la localisation ne touche à aucune clé de sauvegarde ;
##   C13 les replis affichent le jeton brut, jamais un ⟦…⟧ accidentel.
## (C11 et C12 — détection d'un texte neuf, non-contournement par table —
## vivent dans tests/unit/test_localisation_iss075_detecteur.gd.)
extends GateTestCase

const SHELL: String = "res://scenes/ui/GameplayShell.tscn"
const TEMOIN: StringName = &"en"

## LE FRANÇAIS ÉPINGLÉ, OCTET POUR OCTET. Ces littéraux sont la COPIE de ce
## que gameplay_shell.gd affichait avant migration (arbre 8c6955c6, inventaire
## du 2026-08-30). Si une clé rend autre chose, le joueur ne lit plus le même
## jeu — et ce test le dit avant lui.
const FRANCAIS_EPINGLE: Dictionary = {
	"inventaire.titre": "INVENTAIRE",
	"inventaire.conductivite": "Conductivité",
	"inventaire.fermer": "Tab / Échap — Fermer",
	"inventaire.detail.stats": "Dégâts  %.0f\nPortée  %.1f m\nDurabilité  %d / %d",
	"menu.pause.commandes": "Commandes",
	"menu.pause.sensibilite": "%.4f rad/px",
	"hud.fleches": "Flèches : %d",
	"hud.plats": "Plats : %d  (F)",
	"hud.arme.mains_nues": "Mains nues",
	"hud.invite.format": "E — %s",
	"hud.buff.attaque": "Attaque",
	"hud.buff.defense": "Défense",
	"hud.buff.endurance": "Endurance",
	"hud.buff.resist_elec": "Résist. élec.",
	"hud.buff.format": "%s — %d s",
	"cuisine.titre": "CUISINE",
	"cuisine.confirmer": "Cuisiner",
	"cuisine.retirer_dernier": "Retirer le dernier",
	"cuisine.reprendre": "Reprendre",
	"cuisine.reserve_pleine": "Réserve de plats pleine",
	"cuisine.fait": "Cuisiné : %s",
	"cuisine.plat_defaut": "Plat",
	"cuisine.choisir": "Choisis 1 à 5 ingrédients",
	"cuisine.choisir_compte": "Choisis (%d/5) : %s",
	"cuisine.apercu.soin": "%s — soigne %d PV",
	"cuisine.apercu.effet": "\n%s pendant %d s",
	"cuisine.apercu.instable": "\n(mélange instable : le soin est fortement réduit)",
	"cuisine.effet.attack": "Attaque renforcée",
	"cuisine.effet.defense": "Défense renforcée",
	"cuisine.effet.stamina": "Endurance renforcée",
	"cuisine.effet.elec_resist": "Résistance à la foudre",
	"boss.nom": "GARDIEN DE L'ORAGE",
	"boss.phase.intro": "Le Gardien s'éveille",
	"boss.phase.phase1": "Armure chargée",
	"boss.phase.grounded_stun": "Mis à la terre — le noyau est nu",
	"boss.phase.transition12": "L'armure se fend",
	"boss.phase.phase2": "Surcharge",
	"boss.phase.overload": "SURCHARGE — le métal renvoie",
	"boss.phase.transition23": "La tempête monte",
	"boss.phase.phase3": "Tempête",
	"boss.phase.stagger": "Chancelant",
	"boss.phase.dead": "Silence",
	"resonance.action.port": "Arc Link",
	"resonance.action.polarity": "Polarité (Maj : repousser)",
	"resonance.action.material": "Mise à la terre",
	"resonance.action.arc_anchor": "Arc Step",
	"resonance.refus.cooldown": "Bracelet en recharge",
	"resonance.refus.aucune_cible": "Aucune cible",
	"resonance.refus.invalide": "Cible invalide",
	"resonance.refus.hors_portee": "Trop loin",
	"resonance.refus.trop_loin": "Les deux ports sont trop écartés",
	"resonance.refus.pas_de_vue": "Un obstacle coupe le trajet",
	"resonance.refus.pas_metal": "Ce n'est pas du métal",
	"resonance.refus.pas_charge": "Cet objet n'est pas chargé",
	"resonance.refus.trop_lourd": "Trop lourd pour la Polarité",
	"resonance.refus.pas_de_charge": "Rien à mettre à la terre",
	"resonance.refus.pas_au_sol": "Il faut les pieds au sol",
	"resonance.refus.occupe": "Mise à la terre déjà en cours",
	"resonance.refus.obstacle": "Le trajet est barré",
	"resonance.refus.pas_de_sol": "Pas de sol à l'arrivée",
	"resonance.refus.endurance": "Endurance insuffisante",
	"resonance.refus.cible_perdue": "Cible perdue",
	"resonance.refus.interrompu": "Interrompu",
	# La clé PROPRE du verdict &"step" (delta 3) : même texte français que
	# `resonance.action.arc_anchor` aujourd'hui, mais deux contextes
	# d'affichage ne partagent plus une clé — ils doivent pouvoir diverger
	# dans une autre langue sans toucher le code.
	"resonance.message.arc_step": "Arc Step",
	"resonance.message.lien_etabli": "Lien établi",
	"resonance.message.polarite_engagee": "Polarité engagée",
	"resonance.message.pulse_vide": "Impulsion — aucune cible à portée",
	"resonance.message.pulse_une": "Impulsion — %d cible révélée",
	"resonance.message.pulse_plusieurs": "Impulsion — %d cibles révélées",
	"resonance.message.lien_rompu": "Lien rompu",
	"resonance.message.terre_effectuee": "Mise à la terre effectuée",
	"resonance.message.terre_annulee": "Mise à la terre annulée — %s",
	"resonance.viseur.titre": "Bracelet de Résonance",
	"resonance.viseur.lier": "Arc Link — relier",
	"resonance.viseur.action": "Clic gauche : %s",
	"resonance.viseur.port_retenu": "Port retenu — vise le second port SANS lâcher G",
	"resonance.viseur.aucune_cible":
		"Aucune cible dans l'axe — approche (18 m) et dégage la vue",
}


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _lire(chemin: String) -> String:
	var f: FileAccess = FileAccess.open(chemin, FileAccess.READ)
	return "" if f == null else f.get_as_text()


## Les spécificateurs %… d'une chaîne, dans l'ordre : "%s", "%d", "%.1f", …
static func _placeholders(s: String) -> Array[String]:
	var out: Array[String] = []
	var i: int = 0
	while i < s.length():
		if s[i] != "%":
			i += 1
			continue
		var spec: String = "%"
		var j: int = i + 1
		while j < s.length() and (s[j] == "." or (s[j] >= "0" and s[j] <= "9")):
			spec += s[j]
			j += 1
		if j < s.length() and (s[j] == "s" or s[j] == "d" or s[j] == "f"):
			out.append(spec + s[j])
			i = j + 1
			continue
		i += 1
	return out


# --------------------------------------------------------------------------
# C1 — le français rendu est l'octet-pour-octet historique
# --------------------------------------------------------------------------
func test_chaque_cle_de_la_tranche_rend_le_francais_historique() -> void:
	check(FRANCAIS_EPINGLE.size() >= 70,
		"préalable NON VACUITÉ : %d clé(s) épinglée(s) — la tranche en "
		% FRANCAIS_EPINGLE.size() + "compte 76, une table fondue signalerait "
		+ "un test vidé, pas une migration finie")
	check(Textes.definir_locale(Textes.LOCALE_SOURCE),
		"préalable : la langue source est active")
	for cle: String in FRANCAIS_EPINGLE.keys():
		check_equal(Textes.t(cle), String(FRANCAIS_EPINGLE[cle]),
			"C1 — « %s » doit rendre le texte historique, octet pour octet"
			% cle)


# --------------------------------------------------------------------------
# C2 — la locale témoin couvre toute la tranche
# --------------------------------------------------------------------------
func test_la_locale_temoin_couvre_toute_la_tranche() -> void:
	var vides: Array[String] = []
	var differentes: int = 0
	for cle: String in FRANCAIS_EPINGLE.keys():
		var en: String = Textes.brut(cle, TEMOIN)
		if en == "":
			vides.append(cle)
		elif en != String(FRANCAIS_EPINGLE[cle]):
			differentes += 1
	check(vides.is_empty(),
		"C2 — chaque clé de la tranche est traduite dans la locale témoin ; "
		+ "manquent : %s" % [vides])
	check(differentes >= 60,
		"C2 — et la traduction DIFFÈRE du français sur la quasi-totalité "
		+ "(%d clé(s) distinctes) : une locale témoin recopiée ne " % differentes
		+ "prouverait aucune indirection. (Quelques formats techniques — "
		+ "« %s — %d s », « %.4f rad/px », « Arc Link » — restent identiques "
		+ "à dessein.)")
	# Le trou VOLONTAIRE de la locale témoin (menu.options.sous_titre, hors
	# tranche) doit survivre à cette passe : c'est lui qui fait courir le
	# chemin de repli d'A5. Le combler serait dé-tester ce chemin.
	check(Textes.cles_sans_traduction(TEMOIN).has("menu.options.sous_titre"),
		"C2 — le trou épinglé d'en.json (`_doc_trou`) est préservé")


# --------------------------------------------------------------------------
# C3 — une clé absente de la source reste bruyante
# --------------------------------------------------------------------------
func test_une_cle_de_tranche_absente_reste_bruyante() -> void:
	Textes.oublier_diagnostic()
	var fantome: String = "hud.tranche.fantome.inexistante"
	check(Textes.ressemble_a_une_cle(fantome),
		"préalable : la clé fantôme a la forme d'une clé")
	# C3 exerce le chemin d'erreur À DESSEIN, comme A3 ; l'étape 2 de
	# validate_fast traite tout « ERROR: » du journal en échec, et elle a
	# raison — on fait taire l'IMPRESSION le temps de l'appel, on n'annule
	# pas l'erreur : le marqueur et le compte restent vérifiés ci-dessous.
	var impression: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	var rendu: String = Textes.t(fantome)
	Engine.print_error_messages = impression
	check(rendu.begins_with("⟦") and rendu.contains(fantome),
		"C3 — le joueur voit un texte manifestement cassé : %s" % rendu)
	check(Textes.absentes_source().has(fantome),
		"C3 — et l'absence est comptée : %s" % [Textes.absentes_source()])
	Textes.oublier_diagnostic()


# --------------------------------------------------------------------------
# C4 — les paramètres de format sont identiques dans les deux langues
# --------------------------------------------------------------------------
## Un « %d » devenu « %s » dans une langue est une faute SILENCIEUSE jusqu'au
## premier affichage — puis c'est une erreur moteur devant le joueur.
func test_les_parametres_de_format_sont_identiques_dans_les_deux_langues() -> void:
	var avec_format: int = 0
	for cle: String in FRANCAIS_EPINGLE.keys():
		var seq_fr: Array[String] = _placeholders(String(FRANCAIS_EPINGLE[cle]))
		var seq_en: Array[String] = _placeholders(Textes.brut(cle, TEMOIN))
		if seq_fr.is_empty() and seq_en.is_empty():
			continue
		avec_format += 1
		check_equal(",".join(seq_en), ",".join(seq_fr),
			"C4 — « %s » : mêmes spécificateurs, dans le même ordre" % cle)
	check(avec_format >= 10,
		"préalable NON VACUITÉ : %d clé(s) paramétrée(s) inspectée(s)"
		% avec_format)
	# Et le formatage RÉEL rend le texte historique — pas seulement une
	# séquence comparée à elle-même.
	check(Textes.definir_locale(Textes.LOCALE_SOURCE), "langue source active")
	check_equal(Textes.t("hud.fleches") % 7, "Flèches : 7",
		"C4 — formatage réel côté source")
	check_equal(Textes.brut("hud.fleches", TEMOIN) % 7, "Arrows: 7",
		"C4 — formatage réel côté témoin")
	check_equal(Textes.t("cuisine.choisir_compte") % [2, "Baie, Viande"],
		"Choisis (2/5) : Baie, Viande",
		"C4 — formatage réel à deux paramètres hétérogènes")


# --------------------------------------------------------------------------
# C5 — le pluriel du Pulse est porté par les clés
# --------------------------------------------------------------------------
## L'ancien code fabriquait le pluriel en collant des « s » conditionnels :
## intranslatable. Les deux formes sont désormais deux CLÉS, et le code
## choisit la clé — pas la lettre.
func test_le_pluriel_du_pulse_est_porte_par_les_cles() -> void:
	check(Textes.definir_locale(Textes.LOCALE_SOURCE), "langue source active")
	check_equal(Textes.t("resonance.message.pulse_une") % 1,
		"Impulsion — 1 cible révélée",
		"C5 — le singulier rend l'octet-pour-octet de l'ancien code")
	check_equal(Textes.t("resonance.message.pulse_plusieurs") % 3,
		"Impulsion — 3 cibles révélées",
		"C5 — le pluriel rend l'octet-pour-octet de l'ancien code")
	check(Textes.brut("resonance.message.pulse_une", TEMOIN)
			!= Textes.brut("resonance.message.pulse_plusieurs", TEMOIN),
		"C5 — la locale témoin distingue aussi ses deux formes")

	# Et le HUD réel choisit la bonne clé selon le compte.
	var shell: CanvasLayer = (load(SHELL) as PackedScene).instantiate() as CanvasLayer
	_tree().root.add_child(shell)
	await _tree().process_frame
	shell.call("_on_resonance_pulse", 1)
	shell.call("_refresh_resonance_hud", 0.0)
	check_equal(String(shell.call("resonance_state_text")),
		"Impulsion — 1 cible révélée", "C5 — le viseur affiche le singulier")
	shell.call("_on_resonance_pulse", 3)
	shell.call("_refresh_resonance_hud", 0.0)
	check_equal(String(shell.call("resonance_state_text")),
		"Impulsion — 3 cibles révélées", "C5 — puis le pluriel")
	_tree().root.remove_child(shell)
	shell.queue_free()
	await _tree().process_frame


# --------------------------------------------------------------------------
# C6 — l'Unicode traverse la table intact
# --------------------------------------------------------------------------
func test_l_unicode_traverse_la_table_intact() -> void:
	check(Textes.definir_locale(Textes.LOCALE_SOURCE), "langue source active")
	check(Textes.t("boss.phase.grounded_stun").contains("—"),
		"C6 — le tiret cadratin survit à l'aller-retour JSON")
	check(Textes.t("boss.nom").contains("L'ORAGE"),
		"C6 — l'apostrophe droite entre lettres survit")
	check_equal(Textes.t("cuisine.effet.elec_resist"), "Résistance à la foudre",
		"C6 — accents aigus et graves, octet pour octet")
	check_equal(Textes.t("inventaire.fermer"), "Tab / Échap — Fermer",
		"C6 — majuscule accentuée (É) et cadratin dans la même chaîne")
	check(Textes.t("inventaire.detail.stats").contains("\n"),
		"C6 — les \\n du JSON deviennent de vrais sauts de ligne")


# --------------------------------------------------------------------------
# C7 — aucune clé brute ne paraît à l'écran
# --------------------------------------------------------------------------
func test_aucune_cle_brute_ne_parait_a_l_ecran() -> void:
	check(Textes.definir_locale(Textes.LOCALE_SOURCE), "langue source active")
	var shell: CanvasLayer = (load(SHELL) as PackedScene).instantiate() as CanvasLayer
	_tree().root.add_child(shell)
	await _tree().process_frame
	shell.call("_on_notification", "camp.braise.libere")
	await _tree().process_frame

	var textes: Array[String] = []
	for l: Node in shell.find_children("*", "Label", true, false):
		textes.append((l as Label).text)
	for b: Node in shell.find_children("*", "Button", true, false):
		textes.append((b as Button).text)
	var non_vides: int = 0
	for t: String in textes:
		if t.strip_edges() != "":
			non_vides += 1
		check(not Textes.ressemble_a_une_cle(t),
			"C7 — « %s » a la forme d'une clé : une clé nue à l'écran est "
			% t + "exactement ce que la migration devait rendre impossible")
	check(non_vides >= 12,
		"préalable NON VACUITÉ : %d texte(s) non vide(s) inspecté(s) — "
		% non_vides + "titres, boutons de cuisine, invite des commandes")

	_tree().root.remove_child(shell)
	shell.queue_free()
	await _tree().process_frame


# --------------------------------------------------------------------------
# C7bis — les chemins d'EXÉCUTION ne montrent jamais une clé nue
# --------------------------------------------------------------------------
## POURQUOI C7 ne suffisait pas, INSTRUMENTÉ par la contre-revue : C7 lit les
## labels une frame après l'instanciation — il n'atteint que les ~10 clés
## posées à la CONSTRUCTION. Dé-enrober `Textes.t()` sur un chemin d'EXÉCUTION
## (le message « port retenu » du viseur) laissait le gate VERT pendant que le
## joueur aurait lu la clé nue à l'écran. Et A9 ne rattrape pas : une chaîne
## en forme de clé y est classée `technique` PAR CONCEPTION — c'est ce qui
## fait baisser le compte à la migration.
##
## Ce cas PILOTE donc les familles d'exécution avec un JOUEUR RÉEL dans la
## scène de la coquille — notifications, messages du viseur/Résonance, HUD
## dynamique (flèches, plats, invite, arme, quatre buffs), cuisine complète —
## puis relit les Label/Button après chaque stimulus. Deux verrous : aucun
## texte affiché n'a la forme d'une clé, et le français attendu de CHAQUE clé
## pilotée est réellement paru (bilan de couverture compté à la fin).
##
## PÉRIMÈTRE DIT FRANCHEMENT — résiduel : boss.phase.* (10 clés), non
## pilotées, exigent un StormGuardian vivant ; leurs VALEURS restent
## vérifiées en table par C1/C13, leur AFFICHAGE au site d'appel n'est PAS
## couvert. (Le mot « tenues » du delta 3 survendait : la contre-revue a
## mesuré qu'un site dé-enrobé traversait C1 — qui épingle Textes.t(clé),
## insensible au code de la coquille — et C13 — qui vérifie les tables,
## insensible au site d'appel. Les trois autres clés du résiduel d'alors,
## cuisine.apercu.instable, cuisine.plat_defaut et inventaire.detail.stats,
## sont désormais pilotées ci-dessous.)
##
## Les états `focus`/`pending` du viseur exigeraient un ResonanceController
## vivant : pour eux, on appelle les fonctions qui CALCULENT la ligne que
## `_refresh_resonance_hud` pose telle quelle dans le label (`_set_label`),
## et on épingle leur rendu par `check_equal`.

class CibleInvite:
	extends Node3D

	## La coquille n'exige de sa cible d'interaction qu'une méthode
	## `prompt_verb()` (voir `_on_interact_focus_changed`).
	func prompt_verb() -> String:
		return "le coffre"


## C7bis — textes actuellement affichés par les Label/Button de la coquille.
func _textes_affiches(shell: CanvasLayer) -> Array[String]:
	var out: Array[String] = []
	for l: Node in shell.find_children("*", "Label", true, false):
		out.append((l as Label).text)
	for b: Node in shell.find_children("*", "Button", true, false):
		out.append((b as Button).text)
	return out


## C7bis — relit l'écran après un stimulus : aucune forme de clé, et mémorise
## tout ce qui est affiché pour le bilan de couverture final.
func _relever(shell: CanvasLayer, vus: Dictionary) -> void:
	for t: String in _textes_affiches(shell):
		check(not Textes.ressemble_a_une_cle(t),
			"C7bis — « %s » a la forme d'une clé : une clé nue à l'écran est "
			% t + "exactement ce que la migration devait rendre impossible")
		vus[t] = true


func test_les_chemins_d_execution_ne_montrent_jamais_une_cle_nue() -> void:
	check(Textes.definir_locale(Textes.LOCALE_SOURCE), "langue source active")
	var racine: Node = Node.new()
	racine.name = "C7bisRacine"
	_tree().root.add_child(racine)
	var player: PlayerController = (load("res://scenes/player/Player.tscn")
		as PackedScene).instantiate() as PlayerController
	racine.add_child(player)
	var shell: GameplayShell = (load(SHELL) as PackedScene).instantiate() \
		as GameplayShell
	racine.add_child(shell)
	await _tree().process_frame
	await _tree().process_frame   # _bind_player est différé d'une frame
	check(shell.bound_player() == player,
		"préalable : la coquille sert le joueur de SA scène — sans lui, les "
		+ "familles arme/buff/cuisine resteraient hors de portée")

	var vus: Dictionary = {}        # tout texte paru à l'écran (ensemble)
	var attendus: Dictionary = {}   # clé pilotée -> français attendu

	# 1. CONSTRUCTION — l'acquis de C7 — plus le label de sensibilité piloté
	# par le même chemin que le curseur (`_refresh_sensitivity_label`).
	for cle: String in ["inventaire.titre", "inventaire.conductivite",
			"inventaire.fermer", "menu.pause.commandes", "cuisine.titre",
			"cuisine.confirmer", "cuisine.retirer_dernier",
			"cuisine.reprendre", "boss.nom"]:
		attendus[cle] = Textes.t(cle)
	shell.call("_refresh_sensitivity_label", 0.0031)
	attendus["menu.pause.sensibilite"] = \
		Textes.t("menu.pause.sensibilite") % 0.0031
	_relever(shell, vus)

	# 2. NOTIFICATIONS — la clé publiée sur la porte, exactement comme
	# `cooking_confirm` le fait quand la réserve déborde.
	shell.call("_on_notification", "cuisine.reserve_pleine")
	attendus["cuisine.reserve_pleine"] = Textes.t("cuisine.reserve_pleine")
	_relever(shell, vus)

	# 3. HUD DYNAMIQUE — flèches, plats, invite, arme aux mains nues, buffs.
	shell.call("_on_arrows_changed", 7)
	attendus["hud.fleches"] = Textes.t("hud.fleches") % 7
	shell.call("_on_meals_changed", 2)
	attendus["hud.plats"] = Textes.t("hud.plats") % 2
	var cible_invite: CibleInvite = CibleInvite.new()
	racine.add_child(cible_invite)
	shell.call("_on_interact_focus_changed", cible_invite)
	attendus["hud.invite.format"] = Textes.t("hud.invite.format") % "le coffre"
	check_equal(shell.prompt_text(), String(attendus["hud.invite.format"]),
		"C7bis — l'invite d'interaction est le format traduit")
	# Le joueur porte sa dotation de départ : on la retire par le chemin réel
	# de la rupture (§11.2 « équiper suivante ou mains nues ») jusqu'aux mains
	# nues — c'est le SEUL chemin qui affiche le repli d'arme.
	var inventaire_armes: InventoryComponent = player.inventory()
	for i: int in range(InventoryComponent.MAX_WEAPONS):
		if inventaire_armes.equipped() == null:
			break
		inventaire_armes.remove_weapon(inventaire_armes.equipped())
	check(inventaire_armes.equipped() == null,
		"préalable : joueur aux mains nues après retrait de la dotation")
	shell.call("_refresh_weapon_text")
	attendus["hud.arme.mains_nues"] = Textes.t("hud.arme.mains_nues")
	_relever(shell, vus)
	for effet: StringName in GameplayShell.BUFF_LABELS.keys():
		player.status().apply_buff(effet, 1.0, 30.0)
		shell.call("_refresh_buff_label")
		var compose: String = Textes.t("hud.buff.format") % [
			Textes.t(String(GameplayShell.BUFF_LABELS[effet])), 30]
		check_equal(shell.buff_label_text(), compose,
			"C7bis — le label de buff « %s » est la composition traduite" % effet)
		attendus[String(GameplayShell.BUFF_LABELS[effet])] = compose
		attendus["hud.buff.format"] = compose
		_relever(shell, vus)

	# 4. CUISINE — le flux réel, avec l'inventaire du joueur.
	var inventory: InventoryComponent = player.inventory()
	var fruit: IngredientDefinition = \
		load("res://resources/ingredients/heal_fruit.tres") as IngredientDefinition
	var herbe: IngredientDefinition = \
		load("res://resources/ingredients/stamina_herb.tres") as IngredientDefinition
	inventory.add_ingredient(fruit, 1)
	inventory.add_ingredient(herbe, 1)
	check(bool(shell.open_cooking(player)), "préalable : l'atelier s'ouvre")
	attendus["cuisine.choisir"] = Textes.t("cuisine.choisir")
	_relever(shell, vus)
	check(shell.cooking_add(&"heal_fruit"), "préalable : fruit choisi")
	check(shell.cooking_add(&"stamina_herb"), "préalable : herbe choisie")
	var noms: String = "%s, %s" % [
		String(shell.call("_ingredient_display_name", &"heal_fruit")),
		String(shell.call("_ingredient_display_name", &"stamina_herb"))]
	attendus["cuisine.choisir_compte"] = \
		Textes.t("cuisine.choisir_compte") % [2, noms]
	var resultat: Dictionary = RecipeRules.cook(
		[fruit, herbe] as Array[IngredientDefinition])
	check(bool(resultat.get("valid", false))
			and String(resultat.get("effect", "")) == "stamina"
			and float(resultat.get("duration", 0.0)) > 0.0,
		"préalable : fruit + herbe rend un plat valide à effet endurance — "
		+ "c'est lui qui fait courir l'aperçu complet (soin + effet)")
	attendus["cuisine.apercu.soin"] = Textes.t("cuisine.apercu.soin") % [
		String(resultat.get("name", "")), int(resultat.get("heal", 0.0))]
	attendus["cuisine.apercu.effet"] = Textes.t("cuisine.apercu.effet") % [
		String(shell.call("_effect_display_name", "stamina")),
		int(round(float(resultat.get("duration", 0.0))))]
	attendus["cuisine.effet.stamina"] = Textes.t("cuisine.effet.stamina")
	_relever(shell, vus)
	shell.cooking_confirm()
	attendus["cuisine.fait"] = \
		Textes.t("cuisine.fait") % String(resultat.get("name", ""))
	_relever(shell, vus)
	check(not shell.is_cooking_open() and not _tree().paused,
		"la confirmation ferme l'atelier et rend le monde")
	# Les trois autres familles d'effet, par le chemin que l'aperçu emprunte.
	for effet_nom: String in ["attack", "defense", "elec_resist"]:
		var rendu_effet: String = \
			String(shell.call("_effect_display_name", effet_nom))
		check_equal(rendu_effet, Textes.t("cuisine.effet." + effet_nom),
			"C7bis — l'effet « %s » se nomme par sa clé" % effet_nom)
		vus[rendu_effet] = true
		attendus["cuisine.effet." + effet_nom] = \
			Textes.t("cuisine.effet." + effet_nom)

	# 4b. RAGOÛT INSTABLE — deux familles majeures (§13.4) : l'aperçu porte
	# l'avertissement traduit. C'était une clé « résiduelle » du delta 3 ; la
	# contre-revue a montré que dé-enrobée, elle traversait le gate vert.
	var racine_def: IngredientDefinition = \
		load("res://resources/ingredients/defense_root.tres") \
		as IngredientDefinition
	inventory.add_ingredient(herbe, 1)
	inventory.add_ingredient(racine_def, 1)
	check(bool(shell.open_cooking(player)), "préalable : l'atelier rouvre")
	check(shell.cooking_add(&"stamina_herb")
			and shell.cooking_add(&"defense_root"),
		"préalable : herbe + racine choisies")
	var instable: Dictionary = RecipeRules.cook(
		[herbe, racine_def] as Array[IngredientDefinition])
	check(bool(instable.get("valid", false))
			and bool(instable.get("unstable", false)),
		"préalable : deux familles majeures rendent le mélange instable")
	attendus["cuisine.apercu.instable"] = Textes.t("cuisine.apercu.instable")
	check(shell.cooking_preview_text().contains(
			Textes.t("cuisine.apercu.instable")),
		"C7bis — l'aperçu du ragoût instable porte l'avertissement traduit : "
		+ "%s" % shell.cooking_preview_text())
	_relever(shell, vus)
	shell.close_cooking()

	# 4c. PLAT SANS NOM — RecipeRules nomme toujours ses plats : le repli du
	# site de notification (extrait en `_meal_display_name` pour être
	# pilotable, comportement identique) n'est joignable qu'en direct.
	var repli_plat: String = String(shell.call("_meal_display_name", {}))
	check_equal(repli_plat, Textes.t("cuisine.plat_defaut"),
		"C7bis — un plat sans nom retombe sur la clé traduite, jamais vide")
	check_equal(String(shell.call("_meal_display_name",
			{"name": "Sauté du grimpeur"})), "Sauté du grimpeur",
		"C7bis — un plat nommé garde son nom : le repli ne l'écrase pas")
	vus[repli_plat] = true
	attendus["cuisine.plat_defaut"] = Textes.t("cuisine.plat_defaut")

	# 4d. INVENTAIRE — les stats d'une arme RÉELLE dans le panneau de détail.
	# LE dé-enrobage que la revue a fait passer inaperçu au delta 3 : il doit
	# maintenant accuser.
	var gourdin: WeaponDefinition = \
		load("res://resources/weapons/wood_club.tres") as WeaponDefinition
	var arme: WeaponInstance = WeaponInstance.create(gourdin)
	check(inventaire_armes.add_weapon(arme),
		"préalable : le gourdin entre à l'inventaire")
	shell.toggle_inventory()
	check(shell.is_inventory_open(), "préalable : l'inventaire s'ouvre")
	var stats_attendu: String = Textes.t("inventaire.detail.stats") % [
		gourdin.base_damage, gourdin.reach_m, arme.current_durability,
		gourdin.max_durability]
	check_equal(shell.detail_stats_text(), stats_attendu,
		"C7bis — le détail d'arme est le format traduit, aux données réelles")
	attendus["inventaire.detail.stats"] = stats_attendu
	_relever(shell, vus)
	shell.toggle_inventory()
	check(not shell.is_inventory_open() and not _tree().paused,
		"fermer l'inventaire rend le monde")

	# 5. RÉSONANCE — chaque verdict, chaque message, posé dans le VRAI label.
	for verdict: StringName in GameplayShell.RESONANCE_REFUSALS.keys():
		shell.call("_on_resonance_verdict", &"pulse", verdict, false)
		shell.call("_refresh_resonance_hud", 0.0)
		var cle_refus: String = String(GameplayShell.RESONANCE_REFUSALS[verdict])
		check_equal(shell.resonance_state_text(), Textes.t(cle_refus),
			"C7bis — le refus « %s » paraît traduit dans le viseur" % verdict)
		vus[shell.resonance_state_text()] = true
		attendus[cle_refus] = Textes.t(cle_refus)
	var succes: Dictionary[StringName, String] = {
		&"linked": "resonance.message.lien_etabli",
		&"engaged": "resonance.message.polarite_engagee",
		&"step": "resonance.message.arc_step",
	}
	for verdict: StringName in succes.keys():
		shell.call("_on_resonance_verdict", &"pulse", verdict, true)
		shell.call("_refresh_resonance_hud", 0.0)
		check_equal(shell.resonance_state_text(), Textes.t(succes[verdict]),
			"C7bis — le verdict exécuté « %s » a SA clé — le delta 3 sépare "
			% verdict + "enfin &\"step\" de la ligne d'action du viseur")
		vus[shell.resonance_state_text()] = true
		attendus[String(succes[verdict])] = Textes.t(succes[verdict])
	shell.call("_on_resonance_pulse", 0)
	shell.call("_refresh_resonance_hud", 0.0)
	attendus["resonance.message.pulse_vide"] = \
		Textes.t("resonance.message.pulse_vide")
	vus[shell.resonance_state_text()] = true
	shell.call("_on_resonance_pulse", 1)
	shell.call("_refresh_resonance_hud", 0.0)
	attendus["resonance.message.pulse_une"] = \
		Textes.t("resonance.message.pulse_une") % 1
	vus[shell.resonance_state_text()] = true
	shell.call("_on_resonance_pulse", 3)
	shell.call("_refresh_resonance_hud", 0.0)
	attendus["resonance.message.pulse_plusieurs"] = \
		Textes.t("resonance.message.pulse_plusieurs") % 3
	vus[shell.resonance_state_text()] = true
	shell.call("_on_resonance_link_dissolved")
	shell.call("_refresh_resonance_hud", 0.0)
	attendus["resonance.message.lien_rompu"] = \
		Textes.t("resonance.message.lien_rompu")
	vus[shell.resonance_state_text()] = true
	shell.call("_on_resonance_grounded", null)
	shell.call("_refresh_resonance_hud", 0.0)
	attendus["resonance.message.terre_effectuee"] = \
		Textes.t("resonance.message.terre_effectuee")
	vus[shell.resonance_state_text()] = true
	shell.call("_on_resonance_ground_cancelled", &"pas_au_sol")
	shell.call("_refresh_resonance_hud", 0.0)
	attendus["resonance.message.terre_annulee"] = \
		Textes.t("resonance.message.terre_annulee") \
		% Textes.t("resonance.refus.pas_au_sol")
	vus[shell.resonance_state_text()] = true
	attendus["resonance.viseur.titre"] = Textes.t("resonance.viseur.titre")
	check_equal(shell.resonance_action_text(),
		Textes.t("resonance.viseur.titre"),
		"C7bis — hors focus, la ligne d'action porte le titre du Bracelet")
	_relever(shell, vus)

	# 6. VISEUR SOUS FOCUS — les lignes que `_set_label` pose telles quelles.
	var cible: ResonanceTargetComponent = ResonanceTargetComponent.new()
	for kind: StringName in GameplayShell.RESONANCE_ACTIONS.keys():
		cible.kind = kind
		var ligne: String = \
			String(shell.call("_resonance_action_line", true, cible, false))
		var cle_action: String = String(GameplayShell.RESONANCE_ACTIONS[kind])
		check_equal(ligne,
			Textes.t("resonance.viseur.action") % Textes.t(cle_action),
			"C7bis — la ligne d'action « %s » est la composition traduite" % kind)
		vus[ligne] = true
		attendus[cle_action] = Textes.t(cle_action)
	attendus["resonance.viseur.action"] = \
		Textes.t("resonance.viseur.action") % Textes.t("resonance.action.port")
	cible.kind = &"port"
	var ligne_lier: String = \
		String(shell.call("_resonance_action_line", true, cible, true))
	check_equal(ligne_lier,
		Textes.t("resonance.viseur.action") % Textes.t("resonance.viseur.lier"),
		"C7bis — un port retenu change le verbe de la ligne d'action")
	vus[ligne_lier] = true
	attendus["resonance.viseur.lier"] = Textes.t("resonance.viseur.lier")
	cible.free()
	var ligne_retenu: String = \
		String(shell.call("_resonance_state_line", true, null, true, false))
	check(not Textes.ressemble_a_une_cle(ligne_retenu),
		"C7bis — LE trou démontré par la contre-revue : « %s » ne doit "
		% ligne_retenu + "jamais être la clé nue")
	check_equal(ligne_retenu, Textes.t("resonance.viseur.port_retenu"),
		"C7bis — l'état « port retenu » est le français de sa clé")
	vus[ligne_retenu] = true
	attendus["resonance.viseur.port_retenu"] = \
		Textes.t("resonance.viseur.port_retenu")
	var ligne_vide: String = \
		String(shell.call("_resonance_state_line", true, null, false, false))
	check_equal(ligne_vide, Textes.t("resonance.viseur.aucune_cible"),
		"C7bis — le focus sans cible explique quoi faire, en français")
	vus[ligne_vide] = true
	attendus["resonance.viseur.aucune_cible"] = \
		Textes.t("resonance.viseur.aucune_cible")

	# 7. BILAN DE COUVERTURE — chaque clé pilotée a réellement paru.
	var manquees: Array[String] = []
	for cle: String in attendus.keys():
		var attendu: String = String(attendus[cle])
		var trouve: bool = false
		for texte: String in vus.keys():
			if texte.contains(attendu):
				trouve = true
				break
		if not trouve:
			manquees.append(cle)
	manquees.sort()
	check(manquees.is_empty(),
		"C7bis — chaque clé pilotée doit paraître en français à l'écran ; "
		+ "manquent : %s" % [manquees])
	check(attendus.size() >= 65,
		"C7bis — bilan : %d clé(s) de la tranche réellement vues à l'écran "
		% attendus.size() + "(C7 seul n'en atteignait que ~10 sur 76). Un "
		+ "compte effondré signalerait un test vidé de ses stimuli — le "
		+ "périmètre restant est déclaré en tête de ce cas")

	_tree().paused = false
	_tree().root.remove_child(racine)
	racine.queue_free()
	await _tree().process_frame


# --------------------------------------------------------------------------
# C8 — le changement de langue à chaud change réellement l'écran
# --------------------------------------------------------------------------
## PORTÉE DITE FRANCHEMENT : les textes ÉMIS (notifications, viseur, jauges
## rafraîchies) suivent la locale immédiatement — c'est ce qui est prouvé ici.
## Les textes posés une fois à la construction (titres de panneaux, boutons)
## ne se retraduisent qu'à la prochaine instanciation de la coquille : limite
## connue, consignée dans docs/LOCALISATION.md, hors du contrat de ce cas.
func test_le_changement_de_langue_a_chaud_change_l_ecran() -> void:
	check(Textes.definir_locale(Textes.LOCALE_SOURCE), "départ : source")
	var fr_camp: String = Textes.t("camp.braise.libere")
	var shell: CanvasLayer = (load(SHELL) as PackedScene).instantiate() as CanvasLayer
	_tree().root.add_child(shell)
	await _tree().process_frame

	check(Textes.definir_locale(TEMOIN), "bascule vers la locale témoin")
	shell.call("_on_notification", "camp.braise.libere")
	shell.call("_on_resonance_pulse", 2)
	shell.call("_refresh_resonance_hud", 0.0)
	await _tree().process_frame

	var notifs: Array[String] = []
	for t: Variant in shell.call("notification_texts") as Array:
		notifs.append(String(t))
	var attendu_en: String = Textes.brut("camp.braise.libere", TEMOIN)
	check(attendu_en != "" and notifs.has(attendu_en),
		"C8 — la notification paraît en anglais : %s" % [notifs])
	check(not notifs.has(fr_camp),
		"C8 — et pas en français : %s" % [notifs])
	check_equal(String(shell.call("resonance_state_text")),
		Textes.brut("resonance.message.pulse_plusieurs", TEMOIN) % 2,
		"C8 — le message du viseur suit la locale")
	check_equal(String(shell.call("resonance_action_text")),
		Textes.brut("resonance.viseur.titre", TEMOIN),
		"C8 — la ligne d'action du viseur aussi")

	check(Textes.definir_locale(Textes.LOCALE_SOURCE), "retour au français")
	shell.call("_on_resonance_pulse", 2)
	shell.call("_refresh_resonance_hud", 0.0)
	check_equal(String(shell.call("resonance_state_text")),
		Textes.t("resonance.message.pulse_plusieurs") % 2,
		"C8 — le retour à la source rend le français immédiatement")

	_tree().root.remove_child(shell)
	shell.queue_free()
	await _tree().process_frame


# --------------------------------------------------------------------------
# C9 — les tables de localisation partent dans l'export
# --------------------------------------------------------------------------
## `Textes` lit ses tables par FileAccess ; un fichier absent de l'export
## rendrait le jeu exporté MUET (⟦clé⟧ partout) sans qu'aucun test d'éditeur
## ne le voie. Mécanisme : les quatre presets exportent `all_resources`, et
## un `.json` est une ressource (JSON) connue de Godot 4 — c'est CETTE
## reconnaissance qui l'embarque. Si elle disparaît, il faut un
## `include_filter` sur resources/localisation/*.json (export_presets.cfg).
## Le niveau 7 (export réel) reste hors de portée ici : ce cas épingle le
## mécanisme, pas le paquet.
func test_les_tables_de_localisation_partent_dans_l_export() -> void:
	var preset: String = _lire("res://export_presets.cfg")
	check(preset.contains("export_filter=\"all_resources\""),
		"préalable : les presets exportent all_resources")
	for locale: String in ["fr", "en"]:
		var chemin: String = "res://resources/localisation/%s.json" % locale
		check(FileAccess.file_exists(chemin),
			"C9 — %s existe (chemin lu par Textes)" % chemin)
		check(ResourceLoader.exists(chemin)
				or preset.contains("resources/localisation"),
			"C9 — %s est une ressource connue du moteur (donc " % chemin
			+ "embarquée par all_resources), ou couverte par un "
			+ "include_filter explicite. Ni l'un ni l'autre = jeu exporté "
			+ "sans textes")


# --------------------------------------------------------------------------
# C10 — la localisation ne touche à aucune clé de sauvegarde
# --------------------------------------------------------------------------
## Une sauvegarde qui stockerait un texte TRADUIT à la place d'un identifiant
## casserait au premier changement de langue. La couche de sauvegarde doit
## ignorer jusqu'à l'existence de `Textes`.
func test_la_localisation_ne_touche_pas_aux_cles_de_sauvegarde() -> void:
	var dossier: DirAccess = DirAccess.open("res://scripts/save")
	check(dossier != null, "préalable : scripts/save existe")
	var inspectes: int = 0
	for f: String in dossier.get_files():
		if not f.ends_with(".gd"):
			continue
		inspectes += 1
		check(not _lire("res://scripts/save/" + f).contains("Textes."),
			"C10 — scripts/save/%s ne connaît pas la table de textes" % f)
	check(inspectes >= 2,
		"préalable NON VACUITÉ : %d fichier(s) de sauvegarde inspecté(s)"
		% inspectes)
	# Le plat stocké est le résultat BRUT de RecipeRules : la coquille ne
	# traduit que sa COPIE affichée, jamais la donnée qui part en inventaire
	# (et de là en sauvegarde).
	var shell_src: String = _lire("res://scripts/ui/gameplay_shell.gd")
	check(shell_src.contains("inventory.add_meal(result)"),
		"C10 — le plat ajouté à l'inventaire est le résultat brut")
	check(not shell_src.contains("add_meal(Textes"),
		"C10 — jamais un texte traduit dans la donnée d'inventaire")


# --------------------------------------------------------------------------
# C13 — les replis affichent le jeton technique BRUT, jamais un marqueur
# --------------------------------------------------------------------------
## Cinq chemins affichaient déjà un jeton technique quand la table de bord ne
## connaît pas l'entrée (buff, phase de boss, action du viseur, verdict,
## effet de cuisine). DÉCISION EXPLICITE de la tranche : ce repli RESTE le
## jeton brut — « mieux vaut un mot brut qu'un silence », commentaire
## historique de RESONANCE_REFUSALS — et il ne passe JAMAIS par `Textes.t()`,
## donc jamais de ⟦…⟧ accidentel. Le ⟦…⟧ est réservé à une clé DÉCLARÉE dans
## une table de bord mais absente de fr.json ; ce cas-là est fermé par le
## second bras : chaque valeur des quatre tables est une clé qui RÉSOUT.
func test_les_replis_affichent_le_jeton_brut_jamais_un_marqueur() -> void:
	check(Textes.definir_locale(Textes.LOCALE_SOURCE), "langue source active")
	# Bras 1 — les quatre tables sont entièrement raccordées à la source :
	# aucune entrée CONNUE ne peut produire un ⟦…⟧ à l'écran.
	var tables: Array[Dictionary] = [
		GameplayShell.BUFF_LABELS, GameplayShell.BOSS_PHASE_LABELS,
		GameplayShell.RESONANCE_ACTIONS, GameplayShell.RESONANCE_REFUSALS,
	]
	var valeurs: int = 0
	for table: Dictionary in tables:
		for jeton: Variant in table.keys():
			var cle: String = String(table[jeton])
			valeurs += 1
			check(Textes.ressemble_a_une_cle(cle),
				"C13 — la valeur de table « %s » est une clé" % cle)
			check(Textes.brut(cle, Textes.LOCALE_SOURCE) != "",
				"C13 — et la clé « %s » résout dans fr.json — sinon le HUD "
				% cle + "montrerait ⟦%s⟧" % cle)
	check_equal(valeurs, 35,
		"préalable NON VACUITÉ : les quatre tables portent bien 35 entrées")

	# Bras 2 — un jeton INCONNU traverse brut : ni marqueur, ni forme de clé.
	var shell: CanvasLayer = (load(SHELL) as PackedScene).instantiate() as CanvasLayer
	_tree().root.add_child(shell)
	await _tree().process_frame
	shell.call("_on_resonance_verdict", &"pulse", &"verdict_tout_neuf", false)
	shell.call("_refresh_resonance_hud", 0.0)
	check_equal(String(shell.call("resonance_state_text")), "verdict_tout_neuf",
		"C13 — un verdict inconnu s'affiche tel quel, jamais ⟦…⟧")
	shell.call("_on_resonance_ground_cancelled", &"raison_neuve")
	shell.call("_refresh_resonance_hud", 0.0)
	check_equal(String(shell.call("resonance_state_text")),
		"Mise à la terre annulée — raison_neuve",
		"C13 — l'annulation de mise à la terre garde le format traduit et "
		+ "le jeton brut")
	check_equal(String(shell.call("_effect_display_name", "poison")), "poison",
		"C13 — un effet de cuisine inconnu retombe sur son identifiant")
	# (Les replis du buff et de la phase de boss suivent le MÊME motif
	# `Textes.t(TABLE[x]) if TABLE.has(x) else String(x)` ; ils exigent un
	# joueur ou un boss vivant et restent couverts par le bras 1.)
	_tree().root.remove_child(shell)
	shell.queue_free()
	await _tree().process_frame
