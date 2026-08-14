# V2.3-A.R2a — preuves

Sous-gate ouvert sur verdict du lead : **gate artistique de V2.3-A.R en
ÉCHEC**, `GO_V2_3_B=FALSE`, `GO_V2_3_R2B=FALSE`. Base `c946b0e`, additif.

Le lead impose un **changement de pipeline** : un script de scène ne
fabrique plus la surface artistique finale sous forme d'assemblages de
`BoxMesh`, de plaques ou de fragments visibles.

## R2a-0 — l'enquête préalable, et ses trois trouvailles

### 1. Blender était présent, installé, et INCAPABLE d'exporter

`tools/setup_blender.sh` sortait « déjà présent » en code 0 sur la foi
d'un `command -v blender`. Blender 4.0.2 était bien là. Mais son
exporteur glTF (`io_scene_gltf2`) importe **numpy**, absent du conteneur.

Et l'échec était **silencieux**. Mesuré :

| Commande | Code retour | Journal |
|---|---|---|
| `blender --background <blend> --python export_gltf.py -- --out /proc/…` | **0** | 2 lignes de traceback |
| la même, avec `--python-exit-code 1` | **1** | idem |

Conséquence : `run_export.sh` rendait 0, son étape 3 revalidait les `.glb`
**déjà versionnés**, et la chaîne annonçait « PIPELINE BLENDER→glTF :
VERT » sans avoir rien exporté.

**Corrigé** : `python3-numpy` installé (1.26.4, celui de
`/usr/lib/python3/dist-packages` — c'est celui que Blender importe, pas
celui de `/usr/local/bin/python3`) ; `--python-exit-code 1` sur les trois
invocations ; et un **jeton de fraîcheur** — tout `.glb` attendu doit être
plus récent qu'un jeton posé avant l'export, car un fichier intact n'est
pas un fichier produit.

**Prouvé par un contrôle négatif** (`controles/`) : numpy masqué →
`RC=1`, `PIPELINE BLENDER→glTF : ROUGE`, avec le diagnostic exact
« n'a PAS été réécrit ». Avant la correction, ce même cas rendait VERT.

### 2. Les pivots des modules CC0, enfin mesurés

`tools/godot/probe_kit_seating.gd` instancie chaque module **exactement**
comme `WorldV2PlaceKit.module()` — même `KitScale.factor()`, même
`KitPlacement.seat()` — et rend son emprise et la position de son origine
dedans. Résultats complets : `mesures_assise_modules.log`.

Ce qu'on ignorait et qui décide de tout assemblage :

- `KitScale.factor()` rend **1,000** pour tous les murs, toits, sols,
  escaliers et modules de grotte : ils ne sont pas dans `MEASURED`, donc
  **aucun redimensionnement silencieux**. La crainte n°1 est levée.
- **Tous les murs font 2,00 × 3,12 × 0,41 m**, pivot `centre / min / 0,77` :
  l'origine est centrée en X, à la base en Y, mais **décalée en Z** — le
  corps du mur est majoritairement du côté −Z. C'est la donnée qui décide
  si deux murs jointent ou laissent un trou.
- Les toits sont bien plus grands que leur nom : `Roof_RoundTiles_4x4`
  mesure **5,51 × 4,25 × 5,56 m** — il coiffe un bâti de 4 × 4 m avec
  débord.
- Les modules de grotte sont sur grille 4 m : `SM_Dungeon_CaveWall`
  4,00 × 4,05 × 2,16, pivot `centre / min / max`.
- **Piège** : `seat()` plaque au sol tout module dont l'origine n'est pas
  à sa base. `Window_Wide_Round1` descend de **1,016 m**,
  `WindowShutters_Wide_Round_Open` de **1,093 m**, `Prop_Support` de
  **1,211 m**. Passer une fenêtre par `K.module()` la pose donc **par
  terre**. Les murs à ouverture (`Wall_*_Window_*`) sont la bonne voie.

### 3. Ce que la bibliothèque CC0 ne couvre pas

Aucun module n'offre de fût effilé à dosserets, d'anneau incomplet, de
couronne bifide, de canal creux, de plaque de céramique isolante ni de
rail de cuivre. Le pylône est un **hero asset original** (`VISUAL_ASSET_BIBLE`
§11.2) : il ne peut pas être rhabillé en modules de château médiéval sans
mentir sur la direction artistique. Blender était donc la seule voie — et
c'est pour cela que le débloquer était le premier pas.
