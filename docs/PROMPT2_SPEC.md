# PROMPT 2 — PASSE D’AMÉLIORATION PROFESSIONNELLE DU PROJET GODOT 4.7.1 « ÉCLATS D’ORAGE »

## Instruction d’utilisation

Donner ce texte à Claude Code **dans le dépôt où le projet issu du premier prompt est déjà présent**.

Ce document est un prompt de continuation. Il ne demande pas de recréer le jeu, de repartir d’un projet vide ou de remplacer aveuglément le travail déjà réalisé. Le premier prompt reste la spécification de base de la verticale jouable. Le présent Prompt 2 ajoute une seconde passe de qualité, de profondeur, d’originalité, de robustesse et de finition.

Lorsque le présent document précise ou renforce une règle du premier prompt, la règle la plus exigeante et la plus récente s’applique. Lorsqu’il n’aborde pas un domaine, conserver le comportement validé du projet existant.

---

## 0. MISSION DE CONTINUATION — NE PAS RECOMMENCER LE PROJET

Tu interviens sur un jeu Godot déjà développé à partir d’un cahier des charges précédent. Ta mission est de transformer cette première version en une verticale beaucoup plus mémorable, cohérente et professionnelle.

Tu dois simultanément agir comme :

- game director ;
- lead gameplay programmer Godot ;
- combat designer ;
- technical game designer ;
- level designer ;
- AI designer ;
- puzzle designer ;
- technical artist ;
- animateur gameplay ;
- sound designer ;
- spécialiste UX/accessibilité ;
- ingénieur performance et QA ;
- responsable de l’intégration Claude Code.

Tu dois **inspecter, mesurer, conserver, corriger, étendre, tester puis polir**. Tu ne dois jamais :

- supprimer ou réinitialiser le dépôt pour gagner du temps ;
- écraser un système fonctionnel sans avoir démontré pourquoi une migration est nécessaire ;
- remplacer des scènes existantes par des prototypes moins complets ;
- annoncer une fonctionnalité terminée sans preuve dans le build réel ;
- confondre présence d’un script, absence d’erreur de parsing et qualité de jeu ;
- masquer un défaut de gameplay sous davantage de bloom, de particules ou de dégâts ;
- casser la boucle jouable complète obtenue avec le premier prompt ;
- copier les noms, silhouettes, symboles, personnages, interfaces, musiques ou assets d’une licence existante.

### 0.1 Résultat attendu

À la fin de cette passe, le projet doit conserver sa boucle complète, mais gagner :

1. une mécanique signature originale et transversale : le **Bracelet de Résonance** ;
2. un déplacement agréable même sans objectif ni combat ;
3. un combat plus expressif, tactique, lisible et mesurable ;
4. des ennemis qui perçoivent, coopèrent et réagissent sans tricher ;
5. un monde où matériaux, eau, charge, masse, bruit et environnement obéissent aux mêmes lois ;
6. des énigmes permettant compréhension, expérimentation et solutions alternatives cohérentes ;
7. un boss qui vérifie réellement les compétences apprises ;
8. trois styles de route, des points d’intérêt denses et une exploration guidée par la curiosité ;
9. une direction artistique plus maîtrisée et une image d’ouverture spectaculaire ;
10. une démo fiable de trois minutes conçue pour impressionner immédiatement ;
11. une performance stable, des options d’accessibilité et des preuves de validation ;
12. une architecture transmissible à une nouvelle session Claude Code sans perte de contexte.

### 0.2 Ordre des priorités en cas de conflit

1. Projet existant lançable et boucle début→victoire préservée.
2. Contrôles, caméra, absence de softlock et sauvegarde fiable.
3. Lisibilité des règles et plaisir du mouvement/combat.
4. Mécanique signature et cohérence systémique.
5. Composition, animation, audio et rendu « wahou ».
6. Performance stable et stabilité temporelle de l’image.
7. Densité de contenu facultatif.

Une fonctionnalité plus spectaculaire ne justifie jamais une régression sur un niveau supérieur.

### 0.3 Règles de vérité

Utiliser exclusivement les statuts suivants :

- `PASS` : critère exécuté avec preuve ;
- `PARTIAL` : fonctionne mais manque un sous-critère explicitement nommé ;
- `FAIL` : testé et échoue ;
- `BLOCKED` : obstacle externe précis ;
- `UNVERIFIED` : non testé.

Il est interdit de transformer `UNVERIFIED` en `PASS` par déduction. Toute affirmation finale doit être reliée à une commande, une capture, une vidéo, un profil, un scénario de reproduction ou un playtest documenté.

### 0.4 Autonomie attendue

Ne demande pas à l’utilisateur de choisir chaque constante de tuning ou chaque détail d’implémentation. Inspecte l’existant, adopte une valeur raisonnable, rends-la data-driven, vérifie-la, puis consigne la décision. Pose une question seulement si une information réellement bloquante ne peut pas être déduite ou testée sans modifier fortement le résultat demandé.

Tu dois aller au-delà du rapport : **implémenter réellement les améliorations**, jalon par jalon, jusqu’aux gates définis ci-dessous. Si le contexte de la session approche de sa limite, laisse le dépôt propre et transmets un état suffisamment précis pour la session suivante.

---

## 1. ÉTAPE ZÉRO OBLIGATOIRE — AUDIT DE LA VERSION DÉJÀ TERMINÉE

Avant toute modification :

1. Inspecter le dépôt, la branche, le statut Git et les changements non commités.
2. Ne pas modifier les changements préexistants sans comprendre leur origine.
3. Identifier la version exacte de Godot réellement installée, le renderer, le moteur physique 3D, la plateforme cible et les exports existants.
4. Vérifier `project.godot`, InputMap, autoloads, collision layers/masks, scènes principales, sauvegarde, addons et licences.
5. Cartographier les scènes, scripts, ressources, shaders, assets, tests et outils de debug.
6. Lancer le parse/import headless si disponible.
7. Lancer les tests existants.
8. Lancer réellement le jeu dans le même mode que l’utilisateur.
9. Jouer le chemin début→vallée→camp→donjon→boss→victoire.
10. Capturer la vue d’ouverture, le camp, une salle du donjon et le boss.
11. Profiler au minimum la vue d’ouverture, un combat groupé, une salle électrique et le boss.
12. Vérifier une sauvegarde puis un chargement au milieu de la vallée, du donjon et avant le boss.
13. Relever les erreurs récurrentes, warnings significatifs, placeholders, ressources manquantes, incohérences de contrôle et régressions.

Créer `docs/PROMPT2_AUDIT.md` avec cette matrice :

| Domaine | État actuel | Preuve | Risque | Action | Gate |
|---|---|---|---|---|---|
| Boot/import |  |  |  |  |  |
| Boucle complète |  |  |  |  |  |
| Mouvement/caméra |  |  |  |  |  |
| Combat |  |  |  |  |  |
| IA |  |  |  |  |  |
| Récolte/cuisine |  |  |  |  |  |
| Électricité/énigmes |  |  |  |  |  |
| Boss |  |  |  |  |  |
| Sauvegarde |  |  |  |  |  |
| Visuel/animation/audio |  |  |  |  |  |
| Performance |  |  |  |  |  |
| Accessibilité |  |  |  |  |  |
| Licences/attributions |  |  |  |  |  |

Conserver une capture et des mesures **avant amélioration** afin de produire un vrai comparatif avant/après.

### 1.1 Point de restauration

Si Git est disponible :

- conserver les changements de l’utilisateur ;
- créer un commit de checkpoint uniquement lorsque l’état existant est compris et cohérent ;
- travailler par petits commits réversibles et thématiques ;
- ne jamais utiliser de reset destructif ;
- ne pas mélanger refactor massif, nouveau gameplay et polish visuel dans le même commit.

### 1.2 Continuité Claude Code

Créer ou mettre à jour sans les gonfler artificiellement :

| Fichier | Contenu attendu |
|---|---|
| `CLAUDE.md` | commandes fiables, architecture stable, conventions, définition de terminé ; rester concis |
| `docs/MASTER_SPEC.md` | premier prompt, source de vérité de la base |
| `docs/PROMPT2_SPEC.md` | présent prompt de continuation |
| `docs/ROADMAP.md` | jalons P2, dépendances et critères de sortie |
| `docs/STATUS.md` | état réel et dernière preuve par système |
| `docs/PROGRESS.md` | journal et prochaine action exacte |
| `docs/DECISIONS.md` | décisions, raisons et alternatives rejetées |
| `docs/RESEARCH_LEDGER.md` | questions, versions, sources, expériences et décisions |
| `docs/KNOWN_ISSUES.md` | reproduction, gravité, cause supposée et statut |
| `docs/TEST_REPORT.md` | commandes, environnement, résultats et échecs |
| `docs/PERFORMANCE.md` | matériel, build, scène, preset, CPU/GPU/mémoire/frame time |
| `docs/ART_BIBLE.md` | formes, palette, matériaux, valeurs, captures et interdits |
| `docs/GAMEPLAY_BIBLE.md` | piliers, verbes, progression, tuning et matrices de décision |
| `docs/PLAYTESTS.md` | protocole, observations, métriques, décision et retest |
| `ATTRIBUTIONS.md` | source, auteur, licence et modification de chaque asset externe |
| `evidence/` | captures, vidéos, profils et logs provenant du build réel |

Une nouvelle session doit pouvoir comprendre le jalon actuel et lancer la validation pertinente en moins de cinq minutes.

### 1.3 Méthode de recherche et d’apprentissage

Tu dois apprendre ce qui est nécessaire, mais une recherche n’a de valeur que si elle devient une décision testée.

Pour toute API incertaine, choix graphique, comportement Jolt, navigation, import Blender/glTF, optimisation ou architecture :

1. Formuler la question précise.
2. Confirmer la version installée.
3. Lire en priorité la documentation officielle de cette version.
4. Consulter ensuite notes de migration, démos officielles, classes et code source si nécessaire.
5. Recouper les décisions coûteuses avec une seconde source primaire ou une expérience locale.
6. Construire le plus petit test capable de départager les options.
7. Mesurer sur renderer et matériel cibles.
8. Consigner question, URL, version, hypothèse, expérience, résultat, décision et limite.
9. Convertir l’apprentissage durable en test, règle ou outil reproductible.
10. Arrêter la recherche dès qu’une décision suffisamment fiable peut être testée.

Ne jamais halluciner une propriété Godot. Ne pas suivre silencieusement un tutoriel 4.0/4.1/`latest` si le projet utilise 4.7.1. Vérifier localement toute différence. Pour Godot 4.7, Jolt se configure dans les paramètres de physique 3D ; ne pas ajouter l’ancienne extension `godot-jolt` si elle n’est pas nécessaire au projet installé. Ne jamais redimensionner dynamiquement un corps physique ou une `CollisionShape3D` via le `scale` du nœud : modifier la ressource de forme de manière sûre et unique lorsque nécessaire.

Si Claude Code permet les sous-agents, utiliser des agents de projet à périmètre borné : recherche Godot en lecture seule, revue game feel, revue visuelle, profilage et QA contradictoire. Deux agents ne modifient jamais simultanément la même scène, la même ressource binaire ou le même import. L’agent principal relit, intègre et reteste tout.

**Gate P2-0** : audit complété ; chemin critique rejoué ; preuves avant modification conservées ; aucun travail utilisateur perdu ; backlog P2 classé par impact, risque et dépendance.

