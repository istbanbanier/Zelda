## GROTTE DU COUCHANT (`valley.poi.waterfall_cave.01`, r04) — une VRAIE
## cavité : coque extérieure et intérieure fermées, plafond continu, bouche
## sombre, seuil sans marche.
##
## LE NOM AFFICHÉ A CHANGÉ EN R2a-3.1, l'identifiant NON. Le monde ne porte
## aucune cascade compatible avec l'hydrologie V2.2 gelée : « Grotte de la
## cascade » promettait ce qui n'existe pas. Seul `name` bascule dans le
## layout ; l'ID technique, les chemins et les noms de maillages restent —
## une migration de sauvegarde pour un libellé serait un coût sans
## contrepartie.
##
## LES TROIS CONSTANTES D'ALTITUDE CI-DESSOUS SONT MESURÉES, PAS CHOISIES.
## Le sol de la cavité monte par palier vers le fond et se relève encore en
## tablette dans l'alcôve ; deux fichiers décrivent alors la même
## géométrie. `make_waterfall_cave.py` imprime donc la hauteur du sol sous
## chaque point de pose (`[grotte] sol sous …`), et ce sont ces chiffres
## qui sont recopiés ici. Toute modification du profil se relit dans ce
## journal avant de toucher à ces valeurs.
##
## REJET R2a : « enveloppe ouverte, plaques minces, face intérieure
## rectiligne noire, caméra intérieure dans les polygones ». Les quatre
## défauts venaient d'un même endroit — `WorldV2PlaceKit.hollow_rock_mesh()`
## fabriquait la surface artistique en GDScript, par nappes non cousues :
## aucun fond entre les anneaux `inner`/`outer`, secteur bouche entièrement
## sauté (`if open[i] and open[i + 1]: continue`) donc trou vers le ciel
## au-dessus de l'entrée, joues émises à 2 segments seulement avec 2,11 m
## de fente contre la face extérieure, paroi intérieure en UN quad par
## colonne donc réglée — et surtout des colliders dont la face interne
## tombait EXACTEMENT sur `INNER_R` alors que le relief de paroi rentrait
## jusqu'à 0,96 m en deçà : la caméra entrait dans le maillage avant d'être
## arrêtée.
##
## Ce script n'assemble donc plus aucune surface. La coque est un maillage
## Blender unique et fermé (`source_assets/blender/environment/
## make_waterfall_cave.py`), le sol de la salle appartient à son profil, et
## sa collision sort du MÊME loft, rétrécie de 0,40 m latéralement et de
## 0,35 m en clé : la caméra est arrêtée AVANT la paroi visible, jamais
## dessus. Ce fichier ne fait plus qu'implanter, raccorder et éclairer.
##
## IMPLANTATION MESURÉE (`probe_site_section`, pas de 2 m) : plateau plat à
## y = 3,00 sur x ∈ [-118 ; -102], z ∈ [0 ; +9] ; le ressaut monte à l'ouest
## (-120 → 3,1 ; -122 → 4,1 ; -124 → 5,8 ; -126 → 7,6) ; l'affluent coule au
## sud (eau dès z = 10) et descend de 3,0 à 0,5 sur ~14 m — une chute
## d'eau n'existe PAS dans le terrain gelé, et on n'en ajoute pas.
## La masse est donc POSÉE sur le plat et adossée au ressaut : son sol
## intérieur reste au niveau du plateau, et sa queue se fait enterrer par
## l'épaulement qui remonte au nord-ouest (3,7 à (-118, -2), 4,8 à
## (-118, -4)).
##
## VÉGÉTATION : `probe_vegetation_near` à r = 5, 8, 10 et 12 m donne ZÉRO
## instance de MULTIMESH gelé dans un rayon de 10 m du site. L'axe de
## bouche à -14° de la passe précédente esquivait donc des massifs qui ne
## sont pas là, et l'orientation est redevenue libre. Attention toutefois :
## cette sonde ne compte QUE les MultiMesh — des massifs instanciés en
## scènes échappent à son comptage, et une capture d'approche en a montré
## devant la bouche. Le cadre se vérifie donc à l'image, pas seulement au
## compteur.
##
## LUMIÈRE — CONTRE-JOUR ASSUMÉ. Soleil mesuré sur la scène montée :
## propagation (0,8677 ; -0,3907 ; 0,3073), azimut 19,5°, élévation 23,0°,
## donc soleil à l'azimut 199,5°. Le ressaut monte à l'OUEST : la bouche
## regarde forcément l'est, à l'opposé du soleil, et aucun azimut de bouche
## vers l'est n'est éclairable (-0,87 plein est, -0,83 au sud-est, -0,40 au
## nord-est). Le site, lui, est AU SOLEIL — vérifié par lancer de rayon
## contre la coupe du terrain : à 23° le rayon franchit la crête du ressaut
## (10,3 m à x = -130) avec de la marge. C'est donc de l'ombre PROPRE, pas
## de l'ombre portée, et le contraste se construit ainsi : plateau
## ensoleillé devant (clair), crête et flanc ouest ensoleillés au-dessus
## (clairs), collerette en ombre propre (moyen sombre), intérieur plus
## sombre encore. Azimut de bouche retenu : 45° (sud-est), pour trois
## raisons mesurées — la queue du massif s'enterre dans l'épaulement qui
## remonte au nord-ouest au lieu de courir vers l'eau ; la bouche est
## franche face à l'approche depuis le sud-est ET à la descente de
## l'affluent, tous deux dans le même cadre ; et aucune orientation vers
## l'est ne pouvant éclairer la collerette, l'argument lumière est nul
## entre 45° et 315°.
class_name WaterfallCavePlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")
const OUVRAGE: String = "res://assets/environment/caves/SM_WaterfallCave.glb"

