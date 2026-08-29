# Le camp braise, premier POI complet — les preuves

Contrat : `docs/contrats/camp_libere_world_v2.md`.
Données : `resources/world_v2/world_v2_camp_liberation.json`.

## Le contrat exécutable, du rouge au vert

| Journal | Ce qu'il montre |
|---|---|
| `contrat_rouge.log` | **0 réussi, 8 échoué** — chaque échec nomme SON exigence (C1, C2, C5, C6, C8) |
| `contrat_vert.log` | **5 réussi, 0 échoué** après l'implémentation |

Le rouge n'est pas décoratif : il prouve que chaque cas peut échouer. Et
chaque cas « après » a son « avant » — un camp qui ne se libérerait jamais
satisferait « pas de coffre » et « foyer éteint » sans rien prouver.

## Les trois captures, pour la revue Codex/Istvan

`captures/` — commit `a80ceca8`, arbre propre, rendu **logiciel**.

| Plan | gardes | foyer | coffre du camp | engagement |
|---|---:|---|---|---|
| `01_approche` | 4 | éteint | absent | — |
| `02_combat` | 4 | éteint | absent | **réel** |
| `03_camp_libere` | 0 | **allumé** | **présent** | — |

`engagement: true` n'est pas un décor : le héros est posé au milieu de la
garnison et le script ATTEND qu'un garde l'acquière par sa propre perception.
Sans engagement, le manifeste l'aurait dit au lieu de livrer une image
racontant un combat inexistant.

**Aucun verdict artistique n'est rendu ici.** Ces images partent à la revue ;
le rendu est logiciel, donc lisible pour une composition et un état de jeu,
jamais pour juger une lumière finale ni une performance.

## Le manifeste qui mentait, gardé exprès

`captures_indicateur_faux/manifest.json` — premier run. `_coffre_present()`
comptait N'IMPORTE QUEL coffre du monde, or les POI de la vallée en posent
déjà. Le manifeste annonçait donc « coffre présent » sur les deux plans où le
camp n'est PAS libéré : un relecteur y aurait lu « la récompense existe avant
la victoire ».

Il est conservé pour la même raison que le profil CPU invalide d'ISS-074 :
**une mesure peut être exacte, reproductible et fausse** quand l'indicateur ne
regarde pas ce qu'on croit. L'indicateur vise désormais le coffre du camp par
son identifiant.

## Deux corrections de provenance, dans l'ordre où elles ont mordu

1. Le premier lot nommait un commit qui **ne contenait pas l'outil** l'ayant
   produit. Outil committé, puis recapture.
2. Le contrôle de propreté se contentait de `--untracked-files=no` : une fois
   les PNG suivis, une recapture les modifie, et l'outil **déclarait l'arbre
   sale à cause de sa propre sortie**. Aligné sur `capture_poi_batch.gd` — on
   saute `evidence/`, et seulement `evidence/`.

Le lot autoritaire porte donc `commit a80ceca8` et `repo_dirty: false`, et ce
commit contient bien le script qui a produit les images.
