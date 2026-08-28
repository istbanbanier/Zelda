# T1 — preuves des contrats rouges de la persistance World V2

Date : 2026-08-28 · branche `claude/world-v2-t1-persistance` · base `a8d2f77`
(la candidate de lundi, ISS-073). Contrat : `docs/contrats/t1_persistance_world_v2.md`.
Fichier de contrats : `tests/world_v2/test_world_v2_t1_persistance.gd`.

Commande, identique pour les deux journaux :

    tools/lancer_godot.sh --path . --script tools/godot/test_runner.gd -- --filter=t1_persistance

## `rouge3.log` — l'état du produit, sans rien toucher

    === RÉSULTAT: 3 réussi(s), 7 échoué(s) ===
    erreurs de script dans le journal : 0

| Cas | Verdict |
|---|---|
| C1 position | ROUGE, 3 échecs |
| C2 orientation | ROUGE, 2 échecs |
| C3 scène de reprise | ROUGE, 2 échecs |
| C4 position V1 jamais réappliquée | vert, 7 assertions |
| C5 sauvegarde corrompue | vert, 22 assertions |
| C6 identifiants stables | vert, 40 assertions |

## `sabotage_aveugle.log` — le contrôle négatif

Sabotage temporaire posé dans `scripts/world_v2/world_v2_root.gd` : relire
`player_position` de `slot0` et l'appliquer **sans regarder `world_version`**
— l'implémentation naïve que T1 pourrait produire.

    === RÉSULTAT: 1 réussi(s), 8 échoué(s) ===

C1 passe de 3 échecs à 1 : sa moitié lecture VERDIT, donc le cas est
satisfiable et mesure bien la position rendue. En échange, C4 rougit et C5
rougit sur exactement les deux formes dont les composantes sont des `float`
(hors bornes, sous le filet de chute) — les deux autres restent vertes parce
que leurs types sont faux. L'étau fonctionne.

Le sabotage a été retiré et l'identité du fichier vérifiée au sha256 :

    scripts/world_v2/world_v2_root.gd: OK

## Ce que ces journaux ne prouvent PAS

Rien sur une build exportée, rien sur une manette, rien sur un écran. Ce sont
des mesures d'éditeur, en rendu logiciel, dans un conteneur sans GPU. Elles
prouvent l'existence du défaut et la solidité des filets — pas que la reprise
plaira à un joueur.
