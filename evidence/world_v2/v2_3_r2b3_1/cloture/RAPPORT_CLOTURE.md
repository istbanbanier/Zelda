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
