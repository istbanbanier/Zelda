# ATLAS DU MONDE — Éclats d'Orage

**Établi le 2026-08-06** · Godot 4.7.1-stable recompilé (`a13da4feb`) · rendu llvmpipe (logiciel)
Cartes : `evidence/atlas/valley_map.png` et `evidence/atlas/valley_relief.png`, avec manifestes.

Ce document répond à une question qui n'avait jamais été posée : **à quoi ressemble
réellement ce monde ?** Il n'existe dans aucun éditeur — il est bâti au démarrage par
13 334 lignes de GDScript. Personne ne l'avait vu en entier avant ces deux images.

---

## 0. La découverte qui commande tout le reste

### Le terrain n'est pas un terrain

`scripts/world/valley_terrain.gd` (2 188 lignes) ne sculpte aucun sol. Il pose :

| Élément | Quantité | Nature réelle | Preuve |
|---|---:|---|---|
| Plan de base | 1 | plan plat à `y = -8` | `valley_terrain.gd:20` (`BASE_Y`) |
| « Macro-formes » (crête, terrasses, plateaux) | **20** | **boîtes rectangulaires** | `_slab()` → `_box_in()`, `valley_terrain.gd` |
| Liaisons entre niveaux | 10 | rampes droites | `_ramp()` |
| Variation de sol | n | **rectangles de couleur à plat** | `_build_ground_variation()`, ligne 1554 |

Les seuls maillages réellement sculptés du fichier sont **les brins d'herbe**
(`_tuft_mesh()`, ligne 1826) et un utilitaire d'enveloppe convexe. Le sol, lui, n'a
jamais été modelé.

**Conséquence visible sur `valley_relief.png`** (rendu à ombre rasante, ambiante 0,10,
qui révélerait le moindre relief) : la vallée est un **damier de rectangles colorés sur
un plan plat**. Aucune colline, aucun vallon, aucune pente organique. Les bords des
zones sont des angles droits.

C'est la cause dominante de « c'est encore moche », et elle est plus profonde que le
style : **on a peint un graybox de level designer au lieu de le remplacer.**
MASTER_SPEC §7.14 l'avait écrit : « aucun shader ne transforme automatiquement une
géométrie faible en direction artistique haut de gamme ».

### Les trois autres blockouts jamais remplacés

| Objet | Nom dans le code | Composition réelle | Preuve |
|---|---|---|---|
| Citadelle de l'Œil-Tempête | **`CitadelProxy`** | 21 boîtes + 1 cône + 1 anneau | `valley_terrain.gd:1166-1290` |
| Rivière | — | bande **rectiligne** (la bible §6.1 exige un S) | visible sur la carte |
| Nuage d'orage | `CitadelStorm` | galette sombre couvrant ~15 % de la carte | `storm_cell.gd` |

Le nom `CitadelProxy` est explicite : c'est un **placeholder posé au premier jour du
projet**, jamais remplacé, et repeint 23 fois.

---

## 1. Emprise et repères

| Repère | Coordonnées | Note |
|---|---|---|
| Bordure intérieure du monde | rayon 250 m | `BORDER_INNER` |
| Bordure extérieure | rayon 292 m | `BORDER_OUTER`, hauteur 70 m |
| Spawn du joueur | `(0, 0.2, -7)` | |
| Plateau du donjon | `(0, 34, -210)`, dalle 130 × 90 m | `_slab("DungeonPlateau")` |
| Citadelle | `z ≈ -212`, sommet de flèche `y = 100` | `CitadelProxy` |
| Rampe processionnelle | `(0,2,-110)` → `(0,34,-165)`, large de 16 m | `_ramp("DungeonRamp")` |

**Densité d'herbe** : 9 touffes/m² dans un rayon de 18 m, 4,5 au-delà
(`MEADOW_NEAR_RADIUS`, `MEADOW_NEAR_DENSITY`). Au-delà de ce rayon, le sol redevient un
aplat — ce qui explique l'effet « moquette verte » dès qu'on lève les yeux.

## 2. Les 32 sites de la vallée

Coordonnées extraites des constantes `SITE_*` des bâtisseurs. `X` d'ouest en est,
`Z` du sud (positif) vers la citadelle (négatif).

| Site | Position | Site | Position |
|---|---|---|---|
| Chute d'eau | `-118, 26` | Cascades | `150, 118` |
| Tour de guet | `-128, 82` | Observatoire | `76, 128` |
| Village de la rivière | *(voir `riverside_village.gd`)* | Hameau forestier | `110, 40` |
| Poste minier | `-68, 86` | Mine | `160, -70` |
| Aqueduc | `-12, 10` | Pont de pierre | `-14, 10` |
| Pont magnétique | `-34, 44` | Bassin conducteur | `16, 28` |
| Ferme abandonnée | `-16, 78` | Source | `-72, 78` |
| Sanctuaire forestier | `34, 94` | Bosquet | `-8, -152` |
| Champ de fleurs | `-34, 112` | Arbre foudroyé | `-92, 148` |
| Arbre ancien | `-96, -62` | Cercle de pierres | `-132, -28` |
| Cimetière tumulaire | `58, -78` | Crypte | `-60, -90` |
| Vieux rempart | `-104, -138` | Bastion | `-140, -60` |
| Caravane de l'orage | `-38, -120` | Gorge | `68, -96` |
| Cristal | `-140, -150` | Repaire | `150, -140` |
| Territoire braise | `72, 112` | Territoire azur | `78, -78` |
| Chasseur | `128, 150` | Belvédère | `168, 40` |
| Passage | `-134, 122` | | |

**Constat de répartition** : les sites occupent une couronne entre 60 et 170 m du
centre. Le centre de la carte et les angles sont **vides** — la carte du ciel le montre
crûment : de vastes plaques vertes sans rien.

