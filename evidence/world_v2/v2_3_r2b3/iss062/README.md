# `iss062/` — index des preuves

Deux agents ont écrit ici. Ce qui vient de l'agent « rectangularité » (calibrage)
et ce qui vient de l'agent « sabotage » (fermeture) est séparé.

## Agent rectangularité — l'instrument et son seuil

| fichier | contenu |
|---|---|
| `regle_seuil.md` | la règle de choix du plafond, **écrite avant toute mesure** (11:08:02) |
| `calibrage_temoins.txt` | les six témoins mesurés, sorties brutes |
| `calibrage_table.md` | le tableau qui en découle, et `M = 2,66 -> plafond 51` |
| `autotest_rectangularite.txt` | l'autotest 15/15 de l'instrument |
| `limite_bruitage.txt` | ce que le bruitage fait aux deux mesures |
| `sujet_avant.json`, `sujet_apres.json` | le sujet, 71,42 % puis 0,32 % |
| `SM_Farm_Ruins_c44f430b.glb` | l'état d'avant, conservé |

## Agent sabotage — l'entrée au filet et le contre-exemple

| fichier | contenu |
|---|---|
| `planchers_enumeres.md` | les NEUF planchers, nommés un par un |
| `00_autotest_rejoue.txt` | l'autotest rejoué indépendamment (15/15, RC 0) |
| `01_python_sujet_propre.txt` | les deux instruments sur le sujet non saboté |
| `sabotage_boites_soudees.py` | le générateur du contre-exemple, avec sa justification |
| `02_SM_Farm_Ruins_SABOTE.glb` | le GLB saboté, conservé pour rejouabilité |
| `03_python_sabote.txt` | **les deux instruments côte à côte** : 0,00 % contre 100,00 % |
| `07_prediction_planchers.txt` | ce que les neuf planchers DEVRAIENT rendre sous sabotage |
| `procedure_sabotage.sh` | installation, réimport, filet, restauration — sous verrou, avec `trap` |
| `04_import_sabote.log` | le réimport après installation du sabotage |
| `05_filet_ROUGE_sabote.log` | le filet Godot sur le GLB saboté |
| `06_import_apres_restauration.log` | le réimport après restauration |
| `08_filet_VERT_restaure.log` | le filet Godot sur le GLB d'origine |
| `RAPPORT_SABOTAGE.md` | le rapport, avec ce qui reste NON VÉRIFIÉ |

Rien n'a été commité : les fichiers sont laissés dans l'arbre pour le lead.
