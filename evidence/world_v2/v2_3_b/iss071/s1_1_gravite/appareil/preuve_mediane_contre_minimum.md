# Le sol est la MÉDIANE de trois repos, jamais le minimum global

Preuve construite pour que les deux lectures DIVERGENT en couleur.

## Le sujet

Un héros qui **ne saute jamais**. Il oscille de 0,6 m entre 24,0 m et
23,4 m — un pas dans un creux, une pente, un tassement de collision.

Séquence de marqueurs jouée : trois repos à 24,0 puis trois paires
(« montée » 24,0 ; « sol » 23,4).

## Les deux lectures

| Sol de référence | Valeur | Sauts conformes | Verdict |
|---|---:|---:|---|
| Minimum global | 23,40 m | **3/3** | **PASS — FAUX VERT** |
| Médiane des 3 repos | 24,00 m | 0/3 | FAIL — correct |

Avec le minimum, chaque « montée » à 24,0 vaut +0,60 m, donc au-dessus
du seuil de 0.5 m ; et chaque « retour » à 23,4 tombe
pile sur ce faux sol, écart nul. L'appareil déclarerait **trois beaux
sauts là où le héros n'a pas quitté le sol une seule fois**.

Avec la médiane, l'excursion vaut 0,00 m et les trois sauts échouent.

## Pourquoi le minimum est structurellement piégeux

Un minimum est déplacé par **un seul** relevé aberrant — une chute,
un pas dans un trou, un tassement. La médiane de trois relevés au
repos ne bouge pas pour un accident : il en faudrait deux.

C'est la même famille que le critère au pixel abandonné en S1.1 :
une grandeur voisine de celle qu'on croit mesurer.

## Le cas est dans l'autotest

`tools/analyse_journal_devmode.py --autotest`, cas
« SABOTAGE DÉCISIF — héros qui n'a JAMAIS sauté mais qui oscille de
0,6 m ». Il rougirait si quelqu'un remettait le minimum.
