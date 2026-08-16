# R2a-3.5.4 — LE PORTAIL D'ORACLE. Ce qui a été mesuré, et ce qui reste ouvert.

**Agent B, 2026-08-16.** Worktree `b_portail`, détaché sur `1580711`.
Aucun `push`. Aucun seuil modifié. Aucune capture.

---

## 1. LES DEUX ÉCARTS DE REPRODUCTION ONT UNE SEULE CAUSE

On me demandait de reproduire **6/7** sur le candidat et **2/7** sur R2a-3.4.
Je ne reproduis ni l'un ni l'autre — et l'écart est le résultat important.

| géométrie | attendu | **obtenu, avec mon `RC`** |
|---|---|---|
| candidat `cc3596c5`, pas 0,10 | 6/7, témoin ROUGE sur `C4` | **7/7 CONFORME, `RC=0`** |
| R2a-3.4 `8bf1a1b3`, pas 0,10 | 2/7, cinq `INEXPLOITABLE` | **0/7, `RC=1`** — témoin `BLOQUÉ`, cinq `INEXPLOITABLE`, `roche_flottante` `BLOQUÉ` |

Journaux : `reproduction/candidat.log` · `reproduction/r2a34.log`, chacun avec
son `RC=` écrit par la commande elle-même. La reproduction R2a-3.4 a été jouée
avec l'oracle **remis à son état d'origine** (`git checkout --`), pour ne pas
mesurer mes propres modifications.

### La cause : le couple (maillage, repères) n'était pas nommé

L'oracle lit `MODELE_*` dans `scripts/world_v2/poi/waterfall_cave_place.gd`
**du dépôt qui le contient**. Or ces repères ont été re-dérivés à R2a-3.5.2 :

```
tronc a4e91dc   MODELE_SALLE (1,05 ; 0,22 ; -6,25)   MODELE_NICHE (-1,20 ; 0,43 ; -8,20)
socle 1580711   MODELE_SALLE (2,62 ; 0,09 ; -2,58)   MODELE_NICHE ( 2,78 ; 0,50 ; -4,09)
```

Plus de quatre mètres d'écart. L'intégrateur mesurait **depuis le tronc**, moi
depuis le socle. Ni l'un ni l'autre ne l'écrivait, et rien ne le criait.

**Matrice complète, mesurée :**

| géométrie | repères | verdict | `RC` |
|---|---|---|---|
| candidat `cc3596c5` | socle (**les siens**) | VERT, deux témoins dedans | 0 |
| candidat `cc3596c5` | tronc | **`C4` : MODELE_NICHE dehors** | 1 |
| R2a-3.4 `8bf1a1b3` | tronc (**les siens**) | VERT, deux témoins dedans | 0 |
| R2a-3.4 `8bf1a1b3` | socle | graine dans la ROCHE → `BLOQUÉ` | 3 |

`C4` n'apparaît sur **aucun** couple cohérent. Le `2/7` du tronc = `temoin` +
`roche_flottante`, les deux seuls contrôles que la fabrique produisait sans
booléen ; mon `0/7` depuis le socle ajoute simplement le refus légitime de la
graine dans la roche.

---

## 2. `C4` TRANCHÉ PAR LA MESURE — et ce n'était aucune des quatre lectures

Quatre lectures étaient en lice. Toutes ont été testées, dans l'ordre du moins
cher au plus cher.

**Lecture 1 — mauvais côté de la barrière : écartée sans calcul.** Barrière à
`y = −1,15`, témoin niche à `y = 4,09` : 3,7 m *derrière* le plan.

**Lecture 2 — placement de la barrière : écartée par mesure.** J'ai dérivé la
bouche (§3) et rejoué : `C4` **persiste** avec la barrière dérivée sous repères
du tronc, **disparaît** sous repères du socle. Le placement n'y est pour rien.
`bouche/candidat_barriere_DERIVEE_reperes_*.log`.

**Lecture 3 — amputation réelle de la cavité : écartée par mesure.** Le témoin
niche du tronc, dans la géométrie candidate, est **dans la ROCHE PLEINE** —
parité impaire des traversées, aucun sol ni plafond au-dessus de lui :

```
MODELE_NICHE_tronc (-1,200 ; 8,200 ; 0,730) : ROCHE   sol -   plafond -
MODELE_NICHE_socle ( 2,780 ; 4,090 ; 0,800) : AIR     sol 0,492   plafond 2,233
```

