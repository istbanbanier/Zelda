# PROMPT 3 — BIBLE VISUELLE ET SPÉCIFICATION EXHAUSTIVE DES ASSETS DE « ÉCLATS D’ORAGE » SOUS GODOT 4.7.1

## Instruction d’utilisation

Donner ce document à Claude Code **dans le dépôt existant** de *Éclats d’Orage*, avec le Prompt Maître, le Prompt 2 et l’image de référence fournie par l’utilisateur.

Ce document est une **spécification artistique et technique de continuation**. Il ne remplace pas les systèmes déjà validés, ne demande pas de recommencer le projet et ne constitue pas une autorisation de casser la boucle jouable. Il précise ce que chaque asset doit montrer, comment les familles visuelles doivent former un monde cohérent et comment les intégrer dans Godot 4.7.1.

Le Prompt Maître reste la base. Le Prompt 2 reste la base des améliorations systémiques. Le présent Prompt 3 devient la source de vérité la plus récente pour la direction artistique, les assets, les matériaux, les shaders, les VFX, l’UI, la composition et leur validation visuelle.

Si le projet est encore à Gate B ou Gate C, ne pas interrompre un jalon critique pour produire toute la vallée finale. Enregistrer immédiatement cette bible dans `docs/VISUAL_ASSET_BIBLE.md`, auditer ce qui existe, préparer le pipeline, puis exécuter le benchmark `HeroShotLab` à la Phase C.5 prévue. La production artistique complète vient seulement après validation de la micro-verticale.

---

## 0. MISSION ABSOLUE

Transformer la vision fournie en une image **réellement rendue dans Godot**, cohérente en mouvement et jouable à 60 FPS : une aventure 3D painterly haut de gamme, lumineuse et dense, dans laquelle le joueur voit dès les premières secondes :

- un héros original de dos, immédiatement reconnaissable ;
- une pente d’herbes et de fleurs animées au premier plan ;
- une vallée lisible, vaste mais parcourable ;
- un camp qui promet une rencontre ;
- un pylône techno-magique qui promet une interaction ;
- une rivière turquoise qui guide le regard et le déplacement ;
- une citadelle monumentale qui donne le but ;
- un orage local cyan qui donne la menace ;
- une lumière dorée accueillante opposée à des ombres et lointains froids.

Le résultat attendu n’est ni un rendu photoréaliste, ni un dessin animé plat, ni un décor low-poly grossier, ni une collection de packs incompatibles. Il doit ressembler à une **illustration peinte devenue espace 3D**, avec de grandes masses colorées, des silhouettes sculptées, des détails concentrés aux focales, un PBR contrôlé et une excellente stabilité temporelle.

### 0.1 Règle de vérité artistique

Ne jamais appeler `final`, `premium`, `AAA`, `wahou` ou `conforme` :

- un proxy ou une primitive non assumée ;
- un humanoïde gris ou un personnage générique non travaillé ;
- une texture photographique brute ;
- une animation mal retargetée, raide ou avec foot sliding ;
- une capture générée qui ne vient pas du moteur ;
- un asset manquant, rose, sans licence ou non redistribuable ;
- un shader spectaculaire qui ne tient pas le budget ;
- une image fixe correcte dont le mouvement révèle shimmer, LOD pop, ghosting ou clipping ;
- un décor qui ne fonctionne que sous un angle et se désagrège en jeu.

Statuts autorisés : `PASS`, `PARTIAL`, `FAIL`, `BLOCKED`, `UNVERIFIED`. Une capture du build, une vidéo, une scène d’aperçu, un profil et un contrôle du manifeste constituent les preuves. Un fichier présent sur disque ne constitue pas une preuve visuelle.

### 0.2 Originalité et propriété intellectuelle

L’image fournie sert uniquement de référence pour : composition, échelle relative, palette, hiérarchie des plans, densité, lumière, profondeur atmosphérique et émotion d’aventure.

Interdictions :

- copier Link, Zelda, un Bokoblin, un Lynel, une Sheikah Tower, un sanctuaire, une créature, une arme, un costume, une interface, un glyphe, une architecture ou une animation Nintendo ;
- extraire, redessiner ou « rapprocher suffisamment » un asset commercial ;
- importer un asset dont la licence ne permet pas sa redistribution dans le dépôt/build ;
- utiliser un logo ou symbole immédiatement attribuable à une autre licence ;
- faire croire qu’une image de concept est une capture Godot.

Le héros, les pillards, le chasseur quadrupède, le Gardien de l’Orage, le pylône, la Citadelle de l’Œil-Tempête et le langage de Résonance doivent avoir des silhouettes et des motifs originaux. Tout asset externe ou généré est enregistré dans `ATTRIBUTIONS.md` et `docs/assets/ASSET_MANIFEST.csv`.

### 0.3 Priorités en cas de conflit

1. Lisibilité du gameplay, télégraphes et collisions.
2. Silhouette, composition et hiérarchie des valeurs.
3. Cohérence de la direction artistique.
4. Animation et stabilité en mouvement.
5. Performance et qualité des fallbacks.
6. Détail de surface.

Une texture 4K ne sauve pas une mauvaise silhouette. Davantage de particules ne sauve pas un télégraphe ambigu. Davantage d’herbe ne sauve pas une composition sans chemin du regard.

---

## 1. DÉCOMPOSITION PRÉCISE DE L’IMAGE NORTH STAR

### 1.1 Format et placement écran

Reproduire les **relations** suivantes dans `VistaCamera_Hero01`, sans faire de copie pixel à pixel. Toutes les positions sont exprimées en pourcentage d’une image 16:9, origine en haut à gauche.

Conserver localement l’image fournie comme référence de production sous `docs/references/NORTH_STAR_VALLEY_V01.png` si sa présence dans le dépôt est autorisée. Elle ne doit pas être importée dans le build comme texture de jeu. Créer à côté `NORTH_STAR_OVERLAY.svg` ou `.png` avec tiers, emprises, horizon et trajectoire du regard afin que les comparaisons restent reproductibles.

| Élément | Centre / emprise cible | Fonction visuelle |
|---|---|---|
| Héros | centre X 39–43 % ; pieds Y 89–92 % ; tête Y 44–48 % ; hauteur visible 38–45 % | point d’ancrage, échelle humaine, promesse de contrôle |
| Premier plan végétal | Y 72–100 %, avec une crête montante à gauche | profondeur, tactilité, mouvement immédiat |
| Camp | centre X 61–66 %, Y 58–64 % | objectif proche et menace lisible |
| Pylône | centre X 75–79 % ; base Y 55–59 % ; sommet Y 14–20 % | objectif moyen, verticale secondaire |
| Citadelle | centre X 48–53 % ; base Y 39–47 % ; spire Y 7–13 % | objectif ultime, masse monumentale |
| Nuage local | X 41–64 %, Y 0–17 % | menace circonscrite, couronne sombre |
| Éclairs | 2–4 trajets minces entre nuage, spire et flancs de la citadelle | liaison causale ciel→monument |
| Soleil/zone lumineuse | hors champ haut-gauche ; plus forte luminance X 8–34 %, Y 0–28 % | accueil, chaleur, contrepoint de l’orage |
| Falaise gauche | X 0–23 %, du premier plan au plan lointain | encadrement et profondeur |
| Falaise droite | X 78–100 %, plus discontinue | encadrement sans étouffer le pylône |
| Ruine/barricade de bord droit | X 89–100 %, Y 45–84 %, partiellement coupée par le cadre | masse sombre proche équilibrant le héros et renforçant la profondeur |
| Rivière/lac | ruban en S du bas-gauche/milieu vers le centre | ligne directrice et route sûre |
| Horizon montagneux | Y 24–43 %, contraste faible | échelle au-delà de la zone jouable |

Le héros ne doit pas masquer le camp, le pylône ou la rivière. Le pylône ne doit pas fusionner avec la citadelle. Le nuage ne doit pas noircir toute la moitié supérieure. La citadelle doit rester lisible en vignette 320 × 180.

### 1.2 Trajectoire du regard obligatoire

Le regard doit parcourir naturellement :

1. silhouette sombre et turquoise du héros ;
2. herbes éclairées et sentier descendant ;
3. feu orange et silhouettes du camp ;
4. pylône cyan vertical ;
5. rivière en S ;
6. citadelle centrale ;
7. éclair et nuage.

Obtenir cette trajectoire avec le terrain, les valeurs, les lignes, la lumière, le mouvement et la couleur. Ne pas ajouter des flèches d’interface ou un marqueur géant pour corriger une composition faible.

### 1.3 Trois profondeurs et quatre fréquences

**Premier plan, 0–35 m** : contrasté, chaud, riche, silhouettes nettes, herbes longues, fleurs, pierres, héros et traces de vent. Les hautes fréquences sont visibles ici.

**Plan moyen, 35–200 m** : jouable et lisible ; camp, arbres, sentiers, eau, ruines, ennemis et pylône. Détails regroupés en masses, jamais distribués uniformément.

**Arrière-plan, 200–1 200 m** : monumental et simplifié ; citadelle, grandes falaises, montagnes, nuage. Contraste, saturation et détail diminuent avec la distance, sauf l’accent cyan focal.

Composer simultanément à quatre fréquences :

- macro 80–500 m : vallée, citadelle, rivière, falaises, grands vides ;
- méso 8–80 m : bosquets, camp, ruines, terrasses, clairières ;
- micro 0,5–8 m : touffes, pierres, accessoires, ruptures de terrain ;
- détail 1–50 cm : fleurs, arêtes, coutures, éclats, traces, seulement près du joueur/focales.

### 1.4 Palette ancre étendue

| Famille | Couleur ancre | Variantes autorisées | Usage |
|---|---:|---|---|
| Soleil miel | `#FFD68A` | `#FFE7B0`, `#E7A85D` | lumière directe, bords chauds |
| Ciel pastel | `#A9D4EA` | `#D7E7EC`, `#7FAEC8` | ciel clair, horizon |
| Brume froide | `#AFC8D3` | `#8AA6B6`, `#D0DDE0` | séparation des plans |
| Herbe moyenne | `#5D8F3D` | `#406C35`, `#7FA648` | masse dominante |
| Herbe au soleil | `#B2C85A` | `#D2D878`, `#8EAC43` | pointes, pentes focales |
| Terre | `#8A5A36` | `#B27B4B`, `#5C3C2B` | chemins, sols secs |
| Roche ocre | `#9B6842` | `#C08B5A`, `#684B40` | falaises et ruines |
| Ombre froide | `#4C5B75` | `#34465E`, `#69778E` | creux, volumes, lointain |
| Bois/cuir | `#684028` | `#8C5A34`, `#3B2924` | héros, camp, armes |
| Ivoire | `#D8C8A1` | `#F0E2BE`, `#AFA17D` | tunique, céramique isolante |
| Turquoise héros | `#168F9B` | `#0E6574`, `#46B2B3` | cape, petites signatures |
| Cyan électrique | `#22D9EC` | `#0FA4C1`, `#78F2F6` | énergie active rare |
| Cœur électrique | `#ECFFFF` | blanc légèrement cyan | centre des arcs et noyaux |
| Cuivre patiné | `#6E765E` | `#A36B43`, `#3F6C68` | technologie ancienne |
| Feu | `#FF9A3D` | `#FFD06A`, `#D94B2B` | camp, cuisson, contraste |
| UI or pâle | `#D8B36A` | `#F0D99A`, `#8D7040` | traits et focus UI |

Ratio global cible : 55–65 % verts/ocres, 25–35 % ciel/eau/brume, 5–10 % neutres de personnage/architecture, **moins de 5 % de cyan saturé simultanément à l’écran** hors climax du boss.

### 1.5 Hiérarchie des valeurs

- Ciel lumineux : valeur 75–95 %, sans blanc brûlé permanent.
- Herbe éclairée : 55–75 %.
- Sol et roche moyens : 35–65 %.
- Ombres : 18–38 %, teintées bleu-violet, jamais bouchées.
- Héros : masse principale 18–45 %, accents ivoire 55–75 %, turquoise 35–65 %.
- Citadelle : masse 35–60 %, détachée de la montagne par brume et contour.
- Cœur électrique : 90–100 % sur une surface très mince ; halo moins lumineux et plus large.

En niveaux de gris, le héros, le pylône et la citadelle doivent rester distincts. Le cyan ne doit jamais être la seule raison pour laquelle un mécanisme se lit.

### 1.6 Interdits visuels

- contours noirs épais ;
- aplats de toon à rupture dure sur tout le monde ;
- rendu plastique à roughness uniforme ;
- microbruit procédural sur chaque surface ;
- textures de photo non repeintes ;
- normal maps trop profondes qui scintillent ;
- bloom laiteux couvrant les formes ;
- ciel bleu uniforme sans gradation ;
- herbe identique, équidistante et orientée pareil ;
- falaises composées d’un même rocher agrandi ;
- cyan présent sur chaque objet ;
- architectures sci-fi propres et neuves ;
- noir pur dans les couloirs ;
- fog opaque qui efface le monde ;
- profondeur de champ pendant le gameplay ;
- motion blur activé par défaut ;
- vignette forte, aberration chromatique ou sharpen agressif ;
- decals, particules ou icônes servant à dissimuler un asset pauvre.

---

## 2. GRAMMAIRE DES FORMES DU MONDE

### 2.1 Nature de la Vallée de Néris

La nature emploie des courbes longues, des S, des terrasses, des éventails et des asymétries équilibrées. Les roches ont des strates horizontales larges cassées par des fractures diagonales. Les arbres ont des troncs inclinés et des couronnes aplaties irrégulières qui laissent voir le ciel entre les masses.

Les bords importants sont sculptés et légèrement exagérés : une arête éclairée doit se lire à 20–40 m. Les creux sont larges et froids. Le détail géologique reste regroupé ; il ne transforme pas chaque centimètre en bruit.

### 2.2 Camp et constructions organiques

Le camp utilise : triangles, pieux inclinés, tissus tendus, bois fendu, cordes, cuir, vannerie et métal récupéré. Sa silhouette est basse, irrégulière et horizontale, interrompue par la verticale du feu et de deux bannières étroites. Aucun tipi ou camp fantasy générique copié : utiliser des auvents asymétriques à trois points et des paravents tressés.

### 2.3 Technologie de Résonance

La technologie ancienne emploie :

- obélisques effilés mais asymétriques ;
- anneaux incomplets ;
- canaux verticaux en creux ;
- fourches à trois branches non symétriques ;
- plaques de céramique ivoire séparant le cuivre ;
- articulations mécaniques lentes et lourdes ;
- motif original de « courant fendu » : une ligne verticale divisée autour d’un losange creux puis réunie ;
- motif de terre : trois arcs descendants vers une barre horizontale brisée ;
- motif de surcharge : anneau incomplet avec quatre dents extérieures.

