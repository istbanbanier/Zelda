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

> **État du dépôt binaire : DÉPOSÉ** (2026-08-02, depuis
> `ECLATS_ORAGE_FINAL_ATMOSPHERE_PACK_V4_1.zip` fourni par le propriétaire —
> intégrité vérifiée, 1672×941 chacun, ~12,7 Mo au total, accepté en git
> simple : LFS indisponible sur ce dépôt). L'addendum propriétaire
> `PROMPT_CLAUDE_VISUAL_FINAL_V4.md` accompagne le pack.
>
> | Fichier | SHA-256 |
> |---|---|
> | `01_WORLD_NORTHSTAR_FINAL_V4.png` | `bbcacfdc9a2f814687cc645c3891877b9594c921bc0c2b046f68c1fd0a1c0f0c` |
> | `02_DUNGEON_ENTRANCE_FINAL_V4.png` | `f7424b0d6f55d40ed8a651cbfb36f94309250b395dd6eaf723af604878e8bc6e` |
> | `03_GAMEPLAY_HUD_FINAL_V4.png` | `9f6a9de6176c02b92ecd52d6a2ea67326f94695e59e8e3087c3633efd66ce783` |
> | `04_INVENTORY_FINAL_V4.png` | `8e2b9661f5a76df72517cffbab077f2ae184d3265bae937c7646b2acec1fcf8b` |
> | `05_PAUSE_MENU_FINAL_V4.png` | `4ea5fa19f7bde31a1c6d37d55822f1c745e57ca97ba39fc43a3b0d1783d4fb4d` |
> | `PROMPT_CLAUDE_VISUAL_FINAL_V4.md` | `8c8061d95d4b0eee1bc02522218c3f6c47a9f8bf0d474317da5fab7ecc03e763` |

## Interdictions absolues (§0.2, .claude/rules/assets.md)

Ne jamais employer ces images comme :

- arrière-plan de gameplay, skybox ou faux monde explorable ;
- billboard, matte painting, façade plate ;
- texture plein écran simulant une interface ;
- preuve de l'état du jeu (une capture vient du renderer, rien d'autre).

Tout ce qu'elles montrent doit être **reconstruit** : environnements 3D réels,
collisions, structures franchissables, interface Godot alimentée par les
données réelles.
