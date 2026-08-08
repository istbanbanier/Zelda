# PROMPT 4 — MÉTHODE DE PRODUCTION VÉRIFIABLE POUR « ÉCLATS D'ORAGE »

## Instruction d'utilisation

Ce document est le **quatrième cahier des charges cumulatif** du projet. Il ne remplace
rien et ne retire aucune obligation.

| Cahier | Ce qu'il dit |
|---|---|
| `MASTER_SPEC.md` | **quoi** construire : la boucle vallée → donjon → boss → victoire |
| `PROMPT2_SPEC.md` | **comment l'améliorer** : profondeur systémique et professionnelle |
| `VISUAL_ASSET_BIBLE.md` | **à quoi ça doit ressembler** : art, assets, shaders, UI |
| `PROMPT4_METHOD.md` (ici) | **comment le prouver** : rendre les exigences vérifiables par une machine |

Les trois premiers décrivent des intentions. Aucun ne dit comment empêcher une intention
de se dégrader en silence. C'est le trou que celui-ci comble, et **uniquement** celui-là :
en cas de conflit sur le *contenu* du jeu, les trois autres priment. En cas de conflit sur
la *preuve*, c'est ce document.

**Origine.** Tout ce qui suit est transposé de `levy-street/world-of-claudecraft`, dépôt
public inspecté intégralement le 2026-08-07 (clone complet, branches, historique, refs de
PR). Constats et mesures : `docs/RESEARCH_LEDGER.md`, entrées **R-014** et **R-015**. Ce
sont des mécanismes empruntés à un projet comparable — un jeu 3D construit très
majoritairement par des agents — et non des idées inventées ici.

**Ce qui est déjà fait** est marqué `[EN PLACE]`. **Ce qui reste à décider** est marqué
`[À DÉCIDER]` et ne doit pas être adopté sans accord du propriétaire.

---

## 0. LE PRINCIPE DIRECTEUR

> **Un invariant qui ne vit que dans un document se dégrade en silence.
> Un invariant vérifié par une machine rougit à la seconde où quelqu'un le casse.**

Corollaire, tout aussi important :

> **Un contrôle trop lourd placé trop tôt finit contourné.**
> Un garde-fou de vingt minutes à chaque tour ne sera pas exécuté ; il sera désactivé.

Toute la méthode découle de ces deux phrases. Chaque contrôle se place **au point le
moins cher où il sert encore**, et ne contrôle que ce dont il est certain.

### Pourquoi croire à ce modèle

Mesures réelles sur le dépôt source, prises sur le clone et non sur sa page d'accueil :

| | |
|---|---|
| Commits | 9 873, en deux mois (10 juin → 7 août 2026) |
| Cadence | 150 à 344 commits par jour |
| Branches / tags | 570 / 46 |
| Pull requests | 2 623 refs, 836 fusionnées sur `main` |
| Livraisons | une version tous les 1 à 3 jours |
| `fix` vs `feat` | **2 573 contre 1 850** — réparer domine construire |
| `test` | 1 043 commits : un type de premier rang, pas un reliquat |
| Fichiers de règles | 51 `CLAUDE.md`, un par répertoire |

Un projet qui absorbe 300 commits par jour sans se déliter ne le doit pas à la discipline
individuelle de cinquante contributeurs. Il le doit à des portes qu'on ne peut pas oublier
de franchir.

---

## 1. LA BARRE EN COUCHES `[EN PLACE]`

Chaque couche fait un seul travail, au moment le moins cher où il est encore utile.

| Couche | Mécanisme | Quand | Coût | Bloque ? |
|---|---|---|---|---|
| Garde-fou instantané | `.claude/hooks/qa-stop.sh` | fin de chaque tour | millisecondes | oui |
| Plancher déterministe | `.githooks/pre-push` | à chaque `git push` | secondes | oui |
| Invariants d'état | `tests/unit/test_invariants.gd` | dans `validate_fast.sh` | secondes | oui |
| Suite complète | `tools/validate_fast.sh` | avant de déclarer un jalon fini | ~20 min | oui |
| Niveaux 4-7 | `tools/validate_release.sh` | avant livraison | long | oui / `BLOQUÉ` |
| Revue de jugement | `adversarial-qa` + `gate-review` | avant tout `PASS` | un agent | consultatif |

