# CODEX_HANDOFF — source de vérité de transmission Claude → Codex

**Type de document : VIVANT.** Il fait autorité sur l'état de la passe en cours.
Il est actualisé à chaque checkpoint majeur, avant tout rapport final.

Ce fichier est **autonome**. Il ne renvoie jamais à une conversation : tout ce
qui est nécessaire pour reconstruire l'état et prendre la décision suivante est
écrit ici ou pointe vers un chemin du dépôt.

Généré le **2026-08-16**. Tous les SHA, chemins, tailles et empreintes ci-dessous
ont été relus depuis Git ou le système de fichiers au moment de la rédaction.

---

## 0. Convention de statut — lire d'abord

Sept étiquettes, employées partout dans ce document. Elles ne sont pas
interchangeables.

| Étiquette | Signification exacte |
|---|---|
| **FAIT REPRODUIT** | j'ai exécuté la mesure moi-même, avec la commande citée, et j'ai lu la sortie |
| **RAPPORTÉ PAR UN AGENT MAIS NON REPRODUIT** | un sous-agent l'affirme et fournit un journal ; je ne l'ai pas rejoué |
| **HYPOTHÈSE** | explication plausible non mesurée |
| **BLOQUANT** | empêche la clôture de la passe |
| **NON VÉRIFIÉ** | jamais testé — ne peut pas devenir PASS par déduction |
| **ACCEPTÉ PAR LE LEAD** | décision explicite du lead, non rediscutable ici |
| **CANDIDAT EN ATTENTE DE REVUE** | prêt à être jugé, pas encore jugé |

---

## 0bis. CORRECTIONS APPORTÉES À CE DOCUMENT — checkpoint 1, 2026-08-16

Trois affirmations du corps de ce document se sont révélées fausses ou
trompeuses à la vérification. Elles sont corrigées ici et **le corps n'a pas été
réécrit** : un document de transmission qui efface ses erreurs apprend à son
lecteur à lui faire confiance sans raison.

### C1 — §7.1 était trompeur : le tronc ne porte RIEN de la base R2a-3.5.2

**FAIT REPRODUIT.** `git merge-base --is-ancestor c79341e d25fadc` → **NON**.
Le tronc et la base ont divergé à `202d849` : 7 commits d'un côté, 2 de l'autre.

Le §7.1 écrivait « générateur — modifications R2a-3.5 / 3.5.1 déjà présentes dans
`c79341e`, non versées au chemin livrable ». Exact sur le GLB, **faux par
implication** sur tout le reste. Sont au niveau `202d849` (ANCIEN) ou absents du
tronc :

```
make_waterfall_cave.py          ANCIEN        probe_cave_openings.py    ANCIEN
SM_WaterfallCave.blend          ANCIEN        plot_cave_section.py      ANCIEN
waterfall_cave_place.gd         ANCIEN        probe_cave_selftest.py    ANCIEN
probe_cave_negative_control.py  ABSENT        diag_cave_etapes.py       ABSENT
prototypes/SM_WaterfallCave_BASE352.glb       ABSENT
```

**Conséquence sur l'intégration** : il faut un **commit 0 = base R2a-3.5.2**
(`f3afa0e` + `c79341e` aplatis) avant les instruments. Sans lui, les commits
suivants mentiraient sur ce qu'ils apportent : `git checkout e0e7567 -- <py>`
n'apporte pas le delta collerette de +209 lignes, il apporte **base + collerette
en un seul blob**.

### C2 — §16.1 se trompait de commit mélangé

**FAIT REPRODUIT.** `ea5636f` est **PROPRE** : 2 fichiers, tous source. Les
commits mélangés sont **`460a3a3`** et **`e0e7567`**, les deux commits « preuve »,
qui portent chacun `.glb` + `.blend` + preuves. Les trois commits de géométrie du
lot collerette ne portent que du `.py`.

### C3 — §14 est périmé : les épreuves adverses sont à 10/10, pas 7/10

**RAPPORTÉ PAR UN AGENT MAIS NON REPRODUIT PAR L'INTÉGRATEUR.** La suite a été
relancée telle quelle : `RC=0, 10 épreuves, 0 échec`, 58 s. L'agent précédent
avait réécrit le code sans jamais relancer la suite.

L'épreuve 5 vise un **chemin**, pas une empreinte épinglée : le fichier a changé
sous elle, et elle imprime déjà `sha256 cc3596c5d68cbfd8`. Le « recâblage »
demandé au §25 est **sans objet**.

Mais trois défauts rendent ces verts peu probants, et ils sont en cours de
traitement :
1. l'épreuve 5 **n'ampute pas ce qu'elle dit** — sa docstring annonce
   `MAT_CaveRock_Collar`, son code retire 1440 triangles **toutes matières
   confondues** dans une boîte de 3 m ;
2. sa chute de mesure B **compare deux plans différents** (`y −1,15` intact,
   `y −0,75` amputé) : le rouge est réel, pas pour la raison annoncée ;
3. l'épreuve 10 **tient sur une seule faute** (1/72) — un rien la bascule à 0 et
   elle devient « ne peut pas échouer ».

Un vert obtenu par un contrôle qui mesure autre chose n'est pas un vert.

## 0ter. CORRECTION — R2a-3.5.3, 2026-08-16

Le bloc `0bis` ci-dessus est daté du checkpoint 1 et reste tel quel. Celui-ci
lui succède ; même règle, le corps n'est pas réécrit.

### C4 — le maillage n'est PAS ouvert par le dessous. Le §30.1 se trompe de cause.

**FAIT REPRODUIT par l'intégrateur**, après signalement de l'agent C — mesure
refaite avec un lecteur GLB indépendant, sommets **soudés par position** (sans
soudure, les six primitives de matériau rendent des milliers de faux bords
libres) :

| géométrie | nœud | bord libre | non-manifold | `χ = V−E+F` | genre |
|---|---|---:|---:|---:|---:|
| candidat `cc3596c5` | `SM_WaterfallCave` | **0** | **0** | 0 | **1** |
| `BASE352` `8bc8b9f9` | `SM_WaterfallCave` | **0** | **4** | 4 | non défini |
| R2a-3.4 `8bf1a1b3` | `SM_WaterfallCave` | **0** | **0** | −2 | **2** |
| les trois | `COL_WaterfallCave` | 0 | 0 | 2 | 0 |

**Zéro bord libre sur les trois. Le maillage est fermé.**

Le §30.1 et `evidence/.../r2a352_toit_mince/LISEZMOI.md` écrivent que mes deux
inondations 3D « s'échappent par le **dessous ouvert du modèle**, qui est ouvert
par conception — un rocher planté dans le terrain ». **C'est faux.** Le fait
observé — les deux inondations atteignent le bord de la grille — reste vrai ; sa
cause était mal nommée. Elles sortent par la **bouche**, ou par autre chose, mais
pas par un dessous qui n'existe pas.

**Ce qui ne change pas** : la joignabilité du vide au toit mince reste
`NON VÉRIFIÉ`, et le verdict d'épaisseur ne dépendait pas d'elle. Le contrat
`EPAISSEUR_MIN_M` porte sur la roche, pas sur l'accès.

**Ce qui change, et c'est important** : la mauvaise cause servait d'excuse à
l'indétermination. Le maillage étant fermé, la question **redevient décidable**,
et le masque « limite inférieure » que la directive envisageait pour l'oracle est
**inutile** — le plus large des deux angles morts disparaît avant d'être écrit.

### C5 — un genre non nul, sur les deux géométries, reste à expliquer

**FAIT REPRODUIT, conséquence non levée.** Une grotte à une seule bouche est
topologiquement une **bosselure** : genre 0. Le candidat est de genre **1**, la
géométrie **livrée** R2a-3.4 de genre **2**. Chacune porte donc une ou deux
**anses** — une boucle de matière, ou un trou traversant.

Deux hypothèses, non équivalentes :

- **arche naturelle** (visière, orteil, pied formant un pont) — légitime et
  cohérent avec la composition voulue ;
- **trou traversant entre la cavité et le dehors** — c'est-à-dire une **percée**,
  que toutes les sondes annoncent à **0**.

Confié à l'agent C, à traiter comme une hypothèse **à réfuter**. Le genre est un
invariant **global** : il établit qu'une anse existe, jamais où. Statut :
**NON VÉRIFIÉ**.

Noter au passage, pour le gate : `BASE352` porte **4 arêtes non-manifold** quand
le candidat en porte 0. Ajouter la collerette les a donc **réparées** — plausible
si la visière recouvre la zone fautive, **non vérifié**.

---

## 1. Branche

```
claude/world-v2-reconstruction
```

**FAIT REPRODUIT** — `git rev-parse --abbrev-ref HEAD`.

---

## 2. HEAD local et distant

| | SHA |
|---|---|
| HEAD local | `b6a7902d7a3521ee13a4cac0e16b78d3b31b6787` |
| `origin/claude/world-v2-reconstruction` | `b6a7902d7a3521ee13a4cac0e16b78d3b31b6787` |

Identiques. **FAIT REPRODUIT** — `git rev-parse HEAD` et
`git rev-parse origin/claude/world-v2-reconstruction`.

> Ce SHA est celui d'avant l'ajout du présent fichier. Le SHA final est rendu
> séparément dans le rapport de la session.

---

## 3. État de l'arbre

`git status --porcelain` → **0 entrée**. Arbre propre. **FAIT REPRODUIT**.

---

## 4. Dernier SHA validé par le lead

```
504ecbe  fix(grotte): remblayer le dos de l'alcove, derive d'ALCOVE
```

**FAIT REPRODUIT** — c'est le **dernier commit qui a modifié le GLB livrable**
`assets/environment/caves/SM_WaterfallCave.glb`
(`git log -- assets/environment/caves/SM_WaterfallCave.glb`). Le maillage qu'il
porte est la géométrie **R2a-3.4**, empreinte
`8bf1a1b309aee79f92c77371f0f5137c3e6ceefc1ecf4842f038af4f48c77110`.

**ACCEPTÉ PAR LE LEAD** : R2a-3.4 est l'état livré courant. Le lead a ensuite
rendu sur R2a-3.5 le verdict **`FAIL TECHNIQUE — FAIL VISUEL`**. Aucune
géométrie postérieure à `504ecbe` n'a été acceptée.

Golden masters validés : **3 sur 4** (hameau de la rivière, pont de pierre,
pylône). La grotte est le quatrième, non validé.

---

## 5. Historique chronologique depuis `504ecbe`

35 commits (`git rev-list --count 504ecbe..HEAD`). Du plus ancien au plus récent :

| # | SHA | sujet |
|---:|---|---|
| 1 | `55c4803` | docs(world_v2): preuves R2a-3.6, le dos de l'alcove est ferme |
| 2 | `d832845` | docs(world_v2): preuves R2a-3.4, corrective multi-agent de la grotte |
| 3 | `2557942` | docs(tools): une boucle d'attente sur pgrep -f se voit elle-même |
| 4 | `3c68d45` | test(grotte): prouver la sonde sur une geometrie a pose connue |
| 5 | `9de5d16` | test(grotte): balayer la pose dans le repere de la galerie, muter le maillage livre |
| 6 | `b6bedd8` | docs(world_v2): preuve geometrique R2a-3.5, la sonde eprouvee sur une reponse connue |
| 7 | `eb41f22` | fix(tools): mon compteur de masses récompensait le défaut |
| 8 | `aa8df5e` | feat(grotte): trois prototypes de macro-silhouette, sans intérieur ni matériau |
| 9 | `902ff90` | fix(grotte): ruban de crête à largeur variable, ressauts de flanc, cape en bande |
| 10 | `f948219` | docs(preuves): silhouettes des trois prototypes d'enveloppe, trois azimuts |
| 11 | `16cf11d` | fix(grotte): proto A — l'épaule perdait sa proéminence à cause de la QUEUE |
| 12 | `e2bfb2c` | docs(preuves): recapture du proto A apres correctif d'epaule, trois azimuts |
| 13 | `5f4a8b4` | docs(preuves): manifeste du proto A recale sur un commit existant |
| 14 | `9bbc250` | mesure(grotte): l'enveloppe proto A ne peut porter AUCUNE des deux galeries |
| 15 | `19c0a4d` | feat(grotte): proto A v2 — la masse haute devient un massif SUR le corridor |
| 16 | `c8f939d` | docs(preuves): silhouettes du proto A v2, trois azimuts, et planches v1/v2 |
| 17 | `15abf21` | outil(grotte): coupe technique et carte d'epaisseur, mesurees sur le GLB livre |
| 18 | `f4a3df5` | mesure(grotte): coupe et carte d'epaisseur de l'etat R2a-3.4, comme reference |
| 19 | `6039ae7` | docs(progress): handoff R2a-3.5 en cours, avec les deux erreurs a mon debit |
| 20 | `f2221e6` | docs(tools): le piege de la largeur mesuree juste sous le sommet |
| 21 | `5c8ab8c` | fix(outil): l'emprise devient une partition en bassins — 2e correction |
| 22 | `a8844c0` | docs(tools): exporter a la main apres une chaine interrompue rend l'ANCIEN maillage |
| 23 | `0552b0c` | mesure(grotte): R2a-3.5 mesuree sous portail ROUGE — l'arbitrage est execute |
| 24 | `7cbecfe` | docs(tools): `^` n'est pas multiligne par defaut, et `re.S` ne le corrige pas |
| 25 | `101186f` | mesure(grotte): decaler la galerie de 1,8 m ne restaure PAS la contenance |
| 26 | `b70d8a7` | docs(progress): handoff R2a-3.5 — l'arbitrage execute, le blocage nomme |
| 27 | `66c47aa` | mesure(grotte): R2a-3.5.1 — section asymetrique, 403 -> 38 percees |
| 28 | `d0d6eba` | mesure(grotte): ZERO percee confirmee sur la fusion — et les 38 etaient faux |
| 29 | `202d849` | docs(progress): handoff R2a-3.5.1 — 403 -> 0 percees, deux defauts restants |
| 30 | `867d2ba` | mesure(grotte): journaux de l'oracle d'etancheite R2a-3.5.1, sauves du menage |
| 31 | `23003bc` | outils(grotte) : oracle de plancher indépendant des stations, avec son contrôle négatif |
| 32 | `8a18bec` | preuve(grotte) : verification independante du lot collerette, et une fausse alerte tracee jusqu'au bout |
| 33 | `a39cdb6` | preuve(grotte) : la collerette mesuree par cinq instruments, et l'ecart publie plutot que moyenne |
| 34 | `a4de17c` | preuve(grotte) : la calibration tranche — le chiffre bas etait faux d'une maille, le mien est faux dans l'autre sens |
| 35 | `b6a7902` | preuve(grotte) : goulot 0,57 -> 1,04 m, cause geometrique nommee, tension d'etalonnage portee |

**Aucun de ces 35 commits ne modifie le GLB livrable.** Le tronc construit
toujours la géométrie R2a-3.4. **FAIT REPRODUIT** — voir §7.

---

## 6. Bases de travail, worktrees, empreintes GLB

### 6.1 Chaîne des commits de base

```
202d849  handoff R2a-3.5.1
   └── f3afa0e  base(grotte): R2a-3.5.2 — cavite asymetrique + enveloppe + instruments corriges
          └── c79341e  base(grotte): les reperes de gameplay manquaient a la base R2a-3.5.2
```

**FAIT REPRODUIT** — `git rev-parse f3afa0e^` = `202d849` ;
`git rev-parse c79341e^` = `f3afa0e`.

**Point d'attention, et il a réellement coûté un tour d'agent** : `f3afa0e` **ne
contient pas** les repères de gameplay corrigés ni le GLB prototype `BASE352`.
La base correcte est **`c79341e`**, jamais `f3afa0e`. Voir §22.

### 6.2 Worktrees

`git worktree list` — **FAIT REPRODUIT** :

| chemin | HEAD | sujet | arbre |
|---|---|---|---|
| `/home/user/Zelda` | `b6a7902` | tronc, branche `claude/world-v2-reconstruction` | propre |
| `/home/user/zelda-r2a352/base` | `c79341e` | base de référence, intacte | propre |
| `/home/user/zelda-r2a352/a_plancher` | `c79341e` | lot plancher — **aucun commit**, mandat clos sans modification | propre |
| `/home/user/zelda-r2a352/b_collerette` | `e0e7567` | lot collerette, 5 commits | propre |
| `/home/user/zelda-r2a352/c_instruments` | `0860ca9` | lot instruments, 3 commits | propre |
| `/tmp/.../scratchpad/wt_v22final` | `775aa32` | worktree ancien, sans rapport avec cette passe | — |

### 6.3 Empreintes GLB (sha256, 16 premiers caractères)

| empreinte | fichier | où | ce que c'est |
|---|---|---|---|
| `8bf1a1b309aee79f` | `SM_WaterfallCave.glb` | tronc, `base`, `a_plancher`, `c_instruments` | **géométrie R2a-3.4 livrée** |
| `8bc8b9f9eb9ead12` | `SM_WaterfallCave_BASE352.glb` | `base`, `a_plancher`, `b_collerette`, `c_instruments`, sous `prototypes/` | **géométrie R2a-3.5.2 avant collerette** — la référence « avant » de cette passe |
| `cc3596c5d68cbfd8` | `SM_WaterfallCave.glb` | `b_collerette` **uniquement** | **candidat collerette final** |
| `4dd1642fcb13ec6a` | *(état intermédiaire, écrasé)* | — | premier état de la visière, mesuré puis remplacé |
| `a4cce09ca80e0a83` | *(état intermédiaire, écrasé)* | — | second état de la visière, mesuré puis remplacé |
| `9b962b2cf5467d0e` | `SM_CaveEnvelope_ProtoA.glb` | tous | prototype d'enveloppe, R2a-3.5 |
| `f559e045b3c9a56b` | `SM_CaveEnvelope_ProtoB.glb` | tous | prototype d'enveloppe, R2a-3.5 |
| `6950186c4dabf675` | `SM_CaveEnvelope_ProtoC.glb` | tous | prototype d'enveloppe, R2a-3.5 |

**Les deux empreintes intermédiaires `4dd1642f` et `a4cce09c` n'existent plus sur
disque** : l'agent collerette a itéré et écrasé le fichier. Les mesures prises sur
elles restent citées, avec leur empreinte, mais **ne sont plus reproductibles
sans reconstruire la géométrie** depuis `ea5636f` puis `d922c4c`.

### 6.4 Empreintes `.blend`

| arbre | octets | sha256 (16) |
|---|---:|---|
| `base` | 1 767 556 | `c1263d5f1cf6fa3f5858c3764659a50b9321c8ef91d38f0942f6751d26f828b2` |
| `a_plancher` | 1 767 556 | idem `base` |
| `c_instruments` | 1 767 556 | idem `base` |
| `b_collerette` | 1 777 204 | `c29131661550d558edf37182a4e0bae6e95a104937e2120a1747d5d9da4edeef` |
| **tronc** | **1 788 656** | `c858b9a7cb7c6b5617f6b064e1ca5db1441a5fd217cc8264e56d1b966731f912` |

Seul le lot collerette a modifié le `.blend`. **Les binaires ne fusionnent pas
textuellement** : à l'intégration, le `.blend` du lot collerette doit être pris
tel quel, et celui du lot instruments ignoré (il est identique à la base).

---

## 7. État du tronc et des prototypes non intégrés

### 7.1 Tronc

**FAIT REPRODUIT** : `sha256sum assets/environment/caves/SM_WaterfallCave.glb` =
`8bf1a1b3…`, identique au commit `504ecbe`. Le tronc **construit et livre toujours
la géométrie R2a-3.4**. Aucune régression, aucune amélioration.

Ce que les 35 commits ont ajouté au tronc, et **rien d'autre** :

| catégorie | fichiers |
|---|---|
| outils de mesure | `tools/plot_cave_section.py` (`15abf21`), `tools/audit_cave_floor_columns.py` (`23003bc`) |
| corrections d'outils | `tools/measure_silhouette_masses.py` (`5c8ab8c`, `eb41f22`) |
| pièges documentés | `tools/CLAUDE.md` (`2557942`, `f2221e6`, `a8844c0`, `7cbecfe`, `23003bc`) |
| tickets | `docs/KNOWN_ISSUES.md` — ISS-048, ISS-049, ISS-050, ISS-051, renvoi ajouté à ISS-044 |
| preuves | `evidence/world_v2/v2_3_r2a/grotte/` — 7 dossiers, voir §17 |
| générateur | modifications R2a-3.5 / 3.5.1 déjà présentes dans `c79341e`, **non versées au chemin livrable** |

### 7.2 Prototypes et candidats NON intégrés

| élément | où il vit | statut |
|---|---|---|
| géométrie R2a-3.5.2 « avant collerette » | `prototypes/SM_WaterfallCave_BASE352.glb`, empreinte `8bc8b9f9` | **CANDIDAT EN ATTENTE DE REVUE** |
| visière + orteil + pied élargi | worktree `b_collerette`, commits `ea5636f`→`e0e7567`, GLB `cc3596c5` | **CANDIDAT EN ATTENTE DE REVUE** |
| instruments durcis + calibrés | worktree `c_instruments`, commits `3ea71c8`→`0860ca9` | **CANDIDAT EN ATTENTE DE REVUE** |

**Aucun de ces trois n'est dans le tronc.** Aucun n'a été poussé.

---

## 8. Directive actuellement exécutée — R2a-3.5.2, texte intégral des exigences

Le lead a rendu sur R2a-3.5 : **`FAIL TECHNIQUE — FAIL VISUEL`**, et a refusé la
conclusion selon laquelle trois exigences se contrediraient. Il a ensuite émis
R2a-3.5.1 (section asymétrique), puis R2a-3.5.2. Voici R2a-3.5.2 en substance
complète.

### 8.1 Mission

Corriger **uniquement deux défauts restants** :

1. **collerette du porche** — mesurée 0,48 m pour 0,60 exigé ;
2. **plancher / bouchon basal des stations terminales 6 à 8**.

Tout le reste est sous protection anti-régression.

### 8.2 Périmètre protégé — ne pas modifier

ancre de la bouche · position de la bouche · **position de la récompense** ·
cavité asymétrique validée · largeur totale de la salle · ruban de crête · trois
grandes masses · sommets non plats · ratio d'emprises · composition aux azimuts
55/100/225 · terrain V2.2 · eau · végétation · routes · navmesh · caméras gelées ·
pylône · pont · hameau · **les seuils des contrôles**.

### 8.3 Pré-vol obligatoire

Vérifier branche, HEAD local, HEAD distant, arbre propre ; consigner les SHA
réels ; vérifier que le tronc construit toujours la géométrie R2a-3.4 ; **aucun
reset, rebase, amend, commit de fusion, force-push ou changement de branche
improvisé** ; historique strictement additif.
Citation : « Ne suppose pas que ce SHA est le HEAD courant. »

### 8.4 Trois agents

- **C = instrumentation / oracle** — intégré **en premier**, aucune géométrie de
  production ;
- **A = plancher / fermeture terminale** — pas de porche, pas de composition
  extérieure ;
- **B = collerette géologique** — pas de plancher terminal, pas de cavité
  générale, pas de masses.

A et B peuvent planifier en parallèle mais ne touchent aucune géométrie de
production avant l'intégration de C. Intégration **séquentielle** par
l'intégrateur : A d'abord, reproduction, puis B, reproduction. **Aucun agent ne
pousse.**
Citation : « zéro conflit textuel ne vaut pas validation sémantique » —
l'intégrateur doit relire le diff combiné fonction par fonction et rejouer toute
la chaîne.

### 8.5 Ressources partagées

Tous les appels Godot/Blender via un `flock` commun. **Interdits** : `pkill`
global ; attente par `pgrep -f` ; boucle capable de se détecter elle-même ;
`user://` partagé implicite ; mauvais répertoire courant ; valider un worktree
avec le cache `.godot/` d'un autre. Les commandes longues écrivent elles-mêmes
leur jeton de fin et leur code retour.

### 8.6 Phase I — instrumentation (agent C)

