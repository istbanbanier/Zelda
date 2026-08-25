## LA SOURCE AUX REFLETS (`valley.poi.turquoise_spring.01`, r04) — une eau
## vive qui sort du pied de la falaise, à vingt-quatre mètres du guet et
## quatorze mètres sous lui.
##
## LES DEUX LIEUX SONT LES DEUX FACES DU MÊME MUR, et c'est le terrain gelé
## qui le dit, pas une intention. Profils mesurés (port Python de
## `world_v2_heightmap.gd`, `docs/V2_3_B_LOT1_VOIE_B_PLAN.md` §0) : à
## l'ouest de la source le sol monte de +0,98 m à 11 m, +8,73 m à 16 m,
## +13,72 m à 20 m, puis se stabilise à +14,0 m — soit exactement
## l'altitude du guet (26 − 12 = 14). La pente vaut 54°, et le shader de
## sol rend de la roche stratifiée au-delà de 55° : la paroi EST là, et
## elle est déjà minérale. Ce lieu n'a donc aucune falaise à construire.
##
## REWORK V2.3-B LOT 1.R (voie A). Le verdict Codex a rejeté la version
## précédente : « elle ne se lit ni comme turquoise ni comme une source
## cohérente » — nappe QUASI BLANCHE (le piège albédo/gain exact de
## `scripts/CLAUDE.md`), `SM_Dungeon_CaveArch` architecturale posée devant
## l'eau, épaules terracotta (captures :
## `evidence/world_v2/v2_3_b/lot1/poi/turquoise_spring_identite.png`).
## Trois décisions en découlent, aucune négociable :
##
##  1. L'EAU EST CELLE DE LA RIVIÈRE — même shader
##     (`shaders/world_v2/SH_WorldV2Water.gdshader`, lu sans être modifié),
##     même bruit (`WorldV2GroundMaterial.grain_texture()`), même
##     convention de sommets que `world_v2_hydrology_builder.gd` :
##     COLOR.r = profondeur 0-1 (pas de DEPTH_FULL_M 2,5 m ici : la vasque
##     encode directement son facteur), COLOR.gb = courant (0,5 = immobile),
##     COLOR.a = opacité. La continuité de teinte avec la rivière V2.2 est
##     donc DE CONSTRUCTION, pas de calibrage.
##  2. AUCUNE ARCHE, AUCUN PANNEAU : la famille `SM_Dungeon_*` est bannie
##     du lieu. L'eau sort d'une FENTE sombre entre deux mâchoires de
##     roche froide au pied de la pente (pieds enterrés, penchées l'une
##     vers l'autre), coiffées d'un troisième rocher qui ferme le haut du
##     creux — la bouche est un creux fermé, pas un intervalle.
##  3. LA VASQUE A UN FOND : un lit sombre qui épouse le terrain sous la
##     nappe — sans lui, une eau transparente posée sur l'herbe du pad se
##     lit comme une décalcomanie (c'est la nappe blanche rejetée).
##
## L'AFFLUENT NAÎT ICI. Premier point de `west_tributary_xz` : (−130 ; 34),
## soit 8,49 m au nord-est du site — et `_trib_bed_curve(0)` vaut 11,0,
## donc une surface d'eau à 11,6 m, quarante centimètres SOUS le pad de la
## source (12,0). Le déversoir n'a rien à inventer : il pointe vers un lit
## qui existe déjà et qui descend. Le fil qui s'en va est une LANGUE du
## maillage de nappe (même module, même shader) qui suit le sol vers les
## dalles, et s'éteint bien avant la tête de lit. Aucune pièce de ce lieu
## ne porte de collider à moins de 5 m de cette tête — la bande creusée de
## l'affluent (6,3 m de demi-largeur au contrat du lot) reste libre.
##
## LE LIEU AVAIT LA PROPORTION LA PLUS COMMUNE DU CORPUS (v7). Le détecteur
## R-D3 rejoué sur les silhouettes du rework a rendu FAIL : source × ferme
## abandonnée, IoU 0,506 à 30 m (seuil 0,493) et 0,494 à 80 m (seuil 0,491),
## et source × belvédère 0,511 à 30 m. En aplat noir, cinq lieux du monde
## rendent la même barre basse — hauteur ÷ emprise entre 0,25 et 0,30 :
## ferme (0,255), camps de pillards (0,258), source (0,280), belvédère
## (0,296), pont de pierre (0,300). Trois retouches sortent la source de
## cette bande sans rien retirer à la fiction : la bouche baisse (mâchoires
## ×1,35/×1,30 → ×1,15/×1,12, couronne redescendue), le bloc tombé cesse
## d'être enfoui à −0,95 m, et le lieu s'étire sur son axe COURT (margelles
## nord et sud écartées, bloc reculé au sud). La vasque, elle, GRANDIT
## (R 3,0 → 3,3) : elle est la seule surface claire du ravin, donc sa part
## d'image est la promesse elle-même.
##
## CE LIEU N'AJOUTE PAS D'EAU AU MONDE. `NappeSource` est un maillage
## visuel, sans collision, sans `WaterMatterComponent`, sans nœud de
## graphe : l'hydrologie V2.2 est gelée et reste seule maîtresse. Le
## turquoise est celui du shader de rivière — jamais le cyan de Résonance,
## réservé aux sites systémiques et au pylône.
## LOT 1.R — DEUXIÈME CORRECTIVE (agent A). LA CAUSE DE LA « NAPPE BLANCHE »
## N'ÉTAIT PAS L'ALBÉDO : C'ÉTAIT L'ANGLE.
##
## La revue a laissé une réserve écrite — « source petite et sombre dans la
## caméra joueur gelée ». Mesuré au pixel sur les captures du commit 7c58573,
## la réserve se précise en un fait :
##
##   même vasque, caméra `_identite` (haute)   H = 190°  S = 0,237  V = 0,437
##   même vasque, caméra `_joueur` (GELÉE)     H = 137°  S = 0,079  V = 0,534
##   rivière V2.2 de référence, `_identite`    H = 179°  S = 0,273  V = 0,436
##
## La même eau, le même shader, la même exposition : vue d'en haut elle est
## turquoise et se tient à côté de la rivière V2.2 ; vue depuis la caméra de
## jugement elle est GRIS-VERT. Géométrie : la caméra joueur est à 1,6 m
## au-dessus du plan d'eau pour 14,9 m de distance, soit une incidence de
## 6,1°. À cet angle, la spéculaire renvoie le ciel blanc et l'alpha de rive
## laisse passer l'herbe pâle — deux mécanismes qu'aucune valeur d'albédo ne
## peut compenser.
##
## D'où le shader LOCAL `shaders/world_v2/poi/SH_TurquoiseSpringWater.gdshader`
## (nouveau fichier, propre à ce lieu — l'hydrologie V2.2 et son shader
## restent gelés et intouchés) : l'opacité MONTE avec l'incidence, et le
## reflet rasant est TEINTÉ turquoise au lieu d'être le blanc du ciel. La
## convention de sommet reste celle de l'hydrologie V2.2 au caractère près,
## donc la continuité de construction avec la rivière est préservée.
##
## Deux réponses géométriques à « petite », toutes deux dans le même module :
##  * le fil du déversoir s'élargit et porte DEUX RENFLEMENTS — des flaques
##    où l'eau s'étale. Elles sont à 8–11 m de la caméra au lieu de 15, et
##    sous une incidence de 9 à 12° au lieu de 6 : plus grandes à l'écran ET
##    mieux vues. Elles ÉPOUSENT le sol comme le reste du fil : un plan
##    d'eau posé à plat sur une pente est la troisième cause de rejet du
##    contrat, et on ne l'échange pas contre de la surface ;
##  * les rebords deviennent MOUILLÉS : le lit déborde le rivage d'une frange
##    IRRÉGULIÈRE (chaque secteur tiré entre 0 et 0,55 m). Irrégulière parce
##    qu'un débord constant redessinerait l'anneau noir déjà mesuré et
##    corrigé en v3 — la frange se lit en taches de terre trempée, pas en
##    cerne.
## LOT 1.R.1 — CONVERGENCE. LE VERDICT NE PORTE PLUS SUR LA COULEUR.
##
## « Trop petite et secondaire dans la caméra joueur. » L'eau, elle, est
## acquise et mesurée (H 189°, S 0,490 dans la caméra gelée, contre H 176–185°
## S 0,368 pour la rivière V2.2 du même lot) : ce qui manque n'est pas la
## teinte, c'est la PRÉSENCE de ce qui l'entoure.
##
## Le sujet de ce lieu est « l'œil » ENTIER — l'eau, les mâchoires dont elle
## sort, les rebords qui la tiennent. Sur `iter5/turquoise_spring_joueur.png`,
## à taille réelle, cet œil n'existe pas : un filet turquoise dans le tiers bas
## du cadre, cerné de cailloux bleu marine de 2,6 m, écrasé par le talus brun
## qui occupe la moitié de l'image.
##
## Trois changements y répondent, et AUCUN ne touche au cadrage — déplacer une
## caméra pour flatter une image est l'A/B malhonnête que la règle
## transversale nº 4 du contrat interdit nommément :
##
##  1. LA ROCHE DEVIENT UN GLB DÉDIÉ (`SM_SpringMaw.glb`, générateur
##     `source_assets/blender/environment/make_spring_maw.py`). Quatre masses
##     à surface continue, nervurées, à jupe ENTERRÉE, remplacent SEPT pièces
##     de kit. Les mâchoires passent de 2,6 m à ≈ 4,0 m et s'écartent, la
##     couronne ferme la fente, un rebord à trois lobes fondus tient la vasque.
##     Agrandir le kit n'aurait pas suffi : `Rock_Medium_*` est une famille de
##     GALETS, et un galet agrandi reste un galet — c'est la même loi de FORME
##     que celle déjà mesurée au belvédère, pas une affaire de teinte.
##  2. LA VASQUE S'ÉLARGIT (R 3,3 → 3,95) mais PAS du côté du fruit : un
##     retrait directionnel garde la berge sous l'ancre de récompense, qui est
##     gelée. Sans lui, l'eau montait sur le fruit.
##  3. LE MOUILLAGE EST DANS LA PIERRE. Chaque masse déclare le côté et la
##     hauteur où l'eau la touche ; la roche y est plus sombre et tire vers le
##     pétrole. C'est l'indice d'humidité demandé, il vit dans `COLOR_0` donc
##     il survit à tous les presets, et il ne peut pas devenir un cerne : il
##     dépend de l'AZIMUT autant que de la hauteur, parce qu'une roche trempée
##     sur tout son pourtour se relit comme un socle sombre posé — l'anneau
##     noir que le lit de cette vasque a déjà payé deux fois.
##
## BUDGET D7 : le lieu était PLEIN (12/12). 12 − 7 pièces de kit + 4 masses
## = 9 modules. Les trois lobes du rebord ne comptent que pour UN : ils vivent
## dans un seul objet du GLB, et c'est précisément pour cela qu'ils y sont
## fondus plutôt que posés séparément.
class_name TurquoiseSpringPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")
## L'eau de ce lieu, et de lui seul. `SH_WorldV2Water` reste gelé.
const EAU_SHADER: String = \
	"res://shaders/world_v2/poi/SH_TurquoiseSpringWater.gdshader"
