# Reprise Codex — le bundle n'a jamais atteint ce conteneur

**Directive** : intégrer `Zelda-Lot1R-Codex-handoff.bundle` (sha256
`03632748b950de3c36076104b9cfd63d59ded8c216b78b2adc1edaa8cbad4c4f`), trois
commits de Codex : `c29a6c54` (quatre lieux reconstruits), `c23df0ce` (preuves
`codex_final/`), `1adeb207` (nettoyage des sauvegardes de tests).

## Constat, établi par recherche exhaustive et non par un seul `ls`

Le conteneur a été **recréé** (sixième fois du projet) : le HEAD local datait
de trois jours (`031f0ad`) et a été avancé proprement vers le distant
`19f70f7` — exactement le SHA vérifié par Codex, donc **rien du travail
poussé n'est perdu**.

Mais la pièce jointe est morte avec l'ancien conteneur :

| Vérification | Résultat |
|---|---|
| `find / -xdev -iname '*.bundle'` (tout le disque) | **aucun** fichier |
| `/mnt/attach/`, `/mnt/user-data/working/` (points de dépôt des pièces jointes) | **vides** |
| `git cat-file -e` sur les trois SHA | **absents** tous les trois |
| `git ls-remote origin` (toutes les refs, y compris `codex/*` et `refs/pull/*`) | aucune ref ne les porte |

Codex ne pouvait pas pousser (pas d'authentification GitHub) ; le bundle était
le seul canal, et ce canal ne survit pas à une recréation de conteneur.

## Ce qui a été fait EN ATTENDANT, pour que l'intégration soit immédiate

Tout ce qui ne dépend pas du bundle a été exécuté et prouvé :

1. **Godot 4.7.1-stable** présent en binaire direct (`/usr/local/bin/godot`
   → build réel, aucun wrapper qui décompresserait un ZIP à chaque appel).
2. **Blender 4.0.2 + NumPy 1.26.4** présents ; les **six contrôles de
   continuité réellement exécutés** (pas un `--version`) : colosse, chasseur,
   gardien, raider rouge/bleu/noir — **six « UN SEUL corps solidaire »**,
   RC=0. Journal : `continuity_6modeles_19f70f7.log`.
3. **Le diagnostic des sauvegardes fantômes est reproduit de notre côté** :
   worktree détaché `git worktree add --detach` sous `/tmp`, import RC=0,
   puis `--filter=room2_vertical,room4_battery,dungeon_run` →
   **26 réussis, 0 échoué, RC=0**. Journal :
   `saves_isolees_26sur26_19f70f7.log`. La cause des huit rouges historiques
   était bien l'environnement synchronisé (restaurations `.rsync-tmp` sous
   `.godot_user/.../saves`), pas le jeu — conformément au constat de Codex.

## Ce qui N'A PAS été fait, et pourquoi

- **Filets 16/16 et sabotages D1–D8** : ils doivent tourner sur l'arbre
  INTÉGRÉ. Les jouer sur `19f70f7` validerait l'état d'avant la corrective de
  Codex — un vert du mauvais arbre.
- **La validation complète** : même raison. Une passe verte sur `19f70f7`
  existe déjà (`validation/validate_fast_VERT_3fd004c.log`, 961/0) ; la
  refaire sans les trois commits ne prouverait rien de neuf.
- **Toute reconstruction des lieux « de mémoire »** : interdite. Les commits
  de Codex contiennent un travail réel (minéral du belvédère, eau turquoise,
  shader `SH_TurquoiseSpringWater.gdshader`) que ce conteneur n'a pas.

## Procédure de reprise EXACTE quand le bundle sera de nouveau accessible

```bash
sha256sum <bundle>                      # doit être 03632748b950…
git bundle verify <bundle>
git fetch <bundle> HEAD:refs/heads/codex-lot1r-handoff
git cat-file -e c29a6c549adc199887c5c2b0f39bd75b26cc6315
git cat-file -e c23df0ceece52c4ea9b01ecc73a380722858e9a0
git cat-file -e 1adeb2079ceeecfe5b0d1b29bf9a08ba19b8488e
git cherry-pick c29a6c54… && git cherry-pick c23df0ce… && git cherry-pick 1adeb207…
# push IMMÉDIAT du checkpoint, puis filets 16/16, D1–D8 8/8, 26/26,
# continuité 6/6, et UNE validate_fast depuis un worktree /tmp
# (git worktree prune d'abord si le conteneur a encore été recréé).
```

Deux canaux alternatifs qui éviteraient le problème du canal périssable :
faire pousser Codex sur **une branche neuve** (`codex/lot1r-handoff`) une fois
l'authentification rétablie, ou joindre le bundle **dans le même message** que
la directive de reprise adressée à une session au conteneur vivant.