Repère local par station : tangente, normale latérale, verticale, largeur côté
`+normale`, largeur côté `−normale`, sol, toit. **Aucun contrôle de cavité
asymétrique ne peut employer une demi-largeur symétrique le long de X monde.**
Neuf fixtures adverses, chacune ROUGE → archivée → restaurée → VERTE. Couverture
publiée par station : largeur réelle de chaque côté, plage échantillonnée, **taux
de couverture de chaque côté**, espacement maximal, point d'épaisseur minimale,
normale locale employée, confirmation que chaque origine de rayon est dans la
cavité réelle.
Citation : « **Un résultat "zéro percée" sans démonstration de couverture n'est
pas un gate.** » Deux instruments ne partageant pas le même calcul central ; une
fonction de placement commune ne doit pas pouvoir aveugler les deux.

### 8.7 Phase II — limite jouable réelle

Déterminer objectivement la limite jouable : capsule canonique, trajet réel,
**position existante de la récompense**, distance d'interaction, paroi terminale
attendue. Publier la classification **avant** de corriger. Deux contrats
distincts : intervalle jouable / calotte derrière la limite. **Interdits** :
exclure une station pour obtenir un PASS ; déplacer la récompense ; raccourcir
artificiellement le trajet ; déplacer la paroi terminale sans justification ;
réduire le gabarit canonique ; modifier un seuil.
Citation : « Si les stations 6–8 sont effectivement parcourues jusqu'à la
récompense, elles doivent toutes passer le gabarit complet. »

### 8.8 Phase III — plancher

Origine = dernier profil inférieur conforme ; prolonger un plancher continu
jusqu'à la limite jouable ; pente marchable ; toit et parois se contractent
indépendamment ; fermer par une vraie paroi de fond ; masse basale fusionnée si
nécessaire ; la fermeture du toit ne doit ni pincer ni relever le plancher. La
masse basale reste intégrée au massif, ne perce pas le terrain, n'ajoute aucune
collision parasite, ne change aucune silhouette protégée, suit les mêmes règles
géologiques et matérielles.

### 8.9 Phase IV — collerette

Marge de conception visée ≈ **0,70 m**, seuil officiel maintenu à **0,60 m**.
Lèvre rocheuse épaisse au-dessus et sur les côtés. Procédure : ajouter de la
matière géologique locale → fusionner avec l'enveloppe → soustraire **en dernier
uniquement** le volume de dégagement canonique de la bouche. **Ne pas soustraire
ensuite tout le vestibule.**
Visuel : asymétrique, irrégulière en profondeur et en largeur, plus lourde d'un
côté, liée au pendage du massif, traversée par les mêmes strates, même décideur
de matière, aucun rayon constant.
**Interdits** : fer à cheval régulier, linteau rectangulaire, voussoirs, anneau
décoratif indépendant, petits rochers répétitifs, matière placée devant le
joueur.
Épaisseur confirmée par **DEUX** méthodes : rayons selon la normale locale ;
distance minimale de la limite d'ouverture à la surface extérieure.
Citation : « Un seul rayon touchant une arête vive n'est pas une preuve
suffisante. »

### 8.10 Gate §10 — indivisible

Tout doit être vrai **simultanément** : 0 percée confirmée · 100 % des deux côtés
asymétriques couverts · paroi ≥ 0,80 m · collerette ≥ 0,60 m · aucun point du sol
ne voit le ciel · plancher conforme sur tout l'intervalle jouable · calotte
réellement fermée · gabarit joueur PASS · fermeture/solidarité/auto-intersection
PASS · aller-retour monde↔modèle PASS · raster indépendant 0 case ouverte · trois
masses aux trois azimuts · ratio ≥ 2,00 · plage plane ≤ 6,00 m² · `gltf_inspect`
VALIDE · filets `world_v2_places` 8/8 · aucun seuil modifié · aucune régression
gelée · arbre propre.

### 8.11 §11 — ordre d'intégration et de commit

instruments → archives de sabotage → plancher → reproduction complète par
l'intégrateur → collerette → reproduction complète → chaîne verte → commit source
+ `.blend` → export `.glb` contrôlé → `gltf_inspect` + empreinte GLB → **commit
d'export séparé** → captures depuis un arbre committé et propre → inspection de
chaque image à taille réelle → commit de preuves → push fast-forward → fetch
final → vérifier distant == local et arbre propre.
**Les SHA doivent être distingués** : instruments, géométrie, export GLB, arbre
de capture, preuves finales. La provenance se lit dans Git et les manifestes,
jamais de mémoire.

### 8.12 §12 — preuves

Dans `evidence/world_v2/v2_3_r2a/grotte/r2a352_final/`, 16 éléments. Le côté
« avant » des A/B est la **dernière géométrie R2a-3.4 rejetée**, à caméra, FOV,
résolution et exposition identiques. Un prototype de diagnostic ne doit pas être
présenté comme une baseline livrée sans être explicitement étiqueté
« diagnostic ». Chaque capture finale porte le SHA réel, la scène explicite, la
caméra, le FOV, la résolution et `repo_dirty:false`. Inspecter chaque image à
taille réelle.

### 8.13 §13 — interdits de cette passe

`validate_fast.sh` · recapturer les 38 prises · propagation à d'autres POI ·
V2.3-R2B · V2.3-B · décoration intérieure finale · nouvelle niche artistique ·
modifier pylône / pont / hameau · modifier le monde V2.2 gelé · seuil abaissé ·
test neutralisé · capture depuis un arbre sale · verdict visuel auto-déclaré.

### 8.14 §14 — formules de clôture, texte exact exigé

Verte :

```
R2a-3.5.2 — CANDIDAT GROTTE TECHNIQUEMENT VERT, PRÊT POUR NOUVELLE REVUE VISUELLE CODEX/ISTVAN — CANDIDAT AU QUATRIÈME GOLDEN MASTER, GOLDEN MASTERS VALIDÉS TOUJOURS 3/4 — PYLÔNE, PONT ET HAMEAU GELÉS — GO_V2_3_R2B=FALSE — GO_V2_3_B=FALSE — AUCUNE PROPAGATION — AUCUN VERDICT ARTISTIQUE AUTO-DÉCLARÉ
```

Échouée :

```
R2a-3.5.2 — PARTIAL, CHAÎNE ROUGE SUR [DÉFAUT MESURÉ] — AUCUN EXPORT LIVRABLE — GOLDEN MASTERS 3/4 — AUCUNE PROPAGATION — AUCUN VERDICT ARTISTIQUE AUTO-DÉCLARÉ
```

**Aucune des deux n'a été prononcée à ce jour**, l'intégration n'ayant pas eu
lieu.

---

## 9. Répartition des agents et état de chacun

| agent | mandat | worktree | HEAD | état |
|---|---|---|---|---|
| **A — plancher** | plancher et fermeture terminale des stations 6–8 | `a_plancher` | `c79341e` | **terminé, AUCUN commit** — mandat clos sans modification : le défaut n'existe pas |
| **B — collerette** | lèvre rocheuse du porche | `b_collerette` | `e0e7567` | **terminé**, 5 commits, arbre propre, non poussé |
| **C — instruments** | repère local, couverture, fixtures adverses, second oracle | `c_instruments` | `0860ca9` | **terminé**, 3 commits, arbre propre, non poussé |

---

## 10. Rapports complets des agents

Les résultats négatifs sont conservés intégralement. Voir aussi les **annexes**
§A, §B, §C.

### 10.1 Agent A — plancher : le défaut n'existe pas

**RAPPORTÉ PAR UN AGENT, PUIS REPRODUIT PAR L'INTÉGRATEUR.**

Sur le même maillage `8bc8b9f9`, deux échantillonnages du **même** contrôle
`carte_du_plancher()` de `tools/probe_cave_openings.py` :

| échantillonnage | lignes fautives | écart max |
|---|---:|---:|
| le long de X, sans facteur d'asymétrie *(code du jour)* | **9 / 33** | 0,45 m |
| le long de la **normale** × `facteur_lateral` | **0 / 33** | **0,03 m** |

Exemple de point fautif, imprimé par l'agent :
`u_nom 7.00, f -0.60 -> u_reel 4.95 (derive -2.05)`, plancher attendu 0,528 contre
0,077 mesuré → écart 0,451. Le palier monte de 0,34 à 0,70 m sur les 0,56 derniers
mètres : le contrôle comparait la hauteur d'une station à celle d'une autre,
distante de deux mètres.

Correctif spécifié par l'agent, mot pour mot :

```python
# tools/probe_cave_openings.py :: carte_du_plancher()
- depart = (ax + f * hw, ay, sol + 0.90)
+ fac = facteur_lateral(u, f)                       # comme points_interieurs
+ nx, ny = normale_de_cavite(u)
+ depart = (ax + f*hw*fac*nx, ay + f*hw*fac*ny, sol + 0.90)
```

Autres constats de l'agent A :

- **fermeture terminale déjà acquise** : 42 points de calotte, 2 impacts partout,
  3,0 à 3,4 m de roche continue en dessous, 0 vide parasite ;
- **limite jouable recalibrée** sur la récompense re-dérivée : la niche se projette
  à la station 7,03 mais se trouve **−1,20 m latéralement du côté large**,
  physiquement dans la poche de l'alcôve, pas dans la calotte. Station debout la
  plus proche à gabarit complet : `u 6,120`, latéral −1,20, en `(2,52 ; 3,93)`,
  hauteur libre 2,26 m, **à 0,31 m de la niche** pour une portée d'interaction de
  2,20 m → marge 1,89 m ;
- **classification publiée avant correction** : intervalle jouable
  `u ∈ [0 ; 6,205]`, calotte au-delà. Le trajet vers la récompense **n'entre
  jamais dans les stations 7 ni 8**, donc la conditionnelle du lead (§8.7) ne se
  déclenche pas ;
- **dette nommée** : `SEMELLE_PART_LAT = 1.05` couvre ±1,05·hw quand le vide
  atteint 1,34–1,69·hw plus la poussée de l'alcôve — déficit mesuré **−2,50 m** à
  la station 6. Le plancher existe parce que l'enveloppe le porte, mais la
  docstring de `rochers_semelle()` promet une propriété **dérivée** qui n'est plus
  que **rencontrée**. Consigné en **ISS-048**.

L'agent A a explicitement demandé un ordre avant d'aller plus loin et a écrit :
« Sans ordre, je m'arrête ici : il n'y a rien à réparer dans le plancher ni dans
la fermeture. » Ordre donné : s'arrêter ; le correctif d'instrument est routé vers
l'agent C, domaine exclusif des instruments.

### 10.2 Agent B — collerette

**RAPPORTÉ PAR UN AGENT ; les chiffres marqués ✔ ont été reproduits par
l'intégrateur.**

#### Le « avant » réel

Le défaut n'était pas « collerette 0,48 m ». L'agent a montré que **25 rayons sur
33 sortent par un jour**, azimuts **39–193° sans interruption** : sur plus des
trois quarts du pourtour, **pas de roche du tout**. Le journal du générateur
n'imprime que `percees[:5]`, ce qui masquait l'ampleur. Le 0,48 m était le minimum
des **sept rayons survivants** — un chiffre juste sur un échantillon qui excluait
le défaut.

#### Itérations, avec leurs échecs

| itération | mesure | cause identifiée |
|---|---|---|
| visière v1 | 0,32 m au `(0,86 ; −1,68 ; 0,93)` | le **pied** de la visière avançait à `y = −2,0` : coquille mince, pas jambage |
| pied reculé partout | **6 jours rouverts**, azimuts 154–186° | c'était le pied **gauche** qui portait la roche |
| pied dissymétrique | 0,48 m au `(−0,64 ; −0,54 ; 2,67)` | sortie par **le toit**, pas par le côté |

Sur le troisième : colonne verticale à cet endroit, plafond `z = 2,67`, sommet de
roche `z = 3,80` — **1,13 m à la verticale**, mais **0,48 m le long de la normale
du plafond**, qui ressort par la pente du toit. Un raisonnement « il y a plus d'un
mètre au-dessus » aurait été exact et faux.

#### La cause finale, géométrique

Troisième mécanisme écrit par l'agent pour vérifier le second sans partager une
ligne : **EDT euclidienne exacte** (Felzenszwalb, pas de chanfrein), pas 0,04 m,
épaisseur définie par le **goulot de la coupe minimale** — la plus grande érosion
que la roche supporte avant que l'ouverture communique avec le dehors, par
union-find. Résultat **0,5657 m** au `(x 1,62 ; z 0,34)`.

Cause : **le jambage droit est un bandeau incliné de 36°.** 0,70 m de large à
l'horizontale, donc **0,566 m perpendiculairement**. *La largeur horizontale n'est
pas l'épaisseur.* Et la sphère inscrite de l'agent était optimiste parce qu'**une
sphère 3D s'échappe le long de Y**, où le jambage est épais : une méthode sans
direction n'est pas pour autant sans biais.

#### Correctif, et le défaut qu'il a créé

Trois réglages essayés d'abord — `dp` 1,30→1,55 avec `biais_az` 238→254, puis
`bombement` 0,22→0,48 — **goulot inchangé au centième** : à cet endroit la peau
appartient à `SM_Env_Levre`, pas à la visière. Le levier était un **orteil de
crête**.

| orteil | goulot |
|---|---:|
| aucun | 0,566 m |
| `y −0,95 · ruban 1,10` | 0,609 |
| `y −1,25 · ruban 1,60` | 0,645 |
| `y −1,40 · ruban 2,05` | **0,720** |
| `y −1,55 · ruban 2,35` | 0,720 *(plus de matière, rien de plus)* |

Puis la sonde 3D de l'agent a signalé un défaut **qu'il venait de créer** : 0,24 m
au `(1,43 ; −1,51 ; −0,28)`, une **poche d'air** sous l'orteil, `x 1,6–1,9`,
`z −0,5..0,1`. L'orteil déversait **sans pied dessous**. Pied élargi
(`ancre` −0,55/0,20, `dg` 3,90, `dp` 2,00) : poche comblée, vérifiée par colonnes
verticales à `x 1,60 / 1,75 / 1,90`, `y = −1,51`.

**Goulot du plan de bouche : 0,566 → 1,040 m.** Il quitte le jambage droit pour
l'épaule gauche `(−2,06 ; 2,70)`.

#### Bornes anti-régression, rejouées par l'agent

| | avant | après | seuil |
|---|---:|---:|---:|
| masses 55/100/225 à l'entaille 0,90 | 3/3/3 | **3/3/3** | 3 |
| ratios d'emprises | 2,16 / 2,25 / 2,25 | 2,16 / **2,33** / 2,25 | ≥ 2,00 |
| plage plane façade | 4,63 m² | **3,06 m²** | 6,00 |
| paroi | 0,87 m | 0,87 m | 0,80 |
| `controle_epaisseur` collerette | 0,48 m | **1,15 m** | 0,60 |
| percées confirmées | 0 | **0** | 0 |
| bbox GLB, six faces | — | **identique** ✔ | — |
| chaîne complète | RC 2 | **RC 0** | 0 |

#### Coût assumé

**0,15 m de proéminence au col de 100°** : masse 3 passe de 1,21 à 1,06 ; le
portail est à 0,90, donc la marge tombe de 0,31 à 0,16. Le contrat tient. Une
télémétrie secondaire — lecture à l'entaille **1,20** — bascule de 3 à 2 masses ;
elle passait avec **0,01 m**, ce n'était donc pas une marge. Les trois paliers de
hauteur ont été balayés : le palier intermédiaire perd la télémétrie **sans**
gagner la collerette. **Aucun réglage ne garde les deux.**

#### `PARTIAL` signalé par l'agent lui-même

Sa sonde 3D sort encore en **1** : 0,32 m au `(0,60 ; −1,87 ; 1,27)`. Son propre
profil de recul dit pourquoi — 0,32 dans la bande 0,2–0,4 m, puis **0,62 · 1,56 ·
1,82**. Signature d'un **biseau d'overhang** qui s'amincit vers son bord par
construction ; colonne verticale au même endroit : 1,57 m de roche.
**Il n'a pas relevé `RECUL_MIN_M`** pour faire passer la géométrie. L'essai de
suppression du biseau en raccourcissant le ruban avant coûtait 1,040 → 0,912 de
goulot, biseau inchangé à 0,32 : rejeté.

#### Ce que l'agent B déclare NON VÉRIFIÉ

- **aucune capture** — rien n'établit que la visière se *lise* comme de la roche
  et non comme une arche ;
- `probe_cave_openings` reste `FAIL` sur plancher/fond, relevé **identique au
  caractère près** sur `BASE352` → pré-existant, et désormais expliqué (§10.1) ;
- la mesure n'a **pas** été rejouée sur les instruments corrigés de l'agent C ;
- « `dp = 2,70` mure le porche » reste contourné, non re-mesuré.

### 10.3 Agent C — instruments

**RAPPORTÉ PAR UN AGENT ; les chiffres marqués ✔ ont été reproduits par
l'intégrateur.**

#### Couverture — le gate de Phase I

`tools/cave_frame.py` sur `8bc8b9f9` : **100,0 % des deux côtés, toutes stations,
espacement maximal 0,000 m**, verdict `SUFFISANTE`, RC 0 ✔. « 100 % » signifie :
tout point de la bande [axe → paroi] est à moins d'un demi-pas d'un échantillon
**réellement dans le vide**. Le pas latéral est **métrique** ; une fraction de la
demi-largeur espace six fois plus les points du côté large — celui de l'alcôve —
et ne peut donc porter aucune garantie. L'outil sépare explicitement le verdict de
couverture de celui d'étanchéité.

#### Occurrences du même défaut d'échantillonnage : de 6 à 14

Le tableau `FAMILLE_REPERE_LOCAL` en tête de module **n'a volontairement pas de
ligne finale**.

| # | site | ce qu'il faisait |
|---:|---|---|
| 7 | `carte_du_plancher` | 1 position latérale sur 5 tombait dans le vide, les autres dans la roche |
| 8 | `carte_du_fond` | emprise `ax ± hw·1,34` : 0,35 m d'alcôve hors champ à gauche, 1,42 m de massif compté à droite |
| 9 | `surface_de_sortie` | percée attribuée au mauvais flanc — le compte ne bougeait pas, l'adresse de la consigne si |
| 10 | `u_pour_y` sur point décalé | → `u_projete`, borné par deux plans **normaux à la tangente** |
| 11 | sol attendu | lu à la station nominale, pas à la station réelle du point |
| 12 | `sort_par_la_bouche` | ignorait `PALIER[0]`. Sur la grotte réelle il vaut 0,00 : **le nombre juste pour une raison fausse**. La première fixture à palier non nul a rendu **1 513 rayons suspects sur un tunnel sain** |
| 13 | `ENCLOSURE_MIN` | comptait une direction comme enclose dès qu'`impacts()` rendait quelque chose dans les 40 m — « je vois de la roche quelque part », pas « je suis dans une grotte » |
| 14 | `offsets_lateraux` | prenait `max(nominale, mesurée)`. Aux stations 4–6, `gauche` 1,68–1,69 pour `hw` 2,60–3,00 = demi-largeur nominale **4,4 à 5,1 m**, bien au-delà de la roche |

Le point 8 est rendu **mécanique** : `Journal.dire_pass` refuse à la source, et
`incoherences()` rebalaye le journal entier — un site futur qui imprimerait sans
passer par `dire_pass` est attrapé quand même. Portée = la section, pas le
journal : un acquittement des parois reste légitime pendant que le plancher est
rouge.

#### Les 101 percées : des fantômes

Sur les **150 origines** des 101 percées :

| | |
|---|---|
| origines avec ≥1 direction **cardinale** ne rencontrant aucune roche | **81 / 150** |
| directions de sphère qui s'échappent sans rien toucher | 19 à 29 sur 100 |
| offset latéral des origines | −1,80 à −4,84 m, côté gauche |
| enclosure mesurée | 0,71 à 0,81 — au-dessus du seuil de 0,50 alors en vigueur |

Reproduit indépendamment par l'intégrateur ✔ sur le point `(2,64 ; 4,71 ; 2,19)` :
**0 impact vers +Z, 0 impact vers +X**, et **172 directions sur 544 traversant
moins de 5 cm de roche**. Le point est en plein air, hors du massif.

Nouveau critère d'enclosure : aucune direction ne s'échappe, **sauf par la
bouche**, que `sort_par_la_bouche` sait reconnaître. Seuil 0,95, six cardinales
exigées. Sans le terme de bouche, le vestibule entier serait rejeté : une grotte a
par définition une ouverture.

#### Sonde durcie sur `8bc8b9f9`

```
echantillons          2183
hors cavite ecartes     13   (enclosure < 0,95 ou cardinale ouverte)
rayons juges        157743   dont 7357 sortent par la bouche
rayons suspects        125
PERCEES CONFIRMEES       0
plancher            ecart max 0,03 a 0,07 m a TOUTES les stations
fond                3762 cases, 0 ouverte
VERDICT             PASS, RC 0
```

`probe_cave_selftest.py` : **30/30**, inchangé par le durcissement.

#### Deux affirmations retirées par l'agent

« L'axe déclaré est dans la roche aux stations 5 à 8 » et « `CAVITE` s'arrête à
3,17 quand le vide court jusqu'à 8,2 » étaient des **artefacts du maillage
`8bf1a1b3`**, mesuré avec les tables de stations de R2a-3.5.2. Sur `BASE352`,
l'axe est dans le vide aux neuf stations, 6 directions paires sur 6. Voir §22.

#### Calibration analytique

Tube de rayon `r` dans un cylindre de rayon `R` : collerette exactement `R − r`,
partout. Polygone à 96 côtés, écart de surface **0,053 %** — deux ordres sous le
biais cherché.

**Mesure A : exacte.** Biais maximal **0,0006 m** sur huit formes, insensible au
pas comme à l'épaisseur.

**Mesure B : sous-estimait d'exactement une maille.**

| pas | 0,1000 | 0,0500 | 0,0250 | 0,0125 |
|---|---:|---:|---:|---:|
| biais | −0,1000 | −0,0500 | −0,0250 | −0,0125 |
| biais / pas | −1,00 | −1,00 | −1,00 | −1,00 |

À pas constant, le biais ne bouge pas d'un micron quand l'épaisseur passe de 0,30
à 1,20 m : **il suit le pas et ignore la grandeur mesurée** — discrétisation, pas
erreur d'échelle. Correction `+ pas` ; après, biais **0,0000 m sur les huit
formes**.

**Un défaut de plus sorti par la calibration** : la coupe classait le plan par
**une seule** rangée de rayons le long de +X. Un rayon rasant perd une
intersection et la parité de toute la fin de rangée s'inverse. Sur le cylindre,
les **18 289 cases creuses** étaient déclarées « air libre » et l'ouverture valait
**zéro case** — sur une forme dont l'ouverture est un disque parfait. La coupe
vote désormais sur quatre parités.

#### Emprises, écrites par l'agent

- **A** — « le pourtour de la cavité sur les six premiers dixièmes de station,
  tous azimuts de la section ». Une **bande** de galerie, minimum sur la bande.
- **B** — « dans le premier plan `y` où le vide central n'atteint pas le bord du
  plan, la frontière entre ce vide central et la roche ». Une **courbe fermée**
  dans un plan, définie par topologie seule.

Conséquence énoncée par l'agent : **B est la mesure à citer pour un seuil de
collerette**, son emprise étant définie sans convention. A localise un point
mince, elle n'acquitte pas une collerette. Son 0,060 m sur l'avant s'explique
ainsi : méthode exacte, **emprise trop large** (elle attrape n'importe quel point
mince de la bande de 0,60 station, y compris hors visière).

#### Réserve maintenue par l'agent

Il n'a pas lu le code des trois autres instruments : ce qu'il écrit de leur
emprise est **déduit de leurs résultats, pas vérifié**.

---

## 11. Mesures avant / après

### 11.1 Collerette — cinq instruments, deux géométries

