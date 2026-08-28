# ISS-073 — la boucle de campagne, prouvée

**Commit de la correction** : `03e8b9d` (portail + correctif), `b2e5bb1`
(chaîne combinée), `b8fd648` (levée de gel documentée).
**Moteur** : Godot 4.7.1.stable.custom_build.a13da4feb, conteneur headless
sans GPU (Xvfb + Mesa llvmpipe pour tout ce qui rend).

## Le défaut, tel qu'il était

Le menu principal ouvre `WorldV2.tscn` depuis le passage à World V2
(`scripts/ui/main_menu.gd`, `WORLD_SCENE`). Trois ruptures s'ensuivaient :

| # | Rupture | Constat |
|---|---|---|
| 1 | Aucune `SceneDoor` sous `scripts/world_v2/` ni `scenes/world_v2/` | le donjon était **inatteignable** : `dungeon_gate` est un `Node3D` nu, avec lequel on ne peut pas interagir |
| 2 | `WorldV2Root` ne consommait aucun `pending_spawn` | un retour du vestibule replaçait le héros au spawn initial |
| 3 | Deux chemins de campagne visaient encore le monde V1 | `victory_screen.gd::VALLEY_SCENE` et la porte de sortie du vestibule |

## Les deux portails

```bash
tools/lancer_godot.sh --path . --script tools/godot/test_runner.gd -- --filter=iss073
```

- `tests/world_v2/test_world_v2_iss073_boucle.gd` — 5 cas, 24 assertions.
  Part du menu principal, monte World V2, MARCHE la route officielle jusqu'au
  seuil, franchit par la touche d'interaction, puis vérifie le retour.
- `tests/world_v2/test_world_v2_iss073_chaine.gd` — 5 cas, 36 assertions.
  Les deux retours vers World V2 sont JOUÉS ; l'intérieur du donjon est
  vérifié en câblage, et le fichier le dit en toutes lettres.

## Ce que les portails s'interdisent

Appeler `SceneDoor.interact()`, appeler `SceneFlow.go_to()`, écrire
`global_position` après le spawn. Le seul geste est la touche d'interaction,
et la marche est mesurée : plus grand déplacement en un tick, et distance
parcourue depuis le spawn.

## Sabotages joués

Chacun a été posé, mesuré, puis retiré. Aucun n'est resté dans l'arbre.

| Sabotage | Assertions rougies | Message |
|---|---:|---|
| `door.spawn_tag = &""` | 2 | « la porte d'ALLER doit poser le tag que le vestibule consomme » |
| `if false and arrival == RETURN_TAG` | 2 | retour mesuré en `(0, 170)` — le spawn initial — au lieu de `(0, -210)` |
| sortie du vestibule renvoyée vers V1 | 5 | dont l'énumération des portes qui NOMME la coupable |
| `DoorArena` détournée vers le hall | 1 | « l'antichambre doit ouvrir l'arène » |
| marche supprimée | 2 | l'interaction ne part pas : le héros entre dos à la porte |

Le deuxième reproduit **exactement** le symptôme d'ISS-073.

## La BUILD EXPORTÉE — `build_exportee/`

Les deux portails ci-dessus tournent dans l'éditeur headless. ISS-071 a montré
ce que vaut cet angle : un défaut qui n'existe QUE hors éditeur, invisible à
toutes les suites du dépôt. Le correctif a donc été rejoué sur un **binaire
autonome**, exporté depuis le commit `c3f1819` sur un arbre propre.

| | |
|---|---|
| Binaire | `EclatsDOrage.x86_64`, 398 840 568 octets, PCK embarqué |
| sha256 | `6ba985ef76228747b349308f4e6b0bd7b0ec9fe0b464d57a7dc71801a3605ac4` |
| Moteur | 4.7.1.stable.custom_build.a13da4feb — template recompilé depuis les sources, le conteneur ayant été recréé |
| Lancement | Xvfb, `--rendering-driver opengl3`, installation NEUVE (`user://` vierge, 0 entrée) |
| Pilotage | « Nouvelle partie » par le FOCUS X — jamais `xdotool key --window`, qui serait ignoré SANS erreur |

