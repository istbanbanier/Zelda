# Intégrité visuelle du candidat `3a80ae71` — trois échecs, tous localisés

Statut : mesures de l'agent B, reçues le 2026-08-17. Hash du GLB relevé **avant**
toute mesure : `3a80ae71c89bfc97…`, 1 488 532 octets, conforme.

## Ce qui passe

| critère | mesure |
|---|---|
| une seule composante rocheuse | 1 composante — V=10 037, E=30 105, F=20 070 ; 0 bulle, 0 écaille |
| **zéro trou vers le ciel depuis le volume jouable** | couper le **seul** contour de bouche sépare le maillage en 1 008 f / 95,19 m² intérieurs et 19 062 f / 747,00 m² extérieurs = 20 070. Graines salle et niche prouvées **dans l'air** par angle solide. **Test sans résolution** |
| zéro bord libre · zéro non-manifold | 0 arête à 1 face, 0 à >2 faces, 0 sommet pincé |
| genre | **0**, conforme à l'attendu ; `χ = 2` |
| aucune surface flottante · aucune vue traversante | intérieur et extérieur ne communiquent qu'à la bouche |
| composition | **3/3/3** à l'entaille contractuelle 0,90 ; ratios `2,23 / 2,37 / 2,25` ; écarts et cols au-dessus des planchers ; décentrement 10,5 % et 14,4 % |
| bouche, ancre, salle, niche, récompense, végétation | inchangés — dont plusieurs **par construction** : le commit ne touche aucun fichier de placement ni de scène |
| `gltf_inspect` | `=== VALIDE ===`, `RC=0` |

Le critère du trou vers le ciel est le plus important de la liste et il est
**mesuré depuis l'intérieur**, avec des graines prouvées dans l'air — pas depuis
l'extérieur, et sans dépendre d'une résolution.

## Ce qui échoue — trois défauts, tous avec leur adresse

### 1. Un triangle d'aire EXACTEMENT nulle — et c'est une régression

`prim 1, tri 3501`, modèle `(−1,504 ; −3,099 ; −0,639)`.

**Ce n'est pas une lamelle : c'est une T-jonction.** `b` est le milieu **exact**
de `a–c` sur un segment de **0,482 m**, produit vectoriel exactement `(0,0,0)`,
`c − a = 2·(b − a)` exact. L'asset livré en porte **zéro**.

### 2. Deux auto-intersections réelles

`MAT_CaveRock_Base`, hors cavité, près du plan de bouche :
`8917↔13031` à `(2,3434 ; −1,6011 ; −0,6581)`, corde **4,972 mm** ;
`13031↔13047` à `(2,0090 ; −2,1816 ; −0,6871)`, corde **59,026 mm**.
Le sommet `13031` est commun aux deux — probablement une seule cause. Le compte
**2 concorde avec le générateur**.

### 3. `world_v2_places` : 7/8

`test_la_grotte_a_un_seuil_et_un_interieur_praticables` : plafond **sous 1,75 m**
vers `(−105,0 ; 3,9)` et `(−105,4 ; 2,2)`. Ce filet mesure la hauteur libre
contre la **collision** — hors du périmètre de l'agent, relayé à celui qui la
tient. Il était `ok` dans un `validate_fast` antérieur.

**Tension à lever, et elle est réelle** : le générateur imprime
`gabarit : capsule r=0,45 h=1,85 passe aux 7 stations`. Les deux ne peuvent pas
être vraies au même endroit — station contre continu, cavité analytique contre
collision exportée (`ISS-044`), ou repère. À trancher par la mesure.

## L'angle mort d'outillage, et il est de la famille d'ISS-018

> **Aucun outil existant ne pouvait voir cette T-jonction.**

`tools/cave_check_mesh.py` soude par position quantifiée puis retire les faces
dégénérées par **égalité d'indices** après remap. Trois sommets **distincts et
colinéaires** reçoivent trois indices distincts : ils passent.