---

## 2. NOUVELLE NORTH STAR DE GAME DESIGN

Le projet ne doit pas seulement contenir beaucoup de fonctionnalités. Il doit produire des décisions intéressantes et des émotions reconnaissables.

### 2.1 Cinq piliers non négociables

1. **Le monde écoute** : héros, ennemis, objets, eau, métal et mécanismes obéissent aux mêmes règles.
2. **Le mouvement est une expression** : traverser un espace est déjà agréable et permet une route personnelle.
3. **Le combat est physique et tactique** : distance, direction, masse, posture, endurance, environnement et préparation comptent.
4. **La curiosité remplace la checklist** : silhouettes, lumière, son et conséquences attirent le joueur ; les marqueurs restent discrets.
5. **La difficulté est honnête** : l’échec enseigne, les télégraphes restent stables et l’assistance ne joue pas à la place du joueur.

### 2.2 Mechanics → Dynamics → Aesthetics

Créer dans `docs/GAMEPLAY_BIBLE.md` la matrice suivante et l’adapter aux observations réelles :

| Émotion recherchée | Dynamique vécue | Mécaniques responsables |
|---|---|---|
| Émerveillement | voir, imaginer une route, l’atteindre | landmarks, verticalité, panorama, Arc Step |
| Ingéniosité | combiner des règles et produire sa solution | conductivité, eau, polarité, masse, IA |
| Maîtrise | réussir mieux une action déjà comprise | déviation, esquive parfaite, posture, routes rapides |
| Tension | engager une ressource ou s’exposer | endurance, durabilité, charge, bruit, recovery |
| Soulagement/fierté | comprendre l’échec puis reprendre le contrôle | télégraphes, checkpoint court, récompense lisible |
| Appartenance au monde | constater que les règles sont cohérentes partout | ReactionSystem partagé, persistance, audio causal |
| Curiosité | une réponse ouvre une nouvelle question | traces, cadrage, raccourcis, récompenses informationnelles |

Toute nouvelle fonctionnalité doit renforcer au moins une émotion et au moins un pilier. Supprimer ou réduire les ajouts qui ne produisent qu’une ligne supplémentaire dans une liste.

### 2.3 Gameplay multiplicatif

Une mécanique centrale doit servir au moins **trois contextes** parmi : exploration, traversal, combat, infiltration, énigme, préparation et boss. Elle doit se connecter à au moins deux systèmes déjà existants.

| Règle | Exploration/traversal | Combat/infiltration | Énigme/boss |
|---|---|---|---|
| Conductivité | rail ou plateforme | arme chargée, piège de zone | propager, isoler, mettre à la terre |
| Eau/humidité | lit de rivière et route | augmente arc électrique, éteint feu | connecte une zone avec risque |
| Polarité | pont, bloc, appui | bouclier, métal projeté | alignement de relais |
| Impact/masse | rocher, obstacle cassable | recul, collision, armure | pression, contrepoids, pylône |
| Bruit | signal de danger/découverte | diversion, alerte, recherche | synchronisation ou indice audio |
| Endurance | route verticale | sprint, garde, esquive, lourde | vitesse contre sécurité |

Pour chaque obstacle majeur, viser :

- une solution principale clairement enseignée ;
- une alternative systémique cohérente ;
- un raccourci de maîtrise risqué mais légitime lorsque l’espace le permet.

Ne pas coder ces solutions sous la forme de trois booléens spéciaux propres à la salle. Elles doivent émerger de composants partagés.

### 2.4 Progression courte et qualitative

Pas d’arbre de statistiques générique ni de grind. La progression de la verticale repose sur :

- nouvelles opérations du Bracelet ;
- compréhension des règles ;
- nouvelles routes et raccourcis ;
- propriétés fortes d’armes ;
- trois `Fragments de Résonance` facultatifs au maximum ;
- maîtrise du joueur.

Le boss doit rester solvable sans Fragment. Les Fragments peuvent améliorer un style, jamais corriger un jeu volontairement désagréable au départ.

Proposition à valider en playtest, une propriété forte par Fragment :

- `Écho` : Pulse laisse brièvement une trace directionnelle de la dernière source sonore perçue, sans vision à travers les murs ;
- `Flux` : une mise à la terre réussie d’une charge significative rembourse une petite quantité d’endurance, avec cooldown ;
- `Élan` : Arc Step conserve une portion bornée de l’élan de sortie afin d’enchaîner un saut ou une attaque.

Les salles et le boss sont conçus pour les capacités de base. Une amélioration ne doit pas court-circuiter un puzzle critique ; si elle ouvre un raccourci, celui-ci est intentionnel et testé.

### 2.5 Courbe de la verticale

Utiliser la séquence `Introduire → Faire pratiquer → Varier → Combiner → Mettre sous pression → Faire maîtriser`.

Pacing cible indicatif :

1. 0–3 min : reveal, mouvement, Pulse et première curiosité.
2. 3–10 min : route libre, récolte, premier coffre et micro-obstacle.
3. 10–18 min : camp avec trois approches, défense et environnement.
4. 18–24 min : cuisine/préparation, pylône, Arc Link et Polarité.
5. 24–36 min : donjon, Arc Step, Ground, quatre règles combinées.
6. 36–45 min : antichambre, choix de préparation, boss et conclusion.

Adapter après playtest. Ne pas remplir artificiellement pour atteindre une durée.

---

## 3. MÉCANIQUE SIGNATURE ORIGINALE — BRACELET DE RÉSONANCE

Ajouter au héros un Bracelet de Résonance lié à la technologie originale du monde. Il manipule des relations présentes ; il ne crée jamais gratuitement énergie, objet ou solution.

### 3.1 Architecture

Préférer des composants et ressources typés, compatibles avec l’architecture existante :

- `ResonanceController` sur le joueur ;
- `ResonanceTargetComponent` sur toute cible valide ;
- `ResonancePort` pour les points de connexion ;
- `MaterialProfile` pour les propriétés durables ;
- `MaterialStateComponent` pour les états d’instance ;
- `ElementPacket` pour les apports cinétiques/électriques/thermiques/humidité ;
- `ReactionSystem` comme arbitre central ;
- `ResonanceActionDefinition` pour portée, coût, timing, filtres, VFX, audio et règle d’annulation.

Ne pas dupliquer un système existant équivalent. Si le projet possède déjà composants de statut ou ports électriques, les migrer proprement vers une interface commune.

Créer des actions InputMap sémantiques et remappables, jamais des touches codées en dur : `resonance_pulse`, `resonance_focus`, `resonance_confirm`, `resonance_cancel`, `resonance_cycle`, `resonance_ground`. Choisir les touches/manette après audit des conflits AZERTY et afficher leur binding réel dans l’UI.

### 3.2 Pulse

Impulsion brève révélant pendant 2 à 4 s :

- état électrique ;
- matériau réactif ;
- ports visibles/atteignables ;
- trace récente déjà déductible ;
- point faible observable ;
- connexion active et direction de flux.

Valeurs initiales à tuner : rayon proche 10 m, cône de focus jusqu’à 18 m, cooldown 1,2–1,8 s. Pulse ne révèle pas un coffre derrière un mur, une solution complète ou une cible que la fiction ne permet pas de comprendre. Il produit une onde lumineuse et un son spatial que certains ennemis peuvent entendre.

### 3.3 Arc Link

Permet de sélectionner deux ports compatibles et de créer un lien temporaire visible.

- portée initiale 12–16 m ;
- ligne de vue ou relais valide ;
- un lien actif au départ ;
- perte/limite d’énergie explicite ;
- transport d’une énergie existante, jamais génération gratuite ;
- source, chemin et destination toujours lisibles ;
- annulation sûre si port détruit, déchargé, hors portée ou sauvegarde rechargée ;
- liaisons persistées uniquement si le design le demande et si leurs IDs sont stables.

Usages : alimenter, détourner, décharger, piéger une zone, charger une arme, transmettre par une flèche conductrice, réveiller un mécanisme ou rediriger un arc de boss.

### 3.4 Polarité

Sur un objet métallique chargé et sous une limite de masse : attirer vers un ancrage ou repousser selon une force bornée.

- utiliser forces/impulsions compatibles Jolt ;
- ne jamais téléporter directement un `RigidBody3D` actif ;
- afficher direction, force, stabilité et destination probable ;
- effectuer les shape casts nécessaires avant engagement ;
- refuser clairement masse excessive, obstacle, acteur vivant protégé ou objet essentiel invalide ;
- limiter vitesse, force, durée et énergie ;
- prévoir récupération si l’objet sort de la zone jouable.

Usages : créer un appui, déplacer un pont, arracher un petit bouclier, projeter du métal, aligner un relais ou modifier une attaque du boss.

### 3.5 Arc Step

Dash physique court vers un ancrage chargé valide.

Valeurs initiales : portée 7–12 m, coût 18–25 endurance, cooldown court 0,25–0,45 s. Le trajet entier reçoit un sweep de capsule et le point d’arrivée une validation de sol, pente, plafond et espace libre.

Interdictions : traverser un mur, finir dans un collider, cibler un ancrage détruit, annuler le coût après exploitation, ignorer un danger sans télégraphe. En cas d’invalidation tardive, annuler vers le dernier état sûr avec feedback compréhensible.

Usages : franchir un vide, prolonger une chaîne de traversal, poursuivre une cible, sortir d’une zone ou atteindre un relais/boss.

### 3.6 Ground

Mise à la terre volontaire : dissiper la charge du héros, drainer un objet, neutraliser brièvement une zone ou rediriger une attaque si un support valide existe.

- startup visible 0,25–0,45 s ;
- immobilité ou vulnérabilité brève ;
- point de terre réellement connecté ;
- énergie dissipée bornée ;
- télégraphe source→héros/objet→terre ;
- pas d’immunité électrique permanente ;
- interaction explicite avec eau, métal, céramique et sol isolant.

### 3.7 Progression d’apprentissage

1. Pulse dès l’ouverture.
2. Arc Link au pylône de la vallée.
3. Polarité dans une situation extérieure sans danger mortel.
4. Arc Step à l’entrée du donjon.
5. Ground dans la deuxième moitié du donjon.
6. Boss : combinaison des cinq opérations, mais perfection non obligatoire en difficulté Aventure.

Chaque opération possède : tutoriel contextuel court, exercice sûr, variation, usage libre, usage sous pression, hint facultatif et scénario automatisé de régression.

### 3.8 UX et accessibilité

- surbrillance combinant forme, mouvement et couleur ;
- source, port sélectionné et destination visuellement distincts ;
- ligne prévue avant confirmation ;
- raison courte en cas de refus ;
- mode maintien ou bascule ;
- sensibilité et aim assist réglables ;
- palette alternative ;
- intensité des flashs et vibrations réglable ;
- son unique par succès, incompatibilité, surcharge et rupture ;
- jamais d’information portée uniquement par cyan/rouge.

### 3.9 Gate Bracelet

Dans `ReactionLab`, exécuter dix fois chacune des opérations dans son cas normal, cas limite, annulation, cible détruite, pause, sauvegarde/chargement et framerate 30/60/120. Gate réussi si :

- aucun état bloqué ;
- aucun passage à travers collision ;
- aucun objet essentiel perdu ;
- aucune énergie créée sans source ;
- feedback causal compréhensible ;
- chaque opération sert au moins trois contextes démontrés ;
- un nouveau joueur comprend l’objectif d’un exercice sans explication orale.

