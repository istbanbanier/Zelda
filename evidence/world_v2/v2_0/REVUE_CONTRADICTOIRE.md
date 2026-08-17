# Revue contradictoire à contexte frais — phase V2.0 (2026-08-12)

Agent `adversarial-qa`, contexte neuf, lecture seule (interdiction de lancer
Godot pendant que la suite complète tournait — piège des runners concurrents,
`tools/CLAUDE.md`). Code jugé : `9408a84` (4 commits au-dessus de la base
`58d4996`).

## Verdicts par critère

| Critère | Verdict | Résumé de la preuve |
|---|---|---|
| V1 intacte | **PASS** | diff 58d4996..HEAD : seuls `tools/godot/test_runner.gd` (+racine additive) et `docs/PROGRESS.md` modifiés côté V1 ; zéro occurrence de `world_v2` hors des répertoires neufs |
| Contrats classés | **PASS** | 23 familles, statuts confrontés au code ; compte « 161 fichiers de test » recompté exact |
| 31 POI couverts | **PASS** | comparaison programmatique layout ↔ POI_MAP ↔ bâtisseurs : 31/31, noms/sites V1/récompenses identiques, zéro doublon, zéro fantôme |
| Plan du donjon conforme au code | **PASS** | constantes d'arène (19/19,6/13/14), mezzanine (16,5), bloc salle 1, batterie salle 4 — toutes revérifiées dans les scripts |
| Contrat de migration cohérent | **PASS** | schéma 4 inchangé, tags checkpoint réels, doctrine de l'absence, « Continuer » inconditionnel constaté |
| Squelette + tests capables d'échouer | **PASS** (sur pièces) | 4 pièges de `tests/CLAUDE.md` cherchés un à un ; contrôle négatif réellement ROUGE archivé |
| Aucun test supprimé/assoupli | **PASS** | diff tests/ : uniquement 4 ajouts sous `tests/world_v2/` |
| Les preuves disent vrai | **FAIL** → **CORRIGÉ** | le README d'evidence committé annonçait deux captures et un log de suite qui n'existaient pas encore dans le dépôt |

**Verdict global rendu : FAIL** (le plus faible des critères — un dossier de
preuves qui affirme avant d'avoir). Sept critères sur huit PASS.

## Corrections appliquées après la revue (même session)

1. **Bloquant — véracité du dossier de preuves** : le README est réécrit pour
   ne référencer que des fichiers PRÉSENTS dans le même état du dépôt ; le log
   de `validate_fast.sh` est archivé avec son code retour ; les captures sont
   prises depuis un arbre committé PUIS commitées — l'ordre de
   `.claude/rules/evidence.md`, cette fois dans le bon sens.
2. **Ancrage** : les références `fichier:ligne` des trois documents VIVANTS
   remplacées par des symboles (`SaveSystem.migrate()`,
   `ValleyWorld.SAVED_POSITION_LIMIT_XZ/_Y`, `main_menu.gd (_on_continue)`…) —
   règle « citer ce qui ne pourrit pas » du `CLAUDE.md`.
3. **Altitude de la gorge** : R07 passe à `[12, 30]` dans le layout (la gorge
   du Vent entaille le plancher à 12) — masterplan aligné.
4. **Lieux de frontière** : note en tête du §4 du masterplan (« le JSON fait
   foi, la mention croisée n'est pas une contradiction ») + région JSON
   explicitée pour `waterfall_cave`, `ancient_aqueduct`, `veil_falls`,
   `storm_caravan`.
5. **Pylônes de l'arène** : « espacés de 90° (aux diagonales de l'arène) » —
   la formulation « à 90° » laissait croire à des positions cardinales.
6. **Vestibule** : l'épinglage par `test_dungeon_topology.gd` est consigné
   dans la matrice §1.4 (catégorie B de fait — il protège l'acquis conservé).
7. **Ordre commit/preuve** : les logs de la première salve dataient d'avant
   les commits qu'ils prouvaient (arbre identique, ordre inversé) — consigné
   ici ; les preuves suivantes suivent l'ordre commit → exécution → commit.

Les points « détail » restants (aucun) : tous traités ci-dessus.
