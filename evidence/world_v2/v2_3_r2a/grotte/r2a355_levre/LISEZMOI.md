# La lèvre du porche — la géométrie LIVRÉE porte le même défaut

**Mesure d'intégrateur, indépendante de l'agent C**, sur la question qui décide
de la passe.

## La question

Le gate de coque à deux seuils place son argmin en `(−2,465 ; −1,798 ; −0,586)`,
soit **0,65 m devant la lèvre du porche** et **0,18 m au-delà de la bouche
dérivée**, et y lit quelques centimètres.

L'instrument précédent portait déjà la phrase juste : *« au REBORD MÊME de la
bouche l'épaisseur tend vers zéro : c'est une arête, pas un défaut »*. Là où peau
intérieure et peau extérieure se rejoignent, leur distance tend vers 0 par
géométrie.

> **La seule question qui tranche : la géométrie LIVRÉE et visuellement validée
> porte-t-elle la même lèvre mince ?** C'est exactement le test qui a disqualifié
> `controle_epaisseur_domaine` comme juge — 326 plaques sur la référence contre
> 167 sur le sujet.

## La réponse

Boîte du porche `x ∈ [−4 ; 4]`, `ay ∈ [−2,6 ; 0,2]`, `z ∈ [−1,5 ; 3]`.
Maillage `SM_WaterfallCave` **seul**, jamais `COL_`.

| | **R2a-3.4 livrée** | candidat corrigé |
|---|---:|---:|
| minimum | **0,3633 m** | 0,2828 m |
| médiane | 1,1305 m | 1,3587 m |
| p90 | 2,2531 m | 2,6909 m |
| sommets sous **0,60 m** | **26** | 52 |
| sommets sous **0,80 m** | **71** | 89 |

**La géométrie livrée porte 71 sommets sous 0,80 m et 26 sous 0,60 m au porche,
avec un minimum de 0,363 m.** Un gate qui exige 0,80 m — ou même 0,60 — en tout
point de cette zone condamne donc la référence, et pas seulement le candidat.

## Ce que cette mesure N'EST PAS, et pourquoi le chiffre diffère de celui du gate

Ce n'est **pas** la métrique du contrat. Elle mesure, par sommet, la distance à
la face non adjacente la plus proche **qui s'oppose en normale et dont le segment
traverse de la roche**. Elle est donc :

- **conservatrice** — un échantillonnage sur l'intérieur des faces trouve des
  points plus minces qu'entre deux sommets ;
- **différente** du gate, qui mesure la distance euclidienne à la peau
  extérieure après classification intérieur/extérieur.

D'où l'écart : le gate lit 0,032 m sur le candidat, cet outil 0,283 m. **Les deux
ne mesurent pas la même chose et ne doivent pas être confondus.** Le fait qu'une
mesure *conservatrice* trouve déjà la référence sous le seuil renforce la
conclusion au lieu de l'affaiblir.

Aucun verdict de contrat ne sort d'ici. Le verdict appartient à l'instrument de
l'agent C, sur la définition du contrat.

## Deux versions invalides sont conservées, et c'est délibéré

| journal | défaut |
|---|---|
| `..._PREMIERE_VERSION_INVALIDE.log` | n'écartait que les faces **incidentes** : mesurait la **longueur d'arête**, pas l'épaisseur. Médiane 0,098 m et **321 sommets sur 321** sous 0,80 m sur la géométrie validée |
| `..._SANS_test_roche_INVALIDE.log` | rangs + opposition, mais **sans** test roche/air : mesurait la largeur des ouvertures comme si c'était une épaisseur |

Deux fautes de ma part, attrapées parce que le chiffre était **invraisemblable
sur une géométrie déjà validée**. C'est le contrôle qui vaut : *une mesure sur
une géométrie saine, dans la même fenêtre, avant de publier un chiffre.*

## Reproduction

```sh
python3 tools/cave_levre_porche.py <a.glb> <b.glb>
# --boite=x0,x1,y0,y1,z0,z1  --anneau=1.5  --pas=0.5  --rangs=3  --opposition=-0.30
```

