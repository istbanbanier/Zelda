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

### Budgets — ce qui est mesuré et ce qui ne l'est pas

`probe_place_metrics.gd` a réellement tourné (log `emprise_apres.log`) et rend,
sur la scène montée : belvédère **12 maillages, 4 corps de collision,
8 appuis** ; source **14 maillages, 3 corps, 11 appuis**. Les plafonds « micro »
du contrat sont 12 modules / 30 nœuds visuels / 6 collisions.

Le compteur de MODULES de D7 n'est pas celui-là (il compte les instances de
scène + les maillages runtime, et exclut le sous-arbre d'un `RewardAnchor`) :
compté sur le code, le belvédère tient **10/12** (deux GLB, une assise runtime,
la marche, le socle, la tablette, deux éclats, deux buissons — cinq pièces de
kit ont disparu au profit des deux GLB) et la source reste **12/12** (rien
d'ajouté : le fil élargi, ses renflements et la frange vivent dans les deux
maillages runtime qui existaient déjà).

**MESURÉ APRÈS COUP — l'item n'est plus `NON VÉRIFIÉ`.** `sonde_budget_lot1.gd`
a fini par obtenir le verrou partagé, `RC_SONDE=0`, journal
`evidence/world_v2/v2_3_b/lot1r/voie_a2/budget_a2.log` :

| Lieu | famille | modules | visuels | collisions | aire runtime |
|---|---|---:|---:|---:|---:|
| `valley.poi.overlook_summit.01` | micro | **10** / 12 | 12 / 30 | **5** / 6 | **0,0 %** / 20,4 % |
| `valley.poi.turquoise_spring.01` | micro | **12** / 12 | 14 / 30 | **4** / 6 | **0,1 %** / 20,4 % |

Le compte de modules établi sur le code était juste. Les trois budgets du
contrat sont tenus sur les deux lieux.

Un écart apparent avec `probe_place_metrics.gd` (qui annonçait 4 et 3 corps)
n'en est pas un : cette sonde-là compte les `StaticBody3D`, celle-ci compte les
`CollisionShape3D`. La forme de plus, dans chaque lieu, est la sphère
`Decouverte_forme` du `PointOfInterest` — elle ne porte aucune collision de
décor. Les deux nombres sont vrais ; ils ne répondent pas à la même question.

L'aire runtime à 0,0 % et 0,1 % confirme aussi que l'exemption nommée
fonctionne : `AssiseCrocs`, `NappeSource` et `FondVasque` sont bien exclues du
calcul — ce qui rend l'arbitrage ci-dessous d'autant plus nécessaire, puisque
c'est cette exemption qui produit ce 0,0 %.

### Une exemption D1a a été ajoutée, et c'est un choix à arbitrer

`AssiseCrocs` est déclarée dans `exemption_runtime`, comme `NappeSource` et
`FondVasque` de la source. La convention du dépôt pour cette exemption est
écrite dans la source elle-même : « une surface qui suit le terrain sommet par
sommet, comme `SolBrule` de l'arbre foudroyé ». L'assise fait exactement cela.

**ACCEPTÉE PAR LE LEAD** (précédent `NappeSource` / `FondVasque` et les trois
`Tertre_*` du cimetière : exemption D1a seulement, comptée au D7). L'assise
compte donc bien dans les 10 modules du belvédère, et n'entre pas dans la part
d'aire runtime.

## Itération 6 — les deux correctifs d'une ligne, désormais budgétés en capture

Le lead a tranché : l'exemption `AssiseCrocs` est acceptée, les deux correctifs
retenus sont commandés avec une passe de capture, et la lecture « dalles
empilées » est présentée en l'état (trois hypothèses testées et mesurées
suffisent pour cette passe ; le changement de topologie n'est pas commandé).

- **Défaut 1 : la crête est plus sombre que les cailloux à son pied.** Mesuré
  sur `iter5/overlook_gros_crete.png` : croc V 0,391 (face au soleil) et 0,468
  (face à l'ombre) contre **0,540** pour les boulders de kit refroidis du même
  lieu, mesurés dans la MÊME image. Cause connue et chiffrée : les trois
  modulations ajoutées en v4 dans `COLOR_0` ont fait monter l'étendue (31 % →
  66 %) mais baisser la moyenne (p10 0,716 → 0,474).
- **Levier** : `MAT_ARDOISE` et `MAT_FRACTURE` × 1,35. Le facteur est calculé,
  pas choisi — la face à l'ombre demande 0,253/0,184 = 1,375 en linéaire pour
  passer de 0,468 à 0,540 ; retenu 1,35 pour garder la vire la plus claire sous
  la valeur de la falaise V2.2 du fond (0,632), qui est le vrai plafond.