---

## 4. NOYAU SYSTÉMIQUE — MATÉRIAUX, ÉTATS ET RÉACTIONS

Le monde doit sembler cohérent, pas composé de scripts spéciaux par salle.

### 4.1 Profils de matériau

Créer des ressources `MaterialProfile` data-driven pour au minimum :

- bois ;
- métal ;
- pierre ;
- céramique/cristal ;
- eau ;
- terre conductrice ;
- matière organique ;
- matière isolante.

Champs possibles : masse/densité logique, conductivité, capacité de charge, isolation, inflammabilité, fragilité, seuil de fracture, absorption d’eau, friction logique, résistance thermique, VFX/audio d’impact, tags et réactions autorisées.

Ne pas confondre matériau de rendu et profil gameplay : plusieurs matériaux visuels peuvent partager une même loi, et une instance peut changer d’état sans dupliquer son asset.

### 4.2 États communs

- `Wet` : meilleure propagation électrique, résistance au feu réduite ; glissance seulement si signalée et testée.
- `Charged` : énergie stockée limitée, visible et décroissante selon profil.
- `Grounded` : dissipation vers un support valide, protection brève sans immunité absolue.
- `Overloaded` : seuil dépassé, télégraphe puis décharge, rupture ou stagger.
- `Burning` : uniquement sur matière inflammable, durée et propagation bornées ; eau éteint.
- `Fractured` : nouvel aspect, faiblesse aux impacts et éventuelle destruction contrôlée.

Le héros, les ennemis, armes, props et mécanismes utilisent les mêmes concepts. Les immunités sont déclarées dans les données, jamais dispersées en `if boss` ou `if puzzle_room_3`.

### 4.3 Paquets d’interaction

Une attaque ou interaction transmet des composantes distinctes :

- `kinetic` ;
- `electric` ;
- `heat` ;
- `wetness` ;
- éventuellement `noise` et impulsion.

Le `ReactionSystem` résout le résultat à partir du profil, de l’état, de l’énergie disponible et du contexte. L’événement conserve source, instigateur, équipe, position, normale, quantité, ID d’action et chaîne causale afin d’éviter boucles et doubles dégâts.

### 4.4 Propagation bornée

Toute propagation définit :

- énergie initiale ;
- perte par connexion ;
- rayon maximum ;
- nombre maximum de sauts ;
- fréquence par cible ;
- durée ;
- ensemble `visited` ou identifiant de chaîne ;
- plafond de travail par tick ;
- comportement lorsque le budget est dépassé.

Regrouper les changements jusqu’à la fin du tick physique puis recalculer seulement les sous-graphes marqués `dirty`. Aucun cycle infini, cascade non bornée ou allocation massive à chaque frame.

### 4.5 Physique et sécurité

- aucune modification concurrente du transform d’un body physique par plusieurs systèmes ;
- aucune collision shape mise à l’échelle dynamiquement ;
- shape cast avant mouvement assisté ;
- pooling seulement après mesure et sans état résiduel ;
- objets essentiels possèdent ID stable, zone de récupération et reset ;
- dégâts par collision utilisent vitesse relative, masse, seuil et cooldown par paire ;
- le joueur peut subir ses erreurs systémiques, avec télégraphe et plafond raisonnable ;
- les ennemis peuvent être affectés par le décor et entre eux lorsque la fiction physique le justifie.

### 4.6 Gate ReactionSystem

Construire une matrice automatisée profils×états×paquets et vérifier : résultat, énergie conservée/perdue, VFX/audio, dégâts, sauvegarde, reset et budget. Tester au minimum :

- eau×électricité ;
- métal×charge×Ground ;
- bois×chaleur×eau ;
- céramique×impact ;
- deux sources électriques ;
- objet essentiel hors zone ;
- chaîne cyclique ;
- ennemi et prop recevant la même interaction ;
- pause/ralenti ;
- 20, 50 puis 100 objets réactifs dans une scène de charge.

---

## 5. TRAVERSAL, FLOW ET CAMÉRA

Le déplacement doit être agréable avant toute récompense externe.

### 5.1 Locomotion mesurable

Conserver `CharacterBody3D` si l’architecture actuelle l’utilise correctement. Toutes les valeurs sont regroupées dans une ressource/configuration de locomotion et ajustables dans `TraversalLab`.

Cibles initiales à valider, pas vérités absolues :

- accélération au sol courte mais lisible ;
- décélération rapide sans arrêt robotique ;
- rotation caméra-relative avec courbe selon vitesse ;
- contrôle aérien limité mais intention conservée ;
- coyote time 0,10–0,15 s ;
- jump buffer 0,12–0,18 s ;
- snap au sol uniquement lorsque cohérent ;
- gestion stable des pentes, marches, coins, plafonds et plateformes ;
- aucun résultat dépendant du framerate de rendu ;
- input reçu visible dans la logique au tick physique suivant.

Instrumenter réception, buffer, consommation, changement d’état, vitesse désirée/réelle, contact sol et retour au contrôle.

### 5.2 Aides invisibles

Ajouter seulement des corrections bornées qui respectent l’intention :

- tolérance de bord ;
- correction latérale faible autour d’un coin ;
- grace de mantle lorsque les mains ont presque atteint la lèvre ;
- conservation courte de la cible de saut ;
- refus explicable lorsque plafond ou espace d’arrivée invalide ;
- priorité d’action stable en cas d’inputs simultanés.

Afficher toutes les aides dans un overlay debug. Elles ne doivent jamais téléporter, aspirer vers une plateforme non visée ou sauver une action clairement ratée.

### 5.3 Chaîne de Flow

Ajouter, si compatibles avec le level design existant :

- `vault` sur obstacle bas ;
- `mantle` haut/bas avec alignement et capsule validés ;
- `slide` après sprint, avec sortie sûre ;
- saut de paroi très borné uniquement sur surfaces prévues ;
- Arc Step vers ancrage ;
- attaque de sprint ou plongeante.

Construire une courte route de flow combinant sprint→vault→saut→mantle→Arc Step. Un novice doit la terminer sans précision pixel-perfect ; un expert doit pouvoir améliorer son temps d’au moins 20 % par maîtrise, sans exploit.

### 5.4 Escalade et endurance

Ne pas autoriser l’escalade sur toutes les surfaces. Utiliser tag, couche ou composant `ClimbableSurface` et un langage visuel cohérent.

- détection par plusieurs raycasts/shape casts plutôt qu’un unique rayon fragile ;
- normale, angle, espace de capsule et continuité validés ;
- transition sol→paroi→coin→mantle sans pop ;
- endurance drainée selon mouvement, pente et état ;
- arrêt/reprise lisible ;
- à zéro : glissade/chute prévisible avec bref délai de réaction, pas téléport ;
- pluie/humidité ne modifie l’adhérence que si le jeu l’enseigne clairement ;
- routes principales réalisables avec l’endurance de base ;
- routes facultatives récompensent planification ou maîtrise.

### 5.5 Caméra comme gameplay

Créer ou consolider des modes : `Explore`, `Sprint`, `LockOn`, `Aim`, `Climb`, `Interaction`, `Boss`, `Vista`, `Cinematic`.

Chaque mode définit pivot, distance, FOV, offsets, damping, limites verticales, collision et autorité d’entrée. Séparer suivi, collision, framing et impulsions. Le shake ne modifie jamais cumulativement le transform de base.

- `SpringArm3D` ou shape cast pour les obstacles ;
- réponse rapide lorsqu’un mur approche, récupération douce lorsqu’il disparaît ;
- fade ciblé ou repositionnement lorsque la géométrie masque le héros ;
- aucune reprise brutale du yaw après visée, lock-on ou cinématique ;
- target switch filtré par angle, distance, visibilité et direction du stick ;
- héros et menace prioritaire conservés dans une zone lisible ;
- test obligatoire dans couloir, pente, falaise, plafond, grand ennemi et multi-cible.

### 5.6 Infiltration légère et bruit

Ajouter une couche d’infiltration simple, connectée aux systèmes existants, sans construire un second jeu :

- perception visuelle par distance, angle, exposition et ligne de vue ;
- perception sonore par événements typés avec rayon/intensité ;
- marche/course/sprint, attaque, projectile, objet lancé, Pulse et explosion produisent des bruits différents ;
- dernière position connue, recherche locale puis retour ;
- diversion par objet/flèche ;
- herbe/ombre uniquement si leur rôle est visuellement fiable ;
- aucune jauge abstraite si le comportement peut être compris par posture, tête, voix et icône discrète.

Le camp extérieur doit permettre trois approches viables : frontal technique, isolement/infiltration, réaction environnementale. Toutes utilisent la même rencontre et les mêmes règles.

### 5.7 `TraversalLab`

Créer une scène avec : sol gradué, pentes, marches, coins, murs, plafond bas, vide, plateformes, obstacles de vault, lèvres de mantle, surfaces escaladables/non escaladables et ancrages Arc Step.

Overlay : état, vitesse, sol, normale, endurance, buffer, coyote, cible mantle, collision caméra, target Arc Step, raison de refus et frame time.

Gate : dix exécutions consécutives de chaque transition sans état bloqué, jitter critique, clipping majeur, input perdu ou arrivée invalide à 30/60/120 FPS.

---

## 6. EXPLORATION, ROUTES ET POINTS D’INTÉRÊT

### 6.1 Trois styles de route

Réorganiser la vallée existante sans l’agrandir inutilement afin qu’elle propose :

1. **Route de la rivière** : sûre, ressources, eau, conductivité, vue progressive.
2. **Route des hauteurs** : escalade, Arc Step, panorama, risque d’endurance, raccourci.
3. **Route des ruines/camp** : combat, infiltration, objets physiques et récompense tactique.

Les routes se croisent, révèlent des raccourcis et offrent des regards de retour sur les lieux traversés. Elles ne doivent pas être trois couloirs séparés.

### 6.2 Densité plutôt que taille

Viser 8 à 10 micro-POI significatifs dans la verticale existante, espacés de manière à ce qu’un élément intéressant soit régulièrement visible, audible ou déductible. Chaque POI répond à au moins deux fonctions :

- enseigner ou varier une règle ;
- raconter le monde ;
- offrir une décision ;
- révéler une route ;
- préparer le boss ;
- donner une récompense qui change la prochaine action.

Exemples : arbre foudroyé, pont magnétique, bassin conducteur, autel de terre, patrouille près de rochers, nid vertical, ruine montrant le langage du donjon, cache révélée par un comportement ennemi.

### 6.3 Guidage par curiosité

- landmarks de tailles et contrastes différents ;
- cadrages qui montrent un objectif et masquent partiellement le suivant ;
- lumière/son/mouvement pour attirer ;
- chemins formés par terrain, végétation et architecture ;
- carte et marqueurs utiles mais non omniscients ;
- aucun tapis d’icônes ;
- récompenses informationnelles et raccourcis, pas seulement monnaie.

Playtest obligatoire : faire parcourir la vallée sans instruction orale et noter où le regard, le chemin et la curiosité conduisent réellement.

### 6.4 Cuisine comme préparation tactique

Conserver la cuisine du premier prompt, mais faire en sorte qu’elle réponde à une question claire : « De quoi ai-je besoin pour la prochaine route ou rencontre ? »

