# Les rouges et les contrôles négatifs, en journaux plutôt qu'en prose

Relevé par la contre-revue à contexte frais (constat 8) : plusieurs preuves
étaient **narrées** dans des messages de commit sans qu'aucun journal ne les
porte. Une affirmation sans journal est `NON VÉRIFIÉ` — c'est la règle du
dépôt, et elle vaut contre moi.

| Journal | Ce qu'il montre |
|---|---|
| `rouge085.log` / `rouge085b.log` | ISS-085 AVANT correctif : 180,0° avant le coup, 180,0° après, 0,00 m parcouru |
| `vert085b.log` | ISS-085 après : 5 cas, 29 assertions |
| `cn085.log` | contrôle négatif — bruit d'impact silencié : le cas B7 **seul** rougit, les quatre autres restent verts |
| `rouge075.log` | ISS-075 avant migration : 4 réussis / 11 échoués, dont les deux défauts de MA conception (`"0.5"` clé valide, champs `doc` réclamés) |
| `cn075.log` | contrôle négatif de la loi — un `notify` brut ajouté dans `reset_button.gd` : rouge, et lui seul |
| `filet085.log` | filet IA large : 194 réussis, 0 échoué |
| `filet_var.log` | filet de la variante visuelle : 39 réussis, 0 échoué |
| `rouge_b8b.log` | 2e passe ISS-085, trouvée PAR la contre-revue : le garde sort à **12,70 m** d'un territoire de 12,0 en allant voir un bruit |
| `vert_b8b.log` | après le clamp au point d'usage : **11,20 m**, 6 cas verts |

| `iss084_rouge.log` | ISS-084 avant implémentation : **1 réussi, 10 échoués**, chaque échec nommant son exigence |

J'avais d'abord écrit ici que ce dernier journal était perdu. Il ne l'était
pas — je ne l'avais pas cherché avant de l'affirmer. Corrigé, et laissé visible
plutôt que réécrit en silence : c'est la même faute, en petit, que celle que la
contre-revue a relevée en grand.