Ne pas utiliser d’œil stylisé identique à un symbole connu. Le nom « Œil-Tempête » peut être évoqué par des anneaux concentriques incomplets et un vide central, sans pupille figurative.

### 2.4 Citadelle de l’Œil-Tempête

La citadelle conjugue masses de pierre anciennes et infrastructure de Résonance : base horizontale très large, terrasses successives, contreforts, tours coupées, spire centrale verticale et deux épaules latérales plus basses. Sa silhouette doit fonctionner à 300–420 m avec moins de vingt grandes formes.

Rapport de masse cible :

- 55 % socle/terrasses de pierre ;
- 20 % tours et contreforts ;
- 10 % vides, arches et ruptures ;
- 10 % cuivre/céramique de Résonance ;
- moins de 5 % émission cyan.

La spire capte l’orage. Trois lignes énergétiques descendent de la couronne vers les flancs, mais aucune façade entière ne devient néon.

### 2.5 Héros et factions

- Héros : diagonales ascendantes, cape courte en pointe divisée, asymétrie fonctionnelle, silhouette athlétique et ouverte.
- Pillards braise : triangles rapides, bas du corps léger, accessoires souples et cassés.
- Pillards azur : verticales minces, protections segmentées, armes longues.
- Briseurs d’obsidienne : trapèzes bas, épaules carrées, masses pleines.
- Colosse : asymétrie lourde, blocs naturels, bras de tailles légèrement différentes.
- Chasseur quadrupède : lignes tendues, carapace en lames, profil long et bas, aucune anatomie équine reconnaissable.
- Gardien de l’Orage : cercle incomplet du noyau opposé à six appuis angulaires ; armure fermée qui s’ouvre progressivement.

---

## 3. ÉCHELLE PHYSIQUE ET REPÈRES DE PRODUCTION

`1 unité Godot = 1 mètre`, axe Y vertical.

| Élément | Dimension cible |
|---|---:|
| Héros | 1,78 m |
| Pillard braise | 1,40–1,52 m |
| Pillard azur | 1,58–1,72 m |
| Briseur d’obsidienne | 1,85–2,05 m |
| Colosse des ravins | 3,7–4,3 m |
| Chasseur quadrupède | garrot 1,9–2,2 m ; torse total 3,0–3,5 m ; longueur 4,0–4,8 m |
| Gardien de l’Orage | hauteur fermée 5,2–6,0 m ; longueur 8–10 m |
| Herbe courte / haute | 0,18–0,35 m / 0,55–0,95 m |
| Fleurs | 0,18–0,55 m |
| Buissons | 0,7–2,2 m |
| Arbres | 5–12 m ; spécimens héros 14–17 m |
| Rochers proches | 0,15–4 m |
| Modules de falaise | 6–28 m |
| Pylône de vallée | 28–36 m |
| Citadelle — largeur lisible | 160–230 m |
| Citadelle — spire | 90–120 m au-dessus du socle |
| Arène du boss | diamètre jouable 36–40 m ; marge visuelle jusqu’à 46 m |

Créer une scène `ScaleLab.tscn` contenant silhouettes 1 m, 1,78 m, 2 m, 4 m, 6 m, 12 m, 32 m et 100 m, une grille métrique, la caméra de jeu et la caméra North Star. Aucun asset ne passe en production si son échelle n’a pas été vérifiée ici.

### 3.1 Caméra North Star

- `VistaCamera_Hero01` ;
- caméra 4,0–4,5 m derrière le héros ;
- objectif 1,55–1,75 m au-dessus de ses pieds ;
- FOV **horizontal** 68° par défaut, plage acceptable 65–72° ;
- roll nul ;
- pitch très légèrement descendant, ajusté pour garder ciel 38–48 % de l’image ;
- exposition manuelle verrouillée ;
- 2560 × 1440 pour captures ; 1920 × 1080 pour gameplay ;
- même transform, seed, heure, vent et preset à chaque comparaison.

Attention à `Camera3D.fov` : avec `KEEP_HEIGHT` — comportement adapté au paysage et valeur par défaut habituelle — la propriété représente le FOV vertical. À 16:9, un FOV horizontal de 65–72° correspond à environ **39,4–44,5° vertical**, et 68° horizontal à environ **41,6° vertical**. Ne pas entrer `68` comme FOV vertical, ce qui produirait une image beaucoup trop large. Autre option : utiliser explicitement `KEEP_WIDTH` et consigner que `fov` représente alors l’angle horizontal. Verrouiller ce choix dans la capture de référence.

---

## 4. CONTRAT DE LIVRAISON DE CHAQUE ASSET

Un asset n’est `PASS` que si tous les éléments applicables existent :

1. ID stable et nom lisible.
2. Concept face/profil/dos ou planche de formes, même simple mais explicite.
3. Échelle réelle et dimensions enregistrées.
4. Source maître modifiable dans `source_assets/`.
5. Export `.glb` reproductible.
6. Pivot/origine corrects ; base au sol ; axes validés.
7. Mesh propre, normales/tangentes correctes, aucune face parasite.
8. UV0 ; UV de lightmap lorsque requis ; aucune couture visuelle critique.
9. Matériaux conformes à la bible, sans chemin absolu.
10. Textures nommées, canaux documentés, mipmaps et compression vérifiés.
11. LOD0/1/2 et LOD3/impostor quand pertinent ; silhouette conservée.
12. Collision simple distincte du rendu ; concave uniquement statique.
13. Navigation/occlusion/lightmap flags selon le rôle.
14. Rig, skinning, clips, sockets et retarget profile si animé.
15. États gameplay visibles si réactif.
16. Scène Godot `.tscn` d’intégration, pas seulement un `.glb` brut.
17. Vignette/capture dans une scène d’aperçu avec lumière neutre et lumière finale.
18. Budget triangles, matériaux, textures et coût mesuré.
19. Licence/source/auteur/modifications dans le manifeste.
20. Test sans erreur d’import, ressource rose, warning récurrent ou dépendance privée.

### 4.1 Arborescence

```text
source_assets/
  concepts/
    north_star/ characters/ creatures/ architecture/ props/ ui/
  blender/
    characters/ creatures/ environment/ architecture/ props/
  textures_source/
    trim_sheets/ atlases/ masks/ decals/ ui/
  vfx_source/
assets/
  characters/{hero,enemies,boss}/
  equipment/{weapons,bracelet,arrows}/
  environment/{terrain,rocks,foliage,water,sky,clutter}/
  architecture/{camp,ruins,pylon,citadel,dungeon,boss_arena}/
  props/{physical,puzzle,loot,cooking,story}/
  vfx/{environment,resonance,electricity,combat,fire,boss,ui}/
  ui/{icons,frames,cursors,glyphs,maps}/
materials/{masters,instances}/
shaders/{characters,environment,foliage,water,sky,vfx,ui}/
scenes/lookdev/{ScaleLab,StyleLab,HeroShotLab,LightingLab,FoliageLab,WaterLab,AnimationLab,VFXLab}/
docs/assets/{ASSET_MANIFEST.csv,IMPORT_RULES.md,TEXEL_DENSITY.md,MATERIAL_LIBRARY.md,SHOT_LIST.md}/
tools/blender/{export_gltf.py,validate_scene.py}/
```

### 4.2 Nommage

| Préfixe | Usage | Exemple |
|---|---|---|
| `SK_` | mesh skinné | `SK_Hero_Neris_LOD0` |
| `SM_` | mesh statique | `SM_Cliff_Strata_A_LOD0` |
| `AN_` | animation | `AN_Hero_MantleHigh` |
| `MAT_` | matériau maître/instance | `MAT_Rock_Ochre_Dry` |
| `T_` | texture | `T_RockAtlas_ORM_2K` |
| `SH_` | shader | `SH_FoliageWind` |
| `VFX_` | effet | `VFX_ArcLink_Active` |
| `UI_` | élément UI | `UI_Icon_Ground` |
| `COL_` | collision | `COL_Pylon_Base` |
| `SOCKET_` | point d’attache | `SOCKET_Weapon_R` |
| `PV_` | scène preview | `PV_Hero_Full` |

Suffixes : `_LOD0..3`, `_A..F` pour formes, `_Dry/_Wet/_Charged/_Fractured` pour états seulement si un mesh ou matériau distinct est réellement nécessaire. Les variantes de teinte ne doivent pas dupliquer inutilement le matériau.

### 4.3 Textures et canaux

- Albedo/base color en sRGB, sans ombre ni lumière directionnelle cuite.
- Normal map importée comme normal map et testée sous rotation complète de la lumière.
- ORM linéaire : R = occlusion, G = roughness, B = metallic, avec convention consignée.
- Emissive séparée ; le masque ne contient pas un halo déjà peint.
- Masques de vent, usure, humidité, charge et fracture en linéaire.
- Mipmaps obligatoires pour la 3D ; vérifier le bleed des atlases.
- Préférer TGA/PNG de travail et formats importés/compressés par Godot ; ne pas éditer `.godot/imported`.
- Conserver les maîtres haute définition hors runtime lorsque le dépôt le permet ; exporter seulement la résolution utile.

### 4.4 Densité texel cible

| Famille | Cible indicative |
|---|---:|
| Visage, mains, Bracelet | 768–1 024 px/m |
| Corps héros / boss focal | 512–768 px/m |
| Ennemi standard | 384–512 px/m |
| Armes/interactables vus de près | 512 px/m |
| Props de camp/coffres | 256–512 px/m |
| Architecture jouable | 192–256 px/m + trims/détails |
| Roches proches | 192–256 px/m + macro variation |
| Terrain | 64–128 px/m de base + détails tilés contrôlés |
| Lointains | 32–64 px/m ou atlas/impostor |

Ce sont des points de départ. Une densité supérieure doit être justifiée par la distance caméra et la capture 1440p, pas par le prestige du nombre.

### 4.5 Budgets géométriques

| Asset | LOD0 | LOD1 | LOD2 | Texture runtime max |
|---|---:|---:|---:|---:|
| Héros | 45k–70k tris | 55 % | 25 % | 2K par set ; 4K seulement preuve |
| Gardien de l’Orage | 110k–160k | 55 % | 25 % | 2–3 sets 4K maximum |
| Chasseur quadrupède | 60k–90k | 55 % | 25 % | 2K par set |
| Ennemi standard | 24k–45k | 55 % | 25 % | 2K |
| Colosse | 55k–85k | 55 % | 25 % | 2K–4K justifié |
| Arbre héros | 10k–18k | 50 % | 22 % | atlas 2K |
| Arbre standard | 5k–12k | 50 % | 20 % | atlas 2K |
| Gros rocher | 4k–12k | 50 % | 20 % | atlas 2K |
| Prop interactif | 1k–8k | 50 % | 20 % | 512–1K |
| Module architecture | 2k–20k | 55 % | 25 % | trim 2K |

Les chiffres sont des plafonds, pas des objectifs à remplir. La silhouette gouverne la décimation. Tester les LOD en déplacement avec le FOV réel.

---

## 5. MATÉRIAUX PAINTERLY — RÈGLES COMMUNES

### 5.1 Traitement de surface

Chaque matériau associe :

- une grande masse de couleur lisible ;
- une variation macro très lente ;
- deux ou trois plans d’ombre adoucis ;
- des arêtes légèrement plus chaudes ;
- des creux légèrement plus froids ;
- une roughness non uniforme mais calme ;
- une normale de faible à moyenne intensité ;
- des détails localisés selon histoire, contact et humidité.

Ne pas peindre des arêtes blanches partout. L’usure apparaît sur les zones manipulées, exposées ou heurtées. La saleté s’accumule dans les creux cohérents et au contact du sol.

### 5.2 Valeurs PBR indicatives

| Matière | Metallic | Roughness | Particularité |
|---|---:|---:|---|
| Pierre sèche | 0 | 0,72–0,92 | variation macro et creux froids |
| Pierre humide | 0 | 0,35–0,65 | assombrie, reflet borné près de l’eau |
| Terre | 0 | 0,78–0,96 | faible normal, jamais brillante |
| Bois brut | 0 | 0,62–0,88 | fibres larges sculptées, pas photo |
| Cuir | 0 | 0,48–0,76 | usure sur plis et bords |
| Tissu | 0 | 0,78–0,95 | détail de tissage discret à courte distance |
| Bronze/cuivre | 0,75–1 | 0,28–0,62 | patine non métallique visuellement mate |
| Fer usé | 0,75–1 | 0,38–0,68 | rayures directionnelles rares |
| Céramique ivoire | 0 | 0,32–0,62 | cassures mates, arêtes propres |
| Cristal de Résonance | selon shader | 0,1–0,35 | profondeur stylisée, émission contrôlée |
| Feuillage | 0 | 0,65–0,9 | transmission/subsurface stylisée modérée |

### 5.3 Réactions visuelles partagées

Tous les assets réactifs peuvent recevoir les mêmes états sans devenir des objets néon :

- `Wet` : albedo 8–18 % plus sombre, roughness diminuée, filet/ripple local ;
- `Charged` : lignes fines dans les creux/ports, petites étincelles directionnelles, cadence lente ;
- `Grounded` : flux descendant visible, particules attirées vers le sol, émission qui décroît ;
- `Overloaded` : cadence accélérée, vibration mécanique courte, fissures émissives localisées ;
- `Burning` : bord carbonisé progressif, feu attaché aux zones plausibles, fumée selon matériau ;
- `Fractured` : fissures géométriques ou masque contrôlé, éclats et changement de silhouette si cassable.

Chaque état possède au moins deux canaux parmi forme, mouvement, lumière, son et couleur. Aucun état critique ne dépend uniquement du cyan.

---

## 6. TERRAIN ET GÉOLOGIE DE LA VALLÉE

### 6.1 Macro-formes obligatoires

Le terrain 512 × 512 m doit être conçu comme un décor intentionnel, pas comme un bruit de hauteur :

