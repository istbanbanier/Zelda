# Hameau R2a — vérification d'intégration par le lead

Candidat reçu de l'agent `hameau`, branche `claude/r2a-hameau`, partie de
`d327e5e`. Fusionné en `--no-ff`.

## Propriété des fichiers — RESPECTÉE, avec une vérification

26 fichiers. Tous dans son périmètre **sauf un en apparence** :
`tools/godot/capture_silhouette.gd`, qui m'est réservé.

Vérifié plutôt que supposé : `git diff 1ed8a79:… claude/r2a-hameau:…` est
**vide**. L'agent a récupéré ma version comme je le lui avais demandé pour
le mode `--place=`, il ne l'a pas modifiée. Le fichier apparaît au diff
contre `d327e5e` uniquement parce que ma correction lui est postérieure.

## Après fusion, dans MON arbre

| contrôle | résultat |
|---|---|
| `godot --headless --import` | RC 0, **0 erreur** |
| `gltf_inspect SM_Village_Quay` | **VALIDE** — 2 264 tris, 3 matériaux |
| `gltf_inspect SM_Village_Wall` | **VALIDE** — 488 tris, 2 matériaux |
| filets `world_v2_places` | **8 / 8** |
| filets `world_v2_hydrology` | **4 / 4** — le quai entre dans l'eau, c'est là que ça pouvait rougir |
| manifestes | `commit f978932`, `repo_dirty: false` |

## Le contrat du lead, point par point

Inspecté à taille réelle :

| exigence | constat |
|---|---|
| auberge principale | oui — 6 × 8, deux niveaux, colombages, balcon |
| maison secondaire | oui — 4 × 6, un niveau, yaw 28° |
| atelier / halle / dépendance | oui — halle-forge **ouverte**, toit en appentis, plus un séchoir sur le quai |
| trois hauteurs distinctes | **quatre** : 11,9 · 7,3 · 3,25 · 1,35 m absolus |
| trois orientations distinctes | **quatre** : 0° · 28° · 96° · 8° |
| place commune | oui — pavée, puits, étal, charrette |
| quai raccordé à l'eau | oui — franc-bord mesuré 0,455 à 0,515 m, pilotis plongeant de 0,91 à 1,10 m |
| circulation claire | oui — rampe du gué, place, venelle est vers le quai, venelle ouest en cul-de-sac |
| au moins un intérieur crédible | oui — murs de 0,41 m à ébrasements réels, quatre îlots fonctionnels, escalier, dortoir à l'étage |
| aucun matériau blanc par défaut | pixels ≥ 0,90 : **0,36 %** contre 3,10 % avant |
| aucune fenêtre posée au sol | aucune — le fichier n'en contenait déjà pas |
| aucune intersection de toiture | SAT exécuté à la construction : `3 toitures, 10 colliders, 24 appuis — aucune faute` |

**Deux volumes sur quatre n'ont aucun mur plein.** C'est ce qui empêche le
hameau de se lire comme le même module répété, et c'est la meilleure
décision du plan.

## Ce que l'agent a rendu exécutable, et qui vaut d'être noté

`_verifier_implantation()` échoue bruyamment à la construction sur les OBB
de toiture, les trois segments de route, les 96 points des huit rayons du
gué, l'écart au sol des appuis, et les pièces flottantes.

Il rapporte avoir dû **corriger ce garde-fou** : sa première règle exigeait
un appui directement sous chaque pièce et accusait aussitôt six pièces
légitimes — planchers d'étage, balcons, étagères murales, tous des
encorbellements. C'est la bonne leçon, et elle est dans le briefing :
**un garde-fou à faux positifs finit désactivé.**

## Ce qui reste faible

L'agent en nomme six ; ce que je vois à taille réelle les confirme.

1. **Bandes de valeur séparées de ~0,08 au lieu de 0,15.** Le site est en
   grande partie à l'ombre de la crête ouest (9,85 m, ombre jusqu'à y ≈ 4,0
   à l'aplomb de l'auberge) : la dynamique disponible est comprimée. Le gain
   réel mesuré ici est de **×0,55**, non de ×1,6 comme en terrain ouvert —
   l'agent s'est fait piéger une fois puis a recalé sur le rapport mesuré.
   Toute la composition se lit dans une bande sombre.
2. **L'enduit ne domine le pavage que de 0,033.** La relation est juste,
   elle est fragile.
3. **Sur la vue de composition, le quai se lit comme posé sur la berge** :
   le platelage occulte l'eau peu profonde et pâle qui passe dessous. La
   géométrie est prouvée par les nombres et par la vue à la ligne d'eau ;
   c'est la lecture à 40 m qui est moins nette.
4. **La silhouette à 0°**, prise dans l'axe de la rue, fusionne auberge et
   maison. Aucune caméra de jeu n'utilise cet angle, mais c'est réel.
5. Trois matériaux non cartographiés retombent sur la teinte par défaut.
6. **Position exacte des arbres non mesurée** — et c'est de ma faute, pas
   de la sienne : `probe_vegetation_near` était cassé pendant qu'il
   travaillait. Corrigé depuis, non rejoué sur ce sujet. Contrôle visuel
   seulement, aucune intersection constatée.

## Ce qui n'est PAS un défaut du sujet

L'agent signalait `SM_WornSword_LOD0` en albédo (1,1,1). **Fausse alerte,
vérifiée** : le GLB porte trois textures, et un facteur blanc multipliant
une texture de couleur de base est la convention glTF normale — celle-là
même que l'agent avait correctement énoncée pour les modules CC0. Aucune
action ; y toucher casserait une arme partagée avec la vallée V1.

## Divergence de teintes — assumée, décidée par le lead

L'agent teinte par `Color` littérales dans son seul fichier, sans toucher
au kit. C'est ma consigne : modifier un ton partagé aurait touché le camp,
la ferme, le bassin et l'arbre, c'est-à-dire de la **propagation**, que le
lead a explicitement interdite. L'écart de valeur entre le hameau et les
autres lieux est la conséquence directe de cette contrainte.

`NON VÉRIFIÉ` sur le plan artistique — aucun verdict auto-déclaré.
