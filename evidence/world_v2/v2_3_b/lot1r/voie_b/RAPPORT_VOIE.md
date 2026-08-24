# RAPPORT — VOIE B, lot 1.R (tour de guet · sanctuaire · cimetière)

Worktree `/home/user/wt-lot1r-b`, détaché depuis `89a3009`. **Aucun push.**
Aucun fichier gelé, partagé, ni des voies A et C n'a été modifié. Les seuls
fichiers ajoutés sous `tools/` sont NEUFS (sondes et chaîne d'export locale).

Statuts : `PASS` · `PARTIAL` · `FAIL` · `BLOQUÉ` · `NON VÉRIFIÉ`.
**Aucun verdict artistique n'est prononcé ici** : ce document donne des images
et des mesures ; la revue tranche.

---

## 1. Commits, dans l'ordre

| Commit | Sujet |
|---|---|
| `e1e040a` | tour — pièces tombées en aplat painterly (reprise de l'arbre sale) |
| `8d6774c` | tour — les trois finitions signalées trois fois par l'audit |
| `93ef2ba` | tour — le pan tombé présentait son seul bord rectiligne à la caméra |
| `250522a` | **sanctuaire** — compo B « La nef avalée », vestige GLB dédié |
| `e18d075` | **cimetière** — compo A renforcée, dos à crête, gueule, dalles |
| `a96571b` | `COLOR_0`, dos sans faîtière, valeurs recalées sur capture |
| `e8ebe08` | variation en travers des faces, relief non radial, coffre refroidi |
| `adb2aaa` | amplitudes de `COLOR_0`, teinte non radiale, fosse au bout affaissé |
| `72151d2` | un **dos** et non une tente ; strates adoucies |
| `7b31316` | cimetière — la hauteur passe de la **terre** à la **pierre** |
| *(celui-ci)* | preuves de l'état livré : silhouettes et captures recapturées à `7b31316`, journaux de filets, §7 et §9 |

Cinq passes de correction ont suivi la première construction, et chacune a
été déclenchée par une **mesure sur capture**, jamais par une impression.

---

## 2. L'arbre sale du §2 de la note — terminé, pas revenu

`watchtower_ruin_place.gd` portait une modification non committée : la
constante `TEINTES_TOMBEES` remplacée par un albédo unique `ALBEDO_TOMBEE`,
avec court-circuit du branchement des cartes pour la variante `tombee`.

Elle était **cohérente et complète** (fonction, constante et unique appelant
concordaient) et son commentaire portait la mesure qui la motive : la carte
`T_UnevenBrick_BaseColor` box-projetée sur des facettes de 0,3 m échantillonne
surtout le mortier peint, et les éclats sortaient « chocolat glacé ». Je l'ai
donc **terminée et committée** (`e1e040a`), en attribuant l'idée à la session
précédente. Parse `RC=0` avant, capture après.

---

## 3. Tour de guet — les trois finitions (priorité 2 de la note) — `PASS`

Chacune était signalée trois fois. Chacune a été **identifiée par une mesure**
avant d'être corrigée.

### 3.1 Les pétales violets géants

`Plant_7`, module de kit posé par le lieu : 1,05 × 0,25 × 0,96 m au glTF,
matériau unique « Leaves » rendu violet saturé, posé à plat — quatre pétales
d'un demi-mètre à une échelle qu'aucune plante de ce monde n'a. Retiré ; une
touffe d'herbe sèche prend sa place.

### 3.2 La dalle pavée coupée au bord droit

Trois causes, dont une trouvée seulement à la deuxième capture :

* « **pavée** » : la carte de brique projetée sur le pan tombé → aplat
  painterly (§2) ;
* « **sans liaison** » : 2,7 m d'herbe rase entre le talus et la plaque. Le pan
  recule de 0,65 m, son grand axe pointe vers la brèche, et une **traînée de
  trois poignées d'éclats** — le maillage du talus lui-même, réduit à 0,34 /
  0,26 / 0,21 — le relie au tas ;
* reste vu sur `iter/tour5` : elle lisait encore « banc de pierre » parce que
  son **seul bord rectiligne** faisait face à la caméra (`pan_tombe` a une
  ligne `y = 0` droite, tout le reste est déchiré). Lacet 52° → 142°, roulis
  4° → 13°, enfoncement 0,20 → 0,34 m.

### 3.3 Le disque teal — et la cause vaut pour tout le lot

**Identifié, pas deviné.** Sonde `tools/godot/probe_ecran_lot1r.gd` (projection
refaite à la main : `unproject_position` ment sur l'axe Y en exécution
`--script`, `tools/CLAUDE.md`). Le nœud est à 11,5 m de la caméra joueur,
emprise pixel 725-892 × 364-413, **seul** à couvrir le rectangle incriminé
790-840 × 365-385.

C'était le caillou de pied `rock_largeC`, et la cause est dans son glTF : il
porte **deux matériaux, `dirt` et `grass`**, et la surface « grass » des kits
Kenney rend menthe/sarcelle sous cette lumière. Le caillou était une galette
brune posée sur une flaque verte plate.

Corrigé par **changement de famille**, pas par teinte : `Rock_Medium_2` (atlas
`Rocks`, matériau unique) à 0,30 → 0,91 × 0,57 × 0,74 m, même hauteur
apparente, donc aucun changement de franchissement.

> **La même cause a été retirée du cimetière** : `rock_largeA`, `rock_largeC`
> **et `rock_smallB`** portent tous `grass` + `dirt` — ce sont les « chapeaux
> turquoise » de la capture d'avant. Les ceintures passent en `Rock_Medium_*`.

**La composition de la vigie n'a pas été touchée** (consigne du lead).

### 3.4 L'épaisseur de la tour — capture ajoutée, géométrie intacte

Sur demande du lead : `apres_final/watchtower_gp_arase.png`, un gros plan pris **du
sol** au jambage de la brèche. C'est une vue **ajoutée pour montrer une qualité
réelle** que les deux caméras gelées ne captent pas — aucune caméra gelée n'a
été déplacée, et les vues gelées sont livrées telles quelles.

---

## 4. Sanctuaire forestier — compo B « La nef avalée »

L'anneau de moignons `SM_Dungeon_PillarStub` et l'autel `ArchBlock`
disparaissent : c'est la famille de trimsheet qui rend terracotta, et **aucun
albédo ne répare une forme de cube**. À leur place, `SM_Shrine_Vestige.glb` et
un **axe** nord→sud — seuil (deux montants franchement inégaux + marche
enfoncée), deux rangées qui **convergent** de 2,68 à 1,64 m d'entraxe, pierre
couchée qui barre, table **fendue** (une moitié a glissé de 0,21 m), et
derrière elle la seule verticale, le chevet.

Le choix de l'axe est aussi une **décision D3** : le cercle intact appartient à
`watchers_circle`, et les stèles de la voie C sont pâles et penchées en couleur
ouverte. Celles-ci sont grises-vertes, **moussues**, basses, sous couvert, et
la seule verticale est un **dossier derrière une table**, jamais un jalon.

### 4.1 Les conditions de l'arbitrage, mesurées

`tools/godot/probe_sanctuaire.gd` — **VERDICT PASS**. Les cotes ci-dessous sont
celles du rejeu à l'état livré `7b31316`
(`evidence/…/voie_b/filets/sonde_sanctuaire_7b31316.log`) :

| Condition | Mesure |
|---|---|
| chevet sous 2,4 m sur le nœud POSÉ, marge imprimée | **2,092 m au-dessus du sol gelé — marge 0,308 m** |
| pierre couchée franchissable aux vrais contrôles | **plus grande marche 0,300 m** (marche du héros 0,38 m) |
| les trois troncs déplacés appartiennent au lieu | `Pine_3_30`, `Pine_3_31`, `CommonTree_3_32`, enfants du lieu ; **159 instances V2.2 dans 14 m, en 8 groupes dont 11 arbres, INTOUCHÉES** |
| `SM_Shrine_Vestige.glb` ≤ 6 k tris, chaîne complète | **878 tris**, `FIN NOMINALE`, `gltf_inspect` VALIDE, min Y = 0 |
| couloir praticable | dégagement latéral minimal **0,65 m** (rayon de capsule 0,40) |
| D2 / D4 redéclarés | filets verts (§7) |
| invisibilité depuis la route, capture P1 (84, 7, 81) regard N | §6.3 |

**La sonde a rougi une fois, et c'est ce qui l'a rendue utile** : première
version, « plus grande marche **0,000 m** sur 32 appuis ». Sans collider, le
rayon traversait la pierre couchée — et le héros aussi. « On l'enjambe »
n'était pas une cote mais un espoir. La pierre porte donc un corps de 0,30 m,
juste sous la hauteur de marche.

### 4.2 La récompense

L'audit l'a mesurée flottante et saturée au maximum (255, 255, 113). Deux
gestes, chacun dans son périmètre :

* **l'altitude appartient au lieu** — `IngredientPickup` dessine sa tige depuis
  son origine et la baie 0,22 m plus haut ; l'ancre descend à
  `TABLE_DESSUS − 0,05`, la tige mord la dalle, l'offrande est **posée** ;
* **l'habillage est local** (autorisé par le lead) : matériaux DUPLIQUÉS, sur
  cette instance seulement, désaturation 35 % et assombrissement 14 %.
  Mesuré après : **(166, 157, 84)**, luminance 0,603. L'épice reste le seul
  point chaud voulu du lieu ; elle ne crève plus l'image.

---

## 5. Cimetière du tertre — compo A « Le chemin des morts » renforcée

### 5.1 D'où venait le « cône », et pourquoi il a fallu trois passes

1. **L'ancien générateur** faisait des dômes de **révolution** : rayon bruité
   par secteur, profil `cos^1,4`, et un **sommet unique** cousu en éventail. Ce
   sommet unique EST une pointe de cône ; aucun bruit de rayon ne l'enlève.
2. **Première réécriture** — le sommet devient une **crête**. Mesuré sur
   capture : plus de cône, mais une **arête faîtière** — « des tentes de papier
   plié ». Cause : la hauteur suivait encore l'INDICE D'ANNEAU, donc tous les
   points de l'anneau intérieur étaient à la même cote et l'anneau suivant
   fermait ce plateau par une arête.
3. **Deuxième réécriture** — la hauteur suit la **distance géométrique au
   segment de crête**, normalisée par le rayon local ; `cos^1,25` a une
   tangente horizontale en zéro, donc le dessus est rond **en travers**, comme
   un pain. Densité 40 × 5 → **48 × 9**.
4. **Troisième** — il restait des plis rayonnants : le relief de flanc était un
   multiplicateur par **secteur**, constant du dos à la lisière. Quarante-huit
   secteurs légèrement différents ne font pas des bosses, ils font
   quarante-huit **plis**. Le relief devient un **champ lisse en (u, v)**,
   trois sinus de fréquences non commensurables, sans structure angulaire.

La méthode **terrain-hugging est inchangée** (`ground_local_y` par sommet) et
les trois noms de nœuds aussi : le titre de l'exemption D1a est exactement
celui qui a été calibré, et D1 reste vert après reprofilage.

### 5.2 La gueule, les déblais, le coffre

Montants de 1,46 et 1,24 m, linteau de **1,97 m de portée** à 11° de dévers,
mordus dans le flanc **sud** du dominant — le flanc d'arrivée des deux caméras
du plan et du parcours joueur. Le générateur **refuse d'enregistrer** si un
seul sommet des déblais entre dans le quadrant d'accès : « coffre jamais
enfermé » est une garde, pas une promesse.

Le coffre : le modèle vient d'une ressource **partagée** que ce lieu ne
remplace pas. L'habillage est local, par surface, sur des matériaux
**dupliqués**, appliqué à l'arrivée de la récompense dans l'ancre (elle est
posée après tous les lieux, d'où l'abonnement à `child_entered_tree`).
L'ancre **ne bouge pas** — ce sont **trois poignées d'éclats** qui montent
autour d'elle pour lui donner son assise.

Mesuré sur les planches : **0,520 → 0,387** de luminance (steppe 0,409) — il
n'est plus l'objet le plus clair du cadre. Sa saturation n'avait pas bougé à la
première passe, pour une raison mécanique : le matériau porte une **texture**,
son `albedo_color` est donc quasi blanc, et désaturer du blanc ne fait rien.
Seul un facteur multiplicatif agit sur une carte — d'où le refroidissement
ajouté à la deuxième passe.

---

## 6. L'aplat de valeur — le défaut central du lot (ISS-066)

C'est la mesure la plus importante de ce rapport.

### 6.1 Le mécanisme

Sur des faces quasi verticales sous ce ciel, l'irradiance ambiante domine :
changer l'orientation d'une facette ne rapporte presque rien en luminance. Les
roches du kit ne se lisent pas comme de la pierre grâce à leur géométrie mais
grâce à la **variation de leur atlas**. Un maillage sans texture et sans
couleur de sommet rendra donc plat quelle que soit la qualité de sa silhouette.

`tools/gltf_inspect.py` contrôle `POSITION`, `NORMAL`, `TEXCOORD_0` et
`JOINTS_0` — **jamais `COLOR_0`**. Il aurait répondu `VALIDE` sur un asset
ayant perdu ses couleurs.

### 6.2 Ce qui a été fait

Les deux générateurs posent des couleurs de sommet : **strates quantifiées en
marches** suivant le plus grand axe de chaque pièce (horizontales sur une
pierre dressée, dans la longueur sur une lame couchée — le lit de débitage),
une **seconde fréquence** plus lente sur l'axe moyen (pour qu'une coupe *en
travers* varie aussi), des **veines** fines, et un **pied assombri**.

Deux conditions, aucune automatique, et une garde de générateur pour chacune :

1. le matériau **consomme** l'attribut (nœud Color Attribute multiplié dans
   Base Color) ;
