# Contrôle négatif n° 9, DE BOUT EN BOUT — le portail se refuse

**HISTORIQUE.** Mesuré le 2026-08-26 sur `cb8c5d7`. Journal :
`controle9_bout_en_bout.log`.

## Ce que ce contrôle éprouve

Photographier une build **pendant** son écran de chargement rend six images
identiques et fait rougir « caméra » et « déplacement » pour une raison qui
n'est pas la leur. Un portail qui conclut sur une telle image ment sans qu'on
puisse le voir. Il doit donc **se refuser**, pas conclure.

Le contrôle intégré au banc (`gate_export_parite_controle_negatif.sh`) éprouve
la *décision* — l'expression `awk` du portail, rejouée sur deux images. C'est
utile, ce n'est pas suffisant : il ne prouve pas que la branche de refus est
réellement atteinte, ni qu'elle sort bien en 3.

## Le sabotage joué ici

Le seuil de luminance a été porté à **0,99**, valeur qu'aucune image réelle du
jeu n'atteint. La condition « l'écran de chargement a disparu » devient donc
impossible à satisfaire — c'est exactement l'état où le portail doit refuser.
La build lancée est le **même binaire**, au sha256 près, que celui de la preuve
rouge.

```
sha256 du binaire : 13de524f6ade6137f02e26a667a8014f06f5c957e3466a9222a675a45c41881d
SHA git enregistré = SHA courant = cb8c5d71a5188a18df49d0e48f37ed453a4b0c89
seuil de luminance : 0.99 (défaut 0.02)
```

## Résultat

```
### 7. attente du jalon de montage, PUIS de l'effacement du chargement
    jalon atteint : [world_v2] fondation V2 vérifiée — vallée whitebox prête.
    luminance moyenne mesurée : 0.519749 (seuil 0.99 ; chargement 0.0027)
BLOQUÉ: l'écran de chargement n'a jamais disparu (luminance 0.519749).
        Le portail REFUSE de conclure sur cette exécution.

=== VERDICT PORTAIL EXPORT ISS-071 : code 3
RC=3
```

Le portail sort en **3 (BLOQUÉ)**. Il ne rend ni 0 (« tout va bien »), ni 1
(« la parité échoue ») : il dit qu'il n'a pas pu mesurer. C'est le seul verdict
honnête, et c'est celui qu'exige `.claude/rules/evidence.md`.

Noter au passage que le jalon de montage **était** atteint et que le manifeste
export **aurait pu** être lu : le portail refuse quand même, parce que la
condition d'observation n'est pas remplie. Un portail qui se contenterait du
jalon aurait conclu.

## Ce que ce contrôle NE prouve pas

Le seuil a été surchargé, pas l'image. Un vrai écran de chargement n'a pas été
photographié par cette exécution — la build affiche le monde en moins d'une
minute et il n'y avait pas de fenêtre d'observation fiable. Les deux moitiés se
complètent :

- **ici** : la branche de refus est réellement atteinte et sort en 3 ;
- **au banc** : la décision refuse bien 0,00275 (repère mesuré de l'écran de
  chargement) et accepte 0,292 puis 0,520 (deux captures réelles du monde).

## Le mode de réutilisation, et pourquoi il est dangereux

Ce contrôle a été joué avec `GATE_REUTILISER_BUILD=1`, qui saute l'import, le
manifeste éditeur et l'export. Mesurer un artefact périmé en croyant mesurer le
code courant est la famille de fautes la plus coûteuse de ce dépôt (ISS-018 ;
et l'export « au nom neuf, aux octets identiques » du 2026-08-16).

Trois garde-fous, aucun facultatif :

1. opt-in explicite par variable d'environnement ;
2. le SHA enregistré dans `contexte.json` doit égaler le HEAD courant, sinon
   sortie **3** ;
3. le mode est annoncé en clair dans le journal et écrit dans `contexte.json`
   (`"artefacts_reutilises": 1`).

**Ce mode ne doit jamais servir à produire une preuve de portail.** La preuve
rouge de `PREUVE_ROUGE.md` vient d'une exécution complète, sans réutilisation.