---

## CORRECTION — « le candidat est meilleur » était partiel, donc trompeur

J'ai écrit, sur la foi du seul **compte** de pénétrations, que le candidat était
meilleur que la référence. L'agent B a mesuré les deux autres grandeurs et m'a
corrigé avant que le chiffre ne serve d'argument :

| grandeur | candidat | R2a-3.4 livrée | meilleur |
|---|---:|---:|---|
| paires, maillage visuel | 6 | 10 | candidat |
| **enfoncement max, visuel** | **0,000612 m** | **0,000000 m** | **R2a-3.4** |
| **couture max, visuel** | **0,570 m** | **0,125 m** | **R2a-3.4** |

Les 10 pénétrations de R2a-3.4 ont un enfoncement **sous le demi-micron** : ce
sont des contacts tangents, pas des pénétrations. Celles du candidat sont **mille
fois plus profondes**, avec des coutures 4,5 fois plus longues.

**Sur les deux grandeurs qui décrivent la sévérité, la référence est meilleure.**
Un comparatif fondé sur le seul compte choisissait sa réponse avant de mesurer —
la même faute que celle qui m'a fait publier une aire de percée trois fois.

## Ce qui ne change pas, et ce qui s'aggrave

**Ne change pas** : les 6 pénétrations du visuel sont toutes 33 fois sous
`REPLI_LIVRABLE_MAX_M = 0,020`. Le contrôle réparé reste vert, honnêtement.

**S'aggrave** : la coque de **collision** du candidat porte **62 pénétrations à
0,457 m d'enfoncement**, contre 7 à 0,020 m pour R2a-3.4. C'est 23 fois le seuil
du visuel, sur la géométrie qui arrête réellement le joueur — et aucun contrôle,
ni l'ancien ni le nouveau, n'a jamais été appelé sur elle.

---

## Le triptyque complet — la lèvre est HÉRITÉE de R2a-3.5.2, et plus mince que la livrée

| | R2a-3.4 **livrée** | `cc3596c5` percé | `c184c8dc` corrigé |
|---|---:|---:|---:|
| minimum | **0,3633 m** | 0,2828 m | 0,2828 m |
| médiane | 1,1305 m | 1,3587 m | 1,3587 m |
| sous 0,60 m | **26** | 52 | 52 |
| sous 0,80 m | **71** | 89 | 89 |
| argmin | `(1,307 ; −0,615 ; 2,789)` | `(1,426 ; −0,100 ; 2,077)` | **identique** |

Deux lectures, et elles ne disent pas la même chose :

**1. Le candidat percé et le candidat corrigé sont IDENTIQUES au porche** — mêmes
comptes, même minimum, même argmin. La calotte nord travaille sur la joue nord,
pas sur le porche : elle n'a donc ni amélioré ni dégradé cette zone, ce qui est
le comportement attendu et le confirme.

**2. Les deux sont plus minces que la géométrie LIVRÉE** — 0,283 contre 0,363 au
minimum, 52 contre 26 sous 0,60, 89 contre 71 sous 0,80. **La lèvre est héritée
de l'enveloppe R2a-3.5.2**, et R2a-3.5.2 l'a amincie par rapport à R2a-3.4.

## Ce que le triptyque établit, et ce qu'il n'établit pas

**Établi** : deux faits distincts qui doivent être tenus ensemble.

- le seuil de 0,80 m **n'est tenu par aucune** des trois géométries au porche, y
  compris la livrée et visuellement validée — un gate qui l'exige partout ne peut
  donc pas passer ;
- **et** le candidat est **mesurablement pire que la référence** sur cette zone.
  Ce second fait est actionnable indépendamment du premier.

**Non établi** : que la lèvre du candidat soit visuellement inacceptable. 0,283 m
de roche à une lèvre de porche peut très bien se lire correctement. **Aucun
instrument ne prononce ce verdict**, et cette mesure n'y prétend pas.

---