Détail et raison de chaque couche : `.claude/hooks/README.md`.

### Règles de conception d'un garde-fou

1. **Le garde-fou instantané ne contrôle QUE l'indiscutable.** Aujourd'hui : contenu
   Nintendo, image de référence employée comme asset, édition à la main de
   `.godot/imported/`, déclaration GDScript non typée. Il ne lance ni Godot, ni la suite,
   ni un sous-agent — un hook est une commande shell, il ne peut pas raisonner.
2. **Zéro faux positif, ou le garde-fou meurt.** Avant d'ajouter une règle, l'éprouver
   contre les formes légitimes. Exemple mesuré : les huit formes GDScript typées
   (`:=`, `: Type =`, `@export`, `@export_range`, `static var`, `Array[String]`, `const`,
   inférence) passent toutes ; seule `var x = 1` est prise.
3. **Une règle qui ne se distingue pas d'un usage légitime n'entre pas.** « Pas de
   `print()` sur le chemin critique » est exclue à dessein : `scripts/core/boot.gd` en
   contient onze, qui sont des diagnostics de démarrage structurés et légitimes.
4. **Le scan porte sur les lignes AJOUTÉES**, jamais sur l'arbre entier. La dette
   existante ne bloque personne ; seule la régression bloque.
5. **Les scripts de garde-fou s'excluent eux-mêmes.** Ils PORTENT les motifs interdits
   pour les interdire. Omission constatée en vrai : le premier push a été refusé par le
   plancher attrapant sa propre ligne de motifs.

### Avant d'ajouter un garde-fou : mesurer la dette

Toujours compter les violations existantes d'abord. Mesuré avant construction : **zéro**
déclaration non typée, **aucun** terme interdit hors `docs/`, liaison AZERTY correcte. Le
garde-fou est donc une protection anti-régression, pas un rattrapage de dette — et il faut
le dire ainsi. Si la dette est massive, le garde-fou se pose quand même, mais scopé au
diff, et la dette devient une tâche nommée, pas un blocage.

---

## 2. RENDRE LES INVARIANTS EXÉCUTABLES `[EN PLACE, à exécuter]`

Le dépôt source consacre **1 891 lignes** (`tests/architecture.test.ts`) à balayer chaque
fichier de son cœur pour interdire ce que son fichier de règles interdit en prose. La
prose dit la règle ; le test la fait rougir.

### Le partage des rôles

- **Le hook** regarde les lignes **ajoutées**, en millisecondes, à chaque tour.
- **Le test** regarde l'**état du projet** : un réglage, une touche remappée, un fichier
  déjà présent — ce qu'aucun diff ne montrera jamais.

Les deux sont nécessaires ; aucun ne remplace l'autre.

`tests/unit/test_invariants.gd` couvre aujourd'hui : `Q` à gauche via `physical_keycode`
(et non `keycode`, le piège exact), `lock_on` jamais sur `Q`, version 4.7.1 exacte,
avertissements de typage actifs, aucun contenu interdit dans le code livré, image de
référence jamais employée comme asset.

> **Statut honnête : `NON VÉRIFIÉ`.** Ce test est écrit mais n'a jamais été exécuté —
> Godot est absent du conteneur d'inspection. Ses chemins de réglages ont été validés
> statiquement contre `project.godot`. Il passe `À VÉRIFIER` au premier
> `tools/validate_fast.sh` sur une machine avec moteur.

### Comment en ajouter un

1. Prendre une ligne d'invariant du `CLAUDE.md` et se demander : *une machine peut-elle
   en constater la violation sans jouer au jeu ?*
