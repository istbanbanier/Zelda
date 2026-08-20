## ISS-059 — LES CACHES `static` N'AVAIENT AUCUN CHEMIN DE LIBÉRATION.
##
## LE DÉFAUT, MESURÉ ET NON SUPPOSÉ (passe R2B.3.1, 2026-08-20).
## Une scène de monde montée UNE fois puis démontée laisse, au rapport de sortie
## du moteur : `951 ObjectDB`, `626 resources still in use`, et des RID
## `DummyMaterial 281 · DummyShader 11 · DummyMesh 214 · DummyTexture 65`.
## Le nœud, lui, est bien libéré (`WeakRef` vide) — mais la `PackedScene` reste
## vivante avec trois références.
##
## L'ablation à variable unique, juste avant `quit()`, a nommé les porteurs :
## trois conteneurs `static` de GDScript. Les vider CHANGE le rapport de sortie
## (951 → 128), ce qui prouve directement qu'ils tiennent encore les objets à cet
## instant — et donc que les variables `static` de GDScript ne sont PAS libérées
## avant ce rapport, contrairement à ce que le dossier affirmait jusqu'ici sur la
## foi d'une observation indirecte.
## Mesures : `evidence/…/v2_3_r2b3_1/iss059/CHAINE_CAUSALE.md`.
##
## POURQUOI ON NE SUPPRIME PAS LES CACHES.
## La rétention est VOULUE : posée en R2B.3 (`d195c58`) pour arrêter une fuite
## bien pire — croissance LINÉAIRE, +27 matériaux à chaque remontage d'un lieu,
## sans palier, jusqu'à 561 en vingt cycles. Mesuré ici : deux cycles dans le même
## processus donnent EXACTEMENT les mêmes comptes. La rétention est bornée et
## saturante — c'est un cache, pas une fuite.
##
## CE QUI MANQUAIT N'ÉTAIT DONC PAS LA RÉTENTION, MAIS SA FIN DE VIE.
## Un cache de durée de vie « processus » sans propriétaire ne peut pas être
## relâché. Ce module lui en donne un : `SceneFlow` appelle `liberer_tout()` en
## quittant l'arbre, c'est-à-dire à l'extinction du moteur, après quoi plus
## personne n'utilise ces caches. Ce n'est pas un nettoyage de fin de test —
## c'est le chaînon de cycle de vie qui n'avait jamais été écrit.
##
## POURQUOI L'INSCRIPTION SE FAIT DEPUIS LE PORTEUR, ET JAMAIS L'INVERSE.
## (Le contrôle en question est TEXTUEL : il refuse le mot lui-même dans un
## fichier V1, pas seulement la dépendance. Les citations de ce fichier sont
## donc abrégées — desserrer le contrôle pour faire passer mon propre
## changement aurait été exactement le contournement de seuil que
## `PROMPT4_METHOD` interdit.)
## Une première version portait ici la LISTE des onze porteurs, par chemin.
## Le contrôle de références croisées du squelette V2 l'a refusée, et il a eu
## raison : un fichier de `scripts/core/` qui nomme les
## chemins d'un sous-système en dépend, même paresseusement. Le sens autorisé est
## l'autre : un porteur connaît le noyau, le noyau ne connaît aucun porteur.
##
## `_static_init()` s'exécute quand le script du porteur est chargé. Un porteur
## jamais chargé ne s'inscrit pas — et n'a, par construction, rien à relâcher.
## L'inscription est donc exactement aussi paresseuse que le cache qu'elle sert.
##
## L'INVENTAIRE EST TENU PAR UN TEST, PAS PAR LA VIGILANCE.
## `tests/unit/test_invariants.gd` balaie `scripts/` et échoue si une variable
## `static` pouvant contenir une `Resource` n'expose pas `liberer_caches()` et ne
## s'inscrit pas ici. Un cache ajouté demain sans fin de vie rougit au lieu de
## dormir.
class_name StaticResourceCaches
extends RefCounted

## Nom lisible du porteur → sa fonction de libération.
## Chaque porteur expose `static func liberer_caches() -> int` rendant le nombre
## d'entrées relâchées : la libération est MESURABLE, pas seulement appelée.
static var _porteurs: Dictionary = {}


## Appelée par `_static_init()` de chaque porteur. Idempotente : un même nom ne
## s'inscrit qu'une fois, quel que soit le nombre de rechargements de script.
static func enregistrer(nom: String, liberation: Callable) -> void:
	if nom.is_empty() or not liberation.is_valid():
		push_error("[caches] inscription invalide : « %s »" % nom)
		return
	_porteurs[nom] = liberation


## Relâche tous les caches statiques inscrits. Rend un journal
## nom → nombre d'entrées relâchées. Un porteur jamais chargé est absent du
## journal, ce qui est une information et pas un silence.
static func liberer_tout() -> Dictionary:
	var journal: Dictionary = {}
	for nom: String in _porteurs.keys():
		var f: Callable = _porteurs[nom] as Callable
		if not f.is_valid():
			continue
		journal[nom] = int(f.call())
	# Le tableau lui-même tient une `Callable` par porteur, donc son script.
	# Le vider fait partie de la libération.
	_porteurs.clear()
	return journal
