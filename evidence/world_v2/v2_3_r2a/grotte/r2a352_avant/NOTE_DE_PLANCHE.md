# Note de planche — R2a-3.5.2, preuve visuelle de la grotte

Texte destiné à accompagner les images. Il porte ce que les images ne disent
pas d'elles-mêmes. À recopier dans le `LISEZMOI.md` du dossier de preuves.

---

## Ce que chaque vue montre, et ce qu'elle ne montre pas

| vue | ce qu'elle montre | à ne pas y chercher |
|---|---|---|
| `02_approche_joueur` | le porche vu de l'extérieur à l'échelle du joueur, massif et sol compris | — |
| `03_gros_plan_seuil` — **« gorge du porche »** | la caméra est **dans la gorge** et regarde la galerie | **pas** le seuil vu de dehors. Le seuil extérieur est servi par `08` |
| `04_interieur_sortie` | l'intérieur vers la sortie | — |
| `08_visiere_face` | la masse rocheuse **au-dessus** de la bouche, sur l'axe du porche | — |
| `09_visiere_profil` | trois-quarts à l'azimut 100 : la **profondeur** du surplomb | pas un profil pur — un profil à 90° rase la face et le flanc masque le porche |
| `10_visiere_dessous` | la **sous-face** du surplomb, seule vue qui regarde dessous | — |
| `11_orteil_pied` | **cadre le pied `+x`, pas le porche.** C'est là que le lot collerette a créé puis comblé une poche de 0,24 m | une composition du porche |
| silhouettes 55 / 100 / 225 | les trois masses, forme seule | — |

`03` et `08` sont **complémentaires, pas redondantes** : l'une est dans la
gorge, l'autre montre la façade. L'identifiant de `03` est conservé tel quel —
il est verbatim du manifeste committé, et le renommer casserait la
comparabilité avec la référence.

---

## Les trois chiffres que l'image ne dit pas

`tools/godot/capture_silhouette.gd` cadre sa caméra orthogonale sur **l'AABB du
sujet**. Les deux géométries de l'A/B n'ont pas la même : la caméra n'est donc
pas identique des deux côtés, et **rien dans l'image ne le crie**.

| | valeur | part du cadre |
|---|---:|---:|
| échelle — le sujet APRÈS paraît | **+4,28 %** | — |
| décentrement horizontal | **0,642 m** | **2,26 %** |
| décentrement vertical | **−0,726 m** | **1,92 %** |

**Ce n'est pas le sujet qui change de taille, c'est la caméra.**

Emprises, `--clip-below=3.00` :

| | emprise (m) | `camera.size` |
|---|---|---:|
| AVANT `8bf1a1b3` | 23,652 × 10,143 × 23,652 | 37,843 m |
| APRÈS `cc3596c5` | 22,680 × 8,692 × 22,680 | 36,288 m |

Fait établi au passage : **l'AABB montée est entièrement déterminée par la boîte
du GLB** — les props du lieu ne l'étendent pas. Démontré en reproduisant
l'emprise mesurée à **2 mm** depuis la seule bbox glTF tournée de 45°.

---

## Format des silhouettes — différent des planches `r2a351`

**1200×900 paysage**, là où `r2a351` était en 900×1200 portrait. Trois raisons :

1. le seul A/B qui compte est interne à cette passe, les deux côtés au même
   format. Les planches `r2a351` ne peuvent pas servir de côté AVANT :
   `repo_dirty: true` **et** géométrie de diagnostic ;
2. la question posée est **Q4, « les trois masses restent-elles distinctes »** —
   un jugement d'œil. Mesuré en portrait : le sujet n'occupe que **16 % de
   l'image**, parce que la largeur (23,65 m) commande le cadrage devant la
   hauteur (10,14 m). En paysage : **~48 % de la hauteur** ;
3. le décalage d'échelle est **inchangé** — +4,31 % en paysage contre +4,28 %
   en portrait. La mesure ne bouge pas, seule la lisibilité gagne.

---

## Le confondant d'éclairage, et sa décomposition

Entre les deux côtés, **la géométrie n'est pas la seule chose qui change** :
les deux sources de la grotte se déplacent.

```
seuil.position (0.20, 1.50, −2.60) → (0.15, 1.50, −1.20)   JourDuSeuil, portée 5,5 m, ombres
salle.position (0.20, 1.90, −7.20) → (2.70, 1.90, −3.35)   CielReplie,  portée 6,5 m, ombres
```

`JourDuSeuil` se rapproche de la bouche de **1,40 m** : son halo passait de
`z = +2,9` à `z = +4,3`, soit **4,3 m à l'extérieur de la bouche**. Elle éclaire
la sous-face du surplomb depuis l'intérieur, différemment des deux côtés — et
c'est exactement la zone de `10`.

D'où le **triptyque** :

| plan | géométrie | lampes | statut |
|---|---|---|---|
| **A** | R2a-3.4 `8bf1a1b3` | anciennes | **preuve** |
| **B** | R2a-3.4 `8bf1a1b3` | **nouvelles** | **DIAGNOSTIC — arbre sale, non probant comme livrable** |
| **C** | `cc3596c5` | nouvelles | **preuve** |

A → B isole l'éclairage. B → C isole la géométrie.

**Les silhouettes sont immunisées** : `capture_silhouette.gd` remplace tous les
matériaux par un unshaded, neutralise les `WorldEnvironment` et n'ajoute aucune
lumière. **Q4 n'est pas touchée par le confondant.**

---

## Limites d'instrument à porter avec les images

1. **Aucun outil du dépôt ne mesure les basses lumières.**
   `check_capture_exposure.gd` ne voit que l'écrêtage **haut** et la
   fluorescence. Mesuré sur ces plates : **0,00 %** de pixels ≤ 24/255 — rien
   n'est écrasé. Le défaut réel est une **compression de contraste**, `10`
   vivant entre 32 et 84, soit 20 % de la dynamique. Les planches `lecture/`
   relèvent le gamma pour lire dedans ; ce sont des **dérivées documentées, pas
   des captures**, et jamais un rendu du moteur à cette exposition.
2. **`capture_silhouette.gd` n'a pas de garde-fou de fraîcheur d'import**,
   contrairement à `capture_poi_batch.gd`. Un `--import` le précède
   systématiquement, dans le même verrou. Ce n'est pas une précaution
   théorique : le garde-fou de l'autre outil a bloqué en 3 sur trois prototypes
   d'enveloppe non importés.
3. **Rendu logiciel Mesa llvmpipe sous Xvfb, sans GPU.** Aucune mesure de
   performance ne peut sortir de ces images.
4. Le verdict artistique appartient au lead. Rien ici ne le rend, et rien ici
   ne le remplace.
