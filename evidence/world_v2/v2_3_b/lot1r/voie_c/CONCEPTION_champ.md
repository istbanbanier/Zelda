# CONCEPTION — Le Champ des mille fleurs (`valley.poi.flower_field.01`)

Voie C, lot 1.R. Brief exigé par `ADDENDUM_DA.md` avant tout gel de
géométrie. Intention imposée : **la respiration et la joie** — un des
premiers moments de beauté accessibles, une masse colorée VIVANTE
traversée par le vent, organisée autour d'un passage naturel ; le village
reste un horizon.

## Émotion recherchée

Émerveillement simple, soulagement. Le joueur sort de la crête de départ,
descend — et le sol se met à fleurir devant lui. Aucune menace, aucun
puzzle : un endroit où l'on ralentit de soi-même. La joie vient de la
couleur en masse et du mouvement du vent ; la liberté vient de la fourche.

## Micro-histoire (sans texte)

Un très vieux chemin de dalles à demi avalées descend de la crête et se
sépare en deux au milieu d'une prairie que personne ne fauche plus. Au
point où l'on doit choisir sa route, quelqu'un, il y a longtemps, a
dressé une pierre — les fleurs l'ont depuis à moitié reprise. On ne
trouve pas un monument : on trouve un carrefour que le monde a fleuri.
L'herbe d'endurance pousse à l'abri de la pierre — le voyageur qui
s'arrête au choix de route repart plus fort.

## Lecture aux trois distances

- **80–120 m** (depuis la crête et la route de la rivière) : une plage de
  couleur dans le vert — deux taches (blanc, jaune) et un point pâle
  dressé au milieu ; PROMESSE : « là-bas, il y a des fleurs et quelque
  chose debout ».
- **30–50 m** : les nappes se séparent (blanche au cœur, jaune au sud,
  bleue derrière), la ligne claire des dalles apparaît, la ou les pierres
  pâles marquent la fourche ; le vent couche des vagues dans la couleur.
- **5–15 m** : les fleurs à hauteur de genou encadrent le regard, la voie
  dallée s'ouvre entre deux ourlets d'herbes paille, les pétales
  s'écartent du chemin ; la pierre penchée porte l'ombre de la récompense.

## Élément héroïque unique

C'est LE point faible de l'état actuel (iter2) et la cause mesurée de
l'échec D3-image (IoU 0,537 vs cimetière du tertre à 30 m : deux bandes
basses sans accent). Les deux compositions ci-dessous divergent
exactement là-dessus.

## Palette (valeurs RENDUES, jugées sur capture — gain ≈ 1,8 non linéaire)

