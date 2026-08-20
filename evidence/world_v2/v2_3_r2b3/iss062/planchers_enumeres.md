# Les NEUF planchers de `test_world_v2_r2b3_debris.gd`, énumérés

Le décompte est celui d'ISS-062 (« franchissent les neuf planchers »). Ce sont
les neuf conditions que `test_les_gravats_ne_sont_pas_des_paves()` applique
**à chaque tas**, `SM_Farm_Debris_A` et `SM_Farm_Debris_B` :

| # | Nom dans le fichier | Constante | Condition |
|---:|---|---|---|
| 1 | LE LIANT (boîtitude) | `HEXA_PLAFOND_PCT` | part de triangles en pavés `<= 25,0 %` |
| 2 | PLANCHER 1 — les débris ne disparaissent pas | `COMPOSANTES_MIN` | composantes `>= 9` |
| 3 | PLANCHER 6 — pas de subdivision | `TRIS_MAX_PAR_TAS` | triangles `<= 600` |
| 4 | PLANCHER 2 — pas de rétrécissement | `AIRE_TOTALE_MIN_*_M2` | aire `>= 3,20` (A) / `3,35` (B) m² |
| 5 | PLANCHER 3 — un fragment reste macroscopique | `AIRE_MEDIANE_MIN_M2` | médiane de composante `>= 0,08` m² |
| 6 | PLANCHER 4 — pas de bruit sous-pixel | `AIRE_FINE_MAX_PCT` | aire portée par des triangles < 2 mm `<= 1,00 %` |
| 7 | PLANCHER 5 — implantation, axe X | `EMPRISE_TOL_XZ` | emprise X à `± 20 %` de la base |
| 8 | PLANCHER 5 — implantation, axe Y | `EMPRISE_TOL_Y` | emprise Y à `± 30 %` de la base |
| 9 | PLANCHER 5 — implantation, axe Z | `EMPRISE_TOL_XZ` | emprise Z à `± 20 %` de la base |

Le **dixième** contrôle est celui que cet agent ajoute : `RECT_PLAFOND_PCT`,
`indice_boite <= 51 %`, appliqué à **l'agrégat** des deux tas — exactement la
portée de `mesure_rectangularite.py --mesh SM_Farm_Debris_A --mesh
SM_Farm_Debris_B`.

## Hors des neuf, mais dans le même fichier

`test_le_budget_tient_et_toute_primitive_porte_ses_uv()` porte trois conditions
supplémentaires, sur la ferme ENTIÈRE et non sur les tas :
budget `<= 4 500` triangles, plancher `>= 1 900`, UV0 sur chaque primitive, et
un garde de `>= 20` surfaces inspectées. Le sabotage les respecte lui aussi —
27 primitives conservées, quatre par tas, mêmes matériaux, UV0 émises, et
2 264 triangles pour la ferme (2 228 avant).
