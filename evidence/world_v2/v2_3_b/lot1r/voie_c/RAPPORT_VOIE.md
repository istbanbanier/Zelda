# RAPPORT VOIE C — LOT 1.R : Champ des mille fleurs + outillage de preuve

Worktree : `/home/user/wt-lot1r-c`, détaché depuis `89a3009`.
Sujet : `valley.poi.flower_field.01` (micro-POI, r02). Verdict d'entrée
(Codex) : « dans la vue joueur, le champ n'est pas le sujet » — un rocher
sombre au centre du cadre, le bâti derrière, des fleurs en saupoudrage.
Intention imposée en cours de passe (`ADDENDUM_DA.md`) : la respiration
et la joie ; arbitrage lead rendu : **composition B « la Porte des
fleurs » RETENUE**, cinq conditions ; puis **inspection du lead** sur les
captures `apres/`, deux défauts à corriger. Les deux sont traités
ci-dessous, avec la mesure qui les a diagnostiqués.

## 1. Ce qui a changé (le champ)

Fichiers en propriété voie C uniquement :
`scripts/world_v2/poi/flower_field_place.gd`,
`shaders/world_v2/poi/SH_FlowerFieldSway.gdshader`,
`source_assets/blender/environment/make_flower_field_steles.py` +
son `.blend`, `assets/environment/rocks/SM_FlowerField_Steles.glb`,
`tools/lot1r_planches.py`, `tools/lot1r_manifeste.py`,
`tools/lot1r_video.sh`, `tools/godot/lot1r_video.gd`,
`tools/lot1r_export_stele.sh`, `tools/lot1r_video_planche.py`,
`CONCEPTION_champ.md`, le parcours JSON et l'evidence de la voie.

### 1.1 Le fond (première corrective, inchangé)

- **Trois nappes florales** en `MultiMeshInstance3D` (un nœud visuel
  chacune) : blanche au cœur, jaune au flanc sud + poche de premier plan,
  bleue en accent. Plantation en PHRASES de 3-8 autour de centres
  d'ellipse, graine fixe (`GRAINE = 20260824`), clairières explicites. Le
  semis V2.2 gelé est intouché.
- **Couleurs conformes bible §1.4 (blanc/jaune/bleu)** : l'atlas
  Quaternius ne porte que du ROSE et du JAUNE (mesuré capture iter1 — la
  « nappe blanche » rendait rose). Le shader local désature les pétales
  vers la luminance puis les recolore.
- **Vent** : `SH_FlowerFieldSway` = grammaire `foliage_wind` V2.2 (relue,
  jamais modifiée) sur maillage texturé.
- **Récompense** : ancre canonique inchangée (`RewardAnchor.attach`,
  `stamina_herb`) ; elle SUIT désormais la grande stèle (elle est calculée
  depuis `PORTE_GRANDE`), côté abrité.

### 1.2 DÉFAUT 1 du lead — « le cheminement ne se lit pas comme un chemin »

Constat : neuf dalles espacées de 2 à 4 m rendaient « trois ou quatre
POCHES disjointes », et la poche du premier plan lisait « placette ».

Cause : le pas. Une dalle de 0,8 m suivie de 3 m de vert ne ferme pas une
ligne. Densifier était impossible tant que chaque dalle coûtait un
module : elles en prenaient **neuf sur douze**.

Geste : le pavage quitte `K.module()` pour deux `MultiMeshInstance3D`
(0 module, 1 nœud visuel par modèle), à un pas de **0,82 m** avec jeu de
pas, décalage latéral et échelles 0,72-0,94 — les dalles laissent 0,1 à
0,3 m de vert entre elles et l'œil ferme la ligne. La voie principale est
allongée aux deux bouts : elle **traverse** le champ sur ~24 m de
polyligne au lieu de commencer et finir dans le cadre. La branche
sud-ouest reste secondaire (pas de 1,30 m) pour se lire comme un
embranchement. Les deux buissons cédés au budget reviennent.