- 1 à 5 ingrédients ;
- résultat déterministe à catégories compréhensibles ;
- aperçu avant validation sans dévoiler toutes les découvertes ;
- journal des plats déjà préparés ;
- comparaison soin, durée et effet ;
- règles de compatibilité simples ;
- pas de recettes nécessitant du farm ;
- ingrédients de résistance électrique garantis avant le boss ;
- animation courte et audio gratifiant, annulables sans duplication ;
- une action `plat rapide` équipée au maximum, utilisation visible et interruptible ;
- pas de pause infinie permettant de consommer dix plats au milieu d’un coup de boss.

Buffs minimaux : soin, endurance/récupération, résistance électrique, défense et attaque légère. Limiter le cumul : un effet principal de repas actif, avec règle claire de remplacement. Le buff doit modifier une décision sans devenir obligatoire à chaque combat.

Ajouter des ingrédients par affordance et lieu : isolant près d’un risque électrique, endurance près d’une route verticale, soin près d’un camp dangereux. La récolte guide et prépare ; elle ne remplit pas seulement l’inventaire.

Tester avec/sans cuisine, joueur prudent/maladroit, interruption, inventaire plein, sauvegarde pendant buff, expiration, remplacement et consommation rapide. Si les joueurs ouvrent systématiquement le menu après chaque coup, réduire l’abus plutôt que gonfler les dégâts ennemis.

---

## 7. COMBAT — RÉACTIVITÉ, DÉFENSE ET IDENTITÉ DES ARMES

Le combat existant doit être audité couche par couche. Ne pas ajouter des combos avant d’avoir validé entrée, mouvement, contact, réaction et caméra.

### 7.1 Contrat data-driven de chaque action

Conserver ou créer une ressource `AttackDefinition`/`ActionDefinition` décrivant :

- action d’entrée, priorité et conditions ;
- coût et moment de consommation ;
- startup, phase active et recovery ;
- buffer, queue, combo, cancel, dodge cancel et hit confirm ;
- déplacement, rotation et autorité root motion/code ;
- hitbox/sweep, équipe, masque et ID unique ;
- dégâts, posture, poise, recul, launch et paquets élémentaires ;
- hit-stop attaquant/cible, caméra, vibration, son et VFX ;
- tags `blockable`, `deflectable`, `dodgeable`, `interruptible` ;
- comportement contre mur, vide, perte de cible, rupture, mort et interruption.

Une animation ne doit pas cacher la logique. La phase active est déclenchée par une méthode/signal contrôlé ; chaque cible est touchée une seule fois par ID d’attaque. Aucun dégât à chaque frame d’overlap.

Valeurs de départ à retuner : buffer attaque 0,12–0,18 s, buffer esquive 0,10–0,14 s, fenêtre combo dans les derniers 25–35 %, hit-stop léger 0,035–0,055 s, lourd 0,070–0,095 s. Une action lente doit être intentionnellement anticipée, pas retardée par le code.

### 7.2 Instrumentation du game feel

Horodater :

1. réception de l’entrée ;
2. mise en buffer ;
3. consommation ;
4. début logique ;
5. premier changement de pose ;
6. phase active ;
7. contact ;
8. conséquence ;
9. retour au contrôle.

Afficher millisecondes et ticks dans `CombatLab`. Le rendu à 30, 60 ou 120 FPS ne doit pas modifier les résultats. Tester les fenêtres à ±1 tick.

### 7.3 Grammaire de feedback

Chaque impact suit :

1. **Intention** : anticipation, pose, trajectoire et son préparatoire.
2. **Contact** : hit-stop court, pose, transitoire audio et effet au point réel.
3. **Conséquence** : recul, posture, dégâts, environnement et caméra.
4. **Résolution** : recovery lisible et retour au contrôle.

Définir trois intensités cohérentes : léger, lourd, critique/boss. Une frappe légère ne déclenche pas un feedback supérieur à une déviation parfaite ou une rupture d’armure. Shake additif filtré, jamais accumulation sur le transform. Prévoir réglages shake, flash, vibration, motion effects et intensité VFX.

Tester le combat sans son, sans VFX et sans shake : timing et menaces doivent rester lisibles. Réactiver ensuite la pile ; elle doit amplifier la compréhension.

### 7.4 Défense expressive

Ajouter ou consolider :

- garde tenue ;
- déviation parfaite ;
- esquive directionnelle ;
- esquive parfaite ;
- poise ;
- posture ;
- brise-garde ;
- attaques imblocables ;
- protection anti-stunlock.

| Menace | Garde | Déviation | Esquive | Réponse systémique |
|---|---|---|---|---|
| légère | sûre mais coûteuse | forte posture | sûre si direction correcte | interruption/obstacle |
| lourde | gros coût et recul | seulement si autorisée | réponse standard | sortir de l’axe |
| brise-garde | casse/traverse | risquée ou interdite | oui | hauteur/impact |
| imblocable | non | non | oui | Arc Step/couverture |
| projectile | selon arme | renvoi si lisible | oui | couverture/polarité |
| arc électrique | risque avec métal | Ground contextuel | sortir de la chaîne | isolant/eau maîtrisée |

Réglages initiaux data-driven :

- garde frontale 120–145° ;
- coût selon masse/dégâts de posture ;
- zéro endurance provoque `GuardBreak` ;
- buffer de déviation ~0,10 s ;
- fenêtre parfaite initiale 0,12 s, ajustable 0,08–0,16 s ;
- si tentative trop précoce et bouton tenu, devenir garde ordinaire lorsque l’arme le permet ;
- tracking d’une mêlée décroît pendant le startup et se coupe avant la phase active ;
- esquive parfaite dans une fenêtre 0,10–0,16 s : petit remboursement d’endurance et `Clarity` ~0,35 s ;
- `Clarity` révèle ouverture/point faible sans ralentissement global obligatoire ;
- après gros stagger, 0,35–0,60 s de résistance aux petits staggers, sans invulnérabilité secrète aux dégâts.

Ne jamais communiquer une attaque uniquement par couleur. Forme, pose, trajectoire et son distinguent brise-garde, imblocable, saisie et charge électrique.

Séparer :

- **poise** : résistance instantanée au stagger d’une action ;
- **posture** : jauge tactique ouvrant une vulnérabilité ;
- **santé** : ressource de survie.

Une rupture de posture crée une fenêtre courte et positionnelle. Sur le boss, elle expose le noyau ; elle ne déclenche pas une longue cinématique répétitive.

### 7.5 Six familles d’armes distinctes

Ne pas produire six recolorations d’un même combo.

| Famille | Question tactique | Kit minimal | Faiblesse réelle |
|---|---|---|---|
| Gourdin de bois | balayer et projeter | chaîne large, lourde de recul, lancer volontaire | courte portée ; faible précision |
| Épée usée | lire et dévier | chaîne rapide, feinte légère→lourde, meilleure déviation | posture brute faible ; métal conducteur |
| Lance | contrôler la distance | thrust, sweep, charge tenue, attaque de course | mauvaise encerclée ou contre mur |
| Hache lourde | engager et briser | swings de posture, overhead, plongeante | startup/recovery élevés |
| Arc simple | préparer et déclencher | tir rapide, tir complet, diversion, point faible | munitions et vulnérabilité en visée |
| Lame conductrice | stocker et risquer | chaîne moyenne, charge Link/parade, décharge | faible durabilité et surcharge |

Limiter chaque famille à 4–6 actions vraiment utiles : neutre, lourde/tenue, sortie d’esquive, sprint/aérienne et propriété signature. Les lourdes déplacent, brisent, percent, chargent ou contrôlent ; elles ne sont pas seulement « dégâts ×2 ».

Auto-alignement borné par action, cible visible, angle/distance maximum et aucun déplacement à travers obstacle ou bord.

### 7.6 Durabilité tactique et butin

La durabilité ne diminue qu’en touchant ennemi, bouclier, cassable ou surface explicitement prévue. Jamais dans le vide.

- coût prévisible par action/matière ;
- avertissement à 25 % sans spam ;
- son et usure visuelle ;
- à zéro : hitbox coupée, instance retirée, sockets/références nettoyés ;
- auto-équipement selon préférence et sécurité, ou mains nues si choisies ;
- objets-clés et Bracelet incassables.

À l’état `Worn`, permettre une **action de dernier éclat** volontaire : lancer/frappe engagée, forte posture et réaction du matériau, puis rupture garantie. Confirmation si objet rare/important. Cette action reste facultative.

Une seule station d’entretien facultative peut réparer partiellement avec une ressource commune garantie. Si ce système ajoute grind, confusion ou backtracking, le couper avant les mécaniques centrales.

Le radial ne doit pas figer indéfiniment boss ou circuits. Après rupture, ne pas équiper automatiquement du métal dans une zone électrique sans avertissement.

Le loot évite les micro-statistiques aléatoires. Une variante d’arme peut avoir une propriété forte lisible : isolante, bonne déviation, brise-armure, légère, stockage de charge ou récupération de flèche. Récompenses critiques fixes ; aléatoire mineur seulement.

Avant le boss, valider automatiquement la présence d’au moins : deux armes utilisables, une option peu conductrice, un arc, munitions suffisantes, soin et possibilité de résistance électrique. Simuler économie prudente, moyenne et maladroite.

### 7.7 Matrice de décisions et stratégie dominante

Pour chaque rencontre, documenter les choix plausibles selon distance, nombre, armure, environnement, arme et état électrique. Collecter localement : première action, arme, durée, dégâts par source, dégâts reçus, garde/esquive/Résonance, position et cause d’échec.

Gate de profondeur :

- trois plans viables sur le camp ;
- aucune boucle simple ne produit plus de 70 % des victoires sans raison contextuelle ; ce seuil déclenche une analyse, pas un nerf automatique ;
- le joueur explique la menace et une réponse après l’échec ;
- l’expert gagne par lecture et maîtrise, pas par caméra cassée, stunlock ou IA ;
- le positionnement reste intéressant lorsque dégâts et spectacle sont réduits.

Identifier si une domination vient de sécurité, dégâts, coût, lisibilité, IA, géométrie ou économie. Renforcer alternatives et contres avant d’homogénéiser les armes.

### 7.8 `CombatLab`

Créer piste graduée, murs, pente, bord, mannequins de tailles/résistances différentes, cibles mobiles, deux ennemis et caméra libre.

Debug : hitboxes/hurtboxes/sweeps, timeline, état, endurance, posture, invulnérabilité, historique inputs/rejets, trajectoire, attaque ID, victimes déjà touchées, frame time, ralenti et pas-à-pas.

Scénarios : combo, mur, esquive dernier instant, déviation ±1 tick, multi-cible, changement de cible, tir près d’un obstacle, rupture, stagger simultané, Arc Step pendant attaque et Link pendant esquive.

Gate : dix exécutions sans input perdu non intentionnel, double hit, traversée de mur, caméra cassée ou état bloqué ; puis playtest à l’aveugle sur contrôle, clarté, satisfaction et injustice.

---

## 8. INTELLIGENCE ARTIFICIELLE ET RENCONTRES

### 8.1 Architecture hybride sûre

Utiliser une machine à états pour les invariants (`Idle`, `Patrol`, `Investigate`, `Engage`, `Attack`, `Recover`, `Stagger`, `Flee`, `Dead`) et une sélection utilitaire bornée seulement dans les états où un choix tactique existe.

Chaque option calcule un score explicable à partir de :