- **Défaut 2 : le buisson sec est l'objet le plus CLAIR de la caméra joueur.**
  Mesuré RGB(170 ; 174 ; 131), **V 0,683**, dans une herbe à 0,407 — et il y
  est seul au milieu du pré.
- **Levier** : `TONE_DRY` × 0,71. Calculé aussi : l'albédo est multiplié en
  espace sRGB, donc un facteur k y vaut k^2,2 en linéaire ; pour un rapport
  linéaire de 0,47 il faut k = 0,47^(1/2,2) ≈ 0,71. La teinte ocre ne bouge
  pas — le défaut est une VALEUR, pas une couleur.
- **Attendu dans les pixels** : croc autour de 0,50–0,54, donc dans la famille
  des boulders de kit ; buisson autour de 0,48, au-dessus de l'herbe mais plus
  jamais le point le plus clair du cadre.
- **Caméras** : `overlook_summit_identite`, `overlook_summit_joueur`,
  `overlook_gros_crete`. Une seule passe ; commit si l'image confirme, revert
  documenté si elle infirme.
- **Contrôle du GLB** : la taille du fichier est restée identique au bit près
  (121 536 octets), ce qui est exactement le symptôme du piège « exporter à la
  main rend l'ANCIEN maillage » de `tools/CLAUDE.md`. Vérifié par le CONTENU et
  non par la taille : `baseColorFactor` du GLB lit bien
  `[0,0767 ; 0,0919 ; 0,1557]` et `git diff` voit le binaire changer. La taille
  ne bougeait pas parce que seuls des flottants ont été remplacés.

## Résultat de l'itération 6, mesuré (`voie_a2/iter6`, capture RC=0)

### Correctif 1 — CONFIRMÉ, gardé

| Zone (`overlook_gros_crete`) | iter5 | **iter6** | cible mesurée |
|---|---|---|---|
| croc, face à l'ombre | 0,468 | **0,549** | boulder de kit : **0,540** |
| croc, face au soleil | 0,391 | **0,457** | — |
| masse (`_identite`) | 0,446 | **0,498** | falaise V2.2 : 0,632 (plafond) |

Teinte inchangée (H 220–226°, S 0,19), et la vire la plus claire reste sous la
falaise du fond. À taille réelle, la crête appartient enfin à la même famille
que les cailloux à son pied — c'était exactement le défaut à corriger.

### Correctif 2 — INFIRMÉ, reverté

La capture n'a pas bougé **d'un centième** : RGB(170,7 ; 174,2 ; 131,1),
V 0,683, avant comme après. Mesuré ensuite sur toute la série, le pixel est
identique depuis l'état de départ `7c58573` — il n'a bronché ni au
remplacement des deux masses, ni au refroidissement des pièces de kit.

**Cet objet n'appartient pas au lieu** : c'est le semis de végétation V2.2,
gelé, que la règle transversale nº 1 du contrat interdit de toucher. Mon
diagnostic était faux, et pour la raison exacte qui a déjà produit deux
fenêtres de mesure fausses dans cette passe : j'ai attribué l'objet à
`TONE_DRY` sur la seule foi de sa COULEUR (même ocre jaune-vert), sans jamais
vérifier que c'était bien lui. La méthode qui tranche est dans
`tools/CLAUDE.md` — repeindre le nœud d'une couleur impossible, recapturer,
mesurer le pixel — et je ne l'ai pas appliquée.

`TONE_DRY` revient donc à (0,74 ; 0,70 ; 0,48). Aucune mesure ne demande de la
changer, et un changement sans mesure n'entre pas.

**Écart nommé** : les PNG d'`iter6` ont été rendus avec `TONE_DRY` assombri,
que le code livré ne porte plus. L'écart ne concerne que les deux
`Bush_Common` du lieu ; il ne touche aucune des grandeurs mesurées ci-dessus,
qui portent toutes sur les crocs, les boulders de kit et la falaise. Je le
signale plutôt que de le passer sous silence : la capture prouve le
correctif 1, elle ne prouve rien sur `TONE_DRY`.

### Point 3 du lead — « dalles empilées » présenté en l'état

Trois hypothèses testées et mesurées (retrait lopside ; diaclases profondes +
retrait divisé par deux ; valeur dans la face). Chacune a amélioré, aucune n'a
supprimé la lecture. Le changement de topologie — masses non convexes,
contrefort qui déborde d'un banc à l'autre, niche creusée — n'est pas un
réglage et n'est pas commandé. La limite est nommée telle quelle.

