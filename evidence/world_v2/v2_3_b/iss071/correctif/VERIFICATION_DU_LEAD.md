# Ce que le lead a vérifié lui-même sur la voie B, sans la croire sur parole

## 1. Le rouge et le vert, rejoués

| | commit | code | résultat |
|---|---|---:|---|
| avant correctif | `69502e7` (test seul) | **1** | `0 réussi(s), 6 échoué(s)` |
| après correctif | `3ef33d6` | **0** | `6 réussi(s), 0 échoué(s)` |

Gel des six lieux revérifié après manipulation : **46/46**.

## 2. Le test rougit-il aussi sur un correctif FAUX ?

Le rouge d'origine dit surtout « la fonction est absente ». Cela ne prouve pas
que les assertions attraperaient un correctif présent mais faux — c'est la
question du `test-coverage-auditor`, et elle se tranche par mutation.

Deux correctifs plausibles et faux, joués puis restaurés à l'octet près :

| mutation | ce qu'elle change | résultat |
|---|---|---|
| **M1** | vérifie l'extension **avant** de retirer `.import` — le correctif « évident » : les entrées `.gltf.import` redeviennent invisibles, l'index d'une build resterait vide | **ROUGE** — 2 réussis, 9 échoués, **18 assertions en échec** |
| **M2** | retire `.import` **sans revérifier** l'extension — `Foo.bin.import` et `Foo.tres.import` entrent dans un index de `PackedScene` | **ROUGE** — 2 réussis, 11 échoués, **22 assertions en échec** |

Restauration prouvée par sha256 dans les deux cas :
`0de4c97ad8b2bb333f31aa07d3231a7ba84428b478959adf651ec63103d7ff52`, identique à
l'état sain, et arbre de travail vide de toute modification résiduelle.

**Conclusion** : le test n'est pas un test qui ne peut pas échouer. Il épingle
l'ORDRE des deux opérations, qui est tout le contrat.

## 3. Ce qui reste NON VÉRIFIÉ à ce stade

Tout ceci est mesuré en **exécution éditeur**. Le défaut d'ISS-071 n'existe que
dans un PCK : ce test épingle la règle, pas le défaut. La preuve de la parité
réelle build/éditeur appartient au portail d'export, et n'est pas encore rendue.
