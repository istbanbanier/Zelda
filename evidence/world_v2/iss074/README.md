# ISS-074 — le peuplement de World V2, du rouge au vert

Ce répertoire porte la trace COMPLÈTE de la tranche « garnison du camp
braise », dans l'ordre où elle s'est produite. Les journaux rouges sont gardés
volontairement : un portail qui n'a jamais rougi ne prouve rien.

## Le portail, avant et après

| Journal | Ce qu'il montre |
|---|---|
| `portail_rouge_a8d2f77.log` | le tout premier portail, sur la candidate : `0 réussi, 2 échoué` — aucun adversaire, aucun coordinateur |
| `portail_rouge_1717ddfe.log` | le même rouge rejoué sur cette branche après le cherry-pick |
| `portail_renforce_rouge.log` | le portail RENFORCÉ à neuf exigences, écrit avant la moindre ligne de production : **0 réussi, 10 échoué** |
| `portail_vert.log` | après le bâtisseur : **6 réussi, 0 échoué** |
| `portail_vert_navmesh_frais.log` | rejoué après le recuit du navmesh, avec l'ouïe et les ancres de région ajoutées : **6/0** |

## Les contrôles négatifs — chacun ne doit rougir QUE sa règle

| Journal | Sabotage | Attendu / obtenu |
|---|---|---|
| `controle_negatif_s1_vision.log` | vision de l'azur remise à son défaut sauvage (30 m) | la seule règle des calmes rougit — **5 réussi, 1 échoué** |
| `controle_negatif_s2_composition.log` | un pillard braise retiré de la donnée | tout rougit, par les gardes de complétude — **0 réussi, 8 échoué** |
| `controle_negatif_s3_persistance.log` | la mort n'est plus écrite | le seul cas 9 rougit — **5 réussi, 4 échoué** |

## Le navmesh, et pourquoi il a fallu le recuire

`sonde_navmesh_camp.log` est la première mesure : 240 points sondés dans r05,
239 sur navmesh, 238 atteignables. Chiffres exacts — et portant sur un navmesh
cuit le **2026-08-13**, six jours AVANT la géométrie du camp. La sonde
décrivait un terrain nu là où le jeu pose une palissade.

`recuit_navmesh.log` : les quatre quadrants recuits. **Les quatre ont changé
de sha256** — la dérive était réelle. `sonde_navmesh_camp_apres_recuit.log`
est la mesure qui fait autorité, et sur laquelle les quatre positions ont été
re-choisies : une d'entre elles était passée de 0,010 m à 0,830 m d'écart.

## Le combat, prouvé en moteur

| Journal | Ce qu'il montre |
|---|---|
| `combat_rouge_premier.log` | 4/1 — le héros ne blessait jamais le garde : une attaque légère n'est engagée que depuis LOCOMOTION, et il passait son temps en HURT |
| `combat_vert.log` | **5 réussi, 0 échoué** — engagement décidé par l'ennemi, dégâts dans les deux sens, garnison entière tombée, mort du héros qui ne ressuscite personne |

Le second rouge, corrigé entre les deux, ne laisse pas de journal séparé : 45,0
pv avant, 45,0 après, attaque pourtant en phase RECOVERY — le héros frappait
DANS LE VIDE, la hitbox pendant sous `VisualRoot`, seul nœud qui tourne.

## Autres pièces

- `contrat_budget_vert.log` — le contrat « acteur prématuré » remplacé par le
  contrat de BUDGET : 5/0.

## Ce qui n'est PAS ici

Le volet EXPORT (`tools/gate_export_garnison.sh`) et le profil CPU du camp à
garnison pleine exigé par le contrat §6.6. Les deux sont **NON VÉRIFIÉS** tant
qu'aucun journal ne figure dans ce répertoire.