## Seuil de la bouche, en LOCAL. Le seuil est donc à (-107,5 ; 6,4) en
## monde. Il était à (-111,0 ; 6,4) au premier jet, et c'était trop à
## l'ouest : la QUEUE de la cavité tombait alors vers (-115,5 ; -2,7), où
## l'épaulement gelé remonte à 3,4 m. Vu en capture — la surface du
## terrain traversait le fond de la salle. Le champ de hauteurs ne se
## creuse pas ; c'est la cavité qui recule. Décalée de 3,5 m vers l'est,
## toute la cavité tient sur le plat à 3,00 (x ∈ [-115 ; -104]) et seul le
## MASSIF, lui, va se faire enterrer par le ressaut.
const SEUIL_LOCAL: Vector2 = Vector2(4.0, -2.5)
## Le modèle sort de la bouche vers son +Z local ; ce lacet l'oriente vers
## le sud-est monde (0,707 ; 0,707).
const LACET_DEG: float = 45.0
## Exhaussement du sol construit au-dessus du terrain gelé. 0,02 au
## premier jet : la CUVETTE du profil (0,08 m) passait alors 6 cm SOUS le
## terrain et, mesuré en capture, l'herbe gelée traversait le sol de la
## salle sur toute sa longueur. 0,11 met le point le plus bas du sol à
## 3,50 pour un terrain à 3,00 — les touffes d’herbe gelées (0,30 m) ne le
## traversent plus. La lèvre du porche, creusée de 0,58 dans le modèle,
## reste enterrée : le mètre de porche devient un seuil de roche que l’on
## monte, à 0,20 m par échantillon — sous la marche maximale du filet.
const EXHAUSSEMENT: float = 0.50

## Points du contour extérieur au niveau du sol, en repère MODÈLE (le
## modèle a son plan de sol à y = 0 et sa galerie vers -Z). Ils servent
## d'appuis déclarés : leur hauteur est lue sur le terrain gelé, donc
## l'écart au sol est nul par construction.
const APPUIS_MODELE: Array[Vector2] = [
	Vector2(3.00, 0.00), Vector2(-3.00, 0.00),
	Vector2(4.24, -2.54), Vector2(-3.76, -3.86),
	Vector2(5.70, -4.55), Vector2(-3.60, -7.95),
	Vector2(5.18, -7.20), Vector2(0.52, -11.30),
]

## Repères de gameplay, en repère MODÈLE.
const MODELE_SEUIL_DEHORS: Vector3 = Vector3(0.0, 0.10, 1.60)
const MODELE_SALLE: Vector3 = Vector3(1.05, 0.22, -6.25)
## LA NICHE A CHANGÉ DE CÔTÉ EN R2a-3.1, et ce n'est pas un déplacement
## décoratif. La revue exigeait une récompense « mise en scène par la
## géométrie et la lumière, pas simplement posée au milieu d'un sol vide » :
## le générateur creuse désormais une ALCÔVE latérale (azimut modèle 180°,
## stations 5 à 7), et le sol de la galerie MONTE vers elle. L'ancienne
## niche (2,50 ; −7,00) était du côté OPPOSÉ, en plein sol.
##
## Une TABLETTE relevée y a été tentée deux fois, à 0,34 puis 0,52 m, et
## retirée : mesurée sur le maillage produit, elle ne relevait rien. Une
## fenêtre d'azimut de 52° est plus étroite que l'écart entre deux sommets
## de la section (40° à 9 facettes) : l'arête droite qui joint ses voisins
## l'efface. La mise en scène tient donc au creux de l'alcôve, à la lampe
## qui la prend de face, et au sol qui s'élève de −0,04 m au seuil à
## +0,33 m au fond. Ce sont les seules valeurs mesurées.
const MODELE_NICHE: Vector3 = Vector3(-1.20, 0.43, -8.20)


