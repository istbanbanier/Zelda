# Arbitrage des trois plans — R2B.1 (lead, 2026-08-19)

Base commune des trois worktrees : `7c3d3ca`. Les trois plans ont été rendus
AVANT toute implémentation, comme l'exige la directive §2. Ce document fige ce
que le lead a accordé, refusé et ajouté — pour qu'aucun écart ne se découvre
seulement à l'intégration.

## Ce que chaque agent a mesuré (et que le lead a recoupé)

| Agent | Cause première établie | Recoupement du lead |
|---|---|---|
| A — ferme | Le mur de kit **n'a pas de tranche** : face brique plan strict à Z=0,000, face plâtre à Z=−0,200, rien entre les deux ; la face intérieure est **un quad de 6,00 m² pour 2 triangles**. Sur 8 modules : 48 m² d'aplat en 16 triangles. Arases alignées à σ = 0,050 m sur 6,4 m. À l'écran : **24,5 % d'aplats unis, dont un seul de 17,0 %**. | Confirmé visuellement par la baseline AVANT du lead : `ferme_laterale.png` montre le panneau uni plein cadre, `ferme_seuil.png` la coque intérieure plate, `ferme_arriere.png` l'arase droite d'un bout à l'autre. |
| B — arbre | Le **plan de fourche** : `chemin_vivant` et `chemin_mort` divergent de 3,59 m en X pour 0,57 m en Y — plan à **9,0°**, et la caméra de silhouette regarde DEDANS à l'azimut 000°, où les deux moitiés se superposent. Élancement H/l 4,8, anisotropie 1,80. Disque brûlé : 2 harmoniques pures, 5 maxima, `rmax/rmin` 2,13, aire 34,5 m² = 3,9× l'emprise de souche. Bois au sol : rayon 0,155 identique, inclinaison 0,00 pour les deux. | **Recalculé par le lead sur les constantes du générateur** : `chemin_vivant(1) = (2,09 ; 0,33)`, `chemin_mort(1) = (−1,50 ; −0,24)` → ΔX 3,59, ΔY 0,57, `atan2 = 9,0°`. Chiffre exact. Ce diagnostic PRIME sur la piste du disque que le lead avait avancée. |
| C — braise | 54 modules / 82 nœuds / 11 collisions reproduits à l'instrument. **Code et montage divergent d'exactement 1** : le bâtisseur pose 53 ; le 54ᵉ est le `Model` du coffre, instancié au runtime par `chest.gd` sous la `RewardAnchor`. Deux pièges de mesure attrapés par l'agent lui-même : fenêtre headless 64×64, et `unproject_position` rendant des pixels du viewport projet et non de la taille de capture. | Compte cohérent avec la sonde indépendante de la passe précédente (`camps/sonde_mesures.txt`). |

## Décisions du lead

**A1 — Quatrième matériau `MAT_Farm_Stone` : ACCORDÉ.** Faire lire des moellons
en terre cuite serait mentir sur la matière. Trois conditions : le plafond de
**4 500 triangles reste intouché** ; l'en-tête du générateur dit que le lead a
porté la limite de 3 à 4 matériaux le 2026-08-19 et pourquoi ; la ligne
`SM_Farm_Ruins` du manifeste est mise à jour dans le même commit.
*Un plafond relevé sans trace est indiscernable d'un plafond contourné.*

**A2 — Critère d'acceptation visuel mesurable AJOUTÉ par le lead.** Le chiffre
d'aplat de l'agent devient le portail : plus grand aplat uni **≤ 8 %** de
l'image, total des aplats **≤ 12 %**, mesurés à la même méthode et publiés
avant/après. Rendre le verdict du lead reproductible au lieu d'une impression.

**B1 — Troisième rupture de cime : REFUSÉE si elle consomme la cime vivante.**
La moitié vivante intacte EST le récit du lieu — un arbre foudroyé qui a
survécu d'un côté. Les deux ruptures obligatoires sont toutes deux du côté
frappé, à ≥ 1,5 m d'écart ; une lecture supplémentaire se prend sur un moignon
latéral, jamais sur la pointe vivante. La directive demande « deux ou trois » :
deux suffisent, et personne n'a demandé de réécrire la fiction.

**B2 — Racines dans un objet séparé `SM_ThunderstruckTree_Roots` : ACCORDÉ**,
et pour la raison donnée par l'agent : ne pas desserrer le garde-fou
`SOUCHE_LARGEUR` pour lui faire avaler autre chose que la souche. C'est
l'application exacte de « on ne modifie pas un seuil pour faire passer une
géométrie ».