## Les quatre masses du lieu. Un seul GLB, quatre objets : on instancie, on ne
## garde que l'objet demandé (même recette que les crocs du belvédère et que
## les stèles du champ).
const MAW_GLB: String = "res://assets/environment/rocks/SM_SpringMaw.glb"

## (`TONE_ROCK_A/B` et `TONE_MOUSSE` ont quitté ce fichier avec les sept
## pièces de kit qu'ils teintaient : la roche vient désormais d'un GLB dont la
## matière vit dans `COLOR_0`. Les deux mesures qui les avaient produits
## restent vraies et valent pour toute pièce de kit du dépôt : (v1) la coiffe
## « grass » de l'atlas Rocks rend MENTHE VIF si on ne lui donne pas sa propre
## teinte ; (v2) sous une lumière chaude, un multiplicateur presque neutre
## ressort CHAUD — sur `iter3/spring_gros_fente.png` les mâchoires rendaient
## olive, et il a fallu relever franchement le rapport bleu/rouge pour obtenir
## le « froid » que le contrat demande.)
##
## `TONE_RIM` reste : les trois dalles du déversoir sont encore des pièces de
## kit, et elles sont les seules du lieu à en être.
const TONE_RIM: Color = Color(0.66, 0.70, 0.80)
## Lit de vasque : v4 — le CENTRE tire vers la sarcelle (dépôt minéral :
## c'est le mécanisme réel d'une source turquoise — l'eau se colore par
## son fond), le BORD reste terre humide. La teinte par sommet porte le
## dégradé de HUE (elle multiplie par canal, pas seulement en valeur).
const TONE_LIT: Color = Color(0.27, 0.27, 0.25)
const LIT_CENTRE: Color = Color(0.52, 1.0, 0.98)
const LIT_BORD: Color = Color(1.0, 0.92, 0.80)
## Centre de la vasque, dans le repère du lieu — au pied de la paroi.
const BASSIN_X: float = -5.4
const BASSIN_Z: float = 0.2
## 3,0 → 3,3 (v7). Deux raisons, aucune décorative : la vasque est la seule
## surface CLAIRE d'un ravin sombre, donc sa part d'image EST la promesse
## (addendum §3) ; et le rayon haché monte à R×1,08, soit 3,56 m — l'ancre
## du fruit, à 3,84 m du centre, reste sur la berge avec 28 cm de marge.
## 3,3 → 3,95 (lot 1.R.1). La vasque est la seule surface claire d'un ravin
## sombre : sa part d'image EST la promesse. Elle ne grandit PAS uniformément
## — voir `_retrait_ancre()`.
const BASSIN_R: float = 3.95
## Azimut de l'ancre du fruit vue du centre de vasque : l'ancre est en
## (−2,4 ; 2,6), le centre en (−5,4 ; 0,2), soit un vecteur (+3,0 ; +2,4),
## donc 38,7° = 0,675 rad. Le rivage se RETIRE dans ce secteur : sans cela
## l'élargissement noierait la récompense, qui est gelée et ne se déplace pas
## pour arranger une image.
const ANCRE_AZIMUT: float = 0.675
## Direction du déversoir : de la vasque vers les dalles puis la tête
## d'affluent (local +6 ; −6). Normalisée de (7,0 ; −5,2).
const FIL_DIR: Vector2 = Vector2(0.803, -0.596)


