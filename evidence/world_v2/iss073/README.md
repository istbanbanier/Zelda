# ISS-073 — le portail est ROUGE avant tout correctif

Date : 2026-08-27. Commit de l'arbre : `05ad4d89457f37b4839e9a86f8782375f9e68218`.
Commande : `tools/lancer_godot.sh --path . --script tools/godot/test_runner.gd -- --filter=iss073`
Code retour : **1**.

```
=== RÉSULTAT: 1 réussi(s), 8 échoué(s) ===
```

## Les huit échecs, et ce que chacun prouve

| Échec | Ce qu'il établit |
|---|---|
| Aucune `SceneDoor` dans World V2 | le donjon est inatteignable |
| Aucune porte ne vise le vestibule | le marqueur `dungeon_gate` est un `Node3D` nu |
| L'interaction ne demande rien | appuyer sur E au seuil ne fait rien |
| Aucun tag de retour posé | le vestibule ne saurait pas d'où l'on vient |
| `pending_spawn` NON consommé par World V2 | il resservirait à la transition suivante |
| Retour en (0, 170) au lieu de (0, -210) | le héros réapparaît au spawn initial |
| 3 chemins visent encore `ValleyWorld.tscn` | un joueur V2 serait déposé dans le monde V1 |

## Ce que le portail NE fait PAS, et qui fait sa valeur

Il n'appelle ni `SceneDoor.interact()`, ni `SceneFlow.go_to()`, et
n'écrit aucune position de joueur. Le héros **marche** la route
officielle lue au monde monté — celle de `test_world_v2_traversal.gd`,
pas des jalons inventés — puis on appuie sur la touche d'interaction.
Atteindre les coordonnées du seuil ne compte pas comme un passage.

## Trois défauts de ma première version, corrigés avant de figer

1. **Des jalons inventés** enlisaient le héros vers z = -150, dans un
   relief que personne n'avait marché. Le portail lit désormais la
   route officielle au groupe `world_v2_routes` du monde monté.
2. **Un `SCRIPT ERROR`** sur `seuil.global_position` quand la porte
   est absente — il avortait le cas en silence et masquait les vraies
   raisons. Garde posée.
3. **Le monde restait dans l'arbre** : le démontage passe maintenant
   par `remember_root()` / `restore_root()`, le contrat de la classe
   de base, et non par un `queue_free()` qui survit une frame.
