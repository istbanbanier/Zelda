# Journal d'itérations — agent A (belvédère, source)

Format imposé (§9 de la directive) : AVANT chaque itération, défaut observé →
cause supposée → levier modifié → changement attendu DANS LES PIXELS → caméra
qui doit le montrer. APRÈS : parse, capture, ouverture à taille réelle, mesure,
décision.

## Deux avertissements du lead, notés ici pour qu'on ne les relise pas de travers

1. **Mes cibles chiffrées sont des cibles de CALIBRATION, pas des seuils de
   gate.** « S ≥ 0,25 et H ∈ [170 ; 195] dans `turquoise_spring_joueur` », «
   H 200–225° / V 0,47–0,52 au belvédère » : ces nombres servent à savoir dans
   quel sens tourner un levier et à publier un avant/après honnête. Le contrat
   exige, lui, « turquoise perçu dans la capture joueur, calibré contre l'eau
   V2.2, mesure avant/après » et « minéral froid » — le jugement reste au lead
   et à Istvan. Aucun de ces nombres ne doit être recopié plus tard comme un
   critère du contrat.
2. **Géométrie nouvelle ⇒ emprise à republier.** L'assise rocheuse et les
   gradins du déversoir changent l'emprise des lieux, donc potentiellement la
   proportion H/emprise que le détecteur R-D3 compare entre lieux. Emprise
   avant/après publiée à chaque itération qui touche la forme.

## État de départ, mesuré au pixel (PIL) — captures `lot1r/final/`, commit 7c58573

| Sujet | Zone | RGB rendu | H | S | V |
|---|---|---|---|---|---|
| Belvédère `identite` | masse au soleil | (155 ; 149 ; 138) | 40° | 0,112 | 0,607 |
| Belvédère `identite` | avant-poste | (149 ; 147 ; 135) | 50° | 0,095 | 0,586 |
| Belvédère `identite` | falaise V2.2 (fond) | (161 ; 144 ; 132) | 26° | 0,182 | 0,632 |
| Belvédère `identite` | boulder V2.2 gelé | (120 ; 125 ; 113) | 85° | 0,097 | 0,492 |
| Source `joueur` (GELÉE) | nappe | (125 ; 136 ; 128) | **137°** | **0,079** | 0,534 |
| Source `identite` | vasque | (85 ; 107 ; 112) | 190° | 0,237 | 0,437 |
| Source `identite` | **rivière V2.2** (référence) | (81 ; 111 ; 111) | 179° | 0,273 | 0,436 |

Lecture : le belvédère rend **chaud (H 40°) et plus clair que la falaise du
fond** — l'inverse du « minéral FROID » du contrat. La source rend turquoise
depuis la caméra haute (S 0,237, proche de la rivière 0,273) et **gris-vert
depuis la caméra joueur gelée (S 0,079)** : la nappe blanche n'est pas un
défaut d'albédo, c'est l'**incidence**. Géométrie mesurée : caméra joueur à
(−126,5 ; 13,7 ; 40,0), plan d'eau à ~12,08 m, centre de vasque à 14,9 m →
angle d'incidence **6,1°**. À 6° la composante spéculaire du ciel domine.

---

## Itération 1 — belvédère : la forme avant la couleur

- **Défaut observé** : sur `overlook_gros_crete.png`, la crête lit « des
  oreillers de pierre pâles posés sur l'herbe ». Aucune strate, aucun
  enracinement, contact franc pierre/herbe sur une ligne nette.
- **Cause supposée** : la famille `Rock_Medium_*` est faite de galets
  arrondis facettés à coiffe de mousse. Aucune teinte ne fabrique une strate
  sur un galet — c'est une loi de FORME. Et sa matière rend chaud.
- **Levier** : un GLB dédié (`SM_OverlookCrags.glb`, générateur
  `source_assets/blender/environment/make_overlook_crags.py`) : deux masses
  en piles de bancs (paroi verticale + vire horizontale), **pendage partagé**
  entre les deux (209°, 13,5°) pour qu'elles lisent comme une formation
  rompue et non deux rochers, diaclases verrouillées sur l'azimut, pied
  évasé, couronne rompue, matière portée par `COLOR_0` (ardoise froide).
- **Changement attendu dans les pixels** : des lignes horizontales de valeur
  sur les faces des masses (les vires), une silhouette à ressauts et non
  bombée, une teinte dont le bleu dépasse le rouge (H > 190°) et une valeur
  plus basse que la falaise du fond.
- **Caméras** : `overlook_gros_crete` (strates, contact), `overlook_summit_identite`
  (froideur/valeur, bimodalité), `overlook_summit_joueur`.
- **Produit** : `SM_OverlookCrags.glb` — crête 600 tris / 6,96 m / **5 vires**,
  éperon 520 tris / 4,38 m / **4 vires**, étendue de couleur de sommet 26,9 %
  et 26,8 %, `COLOR_0` vérifié présent dans le JSON du GLB. Chaîne verte.
  Modules du lieu : 12 → **10** (deux GLB + une assise remplacent cinq pièces
  de kit). Collisions 4/6 inchangé.

## Itération 2 — source : l'incidence, pas l'albédo

- **Défaut observé** : dans `turquoise_spring_joueur` (GELÉE), la nappe est un
  ruban gris-vert pâle — la « nappe blanche » que la première corrective
  croyait avoir corrigée. Et la revue note « petite et sombre ».
