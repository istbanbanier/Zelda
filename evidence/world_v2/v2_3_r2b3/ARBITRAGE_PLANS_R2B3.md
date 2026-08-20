# R2B.3 — registre d'arbitrage du lead

**Type de document : VIVANT** jusqu'au verdict visuel, **HISTORIQUE** ensuite.

Base exigée `1491ee466c6b81e23d53655377376164e45da1b3`. Trois voies :
**A** débris de ferme · **B** instrumentation d'ISS-059 · **C** audit indépendant,
zéro géométrie de production.

---

## Décision 1 — le conteneur était revenu en arrière ; fast-forward, pas reset

Au pré-vol, `HEAD` local pointait sur `c44f430b` — la base de **R2B.2**, soit
**64 commits en retard** sur le distant. Le conteneur avait été recréé sur un
état plus ancien que le travail poussé.

Vérifié avant tout geste : `git merge-base --is-ancestor c44f430b origin/…` →
vrai. Le local était **seulement en retard**, aucune divergence. Résolu par
`git merge --ff-only`, strictement additif : aucun rebase, aucun reset, aucun
force-push. La base exigée a ensuite été atteinte au SHA près.

C'est la règle 2 de `COMMENT_TRAVAILLER_ENSEMBLE` en action : **on vérifie
l'état du dépôt entier, pas ce que l'arbre de travail montre.** Un `git log`
lu sans le `fetch` aurait fait croire que R2B.2 n'existait pas.

## Décision 2 — l'instrument du portail appartient au lead, pas à la voie mesurée

`hexa` n'avait **aucune implémentation commitée** : la mesure de R2B.2 était
ad hoc côté lead, et l'audit indépendant n'a rien poussé. Le portail d'ISS-060
n'était donc pas rejouable — un seuil sans instrument n'est pas un seuil.

`tools/mesure_boititude.py` est écrit **avant le dispatch**, par le lead.
L'agent A le CONSOMME et n'a pas le droit d'y toucher. Un portail dont le sujet
est propriétaire n'est pas un portail.

## Décision 3 — le liant reste `hexa`, et c'est le prédicat le plus LÂCHE

Trois prédicats emboîtés sont publiés ; **un seul est liant**.

| prédicat | définition | statut |
|---|---|---|
| `hexa` | 12 triangles + 8 sommets soudés | **LIANT, plafond 25 %** |
| `equidistance` | + 8 coins à 2 % du centroïde | publié |
| `droite` | + 6 directions de normale signée | publié |

Le liant est **le plus lâche des trois, à dessein**. Un prédicat strict se
contourne en bougeant les coins : une boîte déformée cesse d'être « droite »
sans cesser d'être une boîte à l'écran — c'est exactement ce que fait
`moellon()`, qui rend 100 % sous `hexa` et 0 % sous l'équidistance. Faire
tomber `hexa` oblige à **changer la topologie**, pas la métrique.

Le seuil de 25 % est repris tel quel de R2B.2. **Aucun seuil n'est relevé.**

## Décision 4 — sept planchers anti-contournement, chiffrés AVANT le dispatch

Il y a trois façons de faire tomber un chiffre sans traiter le sujet :
supprimer, rétrécir, pulvériser. Chacune a son plancher, mesuré sur la base :

| plancher | valeur | ce qu'il ferme |
|---|---|---|
| composantes par tas | ≥ 9 | suppression |
| aire totale | ≥ 3,20 m² (A) · 3,35 m² (B) — 80 % de la base | rétrécissement |
| aire médiane de composante | ≥ 0,08 m² | pulvérisation |
| arête minimale | ≥ 0,03 m | bruit sous-pixel |
| emprise X/Z, hauteur Y | ±20 % · ±30 % | déplacement de l'implantation |
| budget ferme | ≤ 4 500 triangles | débordement |
| UV0 + `gltf_inspect` | 100 % · 0 avertissement | régression de matière |

Ils sont posés **avant** de connaître la solution d'A, et ils entrent dans son
test. La directive interdit explicitement « les détails sous-pixel destinés
seulement à tromper le test » ; un interdit qui n'est pas mesuré n'est pas un
interdit.

## Décision 5 — l'autotest précède la mesure, et il a déjà mordu

`mesure_boititude.py --autotest` fabrique cinq cas analytiques et exige le bon
verdict sur chacun. Il a **échoué à son premier lancement, avant la première
mesure réelle** : `droite` rendait faux sur un **cube unité**, parce que la
grappe de normales utilisait `abs(dot)` et rangeait +X avec −X — un pavé
rendait 3 directions au lieu de 6.

