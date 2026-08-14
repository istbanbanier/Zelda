## VILLAGE DE LA RIVIÈRE (`valley.poi.riverside_village.01`, r03) — le
## lieu habité de la route de la rivière.
##
## R2a — RECONSTRUCTION. Le lead a rejeté la version précédente sur trois
## points, tous diagnostiqués avant d'écrire une ligne :
##
##  1. « une maison domine ». `_house()` était appelée deux fois avec le
##     MÊME `span = 6` : deux bâtis identiques, mêmes murs de 3,12 m, même
##     `Roof_RoundTiles_6x6`, faîte identique à 8,79 m. Le troisième volume
##     était un empilement de neuf `stone_block`. Une silhouette dupliquée
##     n'est pas une silhouette collective.
##  2. Toitures qui s'intersectaient — jamais nommé, mais présent et
##     démontrable : centres (−4,5 ; 6,0) et (3,5 ; 11,0), distance
##     9,43 m ; `Roof_RoundTiles_6x6` mesuré 8,25 × 8,03. Projections SAT
##     sur l'axe des centres : 4,33 + 5,70 = 10,03 > 9,43, soit 0,60 m
##     d'interpénétration, au même niveau.
##  3. « éléments blancs non finis ». `K.stone_block()` multiplie la teinte
##     par un `shade` allant jusqu'à 1,08 ; `TONE_STONE` × 1,08 donne
##     (1,03 ; 0,95 ; 0,84), écrêté. Sonde du lieu monté : `Margelle_2` à
##     (0,99 ; 0,91 ; 0,81) et `Margelle_5` à (1,00 ; 0,93 ; 0,82). Capture
##     fraîche : 3,1 % des pixels à luminance 1,0 ; raycast à travers ces
##     pixels → `Puits_col`. C'était le puits.
##
## En revanche, les « fenêtres posées au sol » n'existaient PAS ici : le
## fichier ne contenait ni `Window_Wide_Round1` (assise 1,016 m) ni
## `Prop_Support` (1,211 m), et passait déjà par `Wall_*_Window_*`. Le
## piège reste réel — il est évité par construction, voir `_pose()`.
##
## CE QUI PORTE LA SILHOUETTE COLLECTIVE. Quatre volumes, quatre
## orientations, quatre hauteurs séparées d'au moins 2,8 m :
##   auberge 6×8 à deux niveaux, faîte 11,9 m, yaw 0° ;
##   maison 4×6 à un niveau, faîte 7,3 m, yaw 28° ;
##   halle-forge OUVERTE à toit en appentis, 3,3 m, yaw 96° ;
##   séchoir posé SUR le quai, 1,4 m au-dessus du datum, yaw 8°.
## Aucun bâtiment ne réutilise le gabarit d'un autre, et deux d'entre eux
## n'ont pas de mur plein : ils se lisent comme des dépendances.
##
## LE TERRAIN GELÉ COMMANDE, et il a corrigé deux intentions :
##  * il n'y a PAS de scarpe à cet endroit — le sol passe de 1,69 (tête de
##    la rampe du gué) à 3,00 (terrasse) en formant une cuvette douce, pas
##    un ressaut. Le mur de soutènement rêvé au plan devient donc ce que le
##    relief autorise : des assises de plinthe sous les bâtis et un parapet
##    d'un rang au bord de la place. La vraie descente du hameau, elle, est
##    réelle et mesurée : place 3,00 → platelage 1,15 → eau 0,65.
##  * la berge REMONTE vers le nord (0,61 à z local −5,0 ; 1,45 à −3,2) :
##    la passerelle du quai monte, elle ne descend pas.
##
## LES RAYONS DU GUÉ DESSINENT LA RUE. `ford.west` est à (−96, 22), soit
## local (0, −8) ; ISS-032 le sonde par huit azimuts sur 12 m au sol
## PHYSIQUE, marche maximale 1,0355 m/m. Le terrain nu consomme déjà 0,50
## sur les rayons 45°, 90° et 135° : il ne reste que 0,53 m. Aucun collider
## ne peut donc vivre sous |x| < 2,5 tant que z < +5,5. Cette contrainte
## n'est pas subie : la trouée qu'elle impose EST la rue qui monte du gué.
class_name RiversideVillagePlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")
const QUAI_SCENE: PackedScene = preload(
	"res://assets/architecture/village/SM_Village_Quay.glb")
const MUR_SCENE: PackedScene = preload(
	"res://assets/architecture/village/SM_Village_Wall.glb")

const MODULE: float = 2.0
const WALL_H: float = 3.12
const DOOR_GAP: float = 1.30

## Assise mesurée du module de mur (`SM_Village_Wall.glb`) : une assise de
## 0,45 m à empiler, plus un couronnement de 0,16 m.
const ASSISE_H: float = 0.45
const ASSISE_L: float = 4.00

## Cotes du quai, toutes issues de la sonde du terrain GELÉ (2026-08-14) :
## eau 0,695 → 0,635 sous le platelage ; lit 0,24 → 0,05 ; berge nord 0,55
## (ouest) → 1,05 (est). Le GLB porte son Z = 0 au point le plus bas du lit.
const QUAI_ORIGINE: Vector3 = Vector3(16.5, 0.05, -7.5)
const QUAI_PONT_MONDE: float = 1.15

## Racine du lieu : le bâtisseur l'assoit sur le sol, mesuré à 1,695.
const RACINE_MONDE_Y: float = 1.695

# ---------------------------------------------------------------------------
# TEINTES LOCALES — par NOM DE MATÉRIAU SOURCE, jamais par module.
#
# Les modules CC0 portent tous `albedo_color = (1,1,1)` + une texture : la
# valeur vient donc de la texture MULTIPLIÉE par la teinte. Or
# `K.apply_tone()` teinte toutes les surfaces d'un module d'un seul coup,
# ce qui interdit de distinguer l'enduit de sa boiserie. On surcharge donc
# ici surface par surface, en lisant le nom du matériau importé.
#
# LES CONSTANTES DU KIT NE SONT PAS TOUCHÉES : ce sont des `Color`
# littérales, propres à ce fichier. Le camp, la ferme, le bassin et l'arbre
# gardent exactement leurs valeurs — aucune propagation.
#
# MOYENNES sRGB DES TEXTURES, mesurées sur les PNG du dépôt :
#   T_Plaster 0,685 · T_UnevenBrick 0,530 · T_Brick 0,575
#   T_RoundTiles 0,697/0,329/0,187 · T_WoodTrim 0,545
#   T_Trim_Furniture 0,545 · T_Trim_Props 0,601 · PathRocks 0,301
#
# CIBLES DE VALEUR RENDUE (briefing §3.3) : trois bandes séparées d'environ
# 0,15, faute de quoi l'écart d'éclairement (×1,6 mesuré sur ce monde)
# égale l'écart de matière et tout se lit dans une seule valeur — le
# défaut exact relevé sur la capture précédente, où l'enduit au soleil
# (0,500) et l'enduit à l'ombre (0,495) étaient indiscernables, et où le
# pavage (0,534) battait les murs.
#   enduit  → clair  ≈ 0,68 au soleil    albédo visé 0,42
#   brique  → moyen  ≈ 0,52              albédo visé 0,33
#   bois    → sombre ≈ 0,35              albédo visé 0,22
#   pavage  → jamais plus clair que l'enduit
# CES NOMBRES SERONT RECALÉS SUR LA CAPTURE : un albédo n'est pas une
# valeur rendue.
# ---------------------------------------------------------------------------
const TEINTES: Dictionary = {
	"MI_Plaster": Color(0.62, 0.57, 0.50),
	"MI_UnevenBrick": Color(0.62, 0.58, 0.52),
	"MI_Brick": Color(0.57, 0.53, 0.48),
	"MI_RedBrick": Color(0.50, 0.47, 0.44),
	"MI_RoundTiles": Color(0.52, 0.62, 0.72),
	"MI_WoodTrim": Color(0.40, 0.42, 0.44),
	"MI_RockTrim": Color(0.55, 0.53, 0.50),
	"MI_Trim_Furniture": Color(0.42, 0.44, 0.46),
	"MI_Trim_Props": Color(0.45, 0.44, 0.43),
	"MI_Trim_Cloth": Color(0.56, 0.46, 0.38),
	"MI_Trim_Metal": Color(0.40, 0.40, 0.42),
	"MI_MetalOrnaments": Color(0.40, 0.40, 0.42),
	# Le pavage rendait BLEU-ARDOISE et froid, en contradiction avec le
	# village : la texture `PathRocks` moyenne (0,301 ; 0,348 ; 0,228) tire
	# déjà au vert, et une teinte neutre l'y enfonçait. Teinte chaude.
	"PathRocks": Color(0.72, 0.60, 0.46),
}
const TEINTE_DEFAUT: Color = Color(0.52, 0.50, 0.47)
## Plafond dur : aucune surface du hameau au-dessus de cet albédo. Le
## défaut « éléments blancs » venait précisément d'un dépassement de 1,0.
const ALBEDO_MAX: float = 0.80

