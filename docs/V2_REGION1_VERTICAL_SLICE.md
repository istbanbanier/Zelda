# TRANCHE VERTICALE — région 1, lot 2

Statut : **VIVANT, PRÊT À EXÉCUTER, NON AUTORISÉ.**
Date : 2026-08-27. `GO_V2_3_B_LOT2 = FALSE`.

Ce document rend la tranche **directement exécutable dès que le lead
l'autorise**. Aucune ligne de production n'a été écrite, aucun lieu accepté
n'a été touché. Autorité amont : `docs/V2_PRODUCT_DOCTRINE.md` (l'ambition),
`docs/V2_LONG_GAME_ROADMAP.md` (l'ordre et le coût).

---

## 1. Où cette tranche se situe

Le chemin critique de la feuille de route place « **finir la région 1** » en
étape 1, juste après la mesure du temps de parcours. Cette tranche est le
deuxième des quatre lots qui y mènent : **21 lieux déclarés restent à
construire**, celui-ci en prend **six**.

Elle ne touche à aucun système absent. C'est délibéré : les six sujets se
posent sur l'infrastructure déjà payée, et leur seul but est de **calibrer le
coût unitaire** sur un lot dont les prédécesseurs sont mesurés.

---

## 2. Expérience joueur visée

Le joueur qui a franchi le lot 1 connaît la vallée sûre. Ce lot lui donne
**deux choses qu'il n'a pas encore** :

1. **Une raison de monter.** Trois des six sujets sont en hauteur
   (`veil_falls` à Y=15, `earth_altar` à Y=26, `logging_hamlet` à Y=8) ;
   l'autel de terre est explicitement *la récompense de l'ascension* de la
   paroi d'apprentissage. La route des hauteurs cesse d'être un détour.
2. **Une raison de traverser.** Le pont magnétique franchit le bras nord :
   il transforme un obstacle en raccourci permanent — c'est le temps
   **restaurer** de la boucle, appliqué pour la première fois.

Émotion visée, dans l'ordre : *curiosité* (une silhouette en hauteur qu'on ne
sait pas atteindre) → *ingéniosité* (la polarité ouvre le passage) →
*appartenance* (le raccourci reste ouvert au retour).

---

## 3. Contenu exact — six sujets, coordonnées gelées

Les positions viennent de `resources/world_v2/world_v2_layout.json` et ne
sont **pas** rediscutées ici : le layout fait foi sur les nombres.

| ID | Nom | Catégorie | Région | Site V2 | Récompense |
|---|---|---|---|---|---|
| `valley.poi.logging_hamlet.01` | Hameau des bûcherons | village | r06 bois du Levant | `[118, 8, 96]` | arme au sol — gourdin |
| `valley.poi.mining_post.01` | Poste minier | village | r04 falaises du Couchant | `[-112, 5, 58]` | coffre — flèches |
| `valley.poi.veil_falls.01` | La Chute du Voile | merveille | r07 hauteurs de l'Orient | `[196, 15, 20]` | coffre — flèches |
| `valley.poi.ancient_aqueduct.01` | Aqueduc ancien | ruine | r09 ruines du Cœur | `[-14, 4, -32]` | fragment d'histoire |
| `valley.poi.magnetic_bridge.01` | Pont magnétique | systémique `polarite` | r03 val de Néris | `[-44, 2, -58]` | — (raccourci) |
| `earth_altar` | Autel de terre | systémique `ground` | r04 falaises du Couchant | `[-136, 26, 92]` | — (école Ground) |

### Identité et silhouette attendue, par sujet

**Hameau des bûcherons** — horizontale basse, bois fendu, billes empilées, une
verticale unique (cheminée ou grue de levage). Ne doit **pas** ressembler au
village riverain déjà accepté : le détecteur R-D3 a déjà attrapé un belvédère
trop proche de la grotte, et il attrapera celui-ci. Composition *industrielle*,
pas résidentielle.

