## LA SOURCE AUX REFLETS (`valley.poi.turquoise_spring.01`, r04) — une eau vive
## qui sort du pied de la falaise, à vingt-quatre mètres du guet et quatorze
## mètres sous lui.
##
## LES DEUX LIEUX SONT LES DEUX FACES DU MÊME MUR, et c'est le terrain gelé qui
## le dit. Profils REMESURÉS dans le moteur au lot 1.R.2
## (`evidence/world_v2/v2_3_b/lot1r2/source/sol_grille.json`, sonde
## `outils/sonde_sol_source.gd`) :
##
##   * le pad est PLAT à 0,00 m sur x ∈ [−9 ; +2] et z ∈ [−8 ; +8] ;
##   * la paroi part de x ≈ −10 : +0,98 m à −11, +3,58 à −13, +7,00 à −15,
##     +10,37 à −17 — soit l'altitude du guet ;
##   * le sol remonte aussi avec |z| près de la paroi (+1,58 m en (−10 ; +6)) ;
##   * le lit creusé de l'affluent est à −1,00 m en (+6 ; −6).
##
## Ce lieu n'a donc aucune falaise à construire — mais il n'a non plus AUCUN
## dénivelé à exploiter. Tout ce qui a de la hauteur ici est bâti.
##
## ══════════════════════════════════════════════════════════════════════════
## LOT 1.R.2 — LE VERDICT, ET LA GÉOMÉTRIE QUI L'EXPLIQUE
## ══════════════════════════════════════════════════════════════════════════
##
## Verdict Codex (lecture aveugle, REJET) : « l'eau reste une petite tache
## sombre ; la couronne ressemble à des blocs indépendants disposés autour d'un
## point ; arrivée, vasque et déversoir ne forment pas une lecture continue ;
## aucun élément ne domine réellement la caméra joueur. »
##
## Mesuré au pixel sur la capture qu'il a lue
## (`outils/mesurer_eau.py`, bande turquoise calibrée sur l'image elle-même) :
##
##   caméra joueur gelée   eau = 0,81 % du cadre, boîte 418 × 70 px,
##                         colonne d'eau la plus haute **35 px** sur 720
##
## « Petite tache » est donc un fait mesuré. Et sa cause n'est ni la teinte ni
## le rayon : c'est l'INCIDENCE. La caméra gelée est à 1,62 m au-dessus du plan
## d'eau pour 15 m de portée. Une nappe HORIZONTALE de 7,9 m y sous-tend
## `atan(1,62/11,0) − atan(1,62/18,9) = 3,5°`, soit 39 px — la valeur mesurée.
## Doubler le rayon n'y ajoute presque rien : au ras, la hauteur écran d'une
## surface plate varie comme l'inverse de la distance, pas comme le rayon.
##
## Une surface VERTICALE de 2,3 m à 18 m sous-tend 7,3°, soit ≈ 81 px.
##
## D'où les cinq gestes de cette passe, tous structurels, aucun de cadrage
## (les caméras sont GELÉES et le rester est une règle du lot) :
##
##  1. **L'ARRIVÉE EST UN VOILE.** L'eau sort d'une gorge à 2,35 m sur la face
##     est de la LÈVRE (`SM_Spring_Spout`) et descend jusqu'à la vasque. C'est
##     une surface presque verticale : elle occupe à elle seule plus de hauteur
##     d'écran que toute la nappe précédente, et elle est vue sous 70° au lieu
##     de 6°, donc sans le voile de ciel qui délavait la teinte.
##  2. **LA VASQUE EST BÂTIE, PAS POSÉE.** Un lit et une BERGE forment un vrai
##     bassin : le plan d'eau est à +0,26 m au-dessus du pad, contenu par un
##     bourrelet de gravier trempé dont la crête monte à 0,34–0,52 m. L'eau
##     n'est donc plus vue CONTRE L'HERBE PÂLE — qui la délavait à travers son
##     alpha de rive — mais contre de la pierre mouillée sombre.
##  3. **LE DÉVERSOIR EST UNE ÉCHANCRURE.** À l'est, la crête de berge tombe au
##     niveau de l'eau sur un secteur étroit, et l'eau franchit une marche de
##     ≈ 0,25 m avant de filer vers la tête d'affluent. Arrivée → vasque →
##     déversoir sont les trois moments d'une MÊME surface d'eau continue,
##     dans un seul maillage et un seul matériau.
##  4. **LE CERCLE DE BLOCS DEVIENT DEUX RIVES ET UNE OUVERTURE.** Voir la
##     table `MASSES` de `make_spring_maw.py` : une rive principale HAUTE au
##     sud (contrefort de 5,4 m qui descend en marches jusqu'à l'écrin du
##     fruit), une rive secondaire BASSE au nord (table de 1,44 m, sèche et
##     claire), et rien à l'est-nord-est — c'est par là que l'eau part.
##  5. **LES VALEURS SONT DIFFÉRENCIÉES.** Écart de valeur mesuré entre la
##     masse la plus claire et la plus sombre : 0,185 (plancher du contrôle :
##     0,14). Sur la version rejetée il était nul par construction — les
##     quatre masses partageaient teinte et niveau.
##
## CE LIEU N'AJOUTE TOUJOURS PAS D'EAU AU MONDE. `NappeSource` est un maillage
## visuel : pas de collision, pas de `WaterMatterComponent`, pas de nœud de
## graphe. L'hydrologie V2.2 est gelée et reste seule maîtresse. Le turquoise
## est celui de la rivière — jamais le cyan de Résonance.
##
## L'AFFLUENT NAÎT À L'EST. Premier point de `west_tributary_xz` : (−130 ; 34),
## soit le local (+6 ; −6). Le bout de la langue est à 5,26 m de cette tête, et
## aucune pièce de ce lieu ne porte de collider à moins de 8 m d'elle — la
## bande creusée du contrat (6,3 m de demi-largeur) reste libre.
##
## RÉCOMPENSE ET INTERACTION INCHANGÉES : `default_place_id()`, la sphère de
## découverte, l'ancre `RewardAnchor` en (−2,40 ; +2,60) et la table de butin
## de `discovery_rewards.gd` ne bougent pas d'un centimètre. C'est la BERGE qui
## se retire devant le fruit (`_retrait_ancre`), jamais la récompense qui
## s'écarte pour arranger une image.
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

