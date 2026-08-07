# Lot 3 — première vidéo de stabilité temporelle (§30.1)

**Date** : 2026-08-06 · **Arbre committé** : `ae95f05` · **Statut :
`Fonctionnel`** (outil testé 2/2 ; séquence produite et jugée en
interne). Le verdict visuel qui compte reste `UNVERIFIED` — humain sur
GPU (ISS-002).

## Le manque comblé

La bible exige (§30.1) une séquence de 10-20 s « avec marche, sprint et
rotation caméra » à chaque revue — JAMAIS produite (domaine mouvement :
2/10 à l'éval sévère v5). Produite via le mode Movie Maker du moteur
(`--write-movie` + `--fixed-fps 12`, vérifié dans la source 4.7.1) :
pas de temps FIXE — le vent et la tempête sont échantillonnés au bon
rythme quel que soit le débit du rendu logiciel.

## Timeline (`scenes/lookdev/StabilityDolly.tscn`, 18,1 s, 217 frames)

- 0-3 s : ARRÊT (vent/orage jugés sans parallaxe — ajouté après la
  première séquence, où la caméra toujours en mouvement noyait tout) ;
- 3-9 s : marche 3,5 m/s (contrat §8.2), glissement vers le chemin ;
- 9-13 s : sprint 9 m/s ; 13-18 s : rotation ±35°.

## Sorties

- `herolab_v6_stabilite.webp` (640×360, 12 i/s, 18,1 s) ;
- `herolab_v6_stabilite_cles.png` (4 images-clés 960×540) ;
- `herolab_v6_stabilite.json` (manifeste, `repo_dirty: false`).

## Ce que la vidéo a RÉVÉLÉ (sa raison d'être)

1. **L'herbe du lab était FIGÉE** : sondes sur la phase immobile =
   diffs 0,00 partout — aucun vent, contre §11.1. **Corrigé dans ce
   lot** : `SH_FoliageWindPainterly` (vent de SH_FoliageWind au vertex
   + ramps peintes au light) sur TOUTES les cellules d'herbe du lab —
   rouge 0/8 prouvé, puis pilotes 3/3, héros 17/17. Sondes après :
   1,62-2,03 — balancement doux, cohérent, sans vague uniforme.
2. **Le lab est un décor à UNE caméra** : dès que le dolly descend la
   pente, le sol devient nu (BL-06), la rivière se lit comme une
   planche flottante, le chemin s'arrête, le camp est une boîte. C'est
   ACCEPTABLE pour un lab de composition (une seule caméra de
   référence), mais c'est un garde-fou écrit pour la propagation V4 :
   la vallée réelle doit survivre au mouvement, pas copier ces
   raccourcis.
3. **Stabilité temporelle** : aucun shimmer, scintillement, pop ni
   ghosting observé sur les 217 frames — honnêtement, en partie parce
   que le lab n'a ni LOD, ni transparence, ni TAA : la valeur de cette
   vidéo grandira avec chaque matière ajoutée.
4. **L'éclair n'est pas tombé** dans la fenêtre d'arrêt de 3 s (cadence
   volontairement rare) ; le flash tenu reste prouvé par la capture
   fixe (`hold_flash`, v2+).

## Capture officielle v7 (`herolab_v7_vent.png`, arbre `ae95f05`)

L'herbe entière portant désormais le feuillage painterly, la vue de
référence a été recapturée : bandes de valeurs §1.5 IDENTIQUES à v6 au
dixième près (héros 25,8 %, citadelle 52,7 %, ciel 73,7 %) — le vent et
la déclinaison feuillage n'ont pas cassé la hiérarchie. Vignette
320×180 : trajectoire héros→chemin→camp→pylône→citadelle→orage intacte.

## Ce que cette vidéo NE prouve PAS

La fluidité. Rendu logiciel llvmpipe, 12 i/s reconstituées : aucune
mesure de FPS n'existe ni n'existera ici (ISS-002).

## Reste (ordre AD-004)

1. Étendre le painterly aux surfaces restantes du lab (falaises hors
   pilote, terrain, camp, citadelle, montagnes, rivière) ;
2. re-évaluation sévère §30.2 + revue contradictoire ;
3. propagation V4 seulement si ≥ 75 tenu — avec l'enseignement n°2
   ci-dessus comme contrainte de construction.
