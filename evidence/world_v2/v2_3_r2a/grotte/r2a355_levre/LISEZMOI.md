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
