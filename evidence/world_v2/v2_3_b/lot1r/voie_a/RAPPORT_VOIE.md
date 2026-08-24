# RAPPORT VOIE A — Belvédère du guetteur + Source aux reflets (lot 1.R)

Worktree `/home/user/wt-lot1r-a`, base `89a3009`, HEAD à la clôture :
`233e27b`. Géométrie engagée sur les DEUX arbitrages
du lead (compositions A « La mâchoire » et A « La bouche »).

**Aucun verdict artistique n'est prononcé ici.** Ce rapport compare
l'intention aux images réellement rendues et remet les mesures ; la revue
humaine tranche. Statuts employés : `PASS` / `PARTIAL` / `FAIL` / `BLOQUÉ` /
`NON VÉRIFIÉ`.

---

## 1. Ce qui a changé, et pourquoi

### 1.1 Belvédère (`overlook_summit_place.gd`)

- **`SM_Dungeon_CaveRock/CaveWallTop/CaveWallHalf` bannis** (rejet Codex :
  « plaques terracotta rectangulaires »).
- **La famille Kenney `rock_*` a quitté le lieu à son tour (v7b)**, et pour
  une raison mesurée, pas de goût : `tools/gltf_inspect.py` sur
  `assets/environment/cliffs/rock_largeC.glb` rend **72 triangles, 0
  texture, 2 matériaux à couleur plate**. Aucune teinte ne fait lire
  « roche » à un solide de 72 faces sans texture ; il rend un coin à faces
  planes quoi qu'on fasse. C'est exactement ce que le troisième passage
  d'audit a relevé au pied du gros bloc. Strate, dalle de pied et éclats
  passent à `Rock_Medium_*` (244–522 triangles, atlas Rocks) ; la tablette
  passe à `RockPath_Square_Small_1` (783 triangles, atlas PathRocks).
  Comparer `v5/overlook_gros_poste.png` (deux coins tan) et
  `final/overlook_gros_crete.png` (formation moussue, aucun aplat).
- **La brèche est devenue un vrai vide (v7)**. Elle était déclarée dans
  l'en-tête du script depuis le début, mais la silhouette en aplat noir
  montrait le contraire : `rock_smallB` posé à (11,8 ; −2,8) tombait dans
  l'intervalle et le refermait par un pont mince, et la dalle de pied
  remontait à z ≈ −0,4, donc dans l'emprise en Z de la crête. Trois
  déplacements ouvrent le vide sur les DEUX axes de lecture : crête reculée
  au sud (z 3,0 → 4,6) et agrandie (×2,2 → ×2,26), avant-poste porté à
  (17,8 ; −5,8), éclat sorti de l'intervalle vers (19,6 ; −7,2).
- **Tablette et arc** : la nouvelle dalle mesure 1,78 × 0,26 × 1,70 m ;
  `bbox_min.y = −0,0086` donc `KitPlacement.seat()` ne la déplace pas, et
  son sommet tombe à `0,1412 × 1,75 = 0,247` m. L'ancre de l'arc suit ce
  nombre mesuré : **+0,25**, et non l'ancien +0,56.

### 1.2 Source (`turquoise_spring_place.gd`)

- **`SM_Dungeon_CaveArch` et épaules bannies**. La bouche est un trio
  `Rock_Medium` assis au PIED de la pente de 54° (les mâchoires v1, hautes
  sur la pente, flottaient — audit §5).
- **La nappe blanche d'albédo est morte** : l'eau est un maillage local
  portant le shader V2.2 `SH_WorldV2Water` (lu, jamais modifié) + le bruit
  `WorldV2GroundMaterial.grain_texture()`, avec la convention de sommets
  exacte de l'hydrologie (R profondeur, GB courant, A opacité). La
  continuité avec la rivière gelée est donc **de construction** ; elle est
  aussi **mesurée** — §4.2.
- **Vasque → fil → dalles physiquement continus** : la langue du déversoir
  est le MÊME maillage et le MÊME shader que la nappe ; elle épouse le sol
  et s'éteint à 5,47 m de la tête d'affluent gelée (contrat : ≥ 5 m).
- **La vasque a grandi (v7, R 3,0 → 3,3 m)** : c'est la seule surface claire
  du ravin, donc sa part d'image EST la promesse. Contrôle fait : le rayon
  haché monte à R×1,08 = 3,56 m, l'ancre du fruit est à 3,84 m du centre —
  28 cm de berge lui restent.
