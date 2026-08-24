## LE CHAMP DES MILLE FLEURS (`valley.poi.flower_field.01`, r02) — la
## respiration, et le premier lieu que le joueur atteindra.
##
## REWORK LOT 1.R (voie C). Le verdict Codex sur la version précédente :
## « dans la vue joueur, le champ n'est pas le sujet » — un rocher sombre
## au centre du cadre, le bâti de la ferme derrière, et des fleurs en
## saupoudrage. La corrective inverse la hiérarchie, sans changer ni le
## site, ni la fonction, ni la récompense :
##
##  1. **Le champ devient la matière du premier plan** : trois NAPPES
##     florales instanciées (`MultiMeshInstance3D`, un nœud visuel par
##     nappe) — blanche au cœur du lieu, jaune sur le flanc sud et au
##     premier plan, bleue plus loin en accent rare (bible §1.4 : fleurs
##     par groupes, jamais un semis uniforme ; le bleu reste plus sombre
##     que l'électricité). Chaque nappe pousse en PHRASES de 3 à 8 avec
##     des clairières de 2 à 6 m — le vide est le rythme, pas un oubli.
##  2. **Le cheminement se lit** : une VOIE CONTINUE traverse le champ du
##     sud-est au nord-ouest, pavée de dalles à demi avalées presque
##     jointives, et les fleurs s'écartent de sa bande pendant qu'un ourlet
##     d'herbes hautes la borde — on voit le chemin PARCE QUE le champ
##     l'évite.
##  3. **La Porte des fleurs** (composition B, `CONCEPTION_champ.md`,
##     arbitrage lead RENDU : B retenue ; A = commit 78767e8) : deux stèles
##     pâles et inégales, penchées l'une vers l'autre, encadrent la voie
##     juste après la fourche. L'élément héroïque du lieu, sa promesse à
##     distance, et sa signature de silhouette — le monolithe SOMBRE du
##     rejet Codex, lui, a disparu. Le village reste un arrière-plan : il
##     est gelé, à 32 m.
##
## DEUXIÈME CORRECTIVE (inspection du lead sur les captures `apres/`) —
## deux défauts mesurés, deux causes distinctes, deux gestes :
##
##  * **Le chemin ne se lisait pas comme un chemin.** Neuf dalles espacées
##    de 2 à 4 m sur trois brins donnaient « trois ou quatre POCHES
##    disjointes », et la poche du premier plan lisait « placette ». Une
##    ligne continue, même clairsemée, se lit ; quatre paquets non. Les
##    dalles quittent donc `K.module()` pour deux `MultiMeshInstance3D`
##    qui PAVENT la polyligne à pas serré (~0,8 m, dalles de 0,7-0,9 m,
##    jeu latéral) : la voie devient une ligne, elle TRAVERSE le champ de
##    bout en bout, et elle coûte 0 module au lieu de 9.
##  * **La Porte ne se lisait pas comme une porte.** `rock_largeA` dressé
##    sur chant est une dalle à très peu de GRANDES FACES PLANES : la
##    petite présentait sa face au soleil et rendait un blanc plat sans
##    matière, la grande présentait la sienne au ciel et redevenait
##    l'objet le plus sombre du cadre — le défaut d'origine. Le MÊME
##    albédo produisant les deux défauts opposés, la cause est la loi de
##    forme, pas la teinte : aucune valeur ne répare une face plane de
##    2 m. Les deux pierres sont donc un GLB dédié
##    (`SM_FlowerField_Steles.glb`, 1 008 tris, source Blender
##    reproductible) : section élancée, cannelures verrouillées sur
##    l'azimut, phase d'échantillonnage tournante — aucune facette ne
##    dépasse 0,010 m², donc aucun aplat possible.
##
## Le vent des nappes est la grammaire V2.2 (`foliage_wind.gdshader`,
## relu jamais modifié) portée sur maillage texturé :
## `SH_FlowerFieldSway.gdshader`, LOCAL à ce lieu. Phase par position
## monde, variation par instance via COLOR — la V2.2 ne pose pas de
## custom data, ce lieu non plus.
##
## Plantations UNIQUEMENT dans cette scène : le semis V2.2 global et ses
## masques restent gelés. Toute TEINTE ci-dessous a été jugée sur capture
## rendue (gain ≈ 1,8 non linéaire — scripts/CLAUDE.md), pas sur l'albédo.
class_name FlowerFieldPlace
extends WorldV2Place

const K: GDScript = preload("res://scripts/world_v2/poi/world_v2_place_kit.gd")
const SWAY_SHADER: String = \
	"res://shaders/world_v2/poi/SH_FlowerFieldSway.gdshader"

## Graine unique du lieu — deux montages plantent le même champ.
const GRAINE: int = 20260824

