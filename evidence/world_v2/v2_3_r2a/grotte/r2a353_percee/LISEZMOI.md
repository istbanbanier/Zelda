# LE CANDIDAT EST PERCÉ. La géométrie livrée ne l'est pas.

**C'est le résultat qui clôt R2a-3.5.3**, et il retourne tout ce que la passe
précédente croyait avoir établi.

Ce qui était décrit comme « une lame de roche de 3,8 cm » n'est pas une lame :
c'est le **bord d'un trou**. L'enveloppe R2a-3.5.2 est ouverte sur le ciel,
au-dessus de la galerie où le joueur marche.

## La mesure

Trouvé par l'agent C via genre + inondation à pas fin. **Reproduit
indépendamment par l'intégrateur**, avec sa propre méthode, à la résolution du
défaut.

Test : depuis un point **dans la galerie** (`z = 1,50`), compter les traversées
en **montant**. Zéro traversée = on voit le ciel. Fenêtre de 30 × 30 cm autour du
défaut, **3 721 colonnes au pas de 5 mm**.

| géométrie | colonnes ouvertes sur le ciel | emprise du trou |
|---|---:|---|
| **candidat `cc3596c5`** | **343 / 3 721** | **160 × 200 mm** |
| **`BASE352` `8bc8b9f9`** | **343 / 3 721** | **identique** |
| **R2a-3.4, la géométrie LIVRÉE** | **0** | — |

Trou centré sur `x ∈ [0,468 ; 0,623]`, `y ∈ [5,850 ; 6,045]` en repère modèle —
exactement là où la passe précédente mesurait « 0,038 m de toit ».

**Le trou est hérité de l'enveloppe R2a-3.5.2, pas du lot collerette** :
`BASE352` le porte à l'identique, aux 343 colonnes près.

### Deux tests faux avant le bon, et le second est le piège

1. **Compter *tous* les croisements de la verticale** ne peut pas voir une
   percée : un rayon qui traverse un trou du toit **continue** de couper le
   plancher et la roche du dessous. Ce test rend « 0 colonne ouverte » sur une
   géométrie percée — il a failli me faire *réfuter* un résultat juste.
2. **« Zéro traversée au-dessus » peut aussi vouloir dire « ce point est déjà
   au-dessus du massif »**, ce qui n'est pas un trou. Le garde-fou exige de la
   roche **en dessous** : une colonne sans croisement des deux côtés est hors du
   solide et ne prouve rien. Mesuré : **0 colonne écartée** — le confondant
   n'existe pas ici, mais il fallait le vérifier, pas le supposer.

## Corroborations indépendantes, par trois chemins qui ne partagent rien

| chemin | ce qu'il dit |
|---|---|
| **genre** (`tools/cave_topology_check.py`) | candidat de **genre 1** — une anse, sur une forme qui devrait être de genre 0. Il annonçait le trou **avant toute inondation**, sans le localiser |
| **inondation sans parité** (`tools/cave_oracle_global.py --pas 0.06`) | **ROUGE, RC=1**. La trace monte la colonne `x = 0,618` : à `y = 5,835` la plage vaut `[0,139 ; 1,579]`, à `y = 5,895` elle vaut `[0,139 ; **9,379**]` puis atteint le bord de grille |
| **connexité par colonnes** (`tools/cave_void_connectivity.py`) | `première 0,002 m · cumul 0,002 m` en `(0,60 ; 5,90)` — **deux millimètres de roche**, à un pas de grille du centre du trou. Cette mesure était en ma possession **avant** que le trou soit nommé, et je ne l'avais pas lue pour ce qu'elle était |

## Pourquoi aucune sonde ne l'avait vu

Toutes les sondes de percée s'ancrent sur les stations de `CAVITE`, **dont la
dernière est à `ay = 3,17`**. Le trou est à `ay ≈ 5,9`, soit **2,7 m au-delà**.
**Hors domaine.** Elles publiaient « 0 percée confirmée » et n'avaient pas tort :
elles ne regardaient pas là.

C'est la même cause que le toit mince, que la collerette sous-mesurée et que les
quatorze occurrences du défaut d'échantillonnage. **Le domaine, pas la méthode.**

Et la résolution compte autant : le même oracle rend **VERT au pas de 0,10 m** et
**ROUGE à 0,06**. Un portail dont le pas dépasse la taille du défaut ne dit rien.

## La géométrie livrée, elle, est étanche

Depuis le tronc, sur son propre GLB, avec les repères de sa propre géométrie
— l'oracle lit la graine dans `scripts/world_v2/poi/waterfall_cave_place.gd` :

```
sha256 8bf1a1b3…   noeud SM_WaterfallCave
graine (2.62 ; 2.58 ; 0.99) -> ecartee ; graine du tronc (1.05 ; 6.25 ; 1.12)
composante de la graine : AIR, 105 031 cases = 105,03 m3
VERDICT : VERT — une composante ROCHE, une composante AIR      RC=0
```

