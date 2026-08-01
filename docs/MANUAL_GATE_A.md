# GATE A — PROCÉDURE DE VALIDATION MANUELLE SUR macOS

Document **opérateur**. Il s'exécute sans moi, sur un Mac, en environ une heure.
Le protocole générique et la politique de gate vivent dans
`docs/MANUAL_VALIDATION.md` ; ce fichier-ci est la version à suivre pas à pas.

> **Gate A est `EN ATTENTE`.** Ni `PASS`, ni `FAIL`. Je ne le déclarerai pas moi-même :
> j'attends le rapport rempli.

---

## 0. Pourquoi une application macOS n'est pas fournie

C'est une limite réelle de mon environnement, pas un choix :

- les **modèles d'export** Godot se téléchargent depuis `godotengine.org`, bloqué
  par la politique réseau de ce conteneur (`docs/KNOWN_ISSUES.md` ISS-001) ;
- aucun modèle n'est compilé dans l'arbre source ;
- construire un modèle macOS exige le **SDK macOS**, absent ici — une compilation
  croisée est impossible.

Le paquet livré est donc le **projet Godot complet**, à ouvrir avec un Godot
officiel. C'est aussi la forme la plus vérifiable : vous voyez le code que vous
exécutez.

---

## 1. Installer Godot 4.7.1 sur le Mac

**La version doit être exactement 4.7.1-stable**, édition standard (pas .NET).
Une autre version invaliderait le test : les API et le comportement diffèrent.

1. Télécharger depuis `https://godotengine.org/download/archive/` la version
   **4.7.1-stable**, build **macOS (Universal)**.
2. Déplacer `Godot.app` dans `/Applications`.
3. Premier lancement : macOS bloque une application non notariée. Faire
   **clic droit → Ouvrir**, puis confirmer. En cas de blocage persistant :
   *Réglages Système → Confidentialité et sécurité → « Ouvrir quand même »*.
4. Vérifier la version, dans le Terminal :

```bash
/Applications/Godot.app/Contents/MacOS/Godot --version
# doit afficher : 4.7.1.stable.official.<hash>
```

Pour la suite, ce raccourci évite de retaper le chemin :

```bash
alias godot='/Applications/Godot.app/Contents/MacOS/Godot'
```

## 2. Déballer le projet

```bash
cd ~/Downloads
unzip EclatsDOrage_GateA.zip -d EclatsDOrage_GateA
cd EclatsDOrage_GateA

# Contrôle d'intégrité : doit correspondre au SHA-256 annoncé à la livraison
shasum -a 256 ../EclatsDOrage_GateA.zip

# Ce que contient ce paquet, et à quel commit il correspond
cat PAQUET.txt
```

**Premier import** (une seule fois, ~30 s) :

```bash
godot --headless --path . --import
```

## 3. Régler le clavier en AZERTY

Indispensable pour l'étape 4. *Réglages Système → Clavier → Sources de saisie* →
ajouter **Français**, puis le sélectionner dans la barre de menus.

⚠️ C'est la disposition **système** qui compte, pas les lettres gravées sur les
touches. L'audit affiche la disposition détectée : s'il annonce QWERTY, la bascule
n'a pas été faite.

---

## 4. Procédure de test

Cocher au fur et à mesure dans `evidence/gateA/RAPPORT.md`, généré par :

```bash
tools/manual_validation_kit.sh
```

### 4.1 Lancement Boot → MainMenu

```bash
godot --path . 2>&1 | tee evidence/gateA/01_lancement.log
```

**Attendu** : la fenêtre s'ouvre ; la console affiche les lignes `[boot]` puis
`[boot] transition vers le menu principal.` ; le menu apparaît, titré
« Éclats d'Orage ».

> ⚠️ **Le menu est l'aboutissement attendu, pas une étape intermédiaire.** Il
> n'existe aucun monde ni personnage à ce stade : la Phase A ne livre que la
> fondation. Si le menu s'affiche et répond, l'étape est réussie — il n'y a rien
> d'autre à atteindre. « Continuer » et « Nouvelle partie » agissent réellement
> sur la sauvegarde puis annoncent que la vallée arrive en Phase D.

- **PASS** : menu affiché, **aucune ligne `ERROR:`** dans le log.
- **FAIL** : erreur bloquante, fenêtre noire, ou menu jamais atteint.

📸 `evidence/gateA/01_lancement.png` — la fenêtre au menu.

### 4.2 Clavier AZERTY — l'invariant central

Depuis le menu, cliquer **« Debug — Audit d'entrée »**. (Cette entrée n'existe
qu'en build de développement, §6.1 ; elle est absente d'un export final.)

Le bandeau doit afficher, en vert :
`AZERTY confirmé : la position liée à « gauche » porte l'étiquette « Q ».`

Puis **maintenir `Q`**. Deux verdicts se verrouillent et restent affichés :

1. `« Q » déclenche move_left : CONFIRMÉ`
2. `« Q » n'active jamais lock_on : CONFIRMÉ sur les appuis observés`

