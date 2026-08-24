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

*(vide — se remplit à l'intégration)*
