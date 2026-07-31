# PROMPT MAÎTRE PROFESSIONNEL POUR CLAUDE CODE — ACTION-AVENTURE 3D STYLISÉE « EFFET WAHOU » SOUS GODOT 4.7.1

## Instruction d’utilisation

Le présent texte est un cahier des charges indivisible destiné à une IA de développement capable de créer et modifier un projet Godot. Il doit idéalement être fourni avec l’image de référence représentant le héros vu de dos, une vallée lumineuse, un camp ennemi, un pylône cyan et une citadelle électrique monumentale sous un nuage d’orage. La description visuelle intégrée reste néanmoins suffisante si l’image n’est pas accessible.

Toutes les sections sont cumulatives. Une exigence visuelle ne supprime jamais une mécanique. Une mécanique ne justifie jamais un rendu final négligé. Les valeurs chiffrées sont des points de départ à tester et ajuster en conservant l’intention.

Le but est une verticale jouable compacte donnant l’impression d’un grand jeu d’aventure stylisé, pas la promesse irréaliste de fabriquer seul un AAA complet. Toute réussite doit être appuyée par un projet lancé, des captures réelles et des tests reproductibles.

Ce document est la **bible de production exhaustive**. Il ne faut pas le copier intégralement dans un `CLAUDE.md` racine : Claude Code perdrait les règles importantes au milieu du bruit. Le projet doit conserver ce texte dans `docs/MASTER_SPEC.md`, puis utiliser un `CLAUDE.md` court qui l’importe et ne contient que les invariants, commandes et règles quotidiennes.

---

## 0. DIRECTIVE ABSOLUE

Tu es simultanément directeur créatif, game director, lead gameplay programmer Godot, technical artist, environment artist, character artist, animateur gameplay, level designer, combat designer, VFX artist, sound designer, UX/UI designer, testeur QA et responsable optimisation/livraison.

Ta mission n’est pas de rédiger seulement un plan ou quelques extraits de GDScript. Tu dois créer un véritable projet Godot jouable, importer les ressources, corriger les erreurs, lancer les scènes, tester les systèmes, produire des builds et documenter honnêtement ce qui fonctionne.

Cycle obligatoire :

1. Inspecter l’environnement et les fichiers existants.
2. Documenter la version exacte de Godot.
3. Créer ou corriger le projet.
4. Lancer l’import des ressources.
5. Exécuter les tests automatisables.
6. Lancer réellement le jeu.
7. Lire les erreurs et avertissements pertinents.
8. Reproduire et corriger la cause de chaque problème.
9. Rejouer le cas corrigé.
10. Capturer des preuves visuelles depuis le build réel.
11. Ne déclarer « terminé » que ce qui est effectivement jouable.

Si Godot ou le rendu ne peuvent pas être exécutés pour une raison réelle, indiquer précisément le blocage. Ne jamais inventer de capture, vidéo, FPS ou résultat de test.

### 0.1 Priorités en cas de conflit

1. Projet lançable sans erreur bloquante.
2. Boucle complète du début à la victoire.
3. Contrôles agréables, caméra stable, aucun softlock.
4. Composition et atmosphère proches de la référence.
5. Lisibilité du gameplay.
6. Performance stable.
7. Densité et finition artistique.
8. Contenu optionnel.

Ne jamais sacrifier les quatre premières priorités pour agrandir artificiellement le monde.

### 0.2 Règles de vérité

- « Implémenté » : présent et techniquement raccordé.
- « Fonctionnel » : testé dans une scène exécutable.
- « Validé » : conforme aux critères et sans régression connue.
- « Final » : sans placeholder visible sur le chemin critique.
- Un modèle gris animé n’est pas un personnage final.
- Une lumière cyan sur une porte n’est pas un système électrique.
- Un décor peint en fond n’est pas un monde 3D explorable.
- Ne jamais employer l’image de référence comme skybox, matte painting, billboard ou texture de décor.

### 0.3 Système d’exploitation Claude Code obligatoire

Traiter le développement comme une succession de sessions bornées, vérifiables et transmissibles. Une session géante qui tente de réaliser tout le jeu d’un coup est interdite : le contexte se dégrade, les décisions se perdent et un agent finit souvent par annoncer prématurément que le travail est terminé.

Lors de la **première session uniquement**, agir comme agent initialisateur :

1. Inspecter dépôt, branche, changements non commités, outils, versions et restrictions réseau.
2. Ne supprimer, réinitialiser ou écraser aucun travail existant.
3. Conserver ce prompt sous `docs/MASTER_SPEC.md`.
4. Créer un `CLAUDE.md` racine concis, idéalement inférieur à 150 lignes, important `@docs/MASTER_SPEC.md` et listant seulement commandes exactes, architecture stable, règles critiques et définition de « terminé ».
5. Créer les artefacts de continuité ci-dessous avant d’implémenter le contenu.
6. Vérifier qu’une nouvelle session peut comprendre l’état du projet en moins de cinq minutes.
7. Si Git existe, créer des commits petits, cohérents et réversibles ; laisser chaque jalon dans un état propre, testable et prêt à relire.

| Artefact | Rôle obligatoire |
|---|---|
| `docs/MASTER_SPEC.md` | Présent cahier des charges, source de vérité produit |
| `CLAUDE.md` | Invariants et commandes réellement utiles à chaque session |
| `docs/ROADMAP.md` | Phases, dépendances, gates, ordre et critère de sortie |
| `docs/STATUS.md` | État par fonctionnalité avec preuve et dernier test |
| `docs/PROGRESS.md` | Journal chronologique et handoff de la prochaine session |
| `docs/DECISIONS.md` | Décisions d’architecture/art/gameplay et alternatives rejetées |
| `docs/RESEARCH_LEDGER.md` | Questions, sources, expériences, mesures et apprentissages |
| `docs/KNOWN_ISSUES.md` | Bugs reproduits, sévérité, contournement et propriétaire |
| `docs/TEST_REPORT.md` | Résultats automatisés/manuels, environnement et commandes |
| `docs/PERFORMANCE.md` | Mesures CPU/GPU/mémoire, scènes et corrections |
| `docs/ART_BIBLE.md` | Langage visuel, palette, formes, matériaux et captures |
| `ATTRIBUTIONS.md` | Provenance et licence de chaque ressource externe |
| `evidence/` | Captures, vidéos, profils et logs datés provenant du build |

Employer les fonctions Claude Code avec parcimonie :

- `.claude/rules/` pour les règles ciblées par chemin, par exemple GDScript, shaders, tests et assets ;
- `.claude/skills/` seulement pour des procédures répétables comme capturer une scène, profiler un jalon ou auditer une ressource ;
- `.claude/agents/` pour des spécialistes à contexte séparé ;
- `.claude/settings.json` et hooks uniquement si les commandes sont sûres, déterministes et comprises par l’équipe ;
- ne jamais contourner une permission, élargir aveuglément les commandes autorisées ou automatiser une opération destructive.

### 0.4 Contrat de chaque session de production

Chaque session prend **un jalon borné ou un seul bug complexe**, pas une liste infinie. Elle suit ce cycle :

1. **Orienter** : lire `CLAUDE.md`, la section pertinente du présent document, `STATUS`, `PROGRESS`, `KNOWN_ISSUES` et les derniers résultats.
2. **Explorer** : inspecter le code, les scènes et les ressources concernés avant de proposer une modification ; identifier les fichiers réellement maîtres.
3. **Formuler** : écrire le résultat attendu, les non-objectifs, le risque principal, le gate et les commandes de preuve.
4. **Planifier** : produire un plan court, ordonné et révisable ; résoudre les inconnues dangereuses avant les gros changements.
5. **Implémenter** : effectuer le plus petit changement cohérent qui traverse réellement le système.
6. **Vérifier** : importer, parser, tester, lancer, reproduire en jeu, capturer et profiler selon le domaine.
7. **Réviser** : faire rechercher les contre-exemples par un contexte frais ; corriger ou consigner tout échec.
8. **Transmettre** : mettre à jour `STATUS`, `PROGRESS`, décisions, problèmes et preuves ; indiquer exactement la prochaine action.

Au début, afficher : jalon actuel, gate visé, état du dépôt, inconnues, fichiers concernés et commandes de validation. À la fin, afficher : changement réel, tests exécutés, preuves, résultats mesurés, limites et prochain jalon. Ne jamais répéter dix fois une correction qui échoue : après deux tentatives similaires, arrêter, revenir à la cause, réduire le cas et changer d’hypothèse.

### 0.5 Protocole de recherche et d’apprentissage continu

« Apprendre » signifie transformer une information fiable en **décision testée, mesure, règle, outil ou test reproductible**. Une longue liste de liens non appliquée n’est pas un apprentissage.

Pour toute API incertaine, optimisation, technique graphique, import 3D, comportement physique ou choix d’architecture :

1. Écrire une question précise et ce qui changera selon la réponse.
2. Confirmer la version réellement installée de Godot et des outils DCC.
3. Consulter en priorité la documentation officielle Godot correspondant à cette version, puis les classes/API, notes de version, démos officielles et code source si nécessaire.
4. Pour Blender, glTF, Git LFS et Claude Code, consulter leurs documentations officielles. Pour l’art, le game feel et la production, utiliser des présentations de développeurs/GDC et distinguer principe transférable de recette propre à un autre moteur.
5. Recouper les affirmations à fort impact ; ne pas prendre un billet SEO, une vidéo isolée ou une réponse ancienne comme vérité si une source primaire existe.
6. Consigner dans `RESEARCH_LEDGER.md` : date, versions, question, URLs, constat, hypothèses, mini-expérience, mesures, décision, limites et date de réévaluation.
7. Créer sous `experiments/` ou dans une scène laboratoire le plus petit test capable de départager les options.
8. Comparer au moins deux approches si le coût, la qualité ou la stabilité sont réellement incertains.
9. Adopter la solution seulement après preuve sur le renderer et le matériel cibles ; archiver ou supprimer proprement l’expérience devenue inutile.
10. Convertir l’apprentissage durable en test, commentaire de justification, entrée de décision ou procédure réutilisable.

Règles strictes :

- ne jamais halluciner une méthode, propriété ou capacité de Godot ;
- ne jamais utiliser silencieusement une documentation d’une autre version ;
- si Internet est indisponible, marquer l’affirmation `À vérifier` et construire un test local au lieu d’inventer ;
- ne pas coller du code externe sans comprendre sa licence et son adaptation ;
- ne pas installer un addon parce qu’une page le recommande : vérifier maintenance, version Godot, licence, surface de code, dépendances et plan de retrait, puis épingler une version ;
- arrêter la recherche quand la décision est suffisamment sourcée et qu’une expérience peut la valider ; l’exploration sans critère d’arrêt ne remplace pas le développement.

### 0.6 Sous-agents et revue contradictoire

Si Claude Code permet les sous-agents, les utiliser pour protéger le contexte principal, jamais pour multiplier des modifications incohérentes :

- `godot-researcher` : lecture seule, vérifie API/version et renvoie URLs + implications ;
- `visual-director` : compare captures, valeurs, silhouettes, hiérarchie, répétition et cohérence ;
- `game-feel-reviewer` : mesure latence, fenêtres d’action, feedback, caméra et lisibilité ;
- `performance-profiler` : établit protocole, mesures et cause dominante sans optimiser au hasard ;
- `adversarial-qa` : reçoit la spécification, le diff et les preuves dans un contexte frais et tente de démontrer que le gate échoue.

Un sous-agent enquête sur un périmètre précis et retourne une synthèse courte avec preuves. Deux agents ne modifient jamais simultanément les mêmes scènes, ressources d’import ou fichiers binaires. L’agent principal reste responsable de l’intégration et relance tous les tests. Une approbation de l’auteur de la fonctionnalité ne remplace jamais la revue contradictoire.

### 0.7 Matrice de preuve et interdiction de validation prématurée

| Affirmation | Preuve minimale |
|---|---|
| « Le code compile/parse » | commande exacte, code retour et zéro erreur pertinente |
| « La scène fonctionne » | lancement réel, scénario reproduit et log/capture du build |
| « Le gameplay est bon » | test contrôlé, métriques de réponse et essai humain documenté |
| « Le rendu correspond » | captures fixes reproductibles, comparaison North Star et score détaillé |
| « C’est performant » | profil CPU/GPU/mémoire sur matériel, build, preset et durée indiqués |
| « Le bug est corrigé » | test qui échouait avant, réussit après et recherche de régression |
| « C’est final » | chemin critique sans placeholder, gates verts et revue indépendante |

Avant chaque Gate, `adversarial-qa` ou une seconde passe à contexte frais doit examiner les critères un par un, jouer le scénario malheureux, vérifier les preuves et retourner `PASS`, `FAIL` ou `BLOQUÉ`. Tout critère non testé est `NON VÉRIFIÉ`, jamais implicitement réussi.

### 0.8 Démonstration prioritaire « impressionner mon frère »

Optimiser une **démo sûre de trois minutes** avant de disperser la finition :

1. `0:00–0:12` : reveal de la vallée, héros de dos, herbe au vent, citadelle et éclair synchronisé au tonnerre.
2. `0:12–0:50` : contrôle immédiat, course fluide dans l’herbe, saut/mantle et arrivée sur un point de vue.
3. `0:50–1:45` : approche du camp, tir à l’arc, esquive, combo, hit reaction et rupture d’un élément physique.
4. `1:45–2:25` : propagation électrique spectaculaire dans une micro-énigme compréhensible sans explication.
5. `2:25–3:00` : transition vers un extrait de boss, mise à la terre d’un pylône, attaque majeure et fin sur un plan fort.

Ce parcours possède un mode `DemoRoute` non-triché qui prépare seulement une sauvegarde légitime et évite l’errance. Il ne doit montrer aucun placeholder, chargement visible, compilation shader, pop de LOD évident, tutoriel bavard, bug de caméra ou chute de fluidité répétitive. Les soixante premières secondes reçoivent le plus haut niveau de polish, car elles établissent immédiatement la qualité perçue.

---

## 1. MISSION ET EXPÉRIENCE CIBLE

Créer une action-aventure originale en troisième personne fondée sur :

- liberté de déplacement 3D ;
- déplacement relatif à la caméra ;
- exploration horizontale et verticale ;
- course, sprint, saut et escalade ;
- endurance commune à plusieurs actions ;
- objets physiques participant aux énigmes ;
- combat en temps réel lisible ;
- arc et projectiles physiques ;
- coffres, armes récupérables et durabilité ;
- récolte, cuisine et préparation ;
- cinq familles d’ennemis réellement différentes ;
- donjon électrique reposant sur un graphe de connexions ;
- boss final en trois phases ;
- sauvegarde et reprise ;
- boucle de 25 à 40 minutes lors d’une première partie.

Séquence :

1. Une courte ouverture révèle la vallée et la citadelle sous l’orage.
2. Le joueur prend le contrôle sur une colline d’herbe et de fleurs.
3. Il apprend à marcher, courir, sauter, sprinter et grimper.
4. Il récolte des ingrédients.
5. Il repère camp, pylône et donjon.
6. Il trouve un coffre et une arme.
7. Il affronte un groupe d’ennemis.
8. Il cuisine au feu de camp.
9. Il traverse la vallée par au moins deux itinéraires.
10. Il entre dans le donjon électrique.
11. Il résout quatre énigmes complémentaires.
12. Il prépare armes et plat de résistance électrique.
13. Il vainc le Gardien de l’Orage.
14. Il reçoit la récompense et atteint l’écran de victoire.

Boucle centrale : **Observer → choisir → explorer → récolter → combattre → s’équiper → résoudre → se préparer → vaincre.**

---

## 2. ORIGINALITÉ ET PROPRIÉTÉ INTELLECTUELLE

L’image jointe sert uniquement de référence de cadrage, échelle, hiérarchie des plans, palette, lumière, profondeur atmosphérique, densité végétale et sensation d’aventure.

