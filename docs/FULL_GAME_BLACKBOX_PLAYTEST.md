# Playtest du jeu complet en boîte noire

**Nature de ce document : PLAYTEST VISUEL EN BOÎTE NOIRE PAR AGENT IA.**
Ni test automatique, ni validation sur GPU réel, ni validation par humain réel.
Ces quatre choses sont distinctes et ne se remplacent pas.

## État d'avancement

| Parcours | Objectif | Sessions | État |
|---|---|---|---|
| A | découvrir, atteindre le camp, **gagner un combat** | 1 | EN COURS |
| B | inventaire, armes, objets | 0 | NON COMMENCÉ |
| C | trouver et parcourir le donjon | 0 | NON COMMENCÉ |
| D | boss et conclusion | 0 | NON COMMENCÉ |
| E | les 31 lieux, sans coordonnées | 0 | NON COMMENCÉ |

`BL-01` reste donc ouvert : **le jeu complet n'a jamais été terminé en boîte
noire.** Aucun verdict « le jeu est finissable par un joueur » n'est recevable
tant que le parcours D n'a pas été joué.

## Session 1 — profil `decouverte`, parcours A

`evidence/blackbox_player/decouverte_A_20260804_021956/`

Premier playtest du projet où le joueur choisit réellement chacune de ses
actions. Le journal montre la chaîne complète : capture reçue, observation
écrite, décision écrite **avant** l'appel d'outil, entrée envoyée, durée de
jeu, capture résultante.

### Ce que le joueur a compris seul

- que « Nouvelle partie » se clique et que l'écran noir qui suit est un
  chargement, pas un blocage — après avoir hésité et l'avoir écrit ;
- que `Z Q S D` déplacent et que le personnage s'oriente vers sa marche ;
- que `Shift` sprinte, **en déduisant l'endurance de la barre bleue** qui
  apparaît pendant le sprint. Personne ne le lui a dit ;
- que la citadelle et son éclair cyan sont au loin, et qu'un camp de bois se
  trouve sur la droite. Il s'y est dirigé de lui-même.

Ce sont des acquisitions réelles, obtenues sans texte de tutoriel : le guidage
par la curiosité (§6.3) fonctionne au moins jusqu'à l'approche du camp.

### Ce qu'il a signalé, et qui est vérifié

| Constat du joueur | Vérification | Verdict |
|---|---|---|
| « fleur jaune énorme, un quart de l'écran » | `Flower_4_Group` mesuré à **2,49 m** ; bible §3 borne les fleurs à 0,18–0,55 m | **CONFIRMÉ** — défaut réel |
| « écran noir ~35–40 s après Nouvelle partie » | chargement réel en rendu logiciel, aggravé par le verrouillage par pas qui obligeait à huit « décisions » consécutives | **CONFIRMÉ**, en partie artefact du harnais — corrigé (attente jusqu'à 8 s) |
| « pose bizarre, bras écartés » à l'apparition | capture `pas_0015` : pose d'apparition/chute ; le héros s'anime normalement dès `pas_0027` | **À REPRODUIRE** — vu une fois, non expliqué |
| « déplacement saccadé, parfois aucune progression » | rendu logiciel sans GPU + suspension par pas | **NON MESURABLE ICI** — demande un GPU |

### Le défaut principal, et sa portée réelle

La fleur géante n'était pas un cas isolé. La mesure de tout le kit végétal
montre un défaut **systématique** : le kit a été importé sans normalisation
d'échelle et posé à l'échelle native par sept modules.

| Asset | Hauteur mesurée | Borne de la bible §3 |
|---|---:|---|
| `Fern_1` | 2,69 m de haut, **9,05 m de large** | fougère basse |
| `Flower_4_Group` | 2,49 m | 0,18–0,55 m |
| `Flower_4_Single` | 2,42 m | 0,18–0,55 m |
| `Flower_3_Single` | 2,07 m | 0,18–0,55 m |
| `Grass_Common_Tall` | 1,87 m | 0,55–0,95 m |
| `Clover_2` | 1,26 m | trèfle |
| `Plant_1_Big` | 3,76 m | — |

C'est une violation de l'invariant **1 unité = 1 m**, pas un désaccord de
goût : une fougère de neuf mètres de large détruit la lecture d'échelle de la
vallée, donc la profondeur, donc la composition North Star.

Aucun site de placement ne compensait — les facteurs passés vont de 0,85 à 1,3
et sont des variations. Corrigé par `KitScale`, point unique consulté par les
sept modules, avec la table des hauteurs mesurées et visées pour qu'elle reste
vérifiable. Deux tests de régression : un à la source, un dans la vallée
montée.

**585 tests → 587.** Le plancher monte, comme l'exige la règle.

### Ce que la session ne dit pas

Elle s'arrête à l'approche du camp. Le combat n'a pas eu lieu ; aucune note sur
le plaisir du combat, la lisibilité des télégraphes ou l'équilibrage n'est
recevable. Rien non plus sur le donjon, le boss, la conclusion, la fluidité
(pas de GPU) ni le son (pas de périphérique audio).

## Ce que le dispositif vaut

Trois contrôles négatifs sont écrits (`tools/blackbox_player/negative_controls.sh`)
et **n'ont pas encore été exécutés**. Tant qu'ils ne l'ont pas été, on ne sait
pas si un joueur privé d'image continuerait de « raconter » le jeu — auquel cas
tous les verdicts ci-dessus seraient sans valeur. C'est la prochaine action.