static var _cache_teintes: Dictionary = {}

# ---------------------------------------------------------------------------
# IMPLANTATION — la table est la donnée, `_verifier_implantation()` en est
# le filet. Les marges tenues à la main se perdent à la première retouche.
# ---------------------------------------------------------------------------
## Segments LOCAUX de la route de la rivière, relus dans
## `world_v2_layout.json` (`river_route`) et non recopiés de mémoire :
## monde (−72,27) → (−92,29) → (−96,22) → (−60,10).
const ROUTE_LOCALE: Array[Vector2] = [
	Vector2(24.0, -3.0), Vector2(4.0, -1.0), Vector2(0.0, -8.0),
	Vector2(36.0, -20.0),
]
const ROUTE_DEGAGEMENT: float = 1.2
## Gué ouest en coordonnées LOCALES, et son rayon de sonde.
const GUE_LOCAL: Vector2 = Vector2(0.0, -8.0)
const GUE_RAYON_M: int = 12

var _empreintes_toit: Array[Dictionary] = []
var _empreintes_col: Array[Dictionary] = []


func default_place_id() -> StringName:
	return &"valley.poi.riverside_village.01"


func _build() -> void:
	_parapet()
	_auberge()
	_maison_du_passeur()
	_halle_forge()
	_place_commune()
	_quai()
	_voirie()
	_poi_area()
	# Récompense canonique : l'épée au sol, sur la place, visible depuis la
	# rampe du gué et hors de tout rayon de sonde.
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.WEAPON,
		_au_sol(4.6, 3.4) + Vector3(0.0, 0.10, 0.0), Vector3(1.2, 0.0, 1.2))
	_verifier_implantation()


# ===========================================================================
# LES QUATRE VOLUMES
# ===========================================================================

## B1 — AUBERGE DU GUÉ. Le seul volume massif : 6 × 8 m, DEUX niveaux,
## faîte à 11,9 m. Elle tient la rive ouest, plus haute, comme le veut le
## contrat, et son rez-de-chaussée est l'intérieur crédible.
##
## Elle est à demi dans l'ombre de la falaise : la crête mesurée culmine à
## 9,85 (x local −20) et le soleil est à 23° d'élévation, azimut 199,5° —
## l'ombre monte donc jusqu'à y = 4,0 à l'aplomb de l'auberge. Rez sombre,
## étage et toiture au soleil : c'est un clair-obscur voulu, à vérifier au
## pixel et non à espérer.
func _auberge() -> void:
	var maison: Node3D = _batiment({
		"nom": "Auberge",
		"centre": Vector2(-7.0, 7.5),
		"yaw": 0.0,
		"travees_x": 3, "travees_z": 4,
		"niveaux": 2,
		"style": "plaster",
		"porte": "z-",
		"toit": &"Roof_RoundTiles_6x8",
		"pignon": &"Roof_Front_Brick6",
		"toit_emprise": Vector2(8.25, 9.68),
		"cheminee": Vector2(-1.9, -2.4),
		"balcon": true,
	})
	_interieur_auberge(maison)


## B2 — MAISON DU PASSEUR. 4 × 6, un seul niveau, faîte 7,3 m, tournée de
## 28° : elle referme la place au nord-est sans s'aligner sur l'auberge.
func _maison_du_passeur() -> void:
	_batiment({
		"nom": "MaisonPasseur",
		"centre": Vector2(3.5, 11.0),
		"yaw": 28.0,
		"travees_x": 2, "travees_z": 3,
		"niveaux": 1,
		"style": "brick",
		"porte": "z-",
		"toit": &"Roof_RoundTiles_4x6",
		"pignon": &"Roof_Front_Brick4",
		"toit_emprise": Vector2(5.51, 7.57),
		"cheminee": Vector2(1.2, 1.9),
	})


## B3 — HALLE-FORGE. OUVERTE : six poteaux, un seul mur de fond, toit en
## APPENTIS à faible pente. Faîte 3,3 m au-dessus de son sol, soit 3,25 m
## au-dessus du datum de la terrasse.
##
## Pourquoi un appentis et pas un toit à deux pentes : n'importe quel
## `Roof_RoundTiles_*` mesure au moins 4,23 m de haut à lui seul, ce qui
## aurait placé la halle à 6,7 m — à 0,6 m de la maison. La séparation des
## hauteurs vient de la TYPOLOGIE, pas d'un réglage.
func _halle_forge() -> void:
	var halle: Node3D = Node3D.new()
	halle.name = "HalleForge"
	add_child(halle)
	var centre: Vector2 = Vector2(11.0, 4.4)
	var yaw: float = 96.0
	var sol: float = _assiette(centre, Vector2(6.0, 4.0), yaw, halle.name)
	halle.position = Vector3(centre.x, sol, centre.y)
	halle.rotation.y = deg_to_rad(yaw)

	# Sol de terre battue : une plaque CONTINUE, jamais des dalles éparses.
	# L'herbe gelée (647 touffes mesurées dans 26 m) passe entre les dalles
	# disjointes — défaut déjà constaté sur la grotte.
	_sol_plein(halle, Vector3(0.0, 0.05, 0.0), Vector3(6.2, 0.16, 4.2),
		Color(0.40, 0.34, 0.27), 7010)

	# Poteaux : bas côté rivière, hauts côté fond — c'est la pente du toit.
	var bas: float = 2.30
	var haut: float = 3.05
	for i: int in range(3):
		var x: float = -2.0 + float(i) * 2.0
		_poteau(halle, "PoteauAvant_%d" % i, Vector3(x, 0.0, 1.9), bas, 0.17)
		_poteau(halle, "PoteauFond_%d" % i, Vector3(x, 0.0, -1.9), haut, 0.19)
	# Un seul mur plein, au fond : la halle reste traversable du regard.
	for i2: int in range(3):
		var x2: float = -2.0 + float(i2) * 2.0
		_module(halle, &"Wall_UnevenBrick_Straight", Vector3(x2, 0.10, -2.0),
			180.0)
	_collider(halle, "HalleFond_col", Vector3(0.0, 1.56, -2.0),
		Vector3(6.2, 3.12, 0.42))
	# Toiture d'appentis : panneaux de tuiles plates posés sur la pente.
	#
	# PAS DE 1,90 m POUR DES PANNEAUX DE 2,00 × 2,02 : au pas de 2 m ils se
	# touchaient bord à bord et laissaient passer le jour entre chaque
	# tuile (vu sur `vue02`). Ils se recouvrent maintenant de 10 cm en X et
	# de 60 cm en Z, comme des tuiles posées.
	for i3: int in range(3):
		var x3: float = -1.9 + float(i3) * 1.9
		for j: int in range(3):
			var z3: float = -1.4 + float(j) * 1.4
			var y3: float = lerpf(haut, bas, (z3 + 2.0) / 4.0) + 0.12
			var panneau: Node3D = _module(halle, &"Overhang_Roof_UnevenBricks",
				Vector3(x3, y3, z3), 0.0, 1.06)
			if panneau != null:
				panneau.rotation.x = deg_to_rad(-10.5)
	# Sablières : 4,60 m et non 6,40 — au premier jet elles dépassaient de
	# 1,20 m de part et d'autre des poteaux et se lisaient, à hauteur de
	# joueur, comme un rail flottant au-dessus de l'herbe.
	_poutre(halle, "Sabliere_fond", Vector3(0.0, haut + 0.06, -1.9),
		Vector3(4.6, 0.16, 0.18), Color(0.30, 0.24, 0.18), 7020)
	_poutre(halle, "Sabliere_avant", Vector3(0.0, bas + 0.06, 1.9),
		Vector3(4.6, 0.16, 0.18), Color(0.30, 0.24, 0.18), 7021)

	# L'atelier, meublé PAR FONCTION : feu, frappe, affûtage, stock.
	_module(halle, &"Anvil_Log", Vector3(-1.4, 0.13, 0.2), 24.0)
	_pose(halle, &"Anvil", Vector3(-1.4, 1.20, 0.2), 24.0)
	_module(halle, &"Workbench", Vector3(1.6, 0.13, -1.2), 90.0)
	_module(halle, &"Whetstone", Vector3(2.2, 0.13, 0.9), -40.0)
	_module(halle, &"Barrel_Holder", Vector3(-2.4, 0.13, -1.1), 0.0)
	_module(halle, &"Crate_Wooden", Vector3(2.5, 0.13, -1.7), 15.0)
	_module(halle, &"FarmCrate_Carrot", Vector3(0.6, 0.13, 1.5), -20.0)
	_pose(halle, &"Axe_Bronze", Vector3(1.6, 1.02, -1.2), 8.0)
	_pose(halle, &"Torch_Metal", Vector3(-3.0, 1.95, -1.85), 0.0)
	_collider(halle, "HalleSol_col", Vector3(0.0, -0.10, 0.0),
		Vector3(6.2, 0.40, 4.2))
	_noter_toit(centre, Vector2(6.4, 4.4), yaw, "HalleForge")
	_noter_col(centre, Vector2(6.2, 4.2), yaw, "HalleForge")


