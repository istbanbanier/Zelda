## SANCTUAIRE FORESTIER (`valley.poi.forest_shrine.01`, r06) — petit, bas,
## sous couvert. La seule chose du lot qu'on puisse manquer.
##
## SON IDENTITÉ EST UNE CONTRAINTE, PAS UNE DÉCORATION. Le layout dit
## « la curiosité seule y mène » ; le terrain et la route disent comment
## l'obtenir. Le site est une soucoupe : plat jusqu'à r ≈ 10 m, puis le sol
## tombe de 2,5 à 4,9 m à 16-20 m DANS TOUTES LES DIRECTIONS. Et la route
## 2 passe à **7,3 m au sud-sud-ouest, exactement à la même altitude**
## (point (84,2 ; 81,1), sol 7,00 comme le site — il est encore dans le pad
## plat). L'invisibilité ne peut donc venir ni de la distance ni du
## dénivelé : elle vient de deux décisions mesurables —
##
##   1. **RIEN DU BÂTI NE DÉPASSE 2,4 m.** La pierre de chevet, la seule
##      verticale du lieu, monte à 2,05 m sur son maillage ; la marge réelle
##      sur le nœud POSÉ est mesurée par `tools/godot/probe_sanctuaire.gd` et
##      reportée dans `RAPPORT_VOIE.md` — jamais déduite.
##   2. **UN RIDEAU SUR L'ARC SUD**, entre le sanctuaire et la route :
##      fougères et buissons à 2,2-6,2 m, SANS collider — ils masquent
##      sans rien fermer, et le filet des routes ne compte que les corps
##      solides (`ROUTE_CLEAR_M = 1,2 m` autour de chaque échantillon).
##      Les trois troncs, eux, vont au nord et à l'ouest : un tronc porte
##      un collider, et un collider à 7 m d'une route est un pari inutile.
##
## ---------------------------------------------------------------------------
## LOT 1.R — CORRECTIVE VISUELLE, COMPOSITION B « LA NEF AVALÉE ».
##
## Le gate visuel a rejeté la version en modules de kit : « les murs beige
## rectangulaires restent du graybox ». Cause mesurée, et elle n'est pas une
## affaire de teinte : l'anneau était fait de `SM_Dungeon_PillarStub` (des
## moignons à faces planes) et l'autel d'un `SM_Dungeon_ArchBlock` (un cube),
## et cette famille de trimsheet rend TERRACOTTA/BEIGE sous la lumière de ce
## monde. Aucun albédo ne répare une forme de cube.
##
## La maçonnerie du vestige est donc désormais un GLB dédié
## (`SM_Shrine_Vestige.glb`, générateur `make_forest_shrine.py`, 878 tris pour
## un budget de 6 000) : neuf pierres à pans impairs, fuseau et sommet CASSÉ,
## une mousse posée par règle de nature (faces tournées vers le haut + la
## chaussette de pied), et une table d'offrande FENDUE dont une moitié a
## glissé de 0,21 m.
##
## ET LA COMPOSITION CHANGE, pas seulement la matière. L'anneau devient un
## AXE court nord→sud : le seuil (deux montants franchement inégaux, plus une
## marche enfoncée et un linteau tombé en travers de l'approche), deux
## bordures basses qui CONVERGENT vers le cœur, la table, et derrière elle la
## seule verticale — le dossier. Trois raisons, dans cet ordre :
##
## COTES ET PLACEMENTS DE CE PARAGRAPHE : ils ont bougé au LOT 1.R.2 et les
## chiffres ont été retirés d'ici plutôt que recopiés. Les hauteurs de
## montants vivent dans `make_forest_shrine.py`, les positions dans
## `_seuil()`, `_bordures_de_nef()` et `MURETS` — un nombre dupliqué dans un
## préambule diverge du réel sans que personne le remarque, et l'ancrage du
## dépôt l'interdit. La pierre couchée, en particulier, ne barre PLUS la nef :
## elle la borde à l'ouest, et `_nef_enceinte()` dit pourquoi.
##
##   * l'intention imposée (ADDENDUM_DA §4) demande « un seuil, un centre
##     rituel, une lumière ou une ouverture qui guide le regard » : un anneau
##     fait TOURNER le regard autour du centre, un axe l'y CONDUIT ;
##   * D3 par construction : le cercle de pierres levées INTACT appartient à
##     `watchers_circle` (lot futur), et la voie C fabrique en ce moment des
##     stèles PÂLES ET PENCHÉES dans la couleur ouverte pour la Porte du
##     champ. Ici les pierres sont grises-vertes, moussues, basses, sous
##     couvert, et la seule verticale est un DOSSIER derrière une table —
##     jamais un jalon planté dans le vide ;
##   * les trois caméras du plan gelé arrivent toutes du NORD (local z ≈ −9,5
##     à −15) : l'axe de la nef est exactement leur axe de visée, et la
##     composition se lit donc dans les cadres qui la jugent.
##
## L'implantation du SITE, la récompense et son genre, le `poi_id` et le rayon
## de découverte ne changent pas. Ce qui change : la position VERTICALE de
## l'ancre de récompense, qui suit le dessus de la nouvelle table (0,89 m au
## lieu de 0,95 m) — une offrande qui flotte au-dessus de sa table est
## précisément le défaut que l'audit a relevé chez une autre voie.
class_name ForestShrinePlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")
const VESTIGE_SCENE: PackedScene = preload(
	"res://assets/architecture/shrine/SM_Shrine_Vestige.glb")

## Dessus de la table d'offrande, mesuré sur le maillage exporté
## (désormais `SM_Shrine_Coeur`). Ce n'est pas un choix : c'est une cote lue
## dans le journal de la chaîne Blender, et si le générateur change, ce nombre
## doit être RELU et non deviné — l'ancre de récompense s'y appuie, et une
## cote périmée ferait flotter l'offrande, ce qui est exactement le défaut
## B-f-7 relevé par l'audit sur ce lieu.
## LOT 1.R : la fusion table+chevet a élargi la dalle mais laissé son dessus
## à 0,890 — c'est la raison pour laquelle le dossier a été construit À CÔTÉ
## de la dalle et non dessous.
const TABLE_DESSUS: float = 0.89

## TEINTES DU VESTIGE — albédos ABSOLUS, pas des multiplicateurs.
##
## Le générateur pose déjà une couleur de base, mais elle n'est pas la matière
## finale : ces deux constantes-ci sont le seul endroit à toucher pour
## recalibrer, sans repasser par Blender. Et elles se jugent sur CAPTURE
## RENDUE, jamais sur leur valeur : le gain de lumière de ce monde vaut 1,4 à
## 1,8 et n'est pas linéaire (`scripts/CLAUDE.md`). Cible de la bande §1.5,
## sous couvert : pierre 0,32-0,45 rendu, mousse 0,26-0,34.
## RECALÉ SUR CAPTURE (apres/forest_shrine_joueur.png + shrine_gp_nef.png) :
## à 0,455 la pierre RENDAIT 0,39-0,42, c'est-à-dire PLUS CLAIRE que le
## sous-bois qui l'entoure (0,351 mesuré) — le vestige sortait en dalles
## pâles et lisses, exactement la lecture dont le lead a demandé de
## s'écarter (les stèles de la voie C sont pâles, en couleur ouverte).
## Descendue à 0,375 : la pierre passe sous la valeur de l'herbe et se lit
## avalée par le bois, ce qui est l'intention du lieu.
const TEINTES_VESTIGE: Dictionary = {
	"MAT_Shrine_Stone": Color(0.375, 0.378, 0.358),
	"MAT_Shrine_Moss": Color(0.232, 0.278, 0.182),
}

