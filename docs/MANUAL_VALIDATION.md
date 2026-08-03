# PROTOCOLE DE VALIDATION MANUELLE — Gate A

Base : MASTER_SPEC §21.4 (tests manuels obligatoires), §23.1 (gates gameplay),
§0.7 (matrice de preuve).

**À qui s'adresse ce document** : à une personne disposant d'une machine avec
écran, clavier **AZERTY** et manette. Il est écrit pour être exécuté sans moi et
sans connaissance préalable du projet.

**Pourquoi il existe** : tout ce qui est vérifiable en headless l'est déjà et est
vert (48 tests). Ce qui reste ne l'est pas *par nature* — une liaison de touche
testée n'est pas une touche pressée, et une structure d'interface testée n'est pas
une interface lisible. Le conteneur de développement n'a ni écran, ni clavier, ni
manette, ni périphérique audio (`docs/KNOWN_ISSUES.md` ISS-002, ISS-004).

> **État du Gate A : `EN ATTENTE`** — ni `PASS`, ni `FAIL`. Il le reste tant que
> les six étapes ci-dessous n'ont pas produit leurs preuves.
>
> 👉 **Pour exécuter la campagne sur un Mac, suivre `docs/MANUAL_GATE_A.md`** :
> c'est la version opérateur, pas à pas, avec l'installation de Godot, le déballage
> du paquet et la procédure de reprise en session Claude Code. Le présent document
> reste la référence de **politique** (critères, preuves attendues, règle de
> verdict) ; les deux ne doivent jamais diverger sur les critères.

---

## Avant de commencer

```bash
# 1. Godot 4.7.1 disponible (sur un poste normal, préférer le binaire officiel)
godot --version          # doit afficher 4.7.1.stable…

# 2. Se placer à la racine du dépôt, sur le commit gelé
git rev-parse --short HEAD

# 3. Préparer le dossier de preuves et le rapport à remplir
tools/manual_validation_kit.sh
```

Le kit crée `evidence/gateA/`, y écrit le rapport d'environnement et copie le
gabarit de rapport à compléter.

> Note de convention : le prompt maître (§0.3) impose un dossier `evidence/` à la
> racine ; c'est donc `evidence/gateA/` et non `docs/evidence/`. Les documents de
> `docs/` y renvoient.

**Règle qui prime sur toutes les autres** : si une étape ne peut pas être faite,
elle est `NON VÉRIFIÉ`. Elle n'est jamais supposée réussie, jamais « probablement
bon ». Un `FAIL` honnête vaut mieux qu'un `PASS` confortable.

---

## Étape 1 — Lancement sur une machine avec écran

**But** : le jeu démarre réellement et atteint le menu, hors headless.

```bash
godot --path .
```

**Attendu** :
- la fenêtre s'ouvre sans message d'erreur bloquant ;
- la console affiche les lignes `[boot]` puis `[boot] transition vers le menu principal.` ;
- le menu principal apparaît, avec titre « Éclats d'Orage ».

**Preuve à produire** :
- `evidence/gateA/01_lancement.png` — capture de la fenêtre au menu ;
- `evidence/gateA/01_lancement.log` — sortie console complète :
  ```bash
  godot --path . 2>&1 | tee evidence/gateA/01_lancement.log
  ```

**PASS si** : fenêtre ouverte, menu affiché, **aucune ligne `ERROR:`** dans le log.
**FAIL si** : erreur bloquante, fenêtre noire, ou menu jamais atteint.

---

## Étape 2 — Clavier AZERTY réel, `Q` = gauche

**But** : vérifier l'invariant le plus important du projet sur un vrai clavier.
Les tests automatiques verrouillent la *liaison* (`physical_keycode` 65) ; ils ne
peuvent pas presser une touche.

**Préalable** : la disposition **système** doit être AZERTY (français). Le vérifier
dans les réglages du système d'exploitation, pas seulement sur les touches.