## Pierre pâle des dalles : la valeur claire du lieu, celle qui dessine la
## fourche dans le vert. Reste sous la bande haute de `VISUAL_ASSET_BIBLE`
## §1.5 — une dalle plus claire que le ciel tirerait l'œil hors de la
## composition (leçon ISS-037 du chemin de terre).
const TONE_DALLE: Color = Color(0.88, 0.86, 0.79)
## Feuillage des nappes : l'olive painterly commun (§1.4), identique au
## ton végétal du kit — les tiges appartiennent à la même prairie.
const TONE_FEUILLES: Color = Color(0.60, 0.63, 0.50)
## Pétales. MESURÉ sur capture iter1 : l'atlas Quaternius ne porte que du
## ROSE (Flower_3) et du JAUNE (Flower_4) — la bible §1.4 demande
## blanc/jaune/bleu. Blanc et bleu sont donc obtenus par DÉSATURATION du
## rose puis recoloration (le shader local le permet) ; le jaune reste
## natif. Le bleu reste assourdi, loin du cyan électrique.
const TONE_PETALE_NATIF: Color = Color(1.0, 1.0, 1.0)
const TONE_PETALE_BLANC: Color = Color(1.50, 1.50, 1.42)
const TONE_PETALE_BLEU: Color = Color(0.55, 0.65, 1.25)
## L'ourlet d'herbes. Deux échecs symétriques déjà mesurés, et la valeur
## retenue est entre les deux : l'olive des feuillages (0,60/0,63/0,50) le
## rendait MARRON BRÛLÉ (iter1, gros plan chemin) ; l'éclaircissement à
## 1,12/1,06/0,88 le rendait BLANC-MENTHE sur les deux vues APRÈS (constat
## du lead). Cette valeur reste sous 1 — elle n'amplifie plus l'atlas — et
## descend franchement le bleu : de la paille dorée, pas de la menthe.
const TONE_PAILLE: Color = Color(0.95, 0.84, 0.55)

## LA VOIE, en polyligne locale.
##
## `CHEMIN_VENUE` + `CHEMIN_NO` forment UNE SEULE LIGNE CONTINUE de ~26 m
## qui TRAVERSE le champ : elle entre au sud-est (d'où le joueur arrive),
## passe la fourche, franchit la Porte et ressort au nord-ouest vers la
## rivière. C'est la correction du défaut mesuré par le lead : « une ligne
## continue, même clairsemée, se lit ; quatre paquets ne se lisent pas ».
## Les deux brins sont donc allongés aux DEUX bouts — un chemin qui commence
## et finit dans le cadre est une placette, pas une voie.
##
## `CHEMIN_SO` reste la branche secondaire vers la ferme : plus courte, et
## pavée à pas plus lâche (voir `_paver`), pour qu'elle se lise comme un
## embranchement et non comme une seconde voie qui disputerait la lecture.
## Les deux bouts sont resserrés d'un mètre par rapport au premier jet
## (11,4/-10,9) : à cette longueur l'emprise du lieu passait à 25,3 m et la
## capture de silhouette RATAIT son plancher — le sujet n'occupait plus que
## 1,8 % de l'image contre 2,0 % exigés, parce que le cadrage orthogonal se
## règle sur la plus grande largeur. La voie traverse toujours le champ de
## bout en bout (~24 m de polyligne) ; c'est le cadre de preuve qui a une
## limite, pas la composition.
const CHEMIN_VENUE: Array[Vector2] = [
	Vector2(10.2, 9.9), Vector2(8.8, 8.8), Vector2(7.4, 7.4),
	Vector2(4.6, 4.6), Vector2(2.4, 2.6), Vector2(0.6, 1.4),
]
const CHEMIN_NO: Array[Vector2] = [
	Vector2(0.6, 1.4), Vector2(-2.8, -1.4), Vector2(-5.4, -3.2),
	Vector2(-8.2, -5.4), Vector2(-9.8, -6.4),
]
const CHEMIN_SO: Array[Vector2] = [
	Vector2(0.6, 1.4), Vector2(-1.4, 4.4), Vector2(-3.6, 7.0),
	Vector2(-5.8, 9.4),
]
## Pas de pavage le long de l'axe, en mètres. Les dalles font 0,7 à 0,9 m
## une fois mises à l'échelle : à ce pas elles laissent 0,1 à 0,3 m de vert
## entre elles — l'œil ferme la ligne. Le pas de 2 à 4 m de la version
## précédente laissait 1,5 à 3 m, et l'œil lisait des cailloux isolés.
const PAVAGE_PAS_M: float = 0.82
const PAVAGE_PAS_SECONDAIRE_M: float = 1.30
## Demi-largeur de la bande où les fleurs s'écartent du chemin. Élargie
## d'un cran après iter1 : à 1,15 m la voie se refermait à l'image.
const CHEMIN_DEGAGE_M: float = 1.35

