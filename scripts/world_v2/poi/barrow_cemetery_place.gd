## CIMETIÈRE DU TERTRE (`valley.poi.barrow_cemetery.01`, r08) — trois
## masses tombées dans la steppe, et beaucoup de vide entre elles.
##
## LE VIDE EST LE CONTRAT, pas une économie. r08 dit « densité basse
## voulue — le vide est une identité » et « plans très larges ». Le terrain
## le confirme : ±1 m sur quarante mètres dans toutes les directions sauf
## le nord-est. Rien ici ne se cache derrière rien ; la lecture se fait de
## loin, et elle doit tenir en trois masses inégales séparées par de
## l'herbe rase. Le lieu le plus proche est à 46,6 m.
##
## POURQUOI DES DÔMES DE TERRE, ET POURQUOI ILS SONT CONSTRUITS EN RUNTIME.
## Un tertre est un GONFLEMENT DU SOL. Aucun module du kit ne sait se
## raccorder tangentiellement au terrain gelé à sa lisière : posé dessus,
## un rocher fait un objet ; un dôme cousu au sol fait une tombe. C'est
## exactement la famille d'exemption déjà NOMMÉE pour `SolBrule` (arbre
## foudroyé) et `rock_floor_mesh` (grotte) — de la géométrie qui doit lire
## le terrain du site AU MONTAGE. L'exemption est donc revendiquée ici pour
## trois nœuds, `Tertre_Grand`, `Tertre_Moyen` et `Tertre_Petit`, et pour
## eux seuls : tout le reste du lieu est du kit ou du GLB importé.
##
## ---------------------------------------------------------------------------
## LOT 1.R — CORRECTIVE VISUELLE, COMPOSITION A « LE CHEMIN DES MORTS »
## RENFORCÉE (arbitrage du lead). Le gate visuel a rejeté deux choses.
##
## 1. « LES TERTRES CONIQUES RÉGULIERS SONT REFUSÉS. » Cause exacte : le
##    générateur faisait des DÔMES DE RÉVOLUTION — un rayon par secteur, un
##    profil `cos^1,4`, et un SOMMET UNIQUE cousu en éventail. Un sommet
##    unique EST une pointe de cône, quel que soit le bruit qu'on met sur le
##    rayon. Le nouveau profil n'a plus de sommet : il a une CRÊTE, un
##    segment orienté sur lequel se referme l'anneau intérieur. D'où un DOS
##    long et dissymétrique au lieu d'une capsule ; le grand axe des trois
##    tertres suit à peu près le même sens (un champ funéraire s'aligne)
##    sans jamais le même angle ; et le dominant porte une FOSSE DE PILLAGE
##    creusée dans sa crête.
##    La méthode TERRAIN-HUGGING est conservée telle quelle : chaque sommet
##    du maillage appelle `ground_local_y(x, z)`. C'est le titre même de
##    l'exemption D1a, et il est donc revérifié après reprofilage.
##
## 2. « LES ARCHES BEIGE. » Cause mesurée : `SM_Dungeon_ArchBlock` et
##    `PillarStub` (trimsheet qui rend terracotta), `RockPath_Square_Wide`
##    (dalle trop propre), `cliff_half_rock` couché (des marches beige dans
##    l'herbe), et `rock_largeA/C` en ceinture — dont le glTF porte une
##    surface `grass` qui rend TURQUOISE ici. Les cinq familles sont
##    retirées. À leur place, un GLB dédié `SM_Barrow_Stones.glb` (718 tris
##    pour un budget de 4 000) : des DALLES minces, grises et froides,
##    lichénées, dont la majorité est COUCHÉE et à demi enterrée.
##
## LA GUEULE DE LA CHAMBRE EST RENFORCÉE (condition du lead) : deux montants
## de 1,46 et 1,24 m et un linteau de 1,97 m de portée qui a GLISSÉ, mordus
## dans le flanc sud du dominant, avec les déblais répandus DEVANT et le
## coffre dedans. Le tas est un ÉVENTAIL OUVERT et le générateur le vérifie
## (zéro sommet dans le quadrant d'accès) : « un coffre au fond d'une chambre
## fermée serait un piège », dit le contrat, et il ne l'est pas.
##
## L'ANCRE DE RÉGION `anchor.r08` EST À 5,66 m (local +4 ; +4). Le tertre
## moyen reste à (+9,0 ; +6,5) : son bord passe à 5,6 m de l'ancre au lieu de
## la recouvrir.
##
## ---------------------------------------------------------------------------
## CORRECTION D3 (arbre intégré du lot 1.R) — LA PIERRE DOMINE LA TERRE
##
## Fait mesuré, et il n'a pu apparaître qu'à l'intégration : le détecteur de
## répétition compare les lieux DEUX À DEUX, et une fois les six lieux
## corrigés réunis, `valley.poi.overlook_summit.01 ≈ valley.poi.
## barrow_cemetery.01` à 30 m — IoU 0,505 contre un seuil de 0,4931 calibré
## sur `ferme abandonnée × pont de pierre`. Les deux aplats noirs lisaient la
## même phrase : « masse dominante à gauche, vide, satellite détaché à
## droite ». Le cimetière portait donc la composition du belvédère et non la
## sienne.
##
## Cause exacte, en cotes : ses verticales ne perçaient pas le ciel. Le
## linteau culminait à 1,92 m SOUS la crête de `Tertre_Grand` (2,15 m), les
## deux stèles du chemin à 1,57 et 0,92 m. Le lieu n'avait donc, en
## silhouette, que des dos — c'est-à-dire la même famille de formes que
## n'importe quelle butte.
##
## Correction, et elle est de COMPOSITION : les six marques dressées prennent
## leur taille de pierres levées, en crescendo le long du chemin d'arrivée,
## et une PIERRE DU SEUIL de 4,33 m se dresse à la tête du dos dominant. Rien
## n'est ajouté dans le vide entre les masses, aucune lame couchée ne bouge,
## aucun autre lieu n'est touché, et le seuil du détecteur n'est pas effleuré.
## Détail et cotes : § CHEMIN et § PIERRE_DE_TETE.
##
## ---------------------------------------------------------------------------
## LOT 1.R.1 — RECONSTRUCTION APRÈS REJET (verdict Codex, inspection réelle)
##
## > « le lieu actuel lit comme des POTEAUX RECTANGULAIRES répartis autour de
## > BOSSES VERTES. Le COFFRE BLEU devient le sujet principal. »
##
## Trois reproches, trois causes distinctes, et aucune n'était un réglage :
##
## 1. LES POTEAUX. Traité dans le GÉNÉRATEUR, pas ici — `dalle()` n'avait
##    qu'un facteur d'amincissement commun aux deux côtés, donc deux arêtes
##    de silhouette structurellement parallèles. Douze pierres de cinq
##    familles les remplacent, avec épaules arrachées, entailles et têtes
##    cassées en biais ; une garde du générateur refuse d'enregistrer une
##    pierre dont le remplissage de silhouette n'est pas nettement sous celui
##    de la forme rejetée.
## 2. LES BOSSES VERTES. Deux causes mesurées : la TEINTE de `TERRE` avait son
##    canal vert dominant, donc celui de l'herbe (§ TERRE) ; et les trois
##    masses étaient dans un rapport de 1 à 0,66 avec des azimuts tenant dans
##    38°, donc « trois bosses » et non « une dominante et ses tombes »
##    (§ TERTRES). S'y ajoutent l'affaissement doublé, la cuvette de tassement
##    et la lisière deux fois plus hachée.
## 3. LE COFFRE SUJET. Sa position ne change pas d'un millimètre : c'est la
##    GUEULE qui vient l'encadrer et la TRANCHÉE qui s'ouvre derrière lui
##    (§ GUEULE, § TRANCHEE). Il passe de « seul au milieu d'une prairie
##    claire » à « au fond d'un renfoncement, entre deux montants, sous un
##    linteau glissé, devant le dos sombre du dominant ».
##
## Et le lieu gagne ce qui lui manquait pour être un LIEU : une ENTRÉE
## (§ SEUIL) et un AXE INCOMPLET qui y mène (§ CHEMIN).
class_name BarrowCemeteryPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")
const PIERRES_SCENE: PackedScene = preload(
	"res://assets/architecture/barrow/SM_Barrow_Stones.glb")

## Terre remuée sous l'herbe rase. Valeur choisie dans la même bande que
## `earth_color` du shader de sol (0,315 / 0,25 / 0,20) et `wet_bed_color`
## (0,24 / 0,26 / 0,23) — deux albédos DÉJÀ mesurés sûrs sur ce monde.
## `scripts/CLAUDE.md` : une couleur de palette n'est pas un albédo, le
## gain de lumière vaut 1,4 à 1,8, et un vert de bible donné tel quel
## ferait des tertres plus clairs que la prairie qui les entoure.
## RECALÉ SUR CAPTURE (apres/barrow_cemetery_joueur.png) : à (0,280 /
## 0,300 / 0,195) les trois dos RENDAIENT 0,41-0,43, c'est-à-dire la MÊME
## valeur que la steppe qui les porte (0,426 mesuré au même pixel près). Un
## tumulus qui a exactement la valeur de son herbe n'est pas une masse : il
## n'existe que par ses facettes, et c'est ce qui donnait la lecture « tente
## de toile ». La cible de la conception était 0,22-0,30 ; à 0,170 l'albédo
## rend ≈ 0,26. Rappel : on juge la valeur RENDUE, jamais l'albédo.
## LOT 1.R, AGENT B — REMONTÉE APRÈS MESURE SUR CAPTURE.
##
## La revue avait posé une réserve en mots : « tumuli très bruns et sombres ».
## Elle est désormais un chiffre : sur `agent_b/it/t2/barrow_cemetery_joueur.png`,
## le flanc éclairé du dos rend **p50 = 69,8** quand l'herbe voisine, mesurée
## dans la même image, rend **113,0** — quarante-trois niveaux d'écart. À cette
## distance, une masse aussi basse ne se lit plus comme de la terre sous
## l'herbe : elle se lit comme une OMBRE.
##
## L'intention ne change pas — un tertre funéraire doit rester PLUS SOMBRE que
## la steppe, et la conception du lieu le dit. Ce qui change est l'ampleur de
## l'écart : on vise ~20-25 niveaux, pas 43.
##
## Le facteur est 1,55 et il est raisonné, pas tâtonné : passer de 69,8 à ~90
## en sortie sRGB demande ×1,29 à l'écran, soit ×1,73 si la chaîne était une
## pure loi de puissance en 2,2. Elle ne l'est pas — le tonemapping comprime le
## haut — d'où une valeur intermédiaire, à REMESURER sur la capture suivante et
## non à déduire. `scripts/CLAUDE.md` : le gain de ce monde vaut 1,4 à 1,8 et
## n'est pas linéaire.
##
## LOT 1.R.1, AGENT C — LA VALEUR RESTE, LA TEINTE CHANGE.
##
## Verdict Codex : « des bosses VERTES ». Il est mesuré, et le chiffre est
## accablant : sur `candidate/ab13/barrow_cemetery_joueur.png`, le flanc
## éclairé du dominant rend **p50 = 108,8** quand l'herbe témoin, hors lieu,
## rend **110,6** — moins de deux niveaux d'écart — et sa teinte moyenne
## (100, 107, 67) est celle de l'herbe (104, 117, 68). Un tumulus qui a la
## valeur ET la teinte de sa prairie n'est pas une masse de terre : c'est de
## l'herbe en relief.
##
## La VALEUR n'est donc pas le levier — elle a déjà été traitée, et la
## consigne est de ne pas la faire régresser. Le levier est la TEINTE : ce
## `Color` a son canal VERT dominant, alors que de la terre remuée a son canal
## ROUGE dominant. On échange donc rouge et vert à **luminance d'albédo
## constante** :
##   ancienne : 0,2126·0,264 + 0,7152·0,287 + 0,0722·0,186 = **0,2748**
##   nouvelle : 0,2126·0,305 + 0,7152·0,272 + 0,0722·0,180 = **0,2724**
## soit 0,9 % d'écart, sous le bruit du tonemapping. Ce qui change est le
## rapport R/V, qui passe de 0,92 à 1,12.
##
## Rappel du piège de `scripts/CLAUDE.md` : le gain de ce monde vaut 1,4 à 1,8
## et n'est PAS linéaire. La luminance d'albédo ne prédit donc pas la
## luminance rendue — elle sert seulement à garantir qu'on ne DÉPLACE pas la
## valeur en changeant la teinte. Le verdict se prend sur la capture.
##
## PASSE C2 — DÉSATURÉE, ET C'EST ENCORE UNE MESURE. Sur `it/c1`, le dos
## éclairé rend une saturation médiane de **0,321** quand l'herbe rend 0,265 et
## quand les SENTIERS DE TERRE du monde gelé rendent **0,091**. Le tertre
## n'était donc plus vert : il était devenu l'objet le plus saturé du cadre,
## et il lisait sable. La luminance d'albédo est de nouveau conservée —
## 0,2126·0,297 + 0,7152·0,272 + 0,0722·0,216 = **0,2732** — et le canal bleu
## remonte de 0,180 à 0,216, ce qui fait tomber la saturation d'albédo de 0,41
## à 0,27 sans toucher ni la valeur ni le rapport R/V (1,09, toujours > 1).
const TERRE: Color = Color(0.297, 0.272, 0.216)