- **La bouche a baissé (v7)** — mâchoires ×1,35/×1,30 → ×1,15/×1,12,
  couronne redescendue de la pente. Raison mesurée en §2.

### 1.3 Recette de matière commune

`_teinter()` local à chaque lieu, teinte PAR SURFACE, sans mutation de
ressource partagée : (1) `vertex_color_use_as_albedo = false` — sinon
l'atlas Rocks rend PISTACHE au soleil, c'est le bâtisseur de végétation V2.2
qui donne la recette ; (2) la surface « grass » du kit reçoit sa propre
teinte — la coiffe MENTHE nue est l'interdit mesuré v1 ; (3) albédo POSÉ en
absolu pour les matériaux à couleur plate, MULTIPLIÉ pour les atlas
texturés ; (4) roughness ≥ 0,95, spéculaire 0,1.

---

## 2. Le détecteur D3 a rougi sur mon propre rework — journal de la reprise

C'est le fait marquant de cette session, et il n'était pas prévu : le
détecteur R-D3, rejoué sur les silhouettes de v6, a rendu **FAIL** —
belvédère × source 0,511 à 30 m (seuil 0,493), source × ferme abandonnée
0,506 et 0,494, et le belvédère à **0,0011** du seuil contre le Pont de
pierre. Cause lue en aplat noir : les deux lieux étaient devenus des barres
basses de même proportion, et la « bimodalité » du belvédère était refermée
par un pont mince.

La proportion est le levier dominant de ce détecteur, et la bande
`hauteur ÷ emprise ≈ 0,25–0,30` est la plus encombrée du corpus : ferme
0,255 · camps 0,258 · source 0,280 · belvédère 0,296 · pont 0,300. Les deux
lieux y étaient.

| # | changement engagé | H/emprise | verdict D3 rejoué |
|---|---|---:|---|
| v7  | brèche ouverte + source abaissée/élargie | 0,284 | FAIL (belvédère × ferme 0,504) |
| v7b | crête ×2,55 | 0,325 | FAIL (belvédère × hameau 0,508) |
| v7c | crête ×2,35, brèche élargie | 0,300 | FAIL (belvédère × ferme 0,502) |
| v7d | masses rééquilibrées (aire déplacée vers l'avant-poste) | 0,260 | FAIL, nettement pire (4 paires) |
| v7e | arête montante à l'ouest | 0,291 | FAIL (0,507) |
| v7g | interpolation entre v7b et v7c | 0,313 | **PASS** |
| v7b/c matières | famille Kenney sortie → hauteur remontée à 7,34 | 0,323 | FAIL (hameau) |
| **v7c final** | enfoncements de l'avant-poste + crête ×2,26 | **0,311** | **PASS** |

Deux enseignements que je consigne parce qu'ils re-serviront :

1. **Un changement de famille d'asset change la PROPORTION du lieu**, donc
   le verdict D3, même à composition identique. Sortir la famille Kenney a
   fait passer la hauteur d'emprise de 7,01 à 7,34 m et a suffi à faire
   rougir le détecteur. Les deux contrôles ne sont pas indépendants.
2. **Le belvédère vit dans un voisinage dense.** Trop bas il rejoint la
   ferme abandonnée, trop haut le hameau de la rive : ce sont les trois
   mêmes compositions « grande masse + satellite ». Le passage tient, mais
   ses marges sont fines (§4.1), et je le dis plutôt que de le taire.

Après deux tentatives de même nature qui échouaient (v7b puis v7c), j'ai
changé d'hypothèse — d'abord en déplaçant de l'aire d'une masse à l'autre
(v7d, mesuré PIRE, abandonné), puis en pilotant la hauteur d'emprise par un
balayage hors moteur sur la silhouette réelle. C'est ce balayage qui a donné
la cible et l'a tenue.

---

## 3. Conformité aux contrats conservés

- Sites, `poi_id`, `PointOfInterest`, fonctions, récompenses canoniques :
  inchangés. Ancres : le fruit a bougé de ≤ 0,3 m (même côté est, même
  écrin) ; l'arc suit le sommet mesuré de sa nouvelle dalle (+0,25 au lieu
  de +0,56) sur la MÊME tablette, au même endroit local (3,8 ; 5,6).