Mesure par rayon vertical, indépendante de toute grille et de tout pas.
`bouche/nature_temoin_tronc.log`.

**Lecture 4 — « il n'existe pas de cavité scellée sur une géométrie percée » :
écartée par mesure, pour ce cas précis.** Dans le run candidat + tronc à 0,10,
**`C3` n'a pas tiré** (`grep -c` = 0) et la composante de la graine faisait
**55,36 m³ d'emprise bornée** : une cavité scellée existait bel et bien.

### Le discriminant à trois genres

| géométrie | genre | repères | `C4` ? |
|---|---|---|---|
| `cc3596c5` | **1** | les siens | **non** |
| `c184c8dc` | **0** | les siens | **non** |
| `8bf1a1b3` (R2a-3.4) | **2** | les siens | **non** |
| `cc3596c5` | 1 | ceux d'une autre révision | **oui** |

`C4` ne suit pas le genre. Il suit la cohérence du couple. **La cause est le
croisement d'une géométrie et de repères d'une autre révision.**

### Reproduit indépendamment par l'intégrateur, sur une quatrième géométrie

L'intégrateur est tombé dans le même piège par accident, en lançant l'oracle
sur `c184c8dc` **depuis le tronc** : `C4` ROUGE. Depuis le worktree de l'agent A,
même GLB aux octets près : VERT. Et dans les **deux** runs,
`composantes d'espace (sans barrière) : 2` — l'étanchéité était établie des deux
côtés, seul le témoin divergeait.

**Un `C4` peut donc coexister avec une géométrie parfaitement saine.** C'est ce
qui rend le cas insidieux, et c'est pourquoi il devait sortir en `BLOQUÉ`.

Rejoué avec mon oracle corrigé, ce cas exact rend désormais :

```
composantes d'espace (sans barriere) : 2
temoin MODELE_NICHE (-1,20 ; 8,20 ; 0,73) : DEHORS  [ROCHE]
BLOQUE : ... rien n'a ete ampute, le couple (maillage, reperes) est incoherent
RC=3
```

`c184c8dc/reperes_tronc.log`.

### Le défaut que cela révèle dans l'oracle, et sa correction

Le message de `C4` — « le scellement ampute la cavité » — était un **mauvais
diagnostic**. L'oracle appliquait déjà la bonne lecture à la **graine** (« une
graine dans la roche rendrait ÉTANCHE sans rien prouver ») et ne l'appliquait
pas aux **témoins**. Cette asymétrie a produit un rouge crédible et faux
pendant toute une passe.

Corrigé : un témoin dans la ROCHE sort en **`BLOQUÉ`** (couple incohérent), un
témoin dans l'AIR mais déconnecté reste **`C4` ROUGE** (vraie amputation).

**Et j'ai prouvé que `C4` peut encore rougir** — sinon j'aurais transformé un
contrôle en formalité. Barrière forcée à `y = 3,00`, entre la salle et la
niche : `C4` tire, témoin marqué `[AIR]`, `RC=1`.
`bouche/falsifiabilite_C4_barriere_3m.log`.

---

## 3. LA BARRIÈRE EST DÉRIVÉE, PLUS DÉCLARÉE

`Y_BOUCHE_DEFAUT = -1.15` était une constante héritée de deux oracles
condamnés. Le contrat §2.1 exige une position **dérivée** et **indépendante du
verdict qu'elle sert**.

`tools/cave_oracle_bouche.py` découpe le massif en tranches `y`, calcule la
connexité **strictement 2D** dans chaque tranche, et suit la section close de
la galerie vers l'avant depuis `MODELE_SALLE`. La bouche est le plan qui sépare
la dernière tranche close de la première tranche ouverte.

Le critère d'arrêt — « close dans sa tranche » — est **local et 2D** ;
`C3`/`C4` sont **globaux et 3D**. Aucun seuil : « touche le bord de sa tranche »
est un fait combinatoire.

```
dernière tranche CLOSE   : j=26  y=-1,685
première tranche OUVERTE : j=25  y=-1,785
BOUCHE DÉRIVÉE : y = -1,7348   (barrière j=25, épaisseur nulle)
écart à la constante historique : -0,5848 m
```

