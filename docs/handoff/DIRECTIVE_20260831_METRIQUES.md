# Les dix métriques exigées par la directive du 2026-08-31

**Document HISTORIQUE.** Il relève ce qui s'est passé, il ne fait autorité sur
rien.

Il vit sur la branche de la voie C faute de branche partagée : la directive
interdit toute fusion officielle, les trois voies sont isolées, et ce relevé
les traverse toutes. Le déplacer si une branche commune existe un jour.

Toutes les valeurs ci-dessous sont **relevées dans le journal de session**
(`~/.claude/projects/.../subagents/agent-*.jsonl`) et dans `git log`, pas
estimées. Là où je ne peux pas mesurer, je l'écris.

---

## 0. Le fait qui prime sur les dix autres

**Agent Teams n'était pas disponible.** Le substitut employé — des sous-agents
de fond adressables en topologie en étoile, via `SendMessage` — a été **annoncé
comme tel**, et non glissé en silence à la place de ce qui était demandé. La
directive l'exigeait explicitement : « Si Agent Teams n'est réellement pas
disponible, ne pas lancer silencieusement un Dynamic Workflow. Expliquer
précisément le blocage technique. »

Tout ce qui suit décrit donc la performance de ce substitut, pas celle d'un
Agent Team.

---

## 1. Nombre maximum réellement actifs simultanément

**3.** Atteint le 31/08 à 00:32.

La directive demandait de démarrer à 1 lead + 8 coéquipiers, et de monter à 12
puis 16 **seulement si du travail réellement indépendant restait**. Je n'ai
jamais dépassé 3, et je n'ai lancé que **8 agents en tout** sur la vague.

Ce n'est pas une réserve de prudence : c'est ce que la structure du travail
permettait, et trois contraintes s'y opposaient toutes les trois.

| Contrainte | Effet sur la concurrence |
|---|---|
| **Trois rédacteurs maximum**, un jeu de fichiers par voie | plafonne l'écriture à 3 — et il n'y en a eu que **2**, ISS-088 ayant été traitée par le lead |
| Les contre-revues sont **postérieures** à ce qu'elles relisent | elles ne peuvent pas tourner en même temps que leur sujet |
| Verrou `flock` unique sur Godot et Blender | tout agent ayant besoin du moteur fait la queue derrière les autres, quelle qu'en soit le nombre |

La directive dit aussi : « **Ne pas inventer de tâches pour remplir les
places.** » Monter à 8 simultanés aurait demandé d'en inventer cinq. Je ne l'ai
pas fait, et c'est la raison exacte du chiffre 3.

## 2. Temps jusqu'au premier résultat utile

**9 minutes.** Premier lancement à 00:31, premier rapport exploitable rendu à
00:40 (`a2a00a98`, contre-revue en lecture seule sur ISS-086/088).

## 3. Résultats utiles par heure

La vague va de 00:31 à 03:49, soit **3 h 18**.

- **8 rapports rendus sur 8 lancés** → 2,4 rapports/h.
- **8 rapports sur 8 ont produit au moins une correction acceptée ou une
  réfutation confirmée** → 2,4 rapports utiles/h. Aucun rapport à jeter.
- En constats distincts acceptés après reproduction : **19** → **5,8/h**.

Le chiffre qui compte n'est aucun des trois. Deux constats sur les dix-neuf
étaient de ceux qui invalident un lot entier :

- l'instrument spectral était encore faux d'un **facteur 1 700** sur les
  one-shots percussifs, soit 20 des 21 WAV du dépôt ;
- `72e081a6` (ISS-088) n'est pas dans l'arbre de la voie C, donc tout prototype
  d'ambiance y aurait rebouclé **en silence** sur un cinquième de sa longueur,
  et l'essai d'écoute aurait condamné la conception par un accident de fusion.

## 4. Conclusions dupliquées entre agents

**0 entre les deux contre-revues de la voie C.** Périmètres disjoints attribués
à l'avance, et respectés : CR n°1 a écrit d'elle-même « les prototypes et le
protocole d'écoute : hors de mon périmètre, confiés au second relecteur ».

