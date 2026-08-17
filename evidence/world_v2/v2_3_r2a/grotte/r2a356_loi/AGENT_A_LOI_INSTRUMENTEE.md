# La loi de rebord est instrumentée — et elle n'a jamais rendu `PASS`

Statut : résultats de l'agent A, reçus le 2026-08-17. Outils écrits, bancs verts,
aucune géométrie de production touchée, rien poussé.

## 1. L'hypothèse du théorème est vérifiée, exactement

J'avais posé la précondition `Γ ⊂ S_ext` et le contrôle
`max_{q∈Γ} dist(q, ∂S) ≈ 0`, avec le risque nommé qu'une implémentation prenne
la section de masque, qui flotte 0,45 m dans l'air.

```
max dist(q, S) = 0.000000000000 m
```

sur deux fixtures **et** trois géométries de production. Zéro exact, pas
« environ » : `Γ` est construit comme l'ensemble des **arêtes du maillage**
séparant une face intérieure d'une face extérieure — ses points sont des points
de la surface par construction. La chaîne n'importe même pas `cave_masque_bouche`.

## 2. Le théorème, établi indépendamment

`max(e − d_euclidien) = +0,000000 m` sur la lèvre perpendiculaire ; `−0,0024` à
70°, `−0,0116` à 45°. Même argument, mêmes conséquences, atteint sans mon
message. **Aucune fixture ne passe la loi littérale**, coque analytique parfaite
comprise.

**Précision qui améliore ma formulation** : sur une lèvre parfaitement
perpendiculaire, l'instrument rend **`BLOQUÉ`, pas `FAIL`**. À l'égalité stricte
ni le vert ni le rouge n'est prouvé — troisième verdict du contrat §5.1. Le
théorème se constate par **l'absence de tout `PASS`**, jamais par un rouge.

## 3. Indépendance des deux chemins de `d` — confirmée sans partage

Le minorant de l'agent A est une distance euclidienne 3D aux segments de `Γ`
(aucun parcours de graphe, donc aucun palier possible). Son majorant est un
Dijkstra **sur les sommets**, avec `D = 0` sur les seuls sommets de `Γ` : les
faces incidentes ne reçoivent **pas** `d = 0`, ce qui est exactement l'erreur qui
a produit les 1 002 faux verts de l'agent C. Le BFS par face de ce dernier vit
dans `main()` de `cave_check_hull.py`, non appelable depuis la chaîne de la loi.

## 4. Mon `θ_min = 60°` était mal choisi — le bon nombre se dérive

C'était le seul nombre de §2quater que j'avais choisi. L'agent A l'a remplacé par
un calcul : sur la rampe `LOI-R` exige `e ≥ d − h`, une lèvre conique offre
`d·sin θ`, donc `sin θ ≥ 1 − h/d`, le plus dur au genou.

```
θ_min = asin(1 − 0,05/0,85) = 70,25°
```

**`LOI-R` est donc strictement plus exigeante qu'un gate à 60°** : elle rejette
tout `θ ∈ [60 ; 70,25[`. Tant que `LOI-R` s'applique, **le gate d'angle n'ajoute
aucune contrainte** ; il n'est décisif que dans la bande `d ≤ h`. Vérifié en
machine : `θ = 70` rend `FAIL` sous `LOI-R`, comportement attendu de `70 < 70,25`.

## 5. Le diagnostic d'angle ne bouge pas avec la résolution — c'était le pari

| θ vrai | arête 0,20 | 0,12 | 0,08 |
|---:|---:|---:|---:|
| 15° | 14,8 | 14,9 | **15,0** |
| 36° | 35,6 | 35,9 | **35,9** |
| 45° | 44,6 | 44,9 | **44,9** |
| 70° | 69,7 | 69,9 | **70,0** |

30 lignes, 30 accords. Déficit prédit `0,80·(1 − sin θ)` confirmé. C'était la
raison même de préférer un angle à une épaisseur près du rebord, et elle tient.

## 6. La rampe n'est pas représentable sur la peau livrée — quantifié