**C1 — Le coffre de récompense NE COMPTE PAS, par exemption NOMMÉE.** Le
plafond §4 borne ce que le bâtisseur compose ; le `Model` du coffre est
instancié au runtime et aucun bâtisseur ne le contrôle — le compter ferait
hériter à 31 lieux un +1 incorrigible. Précédent suivi : le filet camps exempte
déjà `CampfireProp` par son nom. Le journal publie **les deux comptes**
(bâtisseur / total monté) : un nombre exempté qu'on ne voit plus est un nombre
qu'on ne vérifie plus.

**C2 — Pas de dixième coupe.** 45 est conforme ; couper davantage pour le
confort d'une marge coûterait de l'identité contre rien. Mais le test AFFICHE
la valeur courante à côté du plafond, pour que la session suivante lise
« 45/45 » au lieu de le découvrir en rougissant. (Avec l'exemption C1, le
compte bâtisseur est 44 : la marge existe, du bon côté.)

**Trois fichiers de test PROPRES, filets partagés intacts.** `…r2b1_ferme.gd`,
`…r2b1_arbre.gd`, `…r2b1_braise.gd`. `test_world_v2_r2b_farm_tree.gd` et
`test_world_v2_r2b_camps.gd` restent **octet pour octet identiques** : ils
portent les contrôles de lieux GELÉS et trois voies intègrent en parallèle.
Conséquence gravée : les cinq noms `SM_Farm_*` existants ne peuvent pas être
renommés.

## Dettes consignées, NON corrigées ici

- **Branche morte dans `_palisade`** (agent C) : `kind == 0` implique `index`
  pair, donc la branche `SM_Dungeon_RubbleSmall` est inatteignable. Antérieure
  à cette passe, hors périmètre — consignée, pas corrigée en silence.
- **UV0 minimalistes** sur les deux GLB originaux de R2B (dette héritée).

## Erreur du lead, consignée

Deux caméras de la première baseline AVANT (`arbre_fracture` à y=6,4,
`arbre_pied` à y=4,2) étaient **sous le terrain** — le sol au site de l'arbre
est à ~8 m. Elles rendaient le dessous du monde avec un code retour 0 et une
image plausible. Corrigées à 9,5 et 9,3, baseline recapturée (`63c4097`).
Même famille de piège que le checkpoint 4 de la grotte : une origine posée au
jugé sous une masse, et l'image reste crédible tant qu'on ne la regarde pas en
grand. Transmise aux trois agents comme avertissement.

## Arbitrages rendus PENDANT l'implémentation

**C3 — Sabotage du lead corrigé par l'agent.** Le lead avait prescrit
« remets `Chain_Coil` seul → 46 → doit rougir ». Faux : avec l'exemption du
coffre que le lead venait lui-même d'accorder, `Chain_Coil` seul ramène le
compte bâtisseur à 45, donc le test serait resté **VERT** et ce vert aurait été
pris pour une preuve. L'agent l'a détecté et remplacé par un sabotage à DEUX
PAS — 45 attendu vert, 46 attendu rouge — qui prouve les deux côtés de la
frontière et établit que le plafond est **inclusif**. L'erreur est du lead ;
la correction est acquise et gravée dans l'en-tête du test.

