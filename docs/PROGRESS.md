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

## HANDOFF — prochaine action exacte

> **Gate A : `ACCEPTÉ AVEC RÉSERVE / BLOQUÉ SUR LA VALIDATION MANETTE`** (D-012).
> Ce n'est pas un `PASS`. La dette `CONTROLLER-001` court.
> **Phase B en cours** : B.0, B.1 et B.2 livrés.

### Action suivante : jalon B.3 — escalade et mantle

§9.2 et §9.3, dans cet ordre : la paroi d'abord, le franchissement ensuite.

**Escalade (§9.2)** — valeurs déjà fixées, rien à inventer :
- sondes tête / torse / pieds, côtés, dessus, plus dégagement de capsule ;
- accroche 0,55–0,80 m ; distance au mur 0,38–0,48 m ;
- vitesse verticale 1,9–2,2 m/s ; latérale 1,5–1,8 m/s ;
- lissage de normale 0,08–0,16 s ; saut d'escalade 0,75–1,0 m ;
- surfaces refusées : `unclimbable`, `electrified`, `burning`, `spiked`,
  `fragile_unsupported`, eau, plateformes trop rapides.

**Mantle (§9.3)** : détection du haut → surface marchable → dégagement de capsule →
mantle bas/haut → transform cible → alignement animation/capsule → réactivation.
Annulation propre si invalide, **aucun snap visible**. C'est ici que
`ActionAlignmentComponent` (§7.12) devient nécessaire, et que la question ouverte
**R-009** doit être tranchée.

Points d'accroche déjà en place, à ne pas reconstruire :

- `StaminaComponent.try_sustain()` pour l'escalade continue (18/s) et le latéral
  (16/s) ; `try_spend()` pour le saut d'escalade (20). Les trois valeurs sont déjà
  dans `stamina_default.tres`, déclarées et non consommées — il ne reste qu'à les
  appeler.
- À endurance nulle, §9.1 impose de **lâcher le mur** : `can_sustain()` renvoie
  déjà faux, le composant n'a pas à changer.
- Le bac à sable a un mur vertical en `x = 30` (`z` de -10 à 10, haut de 6 m) et
  deux pentes encadrant le seuil de 46°.

### Pièges connus, vérifiés en B.1 et B.2

- **Un contrôle négatif sur un réglage doit muter le `.tres`**, pas la valeur par
  défaut du `@export` : sinon il ne casse rien et le test paraît faussement inutile
  (R-006bis).
- **Un effort maintenu ne reste pas épuisé** : mesurer « après N secondes » attrape
  un cycle plus tard. S'arrêter à la transition (`_drain_until_exhausted`).
- **Une mesure d'intégration ne doit pas dépendre de la taille du décor** : le sol
  du bac à sable fait 80 m, un sprint de 8 s en sort.
- **Une rampe de test ne doit pas être une boîte tournée** : son dessous forme un
  surplomb sous lequel la capsule se faufile, sans aucun drapeau de collision pour
  le signaler.
- **`SpringArm3D` réécrit la position de ses enfants directs** (D-014) ; son
  `margin` est sans effet, c'est `shape` qui donne un dégagement (D-015).
- Un `MainLoop` lancé par `--script` n'a ni autoloads ni tree prêt pendant
  `_initialize()` (D-009) ; le runner attend une frame, ne pas défaire.
- Toute méthode de test avec `await` doit être attendue, **et la boucle appelante
  aussi** (D-010).
- **Relever `MIN_TESTS` dans `tools/validate_fast.sh` à chaque ajout de test.**
- Le nombre de tests de référence vit dans `docs/TEST_REPORT.md` **uniquement**.
- Doc Godot en ligne bloquée (ISS-001) : mesurer sur le binaire installé et
  consigner la mesure dans `RESEARCH_LEDGER.md`.