C'est le deuxième bug d'instrument attrapé par un cas témoin dans ce dossier.
Le premier, en R2B.2, avait été attrapé par l'**invraisemblance du résultat**
(0,0 % de boîtes sur un maillage qui en est plein) et non par le code. La leçon
est passée dans l'outil : l'autotest est obligatoire au journal.

Recoupement, une fois l'instrument sain : il reproduit **au dixième** deux
mesures antérieures écrites séparément — 79,6 % (audit R2B.2) et 42,1 % (lead
R2B.2), `Debris_A/B` à 96,8 %. Trois implémentations indépendantes, mêmes
chiffres.

## Décision 6 — huit caméras reprises à l'identique, trois visées sur du mesuré

La directive impose de ne pas remplacer un cadrage défavorable. Les huit vues
de R2B.2 (`ferme_seuil`, `ferme_laterale`, `ferme_arriere`, `ferme_facade`,
quatre orbites) sont **recopiées champ par champ**, ce qui donne l'A/B sans
aucun recadrage.

Les trois vues nouvelles sont visées sur une **emprise sondée**, pas sur une
lecture du script de placement : `tools/godot/sonde_aabb_lieu.gd` rend
`Debris_A` centré (−51,437 · 5,512 · 91,746) et `Debris_B` (−49,593 · 5,343 ·
91,800). En R2B.1, cinq caméras posées de mémoire visaient deux fois sous le
terrain et trois fois le pied au lieu du fût ; la chaîne ancre → yaw → position
locale est trop longue pour être refaite de tête.

`debris_rasant` est ajoutée délibérément : **c'est l'angle qui démasque un
pavé**. Un fragment vu de très bas montre une arête et une facette ; un pavé
montre deux rectangles.

## Décision 7 — la baseline AVANT est prise avant l'intégration, ou elle est perdue

Les trois vues nouvelles n'existent pas dans les preuves R2B.2. Leur panneau
« avant » ne peut être capturé qu'à l'état actuel, **avant** que la géométrie
d'A n'entre. Capturé d'abord, arbre propre, `repo_dirty: false`.

Corollaire appliqué pendant la capture : **aucun fichier n'est créé dans
l'arbre tant qu'un manifeste s'écrit.** En R2B.2, un script non suivi avait
rendu `repo_dirty: true` au milieu d'un lot ; le hook l'a signalé avant l'écriture.

## Décision 8 — trois cadrages remplacés parce qu'ils ne MONTRENT PAS le sujet

Le premier lot AVANT est sorti à 11/11, `repo_dirty: false`, `glb_ferme`
`9c7b94e1…` — techniquement irréprochable. **Inspecté à taille réelle, il est
inutilisable sur trois vues.**

| vue | ce que l'image montre réellement |
|---|---|
| `debris_a_proche` | un gros plan du **mur** ; le tas est un coin sombre en bas à droite |
| `debris_b_proche` | idem |
| `debris_rasant` | l'œil à 0,62 m au-dessus du sol est **dans l'herbe** ; les brins occultent le tas |

Cause, et elle est de moi : j'ai visé les caméras à l'est des tas **en regardant
vers l'ouest**, donc vers la maison. À 3 m avec 45° de champ, le mur remplit le
cadre et un tas de 0,68 m de haut tombe au bord. J'avais sondé l'emprise de la
cible et **pas ce qu'il y avait derrière** — la sonde a corrigé la moitié du
problème et m'a donné confiance pour l'autre moitié.

Le terrain porte en outre une herbe haute de 0,6 à 0,8 m : toute caméra basse
est perdue d'avance sur un objet de cette taille.

**Ce remplacement n'est pas celui que la directive interdit.** L'interdit vise
le cadrage **défavorable** qu'on échangerait contre un plus flatteur ; ici les
trois vues ne montrent pas le sujet du tout. Les huit vues reprises de R2B.2,
elles, ne bougent pas d'un champ — `ferme_seuil` compris, qui reste le cadrage
sur lequel un portail a déjà échoué.

Deux garanties : le recadrage est décidé **avant** toute intégration de la voie
A, donc il ne peut pas être ajusté à un résultat ; et les essais de cadrage
sont capturés **hors du dépôt** (`/tmp`), pour qu'aucune image intermédiaire ne
puisse être prise plus tard pour une preuve.

Nouvelle règle tirée de l'incident : **une caméra n'est acquise qu'après avoir
été regardée à taille réelle.** Une capture qui sort à 11/11 avec un manifeste
propre ne prouve que le fonctionnement de l'outil.