## La coque de COLLISION — reproduit par l'intégrateur, et deux corrections de lecture

`tools/cave_localiser_penetrations.py --maillage=COL_WaterfallCave`, `RC=0` sur
les trois.

| géométrie | paires | enfoncement max | où, en `ay` RÉEL |
|---|---:|---:|---|
| R2a-3.4 **livrée** | **7** | **0,020 m** | `+8,37` à `+9,11` |
| `cc3596c5` percé | **62** | **0,457 m** | 32 au porche `−1,15…0`, 28 vers `+2,9…3,1` |
| `c184c8dc` corrigé | **62** | **0,457 m** | **identique à `cc3596c5`, ligne pour ligne** |

### Correction 1 — mon hypothèse du coude est réfutée

J'avais proposé que le coude de 42° de R2a-3.5.2 fabrique les pénétrations. **Il
en porte 2 sur 62, soit 3 %.** Le milieu de la galerie, coude compris, est propre.
Elles sont aux **deux extrémités** du tube.

L'hypothèse de l'agent B est meilleure et non réfutée : la signature est celle
d'un loft dont la **section change trop vite**, pas d'un loft qui vire. Entre les
stations 6 et 8 la demi-largeur chute de 2,50 à 1,30 (−48 %) sur 0,48 m de
progression, et le porche est symétriquement l'endroit où la lèvre s'évase.

### Correction 2 — l'étiquetage par station de R2a-3.4 est un artefact d'écrêtage

L'outil recopie `CAVITE` **du socle**, dont la dernière station est à `ay = 3,17`.
Les pénétrations de R2a-3.4 vivent à `ay = 8,4` à `9,1` : la projection les
**écrête** toutes sur la dernière station et les étiquette « station 8 ».

Le tell est dans les données publiées : **`écart axe` de 5,2 à 5,9 m**. Aucune
pénétration à 5 m de l'axe n'est « à une station ».

La conclusion de l'agent B — *« toutes à la calotte du fond »* — **est juste en
substance** : `ay ≈ 8,4–9,1` est bien le fond de la galerie **de R2a-3.4**, dont
les stations vont jusqu'à 9,25. Mais elle est juste par accident de vocabulaire,
et le comparatif station-par-station entre les deux familles **n'est pas valide** :
les tables diffèrent. **Seules les positions brutes en `ay` se comparent.**

Ainsi lu, le résultat est plus fort : les trois géométries portent leurs
pénétrations **aux extrémités de leur propre tube**, ce qui soutient l'hypothèse
du changement de section rapide — R2a-3.4 comprise, en beaucoup plus bénin.

### Ce que ça vaut

**Attribution certaine** : `cc3596c5` et `c184c8dc` sont identiques ligne pour
ligne. La régression vient **entièrement de l'enveloppe R2a-3.5.2** ; ni cette
passe ni la calotte nord ne l'ont fabriquée.

**Convergence de deux instruments** : le porche concentre à la fois la roche la
plus mince (0,283 m contre 0,363 pour la livrée) et 32 des 62 pénétrations à
0,457 m. Deux mesures indépendantes, deux grandeurs différentes, **la même
région**. Le porche de l'enveloppe R2a-3.5.2 est malformé.

Et personne ne l'avait vu, parce que **aucun contrôle n'a jamais été appelé sur
`COL_WaterfallCave`** — y compris quand R2a-3.5.4 a déclaré la percée fermée et
le portail conforme.

---

## Pourquoi le porche a régressé alors que ses stations n'ont PAS bougé

Le paradoxe méritait d'être levé : les stations 0 (porche) et 1 (seuil) sont
**identiques au chiffre près** entre R2a-3.4 et R2a-3.5.x — le générateur
annote même la seconde « seuil — INCHANGÉ ». Et pourtant le maillage du porche
est plus mince **et** porte 32 auto-intersections que la livrée n'a pas.

**C'est la voisine qui a bougé.**