## TEINTES DES PIERRES FUNÉRAIRES — albédos ABSOLUS, à recalibrer ICI et
## nulle part ailleurs, et à juger sur CAPTURE RENDUE (gain non linéaire).
## Cible §1.5 : pierre 0,30-0,42 rendu, GRISE et froide. RECALÉ SUR CAPTURE :
## à 0,505 les dalles rendaient 0,50-0,51 — au-dessus de la steppe (0,426),
## donc du blanc de plastique dans une prairie. À 0,345 elles rendent dans la
## bande visée et se détachent des tertres (0,26) sans crever le ciel.
const TEINTES_PIERRES: Dictionary = {
	"MAT_Barrow_Stone": Color(0.345, 0.352, 0.345),
	"MAT_Barrow_Lichen": Color(0.258, 0.276, 0.222),
}
## Ceintures de blocs au pied des tertres : atlas `Rocks`, gris neutre, sans
## surface `grass` — c'est tout l'intérêt du changement de famille.
const TONE_BLOC: Color = Color(0.72, 0.72, 0.70)

## Chaque tertre : nom, centre local, demi-longueur, demi-largeur, hauteur,
## azimut du grand axe (degrés, dans le plan XZ local), graine.
##
## LES TROIS AZIMUTS SE RESSEMBLENT SANS SE RÉPÉTER (28°, 52°, 14°) : un
## champ funéraire s'aligne — c'est ce qui fait l'inquiétude — mais trois
## masses au même angle se reliraient « instanciées ». Et l'axe moyen est
## à peu près perpendiculaire à la direction d'arrivée (sud-ouest), donc on
## voit les trois DOS par leur longueur, jamais en bout.
## HAUTEURS RELEVÉES (2,10 → 2,45 et 1,35 → 1,55), et pour une raison
## mesurée, pas esthétique : `capture_silhouette.gd` a REFUSÉ d'écrire la
## silhouette du lieu — « le sujet n'occupe que 1,6 % de l'image », sous son
## plancher de 2,0 %. Le lieu fait 24 m de large pour 2 m de haut ; cadré dans
## un format portrait 900 × 1200, il devient un ruban. La version précédente
## passait à 2,05 % avec une emprise de 27,5 × 2,86 m. Le rapport
## hauteur/largeur est donc le paramètre, et c'est le tertre DOMINANT qui doit
## le porter — il est censé dominer. À 2,45 m le rapport revient à 0,101,
## contre 0,104 à la version acceptée.
##
## LOT 1.R.1, AGENT C — HIÉRARCHIE FUNÉRAIRE ET ORIENTATIONS.
##
## Deux reproches du verdict tiennent à cette table, et un seul chiffre les
## résume : 2,15 / 1,42 / 0,80, soit un rapport de 1 à 0,66 entre le dominant
## et le premier secondaire. Deux masses aux deux tiers l'une de l'autre ne
## sont pas « une dominante et des subordonnées » : ce sont trois bosses.
## Et 28° / 52° / 14° tiennent dans 38° — trois masses posées presque dans le
## même sens se relisent instanciées, ce que le contrat §5 refuse
## explicitement (« rythme, pas symétrie »).
##
## Nouvelle table : **2,08 / 1,06 / 0,58**, soit 1 : 0,51 : 0,28 — une
## dominante et deux tombes secondaires ; et **34° / 96° / 152°**, exactement
## 62° d'écart entre voisines — un champ funéraire garde un sens général sans
## que deux tombes soient parallèles.
##
## LE DOMINANT S'ALLONGE ET S'ABAISSE : 5,00 × 3,35 × 2,15 → 5,60 × 3,55 ×
## 2,08. C'est la définition d'« affaissé » en cotes : une tombe qui s'est
## tassée s'étale, elle ne monte pas. La hauteur du LIEU n'en dépend plus —
## elle est portée par la pierre depuis la correction D3 (menhir du seuil), ce
## qui est justement ce qui permet d'abaisser la terre sans perdre la
## silhouette.
##
## EFFET DE BORD VOULU ET CALCULÉ : la jupe du dominant, dans la direction du
## coffre, passe de **2,24 m** (elle s'arrêtait 2,1 m avant lui) à **3,78 m**
## — le coffre est désormais AU PIED du dos, et non plus dans l'herbe plate à
## deux mètres de lui. Il se détache donc sur une masse sombre au lieu d'une
## prairie claire. C'est la moitié de la subordination demandée ; l'autre
## moitié est la gueule, qui vient l'encadrer (§ GUEULE).
##
## LOT 1.R.2 — LA MASSE REPREND LE DESSUS SUR SES PROPRES PIERRES.
##
## Verdict Codex : « aucun tertre ne domine nettement la composition ». La
## cause n'est pas la table des trois masses entre elles — 1 : 0,51 : 0,28
## était déjà une hiérarchie — mais le rapport du dominant AUX PIERRES DU
## LIEU. Sur la vue joueur gelée, le dominant culmine à 2,08 m quand la
## pierre de tête en fait 3,63 et le montant A 2,88 : la terre était la
## troisième masse de son propre cimetière.
##
## Le dominant passe donc à 2,50 m et s'étale à 6,05 × 3,80. Ce n'est pas
## une augmentation disproportionnée et c'est vérifiable : 2,45 m était sa
## cote au lot 1.R, acceptée alors, et l'élargissement suit le tassement déjà
## écrit ici (« une tombe qui s'est tassée s'étale »). Le rapport aux deux
## secondaires — inchangées — passe de 1 : 0,51 : 0,28 à 1 : 0,42 : 0,23,
## donc la subordination demandée se renforce sans qu'aucune tombe secondaire
## ne soit touchée.
const TERTRES: Array[Array] = [
	["Tertre_Grand", -3.30, -0.90, 6.05, 3.80, 2.50, 34.0, 4131],
	["Tertre_Moyen", 9.0, 6.2, 3.05, 2.30, 1.06, 96.0, 9077],
	["Tertre_Petit", 2.4, -8.6, 2.70, 1.50, 0.58, 152.0, 2609],
]

## LA TRANCHÉE D'ACCÈS — creusée dans le flanc sud du dominant, dans l'axe de
## la gueule. C'est elle qui fait qu'on voit une tombe OUVERTE et non une
## butte devant laquelle on a posé deux pierres.
##
## Définie en coordonnées LOCALES XZ et non dans le repère de crête : elle
## doit pointer vers le coffre, dont la position est locale, et un repère
## dérivé de l'azimut aurait fait bouger la tranchée à chaque retouche de
## l'azimut sans que personne le voie.
## [x0, z0, x1, z1, demi_largeur, profondeur]
const TRANCHEE: Array = [-2.85, 0.60, -1.62, 4.05, 1.20, 1.05]

## L'AFFAISSEMENT LARGE — une cuvette molle sur le dos, à l'opposé de la fosse
## de pillage. La fosse est un TROU (on a percé) ; celle-ci est un TASSEMENT
## (la chambre a cédé sous la terre). Deux accidents de natures différentes,
## et c'est leur différence qui raconte l'âge du lieu.
## [u, v, profondeur, rayon_u, rayon_v]
## PASSE 2 : CREUSÉ AVEC LE DOS. À 0,30 m de creux sur un dos de 2,08 m, la
## cuvette valait 14 % de la masse ; sur un dos de 2,50 m elle n'en vaudrait
## plus que 12 %, et sur `it1` le flanc rend une surface LISSE — c'est ce qui
## lui donne encore la lecture « toile tendue ». Le creux suit donc la masse :
## 0,50 m sur 2,50, soit 20 %, et les rayons s'élargissent d'autant.
const AFFAISSEMENT: Array = [-1.70, -0.35, 0.50, 2.90, 2.10]

## LA FOSSE DE PILLAGE, sur le dominant seulement : centre en repère de
## crête (u le long du grand axe, v en travers), profondeur, rayons.
## Profondeur ramenée de 0,80 à 0,62 : le dos est redescendu à 2,15 m et une
## fosse de 0,80 y percerait presque jusqu'au terrain.
## LA FOSSE VA AU BOUT AFFAISSÉ, PAS AU BOUT HAUT — et c'est une mesure, pas
## un goût. Placée à u = −1,20 elle creusait 0,61 m exactement là où la crête
## culmine : le sommet du lieu tombait de 2,45 à 1,84 m, et
## `capture_silhouette.gd` refusait toujours d'écrire (1,8 % contre un
## plancher de 2,0 %). À u = +0,90 elle tombe du côté déjà affaissé — ce qui
## est d'ailleurs plus juste : on ouvre une tombe par où elle s'est tassée.
## PASSE 2 : la fosse suit la masse elle aussi — 0,95 m de creux sur un dos de
## 2,50 m, rayons 1,95 × 1,45. Elle tombe à 514 px sur la vue joueur, en plein
## sur le dos : un TROU d'ombre dans un flanc clair est ce qui distingue une
## tombe éventrée d'une bâche, et c'est aussi ce qui donne au regard une raison
## d'aller au tertre. Le générateur la borne toujours à 5 cm au-dessus du
## terrain : elle ne peut pas percer.
##
## PASSE 3 — LA FOSSE CHANGE DE PLACE, PARCE QU'ON NE LA VOYAIT PAS.
##
## C'est un changement de DISPOSITION, pas un réglage de plus : deux passes
## avaient creusé le dos sans que rien n'apparaisse dans le cadre, et la
## raison n'était pas la profondeur. À u = +0,90 la fosse tombe à 515 px —
## exactement derrière la pierre penchée du chemin. On creusait un trou
## d'un mètre derrière un obstacle.
##
## Elle passe à u = −1,35, v = +0,24, soit 400 px : la seule bande du dos qui
## reste dégagée dans la vue joueur, entre le montant du seuil (232 px) et les
## pierres du centre (450+). Un tertre a besoin d'un ACCIDENT pour se lire
## comme une tombe et non comme une toile tendue, et c'est aussi ce qui donne
## au regard une raison d'aller à la masse plutôt qu'au coffre.
##
## CE QUE ÇA COÛTE, ET C'EST BORNÉ : à u = −1,35 la crête locale vaut 2,31 m
## au lieu de 2,50, donc la fosse descend à 1,36 m. Le point haut du lieu reste
## au bout de crête (u = −2,78 ; 2,50 m), il n'est pas touché — c'est
## précisément ce que la note « la fosse va au bout affaissé » cherchait à
## protéger, et le contrôle vaut mieux ici que la règle recopiée.
const FOSSE: Array = [-1.35, 0.24, 0.95, 1.95, 1.45]

static var _cache_pierres: Dictionary = {}


func default_place_id() -> StringName:
	return &"valley.poi.barrow_cemetery.01"


func _build() -> void:
	# L'exemption revendiquée dans l'en-tête, RÉELLEMENT posée — mesuré le
	# 2026-08-23 : revendiquée en prose mais jamais câblée, elle n'exemptait
	# rien, et D1a rendait 55,7 % d'aire runtime sur ce lieu. Le titre de
	# l'exemption est vérifié dans `_tertre()` : chaque sommet appelle
	# `ground_local_y(x, z)` — un gonflement du terrain gelé ne peut pas être
	# un GLB, même famille que `SolBrule`. Le reprofilage du lot 1.R ne change
	# NI les noms des trois nœuds NI cette méthode : l'exemption reste
	# exactement celle qui a été calibrée.
	set_meta(&"exemption_runtime", PackedStringArray(
		["Tertre_Grand", "Tertre_Moyen", "Tertre_Petit"]))
	for spec: Array in TERTRES:
		var dominant: bool = String(spec[0]) == "Tertre_Grand"
		_tertre(String(spec[0]), float(spec[1]), float(spec[2]),
			float(spec[3]), float(spec[4]), float(spec[5]),
			float(spec[6]), int(spec[7]),
			FOSSE if dominant else [],
			TRANCHEE if dominant else [],
			AFFAISSEMENT if dominant else [])
	_ceintures()
	_gueule_de_chambre()
	_enceinte_du_coffre()
	_chemin_des_morts()
	_steppe()
	_collisions()

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Cimetière du tertre"
	poi.region = &"r08_steppe_du_nord"
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Decouverte_forme"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 18.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	# Le layout dit « coffre — hache lourde », et c'est le `kind` de
	# l'ancrage qui décide de la forme : `CHEST` donne bien un coffre dont
	# `DiscoveryRewards` remplit le `weapon_loot` depuis sa table. Il est
	# posé DANS LES DÉBLAIS, devant la gueule : les pilleurs l'ont laissé là.
	# Position inchangée depuis la version validée — le tas s'organise autour
	# d'elle, pas l'inverse.
	# POSITION, GENRE, IDENTIFIANT ET APPROCHE INCHANGÉS. `ANCRE_COFFRE` vaut
	# exactement (−1,5 ; 4,3) : le littéral devient une constante pour que
	# l'enceinte se calcule depuis lui, pas pour le déplacer.
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.CHEST,
		_seated(ANCRE_COFFRE.x, ANCRE_COFFRE.y) + Vector3(0.0, 0.1, 0.0),
		Vector3(0.4, 0.0, 7.4))
	# HABILLAGE LOCAL DU COFFRE (autorisé par le lead, lot 1.R). Le coffre est
	# posé par `DiscoveryRewards.furnish()`, APRÈS que tous les lieux soient
	# bâtis : il n'existe pas encore ici. On s'abonne donc à son arrivée.
	var ancre: Node = get_node_or_null("AncrageRecompense")
	if ancre != null:
		ancre.child_entered_tree.connect(_sur_recompense)


