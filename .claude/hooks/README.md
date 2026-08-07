# Hooks du projet

Éclats d'Orage applique sa barre de qualité **en couches**, chacune au point le moins
cher où elle est encore utile. C'est la leçon centrale rapportée de
`levy-street/world-of-claudecraft` (voir R-014 dans `docs/RESEARCH_LEDGER.md`) : un
invariant qui ne vit que dans un document se dégrade en silence, et un contrôle trop
lourd placé trop tôt finit contourné.

## Qui fait quoi, et quand

| Couche | Mécanisme | Quand | Coût | Bloque ? |
|---|---|---|---|---|
| Garde-fou instantané | hook `Stop` → `qa-stop.sh` | fin de chaque tour | millisecondes | oui, sur invariant dur |
| Plancher déterministe | `.githooks/pre-push` | à chaque `git push` | secondes | oui |
| Invariants d'état | `tests/unit/test_invariants.gd` | dans `validate_fast.sh` | secondes | oui |
| Suite complète | `tools/validate_fast.sh` | avant de déclarer un jalon fini | ~20 min | oui |
| Revue de jugement | `adversarial-qa` + compétence `gate-review` | avant tout `PASS` de gate | un agent | consultatif |

### Garde-fou instantané (`qa-stop.sh`)

Scanne les lignes **ajoutées** de l'arbre de travail et bloque sur quatre invariants
durs du `CLAUDE.md`, tous détectables sans lancer quoi que ce soit :

1. contenu Nintendo dans le code, les scènes ou les ressources ;
2. l'image de référence North Star employée comme asset ;
3. une édition à la main de `.godot/imported/` ;
4. une déclaration GDScript non typée (`var x = ...`).

Il ne lance jamais Godot ni `validate_fast.sh` : un hook `Stop` se déclenche à chaque
tour, et la suite met une vingtaine de minutes. Il ne peut pas non plus invoquer un
sous-agent — un hook est une commande shell.

**Ce qu'il ne contrôle pas, à dessein.** La règle « pas de `print()` sur le chemin
critique » n'y est pas : elle ne se distingue pas d'un journal de diagnostic
structuré (`scripts/core/boot.gd` en contient onze, légitimes). Un gate qui crie au
loup finit désactivé ; celui-ci ne se déclenche que sur du certain. Vérifié : zéro
faux positif sur huit formes GDScript typées légitimes (`:=`, `: Type =`,
`@export`, `@export_range`, `static var`, `Array[String]`, `const`, inférence).

### Plancher déterministe (`pre-push`)

Le push est la frontière où le code quitte la machine, et il arrive bien moins souvent
qu'un tour : c'est là que se placent les contrôles un peu plus lourds. Il rejoue le
scan d'invariants sur le **diff poussé**, puis lance `--check-only` sur chaque `.gd`
modifié si Godot est disponible. Godot absent, il le **dit** au lieu de laisser croire
que le parse a tourné.

Il ne lance délibérément pas `validate_fast.sh` en entier : imposer vingt minutes à
chaque push ferait systématiquement chercher `--no-verify`, c'est-à-dire supprimerait
le garde-fou. Cette suite reste la barre à franchir avant de déclarer un jalon terminé.

Base de comparaison : l'amont de la branche, sinon `origin/main`. S'il flagge des
lignes que vous n'avez pas écrites, réglez l'amont sur la base de la PR
(`git branch --set-upstream-to origin/<base>`) plutôt que d'attraper `--no-verify`.

### `ensure-hooks.sh`

Hook `SessionStart` : pointe `core.hooksPath` de ce clone vers `.githooks`, sans quoi
le plancher pre-push ne tournerait jamais. Idempotent, et il n'agit que si personne ne
possède déjà le chemin de hooks — il n'écrase donc aucune configuration existante.

## La couche de jugement n'est pas ici

Un hook ne raisonne pas. La couverture, la cohérence d'un gate, la conformité d'une
preuve dans `evidence/` relèvent de l'agent `adversarial-qa` et de la compétence
`gate-review`. Aucun de ces hooks ne dispense d'une revue contradictoire à contexte
frais avant un `PASS`.

## Confiance et sûreté

Ces scripts s'exécutent avec vos droits : traitez-les comme tout outillage versionné.
Ils sont volontairement petits et auditables — bash, `git`, `perl` — ne lisent que
`git diff` et `git status`, n'écrivent rien hors de `core.hooksPath` dans
`.git/config`, et ne font aucun appel réseau.

## Se désengager

- sauter le plancher pour un push : `git push --no-verify` (urgence réelle) ;
- désactiver les hooks git de ce clone : `git config --unset core.hooksPath` ;
- désactiver les hooks Claude Code : `"disableAllHooks": true` dans
  `.claude/settings.local.json` (non versionné).