## Points de vue à ne pas boucher (coordonnées LOCALES au lieu — jamais le
## site) : l'œil joueur du plan gelé et le gros plan « nappe au ras du
## sol ». [x, z, rayon].
const OEILS_DEGAGES: Array[Vector3] = [
	Vector3(4.8, 8.2, 2.1),
	Vector3(2.0, -5.2, 1.0),
]

## LA PORTE DES FLEURS (composition B du brief CONCEPTION_champ.md,
## RETENUE par l'arbitrage lead ; A = commit 78767e8).
##
## GLB DÉDIÉ depuis la seconde corrective : `SM_FlowerField_Steles.glb`
## porte `SM_Stele_Grande` (2,16 m) et `SM_Stele_Petite` (1,28 m), générées
## par `source_assets/blender/environment/make_flower_field_steles.py` et
## exportées par `tools/lot1r_export_stele.sh`. L'essai en kit rescalé —
## autorisé comme premier essai par la condition n°1 du lead — a été fait
## et REJETÉ sur capture ; le fichier de génération porte le diagnostic.
##
## PLACEMENT — c'est la VUE JOUEUR qui juge, et elle a une géométrie.
## L'œil du plan gelé est en local (4,8 · 8,2) et vise (0 · 0) : son axe
## traverse la voie juste après la fourche. La version précédente posait la
## grande pierre à 0,10 m de cet axe — d'où « l'objet le plus sombre près du
## centre du cadre ». Les deux stèles ENCADRENT donc l'axe au lieu de s'y
## asseoir : la grande à ~1,0 m d'un côté, la petite à ~1,9 m de l'autre, la
## voie passant entre les deux. [x, z, rayon d'écart des fleurs].
const PORTE_GRANDE: Vector3 = Vector3(0.661, -0.752, 1.35)
const PORTE_PETITE: Vector3 = Vector3(-1.247, 1.564, 1.05)
## Chemin du GLB des deux stèles.
const STELES_GLB: String = "res://assets/environment/rocks/SM_FlowerField_Steles.glb"
## Cap des faces larges : perpendiculaire à la voie au point de Porte, pour
## que le passant voie deux PLATS dressés et non deux tranches.
const PORTE_CAP_DEG: float = 50.5

var _emprise_min_x: Vector2 = Vector2.ZERO
var _emprise_max_x: Vector2 = Vector2.ZERO
var _emprise_min_z: Vector2 = Vector2.ZERO
var _emprise_max_z: Vector2 = Vector2.ZERO
var _emprise_vierge: bool = true
var _maillages: Dictionary = {}


func default_place_id() -> StringName:
	return &"valley.poi.flower_field.01"