```bash
godot --path . --scene res://scenes/tests/InputAudit.tscn
```

La sonde affiche la disposition détectée et un verdict automatique. Elle existe
parce qu'à ce stade il n'y a ni joueur ni monde : sans elle, appuyer sur `Q` ne
produirait rien de visible.

**Contrôles, un par un** :

| Touche pressée | Action qui doit s'allumer |
|---|---|
| `Q` | `move_left` |
| `Z` | `move_forward` |
| `S` | `move_back` |
| `D` | `move_right` |
| `Espace` | `jump` |
| `Maj gauche` | `sprint` |
| `E` | `interact` |
| `R` | `attack_heavy` |
| `Ctrl gauche` | `dodge` |
| `C` | `lock_on` |
| `X` / `V` | `target_prev` / `target_next` |
| `Tab` | `inventory` |
| `F` | `quick_meal` |
| `Échap` | `pause` |
| clic gauche / droit | `attack_light` + `shoot` / `aim` |

**Contrôle négatif, obligatoire** : appuyer sur `Q` ne doit **jamais** allumer
`lock_on`. C'est l'interdit explicite de §8.5.

**Preuve à produire** :
- `evidence/gateA/02_azerty_bandeau.png` — le haut de la sonde, montrant
  « AZERTY détecté — la position liée à « gauche » s'appelle « Q ». ✔ » ;
- `evidence/gateA/02_azerty_q_gauche.png` — `Q` maintenu, `move_left` **ACTIF** ;
- `evidence/gateA/02_azerty_tableau.md` — le tableau ci-dessus recopié avec une
  colonne « observé » remplie ligne par ligne.

**PASS si** : les 18 actions répondent à la touche annoncée **et** `Q` n'active pas
`lock_on`.
**FAIL si** : une seule action ne répond pas, ou répond à la mauvaise touche.

---

## Étape 3 — Manette

**But** : §23.1 exige « clavier AZERTY **et** manette fonctionnels ».

Brancher la manette **avant** de lancer. Même scène que l'étape 2 : la ligne
« Manette : … » doit afficher son nom.

| Entrée manette | Action attendue |
|---|---|
| stick gauche, 4 directions | `move_forward` / `move_left` / `move_back` / `move_right` |
| A / Croix | `jump` |
| stick gauche pressé | `sprint` |
| X / Carré | `interact` |
| RB / R1 | `attack_light` |
| RT / R2 | `attack_heavy` + `shoot` |
| LT / L2 | `aim` |
| B / Rond | `dodge` |
| stick droit pressé | `lock_on` |
| stick droit gauche/droite | `target_prev` / `target_next` |
| Y / Triangle | `inventory` |
| d-pad bas | `quick_meal` |
| Menu / Start | `pause` |

**Preuve à produire** :
- `evidence/gateA/03_manette_detectee.png` — nom de la manette affiché ;
- `evidence/gateA/03_manette_tableau.md` — tableau avec colonne « observé » ;
- noter le modèle exact de la manette : le mapping dépend de la base SDL.

**PASS si** : toutes les entrées du tableau répondent.
**FAIL si** : la manette n'est pas détectée, ou une entrée reste morte.
**`NON VÉRIFIÉ`** si aucune manette n'est disponible — dans ce cas le dire, ne pas
extrapoler depuis le clavier.

---

## Étape 4 — Lisibilité et focus du MainMenu

**But** : §17.3 et §17.4. La structure est testée automatiquement (cycle de focus,
boutons désactivés non focalisables) ; l'**apparence** et le **confort** ne le sont
pas et ne peuvent pas l'être sans écran.

```bash
godot --path .
```

**Contrôles** :

1. **Focus visible** : au clavier seul, la sélection courante est-elle
   identifiable sans hésitation ? Prendre la capture en s'en assurant.
2. **Navigation clavier** : flèches haut/bas parcourent les boutons ; la liste
   **boucle** (du dernier on revient au premier) ; `Entrée` active ; aucun
   moment où le focus disparaît.