## Les deux dalles mouillées du fil. Ce sont les seules pièces de KIT du lieu ;
## tout le reste vient du GLB dédié ou d'un maillage runtime.
const TONE_RIM: Color = Color(0.62, 0.68, 0.80)
## Plantes de bord d'eau : vert plus froid et plus sombre que le `TONE_PLANT`
## du kit — elles poussent les pieds dans l'eau, à l'ombre d'une paroi.
const TONE_PLANTE_HUMIDE: Color = Color(0.50, 0.66, 0.55)

## ── LE BASSIN ─────────────────────────────────────────────────────────────
## Le lit de vasque et sa berge. Le CENTRE tire vers la sarcelle (dépôt
## minéral : c'est le mécanisme réel d'une source turquoise — l'eau se colore
## par son fond) ; la rive est de la terre trempée ; la crête de berge est du
## gravier, sombre côté eau et sec côté extérieur.
const TONE_LIT: Color = Color(0.27, 0.27, 0.25)
const LIT_CENTRE: Color = Color(0.52, 1.0, 0.98)
const LIT_RIVE: Color = Color(0.86, 0.80, 0.70)
const LIT_CRETE: Color = Color(1.42, 1.36, 1.22)
const LIT_TALUS: Color = Color(1.72, 1.66, 1.50)

## Centre de la vasque, dans le repère du lieu.
const BASSIN_X: float = -5.05
const BASSIN_Z: float = -0.65
## LA VASQUE EST UNE GOUTTE, PAS UN DISQUE — allongée sur l'axe qui va de
## l'arrivée au déversoir. Un disque haché se lit « flaque » ; une forme
## orientée dit d'où l'eau vient et où elle va, ce qui EST la lecture continue
## que le verdict demande.
## `A` est la demi-longueur le long de `FIL_DIR`, `B` la demi-largeur.
const BASSIN_A: float = 3.62
const BASSIN_B: float = 2.62
## Hauteur du plan d'eau au-dessus du sol gelé. Ce n'est pas une nappe posée :
## la berge la contient (voir `_bassin`).
const NIVEAU_EAU: float = 0.26
## Crête de berge au-dessus du sol, avant modulation par secteur.
const CRETE_BASSE: float = 0.34
const CRETE_HAUTE: float = 0.52

## Direction du fil : de la vasque vers la tête d'affluent gelée (+6 ; −6).
const FIL_DIR: Vector2 = Vector2(0.803, -0.596)
## Secteur de l'échancrure, en angle autour de `FIL_DIR` (0 = plein est).
const ECHANCRURE_LARGEUR: float = 0.34
## Azimut du fruit dans le repère (FIL_DIR ; perpendiculaire), mesuré depuis le
## centre de vasque : l'ancre GELÉE (−2,40 ; +2,60) est à `along` 0,19 et
## `perp` 4,19, soit 1,525 rad. La berge se retire dans ce secteur.
const ANCRE_PHI: float = 1.525

## ── LA LÈVRE ET SON VOILE ─────────────────────────────────────────────────
## La gorge d'où l'eau sort, et le pied du voile. Les deux points sont
## MESURÉS sur la masse exportée, pas choisis : la face est de
## `SM_Spring_Spout` va de x ≈ −7,85 au ras du sol à x ≈ −8,20 à 2,2 m (elle
## recule en montant, parce que la masse penche vers l'ouest). Le voile est
## posé 0,18 m à l'est de cette face : là où une nervure ressort, il disparaît
## DANS la roche ; là où elle rentre, l'écart n'est pas visible depuis la
## caméra joueur, qui regarde le long de −X.
const VOILE_HAUT: Vector3 = Vector3(-8.02, 2.35, 1.70)
const VOILE_BAS: Vector3 = Vector3(-7.72, 0.30, 1.70)
const VOILE_LARGEUR_HAUT: float = 0.95
const VOILE_LARGEUR_BAS: float = 1.95

## Implantation des quatre masses, en local. Recopiée dans la table `MASSES`
## du générateur, qui la commente côté forme.
const POSE_CONTREFORT: Vector2 = Vector2(-9.60, 4.20)
const POSE_LEVRE: Vector2 = Vector2(-9.30, 1.70)
const POSE_TABLE: Vector2 = Vector2(-6.60, -4.70)
const POSE_SEUIL: Vector2 = Vector2(-2.20, -1.90)

const SEGMENTS: int = 48


func default_place_id() -> StringName:
	return &"valley.poi.turquoise_spring.01"


