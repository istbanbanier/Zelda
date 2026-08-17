# Côté AVANT — R2a-3.4, la baseline rejetée. **LE CÔTÉ APRÈS MANQUE.**

**Cette planche est incomplète, et ce n'est pas un oubli.** La passe R2a-3.5.2
s'est arrêtée en `PARTIAL` avant l'intégration : le candidat n'a jamais été versé
au tronc, donc jamais rendu. Il n'y a **qu'un seul côté**.

**Pourquoi elle s'est arrêtée**, puisque la reprise lira ce dossier avant
l'historique : le toit du massif tombe à **0,038 m** au-dessus d'un vide de 1,4 m
en `(0,50 ; 5,80)`, pour un contrat de **0,80 m**. La cause n'est pas la
géométrie seule — c'est que `controle_epaisseur` ne balaie que les stations de
`CAVITE`, dont **la dernière est à `ay 3,17`**, alors que le défaut vit à
`ay ≈ 5,8`. **Hors domaine.** Le contrôle publiait 0,87 m et passait. Détail et
cartographie : `../r2a352_toit_mince/`.

Ne lisez rien ici comme un verdict, ni comme une comparaison. C'est une
**baseline conservée pour la reprise** — la seule fenêtre où la géométrie R2a-3.4
était encore joignable depuis un arbre committé et propre.

## Provenance

| | |
|---|---|
| commit du code | `1152c92` |
| `repo_dirty` | **`false`** |
| scène | `res://scenes/world_v2/WorldV2.tscn` |
| géométrie | GLB `8bf1a1b309aee79f…`, dernier commit du chemin **`504ecbe`** |
| lieu / monde | `1fb57d3` / `131b74d` |
| exposition | FILMIC, `tonemap_exposure` 1.0, auto **désactivée** |
| convention de FOV | `KEEP_HEIGHT` — le champ `fov` est **vertical** ; l'équivalent horizontal 16:9 est inscrit à côté, jamais dans le champ |
| rendu | llvmpipe, **logiciel** — aucun chiffre de performance ne sort d'ici |

La provenance de la géométrie a été **re-dérivée par l'outil de manifeste**, sans
qu'on la lui donne : quatrième confirmation indépendante de la baseline.

**Le lot est capturé à `1152c92` et versé plus tard — sans effet, et c'est
mesuré**, pas supposé :

```
git diff --name-only 1152c92..HEAD | grep -vE '^(docs/|evidence/)'   →  vide
```

81 fichiers ont changé sur la plage, **les 81 sous `docs/` ou `evidence/`**. Rien
de ce qui est *rendu* n'a bougé : recapturer n'aurait changé qu'une chaîne de
caractères pour des pixels identiques. Sans cette ligne, la prochaine session
verrait deux SHA différents et douterait des images.

## Contenu

- **7 perspectives** 1280×720 : approche · gorge du porche · intérieur/sortie ·
  visière de face · visière de profil · visière par-dessous · orteil et pied ;
- **3 silhouettes** 1200×900, `clip_below 3.0`, filet bimodal **0,000 % hors
  bandes** aux trois azimuts ;
- vignettes et niveaux de gris ;
- une **planche de lecture** gamma 2,2 de la vue par-dessous, dans `lecture/` —
  **dérivée, jamais une capture** ;
- `diagnostic_plan_b/` — voir ci-dessous, **arbre sale par construction** ;
- `NOTE_DE_PLANCHE.md` : libellés, limites d'instrument, justification du format ;
- `TRIPTYQUE_mesures_du_confondant.md`.

## LE RÉSULTAT LE PLUS IMPORTANT DE CE LOT

**Les deux lampes intérieures se déplacent entre les deux côtés.** Un A/B naïf
aurait donc comparé **géométrie + éclairage** et attribué à la roche ce qui
appartient à une lampe. Le plan B isole la variable : **même GLB, aux octets
près, seules les deux lignes de position de lampe changent.**