- distance et angle ;
- ligne de vue ;
- dernière position connue ;
- santé/posture/endurance ;
- rôle ;
- cooldown ;
- danger environnemental ;
- état électrique/humide ;
- alliés et tokens disponibles ;
- accessibilité navigation ;
- confiance/morale.

Afficher en debug les trois meilleurs scores, le choix, la raison d’un rejet et la durée de décision. Pas de comportement opaque impossible à diagnostiquer.

### 8.2 Perception honnête

- vision : distance, angle, ligne de vue et exposition ;
- audition : événements de bruit, pas lecture de la position du joueur ;
- mémoire : dernière position connue avec incertitude croissante ;
- partage d’information par cri ou proximité, avec délai ;
- perte de cible puis recherche locale ;
- aucun tir ou poursuite parfaite à travers mur ;
- temps de réaction data-driven, jamais instantané pour simuler la difficulté.

### 8.3 Coordination par tokens

Un `EncounterCoordinator` attribue des tokens : mêlée, distance, charge lourde, recherche et éventuellement interaction environnementale.

- Aventure : deux engagements mêlée simultanés maximum ;
- Maîtrise : troisième seulement si espace et télégraphes le permettent ;
- token avec timeout et libération sur interruption, mort, perte de cible ou changement d’état ;
- ennemis non engagés restent actifs par déplacement, menace, cri, projectile rare ou manipulation du décor ;
- aucun cercle passif évident autour du joueur.

### 8.4 Rôles et familles

Conserver les cinq familles du premier prompt, mais rendre leurs décisions réellement distinctes :

- pillard braise : impulsif, objet inflammable, pression simple ;
- pillard azur : repositionnement, projectile/diversion, soutien ;
- briseur d’obsidienne : garde, armure, contrôle d’espace ;
- colosse : masse, destruction de couverture, attaques engagées ;
- chasseur quadrupède : mobilité, portée, punition des lignes droites, phases de confiance.

Chaque famille possède silhouette, cadence, distance préférée, peur, vulnérabilité systémique et au moins un comportement observable qui la rend reconnaissable sans regarder sa couleur.

### 8.5 Mémoire, morale et environnement

Ajouter seulement si la base est stable :

- peur d’une surcharge proche ;
- recul après perte d’un chef/allié ;
- recherche d’une arme ou couverture ;
- contournement d’eau électrifiée ;
- possibilité de provoquer une erreur entre ennemis ;
- fuite courte ou reddition pour une famille adaptée.

La morale enrichit la rencontre ; elle ne doit pas transformer chaque combat en poursuite interminable. Borner durée, distance et conditions.

### 8.6 Navigation et performance

- utiliser `NavigationAgent3D`/`NavigationServer3D` conformément à la version installée ;
- attendre la synchronisation de la map avant une première cible ;
- ne pas recalculer toutes les destinations à chaque frame ;
- mettre à jour décisions et perception à fréquences différentes selon distance/importance ;
- adapter rayon, hauteur, couches ou maps/regions par famille après test, pas créer arbitrairement un navmesh complet par ennemi ;
- fallback sûr lorsque cible inaccessible ;
- éviter local avoidance coûteux sur tous les agents si une séparation plus simple suffit ;
- profiler un combat avec le nombre maximal d’ennemis prévu.

### 8.7 `AILab`

Scénarios : vision face/dos, obstacle, bruit, Pulse, perte de cible, dernière position, eau chargée, token abandonné, mort pendant attaque, nav impossible, allié bloquant, sauvegarde/chargement et 10+ agents en charge.

Gate : aucune omniscience, aucun token perdu, aucun état bloqué, décision explicable, rôles perceptiblement différents et budget CPU respecté.

---

## 9. DONJON ÉLECTRIQUE — ÉNIGMES SYSTÉMIQUES

Conserver le donjon et ses quatre salles, mais les transformer d’une suite de scripts en une progression de compréhension.

### 9.1 Doctrine

Chaque salle possède :

- une loi principale ;
- un état initial lisible ;
- une expérience sûre ;
- une variation ;
- une combinaison ;
- une conséquence visible à distance ;
- une récupération après erreur ;
- une solution principale ;
- une alternative systémique ;
- un raccourci de maîtrise si sûr ;
- un hint facultatif gradué.

La difficulté vient de la combinaison, pas de ports cachés, timing arbitraire ou objet minuscule.

### 9.2 Graphe électrique

Reprendre ou migrer vers des interfaces : sources, ports, câbles, relais, interrupteurs, batteries, récepteurs, zones d’eau, terre et isolants.

À chaque changement :

1. marquer le sous-graphe `dirty` ;
2. regrouper jusqu’à fin du tick physique ;
3. reconstruire les connexions spatiales affectées ;
4. parcourir depuis les sources actives avec `visited` ;
5. vérifier direction, portée, alignement, état et capacité ;
6. calculer énergie et récepteurs ;
7. comparer ancien/nouvel état ;
8. émettre seulement les changements ;
9. interpoler feedback visuel/audio ;
10. respecter budget et ordre déterministe logique.

Créer un affichage debug du graphe, des ports, de l’énergie, des connexions refusées et de la cause.

### 9.3 Salle 1 — Lire la chaîne

Objectif : source→conducteur→récepteur.

- bloc métallique déplaçable ;
- isolant évident ;
- Pulse révèle états, pas solution ;
- Arc Link peut corriger un petit écart ;
- aucune mort punitive ;
- reset immédiat.

### 9.4 Salle 2 — Circuit vertical et Ground

Objectif : comprendre hauteur, relais et mise à la terre.

- route physique et route Arc Step ;
- risque électrique télégraphié ;
- Ground appris dans un espace sûr ;
- choix entre décharger avant déplacement ou rediriger ;
- chute récupérable.

### 9.5 Salle 3 — Relais rotatifs et Polarité

Objectif : direction des ports et orientation.

- relais à silhouette lisible ;
- polarité aligne ou déplace ;
- feedback avant confirmation ;
- plusieurs ordres valides si les lois sont respectées ;
- pas de combinaison arbitraire à mémoriser.

### 9.6 Salle 4 — Batterie, eau et risque

Objectif : combiner transport d’énergie, eau conductrice et sécurité.

- batterie essentielle avec récupération ;
- eau peut raccourcir le circuit mais menacer le joueur ;
- solution sûre par isolants/terre ;
- solution experte plus rapide ;
- propagation bornée ;
- sauvegarde intermédiaire robuste.

### 9.7 Salle centrale et antichambre

Les quatre salles alimentent une représentation centrale visible. Chaque victoire modifie lumière, son, architecture et accès. L’antichambre vérifie une combinaison courte sans introduire une règle nouvelle et garantit l’équipement minimal du boss.

### 9.8 Anti-softlock et solveur

- IDs persistants ;
- reset local ;
- respawn des objets essentiels ;
- détection de sortie de bounds ;
- chargement depuis chaque état intermédiaire ;
- aucune porte irréversiblement fermée avec objet du mauvais côté ;
- solveur ou validateur de graphe pour états de référence ;
- invariants : source disponible, chemin potentiel, objet critique récupérable, sortie accessible.

Hints gradués après observation d’échecs, pas après un simple timer : rappeler loi, attirer vers cause, puis montrer relation. Ne jamais donner directement la séquence complète au premier hint.

### 9.9 `PuzzleLab`

Tester état initial, chaque action, ordres alternatifs, cycle, double source, objet détruit, reset, sauvegarde/chargement, mort, sortie/reprise, framerate et budget. Faire jouer sans instruction orale et demander au testeur d’expliquer la loi après chaque salle.

---

## 10. BOSS — GARDIEN DE L’ORAGE COMME EXAMEN DE MAÎTRISE

Conserver l’identité et les trois phases du boss, mais remplacer toute dépendance à des scripts fragiles par les systèmes communs.

### 10.1 Contrat général

- silhouette et point faible lisibles ;
- caméra boss dédiée mais compatible collision ;
- bibliothèque d’attaques data-driven ;
- chaque attaque possède startup, engagement, actif, recovery et réponse valide ;
- aucune attaque parfaite hors champ sans avertissement multimodal ;
- aucune rotation instantanée après engagement ;
- arène avec pylônes, terre, zones sûres et lignes de vue ;
- équipement minimal garanti ;
- checkpoint proche et reprise rapide ;
- boss possible sans Fragment ni action de dernier éclat.

### 10.2 Phase 1 — Lire et mettre à la terre

Le boss présente armure chargée, coups lourds, arc simple et pylône. Le joueur doit lire, éviter/dévier, utiliser Arc Link puis Ground pour créer une fenêtre de noyau. Réponse principale claire, alternative plus lente par posture.

### 10.3 Phase 2 — Surcharge et espace

Ajouter arcs en chaîne, zones d’eau/charge, destruction contrôlée et repositionnement. Polarité modifie un élément de l’arène ; Arc Step sert à sortir ou atteindre un relais. Ne jamais produire un écran entièrement dangereux sans route lisible.

### 10.4 Phase 3 — Combiner sous pression

Patterns plus courts et combinés, mais récupération honnête. Le joueur enchaîne observation, mouvement, Link/Ground et attaque du noyau. Réduire le temps mort, pas les télégraphes. Une dernière séquence spectaculaire doit rester jouable, pas devenir une cinématique déguisée.

### 10.5 Directeur de patterns borné

Créer une bibliothèque avec tags : distance, phase, danger, côté arène, cooldown, répétition, prérequis et réponse. Le directeur choisit parmi les patterns légaux en respectant :

- pas de répétition excessive ;
- pas de combinaison sans espace de réponse ;
- pas de pattern dépendant d’un pylône détruit/inaccessible ;
- budget simultané de projectiles, zones et VFX ;
- seed enregistrable pour reproduction ;
- transition de phase sûre ;
- fallback déterministe.

Ne pas utiliser de random pur sans historique.

### 10.6 Difficulté et anti-frustration

- Histoire : fenêtres légèrement plus généreuses, dégâts réduits, hints plus rapides ;
- Aventure : référence ;
- Maîtrise : cadence/combinaisons plus exigeantes, jamais télégraphes mensongers ;
- mode personnalisé : dégâts reçus, fenêtre défense, aim assist, hints et vitesse globale de combat dans des limites testées.

Après plusieurs échecs, proposer préparation/hint, pas modifier secrètement les règles. L’écran de mort doit permettre reprise rapide.

### 10.7 `BossLab`

Tester chaque attaque seule, chaque paire autorisée, transitions à seuils, stun, posture, pylône détruit, joueur sans métal, équipement minimal, sauvegarde, pause, mort simultanée, 30/60/120 FPS et plusieurs seeds.

Gate : chaque pattern possède une réponse démontrée ; zéro softlock ; boss dans le cadre ; causes d’échec compréhensibles ; temps de victoire raisonnable ; aucune stratégie unique n’annule les trois phases.

---

## 11. DIRECTION ARTISTIQUE ET RENDEMENT « WAHOU »

L’objectif n’est pas de promettre magiquement un budget AAA. Il faut obtenir une **qualité perçue premium** par composition, cohérence, animation, lumière, stabilité temporelle et finition ciblée.

### 11.1 `HeroShotLab` avant extension

Créer une micro-scène de 80×80 m reproduisant les éléments essentiels de la vue d’ouverture :

