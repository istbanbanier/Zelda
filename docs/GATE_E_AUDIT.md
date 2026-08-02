# Audit du Gate E — récolte, cuisine, buffs, sauvegarde

Base : MASTER_SPEC §13 (récolte, cuisine, buffs), §19 (sauvegarde,
migrations, persistance), §22 Phase E, §23. Critère de sortie du gate :
« chaîne collecte → cuisine (1-5 ingrédients) → buff → save → load
validée ». Preuves rejouées au commit de HEAD, jamais reprises d'un
résumé.

## Matrice de preuve

| # | Item de la Phase E | Preuve rejouée | Verdict |
|---|---|---|---|
| 1 | Récolte et inventaires | `--filter=ingredients` 4/4 : sept familles §13.1 dans la vallée, collecte ATOMIQUE (l'objet ne part qu'après l'ajout), refus sur réserve pleine, aucune double collecte | **PASS** |
| 2 | Interface du feu de cuisine | `--filter=cooking_ui` 4/4 : `Campfire` interactable posé sur le foyer réel, invite « Cuisiner », l'atelier s'ouvre EN PAUSE (§13.3 : aucune minuterie ne court) | **PASS** |
| 3 | Sélection de 1 à 5 ingrédients | même suite : sélection bornée à 5 ET au stock réellement possédé (un 3e fruit refusé quand on n'en a que 2) | **PASS** |
| 4 | Aperçu du résultat | même suite : l'aperçu nomme la famille du plat et son soin, mis à jour à chaque ajout — sans divulguer les valeurs secrètes (§13.3) | **PASS** |
| 5 | Recettes et plats | `--filter=cooking_rules` 7/7 (règles pures §13.4 : soin cumulé et clampé, effet dominant, ragoût instable sur deux familles majeures, durée 60 + 30/compatible + 45/épice, plafond 300 s) | **PASS** |
| 6 | Buffs visibles dans le HUD | `--filter=cooking_ui` : le label nomme la famille et les secondes restantes, un nouveau buff REMPLACE l'ancien, l'expiration efface le label | **PASS** |
| 7 | Sauvegarde, migrations, persistance | `--filter=phase_e` 2/2 : migration 1 → 2 sur une COPIE (source jamais réécrite, contenu d'origine intact, champs de cuisine posés à vide) ; `--filter=save` 9/9 et `--filter=meals_and_buffs` 4/4 : buff expiré jamais ressuscité, plats et ingrédients persistants | **PASS** |
| 8 | Test collecte → cuisine → buff → save/load | `test_the_full_chain_survives_a_reload` : 15 assertions, chaque maillon par le VRAI chemin de jeu, vallée déchargée puis rejouée DEPUIS LE DISQUE | **PASS** |

## Exigences transverses (§13.3, §19.2, §19.4)

| Exigence | Preuve | Verdict |
|---|---|---|
| Annuler rend toujours les ingrédients | `test_cancelling_returns_everything_and_costs_nothing` : la sélection n'est qu'un plan, rien n'est retiré avant confirmation | **PASS** |
| Aucune duplication ni perte à l'interruption | confirmation ATOMIQUE : place et stocks revérifiés AVANT tout retrait, puis retrait complet et plat, ou rien | **PASS** |
| Un seul buff majeur actif | `--filter=meals_and_buffs` : le nouveau remplace l'ancien, aucun multiplicateur résiduel | **PASS** |
| Écriture atomique de la sauvegarde | `SaveSystem` : fichier temporaire, flush, vérification, remplacement (§19.2) | **PASS** |
| Jamais de référence Node/Resource sérialisée | la sauvegarde ne contient que primitives, tableaux et dictionnaires | **PASS** |
| Sauvegarde plus récente jamais écrasée | `load_slot` refuse un schéma supérieur au sien (§19.4) | **PASS** |

## Ce qui n'est PAS couvert

- **Animation de cuisine** (§13.3 : « courte animation 2-4 s ») : le
  geste `consume` existe (D-lot 14) et part au plat rapide, mais la
  séquence de cuisson au feu n'a pas d'animation dédiée. Le contenu
  fonctionnel est complet ; l'habillage appartient à la Phase H.
- **Essai humain** : impossible dans ce conteneur (ni écran, ni clavier,
  ni manette — CLAUDE.md). L'ergonomie de l'atelier, la lisibilité de
  l'aperçu et le confort de la sélection n'ont jamais été jugés par un
  œil humain.

## Verdict global

Tous les items automatisables sont `PASS`, sur des preuves rejouées.
Aucun essai humain n'a eu lieu.

> **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE**

Aucune case `PASS humain` n'est cochée. Le protocole d'essai est prêt
(`docs/MANUAL_VALIDATION.md`, `docs/PLAYTEST_PACKAGE.md` §5, où les
points de cuisine sont listés).
