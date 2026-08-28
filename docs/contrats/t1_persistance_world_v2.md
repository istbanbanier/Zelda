# T1 — LA PERSISTANCE DE WORLD V2 : CONTRATS ÉCRITS ROUGES D'ABORD

**Statut : VIVANT** · Date : 2026-08-28 · Branche : `claude/world-v2-t1-persistance`
· Base : `a8d2f77` (la candidate de lundi, ISS-073).

Ce document n'est pas une implémentation et n'en contient aucune. Il déclare
ce que T1 doit rendre vrai, avant qu'une seule ligne de production soit
écrite. Les six contrats vivent dans
`tests/world_v2/test_world_v2_t1_persistance.gd` et sont **exécutables** : le
verdict ci-dessous vient du runner, pas d'une lecture.

L'autorité de fond reste `docs/WORLD_V2_SAVE_MIGRATION.md`, écrit dès V2.0.
Ce document-ci ne le remplace pas : il en exécute la part que T1 prend en
charge, et laisse le reste explicitement dehors.

## 1. Pourquoi maintenant

ISS-073 vient de rendre la boucle **atteignable** : le menu ouvre World V2,
une porte mène au donjon, le retour replace le héros devant elle. Le défaut
suivant sur le chemin critique est qu'elle ne se **reprend** pas.

Ce n'est pas une déduction, c'est écrit aux deux bouts du code :

- `scripts/world_v2/world_v2_root.gd` énumère trois provenances de placement
  et en écarte une — « une position sauvegardée — hors périmètre de cette
  corrective » ;
- `scripts/ui/main_menu.gd` charge la sauvegarde, vérifie qu'elle est lisible,
  puis appelle `_enter_world()` sans jamais la regarder — « le checkpoint
  World V2 repart de son spawn canonique ».

Conséquence pour un joueur : « Continuer » rouvre le monde au point de départ,
quelle qu'ait été la partie. Un joueur arrêté dans l'antichambre du boss
refait tout le donjon.

## 2. Portée — ce que T1 fait, et ce qu'il ne fait pas

**Dans T1.** World V2 écrit et relit **son propre** état de reprise :
position, orientation, et le lieu où rouvrir la partie. Les champs employés
existent déjà au schéma 4 (`player_position`, `player_yaw`, `checkpoint`) ;
le seul champ nouveau est `world_version`, prévu de longue date par le
contrat de migration §2.

**Hors T1.** La migration V1 → V2 elle-même — le remappage d'une position V1
vers un checkpoint ou une ancre de région V2 (contrat de migration §4, tests
de catégorie D). T1 en tient seulement l'invariant qui la précède : une
position V1 n'est **jamais** réappliquée dans World V2. Où le héros atterrit
à la place restera « le point d'apparition » tant que la migration n'est pas
écrite.

Également hors T1, et pour la même raison qu'ISS-073 : aucune retouche
artistique, aucun Lot 2, aucun ennemi, aucune localisation, aucune réécriture
générale de la sauvegarde.

## 3. Les six contrats

| # | Contrat | Ce qu'il mesure | Verdict à l'écriture |
|---|---|---|---|
| C1 | la position du héros survit à un démontage/remontage | monte, déplace, sauvegarde, démonte, **remonte, mesure la position obtenue** | **ROUGE** — 3 échecs |
| C2 | l'orientation survit au même cycle | le lacet du `VisualRoot` — jamais celui du corps, qui vaut 0 par construction | **ROUGE** — 2 échecs |
| C3 | la reprise rouvre la scène où l'on s'est arrêté | on presse « Continuer » comme un joueur et on lit la destination annoncée par `SceneFlow` | **ROUGE** — 2 échecs |
| C4 | une position V1 n'est jamais réappliquée en V2 | une coordonnée V1 plausible et **dans les bornes V2** ne doit pas être appliquée | vert — filet, 7 assertions |
| C5 | une sauvegarde corrompue replie sur le spawn | quatre formes malformées + un JSON tronqué | vert — filet, 22 assertions |
| C6 | les identifiants de lieux sont stables entre deux montages | deux montages, même carte identifiant → position | vert — filet, 40 assertions |
| C7 | la mort ne déplace pas le point de reprise | tuer le héros ailleurs, sauvegarder, relire | **né APRÈS l'implémentation** — voir §7 |
| C8 | le chemin RÉEL d'autosave | vraie transition `SceneFlow`, fusion éprouvée par témoins, reprise par le vrai bouton du menu, débranchement prouvé sur monde libéré | né de la contre-revue §9 — vert, 23 assertions |
| C9 | fermer le jeu sauvegarde ; la perte brutale est bornée | `NOTIFICATION_WM_CLOSE_REQUEST` + minuterie épinglée à 60 s + « jamais en l'air » (vrai saut) | **rouge d'abord** (2 échecs), puis vert, 14 assertions |
| C10 | l'autosave n'écrase jamais un slot illisible | schéma futur et JSON tronqué : fichier intact à l'octet près | **rouge d'abord** (2 échecs), puis vert, 9 assertions |
| C11 | reprendre dans l'antichambre ne vide pas l'inventaire | graine riche → « Continuer » → écriture différée **prouvée** → ce qu'une relance LIRA (le slot) et ce qu'elle JOUERA (le sac du héros) | **rouge d'abord** (2 échecs), puis vert — ferme ISS-080 |