Ne copier aucun contenu appartenant à Nintendo ou à une autre œuvre : personnages, costumes, silhouettes, modèles, textures, rigs, animations, carte, salle, interface, symbole, musique, son, dialogue ou asset extrait.

Les termes « Bokoblin » et « Lynel » sont uniquement des noms de travail hérités du brief. Dans le projet :

- utiliser `raider_red`, `raider_blue`, `raider_black`, `ravine_troll`, `centaur_hunter` ;
- stocker les noms affichés dans des ressources/localisations ;
- prévoir des noms originaux par défaut ;
- créer visages, silhouettes, équipements et comportements visuels originaux.

Nom de travail recommandé : **Éclats d’Orage**. Monde : **Vallée de Néris**. Donjon : **Citadelle de l’Œil-Tempête**. Tous les noms restent pilotés par données.

Tout asset externe doit être original, généré, domaine public ou sous licence redistribuable. Tenir `ATTRIBUTIONS.md` avec source, auteur, licence et modifications. Aucun asset ne doit exiger le compte personnel du joueur.

---

## 3. NORTH STAR VISUELLE — RECONSTRUIRE L’EFFET DE L’IMAGE

### 3.1 Intention

Créer une illustration 3D stylisée, painterly et haut de gamme, sans photoréalisme générique. L’image doit provoquer en moins de trois secondes : envie de descendre dans la vallée, compréhension du but lointain, curiosité pour le camp/pylône, sensation de monde vaste et contraste nature accueillante/menace électrique.

Associer formes stylisées solides, géométrie riche au premier plan, textures à larges masses, PBR contrôlé, lumière dorée, ombres froides, brume bleutée, végétation animée et énergie cyan à cœur blanc. Éviter cel-shading plat, plastique, gros contours noirs et assemblage d’assets réalistes incohérents.

### 3.2 Vue d’ouverture obligatoire

Créer `VistaCamera_Hero01`. En 16:9 :

- héros au tiers inférieur, légèrement à gauche du centre, 32–40 % de la hauteur ;
- caméra environ 4,2 m derrière, à 1,7 m au-dessus des pieds ;
- FOV horizontal proche de 65–72° ;
- pente herbeuse/fleurs sur les 22–30 % inférieurs ;
- camp visible au milieu droit, à 70–110 m ;
- pylône techno-magique dans le tiers droit, à 140–190 m ;
- rivière/lac formant un ruban guidant vers le centre ;
- citadelle monumentale au centre, à 300–420 m ;
- falaises encadrant les côtés ;
- nuage d’orage local au-dessus de la citadelle ;
- éclairs cyan entre nuage et monument ;
- soleil chaud hors champ en haut à gauche ;
- premier plan chaud/contrasté, arrière-plan clair, bleu et moins saturé.

Trois plans lisibles :

1. Premier plan : héros, herbe longue, fleurs, rochers proches.
2. Plan moyen : camp, sentier, arbres, eau, ruines, pylône, menaces.
3. Arrière-plan : citadelle, falaises, montagnes, nuage, éclairs.

### 3.3 Implantation indicative

1 unité = 1 m ; Y vertical ; terrain environ 512 × 512 m :

- spawn `(0, 24, 170)`, regard vers `-Z` ;
- camp `(45, 6, 65)` ;
- pylône `(115, 18, -25)` ;
- rivière en S autour de `Z = 10` ;
- falaise d’apprentissage à l’ouest, `X = -80` à `-145` ;
- forêt claire sud-est du centre ;
- donjon `(0, 34, -210)` ;
- montagnes non jouables à 550–1 200 m.

Les coordonnées peuvent évoluer, mais la relation héros → camp → pylône → citadelle reste immédiatement lisible.

### 3.4 Palette ancre

| Usage | Couleur |
|---|---:|
| Soleil | `#FFD68A` |
| Ciel pastel | `#A9D4EA` |
| Brume | `#AFC8D3` |
| Herbe moyenne | `#5D8F3D` |
| Herbe éclairée | `#B2C85A` |
| Roche ocre | `#9B6842` |
| Ombre froide | `#4C5B75` |
| Bois/cuir | `#684028` |
| Tissu turquoise | `#168F9B` |
| Électricité | `#22D9EC` |
| Cœur électrique | `#ECFFFF` |
| UI or pâle | `#D8B36A` |

Ratio visé : 60 % verts/ocres, 30 % ciel/brume/eau, moins de 10 % d’accents très saturés. Le cyan reste rare.

### 3.5 WOW Gate

Noter la capture `VistaCamera_Hero01` sur 100 :

| Domaine | Points |
|---|---:|
| Composition des masses | 25 |
| Lumière et chaud/froid | 20 |
| Profondeur/échelle | 15 |
| Végétation | 15 |
| Matériaux painterly | 10 |
| Lisibilité héros/camp/pylône/citadelle | 10 |
| Nuage/éclairs/énergie | 5 |

Validation à partir de 85/100, aucun domaine à zéro. Produire des captures avant/après chaque passe majeure.

---

## 4. PORTÉE DE LA VERSION 0.1

### 4.1 Obligatoire

- vallée 500 × 500 m, trois hauteurs exploitables ;
- vue d’ouverture proche de la référence ;
- camp de départ et feu de cuisine ;
- prairie, bosquet, forêt, rivière, falaises et ruines ;
- grande paroi escaladable ;
- deux routes et raccourcis verticaux ;
- pylône ancien ;
- huit coffres minimum ;
- sept ingrédients ;
- six armes ;
- cinq familles d’ennemis ;
- camp ennemi ;
- chasseur centaure facultatif ;
- entrée monumentale, quatre énigmes, salle centrale, antichambre, arène ;
- boss trois phases ;
- conclusion et victoire.

### 4.2 Hors périmètre avant validation

Multijoueur, monde infini, villes, montures, parapente, construction, économie complexe, longues quêtes secondaires, dialogues à branches, cycle jour/nuit complet, météo globale, crafting hors cuisine et monde de plusieurs kilomètres.

Le nuage d’orage scripté et le vent local ne constituent pas un système météo complet.

### 4.3 Densité

Le joueur voit ou rencontre un élément intéressant toutes les 15 à 30 s : ingrédient, relief, chemin, ruine, ennemi, coffre, point de vue, physique ou indice. Conserver des respirations autour de l’eau et des panoramas.

---

## 5. BASELINE TECHNIQUE GODOT

### 5.1 Version et langage

- **Godot 4.7.1-stable**, édition standard sans .NET ;
- GDScript typé ;
- jamais 4.8 dev/beta/RC ;
- si version stable ultérieure imposée, documenter et valider la migration ;
- consigner `Engine.get_version_info()` dans `docs/BUILD_ENVIRONMENT.md` ;
- aucune API expérimentale sans fallback justifié.

### 5.2 Plateformes/rendu

Natif principal : Forward+, macOS Apple Silicon prioritaire, Windows/Linux 64 bits, 1080p gameplay, 1440p capture, 60 FPS sur matériel recommandé, presets Medium/High/Cinematic.

Web optionnel : Compatibility/WebGL 2.0, build séparé, 900p à 30–60 FPS, sans volumetric fog, SDFGI, SSIL, SSR, TAA, FSR2, decals ni compute. Utiliser LightmapGI pré-calculé, fog classique, matériaux/ombres/végétation allégés. Ne jamais promettre une identité parfaite entre Web et natif.

### 5.3 Physique

- Jolt Physics intégré ;
- tick 60 Hz ;
- interpolation si stable ;
- pas de thread physique expérimental ;
- capsules/convexes pour mobiles ;
- concave uniquement statique ;
- CCD pour projectiles rapides ;
- masses/vitesses plafonnées.

### 5.4 Code

- typage explicite et `class_name` pour les types réutilisables ;
- composition plutôt qu’héritage profond ;
- signaux typés ;
- `@onready`, NodePath, groupes et injection au lieu de chaînes `get_node()` fragiles ;
- aucune dépendance circulaire ;
- équilibrage hors scènes de niveau ;
- définitions en `Resource`, état mutable séparé ;
- jamais de durabilité stockée dans une ressource partagée ;
- protéger les `await` contre les nœuds supprimés ;
- déconnecter les signaux dynamiques ;
- aucune boucle monde entière par frame ;
- aucune allocation massive par frame ;
- erreurs de parsing/références cassées bloquantes.

### 5.5 Arborescence

```text
res://
  project.godot
  addons/
  assets/
    characters/{hero,enemies,boss}/
    environment/{valley,dungeon,foliage,rocks,props,water}/
    animations/
    audio/{ambience,combat,ui,music}/
    textures/
    fonts/
  scenes/
    boot/
    player/
    enemies/
    boss/
    world/{valley,chunks}/
    dungeon/rooms/
    interactables/
    ui/
    tests/
    cinematics/
  scripts/
    core/
    components/
    player/
    combat/
    inventory/
    interaction/
    ai/
    electricity/
    world/
    ui/
    save/
    tools/
  resources/{weapons,ingredients,meals,enemies,loot_tables,status_effects,tuning}/
  materials/{base,instances}/
  shaders/{characters,environment,foliage,water,sky,vfx,ui}/
  tests/{unit,integration,playthrough}/
  docs/
  builds/{macos,windows,linux,web}/
```

### 5.6 Autoloads

- `GameState` : flux et difficulté ;
- `SaveSystem` : schéma, migrations, écriture atomique ;
- `AudioManager` : bus, musique, pools ;
- `SceneFlow` : transitions/chargements ;
- `EventBus` seulement pour événements réellement globaux.

Ne pas dupliquer des références fragiles au joueur ou aux ennemis dans les autoloads.

### 5.7 Groupes et collisions

Groupes : `player`, `enemies`, `damageable`, `interactable`, `climbable`, `unclimbable`, `conductive`, `insulated`, `electric_sources`, `electric_receivers`, `saveable`, `world_chunks`, `lock_on_targets`, `water`, `danger`, `respawnable_essential`, `camera_fade_objects`.

Couches nommées : World Static, Player, Enemy, Player Hitbox, Enemy Hitbox, Hurtbox, Projectile, Physics Prop, Interactable, Climb Probe, Conductive, Water/Danger, Navigation Obstacle, Camera Collision. Chaque masque reste minimal.

### 5.8 Composants

Créer `HealthComponent`, `StaminaComponent`, `AttributeComponent`, `HitboxComponent`, `HurtboxComponent`, `StatusEffectComponent`, `InteractionComponent`, `InventoryComponent`, `EquipmentComponent`, `DurabilityComponent`, `LootComponent`, `PerceptionComponent`, `TargetableComponent`, `ClimbingComponent`, `LedgeDetectorComponent`, `ElectricNodeComponent`, `ConductivityComponent`, `PersistentStateComponent`, `AudioSurfaceComponent`.

API courte, signaux typés, aucune connaissance inutile de l’UI.

### 5.9 Ressources de données

Créer `WeaponDefinition`, `AttackDefinition`, `IngredientDefinition`, `MealDefinition`, `RecipeRuleDefinition`, `EnemyDefinition`, `LootTableDefinition`, `StatusEffectDefinition`, `AudioSetDefinition`, `GraphicsPresetDefinition`, `WorldObjectDefinition`.

Exemple de définition immuable :

```gdscript
class_name WeaponDefinition
extends Resource

@export var id: StringName
@export var display_name_key: StringName
@export var weapon_type: StringName
@export var base_damage: float
@export var attack_speed: float
@export var reach_m: float
@export var max_durability: int
@export var conductivity: float
@export var rarity: int
@export var mesh_scene: PackedScene
@export var icon: Texture2D
@export var attack_set: Array[AttackDefinition]
```

L’instance mutable contient `instance_id`, `definition_id`, `current_durability` et modificateurs. Deux exemplaires ne partagent jamais leur durabilité.

---

## 6. ARCHITECTURE DES SCÈNES

### 6.1 Flux

`Boot → MainMenu → Valley → Dungeon → BossArena → Victory`.

`Boot.tscn` contient `SceneFlow`, `FadeLayer`, `LoadingUI`, et un debug overlay désactivé dans le build final. Les transitions sauvegardent, coupent l’input, chargent proprement et ne laissent aucun ancien nœud actif.

### 6.2 Joueur

```text
Player (CharacterBody3D)
├── CollisionShape3D
├── VisualRoot
│   ├── HeroModel/Skeleton3D/AnimationTree
│   ├── WeaponSocket (BoneAttachment3D)
│   └── BowSocket (BoneAttachment3D)
├── StateMachine
├── Components
├── Probes/{Ground,Step,WallHead,WallChest,WallFoot,LedgeClearance}
├── CameraRig/YawPivot/PitchPivot/SpringArm3D/Camera3D
├── Hurtbox
├── AimOrigin
└── Audio
```

### 6.3 Ennemi

```text
Enemy (CharacterBody3D)
├── VisualRoot
├── CollisionShape3D
├── NavigationAgent3D
├── StateMachine
├── PerceptionComponent
├── HealthComponent
├── StatusEffectComponent
├── TargetableComponent
├── Hurtbox
├── AttackOrigin
├── TerritoryOrigin
└── Audio
```

### 6.4 Persistant

Chaque coffre, interrupteur, porte, ingrédient important et objet d’énigme possède identifiant stable éditable, interaction, composant persistant, application idempotente de l’état et fonctionnement correct quel que soit l’ordre entre chargement et `_ready()`.

## 7. DIRECTION ARTISTIQUE ET PIPELINE DE RENDU

### 7.1 Style général

Créer une 3D stylisée painterly haut de gamme fondée sur silhouettes fortes, proportions semi-réalistes héroïques, plans colorés larges, arêtes sculptées, PBR modéré, deux ou trois grandes zones d’ombre, rim light discret, variation macro, ombres bleues/violettes et hautes lumières chaudes.

Éviter : gros contours noirs, matériaux gris génériques, rendu plastique, normal maps agressives, textures photographiques brutes, bloom brûlé, saturation uniforme, netteté excessive, feuillage opaque, lumière plate de midi, exposition qui pompe et profondeur de champ en gameplay.

### 7.2 Hiérarchie artistique

Prioriser : héros/animations → vue d’ouverture/herbe proche → citadelle/pylône/orage → camp/feu → entrée et circuits → boss/arène → routes secondaires → fonds. Un rocher à 300 m ne reçoit pas le budget d’un coffre à 1 m.

Créer `docs/ART_BIBLE.md` : palette, formes par faction, matériaux, roughness, densité selon distance, épaisseurs de silhouette, ombres, émission cyan, proportions et captures réelles.

### 7.3 Kit d’environnement minimal

- 12 rochers ; 6 falaises ; 4 talus ;
- 5 arbres majeurs ; 6 buissons ; 8 herbes ; 5 fleurs ;
- 8 modules de ruine ; 12 modules de donjon ;
- 6 câbles/rails ; 4 connecteurs ; 3 portes ; 4 pylônes ;
- 10 props de camp.

Varier rotation, échelle, teinte, asymétrie et usure. Une simple rotation de 90° ne suffit pas à cacher la répétition.

### 7.4 Terrain

Autorisé : meshes sculptés par chunks, `ArrayMesh` déterministe, Blender → glTF si disponible, ou addon open source Godot 4.7.1 audité/épinglé. Aucun service payant obligatoire.

Exigences : chunks 64–128 m, collisions simplifiées, blending sans couture, vertex colors/splat pour herbe-terre-roche-humidité, triplanar sur fortes pentes, chemin lisible, rebords compatibles escalade, limites par relief crédible et aucun piège hors monde.

### 7.5 Végétation

Employer `MultiMeshInstance3D`, partitionné en cellules de 24–48 m. Ne jamais regrouper toute la vallée dans un MultiMesh unique.

Scatter déterministe selon pente, altitude, humidité, eau, sol, chemins, exclusions, combat et vue d’ouverture. Touffes regroupées plutôt qu’uniformes ; fleurs blanches/jaunes/bleues ; chemins moins denses ; humide près de l’eau ; végétation rare près des dangers électriques.

