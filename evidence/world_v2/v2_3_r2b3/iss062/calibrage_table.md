# ISS-062 — tableau de calibrage `mesure_rectangularite.py`

Outil : `tools/mesure_rectangularite.py`. Autotest 15/15, RC 0.
Dépôt : branche `claude/world-v2-reconstruction`, HEAD `4857c088` au moment de la
mesure (`291a6219` en est ancêtre ; les deux commits intercalés ne touchent
aucun `.glb` — vérifié par `git diff --name-only 291a6219 HEAD -- assets`, sortie vide).

## Témoins acceptés — famille NATURE/DÉBRIS (celle qui calibre le seuil)

| fichier | plaques | RECT % | ortho % | **indice_boite** |
|---|---:|---:|---:|---:|
| `SM_Dungeon_RubbleLarge.glb` | 65 | 0,62 | 0,00 | **0,00** |
| `SM_Dungeon_RubbleSmall.glb` | 60 | 0,42 | 0,00 | **0,00** |
| `SM_ThunderstruckTree.glb` | 3 014 | 2,66 | 4,80 | **2,66** |

`M` = 2,66.

## Témoins acceptés — famille ARCHITECTURE (mesurés, hors calibrage)

| fichier | plaques | RECT % | ortho % | indice_boite |
|---|---:|---:|---:|---:|
| `SM_StoneBridge_Arch.glb` | 2 571 | 56,91 | 6,46 | 6,46 |
| `SM_Village_Wall.glb` | 197 | 28,22 | 4,53 | 4,53 |
| `SM_Pylon_Resonance.glb` | 1 771 | 48,84 | 15,68 | 15,68 |

Résultat non anticipé, et il renforce l'instrument : même l'architecture
acceptée reste sous 16 % d'indice, parce que sa pierre est chanfreinée et
érodée, pas cubique. Le plus haut indice des SIX témoins est 15,68.

## Références analytiques (autotest)

| montage | RECT % | ortho % | indice |
|---|---:|---:|---:|
| assemblage de 18 pavés, soudés par un coin | 100,00 | 100,00 | **100,00** |
| 18 pavés **tournés**, tailles différentes, soudés par un coin | 100,00 | 100,00 | **100,00** |
| 18 pavés en rangée entièrement fusionnée | 100,00 | 100,00 | **100,00** |
| cylindre 24 côtés | 66,86 | 20,70 | 20,70 |
| icosphère 320 faces | 0,00 | 0,00 | 0,00 |
| tétraèdre régulier | 0,00 | 0,00 | 0,00 |

## Seuil

Règle figée AVANT mesure (`regle_seuil.md`) :
`plafond = floor((M + 100) / 2)` avec `M` = max de la famille NATURE/DÉBRIS,
et `plafond >= M + 10`.

`M = 2,66` → **plafond = floor(51,33) = 51**. Marge : 51 >= 12,66, satisfaite.

Écart de séparation obtenu : 15,68 (pire témoin, toutes familles) contre 100,00
(assemblage de boîtes). Le plafond de 51 est à 35 points au-dessus du pire
témoin et à 49 points sous la référence boîte.

## Sujet

`SM_Farm_Debris_A` + `SM_Farm_Debris_B` de `SM_Farm_Ruins.glb`.

| état | plaques | RECT % | ortho % | indice_boite | verdict / RC |
|---|---:|---:|---:|---:|---|
| **AVANT** (`c44f430b`) | 168 | 71,42 | 71,73 | **71,42** | ÉCHEC, RC 1 |
| **APRÈS** (arbre de travail) | 353 | 0,32 | 14,97 | **0,32** | PASS, RC 0 |

L'état d'avant dépasse de 20 points un plafond fixé sans l'avoir vu.
L'état d'après est sous le pire témoin naturel (2,66) sur la part rectangulaire.