func default_place_id() -> StringName:
	return &"valley.poi.turquoise_spring.01"


func _build() -> void:
	# — LES DEUX MÂCHOIRES. Deux masses au PIED de la pente, penchées l'une
	# vers l'autre, qui ouvrent entre elles la fente d'où l'eau sort. Ce n'est
	# PAS une porte : deux formes différentes, deux inclinaisons, deux
	# hauteurs, pieds enterrés.
	#
	# HISTOIRE DE LEUR TAILLE, ET ELLE SE CONTREDIT — c'est la question que
	# cette passe laisse ouverte, autant l'écrire ici. En v7 les mâchoires
	# avaient été BAISSÉES (×1,35 → ×1,15) pour sortir le lieu de la bande de
	# proportion la plus encombrée du corpus : le détecteur R-D3 rendait FAIL
	# (source × ferme abandonnée, IoU 0,506 à 30 m pour un seuil de 0,493) et
	# cinq lieux y rendaient la même barre basse en aplat noir. Le lot 1.R.1
	# demande l'inverse — de la PRÉSENCE — et les remonte à ≈ 4,0 m. Les deux
	# demandes sont légitimes et elles tirent en sens contraire ; le détecteur
	# rejoué tranchera, pas ce commentaire.
	#
	# LOT 1.R.1 : les mâchoires passent de 2,6 m à ≈ 4,0 m et S'ÉCARTENT
	# (z ±1,9/2,4 → −3,4/+3,8). L'écartement n'est pas décoratif : à masses
	# grossies et positions inchangées, les deux enveloppes se touchaient et
	# la fente — le point d'où l'eau sort — se refermait.
	#
	# ITÉRATION 12 — L'ANNEAU S'ÉLARGIT SUR LES DEUX AXES, et le geste est
	# prouvé par l'arithmétique AVANT d'être bâti
	# (`evidence/.../voie_a3/controles/controle_occlusion_iter12.py`, PASS au
	# commit be98d97). Les mâchoires s'écartent encore en Z (−3,4 → −5,2 et
	# +4,2 → +6,1) : la couronne de roche grandit AUTOUR de l'œil — la
	# composition joueur y gagne, l'eau reste au centre. Leur amincissement en
	# X (demi_a, côté générateur) recule leur face est : c'est la moitié ouest
	# du corridor de 2,62 m dont les flancs est du rebord forment l'autre
	# moitié. Le support de la mâchoire sud était déclaré à (−9,5 ; 3,8) — la
	# position d'AVANT le commit 49b4913 — pendant que la masse était à
	# (−10,1 ; 4,2) : un appui D2 qui flottait à 70 cm de sa pierre. Les deux
	# suivent désormais le même littéral.
	var machoire_n: Vector3 = _seated(-9.9, -5.2)
	_masse(&"SM_Spring_MawN", "Machoire_nord", -9.9, -5.2, 18.0, 0.22, true)
	declare_support(machoire_n)
	var machoire_s: Vector3 = _seated(-10.1, 6.1)
	_masse(&"SM_Spring_MawS", "Machoire_sud", -10.1, 6.1, -24.0, 0.22, true)
	declare_support(machoire_s)
	# — LA COURONNE ferme le haut de la fente : l'eau sort d'un creux fermé,
	# pas d'un intervalle entre deux objets.
	# La couronne remonte sur la pente (−10,4 → −11,0) et s'enfonce davantage :
	# le sol y gagne ≈ 1 m en un mètre et demi (profils mesurés en tête de
	# fichier), et une masse posée à plat sur une pente montre sa jupe.
	# Itération 12 : la couronne recule d'un cran vers l'est (−11,0 → −10,6,
	# le sol mesuré y est 40 cm plus bas : elle coiffe la fente sans remonter)
	# et glisse au sud (0,3 → 0,85) pour laisser la respiration nord–couronne
	# du masque 0° (mesurée 0,63 m au pré-contrôle).
	var couronne: Vector3 = _seated(-10.6, 0.85)
	_masse(&"SM_Spring_Crown", "Couronne_fente", -10.6, 0.85, 40.0, 0.35, true)
	declare_support(couronne)

	# — LA VASQUE. Le lit D'ABORD, la nappe ensuite, les margelles au bord
	# de l'eau — jamais l'inverse.
	_lit()
	_nappe()
	# — LE REBORD : trois lobes FONDUS dans un seul objet, donc un seul
	# module. Ils remplacent les trois margelles de kit et le bloc tombé.
	#
	# ANNEAU ROMPU, jamais un cercle : nord, est et sud, RIEN à l'ouest —
	# c'est de ce côté que l'eau arrive, et un rebord y boucherait la fente.
	# Le lobe EST est l'ÉCRIN de la récompense (audit v1 : le fruit flottait
	# sans écrin) et il est délibérément le plus BAS des trois : il se trouve
	# entre la caméra du joueur et l'eau, et un rebord qui masque le sujet
	# qu'il encadre est un contresens.
	#
	# Le mouillage de ces lobes est porté par leur `COLOR_0` (azimut 215°,
	# hauteur 0,85 m) : la pierre est trempée du côté de l'eau, sèche de
	# l'autre. C'est l'indice d'humidité demandé, et il ne coûte rien.
	_masse(&"SM_Spring_Rim", "Rebord_vasque", BASSIN_X, BASSIN_Z, 0.0, 0.30,
		false)
	# Les appuis DÉCLARÉS suivent les lobes, pas l'objet : le filet D2 lit des
	# points, et un point au centre de la vasque serait un appui sur de l'eau.
	# Itération 12 : les lobes nord et sud sont désormais les FLANCS EST
	# (x −2,95, z −5,1/+6,2) — leurs appuis les suivent. L'écrin ne bouge pas.
	for lobe: Vector2 in [Vector2(-2.95, -5.1), Vector2(-1.5, 3.9),
			Vector2(-2.95, 6.2)]:
		declare_support(_seated(lobe.x, lobe.y))
	# — LE FIL QUI S'EN VA. Trois dalles mouillées, à demi enfoncées, qui
	# descendent au nord-est vers la tête de l'affluent (local +6 ; −6),
	# le long de la langue d'eau de la nappe. La dernière s'arrête à 5,0 m
	# de la tête : le lit gelé reste libre. Chacune DÉCLARE son assise :
	# ce sont les seules pièces portées du tiers est de l'emprise, et le
	# filet D2 exige un appui là-bas — la vasque et la fente, tout à
	# l'ouest, ne prouvent rien de ce côté.
	for spec: Array in [[-1.2, -3.4, 24.0, &"RockPath_Round_Small_1"],
			[0.6, -4.4, -51.0, &"RockPath_Square_Small_1"],
			[1.6, -5.0, 12.0, &"RockPath_Round_Small_1"]]:
		var assise: Vector3 = _seated(float(spec[0]), float(spec[1]))
		K.module(self, spec[3] as StringName,
			assise + Vector3(0.0, -0.05, 0.0), float(spec[2]), 1.0, TONE_RIM)
		declare_support(assise)
	# BUDGET D7 après le lot 1.R.1 : quatre masses de GLB + trois dalles de
	# kit + la nappe + le lit = 9 modules sur 12. Le lieu était PLEIN ; il ne
	# l'est plus, et les trois slots libérés le sont parce que sept pièces de
	# kit ont fusionné dans quatre objets, pas parce qu'on a retiré du contenu.

	_collisions()

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "La Source aux reflets"
	poi.region = &"r04_falaises_du_couchant"
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Decouverte_forme"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 12.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	# Le fruit de soin pousse au bord de l'eau, côté est — le côté par
	# lequel on arrive, et le seul qui ne soit pas contre la paroi. Il est
	# POSÉ AU SOL, niché au pied du lobe EST du rebord (audit v1 : il flottait
	# à 0,3-0,5 m sans écrin). Le lobe est en (−2,6 ; 2,3) et lui fait un dos
	# de pierre ; c'est aussi pour lui que le rivage se retire dans ce secteur
	# (`_retrait_ancre`), sinon la vasque élargie serait montée sur le fruit.
	# −0,06 : `IngredientPickup` dessine sa baie centrée à +0,22 (rayon
	# 0,14) au-dessus de l'ancre — la baie touche donc le sol au lieu de
	# flotter (audit : trois captures avec le fruit en lévitation).
	RewardAnchor.attach(self, default_place_id(),
		RewardAnchor.Kind.INGREDIENT,
		_seated(-2.4, 2.6) + Vector3(0.0, -0.06, 0.0), Vector3(2.0, 0.0, 2.0))


