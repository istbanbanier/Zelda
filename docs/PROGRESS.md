# PROGRESS — journal chronologique et handoff

Ordre **anti-chronologique** : l'entrée la plus récente est en haut. La dernière
entrée fait office de handoff et doit indiquer **exactement** la prochaine action.

---

## 2026-08-15 (suite) — R2a-3.3 : extérieur de la grotte rebâti en roches CC0

Point de contrôle livré, **aucun verdict artistique auto-déclaré**. Preuves :
`evidence/world_v2/v2_3_r2a/grotte/tranche3/TRANCHE3.md`.

### Le pivot

`anneau_exterieur()` ne rend plus aucune surface : il ne sert plus qu'à la
coque de collision, jamais rendue. L'extérieur est fait de **98 roches du kit
CC0** `kenney_modular_cave_1_0`, échelle 0,55 à 1,55, fondues par remaillage
volumétrique 0,12 m puis décimées, la cavité étant soustraite comme un solide.
Six des sept modules du kit ont été **écartés sur mesure** : leur dos est plat
par construction (plage plane 7,2 à 18,0 m² contre 2,59 pour `template-detail`),
ou ils résistent à la réparation, ou ils font échouer l'union sans jamais
échouer un contrôle — ce dernier cas n'a été trouvé que par bissection.

### Trois exécutions, trois causes, aucune trouvée à l'œil

Un relevé « faite par rang » a été ajouté au générateur : la gaine culminait à
8,26 m contre 9,16 m pour les masses majeures, donc trente-cinq dents
régulières décidaient de la crête. La correction évidente — ancrer le sommet —
a **ouvert un jour** (station 6, azimuts 51 à 71°, 0 croisement), parce que le
placement radial était ce qui garantissait la couverture. La crête se plafonne
donc par la taille : échelle 1,45 → 1,15, marge 1,60 → 0,55, sept puis neuf
azimuts après une épaisseur tombée à 0,16 m dans la salle.

Chaîne verte, RC = 0. Crête gaine 6,01 m. `gltf_inspect` VALIDE, 21 324 tris.

### Deux caméras de preuve étaient fausses, et ce n'était pas le maillage

Le « gros plan du seuil » visait à travers la bouche : la **capture R2a-3.1 à
la même caméra** montre la même masse grise au même endroit, sur un maillage
entièrement différent. Et la vue « trois masses » était prise du côté opposé à
l'approche du joueur. Les deux caméras fausses sont **conservées** pour que les
A/B restent à caméra identique ; deux caméras justes ont été ajoutées à côté.

### Ce que la mesure dit de la composition

`tools/measure_silhouette_masses.py` (nouveau) compte les sommets d'une
silhouette par **proéminence topographique**. Sur l'azimut réel d'approche
(55°, dérivé de la caméra, pas choisi) : **4 sommets de largeur 1,07 à 1,26 m,
coefficient de variation 0,06**. La consigne demandait « trois masses larges et
**asymétriques** » ; l'asymétrie de largeur n'y est pas. Cause nommée : un seul
module, à rapport hauteur/largeur 1,6, répété. Le levier — grouper les majeures
en trois amas d'emprises inégales — n'a **pas** été actionné : c'est une
décision de composition.

Une première version de cet outil comptait les marches d'escalier comme des
masses et rendait des « masses » de 6 cm. Corrigée, et la raison est écrite
dans le fichier.

### Aussi

`ISS-043` : neuf lignes de `ASSET_MANIFEST.csv` ne sont pas du CSV valide
(champ à virgules non quoté). Seule celle de la grotte est corrigée ; les huit
autres appartiennent à des lots gelés et sont nommées, pas touchées.

### Prochaine action exacte

**Attendre le verdict du lead sur les captures de la tranche 3.** Rien d'autre
ne doit partir : pylône, pont et hameau restent gelés, `GO_V2_3_R2B` et
`GO_V2_3_B` restent FAUX, `validate_fast` et les 38 plans restent interdits
tant que la stabilité visuelle n'est pas prononcée.