## LE COFFRE EST LE SEUL OBJET DU CADRE QUI N'APPARTIENNE À AUCUNE MATIÈRE DU
## MONDE — mesuré par l'audit : l'élément le plus clair ET le plus saturé de
## l'image, orange et bleu-gris dans une steppe olive. Le MODÈLE vient d'une
## ressource partagée (`res://scenes/interactables/Chest.tscn`) qu'un lieu n'a
## pas le droit de remplacer ; il part en ticket. Ce qu'on peut faire ici, et
## que le lead a explicitement autorisé, c'est la technique déjà employée pour
## les pierres : un habillage PAR SURFACE sur des matériaux DUPLIQUÉS, sur
## cette instance seulement, sans jamais muter la ressource partagée.
##
## Ce qui NE bouge pas : la récompense, son ancre, son identifiant, la logique
## d'octroi, et la lisibilité — un coffre doit rester un coffre ouvrable, donc
## on désature et on assombrit, on ne repeint pas.
func _sur_recompense(noeud: Node) -> void:
	if noeud.is_node_ready():
		_habiller_recompense(noeud)
	else:
		noeud.ready.connect(_habiller_recompense.bind(noeud),
			CONNECT_ONE_SHOT)


## Désaturation de 55 % vers le gris de sa propre luminance, puis 22 %
## d'assombrissement, et la rugosité painterly du lieu. Le contraste
## bois/ferrure du coffre SURVIT (c'est un rapport, pas une valeur absolue) ;
## seul l'écart au reste du cadre diminue.
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
			# MESURÉ APRÈS LA PREMIÈRE PASSE : les planches sont passées de
			# 0,520 à 0,387 de luminance — le coffre a cessé d'être l'objet le
			# plus clair du cadre (steppe 0,409) — mais leur SATURATION n'a pas
			# bougé (0,25). La raison est mécanique : ce matériau porte une
			# TEXTURE, son `albedo_color` est donc quasi blanc, et désaturer du
			# blanc ne fait rien. Seul le facteur multiplicatif agit sur une
			# texture. On refroidit donc en plus d'assombrir, pour ramener le
			# coffre vers la palette minérale du lieu sans toucher la carte.
			# LOT 1.R.1 — l'habillage est POUSSÉ, mais il reste le levier
			# secondaire, et il faut le dire. Mesuré sur
			# `candidate/ab13/barrow_cemetery_joueur.png` : le coffre porte
			# une saturation médiane de 0,193, INFÉRIEURE à celle de l'herbe
			# (0,265). Ce n'est donc pas sa couleur qui le fait sujet — c'est
			# sa LUMINANCE HAUTE (p90 = 122,5, la plus élevée du lieu après le
			# menhir) et son contraste interne (p50 69 → p95 143), dans un
			# cadre où tout le reste est mat. On désature un peu plus et on
			# assombrit franchement pour rentrer sa pointe claire ; le vrai
			# travail est fait par la gueule qui l'encadre et par le dos
			# sombre du tertre derrière lui.
			mat.albedo_color = Color(
				lerpf(c.r, gris, 0.66) * 0.60,
				lerpf(c.g, gris, 0.66) * 0.63,
				lerpf(c.b, gris, 0.66) * 0.69, c.a)
			mat.roughness = maxf(mat.roughness, 0.94)
			mat.metallic_specular = 0.1
			# `material_override` PRIME sur les surcharges de surface : si le
			# coffre en porte un, écrire une surcharge de surface ne ferait
			# RIEN, en silence. On écrit alors au bon endroit.
			if instance.material_override != null:
				instance.material_override = mat
			else:
				instance.set_surface_override_material(surface, mat)


## UN TERTRE — un DOS cousu au terrain gelé, sommet par sommet.
##
## CE QUI A CHANGÉ, ET POURQUOI CE N'EST PAS UN RÉGLAGE. L'ancien profil
## était un dôme de révolution : rayon bruité par secteur, profil `cos^1,4`,
## et un SOMMET UNIQUE. Ce sommet unique est la définition d'un cône ; aucun
## bruit de rayon ne l'enlève, et c'est ce que le gate a vu.
##
## Ici l'anneau intérieur ne se referme pas sur un point mais sur une CRÊTE :
## un segment orienté selon `azimut`, sur lequel les 40 secteurs se
## répartissent par `cos θ`. Le tertre a donc une longueur et une largeur
## distinctes, un dos, et deux bouts qui ne se ressemblent pas.
##
## Trois dissymétries s'ajoutent, chacune nommée :
##   * l'AFFAISSEMENT — la crête est plus basse d'un quart à l'une de ses
##     extrémités (`0,74 + 0,26·…`), donc le dos penche ;
##   * la LISIÈRE IRRÉGULIÈRE — demi-longueur et demi-largeur sont hachées
##     par secteur puis lissées sur trois voisins, la recette anti-« étoile »
##     que l'arbre foudroyé a payée d'une revue (deux sinus purs donnent cinq
##     lobes réguliers ; un hachage lissé n'a plus de période) ;
##   * la FOSSE DE PILLAGE, sur le dominant seulement, creusée en gaussienne
##     dans le repère de la crête et bornée à 5 cm au-dessus du terrain — une
##     fosse qui passerait sous le sol y disparaîtrait en z-fighting.
##
## Le profil garde sa tangente HORIZONTALE aux deux bouts : le dos ne fait ni
## arête au sommet ni marche à la lisière, et c'est l'arête de lisière qui
## trahirait une capsule posée sur l'herbe.
func _tertre(nom: String, cx: float, cz: float, demi_long: float,
		demi_large: float, hauteur: float, azimut: float, graine: int,
		fosse: Array, tranchee: Array = [], affaissement: Array = []) -> void:
	# RECALÉ SUR CAPTURE (apres/barrow_gp_gueule.png) : à 40 secteurs, CINQ
	# anneaux et une crête large de 0,10·demi_large, la surface passait d'une
	# ellipse de 5,5 m de long et 0,6 m de large à l'anneau suivant en un seul
	# bond — deux panneaux plans et une arête vive, c'est-à-dire une TENTE DE
	# TOILE. La géométrie disait « cône » sous un autre nom.
	# Trois corrections, et chacune vise cette lecture :
	#   * NEUF anneaux au lieu de cinq, resserrés près de la crête ;
	#   * la crête est une petite ELLIPSE (0,34·L × 0,26·l) et non un fil : la
	#     transition n'a plus de saut à combler ;
	#   * un RELIEF de flanc, nul à la crête ET nul à la lisière, maximal à
	#     mi-pente — il bombe et creuse les panneaux sans toucher ni le dos ni
	#     le raccord au terrain, qui sont les deux endroits où une irrégularité
	#     se verrait comme un défaut.
	var secteurs: int = 48
	var anneaux: Array[float] = [0.0, 0.13, 0.26, 0.39, 0.52, 0.65, 0.78,
		0.90, 1.0]
	var a_rad: float = deg_to_rad(azimut)
	var e: Vector2 = Vector2(cos(a_rad), sin(a_rad))
	var f: Vector2 = Vector2(-e.y, e.x)
	## Le demi-segment de crête : c'est LUI qui fait le « dos long ». Au-delà
	## de ses deux bouts la masse se referme en calotte, comme un pain.
	## 0,46 et non 0,40, et l'affaissement s'adoucit de 0,74 à 0,85 : à
	## 2,60 m de haut — cote imposée par le plancher de l'outil de silhouette
	## — la crête courte et fortement affaissée redonnait une BOSSE à un bout
	## et une arête (`apres4/barrow_gp_gueule.png`). Une crête plus longue et
	## plus égale rend le même point haut, donc la même silhouette mesurée,
	## mais un DOS et non une tente. Le rapport hauteur/demi-largeur descend
	## de 0,84 à 0,78 avec l'élargissement ci-dessus.
	var demi_axe: float = demi_long * 0.46

	# Hachage de lisière, lissé sur trois voisins — un par axe.
	var brut_l: PackedFloat32Array = PackedFloat32Array()
	var brut_t: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(secteurs):
		brut_l.append(_alea(float(i) * 1.9 + float(graine) * 0.013))
		brut_t.append(_alea(float(i) * 2.7 + float(graine) * 0.021 + 5.0))
	var rayons_l: PackedFloat32Array = PackedFloat32Array()
	var rayons_t: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(secteurs):
		var lisse_l: float = (brut_l[(i - 1 + secteurs) % secteurs] + brut_l[i]
			+ brut_l[(i + 1) % secteurs]) / 3.0
		var lisse_t: float = (brut_t[(i - 1 + secteurs) % secteurs] + brut_t[i]
			+ brut_t[(i + 1) % secteurs]) / 3.0
		# HACHAGE DE LISIÈRE RELEVÉ (0,22 → 0,34 en long, 0,30 → 0,44 en
		# travers) — lot 1.R.1. Une jupe quasi elliptique se lit « primitive
		# posée » ; c'est le second membre du reproche « bosses ». Le lissage
		# sur trois voisins est conservé tel quel : c'est lui qui empêche le
		# retour des cinq lobes réguliers que l'arbre foudroyé avait payés
		# d'une revue.
		rayons_l.append(demi_long * (0.84 + 0.34 * lisse_l))
		rayons_t.append(demi_large * (0.78 + 0.44 * lisse_t))

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grilles: Array[PackedVector3Array] = []
	var valeurs: Array[PackedFloat32Array] = []
	for anneau: float in anneaux:
		var points: PackedVector3Array = PackedVector3Array()
		var tons: PackedFloat32Array = PackedFloat32Array()
		for i: int in range(secteurs):
			var angle: float = TAU * float(i) / float(secteurs)
			# La CRÊTE : un segment, pas un point. Le petit terme en `f`
			# évite l'anneau dégénéré (deux secteurs opposés tomberaient
			# exactement au même endroit et coûteraient des triangles d'aire
			# nulle — le défaut que `tools/cave_check_mesh.py` ne voit pas).
			var crete: Vector2 = Vector2(cx, cz) \
				+ e * (demi_axe * cos(angle)) \
				+ f * (demi_large * 0.26 * sin(angle))
			var bord: Vector2 = Vector2(cx, cz) \
				+ e * (rayons_l[i] * cos(angle)) \
				+ f * (rayons_t[i] * sin(angle))
			var p: Vector2 = crete.lerp(bord, anneau)
			# LA HAUTEUR NE SUIT PLUS L'INDICE D'ANNEAU, ET C'EST LA
			# CORRECTION DE FOND. Tant qu'elle le suivait, tous les points de
			# l'anneau 0 étaient à la même cote quelle que soit leur position :
			# un PLATEAU fermé par une arête au premier anneau suivant,
			# c'est-à-dire une ARÊTE FAÎTIÈRE, et un tumulus n'en a pas
			# (troisième signalement de l'audit : « des tentes de papier
			# plié »). Elle suit maintenant la DISTANCE GÉOMÉTRIQUE au segment
			# de crête, normalisée par le rayon local. Le profil `cos^1,25` a
			# une tangente HORIZONTALE en zéro : le dessus est donc rond EN
			# TRAVERS comme un pain, et il n'y a plus d'arête nulle part.
			var d: Vector2 = p - Vector2(cx, cz)
			var u: float = d.dot(e)
			var v: float = d.dot(f)
			var bosse: float = (0.50 * sin(u * 0.83 + 1.30)
				+ 0.34 * sin(v * 1.31 - 0.70)
				+ 0.24 * sin(u * 0.51 + v * 0.77 + 2.10))
			var u_serre: float = clampf(u, -demi_axe, demi_axe)
			var dn: float = sqrt(
				pow((u - u_serre) / maxf(0.35, rayons_l[i] - demi_axe), 2.0)
				+ pow(v / maxf(0.35, rayons_t[i]), 2.0))
			dn = clampf(dn, 0.0, 1.0)
			# AFFAISSEMENT : la crête est plus basse à l'une de ses extrémités.
			# AMPLITUDE DOUBLÉE au lot 1.R.1, et c'est une mesure, pas un
			# goût : 0,15 ne produisait que 15 % d'écart entre les deux bouts
			# du dos, soit 32 cm sur 2,15 m. À quinze mètres, 32 cm de
			# différence entre deux bouts d'une masse de six mètres ne se
			# voient pas — le dos se relisait SYMÉTRIQUE, donc « une bosse ».
			# À 0,30 l'écart passe à 62 cm et la tombe penche vraiment.
			var s_crete: float = clampf(u / maxf(0.35, demi_axe), -1.0, 1.0)
			var h_crete: float = hauteur \
				* (0.70 + 0.30 * (0.5 - 0.5 * s_crete))
			# DEUX FLANCS QUI NE SE RESSEMBLENT PAS (passe C3). L'exposant du
			# profil était 1,25 dans TOUTES les directions : le dos était donc
			# un solide de révolution déformé, et son ombre propre restait
			# symétrique — d'où la lecture « dune » ou « tente » qui a survécu
			# à C1 et à C2 malgré l'affaissement de crête et le relief de
			# flanc. Un tumulus qui s'est tassé a un côté ÉBOULÉ, en pente
			# courte, et un côté ÉTALÉ, en longue rampe.
			# L'exposant suit donc `v`, la coordonnée en travers de la crête :
			# sous 1 il gonfle le flanc (pente raide au pied), au-dessus il
			# l'aplatit (longue rampe). Bornes serrées pour que le raccord au
			# terrain reste tangent aux deux extrémités.
			var pente: float = clampf(
				1.25 + 0.62 * (v / maxf(0.35, rayons_t[i])), 0.72, 2.05)
			var releve: float = h_crete \
				* pow(maxf(cos(dn * PI * 0.5), 0.0), pente)
			# LE RELIEF DE FLANC — ET IL N'EST PLUS RADIAL, ce qui était la
			# cause du « papier plié ». Première version : un multiplicateur
			# par SECTEUR, constant du dos à la lisière. Quarante-huit
			# secteurs, chacun un peu différent de son voisin, cela ne fait
			# pas des bosses : cela fait quarante-huit PLIS rayonnants, et
			# c'est exactement ce que la capture a montré.
			# Ici le relief est un champ LISSE en (u, v) — trois sinus de
			# fréquences non commensurables dans le plan du tertre — donc il
			# n'a plus aucune structure angulaire. `sin(π·dn)` l'annule au dos
			# ET à la lisière : le dessus reste rond et le bord reste cousu.
			# AMPLITUDE RELEVÉE 0,115 → 0,17 (passe C2) : sur `it/c1` le dos
			# rend une surface lisse et continue — le défaut « papier plié »
			# est bien mort, mais ce qui l'a remplacé est une DUNE. Une tombe
			# de terre affaissée a des creux et des bosses ; 11 % de modulation
			# à quinze mètres ne se voient pas.
			releve *= 1.0 + 0.17 * bosse * sin(dn * PI)
			if not fosse.is_empty():
				var du: float = (u - float(fosse[0])) / float(fosse[3])
				var dv: float = (v - float(fosse[1])) / float(fosse[4])
				releve -= float(fosse[2]) * exp(-(du * du + dv * dv))
			# L'AFFAISSEMENT LARGE — une cuvette molle, pas un trou. Elle est
			# posée à l'AUTRE bout du dos que la fosse de pillage : deux
			# accidents de natures différentes, et c'est leur différence qui
			# raconte l'âge du lieu. Rayons trois fois ceux de la fosse pour
			# une profondeur deux fois moindre.
			if not affaissement.is_empty():
				var au: float = (u - float(affaissement[0])) \
					/ float(affaissement[3])
				var av: float = (v - float(affaissement[1])) \
					/ float(affaissement[4])
				releve -= float(affaissement[2]) * exp(-(au * au + av * av))
			# LA TRANCHÉE D'ACCÈS, en coordonnées LOCALES XZ. Distance du point
			# au segment, gaussienne en travers, fondu aux deux bouts pour que
			# la coupe ne s'arrête pas sur une marche.
			if not tranchee.is_empty():
				releve -= _creux_de_tranchee(p, tranchee)
			releve = maxf(releve, 0.04 if anneau < 0.98 else 0.0)
			points.append(Vector3(p.x, ground_local_y(p.x, p.y) + releve, p.y))
			# La couronne est plus TERREUSE (0,86), la lisière rejoint
			# l'herbe (1,08) : c'est le dégradé qui fait fondre le bord.
			# LA TEINTE AUSSI CESSE D'ÊTRE RADIALE, et c'est le dernier
			# morceau du « papier plié ». La géométrie était corrigée, mais
			# `_alea(i·3,7 + …)` donnait à CHAQUE SECTEUR sa propre valeur :
			# quarante-huit rubans verticaux du dos à la lisière, visibles sur
			# `apres3/barrow_gp_gueule.png` alors que la forme, elle, était
			# devenue ronde. On réemploie le champ lisse en (u, v).
			tons.append(lerpf(0.86, 1.08, anneau) + 0.055 * bosse)
		points.append(points[0])
		tons.append(tons[0])
		grilles.append(points)
		valeurs.append(tons)

	# L'ENROULEMENT est celui de `SolBrule` et de `rock_floor_mesh` — à angle
	# croissant — parce que c'est l'enroulement d'une surface tournée VERS LE
	# HAUT qui a déjà été validée sur ce moteur. Il n'y a plus d'éventail de
	# sommet : l'anneau 0 est une crête, et il est cousu comme les autres.
	var normales: Array[PackedVector3Array] = _normales_de_grille(grilles)
	for anneau_index: int in range(anneaux.size() - 1):
		var bas: PackedVector3Array = grilles[anneau_index + 1]
		var haut: PackedVector3Array = grilles[anneau_index]
		var t_bas: PackedFloat32Array = valeurs[anneau_index + 1]
		var t_haut: PackedFloat32Array = valeurs[anneau_index]
		var n_bas: PackedVector3Array = normales[anneau_index + 1]
		var n_haut: PackedVector3Array = normales[anneau_index]
		for i: int in range(secteurs):
			_triangle_degrade(st, haut[i], bas[i], bas[i + 1],
				t_haut[i], t_bas[i], t_bas[i + 1],
				n_haut[i], n_bas[i], n_bas[i + 1])
			_triangle_degrade(st, haut[i], bas[i + 1], haut[i + 1],
				t_haut[i], t_bas[i + 1], t_haut[i + 1],
				n_haut[i], n_bas[i + 1], n_haut[i + 1])
	# La crête elle-même se ferme en éventail sur son MILIEU — pas sur un
	# sommet du dôme : ce point est au niveau de la crête, pas au-dessus.
	var milieu: Vector3 = Vector3(cx, 0.0, cz)
	var somme: float = 0.0
	for i: int in range(secteurs):
		milieu += grilles[0][i]
		somme += 1.0
	milieu = (milieu - Vector3(cx, 0.0, cz)) / somme
	# La normale du point de fermeture est la MOYENNE de celles de la crête :
	# sans elle, l'éventail central retrouverait l'ombrage plat qu'on vient de
	# retirer au reste du dos, et la crête porterait une étoile de facettes —
	# exactement à l'endroit le plus regardé du tertre.
	var n_milieu: Vector3 = Vector3.ZERO
	for i: int in range(secteurs):
		n_milieu += normales[0][i]
	n_milieu = n_milieu.normalized() if n_milieu.length_squared() > 1e-8 \
		else Vector3.UP
	for i: int in range(secteurs):
		_triangle_degrade(st, milieu, grilles[0][i], grilles[0][i + 1],
			0.86, 0.86, 0.86,
			n_milieu, normales[0][i], normales[0][i + 1])

	var dome: MeshInstance3D = MeshInstance3D.new()
	dome.name = nom
	dome.mesh = st.commit()
	var terre: StandardMaterial3D = K.flat_material(TERRE)
	terre.vertex_color_use_as_albedo = true
	dome.mesh.surface_set_material(0, terre)
	add_child(dome)
	declare_support(_seated(cx, cz))


