---
name: gate-review
description: Procédure de passage d'un gate — rassembler les preuves, lancer la revue contradictoire, rendre un verdict par critère et mettre à jour la continuité. Utiliser quand un jalon semble terminé et avant toute déclaration PASS.
---

# Revue de gate

Procédure répétable. Ne jamais déclarer un gate `PASS` sans l'avoir suivie.

## 1. Rassembler les preuves

```bash
tools/env_report.sh evidence/<gate>/env_report.txt
tools/validate_fast.sh 2>&1 | tee evidence/<gate>/validate_fast.log
tools/validate_release.sh 2>&1 | tee evidence/<gate>/validate_release.log   # peut sortir en code 3
```

Copier dans `evidence/<gate>/` uniquement ce qui prouve quelque chose : logs avec
code retour, captures **avec leur manifeste JSON**, mesures avec leur protocole.
Noter le commit exact auquel les preuves correspondent.

## 2. Confronter les critères un par un

Ouvrir `docs/ROADMAP.md` à la section du gate. Pour **chaque** critère, écrire :

| Critère | Preuve (chemin + commande) | Verdict |
|---|---|---|

Verdicts autorisés : `PASS` · `FAIL` · `BLOQUÉ` · `NON VÉRIFIÉ`.
Un critère sans preuve est `NON VÉRIFIÉ` — jamais `PASS`.

## 3. Convoquer les spécialistes

Tu es le répartiteur. Tu ne fais pas les audits toi-même : tu regardes le diff et
tu **désignes** qui doit passer. Adapte la profondeur à la taille du changement —
un diff de documentation seule mérite une ligne de verdict, pas la matrice
entière.

```bash
git diff --name-only <base>..HEAD
```

| Si le diff touche… | Convoquer |
|---|---|
| mouvement, physique, IA, boss, timers, `randf` | `determinism-reviewer` |
| `_process`, végétation, VFX, graphe électrique, navigation | `frame-budget-reviewer` |
| sauvegarde, état persistant, `persistent_id`, schéma | `save-safety-reviewer` |
| UI, shader, VFX, animation, télégraphe | `presentation-seam-reviewer` |
| preset graphique, InputMap, affordance, glyphe | `parity-reviewer` |
| un fichier sous `tests/`, ou « couvert par un test » | `test-coverage-auditor` |
| un commit décrit comme refactor / déplacement / renommage | `move-not-rewrite` |
| un binaire sous `assets/`, `materials/`, `source_assets/` | `asset-license-auditor` |
| avant **toute** publication d'archive | `release-hygiene-reviewer` **et** `asset-license-auditor` |
| API ou réglage Godot incertain | `godot-researcher` |
| le ressenti, la lisibilité, le plaisir | `blackbox-player` |

Deux règles de convocation :

- **Contexte frais, jamais l'implémenteur.** Un agent qui a écrit le code ne peut
  pas l'auditer : il défendra ses choix au lieu de les éprouver.
- **Chaque spécialiste sort tôt** s'il n'est pas concerné. Ne t'excuse pas d'en
  convoquer plusieurs — celui qui n'a rien à voir répond en une ligne.

## 3 bis. Revue contradictoire à contexte frais

Après les spécialistes, lancer `adversarial-qa` avec : la liste des critères, le
diff et les chemins de preuves. Il doit **rejouer** les commandes et tenter de
démontrer l'échec, pas relire le résumé.

Traiter chaque `FAIL` qu'il remonte : corriger, ou consigner dans
`docs/KNOWN_ISSUES.md` avec sévérité et propriétaire.

## 3 ter. Passe adverse « qu'est-ce qui manque »

Le dernier geste, et le plus rentable. Après tous les rapports, se demander une
fois, explicitement :

- quel critère du gate n'a été examiné par **personne** ?
- quelle branche de code n'est traversée par aucun test ?
- quelle affirmation repose sur un log recopié plutôt que rejoué ?
- quel spécialiste aurait dû être convoqué et ne l'a pas été ?

Écrire la réponse même quand elle est « rien ». Un trou nommé vaut mieux qu'un
trou invisible.

### Relevé de convocation

Clore la section par la liste **entière** du tableau ci-dessus, chaque ligne
marquée `convoqué` · `hors périmètre` · `non convoqué`. Un spécialiste oublié
doit se voir dans le relevé, pas se deviner par son absence.

## 4. Verdict global

Le verdict du gate est le **plus faible** de ses critères, jamais leur moyenne.
Une capture magnifique à 12 FPS ne passe pas ; un jeu fluide mais visuellement
provisoire non plus.

## 5. Transmettre

- `docs/STATUS.md` : état par fonctionnalité, avec preuve et date du dernier test.
- `docs/TEST_REPORT.md` : date, build, commit, commandes, résultats, échecs restants.
- `docs/PROGRESS.md` : entrée datée + **handoff indiquant exactement la prochaine action**.
- `docs/DECISIONS.md` : toute décision prise pendant le jalon, avec l'alternative rejetée.
- Commit petit et cohérent, laissant le dépôt propre et relisable.

## Pièges à refuser

- Assouplir un seuil pour faire passer un test, sans décision documentée.
- Remplacer silencieusement une image de référence pour « réparer » un test visuel.
- Déclarer `PASS` un critère dont la preuve date d'un commit antérieur.
- Passer au gate suivant avec une erreur bloquante ouverte.
