# WORLD V2 — CONTRAT DE MIGRATION DE SAUVEGARDE

**Statut : VIVANT** · Phase V2.0 — ce document est un CONTRAT, pas une
implémentation. Aucun fichier de sauvegarde réel n'est migré pendant V2.0 ;
`SaveSystem.SCHEMA_VERSION` reste à 4. La migration s'implémente quand le
monde V2 devient jouable (V2.5+), avec les tests exigés au §5 — écrits ROUGES
d'abord.

## 0. État réel constaté (audit V2.0, base `58d4996`)

- Enveloppe : `{schema_version: 4, slot, saved_at_utc, data}` ; écriture
  atomique + `.bak` ; migrations par étape sur COPIE (`save_system.gd:131-171`).
- **Aucun identifiant de monde n'existe.** Le seul indice de lieu est le tag
  `checkpoint` (valeurs réelles : `valley.camp.start`, `dungeon.antechamber`)
  et AUCUN code ne le lit pour router : « Continuer » charge la vallée V1
  inconditionnellement (`main_menu.gd:149-168`).
- `player_position` = dernier sol foulé, primitives x/y/z, traité en entrée
  NON FIABLE : bornes V1 |x|,|z| ≤ 260, −6 < y ≤ 120 ; toute position
  absente/malformée/hors bornes → spawn (`valley_world.gd:1139-1158`).
  Doctrine du projet : **l'absence d'un champ est un état valide**.
- Le payload porte un champ interne `schema` incohérent entre scènes (4 côté
  vallée, 2 côté menu/victoire/donjon) ; seul `schema_version` d'enveloppe
  fait autorité. La migration ne s'y fiera JAMAIS.
- IDs persistants §19.3 `zone.category.name.index` ; les coffres/ramassables
  de lieux DÉRIVENT de l'ID du POI (`valley.poi.x.01` → `valley.chest.x.01`,
  `discovery_rewards.gd:153-155`).

## 1. Identifiants de monde

Déclarés dans `scripts/world_v2/world_ids.gd` (`class_name WorldIds`) :

| Monde | Identifiant | Règle |
|---|---|---|
| Vallée V1 | `neris_v1` | **l'absence du champ `world_version` SIGNIFIE ce monde** — toute sauvegarde de schéma ≤ 4 est une sauvegarde V1 par construction |
| World V2 | `neris_v2` | seul le contenu de `scenes/world_v2/` a le droit de l'écrire |

Ces valeurs sont des identités persistantes : une fois publiées dans une
sauvegarde, elles ne changent plus de sens et ne sont jamais réutilisées pour
autre chose. Test protecteur (déjà actif) :
`test_world_v2_layout.gd::test_les_identifiants_de_monde_sont_distincts`.

## 2. Schéma 5 — le champ `world_version` (additif, non cassant)

- `SCHEMA_VERSION` passera de 4 à 5 au moment de l'implémentation (V2.5+).
- Nouveau champ de payload : `world_version: String` (`"neris_v1"` |
  `"neris_v2"`).
- **Migration 4 → 5** : poser `world_version = "neris_v1"` si absent. Ici,
  poser le champ n'est PAS inventer une donnée (contrairement à la position,
  doctrine 2→3) : toute sauvegarde antérieure au schéma 5 provient
  factuellement du monde V1 — l'écrire est la seule lecture honnête.
- Une sauvegarde de schéma 5 rechargée par un build plus ancien est déjà
  refusée fichier intact (`save_system.gd:117-121`, testé) — pas de nouveau
  risque.
