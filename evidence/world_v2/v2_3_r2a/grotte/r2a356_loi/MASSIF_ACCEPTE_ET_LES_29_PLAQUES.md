# `MASSIF` accepté — et ce que le théorème n'excuse PAS

Statut : réparation de l'agent B **reproduite par le lead** avec un instrument
indépendant, le 2026-08-17. Patch non intégré au tronc à cette date.

## 1. La réparation, et sa cause

Lissage laplacien des positions de `MASSIF`, λ = 0,8, trois passes, stations 1
à 10. `hw`, `cle`, `jeu_lat`, `jeu_cle` inchangés — seul le **chemin** est
adouci. Visière et pointe de queue immobiles ; déplacement maximal 0,53 m.

La cause est **intrinsèque**, pas accidentelle, et c'est ce qui rend la
correction acceptable :

| station `MASSIF` | rayon latéral `hw + jeu_lat` | rayon de courbure |
|---|---:|---:|
| 1 | 3,30 m | **2,37 m** |
| 2 | 3,60 m | **2,26 m** |

Un tube plus large que le virage qu'il suit **se traverse nécessairement** : le
bord intérieur recule pendant que l'axe avance. Aucune subdivision ne corrige
cela. R2a-3.4 tenait 0,11 et 0,20 parce que sa galerie filait droit sur 10,4 m.

Le zéro obtenu tient sur un **plateau** — λ de 0,6 à 1,0, 3 à 20 passes — donc ce
n'est pas un réglage en équilibre instable.

## 2. La prédiction falsifiable, tenue sous deux instruments

J'avais posé la condition avant la mesure : si `MASSIF` n'alimente que la coque
de collision, alors `SM_WaterfallCave` doit être **inchangé au bit près** et seul
`COL_WaterfallCave` doit bouger. Sinon l'attribution est fausse.

Empreintes de l'agent B (md5 de son outil) et les miennes (sha256 des `POSITION`
et des indices, lecture GLB pure Python, code écrit séparément) :

| nœud | agent B | lead | verdict |
|---|---|---|---|
| `SM_WaterfallCave` | `df00200e…` → `df00200e…` | `f51919de0d27a2c3` → `f51919de0d27a2c3` | **INCHANGÉ** |
| `COL_WaterfallCave` | `71b61401…` → `c977117b…` | `f17852ba628a8dc6` → `d36e70aac884ff59` | **MODIFIÉ** |

Deux algorithmes, deux auteurs, même verdict. « `MASSIF` est exclusivement
collision » n'est plus une lecture de code, c'est un fait expérimental.

## 3. Le résultat, sur le GLB exporté et non en laboratoire

| | avant | après |
|---|---:|---:|
| `COL_WaterfallCave` | 62 | **16** |
| `SM_WaterfallCave` | 6 | 6 |
| `cav×cav` | 0 | 0 |
| `cav×env` | 28 | 16 |
| **`env×env`** | **34** | **0** |
| enfoncement max | 0,457 m | **0,245 m** |

Topologie intacte : 0 bord libre, 0 non-manifold, 1 composante, **genre 0** sur
les deux maillages. Gabarit : `capsule r=0,45 h=1,85 passe aux 7 stations`.
Épaisseur de paroi **0,87 m**, linteau 1,15 m — au-dessus de 0,80, contre 0,20 m
sur la variante `CAVITE_ASYM` qui avait été écartée.

## 4. Un outil de l'agent B mentait, et la correction est la bonne

Sa première ventilation classait par matériau. Or `COL_WaterfallCave` s'exporte
avec `avec_matieres=False` : **une primitive, aucun matériau**. L'outil rangeait
donc tout du côté enveloppe et publiait « 62 `env×env` / 0 `cav×env` » — faux, et
contredisant sa propre mesure interne. Il classe désormais par appariement de
positions et **refuse en code 2** quand il ne peut pas décider.

C'est la règle générale de ce dépôt, retrouvée une fois de plus : un outil qui ne
peut pas trancher doit le dire, jamais rendre une valeur par défaut.

## 5. Ce que le théorème n'excuse PAS — correction d'une de mes inférences

En voyant les cinq plaques rouges publiées — `(−0,07 ; −2,13)`, `(0,03 ; −2,13)`,
`(0,13 ; −2,13)`, `(1,03 ; −1,73)`, `(1,13 ; −1,73)` — j'ai d'abord supposé
qu'elles étaient au rebord du porche et que `LOI-R` les reclasserait. **C'est
faux, et la lecture du code le montre.**

`_cumul_au_dessus_du_vide` rend le **banc de roche au-dessus du vide**. Une
« PLAQUE 0,114 m sous 2,63 m de vide, 6/8 voisins » est donc un **toit de 11 cm
au-dessus d'un volume de 2,63 m**, pas une terminaison latérale. Le tri
`plaques / bords` par `VOISINS_PLAQUE_MIN = 6` existe précisément pour séparer
les deux, et la docstring de la fonction avait déjà trouvé le phénomène que je
viens de démontrer, en d'autres mots :

> « au bord d'un porche ou d'un surplomb, l'épaisseur verticale de la roche EST
> nulle, par définition du bord. Mesuré, le minimum du domaine complet tombe sur
> un tel bord sur les TROIS géométries, y compris la livrée R2a-3.4. »

Une plaque à 6/8 voisins n'est pas un bord. Sous `LOI-R`, à `d ≈ 0,5 m`,
l'exigence vaut encore 0,45 m contre 0,114 m mesurés — **rouge d'un facteur
quatre**. Le théorème répare le gate ; il n'excuse pas une dalle mince.

## 6. La mesure qui manque, et qui décide de la suite

Deux situations opposées, que seule la comparaison au **livré** distingue :

- R2a-3.4 porte aussi des plaques sous 0,80 m → **état préexistant**. La porte
  n'a jamais été verte, elle n'a été franchie qu'en diagnostic. Ticket, pas
  blocage — exiger du candidat ce que le livré ne tient pas serait un plancher
  fabriqué.
- R2a-3.4 est propre et le candidat en fabrique 29 → **régression bloquante**.

Demandé à l'agent B : les 29 coordonnées, la même liste sur R2a-3.4, et si les
deux en ont, si ce sont les mêmes endroits.

## `NON VÉRIFIÉ`

- Le patch n'est pas intégré au tronc ; le GLB reste un échafaudage
  (`RC_MAKE=2`, portail « épaisseur sur le domaine » rouge et franchi en
  diagnostic).
- Les **16 `cav×env`** restants demandent d'épaissir l'enveloppe vers
  l'extérieur — couloir de l'agent C, hors périmètre de l'agent B.
- Aucune capture, conformément à la directive §8.