func _build() -> void:
	# — LA PORTE DES FLEURS. Deux dalles de falaise dressées sur chant,
	# inégales et penchées l'une vers l'autre, de part et d'autre de la
	# branche nord-ouest : l'élément héroïque du lieu (ADDENDUM_DA), la
	# promesse visible à 80-120 m, et la signature de silhouette (deux
	# pics inégaux sur bande basse) qu'aucun autre sujet du corpus ne
	# porte. Pâles et fines — jamais le monolithe sombre du rejet Codex.
	var pied_grande: Vector3 = _seated(PORTE_GRANDE.x, PORTE_GRANDE.y)
	# Penchée VERS la voie (la petite est de l'autre côté) : les deux têtes
	# se rapprochent au-dessus du passage sans jamais se toucher.
	_planter_stele("Porte_grande", &"SM_Stele_Grande", pied_grande,
		PORTE_CAP_DEG - 9.0, Vector2(-0.636, 0.772), 17.0, 1.0, 0.06)
	declare_support(pied_grande)
	_note_emprise(Vector2(PORTE_GRANDE.x, PORTE_GRANDE.y))
	K.collider_box(self, "Porte_grande_col",
		pied_grande + Vector3(0.0, 1.02, 0.0), Vector3(0.78, 2.05, 0.44),
		PORTE_CAP_DEG - 9.0)
	var pied_petite: Vector3 = _seated(PORTE_PETITE.x, PORTE_PETITE.y)
	_planter_stele("Porte_petite", &"SM_Stele_Petite", pied_petite,
		PORTE_CAP_DEG + 14.0, Vector2(0.636, -0.772), 15.0, 0.95, 0.05)
	declare_support(pied_petite)
	_note_emprise(Vector2(PORTE_PETITE.x, PORTE_PETITE.y))
	K.collider_box(self, "Porte_petite_col",
		pied_petite + Vector3(0.0, 0.64, 0.0), Vector3(0.58, 1.30, 0.36),
		PORTE_CAP_DEG + 14.0)

	# — LA VOIE. Le lead a mesuré sur les captures `apres/` que neuf dalles
	# espacées de 2 à 4 m rendaient « trois ou quatre POCHES disjointes »,
	# et non un chemin. Le pavage est donc SERRÉ et CONTINU, et il quitte
	# `K.module()` pour deux `MultiMeshInstance3D` : neuf modules libérés,
	# quarante-et-quelques dalles posées, un seul nœud visuel par modèle.
	# Toutes ENFONCÉES de quatre à huit centimètres — une dalle à demi
	# avalée se lit ancienne. Aucune ne porte de collider : un chemin se
	# marche.
	_paver()
	declare_support(_seated(8.8, 8.8))
	declare_support(_seated(-5.4, -3.2))
	declare_support(_seated(-3.6, 7.0))

	# — DEUX BUISSONS derrière la petite stèle : la masse intermédiaire
	# entre les fleurs (0,4 m) et la Porte (1,3-2,1 m). Le second, cédé au
	# budget quand les dalles coûtaient neuf modules, revient : le pavage
	# en MultiMesh les a tous rendus.
	K.module(self, &"Bush_Common_Flowers", _seated(-3.1, 3.0), 52.0, 0.70,
		K.TONE_PLANT)
	K.module(self, &"Bush_Common_Flowers", _seated(-5.6, 1.1), -24.0, 0.55,
		K.TONE_PLANT)

	# — LES NAPPES. Le sujet du lieu. Trois couleurs, trois masses, des
	# clairières — et la bande du chemin qui reste vide de bout en bout.
	#
	# Blanche : le cœur du champ, à droite et devant la fourche —
	# pétales roses natifs DÉSATURÉS puis éclaircis (§1.4 : blanc).
	_nappe("Nappe_blanche", &"Flower_3_Group", TONE_PETALE_BLANC, 1.0, 11,
		Vector2(-1.0, -4.5), Vector2(8.0, 5.5), 300,
		[Vector3(-4.5, -7.5, 2.2), Vector3(3.2, -6.8, 1.8)])
	# Jaune : le flanc sud — et la poche de premier plan au pied du
	# joueur, celle qui met des fleurs dans le bas du cadre dès la
	# première seconde.
	_nappe("Nappe_jaune", &"Flower_4_Group", TONE_PETALE_NATIF, 0.0, 23,
		Vector2(-4.2, 6.0), Vector2(5.8, 4.2), 150,
		[Vector3(-8.2, 7.6, 1.9)])
	_nappe("Nappe_jaune_avant", &"Flower_4_Group", TONE_PETALE_NATIF, 0.0, 31,
		Vector2(6.6, 3.4), Vector2(2.6, 2.2), 40, [])
	# Bleue : l'accent rare, au-delà de la Porte — sortie de l'ombre portée
	# de la crête ouest (iter1 : elle y rendait violet éteint). RESSERRÉE :
	# à 4,2 m de rayon depuis x = -8,6 elle atteignait x = -12,8 et devenait
	# la pièce la plus à l'ouest du lieu — c'est ELLE, et non la voie, qui
	# poussait l'emprise à 24 m et faisait rater son plancher à la capture
	# de silhouette. Un accent rare n'a pas besoin d'être le point extrême.
	_nappe("Nappe_bleue", &"Flower_3_Group", TONE_PETALE_BLEU, 1.0, 47,
		Vector2(-7.6, 0.4), Vector2(3.5, 3.0), 70, [])
	# L'ourlet d'herbes hautes : il borde le chemin des deux côtés — c'est
	# lui qui raconte « l'herbe s'ouvre » sans toucher au semis gelé.
	_ourlet_chemin("Ourlet_herbes", &"Grass_Wispy_Tall", 59)

	# — APPUIS DE COUVERTURE : les extrémités RÉELLES de l'emprise plantée
	# (D2 : tout axe > 6 m exige un appui dans le tiers bas ET le tiers
	# haut). Chaque point est assis par la fonction de sol : l'écart est
	# nul par construction.
	if not _emprise_vierge:
		declare_support(_seated(_emprise_min_x.x, _emprise_min_x.y))
		declare_support(_seated(_emprise_max_x.x, _emprise_max_x.y))
		declare_support(_seated(_emprise_min_z.x, _emprise_min_z.y))
		declare_support(_seated(_emprise_max_z.x, _emprise_max_z.y))

	var poi: PointOfInterest = PointOfInterest.new()
	poi.name = "Decouverte"
	poi.poi_id = default_place_id()
	poi.display_name = "Le Champ des mille fleurs"
	poi.region = &"r02_prairie_mille_fleurs"
	var shape: CollisionShape3D = CollisionShape3D.new()
	shape.name = "Decouverte_forme"
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 14.0
	shape.shape = sphere
	poi.add_child(shape)
	add_child(poi)
	# L'herbe d'endurance pousse AU PIED DE LA GRANDE STÈLE, du côté abrité
	# — celui qui n'est pas sur la voie. La récompense reste au moment du
	# choix de route, et la Porte lui donne son ombre : elle appartient au
	# lieu, pas à un coffre posé là. Suit la stèle dans son déplacement.
	RewardAnchor.attach(self, default_place_id(),
		RewardAnchor.Kind.INGREDIENT,
		_seated(PORTE_GRANDE.x + 0.57, PORTE_GRANDE.y - 0.69)
			+ Vector3(0.0, 0.1, 0.0), Vector3(1.2, 0.0, 1.2))