# ===========================================================================
# BÂTIMENT GÉNÉRIQUE — rectangulaire, à niveaux, sur assises de plinthe
# ===========================================================================

## Un bâti rectangulaire de `travees_x` × `travees_z` travées de 2 m.
##
## LA PLINTHE N'EST PLUS UNE BOÎTE. Le lead avait rejeté « le gros
## rectangle de fondation » ; la réponse d'alors — vingt `stone_block` en
## pourtour — reproduisait le défaut à l'échelle du bloc. Ici le pourtour
## reçoit des ASSISES loftées (`SM_Village_Wall.glb`), volume continu à
## fruit et à joints creusés dans le profil.
func _batiment(spec: Dictionary) -> Node3D:
	var maison: Node3D = Node3D.new()
	maison.name = String(spec["nom"])
	add_child(maison)
	var centre: Vector2 = spec["centre"] as Vector2
	var yaw: float = float(spec["yaw"])
	var tx: int = int(spec["travees_x"])
	var tz: int = int(spec["travees_z"])
	var span_x: float = float(tx) * MODULE
	var span_z: float = float(tz) * MODULE
	var niveaux: int = int(spec["niveaux"])
	var style: String = String(spec["style"])

	var sol: float = _assiette(centre, Vector2(span_x, span_z), yaw, maison.name)
	maison.position = Vector3(centre.x, sol, centre.y)
	maison.rotation.y = deg_to_rad(yaw)

	# Plinthe : une ceinture d'assises loftées. Le dénivelé mesuré sous les
	# bâtis ne dépasse pas 0,30 m, donc une assise de 0,45 m suffit et le
	# couronnement reste de niveau.
	_plinthe(maison, span_x, span_z)
	# Sol porteur CONTINU sous le plancher : sans lui l'herbe gelée
	# traverse les lames de 2 cm des modules `Floor_*`.
	_sol_plein(maison, Vector3(0.0, -0.20, 0.0),
		Vector3(span_x + 0.10, 0.64, span_z + 0.10),
		Color(0.34, 0.29, 0.24), 7100 + tx * 7 + tz)

	var mur_plein: StringName = &"Wall_Plaster_Straight" if style == "plaster" \
		else &"Wall_UnevenBrick_Straight"
	var mur_fenetre: StringName = &"Wall_Plaster_Window_Wide_Round" \
		if style == "plaster" else &"Wall_UnevenBrick_Window_Wide_Round"
	var mur_porte: StringName = &"Wall_Plaster_Door_Round" if style == "plaster" \
		else &"Wall_UnevenBrick_Door_Round"
	var plancher: StringName = &"Floor_WoodLight" if style == "plaster" \
		else &"Floor_Brick"

	var demi_x: float = span_x * 0.5
	var demi_z: float = span_z * 0.5
	for niveau: int in range(niveaux):
		var base: float = float(niveau) * WALL_H
		for ix: int in range(tx):
			for iz: int in range(tz):
				_module(maison, plancher, Vector3(
					(float(ix) - float(tx - 1) * 0.5) * MODULE, base + 0.10,
					(float(iz) - float(tz - 1) * 0.5) * MODULE), 0.0)
		for i: int in range(tx):
			var x: float = (float(i) - float(tx - 1) * 0.5) * MODULE
			var porte_ici: bool = niveau == 0 and i == tx / 2
			_mur(maison, Vector3(x, base, -demi_z), 180.0,
				mur_porte if porte_ici else
				(mur_fenetre if niveau == 1 else mur_plein))
			_mur(maison, Vector3(x, base, demi_z), 0.0,
				mur_fenetre if i != tx / 2 or niveau == 1 else mur_plein)
		# Longues faces : une baie sur DEUX, en quinconce d'une face à
		# l'autre. Le premier jet n'en posait qu'une au milieu, et le gros
		# plan structurel n'a montré qu'un panneau d'enduit nu de 6 m — une
		# façade sans percement se lit comme une boîte, quelle que soit la
		# matière.
		for j2: int in range(tz):
			var z: float = (float(j2) - float(tz - 1) * 0.5) * MODULE
			_mur(maison, Vector3(-demi_x, base, z), 90.0,
				mur_fenetre if j2 % 2 == 1 else mur_plein)
			_mur(maison, Vector3(demi_x, base, z), 270.0,
				mur_fenetre if j2 % 2 == 0 else mur_plein)
		for coin: Vector3 in [Vector3(-demi_x, base, -demi_z),
				Vector3(demi_x, base, -demi_z), Vector3(-demi_x, base, demi_z),
				Vector3(demi_x, base, demi_z)]:
			_module(maison, &"Corner_Exterior_Wood", coin, 0.0)

	var faite: float = float(niveaux) * WALL_H
	_module(maison, spec["toit"] as StringName, Vector3(0.0, faite, 0.0), 0.0)
	for cote: int in [-1, 1]:
		_module(maison, spec["pignon"] as StringName,
			Vector3(0.0, faite, demi_z * float(cote)),
			0.0 if cote > 0 else 180.0)
	# Profondeur de façade : un auvent sur la porte, une cheminée. Une
	# façade plate se lit comme une boîte, quelle que soit la texture.
	# L'auvent est ASSORTI au style : mélanger enduit et brique sur la même
	# façade se voit immédiatement.
	_module(maison, &"Overhang_Plaster_Long" if style == "plaster"
		else &"Overhang_UnevenBrick_Long",
		Vector3(0.0, 0.0, -demi_z - 1.05), 180.0)
	var chem: Vector2 = spec["cheminee"] as Vector2
	_module(maison, &"Prop_Chimney", Vector3(chem.x, faite + 0.55, chem.y), 0.0)
	# Balcon d'étage : sur la silhouette 0°, vue dans l'axe de la rue, le
	# volume à deux niveaux se lisait comme un bloc plein. Une saillie de
	# 1,23 m casse le contour et donne une ligne d'ombre horizontale.
	# `Balcony_Simple_Straight` a son pivot en min-Y : posé à `WALL_H`, il
	# s'assied exactement au plancher de l'étage.
	if bool(spec.get("balcon", false)) and niveaux >= 2:
		for cote2: float in [-1.0, 1.0]:
			_module(maison, &"Balcony_Simple_Straight",
				Vector3(cote2 * MODULE, WALL_H, -demi_z - 0.04), 180.0)
	# Pas de `DoorFrame_Round_WoodDark` rapporté : `Wall_*_Door_Round` porte
	# déjà son huisserie, et le cadre ajouté venait mordre le jour de
	# 1,30 m — la caméra intérieure butait dessus à 0,21 m.
	# Les modules à assise fautive (`Window_Wide_Round1` −1,016,
	# `WindowShutters_Wide_Round_Open` −1,093, `Prop_Support` −1,211) sont
	# bannis de ce fichier : `K.module()` les plaquerait au sol, ce qui est
	# très exactement le défaut « fenêtre posée au sol ».

	_collider(maison, maison.name + "_sol", Vector3(0.0, -0.15, 0.0),
		Vector3(span_x + 0.2, 0.5, span_z + 0.2))
	_noter_toit(centre, spec["toit_emprise"] as Vector2, yaw, maison.name)
	# L'empreinte notée est PLUS LARGE que le bâti : les colliders de mur
	# débordent de 0,21 m (demi-épaisseur mesurée du module) et la plinthe
	# de 0,30 m. Un filet qui sous-estime l'emprise ne protège de rien.
	_noter_col(centre, Vector2(span_x + 0.9, span_z + 0.9), yaw, maison.name)
	return maison


