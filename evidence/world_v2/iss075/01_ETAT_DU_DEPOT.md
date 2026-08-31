# À LIRE AVANT DE COMMITER — comment savoir si l'arbre est propre

> **ÉTAT AU MOMENT DE LA REMISE : la chaîne est allée au bout.** Les six
> sabotages ont été posés puis retirés, le vert final est journalisé
> (56 réussis, 0 échoué), et les cinq contrôles ci-dessous rendent tous zéro.
> Le reste de cette page est la procédure à rejouer si un doute subsiste, ou si
> une session future refait une passe de sabotage.

La preuve par sabotage (`10_SABOTAGES.md`) modifie **temporairement** trois
fichiers, puis les restaure. Elle attend le verrou `heavy_tools.lock`, partagé
par tout le dépôt : si une autre voie tient le verrou, le sabotage reste posé
tant que le tour n'est pas venu.

## Le test, en une commande

```bash
cd /home/user/wt-B
grep -c "Retrait intégral" evidence/world_v2/iss075/10_SABOTAGES.md
```

- **`1`** — la chaîne est allée au bout, l'arbre est propre, le vert final est
  journalisé dans le même fichier. Rien à faire.
- **`0`** — la chaîne n'a pas fini. **Ne pas commiter avant le contrôle
  ci-dessous.**

## Si la chaîne n'a pas fini

Un seul sabotage peut être posé à la fois, et chacun est d'une à quatre lignes.
Les trois formes possibles, et leur signature dans `git diff` :

| Sabotage | Fichier | Signature à chercher |
|---|---|---|
| S1 | `scripts/localisation/textes.gd` | un `_charge = true` AVANT l'appel à `_charger_depuis` dans `_charger()` |
| S2 | `scripts/localisation/textes.gd` | `_tables.get(demandee, {})` de retour dans `brut()` |
| S3 | `scripts/ui/gameplay_shell.gd` | `_buff_label.text = ""` au lieu de `_set_label(_buff_label, "")` |
| S4 | `scripts/ui/gameplay_shell.gd` | un `Textes.t(` dans `_resonance_state_line` |
| S5 | `resources/localisation/fr.json` | `"boss.phase.dead": "Silence "` — avec une espace finale |
| S6 | `scripts/ui/gameplay_shell.gd` | `_on_notification("Cuisiné : %s" …)` écrit en dur |

Contrôle direct :

```bash
git diff -- scripts/localisation/textes.gd | grep -n '^+.*_charge = true'
git diff -- scripts/localisation/textes.gd | grep -n '^+.*get(demandee, {})'
git diff -- scripts/ui/gameplay_shell.gd   | grep -n '^+.*_buff_label\.text ='
git diff -- resources/localisation/fr.json | grep -n '^+.*"Silence "'
git diff -- scripts/ui/gameplay_shell.gd   | grep -n '^+.*"Cuisiné : %s"'
```

**Chacune de ces cinq commandes doit ne rien rendre.** Si l'une rend une ligne,
un sabotage est resté posé : les copies d'avant sabotage sont dans
`/tmp/wb/T.bak`, `/tmp/wb/S.bak` et `/tmp/wb/F.bak`, et la restauration est un
`cp`. Si `/tmp` a disparu, l'état correct se reconstruit par la description
ci-dessus — aucun sabotage ne dépasse quatre lignes.

## Ce qui reste vrai même si la chaîne n'a pas fini

La preuve par sabotage est une preuve de **rougeur** — que les contrats
attrapent bien ce qu'ils annoncent. Le **vert**, lui, a été constaté avant :
10 contrats et 44 pins préexistants, journalisés au §5 de `20_JOURNAL.md`.
`B10` a en outre sa preuve de rougeur hors moteur, reproductible par
`python3 evidence/world_v2/iss075/preuve_b10.py`.

Ce qui manquerait alors, et qu'il faut déclarer `NON VÉRIFIÉ` plutôt que
supposer : la rougeur de S1 à S5 dans le moteur, le fichier
`tests/unit/test_textes_iss075.gd.uid` (les 22 autres tests unitaires en ont un
committé), et le vert des trois derniers changements — `B9`, `B10` à candidates
dérivées, et le correctif `cuisine.plat_cuisine` du §8.