2. Si oui, et si c'est un état → un test dans `tests/unit/test_invariants.gd`.
3. Si oui, et si c'est une ligne de code ajoutée → une règle dans `qa-stop.sh`.
4. Si non → c'est du jugement : `adversarial-qa`, ou `docs/MANUAL_VALIDATION.md`.
5. **Documenter le piège dans le test lui-même.** Le test doit expliquer *pourquoi il
   existe*, c'est-à-dire l'incident qu'il empêche de revenir. C'est déjà la convention du
   projet (voir l'en-tête de `tests/test_case.gd`) ; elle est excellente, la garder.

### Le piège du test qui ne peut pas échouer

Le dépôt source dédie un agent entier à ce sujet (`test-coverage-auditor`). Il traque :

- **la comparaison d'une constante avec elle-même** — un test qui lit une valeur et la
  compare à elle-même passe toujours ;
- **une assertion qui n'éprouve qu'un seul bras** d'une affirmation « soit / tous » ;
- **les clés, requêtes et jetons porteurs non épinglés à un littéral** ;
- toute assertion qui ne **rougirait pas réellement** en cas de régression.

C'est exactement le mode de panne d'ISS-018 chez nous : les créatures s'affichaient en
pièces détachées alors que **tous les tests étaient verts**, parce qu'ils mesuraient des
boîtes englobantes de maillages skinnés — donc la pose de liaison, pas ce que le moteur
dessine. Un test vert n'est pas une preuve ; un test qui échouerait sans le correctif en
est une.

> **Règle** : pour tout bug réel corrigé, écrire d'abord le test qui échoue, **vérifier
> qu'il échoue**, puis faire le plus petit changement qui le rend vert.

---

## 3. LA FABRIQUE D'ASSETS : DE L'IMAGE DE RÉFÉRENCE À L'ASSET LIVRÉ `[À DÉCIDER]`

C'est le problème central non résolu d'Éclats d'Orage. `VISUAL_ASSET_BIBLE` le décrit sur
33 sections, en prose. Le dépôt source a reconstruit une ville entière depuis des images
de référence avec une porte fermée à chaque étape.

Notre chaîne actuelle est : `source_assets/**.blend` → `tools/blender/run_export.sh` →
`assets/**.glb` → `python3 tools/gltf_inspect.py <glb>` → import Godot headless. Les
étapes ci-dessous **s'y insèrent**, elles ne la remplacent pas.

### Étape 1 — Admettre la référence, et la noter

Avant toute modélisation, noter la référence sur sept axes, de 1 à 3 :

| Axe | Question |
|---|---|
| Isolation de l'objet | est-il détachable du fond ? |
| Lisibilité de la silhouette | tient-elle en aplat noir ? |
| Déduction de profondeur | peut-on inférer le volume ? |
| Décomposition en primitives | se ramène-t-il à des formes simples ? |
| Procéduralité des matériaux | reproductible sans texture photo ? |
| Risque d'occlusion | des parties essentielles sont-elles cachées ? |
| Aptitude à l'interaction | supporte-t-il ce que le gameplay exige ? |

**Une référence peut être jugée inexploitable, et doit l'être** plutôt que de produire un
asset qu'on repoussera trois fois. Consigner la note et la décision.

Si la référence est une image générée par IA, ouvrir un registre de provenance : outil,
date, chemins exacts des entrées, hachages, itérations **rejetées** listées, et le texte de
prompt figé dans un fichier distinct qui fait autorité. Rappel de `MASTER_SPEC` §0.2 : une
image générée est un concept ou un moodboard, **jamais** une capture du moteur.

### Étape 2 — Verrouiller les budgets AVANT de modéliser

Écrire, avant de toucher Blender : cible et **plafond dur** de triangles, plafond
d'octets, nombre de primitives et de matériaux, dimensions en mètres.

Les étalons du dépôt source donnent l'ordre de grandeur d'un objet stylisé sans texture :
coffre 2 048 tri / 4 matériaux / 44 Ko ; boîte aux lettres 1 640 tri / 2 mat / 33 Ko ;
bâtiment de service 2 300 à 4 400 tri / 2 mat / 40 à 68 Ko ; **unique** grand point de
repère 8 226 tri / 6 mat / 137 Ko. Nos fourchettes sont dans `ART_BIBLE` §5 et
`VISUAL_ASSET_BIBLE` §4.5 — la nouveauté n'est pas le chiffre, c'est qu'il soit **posé
avant** et **vérifié à l'export**.

### Étape 3 — L'inventaire de détails

Transforme « ressembler à l'image » en liste vérifiable. Balayer la référence en grille
3×3 plus des vues croisées, et retenir **au moins douze** détails. Chacun porte :

```json
{
  "id": "arete-chaude-strate-haute",
  "kind": "bevel",
  "description": "Le chanfrein supérieur capte la lumière rasante et sépare la falaise du ciel.",
  "region": { "x": 0.12, "y": 0.03, "width": 0.76, "height": 0.28, "units": "normalized" },
  "scale": "meso",
  "affects": "silhouette et hautes lumières",
  "mapsTo": { "type": "component.localFeatures", "ref": "falaise/chanfrein-sommet" },
  "evidenceRef": "vue-rasante",
  "confidence": 0.92
}
```

`scale` reprend nos trois fréquences (`VISUAL_ASSET_BIBLE` §1.3) : macro, méso, micro.
`affects` dit ce qui porte le détail — géométrie, couleur de sommet, rugosité, silhouette.
`confidence` rend visible ce qui est déduit plutôt que vu.

### Étape 4 — Le seuil est PAR TRAIT D'IDENTITÉ

> **Une moyenne globale n'excuse jamais un trait d'identité raté.**

C'est une critique directe de notre WOW Gate. Notre note sur 100
(`VISUAL_ASSET_BIBLE` §30.2) n'a pour seule garde que « aucun domaine à zéro » : une
citadelle à 3/10 passe si le reste compense. Chez eux, chaque trait critique doit franchir
son propre seuil (0,70), **quel que soit le total**.

`[À DÉCIDER]` — adoption proposée : conserver la note sur 100 **et** ajouter la règle du
seuil par trait, en nommant les traits d'identité de la vue North Star (héros lisible de
dos · camp · pylône · citadelle · ruban de la rivière · éclair à cœur blanc · chaud à
gauche contre froid lointain). Un seul raté = échec du gate.