## LE CREUX DE LA TRANCHÉE en un point local (x, z).
##
## Distance du point au SEGMENT (pas à la droite : une droite creuserait le
## tertre de part en part, y compris derrière la crête, et on verrait la butte
## fendue en deux au lieu d'ouverte d'un côté). Profil gaussien en travers,
## fondu linéaire sur les deux derniers quarts de la longueur.
func _creux_de_tranchee(p: Vector2, spec: Array) -> float:
	var a: Vector2 = Vector2(float(spec[0]), float(spec[1]))
	var b: Vector2 = Vector2(float(spec[2]), float(spec[3]))
	var ab: Vector2 = b - a
	var long2: float = maxf(1e-4, ab.length_squared())
	var t: float = clampf((p - a).dot(ab) / long2, 0.0, 1.0)
	var d: float = (p - (a + ab * t)).length() / maxf(0.05, float(spec[4]))
	# Fondu aux extrémités : plein entre 20 % et 80 % de la longueur.
	var bout: float = clampf(t / 0.20, 0.0, 1.0) \
		* clampf((1.0 - t) / 0.20, 0.0, 1.0)
	return float(spec[5]) * bout * exp(-(d * d))


## LES CEINTURES — blocs demi-enterrés au PIED de chaque tertre. Ce sont
## elles qui empêchent le dos de se lire comme une primitive : un tumulus est
## ceint de blocs, et l'œil accroche la pierre avant la terre.
##
## FAMILLE CHANGÉE au lot 1.R : `rock_largeA/C` portent DEUX matériaux au
## glTF, `dirt` et **`grass`**, et la surface « grass » des kits Kenney rend
## menthe/sarcelle sous cette lumière — ce sont les « chapeaux turquoise »
## mesurés sur la capture d'avant. `Rock_Medium_1/2/3` (atlas `Rocks`) n'ont
## qu'un seul matériau et rendent gris neutre. Même correction que le caillou
## de pied de la tour de guet, même cause, même remède.
##
## Pas d'espacement régulier : trois blocs sur le grand, deux sur le moyen,
## un sur le petit, à des azimuts qui ne se répondent pas.
func _ceintures() -> void:
	# RAYONS RECALÉS SUR LES NOUVELLES COTES (lot 1.R.1). Ce ne sont pas des
	# constantes esthétiques : chacun est l'extension de l'ellipse du tertre
	# DANS SON AZIMUT, calculée depuis `TERTRES`. Les laisser à leur ancienne
	# valeur aurait posé trois blocs en l'air ou trois blocs sur le dos — un
	# défaut que la capture montre mal et qu'aucun test ne voit.
	var pierres: Array[Array] = [
		# RECALÉS SUR L'ELLIPSE DU LOT 1.R.2 (6,05 × 3,80). Le rayon d'une
		# ellipse dans une direction donnée vaut
		# `1 / sqrt((cos/a)² + (sin/b)²)` avec l'angle pris DANS le repère du
		# tertre (azimut de la ceinture − 34°) ; les trois valeurs suivent
		# donc l'agrandissement au lieu de laisser trois blocs sur le dos.
		[-3.30, -0.90, 5.72, 202.0, &"Rock_Medium_1", 0.42],
		[-3.30, -0.90, 3.85, 300.0, &"Rock_Medium_3", 0.34],
		[-3.30, -0.90, 3.69, 118.0, &"Rock_Medium_2", 0.28],
		[9.0, 6.2, 2.90, 41.0, &"Rock_Medium_2", 0.30],
		[9.0, 6.2, 2.40, 236.0, &"Rock_Medium_1", 0.22],
		[2.4, -8.6, 1.70, 154.0, &"Rock_Medium_3", 0.20],
	]
	for spec: Array in pierres:
		var azimut: float = deg_to_rad(float(spec[3]))
		var x: float = float(spec[0]) + cos(azimut) * float(spec[2])
		var z: float = float(spec[1]) + sin(azimut) * float(spec[2])
		var at: Vector3 = _seated(x, z)
		K.module(self, spec[4] as StringName, at + Vector3(0.0, -0.16, 0.0),
			float(spec[3]) * 0.7, float(spec[5]), TONE_BLOC)
		declare_support(at)


