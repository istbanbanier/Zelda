# ISS-074 — le peuplement de World V2, du rouge au vert

Ce répertoire porte la trace COMPLÈTE de la tranche « garnison du camp
braise », dans l'ordre où elle s'est produite. Les journaux rouges sont gardés
volontairement : un portail qui n'a jamais rougi ne prouve rien.

## Le portail, avant et après

| Journal | Ce qu'il montre |
|---|---|
| `portail_rouge_a8d2f77.log` | le tout premier portail, sur la candidate : `0 réussi, 2 échoué` — aucun adversaire, aucun coordinateur |
| `portail_rouge_1717ddfe.log` | le même rouge rejoué sur cette branche après le cherry-pick |
| `portail_renforce_rouge.log` | le portail RENFORCÉ à neuf exigences, écrit avant la moindre ligne de production : **0 réussi, 10 échoué** |
| `portail_vert.log` | après le bâtisseur : **6 réussi, 0 échoué** |
| `portail_vert_navmesh_frais.log` | rejoué après le recuit du navmesh, avec l'ouïe et les ancres de région ajoutées : **6/0** |

## Les contrôles négatifs — chacun ne doit rougir QUE sa règle

| Journal | Sabotage | Attendu / obtenu |
|---|---|---|
| `controle_negatif_s1_vision.log` | vision de l'azur remise à son défaut sauvage (30 m) | la seule règle des calmes rougit — **5 réussi, 1 échoué** |
| `controle_negatif_s2_composition.log` | un pillard braise retiré de la donnée | tout rougit, par les gardes de complétude — **0 réussi, 8 échoué** |
| `controle_negatif_s3_persistance.log` | la mort n'est plus écrite | le seul cas 9 rougit — **5 réussi, 4 échoué** |

## Le navmesh, et pourquoi il a fallu le recuire

`sonde_navmesh_camp.log` est la première mesure : 240 points sondés dans r05,
239 sur navmesh, 238 atteignables. Chiffres exacts — et portant sur un navmesh
cuit le **2026-08-13**, six jours AVANT la géométrie du camp. La sonde
décrivait un terrain nu là où le jeu pose une palissade.

`recuit_navmesh.log` : les quatre quadrants recuits. **Les quatre ont changé
de sha256** — la dérive était réelle. `sonde_navmesh_camp_apres_recuit.log`
est la mesure qui fait autorité, et sur laquelle les quatre positions ont été
re-choisies : une d'entre elles était passée de 0,010 m à 0,830 m d'écart.

## Le combat, prouvé en moteur

| Journal | Ce qu'il montre |
|---|---|
| `combat_rouge_premier.log` | 4/1 — le héros ne blessait jamais le garde : une attaque légère n'est engagée que depuis LOCOMOTION, et il passait son temps en HURT |
| `combat_vert.log` | **5 réussi, 0 échoué** — engagement décidé par l'ennemi, dégâts dans les deux sens, garnison entière tombée, mort du héros qui ne ressuscite personne |

Le second rouge, corrigé entre les deux, ne laisse pas de journal séparé : 45,0
pv avant, 45,0 après, attaque pourtant en phase RECOVERY — le héros frappait
DANS LE VIDE, la hitbox pendant sous `VisualRoot`, seul nœud qui tourne.

## Le coût CPU du camp, exigé par le contrat §6.6

Quatre runs, gardés tous les quatre. Le chiffre unique et net que ce
répertoire affichait — « +6,587 ms » — n'était pas reproductible, et c'est
la mesure elle-même qui l'a démontré.