- Les autres champs ne changent NI de nom NI de type. Toute écriture reste
  une FUSION par clé (jamais d'écrasement du payload), comme aujourd'hui.

## 3. Ce qui est conservé tel quel à la migration V1 → V2

Conservés parce que leurs identités ne sont pas spatiales :

| Donnée | Champ(s) | Règle V2 |
|---|---|---|
| Inventaire d'armes + durabilités | `weapons` (instances) | copie telle quelle — `WeaponInstance` est déjà par-instance |
| Arme équipée | `equipped_index` | telle quelle |
| Flèches | `arrows` | telles quelles |
| Ingrédients / plats / buff restant | `ingredients`, `meals`, `buff` | tels quels |
| Fragments de Résonance | `fragments` | tels quels |
| Découvertes de lieux | `discoveries.discovered` | **tels quels** — les 31 IDs §19.3 sont conservés en V2 (layout), donc un lieu découvert en V1 reste découvert en V2 |
| Récompenses prises | `chests_opened`, pickups/ingrédients pris | tels quels — les IDs de coffres dérivent des IDs de POI conservés ; un coffre ouvert ne re-loote jamais (§11.4) |
| État du donjon | `dungeon[room_id]` | tel quel — la logique des salles est un contrat protégé, les `room_id` ne changent pas |
| Victoire | `boss_defeated` | telle quelle |
| Temps de jeu | `playtime_seconds` | tel quel |
| Options | `user://settings.cfg` | hors sauvegarde (§19.1), aucun impact |

Un identifiant inconnu au chargement reste journalisé-et-ignoré sans crash
(comportement existant, `discovery_log.gd:139-145`) — c'est le filet si un ID
V2 rencontre un vieux build.

## 4. La position — JAMAIS réappliquée aveuglément

`player_position`/`player_yaw` d'une sauvegarde dont le `world_version` ne
correspond pas au monde en train de charger sont **ignorés d'office** (pas
« bornés » : ignorés — une position V1 peut être parfaitement dans les bornes
V2 et pourtant au fond d'un lac V2). Le placement suit alors, dans l'ordre :

1. **Dernier checkpoint narratif compatible** — lu depuis le tag `checkpoint`
   existant et la progression :
   - `dungeon.antechamber` → antichambre V2 (logique du donjon inchangée, le
     tag garde son sens) ;
   - `boss_defeated` présent → position de victoire V2 (retour d'exploration) ;
   - état du donjon non vide (`dungeon[...]`) sans tag antichambre →
     checkpoint `dungeon_gate` V2 (le plateau — on ne replace jamais un
     joueur AU MILIEU d'une salle dont l'enveloppe a changé) ;
   - `valley.camp.start` (ou tout tag de vallée) → checkpoint `camp` V2.
2. **Sinon, ancrage sûr de région** — la position V1 est classée par ses
   bornes dans une région V1, mappée vers la région V2 correspondante, et le
   joueur est posé sur le `save_anchor` de cette région
   (`world_v2_layout.json`, `regions[].save_anchor` : plat, au sol, hors
   combat, hors eau). Table de correspondance V1→V2 des régions : portée par
   le layout (chaque POI y garde `v1_site` ET `v2_site` — la région V2 d'une
   position V1 est celle de son lieu V1 le plus proche).
3. **Sinon, spawn V2** — le comportement historique « position inconnue »
   (§19.4), déjà testé côté V1.

Chaque étape émet un message joueur honnête (« Reprise au camp — le monde a
changé »), jamais un silence.

## 5. Tests exigés AVANT d'activer la migration (catégorie D)

À écrire rouges d'abord, dans `tests/world_v2/` :

1. sauvegarde schéma 4 (fixture réelle) chargée après migration → `world_version = "neris_v1"`, TOUS les autres champs inchangés octet pour octet hors champ ajouté ;
2. sauvegarde 4 avec `player_position` V1 valide, chargée en V2 → position IGNORÉE, placement au checkpoint compatible, aucune écriture avant reprise réussie ;
3. sauvegarde avec `checkpoint = dungeon.antechamber` → antichambre, équipement du checkpoint conservé (comportement `boss_arena.gd:374-407` inchangé) ;
4. sauvegarde avec donjon entamé sans antichambre → `dungeon_gate` ;
5. sauvegarde vierge de tout marqueur → spawn V2 ;
6. `boss_defeated` → position de victoire V2 + victoire toujours vraie ;
7. coffres ouverts / lieux découverts V1 → toujours ouverts/découverts en V2 (IDs conservés) ;
8. migration interrompue (fichier temporaire corrompu) → l'original est intact (mécanisme atomique existant, re-testé sur le chemin 4→5) ;
9. schéma 5 relu par le mécanisme V1 → refusé fichier intact (déjà couvert par `test_save_system.gd`, re-vérifié avec la vraie valeur 5) ;
10. AUCUN identifiant persistant V2 ne réutilise un ID V1 pour un AUTRE objet — vérifiable par la table du layout (IDs identiques = même objet logique, IDs neufs = objets neufs).

## 6. Interdits

- Réutiliser un ID persistant pour un autre objet — jamais, dans aucun sens.
- Écrire `world_version = "neris_v2"` depuis autre chose que le contenu
  `scenes/world_v2/`.
- Modifier ou supprimer un champ existant du schéma 4.
- Migrer le fichier source avant relecture de contrôle réussie (le mécanisme
  atomique existant s'applique au chemin 4→5 sans exception).
- Toucher aux sauvegardes pendant la phase V2.0 — le squelette n'écrit RIEN
  (`test_world_v2_skeleton.gd` : slot0 identique à l'octet près).