### Étape 5 — Refuser le carton

La silhouette doit tenir **de face, de profil, de trois-quarts et en vue rasante**. Une
seule belle image ne prouve rien. Nos tests de silhouette existent déjà
(`VISUAL_ASSET_BIBLE` §30.3) : leur ajouter systématiquement la vue rasante, qui est celle
qui démasque un plan peint en guise de volume.

### Étape 6 — Épingler le contrat de l'asset dans un test

C'est le point qui aurait attrapé **ISS-018**. Après export, épingler dans un test :
octets, sha256, triangles, primitives, matériaux, absence de texture/animation/squelette
non voulues, boîte englobante **posée au sol** (min Y ≈ 0) et centrée en X/Z, et
**l'empreinte de la source**.

Chez nous, l'outil existe déjà : `tools/gltf_inspect.py` sait lire un `.glb` hors Godot.
L'adaptation consiste à lui faire écrire un contrat, puis à le comparer.

> **Attention, leçon d'ISS-018 :** ne pas épingler la boîte englobante d'un maillage
> **skinné** — elle décrit la pose de liaison, pas ce que le moteur dessine. Pour un
> personnage, lire la géométrie **après** évaluation du graphe de dépendances, comme le
> fait déjà le niveau correspondant de `validate_fast.sh`.

### Étape 7 — Prouver en jeu, et rapporter le delta

Capture depuis le moteur réel, tests ciblés, puis la suite. Rapporter le **delta exact**
en octets et en triangles. Et, mot pour mot, la discipline du dépôt source : *un budget
d'assets qui reste rouge sur un dépassement préexistant reste rouge — ne jamais prétendre
qu'il est passé*.

---

## 4. L'IMPLANTATION EST UNE DONNÉE, LES TESTS ÉPINGLENT LES LITTÉRAUX `[À DÉCIDER]`

Le plan directeur de leur ville est un **tableau** : ordre, nom, position `(x,z)`,
rotation en radians, dimensions `L × H × P`, et une échelle exprimée **relativement au
joueur**. Puis : « les tests épinglent chaque littéral ci-dessus et prouvent que tous les
coins de bâtiment restent à l'intérieur de la face interne de l'enceinte ».

Deux idées à prendre :

1. **L'échelle relative au joueur.** Ils expriment chaque hauteur en multiples du gabarit
   humanoïde. Nous avons le même repère : héros = 1,78 m (`VISUAL_ASSET_BIBLE` §3). Écrire
   « 3,0 hauteurs de héros » plutôt que « 5,34 m » rend une erreur d'échelle visible à la
   lecture.