## 3. Verdict par zone

| Zone | Ce que le joueur voit | État |
|---|---|---|
| Vallée (sol) | plan plat + rectangles de couleur | **BLOCKOUT** |
| Citadelle | 21 boîtes empilées | **BLOCKOUT** (`CitadelProxy`) |
| Nuage / éclair | galette sombre surdimensionnée | **BLOCKOUT** |
| Rivière | bande droite cyan | **BLOCKOUT** |
| Falaises de bordure | modules Kenney en anneau | **KIT_CC0** — correct |
| Végétation proche | touffes sculptées + arbres Quaternius | **PROCEDURAL / KIT** — le meilleur du jeu |
| Rochers | Quaternius texturés | **KIT_CC0** — correct |
| Camp / hameaux / village | props CC0 posés | **KIT_CC0** — correct mais composition mécanique |
| Vestibule de la citadelle | modules de brique, colonnes, bannières, lanternes | **KIT_CC0 — le seul intérieur réussi** |
| Donjon, 6 salles | boîtes brunes, **zéro modèle 3D** | **BLOCKOUT** |
| Arène du boss | disque nu, marques au sol | **BLOCKOUT** |
| Héros | Quaternius riggé + 5 signes | **PRODUCTION** — bon |
| 3 pillards | corps Quaternius habillés | **PRODUCTION** — bons |
| Colosse, Chasseur, Gardien | assemblages de primitives **sans texture** | **BLOCKOUT** |

## 4. Le gisement inexploité

`assets/` contient **231 modèles CC0** importés, attribués, prêts à l'emploi. Le code
n'en référence explicitement que **37**.

| Dossier | Modèles | Utilisés par |
|---|---:|---|
| `environment/village` | 53 | vallée |
| `environment/props` | 50 | vallée |
| **`environment/dungeon`** | **42** | **la vallée — jamais le donjon** |
| `environment/foliage` | 34 | vallée |
| `environment/rocks` | 15 | vallée |
| `environment/cliffs` | 8 | bordure |
| `environment/riverside` | 8 | rive |

**Le fait le plus actionnable de tout cet audit** : les 42 modules de donjon (murs de
brique, sols, encadrements de porte, coins, poutres, vignes, grilles, balcons) servent
à décorer la vallée. Les six salles du donjon n'en chargent **aucun** —
`grep "res://assets" scripts/dungeon/*.gd` ne renvoie qu'un coffre et une ressource
d'arme.

Or le vestibule, lui, les utilise :

```gdscript
# scripts/world/citadel_vestibule.gd:196-199
var packed: PackedScene = AssetRegistry.resolve(&"arch.column.module") \
    if index % 2 == 0 else AssetRegistry.model(&"Corner_Exterior_Brick")
```

C'est exactement pourquoi le vestibule est « le plus bel intérieur du jeu » et pourquoi
les six salles sont des boîtes. **La recette est déjà écrite, dans ce dépôt, et elle
n'a jamais été appliquée au donjon.**

---

## 5. Plan de reprise, par gain d'image et par effort

| # | Chantier | Méthode | Coût | Gain |
|---:|---|---|---|---|
| 1 | **Habiller les 6 salles du donjon** | appliquer la recette du vestibule : `AssetRegistry.model()` pour murs, sols, portes, coins ; puis l'éclairage motivé (AD-008 : l'éclairage AVANT la peinture) | PETIT | **DÉCISIF** |
| 2 | **Sculpter le terrain** | remplacer `_slab()` par un vrai maillage de hauteur (`SurfaceTool` + bruit + masques de zones), garder les collisions existantes | GROS | **DÉCISIF** |
| 3 | **Remplacer `CitadelProxy`** | `tools/blender/make_citadel.py` sur le patron de `make_storm_guardian.py` — silhouette validée en aplat noir avant tout matériau | MOYEN | **DÉCISIF** |
| 4 | **Arène du boss** | sol à trois matières, bord architectural, pylônes lisibles, gradins (kit KayKit déjà présent) | MOYEN | FORT |
| 5 | **Texturer colosse, chasseur, Gardien** | matériaux + couleurs de faction, a minima ; sculpture procédurale ensuite | PETIT→MOYEN | FORT |
| 6 | **Courber la rivière** | remplacer la bande droite par une courbe en S (§6.1) | PETIT | FORT |
| 7 | **Nuage d'orage multi-couches** | §9.2 : base sombre, masse dense, bords chauds, 2 nappes — et le réduire | MOYEN | FORT |
| 8 | **Casser les rectangles de sol** | bords irréguliers pour `_build_ground_variation()` | PETIT | MOYEN |
| 9 | **Densité d'herbe au-delà de 18 m** | étendre `MEADOW_NEAR_RADIUS` par cellules, pas globalement (budget) | PETIT | MOYEN |
| 10 | **Peupler le centre et les angles vides** | 150 OBJ Quaternius déjà déposés | MOYEN | MOYEN |

**À ne pas casser** : le héros et les trois pillards, les rochers et la végétation
proche, les falaises de bordure, le vestibule, les marques de sol lisibles de l'arène,
la direction chaud/froid de la lumière, et l'intégralité du gameplay (≈ 730 tests).

---

## 6. Comment reproduire ces cartes

```bash
xvfb-run -a --server-args="-screen 0 2048x2048x24" \
  godot --path . --rendering-driver opengl3 \
  --script tools/godot/capture_world_map.gd -- \
  --out=evidence/atlas/valley_map.png --size=2048x2048 \
  --span=520 --height=600 --frames=45
# variante relief : --ambient=0.10
```

L'outil désactive le brouillard et l'interface pour la durée du rendu, compte la
géométrie visible (échec sous 50 instances) et écrit un manifeste JSON à côté du PNG.
