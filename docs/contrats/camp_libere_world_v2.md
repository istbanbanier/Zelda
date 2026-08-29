# CONTRAT — le camp braise devient le premier POI COMPLET de World V2

**Statut** : VIVANT. Écrit AVANT la moindre ligne de production, comme l'exige
`PROMPT4_METHOD` §2 et la directive lead du 2026-08-29.

---

## 0. De quel camp on parle, et pourquoi la question n'est pas rhétorique

Le dépôt contient **deux** lieux appelés « camp braise », à 70 m l'un de
l'autre, et les confondre invaliderait tout ce document.

| | `r05_terrasse_du_camp` | `valley.poi.ember_raider_camps.01` |
|---|---|---|
| Rôle du layout | « première rencontre 3 approches, cuisine, checkpoint camp » | POI décoratif des bois du levant |
| Bornes | `x[8,64] z[40,100]` | `v2_site [96, 6, 120]`, région `r06` |
| Checkpoint | **`camp` à (45, 6, 65)** | aucun |
| Garnison ISS-074 | **les quatre gardes y sont** | aucun ennemi |
| Foyer | ALLUMÉ (`CampfireProp` + `Campfire`) | **MORT, et verrouillé par un test** |
| Lieu | `camp_checkpoint_place.gd` (GELÉ) | `ember_raider_camp_place.gd` (GELÉ) |

**Le sujet de ce contrat est r05** — celui où le joueur se bat. Le foyer mort
verrouillé par `test_world_v2_r2b_camps.gd:109` appartient à l'AUTRE camp et
n'est pas touché.

La fiction que cela produit tient debout toute seule : les pillards occupent
la terrasse qui doit devenir le camp du joueur. Le libérer, c'est rallumer son
feu.

---

## 1. Les huit exigences, et ce qui les rend vérifiables

| # | Exigence de la directive | Comment une machine la constate |
|---|---|---|
| C1 | victoire clairement signalée | une notification atteint le HUD par `EventBus.notify` ; le texte vient de la DONNÉE |
| C2 | récompense fixe et utile | un `Chest` porte l'arme nommée dans la donnée ; aucune table de butin, aucun tirage |
| C3 | disponible si le joueur part avant de la prendre | au remontage d'un camp libéré et non pillé, le coffre est REPOSÉ |
| C4 | jamais duplicable après réouverture | l'id du coffre est persisté ; au remontage il est `mark_opened_silently()` |
| C5 | état « camp libéré » persistant | champ ADDITIF dans le slot, écrit par la garde d'ISS-082 |
| C6 | transformation visible minimale | le foyer du camp est ÉTEINT tant que la garnison tient, RALLUMÉ après |
| C7 | aucun fichier gelé modifié | `tools/gel_verifier.sh` rend 0 absent avant et après |
| C8 | aucun texte joueur codé en dur | tout texte affiché vit dans `resources/world_v2/world_v2_camp_liberation.json` |

### Ce que C8 veut dire ici, faute de localisation

Il n'existe **aucun** mécanisme de traduction dans ce dépôt : zéro
`.translation`, zéro section `[internationalization]`, zéro appel `tr()`. Le
motif établi — et déjà verrouillé par des tests — est *« le texte affiché vit
dans la donnée, pas dans le code »* : `@export var display_name` sur une
`Resource` (armes, ingrédients, `PointOfInterest`). C8 est donc satisfaite en
sortant le texte du `.gd` vers un fichier de données, pas en inventant une
table de clés que rien ne lirait.

---

## 2. Le point d'accroche, et pourquoi il ne casse aucun gel

`scenes/world_v2/WorldV2.tscn` n'est **pas** gelé ; `world_v2_root.gd` et
`world_v2_encounters_builder.gd` le sont. Un conteneur FRÈRE d'`Encounters`,
portant un script neuf, suffit :

- `REQUIRED_CONTAINERS` ne vérifie que des PRÉSENCES — un conteneur
  supplémentaire n'est pas refusé ;
