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

### Rappels

- Rebaker le navmesh après TOUTE modification du relief (749 poly).
- Pièges frais : position-avant-add_child ; tampons MultiMesh illisibles en
  headless (seam origins/tints) ; cadence Timer temps-réel vs frames
  llvmpipe (~250 ms) ; PrismMesh : arête le long de Z ; plaques UI ancrées
  centre, jamais par `position` avant le premier layout.
- `MIN_TESTS` = 270 ; compte de référence dans TEST_REPORT uniquement.
- Le pack V4 binaire reste à déposer dans `source_assets/concepts/final_v4/`.
