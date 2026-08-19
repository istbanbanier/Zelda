## V2.3-A.R2B.2 — FILET de l'agent A : la ferme abandonnée doit être faite de
## la MATIÈRE de la maçonnerie qui l'entoure, et son mur nord doit MANQUER.
##
## ORIGINE. Verdict PARTIAL du lead (R2B.2) sur trois vues — `ferme_seuil`,
## `ferme_facade`, `ferme_arriere` : « planches et panneaux pâles lisant comme
## des plaques opaques sans matière », « des ajouts qui BOUCHENT la lecture »,
## « pignon arrière lisant comme une plaque beige POSÉE sur le bâtiment »,
## « mur nord toujours parfaitement rectangulaire ».
##
## LES QUATRE DÉFAUTS SONT MESURÉS, jamais supposés (sondes du 2026-08-19,
## `evidence/world_v2/v2_3_r2b2/ferme/rouge_avant/`) :
##
##   1. UV0 — sonde Godot : 23 surfaces sur 23 des 12 pièces `SM_Farm_*` sans
##      `ARRAY_FORMAT_TEX_UV` et sans `albedo_texture`, quand le module de kit
##      voisin `Wall_UnevenBrick_Straight` a UV0 sur ses 3 surfaces et porte
##      `T_UnevenBrick_BaseColor.png`. C'est cette discontinuité de MATIÈRE,
##      mur contre mur, qui produit le « carton ».
##      LE COMPTE EST DOUZE, PAS ONZE : la directive disait onze pièces, la
##      sonde en trouve douze. Que personne ne cherche la douzième plus tard.
##
##   2. PROFONDEUR DE POSE — les tableaux ne manquent pas d'épaisseur (0,52 m,
##      soit PLUS que le mur qu'ils bordent) : leur signe est INVERSÉ. Blender
##      les extrude de y = -0,42 à +0,10 pour entrer de 42 cm DANS le mur ;
##      l'export Y-up donne `Godot z = -y`, et le GLB rend Z ∈ [-0,10 ; +0,42].
##      Posés sur un parement dont le plan de brique est à z = 3,000 (le module
##      de kit est DEUX PLANS STRICTS, brique Z=0,000 et plâtre Z=-0,200, sans
##      aucune face de chant), ils SAILLENT de 42 cm devant la façade. Ce sont
##      eux, `SM_Farm_Jamb_Door` et `SM_Farm_Jamb_Breach`, qui « bouchent la
##      lecture » : 7,32 + 5,32 + 2,92 + 1,31 % du cadre de `ferme_seuil`.
##
##   3. PIGNON POSÉ — 0,68 m d'épaisseur sur un mur dont la géométrie réelle
##      n'a que 0,20 m, donc 34 cm de surplomb devant le parement, et une base
##      qui n'entre que de 0,06 m dans l'arase (posé 3,06, arase 3,12).
##
##   4. MUR NORD — trois `Wall_UnevenBrick_Straight` pleine hauteur : la ligne
##      d'arase du seul mur nord est PLATE à 3,12 m, écart-type 0,000 m. Le
##      filet R2B.1 ne l'attrape pas : il mesure la dispersion sur TOUTE la
##      maçonnerie, que le pignon et le moignon suffisent à faire passer.
##
## Écrit ROUGE d'abord : les quatre contrôles échouent sur `c44f430b`, chacun
## en nommant le nombre qu'il constate.
extends GateTestCase

const FARM_SCENE: String = "res://scenes/world_v2/poi/AbandonedFarmPlace.tscn"
const FARM_GLB: String = "res://assets/architecture/farm/SM_Farm_Ruins.glb"
## Le golden master du socle, GELÉ (`GM_BASELINE_SHA256.txt` ligne 6,
## sha 24f39047…) et SANS UV0 sur ses deux primitives — mesuré le 2026-08-19.
## Il sert aussi au hameau de la rivière, lieu GELÉ ayant passé sa revue.
const MUR_GLB: String = "res://assets/architecture/village/SM_Village_Wall.glb"

## Arase mesurée du module de mur (`probe_kit_seating`, 2026-08-19).
const ARASE_M: float = 3.12
## Demi-portée du bâtiment : le plan de brique du mur nord est à z = -3,00.
const DEMI_M: float = 3.00

## -- Contrôle A : matière ----------------------------------------------------
## Plancher : sous ce compte de surfaces, le contrôle ne regarderait rien.
const SURFACES_MIN: int = 20

