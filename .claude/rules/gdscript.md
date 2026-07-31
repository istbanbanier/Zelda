---
description: Règles GDScript — appliquer à toute modification de scripts/**/*.gd, tools/godot/**/*.gd et tests/**/*.gd
globs: ["scripts/**/*.gd", "tools/godot/**/*.gd", "tests/**/*.gd"]
---

# GDScript — règles obligatoires

Base : MASTER_SPEC §5.4. Ces règles sont non négociables ; une exception se justifie
dans `docs/DECISIONS.md`, jamais en silence.

## Typage

- **Typage explicite partout** : paramètres, retours, variables locales, éléments de
  tableaux (`Array[String]`, pas `Array`).
- `class_name` pour tout type réutilisable ; les scripts d'usage unique s'en passent.
- Signaux **typés** : `signal damaged(amount: float, direction: Vector3)`.
- Les avertissements `untyped_declaration`, `unsafe_property_access`,
  `unsafe_method_access` et `unsafe_cast` sont actifs dans `project.godot` :
  ne pas les désactiver pour faire taire un problème réel.

## Structure

- **Composition plutôt qu'héritage profond.** Un comportement réutilisable est un
  composant (`HealthComponent`, `StaminaComponent`, …), pas une classe de base
  supplémentaire.
- Aucune dépendance circulaire entre scripts.
- Préférer `@onready`, `NodePath` exporté, groupes et injection aux chaînes
  `get_node("../../Machin")` fragiles.
- L'équilibrage vit dans des `Resource` sous `resources/tuning/`, **jamais** dans
  une scène de niveau.
- Définitions en `Resource` **immuables** ; l'état mutable est séparé. Deux
  exemplaires d'une arme ne partagent jamais leur durabilité — une durabilité
  stockée dans une ressource partagée est un bug de conception, pas un raccourci.

## Durée de vie et signaux

- Protéger les `await` contre la suppression du nœud :
  `if not is_instance_valid(self): return` après l'attente.
- Déconnecter les signaux connectés dynamiquement quand la source ou la cible meurt.
- Ne jamais conserver une référence brute vers un nœud susceptible d'être libéré
  sans `is_instance_valid()` au point d'usage.

## Performance

- Aucune boucle sur le monde entier par frame.
- Aucune allocation massive par frame (tableaux, dictionnaires, chaînes formatées
  dans `_process`).
- Pas de `_process` sur des nœuds dormants : désactiver via
  `set_process(false)` / `set_physics_process(false)`.
- Timers et signaux plutôt que polling.
- Toute la logique de mouvement dans `_physics_process()` ; ne jamais écrire des
  transforms de gameplay concurrents depuis `_process()` (§20.9).

## Interdits

- Halluciner une méthode, une propriété ou une capacité de Godot. En cas de doute :
  vérifier dans la source du tag `4.7.1-stable` ou écrire un test — jamais supposer.
- Utiliser silencieusement la documentation d'une autre version.
- Laisser une erreur de parsing ou une référence cassée : c'est **bloquant**.
- `print()` de debug laissé sur le chemin critique d'un build final.