func _build() -> void:
	# ── LA RIVE PRINCIPALE, AU SUD (écran GAUCHE depuis la caméra joueur).
	# Une seule masse, cinq lobes fondus, qui descend en marches du contrefort
	# de 5,4 m jusqu'à l'écrin du fruit. C'est elle qui doit dominer le cadre :
	# projetée dans la caméra gelée (`outils/projeter.py`), sa tête tombe à
	# y ≈ 191 px et son pied à y ≈ 387 — soit près de 200 px de silhouette,
	# contre 105 px pour la plus haute mâchoire de la version rejetée.
	var contrefort: Vector3 = _seated(POSE_CONTREFORT.x, POSE_CONTREFORT.y)
	_masse(&"SM_Spring_Buttress", "Contrefort_sud", POSE_CONTREFORT, 0.55)
	declare_support(contrefort)
	# Les appuis suivent les LOBES, pas l'objet : le filet D2 lit des points, et
	# un seul point sous une masse de onze mètres d'emprise ne prouve rien de
	# ses extrémités.
	for lobe: Vector2 in [Vector2(-11.30, 2.20), Vector2(-6.00, 4.90),
			Vector2(-3.00, 3.20)]:
		declare_support(_seated(lobe.x, lobe.y))

	# ── LA LÈVRE D'ARRIVÉE. Blottie contre le contrefort — leurs enveloppes se
	# recouvrent, et c'est voulu : deux masses qui se touchent se lisent comme
	# UNE formation, deux masses séparées par de l'herbe se lisent comme deux
	# cailloux. C'est le défaut nommé par le verdict.
	var levre: Vector3 = _seated(POSE_LEVRE.x, POSE_LEVRE.y)
	_masse(&"SM_Spring_Spout", "Levre_arrivee", POSE_LEVRE, 0.30)
	declare_support(levre)

	# ── LA RIVE SECONDAIRE, AU NORD (écran DROITE) : une table BASSE, sèche et
	# claire. Le contraste des deux rives — 5,4 m sombre contre 1,4 m clair —
	# est ce qui remplace l'anneau, pas leur nombre.
	var table: Vector3 = _seated(POSE_TABLE.x, POSE_TABLE.y)
	_masse(&"SM_Spring_Shelf", "Table_nord", POSE_TABLE, 0.22)
	declare_support(table)
	declare_support(_seated(-4.00, -5.20))

	# ── LE SEUIL DU DÉVERSOIR. Deux lobes bas qui ENCADRENT l'échancrure sans
	# la fermer. Ce sont les pièces les plus proches de la caméra joueur (11 m),
	# donc celles dont chaque centimètre pèse le plus à l'écran.
	var seuil: Vector3 = _seated(POSE_SEUIL.x, POSE_SEUIL.y)
	_masse(&"SM_Spring_Sill", "Seuil_deversoir", POSE_SEUIL, 0.28)
	declare_support(seuil)
	declare_support(_seated(-1.10, -4.20))

	# ── L'EAU. Le lit et sa berge D'ABORD, la nappe ensuite : une nappe posée
	# avant son lit se lit comme une décalcomanie sur l'herbe, et c'est
	# exactement le défaut « petite tache sombre ».
	_bassin()
	_nappe()

	# ── DEUX DALLES MOUILLÉES dans le fil, en aval du seuil. Elles prolongent
	# la ligne de fuite vers la tête d'affluent et donnent au regard un dernier
	# appui. Chacune DÉCLARE son assise : ce sont les seules pièces portées du
	# tiers est de l'emprise.
	for spec: Array in [[-0.35, -4.05, 24.0, &"RockPath_Round_Small_1"],
			[0.65, -5.05, -51.0, &"RockPath_Square_Small_1"]]:
		var assise: Vector3 = _seated(float(spec[0]), float(spec[1]))
		K.module(self, spec[3] as StringName,
			assise + Vector3(0.0, -0.06, 0.0), float(spec[2]), 0.9, TONE_RIM)
		declare_support(assise)

	# ── LA VÉGÉTATION DE BORD D'EAU. Elle n'est pas décorative : trois touffes
	# posées SUR LA BERGE, à des azimuts choisis, dont deux entre la caméra et
	# l'eau. Une plante au premier plan devant une surface claire fabrique une
	# occlusion partielle, et une occlusion partielle est ce qui fait lire la
	# profondeur — c'est le seul levier qui reste quand le cadrage est gelé.
	# Elles sont placées PAR LA GÉOMÉTRIE DE LA BERGE (`_point_talus`), jamais
	# par des coordonnées tapées à la main : la berge peut bouger, elles
	# suivront, et aucune ne se retrouvera dans l'eau.
	_plante(&"Plant_7_Big", -1.05, 0.55, 1.05)
	_plante(&"Plant_7_Big", -2.05, 0.35, 0.85)
	_plante(&"Fern_1", 2.35, 0.45, 1.10)

	_collisions()

	# ── DÉCOUVERTE ET RÉCOMPENSE — INCHANGÉES.
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
	# Le fruit de soin pousse au bord de l'eau, côté est — le côté par lequel on
	# arrive, et le seul qui ne soit pas contre la paroi. L'ancre est GELÉE ;
	# c'est la berge qui se retire devant elle (`_retrait_ancre`).
	# −0,06 : `IngredientPickup` dessine sa baie centrée à +0,22 (rayon 0,14)
	# au-dessus de l'ancre — la baie touche donc le sol au lieu de flotter.
	RewardAnchor.attach(self, default_place_id(),
		RewardAnchor.Kind.INGREDIENT,
		_seated(-2.4, 2.6) + Vector3(0.0, -0.06, 0.0), Vector3(2.0, 0.0, 2.0))


## ══════════════════════════════════════════════════════════════════════════
## LA GÉOMÉTRIE DE LA VASQUE — une seule famille de fonctions pour le lit, la
## berge, la nappe et le déversoir. Elles partagent le repère (FIL_DIR ;
## perpendiculaire) et le même rayon haché : si le bassin change de forme, les
## quatre surfaces changent ENSEMBLE. Deux descriptions séparées de la même
## rive finissent toujours par diverger d'un centimètre, et un centimètre
## d'écart entre l'eau et son lit est un liseré noir.
## ══════════════════════════════════════════════════════════════════════════

