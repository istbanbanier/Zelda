# R2a-3.5.8 — Checkpoint 4 : les trois couloirs sont verts, entrée en ordre d'intégration §7

Date : 2026-08-18. HEAD au moment du relevé : `478058b` (== origin). Budget
géométrie : 1 itération consommée sur 3.

## Couloir A — collision : PASS (reproduit au checkpoint 3)

GLB final `5ff4ec6ee7a5bb6f…` (1 488 700 o) : zéro pénétration réelle au juge
du tronc (`cave_exact_intersect.py` committé), exécuté de mes mains, RC=0.
`SM_` bit-identique à la baseline (`dd3ea5c6…`). 9/9 positions soudées
modifiées, toutes en bande de queue. Source finale `28535fb3…`, delta 259 l
`750151d5…`.

## Couloir C — provenance et identité visuelle : PASS (double verdict)

- Conformité générateur : état fusionné prescrit (S1 + hunks massif {1,2,5,6}
  + 86b01ece) reconstruit indépendamment par C, **byte-identique** à
  `102cc33d…` (hash complet `102cc33d3836d07fdb0b13951b3fa780187dc5388fafb43aa34bf8e05f0f4bb5`) ;
  `soustraire()` byte-identique à S1 (66 l, `97ee5b3c…`) ;
  `_desamorcer_ngones_colineaires` : 0 occurrence.
- Identité visuelle : `sha256_geom(SM)` de C (`e6a4bdb0…`) identique à sa
  baseline — boucle à trois instruments fermée. `COL_` final `98034206…`
  (outil C) / `e322e4b5…` (outil lead) — valeurs jamais comparables ENTRE
  outils, chacune stable dans le sien.
- Précision consignée : bande de queue réelle ay [5,275 ; 7,142] — mon
  « 5,3–7,0 » était arrondi un cran trop court ; l'invariant tient.

## Couloir B — traversabilité : PASS (tableau final/05, journaux 00…04 jetonnés RC=)

- T1 canonique courbe : 0 échantillon sous contrat, aller ET retour, 2 rayons ;
  corde-témoin 11 fautes (discriminant intact).
- T2 capsule : st1 0,7013/+0,2513 · st3 1,2001/+0,7501 · st5 0,5713/+0,1213 —
  au chiffre près le relevé 3.5.7, par une chaîne indépendante.
- T3 champ paroi invisible : pire excès +0,0503 < seuil 0,061 (43 200 rayons) ;
  fonctionnel : capsule jamais bloquée par COL_ dans du vide SM_ ; niche
  atteinte à 0,569 m (contrat 1,8–2,4) ; Δsol ≤ 0,005.
- T3d jauge de poche : 0,5828 ≥ plancher 0,524 — **au fil du couteau**
  (marge +0,059 ≈ erreur ~0,06), tenu par deux appuis : la valeur de
  conception EST le plancher (0,524 = 1,20 − 0,40×1,69, formule vérifiée mot
  pour mot dans la source d'A), et l'état refusé (0,355) lirait ≈0,41,
  exclu à 4× l'erreur.
- Contrôles négatifs (a)(b)(c)(d) : tous rouges au bon endroit, restauration
  prouvée au bit près.

## Reproduction lead du fil du couteau (instrument indépendant, `repro_poche/`)

Éventail 360° × 1° depuis l'axe publié (3,10 ; −2,88), y = sol+0,50
(sol mesuré 0,2664, cohérent avec le Δsol≈0 de B), Möller–Trumbore, aucune
ligne de B réutilisée :

- direction publiée reproduite : θ=238 → d_SM=4,8321 / d_COL=3,5670 /
  diff=1,2652 (B : 4,8422 / 3,5490 / 1,2932 ; écarts ≤ 3 cm — pas angulaire
  1° et hauteur légèrement différente) ; estimateur → **0,611** (B : 0,583),
  tous deux ≥ 0,524 ;
- le secteur alcôve 225–255 est lisse et culmine exactement à θ=238 : la
  jauge de B visait le max du secteur, aucune direction pire ne se cache ;
- découverte annexe : discontinuité θ=115–119 (jonction salle→couloir), le
  jambage COL s'ouvre ~5° plus tard que le SM (~0,13 m à 1,5 m) — lamelle
  inutilisable par une capsule r=0,45, couverte par le champ-avec-marges et
  le test fonctionnel de B, tous deux verts. Consigné, pas un rouge.
- première exécution fautive consignée : origine du rayon-sol à y=3,0 —
  DANS le massif — le « sol » trouvé était le plafond (2,44). Corrigé en
  partant de l'intérieur de la cavité (y=1,2). Le piège « mesurer le sol »
  frappe aussi le lead ; 5ᵉ occurrence.

## Note d'intégration publiée par B (pas un blocage)

« Jauge ≥ rodage » n'est PAS vérifié : 0,583 contre 1,065 — le correctif
86b01ece rétrécit la poche de collision par conception (prix arbitré du zéro
pénétration) ; le joueur perd 0,48 m de profondeur de poche en collision par
rapport à l'état pré-correctif. Le champ reste sous la marge figée et
l'atteinte de la niche est inchangée. Chiffre porté au dossier d'intégration.

## Décision

Les trois couloirs sont verts sur le binaire exporté `5ff4ec6e…`. J'entre
dans l'ordre d'intégration §7 : outils indispensables (le contrôle spécialisé
unique du budget = `cave_paroi_invisible.py` ; `cave_sha256_geom.py` intégré
comme instrument de provenance, pas comme gate), commit outils, reconstruction
du candidat en worktree propre, correction locale, contrôles ciblés, sources,
export contrôlé, gltf_inspect, vérification de hash, commit GLB séparé,
arbre propre, captures. Le déclassement TELEMETRIE du portail d'épaisseur de
domaine (tâche #91, décidé au contrat gelé cca1778, politique 28fa140)
s'applique au générateur à l'intégration.

NON VÉRIFIÉ à ce stade : comportement en moteur (rejoué au §9) ; captures ;
validate_fast (UN seul, à la fin, §9).
