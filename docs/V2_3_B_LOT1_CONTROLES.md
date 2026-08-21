# V2.3-B lot 1 — LES CONTRÔLES, écrits AVANT toute mesure

**VIVANT.** Autorité sur *comment le lot 1 se prouve*. Écrit par la voie C
pendant que les voies A et B construisent, et committé **avant** que le premier
chiffre ne soit relevé — c'est la seule façon qu'une règle de seuil ne soit pas
choisie après avoir vu le résultat qu'elle doit juger.

Ce document ne construit rien. Il répond à une question et une seule :
**le jour où l'un des huit défauts du §4 du contrat revient, l'apprend-on en
secondes, ou par la bouche du propriétaire trois semaines plus tard ?**

## 0. La règle qui gouverne tout ce fichier

> Un test vert n'est pas une preuve. Un test qui **rougirait** si le défaut
> revenait en est une.

ISS-018 est le témoin : les créatures s'affichaient en pièces détachées avec
TOUS les tests verts, parce qu'ils mesuraient la boîte englobante d'un maillage
skinné — donc la pose de liaison, pas ce que le moteur dessine. Conséquence
pratique retenue ici : **ne jamais mesurer une propriété qui n'est pas celle
qu'on veut garantir**, et lire la **scène montée** plutôt que le code qui
prétend la produire.

Deux corollaires appliqués partout dans ce fichier :

1. **Aucun contrôle ne peut passer à vide.** Chaque test porte un
   *recensement* : si les six lieux ne sont pas montés, il rougit en nommant
   les absents au lieu de verdir sur zéro sujet. C'est la facture déjà retenue
   par `test_world_v2_places_contract.gd` (`REGISTRY.size() >= PILOT_PLACES.size()`).
2. **Aucun seuil n'est lu depuis ce qu'il surveille.** Les valeurs attendues
   sont recopiées en littéral depuis le contrat ; un test qui lirait
   `DiscoveryRewards.PLAN` pour savoir ce que `PLAN` doit contenir suivrait
   l'erreur au lieu de la dénoncer (`tests/CLAUDE.md`, « l'auto-comparaison »).

## 1. Les seuils EMPLOYÉS, et d'où ils viennent

Vérifiés dans le code, pas dans la prose. Le §4 de `WORLD_V2_POI_CONTRACTS.md`
annonce « routes 2,3 m, gués 12 m, checkpoints 4,5 m, caméras 6 m » : **ce sont
les exclusions de la VÉGÉTATION** (`world_v2_vegetation_builder.gd`), pas celles
d'un lieu. Les reprendre donnerait une marge deux à quatre fois trop large.

| constante | valeur | source vérifiée |
|---|---:|---|
| `ROUTE_CLEAR_M` | 1,2 m | `tests/world_v2/test_world_v2_places_contract.gd` |
| `SITE_XZ_TOLERANCE_M` | 0,5 m | idem |
| `ROOT_GROUND_TOLERANCE_M` | 1,0 m | idem |
| `SUPPORT_TOLERANCE_M` | 0,65 m | idem |
| bande creusée, cours principal | 9,5 m | `RIVER_BED_HALF_W 3,0 + RIVER_BANK_W 6,5` (`world_v2_heightmap.gd`) |
| bande creusée, affluent | 6,3 m | `TRIB_BED_HALF_W 1,8 + TRIB_BANK_W 4,5` (idem) |
| dégagement du lac | 2,0 m | `lake_radius()` + 2 |
| `CLEAR_SIGHT_FRACTION` | 0,6, masque 1 | `tests/world_v2/test_world_v2_cameras.gd` |
| plafond de boîtitude `hexa` | 25,0 % | `HEXA_PLAFOND_PCT`, acquis R2B.3 (ISS-060) |

Budgets par lieu (`WORLD_V2_POI_CONTRACTS.md` §4), et l'affectation du lot 1 :

| lieu | famille | modules | nœuds visuels | collisions |
|---|---|---:|---:|---:|
| `watchtower_ruin.01` | ruine | ≤ 40 | ≤ 80 | ≤ 20 |
| `forest_shrine.01` | vestige | ≤ 40 | ≤ 80 | ≤ 20 |
| `barrow_cemetery.01` | vestige | ≤ 40 | ≤ 80 | ≤ 20 |
| `overlook_summit.01` | micro-POI naturel | ≤ 12 | ≤ 30 | ≤ 6 |
| `turquoise_spring.01` | micro-POI naturel | ≤ 12 | ≤ 30 | ≤ 6 |
| `flower_field.01` | micro-POI naturel | ≤ 12 | ≤ 30 | ≤ 6 |