## LE LIT DE VASQUE — terre noyée sombre qui ÉPOUSE le terrain (chaque
## sommet échantillonne le sol gelé, +3 cm), sous la nappe et sous sa
## langue de déversoir. Exemption D1a NOMMÉE, même titre que la nappe :
## une surface qui suit le terrain sommet par sommet, comme `SolBrule` de
## l'arbre foudroyé. Sans lui, l'eau transparente laisse voir l'herbe du
## pad et la vasque se lit décalcomanie — c'est le défaut rejeté.
func _lit() -> void:
	var lit: MeshInstance3D = MeshInstance3D.new()
	lit.name = "FondVasque"
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments: int = 40
	var rayons: PackedFloat32Array = _rayons_vasque(segments)
	var centre_y: float = _y_sol(BASSIN_X, BASSIN_Z, 0.03)
	# PLAFOND DU LIT — réparation d'une régression que J'AI faite en élargissant
	# la vasque (R 3,3 → 3,95). Le lit épouse le terrain ; la nappe, elle, est
	# un PLAN à la hauteur du centre. En grandissant, la vasque atteint du
	# terrain PLUS HAUT que ce plan, et le lit ressortait au-dessus de son
	# eau — deux coins NOIRS mesurés sur `iter8/spring_gros_eau.png`. C'est
	# l'anneau noir de la v3, revenu par une porte que je venais d'ouvrir.
	# Une surface de fond qui passe au-dessus de son eau n'est pas un fond.
	var plafond: float = _y_sol(BASSIN_X, BASSIN_Z, 0.08) - 0.04
	var bord: PackedVector3Array = PackedVector3Array()
	for i: int in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		# STRICTEMENT SOUS la nappe (−0,15) : en v1 puis v2 le lit
		# débordait du rivage et dessinait un ANNEAU NOIR autour de l'eau
		# (mesuré sur les deux captures). Le bord du lit doit mourir sous
		# l'eau ; c'est l'herbe du pad qui rencontre la rive, et la mousse
		# du shader qui fait la transition.
		var r: float = rayons[i] - 0.15 + _bosse_ouest(angle) * 1.60
		var px: float = BASSIN_X + cos(angle) * r
		var pz: float = BASSIN_Z + sin(angle) * r
		bord.append(Vector3(px, minf(_y_sol(px, pz, 0.03), plafond), pz))
	var centre: Vector3 = Vector3(BASSIN_X, minf(centre_y, plafond), BASSIN_Z)
	for i: int in range(segments):
		var j: int = (i + 1) % segments
		# Centre SARCELLE, bord terre : le dégradé de teinte du fond est
		# ce qui colore l'eau transparente au-dessus de lui.
		var t_bord: Color = Color(
			LIT_BORD.r * (0.90 + 0.08 * _alea(float(i) * 3.1)),
			LIT_BORD.g * (0.90 + 0.08 * _alea(float(i) * 3.1)),
			LIT_BORD.b * (0.90 + 0.08 * _alea(float(i) * 3.1)), 1.0)
		_tri_couleur(st, centre, bord[i], bord[j], LIT_CENTRE, t_bord)
	# LA FRANGE MOUILLÉE. Le lit déborde le rivage, mais d'une largeur TIRÉE
	# PAR SECTEUR entre 0 et 0,42 m : un débord constant redessinerait le
	# cerne noir mesuré en v1/v2 et corrigé en v3. Ici certains secteurs ne
	# débordent pas du tout, et la pierre trempée se lit en TACHES.
	# La teinte s'ÉCLAIRCIT vers l'extérieur (1,30 au bord d'eau → 1,75 en
	# pointe de frange) : c'est ce qui empêche la frange d'être un trait
	# sombre autour de l'eau. Ces deux nombres ont DÉJÀ été faux une fois —
	# voir la note de régression ci-dessous ; ils sont recopiés du code.
	var frange: PackedVector3Array = PackedVector3Array()
	var teintes_frange: PackedColorArray = PackedColorArray()
	for i: int in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		var tirage: float = 0.5 + 0.5 * _alea(float(i) * 1.7 + 19.3)
		# Rien à l'ouest : c'est la fente, et la roche y descend.
		var largeur: float = 0.42 * tirage * (1.0 - _bosse_ouest(angle) * 0.8)
		var r: float = rayons[i] - 0.15 + _bosse_ouest(angle) * 1.60 + largeur
		var px: float = BASSIN_X + cos(angle) * r
		var pz: float = BASSIN_Z + sin(angle) * r
		frange.append(Vector3(px, _y_sol(px, pz, 0.025), pz))
		# v2 — REMONTÉE, ET C'EST UNE CORRECTION DE MA PROPRE RÉGRESSION.
		# À (0,90 … 1,45) sur un matériau de base déjà sombre (0,27), la
		# frange sortait en COINS NOIRS autour de l'eau (mesuré sur
		# `iter3/spring_gros_eau.png` et `spring_gros_fente.png`) : c'est
		# exactement l'anneau noir que la v3 de la première corrective avait
		# supprimé, revenu par la porte que la frange venait d'ouvrir.
		# La pierre trempée est plus sombre que la pierre sèche, pas plus
		# sombre que TOUT : la plage va donc de « un peu sous l'herbe » à
		# « herbe », et la frange meurt au lieu de cerner.
		var v: float = 1.75 - 0.45 * (1.0 - tirage)
		teintes_frange.append(Color(LIT_BORD.r * v, LIT_BORD.g * v,
			LIT_BORD.b * v, 1.0))
	# 0,72 → 1,30 : le bord d'eau reste le point le plus sombre de la frange,
	# mais il cesse d'être un trait noir. La différence avec la pointe de
	# frange (1,75) suffit à lire « mouillé », et c'est ce qu'on voulait.
	var mouille: Color = Color(LIT_BORD.r * 1.30, LIT_BORD.g * 1.28,
		LIT_BORD.b * 1.20, 1.0)
	for i: int in range(segments):
		var j: int = (i + 1) % segments
		# Trois teintes distinctes, une par sommet : avec `_tri_couleur` (une
		# teinte de centre, une de bord) le sommet `bord[j]` de la seconde
		# face aurait reçu la teinte CLAIRE de la frange, et une pointe pâle
		# serait apparue sur la ligne d'eau — exactement l'inverse de ce que
		# la frange doit faire.
		_tri3(st, bord[i], frange[i], frange[j], mouille, teintes_frange[i],
			teintes_frange[j])
		_tri3(st, bord[i], frange[j], bord[j], mouille, teintes_frange[j],
			mouille)

	# L'ombre du fil : une bande humide sous la langue du déversoir, un
	# peu plus large qu'elle — le sol mouillé déborde toujours l'eau. Les
	# mêmes renflements que l'eau, sinon les flaques déborderaient sur de
	# l'herbe sèche.
	# Départ reculé (2,65 → 3,20) parce que le rivage a grandi, et LONGUEUR
	# RACCOURCIE d'autant (5,1 → 4,55) : le bout de la bande retombe au
	# centimètre près où il était. Sans cette compensation, la langue avançait
	# de 55 cm vers la tête d'affluent et tombait sous les 5 m que le contrat
	# du lot exige de laisser libres.
	_bande(st, 3.20, 4.55, 1.85, 0.98, 0.03, Color(0.88, 0.84, 0.74, 1.0),
		Color(1.0, 0.95, 0.85, 1.0), true, false)
	lit.mesh = st.commit()
	var terre: StandardMaterial3D = K.flat_material(TONE_LIT)
	terre.vertex_color_use_as_albedo = true
	lit.mesh.surface_set_material(0, terre)
	add_child(lit)