- héros original de dos ;
- herbe et fleurs au premier plan ;
- eau/chemin/camp au plan moyen ;
- pylône et citadelle au loin ;
- nuage d’orage et éclair ;
- lumière chaude latérale et profondeur froide ;
- atmosphère, vent, audio et légère vie environnementale.

Cette scène sert au look-dev des matériaux, échelles, valeurs, shaders, LOD, brouillard, animation et performance. Interdiction de propager un style générique à toute la vallée tant que cette micro-scène ne passe pas son gate.

### 11.2 Composition multi-échelle

La vue d’ouverture doit fonctionner :

- en vignette ;
- en niveaux de gris ;
- plein écran ;
- en mouvement ;
- avec HUD ;
- sur preset moyen.

Hiérarchie : héros→pylône/camp→citadelle/orage. Utiliser lignes de terrain, chemin, rivière, lumière et contraste. Préserver trois plans : premier plan détaillé et chaud, moyen jouable, lointain monumental et plus froid. Éviter distribution uniforme, symétrie involontaire et répétition procédurale visible.

### 11.3 Pipeline Blender → glTF 2.0 → Godot

Pour chaque famille d’asset :

1. échelle et axes documentés ;
2. transforms appliqués lorsque requis ;
3. noms, pivots, origine, matériaux et UV cohérents ;
4. LODs explicites ;
5. collisions simples séparées ;
6. rig/animations testés sur un asset pilote ;
7. export glTF 2.0 reproductible ;
8. import Godot contrôlé sans écraser les sources ;
9. presets d’import versionnés lorsque possible ;
10. attribution/licence enregistrée.

Tester cube, matériau, squelette et clip avant une production massive. Conserver sources DCC séparées des exports. Aucun asset extrait d’un jeu commercial.

### 11.4 Terrain et végétation

- macro-formes lisibles avant détail ;
- matériaux stylisés cohérents avec la palette ;
- variation par masque/vertex color/altitude, pas bruit uniforme ;
- herbe proche dense par MultiMesh/technique mesurée ;
- distance réduite et transition douce ;
- arbres en familles limitées avec silhouettes fortes ;
- vent partagé mais phases/amplitudes variées ;
- interaction locale du héros bornée ;
- éviter transparence coûteuse, overdraw et shimmer ;
- LOD/HLOD/culling validés en mouvement.

### 11.5 Éclairage et atmosphère

Approche recommandée à tester :

- lumière directionnelle et environnement maîtrisés ;
- LightmapGI pour zones statiques lorsque le bake et le workflow le justifient ;
- SDFGI uniquement là où son coût et ses limites sont mesurés ;
- brouillard volumétrique/fog volumes parcimonieux ;
- brume atmosphérique et désaturation lointaine ;
- ombres concentrées sur héros, combat et éléments proches ;
- éclairs pilotés par événement synchronisé lumière→VFX→tonnerre retardé ;
- aucune surexposition permanente détruisant les silhouettes.

Comparer au moins deux configurations dans `HeroShotLab`, avec captures et coût GPU. Choisir par preuve, pas par nombre de fonctionnalités activées.

### 11.6 Matériaux et shaders signatures

Créer un petit langage cohérent :

- sol/roche avec grandes formes et variation contrôlée ;
- végétation avec subsurface/fresnel stylisé modéré ;
- eau lisible et compatible gameplay ;
- énergie de Résonance à cœur clair, halo cyan maîtrisé et mouvement directionnel ;
- surcharge avec rythme accéléré ;
- matériaux mouillés/chargés/fracturés perceptibles sans tout rendre fluorescent ;
- héros séparé du fond par valeurs, rim ou traitement ciblé.

Tout shader possède fallback, paramètres exposés, budget et test de stabilité temporelle. Réduire particules/bloom avant de réduire la lisibilité.

### 11.7 Héros, ennemis et animation

Le héros doit être original, reconnaissable de dos et ne pas reproduire la silhouette d’un personnage existant. Palette et Bracelet forment sa signature.

Pipeline animation : locomotion blend, starts/stops, pivots, sauts, chutes, mantle, escalade, garde, impacts, six armes, Bracelet et boss. Utiliser retargeting/AnimationTree selon documentation de la version installée.

Priorités :

- contact pieds/sol crédible ;
- mains sur armes ;
- anticipation des attaques ;
- contact synchronisé ;
- réactions directionnelles ;
- transition sans pop ;
- silhouette lisible ;
- secondary motion bornée ;
- aucun clipping majeur sur le chemin de démo.

Une animation spectaculaire ne doit pas retirer le contrôle trop longtemps ou désaligner la hitbox.

### 11.8 Score visuel reproductible

Noter la capture North Star sur 100 :

- composition et hiérarchie : 20 ;
- profondeur/atmosphère : 15 ;
- lumière/couleur : 15 ;
- héros/silhouette : 10 ;
- matériaux/cohérence : 10 ;
- végétation/terrain : 10 ;
- citadelle/pylône/orage : 10 ;
- stabilité temporelle/performance : 10.

`HeroShotLab` doit atteindre 85/100 avant propagation finale. Toute note doit citer un défaut visible et une action, pas seulement « beau ».

---

## 12. AUDIO, UI, DIFFICULTÉ ET ACCESSIBILITÉ

### 12.1 Audio causal

Chaque système central possède un langage sonore :

- matériau et masse aux impacts ;
- startup/contact/recovery du combat ;
- Pulse, port compatible, refus, Link, charge, Ground et surcharge ;
- état d’alerte/recherche/morale des ennemis ;
- endurance faible et arme usée sans alarmes répétitives ;
- circuit source→chemin→récepteur ;
- boss et transitions.

Spatialiser ce qui aide à localiser. Limiter voix/sons simultanés. Ducking court et hiérarchisé pour impact majeur, jamais compression permanente. Tonnerre retardé selon distance apparente pour donner de l’échelle.

Musique adaptative par couches : exploration, menace, combat, donjon, boss phases et victoire. Transitions sur mesures ou points musicaux, avec fallback si événement répété.

### 12.2 HUD contextuel

Afficher ce qui aide une décision immédiate : santé, endurance lorsqu’elle change, arme/durabilité, munitions, cible/état, interaction et feedback Bracelet. Masquer progressivement hors contexte.

- UI originale ;
- marges sûres ;
- navigation clavier/manette ;
- comparaison de loot compacte ;
- aucun réticule/couleur emprunté à une licence ;
- feedback d’erreur court ;
- sous-titres et indications de locuteur/direction lorsque pertinent.

### 12.3 Options obligatoires

- remapping complet clavier/manette ;
- mode maintien/bascule pour visée, lock-on et focus Résonance ;
- sensibilité X/Y et inversion ;
- aim assist réglable ;
- taille UI/sous-titres ;
- contraste et palette daltonisme ;
- intensité flash, bloom, shake, vibration et motion effects ;
- FOV dans une plage testée ;
- volume séparé musique, voix, effets, ambiance ;
- indices d’énigme : désactivés, contextuels, renforcés ;
- pause lors de menus selon mode solo ;
- sauvegarde des options.

### 12.4 Difficulté multidimensionnelle

Ne pas réduire la difficulté à multiplier les PV.

Profils :

- `Histoire` : dégâts reçus réduits, fenêtres plus généreuses, hints plus rapides ;
- `Aventure` : expérience de référence ;
- `Maîtrise` : pression et combinaison accrues dans les limites de lisibilité ;
- `Personnalisé` : dégâts reçus, fenêtre de défense, aim assist, hints, vitesse combat et endurance dans des plages validées.

Conserver mêmes règles, mêmes timings annoncés et mêmes affordances. Ne jamais modifier secrètement le jeu après un échec. Afficher clairement ce que chaque option change.

### 12.5 Validation multimodale

Tester : sans son, en niveaux de gris, avec shake à zéro, flash réduit, UI agrandie, clavier seulement, manette seulement et preset Histoire. Une information critique doit toujours avoir au moins deux canaux parmi forme, mouvement, position, son, texte, vibration et couleur.

---

## 13. PERFORMANCE, STABILITÉ ET PROFILAGE

Ne jamais déclarer « optimisé » à partir du nombre d’objets ou d’une impression dans l’éditeur. Mesurer un build représentatif sur le matériel réellement disponible.

### 13.1 Cibles honnêtes

Documenter : CPU, GPU, RAM, OS, résolution, renderer, preset, build debug/release, fréquence écran et version exacte.

Objectif principal si le matériel le permet : 1080p, preset High, 60 FPS avec frame pacing stable. Prévoir un preset 30 FPS visuellement cohérent pour matériel plus faible. Si la machine de développement ne peut pas représenter la cible, annoncer la limite et fournir les mesures disponibles sans inventer.

À 60 FPS, budget total 16,67 ms ; à 30 FPS, 33,33 ms. Ne pas fixer arbitrairement un partage CPU/GPU avant profilage. Suivre moyenne, médiane, percentile élevé, pics, mémoire et hitchs, pas seulement FPS moyen.

### 13.2 Scénarios obligatoires

1. Vue North Star immobile puis rotation rapide.
2. Sprint dans l’herbe avec streaming/LOD.
3. Camp avec nombre maximal d’ennemis et réactions.
4. Eau électrifiée avec propagation.
5. Salle du donjon avec graphe complet.
6. Boss phase 3 et VFX maximum légal.
7. Ouverture d’inventaire, changement d’arme et première utilisation de chaque effet.
8. Session continue de 60 minutes avec sauvegardes/chargements.

### 13.3 Frame pacing et interpolation

- physique à fréquence fixe documentée ;
- interpolation activée/configurée selon documentation 4.7 si adaptée ;
- téléports, respawns et changements de scène utilisent la procédure de reset d’interpolation appropriée ;
- aucun système ne modifie le même transform dans `_process` et `_physics_process` sans contrat clair ;
- caméra suit le domaine temporel cohérent avec le personnage ;
- tests 30/60/120 FPS et avec variation de frame time ;
- diagnostiquer séparément jitter, stutter, input lag et shader compilation.

### 13.4 Rendu et monde

Appliquer après mesure :

- mesh LOD ;
- visibility ranges/HLOD ;
- MultiMesh pour végétation/instances adaptées ;
- occlusion culling dans les espaces qui en bénéficient ;
- shadow distances et résolutions par importance ;
- réduction overdraw/transparence ;
- densité/portée de végétation par preset ;
- budget particules, lumières et FogVolumes ;
- matériaux partagés et nombre de variantes maîtrisé ;
- résolution interne/upscaling seulement après comparaison de netteté, ghosting et coût ;
- warming contrôlé des shaders/effets du parcours de démo lorsqu’une API officielle le permet.

Ne pas utiliser un cache ou pooling qui conserve état, signaux, target, matériau ou charge d’une ancienne instance.

### 13.5 Chargement et streaming

La verticale est compacte : ne pas construire un framework open world général sans preuve de besoin. Commencer par scènes modulaires, chargement en arrière-plan officiel et zones simples.

- chargement asynchrone avec progression et gestion d’erreur ;
- activation différée seulement lorsque ressource prête ;
- aucun accès à un nœud libéré pendant transition ;
- persistance par IDs, pas références de scène fragiles ;
- garder les laboratoires et le menu légers ;
- profiler temps de chargement, pic mémoire et hitch d’activation ;
- ajouter streaming spatial plus complexe uniquement si mémoire/temps mesurés le justifient.

### 13.6 Navigation, réactions et IA

Définir des budgets séparés :