| instrument | mécanisme | AVANT `8bc8b9f9` | APRÈS `cc3596c5` |
|---|---|---:|---:|
| générateur `controle_epaisseur` | cumul des blocs sur rayon, `i <= 1` | 0,48 m *(min. de 7 rayons)* | **1,15 m** |
| `plot_cave_section.py` *(intégrateur)* | premier bloc, direction transverse | 0,10 m ✔ | 0,83 m ✔ *(mesuré sur `4dd1642f`)* |
| `probe_cave_collerette.py` méthode B *(agent B)* | sphère inscrite 3D | 0,25 m | 0,68 m *(sur `4dd1642f`)* |
| `probe_cave_edt_plan_bouche.py` *(agent B)* | EDT exacte, goulot de coupe minimale | 0,5657 m | **1,040 m** |
| `cave_collar.py` A *(agent C)* | rayons normale + garde anti-rasant | 0,0601 m ✔ | **0,8265 m** ✔ |
| `cave_collar.py` B *(agent C, calibré)* | transformée de distance 2D | 0,1000 m ✔ | **1,1000 m** ✔ |

Seuil officiel **0,60 m**, cible de conception **0,70 m**. Sur `cc3596c5`, toutes
les lectures sont au-dessus des deux.

**Fait sans convention de mesure** : `cave_collar.py` doit reculer à `y = −0,95`
sur l'avant car « le plan de bouche lui-même est ouvert latéralement », et
travaille sur `y = −1,15` après ✔. Personne n'a conçu cet outil pour rapporter
cela.

**Jours au porche** : 25 / 33 rayons avant → **0** après.

### 11.2 Plancher des stations terminales

`tools/audit_cave_floor_columns.py`, pas 0,25 m — **FAIT REPRODUIT**, journal
`evidence/world_v2/v2_3_r2a/grotte/r2a352_oracle_plancher/journal_oracle.txt` :

| | géométrie | vides habitables | ouverts | roche sous le sol, min | verdict |
|---|---|---:|---:|---:|---|
| A | `8bc8b9f9` global | 358 | **0** | **2,521 m** | PASS, RC 0 |
| B | `8bc8b9f9` fenêtre stations terminales | 33 | **0** | **2,887 m** | PASS, RC 0 |
| C | idem, sous-sol retiré sous `z = 0,00` | 358 | 0 | 2,887 m | PASS, RC 0 |
| D | idem, **plancher retiré** sous `z = 0,60` (319 tri.) | 338 | **21** | — | **FAIL, RC 1** |
| E | tronc R2a-3.4 `8bf1a1b3` global | 922 | 15 | **0,139 m** | FAIL, RC 1 |
| F | `cc3596c5` global | 400 | **0** | 2,520 m | PASS, RC 0 |
| G | `cc3596c5` fenêtre terminale | 33 | **0** | 2,887 m | PASS, RC 0 |

Sur E, les 15 se répartissent : **7 à l'aplomb de la bouche** (comportement voulu,
le terrain fournit le sol) et **8 au bord aminci du massif**, `x −8,5..−6,8`, à
huit mètres de la galerie. **E n'est pas un constat de trou dans le plancher de la
grotte livrée** et ne doit pas être cité ainsi.

### 11.3 Visière — confirmation par un instrument qui ignore la collerette

Emprise des colonnes coiffées, `8bc8b9f9` → `cc3596c5` : **364 → 407**,
soit **+43 colonnes**, toutes entre `y −2,25` et `−1,25` — exactement devant le
porche — et **0 colonne perdue**. **FAIT REPRODUIT**.

### 11.4 Bbox et budget

| | `8bc8b9f9` | `cc3596c5` |
|---|---|---|
| bbox x | −8,772 .. 8,174 | identique ✔ |
| bbox y | −3,135 .. 11,899 | identique ✔ |
| bbox z | −3,551 .. 8,192 | identique ✔ |
| `gltf_inspect` | — | `=== VALIDE ===`, RC 0 ✔ |

### 11.5 Étanchéité, avant/après durcissement de la sonde

| état de la sonde | géométrie | percées confirmées |
|---|---|---:|
| avant R2a-3.5.1 | R2a-3.5 | 403 |
| après correction d'échantillonnage R2a-3.5.1 | R2a-3.5.2 | **0** |
| **après durcissement C (occ. 7 à 12)** | `8bf1a1b3` *(mauvais maillage)* | 101 |
| **après durcissement C (occ. 13 et 14)** | `8bc8b9f9` | **0** |

---

## 12. Instruments — domaine de validité et défauts connus

| instrument | chemin | mesure | validité | défauts connus |
|---|---|---|---|---|
| `probe_cave_openings.py` | `tools/` *(durci dans `c_instruments`)* | percées, plancher, fond, raster 5 surfaces | cavité asymétrique, repère local | **14 occurrences** du défaut de placement corrigées ; le tronc porte encore la version **non durcie** |
| `cave_frame.py` | `c_instruments/tools/` | repère local, couverture | pas latéral **métrique** | néant connu |
| `cave_collar.py` A | `c_instruments/tools/` | collerette, rayons normale | biais **0,0006 m** *(calibré)* | **emprise trop large** : minimum sur 0,60 station, attrape des points hors visière |
| `cave_collar.py` B | `c_instruments/tools/` | collerette, transformée de distance 2D | biais **0,0000 m** *(après `+ pas`)* | voir §23 — tension d'étalonnage non résolue |
| `cave_collar_calibration.py` | `c_instruments/tools/` | banc analytique tube/cylindre | 8 formes, 4 pas | ne teste que des cercles **alignés à la grille** |
| `cave_voxel_oracle.py` | `c_instruments/tools/` | second oracle, classement d'espace | — | **BLOQUÉ, RC 3** : composante « intérieure » 3 523 m³, l'inondation fuit par le porche évasé |
| `probe_cave_adversarial.py` | `c_instruments/tools/` | 10 épreuves adverses | — | 3 épreuves rouges, voir §14 |
| `probe_cave_collerette.py` | `b_collerette/tools/blender/` | collerette, rim topologique + sphère inscrite | rim vérifié : 561 faces de trace contre 16 799 de roche | **sphère 3D s'échappe le long de Y** → optimiste ; **non calibrée** |
| `probe_cave_edt_plan_bouche.py` | `b_collerette/tools/blender/` | EDT exacte, goulot de coupe minimale | pas 0,04 m | **non calibrée** |
| `plot_cave_section.py` | `tools/` *(tronc)* | coupe, carte d'épaisseur, écart crête/axe | mesure le **GLB livré** | **SUR-ÉVALUE jusqu'à +0,0897 m**, non corrigé ; `premiere` ≠ « la paroi » s'il existe une structure entre l'axe et le dehors |
| `audit_cave_floor_columns.py` | `tools/` *(tronc)* | roche sous chaque vide habitable | **aucune station**, colonnes verticales | ne mesure **ni pente, ni continuité, ni gabarit** ; un trou **latéral** ne s'y voit pas |
| `measure_silhouette_masses.py` | `tools/` *(tronc)* | masses de silhouette, image rendue | partition en bassins | corrigé deux fois (`eb41f22`, `5c8ab8c`) |
| `gltf_inspect.py` | `tools/` | validation glTF hors Godot | — | avertit sur `min Y = −3,55` et absence d'UV0 : **pré-existant**, non bloquant |

### 12.1 Calibration de `plot_cave_section.py` — l'instrument de l'intégrateur

**FAIT REPRODUIT** —
`evidence/world_v2/v2_3_r2a/grotte/r2a352_collerette_croisee/calibration_de_ma_coupe.txt` :

| r | R | attendu | mesuré | biais |
|---:|---:|---:|---:|---:|
| 0,8 | 1,5 | 0,7000 | 0,7897 | **+0,0897** |
| 1,0 | 2,2 | 1,2000 | 1,2465 | +0,0465 |
| 1,0 | 1,6 | 0,6000 | 0,6327 | +0,0327 |
| 1,0 | 1,3 | 0,3000 | 0,3204 | +0,0204 |
| 1,5 | 2,7 | 1,2000 | 1,2034 | +0,0034 |
| 1,5 | 1,8 | 0,3000 | 0,3013 | +0,0013 |
| 2,0 | 2,3 | 0,3000 | 0,3000 | **+0,0000** |
| 2,0 | 3,2 | 1,2000 | 1,2000 | **+0,0000** |

**HYPOTHÈSE** sur la cause : origine de rayon hors de l'axe du cercle, le rayon
parcourant une corde et non un rayon. Non vérifiée.

Restent valides dans les lectures de cet outil : **les comptes** et **la structure
des blocs**. À corriger vers le bas : ses **chiffres absolus d'épaisseur**.

---

## 13. Sabotages rouges/verts réellement rejoués

| sabotage | instrument | résultat | statut |
|---|---|---|---|
| plancher des stations terminales retiré, 319 triangles sous `z = 0,60` | `audit_cave_floor_columns.py` | **21 colonnes ouvertes**, RC 1 ; vides bornés 358 → 338 | **FAIT REPRODUIT** |
| sous-sol seul retiré sous `z = 0,00`, 202 triangles | `audit_cave_floor_columns.py` | **reste vert**, RC 0 — correct, le joueur ne tombe pas | **FAIT REPRODUIT** |
| banc analytique tube/cylindre, 8 formes × 4 pas | `cave_collar_calibration.py` | A biais 0,0006 ; B biais −1,00 × pas, corrigé à 0,0000 | **RAPPORTÉ, PARTIELLEMENT REPRODUIT** : j'ai rejoué le banc sur *mon* instrument, pas sur A et B |
| ouverture d'un disque parfait sur cylindre | `cave_collar.py` coupe | 18 289 cases déclarées « air libre », ouverture **0 case** → défaut trouvé et corrigé | **RAPPORTÉ PAR UN AGENT MAIS NON REPRODUIT** |
| fixture à palier non nul | `probe_cave_adversarial.py` | **1 513 rayons suspects sur un tunnel sain** → occurrence 12 | **RAPPORTÉ PAR UN AGENT MAIS NON REPRODUIT** |
| 7 épreuves adverses sur 10 | `probe_cave_adversarial.py` | ROUGE → archivée → restaurée → VERTE | **RAPPORTÉ PAR UN AGENT MAIS NON REPRODUIT** |
| `probe_cave_selftest.py` | — | **30/30**, inchangé après durcissement | **RAPPORTÉ PAR UN AGENT MAIS NON REPRODUIT** |

---

## 14. Sabotages écrits mais NON rejoués

**BLOQUANT pour le gate §10** — l'agent C a réécrit le code de ces trois épreuves
mais **n'a pas relancé la suite après réécriture**. Leur statut reste celui du
dernier run.

| épreuve | ce qu'elle doit prouver | dernier état | ce qui a été réécrit |
|---|---|---|---|
| **5 — collerette** | un sabotage de collerette doit faire rougir | **FAIL** — le sabotage ne mordait pas | câblée sur `4dd1642f` avec ablation de `MAT_CaveRock_Collar` ; **la cible est maintenant `cc3596c5`, non recâblée** |
| **9 — plancher intact** | 0 faute sur une fixture saine | **FAIL** — 13 fautes de plancher résiduelles | prolongement de porche pour supprimer l'artefact de bord |
| **10 — courbure** | l'ancien échantillonnage rougit, le nouveau passe | **FAIL** — 6/73 contre 5/85, la fixture n'isole pas la variable | réécrite **à même jeu de points** |

Bilan officiel : **7 / 10**. L'agent a explicitement refusé de les déclarer vertes
sur la foi d'une modification.

---

## 15. Tests BLOQUÉS, SKIP ou non décisifs

| test | statut | raison |
|---|---|---|
| `cave_voxel_oracle.py` | **BLOQUÉ, RC 3** | composante « intérieure » 3 523 m³ ; l'inondation fuit par le porche évasé qui plonge sous le terrain. Sa première version rendait « 0 fuite » en confinant l'inondation à une tranche de façade — un acquittement par aveuglement. **Ne doit pas être cité comme corroboration.** |
| `probe_cave_openings.py` dans le worktree `b_collerette` | **FAIL, non décisif** | le lot collerette a mesuré avec la sonde **non durcie** ; son FAIL sur plancher/fond est identique au caractère près sur `BASE352`, donc pré-existant et depuis expliqué (§10.1) |
| sonde 3D de collerette, `probe_cave_collerette.py` | **FAIL, RC 1, contesté** | 0,32 m au `(0,60 ; −1,87 ; 1,27)` ; profil de recul 0,32 → 0,62 → 1,56 → 1,82, signature d'un biseau d'overhang. Colonne verticale au même endroit : 1,57 m. Seuil **non relevé**. |
| `validate_fast.sh` | **NON EXÉCUTÉ, interdit** | §13 de la directive |
| niveaux 6 et 7 (performance, soak, export) | **NON EXÉCUTABLE** | conteneur headless sans GPU — limite d'environnement permanente |
| contrôles manuels §21.4 (clavier, manette, écran) | **NON EXÉCUTABLE** | même raison ; protocole dans `docs/MANUAL_VALIDATION.md` |

---

## 16. Fichiers modifiés par chaque lot

### 16.1 Lot collerette — `c79341e..e0e7567`, 15 fichiers, +1964 lignes

```
assets/environment/caves/SM_WaterfallCave.glb            Bin 1506684 -> 1489928
source_assets/blender/environment/SM_WaterfallCave.blend Bin 1767556 -> 1777204
source_assets/blender/environment/make_waterfall_cave.py     +209
tools/blender/probe_cave_collerette.py                       +509  (nouveau)
tools/blender/probe_cave_edt_plan_bouche.py                  +130  (nouveau)
evidence/world_v2/v2_3_r2a/grotte/r2a352_collerette/LISEZMOI.md               +222
evidence/.../r2a352_collerette/cartes_porche_avant.log                        +204
evidence/.../r2a352_collerette/chaine_avant.log                               +127
evidence/.../r2a352_collerette/chaine_visiere.log                             +129
evidence/.../r2a352_collerette/edt_plan_de_bouche.log                          +27
evidence/.../r2a352_collerette/gltf_inspect.log                                +24
evidence/.../r2a352_collerette/probe_openings_apres.log                       +167
evidence/.../r2a352_collerette/probe_openings_base352.log                     +167
evidence/.../r2a352_collerette/sonde_collerette_apres.log                      +25
evidence/.../r2a352_collerette/sonde_collerette_avant.log                      +24
```

Modification du générateur : **une seule entrée ajoutée** à la liste `ENVELOPPE`,
`SM_Env_Visiere`, plus ~155 lignes de commentaire. **Aucune fonction nouvelle,
aucun seuil touché, aucune table gelée modifiée** — vérifié ✔ par
`git diff c79341e..HEAD | grep -E "^[-+][A-Z_]+ *="` → vide.

L'entrée, telle qu'elle est dans le code :

```python
dict(nom="SM_Env_Visiere", amas="levre", rang=RANG_ENVELOPPE,
     ancre=(-0.85, 0.35), dg=3.60, dp=1.30, n=22, niveaux=11, graine=131,
     p_flanc=0.74, bombement=0.22, biais=0.34, biais_az=238.0,
     crete=[
         (-3.45, 0.15, 1.90, 0.30), (-2.75, -0.90, 2.90, 1.55),
         (-1.95, -1.30, 3.70, 0.70), (-1.10, -1.45, 3.50, 1.90),
         (-0.20, -1.30, 3.45, 0.80), (0.70, -0.95, 3.30, 1.75),
         (1.55, -0.40, 2.35, 0.60), (2.35, 0.45, 1.55, 0.30),
     ])
```

*(état au commit `ea5636f` ; `d922c4c` et `ffb7c3b` l'ont ensuite ajustée —
orteil droit, puis pied élargi `ancre` −0,55/0,20, `dg` 3,90, `dp` 2,00.)*

**Note d'intégration** : `ea5636f` mêle source et GLB. Le §11 de la directive
exige un **commit d'export séparé** — il faudra scinder à l'intégration.

### 16.2 Lot instruments — `c79341e..0860ca9`, 27 fichiers, +10742 / −48

```
tools/probe_cave_openings.py             +693 / -48
tools/probe_cave_adversarial.py         +1101  (nouveau)
tools/cave_frame.py                      +761  (nouveau)
tools/cave_voxel_oracle.py               +638  (nouveau)
tools/cave_collar.py                     +466  (nouveau)
tools/cave_collar_calibration.py         +299  (nouveau)
evidence/r2a352_c_instruments/           21 journaux et JSON
```

**Aucune géométrie, aucun seuil.** Chemin de preuve non standard
(`evidence/r2a352_c_instruments/` au lieu de
`evidence/world_v2/v2_3_r2a/grotte/`) — **à normaliser à l'intégration**.

### 16.3 Lot plancher — aucun fichier

Le worktree `a_plancher` est à `c79341e`, **0 commit, arbre propre**.

### 16.4 Tronc, par mes soins

| commit | fichiers |
|---|---|
| `23003bc` | `tools/audit_cave_floor_columns.py` (nouveau), `tools/CLAUDE.md`, `docs/KNOWN_ISSUES.md`, `evidence/.../r2a352_oracle_plancher/` |
| `8a18bec` | `docs/KNOWN_ISSUES.md`, `evidence/.../r2a352_oracle_plancher/LISEZMOI.md` |
| `a39cdb6` | `evidence/.../r2a352_collerette_croisee/` |
| `a4de17c` | `docs/KNOWN_ISSUES.md`, `evidence/.../r2a352_collerette_croisee/` |
| `b6a7902` | `evidence/.../r2a352_collerette_croisee/` |

---

## 17. Journaux et chemins de preuves

### 17.1 Dans le tronc — vérifié par `find`

```
evidence/world_v2/v2_3_r2a/grotte/r2a352_oracle_plancher/LISEZMOI.md
evidence/world_v2/v2_3_r2a/grotte/r2a352_oracle_plancher/journal_oracle.txt
evidence/world_v2/v2_3_r2a/grotte/r2a352_collerette_croisee/LISEZMOI.md
evidence/world_v2/v2_3_r2a/grotte/r2a352_collerette_croisee/journal_cave_collar.txt
evidence/world_v2/v2_3_r2a/grotte/r2a352_collerette_croisee/calibration_de_ma_coupe.txt
```

Dossiers antérieurs, également dans le tronc : `r2a35_coupe_baseline`,
`r2a35_diagnostic`, `r2a35_enveloppe`, `r2a35_fusion`, `r2a351_integration`.

### 17.2 Dans le worktree collerette — NON INTÉGRÉ

`/home/user/zelda-r2a352/b_collerette/evidence/world_v2/v2_3_r2a/grotte/r2a352_collerette/` :
`LISEZMOI.md`, `cartes_porche_avant.log`, `chaine_avant.log`, `chaine_visiere.log`,
`edt_plan_de_bouche.log`, `gltf_inspect.log`, `probe_openings_apres.log`,
`probe_openings_base352.log`, `sonde_collerette_apres.log`,
`sonde_collerette_avant.log`.

### 17.3 Dans le worktree instruments — NON INTÉGRÉ

`/home/user/zelda-r2a352/c_instruments/evidence/r2a352_c_instruments/` :
`adversarial.log`, `adversarial_bilan.json`, `base352_sonde_durcie.json`,
`base352_sonde_durcie.log`, `collerette_apres_4dd1642f.json`,
`collerette_avant_8bc8b9f9.json`, `collerette_calibration.json`,
`collerette_calibration.log`, `collerette_deux_mesures.log`, `couverture.log`,
`epreuve2_asymetrie.json` … `epreuve10_courbure.json`, `selftest_30sur30.log`,
`sonde_rapide.log`.

---

## 18. Captures réellement produites / captures absentes

### 18.1 Produites pour R2a-3.5.2

**AUCUNE.** `find` sur les quatre dossiers de preuve de cette passe : **0 PNG**.
**FAIT REPRODUIT.**

### 18.2 Existantes pour la passe précédente

`evidence/world_v2/v2_3_r2a/grotte/r2a351_integration/` : **9 PNG** — profil
asymétrique, carte d'épaisseur, coupe technique, silhouettes aux trois azimuts.
Ils décrivent la géométrie **avant** collerette.

### 18.3 Manquantes et exigées par le §12

**NON VÉRIFIÉ / BLOQUANT** pour la clôture :

- A/B du porche, côté « avant » = dernière géométrie R2a-3.4 rejetée, à caméra,
  FOV, résolution et exposition identiques ;
- silhouettes aux azimuts 55 / 100 / 225 sur `cc3596c5` ;
- vues rendues de la visière, pour juger si elle **se lit** comme de la roche et
  non comme une arche ;
- manifeste par capture : SHA réel, scène, caméra, FOV, résolution,
  `repo_dirty:false` ;
- inspection de chaque image à taille réelle.

Rappel d'environnement : le niveau 5 (capture) fonctionne via **Xvfb + Mesa
llvmpipe**, en rendu **logiciel** — utilisable pour la régression visuelle,
**jamais** pour une mesure de performance.

---

## 19. Éléments intégrés

Intégrés au tronc et poussés :

