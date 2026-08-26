# Sondes du sanctuaire — LOT 1.R.2

## `probe_AVANT_ROUGE.log` — l'état hérité, mesuré AVANT toute modification

Rejoué le 2026-08-25 sur `529d767`, arbre propre, depuis
`/home/user/wt1r2-sanctuaire`. Il existe pour une seule raison : sans mesure
d'avant, une mesure d'après ne prouve rien.

- `fenêtre libre minimale 0.89 m à z de nef -3.20` — c'est ISS-070, au
  centimètre près (critère 0,80 de capsule + 2 × 0,05 de marge = 0,90).
- `VERDICT : FAIL (1 ecart(s))`, `RC=1`.

Les autres mesures sont vertes et servent de repère : plafond d'identité
2,029 m (marge 0,371), plus grande marche 0,300 m, atteinte de l'ancre 1,50 m.

## `probe_APRES.log` — la même sonde, après la corrective

Rejouée sur `c00cc7b`, arbre propre — une seconde fois, après le
déplacement du linteau : une mesure prise avant le dernier changement ne
prouverait rien sur le lieu livré. Même script, mêmes seuils : **aucun
critère n'a été déplacé**, et deux ont été AJOUTÉS (§2c, le balayage de la
vraie capsule dans les deux sens de traversée).

| Mesure | AVANT | APRÈS | Critère |
|---|---|---|---|
| Fenêtre libre du seuil | **0,89 m** | **1,31 m** | ≥ 0,90 (cible de lot : ≥ 1,00) |
| Dégagement d'un côté | 0,34 m | 0,56 m | publié, pas seuillé |
| Capsule, entrée nord → sud | *non mesuré* | **100 %** | 100 % |
| Capsule, sortie sud → nord | *non mesuré* | **100 %** | 100 % |
| Plafond d'identité | 2,029 m | 2,039 m | < 2,40 m |
| Plus grande marche en nef | 0,300 m | 0,000 m | ≤ 0,38 m |
| Atteinte de l'ancre | 1,50 m | 1,63 m | ≤ 1,80 m |
| Verdict | **FAIL** (RC 1) | **PASS** (RC 0) | |

**Le 0,000 m de marche est une conséquence déclarée, pas une victoire.** La
pierre couchée barrait la nef en travers ; la corrective visuelle l'a mise au
bord ouest, et l'axe n'a donc plus de contremarche du tout. Ce zéro ne prouve
plus rien sur cette pierre — il prouve qu'aucune masse nouvelle n'est venue
barrer la nef. L'en-tête de la sonde porte le même avertissement.