2. la couche est l'attribut **actif ET de rendu**.

La garde refuse aussi d'enregistrer si l'étendue de `COLOR_0` tombe sous 0,12 —
des couleurs présentes mais uniformes ne valent pas mieux qu'un aplat.
Côté Godot, `vertex_color_use_as_albedo` est activé sur les matériaux
dupliqués : sans lui, le `COLOR_0` ne servirait à rien.

**Vérifié à la main** dans le JSON glTF, comme demandé :

| GLB | octets avant → après | `COLOR_0` |
|---|---|---|
| `SM_Shrine_Vestige.glb` | 75 756 → **105 396** | **présent** |
| `SM_Barrow_Stones.glb` | 65 420 → **91 588** | **présent** |

### 6.3 Les profils de luminance, avant et après

Un profil de luminance pris **en travers d'une face**, en pixels. « Étendue »
est `max − min` : zéro signifie un aplat parfait.

| Face | avant (audit, `apres/`) | après (livré, `apres_final/`) |
|---|---|---|
| linteau du dolmen | **82 constant sur 135 px — étendue 0** | **36 → 51 → 39 — étendue 15**, aucun plateau |
| stèle du cimetière | **109 constant sur 48 px — étendue 0** | **71 → 123 dans la pierre — étendue 90** |
| montants du sanctuaire | **94 constant — étendue 0** | **70 → 76 — étendue 6**, gradient continu |
| dalle tan de la tour | **141 constant — étendue 0** | **140–141 — étendue 1 à 2 : INCHANGÉ** |