## LA GUEULE DE LA CHAMBRE — le grand tertre a été OUVERT.
##
## C'est l'élément héroïque du lieu et la raison d'être de la hache : deux
## montants inégaux (1,46 et 1,24 m), un linteau de 1,97 m qui a GLISSÉ de
## son appui, et les déblais répandus devant. Une couverture d'aplomb se lit
## maçonnée ; une couverture descellée se lit rouverte.
##
## La gueule mord le flanc SUD du dominant, c'est-à-dire le flanc par lequel
## on arrive (les deux caméras du plan et le parcours joueur viennent du
## sud-ouest). Elle est donc lisible à 5-15 m, condition du lead.
##
## LES DÉBLAIS SONT OUVERTS, et pas seulement par intention : le générateur
## refuse d'enregistrer si un seul sommet entre dans le quadrant d'accès. Le
## tas est posé en lacet 180° pour que ce quadrant regarde le sud — d'où l'on
## vient, et vers où l'on repart.
## ---------------------------------------------------------------------------
## LOT 1.R.1 — LA GUEULE VIENT AU COFFRE, ET NON L'INVERSE
##
## Verdict : « le coffre bleu devient le sujet principal ». La cause n'était
## pas sa couleur — elle est déjà désaturée et assombrie ici — mais sa
## POSITION dans la composition : il était seul, en pleine lumière, sur
## l'herbe, à deux mètres devant une gueule qui le doublait au lieu de
## l'encadrer. Calculé sur les anciennes cotes : la jupe du dominant
## s'arrêtait à (−2,21 ; 2,24) et l'ancre est à (−1,5 ; 4,3) — 2,2 m de
## prairie plate entre les deux.
##
## L'ANCRE NE BOUGE PAS D'UN MILLIMÈTRE. Ni sa position locale, ni son
## approche, ni son genre, ni son identifiant, ni sa table de butin. Ce qui
## bouge, c'est la GUEULE : les deux montants passent de part et d'autre de
## l'ancre (à 1,15 et 1,10 m d'elle), le linteau glissé passe au-dessus, et la
## tranchée d'accès est creusée dans le flanc derrière. Le coffre se trouve
## donc DANS le renfoncement, sur trois plans successifs — montant, coffre,
## montant — et devant le dos sombre du tertre au lieu de la prairie claire.
##
## Ce que cela coûte, et c'est nommé : le linteau n'a PLUS de collider. Il est
## à 2,20 m d'appui et son extrémité glissée descend vers 1,90 m ; un corps à
## cette cote serait exactement le « mur invisible qu'on sent sans le voir »
## que ce fichier refuse déjà pour les lames et les têtes de stèles — et il
## serait posé au-dessus de la récompense, c'est-à-dire à l'endroit le plus
## coûteux du lieu. Les deux montants, eux, gardent chacun leur boîte.
func _gueule_de_chambre() -> void:
	# Les deux montants encadrent l'ancre de récompense (−1,5 ; +4,3).
	var a: Vector3 = _seated(-2.62, 4.02)
	_piece_pierre("SM_Barrow_Jamb_A", a,
		Vector3(0.0, deg_to_rad(26.0), deg_to_rad(6.0)), "", 1.06)
	declare_support(a)
	var b: Vector3 = _seated(-0.46, 4.46)
	_piece_pierre("SM_Barrow_Jamb_B", b,
		Vector3(0.0, deg_to_rad(-18.0), deg_to_rad(-8.0)), "", 0.94)
	declare_support(b)
	# LE LINTEAU. Son origine est à UNE EXTRÉMITÉ (dans le GLB, Y court de
	# −1,98 à 0,02, donc en Godot la pièce s'étend de z ≈ 0 à z ≈ +1,98 depuis
	# son origine). Il est donc posé sur le montant A et non au milieu, et son
	# lacet est celui de la droite A→B : direction (0,980 ; 0,199), soit 78,5°.
	#
	# LE LINTEAU EST TOMBÉ — CHANGEMENT D'HYPOTHÈSE, PAS DE CONSTANTE (passe C3).
	#
	# Deux tentatives de le faire PORTER ont échoué de la même manière : sur
	# `it/c1` (appui 2,20 m, dévers −9°) et sur `it/c2` (appui 2,50 m, dévers
	# +14,4°, recalculé sur les arases réelles), la capture `barrow_gp_gueule`
	# montre toujours une barre suspendue à ~0,26 m au-dessus des deux
	# montants. La règle du dépôt est explicite : deux échecs sur la même
	# hypothèse, on cesse de régler des constantes.
	#
	# Le geste change donc de nature. Une couverture qu'on est venu forcer ne
	# reste pas en équilibre : elle est par terre. Le linteau part du SOL, à
	# 1,26 m à l'ouest du montant A, et s'appuie contre son flanc à mi-hauteur.
	# Un bout au sol ne peut pas flotter — la faute est structurellement
	# impossible — et le ciel se dégage au-dessus du coffre, qui reste encadré
	# par les deux montants seuls.
	#
	# Cotes : course horizontale 1,26 m pour une pièce de 1,98 m, donc
	# `cos θ = 0,636` et θ = 50,5° ; le haut arrive à 1,53 m contre un montant
	# de 2,63 m. Lacet : la direction (0,579 ; −0,817) donne 144,6°.
	# LE SIGNE DU TANGAGE EST MESURÉ, PAS SUPPOSÉ : sur `it/c2`, `+14,4°`
	# abaisse visiblement le bout lointain ; il faut donc **−50,5°** pour le
	# relever.
	_piece_pierre("SM_Barrow_Lintel", _seated(-3.35, 5.05),
		Vector3(deg_to_rad(-50.5), deg_to_rad(144.6), deg_to_rad(7.0)),
		"", 1.02)
	# LES DÉBLAIS — trois tas, et leur rôle a changé. Ils ne « bercent » plus le
	# coffre depuis le fond : ils forment maintenant deux BANQUETTES latérales
	# le long de la tranchée et un bourrelet DEVANT, entre la caméra joueur et
	# le coffre. C'est ce bourrelet qui coupe le bas du coffre — un objet dont
	# on ne voit pas la base cesse d'être le premier plan.
	# Lacet 180° : dans le GLB le quadrant libre regarde Blender +y, donc
	# Godot −z ; il faut qu'il regarde +z, le sud, d'où l'on arrive.
	var tas: Vector3 = _seated(-1.55, 5.30)
	var grand: Node3D = _piece_pierre("SM_Barrow_Deblais", tas,
		Vector3(0.0, deg_to_rad(180.0), 0.0), "Deblais_grand", 0.88)
	# PASSE 3 : le bourrelet grossit. Sur `it2` il coupe déjà le bas du coffre,
	# et l'effet est visible ; il ne va simplement pas assez haut. Un objet dont
	# on ne voit ni la base ni le tiers inférieur de la face cesse d'être un
	# premier plan — c'est le seul levier d'ENVIRONNEMENT qui reste une fois la
	# gueule et le dos sombre en place, et il ne touche ni la couleur du coffre
	# ni sa logique.
	grand.scale = Vector3(1.70, 1.55, 1.35)
	declare_support(tas)
	var tas_b: Node3D = _piece_pierre("SM_Barrow_Deblais",
		_seated(-3.10, 4.55), Vector3(0.0, deg_to_rad(232.0), 0.0),
		"Deblais_petit", 0.90)
	tas_b.scale = Vector3(1.15, 0.95, 1.05)
	# Deux poignées d'éclats serrées contre les montants : la terre sortie de
	# la tranchée, jetée sur les bords.
	# ÉCHELLES RÉDUITES (passe C2) : à 0,46 et 0,36 elles produisaient, autour
	# du coffre, un semis d'éclats anguleux gris qui lit « bris de poterie » et
	# non « tas de déblais ». Un tas se lit à sa MASSE, pas au nombre de ses
	# arêtes. Elles reculent aussi de 20 cm pour dégager le pied du coffre.
	# UNE SEULE poignée d'éclats (passe C3). À deux, elles bordaient le coffre
	# des deux côtés et l'entouraient d'un semis d'arêtes grises qui lit « bris
	# de poterie ». Un tas de déblais se lit à sa masse ; ce qui restait était
	# du bruit, et le bruit vole la lecture aux montants.
	var eclat: Node3D = _piece_pierre("SM_Barrow_Deblais",
		_seated(-2.72, 4.90), Vector3(0.0, deg_to_rad(62.0), 0.0),
		"Deblais_pied", 0.86)
	eclat.scale = Vector3.ONE * 0.40


## LE CHEMIN DES MORTS — la séquence qui fait la composition A.
##
## Depuis l'arrivée au sud-ouest : lame couchée → stèle penchée → lame →
## stèle → la gueule. Les signes secondaires viennent D'ABORD, le dominant
## ensuite, exactement comme l'intention l'impose. Les lames sont enfoncées
## de 7 à 11 cm : elles n'émergent plus que de 0,13 à 0,20 m, donc bien sous
## la hauteur de marche du héros (0,30-0,38 m, §8.2) — on marche dessus sans
## collider et sans traversée visible. « À demi avalées par l'herbe » cesse
## d'être une image : c'est la cote.
##
## Trois marques isolées loin du chemin (est et ouest) étendent le lieu
## au-delà des trois dos sans le remplir : entre elles, il n'y a rien, et
## c'est voulu. Ce sont elles qui portent l'emprise, donc elles déclarent
## leur assise.
##
## ---------------------------------------------------------------------------
## D3 — LA PIERRE FINIT DE PRENDRE LA HAUTEUR (lot 1.R, correction D3)
##
## Le geste précédent s'appelait « la hauteur passe de la TERRE à la PIERRE ».
## Il n'est pas allé jusqu'au point où la pierre DOMINE la terre : le linteau
## culminait à 1,92 m sous une crête de `Tertre_Grand` à 2,15 m, et sur
## l'aplat noir il n'en restait qu'un éclat au-dessus du dos gauche. Le
## cimetière lisait alors, comme le belvédère, « masse dominante à gauche,
## vide, satellite détaché à droite » — même signature de composition, et
## `tools/lot1_repetition.py` l'a mesuré sur l'arbre intégré : IoU 0,505 à
## 30 m contre un seuil de 0,4931.
##
## Les six marques dressées prennent donc leur vraie taille, EN CRESCENDO le
## long du chemin d'arrivée (sud-ouest → gueule) : la séquence « signes
## secondaires d'abord, puis le dominant » cesse d'être un simple ordre de
## rencontre et devient une montée. Les lames couchées ne bougent PAS —
## « à demi avalées par l'herbe » reste la cote, et le vide entre les masses
## n'est pas rempli : on ajoute UNE pierre, on n'en sème pas dix.
##
## Deux colonnes s'ajoutent aux spécifications : l'échelle EN TRAVERS et
## l'échelle EN HAUTEUR. Elles sont dissociées parce qu'une pierre dressée
## n'est pas une petite pierre agrandie — elle est plus élancée. Les strates
## de `COLOR_0` s'étirent d'autant : sur un bloc de quatre mètres, un lit de
## 0,45 m est plus juste qu'un lit de 0,17 m.
##
## ---------------------------------------------------------------------------
## LOT 1.R.1 — UNE ENTRÉE, PUIS UN AXE ; PLUS UN SEMIS
##
## Le verdict dit « répartis autour » : c'est le mot qui condamne l'ancienne
## liste. Cinq pièces jetées de biais entre l'arrivée et la gueule ne font pas
## un chemin ; il leur manquait le commencement. Un lieu funéraire commence
## par un SEUIL — deux pierres inégales et une rupture du sol — et se
## poursuit par un axe qu'on suit sans y penser.
##
## LES POSITIONS SONT CALCULÉES DEPUIS LA CAMÉRA JOUEUR, ET C'EST ASSUMÉ. La
## caméra gelée `barrow_cemetery_joueur` est en local (−6,0 ; +10,4) et
## regarde l'origine ; sa direction unitaire vaut (0,500 ; −0,866). Pour
## chaque pierre, la profondeur `p = 0,5·dx − 0,866·dz` et le décalage
## latéral `l = 0,5·dz + 0,866·dx` disent où elle tombera dans le cadre —
## et à 65° de champ, la demi-largeur visible à la profondeur `p` vaut
## `0,637·p`. Ce n'est PAS un cadrage flatteur (aucune caméra ne bouge, aucun
## FOV ne change) : c'est le seul moyen de placer un seuil qui encadre au lieu
## de masquer, et de vérifier AVANT la capture que la pierre du seuil ne vient
## pas se poser devant le coffre.
##
##   seuil haut  (−6,45 ; 5,98) → profondeur 3,66 ; latéral −2,55 → bord gauche
##   seuil bas   (−4,30 ; 6,36) → profondeur 4,35 ; latéral −0,63 → tiers gauche
##   coffre      (−1,50 ; 4,30) → profondeur 7,53 ; latéral +0,85 → centre droit
##
## L'écart entre les deux pierres du seuil vaut 2,18 m : on passe entre elles.
##
## ---------------------------------------------------------------------------
## LOT 1.R.2 — LE PORTAIL RECULE, SE RESSERRE, ET S'OUVRE SUR LE TERTRE
##
## Verdict Codex : « l'entrée n'est pas évidente ». Elle ne l'était pas, et la
## cause est mesurable dans le cadre gelé plutôt que dans l'intention.
##
## PREMIÈRE MESURE, ET ELLE CORRIGE UNE ERREUR DE CE FICHIER. Les colonnes
## « profondeur / latéral » ci-dessus supposaient un demi-champ horizontal de
## `tan 32,5° = 0,637`. C'est faux : `shots_lot1.json` donne `fov 65`, et un
## `Camera3D` en `KEEP_HEIGHT` — le défaut — traite `fov` comme VERTICAL. À
## 1280 × 720 le demi-champ horizontal vaut donc `tan(32,5°) × 16/9 = 1,132`,
## soit un champ de 97°, presque le double de ce qui était supposé. Toutes les
## positions écran calculées au lot 1.R.1 étaient donc décalées vers les bords.
## Vérification indépendante : le coffre, à `l/p = 0,1125`, tombe à
## `640 + 640 × 0,1125 / 1,132 = 704 px` — et il est bien à 704 px sur
## `lot1r1/revue_intermediaire/vues/barrow_cemetery_joueur.png`.
##
## DEUXIÈME MESURE, QUI EN DÉCOULE. Avec le bon champ, la pierre du seuil haut
## tombait à 232 px et à 3,60 m de l'objectif : elle occupait 653 px de haut,
## coupée par le bord bas — un menhir de premier plan, pas une entrée. Et sa
## compagne tombait à 569 px : 337 px les séparaient, avec quatre autres
## pierres entre elles. Deux pierres si écartées, avec du monde au milieu, ne
## se lisent pas comme une porte.
##
## Le portail recule à `p = 4,5 / 4,9` et se resserre à 340 et 560 px. Entre
## les deux, plus rien ne se dresse ; et derrière l'ouverture, à 346-472 px,
## il y a exactement une chose : la crête du tertre dominant. L'entrée ouvre
## donc SUR la masse, ce que la corrective demande.
##
## Le passage reste franchissable : 1,74 m entre les deux centres, moins les
## demi-largeurs (0,43 et 0,39), soit 0,92 m de libre pour une capsule de
## 0,40 m de rayon.
const SEUIL: Array[Array] = [
	# pièce, x, z, lacet, enfoncement, roulis, échelle_travers, échelle_hauteur
	["SM_Barrow_Seuil_A", -5.82, 5.31, 58.0, 0.24, 11.0, 1.00, 1.00],
	# PASSE 2 : la pierre basse se relève de 1,07 à 1,55 m. À 1,07 m elle ne
	# lisait pas comme un montant mais comme un caillou, et un portail dont un
	# seul jambage tient debout n'est plus un portail. La paire reste
	# franchement dépareillée — 2,27 contre 1,55 — ce que le seuil exige.
	["SM_Barrow_Seuil_B", -4.15, 5.81, -41.0, 0.26, 24.0, 1.00, 1.45],
	# LA RUPTURE DU SOL — deux lames posées EN TRAVERS de l'axe, à demi
	# avalées. Ce sont elles qui disent « ici, le sol a été préparé » ; sans
	# elles, deux pierres debout ne sont que deux pierres debout.
	# Elles passent DEVANT le portail (0,35 m vers l'objectif) au lieu d'être
	# semées de biais derrière lui : c'est le seuil qu'on foule avant d'entrer.
	["SM_Barrow_Lame_A", -5.59, 5.73, 73.0, 0.13, 0.0, 1.00, 1.00],
	["SM_Barrow_Lame_C", -4.76, 5.98, 96.0, 0.09, 0.0, 1.00, 1.00],
]

