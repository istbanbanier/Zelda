# Sources des planches A/B légères — R2B.2 vs R2B.3

Aucun rendu n'a été relancé. Les huit PNG ci-dessous étaient déjà dans le
dépôt ; les planches en sont dérivées par `tools/planches_legeres.py`.

Traitements appliqués, et rien d'autre : recadrage, conversion RGBA→RGB
(alpha à 255 partout, donc sans effet), encodage JPEG du montage. Aucun
redimensionnement, aucun réglage de contraste, luminosité, saturation ou
netteté. Le rectangle de recadrage est une seule variable par vue, lue dans
`RECADRAGE` et appliquée aux deux côtés : il ne peut pas différer.

| vue | côté | source | dimensions | recadrage (g,h,d,b) | SHA-256 |
|---|---|---|---|---|---|
| `debris_a_proche` | AVANT | `evidence/world_v2/v2_3_r2b3/preuves_lead/avant_r2b2/debris_a_proche.png` | 1280×720 | `0,0,1280,720` | `ff61213883b9eefa90f445aa1850ea794fce0e52440b39689c00990efbe94501` |
| `debris_a_proche` | APRÈS | `evidence/world_v2/v2_3_r2b3/preuves_lead/apres_r2b3/debris_a_proche.png` | 1280×720 | `0,0,1280,720` | `e97ad41d025938cbca781edf5d174bbe5ad91589ef54a598903f66e4a049b641` |
| `debris_b_proche` | AVANT | `evidence/world_v2/v2_3_r2b3/preuves_lead/avant_r2b2/debris_b_proche.png` | 1280×720 | `0,0,1280,720` | `0ba1a48b944779a61d7fc5dc1ac7ab92f247e4946cfc3536997d67f947f931c5` |
| `debris_b_proche` | APRÈS | `evidence/world_v2/v2_3_r2b3/preuves_lead/apres_r2b3/debris_b_proche.png` | 1280×720 | `0,0,1280,720` | `b1db2b03d1d48c58e15f638353c3a259c2fdb7500cb98adf834dacaeae9995c9` |
| `ferme_laterale` | AVANT | `evidence/world_v2/v2_3_r2b3/preuves_lead/avant_r2b2/ferme_laterale.png` | 1280×720 | `0,0,1280,720` | `86688a8fffd07c454f8a75f001f7264ab218755679facad6329b6775564796ea` |
| `ferme_laterale` | APRÈS | `evidence/world_v2/v2_3_r2b3/preuves_lead/apres_r2b3/ferme_laterale.png` | 1280×720 | `0,0,1280,720` | `71e8bb6921f76b598c75d92aa32ba7587233c4225eeed72f6e6ad1ac1b189940` |
| `ferme_orb090` | AVANT | `evidence/world_v2/v2_3_r2b3/preuves_lead/avant_r2b2/ferme_orb090.png` | 1280×720 | `0,0,1280,720` | `470419eeb079130c108477ab2722ba66eb22a64736591e34bf2f9a16858447da` |
| `ferme_orb090` | APRÈS | `evidence/world_v2/v2_3_r2b3/preuves_lead/apres_r2b3/ferme_orb090.png` | 1280×720 | `0,0,1280,720` | `b8b16f4c33a03483917617cc4722f0ec32244d52b51386a5c552b7127221f6f6` |

## Planches produites

| fichier | dimensions | qualité JPEG | octets | plafond 900 000 octets |
|---|---|---|---|---|
| `ab_leger_debris_a_proche.jpg` | 1280×1730 | 92 (4:4:4) | 576211 | marge 323789 octets |
| `ab_leger_debris_b_proche.jpg` | 1280×1730 | 92 (4:4:4) | 563094 | marge 336906 octets |
| `ab_leger_ferme_laterale.jpg` | 1280×1730 | 92 (4:4:4) | 669562 | marge 230438 octets |
| `ab_leger_ferme_orb090.jpg` | 1280×1730 | 92 (4:4:4) | 706681 | marge 193319 octets |

Reproduire : `python3 tools/planches_legeres.py` depuis la racine du dépôt.