## LA NAPPE — le maillage d'eau du lieu : la vasque, sa bouche sous la
## fente, et la LANGUE du déversoir qui suit le sol vers les dalles.
## Un seul module runtime, un seul matériau : le shader de la rivière V2.2.
##
## Le bord n'est PAS harmonique. L'arbre foudroyé a payé une revue pour
## avoir modulé son disque par deux sinus purs : cinq lobes réguliers, une
## « étoile ». Ici le rayon vient d'un hachage par secteur lissé sur trois
## voisins — la modulation n'a plus de période.
##
## Couleurs de sommet = convention EXACTE de l'hydrologie V2.2 :
## R profondeur (0 = rive mousseuse, 1 = fond), GB courant encodé
## (0,5 = immobile), A opacité. Le shader fait le reste — turquoise au
## bord, pétrole au centre, mousse cassée à la rive, rides dérivantes.
func _nappe() -> void:
	# L'exemption d'AIRE des maillages runtime, RÉELLEMENT posée : nappe ET
	# lit — les deux épousent le terrain, aucun autre nœud runtime au lieu.
	# Elle ne porte QUE sur D1a : au budget D7 les deux modules COMPTENT
	# (c'est pour ça que le lieu a cédé sa fougère).
	set_meta(&"exemption_runtime",
		PackedStringArray(["NappeSource", "FondVasque"]))
	var nappe: MeshInstance3D = MeshInstance3D.new()
	nappe.name = "NappeSource"
	var segments: int = 40
	var rayons: PackedFloat32Array = _rayons_vasque(segments)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# 0,08 au-dessus du pad : assez pour noyer la base des margelles, assez
	# bas pour que la tranche d'eau au rivage ne montre pas de falaise.
	var niveau: float = _y_sol(BASSIN_X, BASSIN_Z, 0.08)
	var interieur: PackedVector3Array = PackedVector3Array()
	var exterieur: PackedVector3Array = PackedVector3Array()
	var teintes_ext: PackedColorArray = PackedColorArray()
	for i: int in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		# La bouche : vers l'ouest, la nappe s'étire jusque sous le seuil
		# de la fente — l'eau SORT de la paroi, elle n'apparaît pas au
		# milieu de l'herbe.
		var r_ext: float = rayons[i] + _bosse_ouest(angle) * 1.60
		var r_int: float = rayons[i] * (0.50 + 0.08 * _alea(float(i) * 4.7))
		interieur.append(Vector3(BASSIN_X + cos(angle) * r_int, niveau,
			BASSIN_Z + sin(angle) * r_int))
		exterieur.append(Vector3(BASSIN_X + cos(angle) * r_ext, niveau,
			BASSIN_Z + sin(angle) * r_ext))
		# Rive peu profonde partout (mousse cassée), nettement plus creuse
		# à la bouche (l'eau y arrive, elle n'y meurt pas).
		# v5 — mesuré sur la capture P1 : à profondeur faible, l'eau au
		# ras rend GRIS CIEL (alpha 0,6 + spéculaire) et la « tache
		# turquoise » de la promesse n'existe pas à distance. La vasque
		# est donc PROFONDE : alpha 0,9, couleur pétrole saturée du
		# shader — c'est le levier autorisé par l'arbitrage (« profondeur
		# au centre via couleurs de sommet »).
		# Rive à 0,12 — SOUS le seuil de mousse du shader (0,16) : l'anneau
		# de mousse cassée est ce qui accroche l'œil aux vues rasantes, où
		# la teinte de l'eau disparaît dans le reflet du ciel (mesuré P1).
		var prof_rive: float = 0.45 if _bosse_ouest(angle) > 0.3 else 0.12
		var courant: Vector2 = Vector2(0.5, 0.5)
		if _bosse_ouest(angle) > 0.3:
			# À la bouche, l'eau pousse vers l'est (elle sort de la fente).
			courant = Vector2(0.5 + 0.9 * 0.35, 0.5)
		teintes_ext.append(Color(prof_rive, courant.x, courant.y, 1.0))
	var teinte_centre: Color = Color(0.85, 0.5, 0.5, 1.0)
	var teinte_int: Color = Color(0.62, 0.5, 0.5, 1.0)
	var centre: Vector3 = Vector3(BASSIN_X, niveau, BASSIN_Z)
	for i: int in range(segments):
		var j: int = (i + 1) % segments
		_tri_eau(st, [centre, interieur[i], interieur[j]],
			[teinte_centre, teinte_int, teinte_int])
		_tri_eau(st, [interieur[i], exterieur[i], exterieur[j]],
			[teinte_int, teintes_ext[i], teintes_ext[j]])
		_tri_eau(st, [interieur[i], exterieur[j], interieur[j]],
			[teinte_int, teintes_ext[j], teinte_int])
	# LA LANGUE DU DÉVERSOIR : une bande mince qui quitte la vasque vers
	# les dalles, épouse le sol (+4,5 cm) et s'amincit jusqu'à s'éteindre —
	# le fil lisible exigé, dans le MÊME module et le MÊME shader.
	# Départ à 2,85 (et non 2,55) : le rivage a grandi avec BASSIN_R, la
	# langue doit toujours NAÎTRE sous la nappe, jamais à côté d'elle.
	# Bout de langue : (0,78 ; −4,39) local, soit 5,47 m de la tête
	# d'affluent gelée (+6 ; −6) — le lit reste libre (contrat ≥ 5 m).
	# LARGEURS RELEVÉES (0,85 → 1,30 au départ, 0,34 → 0,52 au bout) et DEUX
	# RENFLEMENTS. C'est la réponse géométrique à « source petite » : dans la
	# caméra joueur gelée, la vasque est à 14,9 m sous 6° d'incidence, alors
	# que le milieu du fil est à ~10 m sous ~9° et son bout à ~8 m sous ~12°.
	# Une surface d'eau placée LÀ est plus grande à l'écran et mieux vue,
	# sans qu'aucune caméra n'ait bougé.
	var gb: Vector2 = Vector2(FIL_DIR.x * 0.5 + 0.5, FIL_DIR.y * 0.5 + 0.5)
	# Même compensation que pour le lit : 2,85 → 3,40 de départ, 4,8 → 4,25 de
	# longueur. Le bout de langue reste à 5,47 m de la tête d'affluent gelée,
	# la valeur déjà publiée. Largeurs relevées (1,30 → 1,55 ; 0,52 → 0,60) :
	# c'est la portion d'eau la plus PROCHE de la caméra joueur, donc celle
	# dont chaque centimètre compte le plus à l'écran.
	_bande(st, 3.40, 4.25, 1.55, 0.60, 0.045,
		Color(0.20, gb.x, gb.y, 0.95), Color(0.06, gb.x, gb.y, 0.45),
		true, true)
	nappe.mesh = st.commit()
	var eau: ShaderMaterial = ShaderMaterial.new()
	eau.shader = load(EAU_SHADER) as Shader
	eau.set_shader_parameter(&"wave_noise",
		WorldV2GroundMaterial.grain_texture())
	nappe.mesh.surface_set_material(0, eau)
	add_child(nappe)
	declare_support(Vector3(BASSIN_X, _y_sol(BASSIN_X, BASSIN_Z, 0.0),
		BASSIN_Z))


