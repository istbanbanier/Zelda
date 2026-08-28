# Contre-revue ISS-073 — §6 de la directive, contexte frais, modèle Fable 5

Date : 2026-08-28. Candidate revue : **`98cbaf0`** (tête de branche `a8d2f77`).
Revue exécutée en LECTURE SEULE, moteur non lancé — le verrou était tenu par
la session T1. Toutes les lectures sont passées par `git show 98cbaf0:<chemin>`
et non par le disque : l'arbre de travail était vivant pendant la revue, et le
rapport le dit lui-même.

Ce fichier consigne le VERDICT et les constats. Il ne corrige rien : les
corrections appartiennent à leurs passes respectives, et l'une d'elles est
déjà faite (constat 1, voir plus bas).

## Les huit points de la directive

| # | Point | Verdict |
|---|---|---|
| 1 | Entrée réelle dans le donjon | PASS |
| 2 | Accord des tags aller / retour | PASS |
| 3 | Consommation unique du `pending_spawn` | PASS, 1 constat |
| 4 | Aucun retour vers le monde V1 | PASS |
| 5 | Chaîne jusqu'à la victoire | PARTIAL — conforme à ce qui est annoncé |
| 6 | Protocole F4 | PARTIAL |
| 7 | Analyseur de gravité | PASS |
| 8 | Cohérence feuille de route / STATUS / KNOWN_ISSUES | PASS, 2 détails |

Vérifications annexes du relecteur : `validate_fast_c3f1819.log` → RC=0 et 977
`ok` **comptés dans le log**, pas recopiés ; les deux portails d'export RC=0 ;
la release vérifiée EN LIGNE — `prerelease: true`, `target_commitish` = la
candidate, et les **quatre digests SHA-256 publiés par l'API GitHub
correspondent exactement** au tableau du README ; `git diff c3f1819..98cbaf0`
ne touche que `docs/` et `evidence/`.

## Constats, par sévérité

**À corriger**

1. `scripts/ui/gameplay_shell.gd` — `retry_checkpoint` est posé par
   « Réessayer » et compris par AUCUNE scène ; World V2 le traitait en tag
   inconnu. **Déjà corrigé** sur la branche T1 (`RETRY_TAG`, contrat C7). La
   contre-revue décrivait aussi un dépôt au spawn « à 380 m du lieu de la
   mort » : le contrôle négatif de C7 a précisé le constat — le placement
   correct vient de la reprise T1, et `RETRY_TAG` ne corrige qu'un
   avertissement FAUX émis à chaque mort.
2. `tools/analyse_journal_devmode.py` (fonction `juger`) — au-delà de **9**
   marqueurs dans une session, l'outil prend silencieusement les 9 premiers et
   peut rendre `FAIL` sur une erreur de PROTOCOLE (un repos surnuméraire
   décale les paires). Le contrat promet de « dire lui-même si la séquence est
   incomplète » : vrai seulement en dessous de 9. Risque : imputer au jeu un
   défaut du testeur — la faute que `docs/contrats/s1_1_gravite.md` nomme
   elle-même. **NON CORRIGÉ.**
3. `docs/PROTOCOLE_SAUT_ISTVAN.md` — un seul marqueur aérien par saut et 3/3
   exigés ; un appui plus de ~0,55 s après `Espace` donne moins de 0,50 m,
   donc `FAIL`, annoncé à Istvan comme « rouge — vrai défaut ». Le contrat
   initial prenait le **max de deux** repères aériens précisément pour cette
   marge ; le protocole à 9 appuis l'a perdue. **NON CORRIGÉ.**

**Détails**

4. Compteurs en prose divergents : `docs/STATUS.md` dit « 9 cas » ;
   `evidence/world_v2/iss073/README.md` dit « 5 cas, 23 assertions » et
   « 4 cas, 29 assertions » ; le réel est **10 cas, 60 assertions**, compté
   dans le log. `docs/TEST_REPORT.md` est juste. La règle d'ancrage du dépôt
   — le chiffre vit dans la preuve datée, pas dans la prose qui le recopie —
   est enfreinte par les deux premiers.
5. L'en-tête de `test_world_v2_iss073_boucle.gd` dit « voir la scène changer » ;
   le test vérifie la DEMANDE (`transition_started` + destination), pas le swap
   effectif. L'assertion elle-même est honnête.
6. `victory_screen.gd::_on_explore` ne pose aucun `pending_spawn` : après la
   victoire, « Continuer » ramenait au spawn, pas devant la porte. **Aucun
   document du dépôt ne prétendait le contraire** — c'est la formulation que
   j'avais relayée qui était fausse. Le « devant la porte » ne vaut que pour la
   sortie du vestibule. À noter : T1 change ce comportement sans l'avoir visé —
   la reprise se fait désormais à la dernière position sauvegardée.
7. `docs/V2_LONG_GAME_ROADMAP.md` étape 0 : « la build exportée reste à
   prouver » est périmé à `98cbaf0`. Staleness dans le sens conservateur.
8. `tools/fumee_gravite.py` : `sol = min(ys)` sur le lot de repos, là où
   l'outil frère a reçu la médiane. Sans conséquence pratique, mais c'est le
   piège que `tools/CLAUDE.md` nomme — chercher les AUTRES endroits qui font
   la même mesure.

## Ce que le relecteur n'a pas pu vérifier

Moteur verrouillé : rejouer les portails éditeur, `validate_fast.sh` sur
`c3f1819`, les portails d'export, et hacher les ~1,5 Go d'archives de la
release (seuls les digests publiés par l'API GitHub ont été comparés).
Et surtout : **personne n'a lancé les binaires produits par le runner
GitHub** — le binaire éprouvé localement venait d'un template recompilé ici.
Le README de la preuve le disait déjà.

## Verdict global du relecteur

« La candidate est honnête, et probablement jouable de bout en bout — mais
"probablement" est le mot exact, et le dépôt le dit lui-même. » Le mode de
panne maison — un test vert qui mesure une grandeur voisine — a été cherché
dans les tests décisifs et n'y a pas été trouvé ; les pièges restants sont
dans l'**appareil de mesure de lundi** (constats 2 et 3), pas dans le jeu.

Risques pour lundi, par ordre de probabilité selon le relecteur : les binaires
CI jamais lancés · l'intérieur du donjon jamais marché · une mort en V2 sans
checkpoint · le spawn dos à la vallée (ISS-076, déjà consigné et annoncé au
testeur) · la porte, un bloc de bronze de 3,2 m dont le protocole demande
déjà « ressemble-t-elle à une porte ? ».
