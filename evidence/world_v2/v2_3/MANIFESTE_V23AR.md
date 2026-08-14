# V2.3-A.R — manifeste des preuves

Passe corrective additive ouverte sur verdict du lead
(`V2.3-A GATE ARTISTIQUE : REJETÉE`, `GO_V2_3_B=FALSE`), depuis
`aa45a74d36c63d7d7aa6c9f03ff113e92bfad9ab`.

**Aucun verdict artistique n'est prononcé ici.** Ce document dit ce qui a
été changé, ce qui a été mesuré, et ce qui reste faible. Le jugement
appartient au lead.

## 1. Les deux SHA, séparés

| | |
|---|---|
| **SHA du code de capture** | `63821a7` — `fix(world_v2): V2.3-A.R groupes 3 et 4` |
| **SHA des preuves finales** | le commit qui porte ce fichier (voir `git log`) |
| SHA de la ligne de base | `775aa323c1fe80401d4cd146e326297f4fc6c268` (V2.2 gelée) |
| Base de la passe | `aa45a74d36c63d7d7aa6c9f03ff113e92bfad9ab` |

Les trois jeux de captures portent `repo_dirty: false` dans leur
manifeste, et le chemin de scène `res://scenes/world_v2/WorldV2.tscn`.

## 2. Les trois défauts de PREUVE signalés par le lead

### 2.1 Planches entièrement monochromes — CORRIGÉ

Cause mesurée : `Image.blit_rect()` exige que source et destination
partagent le même format. Les PNG se chargent en `FORMAT_RGBA8` ; la
planche était créée en `FORMAT_RGB8`. **Chaque collage échouait en
silence**, sans une ligne d'erreur, et la planche partait en preuve.

- outil corrigé : `tools/godot/compose_contact_sheet.gd` (conversion
  explicite + manifeste JSON de tuiles) ;
- planches vivantes : `planche_silhouettes_v23ar.png`,
  `planche_niveaux_de_gris_v23ar.png` (+ leurs `.json`) ;
- les deux planches vides sont conservées comme contrôle négatif sous
  `controles/planches_vides_v23a/`.

### 2.2 Filet fail-first — ÉCRIT, ROUGE PUIS VERT

`tests/world_v2/test_world_v2_proof_boards.gd` vérifie, planche par
planche puis **tuile par tuile** : nombre de valeurs distinctes,
écart-type de luminance, présence du manifeste, présence réelle du sujet
(ratio de pixels non-fond), écart de luminance entre la tuile et sa
source, et qu'une planche annoncée « niveaux de gris » l'est vraiment.

| Journal | Contenu |
|---|---|
| `controles/controle_planches_ROUGE_avant_v23ar.log` | 6 écarts sur les deux planches livrées en V2.3-A |
| `controles/controle_planches_ROUGE_v23a_relance.log` | rejoué : mêmes 6 écarts |
| `controles/controle_planches_ROUGE_apres_correction_seuil.log` | le filet mord toujours sur les planches vides APRÈS la correction de seuil ci-dessous |
| suite `--filter=proof_boards` | **vert** sur les planches réparées |

**Une correction de seuil, et sa justification.** Le seuil « ≥ 256
valeurs distinctes » est arithmétiquement INATTEIGNABLE sur une planche
en niveaux de gris : `r = v = b`, donc son plafond EST 256, atteint
seulement si les 256 valeurs apparaissent toutes ; mesuré sur la planche
réparée, 237. Le test ne pouvait que rougir, quelle que soit la qualité
de la preuve. Le seuil gris est donc porté à 64 — ce n'est pas un seuil
abaissé pour faire passer une correction, c'est une borne fausse
remplacée par la borne juste, et le contrôle négatif ci-dessus démontre
que les planches vides échouent toujours (1 valeur, écart-type 0,0000).

### 2.3 Ligne de base malhonnête — CORRIGÉE, ET UN DÉFAUT PLUS GRAVE TROUVÉ

