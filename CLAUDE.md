# Éclats d'Orage — règles de travail quotidiennes

Action-aventure 3D stylisée, Godot **4.7.1-stable**, GDScript typé, Forward+, Jolt.
Monde : Vallée de Néris. Donjon : Citadelle de l'Œil-Tempête.

La source de vérité produit est @docs/MASTER_SPEC.md — ce fichier ne contient que
les invariants, les commandes réelles et la définition de « terminé ».

## Démarrage de session (5 min max)

1. `docs/STATUS.md` — état par fonctionnalité + preuve.
2. `docs/PROGRESS.md` — dernière entrée = handoff, dit exactement la prochaine action.
3. `docs/KNOWN_ISSUES.md` — ne pas re-découvrir un bug déjà consigné.
4. La section de `docs/MASTER_SPEC.md` correspondant au jalon courant, pas tout le fichier.

Une session = **un jalon borné ou un seul bug complexe**. Jamais « tout le jeu ».

## Commandes réelles

```bash
tools/env_report.sh                  # versions exactes -> docs/BUILD_ENVIRONMENT.md
tools/setup_godot.sh                 # (re)construit Godot 4.7.1 si absent — ~90 min
tools/validate_fast.sh               # niveaux 1-3 : import, parse, tests unitaires
tools/validate_release.sh            # niveaux 4-7 ; codes: 0 vert, 1 rouge, 3 BLOQUÉ
tools/blender/run_export.sh          # Blender -> .glb dans assets/
python3 tools/gltf_inspect.py <glb>  # validation glTF hors Godot
```

Binaire Godot : `$GODOT_BIN` (défaut `/usr/local/bin/godot`).

```bash
godot --headless --path . --import                 # import des ressources
godot --headless --path . --check-only --script <f.gd>   # parse d'un script
godot --headless --path . --script tools/godot/test_runner.gd  # tests
godot --path .                                     # lancer (nécessite un affichage)
```

## Invariants non négociables

- **Godot 4.7.1-stable exactement.** Jamais 4.8 dev/beta/RC. Vérifier avec
  `godot --version` avant de croire une API.
- **1 unité = 1 m**, Y vertical.
- **AZERTY prioritaire : `Q` = gauche.** Ne jamais mapper `Q` sur le lock-on.
- **GDScript typé**, `class_name` pour les types réutilisables, signaux typés,
  composition > héritage profond.
- **Définitions en `Resource` immuables ; état mutable séparé.** Deux exemplaires
  d'une arme ne partagent jamais leur durabilité.
- **Aucun contenu Nintendo** : ni modèle, ni son, ni carte, ni UI, ni nom affiché.
  Noms de code ennemis : `raider_red`, `raider_blue`, `raider_black`,
  `ravine_troll`, `centaur_hunter`.
- **L'image de référence n'est jamais un asset** (ni skybox, ni billboard, ni texture).
- Tout asset externe entre dans `ATTRIBUTIONS.md` **avant** d'entrer dans le build.
- Aucune boucle sur le monde entier par frame ; aucune allocation massive par frame.
- Ne jamais éditer `.godot/imported/` à la main.

## Règles de vérité (interdiction de validation prématurée)

| Mot | Signifie |
|---|---|
| Implémenté | présent et raccordé |
| Fonctionnel | testé dans une scène exécutable |
| Validé | conforme aux critères, sans régression connue |
| Final | zéro placeholder sur le chemin critique |

- Une affirmation sans preuve dans `evidence/` est `NON VÉRIFIÉ`, jamais « réussi ».
- Ne jamais inventer une capture, un FPS, une durée ou un résultat de test.
- Ne jamais halluciner une méthode Godot : vérifier dans la doc **4.7** ou tester.
- Si Internet est indisponible pour une affirmation : la marquer `À vérifier` et
  construire un test local.
- Après **deux** tentatives de correction similaires qui échouent : arrêter,
  revenir à la cause, réduire le cas, changer d'hypothèse.

## Ordre des priorités en cas de conflit

1. Lançable sans erreur bloquante → 2. boucle complète jusqu'à la victoire →
3. contrôles/caméra/zéro softlock → 4. composition proche de la référence →
5. lisibilité gameplay → 6. performance → 7. finition → 8. contenu optionnel.

Ne jamais sacrifier 1-4 pour agrandir le monde.

## Definition of Done d'un jalon

- [ ] `tools/validate_fast.sh` vert, code retour 0.
- [ ] Scénario rejoué réellement (pas seulement compilé).
- [ ] Preuve datée dans `evidence/<gate>/` reliée au commit.
- [ ] `docs/STATUS.md`, `docs/PROGRESS.md` mis à jour ; `KNOWN_ISSUES` si échec.
- [ ] Revue contradictoire à contexte frais → `PASS` / `FAIL` / `BLOQUÉ`.
- [ ] Commit petit, cohérent, réversible.

Ne jamais passer au Gate suivant sans le Gate courant vert ou explicitement `BLOQUÉ`.

## Gates (détail : docs/ROADMAP.md)

`0` init/continuité · `A` fondation · `B` traversal · `C` combat ·
`C.5` micro-verticale ≥ 75/100 · `D` graybox monde · `E` cuisine/save ·
`F` donjon électrique · `G` boss · `H` art ≥ 85/100 · `I` perf/livraison · `J` démo 3 min.

## Limites connues de cet environnement

Conteneur Linux **headless, sans GPU**. Le niveau 5 (capture) fonctionne via
Xvfb + Mesa llvmpipe, en rendu **logiciel** : utilisable pour la régression
visuelle, jamais pour une mesure. Les niveaux **6 et 7** (performance, soak,
export) ne sont **pas** exécutables ici et ne doivent pas être annoncés comme
réussis. Aucun périphérique audio non plus. Détail : `docs/BUILD_ENVIRONMENT.md`.
