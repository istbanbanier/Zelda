# Pack visuel V4 — références finales d'atmosphère

Statut : **références faisant autorité** depuis la Passe visuelle V4.1
(2026-08-01). Elles remplacent toutes les anciennes références visuelles de
paysage, architecture, HUD, inventaire et pause — y compris l'image North Star
unique de Phase 0 (qui reste un document historique).

## Provenance

Fournies par le propriétaire du projet dans
`ECLATS_ORAGE_FINAL_ATMOSPHERE_PACK_V4.zip`, transmis avec l'ordre de la Passe
visuelle V4.1. Ce sont des **concepts générés/illustrés hors moteur** : des
références de composition, ambiance, profondeur, palette et hiérarchie —
**jamais des captures de la build**, jamais des assets.

## Contenu attendu

| Fichier | Sujet |
|---|---|
| `01_WORLD_NORTHSTAR_FINAL_V4.png` | Vallée complète — héros de dos, camp, pylône, rivière en S, citadelle sous orage local |
| `02_DUNGEON_ENTRANCE_FINAL_V4.png` | Entrée monumentale du donjon — porte ouverte, vestibule réel visible |
| `03_GAMEPLAY_HUD_FINAL_V4.png` | HUD en jeu — rubis de vie, stamina radiale, invite E, carte d'arme |
| `04_INVENTORY_FINAL_V4.png` | Inventaire plein écran — 8 cases, stats réelles, panneau de détail |
| `05_PAUSE_MENU_FINAL_V4.png` | Menu pause — panneau ardoise latéral, sensibilité, monde visible derrière |

> **État du dépôt binaire** : le ZIP n'a pas atteint le disque du conteneur au
> moment de l'ordre (vérifié) ; les cinq images ont été transmises et analysées
> dans la conversation — leur lecture détaillée fait foi dans
> `docs/ART_BIBLE.md` §1bis. Déposer les cinq PNG ici pour rendre les
> comparaisons côte à côte reproductibles entre sessions.

## Interdictions absolues (§0.2, .claude/rules/assets.md)

Ne jamais employer ces images comme :

- arrière-plan de gameplay, skybox ou faux monde explorable ;
- billboard, matte painting, façade plate ;
- texture plein écran simulant une interface ;
- preuve de l'état du jeu (une capture vient du renderer, rien d'autre).

Tout ce qu'elles montrent doit être **reconstruit** : environnements 3D réels,
collisions, structures franchissables, interface Godot alimentée par les
données réelles.