Le profil complet des 44 tranches est publié (`bouche/bouche_candidat_pas010.log`).
Corroboration indépendante : `MODELE_SEUIL_DEHORS` est à `y = −1,60`, soit
0,13 m **derrière** la bouche dérivée — ce qu'un seuil doit être. La constante
`−1,15`, elle, tombait 0,45 m **à l'intérieur** de la galerie.

Épaisseur nulle conservée : la barrière coupe les adjacences `y` d'**une seule**
couche et ne masque aucune adjacence `x` ou `z`.

### Le relèvement des témoins est désormais un décalage nommé et vérifié

`TEMOIN_RELEVEMENT_M = 0.30`, avec son motif écrit. Et `cave_oracle_bouche.py`
**mesure** sol et plafond à l'aplomb de chaque repère à chaque exécution :

```
MODELE_NICHE (2,780 ; 4,090 ; 0,500) : AIR   sol 0,492   plafond 2,233
```

Le relèvement est donc vérifiable, pas supposé.

---

## 4. LA FABRIQUE EST DEVENUE INDÉPENDANTE DE LA GÉOMÉTRIE — deux causes, pas une

Les trois nombres clés étaient des constantes du candidat
(`--graine 2.62,2.58,0.99`, `--point 1.50,-0.40,2.00`, `--rayon 0.30`).
`tools/cave_oracle_placement.py` les dérive maintenant du maillage visé :
graine depuis les repères qui accompagnent la géométrie (nature AIR vérifiée),
rayon depuis le **dégagement mesuré** aux six axes, longueur depuis la diagonale
AABB, poche au point de roche le plus profond, bloc au-dessus de l'AABB.

Mais les `INEXPLOITABLE` avaient **deux** causes distinctes, et le jitter
déterministe que j'avais prévu ne traitait ni l'une ni l'autre.

### Cause A — le maillage n'était pas soudé

Six tentatives avec jitter, chiffres **rigoureusement identiques**. Ce n'était
donc pas une coïncidence de solveur. Mesure à l'import :

```
R2a-3.4   V=55542 E=57702 F=19954   bords libres 55542
candidat  V=54810 E=57541 F=20090   bords libres 54812
```

Un GLB indexe **par primitive** : le maillage arrive en soupe de triangles. Le
booléen opérait dessus, la soudure n'arrivait qu'**après**. Soudé d'abord, tout
devient déterministe.

### Cause B — `use_self` fabriquait le défaut qu'il prétendait corriger

Matrice sur R2a-3.4, entrée soudée, sortie brute du booléen :

| `use_self` | `hole_tolerant` | bords libres | non-manifold |
|---|---|---|---|
| False | False | **0** | **0** |
| False | True | **0** | **0** |
| True | False | 0 | **10** |
| True | True | 0 | **10** |

Et le « ménage » d'après booléen était **nuisible** : c'est `remove_doubles` qui
créait le bord libre unique condamnant cinq sabotages.

```
après booléen (aucun ménage)   bords 0   non-manifold 10
+ remove_doubles 1e-5          bords 1   non-manifold  5
```

### Cause C — trouvée sur la géométrie de l'agent A, et c'est la plus intéressante

Après ces deux correctifs, R2a-3.4 passait 8/8 — et `c184c8dc` échouait sur
**tous** les booléens, à toutes positions (toit, plancher, parois, poche
profonde, bosse extérieure), **invariant aux 24 configurations** de
(drapeaux × jitter).

Test décisif : un booléen avec un cube à **500 m**, donc sans aucune
intersection. Sur un solide valide il doit être neutre.

```
c184c8dc  V=10038 F=20072 bords 0  ->  V=10038 F=20071 bords 3
cc3596c5  V=10045 F=20090 bords 0  ->  V=10045 F=20089 bords 3
R2a-3.4   V=9975  F=19954 bords 0  ->  INCHANGÉ
```

**Les deux géométries issues de l'enveloppe R2a-3.5.2 portent une face que le
solveur exact supprime de lui-même**, ouvrant un trou de trois arêtes — avant
qu'on lui demande de couper quoi que ce soit. C'est la vraie origine des
« 3 bords libres et 82 arêtes à trois faces » rapportés par la passe
précédente : **les 3 viennent de la source, les 82 du drapeau `use_self`.**