## Mousse du dallage avalé — le sol du sanctuaire existait, le bois l'a repris.
const TONE_MOUSSE: Color = Color(0.62, 0.68, 0.55)

## ---------------------------------------------------------------------------
## LE REPÈRE DE NEF — LOT 1.R.1, ET C'EST TOUTE LA CORRECTION DU REJET
## ---------------------------------------------------------------------------
## CE QUE CODEX A VU : « dans la caméra joueur, l'arbre central masque le lieu ».
## Ce n'est pas une impression, et la géométrie le dit à la décimale.
##
## `forest_shrine_joueur` part du local (5,5 ; −9,5) et vise (0 ; 0), fov
## VERTICAL 65° sur 1280 × 720 — donc `tan_h = tan(32,5°) × 16/9 = 1,1327`
## pour 640 px. Le tronc gelé occupe **x 594 à 718** (mesuré colonne par
## colonne sur les pixels bruns de `candidate/ab13/forest_shrine_joueur.png`),
## soit une bande d'occultation en tangente de [−0,081 ; +0,138]. Le cœur, lui,
## projette à **x 640,0** : au pixel près derrière le tronc. Le seuil projette
## à 730-813, de l'AUTRE côté. Le lieu était coupé en deux par un arbre, et ses
## deux pièces maîtresses de part et d'autre.
##
## L'arbre est GELÉ : il ne bouge pas. C'est le LIEU qui se recompose, par une
## similitude appliquée aux offsets LOCAUX — rotation de l'axe de nef,
## translation, et deux facteurs d'échelle (la nef raccourcit, elle s'élargit).
## Les quatre paramètres sortent d'une recherche exhaustive sur la projection
## des sept pièces maîtresses dans les trois caméras GELÉES ; les contraintes
## étaient, dans cet ordre :
##   1. cœur ET seuil hors de la bande du tronc, du MÊME côté ;
##   2. aucune pièce à moins de 2,2 m du tronc (sa position est estimée à
##      ±0,6 m par la ligne de sol : marge délibérée) ;
##   3. `z` maximal ≤ celui d'aujourd'hui — le lieu ne s'approche PAS de la
##      route, sinon le contrat d'invisibilité change de donne ;
##   4. le lieu reste lisible depuis `forest_shrine_joueur_b` et `_identite`.
## Résultat retenu : θ = 45°, T = (2,50 ; 0,25), nef ×0,80 en longueur et
## ×1,15 en largeur. Le cœur passe de x 640 à x ≈ 510, le seuil à x ≈ 340-470,
## et le tronc devient le montant DROIT du cadre. `z` maximal 0,77 contre 0,74
## aujourd'hui : la route ne voit pas un centimètre de plus.
## ---------------------------------------------------------------------------
## LOT 1.R.2 — L'AXE DE NEF SE COUCHE DANS L'AXE DE VISÉE, ET C'EST LA
## CORRECTION DU SECOND REJET
## ---------------------------------------------------------------------------
## CE QUE CODEX A VU : « le seuil et l'axe rituel ne sont pas immédiatement
## lisibles ». La cause est géométrique et je l'ai mesurée avant de toucher
## quoi que ce soit, sur la capture héritée
## `lot1r1/revue_intermediaire/vues/forest_shrine_joueur.png` — trois pièces
## indépendantes valident le modèle de projection au pixel près (cœur prédit
## x 510 / mesuré 502-515 ; sommet du dossier prédit y 317 / mesuré 312 ;
## sommet du montant prédit y 346 / mesuré 357) :
##
##   * l'axe de visée du plan joueur a l'azimut −30,05° dans le repère local
##     (caméra locale (5,5 ; −9,5) visant (0 ; 0)) ;
##   * l'axe de la nef, à θ = 45°, avait l'azimut −45° : un écart de 15°.
##
## QUINZE DEGRÉS, C'EST LE PIRE DES DEUX MONDES. À 0° le seuil ENCADRE le
## cœur — on regarde l'autel à travers la porte. À 45° la nef se voit de
## trois-quarts et se lit comme une ligne. À 15° elle ne fait ni l'un ni
## l'autre : les montants projetaient à x 357 et 461, le cœur à x 510 — donc
## À CÔTÉ du seuil et non DEDANS, pendant que le montant le plus haut (x 461,
## sommet y 346) venait se superposer au dossier (x 518, sommet y 317). Le
## seuil masquait le cœur au lieu de le présenter.
##
## θ passe donc de 45° à 14,3° : l'azimut de la nef devient −30,05°, celui de
## la visée. T suit (le cœur reste sur le même rayon, à la même distance),
## et les sept pièces maîtresses se rangent d'elles-mêmes — montants à x 401
## et 555, cœur à 481, dossier à 469, linteau et marche à 483. Le cœur tombe
## au MILIEU de la porte.
##
## LA CONTRAINTE QUI DÉCIDE DE T N'EST PAS LE CENTRAGE, C'EST LE TRONC GELÉ.
## Mesuré colonne par colonne sur la capture héritée, dans la bande de hauteur
## du sujet (y 300..500) : les troncs occupent x 203-235, 661-717, 794-836,
## 901-915 et 1239-1276. La plus large fenêtre LIBRE est **x 236 à 660**, soit
## −35,6° à +2,0° de l'axe de visée — elle est donc entièrement à gauche de
## l'axe, et le gros tronc central commence à +2,1°. Le lieu recomposé
## s'étale de x 334 (muret B) à x 615 (muret A) : tout tient dans l'ouverture,
## avec 45 px de marge sur le tronc. C'est cela, « déplacer les éléments dans
## l'ouverture réellement visible » — une mesure, pas une intuition.
##
## Les deux autres plans gelés y gagnent au lieu d'y perdre : `_joueur_b`
## (azimut +30,05°) et `_identite` (+20,1°) voient désormais la nef à 60° et
## 50°, c'est-à-dire de trois-quarts — la lecture complémentaire de celle du
## plan joueur, et celle qu'on demande à une vue d'identité.
const NEF_ROT_DEG: float = 14.3
const NEF_T: Vector2 = Vector2(3.02, 0.25)
const NEF_L: float = 0.80
const NEF_W: float = 1.15


## Un point du plan de nef -> le plan LOCAL du lieu.
func _nef(x: float, z: float) -> Vector2:
	var t: float = deg_to_rad(NEF_ROT_DEG)
	var c: float = cos(t)
	var s: float = sin(t)
	var xx: float = x * NEF_W
	var zz: float = z * NEF_L
	return Vector2(xx * c - zz * s + NEF_T.x, xx * s + zz * c + NEF_T.y)


## ... et posé au sol.
func _nef_seated(x: float, z: float) -> Vector3:
	var p: Vector2 = _nef(x, z)
	return Vector3(p.x, ground_local_y(p.x, p.y), p.y)


## Le lacet correspondant. Le signe n'est pas une convention libre : la
## rotation de plan `(x, z) -> (x cosθ − z sinθ, x sinθ + z cosθ)` est celle
## d'un lacet Godot de **−θ** (la matrice de rotation autour de +Y envoie
## (1,0,0) sur (cos ψ, 0, −sin ψ)). Se tromper de signe laisserait les
## positions justes et toutes les pierres tournées à l'envers.
func _nef_yaw(deg: float) -> float:
	return deg - NEF_ROT_DEG

