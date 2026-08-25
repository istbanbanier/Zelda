# LOT 1.R — dossier de la candidate visuelle, pour la revue Codex/Istvan

Aucun verdict artistique n'est prononcé ici. Ce dossier rassemble les pièces,
consigne ce que le lead a VU (visible / ambigu / faible / non concluant), et
pose les six questions de la directive §19 sans y répondre.

## Où regarder

| Pièce | Chemin |
|---|---|
| Six A/B principaux + tous les A/B | `planches/ab_<vue>.png` (13) |
| Planche couleur / niveaux de gris | `planches/planche_couleur.png` · `planche_gris.png` |
| **Planche anonyme** (6 vues joueur, numérotées, sans nom) | `planches/planche_anonyme.png` — la clé est dans `planche_anonyme_cle.json`, **à ne pas ouvrir avant la lecture en aveugle** |
| Silhouettes 0°/90° des six lieux | `planches/planche_silhouettes.png` + `silhouettes/` |
| Gros plans matière/structure | `planches/planche_matiere.png` + `gros_plans/` (29) |
| Manifeste global (70 images, sha, résolutions) | `MANIFESTE_CANDIDATE.json` |
| Verdicts D3 (le FAIL attrapé puis le PASS) | `verdict_d3_abd8ea0.json` · `verdict_d3_0e4adc4.json` |
| Filet complet 25/25 | `filet_25sur25_4f66609.log` |

## Constats du lead, à taille réelle (jamais un PASS)

**Tour** — VISIBLE : maçonnerie à vraies valeurs (COLOR_0), un côté porteur
un côté arraché, coffre aperçu EN HAUT par la brèche (la récompense demande
l'ascension), gravats au pied. FAIBLE : la grande plaque intérieure sombre
reste uniforme ; le coffre est petit dans le cadre joueur.

**Belvédère** — VISIBLE : minéral froid (ardoise, V 0,498 contre falaise
0,632), bimodalité et vide panoramique, strates au pendage partagé,
crête recalée sur la valeur des boulders de kit (0,549 pour cible 0,540).
AMBIGU : l'enracinement (l'assise se distingue mal de l'ombre portée).
FAIBLE : la lecture « formation » — ça lit encore des dalles empilées ;
trois hypothèses testées, la suivante est un changement de topologie.

**Source** — VISIBLE : l'eau est turquoise dans la caméra joueur GELÉE
(S 0,079 → 0,490 ; rivière V2.2 : 0,368-0,372), la chaîne bouche → vasque →
déversoir se lit, la tour au-dessus (relation croisée). FAIBLE : le lieu
reste petit dans le cadre joueur ; les mâchoires tirent vers le bleu-nuit ;
rebords mouillés peu lisibles aux caméras gelées.

**Sanctuaire** — VISIBLE : un cœur à silhouette d'enclume (2,69 × 1,72 m)
dominant l'enceinte, un linteau-seuil rompu, deux socles couchés, rien
depuis la route (contrat d'invisibilité tenu). AMBIGU : les frontières de
mousse gardent des bords facettés ; l'ensemble reste petit.

**Cimetière** — VISIBLE : dos de terre continus (normales lissées — plus de
« citrouilles »), terre éclaircie (69,8 → 86,7 contre herbe 113), stèles
inclinées/enfouies, linteau sur montants. FAIBLE : stèles à côtés parallèles ;
le coffre lit « posé au milieu » et son bleu attire l'œil.

**Champ** — VISIBLE : le premier plan EST le sujet (vert nu 76 % → 33 % dans
le bas du cadre joueur), trois phrases de couleur, voie dallée, village
lointain, et l'arbre du bord ouest cadre sans voler. AMBIGU : jaune et blanc
rendent la même valeur en niveaux de gris — les phrases ne se distinguent que
par la teinte.

## Les six questions de la revue (§19) — sans réponse du lead

1. **Tour** : la construction se lit-elle comme une véritable tour ancienne
   brisée, avec ses niveaux et son ascension, ou encore comme un assemblage
   de volumes ?
2. **Belvédère** : la formation se lit-elle comme deux éperons rocheux
   naturels et froids, ou comme des panneaux disposés pour obtenir une
   silhouette ?
3. **Source** : l'eau se lit-elle comme une source turquoise continue, de
   l'arrivée au déversoir, ou comme un plan blanc ajouté dans une vasque ?
4. **Sanctuaire** : le lieu se lit-il comme une ruine rituelle reprise par la
   forêt, ou comme un graybox partiellement décoré ?
5. **Cimetière** : le lieu se lit-il comme un paysage funéraire ancien et
   affaissé, ou comme une répétition procédurale de cônes et d'arches ?
6. **Champ** : le champ de fleurs est-il immédiatement le sujet de la vue
   joueur, avec une composition lisible, ou le regard part-il d'abord vers le
   rocher ou le village ?

## Gate technique ciblé (§15) — état

| Contrôle | Verdict |
|---|---|
| Parse des six scripts | RC=0 |
| Chargement des six lieux (monde monté par le filet) | vert |
| Filets lot 1 (D1-D8 + contrat + invariants) | **25/25, RC=0** |
| Détecteur R-D3 (seuils gelés) | **PASS**, 0 signalée — après un FAIL réel attrapé et corrigé par composition |
| Budgets D7 | verts — après un dépassement réel (sanctuaire 43>40) corrigé par consolidation |
| Gel V2.2 (43 éléments au sha256) | VERT |
| Récompenses / identifiants | inchangés (D6 vert) |
| Manifeste d'assets lot 1.R | 4/4 vérifiées + SM_OverlookCrags ajoutée, empreintes recalculées |
| Arbre propre, captures depuis commit propre | oui — `repo_dirty: false` aux manifestes |
| `validate_fast.sh` | **NON LANCÉE, par construction** (§16 : après le PASS visuel seulement) |