Shader de vent : balancement basse fréquence + mouvement fin des pointes, amplitude par vertex color, phase par instance custom data, direction `WindManager`, interaction locale dans un rayon 1,2–1,8 m, fallback Web réduit. Aucun recalcul CPU de toute la prairie.

### 7.6 Roches, eau et ciel

Roches : strates larges, arêtes chaudes, creux froids, mousse selon humidité/orientation, triplanar/UV propres, vertex painting et LOD préservant la silhouette.

Eau : deux normales animées, couleur par profondeur, transparence contrôlée, légère réfraction native si mesurée, mousse d’intersection, reflets stables, ruban turquoise guidant vers le donjon. Web : version simplifiée sans dépendance écran.

Godot n’est pas supposé posséder les nuages volumétriques d’Unreal. Utiliser sky physique/custom, couches de nuages par dômes/cartes/meshes, nuage local multi-couches au-dessus de la citadelle, raymarch seulement en Cinematic si mesuré, fallback Web par cartes.

Éclair : tracé irrégulier, 2–4 branches, cœur blanc/halo cyan, flash nuageux, lumière locale, exposition très légèrement modulée, tonnerre retardé, cadence irrégulière, un éclair majeur simultané dans la vue d’ouverture.

### 7.7 Lumière extérieure

Utiliser `DirectionalLight3D`, PSSM quatre splits sur High si possible, `WorldEnvironment`, sky, fog distance/height, volumetric fog Forward+ à portée limitée, `FogVolume` local, SSAO modéré, SSIL subtil, `ReflectionProbe`, exposition manuelle, tonemapping, color grading et debanding.

Fin d’après-midi fixe : soleil ouest/gauche, angle 18–28°, ombres longues lisibles. Aucun visage de combat noir.

GI : évaluer SDFGI demi-résolution pour High/Cinematic ; LightmapGI pour zones statiques, Medium/Web et donjon ; probes dynamiques ; ne pas empiler sans mesure. Les noyaux cyan synchronisent émission et vraies lumières locales.

Bloom faible, seuil élevé ; motion blur désactivé ; DOF uniquement cinématique. Fog volumétrique proche + fog classique lointain afin d’éviter une coupure visible.

### 7.8 Donjon

Base ocre/bronze sombre, ambre faible, énergie cyan directionnelle, dangers plus pulsés, fog local, sources motivées, exposition stable extérieur/intérieur, aucun couloir noir et trajet du courant visible à distance.

### 7.9 Shaders

Créer : `SH_CharacterPainterly`, `SH_RockTriplanar`, `SH_GroundBlend`, `SH_FoliageWind`, `SH_TreeCanopy`, `SH_WaterStylized`, `SH_MetalPatina`, `SH_EnergyCyan`, `SH_ElectrifiedSurface`, `SH_CloudLayer`, `SH_DistanceImpostor`, `SH_CameraFadeDither`.

Painterly : ramp diffuse 2–3 niveaux adoucis, ombre froide, lumière chaude, rim, variation macro, AO, roughness, normal modérée, réglages distincts peau/métal/pierre et fallback Web.

Énergie : cœur blanc, bord cyan, fresnel, pulsation organique, scrolling UV, masque de propagation 0–1, flash d’activation et synchronisation code/audio/lumière.

### 7.10 Budgets artistiques et LOD

| Asset | Triangles LOD0 | Texture max |
|---|---:|---:|
| Héros | 40k–70k | 2K ; 4K justifié |
| Boss | 100k–160k | 4K |
| Centaure | 55k–90k | 2K |
| Ennemi standard | 22k–45k | 2K |
| Grand arbre | 8k–18k | atlas 2K |
| Gros rocher | 3k–12k | atlas 2K |
| Prop | 0,5k–5k | 512–1K |

LOD1 ≈ 50–60 %, LOD2 ≈ 20–30 %, LOD3/impostor si nécessaire ; collisions convexes simples ; mipmaps ; compression VRAM ; transitions invisibles dans la bande 30–80 m. Utiliser LOD d’import, visibility ranges et HLOD manuels.

### 7.11 Héros

Silhouette originale reconnaissable de dos : cheveux sombres sculptés, bande/cape turquoise, tunique ivoire/ocre, cuir brun, arc/carquois, arme attachée, sacoches, chaussures d’escalade, proportions athlétiques, usure légère. Le turquoise relie visuellement le héros à la citadelle. Aucun accessoire iconique d’une licence existante.

### 7.12 Animation

Utiliser `AnimationPlayer`, `AnimationTree`, state machine, blend spaces, root motion, `SkeletonModifier3D`, `TwoBoneIK3D`, `FABRIK3D`, `LookAtModifier3D`, contraintes et retargeting.

Animations : idles, départs/arrêts/pivots, marche/course/sprint, virages, saut/chute/réceptions, épuisement, escalade quatre directions/repos/saut/mantle, combos et lourdes par arme, esquives, arc, interaction/ramassage/coffre/cuisine, impacts directionnels, stagger, électrocution, mort.

Foot IK, hand IK, pentes, aim offset, look-at limité, secondary motion, aucun clipping majeur/foot sliding. Transitions locomotion 0,10–0,22 s.

Créer `ActionAlignmentComponent`, substitut ciblé au motion warping : capture transform validée, interpolation de racine, root motion, correction plafonnée, annulation si capsule bloquée, verrouillage temporaire. L’utiliser pour mantle, coffre, cuisine et pylône.

### 7.13 VFX

`GPUParticles3D`, shaders, meshes, courbes, decals et lumières pour électricité, étincelles, poussière, impacts, feuilles/pollen, feu/fumée/braises, coffres, cuisine, buffs, projectiles, rupture, onde de choc et boss.

Chaque action importante combine au moins deux retours. Aucun VFX ne masque le joueur plus de 0,35 s. Électricité : cœur blanc fin, halo cyan, branches, résidus, propagation et lumière ; aucun ruban opaque géant.

### 7.14 Réalité de production artistique

La qualité perçue dépend d’abord de la composition, des silhouettes, de l’éclairage, des animations et de la cohérence des assets, pas du nombre d’effets cochés dans `WorldEnvironment`. Aucun shader ne transforme automatiquement une géométrie faible, une animation raide ou une collection d’assets incompatibles en direction artistique haut de gamme.

Par conséquent :

- valider un petit décor héroïque avant de construire toute la vallée ;
- privilégier cinq assets excellents et réutilisables à cinquante assets médiocres ;
- ne jamais appeler `final` un personnage gris, un rig provisoire ou une animation générique mal retargetée ;
- si les outils de modélisation, les compétences, le temps ou les assets légalement utilisables manquent, réduire le périmètre visible et déclarer honnêtement le blocage artistique ;
- les images générées peuvent servir de concept, moodboard ou base de travail autorisée, jamais de fausse capture du moteur ;
- ne pas dépendre d’un service payant, d’un compte personnel, d’un asset volé ou d’une ressource non redistribuable pour lancer le projet.

### 7.15 Usine d’assets Blender → glTF 2.0 → Godot

Utiliser glTF 2.0, de préférence `.glb`, comme format d’échange 3D principal recommandé par Godot. L’import direct `.blend` peut accélérer l’itération locale, mais il appelle Blender comme convertisseur et crée une dépendance de poste : les livrables reproductibles doivent donc posséder des `.glb` exportés et validés.

Arborescence recommandée :

```text
source_assets/
  blender/characters environment props creatures
  textures_source/ audio_source/ concepts/
assets/
  characters environment props creatures animations materials textures audio
tools/blender/
  export_gltf.py validate_scene.py
docs/assets/
  ASSET_MANIFEST.csv IMPORT_RULES.md
```

Conventions :

- unités métriques, échelle réelle cohérente avec `1 unité Godot = 1 m` ;
- appliquer proprement rotation/échelle avant export sans détruire les besoins du rig ;
- origine et pivot intentionnels, bas de l’objet au sol, axes vérifiés par un test d’import ;
- noms stables et lisibles : `SM_` statique, `SK_` skinné, `MAT_`, `T_`, `AN_`, `COL_`, `SOCKET_`, suffixes `_LOD0..3` ;
- collections exportables par asset, aucune caméra/lumière/helper exporté par accident ;
- normales personnalisées, tangentes, UV0 propres, UV1/UV2 si lightmap requise, densité texel documentée ;
- moins de slots matériaux, atlases cohérents et trimsheets pour architecture répétée ;
- armature propre, poids normalisés, maximum d’influences compatible avec la cible, noms d’os stables ;
- animations nommées, durée/fps/loop/root motion documentés, aucune action de test exportée ;
- niveaux de LOD et collisions simplifiées générés dans la source ou selon une procédure Godot testée ;
- aucune texture absolue manquante, aucun fichier dépendant d’un chemin privé.

Le script d’export Blender doit être exécutable en ligne de commande si Blender est installé, définir explicitement le preset glTF, exporter les collections désignées et produire un log. Ne jamais supposer les options d’une version différente de Blender : interroger la version installée et la documentation de son exporter.

Après export, valider automatiquement si possible :

- ouverture du `.glb` et absence d’erreur ;
- dimensions, orientation, position du sol et pivot ;
- nombre de meshes, triangles, matériaux, textures, bones et animations ;
- noms/LOD/collisions attendus ;
- textures présentes, dimensions/power-of-two quand utile, canaux et espace colorimétrique corrects ;
- animation de boucle sans saut, pose de référence et déformations extrêmes ;
- import headless Godot sans erreur ni ressource rose ;
- scène d’aperçu générée montrant LOD0/1/2, collision, skeleton et matériaux.

Ne jamais modifier à la main le cache `.godot/imported`. Versionner les sources critiques, les exports nécessaires, scripts, presets et manifests. Si le dépôt distant prend en charge Git LFS, suivre via `.gitattributes` les gros binaires tels que `.blend`, `.glb`, textures maîtres, audio et vidéo ; vérifier que LFS est réellement disponible avant d’en dépendre.

`ASSET_MANIFEST.csv` contient au minimum : ID, type, propriétaire/auteur, source, licence, fichier maître, export, version, échelle, LOD, collision, matériaux, textures, rig, animations, statut import, budget, date et notes. Une ressource externe sans licence claire n’entre pas dans le build.

### 7.16 Laboratoires de look-dev obligatoires

Créer des scènes isolées, rapides à charger et capturables :

| Scène | Question à trancher |
|---|---|
| `StyleLab.tscn` | Les formes, valeurs, palette et matériaux appartiennent-ils au même monde ? |
| `HeroShotLab.tscn` | La North Star fonctionne-t-elle dans 80 × 80 m avant le monde complet ? |
| `LightingLab.tscn` | Peau, tissu, métal, roche, feuillage et énergie restent-ils lisibles ? |
| `FoliageLab.tscn` | Densité, vent, interaction, LOD, ombres et overdraw tiennent-ils le budget ? |
| `WaterLab.tscn` | Profondeur, rive, mousse, reflets et fallback sont-ils stables ? |
| `AnimationLab.tscn` | Boucles, pivots, pentes, IK, mains, impacts et retargeting sont-ils propres ? |
| `CombatLab.tscn` | Silhouettes, télégraphes, hit reactions, VFX et caméra restent-ils lisibles ? |
| `PerformanceLab.tscn` | Chaque effet possède-t-il un coût mesuré et un niveau de qualité ? |

Construire d’abord `HeroShotLab` : un héros, 20–30 m d’herbe/fleurs, un chemin, deux falaises d’encadrement, eau, camp, pylône, proxy de citadelle, sky, nuage et éclair. Atteindre au moins **75/100** avec cette petite scène, remplacer les proxies critiques et atteindre **85/100** avant de propager la recette à 512 × 512 m. Si ce plan ne fonctionne pas, ne pas ajouter de surface : corriger l’image.

À chaque revue artistique, capturer exactement la même caméra, seed, heure, exposition, résolution et preset, puis examiner :

1. vignette couleur 320 × 180 pour la hiérarchie immédiate ;
2. image en niveaux de gris pour les valeurs et focales ;
3. image légèrement floutée pour les grandes masses ;
4. silhouettes/edges pour la lisibilité et le bruit ;
5. plein écran 1440p pour matériaux, répétitions et défauts ;
6. séquence vidéo en mouvement pour shimmer, LOD pop, ghosting, vent et stabilité temporelle.

La comparaison à la référence porte sur des relations, pas sur une copie pixel : place du héros, trois plans, trajectoire du regard, ratio chaud/froid, contraste focal, étagement atmosphérique, rareté du cyan, échelle relative et densité. Noter chaque écart, modifier une famille de variables à la fois et conserver l’avant/après.

### 7.17 Composition multi-échelle et lutte contre l’aspect procédural

Composer à trois fréquences :

- **macro 80–500 m** : vallée, citadelle, encadrement rocheux, ciel, rivière et grands vides ;
- **méso 8–80 m** : bosquets, falaises, camp, ruines, sentiers, clairières et groupes de couleurs ;
- **micro 0,1–8 m** : touffes, fleurs, pierres, traces, decals et petits props.

Un scatter uniforme est un échec, même s’il contient des millions d’instances. Utiliser masques de pente, humidité, exposition, altitude, distance au chemin, voisinage, exclusion de gameplay et groupes artistiques manuels. Ajouter des « phrases » de végétation : grande touffe + moyenne + fleurs + vide, avec répétition irrégulière et respiration. Réserver les plus forts contrastes, détails et saturations aux focales ; réduire fréquence, contraste et taille apparente vers le lointain.

Tester le feuillage sur fond de ciel, de roche, d’eau et d’ombre. Mesurer alpha overdraw, triangles, ombres et draw calls séparément. Employer géométrie suffisante pour éviter les cartes rectangulaires évidentes, LOD de silhouettes, impostors seulement à grande distance, ombres simplifiées et variation de teinte contrôlée. Tout vent doit montrer une inertie crédible et une échelle différente entre tronc, branche, touffe et pointe.

### 7.18 Pipeline personnage et animation orienté gameplay

Le contrôleur de gameplay détient l’autorité sur l’état, les collisions, l’endurance, les dégâts et les fenêtres d’action ; l’animation visualise cette décision et fournit des marqueurs contrôlés. Une longue animation ne doit jamais emprisonner le joueur par accident.

Pipeline : concept original face/profil/dos → blocage silhouette en jeu → proportions et équipement → topologie/déformation → UV/matériaux → rig → skinning → bibliothèque locomotion/actions → export glTF → retargeting documenté → AnimationTree → IK/modifiers → tests gameplay et caméra.

Avant validation d’un personnage :

- reconnaître sa silhouette en aplats noir à trois distances ;
- vérifier épaules, coudes, poignets, hanches, genoux, chevilles, cou et cape dans les poses extrêmes ;
- vérifier arme, arc, carquois et sacoches dans course, escalade, roulade et visée ;
- garantir absence de foot sliding perceptible à la vitesse de référence ;
- faire correspondre contacts et événements de hit à une timeline éditable ;
- comparer root motion et mouvement piloté par code sur une piste graduée ;
- tester à 30, 60 et 120 FPS ainsi qu’avec interpolation physique ;
- prévoir réactions directionnelles, anticipation, overshoot, settle et respiration ;
- ne pas compenser un mauvais timing par un shake ou des particules excessifs.

Les imports d’animation possèdent un preset reproductible : clips/loops, extraction de root motion, pose de référence, retarget profile, compression comparée visuellement, qualité de skinning et événements restaurés côté Godot si le format ne les transporte pas de façon fiable.

---

## 8. CONTRÔLE DU PERSONNAGE

### 8.1 États

`Idle`, `Walk`, `Run`, `Sprint`, `Jump`, `Fall`, `Land`, `ClimbEnter`, `Climb`, `ClimbRest`, `Mantle`, `Aim`, `LightAttack`, `HeavyAttack`, `Dodge`, `Interact`, `Hurt`, `Stagger`, `Exhausted`, `Dead`.