Part des pixels changés **par l'éclairage seul** :

| vue | pixels changés | écart max |
|---|---:|---:|
| `04_interieur_sortie` | **83,97 %** | 152/255 |
| `03_gros_plan_seuil` | **61,20 %** | 84/255 |
| `11_orteil_pied` | 26,33 % | 121/255 |
| `10_visiere_dessous` | **14,77 %** | 98/255 |
| `08_visiere_face` | 8,41 % | 85/255 |
| `02_approche_joueur` | 5,78 % | 90/255 |
| `09_visiere_profil` | **1,25 %** | 164/255 |

**Les deux vues intérieures sont dominées par l'éclairage.** Publiées comme un
A/B « de géométrie », elles auraient été **fausses**. Le triptyque n'était pas une
précaution ; c'est ce qui empêche deux planches d'être mensongères.

La vue par-dessous change de **14,77 %** : bien assez pour qu'une ombre lue comme
un défaut de surplomb ne soit qu'une lampe déplacée. **Elle n'est répondable que
par B→C.**

Et `09_visiere_profil` est **quasi immune, 1,25 %** — le trois-quarts à l'azimut
100 répond donc presque proprement à « roche ou arche ». Trouvé après coup, pas
recherché.

### Règle de lecture, à porter sur toute planche future

> **A→B = l'éclairage seul · B→C = la géométrie seule.**
> **A→C ne doit jamais être présenté seul sur `03`, `04`, `10`.**

Les silhouettes sont **totalement immunes** (unshaded, sans lumière) : la
composition aux trois azimuts se compare directement.

## Deux chiffres à porter sur la planche du jour où le côté APRÈS existera

L'outil de silhouette cadre sur l'AABB **du sujet**, et les deux géométries n'ont
pas la même. L'A/B n'est donc **pas à échelle constante** :

- **échelle : le sujet APRÈS paraîtra +4,28 % dans le cadre** ;
- **centre décalé de 0,642 m horizontal (2,26 % du cadre) et −0,726 m vertical
  (1,92 %)**.

Rien dans l'image ne le dit. Emprise AVANT **mesurée** `23,652 × 10,143 × 23,652`
(modèle de cadrage validé à **2 mm** contre la mesure) ; emprise APRÈS
**calculée**, à confirmer au rendu.

## `diagnostic_plan_b/` — sale par construction, non probant

Géométrie R2a-3.4, **lampes du candidat**. Worktree jetable, patch de deux lignes
vérifié au diff (1 fichier, 2 insertions / 2 suppressions), `repo_dirty: true`,
worktree retiré après usage. Il n'existe que pour produire le tableau ci-dessus.
**Ne jamais le citer comme preuve de livraison.**

## Limites d'instrument, inscrites

- `capture_silhouette.gd` n'a **aucun garde-fou de fraîcheur d'import** —
  contrairement à `capture_poi_batch.gd`, dont le garde-fou a réellement mordu
  (BLOQUÉ 3 sur trois protos d'enveloppe) ;
- `check_capture_exposure.gd` ne mesure que l'**écrêtage haut** et la
  fluorescence. Aucun outil du dépôt ne mesure la **compression de contraste** ni
  les basses lumières — or la vue par-dessous vit entre p1 = 32 et p99 = 84, soit
  20 % de la dynamique ;
- le format est **1200×900 paysage**, différent des planches `r2a351` : le sujet
  passe de 16,0 % à 28,4 % de l'image, et le décalage d'échelle mesuré est
  inchangé (+4,31 % contre +4,28 %). Justifié dans `NOTE_DE_PLANCHE.md` ;
- rendu **logiciel** : régression visuelle uniquement, jamais une mesure.

## Ce qui reste NON VÉRIFIÉ

Tout le côté APRÈS. Le plan C. Et **le verdict visuel**, qui n'appartient à aucun
instrument.