**Poste minier** — adossé à la paroi, masse creusée plus que bâtie ; entrée
sombre, déblais en éventail, étais. Sa silhouette doit dire « on entre dans la
roche », par opposition au hameau qui dit « on habite dessus ».

**La Chute du Voile** — belvédère, pas bâtiment. La cascade naît à l'ouest ; le
sujet est le **point de vue**, et son intérêt est ce qu'il montre. Silhouette
minimale, cadrage maximal.

**Aqueduc ancien** — la seule ruine du lot. Arches répétées à rythme
irrégulier, un tronçon effondré. C'est aussi le sujet qui enseigne le langage
architectural du donjon en extérieur.

**Pont magnétique** — deux culées, un tablier en segments métal/céramique,
pivots visibles. L'état non alimenté doit se lire **de loin** comme un passage
interrompu, sinon le joueur ne saura pas qu'il y a quelque chose à faire.

**Autel de terre** — plaque basse à trois arcs descendants vers une barre
brisée, cuivre enterré, racines. Sobre : c'est un motif du langage de
Résonance, pas un monument.

---

## 4. Systèmes requis — tous présents

| Système | État | Rôle dans la tranche |
|---|---|---|
| `WorldV2PlacesBuilder` | présent | monter les six scènes au layout |
| Terrain / heightmap | présent, **gelé** | ancrage au sol |
| `ResonanceController` — Polarité | présent | pont magnétique |
| `ResonanceController` — Ground | présent | autel de terre |
| `RewardAnchor` | présent | quatre récompenses |
| Sauvegarde (`SaveSystem`) | présent | états persistants des six lieux |

**Aucun système absent n'est requis.** C'est la propriété qui rend cette
tranche exécutable immédiatement, et c'est pourquoi elle passe avant
PNJ/quêtes malgré leur priorité stratégique supérieure.

---

## 5. Dépendances et gel

**Gelé, intouchable :** les 15 lieux montés, le terrain, l'hydrologie, la
végétation V2.2, les routes, les caméras, les récompenses existantes.
Vérification par `tools/gel_verifier.sh` (43 éléments) et
`GEL_SIX_LIEUX_51b7b29.sha256` (46 fichiers) **avant et après** chaque
intégration — pas seulement à la fin.

**Dépendance de séquence :** le pont magnétique et l'autel de terre exercent
deux écoles de Résonance. Ils viennent **en dernier**, après les quatre sujets
purement architecturaux, pour que l'échec éventuel d'une école ne bloque pas
le lot entier.

---

## 6. Budgets

Dérivés de la médiane mesurée de **24 commits par lieu** sur les treize lieux
construits (`tools/mesures_socle.py`).

| | Estimation |
|---|---:|
| Six sujets × 24 commits | **~145 commits** |
| Fourchette attendue | 90 (min observé ×6) à 270 (max ×6) |

Budgets géométriques : **inchangés**, ceux du lot 1 —
`AIRE_RUNTIME_PLAFOND_PCT = 20.4`, `HEXA_PLAFOND_PCT = 25.0`. Ce sont des
**plafonds, jamais des cibles**, et ils ne sont pas recalibrés pour ce lot :
recalibrer un seuil sur la géométrie qu'on est en train de juger serait
calibrer sur le sujet.

---

## 7. Tests ROUGES à écrire en premier

Dans l'ordre, et chacun doit **échouer avant** la moindre géométrie.

1. **`LOT2_PLACES` dans `test_world_v2_places_contract.gd`.** L'en-tête du
   fichier le dit déjà pour le lot 1 : *« un lot qui n'y entrerait pas
   pourrait rester marqueur sans qu'un seul test rougisse »*. C'est le
   premier geste, avant tout le reste.