static var _cache_vestige: Dictionary = {}


func default_place_id() -> StringName:
	return &"valley.poi.forest_shrine.01"


func _build() -> void:
	_seuil()
	_bordures_de_nef()
	_nef_enceinte()
	_coeur()
	_dallage_avale()
	_rideau_sud()
	_sous_bois()
	_couvert()
	_collisions()

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Sanctuaire forestier"
	poi.region = &"r06_bois_du_levant"
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Decouverte_forme"
	var sphere: SphereShape3D = SphereShape3D.new()
	# 9 m : le rayon du plat. Au-delà le sol tombe et on n'est plus dans la
	# clairière — un volume de découverte plus large annoncerait le lieu
	# depuis la route, ce que ce sanctuaire doit précisément éviter.
	sphere.radius = 9.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	# L'épice rare est POSÉE SUR LA TABLE : c'est une offrande laissée là,
	# pas une plante qui aurait poussé. On arrive par le seuil, au nord.
	# L'ALTITUDE DE L'ANCRE APPARTIENT AU LIEU (arbitrage du lead) : le VISUEL
	# de la récompense vient d'une ressource partagée, mais la cote à laquelle
	# il se pose est une décision d'implantation. `IngredientPickup` dessine sa
	# tige depuis SON origine et la baie 0,22 m plus haut ; à +0,10 au-dessus
	# du dessus de table, la baie flottait donc 0,32 m au-dessus de la dalle —
	# mesuré par l'audit sur `apres/shrine_gp_nef.png`. À −0,05 la tige mord
	# la dalle de cinq centimètres et l'offrande est POSÉE.
	# L'ANCRE SUIT LE CŒUR, ET C'EST LA GÉOMÉTRIE QUI L'EXIGE — je le dis au
	# lieu de le glisser : l'offrande est POSÉE SUR la dalle, elle ne peut donc
	# pas rester à l'ancien local (0 ; 0) quand la dalle est en (2,50 ; 0,25).
	# Ne changent PAS : le `Kind`, l'identifiant du lieu, la table de butin,
	# la cote `TABLE_DESSUS − 0,05`. Le point d'approche suit le même repère.
	var approche: Vector2 = _nef(0.45, -2.40)
	RewardAnchor.attach(self, default_place_id(),
		RewardAnchor.Kind.INGREDIENT,
		_nef_seated(0.0, 0.0) + Vector3(0.0, TABLE_DESSUS - 0.05, 0.0),
		Vector3(approche.x, 0.0, approche.y))
	var ancre: Node = get_node_or_null("AncrageRecompense")
	if ancre != null:
		ancre.child_entered_tree.connect(_sur_recompense)


## HABILLAGE LOCAL DE LA RÉCOMPENSE (autorisé par le lead, lot 1.R). L'audit
## a mesuré la baie à (255, 255, 113) : saturée au maximum, et donc le point
## le plus lumineux d'un lieu dont l'intention est « calme, mystère, respect ».
## Le MODÈLE est partagé et ne se remplace pas ; la surface, elle, s'habille
## sur une COPIE, pour cette instance seulement.
##
## Le réglage est plus doux que celui du coffre du cimetière (35 % de
## désaturation contre 55 %) et volontairement : l'épice est le SEUL point
## chaud voulu de ce sanctuaire (conception, « aucun accent saturé sauf
## l'offrande »). On veut qu'elle attire, pas qu'elle crève l'image.
func _sur_recompense(noeud: Node) -> void:
	if noeud.is_node_ready():
		_habiller_recompense(noeud)
	else:
		noeud.ready.connect(_habiller_recompense.bind(noeud), CONNECT_ONE_SHOT)


func _habiller_recompense(racine: Node) -> void:
	if racine == null or not is_instance_valid(racine):
		return
	var cibles: Array[Node] = racine.find_children("*", "MeshInstance3D",
		true, false)
	if racine is MeshInstance3D:
		cibles.append(racine)
	for noeud: Node in cibles:
		var instance: MeshInstance3D = noeud as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var base: StandardMaterial3D = instance.get_active_material(
				surface) as StandardMaterial3D
			if base == null:
				continue
			var mat: StandardMaterial3D = base.duplicate() as StandardMaterial3D
			var c: Color = mat.albedo_color
			var gris: float = c.get_luminance()
			mat.albedo_color = Color(
				lerpf(c.r, gris, 0.35) * 0.86,
				lerpf(c.g, gris, 0.35) * 0.84,
				lerpf(c.b, gris, 0.35) * 0.86, c.a)
			mat.roughness = maxf(mat.roughness, 0.92)
			mat.metallic_specular = 0.1
			# `material_override` PRIME sur les surcharges de surface : écrire
			# une surcharge sur une instance qui en porte un ne ferait RIEN,
			# en silence.
			if instance.material_override != null:
				instance.material_override = mat
			else:
				instance.set_surface_override_material(surface, mat)


