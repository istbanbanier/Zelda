# Les contrôles du gate peuvent-ils échouer ? — audit de vacuité

Motif : **ISS-052** a montré qu'un contrôle du gate — les appuis de
`world_v2_places` — **compare la hauteur du terrain à elle-même** et ne peut donc
pas échouer. Ayant trouvé un contrôle vide, il faut regarder les autres du même
gate plutôt que supposer qu'il était seul. C'est l'anti-motif nommé au
`PROMPT4_METHOD` §2 : « toute assertion qui ne rougirait pas réellement en cas de
régression ».

Lecture de code uniquement, **aucune exécution**. Statut : `FAIT REPRODUIT` pour
les lectures, `NON VÉRIFIÉ` pour tout ce qui demanderait de lancer les contrôles.

## `controle_aller_retour` — SOUND, et exemplaire

`tools/probe_cave_openings.py::Pose.controle_aller_retour`.

Cinq propriétés le rendent falsifiable, et elles sont **écrites dans le code avec
leur raison** :

1. **deux chemins indépendants** — `vers_monde()` par chaîne de matrices,
   `vers_modele()` en forme fermée. La docstring interdit explicitement d'écrire
   l'un en appelant l'autre : « l'aller-retour deviendrait un test qui ne peut pas
   échouer (`docs/PROMPT4_METHOD.md` §2) » ;
2. **les points d'épreuve couvrent les huit coins d'une boîte de 20 m** plus des
   points hors axe — « un aller-retour éprouvé seulement sur l'origine passerait
   quelle que soit la rotation » ;
3. **les directions sont éprouvées séparément** — « un lacet correct sur les
   points mais inversé sur les directions ferait viser à côté sans que
   l'aller-retour des points s'en aperçoive » ;
4. **la tolérance est un plancher de bruit, pas un budget** : 1e-9 m est ~5 ordres
   au-dessus du bruit flottant et ~8 ordres sous toute faute réelle de
   transformation. « Ce n'est pas un réglage à ajuster si un jour le test
   rougit » ;
5. **l'origine n'est pas une option de ligne de commande** — pratique rejetée :
   « une valeur en ligne de commande n'est pas une mesure ». Et la tentative de la
   valider par superposition de silhouette a été **disqualifiée par son auteur** :
   52,4 % de concordance, et décaler l'origine de +3 m *améliorait* le score.

**Détail mineur** : la liste de points d'épreuve contient encore
`(1.05, 6.25, 0.22)`, c'est-à-dire l'**ancien** `MODELE_SALLE`, qui pointe
aujourd'hui dans la roche. Sans effet — un aller-retour est valide sur n'importe
quel point — mais c'est une référence périmée qui gagnerait à être nommée telle.

## `controle_gabarit` — SOUND, et il porte sa propre autopsie

`make_waterfall_cave.py::controle_gabarit`. Sa docstring décrit **exactement la
maladie qu'on traque**, sur lui-même :

> « CE CONTRÔLE ÉTAIT DEVENU FAUX, ET IL L'AURAIT DIT VERT. Il mesurait
> `hw * (1 - AMP_INTERIEUR)`, c'est-à-dire une DEMI-LARGEUR SYMÉTRIQUE, en
> ignorant `CAVITE_ASYM`. […] le contrôle annonçait 2,74 m de demi-largeur à la
> station 5 quand le côté mince n'en offre que 0,99. **Un contrôle qui ne voit
> pas l'asymétrie qu'on vient d'introduire est pire qu'inutile : il donne un vert
> qui interdit de chercher.** »

Réparé : il mesure la **bande utile** — la largeur contiguë où la hauteur libre
tient le contrat — et ne suppose rien sur la position de l'axe dans la section.

**Non-rétroactivité vérifiée par son auteur** : le maillage d'avant la passe passe
le nouveau contrôle (bande 2,60 à 4,55 m). Ce n'est donc pas un durcissement
rétroactif, « c'est la même exigence enfin mesurée là où elle vit ».

Il peut échouer : `bande_utile(i) < 2 × 0,95` remplit `faibles`.

**Exclusion des deux dernières stations** — `if i >= len(CAVITE) - 2: continue` —
justifiée : elles ferment la calotte, et la classification de la Phase II établit
que l'intervalle jouable s'arrête à `u = 6,205`. Ce n'est **pas** une station
écartée pour obtenir un PASS, ce que la directive interdit ; c'est une station
hors du chemin praticable mesuré.

## Bilan

| contrôle du gate | peut-il échouer ? |
|---|---|
| aller-retour monde↔modèle | **oui**, deux chemins indépendants |
| gabarit joueur | **oui**, et il a déjà été réparé pour ça |
| trois masses / ratio / plage plane | **oui** — reproduits, valeurs sous seuil possibles |
| plancher, oracle en colonnes | **oui** — sabotage rouge démontré |
| percées, raster | durcissement **non terminé** (lot instruments non intégré) |
| collerette | calibration **non terminée** (idem) |
| **appuis `world_v2_places`** | **NON — ISS-052** |

Un seul contrôle vide trouvé sur ceux inspectés. Les deux lus en détail sont non
seulement sains mais **portent l'histoire de leur propre réparation**, ce qui est
le meilleur signe qu'un contrôle ait jamais été pris au sérieux.

## Ce que cet audit ne dit pas

Il ne dit **rien** du défaut qui a arrêté la passe. Un contrôle peut être
parfaitement falsifiable **et** aveugle : `controle_epaisseur` est de ceux-là — il
peut rougir, il l'a fait, mais son domaine s'arrête à `ay 3,17` et le défaut vit à
`ay 5,8`. **Vacuité et domaine sont deux maladies distinctes.** Cet audit ne
traite que la première ; la seconde a coûté la passe, et reste ouverte.
