# Grotte du Couchant — sonde de végétation gelée (exigence 7 de R2a-3.1)

**Question posée par la revue.** « Rejouer la sonde de végétation corrigée
autour de la grotte. » Le semis V2.2 est **gelé** : s'il traverse la roche, ce
n'est pas lui qu'on corrige, c'est l'implantation du lieu.

**Outil.** `tools/godot/probe_vegetation_near.gd --place=valley.poi.waterfall_cave.01`.
C'est la version corrigée le 2026-08-14, celle qui lit le plan de plantation en
méta `instance_origins` au lieu d'interroger le MultiMesh — le renderer DUMMY
jette les transforms d'instance et rendait des comptes faux d'un facteur 90.

## Mesure

```
lieu valley.poi.waterfall_cave.01
  emprise monde : x [-117.9 ; -100.0]  z [-10.1 ; 7.8]  y [0.3 ; 10.8]
  instances de semis gelé dans le monde : 16651
  instances dans l'emprise du lieu (marge 0.35 m) : 0

  AUCUNE INTERSECTION
```

Code retour **0**.

## Le contrôle qui empêche un zéro silencieux

Un « 0 » n'est une réponse que si la sonde atteint vraiment la zone. Balayage de
la marge, qui doit croître régulièrement et non par marche d'escalier :

| marge | instances dans l'emprise |
|---:|---:|
| 0,35 m | 0 |
| 4 m | 0 |
| 6 m | 0 |
| 8 m | 6 |
| 10 m | 17 |
| 20 m | 150 |

Croissance continue à partir de 8 m. **La touffe gelée la plus proche est donc
entre 6 et 8 m au-delà de l'emprise de la grotte** — dégagement confortable, pas
une marge tenue par chance.

(Les « intersections » signalées à marge 10 et 20 m sont l'effet mécanique du
paramètre : `margin` sert à la fois de filtre d'emprise et de tolérance de
contenance. À 10 m de tolérance, une plante à 10 m d'une pièce est comptée
dedans. Le verdict est celui de la marge de travail, 0,35 m.)

## Portée exacte de ce verdict

La sonde confronte les positions de semis aux **AABB monde** des pièces du lieu.
Ici le résultat ne dépend pas du découpage par pièce : **aucune instance ne tombe
dans l'emprise globale** de la grotte, annexes comprises. La question du filtre
`EMPRISE_BATI_MAX_M` — qui écarte les pièces de plus de 14 m — est donc sans
effet sur ce verdict.

**Conclusion : rien à adapter. Ni le lieu, ni son implantation. La végétation
V2.2 reste intacte, comme exigé.**
