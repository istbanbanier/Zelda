# ISS-074 — CONTRAT DE PEUPLEMENT DE WORLD V2

**Statut : VIVANT** · Date : 2026-08-28 · Branche :
`claude/world-v2-iss074-population-contract` · Base : `a8d2f77` (la candidate
de lundi). **Aucun ennemi de production n'est posé par cette branche** — elle
porte le contrat, l'inventaire, le portail rouge et la tranche proposée.
`GO_V2_3_B_LOT2 = FALSE` reste vrai et ce contrat n'y touche pas.

## 1. Le problème, dit une fois

World V2 est un monde d'action-aventure sans un seul adversaire (ISS-074,
`docs/STATUS.md` : « FAIL — zéro ennemi »). Le vide n'est pas un oubli : il
est VERROUILLÉ par
`tests/world_v2/test_world_v2_places_contract.gd::test_aucun_acteur_et_les_routes_restent_libres`,
qui compte le groupe `enemies` sur tout le monde et exige 0. ISS-074 le
diagnostique déjà : « ce n'est pas un bug du contrat, c'est un contrat qui a
survécu à sa raison. Le remplacer par un budget d'IA — un plafond d'agents
actifs, pas une interdiction — est la correction, et elle doit être faite
AVANT le peuplement, pas pendant. »

Ce document EST ce remplacement, écrit avant toute ligne de production.

## 2. Inventaire — ce qui existe, ce qui manque