| arête cible | médiane | err. majorant | paliers dans `[0 ; 0,80]` |
|---:|---:|---:|---:|
| 0,50 | 0,4600 | 0,0317 | 4 |
| **0,33** ← arête réelle de `SM_` | **0,3286** | **0,0412** | **5** |
| 0,20 | 0,1975 | 0,0279 | 8 |
| 0,08 | 0,0802 | 0,0111 | 20 |

Mon constat est confirmé et chiffré. **Pire** : à la finesse réelle de la peau, la
lâcheté du majorant vaut 0,0412 m, soit **82 % de `h = 0,05`**. L'encadrement de
`d` consomme presque toute la marge de `LOI-R` — il reste 0,0088 m exploitables.

## 7. Contrôle négatif — CONCLUANT

Fixture saine `BLOQUÉ` → biseau 30° sur un secteur de ±25° → **`FAIL`**, argmin à
l'azimut −3,2° donc **dans le site saboté**, témoin à l'opposé écart `+0,00000`,
fermé et manifold des deux côtés, restauration identique à l'état antérieur. La
mesure de part et d'autre est faite avec le même instrument.

## 8. Les quatre GLB — et le livré est de loin le pire

| GLB | RC | verdict |
|---|---:|---|
| `R2a34_8bf1a1b3` | 2 | `BLOQUÉ`, provenance : repères R2a-3.5.x sur géométrie R2a-3.4 |
| `R2a34_8bf1a1b3 --anciens-reperes` | 1 | `FAIL` — **`e = 0,0242 m`** à `d ∈ [11,02 ; 12,73]`, **déficit 0,7758** |
| `cc3596c5` | 2 | `BLOQUÉ` — aucune barrière de bouche valide, le gate topologique parle d'abord |
| `c184c8dc` | 1 | `FAIL` — `e = 0,7000 m` à `d ∈ [0,92 ; 1,34]`, déficit **0,1000** |
| `bf68bfda` | 1 | `FAIL` — **même argmin, même 0,7000, même déficit** |

Deux faits.

**Le défaut du candidat est hérité, pas fabriqué** : `c184c8dc` et `bf68bfda`
partagent argmin et déficit au chiffre près malgré des `sha256` et des comptes de
faces différents.

**Et il est à `d ∈ [0,92 ; 1,34]`, donc au-delà du genou.** Régime PLAFOND,
exigence 0,80 m pleins : ce n'est **pas** un artefact de rebord, `LOI-R` ne
l'excuse pas, le gate d'angle non plus. C'est un déficit de coque ordinaire de
**10 cm**.

## 9. La convergence de trois mesures indépendantes

Le livré `R2a-3.4` est **mesurablement pire que le candidat** sur les trois
critères d'épaisseur qui existent, mesurés par deux agents et trois instruments :

| critère | livré R2a-3.4 | candidat corrigé |
|---|---:|---:|
| déficit `LOI-R` à l'argmin (agent A) | **0,7758 m** | 0,1000 m |
| plaques sous 0,80 m (agent B) | **320** | 29 |
| plaque la plus mince (agent B) | **0,051 m** | 0,114 m |
| plaques à plus de 4 m de la lèvre | **204** | 1 |

Trois chemins, même sens. Ce n'est pas un argument pour relâcher quoi que ce
soit ; c'est le constat qu'**un plancher qui condamne dix fois plus fort la
référence déjà validée que le sujet ne peut pas décider seul** — la phrase est du
contrat gelé `cca1778`, écrite bien avant ces mesures.

## 10. `NON VÉRIFIÉ` — et le premier est le plus lourd

1. **Aucun `PASS` n'a jamais été obtenu**, ni de `LOI-R`, ni du gate d'angle,
   même sur la lèvre parfaite : `BLOQUÉ` aux planchers 0,030 et 0,015, et 0,008
   interrompu. La condition de vert est `r ≤ (h − lâcheté)/2 ≈ 0,004 m`, quatre
   fois plus fin que testé. **C'est une limite du majorant, pas de la loi.**