1. **Crête de départ** vers `(0, 24, 170)` : pente douce orientée vers la citadelle, surface fleurie, silhouette du héros dégagée.
2. **Descente principale** : courbe en S qui cadre d’abord le camp puis le pylône.
3. **Terrasse du camp** vers `(45, 6, 65)` : clairière de 28–38 m, trois accès, couvertures et fuite visuelle vers la citadelle.
4. **Lit de rivière** autour de `Z = 10` : berges alternant plages basses, rochers et roseaux, sans canal uniforme.
5. **Falaise d’apprentissage ouest** entre `X = -80` et `-145` : paroi escaladable lisible, deux corniches de repos, sommet récompensé par un panorama.
6. **Éperon du pylône** vers `(115, 18, -25)` : terrasse rocheuse légèrement surélevée, vide visuel autour du landmark.
7. **Forêt claire sud-est** : couvertures végétales alternées avec trouées, pas de mur d’arbres.
8. **Ruines centrales** : terrain plus géométrique et comprimé, transition graduelle vers la Citadelle.
9. **Plateau d’entrée du donjon** vers `(0, 34, -210)` : escalier/rampe monumental, végétation raréfiée, traces de charge.
10. **Limites naturelles** : falaises, eau profonde, éboulis, végétation dense ou contreforts ; aucune paroi invisible exposée.

Le terrain comporte trois hauteurs réellement exploitables et des regards croisés. Depuis au moins trois points, le joueur doit pouvoir revoir la crête de départ et comprendre la distance parcourue.

### 6.2 Matériau de terrain

Créer `SH_GroundBlend` avec au minimum :

- sol herbeux vert-olive ;
- terre chaude compactée ;
- roche ocre ;
- sol humide sombre ;
- option de poussière/cendre locale près de la foudre.

Blending par splat map ou vertex colors, renforcé par pente, hauteur et humidité. Triplanar sur les pentes fortes. La variation macro doit avoir des motifs de 8–30 m ; le détail de sol, 0,15–0,8 m. Éviter que deux bruits de tailles similaires se battent.

Les chemins sont dessinés par : compression de l’herbe, terre visible, alignement de pierres, interruption des fleurs, traces de roues/pieds et lumière. Ils ne sont ni parfaitement lisses, ni des bandes marron de largeur constante.

### 6.3 Kit roche et falaise

| ID/famille | Qté min. | Échelle | Description visuelle |
|---|---:|---:|---|
| `SM_Cliff_Strata` A–F | 6 | 10–28 m | murs stratifiés, profils différents, grands replats |
| `SM_Cliff_Corner` A–C | 3 | 8–20 m | angles concaves/convexes, continuité des strates |
| `SM_Cliff_Overhang` A–B | 2 | 8–16 m | surplombs pour silhouette, marqués `unclimbable` si nécessaire |
| `SM_Cliff_Cap` A–D | 4 | 5–14 m | rebords praticables et transitions terrain |
| `SM_Ledge_Climb` A–F | 6 | 1–5 m | corniches, prises larges, langage escaladable |
| `SM_Rock_Hero` A–D | 4 | 2–5 m | rochers focales à silhouette forte |
| `SM_Boulder_Med` A–F | 6 | 0,8–2,5 m | rochers de composition et couverture |
| `SM_Stone_Small` A–H | 8 | 0,12–0,8 m | groupes de sol, jamais scatter uniforme |
| `SM_ScreeCluster` A–D | 4 | 1–4 m | amas fusionnés limitant les draw calls |
| `SM_Rock_Arch` A | 1 | 10–18 m | point d’intérêt facultatif original |
| `SM_Background_Mesa` A–F | 6 | 40–160 m | montagnes non jouables, silhouettes simples |

Style : roche sédimentaire ocre, arêtes larges sculptées, plans légèrement facettés mais non low-poly, strates peintes en masses, cavités bleu-violet, lichens vert-gris seulement sur faces humides/abritées. Produire deux atlases cohérents plutôt qu’une texture unique répétée sur tout.

Le kit doit pouvoir créer au moins cinq compositions visuellement distinctes sans rotation/scale évidents. Ajouter des patches manuels de rupture, racines, mousse et éboulis aux répétitions les plus visibles.

### 6.4 Langage d’escalade

Les surfaces escaladables présentent au moins deux indices :

- strates ou fractures horizontales espacées à l’échelle des mains ;
- variation de roughness/mousse interrompue par des zones d’appui ;
- silhouette de rebord accessible ;
- petites plantes de fissure sur les routes sûres.

Les surfaces non escaladables utilisent surplomb, plaques lisses de céramique, pointes, ruissellement électrique, roche friable ou géométrie explicitement fermée. Ne pas utiliser une couleur arbitraire comme unique règle.

---

## 7. VÉGÉTATION ET SOL VIVANT

### 7.1 Familles d’assets

| Famille | Variantes min. | Silhouette et rôle |
|---|---:|---|
| Herbe courte en plaque | 3 | couvre-sol calme, 0,18–0,32 m |
| Touffe moyenne | 4 | éventail de 12–28 brins, 0,35–0,62 m |
| Herbe longue héroïque | 4 | lames courbes épaisses, 0,65–0,95 m |
| Herbe sèche | 2 | ponctuation ocre, jamais dominante |
| Fleur blanche | 2 | petites ombelles en groupes de 5–12 |
| Fleur jaune | 2 | disques chauds, focales du premier plan |
| Fleur bleue | 2 | accent rare, plus sombre que l’électricité |
| Fleur haute | 1 | tige 0,45–0,65 m, rythme vertical |
| Fougère basse | 2 | ombre humide et base des roches |
| Roseau | 3 | berges, orientation liée à l’eau |
| Buisson rond ouvert | 3 | masse moyenne laissant des trous |
| Buisson épineux | 2 | zones sèches/dangereuses |
| Arbuste fleuri | 2 | transition prairie-bosquet |
| Arbre canopée plate | 3 | silhouette principale de vallée |
| Arbre incliné | 2 | cadre et direction du vent |
| Arbre riverain | 2 | feuillage plus frais, branches descendantes |
| Arbre foudroyé | 2 états | POI ; bois noirci, fente pâle, repousses |
| Souche/tronc mort | 3 | narration, couverture, bois récupérable |
| Racines de falaise | 2 | intégration roche/sol |

Les feuilles utilisent des cartes découpées selon la silhouette ou de petits bouquets géométriques ; aucune grande carte rectangulaire visible de profil. Alpha scissor/dither privilégié au blend transparent lorsque possible. Tester le feuillage sur ciel clair, roche, eau et ombre.

### 7.2 Densité par distance

Les valeurs décrivent des **touffes**, pas des brins individuels :

- 0–18 m : 7–14 touffes/m² dans les zones héroïques ; 4–8 ailleurs ;
- 18–40 m : 2,5–5 touffes/m² ;
- 40–80 m : 0,5–1,8 touffe/m² + matériau de sol enrichi ;
- 80–140 m : groupes simplifiés/HLOD, couleurs de terrain ;
- au-delà : aucune géométrie d’herbe fine, seulement masses/impostors si utile.

Fleurs : 0,08–0,45 groupe/m² selon masque, en phrases irrégulières. Réserver les plus fortes densités au premier plan North Star, aux bords de chemin et aux clairières ; créer des vides de 2–8 m qui donnent du rythme.

Arbres : groupes de 3–9 avec arbres de tailles différentes, puis respirations. La forêt claire doit conserver des lignes de vue de 15–40 m. Les pentes, le camp, les arènes et les lignes caméra ont des masques d’exclusion.

### 7.3 Shader `SH_FoliageWind`

Entrées minimales :

- direction/force globale du `WindManager` ;
- vertex color R = flexion depuis la racine ;
- G = mouvement fin des pointes/feuilles ;
- B = variation de phase ;
- A = masque d’interaction ou rigidité selon convention documentée ;
- phase par `INSTANCE_CUSTOM` ou données d’instance ;
- variation de teinte contrôlée ;
- amplitude par espèce ;
- impulsion locale du héros ;
- option de vent de tempête local.

Mouvement : lente flexion de masse + flutter plus rapide et faible. Le tronc bouge moins que les branches ; la base de l’herbe reste fixe. Les instances ne se balancent jamais en phase. Le passage du héros ouvre l’herbe dans un rayon 1,2–1,8 m, avec retour amorti, sans mise à jour CPU de toute la prairie.

### 7.4 Placement artistique

Créer des « phrases » réutilisables mais variées :

- grande touffe + deux moyennes + fleurs + vide ;
- rocher bas + herbe sèche côté soleil + fougère côté ombre ;
- arbre incliné + buisson opposé + fenêtre vers landmark ;
- roseaux interrompus par une plage praticable ;
- fleurs qui se raréfient à l’approche d’un danger électrique.

Le scatter déterministe combine pente, altitude, humidité, type de sol, distance à l’eau, distance au chemin, exposition, zones de gameplay et corrections artistiques manuelles.

---

## 8. EAU, BERGES ET HUMIDITÉ

### 8.1 Assets

- `SM_RiverRibbon` par segments courbes avec largeur 4–16 m ;
- `SM_LakeSurface` pour bassins plus calmes ;
- `SM_ShoreFoamStrip` courbes de rive ;
- `SM_RipplePatch` pour vent/interaction ;
- `SM_ShallowCurrent` pour direction visible ;
- 3 familles de galets humides ;
- 3 familles de roseaux ;
- 2 troncs flottés ;
- 2 petites passerelles/gué isolant ;
- VFX entrée, nage si prévue, pas, projectile, objet lourd, eau chargée et décharge.

### 8.2 `SH_WaterStylized`

- couleur peu profonde turquoise-vert `#4FAFB2` ;
- profondeur bleu-pétrole `#2A7182` ;
- deux normales animées de directions/vitesses différentes ;
- distorsion faible, jamais gélatineuse ;
- transparence contrôlée, profondeur du fond lisible aux gués ;
- mousse d’intersection fine et cassée ;
- reflets stables et limités ;
- gradient de profondeur ;
- courant directionnel visible par traits doux ;
- paramètre `charged_amount` révélant des arcs de surface et des zones sûres.

L’eau guide vers la citadelle. Elle reste plus calme dans les respirations panoramiques et plus texturée près des roches. En état chargé, le danger se lit par une onde qui se propage, des points d’impact, un son et des intervalles sûrs ; ne pas teinter uniformément tout le bassin en cyan.

Fallback Web : pas de réfraction écran ni SSR ; mesh opaque/translucide simple, deux normales, profondeur approximée, mousse par texture/vertex color, VFX de charge simplifié.

---

## 9. CIEL, NUAGES, ORAGE ET ATMOSPHÈRE

### 9.1 Ciel fixe de fin d’après-midi

Créer un ciel allant de miel pâle à gauche vers bleu pastel à droite et bleu-gris au zénith. Le soleil reste hors champ haut-gauche, mais ses rayons définissent toutes les arêtes chaudes. Ajouter des cirrus larges très doux et quelques masses de cumulus périphériques. Le ciel ne doit jamais concurrencer la citadelle par un bruit excessif.

### 9.2 Nuage local de la Citadelle

Construire le nuage avec 4–7 couches :

- base sombre aplatie au-dessus de la spire ;
- masse centrale plus dense ;
- bords plus clairs et chauds côté soleil ;
- deux nappes périphériques de vitesses différentes ;
- ombres internes bleu-violet ;
- illumination cyan interne très brève lors des éclairs.

Utiliser dôme, cartes/meshes courbes, textures tilées et profondeur artificielle. Raymarch uniquement en preset Cinematic si mesuré. La forme générale doit évoquer une couronne basse et menaçante, pas couvrir tout le ciel.

### 9.3 Éclair majeur

Chaque éclair comporte :

1. préflash interne du nuage 40–90 ms ;
2. trait principal irrégulier à cœur blanc fin ;
3. 2–4 branches cyan plus faibles ;
4. impact sur spire ou conducteur ;
5. lumière locale très brève ;
6. afterglow 100–250 ms ;
7. tonnerre retardé selon distance apparente.

Éviter zigzag régulier, ruban opaque et bloom plein écran. Dans la vue North Star, un seul éclair majeur domine ; d’éventuelles branches secondaires restent fines.

### 9.4 Profondeur atmosphérique

- fog distance classique pour désaturer le lointain ;
- fog height léger dans la vallée et près de l’eau ;
- volumetric fog Forward+ localisé dans les creux et autour de la citadelle ;
- `FogVolume` ponctuel, jamais empilé sans mesure ;
- montagnes 550–1 200 m éclaircies, refroidies et simplifiées ;
- premier plan sans voile gris uniforme.

---

## 10. CAMP EXTÉRIEUR ET PROPS DE VIE

### 10.1 Composition du camp

Clairière de 28–38 m. Le feu occupe une position lisible mais non centrale parfaite. Trois groupes fonctionnels forment un triangle : repos/auvent, stockage/cuisine, garde/armes. Trois approches restent visibles : route frontale, herbes/rochers d’infiltration, hauteur ou détour systémique.

Le camp doit être lisible à 70–110 m grâce à : flamme orange, fumée fine, deux bannières, 3–5 silhouettes ennemies aux poses différentes et reflet chaud sur une toile. Il ne doit pas dépendre de petits props pour être reconnu.

### 10.2 Kit minimum de camp

| Asset | Variantes | Description |
|---|---:|---|
| Auvent asymétrique | 2 | toile ocre/rouge, trois appuis, cordes visibles |
| Paravent tressé | 3 | silhouette basse, couverture destructible contrôlée |
| Pieux/barricades | 5 modules | bois fendu, angles irréguliers, sans palissade générique |
| Feu de camp | 1 + états | pierres, bois, braises, flamme/fumée/lumière |
| Trépied/marmite | 1 | cuisson ennemie, silhouette lisible |
| Couchettes | 2 | tissus roulés, paille, peaux originales |
| Caisses bois | 3 | tailles et assemblages distincts |
| Coffres de stockage | 2 | non confondus avec coffre de loot |
| Paniers | 3 | vannerie, ingrédients visibles |
| Râtelier d’armes | 2 | sockets réels pour loot |
| Table basse | 1 | carte/objets de narration |
| Jarres céramique | 4 | cassables/non cassables clairement distinguées |
| Cordes/attaches | 4 | segments courbes, pas de lignes flottantes |
| Bannières | 3 | motif de faction original, vent cohérent |
| Torches | 2 | piquet et applique |
| Restes/ossements stylisés | 2–3 | non gore, narration discrète |

Matériaux dominants : bois brun, corde chanvre, toile terre/rouge sourd, céramique grise, quelques récupérations métalliques. Le cyan n’apparaît que sur un objet capturé/chargé ou une réaction active.

### 10.3 Feu et fumée

La flamme possède noyau jaune pâle, milieu orange et bord rouge transparent, avec 2–3 meshes/particles complémentaires. Les braises montent par bouffées, la fumée suit le vent puis se dissipe. La lumière locale est chaude, de portée bornée et sans flicker stroboscopique. Prévoir états `unlit`, `embers`, `lit`, `cooking`, `electrically_disturbed`.

