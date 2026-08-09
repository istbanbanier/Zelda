# Preuves — S1 (infrastructure) et S2.0 (correction de `P9c`)

| | |
|---|---|
| Code éprouvé | `b0850e5b19716f2f4d251ac28e08d4582eab36e3` |
| Branche | `claude/world-of-claudecraft-advice-snt1qa`, **poussée** |
| Base de la passe S2.0 | `bec93f1ac9bb0bb311156055e718bb7d86f96ba7` |
| Arbre pendant les exécutions | propre — `git status --porcelain` vide, `git diff --check` muet |
| Godot | `4.7.1.stable.custom_build.a13da4feb` · `forward_plus` · headless · Jolt 60 Hz |
| Date | 2026-08-09 |

## Le verdict, en trois lignes qui ne se remplacent pas

| Question | Verdict | Pourquoi |
|---|---|---|
| **Gate automatique actuel** | **`PASS`** | `validate_fast` **VERT**, 816 réussis / 0 échoué, code 0 |
| **Couverture BOOT-TO-FUN complète** | **`NON VÉRIFIÉ`** | salles 2-4, salle centrale, antichambre, boss, victoire jamais atteints depuis le flux normal |
| **Critères humains** | **`BLOQUÉ`** | ni écran, ni clavier, ni manette, ni son, ni GPU |

**Verdict global : `NON VÉRIFIÉ`**, par la règle du plus faible critère. Un gate
vert ne dit pas que le jeu est jouable ; il dit que rien de ce qu'on sait
mesurer n'est cassé.

## Résultats

| Fichier | Commande | Résultat |
|---|---|---|
| `validate_fast.log` | `tools/validate_fast.sh` | **816 / 0 — VERT, code 0** |
| `dungeon_door_is_reachable.log` | `--filter=dungeon_door_is_reachable` | 3/0, 14 assertions |
| `regression_AVANT_correction.log` | le MÊME test sur `bec93f1` | **1/4 — ROUGE**, comme il se doit |
| `physical_run.log` | `--filter=physical_run` | 1/0, **32 assertions** |
| `flow_wiring.log` | `--filter=flow_wiring` | 1/0, 20 assertions |
| `boot_smoke.log` | `--filter=boot_smoke` | 1/0, 21 assertions |
| `restore_root.log` | `--filter=restore_root` | 6/0, six cas adverses |
| `anti_poison_sequentiel.log` | 7 fichiers chargeant un monde, à la suite | **15/0** |
| `controle_negatif.log` | `tools/gate_negative_control.sh` | 2 déclarés, 2 exécutés, **0 ignorés**, 2 validés |
| `controle_negatif_AUTOTEST.log` | signature fausse + fichier absent | **code 1** — les garde-fous mordent |
| `physical_run_INSTRUMENTE.log` | recorder rallongé d'un `print` | **lecture, pas preuve** — arbre sale |

Aucune fuite de ressources, aucun `SCRIPT ERROR`.

## S2.0 — `P9c` corrigé

Le défaut, mesuré pendant deux passes d'audit : à 0,75 m de la porte du donjon,
parfaitement en face, au sol, porte dans le groupe `interactable`,
`_select_interactable()` ne rendait **rien**. Le rayon de `_has_interact_los()`
— couche 1 — était coupé par `SealedSeam`, une veine cyan **décorative**
construite par `_box()` en `StaticBody3D` à `z = −12,50`, devant le battant à
`z = −12,75`.

La correction est locale et structurelle : `_decor_box()` produit un
`MeshInstance3D` seul — même boîte, même matériau, même émission, **aucun corps,
aucune forme de collision**. Rien d'autre n'a bougé : ni `INTERACT_RANGE`, ni le
cône, ni la ligne de vue, ni la position de la porte ou du joueur, et aucune
exception n'a été ajoutée au contrôleur.

Le contraste, extrait des deux lectures :

```
AVANT   vue=SealedSeam · choisi=aucun      → il fallait un pas de côté
APRÈS   vue=libre      · choisi=DungeonDoor → P9d : 0 repositionnement
```

### Le test de régression a bien rougi avant

`regression_AVANT_correction.log` : le même fichier, rejoué en worktree détaché
sur `bec93f1`, sort **1 réussi / 4 échoués** —

```
ÉCHEC  ligne de vue LIBRE au centre du battant (obstacle : SealedSeam)
ÉCHEC  le contrôleur DÉSIGNE `DungeonDoor` par identité (obtenu : aucune cible)
ÉCHEC  …mais ce n'est PLUS un corps de collision (classe : StaticBody3D)
ok     la porte garde son corps et son apparence
```

Le cas « la porte garde son corps » reste vert : ce n'est pas un test qui échoue
toujours.

### Ce que `physical_run` mesure maintenant

- 11/11 jalons de crête, 5/5 de la route du donjon ;
- coffre `RiverChest` ouvert à la touche, inventaire 1 → 2 armes ;
- 4 touches par `attack_pressed`, instigateur = le joueur ;
- `pulse_pressed` → 1 cible révélée ;
- **`P11` : 4 864 ticks physiques échantillonnés**, min y = 0,00 (seuil −5,0),
  aucune discontinuité de position ;
- **`P9c` PASS au centre**, **`P9d` : zéro repositionnement latéral**. Le
  parcours latéral survit comme filet, jamais comme solution — sans `P9d`, un
  retour du défaut serait absorbé par le filet et `P9b` resterait vert.

## Une fuite trouvée en chemin, et qui n'était pas `P9c`

Une fois `P9c` corrigé, tous les tests passaient mais le gate restait ROUGE sur
« 2 ObjectDB instances were leaked » et « resources still in use » — les deux
motifs ajoutés au filtre pendant S1, qui faisaient leur travail.

Source **nommée** par `--verbose` plutôt que devinée :
`res://assets/audio/sfx/amb_valley.wav`. Isolés un par un : `boot_smoke` propre,
`physical_run` propre, le nouveau test d'intégration propre, `test_audio_sfx`
fuit. Son cas `test_playing_a_sound_is_safe_even_headless` joue **tous** les sons
déclarés, `amb_valley` compris, et il vit dans `unit/` — donc il s'exécute
**après** les trois parcours, qui eux arrêtent l'ambiance. Le lecteur du pool
gardait le flux et sa lecture jusqu'à la fin du processus.

Il rend maintenant le pool comme il l'a trouvé. Ni le filtre ni le verdict n'ont
été arrangés pour obtenir ce vert.