---

# CONVERGENCE LOT 1.R.1 — le verdict Codex rejette les deux lieux

Verdict, inspection réelle des planches : belvédère **REJET** — « reste une pile
de dalles bleues » ; source **REJET** — « trop petite et secondaire dans la
caméra joueur ». Le niveau demandé n'est plus « identifiable » mais « lisible,
composé et mémorable depuis la caméra du joueur ».

Ce que je VOIS moi-même à taille réelle avant de toucher quoi que ce soit, sur
`iter6/overlook_summit_identite.png` et `iter6/overlook_summit_joueur.png` :
la crête est une **pièce montée de trois ou quatre galettes bleu-gris**, chacune
avec un replat qui fait le tour ; le contact avec l'herbe est une **ligne
franche** ; l'assise ne se distingue pas de l'ombre portée. L'éperon est la même
pièce montée en plus petit. Le verdict est juste, et mes trois itérations de
réglage (retrait lopside, diaclases profondes, valeur dans la face) n'ont
jamais attaqué la cause : **la topologie elle-même est un empilement d'anneaux**.

Sur `iter5/turquoise_spring_joueur.png` : l'eau est un **filet turquoise** dans
le tiers bas du cadre, entouré de **cailloux bleu marine** — la couleur est
acquise, la présence n'existe pas. Ce n'est pas « un œil » : c'est une flaque et
quelques galets, écrasés par le talus brun qui occupe la moitié de l'image.

## Itération 7 — belvédère : CHANGER LA TOPOLOGIE, pas les constantes

- **Défaut observé** : « pile de dalles ». Chaque `banc` du générateur est un
  couple d'anneaux (paroi verticale + vire horizontale) dont le rayon est
  constant en azimut à un facteur près. Un anneau retiré fait donc **le tour**,
  et une pile d'anneaux est une pièce montée. Le retrait « lopside » de la v2
  modulait l'amplitude du retrait, jamais son EXISTENCE : la vire faisait
  toujours le tour, plus large d'un côté.