- l'ordre d'arbre garantit que son `_ready()` suit celui d'`Encounters`, donc
  que son `call_deferred("_build")` est mis en file APRÈS celui du bâtisseur
  de garnisons : il voit la garnison déjà posée ;
- l'observation passe par les NŒUDS, seule surface publique du bâtisseur gelé :
  `find_children("*", "EnemyBase", true, false)` — `owned=false` obligatoire,
  les ennemis sont créés au runtime — puis `get_meta(&"encounter_id")`.

**Piège nommé ici parce qu'il est invisible** : un ennemi déjà tombé n'est
jamais instancié au rechargement. « Zéro ennemi sous l'hôte » ne distingue donc
pas *camp jamais visité* de *camp libéré*. L'effectif ATTENDU se lit dans
`world_v2_camp_liberation.json`, et les morts dans le slot.

Deuxième piège : `_on_died()` ne libère pas le nœud. Compter les vivants exige
`health().is_dead()`, jamais une simple présence dans l'arbre.

---

## 3. Le foyer : masquer, pas supprimer

Le chemin réel après montage est `Places/place_camp/FeuVisuel`
(`CampfireProp`) et `Places/place_camp/FeuDeCuisine` (`Campfire`).

- **Ce qu'on fait** : `FeuVisuel.visible = false` tant que la garnison tient.
- **Ce qu'on ne fait JAMAIS** : démonter, déplacer, ou sortir `FeuDeCuisine`
  du groupe `interactable` — `test_world_v2_places_behavior.gd:157-161` exige
  au moins un nœud de classe `Campfire` dans ce groupe, et c'est un contrat de
  checkpoint, pas de décor.
- **Ce qu'on ne fait pas non plus** : poser un « foyer éteint » procédural.
  `test_world_v2_r2b_camps.gd:53-75` exige que tout `MeshInstance3D` du camp
  descende d'une scène `res://assets/`, avec une exemption unique bornée au
  sous-arbre d'un `CampfireProp`.

Aucun test du dépôt ne nomme `FeuVisuel`, ne lit sa visibilité, ni n'écarte
les nœuds cachés d'un calcul d'emprise : le masquage est neutre pour les cinq
contrôles qui portent sur ce camp.

---

## 4. La persistance, et le champ qu'on n'invente pas

Deux champs ADDITIFS dans le slot, écrits par `SaveMergeGuard.base_de_fusion()`
— la garde d'ISS-082, sans quoi libérer le camp détruirait la sauvegarde d'un
build futur :

| Champ | Sens | Précédent |
|---|---|---|
| `camps_liberes` | tableau d'identifiants de garnisons vaincues | même forme qu'`enemies_slain` |
| `opened_chests` | tableau d'identifiants de coffres pillés | **nom réutilisé de la V1** (`valley_world.gd`), pas inventé |

`WorldV2Root.autosave()` fusionne (`payload.merge(..., true)`) : ces champs
survivent aux autosaves de position.

**Aucune économie globale, aucune table de butin.** La récompense est UNE
entrée de données nommant une arme existante et un nombre de flèches.

---

## 5. Ce que ce contrat ne prétend pas

- Il ne rend pas la découverte des lieux V2 bavarde : World V2 ne connecte
  toujours pas `DiscoveryLog.discovered` au HUD, et ce n'est pas le sujet.
- Il n'ajoute **pas** de `PointOfInterest` au camp : cela demanderait de
  modifier un lieu gelé. La notification de victoire ne passe donc pas par la
  découverte, mais par la libération — qui est un événement de jeu, pas de
  déplacement.
- Il ne juge **rien** de l'apparence. Les trois captures demandées partent à
  la revue Codex/Istvan ; aucune note artistique n'est rendue ici.
- Le foyer rallumé est une transformation **minimale**, comme demandé : une
  visibilité, pas une passe d'art.