| révision | segment seuil → station 2 | longueur | virage au seuil |
|---|---|---:|---:|
| R2a-3.4 | `(0,00 ; 0,00) → (0,06 ; 1,60)` | 1,601 m | **2,15°** |
| R2a-3.5.x | `(0,00 ; 0,00) → (0,22 ; 1,05)` | 1,073 m | **11,83°** |

Le segment sortant du seuil est **33 % plus court** et vire **5,5 fois plus**.

Or la section d'une station est orientée par `normale_de_cavite(u)`, qui vaut
`(tangente.y, −tangente.x)` : **l'orientation de la section au seuil dépend de
ses voisines**. Une section de 1,90 m de demi-largeur qu'on fait pivoter de près
de 10° par rapport à sa voisine se cisaille — et un loft cisaillé se replie du
côté intérieur du virage.

**Statut : hypothèse mécanique, non prouvée.** Elle est cohérente avec les deux
mesures indépendantes qui convergent sur le porche, et elle explique pourquoi
figer les stations du porche n'a pas suffi à figer le porche. Elle se réfuterait
en rallongeant le segment sortant sans toucher aux stations 0 et 1.

**Ce qu'elle change pour la suite** : « les stations de la bouche sont
inchangées » ne garantit **pas** que la bouche est inchangée. L'addendum du
masque s'appuie sur cette stabilité de stations — elle reste vraie pour le
*chemin*, elle est fausse pour la *géométrie*. Le masque, lui, ne dépend que du
chemin, donc il tient ; mais la phrase « R2a-3.5.2 n'a pas touché la bouche »
doit se lire « n'a pas touché ses stations », et rien de plus.

---

## LA PREUVE — au rebord, il n'y a pas d'épaisseur, il y a un BORD

Reproduit par l'intégrateur, `RC=0`, sur les deux géométries. `h` visé divisé
par 8 :

| `h` | R2a-3.4 **livrée** | `lect./h` | `c184c8dc` | `lect./h` |
|---:|---:|---:|---:|---:|
| 0,400 | 0,00400 | **0,010** | 0,00800 | **0,020** |
| 0,200 | 0,00200 | **0,010** | 0,00400 | **0,020** |
| 0,100 | 0,00100 | **0,010** | 0,00200 | **0,020** |
| 0,050 | 0,00050 | **0,010** | 0,00100 | **0,020** |

**Le rapport `lecture / h` est exactement constant.** La lecture ne converge pas
vers une valeur finie : elle **suit la résolution**. C'est la signature
mathématique d'une **arête** — au contour de bouche la peau intérieure rejoint la
peau extérieure, et un échantillon posé à `r` du contour lit `r`.

> **Il n'y a pas d'épaisseur à mesurer là. Il y a un bord.**

Ce n'est donc pas un résultat sur ces deux géométries : c'est un résultat sur
**toute grotte pourvue d'une bouche**. Aucun seuil strictement positif ne peut y
être tenu, si soignée que soit la sculpture.

Et la géométrie **livrée et visuellement validée est la plus mince des deux** —
0,0005 contre 0,0010 m à `h = 0,05`. Le critère la condamne plus fort que le
sujet, exactement comme `controle_epaisseur_domaine` avec ses 326 plaques.

### Deux faits distincts, qui ne se contredisent pas

Mon outil de lèvre et celui de l'agent C ne mesurent pas au même endroit, et
c'est pour cela qu'ils ordonnent les géométries différemment :

| | mesure | R2a-3.4 | candidat | qui est le plus mince |
|---|---|---:|---:|---|
| **AU rebord** | échantillons jusqu'au contour | 0,0005 m | 0,0010 m | **la référence** |
| **PRÈS du rebord** | sommets, 3 rangs exclus, test roche | 0,363 m | 0,283 m | **le candidat** |

- **Au rebord** : les deux tendent vers 0. C'est de la géométrie, pas un défaut,
  et la référence a l'arête la plus vive.
- **Près du rebord** : la roche du porche du candidat est réellement plus mince —
  89 sommets sous 0,80 m contre 71, minimum 0,283 contre 0,363.