## -- Contrôle B : profondeur de pose ------------------------------------------
## Un tableau de baie AFFLEURE son parement et s'enfonce dans la tranche.
## `+0,02` : deux centimètres de tolérance pour un arrondi, pas un pilastre.
const TABLEAU_SAILLIE_MAX_M: float = 0.02
const TABLEAU_ENFONCEMENT_MIN_M: float = 0.30
## Le pignon prolonge un mur de 0,40 m ; au-delà il déborde et se lit posé.
const PIGNON_EPAISSEUR_MAX_M: float = 0.42
const PIGNON_SAILLIE_MAX_M: float = 0.12

## -- Contrôle D1 : le pignon est SOLIDAIRE ------------------------------------
## Il ne coiffe pas une arête : il EST les assises hautes du mur. 0,45 m, c'est
## deux assises de 0,22 m — en deçà, la jonction redevient une ligne.
const PIGNON_RECOUVREMENT_MIN_M: float = 0.45
## Débord hors du plan de parement du mur nord.
const PIGNON_DEBORD_MAX_M: float = 0.06

## -- Contrôle D2 : le mur NORD manque -----------------------------------------
## La ligne d'arase du SEUL mur nord, échantillonnée en colonnes.
const NORD_BANDE_Z_MAX: float = -2.40
const NORD_COLONNE_M: float = 0.25
const NORD_COLONNES_MIN: int = 12
const NORD_ECART_TYPE_MIN_M: float = 0.35
const NORD_POINT_BAS_MAX_M: float = 2.10
## LE MANQUE EST UNE ÉTENDUE, PAS UN POINT — durci après un sabotage qui ne
## rougissait pas. Reposer le module de kit nord-est PAR-DESSUS le pan rompu
## laissait l'écart-type et le point bas satisfaits : deux colonnes basses au
## bout de la pièce suffisaient, alors que le mur redevenait visuellement
## intact. Un contrôle qu'un sabotage ne peut pas faire rougir ne compte pas
## (PROMPT4_METHOD §2). On exige donc qu'une PART du couronnement manque.
const NORD_MANQUE_SEUIL_M: float = 2.60
const NORD_MANQUE_PART_MIN: float = 0.18
## UN ÉCART-TYPE MESURE LA DISPERSION, PAS L'IRRÉGULARITÉ — et une diagonale
## parfaite a une grande dispersion. Le lead a repris le profil colonne par
## colonne le 2026-08-19 : les sommets de gradins tombaient sur une droite à
## 3,3 % près (1,7 % sur l'échantillonnage de ce contrôle), et les 16 colonnes
## du plateau avaient un écart-type de 0,0000 m. De près on voyait des
## marches ; de loin — trois vues sur six — un trait tiré à la règle. Cause
## dans `_gradins` : le bruit était appliqué à `x1` seulement, donc à la
## LONGUEUR des marches, jamais à leur HAUTEUR.
##
## Trois critères, chacun contre un aspect distinct :
##   * RÉSIDU — la partie descendante ne doit pas coller à sa tendance, et la
##     tendance se cherche EN LINÉAIRE **ET** EN LOG, indicateur = le minimum
##     des deux. Correction du lead du 2026-08-19, démontrée par l'audit sur
##     son propre indicateur : une rampe GÉOMÉTRIQUE (rapports successifs
##     0,411 / 0,476 / 0,376 / 0,376) rend 15,2 % de résidu linéaire — donc
##     « irrégulière » — et 1,7 % en espace log, où elle apparaît pour ce
##     qu'elle est. Un balayage de paramètre est multiplicatif ; le chercher
##     additivement ne le voit pas. Mon défaut mesuré est additif (gradins à
##     -0,22 m constants), mais rien ne garantit qu'une correction ne
##     remplace pas une rampe additive par une rampe géométrique ;
##   * DENT — au moins une assise doit SURVIVRE nettement au-dessus de la
##     tendance. Un bruit symétrique satisferait le résidu tout en rendant une
##     diagonale floue ; une dent, c'est ce qui fait lire « effondrement » ;
##   * PLATEAU — une arase intacte sur 4 m est une donnée du module de kit,
##     pas une fatalité : rien n'oblige à la laisser entière sur sa longueur.
## 12 %, calibré sur les mesures de l'audit du 2026-08-19 : boîtes de la ferme
## 4,7 % sur 118 membres · boîtes de l'arbre 5,2 % · veines du pylône 6,5 % ·
## racines 13,7 % · écorces 20,1 %. Ce seuil ne vise QUE la partie descendante
## d'un arrachement, jamais un ouvrage debout : les trois pieds du pylône
## golden master sont à 0,0 % pour une amplitude nulle — trois volumes
## rigoureusement identiques — et le pylône a passé la revue visuelle. Une
## architecture se répète légitimement ; une maçonnerie ROMPUE, non (directive
## point 7 : « arêtes de rupture irrégulières et une logique de gravité »).
const NORD_RESIDU_PART_MIN: float = 0.12
const NORD_DENT_MIN_M: float = 0.25
const NORD_PLAT_MAX_COLONNES: int = 10
const NORD_PLAT_TOLERANCE_M: float = 0.02
## La partie « descendante » : tout ce qui est nettement sous le point haut.
const NORD_DESCENTE_MARGE_M: float = 0.30
const NORD_DESCENTE_MIN_COLONNES: int = 5