2. **Les invariants spatiaux sont testables.** Chez nous : aucun objet essentiel hors des
   limites, aucune paroi invisible exposée, les corniches de repos existent bien sur la
   falaise d'apprentissage, l'arène du boss n'a pas de colonne centrale. Ce sont des
   affirmations géométriques — donc des tests, pas des espoirs.

Notre `docs/MASTER_SPEC.md` §3.3 donne déjà des coordonnées d'implantation. Elles ne sont
épinglées nulle part.

---

## 5. ANIMATION : RECYCLER AVANT D'INVENTER `[À DÉCIDER]`

Leur technique par défaut n'appelle pas Blender : elle **échantillonne des poses déjà
présentes dans la bibliothèque de clips du rig**, les mélange avec un lissage écrit à la
main, et cuit le résultat en un nouveau clip. Blender headless est le chemin
d'**escalade**, réservé au cas où aucun clip donneur ne peut fournir la pose.

Et surtout, la démarche qui précède : face à une proposition d'outillage Blender à grande
échelle, ils ont commencé par **vérifier que cet outillage n'était pas déjà branché**. Il
ne l'était pas. Ils l'ont écrit, puis ont choisi la voie sans dépendance.

> **Règle** : avant de construire un pipeline, vérifier ce qui existe et le dire. La
> bibliothèque d'animations exigée par `VISUAL_ASSET_BIBLE` §13.6 est immense ; une part
> se dérive de clips déjà présents plutôt que de s'autoriser à tout produire.

---

## 6. LES PIÈGES QUI ÉCHOUENT EN SILENCE : UN FICHIER DE RÈGLES PAR RÉPERTOIRE `[À DÉCIDER]`

Le dépôt source compte **51 `CLAUDE.md`**, un par répertoire, chargés à la demande quand on
ouvre un fichier là-bas. La racine tient en ~200 lignes et **interdit explicitement** d'y
dupliquer le contenu local.

Ce que contient un fichier local, sur l'exemple d'un répertoire d'assets :

- la **moyenne de taille mesurée** de la catégorie, avec le compte de fichiers ;
- la fourchette admise pour une nouvelle entrée ;
- la commande de compression exacte ;
- **le piège qui échoue en silence**, écrit noir sur blanc :

> « Toujours compresser en meshopt, **jamais** en draco : le chargeur runtime n'a pas de
> `DRACOLoader`, donc un GLB draco échoue silencieusement et retombe sur l'ancienne
> géométrie procédurale, **sans erreur visible**. »

C'est la forme la plus efficace de transmission que j'aie vue dans ce dépôt : le savoir
douloureux est posé là où on va le rencontrer, pas dans un document que personne ne rouvre.

`[À DÉCIDER]` — candidats chez nous, par ordre d'utilité : `assets/`, `tools/`, `tests/`,
`scripts/`, `shaders/`, `resources/tuning/`. Chacun porte déjà des pièges connus, dispersés
dans les commentaires et `KNOWN_ISSUES`.

---

## 7. DOCUMENTS VIVANTS CONTRE ARCHIVES HISTORIQUES `[À DÉCIDER]`

Leur `docs/CLAUDE.md` tranche une ambiguïté que nous avons :

> « Deux sortes vivent ici : les **documents vivants** (runbooks, spécifications de travail
> non construit) et les **archives historiques** (programmes livrés, rapports ponctuels).
> **Seuls les documents vivants font autorité**, et même eux décrivent un comportement
> *voulu* : quand le code et un document divergent, revérifier contre le code et consigner
> l'écart. Les points d'accroche `fichier:ligne` dérivent : faire confiance à l'intention
> du document, pas à ses numéros de ligne. »

Nous avons quatre cahiers cumulatifs et une quarantaine de documents, sans cette
distinction. Un rapport de gate d'il y a trois semaines a aujourd'hui la même apparence
d'autorité que `MASTER_SPEC`.

`[À DÉCIDER]` — marquer chaque document `VIVANT` ou `HISTORIQUE` dans son en-tête, et
énoncer la règle de divergence dans `CLAUDE.md`.

