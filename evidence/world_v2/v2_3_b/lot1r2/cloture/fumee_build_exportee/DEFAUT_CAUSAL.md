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
| `kit : modèle inconnu` | **457** | 0 |
| `modèle végétal introuvable` | **631** | 0 |
| `modèle de dalle inconnu` | **2** | 0 |
| **Total appels de placement manqués** | **1 090** | **0** |

Une cellule végétale sautée emporte TOUTES ses instances : le nombre
d'objets réellement absents est très supérieur à 1 090.

| Modèles distincts introuvables | **109** | 0 |

Le monde se monte quand même — `[world_v2] lieux : 15 scène(s) posée(s)`,
`terrain : 64 chunks` — mais **vide de ses modules** : ni murs, ni sols, ni
clôtures, ni chemins de pierre, ni arbres, ni rochers, ni galets.

Inventaire nominatif complet : `inventaire_modeles_absents.txt`.

## 2. La cause, lue dans la source du moteur installé

Deux fonctions indexent les modèles en **balayant un répertoire** et en
retenant les fichiers dont le nom finit par `.glb` ou `.gltf` :

- `scripts/world_v2/poi/world_v2_place_kit.gd`, `scene_for()` ;
- `scripts/core/asset_registry.gd`, `model()` — qui sert aussi de recours au
  premier, donc les deux échouent ensemble.

```gdscript
for file: String in dir.get_files():
    var lower: String = file.to_lower()
    if lower.ends_with(".gltf") or lower.ends_with(".glb"):
        _index[StringName(file.get_basename())] = dir_path + "/" + file
```

Dans un projet **exporté**, une ressource importée n'entre pas dans le PCK sous
son nom d'origine : l'exporteur y place un fichier `<nom>.gltf.remap` dont le
contenu pointe vers `res://.godot/imported/<nom>.gltf-<md5>.scn`. Vérifié sur
le binaire produit : **343 entrées `.remap`** et **425 chemins
`res://.godot/imported/…`**.

Et le moteur n'enlève pas ce suffixe quand on liste un répertoire empaqueté —
`core/io/file_access_pack.cpp` de la source 4.7.1 installée :

```cpp
String filename = simplified_path.get_file();
if (!filename.is_empty()) {
    cd->files.insert(filename);          // le nom PACKÉ, tel quel
}
```

```cpp
Error DirAccessPack::list_dir_begin() {
    for (const String &E : current->files) {
        list_files.push_back(E);         // rendu verbatim par get_next()
    }
```

Donc `DirAccess.get_files()` rend `Wall_Plaster_Straight.gltf.remap`, le test
`ends_with(".gltf")` est **faux**, l'index reste vide, et chaque appel finit en
`push_error("modèle inconnu")`.

En exécution éditeur le même code lit le vrai système de fichiers, où
`Wall_Plaster_Straight.gltf` existe : il marche. **Le défaut ne peut donc
apparaître que dans une build exportée** — exactement l'angle mort que le test
de fumée §4 existe pour couvrir.

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