| élément | commit |
|---|---|
| `tools/audit_cave_floor_columns.py` avec son contrôle négatif | `23003bc` |
| quatre pièges dans `tools/CLAUDE.md` | `2557942`, `f2221e6`, `a8844c0`, `7cbecfe` + le piège de parité dans `23003bc` |
| ISS-048 (dette de semelle), ISS-049 (7ᵉ occurrence), ISS-050 (vides internes), ISS-051 (biais d'instruments), renvoi ISS-044 | `23003bc`, `8a18bec`, `a4de17c` |
| preuves oracle de plancher | `23003bc`, `8a18bec` |
| preuves collerette croisée + calibration | `a39cdb6`, `a4de17c`, `b6a7902` |

**Aucune géométrie n'est intégrée.**

---

## 20. Éléments présents uniquement en worktree ou en patch

| élément | où | pourquoi pas intégré |
|---|---|---|
| visière + orteil + pied élargi, GLB `cc3596c5`, `.blend` `c2913166` | `b_collerette`, `ea5636f`→`e0e7567` | l'ordre §11 impose les instruments d'abord ; épreuves adverses 7/10 |
| instruments durcis, calibrés, 10 épreuves | `c_instruments`, `3ea71c8`→`0860ca9` | 3 épreuves rouges non rejouées ; `cave_voxel_oracle` BLOQUÉ ; chemin de preuve à normaliser |
| GLB prototype `BASE352` `8bc8b9f9` | `prototypes/` des quatre worktrees | non versé au chemin livrable, par construction |
| correctif `carte_du_plancher()` de l'agent A | intégré **par C** dans `probe_cave_openings.py` | l'agent A n'a produit aucun commit |

---

## 21. Décisions déjà prises par le lead

**ACCEPTÉ PAR LE LEAD — non rediscutables.**

1. **Arbitrage R2a-3.5** : « **Déplacer le vide intérieur, pas sacrifier la
   silhouette extérieure.** » Exécuté et mesuré : écart crête/axe moyen 2,84 →
   1,06 m, maximum 7,95 → 2,29 m.
2. **Verdict R2a-3.5** : `FAIL TECHNIQUE — FAIL VISUEL`.
3. **Refus de la contradiction** : « La bouche peut rester ancrée et la poche
   rester sous la dominante sans que la galerie ni sa section soient centrées dans
   la roche. » Ma conclusion selon laquelle trois exigences se contredisaient a été
   **refusée**.
4. **R2a-3.5.1 — section asymétrique** : à partir de la station 2, côté `+normal`
   limité au gabarit réel du joueur, côté `−normal` élargissement déporté. « **La
   demi-largeur actuelle de 4,20 m n'est pas le gabarit du joueur.** »
5. **Contrefort basal** autorisé **en repli seulement**, après mesure des routes,
   caméras et instances gelées. **Non construit** : après asymétrie, les stations
   portent 0,87 à 0,90 m de paroi, et le justifier aurait demandé une mesure qui
   n'existe plus.
6. **La bouche est gelée** : ancre, position et cadrage inchangés au millimètre.
7. **La récompense ne se déplace pas.**
8. **Aucun seuil ne peut être modifié.**
9. **Golden masters : 3 / 4.** Pylône, pont et hameau gelés.
10. **`GO_V2_3_R2B = FALSE`, `GO_V2_3_B = FALSE`, aucune propagation.**

---

## 22. Hypothèses réfutées

| hypothèse | réfutation | statut |
|---|---|---|
| « Les stations 6 à 8 n'ont pas de plancher » — inscrite par moi au cahier des charges de cette passe | **7ᵉ occurrence** du défaut d'échantillonnage dans `carte_du_plancher()`. Le même contrôle, échantillonné le long de la normale : 0 faute sur 33, écart max 0,03 m. Cinq instruments concordent, dont un sans stations : **2,887 m de roche** sous les 33 colonnes habitables | **RÉFUTÉE, FAIT REPRODUIT** |
| « Trois exigences de R2a-3.5 se contredisent » | refusée par le lead ; la section asymétrique les concilie. Paroi 0,11 → 0,87 m, percées 403 → 0 | **RÉFUTÉE** |
| « Un contrefort basal est nécessaire » | ma mesure était confondue : prise sur le maillage **final**, où la soustraction avait déjà retiré la peau extérieure. Avant soustraction la roche est là : 2,96 / 2,69 / 2,23 / 1,69 / 1,44 / 1,32 m | **RÉFUTÉE** |
| « Le porche a une collerette de 0,48 m » | 0,48 était le minimum des **7 rayons survivants** ; 25 rayons sur 33 sortaient par un jour, azimuts 39–193° sans interruption. Pas de roche du tout sur les trois quarts du pourtour | **RÉFUTÉE** |
| « L'axe déclaré est dans la roche aux stations 5 à 8 » *(agent C)* | artefact du maillage `8bf1a1b3` mesuré avec les tables de R2a-3.5.2. Sur `8bc8b9f9`, axe dans le vide aux neuf stations, 6/6 directions paires | **RÉFUTÉE, retirée par son auteur** |
| « `CAVITE` s'arrête à 3,17 quand le vide court jusqu'à 8,2 » *(agent C)* | l'agent lisait les **anciennes** valeurs `MODELE_SALLE (1.05, 0.22, -6.25)` et `MODELE_NICHE (-1.20, 0.43, -8.20)`, absentes de `c79341e`. Valeurs corrigées : salle `ay 2,58`, niche `ay 4,09` | **RÉFUTÉE, retirée par son auteur** |
| « 101 percées confirmées sur `8bc8b9f9` » | fantômes : **81 origines sur 150** ont au moins une direction cardinale sans roche. Deux défauts d'instrument (`ENCLOSURE_MIN`, `offsets_lateraux`) | **RÉFUTÉE, FAIT REPRODUIT** sur un point |
| « 24 rayons sous le minimum de paroi de 0,80 m » *(mon instrument)* | le bloc mince est une **nervure intérieure** entre galerie et poche d'alcôve ; la paroi réelle fait 3,2 à 3,9 m. `controle_epaisseur` a raison | **RÉFUTÉE, FAIT REPRODUIT** |
| « Ma coupe et le B corrigé convergent à quatre décimales, donc c'est prouvé » | la calibration montre que **ma coupe sur-évalue** de +0,00 à +0,09 m. Deux instruments biaisés en sens contraires peuvent se croiser | **RÉFUTÉE par moi-même** |
| « `dp = 2,70` mure le porche » *(R2a-3.5.1)* | contournée, **non re-mesurée** | **HYPOTHÈSE non levée** |

---

## 23. Limites techniques restantes

1. **BLOQUANT — trois épreuves adverses sur dix restent rouges** (§14),
   réécrites mais non rejouées. L'épreuve 5 n'est même plus câblée sur la
   géométrie candidate finale `cc3596c5`.
2. **BLOQUANT — `cave_voxel_oracle.py` en RC 3.** Le second oracle exigé par la
   Phase I n'est pas opérationnel. La corroboration indépendante repose donc sur
   `audit_cave_floor_columns.py` (plancher) et `cave_frame.py` (couverture), pas
   sur lui.
3. **Tension d'étalonnage NON RÉSOLUE.** `cave_collar.py` B **non corrigé** lit
   0,5657 au pas 0,05 ; l'EDT exacte de l'agent B lit 0,5657 au pas 0,04. **Deux
   pas différents, le même nombre à quatre décimales.** S'ils portaient tous deux
   le biais d'une maille démontré sur le cylindre, ils différeraient de 0,01 m.
   Même schéma sur la géométrie finale : B non corrigé vaudrait 1,05 ; l'EDT lit
   1,040. Deux lectures possibles :
   *(a)* la correction `+ pas`, valide sur un cercle **aligné à la grille**,
   sur-corrige sur une frontière irrégulière ; *(b)* l'EDT « exacte » porte le même
   biais et la coïncidence des pas est fortuite.
   **Le discriminant est le même cylindre**, et l'EDT n'y a pas été confrontée.
   **HYPOTHÈSE non levée.** Sans effet sur le verdict — 0,827 m au minimum sur
   `cc3596c5` — mais à lever avant de citer un chiffre au centimètre.
4. **Le générateur `controle_epaisseur` et la sphère inscrite ne sont pas
   calibrés.** Leurs chiffres sont des indications, pas des preuves.
5. **`plot_cave_section.py` sur-évalue**, mesuré et publié, **non corrigé**.
6. **ISS-048** — `SEMELLE_PART_LAT` ne dérive plus de la cavité ; le plancher
   existe parce que l'enveloppe le porte. Docstring à réconcilier avec le code.
7. **ISS-050** — vides internes de 0,18 à 1,74 m dans le massif entre galerie et
   paroi, stations 4,75–5,25 du côté large. Sans effet sur le contrat. `S4`.
8. **ISS-049** — le filet qui balaierait les outils à la recherche du motif
   `ax + f * hw` n'existe pas. Tant qu'il n'existe pas, rien ne garantit qu'il n'y
   ait pas de 15ᵉ occurrence.
9. **Coût de composition assumé** : proéminence du col à l'azimut 100° 1,21 →
   1,06 m ; portail à 0,90, marge 0,31 → 0,16. La télémétrie à l'entaille 1,20
   bascule de 3 à 2 masses — elle passait avec 0,01 m.
10. **Le sabotage doit retirer la chose testée.** Un premier contrôle négatif
    retirait la matière sous `z = 0` alors que le plancher vit à `z ≈ 0,1..0,37` :
    il laissait la peau intacte et l'outil restait vert. Toujours vérifier le
    nombre de triangles réellement retirés.
11. **Environnement** : conteneur Linux headless, **sans GPU**, sans périphérique
    audio. Niveaux 6 et 7 non exécutables. Capture en rendu logiciel uniquement.

---

## 24. Limites visuelles restant NON VÉRIFIÉES

Toutes **NON VÉRIFIÉ**. Aucune ne peut être levée par un instrument.

1. **La visière se lit-elle comme de la roche, ou comme une arche ?** Aucun
   rendu n'existe. Les interdits du §8.9 — fer à cheval régulier, linteau
   rectangulaire, voussoirs, anneau décoratif — sont des critères d'**œil**.
2. **Le biseau d'overhang à 0,32 m** se lit-il comme de la roche ? L'agent B
   refuse de le combler et refuse de relever le seuil ; il le pose au lead.
3. **La composition aux trois azimuts** après la perte de 0,15 m de proéminence
   au col de 100° : le contrat tient à 3/3/3, mais l'effet visuel n'est pas jugé.
4. **La cohérence géologique** de la visière avec le pendage du massif et les
   strates — exigée au §8.9, non vérifiable sans image.
5. **Le verdict artistique reste au lead.** Aucun verdict visuel auto-déclaré
   n'est admis (§8.13).

---

## 25. Prochaine action exacte

Dans cet ordre, sans en sauter aucune.

1. **Rejouer les épreuves adverses 5, 9 et 10** dans le worktree
   `c_instruments`, après avoir **recâblé l'épreuve 5 sur `cc3596c5`** (elle vise
   encore `4dd1642f`, qui n'existe plus sur disque). Objectif : **10/10**. Tant
   que ce n'est pas fait, la Phase I n'est pas close et le gate §10 ne peut pas
   être évalué.
2. **Trancher la tension d'étalonnage** (§23.3) en passant
   `probe_cave_edt_plan_bouche.py` au banc `cave_collar_calibration.py`. Une
   minute de calcul. Résultat attendu : soit l'EDT porte le biais d'une maille et
   la correction de `cave_collar.py` est confirmée, soit elle ne le porte pas et
   la correction sur-corrige sur frontière irrégulière.
3. **Calibrer `controle_epaisseur` du générateur et la sphère inscrite** sur le
   même banc, ou déclarer explicitement leurs chiffres non probants.
4. **Intégrer dans l'ordre du §11** : instruments d'abord
   (`c_instruments`, `3ea71c8`→`0860ca9`, en **normalisant le chemin de preuve**
   vers `evidence/world_v2/v2_3_r2a/grotte/`), reproduction complète par
   l'intégrateur, **puis** géométrie (`b_collerette`, `ea5636f`→`e0e7567`, en
   **scindant `ea5636f`** en un commit source + `.blend` et un commit d'export GLB
   distinct), reproduction complète.
5. **Relire le diff combiné fonction par fonction.** « Zéro conflit textuel ne
   vaut pas validation sémantique. » Point d'attention : le `.blend` est binaire et
   ne fusionne pas ; prendre celui du lot collerette.
6. **Rejouer la chaîne complète** et exiger RC 0, puis `gltf_inspect` et
   l'empreinte GLB.
7. **Produire les captures du §12** depuis un arbre **committé et propre**,
   `repo_dirty:false`, et **les inspecter à taille réelle**.
8. **Soumettre à revue visuelle Codex/Istvan.** Aucun verdict artistique
   auto-déclaré.
9. **Actualiser le présent fichier**, puis prononcer la formule §14 qui
   correspond à l'état réel.

---

## 26. Actions explicitement interdites

Reprises du §13 de la directive et des règles permanentes du dépôt.

**Interdits par la directive R2a-3.5.2 :**

- exécuter `validate_fast.sh` ;
- recapturer les 38 prises ;
- propager à d'autres POI ;
- ouvrir V2.3-R2B ou V2.3-B ;
- décoration intérieure finale ;
- nouvelle niche artistique ;
- modifier pylône, pont ou hameau ;
- modifier le monde V2.2 gelé ;
- **abaisser un seuil** ;
- **neutraliser un test** ;
- capturer depuis un arbre sale ;
- **prononcer un verdict visuel auto-déclaré**.

**Interdits par la directive, périmètre géométrique :**

- déplacer la bouche, son ancre ou son cadrage ;
- **déplacer la récompense** ;
- exclure une station pour obtenir un PASS ;
- raccourcir artificiellement le trajet ;
- déplacer la paroi terminale sans justification ;
- réduire le gabarit canonique ;
- soustraire tout le vestibule après avoir ajouté la matière de collerette ;
- fer à cheval régulier, linteau rectangulaire, voussoirs, anneau décoratif
  indépendant, petits rochers répétitifs, matière placée devant le joueur.

**Interdits de procédure :**

- `reset`, `rebase`, `amend`, commit de fusion, `force-push`, changement de
  branche improvisé — l'historique reste **strictement additif** ;
- laisser un agent pousser ;
- `pkill` global ; attente par `pgrep -f` ; boucle capable de se détecter
  elle-même ; `user://` partagé implicite ; valider un worktree avec le cache
  `.godot/` d'un autre ;
- créer une pull request sans demande explicite.

**Interdits permanents du dépôt :**

- tout contenu Nintendo, sous quelque forme ;
- employer l'image de référence North Star comme asset ;
- éditer `.godot/imported/` à la main ;
- déclaration GDScript non typée ;
- inventer une capture, un FPS, une durée ou un résultat de test ;
- transformer `NON VÉRIFIÉ` en `PASS` par déduction.

---

## 27. CHECKPOINT 1 — ce que l'intégrateur a établi lui-même

Tout ce qui suit est **FAIT REPRODUIT** par l'intégrateur, commandes et sorties
dans `evidence/world_v2/v2_3_r2a/grotte/r2a352_reproductibilite/`.

### 27.1 Le GLB candidat est reproductible byte-identique — la condition d'arrêt ne se déclenche pas

Worktree isolé `/home/user/zelda-r2a352/determinisme` créé sur `e0e7567`, chaîne
officielle `tools/blender/export_architecture.sh waterfall_cave` sous verrou
global :

| | source | RC | GLB produit |
|---|---|---:|---|
| run 1 | `e0e7567`, avec collerette | **0** | `cc3596c5d68cbfd8060987604aad6d5356772df18086f3f76f5aa8dbf8a73f49` |
| run 2 | idem, relancé | **0** | **empreinte identique, 64 caractères** |
| run 3 | `c79341e`, **sans** collerette | **1** | aucun — la chaîne refuse d'exporter |

Le run 3 est le contrôle négatif, et il prouve que les deux premiers ne sont pas
une chaîne inerte : avec la source d'avant la collerette, le générateur sort
non-zéro et imprime lui-même le défaut —
`station 0, azimut 39°/45°/51°/58°/64° — 0 croisement(s) : le rayon sort par un JOUR`.
C'est exactement le défaut corrigé par le lot, retrouvé sans instrument tiers.

### 27.2 Le `.blend` n'est PAS reproductible, et cela impose une étape

Trois empreintes pour la même entrée : `c2913166…` versionné, `3c19d05e…` après
run 1, `b468b665…` après run 2. Comportement documenté de Blender.

**La séquence d'intégration doit comporter un `git checkout -- <blend>` explicite
après l'export et avant le commit du GLB**, sinon aucune capture ne pourra venir
d'un arbre propre. Le `.blend` est un **conteneur** ; la source est le `.py`.

### 27.3 Les repères de gameplay — re-dérivation, pas déplacement de récompense

Le §26 interdit de déplacer la récompense, et la base `c79341e` change
`MODELE_NICHE`. Mesuré, plutôt qu'arbitré — rayon vertical, parité d'impacts,
sur le candidat `cc3596c5` :

| constante | état dans la roche |
|---|---|
| `MODELE_NICHE` **ancien** `(-1.20, 0.43, -8.20)` | **DANS LA ROCHE** |
| `MODELE_NICHE` `c79341e` `(2.78, 0.50, -4.09)` | **DANS LE VIDE** — sol 0,49, plafond 2,23 |
| `MODELE_SALLE` **ancien** `(1.05, 0.22, -6.25)` | **DANS LA ROCHE** |
| `MODELE_SALLE` `c79341e` `(2.62, 0.09, -2.58)` | **DANS LE VIDE** — sol 0,08, plafond 2,89 |

Les anciennes valeurs murent la récompense. Les conserver n'est pas « ne pas la
déplacer », c'est la laisser **inatteignable**.

Deux vérifications referment le raisonnement :
- le sol lu sous la niche vaut **0,49 m** ; `controle_sol_repere` du générateur
  publie **+0,492** pour le même repère — deux chemins indépendants, même valeur ;
- la directive en cours **a déjà accepté la conséquence** de la valeur corrigée
  (« la récompense demeure accessible »), accessibilité calculée avec
  `(2,78 ; 0,50 ; −4,09)`.

**Décision de l'intégrateur, ouverte à renversement par le lead** : re-dérivation
légitime. Les huit `APPUIS_MODELE` et la lampe de seuil suivent la même cavité et
relèvent du même raisonnement, **mais restent à mesurer un par un**.

### 27.4 Surface de conflit entre lots — vide, mesurée

`b_collerette ∩ c_instruments` → vide. `b_collerette ∩ tronc-depuis-202d849` →
vide. `c_instruments ∩ tronc-depuis-202d849` → vide.
`probe_cave_openings.py` n'est touché que par `c_instruments`. `a_plancher` a
0 commit et un diff vide à `c79341e` — **confirmé, non supposé**.

L'ordre séquentiel est donc légitime au sens textuel.

### 27.5 Périmètre — zéro débordement

Union exhaustive des lots : **48 fichiers**, dont 17 hors `evidence/`. Aucun
n'appartient à un domaine gelé. Cinq correspondances d'un premier balayage large
étaient des faux positifs : « Waterfall » contient « water ».

### 27.6 Séquence d'intégration retenue — six commits

| # | contenu | nature | précondition |
|---:|---|---|---|
| **0** | base R2a-3.5.2 — `f3afa0e` + `c79341e` aplatis | source + `.blend` + prototype `.glb` | aucune |
| 1 | instruments durcis et calibrés | `tools/` + preuves, chemin normalisé vers `evidence/world_v2/v2_3_r2a/grotte/r2a352_instruments/` | instruments reproduits verts **par l'intégrateur** |
| 2 | source + `.blend` collerette | source + `.blend`, **sans le `.glb`** | **gate technique complet** |
| 3 | export GLB contrôlé | artefact | hash == `cc3596c5…`, après `git checkout -- <blend>` |
| 4 | journaux du lot collerette | preuves | commit 3 réussi |
| 5 | captures et manifestes | preuves | **non exécutable en l'état** — 0 PNG |

### 27.7 Le lot plancher est clos

**`REFUTED — NO GEOMETRY CHANGE`.** Aucune géométrie de plancher n'est construite.
Les preuves et les instruments corrigés sont conservés. Les stations 7 et 8 sont
hors du trajet praticable mesuré ; la récompense demeure accessible.

---

## 28. CHECKPOINT 2 — l'audit d'intégration, et un danger de périmètre

Stratégie complète : `scratchpad/r2a352/audit/06_strategie.md`. Ce qui suit en est
l'essentiel, avec ce que l'intégrateur a tranché.

### 28.1 DANGER — la chaîne d'export sans argument touche quatre assets GELÉS

**FAIT REPRODUIT** (lecture de `tools/blender/export_architecture.sh`).

`pylon`, `stone_bridge`, `village_quay` et `village_wall` vivent dans **la même
liste `SUJETS`** que `waterfall_cave`. Lancer :

```sh
tools/blender/export_architecture.sh          # SANS argument
```

régénère les quatre, c'est-à-dire **trois golden masters validés**. C'est la seule
véritable porte de sortie du périmètre trouvée sur les 48 fichiers de la passe, et
elle ne s'ouvre pas par malveillance : elle s'ouvre quand la commande est tapée de
mémoire.

**RÈGLE : l'argument de sujet est obligatoire.** Toute commande de chaîne écrite
dans un document, un script ou un message porte `waterfall_cave` explicitement.
Les trois runs de déterminisme du checkpoint 1 le portaient — vérifié dans leurs
journaux.

### 28.2 Le `.blend` est une SORTIE de la chaîne, jamais une entrée

**FAIT REPRODUIT** : `read_factory_settings(use_empty=True)` → import du kit →
`save_as_mainfile`. Le `.blend` n'est lu nulle part comme source. Combiné à sa
non-reproductibilité (§27.2), cela commande trois règles :

1. **ne jamais committer le `.blend` fraîchement produit** — il diffère à chaque
   exécution et ne correspondrait à aucune empreinte citée ;
2. le `.blend` versé au commit 2 est celui du lot, `c29131661550d558…`, obtenu par
   `git checkout e0e7567 -- <blend>`. **Décision de l'intégrateur**, contre la
   proposition par défaut de l'audit (rendre à `c79341e`) : un tronc dont le
   `.blend` ne correspond pas à son propre `.py` induirait en erreur tout lecteur
   ultérieur ;
3. après la chaîne du commit 3, `git checkout e0e7567 -- <blend>` restaure l'arbre
   avant le commit du GLB.

### 28.3 Commit 0 — liste close à neuf fichiers

`git diff --name-status 202d849..c79341e` → 9 fichiers, 3 ajouts, 6 modifications.

Touchés ensuite par un lot (3) : `make_waterfall_cave.py`, `SM_WaterfallCave.blend`,
`probe_cave_openings.py`.

**Touchés par personne (6)** — sans le commit 0 ils resteraient anciens ou absents :
`waterfall_cave_place.gd` · `plot_cave_section.py` · `probe_cave_selftest.py` ·
`probe_cave_negative_control.py` · `diag_cave_etapes.py` ·
`prototypes/SM_WaterfallCave_BASE352.glb`.

`base(202d849..c79341e) ∩ tronc(202d849..d25fadc)` → **vide**. Aucune collision.

`BASE352` entre dans le commit 0, **étiqueté artefact de diagnostic**, jamais
livrable : des preuves déjà versées au tronc mesurent sur `8bc8b9f9`, et sans lui
le tronc porterait des journaux désignant une empreinte introuvable.

`f3afa0e` et `c79341e` sont **aplatis** : verser `f3afa0e` séparément recréerait
sur le tronc l'état exact qui a fait mesurer le mauvais maillage à un agent.

Le cherry-pick est prouvé **conflictuel** sur les deux lots (`git merge-tree`,
RC 1) : l'application se fait par `git checkout <sha> -- <chemin>`.

### 28.4 Les repères — une confirmation, une nuance, une réserve

**Confirmation.** L'audit reproduit indépendamment la mesure du §27.3 :
`MODELE_NICHE` et `MODELE_SALLE` anciens dans la roche, nouveaux dans le vide,
sol +0,49 et +0,08. Le +0,49 recoupe le +0,492 de `controle_sol_repere`.

**Nuance, et elle corrige l'intégrateur.** La **lampe de seuil ne relève pas du
même raisonnement** : ses deux positions sont dans le vide (ancienne sol +0,00,
nouvelle sol −0,05). L'ancienne n'était **pas** murée. C'est un ajustement de mise
en scène, **pas une réparation**, et le message du commit 0 ne doit pas les
confondre.

**`APPUIS_MODELE`.** Mesure par coupe exacte au plan `y = 0`, 484 segments :
anciens écart moyen **1,37 m** (max 3,27) · nouveaux **0,43 m** (max 0,92). Les
nouveaux suivent le contour réel trois fois mieux.

**RÉSERVE OUVERTE** : un des huit **nouveaux** appuis tombe **0,92 m en dehors**
de la coupe au sol. HYPOTHÈSE de l'intégrateur, à éprouver : il serait **sous un
surplomb** — la coupe à `y = 0` exclut les surplombs par construction, et la zone
remodelée (porche évasé, visière, orteil, pied élargi) déborde précisément vers
l'avant au-dessus du sol. Trois mesures tranchent : appartenance à la silhouette
projetée, présence de roche au-dessus, altitude à laquelle elle commence.

L'audit a posé **deux mauvais tests avant le bon** et les a consignés tous les
trois, dont une fausse alerte due à un point de contour tangent qu'un rayon peut
manquer.

### 28.5 Le contrôle final compare les DELTAS, pas le vide

Un `git diff` vide entre le tronc et `c79341e` ne prouverait que l'égalité finale,
pas l'absence de contenu tiers. Le contrôle exige que le générateur sur le tronc
vaille **exactement** `c79341e..e0e7567` et `probe_cave_openings.py` **exactement**
`c79341e..0860ca9`, par comparaison de deux patches.

### 28.6 Le filet `world_v2_places` NE PEUT PAS ÉCHOUER sur les appuis — BLOQUANT de preuve

**FAIT REPRODUIT** par lecture de code, chaîne fermée maillon par maillon, sans
aucune exécution Godot. Détail complet : **ISS-052**.

L'appui est déclaré à `ground_local_y(...)`, qui rend
`_ground.call(x, z) - global_position.y`. Le builder injecte ce même `height_at`
comme `_ground`. Le test compare `absf(world_point.y - height_at(x, z))` à 0,65 m.
Le lacet de 45° étant porté par `ouvrage` et non par le nœud du lieu, `to_global`
préserve `y` exactement. **L'écart vaut 0 par construction.**

Le commentaire du code l'écrivait déjà — « l'écart au sol est nul par
construction » — mais personne n'en avait tiré que l'assertion correspondante
était vide. C'est l'anti-motif nommé au `PROMPT4_METHOD` §2.

**Portée au-delà de la grotte** : `stone_bridge_place.gd:237` construit ses appuis
de la même façon. **Le pont est un golden master validé.**

**Conséquence directe sur le gate §10.** L'item « filets `world_v2_places` 8/8 »
peut être cité, mais **uniquement pour ce qu'il couvre réellement** :