## Perpendiculaire à `FIL_DIR`, sens direct.
func _perp() -> Vector2:
	return Vector2(-FIL_DIR.y, FIL_DIR.x)


## Rayon de la ligne d'eau à l'angle `phi` (0 = plein est, vers le déversoir).
##
## Ellipse allongée sur `FIL_DIR`, hachée par secteur et lissée sur trois
## voisins — jamais deux sinus purs : l'arbre foudroyé a payé une revue pour
## avoir modulé son disque par une somme harmonique, qui rend une étoile.
func _rayon_rive(phi: float) -> float:
	var c: float = cos(phi)
	var s: float = sin(phi)
	var ell: float = 1.0 / sqrt(pow(c / BASSIN_A, 2.0) + pow(s / BASSIN_B, 2.0))
	var i: float = phi / TAU * float(SEGMENTS)
	var lisse: float = (_alea(floorf(i - 1.0) * 2.3 + 7.1)
		+ _alea(floorf(i) * 2.3 + 7.1)
		+ _alea(floorf(i + 1.0) * 2.3 + 7.1)) / 3.0
	return ell * (0.93 + 0.12 * lisse) * _retrait_ancre(phi)


## LA BERGE SE RETIRE DEVANT LA RÉCOMPENSE.
##
## L'ancre du fruit est GELÉE à 4,19 m de l'axe. Sans retrait, la ligne d'eau
## haché monte à 2,93 m et le talus extérieur de la berge (1,3 m de plus) la
## rejoindrait. Un retrait de 18 % dans son secteur ramène le talus à 3,70 m et
## laisse une demi-largeur de berge sèche sous le fruit.
func _retrait_ancre(phi: float) -> float:
	var ecart: float = wrapf(phi - ANCRE_PHI, -PI, PI)
	return 1.0 - 0.18 * exp(-pow(ecart / 0.80, 2.0))


## Poids de l'échancrure : 1 plein est (le déversoir), 0 hors du secteur.
## C'est la seule ouverture de la berge, et elle est étroite — une berge qui
## s'ouvre partout ne contient rien.
func _echancrure(phi: float) -> float:
	var ecart: float = absf(wrapf(phi, -PI, PI))
	return clampf(1.0 - ecart / ECHANCRURE_LARGEUR, 0.0, 1.0)


## Hauteur de la crête de berge au-dessus du sol, à l'angle `phi`.
## Elle est irrégulière (un bourrelet régulier est un anneau de béton) et
## TOMBE au niveau de l'eau dans l'échancrure : c'est là que l'eau franchit.
func _crete(phi: float) -> float:
	var i: float = phi / TAU * float(SEGMENTS)
	var brut: float = _alea(floorf(i) * 1.9 + 41.3)
	var haut: float = lerpf(CRETE_BASSE, CRETE_HAUTE, 0.5 + 0.5 * brut)
	return lerpf(haut, NIVEAU_EAU - 0.03, _echancrure(phi))


## Largeur du talus extérieur de la berge, à l'angle `phi`.
func _largeur_talus(phi: float) -> float:
	var i: float = phi / TAU * float(SEGMENTS)
	return 1.00 + 0.55 * (0.5 + 0.5 * _alea(floorf(i) * 3.7 + 11.9))


## Point de la ligne d'eau (plan XZ local).
func _point_rive(phi: float) -> Vector2:
	var r: float = _rayon_rive(phi)
	return Vector2(BASSIN_X, BASSIN_Z) + FIL_DIR * (r * cos(phi)) \
		+ _perp() * (r * sin(phi))


## Point de la CRÊTE de berge (plan XZ local) — un peu au-delà de la rive.
func _point_crete(phi: float) -> Vector2:
	var r: float = _rayon_rive(phi) + 0.42
	return Vector2(BASSIN_X, BASSIN_Z) + FIL_DIR * (r * cos(phi)) \
		+ _perp() * (r * sin(phi))


## Point du PIED extérieur du talus de berge (plan XZ local).
func _point_talus(phi: float) -> Vector2:
	var r: float = _rayon_rive(phi) + 0.42 + _largeur_talus(phi)
	return Vector2(BASSIN_X, BASSIN_Z) + FIL_DIR * (r * cos(phi)) \
		+ _perp() * (r * sin(phi))


## Niveau du plan d'eau, en local.
func _niveau() -> float:
	return _y_sol(BASSIN_X, BASSIN_Z, NIVEAU_EAU)


