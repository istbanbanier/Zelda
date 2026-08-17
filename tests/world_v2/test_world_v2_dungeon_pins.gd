## V2.2 — épinglage des contraintes IMMUABLES du donjon, AVANT toute enveloppe.
##
## Le masterplan §10 autorise V2.2 à reconstruire l'ENVELOPPE du donjon
## (volumes, matière, lumière, présentation) et lui interdit de déplacer la
## LOGIQUE : positions de gameplay, topologie des salles, géométrie de
## l'arène. Ces littéraux sont copiés du MASTERPLAN, jamais des scripts
## qu'ils surveillent (PROMPT4 §4 : les tests épinglent les littéraux) — si
## un travail d'enveloppe bouge une constante, ce test rougit en la NOMMANT,
## avant que les suites de comportement n'aient à chercher pourquoi elles
## cassent. Écrit VERT contre la V1 intacte : c'est un fil de détente, pas
## un constat.
extends GateTestCase


func test_les_positions_de_gameplay_des_salles_sont_epinglees() -> void:
	# Salle 1 — Initiation : axe du couloir, ligne des plaques, départ du bloc.
	check_approx(Room1Initiation.CHANNEL_X, 0.0, 0.001, "salle 1 : axe du couloir")
	check_approx(Room1Initiation.CONTACT_Z, -4.0, 0.001, "salle 1 : ligne des plaques")
	check(Room1Initiation.BLOCK_START.is_equal_approx(Vector3(0, 0.81, 3.0)),
		"salle 1 : départ du bloc (0 ; 0,81 ; 3)")
	# Salle 2 — Circuit vertical : puits d'escalade et mezzanine.
	check_approx(Room2Vertical.CLIMB_X, -6.2, 0.001, "salle 2 : puits d'escalade")
	check_approx(Room2Vertical.MEZZANINE_Y, 16.5, 0.001, "salle 2 : mezzanine")
	# Salle 4 — Batterie : départs de la batterie et de la planche.
	check(Room4Battery.BATTERY_START.is_equal_approx(Vector3(-9.5, 0.6, 2.0)),
		"salle 4 : départ de la batterie (-9,5 ; 0,6 ; 2)")
	check(Room4Battery.PLANK_START.is_equal_approx(Vector3(-6.0, 0.4, 3.5)),
		"salle 4 : départ de la planche (-6 ; 0,4 ; 3,5)")


func test_la_geometrie_de_l_arene_est_epinglee() -> void:
	check_approx(BossArena.ARENA_RADIUS, 19.0, 0.001, "rayon jouable 19 m")
	check_approx(BossArena.WALL_RADIUS, 19.6, 0.001, "mur r 19,6")
	check_approx(BossArena.WALL_HEIGHT, 13.0, 0.001, "mur h 13")
	check_approx(BossArena.RAIL_RADIUS, 14.0, 0.001, "rail r 14")
	# Quatre pylônes espacés de 90°, AUX DIAGONALES : indices 3/9/15/21 sur
	# 24 segments = azimuts 45°, 135°, 225°, 315°.
	check_equal(BossArena.WALL_SEGMENTS, 24, "24 segments de mur")
	check_equal(BossArena.PYLON_INDICES, [3, 9, 15, 21] as Array[int],
		"pylônes aux diagonales (90° d'écart)")


func test_la_topologie_des_salles_est_epinglee() -> void:
	# Le chaînage vestibule → salle 1 → hub → branches → antichambre → arène
	# est un contrat protégé : les scènes se référencent par CES chemins.
	check_equal(Room4Battery.HALL, "res://scenes/dungeon/rooms/CentralHall.tscn",
		"la salle 4 rend au hub")
	check_equal(BossArena.ANTECHAMBER, "res://scenes/dungeon/rooms/Antechamber.tscn",
		"l'arène renvoie à l'antichambre")
	check_equal(BossArena.GUARDIAN, "res://scenes/boss/StormGuardian.tscn",
		"l'arène invoque le Gardien")
	for scene_path: String in [
			"res://scenes/dungeon/rooms/Room1Initiation.tscn",
			"res://scenes/dungeon/rooms/Room2Vertical.tscn",
			"res://scenes/dungeon/rooms/Room3Relays.tscn",
			"res://scenes/dungeon/rooms/Room4Battery.tscn",
			"res://scenes/dungeon/rooms/CentralHall.tscn",
			"res://scenes/dungeon/rooms/Antechamber.tscn"]:
		check(ResourceLoader.exists(scene_path),
			"la scène %s existe" % scene_path.get_file())