| ce que le 8/8 atteste | ce qu'il n'atteste PAS |
|---|---|
| chaque lieu déclare des appuis non vides | qu'un appui appartienne au massif |
| chaque lieu s'instancie seul | l'écart réel d'un appui au terrain |
| le lieu n'est ni flottant ni enterré *(AABB visuelle du lieu entier)* | quoi que ce soit **par appui** |

Le correctif n'est **pas** appliqué dans cette passe : rendre un contrôle vide
signifiant peut faire rougir un golden master validé. C'est une décision de lead.

### 28.7 Un appui de la grotte est à l'air libre — RÉSERVE NON LEVÉE, non bloquante

**FAIT REPRODUIT.** L'hypothèse du surplomb formulée par l'intégrateur est
**réfutée** : la colonne verticale de l'appui `(8.14 ; −6.03)` porte **0 impact à
toute hauteur**, quand les sept autres appuis neufs en portent **tous exactement
2**. Sommet de maillage le plus proche : 0,74 m. Il est à l'air libre.

Écarts signés à la coupe au sol, liste `c79341e` : `+0,92` *(dehors)* · −0,09 ·
−0,17 · −0,20 · −0,37 · −0,46 · −0,58 · −0,67.

**Gravité bornée par la mesure, pas par l'opinion** : recherche exhaustive de
`get_meta(&"support_points")` → lu seulement par le filet de test,
`tools/godot/probe_place_metrics.gd`, et `riverside_village_place.gd` pour ses
propres appuis. **Aucun effet de gameplay, collision, navmesh ou rendu.** Défaut
de véracité, `S3` — **ISS-053**, ticket, pas blocage de gate.

Note de méthode : l'intégrateur avait interverti les deux listes en lisant un
`git diff c79341e f3afa0e`, qui parcourt le temps **à l'envers**. L'audit a relu
par `git show` aux deux révisions plutôt que de se fier au diff. Un diff dont on
ne vérifie pas le sens est un piège ordinaire.

### 28.8 Ce que l'audit n'a PAS vérifié

`NON VÉRIFIÉ` de son propre aveu : la reproductibilité du GLB (mesure de
l'intégrateur, non rejouée par lui), les dix épreuves adverses, et le filet
`world_v2_places` sur l'appui aberrant — cette dernière lui est confiée en lecture
de code.

---

## 29. CHECKPOINT 3 — la séquence d'intégration jouée à blanc, et elle aboutit

**FAIT REPRODUIT.** Preuves :
`evidence/world_v2/v2_3_r2a/grotte/r2a352_reproductibilite/repetition_integration.md`.

Worktree jetable `repetition`, détaché sur le tronc `179806b`. Commits 0, 2 et 3
joués, puis le contrôle final.

Ce que cela ajoute au checkpoint 1, et ce n'est pas la même chose : le
checkpoint 1 prouvait la reproduction **depuis l'arbre du lot**. Il ne disait rien
de ce que la chaîne produirait **depuis le tronc**, dont tous les autres fichiers
diffèrent — à commencer par le kit de modules que le générateur importe.

```
GLB produit depuis TRONC + commit 0 + commit 2 :
  cc3596c5d68cbfd8060987604aad6d5356772df18086f3f76f5aa8dbf8a73f49
```

**Byte-identique au candidat.** Les autres fichiers du tronc n'influencent pas la
géométrie.

Contrôle final sur les **deltas** : `git diff c79341e HEAD -- <générateur>` est
**identique** à `git diff c79341e e0e7567 -- <générateur>`. Le tronc simulé porte
exactement le delta collerette, ni plus ni moins. Et les six fichiers de base que
personne ne touche sont bien à leur état `c79341e`, vérifiés blob par blob.

Après le commit 3 : **arbre propre**, une fois le `.blend` restauré par
`git checkout e0e7567 --`.

**Non couvert** : le commit 1 (instruments), dont le contenu bouge encore — sa
liste devra être **relue au moment d'appliquer**. Et la répétition prouve la
**mécanique**, pas le **droit** d'intégrer : les gates de qualité restent ouverts.

### 29.1 Worktrees existants au moment de ce checkpoint

Deux worktrees ont été créés par l'intégrateur, tous deux jetables, jamais
poussés, sans lien avec la branche :

| chemin | base | rôle |
|---|---|---|
| `zelda-r2a352/determinisme` | `e0e7567` | trois runs de reproductibilité (checkpoint 1) |
| `zelda-r2a352/repetition` | `179806b` | répétition de l'intégration, 3 commits locaux jetables |

Ils s'ajoutent aux quatre worktrees d'agents du §6.2. Toute session qui découvre
un worktree inattendu doit demander avant d'agir — c'est
`COMMENT_TRAVAILLER_ENSEMBLE` §1, et l'audit l'a correctement appliqué.

### 29.2 Un piège de shell, signalé par l'agent preuves visuelles

Son premier lancement a **rendu 0 sans rien exécuter** : redirection vers un
fichier dans un répertoire que le script devait lui-même créer. Le shell a échoué
**avant** la première commande, et le code retour du pipeline valait 0.

Même famille que les pièges déjà consignés : **créer l'arborescence avant**, et ne
croire un travail terminé que sur son jeton `^RC=` écrit par la commande
surveillée.

---

## 30. CHECKPOINT 4 — ARRÊT. La passe s'arrête en `PARTIAL`.

Trois conditions d'arrêt de la directive sont réunies. Aucune géométrie n'est
intégrée ; le tronc porte toujours R2a-3.4.

### 30.1 BLOQUANT — le toit du massif tombe à 3,8 cm au-dessus d'un vide de 1,4 m

**FAIT REPRODUIT** par l'intégrateur, signalé d'abord par l'agent instruments.
Preuves : `evidence/world_v2/v2_3_r2a/grotte/r2a352_toit_mince/`.

Épaisseur de la première roche au-dessus d'un vide ≥ 1,00 m, balayage
`x ∈ [−2 ; 3]`, `y ∈ [4 ; 7]`, pas 0,10 :

| géométrie | toit minimal | où |
|---|---:|---|
| **candidat `cc3596c5`** | **0,038 m** | `(0,50 ; 5,80)` |
| **BASE352 `8bc8b9f9`** | **0,038 m** | identique |
| tronc R2a-3.4 `8bf1a1b3` | **0,374 m** | `(0,80 ; 6,00)` |

Seuil : `EPAISSEUR_MIN_M = 0,80 m`. **L'item de gate « paroi ≥ 0,80 m » échoue.**

Deux lectures, distinctes : **le lot collerette n'en est pas la cause** (identique
sur `BASE352`, donc hérité de l'enveloppe R2a-3.5.2) ; mais c'est une
**régression d'un facteur dix contre la géométrie livrée**.

Ce n'est pas un artefact de rayon rasant : la carte du toit montre une **arête de
roche continue**, ~0,30 m de large sur ~0,60 m de long, dont l'épaisseur varie
régulièrement de 0,58 à 0,038 m puis remonte. Sous elle, 1,36 à 1,47 m de vide.

**Pourquoi aucun contrôle ne l'a vu** : `controle_epaisseur` publie 0,87 m et
n'a pas tort — il mesure **là où il regarde**, et il ne regarde que les stations
de `CAVITE`, dont la dernière est à `ay = 3,17`. Le défaut est à `ay ≈ 5,8`, soit
**2,6 m au-delà**. Hors domaine.

**Joignabilité INDÉTERMINÉE** : deux inondations 3D, l'une sans bouchon, l'autre
avec la dalle de bouche entière bouchée, **atteignent toutes deux le bord de la
grille** — elles s'échappent par le **dessous ouvert du modèle**, ouvert par
conception. Une coulée qui sort n'établit aucune connexité intérieure. Cela ne
change pas le verdict : le contrat porte sur l'épaisseur de la roche, pas sur la
joignabilité, et une lame de 3,8 cm est à une décimation d'être un trou.

### 30.2 BLOQUANT — épreuves adverses 9/10, et l'échec est structurel

L'épreuve 5 est `FAIL`, pour une raison qui ne se répare pas par un réglage :

- **S1** — 164 triangles de `MAT_CaveRock_Collar` retirés → **A et B strictement
  inchangés**. La matière que la docstring prétendait amputer **ne porte pas la
  mesure**. Le rouge du tour précédent venait des 1 276 autres triangles emportés
  par une boîte de 3 m ;
- **S2** — 101 triangles au goulot → **B MONTE**, 1,1000 → 1,1107. L'emprise de B
  **est l'ouverture elle-même** : la roche retirée devient air, l'ouverture
  rétrécit (3 625 → 3 515 cases) et son point le plus mince disparaît avec elle.
  **B n'est pas monotone sous ablation locale** — une épreuve bâtie sur
  « ablater ⇒ la mesure tombe » ne peut donc pas mordre ;
- **S3** — direction sortante tombée dans le vide, 1 triangle retiré. Échec de
  l'agent, nommé comme tel.

Le défaut de comparaison entre deux plans est corrigé (plan imposé `y = −1,15`).

### 30.3 BLOQUANT — l'oracle global n'est pas validé

Il rend `ÉTANCHE` sur le candidat, et **ce verdict ne prouve rien** :
**cinq contrôles négatifs sur six ne rougissent pas**, avec des tunnels de 0,35 à
0,65 m de rayon libre mesuré, de la graine jusqu'au dehors.

Cause de fond : percer en retirant des triangles rend le maillage **ouvert** ; la
parité n'y définit plus de dedans ; **le vote à trois axes rebouche le trou, 2
voix contre 1**. Le vote, introduit pour corriger un vrai défaut, devient la cause
de la cécité.

**La Phase I reste sans second oracle opérationnel.**

### 30.4 Ce qui est ACQUIS malgré l'arrêt

- **GLB reproductible byte-identique**, 3 runs + contrôle négatif rouge (§27) ;
- **séquence d'intégration jouée à blanc depuis le tronc**, elle aboutit (§29) ;
- **gates du générateur reproduits** par l'intégrateur (masses, ratios, plage
  plane, gabarit, plancher) ;
- **plancher réel** : oracle sans stations, RC 0, 420 vides, 0 ouvert ;
- **débord d'overhang AUTORISÉ** — cinq conditions, contrôle négatif à coque
  creuse **refusé** (2 poches) ;
- **§23.3 tranché** : la correction `+ pas` **sur-corrige**. Le biais de B suit la
  **phase de la frontière dans la grille**, pas l'angle. `B` sur-lit jusqu'à +1
  maille, borne à employer `lecture − pas` ; l'EDT sous-lit de −0,76 à −1,12 ×
  pas, sa lecture brute **est déjà une borne inférieure**. Les deux instruments
  sont biaisés **en sens contraires** : leur « convergence à quatre décimales »
  ne pouvait pas en être une ;
- **contrôle rasant** : l'EDT rend 0,08 m pour 0,60 m attendus, faute de voter sur
  une seule parité ; `cave_collar`, qui vote sur quatre, lit +0,0003 m ;
- **ISS-052** — le filet d'appuis `world_v2_places` **ne peut pas échouer** ;
- **audit de vacuité** : `controle_aller_retour` et `controle_gabarit` sont sains
  et portent l'histoire de leur propre réparation.

### 30.5 Prochaine action exacte

1. **Traiter le toit mince** — il appartient à l'enveloppe R2a-3.5.2, pas à la
   collerette. Soit épaissir la lame, soit abaisser le vide, soit démontrer que
   la zone est hors du modèle jouable **et** hors contrat.
2. **Étendre le domaine des contrôles au-delà de `CAVITE`.** Tant que
   `controle_epaisseur` s'arrête à `ay = 3,17`, il ne peut pas voir ce qui vit à
   `ay = 5,8`. C'est la cause commune des trois faits bruts de l'agent
   instruments.
3. **Reconstruire l'épreuve 5 sur un sabotage qui laisse le maillage clos**, seule
   forme qui puisse mordre sur une mesure non monotone.
4. **Reconstruire l'oracle** de même — un sabotage qui laisse le maillage clos.
5. Les captures AVANT restent valides et utiles : elles sont la baseline de la
   reprise.

---

## 31. CHECKPOINT 5 — clôture matérielle de la passe `PARTIAL`

Trois commits après l'arrêt. **Aucun ne touche la géométrie, aucun n'intègre
quoi que ce soit.** Ils existent pour que la passe soit reprenable, ce qui est la
seule chose qu'un `PARTIAL` doive encore garantir.

### 31.1 Les SHA, à distinguer

| commit | rôle | fichiers |
|---|---|---:|
| `1152c92` | répétition d'intégration à blanc (checkpoint 3) | — |
| `fa59912` | **ARRÊT** — le toit à 0,038 m | — |
| `39f0e1d` | **baseline AVANT conservée** + la mesure du confondant | 71 |
| `23b7960` | **les trois lots non intégrés, en patches texte** | 7 |
| `HEAD` actuel | ce checkpoint | — |

`HEAD` = `origin/claude/world-v2-reconstruction`, arbre propre, à chaque étape.

### 31.2 `39f0e1d` — la baseline AVANT, et pourquoi elle n'est pas un A/B

`evidence/world_v2/v2_3_r2a/grotte/r2a352_avant/` — 7 perspectives, 3 silhouettes,
vignettes, niveaux de gris, planche de lecture gamma, `reproduction/` (9 pièces,
self-contained), `SHA256SUMS.txt` (41 fichiers, `sha256sum -c` sans échec).

Le LISEZMOI **mène** avec « LE CÔTÉ APRÈS MANQUE », parce qu'une planche A/B à un
seul côté sera lue comme un verdict si elle ne dit pas qu'elle est incomplète.

**Le résultat le plus important du lot n'est pas une image.** Les deux lampes
intérieures se déplacent entre les deux côtés : un A/B naïf aurait comparé
**géométrie + éclairage** et attribué à la roche ce qui appartient à une lampe.
Triptyque à GLB constant, aux octets près, seules les deux lignes de lampe
changeant :

| vue | pixels changés par l'**éclairage seul** |
|---|---:|
| `04_interieur_sortie` | **83,97 %** |
| `03_gros_plan_seuil` | **61,20 %** |
| `10_visiere_dessous` | **14,77 %** |
| `09_visiere_profil` | 1,25 % |

> **Règle de lecture, à porter sur toute planche future :**
> **A→B = l'éclairage seul · B→C = la géométrie seule.**
> **A→C ne doit jamais être présenté seul sur `03`, `04`, `10`.**

Deux chiffres pour le jour où le côté APRÈS existera : l'outil cadre sur l'AABB
**du sujet**, donc l'A/B **n'est pas à échelle constante** — le sujet APRÈS
paraîtra **+4,28 %**, centre décalé de 0,642 m horizontal et −0,726 m vertical.
Rien dans l'image ne le dit.

**Le décalage entre commit de capture (`1152c92`) et commit de versement est
inerte, et c'est mesuré** : `git diff --name-only 1152c92..HEAD` hors `docs/` et
`evidence/` est **vide** — 81 fichiers changés, les 81 sous ces deux dossiers.
Recapturer n'aurait changé qu'une chaîne de caractères pour des pixels
identiques. Vérifié par l'intégrateur, pas repris sur parole.

### 31.3 `23b7960` — les patches, et pourquoi le `.blend` n'y est pas

Les commits des trois lots vivent dans des **worktrees détachés**, donc dans
l'objet-store d'un conteneur **éphémère**. Non poussés, ils disparaissent avec
lui. Les pousser sur des branches séparées est interdit par les règles de la
session ; les conserver en patches texte committés respecte la règle et rend le
travail récupérable.

| lot | plage | contenu | taille |
|---|---|---|---:|
| instruments | `c79341e..51a7dab` | 4 commits `format-patch` complets | 692 K |
| collerette | `c79341e..e0e7567` | **source seule** | 60 K |
| base R2a-3.5.2 | `202d849..c79341e` | **source seule** | 180 K |

La source seule suffit **parce que c'est mesuré** : la chaîne reproduit le GLB
candidat byte-identique depuis elle, trois fois, avec un contrôle négatif qui
rougit. Le `.blend` est délibérément **absent** — il est une *sortie* de la
chaîne, non reproductible d'un run à l'autre (trois empreintes pour la même
entrée), jamais lu en entrée. Le conserver donnerait l'illusion d'une source.

Et le LISEZMOI le dit sans le noyer : **« reprendre ces patches, c'est reprendre
le défaut avec »** — le toit mince appartient à la base, pas à la collerette.

### 31.4 Ce checkpoint — l'audit de vacuité versé

`evidence/world_v2/v2_3_r2a/grotte/r2a352_audit_vacuite/`. Il était retenu par le
gel du tronc ; le gel est levé.

Il conclut qu'un seul contrôle vide a été trouvé — **ISS-052**, les appuis
`world_v2_places`, qui comparent la hauteur du terrain à elle-même et affectent
un golden master déjà validé. Et il se termine par la distinction qui a coûté la
passe : **vacuité et domaine sont deux maladies distinctes.**
`controle_epaisseur` est parfaitement falsifiable — il *peut* rougir — et
pourtant aveugle, parce que son domaine s'arrête où le défaut commence.

### 31.5 État final, sans adoucissement

- **aucune géométrie intégrée** ; le tronc construit et livre toujours R2a-3.4
  (`8bf1a1b3`, commit de chemin `504ecbe`) ;
- **aucun seuil abaissé, aucun test neutralisé, aucun domaine gelé touché** ;
- golden masters **3/4**, inchangés ;
- `GO_V2_3_R2B=FALSE`, `GO_V2_3_B=FALSE` ;
- verdict visuel **NON VÉRIFIÉ**, et il n'appartient à aucun instrument.

---

## 32. R2a-3.5.3 — ouverture de passe, socle de mesure, trois agents

**R2a-3.5.2 est close en `PARTIAL` et ne doit pas être relue rétrospectivement
comme verte.** La passe R2a-3.5.3 reprend au même endroit avec un mandat
différent : *corriger le défaut réel de toiture, étendre le domaine des contrôles
qui ne le voyaient pas, reconstruire les preuves adverses et l'oracle global,
puis seulement si tout devient vert produire un nouveau candidat.*

Point de départ imposé : `bd78b1853da70603e22825a2a416df15e1121736`. Vérifié —
branche, HEAD local, HEAD distant, arbre propre.

### 32.1 Ce que la directive interdit de rouvrir

- **il est interdit d'intégrer directement `cc3596c5`** ;
- la correction du toit produira nécessairement un **nouveau SHA256**. Si
  l'export après correction reste byte-identique à `cc3596c5`, **la correction
  n'a pas atteint l'artefact** et il faut s'arrêter ;
- plancher : `REFUTED — NO GEOMETRY CHANGE` ; débord de visière : autorisé ;
  collerette (orteil, visière, porche, jambage) : **gelée** sauf défaut nouveau
  démontré ; pylône, pont, hameau, V2.2 : gelés ;
- ISS-052 et ISS-053 **ne sont pas corrigés dans cette passe** ; le filet
  `world_v2_places` 8/8 ne doit jamais être présenté comme une preuve de validité
  individuelle des appuis.

### 32.2 Le socle de mesure — `507ef6a`

Preuves : `evidence/world_v2/v2_3_r2a/grotte/r2a353_socle/`.

Worktree `/home/user/zelda-r2a353/socle`, détaché sur `bd78b18`, plus quatre
applications locales **jamais poussées** — c'est un échafaudage, pas une
intégration :

| # | contenu | provenance | mesure |
|---|---|---|---:|
| 0 | base R2a-3.5.2 | `c79341e` | `2687 insertions(+), 221 deletions(-)`, 9 fichiers |
| 1 | instruments durcis et calibrés | `51a7dab` | 54 fichiers |
| 2 | collerette, **source + `.blend`, sans le `.glb`** | `e0e7567` | 13 fichiers |
| 3 | GLB candidat `cc3596c5` | `e0e7567` | échafaudage de mesure |

Le chiffre du commit 0 est **identique** à celui de la répétition du
checkpoint 3. Recoupement gratuit, non recherché.

### 32.3 FAIT REPRODUIT — la chaîne reproduit `cc3596c5` AVEC les instruments

Le checkpoint 3 prouvait la reproduction depuis **tronc + base + collerette**. Il
ne disait rien de ce que la chaîne produirait **avec les instruments appliqués**,
qui touchent `probe_cave_openings.py` et `plot_cave_section.py`.

```
avant : cc3596c5d68cbfd8060987604aad6d5356772df18086f3f76f5aa8dbf8a73f49
CHAINE_RC=0        === VALIDE ===        20 970 triangles
apres : cc3596c5d68cbfd8060987604aad6d5356772df18086f3f76f5aa8dbf8a73f49
```

**Byte-identique** — quatrième confirmation indépendante, la première avec les
instruments. Contrôle de périmètre après la chaîne : `git status --porcelain
assets/ source_assets/` ne montre **qu'une ligne**, le `.blend`, sortie non
déterministe restaurée aussitôt. Le `.glb` n'apparaît même pas.

Conséquence utile pour l'agent A : toute divergence d'empreinte qu'il observera
après une modification vient **de sa modification**, pas du bruit de la chaîne.

### 32.4 Contrôles de provenance — sur les deltas, pas sur l'égalité

| contrôle | résultat |
|---|---|
| générateur `bd78b18..socle` == `202d849..e0e7567` | **IDENTIQUE** |
| `probe_cave_openings.py` `bd78b18..socle` == `202d849..51a7dab` | **IDENTIQUE** |
| 5 fichiers de base intouchés, blob à blob vs `c79341e` | **5 / 5** |
| fichiers de domaine gelé dans le diff | **aucun** |
| **14 seuils nommés, un par un** | **0 modifié** |

**Un contrôle mal fait, consigné plutôt qu'effacé.** Le premier contrôle de
seuils cherchait `^[-+][A-Z_]+ *=` et a rougi — sur `CAVITE_APEX`, `MASSIF_APEX`,
`PALIER`, c'est-à-dire sur la géométrie de la base, qui a légitimement changé. Le
motif venait du §16.1, où il était juste parce qu'il y portait sur le seul delta
collerette. Étendu à une plage qui inclut la base, il ne distingue plus un seuil
d'une table de coordonnées. **Un contrôle qui rougit sur du travail légitime est
un contrôle qu'on apprend à ignorer** — c'est la façon ordinaire dont un portail
meurt. Remplacé par la lecture des quatorze seuils nommés.

**Fusion plutôt qu'écrasement.** Le lot instruments et le tronc ont tous deux
ajouté un piège en fin de `tools/CLAUDE.md` : prendre le blob du lot aurait
**révoqué** le piège de parité versé au tronc. Le delta a été appliqué, le
conflit résolu en gardant les deux, la présence des deux vérifiée.

### 32.5 Les trois agents

Worktrees détachés sur `507ef6a`, propriétés de fichiers **disjointes**, aucun ne
pousse.

| agent | worktree | propriété exclusive |
|---|---|---|
| **A — toiture et domaine** | `zelda-r2a353/a_toit` | `make_waterfall_cave.py`, `tools/cave_roof_*.py` |
| **B — épreuves adverses** | `zelda-r2a353/b_adverse` | `probe_cave_adversarial.py` et ses fixtures |
| **C — oracle global** | `zelda-r2a353/c_oracle` | `cave_voxel_oracle.py`, `cave_seal_oracle.py`, `tools/cave_oracle_*.py` |

B et C travaillent sur `cc3596c5` : leur mandat porte sur les **instruments**,
pas sur la géométrie. L'intégrateur rejouera leurs outils sur le maillage corrigé
par A.

Cadrage commun remis aux trois : `/home/user/zelda-r2a353/CADRAGE_COMMUN.md`
(hors dépôt — échafaudage).

### 32.6 QUESTION OUVERTE, posée à l'agent A — régression, ou violation préexistante ?

**`EPAISSEUR_MIN_M = 0,80`. La géométrie livrée R2a-3.4 mesure `0,374 m`.** Elle
est donc, elle aussi, **sous le seuil**, d'un facteur deux.

