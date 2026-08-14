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

---

## R2a-4.1 — recalibrage du pylône sur verdict du lead

Le lead a jugé R2a-4 « progrès majeur, mais pas encore golden master » : le
pylône est bien une structure cohérente et non un amas de primitives, mais
les trois faiblesses ci-dessus restent bloquantes, et **un défaut de preuve
s'y ajoutait** — `manifest_composition.json` portait `commit: 6ddac267` et
`repo_dirty: true`. Les images avaient donc été produites avant le commit
du code final, depuis un arbre modifié : elles ne prouvaient rien.

Cette passe traite les quatre points demandés, plus deux défauts trouvés en
les traitant. **Toutes les images ci-dessous viennent d'un arbre committé
propre** : `commit 4165801`, `repo_dirty: false`, portés par
`manifest_r2a41_vues.json` et `manifest_silhouettes_pylone.json`.

### 1. Pieds et ancrage

Section passée de quatre coins à un **octogone chanfreiné** ; sabot noyé
dans la plinthe à z = 0,85, sous son dessus à 1,70 ; chapiteau évasé sous
le collier. Le montant se raccorde à ses deux bouts au lieu de s'y arrêter.

Demi-largeur ramenée de 1,80 à **1,32 m après mesure sur silhouette
isolée** : à 1,80 les trois pieds se rejoignaient en une jupe trapézoïdale
percée de deux fentes. Trois volumes séparés dans le maillage ne font pas
trois pieds séparés à l'œil — c'est la projection qui décide, et seule une
silhouette le montre.

### 2. Canaux — et le fond qui n'était pas là

Deux **nervures** encadrent chaque canal. Le tube lumineux continu est
supprimé : neuf inserts séparés par canal, coupures calées sur les deux
bandeaux qui traversent le canal, longueurs décroissantes vers le haut.
Émission ramenée de 1,4 à 0,85.

Puis le balayage horizontal a montré que ça ne suffisait pas. Le noyau
sombre était posé **6 cm derrière** le fond du canal ; or le profil du fût
porte son propre fond, donc c'était lui qu'on voyait, dans le même bronze
que les joues. Le noyau ne rendait **nulle part**.

| position (bande sans insert cyan) | avant | après |
|---|---:|---:|
| flanc du fût | 0,203 | 0,203 |
| nervure gauche | 0,262 | 0,260 |
| **fond du canal** | **0,203** | **0,133** |
| nervure droite | 0,254 | 0,258 |
| flanc du fût | 0,203 | 0,208 |

Le creux avait exactement la valeur de la surface qui l'entoure : seule la
veine cyan le signalait. Il a maintenant, **cyan coupé**, un rapport de 1 à
2 avec ses joues. La géométrie porte le canal ; la lumière ne fait que
l'habiter.

### 3. Anneau — le défaut était un pivot, pas un dessin

Le basculement passait par `obj.rotation_euler`, qui tourne autour de
l'origine de l'**objet**, au sol. Appliqué à un anneau situé à z = 22,30, un
basculement de 9° déplaçait son centre de 22,30 × sin 9° = **3,49 m**.
Rayon intérieur 4,04 contre décentrement 3,49 : la bande passait
littéralement à travers le fût d'un côté et pendait dans le vide de
l'autre — « une portion semble flotter ou seulement traverser le fût ».

Le basculement est désormais appliqué autour du **centre de l'anneau**,
dans les coordonnées des sommets ; les deux consoles empruntent le même
repère et ne peuvent plus se décoller. Le générateur **refuse d'enregistrer**
si l'étalement des distances à l'axe dépasse 1,10 m : 0,85 pour un anneau
centré, plus de 7 pour celui d'hier. Mesuré à la génération :
`distance à l'axe 3,83–4,68 m (étalement 0,85), fût 1,81 m au plus près`.

L'ouverture est élargie à 84° et surtout **présentée de profil**. Pointée
vers l'objectif — ce qu'elle était au premier jet de cette passe — elle
donne deux cornes et aucun anneau : à 96 m on lisait une barre. À 90° de
l'axe de vue, l'anneau se lit ET sa morsure aussi.

### 4. Couronne et matières

Dents et coiffes en sections octogonales, effilement porté à 3,3× ; la
coiffe est un volume unique qui se termine en pointe, non trois carrés
empilés. La fourche reçoit un **décalage Y opposé** : deux dents décalées
sur le seul axe X s'alignaient exactement vue selon X, et à 0° la couronne
bifide se lisait comme une simple flèche — un repère majeur ne peut pas
perdre sa signature sur un demi-tour.

Les matières sont **calibrées sur la capture, pas sur l'intention**. Mesuré
au pixel avant : cuivre éclairé 0,486, pierre ombrée 0,447, ivoire ombré
0,403. L'écart d'éclairement (×1,63) égalait l'écart de matière (×1,62), et
les trois matériaux rendaient la même valeur. Après :

