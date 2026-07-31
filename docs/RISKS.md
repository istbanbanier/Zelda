# RISQUES — classés, avec déclencheur et plan

Exigence §0.6 de la Phase 0. Un risque sans signal d'alerte observable et sans
plan de repli n'est pas géré, il est seulement nommé.

Gravité : `G1` menace le projet · `G2` menace une phase · `G3` coûte du temps.
Probabilité : `P-haute` / `P-moyenne` / `P-basse`.

---

## RSK-01 — Art et animation : le goulot d'étranglement réel · `G1` · `P-haute`

Le prompt exige une qualité « haut de gamme painterly » : héros original rigué et
animé, cinq familles d'ennemis aux silhouettes distinctes, boss hero asset. C'est le
poste de travail le plus lourd et le moins automatisable de tout le projet — et §7.14
le dit explicitement : aucun shader ne rattrape une géométrie faible ou une animation
raide.

- **Signal d'alerte** : Gate C.5 sous 75/100, ou personnage encore gris à l'entrée de D.
- **Plan** : réduire le périmètre visible avant de baisser la qualité. Cinq assets
  excellents et réutilisables valent mieux que cinquante médiocres (§7.14). Valider
  `HeroShotLab` sur 80 × 80 m avant toute vallée complète.
- **Repli honnête** : si les compétences ou les assets légalement utilisables
  manquent, déclarer le blocage artistique — ne jamais appeler `final` un placeholder.

## RSK-02 — Aucune capacité de rendu dans l'environnement d'exécution · `G1` · `P-haute` (avérée)

Pas de GPU, pas d'affichage. La capture reste possible en rendu **logiciel**
(llvmpipe), mais la notation visuelle fine et toute mesure de performance ne le
sont pas : les gates C.5 (notation), H, I et J en dépendent directement.

- **Statut** : **avéré**, pas hypothétique. Voir KNOWN_ISSUES ISS-002.
- **Signal d'alerte** : `tools/validate_release.sh` sort en code 3, ou une capture
  échoue en code 5/6.
- **Plan** : `validate_release.sh` sort en code 3 « BLOQUÉ » plutôt que faux vert.
  Tenter le rendu logiciel llvmpipe pour la non-régression grossière uniquement.
- **Repli** : ces gates devront être exécutés sur une machine avec GPU. Le projet
  reste entièrement développable ici jusqu'à Gate G (graybox jouable).

## RSK-03 — Politique réseau : dépendances non téléchargeables · `G2` · `P-haute` (avérée)

`godotengine.org`, `downloads.godotengine.org`, `download.blender.org` bloqués.

- **Statut** : **avéré**. Contourné légitimement : moteur compilé depuis la source
  git (D-001), Blender depuis le dépôt Ubuntu (D-002).
- **Signal d'alerte** : un `curl`/`git` qui renvoie 403 sur un nouvel hôte, ou
  `tools/setup_godot.sh` qui échoue au clonage.
- **Risque résiduel** : toute future dépendance (addon, police, banque de sons)
  peut être injoignable. Le prompt interdit de toute façon d'installer un addon
  sans audit, version épinglée, licence et plan de retrait (§0.5).
- **Plan** : privilégier systématiquement le procédural et le fait-maison.

## RSK-04 — Dérive de portée : le prompt décrit un contenu très supérieur à une V0.1 · `G1` · `P-haute`

Cinq familles d'ennemis, boss trois phases, donjon quatre salles, cuisine, sauvegarde,
25-40 min de jeu, plus une qualité visuelle « wahou ».

- **Signal d'alerte** : une phase qui déborde sans que son gate approche du vert.
- **Plan** : l'ordre des priorités de §0.1 tranche tout arbitrage — jouable et
  complet d'abord, densité et finition ensuite. §4.2 liste ce qui est hors périmètre
  et doit le rester.
- **Repli** : couper dans le contenu optionnel (chasseur centaure, second itinéraire,
  coffres au-delà de huit) avant de couper dans la boucle ou le polish des 60
  premières secondes.

## RSK-05 — Performance non mesurable ici, donc non pilotable · `G2` · `P-moyenne`

Les budgets de §20.2 (≤ 16,6 ms, p95 ≤ 18,5 ms) supposent un matériel de référence.

- **Signal d'alerte** : un chiffre de performance apparaissant dans un document
  sans matériel, build, preset et durée associés.
- **Plan** : ne jamais annoncer de FPS non mesuré. Construire les scénarios
  reproductibles `Perf_*` (§20.11) dès que possible pour qu'ils soient prêts le jour
  où un GPU est disponible ; ils sont utiles même non exécutés, car ils fixent le
  protocole.
- **Repli** : dégrader dans l'ordre contrôlé de §20.8, jamais au hasard.

## RSK-06 — Propriété intellectuelle · `G1` · `P-basse` mais impact maximal

Le brief hérite de noms et d'une inspiration Nintendo.

- **Signal d'alerte** : un nom, une silhouette ou un son évoquant directement une
  œuvre existante lors d'une revue artistique.
- **Plan** : noms de code uniquement en interne (`raider_red`…), noms affichés
  pilotés par données, silhouettes et comportements originaux. `ATTRIBUTIONS.md`
  tenu **avant** qu'un asset entre dans le build. L'image de référence ne sert
  jamais d'asset (ni skybox, ni billboard, ni texture).
- **Contrôle** : point de vérification explicite à chaque gate artistique.

## RSK-07 — Web/Compatibility promis trop tôt · `G3` · `P-moyenne`

§5.2 interdit volumetric fog, SDFGI, SSIL, SSR, TAA, FSR2, decals et compute en Web.

- **Signal d'alerte** : une fonctionnalité de la liste interdite utilisée sur le
  chemin critique sans fallback Compatibility.
- **Plan** : le Web reste optionnel et arrive en Phase I. Ne jamais promettre une
  identité visuelle entre Web et natif.

## RSK-08 — Continuité entre sessions · `G2` · `P-moyenne`

Un agent qui perd le contexte réimplémente, casse, ou déclare « terminé » à tort.

- **Plan** : c'est précisément l'objet de la Phase 0. `STATUS`, `PROGRESS`,
  `KNOWN_ISSUES` et `DECISIONS` sont mis à jour **à chaque fin de session**, et le
  handoff indique exactement la prochaine action.
- **Signal d'alerte** : une session qui repose une question déjà tranchée dans
  `DECISIONS.md`, ou qui réimplémente quelque chose de `STATUS.md`.
- **Contrôle** : le critère « une session neuve reprend en moins de 5 min » n'est
  à ce jour vérifié que par **relecture** de la chaîne documentaire — voir
  TEST_REPORT T-07, qui le classe `PASS sous réserve`. Il ne sera réellement testé
  que par une session repartie de zéro.

## RSK-09 — Coût de reconstruction du moteur pour chaque session neuve · `G3` · `P-haute`

Le conteneur est éphémère : Godot devra être recompilé (~60-120 min) à chaque
session neuve tant que la politique réseau ne change pas.

- **Signal d'alerte** : `godot --version` absent ou différent de 4.7.1-stable en
  début de session.
- **Plan** : `tools/setup_godot.sh` est idempotent et vérifie le commit. Lancer la
  compilation **en arrière-plan dès le début** d'une session et travailler sur la
  documentation, les données et les scripts pendant ce temps.
- **Repli** : si un cache d'artefacts devient disponible, y déposer le binaire.
