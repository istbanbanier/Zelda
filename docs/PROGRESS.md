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

## HANDOFF — prochaine action exacte

> **Gate A : `ACCEPTÉ AVEC RÉSERVE / BLOQUÉ SUR LA VALIDATION MANETTE`** (D-012).
> **Phase B : B.0 à B.4 livrés.** §8.2 et §9.2/§9.3 sont couverts, le parcours
> enchaîné est vert.
> **Gate B n'est PAS acquis** — mais ce qui manque ne relève plus du code.

### Action suivante : instruire le Gate B, puis le faire trancher

Trois choses, dans cet ordre :

1. **Mesure de latence (§10.6).** Horodater réception de l'intention, consommation,
   début logique et premier déplacement, puis exposer le résultat en **ticks et en
   millisecondes**. §23.1 exige « entrée mouvement visible au tick physique suivant
   et latence d'action instrumentée » : c'est le seul critère chiffré du Gate B
   encore absent, et il est atteignable en headless.
2. **Compléter `docs/MANUAL_VALIDATION.md`** avec les essais de §21.4 touchant le
   traversal : caméra contre tous types de murs, falaise irrégulière et coins,
   mantle sous plafond (automatisé, mais l'œil doit confirmer l'absence d'à-coup),
   sprint à endurance nulle. Le protocole existe déjà pour le Gate A ; il s'agit de
   l'étendre, pas d'en créer un.
3. **Lancer la revue contradictoire** (`gate-review`, `adversarial-qa`) sur le
   Gate B avec la spécification, le diff et les preuves. §0.7 l'exige avant toute
   déclaration `PASS`, et l'approbation de l'auteur ne la remplace jamais.

Ne pas déclarer Gate B `PASS` sans ces trois éléments. Ne pas entamer la Phase C
avant que le Gate B soit `PASS` ou explicitement `BLOQUÉ`.

### Ce qui reste implémenté mais non mesuré, à traiter en Phase C ou plus tard

- Lissage de la normale de paroi et vitesse latérale (§9.2) : le bac à sable n'a
  que des parois planes, il n'y a rien à lisser.
- Annulation en cours de franchissement (§7.12) : exercée indirectement par P3.
- Dégâts de chute (§8.2) : `landed(impact_speed)` porte déjà la vitesse d'impact.
- `ClimbRest` et corniches de repos (§8.1, §9.3) : level design.
- La `StateMachine` de §8.1 reste due — le `Mode` à trois valeurs sera absorbé,
  pas conservé en parallèle (D-018).

### Pièges connus, vérifiés de B.1 à B.4

- **Un contrôle négatif qui ne casse rien est une information** : trou de
  couverture (B.3/P2) ou limite de ce que le test prouve (B.4/Q3 et Q5). Ne jamais
  le lire comme « le test est robuste ».
- **Un contrôle négatif sur un réglage doit muter le `.tres`**, jamais la valeur
  par défaut du `@export` (R-006bis).
- **Un test vert peut l'être pour la mauvaise raison** (B.3/B3-1).
- **Ne pas croire un drapeau du moteur sans le mesurer** : `is_on_wall()` est faux
  contre un mur (D-020).
- **Une mesure d'intégration ne doit pas dépendre de la taille du décor.**
- **Un composant `Node` créé dans un test doit être libéré**, sinon « resources
  still in use at exit », que `validate_fast.sh` traite en rouge.
- **Une rampe de test ne doit pas être une boîte tournée** : son dessous forme un
  surplomb sous lequel la capsule se faufile.
- **`SpringArm3D` réécrit la position de ses enfants directs** (D-014) ; son
  `margin` est sans effet, c'est `shape` qui donne un dégagement (D-015).
- Un `MainLoop` lancé par `--script` n'a ni autoloads ni tree prêt pendant
  `_initialize()` (D-009).
- Toute méthode de test avec `await` doit être attendue, **et la boucle appelante
  aussi** (D-010).
- **Relever `MIN_TESTS` dans `tools/validate_fast.sh` à chaque ajout de test.**
- Le nombre de tests de référence vit dans `docs/TEST_REPORT.md` **uniquement**.
- Doc Godot en ligne bloquée (ISS-001) : mesurer sur le binaire installé et
  consigner la mesure dans `RESEARCH_LEDGER.md`.