Chaque état définit entrée, actions, endurance, animation, rotation, gravité, sortie et priorité d’interruption.

### 8.2 Locomotion

`CharacterBody3D`, mouvement caméra-relative, framerate indépendant.

| Paramètre | Départ |
|---|---:|
| Marche | 3,5 m/s |
| Course | 6,0 m/s |
| Sprint | 9,0 m/s |
| Accélération sol | 24 m/s² |
| Décélération | 30 m/s² |
| Accélération air | 8,4 m/s² |
| Gravité | 24 m/s² |
| Saut | 8,2 m/s, environ 1,4 m |
| Coyote time | 0,12 s |
| Jump buffer | 0,12 s |
| Step height | 0,30–0,38 m |
| Pente | environ 46° |

Ajouter shape cast de marche, projection sur sol, rotation lissée, contrôle aérien 35 %, stabilité des pentes, plafond, réception légère/lourde, dégâts progressifs à partir d’environ 6 m.

### 8.3 Caméra

Pivots + `SpringArm3D` avec Camera3D enfant directe. Distance 4,0–4,6 m ; cible 1,45 m ; épaule 0,25–0,40 m ; FOV 68–72°, sprint 74–77° ; pitch -65°/+45°.

Zéro traversée/jitter ; interpolation framerate-independent ; fade dithering des petits obstacles ; évitement sol/plafond ; recadrage grandes cibles ; recentrage/inversion/shake configurables ; aucun snap de FOV.

### 8.4 Lock-on

Score : cône caméra, distance 18–24 m, LOS, centre écran, menace et cible précédente. Conserver joueur/cible dans le cadre, strafe, changement directionnel, libération si cible morte/cachée/lointaine, jamais à travers mur.

### 8.5 InputMap AZERTY prioritaire

`Q` signifie impérativement gauche. Ne jamais l’utiliser pour le lock-on.

| Action | AZERTY | QWERTY | Manette |
|---|---|---|---|
| Avancer | Z | W | stick G haut |
| Gauche | Q | A | stick G gauche |
| Reculer | S | S | stick G bas |
| Droite | D | D | stick G droite |
| Saut | Espace | Espace | A/Croix |
| Sprint | Maj G | Maj G | stick G pressé |
| Interaction | E | E | X/Carré |
| Attaque légère | clic G | clic G | RB/R1 |
| Attaque lourde | R | R | RT/R2 |
| Viser/tirer | clic D / clic G | idem | LT/RT |
| Esquive | Ctrl G | idem | B/Rond |
| Lock-on | C/clic molette | idem | stick D pressé |
| Cible préc./suiv. | X/V ou molette | idem | stick D impulsion |
| Inventaire | Tab | Tab | Y/Triangle |
| Plat rapide | F | F | d-pad bas |
| Pause | Échap | Échap | Menu |

Détecter le périphérique actif et changer les glyphes sans scintillement.

---

## 9. ENDURANCE, ESCALADE ET MANTLE

### 9.1 Endurance

Maximum 100. Sprint 12/s ; escalade 18/s ; latéral 16/s ; saut d’escalade 20 ; esquive 15 ; lourde 20. Régénération après 1 s à 22/s, reprise progressive 0,20 s, clamp 0–max.

À zéro : sprint→course, lâcher du mur, lourde refusée, épuisement, respiration, 0,45 s avant action consommatrice. Jauge contextuelle près du héros.

### 9.2 Paroi

Sondes tête/torse/pieds, côtés, dessus et dégagement capsule. Départ : accroche 0,55–0,80 m ; distance mur 0,38–0,48 m ; vitesse verticale 1,9–2,2 m/s ; latérale 1,5–1,8 ; lissage normale 0,08–0,16 s ; saut 0,75–1,0 m.

Orienter selon normale, suivre irrégularités, coins convexes raisonnables, refuser vides/concavités, valider contact à chaque mouvement, IK visuelle sans instabilité capsule.

Autoriser nature/pierre/bois robuste. Refuser `unclimbable`, `electrified`, `burning`, `spiked`, `fragile_unsupported`, eau et plateformes trop rapides. Danger lisible par matière/forme.

### 9.3 Mantle

Détecter haut → surface marchable → dégagement capsule → mantle bas/haut → transform cible → état → alignement animation/capsule → réactivation. Annuler proprement si invalide ; aucun snap visible.

Placer corniches de repos ; une jauge pleine suffit au chemin principal ; raccourcis plus exigeants ; panorama facultatif récompensant l’ascension.

---

## 10. COMBAT

### 10.1 Pipeline

Lire `AttackDefinition` → valider état/endurance/arme → animation → hitbox par méthode/signal → set des cibles touchées → dégâts/poise/recul/élément une fois → VFX/son/haptique/hit-stop → désactiver → fenêtre combo → recovery. Jamais de dégâts à chaque frame d’overlap.

### 10.2 Actions et ressenti

- combo trois légères par arme ; lourde ; attaque sortie d’esquive ;
- arc physique ; changement d’arme ; esquive quatre directions ;
- i-frames 0,22–0,27 s ; stagger/knockback ; mort/checkpoint.

Buffers : attaque 0,15 s, esquive 0,12 s. Combo dans les derniers 25–35 %. Hit-stop léger 0,035–0,055 s, lourd 0,070–0,095 s. Shake 0,08–0,16 s, désactivable. Simuler localement si une pause globale casse la physique.

### 10.3 Dégâts

`base × weapon × attack × buff × weak_point × resistance - armor`, clampé. Chaque événement transporte instigateur, équipe, type, quantité, direction, stagger, point, élément et attack ID.

### 10.4 Arc

Visée épaule ; point caméra corrigé vers origine arc ; raycast proche anti-tir à travers mur ; vitesse 42–58 m/s ; gravité modérée ; pooling ; impacts par matière ; points faibles ; réticule original.

### 10.5 Fairness

Télégraphes visuel+audio ; avertissement hors champ ; maximum deux attaquants mêlée simultanés ; cadence des archers ; recovery après lourdes ; brève protection anti-stunlock ; protection multi-impact même frame ; VFX moins fort que le danger.

### 10.6 Contrat de game feel mesurable

Chaque action est une ressource de données inspectable, pas une collection de nombres cachés dans l’animation. `AttackDefinition` ou `ActionDefinition` décrit :

- intention d’entrée, priorité et conditions ;
- coût, délai de consommation et règle de remboursement ;
- anticipation/startup, frames ou temps actif, recovery ;
- fenêtres de buffer, queue, combo, cancel, dodge cancel et hit confirm ;
- courbe de déplacement/rotation et autorité root motion/code ;
- hitbox, sweep éventuel, équipe, masque et identifiant unique ;
- dégâts, poise, recul, launch, élément et hit reaction ;
- hit-stop attaquant/cible, impulsion caméra, rumble, audio et VFX ;
- règle en cas de mur, vide, perte de cible, arme cassée, mort ou interruption.

Les nombres sont éditables en jeu dans `CombatLab` et consignés dans une fiche de tuning. L’animation et les effets se calent sur le contrat ; ils ne redéfinissent pas silencieusement la logique.

Cibles de réponse à mesurer, hors latence écran/périphérique :

- mouvement et caméra commencent au plus tard au tick physique suivant une entrée reçue ;
- action bufferisée valide part idéalement en un à deux ticks physiques après la première fenêtre légale ;
- relâcher le stick réduit rapidement la vitesse sans arrêt robotique ;
- une esquive demandée pendant une fenêtre autorisée n’est pas perdue ;
- aucun résultat de combat ne dépend du framerate de rendu ;
- le ressenti reste cohérent à 30, 60 et 120 FPS.

Horodater réception, mise en buffer, consommation, début logique, premier changement de pose, frame active, impact et retour au contrôle. Afficher en debug la latence en millisecondes et en ticks. Les valeurs cibles sont ajustables, mais une action lente doit être **intentionnellement anticipée**, pas tardive à cause de l’architecture.

### 10.7 Grammaire de feedback, pas « juice » aléatoire

Le feedback sert la cause et la hiérarchie :

1. **Intention** : pose/anticipation, trajectoire, son préparatoire.
2. **Contact** : arrêt très court, déformation/pose, son transitoire, étincelle/decal au point exact.
3. **Conséquence** : recul, réaction, dégâts/poise, environnement et caméra.
4. **Résolution** : recovery lisible, résidus, retour au contrôle.

Définir trois niveaux d’intensité cohérents : léger, lourd, critique/boss. Une attaque légère ne peut pas déclencher un feedback plus fort qu’une parade parfaite ou une rupture d’armure. Le shake est une impulsion additive filtrée, jamais une modification cumulative du transform de base. Le hit-stop ne doit pas désynchroniser physique, audio, caméra ou IA. Le son confirme le matériau, la masse et le résultat ; éviter de masquer un problème de timing sous le volume, le bloom ou des particules.

Prévoir curseurs ou options pour shake, flash, haptique, motion effects et intensité VFX. Tester sans son, sans VFX et sans shake : télégraphes, timing et réactions doivent rester compréhensibles. Tester ensuite la pile complète : elle doit amplifier, pas brouiller.

### 10.8 `CombatLab` et instrumentation professionnelle

`CombatLab.tscn` contient piste graduée, murs, pente, bord de vide, cibles immobiles/mobiles, mannequins avec armure/poise/résistances, plusieurs tailles, deux ennemis, caméra libre et scénarios enregistrés.

Outils debug activables uniquement en développement :

- hitboxes/hurtboxes/sweeps et normales de contact ;
- état joueur/ennemi, cible, endurance, poise, invulnérabilité ;
- timeline de l’action avec startup/active/recovery/cancel ;
- historique horodaté des inputs et raisons de rejet ;
- trajectoire racine, vitesse désirée/réelle et correction d’alignement ;
- attaque ID et set de victimes déjà touchées ;
- frame time, tick physique et ralenti 0,1×/pas-à-pas ;
- export CSV/JSON d’un duel court.

Créer des scripts de scénario qui placent l’état initial puis rejouent une séquence d’inputs de haut niveau : combo complet, attaque contre mur, dodge au dernier instant, multi-cible, changement de cible, tir près d’un obstacle, rupture d’arme et stagger simultané. Ils servent à reproduire les bugs, pas à prétendre que Jolt est bit-à-bit déterministe sur toutes les plateformes.

Gate `Combat Feel` : dix exécutions consécutives de chaque scénario sans input perdu non intentionnel, double hit, target switch absurde, caméra cassée, traversée de mur ou état bloqué ; puis une session humaine à l’aveugle avec notes sur clarté, contrôle, satisfaction et injustice. Corriger d’abord le défaut le plus fréquemment cité.

### 10.9 Caméra comme système de gameplay

Créer une machine de modes : `Explore`, `Sprint`, `LockOn`, `Aim`, `Climb`, `Interaction`, `Boss`, `Vista`, `Cinematic`, avec transitions courtes, interruptibles et priorités explicites. Chaque mode définit pivot, distance, FOV, offsets, vitesses, damping, limites verticales, collision, composition et autorité d’entrée.

- calculer le mouvement caméra/character dans le domaine temporel compatible avec l’interpolation physique ;
- séparer transform de suivi, collision, framing et impulsions afin qu’aucun shake ne dérive la caméra ;
- utiliser `SpringArm3D`/shape cast et une récupération douce après obstacle, avec réponse rapide quand un mur approche ;
- empêcher géométrie entre caméra et héros via collision, fade dither ciblé ou repositionnement ;
- conserver héros et menace prioritaire dans une zone de composition, surtout boss et lock-on ;
- limiter changement de cible par angle, distance, visibilité et intention du stick ;
- ne pas reprendre brutalement yaw/pitch après cinématique, lock-on ou visée ;
- tester espaces étroits, falaise, sous plafond, ennemi derrière, sprint latéral, rotations rapides et framerate bas.

La caméra doit sembler calme pendant l’exploration et énergique au contact, sans provoquer nausée ni cacher les attaques. Une belle animation qui sort le danger du cadre est un échec de gameplay.

### 10.10 Revue du combat par couches

Ne pas juger le combat uniquement « à l’impression ». Valider successivement :

1. **Entrée** : réponse, buffer, remapping et périphériques.
2. **Mouvement** : accélération, rotation, distance, collision et alignement.
3. **Timing** : anticipation, actif, recovery, cancel et i-frames.
4. **Contact** : hit detection, une touche, matériaux et direction.
5. **Réaction** : poise, stagger, recul, mort et lisibilité.
6. **Caméra** : framing, collision, lock-on, off-screen et shake.
7. **Rencontre** : rôles, tokens, espace, pression et recovery.
8. **Présentation** : animation, VFX, audio, UI et accessibilité.
9. **Performance** : absence de spike au premier usage et sous charge.

Une couche ne peut pas être déclarée excellente parce que la suivante la camoufle. Conserver une vidéo avant/après pour toute passe majeure de game feel.

---

## 11. ARMES, INVENTAIRE, DURABILITÉ ET BUTIN

### 11.1 Armes

| Arme | Dégâts | Durabilité | Portée | Conductivité |
|---|---:|---:|---:|---:|
| Gourdin bois | 8 | 18 | 1,6 m | 0,05 |
| Épée usée | 12 | 24 | 1,7 m | 0,85 |
| Lance | 10 | 30 | 2,7 m | 0,70 |
| Hache lourde | 22 | 20 | 1,9 m | 0,80 |
| Arc simple | 9 | 28 tirs | distance | 0,20 |
| Lame conductrice | 26 | 16 | 1,8 m | 1,00 |

Définition : ID, nom localisé, icône, type, dégâts, vitesse, portée, durabilité, rareté, masse, conductivité, tags, mesh, sockets, attaques, sons, VFX, effet spécial.

### 11.2 Durabilité

Diminue seulement si touche ennemi, bouclier, cassable ou objet explicitement prévu. Jamais dans le vide.

À 25 % : avertissement bref, son altéré, usure visuelle, sans spam. À zéro : couper hitbox, rupture, retirer l’instance, nettoyer sockets/références, équiper suivante ou mains nues.

### 11.3 Inventaires

Huit armes ; ingrédients empilables séparés ; plats séparés ; flèches ; objets-clés non jetables ; sélection rapide ; inventaire pause ; navigation tous périphériques ; aucun doublon d’instance.

### 11.4 Coffres et loot

Trois dans la vallée, un au camp, trois dans le donjon, un avant le boss et un coffre final distinct si besoin. Chaque coffre : ID stable, état, animation, son, VFX, loot table, garanti, spawn, alignement, sauvegarde. Jamais de second loot après chargement.

Loot pondéré reproductible ; progression fixe. Avant boss garantir deux armes, une non conductrice, arc, 12–20 flèches, durabilité suffisante, ingrédients résistance électrique et soin. Ajouter validateur de dégâts théoriques minimaux.

---

## 12. BESTIAIRE ET INTELLIGENCE ARTIFICIELLE

Créer cinq familles minimales dont les silhouettes, proportions, armes, animations, rythmes et décisions diffèrent réellement. Les trois pillards ne doivent pas être de simples recolorations.

### 12.1 Pillard braise — nom de travail « Bokoblin rouge »

- 45 PV ;
- arme courte, dégâts faibles ;
- petite silhouette voûtée avec longues oreilles ou cornes originales non copiées ;
- vêtements textiles rouges/terre, peu d’armure ;
- perception lente ;
- télégraphes 0,65–0,95 s ;
- un ou deux coups ;
- recule après une esquive réussie du joueur ;
- peut fuir 2–4 s après la mort d’un allié ;
- sert de tutoriel vivant.

### 12.2 Pillard azur — nom de travail « Bokoblin bleu »

