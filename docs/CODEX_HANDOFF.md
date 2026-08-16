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
| `base` | 1 767 556 | `c1263d5f1cf6fa3f` |
| `c_instruments` | 1 767 556 | `c1263d5f1cf6fa3f` |
| `b_collerette` | 1 777 204 | `c29131661550d558` |

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

*Fin de CODEX_HANDOFF. Actualiser à chaque checkpoint majeur, avant tout rapport
final.*
