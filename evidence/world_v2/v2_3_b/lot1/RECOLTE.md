# Récolte des trois voies — ordre d'intégration (à exécuter APRÈS le commit de clôture)

État constaté le 2026-08-21 ~17:50 UTC. Les trois agents sont morts dans la
suspension de 12 h ; leurs commits sont les livrables. Sauvetages effectués dans
LEURS arbres : `1bed85b` (voie B, trois lieux en cours) et `9a955c6` (voie C).

## Ce que chaque voie a livré

| Voie | Commits | Contenu | À inspecter avant cueillette |
|---|---|---|---|
| A | 10 | sonde d'implantation (729 l), mesures XZ hors moteur, filet LOT1_PLACES écrit ROUGE, publication SITES | RAS — n'a PAS touché le REGISTRY (conforme phase 2) |
| B | 4 + sauvetage | plan des six silhouettes ARRÊTÉ AVANT construction, puis 6 scripts + 6 scènes | les 3 lieux du commit de sauvetage sont NON RELUS, NON TESTÉS |
| C | 10 + sauvetage | filet des 8 défauts, détecteur D3, compteur de budget, plan de captures, provenance | idem sur gate_negatif_lot1.sh |

Zéro recouvrement de fichier entre les trois arbres — vérifié par diff.

## Constats remontés par les voies, à traiter par le lead

1. **C : `SM_WaterfallCave_r2a358.glb` est GELÉ mais absent d'ASSET_MANIFEST.csv**
   (trouvé par lot1_provenance.py, reproductible). Violation de la règle
   « manifeste AVANT build » sur un fichier déjà livré — dette à corriger, pas
   un défaut du lot 1.
2. **C : sa première version de D5 accusait 3 des 9 lieux ACCEPTÉS** — corrigée
   et mesurée avant livraison. À revérifier en cueillant.
3. **A + B ont convergé indépendamment sur le secteur libre du belvédère** :
   masse à l'est (derrière cam05), ouverture OSO. Convergence de deux mesures
   séparées = bon signe ; le filet caméras tranchera.
4. **A : marges critiques** — overlook_summit route −1,20 m (la route passe SUR
   le site : composer AUTOUR, jamais dessus) ; turquoise_spring affluent +2,19 m.

## Ordre de cueillette (cherry-pick, aucun merge commit) — RÉVISÉ

Première version exigeait « chaque état intermédiaire vert » avec A cueillie
SANS son filet. Impossible proprement : les retouches du filet sont réparties
sur DEUX commits de A (0389e34, d6262f9), entrelacés dans la série avec
l'outillage. Découper ces commits serait réécrire l'histoire de l'agent.

Ordre révisé — le ROUGE du filet entre A et le câblage est ASSUMÉ, borné à
l'intérieur d'une même vague locale, et rien n'est poussé avant le vert :

1. Voie B d'abord : les 6 lieux, non câblés → tout reste vert.
   INSPECTION passe 2 (moteur) sur les 3 lieux du sauvetage AVANT cueillette.
2. Voie A entière, dans l'ordre de ses commits → le filet devient ROUGE
   (six sujets « RESTÉ SIMPLE MARQUEUR ») — c'est le rouge d'abord VOULU,
   dont l'agent a archivé la preuve.
3. LEAD, immédiatement après : câblage REGISTRY (6 entrées) → le filet juge
   les lieux réels et doit verdir.
4. Voie C : filet des 8 défauts + outillage + sabotages archivés.
5. UNE validation complète. AUCUN push entre 1 et 5 : le distant ne voit
   jamais l'état rouge intermédiaire.
6. Captures depuis arbre committé, carte, planche, checkpoint.

## Reproduction par le lead (rien n'est accepté sans elle)

- rejouer la sonde A (phase 2, moteur) et comparer à geometrie_xz.json ;
- instancier chaque scène B isolément, compter les budgets avec l'outil C ;
- rejouer les sabotages C et vérifier que chaque rouge nomme SON défaut.

## Inspection du lead — passe 1 (hors moteur, 2026-08-21 ~17:55 UTC)

Portée : les 3 lieux du SAUVETAGE d'abord (les plus risqués), puis les 6 scènes.

| contrôle | résultat |
|---|---|
| classe + `default_place_id()` constant | 6/6 conformes |
| position de site codée en dur | AUCUNE — les littéraux signalés (86.0, 74.0) sont des angles locaux, vérifiés en contexte |
| appuis déclarés / assise | 13 à 25 usages par lieu |
| primitives nues | ZÉRO — tout passe par le kit |
| ancres de récompense vs PLAN canonique | 6/6 cohérentes ; `barrow`=CHEST(hache dans un coffre) et `overlook`=WEAPON(arc posé) sont deux choix délibérés, confirmés par la lecture de `furnish()`/`_grant()` |
| scènes `.tscn` | 6/6 sur le patron accepté (enveloppe mince, 11 lignes) |

**Ce que cette passe NE prouve PAS** : parse, instanciation, budgets réels,
fondations sur le vrai terrain, filets D1–D8. Tout cela exige le moteur —
passe 2, après le commit de clôture. Les trois lieux sauvés restent marqués
NON TESTÉS jusqu'à là.
