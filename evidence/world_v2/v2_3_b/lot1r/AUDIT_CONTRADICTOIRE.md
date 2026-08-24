# AUDIT VISUEL CONTRADICTOIRE — voies A et B (lecture seule)

Auditeur : voie C. Méthode : chaque capture regardée en taille réelle,
une par une, dans le worktree de la voie ; coordonnées approximatives en
pixels (x, y) origine en haut à gauche ; sévérités : **bloquant** (pour
la revue humaine) / **à corriger** / **détail**. Confronté aussi aux
intentions d'`ADDENDUM_DA.md` (émotion, séquence promesse → révélation →
sortie), comme demandé. Aucun verdict artistique global : ce qui se voit
est listé, la revue humaine tranche.

**État audité** (les voies travaillent encore — re-passer l'audit sur
leurs états finaux) :
- voie A : commit `63af918` (« belvédère et source v1 »), captures
  `evidence/world_v2/v2_3_b/lot1r/voie_a/v1/` (manifeste propre, commit
  concordant) ;
- voie B : commit `f5ad2b3` (« teintes recalées it.3 »), captures
  `…/voie_b/iter/tour3/` (manifeste propre, commit concordant). Le
  sanctuaire forestier et le cimetière du tertre n'avaient AUCUNE
  itération au moment de l'audit — non audités, non reprochés.

---

## VOIE A — Belvédère (`overlook_summit`)

1. **`v1/overlook_gros_crete.png` (370-1030, 200-660) — bloquant.**
   La masse centrale de la « crête fondue » est un pan UNIFORME pêche :
   une seule face plane sans strate, sans variation de valeur, sans
   arête secondaire, qui remplit la moitié du cadre. À cette échelle
   (×9-12 par KitScale), les pièces cliff_* à couleurs plates ne portent
   aucun détail — la lecture est « graybox pêche », exactement la
   famille de défauts qui a fait rejeter le lot.
2. **`v1/overlook_summit_identite.png` (370-520, 255-330) et
   (680-745, 290-335) ; `v1/overlook_summit_joueur.png`
   (700-1230, 130-330) — bloquant.** Les chapeaux des blocs de crête
   rendent SARCELLE/menthe : c'est la surface « grass » du kit falaise
   (albédo 0,17/0,85/0,72, mesuré sur le GLB), laissée telle quelle.
   Contre le pêche chaud, elle lit comme une peinture émissive — pas
   comme de la végétation sommitale. (Le même piège a mordu la voie C
   sur `rock_largeA` ; correctif possible : override LOCAL par surface,
   voir `_habiller_pierre()` du champ.)
3. **`v1/overlook_summit_joueur.png` — à corriger (intention).** La
   séquence de l'addendum (« attire depuis le bas, conduit vers une
   crête, révèle SOUDAINEMENT le panorama ») ne se lit pas encore : la
   vue joueur bute sur la masse pêche, aucun chemin d'ascension visible,
   pas de promesse de vue. Les roches SONT le sujet — l'addendum demande
   l'inverse (« elles mettent en scène la vue »).
4. **`v1/overlook_summit_identite.png` (600-660, 355-375) — détail.**
   Un petit bloc-marche pêche devant la masse centrale semble posé sur
   l'herbe sans contact franc — vérifier l'assise après basculement
   (piège `_coucher`/remesure du dépôt).

## VOIE A — Source aux reflets (`turquoise_spring`)

5. **`v1/spring_gros_fente.png` (170-630, 20-355) et (620-1090,
   20-320) ; confirmé dans `v1/turquoise_spring_identite.png`
   (415-680, 220-300) et `v1/turquoise_spring_joueur.png` (475-790,
   215-320) — bloquant.** Les deux « mâchoires » beiges FLOTTENT :
   du ciel passe sous leurs bases plates, aucun contact terrain visible
   sous AUCUN des trois angles. Pièces flottantes au sens strict du
   filet D2 — si le filet ne rougit pas, c'est que les appuis déclarés
   ne couvrent pas ces pièces (à vérifier côté voie A).