C1, C2 et C3 sont les contrats **rouges** : ils décrivent le défaut. C4, C5 et
C6 sont des **filets** déjà verts, qui doivent le rester — c'est là qu'un T1
mal écrit se fera prendre. Un T1 qui relirait `player_position` sans regarder
`world_version` verdirait C1 et rougirait C4, exactement comme il faut.

## 4. La méthode, et le piège qu'elle refuse

Le portail ISS-073 a mis trois erreurs au jour, toutes du même genre :
**mesurer une grandeur voisine de celle qui compte** — le produit scalaire
calculé sur le corps au lieu du visuel, le lambda qui capture par valeur, le
tag d'aller confondu avec celui du retour.

L'équivalent ici serait de tester `SaveSystem.save_slot()` puis `load_slot()`
— la comptabilité du dictionnaire — et d'en conclure que la reprise
fonctionne. Cela ne prouverait rien : `SaveSystem` marche déjà, et c'est
World V2 qui ne s'en sert pas.

**Un contrat n'est donc vert ici que s'il a monté le monde, écrit, démonté,
remonté, et mesuré la position réellement obtenue.**

Chaque contrat asserte séparément l'**écriture** (par la méthode du monde) et
la **lecture** (depuis un slot posé à la main par le chemin pavé). Écrire et
relire sont deux défauts distincts : un monde qui sauvegarderait sans relire,
ou relirait ce que personne n'écrit, n'échouerait que sur une moitié.

### Le contrôle négatif : un seul sabotage, trois preuves

Un test rouge prouve qu'un défaut existe. Il ne prouve pas qu'il deviendra
vert pour la bonne raison. Contrôle exécuté : poser dans `world_v2_root.gd`
une restauration **aveugle** — relire `player_position` de `slot0` et
l'appliquer sans regarder `world_version`. C'est très exactement
l'implémentation naïve que T1 pourrait produire.

Verdict mesuré, `3 réussi(s) / 7 échoué(s)` avant, `1 / 8` après :

| Contrat | Sans sabotage | Avec restauration aveugle | Ce que ça prouve |
|---|---|---|---|
| C1 | 3 échecs | **1 échec** — la moitié lecture VERDIT | le cas est satisfiable, et il mesure bien la position rendue |
| C2 | 2 échecs | 2 échecs | l'orientation est un défaut distinct de la position |
| C3 | 2 échecs | 2 échecs | le routage de reprise est un défaut distinct |
| C4 | vert | **ROUGE** | le filet attrape la position V1 réappliquée |
| C5 | vert | **ROUGE sur 2 formes / 4** | et exactement les deux dont les composantes sont des `float` : hors bornes, et sous le filet de chute. Les deux autres restent vertes parce que leurs types sont faux — la discrimination est fine, pas globale |
| C6 | vert | vert | sans rapport, et il le montre |

Autrement dit : l'implémentation qui ferait verdir C1 le plus vite est prise
en étau par C4 et C5. C'est ce que doit faire une batterie de contrats.

Le sabotage a été retiré et l'identité du fichier vérifiée au sha256.

### Un défaut de harnais, trouvé par le premier rouge

`restore_root()` **vide sa photo en sortant**. Un cas qui monte deux fois
appelait donc `restore_root()` deux fois pour une seule `remember_root()` — et
le second balayage, photo vide, prenait les autoloads pour des intrus et
**supprimait `GameState`, `EventBus` et `SaveSystem`**. Correction : la photo
est prise dans le montage, une par montage. Consigné ici parce que le piège
attend tout autre fichier de test qui monte deux fois dans un même cas.

## 5. Ce que T1 devra lever, explicitement