Coupes exactes, coordonnées, méthode et lecture de chacune : **§9.2**. La
dernière ligne n'est pas un oubli de mesure mais un défaut qui subsiste, et il
est instruit là-bas.

Trois passes de réglage ont été nécessaires : la première pose de `COLOR_0`
donnait 9 niveaux en vertical et **1 en travers** — géométriquement normal
(les strates sont horizontales, une coupe horizontale n'en traverse qu'une)
mais sans effet pour l'œil. D'où une **seconde fréquence sur l'axe moyen** de
chaque pièce, puis une amplitude doublée, puis un mélange marches/onde
continue quand le contraste plein sortait en blocs d'ombrage au lieu de lits
de pierre.

---

## 7. Filets

Tout ce qui suit a été **exécuté à `7b31316`**, l'état livré, et les journaux
sont committés sous
`evidence/world_v2/v2_3_b/lot1r/voie_b/filets/`. Aucun résultat n'est déclaré :
chaque ligne renvoie à un fichier qui porte son jeton de fin.

### 7.1 Les deux suites

| Filet | Commande | Résultat | Journal |
|---|---|---|---|
| Les huit défauts nommés d'avance (D0–D8 + 2 témoins) | `tools/lancer_godot.sh --path . --script tools/godot/test_runner.gd -- --filter=lot1_defauts` | **11 réussi(s), 0 échoué(s)**, 38 assertions, 0 erreur de script, `RC_GODOT=0` | `filet_lot1_defauts_7b31316.log` |
| Contrat des lieux | `… -- --filter=places_contract` | **5 réussi(s), 0 échoué(s)**, 14 assertions, `RC_GODOT=0` | `filet_places_contract_7b31316.log` |

