# Arbitrage des trois plans — R2B.2 (lead, 2026-08-19)

Base commune : `c44f430b`. Les trois plans ont été rendus AVANT toute
implémentation. Ce document fige les décisions pour qu'aucun écart ne se
découvre à l'intégration.

## Les mesures qui ont corrigé le brief ou le lead

**A1 — Le lead avait tort sur OÙ mettre les textures.** Le lead proposait
« déplier les UV0 et brancher les textures du kit » sans préciser l'emplacement.
L'agent A a mesuré : embarquer les cartes dans le GLB coûterait ≈ 30 Mo (12
fichiers de 1,2 à 4,4 Mo) contre 101 Ko aujourd'hui. Décision : **UV0 dans le
GLB, textures branchées côté Godot** sur le point d'accroche existant de
`_peindre_glb()`. Échelle **0,48 UV/m**, mesurée sur le kit et non choisie.

**A2 — La DIRECTIVE avait tort sur la nature du défaut.** Son point 3 demande
« donner une vraie épaisseur aux éléments visibles depuis le seuil ». Mesure :
**une seule pièce sur douze est une plaque** (RoofPan_Intact, 0,14 m) ; les
tableaux font 0,52 m, plus épais que le mur qu'ils bordent. Le vrai défaut est
une **INVERSION D'AXE** : Blender extrude de −0,42 à +0,10 pour ENTRER dans le
mur, l'export Y-up donne `z = −y`, et le GLB rend Z ∈ [−0,10 ; +0,42] — les
quatre tableaux **saillent de 42 cm DEVANT la façade**. Bug de signe, pas
manque de matière. Il explique exactement « les ajouts bouchent la lecture ».
Même cause pour le pignon : 0,68 m d'épaisseur sur un mur dont la géométrie
réelle n'a que 0,20 m → 34 cm de surplomb, base n'entrant que de 0,06 m dans
l'arase.

**A3 — Le compte est DOUZE pièces, pas onze.** La directive dit onze ; la sonde
dit douze, et 23 surfaces sur 23 sont sans UV0 ET sans texture d'albédo. C'est
la sonde qui fait foi.

**B1 — La rotation inter-anneau est exactement 0,000°.** `anneau()` échantillonne
toujours depuis la même origine : les arêtes longitudinales sont des méridiens
exacts. C'est la définition mathématique du « prismatique », et elle donne le
geste — casser la phase, à coût nul en triangles.

**B2 — Le CV lissé révèle le ruban peint que le CV brut masquait.** Brut 0,402
(rassurant) ; lissé sur trois stations, à l'échelle où l'œil intègre, **0,155**.
Le chiffre honnête mesurait une alternance station à station que personne ne voit
(autocorrélation lag-1 = −0,483).

**B3 — L'agent B a JETÉ son propre contrôle.** Sa mesure de plages coplanaires
rendait 0,3 %, donc VERT, sur la géométrie jugée prismatique : le bruit `_graine`
rend le maillage numériquement non plan partout sans rien donner à l'œil.
« Un contrôle que du bruit satisfait mesure du bruit. »

**B4 — L'écart métriques/œil, expliqué.** R2B.1 mesurait la **répartition**
(champ lointain) ; le lead lit la **loi de forme d'une pièce** (champ proche).
Un objet peut être parfaitement irrégulier en répartition et rester fait de
prismes, d'un ruban et de cônes droits.

**C1 — La granularité décide.** Plaques détectées 1/12 par bbox de mesh, 4/23
par primitive, **37/133 par composante connexe**. Trois réponses à la même
question selon l'échelle — de quoi faire diverger un agent et son lead sans
qu'aucun ne sache qu'ils ne mesurent pas la même chose.

**C2 — La boîtitude, que personne ne mesurait.** 118/133 composantes et **87 %
des triangles** sont des boîtes canoniques à 12 triangles.

**C3 — L'auditeur a pris son propre estimateur en défaut.** La moyenne des
écarts angulaires vaut toujours 360/n : tautologie. Seul le CV informe.

**LEAD-0 — Vérification du lead.** `SM_Farm_Ruins.glb` : **23 avertissements
« pas d'UV0 » puis `=== VALIDE ===`**. Le module de kit voisin : **0**. L'outil
avertissait depuis le début et personne n'a agi — défaut de portail consigné,
outil NON modifié dans cette passe.

## Décisions du lead

**4ᵉ matériau de l'arbre (`MAT_Tree_ScorchedSap`) : ACCORDÉ.** La directive exige
une transition écorce brûlée → cœur pâle → éclats, et l'agent a mesuré qu'il
n'existe **aucune valeur intermédiaire** entre deux matériaux au contraste 3,43.
Une transition sans palier ne se fabrique pas par la géométrie. Même écart
accordé à la ferme en R2B.1 pour la même raison. Conditions : plafond de 6 000
triangles intouché · **palier de VALEUR dans la famille existante, pas de teinte
neuve dans le monde** · en-tête du générateur nommant qui a relevé la limite et
pourquoi · ligne de manifeste mise à jour.