- requêtes/path updates par seconde ;
- décisions utility par seconde ;
- raycasts de perception par frame ;
- événements de bruit actifs ;
- sous-graphes de réaction recalculés ;
- sauts de propagation ;
- projectiles/impacts/VFX simultanés.

Échelonner les mises à jour, mettre en sommeil les agents non pertinents et éviter les allocations répétées. Une optimisation ne doit pas rendre l’IA aveugle à un événement critique ou retarder un feedback causal.

### 13.7 Presets

Minimum :

- `Low` : ombres, fog, végétation, particules et distance réduits ;
- `Medium` : composition préservée avec densité modérée ;
- `High` : référence ;
- éventuellement `Ultra` seulement si différence visible et mesurée.

Le gameplay, les collisions, les ports et les télégraphes restent identiques. Un preset ne peut pas supprimer une herbe nécessaire à l’infiltration ou un VFX nécessaire à une énigme sans alternative.

Si un export Web est conservé, utiliser le renderer Compatibility et une variante explicitement simplifiée ; tester réellement l’export. Ne pas promettre Forward+ ou des effets incompatibles sur Web.

### 13.8 Gate performance

Créer `docs/PERFORMANCE.md` avec tableau avant/après par scénario : FPS, frame CPU, frame GPU, mémoire, draw calls/objets si disponibles, 1 % low ou percentile pertinent, hitch max et cause dominante.

Gate réussi si :

- cible choisie tenue de manière stable sur le matériel déclaré ;
- pas de freeze gameplay >100 ms sur le parcours de démo ;
- pas de hitch répété à la première attaque/effet après warm-up prévu ;
- pas de fuite visible sur 60 minutes ;
- aucun pop LOD majeur sur les distances de la démo ;
- budget IA/réaction respecté sous charge ;
- presets réellement différents et cohérents ;
- dégradation visuelle ne casse pas la lisibilité.

---

## 14. TESTS, TÉLÉMÉTRIE ET PLAYTESTS

### 14.1 Pyramide de validation

1. **Parse/import** : scripts, ressources et scènes se chargent.
2. **Unitaires** : calculs purs, états, économie, graphe, scoring utility, sérialisation.
3. **Intégration** : personnage+caméra, attaque+cible, réaction+matériau, IA+navigation, puzzle+save.
4. **Scènes laboratoire** : timings, collisions et interactions observables.
5. **Golden path** : partie complète et démo.
6. **Playtests humains** : compréhension, contrôle, stratégie, plaisir et accessibilité.
7. **Release validation** : build exporté, stabilité, licences et preuves.

Chaque bug réel important reçoit un test de régression au niveau le plus bas capable de le reproduire.

### 14.2 Laboratoires obligatoires

| Lab | But | Cas essentiels |
|---|---|---|
| `InputLab` | entrées, buffers, remap | press/release/hold, conflits, 30/60/120 |
| `TraversalLab` | contrôle et transitions | pente, coin, plafond, vide, Flow, Arc Step |
| `CombatLab` | timing/contact/caméra | ±1 tick, mur, multi-cible, six armes |
| `ReactionLab` | lois matérielles | matrice états, cycles, budgets, save |
| `AILab` | perception/décision | LOS, bruit, utility, tokens, morale |
| `PuzzleLab` | graphe et softlock | états, reset, solveur, hints |
| `BossLab` | patterns et solvabilité | actions, paires, seeds, équipement minimal |
| `HeroShotLab` | image et coût | captures fixes, mouvement, presets, profil GPU |

Tous doivent être lançables séparément par commande/scène documentée.

### 14.3 Matrice combinatoire à risque

Tester au minimum :

- mouvement×caméra ;
- attaque×mur/vide ;
- esquive×Arc Link ;
- Arc Step×cible détruite ;
- eau×électricité ;
- Ground×deux sources ;
- Polarité×objet essentiel ;
- IA×danger environnemental ;
- rupture×transition boss ;
- save/load×chaque état persistant ;
- pause/ralenti×timers ;
- changement de scène×signaux différés ;
- pool×charge/material state ;
- preset graphique×télégraphe.

### 14.4 Télémétrie locale de playtest

Uniquement locale, désactivable, sans donnée personnelle ni envoi réseau. Enregistrer avec timestamp/seed/version :

- route et POI visités ;
- morts et causes ;
- durée de rencontre/salle/boss ;
- armes et actions utilisées ;
- dégâts par source ;
- usage Bracelet ;
- hints demandés ;
- resets/softlocks détectés ;
- options/difficulté ;
- frame spikes par zone.

Ne jamais considérer un seul chiffre comme une conclusion. Croiser avec observation et entretien court.

### 14.5 Protocole de playtest

Faire tester à une personne qui n’a pas construit la fonctionnalité. Ne pas expliquer avant qu’elle soit bloquée. Noter :

- où elle regarde et va ;
- ce qu’elle pense possible ;
- première stratégie ;
- moment de confusion ;
- cause supposée de l’échec ;
- seconde tentative ;
- usage spontané des systèmes ;
- plaisir, tension et envie de rejouer.

Questions après l’action, pas pendant : « Que s’est-il passé ? », « Quelle règle as-tu comprise ? », « Qu’aurais-tu essayé ensuite ? », « Qu’est-ce qui semblait injuste ? ».

### 14.6 Gate « amusant avant habillage »

À chaque verticale graybox, notes 1–5 : contrôle, clarté, profondeur de décision, rythme/tension, envie de recommencer. Exiger un exemple concret par note.

Gate : aucun axe critique <3 ; contrôle et clarté ≥4 ; viser moyenne ≥4 avant polish final. Signaux forts : le joueur essaie une seconde solution, améliore son parcours, change de plan, utilise sa récompense et veut rejouer.

Si le plaisir dépend seulement des dégâts, du loot ou des effets, revenir aux timings, espaces et règles.

### 14.7 Régression visuelle

Captures déterministes ou reproductibles : North Star, camp, entrée donjon, chaque salle, boss par phase et victoire. Même résolution, preset, heure, caméra et seed lorsque possible.

Comparer : composition, valeurs, couleurs, assets manquants, LOD, ombres, effets, UI et stabilité temporelle. Une capture fixe ne suffit pas pour shimmer, ghosting, pop ou jitter : produire aussi une courte vidéo réelle.

---

## 15. DÉMO DE TROIS MINUTES « IMPRESSIONNER MON FRÈRE »

Créer un mode `DemoRoute` honnête. Il charge une sauvegarde légitime et prépare le parcours, mais ne change ni l’IA, ni les dégâts, ni la précision requise, ni les règles. Les inputs restent joués en direct.

### 15.1 Déroulé cible

1. **0:00–0:12** — reveal de la vallée : héros de dos, herbe au vent, citadelle, éclair et tonnerre.
2. **0:12–0:45** — prise de contrôle : course fluide, vault, saut, mantle puis Arc Step au panorama.
3. **0:45–1:35** — camp : Pulse, diversion par bruit, déviation parfaite, changement d’arme, Polarité sur un prop et réaction de groupe.
4. **1:35–2:15** — système : Arc Link source→métal→eau, danger visible, Ground puis ouverture spectaculaire d’un raccourci.
5. **2:15–3:00** — extrait légitime de boss : esquive d’un pattern, Arc Step, Link vers pylône, Ground, noyau exposé et conclusion visuelle forte.

### 15.2 Robustesse de démonstration

- variante si une action est ratée, sans tricher ;
- aucun écran bloqué ;
- aucun placeholder ;
- aucun chargement visible ou compilation shader ;
- aucun tutoriel bavard ;
- aucun pop LOD évident ;
- caméra fiable même avec entrée imparfaite ;
- audio mixé pour des haut-parleurs ordinaires ;
- possibilité de rejouer rapidement ;
- capture sans coupe d’une exécution réelle réussie.

Concentrer le plus haut niveau de polish sur les 60 premières secondes, puis sur les deux moments systémiques et la fin boss.

**Gate Demo** : trois exécutions consécutives sans crash, softlock, hitch majeur ou comportement différent ; vidéo non coupée ; revue par une personne externe ; aucun élément illégal ou trompeur.

---

## 16. ORDRE D’IMPLÉMENTATION IMPOSÉ POUR LE PROMPT 2

Ne pas développer tous les chantiers en parallèle. À chaque phase : inspecter→formuler hypothèse→modifier au minimum→tester→jouer→capturer→documenter→commit cohérent.

### Phase P2-0 — Audit et sécurité

- exécuter section 1 ;
- conserver baseline visuelle/performance ;
- corriger uniquement les blockers empêchant l’audit ;
- créer roadmap et preuves.

**Sortie** : Gate P2-0.

### Phase P2-1 — Réponse, caméra et laboratoires

- InputLab, TraversalLab et CombatLab ;
- instrumentation ;
- coyote/buffer/mantle/caméra ;
- pipeline d’action data-driven ;
- tests 30/60/120.

**Sortie** : mouvement agréable sans contenu, caméra stable, attaque fiable dix fois sur dix.

### Phase P2-2 — Bracelet et ReactionSystem

- profils, états et paquets ;
- Pulse, Arc Link, Polarité, Arc Step, Ground ;
- UI/audio/accessibilité ;
- ReactionLab ;
- intégration à un prop et un ennemi.

**Sortie** : Gate Bracelet + Gate ReactionSystem.

### Phase P2-3 — Combat profond, armes et IA

- garde/déviation/esquive/posture ;
- six identités d’armes ;
- dernier éclat et économie ;
- perception, utility bornée et tokens ;
- camp à trois approches ;
- playtest stratégie dominante.

**Sortie** : CombatLab/AILab verts et camp amusant en graybox.

### Phase P2-4 — Exploration et progression

- trois styles de route ;
- 8–10 POI ;
- progression du Bracelet et Fragments facultatifs ;
- infiltration/bruit ;
- playtest sans marqueurs ;
- sauvegarde de tous nouveaux états.

**Sortie** : chaque route a une raison, un choix et un retour ; aucune route obligatoire ne dépend d’une technique experte.

### Phase P2-5 — Donjon et boss

- migration vers lois communes ;
- quatre salles ;
- solveur/reset/hints ;
- boss library/director ;
- solvabilité avec équipement minimal ;
- PuzzleLab/BossLab.

**Sortie** : donjon et boss complets sans softlock, règles comprises par testeur externe.

### Phase P2-6 — Benchmark visuel et audio

- HeroShotLab ;
- art bible et pipeline assets ;
- héros/kit environnement/énergie ;
- éclairage, fog, végétation, LOD ;
- animation, VFX, audio et UI ;
- score 85/100 ;
- propagation au chemin critique seulement après validation.

**Sortie** : capture et vidéo nettement supérieures à la baseline, sans régression de lisibilité/performance.

### Phase P2-7 — Performance, accessibilité et démo

- profils et presets ;
- frame pacing et hitchs ;
- options d’accessibilité ;
- DemoRoute ;
- partie complète, session 60 min et export ;
- revue contradictoire finale.

**Sortie** : tous les gates critiques PASS ; les limites non critiques sont documentées honnêtement.

Ne pas avancer vers une phase coûteuse avec un gate critique rouge. Une phase peut être subdivisée en sessions, mais son état et sa prochaine action doivent être transmis.

---

## 17. CHECKLIST D’ACCEPTATION PASS/FAIL

### 17.1 Gameplay