- pétales blancs : rendu quasi-blanc lumineux (désaturation du rose de
  l'atlas ×1,5) — vérifié capture iter2 ;
- pétales jaunes : natifs atlas — rendu jaune franc, vérifié ;
- pétales bleus : rendu bleuet assourdi (0,55/0,65/1,25 après
  désaturation), plus sombre que le cyan électrique — vérifié ;
- dalles : pierre pâle sous la bande haute (TONE 0,88/0,86/0,79, leçon
  ISS-037) — vérifié ;
- pierre(s) dressée(s) : gris clair froid (0,92/0,93/0,92 sur l'atlas
  Rocks) — vérifié iter2, ne rend plus noir ;
- ourlet : paille dorée (natif éclairci 1,12/1,06/0,88) — vérifié ;
- feuillages : olive painterly commun (0,60/0,63/0,50).

## Mouvements et effets locaux

- vent des nappes : `SH_FlowerFieldSway` (grammaire foliage_wind V2.2 —
  phase par position monde, amplitude croissante avec la hauteur,
  variation par instance) — EN PLACE ;
- le semis V2.2 gelé continue d'onduler autour : continuité gratuite ;
- pas de pollen/particules au premier jet : la masse en mouvement EST
  l'effet ; à réévaluer sur la vidéo joueur si l'image reste statique.

## Références (décrites, aucune image copiée)

1. Prairies de « The Witness » : champs monochromes en NAPPES franches
   séparées par des respirations, lisibles de loin comme des aplats.
2. Chemins de campagne hollandais peints (Van Gogh, « Champ de blé avec
   cyprès ») : la voie claire qui serpente DANS la masse colorée, bordée
   d'herbes hautes plus sèches.
3. Menhirs de Bretagne en lande fleurie : une pierre pâle penchée, seule
   verticale dans un tapis bas — l'homme ancien dans la nature vivante.
4. Champs de cosmos japonais (Showa Kinen) : densité réelle par vagues de
   couleur, allées où les fleurs s'écartent, visiteurs à hauteur de fleur.
5. La colline d'ouverture de la North Star du projet (docs/references) :
   premier plan chaud fleuri, profondeur froide, village comme horizon.

## Assets

**Utilisables (en place)** : Flower_3_Group / Flower_4_Group (pétales
rose/jaune de l'atlas — le shader local désature et recolore pour le
blanc et le bleu §1.4), Grass_Wispy_Tall (paille), RockPath_* (dalles),
Rock_Medium_1 (erratique), Bush_Common_Flowers, shader SH_FlowerFieldSway
local, MultiMesh + graine fixe.

**Bloquants constatés** : aucun modèle de fleur HAUTE (tige 0,45-0,65 m
type « fleur haute » de la bible §7.1) — sans elle, le profil du champ
reste une bande uniforme ; aucun modèle de pierre dressée élancée (les
Rock_Medium sont des galets trapus — une VRAIE stèle exigerait un GLB
Blender dédié). Les deux compositions ci-dessous n'en dépendent pas ;
une stèle taillée dédiée est l'amélioration suivante la plus rentable si
le lead veut pousser l'élément héroïque au-delà.

## COMPOSITION A — « La fourche fleurie » (état iter2, committé `78767e8`)

Le champ pur : trois nappes, fourche de neuf dalles, UNE pierre modeste
(×0,62, ≈1,1 m) décalée hors de l'axe, deux buissons. Le lieu est
entièrement horizontal ; la couleur est le seul événement.

- POUR : respiration maximale, aucun objet ne dispute la lecture aux
  fleurs ; c'est la réponse la plus littérale au rejet Codex.
- CONTRE (mesuré) : pas d'élément héroïque — la promesse à 80-120 m est
  faible (une tache de couleur sans point d'ancrage) ; D3-image FAIL
  (IoU 0,537 vs tertre à 30 m, verdict committé) : une bande basse
  continue ressemble à une autre bande basse continue ;
  la barre « wahou » de l'addendum (« reconnaissable sans son nom ? une
  image qui pourrait représenter le jeu ? ») repose sur la seule couleur.

## COMPOSITION B — « La Porte des fleurs » (RECOMMANDÉE)

Tout de A, plus : la fourche passe entre DEUX pierres dressées pâles et
penchées, inégales (≈2,3 m et ≈1,2 m visibles, penchées l'une vers
l'autre sans se toucher), les fleurs lappant leurs pieds. L'herbe
d'endurance pousse au pied de la grande, côté abrité. Les pierres sont
claires (gris froid éclairci mesuré iter2), fines par rapport à la tour
ou au tertre, et DÉCALÉES de l'axe caméra joueur — on passe entre elles,
on ne bute pas dessus.

- POUR : l'élément héroïque existe (la porte de pierre dans les fleurs) ;
  la promesse à 80-120 m devient « quelque chose est debout dans la
  couleur » ; la séquence de l'addendum se joue : promesse (pierres
  pâles) → approche (la voie dallée) → révélation (le passage entre les
  pierres, le champ entier s'ouvre) → récompense (l'herbe au pied de la
  grande pierre) → sortie (deux branches, deux horizons) ; la silhouette
  gagne deux pics inégaux sur bande basse — signature qu'aucun des
  quatorze autres sujets ne porte (le tertre = dômes, la tour = masse
  haute pleine) ; micro-histoire renforcée (une porte dressée par les
  anciens au choix de route).
- CONTRE : réintroduit de la pierre dans un lieu dont l'identité première
  était « le seul lieu sans masse verticale » ; risque contrôlé de
  re-voler la lecture (mitigé : pierres fines, pâles, hors axe, à ~12 m
  de l'œil joueur — à VÉRIFIER sur capture, c'est le juge) ; +1 module
  (13 > plafond 12 si on garde tout — il faut céder un buisson ou une
  dalle : je cède le second buisson).

**Recommandation : B.** A est la réponse au rejet d'hier ; B est la
réponse au rejet d'hier ET à l'intention d'aujourd'hui, et elle répare
D3-image par la composition plutôt que par un seuil. A reste liviable en
un cherry-pick (`78767e8` + preuves committées) si le lead tranche
autrement.

## PARCOURS VIDÉO JOUEUR (20-40 s, vrais contrôles)

Séquence promesse→révélation→sortie, coordonnées MONDE (x, y sol, z) et
regards :

1. départ (-38,0, ~7,4, 138,0), regard vers (-52, 6, 128) : la couleur
   apparaît en contrebas, pierres pâles au-dessus des fleurs (promesse) ;
2. marche vers (-48,6, ~6,4, 131,4) — l'entrée de la voie dallée, regard
   (-55, 6, 125) : les nappes se séparent, la voie s'ouvre (approche) ;
3. suivre les dalles jusqu'à (-55,4, ~6,2, 125,4) — le cœur de la
   fourche, regard balayant de (-62, 6, 122) à (-59, 6, 117) : passage
   entre les pierres, le champ entier autour (révélation) ;
4. pas de côté vers (-59,6, ~6,1, 126,0) — le pied de la grande pierre,
   regard (-60, 5,8, 123) : la récompense (exploration/récompense) ;
5. repartir vers (-61,4, ~5,9, 120,8) — la branche nord-ouest, regard
   (-70, 5, 114) : l'horizon de la rivière (sortie).

Cadence marche naturelle, une pause de 2 s aux étapes 3 et 4. Durée
attendue ≈ 30 s. Fichier machine : `evidence/world_v2/v2_3_b/lot1r/
voie_c/parcours_flower_field.json` (waypoints + regards, lu par
`tools/godot/lot1r_video.gd`).

---

## POST-SCRIPTUM — ARBITRAGE RENDU

Le lead a RETENU la composition B « la Porte des fleurs », avec cinq
conditions (pierres jugées sur capture ; 12/12 en cédant le second
buisson ; distinction du seuil du sanctuaire et des stèles du cimetière —
pierres PÂLES penchées l'une vers l'autre dans la couleur ouverte,
re-mesure D3 à l'intégration ; « placette » du premier plan à re-juger ;
ancre canonique intacte). État de chaque condition : RAPPORT_VOIE.md §7.