| zone | valeur rendue |
|---|---:|
| anneau — bronze oxydé à l'ombre | 0,261 |
| fût — bronze oxydé | 0,398 |
| pied — pierre à l'ombre | 0,447 |
| plinthe — pierre éclairée | 0,553 |
| collier — ivoire | 0,678 |

### Deux outils, parce qu'une preuve doit être rejouable

`tools/blender/export_architecture.sh` — le pylône de R2a-4 avait été
exporté à la main, invocation par invocation : ça marchait et ça ne prouvait
rien. La chaîne source → `.blend` → `.glb` → inspection se rejoue
maintenant d'une commande, avec les deux garde-fous de `run_export.sh`
(`--python-exit-code 1`, jeton de fraîcheur).

`tools/godot/capture_silhouette.gd` — la silhouette **isolée** exigée par
le lead : sujet seul dans une scène vide, matériaux remplacés par un aplat
unshaded, fond de couleur plate, cadrage orthographique déduit de l'AABB.
L'outil **refuse d'écrire** une image qui n'est pas bimodale — c'est le
contrôle qui manquait à la « mosaïque de couleurs ». Mesuré sur les deux
vues livrées : **0,000 %** de pixels hors des deux valeurs.

### Preuves de cette passe

| fichier | contenu |
|---|---|
| `pylone/pylone_composition.png` | composition complète |
| `pylone/pylone_approche.png` | approche à hauteur de joueur (sol mesuré 8,5 m, œil +1,7) |
| `pylone/pylone_base.png` | base à hauteur de joueur, **côté éclairé** |
| `pylone/pylone_structure_canal.png` | gros plan du canal, sur son rayon exact |
| `pylone/pylone_lointain_96m.png` | vue à 95,4 m |
| `pylone/silhouette_pylone_000.png` | silhouette isolée 0° |
| `pylone/silhouette_pylone_090.png` | silhouette isolée 90° |
| `pylone/plans_r2a41.json` | les cinq caméras, avec la raison de chacune |
| `pylone/manifest_r2a41_vues.json` | `commit 4165801`, `repo_dirty: false` |
| `pylone/manifest_silhouettes_pylone.json` | idem, plus les mesures de bimodalité |
| `pylone/gltf_inspect_pylone.log` | VALIDE — 17 maillages, 34,94 m, base z = 0, 8 052 tris, 5 matériaux, 0 texture |
| `pylone/materiaux_importes.log` | les cinq albédos arrivent au centième |
| `pylone/filets_places_VERT.log` | `world_v2_places` 8/8 |

### Trois cadrages ont dû être corrigés, et c'est une leçon

- **`pylone_structure_canal`** de R2a-4 visait l'azimut 39° ; les trois
  canaux sont aux azimuts monde 330°, 210° et 90°. La caméra était donc à
  **51° du canal le plus proche** et montrait le flanc du fût. C'est
  pourquoi le lead n'a « pas vu clairement un canal » : il n'y en avait
  pas dans le cadre. La conversion Blender Z-up → glTF Y-up donne, pour un
  azimut modèle θ, la direction monde `(cos θ ; −sin θ)` ; le canal se vise
  par le calcul, pas à l'œil.
- **`pylone_approche`** et **`pylone_base`** de R2a-4 étaient à y = 20,
  soit 11,5 m au-dessus du sol pour l'une : ce n'était pas une hauteur de
  joueur. Les sols ont été sondés (`probe_site_section`) et l'œil placé à
  +1,7 m.
- **`pylone_base`** a en outre changé de côté : la direction du `Sun` de
  `WorldV2.tscn` (colonne −Z de sa base) porte vers l'azimut 19,5°, donc le
  soleil est à 199,5°. Le premier cadrage prenait la base à contre-jour et
  aucun chanfrein ne s'y lisait.

### Ce qui reste faible, et n'est pas déclaré acceptable

- le flanc éclairé du fût monte à **0,56** au bord du gros plan, en
  incidence rasante ; ce n'est pas un matériau blanc, mais c'est clair ;
- à 0°, deux des trois pieds se recouvrent — géométrie normale d'un
  tripode vu dans l'axe d'un montant, mais la base y paraît plus pleine ;
- les deux consoles de l'anneau sont désormais solidaires et visibles de
  près ; à 96 m elles restent fines ;
- **l'orientation de l'anneau est un arbitrage, pas un optimum.** Présenté
  de profil, il se lit comme un anneau depuis les caméras de composition,
  d'approche et de 96 m — mais sur la silhouette isolée à 0°, qui regarde
  perpendiculairement, il redevient une barre horizontale. Un anneau ouvert
  ne peut pas lire comme un anneau sous tous les azimuts ; le choix
  privilégie les vues de jeu, et c'est un choix, pas une propriété.

`NON VÉRIFIÉ` — soumis au jugement du lead. **Aucun verdict artistique
n'est auto-déclaré.**
