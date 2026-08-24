# Récolte du lot 1.R — plan d'intégration et journal

Document du LEAD, ouvert **avant** l'intégration. Il ne contient encore aucun
résultat : ce qui suit est le plan, les données déjà collectées, et les pièges
identifiés. Les résultats s'ajoutent au fur et à mesure, datés.

## 1. Règle de cueillette

Trois arbres de travail détachés de `89a3009`, un propriétaire par fichier.
Le contrôle de recouvrement du 2026-08-24 confirme qu'**aucune voie n'a touché
un fichier gelé, un test, ni un outil existant** — zéro conflit attendu sur les
scripts de lieu.

Ordre : **A → B → C**, par cherry-pick, sans commit de fusion.

**Chemins à NE PAS cueillir**, quelle que soit la voie qui les porte :

| Chemin | Raison |
|---|---|
| `evidence/.../lot1/controles/verdict_repetition.json` | le détecteur R-D3 compare les lieux DEUX À DEUX ; un verdict produit dans un seul arbre est calculé pendant que les cinq autres lieux sont dans leur état REJETÉ. Le lead le régénère UNE fois sur l'arbre intégré. Les voies A et C l'ont toutes deux écrit ; la voie C signale elle-même ses deux commits concernés. |
| `docs/assets/ASSET_MANIFEST.csv`, `ATTRIBUTIONS.md` | fichiers partagés, quatre GLB neufs, trois voies : le lead écrit les lignes d'un seul geste (§3). Aucune voie ne les a touchés — consigne respectée. |
| `.gitignore` | fichier partagé ; la règle vidéo est déjà posée par le lead (`e594c54`). |
| `ADDENDUM_DA.md`, `BRIEF_*.md`, `HANDOFF_LEAD_*.md`, `CONCEPTION_*.md`, `RAPPORT_VOIE.md`, `AUDIT_CONTRADICTOIRE.md` | échafaudage de session à la racine des arbres de travail ; leur contenu utile est versé ici et dans `docs/`. |

## 2. CE QUI DOIT ÊTRE PRODUIT SUR L'ARBRE INTÉGRÉ, ET NON DANS UN ARBRE DE VOIE

Point de méthode, identifié le 2026-08-24 : **une preuve qui montre plusieurs
lieux ne peut pas être produite dans l'arbre d'une seule voie**, car les cinq
autres lieux y sont encore dans leur état rejeté. Cela vaut pour :

1. le **verdict R-D3 du lot** (comparaison deux à deux) — et en particulier les
   paires devenues sensibles : trois lieux sur six portent désormais des
   pierres dressées (montants du sanctuaire, stèles du cimetière, Porte du
   champ) ;
2. la **preuve croisée `gp_lointain`** : la caméra du gros plan lointain de la
   tour cadre la vasque de la source, 24 m en contrebas — les deux lieux
   corrigés doivent lire ensemble dans le même cadre ;
3. la **planche anonyme des six vues joueur** destinée à la revue humaine ;
4. les **vidéos joueur** : un parcours filmé dans l'arbre d'une voie peut
   montrer, à l'arrière-plan, un lieu voisin non corrigé. La vidéo du champ
   déjà enregistrée fait exception vérifiée — son cadre ne contient aucun autre
   sujet du lot (village gelé seulement).

## 2 bis. Deux découvertes des voies qui pilotent l'intégration

Elles sont écrites ici parce qu'elles changent la façon dont le lead doit
mener la passe intégrée — pas seulement parce qu'elles sont intéressantes.

### Le contrôle de matière et le contrôle de répétition NE SONT PAS indépendants

Mesuré par la voie A : sortir la famille d'assets Kenney d'un lieu a fait
passer sa hauteur d'emprise de **7,01 à 7,34 m** — et cela a suffi, **à
composition identique**, à faire rougir le détecteur R-D3. Changer de famille
d'asset change la PROPORTION du lieu, donc son verdict de répétition.

