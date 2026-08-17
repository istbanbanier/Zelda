# Addendum d'interprétation — le masque de bouche, rendu exécutable

**Type de document : VIVANT.** Il complète `docs/CONTRAT_COQUE_STRUCTURELLE.md`
et ne fait autorité que sur un point : **comment le masque de bouche de son §2.5
se calcule**, et comment la roche se classe entre collerette et coque.

**Écrit le 2026-08-16, AVANT toute nouvelle géométrie de la passe R2a-3.5.5, et
committé avant elle.** Même raison d'être que le contrat qu'il complète : un
domaine choisi *après* avoir vu le résultat n'est pas un contrat.

Le contrat lui-même reste **gelé au commit `cca1778`**. Cet addendum n'en change
ni la définition, ni le domaine, ni un seuil, ni un verdict. Il **instancie** une
clause que le contrat avait laissée sans emprise, sur arbitrage du lead du
2026-08-16.

---

## 0. Le trou que cet addendum bouche

Le contrat §2.5 dit :

> *Seule la bouche canonique, explicitement masquée, est exclue.*

Il ne dit **pas** quelle emprise. Le gate d'épaisseur de R2a-3.5.4 a donc dû
publier la courbe entière plutôt que trancher, et le verdict — `FAIL` dans tous
les cas — s'accompagnait de deux causes incompatibles selon l'emprise retenue :

| emprise géodésique | lecture | argmin |
|---:|---:|---|
| 0,00 – 1,50 m | 0,0216 → 0,0565 m | `ay ≈ −1,11`, collé au rebord du porche |
| 2,00 / 3,00 m | 0,6613 m | `(1,036 ; 5,173 ; 2,316)` |

Un instrument qui ne sait pas dire *où* est le défaut ne sert pas à le réparer.

### 0.1 Le changement de nature, et il durcit le gate

L'arbitrage du lead ne se contente pas de fixer une emprise. Il change ce que le
masque **fait** :

| | avant | après |
|---|---|---|
| rôle du masque | **exclure** une zone de la mesure | **classer** cette zone à un seuil plus bas |
| zone de bouche | non mesurée | mesurée, seuil **0,60 m** |
| reste | 0,80 m | 0,80 m |
| surface exemptée | l'emprise du masque | **aucune** |

**Plus rien n'est exempté.** C'est strictement plus exigeant que la version
précédente, et c'est le point important de cet addendum : ce n'est pas un
assouplissement déguisé en clarification.

---

## 1. Ce sur quoi le masque s'appuie, et pourquoi ces ancrages-là

Le lead impose de dériver le masque **« à partir des repères et de l'ancre
canonique de R2a-3.4, pas depuis une géométrie corrective »**. Cette instruction
n'est exécutable que si les grandeurs nécessaires existent en R2a-3.4 **et** n'y
ont pas divergé. Vérifié, une par une :

| grandeur | ancrage | R2a-3.4 (tronc) | R2a-3.5.x (base) | verdict |
|---|---|---|---|---|
| `MODELE_SEUIL_DEHORS` | `scripts/world_v2/poi/waterfall_cave_place.gd` | `(0.0, 0.10, 1.60)` | **identique** | utilisable |
| `SEUIL_LOCAL` | idem | `Vector2(4.0, -2.5)` | **identique** | utilisable |
| `LACET_DEG` | idem | `45.0` | **identique** | utilisable |
| `EXHAUSSEMENT` | idem | `0.50` | **identique** | utilisable |
| `CAVITE` station 0 — porche | `source_assets/blender/environment/make_waterfall_cave.py` | `(0.00, -1.15, 1.90, 2.80)` | **identique** | utilisable |
| `CAVITE` station 1 — seuil | idem | `(0.00, 0.00, 1.70, 2.85)` | **identique**, annotée « seuil — INCHANGÉ » | utilisable |
| `MODELE_SALLE` | `waterfall_cave_place.gd` | `(1.05, 0.22, -6.25)` | `(2.62, 0.09, -2.58)` | **DIVERGENT — interdit ici** |
| `MODELE_NICHE` | idem | `(-1.20, 0.43, -8.20)` | `(2.78, 0.50, -4.09)` | **DIVERGENT — interdit ici** |