## ══════════════════════════════════════════════════════════════════════════
## LE BASSIN — lit + berge, un seul maillage, un seul module.
##
## Exemption D1a NOMMÉE, comme la nappe : la surface épouse le terrain sommet
## par sommet (même titre que `SolBrule` de l'arbre foudroyé). Elle ne porte
## QUE sur l'aire ; au budget D7 les deux maillages COMPTENT.
##
## Profil radial, du centre vers l'extérieur :
##   centre        sol + 0,03      sarcelle (dépôt minéral)
##   ligne d'eau   niveau − 0,02   terre trempée
##   crête         sol + crête     gravier mouillé côté eau
##   pied de talus sol + 0,01      gravier SEC, qui meurt dans l'herbe
##
## LE PIÈGE, ET IL A DÉJÀ COÛTÉ TROIS ITÉRATIONS À CE LIEU : un bord plus
## sombre que TOUT dessine un anneau noir autour de l'eau. La pierre trempée
## est plus sombre que la pierre sèche, pas plus sombre que l'herbe. Les
## teintes vont donc de 0,86 (rive) à 1,72 (pied de talus) sur un matériau de
## base déjà sombre, et la valeur MONTE vers l'extérieur.
## ══════════════════════════════════════════════════════════════════════════
func _bassin() -> void:
	set_meta(&"exemption_runtime",
		PackedStringArray(["NappeSource", "FondVasque"]))
	var lit: MeshInstance3D = MeshInstance3D.new()
	lit.name = "FondVasque"
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var niveau: float = _niveau()
	var centre: Vector3 = Vector3(BASSIN_X, _y_sol(BASSIN_X, BASSIN_Z, 0.03),
		BASSIN_Z)
	var rive: PackedVector3Array = PackedVector3Array()
	var crete: PackedVector3Array = PackedVector3Array()
	var talus: PackedVector3Array = PackedVector3Array()
	var t_crete: PackedColorArray = PackedColorArray()
	for i: int in range(SEGMENTS):
		var phi: float = TAU * float(i) / float(SEGMENTS)
		var pr: Vector2 = _point_rive(phi)
		rive.append(Vector3(pr.x, niveau - 0.02, pr.y))
		var pc: Vector2 = _point_crete(phi)
		crete.append(Vector3(pc.x, _y_sol(pc.x, pc.y, _crete(phi)), pc.y))
		var pt: Vector2 = _point_talus(phi)
		talus.append(Vector3(pt.x, _y_sol(pt.x, pt.y, 0.01), pt.y))
		# La crête s'assombrit dans l'échancrure : c'est le seul endroit où
		# l'eau passe PAR-DESSUS, donc le seul qui soit trempé en haut.
		var mouille: float = _echancrure(phi)
		t_crete.append(LIT_CRETE.lerp(LIT_RIVE, mouille * 0.85))

	# Le lit : un éventail du centre vers la ligne d'eau.
	for i: int in range(SEGMENTS):
		var j: int = (i + 1) % SEGMENTS
		_tri3(st, centre, rive[i], rive[j], LIT_CENTRE, LIT_RIVE, LIT_RIVE)
	# La face intérieure de la berge : de la ligne d'eau à la crête.
	# La lèvre du fil du déversoir n'y fait pas exception — elle est plus basse,
	# c'est tout, et c'est `_crete()` qui le dit.
	for i: int in range(SEGMENTS):
		var j: int = (i + 1) % SEGMENTS
		_tri3(st, rive[i], crete[i], crete[j], LIT_RIVE, t_crete[i], t_crete[j])
		_tri3(st, rive[i], crete[j], rive[j], LIT_RIVE, t_crete[j], LIT_RIVE)
	# Le talus extérieur : de la crête au pied, où le gravier meurt dans
	# l'herbe. C'est la valeur la PLUS CLAIRE du bassin, et c'est ce qui
	# empêche la berge de cerner l'eau d'un trait sombre.
	for i: int in range(SEGMENTS):
		var j: int = (i + 1) % SEGMENTS
		_tri3(st, crete[i], talus[i], talus[j], t_crete[i], LIT_TALUS,
			LIT_TALUS)
		_tri3(st, crete[i], talus[j], crete[j], t_crete[i], LIT_TALUS,
			t_crete[j])

	# L'OMBRE DU FIL : une bande humide sous la langue du déversoir, un peu
	# plus large qu'elle — le sol mouillé déborde toujours l'eau.
	_bande_fil(st, 0.55, 3.70, 2.05, 1.05, 0.02,
		Color(0.92, 0.87, 0.76, 1.0), Color(1.34, 1.27, 1.14, 1.0), false)

	lit.mesh = st.commit()
	var terre: StandardMaterial3D = K.flat_material(TONE_LIT)
	terre.vertex_color_use_as_albedo = true
	lit.mesh.surface_set_material(0, terre)
	add_child(lit)


## ══════════════════════════════════════════════════════════════════════════
## LA NAPPE — l'arrivée, la vasque, le déversoir et le fil, dans UN SEUL
## maillage et un seul matériau. C'est la définition même de la « lecture
## continue » demandée : ce ne sont pas trois objets qui se suivent, c'est une
## seule surface d'eau qui descend.
##
## Couleurs de sommet = convention EXACTE de l'hydrologie V2.2, au caractère
## près (c'est ce qui garde la continuité de construction avec la rivière) :
##   COLOR.r  facteur de profondeur 0–1
##   COLOR.gb direction du courant en plan, encodée 0–1 (0,5 = immobile)
##   COLOR.a  opacité de base
## ══════════════════════════════════════════════════════════════════════════
func _nappe() -> void:
	var nappe: MeshInstance3D = MeshInstance3D.new()
	nappe.name = "NappeSource"
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var niveau: float = _niveau()
	var gb: Vector2 = Vector2(FIL_DIR.x * 0.5 + 0.5, FIL_DIR.y * 0.5 + 0.5)
	# La vasque : un éventail du centre vers la ligne d'eau.
	# PROFONDE au centre (r = 0,88, alpha 0,97), très mince à la rive
	# (r = 0,10, SOUS le seuil de mousse du shader) : l'anneau de mousse cassée
	# est ce qui accroche l'œil aux vues rasantes, où la teinte de l'eau se
	# perd dans le reflet du ciel.
	var centre: Vector3 = Vector3(BASSIN_X, niveau, BASSIN_Z)
	var teinte_centre: Color = Color(0.88, 0.5, 0.5, 0.97)
	var rive: PackedVector3Array = PackedVector3Array()
	var t_rive: PackedColorArray = PackedColorArray()
	for i: int in range(SEGMENTS):
		var phi: float = TAU * float(i) / float(SEGMENTS)
		var pr: Vector2 = _point_rive(phi)
		rive.append(Vector3(pr.x, niveau, pr.y))
		# Le courant ne va nulle part au repos, sauf dans l'échancrure où
		# l'eau sort, et sous le voile où elle arrive.
		var e: float = _echancrure(phi)
		var g: float = lerpf(0.5, gb.x, e)
		var b: float = lerpf(0.5, gb.y, e)
		t_rive.append(Color(lerpf(0.10, 0.42, e), g, b, lerpf(0.62, 0.92, e)))
	for i: int in range(SEGMENTS):
		var j: int = (i + 1) % SEGMENTS
		_tri_eau(st, [centre, rive[i], rive[j]],
			[teinte_centre, t_rive[i], t_rive[j]])

	_voile(st)
	_deversoir(st, niveau, gb)

	nappe.mesh = st.commit()
	var eau: ShaderMaterial = ShaderMaterial.new()
	eau.shader = load(EAU_SHADER) as Shader
	eau.set_shader_parameter(&"wave_noise",
		WorldV2GroundMaterial.grain_texture())
	nappe.mesh.surface_set_material(0, eau)
	add_child(nappe)
	declare_support(Vector3(BASSIN_X, _y_sol(BASSIN_X, BASSIN_Z, 0.0),
		BASSIN_Z))


