# ART BIBLE — Éclats d'Orage

État : **squelette de Phase 0**. Les sections marquées `À REMPLIR` attendent des
captures réelles du moteur (§7.2) et ne doivent pas être remplies d'intentions.
Aucune image de ce document ne peut provenir d'ailleurs que du renderer (§7.14).

---

## 1. North Star — lecture de l'image de référence

L'image de référence a été fournie et **analysée directement**. Elle sert de
référence de cadrage, d'échelle, de hiérarchie des plans, de palette, de lumière et
de densité — **jamais d'asset**. Interdiction absolue de l'employer comme skybox,
matte painting, billboard ou texture de décor (§0.2).

> ⚠️ Le fichier binaire n'est pas encore dans le dépôt (voir KNOWN_ISSUES ISS-003).
> À déposer en `source_assets/concepts/NORTHSTAR_reference.png` pour rendre les
> comparaisons avant/après de §7.16 reproductibles entre sessions.

### 1.1 Relations observées, confrontées à §3.2

Ce qui compte est la **relation** entre les éléments, pas une copie pixel.

| Élément | Observé dans la référence | §3.2 attend | Verdict |
|---|---|---|---|
| Héros | de dos, tiers inférieur, légèrement à gauche du centre (~0,42 en X), ~40 % de la hauteur | tiers inférieur, gauche du centre, 32-40 % | conforme |
| Pente d'herbe/fleurs | occupe les ~28 % inférieurs, fleurs blanches, jaunes et bleues | 22-30 % inférieurs | conforme |
| Camp | milieu droit, feu allumé, 3-4 silhouettes debout autour | milieu droit, 70-110 m | conforme |
| Pylône | tiers droit, tour ouvragée à anneaux cyan, sommet haut dans le cadre | tiers droit, 140-190 m | conforme |
| Eau | rubans turquoise à gauche et à droite du plan moyen, convergeant vers le centre | rivière/lac guidant vers le centre | conforme |
| Citadelle | centre, très lointaine, masses de pierre étagées | centre, 300-420 m | conforme |
| Falaises | encadrent nettement les deux bords | encadrement latéral | conforme |
| Nuage d'orage | **local**, sombre, uniquement au-dessus de la citadelle ; ciel clair ailleurs | nuage local au-dessus de la citadelle | conforme |
| Éclairs | verticaux, cyan à cœur clair, du nuage vers le monument | éclairs cyan nuage → monument | conforme |
| Soleil | chaud, hors champ en haut à gauche, halo diffus | hors champ haut gauche | conforme |
| Étagement | premier plan chaud et contrasté → fond bleu pâle désaturé | idem | conforme |

**Élément supplémentaire non listé par §3.2** : une structure de bois sombre en
premier plan droit, qui ferme le cadre de ce côté. À conserver comme motif de
premier plan — c'est elle qui empêche le regard de fuir vers la droite.

### 1.2 Trajectoire du regard à reproduire

Héros (bas gauche) → chemin et herbe → camp et feu (milieu droit) → eau qui ramène
au centre → citadelle et éclairs (centre lointain), le pylône servant d'ancre
verticale à droite. **Trois plans nettement séparés** par la brume, pas un dégradé
continu.

### 1.3 Écarts assumés entre référence et moteur

- La référence est une **illustration**, avec une diffusion painterly et une brume
  que Godot devra obtenir par fog volumétrique court + fog de distance, sans coupure
  visible entre les deux (§7.7).
- Le cyan pur (éclairs, noyaux du pylône) reste **rare** en surface d'écran, comme
  l'exige §3.4 ; l'eau turquoise appartient à la bande « ciel/brume/eau » des 30 %,
  pas aux accents saturés des « moins de 10 % ».
- Godot **n'a pas** les nuages volumétriques d'Unreal : le nuage d'orage sera obtenu
  par couches de dômes/meshes, raymarch réservé au preset Cinematic si mesuré (§7.6).

---

## 2. Palette ancre