## Rayons hachés de la vasque — déterministes (pas de `randf()` : la
## régression visuelle compare deux montages, ils doivent être identiques).
func _rayons_vasque(segments: int) -> PackedFloat32Array:
	var brut: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(segments):
		brut.append(_alea(float(i) * 2.3 + 7.1))
	var rayons: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(segments):
		var lisse: float = (brut[(i - 1 + segments) % segments] + brut[i]
			+ brut[(i + 1) % segments]) / 3.0
		var angle: float = TAU * float(i) / float(segments)
		rayons.append(BASSIN_R * (0.88 + 0.20 * lisse) * _retrait_ancre(angle))
	return rayons


## LE RIVAGE SE RETIRE DEVANT LA RÉCOMPENSE.
##
## La vasque passe de R 3,3 à 3,95 pour gagner en présence. L'ancre du fruit,
## elle, est GELÉE en (−2,4 ; 2,6), soit 3,84 m du centre : à rayon uniforme,
## le rivage haché montait à 4,27 m et le fruit se serait retrouvé DANS l'eau.
## Un retrait de 19 % dans son secteur ramène le rivage à ≈ 3,2 m et laisse
## 0,6 m de berge — et c'est la berge qui bouge, jamais la récompense.
func _retrait_ancre(angle: float) -> float:
	var ecart: float = wrapf(angle - ANCRE_AZIMUT, -PI, PI)
	return 1.0 - 0.19 * exp(-pow(ecart / 0.85, 2.0))