3. **Navigation manette** : d-pad et stick gauche parcourent les boutons, `A`
   active. Le focus ne doit jamais se perdre.
4. **Boutons désactivés** : « Options » est grisé et **jamais atteint** par la
   navigation. Sans sauvegarde, « Continuer » l'est aussi.
5. **Confirmation d'écrasement** : avec une sauvegarde existante, un premier appui
   sur « Nouvelle partie » affiche la demande de confirmation ; un second écrase.
6. **Redimensionnement** : réduire et agrandir la fenêtre — la mise en page suit,
   rien n'est coupé ni superposé (§17.1 : jamais de placement absolu).
7. **Lisibilité** : texte lisible sans effort à distance normale ; contraste
   suffisant entre texte et fond.

**Preuve à produire** :
- `evidence/gateA/04_menu_focus.png` — un bouton clairement focalisé ;
- `evidence/gateA/04_menu_petit.png` et `04_menu_grand.png` — deux tailles de
  fenêtre très différentes ;
- `evidence/gateA/04_menu_confirmation.png` — l'état « Écraser la sauvegarde ? » ;
- observations écrites dans le rapport, y compris ce qui est laid ou peu lisible.

**PASS si** : 1 à 6 sont conformes et le texte est lisible.
**FAIL si** : le focus se perd, un bouton désactivé est atteignable, la mise en
page casse au redimensionnement, ou le texte est illisible.

> Le point 7 est subjectif et c'est assumé : le noter honnêtement. Un menu
> fonctionnel mais laid est un `PASS` avec réserve écrite, pas un `FAIL` — la passe
> d'interface est prévue en Phase H, pas maintenant.

---

## Étape 5 — Reprise réelle depuis une session neuve

**But** : lever la réserve principale du Gate 0 (`docs/DECISIONS.md` D-006). Le
critère « une session neuve reprend le travail en moins de 5 minutes » n'a jamais
été mesuré, seulement estimé par relecture. C'est donc `NON VÉRIFIÉ` depuis le
début, et ce document ne prétend pas le contraire.

**Protocole — à faire par quelqu'un qui n'a pas construit le projet, si possible** :

1. Cloner le dépôt dans un dossier vierge, sur le commit gelé.
2. Démarrer un **chronomètre**.
3. Lire, dans cet ordre et **rien d'autre** : `CLAUDE.md`, `docs/STATUS.md`,
   `docs/PROGRESS.md`, `docs/KNOWN_ISSUES.md`.
4. Arrêter le chronomètre dès que ces quatre questions ont une réponse :
   - où en est le projet ?
   - quel est le prochain jalon et sa première action concrète ?
   - qu'est-ce qui est bloqué, et par quoi ?
   - quelle commande valider avant de modifier quoi que ce soit ?
5. Puis, séparément, vérifier que le projet est réellement reprenable :
   ```bash
   tools/setup_godot.sh     # ~60-120 min si Godot doit être reconstruit
   tools/validate_fast.sh   # doit sortir en 0, 48 tests
   ```

**Preuve à produire** :
- `evidence/gateA/05_reprise.md` : durée chronométrée, réponses aux quatre
  questions **écrites par le lecteur**, et toute question restée sans réponse ;
- `evidence/gateA/05_validate_fast.log` : sortie complète et code retour.

**PASS si** : les quatre réponses sont trouvées en < 5 min **et**
`validate_fast.sh` sort en 0.
**FAIL si** : une question reste sans réponse, ou la documentation induit en
erreur. Dans ce cas, consigner **quel document** a manqué : c'est le défaut à
corriger, pas le lecteur.

---

## Étape 6 — Archivage des preuves

**But** : §0.7 — une preuve non rattachée à un commit ne prouve rien.

```bash
# Depuis la racine, une fois toutes les captures déposées :
tools/manual_validation_kit.sh --finalize
```