**Le masque n'emploie que la colonne « identique ».** C'est ce qui rend
l'instruction du lead cohérente : R2a-3.5.2 a raccourci et coudé la galerie —
salle de `ay = 6,25` à `ay = 2,58`, dernière station de `9,25` à `3,17` — mais
**n'a pas touché la bouche**. Les deux premières stations sont les mêmes, et le
repère extérieur du seuil n'a jamais bougé.

Si le masque avait eu besoin de `MODELE_SALLE`, l'instruction aurait été
contradictoire, et cet addendum aurait dû s'arrêter en `BLOQUÉ`. Ce n'est pas le
cas, et il fallait le vérifier avant de l'affirmer.

### 1.1 Le plan de bouche hérité `y = −1,15` n'est PAS employé

Constat de provenance, à consigner parce qu'il touche cinq outils :

- `−1,15` est une **constante héritée** (`Y_BOUCHE_DEFAUT`), recopiée telle
  quelle dans `cave_oracle_global.py`, `cave_collar.py`, `cave_voxel_oracle.py`
  et deux autres. Le `−1,155` des journaux n'en est que l'arrondi à la grille de
  0,06 m ;
- `tools/cave_oracle_bouche.py`, qui **dérive** la bouche sans jamais inonder en
  3D, rend `y = −1,7348` — **0,58 m plus en avant** ;
- le contrat §2.1 exige une barrière **dérivée**, « qui ne partage aucune logique
  avec le verdict qu'elle sert ». Une constante recopiée cinq fois n'est pas une
  dérivation.

**Le masque ne dépend d'aucun de ces deux plans.** Son extrémité extérieure est
`MODELE_SEUIL_DEHORS`, un repère de gameplay canonique, stable, et versionné —
qui se trouve d'ailleurs *entre* les deux (`ay = −1,60`). L'écart `−1,15` contre
`−1,7348` reste un **ticket ouvert**, pas un préalable à cette passe.

---

## 2. Définition exécutable du masque

En cinq étapes, dans cet ordre, toutes reproductibles.

### 2.1 Le chemin

Le chemin canonique est la **polyligne des stations de `CAVITE`**, interpolée par
`station_de_cavite(u)`, avec `u` indice de station éventuellement fractionnaire.
La normale latérale est `normale_de_cavite(u)`, **jamais l'axe X** : le générateur
documente lui-même que décaler le long de X devient faux dès que la galerie
s'infléchit.

L'asymétrie gauche/droite `CAVITE_ASYM` **est appliquée**. Au seuil elle vaut
`0,81` à droite et `1,30` à gauche : une section symétrique y serait fausse des
deux côtés à la fois.

### 2.2 La section balayée

La section est le **gabarit de passage déjà contractuel** :

```
GABARIT_DEMI_LARGEUR_M = 0.95        # demi-largeur libre exigée
GABARIT_CLE_M          = 2.05        # hauteur de clé libre exigée
```

C'est ce que le lead nomme « les marges de passage déjà contractuelles ». Ces
deux constantes existent, sont gelées, et ont un consommateur unique et lisible
(`controle_gabarit()`).

**La capsule brute n'est pas retenue comme gate**, pour une raison mesurée : le
générateur la déclare `r = 0,45 m, h = 1,85 m` dans le commentaire de
`GABARIT_DEMI_LARGEUR_M`, alors que la capsule réelle de
`scenes/player/Player.tscn` est `r = 0,35 m, h = 1,80 m`, et que le système de
grottes V1 en déclare une troisième à `h = 1,70 m`. **Trois valeurs, aucune
arbitrée.** Un gate ne se fonde pas sur une grandeur en litige ; un gabarit gelé,
oui. Le commentaire périmé du générateur est un **ticket**, pas un préalable.

> **Obligation de publication.** Le masque au gabarit **et** le masque à la
> capsule réelle (`0,35 / 1,80`) sont mesurés et publiés **tous les deux**, avec
> leurs argmins. Le gate porte sur le gabarit. Si les deux ne rendent pas le même
> verdict, le résultat est **`BLOQUÉ`** et remonte au lead : cela signifierait
> que la conformité dépend d'une constante en litige.

