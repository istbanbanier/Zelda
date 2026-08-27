# S1.1 — contrat de mesure de la gravité, ÉCRIT AVANT TOUTE MESURE

Statut : **préenregistré**. Date : 2026-08-27. Aucun chiffre de ce document
n'est issu d'une exécution : ils viennent tous du tuning committé et de la
résolution de l'appareil. Les relire après coup, c'est vérifier une promesse,
pas raconter un résultat.

## Ce qui a échoué, et pourquoi ce n'était pas la gravité

`fumee_build_exportee.py` jugeait la gravité au **pixel** : capture avant le
saut (`d`), pendant (`e`, +0,35 s), après (`f`, +3,0 s), puis

    PASS si  rmse(d,e) > 0,005  ET  rmse(d,f) < rmse(d,e)

Mesuré sur la build publiée : `monte = 0,0602`, `revenu = 0,1064`. Donc
`revenu > monte`, donc **PARTIAL**. La vue d'après-saut était PLUS éloignée de
la référence que la vue en l'air.

La cause n'est pas le sol : c'est le **délai**. Entre `d` et `f` il s'écoule
3,35 s pendant lesquelles le tapis de fleurs, animé par le vent, dérive
librement — le même mécanisme que celui déjà mesuré sur `flower_field`, où
deux exécutions ÉDITEUR de la même vue divergent de 0,109 RMSE. Le critère
mesurait le vent et l'imputait à la gravité.

Deux défauts distincts en sont sortis, et c'est le second qui est grave :

