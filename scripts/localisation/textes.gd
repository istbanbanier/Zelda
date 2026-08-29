## ISS-075 — LA TABLE DE TEXTES DU JEU, ET SES DEUX RÈGLES.
##
## Règle 1 : **une clé absente de la langue SOURCE est une faute**, bruyante.
## Règle 2 : **une clé absente d'une AUTRE langue n'en est pas une** — elle
## retombe sur le français et se compte. C'est la différence entre « le texte
## n'existe pas » et « la traduction n'est pas encore faite », et confondre les
## deux est la façon habituelle de ne jamais voir la première.
##
## POURQUOI PAS `TranslationServer`. Trois raisons mesurées, pas une préférence.
##
## 1. `tr()` rend la CLÉ elle-même quand elle manque. Silencieusement. C'est
##    l'inverse exact de ce que la directive demande, et il faudrait de toute
##    façon une couche par-dessus pour retrouver l'échec — donc la couche est
##    le vrai mécanisme, et le serveur n'ajouterait qu'une indirection.
## 2. Un `Translation` est une `Resource`, et `TranslationServer` la retient
##    jusqu'à la fin du processus. Le résidu de fin de processus de ce dépôt
##    est ÉPINGLÉ par un contrat (`docs/contrats/residu_cache_moteur.json`),
##    lui-même GELÉ : deux locales = deux ressources = enveloppe à rouvrir, et
##    le gel à régénérer. Une table en `Dictionary` n'est ni un objet ni une
##    ressource — elle n'apparaît nulle part dans ce comptage.
## 3. Aucun autoload de plus. La racine en porte six ; les tests savent les
##    reconstruire et `restore_root()` compte dessus.
##
## Ce que l'on perd, dit franchement : la traduction automatique du `text` des
## `Control` posés en scène. Cette passe ne migre que du texte ÉMIS PAR CODE,
## donc la perte est nulle aujourd'hui. Le jour où un `.tscn` devra être
## traduit, tous les appels passent déjà par `t()` : le changement tiendra dans
## ce fichier.
class_name Textes
extends RefCounted

## La langue dont l'absence est une faute. Les autres sont des traductions.
const LOCALE_SOURCE: StringName = &"fr"
const DOSSIER: String = "res://resources/localisation/"

## Ce que voit un joueur quand une clé manque à la source. VISIBLE À DESSEIN :
## un message vide ou une clé nue passeraient pour un choix de mise en page.
## Ces crochets-là ne ressemblent à rien du jeu, donc ils se signalent.
const MARQUEUR: String = "⟦%s⟧"

static var _tables: Dictionary = {}
static var _locale: StringName = LOCALE_SOURCE
static var _charge: bool = false
## Diagnostic, jamais du gameplay : ce que la dernière session a réclamé sans
## le trouver. Deux paniers séparés, parce que ce sont deux problèmes.
static var _absentes_source: Dictionary = {}
static var _repliees: Dictionary = {}


## ------------------------------------------------------------------------
## La forme d'une clé
## ------------------------------------------------------------------------
## `camp.libere.feu`, jamais « Le camp est libéré. ». Minuscules, chiffres,
## soulignés et points ; au moins un point ; ni point au bord, ni point double.
##
## Cette forme n'est pas cosmétique : c'est ELLE qui permet au HUD de
## distinguer une clé d'un texte brut hérité, et donc de migrer message par
## message au lieu de tout basculer d'un coup. Aucun texte joueur français ne
## peut la satisfaire — il porte des espaces, des majuscules ou des accents —
## et `test_localisation_iss075.gd` le vérifie sur les littéraux réels du
## dépôt plutôt que de le supposer.
##
## Écrit à la main, sans `RegEx` : une `RegEx` en `static var` vivrait jusqu'à
## la fin du processus et se compterait dans le résidu épinglé (voir en-tête).
static func ressemble_a_une_cle(texte: String) -> bool:
	if texte.length() < 3 or not texte.contains("."):
		return false
	if texte.begins_with(".") or texte.ends_with(".") or texte.contains(".."):
		return false
	# PREMIER CARACTÈRE UNE LETTRE, et ce n'est pas de la cosmétique : sans
	# cette ligne, « 0.5 » est une clé valide. Trouvé par le premier passage
	# ROUGE de `test_localisation_iss075.gd`, pas par relecture — une
	# notification portant un nombre serait partie chercher une traduction et
	# aurait affiché ⟦0.5⟧ au joueur.
	var premier: String = texte[0]
	if premier < "a" or premier > "z":
		return false
	for i: int in range(texte.length()):
		var c: String = texte[i]
		var ok: bool = (c >= "a" and c <= "z") or (c >= "0" and c <= "9") \
			or c == "." or c == "_"
		if not ok:
			return false
	return true


## ------------------------------------------------------------------------
## Résolution
## ------------------------------------------------------------------------
## Rend le texte, ou `""` si la clé est inconnue de la locale demandée.
## SANS repli et SANS bruit : c'est la brique que les tests interrogent pour
## constater une absence sans la provoquer.
static func brut(cle: String, locale: StringName = &"") -> String:
	_charger()
	var demandee: StringName = _locale if locale == &"" else locale
	var table: Dictionary = _tables.get(demandee, {}) as Dictionary
	return String(table.get(cle, ""))


