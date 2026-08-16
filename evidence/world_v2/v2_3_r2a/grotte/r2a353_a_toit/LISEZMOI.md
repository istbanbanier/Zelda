# Agent A — toiture et domaine géométrique, R2a-3.5.3

Socle `507ef6a`. Toutes les mesures sont en repère **modèle** `(ax, ay, z)`.

## 1. La cartographie est reproduite, et elle est JUSTE

| géométrie | sha256 | toit minimal, fenêtre `x[-2;3] y[4;7]`, pas 0,10 |
|---|---|---|
| candidat | `cc3596c5` | **0,038 m** en `(0,50 ; 5,80)`, vide **1,408 m** |
| BASE352 | `8bc8b9f9` | **0,038 m** en `(0,50 ; 5,80)`, vide **1,408 m** |
| R2a-3.4 livrée | `8bf1a1b3` | **0,374 m** en `(0,80 ; 6,00)` |

Reproduit par un lecteur `.glb` **indépendant de Blender** (`tools/cave_roof_glb.py`,
pur Python, ni `bpy` ni numpy). Colonnes qualifiantes 512 contre 514 annoncées —
écart de tolérance de fusion d'impacts, sans effet sur le minimum.

Lame : bande continue d'environ **0,25 m de large sur 0,55 m de long**, `x ∈ [0,30 ; 0,50]`,
`y ∈ [5,55 ; 6,10]`, épaisseur de 0,58 m à 0,038 m puis remontée. Identique sur
BASE352 : **le défaut est hérité de l'enveloppe, pas du lot collerette.** Cette
conclusion de la cartographie tient.

## 2. MON ERREUR, conservée intégralement

J'ai d'abord mesuré le `.glb` **sans filtrer le maillage**. Or il en contient deux :

    noeud COL_WaterfallCave   mesh=0     <- coque de collision
    noeud SM_WaterfallCave    mesh=1     <- visuel

La coque de collision est un **tube plein le long de la galerie** : elle rebouche
le vide qu'on mesure. Mes colonnes rendaient donc « 3,06 m de roche continue » en
`(0,50 ; 5,80)`, et la séquence de normales non alternée
`entree, entree, sortie, sortie` — deux coques imbriquées — m'a fait conclure que
le maillage s'auto-traversait et que **la règle de parité de `tools/CLAUDE.md`
était en défaut**.

**C'était faux.** Sur le maillage visuel seul, les deux lectures — parité et
enlacement — donnent le **même** résultat, `0,038 | 1,408 | 2,712`. Il n'y a pas
d'auto-intersection à cet endroit, la parité n'était pas en cause, et la
cartographie avait raison depuis le début.

Le journal `equivalence_enlacement_MAILLAGES_FUSIONNES_ERRONE.log` est conservé
sous ce nom : ses 150/150 concordances sont exactes **mais portent sur le mauvais
maillage**. C'est la famille ISS-018 — mesurer avec assurance autre chose que ce
qu'on croit — et le garde-fou qui manquait était trivial : *regarder ce qu'il y a
dans le fichier avant de le mesurer*. `charger()` filtre désormais sur
`SM_WaterfallCave` par défaut, et `noms_de_maillages()` existe pour l'exiger.

L'implémentation par enlacement est **conservée** : elle englobe la parité comme
cas particulier et ne coûte rien. Mais elle ne corrigeait aucun défaut réel.

## 3. R2a-3.4 LIVRÉE EST AUSSI HORS CONTRAT — domaine complet, visuel seul

`x[-9;9] y[-4;12,5]`, pas 0,10 m, seuil `EPAISSEUR_MIN_M = 0,80` (jamais modifié).
Une colonne mince est une **plaque** si ≥ 6 de ses 8 voisins ont un vide
qualifiant, sinon un **bord** (terminaison latérale, où l'épaisseur verticale est
nulle par géométrie et non par défaut).

### 3.a — CORRECTION : j'ai d'abord publié 271 / 0,049 m pour R2a-3.4

La première version de ce document annonçait, pour R2a-3.4, **271 plaques et un
minimum de 0,049 m en `(5,30 ; 5,00)`**. L'intégrateur a rejoué
`tools/cave_roof_plaques.py` et obtenu **326 plaques et 0,020 m en
`(−0,20 ; −2,60)`**. Deux de mes propres instruments se contredisaient, sur la
géométrie de référence, de 20 % sur le compte.