Le premier fait rend le gate inatteignable. Le second reste une **régression
réelle du candidat**, actionnable indépendamment.

---

## DEUX CORRECTIONS APRÈS LE RAPPORT FINAL DE L'AGENT A

### 1. Ma réserve sur le périmètre de bouche est RÉFUTÉE

J'avais arrêté l'agent A sur un périmètre de 53,755 m, invraisemblable contre les
~10,6 m d'une ouverture de 3,8 × 2,9 m, et conclu que sa lecture était
« probablement optimiste ». **Elle ne l'est pas**, et les données le montrent :

| | pas 0,050 | pas 0,250 |
|---|---:|---:|
| arêtes coupées | 533 | 175 |
| **bordant la peau INTÉRIEURE** | **99** | **99** |
| → **faces de départ du front** | **56** | **56** |
| bordant la peau extérieure seule | 434 | 76 — **ignorées** |
| emprise des faces de départ | **3,96 × 3,01 m** | **3,96 × 3,01 m** |

Le front géodésique ne part que des faces `dedans`. Les deux exécutions publient
des tables **identiques au point près** — 86 020 échantillons, 0,6613 m, même
argmin. Les trois chiffres viennent du **même outil**, `cave_check_hull.py`, et ne
diffèrent que par `--pas-balayage` ; le troisième (13,879 m) porte sur R2a-3.4,
une autre géométrie.

**Ce qui reste vrai** : le champ publié s'appelle « périmètre de la bouche » et
publie le **contour de coupe complet**. C'est un défaut d'étiquette, pas de
mesure — et il m'a coûté un aller-retour. **Ticket.**

La cause est réelle et vaut d'être notée : les deux barrières enferment
*exactement* 95,19 m², donc le critère « la plus extérieure des valides » est
**dégénéré**, et un pas fin élit un plan qui coupe le massif entier.

### 2. Le tableau d'ensemble était trop sombre

La correction de calotte a mieux marché que ce que j'ai rapporté :

| | avant | après |
|---|---:|---:|
| lecture / borne | 0,6613 / 0,5613 | 0,6813 / 0,5813 |
| argmin | `(1,036 ; 5,173 ; 2,316)` | `(3,039 ; 1,920 ; 1,704)` |
| **direction** | **97,1 % verticale** | **98,2 % horizontale** |
| **échantillons sous 0,80 m** | 2 216 | **1 122** — **−49,4 %** |
| **points sous 0,60 m** | — | **0** |

**Au point visé** : certificat local `h = 0,05`, rayon 0,30 m → lecture
**1,1777 m**, borne **1,1277 m**, zéro point sous seuil. La cible de la passe —
mesure centrale ≥ 0,90, borne ≥ 0,85 — est **dépassée**.

**Et la distribution est groupée** : 5 amas → 3, le plus gros à 67,8 %, **97 %
des points restants entre 0,70 et 0,80 m**. Ce n'est donc pas une coque mince
partout : c'est une **bande étroite sous le seuil**, bornée et localisée.

L'argmin a changé de **nature** : le défaut corrigé était zénithal, du ressort de
la calotte ; le suivant est **latéral sur la joue droite**, que la calotte ne
couvre pas par construction (azimuts 100→176°, côté `−n`). Le même levier ne s'y
applique pas.

**Non-régression** : genre 0 conservé, 0 bord libre, 0 non-manifold, composition
3/3/3, ratios 2,16 / **2,37** / 2,25 — le ratio central *monte* (2,33 avant),
domaine 29 → 28 plaques, connexité 5 composantes avant et après, les mêmes,
aucune bulle nouvelle.

### Ce que ça change pour la décision du lead

Le seuil de 0,80 m reste hors de portée **au rebord**, et c'est structurel. Mais
hors rebord, l'écart restant est **1 122 échantillons dans une bande de 0,70 à
0,80 m, en trois amas**, sans aucun point sous 0,60. **C'est un problème borné,
pas systémique** — et il serait entièrement conforme à un seuil de collerette de
0,60 m.