## Intérieur crédible de l'auberge — quatre îlots FONCTIONNELS, pas un
## semis de meubles. Murs de 0,41 m mesurés : chaque baie donne un vrai
## ébrasement, et la caméra entre par un jour libre de 1,30 m.
func _interieur_auberge(maison: Node3D) -> void:
	# Foyer et cuisine, angle nord-ouest (sous la cheminée).
	_ame_de_foyer(maison, Vector3(-1.85, 0.12, -2.45))
	_module(maison, &"Cauldron", Vector3(-1.85, 0.30, -2.05), 0.0)
	_module(maison, &"Bucket_Wooden_1", Vector3(-1.05, 0.12, -2.60), 20.0)
	_pose(maison, &"Pot_1", Vector3(-2.35, 0.62, -2.75), -15.0)
	_pose(maison, &"Shelf_Simple", Vector3(-2.30, 1.55, -3.40), 0.0)
	_pose(maison, &"Shelf_Arch", Vector3(-0.60, 1.35, -3.42), 0.0)

	# Salle commune, au centre : la grande table face à la porte.
	_module(maison, &"Table_Large", Vector3(0.35, 0.12, -0.20), 8.0)
	_module(maison, &"Bench", Vector3(0.35, 0.12, 0.62), 8.0)
	_module(maison, &"Bench", Vector3(0.35, 0.12, -1.02), 8.0)
	_module(maison, &"Stool", Vector3(1.95, 0.12, -0.40), 0.0)
	_module(maison, &"Stool", Vector3(-1.20, 0.12, 0.55), 0.0)
	_module(maison, &"Chair_1", Vector3(1.90, 0.12, 0.70), -110.0)
	_pose(maison, &"Mug", Vector3(0.05, 0.93, -0.05), 0.0)
	_pose(maison, &"Mug", Vector3(0.75, 0.93, -0.45), 40.0)
	_pose(maison, &"Bottle_1", Vector3(0.42, 0.93, 0.10), 0.0)
	_pose(maison, &"CandleStick", Vector3(-0.35, 0.93, -0.30), 25.0)
	_pose(maison, &"Book_Stack_1", Vector3(1.05, 0.93, 0.05), -18.0)

	# Comptoir et cellier, mur est.
	_module(maison, &"Barrel_Holder", Vector3(2.20, 0.12, 2.05), -90.0)
	_module(maison, &"Barrel", Vector3(2.25, 0.12, 3.05), 0.0)
	_module(maison, &"Crate_Wooden", Vector3(1.55, 0.12, 3.25), 22.0)
	_module(maison, &"FarmCrate_Apple", Vector3(0.55, 0.12, 3.30), -12.0)
	_module(maison, &"Chest_Wood", Vector3(-2.05, 0.12, 2.95), 12.0)

	# Montée à l'étage : `Stair_Interior_Simple` mesure 1,68 × 3,03 × 4,62,
	# pivot centre / min / MAX. Son corps s'étend donc de pivot − 4,62 à
	# pivot en Z. Posée à z = 0,90 avec yaw 180, elle courait de 0,90 à
	# 5,48 et traversait le mur nord de 1,89 m (relevé d'AABB). À yaw 0 et
	# z = 3,40 elle occupe −1,22 à 3,40, entièrement dans les 3,59 m utiles.
	_module(maison, &"Stair_Interior_Simple", Vector3(-1.85, 0.12, 3.40), 0.0)

	# Étage : dortoir, visible depuis la cage d'escalier.
	_module(maison, &"Bed_Twin1", Vector3(-1.55, WALL_H + 0.12, -2.20), 90.0)
	_module(maison, &"Bed_Twin1", Vector3(1.55, WALL_H + 0.12, -2.20), -90.0)
	_module(maison, &"Chest_Wood", Vector3(2.05, WALL_H + 0.12, 0.10), -90.0)
	_pose(maison, &"Lantern_Wall", Vector3(-2.45, WALL_H + 1.95, 0.40), 90.0)
	# Lumière de l'âtre : chaude, courte, motivée par le foyer.
	var feu: OmniLight3D = OmniLight3D.new()
	feu.name = "LumiereAtre"
	feu.position = Vector3(-1.85, 0.75, -2.35)
	feu.light_color = Color(1.0, 0.72, 0.44)
	# 1,2 et non 2,4 : à 2,4 la jouée de l'âtre rendait au-dessus de 0,85
	# et se lisait comme une plaque blanche (mesuré sur `vue04`).
	feu.light_energy = 1.2
	feu.omni_range = 4.5
	feu.shadow_enabled = false
	maison.add_child(feu)


# ===========================================================================
# PLACE, PARAPET, VOIRIE
# ===========================================================================

## La place : un pavage CONTINU, le puits, l'étal, la bannière.
##
## Le puits a changé de teinte, pas de nature. Ses margelles étaient huit
## `stone_block` en `TONE_STONE` × shade jusqu'à 1,08 — l'origine mesurée
## des « éléments blancs ». Elles restent des blocs taillés (c'est un puits
## de village), mais leur teinte est bornée à 0,44 pour que le shade de
## 1,08 culmine à 0,48, très en dessous du plafond de 0,80.
func _place_commune() -> void:
	var place: Node3D = Node3D.new()
	place.name = "Place"
	add_child(place)

	# Pavage joint : les dalles mesurent 2,05 × 1,99 et sont posées au pas
	# de 1,95 — elles se RECOUVRENT, donc l'herbe ne passe pas entre elles.
	for ix: int in range(5):
		for iz: int in range(4):
			var x: float = -2.9 + float(ix) * 1.75
			var z: float = 3.3 + float(iz) * 1.75
			_module(place, &"RockPath_Square_Wide", _au_sol(x, z),
				float((ix * 3 + iz) % 4) * 90.0)
	for bord: Array in [[-4.4, 4.2], [-4.2, 7.4], [5.6, 4.0], [5.4, 7.8],
			[0.6, 10.4], [-2.6, 10.2]]:
		_module(place, &"RockPath_Round_Wide",
			_au_sol(float(bord[0]), float(bord[1])),
			float(bord[0]) * 37.0)

	# Le puits — hors de tout rayon du gué : le rayon 90° s'arrête à
	# (0 ; +4), la margelle vit entre x 1,8 et 3,8, soit 1,8 m de marge.
	var puits: Vector3 = _au_sol(2.8, 5.2)
	for i: int in range(8):
		var angle: float = TAU * float(i) / 8.0
		K.stone_block(place, "Margelle_%d" % i,
			puits + Vector3(cos(angle) * 0.95, 0.34, sin(angle) * 0.95),
			Vector3(0.62, 0.70, 0.42), rad_to_deg(-angle),
			Color(0.44, 0.41, 0.37), 6600 + i, 0.06)
	_poteau(place, "PuitsMontant", puits + Vector3(0.0, 0.0, -0.88), 2.35, 0.09)
	_poteau(place, "PuitsMontant2", puits + Vector3(0.0, 0.0, 0.88), 2.35, 0.09)
	_poutre(place, "PuitsTraverse", puits + Vector3(0.0, 2.42, 0.0),
		Vector3(0.14, 0.14, 2.10), Color(0.30, 0.24, 0.18), 6621)
	_pose(place, &"Bucket_Metal", puits + Vector3(0.0, 1.60, 0.0), 0.0)
	_collider(place, "Puits_col", puits + Vector3(0.0, 0.5, 0.0),
		Vector3(2.0, 1.0, 2.0))
	declare_support(puits)
	_noter_col(Vector2(puits.x, puits.z), Vector2(2.0, 2.0), 0.0, "Puits")

	# L'étal et le banc : la place sert à quelque chose.
	_module(place, &"Stall_Cart_Empty", _au_sol(-3.2, 8.6), 152.0)
	_module(place, &"FarmCrate_Apple", _au_sol(-1.9, 8.4), 25.0)
	_module(place, &"Barrel_Apples", _au_sol(-4.1, 7.2), 0.0)
	_module(place, &"Bench", _au_sol(4.6, 6.2), 104.0)
	_module(place, &"Banner_1", _au_sol(5.2, 9.2), 62.0)
	_module(place, &"Prop_Wagon", _au_sol(6.6, 1.6), 78.0)