- **Cause supposée** : ce n'est PAS l'albédo. La même eau rend S=0,237 depuis
  la caméra haute et S=0,079 depuis la caméra joueur. La caméra joueur est à
  1,6 m au-dessus du plan d'eau pour 14,9 m → **6,1° d'incidence**. À cet
  angle (a) la spéculaire renvoie le ciel blanc — Fresnel — et (b) l'alpha de
  rive 0,60 laisse passer l'herbe pâle sur presque toute la surface vue.
- **Levier** : shader local `SH_TurquoiseSpringWater.gdshader` — ALPHA qui
  monte avec le Fresnel (quasi opaque au ras), reflet rasant TEINTÉ turquoise
  au lieu du blanc, spéculaire 0,10 / rugosité 0,42, aucune émission. Plus
  deux réponses géométriques à « petite » : fil élargi avec deux renflements
  (flaques à 8–11 m sous 9–12° au lieu de 15 m sous 6°), et frange mouillée
  irrégulière aux rebords.
- **Changement attendu dans les pixels** : dans `turquoise_spring_joueur`, la
  bande d'eau cesse d'être gris-vert (H≈137°) et passe au turquoise
  (H ≈ 175–190°) avec une saturation qui rejoint l'ordre de grandeur de la
  rivière V2.2 ; deux élargissements visibles dans le premier tiers proche.
- **Caméras** : `turquoise_spring_joueur` (la seule qui juge),
  `turquoise_spring_identite`, `spring_gros_eau`, `spring_gue_riviere` (la
  RÉFÉRENCE d'eau V2.2, capturée dans le même lot pour que la comparaison
  soit faite à moteur, exposition et heure identiques).

## Résultat de l'itération 1+2, mesuré (`voie_a2/iter1`, commit 90f0d67)

| Vue | Zone | avant | après | verdict |
|---|---|---|---|---|
| `turquoise_spring_joueur` (GELÉE) | eau | H 137° S 0,079 | **H 185° S 0,577** | levier CONFIRMÉ, et il dépasse |
| `turquoise_spring_identite` | eau | H 190° S 0,237 | H 188° S 0,602 | idem |
| `spring_gros_eau` | eau | H 193° S 0,270 | H 188° S 0,727 | trop |
| `turquoise_spring_identite` | rivière V2.2 | H 179° S 0,273 | H 179° S 0,273 | **inchangée** (gel respecté) |
| `overlook_gros_crete` | croc face soleil | — | RGB(255,255,255) V 0,999 | **ÉCRÊTÉ** |
| `overlook_gros_crete` | croc face ombre | — | V 0,853 | trop clair |
| `overlook_gros_crete` | assise | — | V 0,624 H 93° | trop claire, VERTE |
| `overlook_gros_crete` | boulder de kit refroidi | H 40° V 0,61 | **H 223° S 0,254 V 0,540** | la cible est là |
| `overlook_summit_identite` | herbe, falaise V2.2 | — | identiques au pixel | rien de gelé n'a bougé |

Ce que je VOIS à taille réelle sur `iter1` : la forme stratifiée **se lit** —
risers et vires visibles, silhouette à ressauts, deux masses distinctes ; mais
les deux crocs sortent **blancs**, et l'empilement de vires régulières lit
« pièce montée ». L'assise lit « dalle de béton ». Le turquoise de l'eau est
franc, et trop.

## Itération 3 — corriger sur mesure, sans changer d'hypothèse

- **Défaut 1 : crocs blancs.** Cause : `baseColorFactor` glTF est LINÉAIRE ;
  (0,355 ; 0,395 ; 0,462) n'est pas un gris moyen mais une valeur claire, et la
  lumière du monde la pousse au-delà de 1. Deuxième cause, indépendante : la
  lumière est CHAUDE, donc un albédo légèrement bleu ressort neutre. Levier :
  base ramenée à (0,0714 ; 0,0764 ; 0,1050) — rapport 1 : 1,07 : 1,47, dérivé
  de la cible **mesurée dans la même image** (boulders de kit refroidis,
  RGB 103/112/138). Attendu : face au soleil autour de 130–160, face à
  l'ombre autour de 75–110, teinte au-delà de 200°.
- **Défaut 2 : pièce montée.** Cause : le retrait était le même sur TOUT le
  pourtour, donc chaque vire faisait un anneau complet. Levier : retrait
  LOPSIDE (amplitude et azimut propres à chaque banc) + épaisseurs beaucoup
  plus inégales (0,34–1,90 au lieu de 0,72–1,35) + couronne franchement
  dissymétrique. Attendu : plus aucun replat ne fait le tour ; d'un côté un
  mur continu, de l'autre de larges vires.
- **Défaut 3 : assise-dalle.** Levier : (0,34 ; 0,36 ; 0,40) → (0,19 ; 0,20 ;
  0,23), bord vers la terre humide et non vers le vert, 28 → 40 segments,
  hachage du rayon doublé, cœur soulevé de 12 → 6 cm. Attendu : une roche
  affleurante plus sombre que l'herbe, à contour non polygonal.
- **Défaut 4 : eau trop saturée.** Levier : les trois couleurs du shader
  remontent leur canal rouge et `glaze_strength` 0,78 → 0,55. Attendu : dans
  la caméra joueur, S autour de 0,35–0,45 — au-dessus de la rivière V2.2
  (0,273), qui reste la référence, sans en être le double.
- **Caméras** : les mêmes, à l'identique.
