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

## 3. Revue contradictoire à contexte frais

Lancer le sous-agent `adversarial-qa` avec : la liste des critères, le diff et les
chemins de preuves. Il doit **rejouer** les commandes et tenter de démontrer l'échec,
pas relire le résumé.

Traiter chaque `FAIL` qu'il remonte : corriger, ou consigner dans
`docs/KNOWN_ISSUES.md` avec sévérité et propriétaire.

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