---

## 8. MODULARITÉ : LA RÈGLE DE TROIS

Trois règles, transposables telles quelles :

1. **Extraire à la règle de trois, pas avant.** Deux blocs semblables se laissent
   tranquilles ; un troisième exemplaire — ou un bloc portant une responsabilité qu'on
   sait nommer — mérite son module. Ne jamais abstraire pour un seul usage ni pour un
   besoin futur hypothétique.
2. **La question unique avant de grossir un fichier déjà gros** : *ce comportement a-t-il
   besoin de l'état mutable privé de ce coordinateur ?* Non → un module voisin. En partie
   → extraire la partie pure (le calcul, le formatage, la résolution d'identifiant) dans
   un module qu'un test importe directement, et laisser un consommateur mince.
3. **Corriger un bug par le test d'abord.** Reproduire avec un test qui échoue sur le vrai
   chemin de code ; si la logique fautive est enfouie dans un coordinateur, c'est le signal
   qu'il faut d'abord en extraire l'unité à tester.

Cela sert directement notre §5.4 (« composition plutôt qu'héritage profond ») en lui
donnant un critère de décision au lieu d'un principe.

---

## 9. REVUE : DES SPÉCIALISTES, ET LA COUVERTURE AVANT LE FILTRAGE

Le dépôt source embarque **neuf agents relecteurs**, tous en lecture seule, chacun sur un
périmètre nommé : architecture/déterminisme, parité entre hôtes, seams de présentation,
performance base de données, sûreté des migrations, vie privée/sécurité, audit de malware
de livraison, couverture de tests, et une porte QA de fin de contribution.

Trois règles de méthode :

1. **Le relecteur cherche la COUVERTURE, pas le filtrage.** Sa mission est de signaler
   *tout* écart de correction ou d'exigence, avec **confiance et sévérité**. Le tri vient
   après, dans une passe séparée. Un relecteur qui filtre lui-même cache des défauts.
2. **Le contexte doit être frais.** Toujours relancer un agent neuf, jamais celui qui a
   écrit le code. Nous l'avons déjà : `adversarial-qa`. La nouveauté est la
   **spécialisation** — un relecteur par domaine, dont la description dit précisément
   quand le convoquer.
3. **Chaque constat porte une sévérité et une preuve** : `bloquant` / `à corriger` /
   `détail`, avec un pointeur `fichier:ligne` et une ligne de justification.

Sur la **voix** d'une revue, leur consigne mérite d'être reprise mot pour mot :

> « Court, calme, ordinaire. Écrire comme une personne : pas de préambule, pas de résumé
> de résumé, pas de félicitations pour s'éclaircir la gorge, pas de reformulation du diff
> en liste à puces. **Si une phrase sonne comme un modèle l'a écrite, la couper.** »

---

## 10. CADENCE ET HYGIÈNE DU DÉPÔT

- **Livrer petit et souvent** : une version tous les 1 à 3 jours, 46 tags en deux mois.
- **Partir de la branche de livraison courante**, pas de la branche principale, qui ne
  reçoit que du fini.
- **Un arbre de travail git séparé par tâche**, pour que du travail en cours sans rapport
  ne contamine jamais une branche. Cela recoupe notre règle la plus coûteuse :
  `COMMENT_TRAVAILLER_ENSEMBLE` §1, « une seule session à la fois ».
- **Commits conventionnels avec portée** : `feat(combat): …`, `fix(donjon): …`. 7 820 de
  leurs 9 873 commits suivent la convention.
- **Ne jamais indexer avec `git add -A`** quand un arbre peut être partagé : indexer des
  chemins explicites. Souvent, le bon geste est de ne rien committer qui ne soit pas à soi.
- **En CI, détecter les changements qui ne touchent pas le code** et sauter les portes
  correspondantes ; isoler les tests longs dans leur propre voie.

---

## 11. CE QUI NE SE TRANSPOSE PAS

Honnêteté obligatoire, sans quoi ce document ferait plus de mal que de bien.

| Leur mécanisme | Pourquoi il ne s'applique pas tel quel |
|---|---|
| Leurs invariants (tirets cadratins, emojis, `.only(`) | ce sont **leurs** règles, pas les nôtres. On transpose le mécanisme, jamais la liste |
| File de fusion, portes CI à deux étages | supposent une CI qui **exécute** les tests ; nos trois workflows ne le font pas |
| Gate nocturne | même dépendance |
| GLB procéduraux sans texture, atlas partagé | leur pile est Three.js ; la nôtre est Godot + Blender → glTF |
| `pnpm`, Vitest, Biome | sans objet ici |
| Cinquante contributeurs | notre contrainte est l'inverse : **une seule session à la fois** |

Et la limite qui prime sur tout : **ce conteneur n'a ni écran, ni clavier, ni manette, ni
GPU**. Aucun mécanisme de ce document ne transforme un test automatique en preuve de
jouabilité. Les contrôles manuels de `MASTER_SPEC` §21.4 restent impossibles ici et passent
par `docs/MANUAL_VALIDATION.md`. Un gate qui en dépend reste `EN ATTENTE`.

---

## 12. VOCABULAIRE DE VÉRITÉ

Inchangé et non négociable. Rappelé ici parce que ce document parle de preuve.

`Implémenté` (raccordé) < `Fonctionnel` (testé en scène exécutable) < `Validé` (conforme,
sans régression connue) < `Final` (zéro placeholder critique).

Statuts d'un critère : `PASS` · `PARTIAL` · `FAIL` · `BLOQUÉ` · `NON VÉRIFIÉ`.

- Tout critère non testé est `NON VÉRIFIÉ`, **jamais** implicitement réussi.
- Il est interdit de transformer `NON VÉRIFIÉ` en `PASS` par déduction.
- Le verdict d'un gate est **le plus faible** de ses critères, pas leur moyenne.
- Une mesure obtenue en rendu logiciel n'est **jamais** un budget de frame.
- Une capture vient du moteur réel, avec son manifeste, depuis un arbre **committé**.

---

## 13. CHECKLIST D'ADOPTION

Ce qui est fait, ce qui reste, dans l'ordre du rapport coût/bénéfice.

| # | Élément | Coût | État |
|---|---|---|---|
| 1 | Barre en couches (hooks Stop + pre-push) | fait | `[EN PLACE]`, testé |
| 2 | Test d'invariants d'état | fait | `[EN PLACE]`, **`NON VÉRIFIÉ`** — exécuter |
| 3 | Seuil par trait d'identité au WOW Gate | faible | `[À DÉCIDER]` |
| 4 | Fichier de règles par répertoire, avec pièges mesurés | faible | `[À DÉCIDER]` |
| 5 | Marquer chaque doc `VIVANT` / `HISTORIQUE` | faible | `[À DÉCIDER]` |
| 6 | Vue rasante ajoutée aux tests de silhouette | faible | `[À DÉCIDER]` |
| 7 | Budgets d'assets verrouillés avant modélisation | moyen | `[À DÉCIDER]` |
| 8 | Inventaire de détails pour les assets North Star | moyen | `[À DÉCIDER]` |
| 9 | Contrat d'asset épinglé dans un test | moyen | `[À DÉCIDER]` |
| 10 | Littéraux d'implantation épinglés | moyen | `[À DÉCIDER]` |
| 11 | Relecteurs spécialisés au-delà d'`adversarial-qa` | moyen | `[À DÉCIDER]` |
| 12 | CI qui exécute réellement les tests | élevé | `[À DÉCIDER]`, débloque 13 |
| 13 | Portes CI à deux étages + voie tests longs | élevé | dépend de 12 |

**Les éléments `[À DÉCIDER]` touchent la barre de qualité du projet. Ils appartiennent au
propriétaire, pas à la session.** Ne pas les adopter unilatéralement : les proposer, avec
leur coût, et attendre.

---

## FIN DU PROMPT 4

Ce document n'ajoute aucune fonctionnalité au jeu. Il rend vérifiable ce que les trois
autres exigent déjà. Sa réussite ne se mesure pas au nombre de règles adoptées, mais à une
seule chose : **le jour où quelqu'un casse un invariant, l'apprend-il en secondes, ou
trois semaines plus tard par la bouche du joueur ?**