## Parapet du bord de terrasse : UN rang d'assise plus son couronnement.
##
## Le plan annonçait un mur de soutènement de 1,35 m ; le terrain a dit
## non. La sonde donne 2,67–3,00 à z = +2 et 1,69–1,93 à z = 0 : c'est une
## cuvette douce, pas un ressaut. Un mur de 1,35 m y flotterait ou
## s'enterrerait. Le parapet fait donc ce que le relief autorise — il
## dessine le bord de la place et donne une ligne de premier plan.
##
## Il s'arrête à 1,6 m de part et d'autre de x = 0 : la trouée est imposée
## par le rayon 90° du gué, qui monte jusqu'à (0 ; +4).
func _parapet() -> void:
	var parapet: Node3D = Node3D.new()
	parapet.name = "Parapet"
	add_child(parapet)
	var runs: Array[Vector2] = [
		Vector2(-11.0, 1.9), Vector2(-7.0, 1.8), Vector2(-5.6, 1.75),
		Vector2(4.0, 1.6), Vector2(8.0, 1.5),
	]
	for i: int in range(runs.size()):
		var depart: Vector2 = runs[i]
		# ASSISE SUR LE POINT LE PLUS BAS DU TRONÇON, moins 0,35 m. Le
		# premier jet n'échantillonnait que deux points et posait la base
		# à ce minimum : partout où le sol redescendait sous le tronçon, le
		# mur décollait et se lisait comme un rail flottant (`vue02`). Cinq
		# points et un enfouissement franc suppriment le cas.
		var sol: float = 1e9
		for e: int in range(5):
			sol = minf(sol, ground_local_y(
				depart.x + ASSISE_L * float(e) / 4.0, depart.y))
		sol -= 0.35
		var yaw: float = sin(float(i) * 1.7) * 2.5
		# DEUX assises : à 0,61 m de haut le parapet se lisait comme une
		# planche ; à 1,06 m il se lit comme un mur bas.
		_assise_mur(parapet, "Parapet_%d_bas" % i,
			Vector3(depart.x, sol, depart.y), yaw, false)
		_assise_mur(parapet, "Parapet_%d_haut" % i,
			Vector3(depart.x, sol + ASSISE_H, depart.y), yaw, true)
		declare_support(Vector3(depart.x + ASSISE_L * 0.5, sol + 0.35,
			depart.y))
		_collider(parapet, "Parapet_col_%d" % i,
			Vector3(depart.x + ASSISE_L * 0.5, sol + 0.53, depart.y),
			Vector3(ASSISE_L, 1.06, 0.94), yaw)
		_noter_col(Vector2(depart.x + ASSISE_L * 0.5, depart.y),
			Vector2(ASSISE_L, 0.94), yaw, "Parapet_%d" % i)


## Voirie : la rampe pavée du gué à la place, et la venelle qui descend
## vers le quai. Aucun collider — les dalles font 0,11 à 0,18 m
## d'épaisseur et le terrain gelé porte déjà le joueur. C'est ce qui
## permet à la rue de traverser les rayons du gué sans les toucher.
func _voirie() -> void:
	var rue: Node3D = Node3D.new()
	rue.name = "Voirie"
	add_child(rue)
	# Rampe du gué : deux files de dalles, resserrées près de l'eau.
	for i: int in range(9):
		var t: float = float(i) / 8.0
		var z: float = lerpf(-7.4, 2.6, t)
		var ecart: float = lerpf(0.95, 1.35, t)
		for cote: float in [-1.0, 1.0]:
			_module(rue, &"RockPath_Round_Wide",
				_au_sol(cote * ecart, z), float(i) * 47.0 + cote * 20.0)
	# Venelle est : de la place vers la halle puis le quai.
	for pas: Array in [[6.2, 3.2], [8.0, 2.4], [9.8, 1.4], [11.4, 0.2],
			[12.6, -1.2], [13.6, -2.6], [14.4, -3.6]]:
		_module(rue, &"RockPath_Round_Thin",
			_au_sol(float(pas[0]), float(pas[1])), float(pas[1]) * 61.0)
	# Venelle ouest, au pied de la falaise : un cul-de-sac assumé qui donne
	# de la profondeur derrière l'auberge.
	for pas2: Array in [[-11.6, 5.0], [-12.2, 7.2], [-12.6, 9.4]]:
		_module(rue, &"RockPath_Round_Thin",
			_au_sol(float(pas2[0]), float(pas2[1])), float(pas2[1]) * 43.0)
	_module(rue, &"Prop_WoodenFence_Single", _au_sol(-10.6, 3.2), 22.0)
	_module(rue, &"Prop_WoodenFence_Single", _au_sol(-12.0, 11.0), 78.0)
	_module(rue, &"Crate_Wooden", _au_sol(-12.4, 10.2), 34.0)


# ===========================================================================
# LE QUAI
# ===========================================================================

