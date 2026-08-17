# Provenance et ordre d'intégration — R2a-3.5.7

Statut : relevé de l'agent C, reçu le 2026-08-17, **vérifié mécaniquement** et non
par lecture. Preuves détaillées dans son arbre
(`/home/user/zelda-r2a355/integration/.../r2a357_agentC/`, 9 fichiers).

## 1. Ma cartographie est juste — et l'intégration est bien plus simple

`531cdd8` descend de `f2ea189` **et** de `fd4effe`, prouvé par
`git merge-base --is-ancestor` sur une matrice 11×11. La chaîne candidate est
**linéaire, 12 commits, aucun merge**, base commune `0cdfd91`. Le tronc ne
contient aucun des trois.

> **Il n'y a pas trois greffes : une seule — `531cdd8` — plus `MASSIF`.**

Et son contenu est celui que j'annonçais : fermeture + calotte + joue droite,
**pas** `MASSIF`. Vérifié par `patch --dry-run` : **6/6 hunks, `RC=0`**.

### Deux corrections à mon relevé

- `1569539` et `dd0a5b2` ne touchent **aucune source** — preuves seules ;
- `3644b7c` est un **cul-de-sac intégralement annulé** : l'AST du générateur à
  `a85301c` et à `531cdd8` est **identique** (`bf7a021c2103876c`), leur écart est
  du commentaire pur. C'est ce qui explique le GLB byte-identique après retrait
  de la doublure, et c'est une meilleure preuve que le sha256 seul.

## 2. L'impossibilité, et elle invalide l'ordre annoncé

La directive impose : politique → `MASSIF` → intersections → fermeture/calotte →
joue droite. **`MASSIF` ne peut pas être en 2ᵉ position**, pour deux raisons
indépendantes.

**Mécanique — reproduite par moi, avec une correction de formulation.** La
table `MASSIF` **existe** sur le tronc, 15 lignes, même compte qu'à `f2ea189` :
elle n'est donc pas « introduite » par ce commit. Ce qui diffère, ce sont ses
**valeurs** — **10 des 15 lignes** ont changé. La conséquence est identique et je
l'ai vérifiée en nommant explicitement la cible, mon premier essai ayant échoué
pour une raison d'outillage (le patch porte des chemins absolus, donc `-p1` ne
résout pas — un échec qui *ressemblait* à une confirmation) :

```
sur le TRONC     RC = 1    Hunk #2 FAILED at 250       1 des 6 hunks echoue
sur 531cdd8      RC = 0    6/6 hunks appliques
```

**Sémantique, et c'est la plus intéressante.** Le ratio rayon latéral / rayon de
courbure vaut **0,98 sur le tronc** — rien à réparer, ce qui explique que la
géométrie livrée n'ait jamais eu ce défaut — contre **2,53 sur le candidat**,
où la traversée est garantie. Appliquer le lissage au tronc reviendrait à
**lisser une courbe saine**.

**Ordre exécutable** : politique → fermeture/calotte → joue droite → `MASSIF` →
intersections restantes → … Et les deux premières fusionnent : `531cdd8` est un
**seul état de fichier**, pas deux greffes successives.

## 3. Le piège évité, et il aurait coûté la passe

Prendre `531cdd8` comme base par `checkout` **détruirait 12 outils et environ
4 000 lignes créés par le tronc après la bifurcation** — dont
`cave_exact_intersect.py`, **l'instrument même qui mesure ce que `MASSIF`
prétend corriger**, et `cave_topology_check.py`, que le tronc a réparé de ses
trois chemins absolus morts.

L'intégration se fait donc **sur le tronc**, en n'y portant que la géométrie :
**5 fichiers, tous non touchés côté tronc, donc zéro arbitrage**. Les deux
« conflits » d'outils se dissolvent — le tronc est un instantané du candidat à
`19fd800` pour l'un, hunks disjoints pour l'autre.

## 4. Un couplage dur à ne pas rater

> `scripts/world_v2/poi/waterfall_cave_place.gd` déplace `MODELE_SALLE` de
> `(1,05 ; 0,22 ; −6,25)` à `(2,62 ; 0,09 ; −2,58)`, soit **3,994 m** — l'agent
> annonçait 3,7 m, j'ai recalculé. Livrer le GLB sans lui met **la récompense et
> les lampes dans la roche**.

C'est le genre de dépendance qu'un commit « géométrie seule » perd en silence.

## 5. `TICKET-B4` — confirmé par AST, et plus large que consigné

`rochers_gaine` est appelée 1× au tronc, **définie mais morte** au candidat :
mon relevé tient. Mais `main()` du candidat appelle aussi **`bande_utile`,
`controle_epaisseur_domaine`, `franchir`, `pieces_enveloppe`** — quatre appels
absents du relevé du tronc. `construire()` est identique des deux côtés.

Deux trouvailles annexes :

- `facette` et `unir` sont mortes **des deux côtés** — dette, pas régression ;
- **`_orient_exact` est ajoutée par le patch `MASSIF` puis jamais appelée.**
  Signalé à l'agent qui le tient : soit elle sert et se branche, soit elle sort.
  Une fonction morte introduite par une correction est exactement ce que cette
  série vient de payer avec `rochers_gaine()`.

## 6. Deux réserves que l'agent n'enterre pas, et qu'il a raison de garder

**L'invariant invoqué par le patch `MASSIF` n'est pas rétabli.** Le patch annonce
« ratio 2,73 → 1,15 » ; la mesure indépendante donne **2,53 → 1,09**. Les deux
estimateurs divergent sur la valeur mais **concordent sur le point qui compte** :

> le ratio reste **`> 1` après réparation**, alors que le patch énonce ce seuil
> comme la **cause nécessaire** des traversées.

La cause est donc **atténuée, pas supprimée**. Le `env×env : 34 → 0` n'est pas
contesté — il n'a pas été rejoué — mais l'explication causale l'est
partiellement. Relayé à l'agent collision comme piste pour les 16 restantes :
si elles se concentrent là où le ratio dépasse encore 1, c'est le même mécanisme.

**Le `.blend` de `531cdd8` diffère de celui d'`a85301c` de 108 octets** alors que
le code et le GLB sont identiques. D'où la règle retenue : **le `.blend` livré
vient de l'export, jamais repris du candidat.**

## 7. Captures — ce qui n'est pas faisable, dit avant de promettre

`shots_r2a352.json` existe (7 plans) mais **ses caméras sont périmées** :
dérivées pour R2a-3.5.2, elles viseraient la roche après le déplacement de la
salle. `deriver_cameras.py` est l'outil prévu ; la re-dérivation n'est pas faite.
Manquent aussi les trois-quarts et la latérale.

> **La vue « gros plan de la collision réparée » n'a aucun outil** :
> `COL_WaterfallCave` n'est pas rendu en jeu. Trois voies sont possibles, aucune
> n'est écrite.

Le reste est faisable en llvmpipe, avec `check_capture_exposure.gd` obligatoire
sur les intérieurs. Et, dit par l'agent lui-même : **aucune de ces images n'est
une mesure.**

## 8. `NON VÉRIFIÉ`

`env×env 34→0` et `cav×env 28→16` sont **repris du texte du patch**, non rejoués ·
reproductibilité de `3a80ae71` non refaite · cause de l'écart `.blend` inconnue ·
que `MASSIF` sur `531cdd8` **construise** n'est pas prouvé · nécessité des trois
outils candidats absents du tronc non établie · effet des 84 roches
(`TICKET-B4`) toujours ouvert · péremption des caméras **déduite, non rendue** ·
aucun Godot ni Blender lancé · `validate_fast.sh` non lancé.
