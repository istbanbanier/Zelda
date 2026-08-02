---
description: Règles de preuve et de validation — appliquer à docs/**, evidence/** et à toute déclaration d'achèvement
globs: ["docs/**", "evidence/**", "tests/**", "tools/**"]
---

# Preuve — interdiction de validation prématurée

Base : MASTER_SPEC §0.2 et §0.7. C'est la règle qui protège le projet de
l'auto-illusion ; elle prime sur la vitesse d'avancement.

## Matrice de preuve minimale

| Affirmation | Preuve exigée |
|---|---|
| « le code compile/parse » | commande exacte, code retour, zéro erreur pertinente |
| « la scène fonctionne » | lancement réel, scénario reproduit, log ou capture du build |
| « le gameplay est bon » | test contrôlé, métriques de réponse, essai humain documenté |
| « le rendu correspond » | captures reproductibles, comparaison North Star, score détaillé |
| « c'est performant » | profil CPU/GPU/mémoire, matériel, build, preset et durée indiqués |
| « le bug est corrigé » | un test qui échouait avant et réussit après, plus recherche de régression |
| « c'est final » | chemin critique sans placeholder, gates verts, revue indépendante |

## Règles

- Tout critère non testé est **`NON VÉRIFIÉ`**, jamais implicitement réussi.
- Ne jamais inventer une capture, une vidéo, un FPS ou un résultat de test.
- Une capture doit provenir du **renderer réel**, via `tools/godot/capture_reference.gd`,
  accompagnée de son manifeste JSON (commit, version, renderer, résolution, frames).
- Un script de validation qui saute une étape impossible doit **échouer ou signaler
  `BLOQUÉ`** (code 3), jamais retourner vert.
- Le verdict d'un gate est le **plus faible** de ses critères, pas leur moyenne.
- Une mesure obtenue en rendu logiciel (llvmpipe) n'est **jamais** un budget de frame.

## Vocabulaire imposé

`Implémenté` (raccordé) < `Fonctionnel` (testé en scène exécutable) <
`Validé` (conforme, sans régression connue) < `Final` (zéro placeholder critique).

Ne pas employer un mot du niveau supérieur sans la preuve correspondante.

## À chaque fin de session

Mettre à jour `docs/STATUS.md`, `docs/PROGRESS.md`, et `docs/KNOWN_ISSUES.md` si un
échec a été observé. Le handoff doit indiquer **exactement** la prochaine action —
pas une intention vague.

## Capture depuis un arbre COMMITTÉ (revue V4 lot 16)

Toute capture de preuve se fait APRÈS le commit du code qu'elle prouve —
jamais depuis un arbre sale : le manifeste doit porter `repo_dirty: false`
et le hash du commit livré. Le commit d'evidence suit immédiatement.