## Quai lofté (`SM_Village_Quay.glb`) posé au point le plus bas du lit.
##
## COTES MESURÉES, jamais devinées : surface de l'eau 0,695 (x local 13,5)
## à 0,635 (19,5) ; lit 0,24 à 0,05 ; berge nord 0,55 (ouest) à 1,05 (est).
## Le platelage est à monde 1,15, soit un franc-bord de 0,455 à 0,515 m, et
## les pilotis plongent de 0,91 à 1,10 m jusqu'au lit. Au nord-est la berge
## affleure le platelage : le quai SORT du talus d'un côté et repose sur
## pilotis de l'autre.
##
## Un seul collider, limité au platelage : la passerelle n'en reçoit pas.
## Elle fait 0,10 m d'épaisseur au-dessus d'un sol déjà praticable, et lui
## en donner un la ferait entrer dans le couloir de la route (marge 0,14 m
## calculée, contre 1,34 m pour le platelage seul).
func _quai() -> void:
	var quai: Node3D = Node3D.new()
	quai.name = "Quai"
	add_child(quai)
	var corps: Node3D = QUAI_SCENE.instantiate() as Node3D
	corps.name = "SM_Village_Quay"
	quai.add_child(corps)
	corps.position = Vector3(QUAI_ORIGINE.x,
		QUAI_ORIGINE.y - RACINE_MONDE_Y, QUAI_ORIGINE.z)
	_teinter_glb(corps)

	var pont: float = QUAI_PONT_MONDE - RACINE_MONDE_Y
	_collider(quai, "Quai_col", Vector3(16.5, pont - 0.15, -7.5),
		Vector3(6.0, 0.30, 5.0))
	_noter_col(Vector2(16.5, -7.5), Vector2(6.0, 5.0), 0.0, "Quai")
	for pilotis: Array in [[14.1, -9.5], [16.5, -9.5], [18.9, -9.5],
			[14.1, -5.45], [16.5, -5.45], [18.9, -5.45]]:
		declare_support(_au_sol(float(pilotis[0]), float(pilotis[1])))

	# B4 — SÉCHOIR DU QUAI. Le quatrième volume, et le plus bas : 1,4 m
	# au-dessus du datum de la terrasse. Il est posé SUR le platelage, donc
	# il n'ajoute aucune emprise au sol et ne peut fouler ni la route ni un
	# rayon de gué.
	var sechoir: Node3D = Node3D.new()
	sechoir.name = "Sechoir"
	quai.add_child(sechoir)
	sechoir.position = Vector3(18.2, pont, -7.9)
	sechoir.rotation.y = deg_to_rad(8.0)
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.3, 1.3]:
			_poteau(sechoir, "PoteauSechoir_%d_%d" % [int(x * 10.0),
				int(z * 10.0)], Vector3(x, 0.0, z), 2.05, 0.09)
	# TOIT DU SÉCHOIR — panneaux plats, et surtout AUCUNE mise à l'échelle
	# après coup. Le premier jet posait `Roof_Wooden_2x1` puis écrasait
	# `panneau.scale` : cela annulait le facteur de `KitScale` ET déplaçait
	# le min-Y que `seat()` venait de caler. Résultat vu sur `vue07` : deux
	# pans de toit suspendus en l'air, détachés des poteaux — la « pièce
	# flottante » explicitement interdite.
	for j: int in range(2):
		var panneau: Node3D = _module(sechoir, &"Overhang_Roof_UnevenBricks",
			Vector3(0.0, 2.05, -0.35 + float(j) * 0.70), 0.0)
		if panneau != null:
			panneau.rotation.x = deg_to_rad(-7.0 + 14.0 * float(j))
	_poutre(sechoir, "SechoirFaitiere", Vector3(0.0, 2.10, 0.0),
		Vector3(2.4, 0.12, 0.14), Color(0.28, 0.22, 0.17), 7300)
	_module(sechoir, &"Crate_Metal", Vector3(-0.6, 0.02, 0.9), 18.0)
	_pose(sechoir, &"Rope_1", Vector3(0.7, 0.03, -0.9), 30.0)

	# La vie du quai, sur le platelage et la berge.
	_module(quai, &"Barrel", Vector3(14.4, pont + 0.02, -6.2), 0.0)
	_module(quai, &"Barrel", Vector3(15.1, pont + 0.02, -6.5), 0.0)
	_pose(quai, &"Chain_Coil", Vector3(16.9, pont + 0.03, -9.3), 12.0)
	_pose(quai, &"Bucket_Wooden_1", Vector3(15.6, pont + 0.03, -9.6), -25.0)
	_module(quai, &"FarmCrate_Empty", _au_sol(14.9, -3.7), 40.0)
	_module(quai, &"Prop_WoodenFence_Single", _au_sol(20.4, -4.6), 100.0)


# ===========================================================================
# OUTILLAGE LOCAL
# ===========================================================================

## Pose un module de kit SANS la teinte globale, puis teinte par matériau.
func _module(parent: Node3D, nom: StringName, at: Vector3,
		yaw: float = 0.0, echelle: float = 1.0) -> Node3D:
	var node: Node3D = K.module(parent, nom, at, yaw, echelle, Color.WHITE)
	if node != null:
		_teinter(node)
	return node


## Pose un module À UNE HAUTEUR DONNÉE, en contournant `seat()`.
##
## `K.module()` appelle `KitPlacement.seat()`, qui ramène le min-Y du
## module à 0 dans le repère du PARENT. Un objet dont l'origine n'est pas
## à sa base — `Window_Wide_Round1` (−1,016), `Prop_Support` (−1,211),
## `Lantern_Wall` (+0,082) — se retrouve donc plaqué au sol. En
## interposant un `Node3D` porté à la bonne hauteur, `seat()` ramène le
## min-Y à CETTE hauteur, ce qui est exactement le comportement voulu.
## Aucune modification du kit n'est nécessaire.
func _pose(parent: Node3D, nom: StringName, at: Vector3,
		yaw: float = 0.0, echelle: float = 1.0) -> Node3D:
	var support: Node3D = Node3D.new()
	support.name = "socle_%s_%d" % [nom, parent.get_child_count()]
	support.position = at
	parent.add_child(support)
	return _module(support, nom, Vector3.ZERO, yaw, echelle)


## Teinte PAR NOM DE MATÉRIAU SOURCE, avec plafond dur d'albédo.
func _teinter(racine: Node3D) -> void:
	var cibles: Array[Node] = racine.find_children("*", "MeshInstance3D",
		true, false)
	if racine is MeshInstance3D:
		cibles.append(racine)
	for node: Node in cibles:
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var actif: Material = instance.get_active_material(surface)
			var base: StandardMaterial3D = actif as StandardMaterial3D
			if base == null:
				continue
			var nom: String = base.resource_name
			var teinte: Color = TEINTES.get(nom, TEINTE_DEFAUT) as Color
			var cle: String = "%d|%s" % [base.get_instance_id(), teinte]
			var teinte_mat: StandardMaterial3D = \
				_cache_teintes.get(cle) as StandardMaterial3D
			if teinte_mat == null:
				teinte_mat = base.duplicate() as StandardMaterial3D
				var a: Color = base.albedo_color
				teinte_mat.albedo_color = Color(
					minf(a.r * teinte.r, ALBEDO_MAX),
					minf(a.g * teinte.g, ALBEDO_MAX),
					minf(a.b * teinte.b, ALBEDO_MAX), a.a)
				teinte_mat.roughness = maxf(teinte_mat.roughness, 0.95)
				teinte_mat.metallic_specular = 0.1
				_cache_teintes[cle] = teinte_mat
			instance.set_surface_override_material(surface, teinte_mat)


## Les GLB du hameau portent déjà leur valeur, calibrée dans le générateur
## Blender (sRGB converti en linéaire). On borne seulement la rugosité, le
## spéculaire et l'albédo pour rester dans le langage painterly du monde.
func _teinter_glb(racine: Node3D) -> void:
	for node: Node in racine.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = node as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var base: StandardMaterial3D = instance.get_active_material(
				surface) as StandardMaterial3D
			if base == null:
				continue
			var cle: String = "glb|%d" % base.get_instance_id()
			var mat: StandardMaterial3D = \
				_cache_teintes.get(cle) as StandardMaterial3D
			if mat == null:
				mat = base.duplicate() as StandardMaterial3D
				mat.roughness = maxf(mat.roughness, 0.95)
				mat.metallic_specular = 0.1
				var a: Color = mat.albedo_color
				mat.albedo_color = Color(minf(a.r, ALBEDO_MAX),
					minf(a.g, ALBEDO_MAX), minf(a.b, ALBEDO_MAX), a.a)
				_cache_teintes[cle] = mat
			instance.set_surface_override_material(surface, mat)


## Une assise de mur loftée, éventuellement couronnée.
func _assise_mur(parent: Node3D, nom: String, at: Vector3, yaw: float,
		couronnee: bool) -> void:
	var piece: Node3D = MUR_SCENE.instantiate() as Node3D
	piece.name = nom
	parent.add_child(piece)
	piece.position = at
	piece.rotation.y = deg_to_rad(yaw)
	for enfant: Node in piece.get_children():
		var est_couronnement: bool = String(enfant.name).contains("Coping")
		if est_couronnement and not couronnee:
			enfant.queue_free()
		elif est_couronnement:
			(enfant as Node3D).position.y = ASSISE_H
	_teinter_glb(piece)