- **Cause** : la forme est engendrée par une boucle `for k in range(nb_bancs)`
  qui empile des tranches. Aucune constante de cette boucle ne peut produire une
  surface continue — c'est une propriété de la structure, pas de ses valeurs.
  C'est exactement la conclusion écrite en fin d'itération 5 (« la suivante
  n'est plus un réglage : masses NON CONVEXES, contrefort qui déborde d'un banc
  à l'autre, niche creusée — changer la topologie du générateur »).
- **Levier** : le générateur cesse d'empiler. Une seule surface continue
  `r(θ, t)` par masse, échantillonnée finement, composée de :
  1. un **profil vertical non monotone** (spline sur points de contrôle tirés) —
     une masse peut se resserrer puis regrossir, donc porter un vrai surplomb ;
  2. les **nervures verrouillées sur l'azimut** (conservées : c'est le seul
     trait de l'ancien générateur qui marchait — elles font les contreforts) ;
  3. les **strates en RELIEF et non en tranches** : une rainure douce à la base
     de chaque lit, dont l'amplitude S'ANNULE sur des secteurs entiers et dont
     la hauteur DÉRIVE avec l'azimut. Aucune rainure ne peut plus faire le tour ;
  4. des **niches et des surplombs** — gaussiennes signées en (θ, t) — qui
     rendent la section non convexe ;
  5. des **contreforts de pied** et une **jupe enterrée** : la masse continue
     sous z = 0 en s'évasant. Le contact avec l'herbe cesse d'exister comme
     ligne ;
  6. une **face d'ascension** (secteur où les rainures se creusent et la pente
     s'adoucit), une **cassure de crête** (encoche en V) et une **plateforme
     panoramique** au sommet.
- **Ce que le générateur REFUSERA d'écrire**, et c'est le point qui rend le
  changement vérifiable plutôt que déclaratif — deux contrôles neufs qui
  échoueraient tous les deux sur l'ANCIENNE géométrie :
  * `CEINTURE_MAX` : aucune rainure ne couvre plus de 55 % des azimuts dans une
    tranche de 30 cm. L'ancien générateur y rendait 100 % à chaque banc ;
  * `SURPLOMBS_MIN` : au moins trois secteurs d'azimut où le rayon AUGMENTE
    avec la hauteur, mesuré sur le profil LISSE (strates exclues, sinon le test
    serait tautologique — chaque rainure produit mécaniquement un dr/dt > 0).
- **Changement attendu dans les pixels** : plus aucun replat qui fait le tour ;
  une silhouette à surplombs et non à degrés ; un pied qui s'évase et disparaît
  dans l'herbe sans ligne de contact ; des lignes de strate qui MONTENT et
  DESCENDENT autour de la masse et s'interrompent.
- **Caméras** : `overlook_summit_joueur` et `overlook_summit_identite` (les deux
  gelées, seules à juger), `overlook_gros_crete` (le contact et les rainures),
  silhouettes 0/90 (l'aplat noir dit si c'est une formation ou un tas).

## Résultat de l'itération 7 — la topologie répond, la matière ne suit pas

Captures `voie_a3/iter7`, commit `422808c`, RC=0. Ce que je VOIS à taille
réelle, sans indulgence :

- **« Pile de dalles » : DISPARU.** Plus un seul replat qui fait le tour, plus
  de galettes empilées. La crête est une masse continue à crête brisée, avec
  une encoche en V au sommet, des nervures verticales et une grande diaclase
  qui la fend sur toute sa hauteur. Sur `overlook_summit_joueur`, c'est une
  paroi qui entre dans le cadre, plus une pièce montée. **Visible.**
- **Le contact avec l'herbe a cessé d'être une ligne.** Le pied s'évase et
  plonge ; sur `overlook_gros_crete` le bas gauche de la masse se perd dans
  l'herbe sans arête. **Visible.**
- **La brèche et la bimodalité tiennent** : les deux masses se lisent séparées
  sur `_identite`, du ciel entre elles. **Visible.**
- **Le défaut qui reste, et il est net : ça lit CIRE FONDUE, pas roche.** La
  surface est trop lisse, la silhouette trop coulante ; les rainures de strate
  existent dans la géométrie mais ne se voient pas. **Faible.**
- **Les deux éclats de kit au pied lisent comme une autre famille** : des
  galets ronds et lisses contre une masse anguleuse. **Ambigu.**

## Itération 8 — la cause du « cire fondue » est l'OMBRAGE, pas le relief

- **Défaut** : la masse rend une surface molle et continue, alors que TOUT le
  monde autour d'elle — falaises V2.2, rochers de kit, éboulis — est
  franchement FACETTÉ. Elle n'appartient pas à la même matière.
- **Cause** : `bm.normal_update()` produit des normales de sommet LISSÉES, et
  l'exporteur les écrit telles quelles. Une surface de 32 × 45 échantillons
  ombrée en douceur est, par construction, un dégradé continu — c'est-à-dire
  de la cire. Ce n'est pas un manque de relief : le relief est là, mesuré
  (ceinture 0,28, sept secteurs de surplomb), mais l'ombrage le dissout.
- **Levier, en trois gestes** :
  1. **ombrage à FACETTES** (`polygon.use_smooth = False`), ce qui aligne la
     matière sur celle du monde V2.2 ;
  2. **résolution BAISSÉE** (crête 32 × 40 → 26 × 26) : une facette doit se
     LIRE. À 32 × 40 les facettes font 20 cm et l'ombrage à facettes rendrait
     du bruit ; à 26 × 26 elles font ~75 × 30 cm, l'échelle des falaises du
     fond ;
  3. **rainures de strate presque doublées** (0,075–0,098 → 0,135–0,165) : à
     l'amplitude précédente elles ne survivaient pas à l'échelle du cadre.
- **Changement attendu dans les pixels** : des arêtes franches entre plans, un
  contraste net entre face au soleil et face à l'ombre, des redents de strate
  qui se lisent à dix mètres. La masse doit cesser d'avoir l'air molle.
- **Et la courbure d'axe descend de 0,085 à 0,050** : c'est elle qui donnait
  l'air « penché comme une bougie ». Un cisaillement de pendage suffit.
- **Caméras** : les deux gelées, plus `overlook_gros_crete`.

## Itération 8 bis — source : la présence, pas la couleur

- **Défaut observé** (verdict, et je le vois moi-même sur
  `iter5/turquoise_spring_joueur.png` à taille réelle) : « trop petite et
  secondaire dans la caméra joueur ». Un filet turquoise dans le tiers bas du
  cadre, cerné de cailloux bleu marine de 2,6 m, écrasé par le talus brun qui
  occupe la moitié de l'image. La couleur, elle, est acquise et mesurée
  (H 189°, S 0,490 contre H 176–185° S 0,368 pour la rivière V2.2).
- **Cause** : le sujet du lieu est « l'œil » ENTIER — eau + mâchoires +
  rebords — et cet œil n'a jamais existé à l'écran. Les pièces de kit ne
  pouvaient pas le fabriquer : `Rock_Medium_*` est une famille de GALETS, et
  un galet agrandi reste un galet. Même loi de FORME qu'au belvédère.
- **Levier** : `SM_SpringMaw.glb` — quatre masses à surface continue,
  nervurées, à jupe enterrée, qui remplacent SEPT pièces de kit. Mâchoires de
  2,6 m à ≈ 4,0 m et ÉCARTÉES (à masses grossies et positions inchangées leurs
  enveloppes se touchaient, et la fente d'où l'eau sort se refermait) ;
  couronne qui ferme le haut de la fente ; rebord à trois lobes FONDUS dans un
  seul objet. Vasque R 3,3 → 3,95, sauf du côté du fruit. Mouillage dans
  `COLOR_0`.
- **Ce que le cadrage NE fait PAS** : rien. Les deux caméras du lieu sont
  recopiées du plan précédent au chiffre près, vérifié par script avant la
  capture. Agrandir un sujet en rapprochant la caméra serait l'A/B malhonnête
  que la règle transversale nº 4 interdit.
- **Changement attendu dans les pixels** : la roche cesse d'être une poignée
  de galets et devient un amphithéâtre ; la fente se lit comme un creux fermé ;
  les rebords assombris au ras de l'eau ; la chaîne arrivée → vasque →
  déversoir lisible d'un coup d'œil.
- **Budget D7** : 12 − 7 + 4 = **9 modules sur 12**. Le lieu était PLEIN ; les
  trois slots libérés le sont par fusion, pas par retrait de contenu.
- **Caméras** : `turquoise_spring_joueur` et `_identite` (les deux gelées),
  `spring_gros_eau`, `spring_gros_fente`, `spring_promesse_p1`, plus
  `spring_gue_riviere` qui porte la RÉFÉRENCE d'eau V2.2 dans la même image.

## Résultat de l'itération 8, mesuré (`voie_a3/iter8`, commit `58e8df1`, RC=0)

### Belvédère — l'ombrage à facettes fait ce qu'on lui demandait

Ce que je VOIS sur `overlook_gros_crete` à taille réelle : des plans francs,
des arêtes, une crête fendue, un pied qui se perd dans l'herbe. La masse
appartient enfin à la même matière que les falaises V2.2 et les rochers de kit,
qui sont facettés eux aussi. La lecture « cire fondue » a disparu. **Visible.**

Ce qui reste **faible** : les rainures de strate ne se lisent pas comme des
lignes horizontales, elles se fondent dans le facettage. Le relief est mesuré
(159 rainures, ceinture 0,31) mais il ne se voit pas en tant que STRATE.

| Vue gelée | Zone | iter6 | **iter8** |
|---|---|---|---|
| `_identite` | crête | H 220-226° S 0,19 V 0,498 | **H 230° S 0,127 V 0,550** |
| `_identite` | falaise V2.2 (plafond) | 0,632 | **0,643** (inchangée) |
| `_identite` | éperon | — | H 224° S 0,172 V 0,631 |
| `_joueur` | crête proche | — | H 223° S 0,213 V 0,446 |
| `_joueur` | caillou de kit du lieu | — | H 222° S 0,187 V 0,563 |

Deux réserves honnêtes sur ces chiffres : (1) mes deux fenêtres « face au
soleil » et « face à l'ombre » rendent 0,550 et 0,567 — l'écart est dans le
mauvais sens, donc je ne sais pas laquelle est laquelle et je ne le prétends
pas ; (2) l'éperon à 0,631 est à un centième de la falaise du fond (0,643) :
il ne s'en détache pas en valeur. À arbitrer.

### Source — la présence est gagnée, la MATIÈRE ne suit pas

**Visible** : la roche n'est plus une poignée de cailloux. Quatre masses
forment un amphithéâtre qui occupe le milieu du cadre, l'eau en sort par
dessous, et la chaîne vasque → déversoir se lit d'un coup d'œil.

**Et quatre défauts, dont trois que J'AI introduits :**

1. **La roche rend INDIGO.** Mesuré `H 221° S 0,441 V 0,358`, contre
   S 0,13–0,21 pour les crocs du belvédère. À S 0,44 ce n'est plus de la
   pierre froide, c'est du bleu. Pire : l'eau mesure S 0,554 dans la même
   image — la roche est à quatre cinquièmes de la saturation de l'eau, donc
   l'eau cesse d'être « la seule note froide saturée du ravin ».
   **Cause, et elle est instructive** : l'albédo est le même rapport
   1 : 1,20 : 2,03 qui rend S 0,13–0,21 au belvédère. Là-bas le soleil DIRECT
   et chaud mange le biais bleu ; ici, dans un ravin à l'ombre d'une paroi de
   54°, il n'y a que l'ambiante froide et le biais survit entier. **Le même
   albédo ne donne pas la même couleur selon l'éclairage du lieu** — c'est le
   piège d'albédo de `scripts/CLAUDE.md` dans une variante qu'il ne décrit pas.
2. **Les masses lisent COUSSINS.** Le profil de dôme `(1 − t^q)^e` est trop
   rond aux épaules ; même facettées, elles restent molles.
3. **Deux coins NOIRS au bord de l'eau** (`spring_gros_eau`). Régression que
   j'ai fabriquée en élargissant la vasque : le lit épouse le terrain
   (sol + 3 cm) tandis que la nappe est un PLAN à hauteur du centre. En
   grandissant, la vasque atteint du terrain plus haut que ce plan, et le lit
   ressort AU-DESSUS de l'eau. C'est l'anneau noir de la v3, revenu par une
   porte que je viens d'ouvrir moi-même.
4. **L'ancre du fruit est DANS la pierre.** Vérifié au calcul avant même de
   regarder l'image : le lobe est du rebord a son centre à 0,36 m de l'ancre
   pour une demi-emprise de 1,01 m. La récompense est gelée, donc c'est le
   lobe qui bouge.

**Et un objet non identifié** : une pierre OLIVE, plate et anguleuse, au bord
nord de la vasque, d'une famille étrangère au reste. Je ne sais pas ce que
c'est, et je refuse de l'attribuer sur sa seule couleur — c'est exactement la
faute qui a produit le revert de l'itération 6 (`TONE_DRY` accusé à tort). Elle
peut être : (a) le fond de jupe d'un lobe du rebord, peint en `TEINTE_PIED`
verdâtre et exposé parce que l'objet est assis sur le terrain du CENTRE de la
vasque alors que ses lobes sont ailleurs ; (b) une pièce du semis V2.2 gelé,
qu'il serait interdit de toucher.
**Le test qui tranche est posé dans l'itération 9** : `TEINTE_PIED` de ce
générateur passe du vert au gris froid. Si la pierre olive devient ardoise,
elle est à moi ; si elle ne bouge pas d'un centième, elle ne l'est pas, et le
semis gelé reste le seul suspect.

## Itération 9 — source : la matière, et trois régressions à réparer

- **Levier 1, couleur** : rapport d'albédo 1 : 1,20 : **2,03** → 1 : 1,07 :
  **1,41**, et magnitude ×1,25. Cible RENDUE : S autour de 0,20 (famille des
  crocs) et V autour de 0,42, pour que la roche cesse de concurrencer l'eau.
  Les deux nombres sont dérivés de la mesure d'iter8, pas choisis — mais le
  gain n'est pas linéaire, donc c'est une approximation à REMESURER.
- **Levier 2, forme** : épaules carrées (`dome_q` 2,4–3,4 → 3,2–4,6,
  `dome_e` 0,26–0,38 → 0,16–0,26), nervures relevées d'un tiers, fentes plus
  profondes et plus étroites.
- **Levier 3, coins noirs** : le lit est PLAFONNÉ sous le plan d'eau. Une
  surface de fond qui passe au-dessus de son eau n'est pas un fond.
- **Levier 4, ancre** : le lobe est part de (−2,6 ; 2,3) à (−1,5 ; 3,9) et
  rétrécit ; l'ancre retrouve 0,68 m de marge. Et la jupe du rebord double
  (0,60 → 1,10 m) avec un enfoncement de 0,25 → 0,55 : un objet à trois lobes
  est assis sur UN point de terrain, donc il lui faut de quoi absorber le
  relief sous les deux autres.
- **Caméras** : les mêmes, inchangées.

## Résultat de l'itération 9, mesuré (`voie_a3/iter9`, commit `a33d154`, RC=0)

### Le test de la pierre olive a TRANCHÉ, et il dit « pas à moi »

`TEINTE_PIED` est passée du verdâtre au gris froid. La fenêtre mesurée sur la
pierre olive rend **RGB(65,9 ; 73,4 ; 67,2)** dans `iter9` — identique au
centième à `iter8`, et la pierre est visiblement inchangée à taille réelle.
Ce n'est donc pas un fond de jupe à moi : elle appartient au décor gelé, que
la règle transversale nº 1 interdit de toucher. Le test coûtait une ligne et
il a évité de refaire exactement la faute de l'itération 6.

### Ce qui est réparé, mesuré

| Défaut d'iter8 | iter9 |
|---|---|
| roche indigo, S 0,441 | **S 0,334** — le levier marche, il n'est pas fini |
| coins NOIRS au bord de l'eau | disparus ; il reste un liseré sombre de rive |
| ancre du fruit dans la pierre | **le fruit est sur la berge**, visible |
| masses en coussins | épaules plus franches, encore rondes de près |

| Vue gelée | Zone | iter8 | **iter9** |
|---|---|---|---|
| `turquoise_spring_joueur` | roche haute | H 221° S 0,441 V 0,358 | **H 218° S 0,334 V 0,376** |
| `turquoise_spring_joueur` | roche gauche | — | H 218° S 0,331 V 0,417 |
| `turquoise_spring_joueur` | eau | H 190° S 0,554 V 0,462 | **inchangée** (H 190° S 0,554) |
| `turquoise_spring_joueur` | herbe, talus | — | **identiques au centième** (rien de gelé n'a bougé) |

### Ce que je VOIS à taille réelle, sans indulgence

- Source, présence : **visible**. Quatre masses forment un amphithéâtre qui
  tient le milieu du cadre ; l'eau en sort par-dessous et s'en va vers le
  premier plan. Ce n'est plus une flaque cernée de cailloux.
- Source, chaîne arrivée → vasque → déversoir : **visible**.
- Source, fruit sur la berge : **visible**.
- Source, matière : **faible**. À S 0,334 la roche reste plus bleue que la
  pierre du monde (crocs : 0,13–0,21) et elle est encore à 60 % de la
  saturation de l'eau, qui devrait rester seule saturée. **Non résolu, et
  chiffré** : il faudrait descendre le rapport bleu/rouge de 1,41 vers ~1,20.
- Source, formes : **ambigu**. Les épaules sont plus carrées qu'en iter8, mais
  en gros plan les masses lisent encore « blocs arrondis » plutôt que
  « mâchoires ».
- Belvédère, formation : **visible**. La silhouette à 90° montre une crête
  haute à couronne rompue, un éperon détaché et un vide franc entre les deux —
  le « vide qui fait partie de la silhouette » du contrat.
- Belvédère, strates : **faible**. Le relief existe et se mesure ; il ne se
  lit pas comme des lignes horizontales, il se fond dans le facettage.
- Belvédère, éperon contre falaise du fond : **ambigu**. 0,631 contre 0,643 —
  il ne s'en détache pas en valeur.

## D3 REJOUÉ — INDICATIF, et il rougit sur MES DEUX LIEUX

`tools/lot1_repetition.py` rejoué sur un jeu de silhouettes composé des DEUX
sujets fraîchement capturés (commit `a910349`) et des quatre autres lieux du
lot tels qu'ils étaient dans la candidate. Verdict versé :
`voie_a3/controles/verdict_d3_indicatif_a910349.json`.

**Ce résultat est INDICATIF et je ne le présente pas autrement.** Les quatre
autres lieux sont reconstruits en ce moment même par d'autres agents : les
paires qui les impliquent ne veulent rien dire aujourd'hui. En revanche, les
paires de mes lieux contre le CORPUS ACCEPTÉ sont lisibles tout de suite,
puisque ce corpus, lui, est gelé — et le seuil en dérive.

    VERDICT indicatif : FAIL (seuil 30 m : S = 0,4931)

    belvédère × source                 IoU 0,507
    belvédère × hameau (corpus)        IoU 0,510
    source    × hameau (corpus)        IoU 0,575
    source    × pont de pierre (corpus) IoU 0,583
    source    × grotte du couchant     IoU 0,517

Avant cette passe, au commit `abd8ea0`, la SEULE paire signalée du lot était
`flower_field × ember_raider_camps` — mes deux lieux passaient. **Ils ne
passent plus, et c'est le prix direct de ce qui m'a été demandé.** Le détecteur
NORMALISE l'échelle (cadrage sur l'AABB) : il ne juge donc pas la taille mais
la FORME. En donnant à la source la présence qui lui manquait, je lui ai donné
la forme la plus commune du corpus — une masse basse, large et bosselée — et
c'est exactement ce que cinq lieux acceptés rendent déjà.

Ce n'est pas un défaut d'exécution que je pourrais corriger seul : les deux
exigences tirent en sens contraire, et l'arbitrage ne m'appartient pas.

## Emprises AVANT / APRÈS — sonde réelle `probe_place_metrics.gd`

| Lieu | avant (publié en itération 4) | **après** | mesh | colls | appuis |
|---|---|---|---:|---:|---:|
| `valley.poi.overlook_summit.01` | 22,1 × 8,0 × 18,6 m | **22,8 × 8,4 × 19,4 m** | 12 | 4 | 8 |
| `valley.poi.turquoise_spring.01` | 14,4 × 3,2 × 14,2 m | **17,2 × 5,9 × 16,8 m** | 11 | 3 | 10 |

Le belvédère bouge à peine. **La source, elle, change de catégorie** : sa
hauteur passe de 3,2 à 5,9 m et son emprise de 14,4 à 17,2 m, donc son rapport
hauteur ÷ emprise de 0,224 à 0,347. C'est exactement le levier que la revue a
demandé — de la présence — et c'est aussi la cause directe de ce qui suit.

Budget D7 compté sur le code : belvédère **10/12** modules (inchangé),
source **9/12** (elle était pleine à 12/12 ; sept pièces de kit ont fusionné
dans quatre masses).

## SIMULATION DE COMPOSITION SUR LES MASQUES — onze variantes, aucun engin lancé

Méthode donnée par le lead : peindre l'entaille à la main dans la silhouette
capturée, rejouer `lot1_repetition.py`, et ne RECAPTURER qu'une prédiction qui
passe. Outils versés : `voie_a3/controles/simule.py`, `voir_masque.py`.

**Un piège a failli rendre toute la simulation muette**, et il mérite d'être
écrit : le manifeste porte le CHEMIN de l'image, et `charger()` le résout
depuis le cwd. Peindre une COPIE ne change donc rien — le détecteur rouvre
l'original et rend exactement le même verdict, ce qui ressemble parfaitement à
« le geste ne sert à rien ». Mes deux premières simulations sont tombées dedans.
La parade est dans `simule.py` : on réécrit le manifeste pour ne garder que le
NOM du fichier, et la solution de repli `manifeste.parent / nom` s'applique.

### Ce que la simulation dit, et c'est contre-intuitif

Point de départ (`iter9`, réel) : source × pont 0,583 · source × hameau 0,575 ·
source × grotte 0,517 · belvédère × hameau 0,510 · belvédère × source 0,507.

| Geste simulé | Effet mesuré |
|---|---|
| A/B/C — source « une mâchoire HAUTE d'un côté, rebord bas » | source × hameau 0,575 → 0,503 et pont/grotte tombent, **mais belvédère × source 0,507 → 0,611** |
| D/E/F — source en SELLE (deux mâchoires, entaille centrale, tout bas) | hameau 0,575 → **0,494**, pont 0,583 → 0,532, grotte sort, belvédère × source → 0,502 |
| G — belvédère, col élargi aux deux angles | belvédère × hameau 0,510 → **0,504** |
| H = F + G, les deux gestes ensemble | **tout entre 0,494 et 0,532 ; rien ne passe** |
| I — source coupée EN DEUX jusqu'au sol | pont 0,532 → **0,553**, ça empire |
| J — source resserrée (tiers est retiré) | hameau → **0,610 à 160 m**, ça empire beaucoup |
| K — entaille plus large et décentrée | pont → 0,566, ça empire |

**Le premier geste prescrit fait collisionner mes deux lieux entre eux.** Donner
à la source « un pic dominant et un rebord bas », c'est lui donner la signature
du belvédère : le détecteur normalise l'échelle, donc « une masse haute plus un
satellite bas » est UNE seule forme, quelle que soit la taille. Ce n'est pas une
objection au raisonnement du lead — c'est une conséquence que seule la mesure
pouvait rendre visible, et elle a coûté deux minutes au lieu d'un cycle moteur.

**Et la selle bute sur le pont de pierre**, pour une raison qu'on voit dans son
masque à 90° : le pont EST une selle — un tablier plat sur deux jambes avec du
vide entre elles. En regardant les masques plutôt que les nombres, on constate
que les quatre profils qu'une masse basse et large peut prendre sont DÉJÀ pris :
bloc plein = hameau, pic + queue = belvédère, selle = pont, deux blocs séparés =
pont encore. La source a 5,9 m pour 17 m d'emprise ; à cette proportion, son
contour a très peu de degrés de liberté.

**Aucune prédiction ne passe, donc je ne recapture pas** — c'est la consigne, et
elle est juste : recapturer une géométrie qu'on sait encore signalée coûterait
un cycle moteur pour un rouge déjà connu.
