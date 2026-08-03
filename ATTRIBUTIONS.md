# ATTRIBUTIONS

Règle absolue (§2, §7.14) : **aucune ressource n'entre dans le build avant d'être
inscrite ici** avec source, auteur, licence et modifications. Une ressource sans
licence claire n'entre pas dans le build. Aucun asset ne doit exiger le compte
personnel du joueur ni un service payant.

## État à ce jour

Le projet contient des ressources externes d'une seule provenance : les packs
**Quaternius Standard (CC0 1.0)**, inscrits ci-dessous AVANT leur entrée dans
le build (2026-08-02). Tout le reste a été généré par les scripts du dépôt.

## Packs Quaternius Standard — CC0 1.0 Universal (ART-Q0)

| Élément | Valeur |
|---|---|
| Auteur | **Quaternius** (https://quaternius.com) |
| Licence | **CC0 1.0 Universal (Public Domain Dedication)** — confirmée sur le fichier `License*.txt` PRÉSENT DANS CHACUNE des sept archives, https://creativecommons.org/publicdomain/zero/1.0/ |
| Canal d'acquisition | GitHub Release `asset-inbox-quaternius-free-v1` du dépôt du projet (boîte de transport déposée par le propriétaire) ; empreintes SHA-256 vérifiées identiques aux digests GitHub — détail dans `docs/assets/QUATERNIUS_INBOX.md` |
| Archives sources | Stylized Nature MegaKit, Fantasy Props MegaKit, Medieval Village MegaKit, Universal Base Characters, Modular Character Outfits – Fantasy, Universal Animation Library 1 et 2 (éditions Standard, gratuites) |
| Modifications | copies à l'octet près depuis les archives, SAUF les trois dérivations listées ci-dessous ; la sélection (~130 modèles promus sur 2162 entrées) est documentée dans `docs/assets/PROMOTIONS.csv` et `docs/assets/ASSET_MANIFEST.csv` |
| Fichiers dans le build | `assets/environment/{foliage,rocks,props,dungeon}/` et `assets/characters/{hero,enemies,parts}/` — voir manifeste |

### Dérivations d'assets Quaternius (V4 lot 13) — licites en CC0, consignées

| Fichier | Nature de la modification |
|---|---|
| `assets/characters/hero/T_Ranger_Hero_BaseColor.png` | dérivée de `T_Ranger_BaseColor.png` : recoloration turquoise (#168F9B) de la seule région UV de la capuche, script reproductible `tools/godot/recolor_hero_hood.gd`, manifeste JSON à côté du fichier |
| `assets/characters/parts/T_Hair_1_Normal_png.png` | copie octet à octet de `T_Hair_1_Normal.png` sous le nom que le gltf `Superhero_Male_FullBody` référence — correction d'un défaut de nommage AMONT du pack, aucune retouche d'image |
| `assets/characters/parts/T_Eye_Normal_png.png` | idem, copie de `T_Eye_Normal.png` |

CC0 : aucune attribution exigée légalement ; elle est donnée ici par honnêteté
de provenance. Aucun compte, aucun paiement, aucune restriction de
redistribution. Les archives elles-mêmes ne sont **pas** versionnées.

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
| `SK_Raider{Red,Blue,Black}` (.blend, .glb) — Phase H lot H.2 | **création originale du projet** — géométrie générée par `tools/blender/make_raiders.py`. Le SQUELETTE réutilisé est celui du pack Quaternius CC0 déjà attribué ci-dessus (65 os UAL) : seules les formes sont neuves, et c'est ce qui permet de garder les animations existantes | licence du projet (géométrie) · CC0 (squelette, cf. Quaternius) |
| `SK_RavineTroll`, `SK_CentaurHunter` (.blend, .glb) — Phase H lots H.3-H.4 | **création originale du projet** — géométrie et rigs générés par `tools/blender/make_creatures.py`. Aucune anatomie réelle citable : le chasseur n'a ni sabots, ni crinière, ni croupe équine | licence du projet |
| `SK_StormGuardian` (.blend, .glb, textures) — Phase H lot H.1 | **création originale du projet** — géométrie, rig 22 os, UV et atlas générés par `tools/blender/make_storm_guardian.py` (reproductible, seed 20260803). Bête-machine à six appuis : aucune anatomie réelle citable, aucune silhouette empruntée, aucun symbole d'une autre licence | licence du projet |

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