### 2.3 L'abscisse est une LONGUEUR, jamais un indice de station

Point de méthode, et il a déjà coûté quatorze occurrences à ce projet.

`u`, dans `station_de_cavite(u)`, est un **indice de station éventuellement
fractionnaire** — pas une distance. Or les tables `CAVITE` de R2a-3.4 et de
R2a-3.5.x **n'ont pas les mêmes stations** : `u = 2` désigne `ay = 1,60` dans
l'une et `ay = 1,05` dans l'autre. Comparer, écrêter ou geler une emprise
exprimée en `u` reviendrait à comparer un paramètre de courbe à une coordonnée.

> **Toute emprise de masque s'exprime en `s`, longueur d'arc en mètres mesurée le
> long du chemin depuis la station « seuil », qui est identique dans les deux
> révisions et vaut donc origine commune.** `s` est négatif vers l'extérieur.
> Les conversions `s ↔ u` se font sur le chemin de la géométrie concernée, jamais
> entre géométries.

### 2.4 L'extrémité extérieure

`s_dehors` = abscisse curviligne de `MODELE_SEUIL_DEHORS` projeté sur le chemin.

En repère modèle Blender, `MODELE_SEUIL_DEHORS` vaut `(0.00 ; −1.60 ; 0.10)` —
soit **0,45 m devant la lèvre du porche** (`ay = −1,15`), donc `s_dehors ≈ −1,60`
le porche étant rectiligne en `ax = 0`. C'est littéralement « l'extérieur immédiat
du seuil ». La valeur exacte est **mesurée et publiée**, pas recopiée d'ici.

### 2.5 L'extrémité intérieure — « la première section entièrement enfermée »

**Cette expression n'a aucune définition dans le dépôt.** Trois lectures
incompatibles y coexistaient. Elle est donc définie ici, avant toute mesure :

> **Une section à l'abscisse `s` est ENTIÈREMENT ENFERMÉE si, depuis le contour du
> gabarit à cette abscisse, `N ≥ 72` rayons répartis uniformément dans le plan de
> la section (pas de 5°) rencontrent tous de la roche avant de sortir de la boîte
> englobante du modèle.**
>
> `s_enclos` est le **plus petit** `s > s_dehors` vérifiant cette propriété, et la
> vérifiant encore à `s + 0,25 m` — une section isolément fermée sous une nervure
> ne suffit pas.

Trois précisions qui font toute la différence :

1. **`s_enclos` est calculé sur la géométrie CANONIQUE R2a-3.4** — le GLB
   `8bf1a1b3`, présent au tronc en permanence. Pas sur la géométrie mesurée. Une
   emprise qui s'adapterait à la géométrie sous test serait exactement le
   « domaine choisi après avoir vu le résultat » que le lead interdit.
2. **Écrêtage conservateur, en mètres.**
   `s_final = min(s_enclos_canonique, s_enclos_sous_test)`. Un masque **plus
   long** est plus **permissif** — il place davantage de roche au seuil bas de
   0,60 m. On prend donc toujours le plus court des deux. Une géométrie ne peut
   pas s'octroyer un masque plus généreux en se modifiant.
3. **Aucune salle, aucune niche, aucune alcôve.** Sur la géométrie R2a-3.5.x, la
   salle est à `ay = 2,58` et la niche à `4,09`, très au-delà de toute valeur
   plausible de `s_final`. L'exclusion demandée par le lead est donc structurelle,
   pas déclarative — mais elle est **vérifiée et publiée** à chaque mesure, et un
   `s_final` qui atteindrait la salle rend **`BLOQUÉ`**.

### 2.6 Le volume

`MASQUE` = union des sections balayées pour `s ∈ [s_dehors ; s_final]`, pas de
balayage `≤ 0,06 m`, raffiné à `0,005 m` près des extrémités. Le volume est publié
en coordonnées **modèle**, jamais en indices de station.

---

## 2bis. LOI DE REBORD PROGRESSIVE — remplace les deux seuils du §3

