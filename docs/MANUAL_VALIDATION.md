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
