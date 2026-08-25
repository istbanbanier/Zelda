# ITERATIONS_C — Champ des mille fleurs, lot 1.R (V2.3-B)

Base : `de43152` (« La Porte des fleurs », état de la première corrective,
captures de référence `evidence/.../voie_c/apres4/`, commit `0894bd5`).
Méthode §9 : chaque itération s'écrit AVANT modification.

---

## Itération R1 — remplir le PROCHE et structurer les nappes

**Défaut** (lu à taille réelle sur `apres4/flower_field_joueur.png`) : le
champ ne « explose » pas. Les 40 % bas du cadre joueur sont de l'herbe nue ;
la seule couleur proche est la coulée jaune du bord gauche. Les trois nappes
lisent comme des taches de semis, sans phrases ni respirations, toutes à la
même hauteur. Sur `apres4/flower_field_identite.png` le même défaut : la
couleur occupe une bande médiane et laisse le bas et la droite en vert nu.

**Cause supposée**, en trois points mesurés sur la géométrie du fichier :

1. la clairière d'œil `OEILS_DEGAGES[0]` faisait **2,1 m de rayon** autour de
   la position exacte de la caméra joueur — elle vidait tout ce que le bas du
   cadre regarde ;
2. **aucune nappe ne descendait sous ~6 m de la caméra.** Projection de la
   « poche de premier plan » `Nappe_jaune_avant` (local 6,6 · 3,4) dans le
   repère de la vue joueur : profondeur a = 3,23 m, écart b = 3,98 m, donc
   abscisse écran b/(1,13·a) = **1,09 — hors cadre à droite**. Elle ne servait
   à rien depuis la seule vue qui juge ;
3. l'algorithme de nappe tirait un centre au hasard et y posait 3 à 8 fleurs
   en boucle : à faible cible cela fait des taches, à forte cible les taches
   se recouvrent et **convergent vers un semis uniforme**. Densifier sans
   changer la structure aurait effacé les phrases au lieu de les affirmer.

**Levier** (quatre gestes, un seul fichier) :

- `OEILS_DEGAGES` 2,1 → **1,25 m** et 1,0 → 0,8 m. RÉDUIT, PAS FERMÉ, et la
  justification est vérifiée, pas supposée : ces discs ne sont exigés par
  aucun contrat. D4 ne teste que des **colliders** contre les six caméras du
  bâtisseur (`intersect_ray` masque 1) et les nappes n'en portent aucun ; la
  conception (`CONCEPTION_champ.md`) ne les mentionne pas ; ils ont été
  inventés à la première corrective comme garde-fou de composition. Une
  respiration au pied de l'observateur reste juste — d'où 1,25 m et non 0.
- les nappes deviennent des **LOBES** (`LOBES_JAUNE`, `LOBES_BLANC`,
  `LOBES_BLEU`), placés par le calcul de projection ci-dessus : jaune à
  x_écran ≈ -0,9 / -0,30 / +0,77, blanc au cœur profond + un lobe ramené en
  avant à droite de la voie, bleu lointain + un accent juste après la Porte.
- chaque lobe est creusé de **CŒURS** denses écartés d'au moins 0,82 × la
  somme de leurs rayons : le vide entre eux est une contrainte, pas un
  hasard. C'est la respiration, et les phrases.
- **strate haute** : une fleur sur six à 1,12-1,50 × l'échelle du kit, pour
  donner un profil au champ ; et les fleurs lappent enfin le pied des stèles
  (rayon d'écart 1,35 → 0,85 et 1,05 → 0,70, au-dessus des demi-diagonales
  0,45 et 0,34 des colliders).
- cibles 560 → **960 fleurs** (jaune 430, blanc 380, bleu 150).

**Changement attendu dans les pixels** : bas du cadre joueur occupé par du
jaune à hauteur de genou des deux côtés de la voie dallée ; une masse blanche
plus proche à droite ; un accent bleu derrière la Porte ; du vert franc entre
les masses, et la voie qui reste la seule ligne claire continue.