## Plinthe de bâtiment : une ceinture d'assises loftées sur le pourtour.
func _plinthe(maison: Node3D, span_x: float, span_z: float) -> void:
	var socle: Node3D = Node3D.new()
	socle.name = "Plinthe"
	maison.add_child(socle)
	var demi_x: float = span_x * 0.5
	var demi_z: float = span_z * 0.5
	# SENS DE PARCOURS — mesuré, pas déduit. Le premier jet donnait −90° au
	# retour ouest et +90° au retour est : les deux assises partaient DANS
	# LE MAUVAIS SENS et couraient 8,6 m hors du bâti (relevé d'AABB :
	# x −3,70..−2,90 pour z 4,30..12,90, contre z ±4,30 attendu). Une
	# rotation dont on n'a pas vérifié le signe est un bug silencieux : la
	# pièce existe, elle est simplement ailleurs.
	var runs: Array[Array] = [
		[Vector3(-demi_x - 0.30, 0.0, -demi_z - 0.30), 0.0, span_x + 0.6],
		[Vector3(demi_x + 0.30, 0.0, demi_z + 0.30), 180.0, span_x + 0.6],
		[Vector3(-demi_x - 0.30, 0.0, demi_z + 0.30), 90.0, span_z + 0.6],
		[Vector3(demi_x + 0.30, 0.0, -demi_z - 0.30), -90.0, span_z + 0.6],
	]
	for i: int in range(runs.size()):
		var depart: Vector3 = runs[i][0] as Vector3
		var yaw: float = float(runs[i][1])
		var longueur: float = float(runs[i][2])
		var piece: Node3D = MUR_SCENE.instantiate() as Node3D
		piece.name = "PlintheAssise_%d" % i
		socle.add_child(piece)
		piece.position = depart + Vector3(0.0, -ASSISE_H + 0.10, 0.0)
		piece.rotation.y = deg_to_rad(yaw)
		# L'assise fait 4,00 m ; on l'ajuste EN LONGUEUR seulement — les
		# joints s'étirent ou se resserrent, jamais les hauteurs d'assise.
		piece.scale = Vector3(longueur / ASSISE_L, 1.0, 1.0)
		for enfant: Node in piece.get_children():
			if String(enfant.name).contains("Coping"):
				enfant.queue_free()
		_teinter_glb(piece)


## Sol plein continu : une plaque taillée, jamais des lames de 2 cm.
func _sol_plein(parent: Node3D, at: Vector3, taille: Vector3, tonalite: Color,
		graine: int) -> void:
	K.stone_block(parent, "SolPlein_%d" % graine, at, taille, 0.0, tonalite,
		graine, 0.02)


func _poteau(parent: Node3D, nom: String, pied: Vector3, hauteur: float,
		demi: float) -> void:
	K.stone_block(parent, nom, pied + Vector3(0.0, hauteur * 0.5, 0.0),
		Vector3(demi * 2.0, hauteur, demi * 2.0), 0.0,
		Color(0.30, 0.24, 0.18), 7400 + parent.get_child_count(), 0.03)


func _poutre(parent: Node3D, nom: String, at: Vector3, taille: Vector3,
		tonalite: Color, graine: int) -> void:
	K.stone_block(parent, nom, at, taille, 0.0, tonalite, graine, 0.02)


## Âme de foyer : dalle, jouées et linteau sous la cheminée.
func _ame_de_foyer(parent: Node3D, at: Vector3) -> void:
	K.stone_block(parent, "Atre_dalle", at + Vector3(0.0, 0.02, 0.0),
		Vector3(1.5, 0.14, 1.1), 0.0, Color(0.36, 0.33, 0.30), 7500, 0.05)
	for cote: float in [-1.0, 1.0]:
		K.stone_block(parent, "Atre_jouee_%d" % int(cote),
			at + Vector3(cote * 0.68, 0.42, 0.0),
			Vector3(0.20, 0.72, 1.0), 0.0, Color(0.33, 0.30, 0.27),
			7502 + int(cote), 0.06)
	K.stone_block(parent, "Atre_linteau", at + Vector3(0.0, 0.86, 0.0),
		Vector3(1.5, 0.20, 1.0), 0.0, Color(0.38, 0.35, 0.31), 7503, 0.04)


func _mur(parent: Node3D, at: Vector3, yaw: float, kind: StringName) -> void:
	_module(parent, kind, at, yaw)
	var le_long: Vector3 = Vector3(cos(deg_to_rad(yaw)), 0.0,
		-sin(deg_to_rad(yaw)))
	var epaisseur: Vector3 = Vector3(absf(le_long.z), 0.0, absf(le_long.x)) * 0.42
	var portee: Vector3 = le_long.abs() * MODULE
	if String(kind).contains("Door"):
		var jambage: float = (MODULE - DOOR_GAP) * 0.5
		for cote: float in [-1.0, 1.0]:
			var centre: Vector3 = at + le_long * cote * (DOOR_GAP + jambage) * 0.5 \
				+ Vector3(0.0, WALL_H * 0.5, 0.0)
			_collider(parent, "jambage_%d" % parent.get_child_count(), centre,
				Vector3(maxf(le_long.abs().x * jambage, 0.42), WALL_H,
					maxf(le_long.abs().z * jambage, 0.42)))
		_collider(parent, "linteau_%d" % parent.get_child_count(),
			at + Vector3(0.0, WALL_H - 0.40, 0.0),
			Vector3(maxf(portee.x, 0.42), 0.80, maxf(portee.z, 0.42)))
		return
	_collider(parent, String(kind) + "_col_%d" % parent.get_child_count(),
		at + Vector3(0.0, WALL_H * 0.5, 0.0),
		Vector3(maxf(portee.x, epaisseur.x), WALL_H,
			maxf(portee.z, epaisseur.z)))


func _collider(parent: Node3D, nom: String, at: Vector3, taille: Vector3,
		yaw: float = 0.0) -> void:
	K.collider_box(parent, nom, at, taille, yaw)


## Assiette d'un bâti : le point HAUT de son emprise, tous les coins étant
## déclarés comme appuis. Le terrain gelé n'est jamais remodelé.
func _assiette(centre: Vector2, taille: Vector2, yaw: float,
		nom: String) -> float:
	var haut: float = -1e9
	var demi: Vector2 = taille * 0.5
	for coin: Vector2 in [Vector2(-demi.x, -demi.y), Vector2(demi.x, -demi.y),
			Vector2(-demi.x, demi.y), Vector2(demi.x, demi.y)]:
		var tourne: Vector2 = coin.rotated(deg_to_rad(-yaw))
		var p: Vector2 = centre + tourne
		var sol: float = ground_local_y(p.x, p.y)
		haut = maxf(haut, sol)
		declare_support(Vector3(p.x, sol, p.y))
	# +0,20 et non +0,06. Mesuré sur `vue04` : des brins d'herbe GELÉE
	# traversaient le plancher de l'auberge. La végétation V2.2 est posée
	# sur le terrain et monte jusqu'à ~0,5 m ; un plancher à 0,16 m
	# au-dessus du coin le plus HAUT laisse donc passer l'herbe des coins
	# bas. La plinthe (0,45 m d'assise posée à −0,35) couvre le retrait.
	return haut + 0.20


func _au_sol(x: float, z: float) -> Vector3:
	return Vector3(x, ground_local_y(x, z), z)


func _noter_toit(centre: Vector2, taille: Vector2, yaw: float,
		nom: String) -> void:
	_empreintes_toit.append({"c": centre, "d": taille * 0.5, "yaw": yaw,
		"nom": nom})


func _noter_col(centre: Vector2, taille: Vector2, yaw: float,
		nom: String) -> void:
	_empreintes_col.append({"c": centre, "d": taille * 0.5, "yaw": yaw,
		"nom": nom})


func _poi_area() -> void:
	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Village de la rivière"
	poi.region = "r03_val_de_neris"
	var forme: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 18.0
	forme.shape = sphere
	poi.add_child(forme)
	add_child(poi)


# ===========================================================================
# LE FILET D'IMPLANTATION — l'invariant devient exécutable
# ===========================================================================