## LE SEUIL — deux montants FRANCHEMENT inégaux et une marche enfoncée.
##
## L'inégalité n'est pas un caprice : deux montants jumeaux se lisent
## « portique », donc bâti et symétrique, donc récent. Deux fruits différents,
## deux cassures différentes, et un rapport de hauteur franc — on lit une
## porte qui a vieilli de travers. Les cotes vivent dans le générateur, pas
## ici. La marche est le seul élément encore à peu près à sa
## place, et c'est elle qui dit « on entre ICI » sans un mot.
## LOT 1.R.1, deuxième passe — LE SEUIL SE RESSERRE.
##
## Constat sur `it/r1/forest_shrine_joueur.png`, à ×3 : les deux montants
## projettent à x ≈ 333 et 480, soit 147 px d'écart pour 2,02 m d'entraxe à
## 7 m. Trois murets s'intercalent entre eux, et l'œil ne peut pas relier deux
## pierres séparées par un tiers de l'image : le seuil ne se lit plus comme
## une porte. L'entraxe passe de 2,02 à 1,38 m — l'écart apparent tombe à
## ≈ 110 px, et le linteau tombé les relie enfin.
## LOT 1.R.2 — LE SEUIL S'OUVRE, ET C'EST ISS-070 QUI SE FERME.
##
## La sonde mesurait une fenêtre libre de **0,89 m** entre les colliders des
## deux montants, pour un critère de 0,90 (diamètre de capsule 0,80 + 0,05 de
## marge par côté) : un centimètre, et un FAIL au journal depuis
## l'intégration du lot 1.R.1. L'entraxe passe de 1,20 à **1,62 en x de nef**,
## soit 1,863 m réels (× NEF_W = 1,15).
##
## LE CALCUL EST FAIT SUR LES COLLIDERS TOURNÉS, PAS SUR LEUR CÔTÉ — c'est ce
## qui manquait au raisonnement précédent, et c'est ce qui expliquait de rater
## la cible d'un centimètre. Le montant ouest porte un corps de 0,64 × 0,49
## tourné de 24° dans le plan de nef : sa demi-largeur EFFECTIVE face au tir
## latéral vaut (0,64 cos24° + 0,49 sin24°)/2 = 0,392 m, pas 0,32. L'est,
## 0,50 × 0,53 tourné de −58°, vaut (0,50 cos58° + 0,53 sin58°)/2 = 0,357 m.
## Fenêtre attendue : 1,863 − 0,392 − 0,357 = **1,114 m**, soit 0,214 m de
## marge au-dessus du critère au lieu de −0,010. La cible du lot est « au
## moins 1,00 m de largeur géométrique, pour éviter un résultat au centimètre
## près » : elle est tenue par le calcul, et VÉRIFIÉE par la sonde — le seuil
## du test, lui, ne bouge pas d'un millimètre.
##
## Le linteau relie encore : il mesure 2,21 m sur le maillage exporté, pour
## 1,86 m d'entraxe.
func _seuil() -> void:
	var a: Vector3 = _nef_seated(-0.82, -3.30)
	_piece_vestige("SM_Shrine_Montant_A", a,
		Vector3(0.0, deg_to_rad(_nef_yaw(24.0)), deg_to_rad(5.0)))
	declare_support(a)
	var b: Vector3 = _nef_seated(0.80, -3.50)
	_piece_vestige("SM_Shrine_Montant_B", b,
		Vector3(0.0, deg_to_rad(_nef_yaw(-58.0)), deg_to_rad(-8.0)))
	declare_support(b)
	# LE LINTEAU TOMBÉ — en travers, entre les deux montants et un peu en
	# avant. C'est lui qui fait qu'on lit une PORTE et non deux pierres : la
	# pièce est taillée là où tout le reste est de la pierre de champ, et elle
	# est couchée là où tout le reste est debout. Enfoncée de 11 cm, elle
	# n'émerge que de 0,22 m — sous la hauteur de marche du héros, donc aucun
	# corps : on l'enjambe, exactement comme la pierre couchée de la nef.
	var linteau: Vector3 = _nef_seated(-0.30, -4.05)
	# LE LINTEAU PASSE DEVANT LE SEUIL, ET LA PROJECTION DIT POURQUOI C'EST
	# POSSIBLE. Trois positions ont été essayées, et chacune a été jugée sur
	# capture, pas sur intention :
	#   * à plat entre les montants (`it1`) : indiscernable des blocs tombés ;
	#   * relevé à 50° entre les montants (`it2`) : il projetait à x 456,
	#     entre le montant est (400) et le cœur (481) — il MASQUAIT le sujet
	#     qu'il était censé présenter ;
	#   * au pied du montant ouest (`it3`) : il ne masque plus rien, mais il
	#     ne relie plus les deux montants non plus, et le seuil retombe à
	#     « deux pierres » au lieu d'« une porte ».
	# La quatrième position est la bonne parce qu'elle sort du CONFLIT au lieu
	# d'arbitrer entre ses deux termes : DEVANT le seuil, en travers de
	# l'approche (z de nef −4,05). Il se projette alors à x 486, y 440 —
	# c'est-à-dire 59 px SOUS le cœur (y 381) et 124 px sous le sommet du
	# dossier (y 316). Il ne peut donc rien masquer : il est au premier plan
	# bas, là où une barre de seuil se lit comme un pas à franchir.
	#
	# ENFONCÉ DE 12 CM, et ce n'est pas de l'esthétique : le maillage culmine
	# à 0,46 m, et le contrat du lieu veut que le linteau s'ENJAMBE. À 0,34 m
	# il reste sous la hauteur de marche du héros (0,38 m) et garde donc son
	# droit de n'avoir aucun corps de collision, comme la marche.
	_piece_vestige("SM_Shrine_Linteau",
		linteau + Vector3(0.0, -0.12, 0.0),
		Vector3(0.0, deg_to_rad(_nef_yaw(84.0)), deg_to_rad(8.0)))
	declare_support(linteau)
	# Enfoncée de 8 cm : une dalle qui affleure l'herbe se lit neuve.
	var marche: Vector3 = _nef_seated(-0.02, -3.02)
	_piece_vestige("SM_Shrine_Step", marche + Vector3(0.0, -0.08, 0.0),
		Vector3(0.0, deg_to_rad(_nef_yaw(9.0)), 0.0))
	declare_support(marche)


## LES DEUX BORDURES DE NEF — L'AXE, RENDU VISIBLE
##
## LOT 1.R.2. Le verdict dit « l'axe rituel n'est pas immédiatement lisible ».
## La cause est nommable, et elle n'est pas une affaire de composition : avant
## cette passe, l'axe n'existait QUE sous forme de dallage au sol — neuf
## `Floor_UnevenBrick` enfoncés de 7 à 14 cm. Or l'herbe du semis V2.2 monte
## plus haut que les dalles, et une caméra qui rase le sol à 10 m ne voit pas
## un sol. Sur la capture héritée, pas UNE des neuf dalles n'est discernable.
##
## Ce qui se voit dans l'herbe, c'est ce qui en dépasse. Deux rangées de
## bornes basses (0,65 et 0,47 m au maillage) prolongent donc la ligne des
## deux montants jusqu'au cœur. Elles sont posées à |x| de nef 0,80, c'est-à-
## dire à 0,92 m réels de l'axe — les montants sont à 0,93 m : les bordures
## sont littéralement la CONTINUATION du seuil, et c'est ce qui fait qu'on lit
## une nef et non deux alignements séparés.
##
## ELLES CONVERGENT DE 6°, ET LE SIGNE N'EST PAS LIBRE. Une rotation Godot de
## lacet ψ envoie (x, z) sur (x cosψ + z sinψ, −x sinψ + z cosψ) ; le bout
## d'une bordure côté seuil a z de nef NÉGATIF, donc pour l'écarter vers
## l'extérieur il faut sinψ du signe de ce côté. La gauche (x négatif) prend
## donc +6° et la droite −6°. Se tromper de signe donnerait deux rangées qui
## divergent vers le cœur — l'inverse exact d'un axe.
##
## ELLES REÇOIVENT UN CORPS, et c'est la conséquence de les avoir relevées.
## À 0,39 m on les enjambait et le contrat de la marche et du linteau
## s'appliquait ; à 0,60 et 0,42 m au-dessus du sol (cotes LUES sur le
## maillage exporté — 0,65 et 0,47 moins l'enfoncement — et non recopiées de
## la hauteur demandée, que la brisure du générateur rabat), une pierre qu'on
## traverse est un mensonge physique. Le couloir n'en souffre pas, et le
## chiffre le dit : les bordures sont à 0,92 m de l'axe, leurs corps font
## 0,50 et 0,47 m de large, donc la fenêtre qu'elles laissent vaut
## 2 × (0,92 − 0,25) = 1,34 m — au-dessus du 1,00 m visé et bien au-dessus du
## critère de 0,90. Deux `CollisionShape3D` de plus : treize pour vingt.
func _bordures_de_nef() -> void:
	var g: Vector3 = _nef_seated(-0.80, -2.20)
	_piece_vestige("SM_Shrine_Bordure_G",
		g + Vector3(0.0, -BORDURE_ENFONCEMENT, 0.0),
		Vector3(0.0, deg_to_rad(_nef_yaw(6.0)), deg_to_rad(2.0)))
	declare_support(g)
	var d: Vector3 = _nef_seated(0.78, -2.35)
	_piece_vestige("SM_Shrine_Bordure_D",
		d + Vector3(0.0, -BORDURE_ENFONCEMENT, 0.0),
		Vector3(0.0, deg_to_rad(_nef_yaw(-6.0)), deg_to_rad(-3.0)))
	declare_support(d)