Et sur le fichier de référence avec les repères **courants**, l'oracle rend
`RC=3 **BLOQUÉ**` : *« la graine intérieure tombe dans une composante ROCHE : une
graine dans la roche rendrait ÉTANCHE sans rien prouver »*. Refuser plutôt que
rendre un vert vide est exactement le comportement attendu, et c'est la symétrie
du §27.3 — les repères ont été re-dérivés, les nouveaux tombent dans la roche de
l'ancienne géométrie.

## Ce que cette mesure NE dit pas

- **Elle ne prouve pas que R2a-3.4 est globalement étanche à 5 mm.** Mon balayage
  fin ne couvre qu'une fenêtre de 30 × 30 cm autour du défaut connu. Le verdict
  global sur R2a-3.4 vient de l'oracle — mais **au même pas de 0,06 m qui fait
  rougir le candidat**, et il rend `VERT, RC=0`
  (`oracle_r2a34_tronc_pas006.log`). La comparaison n'est donc pas biaisée par
  la résolution ; une percée plus fine que 6 cm y resterait invisible, et c'est
  la seule réserve qui tienne.
- **Elle ne dit rien de la visibilité en jeu** : un trou de 16 × 20 cm à cette
  hauteur se voit-il depuis le trajet du joueur ? Aucun instrument ne répond à
  cela, et aucun rendu n'existe.
- **Elle ne mesure que la verticale.** Une percée latérale ne s'y verrait pas.

## Conséquence

**Le candidat `cc3596c5` n'est pas intégrable**, et la question du niveau
d'épaisseur à viser devient secondaire : ce n'est plus un débat de seuil, c'est
un trou. La géométrie livrée R2a-3.4 est étanche ; la remplacer par une
géométrie percée serait une régression au sens le plus simple du terme.

C'est aussi, enfin, une **vraie régression mesurée** — là où « facteur dix sur
l'épaisseur » n'en était pas une, la mesure complète ayant montré 205 colonnes
minces contre 202 sur la livrée.

## Reproduction

```sh
python3 evidence/.../r2a353_percee/scan_independant_5mm.py          # les trois geometries
python3 tools/cave_oracle_global.py <glb> --pas 0.06 --tracer       # inondation
python3 tools/cave_topology_check.py                                # genre
```

---

## La batterie de l'oracle, rejouée par l'intégrateur — et un écart non tranché

L'agent C annonce **7/7 CONFORME** dans son arbre. Mes deux exécutions, depuis le
tronc, ne le reproduisent pas — et les deux échecs sont **différents et
instructifs**.

### Sur le candidat : 6 / 7

| contrôle | attendu | obtenu | état | rayon libre |
|---|---|---|---|---:|
| `temoin` | VERT | **ROUGE** | **NON CONFORME** | – |
| `toit` · `paroi_est` · `paroi_ouest` · `plancher` | ROUGE | ROUGE | CONFORME | **0,280 m** |
| `poche` · `roche_flottante` | ROUGE | ROUGE | CONFORME | – |

**Les six sabotages rougissent tous, pour la bonne raison, avec un rayon libre
mesuré.** La falsifiabilité de l'oracle est donc démontrée.

Le témoin, lui, échoue sur **`C4` : « témoin(s) hors de la cavité scellée :
`MODELE_NICHE` → le scellement ampute la cavité au lieu de la fermer »**. Le
maillage est pourtant sain (0 bord libre, 0 non-manifold, 0 sommet pincé,
genre 1 — identique au candidat).

**Ce n'est pas la percée qui parle ici**, et je ne prétends pas le contraire : au
pas de 0,10 m le trou est sous la résolution, et le motif invoqué est le
**scellement de bouche**, pas une communication vers le bord. Est-ce un artefact
de placement de la barrière ou une conséquence réelle de la géométrie ?
**NON VÉRIFIÉ.** Je n'ai pas tranché, et je préfère l'écrire que de choisir la
lecture qui m'arrange.

### Sur R2a-3.4 : 2 / 7, et le refus est correct

Cinq sabotages sortent **`INEXPLOITABLE`** : le booléen **ouvre** le maillage
(1 bord libre, 2 à 3 arêtes non-manifold, `χ` impair). Le pilote refuse alors de
compter le rouge :

> « INEXPLOITABLE : le sabotage a OUVERT le maillage. Un vert obtenu ici ne
> prouverait rien sur l'oracle — c'est exactement l'erreur de la passe
> précédente. »

C'est le bon comportement, et c'est même le cœur de ce que la passe devait
réparer. Mais cela établit que **la fabrique de sabotages dépend de la
géométrie** : elle fonctionne sur le candidat, pas sur R2a-3.4. La batterie n'est
donc **pas** un portail utilisable sur une géométrie quelconque en l'état.

La restauration reste byte-identique dans les deux exécutions —
`8bf1a1b3…` avant et après.

### Ce que j'en retiens

L'oracle **sait rougir** — six sabotages fermés, rayon libre mesuré. Sa batterie
n'est **pas encore un portail** : témoin rouge sur le candidat, fabrique fragile
sur R2a-3.4. Statut : `NON INTÉGRÉ COMME GATE`, `UTILISABLE COMME DIAGNOSTIC`.

Rien de cela n'affaiblit le constat de percée, qui ne dépend ni de la batterie ni
de l'oracle : il est établi par **mon balayage à 5 mm**, corroboré par le genre
et par l'inondation.