---

## 11. RUINES, PYLÔNE ET CITADELLE EXTÉRIEURE

### 11.1 Kit de ruines de vallée

- mur plein 4 m et 8 m ;
- mur brisé gauche/droite ;
- angle intérieur/extérieur ;
- arche entière et effondrée ;
- colonne entière, courte et brisée ;
- linteau ;
- escalier 2 m et 4 m ;
- dalle/floor 2 × 2 et 4 × 4 m ;
- socle de mécanisme ;
- canal de Résonance droit, angle et intersection ;
- plaque de céramique isolante ;
- relief mural original ;
- amas de gravats fusionné ;
- racines/mousse d’intégration.

Pierre ocre légèrement plus géométrique que la falaise, cuivre très patiné, céramique ivoire fissurée. Les ruines montrent l’ancien langage du donjon sans révéler toutes les solutions.

### 11.2 Pylône de vallée — hero asset secondaire

Dimensions : 28–36 m, base 8–12 m, sommet asymétrique. Silhouette : base tripode/étagée, fût légèrement effilé, trois canaux creux, anneau incomplet proche du sommet et fourche terminale.

Sous-assets :

- base avec marches ;
- trois contreforts ;
- fût en 3–5 segments ;
- plaques de céramique isolante ;
- rails de cuivre ;
- anneau mobile ;
- noyau/port de connexion à hauteur du joueur ;
- couronne de capture ;
- gravats et végétation d’intégration ;
- collisions séparées ;
- LOD distant conservant fût, anneau et fourche.

États :

- `Dormant` : cuivre sombre, anneau incliné, aucune émission continue ;
- `Detected` par Pulse : ports soulignés 2–4 s ;
- `Linked` : flux fin de la base au sommet ;
- `Charging` : anneau se redresse, rythme croissant ;
- `Active` : cœur blanc/cyan, légère rotation, onde vers citadelle ;
- `Overloaded` : vibration, arcs vers points de fuite, télégraphe orange/cyan ;
- `Grounded` : énergie descendante et relâchement mécanique.

Activation spectaculaire 3–5 s, entièrement composée des assets de gameplay.

### 11.3 Citadelle extérieure

Kit/proxy final minimum :

- socle principal en terrasses ;
- façade d’entrée monumentale ;
- deux ailes asymétriques ;
- 4 contreforts majeurs ;
- 4 tours de hauteurs différentes ;
- 2 tours ruinées ;
- spire centrale en 5 segments ;
- couronne de capture ;
- 3 conduits énergétiques géants ;
- pont/rampe d’accès ;
- arches/vides profonds ;
- murs de fond simplifiés ;
- kit de dégâts/éboulis ;
- HLOD 200–500 m et silhouette lointaine 500 m+.

À distance, employer de vraies ombres de forme et une légère émission, pas une façade détaillée de milliers de petites fenêtres. Les cyan actifs tracent trois lignes principales lisibles, laissant plus de 95 % de la masse non émissive.

---

## 12. DONJON — KIT ARCHITECTURAL ET LANGAGE VISUEL

### 12.1 Ambiance

Base ocre sombre et bronze, céramique ivoire pour l’isolation, ambre faible pour la circulation, cyan directionnel uniquement pour l’énergie. Les salles restent lisibles sans exposition adaptative agressive. Les hauteurs, rails et portes montrent le trajet électrique à distance.

### 12.2 Grille et modules

Grille principale 2 m, grands modules 4 m. Produire :

- sols pleins, sols à canal, sols fissurés, sols de danger ;
- murs 2 × 4, 4 × 4 et 4 × 8 m ;
- angles, piliers, contreforts, arches ;
- plafonds plats, voûtes, puits verticaux ;
- escaliers, rampes, plateformes et corniches ;
- portes simples, portes à anneau, grande porte centrale ;
- cadres de mécanismes ;
- rails/câbles droit, angle, T, croix et vertical ;
- conduits en pont au-dessus du joueur ;
- grilles/barrières ;
- panneaux sculptés et fresques ;
- variantes intactes, usées et brisées ;
- gravats et transitions sol/mur ;
- modules spécifiques d’arène.

Limiter les matériaux par module. Utiliser trimsheet pierre/bronze/céramique et atlas de détails. Les joints modulaires sont cachés par contrefort, rupture de dalle, rail ou changement de niveau, jamais par une pluie de petits props.

### 12.3 Éclairage motivé

Chaque lumière visible possède une source : brasero ambre, cristallin faible, rail alimenté, ouverture extérieure ou noyau de mécanisme. Les câbles cyan n’éclairent localement que lorsqu’ils sont alimentés. Le trajet sûr conserve une valeur minimale lisible ; les dangers ont rythme et forme, pas seulement luminance.

---

## 13. HÉROS — DESIGN, MODÈLE ET ÉQUIPEMENT

### 13.1 Identité originale

Le héros est un jeune adulte humain de 1,78 m, athlétique sans musculature exagérée. Il doit être reconnu de dos par cinq éléments :

1. cheveux sombres sculptés en mèches larges, coupe courte asymétrique ;
2. mantelet/écharpe turquoise courte, divisée en deux pointes inégales ;
3. épaulière unique ivoire et bronze sur le côté opposé au Bracelet ;
4. Bracelet de Résonance large à l’avant-bras gauche ;
5. diagonale arc/carquois + arme de mêlée, créant un X incomplet.

Ne pas utiliser bonnet, longue tunique verte, oreilles pointues, bouclier iconique, coiffure ou palette assimilable à Link. La cape s’arrête au-dessus des genoux pour l’escalade et ne forme pas une grande voile.

### 13.2 Costume

- sous-tunique ivoire cassé, manches retroussées ;
- plastron textile/cuir léger asymétrique, brun terre ;
- mantelet turquoise désaturé, bord usé et doublure plus sombre ;
- pantalon charbon ample aux cuisses et resserré aux mollets ;
- ceinture multi-couches avec deux sacoches fonctionnelles ;
- protections de genoux souples ;
- bottes d’escalade cuir sombre, semelles épaisses, bandes turquoise très discrètes ;
- gants courts, paume renforcée ;
- boucles en bronze patiné ;
- Bracelet ivoire/cuivre/cyan ;
- aucune surface propre : usure légère aux coudes, genoux, bords et prises.

Le visage reste original et crédible même si la caméra montre surtout le dos : traits simples, nez net, sourcils expressifs, peau chaude, aucun maquillage ou marque copiée. Prévoir expressions minimales douleur, effort, concentration, surprise et soulagement.

### 13.3 Mesh et matériaux

- 45k–70k tris LOD0 ;
- tête/mains suffisamment propres pour les plans courts ;
- boucles de déformation aux épaules, coudes, poignets, hanches, genoux, chevilles et cou ;
- cape/mantelet séparé mais intégré au rig ;
- cheveux en volumes sculptés, quelques cartes seulement pour mèches fines ;
- 3–5 slots matériaux maximum : peau, tissu/cuir, métal/céramique, cheveux, yeux ;
- variantes visuelles `Dry`, `Wet`, `Charged`, `LowHealth` très sobres ;
- outline noir interdit ; rim light artistique faible et dépendante de la scène.

### 13.4 Rig et sockets

Rig humanoïde propre, 4 influences principales par vertex si possible, twist bones utiles et contrôleurs non exportés. Sockets minimum :

- main droite/gauche ;
- dos arme longue ;
- hanche arme courte ;
- arc ;
- carquois ;
- flèche ;
- Bracelet ;
- VFX torse/tête/pieds/mains ;
- points d’IK mains/pieds.

Tester toutes les combinaisons d’équipement en course, roulade, saut, escalade, visée et cuisine. Aucun carquois ne traverse la cape ou le mur de manière majeure.

### 13.5 Bracelet de Résonance

Forme : brassard asymétrique couvrant environ 60 % de l’avant-bras, base de cuir sombre, trois plaques de céramique ivoire séparées par des nervures de cuivre, petit anneau incomplet sur le dessus et canal lumineux en « courant fendu ».

États visuels :

- repos : aucune émission ou respiration presque imperceptible ;
- Pulse : anneau s’ouvre de 12–20°, onde concentrique fine ;
- Link : deux segments alignés, flux dirigé vers l’index/port ;
- Polarité : plaques coulissent, vecteur avant/arrière lisible ;
- Arc Step : charge concentrée au poignet puis trait arrière ;
- Ground : plaques s’abaissent, énergie circule vers paume/sol ;
- surcharge : joints orange/cyan alternés, vibration brève ;
- cooldown/refus : retour mécanique et son sec, pas de clignotement rouge générique.

### 13.6 Bibliothèque d’animation héros

Créer ou acquérir légalement puis retoucher un set cohérent. Minimum visuel :

**Locomotion** : idle calme, idle observation, idle fatigué, starts 4 directions, marche/course/sprint 8 directions ou blendspaces, stops, pivots 90/135/180°, strafes lock-on, changements de pente.

**Air** : anticipation saut, takeoff, montée, apex, chute courte/longue, contrôle directionnel, landing léger/lourd/roulé, stumble, dégâts de chute.

**Traversal** : vault bas gauche/droite, mantle bas/haut, accroche rebord, shimmy, escalade haut/bas/gauche/droite, repos mur, saut de mur, lâcher, glissade d’épuisement, réception Arc Step.

**Défense** : garde par famille d’arme, impact garde léger/lourd, déviation parfaite, guard break, esquives 4 directions, esquive parfaite/Clarity.

**Armes** : idle/équipement/rangement, 3 légères, lourde, attaque sprint, sortie d’esquive, aérienne/plongeante, impact/recovery et dernier éclat pour chaque famille applicable. Les six familles ne partagent pas simplement le même clip accéléré.

**Arc** : sortir, encocher, viser haut/bas/gauche/droite, tir rapide, tir complet, cancel, impact/recul, déplacement en visée.

**Résonance** : Pulse, focus, sélection port, confirmation Link, maintien Link, Polarité attirer/repousser, Arc Step départ/vol/arrivée, Ground startup/maintien/release, refus, surcharge.

**Interactions** : ramasser sol/haut, ouvrir coffre, pousser/tirer, porter/poser batterie, activer pylône, levier, bouton reset, cuisiner, manger, boire, examiner fresque, checkpoint.

**Réactions** : hits avant/arrière/gauche/droite, stagger léger/lourd, knockdown, relever, électrocution, brûlure, trempé, épuisement, mort.

**Cinématiques** : reveal respiration/regard, activation pylône, entrée boss, victoire et retour de contrôle.

Priorités : contact pieds, placement mains, anticipation, impact, réactions directionnelles et transitions. Secondary motion de cape/cheveux bornée ; fallback stable si la physique secondaire pose problème.

---

## 14. BESTIAIRE — CINQ FAMILLES VISUELLEMENT DISTINCTES

Les trois pillards peuvent partager une base biologique, mais pas une simple géométrie et un matériau recoloré. À 25 m, en silhouette noire et sans UI, un testeur doit identifier la famille, le type d’arme et l’imminence d’une attaque.

### 14.1 Pillard braise (`raider_red`)

**Taille et silhouette** : 1,40–1,52 m ; torse court incliné ; jambes nerveuses ; avant-bras longs ; tête en forme de coin ; deux petites excroissances osseuses orientées vers l’arrière, non assimilables à des oreilles de Bokoblin. Centre de gravité vers l’avant.

**Visage** : museau non porcin ; mâchoire courte ; nez plat ; pommettes hautes ; yeux ambrés petits et espacés. Pas de masque tribal générique.

**Costume** : tissus terre cuite/rouge sombre, ceinture de corde, protections en cuir récupéré, bras souvent dégagés, bandes carbonisées. Une seule pièce de métal au maximum.

**Armes/props** : gourdin court, torche, petite jarre inflammable ou pierre. Le gourdin est large et léger visuellement, adapté aux balayages.

**Télégraphes** : s’accroupit, recule l’arme, expose tout le torse ; attaque en arc ample. Fuite : oreilles/excroissances et épaules s’abaissent, regard vers issue.

**États** : peur, alerte, brûlé, humide, chargé, désarmé, stagger, mort. Palette chaude mais peu saturée pour ne pas rivaliser avec le feu.

**Animations propres** : idle accroupi, flair/écoute, patrouille sautillante, cri d’alerte, attaque 1/2, recul après esquive, ramassage objet, lancer, peur/fuite, célébration courte.

### 14.2 Pillard azur (`raider_blue`)

**Taille et silhouette** : 1,58–1,72 m ; posture plus droite ; épaules étroites ; jambes longues ; petite crête osseuse verticale ; protège-épaules segmentés créant une silhouette en parenthèses.

**Costume** : indigo délavé, bleu ardoise, cuir brun froid. Protections en bois stratifié et céramique gris-bleu. Accent azur mat, distinct du cyan électrique.

**Armes** : lance longue ou arc court asymétrique, carquois de 6–10 flèches visibles. Silhouette arme lisible avant engagement.

**Télégraphes** : lance abaissée puis ligne tendue pour thrust ; arc levé avec reflet mat sur la pointe ; pas de tir sans posture préparatoire. Lorsqu’il alerte, bras haut et bannière/bracelet sonore.

**Animations propres** : maintien de distance, pas croisés, contournement, thrust, sweep, charge tenue, tir, changement de position, esquive occasionnelle, appel allié, utilisation couverture.

### 14.3 Briseur d’obsidienne (`raider_black`)

**Taille et silhouette** : 1,85–2,05 m ; bassin bas ; torse très large ; cou presque absent ; bras épais ; deux grandes plaques d’épaule inégales formant un trapèze.

**Armure** : pierre vitreuse sombre/céramique noire mate en plaques imparfaites, montée sur cuir. Les bords ébréchés révèlent un cœur brun-gris, pas un noir pur. Quelques rivets en bronze. Visage partiellement visible sous une visière fendue originale.

**Arme** : masse lourde à tête oblongue, ou grand bouclier de récupération pour une variante clairement signalée. L’arme doit transmettre poids et inertie.

**Télégraphes** : plante les pieds, épaules montent, masse passe derrière la tête ; le tracking décroît visiblement. Garde : arme/avant-bras fermement devant le noyau, jauge de posture matérialisée par fissures/pose, pas seulement UI.

**Dommages visuels** : plaques qui se fissurent, morceau d’épaule détachable contrôlé, poussière noire, posture qui s’ouvre. Pas de démembrement gore.

**Animations propres** : marche lourde, blocage, impact garde, combo 2–3, overhead, brise-garde, guard break, stagger lourd, reprise lente.