- **D7** : belvédère 12 modules, source 12 (10 pièces de kit + nappe + lit,
  les deux maillages runtime comptent). Aucune pièce ajoutée : toutes les
  corrections sont des déplacements, des échelles ou des substitutions.
- **D2** : chaque pièce de crête, d'avant-poste, de bouche et de margelle
  déclare son assise ; couverture des tiers extrêmes des deux axes.
- **D4** : distances de route recalculées après déplacement — crête 8,7 m,
  avant-poste 8,5 m, épaulement 8,8 m, épaule 6,4 m (seuil 1,2 m). Source :
  aucun collider à moins de 16 m de la tête d'affluent, langue d'eau
  éteinte à 5,47 m. Caméras gelées non déplacées ; les plans ajoutés sont
  des PLUS.
- **D1a** : exemptions nommées `NappeSource` + `FondVasque` (les deux
  épousent le terrain sommet par sommet). **D1b** : aucun BoxMesh, aucun
  `stone_block`.
- **D5** : aucune coordonnée de site en dur. **D8** : aucun fichier gelé,
  aucun `tests/**`, aucun `tools/**` existant, aucun fichier partagé touché.

---

## 4. Verdicts mesurés — remplis depuis les journaux, pas déclarés

### 4.1 Filets et détecteur

| Contrôle | Résultat | Journal / preuve |
|---|---|---|
| `lot1_defauts` (D0–D8 + 2 témoins) | **PASS — 11 réussis, 0 échoué, 0 erreur de script**, code retour 0 | `etape_filet_lot1.log` |
| `places_contract` | **PASS — 5 réussis, 0 échoué, 0 erreur de script**, code retour 0 | `etape_filet_contrats.log` |
| Détecteur R-D3 rejoué | **PASS**, code retour 0 | `evidence/world_v2/v2_3_b/lot1/controles/verdict_repetition.json` |
| Manifeste des captures finales | **CONFORME** — arbre propre, SHA unique, 19/19 images | `tools/lot1r_manifeste.py` (voie C, lu sans être copié) |

Marges D3, par distance (seuil = max d'IoU entre deux sujets DÉJÀ acceptés) :

| distance | seuil S | belvédère — pire paire | marge | source — pire paire | marge |
|---:|---:|---|---:|---|---:|
| 30 m | 0,4931 | hameau de la rive 0,4773 | **−0,0158** | belvédère 0,4669 | −0,0262 |
| 80 m | 0,4912 | hameau de la rive 0,4822 | **−0,0090** | ferme abandonnée 0,4698 | −0,0214 |
| 160 m | 0,5458 | ferme abandonnée 0,5174 | **−0,0284** | ferme abandonnée 0,4275 | −0,1183 |

**Ce verdict est LOCAL à mes deux lieux** (consigne du lead) : les quatre
autres sujets du lot y sont encore dans leur état rejeté, et le détecteur
compare les lieux deux à deux. Le juge du lot est la passe intégrée du lead,
pas ce fichier. La marge de 0,009 du belvédère à 80 m est à connaître avant
cette passe.

Emprises finales mesurées par l'outil de silhouette :
belvédère **22,41 × 6,96 × 20,41 m** · source **14,44 × 3,19 × 14,16 m**.
Manifestes : commit `dd3de2e`, `repo_dirty: false` pour les deux.

### 4.2 Teintes rendues — l'eau, mesurée et non supposée

Toutes les valeurs sont des moyennes de zone **recalculées sur les pixels**
au moment du montage (`voie_a_montage_eau.py`), sur les captures
`final/`. Le montage annoté est
`final/comparatif_eau_final.png`.

| échantillon | RGB rendu | saturation |
|---|---|---:|
| P1, incidence rasante — **vasque de la source** | 131, 139, 134 | 0,058 |
| P1, incidence rasante — **affluent V2.2 GELÉ, même image** | 105, 128, 116 | 0,180 |
| gros plan, incidence moyenne — **vasque de la source** | 77, 107, 118 | 0,347 |
| gué, incidence moyenne — **rivière V2.2 GELÉE, même moteur** | 68, 105, 107 | 0,364 |
| herbe du ravin (ombre) | 68, 83, 73 | 0,181 |
| herbe au soleil (gué) | 64, 100, 75 | 0,360 |

Deux faits en découlent, et ils ne disent pas la même chose :

1. **Le ruban blanc de P1 n'est pas la nappe blanche rejetée.** Dans la même
   image, l'affluent GELÉ — que je n'ai pas construit et que je n'ai pas le
   droit de toucher — rend le même blanc au même angle. C'est le miroir
   spéculaire du ciel que `SH_WorldV2Water` (SPECULAR 0,4 · ROUGHNESS 0,18)
   produit à incidence rasante sur toute l'eau du monde. La preuve est
   montée côte à côte pour éviter le contresens de revue.
2. **À incidence moyenne, la continuité est atteinte au chiffre près** : ma
   vasque rend (77, 107, 118) et la rivière gelée (68, 105, 107) — le même
   sarcelle, à quelques unités près, sur les trois canaux.

### 4.4 Ce que mon verdict ne PEUT PAS savoir — et de combien

Mon `PASS` est mesuré contre un corpus où **quatre sujets du lot sont encore
dans leur état rejeté**. Pendant que je travaillais, la voie B a changé la
FORME de trois d'entre eux (tertres passés de cônes à des dos arrondis,
sanctuaire doté d'un axe et d'un chevet, tour re-matiérée) et la voie C
travaille le champ. Ces silhouettes-là n'existaient pas quand j'ai mesuré,
et le verdict du lot sera rejoué par le lead sur l'arbre intégré.