Le script écrit `evidence/gateA/MANIFESTE.txt` : commit exact, date, machine,
versions, et liste des fichiers présents avec leur empreinte SHA-256.

**Contrôles avant de conclure** :
- [ ] chaque étape a ses fichiers, ou une mention `NON VÉRIFIÉ` motivée ;
- [ ] `evidence/gateA/RAPPORT.md` est rempli, verdict par étape ;
- [ ] le commit du manifeste correspond à celui testé ;
- [ ] aucune capture ne provient d'ailleurs que de l'exécution réelle.

Puis committer le dossier.

---

## Conclusion du Gate A

Le verdict global est le **plus faible** des six étapes, jamais leur moyenne
(§0.7).

| Étape | Verdict |
|---|---|
| 1. Lancement avec écran | |
| 2. Clavier AZERTY, `Q` = gauche | |
| 3. Manette | |
| 4. Lisibilité et focus du menu | |
| 5. Reprise depuis une session neuve | |
| 6. Archivage des preuves | |

- **Gate A `PASS`** si les six sont `PASS`. Consigner dans `docs/STATUS.md`,
  `docs/TEST_REPORT.md` et `docs/PROGRESS.md`, puis démarrer la **Phase B**.
- **Gate A `FAIL`** si une étape échoue : ouvrir une entrée dans
  `docs/KNOWN_ISSUES.md` avec sa sévérité, corriger, rejouer **l'étape concernée**
  seulement, et re-conclure.
- **Gate A `EN ATTENTE`** tant que des étapes sont `NON VÉRIFIÉ` faute de matériel.
  C'est l'état actuel. Ce n'est pas un échec du travail : c'est une limite de
  l'environnement, et la dire est la seule option honnête.

**Interdiction explicite** : ne pas déclarer `PASS` sur la foi des tests
automatiques. Ils prouvent que la liaison `Q` → gauche existe dans `project.godot`.
Ils ne prouvent pas qu'une personne appuyant sur `Q` va vers la gauche.

---
---

# PROTOCOLE DE VALIDATION MANUELLE — Gate B (traversal)

Essais de §21.4 touchant le traversal, plus les deux observations que l'automatique
ne peut pas produire : le jitter caméra (§8.3) et le ressenti de latence (§10.6).
Ce que les tests automatiques prouvent déjà — et qu'il est donc inutile de
re-prouver à la main — est listé en fin de section.

## Préparation

```bash
# 1. Se placer sur le commit à valider (le noter : il ira dans le rapport)
git log --oneline -1

# 2. Lancer le terrain d'essai. --debug-collisions est INDISPENSABLE : le bac à
#    sable est un décor d'épreuves sans meshes, seules ses formes de collision
#    sont visibles.
godot --path . --debug-collisions scenes/tests/TraversalPlayground.tscn
```

Contrôles : `ZQSD` (AZERTY), souris pour la caméra, `Espace` saut, `Maj G` sprint,
`Échap` rend/reprend la souris. Un panneau en haut à gauche affiche endurance,
mode, vitesse et les derniers événements (accroche, franchissement, refus) — s'y
fier plutôt qu'à l'interprétation de la silhouette.

Plan du bac à sable (positions monde ; le joueur apparaît en (0, 1, 0)) :

| Épreuve | Où |
|---|---|
| Marche 0,32 m | (0 ; 20), abordée en s'éloignant du spawn vers +Z |
| Marche sous plafond bas | (−36 ; −30) |
| Pente 40° (marchable) | (−20 ; 0) |
| Pente 60° (mur) | (−30 ; 0) |
| Mur vertical 6 m | (30 ; 0) |
| Paroi d'escalade 4 m | (−5 ; −30) |
| Paroi `unclimbable` (jumelle) | (−25 ; −30) |
| Surplomb flottant | (−15 ; −30) |
| Rebord bas | (12 ; −30) |
| Rebord sous plafond | (28 ; −30) |