Les deux témoins du premier filet comptent autant que les huit familles : ils
vérifient que l'instrument de « boîtitude » voit un pavé et que les compteurs
comptent ce qu'ils prétendent compter. Un filet vert dont l'instrument est
aveugle est le mode de panne d'ISS-018, et il est explicitement surveillé ici.

### 7.2 Ce que les filets mesurent RÉELLEMENT sur mes trois lieux

Un `ok` ne dit pas de combien on passe. La sonde de budget donne les cotes, lues
sur la **scène montée** (`sonde_budget_7b31316.log`) ; les plafonds sont ceux du
contrat, recopiés en littéral dans le filet.

| Lieu | famille | modules | nœuds visuels | collisions | aire runtime |
|---|---|---|---|---|---|
| `watchtower_ruin` | ruine | **15** / 40 | **19** / 80 | **12** / 20 | **0,0 %** |
| `forest_shrine` | vestige | **33** / 40 | **35** / 80 | **13** / 20 | **0,0 %** |
| `barrow_cemetery` | vestige | **30** / 40 | **34** / 80 | **12** / 20 | **0,0 %** |

L'aire runtime à 0,0 % n'est pas une performance, c'est une conséquence de
l'architecture retenue : la géométrie des trois lieux vient de `.glb` importés,
donc de maillages à `resource_path`, et non de meshes fabriqués à l'exécution.
D1a — « la part d'aire portée par du runtime » — n'a donc rien à juger chez moi,
et D1b juge la boîtitude de ce qui reste. C'est une information sur le
périmètre du contrôle, pas un satisfecit.

### 7.3 D3, étage image — le détecteur de répétition

Rejoué sur les silhouettes fraîches :
`python3 tools/lot1_repetition.py --manifestes evidence/world_v2/v2_3_b/lot1/silhouettes --out …`
→ **`PASS`**, 0 paire signalée. Verdict archivé sous
`filets/verdict_repetition_voie_b_7b31316.json`.

Écart maximal de chacun de mes trois sujets à **n'importe quel autre** sujet,
et marge au seuil calibré sur le corpus accepté :

| Sujet | 30 m (S = 0,4931) | 80 m (S = 0,4912) | 160 m (S = 0,5458) |
|---|---|---|---|
| `watchtower_ruin` | 0,4647 → **−0,0284** | 0,4526 → −0,0386 | 0,4355 → −0,1103 |
| `forest_shrine` | 0,4516 → −0,0415 | 0,4544 → −0,0368 | 0,4532 → −0,0926 |
| `barrow_cemetery` | 0,4369 → −0,0562 | 0,4103 → −0,0809 | 0,4610 → −0,0848 |

Le voisin le plus proche des trois n'est pas un lieu du lot mais un accepté :
`waterfall_cave` pour la tour et le sanctuaire, `abandoned_farm` pour le
cimetière. Le témoin dégénéré — un sujet comparé à lui-même — est **signalé à
1,0000 aux trois distances** : la chaîne de chargement, de ré-échantillonnage et
de comparaison a donc réellement tourné.

**Portée exacte de ce rejeu, et sa limite.** Dans MON arbre, les silhouettes des
sujets des voies A et C sont celles d'avant leur reprise : le rejeu fait
autorité sur la forme de mes trois sujets, pas sur la distance finale entre lots.
Le verdict officiel se regénère à l'intégration, quand les six silhouettes
reprises coexistent. Je n'ai **pas** touché
`evidence/world_v2/v2_3_b/lot1/controles/verdict_repetition.json`, qui est le
fichier que lit le filet.

### 7.4 Le filet des silhouettes