## L'ARRIVÉE — un voile d'eau presque vertical sur la face est de la lèvre.
##
## C'est le geste central de cette passe, et sa justification est arithmétique :
## à 18 m et sous 1,62 m de hauteur d'œil, une surface HORIZONTALE de 7 m ne
## sous-tend que 3,5° (39 px) alors que ce voile de 2,05 m en sous-tend 6,5°
## (72 px). Il est aussi vu sous ≈ 70° d'incidence au lieu de 6° : le Fresnel du
## shader n'y pose donc PAS son vernis rasant, et la couleur qui sort est celle
## de l'eau, pas celle du ciel.
##
## Il s'ÉLARGIT en descendant (0,95 → 1,95 m) parce que c'est ce que fait une
## lame d'eau qui quitte une lèvre, et parce que la roche s'évase de même : le
## voile suit la face, il ne pend pas devant.
func _voile(st: SurfaceTool) -> void:
	var pas: int = 12
	var lateral: Vector3 = Vector3(0.0, 0.0, 1.0)
	var precedent_g: Vector3 = Vector3.ZERO
	var precedent_d: Vector3 = Vector3.ZERO
	var precedent_t: Color = Color.WHITE
	for k: int in range(pas + 1):
		var t: float = float(k) / float(pas)
		var axe: Vector3 = VOILE_HAUT.lerp(VOILE_BAS, t)
		# Le voile s'écarte de la roche en tombant : une lame d'eau accélère et
		# décolle. 9 cm au plus — au-delà elle pendrait dans le vide.
		axe.x += 0.09 * sin(PI * t) + 0.05 * sin(t * 7.3)
		var demi: float = lerpf(VOILE_LARGEUR_HAUT, VOILE_LARGEUR_BAS, t) * 0.5
		# Le sol du lieu est plat sous le voile : on ancre le bas au niveau
		# d'eau, pour que la lame ENTRE dans la vasque au lieu de la percer.
		var y: float = maxf(axe.y, _niveau() - 0.02)
		var gauche: Vector3 = Vector3(axe.x, y, axe.z + demi)
		var droite: Vector3 = Vector3(axe.x, y, axe.z - demi)
		# Une lame mince en haut (elle sort d'une gorge), épaisse et écumante en
		# bas (elle frappe l'eau). `r` bas + alpha haut = la mousse du shader.
		var teinte: Color = Color(lerpf(0.34, 0.06, t), 0.5,
			0.5 - 0.34 * t, lerpf(0.90, 0.99, t))
		if k > 0:
			_tri_eau(st, [precedent_g, gauche, droite],
				[precedent_t, teinte, teinte])
			_tri_eau(st, [precedent_g, droite, precedent_d],
				[precedent_t, teinte, precedent_t])
		precedent_g = gauche
		precedent_d = droite
		precedent_t = teinte
	# LE BOUILLON DE PIED. Une petite calotte d'eau très peu profonde autour du
	# point de chute : c'est elle qui fait lire « ça tombe ici » plutôt que
	# « une plaque est posée là ». Elle est DANS la vasque, à son niveau, donc
	# elle ne peut pas flotter.
	var pied: Vector2 = Vector2(VOILE_BAS.x + 0.35, VOILE_BAS.z)
	var niveau: float = _niveau()
	var noyau: Vector3 = Vector3(pied.x, niveau + 0.012, pied.y)
	var anneau: PackedVector3Array = PackedVector3Array()
	for i: int in range(16):
		var a: float = TAU * float(i) / 16.0
		var r: float = 0.95 + 0.30 * _alea(float(i) * 5.3 + 2.7)
		anneau.append(Vector3(pied.x + cos(a) * r, niveau + 0.004,
			pied.y + sin(a) * r))
	for i: int in range(16):
		var j: int = (i + 1) % 16
		_tri_eau(st, [noyau, anneau[i], anneau[j]],
			[Color(0.02, 0.5, 0.5, 0.99), Color(0.07, 0.5, 0.5, 0.72),
			Color(0.07, 0.5, 0.5, 0.72)])