Nous avons qualifié le candidat de « régression d'un facteur dix ». C'est exact
en relatif. Mais si le contrat n'a **jamais** été tenu hors du domaine des
stations, alors ce que la passe précédente a découvert n'est pas une régression
introduite par R2a-3.5.2 : c'est une **violation de contrat préexistante que
personne ne pouvait voir**, faute d'instrument regardant là.

Les deux lectures commandent des corrections différentes — revenir au
comportement de R2a-3.4 suffirait dans un cas, pas dans l'autre.

Le `controle_epaisseur` étendu sera donc passé sur **trois** géométries :
`cc3596c5`, `8bc8b9f9` et `8bf1a1b3`. **Si R2a-3.4 échoue aussi, c'est un
résultat qui appartient au lead** : il ne peut servir ni à abaisser un seuil, ni
à requalifier le défaut en non-problème.

**Statut : NON VÉRIFIÉ.** La mesure sur R2a-3.4 n'existe pour l'instant qu'en un
point (`0,374 m` en `(0,80 ; 6,00)`), pas sur le domaine complet.

---

## 33. R2a-3.5.3 — CLÔTURE. Le candidat est PERCÉ ; la géométrie livrée ne l'est pas.

### 33.1 BLOQUANT — un trou de 160 × 200 mm vers le ciel, au-dessus de la galerie

**FAIT REPRODUIT.** Preuves :
`evidence/world_v2/v2_3_r2a/grotte/r2a353_percee/`.

Ce que R2a-3.5.2 appelait « une lame de roche de 3,8 cm » n'est pas une lame :
c'est le **bord d'un trou**.

Test : depuis un point **dans la galerie** (`z = 1,50`), compter les traversées
en **montant**. Zéro = on voit le ciel. Fenêtre de 30 × 30 cm, **3 721 colonnes
au pas de 5 mm**, avec garde-fou exigeant de la roche **en dessous** :

| géométrie | colonnes ouvertes | aire ouverte | boîte |
|---|---:|---:|---|
| **candidat `cc3596c5`** | **343 / 3 721** | **85,8 cm²** | 160 × 200 mm |
| **`BASE352`** | **343** | **85,8 cm²** | identique |
| **R2a-3.4 LIVRÉE** | **0** | — | — |

**Corrigé après coup** : j'avais publié « 160 × 200 mm » seul, ce qui est la
**boîte englobante** et **surestime** l'ouverture — les 343 colonnes couvrent
85,8 cm², soit 27 % de cette boîte, équivalent à un disque de 104 mm. L'agent C
annonce 20 × 20 mm, mesuré à 2 cm : c'est le **noyau**, et cela sous-estime.
**Le nombre à citer est l'aire.**

`x ∈ [0,468 ; 0,623]`, `y ∈ [5,850 ; 6,045]` en repère modèle. **Hérité de
l'enveloppe R2a-3.5.2, pas du lot collerette.**

**Trois chemins indépendants concordent** : le **genre** (candidat genre 1, sur
une forme qui devrait être de genre 0) l'annonçait avant toute inondation ;
l'**inondation sans parité** de l'agent C le localise (`RC=1` au pas 0,06, la
plage bascule de `[0,139 ; 1,579]` à `[0,139 ; 9,379]` en `y = 5,895`) ; et ma
**connexité par colonnes** lisait déjà `première 0,002 m · cumul 0,002 m` en
`(0,60 ; 5,90)` — deux millimètres de roche — **avant** que le trou soit nommé,
sans que je l'aie lu pour ce que c'était.

**La géométrie livrée est étanche au même pas** : oracle depuis le tronc,
`VERT, RC=0` à 0,10 **et** à 0,06. La comparaison n'est pas biaisée par la
résolution ; le même oracle rend VERT à 0,10 sur le candidat et **ROUGE à 0,06**.
Un portail dont le pas dépasse la taille du défaut ne dit rien.

**Deux tests faux avant le bon, de ma main** : compter *tous* les croisements de
la verticale ne peut pas voir une percée — le rayon traverse le trou puis coupe
le plancher — et j'ai failli **réfuter un résultat juste** avec. Puis « zéro
traversée au-dessus » peut vouloir dire « déjà au-dessus du massif » ; le
garde-fou a mesuré **0 colonne écartée**, mais il fallait le vérifier.

### 33.2 La lecture de R2a-3.5.2 ne survit pas à la mesure complète

`evidence/world_v2/v2_3_r2a/grotte/r2a353_connexite/`.

« Régression d'un facteur dix sur l'épaisseur » était le minimum dans une
**fenêtre** de 5 × 3 m. Sur le domaine complet, roche mince **au-dessus de la
galerie jouable** :

| géométrie | mince sur la galerie | membrane interne | bulle isolée |
|---|---:|---:|---:|
| candidat | **205** | 0 | 11 |
| `BASE352` | **276** | 0 | 6 |
| R2a-3.4 LIVRÉE | **202** | 64 | 307 |

Candidat et livrée sont **équivalents** sur ce critère. Le lot collerette
**améliore réellement** : 276 → 205, soit **−26 %**. Et la livrée porte **307
bulles internes** contre 11 — ISS-050 à l'échelle.

**La vraie régression n'était donc pas l'épaisseur ; c'est l'étanchéité.** Et le
débat sur le niveau d'épaisseur à viser devient secondaire : un trou n'est pas un
débat de seuil.

### 33.3 Les trois agents

