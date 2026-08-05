# PROGRESS — journal chronologique et handoff

Ordre **anti-chronologique** : l'entrée la plus récente est en haut. La dernière
entrée fait office de handoff et doit indiquer **exactement** la prochaine action.

---

## 2026-08-01 — A.2 gelé, protocole de validation humaine préparé

**A.2 validé et gelé sur `9414fd0`** par décision du propriétaire.

### Livré

`docs/MANUAL_VALIDATION.md` : protocole en six étapes, écrit pour être exécuté
**sans moi** par une personne disposant d'un écran, d'un clavier AZERTY et d'une
manette. Chaque étape a ses commandes exactes, ses preuves attendues et ses
critères `PASS`/`FAIL` — jamais « vérifier que ça marche ».

`tools/manual_validation_kit.sh` prépare `evidence/gateA/`, y dépose le rapport
d'environnement et un gabarit de rapport à remplir. Son mode `--finalize` écrit un
manifeste (commit, machine, versions, SHA-256 de chaque preuve) et **sort en code 3
tant qu'une preuve manque** — cohérent avec `validate_release.sh`, et empêchant de
clore la campagne sur un dossier incomplet.

`scenes/tests/InputAudit.tscn` : **sans elle, le protocole serait inexécutable.**
À ce stade il n'existe ni joueur ni monde, donc appuyer sur `Q` ne produit rien de
visible. La sonde rend l'InputMap observable et, surtout, interroge la disposition
clavier réelle du système via `DisplayServer.keyboard_get_keycode_from_physical()` :
elle affiche quel nom la disposition courante donne à la position liée à
« gauche ». Sur AZERTY, ce doit être « Q ». L'invariant devient objectif et
capturable, au lieu d'être ressenti.

Quatre tests verrouillent la sonde elle-même : si une action est ajoutée à
l'InputMap sans être ajoutée à la sonde, la validation manuelle testerait un
sous-ensemble sans que personne ne s'en aperçoive.

### État des gates

- **Gate 0** : `GELÉ / ACCEPTÉ AVEC RÉSERVES` (D-006).
- **Gate A** : **`EN ATTENTE`**. Volet automatisable vert — 52 tests. Les six
  contrôles humains sont `NON VÉRIFIÉ`, et `--finalize` le confirme : 13 preuves
  manquantes, code 3.

**La Phase B ne démarre pas.** Elle attend le verdict du Gate A.

---

## 2026-08-01 — Session 1 (suite) — Durcissement du harnais, gel du Gate 0

**Quatre revues adverses à contexte frais, quatre `FAIL`.** Chacune a trouvé des
défauts réels ; trois ont réfuté un correctif de la précédente. C'est le résultat le
plus utile de la Phase 0 : sans elles, un harnais qui ne détectait plus rien aurait
été déclaré vert.

### Défauts corrigés, par revue

- **1re** (D1-D17) : erreur d'exécution comptée « ok » ; test sans reporter avalant
  ses assertions ; `validate_release.sh` vert en sautant des étapes ; capture d'une
  scène vide indiscernable d'une vraie.
- **2e** (N1-N11) : parse error dans un script non référencé → vert ; filtre
  d'erreurs trop étroit (asset supprimé invisible) ; contrat de test contournable ;
  comptage de couleurs ne distinguant pas plein de vide.
- **3e** (B1-B8) : contrat contournable par 3 vecteurs de plus ; `Light3D` compté
  comme géométrie ; perte de couverture par renommage ; fichier de test illisible
  avalé ; « 0 test exécuté » sortant en 0.
- **4e** (Q1-Q8) : `func<TAB>check(` et classe de base intermédiaire échappant au
  scan ; plancher de couverture franchissable par un faux résumé imprimé ; géométrie
  hors champ acceptée ; **deux journaux de preuve produits par une version
  antérieure du code**.

### Les deux corrections de fond

Les tentatives 1 à 3 reposaient sur de l'**inspection statique** — lire le code pour
deviner s'il triche. Toutes ont été contournées. Remplacées par de la **mesure** :

1. **Sonde comportementale du contrat de test** : le runner appelle lui-même les
   quatre méthodes d'assertion et vérifie qu'elles atteignent son enregistreur.
   Ne lit rien, mesure un effet — insensible à la syntaxe et à l'héritage.
2. **Rendu différentiel pour la capture** : la scène est rendue deux fois, dont une
   géométrie masquée, et les images doivent différer. Référence : 1,414 % des pixels.
   Les trois attaques : 0,000 %.

### Décision

D-006 : Gate 0 **gelé, accepté avec réserves** sur décision du propriétaire — pas
`PASS`. La boucle durcissait un harnais contre un auteur de test hostile alors que
le projet n'a aucun gameplay et que son risque dominant est l'art (RSK-01).

### Vérification de clôture (2026-08-01)

| Contrôle | Résultat |
|---|---|
| Arbre Git propre, synchronisé avec l'origine | ✅ |
| `validate_fast.sh` nominal | `RC=0` (compte de tests : voir `docs/TEST_REPORT.md`) |
| `validate_release.sh` nominal | `RC=3` (BLOQUÉ, attendu) |
| Contrat de test — classe de base intermédiaire | `RC=1` ✅ |
| Capture — géométrie hors champ avec ciel | `RC=7`, aucun PNG ✅ |
| Erreur d'exécution dans un test | `RC=1` ✅ |
| Manifeste de capture rattaché à un commit existant | ✅ |

---

## 2026-07-31 — Session 1 — Phase 0 : initialisation et continuité

**Jalon pris** : Phase 0 uniquement, jusqu'au Gate 0. Aucun gameplay.

### Ce qui a été fait

1. **Lecture intégrale** du cahier des charges (2358 lignes), conservé en
   `docs/MASTER_SPEC.md` comme source de vérité.
2. **Audit de l'environnement** : dépôt vide sans commit, Godot absent, Blender
   absent, aucun GPU, aucun affichage, politique réseau restrictive.
3. **Résolution de la disponibilité du moteur.** Les binaires officiels sont
   inaccessibles (egress 403). Après avoir écarté Godot 3.5.2 d'apt (mauvaise
   version majeure) et vérifié que ni PyPI ni npm ne distribuent le moteur, le tag
   `4.7.1-stable` a été trouvé accessible en lecture git et compilé depuis la
   source, épinglé au commit `a13da4fe`.
4. **Système de continuité complet** (§0.3) : les 12 artefacts obligatoires, plus
   `RISKS.md` et `BUILD_ENVIRONMENT.md`. `CLAUDE.md` tenu sous 150 lignes.
5. **Outillage de preuve** : `env_report.sh`, `setup_godot.sh`, `validate_fast.sh`,
   `validate_release.sh`, `test_runner.gd`, `capture_reference.gd`.
6. **Pipeline d'assets Blender → glTF vérifié de bout en bout**, deux bugs réels
   trouvés et corrigés au passage (voir ISS-R01 et ISS-R02).
7. **Réglages moteur vérifiés dans la source du tag**, pas supposés : noms exacts de
   `physics/3d/physics_engine`, `"Jolt Physics"`, `rendering_method`, `CONFIG_VERSION`.

### Ce qui n'a pas été fait, et pourquoi

- **Aucune mesure de performance ni score visuel.** La capture, elle, s'est
  révélée possible via Xvfb + llvmpipe (rendu logiciel) — hypothèse R-004
  infirmée dans le bon sens. Mais llvmpipe interdit toute mesure, et il n'existe
  aucune scène North Star à noter. Gates H, I et J restent bloqués ici.
- **Aucune scène laboratoire** (`StyleLab`, `HeroShotLab`…) : elles n'ont de sens
  qu'avec un rendu, et §7.16 exige de les capturer. Les créer aveuglément
  produirait des coquilles vides.
- **Aucun gameplay** : c'est le périmètre de la Phase A. La consigne était de ne
  pas dépasser la Phase 0.
- **L'image de référence n'a pas pu être versionnée** : fournie dans la
  conversation, pas comme fichier (ISS-003). Son analyse est consignée.

### Décisions prises

D-001 (compiler Godot depuis la source), D-002 (Blender 4.0.2 Ubuntu),
D-003 (`.glb` seul format d'échange), D-004 (validation glTF hors moteur),
D-005 (`validate_release.sh` sort en BLOQUÉ plutôt qu'en faux vert).

### Erreurs commises et corrigées

- Introspection de l'exporter glTF par la mauvaise API : le preset partait vide et
  aucun `.glb` n'était produit. Détecté par le script de validation, pas deviné.
- Dépendance numpy manquante dans le Blender Ubuntu, invisible jusqu'à l'exécution
  réelle de l'export.

Les deux confirment la règle : une chaîne d'outils n'est vérifiée que lorsqu'elle
a réellement tourné.

---

## 2026-08-01 — Jalon B.1 : Player, CameraRig, locomotion

**Gate visé** : B (traversal). **État du dépôt à l'ouverture** : Gate A gelé sur
`9414fd0`, B.0 (couche d'entrée) livré, aucun joueur.

### Changement réel

Un joueur existe et se déplace. `PlayerController` (`CharacterBody3D`), `CameraRig`
(pivots + `SpringArm3D`), réglages dans `resources/tuning/locomotion_default.tres`,
bac à sable `TraversalSandbox.tscn`. 21 nouveaux cas de test, tous pilotés par
`InputIntent` **injectée** : aucune touche simulée, aucun périphérique requis.

### Trois défauts réels, dont deux étaient invisibles

- **La rampe de test était une boîte tournée.** Sa face basse formait un surplomb :
  la capsule passait **sous** la rampe au lieu de la gravir, s'arrêtait net au ras
  du sol, `is_on_floor()` vrai et `is_on_wall()` faux. Aucun drapeau de collision ne
  signalait quoi que ce soit. Trouvé en imprimant position et drapeaux à chaque
  tick, pas en relisant le code. Les rampes sont désormais des **prismes pleins**.
- **Le décalage d'épaule de §8.3 était silencieusement perdu.** `SpringArm3D`
  réécrit intégralement la position de ses enfants directs ; la caméra placée en
  `x = 0,32` revenait en `x = 0`. Rien ne le signalait — ni erreur, ni
  avertissement, ni test rouge. Trouvé en relisant la position **après** quelques
  frames au lieu de faire confiance à la scène (D-014).
- **La caméra s'arrêtait à 0,8 mm du mur.** Techniquement en deçà de la face, donc
  « conforme » ; visuellement dedans. `SpringArm3D.margin` s'est révélé sans effet
  (mesuré à 0,01 / 0,25 / 0,50 : longueur identique). Corrigé par une sonde
  volumique, dégagement mesuré exactement égal au rayon (D-015).

### Deux enseignements de méthode

- **Un contrôle négatif peut mentir.** Muter la valeur par défaut d'un `@export`
  n'a aucun effet si une ressource `.tres` sérialise sa propre valeur : le test
  reste vert et se lit à tort « ce test ne prouve rien ». Il fallait muter le
  `.tres`. Consigné en R-006bis, avec la règle qui en découle.
- **Un commentaire de justification est une affirmation, donc une dette de
  preuve.** Le code affirmait qu'une caméra non-enfant-direct « traverserait les
  murs ». Le contrôle négatif C7 l'a **réfuté** : avec un nœud intercalé à position
  nulle, l'anti-traversée tient. Le vrai mécanisme, isolé par C8, est autre. Le
  commentaire a été réécrit pour dire ce qui a été mesuré, pas ce qui semblait
  plausible.

### Vérification

`tools/validate_fast.sh` → `RC=0`, VERT, plancher relevé à 80. Huit contrôles
négatifs rejoués et archivés dans `docs/TEST_REPORT.md` : chacun casse une défense
et fait rougir le test visé.

### Ce que B.1 ne prouve pas

Le sprint n'a **aucun coût** (§9.1 en B.2). Le ressenti et la latence en ticks
(§10.6) ne sont pas mesurés. Le jitter caméra n'est pas testé. Il n'y a ni modèle
ni animation. Et piloter le contrôleur par intention injectée prouve qu'il n'exige
pas de clavier — **jamais** que la manette fonctionne : `CONTROLLER-001` reste
ouverte et ne sera jamais levée par un test automatique.

---

## 2026-08-01 — Jalon B.2 : endurance

**Gate visé** : B (traversal). **État à l'ouverture** : B.1 livré, sprint sans coût.

### Changement réel

`StaminaComponent` (§5.8, §9.1) et `StaminaTuning`, câblés au sprint. Le composant
ne connaît ni le joueur ni la locomotion : l'escalade (§9.2), l'esquive et
l'attaque lourde (§10.2) s'y brancheront sans le modifier. Le contrôleur prend
**une seule** décision de sprint par tick et la transmet à la caméra, à la vitesse
et à l'endurance — trois recalculs auraient divergé précisément au moment où la
jauge se vide.

20 nouveaux cas de test. Plancher relevé à 100.

### Le défaut que §9.1 ne pouvait pas prévenir

§9.1 décrit ce qui arrive à zéro, mais pas **à quelle condition l'épuisement se
lève**. L'implémentation littérale le levait dès la première unité régénérée :
sprint maintenu, la jauge repartait, le sprint reprenait **un seul tick**, se
revidait. Sept cycles en quinze secondes — le joueur aurait vu sa vitesse osciller
entre 6 et 9 m/s six fois par seconde.

Rien dans le code ne clochait à la relecture : chaque ligne suivait la spec. C'est
le **comptage du signal** `exhausted` qui a nommé le défaut (« attendu 1, obtenu
7 »). Corrigé par un seuil de récupération, marqué comme valeur hors spec et donc à
confirmer par un essai humain (D-016).

### Deux réglages de méthode

- **Un test qui sprinte « 15 s puis mesure » ne mesure pas l'épuisement** mais un
  cycle plus tard : l'effort maintenu laisse la jauge repartir. D'où
  `_drain_until_exhausted()`, qui s'arrête exactement à la transition.
- **Une mesure d'intégration ne doit pas dépendre de la taille du décor.** Vider
  100 d'endurance à 12/s demande 8,3 s, soit 75 m à la vitesse de sprint : le
  joueur quittait le sol du bac à sable et la mesure portait sur une chute. La
  réserve est désormais amorcée basse ; la durée réelle est mesurée côté unitaire,
  où elle ne dépend d'aucune géométrie.

### Vérification

`tools/validate_fast.sh` → `RC=0`, VERT, 100 tests. Huit contrôles négatifs rejoués
et archivés ; N3 reproduit le défaut d'origine et affiche « rafale de 0,017 s ».

### Ce que B.2 ne prouve pas

Les coûts d'escalade, d'esquive et d'attaque lourde sont **déclarés, pas
consommés** — les câbler sans escalade ni combat serait du code mort. Aucune jauge
à l'écran (§17.2), aucun souffle (ISS-004), aucune animation d'épuisement. Le seuil
de récupération n'a été validé par aucun joueur. `CONTROLLER-001` reste ouverte.

---

## 2026-08-01 — Jalon B.3 : escalade et mantle

**Gate visé** : B (traversal). **État à l'ouverture** : B.2 livré, aucune escalade.

### Changement réel

Trois composants, aucun n'appartenant au contrôleur : `ClimbingComponent` (les
trois sondes de §9.2, qui **répondent** au lieu de décider), `LedgeDetectorComponent`
(§9.3, refus nommés) et `ActionAlignmentComponent` (§7.12, celui qui servira aussi
aux coffres, à la cuisine et au pylône). Le contrôleur gagne un `Mode` à trois
valeurs plutôt que la `StateMachine` de §8.1, qui attendra d'avoir des états de
combat à porter (D-018).

L'endurance n'a pas eu à changer : les coûts d'escalade déclarés en B.2 n'avaient
qu'à être appelés, et `can_sustain()` produisait déjà le « lâcher du mur » de §9.1.

23 nouveaux cas de test. Plancher relevé à 124.

### Quatre défauts, dont deux se masquaient mutuellement

- **Le contrôle de dégagement refusait tout rebord dégagé.** Posée pile sur la
  surface d'arrivée, la capsule la touche ; avec 2 cm de marge, tout franchissement
  se déclarait `blocked`. Le piège : le test du plafond **passait** — en accusant le
  rebord au lieu du plafond. Un test vert pour la mauvaise raison est pire qu'un
  test rouge.
- **Le trajet traversait le rebord.** La droite qui relie le pied d'un rebord à son
  dessus coupe le coin ; le contrôle de capsule annulait à mi-parcours, comme il
  doit. Le composant faisait son travail, c'est la forme du trajet qui était fausse.
  D'où `begin_path()` — monter, puis avancer. C'est la réponse à **R-009**, restée
  ouverte depuis le Gate 0.
- **Une bande d'angles ni marchable ni escaladable.** Seuil de paroi à 50°, sol à
  46° : quatre degrés où l'on glisse sans pouvoir s'accrocher. Aucune erreur, aucun
  test rouge. Trouvé en cherchant quelle surface exercerait le filtre d'angle
  (D-019).
- **La branche « surplomb » n'était couverte par aucun test** — révélé par le
  contrôle négatif P2, qui a retiré l'exigence de contact aux pieds **sans rien
  casser**. Un contrôle négatif qui ne casse rien désigne un trou de couverture,
  pas un test robuste.

### Un constat de géométrie qui a corrigé un test, pas le code

Un test devait vérifier qu'une pente à 40° est refusée pour `too_shallow`. Elle est
refusée, mais pour `no_wall` : un rayon horizontal parti de la hauteur du torse ne
rencontre une pente d'angle θ qu'à la distance `1,10 / tan θ`, laquelle dépasse la
portée d'accroche sous environ 57°. Le filtre d'angle ne peut donc rien départager
à l'approche depuis le sol — il agit sur les parois irrégulières rencontrées **en
cours d'escalade**. Le test affirmait une raison qu'il ne pouvait pas obtenir ;
c'est lui qui a été corrigé, et le constat consigné (R-011).

### Vérification

`tools/validate_fast.sh` → `RC=0`, VERT, 124 tests. Huit contrôles négatifs rejoués
et archivés.

### Ce que B.3 ne prouve pas

Le lissage de la normale et la vitesse latérale ne sont **pas testés** — le bac à
sable n'a que des parois planes. « Aucun snap visible » est mesuré, pas vu : aucun
œil humain n'a regardé un franchissement, et il n'y a ni squelette ni animation.
`ClimbRest` et les corniches de repos relèvent du level design. `CONTROLLER-001`
reste ouverte.

---

## 2026-08-01 — Jalon B.4 : franchissement de marche et parcours enchaîné

**Gate visé** : B (traversal). **État à l'ouverture** : B.3 livré ; §8.2 incomplet,
aucun parcours enchaîné.

### Changement réel

`_try_step_up()` — trois sondes, trois refus possibles — et
`scenes/tests/TraversalCourse.tscn`, un tracé linéaire qu'un pilote scripté
parcourt d'un bout à l'autre : sol, marche de 0,32 m, rampe à 40°, saut par-dessus
un vide, escalade d'une tour de 4 m, franchissement du sommet. **§8.2 est
désormais couvert en entier.**

Le parcours est le premier test de `tests/playthrough/`, resté vide depuis le
Gate 0. Il vérifie ce qu'aucun test unitaire ne peut dire : que les capacités
s'enchaînent, et qu'aucune ne laisse le personnage dans un état qui casse la
suivante.

### Deux mesures avant d'écrire une ligne

- **`move_and_slide()` ne monte aucune marche.** Une marche de 0,32 m arrêtait le
  personnage net, `is_on_wall()` vrai, position figée trois secondes, aucune
  erreur. Le franchissement ne pouvait donc pas être un réglage — il fallait un
  shape cast.
- **`is_on_wall()` est faux contre un mur.** Plaqué contre le mur de 6 m du bac à
  sable, poussant depuis deux secondes : `false`. Le franchissement y était
  adossé ; il se serait tu précisément là où il faut décider. Remplacé par une
  comparaison entre distance demandée et distance parcourue (D-020).

### Deux contrôles négatifs non concluants, et pourquoi c'est un résultat

- **Q3** : le retrait *simultané* des deux contrôles censés distinguer un mur d'une
  marche laisse `test_a_tall_wall_is_not_treated_as_a_step` **vert**. Cause
  mesurée : devant un mur plein, la sonde descendante ne trouve aucun sol et la
  fonction refuse avant d'atteindre ses contrôles. Défense en profondeur réelle —
  mais ce test ne valide aucune ligne précise, et sa docstring le dit désormais.
- **Q5** : remettre `is_on_wall()` comme déclencheur laisse la suite verte. **Aucun
  test ne départage les deux déclencheurs.** Le changement repose sur la mesure,
  pas sur un test ; c'est écrit dans D-020 et dans le test concerné.

Les deux logs sont archivés au même titre que les autres. Un contrôle négatif qui
ne casse rien est une information — en B.3 il avait révélé un trou de couverture,
ici il délimite ce qu'un test prouve réellement.

### Ce que le parcours mesure et que rien d'autre ne mesurait

La caméra est sondée **à chaque tick** par une sphère de 12 cm posée au point de
vue : 0 image sur environ 1 400 où l'œil se trouve dans la géométrie. C'est la
formulation la plus directe de §23.1 — non pas que le bras se raccourcisse, mais
que la caméra ne soit jamais dans la roche.

Un filet est posé sous le vide. Il ne fait pas partie du parcours : sans lui, un
saut raté produirait une chute infinie que le test lirait comme « toujours en
mouvement ».

### Vérification

`tools/validate_fast.sh` → `RC=0`, VERT, 129 tests. Cinq contrôles négatifs joués,
trois concluants, deux informatifs.

### Ce que B.4 ne prouve pas

Le parcours est joué par un **pilote scripté, pas par une personne** : il prouve
l'absence de blocage mécanique, pas l'agrément. Le jitter caméra (§8.3) et la
latence en ticks (§10.6) restent hors de portée d'un test headless.
`CONTROLLER-001` reste ouverte.

---

## 2026-08-01 — Jalon B.5 : latence instrumentée, protocole manuel, terrain d'essai

**Gate visé** : B. **État à l'ouverture** : B.4 livré ; il manquait la mesure de
latence, le protocole humain et la revue.

### Changement réel

- **`LatencyInstrument`** (§10.6, §23.1) : pose l'intention entre deux ticks — la
  position temporelle exacte d'un événement de périphérique — et compte les ticks
  jusqu'au premier effet. Mesuré : **1 tick** (16,7 ms à 60 Hz), pire cas sur cinq
  essais, mouvement comme saut, stable. §23.1 (« visible au tick physique
  suivant ») est un chiffre, plus une intention.
- **Protocole Gate B** dans `docs/MANUAL_VALIDATION.md` : six essais (B-1 à B-6)
  couvrant §21.4, le jitter (§8.3) et le ressenti (§10.6), chacun avec but,
  procédure, critère et preuve attendue. Il dit aussi ce que l'automatique prouve
  déjà, pour que l'opérateur ne perde pas son temps à le re-prouver.
- **`TraversalPlayground.tscn`** : le terrain d'essai jouable qui manquait au
  protocole — sandbox + joueur + panneau d'état (endurance, mode, vitesse,
  événements journalisés), souris capturée, lancé réellement en headless (RC=0).
  Lancement documenté : `--debug-collisions`, car le bac à sable n'a pas de meshes.
- **Silhouette graybox** (capsule + nez d'orientation) : le minimum pour qu'un
  opérateur voie le corps et son orientation. Pas un personnage (§7.14).

### Contrôles négatifs

L1 (accélération réduite à l'imperceptible dans le `.tres`) : la mesure passe à
3 ticks, le test rougit. **L2 (réordonnancement `_try_jump()` avant
`_update_timers()`)** : latence de saut mesurée à 2 ticks — c'est exactement la
régression d'architecture que §10.6 vise, une action tardive par ordre
d'exécution. Le test la chiffre : « min 2, max 2, 33,3 ms ».

### Vérification

`tools/validate_fast.sh` → `RC=0`, VERT, 133 tests, plancher 133.

### Ce que B.5 ne prouve pas

Le protocole est **prêt, pas joué** : ressenti, jitter et lisibilité restent
`NON VÉRIFIÉ`. La latence mesurée est celle du pipeline intention → mouvement —
périphérique et écran exclus, comme §10.6 le fait lui-même. La falaise
irrégulière de §21.4 n'est pas jugeable en graybox (essai B-2, rejouer en
Phase D). `CONTROLLER-001` reste ouverte.

---

## 2026-08-01 — Revue contradictoire du Gate B, constats traités, volet automatique clos

**Gate visé** : B. **État à l'ouverture** : B.5 livré, revue à lancer.

### La revue

Menée à contexte frais sur `c31534c`, preuves ré-exécutées (dépôt principal + clone
frais, playground, release) et sondes adverses propres. **Verdict : BLOQUÉ / EN
ATTENTE, aucun `FAIL`** — identique à ma proposition mais établi indépendamment.
Rapport intégral : `evidence/gateB/REVUE.md`.

Elle a démontré ce que mes propres contrôles n'avaient pas vu :

- **fenêtres de saut non défendues** — coyote et buffer mutés à 5,0 s, suite
  verte ;
- **tests de vitesse circulaires** — mesure comparée au tuning lui-même ;
- **poussée diagonale contre la marche jamais franchie** — glissement à ~71 % de
  la distance demandée, déclencheur muet.

### Le traitement, et une découverte en cascade

Quatre tests ajoutés (fermeture de fenêtre, expiration de tampon, épinglage §8.2,
franchissement diagonal), quatre contrôles négatifs V1–V4 tous rouges comme
attendu, plancher à 137.

En corrigeant le déclencheur diagonal, la mesure fondatrice de D-020 s'est révélée
**fausse** : « `is_on_wall()` faux contre le mur » était un artefact — le joueur
avait SAISI le mur (tenu à 0,42 m, aucun contact). Ni moi ni la revue ne l'avions
vu ; c'est la sonde de collisions de glissement qui l'a montré. D-020 porte un
amendement daté, Q5 est caduc (archive conservée intacte), et le déclencheur
définitif écoute les collisions de glissement — présent de face et en diagonale,
jamais sur sol libre.

Constats mineurs traités : convention `RC=` en fin de log (V-série + Q3
régénéré), compte de contrôles retiré de PROGRESS, nombre de ticks sondés archivé
dans le message caméra du parcours, R-012/R-013 consignées.

### Vérification

`tools/validate_fast.sh` → `RC=0`, VERT, **137 tests**, plancher 137.

### Ce que cette clôture ne dit pas

Le Gate B n'est **pas** `PASS`. Les six essais humains restent à jouer, la dette
manette court, et la leçon de la session vaut d'être écrite : deux mesures de
suite ont fondé des décisions — l'une mal interprétée (D-020), l'autre incomplète
(distance vs projection) — et c'est la revue plus une troisième mesure qui les ont
rattrapées. Mesurer ne suffit pas ; il faut mesurer **ce qui discrimine**.

---

## 2026-08-01 — D-021 : Gate B clos pour continuation · Jalon C.0 : fondations de dégâts

### La décision

Product Owner, sur revue rendue : essais manuels (manette comprise) reportés à la
passe finale, limitations GPU non bloquantes, pas de deuxième revue. La revue
n'ayant démontré **aucun défaut bloquant** (ses constats non bloquants étaient
déjà traités), Gate B est clos « **accepté pour continuation, validation humaine
finale différée** » (D-021). Dettes enregistrées : VALIDATION-B-001 s'ajoute à
CONTROLLER-001, toutes deux `S2`, à solder avant toute déclaration `Final`.

### C.0 — changement réel

Le pipeline de §10.1 et la formule de §10.3, en composants : `DamageEvent`
(l'événement complet exigé par la spec), `DamageFormula` (fonction pure, côté
attaquant / côté défenseur séparés), `HealthComponent` (mort idempotente),
`HurtboxComponent` (récepteur pur, point faible déclaré), `HitboxComponent`
(fenêtre active par méthode, set des cibles touchées, attack ID globalement
uniques). 14 nouveaux cas de test, plancher à 151.

Le critère central du Gate C — « une touche par swing » — est prouvé dans les
deux sens : 30 frames de chevauchement → 1 coup, et le contrôle W1 montre 30
coups (santé 100 → 0) dès que le set disparaît.

### Le piège moteur du jour (R-014)

`Area3D.monitoring` coupé puis rallumé entre deux ticks laisse
`get_overlapping_areas()` **définitivement vide** — le second swing d'un
enchaînement ne touchait jamais. Mesuré à la sonde. Correctif : `monitoring`
permanent, la fenêtre active vit dans `_active`, le balayage est coupé hors
fenêtre. C'est le test « deux swings, deux coups » qui l'a attrapé — en C.1 ce
bug aurait été un coup fantôme intraçable en plein combat.

### Vérification

`tools/validate_fast.sh` → `RC=0`, VERT, **151 tests**, plancher 151. Contrôles
W1–W4 archivés avec `RC=`.

### Ce que C.0 ne prouve pas

Personne n'appelle encore `activate()` en gameplay : ni arme, ni ennemi, ni état
d'attaque, ni hurtbox sur le joueur. Poise, recul, élément transportés mais non
consommés ; résistance et armure neutres. C'est le squelette du combat, pas le
combat.

---

## 2026-08-01 — Jalon C.1 : épée, combo, premier échange

**Gate visé** : C. **État à l'ouverture** : C.0 livré, personne n'appelait
`activate()`.

### Changement réel

L'attaque est un contrat de données : `AttackDefinition` (startup / actif /
recovery / buffer / fenêtre de combo / hit-stop, §10.6) exécutée par
`AttackControllerComponent`, trois `.tres` d'épée (multiplicateurs 1,0 / 1,05 /
1,3), mode `ATTACKING` du joueur (locomotion figée, gravité conservée), hurtbox
et santé câblées sur le joueur, `CombatDummy` (45 PV — pillard braise) et
l'embryon du `CombatLab`. 15 nouveaux cas, plancher à 165.

