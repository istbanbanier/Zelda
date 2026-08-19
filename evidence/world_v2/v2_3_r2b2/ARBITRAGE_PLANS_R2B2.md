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