## L'ENCEINTE — TROIS MURETS ROMPUS, ET PLUS UN SEUL CERCLE DE PIERRES.
##
## Ce qui était là : six socles dressés plus quatre marques d'angle, dix pièces
## isolées. Mon propre constat de la passe précédente le disait déjà — « neuf
## pièces sur neuf sont le même prisme dressé » — et l'exigence de niveau de
## cette passe le tranche : « une petite ruine brisée, moussue, ENRACINÉE :
## blocs irréguliers solidaires », « pas de cercle de pierres, pas d'amas
## décoratif ».
##
## Trois murets les remplacent : des blocs LIÉS sur une assise commune, crête
## rompue, une brèche par pan, deux blocs tombés au pied de la brèche. Deux
## conséquences mesurables et non deux opinions :
##   * D7 — dix modules deviennent trois. Le lieu passe de 40 (le plafond
##     PILE) à 33 : la marge revient au budget au lieu d'être consommée.
##   * hiérarchie — le plus haut socle culminait à 1,13 m contre 2,03 m pour
##     le cœur, soit 1,8. Les murets plafonnent à 0,82 / 0,72 / 0,55 m : le
##     rapport passe à 2,5, et le cœur domine enfin ses murs.
##
## Ils sont ENFONCÉS de 10 cm : un muret posé sur l'herbe se lit neuf.
## `[pièce, x_nef, z_nef, lacet_nef, tangage, hauteur]`
## LOT 1.R.2 — LES DEUX MURETS LATÉRAUX RECULENT VERS LE CŒUR, ET LA TRAVÉE
## DU SEUIL SE VIDE.
##
## Constat sur `it1/forest_shrine_joueur.png`, à ×3 : entre le seuil et le
## cœur, la travée est SATURÉE de blocs au même gabarit — deux murets, leurs
## quatre blocs tombés, la pierre couchée et les bordures, tous entre 0,3 et
## 0,9 m, tous dans les deux mètres qui suivent la porte. Un seuil ne se lit
## que s'il a du VIDE autour de lui ; celui-ci en avait un mur.
##
## Les murets A et B passent donc de z de nef −1,90/−1,75 à −0,75/−0,55 :
## ils cessent d'être l'enceinte de la NEF pour devenir celle du CŒUR, qu'ils
## flanquent à ±2,1 m. La travée −3,3 → −1,5 ne garde que la pierre couchée
## (0,52 m, qu'on enjambe) et les deux bordures qui tracent l'axe.
const MURETS: Array[Array] = [
	["SM_Shrine_Muret_A", -1.85, -0.75, -84.0, 3.0, 0.92],
	["SM_Shrine_Muret_B", 1.80, -0.55, -97.0, -4.0, 0.84],
	["SM_Shrine_Muret_C", -0.40, 1.05, 10.0, 2.0, 0.66],
]
## Enfoncement des murets, et de la pierre couchée.
const MURET_ENFONCEMENT: float = 0.10
## Enfoncement des bordures de nef : leur assise fait 0,11 m d'épaisseur, et
## on l'enterre presque entièrement — c'est la ligne de pied qui doit se lire,
## pas la semelle. 0,05 laisse les bornes à 0,60 et 0,42 m au-dessus du sol.
const BORDURE_ENFONCEMENT: float = 0.05
## Longueurs des corps de collision, LUES sur le maillage exporté (2,65 /
## 2,22 / 1,69 m) et rognées d'un peu pour rester dans la pierre. Tableau
## TYPÉ : `[2.55, 2.15, 1.62][index]` rendrait un `Variant`, et
## `unsafe_cast` est un avertissement ACTIF dans ce projet.
const MURET_LONGUEURS: Array[float] = [2.55, 2.15, 1.62]
const COUCHEE_ENFONCEMENT: float = 0.19


func _nef_enceinte() -> void:
	for index: int in range(MURETS.size()):
		var spec: Array = MURETS[index]
		var at: Vector3 = _nef_seated(float(spec[1]), float(spec[2]))
		_piece_vestige(String(spec[0]),
			at + Vector3(0.0, -MURET_ENFONCEMENT, 0.0),
			Vector3(0.0, deg_to_rad(_nef_yaw(float(spec[3]))),
				deg_to_rad(float(spec[4]))),
			"Muret_%d" % index)
		declare_support(at)
	# LA PIERRE COUCHÉE NE BARRE PLUS LA NEF, ELLE LA BORDE. Elle était en
	# travers, au milieu du passage (x de nef −0,10) : 1,86 m de fût posés
	# exactement là où l'œil doit trouver un couloir. Sur `it2` c'est la masse
	# qui brouille le plus la travée. Elle glisse au bord ouest (x de nef
	# −1,70) et se couche DANS l'axe au lieu d'en travers — un fût tombé le
	# long de son mur, ce que la ruine raconte aussi bien.
	#
	# CE QUE ÇA CHANGE POUR LA SONDE, ET JE LE DIS AU LIEU DE LE TAIRE : la
	# nef n'a plus de contremarche du tout sur son axe, donc la mesure de
	# marche va tomber vers zéro. Ce n'est PAS un seuil qu'on abaisse —
	# `MARCHE_MAX` ne bouge pas — mais le contrôle « la pierre couchée est
	# franchissable » perd son objet, et l'en-tête de la sonde le dit.
	var couchee: Vector3 = _nef_seated(-1.70, -1.30)
	_piece_vestige("SM_Shrine_Fallen",
		couchee + Vector3(0.0, -COUCHEE_ENFONCEMENT, 0.0),
		Vector3(0.0, deg_to_rad(_nef_yaw(12.0)), deg_to_rad(3.0)))
	declare_support(couchee)


## LE CŒUR — la table fendue et son chevet.
##
## La table est l'élément héroïque du lieu : une dalle cassée en deux dont une
## moitié a GLISSÉ de 0,21 m, posée sur deux dés inégaux, et l'épice rare
## dessus. C'est le seul endroit du lot où la récompense EST la narration —
## quelqu'un dépose encore une offrande sur une table brisée.
##
## Le chevet est la seule verticale du sanctuaire, et c'est un DOSSIER : il se
## tient derrière la table, du côté de la route, à 0,95 m. Deux fonctions dans
## la même pierre — il donne au cœur son fond, et il ajoute une masse de plus
## entre la table et la route.
func _coeur() -> void:
	var table: Vector3 = _nef_seated(0.0, 0.0)
	var dalle: Node3D = _piece_vestige("SM_Shrine_Coeur", table,
		Vector3(0.0, deg_to_rad(_nef_yaw(12.0)), 0.0))
	# LE CŒUR DOIT DOMINER LES MURS — c'est la phrase du contrat, et la capture
	# `it/t2/shrine_gp_nef.png` montre l'inverse : la table est vue de champ,
	# aussi large qu'un socle de nef, et rien ne dit que c'est ELLE le sujet.
	# Elle s'élargit de 30 % au sol (1,60 × 1,12 m → 2,08 × 1,46 m), en XZ
	# SEULEMENT.
	# L'axe Y est laissé à 1,0 et ce n'est pas un détail : `TABLE_DESSUS` vaut
	# 0,89 m, c'est une cote LUE dans le journal de la chaîne Blender, et
	# l'ancre de récompense s'y appuie. L'étirer verticalement ferait flotter
	# l'offrande de la hauteur exacte de l'étirement — le défaut que l'audit a
	# relevé sur ce lieu (B-f-7) et qui vient d'être corrigé.
	declare_support(table)
	# Le dossier n'est plus une pièce à part : il fait partie du CŒUR, et son
	# corps de collision est donc enfant de la pièce — il hérite ainsi du lacet
	# de 12°, ce qu'une boîte posée sur le lieu n'aurait pas fait. Cotes lues
	# sur le générateur : dossier centré en (0,14 ; −0,74) Blender, c'est-à-dire
	# (0,14 ; +0,74) en repère Godot, 2,05 m de haut.
	# Cotes RELUES sur le générateur après l'élargissement : dossier centré en
	# (0,16 ; −0,86) Blender, donc (0,16 ; +0,86) en repère Godot, rayons
	# 0,54 × 0,26, sommet à 2,03 m. Recopier l'ancienne cote aurait laissé un
	# mur invisible décalé de 12 cm — le genre d'écart qu'aucune capture ne
	# montre et que seule une sonde physique attrape.
	# LOT 1.R.2 — le dossier est passé de 0,54 × 0,26 à 0,80 × 0,32 de rayons
	# (1,60 m de large au lieu de 1,08) : son corps suit, rogné à 1,50 pour
	# rester DANS la pierre. La hauteur, elle, n'a pas bougé d'un centimètre —
	# c'est le plafond d'invisibilité depuis la route, et l'élargissement est
	# le seul levier de masse qui ne l'entame pas.
	K.collider_box(dalle, "Sanctuaire_coeur_dossier",
		Vector3(0.16, 1.02, 0.86), Vector3(1.50, 2.04, 0.62))
	declare_support(_nef_seated(0.16, 0.86))