**Écrit le 2026-08-17, sur arbitrage du lead (directive R2a-3.5.6 §1), AVANT
toute mesure sous cette loi.** Même discipline que le reste de ce document : la
loi est posée avant d'être éprouvée, pour qu'un `FAIL` ne puisse pas la faire
bouger.

### 2bis.1 Ce que la mesure de R2a-3.5.5 a établi, et qui force ce changement

Le rapport `lecture / h` est **exactement constant** — 0,010 sur R2a-3.4, 0,020
sur le candidat, `h` variant d'un facteur 8. La lecture **suit la résolution** au
lieu de converger : au contour de bouche la peau intérieure rejoint la peau
extérieure, et un échantillon posé à `r` du contour lit `r`.

**Il est donc géométriquement impossible d'imposer une épaisseur strictement
positive exactement sur l'arête ouverte d'une bouche.** Ce n'est pas un défaut de
géométrie, c'est une propriété de toute surface ouverte.

### 2bis.2 La loi — et ce n'est PAS une bande exclue

Le lead **refuse** une bande simplement retirée des contrôles. Soit :

- `Γ` : le contour canonique de la bouche ;
- `d(p)` : distance **géodésique** de `p`, sur la peau intérieure, à `Γ` ;
- `e_garantie(p)` : la borne inférieure qualifiée de l'épaisseur.

```
e_requise(p) = min( d(p) , 0,80 m )
```

| `d(p)` | exigence |
|---|---|
| `0` | le gate porte sur la **continuité et la topologie** du rebord |
| `0,60 m` | au moins **0,60 m** garantis |
| entre `0,60` et `0,80` | l'exigence **croît** jusqu'à 0,80 |
| `≥ 0,80 m` | au moins **0,80 m** garantis |

**Aucun point n'est ignoré.** Le rebord reçoit une loi adaptée à une surface
ouverte ; il ne sort pas du domaine.

### 2bis.3 Trois clauses qui empêchent la loi de devenir molle

1. **Le gate porte sur la borne conservatrice**, jamais sur la mesure centrale,
   jamais sur une moyenne. **Aucun percentile ne peut masquer un point rouge.**
2. **Le seuil général reste 0,80 m** au-delà des 0,80 premiers mètres
   géodésiques. Le constat de R2a-3.5.5 — *« hors rebord, tout serait conforme à
   0,60 m »* — **ne vaut donc aucune validation** : 0,60 n'est pas un seuil
   général, c'est une valeur de la rampe.
3. **Contrôle négatif obligatoire** : une lèvre réellement trop aiguë doit
   **rougir**, même si la topologie reste fermée. Une loi qui ne rougit sur
   aucune lèvre n'est pas une loi, c'est une exemption déguisée.

### 2bis.4 Validation analytique exigée avant tout usage

La loi se valide sur des **fixtures analytiques** — coques ouvertes et rebords
inclinés à **15°, 36°, 45° et 70°**, à plusieurs résolutions — avant d'être
appliquée à une géométrie de production. Une loi éprouvée seulement sur le sujet
qu'elle doit juger ne prouve rien.

### 2bis.5 Ce que cette loi remplace

Elle **remplace** la classification binaire du §3 ci-dessous (collerette 0,60 /
coque 0,80). Le §3 est conservé pour l'histoire — il documente pourquoi la
classification binaire ne suffisait pas — mais **il ne fait plus autorité**.

Ce qui du §3 **reste vrai et s'applique** : la publication obligatoire des deux
variantes de masque (§2.2), les trois verdicts du contrat §5.1 appliqués à
`e_requise(p)` au lieu d'un seuil constant, et les six champs que chaque argmin
doit publier (§3.2) — auxquels s'ajoute désormais **`d(p)` et l'`e_requise` qui
en découle**.

---

## 2quater. L'ÉPAISSEUR EST MAJORÉE PAR `d` — théorème, et réparation de la loi

Écrit après démonstration, avant toute mesure de production. Instrument :
`tools/cave_borne_rebord.py`, banc 15/15 vert.

### 2quater.1 Le théorème