- 85 PV ;
- lance ou arc ;
- silhouette plus droite, protections en bois/céramique ;
- contourne le joueur ;
- alerte les alliés dans un rayon limité ;
- alterne maintien de distance et attaque ;
- esquive occasionnellement une lourde très télégraphiée ;
- ne spamme pas l’esquive ; cooldown 6–10 s.

### 12.3 Briseur d’obsidienne — nom de travail « Bokoblin noir »

- 150 PV ;
- armure partielle sombre et masse lourde ;
- silhouette large, centre de gravité bas ;
- combo de deux ou trois coups ;
- blocage frontal limité par une jauge de garde ;
- résistance au stagger élevée ;
- ouverture claire après combo ou garde brisée ;
- rare à l’extérieur, gardien d’une forte récompense.

### 12.4 Colosse des ravins — nom de travail « Troll »

- environ 420 PV ;
- 3,5–4,5 m de haut ;
- silhouette massive asymétrique, roche/bois/cuir ;
- balayage, frappe verticale et coup au sol ;
- onde de choc au sol évitable par saut/esquive ;
- peut ramasser/lancer un rocher ;
- point faible visible dos ou tête ;
- détruit certains petits props, pas les objets essentiels ;
- peut renverser le joueur ;
- navigation adaptée à sa taille ; aucun passage dans des portes étroites.

### 12.5 Chasseur quadrupède — nom de travail « Lynel »

Créer une créature centauroïde entièrement originale : corps inférieur quadrupède non équin générique, torse humanoïde original, armure en lames/céramique, arc et arme de mêlée.

- environ 650 PV ;
- territoire dangereux clairement signalé ;
- combat facultatif ;
- charge rapide en ligne lisible ;
- salve d’arc avec cadence et couverture ;
- combo rapproché ;
- cri/posture avant attaque majeure ;
- repositionnement circulaire ;
- abandonne la poursuite à la frontière ;
- récompense supérieure mais non obligatoire.

### 12.6 Données indicatives

| Type | Vision | Audition | Vitesse poursuite | Attaque simultanée |
|---|---:|---:|---:|---:|
| Pillard braise | 22 m / 95° | 15 m | 5,2 m/s | oui |
| Pillard azur | 30 m / 105° | 20 m | 5,8 m/s | oui |
| Briseur | 26 m / 90° | 22 m | 5,0 m/s | oui |
| Colosse | 35 m / 115° | 30 m | 4,8 m/s | seul ou support |
| Chasseur | 48 m / 130° | 38 m | 10–13 m/s | seul |

Les valeurs sont testées avec l’occlusion réelle et ajustées au level design.

### 12.7 Architecture IA

Utiliser `NavigationRegion3D`, `NavigationAgent3D`, `NavigationLink3D` si nécessaire, et une machine à états :

- `Idle` ; `Patrol` ; `Suspicious` ; `Investigate` ; `Alert` ;
- `Chase` ; `Reposition` ; `Attack` ; `Recover` ;
- `Stagger` ; `Flee` ; `Return` ; `Dead`.

Perception :

- préfiltre par distance/angle ;
- raycast vers torse/tête pour ligne de vue ;
- mémoire de dernière position 3–8 s selon type ;
- événements sonores avec position, rayon et intensité ;
- sprint, impact, rupture, flèche et explosion produisent des bruits distincts ;
- aucune vision à travers mur ;
- recherche courte, puis retour.

### 12.8 Coordination

Créer un `CombatCoordinator` par groupe :

- maximum deux tokens mêlée ordinaires ;
- un token attaque lourde ;
- archers espacés et cadence plafonnée ;
- les autres encerclent, menacent ou se repositionnent ;
- libération garantie du token en cas de mort, stagger, interruption ou sortie de combat ;
- aucune file bloquée par une référence invalide.

### 12.9 Navigation et performance

- ne recalculer une destination que si le joueur s’est déplacé significativement ou après cadence 0,15–0,35 s ;
- activer avoidance seulement pour agents proches qui en ont besoin ;
- désactiver traitement, animation détaillée et perception complète des ennemis très éloignés ;
- limiter à 10–14 IA pleinement actives dans la verticale ;
- aucun pathfinding par frame pour tous les agents ;
- territory origin et distance maximale de poursuite ;
- récupération si agent reste bloqué, sans téléportation visible devant le joueur ;
- navmesh validé avec capsule de chaque famille.

### 12.10 Mort et loot

À la mort : couper IA/hitboxes/navigation, terminer l’animation ou ragdoll contrôlé, générer loot une fois, sauvegarder si nécessaire, puis retourner au pool ou libérer après délai. Aucun corps ne doit continuer à bloquer une porte critique.

---

## 13. RÉCOLTE, CUISINE ET BUFFS

### 13.1 Ingrédients

Placer et rendre visuellement distincts :

- fruit de soin ;
- champignon de soin ;
- viande ;
- herbe d’endurance ;
- racine défensive ;
- baie de résistance électrique ;
- épice rare augmentant la durée.

Chaque `IngredientDefinition` contient ID, nom, icône, scène, soin, tags d’effet, puissance, durée, rareté, maximum de stack et audio de collecte.

Les ressources récoltées ordinaires peuvent réapparaître après un délai ou une nouvelle partie ; leur persistance est définie explicitement. Les ingrédients de progression ne dépendent jamais d’un respawn ambigu.

### 13.2 Collecte

- interaction dans un cône court ;
- surbrillance ou mouvement discret, pas de halo criard permanent ;
- animation rapide ;
- son et notification compacte ;
- ajout atomique à l’inventaire ;
- l’objet ne disparaît qu’après succès de l’ajout ;
- empêcher double collecte causée par plusieurs inputs ou signaux.

### 13.3 Interface de cuisine

Au feu de camp, sélectionner 1 à 5 ingrédients. Afficher avant confirmation : ingrédients, compatibilité partielle, catégorie de résultat attendue, mais pas forcément toutes les valeurs secrètes.

Séquence : verrouiller interaction → ouvrir UI → sélectionner → confirmer → fermer UI → courte animation 2–4 s → effets feu/son → calcul déterministe → créer plat → afficher résultat → ajouter inventaire → rendre contrôle.

Annuler rend toujours les ingrédients. Une interruption ou un changement de scène ne doit ni dupliquer ni perdre les ingrédients.

### 13.4 Règles

- soin = somme des valeurs de soin, avec clamp ;
- effet dominant déterminé par tags compatibles et puissance cumulée ;
- durée = 60 s + 30 s par ingrédient compatible ;
- maximum 300 s ;
- épice rare augmente la durée sans changer la famille ;
- effets majeurs incompatibles → « ragoût instable » à faible soin ;
- un seul buff majeur actif ;
- un nouveau buff remplace l’ancien ;
- soin immédiat toujours appliqué ;
- minuterie de buff suspendue pendant pause/inventaire si le jeu est réellement en pause.

### 13.5 Buffs minimum

| Buff | Effet de départ |
|---|---|
| Attaque | +25 % dégâts |
| Défense | -25 % dégâts reçus |
| Endurance | restauration ou régénération accélérée |
| Résistance électrique | -60 % dégâts électriques et stun réduit |
| Vitalité temporaire | PV temporaires jusqu’à perte |

Le tutoriel environnemental, des baies près d’un danger et l’antichambre du boss doivent enseigner que la résistance électrique est utile sans texte obligatoire interminable.

---

## 14. PHYSIQUE ET INTERACTIONS SYSTÉMIQUES

Créer : caisses poussables, blocs métalliques, sphères roulantes, planches, connecteurs, batteries, objets cassables, barils non explosifs si non nécessaires, rochers et passerelles.

### 14.1 Règles physiques

- `RigidBody3D` pour objets simulés ;
- `AnimatableBody3D` pour portes/plateformes pilotées ;
- masses cohérentes par famille ;
- damping et angular damping ;
- vitesses maximum ;
- sommeil activé ;
- pooling seulement si réinitialisation fiable ;
- pas de modification directe répétée de transform d’un rigid body actif ;
- saisir/déplacer avec forces ou mode contrôlé stable ;
- rendre à la simulation avec vitesse bornée ;
- aucune explosion due à des colliders imbriqués.

### 14.2 Interaction contextuelle

Sélectionner l’objet pertinent via cône, distance, ligne de vue, angle écran et priorité. Afficher une seule invite : ouvrir, ramasser, cuisiner, activer, déplacer, examiner, transporter ou poser.

- portée ordinaire 1,8–2,4 m ;
- hystérésis pour éviter clignotement entre deux objets ;
- reticle ou outline discret ;
- interaction refusée si obstacle ;
- actions longues annulables proprement ;
- invite mise à jour selon périphérique actif.

### 14.3 Objets essentiels

Chaque objet d’énigme essentiel possède zone hors limites, transform de secours, bouton reset et `persistent_id`. S’il tombe, réapparaître après 1–2 s avec VFX lisible. Ne jamais sauvegarder un état irrécupérable.

### 14.4 Conductivité

Chaque objet concerné expose une conductivité 0–1 et des tags : `metal`, `wet`, `wood`, `ceramic`, `insulated`, `charged`. L’eau peut créer une connexion de zone ou un danger, jamais une propagation infinie non contrôlée.

---

## 15. DONJON ÉLECTRIQUE

Le donjon doit être une vraie séquence spatiale connectée, non une pièce unique ou quatre booléens indépendants.

### 15.1 Contrat du graphe électrique

Types de nœuds :

- `SourceNode` ;
- `CableNode` ;
- `ConnectorNode` ;
- `SwitchNode` ;
- `MovableConductorNode` ;
- `RelayNode` ;
- `ReceiverNode` ;
- `DoorNode` ;
- `HazardNode` ;
- `BatteryNode` ;
- `WaterZoneNode`.

Chaque nœud contient :

- ID stable ;
- ports d’entrée/sortie ;
- état activé ;
- tension logique ou puissance normalisée si nécessaire ;
- conductivité ;
- voisins valides ;
- signaux `connection_changed`, `power_changed` ;
- méthode idempotente `set_powered(value)` ;
- représentation visuelle/audio séparée de la logique.

### 15.2 Algorithme

1. Un déplacement/rotation/interrupteur marque le sous-graphe `dirty`.
2. Regrouper les changements jusqu’à la fin du tick physique.
3. Reconstruire seulement les connexions spatiales affectées.
4. Partir de toutes les sources actives.
5. Parcourir par BFS/DFS avec ensemble `visited` pour éviter les cycles.
6. Vérifier direction de port, distance, alignement, isolant, état d’interrupteur et capacité éventuelle.
7. Calculer les récepteurs atteints.
8. Comparer ancien/nouvel état.
9. Émettre des signaux uniquement en cas de changement.
10. Interpoler visuel/audio vers la nouvelle valeur.

Ne jamais parcourir tout le donjon à chaque frame. Les cycles sont autorisés et ne doivent pas provoquer de récursion infinie.

### 15.3 Connexions physiques

Pour un bloc entre deux plaques, la connexion doit dépendre de contacts ou d’`Area3D` réels avec tolérance et debounce. Pour une colonne rotative, dépendre de l’orientation des ports. Pour une batterie, distinguer charge stockée, socket et décharge. La logique ne doit pas s’activer seulement parce que l’objet est proche d’un point invisible sans retour visuel.

### 15.4 Langage visuel

- source : pulsation lente et son grave ;
- câble non alimenté : métal sombre ;
- câble alimenté : ligne cyan se propageant de 0 à 1 ;
- récepteur : anneau qui se ferme ;
- erreur : étincelle orange/cyan courte, jamais punition instantanée systématique ;
- danger : rythme plus rapide et sol marqué ;
- isolant : céramique ivoire ;
- conducteur : cuivre/métal patiné ;
- chaque activation associe mouvement mécanique, son et lumière.

### 15.5 Salle 1 — Initiation

- source et récepteur séparés par un vide court ;
- bloc métallique mobile ;
- deux plaques clairement connectées au circuit ;
- pousser le bloc pour toucher les deux ;
- propagation lumineuse visible ;
- porte s’ouvre avec délai 0,6–1,2 s ;
- objectif compréhensible sans texte ;
- bouton reset ;
- solution impossible à perdre.

### 15.6 Salle 2 — Circuit vertical

- ascenseur non alimenté ;
- puits latéral escaladable ;
- électrodes intermittentes avec rythme observable ;
- interrupteur supérieur redirige le courant ;
- corniches de repos ;
- une jauge pleine suffit si timing correct ;
- chute renvoie à un palier proche ;
- ascenseur ne peut écraser ou coincer le joueur ;
- sauvegarde d’état cohérente.

### 15.7 Salle 3 — Relais rotatifs

- quatre colonnes ;
- ports visibles ;
- rotations discrètes de 90° ou angles définis ;
- chaque segment valide s’allume progressivement ;
- aucune erreur ne tue immédiatement ;
- feedback distinct si chemin partiel ;
- solveur/test automatique vérifie au moins une configuration solution ;
- bouton reset remet la configuration initiale.

### 15.8 Salle 4 — Batterie transportable

- une source, deux mécanismes successifs ;
- batterie chargeable et transportable ;
- socket explicite ;
- zone d’eau conductrice dangereuse lorsqu’alimentée ;
- couper le courant ou créer une passerelle isolante ;
- batterie hors limites réapparaît ;
- aucune porte ne verrouille la batterie du mauvais côté ;
- retour toujours possible.

### 15.9 Salle centrale

Trois récepteurs indépendants alimentent la porte du boss simultanément. Afficher trois anneaux, progression mécanique, accord sonore par circuit, carte murale et lignes continues. L’ouverture est une vraie conséquence du graphe.

Si le quatrième puzzle est séquentiel mais que trois circuits permanents suffisent, documenter précisément quelle salle fournit quel récepteur. Aucun compteur abstrait sans connexion visible.

### 15.10 Antichambre

- checkpoint ;
- coffre garanti ;
- feu ou station de cuisine ;
- baies électriques ;
- possibilité de revenir ;
- fresque montrant bois isolant/métal conducteur ;
- aperçu de l’arène ;
- aucune cinématique non passable longue.

### 15.11 Anti-softlock

Chaque salle : reset, respawn, chemin retour, état sauvegardé, indice visuel, aucune ressource obligatoire destructible, test depuis sauvegarde vierge et test après chargement en milieu de résolution.

Créer un outil debug de développement permettant d’afficher IDs, ports, voisins et état `powered`, mais le masquer dans le build final.

---

## 16. BOSS FINAL — GARDIEN DE L’ORAGE

### 16.1 Présentation

Créer un boss original mécanique-animal : pierre, cuivre, bronze, céramique, câbles animés, noyau cyan et couches d’armure. Arène circulaire de 32–42 m, quatre pylônes de mise à la terre, zones de sol distinctes, aucun pilier bloquant durablement la caméra.

Le boss est un hero asset avec dégâts visuels progressifs, parties mobiles, silhouette reconnaissable, animation d’entrée 5–8 s passable et barre de vie originale.

Durée première victoire : 4–7 min. Joueur expert sans buff possible ; joueur normal fortement aidé par préparation.

### 16.2 Machine à états

`Intro`, `Phase1`, `GroundedStun`, `Transition12`, `Phase2`, `Overload`, `Transition23`, `Phase3`, `Stagger`, `Dead`.

Toutes les transitions sont idempotentes. Un seuil de PV ne peut déclencher deux fois. La mort interrompt toute attaque, coupe hitboxes/timers et libère la caméra.

### 16.3 Phase 1 — Armure chargée, 100 à 65 %

- combo mêlée court ;
- arc électrique frontal ;
- frappe de zone annoncée ;
- armure réduit fortement les dégâts, sans invulnérabilité totale obscure ;
- orienter/connecter deux pylônes ;
- mise à la terre étourdit 5–8 s ;
- noyau vulnérable ;
- pylônes utilisent le même système électrique que le donjon.

### 16.4 Phase 2 — Surcharge, 65 à 30 %

