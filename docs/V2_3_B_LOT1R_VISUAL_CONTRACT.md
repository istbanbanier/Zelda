# Contrat visuel du Lot 1.R — écrit AVANT la géométrie

> Committé et poussé avant le premier changement de forme, conformément à la
> directive maître du 2026-08-25. Les métriques du dépôt (D1–D8, R-D3,
> budgets) restent des garde-fous : elles ne décident ni de la beauté, ni de
> l'identité, ni de l'émotion — ce contrat non plus. Il fixe ce que chaque
> lieu doit FAIRE LIRE, et ce qui le fait rejeter sans discussion.
> **Aucun seuil de ce document n'a été choisi après observation d'un
> résultat.** Le verdict artistique appartient à Codex et à Istvan.

Base : `3f792d3` (état intégré de la première corrective des voies).
Les six lieux repartent de cet état — on améliore ou reconstruit par-dessus,
on ne repart pas d'un terrain nu.

Caméras de jugement : pour chaque lieu, les deux caméras GELÉES du plan
`evidence/world_v2/v2_3_b/lot1/poi/shots_lot1.json` (`<lieu>_identite`,
`<lieu>_joueur`) sont les SEULES qui comptent pour l'A/B. Toute autre vue
listée ci-dessous est diagnostique. `cam05_belvedere_crete` (bâtisseur
`world_v2_cameras_builder.gd`) traverse le belvédère et ne doit jamais être
obstruée.

---

## 1. Tour de guet — « la sentinelle brisée »

- **Souvenir** : une ancienne tour de surveillance éventrée, encore dressée
  malgré son effondrement.
- **Lecture 3 s** : une verticale asymétrique qui découpe le ciel — un côté
  porteur, un côté arraché, des niveaux anciens visibles, une ascension
  compréhensible, des gravats venant manifestement d'elle.
- **Silhouette dominante** : verticale rompue en diagonale, couronne
  incomplète ; la plus HAUTE des six silhouettes du lot (H/L ≈ 0,9 mesuré).
- **Approche** : depuis la falaise nord-est (`watchtower_ruin_joueur` vient
  de (-154,5 ; 40,5)) ; l'entrée-brèche se présente au joueur.
- **Premier plan** : gravats concentrés sous les zones effondrées.
- **Sujet central** : le fût de la tour et sa rupture.
- **Arrière-plan** : ciel et falaise gelée — la tour doit se découper dessus.
- **Palette** : pierre du langage V2.2, bois en trace structurelle ; valeurs
  liées à l'usure et à l'exposition, jamais un aplat.
- **Formes** : arases rompues, escalier scellé DANS la structure, deux
  niveaux anciens lisibles.
- **Distinction** : seule verticale bâtie du lot ; le belvédère est naturel,
  le sanctuaire est bas.
- **Trois causes de rejet** : lecture d'empilement de boîtes · plateformes
  semblant ajoutées après coup · gravats sans relation avec l'effondrement.
- **Caméras** : `watchtower_ruin_identite`, `watchtower_ruin_joueur` ;
  diagnostiques : `watchtower_gp_breche`, `watchtower_gp_arase`,
  `watchtower_gp_lointain` (preuve croisée avec la source).

## 2. Belvédère — « les deux crocs froids »

- **Souvenir** : un promontoire naturel de deux masses froides dominant la
  vallée.
- **Lecture 3 s** : une montée conduit à une crête principale, un éperon
  détaché, et un VIDE panoramique entre les deux.
- **Silhouette dominante** : bimodale — deux masses, jamais une ; le vide
  entre elles fait partie de la silhouette.
- **Approche** : montée ouest (`overlook_summit_joueur` depuis
  (159,8 ; 56,8)) ; la brèche se traverse vers l'est.
- **Premier plan** : roche d'assise enracinée, herbe rase.
- **Sujet central** : la paire crête/avant-poste et leur écart.
- **Arrière-plan** : la vallée — le panorama est la récompense ; il doit
  rester dégagé dans l'axe `cam05` → crête de départ.