## LE DALLAGE AVALÉ — le sol du sanctuaire existait ; le bois l'a repris.
##
## LOT 1.R — DE TROIS DALLES À NEUF, ET C'EST CE QUI DESSINE LE LIEU DE LOIN.
## Trois dalles éparses ne font pas un sol : elles font trois taches. Depuis la
## caméra d'identité, à 18 m et 6 m au-dessus, la seule chose qui puisse dire
## « il y a une enceinte ici » est une SURFACE plus sombre que l'herbe — un
## sol dallé se lit comme une empreinte, exactement comme une trace de fouille
## se lit d'avion. La mesure justifie le geste : le dallage rend p50 = 48,5
## contre 67,4 pour l'herbe voisine (`base/shrine_gp_nef.png`), soit 19 niveaux
## d'écart — assez pour marquer une forme sans assombrir le sous-bois.
##
## CE N'EST PAS UN PAVAGE CONTINU, et le contrat l'interdit explicitement
## (« refus : rectangle fermé »). Les neuf dalles sont à des échelles de 0,52 à
## 0,86 — soit 1,04 à 1,72 m pour un module natif de 2 m — avec de vraies
## RESPIRATIONS entre elles, des orientations toutes différentes, et une
## densité qui décroît vers les bords : au centre le sol tient encore, aux
## marges la terre a gagné. Les profondeurs d'enfoncement sont toutes
## distinctes (7 à 14 cm) : deux dalles coplanaires produiraient du z-fighting,
## et le sol du sanctuaire n'a de toute façon aucune raison d'être de niveau.
## LOT 1.R.2 — NEUF DALLES DEVIENNENT QUATRE, ET C'EST LE VERDICT QUI LE
## DEMANDE : « réduire les pierres décoratives sans rôle ».
##
## Le constat est une mesure, pas un avis. Sur la capture héritée, à la
## caméra joueur, AUCUNE des neuf dalles n'est discernable : elles sont
## enfoncées de 7 à 14 cm et l'herbe du semis V2.2 les recouvre. Neuf modules
## du budget D7 pour zéro pixel. Les quatre qui restent sont celles qui
## portent encore un rôle depuis les vues rasantes — le pied du cœur, deux
## appuis de la nef et le devant du seuil ; l'axe, lui, est désormais tenu par
## ce qui DÉPASSE de l'herbe, c'est-à-dire les deux bordures.
const DALLES: Array[Array] = [
	# x, z, lacet, échelle, enfoncement
	# DEUX, ET SUR L'AXE. Les deux autres tombaient dans la travée que la
	# passe suivante a précisément dégagée ; elles n'y étaient pas visibles et
	# elles y ajoutaient du bruit de forme. Restent le pied du cœur et le
	# devant du seuil — les deux endroits où un sol dallé a encore un rôle.
	[-0.15, -0.55, 57.0, 0.86, 0.075],
	[-0.06, -3.62, -41.0, 0.60, 0.135],
]


func _dallage_avale() -> void:
	for spec: Array in DALLES:
		K.module(self, &"Floor_UnevenBrick",
			_nef_seated(float(spec[0]), float(spec[1]))
				+ Vector3(0.0, -float(spec[4]), 0.0),
			_nef_yaw(float(spec[2])), float(spec[3]), TONE_MOUSSE)


## LE RIDEAU SUD — ce qui rend le lieu invisible depuis la route, à 7,3 m.
##
## RENFORCÉ pour le lot 1.R, et pour une raison mesurable : la composition B
## dresse au sud du cœur une pierre de 2,05 m là où l'ancienne version n'avait
## qu'un moignon de 1,32 m. Le rideau avance donc de 4,5-6,0 m à 2,2-6,2 m et
## gagne en hauteur. Toujours AUCUN collider : ils masquent, ils ne ferment
## pas, et le filet des routes ne compte que les corps solides.
##
## `Fern_1` mesure 9,05 m de large en natif ; `KitScale` le ramène à 0,62 m de
## haut (facteur 0,2306), soit 2,09 m d'envergure. `Bush_Common` est la seule
## masse du kit qui monte assez pour couvrir un chevet vu de 7 m.
func _rideau_sud() -> void:
	# LE SIXIÈME BUISSON EST UNE MESURE, PAS UNE DÉCORATION. La capture
	# `apres2/shrine_gp_route_p1.png` — prise depuis la route, au point P1
	# (84, 7, 81), regard nord — montre le rideau faisant son travail SAUF sur
	# une bande : le chevet dépasse d'une trentaine de centimètres au-dessus
	# des buissons, en (630-690, 285-390). La ligne P1 → chevet passe par le
	# local (−0,93 ; 4,0) ; c'est là que va le buisson manquant, et les deux
	# voisins montent d'un cran. Aucun collider, comme tout le rideau : il
	# masque, il ne ferme pas.
	# LOT 1.R.1 — LE RIDEAU SUIT LA RECOMPOSITION, ET DE COMBIEN SE CALCULE.
	# Le bâti a glissé vers l'est ; les lignes de vue depuis P1 (local −2 ; +7)
	# vers les pièces les plus hautes croisent désormais le plan z = 4,0 entre
	# x = −0,7 (muret A) et x = +0,7 (montant B), contre x ≈ −1,1 auparavant.
	# Le rideau se décale donc de +0,70 m en x — pas davantage : il ne
	# s'approche pas de la route d'un centimètre, et il n'a toujours AUCUN
	# collider, par contrat (il masque, il ne ferme pas).
	# LOT 1.R.2 — LE RIDEAU SUIT ENCORE, ET DE COMBIEN SE CALCULE. Le cœur a
	# glissé de (2,50 ; 0,25) à (3,02 ; 0,25) et son dossier de (2,14 ; 0,87)
	# à (3,03 ; 0,96). La ligne P1 (local −1,8 ; 7,1) → dossier croisait le
	# plan z = 4,0 en x = 0,16 ; elle le croise maintenant en x = 0,64. Le
	# rideau se décale donc de +0,45 m en x — pas davantage, et jamais vers le
	# sud : il ne s'approche pas de la route d'un centimètre, et il n'a
	# toujours AUCUN collider (il masque, il ne ferme pas).
	for spec: Array in [[-1.05, 2.95, 41.0, 1.40], [2.60, 3.35, -27.0, 1.55],
			[0.75, 4.55, 66.0, 1.55], [4.30, 3.75, 12.0, 1.15],
			[-2.40, 4.15, -74.0, 1.25], [0.20, 3.95, 28.0, 1.62]]:
		K.module(self, &"Bush_Common", _seated(float(spec[0]), float(spec[1])),
			float(spec[2]), float(spec[3]), K.TONE_PLANT)
	for spec: Array in [[-0.45, 2.25, 41.0, 1.10], [2.05, 2.55, -27.0, 1.20],
			[3.55, 2.90, 66.0, 1.00], [-1.90, 2.70, 12.0, 1.05]]:
		K.module(self, &"Fern_1", _seated(float(spec[0]), float(spec[1])),
			float(spec[2]), float(spec[3]), K.TONE_PLANT)
	# Le bord sud du rideau porte l'emprise visuelle du lieu vers le sud : il
	# DÉCLARE donc son assise, sinon le tiers haut de l'axe Z n'aurait aucun
	# appui et D2 aurait raison de le dire.
	declare_support(_seated(0.75, 4.55))
	declare_support(_seated(-2.40, 4.15))