## Poids de la bouche ouest : 1 plein ouest, 0 hors du secteur ±38°.
func _bosse_ouest(angle: float) -> float:
	var delta: float = absf(wrapf(rad_to_deg(angle) - 180.0, -180.0, 180.0))
	return clampf(1.0 - delta / 38.0, 0.0, 1.0)


## Bande de quads le long du fil du déversoir, du bord de vasque vers les
## dalles — elle ÉPOUSE le sol gelé (+`sur_sol`) sommet par sommet. Les
## teintes portent les données du matériau appelant : convention d'eau
## pour la nappe, valeur multiplicative pour le lit.
##
## `renflements` ajoute deux ÉLARGISSEMENTS le long du parcours : des flaques
## où l'eau s'étale avant de repartir. Elles suivent le sol comme le reste de
## la bande — c'est volontaire et non négociable : une surface plane posée en
## travers d'une pente est un « plan d'eau flottant », l'une des trois causes
## de rejet du lieu. On gagne de la surface vue, jamais en trichant sur
## l'assise.
##
## `eau` dit si la teinte porte la convention d'eau (R = profondeur) ou une
## valeur multiplicative (le lit). Sans ce drapeau, creuser les renflements
## reviendrait à teinter le sol mouillé en ROUGE — le canal R ne veut pas
## dire la même chose dans les deux matériaux.
func _bande(st: SurfaceTool, depart_r: float, longueur: float,
		larg_depart: float, larg_fin: float, sur_sol: float,
		teinte_depart: Color, teinte_fin: Color,
		renflements: bool = false, eau: bool = false) -> void:
	var pas: int = 20 if renflements else 8
	var perp: Vector2 = Vector2(-FIL_DIR.y, FIL_DIR.x)
	var origine: Vector2 = Vector2(BASSIN_X, BASSIN_Z) + FIL_DIR * depart_r
	var precedent_g: Vector3 = Vector3.ZERO
	var precedent_d: Vector3 = Vector3.ZERO
	var precedent_t: Color = teinte_depart
	for k: int in range(pas + 1):
		var t: float = float(k) / float(pas)
		var centre2: Vector2 = origine + FIL_DIR * (longueur * t)
		# Ondulation légère du fil — un ruisselet droit se lit tracé.
		centre2 += perp * (0.22 * sin(t * 9.4 + 1.3) * (1.0 - t))
		var bosse: float = 0.0
		if renflements:
			# Deux gaussiennes, largeurs et hauteurs différentes : deux
			# flaques identiques se reliraient comme un motif.
			bosse = 0.95 * exp(-pow((t - 0.34) / 0.135, 2.0)) \
				+ 0.72 * exp(-pow((t - 0.74) / 0.115, 2.0))
		var demi: float = lerpf(larg_depart, larg_fin, t) * 0.5 * (1.0 + bosse)
		var g2: Vector2 = centre2 + perp * demi
		var d2: Vector2 = centre2 - perp * demi
		var gauche: Vector3 = Vector3(g2.x, _y_sol(g2.x, g2.y, sur_sol), g2.y)
		var droite: Vector3 = Vector3(d2.x, _y_sol(d2.x, d2.y, sur_sol), d2.y)
		var teinte: Color = teinte_depart.lerp(teinte_fin, t)
		if eau and bosse > 0.0:
			# Une flaque est plus PROFONDE qu'un filet : sa couleur tire vers
			# le pétrole du fond, et elle cesse d'être un film transparent.
			teinte.r = minf(1.0, teinte.r + 0.55 * bosse)
			teinte.a = maxf(teinte.a, minf(0.98, 0.55 + 0.45 * bosse))
		if k > 0:
			_tri_eau(st, [precedent_g, gauche, droite],
				[precedent_t, teinte, teinte])
			_tri_eau(st, [precedent_g, droite, precedent_d],
				[precedent_t, teinte, precedent_t])
		precedent_g = gauche
		precedent_d = droite
		precedent_t = teinte


## Quatre volumes — et AUCUN sur le fil de l'eau : les dalles du déversoir
## sont à plat et se franchissent, un corps solide dessus ferait une marche
## au milieu d'un ruisseau. Itération 12 : les deux flancs est portent
## désormais ≈ 2,3 m de roche chacun — un joueur ne doit pas les traverser.
## Quatre boîtes + la sphère du POI = 5 formes sur les 6 du budget micro.
## Distances à la tête d'affluent gelée (+6 ; −6) : nord 15,9 m, sud 20,1 m,
## flanc nord 9,0 m, flanc sud 15,1 m — le contrat en demande 5.
func _collisions() -> void:
	# Volumes plus ÉTROITS que le visible : le pied s'évase et se franchit,
	# on ne bute pas sur son évasement. Les mâchoires amincies en X (demi_a
	# 1,50/1,30) reçoivent des boîtes amincies de même.
	K.collider_box(self, "Source_machoire_nord",
		_seated(-9.9, -5.2) + Vector3(0.0, 1.5, 0.0), Vector3(2.6, 3.0, 3.6),
		18.0)
	K.collider_box(self, "Source_machoire_sud",
		_seated(-10.1, 6.1) + Vector3(0.0, 1.3, 0.0), Vector3(2.2, 2.6, 3.2),
		-24.0)
	K.collider_box(self, "Source_flanc_nord",
		_seated(-2.95, -5.1) + Vector3(0.0, 0.9, 0.0), Vector3(2.4, 1.8, 2.2),
		30.0)
	K.collider_box(self, "Source_flanc_sud",
		_seated(-2.95, 6.2) + Vector3(0.0, 0.8, 0.0), Vector3(2.2, 1.6, 2.0),
		150.0)