- **Palette** : minéral FROID — gris bleuté, ardoise, pierre désaturée ;
  aucune plaque terracotta dominante.
- **Formes** : strates et fractures à l'échelle géologique, assise enfoncée
  dans le terrain.
- **Distinction** : le seul sommet ouvert du lot ; la source enveloppe, lui
  expose.
- **Trois causes de rejet** : monolithes/panneaux rectangulaires dressés ·
  roches posées SUR le sol sans racine · panorama obstrué.
- **Caméras** : `overlook_summit_identite`, `overlook_summit_joueur` ;
  diagnostiques : `overlook_breche_est`, `overlook_gros_crete`,
  `overlook_seuil_p4`.

## 3. Source aux reflets — « l'œil turquoise »

- **Souvenir** : une eau turquoise qui naît de la roche, se rassemble dans
  une vasque, s'échappe naturellement.
- **Lecture 3 s** : la chaîne visible arrivée → vasque → niveau → déversoir
  → écoulement.
- **Silhouette dominante** : basse et enveloppante — des mâchoires de roche
  autour d'un creux ; l'accent est la COULEUR de l'eau, pas une masse.
- **Approche** : depuis l'est (`turquoise_spring_joueur` depuis
  (-126,5 ; 40,0)), l'eau au centre du cadre.
- **Premier plan** : rebords mouillés, dalles d'approche.
- **Sujet central** : l'œil d'eau turquoise.
- **Arrière-plan** : la paroi et la tour au-dessus (preuve croisée
  `gp_lointain`).
- **Palette** : roches froides, eau turquoise PERÇUE DANS LE RENDU — calibrée
  contre une référence d'eau V2.2 dans le même moteur, même exposition, avec
  mesure avant/après ; jamais seulement l'albédo.
- **Formes** : vasque irrégulière, un point de reflet contrôlé.
- **Distinction** : le seul lieu d'eau du lot ; le champ est couleur sèche,
  la source est couleur liquide.
- **Trois causes de rejet** : nappe blanche ou eau « éclairée de
  l'intérieur » · plan d'eau flottant ou arrivée sans déversoir · plaques
  terracotta autour de l'eau.
- **Caméras** : `turquoise_spring_identite`, `turquoise_spring_joueur` ;
  diagnostiques : `spring_gros_eau`, `spring_gros_fente`,
  `watchtower_gp_lointain`.

## 4. Sanctuaire forestier — « la pierre que la forêt a reprise »

- **Souvenir** : une petite ruine rituelle cachée, reprise par les arbres et
  la mousse.
- **Lecture 3 s** : un seuil, une enceinte brisée, un cœur rituel central,
  une ouverture cadrée par la forêt ; progression profane → sacré.
- **Silhouette dominante** : basse, interrompue, asymétrique ; le CENTRE
  domine les murs.
- **Approche** : depuis la route au sud (`forest_shrine_joueur` et
  `_joueur_b`) ; rien de lisible depuis la route, tout depuis le seuil.
- **Premier plan** : pierres enfoncées, mousse près du sol.
- **Sujet central** : le cœur rituel (vestige), visible AVANT d'entrer par
  l'ouverture cadrée.
- **Arrière-plan** : les arbres V2.2 gelés servent de cadre latéral — ils
  encadrent, ils ne masquent pas.
- **Palette** : pierre froide/neutre, humidité localisée, plus sombre au
  sol ; pas de murs beige uniformes.
- **Formes** : murs interrompus, pierres reprises par le terrain.
- **Distinction** : le seul lieu CACHÉ du lot — sa révélation est retardée.
- **Trois causes de rejet** : graybox beige / rectangle fermé · autel perdu
  dans le décor · végétation utilisée pour cacher une géométrie insuffisante.
- **Caméras** : `forest_shrine_identite`, `forest_shrine_joueur`,
  `forest_shrine_joueur_b` ; diagnostiques : `shrine_gp_nef`,
  `shrine_gp_coeur`, `shrine_gp_route_p1` (qui doit montrer PEU).