Parade générique : dissoudre soi-même les faces dégénérées puis reboucher le
trou. Sommets et faces retrouvent exactement leur compte — l'opération est
neutre — et le booléen sans intersection redevient neutre.

**C'est un défaut des sources, pas de ma fabrique**, et il vaut d'être signalé
à l'agent A : `c184c8dc` est fermée, manifold et de genre 0, mais elle n'est
pas propre au CSG exact.

---

## 5. RÉSULTAT DE LA BATTERIE, AU PAS EXIGÉ DE 0,06 m

| contrôle | attendu | R2a-3.4 `8bf1a1b3` | `c184c8dc` |
|---|---|---|---|
| `temoin` | VERT | **VERT** | **VERT** |
| `placebo` | VERT | **VERT** | **VERT** |
| `toit` | ROUGE | **ROUGE** 0,280 m | **ROUGE** 0,280 m |
| `paroi_est` | ROUGE | **ROUGE** 0,280 m | **ROUGE** 0,280 m |
| `paroi_ouest` | ROUGE | **ROUGE** 0,280 m | **ROUGE** 0,280 m |
| `plancher` | ROUGE | **ROUGE** 0,280 m | **ROUGE** 0,280 m |
| `poche` | ROUGE | **ROUGE** | **ROUGE** |
| `roche_flottante` | ROUGE | **ROUGE** | **ROUGE** |
| | | **8/8, `RC=0`** | **8/8, `RC=0`** |

**Tentatives : 1 pour les huit contrôles, sur les deux géométries.** Aucun
`INEXPLOITABLE`, aucun `SKIP`, aucun résultat obtenu sur un maillage ouvert.
Restauration byte-identique vérifiée des deux côtés.

Fermeture prouvée **avant** chaque sabotage (contrat §3 étape 1) et **après**,
par deux codes indépendants : bmesh dans Blender pour la reprise, soudure par
position sur le GLB exporté pour le verdict.

### La troisième géométrie, `cc3596c5`, ne peut pas être verte — et c'est correct

Elle est **percée** (genre 1). Au pas exigé de 0,06 m l'oracle rend `ROUGE`
`RC=1` sur la source elle-même, motif `C3`. Le 7/7 que j'ai reproduit était au
pas de 0,10 m, où le défaut est sous la résolution.

J'ai donc ajouté un garde-fou que la batterie n'avait pas : **le verdict de la
source est mesuré AVANT tout sabotage.** Si la source n'est pas verte, les six
contrôles attendus ROUGE deviennent `NON INFORMATIF` — ils rougiraient pour le
défaut de la source, pas pour le sabotage.

Sans ce garde-fou la batterie était **un test qui ne peut pas échouer** : six de
ses huit contrôles attendent ROUGE, donc une source déjà cassée les valide tous.

Résultat obtenu, `batterie/candidat_pas006.log`, `RC=1` :

| contrôle | attendu | obtenu | état |
|---|---|---|---|
| `temoin` · `placebo` | VERT | **ROUGE** | NON CONFORME |
| les six sabotages | ROUGE | ROUGE | **NON INFORMATIF** |

> MOTIF PREMIER : la source est ROUGE à ce pas. La batterie ne peut pas
> démontrer la falsifiabilité de l'oracle sur une géométrie déjà défectueuse.

**La fabrique, elle, a réussi les huit types en 1 tentative sur les trois
géométries** — y compris la percée. L'indépendance vis-à-vis de la géométrie est
donc établie sur trois genres (0, 1, 2), indépendamment du verdict de l'oracle.

---

## 6. LA BATTERIE SAIT ÉCHOUER DANS LES DEUX SENS — et je le prouve

C'était la mise en garde qui m'était adressée. Trois mécanismes, chacun
démontré :

1. **`placebo`** — une bosse fermée soudée à la peau extérieure. Le maillage
   change vraiment (sha et nombre de faces différents du témoin), aucun défaut
   n'est créé, attendu **VERT**. C'est le seul contrôle capable de faire échouer
   la batterie pour **sur-sensibilité**. Il passe VERT sur les deux géométries
   saines.
2. **`C4` forcé** — barrière à `y = 3,00`, témoin `[AIR]` déconnecté, `C4`
   tire, `RC=1`. Le contrôle mord encore après ma correction.
3. **verdict de source mesuré d'abord** — une source rouge ne peut plus produire
   un bon score.

