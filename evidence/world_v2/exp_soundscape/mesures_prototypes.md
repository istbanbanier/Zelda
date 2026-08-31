# Mesures des prototypes d'ambiance — ISS-087

Vérificateur : `tools/audio/verifier_prototypes_iss087.py` (instrument spectral : `band_profile.py`, validé sur six réponses théoriques).

Référence banque courte (20 sons, moyenne énergétique des RMS, `amb_*` exclus) : **-14.04 dBFS**. Marge exigée : ≥ 11 dB.

| fichier | rôle | trames | RMS dBFS | crête | raccord | p95 deltas | stab. dB | 707-2 828 % | 125-500 % | QOA o |
|---|---|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| amb_p1_lit | lit | 661500 | -27.50 | 0.2178 | 0.000000 | 0.043488 | 3.61 | 91.5 | 1.48 | 267728 |
| amb_p2_ouvert | lit | 330750 | -27.50 | 0.1810 | 0.000031 | 0.043488 | 2.69 | 91.4 | 1.50 | 133872 |
| amb_p2_ferme | lit | 330750 | -27.50 | 0.2044 | 0.000000 | 0.030396 | 3.49 | 94.4 | 5.20 | 133872 |
| amb_p3_lit | lit | 441000 | -27.50 | 0.1940 | 0.000000 | 0.043579 | 4.58 | 91.4 | 1.48 | 178496 |
| amb_evt_1 | evenement | 55125 | -21.29 | 0.2414 | 0.000000 | 0.132324 | 79.01 | 100.0 | 0.00 | 22328 |
| amb_evt_2 | evenement | 55125 | -26.63 | 0.2414 | 0.000000 | 0.034027 | 14.22 | 96.9 | 3.11 | 22328 |
| amb_evt_3 | evenement | 55125 | -26.43 | 0.2414 | 0.000061 | 0.100494 | 12.10 | 37.9 | 0.18 | 22328 |
| amb_evt_4 | evenement | 55125 | -22.39 | 0.2414 | 0.000031 | 0.210602 | 7.95 | 0.0 | 0.00 | 22328 |

Coûts QOA par prototype : P1 = 267728 o (budget 267728), P2 = 267744 o (budget 267744), P3 = 267808 o (budget 267808).

RMS par fichier de la banque courte :

- chest_open : -11.55 dBFS
- death : -12.60 dBFS
- guard : -14.02 dBFS
- hit_land : -15.44 dBFS
- hit_taken : -12.93 dBFS
- jump : -17.07 dBFS
- land_hard : -14.48 dBFS
- land_soft : -15.85 dBFS
- parry : -15.95 dBFS
- pickup : -11.46 dBFS
- refuse : -11.56 dBFS
- step_grass_a : -16.06 dBFS
- step_grass_b : -16.62 dBFS
- step_grass_c : -15.49 dBFS
- step_stone_a : -15.33 dBFS
- step_stone_b : -15.67 dBFS
- swing : -16.15 dBFS
- ui_accept : -12.29 dBFS
- ui_move : -12.64 dBFS
- weapon_break : -15.57 dBFS
