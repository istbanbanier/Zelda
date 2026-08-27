# Contrôle négatif du portail — le sabotage du faux vert

Date : 2026-08-27. Un portail qui ne peut pas rougir n'est pas un portail.
On rouvre donc le défaut EXACT que la passe corrige, et on vérifie que la
chaîne entière le voit.

## Le sabotage

Dans `tools/lib/verdict.py`, on retire `PARTIAL` de la branche non nulle :

```diff
-    if "FAIL" in verdicts or "PARTIAL" in verdicts:
+    if "FAIL" in verdicts:
         return 1
```

C'est mot pour mot le défaut qui a produit le « 17/17 ».

## Avant sabotage
```
  [OK]   verdict.py — autotest vert
  [OK]   analyse_journal_devmode.py — autotest vert
  [OK]   fumee_build_exportee.py — autotest vert
  FAIL=0
```

## Pendant le sabotage — les TROIS rougissent
```
  [ÉCHEC] verdict.py — autotest ROUGE (code 1)
  [ÉCHEC] analyse_journal_devmode.py — autotest ROUGE (code 1)
  [ÉCHEC] fumee_build_exportee ROUGE (1)
  FAIL=1
```

Le sabotage se propage aux trois outils parce quils partagent désormais
la même source de jugement. Cest précisément ce quon voulait obtenir en
l'extrayant : une seule chose à corriger, une seule chose à saboter.

## Après restauration

sha256 identique au fichier d'origine :
```
5866f77b1de8ae1e12e6ffceab400c67f17bd9d4b287b40a0fdcf27fce08aead  tools/lib/verdict.py
```

Le sabotage na donc laissé aucune trace dans le dépôt — condition
nécessaire pour quun contrôle négatif soit honnête.
