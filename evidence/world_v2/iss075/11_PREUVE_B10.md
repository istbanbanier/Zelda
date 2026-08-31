# B10 — preuve que le contrat attrape le défaut qui l'a fait naître

`B10` (`test_le_francais_restant_est_confine_au_chemin_par_frame`) est né d'un
défaut réel de ma propre migration, décrit au §8 du journal : une ligne portant
DEUX littéraux joueur, une carte indexée par numéro de ligne, et le second
littéral qui écrase le premier.

Le sabotage `S6` (voir `10_SABOTAGES.md`) remet ce défaut et fait rougir `B10`
dans le moteur. La simulation ci-dessous prouve la **règle** hors moteur, et
sert de repli si l'exécution GDScript n'a pas pu être rejouée.

## La règle, appliquée à la version buguée

```bash
python3 evidence/world_v2/iss075/preuve_b10.py
```

Sortie attendue :

```
B10 sur la version CORRIGÉE — français hors chemin par frame : 0
B10 sur la version BUGUÉE   — français hors chemin par frame : 1
   ROUGE  cooking_confirm      'Cuisiné : %s'
```

Le point qui compte : sur la version corrigée il reste **neuf** littéraux
français dans le fichier, et les neuf sont dans `RESONANCE_ACTIONS`,
`_resonance_action_line` ou `_resonance_state_line` — c'est-à-dire exactement le
chemin par frame, celui où `B4` **interdit** de traduire. Le contrat n'est donc
pas une liste d'exceptions gelée : il dérive l'autorisation de l'interdiction.

## Limite de cette preuve

C'est une simulation **Python** de la règle, pas une exécution du GDScript. Elle
prouve que la règle discrimine ; elle ne prouve pas que ma transcription en
GDScript est fidèle. C'est `S6` qui le prouve, dans le moteur, et le vert final
qui prouve l'absence de faux positif.
