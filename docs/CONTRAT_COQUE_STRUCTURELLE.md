# Contrat de coque structurelle — grotte de la cascade

**Type de document : VIVANT.** Il fait autorité sur ce que « épaisseur ≥ 0,80 m »
veut dire pour la grotte, et sur rien d'autre.

**Écrit le 2026-08-16, AVANT toute correction géométrique de la passe R2a-3.5.4,
et committé avant elle.** C'est la raison d'être de ce fichier : un domaine de
mesure choisi **après** avoir vu le résultat n'est pas un contrat, c'est une
justification. Le SHA de ce commit précède le SHA de la correction, et cela se
vérifie dans Git.

---

## 0. Pourquoi ce document existe

`EPAISSEUR_MIN_M = 0,80` existe depuis longtemps. Ce qu'il **mesure** n'a jamais
été écrit, et trois passes successives ont buté sur cette ambiguïté :

- `controle_epaisseur` du générateur ne balayait que les stations de `CAVITE`,
  **dont la dernière est à `ay = 3,17`**. Il publiait 0,87 m et passait, pendant
  qu'une percée de 85,8 cm² vivait à `ay ≈ 5,9`. Il n'avait pas tort : il ne
  regardait pas là ;
- le balayage vertical du massif entier, introduit en R2a-3.5.3, voit tout — mais
  il compte comme « plaque » de la roche qui n'est pas la coque de la cavité, et
  il rend **326 plaques sur la géométrie R2a-3.4 déjà validée visuellement**
  contre 167 sur le candidat. Un critère qui condamne plus fort la référence que
  le sujet ne peut pas décider seul ;
- deux instruments de collerette étaient biaisés **en sens contraires**, ce qui
  faisait de leur « convergence à quatre décimales » une coïncidence.

Le seuil n'est pas en cause. **Le domaine l'était.**

---

## 1. Le seuil ne bouge pas

```
EPAISSEUR_MIN_M = 0.80
```

Inchangé, non négociable, et ce document ne l'assouplit pas. Il dit **où** il
s'applique.

---

## 2. Définition de la coque structurelle

En six étapes, toutes reproductibles, dans cet ordre.

### 2.1 Sceller virtuellement la bouche canonique

Une barrière de **surface d'épaisseur nulle**, jamais une tranche pleine de
cellules : une tranche épaisse ampute la cavité au lieu de la fermer, et c'est
exactement le défaut `C4` observé en R2a-3.5.3.

La barrière est **dérivée** — position obtenue par balayage du profil
d'étanchéité, publiée avec ce balayage — et non déclarée en constante. Elle ne
partage aucune logique avec le verdict qu'elle sert.

### 2.2 Identifier la composante d'air intérieure

Inondation depuis une graine, sur un maillage dont la fermeture est **prouvée**
(0 bord libre, 0 arête non-manifold, 0 sommet pincé) avant toute inondation.

### 2.3 Vérifier que les deux repères de gameplay sont dans cet air

`MODELE_SALLE` **et** `MODELE_NICHE` doivent appartenir à la composante trouvée.

**Si l'un des deux tombe dans la roche, le contrôle sort en `BLOQUÉ`, jamais en
vert.** Une graine dans la roche rendrait « étanche » sans rien prouver. Et les
repères ayant été re-dérivés à R2a-3.5.2, une géométrie antérieure doit être
semée avec **ses** repères — sinon le refus est légitime et il faut le lire comme
tel, pas le contourner.

### 2.4 La coque, c'est ce qui sépare cet air du dehors

**Coque structurelle** = l'ensemble des surfaces rocheuses séparant la composante
d'air intérieure de la composante d'air extérieure.

Cette définition ne mentionne **ni station, ni `ay`, ni distance à un axe**. Elle
est topologique. C'est délibéré : toute borne exprimée en station reproduirait le
défaut qu'on répare.

> **Aucun point de la coque ne peut être écarté au motif qu'il se trouve au-delà
> de la dernière station de `CAVITE`.** C'est la clause qui rend ce contrat
> différent du précédent.

### 2.5 Exclusion unique

**Seule** la bouche canonique, explicitement masquée, est exclue. Le masque est
archivé avec la mesure : son emprise, sa position dérivée, et le balayage qui l'a
produite. Rien d'autre n'est exclu — ni le porche, ni la visière, ni l'orteil, ni
la calotte, ni une zone « décorative ».

### 2.6 Mesure de l'épaisseur

Au point `p` de la surface intérieure, l'épaisseur est la **distance euclidienne
de `p` à la surface extérieure la plus proche**.

Ce choix est motivé, pas esthétique :