`docs/CONTRAT_COQUE_STRUCTURELLE.md` §2.6 définit l'épaisseur en un point de la
peau intérieure comme **la distance euclidienne à la surface extérieure la plus
proche**. Et `Γ` est, par construction, la courbe où la peau intérieure s'arrête
et où la surface extérieure commence : **`Γ` est donc contenue dans `S_ext`**.

```
(1)  e(p) = dist(p, S_ext)  ≤  dist(p, Γ)     car Γ ⊂ S_ext
(2)  dist(p, Γ)             ≤  d(p)           euclidien ≤ géodésique
———
     e(p) ≤ d(p)      pour tout p, sur toute géométrie.
```

Ce n'est pas un constat sur cette grotte. C'est une conséquence directe de la
définition d'épaisseur du contrat, combinée à la définition de `Γ`.

#### L'hypothèse, et elle est violable par l'implémentation

Le pas (1) exige **`Γ ⊂ S_ext`** : le contour doit être une courbe **posée sur la
roche**, là où la peau intérieure s'arrête et où la surface extérieure commence.

Ce n'est pas automatique. Le masque du §2.4 fixe son extrémité extérieure à
`MODELE_SEUIL_DEHORS`, soit **0,45 m devant la lèvre du porche** — donc *dans
l'air*. Une implémentation qui prendrait pour `Γ` la **section du masque à cette
extrémité** obtiendrait une courbe qui ne touche aucune surface, et alors :

- le pas (1) tombe, et le théorème avec lui ;
- pire, `d(p)` lui-même perd son sens — une distance géodésique *sur la peau*
  vers une courbe *hors de la peau* n'est pas définie, et tout code qui en rend
  une l'a fabriquée.

**`Γ` est le rebord, pas la section de masque.** Concrètement : la courbe fermée
de `∂S` qui borde l'ouverture, celle que la peau intérieure et la surface
extérieure ont en commun.

Contrôle exécutable, à faire **avant** de croire un seul chiffre de `d` :
`max_{q ∈ Γ} dist(q, ∂S)` doit valoir zéro à la tolérance du maillage. S'il vaut
0,45 m, l'implémentation a pris la section de masque, et tous les `d` publiés
sont faux — dans le sens indulgent, puisqu'un `Γ` avancé dans l'air **majore**
les distances et donc l'exigence, mais sur une base sans rapport avec la roche.

C'est la même famille d'erreur que l'abscisse en indice de station du §2.3 : deux
grandeurs qui portent le même nom, dont l'une seule a un sens, et rien dans le
code qui crie quand on prend l'autre.

### 2quater.2 Les trois conséquences, et elles condamnent le §2bis.2

1. **`e ≥ min(d ; 0,80)` force `e = d` exactement** partout où `d < 0,80`. La
   loi n'est pas un plancher : elle **est le majorant**. La marge maximale
   atteignable y vaut **zéro**, sur une géométrie parfaite comprise.
2. **Avec la borne conservatrice**, exigée en toutes lettres par §2bis.3.1, il
   faudrait `e − h ≥ d`, donc `e ≥ d + h`, que (1)+(2) interdisent. La loi
   littérale est **insatisfiable** sur `d < 0,80`, pour tout `h > 0`.

   *Précision de l'agent A, et elle est plus rigoureuse que ma formulation
   initiale :* sur une lèvre parfaitement perpendiculaire, un instrument correct
   rend **`BLOQUÉ`, pas `FAIL`**. À l'égalité stricte, ni le vert ni le rouge
   n'est prouvé — c'est le troisième verdict du contrat §5.1, et c'est le verdict
   exact. Le théorème se constate donc par **l'absence de tout `PASS`**, jamais
   par la présence d'un rouge. Mesuré : `max(e − d_euclidien) = +0,000000 m` sur
   la lèvre droite, `−0,0024` à 70°, `−0,0116` à 45°.
3. **Le même argument condamne tout seuil constant `S` en deçà de `d = S`** : la
   collerette à 0,60 m est inatteignable à moins de 0,60 m du rebord, et le
   seuil structurel à 0,80 m à moins de 0,80 m. **C'est exactement ce que
   R2a-3.5.5 avait mesuré sans le nommer** — `lecture / h` rigoureusement
   constant à un facteur 8 près sur deux géométries indépendantes, signature
   d'une arête. Le théorème l'explique et l'étend à toute la série.

