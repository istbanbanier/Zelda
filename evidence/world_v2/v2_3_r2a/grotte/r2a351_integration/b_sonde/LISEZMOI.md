# Journaux de l'oracle d'étanchéité — R2a-3.5.1

Sauvés d'un worktree retiré pour libérer du disque : le conteneur est tombé à
1,4 Go libres pendant la création des arbres de R2a-3.5.2. Les onze worktrees
des passes précédentes étaient **propres** — zéro fichier non commité — et ces
23 fichiers d'analyse étaient les seuls qui n'existaient nulle part ailleurs.
Les deux `.glb` intermédiaires de plus de 2 Mo n'ont pas été conservés : ils se
reproduisent par `tools/blender/diag_cave_etapes.py`.

| dossier | ce qu'il mesure |
|---|---|
| `tronc_r2a34/` | la géométrie **livrée**, sonde durcie, cotes lues par `--cotes-de` : **0 percée confirmée**, plus grande ouverture parmi les 71 amas écartés **0,000 m** |
| `a1_asym/`, `a1_asym_v2/`, `a1_apres/` | la cavité asymétrique seule, avant et après correction de l'échantillonnage : 162 → 118 |
| `integ_avant/`, `integ_apres/` | la fusion cavité + enveloppe : **38 → 0** |
| `etapes/` | remaillage, stratification, décimation — les trois étapes séparées, qui ont établi que les ouvertures ne venaient **ni de la décimation ni du booléen** |
| `journal_minima.csv` | station, côté, azimut, valeur, seuil |
| `controle_negatif.log` | 18/18, et 13/15 rouges sur une convention de côté inversée |

Le passage de 38 à 0 est démontré percée par percée : **38/38** partaient hors
de la cavité réelle, **38/38** avaient deux impacts entre l'axe et ce point —
une paroi intacte traversée à l'aller et au retour. Propriété de sûreté : sur un
profil symétrique, l'écart entre l'ancien et le nouveau placement vaut
**0,00 m sur 495 points**.