Une chose ne bougera pas, et elle vaut d'être dite : **le SEUIL est stable**.
R-D3 le calibre sur le maximum d'IoU entre deux sujets DÉJÀ ACCEPTÉS — la
paire calibrante est ferme abandonnée × pont de pierre, deux lieux que
personne ne retouche. Les seuils 0,4931 / 0,4912 / 0,5458 seront donc les
mêmes à l'intégration. Seules les PAIRES peuvent bouger, jamais la barre.

Voici donc la marge dont je dispose aujourd'hui sur les paires périmées,
pour que le lead sache lesquelles surveiller (marge = IoU − seuil ; plus elle
est négative, plus la paire est loin de rougir) :

| paire (sujet à moi × sujet qui va changer) | 30 m | 80 m | 160 m |
|---|---:|---:|---:|
| belvédère × **champ des mille fleurs** | −0,074 | −0,076 | −0,116 |
| source × champ des mille fleurs | −0,187 | −0,156 | −0,234 |
| source × cimetière du tertre | −0,196 | −0,221 | −0,316 |
| belvédère × tour de guet | −0,224 | −0,230 | −0,284 |
| belvédère × cimetière du tertre | −0,247 | −0,230 | −0,412 |
| source × tour de guet | −0,256 | −0,263 | −0,345 |
| source × sanctuaire forestier | −0,303 | −0,286 | −0,363 |
| belvédère × sanctuaire forestier | −0,320 | −0,300 | −0,370 |

Lecture : **les trois lieux repris par la voie B sont loin** de moi — la plus
proche de leurs paires est à −0,224, il faudrait qu'une silhouette gagne
vingt-deux centièmes d'IoU pour venir me toucher. La seule paire réellement
serrée du côté « qui va changer » est **belvédère × champ des mille fleurs**
(−0,074), et le champ appartient à la voie C.

Le vrai point de fragilité reste ailleurs, et il ne bougera pas à
l'intégration puisqu'il vit contre le corpus stable : **belvédère × hameau de
la rive à 80 m, marge −0,009** (§4.1).

### 4.3 L'hypothèse du lead sur le turquoise : testée, et elle tient

Le lead demandait d'arrêter de pousser la teinte et de tester si c'est
**l'ombre du ravin** qui tue le turquoise. Mesure faite ci-dessus : l'herbe
du ravin perd la moitié de sa saturation par rapport à l'herbe au soleil
(0,181 contre 0,360), et l'eau suit la même loi.

Mais la mesure ajoute une seconde cause que l'hypothèse ne contenait pas, et
c'est elle qui domine dans les vues incriminées : **l'incidence**. La MÊME
vasque, dans le MÊME ravin, à la MÊME heure, rend 0,058 de saturation vue au
ras (P1) et 0,347 vue à angle moyen (gros plan) — un facteur six, sans que
rien du lieu n'ait changé. Les vues où l'eau paraît grise sont des vues
rasantes ; celles où elle rend sarcelle sont des vues plongeantes.