6. **`v1/spring_gros_eau.png` (700-1130, 240-560) — à corriger.** Trois
   vasques périphériques au sommet TEAL PLAT : ce n'est PAS le shader
   d'eau V2.2 (le bassin central, lui, l'utilise — profondeur + écume
   visibles). Deux eaux différentes dans la même image ; le teal plat
   ressemble à la surface « grass » du kit ou à un albédo posé sans
   rendu de contrôle. La continuité « de construction » promise par la
   réutilisation du shader n'y est pas.
7. **`v1/spring_gros_eau.png` (200-235, 360-395) — à corriger.** La
   récompense (fruit rouge) FLOTTE en l'air à ~0,3-0,5 m du sol, à
   l'écart du bassin, sans écrin. L'ancre est canonique mais son point
   d'accroche est en l'air.
8. **`v1/spring_gros_eau.png` (280-520, 300-560) — à corriger.** Le
   bord du bassin est cerné d'un anneau NOIR quasi pur (lit sombre
   sous-exposé) : à l'écran il lit comme un trou de texture, pas comme
   de la profondeur. Bible §1.6 : pas de noir bouché.
9. **`v1/turquoise_spring_identite.png` (ensemble) — à corriger
   (intention).** Le lieu entier baigne dans l'ombre de la cuvette :
   la « première apparition du turquoise [qui] attire immédiatement »
   (addendum) n'a pas lieu — le turquoise du bassin est plus terne que
   la rivière gelée en contrebas (`spring_gue_riviere.png`). La
   révélation est éteinte par l'exposition.

## VOIE B — Tour de guet (`watchtower_ruin`)

10. **`iter/tour3/watchtower_ruin_joueur.png` (905-1085, 510-580) —
    à corriger.** Les pétales violets géants au sol (≈0,5 m chacun,
    posés à plat) n'appartiennent à aucun langage du lieu : ni gravat,
    ni plante du kit à cette échelle. Ils lisent comme un modèle de
    fleur posé à ×5-8 l'échelle — présents depuis tour1, toujours là
    en it.3.
11. **`iter/tour3/watchtower_ruin_joueur.png` (1180-1280, 480-600) —
    détail.** Une dalle pavée coupée par le bord droit du cadre, sans
    liaison lisible avec la tour — vérifier ce qu'elle est hors champ ;
    à cette place elle lit comme un reste de la plateforme AVANT.
12. **`iter/tour3/watchtower_ruin_joueur.png` (790-840, 365-385) —
    détail.** Petit disque TEAL plat posé dans l'herbe derrière la tour
    (même famille que le teal du kit) — ni eau shadée, ni pierre.
