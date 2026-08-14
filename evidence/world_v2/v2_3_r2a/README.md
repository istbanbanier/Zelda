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

---

## R2a-4 — pylône : le premier golden master, et la preuve du pipeline

Le pylône passe en premier parce qu'il n'avait **aucune** issue en modules
CC0 : c'est un hero asset original. Le construire prouvait donc la chaîne
entière — source reproductible → GLB → inspection hors moteur → import →
capture en monde réel.

### Ce que le script de scène fait désormais, et ce qu'il ne fait plus

`scripts/world_v2/poi/resonance_pylon_landmark.gd` est passé de **238
maillages fabriqués en GDScript** à **zéro**. Il instancie un GLB,
l'implante sur l'ancre décalée, pose deux cylindres de collision et le
parvis. Les seules primitives restantes sont les deux corps de collision —
invisibles, exactement la place que le lead leur assigne.

### La source

`source_assets/blender/architecture/make_pylon_resonance.py` — génération
reproductible, versionnée, plus le `.blend` qu'elle enregistre.

**Aucun booléen.** Toutes les pièces sont des volumes **loftés** : on
empile des profils fermés et on les coud. Un booléen sur une pile de
primitives reproduit exactement les artefacts rejetés (faces ouvertes,
arêtes en escalier, pièces désolidarisées) ; un loft donne par
construction un volume continu et fermé.

**Les trois canaux sont dans le PROFIL du fût**, pas creusés après coup :
le rayon chute de 0,62 m sur trois secteurs de 26°. Le canal a donc de
vraies joues verticales et un vrai fond — et un noyau plus sombre au fond,
sans quoi le creux se comble visuellement.

Mesuré à la génération : **17 objets, 2 386 faces, 34,56 m, base à z = 0**.
Le générateur refuse de s'enregistrer si la hauteur sort de [26 ; 40] m,
si la base n'est pas à zéro, ou s'il y a moins de 8 objets — les trois
contraintes du filet `test_le_pylone_est_un_repere_majeur`.

### Deux défauts d'outillage trouvés en chemin

**1. `gltf_inspect.py` ne mesurait qu'UN maillage.** L'appel était câblé
sur `accessor_bounds(gltf, 0)`. Sur le pylône, il annonçait
`dimensions_m [10.6, 1.7, 10.6]` — les cotes de la plinthe — pour un
ouvrage de 34,56 m. Et son contrôle « min Y ≈ 0 » ne regardait que cette
plinthe : une pièce flottant vingt mètres plus haut n'aurait rien
déclenché. Corrigé : accumulation sur tous les maillages. Après
correction, `dimensions_m [10.6, 34.56, 10.6]`.

**2. Le pylône rendait ENTIÈREMENT BLANC** — ce que le lead interdit.
Ce n'était ni un goût ni un matériau manquant, et l'œil ne pouvait pas
trancher entre « blanc » et « beige très clair ».
`tools/godot/probe_asset_materials.gd` (créé pour ça) a mesuré les
albédos réellement portés par l'asset importé :

| écrit dans la source | reçu dans Godot |
|---|---|
| pierre 0,40 | **0,67** |
| ivoire 0,62 | **0,81** |
| cuivre 0,30 | **0,58** |
| fond de canal 0,14 | **0,41** |

C'est la conversion **sRGB ↔ linéaire** : glTF stocke `baseColorFactor` en
linéaire, Godot le réencode en sRGB pour `albedo_color`. Tout remontait
dans une bande 0,41–0,81 — contraste écrasé, fond de canal plus sombre du
tout, masse uniformément pâle. La source convertit désormais
explicitement ; vérifié après correction : les albédos arrivent au
centième près (`materiaux_importes.log`).

### Preuves

`pylone/` — composition, approche, vue lointaine à 96 m, gros plan
structurel montrant un canal **de la base au sommet** avec sa veine au
fond, et la vue de base. Plus l'inspection glTF, les albédos importés et
les filets `world_v2_places` **8/8 verts**.

### Ce qui reste faible sur ce sujet

- la veine cyan lit comme un tube lumineux continu dans le gros plan ;
  elle est bien CONTENUE dans le canal, mais son intensité mériterait
  d'être rompue ;
- les trois pieds sont des volumes propres, mais leur section reste
  rectangulaire — un chanfrein les rendrait plus taillés ;
- l'anneau incomplet se lit à 96 m ; sa liaison au fût par deux consoles
  reste discrète.

Aucun de ces trois points n'est déclaré acceptable : ils sont `NON VÉRIFIÉ`
et soumis au jugement du lead.