## Hachage déterministe dans [−1 ; 1]. Pas de `randf()` : la nappe doit
## être identique d'un montage à l'autre, sinon la régression visuelle
## compare deux formes différentes et ne prouve rien.
func _alea(graine: float) -> float:
	var v: float = sin(graine * 127.1 + 311.7) * 43758.5453
	return (v - floor(v)) * 2.0 - 1.0


## Triangle d'eau : couleur de sommet = données du shader (R profondeur,
## GB courant, A opacité), normale verticale comme les rubans V2.2.
func _tri_eau(st: SurfaceTool, points: Array[Vector3],
		teintes: Array[Color]) -> void:
	for k: int in range(3):
		st.set_color(teintes[k])
		st.set_normal(Vector3.UP)
		st.add_vertex(points[k])


## Triangle du lit : couleur par sommet (dégradé de teinte centre → bord),
## normale verticale.
func _tri_couleur(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		c_centre: Color, c_bord: Color) -> void:
	_tri3(st, a, b, c, c_centre, c_bord, c_bord)


## Triangle à TROIS teintes indépendantes. Nécessaire dès qu'une face a un
## sommet sur la ligne d'eau et deux en frange : deux teintes ne peuvent pas
## décrire ce cas sans mentir sur l'un des sommets.
func _tri3(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		ca: Color, cb: Color, cc: Color) -> void:
	for donnee: Array in [[a, ca], [b, cb], [c, cc]]:
		st.set_color(donnee[1] as Color)
		st.set_normal(Vector3.UP)
		st.add_vertex(donnee[0] as Vector3)


## Hauteur du sol gelé + surcote, en local.
func _y_sol(local_x: float, local_z: float, sur_sol: float) -> float:
	return ground_local_y(local_x, local_z) + sur_sol


## POSER UNE MASSE DU GLB DÉDIÉ, recentrée sur son emprise et enterrée.
##
## (`_roche()` et `_teinter()` ont quitté ce fichier avec les sept pièces de
## kit qu'ils habillaient. Les deux pièges qu'ils documentaient restent VRAIS
## et vivent ailleurs : `KitPlacement.seat()` mesure AVANT le roulis, donc une
## pièce dont l'origine est sur une arête se pose ailleurs qu'où on croit — voir
## les lieux de la voie B ; et `K.apply_tone` laisse
## `vertex_color_use_as_albedo` allumé, ce qui fait rendre l'atlas Rocks en
## PISTACHE au soleil et la coiffe « grass » en MENTHE. Ici la matière vient du
## GLB, donc ni l'un ni l'autre ne s'applique.)
##
## L'ASSISE NE SE CALCULE PAS SUR LE BAS DE L'EMPRISE. Le GLB a un `min Y`
## NÉGATIF, volontairement : chaque masse est prolongée SOUS son plan de sol
## par une jupe évasée, et c'est elle qui supprime la ligne de contact
## pierre/herbe. Le plan y = 0 du modèle EST le sol prévu. Soustraire
## `boite.position.y` remonterait donc la masse de toute la hauteur de jupe et
## la reposerait SUR l'herbe — le défaut qu'on répare, obtenu en croyant le
## corriger, et rien dans le rendu ne le crierait.
##
## `recentrer` dit si l'objet doit être recentré sur son emprise. VRAI pour une
## masse unique, dont l'origine n'est pas son milieu. FAUX pour le rebord :
## ses trois lobes sont placés dans le GLB PAR RAPPORT À L'ORIGINE, et les
## recentrer sur leur emprise commune les décalerait tous.
##
## LA COULEUR DE SOMMET EST FORCÉE (ISS-066) : la matière de ces masses — le
## mouillage compris — vit dans leur `COLOR_0`. Si le matériau importé ne la
## consommait pas, la roche redeviendrait un aplat SANS erreur ni
## avertissement. On force le drapeau sur une COPIE posée en override de
## surface ; la ressource importée n'est jamais mutée.
func _masse(objet: StringName, nom: String, x: float, z: float,
		yaw_deg: float, enfoncement: float, recentrer: bool) -> Node3D:
	var packed: PackedScene = load(MAW_GLB) as PackedScene
	if packed == null:
		push_error("[source] masses introuvables — %s" % MAW_GLB)
		return null
	var racine: Node3D = packed.instantiate() as Node3D
	racine.name = nom
	var garde: bool = false
	for enfant: Node in racine.get_children():
		if enfant.name == String(objet):
			garde = true
		else:
			racine.remove_child(enfant)
			enfant.queue_free()
	if not garde:
		push_error("[source] masse %s absente du GLB" % objet)
		racine.queue_free()
		return null
	racine.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)),
		Vector3(x, 0.0, z))
	for noeud: Node in racine.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = noeud as MeshInstance3D
		if instance.mesh == null:
			continue
		for surface: int in range(instance.mesh.get_surface_count()):
			var actif: StandardMaterial3D = \
				instance.get_active_material(surface) as StandardMaterial3D
			if actif == null:
				continue
			var copie: StandardMaterial3D = actif.duplicate() \
				as StandardMaterial3D
			copie.vertex_color_use_as_albedo = true
			copie.roughness = maxf(copie.roughness, 0.94)
			copie.metallic_specular = 0.1
			instance.set_surface_override_material(surface, copie)
	add_child(racine)
	if recentrer:
		var boite: AABB = Transform3D(racine.transform.basis, Vector3.ZERO) \
			* KitPlacement.local_aabb(racine)
		var centre: Vector3 = boite.get_center()
		racine.position.x = x - centre.x
		racine.position.z = z - centre.z
	racine.position.y = ground_local_y(x, z) - enfoncement
	return racine


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