L'A/B de V2.3-A annonçait « V2.2 gelée — 131b74d » alors que
`V2_2_FINAL_SHA` vaut `775aa32`. La ligne de base est reprise **depuis
775aa32 exactement**, dans un arbre de travail détaché
(`git worktree add --detach`), manifeste à l'appui
(`captures_baseline_v22final/manifest.json` : `commit`
`775aa323c1fe80401d4cd146e326297f4fc6c268`, `repo_dirty: false`).

En la reprenant, **un défaut de preuve bien plus grave est apparu** :

> `tools/godot/capture_poi_batch.gd` avait pour scène par défaut la
> vallée **V1** (`ValleyWorld.tscn`). Une passe de 21 plans lancée sans
> `--scene` est sortie avec un code retour 0, un manifeste complet et
> des images crédibles — d'un autre monde. La vallée V1 partage les
> ancres §3.3, donc les caméras visaient des objets plausibles : rien
> dans l'image ne criait l'erreur.

Corrigé au point le moins cher : `--scene` est désormais **obligatoire**
dans `capture_poi_batch.gd` et `capture_world_map.gd` ; sans lui, l'outil
s'arrête en `BLOQUÉ` (3). Le manifeste porte le chemin de scène : c'est
lui qu'il faut lire avant de croire un plan.

## 3. Les neuf sujets — ce qui a changé

