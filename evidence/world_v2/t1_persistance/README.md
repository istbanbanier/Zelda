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

## `vert2.log` — après implémentation

    === RÉSULTAT: 7 réussi(s), 0 échoué(s) ===
    erreurs de script dans le journal : 0

115 assertions. Les trois filets C4, C5 et C6 sont restés verts : le correctif
n'est pas l'implémentation naïve qu'ils attrapaient.

## `sabotage_c7.log` — le contrôle négatif de C7

C7 est né APRÈS l'implémentation, désigné par la contre-revue à contexte frais
(§6). En retirant ses deux gardes de `world_v2_root.gd` :

    === RÉSULTAT: 6 réussi(s), 1 échoué(s) ===

**Une seule** assertion rougit — celle du mort. La seconde moitié de C7
(« Réessayer » reprend au dernier état sauvegardé) reste VERTE sans la
constante `RETRY_TAG`, parce que le placement correct vient de C1. Ce que
`RETRY_TAG` corrige est donc un avertissement FAUX (« tag d'apparition
inconnu ») émis à chaque mort, pas un défaut de placement. Le contrôle négatif
a PRÉCISÉ le constat de la contre-revue au lieu de le répéter.

## `validate_fast_ca1ffed.log` — la chaîne complète, sur l'arbre committé

    Gel V2.3-B : 44 élément(s) gelé(s) intacts au sha256
    454 script(s) GDScript parsés sans erreur
    === RÉSULTAT: 984 réussi(s), 0 échoué(s) ===
    plancher de couverture 586 respecté
    autotests des harnais : verdict.py, analyse_journal_devmode.py,
                            fumee_build_exportee.py — verts
    === VALIDATE_FAST : VERT ===   (RC=0)

## `autotest_analyseur.log` — l'appareil de mesure de lundi

Trois cas neufs, écrits ROUGES d'abord (3 échecs constatés avant correctif) :
un repos refait, deux repos refaits, un marqueur surnuméraire en queue. Ils
ferment le constat 2 de la contre-revue — au-delà de neuf marqueurs, l'outil
prenait silencieusement les neuf PREMIERS, et un repos refait décalait toutes
les paires : l'appareil rendait `FAIL` sur une faute de protocole.

Piège rencontré en écrivant ces cas, et consigné dans le code : `mq()`
numérote dans l'ordre d'APPEL et `sequence()` remet le compteur à zéro, alors
que `marqueurs()` trie par `numero`. Mes deux premiers cas passaient donc au
vert AVANT le correctif — ils simulaient en réalité un marqueur de queue. La
fonction `renumerote()` remet les numéros dans l'ordre de la liste.

Aucun seuil n'a été déplacé.

## Ce que ces journaux ne prouvent PAS

Rien sur une build exportée, rien sur une manette, rien sur un écran. Ce sont
des mesures d'éditeur, en rendu logiciel, dans un conteneur sans GPU. Elles
prouvent l'existence du défaut et la solidité des filets — pas que la reprise
plaira à un joueur.