Relevé sur pièces le 2026-08-28 (chemins et symboles, jamais de numéros de
ligne — règle d'ancrage).

### Prêt, réutilisable tel quel

- **Les cinq familles** : `scripts/enemies/{raider_red,raider_blue,
  raider_black,ravine_troll,centaur_hunter}.gd` sur le socle
  `EnemyBase` (12 états, perception par cadence avec double raycast de LOS,
  ouïe par `NoiseEvents`, mémoire/enquête/retour, territoire borné, alerte
  alliée, fuite, stagger par poise, mort §12.10). Tuning par famille dans
  `resources/enemies/*_default.tres` (`EnemyTuning`), valeurs conformes à
  MASTER_SPEC §12.6. Sept suites d'intégration les couvrent
  (`tests/integration/test_raider*.gd`, `test_ravine_troll.gd`,
  `test_centaur_hunter.gd`, `test_enemy_base.gd`, `test_bestiary_gate.gd`).
- **La coordination** : `CombatCoordinator` — `MELEE_TOKENS = 2`,
  `HEAVY_TOKENS = 1`, `MAX_ACTIVE_AI = 14`, plafond d'activité par distance
  (`_enforce_activity_cap`). Jamais instancié en V2 ; sans lui, le token est
  accordé d'office — un peuplement SANS coordinateur violerait §12.8 en
  silence.
- **La navigation V2 pour gabarit standard** :
  `resources/world_v2/nav/world_v2_navmesh_q{0..3}.tres` (agent 0,7 m),
  validés par `test_world_v2_navigation.gd`.
- **Un territoire construit sur cinq** : `EmberRaiderCampPlace`
  (`valley.poi.ember_raider_camps.01`) — enceinte, deux brèches, flanc
  éboulé, guet, foyer éteint : l'architecture tactique complète, vide par
  contrat (« territoire ennemi SANS acteurs »). Saturé à 45/45 modules
  (plafond exécutable dans `test_world_v2_r2b1_braise.gd`) : les acteurs ne
  peuvent PAS y entrer au budget de modules — ils n'en sont pas.
- **Le conteneur** : `WorldV2.tscn` porte `Encounters` (Node3D), exigé par
  `WorldV2Root.REQUIRED_CONTAINERS`, rempli par personne.

### Absent, à construire (l'ordre est celui de la tranche §6)

| Brique | Fait constaté |
|---|---|
| Bâtisseur de rencontres V2 | aucun équivalent de `ValleyWorld._spawn_bestiary()` ; `Encounters` vide |
| Lecture de `regions[].encounters` | la prose du layout n'est lue par AUCUN script ni test |
| Navmesh V2 grandes carrures | pas d'`OUT_LARGE` dans `bake_world_v2_navmesh.gd` ; pas de groupe `large_navigation` en V2 — colosse et chasseur (`uses_large_navmesh = true`) retomberaient EN SILENCE sur le maillage 0,7 m |
| Persistance des morts | aucun champ ennemi dans aucun payload de sauvegarde (V1 comme V2) — tout remontage ressuscite tout |
| Loot | aucun `LootComponent`, aucune `LootTableDefinition`, aucune `EnemyDefinition` — « tuer ne rapporte rien » (ISS-074) |
| `AILab` | la gate PROMPT2 §8.7 n'a jamais eu de scène |
| Profilage IA en V2 | aucune mesure dans `evidence/` — le budget CPU est INCONNU, pas « acquis » |

Fait utile : l'isolation V1/V2
(`test_world_v2_skeleton.gd::test_aucune_reference_croisee_interdite`)
n'interdit PAS d'instancier `res://scenes/enemies/*.tscn` depuis V2 — les
scènes d'ennemis sont du contenu partagé, pas du contenu spatial V1.

## 3. Le remplacement du contrat « acteur prématuré »

Le contrat actuel (`= 0` partout) est remplacé, LE JOUR DU PEUPLEMENT, par un
contrat de BUDGET à quatre règles — chacune exécutable :

1. **Plafond d'agents** : au plus `MAX_ACTIVE_AI = 14` IA pleinement actives
   (MASTER_SPEC §12.9 : « 10-14 ») ; le plafond est celui du
   `CombatCoordinator`, jamais une seconde constante — une copie diverge.
2. **Un seul coordinateur** : exactement un `CombatCoordinator` dans le
   monde monté, découvert par le groupe `combat_coordinator` — sans lui les
   tokens sont accordés d'office et §12.8 meurt en silence.
3. **Territoire obligatoire** : chaque ennemi posé porte une origine de
   territoire et une `max_pursuit_distance` > 0 — aucun poursuivant infini.
4. **Calmes garantis** : AUCUNE perception ennemie ne déborde sur les zones
   calmes du masterplan (WORLD_V2_MASTERPLAN §8 : crête, prairie, lit de
   rivière, source, sanctuaire, belvédère, berges du lac) ni sur un
   checkpoint.

   **La règle exécutable retenue est plus stricte que cette phrase, et elle
   ne demande aucune liste à tenir à la main** : les disques de VISION,
   d'OUÏE et de POURSUITE de chaque ennemi tiennent entièrement dans les
   bornes de sa propre région. Toute zone calme étant hors de cette région,
   aucune ne peut être atteinte. L'ouïe compte autant que la vision :
   `hear_noise()`, `receive_alert()` et `witness_ally_death()` réveillent un
   ennemi **sans jamais consulter** `max_pursuit_distance`.

   **UNE EXCEPTION, NOMMÉE, ET UNE SEULE** : le checkpoint `camp`
   (45, 6, 65) est DANS r05. Le layout en fait la fonction même de la région
   — « première rencontre 3 approches, cuisine, checkpoint camp » — et sa
   ligne `encounters` dit « garnison braise du camp ». Ce checkpoint est
   l'OBJECTIF de la rencontre, pas un sanctuaire ; exiger qu'aucun garde ne
   le voie rendrait la région impossible à peupler et contredirait le layout.
   Il est donc exclu **par identifiant**, dans une constante unique du
   portail (`CHECKPOINT_OBJECTIF`), pour qu'aucune autre exclusion ne puisse
   se glisser en silence.

   **CE QUE CETTE RÈGLE NE COUVRE PAS, dit ici plutôt que découvert plus
   tard** : elle borne les disques à la position de POSE. Un garde attiré
   par des bruits répétés entre en `INVESTIGATE` vers `_last_known` **sans
   clamp cumulatif sur son origine**, et `FLEE` n'est pas borné davantage.
   Un joueur qui kite délibérément peut donc tirer un garde hors de sa
   région. Ce qui reste garanti en toutes circonstances, et qui est le
   verrou réel : `_tick_perception()` refuse toute ACQUISITION de cible
   au-delà de `max_pursuit_distance` mesurée depuis `_territory_origin` —
   un garde égaré ne peut pas prendre une nouvelle cible hors de son
   territoire. Le clamp du retour appartient à `EnemyBase`, donc à une passe
   qui pourra le prouver.

Jusqu'à ce jour-là, le contrat actuel RESTE en vigueur sur la candidate :
cette branche ne le modifie pas.

## 4. Règles de densité et de territoire

Source : `world_v2_layout.json` (`regions[].encounters`, prose aujourd'hui
morte — ce contrat la rend NORMATIVE), bornée par MASTER_SPEC §12 et
PROMPT2_SPEC §8.

| Région | Rencontre (du layout) | Traduction contractuelle |
|---|---|---|
| r01 (crête du départ) | aucune | zone calme — zéro spawn, zéro perception débordante |
| r02 | patrouille braise légère en lisière | 2-3 `raider_red`, patrouille par `patrol_offsets`, JAMAIS sur la route principale |
| r05 | garnison braise du camp | le camp construit : 3-4 `raider_red` + 1 `raider_blue` au guet — la tranche §6 |
| r06 | camps braise ; territoire du chasseur (SE, facultatif) | chasseur : FACULTATIF, frontière marquée, jamais sur le chemin critique |
| r08 | patrouille azur ; bastion des briseurs | postérieur à la tranche |
| r10 | tanière du colosse (poche NE, facultative) | postérieur ; EXIGE le navmesh large |
| r11 (plateau du donjon) | aucune | zone calme |

Règles transverses :
- deux engagements mêlée simultanés maximum en Aventure (PROMPT2 §8.3) —
  c'est le token, pas une promesse ;
- chaque rencontre a ≥ 12 m de rayon dégagé + une couverture + une sortie de
  fuite lisible (MASTERPLAN §8) ;
- perception honnête : vision par cône + LOS réel, ouïe par événements —
  jamais la position du joueur lue directement (PROMPT2 §8.2) ; c'est déjà le
  comportement d'`EnemyBase`, le contrat l'ÉPINGLE pour qu'il ne régresse pas.

## 5. Respawn et persistance — la règle AVANT le système

MASTER_SPEC §12.10 exige « générer loot une fois, sauvegarder si
nécessaire ». Aujourd'hui rien n'est sauvegardé : tout remontage ressuscite
tout, et tuer ne rapporte rien. Règles posées ici, à implémenter avec la
tranche :

1. **Un ennemi de GARNISON tué reste mort** dans la sauvegarde de la partie
   (champ additif `enemies_slain: Array[String]` d'IDs stables
   `zone.category.name.index`, fusion par clé comme T1) — sinon le camp se
   referme derrière le joueur à chaque reprise.
2. **Une PATROUILLE peut réapparaître** après une vraie transition de scène
   (comportement V1 constaté et acceptable pour des rencontres de route), et
   sa persistance est déclarée EXPLICITEMENT dans le placement — jamais
   ambiguë (§13.1 : « leur persistance est définie explicitement »).
3. **Le loot n'entre PAS dans cette tranche** : la dette est déjà consignée
   (ISS-074, `enemy_tuning.gd`) ; la poser ici sans `LootTableDefinition`
   fabriquerait une demi-économie intestable.

## 6. Tranche verticale proposée — « la garnison du camp braise »

LA plus petite tranche qui rend un affrontement réellement jouable, région
r05, camp déjà construit :

1. **Navmesh d'abord, rien avant** : vérifier que les quatre quadrants
   couvrent le camp et ses brèches (le bâtisseur du camp pose des colliders —
   le navmesh actuel a-t-il été recuit APRÈS le camp ? à mesurer, pas à
   supposer).
2. **`WorldV2EncountersBuilder`** (fichier NEUF — le gel V2.3-B énumère, il
   n'interdit pas d'ajouter) : lit une table de placement data-driven
   (`resources/world_v2/world_v2_garrisons.json — chemin réel, l'ancien `resources/world_v2/encounters/` n'a pas été retenu : …`), instancie sous `$Encounters`,
   instancie UN `CombatCoordinator`, assigne territoire et patrouilles.
   AUCUNE position codée en dur dans le bâtisseur — la leçon de
   `_spawn_bestiary()`, dont la table littérale n'a jamais parlé aux
   territoires.
3. **Garnison** : 3 `raider_red` (foyer, appentis, ronde de palissade) +
   1 `raider_blue` au guet. Le colosse, le chasseur et le bastion attendent
   le navmesh large.
4. **Remplacement du contrat** : `test_aucun_acteur…` devient le contrat de
   budget §3 (même fichier, décision datée dans DECISIONS.md).
5. **Persistance** : `enemies_slain` additif, règle §5.
6. **Preuves** : le portail
   `tests/world_v2/test_world_v2_iss074_portail.gd` passe au vert ; les
   suites bestiaire existantes restent vertes ; un profil du camp à garnison
   pleine (le « profiler un combat avec le nombre maximal d'ennemis prévu »
   de PROMPT2 §8.6) entre dans `evidence/`.

Hors tranche, explicitement : loot, AILab, morale avancée, colosse/chasseur,
bastion azur/briseur, toute retouche des six lieux gelés.

## 7. Le portail rouge

`tests/world_v2/test_world_v2_iss074_portail.gd` monte World V2 et exige :
un adversaire du groupe `enemies` EXISTE, est ATTEIGNABLE (un chemin de
navigation non vide mène du spawn à moins de 4 m de lui), et un
`CombatCoordinator` gouverne le monde. **Il est ROUGE aujourd'hui, sur cette
branche, volontairement** — c'est la définition exécutable de « ISS-074
fermée », écrite avant la production, comme le portail ISS-073 l'a été. La
suite de CETTE branche porte donc un rouge assumé ; la candidate de lundi
n'en porte aucun (cette branche n'y est pas fusionnée).