**Caméra qui doit le montrer** : `flower_field_joueur` d'abord (c'est elle qui
porte le défaut), `flower_field_identite` pour vérifier que les masses se
séparent encore vues de haut, `flower_field_gp_chemin` pour le couloir.

**Contrôle de budget** : compte d'instances MultiMesh avant/après, et D7
(micro : 12 modules / 30 nœuds visuels / 6 collisions).

### Mesure AVANT (`de43152`, arbre propre, `tools/godot/lot1r_sonde_champ.gd`)

```
nœud                        instances    aire_xz    h_moy
Voie_dalles_carrees                20      294.3     0.12
Voie_dalles_rondes                 20      295.0     0.09
Nappe_blanche                     300      156.0     0.44
Nappe_jaune                       150       78.7     0.46
Nappe_jaune_avant                  40       11.9     0.46
Nappe_bleue                        70       32.7     0.43
Ourlet_herbes                      28      363.8     0.73
TOTAL INSTANCES MULTIMESH : 628      (dont 560 fleurs)
EMPRISE DES INSTANCES     : 21.4 x 20.1 m (local)
BUDGET micro (D7) : modules 4/12 ok · visuels 13/30 ok · collisions 3/6 ok
```

Lecture : toutes les fleurs mesurent 0,43-0,46 m — **une seule strate**, d'où
la moquette. Et 560 fleurs sur ~250 m² d'ellipses font 2,2/m² : le semis, pas
la masse.

### Vérification à sec AVANT capture (aucun moteur)

L'algorithme de lobes/cœurs a été rejoué en Python avec un autre générateur
aléatoire — non pour prédire l'image, mais pour vérifier qu'aucun paramètre
n'est dégénéré (boucle de rejet qui n'aboutit pas, cible jamais atteinte,
emprise qui explose) avant de dépenser une prise du verrou partagé :

```
JAUNE lobe(-5,0;+6,6) aire 56,5 m²  demande 258  posées 258  cœurs 6  4,6/m²
JAUNE lobe(+3,0;+6,3) aire 22,6 m²  demande 103  posées 103  cœurs 3  4,6/m²
JAUNE lobe(+5,7;+2,9) aire 15,1 m²  demande  69  posées  69  cœurs 2  4,6/m²
BLANC lobe(-2,4;-5,8) aire 57,2 m²  demande 276  posées 276  cœurs 5  4,8/m²
BLANC lobe(+3,4;-2,2) aire 21,7 m²  demande 104  posées 104  cœurs 3  4,8/m²
BLEU  lobe(-7,4;+0,6) aire 29,0 m²  demande 115  posées 115  cœurs 3  4,0/m²
BLEU  lobe(-3,0;+1,2) aire  9,0 m²  demande  35  posées  35  cœurs 2  3,9/m²
TOTAL 960 fleurs · emprise des fleurs 18,0 × 17,4 m
```

L'emprise des fleurs RÉTRÉCIT (21,4 → ~18 m sur X) alors que leur nombre
augmente : c'est voulu, la capture de silhouette se cadre sur la plus grande
largeur et son plancher d'occupation avait déjà été raté une fois.

Le lobe de premier plan a été replacé après ce calcul : (1,9 · 7,3) tombait à
x_écran +0,81, donc au bord ; (3,0 · 6,3) donne a = 2,55 m et x_écran +0,21 —
plein bas du cadre. Un troisième œil dégagé (3,4 · 4,6 · 1,1 m) est ajouté pour
la lentille du gros plan `gp_chemin`, que ce lobe recouvre désormais.

### Mesure APRÈS R1 (`5b93280`, `repo_dirty: false`, `c3_iter1/`)

```
nœud                        instances    aire_xz    h_moy
Voie_dalles_carrees                20      294.3     0.12
Voie_dalles_rondes                 20      295.0     0.09
Nappe_blanche                     380       83.5     0.46
Nappe_jaune                       430      130.6     0.49
Nappe_bleue                       150       33.8     0.47
Ourlet_herbes                      30      355.5     0.72
TOTAL INSTANCES MULTIMESH : 1030     (dont 960 fleurs)   [avant : 628 / 560]
EMPRISE DES INSTANCES     : 21.2 x 18.6 m   [avant : 21.4 x 20.1]
BUDGET micro (D7) : modules 4/12 ok · visuels 12/30 ok · collisions 3/6 ok
```