Le premier échange est chiffré : 12 ; 12,6 ; 15,6 ; puis 12 — le combo complet
(40,2) laisse le mannequin à 4,8 PV, le quatrième coup le couche, et son montant
« 12 tout rond » prouve la remise à zéro du combo.

### Trois défauts, trois natures

- **Mon arithmétique** (test) : j'affirmais 40,2 ≥ 45. Le test corrigé prouve
  plus qu'avant.
- **L'infrastructure** : le monde `queue_free` du test précédent survit une
  frame — le joueur apparaissait posé dessus (y = 0,87), chutait, et son premier
  appui était consommé en l'air. Symptôme trompeur (appui unique perdu,
  martèlement OK), diagnostic obtenu par sonde EN CONTEXTE DE RUNNER — la sonde
  isolée « prouvait » que tout allait bien. Règle : attendre l'état, jamais des
  ticks.
- **Le contrat** : un appui 0,1 s avant la fin du combo mourait à l'idle —
  l'entrée avalée que §10.6 interdit. Report de buffer ajouté, borné par le même
  0,15 s, deux tests (frais → relance à zéro ; périmé → rien).

### Vérification

`tools/validate_fast.sh` → `RC=0`, VERT, **165 tests**. X1–X4 archivés avec `RC=`,
dont X4 qui chiffre la perte du terme « attack » de la formule.

### Ce que C.1 ne prouve pas

Personne ne frappe le joueur. Ni esquive, ni lock-on, ni stagger, ni hit-stop, ni
son. `base_damage` provisoire en attendant `WeaponDefinition` (C.3). Le ressenti
reste une dette de passe finale.

---

## 2026-08-01 — Jalon C.2 : esquive, i-frames, lock-on, premier pillard

**Gate visé** : C. **État à l'ouverture** : C.1 livré, personne ne frappait le
joueur.

### Changement réel

L'esquive (§10.2 : quatre directions, i-frames 0,02–0,27 par l'effet, coût de 15
enfin consommé, dodge cancel de la recovery), le verrouillage (§8.4 : cône
caméra, LOS réelle, hystérésis de distance, strafe face à la cible, convergence
caméra sous butées), la poise (transportée depuis C.0, consommée : 2 coups
d'épée étourdissent), et le **pillard braise** — perception en cône par cadence,
télégraphe de 0,8 s, repli après esquive réussie, mort inerte. Le duel complet
de §12.1 tient en assertions : télégraphe mesuré, esquive chronométrée sur
l'annonce, 0 dégât, repli à distance. 21 cas, plancher à 186.

D-018 amendée : l'absorption du Mode a eu lieu **en place** — la machine plate à
cinq états EST celle de §8.1, la version nodale restant un besoin, pas un dogme.
D-022 : pilotage direct sans navmesh, à échéance dure (Phase D).

### Cinq défauts — tous dans MES TESTS, aucun dans le code livré

Masque de hitbox par défaut (assertion verte pour la mauvaise raison, révélée
par le contrôle inverse), pillard posé derrière le joueur (l'épée battait
l'air), course de signaux au setup (annonce manquée), élan résiduel d'esquive
(cible sortie du volume), assertion ignorant la régénération. Détail et leçons :
`TEST_REPORT`, C2-1 à C2-5. Le code livré, lui, n'a pas bougé d'une ligne après
l'écriture — les cinq corrections sont des corrections de mesure.

### Vérification

`tools/validate_fast.sh` → `RC=0`, VERT, **186 tests**. Y1–Y5 archivés avec
`RC=` ; Y5 rougit comportement ET enveloppe, indépendamment.

### Ce que C.2 ne prouve pas

Le joueur encaisse sans réaction (Hurt/knockback/anti-stunlock : C.3). Pas de
changement de cible, ni de présentation (hit-stop/VFX/son). Navmesh et audition
différés (D-022). Le ressenti du duel attend l'essai humain — le CombatLab avec
pillard vivant est prêt pour lui.

---

## 2026-08-01 — Jalon C.3 : attaque lourde, réaction du joueur, arc

**Fait** : l'item 12 de §22 est complet et l'item 13 ouvert. La lourde (×1,8,
poise 25, 20 d'endurance prélevés à l'amorce, refusée à jauge insuffisante), la
réaction Hurt (recul dans la direction du coup, 0,25 s de perte de contrôle,
grâce anti-stunlock 0,85 s qui protège le contrôle mais jamais les PV), l'arc
complet (balistique par balayage CCD, origine-poitrine anti-tir-à-travers-mur,
pool, chute de gravité mesurée, mort à la première victime, visée obligatoire),
et le changement de cible directionnel de §8.4 (sans boucle, jamais à travers un
mur). 14 cas de test, plancher relevé 186 → **200**, `validate_fast` VERT.

**Défaut réel trouvé par la première exécution** : `_on_hit_received` écrit mais
**jamais connecté** à la hurtbox — dégâts passés, réaction morte. Corrigé
(connexion dans `_ready`), rejoué en contrôle négatif (Z5). C'est exactement le
scénario que la doctrine « le test doit pouvoir échouer » existe pour attraper :
sans test comportemental, la réaction serait restée décorative jusqu'au premier
essai humain.

**Défauts de mes tests** : mesure d'endurance polluée par la régénération du
recovery (C2-5 récidivé — mesurer immédiatement après le prélèvement) ; géométrie
du changement de cible comptée depuis le joueur au lieu de la caméra (épaule
x +0,32 — la « gauche » de la caméra n'est pas celle du joueur) et mur trop
étroit que la caméra voyait par-dessus le côté.

**Contrôles négatifs** : Z1–Z6, tous ÉCHEC avec `RC=`, dans
`evidence/gateC/negative_controls/`. Z6 isole l'impulsion de recul : sans elle,
le mode HURT s'ouvre encore et seule l'assertion de déplacement rougit.

**Limites** : arc sans munitions comptées (C.4), pas de réticule ni de
présentation (§10.7), ressenti non prouvé (dette de passe finale), gardes
Hurt-pendant-escalade/mantle non testées.

---

## 2026-08-01 — Jalon C.4 : inventaire, durabilité, rupture

**Fait** : les items 13–14 de §22 sont clos — la Phase C a couvert ses cinq
items. `WeaponDefinition` immuable + les six `.tres` de la table §11.1 ;
`WeaponInstance` (état mutable séparé) ; `InventoryComponent` (8 armes, aucun
doublon, flèches à part). Le `base_damage = 12` provisoire de C.1 est remplacé :
l'export du contrôleur devient la valeur mains nues (3, D-023), l'arme fournit
dégâts ET portée (face avant du volume de frappe posée à `reach_m` — la lance
touche à 2,4 m, l'épée non). Usure au contact seulement, avertissement à 25 %
une fois, rupture qui coupe la fenêtre AU MILIEU du tick, retire l'exemplaire
et équipe la suivante — jusqu'aux mains nues qui restent un état de combat.
Flèches comptées, consommées par tir réel uniquement. 14 cas de test, plancher
200 → **214**, `validate_fast` VERT. Six choix non fixés par la spec actés en
D-023.

**L'invariant de CLAUDE.md est prouvé dans les trois directions** : user un
exemplaire laisse le jumeau ET la définition intacts ; le contrôle AA4
(durabilité écrite dans la ressource partagée) déclenche 15 échecs dans quatre
suites.

**Défaut de MON test attrapé par son propre contrôle** : « à zéro flèche, aucun
tir » restait verte portail retiré — la CADENCE de l'arc bloquait le tir à la
place du compteur (récidive C2-1 : purger tout système de refus concurrent avant
de tester celui qu'on vise). Test corrigé, AA6 rejoué, deux rouges.

**Limites** : durabilité de l'arc (28 tirs) non décomptée — l'arc n'est pas
encore un exemplaire d'inventaire ; pas d'entrée clavier de sélection (API
`equip_next`) ; pas d'usure visuelle/son (Phase H) ; pas de ramassage (coffres,
Phase D).

---

## 2026-08-01 — Revue du Gate C (passe unique, D-024) · Jalon D.0 : la vallée existe

**Revue** : passe unique à contexte frais (décision propriétaire), code jugé
`78f2b9a`, rapport dans `evidence/gateC/REVUE.md`. Quatre critères **PASS au
volet automatique**, rejoués. Constats traités le jour même : **D1 (S2) — la
mort du joueur n'existait pas** (cadavre courant/attaquant/esquivant, pillard
frappant le cadavre sans fin) → `Mode.DEAD` + désengagement du pillard +
régression `test_player_death.gd` rejouant la sonde du réviseur ; D2 — lignes
`RC=` des logs W/X/Y annotées invalides (artefact de capture), sans
régénération ; D3 — garde null. Verdict prononcé : **ACCEPTÉ POUR CONTINUATION
AVEC VALIDATION HUMAINE DIFFÉRÉE** (D-024).

**D.0** (ordonné par D-024, sans laboratoire préalable) : `ValleyWorld.tscn` —
sol 512 × 512 m, spawn sud (§3.3), camp à (45, 0, 65) avec trois pillards, le
coffre garanti du camp (`valley.chest.camp.01`, hache + 12 flèches, jamais de
second loot) et un gourdin ramassable. Le geste d'interaction de §14.2 existe
enfin (2,2 m, cône avant, le plus proche gagne) ; `WeaponPickup` et `Chest`
versent dans l'inventaire de C.4 — inventaire plein = l'objet RESTE, rien n'est
perdu. « Nouvelle partie » (et « Continuer ») entrent réellement dans la vallée
via `SceneFlow`. 7 cas de test, plancher 216 → **221**, `validate_fast` VERT.

**Pièges mesurés** : StaticBody3D ajouté puis déplacé = un tick DANS le joueur,
dépénétration de 0,6 m (positionner AVANT `add_child`) ; les tests du menu
doivent bloquer `SceneFlow` pendant l'appui, sinon la transition réelle
remplace la scène du runner et fige l'arbre en pause.

**Limites** : sol plat sans relief/rivière/pylône/citadelle ; « Continuer »
repart du spawn (état : Phase E) ; pas d'invite d'interaction à l'écran ;
filet anti-chute à −20 m en attendant les bords réels.

---

## 2026-08-01 — Jalon D.1 : relief macro, proxys, navmesh prouvé

**Fait** (portée D-025) : `ValleyTerrain` — blockout déclaratif portant TOUTE la
relation de §3.3 : crête de départ (0, 24, 170), descente en S (3 rampes, 2
paliers, 14–18°), terrasse du camp (45, 6, 65), lit de rivière (bande z 4–16,
deux gués), falaise d'apprentissage ouest (12 m, deux corniches de repos §9.3),
terrasse du pylône (115, 18, −25) et sa rampe, forêt SE (12 troncs à collision),
ruines centrales avec salle en U, plateau monumental (0, 34, −210), rampe
processionnelle, **proxys émissifs du pylône et de la citadelle** — la relation
héros → camp → pylône → objectif se lit depuis la crête. Soleil ouest 22°
(§7.7), ciel/brume §3.4, `VistaCamera_Hero01` à constantes fixes (§21.8).
Navmesh baké versionné (488 polygones, outil `bake_valley_navmesh.gd`) ;
navigation du pillard par requêtes serveur + suivi 2D manuel. 4 tests de
risques critiques (parcours piloté 11 jalons, détour hors d'une salle en U,
filet de chute, spawn/jalons), plancher 221 → **225**, `validate_fast` VERT.
Capture de la caméra de départ : `evidence/gateD/` (commit suivant).

**Pièges moteur, trois sondes** (détail D-025) : le suiveur de
`NavigationAgent3D` compare en 3D contre des hauteurs voxelisées (~0,45 m
au-dessus des pieds) — gel sur place (seuil 0,4), gel au coin (0,8),
réinitialisation d'index en reposant la cible à cadence fixe. Remplacé par
`map_get_path` + avancement 2D. Et une sonde qui interroge l'agent CONSOMME ses
waypoints — instrumenter DANS le code observé. Corrigé aussi en route : une
rampe qui atterrit DANS l'emprise d'un plateau laisse un mur en travers —
atterrir AU RAS du bord (sondé aux points clés, 21 hauteurs vérifiées).

**Limites** : pas d'eau dans le lit, un seul coffre (les 8 + validateur d'IDs :
emplacements définitifs), pas de bords de monde, S de rivière rectiligne,
proxys ≠ art.

---

## 2026-08-01 — Package de playtest D.1, C.5 mis en attente du premier retour humain

**Fait** (ordre propriétaire) : `docs/PLAYTEST_D1.md` — package auto-suffisant
pour un testeur : commit de référence du code jouable (`316e4dd`), Godot
4.7.1-stable exigé et vérifiable, lancement, table AZERTY **honnête** (chaque
ligne dit si l'action a un effet réel : Tab/F/Échap liées mais inertes, manette
jamais validée), limites connues distinguées des bugs (silence total, aucun
HUD — l'endurance invisible est LA confusion prévisible —, mort définitive,
« Continuer » au spawn, proxys). Formulaire de retour dans
`evidence/gateD/playtest01/` : contexte machine, chronologie de mémoire, les
cinq questions de §21.9 au mot près, questions D.1 (lecture de la vallée,
descente, camp, combat, falaise, arc), tableau de bugs S0–S4. README remis à
l'état réel (il annonçait la Phase 0).

---

## 2026-08-01 — D.1R : version corrective après le playtest humain n° 1

**Verdict propriétaire consigné** : D.1 n'était pas jouable (12 constats,
`evidence/gateD/playtest01/FORMULAIRE.md` — retour testeur et audit technique
séparés). C.5 et toute passe artistique SUSPENDUS jusqu'à version corrective.

**Fait**, cinq sous-jalons enchaînés, chacun commité avec ses régressions :

- **D.1R.1 souris/caméra/pause** (`d3a5214`) : capture souris (seam
  `wants_mouse_captured()` — headless refuse CAPTURED, mesuré), 360° de lacet
  (`wrapf`), canaux de regard séparés — `look_mouse` en radians appliqués TELS
  QUELS, `look_analog` en vitesse×delta ; le bug originel était un
  double-échelonnage ÷25. Échap = pause réellement suspensive
  (`tree.paused`), sensibilité persistée `user://settings.cfg` (UserSettings).
- **D.1R.2 corps séparés** (`4ebd987`) : masques joueur 5 (World+Enemy) et
  pillard 7 (World+Player+Enemy) — on ne traverse plus personne ; séparation
  locale des pillards (poussée 1,7 m, morts exclus) — plus de tas ; le détour
  navmesh de la salle en U reste prouvé.
- **D.1R.3 lisibilité** (`c7fb7cd`) : `GameplayShell` (CanvasLayer 64) — HUD
  vie/endurance/flèches/arme+durabilité/verrouillage/réticule/notifications
  (EventBus `gameplay_notification`, D-026) ; invite unique « E — Verbe » avec
  LIGNE DE VUE (paroi = ni invite ni interaction) ; inventaire Tab (8 cases,
  équiper, réordonner) ; molette = arme hors lock, cible pendant lock ; 3
  coffres extérieurs ajoutés (rivière, falaise, pylône — IDs stables, loot
  déterministe) ; feedback graybox : arme visible en main (couleur par type),
  pose d'attaque, télégraphe rouge du pillard, flash de touche, stagger, mort
  visibles.
- **D.1R.4 limites et promesses** (`5d55766`) : anneau montagneux continu
  (BORDER 250→292, h 70, `unclimbable` ; prouvé par 16 rayons — les diagonales
  exigent 200 m de portée) ; filet précoce −6 m + fondu + retour au DERNIER
  POINT SÛR ; interface de mort (Retry → monde-checkpoint via
  `pending_spawn`) ; VRAIE porte de citadelle → vestibule graybox explorable
  (colonnes, omni cyan, porte scellée honnête, sortie → DEVANT la porte).
  Piège moteur : `ValleyTerrain` positionnait ses StaticBody APRÈS `add_child`
  — montagnes-fantômes catapultant le joueur (+4,6 m mesuré). Règle
  position-avant-add_child généralisée à TOUS les générateurs.
- **D.1R.5 « Continuer » honnête** (`b0c681e`) : la vallée applique slot0 à
  son chargement — armes par id + durabilités, arme équipée, flèches, coffres
  ouverts (silencieux) ; autosave sur ouverture de coffre et départ de scène ;
  partie neuve = instantané sans clés d'inventaire → no-op. Aucune duplication
  de loot après rechargement (prouvé).

**Validation** : `tools/validate_fast.sh` VERT après chaque sous-jalon —
251 réussis, 0 échoué. Les 18 régressions exigées mesurent l'EFFET (distances,
positions, états), pas la présence d'un nœud.

