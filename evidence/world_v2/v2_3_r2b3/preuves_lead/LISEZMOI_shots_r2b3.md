# Plan de caméras R2B.3 — 11 vues

**Le fichier de vues doit être un `Array` NU.** `tools/godot/capture_poi_batch.gd`
refuse tout objet enveloppant avec `BLOQUÉ : JSON invalide` — piège payé en
R2B.2 par un lot de captures perdu. La documentation vit donc ici, à côté, et
jamais dans le JSON.

## Sept vues REPRISES À L'IDENTIQUE de R2B.2 — champ par champ

`ferme_seuil`, `ferme_laterale`, `ferme_arriere`, `ferme_facade`,
`ferme_orb000`, `ferme_orb090`, `ferme_orb180`, `ferme_orb270`.

La directive l'impose et la raison est bonne : **on ne remplace pas un cadrage
défavorable.** `ferme_seuil` est la vue qui a fait échouer le portail d'aplats
en R2B.1 ; elle reste. Ces huit vues donnent en outre l'A/B R2B.2 → R2B.3 sans
aucun recadrage, puisque les panneaux de gauche existent déjà dans
`evidence/world_v2/v2_3_r2b2/preuves_lead/captures_r2b2/` et `captures_orbites/`.

## Trois vues NOUVELLES, visées sur une emprise MESURÉE

Sonde `tools/godot/sonde_aabb_lieu.gd` sur `res://scenes/world_v2/WorldV2.tscn` :

| pièce | centre monde | taille | sol |
|---|---|---|---:|
| `SM_Farm_Debris_A` | (−51,437 · 5,512 · 91,746) | 1,648 × 0,684 × 1,781 | y = 5,170 |
| `SM_Farm_Debris_B` | (−49,593 · 5,343 · 91,800) | 1,558 × 0,685 × 1,558 | y = 5,000 |

Les caméras sont calculées sur ces nombres, **pas sur une lecture du script de
placement**. La chaîne ancre du layout → yaw de la maison → position locale de
la pièce est trop longue pour être refaite de tête : en R2B.1, cinq caméras
posées de mémoire visaient deux fois sous le terrain et trois fois le pied au
lieu du fût.

- `debris_a_proche` et `debris_b_proche` : à ~3 m, œil à 1,2–1,35 m au-dessus
  du sol, depuis l'est — la maçonnerie de la ferme passe DERRIÈRE le tas et
  détache les fragments.
- `debris_rasant` : œil à 0,6 m, presque au niveau du tas, les deux tas dans le
  même cadre. **C'est l'angle qui démasque un pavé** : un fragment vu de très
  bas montre son arête supérieure et sa face, un pavé montre deux rectangles.

## Constantes de capture, à ne pas changer

`--scene=res://scenes/world_v2/WorldV2.tscn`, `--size=1280x720`, renderer
`forward_plus`, adaptateur llvmpipe. Identiques à R2B.2 : sans cela l'A/B ne
compare plus rien.

**Rendu LOGICIEL** : régression visuelle seulement, jamais une mesure de
performance.