**Ce n'était pas un bug : ce sont deux mesures différentes**, et j'avais laissé
les deux outils sur des définitions divergentes. J'ai introduit le cumul APRÈS
avoir écrit `cave_roof_plaques.py` et je ne l'ai pas propagé — précisément le
piège consigné dans `tools/CLAUDE.md` : *« quand un défaut de mesure est trouvé
dans un outil, chercher tout de suite les AUTRES endroits qui font la même
mesure. »*

La colonne litigieuse, R2a-3.4 en `(−0,20 ; −2,60)` :

    roche 0,957 | vide 0,471 | roche 0,020 | vide 2,768 | roche 2,602

Le vide de 0,471 m ne qualifie pas (< 1,00 m). `première roche` enjambe donc le
banc épais et tombe sur la **lame de 2 cm** ; `cumul` additionne 0,957 + 0,020 =
0,977 m et passe le seuil. La lame est **réelle** : enlacement vérifié dans huit
directions indépendantes sur le maillage visuel seul — `+1` à z 3,00, `0` à 2,35,
`+1` à 2,12, `0` à 1,00. Elle est **plus mince que le défaut qui a arrêté la
passe précédente**, et elle est sur la géométrie **livrée**, devant le plan de
bouche.

**Ce que je retiens : `première roche`.** Le contrat dit « nulle part une
plaque » ; une lame de deux centimètres est une plaque, que du rocher la surmonte
ou non. Le cumul répond à une autre question — « combien de roche sépare du
dehors » — qui est légitime et reste publiée à côté, mais qui peut **cacher une
lame derrière un banc épais**. Le contrôle du générateur juge désormais sur le
banc et publie le cumul en regard.

### 3.b — Les deux mesures, les trois géométries

`tools/cave_roof_plaques.py --mesure {premiere,cumul}`, `RC=0` partout.

| mesure | géométrie | plaques | bords | la plus mince |
|---|---|---:|---:|---|
| première | candidat `cc3596c5` | **167** | 46 | 0,038 m `(0,50 ; 5,80)` |
| première | BASE352 `8bc8b9f9` | **232** | 48 | 0,038 m `(0,50 ; 5,80)` |
| première | **R2a-3.4 `8bf1a1b3`** | **326** | 235 | **0,020 m** `(−0,20 ; −2,60)` |
| cumul | candidat | 168 | 46 | 0,038 m |
| cumul | BASE352 | 232 | 48 | 0,038 m |
| cumul | R2a-3.4 | 271 | 229 | 0,049 m `(5,30 ; 5,00)` |

Les deux outils se reproduisent exactement sous la mesure correspondante ; la
divergence est entièrement expliquée. Le générateur rend **167** sur le candidat,
identique à `cave_roof_plaques.py --mesure premiere`.

### 3.c — Ce qui est solide, et ce qui ne l'est pas

**Direction : solide sous les deux lectures.** 326 contre 167, ou 271 contre 168 —
dans les deux cas la géométrie **livrée** porte davantage de plaques hors contrat
que le candidat, et son minimum n'est pas meilleur. **Il n'y a pas de régression
d'un facteur dix** : le 0,374 m de R2a-3.4 était son minimum *dans la seule
fenêtre* `x[-2;3] y[4;7]`.

**Compte : non tranché.** Le nombre exact dépend de la mesure retenue, et ce choix
appartient au lead.

Le contrat `EPAISSEUR_MIN_M` n'a **jamais** été tenu hors du domaine des stations,
sur aucune des trois géométries. Aucun seuil n'a été touché pour écrire cela.

### 3.d — R2a-3.4 porte près de trois fois plus de vide interne

Colonnes à vide qualifiant (≥ 1,00 m) : candidat **2 714**, BASE352 **2 324**,
R2a-3.4 **6 292**. C'est cohérent avec **ISS-050** (vides internes de 0,18 à
1,74 m entre galerie et paroi), et cela dit la même chose que le compte de
plaques : sur ce critère aussi, **le candidat est meilleur que la référence**.