## Essai B-1 — Caméra contre tous types de murs (§21.4, §8.3)

**But** : « tourner caméra contre tous types de murs » ; « zéro traversée/jitter ».

1. Se coller successivement au mur de 6 m, à la paroi d'escalade, dans le coin
   que forment deux parois, et sous le plafond du rebord (28 ; −30).
2. À chaque poste : faire un tour complet de caméra, lentement puis vite ;
   puis un demi-tour en sprintant le long du mur.
3. Observer : la caméra montre-t-elle jamais l'envers de la géométrie ? L'image
   tremble-t-elle quand le bras se raccourcit (jitter) ? Le retour à distance
   pleine est-il doux ?

**PASS** : aucune traversée, aucun tremblement visible, récupération douce.
**Preuve** : `evidence/gateB/manual/B1_camera_murs.md` (verdict + description de
tout défaut), capture ou courte vidéo si un défaut apparaît.

## Essai B-2 — Escalade : parois, coins, refus (§21.4, §9.2)

**But** : « gravir une falaise irrégulière et coins » — adapté au graybox.

1. Gravir la paroi de 4 m (−5 ; −30) : monter, descendre, latéral, saut d'escalade
   (`Espace`), franchir le sommet en poussant vers le haut.
2. Contourner un **coin vertical** de cette paroi en latéral.
3. Vérifier les trois refus : paroi jumelle `unclimbable` (−25 ; −30), surplomb
   flottant (−15 ; −30), pente à 60° (−30 ; 0) — aucune ne doit s'accrocher.

**LIMITE ASSUMÉE** : le graybox n'a que des parois **planes**. « Falaise
irrégulière » (et le lissage de normale qui va avec) ne peut pas être jugé ici ;
cet essai sera **rejoué en Phase D** sur le vrai terrain. Le noter au rapport.

**PASS** : montée fluide, coins franchis sans décrochage brutal, les trois refus
tiennent, le panneau nomme chaque événement.
**Preuve** : `evidence/gateB/manual/B2_escalade.md`.

## Essai B-3 — Mantle, y compris sous plafond (§21.4, §9.3)

**But** : « tenter mantle sous plafond » ; « aucun snap visible ».

1. Franchir le rebord bas (12 ; −30) dix fois, sous des angles d'approche variés.
   L'œil cherche l'à-coup : le test automatique borne le plus grand pas, il ne
   voit pas une trajectoire « mécanique ».
2. Tenter le rebord sous plafond (28 ; −30) : le franchissement doit être
   **refusé** (panneau : « mantle refusé (blocked) »), sans à-coup, sans
   encastrement, et le joueur doit pouvoir repartir librement.
3. Franchir la marche sous plafond bas (−36 ; −30) : refus attendu, le joueur
   reste devant, jamais dedans.

**PASS** : franchissements lisibles sans téléportation perçue, refus nets sans
softlock.
**Preuve** : `evidence/gateB/manual/B3_mantle.md`.

## Essai B-4 — Sprint à endurance nulle (§21.4, §9.1, D-016)

**But** : « sprinter à zéro endurance » — et valider humainement le seuil de
récupération, que D-016 a fixé par mesure, pas par ressenti.

1. Sprinter en boucle jusqu'à `ÉPUISÉ` (panneau). Constater : vitesse retombe en
   course, pas d'arrêt brutal.
2. **Maintenir** sprint enfoncé sans le relâcher : la reprise doit produire des
   rafales franches (~1,7 s), jamais une oscillation rapide de vitesse.
3. Épuisé, tenter de s'accrocher à la paroi de 4 m : l'accroche doit être refusée
   tant que la récupération n'a pas eu lieu ; en cours d'escalade, l'épuisement
   doit faire lâcher.

**PASS** : bascules lisibles, aucune oscillation, la valeur du seuil (20) ne
produit ni attente frustrante ni bégaiement. Si l'attente semble trop longue ou
trop courte : le dire au rapport — c'est exactement la donnée que D-016 attend.
**Preuve** : `evidence/gateB/manual/B4_endurance.md`.

