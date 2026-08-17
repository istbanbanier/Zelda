# La loi `min(d, 0,80)` est de PENTE 1 — analyse, avant toute mesure de production

**Deux agents, deux chemins entièrement différents, la même conclusion**, tous
deux annoncés **avant** de mesurer quoi que ce soit sur la géométrie. Vérifié
indépendamment par l'intégrateur.

## Problème 1 — la pente 1 est la loi d'un rebord à ANGLE DROIT

Deux demi-droites issues du rebord, d'angle `θ`. Un point `P` de la peau
intérieure, à la distance géodésique `d` du rebord. Sa distance à la peau
extérieure :

| | |
|---|---|
| `θ ≤ 90°` | le pied de la perpendiculaire est **sur** la demi-droite → `d · sin θ` |
| `θ > 90°` | le pied tombe **derrière** le rebord → le plus proche est le rebord → **`d`** |

L'épaisseur maximale atteignable à la distance `d` d'un rebord vaut donc **`d`**,
et elle n'est atteinte que pour un rebord **à angle droit ou en surplomb**.

Or la loi exige `e_requise = min(d, 0,80)`. À `d = 0,80` :

| `θ` | épaisseur vraie | exigée | déficit | verdict |
|---:|---:|---:|---:|---|
| 15° | 0,2071 m | 0,80 | **+0,5929** | FAIL |
| 36° | 0,4702 m | 0,80 | **+0,3298** | FAIL |
| 45° | 0,5657 m | 0,80 | **+0,2343** | FAIL |
| 70° | 0,7518 m | 0,80 | **+0,0482** | FAIL |
| 89° | 0,7999 m | 0,80 | **+0,0001** | FAIL |
| **90°** | 0,8000 m | 0,80 | **0,0000** | **PASS à l'égalité** |
| ≥ 90° | 0,8000 m | 0,80 | 0,0000 | PASS à l'égalité |

> **Seul un rebord `θ ≥ 90°` passe, et il passe à l'égalité EXACTE. Il n'existe
> aucune marge.**

Le déficit vaut `0,80 · (1 − sin θ)`. Une lèvre de grotte est naturellement un
coin de roche, pas un angle droit.

## Problème 2 — la borne conservatrice rend la bande `d < h` rouge par construction

Trouvé indépendamment par l'agent C, et il est **d'une autre nature**.

Le gate porte sur `e_garantie = lecture − h`, comme le contrat l'exige et comme
le lead le rappelle : *« la borne conservatrice, jamais la mesure centrale ni une
moyenne »*. Or l'épaisseur vraie ne dépasse jamais `d`. Donc pour tout point à
`d < h` :

```
e_garantie  =  lecture − h  ≤  d − h  <  d  =  e_requise
```

**Rouge quelle que soit la géométrie.** À `h = 0,10`, toute la bande `d < 0,10 m`.
À `h = 0,05`, toute la bande `d < 0,05 m`.

C'est un **`BLOQUÉ` de résolution**, pas un `FAIL` géométrique : le raffinement
adaptatif peut en principe le résoudre, mais le coût explose en approchant du
rebord, et le problème 1 subsiste dessous.

## Les deux ensemble

**La loi n'admet aucune géométrie avec la moindre marge près du rebord.** Un
rebord parfait à angle droit passe à l'égalité exacte ; la borne conservatrice,
que le lead exige explicitement, le fait alors basculer au rouge.

Ce n'est pas un constat sur cette grotte. C'est une propriété de la loi.

## Ce que ça n'invalide PAS

- **La loi discrimine réellement.** Elle sépare les lèvres effilées des rebords
  droits, ce qu'aucune exclusion en bande ne faisait. Le lead avait raison de
  refuser une bande.
- **Le seuil de 0,80 m hors rebord n'est pas en cause** et n'est pas discuté ici.
- **Les 1 122 échantillons ne sont pas concernés** : ils sont tous à `d ≥ 2,00 m`,
  donc `e_requise = 0,80` pour tous. La loi ne les allège pas, et c'est bien ce
  que le lead a écrit.

## Proposition — non appliquée, décision du lead

Rendre la **pente** explicite au lieu de la laisser implicitement à 1 :

```
e_requise(p) = min( sin(θ_min) · d(p) , 0,80 )
```

`θ_min` étant l'**angle de lèvre minimal exigé**, déclaré. La loi devient alors
une exigence de **sculpture**, mesurable et atteignable : « la lèvre doit être au
moins aussi ouverte que `θ_min` ». À `θ_min = 90°` on retrouve exactement la loi
actuelle.

L'agent A publie déjà, par argmin, **l'angle de lèvre mesuré** et le déficit face
à la pente 1 — c'est précisément ce qu'il faut pour choisir `θ_min` sur des
mesures plutôt que sur une intuition.

**Rien de ceci n'est appliqué.** La loi committée à `4796c97` reste en vigueur,
telle qu'elle a été écrite avant toute mesure.

## Reproduction

L'analyse est fermée et se rejoue en quelques lignes ; les fixtures analytiques
de l'agent A la confirmeront ou la réfuteront **sur un maillage réel**, ce que
cette page ne fait pas.