## -- E. Le socle porte la matière, et le gelé n'a pas bougé ------------------
##
## LA PLUS GRANDE SURFACE PLATE DE LA VUE DÉCISIVE. Coupe verticale du lead
## dans `ferme_seuil` à x = 300 : 132 pixels de haut à (64-65, 64, 59), écart
## max-min de 6, arête supérieure franche — une dalle grise absolument unie
## entre la maçonnerie et le gazon. C'est le point 4 de la directive, mot pour
## mot : « supprimer toute lecture de panneau beige ou de carton découpé ».
##
## SA CAUSE N'EST PAS UN OUBLI : `_socle_assises()` lofte `SM_Village_Wall.glb`,
## qui n'a AUCUN UV0 et qui est un golden master INTERDIT DE MODIFICATION. Le
## socle ne peut donc pas recevoir de texture par dépliage. `StandardMaterial3D`
## sait projeter SANS UV — `uv1_triplanar`, vérifié PRÉSENT et affectable sur le
## moteur 4.7.1-stable installé le 2026-08-19, jamais supposé de mémoire.
##
## ET LE RISQUE DE PÉRIMÈTRE EST CONTRÔLÉ ICI, pas espéré : le même GLB sert au
## hameau de la rivière. Un matériau modifié en amont — base non dupliquée,
## cache partagé, ressource importée — changerait un lieu gelé. Le second volet
## de ce contrôle recharge le GLB à neuf et exige que son matériau de base soit
## RESTÉ nu.