## L'AXE FUNÉRAIRE, ET IL EST INCOMPLET — c'est le contrat §5, « espaces vides
## intentionnels ». Quatre marques entre le seuil et la gueule, alternant d'un
## côté et de l'autre de l'axe, dont DEUX sont tombées : la file de pierres
## dressées a des trous, et ces trous sont ce qui distingue un cimetière ancien
## d'une allée de jalons. Les hauteurs ne montent pas régulièrement non plus
## (1,24 puis 1,46) : une progression monotone se relit procédurale.
##
## LOT 1.R.2 — LE CHEMIN COURT DEMANDÉ PAR LA CORRECTIVE
##
## « Relier cette entrée au tertre dominant par un chemin court. » Les quatre
## marques du lot précédent tombaient à 466, 518, 598 et 604 px : elles
## partaient du portail et s'en allaient vers la GUEULE, c'est-à-dire vers le
## coffre. Le chemin conduisait donc l'œil exactement là où il ne devait pas
## aller, et la marque la plus haute (1,58 m, 466 px) se plantait sur la crête
## du dominant (472 px) — elle le hachait au lieu de le montrer.
##
## Le nouvel axe part du MILIEU du portail (−4,985 ; 5,56) et vise le CENTRE
## du dominant : direction (0,2524 ; −0,9676). Il est court par construction —
## la lisière du dos est à 2,65 m — et c'est ce que la corrective demande.
##
## Trois lames couchées y sont posées à 0,75 / 1,55 / 2,35 m ; elles tombent à
## 459, 462 et 464 px, c'est-à-dire sur une VERTICALE d'écran qui pointe la
## crête. Deux stèles les bordent, une de chaque côté et à des distances
## différentes (554 px à droite, 370 px à gauche) : une file bordée alterne,
## elle ne fait pas une haie.
##
## Elles s'arrêtent AVANT la lisière : une lame posée par `_seated()` à
## l'intérieur de la jupe serait enterrée par la terre du tertre, et rien dans
## la capture ne le dirait — c'est le contrôle `dn < 1` fait à la main ici.
##
## PASSE 2 — LES LAMES COUCHÉES DU CHEMIN SONT RETIRÉES, ET C'EST LA CAPTURE
## QUI L'A IMPOSÉ, PAS UN GOÛT.
##
## Sur `it1/barrow_cemetery_joueur.png`, les trois lames tombaient bien à 459,
## 462 et 464 px — c'était le calcul, et il était juste. C'était l'INTENTION
## qui était fausse : trois objets posés sur la ligne de visée ne font pas une
## file, ils se RECOUVRENT. Le résultat lit un tas de dalles jetées, exactement
## le « semis d'arêtes grises » que la passe C3 du lot précédent avait déjà
## chassé autour du coffre. Une file ne se lit que vue de BIAIS.
##
## Le chemin devient donc une MONTÉE DE PIERRES DRESSÉES, décalées de part et
## d'autre de l'axe et croissant vers la crête : 0,99 m à 552 px, 1,61 m à
## 507 px, 1,83 m à 370 px. Le regard monte de droite à gauche et arrive sur le
## point haut du dos (346 px). Trois verticales séparées de 45 à 137 px ne
## peuvent pas se télescoper, et une allée de pierres levées ne demande aucune
## explication.
##
## Les trois sont posées hors de la jupe du dominant, avec la marge du PIRE
## secteur : le rayon en travers vaut `demi_large × (0,78 + 0,44 × lissé)`,
## donc jusqu'à 4,64 m, et les trois sont à v = 4,80 / 5,01 / 5,24. Une pierre
## posée par `_seated()` sous la terre du tertre y serait à moitié enterrée, et
## aucune capture ne le dirait avant que la pierre n'ait disparu.
const CHEMIN: Array[Array] = [
	# pièce, x, z, lacet, enfoncement, roulis, échelle_travers, échelle_hauteur
	["SM_Barrow_Stele_B", -3.912, 5.013, 63.0, 0.20, 22.0, 1.05, 1.05],
	["SM_Barrow_Stele_C", -4.159, 4.309, -24.0, 0.24, 17.0, 1.06, 1.20],
	["SM_Barrow_Stele_B", -5.475, 3.675, 108.0, 0.26, -14.0, 1.15, 1.95],
]
## Les deux marques les plus lointaines se rapprochent de 1,4 et 1,0 m : le
## lieu fait 24 m de large pour 2 m de haut, et c'est ce RAPPORT qui décide si
## une silhouette portrait est lisible. Le vide reste l'identité — on le
## traverse toujours — mais il n'a pas besoin de vingt-trois mètres.
## La stèle de l'est se dresse elle aussi : c'est la marque la plus lointaine
## du côté opposé au chemin, et c'est elle qui empêche le rythme des
## verticales de se tasser tout entier dans la moitié gauche du cadre.
const MARQUES_ISOLEES: Array[Array] = [
	["SM_Barrow_Stele_B", 6.40, -3.20, 71.0, 0.15, 31.0, 1.05, 1.62],
	["SM_Barrow_Lame_C", 11.20, -1.80, -48.0, 0.08, 0.0, 1.00, 1.00],
	["SM_Barrow_Lame_B", -9.40, -5.60, 23.0, 0.10, 0.0, 1.00, 1.00],
]

## LA PIERRE DE TÊTE — la seule verticale qui domine tout le lieu.
##
## RENOMMÉE au lot 1.R.1 (`PIERRE_DU_SEUIL` → `PIERRE_DE_TETE`) : le lieu a
## maintenant un vrai SEUIL — l'entrée funéraire du sud-ouest — et deux
## choses différentes portant le même nom dans le même fichier finissent par
## être confondues en revue. Celle-ci est à la TÊTE de la tombe ; le seuil
## est à l'autre bout du lieu.
##
## Position : au bout HAUT du grand axe de `Tertre_Grand`, 1,2 m au-delà du
## pied du dos, c'est-à-dire à la TÊTE de la tombe et à l'opposé de la gueule.
## Trois raisons, toutes vérifiables :
##   * elle n'entre ni dans le quadrant d'accès des déblais, ni dans le
##     corridor d'arrivée : on continue de marcher jusqu'au coffre sans la
##     contourner (elle est à 4,5 m de l'ancre de récompense) ;
##   * vue depuis l'arrivée sud-ouest elle se dresse DERRIÈRE le dos
##     dominant, donc elle couronne l'élément héroïque au lieu de le
##     précéder — l'intention impose les signes secondaires D'ABORD ;
##   * elle est assise sur le terrain gelé, hors de la jupe du tertre, donc
##     `_seated()` suffit et rien ne flotte.
##
## Hauteur : `SM_Barrow_Stele_A` (1,57 m) étirée à 4,33 m, large de 0,99 m et
## épaisse de 0,42 m. C'est une proportion de menhir, pas une stèle agrandie,
## et c'est la cote qui fait basculer la lecture : contre une crête à 2,15 m,
## la pierre gagne. Le sommet du lieu passe donc du linteau (1,92 m) à cette
## pierre, et l'emprise Y du cadrage de silhouette avec lui — c'est le
## mécanisme de la correction, mesuré et non supposé.
##
## L'emprise XZ n'est PAS touchée : x = +1,89 et z = +1,36 tombent loin à
## l'intérieur des marques isolées (−9,4 … +11,2). Le cadre de capture est
## piloté par la largeur (`max(Y, largeur × H/L)`), il reste donc identique,
## et la comparaison avant/après porte sur la forme seule.
##
## PROPORTION CORRIGÉE (passe C2). À (1,55 ; 2,76) sur une pièce qui culmine
## désormais à 1,58 m au lieu de 1,74 nominal, la pierre faisait 1,05 × 4,36 m,
## soit un élancement de 4,2 : 1 — et sur l'aplat noir 0° de `it/c1` elle ne
## lit pas un menhir, elle lit une ANTENNE. À (1,95 ; 2,30) elle fait
## 1,33 × 3,63 m, élancement 2,7 : 1, ce qui est la proportion d'une pierre
## levée réelle. Elle domine toujours largement la crête du dominant (2,08 m),
## qui est la raison d'être de la correction D3.
##
## LOT 1.R.2 — ELLE CESSE D'ÉCRASER LA MASSE QU'ELLE EST CENSÉE COURONNER.
##
## À 3,63 m contre une crête de 2,08 m, elle faisait 1,75 fois la hauteur du
## tertre, et elle tombe à 751 px — soit 47 px du coffre (704 px). Le duo
## « grande pierre claire + coffre coloré » formait donc, à lui seul, le foyer
## de la vue joueur, dans la moitié DROITE du cadre, pendant que le tertre
## dominant restait un dos mou à gauche.
##
## Elle passe à 1,90 en hauteur, soit 3,00 m sur les 1,58 m réels de
## `SM_Barrow_Stele_A`, pour un tertre remonté à 2,50 : le rapport passe de
## 1,75 à 1,20. Elle reste la verticale la plus haute du lieu — c'est la
## correction D3 et elle n'est pas défaite — mais elle redevient l'ACCENT
## d'une masse au lieu d'en être la rivale. Son élancement, 1,33 × 3,00,
## vaut 2,3 : 1, toujours dans la proportion d'une pierre levée réelle.
const PIERRE_DE_TETE: Array = [1.886, 1.364, 34.0, 6.0, 1.95, 1.90]

## L'ANCRE DE LA RÉCOMPENSE, en local. ELLE NE BOUGE PAS — c'est la ligne
## rouge de la corrective — et elle est nommée ici pour une raison précise :
## l'enceinte basse ci-dessous se calcule DEPUIS elle. Une enceinte posée sur
## des littéraux recopiés dériverait à la première retouche sans que rien ne
## le signale, et le coffre se retrouverait à côté de sa propre sépulture.
const ANCRE_COFFRE: Vector2 = Vector2(-1.5, 4.3)