## Une nappe florale : phrases de 3 à 8 fleurs autour de centres tirés dans
## une ellipse, clairières et chemin respectés, un seul nœud visuel.
func _nappe(nom: String, modele: StringName, petale: Color, desat: float,
		graine: int, centre: Vector2, rayons: Vector2, cible: int,
		clairieres: Array[Vector3]) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([GRAINE, graine, nom])
	var transforms: Array[Transform3D] = []
	var essais: int = 0
	while transforms.size() < cible and essais < cible * 40:
		essais += 1
		var cx: float = centre.x + rng.randf_range(-1.0, 1.0) * rayons.x
		var cz: float = centre.y + rng.randf_range(-1.0, 1.0) * rayons.y
		if not _dans_ellipse(cx, cz, centre, rayons):
			continue
		if not _degage(Vector2(cx, cz), clairieres):
			continue
		var phrase: int = rng.randi_range(3, 8)
		for i: int in range(phrase):
			if transforms.size() >= cible:
				break
			var px: float = cx + rng.randf_range(-1.3, 1.3)
			var pz: float = cz + rng.randf_range(-1.3, 1.3)
			if not _dans_ellipse(px, pz, centre, rayons):
				continue
			if not _degage(Vector2(px, pz), clairieres):
				continue
			var echelle: float = KitScale.factor(String(modele)) \
				* rng.randf_range(0.69, 0.99)
			transforms.append(_pose(px, pz, rng.randf() * TAU, echelle, -0.05))
			_note_emprise(Vector2(px, pz))
	_semer(nom, modele, petale, desat, TONE_FEUILLES, transforms, rng)