13. **`iter/tour3/watchtower_ruin_identite.png` (510-650, 165-460) —
    à corriger (intention/hors-axe).** De ce trois-quarts, la tour lit
    comme une DEMI-COQUILLE mince : le pan de brèche expose un
    intérieur sombre presque plat et la paroi semble sans épaisseur au
    sommet. La « sentinelle » de l'addendum promet un point de vue et
    un chemin d'ascension — aucun niveau intérieur ni départ d'escalier
    n'est lisible d'ici (le commit « escalier scellé » parle d'un
    escalier : il n'apparaît sur aucune des deux vues).
14. **`iter/tour3/watchtower_ruin_joueur.png` (620-700, 385-450) —
    détail.** Le coffre (récompense flèches) est bien dans la brèche,
    mais il lit « posé au milieu » au premier contact — l'addendum
    demande que la récompense paraisse appartenir à l'histoire (ex. :
    demi-enterré dans l'éboulis déjà présent à ses pieds).
15. **Réel progrès à acter (pas un défaut)** : la maçonnerie GLB dédiée
    et la diagonale d'effondrement (identite) sont la seule vraie
    matière nouvelle du lot côté A/B au moment de l'audit ; l'arase
    rompue lit en silhouette. Les points 10-13 sont des finitions de
    bord, pas une reprise de fond.

## Transverse

16. **Deux teals se promènent dans le lot** (points 2, 6, 12) : la
    surface « grass » des kits Kenney rend menthe/sarcelle sous la
    lumière du monde et se retrouve en chapeau de crête, en vasque et
    en disque au sol. Toute pièce cliff_*/rock_* réemployée à une autre
    fin que « falaise vue de loin » doit passer par un habillage par
    surface (précédent : `_habiller_pierre()` du champ, local, sans
    mutation de ressource partagée).
17. ~~Aucun parcours vidéo dans les CONCEPTION des voies A/B~~ —
    PÉRIMÉ (correction lead) : leurs parcours ont été déposés après le
    premier passage. Les JSON waypoints restent à recevoir pour
    enregistrer leurs vidéos avec `tools/lot1r_video.sh`.

---

# SECOND PASSAGE — états A `6337db0` (captures v4 ; code v5 `1f2eaa3`
# committé SANS captures au moment du passage) et B `68cbdf6` (tour4)

## Voie A v4 — ce qui est réglé, ce qui reste

- **Réglé (points 1-2, 5)** : les masses pêche à faces planes et les
  chapeaux sarcelle ont disparu — la crête du belvédère est refaite en
  blocs moussus du langage Rocks ; les mâchoires flottantes de la source
  sont remplacées par un amas de blocs posés autour de la tête d'eau.
  L'anneau noir du bassin (point 8) a disparu.
- **A-v4-1. `v4/spring_gros_eau.png` (205-240, 360-395) ; visible aussi
  `v4/turquoise_spring_joueur.png` (520-535, 388-400) — à corriger.**
  Le fruit de récompense FLOTTE toujours en l'air à l'écart du bassin —
  inchangé depuis v1 (point 7). Troisième capture où il apparaît.
- **A-v4-2. `v4/spring_gros_eau.png` (880-1130, 315-410) et (820-1060,
  465-600) — à corriger (probablement traité par v5).** Les vasques
  périphériques rendent VERT-NOIR plat, presque silhouettes ; ni le
  shader d'eau V2.2 ni une pierre lisible. Le commit v5 (« vasque
  profonde, bleu poussé, margelles ») annonce exactement ce chantier —
  à re-juger sur les captures v5 quand elles existeront.
- **A-v4-3. `v4/turquoise_spring_joueur.png` (ensemble) — à corriger
  (intention, persiste)** : le lieu reste dans la pénombre de la
  cuvette ; l'eau du bassin rend gris pâle, pas turquoise — la
  « première apparition du turquoise » (addendum) n'a pas encore lieu
  dans la vue joueur. Même réserve qu'au point 9 ; v5 à re-juger.
- **A-v4-4. `v4/overlook_summit_joueur.png` (735-795, 450-490) —
  détail.** Petite pièce pâle (socle ? récompense ?) posée seule dans
  l'herbe, dont l'assise semble flotter légèrement — vérifier le
  contact au sol.
- **A-v4-5. `v4/overlook_summit_joueur.png` (745-1060, 300-390) —
  détail.** L'appui du grand bloc moussu sur son socle laisse une fente
  d'ombre continue — de cet angle il lit « posé en équilibre » ;
  acceptable en l'état, à vérifier hors axe.

## Voie B tour4 — ce qui est réglé, ce qui reste

- **Réglé** : maçonnerie GLB, diagonale d'effondrement, intérieur
  remonté (it.3) ; et tour4 livre la séquence de l'addendum : le
  `watchtower_gp_vigie_pov.png` — vallée, rivière, hameau, pylône vus
  du palier — EST « le paysage est la récompense », et le palier est
  prouvé praticable par sonde physique (commit).
- **B-t4-1. `tour4/watchtower_ruin_joueur.png` (905-1085, 510-580) ;
  vu d'en haut dans `watchtower_gp_vigie_pov.png` (260-345, 490-545) —
  à corriger (persiste depuis tour1).** Les pétales violets géants
  (~0,5 m pièce, posés à plat) sont toujours là. Confirmés d'en haut :
  ce sont bien des pétales de fleur à ×5-8 l'échelle du monde.