| Journal | Ce qu'il montre |
|---|---|
| `profil_cpu_INVALIDE_un_seul_processus.log` | gardé POUR SON DÉFAUT : monde témoin 12,629 ms contre 3,857 ms avec garnison — absurde, produit par une sonde qui montait les deux mondes dans le MÊME processus, le témoin payant la démolition du premier |
| run 1 (dans l'historique, commit `fbf2b524`) | machine chargée : moyenne 13,804 / 7,217 → **+6,587** ; p95 44,583 / 23,820 → **+20,763** |
| `profil_cpu_run2_avec.log`, `profil_cpu_run2_sans.log`, `profil_cpu_run2_verdict_rouge.log` | machine calme : moyenne 2,821 / 2,117 → **+0,704** ; p95 4,580 / 5,394 → **−0,814**. Le verdict neuf a rougi — et il avait tort |
| `profil_cpu_run3_arbre_sale.log` | verdict corrigé, VERT, mais l'arbre portait l'outil non committé : **non autoritaire**, gardé pour la traçabilité |
| `profil_cpu_avec.log`, `profil_cpu_sans.log`, `profil_cpu_comparaison.log` | la mesure qui fait autorité, arbre propre |

**Ce que quatre runs ont appris, et qu'un seul cachait.** Les absolus varient
d'un facteur cinq selon la charge du conteneur, et la QUEUE varie davantage
que la moyenne : entre le run 1 et le run 2, le delta de p95 a changé de
signe. Un p95 tiré de 240 échantillons, un seul run par mode, sur une machine
partagée, est dominé par l'ordonnancement.

Le verdict de `profil_camp.sh` ne juge donc plus que ce qui résiste au bruit —
`noeuds`, déterministe et à **+132** aux quatre runs, et la moyenne sur 240
échantillons, positive à chaque fois. Le p95 est **publié, jamais jugé**. Ce
n'est pas un seuil assoupli : c'est une affirmation retirée parce que la
donnée ne peut pas la porter, et le script porte les deux séries qui le
prouvent.

**Ce qu'on peut honnêtement dire du coût** : sur conteneur calme, la garnison
coûte **moins d'une milliseconde** de temps physique moyen et **+132 nœuds**.
Sous charge, le même code affiche plusieurs millisecondes. Aucun de ces
nombres n'est un budget de frame — le rendu est logiciel.

Le journal invalide reste ici parce qu'il enseigne mieux que les bons : une
mesure peut être exacte, reproductible et fausse quand le protocole compare
deux choses qui ne sont pas comparables.

## Le volet EXPORT — ce que seule une build peut casser

| Journal | Ce qu'il montre |
|---|---|
| `gate_export_run_rouge_harnais.md` | le run ROUGE du 2026-08-28 : deux `FAIL` qui ne portaient sur AUCUNE affirmation du jeu, et leur cause |
| `mesure_fermeture_fenetre.log` | le chronométrage qui a tranché : 32 s sur cache froid, 2 s sur cache chaud, contre un budget de 30 s |
| `gate_export_garnison_vert.log` | portail RENFORCÉ après contre-revue : **VERT, 0 échec**, build liée à `9600512e`, arbre propre. Deux contrôles neufs y prouvent ce qu'aucun ne prouvait : les morts SURVIVENT à la réécriture de fermeture (G5), et le balayage de ressources porte sur les **quatre** journaux du run, donjon compris (G7) |

Le portail vert publie l'attente réelle de chaque fermeture — `32 s` pour G5,
`2` à `4 s` ailleurs. Le nombre qui a causé le rouge est désormais visible dans
la preuve elle-même, au lieu d'être caché derrière un verdict.

## Autres pièces

- `contrat_budget_vert.log` — le contrat « acteur prématuré » remplacé par le
  contrat de BUDGET : 5/0.
- `portail_vert_rondes.log` — le portail rejoué après que les décalages de
  ronde ont été repliés dans le contrôle des disques : **6/0**.
- `validate_fast_vert.log` — **PÉRIMÉ, et gardé pour le dire.** La suite a
  bien rendu 999/0, mais elle a été jouée à 20:14 et committée à 20:20 DANS
  LE MÊME COMMIT qu'une modification de `test_world_v2_iss074_portail.gd` :
  ce journal ne décrit donc pas l'arbre qu'il accompagne, et « jouée sur
  l'arbre final » était faux. Constat d'une contre-revue à contexte frais.
  Le journal ne portait ni commit ni état de l'arbre — c'est ce qui rendait
  l'écart invisible ; `validate_fast.sh` imprime désormais sa provenance en
  étape `0a`.
- `validate_fast_arbre_final.log` — la mesure qui fait autorité : **999
  réussi, 0 échoué**, code retour 0, et un en-tête qui dit d'où elle vient —
  `commit 9600512e`, `fichiers sales : 0`.

## Ce qui n'est PAS ici, et le restera

Aucune capture d'écran de la garnison. Le portail d'export est piloté au
clavier synthétique sous Xvfb en rendu **logiciel** : une image en sortirait,
mais elle ne prouverait ni la composition ni la performance, et
`.claude/rules/evidence.md` interdit d'appeler preuve une mesure de rendu
logiciel. Les quatre gardes sont prouvés par le compte du bâtisseur, par la
navigation et par les points de vie, pas par un pixel.

Trois affirmations du contrat ne sont **pas** prouvées par l'export, et le
journal vert le dit lui-même en toutes lettres : dégâts dans les deux sens,
victoire de la garnison, mort du héros et « Réessayer ». Elles sont prouvées
EN MOTEUR par `tests/world_v2/test_world_v2_garrison_combat.gd`, où l'on peut
lire des points de vie — un clavier synthétique sous rendu logiciel ne peut
pas en faire une mesure déterministe.
