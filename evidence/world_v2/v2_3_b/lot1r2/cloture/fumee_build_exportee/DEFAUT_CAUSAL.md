# Défaut causal — la build EXPORTÉE ne résout aucun modèle de kit ni de végétation

**Statut : FAIL.** Découvert par le test de fumée §4 sur la build autonome
Linux, le 2026-08-26. Le défaut **n'existe pas** en exécution éditeur : c'est
pour cela qu'aucune suite ne l'avait vu.

## 1. Ce qui a été observé, et sur quoi

| | |
|---|---|
| Binaire | export Linux x86_64 du SHA validé `919511d`, 393 752 464 octets |
| Lancement | installation neuve, `user://` vierge, Xvfb 1024×768, `--rendering-driver opengl3` |
| Journal | `session1_stdout.log`, 2 222 lignes, produit par le processus lui-même |
| Comparaison | `evidence/validate_fast/02_unit.log` (même code, exécution ÉDITEUR) |

| Mesure | Build exportée | Exécution éditeur |
|---|---:|---:|
| `[world_v2] kit : modèle inconnu` | **457** | 0 |
| `modèle végétal introuvable` | **631** | 0 |
| `[flower_field] modèle inconnu` | **4** | 0 |
| `[flower_field] modèle de dalle inconnu` | **2** | 0 |
| **Total appels de placement manqués** | **1 094** | **0** |
| Modèles distincts introuvables | **110** | 0 |

Une cellule de MultiMesh végétal sautée emporte TOUTES ses instances : le
nombre d'objets réellement absents à l'écran est très supérieur à 1 094.

Le monde se monte quand même — `[world_v2] lieux : 15 scène(s) posée(s)`,
`terrain : 64 chunks` — mais **vide de ses modules** : ni murs, ni sols, ni
clôtures, ni chemins de pierre, ni arbres, ni rochers, ni galets.

Inventaire nominatif complet : `inventaire_modeles_absents.txt`.

## 2. La cause, PROUVÉE par un laboratoire, pas déduite

Deux fonctions indexent les modèles en **balayant un répertoire** et en
retenant les fichiers dont le nom finit par `.glb` ou `.gltf` :

- `scripts/world_v2/poi/world_v2_place_kit.gd`, `scene_for()` ;
- `scripts/core/asset_registry.gd`, `model()` — qui sert aussi de recours au
  premier, donc les deux échouent ensemble et aucune ne rattrape l'autre.

```gdscript
for file: String in dir.get_files():
    var lower: String = file.to_lower()
    if lower.ends_with(".gltf") or lower.ends_with(".glb"):
        _index[StringName(file.get_basename())] = dir_path + "/" + file
```

**Correction d'une première hypothèse fausse.** J'avais d'abord écrit que le
PCK rangeait la ressource sous `<nom>.gltf.remap`. Le binaire porte bien 343
entrées `.remap` — mais pour des `.tres` et des `.gd`, **aucune** pour un
`.gltf` ou un `.glb`. L'hypothèse était plausible et fausse ; un laboratoire l'a
tranchée.

Projet minimal (`lab_dir_access/`), deux modèles importés, une sonde qui
imprime le répertoire, exporté avec les mêmes templates officiels 4.7.1 :

```
--- BUILD EXPORTÉE ---            --- MÊME SONDE, ÉDITEUR ---
get_files() rend 2 entree(s)      get_files() rend 5 entree(s)
  [Floor_WoodLight.gltf.import]     [Floor_WoodLight.bin]
  [SM_Barrow_Stones.glb.import]     [Floor_WoodLight.gltf]
                                    [Floor_WoodLight.gltf.import]
                                    [SM_Barrow_Stones.glb]
                                    [SM_Barrow_Stones.glb.import]
load(gltf) = true                 load(gltf) = true
```

**Le fichier SOURCE n'est pas empaqueté du tout.** Seul son fichier de
métadonnées `<nom>.gltf.import` entre dans le PCK ; le maillage vit sous
`res://.godot/imported/<nom>.gltf-<md5>.scn` (425 chemins de cette forme dans
le binaire du jeu). Un balayage qui teste le suffixe `.glb`/`.gltf` ne trouve
donc **jamais rien** dans une build exportée, tandis que `load()` sur un chemin
explicite réussit — la redirection est transparente pour un chemin, pas pour un
listage.

En exécution éditeur le même code lit le vrai système de fichiers, où les
sources existent : il marche. **Le défaut ne peut donc apparaître que dans une
build exportée** — exactement l'angle mort que le test de fumée §4 existe pour
couvrir.

## 3. Ancienneté

Ce n'est **pas** une régression du lot 1.R.2. Ni `world_v2_place_kit.gd` ni
`asset_registry.gd` ne font partie des 46 fichiers gelés, et le balayage de
répertoire existe depuis `5428e96` (V2.3-A) pour le premier, et depuis le
« Lot 9 » pour le second.

La build **déjà publiée** `world-v2-playtest-lot1-d78f007` (24 août) porte les
mêmes **343 entrées `.remap`** et le même code : voir `ancien_build_publie.log`
pour l'observation directe.

## 4. Ce que cela n'est pas

- Ce n'est pas un filtre d'export : `export_presets.cfg` porte
  `export_filter="all_resources"` et n'exclut pas `assets/`. Les modèles SONT
  dans le PCK — ils sont seulement introuvables par ce chemin de résolution.
- Ce n'est pas un artefact du conteneur : la résolution de ressource ne dépend
  ni du GPU, ni du pilote de rendu, ni de l'audio.
- Ce n'est pas la faute des six lieux gelés : ils appellent un service commun
  qui, dans une build exportée, ne rend rien.