Vérifié par moi, démonstration fermée sur le cas exact :

```
trois sommets DISTINCTS, colineaires, b milieu exact de a-c
test topologique (ra==rb or ...) : PASSE — l outil ne voit RIEN
aire exacte                      : 0.0  -> DEGENERE
```

C'est exactement le mode de panne d'ISS-018 : **un test vert sur une grandeur qui
n'est pas celle qu'on croit mesurer.** Le dégénéré n'est pas une propriété
d'indices, c'est une propriété d'**aire**.

## Une auto-correction qui vaut le résultat

Le premier instrument de l'agent annonçait **4** traversées, dont une corde de
**0,970 m**. Blender n'en voyait que 2. Vérification à la main : une paire ne
straddle que dans un sens, l'autre est **coplanaire** — le piège des faces
tangentes que le générateur dit avoir déjà payé. `max` corrigé en `min`, le
compte revient à 2.

> **La corde de 0,970 m ne doit pas être citée.** L'agent le dit lui-même.

## Lamelles — publiées, non jugées

| aire | livré `8bf1a1b3` | candidat `3a80ae71` |
|---|---:|---:|
| exactement nulle | **0** | **1** |
| < 1e-9 | 4 | **1** |
| < 1e-8 | 9 | 4 |
| < 1e-6 | 13 | 9 |

Le candidat **réduit** les lamelles partout et **introduit** l'unique aire nulle.
Le seuil qui sépare « dégénéré » de « fin » n'est pas tranché, et l'agent a eu
raison de ne pas le trancher seul.

Corroboration croisée : son instrument reproduit **mes quatre chiffres** sur
l'asset livré — 19 954 triangles, arête médiane 0,3325 m, 0 aire nulle, 4 lamelles
à ~1e-10. Trois outils sans code commun s'accordent sur 10 037 sommets soudés et
798,8 m³.

## `NON VÉRIFIÉ`

Si le 7/8 est une régression de `531cdd8` ou d'une étape antérieure — non établi ·
absence **absolue** de végétation devant l'entrée (seulement : aucune ajoutée) ·
bouche comparée à `a76f594b`, pas au livré · silhouette **rendue** non mesurée,
les chiffres sont géométriques · `godot --import` rend **`RC=134`** (SIGABRT)
après `loading_editor_layout DONE`, cache écrit et 8 tests exécutés — ticket, non
poursuivi · tout ce qui touche `COL_WaterfallCave`, par consigne.

---

## 9. La face d'aire nulle est CORRIGÉE — et sa cause était une étape non mesurée

GLB `3a80ae71` → **`40714c46`**, 1 488 700 octets.

L'agent a exporté **chaque étape** de la chaîne et mesuré chacune. Les deux
défauts ne partagent pas de cause, contrairement à ce que le sommet commun 13031
laissait croire :

| étape | triangles | aire nulle | traversées |
|---|---:|---:|---:|
| 4 · stratifier | 135 212 | 0 | 0 |
| 5 · **décimer** | 19 000 | 0 | **2** ← |
| 6 · **soustraire** | 20 070 | **1** ← | 2 |

### La cause, et elle vaut au-delà de ce défaut

**La face d'aire nulle naît de la TRIANGULATION, pas du booléen.** Dans Blender
il n'y a **aucune** face plate — 17 424 polygones, aire minimale `1,29e-05`. Le
coupable est le **polygone 7756, un treize-gone** de 0,2726 m² dont le bord porte
`a, b, c` consécutifs et **colinéaires** ; `b` est légitimement utilisé par deux
quadrangles de la découpe et ne peut pas être supprimé.

Tant que c'est un n-gone, tout va bien. Mais **l'exportateur glTF triangule de
toute façon** :

> une étape **non mesurée**, capable d'injecter un défaut **après le dernier
> contrôle**.

C'est la même famille que le piège déjà consigné — mesurer un artefact sans
prouver qu'il vient d'être produit — et elle explique pourquoi aucun contrôle
côté Blender ne pouvait voir ce triangle. Le correctif fait faire la
triangulation par le générateur, donc **avant** les contrôles.