## L'ENCEINTE BASSE — la corrective, mot pour mot : « intégrer le coffre dans
## un renfoncement funéraire, une enceinte basse ou l'ombre du tertre ».
##
## Ce qui faisait du coffre le sujet n'était pas sa couleur — elle est déjà
## désaturée et assombrie par `_habiller_recompense()`, et sa saturation
## mesurée est INFÉRIEURE à celle de l'herbe. C'était son ISOLEMENT : entre le
## montant A (619 px) et le montant B (771 px) il y avait 152 px de vide et,
## au milieu, un objet posé à plat sur de l'herbe claire. Un objet seul au
## centre d'un vide est un sujet, quelle que soit sa teinte.
##
## Cinq dalles couchées ferment donc un arc autour de lui, à 1,26-1,34 m, et
## le SECTEUR D'APPROCHE RESTE OUVERT : rien entre 55° et 125°, c'est-à-dire
## rien du côté d'où l'on vient et par où `RewardAnchor` fait approcher. Le
## coffre reste visible — les dalles sont couchées et enfoncées, elles ne
## montent pas devant lui — accessible, et sa logique n'est pas touchée.
## Elles portent la teinte ENTERRÉE (0,88) : une enceinte qui brillerait plus
## que le coffre déplacerait le problème au lieu de le résoudre.
##
## [pièce, angle sur l'arc en degrés, rayon en m, échelle]
##
## PASSE 2 : QUATRE DALLES PLUS LARGES ET PLUS SERRÉES, PAS CINQ PETITES. Sur
## `it1`, cinq dalles à échelle 0,95-1,15 se lisaient comme le même semis
## d'éclats que le chemin. Une enceinte se lit à sa CONTINUITÉ : moins de
## pièces, plus grandes, bord à bord.
const ENCEINTE: Array[Array] = [
	["SM_Barrow_Lame_A", 165.0, 1.24, 1.45],
	["SM_Barrow_Lame_B", 218.0, 1.22, 1.40],
	["SM_Barrow_Lame_A", 272.0, 1.26, 1.35],
	["SM_Barrow_Lame_C", 332.0, 1.28, 1.50],
]


## LA TEINTE SUIT LE RÔLE, ET C'EST LE CONTRAT §5 : « pierre exposée ≠
## enterrée ≠ humide ». Toutes les pierres du lieu partagent une même famille
## de matériau ; ce qui les distingue est un simple facteur multiplicatif sur
## l'albédo, appliqué à une COPIE de matériau propre à l'exemplaire. Trois
## bandes seulement — plus serait du bruit :
##   1,06  exposée au vent et au soleil, lessivée
##   1,00  la bande de référence
##   0,88  au ras du sol, dans l'ombre de l'herbe et l'humidité
## Ce n'est pas de la décoration : c'est la hiérarchie de valeurs qui empêche
## un objet unique — le coffre — d'être le seul accident du cadre.
const TEINTE_EXPOSEE: float = 1.06
const TEINTE_ENTERREE: float = 0.88

## LES COTES RÉELLES DES PIÈCES DRESSÉES, relevées à l'export du GLB et non
## reprises des cotes NOMINALES passées à `dalle()` : le générateur ébrèche,
## casse les têtes en biais et amincit, donc la pierre livrée est plus courte
## que la valeur demandée (2,34 → 2,27 ; 1,74 → 1,58 ; 1,42 → 1,34…). C'est
## sur ces cotes-là que les corps se calculent, sans quoi chaque boîte
## flotterait de la différence.
## Elles ne concernent QUE les pierres dressées : une lame couchée n'a pas de
## corps, et lui en donner un ferait un seuil de 20 cm qu'on sent sans le voir.
const HAUTEUR_REELLE: Dictionary = {
	"SM_Barrow_Seuil_A": 2.27, "SM_Barrow_Seuil_B": 1.07,
	"SM_Barrow_Stele_A": 1.58, "SM_Barrow_Stele_B": 0.94,
	"SM_Barrow_Stele_C": 1.34,
}
const LARGEUR_REELLE: Dictionary = {
	"SM_Barrow_Seuil_A": 0.86, "SM_Barrow_Seuil_B": 0.78,
	"SM_Barrow_Stele_A": 0.68, "SM_Barrow_Stele_B": 0.60,
	"SM_Barrow_Stele_C": 0.58,
}
const EPAISSEUR_REELLE: Dictionary = {
	"SM_Barrow_Seuil_A": 0.33, "SM_Barrow_Seuil_B": 0.30,
	"SM_Barrow_Stele_A": 0.24, "SM_Barrow_Stele_B": 0.23,
	"SM_Barrow_Stele_C": 0.22,
}


## L'ENCEINTE BASSE DU COFFRE — un arc de dalles couchées, ouvert du côté par
## lequel on vient.
##
## L'origine d'une lame du GLB n'est pas à son milieu ; la convention retenue
## est celle, déjà éprouvée, des lames du chemin : on pose le point et on
## laisse la pièce s'étendre. Le lacet vaut `−angle` pour que la dalle soit
## TANGENTE à l'arc — une dalle radiale ferait un rayon de roue, une dalle
## tangente ferme une enceinte.
func _enceinte_du_coffre() -> void:
	var index: int = 0
	for spec: Array in ENCEINTE:
		index += 1
		var a: float = deg_to_rad(float(spec[1]))
		var r: float = float(spec[2])
		var x: float = ANCRE_COFFRE.x + cos(a) * r
		var z: float = ANCRE_COFFRE.y + sin(a) * r
		var at: Vector3 = _seated(x, z)
		var dalle: Node3D = _piece_pierre(String(spec[0]),
			at + Vector3(0.0, -0.11, 0.0),
			Vector3(0.0, deg_to_rad(-float(spec[1])), 0.0),
			"Enceinte_%d" % index, TEINTE_ENTERREE)
		dalle.scale = Vector3.ONE * float(spec[3])
		declare_support(at)


func _chemin_des_morts() -> void:
	var index: int = 0
	for lot: Array in [SEUIL, CHEMIN, MARQUES_ISOLEES]:
		for spec: Array in lot:
			index += 1
			var at: Vector3 = _seated(float(spec[1]), float(spec[2]))
			# Plus une pierre est enfoncée, plus elle est sombre : la mesure
			# de son enfoncement DÉCIDE de sa teinte, au lieu d'une table
			# parallèle qui dériverait à la première retouche de cote.
			var enfoncee: float = clampf(float(spec[4]) / 0.26, 0.0, 1.0)
			var teinte: float = lerpf(TEINTE_EXPOSEE, TEINTE_ENTERREE, enfoncee)
			var marque: Node3D = _piece_pierre(String(spec[0]),
				at + Vector3(0.0, -float(spec[4]), 0.0),
				Vector3(0.0, deg_to_rad(float(spec[3])),
					deg_to_rad(float(spec[5]))),
				"Marque_%d" % index, teinte)
			marque.scale = Vector3(float(spec[6]), float(spec[7]),
				float(spec[6]))
			declare_support(at)
	_pierre_de_tete()


## La pierre dressée de la tête de tombe. Elle est bâtie à part et non ajoutée
## à `CHEMIN` : elle n'appartient pas au chemin, elle en est le terme.
func _pierre_de_tete() -> void:
	var at: Vector3 = _seated(float(PIERRE_DE_TETE[0]),
		float(PIERRE_DE_TETE[1]))
	var pierre: Node3D = _piece_pierre("SM_Barrow_Stele_A", at,
		Vector3(0.0, deg_to_rad(float(PIERRE_DE_TETE[2])),
			deg_to_rad(float(PIERRE_DE_TETE[3]))),
		"Pierre_de_tete", TEINTE_EXPOSEE)
	pierre.scale = Vector3(float(PIERRE_DE_TETE[4]),
		float(PIERRE_DE_TETE[5]), float(PIERRE_DE_TETE[4]))
	declare_support(at)


## LA STEPPE — trois touffes sèches, deux éclats, rien d'autre. Aucun
## arbre : la steppe du nord n'en porte pas, et le vide est l'identité.
##
## `rock_smallB` est retiré pour la même raison que `rock_largeA/C` : son
## glTF porte lui aussi les matériaux `grass` et `dirt`.
func _steppe() -> void:
	for spec: Array in [[5.0, 8.2, 27.0], [-9.6, -2.4, -51.0],
			[13.4, 4.6, 84.0]]:
		K.module(self, &"Grass_Common_Tall",
			_seated(float(spec[0]), float(spec[1])), float(spec[2]), 1.0,
			K.TONE_PLANT)
	# Les deux éclats de steppe DÉPLACÉS (lot 1.R.1) : (1,4 ; 3,4) tombait
	# maintenant en plein dans la tranchée d'accès, et (−5,4 ; 7,6) juste
	# derrière la pierre du seuil. Un caillou qui sort du sol au milieu d'une
	# fouille n'est pas un défaut de test, c'est un défaut d'image.
	K.module(self, &"Rock_Medium_3", _seated(2.9, 4.6) + Vector3(0.0, -0.12, 0.0),
		62.0, 0.19, TONE_BLOC)
	K.module(self, &"Rock_Medium_1", _seated(-7.8, 8.4) + Vector3(0.0, -0.10, 0.0),
		-19.0, 0.15, TONE_BLOC)