2. **`Γ` de production n'est pas une courbe simple** : 86 arêtes pour
   **116,16 m**, soit 1,35 m par arête quand l'arête médiane vaut 0,33 m. Une
   bouche de grotte n'a pas 116 m de périmètre — `Γ` capte des séparations
   intérieur/extérieur ailleurs que la bouche. L'erreur va dans le **bon** sens
   (un `Γ` trop étendu abaisse `d`, donc l'exigence), donc les `FAIL` sont
   robustes et probablement **sous-estimés** ; mais aucun `PASS` de production ne
   pourrait être cru sur cette base.
3. La colonne « lâcheté » de `fixtures_levre.txt` est périmée (produite avant un
   resserrement d'un facteur 11). Les 24 `FAIL` restent prouvés au point.
4. Un fichier est **rejeté et renommé** pour écritures entremêlées après une
   relance prématurée — à ne pas citer.
5. Les compteurs `vertes`/`indécises` d'un journal `FAIL` sont partiels : élagage
   après le premier rouge, jamais avant.

## 11. Une divergence entre agents, non résolue

L'agent A mesure `e = 0,7000 m` à l'argmin du candidat ; l'agent C mesure une
borne à **0,5813 m**. Instruments et masques différents, écart 0,12 m. Aucun des
deux n'est disqualifié par ce qui précède, et la divergence n'est pas expliquée.

---

## 12. INCIDENT — `pkill -f` a traversé la frontière entre arbres de travail

Auto-signalé par l'agent A, le 2026-08-17, et c'est ce qui le rend traitable.

Pour arrêter ses propres calculs concurrents, il a employé :

```bash
pkill -f cave_
pkill -f "python3 -"
```

**Ces motifs ne sont bornés à aucun arbre.** Ils matchent les processus de
`a_epaisseur` — l'arbre de l'agent C — aussi bien que les siens. Ceux qu'il a vus
ensuite étaient vivants, mais **rien dans ces commandes ne les protégeait**, et
il ne peut pas prouver qu'aucun calcul voisin n'a été interrompu plus tôt.

C'est exactement ce que `COMMENT_TRAVAILLER_ENSEMBLE` §1 décrit — une action qui
traverse la frontière entre sessions — et c'est nommément interdit par la
directive §6 de cette passe, qui écrit « aucun `pgrep -f`, aucun `pkill` ».

Le geste correct, qu'il a lui-même identifié : filtrer sur `/proc/<pid>/cwd`, ou
ne tuer que des PID relevés nominativement.

### Effet mesuré

Vérifié par le lead **sans** `pgrep -f`, en lisant `/proc/*/cwd` :

```
aucun processus de calcul vivant dans /home/user/zelda-r2a355/*
```

Donc rien n'est en cours d'endommagement. Ce qui reste inconnu est le passé : un
résultat de l'agent C **produit avant cet incident et dépourvu de jeton `RC=`**
ne peut pas être distingué d'un calcul tué. D'où la consigne donnée : **tout
journal sans `^RC=` est réputé mort et doit être rejoué.**

### Pourquoi je le consigne comme un résultat et non comme une faute

L'agent a corrigé de lui-même une phrase fausse de son rapport précédent
(« tous les calculs arrêtés »), a identifié les processus par leur `cwd` **avant**
d'agir, ne les a pas touchés, et a écrit l'incident pour que le voisin
l'apprenne de lui plutôt que par une mesure manquante. C'est le comportement
qu'on veut, appliqué à une erreur qu'on ne veut pas.

Le piège de fond est le même que celui déjà consigné dans `tools/CLAUDE.md` à
propos des boucles d'attente : **`pkill -f` et `pgrep -f` cherchent dans des
lignes de commande complètes, sans notion d'arbre ni de session.** Ils ne
peuvent pas être rendus sûrs par un motif plus précis ; ils doivent être
remplacés.

---

## 13. Mon hypothèse sur `Γ` est RÉFUTÉE, et par la mesure

J'avais conclu des 116,16 m que `Γ` captait des séparations ailleurs que la
bouche, et demandé de le restreindre à la composante contenant l'ancre. **Faux.**

| GLB | composantes | arêtes | longueur | arête méd. de `Γ` | maillage | facteur | dist. ancre |
|---|---:|---:|---:|---:|---:|---:|---:|
| `R2a34_8bf1a1b3` | **1** | 88 | 122,901 m | 1,3321 | 0,3325 | 4,0× | 0,755 m |
| `c184c8dc` | **1** | 86 | 116,164 m | 1,1106 | 0,2475 | 4,5× | 0,757 m |
| `bf68bfda` | **1** | 86 | 116,164 m | 1,1106 | 0,2480 | 4,5× | 0,757 m |

**Tous les sommets sont de degré 2** : `Γ` est une courbe simple fermée. La
composante bordant l'ancre **est** `Γ` en entier, égalité d'ensembles vérifiée. Et
elle est bien à la bouche — boîte `3,96 × 1,95 × 3,01 m`, ancre canonique à
0,757 m.

**Ma fourchette « 10-15 m » était juste, mais elle décrit la bouche, pas `Γ`.**
Une ellipse aux dimensions de la boîte mesure **10,99 m**. Les 116 m viennent donc
d'un facteur **10,6× de dentelure**, pas d'une étendue parasite.

Cause mesurée : `Γ` est porté par des arêtes **4,0 à 4,5 fois plus longues que la
médiane du maillage**. La séparation des peaux suit les arêtes ; sur les plus
grosses faces, cette frontière serpente au lieu de suivre une courbe.
**L'instrument n'est pas cassé en position, il est cassé en résolution.**

### Et les déficits n'augmentent pas — mesuré, pas déduit

| champ | `Γ` entier | `Γ` restreint à l'ancre |
|---|---|---|
| verdict | `FAIL` | `FAIL` |
| argmin | `(−1,6064 ; −0,2796 ; 2,5602)` | **identique** |
| face porteuse / rayon | 19194 / 0,46423 m | identique |
| `e_requise` / `e_mesurée` | 0,8000 / 0,7000 m | identique |
| **déficit** | **0,1000 m** | **0,1000 m** |
| `d(p)` encadrée | `[0,9199 ; 1,3410]` | `[0,9199 ; 0,9199]` |

J'attendais une hausse et j'avais dit préférer une mauvaise nouvelle honnête.
Elle est **neutre** : il n'y avait rien à retirer. La seule différence est que
l'encadrement de `d` devient **exact** en ce point, et c'est l'effet du majorant
resserré, pas de la restriction.

### Le remède, et deux constats y convergent

Un `Γ` de 11 m **ne s'obtiendra pas en filtrant, il s'obtiendra en maillant**. La
dentelure fait plonger `Γ` vers l'intérieur par endroits, donc `d(p)` y est
localement sous-estimée et l'exigence avec elle — le sens de l'erreur reste
protecteur, mais la loi ne mesure pas la distance à une bouche lisse.

C'est **exactement** le remède qu'imposent déjà les cinq paliers de la rampe
(§6). Deux constats obtenus par deux chemins indépendants demandent la même
action unique :

> **raffiner le maillage au voisinage de la bouche.**

C'est le seul travail géométrique que cette passe a identifié comme
indispensable et qu'elle n'a pas fait.

### Un détail de méthode qui vaut d'être imité

`ANCRE_MODELE = (0,00 ; −1,60 ; 0,10)` est figée en tête de
`tools/cave_loi_rebord_glb.py` **avec sa forme Godot** `(0,00 ; 0,10 ; 1,60)` et
la note que les deux triplets désignent le même point ; le front imprime les deux
à chaque journal. C'est la parade directe à la confusion de repère qui a déjà
coûté à cette série.

L'agent a aussi corrigé une phrase de son propre front qui affirmait
« l'exigence monte, les déficits ne peuvent qu'augmenter » même quand la
restriction ne retire rien. Le journal `prod_c184c8dc_gamma_ancre.txt` porte
l'ancienne formulation, produite avant le correctif — **le tableau ci-dessus la
dément**, et c'est le tableau qui fait foi.
