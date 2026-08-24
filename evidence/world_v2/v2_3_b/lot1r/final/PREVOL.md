# Pré-vol de la passe de preuves — ce qui a été vérifié AVANT de dépenser du rendu

Le rendu est logiciel (llvmpipe) : la passe complète coûte plus d'une heure de
mur. Un outil qui meurt à la dernière étape ferait perdre cette heure. Les
contrôles ci-dessous sont donc faits **avant**, sur les fichiers seuls.

| Contrôle | Méthode | Résultat |
|---|---|---|
| Les 13 caméras gelées sont bien les 13 de la baseline | comparaison des noms de `shots_lot1.json` | **13/13**, aucune manquante |
| `shots_ab13.json` porte exactement 6 vues `*_joueur` | filtre sur le suffixe | **6** — `forest_shrine_joueur_b` n'en est pas une |
| Les dossiers A/B porteront les mêmes vues | lecture de `lot1r_planches.py` | scission en `ab13/` + `gros_plans/` **imposée** |
| Les six identifiants de lieu existent | `resources/world_v2/world_v2_layout.json` | **6/6** sur 31 POI |
| Le détecteur D3 retrouvera le corpus accepté | lecture de `lot1_repetition.py` l.197-201 | il lit `vue.image` **dans** le manifeste ; recopier le JSON suffit |
| Les 15 manifestes de silhouette existent | listage | **9 corpus + 6 lot** |
| Les cinq parcours vidéo sont jouables | schéma `place_id` / `etapes` / `pos=[x,z]` | **5/5 conformes**, pauses cumulées 15,2 à 17,5 s |
| La preuve croisée cadre bien les deux lieux | projection dans le repère caméra | tour au centre, source à (+0,28 ; −0,69) — voir `PREUVE_CROISEE.md` |

## Deux pièges attrapés au pré-vol, et ce qu'ils auraient coûté

**`lot1r_planches.py` meurt si les deux dossiers diffèrent d'une seule vue.**
Son texte est explicite : « un appariement partiel rendrait une planche qui a
l'air complète ». Les 40 plans dans un dossier unique, face à une baseline de
13, auraient donc fait échouer la dernière étape **après** tout le rendu. D'où
deux dossiers : `ab13/` s'apparie au pixel près, `gros_plans/` n'a pas d'AVANT
et n'en a pas besoin.

**Les parcours vidéo de la voie A étaient injouables.** Un document pour deux
lieux, et des positions `[x, y, z]` là où l'outil lit `[x, z]` : le pilote
aurait marché vers un point qui n'est pas le lieu, et rendu un film crédible et
faux. Convertis, avec l'allure ramenée à la marche pour tenir les 20-40 s du
contrat.

## Ce que le pré-vol ne peut PAS dire

Rien sur l'image. Il établit que les outils vont s'exécuter et sur les bons
sujets ; il ne dit pas si le résultat est beau, ni même correct. L'occlusion,
la valeur des faces, la lisibilité des silhouettes : seules les captures
tranchent, et la barre « wahou » s'applique après elles.