- [ ] boucle début→victoire du premier prompt préservée ;
- [ ] AZERTY : `Q` déplace bien à gauche ; clavier et manette remappables ;
- [ ] mouvement, caméra, coyote, jump buffer, pentes et marches fiables ;
- [ ] vault, mantle et Arc Step sans traversée de collision ;
- [ ] escalade limitée aux surfaces prévues et zéro endurance géré ;
- [ ] trois styles de route et 8–10 POI significatifs ;
- [ ] camp viable en frontal, infiltration et environnement ;
- [ ] aucune omniscience IA ; tokens toujours libérés ;
- [ ] attaque touche une fois ; buffers/cancels/recovery conformes aux données ;
- [ ] garde, déviation, esquive, posture et anti-stunlock fonctionnent ;
- [ ] six armes perceptiblement différentes ;
- [ ] durabilité, dernier éclat, rupture et auto-équipement sûrs ;
- [ ] économie garantit la solvabilité sans grind ;
- [ ] Pulse, Arc Link, Polarité, Arc Step et Ground fiables/remappables ;
- [ ] mêmes lois de matériau dans monde, combat, donjon et boss ;
- [ ] aucune propagation infinie ni énergie créée ;
- [ ] quatre salles solvables, reset/save/hints fiables ;
- [ ] boss trois phases avec réponse à chaque pattern ;
- [ ] difficulté et options personnalisées explicites ;
- [ ] sauvegarde/reprise de tous les nouveaux états ;
- [ ] DemoRoute exécutable sans manipulation cachée.

### 17.2 Visuel, animation et audio

- [ ] HeroShotLab et North Star ≥85/100 ;
- [ ] héros, camp, pylône, citadelle et orage lisibles ;
- [ ] trois plans et hiérarchie en vignette/niveaux de gris ;
- [ ] aucun placeholder sur le chemin de démo ;
- [ ] aucun asset manquant/rose ;
- [ ] pas de tiling ou répétition majeure ;
- [ ] pas de pop LOD majeur sur la démo ;
- [ ] silhouettes des cinq familles distinctes ;
- [ ] Bracelet lisible sans sur-bloom ;
- [ ] aucun foot sliding/clipping majeur sur les actions principales ;
- [ ] télégraphes compréhensibles sans couleur seule ;
- [ ] caméra boss garde héros et menace dans le cadre ;
- [ ] audio confirme matériau, danger et causalité ;
- [ ] mix et musique ne masquent pas les informations ;
- [ ] image stable en mouvement, sans shimmer/ghosting critique.

### 17.3 Technique et production

- [ ] version Godot/renderer/physique documentée ;
- [ ] zéro parse error et zéro erreur récurrente ;
- [ ] build/export reproductible ;
- [ ] tests automatisés pertinents verts ;
- [ ] tous les Labs lançables séparément ;
- [ ] zéro crash/fuite visible sur 60 minutes ;
- [ ] performance mesurée sur matériel et preset déclarés ;
- [ ] aucun freeze >100 ms sur la démo ;
- [ ] budgets IA/réaction/navigation sous charge ;
- [ ] IDs persistants uniques et migrations de sauvegarde ;
- [ ] options et télémétrie locale sans donnée personnelle ;
- [ ] licences et attributions complètes ;
- [ ] aucune dépendance payante/compte obligatoire non autorisé ;
- [ ] une nouvelle session peut reprendre en moins de cinq minutes ;
- [ ] rapport final correspond exactement au build livré.

Tout critère non testé reste `UNVERIFIED`. Aucun critère critique ne peut être reporté tout en qualifiant la passe de terminée.

---

## 18. ÉCHELLE DE RÉDUCTION DU SCOPE

Si coût, temps, performance ou stabilité menacent la livraison, réduire dans cet ordre, après mesure et documentation :

1. propagation avancée du feu et réactions secondaires rares ;
2. station d’entretien des armes ;
3. variantes de recettes/buffs non essentielles ;
4. morale avancée et comportements sociaux secondaires ;
5. wall leap/slide s’ils n’améliorent pas réellement le Flow ;
6. densité facultative de la troisième route, sans supprimer son identité ;
7. Fragments/spécialisations facultatifs ;
8. streaming spatial complexe ;
9. SDFGI, fog volumétrique dense, éclairages secondaires et VFX coûteux ;
10. contenu cosmétique hors parcours de démo.

Ne jamais couper en premier :

- stabilité du projet ;
- mouvement/caméra ;
- combat de base et feedback ;
- Bracelet de Résonance ;
- lois principales eau/métal/charge/terre ;
- quatre étapes pédagogiques du donjon ;
- boss solvable ;
- sauvegarde ;
- accessibilité critique ;
- composition North Star ;
- tests du chemin critique.

La qualité perçue vient d’un petit nombre de systèmes excellents et cohérents, pas d’une accumulation inachevée.

---

## 19. LIVRAISON ET RAPPORT FINAL

### 19.1 Livrables dans le dépôt

- projet jouable mis à jour ;
- prompts conservés dans `docs/` ;
- CLAUDE.md concis ;
- roadmap/status/progress/décisions ;
- gameplay bible et art bible ;
- audit avant amélioration ;
- rapports tests/performance/playtests ;
- known issues ;
- attributions ;
- laboratoires ;
- captures avant/après ;
- vidéo North Star, démo trois minutes et golden path lorsque l’environnement le permet ;
- export cible avec instructions exactes.

### 19.2 Rapport final de Claude Code

Répondre avec :

1. version/commit/build testé ;
2. résumé des changements réellement implémentés ;
3. tableau des gates `PASS/PARTIAL/FAIL/BLOCKED/UNVERIFIED` ;
4. commandes exactes exécutées ;
5. mesures avant/après ;
6. preuves visuelles et chemin pour les ouvrir ;
7. résultats des playtests et décisions prises ;
8. problèmes restants classés par gravité ;
9. éléments coupés avec justification ;
10. procédure de lancement ;
11. prochaine amélioration la plus rentable, sans la prétendre déjà faite.

Ne pas écrire « tout est terminé » si un gate critique n’est pas PASS.

---

## 20. SOURCES PRIORITAIRES À CONSULTER AU MOMENT UTILE

Ces liens forment un cursus de départ. Lire seulement la page pertinente au jalon, consigner la décision et la vérifier dans le projet.

### 20.1 Godot 4.7 — documentation officielle

- Jolt : `https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html`
- migration 4.6→4.7 : `https://docs.godotengine.org/en/4.7/tutorials/migrating/upgrading_to_godot_4.7.html`
- physique : `https://docs.godotengine.org/en/4.7/tutorials/physics/index.html`
- dépannage physique : `https://docs.godotengine.org/en/4.7/tutorials/physics/troubleshooting_physics_issues.html`
- interpolation : `https://docs.godotengine.org/en/4.7/tutorials/physics/interpolation/using_physics_interpolation.html`
- navigation 3D : `https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_introduction_3d.html`
- optimisation navigation : `https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_optimizing_performance.html`
- SpringArm : `https://docs.godotengine.org/en/4.7/tutorials/3d/spring_arm.html`
- animation tree : `https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html`
- optimisation 3D : `https://docs.godotengine.org/en/4.7/tutorials/performance/optimizing_3d_performance.html`
- GPU : `https://docs.godotengine.org/en/4.7/tutorials/performance/gpu_optimization.html`
- profiler : `https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/the_profiler.html`
- moniteurs custom : `https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/custom_performance_monitors.html`
- MultiMesh : `https://docs.godotengine.org/en/4.7/tutorials/performance/using_multimesh.html`
- mesh LOD : `https://docs.godotengine.org/en/4.7/tutorials/3d/mesh_lod.html`
- visibility ranges/HLOD : `https://docs.godotengine.org/en/4.7/tutorials/3d/visibility_ranges.html`
- occlusion : `https://docs.godotengine.org/en/4.7/tutorials/3d/occlusion_culling.html`
- LightmapGI : `https://docs.godotengine.org/en/4.7/tutorials/3d/global_illumination/using_lightmap_gi.html`
- SDFGI : `https://docs.godotengine.org/en/4.7/tutorials/3d/global_illumination/using_sdfgi.html`
- volumetric fog : `https://docs.godotengine.org/en/4.7/tutorials/3d/volumetric_fog.html`
- chargement arrière-plan : `https://docs.godotengine.org/en/4.7/tutorials/io/background_loading.html`
- ressources custom : `https://docs.godotengine.org/en/4.7/tutorials/scripting/resources.html`
- typage statique GDScript : `https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/static_typing.html`
- organisation des scènes : `https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html`
- import/export 3D : `https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/exporting_3d_scenes.html`
- retargeting : `https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html`
- export Web : `https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html`

Vérifier aussi les pages de classes 4.7 correspondant exactement aux nœuds utilisés.

### 20.2 Claude Code — documentation officielle

- overview : `https://docs.anthropic.com/en/docs/claude-code/overview`
- mémoire/CLAUDE.md : `https://docs.anthropic.com/en/docs/claude-code/memory`
- workflows : `https://docs.anthropic.com/en/docs/claude-code/common-workflows`
- sous-agents : `https://docs.anthropic.com/en/docs/claude-code/sub-agents`
- hooks : `https://docs.anthropic.com/en/docs/claude-code/hooks-guide`
- skills : `https://docs.anthropic.com/en/docs/claude-code/skills`

Les hooks servent uniquement à des actions sûres, déterministes et comprises. Ne jamais élargir aveuglément les permissions ou automatiser une opération destructive.

### 20.3 Pipeline et principes de design

- export glTF Blender : `https://docs.blender.org/manual/en/latest/addons/scene_gltf2.html`
- spécification glTF 2.0 : `https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html`
- MDA : `https://aaai.org/papers/ws04-04-001-mda-a-formal-approach-to-game-design-and-game-research/`
- systèmes et conventions de Breath of the Wild, GDC/Nintendo : `https://www.gdcvault.com/play/1024562/Change-and-Constant-Breaking-Conventions`
- flow : `https://www.jenovachen.com/flowingames/Flow_in_games_final.pdf`
- combat God of War : `https://media.gdcvault.com/gdc2019/presentations/Sheth_Mihir_EvolvingCombat.pdf`
- utility AI de Halo Infinite : `https://media.gdcvault.com/GDC%2B2022/Speaker%2BSlides/ThinkingLikePlayersHowHaloInfinitesBotsMakeDecision_ChinDeyerle_Brie.pdf`
- Xbox Accessibility Guidelines, entrées et difficulté : `https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/107` et `https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/108`

Transposer des principes, jamais des assets, noms ou solutions protégées. En cas de contradiction, suivre la documentation de la version installée et les preuves locales.

---

## INSTRUCTION FINALE À CLAUDE CODE

Commence maintenant par l’audit P2-0. N’efface rien. Ne reconstruis pas le projet. Prouve l’état actuel, crée le backlog ordonné, puis implémente la plus petite tranche verticale de la Phase P2-1. Continue jalon par jalon en protégeant la boucle jouable. À chaque fin de session, laisse des preuves, un dépôt cohérent et la prochaine action exacte.

L’objectif n’est pas de produire le plus grand jeu possible. L’objectif est de produire la verticale la plus **agréable à contrôler, intelligente à jouer, cohérente à comprendre, spectaculaire à regarder et fiable à montrer** possible avec les ressources réellement disponibles.

## FIN DU PROMPT 2
