# ISS-086 — l'ambiance de la vallée survivait à la vallée

Les journaux que J'AI produits portent en tête un bloc de provenance produit
par la machine : arbre, SHA, état propre ou sale, commande exacte, code retour,
date. **Ceux que produit `tools/gate_fuite_composition.sh` n'en ont pas** — cet
outil n'en émet aucun, et je ne l'ai pas modifié pour cette passe. Leur
rattachement à l'arbre `8254e0b0` repose sur le journal de course
(`gate_fuite/course.log`, conservé) et sur le message du commit, pas sur un
bloc machine. La revendication d'origine — « tous » — était trop large ; la
contre-revue à contexte frais a eu raison de la reprendre. Les gros journaux sont **compressés mais INTÉGRAUX** (`gunzip -c` pour les
lire) : la première version de ce dossier n'en gardait que des extraits rédigés
à la main, et la revue adverse a eu raison de les refuser — un extrait choisi
par sa fin ne peut pas démontrer l'absence d'une ligne qui paraît plus tôt.

## Les journaux

| Fichier | Ce qu'il prouve | Mesure |
|---|---|---|
| `etape1_attribution_2cb48dd6.log` | la fuite est PRÉEXISTANTE, mesurée au SHA de base dans un worktree détaché où aucun fichier n'a été modifié | `AudioStreamWAV=1`, `AudioStreamPlaybackWAV=1`, `amb_valley.wav` encore utilisée |
| `etape2_rouge_avant_correctif.log` | rouge d'abord, **sur la PREMIÈRE version du contrat** (le cas de sortie tardive y porte 6 assertions ; il en porte 5 depuis la revue) | 12 assertions rouges |
| `etape4_p1_contrat_vert.log.gz` | le contrat passe sur l'arbre corrigé, et le rapport de sortie est propre | 4/4, 30 assertions, **0 ligne de fuite** |
| `etape4_p2_ablation_D_sans_proprietaire_rouge.log` | rouge d'abord du cas F : avant le correctif, une demande SANS propriétaire démarrait quand même | `F2` rouge |
| `etape4_p2_ablation_A_arret_retire.log` | rouge d'abord du contrat **LIVRÉ** : on retire l'arrêt, il rougit | 12 assertions rouges |
| `etape4_p2_ablation_B_arret_global.log` | l'arrêt global aveugle vole le son de la scène suivante | `E4` rouge : `playing=false, stream=null` |
| `etape4_p2_ablation_C_sans_liberation.log.gz` | `stop()` SEUL suffit : on retire `stream = null`, le rapport reste propre | **0 ligne de fuite** |
| `etape4_p4_controle_apparie.log.gz` | le reproducteur EXACT de l'étape 1, rejoué sur l'arbre corrigé | **0 ligne de fuite** |
| `etape4_p6_non_regression.log.gz` | rien n'a cassé autour : audio, flux, boot, phase E, menu, victoire | 27/0 |
| `gate_fuite/` | course de composition **n°2**, sur l'arbre committé `8254e0b0` — celle qui fait foi | suite 1045/0 ; `PROJECT_RESOURCE_LEAK_GATE` **VERT** ; portail en code **2** (dérive télémétrie) |
| `gate_fuite_run1_diagnostic/` | course **n°1**, lancée sur l'arbre de `ba829625`, donc AVANT la réécriture du contrat — gardée comme diagnostic, elle ne décrit pas l'arbre livré | mêmes chiffres : 1045/0, 140 objets / 76 ressources |

## Deux choses que ces preuves ne disent pas, et qu'il faut lire avant elles