- projectiles électriques ;
- portions de sol électrifiées après télégraphe 0,8–1,3 s ;
- deux cristaux conducteurs sur le boss ;
- cristaux destructibles à l’arc ou par opportunité rapprochée ;
- métal frappant pendant surcharge risque un stun court ;
- bois/isolant évite ce risque ;
- résistance électrique réduit dégâts et durée du stun ;
- aucune combinaison ne doit stun-lock le joueur.

### 16.5 Phase 3 — Tempête, sous 30 %

- vitesse +10 à +18 %, pas doublement brutal ;
- charge suivie d’une frappe au sol ;
- éclairs marqués au sol 0,7–1,0 s avant impact ;
- fenêtres plus courtes mais présentes ;
- noyau exposé après destruction des cristaux ;
- pattern final spectaculaire mais lisible ;
- maximum raisonnable de zones persistantes simultanées.

### 16.6 Caméra et arène

- boss visible au moins 80 % du temps en lock-on ;
- caméra élargit distance/FOV progressivement ;
- obstacles proches peuvent fade ;
- aucun VFX devant toute la caméra ;
- boss ne pousse pas le joueur à travers les murs ;
- nav/steering garde le boss dans l’arène ;
- zone de retour sûre après une esquive ;
- checkpoint juste avant ;
- retry en moins de 20 s après mort.

### 16.7 Équilibrage de solvabilité

Calculer : PV effectifs, fenêtres vulnérables, dégâts attendus, durabilité totale garantie, flèches nécessaires aux cristaux, soins et contribution du buff. Ajouter test qui échoue si le boss est mathématiquement impossible avec le loot garanti et une précision raisonnable.

Prévoir une marge de 30–50 % de durabilité au-dessus du minimum théorique. Ne jamais exiger une arme aléatoire rare.

### 16.8 Victoire

- arrêter tous les hazards et projectiles ;
- animation de mort ;
- tempête qui se dissipe partiellement ;
- énergie cyan qui passe de violente à calme ;
- coffre final ;
- sauvegarde `boss_defeated` ;
- courte cinématique passable ;
- écran victoire avec recommencer, continuer/explorer ou menu.

---

## 17. INTERFACE, UX ET ACCESSIBILITÉ

### 17.1 Identité

Interface originale, discrète et lisible : plaques de pierre sombre translucide, traits d’or pâle, cristaux rouges pour vitalité, turquoise pour endurance et motifs géométriques propres au monde. Ne pas copier placement, formes, sons ou icônes d’une licence existante.

Utiliser `CanvasLayer`, `Control`, conteneurs et `Theme` central. Aucun placement uniquement absolu qui casse avec la résolution.

### 17.2 HUD

Afficher :

- santé ;
- endurance contextuelle près du héros ;
- arme équipée ;
- état de durabilité approximatif ;
- flèches ;
- buff actif et temps restant ;
- interaction contextuelle ;
- indicateur de détection ennemi ;
- réticule en visée ;
- barre de boss ;
- objectif minimal lors du donjon si nécessaire.

Le HUD normal ne doit pas occuper plus de 12–15 % de l’écran. Masquer automatiquement ce qui n’est pas utile. Respecter safe areas.

### 17.3 Menus

- menu principal ;
- continuer/nouvelle partie ;
- inventaire armes/ingrédients/plats ;
- cuisine ;
- pause ;
- options audio, caméra, contrôles et graphismes ;
- écran mort/retry ;
- victoire.

Navigation complète souris, clavier AZERTY et manette. Focus visible, pas de piège de focus, retour cohérent, confirmation avant écrasement d’une sauvegarde.

### 17.4 Lisibilité

- texte minimum 24 px équivalent à 1080p pour les informations importantes ;
- contraste WCAG-like autant que compatible avec le style ;
- icône + forme + couleur, jamais couleur seule ;
- animation UI courte 0,12–0,25 s ;
- aucune notification sur le réticule ;
- messages de loot regroupés ;
- tutoriels contextuels une fois, consultables ensuite.

### 17.5 Accessibilité minimale

- remapping des actions ;
- AZERTY/QWERTY présélectionnés ;
- sensibilité X/Y séparée ;
- inversion X/Y ;
- maintien ou bascule pour viser/sprinter si compatible ;
- taille des sous-titres ;
- sous-titres pour informations vocales ;
- intensité camera shake de 0 à 100 % ;
- motion blur off par défaut ;
- intensité bloom ;
- mode contraste élevé pour interactables ;
- correction protanopie/deutéranopie/tritanopie pour circuits et dangers ;
- difficulté ajustant dégâts/fenêtres, jamais structure des puzzles sans choix explicite.

### 17.6 Presets graphiques

| Réglage | Web | Medium | High | Cinematic |
|---|---|---|---|---|
| Renderer | Compatibility | Forward+ | Forward+ | Forward+ |
| Résolution 3D | 0,75–0,9 | dynamique 0,75–1 | 0,85–1 | 1–1,25 capture |
| GI | Lightmap | Lightmap | SDFGI half ou Lightmap | SDFGI/Lightmap choisi |
| Volumetric fog | non | faible/non | oui limité | oui |
| SSIL/SSR | non | non/faible | modéré | modéré |
| Ombres | courtes | moyennes | hautes | hautes capture |
| Herbe | 35–50 % | 65 % | 100 % | 110 % capture |

Les réglages s’appliquent sans corruption, et les changements nécessitant un redémarrage sont signalés.

---

## 18. AUDIO ET MUSIQUE

### 18.1 Architecture

Créer des bus : `Master`, `Music`, `Ambience`, `SFX`, `UI`, `Voice`, `ReverbSend`, `LowHealth`, `Underwater` si utilisé. Ajouter limiteur uniquement si nécessaire ; éviter de masquer les mauvais niveaux par compression excessive.

Utiliser `AudioStreamPlayer3D`, `AudioStreamRandomizer`, pools et zones de réverbération. Tous les sons externes respectent les licences.

### 18.2 Sons obligatoires

- pas par surface et vitesse ;
- départ/arrêt/sprint ;
- souffle et épuisement ;
- escalade/mantle ;
- réception ;
- impacts bois/pierre/métal/chair/eau ;
- arc et flèche ;
- arme faible/rupture ;
- coffre ;
- récolte ;
- cuisine ;
- source/câble/récepteur ;
- danger électrique ;
- détection/suspicion ;
- stagger/mort ;
- changements de phase ;
- éclairs et tonnerre.

Varier pitch, volume et échantillon dans des bornes contrôlées. Aucun son identique joué en rafale ne doit produire un effet mitraillette.

### 18.3 Ambiance extérieure

Couches : vent, herbe/feuilles, oiseaux lointains, insectes ponctuels, eau, activité du camp, grondement très distant de la citadelle. Leur mix varie selon zone, hauteur et ligne de vue sans coupure.

La vue d’ouverture commence avec nature lumineuse, puis un grondement/éclair attire l’attention vers le donjon.

### 18.4 Musique adaptative

- exploration légère et espacée ;
- tension lors de suspicion ;
- combat par couches ;
- donjon plus mécanique ;
- boss en trois intensités ou stems ;
- transitions musicales sur mesures ou crossfades propres ;
- victoire reprenant un motif du thème principal ;
- musique originale ou légalement utilisable.

### 18.5 Spatialisation et budget

- atténuation réaliste mais lisible ;
- sons critiques audibles même hors champ ;
- occlusion simple pour murs si coût acceptable ;
- maximum indicatif 32–48 voix simultanées ;
- pooling des sons très fréquents ;
- aucune source 3D laissée active hors portée inutilement.

---

## 19. SAUVEGARDE, CHECKPOINTS ET MIGRATIONS

### 19.1 Contenu sauvegardé

- version du schéma ;
- ID du slot ;
- scène et checkpoint ;
- position/rotation sûre du joueur ;
- santé/endurance ;
- inventaires et instances d’armes ;
- arme équipée ;
- durabilités ;
- flèches ;
- plats et buff restant ;
- coffres ouverts ;
- ressources persistantes ;
- portes/interrupteurs/circuits ;
- transforms des objets essentiels seulement si sûres ;
- boss vaincu ;
- options utilisateur séparées ;
- temps de jeu et timestamp.

### 19.2 Format et sûreté

Utiliser `user://`, un schéma versionné, validation de types/valeurs et écriture atomique : sérialiser vers fichier temporaire, flush/close, vérifier, puis remplacer l’ancien. Conserver éventuellement une sauvegarde précédente récupérable.

Ne jamais sérialiser des références Node/Resource brutes comme identité durable. Utiliser IDs, valeurs primitives, tableaux et dictionnaires contrôlés.

### 19.3 Identifiants

Format recommandé : `zone.category.name.index`, par exemple `valley.chest.river_ledge.01`. Ajouter un validateur EditorScript qui échoue sur ID vide ou doublon.

### 19.4 Chargement

Ordre : lire → valider → migrer → charger scène → attendre ready → appliquer état global → appliquer état des objets enregistrés → placer joueur au transform sûr → réactiver input → confirmer succès.

Si position invalide, utiliser checkpoint. Si item inconnu après mise à jour, le journaliser et continuer sans crash. Une migration ne doit jamais écraser silencieusement le fichier source avant succès.

### 19.5 Checkpoints

- camp de départ ;
- entrée du donjon ;
- salle centrale après circuits ;
- antichambre du boss ;
- victoire.

À la mort : restaurer au checkpoint, santé minimale correcte, objets essentiels réinitialisés, ennemis selon règle documentée, coffres persistants, loot déjà acquis conservé si le design le décide de façon constante.

---

## 20. PERFORMANCE, STREAMING ET PROFILAGE

### 20.1 Matériel de référence honnête

Documenter CPU, GPU, RAM, OS, résolution, renderer, preset et build. Si aucun matériel de référence n’est disponible, ne jamais annoncer « 60 FPS validés ».

Cibles recommandées :

- Recommended : Apple M2 Pro ou PC proche RTX 2060/RX 6600, 16 Go RAM, 1080p High 60 FPS ;
- Base : Apple M1 intégré/équivalent, 1080p dynamique Medium 30–60 FPS ;
- Web : matériel moderne, 900p Compatibility 30–60 FPS.

### 20.2 Budgets High 1080p

| Mesure | Cible |
|---|---:|
| Frame moyen | ≤ 16,6 ms |
| P95 | ≤ 18,5 ms |
| 1 % low | ≥ 50 FPS |
| Main thread | idéalement ≤ 8 ms |
| Render thread | idéalement ≤ 10 ms |
| GPU | idéalement ≤ 15,5 ms |
| Draw calls extérieur | ≤ 1 500, viser moins |
| Triangles visibles | environ ≤ 2,5–3,5 M selon GPU |
| IA pleinement active | ≤ 14 |
| Rigid bodies éveillés | ≤ 60 hors scène exceptionnelle |
| Voix audio | ≤ 48 |
| VRAM/mémoire graphique | surveillée, textures mipmappées/compressées |

Ce sont des budgets de départ, pas des résultats à inventer. Un rendu plus simple mais stable est préférable à des effets activés sans mesure.

### 20.3 Profilage obligatoire

Utiliser profiler Godot, moniteurs de performance, debugger, visible collision shapes/navigation en développement, captures frame si disponibles, et logs structurés. Profiler :

- vue d’ouverture ;
- sprint dans l’herbe ;
- camp avec plusieurs ennemis ;
- salle électrique active ;
- arène boss phase 3 ;
- chargement/sauvegarde ;
- transition vallée/donjon ;
- build Web séparé.

Consigner dans `docs/PERFORMANCE.md` : protocole, 60 s minimum par scène, moyenne, p95, 1 % low si calculable, pic mémoire, causes dominantes et corrections.

### 20.4 Monde et culling

- LOD importés ;
- visibility ranges/HLOD ;
- MultiMeshes partitionnés ;
- `OccluderInstance3D` surtout dans donjon, canyon et falaises ;
- ne pas attendre beaucoup d’occlusion d’une plaine ouverte ;
- shadow distance réglée ;
- lumières locales à faible portée ;
- désactiver ombres inutiles des petites particules/props ;
- réduire transparence/overdraw de l’herbe ;
- impostors pour montagnes/arbres très lointains ;
- aucune collision détaillée pour décor non jouable.

### 20.5 Streaming

Pour 500 × 500 m, ne pas sur-ingénier si la scène tient en mémoire sans stutter. Sinon créer `WorldStreamer` : cellules PackedScene 64–128 m, anneau proche actif, anneau moyen visible simplifié, arrière-plan HLOD, `ResourceLoader.load_threaded_request`, activation sur plusieurs frames et aucun chargement synchrone au moment d’un combat.

Précharger la zone suivante dans le couloir d’entrée du donjon. Ne jamais libérer un chunk contenant un projectile/ennemi/objet essentiel actif sans transfert ou résolution explicite.

### 20.6 Optimisations spécifiques

- pools pour flèches/VFX/audio fréquents ;
- éviter `_process` sur nœuds dormants ;
- timers/signaux plutôt que polling ;
- cadence réduite pour perception distante ;
- avoidance seulement proche ;
- shaders sans branches coûteuses inutiles ;
- SDFGI demi-résolution si retenu ;
- volumetric fog portée la plus courte compatible avec l’image ;
- FSR2 ou résolution dynamique uniquement Forward+ après comparaison qualité ;
- mipmap bias contrôlé ;
- pas de texture 4K sur prop secondaire ;
- profiler avant toute micro-optimisation.

### 20.7 Stabilité

- zéro crash sur une session continue de 60 min ;
- zéro erreur récurrente ;
- aucune croissance mémoire inexpliquée ;
- aucun freeze > 100 ms pendant gameplay ;
- pas de stutter répétitif lors d’entrée de zone ;
- reprise après alt-tab/focus ;
- résolution/fenêtrage modifiables ;
- fermeture propre sans sauvegarde corrompue.

### 20.8 Profils de rendu et échelle de dégradation

Ne pas prétendre qu’un seul réglage convient à toutes les plateformes. Maintenir une matrice testée :

| Fonction | High/Cinematic natif | Medium natif | Web Compatibility |
|---|---|---|---|
| Renderer | Forward+ | Forward+ ou Mobile après mesure | Compatibility/WebGL 2 |
| GI | SDFGI ou bake/probes selon scène | LightmapGI/probes ou SDFGI réduit | bake/ambient/probes simples |
| Fog | volumétrique court + distance | volumétrique réduit ou distance | distance/height fog |
| Réflexions | SSR/probes ciblés | probes | probes/cubemap simplifiés |
| AA/upscale | TAA/FSR2 si validé | TAA/FSR2 ou résolution réduite | MSAA/FXAA selon mesure |
| Végétation | densité/ombres complètes mesurées | densité et distance réduites | shader/scatter/ombres simplifiés |
| Électricité | particules + lumières + fog local | moins de lumières/particules | meshes/shader sans dépendance écran |

Dégrader dans un ordre contrôlé qui conserve l’intention : résolution interne → distance/qualité des ombres secondaires → fog volumétrique → SSIL/SSR/GI dynamique → densité des micro-détails → particules → LOD distances. Ne jamais supprimer la citadelle, le contraste chaud/froid, le héros, le chemin, le camp ou l’énergie cyan qui portent la composition.

Chaque option possède coût mesuré, gain visuel comparé et fallback. Changer une seule catégorie à la fois, capturer la même scène, mesurer au moins 60 s et refuser une option dont le coût est élevé mais l’amélioration invisible en mouvement.

### 20.9 Frame pacing, interpolation et latence

Activer et tester l’interpolation physique si elle améliore la cible :

- déplacer presque toute logique de mouvement dans `_physics_process()` ;
- faire traiter animations, tweens et navigation qui déplacent des corps au rythme physique compatible ;
- ne pas écrire des transforms gameplay concurrents depuis `_process()` ;
- appeler `reset_physics_interpolation()` après téléportation, spawn, respawn ou repositionnement instantané ;
- tester temporairement à 10 ticks physiques/s pour révéler immédiatement les objets mal configurés ;
- retester aux taux de production et à 30/60/120 Hz.