`capture_silhouette.gd` refuse d'écrire deux choses : une image non bimodale
(plus de 3 % de pixels hors des deux valeurs) et un sujet occupant moins de
2,0 % de l'image. Les trois sujets, recapturés à `7b31316` :

| Sujet | cadre | 0° | 90° | hors bandes |
|---|---|---|---|---|
| `watchtower_ruin` | 900×1200 | 13,50 % | 9,12 % | 0,000 % |
| `forest_shrine` | 900×1200 | 6,36 % | 6,63 % | 0,000 % |
| `barrow_cemetery` | 1200×900 | 3,51 % | 3,88 % | 0,000 % |

Le changement de cadre du cimetière est une **mesure**, pas un confort : §9.4.

### 7.5 Les deux sondes de condition d'arbitrage, rejouées à l'état livré

| Sonde | Verdict | Cotes | Journal |
|---|---|---|---|
| `probe_sanctuaire.gd` | **PASS** | chevet le plus haut **2,092 m** au-dessus du sol gelé → marge **0,308 m** sous le plafond d'identité de 2,40 m ; 32 appuis sondés, plus grande marche **0,300 m** (marche du héros 0,38) ; dégagement latéral minimal **0,65 m** (rayon de capsule 0,40) ; **159** instances V2.2 dans 14 m en 8 groupes, INTOUCHÉES ; le lieu plante **3** troncs — `Pine_3_30`, `Pine_3_31`, `CommonTree_3_32` | `sonde_sanctuaire_7b31316.log` |
| `probe_vigie_ascension.gd` | **PASS** | 62 appuis sondés ; premier appui 26,00 ; sol du fût 26,00 ; sommet **28,84** ; gain **2,84 m** ; contremarches ≤ 0,38 ; capsule libre ; redescente < 6 m | `sonde_vigie_7b31316.log` |

### 7.6 La chaîne d'assets

Les trois `.glb` ont été régénérés par la chaîne complète, et chaque journal
porte son jeton de fin (`pipeline/`) :

| Sujet | `make` | `export` | `gltf_inspect` | octets | attributs |
|---|---|---|---|---|---|
| `SM_Watchtower_Ruin` | `FIN NOMINALE` | OK | **VALIDE**, 1 110 tris | 81 156 | POSITION, NORMAL, TEXCOORD_0 |
| `SM_Shrine_Vestige` | `FIN NOMINALE` | OK | **VALIDE**, 878 tris | 105 396 | + **COLOR_0** |
| `SM_Barrow_Stones` | `FIN NOMINALE` | OK | **VALIDE**, 718 tris | 91 588 | + **COLOR_0** |

Les trois portent `min Y = 0`, aucune texture, aucun rig, aucune animation.
L'absence de `COLOR_0` sur la tour n'est pas un oubli d'export : c'est un choix
de traitement (aplat painterly, §2) — et §9.2 mesure ce que ce choix coûte.

### 7.7 La provenance des preuves

`python3 tools/lot1r_manifeste.py evidence/world_v2/v2_3_b/lot1r/voie_b/apres_final`
→ **`CONFORME`** : 1 manifeste, 17 images toutes présentes, un seul commit
(`7b31316`), `repo_dirty: false`.

Le même outil sur le dossier de silhouettes rend **2**, et il faut lire pourquoi :
les quinze manifestes sont individuellement **propres** et toutes leurs images
présentes ; l'écart unique est la règle « un seul commit par dossier », que ce
dossier PARTAGÉ n'a jamais respectée — il accumule les sujets du lot pilote
(`bc55474`), le belvédère (`aa4f689`) et désormais mes trois (`7b31316`). Mes
trois portent le même SHA, qui est HEAD. Je ne « répare » pas cet écart : il
appartient au dossier, pas à mes captures.

### 7.8 Ce que ces filets ne prouvent PAS

* Qu'ils **savent rougir** sur l'état livré. Le contrôle négatif qui l'établit
  est celui du 2026-08-23 (`lot1/controles/negatif_lot1_*.log`, commit
  `b7dc0c2`) — il a bien joué un sabotage impliquant `watchtower_ruin`, mais à
  un état antérieur. Rejeu à `7b31316` : **NON VÉRIFIÉ**.
* Quoi que ce soit sur la **performance** : rendu logiciel llvmpipe, jamais un
  budget de frame.
* Quoi que ce soit sur la **jouabilité** : ni écran, ni manette. Les sondes
  prouvent une liaison géométrique et physique, pas un appui de touche.
* Quoi que ce soit d'**artistique**. Ce rapport ne rend aucun verdict de ce
  domaine ; il fournit des images et des cotes.

---

## 8. Lignes de manifeste à écrire par le lead

Sur consigne : **je n'ai touché ni `docs/assets/ASSET_MANIFEST.csv` ni
`ATTRIBUTIONS.md`.** Voici les valeurs réelles, mesurées par `gltf_inspect` et
par lecture directe du JSON glTF.

Les trois GLB sont des **créations originales du projet**, générées par script
Python reproductible : aucune source externe, donc `ATTRIBUTIONS.md` ne les
concerne pas. Seule la tour réemploie des cartes externes — `T_UnevenBrick_*`
et `T_WoodTrim_*` du kit village, **déjà attribuées** dans `ATTRIBUTIONS.md` —
et elle les branche côté Godot, pas dans le GLB (qui ne porte aucune texture).