Le second est **irréversible en cas d'échec** : s'il passe au rouge une seule fois,
il y reste. C'est voulu — un appui malheureux ne doit pas pouvoir être effacé.

Parcourir ensuite tout le clavier :

| Touche | Action attendue | Observé |
|---|---|---|
| `Q` | `move_left` | |
| `Z` | `move_forward` | |
| `S` | `move_back` | |
| `D` | `move_right` | |
| `Espace` | `jump` | |
| `Maj gauche` | `sprint` | |
| `E` | `interact` | |
| `R` | `attack_heavy` | |
| `Ctrl gauche` | `dodge` | |
| `C` | `lock_on` | |
| `X` | `target_prev` | |
| `V` | `target_next` | |
| `Tab` | `inventory` | |
| `F` | `quick_meal` | |
| `Échap`* | `pause` | |
| clic gauche | `attack_light` + `shoot` | |
| clic droit | `aim` | |

\* `Échap` sert aussi à revenir au menu depuis l'audit : observer `pause`
s'allumer au moment de l'appui, la scène se ferme ensuite.

- **PASS** : les 18 actions répondent **et** le verdict 2 reste vert.
- **FAIL** : une action muette, une mauvaise correspondance, ou le verdict 2 rouge.

📸 `02_azerty_bandeau.png` (le bandeau) · `02_azerty_q_gauche.png` (`Q` maintenu,
`move_left` **ACTIF**, les deux verdicts verts).
📝 `02_azerty_tableau.md` — ce tableau, colonne « Observé » remplie.

### 4.3 Manette

Connecter la manette **avant** de lancer. La ligne
`Périphérique actif : … | Manette : …` doit afficher son nom.

| Entrée | Action attendue | Observé |
|---|---|---|
| stick gauche ↑ ← ↓ → | `move_forward` / `move_left` / `move_back` / `move_right` | |
| A / Croix | `jump` | |
| stick gauche pressé | `sprint` | |
| X / Carré | `interact` | |
| RB / R1 | `attack_light` | |
| RT / R2 | `attack_heavy` + `shoot` | |
| LT / L2 | `aim` | |
| B / Rond | `dodge` | |
| stick droit pressé | `lock_on` | |
| stick droit ← / → | `target_prev` / `target_next` | |
| Y / Triangle | `inventory` | |
| d-pad bas | `quick_meal` | |
| Menu / Start | `pause` | |

- **PASS** : toutes les entrées répondent.
- **FAIL** : manette non détectée, ou entrée morte.
- **`NON VÉRIFIÉ`** : aucune manette disponible. Le dire — ne pas extrapoler
  depuis le clavier.

📸 `03_manette_detectee.png` · 📝 `03_manette_tableau.md` + **modèle exact** de la
manette (le mapping dépend de la base SDL).

### 4.4 Navigation du MainMenu

```bash
godot --path .
```

- Flèches **haut/bas** : le focus parcourt les boutons.
- La liste **boucle** : depuis le dernier, on revient au premier.
- `Entrée` active le bouton focalisé.
- À la manette : d-pad et stick gauche naviguent, `A` active.
- Le focus ne disparaît **jamais**.

- **PASS** : navigation fluide dans les deux sens, clavier **et** manette.
- **FAIL** : le focus se perd, se bloque, ou saute des boutons.

### 4.5 Visibilité du focus

Au clavier seul, sans souris : **peut-on dire sans hésitation quel bouton est
sélectionné ?**

- **PASS** : oui, immédiatement.
- **FAIL** : il faut chercher, ou deux boutons semblent également actifs.

📸 `04_menu_focus.png` — un bouton clairement focalisé.

### 4.6 Boutons désactivés

« Options » est grisé. Sans sauvegarde, « Continuer » l'est aussi.

- Ils doivent être **grisés** ;
- et **jamais atteints** par la navigation — le focus doit les sauter.

- **PASS** : grisés et injoignables.
- **FAIL** : le focus s'y arrête, même brièvement.

### 4.7 Confirmation « Nouvelle partie »

1. Sans sauvegarde : « Nouvelle partie » crée la sauvegarde directement, et
   « Continuer » cesse d'être grisé.
2. Avec une sauvegarde : le **premier** appui affiche `Écraser la sauvegarde ?` et
   `Appuyer à nouveau pour confirmer.` — **rien n'est écrasé**.
3. Le **second** appui écrase.

- **PASS** : les trois comportements sont observés.
- **FAIL** : la sauvegarde est écrasée sans confirmation.

📸 `04_menu_confirmation.png` — l'état « Écraser la sauvegarde ? ».

### 4.8 Lisibilité visuelle

Redimensionner la fenêtre, du très petit au plein écran.

- La mise en page **suit** ; rien n'est coupé, superposé ni déformé.
- Le texte reste lisible sans effort à distance normale.
- Le contraste texte/fond est suffisant.

- **PASS** : la mise en page tient et le texte est lisible.
- **FAIL** : la mise en page casse, ou le texte devient illisible.