## Essai B-5 — Ressenti de latence et de contrôle (§10.6)

**But** : l'essai humain que §10.6 exige en complément de la mesure (1 tick,
instrumentée par `test_latency.gd`).

1. Alterner arrêts nets, départs, demi-tours, petits sauts, à 60 FPS.
2. Chercher : un retard perceptible entre touche et mouvement, un arrêt
   « robotique », un saut avalé (appuyer juste avant de retomber : le buffer doit
   le conserver), un saut au bord d'une plateforme juste après l'avoir quittée
   (coyote time).

**PASS** : aucune commande perçue comme perdue ou tardive.
**Preuve** : `evidence/gateB/manual/B5_ressenti.md`.

## Essai B-6 — Parcours enchaîné, à la main (§22)

**But** : rejouer humainement ce que le pilote scripté réussit, dans
`TraversalCourse.tscn` cette fois.

```bash
# Ouvrir la scène du parcours dans l'éditeur, y glisser une instance de
# Player.tscn en (0, 1, 0), puis F6. Ne pas committer cette modification.
```

Sol → marche → rampe → saut du vide → escalade de la tour → sommet. Trois
tentatives ; noter tout endroit où l'on se sent bloqué, ou où la caméra gêne.

**PASS** : parcours bouclé aux trois tentatives sans blocage ni combat contre la
caméra.
**Preuve** : `evidence/gateB/manual/B6_parcours.md`.

## Archivage et conclusion

Rassembler `evidence/gateB/manual/`, y ajouter `RAPPORT.md` : commit testé,
machine, OS, verdicts par essai, défauts décrits. Committer le dossier.

Le verdict du Gate B est le **plus faible** de : tests automatiques (dont le
parcours scripté et la latence instrumentée), ces six essais, et la revue
contradictoire. Jamais leur moyenne.

**Ce que l'automatique prouve déjà** — ne pas le re-prouver à la main : vitesses
de §8.2/§9.2, coûts d'endurance de §9.1, une seule accroche par contact, refus
nommés (`unclimbable`, `overhang`, `blocked`, `too_shallow`), caméra jamais dans
la géométrie sur le parcours scripté (sonde à chaque tick), latence intention →
mouvement de 1 tick. Ces essais manuels cherchent ce que les sondes ne voient
pas : le tremblement, l'à-coup, le ressenti, l'envie de rejouer.

**CONTROLLER-001 ne fait PAS partie de ce protocole** : la dette manette reste
ouverte et se lève par l'étape 3 du protocole Gate A, jamais par le Gate B.

---

# Protocole G — combat du Gardien de l'Orage

Rien de ce qui suit n'a été jugé dans le conteneur : ni écran, ni manette,
ni oreille. Les tests automatiques prouvent des LIAISONS et des BORNES —
qu'une fenêtre dure 0,85 s, qu'un pylône est branché, que le combat est
mathématiquement gagnable. Ils ne disent rien de ce qu'on ressent.

Lancer : `godot --path .`, puis charger la sauvegarde de l'antichambre, ou
directement `scenes/boss/BossArena.tscn` depuis l'éditeur.

## Essai G-1 — Lecture de la première phase (§16.3)

1. Entrer dans l'arène sans rien savoir du combat.
2. Sans consulter ce document : combien de temps avant de comprendre que
   l'armure encaisse presque tout ?
3. Combien de temps avant de remarquer les pylônes ?
4. Combien de temps avant de comprendre qu'il en faut DEUX ?