Conséquence directe pour l'intégration : la voie B a corrigé les matières ET
les formes de ses trois lieux (tertres de cônes vers des dos arrondis, axe et
chevet au sanctuaire, familles de pierre changées) **après** que la voie A a
mesuré son propre `PASS`. Les silhouettes du voisinage ont donc bougé depuis.
Le verdict du lot doit être rejoué, et il peut rougir sur des paires que
ni l'une ni l'autre ne pouvait voir.

**Le risque a ensuite été CHIFFRÉ, et il n'est pas là où le lead le
craignait.** Sur demande, la voie A a mesuré sa distance à chaque paire :

- les trois lieux repris par la voie B sont **très loin** — la plus proche de
  leurs paires est à **−0,224** d'IoU (belvédère × tour de guet) ; il faudrait
  qu'une silhouette gagne vingt-deux centièmes pour venir toucher ;
- la seule paire réellement serrée parmi les sujets qui changent est
  **belvédère × champ des mille fleurs, à −0,074** — et le champ appartient à
  la voie C, pas à la voie B ;
- **le seuil ne bougera pas** : R-D3 se calibre sur `ferme abandonnée × pont
  de pierre`, deux lieux du corpus accepté que personne ne retouche. Les
  0,4931 / 0,4912 / 0,5458 seront identiques à l'intégration — seules les
  paires bougent, jamais la barre.

Donc le vrai point de fragilité est celui qui **ne bougera pas** :
**belvédère × hameau de la rive à 80 m, marge −0,009**, contre le corpus
stable. C'est celui-là qu'il faut regarder en premier si la passe intégrée
rougit, pas les nouvelles formes de la voie B. Si le rouge survient, la
correction est de COMPOSITION, jamais de seuil.

### La saturation de l'eau dépend surtout de l'INCIDENCE, pas de l'ombre

Le lead avait proposé l'ombre du ravin comme cause du turquoise absent. La
voie A l'a testée au lieu de la croire : l'ombre joue (saturation de l'herbe
0,181 contre 0,360 au soleil), mais **l'incidence domine** — la même vasque,
même ravin, même heure, rend **0,058 de saturation vue au ras et 0,347 vue de
plus haut**, un facteur six sans que rien du lieu n'ait changé.

