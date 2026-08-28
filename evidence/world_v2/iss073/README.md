# ISS-073 — la boucle de campagne, prouvée

**Commit de la correction** : `03e8b9d` (portail + correctif), `b2e5bb1`
(chaîne combinée), `b8fd648` (levée de gel documentée).
**Moteur** : Godot 4.7.1.stable.custom_build.a13da4feb, conteneur headless
sans GPU (Xvfb + Mesa llvmpipe pour tout ce qui rend).

## Le défaut, tel qu'il était

Le menu principal ouvre `WorldV2.tscn` depuis le passage à World V2
(`scripts/ui/main_menu.gd`, `WORLD_SCENE`). Trois ruptures s'ensuivaient :

| # | Rupture | Constat |
|---|---|---|
| 1 | Aucune `SceneDoor` sous `scripts/world_v2/` ni `scenes/world_v2/` | le donjon était **inatteignable** : `dungeon_gate` est un `Node3D` nu, avec lequel on ne peut pas interagir |
| 2 | `WorldV2Root` ne consommait aucun `pending_spawn` | un retour du vestibule replaçait le héros au spawn initial |
| 3 | Deux chemins de campagne visaient encore le monde V1 | `victory_screen.gd::VALLEY_SCENE` et la porte de sortie du vestibule |

## Les deux portails

```bash
tools/lancer_godot.sh --path . --script tools/godot/test_runner.gd -- --filter=iss073
```

- `tests/world_v2/test_world_v2_iss073_boucle.gd` — 5 cas, 23 assertions.
  Part du menu principal, monte World V2, MARCHE la route officielle jusqu'au
  seuil, franchit par la touche d'interaction, puis vérifie le retour.
- `tests/world_v2/test_world_v2_iss073_chaine.gd` — 4 cas, 29 assertions.
  Les deux retours vers World V2 sont JOUÉS ; l'intérieur du donjon est
  vérifié en câblage, et le fichier le dit en toutes lettres.

## Ce que les portails s'interdisent

Appeler `SceneDoor.interact()`, appeler `SceneFlow.go_to()`, écrire
`global_position` après le spawn. Le seul geste est la touche d'interaction,
et la marche est mesurée : plus grand déplacement en un tick, et distance
parcourue depuis le spawn.

## Sabotages joués

Chacun a été posé, mesuré, puis retiré. Aucun n'est resté dans l'arbre.

| Sabotage | Assertions rougies | Message |
|---|---:|---|
| `door.spawn_tag = &""` | 2 | « la porte d'ALLER doit poser le tag que le vestibule consomme » |
| `if false and arrival == RETURN_TAG` | 2 | retour mesuré en `(0, 170)` — le spawn initial — au lieu de `(0, -210)` |
| sortie du vestibule renvoyée vers V1 | 5 | dont l'énumération des portes qui NOMME la coupable |
| `DoorArena` détournée vers le hall | 1 | « l'antichambre doit ouvrir l'arène » |
| marche supprimée | 2 | l'interaction ne part pas : le héros entre dos à la porte |

Le deuxième reproduit **exactement** le symptôme d'ISS-073.

## Ce que ces portails NE prouvent PAS

Ils tournent dans l'éditeur headless. Ils ne disent rien de la build exportée
— c'est précisément l'angle mort qui a laissé passer ISS-071. La preuve
d'empaquetage est ailleurs : `tools/gate_export_parite.sh` et
`tools/fumee_build_exportee.py`, sur un binaire autonome lancé.
