# R2B.1 — corrective ferme, arbre, budget braise : rapport du lead

Base `7c3d3ca` · intégré à `e2bf32a` · 27 commits cherry-pickés des trois
voies, aucun merge. Rendu LOGICIEL (llvmpipe) : régression visuelle seulement,
jamais une mesure de performance. **Aucun verdict artistique auto-déclaré.**

## Validation §8

| Contrôle | Résultat |
|---|---|
| Suite `world_v2` complète | **85 réussis, 0 échoué, RC=0**, zéro erreur de script — 68 du monde + 8 ferme + 8 arbre + 1 braise |
| Boot → Menu → Nouvelle partie → WorldV2 | **23 assertions, RC=0** |
| Golden masters byte-identiques | **6/6 OK** (`sha256sum -c GM_BASELINE_SHA256.txt`) |
| `gltf_inspect` | **VALIDE** sur les deux GLB régénérés |
| `git diff --check` | propre |
| Arbre / distant | propre · distant == local |

Budgets de triangles **inchangés** : SM_Farm_Ruins 1 624 / 4 500 ·
SM_ThunderstruckTree 2 526 / 6 000. Aucun seuil de qualité n'a été modifié
dans cette passe.

## Ferme abandonnée — **PARTIAL assumé**

**Cause première mesurée** : le mur de kit n'a pas de tranche — face brique en
plan strict à Z=0,000, face plâtre à Z=−0,200, rien entre les deux ; la face
intérieure est **un quad de 6,00 m² pour 2 triangles**. À l'écran : 24,5 %
d'aplats unis, dont un seul de 17,0 %.

**Bug réel trouvé et corrigé en chemin** : cinq murs présentaient leur face
brique **vers l'intérieur** (yaw 90°/270° inversés). Démontré, pas supposé —
une même façade montrait la pierre au nord et le plâtre uni à l'est ; un mur
crépi le serait sur ses quatre faces.

Huit contrôles verts, **reproduits par le lead** (RC=0). Portail visuel du
lead : **max ≤ 8 % PASS sur les six vues** ; total ≤ 12 % PASS sur cinq,
**FAIL sur `ferme_seuil` (23,74 → 35,46 %)**.

**Le lead ne suit qu'à moitié l'explication de l'agent.** L'agent impute ce
FAIL à une limite de l'outil (« il mesure la platitude du rendu, pas la
richesse du volume »). Après inspection à taille réelle, les tableaux et
poteaux de `ferme_seuil` et le pignon de `ferme_arriere` se lisent comme des
**plaques pâles sans matière** posées devant la pierre texturée. La directive
interdit nommément « les plans visiblement sans épaisseur » : le chiffre pointe
donc aussi un défaut réel. Cause exacte : les onze pièces neuves **n'ont pas
d'UV0**, donc pas de texture. **Dette nommée : déplier les UV des `SM_Farm_*`.**

Observation supplémentaire du lead, portée ici plutôt que laissée à découvrir :
sur `ferme_arriere`, le mur nord reste un rectangle propre d'un bout à l'autre
— c'est le pignon rompu qui apporte l'irrégularité, pas la maçonnerie.

## Arbre foudroyé — technique **VERT**

**Cause première mesurée par l'agent, recalculée par le lead** : le plan de
fourche. `chemin_vivant(1) = (2,09 ; 0,33)`, `chemin_mort(1) = (−1,50 ; −0,24)`
→ 3,59 m en X pour 0,57 m en Y, plan à **9,0°** — et la caméra de silhouette
regarde dedans, où les deux moitiés se superposent. Ce diagnostic prime sur la
piste du disque brûlé qu'avait avancée le lead.

Huit portails verts. Mesures avant → après : emprise latérale au pire azimut
2,32 → **4,22 m** · anisotropie 1,81 → **1,17** · ruptures 1 → **2 à 1,65 m
d'écart** · concavité de souche −0,025 → **+0,082 m** · écart minimal des
saillies 1,4° → **41,4°** · raie dominante du disque 68 % → **23 %**.

**Le lead avait refusé la troisième rupture de cime** proposée par l'agent :
elle consommait la moitié vivante, donc le récit du lieu — un arbre foudroyé
qui a survécu d'un côté. Les deux ruptures obligatoires sont toutes deux du
côté frappé.

**L'agent a été démenti par sa propre mesure et n'a rien touché.** Il craignait
que les contreforts-racines refassent une masse radiale au pied. Mesuré : aire
au sol 39,3 → **28,8 m²**, raie dominante 58 % → **19 %**. La crainte portait
sur une régularité qui n'existe plus ; géométrie inchangée, et un huitième
portail surveille désormais cette masse.

**Son huitième portail était d'abord faux et il l'a attrapé** : il sommait les
secteurs occupés, si bien qu'il **passait au vert sur la géométrie r02** — un
contrôle qui récompense le maillage le plus pauvre. Corrigé, cycle refait,
8/8 rouges sur r02 puis 8/8 verts.

## Camp braise — budget **tenu, marge nulle**

53 modules bâtisseur avant (54 montés, le 54ᵉ étant le coffre de récompense
instancié au runtime). Neuf coupes, puis **le poteau de palissade 280° remis
sur arbitrage du lead** : c'était le plus visible des trois coupes que l'A/B
révélait (0,384 % du cadre), c'est une verticale d'avant-plan, et il appartient
à la palissade que la directive nomme parmi ce qui doit survivre.

Final : **45 modules bâtisseur / 45 au plafond — marge nulle, assumée**,
70/90 visuels, 10/24 collisions. Écrit en tête du test : la prochaine session
lit « 45/45, aucune place » au lieu de le découvrir en rougissant.

**Trois trouvailles de cette voie :**
1. L'agent a mesuré sa neutralité aux caméras du lead, pas seulement aux
   siennes, et a **publié l'écart** : trois coupes sur neuf se voyaient. Il a
   séparé le bruit d'un témoin — 6,72 % de diff dans une zone sans géométrie
   du camp, donc scintillement d'herbe.
2. **Le sabotage prescrit par le lead ne mordait pas** : il comptait le coffre
   que le lead venait d'exempter. L'agent l'a remplacé par un sabotage à deux
   pas, prouvant que le plafond est **inclusif** (45 passe, 46 rougit).
3. **Le portail passait au VERT sur un camp VIDE** — trouvé par le lead en
   reproduisant le contrôle : `0 ≤ 45` donc « budget tenu : 0/45 ». La suite
   rougissait, mais par ISS-027, pas par le portail. **Planchers 30/45/4 posés
   par le lead**, cycle prouvé en trois journaux.

## Ce qui reste ouvert

- **Dette UV0** sur les onze pièces `SM_Farm_*` — cause du seul FAIL du portail visuel.
- Mur nord de la ferme encore rectangulaire (pignon excepté).
- Branche morte de `_palisade` (`kind == 0` implique `index` pair) — antérieure à la passe, consignée, non corrigée.
- Marge de budget nulle au camp braise.
