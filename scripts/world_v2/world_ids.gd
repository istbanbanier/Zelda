## Identifiants de MONDE — le contrat qui sépare V1 et V2 (World V2, phase V2.0).
##
## La sauvegarde V1 (schéma 4) ne porte AUCUN identifiant de monde : toute
## position y est implicitement une position de la vallée V1. La reconstruction
## World V2 rend cette implicite EXPLICITE : chaque monde déclare son
## identifiant ici, et le contrat de migration (`docs/WORLD_V2_SAVE_MIGRATION.md`)
## interdit de réappliquer une position d'un monde dans l'autre.
##
## Ces identifiants sont des IDENTITÉS PERSISTANTES (§19.3) : une fois publiés
## dans une sauvegarde, ils ne changent plus jamais de sens et ne sont jamais
## réutilisés pour autre chose.
class_name WorldIds
extends RefCounted

## Le monde V1 — la vallée servie par le flux normal du jeu. Sa valeur n'apparaît
## dans aucune sauvegarde de schéma <= 4 : l'ABSENCE du champ `world_version`
## SIGNIFIE ce monde-là. La migration qui posera ce champ est décrite dans le
## contrat de migration ; elle n'est PAS exécutée en phase V2.0.
const V1_WORLD_ID: StringName = &"neris_v1"

## Le monde V2 — la reconstruction. Seules les scènes de `scenes/world_v2/`
## ont le droit de se réclamer de cet identifiant.
const V2_WORLD_ID: StringName = &"neris_v2"
