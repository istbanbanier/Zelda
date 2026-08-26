# Portée exacte du défaut : ce qui manque, et ce qui ne manque pas

Écrit pour éviter une exagération autant qu'une minimisation.

## Ce qui FONCTIONNE dans la build exportée

Vérifié sur le journal du processus et sur l'image :

- le jeu démarre, atteint le menu principal, et « Nouvelle partie » ouvre
  **World V2** — jamais l'ancienne vallée V1 (0 mention) ;
- le monde se monte entièrement : `64 chunks`, `4 régions de navigation`,
  **`15 scène(s) posée(s) par le layout`** — le compte attendu ;
- le terrain, l'herbe, les falaises, l'eau, le ciel et le héros sont dessinés
  (capture `t0040.png` de l'observation longue) ;
- **les six lieux gelés chargent leur asset propre** : leurs GLB passent par
  `preload("res://assets/...")` ou `load(chemin)`, et Godot redirige un chemin
  explicite vers la ressource importée de façon transparente. Aucune erreur
  `[source] masses introuvables`, `[sanctuaire]` ni `[cimetière]` au journal ;
- la sauvegarde est écrite dans un `user://` vierge
  (`saves/slot0.json`), et la reprise rouvre World V2.

## Ce qui MANQUE

Tout ce qui est résolu **par balayage de répertoire** :

| Voie de résolution | Mécanisme | Sort en build exportée |
|---|---|---|
| `preload()` / `load("res://…")` | chemin explicite, redirection transparente vers `.godot/imported/*.scn` | **fonctionne** (prouvé au lab) |
| `WorldV2PlaceKit.scene_for()` | `DirAccess.get_files()` + suffixe `.glb` (le PCK ne contient que `.import`) | **échoue** |
| `AssetRegistry.model()` | idem | **échoue** |

Conséquence chiffrée : **1 094 appels de placement manqués, 110 modèles
distincts** — 457 modules de kit, **631 cellules de MultiMesh végétal**, 4 modèles de fleurs (chacune
portant de nombreuses instances : le nombre d'OBJETS absents est donc très
supérieur à 1 094) et 2 dalles — dont six manques
qui frappent le **champ des mille fleurs**, l'un des six lieux validés. Une cellule dont le modèle manque est sautée
entière, sans repli — `_emit_model_cells()` rend `false` et n'émet rien.

Et les six lieux gelés appellent tous le kit :

| lieu | appels au kit |
|---|---:|
| tour de guet | 7 |
| belvédère | 7 |
| champ des mille fleurs | 8 |
| source aux reflets | 2 |
| sanctuaire forestier | 6 |
| cimetière du tertre | 4 |

Leur masse principale est là ; **leur habillage ne l'est pas**. La build ne
montrerait donc pas les six lieux tels qu'ils ont été validés sur captures
éditeur. C'est la raison exacte pour laquelle aucune Release n'a été publiée.

## Ce que cela ne dit pas

Le jeu n'est pas cassé et ne plante pas. Il est **incomplet à l'affichage**,
d'une façon qu'aucune de nos suites ne peut voir, puisqu'elles tournent
toutes en exécution éditeur.