## Ce qui pousse à l'ombre d'un vestige. Les champignons vont au PIED des
## pierres, jamais au milieu du passage : ils accompagnent la masse, ils ne
## meublent pas le vide.
func _sous_bois() -> void:
	K.module(self, &"Mushroom_Common", _nef_seated(-1.62, -2.72),
		_nef_yaw(0.0), 1.0, K.TONE_PLANT)
	# D7 — consolidation d'intégration (lead) : l'itération structurelle a
	# porté le lieu à 43 modules pour un plafond de 40. Retirés : le second
	# Mushroom_Common et les deux Pebble_* — trois micro-décors qui ne portent
	# aucun trait du contrat (seuil/enceinte/cœur et dallage avalé intacts).
	# Le plafond n'a PAS bougé.
	K.module(self, &"Mushroom_Laetiporus", _nef_seated(-1.10, 0.55),
		_nef_yaw(-55.0), 0.75, K.TONE_PLANT)


## LE COUVERT — trois troncs, tous au NORD et à l'OUEST, jamais au sud.
##
## Deux raisons, et la seconde décide : au sud passe la route, et un tronc
## porte un collider ; on ne place pas un collider à cette distance pour un
## effet qu'un buisson sans collider obtient aussi bien.
##
## LOT 1.R — ILS SONT DÉPLACÉS, ET LA VÉRIFICATION EXIGÉE PAR LE LEAD EST
## FAITE DANS LE CODE : ces trois troncs-là sont posés PAR CE FICHIER, ligne
## ci-dessous, et n'appartiennent donc pas au semis V2.2 gelé (lequel est bâti
## par `world_v2_vegetation_builder.gd` sous `WorldV2/Vegetation`, un autre
## sous-arbre, que ce lieu ne touche jamais). Le gel reste intact : si un
## tronc GELÉ bloque encore l'approche nord, il reste où il est et la
## composition fait avec — c'est l'arbitrage du lead, et `probe_sanctuaire.gd`
## recense ce qui est gelé autour du site pour que le constat soit une mesure.
##
## Ils passent de r ≈ 7,5-9 m à r ≈ 4,5-6,5 m et se placent en FLANC de la
## nef, hors de l'axe de visée des trois caméras du plan (qui arrivent toutes
## du nord) : ils encadrent au lieu de masquer, et le couvert se referme sur
## les côtés pendant que le dessus du cœur reste ouvert.
func _couvert() -> void:
	# RECALÉS SUR CAPTURE : à (−4,60 ; −4,20) et (4,40 ; −3,60) les deux pins
	# tombaient SUR l'axe de visée de `forest_shrine_joueur_b` et de
	# `shrine_gp_nef` — un tronc en plein milieu de la nef, ce qui est
	# précisément le reproche « les arbres masquent au lieu de cadrer ». Les
	# lignes de visée des trois caméras gelées passent par le centre du lieu ;
	# à z ≈ −2 elles sont à |x| ≤ 1,3 m. Les pins vont donc à |x| ≈ 6 : ils
	# tiennent le bord du cadre et laissent la nef libre.
	# LOT 1.R.1 — LE PIN DE L'EST DEVIENT LE MONTANT GAUCHE DU CADRE.
	# Il était en (5,70 ; −2,20) ; le seuil recomposé y passe à 1,08 m, donc
	# DANS son tronc. Il part en (6,90 ; 0,40) : 2,27 m du montant le plus
	# proche, et il projette à x ≈ 196 px — le bord gauche du cadre joueur,
	# exactement le rôle qu'on lui demande maintenant que le sujet est à
	# gauche du tronc gelé. Les deux autres ne bougent pas : à x ≈ 823 et 898
	# ils ferment déjà le cadre à droite, au-delà du tronc.
	for spec: Array in [[-5.90, -1.40, 33.0, 1.00, &"Pine_3"],
			[6.90, 0.40, -47.0, 0.90, &"Pine_3"],
			[-6.40, 1.20, 15.0, 0.85, &"CommonTree_3"]]:
		var at: Vector3 = _seated(float(spec[0]), float(spec[1]))
		K.module(self, spec[4] as StringName, at, float(spec[2]),
			float(spec[3]), K.TONE_PLANT)
		declare_support(at)


