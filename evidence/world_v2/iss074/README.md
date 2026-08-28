# ISS-074 — le portail rouge du peuplement

Date : 2026-08-28 · branche `claude/world-v2-iss074-population-contract` ·
base `a8d2f77` (la candidate de lundi).

    tools/lancer_godot.sh --path . --script tools/godot/test_runner.gd -- --filter=iss074

    === RÉSULTAT: 0 réussi(s), 2 échoué(s) ===
    erreurs de script dans le journal : 0

Les deux échecs sont le CONSTAT, mesuré sur le monde monté :
1. aucun adversaire du groupe `enemies` n'existe dans World V2 ;
2. aucun `CombatCoordinator` ne gouverne le monde.

Ce rouge est VOLONTAIRE et vit sur cette branche seulement — c'est la
définition exécutable de « ISS-074 fermée », écrite avant toute production,
comme le portail ISS-073 l'a été pour la boucle. La candidate de lundi ne
porte ni ce test ni ce rouge.

La suite de CETTE branche est donc rouge par construction : ne pas y lancer
`validate_fast.sh` en s'attendant à du vert, et ne rien y publier.