Entre les deux contre-revues de la voie B, **1 recoupement partiel** : les deux
ont examiné la migration des 65 paires, mais par des méthodes différentes
(appariement de lignes contre appariement d'identifiants). Ce n'est pas une
duplication à supprimer — c'est ce qui a permis de conclure « zéro octet de
divergence » avec deux chemins indépendants au lieu d'un.

## 5. Résultats rejetés par contre-revue

**2 affirmations réfutées, dont une des miennes.**

| Affirmation | Source | Verdict |
|---|---|---|
| un dépassement de délai du verrou produirait un `RÉSULTAT` vide, indistinguable d'un contrat qui ne rougit pas | rédacteur voie B | **RÉFUTÉE** — le lanceur prend le verrou sur le descripteur, imprime `BLOQUÉ` + `RIEN N'A TOURNÉ` et rend 3 |
| une copie survivante déclencherait le portail A par `Leaked instance` | **moi, dans mon propre commit** | **RÉFUTÉE deux fois** — `Leaked instance:` est sous `is_stdout_verbose()`, que `validate_fast` ne passe pas, et `CLASSES_MOTEUR` n'est jamais consulté par `verdict_agregat()` |

Et **1 chiffre corrigé à la baisse** : CR n°1 annonçait le tableau d'occupation
faux sur 5 de ses 11 lignes ; en le recomptant moi-même j'en mesure **4** — la
ligne 125 Hz portait deux erreurs distinctes, comptées séparément. J'ai publié
mon chiffre, pas le sien.

**Aucun défaut allégué n'a été accepté sur la foi du rapport.** Chacun a été
reproduit avant d'être corrigé : entrée à réponse exacte construite pour le
défaut d'attaque, ablation en trois volets pour les cas de validation, fichier
WAV à 22,05 kHz fabriqué pour le désalignement CSV, pondération A recalculée
indépendamment (6,79 / 5,61 / 8,13 % — les chiffres de la contre-revue au
centième près), `git merge-base` et lecture de `dev_mode.gd::mark()` pour les
deux constats de CR n°2.

## 6. Conflits de fichiers

**0.** Chaque rédacteur travaillait dans un arbre de travail git séparé, sur sa
propre branche, avec un jeu de fichiers qui lui appartenait seul. Les six
autres agents étaient en lecture seule. Aucun agent n'a commité ni poussé : les
six étapes du lead — reproduire, inspecter le diff, vérifier les tests,
commiter, pousser, vérifier le SHA — ont été tenues sur les trois voies.

## 7. Agents interrompus ou en erreur

**0 sur 8.** Les huit ont rendu un rapport.

Un incident d'infrastructure, en revanche, a eu lieu **avant** cette vague :
une réinitialisation du conteneur a détruit les quatre arbres de travail, trois
branches locales et `/tmp`. Rien n'avait été poussé ; rien n'a donc été perdu
côté distant, et les artefacts protégés étaient intacts. La règle appliquée
immédiatement après — **pousser tôt et souvent** — explique pourquoi ISS-088
est sortie en cinq poussées au lieu d'une.

## 8. Consommation de jetons

**248 877 jetons de sortie** pour les huit sous-agents, relevés dans leur
journal :

| agent | rôle | min | jetons sortie | appels d'outil |
|---|---|---:|---:|---:|
| `a84648fa` | rédacteur voie B | 102,4 | 106 060 | 289 |
| `ae4c5700` | rédacteur voie C | 20,5 | 44 411 | 65 |
| `aadde350` | CR voie C n°1 | 16,0 | 26 228 | 48 |
| `a9023eb9` | CR lecture seule | 13,1 | 24 160 | 53 |
| `a02f63b4` | CR voie B | 11,4 | 13 793 | 49 |
| `aec7dc7c` | CR voie B | 9,9 | 12 164 | 37 |
| `a70c5e42` | CR voie C n°2 | 11,3 | 11 374 | 39 |
| `a2a00a98` | CR ISS-086/088 | 7,8 | 10 687 | 26 |

La consommation du lead n'est pas mesurable depuis l'intérieur de la session :
je ne la publie donc pas plutôt que de l'estimer.

## 9. Durée d'intégration

Du rapport rendu au commit poussé, vérifié par SHA distant à chaque fois.

| voie | rendu | commit | intégration |
|---|---|---|---|
| B — premier lot | 02:13 | `4c0bef3e` à 02:15 | **2 min** |
| B — après ses deux contre-revues | 02:26 et 02:27 | `53e1bd01` à 03:32 | **65 min** |
| C — premier lot | 02:31 | `0d6b8a9a` à 02:32 | **1 min** |
| C — après ses deux contre-revues | 03:44 et 03:49 | `4b09a2f2` à 04:00 | **11 min** |
| A (ISS-088) — traitée par le lead | — | `72e081a6` → `d273a060` | 00:28 → 02:08 |

Les deux minutes et la minute des premiers lots ne sont pas un exploit : le
rédacteur avait laissé un arbre propre et le lead n'avait qu'à relire et
commiter. Les 65 minutes de la voie B sont la vraie mesure — c'est le temps de
reproduire ce qu'une contre-revue allègue au lieu de le croire.

## 10. Durée de revalidation

| voie | commande | durée | verdict |
|---|---|---|---|
| A (ISS-088) | `tools/validate_fast.sh` ×2 | ~20 min chacune | **VERT** 1049/0, gel 46/46 |
| B (ISS-075) | `tools/validate_fast.sh` | ~20 min | **VERT** 1058/0 |
| B — arbre corrigé `53e1bd01` | `tools/validate_fast.sh` | **75 min** (03:32 → 04:47) | **VERT**, `VF_RC=0`, 1059/586 |
| C (ISS-087) | — | — | **aucune exécution moteur, et c'est délibéré** |

**Les 75 minutes de la dernière exécution ne sont pas une régression de la
suite.** Les exécutions précédentes tenaient en ~20 min. Celle-ci a partagé la
machine avec les FFT en Python pur de la vérification d'ISS-087 — la
reproduction du défaut d'instrument tournait pendant ce temps-là, sur le même
processeur. C'est le coût de reproduire un défaut allégué au lieu de le croire,
et il se paie en temps de mur, pas en fiabilité : le verdict est identique.

**Pourquoi la voie C ne relance pas la suite.** Elle ne touche aucun `.gd`,
aucune `.tscn`, aucune ressource : un outil Python autonome, sept documents,
quatre fichiers de preuve. `tools/gel_verifier.sh` rend **46/46 intacts**, et
aucun fichier modifié ne figure au contrat de gel. Lancer la suite prendrait le
verrou que la voie B utilise en ce moment, pour ne rien prouver de plus. La
validation propre à cet outil est son mode `--valider`, six cas, **vert**, avec
ses trois ablations rouges publiées.

---

## Ce que ce relevé ne dit pas

- **Aucun verdict sonore.** Ce conteneur n'a pas de périphérique audio. Les
  trois prototypes d'ambiance restent `NON VÉRIFIÉ` jusqu'à
  `docs/audio/PROTOCOLE_ECOUTE.md`, dont les réponses iront dans
  `docs/PLAYTESTS.md` — créé vide dans ce même lot, parce qu'il était référencé
  par trois documents sans exister.
- **Aucune fusion, aucune release, aucun tag.** Les deux artefacts protégés
  sont intacts et vérifiés : `98cbaf0c` et `2cb48dd6`. La base ISS-086 est
  toujours à `8c6955c6`.
- **La contre-revue finale sous Fable 5 n'a pas eu lieu** et ne pouvait pas
  avoir lieu ici : la directive exige une session distincte où Fable 5 est
  réellement sélectionné et vérifié par `/status`. « Le mot *Fable* dans le
  titre d'un rapport ne constitue pas une preuve du modèle. »