Conséquence honnête pour l'issue proposée : **déplacer la vasque dans une
poche de lumière n'est pas réalisable ici**. Le soleil du monde gelé vient
de l'ouest et c'est la paroi de 14 m, à l'ouest, qui fait l'ombre ; la seule
poche éclairée du secteur est en HAUT du ravin, vingt mètres à l'est et
quatorze mètres plus haut. Y porter la source lui retirerait sa fiction —
l'eau sort du pied du mur, c'est tout le lieu. Je ne l'ai pas fait, et je
n'ai pas poussé la teinte une quatrième fois.

**Statut : `PARTIAL`, mesuré.** Ce que la source offre réellement à distance
est un contraste de VALEUR (le seul point clair du ravin) plus l'anneau de
mousse ; la teinte sarcelle se lit dès que le regard plonge un peu. La revue
tranche : si elle exige une teinte saturée à incidence rasante, les options
sortent de mon périmètre (shader local dédié — refusé par l'arbitrage parce
qu'il romprait la continuité par construction ; ou déplacement du lieu).

---

## 5. Conditions d'arbitrage et d'audit — état après recapture

| Condition | État | Preuve (toutes dans `final/`, manifeste propre) |
|---|---|---|
| Brèche = vide avec ciel (lead B1) | **PASS depuis l'est** | `overlook_breche_est.png` : ciel, mesas et le PYLÔNE visibles entre les deux masses |
| Brèche depuis la montée nord-ouest | **FAIL, mesuré** | `overlook_breche_ouest.png` : la falaise gelée ferme le fond dans cette direction — voir §6.2 |
| Révélation au seuil (lead B2) | **PASS** | `overlook_seuil_p4.png` : la vallée, ses routes, son hameau, ses mesas s'ouvrent d'un coup |
| Panorama depuis la récompense | **PASS** | `overlook_tablette_p5.png` |
| D3 re-mesuré, pas déclaré (lead B3) | **PASS local** | §4.1 + `verdict_repetition.json` |
| Teintes par surface, menthe/terracotta bannies (lead B4) | **PASS** | `overlook_gros_crete.png`, `final/*` |
| Coins tan à faces planes (audit 3ᵉ passage) | **PASS** | famille Kenney sortie du lieu ; comparer `v5/overlook_gros_poste.png` et `final/overlook_gros_crete.png` |
| Petite pièce pâle isolée (audit, 4 passages) | **PARTIAL** | la tablette est désormais une dalle texturée de l'atlas PathRocks, calée entre crête et épaule (`overlook_gros_tablette.png`) ; elle reste une petite pièce claire sur la vue d'identité gelée |
| Assises re-déclarées (lead B5) | **PASS** | filet D2 vert |
| Arc posé sur sa tablette | **PASS** | `overlook_gros_tablette.png` — l'arc est sur la dalle ; sa pose verticale appartient à `WeaponPickup`, hors périmètre |
| Promesse P1 turquoise (lead S1) | **PARTIAL — physique, mesurée** | §4.2, §4.3 |
| Continuité rivière côte à côte (lead S2) | **PASS + chiffré** | `comparatif_eau_final.png` |
| Malecture du ruban blanc (lead §4) | **désamorcée** | même montage, rangée du haut |
| Bouche lisible, fil continu (lead S3) | **PASS** | `spring_gros_fente.png`, `spring_gros_eau.png` |
| Fruit posé dans un écrin (audit §2/7) | **PASS** | `spring_gros_fruit.png` : la baie touche l'herbe, adossée à la margelle est |
| Regard vers la tour au P4 (lead S6) | **PASS** | `spring_approche_p3.png` : la tour de guet se détache sur le ciel |
| Brume / lucioles (lead S4) | **NON ENGAGÉ** | la géométrie doit tenir seule d'abord — chantier ouvert |
| Arbre PROPRE à la capture (audit A-v5-1) | **PASS** | `final/manifest.json` → `repo_dirty: false`, commit unique, 19/19 images |
| Vue depuis la tour (`gp_lointain`) | **BLOQUÉ ici** | caméra de la voie B — à jouer à l'intégration |

---

## 6. Limites honnêtes

1. **La teinte de l'eau dépend d'abord de l'incidence, ensuite de l'ombre**
   (§4.3). `PARTIAL` assumé, mesuré des deux côtés, non compensé par un
   effet.
2. **La brèche ne se lit pas depuis la montée nord-ouest.** Mesuré, pas
   supposé : dans cette direction le fond est la falaise gelée du couchant,
   et aucun réglage de mon lieu ne peut y mettre du ciel. Le vide se lit
   depuis l'est, en sortant — le parcours vidéo a été corrigé en
   conséquence (`parcours_video.json`, étape `sortie_par_la_breche`). Si la
   revue exige le vide DANS la montée, c'est un problème d'implantation du
   lieu, pas de composition, et il sort de mon périmètre.
3. **La vue d'identité gelée reste dominée par un élément que je ne possède
   pas** : la falaise V2.2 pêche, à très grandes faces planes, occupe la
   moitié supérieure du cadre. Le lead l'a relevé et porte le constat à la
   revue ; je n'y touche pas.
4. **Les marges D3 du belvédère sont fines** (−0,009 à 80 m). Elles
   tiennent, elles sont mesurées, et elles peuvent bouger à l'intégration
   puisque quatre autres sujets du lot vont changer de silhouette.
5. **Vie locale (brume, lucioles) non engagée** — conforme à la règle « la
   géométrie tient d'abord seule ».
6. **Vidéo non enregistrée ici.** Je fournis `parcours_video.json` ; la
   décision matérielle du lead interdit tout `.avi` dans git, et
   l'enregistrement est joué par l'outil de la voie C. **Aucun `.avi` n'est
   présent dans mes commits** — vérifiable par `git log --stat`.
7. **llvmpipe.** Toutes les mesures de teinte viennent du rendu logiciel
   gelé du lot : cohérentes entre elles, jamais un budget de frame ni une
   vérité GPU.
8. **Le détecteur D3 que je livre est local à mes deux lieux** — il ne dit
   rien du lot, par construction (consigne du lead).

---

## 7. Fichiers de la voie

- `scripts/world_v2/poi/overlook_summit_place.gd` — rework complet
- `scripts/world_v2/poi/turquoise_spring_place.gd` — rework complet
- `voie_a_montage_eau.py` — outil LOCAL du montage A/B annoté (il recalcule
  les valeurs sur les pixels ; il ne recopie rien)
- `CONCEPTION_belvedere.md`, `CONCEPTION_source.md` — briefs DA, deux
  compositions chacun, arbitrés
- `evidence/world_v2/v2_3_b/lot1r/voie_a/` : `avant/`, `v1/`…`v5/`,
  `final/` (19 plans + manifeste + `comparatif_eau_final.png`),
  `shots_voie_a.json`, `parcours_video.json`
- silhouettes 0°/90° des deux sujets et verdict D3 dans le dossier commun
  du lot (`evidence/world_v2/v2_3_b/lot1/`)

## 8. Commits (petits, locaux, aucun push)

```
63af918  v1  belvédère et source — formes falaise froides, eau au shader V2.2
42b6292  v2  masses Rock_Medium, teinte par surface, eau approfondie
71f7cea  v3  recette V2.2 (vertex albedo coupé), albédos absolus, lit sous la rive
6337db0  v4  arbitrages A+A engagés ; margelles réchauffées, crête moins jaune
1f2eaa3  v5  vasque profonde, margelles Rock_Medium, masse enracinée
149e79c  v6  contacts francs, arc et fruit posés, mousse de rive ; preuves versées
6860118  v7  la brèche ouverte pour de bon, la source hors de la bande commune
0283fc8      preuve : silhouettes et verdict D3 rejoués sur v7
d769b9b  v7b la famille Kenney `rock_*` quitte le belvédère
ec987e9  v7c proportion du belvédère recalée après le changement de famille
dd3de2e      preuve : silhouettes et verdict D3 de v7c
d9945ea      preuve : captures finales (19 plans), montage A/B de l'eau, rapport
233e27b      preuve : verdict D3 rejoué depuis un arbre entièrement propre
```

Aucun `.avi` n'entre dans git (décision matérielle du lead) — contrôlé :
`git log --stat 89a3009..HEAD | grep -c .avi` rend **0**.

Fichiers touchés hors `evidence/`, vérifiés un par un : mes deux scripts de
lieu, mes documents de racine, et `voie_a_montage_eau.py`. **Aucun fichier
gelé, aucun `tests/**`, aucun `tools/**` existant, aucun fichier partagé,
aucun fichier des voies B et C.**

`git log --oneline 89a3009..HEAD` fait foi ; aucun push, le lead récolte par
cherry-pick.
