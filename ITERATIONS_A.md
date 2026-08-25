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

## Résultat de l'itération 3, mesuré (`voie_a2/iter3`, commit e6dd5fb)

| Vue | Zone | iter1 | iter3 | verdict |
|---|---|---|---|---|
| `turquoise_spring_joueur` (GELÉE) | eau | H 185° S 0,577 V 0,460 | **H 185° S 0,458 V 0,405** | tenu |
| `spring_gros_eau` | eau | S 0,727 | S 0,598 | tenu (fond de vasque) |
| `spring_gue_riviere` | **rivière V2.2** | H 176° S 0,368 V 0,394 | inchangée | la référence |
| `overlook_gros_crete` | croc soleil | V 0,999 (écrêté) | **V 0,496, S 0,038** | valeur juste, FROID absent |
| `overlook_gros_crete` | croc ombre | V 0,853 | V 0,545, S 0,019 | idem |
| `overlook_summit_identite` | herbe, falaise V2.2 | — | inchangées au pixel | gel respecté |

**La fenêtre de référence de l'eau était fausse et a été corrigée.** Celle de
`spring_gue_riviere` tombait sur l'HERBE de la rive gauche (H = 122°) : une
« référence d'eau » qui mesurait de la prairie. Repositionnée sur le cours
lui-même après vérification à l'œil sur l'image, elle donne **H 176–185°,
S 0,368–0,372, V 0,39–0,43**. C'est la vraie référence V2.2, et elle change la
lecture : la source à S 0,458 est **au-dessus** de la rivière d'environ un
quart, dans la même famille de teinte et de valeur. C'est ce que « l'œil
turquoise, seule note froide saturée du ravin » demande — pas une couleur
étrangère au monde. (La première référence, S 0,273, venait d'une fenêtre de
`turquoise_spring_identite` qui mélangeait eau et berge.)

Ce que je VOIS sur `iter3` : l'eau est franchement turquoise depuis la caméra
joueur gelée, la chaîne vasque → déversoir → écoulement se lit, et le ruban
s'élargit dans son premier tiers. Le belvédère a la bonne VALEUR (il est enfin
plus sombre que la falaise du fond) mais il est **gris neutre**, et il lit
toujours **« tambours empilés »** — la valeur juste rend même ce défaut plus
net qu'en blanc.

## Itération 4 — le froid, et casser la pile de tambours

- **Défaut 1 : gris neutre.** Cause : la lumière du monde est chaude et mange
  un biais bleu de 1 : 1,07 : 1,47. Levier : rapport porté à **1 : 1,20 :
  2,03** en BAISSANT le rouge et le vert (monter le bleu réécrêterait).
  Attendu : RGB proche de (100 ; 110 ; 135), S autour de 0,20–0,26.
- **Défaut 2 : tambours empilés.** Deux causes, et la première n'avait pas
  été traitée : (a) les diaclases n'avaient que 7 %/5 %/3 % d'amplitude, donc
  chaque banc était un anneau quasi circulaire ; (b) le retrait cumulé
  (−0,07..−0,17 par banc) faisait tomber le sommet à 0,40 du pied — un cône.
  Levier : amplitudes portées à 18 %/13 %/7,5 % et trois entailles franches
  (des CÔTES verticales qui traversent tous les bancs), retrait divisé par
  deux (sommet vers 0,70), couronne rabaissée et décalée, 20 → 24 côtés.
  Attendu : des contreforts verticaux visibles d'un banc à l'autre, une
  silhouette qui garde son épaule au lieu de s'effiler.
- **Défaut 3 : assise invisible.** À (0,19…) elle passait sous l'herbe et se
  confondait avec l'ombre portée. Posée entre les deux essais, gris neutre
  légèrement froid, et rayons réduits (4,25 → 4,00 ; 2,95 → 2,80) parce que
  les crocs ont grossi : l'écart entre les deux lobes doit rester de l'herbe.
- **Emprise des crocs** : crête 7,17 → 7,47 → **8,10 m**, éperon 4,77 → 4,96
  → **5,54 m**. Écart entre les deux masses : 3,8 m → **3,0 m** (calcul sur
  centres et demi-emprises). Le vide reste ouvert sur les deux axes.

## Résultat de l'itération 4, mesuré (`voie_a2/iter4`, commit 6de2930)

| Vue | Zone | iter3 | iter4 | cible mesurée |
|---|---|---|---|---|
| `overlook_gros_crete` | croc face soleil | H 263° S 0,038 V 0,496 | **H 226° S 0,183 V 0,490** | boulder de kit refroidi : H 223° S 0,254 V 0,540 |
| `overlook_gros_crete` | croc face ombre | H 187° S 0,019 V 0,545 | **H 219° S 0,181 V 0,545** | idem |
| `overlook_summit_identite` | masse | H 351° S 0,032 V 0,538 | **H 229° S 0,113 V 0,519** | falaise V2.2 du fond : V 0,632 |
| `overlook_summit_joueur` | masse proche | H 33° S 0,076 V 0,503 | **H 217° S 0,124 V 0,460** | — |
| `turquoise_spring_joueur` | eau | S 0,458 | S 0,456 | rivière V2.2 : S 0,368 |