| Usage | Hex | Note d'emploi |
|---|---|---|
| Soleil | `#FFD68A` | lumière directionnelle, hautes lumières chaudes |
| Ciel pastel | `#A9D4EA` | dominante de fond |
| Brume | `#AFC8D3` | sépare les trois plans |
| Herbe moyenne | `#5D8F3D` | masse principale |
| Herbe éclairée | `#B2C85A` | crêtes exposées, jamais uniforme |
| Roche ocre | `#9B6842` | falaises, rochers |
| Ombre froide | `#4C5B75` | ombres bleutées, jamais noires |
| Bois/cuir | `#684028` | équipement, camp |
| Tissu turquoise | `#168F9B` | héros — relie visuellement le héros à la citadelle |
| Électricité | `#22D9EC` | halo, rare |
| Cœur électrique | `#ECFFFF` | cœur blanc fin des éclairs et arcs |
| UI or pâle | `#D8B36A` | traits d'interface |

**Ratio visé** : 60 % verts/ocres · 30 % ciel/brume/eau · < 10 % accents très saturés.
Le cyan est un événement, pas un décor.

---

## 3. Règles de forme

- Silhouettes fortes lisibles en aplat noir à trois distances.
- Proportions semi-réalistes héroïques, arêtes sculptées, plans colorés larges.
- PBR modéré : deux ou trois grandes zones d'ombre, rim light discret.
- **Interdits** : gros contours noirs, matériaux gris génériques, rendu plastique,
  normal maps agressives, textures photographiques brutes, bloom brûlé, saturation
  uniforme, feuillage opaque, lumière plate de midi, DOF en gameplay.
- Le turquoise du héros est réservé au héros et à l'énergie de la citadelle : il ne
  doit pas se disperser dans le décor, sous peine de perdre le lien visuel.

---

## 4. Hiérarchie d'investissement artistique

Héros et animations → vue d'ouverture et herbe proche → citadelle/pylône/orage →
camp et feu → entrée du donjon et circuits → boss et arène → routes secondaires →
fonds. *Un rocher à 300 m ne reçoit pas le budget d'un coffre à 1 m.*

---

## 5. Budgets (rappel §7.10)

| Asset | Triangles LOD0 | Texture max |
|---|---:|---:|
| Héros | 40k-70k | 2K (4K si justifié) |
| Boss | 100k-160k | 4K |
| Centaure | 55k-90k | 2K |
| Ennemi standard | 22k-45k | 2K |
| Grand arbre | 8k-18k | atlas 2K |
| Gros rocher | 3k-12k | atlas 2K |
| Prop | 0,5k-5k | 512-1K |

LOD1 ≈ 50-60 %, LOD2 ≈ 20-30 %, transitions invisibles dans la bande 30-80 m.

---

## 6. Protocole de revue visuelle (§7.16)

Même caméra, même seed, même heure, même exposition, même résolution, même preset.
Cinq lectures obligatoires plus une vidéo :

1. vignette 320 × 180 — hiérarchie immédiate ;
2. niveaux de gris — valeurs et focales ;
3. image floutée — grandes masses ;
4. silhouettes/edges — lisibilité et bruit ;
5. plein écran 1440p — matériaux, répétitions, défauts ;
6. séquence 5-10 s en mouvement — shimmer, LOD pop, ghosting, vent, stabilité.

Modifier **une famille de variables à la fois** et conserver l'avant/après.

## 7. WOW Gate

| Domaine | Points |
|---|---:|
| Composition des masses | 25 |
| Lumière et chaud/froid | 20 |
| Profondeur/échelle | 15 |
| Végétation | 15 |
| Matériaux painterly | 10 |
| Lisibilité héros/camp/pylône/citadelle | 10 |
| Nuage/éclairs/énergie | 5 |

Validation à partir de **85/100**, aucun domaine à zéro. `HeroShotLab` doit atteindre
**75/100** avant d'agrandir la vallée.

**Score actuel : NON MESURÉ.** Aucune capture n'a pu être produite (ISS-002). Ne
jamais inscrire ici un score estimé.

---

## 8. `À REMPLIR` après les premières captures moteur

- Planches de matériaux (roughness par famille : peau, tissu, métal, pierre, feuillage).
- Densité de végétation selon la distance, avec captures comparatives.
- Épaisseurs de silhouette par faction ennemie.
- Réglages d'émission cyan et synchronisation avec les vraies lumières locales.
- Proportions comparées héros / pillards / colosse / boss sur une même planche.
