# Grotte R2a — vérification d'intégration par le lead

Candidat reçu de l'agent `grotte`, branche `claude/r2a-grotte`, partie de
`d327e5e`. Fusionné en `--no-ff`. Ce document porte ce que **j'ai vérifié
moi-même après la fusion**.

## Propriété des fichiers — RESPECTÉE

23 fichiers, tous dans son périmètre : son générateur, son `.blend`, son
`.glb`, `waterfall_cave_place.gd`, et son dossier de preuves. Aucun fichier
réservé au lead.

## Après fusion, dans MON arbre

| contrôle | résultat |
|---|---|
| `godot --headless --import` | RC 0, **0 erreur** |
| `gltf_inspect` | **VALIDE** — 2 maillages, 3 192 tris, 6 matériaux, 0 texture |
| filets `world_v2_places` | **8 / 8** |
| recapture des 6 plans depuis l'arbre intégré | 6 / 6, rendu conforme |
| `manifest.json` | `commit 1d84923`, `repo_dirty: false` |
| `manifest_silhouettes_grotte.json` | `repo_dirty: false` |

L'avertissement `min Y = −3,175` est **attendu et voulu** : c'est la jupe
enterrée d'une masse plantée. La convention §7.15 vise les objets posés.
L'agent l'a déclaré ; je confirme qu'il ne faut pas le « corriger ».

## Les quatre défauts nommés par le lead

Inspectés à taille réelle, dans mes propres captures :

- **enveloppe ouverte** → la masse est fermée ; aucune plaque vue par la
  tranche, aucun sommet ouvert ;
- **face intérieure rectiligne noire** → l'intérieur montre parois, plafond
  continu et sol raccordés, avec la bouche en ouverture claire ;
- **caméra intérieure dans les polygones** → la vue de salle est prise à
  hauteur d'œil DANS la cavité, et la tournette à 180°, dos à la bouche,
  ne montre ni ciel, ni fond de scène, ni face arrière. La coque tient de
  tous les côtés ;
- **plaques minces** → un loft unique à sections en rondelle, surface
  fermée de genre 0, collision issue du **même** loft.

## Ce que l'agent a trouvé et qui dépassait son sujet

Il a signalé que `tools/godot/probe_vegetation_near.gd` rendait des comptes
faux. **Vérifié, confirmé, corrigé** — voir le commit dédié. Le facteur
d'erreur atteignait 90, la cause était déjà documentée dans
`world_v2_vegetation_builder.gd`, et ma première tentative de correctif
était elle-même fausse. C'est le genre de signalement qui vaut plus qu'un
asset.

## Ce qui reste faible — et c'est le point principal

L'agent en nomme six ; celui qui compte, et qu'il nomme lui-même, est la
**pauvreté de surface** :

1. **Les parois intérieures sont lisses** — amplitude 0,085, de grands
   plans gris subsistent. Vu à taille réelle, l'intérieur se lit plus comme
   un tunnel de béton que comme de la roche.
2. **La masse extérieure se lit comme une miche lisse.** L'agent a ajouté
   deux sommets, un col, une visière, une diaclase et une corniche ; il en
   reste de grandes faces douces et peu de strates.
3. Le flanc ouest **sature à 0,911** sur les replats au soleil, au-dessus
   de la bande 35–65 %. L'agent l'assume : baisser les albédos extérieurs
   ferait passer le rapport bouche/collerette de 0,449 à ~0,63 et casserait
   la lecture côté approche. C'est un arbitrage documenté, pas un oubli.
4. Pied et corps ne sont séparés que de **0,066** au lieu des ~0,15 visés.
5. La silhouette à 90° reste ronde, et son tiers inférieur est la jupe
   enterrée. Sur une cavité, la silhouette ne peut pas montrer la bouche.
6. **Aucune chute d'eau** : l'affluent gelé descend de 3,0 à 0,5 sur ~14 m,
   pente maximale mesurée 0,25 m/m. Le nom du POI dit « Grotte de la
   cascade » ; l'agent n'a pas inventé d'eau, et c'est la bonne décision —
   l'hydrologie est gelée. **Le nommage est une question pour le lead.**

Le lead a écrit que le pylône « ne constitue pas un plafond de richesse
architecturale ». Sur ce sujet, la richesse de surface est **en deçà** du
pylône, pas au-delà. Je le dis clairement plutôt que de le laisser
découvrir.

`NON VÉRIFIÉ` sur le plan artistique — aucun verdict auto-déclaré.