**Revue contradictoire consolidée** (`evidence/gateD/REVUE_D1R.md`) : 23
critères rejoués à contexte frais — aucun S0/S1/S2, trois S3 démontrés
(QA-D1R-01 pickup dupliqué après « Continuer », QA-D1R-02 settings.cfg hostile
contournant les bornes, QA-D1R-03 souris recapturée sous l'écran de mort),
**corrigés le jour même** avec une régression chacun → **254 réussis,
plancher 254**. QA-D1R-04 (S4) : surdéclarations de TEST_REPORT corrigées.

**Hors périmètre maintenu** : cuisine, salles électriques, boss, art/animation/
audio finaux, optimisation, manette.

---
## 2026-08-01 — Passe visuelle V4.1 (lots V4.0 → V4.6)

**Ordre propriétaire** : D.1R validé pour continuation (playtest de contrôle
sans blocage), pack visuel V4 (5 images) érigé en référence d'autorité —
installer le langage visuel dans la VRAIE build sans toucher aux systèmes
D.1R. Le ZIP binaire n'a pas atteint le conteneur : provenance et lecture
consignées (`source_assets/concepts/final_v4/README.md`, ART_BIBLE §1bis),
PNG à déposer.

**Livré, un commit poussé par lot** :

- **V4.0 (`b777772`)** : provenance + lecture d'autorité + état initial
  (capture baseline, minutage llvmpipe indicatif).
- **V4.1 (`ccaa4c7`)** lumière/atmosphère : soleil #FFD68A + ombres, horizon
  réchauffé, filmic + glow faible seuil haut, brume étagée (aerial 0,35,
  densité 0,0009 — la première passe NOYAIT le plan moyen, ÷2), brume basse
  y<6, StormCell : orage LOCAL (8 grumeaux disable_fog, voile de pluie,
  éclair déterministe cœur blanc/halo cyan, tenu en mode vista — llvmpipe :
  ~250 ms/frame réels, la cadence temps-réel échappait à la capture), motes.
  3 itérations sur capture.
- **V4.2 (`42e1c87`)** terrain/limites/profondeur : eau turquoise en S dans
  le lit (visuel sans collision), chemins des deux routes, variations de sol,
  pics en TENTES sur deux rangées (lointaine bleuie) plafonnés derrière la
  citadelle, 8 contreforts physiques unclimbable (navmesh 646), prairie §7.5
  partitionnée en GRAPPES de touffes (3 quads croisés) sur la bande avant de
  la crête + fleurs. Piège : le RenderingServer headless ne relit pas les
  tampons MultiMesh → seam origins/tints.
- **V4.3 (`6e67ef8`)** repères : camp habité (3 tentes physiques, foyer
  chaud), pylône ouvragé (socle/anneaux/runes émissives), façade monumentale
  (gradins DERRIÈRE le plan de la porte, piliers à conduits cyan, linteau,
  braseros, marches mesurées ≤ 0,31 m), vestibule 22 × 26 m à 6 colonnes et
  4 braseros contre la veine cyan du seuil scellé. Navmesh 749.
- **V4.4 (`370cdec`)** HUD (réf. 03) : HudStyle source unique — vie en 5
  RUBIS (somme affichée = seam), endurance turquoise pendant l'usage
  seulement, plaque de cible à la vraie vie de l'ennemi, carte d'arme à
  durabilité SEGMENTÉE, invite en cartouche, notifications sur plaque.
- **V4.5/V4.6 (`4289d5e`)** inventaire (réf. 04) : grille 2 × 4, huit cartes
  (vides estompées), détail véridique (dégâts/portée/durabilité/conductivité
  comparés à la .tres par le test) ; pause sur plaque centrée par ancrage,
  monde visible ; rien d'inexistant affiché.

**Validation** : `validate_fast` VERT après CHAQUE lot — **270 réussis,
plancher 270** (+12 régressions V4 qui mesurent l'effet). Lancements réels
Xvfb sans erreur de script après chaque lot. Perfs llvmpipe INDICATIVES
consignées (`evidence/passeV4/baseline/perf_indicative.txt`). Captures
par lot dans `evidence/passeV4/` avec manifestes.

**Hors périmètre tenu** : aucun système D.1R réécrit, pas de décor définitif
au mètre carré, pas de personnages finaux, pas de donjon complet.

---

## HANDOFF — prochaine action exacte

> **Gates** : A `RÉSERVE` (D-012) · B `CONTINUATION` (D-021) · C
> `CONTINUATION` (D-024) · D **en cours** — D.1R corrigé post-revue, Passe
> visuelle V4.1 livrée (V4.0 → V4.6).
> **C.5** : la Passe V4 en tient lieu sur la crête réelle — la notation
> §3.5 sur capture et le verdict appartiennent au REGARD HUMAIN.

### Action suivante : playtest humain n° 2 (hors conteneur)

1. Suivre `docs/PLAYTEST_D1R.md` (contrôles inchangés) — le build a EN PLUS
   l'atmosphère V4 : orage local, éclairs, eau, prairie, chemins, camp
   habité, façade monumentale, HUD rubis, inventaire en grille.
2. Vérifier les 12 constats du n° 1 ET la lisibilité V4 (trois plans, orage
   localisé, routes guidantes, HUD discret).
3. Déposer le retour dans `evidence/gateD/playtest02/FORMULAIRE.md`.

### ART-P0 livré (2026-08-01, plus récent) — ARRÊT pour validation

> Décision propriétaire : audit validé, stratégie hybride, premier asset =
> l'ÉPÉE USÉE de bout en bout. **Livré** : `SM_WornSword` — création
> originale procédurale (tools/blender/make_worn_sword.py, seed fixe,
> 414 tris, lame patinée à entailles de silhouette, garde bronze
> asymétrique, poignée cuir à gorges, pommeau vieilli, goupille+pastille
> ivoire, ZÉRO cyan), textures 512 BaseColor+MR générées, .blend 448 Ko /
> .glb 190 Ko (Git LFS INDISPONIBLE — vérifié — donc tailles contenues),
> gltf_inspect VALIDE, icône RENDUE du modèle (256, fond transparent).
> Intégré sans toucher un chiffre de gameplay : en main (WeaponModel via
> mesh_scene, usure < 25 % par instance), au sol (pickup), inventaire
> (icône carte + détail), repli boîte CONTRÔLÉ pour les armes sans modèle.
> validate_fast VERT 276/276 (6 régressions ART-P0, plancher 276), vallée
> et inventaire lancés réellement sans erreur. Captures gate :
> evidence/artP0/ (Blender, Godot socle/usée/sol/main, inventaire).
> S4 consigné : la plaque d'inventaire se cale en haut-gauche sous le
> harnais de capture (CenterContainer ajouté ; position à vérifier sur
> poste). **Le verdict du gate visuel est HUMAIN — arrêt : ni héros, ni
> autres armes, ni remplacement massif avant décision.**

### Verdict propriétaire sur la Passe V4 (2026-08-01, plus récent)

> Infrastructure technique et fonctionnelle ACCEPTÉE ; gate artistique
> **REFUSÉ** — un graybox décoré de primitives n'est pas la cible V4.
> Livré en réponse : `docs/assets/ASSET_READINESS_AUDIT.md` (inventaire
> complet, primitives vs production, manquants, créer/acquérir/remplacer,
> licences/formats, risques). Les 5 PNG V4 ne peuvent PAS être déposés
> depuis le conteneur (jamais arrivés sur disque — vérifié) : dépôt à faire
> depuis la machine du propriétaire. **ARRÊT — aucune couche artistique
> supplémentaire avant validation de l'audit et décision propriétaire.**

### Rappels

- Rebaker le navmesh après TOUTE modification du relief (749 poly).
- Pièges frais : position-avant-add_child ; tampons MultiMesh illisibles en
  headless (seam origins/tints) ; cadence Timer temps-réel vs frames
  llvmpipe (~250 ms) ; PrismMesh : arête le long de Z ; plaques UI ancrées
  centre, jamais par `position` avant le premier layout.
- `MIN_TESTS` = 270 ; compte de référence dans TEST_REPORT uniquement.
- Le pack V4 binaire reste à déposer dans `source_assets/concepts/final_v4/`.

## 2026-08-02 — E.2 (fondations) : règles de cuisine et effets d'état

> **Logique pure livrée AVANT le câblage** (interrompu par l'ordre de nuit
> V3 — acquisition Quaternius prioritaire). `RecipeRules.cook()` (§13.4 :
> soin sommé clampé 100, familles majeures, ragoût instable ×0.3, durée
> 60+30/compatible+45/épice max 300 — D-027) et `StatusEffectComponent`
> (§13.5 : un seul buff, remplacement signalé, minuterie `_process`
> pausable, multiplicateurs 1.25/0.75/1.6/0.4, snapshot/restore
> primitives). 7 tests unitaires purs ; plancher 285 → **292**.
> **RESTE À FAIRE (reprise E.2)** : meal_pressed dans l'intent,
> multiplicateurs câblés (hitbox/hurtbox/stamina), _meals en inventaire,
> composant dans Player.tscn, _eat_quick_meal, autosave meals/buff,
> label HUD, tests d'intégration.

## 2026-08-02 (nuit) — ART-Q0 : acquisition Quaternius + 11 ids livrés

> **Acquisition** : les 7 archives depuis la Release GitHub
> `asset-inbox-quaternius-free-v1` (canal API + curl), SHA-256 identiques
> aux digests GitHub, `unzip -tq` OK, zéro chemin dangereux, licences
> **CC0 1.0 lues dans chaque archive**. Zone : /tmp, jamais dans le dépôt.
> **Ingestion** : 12 modèles copiés à l'octet près (~101 Mo, max 12,7 Mo/f),
> inscrits dans ATTRIBUTIONS + MANIFEST AVANT import ; `gltf_inspect`
> étendu au .gltf texte (mêmes contrôles) ; import headless zéro erreur.
> **Livraison** : 11 wrappers .tscn aux chemins réservés du registre
> (arbres ×2, rochers ×2, buisson, coffre/caisse/tonneau, porte/mur/colonne).
> Héros `Male_Ranger` importé en CANDIDAT (préview calibration, étiqueté) —
> câblage animé = ART-Q1. **Squelette héros = squelette UAL (65 os,
> différence ensembliste vide, vérifié par script)** : retargeting direct.
> Tests 292 → **294** (ids livrés montent des maillages réels ; rig du
> héros survit à l'import). Captures : evidence/artQ0/ (2 lumières,
> manifestes). tent/campfire ABSENTS des packs — consigné, options Q3.
> **PROCHAINE ACTION (ART-Q1)** : ingérer UAL1/UAL2 in-place + créer
> HeroVisual.tscn animé (12 états via CharacterAnimSet), sockets main/dos,
> capsule autorité, root motion neutralisé documenté par clip.

## 2026-08-02 (nuit) — ART-Q1 : héros riggé vertical LIVRÉ

> UAL1+UAL2 in-place ingérés (.glb, 65 os = squelette Ranger).
> `bake_hero_animations.gd` cuit AL_HeroStates.res : 12 états, bouclage
> EXPLICITE, **audit root motion par clip** (boucles fermées à 0,000 m ;
> one-shots = déplacement de POSE documenté, ex. Death01 0,81 m corps
> couché ; seuils : boucle 0,05 m / one-shot 1,2 m anti-_RM ; zéro piste
> de position de nœud). `HeroVisual.tscn` = Male_Ranger + AnimationPlayer
> (root_node→modèle, chemins de pistes identiques) + sockets
> SOCKET_HAND_R/SOCKET_BACK/SOCKET_BOW (hand_r/spine_03/hand_l).
> Player.tscn : CharacterVisual (char.hero) + PlayerVisualDriver — mode et
> vitesse RÉELS → clips ; graybox masqué ; **capsule intouchée** ; épée
> dans la MAIN (pivot sous le socket, prise (90,0,0) retenue par balayage
> de 6 orientations par capture) ; balayage procédural et tilt de mort
> coupés quand le modèle est monté (Death01 couche le corps).
> Régression corrigée : chemin dur `VisualRoot/WeaponPivot` dans
> test_hud_and_inventory (cascade de 19 tests) → find_children.
> Tests 294 → **300**. Lancements vallée + vestibule 300 frames zéro
> erreur script. Preuves : evidence/artQ1/ (audit JSON, calibration,
> vallée héros de dos, épée main/attaque).
> **PROCHAINE ACTION (ART-Q2)** : pillard animé sur la VRAIE IA
> (raider_red) + 2 variantes de teinte, mêmes contrats (capsule, hitbox).

## 2026-08-02 (nuit) — ART-Q2 : pillard animé sur la vraie IA + variantes

> Male_Peasant ingéré (12 894 tris, 65 os ; textures Peasant RÉDUITES
> 4K→2K par Blender — budget §7.10 ennemi standard, réduction mécanique
> documentée au manifeste). Outil de cuisson GÉNÉRALISÉ
> (bake_character_animations.gd) : AL_RaiderStates (11 clips, attaque =
> Melee_Hook — grammaire distincte de l'épée du héros, §12), audit root
> motion evidence/artQ2/. Wrappers RaiderRed/Blue/BlackVisual (teintes de
> faction par instance, matériaux dupliqués §5.4) ; CharacterModelSockets
> généralisé (ex-HeroVisualModel) + teinte. RaiderRed.tscn RÉEL :
> CharacterVisual sous Pivot, graybox masqué, gourdin REPARENTÉ dans la
> main animée (même grammaire de prise que l'épée), télégraphe §12.1
> refondu sur les matériaux ACTIFS (survit au masquage du graybox),
> bascules procédurales (mort, étourdissement) coupées sous modèle —
> Death01/Hit_Chest portent. Clips pilotés par le signal state_changed
> (zéro polling). **Bug moteur compris et traité** : la mise à jour
> différée du RenderingServer citait des matériaux teintés déjà libérés
> (« material is null » headless) → surcharges vidées à la sortie de
> l'arbre (NOTIFICATION_EXIT_TREE). Tests 300 → **304**. Captures :
> calibration 18 socles, 4 personnages teintés distincts.
> **PROCHAINE ACTION (ART-Q3)** : camp props production (coffre/caisse/
> tonneau déjà livrés : les brancher dans la vallée en préservant IDs,
> loot, interactions ; feu de camp composé ou graybox documenté).

## 2026-08-02 (nuit) — ART-Q3 : props de production au camp

> **Coffre réel** : le modèle Quaternius est RIGGÉ avec ses clips
> (Chest_Open/Chest_Opened/Close) — chest.gd le monte via le registre,
> masque son graybox, garde sa collision, joue Chest_Open à l'ouverture
> et la POSE Chest_Opened à l'application d'état (§19.4, sans loot ni
> geste). IDs, loot garanti, atomicité inventaire-plein : INTACTS
> (tests). **Camp** : 2 caisses + 2 tonneaux de production en obstacles
> physiques (repli graybox conservé), anneau de 8 galets autour du foyer
> (Pebble_Round_1-3 ingérés, texture PathRocks 1K). Caméra de contrôle
> reproductible du camp (VALLEY_CAMP=1, §21.5 « vue camp »). Les
> pillards du camp portent AUTOMATIQUEMENT le modèle Q2 — la capture
> montre trois pillards braise animés, gourdin en main. Tentes : AUCUN
> asset dans les 7 packs — PrismMesh graybox conservé, documenté.
> Tests 304 → **307**. Capture : evidence/artQ3/camp_props.png.
> **PROCHAINE ACTION (ART-Q4)** : biome nature composé (arbres/buissons/
> rochers réels dans la vallée, pas de dispersion uniforme, navmesh
> rebaké 749 poly à revalider).

## 2026-08-02 (nuit) — ART-Q4 : biome nature composé

> Forêt : les 12 troncs graybox gardent leurs COLLISIONS (le navmesh et la
> preuve de navigation ne bougent pas d'un polygone — suite verte), les
> visuels sont les vrais arbres (large/medium alternés en motif
> irrégulier, lacet à l'angle d'or, échelle variée — testé : ≥10 lacets et
> ≥8 échelles distincts). « Phrases » végétales §7.17 : lisière de forêt
> (3 buissons serrés + isolé), cadrage de crête, langue de galets au coude
> de rivière, 2 rochers-obstacles au pied de la falaise — groupes
> délibérés, test de composition (voisin < 3 m ET vide > 15 m). Un asset
> manquant laisse un VIDE, jamais une boîte. Tests 307 → **309**.
> Captures : evidence/artQ4/ (vista + camp avec forêt réelle).
> **PROCHAINE ACTION (ART-Q5)** : architecture pénétrable — façade
> citadelle + vestibule avec les modules pierre (porte/mur/colonne),
> système de scène préservé.

## 2026-08-02 (nuit) — ART-Q5 : architecture pénétrable

> Vestibule : les SIX colonnes graybox gardent leurs collisions boîte ;
> le visuel est une PILE de trois modules de pilier (3×3,04 m ≈ 9,1 m,
> lacet alterné par segment — le module étant une pièce d'angle, la pile
> lit « tour brute » ; candidate à l'harmonisation Q6, verdict humain).
> Seuil scellé encadré du portail de pierre (×2,3). Façade vallée : la
> MÊME arche à l'échelle monumentale (continuité de matière) + deux
> piliers de flanc au pied des marches. SceneDoors aller/retour, cotes
> et volumes d'interaction : INTACTS (testés). **Correctif au passage** :
> la retenue de réception du pilote visuel comptait en ms murales —
> instable en headless rapide ; passée en TICKS physiques (§20.9).
> Tests 309 → **311**. Capture : evidence/artQ5/vestibule_modules.png
> (contraste ambre/cyan §7.8 sur vraie pierre).
> **PROCHAINE ACTION (ART-Q6)** : cohérence lumière/matériaux/palette V4
> sur les captures de référence (vista, camp, vestibule, calibration).

## 2026-08-02 (nuit) — ART-Q6 : cohérence palette V4

> Teinte SÉLECTIVE par matériau (tint_material_filter) : le héros teinte
> sa tenue MI_Ranger vers le turquoise (§7.11 : « le turquoise relie le
> héros à la citadelle » — accents épaulière/sangles/bottes répondant au
> cyan de la porte/éclair/pylône dans la vista), la PEAU reste vierge
> (testé). Choix (0.38, 0.92, 1.7) par balayage de 3 candidates en
> capture. LIMITE honnête : la capuche saturée résiste au multiplicatif
> (pas de bleu dans la texture à amplifier) — re-texture complète =
> décision humaine de Phase H, consignée. Paquet de référence Q6 :
> evidence/artQ6/ (vista, camp, vestibule, calibration lumière vallée),
> même état, mêmes caméras — la base de la revue Q7. Tests 311 → **312**.
> **PROCHAINE ACTION (ART-Q7)** : revue contradictoire à contexte frais,
> corrections S0/S1/S2 (+S3 contraires à l'ordre), package playtest.

## 2026-08-02 (aube) — ART-Q7 : revue contradictoire PASS, package playtest

> Revue adverse à contexte frais sur f9a0e0d..ed39f8e : **PASS global,
> zéro S0-S3** (evidence/artQ7/REVUE.md — acquisition recoupée
> INDÉPENDAMMENT via l'API GitHub, stats gameplay au diff VIDE, plancher
> strictement croissant, validate_fast rejoué 312/312). Quatre S4
> traités : repo_dirty resserré aux fichiers SUIVIS (capture_reference),
> paquet de référence recapturé post-commit, ISS-013 (bbox skinnés) et
> ISS-014 (couture WEAPON_GRIP, à retirer Phase I) consignés, audits de
> bake régénérés. Package playtest SANS ZIP : docs/PLAYTEST_ARTQ.md —
> le dépôt est le package. STATUS/TEST_REPORT à jour.
> **PROCHAINE ACTION** : reprise du prompt maître — E.2 (cuisine/buffs) :
> câblage des fondations déjà commitées (meal_pressed, multiplicateurs
> hitbox/hurtbox/stamina, _meals, StatusEffect dans Player.tscn,
> _eat_quick_meal, autosave meals/buff, label HUD, tests).

## 2026-08-02 (aube) — E.2a : plats et buffs câblés (reprise prompt maître)

> Sur les fondations E.2 (f9a0e0d) : `meal_pressed` (intention + lecteur,
> action `quick_meal` de §8.5), plats FIFO bornée (6) en primitives dans
> l'inventaire (§11.3 « plats séparés »), StatusEffectComponent dans
> Player.tscn, `_eat_quick_meal` (soin TOUJOURS appliqué, buff majeur
> remplacé, plat consommé UNE fois), multiplicateurs §13.5 propagés PAR
> SIGNAL (hitbox ×1.25 infligé, hurtbox ×0.75 reçu AVANT émission,
> stamina ×1.6 régén) et retombés à l'expiration. Autosave : "meals" +
> "buff" (déclencheurs meals_changed ET buff_applied — le buff s'applique
> APRÈS le prélèvement du plat, mesuré par le test de rechargement).
> 3 tests (25 assertions) sur le VRAI joueur et la VRAIE vallée ; plancher
> 312 → **315**. **RESTE (E.2b)** : UI de cuisine au feu de camp
> (sélection 1-5, aperçu §13.3), label de buff au HUD (§17.2), déclencheur
> feu de camp. Les règles pures (RecipeRules) sont déjà testées.

## 2026-08-02 (nuit V4, lot 1) — correctif : expiration de buff persistée

> Défaut CONFIRMÉ par test rouge : `buff_expired` remettait le composant à
> neutre mais ne produisait AUCUN instantané — le buff sauvegardé à
> l'application ressuscitait au rechargement avec tout son temps et son
> multiplicateur (×1.25 mesuré). Correctif : `buff_expired` → autosave
> (valley_world). Testé : expiration pilotée → rechargement → aucun buff,
> aucun multiplicateur résiduel ; le remplacement restait couvert. Aucune
> valeur de gameplay modifiée. Plancher 315 → **316**.

## 2026-08-02 (nuit V4, lot 2) — catalogue exhaustif automatisé

> `tools/catalog_quaternius.py` (reproductible depuis la Release) : **2162
> entrées brutes traitées à 100 %** — 805 DOUBLON_FORMAT (FBX/OBJ/copies
> Unity-UE), 495 SOURCE_TECHNIQUE (bins/licences/blend/mtl), 359
> DOUBLON_CONTENU (hash identique), 4 VARIANTE_ROOT_MOTION, 81 GALERIE
> (textures), 61 UTILISÉ_RUNTIME, et **375 modèles canoniques scorés**
> (grille §7 transparente, mots-clés lisibles dans le script) : 249
> CANDIDAT_RUNTIME (≥65), 102 À_ADAPTER, 6 REJETÉ. Métriques réelles par
> modèle (tris, bbox TOUS meshes, matériaux, os, clips). Sorties : JSON
> (946 Ko), CSV, CATALOG_REPORT.md. Le score est un TRI préparatoire —
> le verdict artistique reste humain.

## 2026-08-02 (nuit V4, lot 3) — promotion massive, index direct, galerie

> `tools/promote_quaternius.py` + `docs/assets/PROMOTIONS.csv` (sélection
> commentée par zone, rejouable depuis la Release) : **113 nouveaux modèles
> promus** (265 fichiers, 76,5 Mo — nature 30, rochers 8, props 43,
> architecture 32), import Godot ZÉRO erreur, 119 lignes de manifeste
> générées depuis le catalogue. `AssetRegistry.model(nom)` : index
> paresseux nom canonique → PackedScene (jamais 130 constantes à la main).
> Galerie paginée `AssetGallery.tscn` (§8) : 12 modèles/page, catégorie/
> page/espacement par environnement, promus depuis le dépôt + candidats
> depuis l'extraction (GLTFDocument runtime), échec d'asset = jalon orange
> consigné. **35 planches-contact** capturées (toutes les pages de toutes
> les catégories) : evidence/v4lot3/. Tests : index ≥110 + page pleine
> sans perte. Plancher 316 → **318**.

## 2026-08-02 (nuit V4, lot 4) — zones A/B/C : crête, descente, prairie

> Système de placement par zone (`_place_model`/`_dress_zone`) sur la
> topologie INTACTE : crête (cadre latéral d'arbres, rochers héroïques,
> premier plan fleuri — **couloir de vista x −12..12 vide de toute
> silhouette haute, TESTÉ**), descente (bornes de pierre aux paliers,
> buissons aux bords EXTÉRIEURS, jalons verticaux — jamais rien sur l'axe
> de course), prairie (arbres isolés à collision de tronc, bouquets
> groupés avec vides, herbes de berge, galets du gué ouest). 51
> placements, ~25 modèles distincts. Correction sur capture : l'arbre
> tordu ROUGE quittait l'axe de la citadelle pour marquer le coude ouest
> (accent hors axe, §11.A). Caméra de contrôle DESCENTE (VALLEY_DESCENT).
> Tests zones+couloir. Plancher 318 → **320**. evidence/v4lot4/.

## 2026-08-02 (nuit V4, lot 5) — le camp habité

> `_dress_camp_life` : 30 éléments — cuisine (chaudron SUR le foyer, table
> dressée avec pot/tasse/bouteille/carotte, banc, tabouret, seau), réserve
> (tonneau de pommes, cageots, sacs), coin de travail (enclume, billot +
> hache, pierre à affûter, corde), râtelier d'armes + épée + bouclier,
> charrette et bannière à l'entrée, clôture PARTIELLE au nord, abri
> ASSEMBLÉ (panneau de toit incliné + couche + chandelle — un pillard dort
> là). Aucune entité gameplay dupliquée (feu, coffre, viande intouchés,
> §11.D). Test : 30/30 maillages réels. Capture : evidence/v4lot5/.

## 2026-08-02 (nuit V4, lots 6-7) — forêt et rivière

> Forêt (§11.E) : +6 troncs à collision (feuillus, morts-bois au nord,
> pin de lisière est) — le couloir diagonal (60,50)→(90,28) reste
> praticable ; sous-bois aux pieds des troncs (fougères, grandes plantes,
> trèfles), lisière ouest en phrase de buissons, ronde de champignons
> (repère 1), ruine-curiosité arche+briques+lierre (repère 2). Rivière
> (§11.F) : arbre tordu penché au coude ouest (près du coffre-corniche
> existant, récompense route 2), roseaux de berge, 4 pierres émergentes
> HORS des gués, bivouac abandonné au gué est (seau renversé, corde,
> bouteille). 41 placements. Tests de zones étendus (26 + 15).

## 2026-08-02 (nuit V4, lots 8-9) — falaise ouest et pylône rituel

> Falaise (§11.G) : bosquet de pins au sommet (les hauteurs §12),
> mort-bois en repère de corniche, gros rochers d'appui au pied dont une
> formation EMPILÉE, herbes sèches clairsemées — surfaces d'escalade et
> corniches de repos intactes. Pylône (§11.H) : composition rituelle —
> cercle de dalles autour du socle, piliers de brique encadrant
> l'approche, bannières de seuil (lieu entretenu), pierres votives,
> végétation quasi absente (§7.5 près du danger électrique). 24
> placements. Tests de zones : 7 zones couvertes.

## 2026-08-02 (nuit V4, lot 10) — approche de la citadelle en quatre couches

> §11.I : ruines extérieures dans la plaine (murs effondrés, briques,
> lierre — la route traverse un passé), rampe fortifiée (deux paires
> pilier+torchère à mi-montée, bannières hautes), terrasse d'accueil
> (murs d'enceinte PARTIELS en corridor, fenêtres, charrette de siège,
> ravitaillement), seuil monumental (bannières sur les piliers de bronze
> V4.3). 24 placements à collisions d'obstacle. Rampe processionnelle et
> SceneDoor intactes. Test de zone. evidence/v4lot10/.
> **PROCHAINE ACTION (V4 lot 11)** : vestibule — casser la répétition du
> pilier d'angle (variantes), panneaux muraux, allée de dalles, mobilier
> martial ; puis lot 12 structures pénétrables (avant-poste, abri
> rivière, sanctuaire falaise, poste de garde).

## 2026-08-02 (nuit V4, lot 11) — vestibule varié et meublé

> §11.J : la répétition du pilier d'angle unique est cassée — les piles
> de colonnes alternent module LARGE (arch.column.module ×1.6) et
> variante ÉTROITE (Corner_Exterior_Brick ×2.1, repli propre sur le
> large si absente). Intérieur habité : allée processionnelle de 6
> dalles Floor_Brick vers la porte de sortie, 2 panneaux muraux
> plâtre au nord, mobilier martial (râtelier d'armes, bouclier, banc,
> caisse+parchemin — un poste de garde, pas un hall vide), 2 bannières
> latérales, 2 lanternes murales avec OmniLight chauds MOTIVÉS (§7.8 :
> sources visibles, aucun couloir noir). 17 placements + 2 lumières.
> Tests citadel_dressing 2/2 (structure ColumnStack/Segment préservée).
> Capture : evidence/v4lot11/vestibule_dressed.png (manifeste).
> **PROCHAINE ACTION (V4 lot 12)** : structures secondaires pénétrables
> (avant-poste route nord, abri rivière, sanctuaire falaise, poste de
> garde citadelle) — chaque intérieur : raison d'être, récompense,
> dimensions joueur, sortie sûre.

## 2026-08-02 (nuit V4, lot 12) — structures secondaires pénétrables

> Aucun bâtiment important ne reste une boîte fermée : quatre abris 4×6 m
> sur le kit modulaire 2 m (cotes mesurées au catalogue), coquille
> complète (6 dalles, 10 murs à collision, 4 angles, toit, lanterne +
> omni chaude MOTIVÉE §7.8), porte JAMAIS barrée (deux flancs + linteau,
> l'arche 1,2×2,3 m reste franche). Avant-poste route nord (guet des
> ruines : table+ordres, râtelier+hache, tonneau — récompense VIANDE),
> abri de rivière (pêcheur : lit, étagère, corde — récompense FRUIT),
> sanctuaire de falaise (autel, chandelles, livres — l'épice rare
> EXISTANTE devient l'offrande au centre), poste de garde citadelle
> (râtelier, bouclier, chaîne — récompense BAIE D'ORAGE, §13.5 : la
> résistance AVANT le donjon). 3 nouveaux IngredientPickup persistants.
> Face en relief des murs vers l'INTÉRIEUR (l'expérience pénétrable
> prime) ; angles de pierre + bannière/torche portent l'extérieur.
> Limite connue : pignons ouverts sous le toit (aucune pièce de gable
> promue) ; navmesh non recuit (aucune IA ne fréquente ces abris).
> Wall_UnevenBrick_Straight ajouté à PROMOTIONS.csv (présent depuis
> ART-Q0, vérifié identique à l'octet). Test : 48 assertions (coquilles,
> portes franches, récompenses DANS les abris). Caméras de contrôle
> VALLEY_STRUCTURES=1/2. Captures : evidence/v4lot12/. Plancher 321.
> **PROCHAINE ACTION (V4 lot 13)** : personnages et palettes (capuche
> héros bleu-vert réel, pillards ≠ paysans recolorés, silhouettes).

## 2026-08-02 (nuit V4, lot 13) — personnages et palettes

> §12 « pas de simples recolorations » TENU : les trois pillards partagent
> le squelette UAL 65 os mais plus la silhouette. Système de GREFFE de
> pièces modulaires (maillages skinnés re-parentés sous le Skeleton3D,
> binds identiques vérifiés) : azur = épaulière + bottes de ranger ;
> obsidienne = capuche sombre + épaulière + carrure ×1,12 (visuel seul,
> capsule intacte) ; braise = ligne de base. Les trois reçoivent le CORPS
> DE BASE Superhero_Male (tête, yeux, sourcils — ils étaient SANS TÊTE de
> face, invisible jusqu'ici faute de capture frontale) ; la peau est
> RETRACTÉE (grow −8 mm) sous la tenue contre le z-fighting §21.8, et la
> teinte de faction est désormais limitée aux VÊTEMENTS (MI_Peasant +
> MI_Ranger) — peau et visage naturels. Héros : la teinte globale
> turquoise est REMPLACÉE par une texture dérivée où seule la capuche est
> #168F9B — script reproductible tools/godot/recolor_hero_hood.gd
> (masque = UV de la pièce capuche rasterisées, 2136 triangles, manifeste
> JSON), peau/cuir/tunique intacts (§7.11). Bibliothèque de silhouettes
> scenes/tests/SilhouetteLineup.tscn (§7.18) : 4 personnages, mode
> SILHOUETTE_FLAT=1 en aplats noirs — captures matière + aplats dans
> evidence/v4lot13/. Défaut amont consigné : 2 normal maps du corps de
> base référencées sous un nom absent de l'archive (copies renommées,
> ATTRIBUTIONS.md). Test hero_visual mis à jour vers le nouveau contrat
> (substitution blanche, peau vierge) ; nouveau test variantes (greffes
> liées, comptes relatifs, carrure) + test lineup. Plancher 323.
> **PROCHAINE ACTION (V4 lot 14)** : animations supplémentaires
> (escalade, interaction, cuisine, arc) depuis les bibliothèques UAL.

## 2026-08-02 (nuit V4, lot 14) — animations supplémentaires

> Trois états OPTIONNELS cuits dans AL_HeroStates (15 clips : 12
> obligatoires + 3), audités in-place (dérive pelvis 0,0000 m chacun) :
> mantle = ClimbUp_1m (le franchissement joue enfin un vrai clip, la
> limite « départ de saut » du TEST_REPORT est levée), interact =
> Interact, consume = Consume. CharacterAnimSet : exports optionnels
> hors du contrat des douze (un vide n'est pas un trou). Câblage §7.18
> (l'animation visualise, ne décide pas) : signal typé interacted(cible)
> émis quand l'interactable ACCEPTE, meal_eaten(nom) émis au plat
> rapide ; le pilote joue le geste et le TIENT 45 ticks à l'arrêt —
> bouger l'annule immédiatement, le contrôle prime. Le geste de cuisine
> (E.2b) branchera consume au feu de camp. Tests : bibliothèque 15
> clips épinglée, audit 15 entrées, nouveau test geste (consommation
> réelle par le chemin plat rapide + annulation par mouvement).
> Plancher 324.
> **PROCHAINE ACTION (V4 lot 15)** : optimisation (matériaux partagés,
> mesures taille/temps d'import) puis lot 16 revue contradictoire.

## 2026-08-02 (nuit V4, lot 15) — optimisation et mesures

> Cache de matériaux graybox par clé (couleur, émission) : ~150 volumes
> partagent ~10 ressources au lieu d'une chacun ; les personnalisations
> (braises du camp, runes du pylône) deviennent des DUPLICATAS explicites
> — la mutation en place aurait teinté tous les volumes de même clé.
> Outil de mesure reproductible tools/godot/measure_world_metrics.gd
> (CPU headless, JAMAIS un budget de frame) : vallée = 1627 nœuds, 647
> maillages, 194 collisions, 9 lumières, 353 matériaux uniques, load
> 395 ms. Dépôt : .git 258 Mo, plus gros fichier suivi 12,1 Mo (<100).
> PERFORMANCE.md §6 : première entrée du journal. Test de partage (4
> assertions). Leçon consignée : ne JAMAIS éditer un script pendant
> qu'une validation tourne — le processus garde l'ancienne version en
> cache et le verdict devient un état mixte (mesuré cette nuit).
> Plancher 325.
> **PROCHAINE ACTION (V4 lot 16)** : revue contradictoire à contexte
> frais (liste de chasse §20 de l'ordre V4) puis lot 17 package.

## 2026-08-02 (nuit V4, lot 16) — revue contradictoire et correctifs

> Revue à contexte frais (agent adversarial-qa, périmètre
> 2bf9e2b..71748e7, liste de chasse §20 de l'ordre V4) : 11 points
> rejoués commande par commande. Verdict initial **FAIL** — deux défauts
> réels, corrigés dans ce lot :
> 1. **Reproductibilité (principal)** : le rejeu de la promotion sur
>    clone frais sortait en erreur sur les 2 textures au nommage amont
>    défectueux (Superhero_Male_FullBody). Correctif : table
>    UPSTREAM_RENAMES dans tools/promote_quaternius.py (repli documenté,
>    renvoie vers ATTRIBUTIONS.md). Rejeu prouvé : « 0 fichier à copier,
>    744 identiques », exit 0.
> 2. **Couloir de vista (mineur)** : un buisson de _build_nature_phrases
>    (ART-Q4) à x=11, 1,5 m de haut, DANS le couloir x −12..12 — hors du
>    périmètre de l'ancien test (enfants de DressZoneCrest seulement).
>    Correctifs : buisson déplacé à x=14,5 ET test étendu à TOUS les
>    nœuds de la crête (20 assertions ; échec avant / succès après
>    prouvé en re-plaçant temporairement le buisson).
> Signal transversal admis : preuves capturées en arbre sale au commit
> précédent — règle ajoutée à .claude/rules/evidence.md : capturer APRÈS
> le commit du code (manifeste repo_dirty:false), commit d'evidence
> immédiat ensuite. Points PASS notables : compositions non uniformes,
> structures pénétrables, personnages, audits d'animation, sauvegarde,
> dépôt < 100 Mo, mesures honnêtes, validate_fast VERT 325.
> **PROCHAINE ACTION (V4 lot 17)** : clore le package de playtest
> (document déjà commité 7059ae9), puis §17 : E.2b cuisine visible.

## 2026-08-02 (nuit V4, lot 17) — package de playtest clos

> docs/PLAYTEST_PACKAGE.md (commité 7059ae9) : le package EST le dépôt —
> archive HEAD ~310 Mo SANS ZIP source, plus gros fichier suivi 12,1 Mo,
> reconstruction de la promotion prouvée depuis la Release (« 0 à
> copier, 744 identiques » après le correctif lot 16). Prérequis,
> import, scènes de contrôle, protocole humain §21.4 + points V4,
> limites honnêtes. Première capture conforme à la nouvelle règle
> d'evidence : vista rejouée depuis l'arbre COMMITTÉ (95b757d,
> repo_dirty:false) — evidence/v4lot16/vista_post_review.png : couloir
> dégagé (buisson déplacé), capuche turquoise lisible de dos.
> **Les 17 lots de l'ordre V4 sont livrés.**
> **PROCHAINE ACTION (§17 de l'ordre)** : E.2b cuisine visible au feu
> (code prêt en scratchpad : Campfire interactable + atelier du shell +
> label de buff HUD + 4 tests), puis revue Gate E, puis Phase F selon
> l'addendum multi-étages (graphe sandbox d'abord).

## 2026-08-02 (E.2b, travail en vol clos — ordre corrigé reçu)

> E.2b était en cours d'écriture à l'arrivée de la CORRECTION du
> propriétaire (arrêt des lots artistiques V4, réouverture du Gate D).
> Le travail produit est conservé et clos proprement : feu de cuisine
> interactable SUR le foyer du camp (Campfire, groupe interactable,
> « Cuisiner »), atelier du shell (§13.3 : sélection 1-5 bornée au stock
> possédé, aperçu honnête nom+soin via RecipeRules, confirmation
> ATOMIQUE — place et stocks revérifiés avant tout retrait, annulation
> gratuite car la sélection n'est qu'un plan), label de buff au HUD
> (famille + secondes restantes), autosave déjà câblé (meals_changed,
> E.2a). 4 tests d'intégration (28 assertions) sur la vraie scène ;
> le geste d'interaction (lot 14) part à l'ouverture du feu.
> **Gate E : NON fermé** — la revue attendra le Gate D (ordre corrigé).
> **PROCHAINE ACTION (ordre corrigé)** : audit complet du Gate D —
> matrice de preuve items 16-20, puis implémentation des QUATRE familles
> ennemies manquantes (§12.2-12.5 : azur, obsidienne, colosse,
> chasseur), batterie de tests §12, aplats des cinq familles.

## 2026-08-02 (ordre corrigé, jalon 1) — audit du Gate D : ROUVERT

> Matrice de preuve items 16-20 rejouée au commit 056788c
> (docs/GATE_D_AUDIT.md) : 16 PASS, 17 PASS, 18 PARTIEL (4/8 coffres —
> les 4 de la vallée conformes §11.4, le solde appartient aux salles de
> Phase F, consigné), 19 **FAIL** (0/4 familles au-delà du pillard
> braise — le lot V4-13 n'a produit que des variantes visuelles), 20
> PARTIEL (bloqué par 19). Verdict global FAIL : Gate D rouvert. Plan
> de fermeture en 7 jalons D-EN.0..6 (socle+mémoire+territoire, azur,
> obsidienne, coordinateur, colosse, chasseur, placements+aplats+revue).
> **PROCHAINE ACTION** : D-EN.0 — socle commun extrait de raider_red,
> mémoire de dernière position (§12.7) et territoire/retour (§12.9),
> raider_red re-testé à l'identique.

## 2026-08-02 (Gate D, D-EN.0) — socle ennemi : mémoire, territoire, ouïe

> EnemyBase extrait de raider_red et GÉNÉRALISÉ (§12.6-§12.10) — les 12
> tests pillard existants passent inchangés. États communs de §12.7 :
> Idle, Patrol (points optionnels), Suspicious (pause orientée),
> Investigate, Chase, Reposition (réservé familles), Attack, Retreat,
> Staggered, Flee, Return, Dead ; « Alert » = instant d'acquisition,
> « Recover » = phase RECOVERY du contrat d'attaque (mappings
> documentés). NOUVEAU : mémoire de dernière position (poursuite de
> mémoire, investigation, recherche, retour), territoire borné avec
> garde anti-oscillation (une cible hors territoire n'intéresse pas),
> ouïe par événements réels (NoiseEvents : sprint du joueur ÉMET toutes
> les 0,5 s, l'impact reçu ÉMET — rupture/flèche à câbler avec l'arc de
> l'azur), LOS torse PUIS tête, fuite à la mort d'un allié (§12.1 : le
> braise détale, les autres familles décideront), alerte §12.2 (le
> receveur endormi adopte la cible). EnemyTuning : 6 champs nouveaux.
> raider_red devient une sous-classe MINCE (gourdin, recul sur esquive,
> fuite). 5 tests D-EN.0 (18 assertions) : mémoire→recherche→maison,
> frontière SANS oscillation, bruit→suspicion→investigation (+ bruit
> hors d'audition ignoré), fuite réelle mesurée, alerte reçue.
> Plancher 334.
> **PROCHAINE ACTION (D-EN.1)** : pillard azur — 85 PV, LANCE (contrat
> d'attaque propre), contournement (crochet de vitesse de chasse),
> maintien de distance, esquive de lourde (cooldown 8 s), alerte 14 m.

## 2026-08-02 (Gate D, D-EN.1) — pillard azur : deuxième famille RÉELLE

> §12.2 au complet, prouvé en physique réelle : 85 PV, LANCE (contrat
> d'attaque propre spear_thrust — pique 0,55 s/0,18/0,85, hitbox longue
> et étroite, portée 2,4 m où le gourdin ne touche pas), silhouette
> droite (capsule 1,75), vision 30 m/105°, audition 20 m, poursuite
> 5,8 m/s. Comportements PROPRES : contournement (crochet
> _family_chase_velocity du socle — composante latérale 45 % à
> mi-distance, flanc déterministe par spawn), alternance
> distance/attaque (il ROUVRE l'écart pendant son cooldown), esquive
> d'une lourde télégraphiée (lecture du CONTRAT d'attaque du joueur —
> startup d'une lourde à portée —, pas latéral 0,28 s, cooldown 8 s
> mesuré : la 2e lourde n'est PAS esquivée), alerte 14 m via le socle.
> 5 tests (18 assertions). Leçon de test consignée : l'attente
> d'atterrissage du setup laisse le temps d'attaquer — démarrer le
> joueur hors de vue puis le téléporter dans le scénario. Plancher 339.
> **PROCHAINE ACTION (D-EN.2)** : briseur d'obsidienne — 150 PV, masse
> en combo 2-3 coups (chaînage par la vraie fenêtre), garde frontale à
> jauge (amorti + rupture = ouverture), poise 60.

## 2026-08-02 (Gate D, D-EN.2) — briseur d'obsidienne : troisième famille

> §12.3 au complet : 150 PV, poise 60 (la séquence qui couche le braise
> laisse le briseur DEBOUT — mesuré), capsule large et basse (0,5/1,5),
> vision 26 m/90°, audition 22 m, poursuite 5,0. MASSE en chaîne de 3
> contrats (mace_1/2/3 — le chaînage passe par la VRAIE fenêtre de
> combo, attack_started ré-émis avec index > 0 ; recovery 1,2-1,4 s sur
> les derniers coups = l'ouverture §12.3). GARDE FRONTALE À JAUGE :
> amorti ×0,25 dans l'arc de 120° face à la menace (levée pendant sa
> propre ANNONCE — l'ouverture est après le combo, pas pendant le
> télégraphe), drain par coup encaissé, rupture = STAGGER, régénération
> après 5 s d'accalmie. DEUX DÉFAUTS RÉELS trouvés par les tests et
> corrigés au socle et aux scènes : (1) attaquer sans être TOURNÉ vers
> la cible (acquis de dos, le coup partait dans le vide — le socle exige
> désormais ≤30° de désaxement, le pivot travaille d'abord) ; (2) portée
> d'engagement > extension de la hitbox (boucle de coups courts à
> jamais — volumes de masse ET de gourdin étendus à la portée). Test de
> rupture par injection aux instants de garde (le duel réel est prouvé
> par le test frontal ; le duel complet est trop bruité pour compter des
> drains). 5 tests briseur, 22/22 sur toutes les suites pillards.
> Plancher 344.
> **PROCHAINE ACTION (D-EN.3)** : CombatCoordinator §12.8 (2 tokens
> mêlée, 1 lourd, libération garantie, plafond 10-14 IA), puis D-EN.4
> colosse des ravins.

## 2026-08-02 (Gate D, D-EN.3) — coordinateur de combat §12.8

> CombatCoordinator par groupe : DEUX tokens mêlée, UN lourd (réservé
> colosse/chasseur), purge par cadence — un token n'est tenu que par un
> porteur VIVANT et EN ATTAQUE, la libération est STRUCTURELLE (mort,
> stagger, interruption, sortie : rien ne bloque la file, aucune
> référence morte). Sans token : l'ennemi ENCERCLE (orbite au lieu de
> s'empiler). Plafond §12.9 : au-delà de 14 IA vivantes, les plus
> lointaines du joueur DORMENT (physique coupée, réveil au rang).
> SANS coordinateur en scène : accord implicite — aucun duel existant
> ne change. Libérations câblées au socle (fin d'attaque, poise brisée,
> mort). 3 tests : ≤2 attaquants simultanés mesuré sur 6 s avec
> encerclement réel du tiers, token du mort repris par un survivant,
> 16 vivantes → 2 dormeuses (les plus lointaines exactement). Leçon :
> un test avorté (erreur script) saute son teardown et contamine le
> suivant par le groupe global — l'isolation du cas l'a démontré.
> Plancher 347.
> **PROCHAINE ACTION (D-EN.4)** : colosse des ravins §12.4 — 420 PV,
> 3,5-4,5 m, balayage/verticale/onde de choc évitable, lancer de
> rocher, point faible dorsal, token lourd.

## 2026-08-02 (Gate D, D-EN.4) — colosse des ravins : quatrième famille

> §12.4 : 420 PV, poise 100, capsule de 3,8 m (rayon 1,1 — sa TAILLE
> est sa navigation : un test prouve qu'une porte de 1,6 m le refuse
> physiquement alors qu'il pousse contre elle), vision 35 m/115°,
> audition 30 m, poursuite 4,8, virage LENT (3,5). Trois attaques :
> balayage (renversement, knockback 6) chaîné d'une frappe VERTICALE,
> et COUP AU SOL lourd dont l'impact émet une ONDE DE CHOC — anneau
> autonome qui s'étend à 9 m/s jusqu'à 8 m, frappe UNE fois, et
> ÉPARGNE un joueur DÉCOLLÉ (§12.4 « évitable par saut » — les deux cas
> mesurés sur la même onde). LANCER DE ROCHER entre 6 et 16 m :
> annonce immobile orientée 0,9 s (rougeoiement de télégraphe), vrai
> projectile balistique (le balayage CCD de la flèche, réutilisé, jamais
> ré-instancié). POINT FAIBLE DORSAL : deux hurtbox non chevauchantes,
> le dos à ×2 (§10.3, appliqué par la formule). Token LOURD (§12.8).
> Deux défauts réels trouvés par les tests : (1) le socle exigeait la
> hurtbox à la RACINE — le dos doit tourner avec le pivot, résolution
> par recherche de nom dans le sous-arbre ; (2) le rocher naissait DANS
> la carrure du colosse et mourait au premier tick — il part désormais
> devant et au-dessus. 5 tests colosse, 22/22 pillards, 5/5 socle.
> Plancher 352.
> **PROCHAINE ACTION (D-EN.5)** : chasseur quadrupède §12.5 — ~650 PV,
> centauroïde original, charge télégraphiée, salve d'arc plafonnée,
> combo rapproché, cri d'annonce, territoire à frontière d'abandon.

## 2026-08-02 (Gate D, D-EN.5) — chasseur quadrupède : CINQUIÈME famille

> §12.5 : 650 PV, poise 80, silhouette CENTAUROÏDE originale et mesurée
> (corps bas allongé 1,6×1,1×3,0 — plus long que large, quadrupède —
> surmonté d'un torse haut porté vers l'avant ; aucun élément d'une
> licence existante), vision 48 m/130°, audition 38 m, poursuite 11 m/s
> (le plus rapide du bestiaire), token lourd. Quatre comportements
> propres : CRI d'annonce 0,8 s immobile et orienté avant toute manœuvre
> majeure (mesuré : vitesse < 0,5 m/s pendant l'annonce) ; CHARGE en
> ligne FIGÉE au départ — la trajectoire réelle garde son cap malgré un
> décalage latéral de la proie (alignement > 0,95 sur tous les pas),
> donc esquivable ; SALVE d'arc de 3 flèches espacées suivie d'un repos
> de 5 s (cadence plafonnée par construction, pool de projectiles) ;
> REPOSITIONNEMENT CIRCULAIRE entre 4 et 9 m. Territoire à frontière
> d'abandon (rencontre FACULTATIVE §4.1) : mesuré, il rentre. 5 tests.
> Plancher 357. **Les cinq familles de §12 existent et sont testées.**
> **PROCHAINE ACTION (D-EN.6)** : placements dans la vallée, aplats
> noirs des cinq familles à la même échelle, batterie transverse
> (occlusion, mémoire, retour, séparations, cadavres, loot unique),
> puis revue contradictoire du Gate D.

## 2026-08-02 (Gate D, D-EN.6) — placements, aplats, batterie transverse

> Les cinq familles sont DANS la vallée à leur poste (§12.2-§12.5) :
> azur au gué est et en lisière de forêt (lignes de tir), briseur au
> sommet de la falaise ouest gardant la Lame conductrice, colosse aux
> ruines centrales sur la route du donjon, chasseur à l'est DERRIÈRE le
> pylône (territoire optionnel, hors corridor principal — testé). Un
> CombatCoordinator gouverne le groupe. Planche du bestiaire
> (scenes/tests/BestiaryLineup.tscn, BESTIARY_FLAT=1) : les cinq à la
> MÊME échelle, en matière et en aplats noirs — evidence/gateD/. §12.9 :
> DEUX navmesh cuits depuis la même géométrie (agent 0,7 m : 1098
> polygones ; agent 1,2 m : 1044) sur des cartes SÉPARÉES ; colosse et
> chasseur empruntent la grande via tuning.uses_large_navmesh. Batterie
> transverse test_bestiary_gate (107 assertions) : stats/armes/carrures
> toutes distinctes et aucun identifiant de contrat partagé, aucune
> vision à travers un mur sur les cinq, aucune hitbox ni hurtbox active
> après la mort, placements et navigation vérifiés. TROIS défauts réels
> corrigés : hurtbox secondaire (dos du colosse) encore frappable après
> la mort ; deux _exit_tree concurrents ; fuite de RID de la carte de
> navigation créée en code. Audit du Gate D réécrit avec preuves
> rejouées : **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE**
> (jamais de PASS humain ; item 18 PARTIEL assumé, coffres du donjon en
> Phase F). Plancher 362.
> **PROCHAINE ACTION** : revue contradictoire du Gate D à contexte frais
> (ordre corrigé §5), puis fin de Phase E (Gate E) puis Phase F.

## 2026-08-02 (Gate D) — revue contradictoire : FAIL, sept correctifs

> Verdict de la revue à contexte frais sur a465299 : **FAIL**. Mon
> auto-évaluation était trop généreuse. Sept défauts réels, tous
> corrigés dans ce lot :
> 1. **`move_and_slide()` appelé DEUX FOIS par tick** dès qu'une famille
>    bougeait puis rendait `true` — toutes les vitesses de manœuvre
>    doublées EN SILENCE (charge du chasseur mesurée à 30 m/s pour 15
>    déclarés, soit le double du plafond §12.6). Le socle bouge une
>    fois, les familles jamais. Test de vitesse réelle ajouté.
> 2. **Le plafond d'IA gelait un attaquant en pleine attaque** : hitbox
>    armée à jamais (§12.10) et token confisqué (§12.8). Nouvelle sortie
>    propre sleep_for_activity_cap(). Test de reproduction ajouté.
> 3. Le briseur rendait la main sans rendre son token.
> 4. Proportions du briseur : 1,12 UNIFORME le rendait simplement plus
>    grand, contre §12.3 (« large et bas ») et contre sa capsule —
>    remplacé par 1,18 × 0,94 × 1,18.
> 5. Assertion tautologique (x == x) + deux messages qui affirmaient
>    plus que leur condition (coordinateur, colosse) — resserrés.
> 6. La preuve de l'item 20 RETIRAIT les ennemis et s'arrêtait 190 m
>    avant la porte. Remplacée par un pilote scripté qui marche
>    réellement de la plaine nord au seuil, bestiaire en place, en
>    contournant les ruines (blocage franc mesuré à z = −29 : le détour
>    est délibéré).
> 7. ROADMAP.md déclarait encore le Gate D « non commencé ».
> Item 19 ramené à **PARTIEL** et limites CONSIGNÉES : les trois
> pillards partagent maillage et bibliothèque d'animations ; colosse et
> chasseur n'ont ni modèle riggé ni animation (Phase H). Le verdict
> global reste **ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE
> DIFFÉRÉE**, désormais sur des preuves qui tiennent. Plancher 364.
> **PROCHAINE ACTION** : recapturer les planches du bestiaire depuis
> l'arbre COMMITTÉ (manifestes au bon commit), puis fin de Phase E
> (migration de schéma + chaîne complète), puis Gate E.

## 2026-08-02 (Phase E, E.3) — migrations et chaîne complète

> Les deux derniers items de la Phase E (§19, §22 Gate E) :
> 1. **Migration RÉELLE de schéma** (SaveSystem 1 → 2) : une sauvegarde
>    d'avant la cuisine n'a ni plats, ni buff, ni ingrédients récoltés —
>    la migration les pose À VIDE, en chaîne, sur une COPIE. La source
>    n'est jamais réécrite (§19.4), le contenu d'origine (armes,
>    durabilités, flèches, coffres) est intact — 10 assertions.
> 2. **Chaîne complète de bout en bout** sur la vraie vallée : récolte
>    par interaction réelle → cuisine à l'atelier du feu (sélection,
>    confirmation atomique) → buff actif et NOMMÉ au HUD → sauvegarde
>    contenant plat, buff et ingrédients → vallée DÉCHARGÉE et rejouée
>    depuis le disque → plat et buff survivent, les ingrédients récoltés
>    ne repoussent pas. 15 assertions.
> Leçon consignée : le label du HUD se rafraîchit sur la cadence de
> _process (0,1 s), pas au tick physique — un test qui n'attend que des
> frames physiques ne le voit jamais. Plancher 367.
> **PROCHAINE ACTION** : revue de Gate E (les critères §22 sont
> couverts ; verdict attendu ACCEPTÉ POUR CONTINUATION — VALIDATION
> HUMAINE DIFFÉRÉE), puis Phase F : graphe électrique en sandbox
> automatisée AVANT toute salle (§22 ordre obligatoire).

## 2026-08-02 (Gate E) — revue et verdict

> `docs/GATE_E_AUDIT.md` : les HUIT items de la Phase E (§22) rejoués un
> par un — récolte (ingredients 4/4), atelier du feu (cooking_ui 4/4),
> sélection 1-5 bornée au stock, aperçu honnête, règles de recettes
> (cooking_rules 7/7), label de buff au HUD, sauvegarde et migration
> (phase_e 2/2, save 9/9, meals_and_buffs 4/4), chaîne complète de bout
> en bout. Transverses §13.3/§19 : annulation gratuite, confirmation
> atomique, un seul buff majeur, écriture atomique, refus d'un schéma
> plus récent. Un filtre cité dans le premier jet de l'audit
> (`--filter=recipes`) N'EXISTAIT PAS : corrigé en `cooking_rules` après
> rejeu — exactement le défaut que la revue du Gate D avait reproché.
> Non couvert et consigné : animation de cuisson (Phase H), essai
> humain (impossible ici). Verdict : **ACCEPTÉ POUR CONTINUATION —
> VALIDATION HUMAINE DIFFÉRÉE**.
> **PROCHAINE ACTION (Phase F, ordre §22 obligatoire)** : le graphe
> électrique dans une SANDBOX AUTOMATISÉE, avant toute salle — types de
> nœuds §15.1, algorithme §15.2 (marquage dirty, BFS depuis les sources,
> cycles sans récursion infinie, signaux seulement au changement).

## 2026-08-02 (Phase F, F.1) — graphe électrique en sandbox automatisée

> §22 exige le graphe AVANT toute salle : c'est fait, et rien d'autre
> n'a été construit. `ElectricNode` (§15.1 au complet : ID stable, ports
> ORIENTÉS en espace local, conductivité, enabled, signaux
> connection_changed/power_changed, set_powered IDEMPOTENT, aucune
> ligne de rendu) et `ElectricGraph` (§15.2 point par point : marquage
> dirty, regroupement jusqu'à la fin du tick, reconstruction des
> contacts réels port-à-port avec tolérance et sens, BFS depuis TOUTES
> les sources avec ensemble visited, signaux au seul changement).
> 11 tests en sandbox — aucun n'est une salle : circuit droit et nœud
> orphelin hors de portée, interrupteur ouvert qui reçoit sans
> transmettre, isolant sans même un voisin, CYCLE de quatre câbles qui
> termine, dix marquages = UN recalcul et vingt ticks inactifs = ZÉRO,
> trois recalculs identiques = un seul signal, bloc mobile qui relie
> deux plaques (le cœur de §15.5, prouvé hors salle), relais tourné d'un
> quart qui COUPE la ligne (§15.7), batterie qui alimente loin de toute
> source (§15.8), sauvegarde qui restaure les interrupteurs et RECALCULE
> l'alimentation (§19.1), validateur d'IDs vides et dupliqués (§19.3).
> Plancher 378.
> **PROCHAINE ACTION (F.2)** : salle 1 grayboxée et testée SEULE (§15.5
> exactement : source et récepteur séparés par un vide court, bloc
> métallique mobile, deux plaques, ouverture différée 0,6-1,2 s, bouton
> reset, solution impossible à perdre).

## 2026-08-02 (Phase F, F.2) — salle 1 d'initiation, testable seule

> §15.5 implémenté ligne à ligne dans une scène qui se joue et se teste
> **isolément** : source à l'ouest, deux plaques séparées par 2,8 m de
> vide (contre 0,85 m de portée de port : le vide est un VRAI vide),
> bloc métallique de 40 kg poussé dans un couloir guidé, butée qui
> l'arrête EXACTEMENT au contact, propagation lumineuse qui parcourt le
> circuit, anneau du récepteur qui se ferme, porte différée de 0,9 s
> (fenêtre 0,6-1,2 s mesurée tick par tick), bouton de reset, aucun
> texte dans la salle. La salle ouvre sur un couloir réel terminé par un
> seuil honnêtement scellé — une porte qui donnerait sur le néant serait
> un mensonge, pas un raccourci.
> Le test central ne triche pas : le joueur MARCHE (déplacement relatif
> à la caméra, aucune téléportation, aucun transform écrit), pousse le
> bloc sur 7 m et la porte s'ouvre. Pour qu'il passe, il a fallu ajouter
> au contrôleur la poussée d'objets physiques de §14.1 — impulsions
> bornées sur les corps du groupe `pushable`, jamais d'écriture de
> transform — et découvrir par la mesure que la poussée doit se calculer
> sur la vitesse VOULUE : après `move_and_slide()`, la composante qui
> entre dans l'obstacle vaut ~0, l'impulsion tombe sous le seuil de
> frottement et le bloc reste immobile 600 ticks durant (mesuré, D-027).
> Anti-softlock §15.11 couvert par quatre tests : reset qui rejoue
> l'énigme sans refermer la porte, bloc jeté hors du monde qui revient
> en 1-2 s à son transform de secours (§14.3), rechargement DEPUIS LE
> DISQUE d'une salle résolue (porte ouverte à la première image) et
> d'une salle à mi-résolution (ni résolue, ni bloquée, encore soluble).
> 12 tests `--filter=room1`, plancher relevé.
> Deux captures depuis l'arbre COMMITTÉ (`evidence/F2/`, `repo_dirty:
> false`) : l'énigme telle qu'on la découvre — la ligne cyan s'arrête net
> au vide — et la même image une fois le bloc au contact, circuit allumé
> jusqu'à la porte, anneau fermé, panneau monté. La première capture a
> d'ailleurs révélé deux défauts qu'aucun test ne pouvait voir : le bloc
> conducteur, sans matériau, passait pour une caisse de bois, et le
> premier plan tombait dans le noir (§7.8 : « aucun couloir noir »).
> Un diagnostic FAUX a été corrigé au passage : la capture « salle
> résolue » montrait l'état initial, ce que j'ai d'abord attribué à un
> blocage du solveur — la vraie cause est que `_ready()` ne tourne pas
> dans `add_child()` depuis un script `SceneTree`, si bien que la
> préparation tombait sur une scène à moitié construite. Le contournement
> bâti sur la fausse cause a été retiré, pas empilé.
> **PROCHAINE ACTION (F.3)** : salle 2, circuit vertical (§15.6) —
> ascenseur non alimenté, puits latéral escaladable, électrodes
> intermittentes au rythme observable, interrupteur supérieur qui
> redirige le courant, corniches de repos, une jauge d'endurance pleine
> qui suffit, chute qui renvoie à un palier proche, ascenseur qui ne
> peut ni écraser ni coincer le joueur, état sauvegardé cohérent.

## 2026-08-02 (Phase F, F.3) — salle 2, circuit vertical

> §15.6 implémenté dans une scène jouable et testable seule. Un puits de
> 22 m : trois blocs de pierre décalés le long du mur ouest (le mur
> lui-même est `unclimbable` — la voie passe par eux, sinon l'énigme
> n'existerait pas), trois électrodes intermittentes qui battent 1,1 s de
> décharge pour 1,7 s de calme, phases décalées, un ascenseur SANS
> courant, et sur la mezzanine un levier qui REDIRIGE le courant : la
> branche danger meurt, la branche ascenseur vit, la porte du haut
> s'ouvre.
> Trois briques réutilisables sont nées avec la salle : `ElectricSwitch`
> (aiguillage réel — deux nœuds `SWITCH` commandés d'un seul geste, pas
> un booléen de salle), `ElectricHazard` (décharge rythmée qui blesse ET
> retire la prise via le groupe `electrified` de §9.2) et
> `ElevatorPlatform` (`AnimatableBody3D`, deux zones de garde).
> Le buff de résistance électrique de §13.5 SERT enfin : c'est la
> première source de dégâts électriques du jeu, et un test mesure que la
> décharge coûte nettement moins avec le plat de baies.
> Deux défauts trouvés par la mesure, pas par relecture : (1) les deux
> branches se touchaient directement au carrefour, si bien que les
> aiguillages ne servaient à rien et que TOUT était alimenté d'un bloc —
> corrigé en éloignant les ports de sortie ; (2) la garde haute de
> l'ascenseur prenait son propre passager pour un obstacle, et la
> plateforme ne démarrait jamais — elle surveille désormais la tranche
> 1,9-3,9 m au-dessus du plancher.
> 12 tests `--filter=room2`, dont une montée RÉELLE du joueur (poussée
> vers la paroi, 5 m gravis, aucun transform écrit pendant la montée),
> l'arrêt de l'ascenseur devant un corps, le transport du joueur, la
> chute qui retombe sur le palier du dessous sans dégâts, et le
> rechargement depuis le disque.
> **PROCHAINE ACTION (F.4)** : salle 3, relais rotatifs (§15.7) — quatre
> colonnes à ports visibles, rotations discrètes, allumage progressif des
> segments valides, aucune erreur mortelle, retour distinct sur chemin
> partiel, solveur automatique qui prouve qu'au moins une configuration
> résout, bouton reset qui restaure la configuration initiale.

## 2026-08-02 (Phase F, F.4) — salle 3, relais rotatifs

> §15.7 implémenté : quatre colonnes-relais dont les DEUX bras de cuivre
> sont exactement les deux ports du graphe (§15.3 : « pour une colonne
> rotative, dépendre de l'orientation des ports »). Rotations discrètes
> d'un quart de tour, une à la fois, 0,35 s ; le graphe n'est marqué qu'à
> l'arrivée, si bien qu'une colonne qui tourne ne fait pas clignoter le
> circuit. Le chemin fait un créneau autour de la salle : source à
> l'ouest, récepteur à l'est, et la ligne cyan s'arrête EXACTEMENT à la
> première colonne mal tournée — c'est le « feedback distinct si chemin
> partiel » de §15.7, sans un mot de texte.
> Le solveur automatique exigé par §15.7 est un test : il énumère les 256
> configurations sur le VRAI graphe et prouve qu'il existe exactement UNE
> solution, que la configuration de départ n'en est pas une, et que la
> solution reste rare. Aucun danger dans cette salle : se tromper coûte
> un quart de tour, jamais un point de vie — un test le vérifie aussi.
> 8 tests `--filter=room3`, dont la résolution complète par le VRAI
> chemin d'interaction (7 quarts de tour) et le rechargement qui restaure
> l'orientation des colonnes.
> **PROCHAINE ACTION (F.5)** : salle 4, batterie transportable (§15.8) —
> une source, deux mécanismes successifs, batterie chargeable et
> transportable, socket explicite, zone d'eau conductrice dangereuse
> quand elle est alimentée, couper le courant ou construire une
> passerelle isolante, batterie hors limites qui réapparaît, aucune porte
> qui verrouille la batterie du mauvais côté, retour toujours possible.

## 2026-08-02 (Phase F, F.5) — salle 4, batterie transportable

> §15.8 implémenté avec ses DEUX solutions, pas une. Un canal de 6 m —
> au-delà de la portée d'un saut de §8.2 — coupe la salle en deux ; la
> nappe est un nœud `WATER_ZONE` du graphe, pas un décor : sous tension
> elle frappe en continu. Aucun câble ne traverse : le courant ne passe
> de l'autre côté que DANS la batterie.
> Trois briques nouvelles, toutes réutilisables : `CarryableObject`
> (prendre / porter / poser, §14.2 ; corps gelé en cinématique pendant le
> transport, jamais un transform écrit sur un corps actif),
> `PortableBattery` (charge stockée, socket et décharge sont trois choses
> distinctes comme l'exige §15.3) et `ObjectSocket` (berceau visible,
> zone réelle, calage franc — §15.3 refuse « proche d'un point invisible
> sans retour visuel »). Le socket n'ajoute AUCUNE règle électrique : une
> fois l'objet calé, ce sont les ports qui se touchent.
> Les deux chemins de §15.8 sont testés séparément : couper le courant au
> levier (la nappe meurt, et le berceau de charge avec elle — c'est le
> prix, et c'est ce qui rend l'ordre des gestes intéressant), ou poser la
> planche de bois isolante sur ses berceaux et passer au-dessus de l'eau
> vive sans prendre un point de dégât.
> Anti-softlock vérifié plutôt qu'affirmé : la seule porte est à l'est,
> au-delà du récepteur ; le berceau de charge, le point de secours de la
> batterie ET celui de la planche sont tous à l'ouest ; patauger coûte
> mais ne tue pas ; le levier est rebasculable.
> 11 tests `--filter=room4`, dont le ramassage/transport/dépose par le
> vrai chemin d'interaction et le retour de la batterie tombée au canal.
> **PROCHAINE ACTION (F.6)** : salle centrale et antichambre (§15.9,
> §15.10) — trois récepteurs indépendants alimentés par les trois
> circuits permanents, trois anneaux, ouverture MÉCANIQUE de la porte du
> boss, carte murale, checkpoint, coffre garanti, station de cuisine,
> baies électriques, aperçu de l'arène, retour possible ; plus
> l'architecture multi-niveaux qui relie enfin les quatre salles.

## 2026-08-02 (Phase F, F.6) — salle centrale, antichambre, donjon assemblé

> §15.9 et §15.10 livrés, et surtout : **les six scènes du donjon sont
> enfin reliées**. Vestibule → salle 1 → salle centrale → salles 2/3/4 →
> salle centrale → antichambre, avec un chemin retour partout et, pour
> chaque salle à énigme, un SECOND seuil ouvert par son puzzle : le
> raccourci est la récompense.
> Salle centrale (§15.9) : trois récepteurs sur trois piliers, trois
> anneaux, et trois branches **électriquement séparées**. C'est le point
> dur : relier les trois branches à un nœud commun (la porte, par
> exemple) ferait remonter le courant du premier circuit dans les deux
> autres et fermerait les trois anneaux d'un coup. La porte du boss a
> donc TROIS CONDITIONS (`ElectricDoor.required_paths`) et n'ouvre qu'à
> la troisième. Un test le prouve : une salle résolue n'allume que SON
> anneau. Le tableau « quelle salle fournit quel récepteur », exigé
> nommément par §15.9, est en tête de `central_hall.gd` et vérifié salle
> par salle par un test.
> Architecture à deux niveaux : les portes des salles au sol, la porte du
> boss six mètres plus haut sur la galerie, deux rampes à 36,9° — sous
> les 46° praticables de §8.2. Le pied des rampes est ENTERRÉ dans la
> dalle : mesuré, une rampe posée sur le sol présente une tranche de
> 0,75 m, c'est-à-dire un mur. Un test fait monter le joueur en marchant.
> Antichambre (§15.10) : checkpoint écrit à l'entrée, coffre garanti
> (lame conductrice + 12 flèches), feu de cuisine, quatre baies de
> tempête, retour libre, aperçu réel de l'arène et ses quatre pylônes
> derrière la baie — et une fresque qui ENSEIGNE §14.4 par la
> démonstration : deux lignes du graphe, celle du métal arrive au bout,
> celle du bois meurt au barreau.
> 15 tests neufs (`--filter=dungeon_hub`, `--filter=topology`), dont la
> vérification que chaque traversée dépose le joueur DEVANT la porte de
> retour, et que toutes les salles sont atteignables depuis le vestibule.
> **PROCHAINE ACTION (F.7)** : anti-softlock et persistance sur le donjon
> ENTIER — reprise depuis une sauvegarde vierge, reprise en milieu de
> résolution dans chaque salle, objets essentiels hors limites, mort et
> retour au checkpoint, aucune ressource obligatoire destructible.

## 2026-08-03 (Phase F, F.6 — suite) — trois rouges, une seule cause utile

> La suite complète est repassée ROUGE après l'assemblage, sur des tests
> qui n'avaient pas changé : mort du joueur et parcours de traversal. La
> chaîne réelle, trouvée par la mesure et non par relecture :
> 1. `test_valley_dressing` interrogeait encore `SealedDoor` — le mur que
>    F.6 vient de remplacer par une vraie porte. `get_node()` renvoie
>    null, l'accès suivant lève une erreur de script, et la fonction de
>    test s'arrête AVANT son nettoyage ;
> 2. le vestibule reste donc dans l'arbre, avec son joueur et ses
>    colonnes ;
> 3. trente fichiers plus loin, le parcours de traversal démarre entre
>    ces colonnes et se bloque à x = 5,05 (`Column3` nommée par le
>    diagnostic) ;
> 4. en parallèle, `GameplayShell` liait son affichage au PREMIER joueur
>    du groupe global : avec deux mondes chargés, le shell de la vallée
>    écoutait la santé d'un autre joueur, et la mort ne déclenchait plus
>    rien.
> Trois corrections, aucune cosmétique : l'assertion périmée est mise à
> jour (la porte du fond EXISTE, elle mène au donjon), le shell se lie au
> joueur de SA scène (`test_shell_binding.gd` couvre la régression), et
> le **runner refuse maintenant qu'un test laisse une scène dans
> l'arbre** — il photographie la racine avant chaque test et échoue le
> test fautif en nommant ce qu'il a laissé. Sans ce garde, la prochaine
> fuite coûterait à nouveau une demi-journée à un autre endroit.
> Les deux attentes de panneau de mort se comptent désormais en temps
> réel, pas en images : en headless la cadence varie du simple au double.
> validate_fast VERT, 438 tests, aucune fuite détectée.
> **PROCHAINE ACTION (F.7)** : anti-softlock et persistance sur le donjon
> entier.

## 2026-08-03 (Phase F, F.7 et F.8) — anti-softlock, run complet, Gate F

> F.7 : les garanties de §15.11 sont vérifiées pour les SIX scènes d'un
> seul tenant — chargement depuis une sauvegarde vierge, rechargement à
> mi-résolution, objets essentiels jetés hors du monde qui reviennent
> tous, reset qui ne retire jamais un acquis, sortie/retour qui conserve,
> cent recalculs de graphe sans blocage ni voisin mort, indice visuel
> sans une ligne de texte. L'outil de debug exigé nommément par §15.11
> existe : `ElectricDebugOverlay` liste IDs, types, ports, voisins et
> état `powered`, et se RETIRE de l'arbre dans un build non-debug.
> Il a d'ailleurs servi immédiatement : son compteur d'orphelins a
> désigné le seul nœud sans voisin de la salle 1 — le conducteur du bloc,
> normal avant qu'on le pousse. La métrique distingue donc désormais un
> nœud FIXE mal posé (faute) d'un objet mobile en attente (normal).
> F.8 : le donjon est résolu de bout en bout par ses GESTES RÉELS — le
> bloc poussé à la marche, le levier basculé, les quatre colonnes
> tournées une à une, la batterie prise, chargée, reprise et posée. Deux
> runs : depuis une sauvegarde vierge, et coupé en deux avec relecture du
> fichier depuis le disque. Dans les deux cas, les trois circuits de la
> salle centrale débitent et la porte du boss s'ouvre.
> Le run a trouvé un comportement systémique qu'on a GARDÉ : une batterie
> laissée dans son berceau continue d'alimenter le circuit, donc l'eau.
> Il faut la reprendre PUIS couper. Cohérent avec §15.1 et §15.3, sans
> risque d'enfermement, et désormais couvert par un test qui l'énonce.
> `docs/GATE_F_AUDIT.md` : tous les items automatisables PASS.
> validate_fast VERT, 449 tests, plancher 449.
> **PROCHAINE ACTION (Phase G)** : arène circulaire 32-42 m, quatre
> pylônes de mise à la terre branchés sur le MÊME système électrique que
> le donjon, puis machine à états du boss et ses trois phases.

## 2026-08-03 — Phase G, jalons G.1 à G.3 : l'arène, le combat, la conclusion

> G.1 : l'arène du Gardien est un DISQUE de 38 m (§16.1 : 32-42), fermé
> par un mur circulaire continu, avec trois zones de sol emboîtées — dalle
> du noyau, anneau de combat, marge de terre — et rien au milieu qui
> puisse gêner la caméra. Les quatre pylônes de mise à la terre sont de
> vrais nœuds du graphe du donjon, comme §16.3 l'exige nommément : un
> anneau fermé de 24 câbles court à leurs pieds, alimenté par un puits de
> terre au nord. C'est un CYCLE, et c'en est la démonstration en jeu
> plutôt qu'en laboratoire (§15.2 pt. 5).
> Le premier pylône était FAUX et un test l'a dit : il basculait
> `ElectricNode.enabled`, drapeau que le graphe n'écoute que pour SOURCE,
> SWITCH et BATTERY. Les quatre s'allumaient à l'ouverture de la scène.
> Corrigé par la géométrie, pas par une exception : le mât est
> télescopique et son sabot de cuivre descend sur le rail quand on le
> dresse. Rétracté, il est relevé de 1,6 m, très au-delà des 0,5 m de
> portée. Même doctrine que le bloc de la salle 1 et la batterie de la
> salle 4 (§15.3).
> La caméra reçoit un SUPPLÉMENT de cadrage tant que le Gardien vit — la
> distance et le FOV s'ouvrent sur la même courbe interpolée que le FOV de
> sprint, donc sans snap (§8.3), et le `SpringArm3D` continue de sonder :
> reculer ne fait jamais traverser un mur. Le HUD gagne sa barre de boss
> (§17.2), qui affiche la vie réelle et nomme la phase.
> L'arène n'enferme personne : son seuil sud reste ouvert vers
> l'antichambre, donc vers le feu de cuisine. §15.11 ne s'arrête pas à la
> porte du boss.
> G.2 : le combat. Un test par exigence chiffrée de §16, écrits pour faire
> échouer plutôt que pour confirmer. Deux défauts trouvés ainsi :
> — les 5 s d'éveil de §16.1 n'existaient pas. `_enter()` étant idempotent
> (ce qui protège les seuils de PV, §16.2), entrer dans INTRO depuis INTRO
> ne faisait rien : le timer restait à zéro et le Gardien basculait en
> phase 1 au premier tick. L'intro est désormais armée explicitement ;
> — le boss était INFAISABLE. Le test de solvabilité de §16.7, écrit avant
> tout réglage, a mesuré la marge à -16 % : sous des hypothèses
> pessimistes, le loot garanti plafonne à ~755 dégâts utiles, contre
> 900 PV. Les PV sont maintenant DÉRIVÉS de ce calcul — 560, marge +35 %,
> dans la bande 30-50 % que §16.7 impose. La borne haute est testée aussi.
> Le reste est joué avec les vraies pièces du jeu : deux pylônes (pas un)
> pour la mise à la terre, l'armure à ×0,2 qui n'est pas une
> invulnérabilité, les cristaux révélés en phase 2, le gourdin qui ne
> renvoie rien et la lame conductrice qui brûle les doigts en surcharge,
> le buff de résistance qui amortit, la fenêtre de télégraphe chronométrée
> entre 0,7 et 1,0 s et bornée à la construction.
> G.3 : la conclusion de §16.8, dans son ordre. Les hazards s'arrêtent, le
> puits de terre se tait et le rail s'éteint, le ciel se dissipe
> PARTIELLEMENT — il s'ouvre sans redevenir un midi bleu —, le coffre
> final naît au centre, `boss_defeated` est écrit, et la cinématique est
> passable : ouvrir le coffre la termine sur-le-champ. L'écran de victoire
> offre les trois issues exigées, avec cycle de focus fermé et
> confirmation avant d'écraser une partie terminée.
> **PROCHAINE ACTION (G.4)** : le run complet de 25-40 minutes du Gate G,
> du spawn à la victoire, sans debug — puis l'audit contradictoire.

## 2026-08-03 — Phase H, lot H.1 : le Gardien cesse d'être une capsule

> Le boss de la Phase G était un `CharacterBody3D` avec des `MeshInstance3D`
> VIDES : il n'avait littéralement aucun corps visible. H.1 lui en donne un,
> et c'est une création du projet — `tools/blender/make_storm_guardian.py`
> bâtit la bête-machine de VISUAL_ASSET_BIBLE §15.1 depuis des primitives,
> avec un seed fixe : six appuis dont deux antérieurs lourds, dos voûté,
> tête à trois plaques de céramique, épaules de bronze, queue segmentée
> terminée par une fourche de terre, anneau vertical incomplet en trois
> segments, noyau fendu au sternum. Aucun pack externe, aucune anatomie
> réelle citable.
> 27 meshes NOMMÉS, parce que les phases 2 et 3 les manipulent un par un.
> Les volumes de combat ont été replacés SUR le modèle, et un test refuse
> maintenant toute hurtbox qui ne serait pas dans le corps visible.
> Trois défauts trouvés en mesurant : `matrix_world` périmée après un
> reparentage (Blender annonçait 9,58 m quand Godot en mesurait 14,50) ; le
> parentage « BONE » qui accroche à la QUEUE de l'os (remplacé par des
> groupes de sommets à poids 1) ; et une boîte de collision dont le bas
> flottait à 0,80 m — le Gardien tombait indéfiniment, ce qui le rendait
> plus lent en phase 3 qu'en phase 1.
> Densité assumée : 6 324 triangles contre un plafond de 110-160k. La
> silhouette et la structure y sont, le détail de surface non. C'est au
> manifeste, pas caché.
> **PROCHAINE ACTION (H.2)** : les trois pillards en silhouettes réellement
> distinctes — l'ordre de la Phase H interdit qu'une variante de couleur
> tienne lieu de famille visuelle. Puis le colosse (H.3, modèle original
> rigged : « un humain agrandi ne constitue pas un colosse ») et le
> chasseur quadrupède (H.4, corps inférieur non équin).

## 2026-08-03 — Phase H, lot H.2 : trois pillards, trois corps

> Les trois pillards étaient le même modèle acheté, teinté trois fois —
> exactement ce que l'ordre de la Phase H interdit. Ils ont désormais trois
> géométries construites par le projet : le braise voûté aux avant-bras
> longs et aux excroissances tournées vers l'arrière, l'azur droit aux
> épaules segmentées en parenthèses, le briseur bas et très large à la
> visière fendue et aux deux plaques d'épaule inégales.
> Le SQUELETTE, lui, est celui qui existait : 65 os UAL, poids
> automatiques. `AL_RaiderStates.res` s'applique donc sans retargeting —
> refaire les rigs aurait voulu dire réécrire toutes les animations.
> Le test qui vérifiait des teintes vérifie maintenant des corps : tailles
> dans les bandes de la bible, ordonnées, briseur le plus large, maillages
> distincts. La couleur reste un marqueur de faction, plus une preuve.
> Deux défauts trouvés en mesurant : l'isolation des matériaux n'était
> déclenchée que par une teinte, si bien que le télégraphe d'attaque n'avait
> plus rien où écrire une fois la teinte supprimée ; et l'échelle partait
> DEUX fois vers glTF (cuite dans les sommets par `export_apply`, puis
> reportée par le nœud), Blender annonçant 1,42 m quand Godot mesurait 1,17.
> Règle qui en sort : une cote se vérifie dans Godot, jamais sur le log de
> l'outil qui l'a produite.
> Deux runs de validation ont aussi été perdus parce que j'ai ajouté des
> scènes référençant des `.glb` non importés PENDANT le run. Le dépôt doit
> rester figé entre le lancement et le verdict.
> **PROCHAINE ACTION (H.3)** : le colosse des ravins — modèle original
> rigged, torse incliné, bassin massif, bras ASYMÉTRIQUES dont un couvert
> d'une croissance rocheuse, nodule minéral pâle entre omoplate et nuque
> comme point faible. « Un humain agrandi ne constitue pas un colosse. »

## 2026-08-03 — Phase H, lots H.3 et H.4 : colosse et chasseur BÂTIS

> Les deux dernières familles n'existaient qu'en boîtes de graybox — une
> capsule de 3,8 m pour le colosse, deux boîtes pour le chasseur. Elles ont
> maintenant des modèles : `tools/blender/make_creatures.py`.
> Le colosse (3,97 m, bande 3,7-4,3) porte ce que la bible §14.4 demande :
> torse incliné, bassin massif, bras ASYMÉTRIQUES dont un couvert d'une
> croissance rocheuse, petites jambes puissantes, et le nodule minéral pâle
> entre omoplate et nuque qui est son point faible. Aucune massue : ses
> mains servent à arracher et à lancer.
> Le chasseur (3,20 m de haut, 4,69 m de long) a un corps inférieur bas et
> allongé, quatre pattes à trois doigts larges, les épaules avant plus
> hautes que la croupe, une queue courte en lames — ni sabots, ni crinière,
> ni croupe de cheval. Son torse supérieur naît EN AVANT du bassin
> inférieur, ce qui le distingue d'un centaure classique.
> **LIMITE À DIRE FRANCHEMENT** : les deux `.glb` sont dans le dépôt,
> valides à l'inspection, mais AUCUNE SCÈNE NE LES MONTE encore. En jeu,
> le colosse et le chasseur restent des boîtes. Le travail n'est pas perdu,
> il n'est pas fini.
> **PROCHAINE ACTION** : monter les deux modèles dans `RavineTroll.tscn` et
> `CentaurHunter.tscn` (entrées `char.ravine_troll` et `char.centaur_hunter`
> au registre, `CharacterVisual` sous le Pivot comme les pillards, graybox
> masqué, volumes de combat replacés SUR la géométrie et vérifiés par un
> test du même type que `test_the_combat_volumes_sit_inside_the_body_you_can_see`).

## 2026-08-03 — Phase H, H.3/H.4 montés : les cinq familles ont un corps

> Les deux modèles bâtis au lot précédent sont maintenant DANS le jeu.
> Colosse et chasseur passent par `CharacterVisual` comme les pillards :
> registre → wrapper → montage sous le pivot, graybox masqué.
> Un vrai défaut au passage : `EnemyBase._mount_visual()` ne masquait que
> `BodyMesh`. Le chasseur en porte DEUX (corps et torse) — n'en cacher
> qu'une laissait une boîte plantée dans le modèle. Tous les maillages
> enfants directs du pivot disparaissent désormais ; le modèle riggé, lui,
> vit sous `CharacterVisual` et n'est jamais atteint par cette boucle.
> Le chasseur a dû être RETOURNÉ : construit tête vers +Y en Blender, donc
> vers -Z après conversion, alors que les ennemis regardent +Z. Le colosse,
> lui, tombait juste — vérifié en mesurant, pas en raisonnant.
> Quatre tests neufs : cotes dans Godot, graybox masqués, nodule du colosse
> du même côté que la hurtbox arrière ×2, corps du chasseur plus de deux
> fois et demie plus long que large, et les deux créatures qui regardent le
> côté où elles frappent.
> **Limite assumée** : l'envergure du colosse (4,06 m) dépasse sa capsule
> (rayon 1,1 m). Règle ART-P0 — le modèle est un visuel, la capsule reste
> l'autorité. Le joueur peut passer « à travers » les bras tendus.
> **Limite** : aucune animation pour ces deux créatures. Les rigs sont là
> (8 et 6 os), les clips non : elles gardent leur pose de repos.
> **PROCHAINE ACTION** : les clips d'animation du colosse et du chasseur
> (locomotion lourde, balayage, frappe verticale, coup au sol pour l'un ;
> pas/trot/galop, charge, salve, cri pour l'autre — §14.4 et §14.5), puis
> ceux du Gardien (entrée 5-8 s, dégâts visuels progressifs, mort).

## 2026-08-03 — Phase H lot H.5 : la capture dit ce que les tests ne voient pas

> Le lot précédent avait « monté » les cinq familles, et tous les tests
> étaient verts. La première CAPTURE du vrai moteur a montré autre chose :
> les six modèles générés se lisent en PIÈCES DÉTACHÉES. Construits comme
> des empilements de boîtes indépendantes, ils laissent des jours de 0,15 à
> 0,25 m à chaque articulation — tête flottant au-dessus des épaules,
> avant-bras séparés du coude, queue en chapelet.
> Aucun test ne pouvait le voir : `get_aabb()` d'un maillage skinné rend la
> géométrie de LIAISON, pas le rendu, et les boîtes englobantes restaient
> dans les bonnes bandes pendant que les pièces flottaient.
> **Diagnostic initial FAUX, consigné** : j'ai d'abord accusé le skinning
> (transformation de nœud ignorée par glTF). Un ré-import du `.glb` dans
> Blender a montré le modèle correctement assemblé après déformation — la
> cause était la géométrie source. Le durcissement appliqué entre-temps
> (`apply_transforms` avant liaison) reste juste, et il est de toute façon
> exigé par `.claude/rules/assets.md`, mais il ne corrigeait pas ce
> défaut-là.
> Une passe de « mordant » — chaque volume RECOUVRE son voisin, les membres
> sont allongés d'un diamètre, les attaches ramenées dans la masse — a
> réparé les trois pillards et le tronc du colosse. C'est visible sur
> `evidence/phaseH/lineup_matiere.png`.
> **CE QUI N'EST PAS FINI** : avant-bras et pieds du colosse, chasseur
> presque entier, extrémités du Gardien. ISS-018, sévérité S2. Aucun
> critère visuel de la Phase H n'est déclaré tenu.
> La bibliothèque de silhouettes est passée de quatre à SEPT sujets — sans
> le colosse, le chasseur et le Gardien, elle ne pouvait pas servir au test
> d'affordance de §30.3 qu'elle est censée porter.
> **PROCHAINE ACTION** : poursuivre la passe de mordant créature par
> créature, en RE-CAPTURANT après chacune — c'est le seul contrôle qui voit
> ce défaut. Puis écrire le test de contiguïté d'ISS-019 pour qu'il ne
> revienne pas en silence.

---

## 2026-08-03 — Phase H, lot H.6 : ISS-018 clos par la cause, pas par retouches

**Commits** : `30ae2d3` (continuité), `29a3303` (corps des pillards),
`be96545` (chasseur + planche d'inspection).

### La cause racine, enfin

La passe de « mordant » de la session précédente traitait un symptôme.
La cause tient en une ligne : `bmesh.ops.create_cube(size=1.0)` pose ses
sommets à **±0,5**, donc la taille passée à `add_box` et `limb` est la
dimension **pleine**. Un `* 0.5` traînait sur la longueur de chaque segment
dans `make_creatures.py` et `make_raiders.py` ; les mêmes facteurs `* 0.62`
et `* 0.52` dans `make_storm_guardian.py`. Chaque membre était donc bâti à
la moitié — ou aux deux tiers — de sa portée et s'arrêtait à mi-chemin de
son articulation. Le mordant que les commentaires décrivaient n'a jamais
existé.

Vérifié par un script d'une ligne dans Blender, pas déduit.

Corrigé à la source, puis pièce par pièce sur ce que la MESURE indiquait :
nodule du colosse à 39 cm du dos, ceinture de troncs autour du vide, doigts
sous la paume, cage thoracique du chasseur en rondelles, bras du chasseur et
des pillards sans clavicule, anneau du Gardien orienté radialement au lieu
de tangentiellement, et un tiers d'anneau entièrement en l'air.

### Le contrôle qui manquait (ISS-019)

`tools/blender/check_continuity.py` lit le `.glb` LIVRÉ, évalue le graphe de
dépendances — donc **après déformation par l'armature** —, ressoude les
sommets que l'export glTF sépare, découpe en morceaux connexes et exige
**un seul corps solidaire**.

Trois pièges de mesure, tous rencontrés et tous corrigés :

1. **sans ressoudure**, l'export sépare les sommets par normale et par UV :
   le Gardien comptait 1520 « îlots » d'une face, tous voisins entre eux, et
   le contrôle ne voyait rien ;
2. **« chaque pièce a un voisin » ne suffit pas** : le chasseur passait ce
   critère avec ses deux bras flottant à 11 cm du buste, chaque bras
   touchant son propre avant-bras. D'où le critère de connexité globale, qui
   a immédiatement révélé la même faute sur deux des trois pillards ;
3. **la distance sommet à sommet ment** sur deux boîtes tournées l'une par
   rapport à l'autre : l'anneau du Gardien ressortait « détaché » alors que
   ses maillons s'enfilaient.

Câblé en niveau **3b** de `tools/validate_fast.sh`. Contrôle négatif : une
pièce déplacée de 0,60 m fait sortir le script en code 1, le modèle réparé
en code 0.

### Deux décisions de qualité prises seules

**Les pillards reprennent le corps du pack CC0.** La capture les montrait en
figurines de fil de fer : membres de 4 cm de section. Le pack Quaternius
« Universal Base Characters », déjà dans le dépôt et déjà attribué, fournit
un humanoïde de 12 894 triangles texturé en PBR et pesé sur les mêmes 65 os
— et `load_skeleton` le JETAIT pour ne garder que l'armature. Le corps est
conservé ; restent construites les pièces qui distinguent les familles. La
tête en fait partie : les personnages Quaternius sont modulaires et livrés
sans tête, ce qui tombe bien puisque la bible §14.1-14.3 demande des crânes
non humains. `ATTRIBUTIONS.md` requalifie les pillards en œuvre dérivée avec
la liste exacte des modifications.

**Le chasseur passe du plateau à la bête.** Cage thoracique portée de 0,52 à
1,00 m de profondeur, poitrail nettement plus haut que la croupe, tronc de
liaison entre le poitrail et le buste — la jonction que l'ordre nommait —,
épaules et hanches ajoutées, pattes épaissies.

### Preuves

- `evidence/phaseH/turntable_*.png` + manifestes : chaque personnage de
  face, de trois quarts, de profil, de dos et en aplat noir ;
- `evidence/phaseH/bestiaire_apres.png` : les cinq familles côte à côte ;
- `evidence/pipeline/continuity_*.log` : six personnages, un seul corps.

Nouvelle scène de DEV `CharacterTurntable` (`--creature=<id>`). L'alignement
du bestiaire ne montrait que la face à 25 m : une pièce détachée sur le
flanc ou dans le dos y restait invisible, et c'est ainsi qu'ISS-018 avait
survécu à une capture.

### Ce qui reste honnêtement à faire

Les créatures restent des assemblages de primitives : lisibles, cohérentes,
aux bonnes cotes, mais sans sculpture. Le Gardien et le colosse sont au
plafond de qualité de cette approche. Aucun score visuel n'est revendiqué —
le WOW Gate de §30.2 porte sur la vue d'ouverture, pas sur le bestiaire, et
il n'a pas été rejoué.

**PROCHAINE ACTION** : Phase H suite — reprendre l'ordre des lots là où
`docs/ROADMAP.md` le laisse, la continuité des personnages n'étant plus un
obstacle.

---

## 2026-08-03 — Phase H, lot H.7 : prairie de crête · et prise en compte de l'ordre d'EXTENSION

**Commit** : `96950f0`. `validate_fast.sh` **VERT**, 493 tests, plancher
relevé 490 → 493. Preuve : `evidence/phaseH/vista_prairie.png` (manifeste
`repo_dirty: false`, commit `96950f0`).

### Ce qui a été fait

La vue d'ouverture a d'abord été capturée telle quelle : c'est un graybox.
Le tiers inférieur du cadre, que §3.2 veut porter « une pente herbeuse
riche », était un aplat vert. La prairie tournait à **0,6 touffe/m²** contre
7 à 14 exigées par §7.2 — et le test qui la couvrait demandait « au moins
300 instances par cellule », critère qu'une prairie vide satisfait du moment
qu'elle est large. **Un nombre d'instances ne dit rien sans la surface.**

Densité portée à 9 touffes/m² en zone héroïque et 4,5 sur les côtés, quatre
cellules de 23 m (§7.5). Monter la densité a révélé la faute que la rareté
cachait : la touffe était faite de trois quads de 34 cm, et le premier plan
s'est couvert de petits sapins. Brins refaits à 3,6 cm, sept par touffe,
ployés, normales inclinées à 72 % vers le ciel (voir D-039 et D-040).

### ORDRE D'EXTENSION reçu — état des lieux fait, travail NON commencé

L'ordre demande un monde 500 × 500 m entièrement explorable : village de la
rivière, deux hameaux, ruines, grottes, lieux naturels, territoires ennemis,
système de découverte, densité d'un intérêt toutes les 45-75 s, itinéraires
multiples, vie et narration environnementale.

**Découverte importante pour la suite** : tout le nécessaire est DÉJÀ sur
disque, en CC0, sans aucun téléchargement.

- Les sept packs Quaternius sont extraits dans
  `/tmp/eclats-quaternius.X2JMwF/extracted/` (992 Mo, 2162 fichiers).
- `Medieval.Village.MegaKit` (936 fichiers) est un kit modulaire complet :
  murs plâtre et brique, portes et encadrements, fenêtres, sols, toits,
  balcons, débords, angles, escaliers, clôtures, cheminée, chariot. C'est le
  village, les hameaux, les ruines ET les intérieurs.
- `Stylized.Nature.MegaKit` (454) : 31 familles — 5 arbres communs,
  5 pins, 3 tordus, arbres morts, buissons, fougères, fleurs, champignons,
  trèfle, VRAIS modèles d'herbe, galets, dalles de chemin, rochers.
- `Fantasy.Props.MegaKit` (517) : enclume, établi, étal de marché, tonneaux,
  caisses, lits, tables, bibliothèques, chaudron, bannières, torches,
  lanternes, râteliers, outils.

`tools/promote_quaternius.py` promeut une sélection CURATÉE : ses 744
fichiers sont déjà dans le dépôt (~140 `.gltf`). Étendre le monde demande
donc d'**élargir la sélection de l'outil**, pas de retélécharger.

**RISQUE À TRAITER EN PRIORITÉ** : `/tmp` est éphémère. Si ce répertoire est
recyclé, les packs sont perdus — la réacquisition avait échoué (403 du
Godot Asset Store, voir `docs/assets/QUATERNIUS_INBOX.md`). La première
action de la prochaine session doit être de promouvoir dans le dépôt les
familles nécessaires au monde ouvert.

### PROCHAINE ACTION, dans cet ordre

1. **Sauver les assets** : élargir la sélection de `promote_quaternius.py`
   (kit village complet, arbres et rochers manquants, props de village) et
   promouvoir depuis `/tmp/eclats-quaternius.X2JMwF/extracted/`, tant qu'il
   existe. Mettre à jour `ATTRIBUTIONS.md` et le manifeste.
2. **Chasseur de production** (point 1 de l'ordre) : tête et silhouette
   restent faibles ; la planche `CharacterTurntable --creature=chasseur` est
   l'outil de jugement.
3. **Registre des points d'intérêt et système de découverte** (§3 et §8 de
   l'ordre) AVANT de poser du contenu en masse : identifiant stable, nom au
   premier passage, sauvegarde, aucune seconde récompense au rechargement,
   test d'atteignabilité. C'est vérifiable en headless, donc réellement
   validable ici — contrairement à la géométrie.
4. Puis le contenu : village de la rivière, hameaux, ruines, grottes.

### Limites honnêtes de l'état actuel

La vallée reste un graybox hors premier plan : montagnes en boîtes grises à
plein contraste, citadelle sans terrasses qui se confond avec elles, sol en
aplat vert, cubes de placeholder, HUD visible dans les captures de
référence. Aucun score WOW n'est revendiqué (§30.2 demande un œil humain et
un GPU réel — ISS-002).

---

## 2026-08-03 — Ordre d'extension : assets sécurisés, chasseur, registre des découvertes

**Commits** : promotion CC0, `b7ec49d` (tête du chasseur), puis le présent
lot (registre des découvertes).

### 1. Assets du monde ouvert sauvés de `/tmp`

Les sept packs Quaternius vivaient dans `/tmp`, éphémère, et leur
réacquisition avait échoué (403). 63 modèles promus par sélection
**fonctionnelle** — pas en vrac, comme l'exige §7 de l'ordre : toitures et
débords, sols d'intérieur, portes, fenêtres de toit, escaliers, balcons,
clôtures, cheminée ; puis essences par biome, herbes hautes, plantes,
rochers, dalles. Nouveau dossier `assets/environment/village/` : 53 pièces
d'architecture modulaire, de quoi bâtir un village à VRAIS intérieurs, deux
hameaux et des ruines. 56,8 Mo après déduplication des textures par dossier
cible — le chiffrage brut annonçait 715 Mo en comptant chaque texture une
fois par modèle. `ATTRIBUTIONS.md` : ART-Q8, même CC0 que ART-Q0.

### 2. Chasseur — point 1 de l'ordre

La tête n'était qu'un cube : à distance de jeu la bête n'avait pas de
regard, donc aucune direction de menace avant la charge. Crâne refait en
quatre masses (nuque, crâne, museau, mâchoire), plaque frontale inclinée,
deux cornes filant vers l'arrière, mandibules élargies. Cotes tenues :
3,45 m de haut, 4,20 m de long. Continuité : 64 morceaux, un seul corps.

### 3. Registre des découvertes — la fondation du monde ouvert

`DiscoveryLog` + `PointOfInterest`. Choix structurant : **un lieu ne sait
pas s'il a déjà été vu, il le DEMANDE**. La règle « aucune seconde
récompense après rechargement » devient donc vraie par construction, pas par
discipline — un lieu ne peut pas se déclarer neuf tout seul.

Identifiants au format §19.3 `zone.category.name.index`, unicité refusée en
double, sauvegarde ne sérialisant que des chaînes (§19.2), lieu supprimé par
une mise à jour journalisé puis ignoré (§19.4), regroupement par région pour
une carte.

12 tests : 9 unitaires, 3 d'intégration avec un vrai corps physique qui
traverse le volume. Le scénario central de l'ordre est couvert de bout en
bout — découvrir, sauvegarder, recharger, repasser, ne rien recevoir.

Détail qui aurait fait rougir la suite entière : les refus (identifiant en
double, lieu non déclaré) étaient signalés par `push_error`, et
`validate_fast` traite — à raison — tout `ERROR:` du journal comme un échec.
Un refus lu dans la valeur de retour n'est pas une erreur moteur : ils sont
passés en avertissement.

Plancher de couverture 493 → 505.

### PROCHAINE ACTION

Poser le CONTENU, maintenant que chaque lieu peut naître avec son
identifiant, sa sauvegarde et son test :

1. **Village de la rivière** (§2 de l'ordre) avec le kit promu : place,
   auberge visitable, forge, marché, moulin, sanctuaire, habitations, quai.
   Au moins un intérieur réel — §1 interdit une porte visible qui n'ouvre
   sur rien.
2. Deux hameaux, puis les ruines, puis les grottes.
3. À chaque lieu : un `PointOfInterest` avec identifiant, un contenu
   significatif (§3), et un test d'atteignabilité (§8).
4. Carte des POI et liste des identifiants (§8) — le registre les fournit
   déjà par `registered_ids()` et `by_region()`.

### Limites honnêtes

Aucun contenu de monde ouvert n'est encore posé : le lot ci-dessus livre les
FONDATIONS et les assets, pas les lieux. La vallée reste un graybox hors
premier plan.

---

## 2026-08-03 — Monde ouvert : premier lieu posé, village de la rivière

`validate_fast.sh` VERT à 509 tests avant ce lot ; plancher désormais 510.

### Fait

**Village de la rivière**, bâti du kit modulaire CC0 promu juste avant :
auberge, forge, moulin, sanctuaire, deux habitations, place de marché,
quai. Monté dans `ValleyWorld` — un lieu bâti mais jamais posé ne compte
pas — et déclaré au journal sous `valley.poi.riverside_village.01`.

**Le point dur de §1 est tenu et PROUVÉ** : l'auberge a un intérieur réel.
Le test y fait entrer un corps physique, exige qu'il se pose sur un
plancher, puis le pousse contre chaque mur et exige qu'il reste dedans. Un
décor de façades aurait passé n'importe quel test de comptage.

Cela imposait une collision posée à la main : le kit est purement visuel, et
un collider unique par mur aurait muré l'auberge de l'intérieur. Un mur à
baie reçoit deux jambages et un linteau. Les habitations, elles, sont
fermées — pas de porte praticable, donc aucune promesse trompeuse.

Les découvertes partent dans la sauvegarde de la vallée et en reviennent.

### PROCHAINE ACTION

1. **Resserrer le village** : la capture le montre en maisons éparpillées,
   pas en bourg groupé autour d'une place. Rapprocher les corps de bâtiment,
   dessiner la place au sol, poser des chemins entre les portes.
2. **Habitants** (§6) : quelques villageois qui marchent entre deux points,
   fumée de cheminée, lumière aux fenêtres.
3. **Deux hameaux** (§2), puis les RUINES, puis les GROTTES — chacun avec
   son `PointOfInterest`, son contenu significatif (§3) et son test
   d'atteignabilité.
4. **Carte des POI et liste des identifiants** (§8) : `registered_ids()` et
   `by_region()` les fournissent déjà, il reste à les écrire dans un
   document et à les relier aux captures de région.
5. Puis §4 (rythme d'exploration), §5 (itinéraires multiples), §9 (passe
   artistique de la vallée, performances, Phase H, puis I et J).

### Limites honnêtes

**Un seul lieu sur la liste de §2 est posé.** Manquent : les deux hameaux,
les ruines, les grottes, les lieux naturels mémorables, les territoires
ennemis, les habitants, les histoires environnementales, la carte des POI et
le parcours d'atteignabilité de toute la carte. La vallée reste un graybox
hors premier plan et hors village. Aucun score visuel n'est revendiqué.

## 2026-08-03 — Monde ouvert MO.4 : les ancrages de récompense

Commits `2bf440f`, `018b8b6`, `9538dcf`.

### Ce qui a changé

Les 31 lieux portent chacun un `RewardAnchor` explicite, nommé, déclaré dans
la table de son bâtisseur. Plus aucun repli au centre du volume.

Les positions ne sont pas choisies : `tools/godot/probe_reward_anchors.gd`
monte la vallée réelle et éprouve, autour de chaque lieu, sol, dégagement au
gabarit du joueur, couloir d'approche, absence d'eau et LIGNE DE VUE depuis le
point de station. Le résultat est figé dans le code.

`RewardAnchorAudit` fait ensuite marcher un corps : aller, retour, et pour le
belvédère la montée complète de l'échine — un navmesh aurait répondu
« accessible » sans rien prouver.

Les récompenses sont diversifiées et pilotées par données : coffres, armes au
sol, ingrédients, savoirs, fragments d'histoire lisibles.

### Ce que les preuves ont réellement trouvé

L'audit physique a rendu 14 défauts au premier passage, puis 3, puis 1. Quatre
causes distinctes, aucune contournée : la récompense masquait le sol sous son
propre ancrage ; la sonde prenait pour sol le coffre du tour précédent ; un
rocher en surplomb servait de sol ; un point d'arrivée dégagé au bout d'un
couloir muré.

Puis les 31 captures ont montré ce que la physique ne pouvait pas voir : trois
récompenses **dans l'eau**, deux **derrière le tronc** de l'arbre qui donne son
nom au lieu, une **hors champ**. D'où les deux règles ajoutées à la sonde —
volumes d'eau lus par leur nom, et ligne de vue exigée.

Deux bogues réels ont été corrigés au passage, tous deux masqués par l'ordre de
construction : les découvertes n'étaient **jamais** restaurées au rechargement,
et les récompenses échappaient à la persistance — une arme ramassée revenait.

### Prochaine action exacte

1. Relancer `tools/godot/capture_reward_anchors.gd` et réinspecter les 31 vues
   après le déplacement des huit ancrages.
2. Relever `MIN_TESTS` dans `tools/validate_fast.sh` au nombre réellement
   exécuté, puis lancer la validation complète.
3. Commit propre, puis publication de l'archive par le workflow
   `publish-playtest.yml` (éprouvé en mode auto-test : Release créée, ZIP et
   `.sha256` téléversés).

### Limites honnêtes

Six lieux — les cinq territoires et la cavité de cristal — portent une
récompense dont la condition d'ouverture n'existe pas. Le coffre est réel et
persistant ; le verrou, non. `DiscoveryRewards.deferred_gates()` les nomme.

La vallée reste un graybox hors premier plan et hors lieux. Aucun score visuel
n'est revendiqué.

---

## 2026-08-04 — Un vrai joueur visuel, et ce qu'il a trouvé du premier coup

Commit `96ad94a` (dispositif) puis le lot d'échelle du kit.

### Le problème qu'on a arrêté de contourner

Les deux « playtests » précédents n'en étaient pas. Le premier exécutait un
plan écrit à l'avance ; le second fermait la boucle mais la décision venait de
moi — quelqu'un qui a lu le code, connaît la carte et sait où sont les
coffres. Un joueur qui connaît la solution ne mesure rien.

### Ce qui a été construit

Un serveur MCP stdio (`tools/blackbox_player/server.py`) qui expose cinq
outils et rien d'autre : regarder, agir, cliquer, attendre, noter. Chaque appel
renvoie la nouvelle image — le joueur ne PEUT pas agir deux fois sans regarder.

Les entrées sont réelles : `xdotool` parle au serveur X, Godot les reçoit comme
un clavier, elles traversent l'InputMap puis `PlayerInputReader`. Aucune
méthode de gameplay n'est appelée. Le jeu est suspendu par `SIGSTOP` pendant
que le modèle réfléchit — extérieur au jeu, donc sans fuite d'état privé.

Le joueur est un processus `claude -p` **neuf**, dont les outils sont imposés
par `--allowedTools`/`--disallowedTools` : ni Read, ni Bash, ni Grep, ni Glob,
ni Web. Il ne peut pas lire le code même s'il le voulait.

### Deux vérifications qui ont changé le plan

`.mcp.json` et `.claude/agents/*.md` sont lus au **démarrage** de Claude Code.
Créés en cours de session, ils ne sont pas chargés — constaté deux fois. D'où
le processus séparé plutôt que le sous-agent.

L'API Computer Use n'est pas accessible ici : ni clé, ni SDK `anthropic`.
Vérifié, pas supposé.

### Ce que le joueur a compris seul

`Z Q S D`, l'orientation du personnage, le sprint, et **l'endurance déduite de
la barre bleue** apparue pendant le sprint. Personne ne le lui a dit. Il a vu
la citadelle, l'éclair, le camp de bois, et s'y est dirigé.

### Ce qu'il a trouvé, et que 585 tests n'avaient pas vu

Une fleur jaune occupant un quart de l'écran, plus haute que la poitrine du
héros. Mesure : `Flower_4_Group` = **2,49 m**, quand la bible §3 borne les
fleurs à 0,18–0,55 m. Et ce n'était pas un cas isolé : `Fern_1` fait **9,05 m
de large**, `Grass_Common_Tall` 1,87 m, `Clover_2` 1,26 m.

Le kit végétal entier avait été importé sans normalisation et posé à l'échelle
native par **sept** modules. C'est une violation de l'invariant « 1 unité =
1 m », pas un désaccord de goût : une fougère de neuf mètres détruit la lecture
d'échelle, donc la profondeur, donc la composition North Star.

Corrigé par `KitScale` — un seul point, une table qui garde hauteur mesurée ET
hauteur visée pour rester vérifiable. Deux tests de régression : un à la source
(un asset ajouté demain sans échelle échoue), un dans la vallée montée (une
table correcte mais non appliquée échoue).

### Prochaine action exacte

1. Lancer les trois contrôles négatifs
   (`tools/blackbox_player/negative_controls.sh`). **Tant qu'ils n'ont pas
   tourné, on ne sait pas si un joueur privé d'image continuerait de « raconter »
   le jeu — auquel cas tous les verdicts seraient sans valeur.**
2. Valider l'arbre courant : `tools/validate_fast.sh` (plancher 586).
3. Enchaîner les parcours B à E, un profil par parcours, jusqu'au boss.

### Limites honnêtes

Le parcours A s'est arrêté à l'approche du camp : **aucun combat n'a été
gagné**, donc aucune note sur le combat n'est recevable. `BL-01` reste ouvert —
le jeu complet n'a jamais été terminé en boîte noire.

---

## 2026-08-04 — Le joueur ne bougeait pas : le harnais parlait la mauvaise disposition

Deux sessions blackbox successives se sont arrêtées avant le camp, sans combat.
La première a conclu à une « limite invisible » du monde. C'était faux, et la
mesure le montre : entre deux captures séparées par 2 s de sprint, la bande de
**fond** (y = 100..300) ne variait pas d'un pixel — `0.000`. Un personnage
bloqué par une collision fait quand même bouger la caméra. Là, rien.

### La cause

`project.godot` mappe ses actions en `physical_keycode` : `move_forward` = 87
(W), `move_left` = 65 (A). C'est **correct** — un code physique désigne une
position, étiquetée selon le clavier US, et c'est exactement ainsi qu'on écrit
« AZERTY : Z avance, Q va à gauche » sans casser le QWERTY.

Le harnais, lui, envoyait `xdotool keydown z` sur un Xvfb en disposition **US** :
la position du Z américain, jamais celle du W. Aucune action de déplacement ne
pouvait se déclencher.

Ce qui a mis sur la piste, c'est une **asymétrie** : `Échap` ouvrait bien la
pause et les clics de menu fonctionnaient. Or ce sont précisément les entrées
identiques dans les deux dispositions. Seules les lettres déplacées échouaient.

### Correction et preuve

`KEYMAP` traduit désormais l'étiquette AZERTY vers la position physique
(`z` → keysym `w`, `q` → keysym `a`), et `shift`/`ctrl` passent aux keysyms
canoniques. Vérifié à deux niveaux — livraison des touches par `xev` sur un
Xvfb jetable, puis bout en bout dans le jeu : ancien mapping `0.013` (bruit),
nouveau `1.782`, puis sprint `13.27`, gauche `50.80`, arrière `20.25`, droite
`28.58`, saut `17.19`. Preuve : `evidence/blackbox_player/fix_clavier_20260804_034919/`.

Un second défaut du harnais a été corrigé au passage : `xdotool mousemove
--sync` gelait 60 s chaque rotation de caméra, parce qu'il attend une position
que Godot ne laisse jamais atteindre en souris capturée. Le joueur n'avait donc
aucune caméra non plus.

### Ce que cela change

Le héros traverse la prairie, atteint une clairière d'où les huttes du camp
sont visibles, et la **jauge d'endurance turquoise** apparaît au sprint — un
élément d'interface qu'aucun playtest n'avait encore pu observer.

### Prochaine action exacte

1. Dépouiller le parcours du joueur vierge lancé sur la version corrigée, dont
   l'objectif unique est de **gagner un combat**. Tant qu'aucun combat n'est
   gagné, `BL-01` reste ouvert et aucune note de combat n'est recevable.
2. Corriger `S1 — Le menu Pause enferme le joueur` (voir `KNOWN_ISSUES.md`) :
   c'est le prochain blocage sur le chemin critique, et il perd la partie sur
   place. Piste à instruire : `process_mode` des nœuds du panneau.
3. Ajouter un écran de chargement (`S2`) : 32 à 65 s de noir muet, deux joueurs
   ont cru à un plantage.

### Limites honnêtes

Le correctif prouve la **locomotion**, rien d'autre. Combat, endurance,
durabilité, arc, esquive, donjon et boss restent `UNVERIFIED` en boîte noire.

---

## 2026-08-04 — Phase I (volet export) : premier binaire Linux autonome publié

### Ce qui a été fait

- **Export local prouvé** : templates `linux_release` compilés depuis
  `/opt/src/godot` (le proxy refuse godotengine.org), installés sous
  `4.7.1.stable` ET `4.7.1.stable.custom_build` ; export du preset
  `Linux x86_64` (PCK embarqué) → `builds/linux/EclatsDOrage.x86_64`
  (371 Mo), `savepack DONE`, `--version` répond `4.7.1.stable.custom_build`.
- **Workflow enrichi** (`publish-playtest.yml`) : le runner GitHub télécharge
  le Godot 4.7.1-stable officiel + templates, exporte le binaire et le joint
  à la Release (zip + sha256), en *meilleur effort* (`continue-on-error`) —
  un échec du binaire ne bloque jamais l'archive source.
- Deux itérations de mise au point, chacune tracée au run exact :
  1. `ls motif_A motif_B` sous `pipefail` mourait quand UN motif ne matchait
     rien (run 30940389658) → `|| true` + garde-fou conservé ;
  2. `rm -rf builds/linux` emportait le `.gitkeep` suivi et le garde-fou de
     propreté refusait (run 30941179807) → suppression du seul binaire.
- **Release verte** : `playtest-3038fc5` (run 30941820988), 4 assets —
  archive source 396 Mo, binaire Linux 287 Mo, deux `.sha256`.

### Ce que cela change

§25.1 « build natif disponible » passe de promesse à fait : un testeur Linux
lance le jeu sans installer Godot. Chaque prochaine Release embarquera le
binaire automatiquement.

### Prochaine action exacte

1. Répondre à la question Phase H en attente : « le jeu doit ressembler à
   l'image North Star — comment faire ? » (plan honnête, limites du conteneur).
2. Relancer la suite playthrough (golden path) tuée par le redémarrage du
   conteneur — peu coûteuse, verdict requis avant toute note Gate G/J.
3. `BL-01` (victoire en combat en boîte noire) reste ouvert — ne PAS relancer
   de joueur visuel sans accord explicite (coût).

### Limites honnêtes

Le binaire runner n'a pas été **lancé** (pas de GPU sur le runner non plus) :
il est le produit de la même chaîne d'export que le binaire local vérifié,
rien de plus. Profilage, budgets de frame et session 60 min : toujours
impossibles ici (ISS-002).

---

## 2026-08-04 — Passe H-1 : silhouettes (montagnes, nuage, citadelle, arbres)

### Ce qui a été fait

Diagnostic sur `evidence/phaseH/vista_horizon_etage.png` contre la grille
§30.2 (≈ 40/100, honnêtement), puis correction des quatre pires défauts :

- **Montagnes** : 44 crêtes + 64 massifs lointains convertis de `BoxMesh`
  (« mur de gratte-ciels ») en `PrismMesh` à sommet décentré déterministe
  (R-015 : `left_to_right`, vérifié dans la source 4.7.1).
- **Nuage** : 14 grumeaux en deux étages, hauteur proportionnelle au rayon
  (0,9-1,5×), jupe sombre — la « soucoupe » venait de lobes de 8-13 m de
  haut pour ~26 m de rayon.
- **Citadelle §2.4** : masse 24→34 m, épaules latérales, tours coupées à
  4 hauteurs, spire en 3 segments + cône (sommet y = 100), conduit cyan.
  L'éclair frappe désormais le SOMMET DE LA SPIRE (cellule remontée à
  y 118 ; invariant testé |impact − spire| ≤ 6 m).
- **Arbres torsadés** : feuilles rouge sang (RGB 95/13/13) → variante olive
  (ratio V/R 1,48), 4 gltf repointés, dérivation dans `ATTRIBUTIONS.md`.
- **Palette** : `COL_GRASS_LIT` recalé sur l'ancre `#B2C85A`.

Fail-first : 13 échecs avant, 22 assertions vertes après
(`test_phase_h_silhouettes.gd`).

### Dettes découvertes par la suite complète (corrigées dans la foulée)

1. Deux worktrees d'agents FUSIONNÉS traînaient dans `.claude/worktrees/`
   → 228 faux « parse errors » (doublons de `class_name`). Supprimés.
2. Le test de grâce anti-stunlock frappait 2× en 0,45 s : la fenêtre de
   mercy (0,6 s, commit 9d55cf1) bloque désormais le 2e coup. Test recalé
   sur [0,60 ; 0,85] s — son esprit (la grâce ne protège que la réaction)
   est intact.
3. Les berges de rivière pleine longueur (d3edd75) enterraient l'ancrage
   de l'Arche de pierre 0,67 m sous leur pente. Berges percées sur la
   travée du pont (x −24..−4) : le site garde son lit aménagé.

### Verdict de la capture (`vista_h1_silhouettes`, commit 2ca5713)

Gagné : arbres olive, nuage cumuliforme accroché au haut du cadre, spire et
étagement de citadelle lisibles, crêtes triangulaires. Score §30.2
auto-évalué ≈ 47/100 (baseline ≈ 40).

### Passe H-2 exécutée (a/b/c/d — verdict)

Quatre itérations tracées à l'instrument (sondes + mesures de zones) :
l'éclair frappe la spire et se lit (colonne 18 m, halo 2,2 m) ; la face
sud du plateau — le VRAI « mur-barrage » mesuré, pas le mur de bordure —
porte 14 jupes ocre ; le mur de bordure porte 52 jupes hautes ; le sol a
une variation macro RÉELLE (deux causes racines : distribution FBM
gaussienne → gradient resserré, et mips en vue rasante → anisotrope +
motifs 15 m — R-016). Score §30.2 auto-évalué ≈ 50/100 : les gains sont
réels mais l'image reste dominée par les chantiers différés.

### Passe H-3 exécutée (a/b/c — verdict)

LA transformation de la Phase H à ce jour : la crête descend en PENTE
vers la vallée (SpawnSlope ~15°, invariant testé : aucune marche > 4 m
sur l'axe), le héros se tient au bord de la rupture (spawn z 146), la
caméra plonge à −8° — la vallée est enfin EN CONTREBAS comme dans la
référence, trois plans réels, l'éclair frappe la spire dans le cadre.
L'audit des ancrages a gouverné le tracé deux fois (ferme abandonnée,
puis sanctuaire forestier — déplacé à (34, 94), aucun test ne
l'épinglait). Navmesh rebaké deux fois. Score §30.2 ≈ 52/100.

### Passe H-4 exécutée — verdict

Plafonds du fond nord testés (crêtes ≤ 96, pics ≤ 96 coins compris,
rangée éloignée ≤ 112) et flore de pente (3600 brins qui épousent
l'inclinaison ±0,6 m testé, 340 fleurs concentrées vers la rupture).
Gain réel mais BORNÉ par la géométrie : à pitch −8° (haut de cadre
+13°), un fond à 96 m sur 400 m pointe encore à ~10° — le ciel ne peut
pas dépasser ~20 % du cadre tant que le CONTREBAS ne se creuse pas.
La référence a ~60 m de dénivelé héros→vallée ; nous en avons 22.
Score §30.2 ≈ 53/100.

### Passe H-5 exécutée — verdict

Crête à 32 m, contrebas 30 m (testé ≥ 28), pente raidie à 19,6° à emprise
IDENTIQUE (zéro nouveau conflit d'ancrage), rampe A ré-ancrée, fumée du
camp relevée avec l'œil (invariant croisé S3 verrouillé par le test :
sommet 44,5 > 40). Le village se lit nettement EN DESSOUS — la profondeur
a gagné ce que la géométrie promettait ; le ciel, peu (~+3 %, comme
calculé). Score §30.2 ≈ 55/100. AVANT le patch : fausse alerte S1 donjon
réfutée par bissection des journaux (R-017 — contention CPU, zéro
régression réelle).

### Passe H-6 exécutée — verdict

Couronne de capture (anneau de cuivre patiné incliné, TorusMesh — la
foudre la frappe), trois lignes d'énergie descendantes, quatre
contreforts, pierre ocre/bronze (r−b 0,012 → 0,08). La couronne et les
lignes portent l'identité « Résonance » de la focale ; la chaleur de la
pierre se perd dans la brume à 360 m. Score §30.2 ≈ 56/100.

### Prochaine action exacte (H-7 et au-delà — le mur de l'art)

Les passes géométriques ont donné l'essentiel de leur valeur (40 → 55).
Ce qui sépare 55 de 85 est désormais de l'ASSET : citadelle au langage
§2.4 complet, camp lisible dans le cadre, matériaux painterly
(SH_RockTriplanar/SH_GroundBlend réels), silhouettes de montagnes
sculptées, pétales-quads. Chantiers plus longs, à séquencer en sessions.
Reste aussi : flancs de SpawnSlope (dette H-3), correction de fond
ISS-024 (budgets en ticks).

### (ancien plan H-5)

1. **Creuser le contrebas** : crête 24 → ~36-40 m (spawn, vista, pente
   rallongée, paliers, meadow) OU plaine nord abaissée — à trancher en
   ouvrant avec l'audit des ancrages ET le golden path (la descente
   fait partie du chemin critique). C'est LE déblocage du ciel et de
   la profondeur — les deux domaines §30.2 encore à la traîne.
2. Fleurs de pente : les pétales-cubes lisent « Minecraft » en gros
   plan — passer à 2 quads croisés ou réduire à 0,08 m.
3. Flancs de la SpawnSlope (dette H-3, toujours ouverte).

### Ancien plan H-4 (réalisé)

1. **Ciel trop mince** (~15-20 % du cadre vs 38-48 % référence) : la
   crête devrait dominer la vallée davantage, ou l'horizon descendre —
   chantier macro-terrain (crête +8-12 m ? plaine −4 m ?), à trancher
   avec l'audit des ancrages dès l'ouverture.
2. **Fond pâle en boîtes** : la bande skyline/mur au-dessus du plateau
   reste l'élément le plus « graybox » du cadre — passer les GRANDES
   faces au langage prismes/jupes, ou les fondre davantage (fog).
3. **Fleurs et brins sur la pente** : la rupture est nue — la référence
   y met fleurs et herbes longues (§1.1 : premier plan végétal Y 72-100 %).
4. **Flancs verticaux de la SpawnSlope** (dette H-3) : adoucir par
   éboulis/prismes.

### Passe H-3 — limites honnêtes

Camera §1.1 vérifiée par calcul avant travaux : azimuts déjà conformes
(héros 0,42, citadelle 0,50, camp 0,85, pylône 0,96 — l'ordre de la
référence) ; le manque était VERTICAL, d'où la pente. La « tour blanche »
suspectée était la cascade (écume COL_FOAM) — conforme à la référence,
conservée.

### Limites honnêtes

Rendu llvmpipe : la capture prouve la composition et les couleurs, jamais
la performance. Le score §30.2 restera une auto-évaluation tant qu'aucune
revue contradictoire à contexte frais n'a tranché.

---

## 2026-08-05 — Blocs A→D : Prompt 4 installé, H-7, golden path, release, VERDICT DE GATE

(Entrée de rattrapage — la revue contradictoire a relevé, à raison, que le
journal s'arrêtait avant H-7.)

### Fait

- **Prompt 4 installé** (`ART_DIRECTION_MODE.md`) + `ART_DECISIONS.md`.
- **Bloc A** : `AUDIT_V0_PHASE_H.md`, `SOURCING_MATRIX.md`, AD-001/002/003.
- **Bloc B — H-7 a/b/c** : matière macro étendue à roche et montagne, fleurs
  ellipsoïdes, flancs de pente (surdimensionnés puis réduits sur capture),
  fog aerial 0,62→0,48 mesuré. Dette du verdict sérialisé soldée
  (test_valley_dressing recalé crête 32).
- **Bloc C** : golden path 4/4 VERT (boss, donjon ×2, traversal) ;
  Release `playtest-65709df` (source + binaire Linux).
- **Bloc D** : cinq caméras de gate (§21.5), captures produites — deux
  aveugles CONSIGNÉES (ISS-025 salle noire, ISS-026 caméra boss) ;
  cadence complète 4 cycles dans `ROADMAP.md`.

### VERDICT GATE H : FAIL (revue contradictoire à contexte frais)

Score prouvé ≈ 31-41/100 (auto-éval 56 trop généreuse de 15-25 pts) ;
2 captures aveugles sur 5 ; chemin critique en placeholders assumés ;
HeroShotLab jamais construit ; VICE DE FORME : la North Star précédait
H-7c (capture ≠ code livré). Détail complet : `TEST_REPORT.md`.

### Corrections adoptées (les 5 de la revue, ordonnées)

1. Lumière fin d'après-midi réelle (direct 1,45 / ambiance 0,55) — FAIT,
   à prouver par recapture ;
2. Recadrages boss/camp + recapture North Star depuis HEAD — FAIT au
   commit suivant ;
3. Rivière en S turquoise (Cycle 3, chantier eau) ;
4. Camp dans le cadre North Star + pylône 75-79 % X (Cycle 3) ;
5. Éclair cœur blanc + nuage modelé + cape héros (Cycle 3) ; vidéo
   10-20 s = machine utilisateur.

### Prochaine action exacte

Cycle 1 de la cadence : **P2-0** (audit Prompt 2, `PROMPT2_AUDIT.md`,
baseline, backlog) puis P2-1/P2-2 (Bracelet). Les corrections 3-5
attendent le Cycle 3 — ne pas re-décorer avant le systémique.

## 2026-08-05 — Coursier d'assets + P2-0 + P2-1 (latence instrumentée)

### Fait

- **Coursier v2 vert** (workflow `asset-courier.yml`, run n°2) : 6 packs
  Kenney dans `source_assets/external/` — Mini Arena **CC0** (colonnes,
  murs, statue, bannière, râtelier, épée, lance : kit donjon/camp §10.2),
  starter kits MIT (sons locomotion/impact/ambience, sprites VFX).
  Licences lues et consignées (`ATTRIBUTIONS.md`, `SOURCING_MATRIX.md`).
  Échecs documentés : KayKit et Quaternius absents de leurs GitHub,
  kenney.nl direct 404. Promotion vers `assets/` manuelle, à l'usage.
- **P2-0** : `PROMPT2_AUDIT.md` commis — constat central : le Bracelet
  n'existe pas (zéro ligne) ; backlog P2 ordonné.
- **P2-1** : `LatencyProbe` (réception au front d'événement dans le SEUL
  lecteur d'InputMap, consommation au changement d'état réel, refus
  expliqués) ; test fail-first `test_p2_latency.gd` rouge→vert : saut et
  attaque légale **≤ 1 tick physique** via la vraie chaîne
  `parse_input_event → _input → intent → tick`. `LabOverlay` dans
  TraversalPlayground et CombatLab. Articulation avec `LatencyInstrument`
  B.5 consignée (D-048) ; D-047 : ReactionSystem = nœud de scène, pas
  d'autoload. `GAMEPLAY_BIBLE.md` créée (P2 §1.2).
- **Validation par tranches** (leçon : la suite monolithique meurt entre
  les tours — 2 morts silencieuses) : import OK, parse 236 scripts OK,
  unitaires **109/109**, intégration **502/502**, playthrough en cours au
  moment de cette entrée (verdict ci-dessous ou au commit suivant).

### Prochaine action exacte

FAIT depuis cette entrée : lois 6/6 + 8 profils .tres 2/2 (`4bc430c`) ;
Pulse 5/5 (`test_resonance_pulse` : rayon+LOS, jamais à travers un mur,
cooldown refuse/rend la main, expiration, bruit entendu par les ennemis),
action `resonance_pulse` (physique 81 = étiquette AZERTY A + d-pad haut),
`ResonanceController`/`ResonanceTargetComponent`, câblage contrôleur avec
sonde (consommé/refusé). Non-régression : input 18/18, latences 6/6.

Prochaine action : **Arc Link** (P2 §3.3) fail-first — sélection de deux
ports compatibles, lien temporaire = nœud CABLE injecté dans le graphe
électrique existant (propagation/cycles déjà prouvés Gate F), annulation
sûre (port détruit, hors portée, rechargement).

## 2026-08-05 (suite) — P2-2 : les CINQ opérations du Bracelet prouvées

### Fait (chaque tranche fail-first : rouge prouvé avant l'implémentation)

- **Lois** (`4bc430c`) : MaterialProfile/ElementPacket/MaterialStateComponent/
  ReactionSystem — 6/6 + 8 profils canoniques 2/2.
- **Pulse** (`0208282`) : 5/5 — LOS réelle, cooldown, expiration, bruit
  entendu par les ennemis ; action `resonance_pulse` (étiquette AZERTY A).
- **Arc Link** (`d481f89`) : 6/6 — nœud CABLE injecté dans le graphe du
  Gate F ; transporte sans créer ; un seul lien ; dissolution sûre.
- **Polarité** (`b6d607a`) : 5/5 — impulsions bornées Jolt, vitesse
  plafonnée, continuité tick à tick, rupture à la décharge.
- **Arc Step** (`6be890c`) : 5/5 — sweep de capsule intégral, coût à
  l'exécution seulement, validation d'arrivée, budget de secours 0,8 s.
- **Ground** (commit courant) : 3/3 — startup immobile 0,35 s, drainage
  ENTIER ou RIEN, annulation propre si la cible s'échappe.

### Fait ensuite (même nuit) : le focus rend le Bracelet JOUABLE

`test_resonance_focus` 6/6 (fail-first) : sélection par axe de visée + LOS,
hystérésis au cycle, dispatch par nature de cible (ancrage→Arc Step,
port→lien en deux temps avec oubli du A au relâchement, métal→Polarité),
et le clic en focus ne déclenche JAMAIS l'épée (verrous épée/lourde/
molette-armes/molette-lock-on pendant le maintien). Ground direct sur T
(cible auto = objet chargé le plus proche, groupe `material_states`).
Actions câblées : A=Pulse, G=focus (maintien)+L1, T=Ground, d-pad
haut/gauche manette. Résonance 31/31.

### Fait ensuite : ResonanceLab + clôture P2-2

`ResonanceLab.tscn` jouable (zones Pulse/LOS, Link avec lampes pilotées par
`power_changed`, Polarité avec recharge de lab, fosse d'Arc Step, Ground) —
test structurel 1/1, Résonance 32/32. Liens d'Arc Link éphémères par design
(D-049) : rien à persister. **P2-2 est TERMINÉ hors présentation** — les
VFX/audio des cinq opérations rejoignent la passe visuelle du Cycle 3.

### Fait ensuite : P2-3 tranche 1 — garde et déviation parfaite

`damage_gate` GÉNÉRIQUE sur la hurtbox (le Briseur §14.3 pourra s'en
servir) ; garde = clic D tenu avec une arme de mêlée (l'arc vise), cône
frontal 135°, blocage à 20 % de dégâts contre endurance (GuardBreak à
jauge vide), déviation parfaite dans les 0,12 s de la levée : zéro dégât,
zéro endurance, Clarity 0,35 s, et la POISE de l'attaquant paie (40) — le
stagger passe par le composant, pas par un script spécial. Un coup bloqué
ne déclenche NI HURT NI mercy (recul court seulement). Tuning data-driven
(`guard_default.tres`). 4/4 fail-first ; non-régression hurt 6/6, combat
10/10, raiders 22/22, boss 11/11, buffs 4/4.

### Fait ensuite : P2-3 tranche 2 — la posture

`PostureComponent` partagé (jauge tactique : rupture UNIQUE, recharge
après accalmie, jamais de re-rupture à zéro) ; `posture_damage` transporté
de bout en bout (AttackDefinition → AttackController → Hitbox →
DamageEvent) ; le Briseur MIGRÉ dessus sans changer un seul comportement
observable (5/5 historiques verts — l'arc et l'amorti restent à lui, la
jauge est le composant, le même que portera le boss en P2-5) ; un coup à
posture_damage 12 brise sa garde en UN coup même à 2 de dégâts ; la
déviation parfaite nourrit la POSTURE quand la cible en porte (6 par
parade → 2 parades brisent un Briseur), la POISE sinon. 3/3 fail-first.

### Fait ensuite : P2-3 tranche 3 — identités d'armes

Constat d'entrée : TOUTES les familles empruntaient les attaques de
l'épée, lourde comprise (câblée en dur dans Player.tscn) — les « six
recolorations » que P2 §7.5 interdit. Fait : `heavy_attack` et
`parry_window_bonus` sur WeaponDefinition ; le contrôleur échange la
lourde avec l'arme (repli = export historique) ; CINQ lourdes de famille
en pure data — gourdin `club_heavy_sweep` (recul 7, projette), lance
`spear_heavy_thrust` (perce vite, recovery long), hache `axe_heavy_break`
(posture 12 = brise la garde d'un Briseur EN UN COUP, startup 0,55 très
annoncé), lame `blade_heavy_surge` (élément électrique), épée garde la
sienne + bonus de déviation 0,04 s. 2/2 (45 assertions) ; non-régression
armes 9/9, combat 10/10, garde 24/24, boss 11/11. ISS-027 consigné
(faux « ok » du runner sur erreur post-assertion).

### Fait ensuite : P2-3 tranche 4a — sélection utilitaire explicable

Constat : le `CombatCoordinator` était DÉJÀ conforme §12.8 (tokens 2
mêlée + 1 lourde, purge structurelle — jamais de référence morte —,
plafond 14 IA) : rien à refaire. Le manque réel était l'EXPLICABILITÉ
(P2 §8.1). Fait : `UtilityBrain` (choix scoré, trace des trois meilleurs
avec raisons, égalité départagée par priorité de déclaration) 2/2 ;
l'azur refactoré dessus — rouvrir/flanquer/presser aux MÊMES seuils que
la cascade historique (22/22 raiders verts), mais chaque décision se lit
(`chase_trace()`). Leçon de mise en scène récurrente consignée deux fois
cette nuit : le pivot ennemi regarde +Z par défaut — placer le joueur
côté +Z ou tourner le pivot, sinon pas d'aggro.

### Fait ensuite : P2-3 tranche 4b — camp trois approches. P2-3 TERMINÉ.

La diversion s'est prouvée SYSTÉMIQUE du premier coup : Pulse depuis un
couvert plein → le garde passe suspicious/investigate, quitte son poste
vers le bruit, et n'atteint JAMAIS alert (il n'a rien vu — §12.7, zéro
omniscience). Aucun code d'infiltration dédié : la chaîne P2-2 × bruit
existante suffisait — c'est le pilier « le monde écoute » qui paie.
L'approche environnement : une caisse métallique chargeable par
campement braise (RigidBody + profil métal + marqueur Polarité), cible
légitime de Polarité (projeter) et Ground. 2/2 (10 assertions),
territoires 8/8.

**P2-3 est TERMINÉ** : garde/déviation, posture, identités d'armes,
utility explicable, tokens (déjà conformes), camp trois approches.

### Fait ensuite : P2-4a — l'autel de terre (premier POI Bracelet)

Greffé au sanctuaire forestier existant (densité avant étalement) : un
cœur PRÉ-CHARGÉ (profil terre conductrice, 4 d'énergie) posé sur l'autel,
ciblable au Bracelet ; le mettre à la terre allume la stèle dormante —
conséquence par SIGNAUX d'états réels (patron ResonanceLab), et la
recharge lente du composant ré-arme l'exercice (la stèle s'éteint quand
le cœur se rallume — cohérence lisible). C'est l'« exercice sûr » de
Ground que P2 §3.7 exige avant le donjon. 2/2 fail-first (10 assertions),
reliques 7/7, monde 9/9.

### Fait ensuite : P2-4b — pont magnétique (composant) + correctif décroissance

DÉFAUT DE DESIGN repéré et corrigé fail-first : la décroissance de
charge universelle (0,35/s) aurait vidé tout cœur de POI en ~11 s —
l'autel se serait éteint avant l'arrivée du joueur. Correctif :
`charge_decay_enabled` (7/7), faux sur les cœurs de POI, la loi par
défaut inchangée partout ailleurs. L'autel corrigé.

Le PONT MAGNÉTIQUE (2/2, 11 assertions, vert du premier coup) : diorama
autonome (rives + vide + tablier chargé qui retient sa charge) ; on se
poste DERRIÈRE et on REPOUSSE (la Polarité enseigne son second mode) ;
l'entrée en zone verrouille — gel, alignement par transform (légitime :
plus un corps actif), mise à la terre (le raccourci est DÉFINITIF, la
Polarité répond ensuite pas_charge), signal unique, rayon de portance
prouvé au centre du vide.

### Fait ensuite : P2-4c — le pont est dans la vallée

Sonde d'abord (`tools/godot/probe_bridge_site.gd` : 8 candidats sur la
route des ruines, tous plats à y = 2,00) ; site retenu (−34, 3, 44),
lacet 90°, entre l'aqueduc et la ferme. Implanté dans ValleyRelics comme
32ᵉ LIEU déclaré (POI valley.poi.magnetic_bridge.01, ancre PUZZLE sur la
rive lointaine). Deux défauts attrapés par les suites de lieux : ancre
enterrée (y local −0,5 = dans la rive → 0,0) et DOUBLE attache (la table
ANCHORS attache déjà via _place_poi). Placement 1/1 (8 assertions),
reliques 7/7 (compte 4→5 délibéré), ancres 8/8 (33 saines).

### Fait ensuite : P2-4d — le bassin conducteur (33ᵉ lieu)

Composant `ConductiveBasin` 2/2 : circuit pré-arrangé avec UN maillon
manquant (source à 6 m de l'eau, hors portée des ports), un seul Arc
Link source→eau complète — le courant TRAVERSE l'eau (la leçon) et
allume le récepteur ; dissoudre rend tout (transport, jamais création).
Un défaut de géométrie attrapé par le rouge : le récepteur à 0,67 m du
port de l'eau (portée 0,6) — rapproché à 0,5. Placement sondé (16, 2,
28, rive est du S), 33ᵉ lieu déclaré (POI + ancre PUZZLE), reliques 7/7
à SIX lieux, ancres 8/8 (34 saines).

### Fait ensuite : P2-4e — les trois Fragments (4/4, 22 assertions)

API stricte (trois identifiants connus, jamais deux fois, l'inconnu
refusé, signal). ÉCHO : le contrôleur rejoint un groupe
`noise_listeners` (NoiseEvents étendu — même fait de perception, un
groupe de plus), mémorise la dernière source FRAÎCHE (≤ 8 s), et le
Pulse émet une direction normalisée — jamais son propre bruit (garde
anti-boucle pendant l'émission). FLUX : une terre ≥ 2 de charge rend
15 d'endurance (nouvelle API StaminaComponent.restore, notifiée),
cooldown 10 s. ÉLAN : l'arrivée d'Arc Step conserve 35 % de l'élan,
plafonné à la vitesse de course. Deux bugs de MESURE corrigés en route
(pic capté pendant le dash encore actif ; régénération naturelle
polluant la phase cooldown — dépenser juste avant mesure).

### Prochaine action exacte

Sous-tranche restante de P2-4 : PERSISTANCE des Fragments (audit du
constructeur de payload du save v4) + POSE des trois pickups en monde
(nid vertical pour Élan, territoire d'écoute pour Écho, autel pour
Flux ?) — puis revue de fin de P2-4. Ensuite : P2-5 (migration
donjon/boss vers les lois, boss director).