Si le lead demande la composition en trois amas : le levier est
`ROCHERS`/`rang` dans `make_waterfall_cave.py`, et la mesure de contrôle est
`tools/measure_silhouette_masses.py --entaille=1.50` sur la vue 55°, qui rend
aujourd'hui 3 masses à cv 0,39.

---

## 2026-08-15 — R2a-3.1 : la grotte refaite, et un défaut dans mon propre code

Verdict de la revue au HEAD `9f25e78` : pont et hameau **PASS visuel**,
golden masters 2/4 et 3/4 ; **grotte FAIL visuel**, corrective R2a-3.1
exigée. Travail redevenu séquentiel, agents non relancés, pont/hameau/pylône
non touchés, ni les 38 captures ni `validate_fast` relancés.

### Hameau : gelable, mesuré

Sonde de végétation rejouée sur toute l'emprise (107 pièces, 16 651
instances de semis gelé, 78 dans l'emprise) : **aucune intersection**. Le cas
le plus serré est à 0,35 m — à côté, pas dedans. Aucune reconstruction, la
végétation V2.2 reste intacte. `evidence/…/hameau/VEGETATION_VERDICT.md`.

### Grotte : la première corrective ne changeait rien, et j'ai su pourquoi

La première R2a-3.1 (commit `d8404bb`) passait tous les contrôles et a été
capturée : bouche encore en demi-cercle, façade lisse, galerie en tube.
Mesuré, σ = 13,3 sur la façade et **5,8** sur la paroi intérieure.

La cause était dans mon code, pas dans les réglages. `facette()` quantifiait
le **rayon** mais plaçait le sommet au **vrai azimut** — or un rayon constant
sur un secteur trace un **arc de cercle**. La « section polygonale » que
j'avais annoncée n'existait pas dans le maillage. `coins()` et `polygonal()`
construisent maintenant de vrais polygones, arêtes droites entre sommets.

Le reste a suivi, chaque fois vérifié par une mesure et non par une
intention : polygone du massif **circonscrit** pour ne pas perdre 0,47 m
d'épaisseur ; **visière** et **éperon** ajoutés du côté de l'approche parce
que contrefort et couronne étaient tous deux au nord et que la vue du joueur
ne montrait qu'un dôme ; **collerette** biseautée par une rangée intercalée.

**Deux mécanismes ont été retirés plutôt que gardés** : une banquette et une
tablette d'alcôve, mesurées là où elles devaient culminer, ne relevaient
rien — une fenêtre d'azimut de 52° est plus étroite que l'écart entre deux
sommets (40° à 9 facettes), et l'arête qui joint les voisins l'efface.

### Trois contrôles rendus honnêtes en cours de route

`hauteur_du_sol` rendait 1,544 m à un endroit et −2,078 m à 60 cm de là : le
rayon partait dans la roche. Corrigée (premier impact dont la normale
regarde vers le haut), **elle a montré que la récompense flottait de 0,7 m**.
`controle_annexe_hors_cavite` imprimait `1000000000.00 m` quand il n'avait
rien comparé. Le gabarit ne soustrayait pas le palier de la hauteur libre —
il a d'ailleurs refusé le premier réglage, à 2,04 m pour 2,05 exigés.

### État livré

Commit prouvé `71d1817`, `repo_dirty: false` : 7 vues monde, tournette 8
vues, 2 silhouettes isolées. Filets de lieux **8/8**. Sonde de végétation
rejouée sur l'emprise agrandie : **aucune intersection**. Détail et aveux :
`evidence/world_v2/v2_3_r2a/grotte/CORRECTIVE_R2a_3_1.md`.

**Sept exigences sur huit sont PASS. L'exigence 5 — récompense mise en scène
par la géométrie — est PARTIAL**, et c'est écrit ainsi : le creux de
l'alcôve, la lampe et le palier tiennent la scène, pas une tablette.

### Prochaine action exacte

**Attendre le verdict visuel du lead sur la grotte.** Aucun verdict
artistique n'est auto-déclaré. Ne pas relancer les trois agents, ne pas
toucher au pont, au hameau ni au pylône, ne pas lancer les 38 captures ni
`validate_fast` tant que ce verdict n'est pas rendu.