## 2. Ce que « compter » veut dire — définitions opérationnelles

Un budget qu'on ne sait pas compter deux fois pareil n'est pas un budget. Les
trois nombres se lisent sur la **scène montée**, jamais sur le source :

- **module** = `(nœuds descendants dont `scene_file_path` n'est pas vide)`
  + `(MeshInstance3D dont `mesh.resource_path` est vide)`. Le premier terme
  compte une pièce de kit instanciée, le second une pièce **construite en
  runtime** — R2B a rejeté « un empilement de blocs » précisément parce qu'un
  bloc procédural est un module comme un autre. La racine du lieu ne compte pas.
- **nœud visuel** = `VisualInstance3D`, **et non** `MeshInstance3D`. La
  distinction n'est pas cosmétique : un `MultiMeshInstance3D` — la forme
  attendue d'un champ de fleurs — échappe entièrement au second, et un compteur
  qui ne le voit pas déclare « 0 » sur le lieu le plus dense du lot
  (`tools/CLAUDE.md` porte déjà ce piège).
- **collision** = `CollisionShape3D`, **et non** `StaticBody3D`. C'est la forme
  qui coûte et qui obstrue ; un corps unique peut en porter trente.
  `tools/godot/probe_place_metrics.gd` compte aujourd'hui les corps : sur ce
  chiffre-là, un lieu à 1 corps / 30 formes passerait le budget « 6 ».

## 3. LA RÈGLE DE SEUIL DE RÉPÉTITION (D3) — pré-enregistrée

**Écrite avant la première mesure. Aucun nombre de ce paragraphe n'a été choisi
en regardant un résultat.**

### 3.1 Ce qu'on compare, et pourquoi ça et pas autre chose