À noter : la durée de chaque prise de conscience, et ce qui l'a déclenchée
(la couleur du noyau, le levier, l'arc qui rate). Si rien ne la déclenche
en deux minutes, l'affordance est à revoir — pas le texte à ajouter.

## Essai G-2 — Les télégraphes (§16.4, §16.5)

1. Jouer la phase 2 en gardant la lame conductrice.
2. Le renvoi de surcharge est-il compris comme une CONSÉQUENCE de l'arme,
   ou vécu comme une punition arbitraire ?
3. Changer pour le gourdin : la différence se sent-elle sans la lire ?
4. En phase 3, les marques au sol laissent-elles vraiment le temps de
   sortir ? Compter les fois où l'on est touché en ayant vu la marque.

## Essai G-3 — Caméra (§16.6)

1. Combattre au contact, dos au mur, puis au centre.
2. Le Gardien sort-il du cadre ? Combien de fois, et à quel moment ?
3. L'élargissement de la caméra se remarque-t-il ? Il ne DOIT pas.
4. Un pylône passe-t-il durablement entre la caméra et le héros ?

## Essai G-4 — Durée et retry (§16.1, §16.6)

1. Chronométrer la PREMIÈRE victoire. Cible §16.1 : 4 à 7 minutes.
2. Mourir volontairement. Chronométrer du dernier point de vie à
   l'instant où l'on redevient maître du personnage. Cible : < 20 s.
3. Vérifier qu'on revient avec l'équipement du checkpoint.

## Essai G-5 — Conclusion (§16.8)

1. Après la victoire : l'apaisement du ciel se voit-il ?
2. Le coffre final se trouve-t-il sans le chercher ?
3. L'écran de victoire arrive-t-il trop tôt, trop tard, ou au bon moment ?

## Verdict

Tant que ces cinq essais n'ont pas eu lieu, le Gate G reste
**ACCEPTÉ POUR CONTINUATION — VALIDATION HUMAINE DIFFÉRÉE**. Aucune case
`PASS humain` ne peut être cochée sur la foi des tests automatiques.

---

# Protocole H — silhouettes du bestiaire (bible §30.3)

Ce protocole ne peut PAS être exécuté dans le conteneur : il demande un œil
humain sur un écran. Les tests automatiques établissent que chaque créature
forme un seul corps solidaire et respecte ses cotes ; ils ne disent rien de
la lisibilité d'une silhouette.

## Préparation

```bash
BESTIARY_FLAT=1 godot --path . --script tools/godot/capture_reference.gd -- \
    --scene=res://scenes/tests/BestiaryLineup.tscn \
    --out=evidence/phaseH/silhouettes.png --size=1920x1080 --frames=40
```

Pour inspecter un sujet seul sous cinq angles :

```bash
godot --path . --script tools/godot/capture_reference.gd -- \
    --scene=res://scenes/tests/CharacterTurntable.tscn \
    --creature=colosse --out=evidence/phaseH/turntable_colosse.png \
    --size=1920x1080 --frames=40
```

Sujets disponibles : `braise`, `azur`, `briseur`, `colosse`, `chasseur`,
`gardien`.

## Essai H-1 — Distinction des cinq familles

Montrer la planche en aplats noirs à quelqu'un qui n'a pas construit le jeu,
pendant **trois secondes**, puis masquer. Demander combien de familles
différentes il a vues.

- `PASS` : cinq silhouettes distinctes citées, sans confusion entre les trois
  pillards.
- `FAIL` : deux silhouettes décrites comme « la même en plus grand ».

## Essai H-2 — Reconnaissance de la menace

Montrer chaque silhouette seule et demander : « quel est le danger ? »

Attendu, sans souffler : le briseur porte une garde, le colosse frappe de
haut, le chasseur charge, l'azur tient à distance, le braise se jette.

## Essai H-3 — Lecture à la distance de jeu

En jeu, lock-on coupé, reculer jusqu'à 25 m et vérifier que la famille reste
identifiable **sans** regarder sa couleur.

## Verdict H

Aucun essai de ce protocole ne peut être déclaré `PASS` depuis le conteneur.
Tant qu'ils n'ont pas eu lieu, l'état reste **VALIDATION HUMAINE DIFFÉRÉE**.
