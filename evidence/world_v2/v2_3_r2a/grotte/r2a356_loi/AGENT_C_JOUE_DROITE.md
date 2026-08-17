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
- **divergence avec l'agent A : réduite à 0,0187 m** — voir la correction dans
  `AGENT_A_LOI_INSTRUMENTEE.md` §11, où j'avais comparé une lecture à une borne.
  Restent deux lectures prises en **deux points différents** : leurs deux
  argmin ne sont plus le même point, donc aucun des deux ne peut trancher seul.
  Mesure demandée : que l'agent C lise **au point de l'agent A**,
  `(−1,6064 ; −0,2796 ; 2,5602)`, face porteuse 19194. Deux instruments sur un
  même point sont décidables ; sur deux points, non ;
- commentaire faux ligne 5583 signalé, non corrigé — hors couloir.

---

## 9. Le tour de l'amas 1 — le diagnostic est le résultat, pas la géométrie

### Le levier avait changé de côté, et le diagnostic l'a montré à temps

Le nouvel argmin `(2,210 ; 5,015 ; 1,873)` n'est **pas** côté droit :
**91,0 % horizontal, côté `−n`, joue GAUCHE/NORD**, déport `−2,289 m`,
`u = 6,958` — **dans l'emprise de la calotte**. Étendre la joue droite, comme
l'agent l'avait proposé et comme je l'avais autorisé, **aurait été une erreur**.

C'est le diagnostic qui l'a évitée, pas la chance : `--porteurs` rend **16 boîtes
de calotte** contenant le point, corde 1,087 pour 1,200.

### Ce qui bloque réellement — nommé, et contre-indiqué

Ni densité, ni couverture verticale, ni composition : il manque de la **portée
latérale**, à `−2,289 m` de la courbe, quand le module en porte `1,320` au-delà de
son centre.

Augmenter le déport **détacherait les deux couronnes** — le recouvrement vaut
`1,320 − déport`. La suite est donc un changement de **taille de module**, ce que
la leçon de `rochers_gaine()` interdit de toucher sans mesure dédiée.

**Un déficit dont on connaît la cause *et* la contre-indication est un bon endroit
où s'arrêter.** Il vaut mieux que trois tours d'itération à l'aveugle.

### La doublure a été construite, mesurée, et rate sa cible

L'agent a testé l'hypothèse « locale ou globale » contre une trace laissée dans le
générateur — une doublure **globale** refusée en R2a-3.5 pour `cols 1,51 / 1,64,
rapport 1,08` contre 2,00 exigé. Sa joue droite, **locale**, n'avait rien
régressé ; la question était donc légitime et il l'a tranchée par la mesure.

`controle_amas` **passe** : faîtes `8,35 / 4,01 / 1,33`, 3/3/3 à l'entaille 0,90,
ratios `2,23 / 2,37 / 2,25` inchangés, aucune régression à aucune entaille.

| masque 2,00 ; `h = 0,10` | joue droite | + doublure |
|---|---:|---:|
| lecture | 0,7198 | **0,7193** |
| argmin | `(2,190 ; 5,032 ; 1,877)` | **identique** |
| indécidables | 4 049 | **2 916** (−28,0 %) |

Elle visait l'argmin ; elle ne le déplace pas et ne remonte pas sa lecture —
**−0,5 mm, dans le bruit**.

**Cible lecture ≥ 0,85 : NON ATTEINTE. Il reste 0,1307 m.**

### Arbitrage du lead : la doublure est retirée

Sur la doctrine écrite dans le fichier lui-même, celle qui a tué la gaine :
*« on ne réintroduit que ce que `controle_epaisseur` exige — station par station,
chiffre en face. Si la mesure n'exige rien, la gaine disparaît. »*

Les `−28 %` d'indécidables ne la sauvent pas : c'est une métrique de
**l'incertitude de l'instrument**, pas de l'épaisseur de la roche. Elle ne rend la
coque plus épaisse nulle part où la mesure la cherche.

Et dix roches qui ne font pas leur travail ne sont pas neutres : elles sont
exactement ce que `rochers_gaine()` était devenue — de la matière posée pour une
raison qui n'existe plus, qu'une passe ultérieure devra mesurer, attribuer et
défaire. Cette série a déjà payé ce prix une fois ; c'est `TICKET-B4`, toujours
ouvert.

**`rochers_joue_droite()` reste** : elle, a fait son travail — 1 122 → 499
échantillons sous seuil, lecture `+0,0385 m`, trois contraintes tenues.

---

## 10. État FINAL, mesuré sur le GLB publié

```
3a80ae71c89bfc97db10e0fd31fa9a6233a332df5b0219e880ff4d3684c0b000
1 488 532 octets
```

**Reproduit deux fois** : le build de la joue droite seule et le build après
retrait de la doublure rendent **le même sha256**. Le retrait est donc exact,
sans résidu — et les mesures déjà prises sur `3a80ae71` portent sur ce GLB **au
bit près**, ce n'est pas une extrapolation.

Le code de la doublure sort ; **la trace reste en commentaire**, comme pour la
doublure globale refusée en R2a-3.5. L'hypothèse « local ≠ global » demeure
validée et réutilisable — c'est ce qui distingue un retrait d'un effacement.

### La mesure

| masque 2,00 | `h = 0,10` | `h = 0,05` |
|---|---:|---:|
| lecture | **0,7198 m** | 0,7194 m |
| borne | 0,6198 m | **0,6694 m** |
| échantillons sous seuil | **499** | 2 023 |
| gate | `FAIL` | `FAIL` |

> **Les deux colonnes d'« échantillons » ne se comparent pas entre elles** : un
> `h` deux fois plus fin échantillonne plus dense. La comparaison valable est à
> `h` égal — référence R2a-3.5.5 : `0,6813 / 0,5813 / **1 122**`, à `h = 0,10`.

**Gain : lecture `+0,0385 m`, échantillons sous seuil `−55,5 %`.**
**Cible `0,85` non atteinte : il manque `0,1307 m`.**

### Non-régression, entaille 0,90

3/3/3, ratios **`2,23 / 2,37 / 2,25`** contre `2,16 / 2,37 / 2,25` en référence.
Faîtes `8,35 / 4,01 / 1,33`, cavité 83,1 m³, connexité 1, gabarit aux 7 stations,
plancher 0 faute, auto-intersections 2 paires / 0,0006 m, budget 20 070 tris.
**Aucune régression.**

### La dette nommée est payée

Le reclassement encadré a tourné sur la géométrie **finale** : lot **499**,
minorant min **1,791 m**, exigence pleine **prouvée 499/499**, **0 vert**. Le
chiffre publié porte enfin sur le GLB publié — c'est la règle d'ancrage de
`PROMPT4_METHOD`, et elle était en dette depuis deux tours.

### Un troisième faux-vert, produit et corrigé dans le même tour

La première comparaison `make_FINAL` / `make_APRES` a imprimé « IDENTIQUE »
**sans rien comparer** : `diff` sur deux fichiers absents rend un diff vide, donc
`exit 0`, donc le `&&` s'exécute. Refaite avec garde d'existence — **15 lignes
réellement comparées**.

Troisième occurrence du même schéma en une seule passe, avec `ISS-057` et le
`RC=0` d'un journal mort. D'où la règle générale versée dans `tools/CLAUDE.md` :

> un verdict doit publier **la taille de ce qu'il a examiné**, pas seulement son
> résultat. Un « aucune différence » sans « sur N lignes » ne prouve rien.