## LE DÉVERSOIR — l'eau franchit l'échancrure, tombe d'une marche, puis file.
##
## La marche est BÂTIE : le sol est plat ici (mesuré), et le plan d'eau est à
## +0,26 m parce que la berge le contient. C'est cette différence, et elle
## seule, qui donne au déversoir une hauteur visible depuis une caméra rasante.
func _deversoir(st: SurfaceTool, niveau: float, gb: Vector2) -> void:
	# La lame qui passe la crête, du bord d'eau au pied du talus extérieur.
	var pas: int = 8
	var precedent_g: Vector3 = Vector3.ZERO
	var precedent_d: Vector3 = Vector3.ZERO
	var precedent_t: Color = Color.WHITE
	var demi_angle: float = ECHANCRURE_LARGEUR * 0.72
	for k: int in range(pas + 1):
		var t: float = float(k) / float(pas)
		# Le profil suit celui de la berge : rive → crête → pied de talus.
		var pg: Vector2 = _profil_deversoir(demi_angle, t)
		var pd: Vector2 = _profil_deversoir(-demi_angle, t)
		var yg: float = _hauteur_deversoir(demi_angle, t, niveau)
		var yd: float = _hauteur_deversoir(-demi_angle, t, niveau)
		var gauche: Vector3 = Vector3(pg.x, yg, pg.y)
		var droite: Vector3 = Vector3(pd.x, yd, pd.y)
		var teinte: Color = Color(lerpf(0.30, 0.08, t), gb.x, gb.y,
			lerpf(0.95, 0.80, t))
		if k > 0:
			_tri_eau(st, [precedent_g, gauche, droite],
				[precedent_t, teinte, teinte])
			_tri_eau(st, [precedent_g, droite, precedent_d],
				[precedent_t, teinte, precedent_t])
		precedent_g = gauche
		precedent_d = droite
		precedent_t = teinte
	# LE FIL. Il part du pied du talus et descend vers la tête d'affluent, en
	# ÉPOUSANT le sol. Deux renflements — des flaques où l'eau s'étale — le
	# long du parcours : ils sont à 8–11 m de la caméra au lieu de 15, et sous
	# 9 à 12° d'incidence au lieu de 6. Plus grands à l'écran ET mieux vus,
	# sans qu'aucune caméra n'ait bougé.
	_bande_fil(st, 0.55, 3.70, 1.55, 0.62, 0.045,
		Color(0.24, gb.x, gb.y, 0.94), Color(0.06, gb.x, gb.y, 0.46), true)


## Point du profil de déversoir : `t` va de la ligne d'eau (0) au pied du
## talus (1), en passant par la crête à 0,42.
func _profil_deversoir(phi: float, t: float) -> Vector2:
	if t <= 0.42:
		return _point_rive(phi).lerp(_point_crete(phi), t / 0.42)
	return _point_crete(phi).lerp(_point_talus(phi), (t - 0.42) / 0.58)


func _hauteur_deversoir(phi: float, t: float, niveau: float) -> float:
	var p: Vector2 = _profil_deversoir(phi, t)
	if t <= 0.42:
		return niveau
	# LA MARCHE. Elle tombe du niveau d'eau au ras du sol sur le talus
	# extérieur, en accélérant (courbe en t²) comme le fait une lame qui
	# décroche d'une lèvre.
	var u: float = (t - 0.42) / 0.58
	return lerpf(niveau, _y_sol(p.x, p.y, 0.05), u * u)


## Bande le long du fil, du pied du talus vers la tête d'affluent. Elle ÉPOUSE
## le sol gelé sommet par sommet : une surface plane posée en travers d'une
## pente est un « plan d'eau flottant », et c'est une cause de rejet écrite au
## contrat du lieu. On gagne de la surface vue, jamais en trichant sur l'assise.
##
## `eau` dit si la teinte porte la convention d'eau (R = profondeur) ou une
## valeur multiplicative (le lit). Sans ce drapeau, creuser un renflement
## reviendrait à teinter le sol mouillé en ROUGE.
func _bande_fil(st: SurfaceTool, depart: float, longueur: float,
		larg_depart: float, larg_fin: float, sur_sol: float,
		teinte_depart: Color, teinte_fin: Color, eau: bool) -> void:
	var pas: int = 22
	var perp: Vector2 = _perp()
	var pied: Vector2 = _point_talus(0.0)
	var origine: Vector2 = pied + FIL_DIR * depart
	var precedent_g: Vector3 = Vector3.ZERO
	var precedent_d: Vector3 = Vector3.ZERO
	var precedent_t: Color = teinte_depart
	for k: int in range(pas + 1):
		var t: float = float(k) / float(pas)
		var axe: Vector2 = origine + FIL_DIR * (longueur * t)
		# Ondulation légère — un ruisselet droit se lit tracé à la règle.
		axe += perp * (0.24 * sin(t * 9.4 + 1.3) * (1.0 - t))
		# Deux gaussiennes de largeurs et de hauteurs différentes : deux
		# flaques identiques se reliraient comme un motif.
		var bosse: float = 0.92 * exp(-pow((t - 0.32) / 0.130, 2.0)) \
			+ 0.70 * exp(-pow((t - 0.72) / 0.110, 2.0))
		var demi: float = lerpf(larg_depart, larg_fin, t) * 0.5 * (1.0 + bosse)
		var g2: Vector2 = axe + perp * demi
		var d2: Vector2 = axe - perp * demi
		var gauche: Vector3 = Vector3(g2.x, _y_sol(g2.x, g2.y, sur_sol), g2.y)
		var droite: Vector3 = Vector3(d2.x, _y_sol(d2.x, d2.y, sur_sol), d2.y)
		var teinte: Color = teinte_depart.lerp(teinte_fin, t)
		if eau and bosse > 0.0:
			# Une flaque est plus PROFONDE qu'un filet : sa couleur tire vers le
			# pétrole du fond, et elle cesse d'être un film transparent.
			teinte.r = minf(1.0, teinte.r + 0.52 * bosse)
			teinte.a = maxf(teinte.a, minf(0.98, 0.56 + 0.44 * bosse))
		if k > 0:
			_tri_eau(st, [precedent_g, gauche, droite],
				[precedent_t, teinte, teinte])
			_tri_eau(st, [precedent_g, droite, precedent_d],
				[precedent_t, teinte, precedent_t])
		precedent_g = gauche
		precedent_d = droite
		precedent_t = teinte