- il **ne dépend d'aucune convention de direction**. Mesurer « selon la normale »
  a déjà produit une erreur mesurée : un jambage incliné de 36° offre 0,70 m à
  l'horizontale et **0,566 m** perpendiculairement. *La largeur horizontale n'est
  pas l'épaisseur* ;
- il est **minorant** : la distance euclidienne est inférieure ou égale à
  l'épaisseur selon n'importe quelle direction. Un vert obtenu ainsi est donc
  vrai pour toutes les directions ;
- calculé sur grille, il **sous-estime encore**, d'un montant borné par le pas.
  Mesuré en R2a-3.5.3 : l'EDT sous-lit de −0,76 à −1,12 × pas. **Sa lecture brute
  est déjà une borne inférieure**, et c'est la borne qu'on publie.

**Ce qui est publié :** la lecture brute **et** la borne garantie `lecture − pas`.
Le gate se prononce sur la **borne garantie**, jamais sur la lecture optimiste.

Une mesure selon la normale locale peut être publiée **en regard**, comme
seconde opinion. Elle ne remplace pas la borne.

---

## 3. Le contrôle négatif, sans lequel ce contrat ne vaut rien

Un contrôle qui n'a jamais rougi n'est pas un contrôle.

**Exigence** : amincir localement la coque sous 0,80 m, **en conservant le
maillage fermé et manifold** — par déplacement déterministe de sommets, jamais
par ablation de triangles, qui ouvre le maillage et rend toute lecture
indéfinie.

Séquence obligatoire, dans cet ordre :

1. prouver la fermeture **avant** : 0 bord libre, 0 non-manifold, 0 sommet pincé ;
2. prouver par une **mesure indépendante** que l'épaisseur a réellement baissé à
   l'endroit visé — pas la mesure éprouvée, une autre ;
3. obtenir **ROUGE** ;
4. restaurer **byte-identique**, empreintes publiées des deux côtés ;
5. obtenir **VERT**.

Un rouge obtenu pour une autre cause que celle annoncée ne compte pas.

---

## 4. Ce que le balayage vertical devient

Il est **conservé**, et il n'est **plus** le gate.

Il publie, sur chacune des géométries comparées : nombre de plaques · bords ·
membranes internes · bulles isolées · minimum vertical · et le comparatif
R2a-3.4 / `BASE352` / `cc3596c5` / candidat corrigé.

**Statut : télémétrie de non-régression.** Il sert à voir si un défaut *migre*
plutôt qu'il ne disparaît — question que la mesure de coque, ponctuelle par
nature, ne pose pas d'elle-même.

Ce déclassement n'est pas un assouplissement : la coque est mesurée par une
**borne minorante** sur **tout** ce qui sépare l'air jouable du dehors, station ou
pas. C'est plus exigeant sur ce qui compte, et muet sur ce qui n'est pas une
coque.

---

## 5. Les deux gates, et ils sont durs tous les deux

| gate | énoncé | verdict |
|---|---|---|
| **topologique** | zéro communication entre l'air intérieur canonique et l'extérieur, hors bouche masquée | dur |
| **épaisseur** | borne garantie ≥ **0,80 m** en tout point de la coque structurelle | dur |

Le gate topologique passe **en premier** : mesurer l'épaisseur d'une coque
trouée n'a pas de sens, puisqu'il n'y a pas de séparation à mesurer.

Résolution du portail d'étanchéité : **0,06 m au maximum**, avec raffinement
adaptatif jusqu'à **0,005 m** autour de toute anomalie ou couture. Justification
mesurée : le même oracle rend **VERT au pas de 0,10 m** et **ROUGE à 0,06** sur la
même géométrie. Un portail dont le pas dépasse la taille du défaut ne dit rien.

Le contrôle historique sur les stations **reste actif** — il n'est ni retiré ni
affaibli, il cesse simplement d'être la seule chose qui regarde.

---

## 6. Ce que ce contrat n'établit pas

- **Rien de visuel.** Une coque conforme peut être laide, et une percée peut être
  invisible depuis le trajet du joueur. Le verdict artistique n'appartient à
  aucun instrument.
- **Rien sur le gabarit ni la praticabilité.** « Séparé du dehors » n'est pas
  « parcourable ».
- **Rien en dessous du pas de grille.** Une communication plus fine que 5 mm
  resterait invisible à l'inondation. Le **genre topologique**, lui, la verrait —
  il détecte une anse de n'importe quelle largeur, mais ne la localise pas. Les
  deux sont donc appariés, et leurs journaux restent **séparés**.

---

## 7. Historique

| date | événement |
|---|---|
| 2026-08-16 | rédigé et committé **avant** la correction géométrique de R2a-3.5.4, sur arbitrage du lead |