func test_le_socle_porte_la_matiere_sans_toucher_au_gele() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	var surfaces: int = 0
	if place == null:
		faults.append("ferme : la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var socle: Node3D = _named_child(place, "Socle")
		if socle == null:
			faults.append("aucun nœud « Socle »")
		else:
			for child: Node in socle.find_children("*", "MeshInstance3D",
					true, false):
				var mi: MeshInstance3D = child as MeshInstance3D
				if mi.mesh == null:
					continue
				for s: int in range(mi.mesh.get_surface_count()):
					surfaces += 1
					var mat: StandardMaterial3D = mi.get_active_material(s) \
						as StandardMaterial3D
					if mat == null or mat.albedo_texture == null:
						faults.append("socle %s s%d : aucune albedo_texture "
							% [mi.name, s] + "— dalle unie, la matière du kit "
							+ "n'est pas reprise")
						continue
					if not mat.uv1_triplanar:
						faults.append("socle %s s%d : texture posée sans "
							% [mi.name, s] + "triplanaire, or ce maillage n'a "
							+ "PAS d'UV0 — la carte ne peut pas se plaquer")
			if surfaces < 4:
				faults.append("%d surface(s) de socle inspectée(s) (plancher "
					% surfaces + "4, un run par côté) — le contrôle ne regarde "
					+ "rien")
		_dismount(place)
	# LE GELÉ : rechargé À NEUF, il doit être resté nu.
	var packed: PackedScene = load(MUR_GLB) as PackedScene
	if packed == null:
		faults.append("le golden master de socle ne se charge pas")
	else:
		var racine: Node3D = packed.instantiate() as Node3D
		for child: Node in racine.find_children("*", "MeshInstance3D", true,
				false):
			var mi: MeshInstance3D = child as MeshInstance3D
			if mi.mesh == null:
				continue
			for s: int in range(mi.mesh.get_surface_count()):
				var base: StandardMaterial3D = mi.mesh.surface_get_material(s) \
					as StandardMaterial3D
				if base == null:
					continue
				if base.albedo_texture != null or base.uv1_triplanar:
					faults.append("FUITE DE PÉRIMÈTRE : le matériau de base de "
						+ "%s a été modifié (texture=%s, triplanar=%s) — le " \
						% [MUR_GLB, base.albedo_texture != null,
						   base.uv1_triplanar]
						+ "hameau de la rivière est GELÉ et partage ce GLB")
		racine.free()
	check(faults.is_empty(),
		"le socle porte la matière du kit par triplanaire (%d surface(s)) et "
		% surfaces + "le golden master partagé reste nu (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (socle) — %s" % restore_root_reason())


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _mount_alone(path: String) -> Node3D:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	var place: Node3D = packed.instantiate() as Node3D
	if place == null:
		return null
	_tree().root.add_child(place)
	return place


func _dismount(place: Node3D) -> void:
	if place != null:
		place.get_parent().remove_child(place)
		place.queue_free()


func _capped(faults: Array[String], keep: int = 6) -> String:
	if faults.size() <= keep:
		return " ; ".join(faults)
	return " ; ".join(faults.slice(0, keep)) \
		+ " ; (+%d autres)" % (faults.size() - keep)


## La maison : le repère dans lequel « nord » et « arase » ont un sens.
func _house(place: Node3D) -> Node3D:
	for child: Node in place.find_children("*", "Node3D", true, false):
		if String(child.name) == "Fermette":
			return child as Node3D
	return null


## AABB d'un sous-arbre EXPRIMÉE dans le repère de `frame`.
## PIÈGE R2B.1 recopié ici : composer les transforms AVANT de toucher la boîte,
## sinon la rotation de 25° du bâtiment regonfle l'AABB deux fois.
func _bounds_in(node: Node3D, frame: Node3D) -> AABB:
	var inverse: Transform3D = frame.global_transform.affine_inverse()
	var merged: AABB = AABB()
	var first: bool = true
	var targets: Array[Node] = node.find_children("*", "MeshInstance3D",
		true, false)
	if node is MeshInstance3D:
		targets.append(node)
	for child: Node in targets:
		var instance: MeshInstance3D = child as MeshInstance3D
		if instance.mesh == null:
			continue
		var box: AABB = (inverse * instance.global_transform) \
			* instance.get_aabb()
		if first:
			merged = box
			first = false
		else:
			merged = merged.merge(box)
	return merged


## RMS des résidus d'un ajustement linéaire, rapporté à l'amplitude, dans
## l'espace demandé. `en_log` cherche une tendance MULTIPLICATIVE : une rampe
## géométrique y devient une droite et se démasque.
func _part_residu(xs: Array[float], ys: Array[float], en_log: bool) -> float:
	var vals: Array[float] = []
	for v: float in ys:
		if en_log:
			if v <= 1e-4:
				return 1e9   # log indéfini : l'indicateur linéaire tranchera
			vals.append(log(v))
		else:
			vals.append(v)
	var n: int = xs.size()
	var mx: float = 0.0
	var my: float = 0.0
	for k: int in range(n):
		mx += xs[k]
		my += vals[k]
	mx /= float(n)
	my /= float(n)
	var sxy: float = 0.0
	var sxx: float = 0.0
	for k: int in range(n):
		sxy += (xs[k] - mx) * (vals[k] - my)
		sxx += (xs[k] - mx) * (xs[k] - mx)
	var pente: float = sxy / maxf(sxx, 1e-9)
	var ord0: float = my - pente * mx
	var carres: float = 0.0
	var bas: float = 1e9
	var haut: float = -1e9
	for k: int in range(n):
		var r: float = vals[k] - (pente * xs[k] + ord0)
		carres += r * r
		bas = minf(bas, vals[k])
		haut = maxf(haut, vals[k])
	return sqrt(carres / float(n)) / maxf(haut - bas, 1e-6)


## Le plus grand résidu POSITIF de l'ajustement linéaire, en mètres : la dent
## qui survit au-dessus de la tendance.
func _plus_grand_residu(xs: Array[float], ys: Array[float]) -> float:
	var n: int = xs.size()
	var mx: float = 0.0
	var my: float = 0.0
	for k: int in range(n):
		mx += xs[k]
		my += ys[k]
	mx /= float(n)
	my /= float(n)
	var sxy: float = 0.0
	var sxx: float = 0.0
	for k: int in range(n):
		sxy += (xs[k] - mx) * (ys[k] - my)
		sxx += (xs[k] - mx) * (xs[k] - mx)
	var pente: float = sxy / maxf(sxx, 1e-9)
	var ord0: float = my - pente * mx
	var dent: float = -1e9
	for k: int in range(n):
		dent = maxf(dent, ys[k] - (pente * xs[k] + ord0))
	return dent


func _named_child(root: Node3D, prefix: String) -> Node3D:
	for child: Node in root.find_children("*", "Node3D", true, false):
		if String(child.name).begins_with(prefix):
			return child as Node3D
	return null


## -- A. Chaque pièce de la ruine porte UV0 ET une texture --------------------
##
## Rouge avant le geste : 23 surfaces sur 23 sans l'un ni l'autre.

func test_chaque_piece_porte_uv0_et_une_texture() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	var surfaces: int = 0
	var sans_uv: int = 0
	var sans_texture: int = 0
	if place == null:
		faults.append("ferme : la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		for child: Node in place.find_children("*", "MeshInstance3D", true,
				false):
			var instance: MeshInstance3D = child as MeshInstance3D
			if instance.mesh == null:
				continue
			if not String(instance.name).begins_with("SM_Farm_"):
				continue
			for s: int in range(instance.mesh.get_surface_count()):
				surfaces += 1
				var format: int = instance.mesh.surface_get_format(s)
				if (format & Mesh.ARRAY_FORMAT_TEX_UV) == 0:
					sans_uv += 1
					faults.append("%s s%d : pas d'UV0" % [instance.name, s])
					continue
				var mat: StandardMaterial3D = instance.get_active_material(s) \
					as StandardMaterial3D
				if mat == null or mat.albedo_texture == null:
					sans_texture += 1
					faults.append("%s s%d : aucune albedo_texture — couleur "
						% [instance.name, s] + "plate, la matière du kit "
						+ "voisin n'est pas reprise")
		if surfaces < SURFACES_MIN:
			faults.append("seulement %d surface(s) SM_Farm_* inspectée(s) "
				% surfaces + "(plancher %d) — le contrôle ne regarde rien"
				% SURFACES_MIN)
		_dismount(place)
	check(faults.is_empty(),
		"les %d surfaces des pièces SM_Farm_* portent UV0 et une texture "
		% surfaces + "(%d sans UV0, %d sans texture) — %s"
		% [sans_uv, sans_texture, _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (matière) — %s" % restore_root_reason())


## -- B. Les pièces frontales ENTRENT dans le mur -----------------------------
##
## Rouge avant le geste : tableaux Z ∈ [-0,10 ; +0,42] (42 cm de saillie),
## pignon 0,68 m d'épaisseur pour 0,34 m de surplomb.

func test_les_pieces_frontales_entrent_dans_le_mur() -> void:
	var faults: Array[String] = []
	var packed: PackedScene = load(FARM_GLB) as PackedScene
	if packed == null:
		faults.append("le GLB de ruine ne se charge pas")
	else:
		var racine: Node3D = packed.instantiate() as Node3D
		var vus: int = 0
		for child: Node in racine.find_children("*", "MeshInstance3D", true,
				false):
			var instance: MeshInstance3D = child as MeshInstance3D
			if instance.mesh == null:
				continue
			var nom: String = String(instance.name)
			var box: AABB = instance.mesh.get_aabb()
			if nom.begins_with("SM_Farm_Jamb_"):
				vus += 1
				if box.end.z > TABLEAU_SAILLIE_MAX_M:
					faults.append("%s SAILLE de %.2f m devant le parement "
						% [nom, box.end.z] + "(max %.2f) — pilastre plaqué, "
						% TABLEAU_SAILLIE_MAX_M + "pas un tableau de baie")
				if box.position.z > -TABLEAU_ENFONCEMENT_MIN_M:
					faults.append("%s n'entre que de %.2f m dans la tranche "
						% [nom, -box.position.z] + "(min %.2f)"
						% TABLEAU_ENFONCEMENT_MIN_M)
			elif nom.begins_with("SM_Farm_GableBreak"):
				vus += 1
				if box.size.z > PIGNON_EPAISSEUR_MAX_M:
					faults.append("pignon épais de %.2f m (max %.2f) sur un "
						% [box.size.z, PIGNON_EPAISSEUR_MAX_M]
						+ "mur de 0,40 — il déborde des deux côtés")
				# LE DEHORS N'EST PAS DU MÊME CÔTÉ POUR LES DEUX PIÈCES, et
				# l'oublier fait mesurer la bonne valeur au mauvais endroit.
				# Les tableaux vivent sur le mur SUD, dont l'extérieur est
				# +Z : leur saillie est `end.z`. Le pignon coiffe le mur NORD,
				# dont l'extérieur est -Z : sa saillie est `-position.z`.
				# Vérifié sur les deux états : géométrie R2B.1 (z ∈ [-0,34 ;
				# +0,34]) → 0,34 m, ROUGE ; géométrie R2B.2 → 0,03 m.
				var saillie: float = -box.position.z
				if saillie > PIGNON_SAILLIE_MAX_M:
					faults.append("pignon en surplomb de %.2f m devant le "
						% saillie + "parement nord (max %.2f)"
						% PIGNON_SAILLIE_MAX_M)
		racine.free()
		if vus < 3:
			faults.append("%d pièce(s) frontale(s) trouvée(s) au lieu de 3 "
				% vus + "(deux tableaux, un pignon) — le contrôle ne regarde "
				+ "rien")
	check(faults.is_empty(),
		"tableaux et pignon entrent dans le mur au lieu d'être plaqués "
		+ "(%d écart(s)) — %s" % [faults.size(), _capped(faults)])


## -- D1. Le pignon est SOLIDAIRE du mur --------------------------------------
##
## Rouge avant le geste : recouvrement 0,06 m, débord 0,34 m.

func test_le_pignon_est_solidaire_du_mur_nord() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	if place == null:
		faults.append("ferme : la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var house: Node3D = _house(place)
		var pignon: Node3D = _named_child(place, "SM_Farm_GableBreak")
		if house == null:
			faults.append("aucun nœud « Fermette » — repère introuvable")
		elif pignon == null:
			faults.append("aucun pignon SM_Farm_GableBreak")
		else:
			var box: AABB = _bounds_in(pignon, house)
			var recouvrement: float = ARASE_M - box.position.y
			if recouvrement < PIGNON_RECOUVREMENT_MIN_M:
				faults.append("le pignon ne recouvre l'arase que de %.2f m "
					% recouvrement + "(min %.2f) — il COIFFE une arête au "
					% PIGNON_RECOUVREMENT_MIN_M
					+ "lieu d'être les assises hautes du mur")
			var debord: float = -DEMI_M - box.position.z
			if debord > PIGNON_DEBORD_MAX_M:
				faults.append("le pignon déborde de %.2f m hors du parement "
					% debord + "nord (max %.2f) — bandeau en surplomb, donc "
					% PIGNON_DEBORD_MAX_M + "plaque posée")
		_dismount(place)
	check(faults.is_empty(),
		"le pignon partage le plan et les assises hautes du mur nord "
		+ "(%d écart(s)) — %s" % [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (pignon) — %s" % restore_root_reason())


## -- D2. Le sommet du mur NORD manque ----------------------------------------
##
## Le filet R2B.1 mesure la dispersion sur TOUTE la maçonnerie : le pignon et
## le moignon est suffisent à la faire passer pendant que le mur nord reste un
## rectangle intact. Ici la ligne d'arase du SEUL mur nord est échantillonnée
## en colonnes de 0,25 m — c'est le profil, pas l'AABB d'une pièce, car une
## pièce qui part du faîte et descend garde une AABB haute.
##
## Rouge avant le geste : écart-type 0,000 m, point bas 3,12 m.

func test_le_sommet_du_mur_nord_manque() -> void:
	remember_root()
	var faults: Array[String] = []
	var place: Node3D = _mount_alone(FARM_SCENE)
	var colonnes: Dictionary = {}
	if place == null:
		faults.append("ferme : la scène ne se monte pas seule")
	else:
		await _tree().process_frame
		var house: Node3D = _house(place)
		if house == null:
			faults.append("aucun nœud « Fermette » — repère introuvable")
		else:
			var inverse: Transform3D = house.global_transform.affine_inverse()
			for child: Node in house.find_children("*", "MeshInstance3D",
					true, false):
				var instance: MeshInstance3D = child as MeshInstance3D
				if instance.mesh == null:
					continue
				var nom: String = String(instance.get_parent().name)
				var propre: String = String(instance.name)
				# LE PIGNON EST EXCLU, ET C'EST LE CŒUR DU CONTRÔLE. Mesuré
				# le 2026-08-19 : en l'incluant, ses sommets à 4,31 m suffisent
				# à eux seuls à faire passer l'écart-type, et un mur nord
				# rectangulaire intact passe sous une plaque posée dessus —
				# très exactement le défaut que ce contrôle doit attraper.
				# Ici on mesure le COURONNEMENT DU MUR, pas sa superstructure.
				var maconnerie: bool = nom.begins_with("Wall_UnevenBrick") \
					or propre.begins_with("Wall_UnevenBrick") \
					or propre.begins_with("SM_Farm_WallBreak") \
					or nom.begins_with("Corner_Exterior") \
					or propre.begins_with("Corner_Exterior")
				if not maconnerie:
					continue
				var vers_maison: Transform3D = inverse \
					* instance.global_transform
				# ÉCHANTILLONNAGE PAR TRIANGLE, PAS PAR SOMMET — corrigé
				# après un sabotage qui ne rougissait pas. Le module de kit
				# décrit sa face par DEUX triangles : lire ses sommets ne
				# donne que deux colonnes, et un mur de 2 m remis en place
				# pesait autant qu'un caillou dans le profil. Un triangle
				# COUVRE l'intervalle de colonnes qu'il traverse.
				for s: int in range(instance.mesh.get_surface_count()):
					var arrays: Array = instance.mesh.surface_get_arrays(s)
					var sommets: PackedVector3Array = \
						arrays[Mesh.ARRAY_VERTEX]
					var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
					var total: int = index.size() if index.size() > 0 \
						else sommets.size()
					var t: int = 0
					while t + 2 < total:
						var trio: Array[Vector3] = []
						for k: int in range(3):
							var idx: int = index[t + k] if index.size() > 0 \
								else t + k
							trio.append(vers_maison * sommets[idx])
						t += 3
						var dedans: bool = false
						for q: Vector3 in trio:
							if q.z <= NORD_BANDE_Z_MAX:
								dedans = true
						if not dedans:
							continue
						var x0: float = minf(trio[0].x,
							minf(trio[1].x, trio[2].x))
						var x1: float = maxf(trio[0].x,
							maxf(trio[1].x, trio[2].x))
						var c0: int = int(floor(x0 / NORD_COLONNE_M))
						var c1: int = int(floor(x1 / NORD_COLONNE_M))
						for cle: int in range(c0, c1 + 1):
							# LA COUPE DU TRIANGLE À L'ABSCISSE DE LA COLONNE,
							# pas son sommet le plus haut. Deuxième correction
							# du même contrôle : le prisme d'un pan arraché a
							# une face avant en N-GON, et sa triangulation
							# produit des triangles qui vont du faîte au pied
							# en traversant toute la pièce. Prendre leur y_max
							# relevait le couronnement partout et effaçait
							# précisément le manque qu'on mesure.
							var xc: float = (float(cle) + 0.5) \
								* NORD_COLONNE_M
							if xc < x0 or xc > x1:
								continue
							var haut: float = -1e9
							for k: int in range(3):
								var a: Vector3 = trio[k]
								var b: Vector3 = trio[(k + 1) % 3]
								if absf(b.x - a.x) < 1e-6:
									if absf(a.x - xc) <= NORD_COLONNE_M * 0.5:
										haut = maxf(haut, maxf(a.y, b.y))
									continue
								var u: float = (xc - a.x) / (b.x - a.x)
								if u < 0.0 or u > 1.0:
									continue
								haut = maxf(haut, a.y + (b.y - a.y) * u)
							if haut < -1e8:
								continue
							if not colonnes.has(cle) \
									or float(colonnes[cle]) < haut:
								colonnes[cle] = haut
			var hauteurs: Array[float] = []
			for cle: int in colonnes.keys():
				hauteurs.append(float(colonnes[cle]))
			if hauteurs.size() < NORD_COLONNES_MIN:
				faults.append("%d colonne(s) d'arase nord échantillonnée(s) "
					% hauteurs.size() + "(plancher %d) — le contrôle ne "
					% NORD_COLONNES_MIN + "regarde rien")
			else:
				var somme: float = 0.0
				var bas: float = 1e9
				for h: float in hauteurs:
					somme += h
					bas = minf(bas, h)
				var moyenne: float = somme / float(hauteurs.size())
				var variance: float = 0.0
				for h: float in hauteurs:
					variance += (h - moyenne) * (h - moyenne)
				var ecart: float = sqrt(variance / float(hauteurs.size()))
				if ecart < NORD_ECART_TYPE_MIN_M:
					faults.append("arase nord d'écart-type %.3f m sur %d "
						% [ecart, hauteurs.size()] + "colonnes (min %.2f) — "
						% NORD_ECART_TYPE_MIN_M + "le mur est un rectangle")
				if bas > NORD_POINT_BAS_MAX_M:
					faults.append("point bas de l'arase nord à %.2f m "
						% bas + "(max %.2f) — rien ne MANQUE au mur"
						% NORD_POINT_BAS_MAX_M)
				var basses: int = 0
				for h: float in hauteurs:
					if h <= NORD_MANQUE_SEUIL_M:
						basses += 1
				# — irrégularité de l'arrachement, et plateau non intact —
				var ordre: Array = colonnes.keys()
				ordre.sort()
				var profil: Array[float] = []
				for cle: int in ordre:
					profil.append(float(colonnes[cle]))
				var plus_haut: float = 0.0
				for h: float in profil:
					plus_haut = maxf(plus_haut, h)
				# L'ARÊTE D'ARRACHEMENT SEULE, ET CONTIGUË.
				#
				# La première version retenait TOUTES les colonnes sous le
				# seuil, à index conservés. Le lead a reproduit le calcul le
				# 2026-08-19 et montré que la sélection n'était pas contiguë :
				# trois colonnes d'ENCOCHES du plateau (idx 9, 10, 13) très à
				# gauche, sept colonnes d'ARRACHEMENT (idx 18-24) très à
				# droite. Aucune droite ne passe par les deux paquets, donc le
				# résidu était gonflé par la DISTANCE entre eux : 16,3 % pour
				# l'ensemble, mais 8,6 % pour l'arête seule. Un numéro unique
				# mesurait deux propriétés, et la présence d'encoches ailleurs
				# payait pour l'irrégularité de l'arête.
				#
				# Les encoches restent couvertes — par la règle de plateau
				# (≤ 10 colonnes identiques), qui est faite pour elles. Ici on
				# ne juge QUE le plus long segment contigu sous le seuil.
				var ix: Array[float] = []
				var hy: Array[float] = []
				var debut: int = -1
				var longueur: int = 0
				var course: int = 0
				for k: int in range(profil.size() + 1):
					var dedans: bool = k < profil.size() \
						and profil[k] < plus_haut - NORD_DESCENTE_MARGE_M
					if dedans:
						course += 1
					else:
						if course > longueur:
							longueur = course
							debut = k - course
						course = 0
				for k: int in range(debut, debut + longueur):
					if k < 0:
						break
					ix.append(float(k))
					hy.append(profil[k])
				if ix.size() < NORD_DESCENTE_MIN_COLONNES:
					faults.append("%d colonne(s) descendante(s) seulement "
						% ix.size() + "(min %d) — pas d'arrachement à juger"
						% NORD_DESCENTE_MIN_COLONNES)
				else:
					var lin: float = _part_residu(ix, hy, false)
					var log_: float = _part_residu(ix, hy, true)
					var indic: float = minf(lin, log_)
					var dent: float = _plus_grand_residu(ix, hy)
					if indic < NORD_RESIDU_PART_MIN:
						faults.append("l'arête d'arrachement (%d colonnes "
							% ix.size() + "contiguës) colle à sa tendance : "
							+ "résidu %.1f %% en linéaire, %.1f %% en log, "
							% [lin * 100.0, log_ * 100.0]
							+ "indicateur %.1f %% (min %.0f %%) — de loin "
							% [indic * 100.0, NORD_RESIDU_PART_MIN * 100.0]
							+ "c'est un trait tiré à la règle, pas une "
							+ "maçonnerie rompue")
					if dent < NORD_DENT_MIN_M:
						faults.append("aucune assise ne survit sur l'ARÊTE "
							+ "au-dessus de sa tendance : plus grand résidu "
							+ "positif %+.3f m (min %.2f) — un arrachement "
							% [dent, NORD_DENT_MIN_M]
							+ "monotone n'a pas de dents")
				var plat: int = 1
				var plat_max: int = 1
				for k: int in range(1, profil.size()):
					if absf(profil[k] - profil[k - 1]) < NORD_PLAT_TOLERANCE_M:
						plat += 1
					else:
						plat = 1
					plat_max = maxi(plat_max, plat)
				if plat_max > NORD_PLAT_MAX_COLONNES:
					faults.append("%d colonnes d'arase strictement identiques "
						% plat_max + "d'affilée, soit %.2f m (max %d colonnes)"
						% [float(plat_max) * NORD_COLONNE_M,
						   NORD_PLAT_MAX_COLONNES] + " — le pan resté debout "
						+ "n'a pas perdu une seule pierre")
				var part: float = float(basses) / float(hauteurs.size())
				if part < NORD_MANQUE_PART_MIN:
					faults.append("seulement %.0f %% du couronnement nord "
						% (part * 100.0) + "est sous %.2f m (min %.0f %%) — "
						% [NORD_MANQUE_SEUIL_M, NORD_MANQUE_PART_MIN * 100.0]
						+ "%d colonne(s) sur %d : un creux ponctuel, pas un "
						% [basses, hauteurs.size()] + "pan de mur qui manque")
		_dismount(place)
	check(faults.is_empty(),
		"le sommet du mur nord montre un manque structurel (%d écart(s)) — %s"
		% [faults.size(), _capped(faults)])
	var clean: bool = await restore_root()
	check(clean, "démontage propre (mur nord) — %s" % restore_root_reason())