| champ | tour de guet | sanctuaire | cimetière |
|---|---|---|---|
| id | `SM_Watchtower_Ruin` | `SM_Shrine_Vestige` | `SM_Barrow_Stones` |
| type / catégorie | architecture_ruine | architecture_vestige | architecture_vestige |
| nom affiché | Tour de guet ruinée | Vestige du sanctuaire | Pierres funéraires du tertre |
| auteur / source | projet (générateur Python) | projet | projet |
| licence | licence_projet | licence_projet | licence_projet |
| fichier maître | `source_assets/blender/architecture/SM_Watchtower_Ruin.blend` | `…/SM_Shrine_Vestige.blend` | `…/SM_Barrow_Stones.blend` |
| script de génération | `source_assets/blender/architecture/make_watchtower_ruin.py` | `…/make_forest_shrine.py` | `…/make_barrow_stones.py` |
| chaîne d'export | `tools/blender/export_lieux_voie_b.sh watchtower_ruin` | `… forest_shrine` | `… barrow_stones` |
| export | `assets/architecture/watchtower/SM_Watchtower_Ruin.glb` | `assets/architecture/shrine/SM_Shrine_Vestige.glb` | `assets/architecture/barrow/SM_Barrow_Stones.glb` |
| octets | 81 156 | 105 396 | **91 588** |
| sha256 | *à recalculer par le lead à l'intégration* — deux ont bougé pendant les ré-exports, et un hachage recopié à la main est un hachage faux | idem | idem |
| dimensions (m) | 4,755 × 8,960 × 4,782 | 1,675 × 2,049 × 2,419 | **2,787 × 2,453 × 2,339** |
| min Y | 0,000 | 0,000 | 0,000 |
| triangles | 1 110 (budget 12 000) | 878 (budget 6 000) | 718 (budget 4 000) |
| maillages / pièces | 5 | 9 | 9 |
| matériaux | 3 — `MAT_Tower_Stone`, `MAT_Tower_Wood`, `MAT_Tower_StoneInner` | 2 — `MAT_Shrine_Stone`, `MAT_Shrine_Moss` | 2 — `MAT_Barrow_Stone`, `MAT_Barrow_Lichen` |
| textures dans le GLB | 0 | 0 | 0 |
| attributs | POSITION, NORMAL, TEXCOORD_0 | POSITION, NORMAL, TEXCOORD_0, **COLOR_0** | POSITION, NORMAL, TEXCOORD_0, **COLOR_0** |
| cartes employées à l'exécution | `T_UnevenBrick_*`, `T_WoodTrim_*` (CC0, déjà attribuées) | aucune (aplat + `COLOR_0`) | aucune (aplat + `COLOR_0`) |
| collision | déclarée par le lieu (boîtes/rampes), aucune dans le GLB | idem | idem (sphères par crête) |
| rig / animations | aucun | aucun | aucun |
| LOD | LOD0 seul | LOD0 seul | LOD0 seul |
| statut import | importé sans erreur, `gltf_inspect` VALIDE | idem | idem |

---

## 9. Mesures finales et limites

### 9.1 D'où viennent les preuves livrées

Le dossier de référence est **`apres_final/`** : 17 vues, prises au commit
`7b31316` — le HEAD livré — depuis un arbre dont toutes les sources étaient
committées (`repo_dirty: false`), vérifié par `lot1r_manifeste.py` (§7.7).
Les trois silhouettes ont été recapturées au **même** commit.

Cette recapture n'était pas une formalité. Les silhouettes qui traînaient non
committées dataient de `72151d2`, **un commit avant** `7b31316` — et `7b31316`
est précisément celui qui déplace la hauteur du cimetière de la terre vers la
pierre. La silhouette du cimetière ne montrait donc plus la géométrie livrée.
C'est le genre d'écart qu'une preuve datée attrape et qu'une relecture ne voit
pas.

### 9.2 Les profils de luminance, entrée de l'audit contre sortie livrée

Méthode identique à celle de l'audit : profil de luminance en travers d'une
face, en pixels, sur la capture réelle. Elle a d'abord été **vérifiée** en
reproduisant les quatre mesures d'entrée sur les images que l'audit a lues
(`apres/`, état `e18d075`) : 109 constant sur la stèle, 82 sur 45 échantillons
consécutifs du linteau, 94 sur chacun des deux montants, plateaux 141 / 78 sur
la dalle de la tour. Les quatre sont retrouvées **au niveau près**. La mesure de
sortie est donc comparable.

Une réserve porte sur les coordonnées : la géométrie a bougé entre l'audit et
l'état livré. Là où la ligne de l'audit ne traverse plus la même pièce, je le
dis et je mesure **la pièce**, en publiant sa nouvelle emprise écran.