2. **Six IDs inconnus du REGISTRY** → rouge tant que les scènes n'existent pas.
3. **Placement divergent du layout** → rouge sur les six coordonnées ci-dessus.
4. **Bâti flottant ou enterré** → rouge tant que l'ancrage sol n'est pas fait.
5. **Collision sur une route contractuelle** → rouge si un collider mord.
6. **Fenêtre gelée bouchée** → rouge, avec le nom du coupable.
7. **Détecteur R-D3 de ressemblance** → rouge si le hameau des bûcherons
   ressemble trop au village riverain déjà accepté.
8. **Deux contrôles négatifs d'école** : polarité désactivée → le pont reste
   infranchissable ; Ground désactivé → l'autel ne répond pas.

Le point 8 est celui qu'on oublie : sans lui, un pont qui s'ouvrirait tout
seul passerait pour un succès.

---

## 8. Critères artistiques

- Silhouette lisible en aplat noir à 10, 25 et 50 m, **vue rasante comprise**.
- Aucune ressemblance IoU avec un lieu déjà accepté au-delà du seuil R-D3.
- Trois hauteurs lisibles sur les sujets qui en ont.
- Le cyan reste rare : seuls le pont et l'autel en portent, et seulement à
  l'état actif.
- Aucun placeholder sur le chemin de vue des six caméras gelées.

## 9. Critères techniques

- `tools/validate_fast.sh` **vert**, code retour 0, sans tube.
- Gels **46/46** et **43/43** avant et après.
- Zéro erreur de parsing, zéro référence cassée.
- Les six lieux persistent leur état à travers sauvegarde et rechargement.
- Aucun identifiant persistant dupliqué.
- Autotests de l'appareil verts (`verdict.py`, `analyse_journal_devmode.py`,
  `fumee_build_exportee.py`).

---

## 10. Ordre d'intégration

| # | Sujet | Pourquoi ce rang |
|---|---|---|
| 1 | Aqueduc ancien | le plus simple ; valide la chaîne de bout en bout à coût minimal |
| 2 | Poste minier | premier sujet adossé à une paroi ; exerce l'ancrage en pente |
| 3 | Hameau des bûcherons | premier sujet collectif ; c'est lui que R-D3 risque d'attraper |
| 4 | La Chute du Voile | dépend d'un cadrage, donc des trois précédents pour comparaison |
| 5 | Pont magnétique | première école de Résonance ; isolable si elle échoue |
| 6 | Autel de terre | seconde école ; dernier parce qu'il dépend du sommet de la paroi |

**Un sujet par commit cohérent, gels revérifiés entre chacun.** Un lot qui
s'intègre d'un bloc ne dit pas lequel de ses six a cassé quoi.

---

## 11. Définition de « terminé »

- [ ] Les six sujets montés, `LOT2_PLACES` dans le contrat, union appliquée.
- [ ] Les huit tests rouges devenus verts, **et prouvés rouges avant**.
- [ ] Deux contrôles négatifs d'école joués et rouges quand ils doivent l'être.
- [ ] `validate_fast.sh` vert, code retour relevé **sans tube**.
- [ ] Gels 46/46 et 43/43, avant et après.
- [ ] Six vues capturées depuis un arbre **committé**, `repo_dirty: false`.
- [ ] Coût réel du lot mesuré et **comparé aux ~145 commits estimés** — c'est
      la sortie la plus utile de la tranche, plus que les lieux eux-mêmes.
- [ ] `STATUS.md`, `PROGRESS.md`, `KNOWN_ISSUES.md` à jour.
- [ ] Revue contradictoire à contexte frais → `PASS` / `FAIL` / `BLOQUÉ`.

**Ce qui ne fait PAS partie de « terminé » :** aucune release, aucun verdict
artistique auto-décerné, aucune ouverture du lot 3.

---

## 12. Ce que cette tranche n'apprend pas

Elle ne dit rien des systèmes absents — quêtes, PNJ, multi-régions. Elle ne
rapproche pas de 30-50 heures autrement qu'en finissant une région dont on
saura enfin le coût. C'est utile et c'est borné, et il faut le dire ainsi
plutôt que de lui prêter une portée qu'elle n'a pas.