### 14.4 Colosse des ravins (`ravine_troll`)

**Taille et silhouette** : 3,7–4,3 m ; torse incliné ; bassin massif ; bras asymétriques, l’un couvert d’une croissance rocheuse ; petites jambes puissantes ; tête enfoncée mais visage lisible.

**Anatomie originale** : peau gris-ocre épaisse, plaques naturelles suivant l’omoplate et l’avant-bras, racines sèches et cuir servant de sangles. Ne pas créer un simple humanoïde agrandi.

**Point faible** : nodule minéral pâle entre omoplate et nuque, visible seulement lors de certaines poses ; forme, pulsation et son le signalent, pas une cible rouge peinte.

**Props** : ceinture de troncs tressés, rochers ramassables, protection de bois sur une jambe. Aucun club gigantesque si ses mains servent déjà à arracher/lancer.

**Animations** : locomotion lourde, virage en plusieurs appuis, balayage, frappe verticale, coup au sol, onde de choc, ramassage/lancer rocher, destruction couverture, renversement, point faible exposé, stagger et chute. Les impacts font réagir ventre, épaules et masses secondaires.

**VFX** : poussière ocre, cailloux, onde au sol à bord lisible, éclats selon surface. Limiter l’opacité près de la caméra.

### 14.5 Chasseur quadrupède (`centaur_hunter`)

Créer une créature centauroïde originale, **non équine**.

**Corps inférieur** : quadrupède bas inspiré d’un félin cuirassé et d’un grand lézard, sans sabots, crinière ou croupe de cheval. Quatre pattes à trois doigts larges, épaules avant plus hautes, longue cage thoracique souple et courte queue stabilisatrice en lames de céramique.

**Torse supérieur** : naît en avant du bassin inférieur et reste incliné, avec deux bras longs, tête étroite à plaque frontale et deux mandibules latérales décoratives. Proportions volontairement non humaines.

**Dimensions** : 1,9–2,2 m au garrot inférieur, 3,0–3,5 m au sommet, 4,0–4,8 m de long.

**Armure** : lames de céramique ivoire/gris froid, attaches bronze, textiles bleu nuit très réduits. Silhouette en flèches arrière traduisant la vitesse. Pas de cuirasse de cheval fantasy.

**Armes** : grand arc composite concave original et lame de mêlée en demi-lune brisée. Carquois latéral fixé au corps inférieur.

**Télégraphes** : charge — appuis avant grattent le sol, tête s’abaisse et toutes les lames s’alignent ; salve — torse se redresse et la queue stabilise ; attaque majeure — cri, arc/lame au-dessus de la ligne des épaules.

**Animations** : idle territorial, pas/trot/galop 8 directions, cercle, freinage glissé, charge, annulation contrôlée, tir simple/salve, combo mêlée, ruade latérale non équine, cri, stagger séparé haut/bas, mort contrôlée. Le haut et le bas doivent se coordonner sans effet de mannequin collé.

### 14.6 Variations contrôlées

Chaque famille peut posséder 2–3 variations de tête, tissu, accessoires et usure. La variation ne change jamais un télégraphe critique. Utiliser données d’instance pour teinte/roughness lorsque possible, sans multiplier les matériaux.

### 14.7 LOD et animation distante

- LOD0 pour combats proches ;
- LOD1 conservant mains, arme et contour à 20–45 m ;
- LOD2 simplifiant visage/accessoires à 45–90 m ;
- animation complète seulement pour IA proche/visible ;
- silhouettes distantes gardent les poses de menace ;
- ombres réduites avant de supprimer la lisibilité.

---

## 15. BOSS — GARDIEN DE L’ORAGE

### 15.1 Concept anatomique original

Le Gardien est une machine-bête à six appuis, construite pour ancrer la foudre : quatre pattes locomotrices basses et deux grands membres antérieurs capables de frapper. Sa masse centrale évoque un animal de siège sans reproduire une espèce réelle : dos voûté en pierre, tête courte protégée par trois plaques de céramique, épaules de bronze, longue queue-conducteur segmentée.

Silhouette clé :

- base large et stable ;
- six points de contact triangulaires ;
- deux bras plus massifs créant les attaques lisibles ;
- anneau incomplet vertical au-dessus du dos ;
- noyau circulaire fendu au sternum ;
- queue terminée par une fourche de mise à la terre.

Dimensions : 8–10 m de long, 5,2–6 m de haut anneau fermé, largeur 5–7 m. La caméra doit voir le noyau et au moins quatre appuis pendant les moments de lecture.

### 15.2 Matériaux et sous-meshes

- squelette/masse de pierre ocre sombre ;
- articulations bronze/cuivre ;
- plaques isolantes ivoire ;
- câbles-tendons bleu pétrole non émissifs au repos ;
- noyau cyan à cœur blanc ;
- deux cristaux conducteurs d’épaule ;
- 8–14 plaques d’armure détachables ou animables ;
- anneau dorsal en 3 segments ;
- queue en 5–7 segments ;
- sockets VFX par membre, noyau, cristaux, anneau, tête et sol.

Les composants destructibles sont des sous-meshes propres avec états intacts/fissurés/détruits. Aucun swap ne doit faire disparaître brutalement une grande masse sans débris/transition.

### 15.3 Lecture par phase

**Phase 1 — Armure chargée** : silhouette fermée ; plaques imbriquées ; noyau couvert par trois volets ; anneau vertical incomplet ; énergie lente dans 4–6 canaux. Les membres annoncent clairement mêlée, arc frontal et frappe de zone.

**Mise à la terre** : énergie remonte une dernière fois puis descend vers deux pylônes ; anneau s’affaisse ; volets du sternum s’ouvrent ; vapeur/poussière ; noyau blanc-cyan exposé 5–8 s.

**Phase 2 — Surcharge** : plaques d’épaule ouvertes ; deux cristaux visibles ; câbles-tendons plus exposés ; rythme lumineux plus rapide ; fissures localisées ; silhouette plus haute. Les cristaux ont une forme de diapason brisé, non de gemme flottante générique.

**Phase 3 — Tempête** : cristaux détruits ; noyau et articulations visibles ; certaines plaques pendent ; anneau divisé tourne autour d’un axe instable ; queue plante des arcs au sol. La silhouette reste compréhensible malgré les effets.

**Mort/apaisement** : tous les hazards cessent ; membres s’abaissent ; énergie quitte les extrémités vers le noyau, puis devient une pulsation turquoise calme ; nuage s’ouvre partiellement et laisse entrer une lumière chaude.

### 15.4 Animations boss

Intro 5–8 s passable, idle phase 1/2/3, locomotion avant/latérale/rotation, combo court, bras gauche/droit, arc frontal, slam, récupération, mise à la terre, noyau exposé, projectiles, placement de zones, charge, frappe au sol, cristaux touchés/détruits, transitions 1→2 et 2→3, stagger, mort et état vaincu.

Le poids vient de l’anticipation, du transfert d’appuis, du retard des plaques/câbles et du settle, pas d’un shake permanent.

### 15.5 Arène

Arène circulaire 36–40 m jouables :

- quatre pylônes de terre à 90° ;
- deux bandes de sol conducteur ;
- deux zones de céramique isolante ;
- 1–2 bassins/rigoles peu profonds en phase 2 si gameplay validé ;
- bord architectural bas qui n’occulte pas la caméra ;
- aucune colonne centrale ;
- quatre sorties visuelles mais une seule entrée logique ;
- porte, gradins en ruine et citadelle visibles ;
- matériaux distincts au sol par forme, relief et roughness.

---

## 16. ARMES ET ÉQUIPEMENTS VISUELS

Chaque arme possède : modèle équipé, modèle au sol, icône, silhouette dans inventaire, sockets de main/dos, variantes d’usure, VFX d’impact par matériau et débris de rupture.

### 16.1 Gourdin de bois

Branche dense torsadée, longueur 1,1–1,3 m, masse noueuse en bout, bandes de cuir et aucune lame métallique. Silhouette large, irrégulière et chaleureuse. États : fibres intactes, fissures, bandes lâches, rupture en 2–4 éclats. Faible conductivité immédiatement visible.

### 16.2 Épée usée

Lame 0,8–0,9 m en fer patiné, profil asymétrique, pointe réparée, 2–4 ébréchures nettes, garde courte en bronze et poignée cuir ivoire/brun. Aucun profil de Master Sword. Usure : reflet plus terne, fissure près d’une encoche, son et petites poussières métalliques.

### 16.3 Lance

Hampe 1,9–2,2 m en bois sombre, ligatures turquoise sourd, tête foliacée étroite en bronze/fer avec petit insert céramique. La conductivité vient de la tête et de deux bandes, pas de toute la hampe. Centre de prise marqué visuellement.

### 16.4 Hache lourde

Longueur 1,25–1,45 m ; tête en coin dissymétrique, contrepoids minéral, manche brun renforcé de métal. La silhouette montre immédiatement le startup/recovery élevé. Éclats de métal et manche fissuré à l’usure.

### 16.5 Arc simple

Arc composite asymétrique en deux bois, renforts de tendon/tissu, longueur 1,45–1,6 m. Courbure élégante sans reprendre un arc connu. Corde, poignée et point d’encoche visibles ; flexion modérée animée. Usure : craquements, fibre levée, ligature détendue.

### 16.6 Lame conductrice

Hero prop original : lame en deux rails de cuivre/fer séparés par une âme de céramique ivoire, longueur 0,9 m, pointe fourchue très courte et canal de courant fendu. Au repos, quasi aucune émission. Chargée, un trait blanc-cyan circule entre les rails ; surcharge, arcs vers la garde et son instable. Faible durabilité traduite par plaques céramiques qui se fissurent.

### 16.7 Flèches

- flèche standard : bois, empennage brun/turquoise, pointe fer ;
- flèche conductrice : hampe sombre, pointe double en cuivre, anneau céramique ; n’émet qu’une fois chargée ;
- modèle en vol simplifié ;
- modèle planté par surface ;
- trail très fin seulement pour vitesse/charge ;
- impacts pierre, bois, métal, eau, chair stylisée et énergie.

### 16.8 États de durabilité

Quatre niveaux : `Fresh`, `Used`, `Critical`, `Broken`. Les différences sont localisées : ébréchures, fissures, ligatures, roughness, son et micro-VFX. Ne pas changer simplement l’albedo en rouge. À 25 %, le changement doit se voir dans l’inspection et s’entendre en combat, sans bruit permanent.

---

## 17. COFFRES, BUTIN, INGRÉDIENTS ET CUISINE

### 17.1 Coffres

Trois familles :

1. **Vallée** : bois cintré, ferrures bronze, motif simple de courant fendu ; 1,1 × 0,65 × 0,65 m.
2. **Donjon** : pierre/céramique, couvercle coulissant/rotatif, anneau de Résonance ; plus lourd et géométrique.
3. **Final** : version unique, ivoire et bronze, noyau turquoise calme, silhouette lisible dans l’arène apaisée.

Chaque coffre possède fermé, ciblé discret, ouverture, ouvert/vide, déjà pillé, et éventuellement chargé/bloqué. L’intérieur contient une lumière douce très brève, jamais un projecteur de loot. Le butin apparaît avec poids et pose, pas comme une icône flottante géante.

Implantation minimale : trois coffres de vallée, un au camp, trois dans le donjon, un dans l’antichambre/avant le boss et un coffre final distinct si le flux le demande. Varier le dressing et l’orientation, pas les règles d’interaction ou l’alignement d’ouverture.

### 17.2 Sept ingrédients

| Ingrédient | Forme et palette | Habitat/affordance |
|---|---|---|
| Fruit de soin | fruit ovale corail mat, feuille vert sombre | arbre/buisson près route sûre |
| Champignon de soin | chapeau crème à bord rosé, pied épais | ombre de roche et forêt |
| Viande | paquet stylisé rouge sombre/brun, ficelle ou drop propre | ennemis/faune abstraite ; non gore |
| Herbe d’endurance | trois feuilles longues en spirale, pointe jaune-vert | base de route verticale |
| Racine défensive | tubercule ocre noueux, feuilles bleu-gris | sol rocheux/camp |
| Baie de résistance électrique | grappes de 3–5 baies violet-bleu à peau mate, nervures ivoire | près d’un isolant/danger ; **pas cyan lumineux** |
| Épice rare | capsule orange doré en étoile asymétrique | POI facultatif/pylône |

Chaque ingrédient possède mesh monde, icône peinte cohérente, légère animation naturelle, VFX de collecte discret et version dans panier/plat. Aucun halo permanent ; la silhouette, le contraste local et le mouvement suffisent.

### 17.3 Plats

Créer au minimum cinq présentations : ragoût de soin, bouillon d’endurance, plat défensif racine, brochette attaque, infusion de résistance électrique, plus ragoût instable. Utiliser bol en céramique du monde, formes/couleurs d’ingrédients reconnaissables, vapeur et reflet chaud. Les icônes doivent être illustratives mais rester lisibles à 64–96 px.

### 17.4 Station de cuisine

Feu, cercle de pierres, marmite bronze sombre, trépied, planche, petit panier et place d’alignement héros. Dans l’antichambre, variante intégrée à un foyer de pierre/céramique. Animations 2–4 s : déposer, remuer, bouffée de vapeur, résultat ; pas de séquence opaque longue.

---

## 18. PROPS PHYSIQUES ET ÉTATS SYSTÉMIQUES

### 18.1 Inventaire minimum

| Prop | Variantes | Matériau/lecture |
|---|---:|---|
| Caisse poussable | 3 tailles | bois, poignées, masse faible/moyenne |
| Bloc conducteur | 3 | métal patiné, larges faces de contact |
| Sphère roulante | 2 | pierre et métal ; masse lisible |
| Planche/passerelle | 3 longueurs | bois épais, extrémités d’appui |
| Bouclier ennemi arrachable | 2 | bois/céramique ou métal clairement distinct |
| Rocher lançable | 3 | pierre, prise/poids visuels |
| Jarre cassable | 4 | céramique fine, fissures et fragments |
| Baril non explosif | 2 | bois ; aucune convention rouge explosive |
| Barricade destructible | 3 modules | bois assemblé, zones de rupture |
| Pont magnétique | 2–3 segments | métal/céramique, pivots visibles |
| Plaque isolante mobile | 2 | céramique ivoire, bords épais |
| Ancrage Arc Step | 3 | fourche métallique/anneau, état visible |

Dimensions, centre de masse, prises et points de contact doivent correspondre à la physique. Les objets lourds ont bases larges, volumes pleins et mouvements lents ; les légers ont poignées, vides ou assemblages fins.

