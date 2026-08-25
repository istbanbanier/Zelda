# Voie A, deuxième corrective — preuves de l'agent A (belvédère, source)

Base : `de43152`. Deux lieux et deux lieux seulement :
`valley.poi.overlook_summit.01` et `valley.poi.turquoise_spring.01`.

## Où sont les images

| Dossier | Commit capturé | Ce qu'il montre |
|---|---|---|
| `iter1/` | `90f0d67` | premier jet : crocs stratifiés mais ÉCRÊTÉS blancs ; eau turquoise mais S=0,577 |
| `iter3/` | `e6dd5fb` | valeur corrigée (croc V 0,50) mais teinte NEUTRE ; eau rabattue à S=0,458 |
| `iter4/` | `6de2930` | froid atteint (croc H 226° S 0,18) ; « pile de dalles » persistante |
| `iter5/` | `24df556` | valeur dans la face (COLOR_0 66 % d'étendue) ; frange noire réparée ; mâchoires refroidies |

Les onze vues de chaque lot sont définies par `shots_a2.json`. Les QUATRE
premières sont les caméras **GELÉES** recopiées telles quelles depuis
`evidence/world_v2/v2_3_b/lot1/poi/shots_lot1.json` — ce sont les seules qui
jugent. Les sept autres sont **diagnostiques**, ajoutées par cette passe, et
n'ont remplacé aucune caméra existante. Aucune caméra n'a été déplacée, aucun
FOV, aucune exposition, aucun brouillard n'a été touché.

`spring_gue_riviere` est la **référence d'eau V2.2** : elle est capturée dans le
MÊME lot, donc au même moteur, à la même heure et à la même exposition que la
source. C'est ce qui rend la comparaison de teinte honnête.

## Mesures

`tools/mesure_voie_a.py <dossier> [<dossier_avant>]` — fenêtres nommées, taille
de fenêtre publiée, refus d'une fenêtre invalide. Les nombres qu'il rend sont
des repères de **calibration**, pas des seuils de gate : aucun contrat du
projet ne porte de plancher de saturation.

## Autres preuves de ce dossier

- `emprise_avant.log` / `emprise_apres.log` — `probe_place_metrics.gd` sur les
  DEUX états (les deux fichiers de lieu remis à `de43152`, mesurés, restaurés,
  restauration vérifiée par `git diff --quiet`) ;
- `budget_a2.log` — `sonde_budget_lot1.gd`, budgets de modules relus sur la
  scène montée.

Le journal d'itérations, avec pour chacune défaut → cause → levier → attendu →
caméra, est à la racine du worktree : `ITERATIONS_A.md`.