Un nœud visuel de MOINS qu'avant (12 contre 13) pour 400 fleurs de plus : la
poche hors cadre a fusionné dans la nappe jaune. Parse ciblé RC = 0.

### Ce que je VOIS, à taille réelle (R1)

`flower_field_joueur` — **VISIBLE**, et c'est le changement attendu. Le bas du
cadre porte une masse jaune dense à hauteur de genou ; une seconde masse jaune
occupe le bord droit ; la voie dallée passe ENTRE les deux et se lit enfin
comme un couloir de traversée. Bleu et blanc sont des bandes franches et non
plus un saupoudrage. Les deux stèles ont cessé d'être le sujet.

`flower_field_gp_nappe` — **VISIBLE** : le cœur blanc est un tapis continu, là
où `apres4` montrait des fleurs espacées sur du vert.

`flower_field_identite` — **VISIBLE** : deux masses jaunes, une bande bleue
dense, une bande blanche. Le champ a une forme.

`flower_field_gp_chemin` — **VISIBLE** sur la moitié haute (bleu et blanc
densifiés) ; la moitié basse est inchangée.

**Trois défauts restants, lus sur les mêmes images :**

1. **Le triangle de la fourche est vide.** Dans la vue joueur, une bande verte
   nue traverse tout le cadre entre la masse de premier plan et les nappes du
   milieu ; `gp_chemin` montre la même chose par en dessous. En coordonnées
   locales c'est le triangle entre les trois brins, autour de (1,2 · 4,2) — à
   2,0 m de chaque branche, donc plantable sans toucher au couloir.
2. **Vue identité : trois bandes PARALLÈLES.** Blanc, bleu et jaune s'étirent
   tous selon le même axe. La cause est mécanique et se lit dans les données :
   les cinq lobes sont des ellipses plus larges en X qu'en Z. Ce n'est pas un
   défaut de couleur, c'est un défaut de forme des lobes.
3. Le coin droit du cadre joueur garde un coin vert entre la voie et le lobe
   blanc profond — le blanc s'arrête trop loin.

---

## Itération R2 — casser les bandes, planter la fourche

**Défaut** : les trois ci-dessus.

**Cause supposée** : (1) aucun lobe n'occupe le triangle de la fourche ;
(2) toutes les ellipses de lobe sont allongées selon X, donc toutes les masses
s'étirent dans la même direction ; (3) `BLANC_avant` est à 9,7 m de l'œil et
laisse un coin vert devant lui.

**Levier** :

- un lobe BLANC « île de la fourche » en (1,2 · 4,2 · 2,0 · 1,8) — mesuré à
  2,00 / 2,05 / 1,99 m des trois brins, donc il lappe le couloir sans le
  fermer. Blanc et non bleu : la même couleur répétée à deux profondeurs
  fabrique de la profondeur, une quatrième couleur ferait le hachis que la DA
  refuse ;
- `BLEU_loin` passe de (3,3 × 2,8) à (2,6 × 3,4) — **allongé selon Z** : c'est
  ce qui casse le parallélisme, et cela resserre en prime son emprise ouest ;
- `BLANC_avant` avance de (3,4 · -2,2 · 3,0 · 2,3) à (3,9 · -1,2 · 3,3 · 2,5) ;
- cible blanche 380 → 450, pour tenir la densité (~4,8/m²) sur une aire qui
  passe de 79 à 94 m².

**Changement attendu dans les pixels** : la bande verte du milieu du cadre
joueur se referme sur une masse blanche à mi-distance ; en vue identité, la
tache bleue devient verticale au lieu d'être une barre horizontale, et les
trois masses cessent d'être parallèles.

**Caméra qui doit le montrer** : `flower_field_joueur` (bande du milieu),
`flower_field_identite` (parallélisme), `flower_field_gp_chemin` (couloir
toujours ouvert — c'est le risque de ce geste).
