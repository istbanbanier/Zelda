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
## Détail et cotes : § CHEMIN et § PIERRE_DU_SEUIL.
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
const TERRE: Color = Color(0.170, 0.185, 0.120)

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
const TERTRES: Array[Array] = [
	["Tertre_Grand", -3.5, -1.5, 5.00, 3.35, 2.15, 28.0, 4131],
	["Tertre_Moyen", 9.0, 6.5, 3.50, 2.20, 1.42, 52.0, 9077],
	["Tertre_Petit", 2.0, -8.5, 2.40, 1.60, 0.80, 14.0, 2609],
]

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
const FOSSE: Array = [0.90, 0.15, 0.62, 1.55, 1.15]

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
		_tertre(String(spec[0]), float(spec[1]), float(spec[2]),
			float(spec[3]), float(spec[4]), float(spec[5]),
			float(spec[6]), int(spec[7]),
			FOSSE if String(spec[0]) == "Tertre_Grand" else [])
	_ceintures()
	_gueule_de_chambre()
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
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.CHEST,
		_seated(-1.5, 4.3) + Vector3(0.0, 0.1, 0.0), Vector3(0.4, 0.0, 7.4))
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
			mat.albedo_color = Color(
				lerpf(c.r, gris, 0.55) * 0.68,
				lerpf(c.g, gris, 0.55) * 0.72,
				lerpf(c.b, gris, 0.55) * 0.79, c.a)
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
		fosse: Array) -> void:
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
		rayons_l.append(demi_long * (0.88 + 0.22 * lisse_l))
		rayons_t.append(demi_large * (0.84 + 0.30 * lisse_t))

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
			var h_crete: float = hauteur \
				* (0.85 + 0.15 * (0.5 - 0.5 * (u / maxf(0.35, demi_axe))))
			var releve: float = h_crete \
				* pow(maxf(cos(dn * PI * 0.5), 0.0), 1.25)
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
			releve *= 1.0 + 0.115 * bosse * sin(dn * PI)
			if not fosse.is_empty():
				var du: float = (u - float(fosse[0])) / float(fosse[3])
				var dv: float = (v - float(fosse[1])) / float(fosse[4])
				releve -= float(fosse[2]) * exp(-(du * du + dv * dv))
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
	var pierres: Array[Array] = [
		[-3.5, -1.5, 4.90, 202.0, &"Rock_Medium_1", 0.42],
		[-3.5, -1.5, 5.20, 318.0, &"Rock_Medium_3", 0.34],
		[-3.5, -1.5, 4.30, 96.0, &"Rock_Medium_2", 0.28],
		[9.0, 6.5, 3.40, 41.0, &"Rock_Medium_2", 0.30],
		[9.0, 6.5, 3.10, 236.0, &"Rock_Medium_1", 0.22],
		[2.0, -8.5, 2.35, 154.0, &"Rock_Medium_3", 0.20],
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
func _gueule_de_chambre() -> void:
	var a: Vector3 = _seated(-2.55, 2.35)
	_piece_pierre("SM_Barrow_Jamb_A", a,
		Vector3(0.0, deg_to_rad(22.0), deg_to_rad(5.0)))
	declare_support(a)
	var b: Vector3 = _seated(-0.95, 2.05)
	_piece_pierre("SM_Barrow_Jamb_B", b,
		Vector3(0.0, deg_to_rad(-16.0), deg_to_rad(-7.0)))
	declare_support(b)
	# Le linteau porte à cheval, à 1,18 m — sous l'arase du montant le plus
	# haut (1,46 m), donc il a DESCENDU. Onze degrés de dévers : il a glissé.
	# Le linteau porte à cheval à 1,92 m — sous l'arase du montant le plus
	# haut (2,42 m), donc il a DESCENDU d'un demi-mètre. Onze degrés de
	# dévers : il a glissé, il n'a pas été posé.
	_piece_pierre("SM_Barrow_Lintel",
		_seated(-1.78, 2.22) + Vector3(0.0, 1.92, 0.0),
		Vector3(deg_to_rad(11.0), deg_to_rad(96.0), deg_to_rad(-6.0)))
	# Les déblais, en deux tas de tailles différentes. Lacet 180° : dans le
	# GLB le quadrant libre regarde Blender +y, donc Godot −z ; il faut qu'il
	# regarde +z, le sud, d'où l'on arrive.
	var tas: Vector3 = _seated(-1.52, 3.85)
	# ÉCHELLE RECALÉE SUR CAPTURE : à 1,0 les éclats faisaient 0,30-0,62 m et
	# le coffre — 1,2 m de large — les écrasait ; on lisait « des cailloux à
	# côté d'un coffre », pas « un coffre dans des déblais ». À 1,5 le tas
	# arrive à hauteur de serrure et le berce.
	var grand: Node3D = _piece_pierre("SM_Barrow_Deblais", tas,
		Vector3(0.0, deg_to_rad(180.0), 0.0), "Deblais_grand")
	grand.scale = Vector3.ONE * 1.50
	declare_support(tas)
	var tas_b: Node3D = _piece_pierre("SM_Barrow_Deblais",
		_seated(-3.35, 3.30), Vector3(0.0, deg_to_rad(214.0), 0.0),
		"Deblais_petit")
	tas_b.scale = Vector3.ONE * 0.95
	# L'ASSISE DU COFFRE. L'audit : « il est littéralement posé au milieu ».
	# L'ancre ne bouge pas — c'est une contrainte du lead — donc c'est le TAS
	# qui monte autour d'elle : trois poignées d'éclats serrées contre le
	# coffre, une de chaque côté et une devant, à des échelles décroissantes.
	# Le coffre cesse d'être posé sur l'herbe ; il est calé dans la terre
	# remuée, ce qui est l'histoire du lieu.
	for index: int in range(3):
		var spec: Array = [[-2.25, 4.35, 0.44, 62.0], [-0.72, 4.20, 0.38, 231.0],
			[-1.55, 4.95, 0.30, 148.0]][index]
		var eclat: Node3D = _piece_pierre("SM_Barrow_Deblais",
			_seated(float(spec[0]), float(spec[1])),
			Vector3(0.0, deg_to_rad(float(spec[3])), 0.0),
			"Deblais_pied_%d" % index)
		eclat.scale = Vector3.ONE * float(spec[2])


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
const CHEMIN: Array[Array] = [
	# pièce, x, z, lacet, enfoncement, roulis, échelle_travers, échelle_hauteur
	["SM_Barrow_Lame_A", -7.60, 6.40, 38.0, 0.11, 0.0, 1.00, 1.00],
	["SM_Barrow_Stele_B", -6.05, 5.00, 62.0, 0.0, 24.0, 1.08, 1.72],
	["SM_Barrow_Lame_B", -4.90, 4.90, 15.0, 0.09, 0.0, 1.00, 1.00],
	["SM_Barrow_Stele_A", -4.25, 3.55, -28.0, 0.0, 17.0, 1.10, 1.58],
	["SM_Barrow_Lame_C", -3.05, 4.45, 74.0, 0.07, 0.0, 1.00, 1.00],
]
## Les deux marques les plus lointaines se rapprochent de 1,4 et 1,0 m : le
## lieu fait 24 m de large pour 2 m de haut, et c'est ce RAPPORT qui décide si
## une silhouette portrait est lisible. Le vide reste l'identité — on le
## traverse toujours — mais il n'a pas besoin de vingt-trois mètres.
## La stèle de l'est se dresse elle aussi : c'est la marque la plus lointaine
## du côté opposé au chemin, et c'est elle qui empêche le rythme des
## verticales de se tasser tout entier dans la moitié gauche du cadre.
const MARQUES_ISOLEES: Array[Array] = [
	["SM_Barrow_Stele_B", 6.40, -3.20, 71.0, 0.0, 31.0, 1.05, 1.62],
	["SM_Barrow_Lame_C", 11.20, -1.80, -48.0, 0.08, 0.0, 1.00, 1.00],
	["SM_Barrow_Lame_B", -9.40, -5.60, 23.0, 0.10, 0.0, 1.00, 1.00],
]

## LA PIERRE DU SEUIL — la seule verticale qui domine tout le lieu.
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
const PIERRE_DU_SEUIL: Array = [1.886, 1.364, 34.0, 6.0, 1.55, 2.76]


func _chemin_des_morts() -> void:
	var index: int = 0
	for lot: Array in [CHEMIN, MARQUES_ISOLEES]:
		for spec: Array in lot:
			index += 1
			var at: Vector3 = _seated(float(spec[1]), float(spec[2]))
			var marque: Node3D = _piece_pierre(String(spec[0]),
				at + Vector3(0.0, -float(spec[4]), 0.0),
				Vector3(0.0, deg_to_rad(float(spec[3])),
					deg_to_rad(float(spec[5]))),
				"Marque_%d" % index)
			marque.scale = Vector3(float(spec[6]), float(spec[7]),
				float(spec[6]))
			declare_support(at)
	_pierre_du_seuil()


## La pierre dressée de la tête de tombe. Elle est bâtie à part et non ajoutée
## à `CHEMIN` : elle n'appartient pas au chemin, elle en est le terme.
func _pierre_du_seuil() -> void:
	var at: Vector3 = _seated(float(PIERRE_DU_SEUIL[0]),
		float(PIERRE_DU_SEUIL[1]))
	var pierre: Node3D = _piece_pierre("SM_Barrow_Stele_A", at,
		Vector3(0.0, deg_to_rad(float(PIERRE_DU_SEUIL[2])),
			deg_to_rad(float(PIERRE_DU_SEUIL[3]))),
		"Pierre_du_seuil")
	pierre.scale = Vector3(float(PIERRE_DU_SEUIL[4]),
		float(PIERRE_DU_SEUIL[5]), float(PIERRE_DU_SEUIL[4]))
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
	K.module(self, &"Rock_Medium_3", _seated(1.4, 3.4) + Vector3(0.0, -0.12, 0.0),
		62.0, 0.19, TONE_BLOC)
	K.module(self, &"Rock_Medium_1", _seated(-5.4, 7.6) + Vector3(0.0, -0.10, 0.0),
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
			# La hauteur locale suit l'affaissement de la crête.
			var h_local: float = hauteur * (0.85 + 0.15 * (0.5 + 0.5 * t))
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
	# La gueule : UN volume pour les deux montants et leur linteau.
	K.collider_box(self, "Chambre_gueule",
		_seated(-1.78, 2.22) + Vector3(0.0, 1.25, 0.0), Vector3(2.60, 2.50, 0.95),
		96.0)
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
	K.collider_box(self, "Stele_chemin_haute",
		_seated(-4.25, 3.55) + Vector3(0.0, 1.23, 0.0),
		Vector3(0.73, 2.46, 0.44), -28.0)
	K.collider_box(self, "Stele_chemin_basse",
		_seated(-6.05, 5.00) + Vector3(0.0, 0.76, 0.0),
		Vector3(0.63, 1.51, 0.39), 62.0)
	K.collider_box(self, "Stele_est",
		_seated(6.40, -3.20) + Vector3(0.0, 0.68, 0.0),
		Vector3(0.61, 1.36, 0.38), 71.0)
	# La pierre du seuil : 4,33 m de haut, elle a un corps sur toute sa
	# hauteur — c'est la seule masse du lieu qu'on ne franchit pas.
	K.collider_box(self, "Pierre_du_seuil_col",
		_seated(float(PIERRE_DU_SEUIL[0]), float(PIERRE_DU_SEUIL[1]))
			+ Vector3(0.0, 2.17, 0.0),
		Vector3(1.02, 4.33, 0.46), float(PIERRE_DU_SEUIL[2]))


## Extrait UNE pièce du GLB des pierres funéraires (recette `_piece_tour` de
## la tour) : élaguée AVANT d'entrer dans l'arbre, et nommée explicitement —
## huit marques tirées de cinq maillages produiraient sinon des homonymes que
## Godot rebaptise `@Node3D@366` (`scripts/CLAUDE.md`).
func _piece_pierre(piece: String, at: Vector3, rot: Vector3,
		nom: String = "") -> Node3D:
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
	_peindre_pierres(instance)
	return instance


## Aplat painterly sur les matériaux du GLB — matériaux DUPLIQUÉS et mis en
## cache, jamais de mutation d'une ressource importée.
func _peindre_pierres(racine: Node3D) -> void:
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
			var cle: String = "cimetiere|%d" % base.get_instance_id()
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
					mat.albedo_color = TEINTES_PIERRES[famille] as Color
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