`tests/world_v2/test_world_v2_skeleton.gd` exige aujourd'hui que `slot0` soit
« identique à l'octet près après le passage en V2 ». Ce contrat datait du
squelette, quand World V2 ne devait pas déranger le jeu V1. World V2 **est**
le jeu depuis que le menu l'ouvre : le contrat a survécu à sa raison.

**Et la mesure a tranché : la levée n'a pas été nécessaire.** World V2 n'écrit
qu'au DÉPART d'une transition (`SceneFlow.transition_started`) ; monter puis
démonter le monde n'en déclenche aucune, et la suite complète passe —
`test_world_v2_skeleton.gd` compris. Le contrat garde donc son sens et sa
force. C'était un raisonnement avant l'exécution ; c'est un constat depuis.

Ce qui a bel et bien demandé une levée, c'est le gel V2.3-B sur
`world_v2_root.gd` — une empreinte, documentée en D-056, comme D-055 l'avait
fait pour ISS-073.

*(Il n'y a pas de §6 : la numérotation saute, elle n'a pas été rompue par
un déplacement. Signalé ici pour qu'on cesse de le chercher.)*

## 7. C7 — le contrat que la contre-revue a fait naître

C1 à C6 ont été écrits avant l'implémentation. **C7 ne pouvait pas l'être** :
il décrit un défaut que le correctif lui-même a créé, et c'est la contre-revue
à contexte frais (§6 de la directive ISS-073) qui l'a désigné.

Le crochet d'autosave de T1 est branché sur `SceneFlow.transition_started` —
donc sur TOUTES les transitions, « Réessayer » compris. Sans garde, mourir
inscrivait le lieu de sa mort comme point de reprise : le joueur ressusciterait
là où il vient d'être tué. La règle posée est aussi simple qu'elle en a l'air :
**on ne sauvegarde pas la position d'un mort.**

Le contrôle négatif a en outre PRÉCISÉ le constat que la contre-revue avait
formulé plus largement. En retirant les deux gardes de C7, **un seul**
assertion rougit : celle du mort. La seconde moitié — « Réessayer » reprend au
dernier état sauvegardé — reste verte sans la constante `RETRY_TAG`, parce que
le placement correct vient de C1. Ce que `RETRY_TAG` corrige est donc un
avertissement FAUX (« tag d'apparition inconnu »), émis à chaque mort, pas un
défaut de placement. La distinction est écrite dans le test lui-même.

Verdict complet après implémentation : **7 réussis, 0 échoué, 115 assertions**,
0 erreur de script. Suite complète du dépôt : **983 réussis, 0 échoué** —
`test_world_v2_skeleton.gd` compris, ce qui règle §5 : le contrat « slot0
identique à l'octet près » survit à T1 sans levée, parce que World V2 n'écrit
qu'au DÉPART d'une transition, et que monter puis démonter le monde n'en
déclenche aucune.

## 8. Interdits de la passe T1

- Fusionner quoi que ce soit de T1 dans la candidate de lundi avant
  contre-revue.
- Modifier ou supprimer un champ existant du schéma 4.
- Écrire `world_version = neris_v2` depuis autre chose que `scenes/world_v2/`.
- Verdir un contrat en changeant sa mesure plutôt que le produit.

## 9. La contre-revue du diff final, et ce qu'elle a coûté

La décision lead du 2026-08-28 a exigé une contre-revue à contexte frais du
diff T1 COMPLET (`a8d2f77..84fe2c0`) — la précédente portait sur la candidate
ISS-073, pas sur ce diff. Verdict : **PARTIAL, deux conditions avant toute
build** ; rapport et sort de chaque constat dans
`evidence/world_v2/t1_persistance/contre_revue_t1_fable5.md`.

Les trois FAIL de la revue sont devenus trois contrats :

- **C10** ferme le point le plus dangereux du diff, que la revue a nommé
  avant que le rouge ne le mesure : `load_slot` rend `{}` sur un fichier
  corrompu ET sur un schéma plus récent refusé « fichier intact » — et
  l'autosave fusionnait dans `{}` puis écrasait fichier ET `.bak`. Deux
  transitions détruisaient tout. La garde : un slot présent mais illisible
  n'est JAMAIS réécrit.
- **C9** ferme le geste de sortie le plus naturel d'un joueur : la croix de
  la fenêtre, qu'aucun code n'écoutait. Fermeture → écriture ; minuterie de
  60 s pour borner un arrêt brutal ; position toujours au dernier sol foulé.
  Son premier rouge a aussi appris un piège d'appareil : `is_on_floor()`
  reste vrai UN tick après un repositionnement instantané (le drapeau vient
  du `move_and_slide` précédent), et un téléport de test empoisonnait
  l'enregistreur de sol — le cas mesure désormais un VRAI saut.
- **C8** rend exécuté ce qui n'était que lu : la vraie transition
  `SceneFlow`, la fusion (témoins `boss_defeated`/`weapons` semés AVANT — une
  affectation sèche à la place du `merge` rougit), la reprise par le vrai
  bouton du menu avec position ET orientation mesurées dans le monde remonté,
  et le débranchement (`_exit_tree`) prouvé par une émission sur monde libéré,
  slot intact à l'octet près.

Les détails non corrigés sont consignés : ISS-079 (autosave V1 sous signature
V2, latent), ISS-080 (inventaire par défaut au « Continuer » antichambre,
préexistant), ISS-081 (tag fantôme sur `go_to` échoué, préexistant).

## 10. C11 — ISS-080 fermée, et pourquoi ce cas ne peut pas mentir

La décision lead du 2026-08-28 a rouvert le détail n° 6 de cette contre-revue.
ISS-080 n'était pas une gêne cosmétique : `antechamber.gd` posait son
checkpoint par `call_deferred("_write_checkpoint")`, et cette écriture
recopiait dans la sauvegarde l'inventaire du `Player` **fraîchement monté** —
le kit par défaut de `Player.tscn`. Or T1 route désormais une reprise vers
`dungeon.antechamber`. Le joueur qui rouvrait sa partie là perdait donc tout
ce qu'il portait, **à la seconde du chargement**, sans un message.

Mesuré, pas déduit — le premier rouge de C11, mot pour mot :

> 1 arme(s) au lieu de 3 · arme équipée n° 0 au lieu de 1 · 8 flèche(s) au
> lieu de 37 · 0 « storm_berry » au lieu de 3 · 0 « heal_fruit » au lieu de 2
> · 0 « rare_spice » au lieu de 1 · 0 plat(s) au lieu de 1

C'est exactement le contenu de `Player.tscn` : une `worn_sword`, huit flèches,
rien d'autre.

**La garde qui empêche C11 d'être vert pour rien.** Un cas qui se contenterait
de comparer la sauvegarde avant et après serait vert si l'antichambre
n'écrivait **rien du tout** — la graine serait simplement restée intacte.
C'est le mode de panne d'ISS-018 : un test vert sur une grandeur qui n'est pas
celle qu'on croit mesurer. C11 vérifie donc D'ABORD, par `checkpoint_written()`,
que l'écriture différée a réellement eu lieu ; ce n'est qu'ensuite qu'il
compare. Cette assertion-là était **verte dès le premier rouge**, et c'est ce
qui rend les deux autres décisives.

**Les deux moitiés du mot « relance ».** Une reprise n'est pas seulement un
fichier : c'est aussi une partie qui se joue. C11 mesure donc

1. ce qu'une relance **LIRA** — le slot sur disque après l'écriture ;
2. ce qu'une relance **JOUERA** — l'inventaire vivant du héros après un
   remontage de l'antichambre depuis ce même slot.

Les deux étaient rouges, pour deux causes différentes : la première parce que
l'écriture écrasait, la seconde parce que **rien ne restaurait**.

**La correction, et sa retenue.** Le mécanisme existait déjà dans
`boss_arena.gd`, qui relit ce même checkpoint pour rendre le « Réessayer »
honnête. L'antichambre le fait désormais aussi, avant son écriture différée.
On restaure l'inventaire et **rien d'autre** : ni la santé, ni la position, ni
les circuits — ils ne sont pas l'affaire de ce ticket. Aucun contrôle
d'identité de monde n'est posé, et c'est délibéré : un identifiant d'arme ou
d'ingrédient ne dépend d'aucune carte, contrairement à une position (§4 du
contrat de migration ne s'applique donc pas ici).

**Un effet de bord, dit honnêtement.** Aucune salle du donjon ne restaurait
l'inventaire ; chaque salle monte un `Player` neuf au kit par défaut. En
restaurant à l'entrée de l'antichambre, un joueur venu de la salle centrale
retrouve désormais aussi ce que son dernier checkpoint portait. C'est une
amélioration, pas une régression — mais c'en est une, et elle est notée ici
plutôt que découverte plus tard.

**Une garde de plus, du même sang que C10.** `_write_checkpoint` repartait de
`{"schema": 2}` quand `load_slot` rendait `{}` — donc écrasait un slot
seulement *illisible* par un état neuf **et rétrogradé de schéma**. C'était,
dans l'antichambre, très exactement le défaut que C10 venait de fermer dans
l'autosave. Un slot présent mais illisible n'est plus jamais réécrit ici non
plus.
