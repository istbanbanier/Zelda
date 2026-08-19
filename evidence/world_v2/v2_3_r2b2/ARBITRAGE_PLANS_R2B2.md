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
aurait fait monter le chiffre*. En R2B.1, cinq murs présentaient leur face
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
