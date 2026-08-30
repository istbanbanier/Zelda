# ISS-086 — l'ambiance de la vallée survivait à la vallée

Ce dossier contient les journaux RÉELS, dans l'ordre où ils ont été produits.
Aucun n'est reconstitué, aucun chiffre n'est recopié de mémoire.

| Fichier | Ce qu'il prouve |
|---|---|
| `etape1_attribution_2cb48dd6.log` | la fuite est PRÉEXISTANTE, mesurée au SHA de base dans un worktree détaché où aucun fichier n'a été modifié |
| `etape2_rouge_avant_correctif.log` | le contrat ROUGIT avant le correctif — 12 assertions |
| `etape4_p1_contrat_vert.log` | le contrat passe après le correctif — 3/3, 28 assertions |
| `etape4_p2_controles_negatifs.log` | **trois** ablations : arrêt retiré → 12 rouges ; arrêt GLOBAL → la sortie tardive rouge ; `stream = null` retiré → **aucune fuite, donc `stop()` seul suffit** |
| `etape4_p4_controle_apparie.log` | le reproducteur EXACT de l'étape 1 rejoué sur l'arbre corrigé : plus aucune ligne de fuite |
| `gate_fuite_run1_diagnostic/` | course de composition n°1, gardée comme diagnostic : suite 1045/0, `PROJECT_RESOURCE_LEAK_GATE` VERT, dérive réduite au seul `+1 GDScript` de `scripts/localisation` |
| `gate_fuite/` | course de composition n°2, sur l'arbre FINAL committé — celle qui fait foi |

## Ce que ces preuves NE disent pas

GDScript ne sait pas énumérer l'ObjectDB. La ligne « Leaked instance » n'existe
que dans le rapport de SORTIE du moteur : le contrat ne peut donc pas la lire.
Il mesure l'état du LECTEUR — arrêté, sans lecture, sans flux — c'est-à-dire la
condition à l'endroit où elle se décide.

**Et il faut dire pourquoi ce proxy est nécessaire plutôt que confortable.**
Quatorze fichiers de la suite appellent `stop_ambience()` dans leur nettoyage,
et `tests/unit/test_audio_sfx.gd` balaie même tous les lecteurs enfants de
l'autoload. La suite complète efface donc en partie sa propre trace de sortie :
écrire « deux couches, deux prix » sans le préciser, comme le faisait la
première version de ce fichier, était trop généreux.

Le contrôle apparié qui juge réellement le rapport est
`--filter=phase_e_chain --verbose` — le reproducteur EXACT de l'étape 1 —
rejoué sur l'arbre corrigé, plus la course de composition de `gate_fuite/`.
Sans ce contrôle apparié, la fermeture d'ISS-086 resterait `NON VÉRIFIÉ` :
c'est le constat bloquant de la revue adverse, et il était juste.

## Le prix, mesuré et non annoncé

Contrat seul : ~50 s (5 montages réels de `ValleyWorld`). Course de
composition : plus d'une heure, et elle tient le verrou partagé du dépôt
pendant tout ce temps — `tools/lancer_godot.sh` calcule son verrou depuis
`git rev-parse --git-common-dir`, donc TOUS les worktrees le partagent.

## Ce que la revue adverse à contexte frais a corrigé dans cette livraison

Elle a rendu `FAIL` sur la première version, et sur trois points elle avait
raison :

1. **le contrôle apparié manquait** — la fermeture reposait sur un contrat en
   cours de processus, jamais sur le rapport de sortie que la fiche cite. Il est
   là désormais, et c'est la preuve la plus forte du dossier ;
2. **deux affirmations commitées étaient fausses** — « la source du moteur est
   absente de ce conteneur » (elle est à `/opt/src/godot`) et « `stop()` seul
   n'aurait pas suffi » (l'ablation C mesure le contraire). Corrigées partout,
   avant d'être recopiées ;
3. **le contrat portait des assertions qui ne pouvaient pas rougir** — deux
   préconditions sur des autoloads, et un cas qui réaffirmait son propre
   prédicat. Retirées ou rendues discriminantes.

Un quatrième point a produit un vrai changement de code : le propriétaire était
FACULTATIF, ce qui reconduisait la fuite par un chemin non couvert. Il est
désormais obligatoire.