Le **minéral froid est atteint et mesuré** : les crocs et les boulders de kit
du même lieu appartiennent maintenant à la même famille (H 217–229° contre
223°), et la formation est plus SOMBRE que la falaise du fond (0,49–0,52
contre 0,632), là où au départ elle était plus claire ET chaude (H 40°,
V 0,607).

### Emprise, avant/après (demandée par le lead) — `probe_place_metrics.gd`

| Lieu | avant (`de43152`) | après | mesh |
|---|---|---|---|
| `valley.poi.overlook_summit.01` | 22,4 × 7,0 × 20,4 m | **22,1 × 8,0 × 18,6 m** | 14 → 12 |
| `valley.poi.turquoise_spring.01` | 14,4 × 3,2 × 14,2 m | **14,4 × 3,2 × 14,2 m** | 14 → 14 |

Mesure réelle des deux états : le script remet les deux fichiers de lieu à
`de43152`, mesure, restaure, et VÉRIFIE la restauration (`git diff --quiet`)
avant de rendre la main — une mesure « avant » qui laisserait le dépôt dans
l'état ancien serait pire qu'aucune mesure.

Lecture pour R-D3 : le belvédère gagne un mètre de HAUT et perd 1,8 m en
profondeur ; son rapport hauteur/emprise passe de 0,313 à **0,362**, ce qui
l'ÉLOIGNE de la bande 0,25–0,30 où cinq lieux du corpus se ressemblaient.
L'emprise de la source ne bouge pas d'un centimètre : le fil élargi, ses
renflements et la frange restent dans l'enveloppe déjà fixée par les roches.

## Itération 5 — changer d'hypothèse sur la forme, et réparer ma régression

**Règle des deux échecs, appliquée.** Le défaut « pile de dalles » a résisté à
DEUX passes de géométrie (retrait lopside ; puis diaclases profondes + retrait
divisé par deux). Les deux ont changé les pixels — donc ni la scène, ni le
SHA, ni la caméra, ni le matériau, ni la visibilité de la géométrie ne sont en
cause : ce sont bien mes leviers qui ne suffisent pas. J'arrête donc de régler
des constantes de FORME et je change d'hypothèse.

- **Nouvelle hypothèse, et elle est déjà écrite dans le dépôt** : sur des
  faces quasi verticales, sous ce ciel, l'irradiance ambiante domine et
  l'orientation des normales ne rapporte presque rien — chiffré par le
  générateur des stèles du champ (une face rendait UNE valeur, p10-p90 = 1
  niveau, pour 465 normales distinctes). Ce n'est donc pas plus de relief
  qu'il faut, c'est de la **valeur dans la face**.
- **Levier** : trois modulations neuves dans `COLOR_0` — joint de banc sombre
  au pied de chaque lit, arête haute plus claire, mouchetage verrouillé sur
  l'azimut ; plus le creux de diaclase renforcé (0,30 → 0,45) et une
  harmonique courte de plus. Mesure du générateur : **étendue de couleur de
  sommet 31 % → 66 %**, sans écrêtage (p90 = 0,915).
- **Attendu dans les pixels** : les grandes faces cessent d'être des aplats ;
  une ligne sombre marque le pied de chaque banc ; la lecture « strate »
  passe par la valeur et non plus seulement par le ressaut.
- **Réparation d'une régression que J'AI introduite** : la frange mouillée de
  la source sortait en **coins NOIRS** autour de l'eau (`iter3/spring_gros_eau`,
  `spring_gros_fente`) — c'est l'anneau noir que la v3 de la première
  corrective avait supprimé, revenu par la porte que la frange venait
  d'ouvrir. La plage de teinte passe de 0,72–1,45 à 1,30–1,75 (de « un peu
  sous l'herbe » à « herbe ») et la largeur max de 0,55 à 0,42 m.
- **Et les mâchoires de la source rendaient OLIVE** — même dérive qu'au
  belvédère, même cause (lumière chaude). Rapport bleu/rouge relevé, coiffe de
  mousse dotée de sa propre teinte pour qu'elle ne reparte pas en menthe.

## Résultat de l'itération 5, mesuré (`voie_a2/iter5`, commit `1a72363`)

### Bilan DÉPART → FIN, mesuré au pixel dans les caméras GELÉES

| Vue gelée | Zone | départ (`7c58573`) | fin (`1a72363`) |
|---|---|---|---|
| `overlook_summit_identite` | masse de crête | (155;149;138) **H 40° S 0,112 V 0,607** | (102;104;114) **H 229° S 0,102 V 0,446** |
| `overlook_summit_identite` | éperon | (118;124;111) H 85° S 0,102 V 0,485 | (99;107;116) **H 213° S 0,148 V 0,455** |
| `overlook_summit_joueur` | masse proche | (157;150;139) H 36° V 0,614 | (91;95;101) **H 217° V 0,395** |
| `turquoise_spring_joueur` | eau | (125;136;128) **H 137° S 0,079** | (54;98;105) **H 189° S 0,490** |
| `turquoise_spring_identite` | eau | (85;107;112) H 190° S 0,237 | (50;94;101) H 189° S 0,503 |
| — | **rivière V2.2 (référence)** | H 176–185° S 0,368–0,372 | **identique au pixel** |
| — | herbe, falaise V2.2 du fond | — | **identiques au pixel** |