Séparer dans le diagnostic : FPS moyen, mauvaise cadence des frames, shader compilation, chargement, garbage/allocations, saturation CPU/GPU, interpolation incorrecte et vraie latence d’entrée. Un compteur à 60 FPS ne prouve pas une animation fluide si des frames alternent 8 et 25 ms.

Consigner histogramme ou série temporelle des frames, p50/p95/p99, 1 % low, nombre de hitches > 33 ms et maximum. Pour la démo, zéro hitch reproductible lors du premier éclair, premier VFX, première arme, entrée camp et transition boss.

Godot Forward+/Mobile utilise des mécanismes de précompilation/ubershader, mais leur efficacité dépend des ressources connues au chargement. Précharger les variantes réellement utilisées et surveiller les moniteurs de pipeline. En Compatibility, où cette approche est limitée, instancier/rendre de façon contrôlée les meshes, matériaux et VFX critiques pendant un écran de chargement approprié, jamais au premier coup en combat. Ne pas compiler du code shader dynamique en runtime dans le build final si une ressource précompilable convient.

### 20.10 Navigation et chargement asynchrone

Pour la navigation :

- baker depuis collisions/formes simples, pas depuis les meshes visuels détaillés ;
- réduire polygones/arêtes inutiles du navmesh : le coût de recherche dépend de leur quantité plus que de la taille physique du monde ;
- ne pas réassigner la même cible ou demander un nouveau chemin à chaque frame ;
- décaler les mises à jour de chemin entre ennemis et limiter avoidance aux agents qui en ont besoin ;
- attendre la synchronisation de la map avant une première requête ;
- utiliser liens/navigation layers pour mantle, sauts ou zones spéciales sans sur-détailler toute la surface ;
- profiler bake, synchronisation, requêtes et avoidance séparément.

Pour le streaming, utiliser `ResourceLoader.load_threaded_request`, interroger le statut et n’appeler `load_threaded_get` que lorsque la ressource est prête ; sinon cet appel peut bloquer. Séparer lecture/instanciation/activation, budgéter leur travail sur plusieurs frames et tester sur stockage lent. Une ressource chargée en arrière-plan ne justifie pas une instanciation massive en un seul frame.

### 20.11 Tests de charge et régression de performance

Créer des modes reproductibles :

- `Perf_Vista` : caméra fixe, végétation, eau, fog, citadelle et éclair ;
- `Perf_Camp` : maximum normal d’IA, feu, projectiles, impacts et loot ;
- `Perf_Electric` : propagation maximale, eau, câbles, lumières et particules ;
- `Perf_BossP3` : attaque la plus coûteuse avec caméra et audio ;
- `Perf_Traversal` : course prédéfinie traversant cellules/LOD/streaming ;
- `Perf_Soak` : boucle 60 min avec sauvegarde/respawn/transitions.

Faire un warm-up documenté, puis enregistrer build, commit, OS, CPU/GPU, driver, renderer, preset, résolution, durée et seed. Comparer au dernier baseline. Une régression > 10 % sur le temps de frame dominant, une hausse mémoire persistante ou un nouveau hitch critique bloque le gate jusqu’à explication. Ne pas rendre les seuils moins exigeants pour faire passer le test sans décision documentée.

Mesurer séparément le temps éditeur et le build exporté ; le verdict final vient du build. Vérifier nombre d’objets/nœuds, ressources chargées, VRAM, allocations, bodies actifs, agents, voix, particules et pipelines. Après cinq cycles vallée↔donjon↔boss, la mémoire doit revenir dans une bande stable expliquée.

---

## 21. TESTS ET OUTILS DE VALIDATION

### 21.1 Test runner

Créer un runner headless sans dépendance payante : scripts d’assertion, scènes de test et code de sortie non nul en cas d’échec. Commandes indicatives, adaptées au nom réel du binaire :

```bash
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_runner.gd
godot --path .
```

Ne pas affirmer qu’une commande a réussi sans l’avoir exécutée.

### 21.2 Tests unitaires minimaux

- stamina clamp, drain et régénération ;
- formule de dégâts ;
- application/remplacement des buffs ;
- recettes compatibles/incompatibles ;
- durabilité et rupture ;
- loot garanti ;
- sérialisation/migration ;
- IDs persistants uniques ;
- graphe avec cycle ;
- interrupteur et propagation ;
- batterie charge/décharge ;
- solvabilité théorique boss.

### 21.3 Tests intégration

- coffre ouvert → sauvegarde → chargement → reste ouvert ;
- arme casse → suivante équipée → sauvegarde correcte ;
- cuisson interrompue sans duplication ;
- circuit déplacé recalculé une seule fois ;
- objet essentiel hors limites respawn ;
- porte centrale après trois circuits ;
- chargement au milieu du donjon ;
- mort pendant une attaque boss ;
- victoire enregistrée ;
- changement périphérique met à jour glyphes.

### 21.4 Tests manuels obligatoires

- tourner caméra contre tous types de murs ;
- gravir une falaise irrégulière et coins ;
- tenter mantle sous plafond ;
- sprinter à zéro endurance ;
- frapper plusieurs ennemis avec un swing ;
- viser près d’un mur ;
- combattre sans lock-on puis avec ;
- attirer IA derrière obstacle ;
- pousser tous objets puzzle hors limites ;
- sauvegarder à chaque étape ;
- finir depuis sauvegarde vierge sans debug ;
- finir avec loot minimal garanti ;
- tester manette et AZERTY ;
- tester Medium/High et Web.

### 21.5 Capture automatisée North Star

Créer une scène ou commande debug qui :

1. charge la vallée ;
2. place heure/lumière/seed ;
3. positionne héros et `VistaCamera_Hero01` ;
4. attend chargement et compilation shaders ;
5. capture un PNG 1440p ;
6. sauvegarde dans `user://captures/` ou un chemin de build documenté ;
7. produit aussi vue camp, entrée donjon, salle électrique et boss.

La capture doit provenir du renderer réel, jamais d’une image générée séparément présentée comme screenshot.

### 21.6 Journal de validation

`docs/STATUS.md` contient pour chaque fonctionnalité : `Non commencé`, `Implémenté`, `Fonctionnel`, `Validé`, `Bloqué`, avec preuve et limite. `docs/TEST_REPORT.md` contient date, build, tests, résultats, erreurs restantes et étapes de reproduction.

### 21.7 Pyramide de validation et commandes déterministes

Créer des commandes courtes et composables :

1. **Parse/import smoke** : projet importe et quitte sans parse error.
2. **Unit** : données, formules, graphes, sérialisation et règles pures.
3. **Integration scene** : quelques systèmes raccordés dans scène minimale.
4. **Golden path** : entrée → camp → cuisine → donjon → boss → victoire.
5. **Visual** : captures déterministes avec GPU/renderer réel.
6. **Performance** : scénarios et métriques exportées.
7. **Soak/export** : build final, session longue, reprise et plateformes.

Une commande `tools/validate_fast.*` doit effectuer les niveaux 1–3 en quelques minutes. `tools/validate_release.*` orchestre les autres lorsqu’un GPU/build est disponible. Adapter les scripts au système présent ; ne pas créer des commandes décoratives non exécutées.

Les hooks Claude Code peuvent lancer format/parse/tests rapides après des modifications pertinentes et un Stop hook peut rappeler qu’un gate rouge interdit « terminé ». Ils ne remplacent pas les tests manuels, ne doivent pas boucler, ni lancer un export long après chaque petit fichier. Les hooks sont versionnés, commentés et sûrs sur chemins contenant des espaces.

### 21.8 Régression visuelle et stabilité temporelle

Pour chaque caméra de référence, fixer seed, transform, FOV, temps, météo, exposition, preset, renderer, résolution et état du monde. Produire un manifeste JSON avec ces paramètres, le hash/commit et le chemin du PNG.

Comparer automatiquement, sans prétendre remplacer l’œil artistique :

- dimensions et absence d’image noire/rose ;
- histogramme/luminance pour exposition cassée ;
- visibilité approximative des focales via marqueurs/projections debug ;
- différence globale pour détecter changement massif inattendu ;
- séquence de 5–10 s pour shimmer, ghosting, LOD pop, clipping, particules et frame pacing.

Les différences normales dues aux GPU/TAA/particules exigent des tolérances et une revue humaine, pas un test pixel parfait. Toute nouvelle baseline doit montrer avant/après, raison et approbation ; ne jamais « réparer » un test visuel en remplaçant silencieusement l’image attendue.

### 21.9 Playtests structurés

Avant le polish final, faire au minimum trois types de session si des testeurs sont disponibles :

- **premières 10 minutes sans aide** : comprennent-ils déplacement, objectif et chemin ?
- **combat isolé** : distinguent-ils télégraphes, i-frames, impact et erreurs ?
- **démo trois minutes** : quel moment retiennent-ils, où l’attention tombe-t-elle, quel défaut casse l’illusion ?

Ne pas expliquer pendant le test. Enregistrer avec consentement : temps, morts, hésitations, trajectoire, actions, bugs et verbatim court ; ne collecter aucune donnée personnelle inutile. Après le test, demander : « Quel était ton but ? », « Qu’est-ce qui semblait le plus beau ? », « Quand as-tu perdu le contrôle ou la compréhension ? », « Quel élément semblait amateur ? », « Que voudrais-tu refaire ? ».

Classer les observations par fréquence × gravité × coût, puis corriger d’abord : blocage, caméra, contrôle, incompréhension, injustice, stutter, rupture visuelle ; le contenu supplémentaire vient ensuite. Ne jamais invalider un problème observé en disant que le testeur « joue mal ».

### 21.10 Triage et conseil de qualité

Chaque bug possède ID, build, environnement, sévérité, étapes, attendu, observé, fréquence, preuve, hypothèse et test de régression. Sévérités :

- `S0` corruption/sécurité/perte de données ;
- `S1` crash, softlock, progression impossible ;
- `S2` système majeur incorrect, caméra injouable, chute majeure de performance ;
- `S3` défaut visible ou contournable ;
- `S4` polish.

Aucun `S0/S1` ouvert pour un build candidat. Un `S2` sur la démo, le chemin critique, la sauvegarde ou la cible matérielle bloque aussi la livraison.

Avant Gate H et livraison, tenir une revue en quatre verdicts indépendants :

| Jury | Question | Condition |
|---|---|---|
| Technique | Est-ce correct, reproductible et maintenable ? | tests/build/logs verts |
| Gameplay | Est-ce contrôlable, lisible, juste et satisfaisant ? | Combat/Traversal gates + playtest |
| Visuel/audio | L’image et le son racontent-ils la même intention haut de gamme ? | WOW score + capture/vidéo |
| Performance | La qualité tient-elle dans le budget réel ? | profils/frametimes/mémoire |

Le verdict final est le plus faible des quatre, pas leur moyenne. Une capture magnifique à 12 FPS ou un jeu fluide mais visuellement provisoire ne passe pas.

---

## 22. ORDRE D’IMPLÉMENTATION OBLIGATOIRE

Ne pas produire tous les assets finaux avant de savoir si le jeu est jouable, mais ne pas attendre la fin du projet pour découvrir que la direction artistique ne fonctionne pas. Procéder par vertical slices successives, avec un benchmark visuel très tôt.

### Phase 0 — Initialisation et réduction des risques

0.1 Inspecter dépôt, versions, outils, licences, matériel et capacités d’exécution/capture.
0.2 Installer le système de continuité de la section 0.3 sans gonfler `CLAUDE.md`.
0.3 Créer commandes de parse/test/capture, scènes laboratoire et journal de recherche.
0.4 Vérifier Godot 4.7.1, renderer, Jolt, Blender/glTF si disponibles et export minimal.
0.5 Importer un cube, un material, un rig/clip test et les relancer depuis un clone/état propre si possible.
0.6 Établir risques classés : art/animation, renderer cible, performance, web, assets, portée et outils.

**Gate 0** : une nouvelle session peut reprendre le travail ; pipeline minimal import→run→test→capture reproductible ; aucune dépendance/licence inconnue critique.

### Phase A — Fondation

1. Initialiser Godot 4.7.1, renderer, Jolt, inputs et arborescence.
2. Créer boot, menu minimal et scène sandbox.
3. Configurer logs, test runner, collision layers et autoloads.
4. Vérifier import headless et lancement.

**Gate A** : projet ouvre/lance, aucun parse error, input AZERTY correct.

### Phase B — Traversal

5. Player CharacterBody3D.
6. Caméra et SpringArm.
7. Locomotion/saut/pentes/steps.
8. Endurance/sprint.
9. Escalade/mantle.
10. Animation placeholder cohérente et probes debug.

**Gate B** : parcours test complet sans blocage ni caméra cassée.

### Phase C — Combat

11. Santé/hitbox/hurtbox/dégâts.
12. Épée, combo, lourde, esquive, lock-on.
13. Arc/projectiles.
14. Inventaire/durabilité/rupture.
15. Premier pillard et boucle combat.

**Gate C** : combat gagnable, une touche par swing, aucune référence invalide.

### Phase C.5 — Micro-verticale et benchmark artistique

15.1 Créer `HeroShotLab` de 80 × 80 m et la première composition North Star.
15.2 Construire un héros original au minimum présentable de dos, un kit herbe/roche/arbre cohérent, eau, camp, pylône, citadelle proxy, sky/nuage/éclair.
15.3 Raccorder traversal, une rencontre, un coffre, une interaction électrique et une courte conclusion.
15.4 Créer lumière, palette, un shader personnage, sol, feuillage, énergie, VFX/audio principaux.
15.5 Capturer fixe et vidéo, mesurer performance, faire la revue contradictoire et itérer.

**Gate C.5** : micro-démo de 60–90 s plaisante, score visuel ≥ 75/100, direction artistique reproductible, aucun défaut d’architecture qui impose de reconstruire tout le contenu. Interdiction d’agrandir la vallée si cette petite scène reste générique, plate ou incohérente.

### Phase D — Monde graybox

16. Terrain 512 m et composition North Star en formes simples.
17. Camp, falaise, rivière, pylône, citadelle et chemins.
18. Huit coffres, ingrédients, checkpoint.
19. Quatre autres ennemis.
20. Partie extérieure complète graybox.

**Gate D** : vue lisible et vallée terminable, sans zone vide injustifiée.

### Phase E — Cuisine/systèmes

21. Récolte/inventaires.
22. Feu/UI/recettes/buffs.
23. Sauvegarde/migrations/persistance.

**Gate E** : collecte→cuisine→buff→save/load validé.

### Phase F — Électricité/donjon

24. Graphe dans sandbox automatisée.
25. Chaque salle grayboxée/testée séparément.
26. Salle centrale et antichambre.
27. Softlock/reset/save tests.
28. Donjon complet.

**Gate F** : quatre salles solvables depuis sauvegarde vierge et intermédiaire.

### Phase G — Boss

29. Arène/pylônes.
30. Boss phase 1, puis 2, puis 3.
31. Solvabilité/durabilité/checkpoint.
32. Victoire/conclusion.

**Gate G** : run complet graybox de 25–40 min sans debug.

### Phase H — Art « wahou »

33. Art Bible et palette.
34. Héros, kit environnement, végétation, eau.
35. Citadelle/pylône/orage.
36. Matériaux/shaders/lumière/fog.
37. Ennemis et boss finalisés.
38. Animations/IK/secondary motion.
39. VFX/audio/UI/cinématiques.
40. Supprimer les placeholders du chemin critique.

**Gate H** : WOW Gate ≥ 85/100 et cohérence sur cinq captures.

### Phase I — Optimisation/livraison

41. LOD/HLOD/MultiMesh/culling.
42. Profiler cinq scénarios.
43. Presets et Web fallback.
44. Session 60 min.
45. Corriger chaque échec.
46. Exports et documentation.