Conséquence : l'issue que le lead proposait (déplacer la vasque dans une poche
de lumière) est mesurément impraticable — le soleil vient de l'ouest, c'est la
paroi de 14 m à l'ouest qui fait l'ombre, et la seule zone éclairée est en haut
du ravin, ce qui retirerait au lieu sa fiction (l'eau sort du pied du mur).
Statut retenu : `PARTIAL` mesuré, porté tel quel à la revue. À incidence
moyenne, vasque (77,107,118) et rivière gelée (68,105,107) rendent le même
sarcelle — la continuité par construction est donc tenue.

## 3. Lignes de manifeste à écrire par le lead

Quatre GLB neufs, tous **créations originales du projet** générées par script
Python reproductible. `ATTRIBUTIONS.md` ne les concerne pas ; seule la tour
réemploie des cartes externes (`T_UnevenBrick_*`, `T_WoodTrim_*`, CC0 **déjà
attribuées**), branchées côté Godot et absentes du GLB.

Données mesurées, rapportées par les voies — **les sha256 seront recalculés par
le lead** à l'intégration (un juge par fait) :

| champ | tour | sanctuaire | cimetière | champ |
|---|---|---|---|---|
| id | `SM_Watchtower_Ruin` | `SM_Shrine_Vestige` | `SM_Barrow_Stones` | `SM_FlowerField_Steles` |
| export | `assets/architecture/watchtower/` | `assets/architecture/shrine/` | `assets/architecture/barrow/` | `assets/environment/rocks/` |
| octets | 81 156 | 105 396 | 91 592 | 128 132 |
| dimensions (m) | 4,755 × 8,960 × 4,782 | 1,675 × 2,049 × 2,419 | 2,787 × 1,566 × 2,339 | 0,628 × 2,160 × 0,380 |
| triangles | 1 110 | 878 | 718 | 1 008 |
| matériaux | 3 | 2 | 2 | 2 |
| `COLOR_0` | non (cartes) | **oui** | **oui** | **oui** |
| min Y | 0,000 | 0,000 | 0,000 | 0,000 |
| collision | déclarée par le lieu | idem | idem | idem |

Réserve à consigner en note pour `SM_FlowerField_Steles` : **pas d'UV0**
(signalé en AVERT par `gltf_inspect`) — assumé, les deux matériaux sont des
aplats modulés par `COLOR_0`, mais cela interdirait un lightmap sur cet asset.

## 4. Validation après intégration

Dans cet ordre, une seule fois : filets du lot 1 (`lot1_defauts`,
`places_contract`) → huit sabotages `tools/gate_negatif_lot1.sh --lot1` →
détecteur R-D3 régénéré → **une** `tools/validate_fast.sh`.

## 5. Preuves à produire

Treize caméras gelées en A/B, gros plans, silhouettes 0°/90°, planches couleur
et niveaux de gris, planche anonyme des six vues joueur (clé dans un JSON
séparé), planches contact des six vidéos, manifestes `repo_dirty:false`.

**Aucun `.avi` n'entre dans git** (`e594c54`) : la preuve committée est la
planche contact + le sha256 + les paramètres au manifeste ; le film part en
pièce jointe de Release après le verdict visuel.

## 6. Barre à appliquer avant de déranger un relecteur

`evidence/world_v2/v2_3_b/lot1r/BARRE_WAHOU.md`, écrite le 2026-08-24 **avant**
que les captures finales existent — le journal git en fait foi. Un trait
d'identité raté renvoie son lieu en corrective, quelle que soit la moyenne.

## 7. À signaler à la revue, pour que le constat aille au bon endroit

Deux défauts visibles dans les captures **n'appartiennent pas aux lieux** :

1. **ISS-067** — le visuel des récompenses (sphère unie ou coffre de kit
   saturé) vient du système d'interaction partagé et touche quatre lieux sur
   six. Les lieux ont été autorisés à habiller leur propre exemplaire et à
   poser l'ancre ; ils ne peuvent pas remplacer le modèle.
2. **La falaise du fond du belvédère** appartient au monde V2.2 GELÉ : pêche,
   à très grandes faces planes, elle occupe la moitié supérieure de la vue
   d'identité du lieu et tire la composition vers le graybox. La voie A n'a pas
   le droit d'y toucher, et il ne lui a pas été demandé de le faire.

## 8. Journal

### 2026-08-24 — vérification indépendante des artefacts, AVANT cueillette

Le lead a rejoué lui-même, sur les arbres de travail, ce que les voies
annonçaient. Rien n'a été cru sur parole.

**Manifestes de captures** — voie A `final/` : commit `dd3de2e`,
`repo_dirty: false`, 20 images sur disque, et le commit des captures est bien
un ancêtre du HEAD de la voie. Voie C `apres4/` : commit `0894bd5`,
`repo_dirty: false`. **Conformes.**

**Modèles glTF** — relecture directe du bloc JSON de chaque `.glb` (attributs,
comptage de triangles depuis les accesseurs d'indices, min Y depuis
l'accesseur POSITION, sha256 du fichier entier) :

| GLB | octets | triangles | matériaux | `COLOR_0` | min Y |
|---|---|---|---|---|---|
| `SM_FlowerField_Steles` | 128 132 ✔ | 1 008 ✔ | 2 ✔ | présent | 0,0000 ✔ |
| `SM_Watchtower_Ruin` | 81 156 ✔ | 1 110 ✔ | 3 ✔ | absent (cartes) | 0,0000 ✔ |
| `SM_Shrine_Vestige` | 105 396 ✔ | 878 ✔ | 2 ✔ | présent | 0,0000 ✔ |
| `SM_Barrow_Stones` | **91 588** (rapport : 91 592) | 718 ✔ | 2 ✔ | présent | 0,0000 ✔ |

La voie C est exacte au chiffre près, sha256 compris. La voie A n'a pas de GLB.

**Deux valeurs de la voie B ont bougé depuis la rédaction de son rapport** :
le sha256 du vestige du sanctuaire (`a48af851…` mesuré contre `b6eb5891…`
annoncé) et la taille des pierres du tertre (91 588 contre 91 592, avec un
sha256 lui aussi différent). Ce n'est **pas une erreur de la voie** : elle
itérait encore au moment du contrôle, et un ré-export change le fichier. Mais
c'est la démonstration concrète de la règle posée au §3 — **les sha256 du
manifeste sont recalculés par le lead à l'intégration, jamais recopiés d'un
rapport**. Recopiés, ils auraient été faux dès le premier ré-export, et rien
ne l'aurait signalé.

À refaire donc au moment de la cueillette, sur l'état final de la voie B.

### 2026-08-24 — cueillette des trois voies

Faite **par chemins** plutôt que par relecture de commits : les trois voies
totalisaient 63 commits, et plusieurs d'entre eux touchaient des chemins à ne
pas cueillir (le verdict D3 du lot, l'échafaudage de session). Un cherry-pick
commit par commit aurait donc demandé un filtrage manuel à chaque étape.
Méthode retenue : pour chaque voie, `git checkout <HEAD-voie> -- <chemins
filtrés>` puis **un** commit d'intégration. Additif, sans commit de fusion,
et le filtrage est explicite plutôt que réparti sur soixante gestes.

Contrôle préalable : **aucun fichier n'est écrit par deux voies**, hors
l'échafaudage de racine qui n'est pas cueilli. Aucune suppression à gérer
(94 + 111 + 71 ajouts, 8 + 12 + 4 modifications, zéro `D`).

| Voie | HEAD cueilli | fichiers | commit d'intégration |
|---|---|---:|---|
| A — belvédère, source | `efaa97c` | 95 | `c233ceb` |
| B — tour, sanctuaire, cimetière | `4cb5352` | 119 | `9bb38a1` |
| C — champ, outils, audit | `15386fc` | 71 | `488df31` |

Deux rangements faits au passage : le script de montage de la voie A passe de
la racine à `tools/lot1r_montage_eau.py` (convention du dépôt) ; les briefs de
conception, les rapports de voie et l'audit contradictoire sont préservés sous
`evidence/.../lot1r/` au lieu d'être perdus avec les arbres de travail ou
d'encombrer la racine.

Vérification : **aucun `.avi` indexé** (compté à zéro).

### 2026-08-24 — manifeste d'assets, et ce que le recalcul a attrapé

Les quatre lignes sont écrites (`5a35c99`) avec les valeurs relues par le lead
sur l'arbre intégré. **Trois valeurs des rapports de voie étaient périmées** :
deux sha256 (vestige du sanctuaire, pierres du tertre) qui avaient bougé
pendant les ré-exports, et surtout **l'échelle du cimetière annoncée à 1,566 m
de haut, mesurée à 2,453 m** — la valeur du rapport datait d'avant le dernier
reprofilage des tertres. Recopiées, ces trois valeurs seraient entrées fausses
dans un fichier qu'aucun test ne vérifie.

Constat annexe, **hors périmètre et non corrigé** : huit lignes PRÉEXISTANTES
du manifeste portent 20 à 22 colonnes au lieu de 19 (`Male_Peasant`,
`AL_RaiderStates`, `Superhero_Male_FullBody`, `SK_StormGuardian`,
`AwningTent`, et trois icônes `ui_*`). Aucun contrôle ne les voit — même
famille de panne silencieuse qu'ISS-066.

### 2026-08-24 — validation technique sur l'arbre intégré

| Étape | Commande | Résultat |
|---|---|---|
| Import | `tools/lancer_godot.sh --path . --import` | `RC_GODOT=0` |
| Filet des huit défauts | `… --filter=lot1_defauts` | **11 réussis, 0 échoué**, RC 0 |
| Contrat des lieux | `… --filter=places_contract` | **5 réussis, 0 échoué**, RC 0 |
| Contrôle négatif (8 sabotages) | `tools/gate_negatif_lot1.sh --lot1` | *(en cours)* |
| Détecteur R-D3 du lot | *(à régénérer)* | *(à venir)* |
| `validate_fast.sh` | *(une seule fois, en fin)* | *(à venir)* |