### 18.2 Variantes d’état

Ne pas dupliquer chaque mesh six fois. Utiliser matériaux d’état, masques et sous-meshes détachables. Un prop système doit montrer : matériau principal, capacité à être porté/poussé, ports, état de charge, humidité, fracture et zone de danger si applicable.

### 18.3 Rupture

Créer 2–5 fragments préparés par famille, collision temporaire simplifiée, poussière/étincelles selon matière et decal/trace native seulement si le preset l’autorise. Les fragments disparaissent ou deviennent décoratifs sans bloquer le chemin. Fallback Web : moins de fragments et pas de decal.

---

## 19. ASSETS DU GRAPHE ÉLECTRIQUE ET DES QUATRE SALLES

Tous les nœuds ont un langage commun, avec formes et mouvements distincts pour l’état. Les ports sont de vrais éléments de géométrie, orientés vers les connexions plausibles.

### 19.1 Catalogue commun

| Nœud/asset | Forme | États visuels essentiels |
|---|---|---|
| `SourceNode` | socle large + noyau profond | dormant, actif lent, surchargé |
| `CableNode` | rail cuivre en creux | sombre, propagation 0→1, actif |
| `ConnectorNode` | fourche/prise orientée | compatible, incompatible, connecté |
| `SwitchNode` | levier/anneau mécanique | A/B, bloqué, action en cours |
| `MovableConductorNode` | bloc métal à plaques de contact | libre, aligné partiel, connecté |
| `RelayNode` | colonne/anneau rotatif | angle, port ouvert, partiel, complet |
| `ReceiverNode` | anneau incomplet qui se ferme | vide, alimentation partielle, validé |
| `DoorNode` | segments lourds et canaux | verrouillée, alimentée, ouverture, ouverte |
| `HazardNode` | électrode pointue + marquage sol | repos, télégraphe, actif, cooldown |
| `BatteryNode` | capsule céramique/cuivre avec poignée | vide, charge, pleine, décharge, surcharge |
| `WaterZoneNode` | bassin/rigole | neutre, propagation, danger, retour calme |
| `GroundNode` | plaque basse à trois arcs | disponible, connexion, dissipation |
| `Insulator` | panneau céramique ivoire épais | stable, fissuré, invalide |
| `ResetNode` | pédestal ambre avec poignée circulaire | prêt, confirmation, reset |

### 19.2 Propagation visuelle

La ligne alimentée ne s’allume pas instantanément : un front lumineux parcourt le câble à vitesse lisible, puis laisse une émission plus faible. À une bifurcation, le front se divise. Un récepteur partiel ferme une portion d’anneau ; un récepteur complet verrouille mécaniquement l’anneau et produit un accord sonore/lumière.

Erreur de connexion : deux étincelles courtes orange/cyan et recul mécanique ; aucune explosion gratuite. Port incompatible : forme barrée/rotation refusée et son mat.

### 19.3 Salle 1 — Chaîne

Assets spécifiques : vide court, deux plaques de contact massives, bloc conducteur à pousser, rail source et récepteur, porte à deux segments, bouton reset. Le chemin source→plaque→bloc→plaque→récepteur doit être visible depuis l’entrée par alignement spatial et rainure au sol.

### 19.4 Salle 2 — Circuit vertical et Ground

Assets spécifiques : puits 16–24 m, ascenseur à plateau, rails verticaux, électrodes intermittentes, corniches, interrupteur supérieur, points de terre, ancrages Arc Step et grille de sécurité. Les électrodes ont trois poses : repli, précharge, arc ; le rythme se comprend avant engagement.

### 19.5 Salle 3 — Relais rotatifs et Polarité

Quatre colonnes de 3–5 m, chacune avec ports extrudés visibles, anneau de rotation, repères géométriques et base magnétique. Chaque rotation de 90° est un mouvement lourd avec anticipation/settle. Les segments correctement alignés s’allument progressivement ; les alignements partiels ont un état propre, pas un simple oui/non.

### 19.6 Salle 4 — Batterie, eau et risque

Assets spécifiques : batterie transportable avec deux poignées, station de charge, deux sockets, bassin conducteur, passerelle isolante, coupe-circuit, deuxième mécanisme et zones de récupération. La batterie affiche sa charge par ouverture mécanique de trois volets plus pulsation, afin de rester lisible sans couleur.

### 19.7 Salle centrale

Grande carte murale en relief montrant les quatre branches. Chaque salle active une ligne continue, un anneau/contrepoids et une couche d’éclairage. Trois ou quatre grands récepteurs selon logique finale entourent la porte du boss. L’ouverture déplace de vraies masses de pierre/bronze pendant 5–8 s, avec poussière, accord mécanique et flux convergent.

### 19.8 Antichambre

Checkpoint original, coffre garanti, station de cuisine, baies électriques, râtelier, fresque bois/métal/céramique/eau, ouverture visuelle vers l’arène et porte retour. La fresque enseigne par reliefs de matière et direction des lignes, pas par long texte.

---

## 20. VFX — INVENTAIRE EXHAUSTIF ET GRAMMAIRE

Tous les effets importants suivent : **intention → contact → conséquence → résidu**. Le point de contact réel gouverne l’effet. Les VFX ne doivent pas masquer le héros ou une menace plus de 0,35 s.

### 20.1 Environnement

- poussière très légère près des chemins ;
- pollen/semences par poches, pas partout ;
- feuilles emportées lors de rafales ;
- herbe ouverte autour du héros ;
- insectes lumineux très rares dans les zones ombragées, non cyan ;
- brume basse près de l’eau ;
- ripples et éclaboussures ;
- poussière/cailloux sur glissade et atterrissage ;
- fumée du camp ;
- braises ;
- nuages et éclairs ;
- petites particules de ruine quand un mécanisme lourd bouge.

### 20.2 Résonance

| Action | Intention | Action/contact | Résidu/fin |
|---|---|---|---|
| Pulse | anneau Bracelet s’ouvre | onde mince sur sol/air, contours brefs des ports | traces décroissent 2–4 s selon information |
| Focus | vignette très légère ou désaturation locale bornée | cible gagne contour/segments en mouvement | retour immédiat sans afterimage |
| Arc Link preview | ligne pointillée/segments, direction visible | aucune vraie émission de destination avant validation | disparaît au refus |
| Arc Link actif | flux source→chemin→destination | cœur blanc fin, halo cyan modéré, petites branches | résidu aux ports, pas de ruban épais |
| Polarité attirer | particules/vecteurs convergents | objet oscille faiblement puis force réelle | poussière/contact à l’arrivée |
| Polarité repousser | éventail divergent | impulsion et traînée courte | étincelles si contact métal |
| Arc Step | charge concentrée au poignet/pieds | trait discontinu et silhouette brève, jamais clone opaque | réception, arcs vers ancrage, poussière |
| Ground | pose et ligne vers support | flux héros/objet→sol, anneaux descendants | énergie s’éteint du haut vers le bas |
| Clarity | accent très fin sur ouverture/point faible | pas de ralenti obligatoire | durée ~0,35 s, fade doux |

Le Pulse ne doit pas peindre tous les objets en cyan. Utiliser contours fins, hachures animées, ouverture de ports et relief de surface selon la nature de l’information.

### 20.3 Électricité et matériaux

- arc court métal→métal ;
- arc chaîne avec nœuds visibles ;
- surface chargée ;
- eau conductrice ;
- électrode télégraphe/impact ;
- source active ;
- récepteur partiel/complet ;
- surcharge ;
- mise à la terre ;
- arme chargée ;
- flèche conductrice ;
- héros/ennemi électrocuté ;
- rupture céramique/étincelles cuivre ;
- grand éclair atmosphérique.

Un arc : cœur blanc 1–3 px équivalent à la distance cible, halo cyan 2–5 fois plus large mais beaucoup moins opaque, branches irrégulières, déplacement discontinu, point de départ/arrivée stable. Ne pas utiliser une courbe sinusoïdale parfaite.

### 20.4 Combat

Créer une matrice VFX par intensité et matériau :

| Événement | Léger | Lourd | Critique/boss |
|---|---|---|---|
| Chair stylisée | trait d’impact, poussière colorée très sobre | burst directionnel, réaction | accent plus net sans gore |
| Bois | fibres/copeaux | éclats 2–4 | rupture préparée |
| Métal | 3–8 étincelles directionnelles | gerbe courte + son lourd | flash fin + decal/trace si permis |
| Pierre | poussière/1–2 grains | fragments + anneau sol | fissure/onde préparée |
| Céramique | éclats pâles | fragments angulaires | plaque détruite |
| Électricité | arc bref | branches + lumière | propagation/noyau |

Ajouter : trail d’arme très subtil selon vitesse, déviation parfaite, garde, guard break, esquive parfaite, posture brisée, point faible, tir/vol/impact flèche, arme critique, dernier éclat, rupture, soin, buff, mort/loot. Les trails ne doivent pas transformer chaque swing en large croissant opaque.

### 20.5 Feu, cuisine et loot

- flamme, fumée, braises ;
- ignition et extinction ;
- vapeur de cuisson ;
- bouffée de résultat réussi/instable ;
- collecte d’ingrédient ;
- ouverture de coffre ;
- apparition/présentation d’arme ;
- buffs attaque/défense/endurance/résistance/vitalité avec signatures distinctes ;
- checkpoint activé ;
- coffre final.

### 20.6 Boss

- intro noyau ;
- arc frontal ;
- frappe de zone ;
- mise à la terre par pylônes ;
- fenêtre noyau ;
- projectiles électriques ;
- zones de sol télégraphiées ;
- cristaux touchés/fissurés/détruits ;
- transition surcharge ;
- charge phase 3 ;
- éclairs au sol ;
- pattern final ;
- mort, aspiration de l’énergie et apaisement du ciel.

Chaque effet boss possède un budget simultané et une version de test isolée dans `VFXLab`. L’écran doit toujours laisser une route sûre lisible.

### 20.7 Qualité et fallbacks

High/Cinematic : `GPUParticles3D`, meshes, shaders, lumières brèves et decals mesurés. Medium : moins de particules, moins de lumières, textures plus petites, mêmes silhouettes. Web : pas de decals/compute ; meshes simples, particules réduites, émission non HDR excessive, mêmes timings et formes.

---

## 21. SHADERS MAÎTRES À PRODUIRE

Tous les shaders sont `.gdshader`, avec paramètres exposés, valeurs par défaut sûres, variante/fallback documentée, testés en Forward+ et sur le profil Web applicable.

### 21.1 `SH_CharacterPainterly`

Paramètres : base color/albedo, ORM, normal strength, shadow tint, warm light tint, diffuse ramp 2–3 zones adoucies, wrap, rim color/strength/power, macro color variation, AO influence, skin/tissu/métal profile, wetness, charge mask, hit flash réglable.

Le rim ne doit pas entourer uniformément la silhouette ; il dépend de la lumière/vue et reste discret. Le hit flash ne blanchit pas entièrement le personnage plus de 60–100 ms.

### 21.2 `SH_GroundBlend`

Quatre surfaces minimum, splat/vertex colors, pente/hauteur, triplanar roche, macro tint, détail, humidité, chemin, contrôle de tiling et raccord chunk. Les textures de détail ne doivent pas scintiller à 1440p avec l’antialiasing choisi.

### 21.3 `SH_RockTriplanar`

Atlas/trim, projection par axe, réduction de répétition, vertex tint, masque mousse selon normale/humidité, arête chaude modérée, creux froids et paramètre distance. Préserver les formes sculptées ; le shader complète, il ne crée pas la géologie.

### 21.4 `SH_FoliageWind` et `SH_TreeCanopy`

Vent global/local, phase instance, vertex masks, transmission stylisée, alpha scissor/dither, hue/brightness instance, distance fade contrôlé, interaction héros, réduction d’ombre à distance. Vérifier overdraw et absence de rectangle visible.

### 21.5 `SH_WaterStylized`

Deux normales, profondeur, rive, mousse, courant, réflexion/réfraction selon preset, charge, interaction et fallback sans screen texture.

### 21.6 `SH_MetalPatina`

Metallic/roughness corrects, patine par creux/masque, arêtes manipulées, rayures directionnelles rares, état wet/charged/overloaded. Ne pas rendre la patine entièrement métallique.

### 21.7 `SH_CeramicInsulator`

Ivoire mat, variation chaude/froide, craquelures contrôlées, fractures, poussière et absence de conduction visuelle. Les arêtes captent la lumière mais ne brillent pas comme du plastique.

### 21.8 `SH_EnergyCyan`

Masque directionnel, front de propagation 0–1, cœur blanc, halo cyan, Fresnel modéré, scroll non uniforme, pulsation organique, bruit à grandes formes, paramètres `energy`, `direction`, `overload`, `grounded`, `flash`. L’émission et les vraies lumières sont synchronisées par code.

### 21.9 `SH_ElectrifiedSurface`

Réseau fin suivant un masque/UV ou contact, points d’entrée/sortie, fréquence bornée, réaction eau/métal, télégraphe avant danger. Aucun bruit électrique uniforme sur tout l’objet.

### 21.10 `SH_CloudLayer`

Cartes/meshes multi-couches, profondeur par parallaxe légère, bord solaire, ombre froide, vitesse et illumination interne. Fallback réduit sans raymarch.

### 21.11 `SH_DistanceImpostor`

Fondu/rotation adapté aux montagnes/arbres lointains, color grading atmosphérique, profondeur/ombre approximée et transition masquée. Ne jamais utiliser près du joueur.

### 21.12 `SH_CameraFadeDither`

Fade dither ciblé pour la géométrie entre caméra et héros ; conserve la perception de collision et ne transforme pas toute la scène en transparence. Compatible avec le renderer choisi.

### 21.13 `SH_UIResonance`

Masque, ligne de courant fendu, pulsation faible, focus et état de charge. UI non HDR, flash réglable, aucune dépendance à la couleur seule.

---

## 22. ÉCLAIRAGE, ENVIRONNEMENT ET COLOR GRADING

### 22.1 Extérieur

- `DirectionalLight3D` venant de l’ouest/haut-gauche ;
- hauteur solaire 18–28°, cible 22–24° ;
- ombres longues mais adoucies ;
- lumière couleur miel, environnement froid ;
- PSSM et distance d’ombre concentrés sur la zone jouable ;
- ombres du héros et des menaces prioritaires toujours présentes ;
- exposition manuelle fixe ;
- tonemapper Filmic comme point de départ, comparé à ACES dans `LightingLab` ;
- glow faible à seuil élevé ;
- SSAO modéré ; SSIL subtil si coût acceptable ;
- SDFGI demi-résolution seulement si mesuré contre LightmapGI/probes ;
- reflection probes bornées près de l’eau, du pylône et des surfaces métalliques importantes ;
- debanding activé si compatible.