| Sujet | Correction demandée | Ce qui a été fait |
|---|---|---|
| Pont | tablier, voussoirs, parapets, culées | anneau de 17 voussoirs × 3 rangs, tablier de 15 dalles franchissable, tympans, culées de 7 assises ancrées en berge, parapets à brèche et blocs tombés dans le lit |
| Grotte | enveloppe continue, bouche sombre, seuil | maillage creux unique (parois + voûte + joues), bouche à 12°, rampe de 7 paliers (< 10 cm), sol de roche continu, deux lumières motivées ; poche déplacée deux fois sur mesure (pente du terrain, puis rocher gelé `boulder_-117_3`) |
| Ferme | charpente rompue, pans tombés, gravats | faîtière en deux morceaux, 5 chevrons dont 2 rompus, 3 pans intacts + 2 tombés, débris au sol, soubassement d'assises à la place de la jupe-boîte |
| Village | recomposer sans masquer, quai lisible | troisième volume (grenier sur pilotis), place au puits, profondeur de façade, soubassement maçonné, quai déplacé ; caméra de composition reculée de 21,6 m à 33 m — `village_approche` et `village_proche` restent INCHANGÉES |
| Camp | masse dominante, signes verticaux | halle charpentée (masse dominante), mât à trois fanions, colonne de fumée ; halle déplacée : elle mordait `main_path` en (40, 68) ; mât sorti de la bande de visée gelée de `cam02` (perp. 2,18 → 6,43 m) |
| Camp braise | enceinte crédible, deux brèches, trois zones | pieux/palissade/remblai alternés sur un ovale irrégulier, deux brèches, **flanc éboulé mesuré** (la palissade montait à 8,7 m devant un œil à 8,0), plateforme de guet charpentée, trois zones ; aucun acteur |
| Bassin | eau non rectangulaire, grammaire, trajet | nappe à contour organique (maillage visuel de l'instance SEUL), margelle en pierre taillée, portique isolant, caniveau à rail de cuivre **rompu sur 2,3 m**, anneau d'attente ouvert ; `ConductiveBasin`/`ElectricGraph` intacts, filet de comportement vert |
| Arbre | fente réelle, bois nu, cicatrice, sol brûlé | souche commune, cœur pâle planté dans la fente, moitié vivante à 10,5 m et moitié morte cassée, cicatrice en spirale jusqu'au sol, moignons arrachés, disque brûlé qui épouse le terrain ; fleurs du LIEU retirées |
| Pylône | canaux, anneau, couronne | noyau sombre + piliers détachés (le canal devient un creux d'ombre), base trapue, anneau à deux rangs descendu sous la fourche, couronne bifide à deux dents, veine cyan unique au fond d'un canal ouvert |

## 4. Les preuves livrées

| Dossier / fichier | Contenu |
|---|---|
| `captures_v23ar/` | 33 plans + manifeste (scène World V2, `repo_dirty: false`) |
| `complement_v23ar/` | 5 plans : 3 vues lointaines 90–96 m (camp, camp braise, pylône) et 2 gros plans structurels (charpente de la ferme, canal du pylône) |
| `captures_baseline_v22final/` | 33 plans depuis **775aa32** exactement |
| `ab_v23ar/` | 9 montages A/B, libellés « V2.2 gelée — 775aa32 (aucun lieu) » / « V2.3-A.R — 63821a7 » |
| `planche_silhouettes_v23ar.png` + `.json` | planche couleur, 9 tuiles, contrôlée par le filet |
| `planche_niveaux_de_gris_v23ar.png` + `.json` | même planche en valeurs |
| `metriques_lieux_v23ar.log` | maillages, colliders, appuis et emprise par lieu |
| `controles/` | journaux ROUGES et VERT du filet des planches, planches vides archivées |
| `shots_v23a.json` | les 33 caméras, recadrages documentés dans le commit |
| `shots_v23ar_complement.json` | les 5 caméras de complément |

Les gros plans structurels du pont et de la grotte sont
`pont_sous_arche` et `grotte_interieur`, déjà dans les 33.

## 5. Caméras recadrées, et pourquoi

Quatre recadrages, tous mesurés, aucun de confort :

1. **les quatre caméras du pylône** visaient l'ancre §3.3 `(115, 18, −25)`.
   La structure n'y est PAS : l'ancre doit garder son rayon vertical sur
   le terrain nu (filet `test_world_v2_anchors`, gelé), la structure est
   donc décalée en local `(9,0 ; 4,5)`, soit le monde `(124 ; · ; −20,5)`.
   Les quatre plans photographiaient l'herbe à côté du sujet ;
2. **`camp_braise_composition`** : un rocher gelé de 4 à 5 m tient la
   brèche ouest et barrait le centre. V2.2 ne se déplace pas — l'œil est
   décalé de 4 m au nord-ouest, le rocher encadre au lieu de masquer ;
3. **`village_composition`** : le défaut signalé par le lead. Œil reculé
   de 21,6 m à 33 m et monté à 14 m ;
4. **`ferme_composition` et `bassin_composition`** : le sujet occupait
   moins d'un dixième du cadre — rapprochés à 17 m et 11 m.

## 6. Ce qui reste FAIBLE — dit ici, pas caché

- **Grotte** : vue d'un œil haut, la voûte laisse voir l'intérieur par le
  dessus ; au niveau de la route elle se lit fermée. Non corrigé.
- **Village** : les trois volumes et la rivière se lisent, mais la
  silhouette collective reste mince et le quai ne s'impose pas dans le
  plan de composition.
- **Bassin** : dans le cadrage rapproché, un tronc gelé passe devant la
  cuvette.
- **Arbre** : le disque brûlé est en partie caché par la crête depuis la
  caméra de composition ; le tapis de fleurs gelé au-delà de 8 m reste.
- **Pylône** : l'anneau et la couronne se lisent, mais leur assemblage
  reste un peu grumeleux au sommet.

Aucun de ces cinq points n'a été retesté après une dernière correction :
ils sont `NON VÉRIFIÉ` au sens de `.claude/rules/evidence.md`, et
signalés comme tels plutôt que déclarés acceptables.

## 7. Limites de l'environnement

Conteneur Linux headless sans GPU : les captures viennent de Xvfb + Mesa
llvmpipe, en rendu **logiciel**. Utilisable pour la régression visuelle,
**jamais** pour une mesure de performance. Aucun budget de frame n'est
annoncé dans cette passe.