## COLLISIONS — des SPHÈRES le long de la crête, jamais une boîte : un dos se
## franchit en marchant, une boîte s'y cogne à hauteur d'arête.
##
## UNE seule sphère ne convient plus. L'ancien tertre était un dôme de
## révolution et une sphère l'épousait ; un DOS long de dix mètres pour six
## de large n'a pas de sphère inscrite. On en pose donc une CHAÎNE le long de
## la crête, chacune calibrée sur la demi-LARGEUR : une sphère qui vaut zéro
## au bord et `h` au centre a pour rayon `R = (r² + h²) / 2h`, et son
## empreinte au sol vaut exactement `r`. La chaîne couvre donc la largeur
## sans jamais déborder latéralement.
##
## APPROXIMATION ASSUMÉE ET NOMMÉE : aux deux BOUTS du dos, là où la crête
## s'abaisse sous 0,4 m, la chaîne s'arrête et la géométrie devient
## traversable. C'est le même arbitrage que les lames couchées — une masse
## de moins de 40 cm ne mérite pas un corps — et c'est l'inverse d'un débord,
## qui lui se sentirait comme un mur invisible.
func _collisions() -> void:
	for spec: Array in TERTRES:
		var cx: float = float(spec[1])
		var cz: float = float(spec[2])
		var demi_long: float = float(spec[3])
		var demi_large: float = float(spec[4])
		var hauteur: float = float(spec[5])
		var a_rad: float = deg_to_rad(float(spec[6]))
		var e: Vector2 = Vector2(cos(a_rad), sin(a_rad))
		var rayon: float = demi_large * 0.90
		# Une sphère par 0,9 rayon de largeur le long de la crête utile.
		var portee: float = demi_long * 0.55
		var n: int = maxi(1, int(round(portee * 2.0 / (rayon * 0.95))))
		for i: int in range(n):
			var t: float = 0.0 if n == 1 else \
				(-1.0 + 2.0 * float(i) / float(n - 1))
			var p: Vector2 = Vector2(cx, cz) + e * (portee * t)
			# La hauteur locale suit l'affaissement de la crête — MÊME FORMULE
			# que `_tertre()`, amplitude comprise. Laisser le corps sur
			# l'ancien 0,85 + 0,15 alors que la géométrie passe à 0,70 + 0,30
			# ferait flotter la chaîne de 20 cm à un bout et l'enterrerait à
			# l'autre, sans qu'aucune capture ne le montre.
			var h_local: float = hauteur * (0.70 + 0.30 * (0.5 + 0.5 * t))
			if h_local < 0.40:
				continue
			var r_sphere: float = (rayon * rayon + h_local * h_local) \
				/ (2.0 * h_local)
			var corps: StaticBody3D = StaticBody3D.new()
			corps.name = "%s_col_%d" % [String(spec[0]), i]
			corps.collision_layer = 1
			corps.collision_mask = 0
			var forme: CollisionShape3D = CollisionShape3D.new()
			forme.name = corps.name + "_forme"
			var boule: SphereShape3D = SphereShape3D.new()
			boule.radius = r_sphere
			forme.shape = boule
			corps.add_child(forme)
			add_child(corps)
			corps.position = _seated(p.x, p.y) \
				+ Vector3(0.0, h_local - r_sphere, 0.0)
	# LA GUEULE : DEUX volumes, un par montant, et RIEN sur le linteau.
	#
	# L'ancien volume unique (2,60 × 2,50 × 0,95) enjambait les deux montants
	# ET leur couverture. Il ne gênait personne tant que la gueule était à
	# deux mètres derrière le coffre ; maintenant qu'elle l'ENCADRE, ce même
	# volume fermerait l'accès à la récompense — « un coffre au fond d'une
	# chambre fermée serait un piège », dit le contrat, et un collider qui
	# barre le passage est exactement ce piège, en pire : invisible.
	#
	# Le linteau reste donc sans corps, et c'est une APPROXIMATION ASSUMÉE, la
	# même famille que celle déjà prise pour les têtes de stèles penchées : à
	# 2,20 m d'appui et 1,90 m au bout glissé, un corps serait au-dessus de la
	# tête du héros, au-dessus de la récompense, et se sentirait sans se voir.
	K.collider_box(self, "Gueule_montant_A",
		_seated(-2.62, 4.02) + Vector3(0.0, 1.30, 0.0),
		Vector3(0.95, 2.60, 0.42), 26.0)
	K.collider_box(self, "Gueule_montant_B",
		_seated(-0.46, 4.46) + Vector3(0.0, 1.00, 0.0),
		Vector3(0.82, 2.00, 0.38), -18.0)
	# Les deux stèles du chemin et celle de l'est — les lames se franchissent.
	# Les trois boîtes SUIVENT l'étirement des pierres (§ CHEMIN) : une stèle
	# qui double de hauteur sans son corps se traverserait par le haut.
	#
	# APPROXIMATION ASSUMÉE ET NOMMÉE, et c'est la MÊME que celle d'avant :
	# la boîte reste D'APLOMB alors que la pierre penche (17°, 24°, 31°, 6°).
	# Le sommet penché sort donc de son corps — jusqu'à 0,73 m sur la stèle
	# haute. C'est délibéré et c'est le sens de l'arbitrage déjà pris pour les
	# lames couchées : mieux vaut une masse traversable en haut qu'un mur
	# invisible qu'on sent sans le voir. Le pied, lui, est couvert, et c'est
	# lui qu'on heurte en marchant.
	# LES TROIS CORPS SUIVENT L'ENFONCEMENT (lot 1.R). Les stèles descendent de
	# 0,26 / 0,20 / 0,15 m dans le sol — « les tombes émergent de la colline,
	# elles ne sont pas posées » — et un corps resté à sa cote flotterait
	# d'autant au-dessus du pied qu'on heurte en marchant. Le centre baisse donc
	# de la moitié de l'enfoncement, la hauteur de la totalité : la boîte épouse
	# la partie ÉMERGÉE, qui est la seule qu'on puisse rencontrer.
	# LES CORPS SUIVENT LA NOUVELLE IMPLANTATION (lot 1.R.1). Chaque boîte est
	# calée sur la pièce qu'elle couvre : hauteur = hauteur réelle du GLB ×
	# échelle − enfoncement, centre à la moitié de cette hauteur.
	#   Seuil_A  2,27 × 1,00 − 0,24 = 2,03    Seuil_B  1,07 × 1,00 − 0,26 = 0,81
	#   Marque m1 (Stele_B) 0,94 × 1,55 − 0,22 = 1,24
	#   Marque m3 (Stele_C) 1,34 × 1,28 − 0,26 = 1,45
	# LES CORPS DES PIERRES DRESSÉES SONT DÉRIVÉS DES TABLES, PLUS RECOPIÉS.
	#
	# C'est la correction d'un piège que ce fichier portait sans le dire : cinq
	# `collider_box` répétaient à la main les positions, lacets, enfoncements
	# et échelles de `SEUIL`, `CHEMIN` et `MARQUES_ISOLEES`. Déplacer une
	# pierre — ce que le lot 1.R.2 fait pour six d'entre elles — laissait donc
	# son corps derrière elle, et AUCUNE capture ne montre un collider. La
	# boucle ci-dessous lit les mêmes tables que `_chemin_des_morts()` : les
	# deux ne peuvent plus diverger.
	#
	# Seules les pierres DRESSÉES reçoivent un corps ; les lames couchées
	# restent franchissables, arbitrage déjà pris et inchangé.
	#
	# APPROXIMATION ASSUMÉE, INCHANGÉE : la boîte reste d'aplomb alors que la
	# pierre penche, donc la tête penchée sort de son corps. Mieux vaut une
	# masse traversable en haut qu'un mur invisible qu'on sent sans le voir.
	var index: int = 0
	for lot: Array in [SEUIL, CHEMIN, MARQUES_ISOLEES]:
		for spec: Array in lot:
			index += 1
			var piece: String = String(spec[0])
			if not HAUTEUR_REELLE.has(piece):
				continue
			var enfoncement: float = float(spec[4])
			var hauteur: float = float(HAUTEUR_REELLE[piece]) \
				* float(spec[7]) - enfoncement
			if hauteur <= 0.35:
				continue
			K.collider_box(self, "Marque_%d_col" % index,
				_seated(float(spec[1]), float(spec[2]))
					+ Vector3(0.0, hauteur * 0.5, 0.0),
				Vector3(float(LARGEUR_REELLE[piece]) * float(spec[6]),
					hauteur,
					float(EPAISSEUR_REELLE[piece]) * float(spec[6])),
				float(spec[3]))
	# La pierre de tête : elle a un corps sur toute sa hauteur — c'est la
	# seule masse du lieu qu'on ne franchit pas.
	# COTE RECALCULÉE sur la géométrie du lot 1.R.1, passe C2 :
	# `SM_Barrow_Stele_A` culmine à ~1,58 m ; × 2,30 cela fait 3,63 m, et sa
	# largeur 0,68 × 1,95 fait 1,33 m. Un corps calé sur une cote périmée est
	# exactement le genre de décalage qu'aucune capture ne montre.
	# COTE DÉRIVÉE, elle aussi : `SM_Barrow_Stele_A` culmine à 1,58 m, donc
	# 1,58 × 1,90 = 3,00 m après la réduction du lot 1.R.2, et 0,68 × 1,95 =
	# 1,33 m de large. Un corps calé sur 3,63 m — la cote d'avant — aurait
	# laissé 63 cm de mur invisible au-dessus de la pierre.
	var h_tete: float = float(HAUTEUR_REELLE["SM_Barrow_Stele_A"]) \
		* float(PIERRE_DE_TETE[5])
	K.collider_box(self, "Pierre_de_tete_col",
		_seated(float(PIERRE_DE_TETE[0]), float(PIERRE_DE_TETE[1]))
			+ Vector3(0.0, h_tete * 0.5, 0.0),
		Vector3(float(LARGEUR_REELLE["SM_Barrow_Stele_A"])
			* float(PIERRE_DE_TETE[4]), h_tete,
			float(EPAISSEUR_REELLE["SM_Barrow_Stele_A"])
			* float(PIERRE_DE_TETE[4])),
		float(PIERRE_DE_TETE[2]))


## Extrait UNE pièce du GLB des pierres funéraires (recette `_piece_tour` de
## la tour) : élaguée AVANT d'entrer dans l'arbre, et nommée explicitement —
## huit marques tirées de cinq maillages produiraient sinon des homonymes que
## Godot rebaptise `@Node3D@366` (`scripts/CLAUDE.md`).
func _piece_pierre(piece: String, at: Vector3, rot: Vector3,
		nom: String = "", teinte: float = 1.0) -> Node3D:
	var instance: Node3D = PIERRES_SCENE.instantiate() as Node3D
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
	_peindre_pierres(instance, teinte)
	return instance


## Aplat painterly sur les matériaux du GLB — matériaux DUPLIQUÉS et mis en
## cache, jamais de mutation d'une ressource importée.
func _peindre_pierres(racine: Node3D, teinte: float = 1.0) -> void:
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
			# LA TEINTE ENTRE DANS LA CLÉ DE CACHE, et c'est indispensable :
			# sans elle, la première pierre peinte imposerait sa nuance à
			# toutes les suivantes de la même famille — un défaut qui ne se
			# voit ni au parse ni au compte de nœuds, seulement à la capture.
			var cle: String = "cimetiere|%d|%.3f" % [base.get_instance_id(),
				teinte]
			var mat: StandardMaterial3D = \
				_cache_pierres.get(cle) as StandardMaterial3D
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
				if TEINTES_PIERRES.has(famille):
					var c: Color = TEINTES_PIERRES[famille] as Color
					mat.albedo_color = Color(
						minf(1.0, c.r * teinte), minf(1.0, c.g * teinte),
						minf(1.0, c.b * teinte), c.a)
				_cache_pierres[cle] = mat
			instance.set_surface_override_material(surface, mat)


## Hachage déterministe dans [−1 ; 1]. Pas de `randf()` : trois tertres
## doivent être identiques d'un montage à l'autre, sinon une régression
## visuelle compare deux mondes et ne prouve rien.
func _alea(graine: float) -> float:
	var v: float = sin(graine * 127.1 + 311.7) * 43758.5453
	return (v - floor(v)) * 2.0 - 1.0


## Un triangle dont CHAQUE SOMMET porte sa valeur ET SA NORMALE.
##
## LA VALEUR : c'est le dégradé couronne-terreuse → lisière-herbeuse qui fait
## fondre le bord du tertre dans le terrain. Une valeur unique par triangle
## redonnerait des facettes.
##
## LA NORMALE — CORRECTION DU LOT 1.R, ET C'ÉTAIT LE DÉFAUT PRINCIPAL DU LIEU.
## Cette fonction calculait jusqu'ici la normale de FACE et l'appliquait aux
## trois sommets. C'est la définition de l'ombrage plat : chacune des
## 48 × 8 facettes du dos recevait sa propre valeur d'éclairage, et le tertre
## rendait une CITROUILLE — des bandes claires et sombres rayonnant de la
## crête à la lisière, parfaitement visibles sur
## `agent_b/base/barrow_cemetery_joueur.png` une fois la vue agrandie.
##
## C'est la même famille de reproche que l'audit a portée trois fois (« des
## tentes de papier plié »), et les passes précédentes l'ont attaquée par la
## GÉOMÉTRIE — profil, crête, relief lissé, teinte non radiale. La géométrie
## est effectivement devenue ronde : la silhouette du dos, mesurée sur la
## capture, n'a plus d'arête faîtière. Ce qui restait radial n'était pas la
## forme, c'était l'ÉCLAIRAGE. Aucun réglage de profil ne pouvait le corriger.
##
## Les normales viennent désormais de `_normales_de_grille()`, par différences
## finies sur la grille du dos : une surface de terre est lisse, et son
## ombrage doit l'être aussi. Le redressement vers le haut est conservé — sans
## lui, une erreur de signe d'enroulement donnerait un tertre NOIR, défaut qui
## ne se voit qu'à la capture, jamais au parse ni au compte de maillages.
func _triangle_degrade(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		ta: float, tb: float, tc: float,
		na: Vector3 = Vector3.ZERO, nb: Vector3 = Vector3.ZERO,
		nc: Vector3 = Vector3.ZERO) -> void:
	var face: Vector3 = (b - a).cross(c - a).normalized()
	if face.y < 0.0:
		face = -face
	var normales: Array[Vector3] = [
		na if na.length_squared() > 0.5 else face,
		nb if nb.length_squared() > 0.5 else face,
		nc if nc.length_squared() > 0.5 else face,
	]
	var sommets: Array[Vector3] = [a, b, c]
	var tons: Array[float] = [ta, tb, tc]
	for index: int in range(3):
		var n: Vector3 = normales[index]
		if n.y < 0.0:
			n = -n
		st.set_color(Color(tons[index], tons[index], tons[index], 1.0))
		st.set_normal(n)
		st.add_vertex(sommets[index])


## NORMALES LISSÉES d'une grille anneaux × secteurs, par différences finies.
##
## Chaque sommet interne prend le produit vectoriel de ses deux tangentes —
## le long de l'anneau (voisins i−1, i+1, la grille est fermée) et en travers
## des anneaux (r−1, r+1, bornés aux extrémités). C'est exact et sans soudure :
## la grille partage déjà ses sommets logiques, il n'y a donc rien à souder,
## et aucune tolérance à choisir. Une accumulation par face aurait exigé de
## quantifier les positions, avec le risque connu de coller deux sommets qui
## ne devaient pas l'être.
func _normales_de_grille(
		grilles: Array[PackedVector3Array]) -> Array[PackedVector3Array]:
	var sortie: Array[PackedVector3Array] = []
	var nb_anneaux: int = grilles.size()
	for r: int in range(nb_anneaux):
		var ligne: PackedVector3Array = PackedVector3Array()
		var points: PackedVector3Array = grilles[r]
		# Le dernier point de chaque anneau est la copie du premier (la grille
		# est fermée) : les voisins se prennent donc modulo `secteurs`.
		var secteurs: int = points.size() - 1
		var bas: PackedVector3Array = grilles[mini(r + 1, nb_anneaux - 1)]
		var haut: PackedVector3Array = grilles[maxi(r - 1, 0)]
		for i: int in range(points.size()):
			var j: int = i % secteurs
			var tangente_u: Vector3 = points[(j + 1) % secteurs] \
				- points[(j - 1 + secteurs) % secteurs]
			var tangente_v: Vector3 = bas[j] - haut[j]
			var n: Vector3 = tangente_v.cross(tangente_u)
			if n.length_squared() < 1e-10:
				n = Vector3.UP
			n = n.normalized()
			if n.y < 0.0:
				n = -n
			ligne.append(n)
		sortie.append(ligne)
	return sortie


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
	StaticResourceCaches.enregistrer("BarrowCemeteryPlace", liberer_caches)


static func liberer_caches() -> int:
	var n: int = _cache_pierres.size()
	_cache_pierres.clear()
	return n