Ne pas donner de valeur d’énergie arbitraire sans connaître les unités physiques activées dans le projet. Verrouiller les relations visuelles dans le lab puis consigner les valeurs exactes et réglages de projet.

### 22.2 Donjon

Éclairage ambre faible sur la circulation, cyan motivé par circuit, ouvertures froides, LightmapGI pour l’architecture statique lorsque le workflow est stable, lumières dynamiques seulement aux mécanismes et VFX majeurs. Exposition stable entre salles ; transition extérieur/intérieur de 0,5–1,5 s si nécessaire, sans pompage pendant le combat.

### 22.3 Arène du boss

Base sombre mais lisible, noyau/pylônes comme accents, éclairage de contour froid sur le boss et rappel chaud depuis l’entrée. À chaque phase, modifier rythme et direction, pas seulement augmenter intensité/bloom. Après victoire, augmenter doucement la lumière naturelle et réduire le cyan.

### 22.4 Timeline d’un éclair atmosphérique

| Temps | Événement |
|---:|---|
| -0,08 s | lueur interne faible dans le nuage |
| 0 | trait principal + lumière très brève |
| 0,03–0,08 s | branches secondaires |
| 0,08–0,22 s | afterglow et émission de la spire |
| 0,2–0,6 s | retour à l’exposition identique, aucun pompage |
| selon distance | tonnerre spatial retardé |

### 22.5 LUT/grade

Créer un grade sobre : hautes lumières miel, ombres bleu-violet, verts légèrement olive, cyan protégé contre le clipping, peau chaude. Vérifier sous UI, en niveaux de gris, sur écrans non HDR et avec options daltonisme. Ne pas écraser les noirs ni sursaturer l’ensemble.

---

## 23. UI — IDENTITÉ ET ASSETS À FOURNIR

### 23.1 Langage

Plaques de pierre sombre translucide, contours or pâle, céramique ivoire pour les sélections, motif de courant fendu pour les transitions, rouge rubis pour la vitalité, turquoise doux pour l’endurance et cyan seulement pour la Résonance active.

Angles : coins légèrement coupés, anneaux incomplets et lignes minces. Éviter les cadres fantasy dorés surchargés, parchemins génériques et toute UI copiée d’un Zelda.

### 23.2 Kit `Theme`

- panneau 9-slice principal ;
- panneau secondaire ;
- tooltip ;
- bouton normal/hover/pressed/disabled/focus ;
- tab normal/actif ;
- slot inventaire, 4 raretés maximum ;
- slider, checkbox, option, scrollbar ;
- séparateur ;
- notification ;
- tutoriel contextuel ;
- cadre boss ;
- vignette de repas ;
- focus clavier/manette très lisible.

Utiliser `Control`, `Container`, anchors et safe areas. Le style doit tenir de 720p à 1440p, avec UI scale ajustable.

### 23.3 HUD

- santé : cristaux/segments rubis originaux, pas des cœurs ;
- endurance : jauge contextuelle près du héros, forme de demi-anneau turquoise ;
- arme : icône + famille + état d’usure en 4 niveaux par fissure de cadre ;
- flèches ;
- buff + temps ;
- interaction contextuelle avec glyph réel ;
- détection ennemie par arc/orientation et mouvement ;
- réticule arc original ;
- feedback Bracelet : source, port, destination, coût/refus ;
- barre boss ;
- objectif minimal du donjon si requis.

Le HUD normal occupe moins de 12–15 % de l’écran et disparaît progressivement hors contexte.

### 23.4 Inventaire d’icônes minimum

| Famille | Nombre minimal |
|---|---:|
| Armes | 6 + mains nues si utilisées |
| Flèches | 2 |
| Ingrédients | 7 |
| Plats | 6 |
| Buffs | 5 |
| Actions Bracelet | 5 |
| Fragments de Résonance | 3 |
| États matériau | 6 |
| Interactions | ouvrir, prendre, cuisiner, activer, déplacer, porter, poser, examiner, reset |
| Dangers | électrique, brûlant, chute, eau chargée, surface non escaladable |
| Défense | garde, déviation, esquive parfaite, posture brisée, imblocable |
| Options/accessibilité | remapping, FOV, shake, flash, bloom, daltonisme, aim assist, hints |
| Glyphs | clavier AZERTY/QWERTY, souris, manette générique et profils supportés |

Chaque icône fonctionne en 24, 32, 48, 64 et 96 px, en couleur et monochrome, sur fond clair/sombre. Pas de détail dépendant de traits d’un pixel.

### 23.5 Typographie

Deux familles maximum, légalement redistribuables et embarquées : une display aux terminaisons légèrement taillées pour les titres, une sans humaniste très lisible pour le gameplay. Créer un fallback complet pour les accents français. Texte important ≥ 24 px équivalent 1080p ; chiffres de combat et timers tabulaires si nécessaire. Aucun texte rasterisé dans les textures sauf motif fictionnel.

### 23.6 Carte

Si une carte est utilisée : relief peint simplifié, rivière et trois routes, landmarks découverts, aucune carte satellite omnisciente. Icônes rares et originales ; le monde reste guidé par curiosité. Prévoir état non découvert, aperçu et sélection.

### 23.7 Écrans et transitions

Produire les compositions complètes suivantes avec le même `Theme` :

- Boot/loading sobre : motif de courant fendu, barre ou indicateur non mensonger, conseils contextuels courts ;
- menu principal : vue réelle ou capture autorisée de la vallée, titre original, continuer/nouvelle partie/options/quitter ;
- pause : panneau limité laissant le jeu perceptible derrière sans illisibilité ;
- inventaire armes : grande silhouette, statistiques essentielles, durabilité et conductivité ;
- inventaire ingrédients/plats : grille, comparaison, journal des découvertes ;
- cuisine : sélection 1–5 ingrédients, aperçu de catégorie, confirmation et résultat ;
- options : contrôles, caméra, audio, graphismes, accessibilité, avec preview des effets sensibles ;
- écran mort/retry : cause concise, retry immédiat, préparation/menu ;
- écran victoire : ciel apaisé et motif du noyau calmé, recommencer/continuer/menu ;
- confirmation de sauvegarde écrasée et erreurs non destructives ;
- fade noir/couleur et loading transitionnels sans flash blanc brutal.

Le menu principal ne doit pas utiliser une image générée présentée comme le jeu. Si une capture de fond est utilisée, elle vient du build réel et correspond au preset indiqué.

---

## 24. DRESSING DES TROIS ROUTES ET MICRO-POI

### 24.1 Route de la rivière

Palette plus fraîche, herbes basses, roseaux, pierres humides, fruit/champignon, gués, petites ruines et vues progressives sur la citadelle. Ajouter un bassin conducteur où une source ou un objet enseigne eau + électricité sans punition mortelle immédiate.

### 24.2 Route des hauteurs

Roche ocre plus présente, végétation sèche et basse, prises de grimpe, corniches, ancrages Arc Step, vent plus fort, panorama et raccourci. Placer l’herbe d’endurance avant le défi. Le bord du monde est masqué par un relief crédible.

### 24.3 Route des ruines/camp

Sol compacté, murs bas, couvertures, objets physiques, lignes de vue tactiques, camp, cache et petit pont magnétique. La densité visuelle augmente près du conflit, mais le chemin de fuite reste lisible.

### 24.4 Huit à dix micro-POI

1. **Arbre foudroyé** : deux états, sol vitrifié, repousses, port de charge naturel.
2. **Pont magnétique** : segments métal/céramique, pivot visible, raccourci.
3. **Bassin conducteur** : eau, pierres isolantes, source latérale.
4. **Autel de terre** : plaque à trois arcs, racines et cuivre enterré.
5. **Patrouille aux rochers** : couvertures et objet lançable.
6. **Nid vertical** : plateforme naturelle, cordages/branches, Fragment facultatif.
7. **Ruine pédagogique** : fresque et rail montrant matériau/courant.
8. **Cache ennemie** : placement déduit d’un comportement, coffre/arme.
9. **Belvédère du pylône** : point de vue et Arc Link.
10. **Jardin de baies isolantes** : proximité du danger, préparation boss.

Chaque POI remplit au moins deux rôles : règle, route, histoire, décision, préparation ou récompense. Aucun POI n’est seulement un objet posé sur un terrain vide.

---

## 25. CINÉMATIQUES ET MOMENTS « WAHOU »

Toutes les séquences utilisent les assets de gameplay et restent passables.

### 25.1 Reveal vallée — 5 à 8 s

Départ proche des herbes/fleurs, légère montée derrière l’épaule du héros, révélation camp→pylône→citadelle, éclair, tonnerre retardé, retour au cadrage gameplay. Aucun cut ne présente un monde plus détaillé que celui parcouru.

### 25.2 Premier éclair

Événement contrôlé attirant vers la citadelle pendant que le joueur garde la main. Flash contenu, herbes/arbres réagissent par un vent légèrement retardé, camp/pylône restent lisibles.

### 25.3 Activation pylône — 3 à 5 s

Port→base→fût→anneau→couronne ; mouvement mécanique lourd ; onde directionnelle vers la citadelle ; caméra conservant héros et monument. Retour sans yaw brutal.

### 25.4 Porte centrale — 5 à 8 s

Quatre branches convergent, anneaux se ferment, masses se déverrouillent puis coulissent, poussière et lumière révèlent l’antichambre. Montrer la causalité, pas seulement la porte.

### 25.5 Entrée boss — 5 à 8 s

Silhouette du Gardien d’abord, noyau ensuite, six appuis en mouvement, un pattern de présentation sans danger caché, barre de vie à la fin. Passer la séquence place boss/joueur dans un état identique.

### 25.6 Transitions et victoire

Transition phase 2/3 : 2–4 s avec repositionnement sûr. Mort boss : 8–12 s, arrêt des hazards, chute mécanique, énergie calmée, nuage ouvert et coffre final. Le ciel ne devient pas soudainement midi bleu : conserver la continuité dorée.

---

## 26. IMPLÉMENTATION GODOT 4.7.1

### 26.1 Scène statique type

```text
AssetRoot (Node3D)
├── Visual
│   ├── LOD0 (MeshInstance3D)
│   ├── LOD1 (MeshInstance3D)
│   ├── LOD2 (MeshInstance3D)
│   └── Impostor/HLOD (optionnel)
├── Collision
├── NavigationModifier/Occluder (si requis)
├── Interaction/MaterialState (si requis)
├── VFXSockets
└── AudioSurface
```

Utiliser le LOD automatique à l’import lorsque sa qualité est validée ; utiliser les visibility ranges/HLOD manuels pour remplacer des groupes et contrôler les silhouettes. Ne pas superposer plusieurs LOD visibles. Prévoir marges, hysteresis et fades mesurés.

### 26.2 Scène personnage type

```text
CharacterBody3D
├── CollisionShape3D
├── VisualRoot
│   └── SK_Model/Skeleton3D/AnimationTree
├── EquipmentSockets
├── Hurtboxes/Hitboxes
├── VFXSockets
├── StateVisualController
└── AudioSurface/Voice
```

Le modèle visuel n’écrit pas l’état gameplay. `StateVisualController` traduit état, matériau, charge, dégâts et équipement en paramètres de shader, animation et VFX.

### 26.3 MultiMesh

Partitionner herbes, fleurs et arbustes en cellules de 24–48 m. Un `MultiMeshInstance3D` ne doit pas couvrir toute la vallée. Données par instance : transform, variation limitée de teinte/luminance, phase/amplitude de vent et variation éventuelle. Si le culling d’une cellule coûte plus que le gain d’instancing, mesurer et ajuster sa taille.

### 26.4 Import glTF

- `.glb` comme format d’échange principal ;
- options d’import et réglages avancés vérifiés par asset ;
- matériaux extraits/override sans modifier à la main la source importée ;
- scène héritée ou wrapper `.tscn` pour la logique ;
- animation preview, loop et root motion inspectés ;
- génération LOD automatique désactivée seulement lorsqu’elle casse une silhouette ou un skin ;
- suffixes de nœuds documentés si utilisés pour collision, skip ou LOD ;
- import headless sans erreur.

### 26.5 Culling et HLOD

- chunks terrain 64–128 m selon profil ;
- cellules de végétation 24–48 m ;
- petits props regroupés en HLOD à distance ;
- arbres LOD0 environ 0–35 m, LOD1 35–70 m, LOD2 70–140 m, impostor ensuite, puis ajustement par métrique écran ;
- rochers héros conservant leur silhouette plus longtemps ;
- camp, pylône et citadelle avec HLOD artistiques ;
- occlusion culling évalué surtout dans le donjon et les ruines, sans supposer un gain majeur dans une vallée très ouverte ;
- aucune disparition visible dans la caméra North Star.

### 26.6 Lumières et probes

Limiter les vraies lumières dynamiques aux sources qui changent l’image : feu proche, activation pylône, mécanisme, attaque et boss. Éteindre ou réduire par distance et preset. Reflection probes bornées ; lightmaps pour le statique lorsque validées ; ne pas dépasser les budgets clustered par accumulation de petites lumières/VFX.

---

## 27. PROFILS HIGH, MEDIUM ET WEB

| Domaine | High natif | Medium natif | Web Compatibility |
|---|---|---|---|
| Résolution 3D | 0,85–1,0 | 0,75–0,9 | 0,75–0,9 selon cible |
| GI | SDFGI half ou LightmapGI choisi par mesure | LightmapGI/probes | LightmapGI/baked |
| Fog | distance + volumetric borné | distance + volume faible/non | fog classique uniquement |
| Eau | normales, profondeur, reflets mesurés, légère réfraction | sans effet secondaire coûteux | sans screen texture/SSR |
| Herbe | 100 % densité cible | environ 65 % | 35–50 % |
| Ombres | héros/menaces + environnement proche | distance réduite | très réduites ou baked |
| VFX | complet borné | particules/lumières réduites | meshes/particles simples, sans compute/decals |
| LOD/HLOD | transitions qualité | plus agressif | plus agressif + impostors |
| Atmosphère | nuage multicouche + fog volumes | couches réduites | cartes simples |
| Post | tonemap, debanding, SSAO/SSIL mesurés | sans SSIL si coûteux | aucun effet non supporté |

Web n’utilise pas volumetric fog, SDFGI, SSIL, SSR, TAA, FSR2, decals ou compute. Il doit préserver composition, palette, silhouettes et causalité même si la densité et les effets diminuent.

