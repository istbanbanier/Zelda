# ATTRIBUTIONS

Règle absolue (§2, §7.14) : **aucune ressource n'entre dans le build avant d'être
inscrite ici** avec source, auteur, licence et modifications. Une ressource sans
licence claire n'entre pas dans le build. Aucun asset ne doit exiger le compte
personnel du joueur ni un service payant.

## État à ce jour

Le projet ne contient **aucune ressource d'origine externe**. Tout ce qui est
versionné a été généré par les scripts du dépôt.

## Ressources produites par le projet

| Ressource | Origine | Auteur | Licence | Modifications |
|---|---|---|---|---|
| `source_assets/blender/props/SM_TestCube.blend` | généré par `tools/blender/make_test_assets.py` | projet | licence du projet | — |
| `source_assets/blender/props/SK_TestRigAnim.blend` | généré par `tools/blender/make_test_assets.py` | projet | licence du projet | — |
| `assets/environment/props/SM_TestCube.glb` | export de la source ci-dessus | projet | licence du projet | export glTF 2.0 |
| `assets/characters/hero/SK_TestRigAnim.glb` | export de la source ci-dessus | projet | licence du projet | export glTF 2.0 |

Ces quatre fichiers sont des **assets de test du pipeline**, pas du contenu de jeu.
Ils prouvent que la chaîne Blender → glTF transporte échelle, pivot, matériaux,
armature et animation. Ils ne doivent apparaître dans aucune scène jouable.

## Outils (non redistribués avec le jeu)

| Outil | Version installée | Licence | Rôle |
|---|---|---|---|
| Godot Engine | 4.7.1-stable (commit `a13da4fe`) | MIT | moteur — compilé depuis la source, voir DECISIONS D-001 |
| Blender | 4.0.2 (paquet Ubuntu) | GPL-3.0-or-later | DCC — production des sources 3D |
| `io_scene_gltf2` | 4.0.44 | Apache-2.0 | exporter glTF, fourni avec Blender |
| numpy | 1.26.4 | BSD-3-Clause | dépendance de l'exporter glTF |

Le moteur Godot est sous licence MIT : sa redistribution avec le jeu est autorisée,
à condition de conserver l'avis de copyright. Blender est un outil de production et
n'est pas redistribué ; sa licence GPL **ne contamine pas** les assets produits avec.

## Image de référence North Star

Fournie par l'auteur du projet comme **référence de cadrage uniquement**. Elle n'est
pas versionnée à ce jour (KNOWN_ISSUES ISS-003) et ne doit **jamais** devenir une
ressource du jeu : ni skybox, ni matte painting, ni billboard, ni texture (§0.2).
Si elle est déposée dans `source_assets/concepts/`, l'inscrire ici avec son origine
exacte et son statut de droits.

## Contrôle avant chaque gate artistique

- [ ] Chaque asset du build a une ligne ici.
- [ ] Aucune ressource extraite d'une œuvre commerciale.
- [ ] Aucun nom, symbole, silhouette ou son appartenant à une licence existante.
- [ ] Aucune dépendance à un compte personnel ou à un service payant.
