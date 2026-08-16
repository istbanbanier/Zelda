# R2a-3.5.3 — le socle de mesure, et la quatrième confirmation de reproductibilité

**Ce dossier ne contient aucune géométrie livrable.** Il documente l'échafaudage
sur lequel les trois agents de la passe R2a-3.5.3 mesurent, et une vérification
que personne n'avait encore faite.

## Le socle

Worktree `/home/user/zelda-r2a353/socle`, détaché sur le tronc `bd78b18`, plus
quatre applications locales — **jamais poussées**, c'est un échafaudage :

| # | contenu | provenance | mesure |
|---|---|---|---:|
| 0 | base R2a-3.5.2 | `c79341e`, 9 fichiers | `2687 insertions(+), 221 deletions(-)` |
| 1 | instruments durcis et calibrés | `51a7dab` | 54 fichiers |
| 2 | collerette, **source + `.blend`, sans le `.glb`** | `e0e7567` | 13 fichiers |
| 3 | GLB candidat `cc3596c5` | `e0e7567` | échafaudage de mesure |

Le chiffre du commit 0 — `9 files changed, 2687 insertions(+), 221 deletions(-)`
— est **identique** à celui de la répétition du checkpoint 3 de la passe
précédente. Recoupement gratuit, non recherché.

## Ce que ce socle établit et que la répétition précédente n'établissait PAS

La répétition du checkpoint 3 prouvait que **tronc + base + collerette**
reproduit `cc3596c5`. Elle ne disait rien de ce que la chaîne produirait **avec
les instruments appliqués**, et les instruments touchent `probe_cave_openings.py`
et `plot_cave_section.py`.

```
avant chaine : cc3596c5d68cbfd8060987604aad6d5356772df18086f3f76f5aa8dbf8a73f49
CHAINE_RC=0            === VALIDE ===        20 970 triangles
apres chaine : cc3596c5d68cbfd8060987604aad6d5356772df18086f3f76f5aa8dbf8a73f49
```

**Byte-identique.** Quatrième confirmation indépendante, la première avec les
instruments en place. Journal complet : `chaine_depuis_le_socle.log`.

L'argument statique allait dans ce sens — le générateur n'importe que la
bibliothèque standard et `bpy`, et la chaîne n'appelle que `export_gltf.py` et
`gltf_inspect.py`, qu'aucun lot ne touche. **Mais c'est exactement le genre
d'argument qui a coûté une passe ici.** Mesurer coûtait trois minutes.

### Contrôle de périmètre, après la chaîne

```
git status --porcelain assets/ source_assets/
 M source_assets/blender/environment/SM_WaterfallCave.blend
```

**Une seule ligne, et c'est le `.blend`** — sortie non déterministe de la chaîne,
restaurée aussitôt. Le `.glb` n'apparaît même pas : il est byte-identique. Aucun
asset gelé touché, ce qui est le contrôle qui compte, la chaîne sans argument
régénérant trois golden masters validés.

## Contrôles sur les DELTAS, pas sur l'égalité finale

Un `git diff` vide ne prouverait que l'égalité finale, pas l'absence de contenu
tiers. Les contrôles portent donc sur des **patches comparés** :

| contrôle | résultat |
|---|---|
| générateur `bd78b18..socle` == `202d849..e0e7567` | **IDENTIQUE** — ni plus ni moins |
| `probe_cave_openings.py` `bd78b18..socle` == `202d849..51a7dab` | **IDENTIQUE** |
| 5 fichiers de base que personne ne touche, blob à blob vs `c79341e` | **5 / 5 OK** |
| aucun fichier de domaine gelé dans le diff | **vert** |
| **14 seuils nommés, un par un** | **0 modifié** |

Valeurs relues dans le socle, pour mémoire : `EPAISSEUR_MIN_M` 0,80 ·
`EPAISSEUR_MIN_COLLERETTE_M` 0,60 · `PLAGE_PLANE_MAX_M2` 12,00 ·
`PLAGE_PLANE_FACADE_MAX_M2` 6,00 · `LARGEUR_RATIO_MIN` 2,00 ·
`LARGEUR_ECART_MIN` 1,20 · `COLS_RATIO_MIN` 1,25 · `COLS_ECART_MIN_M` 0,40 ·
`DECENTREMENT_MIN` 0,08 · `ENTAILLE_LECTURE_M` 0,90 · `BANDE_FAITE_M` 0,45 ·
`SEMELLE_PART_LAT` 1,05 · `GABARIT_DEMI_LARGEUR_M` 0,95 · `GABARIT_CLE_M` 2,05.

### Un contrôle mal fait, et pourquoi il est consigné plutôt qu'effacé

Le premier contrôle de seuils cherchait `^[-+][A-Z_]+ *=` sur le diff. Il a
rougi — sur `CAVITE_APEX`, `MASSIF_APEX`, `PALIER` et les tables d'enveloppe,
c'est-à-dire sur la géométrie de la base, qui a **légitimement** changé.

Le motif venait du §16.1 du handoff, où il était juste : il y portait sur
`c79341e..e0e7567`, le seul delta collerette. Appliqué à une plage qui inclut la
base, il ne distingue plus un seuil d'une table de coordonnées.

**Un contrôle qui rougit sur du travail légitime est un contrôle qu'on apprend à
ignorer**, et c'est la façon ordinaire dont un portail meurt. Remplacé par une
lecture des quatorze seuils **nommés**, qui ne peut pas confondre les deux.

## Fusion, plutôt qu'écrasement — `tools/CLAUDE.md`

Le lot instruments et le tronc ont **tous deux** ajouté un piège en fin de
`tools/CLAUDE.md`. Prendre le blob du lot aurait **révoqué** le piège de parité
versé au tronc depuis. Le delta a donc été appliqué en trois points, le conflit
résolu en gardant les deux, et la présence des deux vérifiée :

```
"sans argument régénère QUATRE assets gelés"        -> present
"Quand un rayon cesse de rencontrer des faces"      -> present
```

De même, `tools/blender/probe_cave_edt_plan_bouche.py` existe dans les deux
lots : la version du lot instruments est retenue (12,8 K contre 5,3 K), étant le
portage calibré de celle du lot collerette.

## Ce que ce dossier NE dit pas

Il prouve la **mécanique**, pas le **droit** d'intégrer. Le défaut de toit mince
à 0,038 m est toujours présent dans `cc3596c5` et dans `BASE352` — c'est
précisément ce que la passe R2a-3.5.3 doit corriger. Le tronc construit et livre
toujours **R2a-3.4**.