func default_place_id() -> StringName:
	return &"valley.poi.waterfall_cave.01"


func _build() -> void:
	var assise: float = ground_local_y(SEUIL_LOCAL.x, SEUIL_LOCAL.y) + EXHAUSSEMENT
	var ouvrage: Node3D = _poser_ouvrage(
		Vector3(SEUIL_LOCAL.x, assise, SEUIL_LOCAL.y))

	# Repères lus par le filet de comportement : il MARCHE en ligne droite
	# du seuil à l'intérieur et exige 1,75 m de hauteur libre tous les
	# 0,40 m. La galerie s'infléchit de ~31°, mais la corde d'un arc de
	# cette ouverture sur 6,25 m ne s'écarte que de 0,30 m de l'axe, pour
	# une demi-largeur minimale de 1,55 m : la corde reste dans la galerie
	# avec plus de 2,7 m sous la clé.
	var transformation: Transform3D = ouvrage.transform
	set_meta(&"cave_threshold", transformation * MODELE_SEUIL_DEHORS)
	set_meta(&"cave_interior", transformation * MODELE_SALLE)

	for point: Vector2 in APPUIS_MODELE:
		var au_sol: Vector3 = transformation * Vector3(point.x, 0.0, point.y)
		declare_support(Vector3(au_sol.x,
			ground_local_y(au_sol.x, au_sol.z), au_sol.z))

	_eclairer(ouvrage)
	_habiller(transformation)

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Grotte de la cascade"
	poi.region = "r04_falaises_du_couchant"
	var forme: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 12.0
	forme.shape = sphere
	poi.add_child(forme)
	add_child(poi)

	# La récompense est APRÈS le coude : la poche paie d'être entrée, et
	# elle ne se voit pas depuis le seuil.
	var niche: Vector3 = transformation * MODELE_NICHE
	var approche: Vector3 = (transformation * MODELE_SALLE) - niche
	RewardAnchor.attach(self, default_place_id(), RewardAnchor.Kind.INGREDIENT,
		niche, approche.normalized())


## Instancie la coque, en extrait la collision, libère le maillage de
## collision (il ne doit ni se rendre ni compter comme surface visible).
func _poser_ouvrage(local: Vector3) -> Node3D:
	var paquet: PackedScene = load(OUVRAGE) as PackedScene
	var ouvrage: Node3D = paquet.instantiate() as Node3D
	ouvrage.name = "Coque"
	ouvrage.position = local
	ouvrage.rotation.y = deg_to_rad(LACET_DEG)
	add_child(ouvrage)

	for noeud: Node in ouvrage.find_children("COL_*", "MeshInstance3D", true, false):
		var proxy: MeshInstance3D = noeud as MeshInstance3D
		if proxy.mesh == null:
			continue
		var corps: StaticBody3D = StaticBody3D.new()
		corps.name = "CollisionCoque"
		corps.collision_layer = 1
		corps.collision_mask = 0
		var forme: CollisionShape3D = CollisionShape3D.new()
		forme.name = "CollisionCoque_forme"
		var concave: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
		concave.set_faces(proxy.mesh.get_faces())
		# `backface_collision` reste FAUX, et ce n'est pas un détail : la
		# coque étant un manifold fermé réorienté par
		# `recalc_face_normals`, ses faces intérieures regardent la salle
		# et ses faces extérieures regardent dehors. On obtient donc d'un
		# coup la collision par l'intérieur ET par l'extérieur — et un
		# rayon descendant depuis au-dessus du plafond le traverse sans
		# s'y accrocher, ce dont dépend `_ground_at()` du filet de
		# comportement pour trouver le SOL de la salle et non sa voûte.
		concave.backface_collision = false
		forme.shape = concave
		corps.add_child(forme)
		ouvrage.add_child(corps)
		corps.transform = proxy.transform
		proxy.queue_free()
	return ouvrage


