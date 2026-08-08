# Preuves de la Phase S1 — gate BOOT-TO-FUN

| | |
|---|---|
| Commit prouvé | `1271410ab729f00eeccf4786226ababbd8bed698` |
| Branche | `claude/world-of-claudecraft-advice-snt1qa` |
| Arbre au moment des exécutions | **propre** (`git status --short` vide hors ce dossier) |
| Godot | `4.7.1.stable.custom_build.a13da4feb` |
| Renderer | `forward_plus`, pilote `headless` |
| Physique 3D | Jolt Physics, tick 60 Hz |
| Date | 2026-08-08 |

## Ce que contient chaque fichier

| Fichier | Nature | Autorité |
|---|---|---|
| `boot_smoke.log` | parcours court, arbre **non modifié** | **preuve** |
| `golden_path.log` | parcours long, arbre **non modifié** | **preuve** |
| `controle_negatif.log` | deux sabotages, chacun dans un worktree jetable | **preuve** |
| `boot_smoke_INSTRUMENTE.log` | même test, `GateTestRecorder.record()` rallongé d'un `print` | **lecture, pas preuve** |
| `golden_path_INSTRUMENTE.log` | idem | **lecture, pas preuve** |

Les deux fichiers `_INSTRUMENTE` viennent d'un **worktree détaché jetable**, patché
d'une seule ligne pour imprimer aussi les assertions réussies — le runner ne
publie que les échecs. Ce patch ne touche aucune assertion, mais il rend l'arbre
sale : ils sont donc versés comme **lecture détaillée**, jamais comme preuve.
`.claude/rules/evidence.md` exige `repo_dirty: false` ; ces deux-là ne l'ont pas.
Le worktree a été détruit après mesure (`git worktree list` ne montre que
l'arbre principal).

## Verdicts

| Étape | Commande | Résultat |
|---|---|---|
| Parcours court | `--filter=boot_smoke` | **1 réussi / 0 échoué**, 20 assertions, code 0 |
| Parcours long | `--filter=golden_path` | **1 réussi / 0 échoué**, 20 assertions, code 0 |
| Contrôle négatif | `tools/gate_negative_control.sh` | **2 sabotages sur 2 vus**, code 0 |

## Les valeurs mesurées, pas seulement le vert

Extraites des lectures instrumentées :

- héros au réveil : **100,0 PV**, posé au sol, `y = 32,00` ;
- soulevé de 3 m, il retombe : `35,00 → 32,00` ;
- première interaction : **7 m** du spawn ;
- premier ennemi : **93 m** du spawn ;
- premier coffre atteint : **86 m**, inventaire **1 → 2 armes** ;
- l'ennemi encaisse : **45,0 → 33,0 PV** ;
- Pulse depuis le monde chargé : verdict **`fired`** ;
- porte de la citadelle : **344 m** du spawn.

## Une observation du run, qui n'est pas un blocage

`boot_smoke.log` porte un avertissement, et un seul :

```
WARNING: [save] santé sauvegardée invalide (0.0) — pleine vie
         valley_world.gd:991  _restore_player_vitals
```

Il n'apparaît **pas** dans `golden_path.log`. La différence entre les deux
parcours est que seul le court tue le héros : l'alerte appartient donc au
rechargement après « Réessayer ». La sauvegarde écrite à la mort porte
`player_health = 0.0`, et la reprise repasse à pleine vie par la branche
défensive `elif value <= 0.0`, pas par une règle de checkpoint.

Le jeu s'en sort — `B9c` est vert — donc ce n'est pas un blocage. C'est le seul
défaut réel que ce gate ait trouvé dans le jeu.