## 4. `controle_epaisseur_domaine()` — le contrôle étendu

Dans `source_assets/blender/environment/make_waterfall_cave.py`. Nouvelles
constantes uniquement (`PAS_DOMAINE_M` 0,10 · `MARGE_DOMAINE_M` 0,60 ·
`VIDE_QUALIFIANT_M` 1,00 · `VOISINS_PLAQUE_MIN` 6) ; **aucun seuil existant
modifié**.

* balaie l'emprise réelle du maillage dilatée de 0,60 m, pas les stations ;
* **publie les bornes couvertes** et **échoue** (`franchir("couverture du domaine")`)
  si le domaine échantillonné ne couvre pas le domaine exigé ;
* trois états : `aucune matière` (bouche/ciel) · `matière pleine` · `lame mince` ;
* sépare plaques et bords, publie les deux ;
* publie point minimal, épaisseur et hauteur du vide sous-jacent.

Exécution réelle, `tools/blender/export_architecture.sh waterfall_cave`, `RC=1` :

    domaine : pas 0.10 m, 30012 colonnes, x [-9.37 ; 8.83] y [-3.73 ; 12.57]
    domaine : 2716 colonne(s) a vide qualifiant — 4 sans aucune matiere
              au-dessus (bouche/ciel), 2500 en matiere pleine, 212 lames
    ERREUR: PLAQUE 0.050 m en (0.53 ; 5.77) sous 1.44 m de vide, 8/8 voisins
            — moins que EPAISSEUR_MIN_M = 0.80 m (cumul de la colonne 0.050 m)
    domaine : 167 plaque(s) sous le seuil, la plus mince 0.050 m

Le verdict porte sur le **banc** surmontant le vide, et le **cumul** de la
colonne est publié en regard : voir §3.a, où le cumul seul laissait passer une
lame de 2 cm sur la géométrie livrée. Ce compte de 167 est identique à celui de
`tools/cave_roof_plaques.py --mesure premiere` sur le même `.glb`.

La chaîne passe donc de **VALIDE** à **ROUGE**, et c'est le comportement correct :
la violation est réelle, elle n'était pas regardée.

## 5. Contrôle négatif FERMÉ — concluant

`tools/cave_roof_sabotage.py`, sabotage par **déplacement de sommets**, zéro
triangle retiré.

    soudure    : 54810 -> 10045 sommets (l'export glTF les dedouble par face)
    integrite AVANT : 0 arete de bord, 0 non-manifold
    1. AVANT   : cumul 1.481 m sur un vide de 1.63 m  -> VERT
    2. SABOTAGE: 35 sommets deplaces ; 0 triangle retire
                 integrite APRES : 0 arete de bord, 0 non-manifold
    3. MESURE  : toit 1.481 -> 0.682 m (-0.798 m) ; vide 1.63 -> 2.43 m
    4. APRES   : ROUGE (0.682 < 0.80)
    5. RESTAURE: empreinte 950699a3... identique a l'originale : OUI ; VERT

Deux essais ratés conservés dans le code, avec leur cause :

1. **contrôle d'intégrité sur maillage importé** — 54 812 « arêtes de bord »
   annoncées sur un solide fermé, parce que l'export glTF dédouble les sommets par
   face. Un comptage d'arêtes par indices y est indéfini. Parade : souder avant de
   mesurer la topologie ;
2. **abaisser le toit** — le vide descend avec lui (1,63 → 1,08 m) et le sabotage
   se combat lui-même ; poussé plus loin il aurait fait tomber le vide sous le
   seuil de qualification, retirant la colonne du contrôle au lieu de l'y faire
   rougir — un faux vert par **disparition du sujet**. Parade : remonter le
   plancher du banc, les deux effets vont alors dans le même sens.

## 6. Ce qui n'a PAS été fait

* **temps 2, attribution par étape** — non exécutée ;
* **temps 3 et 4, les trois corrections** — non tentées.

Non par manque de temps mais parce que la cible a changé de nature : corriger
`(0,50 ; 5,80)` à 0,80 m laisserait 167 autres plaques, et la géométrie de
référence en porte 271. Le niveau à atteindre est un arbitrage du lead, pas
d'un agent. Aucune géométrie n'a été modifiée.