📸 `04_menu_petit.png` et `04_menu_grand.png`.

> Dire franchement ce qui est **laid**. Un menu fonctionnel mais austère est un
> `PASS` **avec réserve écrite**, pas un `FAIL` : la passe d'interface est prévue
> en Phase H. Un menu illisible est un `FAIL`.

---

## 5. Reprise dans une nouvelle session Claude Code

Cette étape lève la réserve principale du Gate 0 (`docs/DECISIONS.md` D-006) : le
critère « une session neuve reprend le travail en moins de 5 minutes » n'a jamais
été **mesuré**, seulement estimé par relecture. Il est donc `NON VÉRIFIÉ` depuis le
début, et je ne prétends pas le contraire.

### 5.1 Mesurer la reprise documentaire

Idéalement fait par quelqu'un qui n'a pas construit le projet.

1. **Démarrer un chronomètre.**
2. Lire, dans cet ordre et **rien d'autre** : `CLAUDE.md`, `docs/STATUS.md`,
   `docs/PROGRESS.md`, `docs/KNOWN_ISSUES.md`.
3. **Arrêter le chronomètre** dès que ces quatre questions ont une réponse :
   - où en est le projet ?
   - quel est le prochain jalon, et sa première action concrète ?
   - qu'est-ce qui est bloqué, et par quoi ?
   - quelle commande faut-il lancer avant de modifier quoi que ce soit ?

📝 `05_reprise.md` : durée, les quatre réponses **écrites par le lecteur**, et
toute question restée sans réponse — en nommant **le document fautif**. C'est le
document qu'il faudra corriger, pas le lecteur.

### 5.2 Relancer une session Claude Code sur ce projet

Dans une session neuve, le premier message peut être :

> Reprends le projet Éclats d'Orage. Lis `CLAUDE.md`, `docs/STATUS.md`,
> `docs/PROGRESS.md` et `docs/KNOWN_ISSUES.md`, puis dis-moi l'état du projet et
> la prochaine action prévue — **sans rien modifier**.

Une reprise correcte doit annoncer, sans qu'on le lui souffle : Gate 0 gelé avec
réserves, **Gate A `EN ATTENTE`** faute de validation humaine, et A.1/A.2 livrés.
Si elle propose de démarrer la Phase B, c'est que la continuité a échoué : le
noter comme un `FAIL` de cette étape.

⚠️ Le conteneur est éphémère : Godot doit être **recompilé** (~60-120 min,
`tools/setup_godot.sh`), les binaires officiels étant inaccessibles depuis là-bas
(ISS-001). Le lancer en arrière-plan dès le début.

### 5.3 Vérifier que le projet est réellement reprenable

Sur le Mac, avec Godot officiel :

```bash
tools/validate_fast.sh 2>&1 | tee evidence/gateA/05_validate_fast.log
echo "code retour : $?"
```

- **PASS** : les quatre réponses trouvées en < 5 min **et** `validate_fast.sh`
  sort en `0` avec **54 tests**.
- **FAIL** : une question sans réponse, ou la suite rouge.

---

## 6. Clôture

```bash
export VALIDATION_OPERATOR="votre nom"
tools/manual_validation_kit.sh --finalize
```

Le script écrit `evidence/gateA/MANIFESTE.txt` : commit, machine, versions et
SHA-256 de chaque preuve. Il **sort en code 3 tant qu'une preuve manque** — une
campagne incomplète ne peut pas être close par inadvertance.

Puis remplir le tableau final de `evidence/gateA/RAPPORT.md` :

| Étape | Verdict |
|---|---|
| 4.1 Lancement Boot → MainMenu | |
| 4.2 Clavier AZERTY (`Q` = gauche, `Q` ≠ lock-on) | |
| 4.3 Manette | |
| 4.4 Navigation du MainMenu | |
| 4.5 Visibilité du focus | |
| 4.6 Boutons désactivés | |
| 4.7 Confirmation « Nouvelle partie » | |
| 4.8 Lisibilité visuelle | |
| 5. Reprise en session neuve | |

**Le verdict global est le plus faible, jamais la moyenne** (§0.7).

Me transmettre ensuite `RAPPORT.md` et `MANIFESTE.txt` — ou simplement le contenu
du rapport. Je déclarerai alors Gate A `PASS` ou `FAIL`, je consignerai les
preuves, et **seulement ensuite** je démarrerai la Phase B — Traversal.

---

## Si quelque chose échoue

Ce n'est pas un problème : c'est le but. Un `FAIL` trouvé ici est un `FAIL` qui ne
traversera pas six phases.

- Noter **précisément** ce qui a été observé, pas une interprétation.
- Joindre la capture correspondante.
- Ne pas corriger sur place : je veux voir le défaut tel qu'il s'est produit.

Chaque `FAIL` deviendra une entrée de `docs/KNOWN_ISSUES.md` avec sa sévérité,
sera corrigé, puis **seule l'étape concernée** sera rejouée.
