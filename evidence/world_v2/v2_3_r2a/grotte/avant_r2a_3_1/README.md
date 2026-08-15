# Côté « AVANT » de l'A/B exigé pour R2a-3.2

La revue R2a-3.1 demande « un A/B direct R2a-3.1 → R2a-3.2 pour l'approche,
le seuil et la niche ». Or les recaptures de R2a-3.2 écriront dans le dossier
parent, aux mêmes noms de fichiers. Sans cette copie, le côté gauche du
montage n'existerait plus qu'en histoire git — récupérable, mais pas
juxtaposable sans détour.

Ces neuf images sont donc l'état **R2a-3.1 gelé**, copié avant toute
reconstruction.

## Provenance, vérifiée et non supposée

* Captures produites au commit **`71d18174111b9d2a9044a3d182e781ea376b035d`**,
  `repo_dirty: false` — voir `manifest.json` ci-joint, qui est celui d'origine.
* Fichiers versionnés au commit **`fe9fc67`** (le commit de preuves qui suit
  celui du code).
* Les neuf PNG ont été comparés par `sha256sum` à leur version dans
  `fe9fc67` : **identiques bit à bit**, les neuf.

La distinction entre les deux SHA n'est pas un détail : `71d1817` est le
commit dont le manifeste porte le hash, parce que la capture vient de cet
arbre-là ; `fe9fc67` est celui où les images sont entrées dans le dépôt.
C'est l'ordre impose par `.claude/rules/evidence.md` — commiter le code,
capturer, commiter la preuve.

## Contenu

| Fichier | Vue |
|---|---|
| `01_composition.png` | composition depuis le monde |
| `02_approche_joueur.png` | approche à hauteur de joueur |
| `03_gros_plan_seuil.png` | gros plan du seuil |
| `04_interieur_sortie.png` | intérieur vers la sortie |
| `05_interieur_niche.png` | intérieur vers la récompense |
| `06_flanc_strates.png` | flanc montrant les strates |
| `07_trois_masses.png` | les trois masses depuis le nord-est |
| `silhouette_grotte_000.png` | silhouette isolée 0° |
| `silhouette_grotte_090.png` | silhouette isolée 90° |

Les tournettes ne sont pas copiées : l'A/B demandé porte sur l'approche, le
seuil et la niche, et l'histoire git conserve le reste.

**Ces images ne sont pas une preuve de l'état courant.** Elles documentent un
état rejeté, conservé pour la comparaison.