Ouvrir la lèvre n'y change rien : au-delà de 90°, le point le plus proche
**devient le rebord lui-même**, et la distance sature à `d`. La table A de
l'instrument le montre — aucun angle ne rend une marge strictement positive.

### 2quater.3 `LOI-R` — la réparation, et elle est dérivée, pas choisie

La plus grande exigence qu'une géométrie parfaite puisse satisfaire sous un
instrument de résolution `h` est `d − h`. D'où :

```
LOI-R :  e_requise(p) = min( max(0 ; d(p) − h) , 0,80 m )
```

- pente **1** conservée : c'est l'intention du lead, inchangée ;
- le genou passe de `d = 0,80` à **`d = 0,80 + h`** ;
- à `h = 0,05` : genou à **0,85 m** — le nombre que la directive §4 exigeait
  **déjà** comme borne garantie hors zone progressive. Il n'a pas été choisi
  pour tomber juste, il tombe ;
- `d ≤ h` : exigence nulle, gate sur continuité et topologie — la directive le
  prévoyait à `d = 0` ; le théorème dit que cette bande a la largeur `h`, pas
  zéro, et que sa largeur est **dictée par l'instrument**, pas négociée ;
- `h → 0` : `LOI-R` converge vers la loi littérale du §2bis.2.

**Contradiction contractuelle à trancher par le lead.** La directive §1 écrit
« 0,80 m constant dès `d = 0,80` » et sa §4 écrit « borne garantie ≥ 0,85 m ».
Ces deux phrases sont incompatibles entre elles d'exactement `h`. `LOI-R` retient
la seconde. Aucun seuil n'est abaissé : `EPAISSEUR_MIN_M = 0,80` et
`EPAISSEUR_MIN_COLLERETTE_M = 0,60` restent identiques et restent exigés partout
où le théorème les rend atteignables.

### 2quater.4 Ce qui rend la bande NON exempte : l'angle, pas l'épaisseur

Une épaisseur ne peut pas être le critère au voisinage immédiat du rebord —
table C de l'instrument : aucun choix de pente `α < 1` ne ramène à zéro la bande
`d < h/(1−α)` où la borne conservatrice ne tranche pas.

La grandeur qui **reste décidable** y est l'**angle de lèvre `θ(p)`** : sans
dimension, il ne rétrécit pas avec `h`. Il se mesure directement sur le maillage,
et `θ ≥ θ_min` équivaut localement à `e ≥ sin(θ_min)·d`.

```
θ(p) ≥ θ_min  exigé sur tout le domaine où d(p) < 0,85 m
```

**`θ_min = 70,25°`**, et il est **dérivé**, non choisi. J'avais d'abord écrit 60°
en le justifiant par la coupe des fixtures ; l'agent A a montré que c'était le
mauvais nombre, et l'a remplacé par un calcul :

sur la rampe, `LOI-R` exige `e ≥ d − h`, et une lèvre conique offre `d·sin θ`.
Donc `sin θ ≥ 1 − h/d`, contrainte la plus dure **au genou** `d = 0,80 + h` :

```
θ_min = asin(1 − h/(0,80 + h)) = asin(1 − 0,05/0,85) = 70,25°   à h = 0,05
```

**Conséquence à ne pas manquer : `LOI-R` est strictement plus exigeante qu'un
gate à 60°.** Elle rejette tout `θ ∈ [60 ; 70,25[` que ce gate laisserait passer.
Tant que `LOI-R` s'applique — c'est-à-dire dès `d > h` — **le gate d'angle
n'ajoute aucune contrainte**. Il n'est décisif que dans la bande `d ≤ h`, où
l'exigence d'épaisseur de `LOI-R` vaut zéro. C'est là, et seulement là, que
`θ ≥ θ_min` est le critère.

Vérifié en machine par l'agent A : `θ = 70°` rend `FAIL` sous `LOI-R` aux deux
planchers testés, ce qui est le comportement attendu de `70 < 70,25`.