Preuve : `apres4/flower_field_identite.png` — la voie traverse le cadre de
bas en haut puis se sépare ; `apres4/flower_field_joueur.png` — la voie
monte du premier plan droit vers la Porte sans interruption.

### 1.3 DÉFAUT 2 du lead — « la Porte ne se lit pas comme une porte »

Constat : dans la vue joueur, la petite pierre rendait un **blanc plat
presque sans matière** (« éclat de papier ») et la grande restait
**l'objet le plus sombre près du centre du cadre** — la famille exacte du
défaut d'origine.

Cause, et c'est elle qui condamne l'essai en kit : `rock_largeA` dressé
sur chant est une dalle à **très peu de grandes faces planes**. Une face
unique de 2 m est soit face au soleil — et elle brûle en aplat blanc —
soit tournée vers le ciel — et elle s'effondre en gris-bleu. Le MÊME
albédo (0,58) a produit les deux défauts opposés sur les deux pierres :
ce n'est pas une teinte à corriger, c'est une loi de forme à remplacer.
La condition n°1 de l'arbitrage se déclenche telle qu'elle était écrite.

Geste : **GLB dédié** `SM_FlowerField_Steles.glb` (1 008 tris, 2
matériaux, 0 texture, min Y = 0), généré par
`source_assets/blender/environment/make_flower_field_steles.py` et exporté
par `tools/lot1r_export_stele.sh`. Le générateur REFUSE d'écrire si la
base n'est pas à z = 0, si une facette dépasse 0,010 m² (le défaut de la
dalle de kit, interdit par construction), si l'élancement tombe sous 2,4
(« galet étiré ») ou si l'étendue de couleur de sommet est trop faible.

**Le premier jet du GLB a échoué, et la mesure le dit** : sur
`apres2/flower_field_joueur.png`, la face des deux stèles rendait **une
seule valeur — luminance 175, étendue p10-p90 = 1 niveau sur 58 px de
large** — alors que le maillage portait 465 directions de normale
distinctes. Sur des faces quasi verticales, sous ce ciel, l'irradiance
ambiante domine : la variation d'orientation ne rapporte presque rien.
Les roches du kit ne se lisent pas comme de la pierre grâce à leur
géométrie, mais grâce à la variation de leur atlas. Sans texture, la
seule variation gratuite est `COLOR_0`.