**1. Le portail de composition sort en code 2, pas en 0.** `PROJECT_RESOURCE_LEAK_GATE`
est vert — plus aucune ressource du PROJET ne survit, c'est la fermeture
d'ISS-086. Mais `ENGINE_SCRIPT_CACHE_TELEMETRY` reste en `DÉRIVE — redevient
BLOQUANTE`, pour une cause entièrement attribuée et étrangère à l'audio : le
`+1 GDScript` de `scripts/localisation/textes.gd`. C'est cette dérive-là, et elle
seule, que l'entérinement accepte (D-061, puis D-063).

**2. Le résidu d'une course PARTIELLE n'est pas celui de la suite.**
`etape4_p6` se termine sur un résidu de fin de processus — mesuré en `--verbose`,
c'est **146 `GDScript` + 104 `GDScriptNativeClass`, et 140 ressources toutes en
`.gd`**. Zéro audio, zéro ressource d'une autre extension. C'est le cache de
scripts du moteur (ISS-065), la catégorie que le contrat couvre. Seule la course
de composition sur la suite ENTIÈRE fait autorité sur le résidu.

## GDScript ne sait pas énumérer l'ObjectDB

La ligne « Leaked instance » n'existe que dans le rapport de SORTIE du moteur.
Le contrat mesure donc l'état du LECTEUR — arrêté, sans lecture, sans flux —
c'est-à-dire la condition à l'endroit où elle se décide. Le rapport lui-même est
jugé par le contrôle apparié et par la course de composition.

Et il faut dire pourquoi ce proxy est nécessaire plutôt que confortable :
la plupart des fichiers de la suite qui montent la vallée appellent
`stop_ambience()` dans leur nettoyage — `git grep -l 'call("stop_ambience")' tests/`
les liste — et `tests/unit/test_audio_sfx.gd` balaie même tous les lecteurs
enfants de l'autoload. La suite efface donc en partie sa propre trace de sortie.
Écrire « deux couches, deux prix » sans le préciser, comme le faisait la
première version de ce fichier, était trop généreux.

## Le piège du recyclage asynchrone, et pourquoi il a failli produire une fausse preuve

Le journal `etape4_p1` portait, dans sa version du 2026-08-30 matin, les deux
lignes qui sont exactement la signature d'ISS-086. Une preuve qui se contredit
elle-même.

La cause n'est pas dans le jeu : `AudioServer::stop_playback_stream` ne libère
rien, il pose `FADE_OUT_TO_DELETION`, et le recyclage demande ensuite un pas de
mixage — le pilote muet mixe toutes les ~93 ms de temps RÉEL — puis un
`AudioServer::update()` appelé depuis `Main::iteration`. Une course FILTRÉE se
termine quelques millisecondes après le dernier arrêt. Le contrat laisse
désormais cette fenêtre (400 ms de temps réel, borné) dans son nettoyage.

La comparaison le montrait déjà : le contrôle apparié et la suite complète — où
des centaines de tests suivent — n'ont JAMAIS affiché de ligne de fuite.

## Le prix, mesuré et non annoncé

Contrat seul : 62 s en mode normal, ~110 s en `--verbose` (5 montages réels de
`ValleyWorld`). Course de composition : **4 317 s**, et elle tient le verrou
partagé du dépôt pendant tout ce temps — `tools/lancer_godot.sh` calcule son
verrou depuis `git rev-parse --git-common-dir`, donc TOUS les worktrees le
partagent.

## Les trois portails finaux, sur l'arbre livré

Les journaux des courses intermédiaires (`2d318931`, `7e98b497`) ont été
REMPLACÉS, pas conservés : garder des preuves qui ne décrivent plus l'arbre
livré est le moyen le plus court de faire croire l'inverse de ce qu'on mesure.

| Fichier | Verdict, sur `da0b3e83` |
|---|---|
| `validate_fast_da0b3e83.log` | **VERT** — gel 46/46, 472 scripts, suite **1046/0**, contrôles négatifs 12/12, résidu agrégé **140 contre un contrat de 140**, `PROJECT_RESOURCE_LEAK_GATE` vert |
| `export_parite_da0b3e83.log` | ISS-071 **VERT**, code 0 — 32 contrôles, 0 rouge, 0 bloqué, 0 non vérifié |
| `export_garnison_da0b3e83.log` | ISS-074 **VERT**, 0 échec — build liée au commit courant, arbre propre à l'export |

La suite passe de 1045 à 1046 : c'est le cas F, qui interdit une ambiance sans
propriétaire.
