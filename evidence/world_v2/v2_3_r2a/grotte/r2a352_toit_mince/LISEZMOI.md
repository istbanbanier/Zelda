# Le toit du massif tombe à 3,8 cm au-dessus d'un vide de 1,4 m — ARRÊT

**Ce dossier arrête la passe R2a-3.5.2.** L'item de gate « paroi ≥ 0,80 m » n'est
pas tenu par le candidat, et le contrôle qui l'annonce tenu ne regarde pas
l'endroit où il est violé.

Signalé par l'agent instruments comme un fait brut, **reproduit et cartographié
par l'intégrateur**.

## La mesure

Rayon vertical depuis le ciel, épaisseur de la **première** roche rencontrée
au-dessus d'un vide d'au moins 1,00 m de hauteur. Balayage `x ∈ [−2 ; 3]`,
`y ∈ [4 ; 7]`, pas 0,10 m.

| géométrie | toit minimal | où |
|---|---:|---|
| **candidat `cc3596c5`** | **0,038 m** | `(0,50 ; 5,80)` |
| **BASE352 `8bc8b9f9`** | **0,038 m** | identique |
| tronc **R2a-3.4 livré** `8bf1a1b3` | **0,374 m** | `(0,80 ; 6,00)` |

Seuil contractuel : **`EPAISSEUR_MIN_M = 0,80 m`**.

Deux conclusions, et elles ne disent pas la même chose :

1. **le défaut n'est pas l'œuvre du lot collerette** — identique sur `BASE352`,
   donc hérité de l'enveloppe R2a-3.5.2 ;
2. **c'est une régression d'un facteur dix contre la géométrie livrée.**

## Ce n'est pas un artefact de rayon rasant

Un artefact numérique serait erratique. Épaisseur du toit, en mètres :

```
   y  |  x=0.30   0.40   0.50   0.58   0.66   0.75   0.90
  5.40 |  0.540  0.580  0.566  0.532  0.479  0.392  0.250
  5.60 |  0.276  0.254  0.305  0.406  0.470  0.446  0.400
  5.70 |  0.244  0.160  0.145  0.293  0.412  0.529  1.333
  5.80 |  0.267  0.138  0.038  0.054  0.503  1.115  1.481
  5.90 |  0.266  0.137  0.058  1.428  0.692  1.617  1.599
  6.00 |  0.274  0.145  0.076  0.053  1.033  1.703  1.695
  6.20 |  0.419  0.393  1.443  1.502  1.637  1.805  1.830
```

C'est une **arête de roche continue**, une trentaine de centimètres de large sur
une soixantaine de long, dont l'épaisseur varie régulièrement de 0,58 m à 0,038 m
puis remonte. Une lame de rocher au-dessus d'une salle.

Sous elle, le vide fait **1,36 à 1,47 m de haut** — une cavité, pas une fissure de
décimation.

## Pourquoi aucun contrôle ne l'a vu

`controle_epaisseur` publie **0,87 m** et passe. Il n'a pas tort : il mesure
**là où il regarde**, et il ne regarde que les stations de `CAVITE`, dont la
dernière est à `ay = 3,17`.

**Le défaut est à `ay ≈ 5,8`, soit 2,6 m au-delà de la dernière station.** Hors
domaine. Aucun instrument ancré sur les stations ne peut y entrer — c'est le
troisième des faits bruts que l'agent instruments a publiés, et il est exact :

> « Du vide connecté à la galerie court jusqu'à `y ≈ 7,0` alors que `CAVITE`
> s'arrête à `ay = 3,17`. Ce n'est pas une couverture insuffisante, c'est **hors
> domaine**. »

Le balayage à `x = 0,58` le confirme : le vide court de `y = 3,0` à `y = 6,5`,
avec un toit qui passe de 4,22 m à 0,054 m puis remonte à 2,08 m.

## Ce que l'intégrateur n'a PAS pu établir

> ### CORRECTION — 2026-08-16, passe R2a-3.5.3
>
> **Le paragraphe ci-dessous nomme une cause qui est fausse, et il est conservé
> tel quel plutôt qu'effacé.** Mesure refaite, lecteur GLB indépendant, sommets
> soudés par position : **0 bord libre** sur le candidat, sur `BASE352` et sur
> R2a-3.4. **Le maillage est fermé. Il n'est pas ouvert par le dessous.**
>
> Le fait observé reste vrai — les deux inondations atteignent le bord de la
> grille — mais elles ne sortent pas par un dessous qui n'existe pas.
>
> Le verdict d'épaisseur n'en dépendait pas : `EPAISSEUR_MIN_M` porte sur la
> roche, pas sur l'accès. Ce qui change, c'est que la mauvaise cause servait
> d'excuse à l'indétermination : le maillage étant fermé, **la question redevient
> décidable**. Détail et suites : `docs/CODEX_HANDOFF.md` §0ter, C4 et C5.

**La joignabilité par le joueur reste indéterminée.** Deux inondations 3D lancées
depuis la galerie, l'une sans bouchon, l'autre avec la dalle de bouche entière
bouchée, **atteignent toutes deux le bord de la grille** : elles s'échappent par
le **dessous ouvert du modèle**, qui est ouvert par conception — un rocher planté
dans le terrain. Une coulée qui sort n'établit aucune connexité intérieure.

C'est exactement la panne que l'agent instruments décrit pour son propre oracle,
et je la reproduis indépendamment plutôt que de la lui prendre sur parole.

**Mais cela ne change pas le verdict** : le contrat `EPAISSEUR_MIN_M` porte sur
l'épaisseur de la roche, pas sur la joignabilité. Trois centimètres et demi de
roche au-dessus d'une salle de 1,4 m échouent, que le joueur puisse y entrer ou
non — et une lame de 3,8 cm est à une décimation d'être un trou.

## Statut

`FAIL` mesuré sur un item indivisible du gate §10. La passe s'arrête ici.
Aucune géométrie n'est intégrée, aucun seuil n'est abaissé, et le tronc continue
de porter la géométrie R2a-3.4.

Reproduction : voir `mesures.txt`.