- **B-t4-2. `tour4/watchtower_ruin_joueur.png` (1180-1280, 480-600) —
  détail (persiste).** La dalle pavée coupée par le bord droit, sans
  liaison lisible avec la tour.
- **B-t4-3. `tour4/watchtower_ruin_joueur.png` (790-840, 365-385) —
  détail (persiste).** Le disque TEAL plat dans l'herbe derrière la
  tour.
- **B-t4-4. `tour4/watchtower_gp_lointain.png` (675-745, 480-565) —
  RÉSOLU (enquête lead).** Les trois rectangles orange sont les modules
  REJETÉS de la SOURCE à l'état de base `89a3009` (`SM_Dungeon_CaveArch`
  + 2× `SM_Dungeon_CaveWallHalf`, rendus terracotta — vérifié par le
  lead dans le `turquoise_spring_place.gd` du worktree B, qui ne porte
  pas le correctif de la voie A). Ils disparaissent à l'intégration des
  deux voies. Ni défaut voie B, ni défaut du gel, aucune action.
  CONSÉQUENCE RETENUE pour le troisième passage : cette caméra est une
  LIGNE DE VUE INTER-LIEUX — à l'intégration, reprendre `gp_lointain`
  comme preuve croisée (la tour ET la source corrigées doivent lire
  ensemble dans le même cadre).

## Complément — voie A v5 (captures apparues pendant le passage)

- **A-v5-1. `v5/manifest.json` — bloquant (preuve, pas image).** Le
  manifeste v5 porte `repo_dirty: true` : capturé d'un arbre SALE.
  Règle evidence.md : une capture d'arbre sale ne prouve rien — le lot
  v5 est à recapturer d'un arbre committé (le même incident est arrivé
  à la voie C sur iter2 ; détection par `lot1r_manifeste.py`, recapture).
- **A-v5-2. `v5/turquoise_spring_joueur.png` — à corriger (persiste).**
  Au pixel près comme v4 pour ce qui compte : l'eau du bassin rend
  toujours gris pâle (pas turquoise), le fruit de récompense flotte
  toujours (520-535, 388-400), la cuvette reste éteinte. Les chantiers
  annoncés par le commit v5 (« bleu poussé, vasque profonde ») ne se
  voient pas dans la vue joueur — soit ils ne portent que sur les gros
  plans, soit l'arbre sale a produit un état mélangé.

Fin du second passage. Un TROISIÈME passage reste dû sur les états
FINAUX des deux voies (v5+ recapturé propre / tour final), y compris
hors-axe, et y compris la preuve CROISÉE `gp_lointain` tour+source dans
le même cadre après intégration (décision lead sur B-t4-4).

---

# TROISIÈME PASSAGE — états livrés

**État audité, et une réserve d'entrée qui compte :**

- voie A — captures `voie_a/final/`, manifeste propre, commit
  `149e79c` (v6). Mais le HEAD de la voie est `6860118` (v7), qui déplace
  la crête, l'avant-poste, la dalle de pied, la bouche de la source et le
  bloc tombé. **Aucune capture n'existe pour l'état livré**, et l'arbre
  est actuellement SALE (silhouettes et `verdict_repetition.json`
  modifiés non committés). Ce qui suit juge donc v6, pas v7 — c'est dit,
  ce n'est pas reproché.
- voie B — captures `voie_b/apres/`, manifeste propre, commit `e18d075`,
  qui EST le HEAD. Les trois lieux sont couverts, gros plans compris.

Sévérités inchangées : **bloquant** (pour la revue humaine) / **à
corriger** / **détail**.

## Ce qui est RÉGLÉ depuis le second passage — à acter

- **B-t4-1, B-t4-2, B-t4-3 sont résolus.** Les pétales violets géants, la
  dalle coupée par le bord droit et le disque teal ont disparu de
  `apres/watchtower_ruin_joueur.png`. Trois signalements portés depuis
  tour1, trois corrections.
- La maçonnerie GLB de la tour porte une vraie matière : deux appareils,
  des joints, de la variation. Elle ne fait plus partie du problème.