**Boîtitude : promue en PORTAIL, calibrée contre les GOLDEN MASTERS.** Pas au
jugé : les quatre golden masters sont les seuls assets du dépôt dont on sait
qu'ils lisent correctement pour un œil humain. Le seuil se pose dans leur bande.
Deux garde-fous : le portail vise une PROPORTION (un moellon parallélépipédique
n'est pas une faute) et il doit **rougir aujourd'hui à 89 %**. Si la boîtitude
ne sépare pas les golden masters de la ferme, l'indicateur ne capture pas ce que
l'œil voit : il redevient un chiffre rapporté. C'est un résultat, pas un échec.

**VERDICT DU RÉSIDU D'APLATS — la décision la plus lourde de la passe.**
L'agent A a mesuré que les bandes de **pur kit** produisent **8,11 %** d'aplat à
elles seules sur `ferme_seuil` : le portail « total ≤ 12 % » ne laisse que 3,9
points pour tout le bâti ajouté, sur une vue prise à 2 m où l'image est aux deux
tiers du mur. **Le seuil du lead était mal calibré pour cette vue** — il avait
été posé en R2B.1 sans mesurer le plancher imposé par le kit.

Le lead ne le relève PAS. Assouplir un seuil pour faire passer une géométrie est
interdit, et la directive exige que `ferme_seuil` passe sur l'image réelle et non
par une nouvelle classification. À la place, un critère qui rend le résidu
décidable **sans toucher au seuil** : le plancher de kit est présent dans l'AVANT
comme dans l'APRÈS, donc il s'annule dans la comparaison.

  - `max ≤ 8 %` et `total ≤ 12 %` : **INCHANGÉS**.
  - Critère ajouté : la régression de R2B.1 doit être **entièrement effacée** —
    `ferme_seuil` doit repasser **sous 23,74 %**, sa valeur d'avant.
  - Verdict, trois cas et pas un quatrième :
      * total ≤ 12 % → **PASS** ;
      * 12 % < total < 23,74 % **et** attribution démontrant que l'excédent est
        de la maçonnerie de kit texturée → **PARTIAL nommé et mesuré**, jamais
        rebaptisé PASS ;
      * total ≥ 23,74 % → **FAIL**, la régression n'a pas été effacée.
  - **L'attribution est faite par l'AUDIT INDÉPENDANT (agent C), pas par
    l'agent A.** Si elle confirme, le PARTIAL est honnête ; si elle contredit,
    c'est un FAIL.

**`ferme_facade` et `ferme_arriere` ne se pilotent PAS au chiffre.** Elles
passent le portail d'aplats (6,49 % et 4,05 %) alors que le lead y a vu un
défaut : un pignon lisant POSÉ et un mur nord parfaitement rectangulaire. C'est
de la STRUCTURE, que la mesure d'aplats ne peut pas voir. Leur portail est le
contrôle (D) : recouvrement pignon/arase ≥ 0,45 m, écart-type d'arase nord
≥ 0,35 m.

**Mur nord : un module de kit EN MOINS, pas une décoration EN PLUS.** Retirer le
module est et l'angle nord-est, les remplacer par un `WallBreak` en gradins.
C'est la seule lecture honnête de « ouverture structurelle, pas décoration
superposée ». Collider pleine hauteur conservé, navmesh gelé intact.

**`SM_Village_Wall` à 0/2 UV0 : NE PAS TOUCHER.** Golden master gelé. Consigné
en dette, vérifié byte-identique.

**UV de l'arbre : hors obligation.** Les neuf points de la directive sont tous
géométriques. Permis en complément, jamais en substitution d'un point
géométrique ni au détriment du budget qu'ils exigent.

## Dettes consignées, NON corrigées ici

- `gltf_inspect.py` écrit `[AVERT] pas d'UV0` puis conclut `=== VALIDE ===` —
  l'avertissement était là depuis le début et personne n'a agi.
- `SM_Village_Wall` sans UV0 (golden master gelé).
- **Traversabilité déjà marginalement en défaut AUJOURD'HUI** : 16 sommets de
  racine à 0,382 m hors de l'emprise du collider, au-dessus du `step_height` de
  0,34 (trouvaille incidente de l'agent B, défaut PRÉEXISTANT).

## Erreur de rédaction du lead, corrigée

Le STATUS de R2B.1 disait « Techniquement VERT (ferme PARTIAL) » ; l'audit
indépendant l'a lu comme si le portail visuel avait été déclaré vert. Il ne
l'était pas — l'échec de `ferme_seuil` était écrit et la passe close en PARTIAL —
mais le libellé prêtait à confusion. Corrigé.

## Le critère du lead, mis en cause par l'audit — mesure en cours

L'audit indépendant a exécuté DEUX méthodes sur `ferme_seuil` :
- **attribution** : kit 17,56 % d'écran (51,2 % des aplats), pièces `SM_Farm_*`
  16,67 % (48,7 %) ;
- **ablation** : retirer les 14 pièces fait tomber le total de 34,26 à
  **26,37 %** — soit −7,89 points quand elles en DESSINENT 16,67.

L'écart de 8,78 points est le mur de kit qu'elles masquaient, et le nombre de
composantes **augmente** au retrait (39 → 41) : signature du dévoilement.
L'attribution de l'image d'ablation donne **100,0 %** du résidu au kit. Bande
d'incertitude déclarée : 1,08 point, contre des écarts de 8 à 18 points.

**Conséquence : le critère « retour sous 23,74 % » que le lead avait gravé est
INATTEIGNABLE.** Même en supprimant jusqu'à la dernière pièce ajoutée, le
plancher vaut 26,37 %. Un critère qu'aucune correction ne peut satisfaire n'est
pas un critère, c'est un verdict déguisé.

**Le lead ne le déplace pas sur une intuition.** Une hypothèse précise est
testée avant toute décision : *c'est une correction EXIGÉE PAR LE LEAD qui
aurait fait monter le chiffre*. En R2B.1, quatre murs présentaient leur face
brique vers l'intérieur et ont été retournés — correction juste, saluée. Mais là
où l'on voyait du plâtre lisse on voit désormais de la brique texturée, et à 2 m
chaque pierre peinte dépasse `MIN_COMPOSANTE`. Corriger l'orientation aurait
donc AUGMENTÉ la mesure d'aplats alors que l'image est meilleure.

Mesure commandée à l'audit — quatre points, la rotation isolée :

| état | pièces présentes | pièces retirées |
|---|---:|---:|
| murs actuels (orientation corrigée) | 34,26 % | 26,37 % |
| murs d'avant R2B.1 (plâtre dehors) | à mesurer | **à mesurer ← se compare aux 23,74 % de R2B** |

Les variantes sont des INSTRUMENTS, pas des livrables : construites, mesurées,
restaurées, restauration prouvée. **L'orientation corrigée reste la
production** — le lead ne revient pas sur une correction juste parce qu'un
instrument la note mal.

Trois issues possibles, à trancher sur la mesure : la hausse vient de la
rotation → le seuil est mal spécifié et devient une comparaison à
ISO-ORIENTATION ; elle vient d'ailleurs → le critère tient et la vraie cause
reste à trouver ; les deux contribuent → part de chacun.

**Écart non résolu entre les deux voies** : l'agent A annonce 8,11 % pour le kit
seul et 24,15 % pour ses pièces ; l'audit trouve 17,56/26,37 et 16,67/7,89.
L'audit refuse de trancher sans voir la méthode de A — c'est la bonne posture.
**C'est l'attribution de l'AUDIT qui fait foi pour la clôture**, comme gravé
plus haut.

## RÉSULTAT : l'hypothèse est confirmée, et le lead RETIRE deux de ses critères

Les quatre points de l'audit, sur `ferme_seuil` (rendus réels, même caméra) :

| # | état | max % | total % |
|---|---|---:|---:|
| 1 | actuel, pièces présentes | 7,32 | **34,26** |
| 2 | actuel, pièces retirées | 5,64 | **26,37** |
| 3 | murs d'AVANT, pièces présentes | 7,32 | **31,83** |
| 4 | murs d'AVANT, pièces retirées | 3,81 | **21,85** |
| — | référence R2B | 2,92 | *23,74* |

**Coût de la rotation, mesuré deux fois** : +2,43 pts (pièces présentes),
+4,52 pts (pièces retirées). Cohérents entre eux par le masquage.
**Confirmé indépendamment par l'attribution** : `KIT_maconnerie` 15,23 → 17,56
(+2,33), `FERME_pieces_ajoutees` 16,58 → 16,67 (+0,09, du bruit) — **96 % de
l'effet porte sur la maçonnerie de kit**. Effet 4,2× la bande de bruit (1,08 pt).

**RÉCIT DU MÉCANISME : RETIRÉ, IL ÉTAIT FAUX.** Une première version de ce
document — et du rapport d'audit — affirmait qu'« à cette distance chaque pierre
peinte de `T_UnevenBrick` dépasse `MIN_COMPOSANTE` ». **Mesuré depuis, c'est
faux** : à pièces retirées de part et d'autre, les composantes passent de 42 à
**41** (−1, alors qu'elles exploseraient si chaque pierre formait la sienne), la
médiane ne bouge pas (2 177 px), la plus grande gagne 48 %, la couverture
**beige** gagne 0,3 % quand la surface **plate** gagne 9,4 %. Ni la
fragmentation ni le prédicat de couleur ne sont le moteur : ce sont les grandes
régions déjà présentes qui grossissent.

**Le seul fait établi** : la face brique se lit **9,4 % plus plate** que la face
plâtre, à couverture beige et nombre de composantes constants. Aucune
explication vérifiée du pourquoi, et l'audit a refusé d'en inventer une seconde.
**La MESURE du coût de rotation tient inchangée ; c'est son RÉCIT qui était
faux.**

**Prudence de l'audit, retenue** : seules les paires 1↔3 et 2↔4 sont propres.
Comparer le point 4 aux 23,74 % de R2B mêlerait quatre commits sur la ferme, un
GLB 2,3× plus lourd (44 280 → 101 364 octets) et un **gain d'albédo** (`74a2834`)
qui touche directement le prédicat `est_beige`.

### Décision 1 — le critère « retour sous 23,74 % » est RETIRÉ

Il comparait deux ORIENTATIONS, donc il ne mesurait pas ce qu'il prétendait.
Équivalent iso-orientation consigné pour mémoire : **26,17 %**. Il ne sert pas
de portail, pour la raison ci-dessous.

### Décision 2 — le portail « total ≤ 12 % » sur `ferme_seuil` est RETIRÉ

À orientation d'avant **et toutes pièces retirées**, le résidu vaut encore
**21,85 %, attribué à 100 % au kit**. Aucune correction confinée à la ferme ne
peut passer sous 12 %. Un portail que rien d'autorisé ne peut satisfaire ne
discrimine pas : il condamne d'avance.

**Ce n'est PAS assouplir un seuil pour faire passer une géométrie.** Aucun
chiffre n'est relevé : un critère est retiré parce que la mesure a prouvé qu'il
ne mesure pas ce qu'on lui demandait — la règle même du projet (« quand un test
échoue, la question est *que mesure-t-il vraiment*, pas *quel seuil le ferait
passer* »).

### Décision 3 — ce qui le remplace est PLUS exigeant

- **`max ≤ 8 %` : INCHANGÉ.** Il suit la grosse tache unique qui fait lire
  « carton ». Aujourd'hui 7,32 avec pièces contre 3,81 sans : les pièces
  ajoutent +3,51 au max.
- **NOUVEAU PORTAIL — coût d'ablation des pièces ≤ +2,0 points.** Aujourd'hui
  **+7,89** (34,26 − 26,37). Il mesure exactement ce que le travail contrôle,
  sur deux rendus RÉELS du moteur et non sur une reclassification. Et il dit la
  bonne chose : des pièces correctement texturées ne devraient pas ajouter
  d'aplat par rapport au mur qu'elles couvrent — aujourd'hui elles en DESSINENT
  16,67 pour n'en coûter que 7,89, donc elles sont **pires que la maçonnerie
  qu'elles masquent**. Seuil à 1,9× la bande de bruit, exigeant une division
  par quatre.
- **Le total reste PUBLIÉ à chaque vue, plancher de kit nommé, sans portail.**

### Décision 4 — la question de périmètre est REMONTÉE, pas tranchée

Le portail ≤ 12 % était celui du lead : il peut le retirer. Le gel du kit vient
de la directive : il ne le lève pas. Constat porté nommé et chiffré à la
clôture, pour que la revue décide :

> sur `ferme_seuil` — caméra à **7,10 m de son point visé** et **1,64 m de la
> face de mur la plus proche**, FOV 66 — la maçonnerie de kit produit à elle
> seule **26,37 %** d'aplats dans l'ORIENTATION LIVRÉE (21,85 % dans
> l'orientation d'avant R2B.1, retenue seulement comme point de comparaison).
> **Aucune correction confinée à la ferme ne peut amener cette vue sous 12 %** ;
> il faudrait toucher au kit `Wall_UnevenBrick_*`, donc à des lieux GELÉS dont
> le hameau riverain.

### Trois défauts d'instrument trouvés par l'audit dans ses PROPRES outils

1. Le sélecteur de pivot rendait « 0 nœud pivoté » — il remontait depuis les
   `GeometryInstance3D` au lieu de descendre. Mesure jetée, instrument réécrit.
2. Le motif attrapait **7 nœuds dont 3 dans le hameau GELÉ** — les pivoter
   aurait faussé la mesure en silence tout en violant le périmètre. D'où
   `--pivot-sous-arbre=abandoned_farm`, qui n'en retient que les 4 de la ferme.
3. **La prose du commit `73b5929` dit « 5 modules », le code en produit 4**
   (`range(3)` → 3 ouest + 1 est). Le lead avait relayé ce « cinq » trois fois
   sans le vérifier — STATUS, rapport R2B.1, deux arbitrages ; corrigé partout.
   **Règle : l'attendu d'un contrôle se lit dans le CODE, jamais dans la prose
   d'un commit.**

Le pivot de l'audit est appliqué au RUNTIME, aucun fichier de lieu touché : la
restauration est acquise par construction, pas par une remise en état qu'on
pourrait oublier.

### Décision 5 — le nouveau portail avait un ANGLE MORT, trouvé par l'audit

Par construction, `coût d'ablation = aplat DESSINÉ par les pièces − aplat de kit
RÉVÉLÉ en les retirant`. **Une pièce plate posée à plat contre un mur plat coûte
donc ≈ 0** : elle dessine autant qu'elle cache. Ce n'est pas théorique — les
deux termes sont DÉJÀ déséquilibrés : les pièces **dessinent 16,67 %** pour n'en
coûter que **7,89**, donc elles en cachent déjà 8,78. Élargir les pièces en les
laissant plates ferait tomber le coût vers zéro **sans rien améliorer**.

**Le portail devient une PAIRE**, sur le modèle de la lecture appariée
boîtitude/orthogonalité, et les deux termes doivent tenir ensemble :

  - **coût d'ablation ≤ +2,0 points** (aujourd'hui +7,89) ;
  - **ET part attribuée aux pièces `SM_Farm_*` ≤ 8,0 %** (aujourd'hui 16,67 %).

Aucun des deux ne se contourne seul : élargir des pièces plates fait tomber le
coût mais fait MONTER la part attribuée au-dessus de son plafond ; les rétrécir
fait baisser les deux mais se voit dans l'image. Le seuil de 8,0 % est à 7,4×
la bande de bruit et demande une division par deux d'un chiffre que le travail
contrôle directement.

**Les deux chiffres sont publiés à CHAQUE vue.** Sur certaines, un coût proche
de zéro sera **trivial** faute de pièces à l'écran : la part attribuée
l'accompagne systématiquement pour que ce cas se distingue d'une vraie réussite.

### Deux affirmations du lead corrigées par l'audit

1. **« à 2 m »** : chiffre jamais mesuré par l'audit. Vérifié par le lead —
   la caméra est à **7,10 m de son point visé** et à **1,64 m de la face de mur
   la plus proche**. Les deux voies mesuraient des distances différentes ;
   aucune n'avait tort, le lead a mélangé les deux.
2. **« 21,85 % » en tête de constat** : décrit l'orientation d'AVANT, pas l'état
   livré. Dans l'orientation livrée, le kit seul produit **26,37 %**.

### Décision 6 — FORME FINALE du portail : trois liants, quatre témoins

L'audit a trouvé **deux trous de plus** dans la paire de la décision 5, et la
grandeur qui les ferme :

- **la SUPPRESSION passe les deux liants** : retirer les pièces met le coût à 0
  et la part attribuée à 0 — deux seuils satisfaits sans qu'aucune surface ait
  été traitée, et la ferme perd son détail de ruine ;
- **le RÉTRÉCISSEMENT passe un plafond ABSOLU** : simulation à pièces divisées
  par deux, **sans aucun traitement** — couverture 24,07 → 12,04 %, part
  attribuée 16,67 → **8,34 %** (frôle le plafond de 8,0), **densité d'aplat
  inchangée à 69,3 %**, défaut intact.

**La grandeur qui ne se contourne pas : `densité d'aplat = part ÷ couverture`,
INVARIANTE D'ÉCHELLE.**

| source | couverture | aplat | **densité** |
|---|---:|---:|---:|
| `FERME_pieces_ajoutees` | 24,07 % | 16,67 % | **69,3 %** |
| `KIT_maconnerie` | 51,07 % | 17,56 % | **34,4 %** |

> **Les pièces ajoutées sont deux fois plus plates, par unité de surface
> visible, que la maçonnerie de kit qu'elles côtoient** — indépendamment du
> cadrage et de leur taille.

C'est la formulation la plus nue du défaut de toute la passe, et celle qui sera
portée à la revue : elle ne dépend d'aucun seuil.

**LIANTS — les trois doivent tenir :**
1. **`max ≤ 8 %`** — inchangé depuis R2B.1 (7,32 avec pièces, 3,81 sans).
2. **`densité d'aplat des pièces ≤ 45 %`** — aujourd'hui 69,3 %. La cible réelle
   est le kit lui-même à **34,4 %** ; le seuil est à 45 parce qu'une pièce peut
   être légitimement plate (un pan de couverture EST plat) et qu'on ne condamne
   pas une géométrie honnête. **Toute valeur entre 34,4 et 45 est publiée comme
   résidu nommé**, jamais comme une réussite.
3. **GARDE D'ANTI-VACUITÉ** — `couverture ≥ 10 %` **et** présence vérifiée des
   pièces structurelles nommées. Un lot dont la couverture s'effondre est refusé
   comme **réussite vide**, quels que soient les autres chiffres. Même garde-fou
   que les planchers posés au budget du camp braise après qu'un camp à zéro
   module est passé au vert. Plancher à 10 % et non plus haut : la correction
   d'axe va légitimement RENTRER les tableaux de 42 cm dans le mur, donc réduire
   leur couverture pour une bonne raison — un plancher serré punirait la
   correction juste.

**TÉMOINS PUBLIÉS à chaque vue, sans portail** : coût d'ablation · part
attribuée · couverture d'écran · densité du kit en regard · marquage
`VUE TRIVIALE` sous 2 % de couverture.

Le coût d'ablation et la part attribuée **cessent d'être liants** : la densité
les subsume. Mieux vaut un liant qu'on ne contourne pas que trois qu'on
contourne.

## Bilan des corrections apportées AU LEAD par l'audit indépendant

Six, dont **cinq portaient sur des choses affirmées ou écrites sans mesure** :

1. le compte des murs retournés — **quatre**, pas cinq (prose de commit contre
   code) ;
2. la distance « à 2 m » — jamais mesurée ; vérifié par le lead : **7,10 m** au
   point visé, **1,64 m** à la face de mur la plus proche, deux mesures justes
   de deux choses différentes ;
3. le « 21,85 % » en tête de constat — décrit l'orientation d'AVANT, l'état
   livré donne **26,37 %** ;
4. le récit « chaque pierre dépasse `MIN_COMPOSANTE` » — **faux**, mesuré :
   composantes 42 → 41, médiane inchangée, beige +0,3 % contre plat +9,4 % ;
5. l'**angle mot** du portail de la décision 5 — une pièce plate posée à plat
   contre un mur plat coûte ≈ 0 ;
6. les **deux trous** de la paire — suppression et rétrécissement.

Le lead a écrit deux portails contournables de suite. L'audit a fourni la
grandeur invariante qui ferme les quatre voies de contournement.

---

## Décision 7 — quatrième tour de l'audit sur le portail : quatre remarques, quatre acceptées, une clause ajoutée

L'audit a relu la forme finale ci-dessus et a produit quatre remarques. Toutes
sont acceptées. Trois portent sur le domaine de validité des liants ; la
quatrième est un aveu d'ignorance de l'audit sur son propre instrument, et c'est
la plus importante.

### 7.1 — La garde d'anti-vacuité échouerait À TORT sur les vues lointaines

> « Les 24,07 % de couverture sont ceux de `ferme_seuil`, où les pièces sont le
> sujet. Sur `ferme_approche`, `ferme_composition`, `ferme_arriere`, les pièces
> sont vues de loin et leur couverture tombera **mécaniquement** sous 10 %. »

Exact, et c'est une faute de ma part : j'ai posé un plancher tiré d'une vue de
seuil sans vérifier qu'il avait un sens sur une vue d'approche. Un lot correct
serait déclaré vide par la seule distance de la caméra.

**Correction : la garde ne s'applique qu'aux VUES QUALIFIANTES**, c'est-à-dire
celles où les pièces sont réellement le sujet.

**Et la clause que la formulation de l'audit n'avait pas** — je l'ajoute parce
qu'elle rouvrirait sinon la voie du rétrécissement par la porte de service :

> **La liste des vues qualifiantes est arrêtée sur la couverture de l'ÉTAT DE
> DÉPART, jamais sur celle de l'état corrigé.**

Sans cette clause, rétrécir les pièces les ferait sortir du portail au lieu de
les y soumettre : la garde d'anti-vacuité se désarmerait elle-même. Critère :
**toute vue dont la couverture au point zéro atteint 15 % entre dans la liste et
y reste**, quelle que soit sa couverture après correction.

### 7.2 — La densité n'a pas de sens sur un petit échantillon

> « Sur une vue à 0,5 % de couverture, elle se calcule sur **4 608 px**. »

Accepté. Une densité est un rapport ; sur quelques milliers de pixels, son bruit
dépasse ce qu'elle mesure.

**La densité ne LIE qu'au-dessus de 2 % de couverture** (18 432 px à 1280×720),
même règle d'état de départ que ci-dessus. En dessous, elle reste **publiée**
avec le marquage `VUE TRIVIALE` déjà prévu, et ne conclut rien.

### 7.3 — La dilution par ajout reste ouverte sur la densité

> « Pour atteindre 45 % sans toucher un seul aplat, il faut porter la couverture
> de **24,07 à 37,04 %** — **+54 % de surface visible**, la part attribuée
> restant clouée à 16,67 %. »

La densité est invariante d'échelle, pas invariante d'ajout : gonfler le
dénominateur avec de la matière neuve fait baisser le rapport sans corriger un
seul aplat. Le vecteur est réel mais coûteux et parfaitement visible, et le
témoin qui le trahit — la part attribuée — est déjà publié à chaque vue.

**Il ne devient donc pas un liant de plus, mais une RÈGLE DE LECTURE, opposable
au verdict :**

> **Une densité qui baisse à part attribuée CONSTANTE est une dilution, pas une
> correction — et elle est refusée comme réussite.**

C'est le même refus que celui de la réussite vide, appliqué au dénominateur au
lieu du numérateur.

### 7.4 — L'audit ne connaît pas la bande d'incertitude de sa propre densité

> « Ma bande d'incertitude de 1,08 point porte sur un **total**. La densité est
> un **rapport de deux grandeurs** ; sa bande n'en découle pas, et je ne l'ai pas
> établie. »

C'est la remarque que je retiens le plus, parce que l'audit l'a formulée **avant
de s'en servir**, alors qu'elle affaiblit son propre instrument. C'est
exactement la discipline que la règle de vérité du projet exige, et elle vient
de l'agent, pas du lead.

**Conséquence, opposable à moi-même :**

1. **Le double rendu du même état est une PRÉCONDITION à tout verdict chiffré
   sur la densité.** Il se mesure sur l'état de départ, parce qu'une bande se
   lit entre deux rendus du MÊME état ; la mesurer après correction mêlerait le
   bruit de l'instrument à l'effet de la correction.
2. **Si la bande se révèle large au point que 45 ne discrimine plus, aucun
   verdict chiffré ne sera rendu sur la densité.** L'écart sera publié avec sa
   bande et porté brut à la revue.

> Mieux vaut un verdict absent qu'un verdict faux.

### Ordre imposé à l'audit — DEUX temps, et le titre le dit maintenant

L'audit a relevé que ce titre disait « au SHA intégré » alors que la note
de fin dit l'inverse pour les points 1 et 2. Il a raison : un titre qui
contredit sa propre note est une ambiguïté, pas un détail. Corrigé.

**Temps 1 — SUR L'ÉTAT DE DÉPART `c44f430b`, avant toute intégration.**
Ces deux mesures disparaissent à l'instant du cherry-pick :

1. **double rendu du même état** → bande d'incertitude de la densité, publiée
   AVANT toute comparaison ;
2. **couverture des six vues** → arrêt de la liste des vues qualifiantes.

**Temps 2 — AU SHA INTÉGRÉ.**

3. **point zéro complet** rejoué ;
4. densité liante + couverture, coût, part attribuée et densité du kit sur les
   six vues, avec marquage des vues triviales ;
5. boîtitude en paire (≤ 25 % des triangles, orthogonalité plafonnée à 73,1 %) ;
6. densité apparente à 94 m dans les deux états ;
7. triptyques R2B / R2B.1 / R2B.2 des six vues décisives ;
8. vérification des caméras par sha256 puis égalité champ par champ.

~~Les points 1 et 2 portent sur l'ÉTAT DE DÉPART et sont donc les seuls que
l'audit peut mesurer avant le SHA — ils disparaissent à l'instant de
l'intégration.~~

**RECTIFIÉ le 2026-08-19 — cette phrase était FAUSSE, et elle est de moi.**
L'intégration ne détruit rien. Mesuré sur l'arbre de travail de l'audit :

    git diff --stat c44f430..74723b2 -- source_assets assets scripts tests project.godot   -> VIDE
    git diff --name-only c44f430..74723b2 | grep -vE '^(evidence/|tools/)'                 -> VIDE

**L'arbre de l'audit EST l'état de départ, géométriquement** — il n'a touché que
`evidence/` et `tools/`. Et un arbre de travail ne bouge pas quand j'intègre :
le cherry-pick s'applique à `/home/user/Zelda`, pas à
`/home/user/zelda-r2b2/c_audit`. `c44f430b` est de toute façon immuable dans
git. Les points 1 et 2 peuvent donc être mesurés **avant ou après** mon SHA,
sans course.

Trois conséquences : l'audit n'est plus pressé ; **je ne suis plus bloqué par
lui pour intégrer** ; et sa preuve devient plus forte, puisque « géométrie
identique à `c44f430b` sur les chemins de production » est une affirmation plus
**précise** que `repo_dirty: false` — elle nomme ce qui doit être identique.

C'est la deuxième contrainte de calendrier que je m'étais inventée dans cette
passe. Les deux venaient de la même faute : écrire une conséquence sans la
vérifier.

---

## Annexe — provenance des trois panneaux du triptyque, vérifiée par le lead

Le §7 exige un triptyque `R2B / R2B.1 / R2B.2` sur les vues décisives, **aux
mêmes caméras**. Le piège évident serait de prendre le panneau R2B dans
`evidence/world_v2/v2_3_r2b/ferme_arbre/captures/`, qui existe — mais dont les
cadrages sont **autres** (`ferme_proche`, `ferme_structure`, absents des quinze
caméras R2B.1). Un triptyque à trois cadrages différents ne compare rien.

La bonne source existe déjà, et c'est le lot `avant/` de R2B.1 :

| panneau | dossier | commit | dirty |
|---|---|---|---|
| **R2B** | `evidence/world_v2/v2_3_r2b1/avant/` | `4a2b43aa` | `False` |
| **R2B.1** | `evidence/world_v2/v2_3_r2b1/apres_integre/` | `e2bf32ab` | `False` |
| **R2B.2** | à capturer au SHA intégré | — | `False` exigé |

Vérifications faites par le lead, et non déduites :

- les deux manifestes portent **15 vues** et les mêmes `from` / `look` / `fov`
  champ par champ sur les vues contrôlées ;
- `7c3d3ca` (base R2B.1) est **ancêtre** de `4a2b43aa`, lui-même **ancêtre** de
  `e2bf32ab` ;
- surtout : `git diff 7c3d3ca..4a2b43aa -- source_assets/blender
  assets/architecture scripts/world_v2/poi` est **VIDE**. Le lot `avant/` montre
  donc bien la géométrie de R2B, capturée aux caméras de R2B.1 — `4a2b43aa` ne
  corrigeait que trois caméras d'arbre qui visaient le pied.

Conséquence opérationnelle : **aucune recapture d'un état ancien n'est
nécessaire**, et le risque de substituer un cadrage favorable au panneau R2B est
écarté par construction, puisque les trois panneaux sortent d'un seul et même
fichier de caméras.

---

## Décision 8 — l'audit corrige l'indicateur que je venais de prescrire, en espace log

Je venais de demander à l'agent A un **résidu à l'ajustement linéaire** pour
attraper le couronnement nord tiré à la règle (RMS 0,065 m pour 1,98 m de
chute, soit 3,3 % — voir `preuves_lead/VERIFICATIONS_LEAD.md` §3). L'audit a
appliqué le même correctif à son propre indicateur de variété, puis a trouvé
qu'il était **aveugle à son tour** :

> les volumes de branches ont des rapports successifs **0,411 / 0,476 / 0,376 /
> 0,376** — une rampe **géométrique**. Le résidu linéaire rend **15,2 %** et les
> déclare irrégulières ; en espace **log** il tombe à **1,7 %**.

| instrument | verdict sur les branches |
|---|---|
| étendue min–max | « variées » — faux, une rampe la maximise |
| résidu linéaire | 15,2 %, « irrégulières » — faux |
| `min(linéaire, log)` | **1,7 %**, balayage strict — juste |

**Un balayage de paramètre est multiplicatif ; le chercher additivement ne le
voit pas.** L'indicateur devient `min(résidu linéaire, résidu log)`, et il est
transmis à l'agent A pour le profil de couronnement : le cas mesuré chez A est
additif, mais rien ne garantit que le suivant le sera.

Mesures corrigées sur l'état de départ : branches **1,7 %** · boîtes de l'arbre
5,2 % · racines 13,7 % · écorces 20,1 % · **boîtes de la ferme 4,7 %** sur 118
membres · veines du pylône 6,5 %.

**Et ce chiffre ne devient PAS un portail.** Raison mesurée, la même qui avait
déjà écarté la périodicité : les **trois pieds du pylône golden master** sont à
**0,0 % de résidu pour une amplitude nulle** — trois volumes rigoureusement
identiques — et le pylône a passé la revue visuelle. **Une architecture se
répète légitimement.** Le chiffre est rapporté et lu par classe d'asset ; il ne
lie personne.

C'est la troisième fois de la passe qu'un indicateur proposé comme robuste se
révèle contournable ou faussement accusateur, et la deuxième fois que c'est
l'audit qui le démontre contre son propre travail. Il l'écrit lui-même :
« mon angle mort était pire puisque je l'avais introduit en croyant corriger ».

## Décision 9 — la densité d'aplat de l'ARBRE : mesurée, publiée, non liante

Vérifié par moi sur le GLB : `SM_ThunderstruckTree.glb` porte **0 primitive
avec `TEXCOORD_0`** et aucune texture, là où la ferme vient d'en recevoir.

Ce n'est **pas** hors contrat. Le dépliage UV0 est le point 1 des exigences de
la **ferme** ; les neuf points de l'arbre portent sur la géométrie, la fracture,
les racines et les bois tombés. L'agent B a répondu en géométrie et en paliers
de valeur, ce qui était la demande.

Je n'invente pas une exigence en cours de passe. Mais je ne laisse pas la
question sans chiffre : **la densité d'aplat de l'arbre est mesurée et publiée
comme témoin sur ses vues, sans portail.** Si elle est mauvaise, c'est un
**résidu nommé** porté à la revue visuelle — pas un échec technique, et surtout
pas un silence.

---

## Décision 10 — la boîtitude : je m'engage sur les trois issues AVANT de connaître la mesure

**Écrit et committé avant que l'audit ne mesure. C'est la seule chose qui
distingue une calibration d'un arrangement.**

L'audit rapporte sur la ferme au SHA intégré :

| | base | SHA | plafond |
|---|---:|---:|---:|
| `hexa` triangles | 87,2 % | **79,6 %** | ≤ 25 % |
| orthogonalité | 73,1 % | **76,7 %** | ≤ 73,1 % |

Les deux moitiés de la paire échouent **ensemble**, dans la configuration exacte
que ma clause anti-contournement décrit — `hexa` baisse pendant que
l'orthogonalité monte. La mesure n'est pas en cause.

**Le domaine du seuil l'est.** Le plafond de 25 % a été calibré sur les **cinq
golden masters**, qui sont tous des **meshes sculptés** : grotte, pylône, pont,
quai, mur. La ferme n'est pas un mesh sculpté — c'est un **assemblage de modules
de kit**, et un module de mur EST une boîte. Une maçonnerie faite de murs
rectangulaires est légitimement boîteuse, au même titre que les trois pieds du
pylône sont légitimement identiques : c'est l'audit lui-même qui a établi ce
second point, et le pylône a passé la revue.

La question n'est donc pas « faut-il abaisser le seuil » — la directive
l'interdit et je ne le ferai pas. Elle est : **ce seuil s'applique-t-il à un lieu
bâti en modules ?**

### La mesure qui tranche : la boîtitude du HAMEAU DE LA RIVIÈRE

Lieu **gelé**, bâti des **mêmes modules de kit**, et qui a **passé sa revue
visuelle**. Trois issues, et je m'engage sur les trois **avant** de les
connaître :

| si le hameau vaut | alors |
|---|---|
| **≈ 80 %** | le plafond de 25 % est **HORS DOMAINE** pour un lieu en modules. Je ne l'abaisse pas : je le **déclare inapplicable à ce sujet**, avec la mesure comme raison — exactement comme j'ai retiré `total ≤ 12 %` quand l'audit a montré qu'il mesurait la maçonnerie de kit et non le travail. |
| **≈ 30 %** | la ferme est réellement plus boîteuse qu'un lieu comparable approuvé. Le portail tient, et c'est un **ÉCHEC** que je porte comme tel. |
| **entre les deux** | je publie les trois nombres côte à côte et **je ne rends aucun verdict** ; la revue tranche. |

Le camp braise et le bassin conducteur sont ajoutés si le coût est faible : deux
autres lieux en modules déjà déclarés `PASS` et gelés. Trois points valent mieux
qu'un.

> **Ce que je m'interdis, et qu'on doit pouvoir me reprocher : choisir la
> calibration APRÈS avoir vu le résultat de la ferme.** C'est pour cela que cet
> engagement est écrit et committé avant la mesure, et non après.

## Décision 11 — la bande de la densité, corrigée par l'audit contre lui-même

L'audit avait annoncé une bande d'incertitude de **1,08 point** et m'avait
demandé, à juste titre, de ne rendre aucun verdict chiffré avant de l'établir.
Double rendu du **même état** :

| grandeur | bande réelle |
|---|---:|
| total | **0,00 pt** |
| couverture | **0,00 pt** |
| **densité** | **0,125 pt** |

Le 1,08 séparait deux **commits**, pas deux rendus. L'écart 69,3 → 45 ne vaut
donc pas 2,2 fois la bande mais **192 fois**.

C'est la deuxième fois de la passe que l'audit démonte son propre instrument
**contre son intérêt** — la première étant le résidu linéaire qu'il venait
d'introduire. **La précondition que j'avais posée est levée** : le verdict chiffré
sur la densité est interprétable.

## Décision 12 — `ferme_facade` passe le liant sans qu'aucun travail ait eu lieu

Mesuré par l'audit : `ferme_facade` est **déjà à 44,1 % de densité au point
zéro**, sous mon seuil de 45. Une vue peut donc passer le liant sans correction.
C'est une réussite vide déguisée, et l'audit a eu raison de la nommer.

Trois décisions, aucune ne touche un seuil :

1. **Le verdict se lit sur les vues où le défaut vit** — `ferme_seuil` (69,3 % au
   départ) et `ferme_laterale`. Une vue déjà sous le seuil au point zéro est
   **publiée avec son point zéro à côté**, jamais comptée comme un gain.
2. **La liste des vues qualifiantes est arrêtée telle que la mesure la produit** :
   `ferme_seuil` (24,07 % de couverture) et `ferme_laterale` (16,71 %). **Deux
   vues, pas six.** C'est peu, et c'est le nombre que la mesure donne ; je ne
   l'élargis pas pour avoir l'air plus complet.
3. **`ferme_arriere`** — 6,25 % de couverture pour **0,00 % d'aplat**, densité 0 :
   publié tel quel avec la phrase de l'audit, « c'est le cadrage qui décide, pas
   une platitude intrinsèque ». Cette vue ne prouve rien, dans un sens ni dans
   l'autre.

## Décision 13 — deux chiffres pour l'arête, et pas de moyenne

L'audit mesure **16,1 %** là où j'annonce **18,3 %** sur l'arête d'arrachement.
Nous ne regroupons pas le même ensemble : lui la famille de 108 triangles × 8,
moi les colonnes du profil sous `plus_haut − 0,30`. Ce n'est pas une
contradiction.

**Les deux vont au rapport avec leur définition, et surtout pas leur moyenne :
un chiffre sans sa définition est une opinion.**