**C4 — Neutralité visuelle : la promesse ne tenait pas à toutes les caméras.**
L'agent a mesuré sa neutralité aux cinq plans R2B (approche par l'ouest) ; aux
trois plans du lead (approche par l'est), **trois coupes sur neuf se voient** :
poteau de palissade 280° (3 535 px, 0,384 % du cadre), `Shield_Wooden`
(2 170 px, 0,235 %), `Chain_Coil` (595 px, 0,065 %). L'agent a publié l'écart
au lieu de s'abriter derrière ses propres cadrages, et a séparé le bruit :
1,3 % de diff résiduel est du scintillement d'herbe, établi par un témoin —
6,72 % de diff dans une zone de colline **sans aucune géométrie du camp**.

**C5 — Le lead remet le poteau de palissade 280°, et lui seul.** C'est le plus
visible des trois, c'est une VERTICALE d'avant-plan (une verticale qui
disparaît change la lecture ; un rouleau de chaîne au sol, non), et il
appartient à la palissade, que la directive nomme parmi ce qui doit survivre
intact. Les deux autres restent coupés : la directive nomme « chaînes ou coils
peu visibles » en tête de ce qu'il faut couper, et le manifeste appelle
`Chain_Coil` « candidat n°1 à la coupe ».

**C6 — MARGE NULLE, assumée.** La remise porte le compte bâtisseur à **45 pour
un plafond de 45**. Le plafond est inclusif, donc conforme. Aucune dixième
coupe n'est échangée contre cette place : les neuf prises étaient déjà les
moins visibles, la dixième serait plus voyante que ce qu'elle rachèterait.
**La prochaine session doit lire « 45/45, aucune place » avant d'ajouter quoi
que ce soit** — c'est écrit dans l'en-tête du test, pas seulement ici.

## Décisions d'intégration (lead, après rendu des voies)

**LEAD-1 — Le portail de budget passait au VERT sur un camp VIDE.** Trouvé par
le lead en reproduisant le contrôle de la voie C : en cassant le bâtisseur pour
vérifier que le portail savait rougir, le lieu s'est monté vide et le contrôle
a imprimé « budget §4 tenu : 0/45 modules » puis a rendu VERT. Un plafond seul
déclare conforme tout ce qui n'existe pas. La suite rougissait, mais par
ISS-027 (détecteur d'erreur de script) — un filet qui dépend d'un autre filet
pour signaler l'absence de son propre sujet n'est pas un portail.
**Planchers 30 / 45 / 4 posés par le lead**, sous les deux camps mesurés
(braise 45/70/10, checkpoint 34/47/5) avec marge franche. Cycle prouvé en trois
journaux (`braise/planchers/`) : camp vide VERT (la faiblesse), camp vide ROUGE
par le portail lui-même, camp réel 45/45 VERT.
Deux erreurs du lead dans cette séquence, consignées : le premier sabotage
visait un module INEXISTANT (rien ne se montait, donc rien ne pouvait rougir) ;
le second était inséré au milieu d'un appel multi-ligne et cassait le parsing.
Le contrôle négatif final a été fait proprement, par un `return` en tête de
`_build()`, pour que le rouge vienne du portail et non d'une erreur de syntaxe.

**LEAD-2 — Ferme : PARTIAL assumé, le résiduel est nommé et NON maquillé.**
La voie A a supprimé le défaut principal — le panneau beige uni plein cadre de
`ferme_laterale` a disparu, remplacé par du parement des deux côtés, toit crevé,
intérieur ouvert. Elle a aussi démontré et corrigé un vrai bug : **cinq murs
présentaient leur face brique VERS L'INTÉRIEUR** (yaw 90°/270° inversés), prouvé
en image par une même façade montrant pierre au nord et plâtre uni à l'est.
Portail visuel du lead : **max ≤ 8 % PASS sur les six vues** ; total ≤ 12 %
PASS sur cinq, **FAIL sur `ferme_seuil` (23,74 → 35,46 %)**.

L'agent impute ce FAIL à une limite de l'outil (« il mesure la platitude du
rendu, pas la richesse du volume »). **Le lead ne le suit qu'à moitié** : après
inspection à taille réelle, les tableaux et poteaux de `ferme_seuil` et le
pignon de `ferme_arriere` se lisent comme des **plaques pâles sans matière**,
posées devant la pierre texturée. La directive interdit nommément « les plans
visiblement sans épaisseur » : le chiffre pointe donc aussi un défaut RÉEL, pas
seulement un artefact. Cause exacte : les onze pièces neuves **n'ont pas d'UV0**
(signalé par `gltf_inspect` à chaque export), donc pas de texture.

Décision : **on livre ce PARTIAL tel quel, sans y toucher.** Rouvrir la matière
au moment de l'intégration, sans le contexte de mesure de l'agent, risquerait
de défaire un recalage déjà éprouvé sur capture (la pierre avait viré gris
ardoise à la première passe : le défaut était la SATURATION, pas la luminance).
**Dette nommée : déplier les UV des `SM_Farm_*`.**
Observation supplémentaire du lead, à porter devant la revue plutôt qu'à
laisser découvrir : sur `ferme_arriere`, le mur nord reste un rectangle propre
d'un bout à l'autre — c'est le pignon rompu qui apporte l'irrégularité de
silhouette, pas la maçonnerie.

**LEAD-3 — Deux agents non résumables en fin de passe.** Les transcripts des
voies A et C ont expiré avant la fin de l'intégration. Les corrections encore
nécessaires ont donc été faites PAR LE LEAD dans leurs worktrees, et sont
signées comme telles dans leurs messages de commit. Aucune n'est attribuée aux
agents.
