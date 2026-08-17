# La famille « joue droite » — les trois contraintes tiennent, le déficit se réduit de moitié

Statut : résultats de l'agent C, reçus le 2026-08-17. Patch non intégré au tronc,
non poussé. Un tour supplémentaire est en cours sur l'amas 1.

## 1. Ce qui a été posé

`rochers_joue_droite()`, symétrique de la calotte côté `+n`, **17 roches**, rang
`gaine` à dessein. GLB `bf68bfda` → **`3a80ae71c89bfc97`**.

**Reproductibilité vérifiée** : après `git stash`, le rebuild redonne `bf68bfda`
au bit près. C'est le contrôle qui manque le plus souvent et qui coûte le plus
cher quand il manque.

## 2. Les trois contraintes dures, mesurées

Elles avaient été posées **avant** la construction, avec l'arbitrage.

| contrainte | mesure |
|---|---|
| **crête inchangée** | `faîte par rang : enveloppe 8,35 · gaine 4,01 · semelle 1,33` — identique au mot près |
| **aucun col comblé** | entaille 0,90 : **3/3/3**, ratios `2,16→2,23` / `2,37` / `2,25`. Aucune régression du nombre de masses à **aucune** entaille |
| **intérieur intact** | cavité 83,1 m³, connexité 1, gabarit aux 7 stations, plancher 0 faute, auto-intersections 2 paires / 0,0006 m — tous identiques |

Volume visuel 798,0 → 798,8 m³, **vers l'extérieur**. C'est la lettre de la
directive §4 : ajouter de la roche localement vers l'extérieur, sans réduire le
volume intérieur ni déplacer la bouche.

Les deux masses à `100°/1,20` et `225°/1,50` **existaient déjà** — elles ne sont
pas un effet de l'ajout.

## 3. Le gain

| | avant | après |
|---|---:|---:|
| lecture à l'argmin | 0,6813 m | **0,7198 m** |
| échantillons sous seuil | 1 122 | **499** |

**−55,5 %.** L'argmin a **migré** vers l'amas 1, dont la table donnait déjà le
minimum à 0,7198 : la joue droite a absorbé l'amas visé, exactement comme prévu.

## 4. Le chiffre en face, et pourquoi raffiner ne sert plus à rien

| | `h = 0,10` | `h = 0,05` |
|---|---:|---:|
| lecture | 0,7198 | **0,7194** |
| borne `lecture − h` | 0,6198 | **0,6694** |

**La lecture ne bouge que de 0,4 mm** en divisant `h` par deux : elle a convergé.
La borne valant `lecture − h`, elle ne peut donc **jamais** dépasser 0,7194, quel
que soit `h`.

Il manque **0,1806 m** à la cible de 0,85, et **aucun raffinement d'instrument ne
les fournira**. Le déficit est géométrique, pas métrologique — c'est exactement la
distinction que trois passes de cette série ont mis du temps à établir, et elle
est ici tranchée par une seule mesure à deux résolutions.

Localisation : **au moins 0,13 m de roche à poser sur l'amas 1**, centré
`(2,24 ; 4,93 ; 1,92)`, hors de l'emprise `u ∈ [3,50 ; 7,20]` retenue pour la
joue droite.

**Donc ce n'est pas un mur** : un déficit chiffré, à un endroit nommé, hors d'une
emprise choisie par l'agent lui-même. Un tour supplémentaire est demandé.

## 5. Le théorème confirmé sur ses données, par son propre instrument

`d` est désormais **encadré** : minorant exact (`Γ` inclus dans les triangles
traversés), majorant par chemin admissible **passant par les milieux d'arêtes** —
jamais la corde entre centroïdes, qui sort de la surface. L'exigence est calculée
sur le **majorant**, donc du côté strict.

> Sur 9 840 points à `d_min < 0,10` : **0 violation de `e ≤ d`**.

Ses 1 002 « verts » de la veille étaient bien des faux verts, produits par un BFS
par face qui donnait `d = 0` à toute face touchant `Γ`.

Et le résultat principal est **inchangé et désormais prouvé par le minorant** :
minorant min **1,791 m**, exigence pleine pour **1 122 / 1 122**, **0 vert**. Le
lot était hors rampe par construction ; la loi de rebord n'en innocente aucun.

## 6. Deux majorants indépendants — c'est un avantage, pas une redite

L'agent C a écrit le sien plutôt que de reprendre celui de l'agent A. Les deux
chemins sont réellement disjoints :

| | agent A | agent C |
|---|---|---|
| minorant | euclidien 3D aux segments de `Γ` | exact, `Γ` ⊂ triangles traversés |
| majorant | Dijkstra **sur les sommets**, `D = 0` sur les seuls sommets de `Γ` | chemin admissible **par les milieux d'arêtes** |

Aucun ne peut hériter du défaut de l'autre. C'est le croisement que la §2quater
demandait sans pouvoir l'imposer.

## 7. Revue des journaux après l'alerte `pkill` — la discipline appliquée

| journal | état | action |
|---|---|---|
| `coque_3a80ae71_h005.log` | **tronqué** à « 489 504 échantillons » | **supprimé et rejoué** |
| `non_regression_C3.log` | sans jeton **et** périmé | **refait** intégralement |
| deux journaux de `make` | copies, sans jeton par construction | **attestés** |

L'attestation ne remplace pas le jeton et l'agent le dit : elle vérifie la
**terminaison canonique** du générateur — une phrase écrite en toute dernière
ligne — jointe au `RC=0` du lanceur et au sha256. Un journal tué s'arrêterait
avant. C'est la bonne réponse à `ISS-056`.

## 8. `NON VÉRIFIÉ`

- reclassement encadré **non rejoué** sur `3a80ae71` : le chiffre publié porte sur
  l'ancienne géométrie ;
- **5 817 indécidables** non tranchés ;
- **amas 2** — 111 points à `ay = 0,13` — non couvert ;
- **divergence de 0,12 m avec l'agent A non expliquée**, et aggravée : leurs deux
  argmin ne sont plus le même point, donc aucun des deux ne peut trancher seul.
  Mesure demandée : que l'agent C lise **au point de l'agent A**,
  `(−1,6064 ; −0,2796 ; 2,5602)`, face porteuse 19194. Deux instruments sur un
  même point sont décidables ; sur deux points, non ;
- commentaire faux ligne 5583 signalé, non corrigé — hors couloir.