Si la grotte passe : R2a-5, passe silhouette complète sur les quatre sujets
(angles rasants + contrôle négatif contre l'ancienne planche), puis R2a-6.

## 2026-08-14 (suite 15) — V2.3-A.R2a OUVERTE : changement de PIPELINE artistique

**Verdict du lead sur V2.3-A.R** : chaîne technique et preuves SHA `PASS` ;
**gate artistique ÉCHEC** ; `GO_V2_3_B=FALSE` ; aucune propagation aux cinq
lieux restants ni aux 31 POI. Base de la passe : `c946b0e`, additif strict.

### Ce que le lead accepte

La correction de la chaîne de capture : vraie ligne de base `775aa32`,
`--scene` obligatoire, planches non vides, manifestes propres,
`validate_fast` 899/0.

### Ce qu'il refuse, et c'est une décision de MÉTHODE

> « Les lieux sont encore principalement construits comme des assemblages
> procéduraux visibles, puis corrigés localement. Cela produit des
> intersections, des blocs disjoints et des silhouettes de prototype. »

Corriger localement un assemblage de `BoxMesh` ne le sauvera pas. La règle
change : **les scripts de scène cessent de fabriquer seuls la surface
artistique finale**. Ils gardent l'instanciation, l'implantation, les
interfaces fonctionnelles, les collisions simples et les variations
contrôlées. La peau vient de modules CC0 correctement assemblés ou de
vrais meshes Blender à source conservée. Les primitives ne servent plus
qu'aux collisions, sondes et supports **invisibles**.

### Périmètre de R2a — QUATRE golden masters, pas neuf lieux

1. hameau de la rivière · 2. pont de pierre · 3. grotte de la cascade ·
4. pylône de Résonance.

Ferme, arbre foudroyé, camp braise et bassin **restent en attente** : ils
ne seront repris qu'après validation des quatre références. Le camp /
checkpoint est le seul sujet jugé en progrès ; il reste **gelé** pendant
ce sous-gate.

### Défauts bloquants relevés, sujet par sujet

Village : une maison domine seule, éléments blancs non finis, silhouette
collective absente · Ferme : charpente en dents verticales, mur
rectangulaire intact, et la capture `structure_ferme_charpente` **manque le
sujet** · Pont : blocs désolidarisés, grandes faces blanches, géométrie
qui dépasse des culées, la vue sous arche **entre dans le maillage** ·
Grotte : enveloppe ouverte, plaques fines, la caméra intérieure est
**dans les polygones** · Arbre : blocs bruns, noirs et blancs disjoints ·
Camp braise : accumulation sans hiérarchie, illisible à 94 m · Bassin :
fragments blancs anguleux, arbre masquant le centre · Pylône : progrès à
distance, mais base en amas de blocs · **Planche de silhouettes : non
vide, mais c'est une mosaïque couleur — ce n'est pas un test de
silhouette.**

### R2a-0 — FAIT : l'enquête, et ses trois trouvailles

**Blender était présent et INCAPABLE d'exporter, en silence.** numpy
manquait ; l'exporteur glTF en dépend ; l'échec rendait **code 0** et
`run_export.sh` revalidait alors les `.glb` déjà versionnés en annonçant
« VERT ». Corrigé (numpy, `--python-exit-code 1`, jeton de fraîcheur) et
**prouvé en le faisant rougir** : numpy masqué → RC 1, ROUGE.

**Les pivots des modules CC0 sont enfin mesurés**
(`tools/godot/probe_kit_seating.gd`, 48 modules). `KitScale.factor()` rend
1,000 partout où l'on comptait bâtir : aucun redimensionnement silencieux.
Tous les murs font 2,00 × 3,12 × 0,41 m, pivot centre/min/**0,77**. Et
`seat()` plaque au sol tout module dont l'origine n'est pas à sa base —
une fenêtre passée par `K.module()` finit **par terre** (1,016 m mesurés).

**Aucun module CC0 ne peut couvrir le pylône** : ni fût à dosserets, ni
anneau incomplet, ni couronne bifide, ni canal creux. Blender était la
seule voie honnête — d'où l'ordre des travaux.

### R2a-4 — FAIT : pylône, premier golden master

Script de scène : **238 maillages GDScript → zéro**. Il instancie un GLB
produit par `source_assets/blender/architecture/make_pylon_resonance.py`
(source reproductible versionnée). Aucun booléen — que des volumes
**loftés**. Les trois canaux sont dans le **profil** du fût. 17 objets,
34,56 m, base à z = 0. Filets `world_v2_places` 8/8 verts.

Deux défauts d'outillage trouvés en chemin, tous deux silencieux :
`gltf_inspect.py` ne mesurait **qu'un maillage** (1,7 m annoncés pour
34,56) ; et le pylône rendait **blanc** à cause de la conversion
sRGB/linéaire de `baseColorFactor` (0,40 écrit → 0,67 reçu, 0,14 → 0,41 :
contraste écrasé). Les deux corrigés et mesurés.

### R2a-4.1 — FAIT : recalibrage du pylône sur verdict du lead

Verdict reçu : R2a-0 `PASS`, R2a-4 « progrès majeur, pas encore golden
master », plus **un défaut de preuve** — le manifeste portait
`commit: 6ddac267` et `repo_dirty: true`, donc des images produites avant
le commit du code, depuis un arbre modifié. Corrigé à la racine : toutes
les preuves de cette passe portent `commit 4165801` et `repo_dirty: false`.

Les quatre points demandés, et ce que chacun a réellement révélé :

1. **Pieds** — section octogonale chanfreinée, sabot noyé dans la plinthe,
   chapiteau sous le collier. Demi-largeur 1,80 → 1,32 m *après mesure sur
   silhouette isolée* : trois volumes séparés dans le maillage ne font pas
   trois pieds séparés à l'œil, c'est la projection qui décide.
2. **Canaux** — nervures de part et d'autre, cyan découpé en neuf inserts
   calés sur les bandeaux, émission 1,4 → 0,85. Puis le balayage a montré
   le vrai défaut : le noyau sombre était **6 cm derrière** le fond du
   canal, donc invisible, et le fond rendait 0,203 — la valeur exacte du
   flanc. Noyau ressorti de 4 cm : fond 0,133 contre nervures 0,260,
   **cyan coupé**.
3. **Anneau** — le défaut était un PIVOT. `rotation_euler` tourne autour de
   l'origine de l'objet, au sol : 9° appliqués à z = 22,30 décentraient
   l'anneau de **3,49 m**, et la bande traversait le fût. Basculement
   refait autour du centre de l'anneau ; consoles dans le même repère ; le
   générateur refuse d'enregistrer si l'étalement dépasse 1,10 m.
   Ouverture élargie à 84° et **présentée de profil** — pointée vers
   l'objectif elle donnait deux cornes et aucun anneau.
4. **Couronne et matières** — effilement 3,3×, coiffe en volume unique
   terminé en pointe, fourche décalée en Y (deux dents alignées sur le seul
   axe X disparaissaient l'une derrière l'autre à 0°). Matières recalibrées
   **sur la capture** : l'écart d'éclairement (×1,63) égalait l'écart de
   matière (×1,62), donc les trois matériaux rendaient la même valeur.
   Mesuré après : bronze 0,398 · pierre 0,553 · ivoire 0,678.

Deux outils créés, parce qu'une preuve doit être rejouable :
`tools/blender/export_architecture.sh` (le pylône de R2a-4 avait été
exporté à la main) et `tools/godot/capture_silhouette.gd`, qui produit la
silhouette isolée et **refuse d'écrire** une image non bimodale — le
contrôle qui manquait à la « mosaïque de couleurs ».

Trois cadrages de R2a-4 étaient faux et ont été refaits par le calcul : le
gros plan visait 51° à côté du canal le plus proche, et deux vues « à
hauteur de joueur » étaient à 11,5 m du sol. Détail et nombres :
`evidence/world_v2/v2_3_r2a/README.md`.

### VERDICT LEAD SUR R2a-4.1 — PASS, pylône GELÉ

Reçu : « PASS artistique et technique. Le pylône est validé comme golden
master 1/4 ». Six critères `PASS` — preuves au SHA `4165801`, pipeline
Blender→GLB→Godot reproductible, silhouette générale et couronne bifide,
tripode et ancrage, canal géométrique sombre à cyan rythmé, anneau
incomplet lisible dans les axes réels de jeu.

L'arbitrage de la silhouette à 0° est **accepté** : « il n'est pas
nécessaire qu'un anneau ouvert conserve la même lecture sous tous les
azimuts ».

**PYLÔNE GELÉ au code `4165801`** — ne plus le modifier hors régression
démontrée. Le lead précise qu'il « valide la méthode et la cohérence
géométrique » mais « ne constitue pas un plafond de richesse
architecturale » pour les trois sujets restants.

### R2a-2/3/1 — production PARALLÈLE contrôlée, en cours

Trois worktrees et trois branches créés depuis `d327e5e` :

| agent | worktree | branche | sujet |
|---|---|---|---|
| pont | `/home/user/zelda-r2b/pont` | `claude/r2a-pont` | `stone_bridge_place.gd` |
| grotte | `/home/user/zelda-r2b/grotte` | `claude/r2a-grotte` | `waterfall_cave_place.gd` |
| hameau | `/home/user/zelda-r2b/hameau` | `claude/r2a-hameau` | `riverside_village_place.gd` |

Propriété EXCLUSIVE des fichiers : chaque agent ne touche que son
générateur, son GLB, son `*_place.gd` et son dossier de preuves. Réservés
au lead et interdits aux agents : `PROGRESS`, `STATUS`, le README global
de R2a, le manifeste d'assets, les builders et kits partagés, le layout,
et tout ce qui est gelé en V2.2 (terrain, eau, végétation, navigation,
caméras).

**Blender tourne en parallèle ; Godot est SÉRIALISÉ.** Trois worktrees
partagent la même machine et le même `user://` — le 2026-08-11, deux
suites concurrentes ont fabriqué huit échecs de sauvegarde et coupé une
ligne de journal en plein mot. Le verrou `/home/user/zelda-r2b/godot_serialise.sh`
enveloppe chaque invocation dans un `flock` ; il sort en 3 (BLOQUÉ), jamais
en 0, si le verrou n'est pas obtenu. Aucun agent ne lance `validate_fast`
ni le runner de tests.

Le briefing commun `/home/user/zelda-r2b/BRIEFING_COMMUN.md` porte les
pièges mesurés sur le pylône, pour qu'ils ne soient pas repayés trois
fois : `--python-exit-code 1`, conversion sRGB→linéaire, écart de matière
qui doit dépasser l'écart d'éclairement, pivot de `rotation_euler`,
azimut modèle θ → direction monde `(cos θ ; −sin θ)`, soleil à 199,5°,
hauteur de joueur = sol sondé + 1,7 m, et l'assise `seat()` qui plaque les
fenêtres par terre.

### Les trois candidats sont INTÉGRÉS

Ordre imposé par le lead, tenu : pont → grotte → hameau. Après chaque
fusion : import propre, filets, capture ciblée depuis MON arbre, inspection
à taille réelle. Les trois agents ont respecté la propriété exclusive des
fichiers ; aucun fichier réservé n'a été touché.

| sujet | branche | tris | filets après fusion |
|---|---|---:|---|
| pont | `claude/r2a-pont` | 15 784 | places 8/8 · hydro 4/4 · ancres 2/2 |
| grotte | `claude/r2a-grotte` | 3 192 | places 8/8 |
| hameau | `claude/r2a-hameau` | 2 264 + 488 | places 8/8 · hydro 4/4 |

### Deux outils à moi étaient cassés, et ce sont les agents qui l'ont vu

**`capture_silhouette.gd` aurait menti sur le hameau.** Il instanciait la
scène hors du monde, où `ground_local_y()` rend 0 : quatre bâtiments posés
sur trois niveaux de terrain s'y seraient aplatis, et la silhouette en
gradins — le cœur du sujet — aurait montré une composition inexistante.
Mode `--place=` ajouté, vérifié par contrôle : le pylône y rend la même
silhouette qu'en mode asset.

**`probe_vegetation_near.gd` rendait des comptes faux avec aplomb**, et
trois passes s'en étaient servies pour décider d'implantations. Le test qui
tranche est un balayage de rayon sur un même point : avant, 0 · 0 · **180**
à 3, 6 et 12 m — une marche d'escalier, la cellule entière basculant quand
l'origine de son nœud passe sous le rayon. Après correction : 0 · 0 · **2**.
Facteur d'erreur 90.

La cause était **déjà écrite dans le dépôt** : `world_v2_vegetation_builder.gd`
documente que le renderer DUMMY du mode headless jette les données
d'instance de MultiMesh et rend l'identité, et que le bâtisseur écrit pour
cette raison son plan de plantation en méta `instance_origins`. La sonde
interrogeait le renderer factice.

Ma première tentative de correctif était elle-même fausse — une attente de
stabilisation qui comptait 166 « positions distinctes », c'est-à-dire les
166 cellules. Un détecteur qui se stabilise n'est pas un détecteur qui
mesure.

### Deux points d'arbitrage remontés au lead, non tranchés ici

1. **Le pont est à 28,8 m de son `v2_site`**, contre 19,4 m avant. Mesuré
   et vérifié par moi : à `x = −22`, le sol est en eau de `z = −12` à
   `z = +12` — l'ouvrage précédent était parallèle au chenal et posé dans
   l'eau sur toute sa longueur, ce qui explique rétrospectivement le défaut
   « géométrie qui déborde des culées ». Il n'y avait pas de berge où
   ancrer. La note du layout dit toujours « berge sud du gué central » ;
   personne n'y a touché.
2. **Il n'y a aucune chute d'eau à la « Grotte de la cascade ».** L'affluent
   gelé descend de 3,0 à 0,5 sur ~14 m, pente maximale 0,25 m/m. L'agent
   n'a pas inventé d'eau — l'hydrologie est gelée. C'est une question de
   nommage.

### La faiblesse principale, dite sans l'adoucir

La **richesse de surface de la grotte est en deçà du pylône** : parois
intérieures lisses (amplitude 0,085), masse extérieure en miche. Le lead
avait écrit que le pylône « ne constitue pas un plafond » ; sur ce sujet on
est sous le plancher. Le pont et le hameau, eux, le dépassent.

### Prochaine action exacte

**Attendre le verdict du lead sur les trois candidats.** Aucun verdict
artistique n'est auto-déclaré.

Si les trois passent : R2a-5, la passe silhouette complète sur les quatre
sujets — l'outil existe et a servi ici, il reste à l'étendre aux angles
rasants et à lui écrire son contrôle négatif contre l'ancienne planche —
puis R2a-6, les preuves finales, puis `validate_fast` et les 38 plans, que
le lead a interdit de relancer avant stabilité visuelle.


## 2026-08-12 — Finition visuelle monde entier (branche `claude/full-world-visual-finish`)

Bibliothèque Codex fusionnée (11 packs CC0 en quarantaine), puis huit lots :
terrain entier (teintes organiques, 22 buttes), trois masses boisées
(navmesh re-cuite), rivière pleine longueur, POI harmonisés (toits, crypte,
falaise), donjon habillé par agent (10 GLB promus), UI finie par agent
(débordement 720p corrigé et mesuré). Chaque promotion d'asset est entrée
dans ATTRIBUTIONS + manifeste AVANT commit. Preuves :
`evidence/full_visual_finish_20260812/`.

**Prochaine action exacte** : batterie finale — parcours physiques
(vallée/donjon/boss), `validate_fast.sh` unique, trois joueurs boîte noire
(occasionnel/explorateur/expérimenté), jeu de captures complet (31 POI +
vues générales + salles + acteurs + UI), pousser la branche, livrer à la
revue Codex. Le gate visuel n'est JAMAIS auto-déclaré.