1. le critère est mal choisi (pixels contaminés par l'animation) ;
2. **le harnais imprimait, même en PARTIAL, la phrase
   « la vue s'écarte puis revient : le sol arrête la chute »** — une
   affirmation codée en dur qui énonce précisément ce que la mesure venait de
   nier. Puis `return 1 if echecs` ne comptait que les `FAIL` : le PARTIAL
   rendait RC=0, et la ligne de résumé « 17 points observés, 0 FAIL » a été
   relayée par moi en « 17/17 ». Le produit n'a jamais menti ; l'appareil et
   son compte rendu, si.

## Ce qui remplace le pixel : la télémétrie déjà embarquée

Le jeu **publié** contient l'autoload `DevMode` (`scripts/tools/dev_mode.gd`),
sans aucun bridage de build : `F3` démarre un enregistrement, `F4` pose un
marqueur, et `mark()` fusionne `_player_snapshot()`, qui écrit

    data["x"] = snappedf(body.global_position.x, 0.1)
    data["y"] = snappedf(body.global_position.y, 0.1)   <- LA MESURE
    data["z"] = snappedf(body.global_position.z, 0.1)
    data["etat"] = <nom du mode du contrôleur>

Le recorder sérialise en JSONL sous `user://dev_sessions/<horodatage>/`.

Conséquences, et elles comptent :

- la grandeur mesurée est la **position Y réelle du corps du joueur**, pas une
  différence d'images ;
- **aucune modification du jeu publié** n'est nécessaire : c'est le binaire
  de la release qui produit sa propre télémétrie, par une fonctionnalité
  destinée au propriétaire ;
- l'exigence « exclure les fleurs et autres zones animées » est satisfaite
  **par construction, pas par recadrage** : la mesure ne regarde aucun pixel.
  Il faut le dire ainsi et non prétendre avoir découpé une zone.

Limite acceptée : `snappedf(…, 0.1)` quantifie Y au décimètre. Tous les seuils
ci-dessous sont posés en multiples de ce quantum.

## Valeurs nominales, dérivées du tuning committé

`resources/tuning/locomotion_default.tres` : `jump_velocity = 8.2`,
`gravity = 24.0`. D'où, en chute libre :

| Grandeur | Formule | Valeur |
|---|---|---:|
| Hauteur d'apex | v²/2g | **1,401 m** |
| Temps jusqu'à l'apex | v/g | **0,342 s** |
| Temps de vol total | 2v/g | **0,683 s** |
| Altitude à t = 0,12 s | vt − ½gt² | 0,811 m |
| Altitude à t = 0,30 s | vt − ½gt² | 1,380 m |

## Chaîne de possession de l'artefact éprouvé

L'empreinte nommée par la directive,
`302643c7a5b59418d767121641f798ef0728d8358d6c0b8befec2e1241a8f91e`, est celle
de l'**archive publiée** `EclatsDOrage_Linux_x86_64_05d0760.zip` — c'est ce que
la release publie et ce qu'un joueur télécharge. Le binaire qu'elle contient a
sa propre empreinte, `84025157adc8b7fa02b08d67a571b5b493830d919af66f29e8d6262704c848e5`,
qui est **dérivée** : elle se recalcule après extraction, elle n'ancre rien.

Le harnais vérifie donc l'archive AVANT toute chose, puis **extrait le binaire
de cette archive-là** et lance celui-ci. Sans ce lien, « le ZIP est conforme »
et « j'ai lancé ce binaire » resteraient deux affirmations sans rapport.

## AMENDEMENT 1 — la cadence de l'appareil est MESURÉE, et elle interdit
## l'échantillonnage déterministe

Écrit après la première exécution, et il faut dire pourquoi cet amendement est
légitime : il est justifié par une mesure portant sur l'**instrument**, jamais
sur le sujet. Aucun seuil de jugement n'est touché.

Première exécution : 14 marqueurs au lieu de 20, tous espacés de ~1,04 s alors
que la séquence en demandait à 0,12 s et 0,18 s. Deux hypothèses posées, les
deux RÉFUTÉES par la mesure :

1. « la capture d'écran coûte cher, réduire la fenêtre la rendra rapide » —
   sonde à trois résolutions, **au menu** : 1024×768 → 0,076 s ; 400×300 →
   0,071 s ; 200×150 → 0,070 s. La résolution ne change rien.
2. « le monde tourne à 1 image par seconde » — le journal du run réel ne porte
   que **4 saccades > 100 ms** sur 20 s. Les images ne durent pas 1 s.

Sonde décisive, une seule variable changée — 8 appuis `F4` séparés de 0,05 s :

| Contexte | Marqueurs | Écarts observés |
|---|---:|---|
| Menu principal | 8/8 | 0,068 – 0,081 s |
| **Monde V2 monté** | 8/8 | **1,02 – 1,04 s** |

Les huit appuis partent en 0,59 s de temps mural et ressortent étalés sur
7,2 s : aucun n'est perdu, ils sont **sérialisés**. La cause est le coût de
`capture_screenshot()` — `get_texture().get_image()` est une relecture GPU
d'une scène 3D complète sous llvmpipe — que `mark()` appelle à chaque
marqueur, et que rien ne permet d'éviter sans modifier le jeu publié.

**Conséquence, énoncée sans détour : l'appareil échantillonne au mieux toutes
les 1,03 s, et le vol dure 0,683 s. Aucun marqueur ne peut être placé à un
instant CHOISI du vol.** C'est la limite d'environnement que `CLAUDE.md`
déclare déjà — rendu logiciel, « utilisable pour la régression visuelle,
jamais pour une mesure ».

## AMENDEMENT 2 — échantillonnage par BATTEMENT, et il durcit le critère

Ce qui reste possible, et qui répond à la même question : ne plus choisir
*quand* observer, mais observer **beaucoup**, à une période délibérément
incommensurable avec celle des sauts.

- sauts répétés à intervalle `T_saut = 1,5 s` ;
- marqueurs à la cadence libre de l'appareil, ~1,03 s ;
- les deux périodes dérivent l'une par rapport à l'autre, donc les marqueurs
  échantillonnent la phase de vol **proportionnellement à sa durée**.

Fraction de temps passée en l'air : `0,683 / 1,5 = 45,5 %`. Sur `N` marqueurs
pris pendant une campagne de sauts, on attend donc ~45 % d'observations
au-dessus du sol.

| # | Critère amendé | Seuil |
|---|---|---|
| 2a | Marqueurs élevés (`Y − Y_sol ≥ 0,50 m`) pendant la campagne de sauts | **≥ 25 %** des marqueurs |
| 2b | Marqueurs élevés pendant le contrôle négatif (aucun saut) | **= 0** |
| 2c | Marqueurs total par campagne | **≥ 20** |

Le seuil d'excursion **reste 0,50 m** : ce qui change est le nombre
d'observations exigées, pas la hauteur exigée. Le critère est de fait plus dur
qu'avant — une réussite isolée ne suffit plus, il en faut une sur quatre, et
le contrôle négatif doit en produire **exactement zéro**. Le seuil de 25 %
est posé sous les 45 % attendus pour tolérer la corrélation résiduelle entre
les deux périodes, et très au-dessus de zéro.

Les critères 1 (bruit), 3 (retour au sol) et 4 (état) sont inchangés et
restent évalués sur des marqueurs au repos, où la cadence de 1,03 s ne gêne
pas.

## Séquence temporelle, par répétition (contrat initial, CONSERVÉ pour mémoire)

Tous les repères sont des `F4`. Aucune touche de déplacement n'est pressée
pendant la séquence : sans dérive horizontale, deux Y au sol sont comparables.

| Repère | Instant | Rôle |
|---|---|---|
| `M1` | t = 0 | altitude au sol, référence |
| `M2` | t = +0,50 s, **aucune entrée** | bruit de l'appareil au repos |
| `M3` | +0,12 s après `Espace` | montée |
| `M4` | +0,30 s après `Espace` | proche apex |
| `M5` | +2,00 s après `Espace` | retour au sol |

## Critères et TOLÉRANCES PRÉENREGISTRÉES

| # | Critère | Seuil | Justification |
|---|---|---|---|
| 1 | Bruit sans entrée : `\|Y(M2) − Y(M1)\|` | **≤ 0,10 m** | un quantum ; un héros immobile ne dérive pas |
| 2 | Excursion : `max(Y(M3), Y(M4)) − Y(M1)` | **≥ 0,50 m** | 5 × le quantum, et 2,8 × sous l'apex nominal de 1,401 m — inatteignable par le bruit, atteint avec marge par un vrai saut |
| 3 | Retour au sol : `\|Y(M5) − Y(M1)\|` | **≤ 0,20 m** | deux quanta ; à t = 2,00 s le vol de 0,683 s est fini depuis longtemps |
| 4 | État du contrôleur en `M1` et `M5` | `locomotion` | ni mort, ni blessé, ni escalade — le sujet doit être un héros debout |
| 5 | Répétitions | **3 sur 3** | une réussite unique ne distingue pas d'un hasard d'ordonnancement |

Marge d'ordonnancement : à t = 0,55 s l'altitude vaut encore 0,88 m, soit
1,76 × le seuil d'excursion. Le critère 2 survit donc à 250 ms de retard sur
`M3`/`M4` — et `M3` comme `M4` sont pris, on retient le **max**.

## Contrôle négatif, obligatoire

Même séquence, **sans l'appui `Espace`**. L'excursion doit rester
**< 0,50 m**. Si le contrôle négatif atteint le seuil, l'appareil ne
discrimine pas un saut d'une absence de saut : le verdict d'ensemble est
**BLOQUÉ**, jamais PASS. Un instrument qui dirait « saut réussi » sans saut ne
prouverait rien de ce qu'il prétend.

## Verdict

`PASS` seulement si les 3 répétitions passent les critères 1 à 4 **et** que le
contrôle négatif reste sous le seuil. Tout autre résultat est `PARTIAL`,
`FAIL` ou `BLOQUÉ`, et dans ce cas — conformément à la directive — la passe
s'arrête, `GO_V2_3_B_LOT2` reste `FALSE`, aucune release n'est publiée, et la
cause exacte est nommée.

---

## AMENDEMENT 3 — la cause est l'HORLOGE DU MOTEUR, et elle ferme la mesure

Écrit après la troisième exécution, complète cette fois : 111 marqueurs
drainés contre 18 la précédente, la cadence d'émission ayant été portée à
1,15 s (au-dessus des 1,03 s mesurées à l'AMENDEMENT 1).

### Ce que la séquence complète a rendu

| Critère | Mesure |
|---|---|
| 1 — bruit au repos | Y 24,0 → 24,0 m ; bruit 0,0 ; état `locomotion` — **PASS** |
| 2a — campagne 1 | 17/26 marqueurs élevés (65 %) ; excursion max **1,4 m** |
| 2a — campagne 2 | 24/26 (92 %) ; excursion max **1,5 m** |
| 2a — campagne 3 | 23/26 (88 %) ; excursion max **1,4 m** |
| 3 — retour au sol | 25,3 · 24,3 · 24,9 m contre un sol à 24,0 — **FAIL ×3** |
| 2b — contrôle négatif | **6/23 marqueurs élevés SANS aucun appui sur Espace** |

Le contrôle négatif est la ligne qui décide. Le contrat le disait déjà avant
toute mesure : *« si le contrôle négatif atteint le seuil, l'appareil ne
discrimine pas un saut d'une absence de saut : le verdict d'ensemble est
BLOQUÉ, jamais PASS »*. Le harnais rendait `FAIL` sur ce point ; il rend
désormais `BLOQUÉ`, comme écrit. Un `FAIL` aurait imputé au **jeu** un défaut
de l'**appareil** — la faute exactement symétrique du faux vert qu'on corrige.

### La mesure qui nomme la cause

`DevMode._process()` accumule `delta` et écrit un événement `position` chaque
fois que la somme atteint `SAMPLE_INTERVAL = 1,0 s`. Leur nombre mesure donc
directement le temps que le moteur croit avoir vécu.

| Exécution | Temps mural | `position` | Rapport | F4 |
|---|---:|---:|---:|---:|
| Campagne de battement | 152 s | 2 | **0,013** | 111 |
| Sonde dédiée | 120 s | 7 | **0,058** | **0** |

Le moteur annonce par ailleurs **7,3–7,7 FPS** et aucune image au-delà de
150 ms. Ces deux faits sont **mutuellement incompatibles** : un moteur qui
rend 7,5 images par seconde murale avec des `delta` honnêtes ferait avancer
son accumulateur d'une seconde par seconde murale. Il en met 17 à 76.

### Une hypothèse posée, puis RÉFUTÉE par la mesure

Hypothèse : le décrochage vient de `mark()`, qui fait une relecture GPU par
marqueur sous llvmpipe. Sonde dédiée, une seule variable changée — **aucun F4
n'est pressé** : rapport **0,058**. Le décrochage est là **sans une seule
capture**. L'hypothèse est fausse, et il faut l'écrire ainsi plutôt que la
laisser vivre comme une explication commode.

### Ce que la sonde montre quand même, et qu'il faut dire sans le surclasser

Piste d'altitude de la sonde, échantillonnée par le moteur lui-même :

| Phase murale | Y observés |
|---|---|
| repos, aucune entrée | 24,0 · 24,0 |
| sauts | **25,1 · 25,1 · 25,1** |
| repos, aucune entrée | 24,0 · 24,0 |

Le héros quitte le sol quand on presse Espace et s'y retrouve ensuite, l'état
restant `locomotion`. Les excursions mesurées — 1,4 / 1,5 / 1,4 m — encadrent
l'apex nominal de **1,401 m** dérivé du tuning committé.

**C'est une OBSERVATION, pas un `PASS`.** Sept échantillons ne satisfont ni le
critère 2c (≥ 20 marqueurs par campagne) ni les trois répétitions, et surtout
aucune affirmation *temporelle* — « il retombe en moins de tant » — n'est
tirable d'une horloge décrochée d'un facteur 17.

### Verdict

**S1.1 = `BLOQUÉ`.** La gravité de la build publiée reste **`NON VÉRIFIÉ`** :
ni réussite ni échec n'est démontré. Le protocole préenregistré ne peut pas
être exécuté fidèlement dans ce conteneur, parce que les consignes sont
émises en temps mural et que le sujet vit dans un temps qui n'est pas le
même.

Aucun seuil n'a été déplacé, à aucun moment. C'est `CLAUDE.md` qui l'avait
déjà écrit : rendu logiciel, *« utilisable pour la régression visuelle,
jamais pour une mesure »*. La vérification appartient à
`docs/MANUAL_VALIDATION.md`, sur une vraie machine.

Conformément à la directive : `GO_V2_3_B_LOT2 = FALSE`, aucune nouvelle
release, aucun Lot 2.

Preuves : `evidence/world_v2/v2_3_b/iss071/s1_1_gravite/`.