- Voie A : les masses pêche à faces planes et les chapeaux sarcelle ne
  sont plus visibles ; le fruit de récompense ne flotte plus (mesuré
  `final/turquoise_spring_joueur.png` : il touche le sol au bord du
  bassin). Points 1, 2, 5, 7, 8 et A-v4-1 réglés.

## LE DÉFAUT TRANSVERSE DU LOT — l'aplat de valeur

C'est le constat central de ce passage, et il est le même chez les deux
voies. Je le mesure de la même façon que je viens de le mesurer sur MON
propre asset, où il m'a coûté une itération complète : **profil de
luminance en travers d'une face, à une ligne donnée**.

| Pièce | Image, ligne | Profil mesuré | Étendue |
|---|---|---|---|
| Stèle du cimetière | `barrow_cemetery_joueur.png`, y = 470, x 268→320 | 109 ×16 puis 104 ×2 | **0** sur 48 px |
| Linteau du dolmen | `barrow_gp_gueule.png`, y = 440, x 650→785 | 82 × 45 échantillons consécutifs | **0** sur 135 px |
| Dalle claire au pied de la tour | `watchtower_gp_breche.png`, y = 520 | 141 constant, puis 78 constant | **0** par plage |
| Bassin de la source (voie A) | `turquoise_spring_joueur.png`, y = 390 | 168 / 170 / 165 / 152 | ~18, sans gradient de profondeur |
| Montants du sanctuaire | `shrine_gp_nef.png`, y = 430, deux montants | 94 constant sur chacun | **0** |

Pour comparaison, le tertre voisin, lui, VARIE (76→99 sur la même
mesure) : ce n'est donc pas une limite du rendu, c'est une propriété des
pièces concernées.

**Sévérité : bloquant.** Une face pâle à valeur unique est exactement ce
qui a fait rejeter le lot (« boîtes beige, plaques terracotta, nappe
blanche »), et l'œil la lit comme du carton découpé quelle que soit la
silhouette autour.

Ce que la mesure dit de la CAUSE, et qui peut faire gagner du temps aux
deux voies : ce n'est pas la facettisation. Mon GLB de stèles portait 465
directions de normale distinctes et rendait quand même **une seule
valeur (175, étendue p10-p90 = 1 niveau sur 58 px)**. Sur des faces
quasi verticales, sous ce ciel, l'irradiance ambiante domine et
l'orientation ne rapporte presque rien. Les roches de kit qui se lisent
en pierre le doivent à la variation de leur ATLAS. Sans texture, la seule
variation gratuite est `COLOR_0` : après l'avoir posée, la même face rend
31 à 32 niveaux d'étendue. Deux pièges silencieux sur ce chemin, tous deux
sans erreur ni avertissement : l'exporter glTF 4.0 n'écrit `COLOR_0` que
si le matériau CONSOMME l'attribut, et la couche doit en plus être
l'attribut de couleur ACTIF et de RENDU. Détail dans
`source_assets/blender/environment/make_flower_field_steles.py`.

## VOIE A — Belvédère (`overlook_summit`, état v6)

- **A-f-1. `final/overlook_summit_joueur.png` (ensemble) — bloquant
  (intention, persiste depuis le point 3 du premier passage).** La vue
  joueur montre : 45 % de pelouse vide au premier plan, des blocs gris à
  droite, et une paroi pêche qui ferme le fond. Aucun panorama, aucun
  chemin d'ascension, aucune promesse de vue. L'addendum demande
  « attire depuis le bas, conduit vers une crête, révèle SOUDAINEMENT le
  panorama » et « les roches ne sont pas le sujet : elles mettent en
  scène la vue ». À cette caméra, les roches SONT le sujet et il n'y a pas
  de vue. C'est le troisième passage où ce point est porté.