La matière est donc passée dans la couleur de sommet : strates à deux
fréquences, veines verrouillées sur l'azimut, **creux des cannelures
assombris** (c'est ce qui rend les cannelures visibles alors que
l'ambiante écrase leur relief), pied plus sombre et plus vert. Étendue
mesurée par le générateur : **30,5 %** et **26,6 %** de la valeur moyenne ;
il refuse d'écrire sous 20 %.

Résultat mesuré sur `apres3` (géométrie identique à `apres4` pour les
stèles) : étendue de luminance rendue sur la face **31 et 32 niveaux**,
contre 1 auparavant.

Placement : la vue joueur a une géométrie. Son axe passait à **0,10 m** de
la grande pierre — d'où « l'objet le plus sombre près du centre ». Les
deux stèles encadrent désormais cet axe (≈ 1,0 m d'un côté, 1,9 m de
l'autre) et se penchent l'une vers l'autre de 17° et 15° ; la voie passe
entre elles. Hauteurs rendues 2,16 m et 1,18 m : franchement inégales,
comme la composition B le demande.

### 1.4 Détail du lead — l'ourlet rendait blanc-menthe

`TONE_PAILLE` valait 1,12/1,06/0,88 : au-dessus de 1, la teinte AMPLIFIAIT
l'atlas au lieu de le colorer. Ramenée à 0,95/0,84/0,55 — entre les deux
échecs déjà mesurés (l'olive 0,60/0,63/0,50 rendait marron brûlé à iter1).
Vérifié sur `apres4/flower_field_gp_chemin.png` : les touffes de l'ourlet
rendent ambre doré.

### 1.5 Deux pièges silencieux rencontrés, à consigner

Aucun des deux ne produit d'erreur ni d'avertissement ; les deux
produisent un asset silencieusement plat.

1. **L'exporter glTF 4.0 n'écrit `COLOR_0` que si le MATÉRIAU consomme
   l'attribut.** Sans le nœud Color Attribute × Base Color, le `.glb`
   sortait avec `POSITION` et `NORMAL` seulement — et `gltf_inspect.py` le
   déclarait `VALIDE`. Le preset partagé `tools/blender/export_gltf.py` ne
   surcharge pas `export_vertex_color` ; je ne l'ai pas modifié.
2. **Il faut de plus que la couche soit l'attribut de couleur ACTIF et
   celui de RENDU.** Créée par bmesh, elle ne l'est pas d'office. Le
   `.glb` est passé de 80 324 à 128 132 octets une fois les deux
   conditions réunies.

Côté Godot, `_garantir_couleur_de_sommet()` force
`vertex_color_use_as_albedo` sur une COPIE du matériau importé : si
l'import cessait de le poser, la pierre redeviendrait un aplat sans
qu'aucun test ne rougisse.

Conservé : site (aucune coordonnée de site dans le fichier — D5), POI +
`poi_id`, fonction de fourche, village en arrière-plan (gelé, intouché).

## 2. Itérations (le juge est l'image)

| Étape | Commit | Constat sur capture |
|---|---|---|
| AVANT | `89a3009` | verdict confirmé : rocher sombre au centre, fleurs éparses, chemin illisible |
| iter1 | `3f84252` | champ devient sujet, MAIS « blanc » rendu ROSE, bleu éteint, ourlet marron brûlé |
| iter2 | `78767e8` | blanc/jaune/bleu §1.4 — MAIS silhouette aplatie : D3-image FAIL vs tertre (IoU 0,537), committé tel quel |
| iter3 | (porte v1) | stèles de kit : face « grass » = aplat SARCELLE plein cadre |
| iter4 | `dc06…` | minéral pâle juste ; « placette » = `Round_Wide` à 5 m identifié |
| apres | `ce4c743` | **inspection du lead** : chemin en poches disjointes, Porte illisible en vue joueur |
| apres2 | `ed35148` | voie continue ✔ ; stèles GLB pâles MAIS **aplat mesuré (étendue 1 niveau)** |
| apres3 | `ce087bd` | `COLOR_0` : matière **31-32 niveaux** ✔ ; inclinaisons lisibles ✔ |
| apres4 | `0894bd5` | état livré — emprise resserrée pour que la silhouette retrouve son plancher |

Captures : `evidence/world_v2/v2_3_b/lot1r/voie_c/{avant,iter1,iter2,iter3,
iter4,apres,apres2,apres3,apres4}/` — les DEUX caméras gelées de
`shots_lot1.json` (from/look/fov identiques, jamais déplacées) + DEUX gros
plans ajoutés, capturés à l'identique. **`apres4` est l'état livré** ;
manifeste `repo_dirty: false`, commit `0894bd5`.

Incident de preuve consigné : une première capture iter2 portait
`repo_dirty: true` (édition d'un outil pendant le rendu) — détectée par
`lot1r_manifeste.py`, REFAITE d'un arbre committé.

## 3. Outillage de preuve du lot (NOUVEAUX fichiers seulement)

- `tools/lot1r_planches.py` : montages A/B par vue, planche couleur,
  planche niveaux de gris, planche anonyme des six vues joueur (graine
  fixe, clé numéro→lieu dans un JSON séparé). Entrée absente, vue non
  appariée, PNG illisible ⇒ code 2 et la liste exacte.
- `tools/lot1r_manifeste.py` : `repo_dirty:false` + SHA unique + présence
  des images. Il a détecté ma propre capture sale, et l'état à deux
  commits, préexistant, du dossier `silhouettes`.
- `tools/godot/lot1r_video.gd` + `tools/lot1r_video.sh` : vidéo joueur au
  MovieMaker natif, VRAIS contrôles — un `InputIntent` injecté dans le
  vrai `PlayerController` (D-013), une SEULE écriture de position (le
  spawn). Refuse de tourner sans MovieMaker.
- `tools/lot1r_export_stele.sh` (NOUVEAU) : chaîne Blender du seul asset
  de la voie. `export_architecture.sh` est PARTAGÉ et refuse — à raison —
  un sujet absent de sa table ; y ajouter le mien serait une modification
  partagée pour l'asset d'une seule voie. Ce script reprend ses deux
  garde-fous (`--python-exit-code 1`, jeton de fraîcheur) et en ajoute un
  troisième : le jeton `FIN NOMINALE`, que le générateur n'imprime
  qu'après ses contrôles.
- `tools/lot1r_video_planche.py` (NOUVEAU, §5 ci-dessous).

## 4. Budgets du lieu (D7, sous-arbre `RewardAnchor` exclu)

Comptés dans la source ; **D7 est vert en preuve** (filet `lot1_defauts`).

| | avant cette passe | après | plafond |
|---|---:|---:|---:|
| modules | 12 (9 dalles + 2 pierres + 1 buisson) | **4** (2 stèles + 2 buissons) | 12 |
| nœuds visuels | ~17 | ~11 (2 stèles + buissons + 5 nappes/ourlet + 2 pavages) | 30 |
| `CollisionShape3D` | 3 | **3** (2 stèles + sphère de découverte) | 6 |

Le passage du pavage en MultiMesh a rendu **huit modules** : c'est ce qui
a permis à la fois la voie continue, les deux stèles dédiées et le retour
du second buisson.

## 5. Les vidéos n'entrent pas dans git — et ce qui les remplace

Décision matérielle du lead (`HANDOFF_LEAD_C.md` §3) : `.git` pèse 1,9 Go,
et une vidéo de trente secondes en MJPEG pèse ~250 Mo. Six vidéos
ajouteraient plus d'un gigaoctet d'historique **irréversible**.

`tools/lot1r_video_planche.py` produit donc la preuve committable :

- **balayage des marqueurs JPEG** (`FF D8 FF` … `FF D9`) dans le
  conteneur RIFF — ce conteneur n'a ni ffmpeg, ni imageio, ni cv2. Le
  balayage est exact pour ce format : dans les données entropiques d'un
  JPEG valide, tout `FF` est suivi de `00` ou d'un marqueur de
  redémarrage `D0`-`D7`, donc `FF D8` et `FF D9` ne peuvent pas y
  apparaître. Chaque image candidate est en plus **décodée par PIL** avant
  d'être comptée ;
- l'en-tête `avih` donne cadence et nombre d'images **déclarés**, imprimés
  À CÔTÉ du nombre trouvé, jamais à sa place. Mesuré sur la première
  vidéo : **726 trouvées, 720 déclarées** — un conteneur peut annoncer ce
  qu'il n'a pas écrit ;
- planche PNG à N vignettes régulièrement réparties, numérotées et
  horodatées, avec sha256, durée, cadence, résolution en tête ;
- échecs bruyants (RC = 2) : fichier absent, vide, non-MJPEG, image
  indécodable, moins d'images que demandé, écriture impossible. Testé :
  `--help` ; fichier absent ; fichier non-MJPEG ; `--images 5000` sur une
  vidéo de 726 images ; run réel (1,1 s pour 203 Mo).

**Ligne d'ignorance proposée** (je ne l'applique pas : `.gitignore` est un
fichier partagé) :

```gitignore
# Vidéos joueur produites par le MovieMaker natif (MJPEG) : ~8 Mo par
# seconde de film. La preuve committée est la PLANCHE CONTACT produite par
# tools/lot1r_video_planche.py, plus le sha256 et la durée dans le
# manifeste ; le .avi part en pièce jointe de Release, comme l'archive
# jouable. Un blob supprimé ne quitte pas l'historique.
evidence/**/*.avi
```

## 6. Ligne de manifeste d'asset à écrire par le lead

Je n'édite ni `docs/assets/ASSET_MANIFEST.csv` ni `ATTRIBUTIONS.md`
(consigne d'intégration : quatre GLB, trois voies, un CSV partagé).
Valeurs **mesurées** par `tools/gltf_inspect.py` et par le générateur :

| Colonne | Valeur |
|---|---|
| `id` | `SM_FlowerField_Steles` |
| `type` | `prop_environnement_poi` (les deux pierres de la Porte des fleurs) |
| `auteur` | `projet` |
| `source` | `source_assets/blender/environment/make_flower_field_steles.py` |
| `licence` | `licence_projet` (œuvre originale — rien d'externe, donc rien à ajouter à `ATTRIBUTIONS.md`) |
| `fichier_maitre` | `source_assets/blender/environment/SM_FlowerFieldSteles.blend` |
| `export` | `assets/environment/rocks/SM_FlowerField_Steles.glb` |
| `version` | `2` (le `1` sortait sans `COLOR_0` — voir §1.5) |
| `echelle_m` | `0.628x2.160x0.380` (GLB entier) ; grande 0,628 × 2,159 ; petite 0,443 × 1,240 |
| `lod` | `LOD0` |
| `collision` | `boite_godot_locale` (aucune collision dans le GLB ; `K.collider_box` côté lieu) |
| `materiaux` | `MAT_Stele_Pale|MAT_Stele_Fracture` |
| `textures` | `0` |
| `rig` / `animations` | `non` / `0` |
| `statut_import` | `glb_valide_import_godot_verifie` |
| `budget_tris` | `1008` (504 + 504 ; plafond posé par le lead : 2 000) |
| `date` | `2026-08-24` |
| min Y | `0.0000` — contrôlé par le générateur, qui refuse d'écrire sinon |
| sha256 | `fb32ba372d393d3da777a3ea8a13fe755309e283d1512bf3fd006cb2628a664e` |

Réserve honnête à consigner en note : le GLB **n'a pas d'UV0**
(`gltf_inspect` le signale en AVERT). C'est assumé — les deux matériaux
sont des aplats modulés par `COLOR_0`, sans texture — mais cela interdit
un lightmap sur cet asset si le lot en prend un plus tard.

## 7. Ce qui est mesuré (filets et détecteur)

| Contrôle | Verdict |
|---|---|
| `--filter=lot1_defauts` (D0-D8 + témoins), après déplacement des colliders et passage du pavage en MultiMesh | **11 réussis / 0 échoué** |
| `--filter=places_contract` | **5 réussis / 0 échoué** |
| Silhouettes 0°/90°, 1200×900 paysage | **recapturées** — sujet 2,1 % / 2,1 %, hors bandes 0,000 % |
| D3 étage image — **contrôle LOCAL de mon champ, PAS un verdict de lot** | flower_field ne dépasse aucun seuil ; son appariement le plus fort est 0,111 (contre la tour), et 0,091 contre le cimetière du tertre — l'échec d'iter2 (0,537) est réparé PAR LA COMPOSITION |
| Manifeste `apres4` | `repo_dirty: false`, commit `0894bd5` |

**Le verdict D3 du LOT n'est pas à moi.** Le détecteur compare les lieux
deux à deux : mon arbre porte les cinq autres sujets dans leur état
REJETÉ, donc mon verdict ne dit rien du lot. Le contrôle ci-dessus a donc
été écrit **hors dépôt**, dans un fichier de travail.

⚠️ **Avertissement de cueillette.** Deux commits ANTÉRIEURS à la consigne
du lead ont malgré tout écrit dans le fichier partagé
`evidence/world_v2/v2_3_b/lot1/controles/verdict_repetition.json` :
`7d5b3aa` (le FAIL D3 d'iter2) et `9f1f9d7` (le PASS qui a suivi). Ils
datent d'avant l'avertissement d'intégration. **Ne pas cueillir ce
chemin** : sa version dans mon arbre est calculée sur cinq lieux dans
leur état rejeté. Le reste de ces deux commits (silhouettes, journal de
chaîne) reste valable.

Les seuls autres chemins partagés que je touche sont les trois fichiers
de silhouette de MON lieu
(`silhouette_flower_field_000/090.png` et leur manifeste) : un fichier par
lieu, donc sans conflit avec les voies A et B, et à jour de la géométrie
livrée.

Le FAIL D3 intermédiaire (silhouette aplatie ≈ tertre) reste committé tel
quel (`7d5b3aa`) : c'est l'entrée mesurée de la conception, pas un
accident à cacher.

## 8. Ce qui reste honnêtement non réglé

- **La récompense rend une sphère verte unie** posée au pied de la grande
  stèle (visible `apres4/flower_field_gp_chemin.png`, ~(975, 450)). Elle
  était déjà là avant cette passe : constat, pas régression. Le lead a
  depuis relevé ISS-067 (S2) et autorisé chaque lieu à habiller SON
  exemplaire par teinte de surface sur une copie. **Non fait ici, et
  pourquoi** : le visuel n'est pas produit par mon script — `RewardAnchor`
  ne pose qu'un nœud d'ancrage, et c'est le spawner de récompense qui
  remplit le sous-arbre, plus tard. L'habiller depuis le lieu demanderait
  d'entrer dans un sous-arbre que je ne construis pas et que D6 inspecte.
  À faire, mais avec le temps de le vérifier, pas dans les dernières
  minutes d'une passe.
- **Le sommet rompu des stèles se lit peu** à distance joueur : la
  fracture existe dans la géométrie (plan incliné + chapeau au matériau
  distinct) mais elle est petite dans le cadre. Un creusement plus franc
  est l'amélioration suivante la moins chère.
- **La branche sud-ouest peut encore se lire en poche** selon l'angle :
  sur `apres4/flower_field_gp_chemin.png` (250-440, 525-625) son pavage
  plus lâche forme un groupe qui ne se raccorde pas visiblement à la voie
  principale. C'est voulu — elle doit rester secondaire — mais si le lead
  juge que cela rejoue le défaut 1, la correction est d'un caractère :
  `PAVAGE_PAS_SECONDAIRE_M` de 1,30 à ~1,00.
- **La petite stèle montre un bord blanc franc à angle rasant**
  (`apres4/flower_field_gp_nappe.png`, 40-95 × 365-500). De la caméra
  joueur elle a de la matière ; de ce trois-quarts très rasant, l'arête
  éclairée reprend le dessus. À surveiller si une caméra de démo passe
  par là.
- **Le GLB n'a pas d'UV0** (voir §6).
- Mes nappes blanches et bleues **cohabitent avec des fleurs ROSES**
  visibles au premier plan gauche de la vue identité : elles appartiennent
  au semis V2.2 GELÉ (enquête du lead — le bâtisseur de végétation les
  documente lui-même comme « la ROSE hors palette »). Constat, pas un
  défaut de la voie ; le monde gelé reste gelé.
- **D3 champ×cimetière / champ×sanctuaire après intégration** : à
  re-mesurer par le lead sur l'arbre intégré.
- **La planche anonyme du LOT** ne peut exister qu'à l'intégration ; la
  démonstration de l'outil a été faite sur les six vues de `lot1/poi`.
- Le tas `verdict_repetition_SYNTHETIQUE.json` et l'état à deux commits du
  dossier `silhouettes` (préexistants) sont laissés tels quels.

## 9. Conditions d'arbitrage — état

1. **pierres jugées sur capture** : l'essai en kit rescalé a été fait et
   la capture l'a REJETÉ (aplat blanc d'un côté, masse sombre de l'autre).
   GLB dédié livré, chaîne complète, matière mesurée. FAIT.
2. **12/12 en cédant le second buisson** : périmé dans le bon sens — le
   pavage en MultiMesh rend huit modules, le lieu tient à **4/12** et le
   second buisson revient. FAIT.
3. **distinction sanctuaire/cimetière** : deux stèles pâles inégales
   penchées l'une vers l'autre dans la couleur ouverte ; contrôle D3
   local à 0,091 contre le tertre. Re-mesure du lot à l'intégration.
4. **« placette »** : la cause était le pas du pavage, pas seulement le
   `Round_Wide`. Corrigée par la voie continue. FAIT — à re-juger sur la
   vidéo joueur.
5. **ancre canonique intacte, seul l'écrin change** : FAIT ; l'ancre suit
   désormais la grande stèle par calcul, elle ne peut plus se désolidariser
   d'elle.

## 10. Vidéo joueur

Contrat `ADDENDUM_DA` : le parcours se joue en **20-40 s**. Les deux
enregistrements précédents mesuraient 12,8 s puis 17,7 s de jeu.

Cause mesurée : `allure` est la NORME de l'intention, et
`LocomotionTuning.target_speed()` en fait un **palier** — sous 0,6 le
contrôleur marche à 3,5 m/s, au-dessus il court à 6,0. On ne ralentit donc
pas un parcours contemplatif en baissant l'allure ; on allonge les pauses.
Le parcours livré porte 16 s de pause réparties sur cinq étapes, et son
étape 4 est recalée entre les deux stèles (elle visait l'ancienne position
de récompense, à 3,8 m de la nouvelle).

### 10.1 Résultat mesuré

```
[video] OK : 5/5 étape(s), 26.5 s de jeu
VIDEO: .../video_flower_field.avi (255M) — parcours entier
```

| Mesure | Valeur |
|---|---|
| Parcours joué | **26,5 s** — contrat 20-40 s **tenu** |
| Étapes atteintes | 5 / 5 (RC = 0 ; un jalon manqué aurait rendu 1) |
| Durée du FILM | **28,23 s** (847 images à 30,000 i/s) |
| Résolution | 1920 × 1080 |
| Taille | 267 381 996 octets (255 Mo) |
| sha256 | `bdc0e09e626638a8f1cbf3eb3070a4151c51ce52b409d2e8d4303960b11bc06b` |
| Images déclarées dans l'en-tête `avih` | 841 — soit **6 de moins que les 847 trouvées** |

Les deux lectures possibles du contrat — durée du parcours (26,5 s) et
durée du film (28,23 s) — sont l'une comme l'autre dans 20-40 s.

Le `.avi` n'est **pas** committé. Il reste sur disque à
`evidence/world_v2/v2_3_b/lot1r/voie_c/video_flower_field.avi` pour la
pièce jointe de Release. La preuve committée est
`evidence/world_v2/v2_3_b/lot1r/voie_c/planches/video_flower_field_planche.png`
(15 vignettes) et son manifeste JSON.

### 10.2 Ce que la planche montre, et ce qu'elle montre de moins flatteur

- `t = 0` : le héros est en l'air — c'est la mise en place au départ
  (la seule écriture de position, suivie de la chute d'assise). Franc,
  mais c'est une image de spawn, pas de jeu.
- `t = 2` à `t = 8` : la descente depuis la crête. La masse jaune du
  champ apparaît en contrebas — la promesse fonctionne.
- `t = 10` à `t = 18` : la marche sur la voie dallée. **Les dalles sont
  sous les pieds à chaque vignette de cette plage** : c'est la
  vérification que le lead demandait pour le défaut 1, jouée et non
  cadrée.
- `t = 20` à `t = 24` : le passage entre les deux stèles. À `t = 24,17`
  la grande occupe le tiers droit du cadre, de tout près — elle rend très
  pâle à cette distance ; c'est le moment le plus exposé de l'asset.
- `t = 26` à `t = 28` : la sortie au nord-ouest, la nappe bleue au
  premier plan.

Réserve honnête : la planche est un échantillonnage régulier, pas une
vidéo. Elle ne prouve ni la fluidité, ni le vent, ni l'absence de
saccade. Le film reste la pièce à regarder pour cela.