Les deux masses du belvédère sont passées d'une teinte CHAUDE (H 36–85°) et
plus claire que la falaise du fond, à une teinte FROIDE (H 213–229°) et plus
sombre qu'elle (0,45 contre 0,632). L'eau de la source est passée du gris-vert
(H 137°, S 0,079) au turquoise (H 189°, S 0,490), au-dessus de la rivière V2.2
mesurée dans le même lot (S 0,368) — c'est bien « la seule note froide saturée
du ravin », dans la famille de teinte du monde et non hors d'elle.

**Une seconde fenêtre de mesure était fausse, trouvée de la même façon que la
première.** Celle de l'« éperon » tombait sur la FALAISE V2.2 du fond : elle
rendait donc un delta rigoureusement nul à chaque itération — un chiffre
parfaitement stable qui ne mesurait pas le sujet. Corrigée après vérification
à l'œil ; c'est la deuxième fois de cette passe, et les deux fois le symptôme
était le même (une valeur qui « ne bouge pas »).

### Ce que je VOIS à taille réelle sur `iter5` (visible / ambigu / faible / non concluant)

- Belvédère, froideur et valeur : **visible**. Les deux masses lisent ardoise
  bleutée et se détachent en masse sombre sur la falaise pâle.
- Belvédère, bimodalité et brèche : **visible** — `overlook_breche_est` montre
  du ciel et des montagnes lointaines entre les deux masses ; `overlook_seuil_p4`
  montre le panorama entièrement dégagé.
- Belvédère, strates : **visible** (paroi/vire alternées, joint de banc sombre
  au pied de chaque lit).
- Belvédère, « formation » plutôt que « rochers disposés » : **faible**. Les
  masses lisent encore comme un EMPILEMENT DE DALLES INCLINÉES, pas comme une
  falaise. Trois passes y ont travaillé (retrait lopside, diaclases profondes +
  retrait divisé par deux, valeur dans la face) ; chacune a amélioré, aucune
  n'a supprimé la lecture. **Non résolu.**
- Belvédère, enracinement : **ambigu**. L'assise sombre se voit au pied en gros
  plan, mais dans les deux caméras gelées elle se distingue mal de l'ombre
  portée de la masse.
- Source, turquoise dans la caméra joueur gelée : **visible**, et c'est le
  changement le plus net de la passe.
- Source, chaîne arrivée → vasque → déversoir → écoulement : **visible** ; le
  fil élargi et ses deux renflements se lisent depuis la caméra joueur.
- Source, roches froides : **visible**, et sans doute un cran TROP — mesuré
  H 206–209° S 0,30, contre H 143–155° S 0,13 avant. Elles lisent « bleu »
  plutôt que « pierre froide ». **À arbitrer.**
- Source, rebords mouillés : **faible** dans les caméras gelées (l'incidence
  rasante les écrase) ; l'anneau noir que j'avais introduit a bien disparu.

### Ce qui reste non résolu, avec sa mesure

1. **Le belvédère lit « dalles empilées ».** Trois hypothèses testées, aucune
   suffisante. La suivante à essayer n'est plus un réglage : il faudrait des
   masses NON CONVEXES (un contrefort qui déborde d'un banc à l'autre, une
   niche creusée), ce qui demande de changer la topologie du générateur, pas
   ses constantes.
2. **La crête est devenue plus sombre que les boulders de kit qu'elle devait
   rejoindre** : croc V 0,391–0,468 contre 0,540 pour la cible. Cause connue
   et chiffrée : les modulations ajoutées dans `COLOR_0` ont baissé la moyenne
   (p10 0,716 → 0,474). Correctif d'une ligne — remonter les trois couleurs de
   `MAT_ARDOISE`/`MAT_FRACTURE` d'environ 15 % — mais il n'est PAS appliqué :
   il ne serait pas capturé, donc pas vérifié, et je ne livre pas de changement
   non vu.
3. **Un objet pâle isolé dans la caméra joueur du belvédère** : mesuré
   RGB(170;174;131), V **0,683** — l'objet le plus CLAIR du cadre, dans une
   herbe à 0,407. C'est un `Bush_Common` teinté `TONE_DRY` (0,74 ; 0,70 ;
   0,48). Même remarque : le correctif est d'une ligne, il n'est pas appliqué
   faute de capture pour le vérifier.
4. **L'eau reste plate en gros plan** : le dégradé de profondeur et la mousse
   de rive se lisent peu à courte distance.
5. **La tablette `RockPath_Square_Small_1` lit « pavage »** en gros plan (un
   damier de petites dalles). Elle porte l'ancre de l'arc, dont la hauteur est
   calée sur son sommet mesuré : la changer demande de recalculer l'ancre.
