# D1 — deux instruments indépendants rendent le MÊME chiffre

Daté du 2026-08-21, avant que le moteur n'ait pu tourner (verrou tenu).

## Pourquoi ce croisement

Le contrôle D1 recalcule la boîtitude `hexa` **en GDScript, sur le maillage tel
que le moteur le porte**. `tools/mesure_boititude.py` la calcule **en Python,
sur les octets du GLB**. Ce sont deux chemins entièrement disjoints : accesseurs
glTF d'un côté, `Mesh.surface_get_arrays()` de l'autre.

Si les deux rendent le même nombre, c'est le **prédicat** qui est vérifié, et
non une ligne de code. C'est la facture retenue par
`tests/world_v2/test_world_v2_r2b3_debris.gd`, qui publie ses deux mesures
côte à côte pour cette raison exacte.

## La mesure

Sujet : `assets/architecture/flora/SM_ThunderstruckTree.glb`, un hero asset
**gelé** et **accepté** — donc un témoin dont la réponse est connue d'avance.

| mesh | tris | hexa (référence Python) | hexa (algorithme du filet) |
|---|---:|---:|---:|
| `SM_ThunderstruckTree_Bark` | 1660 | 0 | 0 |
| `SM_ThunderstruckTree_Heart` | 664 | 288 | 288 |
| `SM_ThunderstruckTree_Roots` | 756 | 0 | 0 |
| `SM_ThunderstruckTree_BranchA` | 132 | 24 | 24 |
| `SM_ThunderstruckTree_BranchB` | 66 | 0 | 0 |
| `SM_ThunderstruckTree_BranchC` | 80 | 12 | 12 |
| `SM_ThunderstruckTree_BranchD` | 148 | 36 | 36 |
| `SM_ThunderstruckTree_BranchE` | 68 | 12 | 12 |

**Identiques sur les huit meshes.** Agrégé : `372 / 3574 = 10,41 %`, ce qui est
exactement le « 10,4 % » que l'en-tête de `test_world_v2_r2b3_debris.gd`
publie pour cet asset. Trois sources concordent.

## LE CONSTAT QUI CHANGE UNE DÉCISION

`SM_ThunderstruckTree_Heart` vaut **43,4 %** de boîtitude, à lui seul. C'est
**au-dessus du plafond de 25 %** — et c'est un asset **accepté et gelé**.

Deux conséquences, toutes deux déjà appliquées dans le filet :

1. **La granularité est le LIEU, pas le maillage.** Juger maillage par maillage
   aurait rejeté le cœur pâle de l'arbre foudroyé, c'est-à-dire la géométrie qui
   porte la lecture de la fente. Le filet agrège les triangles runtime d'un lieu
   avant de comparer au plafond.
2. **Le périmètre est le RUNTIME, pas l'importé.** Un GLB passé par la revue et
   le gel a déjà été jugé, une fois, par un humain. Le rejuger au même seuil
   que du procédural produirait un rouge sur du travail validé — le mode de
   panne qui fait désarmer un portail.

Ces deux décisions ne sont pas des assouplissements : le plafond n'a pas bougé
d'un dixième. C'est la **portée** de la mesure qui a été mise en face de ce
qu'on veut garantir — « ne jamais mesurer une propriété qui n'est pas celle
qu'on veut garantir » (ISS-018).

## Reproduction

```bash
python3 tools/mesure_boititude.py \
  assets/architecture/flora/SM_ThunderstruckTree.glb --json
```

Le port Python de l'algorithme GDScript est dans le rapport de la voie C ; le
prédicat lui-même est `_boititude()` dans
`tests/world_v2/test_world_v2_lot1_defauts.gd`, et son témoin analytique
(`un pavé rend 100 %`) est un test à part entière du même fichier.
