# Preuves de la Phase S1 — gate BOOT-TO-FUN

| | |
|---|---|
| Commit prouvé | `27a2cc7` |
| Branche | `claude/world-of-claudecraft-advice-snt1qa` — **non poussée** |
| Arbre au moment des exécutions | **propre** hors ce dossier |
| Godot | `4.7.1.stable.custom_build.a13da4feb` |
| Renderer | `forward_plus`, pilote `headless` |
| Physique 3D | Jolt Physics, tick 60 Hz |
| Date | 2026-08-09 |

## Verdicts

| Étape | Commande | Résultat |
|---|---|---|
| Suite complète | `tools/validate_fast.sh` | **806 réussis / 0 échoué — VERT, code 0** |
| Parcours court | `--filter=boot_smoke` | 1 réussi / 0 échoué, **19 assertions**, code 0 |
| Parcours long | `--filter=golden_path` | 1 réussi / 0 échoué, **20 assertions**, code 0 |
| Contrôle négatif | `tools/gate_negative_control.sh` | **2 sabotages sur 2 vus**, code 0 |
| Anti-empoisonnement | `--filter=boot_smoke,dungeon_run,golden_path` | 4 réussis / 0 échoué |

806 = 804 avant S1 + les deux nouveaux parcours. Aucune régression.

## Ce que contient chaque fichier

| Fichier | Nature | Autorité |
|---|---|---|
| `validate_fast.log` | suite entière | **preuve** |
| `boot_smoke.log` | parcours court, arbre non modifié | **preuve** |
| `golden_path.log` | parcours long, arbre non modifié | **preuve** |
| `controle_negatif.log` | deux sabotages, worktrees jetables | **preuve** |
| `trio_anti_poison.log` | le trio qui reproduisait l'empoisonnement | **preuve** |
| `*_INSTRUMENTE.log` | `GateTestRecorder.record()` rallongé d'un `print` | **lecture, pas preuve** |

Les deux `_INSTRUMENTE` viennent d'un worktree détaché jetable : le runner ne
publie que les échecs, et vingt assertions vertes muettes ne se lisent pas. Le
patch ne touche aucune assertion mais rend l'arbre sale, donc ils ne sont pas
des preuves (`.claude/rules/evidence.md` exige `repo_dirty: false`). Le worktree
a été détruit après mesure.

## Ce que la suite complète a trouvé, et que l'isolation cachait

Au commit `1271410`, les deux parcours passaient seuls et `validate_fast.sh`
sortait **ROUGE : 802 réussis, 20 échoués**. Le premier échec était le mien —
`test_boot_smoke` laissait `Boot, ValleyWorld` dans l'arbre — et les dix-sept
suivants appartenaient à `test_dungeon_run`, qui démarrait à l'intérieur de
cette vallée fantôme trente fichiers plus loin.

Cause mesurée :

```
SCRIPT ERROR: Invalid access to property 'text' on a base object of type
              'previously freed' — test_boot_smoke.gd:110
```

Sans sauvegarde existante, le premier appui sur « Nouvelle partie » part droit
vers la vallée et libère le menu ; lire `.text` ensuite avorte la méthode **en
silence**, donc le nettoyage ne s'exécute plus. Le test dépendait de l'existence
d'une sauvegarde laissée par un passage précédent.

Corrigé en deux points, éprouvés séparément : `is_instance_valid()` avant la
lecture (**19 assertions dans les deux branches**, sans et avec sauvegarde), et
`GateTestCase.remember_root()` / `restore_root()`, qui attend la fin réelle de
`SceneFlow` puis retire le **delta** de la racine.

## Les valeurs mesurées, pas seulement le vert

- héros au réveil : **100,0 PV**, posé, `y = 32,00` ;
- soulevé de 3 m, il retombe : `35,00 → 32,00` ;
- première interaction : **7 m** du spawn ;
- premier ennemi : **93 m** ;
- premier coffre : **86 m**, inventaire **1 → 2 armes** ;
- l'ennemi encaisse : **45,0 → 33,0 PV** ;
- Pulse depuis le monde chargé : **`fired`** ;
- porte de la citadelle : **344 m** du spawn.

## Les deux limites que ces preuves ne couvrent PAS

1. **Le voyage n'est pas prouvé.** Le Golden Path appelle `interact()` sur une
   porte située à 344 m, et `SceneDoor.interact()` ne vérifie aucune distance.
   Il prouve que le graphe de transitions est câblé, jamais que le héros puisse
   parcourir les 344 mètres. Aucun test du dépôt ne fait **marcher** le héros
   dans la vallée : tous le posent.
2. **Tout ce qui suit la salle 1** — salles 2 à 4, salle centrale, antichambre,
   boss, victoire — reste `NON VÉRIFIÉ` en atteignabilité. `test_dungeon_run` et
   `test_boss_run` les chargent directement : ils prouvent la solvabilité, jamais
   l'arrivée.