## L'ourlet du chemin : herbes hautes à 0,7-1,3 m de l'axe, par touffes
## espacées, jamais un rail continu.
func _ourlet_chemin(nom: String, modele: StringName, graine: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([GRAINE, graine, nom])
	var transforms: Array[Transform3D] = []
	for brin: Array[Vector2] in [CHEMIN_VENUE, CHEMIN_NO, CHEMIN_SO]:
		for i: int in range(brin.size() - 1):
			var a: Vector2 = brin[i]
			var b: Vector2 = brin[i + 1]
			var pas: int = maxi(2, int(a.distance_to(b) / 1.1))
			for s: int in range(pas + 1):
				# Porte aléatoire : un ourlet troué se lit naturel.
				if rng.randf() < 0.28:
					continue
				var t: float = float(s) / float(pas)
				var axe: Vector2 = a.lerp(b, t)
				var direction: Vector2 = (b - a).normalized()
				var normale: Vector2 = Vector2(-direction.y, direction.x)
				var cote: float = 1.0 if rng.randf() < 0.5 else -1.0
				var p: Vector2 = axe + normale * cote \
					* rng.randf_range(0.65, 1.15)
				if not _degage(p, [], 0.55):
					continue
				var echelle: float = KitScale.factor(String(modele)) \
					* rng.randf_range(0.75, 1.05)
				transforms.append(_pose(p.x, p.y, rng.randf() * TAU,
					echelle, -0.05))
				_note_emprise(p)
	_semer(nom, modele, TONE_PETALE_NATIF, 0.0, TONE_PAILLE, transforms, rng)


## Matérialise une liste de poses en UN `MultiMeshInstance3D`, avec le plan
## de plantation en méta — même contrat que la végétation V2.2 : le
## headless prouve le plan, la capture prouve le rendu.
func _semer(nom: String, modele: StringName, petale: Color, desat: float,
		feuilles: Color, transforms: Array[Transform3D],
		rng: RandomNumberGenerator) -> void:
	if transforms.is_empty():
		push_error("[flower_field] nappe %s : aucune pose plantée" % nom)
		return
	var maillage: Mesh = _maillage_nappe(modele, petale, desat, feuilles)
	if maillage == null:
		return
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = maillage
	mm.instance_count = transforms.size()
	var origins: PackedVector3Array = PackedVector3Array()
	var scales: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(transforms.size()):
		mm.set_instance_transform(i, transforms[i])
		var luma: float = rng.randf_range(0.86, 1.10)
		mm.set_instance_color(i, Color(luma * rng.randf_range(0.97, 1.03),
			luma, luma * rng.randf_range(0.95, 1.05)))
		origins.append(transforms[i].origin)
		scales.append(transforms[i].basis.get_scale().x)
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = nom
	instance.multimesh = mm
	instance.set_meta(&"instance_origins", origins)
	instance.set_meta(&"instance_scales", scales)
	add_child(instance)


## Maillage d'un modèle de kit, DUPLIQUÉ, chaque surface passée au shader
## de vent local : pétales teintés, feuilles olive. On ne mute jamais la
## ressource partagée.
func _maillage_nappe(modele: StringName, petale: Color, desat: float,
		feuilles: Color) -> Mesh:
	var cle: String = "%s|%s|%.2f|%s" % [modele, petale.to_html(false),
		desat, feuilles.to_html(false)]
	if _maillages.has(cle):
		return _maillages[cle] as Mesh
	var packed: PackedScene = K.scene_for(modele)
	if packed == null:
		push_error("[flower_field] modèle inconnu %s" % modele)
		return null
	var noeud: Node = packed.instantiate()
	var source: Mesh = _premier_maillage(noeud)
	var maillage: Mesh = null
	if source != null:
		maillage = source.duplicate() as Mesh
		var natif: float = maillage.get_aabb().size.y
		for s: int in range(maillage.get_surface_count()):
			var base: StandardMaterial3D = \
				maillage.surface_get_material(s) as StandardMaterial3D
			if base == null:
				continue
			var mat: ShaderMaterial = ShaderMaterial.new()
			mat.shader = load(SWAY_SHADER) as Shader
			mat.set_shader_parameter(&"atlas", base.albedo_texture)
			var est_petale: bool = base.resource_name.findn("flower") >= 0
			mat.set_shader_parameter(&"tone", petale if est_petale else feuilles)
			mat.set_shader_parameter(&"desaturation",
				desat if est_petale else 0.0)
			mat.set_shader_parameter(&"mesh_height", maxf(natif, 0.001))
			mat.set_shader_parameter(&"sway_amplitude", 0.22)
			maillage.surface_set_material(s, mat)
	noeud.free()
	_maillages[cle] = maillage
	return maillage


func _premier_maillage(noeud: Node) -> Mesh:
	if noeud is MeshInstance3D and (noeud as MeshInstance3D).mesh != null:
		return (noeud as MeshInstance3D).mesh
	for enfant: Node in noeud.get_children():
		var trouve: Mesh = _premier_maillage(enfant)
		if trouve != null:
			return trouve
	return null


## Vrai si le point est hors de la bande du chemin, hors des yeux dégagés,
## hors de l'emprise de la pierre et hors des clairières demandées.
func _degage(p: Vector2, clairieres: Array[Vector3],
		marge_chemin: float = CHEMIN_DEGAGE_M) -> bool:
	for brin: Array[Vector2] in [CHEMIN_VENUE, CHEMIN_NO, CHEMIN_SO]:
		for i: int in range(brin.size() - 1):
			var proche: Vector2 = Geometry2D.get_closest_point_to_segment(
				p, brin[i], brin[i + 1])
			if p.distance_to(proche) < marge_chemin:
				return false
	for oeil: Vector3 in OEILS_DEGAGES:
		if p.distance_to(Vector2(oeil.x, oeil.y)) < oeil.z:
			return false
	for porte: Vector3 in [PORTE_GRANDE, PORTE_PETITE]:
		if p.distance_to(Vector2(porte.x, porte.y)) < porte.z:
			return false
	for clairiere: Vector3 in clairieres:
		if p.distance_to(Vector2(clairiere.x, clairiere.y)) < clairiere.z:
			return false
	return true


func _dans_ellipse(x: float, z: float, centre: Vector2,
		rayons: Vector2) -> bool:
	var dx: float = (x - centre.x) / rayons.x
	var dz: float = (z - centre.y) / rayons.y
	return dx * dx + dz * dz <= 1.0


func _pose(x: float, z: float, yaw: float, echelle: float,
		enfonce: float) -> Transform3D:
	var basis: Basis = Basis(Vector3.UP, yaw).scaled(Vector3.ONE * echelle)
	return Transform3D(basis,
		Vector3(x, ground_local_y(x, z) + enfonce, z))


## Note un point planté pour la couverture d'appuis (D2) : on retient les
## quatre extrêmes RÉELS de l'emprise, pas une boîte supposée.
func _note_emprise(p: Vector2) -> void:
	if _emprise_vierge:
		_emprise_min_x = p
		_emprise_max_x = p
		_emprise_min_z = p
		_emprise_max_z = p
		_emprise_vierge = false
		return
	if p.x < _emprise_min_x.x:
		_emprise_min_x = p
	if p.x > _emprise_max_x.x:
		_emprise_max_x = p
	if p.y < _emprise_min_z.y:
		_emprise_min_z = p
	if p.y > _emprise_max_z.y:
		_emprise_max_z = p


## PAVE LA VOIE. Deux `MultiMeshInstance3D` — un par modèle de dalle —
## qui suivent la polyligne à pas serré.
##
## POURQUOI PAS `K.module()`. Neuf dalles espacées de 2 à 4 m coûtaient
## neuf des douze modules du micro-POI ET ne se lisaient pas : le lead a
## mesuré « trois ou quatre POCHES disjointes » sur la vue identité et une
## « placette » au premier plan de la vue joueur. Densifier en modules était
## impossible (budget), densifier en MultiMesh est gratuit au budget — un
## MultiMesh est un seul nœud visuel et zéro module. Le pavage passe de 9 à
## une quarantaine de dalles pour 0 module.
##
## Les deux modèles ALTERNENT le long de l'axe : un pavage d'un seul modèle
## répété tous les 0,8 m se lit comme une frise mécanique.
func _paver() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([GRAINE, 71, "voie"])
	# La voie principale est UNE polyligne : venue + branche nord-ouest
	# partagent le sommet de fourche, qu'on ne compte qu'une fois.
	var principale: Array[Vector2] = []
	principale.append_array(CHEMIN_VENUE)
	for i: int in range(1, CHEMIN_NO.size()):
		principale.append(CHEMIN_NO[i])

	var carres: Array[Transform3D] = []
	var ronds: Array[Transform3D] = []
	var bascule: int = 0
	for brin: Array in [[principale, PAVAGE_PAS_M],
			[CHEMIN_SO, PAVAGE_PAS_SECONDAIRE_M]]:
		var polyligne: Array[Vector2] = brin[0] as Array[Vector2]
		var pas: float = float(brin[1])
		for point: Vector2 in _semis_de_voie(polyligne, pas, rng):
			var echelle: float = rng.randf_range(0.72, 0.94)
			var enfonce: float = rng.randf_range(-0.08, -0.04)
			var pose: Transform3D = _pose(point.x, point.y,
				rng.randf() * TAU, echelle, enfonce)
			if bascule % 2 == 0:
				carres.append(pose)
			else:
				ronds.append(pose)
			bascule += 1
			_note_emprise(point)
	_semer_dalles("Voie_dalles_carrees", &"RockPath_Square_Small_1", carres)
	_semer_dalles("Voie_dalles_rondes", &"RockPath_Round_Small_1", ronds)


## Échantillonne une polyligne à pas régulier, avec un jeu de pas et un
## décalage latéral bornés : une voie ancienne serpente, elle n'est pas un
## rail. Le décalage reste sous la moitié de la demi-largeur dégagée, sinon
## les dalles sortiraient sous les fleurs.
func _semis_de_voie(polyligne: Array[Vector2], pas: float,
		rng: RandomNumberGenerator) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var reste: float = 0.0
	for i: int in range(polyligne.size() - 1):
		var a: Vector2 = polyligne[i]
		var b: Vector2 = polyligne[i + 1]
		var longueur: float = a.distance_to(b)
		if longueur <= 0.001:
			continue
		var direction: Vector2 = (b - a) / longueur
		var normale: Vector2 = Vector2(-direction.y, direction.x)
		var s: float = reste
		while s < longueur:
			var lateral: float = rng.randf_range(-0.42, 0.42)
			points.append(a + direction * s + normale * lateral)
			s += pas * rng.randf_range(0.86, 1.14)
		reste = s - longueur
	return points


## Matérialise des dalles en UN `MultiMeshInstance3D`. Même contrat que les
## nappes : plan de plantation en méta, un seul nœud visuel, aucune
## ressource partagée mutée (le matériau du kit est DUPLIQUÉ avant teinte).
func _semer_dalles(nom: String, modele: StringName,
		poses: Array[Transform3D]) -> void:
	if poses.is_empty():
		push_error("[flower_field] pavage %s : aucune dalle posée" % nom)
		return
	var maillage: Mesh = _maillage_dalle(modele)
	if maillage == null:
		return
	# Assise : la dalle du kit n'a pas forcément son bas à y = 0. On la
	# descend de son propre minimum, à l'échelle de chaque instance.
	var bas: float = maillage.get_aabb().position.y
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = maillage
	mm.instance_count = poses.size()
	var origins: PackedVector3Array = PackedVector3Array()
	var scales: PackedFloat32Array = PackedFloat32Array()
	for i: int in range(poses.size()):
		var pose: Transform3D = poses[i]
		var echelle: float = pose.basis.get_scale().y
		pose.origin.y -= bas * echelle
		mm.set_instance_transform(i, pose)
		origins.append(pose.origin)
		scales.append(echelle)
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = nom
	instance.multimesh = mm
	instance.set_meta(&"instance_origins", origins)
	instance.set_meta(&"instance_scales", scales)
	add_child(instance)


## Maillage de dalle DUPLIQUÉ, teinté comme le ferait `K.apply_tone()` : la
## teinte MULTIPLIE l'albédo de base (l'atlas Rocks reste visible), la
## rugosité monte, le spéculaire descend. La ressource du kit n'est jamais
## mutée — c'est la copie qui porte la teinte.
func _maillage_dalle(modele: StringName) -> Mesh:
	var cle: String = "dalle|%s" % modele
	if _maillages.has(cle):
		return _maillages[cle] as Mesh
	var packed: PackedScene = K.scene_for(modele)
	if packed == null:
		push_error("[flower_field] modèle de dalle inconnu %s" % modele)
		return null
	var noeud: Node = packed.instantiate()
	var source: Mesh = _premier_maillage(noeud)
	var maillage: Mesh = null
	if source != null:
		maillage = source.duplicate() as Mesh
		for s: int in range(maillage.get_surface_count()):
			var base: StandardMaterial3D = \
				maillage.surface_get_material(s) as StandardMaterial3D
			if base == null:
				continue
			var teinte: StandardMaterial3D = base.duplicate() as StandardMaterial3D
			teinte.albedo_color = Color(
				base.albedo_color.r * TONE_DALLE.r,
				base.albedo_color.g * TONE_DALLE.g,
				base.albedo_color.b * TONE_DALLE.b, base.albedo_color.a)
			teinte.roughness = maxf(teinte.roughness, 0.95)
			teinte.metallic_specular = 0.1
			maillage.surface_set_material(s, teinte)
	noeud.free()
	_maillages[cle] = maillage
	return maillage


## Plante une stèle du GLB dédié : cap, inclinaison, échelle, puis assise
## REMESURÉE après basculement.
##
## LA REMESURE N'EST PAS FACULTATIVE : l'origine d'une pièce ne survit pas
## à un basculement, et une pierre penchée dont on n'a pas recalculé
## l'emprise s'enfonce ou flotte (piège mesuré du dépôt, cf. `_coucher()`
## du cimetière du tertre). Ici la base du GLB est à y = 0 par construction
## — le générateur le contrôle — mais l'inclinaison la relève quand même.
##
## `penche_vers` est la direction MONDE (XZ) vers laquelle la TÊTE part.
## Les deux stèles se penchent l'une vers l'autre : c'est ce mouvement, et
## non leur seule présence, qui fait lire une PORTE plutôt que deux pierres.
func _planter_stele(nom: String, mesh_nom: StringName, pied: Vector3,
		cap_deg: float, penche_vers: Vector2, penche_deg: float,
		echelle: float, enfoncement: float) -> void:
	var packed: PackedScene = load(STELES_GLB) as PackedScene
	if packed == null:
		push_error("[flower_field] stèles introuvables — %s" % STELES_GLB)
		return
	var racine: Node3D = packed.instantiate() as Node3D
	racine.name = nom
	var garde: bool = false
	for enfant: Node in racine.get_children():
		if enfant.name == String(mesh_nom):
			garde = true
		else:
			racine.remove_child(enfant)
			enfant.queue_free()
	if not garde:
		push_error("[flower_field] stèle %s absente du GLB" % mesh_nom)
		racine.queue_free()
		return
	var base: Basis = Basis(Vector3.UP, deg_to_rad(cap_deg))
	var vers: Vector3 = Vector3(penche_vers.x, 0.0, penche_vers.y).normalized()
	# Tourner de `penche_deg` autour de cet axe fait partir +Y vers `vers`.
	var axe: Vector3 = Vector3(vers.z, 0.0, -vers.x)
	base = Basis(axe, deg_to_rad(penche_deg)) * base
	racine.transform = Transform3D(base.scaled(Vector3.ONE * echelle), pied)
	_garantir_couleur_de_sommet(racine)
	add_child(racine)
	var boite: AABB = Transform3D(racine.transform.basis, Vector3.ZERO) \
		* KitPlacement.local_aabb(racine)
	racine.position.y -= boite.position.y + enfoncement


## La matière des stèles vit dans leur `COLOR_0` (voir le générateur) : si
## le matériau importé ne la consommait pas, la pierre redeviendrait
## l'aplat mesuré, SANS erreur ni avertissement. On force donc le drapeau
## sur une COPIE du matériau, posée en override de surface — la ressource
## importée n'est jamais mutée.
func _garantir_couleur_de_sommet(racine: Node3D) -> void:
	for noeud: Node in racine.find_children("*", "MeshInstance3D", true, false):
		var instance: MeshInstance3D = noeud as MeshInstance3D
		if instance.mesh == null:
			continue
		for s: int in range(instance.mesh.get_surface_count()):
			var actif: StandardMaterial3D = \
				instance.get_active_material(s) as StandardMaterial3D
			if actif == null or actif.vertex_color_use_as_albedo:
				continue
			var copie: StandardMaterial3D = actif.duplicate() as StandardMaterial3D
			copie.vertex_color_use_as_albedo = true
			instance.set_surface_override_material(s, copie)


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
