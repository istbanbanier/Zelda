## ÉCHELLE DU KIT VÉGÉTAL — correction mesurée, pas devinée.
##
## Trouvé par le premier playtest en boîte noire : sur la capture `pas_0036`,
## une fleur jaune occupe un quart de l'écran et dépasse la poitrine d'un héros
## d'1,78 m. Mesure à la source, hors moteur :
##
##     python3 tools/gltf_inspect.py assets/environment/foliage/Flower_4_Group.gltf
##     dimensions_m : [1.7805, 2.4868, 1.3675]
##
## Soit une fleur de **2,49 m**. La bible visuelle §3 borne les fleurs à
## 0,18–0,55 m. Le kit entier a été importé sans normalisation d'échelle, et
## posé à `factor = 1.0` par six modules différents.
##
## Ce n'est pas un défaut de goût, c'est une violation de l'invariant du
## projet : **1 unité = 1 m**. Une fougère de neuf mètres de large casse la
## lecture d'échelle de toute la vallée, donc la profondeur, donc la
## composition North Star.
##
## Pourquoi ici et pas dans chaque module : `valley_relics`, `valley_ruins`,
## `valley_territories`, `valley_undergrounds`, `valley_caves`, `hamlets` et
## `riverside_village` ont chacun leur `_spawn`. Corriger sept fois, c'est
## garantir qu'un huitième oubliera. La correction vit donc en un seul point,
## consultée par tous.
##
## Le facteur du site d'appel reste une VARIATION (0,85 à 1,3 selon les
## placements existants) et se multiplie à la correction — aucun site ne
## compensait déjà, vérifié avant d'écrire cette table.
class_name KitScale
extends RefCounted

## Hauteur native mesurée (m) → hauteur voulue (m), et le facteur qui en
## découle. Les trois colonnes sont conservées pour que la table soit
## VÉRIFIABLE : on peut remesurer le `.gltf` et refaire la division.
##
## Cibles issues de la bible visuelle §3 et §7.1 :
##   herbe courte 0,18–0,35 · herbe longue 0,55–0,95 · fleurs 0,18–0,55 ·
##   fougère basse · buissons 0,7–2,2 · arbres 5–12 (spécimens 14–17).
##
## Les arbres, pins, buissons et champignons ne figurent pas ici : mesurés,
## ils tombent déjà dans les bornes. On ne corrige que ce qui est démontré
## faux.
const MEASURED: Dictionary = {
	# asset                    : [natif_m, cible_m]
	&"Flower_3_Single":          [2.068, 0.42],
	&"Flower_4_Single":          [2.419, 0.45],
	&"Flower_3_Group":           [2.055, 0.52],
	&"Flower_4_Group":           [2.487, 0.55],
	&"Grass_Common_Short":       [1.330, 0.30],
	&"Grass_Wispy_Short":        [1.070, 0.28],
	&"Grass_Common_Tall":        [1.873, 0.85],
	&"Grass_Wispy_Tall":         [1.670, 0.80],
	&"Clover_1":                 [1.145, 0.16],
	&"Clover_2":                 [1.260, 0.17],
	&"Fern_1":                   [2.689, 0.62],
	&"Plant_1":                  [1.014, 0.55],
	&"Plant_1_Big":              [3.756, 1.60],
	# Lot 12 — kit FALAISE Kenney (CC0, ART-K1) : autoré à l'échelle
	# « tuile » (un bloc de falaise mesure 1 m de haut). Posé tel quel,
	# il ferait un caillou devant un héros d'1,78 m. Cibles issues de
	# la bible §3 : modules de falaise 6-28 m, rochers proches 0,15-4 m.
	&"cliff_large_rock":         [1.000, 11.0],
	&"cliff_blockSlope_rock":    [1.000, 9.0],
	&"cliff_half_rock":          [0.500, 4.5],
	&"cliff_corner_rock":        [1.000, 10.0],
	&"cliff_cornerLarge_rock":   [1.000, 12.0],
	&"rock_largeA":              [0.260, 1.10],
	&"rock_largeC":              [0.321, 1.55],
	&"rock_smallB":              [0.177, 0.55],
	# Lot 13 — kit de RIVE Quaternius Ultimate Nature (CC0, ART-Q9),
	# format OBJ. Les saules sont autorés à ~2,4-2,9 m : à cette
	# taille, un « arbre » arrive à l'épaule du héros. Cible bible §3 :
	# arbre 5-12 m. Rochers, souche et tronc tombent déjà juste.
	&"Willow_1":                 [2.850, 8.20],
	&"Willow_3":                 [2.350, 6.60],
	&"Willow_5":                 [2.420, 7.40],
}

## Hauteur maximale tolérée par famille, utilisée par le test de régression.
## Un asset absent de `MEASURED` doit quand même respecter sa famille.
const FAMILY_CEILING: Dictionary = {
	&"flower": 0.60,
	&"grass": 0.95,
	&"clover": 0.35,
	&"fern": 0.90,
	&"bush": 2.20,
	&"tree": 19.00,
	&"cliff": 28.00,
	&"rock": 4.00,
}


## Facteur correctif d'un asset du kit. 1.0 pour tout ce qui n'a pas été
## mesuré faux : on ne redimensionne pas au hasard.
static func factor(asset: String) -> float:
	var key: StringName = StringName(asset)
	if not MEASURED.has(key):
		return 1.0
	var pair: Array = MEASURED[key]
	var native: float = float(pair[0])
	if native <= 0.001:
		return 1.0
	return float(pair[1]) / native


## Hauteur attendue une fois corrigée, en mètres. Sert aux tests et aux
## messages d'erreur lisibles.
static func target_height(asset: String) -> float:
	var key: StringName = StringName(asset)
	if not MEASURED.has(key):
		return 0.0
	return float((MEASURED[key] as Array)[1])


## Famille déduite du nom, pour le plafond de régression. Renvoie une chaîne
## vide si l'asset n'appartient à aucune famille bornée.
static func family(asset: String) -> StringName:
	var lower: String = asset.to_lower()
	if lower.begins_with("flower"):
		return &"flower"
	if lower.begins_with("grass"):
		return &"grass"
	if lower.begins_with("clover"):
		return &"clover"
	if lower.begins_with("fern"):
		return &"fern"
	if lower.begins_with("bush"):
		return &"bush"
	if lower.contains("tree") or lower.begins_with("pine"):
		return &"tree"
	return &""