Aucun point n'est ignoré : hors bande, gate sur l'épaisseur bornée ; dans la
bande, gate sur l'angle et la topologie. Les deux se recouvrent sur
`h < d < 0,85`, où les deux doivent passer.

---

## 2ter. CODES RETOUR — convention de cette passe, et une divergence à trancher

**Convention imposée par la directive R2a-3.5.6 §2**, appliquée aux instruments
de gate de cette passe :

| verdict | code |
|---|---|
| `PASS` | **0** |
| `FAIL` géométrique | **1** |
| `BLOQUÉ` — résolution, provenance, domaine indécidable | **2** |
| erreur d'outil | **3** ou plus |

> **Un verdict indécidable ne rend JAMAIS `RC=0`.** Si un `RC=0` publié ne
> concerne qu'une expérience diagnostique, le journal final doit le dire
> explicitement.

### La divergence, mesurée, que je ne tranche pas

Le dépôt utilise déjà **`RC=3` pour `BLOQUÉ`**, en quatre endroits :

| document | texte |
|---|---|
| `tools/CLAUDE.md` | « une étape impossible sort en **3 (BLOQUÉ)**, jamais en 0 » |
| `tools/CLAUDE.md` | « `validate_fast.sh` sort désormais en **3 (BLOQUÉ)** si… » |
| `.claude/rules/evidence.md` | « échouer ou signaler `BLOQUÉ` (**code 3**) » |
| `CLAUDE.md` racine | « `validate_release.sh` … sort en **3 (BLOQUÉ)** » |

et `tools/validate_release.sh` l'implémente (`exit 3`).

**Deux conventions coexistent donc dans le dépôt**, et c'est exactement ainsi
qu'une panne silencieuse naît : un appelant qui teste `rc == 3` pour `BLOQUÉ`
lira le `3` d'un nouvel outil comme « erreur d'outil », et son `2` comme un échec
géométrique.

**Ce que je fais** : j'applique la convention de la directive aux **instruments
de gate de cette passe**, parce que c'est son domaine et qu'elle est la plus
récente. Je **ne touche pas** à `validate_release.sh` — ce serait de la
propagation, interdite. La divergence est **signalée au lead**, non tranchée.

---

## 3. Classification de la roche, et les deux seuils — HISTORIQUE, remplacé par §2bis

Soit `p` un échantillon de la coque structurelle au sens du contrat §2.4 —
c'est-à-dire, sans changement, toute surface séparant l'air intérieur canonique
de l'extérieur.

```
d_masque(p) = distance euclidienne de p au volume MASQUE

d_masque(p) <= 0.60  ->  COLLERETTE, seuil 0,60 m
d_masque(p) >  0.60  ->  COQUE,      seuil 0,80 m
```

**La bande vaut le seuil lui-même**, et ce n'est pas une coïncidence commode :
« la roche qui borde directement le masque » est celle qui se trouve à moins que
son épaisseur exigée du passage. Aucune constante nouvelle n'est introduite, et
la bande est aussi étroite que possible — donc conservatrice, puisqu'une
collerette plus large serait plus permissive.

### 3.1 Les deux gates, et ils sont durs tous les deux

| gate | énoncé | seuil |
|---|---|---|
| **collerette** | borne garantie ≥ **0,60 m** en tout point classé collerette | dur |
| **coque** | borne garantie ≥ **0,80 m** en tout point classé coque | dur |

Le verdict global est **le plus faible des deux**, jamais leur moyenne. Les trois
verdicts du contrat §5.1 s'appliquent **séparément à chacun**, avec son propre
seuil :

| cas | verdict |
|---|---|
| `lecture − h ≥ seuil` | **PASS**, garanti |
| `lecture < seuil` | **FAIL**, mesuré |
| `lecture ≥ seuil` **et** `lecture − h < seuil` | **`BLOQUÉ`, RC 3** |

`h` accompagne toujours la borne, des deux côtés. Une borne sans son `h` n'est
pas une borne.

### 3.2 Ce que chaque argmin doit publier

Exigence du lead, reprise mot pour mot et rendue opérationnelle. Pour **chaque**
des deux argmins :