**Portail ISS-071** (`portail_iss071.log`) : **RC=0**, 32 contrôles, 0 rouge,
0 bloqué, 0 non vérifié. Le manifeste écrit par le jeu exporté lui-même
(37 367 o) répond à celui de l'éditeur (37 368 o).

**Portail ISS-073** (`portail_iss073.log`) : **RC=0**, cinq constats lus dans
ce que le jeu dit de LUI-MÊME (`jalons_world_v2.txt`) :

```
[world_v2] lieux        : 15 scène(s) posée(s) par le layout
[world_v2] porte donjon : posée au seuil §3.3
[world_v2] arrivée      : spawn
[world_v2] fondation V2 vérifiée — vallée whitebox prête.
```
plus zéro erreur de script ou de ressource au montage — parce qu'ISS-071
échouait EN SILENCE, et que l'absence de plantage ne prouve rien.

## Ce que RIEN de tout cela ne prouve

Que le joueur **marche** jusqu'à la porte dans la build. Le rendu est logiciel
et l'horloge de jeu découplée du temps réel d'un facteur 17 à 76 (ISS-072) :
380 m de marche y coûteraient des dizaines de minutes de mur pour une mesure
qu'aucun budget ne rendrait crédible. La marche est prouvée en ÉDITEUR, le
PACKAGING dans la build, et le plaisir par ni l'un ni l'autre — il attend
l'essai d'Istvan (`docs/PLAYTEST_ISS073.md`).

Ni la fluidité : une mesure prise en rendu logiciel n'est jamais un budget de
frame.

## La CANDIDATE de lundi

**Pré-publication** (`prerelease: true`), pas une livraison officielle :
<https://github.com/istbanbanier/Zelda/releases/tag/world-v2-candidate-iss073-98cbaf0>

Construite par la CI depuis `98cbaf0`. Le code du JEU y est identique à
`c3f1819`, l'arbre exporté et mesuré localement — entre les deux, seuls
`docs/` et `evidence/` ont bougé, ce que `git diff --name-only c3f1819..HEAD`
atteste.

| Cible | Fichier | SHA-256 |
|---|---|---|
| Windows 64 bits | `EclatsDOrage_Windows_x86_64_98cbaf0.zip` | `ba431dc96417d5d6e42b142dc7738b40536d65f75ab35121df3f5b06fefa66fa` |
| macOS | `EclatsDOrage_macOS_98cbaf0.zip` | `411df11c4dd7f8e8fe1ef6027c3c82c736768198fdd11908091a0b3ae58acad9` |
| Linux x86_64 | `EclatsDOrage_Linux_x86_64_98cbaf0.zip` | `30ef276c3f5f3ae1c148c6e8f111cd7d1439f2c34747355312789a4e7717c054` |
| Projet Godot | `EclatsDOrage_MondeOuvert_98cbaf0.zip` | `669f6400dfe247cb663fc6f7cfc8ea6726b78ca115bf49a0534fe18e27d5d01a` |

`docs/PLAYTEST_ISS073.md` y est joint, ses `@@SHA@@` remplis PAR LE RUN depuis
le commit qu'il construit réellement — un SHA écrit d'avance serait soit
circulaire, soit une ancre morte.

**Ce n'est pas la build que j'ai testée localement.** Celle-ci vient du runner
GitHub avec les templates officiels ; la mienne venait d'un template compilé
ici. Les deux partent du même code de jeu, et c'est la CANDIDATE qui doit être
jouée lundi — pas `world-v2-playtest-lot1r2-05d0760`, qui est antérieure à la
réparation de la boucle.


## Rectification des compteurs — 2026-08-28

La contre-revue §6 a relevé trois chiffres de prose divergents : ce fichier
annonçait « 5 cas, 23 assertions » et « 4 cas, 29 assertions », et
`docs/STATUS.md` « 9 cas ». Recomptés dans `suite_unitaire_c3f1819.log`, qui
est la preuve datée :

    boucle  5 cas, 24 assertions
    chaîne  5 cas, 36 assertions
    total  10 cas, 60 assertions

Les deux lignes ci-dessus sont corrigées ; `docs/STATUS.md` ne porte plus de
compteur du tout, conformément à la règle d'ancrage — le chiffre vit dans la
preuve datée, pas dans la prose qui le recopie.