## Deux sources, pas plus, toutes deux motivées par le jour qui entre —
## le soleil, lui, n'entre pas : la bouche est à 146° de lui.
##
## Les deux portent leurs OMBRES. Sans elles, un omni de 5 à 7 m de portée
## traverse une paroi de 0,9 à 2,5 m et pose une tache claire sur la face
## EXTÉRIEURE du rocher. Avec elles, la lumière reste dans la cavité et ne
## ressort que par la bouche, ce qui est le sens voulu.
func _eclairer(ouvrage: Node3D) -> void:
	var seuil: OmniLight3D = OmniLight3D.new()
	seuil.name = "JourDuSeuil"
	seuil.light_color = Color(1.0, 0.93, 0.83)
	seuil.light_energy = 0.50
	seuil.omni_range = 5.5
	seuil.omni_attenuation = 1.6
	seuil.shadow_enabled = true
	seuil.position = Vector3(0.20, 1.50, -2.60)
	ouvrage.add_child(seuil)

	# Le coude est ce qui permet d'avoir À LA FOIS une bouche noire et une
	# salle lisible : cette source vit APRÈS lui, donc elle n'est pas vue
	# depuis le plateau. Froide et faible — c'est du ciel replié, pas un
	# projecteur de studio.
	var salle: OmniLight3D = OmniLight3D.new()
	salle.name = "CielReplie"
	salle.light_color = Color(0.80, 0.86, 0.95)
	salle.light_energy = 0.42
	salle.omni_range = 6.5
	salle.omni_attenuation = 1.4
	salle.shadow_enabled = true
	# Placée ENTRE la salle et l'alcôve, pas dans l'alcôve. Mesuré en
	# capture : au-dessus de la tablette, la lampe prenait la récompense à
	# contre-jour et la noyait dans l'ombre de sa propre niche. Une
	# récompense en scène est une récompense que la lumière désigne DE
	# FACE.
	salle.position = Vector3(0.20, 1.90, -7.20)
	ouvrage.add_child(salle)


## Habillage vivant, HORS coque : le champignon de la récompense sur le sol
## CONSTRUIT (3,02 en monde, pas le terrain à 3,00 — dix centimètres
## d'écart suffiraient à l'enfoncer), et deux fougères d'ombre au pied de
## la collerette, posées hors de l'axe d'entrée.
func _habiller(transformation: Transform3D) -> void:
	var niche: Vector3 = transformation * MODELE_NICHE
	K.module(self, &"Mushroom_Common", niche, 24.0, 1.15, K.TONE_PLANT)
	var voisin: Vector3 = transformation * Vector3(-1.60, 0.55, -8.20)
	K.module(self, &"Mushroom_Common", voisin, 200.0, 0.9, K.TONE_PLANT)
	# LES DEUX FOUGÈRES MASQUAIENT LA BOUCHE, ET C'ÉTAIT MOI.
	#
	# La revue les a prises — comme moi — pour de la végétation V2.2 gelée.
	# Mesuré : 810 cellules de semis, aucune instance florale à moins de
	# 24 m, et ce qui occupe l'objectif à 8,2 m et 9,7 m de profondeur sur
	# la vue d'approche, ce sont ces deux `Fern_1` que ce script plante
	# lui-même. Le modèle du kit porte de hautes hampes jaunes d'environ
	# 1,5 m ; posées à (3,35 ; 1,20) et (−3,20 ; 1,60), c'est-à-dire juste
	# devant le seuil, elles couvraient le tiers bas de l'ouverture.
	#
	# Elles reculent donc derrière le plan de la bouche et s'écartent : la
	# ligne de vue depuis le sud-est est libre, et elles habillent le pied
	# de la formation au lieu de la cacher. Aucune végétation gelée n'a été
	# touchée — il n'y en avait pas.
	# CORRIGÉ APRÈS CAPTURE : mes premières valeurs les mettaient DANS la
	# galerie. Dans ce repère la galerie va vers −Z ; reculer une plante
	# « derrière le plan de la bouche » demande donc un z POSITIF, pas
	# négatif. Elles flanquent maintenant l'entrée à plus de 3,8 m de la
	# ligne de visée, qui passe par (−0,4 ; 2,4) en repère modèle.
	for cote: Array in [[4.60, 2.40, 15.0], [-4.20, 2.20, 165.0]]:
		var pied: Vector3 = transformation * Vector3(
			float(cote[0]), 0.0, float(cote[1]))
		K.module(self, &"Fern_1",
			Vector3(pied.x, ground_local_y(pied.x, pied.z), pied.z),
			float(cote[2]), 1.0, K.TONE_PLANT)