## LES COLLISIONS — onze volumes, et le choix de ce qui n'en reçoit PAS est
## aussi délibéré que celui de ce qui en reçoit.
##
## En reçoivent : la dalle du cœur, son dossier (enfant de la pièce, pour
## hériter du lacet), les deux montants du seuil, les TROIS MURETS, la pierre
## couchée, les trois troncs. N'en reçoivent pas : la marche, le linteau tombé
## et les blocs tombés au pied des murets — tous sous la hauteur de marche du
## héros, on les enjambe. Le rideau sud n'en a aucun, par contrat : il masque,
## il ne ferme pas.
##
## LOT 1.R.1 : le compte NE MONTE PAS malgré les trois murets, parce que dix
## pièces disparaissent en même temps — quatre corps de socle deviennent trois
## corps de muret. Onze `CollisionShape3D` pour un plafond de 20.
## Le couloir libre entre les deux murets latéraux vaut ≈ 2,1 m au plus
## étroit ; la capsule du héros (0,80 m) y passe. À VÉRIFIER PAR SONDE
## PHYSIQUE, pas par ce calcul — `tools/godot/probe_sanctuaire.gd`.
func _collisions() -> void:
	# LA DALLE DU CŒUR. Emprise RELUE sur le générateur après l'élargissement :
	# contour elliptique 1,26 × 0,80 de demi-axes, contreforts à |x| ≈ 1,3 —
	# soit ≈ 2,95 × 1,75 m au sol, dessus de dalle toujours à 0,89 m.
	K.collider_box(self, "Sanctuaire_coeur_dalle",
		_nef_seated(0.0, 0.0) + Vector3(0.0, 0.45, 0.0),
		Vector3(2.95, 0.90, 1.75), _nef_yaw(12.0))
	# LE CORPS DU DOSSIER N'EST PAS ICI : il est enfant de la pièce, posé dans
	# `_coeur()`, pour hériter du lacet du cœur.
	# Les montants ont BAISSÉ (1,33 et 0,96 m sur le maillage, brisure comprise
	# — cotes lues dans le journal de génération, pas déduites de la hauteur
	# demandée) : leurs corps suivent, sinon deux murs invisibles dépasseraient
	# la pierre de 20 cm.
	# LOT 1.R.2 — cotes RELUES dans le journal de génération après
	# l'abaissement des montants, jamais recopiées : le maillage sort à
	# 0,64 × 0,49 × 1,15 (ouest) et 0,50 × 0,53 × 0,84 (est), la brisure
	# rabattant les sommets sous les 1,34 et 0,98 demandés. Garder l'ancien
	# 1,33 laisserait un mur invisible dépasser la pierre de 18 cm, en
	# silence — l'écart qu'aucune capture ne montre.
	K.collider_box(self, "Sanctuaire_montant_ouest",
		_nef_seated(-0.82, -3.30) + Vector3(0.0, 0.825, 0.0),
		Vector3(0.64, 1.65, 0.49), _nef_yaw(24.0))
	K.collider_box(self, "Sanctuaire_montant_est",
		_nef_seated(0.80, -3.50) + Vector3(0.0, 0.625, 0.0),
		Vector3(0.50, 1.26, 0.53), _nef_yaw(-58.0))
	# LES TROIS MURETS. Ils reçoivent tous un corps, contrairement aux socles
	# bas qu'ils remplacent : un muret est un MUR, et un mur qu'on traverse
	# n'est pas une enceinte. Longueurs lues sur le maillage (2,65 / 2,22 /
	# 1,69 m), moins l'enfoncement sur la hauteur.
	for index: int in range(MURETS.size()):
		var spec: Array = MURETS[index]
		var h: float = float(spec[5]) - MURET_ENFONCEMENT
		var longueur: float = MURET_LONGUEURS[index]
		K.collider_box(self, "Sanctuaire_muret_%d" % index,
			_nef_seated(float(spec[1]), float(spec[2]))
				+ Vector3(0.0, h * 0.5, 0.0),
			Vector3(longueur, h, 0.58), _nef_yaw(float(spec[3])))
	# La pierre couchée : un corps de 0,30 m, sous la hauteur de marche. Il la
	# suit au bord ouest, et son lacet suit sa nouvelle orientation — un corps
	# resté sur l'ancienne position serait un mur invisible en travers d'une
	# nef qu'on vient justement de dégager.
	K.collider_box(self, "Sanctuaire_pierre_couchee",
		_nef_seated(-1.70, -1.30) + Vector3(0.0, 0.15, 0.0),
		Vector3(0.58, 0.30, 1.85), _nef_yaw(12.0))
	# LES DEUX BORDURES DE NEF. Cotes RELUES sur le maillage exporté après
	# leur relèvement, jamais recopiées de la demande : le générateur rabat
	# les sommets par sa brisure.
	K.collider_box(self, "Sanctuaire_bordure_g",
		_nef_seated(-0.80, -2.20) + Vector3(0.0, 0.30, 0.0),
		Vector3(0.50, 0.60, 1.76), _nef_yaw(6.0))
	K.collider_box(self, "Sanctuaire_bordure_d",
		_nef_seated(0.78, -2.35) + Vector3(0.0, 0.21, 0.0),
		Vector3(0.47, 0.42, 1.46), _nef_yaw(-6.0))
	for spec: Array in [[-5.90, -1.40], [6.90, 0.40], [-6.40, 1.20]]:
		K.collider_box(self, "Sanctuaire_tronc_%d" % get_child_count(),
			_seated(float(spec[0]), float(spec[1]))
				+ Vector3(0.0, 2.6, 0.0), Vector3(0.85, 5.2, 0.85))


## Extrait UNE pièce du GLB du vestige (recette `_piece_tour` de la tour) :
## l'instance est élaguée AVANT d'entrer dans l'arbre et porte un nom
## explicite — Godot rebaptise les homonymes en `@Node3D@366`, et six socles
## tirés de trois maillages en produiraient trois paires (`scripts/CLAUDE.md`).
func _piece_vestige(piece: String, at: Vector3, rot: Vector3,
		nom: String = "") -> Node3D:
	var instance: Node3D = VESTIGE_SCENE.instantiate() as Node3D
	instance.name = piece
	for enfant: Node in instance.get_children():
		if String(enfant.name) != piece:
			instance.remove_child(enfant)
			enfant.free()
		else:
			enfant.name = "%s_maille" % piece
	if not nom.is_empty():
		instance.name = nom
	add_child(instance)
	instance.position = at
	instance.rotation = rot
	_peindre_vestige(instance)
	return instance


## Aplat painterly sur les matériaux du GLB — matériaux DUPLIQUÉS et mis en
## cache, jamais de mutation d'une ressource importée (recette `_peindre_glb`
## de la ferme R2B.2 et de la tour).
##
## AUCUNE CARTE N'EST BRANCHÉE ICI, et c'est une leçon payée dans ce même lot :
## sur les pièces tombées de la tour, `T_UnevenBrick_BaseColor` box-projetée
## sur des facettes de 0,3 m échantillonne surtout le mortier peint et sort
## « chocolat glacé ». La famille qui s'intègre au terrain gelé est celle des
## falaises — aplat plus facettes. Un vestige moussu est de cette famille-là.
func _peindre_vestige(racine: Node3D) -> void:
	for node: Node in racine.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var base: StandardMaterial3D = instance.get_active_material(
				surface) as StandardMaterial3D
			if base == null:
				continue
			var famille: String = base.resource_name
			var cle: String = "sanctuaire|%d" % base.get_instance_id()
			var mat: StandardMaterial3D = \
				_cache_vestige.get(cle) as StandardMaterial3D
			if mat == null:
				mat = base.duplicate() as StandardMaterial3D
				mat.roughness = maxf(mat.roughness, 0.95)
				mat.metallic_specular = 0.1
				# LE MULTIPLICATEUR DE COULEUR DE SOMMET, sans quoi le
				# `COLOR_0` du GLB ne sert à rien : Godot ne l'active pas
				# forcément à l'import, et un aplat sans variation est
				# exactement ce que la première capture a montré (ISS-066).
				# L'albédo ci-dessous devient donc une TEINTE, et la variation
				# vient du maillage : strates, veines, pied assombri.
				mat.vertex_color_use_as_albedo = true
				if TEINTES_VESTIGE.has(famille):
					mat.albedo_color = TEINTES_VESTIGE[famille] as Color
				_cache_vestige[cle] = mat
			instance.set_surface_override_material(surface, mat)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)


## ISS-059 — fin de vie du cache statique. Inscrite au démarrage du script
## par `_static_init()`, appelée UNE fois à l'extinction du moteur par
## `SceneFlow._exit_tree()`. Sans elle, ces entrées vivent jusqu'à la mort du
## processus et sortent au rapport de fuite.
##
## AJOUTÉE au lot 1.R : ce lieu a gagné un cache statique en même temps que
## son GLB dédié, et l'invariant `test_tout_cache_statique_de_ressources_est_liberable`
## l'a vu — 960 tests verts, un seul rouge, et c'était celui-là.
##
## Le sens de la dépendance est imposé : le porteur connaît le noyau, le
## noyau ne connaît aucun porteur (test_aucune_reference_croisee_interdite).
static func _static_init() -> void:
	StaticResourceCaches.enregistrer("ForestShrinePlace", liberer_caches)


static func liberer_caches() -> int:
	var n: int = _cache_vestige.size()
	_cache_vestige.clear()
	return n