Deux silhouettes en aplat noir produites par `tools/godot/capture_silhouette.gd`
(projection **orthogonale**, cadrage dérivé de l'AABB, deux valeurs de pixel
seulement, bimodalité vérifiée par l'outil avant écriture). Le cadrage AABB
**normalise l'échelle** : la comparaison porte donc sur la FORME, ce qui est la
question posée — « ces deux lieux se ressemblent-ils ? » — et non sur la taille,
qui n'a jamais été le défaut reproché.

### 3.2 Les trois distances

Une silhouette n'est pas confondue de la même façon de près et de loin. On ne
déplace pas la caméra (la projection est orthogonale) : on **retire de la
résolution**, ce qui est exactement ce que fait la distance. Pour chaque
distance `d ∈ {30, 80, 160} m`, la hauteur apparente en pixels d'un sujet de
hauteur `H` vaut, avec le FOV **vertical** réel du jeu (`camera_fov = 44,0`,
`KEEP_HEIGHT`, `resources/tuning/locomotion_default.tres`) et un écran 1080p :

```
h_px(d) = 1080 * H / (2 * d * tan(44° / 2))
```

La silhouette est sous-échantillonnée à `h_px(d)` (moyenne d'aire), puis
ré-échantillonnée sur une toile commune de 96×96 pour la comparaison. Le
sous-échantillonnage est la perte ; la toile commune ne fait que rendre deux
sujets comparables.

### 3.3 Les deux mesures, publiées ensemble

Une seule mesure se contourne ; deux qui se contredisent se voient.

- `IoU` — intersection sur union des masques binaires.
- `dprofil` — distance L1 normalisée entre les **profils supérieurs** (pour
  chaque colonne, le premier pixel de sujet en partant du haut), la statistique
  dont `tools/measure_silhouette_masses.py` a déjà montré qu'elle porte la
  lecture d'une formation.

`IoU` est le **liant** ; `dprofil` est publié à côté et sert au diagnostic.

### 3.4 LE SEUIL, et la règle qui le fixe

> **RÈGLE R-D3.** Le seuil `S(d)` à la distance `d` est le **maximum d'`IoU`
> observé entre deux sujets DISTINCTS du corpus ACCEPTÉ**, à cette distance,
> tous angles confondus. Le corpus accepté est l'ensemble des lieux déjà validés
> par le lead au moment de la calibration — les sept POI du lot pilote, plus le
> camp et le pylône. Une paire du lot 1 (nouveau × nouveau **ou**
> nouveau × pilote) est **signalée D3** si son `IoU` dépasse `S(d)`.

Ce que cette règle dit en français : *« deux lieux du lot 1 n'ont pas le droit
de se ressembler davantage que ne se ressemblent deux lieux que le lead a déjà
jugés distincts »*. Le seuil est donc mesuré sur des sujets acceptés **avant que
le premier lieu du lot 1 n'existe** ; il ne peut pas être ajusté par ce qu'il
juge.

> **GARDE-FOU R-D3b, pré-enregistré lui aussi.** Si la calibration rend
> `S(d) ≥ 0,90` pour une distance, la calibration est déclarée **INVALIDE** et
> le contrôle rend `BLOQUÉ`, jamais vert. Justification, écrite avant mesure :
> à `IoU ≥ 0,90` deux masques se recouvrent sur neuf dixièmes de leur aire ;
> deux bâtis réellement différents ne peuvent pas y parvenir. Si le corpus
> accepté y parvenait, c'est l'instrument ou le cadrage qui est cassé — pas
> l'art — et un seuil dérivé d'un instrument cassé absoudrait tout.

> **GARDE-FOU R-D3c.** Le détecteur rend `BLOQUÉ` si le corpus accepté compte
> moins de 6 sujets : sous ce compte, `max` sur trop peu de paires n'est plus
> une statistique, c'est un accident.

### 3.5 Le témoin qui prouve que le détecteur sait rougir

Le détecteur reçoit un **couple dégénéré** fabriqué exprès : la silhouette d'un
pilote comparée à **elle-même**, qui doit rendre `IoU = 1,000` et être signalée.
S'il ne signale pas ce couple-là, il ne signale rien, et son verdict est jeté.

## 4. Les huit contrôles, et le sabotage qui prouve chacun

Un contrôle par famille de défaut. Pour chacun : ce qu'il mesure, **et la
réponse écrite à « si ce défaut revenait demain, cette assertion rougirait-elle
vraiment ? »** — réponse dont la preuve est le sabotage, pas l'intuition.

Tous vivent dans `tests/world_v2/test_world_v2_lot1_defauts.gd`, sauf la partie
image de D3 (`tools/lot1_repetition.py`, dont le verdict est rendu *liant* par
le test : verdict absent ou non-`PASS` ⇒ rouge).

---

### D1 — assemblage de primitives

**Mesure.** Deux liants, sur les maillages de la **scène montée** :

- `D1a` part de l'aire visible portée par des maillages **runtime**
  (`mesh.resource_path` vide) — le critère binaire déjà retenu et *mesuré* par
  `test_world_v2_r2b_farm_tree.gd` pour distinguer un bloc procédural d'un asset
  importé. Exemptions **nommées** seulement, par méta `exemption_runtime` du
  lieu (précédent : `SolBrule`, un disque qui épouse le terrain sommet par
  sommet). Plafond **calibré sur le corpus accepté**, même discipline que R-D3 :
  le maximum observé sur les neuf lieux acceptés.
- `D1b` pour chaque maillage runtime non exempté, part des triangles
  appartenant à une composante `hexa` (12 triangles ET 8 sommets soudés à
  0,1 mm) ≤ **25,0 %** — le plafond acquis de R2B.3, recopié, jamais rediscuté.

**Pourquoi `hexa` et pas « ça ressemble à une boîte ».** `K.stone_block` produit
« des boîtes à sommets déplacés » : les coins bougent, la **topologie** ne bouge
pas. `hexa` est insensible au déplacement des coins et sensible à la topologie —
c'est précisément le défaut historique qu'il attrape.

**Rougirait-il ?** Oui, et voici pourquoi ce n'est pas une opinion : le défaut
historique — la ferme et l'arbre bâtis en `K.stone_block` — a été mesuré à
96,8 % de boîtitude sur `SM_Farm_Debris_A`. Un lieu du lot 1 rebâti de la même
main produirait la même famille de chiffre.
**Sabotage** : remplacer un module d'un lieu par `K.stone_block()`.
**Signature attendue** : `D1 …hexa … %` ou `D1 … aire runtime`.

---

### D2 — bâti flottant ou enterré

**Mesure.** Trois choses, dont deux que le filet existant ne regarde pas :

- chaque appui **déclaré** (`declare_support`) à moins de **0,65 m** de
  `height_at` — repris du filet existant ;
- l'emprise du lieu lue sur `VisualInstance3D.get_aabb()`, **pas** sur
  `MeshInstance3D.mesh.get_aabb()` : un `MultiMeshInstance3D` échappe au second,
  et le champ de fleurs est exactement ce cas. Le filet existant mesurerait
  « aucun maillage visuel » sur le lieu le plus peuplé du lot ;
- **couverture des appuis** : pour tout axe où l'emprise dépasse 6 m, au moins
  un appui déclaré dans le **tiers bas** et un dans le **tiers haut** de cet
  axe. Aucun seuil à débattre — c'est une partition. Ce critère attrape le cas
  que le filet existant laisse passer : *un seul appui au centre, et tout le
  reste qui flotte*.

**Rougirait-il ?** Oui : décaler un lieu de +2 m en Y fait sortir tous ses appuis
de la tolérance ; ne déclarer qu'un appui central fait tomber la couverture.
**Sabotage** : ajouter `+2.0` au Y de la racine d'un lieu, puis, second passage,
supprimer tous les `declare_support` sauf un.
**Signature attendue** : `D2 … appui … du sol` / `D2 … couverture des appuis`.

---

### D3 — répétition

**Mesure.** Deux étages.

- Étage structurel, dans le test : la **signature de composition** d'un lieu =
  multi-ensemble trié des `(source de maillage, échelle arrondie au décimètre)`.
  Deux lieux du lot ne peuvent pas porter la **même** signature. Sans seuil :
  identique est identique. Attrape la forme la plus grossière du défaut — le
  copier-coller d'un lieu sur l'autre.
- Étage image : `tools/lot1_repetition.py` et la **règle R-D3** ci-dessus. Son
  verdict JSON est rendu liant par le test.

**Rougirait-il ?** Oui pour l'étage structurel (copie = signature identique),
et l'étage image est éprouvé par son propre témoin dégénéré (§3.5).
**Sabotage** : faire pointer la scène d'un lieu du lot vers celle d'un autre.
**Signature attendue** : `D3 … signature de composition identique`.

---

### D4 — obstruction

**Mesure.** Sur les `CollisionShape3D` des lieux du lot, trois familles :

- routes contractuelles, dégagement **1,2 m** autour de chaque échantillon ;
- **bandes creusées de l'eau** : 9,5 m du cours principal, 6,3 m de l'affluent,
  `lake_radius + 2` du lac. Contrôle qu'aucun filet existant ne porte
  aujourd'hui pour les LIEUX ;
- les **six caméras gelées** : rayon caméra → cible libre sur les 60 premiers
  pour cent, masque 1 — et le rapport **nomme le `place_id`** fautif, pas
  seulement le nœud, pour que la cause soit dans le message.

**Rougirait-il ?** Oui : un collider posé sur une route est vu par la première
famille ; un site poussé dans le lit de la rivière par la deuxième.
**Sabotage** : déplacer un lieu de 30 m vers le cours d'eau ; puis, second
passage, élargir un collider de +12 m.
**Signature attendue** : `D4 … bande creusée` / `D4 … bloque` / `D4 … caméra`.

---

### D5 — placement codé en dur

**Mesure.** Pour chaque lieu du lot, on lit le **texte** du script et de la
scène et on y cherche les littéraux `x` et `z` de son propre `v2_site`
(`-160` et `40` pour la tour de guet, etc.). Un lieu dont la position vient du
layout n'a aucune raison de porter ces deux nombres. On vérifie aussi que
`default_place_id()` rend bien une constante et non une position.

**Pourquoi le texte et pas le comportement ?** Parce qu'un lieu **peut** être
monté au bon endroit tout en portant sa position en dur : le filet de site
(0,5 m) serait vert, et le défaut ne se verrait qu'au premier déplacement du
layout. Le contrat §4 nomme d'ailleurs ce révélateur : « recherche de littéraux
de position dans les scripts de lieu ».

> **CE CRITÈRE A ÉTÉ CORRIGÉ APRÈS MESURE, avant livraison.** Sa première
> version cherchait les deux coordonnées du site n'importe où dans le fichier.
> Rejouée sur les neuf lieux ACCEPTÉS, elle en accusait **trois** : `camp`
> (45, 65), `stone_bridge` (-10, 22), `ember_raider_camps` (96, 120) — des
> entiers ronds trop banals pour qu'une double présence signifie quoi que ce
> soit. La version retenue cherche la FORME du défaut — un `Vector3(x, *, z)`,
> une affectation `position.x =`, ou l'origine d'un `Transform3D` de scène — et
> accuse **zéro** lieu accepté tout en voyant les quatre formes du défaut.
> Journal : `evidence/world_v2/v2_3_b/lot1/controles/D5_calibration_faux_positifs_20260821.md`.

**Rougirait-il ?** Oui, par construction : le sabotage EST l'écriture du
littéral.
**Sabotage** : insérer `position = Vector3(-160.0, 26.0, 40.0)` dans un script
de lieu.
**Signature attendue** : `D5 … littéral de site`.

---

### D6 — récompense non raccordée

**Mesure.** Par lieu du lot : un `PointOfInterest` portant `poi_id == place_id`
et **enregistré dans le `DiscoveryLog`** du monde monté (`is_registered`) — le
révélateur nommé par le contrat, « absence de l'ID canonique dans le journal de
découverte » ; un `AncrageRecompense` ; un interactable enfant dans le groupe
`interactable` ; et le **contenu canonique**, recopié en littéral depuis le §1
du contrat, jamais lu depuis `DiscoveryRewards.PLAN` :

| lieu | contenu attendu, littéral |
|---|---|
| `watchtower_ruin.01` | 15 flèches |
| `overlook_summit.01` | arme `simple_bow` |
| `turquoise_spring.01` | ingrédient `heal_fruit` |
| `forest_shrine.01` | ingrédient `rare_spice` |
| `barrow_cemetery.01` | arme `heavy_axe` |
| `flower_field.01` | ingrédient `stamina_herb` |

**Rougirait-il ?** Oui : c'est la seule assertion du lot qui compare le monde
monté à des littéraux recopiés du contrat. Si `PLAN` et le contrat divergent,
c'est le contrat qui gagne — et le test le dit.
**Sabotage** : changer `{"arrows": 15}` en `{"arrows": 5}` dans `PLAN`.
**Signature attendue** : `D6 … récompense`.

---

### D7 — budget dépassé en silence

**Mesure.** Les trois compteurs du §2, lus sur la scène montée, comparés aux
budgets littéraux du §1.

**Rougirait-il ?** Oui, et c'est justement ce que « en silence » désigne : rien
d'autre dans la suite ne compte les `CollisionShape3D` d'un lieu.
**Sabotage** : ajouter dix modules à un lieu micro-POI.
**Signature attendue** : `D7 … budget`.

---

### D8 — régression sur le gel

**Mesure.** Recalcul du sha256 de **chaque** chemin de
`docs/contrats/gel_v2_3_b.sha256` et comparaison au manifeste — c'est-à-dire
une **seconde implémentation indépendante** de `tools/gel_verifier.sh` :
`sha256sum` d'un côté, `FileAccess.get_sha256()` de l'autre. Si les deux
rendent le même verdict, c'est le gel qui est vérifié, pas une ligne de code.

**Rougirait-il ?** Oui : toucher un octet d'un fichier gelé change son sha256.
**Sabotage** : ajouter un commentaire à `scripts/world_v2/world_v2_heightmap.gd`.
**Signature attendue** : `D8 … gel`.

## 5. Ce que ces contrôles NE prouvent pas

Dit ici pour que personne ne croie le contraire.

- **Aucun d'eux ne prouve qu'un lieu est beau.** Le verdict artistique
  appartient au propriétaire, sur des captures à taille réelle. `IoU` dit que
  deux silhouettes diffèrent, jamais qu'elles sont bonnes.
- **`D1a` a besoin d'une calibration** sur le corpus accepté avant d'être
  liant. Tant que la calibration n'a pas tourné, la constante vaut `-1.0` et le
  test **rougit en le disant** — un plafond non calibré ne doit pas passer pour
  un plafond franchi.
- **Rien ici ne remplace la manette.** Ce conteneur n'a ni écran, ni GPU : le
  verdict de jouabilité passe par `docs/MANUAL_VALIDATION.md`.
- **Le gel ne couvre pas les seuils** (`tools/gel_verifier.sh` le dit lui-même).
  Un seuil de ce fichier peut être abaissé sans qu'aucun sha256 ne bouge ; le
  garde-fou qui reste est la revue du diff.