**Le rayon d'action était le vrai sujet.** Trianguler les 2 515 n-gones d'un bloc
a rendu « 1 arête de bord, 1 non-manifold » et **cassé le build**. On ne triangule
donc que les polygones portant un triplet colinéaire — **5 n-gones**.

## 10. Les deux traversées — jugées NON RÉELLES, sur un seuil qui préexiste

L'agent a tenté `_resoudre_auto_intersection` après décimation. Les 2 traversées
disparaissaient, **mais le solveur laissait un sommet pincé** (6080) là où il n'y
en avait aucun. Il a **annulé** : échanger 0,6 mm de recouvrement contre un défaut
de fermeture est un recul.

**Quelle grandeur juge « réelle ».** L'**enfoncement mutuel** — le repli — et non
la corde. C'est lui qui décide si une nappe **ressort visiblement** de l'autre ;
la corde ne mesure que la *longueur* du contact et surestime un frôlement rasant.
La profondeur sommet-au-plan (0,0485 m) est dominée par la **taille des
triangles**, pas par l'interpénétration.

| | valeur |
|---|---:|
| repli mesuré | **0,0006 m** |
| `REPLI_LIVRABLE_MAX_M` | **0,02 m** |
| rapport | **33× sous le seuil** |
| part de l'arête médiane | 0,24 % |

**Vérification du lead, parce que la directive interdit de transformer une
intersection réelle en zéro par une tolérance** : `REPLI_LIVRABLE_MAX_M = 0.02`
existe **dans le générateur du tronc à `504ecbe`**, aux côtés de
`PROFONDEUR_REPLI_MAX_M = 0.15`. Ce n'est donc **pas** une tolérance inventée pour
cette passe : c'est le seuil de livrabilité que le projet s'était donné avant, et
sous lequel l'asset livré a été validé.

> **Verdict du lead : les deux traversées ne sont pas réelles**, au sens du
> critère préexistant du projet, avec un facteur 33 de marge. Le chiffre est
> publié, la grandeur est nommée, et le seuil n'a pas bougé.

Ce qui **est** corrigé, c'est le trou de surveillance : rien ne mesurait les
traversées entre `decimer()` et la fin.

## 11. Tableau republié — les trois prédictions tiennent au chiffre près

Genre **0**, composition **3/3/3**, ratios **2,23 / 2,37 / 2,25** inchangés. Et
mieux : **V, E, F, aire totale (842,188236 m²) et volume (798,8 m³) sont
identiques** — le correctif ne touche que la triangulation de 5 polygones.

| critère | avant | après |
|---|---|---|
| aire exactement nulle | **1** | **0** — aire min non nulle `4,840e-09` |
| lamelles sous `1e-9` | 1 | **0** |
| lamelles sous `1e-6` | 9 | **6** |
| tous les autres critères visuels | PASS | **PASS**, inchangés |
| `world_v2_places` | 7/8 | **7/8**, collision inchangée — défaut de sonde établi |

## 12. Deux aveux, et le premier est une leçon générale

**Un garde-fou écrit mais jamais observé.** L'agent avait stubé
`bpy.ops.wm.save_as_mainfile` et **documenté** que la course ne toucherait rien de
suivi. Faux : `bpy.ops.wm` re-résout par `__getattr__`, le jeton `NEUTRALISE`
n'est **jamais sorti**, et la course a réécrit le `.blend`. Le GLB candidat, lui,
n'a jamais bougé.

> **Un garde-fou vaut par son observation.** Poser un stub et écrire qu'il
> protège n'est pas le vérifier — il fallait exiger le jeton, comme pour
> `FIN NOMINALE` et `^RC=`.

**Et sa première correction était un recul**, su seulement en re-mesurant avec ses
propres instruments au lieu de croire le « 0 face plate résorbée » du générateur.
