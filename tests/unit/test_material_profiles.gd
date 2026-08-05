## P2-2 — les 8 profils de matériau canoniques (P2 §4.1) existent en données,
## avec des IDs uniques et des valeurs dans les bornes des lois.
##
## Fail-first : écrit avant les .tres. La cohérence avec §11.1 est testée là où
## elle est exigible : le bois quasi isolant, le métal très conducteur — les
## mêmes échelles que les armes (gourdin 0,05, épée 0,85).
extends GateTestCase

const DIR: String = "res://resources/materials/"
const EXPECTED: Array[StringName] = [
	&"bois", &"metal", &"pierre", &"ceramique",
	&"eau", &"terre_conductrice", &"organique", &"isolant",
]


func test_the_eight_canonical_profiles_load_with_unique_ids_and_lawful_values() -> void:
	var seen: Array[StringName] = []
	for id: StringName in EXPECTED:
		var path: String = DIR + "MAT_PROFILE_%s.tres" % id
		var profile: MaterialProfile = load(path) as MaterialProfile
		check(profile != null, "profil chargé : %s" % path)
		if profile == null:
			continue
		check(profile.id == id, "id interne = nom de fichier (%s)" % id)
		check(not profile.id in seen, "id unique : %s" % id)
		seen.append(profile.id)
		check(profile.conductivity >= 0.0 and profile.conductivity <= 1.0,
			"%s : conductivité dans [0;1]" % id)
		check(profile.flammability >= 0.0 and profile.flammability <= 1.0,
			"%s : inflammabilité dans [0;1]" % id)
		check(profile.fragility >= 0.0 and profile.fragility <= 1.0,
			"%s : fragilité dans [0;1]" % id)
		check(profile.logical_mass >= 0.0, "%s : masse ≥ 0" % id)


func test_profiles_respect_the_material_laws_of_the_world() -> void:
	var wood: MaterialProfile = load(DIR + "MAT_PROFILE_bois.tres") as MaterialProfile
	var metal: MaterialProfile = load(DIR + "MAT_PROFILE_metal.tres") as MaterialProfile
	var ceramic: MaterialProfile = load(DIR + "MAT_PROFILE_ceramique.tres") as MaterialProfile
	var stone: MaterialProfile = load(DIR + "MAT_PROFILE_pierre.tres") as MaterialProfile
	var water: MaterialProfile = load(DIR + "MAT_PROFILE_eau.tres") as MaterialProfile
	if wood == null or metal == null or ceramic == null or stone == null or water == null:
		check(false, "profils requis manquants")
		return
	check(wood.conductivity < 0.15, "le bois est quasi isolant (échelle §11.1)")
	check(wood.flammability > 0.0 and wood.absorbs_water, "le bois brûle et absorbe")
	check(metal.conductivity > 0.7, "le métal conduit (échelle §11.1)")
	check(metal.charge_capacity > 0.0, "le métal stocke la charge")
	check(metal.flammability == 0.0, "le métal ne brûle pas")
	check(ceramic.conductivity == 0.0 and ceramic.fragility > 0.5,
		"la céramique isole et casse — le langage du donjon (§15.4)")
	check(stone.fragility == 0.0, "la pierre est incassable par impact")
	check(water.conductivity >= 0.9, "l'eau conduit fortement (§14.4)")