| Pièce | Entrée (audit, `apres/`) | Sortie (`apres_final/`) | Coupe |
|---|---|---|---|
| **Stèle du cimetière** | **109 constant sur 48 px — étendue 0** | dans le corps de la pierre : **71 → 123**, pied assombri à 34 — **étendue 90** sur 95 px | verticale, `x = 440`, `y = 358…452`, stèle éclairée (emprise ≈ 424-457 × 355-455) |
| *idem, coordonnées exactes de l'audit* | idem | **47 → 71 — étendue 24**, gradient continu, aucun plateau | verticale `x = 290`, `y = 455…540` (la lame penchée, dans l'ombre) |
| **Linteau du dolmen** | **82 constant sur 135 px — étendue 0** | **36 → 51 → 39 — étendue 15** sur 131 px, aucun plateau | dans la longueur, `y = 380`, `x = 660…790` |
| **Montants du sanctuaire** | **94 constant sur chacun — étendue 0** | gauche **70 → 76 — étendue 6** ; droit **70 → 76 — étendue 6** | horizontale `y = 430` (la ligne même de l'audit pour le montant gauche) |
| *idem, coupe verticale* | idem | gauche 76 → 69 dans le corps + pied moussu 40 → 36 (**étendue 40**) ; droit 71 → 76 + pied 43 → 28 (**étendue 89**) | verticales `x = 470` et `x = 930` |
| **Dalle tan de la tour** | **141 constant — étendue 0 par plage** | **140–141 sur 150 px — étendue 1 à 2** dans la face. **INCHANGÉ.** | horizontale `y = 505`, `x = 880…1030` |

Trois lectures, et il faut les séparer :

1. **Le cimetière et le linteau sont réglés au sens de la mesure.** Le plateau à
   valeur unique a disparu ; la stèle éclairée porte des lits de pierre lisibles
   en cote (71 → 123 le long de la pierre). La variation vient bien de
   `COLOR_0` : les lits sont horizontaux, donc c'est la coupe **le long** de la
   pierre qui les traverse.
2. **Le sanctuaire est amélioré mais faiblement.** L'étendue passe de 0 à 6 sur
   ~90 px dans le corps de la pierre : le plateau unique a disparu, le gradient
   est continu, mais l'amplitude reste petite. Le lieu est **sous couvert
   forestier**, dominé par l'ambiante : la même amplitude de `COLOR_0` y rend
   moins d'écart de luminance qu'en lumière ouverte. Je donne la cote, pas un
   verdict : `PARTIAL`.
3. **La tour n'est pas traitée sur cet axe, et c'est mesuré.** La pièce a été
   identifiée par sonde écran plutôt que devinée : c'est
   `SM_Watchtower_Slab_A`, un maillage **de mon lieu**, à 6,9 m de la caméra de
   brèche, emprise écran 819-1208 × 441-643 — elle couvre bien le rectangle
   858-1042 × 478-570 de l'audit. Son GLB ne porte pas `COLOR_0` (§7.6) : les
   pièces tombées de la tour ont reçu un aplat painterly (§2), pas des couleurs
   de sommet. **`PARTIAL`, non traité** ; le geste qui l'a réglé ailleurs
   (`COLOR_0` + `vertex_color_use_as_albedo`) est connu et transposable.

### 9.3 La capture d'arase — la qualité existe, une vue la montre

Demande du lead : lever le point B-f-1 par une capture, **sans reconstruire la
géométrie**. C'est `apres_final/watchtower_gp_arase.png`, prise **du sol**
(`from = (-157,6 ; 28,3 ; 39,1)`, `look = (-161,7 ; 29,9 ; 38,9)`, FOV 40°).

Elle cadre la brèche par en dessous et montre les trois choses que les deux
caméras de revue ne montrent pas : les **deux parements** séparés par le joint
vertical sombre (x ≈ 655-680), la **tranche de mur** en retour (x ≈ 680-810), et
les **gradins d'arase** qui descendent en assises (x ≈ 560-760, y ≈ 0-170).
L'épaisseur n'est pas une impression : elle vaut **0,45 m** dans le générateur
(`EP = 0.45`, murs sur les axes ±2,0 m) et le collider la reprend.

Le fichier est **identique au bit près** dans les cinq tours de capture
(`sha256 f12e91f7…`, apres2 → apres_final) : la vue est stable, et rien de ce
qu'elle montre n'a bougé depuis qu'elle a été ajoutée. Aucune caméra gelée n'a
été déplacée ; les vues gelées sont livrées telles quelles.

### 9.4 Le plancher de silhouette du cimetière — une tension qui n'était pas levée

Le message de `7b31316` affirme « la silhouette garde sa hauteur ». **Mesuré :
elle ne la garde pas.** Dans le cadre 900×1200 employé jusque-là, le cimetière
livré est **refusé** par `capture_silhouette.gd` — sujet affiché à 2,0 %, sous
le plancher de 2,0 % (l'outil sort en échec plutôt que d'écrire une preuve qui
n'en est pas une). L'emprise Y du lieu est passée de 2,863 m à **2,762 m**.

Le cadre a donc été changé, et c'est le seul geste de cette reprise qui touche à
autre chose qu'un document : **1200×900** au lieu de 900×1200 → 3,51 % et
3,88 %, hors bandes 0,000 %.

Pourquoi ce n'est pas un contournement du plancher, en trois cotes :

* le cadrage est piloté par l'AABB : `hauteur_requise = max(Y, largeur × H/L)`.
  Sur un lieu de **23,55 × 2,76 × 19,35 m**, un cadre portrait impose une vue de
  37,7 m de haut pour un sujet de 2,76 m — on mesure alors le cadre, pas la
  forme ;
* les sujets **déjà acceptés** de mêmes proportions sont cadrés en paysage :
  `camp` (25,0 × 3,6 × 18,4), `conductive_basin` (18,2 × 3,2 × 10,0),
  `flower_field` (14,4 × 3,2 × 12,2). Le cimetière rejoint sa famille de forme ;
* le détecteur D3 normalise toute image sur une toile 96×96 : le rejeu complet
  après changement de cadre est au §7.3, il rend `PASS` et la marge du cimetière
  reste la plus confortable des trois.

Ce que je ne fais pas : conclure que la géométrie est bonne parce que la
silhouette s'écrit. La cote qui a changé est celle du cadre ; l'affirmation du
message de commit, elle, était fausse, et elle est corrigée ici.

### 9.5 Les deux récompenses, mesurées à l'état livré

Mesures indépendantes de celles du §4.2 et du §5.2 (boîtes de pixels différentes,
donc valeurs différentes ; ce qui compte est le sens et l'ordre de grandeur) :

| Objet | Audit (`apres/`) | Livré (`apres_final/`) | Boîte |
|---|---|---|---|
| Offrande du sanctuaire | luminance moyenne **0,549** | **0,467** | (622-648, 318-344) de `shrine_gp_nef.png` |
| Coffre du cimetière | luminance moyenne **0,460**, saturation moyenne 0,289 | **0,340**, saturation **0,311** | (645-775, 395-480) de `barrow_cemetery_joueur.png` |

Le coffre passe donc **sous** la steppe qui l'entoure (0,420 mesurée au même
cadre) : la remarque « l'objet le plus clair du cadre » ne tient plus. Sa
**saturation**, elle, n'a pas baissé — 0,289 → 0,311 — et les panneaux de bois
orange restent la famille de teinte la plus saturée du plan. C'est cohérent avec
le point 17 de l'audit : le visuel d'ancre de récompense est une ressource
**partagée**, qu'aucune voie ne corrige seule. `PARTIAL`, et hors de ma main.

### 9.6 Limites honnêtes

Ce qui reste `PARTIAL`, avec sa raison :

| Point | État | Pourquoi |
|---|---|---|
| B-f-4 — dalle tan de la tour à valeur unique | **PARTIAL** | pièce identifiée (`SM_Watchtower_Slab_A`), défaut mesuré et inchangé ; les pièces tombées de la tour n'ont pas reçu `COLOR_0` |
| B-f-13 — montants du sanctuaire | **PARTIAL** | plateau supprimé (étendue 0 → 6), amplitude faible sous couvert ; cote au §9.2 |
| B-f-2 / B-f-9 / point 17 — visuel de récompense | **PARTIAL** | luminance ramenée sous la steppe, saturation inchangée ; la ressource est partagée |
| B-f-1 — épaisseur de la tour aux deux caméras de revue | **PARTIAL** | la qualité existe et une vue l'établit (§9.3) ; les deux caméras gelées, elles, ne la montrent toujours pas, et je ne les déplace pas |
| Contrôle négatif rejoué à `7b31316` | **NON VÉRIFIÉ** | le contrôle qui prouve que ces filets savent rougir date du 2026-08-23 (§7.8) |
| Performance, fluidité, jouabilité | **NON VÉRIFIÉ** | conteneur sans GPU, sans écran, sans manette — hors de portée ici, par construction |
| `parcours_video.json` → vidéo | **BLOQUÉ (volontairement)** | les trois plans de parcours sont livrés ; **aucun `.avi` n'entre dans git** (décision matérielle du lead, `.git` à 1,9 Go) |

Ce qui n'a pas été engagé, et qui doit être dit plutôt que passé sous silence :

* **les jeux de captures intermédiaires `apres2` à `apres5` ne sont pas
  committés** — quatre dossiers de 15 Mo chacun, 60 Mo pour des états que trois
  commits expliquent déjà. Ils restent dans l'arbre de travail
  `/home/user/wt-lot1r-b` ; le lead peut les demander avant que l'arbre ne
  disparaisse. Seul `apres_final` — l'état livré — est committé ;
* **le disque teal** identifié au §3.3 a été retiré de mes lieux par changement
  de famille de caillou ; le constat sur le monde gelé n'a pas eu à être ouvert,
  la cause étant chez moi (`rock_largeC` et ses deux matériaux `dirt` + `grass`).
  Rien n'a donc été porté en ticket ;
* **je n'ai touché ni `docs/assets/ASSET_MANIFEST.csv` ni `ATTRIBUTIONS.md`** :
  le §8 donne les colonnes, le lead écrit les lignes et recalcule les sha256 —
  ils ont bougé pendant les ré-exports (le cimetière est à **91 588** octets, et
  non 91 592 comme annoncé plus haut avant sa dernière passe).

Enfin, la règle qui vaut pour tout ce document : **aucun verdict artistique
n'est rendu ici.** Les cotes disent qu'un plateau de valeur unique a disparu sur
deux lieux et pas sur le troisième. Elles ne disent pas que l'image est bonne.
C'est la revue qui tranche, et elle tranche sur les images livrées.