| champ | contenu |
|---|---|
| classification | `COLLERETTE` ou `COQUE` |
| repère | `(ax ; ay ; az)` en modèle Blender, **et** l'équivalent Godot |
| projection | `u` sur le chemin, `ay` de la station interpolée, distance à l'axe |
| raison | `d_masque` mesuré, et le côté du seuil de 0,60 m où il tombe |
| lecture et borne | `lecture`, `h`, `lecture − h`, seuil applicable |
| face | index de la face porteuse, pour rejouer |

Un argmin publié sans sa raison de classification n'est pas recevable.

---

## 4. Provenance — la règle qui a déjà évité un faux rouge

Le couple **(maillage, repères)** doit être cohérent. Mesurer une géométrie
R2a-3.5.x avec les repères du tronc place `MODELE_NICHE` dans la roche pleine :
le contrôle se déclenche, **et il a raison**.

> **Le verdict correct dans ce cas est `BLOQUÉ`, jamais `ROUGE`.** C'est un défaut
> de provenance, pas un défaut de roche. Un outil qui rend `ROUGE` sur ce cas
> accuse la géométrie d'une faute qui appartient au script de lieu.

L'instrument **doit** publier, avant toute mesure : le sha256 du GLB, le commit du
script de lieu dont il lit les repères, les valeurs lues, et le résultat du test
d'appartenance de chaque repère à l'air intérieur. Il refuse de mesurer si l'un
des deux repères tombe dans la roche.

Le masque, lui, ne dépend d'aucun repère divergent (§1) : il reste calculable même
quand la provenance des repères de salle est en défaut. Les deux contrôles sont
donc **séparés**, et leurs journaux aussi.

---

## 5. Ce que cet addendum n'établit pas

- **Rien de visuel.** Une coque conforme peut se lire comme une visière rapportée.
  La question artistique — *« la collerette se lit-elle comme une roche du massif,
  ou comme une arche ajoutée ? »* — n'appartient à aucun instrument.
- **Rien sur la praticabilité.** Le gabarit sert ici de **section de mesure**, pas
  de certificat de passage. `controle_gabarit()` reste seul juge de la
  praticabilité, avec ses deux faiblesses connues et documentées : il saute les
  deux dernières stations, et il n'applique pas `CAVITE_ASYM`.
- **Rien sur la coque de collision.** Le volume réellement traversable est borné
  par `COL_WaterfallCave`, rétrécie de `COL_MARGE_LAT = 0,40` et
  `COL_MARGE_CLE = 0,35` par rapport à la paroi visible. Le masque est défini sur
  le **chemin**, pas sur une surface : il vaut donc pour les deux, et la mesure
  d'épaisseur porte, comme toujours, sur le maillage visible.
- **Rien en dessous du pas.** Une communication plus fine reste invisible à
  l'inondation ; le **genre topologique** la verrait sans la localiser. Les deux
  restent appariés et leurs journaux séparés.

---

## 6. Tickets ouverts par cet addendum, à ne pas confondre avec lui

Aucun n'est un préalable ; tous doivent être consignés.

| # | constat mesuré |
|---|---|
| 1 | `Y_BOUCHE_DEFAUT = −1,15` est une constante **héritée**, recopiée dans cinq outils, alors que `cave_oracle_bouche.py` **dérive** `−1,7348` — écart 0,58 m |
| 2 | trois capsules joueur coexistent : générateur `0,45 / 1,85` (commentaire), scène `0,35 / 1,80`, grottes V1 `0,35 / 1,70` |
| 3 | `controle_gabarit()` saute les deux dernières stations et n'applique pas `CAVITE_ASYM` |
| 4 | `tools/blender/diag_cave_etapes.py` porte trois chemins absolus vers un worktree disparu (ISS-045) |
| 5 | `docs/assets/ASSET_MANIFEST.csv` étiquette le GLB `8bf1a1b3` « R2a-3.6 », quand le lead et les journaux le nomment « R2a-3.4 » |

---

## 7. Historique

| date | événement |
|---|---|
| 2026-08-16 | rédigé et committé **avant** toute géométrie de R2a-3.5.5, sur arbitrage du lead ; complète le contrat gelé `cca1778` sans le modifier |