- **A-f-2. `final/overlook_summit_identite.png` (350-1000, 0-360) — à
  corriger (constat, cause partagée).** Le fond du lieu est une falaise
  pêche à très grandes faces planes, sans strate ni variation. Elle
  appartient au monde GELÉ — ce n'est pas un défaut de la voie A — mais
  elle occupe la moitié supérieure de la vue d'identité du lieu et tire
  toute la composition vers le graybox. À signaler au lead : c'est le
  lieu du lot le plus pénalisé par un élément qu'il n'a pas le droit de
  toucher.
- **A-f-3. `final/overlook_gros_poste.png` (700-830, 480-560) et
  (655-780, 625-700) — à corriger.** Deux coins tan apparaissent au pied
  du gros bloc : faces planes, arêtes droites, aucune matière, et une
  famille de teinte étrangère au gris moussu des autres masses. Même
  lecture que les dalles claires de la voie B.
- **A-f-4. `final/overlook_summit_identite.png` (713-742, 398-416) et
  `final/overlook_breche_montee.png` (840-880, 498-516) — détail.**
  Petite pièce pâle isolée posée sur l'herbe, sans contact franc lisible
  ni rôle apparent, présente sur deux vues. Déjà signalée en A-v4-4.
- **A-f-9. `final/overlook_breche_montee.png` (ensemble) — à corriger,
  et directement lié à A-f-8.** La vue qui porte le mot « brèche » et le
  mot « montée » ne montre ni l'une ni l'autre : cinq blocs alignés sur
  un mamelon herbeux, aucun vide entre eux, aucune marche, aucune
  amorce d'ascension. Le commit v7 s'intitule « la brèche ouverte pour de
  bon » — c'est donc probablement réglé dans l'état livré, mais l'état
  livré n'a pas de capture. C'est exactement le coût de A-f-8.

## VOIE A — Source aux reflets (`turquoise_spring`, état v6)

- **A-f-5. `final/turquoise_spring_joueur.png` (555-760, 372-405) —
  bloquant (intention, persiste depuis le point 9 du premier passage).**
  Le bassin rend **(168, 174, 168)** : un gris pâle neutre, sans
  turquoise, sans gradient de profondeur, sans écume de rive. Dans la
  vue joueur, la « première apparition du turquoise [qui] attire
  immédiatement » n'a pas lieu. Troisième passage sur ce point.
- **A-f-6. `final/spring_promesse_p1.png` (570-700, 348-378) et
  (930-1180, 395-450) — constat, PAS un défaut de la voie A.** Le ruban
  BLANC apparaît sur DEUX nappes d'eau dans le même cadre : celle du lieu
  et une seconde, hors du lieu. Et la même rivière gelée rend un bleu-
  sarcelle franc depuis `final/spring_gue_riviere.png`. Le blanc est donc
  un comportement de MIROIR SPÉCULAIRE à angle rasant, partagé avec l'eau
  gelée du monde, et non la « nappe blanche » de matériau rejetée. La
  vérification demandée par le lead est faite, et elle confirme son
  hypothèse. **La conséquence subsiste néanmoins** : à P1 comme dans la
  vue joueur, l'eau du lieu se lit blanche, et P1 est censé être la
  promesse qui attire.
- **A-f-7. `final/turquoise_spring_joueur.png` et `spring_promesse_p1.png`
  (ensemble) — à corriger (persiste).** Le lieu reste dans la pénombre de
  la cuvette : l'herbe y rend (57, 81, 72), la moitié supérieure du cadre
  est un talus brun uniforme. La révélation reste éteinte par
  l'exposition, comme au point 9 et en A-v4-3.
- **A-f-8. `final/` (manifeste) — bloquant de preuve.** Les captures
  livrées datent de `149e79c` (v6) alors que le HEAD est `6860118` (v7),
  dont le message annonce des déplacements de masses sur les deux lieux.
  Un état livré sans capture ne peut pas être jugé, et l'arbre est en
  plus SALE. C'est la troisième occurrence de cette famille dans le lot
  (le manifeste v5 sale ; ma propre capture iter2 sale). Recapturer d'un
  arbre committé avant la revue.

## VOIE B — Tour de guet (`watchtower_ruin`, état `e18d075`)