| agent | livré | reproduit par l'intégrateur |
|---|---|---|
| **A — toiture** | `controle_epaisseur_domaine()` (257 lignes, 4 constantes neuves, **0 seuil touché**), 7 outils de toit, contrôle négatif fermé concluant | ✔ 167/232/**326** plaques, min **0,020 m** sur la LIVRÉE |
| **B — adverses** | **10/10** + banc `--mutations` (5 mutations dont un **témoin inerte**) | ✔ `RC=0` sur les deux, y compris **depuis le tronc** |
| **C — oracle** | oracle sans parité ni vote, batterie 7/7, sabotages par booléen **fermé** | ✔ percée reproduite indépendamment au pas de 5 mm |

**Chacun a trouvé et publié un défaut dans son propre travail** — A mesurait les
**deux** maillages du GLB, la coque de collision rebouchant la galerie, ce qui
lui a fait conclure un moment que le défaut n'existait pas ; B a découvert que
son sabotage visait une direction **devinée**, fausse de 90° ; C a trouvé quatre
défauts dont un `χ` impair causé par un **sommet pincé**, invisible à tout
compteur d'arêtes.

**B a aussi vu que son propre banc de mutations ne savait dire que « détectée »**
— un test qui ne peut pas échouer, l'anti-motif déplacé d'un cran — et y a ajouté
un témoin inerte qui doit rester vert.

### 33.4 Ce qui est versé au tronc, et ce qui ne l'est pas

**Versé** — instruments seuls, aucune géométrie, aucun seuil : suite adverse,
banc de mutations, 7 outils de toit, 5 outils d'oracle, instruments calibrés du
lot précédent, `cave_topology_check.py`, `cave_void_connectivity.py`. **Les cinq
familles tournent vertes depuis le tronc**, vérifié avant commit.

Deux **fusions** plutôt que deux écrasements : `tools/CLAUDE.md` et
`plot_cave_section.py` auraient perdu du travail si j'avais pris le blob du lot.

**Non versé, conservé en patch** (`r2a353_lots_non_integres/`) : la base
R2a-3.5.2, la source collerette, et le `controle_epaisseur_domaine()`. **Pas
parce qu'il rougit** — il rougit à juste titre. Parce qu'il ne peut pas être
versé seul : l'ensemble donnerait un dépôt dont la source dit R2a-3.5.2, dont
l'artefact est R2a-3.4, et dont la chaîne refuse de les réconcilier. Un tronc qui
ment sur lui-même est pire qu'un tronc incomplet.

### 33.5 Verdict du gate §5

**ROUGE**, sur un item indivisible : *0 percée confirmée*. Le candidat porte un
trou de 160 × 200 mm vers le ciel, au-dessus de l'espace jouable.

Verts par ailleurs, et ils restent acquis : 10 épreuves adverses décisives ·
batterie d'oracle · 0 bord libre · 0 non-manifold sur le candidat · une seule
composante rocheuse · récompense et salle dans la même composante de vide ·
14 seuils inchangés · aucun domaine gelé touché · GLB byte-reproductible
(4ᵉ confirmation, la 1ʳᵉ avec instruments).

### 33.6 Prochaine action exacte

1. **Le trou est dans l'enveloppe R2a-3.5.2**, présent sur `BASE352`. Toute
   reprise part de là, pas de la collerette — qui, elle, **améliore** et devrait
   être conservée.
2. **Étendre le domaine des sondes au-delà de `ay = 3,17`.** C'est la cause
   commune du toit mince, de la collerette sous-mesurée, des quatorze occurrences
   d'échantillonnage — **et de cette percée**. Le domaine, pas la méthode.
3. **Rejouer tout portail d'étanchéité à `--pas 0.06` au minimum.** À 0,10 le
   trou est invisible.
4. La question du niveau d'épaisseur à viser (§32.6) **reste ouverte**, mais elle
   n'est plus bloquante : elle ne se pose qu'une fois l'enveloppe étanche.

---

## 34. R2a-3.5.4 — ouverture. Le domaine est écrit AVANT la correction.

**R2a-3.5.3 reste définitivement `PARTIAL`.** Cette passe ferme la percée et
qualifie le portail.

Point de départ imposé `a4fa7b1` — vérifié : branche, HEAD local == distant,
arbre propre, aucun processus lourd.

### 34.1 Arbitrage du lead, reçu et appliqué

- **la percée est réelle et bloquante** — 85,8 cm² d'aire ouverte, à ne jamais
  confondre avec sa boîte englobante de 160 × 200 mm ;
- **l'enveloppe R2a-3.5.2 n'est pas abandonnée** : la reprise part du défaut
  d'enveloppe, **pas de la collerette**, qui réduit les zones minces de 276 à 205
  et doit être conservée ;
- **`EPAISSEUR_MIN_M = 0,80` reste strictement inchangé** ; c'est son **domaine**
  qui est clarifié.

### 34.2 `a4e91dc` — le contrat, committé AVANT toute géométrie

`docs/CONTRAT_COQUE_STRUCTURELLE.md`. **C'est le premier commit de la passe, et
son antériorité se vérifie dans Git** : un domaine de mesure choisi *après* avoir
vu le résultat n'est pas un contrat, c'est une justification.

Ce qu'il fixe :

| | |
|---|---|
| **coque structurelle** | surfaces rocheuses séparant l'air intérieur canonique de l'extérieur. Définition **topologique** — ni station, ni `ay`, ni distance à un axe. **Aucun point écarté au motif qu'il est au-delà de `ay = 3,17`** |
| **épaisseur** | distance **euclidienne** à la surface extérieure la plus proche. Sans convention de direction, **minorante**, et sous-estimant encore de −0,76 à −1,12 × pas sur grille. On publie la lecture **et** la borne `lecture − pas` ; **le gate se prononce sur la borne** |
| **balayage vertical** | **conservé, déclassé en télémétrie** de non-régression. Motif mesuré : il rend 326 plaques sur R2a-3.4 déjà validée visuellement contre 167 sur le candidat — un critère qui condamne plus fort la référence que le sujet ne peut pas décider seul |
| **deux gates durs** | topologique **d'abord** — mesurer l'épaisseur d'une coque trouée n'a pas de sens — puis épaisseur |
| **résolution** | portail d'étanchéité à **0,06 m maximum**, raffinement adaptatif à **0,005**. Le même oracle rend VERT à 0,10 et ROUGE à 0,06 sur la même géométrie |

Le contrôle historique sur les stations **reste actif** : il n'est ni retiré ni
affaibli, il cesse d'être la seule chose qui regarde.

### 34.3 Socle `1580711`, et le piège qu'il fallait éviter

Worktree `/home/user/zelda-r2a354/socle`, détaché sur `a4e91dc`, plus quatre
applications locales **jamais poussées**.

**Le tronc porte désormais les instruments de R2a-3.5.3.** Appliquer la base
R2a-3.5.2 à l'aveugle aurait **révoqué** `plot_cave_section.py` et
`probe_cave_openings.py`, ramenés d'un état base+instruments à un état base seule.
Vérifié fichier par fichier avant application : **7 fichiers portés, 2 laissés au
niveau du tronc**. Les quatre instruments témoins sont confirmés identiques à
`a4e91dc` après construction.

### 34.4 Les trois agents

| agent | worktree | propriété exclusive |
|---|---|---|
| **A — percée** | `zelda-r2a354/a_percee` | `make_waterfall_cave.py`, `tools/cave_fix_*.py` |
| **B — portail** | `zelda-r2a354/b_portail` | `tools/cave_oracle_*.py` |
| **C — vérification** | `zelda-r2a354/c_verif` | `tools/cave_check_*.py` |

**Une dépendance d'ordre, explicite** : le socle porte le
`controle_epaisseur_domaine()` **câblé en gate**, donc la chaîne sort `RC=1`.
L'agent A doit le **reclasser en télémétrie avant de pouvoir exporter** — ce qui
applique l'arbitrage écrit, et n'est pas neutraliser un test : le gate dur devient
la coque, mesurée par borne minorante.

**Le livrable le plus important de la passe est celui de l'agent C** : rendre le
contrat **exécutable**. Ses six étapes n'existent aujourd'hui qu'en prose.

---

## 35. R2a-3.5.4 — RETRAIT : l'aire de la percée n'a jamais été mesurée valablement

**FAIT REPRODUIT.** Preuves :
`evidence/world_v2/v2_3_r2a/grotte/r2a353_percee/` (bandeau de retrait en tête).

### 35.1 Ce qui est retiré

**Les aires : 85,8 cm², 2 638 cm², équivalent disque 104 mm.** Toutes.

La directive R2a-3.5.4 les reprend comme un acquis — *« aire mesurée :
85,8 cm² »*. **Elles ne le sont pas**, et il faut le dire avant qu'elles ne
servent de référence à une correction.

### 35.2 Pourquoi la mesure est invalide

Le test employé — *« depuis `z = 1,50`, zéro traversée en montant, avec de la
roche en dessous »* — compte en réalité **toute colonne dont le sommet du
maillage est sous `z = 1,50`**. Il confond :

- un **toit absent** au-dessus de la cavité ;
- une **enveloppe simplement plus basse** à cet endroit.

Le garde-fou que j'avais ajouté — exiger de la roche **en dessous** — écarte les
colonnes hors du solide, mais **pas** celles situées au-dessus d'un massif plus
bas que 1,50. C'est le cas majoritaire dès qu'on quitte la zone haute.

### 35.3 Le contrôle qui l'a montré, et qui manquait

Élargissement progressif de la fenêtre, candidat contre R2a-3.4 :

| fenêtre | contrôle R2a-3.4 | « aire » candidat |
|---|---:|---:|
| 0,30 × 0,30 m | 0 | 85,8 cm² |
| 1,20 × 1,60 m | 0 | 2 704 cm² |
| 2,20 × 2,50 m | 0 | 8 208 cm² |
| 3,20 × 3,50 m | 0 | 19 412 cm² |
| 4,20 × 4,50 m | 0 | **47 264 cm²** |

**Un trou ne grandit pas quand on élargit la fenêtre.** Et le zéro constant de
R2a-3.4 n'est pas une validation : il s'explique par un **massif plus haut**, pas
par son étanchéité. J'avais lu ce zéro comme un contrôle ; ce n'était qu'une
coïncidence de hauteur.

### 35.4 Ce qui tient, et par quels chemins

**La percée est réelle.** Deux méthodes, aucune ne passant par cette métrique :

| géométrie | `χ` | genre | lecture |
|---|---:|---:|---|
| candidat `cc3596c5` | 0 | **1** | une anse, sur une forme qui devrait être de genre 0 |
| R2a-3.4 livrée | −2 | 2 | deux anses — arches, étanchéité confirmée par l'oracle |
| **corrigée R2a-3.5.4 `c184c8dc`** | **2** | **0** | **l'anse a disparu** |

plus la trace d'inondation sortant en `(0,618 ; 5,895)` au pas de 0,06.

**L'agent A a donc bien fermé la percée** — genre 1 → 0, 0 bord libre,
0 non-manifold — et par une mesure qui ne dépend d'aucune convention d'altitude.
Sa géométrie est topologiquement **plus propre que la livrée**.

### 35.5 Ce qui reste inconnu

**L'aire réelle de l'ouverture.** Elle se mesurerait comme l'aire des faces de la
**coupure** entre air intérieur et air extérieur — pas comme un compte de
colonnes. **Elle n'est pas nécessaire au verdict** : le genre tranche.

Statut : **`NON VÉRIFIÉ`**, et il n'y a pas lieu de le lever pour clore la passe.

### 35.6 La leçon, à mon débit

> **Un contrôle sur une géométrie saine, dans la même fenêtre, avant de publier
> un chiffre.**

Je l'ai appliqué à l'oracle, aux épreuves adverses, à la connexité. Je ne l'ai
pas appliqué à ma propre métrique d'aire, parce qu'un zéro obtenu au premier
essai ressemble à une validation. C'est la troisième correction que je porte sur
ce même chiffre — d'abord une boîte englobante prise pour une aire, puis une
fenêtre trop étroite, enfin la métrique elle-même. Les deux premières le
raffinaient ; celle-ci le retire.

---

## 36. R2a-3.5.4 — CLÔTURE. La percée est fermée ; la coque est trop mince.

**Verdict : `PARTIAL`.** Un item du gate échoue, mesuré et reproduit par
l'intégrateur. Preuves : `evidence/world_v2/v2_3_r2a/grotte/r2a354_gate/`.

### 36.1 Le gate, item par item

| item | verdict | mesure | reproduit |
|---|---|---|---|
| **topologique** | **PASS** | genre 1 → **0** · oracle `ROUGE → VERT` à 0,06 · barrière duale valide dès `ay = −1,615` | intégrateur, **3 chemins disjoints** |
| **batterie d'oracle** | **PASS** | **8/8 CONFORME**, 1 tentative, placebo compris, sur genres 0, 1 et 2 | intégrateur, `RC=0` |
| suite adverse · mutations · topologie | **PASS** | `RC=0` depuis le tronc | intégrateur |
| **épaisseur de coque** | **FAIL** | lecture **0,6613 m** · borne garantie **0,5613 m** (`h = 0,10`) · seuil **0,80 m** | intégrateur, `RC=1` |

**Argmin : `(1,036 ; 5,173 ; 2,316)` en repère modèle — `ay = 5,17`, deux mètres
au-delà de la dernière station de `CAVITE`.**

`FAIL` **mesuré sur la lecture**, pas `BLOQUÉ` de résolution : le troisième
verdict du contrat (§5.1) ne s'applique pas, la lecture elle-même étant sous le
seuil.

### 36.2 Le contrat a attrapé ce qu'il avait été écrit pour attraper

C'est le résultat de méthode de la passe, et il vaut plus que le verdict.

`CONTRAT_COQUE_STRUCTURELLE.md` est committé à `a4e91dc`, **avant** toute
correction géométrique — antériorité vérifiable dans Git. Il attrape un défaut à
`ay = 5,17`. **L'ancien `controle_epaisseur`, borné à `ay = 3,17`, ne pouvait pas
le voir.** C'est mot pour mot la clause du §2.4 :

> *Aucun point de la coque ne peut être écarté au motif qu'il se trouve au-delà
> de la dernière station de `CAVITE`.*

Quinzième occurrence de la même cause de fond depuis le début de la série.

### 36.3 Ce qui est acquis, et ne l'était pas il y a une passe

**La percée est fermée à la source**, par trois chemins indépendants : genre
(1 → 0), inondation (`ROUGE C3 → VERT` au pas 0,06), graphe dual (aucune barrière
valide sur `cc3596c5` à aucun `ay` ; valide dès `ay = −1,615` sur la corrigée).
Une grotte à une seule bouche est topologiquement une bosselure — genre 0. La
corrigée l'atteint, quand la géométrie **livrée** porte genre 2.

**La cause est nommée** : le vide n'existait à **aucune étape source**, il était
**creusé par le booléen**. `OUTIL_Cavite` déborde à `y = +7,245` quand la dernière
station est à `3,17` ; `hw · gauche` atteint `4,23 m` et la normale y est à ~85 %
alignée avec `−Y`. Le gabarit intérieur est intouchable ; ce qui manquait, c'est
la roche qui aurait dû le couvrir.

**Le portail d'oracle est devenu générique** : 8/8 sur trois genres différents,
une seule tentative par contrôle, restauration byte-identique.

### 36.4 Les cinq précisions de l'addendum, une par une

| précision | ce qui a été fait |
|---|---|
| **gel du contrat à `cca1778`** | respecté. Deux ambiguïtés rencontrées → publiées au lead, **aucune** modification rétroactive du contrat |
| **ordre des gates** | le déclassement de `controle_epaisseur_domaine()` **n'est PAS appliqué**. Il reste dans le patch de l'agent A, non intégré : le gate de remplacement existe mais **échoue**, donc son contrôle négatif ne l'a pas encore qualifié dans un état vert. La reclassification est un commit de politique **séparé**, et son moment n'est pas venu |
| **circularité topologique** | **tranchée par la mesure**, sous un plafond `z ≤ 1,20` qui exclut la percée par construction. Le vide ciblé est en composante 3 — celle de `SALLE` et `NICHE` — **avant comme après**. 5 composantes d'air des deux côtés : aucune bulle isolée créée. Ce n'était pas un défaut de vide mais de **couverture**, et la correction ajoute la roche au-dessus. Détail : `r2a354_percee_fermee/CIRCULARITE.md`, mes deux runs concordant ligne pour ligne avec ceux de l'agent |
| **certificat de couverture** | le premier jet de l'agent C mêlait critère de circonrayon et échantillons au centroïde — incohérent, 3,52 % de dépassement mesuré sur un triangle rectangle isocèle. Corrigé en centroïde + `max‖V−G‖` avec subdivision aux milieux d'arêtes, fixture obtuse comprise. `h` accompagne la borne partout |
| **tâches arrêtées** | les trois worktrees `r2a354/{a_percee,b_portail,c_verif}` inventoriés avant relance ; aucun agent dupliqué ; fichiers et commits préservés |

### 36.5 Deux questions qui remontent au lead, non tranchées ici

**1. L'emprise du masque de bouche n'est pas définie par le contrat.** Le §2.5
dit *« seule la bouche canonique, explicitement masquée, est exclue »* sans fixer
son emprise. Le verdict ne bouge pas — `FAIL` sous les deux lectures — mais la
**cause publiée** change du tout au tout : emprise 0,00–1,50 m donne
`0,0216 → 0,0565 m` collé au rebord du porche ; emprise 2,00 / 3,00 m donne
**0,6613 m** à `ay = 5,17`. Le contrat étant gelé, l'agent a refusé de trancher et
publié la courbe entière. **C'est la conduite exigée par le gel.**

**2. « 0 auto-intersection » contre une tolérance de 0,020 m.** Le livrable porte
**2 paires, repli 0,000612 m**, **pré-existantes** — le candidat les portait déjà.
Le contrôle du générateur passe ; le libellé du gate dit « 0 ». Attribution
mesurée : le repli **naît à la décimation**, et une seconde fragilité — un
triangle d'**aire rigoureusement nulle** en `(−1,504 ; −3,099 ; −0,639)` — **naît à
la soustraction**. R2a-3.4 survit au CSG parce qu'elle porte quatre triangles
*presque* dégénérés mais **aucun exactement nul** : le critère n'est pas « petite
face », c'est « aire nulle ». **Deux défauts distincts, tous deux dans la chaîne,
aucun dans la source** — donc des tickets, pas une passe.

### 36.6 Ce qui n'est pas fait, et pourquoi

- **aucune capture** — le gate est rouge, la directive l'interdit ;
- **aucun export livrable** — la géométrie corrigée `c184c8dc` reste **en patch**,
  `agentA_calotte_nord_ET_reclassement.patch`, 321 lignes ;
- **aucune propagation**, aucun `validate_fast.sh`, aucune des 38 captures ;
- **le tronc construit et livre toujours R2a-3.4** (`8bf1a1b3`, commit `504ecbe`) ;
- **golden masters 3/4** inchangés ; ISS-052 et ISS-053 non touchés ;
- **aucun seuil abaissé, aucun test neutralisé.**

### 36.7 Prochaine action exacte

**Faire passer la coque à `≥ 0,80 m` autour de `(1,036 ; 5,173 ; 2,316)`**, par la
même correction préférée que la percée : **ajouter de la roche vers l'extérieur**,
sans toucher au gabarit intérieur, à la collerette, à la visière ni à l'orteil.

**Première question à trancher, et elle n'est PAS tranchée ici : l'argmin
tombe-t-il sous la calotte nord, ou à côté d'elle ?** Les deux causes appellent
des corrections opposées — épaissir la couverture posée, ou étendre son emprise.
Ce que je sais et ce que je ne sais pas :

- la calotte est paramétrée en abscisse **le long du chemin**, `CALOTTE_U0 = 3,50`
  → `CALOTTE_U1 = 7,20`, azimuts `100°` → `176°`, plafond `4,00 m` ;
- **la correspondance entre cette abscisse et `ay` n'a pas été vérifiée.** Lire
  `5,17 ∈ [3,50 ; 7,20]` serait comparer un paramètre de courbe à une coordonnée
  — exactement le genre de raccourci qui a produit les quatorze occasions
  précédentes.

Leviers data-driven disponibles une fois la question tranchée :
`CALOTTE_COUVERTURE_M = 1,60`, `CALOTTE_ECHELLE = (1,00 ; 1,00 ; 0,55)`,
`CALOTTE_U0/U1`, `CALOTTE_THETA0/THETA1`.

Séquence imposée, dans cet ordre :

1. corriger la géométrie, mesurer avec `cave_check_hull.py`, obtenir la **borne
   garantie** `≥ 0,80` ;
2. **puis seulement** qualifier le gate de remplacement par son contrôle négatif
   complet — sain → sabotage fermé → ROUGE attendu → restauration byte-identique
   → VERT ;
3. **puis** le commit de politique séparé qui déclasse
   `controle_epaisseur_domaine()`, non mêlé au diff géométrique ;
4. **puis** l'export, les captures, le gate.

Deux tickets à ouvrir, indépendants de la passe : repli à la décimation, triangle
d'aire nulle à la soustraction.

---

## 37. R2a-3.5.5 — ouverture. Le socle est prouvé fidèle, et un instrument était mort.

Départ imposé `0cdfd91` — vérifié : branche `claude/world-v2-reconstruction`,
HEAD local == distant, arbre propre, aucun processus lourd. **Aucune branche
parallèle créée** ; `claude/world-v2-reconstruction-khgmlu`, que le cadrage de
session nomme, n'existe nulle part et les SHA du lead vivent ici.

### 37.1 `f27b44c` — l'addendum du masque, committé AVANT toute géométrie

`docs/ADDENDUM_MASQUE_BOUCHE.md`. Il **instancie** la clause §2.5 du contrat gelé
`cca1778` sans le modifier, et son antériorité se vérifie dans Git.

**Le changement est de nature, et il durcit le gate.** Le masque ne retire plus
une zone de la mesure : il la **classe** à 0,60 m quand le reste est à 0,80 m.
Plus rien n'est exempté.

L'instruction du lead — dériver le masque des repères de R2a-3.4 — n'était
exécutable qu'à une condition, vérifiée grandeur par grandeur **avant** de
l'affirmer :

| grandeur | R2a-3.4 | R2a-3.5.x | verdict |
|---|---|---|---|
| `CAVITE` stations 0 et 1 (porche, seuil) | `(0,-1.15,1.90,2.80)` · `(0,0,1.70,2.85)` | **identiques**, annotée « seuil — INCHANGÉ » | utilisable |
| `MODELE_SEUIL_DEHORS` | `(0.0, 0.10, 1.60)` | **identique** | utilisable |
| `SEUIL_LOCAL` · `LACET_DEG` · `EXHAUSSEMENT` | `(4.0,-2.5)` · `45.0` · `0.50` | **identiques** | utilisable |
| `MODELE_SALLE` | `(1.05, 0.22, -6.25)` | `(2.62, 0.09, -2.58)` | **divergent — interdit** |
| `MODELE_NICHE` | `(-1.20, 0.43, -8.20)` | `(2.78, 0.50, -4.09)` | **divergent — interdit** |

R2a-3.5.2 a **raccourci et coudé** la galerie — salle de `ay = 6,25` à `2,58`,
dernière station de `9,25` à `3,17`, coude de 42° — mais **n'a pas touché la
bouche**. Le masque n'emploie que des grandeurs stables. S'il avait eu besoin de
`MODELE_SALLE`, l'instruction aurait été contradictoire et l'addendum se serait
arrêté en `BLOQUÉ`.

Trois points sans définition dans le dépôt, tranchés **avant** mesure : « première
section entièrement enfermée » (trois lectures incompatibles coexistaient), la
section balayée (le gabarit contractuel, la capsule ayant **trois** valeurs en
litige), et la classification collerette/coque (bande = le seuil lui-même, donc
aucune constante nouvelle).

> **L'emprise s'exprime en longueur d'arc, jamais en indice de station.** Les
> tables `CAVITE` diffèrent : `u = 2` vaut `ay = 1,60` dans l'une et `1,05` dans
> l'autre. J'avais écrit la comparaison fautive dans ce handoff avant de la
> retirer ; elle est maintenant interdite par écrit.

### 37.2 Le socle reproduit le candidat au bit près

Le tronc porte encore le générateur **de R2a-3.4** (`4c748d1`), inchangé depuis
31 commits : toute la géométrie R2a-3.5.2 → 3.5.4 vit hors tronc, en patches.

Rejouée sur `0cdfd91`, la pile de quatre patches rend un générateur dont l'écart
avec celui de l'agent A est **exactement** les 105 lignes du hunk de politique,
retiré ici — le déclassement ne pouvant venir qu'après qualification du nouveau
gate (addendum de cadrage §2).

**Preuve d'exécution : `c184c8dc0c0e754a`, 1 490 320 octets, byte-identique.**
Cinquième confirmation de reproductibilité de la série, et elle établit trois
choses d'un coup — la pile est fidèle, `--diagnostic` ne touche pas la géométrie,
la chaîne est déterministe.

Deux outils sont gardés **au tronc** plutôt qu'au patch : `probe_cave_openings.py`
et `probe_cave_edt_plan_bouche.py` portent des correctifs postérieurs à `c79341e`.
Appliquer le patch les aurait fait régresser.

### 37.3 L'appariement de R2a-3.4 est prouvé, plus supposé

Worktree neuf détaché sur `504ecbe`, chaîne rejouée : le GLB rendu est
`8bf1a1b3`, **1 506 684 octets, `cmp` identique au bit près**, et
`git status --porcelain assets/` reste vide. La chaîne est donc **déterministe de
bout en bout sur la géométrie canonique**, 60 commits et un worktree neuf plus
tard.

> **Précision qui compte.** `RC_MAKE=0` sur R2a-3.4 n'indique pas une meilleure
> conformité : `controle_epaisseur_domaine` a **zéro occurrence** dans le
> générateur de `504ecbe`. « 326 plaques sur R2a-3.4 » est le contrôle de
> R2a-3.5.3 appliqué **après coup** à sa géométrie — jamais un verdict que sa
> propre chaîne aurait rendu.

### 37.4 Gates reproduits par l'intégrateur

| mesure | R2a-3.4 `8bf1a1b3` | percé `cc3596c5` | corrigé `c184c8dc` |
|---|---:|---:|---:|
| bords libres · non-manifold | 0 · 0 | 0 · 0 | 0 · 0 |
| χ | −2 | 0 | **2** |
| **genre** | **2** | **1** | **0** |
| batterie d'oracle, pas 0,06 | — | — | **8/8 CONFORME**, 1 tentative |

`COL_WaterfallCave` est de genre 0 dans les trois cas.

### 37.5 Un instrument du tronc était mort, et son banc passait au vert

`tools/cave_topology_check.py` portait **trois chemins absolus** vers
`/home/user/zelda-r2a353/` — worktree de passe close, supprimé pour libérer du
disque — **et ignorait son argument de ligne de commande**. Découvert en voulant
reproduire mon propre gate.

Ce qui rend le défaut coûteux : **`--banc` passait au vert.** Un outil dont
l'auto-test réussit pendant que son chemin de production est mort est la panne
exacte que `PROMPT4_METHOD` §2 décrit. Le banc n'éprouvait que l'analyse ;
personne n'éprouvait la lecture. `MASTER_SPEC` §7.15 l'interdisait déjà.

Corrigé : chemins en argument, **aucun défaut**, `RC=2` et mode d'emploi sans
argument. **Balayage des 42 outils `cave_*` / `probe_cave_*` : c'était le
seul.** 34 démarrent, 5 échouent sur `bpy` (attendu hors Blender), 3 dépassent
60 s en travaillant. Le périmètre du dégât est mesuré, pas supposé.

### 37.6 Un manque réel, à ne pas habiller

**L'épaisseur de R2a-3.4 n'a jamais été mesurée.** Le journal de la passe
précédente s'arrêtait **sans `RC=`** et a été renommé
`coque_R2a34_INTERROMPU_SANS_RC.log` par son auteur.

Cause structurelle : la subdivision d'échantillonnage est 4-aire et **uniforme**,
et quelques triangles à grand rayon imposent leur profondeur à toute la face.

| géométrie | peau intérieure | échantillons à `h = 0,15` |
|---|---:|---:|
| `c184c8dc` | 95 m² | 114 376 — termine |
| **R2a-3.4** | **628 m²** | **16 854 916 — ne termine pas** |

Pas effectif ≈ 6 mm là où `h` valait 0,150. **La couverture reste prouvée ; c'est
le coût qui ne l'est pas.** Statut : `NON MESURÉE`, jamais « probablement bonne ».
Un instrument qui ne termine pas doit le dire — même règle que « une étape sautée
sort en 3, pas en 0 », appliquée au temps de calcul.

### 37.7 Disque : 147 Mo restants au démarrage

Le conteneur était **plein** ; la création des worktrees d'agents a échoué sur
`No space left on device`. Les dix worktrees des passes r2a352 et r2a353 étaient
tous propres — vérifié entrée par entrée avant suppression — et 15 Go ont été
libérés. Rien d'unique n'y vivait : outils sur le tronc, dossiers de preuve à
effectif identique, générateur reproduit dans le socle, GLB copiés.

---

## 38. R2a-3.5.5 — CLÔTURE. Au rebord d'une bouche, il n'y a pas d'épaisseur.

**Verdict : `PARTIAL`.** Le gate d'épaisseur ne peut pas être rendu décisif, et
c'est démontré plutôt que constaté. **Aucun export.** Le tronc continue de livrer
R2a-3.4 (`8bf1a1b3`).

### 38.1 La démonstration, reproduite par l'intégrateur

`h` visé divisé par 8, sur les deux géométries :

| `h` | R2a-3.4 **livrée et validée** | `lect./h` | `c184c8dc` | `lect./h` |
|---:|---:|---:|---:|---:|
| 0,400 | 0,00400 | **0,010** | 0,00800 | **0,020** |
| 0,200 | 0,00200 | **0,010** | 0,00400 | **0,020** |
| 0,100 | 0,00100 | **0,010** | 0,00200 | **0,020** |
| 0,050 | 0,00050 | **0,010** | 0,00100 | **0,020** |

**Le rapport `lecture / h` est exactement constant.** La lecture ne converge pas
vers une valeur finie : elle suit la résolution. C'est la signature mathématique
d'une **arête** — au contour de bouche la peau intérieure rejoint la peau
extérieure, et un échantillon posé à `r` du contour lit `r`.

> **Il n'y a pas d'épaisseur à mesurer là. Il y a un bord.**

Ce n'est donc pas un résultat sur ces deux géométries : c'est un résultat sur
**toute grotte pourvue d'une bouche**. Aucun seuil strictement positif n'y est
tenable. Et la géométrie **livrée est la plus mince des deux** — le critère la
condamne soixante-dix fois plus fort que le sujet, mot pour mot le motif qui a
déclassé `controle_epaisseur_domaine`.

### 38.2 D'où vient le trou, et il est dans MON addendum

L'ancien instrument **excluait** un voisinage géodésique du contour, avec la
phrase juste : *« au rebord même de la bouche l'épaisseur tend vers zéro : c'est
une arête, pas un défaut »*. Mon addendum a remplacé cette exclusion par une
**classification** — plus dur, comme le lead le demandait — sans provision pour ce
fait géométrique.

Et le masque ne peut pas rattraper : il commence à `s_dehors = −1,60` quand la
lèvre vit à `s ≈ −2,04`. **Aucune emprise vers l'intérieur ne la couvre.**

Je n'ai pas amendé l'addendum. Il a été écrit avant la mesure exactement pour
qu'un `FAIL` ne puisse pas le faire bouger. La provision de rebord — et surtout
son **emprise** — est une décision du lead.

### 38.3 La géométrie N'EST PAS intégrée, et c'est la décision de la passe

Trois mesures indépendantes disent que l'enveloppe R2a-3.5.2 **régresse le
porche** par rapport à ce qui est en ligne :

| mesure | R2a-3.4 livrée | candidat |
|---|---:|---:|
| roche **près** du rebord — sommets sous 0,80 m | **71** | 89 |
| idem, minimum | **0,363 m** | 0,283 m |
| coque de **collision** — paires | **7** | **62** |
| idem, enfoncement max | **0,020 m** | **0,457 m** |

Le second est le plus grave : 23 fois le seuil du visuel, **sur la géométrie qui
arrête réellement le joueur**, et aucun contrôle — ni l'ancien ni le nouveau —
n'a jamais été appelé sur elle. Elles étaient déjà là quand R2a-3.5.4 a déclaré
la percée fermée et le portail conforme.

**Cause mécanique nommée, non prouvée.** Les stations 0 et 1 sont identiques au
chiffre près entre les deux révisions — le générateur annote même « seuil —
INCHANGÉ ». Mais leur **voisine** a bougé : le segment sortant du seuil passe de
1,601 m à 1,073 m et le virage de 2,15° à 11,83°. Or `normale_de_cavite` oriente
la section par la **tangente** : une section de 1,90 m de demi-largeur pivotée de
près de 10° se cisaille, et un loft cisaillé se replie.

> **« Les stations de la bouche sont inchangées » ne garantit pas que la bouche
> est inchangée.**

Intégrer cette enveloppe livrerait un porche plus mauvais que celui en ligne.
**Les quatre patches de géométrie sont préservés et rejouables** sous
`r2a355_lots_non_integres/`.

### 38.4 Ce qui est acquis, et entre au tronc

| | |
|---|---|
| **addendum du masque** | `f27b44c`, committé **avant toute géométrie** ; ambiguïté du §2.5 **fermée** — le verdict est stable vis-à-vis de l'emprise, sur les trois géométries |
| **socle prouvé fidèle** | la pile de 4 patches rend `c184c8dc` **au bit près** |
| **appariement R2a-3.4 prouvé** | reconstruit depuis `504ecbe`, `cmp` identique, `git status assets/` vide |
| **gate topologique** | genre 2 / 1 / **0**, zéro bord libre, zéro non-manifold |
| **batterie d'oracle** | **8/8 CONFORME**, une tentative, placebo compris |
| **ISS-055 corrigée** | le contrôle d'auto-intersection testait des **plans** ; il publiait 0 là où il y en a 6, et 10 sur la livrée |
| **triangle d'aire nulle** | corrigé, attribution héritée **réfutée** — il naît de la triangulation d'export, pas de la soustraction |
| **dix instruments** | intégrés, tous parsent, aucun chemin absolu, chacun rend un code non nul sans argument |

### 38.5 Instruments morts, et ce que ça enseigne

`tools/cave_topology_check.py` portait trois chemins absolus vers un worktree
supprimé **et ignorait son argument**. Découvert en voulant reproduire mon propre
gate. **Son banc `--banc` passait au vert** : il n'éprouvait que l'analyse,
personne n'éprouvait la lecture. Balayage des 42 outils grotte : **c'était le
seul**. `diag_cave_etapes.py` (ISS-045) corrigé au passage.

### 38.6 Quatre corrections à mon propre travail

1. **Emprise du masque en indice de station** — les tables `CAVITE` diffèrent
   entre révisions ; corrigé en longueur d'arc **avant** commit.
2. **« L'argmin est au-delà du chemin »** — réfuté : le pied tombe dans un segment
   interne, `t = 0,9124` non écrêté. Les deux mètres d'`ay` sont **latéraux**.
3. **Outil de lèvre, deux versions invalides** — mesurait d'abord la longueur
   d'arête, puis la largeur des ouvertures. Attrapées parce que le chiffre était
   invraisemblable **sur une géométrie déjà validée**.
4. **« Le candidat est meilleur, 6 contre 10 »** — vrai sur le compte, **faux sur
   la sévérité** : les 10 de la référence sont sous le demi-micron.

### 38.6bis Le correctif de calotte marche, et l'écart restant est BORNÉ

Rapport final de l'agent A, arrivé après la première rédaction de cette section
et qui en corrige le ton :

| | avant | après |
|---|---:|---:|
| lecture / borne | 0,6613 / 0,5613 | 0,6813 / 0,5813 |
| argmin | `(1,036 ; 5,173 ; 2,316)` | `(3,039 ; 1,920 ; 1,704)` |
| **direction** | **97,1 % verticale** | **98,2 % horizontale** |
| **échantillons sous 0,80 m** | 2 216 | **1 122 — −49,4 %** |
| **points sous 0,60 m** | — | **0** |

**Au point visé**, certificat local `h = 0,05`, rayon 0,30 m : lecture
**1,1777 m**, borne **1,1277 m**, zéro point sous seuil. La cible de la passe —
mesure centrale ≥ 0,90, borne ≥ 0,85 — est **dépassée**.

**La distribution est groupée** : 5 amas → 3, le plus gros à 67,8 %, **97 % des
points restants entre 0,70 et 0,80 m**. Ce n'est pas une coque mince partout,
c'est une **bande étroite**, bornée et localisée. L'argmin a changé de **nature** :
zénithal avant, **latéral sur la joue droite** après — que la calotte ne couvre
pas par construction (azimuts 100→176°, côté `−n`). Le même levier ne s'y applique
pas.

Non-régression : genre 0, 0 bord libre, 0 non-manifold, composition 3/3/3, ratios
2,16 / **2,37** / 2,25 — le ratio central *monte*, domaine 29 → 28 plaques,
connexité identique, aucune bulle nouvelle.

**Ma réserve sur le périmètre de bouche est RÉFUTÉE.** Aux deux pas de balayage,
**99** arêtes bordent la peau intérieure et **56** faces amorcent le front —
identiques ; les 434 autres sont ignorées, et les deux exécutions publient des
tables identiques au point près. Le défaut est une **étiquette** : le champ dit
« périmètre de la bouche » et publie le contour de coupe complet. **Ticket.**

### 38.7 Prochaine action exacte

**Deux décisions du lead, dans cet ordre.**

1. **La provision de rebord.** Quelle emprise géodésique autour du contour de
   bouche est exclue des deux seuils ? L'ancien instrument en avait une ; mon
   addendum l'a supprimée. Sans elle, aucun gate d'épaisseur ne peut passer.
   Le diagnostic hors contrat de l'agent C, à marge 0,60 m, donne l'ordre de
   grandeur : la référence remonte à 0,0094 m et le candidat à 0,6610 m.
2. **Faut-il réparer le porche de R2a-3.5.2 avant de l'intégrer ?** La régression
   est mesurée et attribuée. L'hypothèse du cisaillement de tangente est
   réfutable en rallongeant le segment sortant sans toucher aux stations 0 et 1.

**Quatre tickets ouverts** : ISS-054 (collision, `S2`), l'angle mort de
triangulation (10,9 % des triangles divergent entre `bmesh` et l'exportateur —
le « 4 » du générateur est un **minorant** du « 6 » réel), la décimation
(4 pénétrations nées au collapse), et l'étiquette « périmètre de la bouche » de
`cave_check_hull.py`, qui publie le contour de coupe complet — le critère « la
plus extérieure des barrières valides » est **dégénéré**, les deux enfermant
exactement 95,19 m².

**Ce que la mesure dit du seuil lui-même**, et qui devrait peser dans la
décision : hors rebord, l'écart restant est **1 122 échantillons dans une bande
de 0,70 à 0,80 m, en trois amas**, sans **aucun** point sous 0,60. La coque
serait donc **entièrement conforme à un seuil de collerette de 0,60 m**. Le
problème n'est pas systémique ; il est borné et localisé.

---

## ANNEXE A — chronologie des instruments et de leurs défauts

Quatorze occurrences du **même** défaut : un contrôle place ses points à
`ax + f·hw`, symétriquement et le long de X monde, sur une cavité devenue
asymétrique et dont l'axe tourne. Il mesure alors une station pour une autre.

| # | site | passe |
|---:|---|---|
| 1–6 | dont `points_interieurs`, `dans_enveloppe`, `sort_par_la_bouche`, `dans_le_noyau`, `_emprise_noyau` | R2a-3.5.1 |
| 7 | `carte_du_plancher` | R2a-3.5.2, trouvé par l'agent A |
| 8 | `carte_du_fond` | R2a-3.5.2, agent C |
| 9 | `surface_de_sortie` | R2a-3.5.2, agent C |
| 10 | `u_pour_y` sur point décalé | R2a-3.5.2, agent C |
| 11 | sol attendu lu à la station nominale | R2a-3.5.2, agent C |
| 12 | `sort_par_la_bouche` ignorait `PALIER[0]` | R2a-3.5.2, agent C |
| 13 | `ENCLOSURE_MIN` | R2a-3.5.2, agent C |
| 14 | `offsets_lateraux` prenait `max(nominale, mesurée)` | R2a-3.5.2, agent C |

`points_interieurs` portait le commentaire « SIXIÈME ET DERNIER ENDROIT DE LA MÊME
FAUTE ». **Il n'était pas le dernier.** Un commentaire qui affirme une exhaustivité
sans test qui l'établisse est une promesse, pas un constat. Le tableau
`FAMILLE_REPERE_LOCAL` n'a désormais **pas de ligne finale**, à dessein.

Trois inversions supplémentaires, **de ma main**, dans
`audit_cave_floor_columns.py`, toutes la même erreur de lecture :

1. « parité impaire = vide ouvert » — c'est l'exact contraire : un rayon
   descendant qui compte un nombre impair d'impacts a fini sa course **dans** la
   roche. Trois colonnes dont le rayon s'enfonçait de trois mètres déclarées
   trouées ;
2. `sous = None` traité comme « pas de plancher » — même inversion, autre branche
   du même fichier, vingt minutes plus tard. Quatre colonnes du tronc, au sol
   infiniment épais, déclarées trouées ;
3. le minimum d'épaisseur ignorait la fenêtre du verdict — « minimum 2,521 m »
   imprimé alors que la fenêtre était sabotée, chiffre exact mesuré ailleurs.

Règle inscrite dans `tools/CLAUDE.md` : **quand un rayon cesse de rencontrer des
faces, cela veut dire PLEIN**, et cette lecture s'écrit **une** fois, dans une
fonction nommée — pas une fois par branche.

---

## ANNEXE B — le repère local, et pourquoi il fallait un pas métrique

`cave_frame.py` publie par station : tangente, normale latérale, verticale,
largeur côté `+normale`, largeur côté `−normale`, sol, toit.

Le pas latéral est **métrique** et non une fraction de la demi-largeur. Raison
donnée par l'agent : une fraction espace **six fois plus** les points du côté
large — celui de l'alcôve — et ne peut donc porter aucune garantie de couverture.

Table `CAVITE_ASYM` en vigueur, `(gauche, droite, inclinaison)` :

```python
CAVITE_ASYM = [
    (1.34, 0.79, -0.44),   # porche — GELÉ
    (1.30, 0.81, -0.40),   # seuil — GELÉ
    (0.56, 1.15, -0.24),
    (0.97, 1.05, 0.10),
    (1.68, 0.41, 0.16),
    (1.69, 0.33, 0.08),    # SALLE, déportée
    (1.69, 0.25, -0.06),
    (1.65, 0.27, -0.12),
    (1.61, 0.25, -0.10),
]
```

`droite` est le côté `+normale` — vérifié deux fois contre la mesure. La
troisième composante **incline la clé** : à la bouche, une clé nominale de 2,80
avec une inclinaison de −0,44 donne une voûte réelle de **4,03 m au bord gauche et
1,57 m au bord droit**.

Table `CAVITE` en vigueur `(ax, ay, hw, cle)` :

```python
CAVITE = [
    (0.00, -1.15, 1.90, 2.80),   # porche évasé, sol sous le terrain
    (0.00,  0.00, 1.70, 2.85),   # seuil — INCHANGÉ
    (0.22,  1.05, 1.75, 2.90),   # fin du vestibule
    (1.00,  1.62, 2.10, 2.90),   # LE COUDE, 42°
    (1.82,  2.12, 2.60, 2.92),
    (2.62,  2.58, 3.00, 2.92),   # SALLE, sous la dominante
    (3.10,  2.88, 2.50, 2.80),
    (3.40,  3.06, 1.85, 2.45),   # alcôve / niche
    (3.58,  3.17, 1.30, 2.00),   # calotte du fond
]
PALIER = (0.00, 0.00, 0.02, 0.06, 0.10, 0.16, 0.34, 0.56, 0.70)
```

Repères de gameplay, dans `scripts/world_v2/poi/waterfall_cave_place.gd`, tels que
posés par `c79341e` — **repère MODÈLE, `Godot = (ax, z, −ay)`** :

```gdscript
const MODELE_SALLE: Vector3 = Vector3(2.62, 0.09, -2.58)
const MODELE_NICHE: Vector3 = Vector3(2.78, 0.50, -4.09)
seuil.position = Vector3(0.15, 1.50, -1.20)
salle.position = Vector3(2.70, 1.90, -3.35)
```

Hauteurs de sol **mesurées** par `controle_sol_repere` : salle +0,084, niche
+0,492, voisin +0,244.

---

## ANNEXE C — seuils en vigueur, relus dans le générateur

**FAIT REPRODUIT** —
`grep -E "^(GABARIT_|EPAISSEUR_MIN|PLAGE_PLANE|LARGEUR_|COLS_|DECENTREMENT|ENTAILLE_LECTURE|BANDE_FAITE|SEMELLE_PART_LAT)" source_assets/blender/environment/make_waterfall_cave.py` :

```
ENTAILLE_LECTURE_M = 0.90
BANDE_FAITE_M = 0.45
LARGEUR_RATIO_MIN = 2.00        # entre la plus large et la plus étroite
LARGEUR_ECART_MIN = 1.20        # entre deux emprises consécutives
COLS_RATIO_MIN = 1.25           # entre les profondeurs des deux cols
COLS_ECART_MIN_M = 0.40         # et leur écart absolu
DECENTREMENT_MIN = 0.08         # du faîte dominant, en fraction de l'emprise
SEMELLE_PART_LAT = 1.05
EPAISSEUR_MIN_M = 0.80          # nulle part une plaque
EPAISSEUR_MIN_COLLERETTE_M = 0.60
PLAGE_PLANE_MAX_M2 = 12.00
PLAGE_PLANE_FACADE_MAX_M2 = 6.00
GABARIT_DEMI_LARGEUR_M = 0.95   # capsule joueur r = 0,45 m
GABARIT_CLE_M = 2.05
```

**Aucun de ces seuils n'a été modifié pendant la passe.** Vérifié par
`git diff c79341e..HEAD` sur chaque worktree : aucune ligne de la forme
`^[-+][A-Z_]+ *=`.

Repères de coordonnées : 1 unité = 1 m ; Blender **Z-up**, glTF/Godot **Y-up** ;
modèle → Godot `(ax, z, −ay)` ; `LACET_DEG = 45` ; le modèle sort de la bouche vers
le sud-est monde `(0,707 ; 0,707)` ; `azimut_glb = azimut_monde + 45`.

Chaîne de construction, dans l'ordre : **voxel remesh (~137k tris) → `stratifier()`
→ `decimer()` (~19k) → soustraction**. La décimation **précède** la soustraction.

Définition d'une **percée confirmée** : un carré de 0,10 m entièrement percé,
grille 0,025 m. Ce n'est **pas** la même chose qu'un rayon suspect.

---

## 39. R2a-3.5.6 — CLÔTURE `PARTIAL`. Le portail est réparé, la roche manque encore.

**Verdict : `PARTIAL`.** Rien n'est intégré au tronc. L'asset livré reste
`8bf1a1b3` (R2a-3.4). Zéro capture, conformément à la directive §8.

### 39.1 Le résultat qui explique toute la série — un théorème

À partir des définitions **déjà gelées** : le contrat §2.6 définit l'épaisseur
comme la distance euclidienne à la surface extérieure la plus proche, et `Γ` est
par construction la courbe où la peau intérieure s'arrête et où la surface
extérieure commence, donc `Γ ⊂ S_ext`. Alors

```
e(p) = dist(p, S_ext) ≤ dist(p, Γ) ≤ d(p)      pour tout p, sur toute géométrie
```

Conséquences, aucune propre à cette grotte :

- `e ≥ min(d ; 0,80)` ne demande pas un plancher, **elle demande le majorant** :
  marge maximale **nulle**, géométrie parfaite comprise ;
- sous la borne conservatrice, exigée en toutes lettres, la loi littérale est
  **insatisfiable** sur `d < 0,80` pour tout `h > 0` ;
- **tout seuil constant `S` est inatteignable en deçà de `d = S`** — ce qui
  explique enfin le `lecture / h` rigoureusement constant à un facteur 8 près
  mesuré en R2a-3.5.5 sur deux géométries indépendantes.

Réparation, écrite **avant** toute mesure et committée : `LOI-R`, §2quater de
`docs/ADDENDUM_MASQUE_BOUCHE.md`.

```
e_requise(p) = min( max(0 ; d(p) − h) , 0,80 m )
θ(p) ≥ θ_min = 70,25°   dans la bande d ≤ h
```

Genou à `0,80 + h` = **0,85 m** à `h = 0,05` — le nombre que la directive §4
exigeait déjà par ailleurs ; il tombe, il n'est pas choisi. `θ_min` est dérivé de
`asin(1 − h/(0,80+h))` et **non choisi** : mon 60° initial était le seul nombre
arbitraire de la loi, et il était faux. `LOI-R` étant strictement plus exigeante,
**le gate d'angle n'ajoute rien tant que `LOI-R` s'applique**.

Instrument : `tools/cave_borne_rebord.py`, banc **15/15** dont trois contrôles
négatifs. Vérifié indépendamment par l'agent A, qui a atteint le même résultat
avant réception du message.

### 39.2 Ce qui est réparé, mesuré, et non intégré

| lot | résultat | preuve |
|---|---|---|
| **`MASSIF`** | auto-intersections `env×env` **34 → 0**, collision **62 → 16**, enfoncement max `0,457 → 0,245 m`, **`SM_` inchangé au bit près** | prédiction falsifiable posée avant mesure, tenue sous **deux** instruments |
| **`rochers_joue_droite()`** | échantillons sous seuil **1 122 → 499** (−55,5 %), lecture `0,6813 → 0,7198 m`, GLB final `3a80ae71c89bfc97` reproduit deux fois | trois contraintes tenues ; reclassement encadré rejoué sur la géométrie finale : **499/499 à exigence pleine, 0 vert** |
| **loi de rebord** | outillée, banc vert, contrôle négatif **concluant** | `Γ` vérifié sur la roche à `0,000000000000 m` |

Cause de `MASSIF`, **intrinsèque et non accidentelle** : rayon latéral `3,30 m`
contre rayon de courbure `2,37 m`. Un tube plus large que le virage qu'il suit se
traverse nécessairement. R2a-3.4 y échappait en filant droit sur 10,4 m.

### 39.3 Les deux blocages, et un seul est géométrique

**a) Contractuel, et circulaire.** Un seul portail est rouge dans toute la
chaîne : `controle_epaisseur_domaine`, 29 plaques. Tout le reste est vert. Or ce
portail est **déjà déclassé en télémétrie par le contrat gelé `cca1778`**, et la
directive interdit d'appliquer ce déclassement avant qualification verte.

```
la chaîne ne peut pas verdir     tant que le portail n'est pas déclassé
le portail ne peut pas être déclassé   tant que la chaîne n'est pas verte
```

**Aucune sculpture ne dénoue cela.** Vérifié et non supposé : la fonction
n'existe **ni** dans `504ecbe`, **ni** sur le tronc — elle est entièrement côté
candidat. Intégrer la pile introduit donc un portail qui n'existe pas aujourd'hui
et qu'elle échoue. Et le livré porte **320** plaques contre 29, la plus mince
`0,051` contre `0,114 m`, dont **204 à plus de 4 m** de la lèvre contre 1.

**b) Géométrique, et nommé.** Cible `borne ≥ 0,80` non atteinte : lecture
`0,7194`, il manque **0,1307 m**. La lecture ne bouge que de **0,4 mm** entre
`h = 0,10` et `h = 0,05` : elle a convergé, donc **aucun raffinement d'instrument
ne fournira ce qui manque**. Le déficit est géométrique, pas métrologique.

Cause diagnostiquée **et contre-indiquée** : il manque de la **portée latérale**
à `−2,289 m` de la courbe, quand le module en porte `1,320`. Augmenter le déport
détacherait les deux couronnes. La suite est un changement de **taille de
module** — ce que la leçon de `rochers_gaine()` interdit sans mesure dédiée.

### 39.4 La prochaine action exacte

**`ISS-058` — raffiner le maillage au voisinage de la bouche.** C'est le seul
travail géométrique que cette passe a identifié comme indispensable et qu'elle
n'a pas fait, et **deux constats indépendants y convergent** :

1. à l'arête médiane réelle de `SM_` — `0,3325 m`, mesurée sur l'asset livré — la
   rampe `[0 ; 0,80]` ne porte que **cinq valeurs**, et la lâcheté du majorant de
   `d` y vaut **82 % de `h`** ;
2. `Γ` est une courbe simple fermée à la bouche, mais **dentelée d'un facteur
   10,6** — `116,16 m` quand une ellipse à ses dimensions en mesure `10,99`.

Un `Γ` de 11 m **ne s'obtiendra pas en filtrant, il s'obtiendra en maillant**.

### 39.5 Ce qui revient au propriétaire, pas à une session

Le déclassement de `controle_epaisseur_domaine()` est une décision de **barre de
qualité** (`PROMPT4_METHOD` §13). Elle est déjà prise au contrat ; elle n'est pas
appliquée au code. **Tant qu'elle ne l'est pas, aucune géométrie ne peut
qualifier cette passe.**

### 39.6 Trois erreurs de lead, corrigées dans la preuve

Consignées parce qu'elles se reproduiront sinon.

1. **`θ_min = 60°`** — choisi au lieu d'être dérivé ; corrigé à `70,25°` par
   l'agent A.
2. **« la collision est huit fois plus grossière »** — faux,
   `1,3384 / 0,3325 = 4,03`.
3. **« divergence de 0,12 m entre agents »** — écrite deux fois dans des fichiers
   versés. Je comparais une **borne** à une **lecture** : `0,6813 − 0,10 = 0,5813`
   exactement. Le vrai écart vaut `0,0187 m`, entre deux points différents.
   **Quand un écart vaut un paramètre connu de l'instrument, soupçonner le
   paramètre avant la mesure.**

Et une inférence corrigée en cours de route : j'avais supposé que les plaques
rouges, étant près du porche, seraient reclassées par la loi de rebord. La
lecture du code l'a démentie — `_cumul_au_dessus_du_vide` rend le banc **au-dessus**
du vide, donc une plaque à 6/8 voisins est un toit mince, pas un rebord.

### 39.7 Incidents de la passe

- **`ISS-056`** — `pkill -f` traverse les frontières entre worktrees.
  Auto-signalé. Présent vérifié sans `pgrep -f`, par `/proc/<pid>/cwd`. Règle
  posée : **tout journal sans jeton `^RC=` est réputé mort et doit être rejoué**,
  et un journal sans jeton se supprime **sans être lu**.
- **`ISS-057`** — `blender --background --python` rend `0` même quand le script
  lève. Tout banc Blender du dépôt est exposé. Parade par jeton `FIN NOMINALE`.
- **Changement hors tables trouvé** — `main()` pose `rochers_gaine()` sur le
  tronc et `rochers_calotte_nord()` sur le candidat : 84 roches échangées,
  invisibles à toute comparaison de tables. Instruit `TICKET-B4`, ne le clôt pas.
- **`TICKET-B5` chiffré** — l'asset livré porte **0** triangle d'aire exactement
  nulle, mais **4** lamelles à `1e-10 m²`. Un portail post-export sous `1e-9`
  rougirait ce qui est en ligne.

---

## 40. R2a-3.5.7 — CLÔTURE `PARTIAL`. Le maillage visuel est vert, la collision non.

**Verdict : `PARTIAL`**, sur un défaut **concret, localisé et mesuré**, comme la
directive §11 le prévoit. Rien n'est intégré au tronc, l'asset livré reste
`8bf1a1b3`, **zéro capture**.

### 40.1 Ce qui est vert, et vérifié par le lead

**Maillage visuel** — GLB candidat `40714c46`, reproduit par mon propre lecteur :
0 aire exactement nulle, 0 lamelle sous `1e-9`, aire totale `842,188236 m²`,
20 070 triangles. Genre **0**, une composante, 0 bord libre, 0 non-manifold,
0 sommet pincé. Composition **3/3/3**, ratios `2,23 / 2,37 / 2,25`. `gltf_inspect`
valide.

**Zéro trou vers le ciel** — le critère le plus important, prouvé **depuis
l'intérieur** et sans dépendre d'une résolution : couper le seul contour de bouche
sépare exactement `1 008 + 19 062 = 20 070` faces, graines salle et niche prouvées
dans l'air par angle solide. Corroboré indépendamment par le genre 0.

**Traversabilité** — instrument exact à `1e-9 m` près : les **deux** rayons de
capsule en litige passent partout, sur `COL_` comme sur `SM_`, marge la plus
faible `+0,1213 m`, soit **48× l'erreur**. `COL_` est partout `0,10 à 0,30 m` plus
étroit que `SM_` : **aucune paroi invisible dans la galerie**.

**Le `7/8` de `world_v2_places` est un défaut de SONDE**, établi par trois
mesures : le chemin canonique donne **zéro échantillon sous contrat** (2,28 à
2,38 m pour 1,75 exigés) ; l'ancre du tronc est **pire** que l'actuelle ; et les
11 points fautifs ont `0,013 à 0,045 m` de dégagement là où une capsule en exige
`0,450` — ils sont **dans la paroi**. Le filet marche une corde droite dans une
galerie coudée.

### 40.2 Le seul défaut bloquant restant

**4 auto-intersections de collision, repli `0,243436 m`.**

Elles sont **réelles** au sens du critère préexistant du projet :
`REPLI_LIVRABLE_MAX_M = 0.02`, présent dans le générateur du tronc à `504ecbe`.
`0,2434 m` est **12× au-dessus**. Le même critère innocente les 2 traversées du
maillage visuel, à `0,0006 m` — **33× sous**. On ne peut pas appliquer
l'instrument dans un sens seulement.

**Le zéro existe et il est vérifié sur le GLB exporté** : à
`COL_MARGE_LAT = 0,50`, zéro pénétration, repli `0,000000 m`. **Arbitrage rendu :
non.** `0,50` ne se dérive d'aucune constante ; le prix est **`0,845 m` de paroi
invisible dans la niche de récompense**, à l'endroit précis où le joueur doit
aller ; et `COL_MARGE_LAT` est une marge de passage gelée. L'interrupteur est
d'une ligne, il reste publié, et la décision appartient au propriétaire.

### 40.3 Deux causes nommées, et c'est ce qui rend les correctifs réutilisables

**La face d'aire nulle naissait de la TRIANGULATION, pas du booléen.** Dans
Blender il n'y a aucune face plate. Le coupable est un treize-gone dont le bord
porte trois sommets colinéaires — et **l'exportateur glTF triangule de toute
façon** : une étape **non mesurée, capable d'injecter un défaut après le dernier
contrôle**. Le générateur triangule désormais lui-même, et seulement les 5 n-gones
concernés — les 2 515 d'un bloc cassaient le build.

**Les pénétrations de collision** : `retrait_lat` est soustrait de `hw` **avant**
la multiplication par `CAVITE_ASYM`. Au flanc de l'alcôve la paroi recule de
`0,676 m` quand on ne retranche que `0,40` : **l'alcôve reculait deux fois moins
que la paroi qu'elle prolonge.** Corrigé sans constante nouvelle — insuffisant,
mais nommé.

### 40.4 Ordre d'intégration — l'ordre imposé était impossible

Vérifié par moi : `531cdd8` descend de `f2ea189` **et** `fd4effe`, donc il n'y a
**pas trois greffes mais une seule**, plus `MASSIF`. Et `MASSIF` **ne peut pas**
venir en 2ᵉ position — `RC=1`, hunk #2 `FAILED` sur le tronc contre `RC=0` en 6/6
sur `531cdd8`. Raison sémantique plus forte encore : le ratio rayon/courbure vaut
`0,98` au tronc, donc **on lisserait une courbe saine**.

**Piège évité** : prendre `531cdd8` par `checkout` détruirait 12 outils et
~4 000 lignes créés par le tronc, dont `cave_exact_intersect.py` — l'instrument
même qui mesure ce que `MASSIF` prétend corriger.

**Couplage dur** : `place.gd` déplace `MODELE_SALLE` de **3,994 m**. Livrer le GLB
sans lui met la récompense et les lampes dans la roche.

### 40.5 Quatre angles morts d'outillage, tous consignés

1. **Le dégénéré est une propriété d'AIRE, pas d'indices.** `cave_check_mesh.py`
   retire par égalité d'indices : une T-jonction passe. Vérifié sur une
   démonstration fermée.
2. **Annoter un journal pendant qu'un processus y écrit efface l'annotation** —
   le fichier se lit ensuite comme une exécution normale et achevée. Pire qu'un
   tronqué : un tronqué se voit.
3. **Un garde-fou vaut par son observation** : un stub de `save_as_mainfile`
   re-résolu par `__getattr__`, jamais déclenché, a laissé réécrire le `.blend`
   qu'il prétendait protéger.
4. **Le compteur interne sous-estime le repli de 12 %** — documenté comme minorant
   du *compte*, il l'est aussi du *repli*, et ce n'était écrit nulle part.

### 40.6 Trois erreurs de lead, corrigées dans la preuve

**Mon hypothèse de courbure était fausse** : la seule station encore au ratio ≥ 1
ne porte **aucune** pénétration, et celles qui en portent ont les ratios **les plus
bas**. Réfutée par la mesure, corrélation nulle et même inversée.

**Mon hypothèse sur `MODELE_SALLE`** — l'ancre déplacée expliquerait le `7/8` —
était fausse aussi : l'ancre du **tronc** donne 13 points fautifs contre 11. La
corde rasait déjà la paroi avant, et plus fort.

**Ma formulation de la raison mécanique** : la table `MASSIF` **existe** au tronc,
ce sont ses valeurs qui diffèrent. Et mon premier test du patch a échoué pour une
raison d'outillage — un échec qui *ressemblait* à une confirmation.

### 40.7 `NON VÉRIFIÉ`, et deux sont lourds

- **Rien n'a été éprouvé en moteur** : ni `validate_fast`, ni la capsule joueur en
  jeu, ni les 7 stations.
- **`export_architecture.sh waterfall_cave` est ROUGE** — 29 plaques au porche,
  préexistant. **Le GLB candidat n'est pas livrable en l'état** ; il vient de
  l'échafaudage.
- **71 des 240 sommets d'enveloppe sortent du rocher visible**, jusqu'à `2,72 m`.
  Préexistant, **jamais mesuré avant cette passe**, terrain non mesuré.
- Le déclassement du portail d'épaisseur de domaine est décidé et documenté mais
  **pas encore appliqué au code** : il ne peut l'être qu'à l'intégration, la
  fonction n'existant pas au tronc.
- `godot --import` rend `RC=134` (SIGABRT) après écriture du cache de classes.

---

*Fin de CODEX_HANDOFF. Actualiser à chaque checkpoint majeur, avant tout rapport
final.*

## 41. R2a-3.5.8 — GROTTE TECHNIQUEMENT VERTE. Candidat intégré, verdict visuel attendu.

Ce que 3.5.7 laissait rouge — les 4 auto-intersections du collider à
0,2434 m de repli — est à **zéro sur le binaire exporté**, en une itération
de géométrie (budget : trois), sans toucher un octet du maillage visuel.

### 41.1 Le mécanisme, en trois lignes

La cause a inversé le diagnostic initial : ce n'était pas l'alcôve de la
cavité mais la **queue de l'enveloppe** (st7-9, az9-11) qui revendiquait de
la roche dans le vide de la niche. Réparation `_reconstruire_alcove_col()` :
enfouissement le long du plus court chemin derrière la surface visible
(marges 0,06/0,03 m), 9 sommets déplacés, direction intrinsèquement sûre —
le collider recule HORS du vide, DANS la roche.

### 41.2 Les quatre SHA de la livraison

| Rôle | SHA |
|---|---|
| code (source candidate + bascule + outils) | `4a51e3b`, `a2c000e`, `c780bb8`, `27946c4` |
| GLB candidat (commit) | `aec039b` — fichier `5ff4ec6ee7a5bb6f…` |
| captures (arbre de capture) | `47f3a2e` (manifeste `repo_dirty:false`) |
| evidence (checkpoints, rapport, contrôles) | `ae9b8c0`, `22639b9`, `a00af60` + commit de clôture |

### 41.3 Ce que Codex doit savoir avant de juger

- **R2a-3.4 reste active** : `assets/environment/caves/SM_WaterfallCave.glb`
  est toujours `8bf1a1b3…`. Le candidat vit sous `candidates/`, monté
  UNIQUEMENT quand `WORLD_V2_GROTTE_CANDIDAT=r2a358` (chaîne de capture).
- L'activation, si le verdict est favorable, est un petit commit : basculer
  `OUVRAGE`/ancres de `waterfall_cave_place.gd` sur les constantes `_R2A358`
  déjà en place, et promouvoir le GLB. Rien d'autre à construire.
- Le **déclassement du balayage de domaine** (décision gelée `cca1778`,
  politique `28fa140`) est appliqué au code du candidat seulement : la
  mesure s'imprime à chaque build, elle ne bloque plus. Les 9 autres portes
  `franchir()` restent bloquantes ; aucun seuil n'a changé.
- La poche de collision est **rétrécie par conception** (0,583 contre 1,065
  pré-correctif ; plancher de conception 0,524 tenu) — c'est le prix arbitré
  du zéro pénétration, publié par l'agent B, reproduit par le lead.
- Les montages A/B : `evidence/world_v2/v2_3_r2a/grotte/r2a358_candidat/
  montages_ab/` — R2a-3.4 à gauche, candidat à droite, mêmes caméras.

- **validate_fast (§9)** : 904/904 tests verts ; verdict ROUGE (RC=1) sur
  des fuites de fin de processus de la suite COMPLÈTE — **préexistantes,
  mesurées aux comptes identiques à la base Codex `0b0ef54`** (ISS-059).
  Un rouge préexistant ne se rebaptise pas vert ; il n'appartient pas aux
  gates de la grotte et attend une session de dette dédiée.

### 41.4 La question posée au propriétaire et à Codex, sans réponse du lead

> « La grotte se lit-elle désormais comme une formation rocheuse naturelle,
> avec une bouche, un virage et une poche intérieure cohérents, ou
> reste-t-elle visuellement inférieure à R2a-3.4 malgré ses améliorations
> techniques ? »