## Une touffe posée SUR LA BERGE, à l'angle `phi`, `debord` mètres au-delà du
## pied de talus. Placée par la géométrie de la berge, jamais par des
## coordonnées tapées : la berge peut bouger, la plante suivra, et aucune ne
## se retrouvera dans l'eau.
func _plante(modele: StringName, phi: float, debord: float,
		echelle: float) -> void:
	var pied: Vector2 = _point_talus(phi)
	var vers: Vector2 = (pied - Vector2(BASSIN_X, BASSIN_Z)).normalized()
	var p: Vector2 = pied + vers * debord
	K.module(self, modele, _seated(p.x, p.y) + Vector3(0.0, -0.04, 0.0),
		rad_to_deg(phi) * 1.7, echelle, TONE_PLANTE_HUMIDE)


## ══════════════════════════════════════════════════════════════════════════
## COLLISIONS — cinq volumes, et AUCUN sur le fil de l'eau : les dalles du
## déversoir se franchissent, un corps solide dessus ferait une marche au
## milieu d'un ruisseau.
##
## Cinq boîtes + la sphère du POI = 6 formes, soit exactement le budget micro.
## Chacune couvre la ou les masses qu'un joueur peut atteindre ; elles sont
## volontairement plus ÉTROITES que le visible, pour qu'on ne bute pas sur
## l'évasement d'un pied qui se franchit.
##
## Distances à la tête d'affluent gelée (+6 ; −6), toutes très au-delà des 5 m
## du contrat : contrefort 18,4 m, queue 16,0 m, lèvre 17,3 m, table 12,8 m,
## seuil 9,3 m.
## ══════════════════════════════════════════════════════════════════════════
func _collisions() -> void:
	K.collider_box(self, "Source_contrefort",
		_seated(-9.90, 4.00) + Vector3(0.0, 2.30, 0.0), Vector3(3.4, 4.8, 3.8),
		0.0)
	K.collider_box(self, "Source_queue_sud",
		_seated(-5.60, 4.60) + Vector3(0.0, 0.85, 0.0), Vector3(3.2, 1.8, 2.6),
		12.0)
	K.collider_box(self, "Source_levre",
		_seated(-9.30, 1.70) + Vector3(0.0, 1.15, 0.0), Vector3(2.2, 2.4, 2.6),
		0.0)
	K.collider_box(self, "Source_table_nord",
		_seated(-5.90, -4.85) + Vector3(0.0, 0.60, 0.0), Vector3(5.4, 1.3, 2.8),
		-8.0)
	K.collider_box(self, "Source_seuil",
		_seated(-1.75, -3.00) + Vector3(0.0, 0.45, 0.0), Vector3(2.6, 1.0, 3.4),
		-24.0)


## ══════════════════════════════════════════════════════════════════════════
## OUTILS
## ══════════════════════════════════════════════════════════════════════════

## Hachage déterministe dans [−1 ; 1]. Pas de `randf()` : la nappe doit être
## identique d'un montage à l'autre, sinon la régression visuelle compare deux
## formes différentes et ne prouve rien.
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


## Triangle à TROIS teintes indépendantes. Nécessaire dès qu'une face a un
## sommet sur la ligne d'eau et deux en berge : deux teintes ne peuvent pas
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


## POSER UNE MASSE DU GLB DÉDIÉ, enterrée de `enfoncement`.
##
## L'ASSISE NE SE CALCULE PAS SUR LE BAS DE L'EMPRISE. Le GLB a un `min Y`
## NÉGATIF, volontairement : chaque masse est prolongée SOUS son plan de sol
## par une jupe évasée, et c'est elle qui supprime la ligne de contact
## pierre/herbe. Le plan y = 0 du modèle EST le sol prévu. Soustraire
## `boite.position.y` remonterait donc la masse de toute la hauteur de jupe et
## la reposerait SUR l'herbe — le défaut qu'on répare, obtenu en croyant le
## corriger, et rien dans le rendu ne le crierait.
##
## AUCUN RECENTRAGE, ET AUCUN LACET. Les lobes de chaque masse sont placés dans
## le GLB PAR RAPPORT À SON ORIGINE (repère Blender, `Godot X;Z = Blender x;−y`).
## Recentrer sur l'emprise commune, ou faire tourner l'objet, déplacerait tous
## les lobes en même temps et l'implantation écrite dans les deux fichiers
## cesserait d'être vraie. L'asymétrie vient de la table des lobes et des
## graines, pas d'un lacet appliqué après coup.
##
## LA COULEUR DE SOMMET EST FORCÉE (ISS-066) : la matière de ces masses — le
## mouillage et la valeur propre de chaque rive compris — vit dans leur
## `COLOR_0`. Si le matériau importé ne la consommait pas, la roche redeviendrait
## un aplat SANS erreur ni avertissement. On force le drapeau sur une COPIE
## posée en override de surface ; la ressource importée n'est jamais mutée.
func _masse(objet: StringName, nom: String, pose: Vector2,
		enfoncement: float) -> Node3D:
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
	racine.transform = Transform3D(Basis.IDENTITY,
		Vector3(pose.x, 0.0, pose.y))
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
	racine.position.y = ground_local_y(pose.x, pose.y) - enfoncement
	return racine


func _seated(local_x: float, local_z: float) -> Vector3:
	return Vector3(local_x, ground_local_y(local_x, local_z), local_z)
