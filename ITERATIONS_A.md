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