### 27.1 Budget frame

À 60 FPS, la frame totale reste ≤ 16,67 ms sur le matériel recommandé. Mesurer séparément CPU/GPU, vue North Star, camp, donjon électrique et boss. Précharger shaders/VFX du parcours de démo ; aucun hitch de première utilisation visible.

### 27.2 Stabilité temporelle

Tester en course et rotation caméra :

- shimmer des normales/feuilles ;
- moiré des trims ;
- ghosting des trails/électricité ;
- pop LOD/HLOD ;
- ombres qui changent brutalement ;
- transparence de cheveux/feuillage ;
- fog en bandes ;
- particules traversant la caméra ;
- exposition qui pompe ;
- vibration des contours painterly.

Une belle capture fixe échoue si la vidéo de 10–20 s montre un défaut critique.

---

## 28. MANIFESTE EXHAUSTIF À TENIR

Créer `docs/assets/ASSET_MANIFEST.csv` avec les colonnes :

```text
id,category,display_name,priority,owner_author,source_url,license,source_master,
export_glb,godot_scene,version,dimensions_m,triangle_lod0,triangle_lod1,
triangle_lod2,materials,textures,texel_density,rig,animations,collision,
navigation,lightmap,lod_hlod,states,shader,preset_web,import_status,
visual_status,performance_status,last_capture,last_review_date,notes
```

### 28.1 Inventaire minimal de production

| Domaine | Minimum |
|---|---:|
| Héros | 1 modèle final + Bracelet + équipements/sockets |
| Familles ennemies | 5 modèles réellement distincts |
| Boss | 1 hero asset modulaire, 3 phases |
| Armes | 6 + 2 flèches + états d’usure/rupture |
| Terrain | 10 zones macro, chunks/collisions |
| Falaises/rochers | 44+ formes/modules, dont petits groupes fusionnés |
| Végétation | 35+ variantes contrôlées |
| Eau/berges | 15+ meshes/VFX de base |
| Camp | 35+ modules/props avec variantes |
| Ruines | 20+ modules |
| Pylône | 1 hero asset en sous-modules/états |
| Citadelle extérieure | 15+ grandes masses/modules + HLOD |
| Donjon | 30+ modules d’architecture |
| Graphe électrique | 14 familles de mécanismes/états |
| Coffres | 3 familles |
| Ingrédients | 7 assets monde + icônes |
| Plats | 6 présentations + icônes |
| Props physiques | 30+ variantes |
| VFX | 50+ effets/variantes cohérents, pas nécessairement 50 systèmes uniques |
| UI | thème complet + 70+ icônes/glyphs/états |
| Cinématiques | 7 séquences utilisant les assets gameplay |

Le nombre n’autorise pas le remplissage médiocre. Plusieurs variantes peuvent partager atlas, rig, shader et logique, mais doivent résoudre les répétitions visibles.

---

## 29. ORDRE DE PRODUCTION OBLIGATOIRE

### Passe V0 — Audit sans destruction

1. Inventorier tous les assets actuels, placeholders, matériaux, shaders, textures, licences et scènes.
2. Capturer North Star, camp, entrée donjon, une salle et boss avant modification.
3. Marquer `KEEP`, `REWORK`, `REPLACE`, `MISSING`, `BLOCKED`.
4. Ne pas supprimer un asset utilisé avant remplacement testé.
5. Créer le manifeste et les planches de style.

### Passe V1 — Langage pilote

Produire un rocher héros, une falaise, une touffe longue, une fleur, un arbre, un module de ruine, un morceau d’eau, un matériau héros, un matériau énergie et un éclair. Les réunir dans `StyleLab`/`LightingLab`. Corriger la cohérence avant multiplication.

### Passe V2 — `HeroShotLab` 80 × 80 m

Assembler : héros présentable, pente herbe/fleurs 20–30 m, chemin, eau, camp simplifié mais finalisable, pylône, proxy de citadelle, falaises d’encadrement, ciel, nuage et éclair. Ajouter vent et caméra exacts.

Gate intermédiaire ≥ 75/100. Remplacer les proxies critiques, puis Gate ≥ 85/100 avant propagation.

### Passe V3 — Héros et déplacement

Finaliser silhouette, costume, Bracelet, équipements, locomotion, saut, mantle, escalade, Arc Step, IK, secondary motion et caméra sur le parcours de démo.

### Passe V4 — Vallée

Propager la recette par chunks ; construire trois routes et 8–10 POI ; finaliser camp, pylône, eau, roches, végétation et citadelle HLOD. Recomposer manuellement les focales.

### Passe V5 — Gameplay props et UI

Armes, coffres, ingrédients, cuisine, réactifs, états, icônes, HUD et menus. Vérifier que chaque affordance se lit sans halo permanent.

### Passe V6 — Ennemis

Finaliser une famille pilote, valider shader, rig, LOD et animation, puis les quatre autres. Tester les silhouettes en camp et dans `CombatLab` avant le détail secondaire.

### Passe V7 — Donjon

Kit modulaire, matériaux, éclairage, mécanismes, quatre salles, salle centrale, antichambre et porte. Chaque activation change architecture, lumière et VFX.

### Passe V8 — Boss

Boss modulaire, arène, trois phases, dégâts visuels, VFX, caméra, intro et mort. Profiler chaque phase isolée puis les combinaisons.

### Passe V9 — Polish et optimisation

Cinématiques, transitions, VFX/audio synchronisés, LOD/HLOD, culling, presets, Web, UI scale, accessibilité, suppression des placeholders, captures et vidéo.

---

## 30. LABORATOIRES ET VALIDATION VISUELLE

| Scène | Contenu et preuve |
|---|---|
| `ScaleLab` | grille, silhouettes, dimensions, caméras |
| `StyleLab` | peau, tissu, cuir, métal, céramique, pierre, bois, feuillage, énergie |
| `HeroShotLab` | North Star complète 80 × 80 m |
| `LightingLab` | extérieur/donjon/boss, Filmic vs ACES, fog/GI |
| `FoliageLab` | densité, vent, interaction, overdraw, LOD |
| `WaterLab` | profondeur, rive, mousse, charge, fallback |
| `AnimationLab` | locomotion, pivots, pentes, armes, IK, Bracelet |
| `VFXLab` | chaque effet seul, pile maximale, accessibilité |
| `CombatLab` | silhouettes, télégraphes, impacts, caméra |
| `PerformanceLab` | coûts isolés et presets |

### 30.1 Protocole d’image

À chaque passe majeure, capturer la même caméra, seed, heure, exposition, résolution et preset :

1. vignette 320 × 180 ;
2. niveaux de gris ;
3. flou léger ;
4. silhouettes/edges ;
5. plein écran 1440p ;
6. vidéo 10–20 s avec marche, sprint et rotation caméra ;
7. preset Medium ;
8. Web si le jalon est concerné.

### 30.2 Score North Star /100

| Domaine | Points | Échec typique |
|---|---:|---|
| Composition/trajectoire du regard | 20 | focales fusionnées, regard sans chemin |
| Profondeur/échelle | 15 | trois plans absents, citadelle plate |
| Lumière/chaud-froid | 15 | midi plat, ombres bouchées, bloom |
| Héros/silhouette | 10 | générique, perdu dans le fond |
| Matériaux/cohérence | 10 | packs réalistes et toon mélangés |
| Terrain/végétation | 10 | scatter uniforme, répétition, shimmer |
| Camp/pylône/citadelle/orage | 10 | landmark illisible ou cyan partout |
| Mouvement/stabilité/performance | 10 | LOD pop, ghosting, hors budget |

Gate : ≥ 85/100, aucun domaine à zéro et aucune violation d’originalité ou de licence.

### 30.3 Tests de silhouette

- héros à 3, 10 et 25 m ;
- cinq ennemis à 10, 25 et 50 m ;
- boss à 15, 25 et 40 m ;
- six armes équipées ;
- source, conducteur, isolant, récepteur, danger et terre ;
- camp, pylône et citadelle en vignette.

Noircir les sujets, retirer UI et VFX. Le test doit rester compréhensible.

### 30.4 Test d’affordance

Sans explication orale, demander à un testeur :

- où descendre ;
- quel objectif est proche, moyen et lointain ;
- quelle surface se grimpe ;
- quel objet conduit ou isole ;
- quel port est compatible ;
- quelle attaque arrive ;
- où se trouve la zone sûre ;
- quel ingrédient prépare au danger ;
- quel état d’arme est critique.

Corriger d’abord forme, mouvement et placement, puis couleur et UI.

---

## 31. CHECKLIST « NE RIEN OUBLIER »

### Monde

- [ ] terrain macro intentionnel ;
- [ ] spawn/crête, camp, rivière, falaise, forêt, pylône, ruines et entrée ;
- [ ] trois hauteurs et trois routes ;
- [ ] limites naturelles ;
- [ ] chemins, raccourcis et regards de retour ;
- [ ] fond montagneux ;
- [ ] sol, roches, falaises, talus et éboulis ;
- [ ] herbes, fleurs, buissons, arbres, roseaux et racines ;
- [ ] eau, rives, mousse et humidité ;
- [ ] ciel, soleil, nuages, orage, éclairs et fog ;
- [ ] 8–10 POI ;
- [ ] camp complet, pylône et citadelle ;
- [ ] densité et respirations ;
- [ ] LOD, HLOD, culling, collisions et navigation.

### Personnages

- [ ] héros original, visage, cheveux, costume et Bracelet ;
- [ ] rig, skin, sockets, LOD, matériaux et états ;
- [ ] locomotion, traversal, 6 armes, arc, défense, Résonance, interactions et réactions ;
- [ ] pillard braise, pillard azur, briseur, colosse et chasseur ;
- [ ] silhouettes, équipements, télégraphes, animations, états et loot ;
- [ ] boss, cristaux, armures, noyau, câbles, trois phases, dégâts et mort.

### Objets et systèmes

- [ ] 6 armes, flèches, usure et rupture ;
- [ ] 3 familles de coffres ;
- [ ] 7 ingrédients et 6 plats ;
- [ ] stations cuisine vallée/donjon ;
- [ ] caisses, blocs, sphères, planches, rochers, jarres, ponts et ancrages ;
- [ ] `Wet`, `Charged`, `Grounded`, `Overloaded`, `Burning`, `Fractured` ;
- [ ] source, câble, port, switch, conducteur, relais, receiver, porte, hazard, batterie, eau, terre, isolant et reset ;
- [ ] Salle 1, Salle 2, Salle 3, Salle 4, centrale, antichambre et arène ;
- [ ] reset/respawn visuels des objets essentiels.

### Présentation

- [ ] shaders maîtres et fallbacks ;
- [ ] lumière extérieur, donjon et boss ;
- [ ] color grading et exposition ;
- [ ] VFX environnement, Résonance, électricité, combat, feu, loot et boss ;
- [ ] HUD, menus, icônes, glyphs, carte et fonts ;
- [ ] modes daltonisme, flash, bloom, shake et VFX réglables ;
- [ ] 7 cinématiques/moments wahou ;
- [ ] parcours démo 3 minutes ;
- [ ] captures déterministes et vidéos ;
- [ ] manifeste, sources, licences, imports, budgets et preuves.

---

## 32. DÉFINITION FINALE DE « REPRODUIT VISUELLEMENT »

Le résultat est conforme seulement si une capture réelle `VistaCamera_Hero01` montre, en moins de trois secondes :

1. le héros original de dos, parfaitement lisible ;
2. une prairie riche et animée, sans répétition évidente ;
3. une route dans une vallée compréhensible ;
4. le camp, le pylône et la citadelle à trois distances ;
5. le ruban turquoise de la rivière ;
6. la lumière dorée à gauche et les ombres froides ;
7. l’orage local et un éclair cyan à cœur blanc ;
8. des matériaux appartenant au même monde ;
9. une image stable en mouvement et dans le budget ;
10. aucun asset copié, manquant, provisoire ou trompeur sur le chemin critique.

La réussite n’est pas la ressemblance d’un objet isolé. C’est la reproduction de la **même émotion structurée** : sécurité proche, curiosité moyenne, menace lointaine, envie immédiate de descendre et certitude qu’un monde cohérent relie la nature, le camp, la Résonance et la tempête.

---

## 33. RÉFÉRENCES TECHNIQUES OFFICIELLES GODOT 4.7 À VÉRIFIER AU MOMENT DE L’IMPLÉMENTATION

- Import de scènes 3D et glTF : <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/index.html>
- Réglages avancés d’import : <https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_3d_scenes/advanced_import_settings.html>
- Mesh LOD automatique : <https://docs.godotengine.org/en/4.7/tutorials/3d/mesh_lod.html>
- Visibility ranges/HLOD : <https://docs.godotengine.org/en/4.7/tutorials/3d/visibility_ranges.html>
- `MultiMeshInstance3D` : <https://docs.godotengine.org/en/4.7/classes/class_multimeshinstance3d.html>
- Langage de shaders et paramètres par instance : <https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/shading_language.html>
- Fog volumétrique et `FogVolume` : <https://docs.godotengine.org/en/4.7/tutorials/3d/volumetric_fog.html>
- Renderers Forward+, Mobile et Compatibility : <https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html>
- Environnement et tonemapping : <https://docs.godotengine.org/en/4.7/classes/class_environment.html>
- Resolution scaling : <https://docs.godotengine.org/en/4.7/tutorials/3d/resolution_scaling.html>
- `Camera3D`, FOV et `keep_aspect` : <https://docs.godotengine.org/en/4.7/classes/class_camera3d.html>

Toujours confirmer la version réellement installée et construire un test minimal avant de figer une option de rendu ou d’import.

---

## INSTRUCTION FINALE À CLAUDE CODE

Commence par auditer ce qui existe et produire une matrice `KEEP / REWORK / REPLACE / MISSING / BLOCKED`. Préserve le projet jouable et les changements de l’utilisateur. Ne produis pas cinquante assets génériques en parallèle. Établis d’abord le langage visuel avec quelques assets pilotes, construis `HeroShotLab`, mesure et itère jusqu’au gate. Ensuite seulement, propage la recette à la vallée, au donjon et au boss.

À chaque asset : concept → échelle → source → export → import → matériau → LOD → collision/rig → scène preview → intégration → capture/vidéo → profil → manifeste. À chaque jalon : preuve réelle dans Godot. Si la qualité artistique requise dépasse les outils ou assets légalement disponibles, réduis le nombre de variantes visibles et signale précisément le blocage ; ne remplace jamais la vérité par une fausse capture ou le mot « final ».

## FIN DU PROMPT 3