## 5. Cimetière du tertre — « les tombes avalées par la terre »

- **Souvenir** : un paysage funéraire ancien, partiellement affaissé dans la
  colline.
- **Lecture 3 s** : une entrée, un tertre dominant, des sépultures
  secondaires, un rythme irrégulier vers le centre, un terrain qui a déformé
  les tombes.
- **Silhouette dominante** : longitudinale et basse (la plus plate des
  bâties) ; UN tumulus non conique domine, le reste s'incline vers lui.
- **Approche** : depuis le nord-ouest (`barrow_cemetery_joueur` depuis
  (50,0 ; -53,6)) — les signes secondaires se rencontrent AVANT le tertre
  dominant.
- **Premier plan** : stèles inclinées, cassées ou enfouies.
- **Sujet central** : le tumulus principal et la chambre rouverte.
- **Arrière-plan** : la colline — les tertres en émergent, ils ne sont pas
  posés dessus.
- **Palette** : terre/herbe/pierre du terrain environnant ; pierre exposée ≠
  enterrée ≠ humide.
- **Formes** : vocabulaire funéraire propre — aucune arche générique ;
  espaces vides intentionnels.
- **Distinction** : le seul lieu dont le TERRAIN est le co-auteur ; rythme,
  pas symétrie.
- **Trois causes de rejet** : cônes réguliers ou tertres identiques · cercle/
  répétition radiale · sépultures simplement posées sans hiérarchie.
- **Caméras** : `barrow_cemetery_identite`, `barrow_cemetery_joueur` ;
  diagnostiques : `barrow_gp_gueule`, `barrow_gp_chemin`, `barrow_gp_fosse`.

## 6. Champ des mille fleurs — « la clairière qui explose en couleurs »

- **Souvenir** : une ouverture spectaculaire de fleurs, le village au loin
  comme récompense de profondeur.
- **Lecture 3 s** : le premier plan floral est le sujet AVANT le rocher, le
  chemin, le village et les arbres.
- **Silhouette dominante** : pas une masse — des NAPPES : phrases de couleur
  denses, respirations, couloirs.
- **Approche** : depuis le nord-est (`flower_field_joueur` depuis
  (-51,2 ; 132,2)) ; un cheminement invite à traverser.
- **Premier plan** : la nappe florale la plus dense et la plus variée.
- **Sujet central** : le champ lui-même.
- **Arrière-plan** : le village, destination lointaine — jamais le sujet.
- **Palette** : grandes phrases de couleur, variation par nappes, jamais un
  hachis au pixel.
- **Formes** : hauteurs et tailles variées, densité par zones, vides voulus.
- **Distinction** : le seul lieu dont le sujet est un TAPIS VIVANT, pas une
  construction ni une roche.
- **Trois causes de rejet** : fleurs invisibles depuis la vue joueur ·
  rocher ou village devenant le sujet · densité uniforme sans chemin ni
  respiration.
- **Caméras** : `flower_field_identite`, `flower_field_joueur` ;
  diagnostiques : `flower_field_gp_nappe`, `flower_field_gp_chemin`.

---

## Règles transversales (rappel exécutoire)

1. Plantations et matières NOUVELLES uniquement dans la scène du lieu — le
   semis V2.2 global, le terrain, l'hydrologie, la lumière et les six caméras
   du bâtisseur restent intacts au hash.
2. Aucun nouvel asset téléchargé : assets déjà attribués ou génération
   reproductible versionnée (`source_assets/blender/*.py`).
3. Collisions locales corrigées uniquement pour épouser la géométrie
   visible ; aucune paroi invisible.
4. Un A/B reste honnête même défavorable — aucune caméra déplacée, aucun
   FOV/exposition/brouillard modifié, aucun cadrage d'évitement.
5. Chaque itération écrit AVANT modification : défaut → cause supposée →
   levier → changement attendu dans les pixels → caméra qui doit le montrer.
   Deux échecs sur la même hypothèse = on cesse de régler des constantes et
   on vérifie scène/SHA/caméra/matériau/visibilité.
