# LOT 1.R.2 — Sanctuaire forestier (`valley.poi.forest_shrine.01`)

Arbre : `/home/user/wt1r2-sanctuaire`, détaché sur `529d767`. Non poussé.

## Le verdict à corriger

> « Le lieu est reconnaissable comme petit autel, mais l'arbre central continue
> de séparer le joueur du sujet. Le seuil et l'axe rituel ne sont pas
> immédiatement lisibles. »

## L'ouverture entre les troncs — une mesure, pas une intuition

Les arbres V2.2 sont gelés et la sonde ne peut pas les localiser : son
recensement rend l'identité pour 16 651 transforms d'instance, et elle le dit
au lieu de publier des coordonnées plausibles et fausses. L'ouverture a donc
été mesurée là où elle est réellement visible — **sur l'image**, colonne par
colonne, dans la bande de hauteur du sujet (y 300..500) de la capture héritée.

| Bandes de tronc (px) | 203-235 · **661-717** · 794-836 · 901-915 · 1239-1276 |
|---|---|
| **Plus large fenêtre LIBRE** | **x 236 → 660**, soit −35,6° à +2,03° de l'axe de visée |

L'ouverture est donc **entièrement à gauche de l'axe de visée**, et le gros
tronc central commence à +2,1°. Les troncs étant gelés, cette fenêtre est
identique avant et après : elle a été revérifiée sur `it3` — mêmes bandes,
au pixel près.

## Le modèle de projection, validé avant de s'en servir

Trois pièces indépendantes, prédites puis relevées sur la capture héritée :

| Pièce | Prédit | Mesuré sur l'image |
|---|---|---|
| Cœur (dessus de dalle) | x 510 | bille d'offrande x 502-515 |
| Sommet du dossier | y 317 | masse verticale, sommet y 312 |
| Sommet du montant A | y 346 | pierre dressée, sommet y 357 |

## Ce que la mesure a révélé, et qui n'était pas une impression

L'axe de visée du plan joueur a l'azimut **−30,05°** ; l'axe de la nef, à
θ = 45°, avait l'azimut **−45°**. **Quinze degrés d'écart, c'est le pire des
deux mondes** : à 0° le seuil ENCADRE le cœur, à 45° la nef se lit de
trois-quarts ; à 15° elle ne fait ni l'un ni l'autre. Les montants
projetaient à x 357 et 461, le cœur à **x 510** — donc À CÔTÉ du seuil, et le
montant le plus haut (sommet y 346) venait se superposer au dossier (y 317).
Le seuil masquait le cœur au lieu de le présenter.

## Les changements de structure, dans l'ordre où les captures les ont imposés

1. **L'axe de nef se couche dans l'axe de visée** — θ 45° → 14,3°,
   T (2,50 ; 0,25) → (3,02 ; 0,25). Montants à x 400 et 555, cœur à 481 :
   le cœur tombe au MILIEU de la porte. Tout le lieu s'étale de x 334 à 615,
   dans l'ouverture, 45 px de marge sur le tronc.
2. **Le seuil s'ouvre** — entraxe 1,20 → 1,62 en x de nef (1,863 m réels).
   C'est ISS-070, et le calcul est fait sur les colliders TOURNÉS.
3. **L'axe devient visible par ce qui dépasse de l'herbe** — deux bordures de
   bornes basses remplacent un dallage dont **aucune des neuf dalles**
   n'était discernable sur la capture héritée.
4. *(après `it1`)* **Les montants remontent** — j'avais eu tort de les
   baisser : à 1,15 m de pierre réelle ils tombaient au gabarit des murets et
   le seuil disparaissait dans l'amas. Le verdict ne dit pas « le cœur est
   écrasé ».
5. *(après `it1`)* **Les murets reculent** vers le cœur : ils cessent d'être
   l'enceinte de la NEF pour flanquer le CŒUR, et la travée se vide.
6. *(après `it2`)* **Le linteau sort du passage** — relevé à 50° au milieu du
   seuil, il projetait à x 456, entre le montant est et le cœur : il masquait
   le sujet qu'il présentait. Il tombe au pied du montant ouest, x 593.
7. *(après `it2`)* **La pierre couchée cesse de barrer la nef** et la borde à
   l'ouest ; le dallage passe à deux dalles.

## Preuves

| Quoi | Où | Verdict |
|---|---|---|
| Sonde AVANT | `sondes/probe_AVANT_ROUGE.log` | **FAIL**, fenêtre 0,89 m |
| Sonde APRÈS | `sondes/probe_APRES.log` | **PASS**, fenêtre **1,31 m** |
| Capsule réelle, entrée puis sortie | idem, §2c (contrôle AJOUTÉ) | **100 %** / **100 %** |
| R-D3 | `verdict_d3_sanctuaire.json` | **PASS**, pire paire 0,389 / seuil 0,4912 |
| Vues gelées | `it3/` (+ `it1/`, `it2/` pour l'historique) | copie exacte des trois plans |
| Avant/après | `planche_avant_apres_joueur.png` | |

## Contrôles faits en plus, et ce qu'ils disent

**Suites du dépôt** (`tests/`) : `lot1_defauts` **11 réussis / 0 échoué**,
`places_contract` **5 / 0**. Deux d'entre elles comptent particulièrement
ici — `test_d7_aucun_budget_de_lieu_n_est_depasse`, parce que la composition
a changé, et **`test_d8_aucun_element_gele_n_a_bouge`**, qui est la
confirmation par le dépôt, et non par mon propre inventaire, que la
recomposition n'a touché aucun élément gelé. Journaux dans `tests/`.

**Invisibilité depuis la route** : le bâti et le rideau sud ayant tous deux
bougé, le contrat « invisible depuis la route à 7,3 m » a été recapturé
depuis P1 (84 ; 81), regard nord — `controle_route/shrine_controle_route_P1.png`.
Sur cette image, aucune pierre du vestige n'apparaît : le rideau de buissons
occupe toute la zone où il se projetterait. Mesure sous l'horizon (x 420-900,
y 330-620), là où le vestige tomberait : **0,64 %** de pixels gris peu
saturés, et ce résidu est du sol et des troncs, pas de la maçonnerie. Le
décalage de +0,45 m du rideau, qui n'était qu'un calcul de ligne de vue, est
donc confirmé par une capture.

## Ce qui reste NON VÉRIFIÉ

- **Le verdict artistique.** Il appartient à Codex et à Istvan. Ce document
  décrit ce qui est visible, pas ce qui est réussi.
- **La franchissabilité humaine du seuil** : aucune manette, aucun écran ici.
- **`tools/validate_fast.sh`** n'a pas été rejoué en entier sur cet arbre : il
  appartient à l'intégration du lead, qui seule voit les trois voies réunies.
  Deux suites l'ont été, et elles sont vertes (voir ci-dessous).
