# R2B.3.1 — rapport de clôture

Base d'entrée `a27e559`. Le lead a rendu **PASS visuel et technique** sur R2B.3
et tranché sur ISS-059 : le résidu de ressources du PROJET est corrigé ; le
résidu de scripts du MOTEUR est un domaine séparé, suivi et non bloquant.

## 1. Ce que cette passe a construit

| | |
|---|---|
| `PROJECT_RESOURCE_LEAK_GATE` | bloquant, deux modes, liste blanche |
| `ENGINE_SCRIPT_CACHE_TELEMETRY` | WARN, **redevient bloquante** (code 2) à la moindre dérive |
| contrôle négatif du portail | 12 fixtures, 12 verdicts, à chaque `validate_fast` |
| gel V2.3-B exécutable | 43 fichiers au sha256, cycle rouge d'abord tenu |
| `tools/gate_fuite_composition.sh` | énumération complète, câblée dans `validate_release` §4b |

## 2. Ce que la revue contradictoire a trouvé, et que j'ai corrigé

Elle a rendu **FAIL**. Elle avait raison sur les huit points. Les deux
bloquants, parce qu'ils touchaient la vérité de ce qui est écrit :

1. **Mon commentaire mentait à l'endroit exact où le seuil baisse.** Il
   affirmait « strictement plus sévère » ; l'étape lance le mode agrégat, qui
   ACCEPTE une enveloppe au lieu de rougir dessus — donc plus permissif. Le
   relecteur a exécuté le contre-exemple. Réécrit pour dire ce que le code fait,
   avec le mot « permissivité assumée ».
2. **`--entériner` gravait un rouge dans la ligne de base.** Démontré sur la
   fixture 02 : le contrat produit contenait `StandardMaterial3D: 1`, et la
   passe suivante repassait au vert. Il refuse désormais d'écrire tant que le
   portail A rougit.

Les six autres, et ce qu'ils auraient coûté :

| # | défaut | ce qu'il aurait coûté |
|---|---|---|
| 3 | le cœur du portail survivait à sa suppression | un portail cassé rendant un vert silencieux |
| 4 | le gel interdisait au lot 1 d'AJOUTER un fichier | le chantier bloqué dès le premier lieu |
| 5 | l'étape 2c pouvait rendre vert en ne montant rien | un vert obtenu sans travail |
| 6 | une exception Python devenait « une ressource du projet survit » | chercher un défaut dans le jeu pour un fichier corrompu |
| 7 | une collision de clés perdait un compte de RID | 3 + 999 rendait 999 |
| 8 | le code 2 était mort, ISS-065 décrivait une intention | un invariant qui ne vit que dans un document |

## 3. La fausse piste, et pourquoi elle est instructive

Une suite lancée à la main rendait **253 288 `SCRIPT ERROR`**, sur exactement
les onze classes auxquelles la passe précédente avait ajouté `_static_init()`.
La corrélation avec le dernier commit était parfaite — et fausse.

Cause réelle, vérifiée : le conteneur recréé est reparti de `c44f430` et son
`.godot/global_script_class_cache.cfg` était bâti pour ce commit. Or
`StaticResourceCaches` est née à `139cda5`. Sans `--import` préalable, la classe
est inconnue, et chaque `_static_init()` qui la référence casse son script
appelant. Un `--import` a tout remis en place.

Ce n'est **pas une régression de code**. C'est consigné dans `tools/CLAUDE.md`,
là où on le rencontrera, avec la ligne qui compte : *« ce qui rend le piège
coûteux, c'est qu'il ressemble à une régression ».*

## 4. Ce qui reste `NON VÉRIFIÉ`

- la **composition** du résidu n'est pas revérifiée dans cette passe : le mode
  qui l'énumère coûte le triple d'une suite et vit désormais en niveau release.
  L'enveloppe committée vient de la mesure du 2026-08-20 ;
- le **verdict artistique** des six nouveaux lieux n'existe pas encore — le lot
  1 n'est pas construit à l'heure de ce rapport ;
- les **seuils** ne sont pas dans le gel : la garde qui reste est humaine, et
  c'est écrit dans `tools/gel_verifier.sh` plutôt que passé sous silence.

## 5. Verdict de la validation finale (exécution du 2026-08-21, 3 805 s)

| critère | résultat |
|---|---|
| tests unitaires | **949 réussis, 0 échoué** |
| gel V2.3-B (43 fichiers) | VERT |
| parse des 429 scripts | VERT |
| contrôle négatif du portail (12 fixtures) | 12/12 |
| **PROJECT_RESOURCE_LEAK_GATE** | **VERT** — signature agrégée conforme au contrat |
| **ENGINE_SCRIPT_CACHE_TELEMETRY** | **WARN — RÉSIDU MOTEUR CONNU ET STABLE**, dans son enveloppe |
| sonde de cycles | empreintes IDENTIQUES aux deux cycles (2876/862/23/0) |
| boot → menu, continuité des 6 personnages, plancher 949/586 | VERT |
| **RC du script** | **1 (ROUGE)** — et voici pourquoi ce rouge ne contredit pas ce qui précède |

Le RC=1 venait de DEUX MÉPRISES DU JUGE, pas d'un défaut du projet :

1. le filtre générique `^ERROR:` de l'étape 2 attrapait les lignes de fin de
   processus du moteur — celles-là mêmes que l'étape 2b juge au chiffre près
   contre le contrat, et rendait VERTES dans la même exécution. Le même fait,
   deux juges, deux verdicts.
2. la garde d'erreurs de l'étape 2c comptait ces mêmes lignes dans le journal
   de la sonde, qui les émettra toujours : l'étape ne POUVAIT pas être verte,
   alors que les empreintes des deux cycles étaient identiques à l'unité.

Les deux juges sont corrigés (chaque fait n'a plus qu'UN juge ; rien n'est
masqué, les lignes restent aux journaux) et le correctif est prouvé de deux
façons : rejugement des MÊMES journaux (4→0 et 3→0 correspondances), et
contre-épreuve montrant qu'une vraie `SCRIPT ERROR` rougit toujours. Une
exécution complète sur le commit de clôture est relancée pour laisser un
enregistrement RC=0 propre — aucune cueillette avant son verdict.
