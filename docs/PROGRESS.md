# PROGRESS — journal chronologique et handoff

Ordre **anti-chronologique** : l'entrée la plus récente est en haut. La dernière
entrée fait office de handoff et doit indiquer **exactement** la prochaine action.

---

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

### Prochaine action exacte

Les trois agents rendent d'abord un **plan court** — exigence du lead. Le
lead les relit, corrige, puis donne le feu vert. Ensuite intégration **un
par un**, dans l'ordre pont → grotte → hameau, et après chacune : import
propre, filets places 8/8, capture ciblée, inspection à taille réelle.

Ne PAS relancer les 38 preuves ni `validate_fast` avant que les trois
sujets soient visuellement stables — consigne explicite du lead.


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
