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

## Assets de production (ART-P0)

| Asset | Origine | Licence |
|---|---|---|
| `SM_WornSword` (.blend, .glb, textures) | **création originale du projet** — géométrie, UV et textures générées par `tools/blender/make_worn_sword.py` (reproductible, seed fixe) | licence du projet |
| `T_WornSword_Icon.png` | rendu Godot du modèle ci-dessus (`tools/godot/render_weapon_icon.gd`) | licence du projet |

Aucun contenu externe, aucun symbole d'une licence existante.

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

## Image de référence North Star (Phase 0 — remplacée)

Fournie par l'auteur du projet comme **référence de cadrage uniquement**. Jamais
versionnée (KNOWN_ISSUES ISS-003). Depuis la Passe visuelle V4.1, elle est
**remplacée comme autorité** par le pack V4 ci-dessous et ne garde qu'une valeur
historique.

## Pack visuel V4 (`source_assets/concepts/final_v4/`)

| Élément | Valeur |
|---|---|
| Source | `ECLATS_ORAGE_FINAL_ATMOSPHERE_PACK_V4.zip`, fourni par le propriétaire du projet (2026-08-01) |
| Auteur / droits | concepts commandés par le propriétaire pour ce projet ; usage interne de référence |
| Nature | illustrations générées/peintes **hors moteur** — références de composition, ambiance, palette et hiérarchie |
| Statut dans le build | **AUCUN** : jamais asset, jamais skybox, jamais billboard, jamais texture d'UI, jamais preuve (§0.2) |
| Binaires | **versionnés** (2026-08-02) dans `source_assets/concepts/final_v4/` — SHA-256 dans le README du dossier ; ~12,7 Mo en git simple, LFS indisponible (décision consignée) |

Tout ce que ces images montrent est **reconstruit** en 3D réelle et en interface
Godot alimentée par les données réelles. Rien n'en est extrait ni copié-collé.

## Contrôle avant chaque gate artistique

- [ ] Chaque asset du build a une ligne ici.
- [ ] Aucune ressource extraite d'une œuvre commerciale.
- [ ] Aucun nom, symbole, silhouette ou son appartenant à une licence existante.
- [ ] Aucune dépendance à un compte personnel ou à un service payant.