Et la batterie a **réellement échoué** en cours de route, deux fois, sur des
défauts que je n'avais pas prévus : `0/7` sur R2a-3.4, puis `2/8` sur
`c184c8dc`. Ces deux échecs sont conservés intégralement
(`batterie/r2a34_pas006.log`, `c184c8dc/batterie_pas006.log`) — ce sont eux qui
ont mené aux causes B et C.

---

## 7. RAFFINEMENT ADAPTATIF — écrit, et NON VÉRIFIÉ

`tools/cave_oracle_raffinement.py` : inondation globale à 0,06 m, recherche des
quasi-contacts (air intérieur séparé de l'air extérieur par ≤ N cases
grossières), puis reconstruction d'une grille locale à **0,005 m** dans une
boîte autour de chaque couture, et test de connexité entre les deux côtés.

**Statut honnête : `NON VÉRIFIÉ`.** Il n'a pas été exécuté sur une géométrie
saine avant qu'un résultat n'en sorte — la précaution que le lead m'a
explicitement demandé d'appliquer, et qui est celle que mon propre placebo
applique à la batterie. Je ne publie donc aucun verdict de raffinement.

Deux choses y sont néanmoins déjà acquises et méritent d'être lues :

- **Toute boîte publie si l'inondation atteint son bord.** Une boîte atteinte au
  bord donne un **minorant**, pas une mesure — c'est la leçon de la métrique
  d'aire retirée, transposée. Le champ s'appelle `tronque_par_la_boite`.
- **L'angle mort est écrit dans l'en-tête, pas découvert après.** Un canal de
  2 mm au milieu de 30 cm de roche ne produit aucun quasi-contact à 0,06 m, donc
  aucune boîte : le raffinement ne le verrait pas. C'est le genre topologique qui
  couvre ce cas — il détecte une anse de n'importe quelle largeur sans aucune
  résolution, mais ne la localise pas. Les deux instruments sont **appariés**, et
  leurs journaux restent **séparés**.

Une mesure incidente, utile à qui reprendra : un tunnel de **40 mm** de diamètre
dans R2a-3.4 est **vu** par l'oracle à 0,06 m (`RC=1`). L'aveuglement du portail
n'est donc pas à la taille de sa maille — la connexité se teste par un segment
centre-à-centre infiniment fin.

---

## 8. CE QUI RESTE OUVERT

| point | statut |
|---|---|
| batterie 8/8 sur R2a-3.4 et `c184c8dc` au pas 0,06 | **PASS**, `RC=0` |
| batterie sur `cc3596c5` | **FAIL attendu** — source percée, genre 1 |
| `C4` : cause établie | **PASS** — couple (maillage, repères) incohérent |
| barrière dérivée, épaisseur nulle | **PASS** |
| fabrique indépendante de la géométrie | **PASS** sur trois géométries, 1 tentative partout |
| raffinement adaptatif 0,005 m | **NON VÉRIFIÉ** — jamais éprouvé sur géométrie saine |
| `c184c8dc` non propre au CSG exact | **à transmettre à l'agent A** |

Aucun de ces résultats ne dit quoi que ce soit de la **jouabilité** ni de
l'**épaisseur** de la coque : ce portail juge la séparation topologique, rien
d'autre. Le gate d'épaisseur reste à jouer, et le contrat rappelle que lorsqu'une
borne ne peut pas trancher, le verdict est **`BLOQUÉ`**, jamais `PASS`.

---

## 9. REPRODUCTION

```sh
cd /home/user/zelda-r2a354/b_portail

# derivation de la bouche, profil complet
python3 tools/cave_oracle_bouche.py <glb> --pas 0.10 --profil

# placements derives d'un maillage
python3 tools/cave_oracle_placement.py <glb> [--reperes <lieu.gd>]

# batterie complete — le verrou est pris par la fabrique
python3 tools/cave_oracle_batterie.py --entree <glb> --travail <dir> \
        --pas 0.06 [--reperes <lieu.gd>]

# un couple (maillage, reperes) doit etre coherent : le nommer
python3 tools/cave_oracle_global.py <glb> --pas 0.06 --reperes <lieu.gd>
```

Le code retour n'est jamais lu à travers un tube. Chaque tâche de fond écrit
son propre `RC=` dans un journal.