- **B-f-1. `apres/watchtower_ruin_identite.png` (515-660, 155-410) et
  `apres/watchtower_gp_breche.png` (400-800, 0-500) — à corriger
  (persiste depuis le point 13 du premier passage), avec une nuance qui
  compte.** De trois-quarts, la tour ne montre aucune ÉPAISSEUR : pas de
  retour de mur, pas d'arase en tranche, pas de plancher intérieur. Le
  pan sombre lit comme un SECOND APPAREIL collé au premier, pas comme un
  intérieur ouvert ; le gros plan de brèche montre deux textures de mur
  qui se touchent sur une arête verticale, sans chaîne d'angle.
  **La nuance** : `apres/watchtower_gp_vigie_pov.png` (440-760, 390-720)
  prouve que l'épaisseur EXISTE — on y voit l'arase en tranche, les deux
  parements et le vide intérieur. Le défaut n'est donc pas la géométrie,
  c'est que les deux caméras que la revue regarde (identité et brèche) ne
  la montrent pas. Un gros plan qui cadre la tranche d'arase depuis le
  sol coûterait une capture et lèverait le point.
- **B-f-15. `apres/watchtower_gp_vigie_pov.png` — acquis à porter au
  crédit, pas un défaut.** Vallée, rivière, hameau et pylône vus du
  palier : « le paysage est la récompense » de l'addendum est là, et c'est
  la seule vue du lot où l'intention d'un lieu se lit sans commentaire.
  (Deux réserves dans le même cadre : la grande dalle tan plate en
  (0-250, 530-700), famille B-f-4 ; et le coffre bleu-gris en
  (295-400, 675-720), famille B-f-2.)
- **B-f-2. `apres/watchtower_ruin_joueur.png` (628-703, 385-458) et
  `apres/watchtower_gp_breche.png` (645-720, 410-480) — à corriger.** Le
  coffre de récompense rend une petite cabane à pignon bleu-gris avec un
  disque brun. À côté d'un appareil de maçonnerie dont les assises font
  ~0,25 m, il paraît haut d'environ 0,8 m et sa famille de teinte
  (bleu-gris saturé) n'appartient à aucune matière du lieu. Il ne lit ni
  comme un coffre, ni comme un objet de ce monde.
- **B-f-3. `apres/watchtower_gp_breche.png` (500-590, 515-585),
  (630-705, 625-685) et `watchtower_ruin_joueur.png` (760-960, 615-700) —
  à corriger.** Les blocs tombés au pied sont des polygones plats posés
  sur l'herbe : arêtes parfaitement droites, aucune épaisseur visible
  sous cet angle, aucun enfoncement dans le sol. Un éboulis se lit à ses
  volumes et à son contact ; ceux-ci lisent comme des découpes.
- **B-f-4. `apres/watchtower_gp_breche.png` (858-1042, 478-570) — à
  corriger.** Grande dalle tan au sol, faces planes, arêtes droites,
  valeur unique mesurée (141 constant). Même famille que A-f-3.
- **B-f-5. `apres/watchtower_ruin_joueur.png` (790-820, 363-390) et
  `gp_breche.png` (853-900, 383-415) — détail.** Petite masse noire posée
  dans l'herbe, sans matière ni rôle lisible, présente sur les deux vues.

## VOIE B — Sanctuaire forestier (`forest_shrine`)

- **B-f-6. `apres/forest_shrine_joueur.png` (595-830, 315-450) —
  bloquant (intention).** Dans la vue joueur, un tronc occupe le centre
  du cadre et COUPE le sanctuaire en deux. Ce qu'on voit du lieu se
  résume à cinq plaques grises verticales, sans sculpture, sans mousse,
  sans seuil et sans centre lisible. L'addendum demande « une
  construction absorbée par arbres et mousse » et « PAS des murs déposés
  entre les arbres » : à cette caméra, c'est exactement ce qu'on lit.