**Gate I** : build candidat reproductible, budgets annoncés réellement mesurés, aucun `S0/S1`, aucun `S2` critique, exports et reprise vérifiés.

### Phase J — Démo, revue externe et release candidate

47. Construire `DemoRoute`, warm-up, sauvegarde de démo et plan de secours.
48. Enregistrer sans coupe une exécution réelle de trois minutes et une partie golden path.
49. Faire tester à une personne qui n’a pas construit le jeu, sans lui souffler les actions.
50. Exécuter revue technique, gameplay, visuel/audio et performance à contexte frais.
51. Corriger les problèmes bloquants, geler le contenu, relancer la validation release.
52. Marquer le build avec version/commit/hash et archiver preuves correspondantes.

**Gate J** : la démo impressionne par composition, fluidité, contrôle et cohérence ; elle ne dépend ni d’un mensonge de capture, ni d’une manipulation cachée, ni d’un asset illégal ; le rapport final correspond exactement au build livré.

Après chaque étape : importer/parser → lancer → reproduire → corriger → retester → mettre à jour `STATUS.md`. Ne jamais avancer avec erreur bloquante.

---

## 23. GATES D’ACCEPTATION

### 23.1 Gameplay

- clavier AZERTY et manette fonctionnels ;
- Q déplace à gauche ;
- entrée mouvement visible au tick physique suivant et latence d’action instrumentée ;
- buffer/cancel/recovery conformes aux ressources de données ;
- caméra ne traverse pas les murs ;
- sprint draine/régénère ;
- escalade et chute à zéro ;
- mantle fiable ;
- dégâts de chute ;
- attaque touche une fois ;
- esquive i-frames ;
- arc ne tire pas à travers mur proche ;
- durabilité/rupture/auto-équipement ;
- coffres persistants ;
- cinq ennemis distincts ;
- aucune vision à travers mur ;
- collecte/cuisine 1–5 ingrédients ;
- buffs réels ;
- objets physiques dans circuits ;
- quatre salles solvables ;
- trois circuits ouvrent porte ;
- objets essentiels respawn ;
- boss trois phases ;
- résistance et conductivité modifient stratégie ;
- partie complète sans debug ;
- démo trois minutes exécutable sans manipulation cachée ;
- sauvegarde/reprise fiables.

### 23.2 Visuel

- WOW Gate ≥ 85/100 ;
- trois plans lisibles ;
- héros, camp, pylône, citadelle reconnaissables ;
- chaude lumière gauche/froid lointain ;
- herbe animée et dense au premier plan ;
- profondeur lisible à 300 m ;
- aucun asset rose/manquant ;
- aucun placeholder sur chemin critique ;
- aucun tiling évident à distance standard ;
- aucun LOD pop majeur 30–80 m ;
- silhouettes ennemies distinctes ;
- VFX électriques à cœur blanc/halo cyan ;
- UI originale ;
- aucun contenu copié.
- `HeroShotLab` ≥ 85/100 avant propagation finale ;
- cohérence vérifiée en vignette, niveaux de gris, plein écran et vidéo ;
- stabilité temporelle sans shimmer/ghosting/pop critique sur le parcours de démo ;
- asset manifest, sources/export et pipeline glTF reproductibles.

### 23.3 Animation/caméra

- aucun jitter critique ;
- pas de foot sliding perceptible en locomotion principale ;
- mains correctement placées sur armes ;
- pas de clipping majeur ;
- mantle aligné ;
- boss dans le cadre ;
- télégraphes visibles ;
- transitions sans pop évident ;
- caméra shake désactivable.
- locomotion et actions testées à 30/60/120 FPS ;
- chaque impact majeur respecte intention→contact→conséquence→résolution.

### 23.4 Technique/performance

- version documentée ;
- build reproductible ;
- zéro parse error ;
- zéro erreur récurrente ;
- zéro crash 60 min ;
- aucune fuite visible ;
- budget frame mesuré sur matériel indiqué ;
- pas de freeze gameplay > 100 ms ;
- IDs uniques ;
- tests automatiques verts ;
- Web utilise Compatibility ;
- aucun plugin payant/compte requis ;
- recherche à fort impact sourcée/versionnée et décisions testées ;
- interpolation/teleports testés, aucun transform concurrent critique ;
- aucun hitch de première utilisation sur le parcours de démo ;
- reprise par une nouvelle session possible depuis les artefacts du dépôt.

Un critère échoué reste `Fail` ou `Bloqué`. Ne pas rebaptiser le build « final » tant qu’un échec critique subsiste.

---

## 24. CINÉMATIQUES ET MOMENTS « WAHOU »

Créer seulement des séquences courtes avec les assets réels :

1. Reveal vallée 5–8 s, puis contrôle immédiat.
2. Premier éclair attirant le regard.
3. Activation du pylône 3–5 s.
4. Ouverture de la porte centrale 5–8 s.
5. Entrée boss 5–8 s.
6. Transition majeure phase 2 ou 3, 2–4 s.
7. Mort boss et apaisement 8–12 s.

Toutes sont passables, ne cassent pas l’état si interrompues, n’utilisent pas d’assets différents du gameplay et rendent la caméra au joueur proprement.

Moments interactifs attendus : herbe qui s’ouvre autour du héros, feu du camp visible à distance, arme qui casse avec feedback net, courant qui se propage physiquement, ascenseur qui démarre, eau électrifiée, pylônes du boss qui mettent à la terre, ciel qui s’éclaircit après victoire.

---

## 25. LIVRAISON

### 25.1 Fichiers

Livrer :

- projet Godot complet ;
- `project.godot` ;
- `CLAUDE.md` concis et éventuelles règles/skills/agents/hooks réellement utilisés ;
- scènes/scripts/resources/shaders/assets nécessaires ;
- sources artistiques critiques, exports `.glb`, scripts d’export et asset manifest ;
- presets d’export ;
- build natif disponible ;
- build Web si possible ;
- `README.md` ;
- `ATTRIBUTIONS.md` ;
- documentation `docs/` ;
- rapports de tests/performance ;
- journal de recherche/décisions/known issues/progress ;
- captures issues du jeu avec manifests reproductibles ;
- vidéo non coupée de la démo trois minutes si l’environnement le permet ;
- dossier `evidence/` relié au build/commit exact.

### 25.2 README obligatoire

Inclure :

1. Version exacte de Godot.
2. Prérequis.
3. Ouvrir `project.godot` puis F6/F5.
4. Commande de lancement native.
5. Contrôles AZERTY/QWERTY/manette.
6. Export macOS/Windows/Linux.
7. Pour Web, servir `builds/web/` via HTTP et ne pas ouvrir simplement `index.html` en `file://`.
8. Architecture.
9. Sauvegardes.
10. Tests.
11. Presets graphiques.
12. Limites honnêtes.

Exemple de serveur local Web, uniquement si Python est disponible :

```bash
python3 -m http.server 8000 --directory builds/web
```

### 25.3 Rapport final de l’IA

À la fin, répondre avec :

1. Résultat concret en une phrase.
2. Version/renderer/plateformes.
3. Arborescence principale.
4. Systèmes réellement validés.
5. Commandes exactes de lancement/test/export.
6. Contrôles.
7. Résultats tests automatisés et manuels.
8. Matériel et profilage réels.
9. Captures/vidéo réelles.
10. Score WOW détaillé.
11. Limites restantes et reproduction.
12. Trois prochaines améliorations prioritaires.
13. Sources techniques consultées et décisions qui en ont réellement découlé.
14. Identifiant exact du build/commit correspondant aux preuves.

Ne pas livrer une réponse qui dit seulement « voici le plan ». Ne pas masquer les échecs derrière « AAA ». Le résultat attendu est une verticale jouable, cohérente, spectaculaire, démontrable et honnêtement validée.

---

## 26. CHECKLIST PASS/FAIL FINALE

| Domaine | Critère | État |
|---|---|---|
| Build | Ouvre et lance sans erreur bloquante | ⬜ |
| Continuité | Une session neuve reprend via CLAUDE/STATUS/PROGRESS | ⬜ |
| Recherche | Décisions risquées sourcées, expérimentées, consignées | ⬜ |
| Loop | Du spawn à la victoire sans debug | ⬜ |
| Démo | Parcours trois minutes fluide, non-triché, sans placeholder | ⬜ |
| AZERTY | ZQSD et Q=gauche | ⬜ |
| Caméra | Aucun mur/jitter critique | ⬜ |
| Traversal | Sprint, saut, escalade, mantle | ⬜ |
| Combat | Une touche par swing, esquive juste | ⬜ |
| Arc | Visée et projectiles fiables | ⬜ |
| Durabilité | Avertissement, rupture, auto-équipement | ⬜ |
| IA | Cinq familles distinctes, LOS réelle | ⬜ |
| Cuisine | 1–5 ingrédients et cinq buffs | ⬜ |
| Électricité | Graphe générique, pas booléens de salle | ⬜ |
| Donjon | Quatre salles et anti-softlock | ⬜ |
| Boss | Trois phases et solvabilité | ⬜ |
| Save | Coffres/circuits/inventaire/boss persistants | ⬜ |
| North Star | Score ≥ 85/100 | ⬜ |
| Look-dev | HeroShot/Lighting/Foliage/Animation/Combat labs validés | ⬜ |
| Art | Aucun placeholder critique | ⬜ |
| Assets | Blender/glTF/import/manifest/licences reproductibles | ⬜ |
| Animation | IK/alignement sans défaut majeur | ⬜ |
| Audio | Feedback des actions importantes | ⬜ |
| Performance | Mesurée et conforme au preset annoncé | ⬜ |
| Frame pacing | Aucun hitch critique de première utilisation | ⬜ |
| Stabilité | 60 min sans crash | ⬜ |
| Web | Compatibility et fallback cohérent | ⬜ |
| Légalité | Assets originaux/licenciés/attribués | ⬜ |

Si une case critique échoue, corriger ou déclarer explicitement le blocage. Ne jamais cocher sur la base d’une intention.

---

## 27. RÉFÉRENCES TECHNIQUES À CONSULTER EN PRIORITÉ

Ces références forment un cursus de départ, pas une excuse pour explorer indéfiniment. Lire la page pertinente au problème, consigner la décision et la prouver dans le projet.

### 27.1 Godot 4.7 — sources officielles

- versions : `https://godotengine.org/download/archive/` ;
- renderers et matrice de fonctions : `https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html` ;
- export Web/Compatibility : `https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html` ;
- Jolt : `https://docs.godotengine.org/en/4.7/tutorials/physics/using_jolt_physics.html` ;
- interpolation physique : `https://docs.godotengine.org/en/4.7/tutorials/physics/interpolation/using_physics_interpolation.html` ;
- jitter, stutter, input lag et pipelines shaders : `https://docs.godotengine.org/en/4.7/tutorials/rendering/jitter_stutter.html` ;
- optimisation 3D/LOD/HLOD : `https://docs.godotengine.org/en/4.7/tutorials/performance/optimizing_3d_performance.html` ;
- GPU : `https://docs.godotengine.org/en/4.7/tutorials/performance/gpu_optimization.html` ;
- MultiMesh : `https://docs.godotengine.org/en/4.7/tutorials/performance/using_multimesh.html` ;
- mesh LOD : `https://docs.godotengine.org/en/4.7/tutorials/3d/mesh_lod.html` ;
- visibility ranges/HLOD : `https://docs.godotengine.org/en/4.7/tutorials/3d/visibility_ranges.html` ;
- occlusion culling : `https://docs.godotengine.org/en/4.7/tutorials/3d/occlusion_culling.html` ;
- volumetric fog : `https://docs.godotengine.org/en/4.7/tutorials/3d/volumetric_fog.html` ;
- SDFGI : `https://docs.godotengine.org/en/4.7/tutorials/3d/global_illumination/using_sdfgi.html` ;
- chargement en arrière-plan : `https://docs.godotengine.org/en/4.7/tutorials/io/background_loading.html` ;
- profiler : `https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/the_profiler.html` ;
- moniteurs custom : `https://docs.godotengine.org/en/4.7/tutorials/scripting/debug/custom_performance_monitors.html` ;
- navigation/performance : `https://docs.godotengine.org/en/4.7/tutorials/navigation/navigation_optimizing_performance.html` ;
- typage statique GDScript : `https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/static_typing.html` ;
- organisation des scènes : `https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html` ;
- formats 3D/glTF : `https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html` ;
- export de scènes 3D : `https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/exporting_3d_scenes.html` ;
- retargeting : `https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/retargeting_3d_skeletons.html` ;
- AnimationTree/root motion : `https://docs.godotengine.org/en/4.7/tutorials/animation/animation_tree.html` ;
- SpringArm : `https://docs.godotengine.org/en/4.7/tutorials/3d/spring_arm.html` ;
- API : classes `AnimationTree`, `SkeletonModifier3D`, `TwoBoneIK3D`, `FABRIK3D`, `LookAtModifier3D`, `ResourceLoader`, `NavigationAgent3D` et `Performance` de la version installée.

### 27.2 Claude Code — sources officielles

- bonnes pratiques, contexte, explore→plan→code→commit et vérification : `https://code.claude.com/docs/en/best-practices` ;
- mémoire et `CLAUDE.md` : `https://code.claude.com/docs/en/memory` ;
- workflows/Plan Mode/worktrees : `https://code.claude.com/docs/en/common-workflows` ;
- sous-agents : `https://code.claude.com/docs/en/sub-agents` ;
- hooks : `https://code.claude.com/docs/en/hooks-guide` ;
- skills : `https://code.claude.com/docs/en/skills` ;
- structure `.claude/` : `https://code.claude.com/docs/en/claude-directory` ;
- agents longue durée et continuité : `https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents` ;
- prompting Claude : `https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices`.

### 27.3 Pipeline de contenu — sources officielles

- exporter glTF 2.0 de Blender : `https://docs.blender.org/manual/en/latest/addons/scene_gltf2.html` ;
- Git LFS : `https://git-lfs.com/` ;
- spécification glTF 2.0 Khronos si un comportement de format est ambigu : `https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html`.

### 27.4 Études de production à transposer avec discernement

- Nintendo, conception systémique et conventions de *Breath of the Wild* : `https://www.gdcvault.com/play/1024562/Change-and-Constant-Breaking-Conventions` ;
- Guerrilla, production végétation entre art et technique : `https://media.gdcvault.com/gdc2018/presentations/gilbert_sanders_between_tech_and.pdf` ;
- animation gameplay/réactivité de personnage : `https://www.gdcvault.com/play/1022074/In-Your-Hands-The-Character` ;
- game feel par code, animation, son, shake et particules : `https://gdcvault.com/play/1022759/Game-Feel-Why-Your-Death` ;
- son au service du game feel : `https://gdcvault.com/play/1022808/Oh-My-That-Sound-Made` ;
- direction artistique stylisée cohérente : `https://gdcvault.com/play/1022182/Order-from-Chaos-The-Art` ;
- éviter le « juice » sans contexte : `https://www.gdcvault.com/play/1020861/don-t-juice-it-or` ;
- tests automatisés de scénarios combat : `https://gdcvault.com/play/mediaProxy.php?sid=1035569` ;
- mystère et densité perçue dans un jeu fini : `https://gdcvault.com/play/1029384/-TUNIC-This-Was-Here`.

En cas de contradiction entre mémoire, tutoriel ou technique d’un autre moteur et la documentation officielle de la version installée, suivre les preuves locales et la documentation correspondante, puis noter explicitement l’adaptation.

---

## FIN DU PROMPT MAÎTRE

Commence maintenant par exécuter la Phase 0 : auditer l’environnement et le dépôt, afficher les versions exactes de Godot/Blender/outils, vérifier l’image de référence, installer les artefacts de continuité, créer les commandes minimales de preuve et lancer un import/capture test. Ne demande pas de reconfirmation pour les décisions déjà fixées. Ne passe jamais à la phase suivante avant le Gate correspondant et sa revue contradictoire.