## Le texte à afficher. Repli documenté, faute bruyante.
static func t(cle: String) -> String:
	var direct: String = brut(cle)
	if direct != "":
		return direct
	var source: String = brut(cle, LOCALE_SOURCE)
	if source != "":
		# Traduction manquante, pas texte manquant. Le joueur lit du français
		# plutôt qu'un crochet : c'est le bon compromis, et il est compté.
		_repliees[cle] = true
		return source
	_absentes_source[cle] = true
	push_error("[textes] clé absente de la langue source « %s » : %s"
		% [LOCALE_SOURCE, cle])
	return MARQUEUR % cle


## Le point d'entrée du HUD : traduit CE QUI EST UNE CLÉ, laisse passer le
## reste. C'est ce qui rend la migration progressive possible — 206 littéraux
## joueur vivent encore dans le code, et les basculer d'un seul coup serait
## exactement le genre de changement qu'on ne sait pas relire.
static func traduire_si_cle(texte: String) -> String:
	return t(texte) if ressemble_a_une_cle(texte) else texte


## ------------------------------------------------------------------------
## Locales
## ------------------------------------------------------------------------
static func locale() -> StringName:
	return _locale


static func definir_locale(nouvelle: StringName) -> bool:
	_charger()
	if not _tables.has(nouvelle):
		push_error("[textes] locale inconnue : %s" % nouvelle)
		return false
	_locale = nouvelle
	return true


static func locales() -> Array[StringName]:
	_charger()
	var out: Array[StringName] = []
	for k: StringName in _tables.keys():
		out.append(k)
	out.sort()
	return out


## Les clés que cette locale n'a pas et qui retomberaient sur le français.
## Un chiffre de couverture, pas une alarme : une locale témoin incomplète est
## un état normal, tant qu'on sait de combien.
static func cles_sans_traduction(locale_cible: StringName) -> Array[String]:
	_charger()
	var source: Dictionary = _tables.get(LOCALE_SOURCE, {}) as Dictionary
	var cible: Dictionary = _tables.get(locale_cible, {}) as Dictionary
	var out: Array[String] = []
	for cle: String in source.keys():
		if not cible.has(cle):
			out.append(cle)
	out.sort()
	return out


static func cles_source() -> Array[String]:
	_charger()
	var out: Array[String] = []
	for cle: String in (_tables.get(LOCALE_SOURCE, {}) as Dictionary).keys():
		out.append(cle)
	out.sort()
	return out


## ------------------------------------------------------------------------
## Diagnostic
## ------------------------------------------------------------------------
static func absentes_source() -> Array[String]:
	var out: Array[String] = []
	for cle: String in _absentes_source.keys():
		out.append(cle)
	out.sort()
	return out


static func oublier_diagnostic() -> void:
	_absentes_source.clear()
	_repliees.clear()


## Rechargement explicite — pour les tests, jamais pour le jeu.
static func recharger() -> void:
	_charge = false
	_tables.clear()
	_charger()


## ------------------------------------------------------------------------
## Chargement
## ------------------------------------------------------------------------
## `FileAccess` + `JSON.parse_string`, PAS `load()` : le résultat est un
## `Dictionary`, donc un Variant. Aucun `Resource` n'entre dans le cache du
## moteur, donc aucun objet ne survit au processus (voir en-tête, raison 2).
## ISS-059 — FIN DE VIE DU CACHE STATIQUE, et ce n'était pas facultatif.
##
## `_tables` est un conteneur `static` : les variables `static` de GDScript ne
## sont PAS libérées avant le rapport de sortie du moteur (mesuré par ablation
## à variable unique, R2B.3.1). Un cache de durée de vie « processus » sans
## propriétaire ne peut pas être relâché — d'où l'inscription au noyau, qui
## appelle `liberer_caches()` UNE fois à l'extinction.
##
## Le sens de la dépendance est imposé : le porteur connaît le noyau, le noyau
## n'a jamais entendu parler du porteur.
##
## Défaut RÉEL de ma première rédaction, attrapé par
## `test_invariants.gd::test_tout_cache_statique_de_ressources_est_liberable` :
## le cache était là, la fin de vie manquait.
static func _static_init() -> void:
	StaticResourceCaches.enregistrer("Textes", liberer_caches)


static func liberer_caches() -> int:
	var n: int = _tables.size()
	_tables.clear()
	_charge = false
	_absentes_source.clear()
	_repliees.clear()
	return n


static func _charger() -> void:
	if _charge:
		return
	_charge = true
	var dossier: DirAccess = DirAccess.open(DOSSIER)
	if dossier == null:
		push_error("[textes] dossier introuvable : %s" % DOSSIER)
		return
	for nom: String in dossier.get_files():
		if not nom.ends_with(".json"):
			continue
		var locale: StringName = StringName(nom.get_basename())
		var f: FileAccess = FileAccess.open(DOSSIER + nom, FileAccess.READ)
		if f == null:
			push_error("[textes] illisible : %s" % nom)
			continue
		var brut_json: Variant = JSON.parse_string(f.get_as_text())
		if not (brut_json is Dictionary):
			push_error("[textes] %s n'est pas un objet JSON" % nom)
			continue
		var table: Dictionary = {}
		for cle: Variant in (brut_json as Dictionary).keys():
			var s: String = String(cle)
			# Les commentaires du fichier de données commencent par « _ » :
			# ils documentent la table sans polluer l'espace des clés.
			if s.begins_with("_"):
				continue
			table[s] = String((brut_json as Dictionary)[cle])
		_tables[locale] = table