## Vérifie à la CONSTRUCTION ce qu'aucune capture ne montre :
##  a. deux toitures ne se recouvrent pas (SAT sur les OBB) ;
##  b. aucun collider n'approche à moins de 1,2 m de la route contractuelle ;
##  c. aucun collider ne contient un point d'échantillonnage des huit
##     rayons du gué (ISS-032) ;
##  d. tout appui déclaré touche le sol gelé à 0,65 m près.
##
## Ces marges se calculent en secondes et se perdent à la première
## retouche. La passe précédente a laissé 0,60 m d'interpénétration de
## toiture sans que personne ne le voie sur une image.
func _verifier_implantation() -> void:
	var fautes: Array[String] = []

	for i: int in range(_empreintes_toit.size()):
		for j: int in range(i + 1, _empreintes_toit.size()):
			var chevauchement: float = _obb_chevauchement(
				_empreintes_toit[i], _empreintes_toit[j])
			if chevauchement > 0.0:
				fautes.append("toitures %s et %s se recouvrent de %.2f m"
					% [_empreintes_toit[i]["nom"], _empreintes_toit[j]["nom"],
						chevauchement])

	for k: int in range(ROUTE_LOCALE.size() - 1):
		var a: Vector2 = ROUTE_LOCALE[k]
		var b: Vector2 = ROUTE_LOCALE[k + 1]
		var pas: int = maxi(1, int(a.distance_to(b)))
		for s: int in range(pas + 1):
			var p: Vector2 = a.lerp(b, float(s) / float(pas))
			for e: Dictionary in _empreintes_col:
				var boite: Rect2 = _aabb_de(e)
				if p.x > boite.position.x - ROUTE_DEGAGEMENT \
						and p.x < boite.end.x + ROUTE_DEGAGEMENT \
						and p.y > boite.position.y - ROUTE_DEGAGEMENT \
						and p.y < boite.end.y + ROUTE_DEGAGEMENT:
					fautes.append("%s empiète la route en (%.1f, %.1f)"
						% [e["nom"], p.x, p.y])
					break

	for huitieme: int in range(8):
		var azimut: float = TAU * float(huitieme) / 8.0
		var direction: Vector2 = Vector2(cos(azimut), sin(azimut))
		for metre: int in range(1, GUE_RAYON_M + 1):
			var p2: Vector2 = GUE_LOCAL + direction * float(metre)
			for e2: Dictionary in _empreintes_col:
				var boite2: Rect2 = _aabb_de(e2)
				if boite2.has_point(p2):
					fautes.append("%s sur le rayon %.0f° du gué à %d m"
						% [e2["nom"], rad_to_deg(azimut), metre])
					break

	var appuis: PackedVector3Array = _appuis()
	for point: Vector3 in appuis:
		var sol: float = ground_local_y(point.x, point.z)
		if absf(point.y - sol) > 0.65:
			fautes.append("appui (%.1f, %.1f) à %.2f m du sol"
				% [point.x, point.z, point.y - sol])

	# e. AUCUNE PIÈCE FLOTTANTE — l'interdit du briefing, rendu exécutable.
	#
	# Chercher une planche suspendue à l'œil sur une capture ne marche pas :
	# il en restait une après deux passes d'inspection. Le test est
	# géométrique — toute pièce dont le dessous est à plus de 0,45 m du sol
	# gelé doit trouver, sous elle et en recouvrement horizontal, une autre
	# pièce dont le dessus arrive à moins de 0,45 m. Sinon elle flotte.
	for flottant: String in _pieces_flottantes():
		fautes.append(flottant)

	if fautes.is_empty():
		print("[hameau] implantation vérifiée : %d toiture(s), %d collider(s), %d appui(s) — aucune faute."
			% [_empreintes_toit.size(), _empreintes_col.size(), appuis.size()])
		return
	for faute: String in fautes:
		push_error("[hameau] IMPLANTATION : %s" % faute)


## Les appuis ne sont publiés en méta qu'APRÈS `_build()` (c'est `_ready()`
## de la classe de base qui les pose) : pendant la vérification, la seule
## source est la liste que la base accumule. `get_meta` lève même avec une
## valeur par défaut lorsque la clé manque — mesuré ici, pas supposé.
func _appuis() -> PackedVector3Array:
	if has_meta(&"support_points"):
		return get_meta(&"support_points") as PackedVector3Array
	return get("_support_points") as PackedVector3Array


## Pièces sans appui : ni le sol gelé, ni une autre pièce sous elles.
##
## LA RÈGLE A DÛ ÊTRE CORRIGÉE, et c'est instructif. Le premier jet exigeait
## un appui DIRECTEMENT SOUS la pièce. Il a aussitôt accusé six pièces
## parfaitement légitimes : les planchers d'étage (portés par les murs du
## pourtour, qui ne sont pas dessous mais à côté), les deux balcons et les
## deux étagères murales (des encorbellements, par définition sans rien
## dessous). Un garde-fou à faux positifs finit désactivé — celui-ci
## demande donc seulement que la pièce TOUCHE quelque chose : le sol gelé,
## ou une autre pièce à moins de 0,45 m dans les trois axes. Une planche
## suspendue au-dessus de l'herbe, elle, ne touche rien.
func _pieces_flottantes() -> Array[String]:
	var boites: Array[AABB] = []
	var noms: Array[String] = []
	for node: Node in find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh == null or not mi.is_inside_tree():
			continue
		var xf: Transform3D = global_transform.affine_inverse() \
			* mi.global_transform
		boites.append(xf * mi.mesh.get_aabb())
		noms.append(mi.name)
	var fautes: Array[String] = []
	for i: int in range(boites.size()):
		var b: AABB = boites[i]
		var centre: Vector3 = b.get_center()
		if b.position.y - ground_local_y(centre.x, centre.z) <= 0.45:
			continue
		var voisine: AABB = b.grow(0.45)
		var porte: bool = false
		for j: int in range(boites.size()):
			if j != i and voisine.intersects(boites[j]):
				porte = true
				break
		if not porte:
			fautes.append("%s FLOTTE : dessous à %.2f m du sol, rien dessous"
				% [noms[i], b.position.y - ground_local_y(centre.x, centre.z)])
	return fautes


## Séparation de deux boîtes orientées par l'axe des séparations (SAT).
## Rend 0 si elles sont disjointes, sinon la plus petite pénétration.
func _obb_chevauchement(u: Dictionary, v: Dictionary) -> float:
	var delta: Vector2 = (v["c"] as Vector2) - (u["c"] as Vector2)
	var minimum: float = 1e9
	for source: Dictionary in [u, v]:
		for k: int in range(2):
			var angle: float = deg_to_rad(float(source["yaw"])) \
				+ (PI * 0.5 if k == 1 else 0.0)
			var axe: Vector2 = Vector2(cos(angle), -sin(angle))
			var ecart: float = absf(delta.dot(axe))
			var somme: float = _projection(u, axe) + _projection(v, axe)
			if ecart >= somme:
				return 0.0
			minimum = minf(minimum, somme - ecart)
	return minimum


func _projection(boite: Dictionary, axe: Vector2) -> float:
	var demi: Vector2 = boite["d"] as Vector2
	var angle: float = deg_to_rad(float(boite["yaw"]))
	var ex: Vector2 = Vector2(cos(angle), -sin(angle))
	var ez: Vector2 = Vector2(sin(angle), cos(angle))
	return demi.x * absf(ex.dot(axe)) + demi.y * absf(ez.dot(axe))


func _aabb_de(boite: Dictionary) -> Rect2:
	var demi: Vector2 = boite["d"] as Vector2
	var angle: float = deg_to_rad(float(boite["yaw"]))
	var demi_x: float = demi.x * absf(cos(angle)) + demi.y * absf(sin(angle))
	var demi_z: float = demi.x * absf(sin(angle)) + demi.y * absf(cos(angle))
	var centre: Vector2 = boite["c"] as Vector2
	return Rect2(centre - Vector2(demi_x, demi_z),
		Vector2(demi_x, demi_z) * 2.0)