- **B-f-7. `apres/shrine_gp_nef.png` (624-660, 300-342) — à corriger.**
  La récompense FLOTTE. La sphère jaune est à environ 150 px au-dessus de
  la plateforme, et l'échantillonnage vertical sous elle donne de l'herbe
  puis de l'ombre — aucun support. Elle rend en plus (255, 255, 113),
  saturée au maximum, ce qui en fait le point le plus lumineux d'un lieu
  dont l'intention est « calme, mystère, respect ». Le visuel d'ancre est
  PARTAGÉ (voir le point 17), mais son ALTITUDE, elle, appartient au lieu.
- **B-f-13. `apres/shrine_gp_nef.png` (452-530, 430) et (777-845, 430) —
  bloquant (aplat).** Les montants du sanctuaire rendent **94 constant**
  sur toute leur face, les deux mesurés à la même ligne. Même famille que
  B-f-8 et B-f-10 ; voir la section transverse pour la cause et le
  remède.
- **B-f-14. `apres/shrine_gp_nef.png` (600-900, 0-720) — détail
  (composition).** Deux troncs traversent le gros plan censé montrer la
  nef et la coupent en deux. Le lieu est un sanctuaire EN forêt, donc des
  troncs devant sont légitimes — mais la caméra de preuve devrait
  montrer la nef, pas les troncs.

## VOIE B — Cimetière du tertre (`barrow_cemetery`)

- **B-f-8. `apres/barrow_cemetery_joueur.png` (250-800, 340-540) —
  bloquant.** Les stèles sont des rectangles pâles à arêtes droites et à
  **valeur unique mesurée** (109 constant sur 48 px). Plusieurs sont des
  rectangles parfaits, sans cassure, sans inclinaison de matière, sans
  altération. C'est la famille de défaut qui a fait rejeter le lot.
- **B-f-9. `apres/barrow_cemetery_joueur.png` (645-765, 395-480) et
  `barrow_gp_gueule.png` (585-740, 520-625) — bloquant (intention).** Le
  coffre est l'objet le plus clair ET le plus saturé du cadre (bleu-gris
  + orange), posé au milieu du champ de stèles, puis dans la gueule même
  du dolmen. L'addendum écrit : « La hache paraît appartenir à l'histoire
  du lieu, pas à un coffre posé au milieu. » Le rendu montre littéralement
  un coffre posé au milieu.
- **B-f-10. `apres/barrow_gp_gueule.png` (540-800, 415-520) — à
  corriger.** Les deux montants et le linteau du dolmen sont des plaques
  à valeur unique (82 constant sur 135 px). La forme du dolmen, elle,
  fonctionne — c'est la matière qui manque, pas la silhouette.
- **B-f-11. `apres/barrow_cemetery_joueur.png` (320-660, 330-440) et
  (1030-1230, 350-450) — à corriger.** Les tertres sont des polygones
  olive à facettes larges et sommet plat qui lisent comme des tentes de
  papier plié. Ils VARIENT en valeur (76→99), donc ils échappent au
  défaut d'aplat — c'est leur loi de forme qui est en cause, pas leur
  matière : un tertre s'affaisse et déborde, il n'a pas d'arête faîtière.
- **B-f-12. `apres/barrow_gp_gueule.png` (455-560, 515-620) et
  (740-790, 545-580) — détail.** Éclats blancs très clairs autour du
  coffre, plus lumineux que tout le reste du lieu ; ils tirent l'œil vers
  la récompense au lieu du dolmen.

## Transverse — ce qui reste à trancher par le lead

17. **Le visuel d'ancre de récompense** produit une sphère unie
    (verte au champ, jaune au sanctuaire) ou un coffre saturé (tour,
    cimetière). C'est une ressource PARTAGÉE : aucune voie ne peut la
    corriger seule, et elle apparaît dans quatre lieux sur six.
18. **La preuve croisée `gp_lointain` (décision B-t4-4)** n'est pas
    rejouable ici : elle exige la tour ET la source corrigées dans le même
    arbre. À reprendre à l'intégration, comme convenu.
19. **L'aplat de valeur** (section transverse ci-dessus) touche les deux
    voies et six pièces distinctes. Si un seul geste doit être demandé
    avant la revue humaine, c'est celui-là.
