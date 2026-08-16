# Les trois lots NON INTÉGRÉS, conservés en patches — pour qu'ils survivent au conteneur

**Rien de ce dossier n'est intégré au tronc.** Il existe pour une raison
d'infrastructure : les commits de ces lots vivent dans des **worktrees détachés**,
donc dans l'objet-store d'un conteneur **éphémère**. Non poussés, ils
disparaîtraient avec lui.

Les pousser sur des branches séparées est interdit par les règles de cette
session. Les conserver en **patches texte, committés sur la branche de travail**,
respecte la règle et rend le travail récupérable.

## Ce qui est conservé

| lot | plage | contenu | taille |
|---|---|---|---:|
| **instruments** | `c79341e..51a7dab` | 4 commits, patches `format-patch` complets | 692 K |
| **collerette** | `c79341e..e0e7567` | **source seule** — `.py`, `.gd`, `.md` | 60 K |
| **base R2a-3.5.2** | `202d849..c79341e` | **source seule** | 180 K |

## Pourquoi la source seule suffit pour la géométrie

Parce que c'est **mesuré**, pas supposé : la chaîne
`tools/blender/export_architecture.sh waterfall_cave` reproduit le GLB candidat
**byte-identique** depuis la seule source, trois fois, avec un contrôle négatif
qui rougit. Voir `../r2a352_reproductibilite/`.

Le `.blend` n'est **pas** conservé, et c'est délibéré : il est une **sortie** de
la chaîne, non reproductible d'un run à l'autre (trois empreintes pour la même
entrée), et jamais lu en entrée. Le conserver donnerait l'illusion d'une source.

Le `.glb` n'est pas conservé non plus : il se reconstruit, et son empreinte
attendue est écrite —
`cc3596c5d68cbfd8060987604aad6d5356772df18086f3f76f5aa8dbf8a73f49`.

## Comment reprendre

```sh
# base, puis collerette — la géométrie
git apply --check evidence/.../base/source_202d849_vers_c79341e.patch
git apply         evidence/.../base/source_202d849_vers_c79341e.patch
git apply         evidence/.../collerette/source_c79341e_vers_e0e7567.patch

# instruments — quatre commits, avec leurs messages
git am evidence/.../instruments/*.patch
```

**Ordre imposé**, et il n'est pas cosmétique : les instruments du lot supposent
les tables de stations de la base. Les appliquer sans elle, c'est mesurer un
maillage avec les cotes d'un autre — l'erreur exacte qui a coûté un tour complet
à l'agent instruments, documentée au §22 du handoff.

## Ce que ces lots contiennent, et pourquoi il serait coûteux de les perdre

**Instruments** — la stabilisation de l'appareil de preuve : 14 occurrences d'un
même défaut de placement corrigées, le repère local par station, la couverture à
100 % des deux côtés, dix épreuves adverses, un banc de calibration analytique, et
la résolution du §23.3. Ce banc a **réfuté les deux prédictions de son auteur** :
le biais ne suit pas l'angle mais **la phase de la frontière dans la grille**, et
les deux instruments de collerette sont biaisés **en sens contraires**.

**Collerette** — la visière, l'orteil et le pied élargi ; le goulot du plan de
bouche passe de 0,566 à 1,040 m, les 25 rayons sur 33 qui sortaient par un jour
tombent à 0.

**Base** — la cavité asymétrique et l'enveloppe R2a-3.5.2, plus les repères de
gameplay re-dérivés. C'est aussi elle qui **porte le défaut de toit mince** qui a
arrêté la passe : reprendre ces patches, c'est reprendre le défaut avec.

## Statut

`CANDIDAT EN ATTENTE DE REVUE` pour la collerette et la base ;
`NON INTÉGRÉ, PARTIELLEMENT VALIDÉ` pour les instruments — 9/10 épreuves
adverses, oracle non validé.

Aucun de ces patches n'a été appliqué au tronc. Le tronc construit et livre
toujours la géométrie **R2a-3.4**.
