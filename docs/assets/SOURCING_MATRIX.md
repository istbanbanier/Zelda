# SOURCING_MATRIX — voies de fabrication des assets de Phase H (Prompt 4 §3)

Date : 2026-08-05 · Soumise à validation utilisateur (les recommandations sont
appliquées par défaut faute d'arbitrage contraire — mandat « Go bloc A→D »).

Règle dure : rien n'entre dans le dépôt sans licence redistribuable vérifiée.
`À VÉRIFIER` bloque l'usage. Environnement : pas de Blender artiste humain —
les voies réalistes ici sont : base CC0 retouchée par script, modélisation
scriptée (procédurale déterministe), génération contrôlée (concepts SEULEMENT).

| Classe | Voie de production | Source précise | Licence | Redistribuable | Retouche prévue | Risque | Fallback |
|---|---|---|---|---|---|---|---|
| Héros | base CC0 retouchée | Quaternius Universal Base Characters + Modular Outfits Fantasy (déjà au dépôt) | CC0 1.0 | **OUI** | épaulière/Bracelet/carquois par script (pièces des packs), textures dérivées | qualité < bible (45-70k tris irréaliste en CC0) → **PARTIAL assumé** | proxy honnête déclaré PARTIAL |
| Animations | base CC0 | Quaternius UAL 1+2 Standard (au dépôt) | CC0 1.0 | **OUI** | retarget baké (outillé), clips manquants composés par code | clips Résonance absents | poses procédurales AnimationPlayer |
| Ennemis ×5 | base CC0 retouchée | mêmes packs Quaternius | CC0 1.0 | **OUI** | équipements §14 par assemblage de props, teintes par baseColorFactor | idem héros | silhouettes différenciées déjà testées |
| Boss | base CC0 retouchée | SK_StormGuardian (dérivé Quaternius, au dépôt) | CC0 1.0 | **OUI** | sous-meshes destructibles par découpe scriptée | complexité §15.2 | états par matériaux/masques |
| Végétation | CC0 + procédural | Quaternius Nature MegaKit + brins/fleurs scriptés | CC0 1.0 | **OUI** | variantes de teinte par instance | répétition visible | phrases manuelles aux focales |
| Roches/falaises | procédural scripté | prismes/ArrayMesh maison (déterministes) | n/a (code) | **OUI** | sculpté ArrayMesh multi-octaves en V4 | painterly limité | silhouettes actuelles (56/100 prouvé) |
| Architecture (camp/village/donjon) | CC0 + compositions scriptées | Quaternius Village/Fantasy Props | CC0 1.0 | **OUI** | trims/atlas dérivés | cohérence donjon §12 | graybox-plus assumé |
| Eau | procédural + shader maison | `SH_WaterStylized` à écrire (spec §8.2) | n/a (code) | **OUI** | — | 1er shader eau du projet | plan d'eau opaque simple |
| VFX | procédural (GPUParticles + meshes + shaders maison) | spec §20 | n/a (code) | **OUI** | — | budget temps | prioriser Résonance/électricité |
| Shaders (12 maîtres) | code maison | spec §21, APIs vérifiées source 4.7.1 | n/a (code) | **OUI** | — | coût llvmpipe des itérations | StandardMaterial3D augmentés (technique R-016 déjà prouvée) |
| UI/icônes | procédural + dessin scripté (SVG→PNG) | spec §23 | n/a (code) | **OUI** | — | finesse limitée | formes géométriques du langage (courant fendu) |
| Typographie | **police libre à embarquer** | **RECOMMANDATION : ne PAS télécharger pendant la phase réseau restreinte — rester police Godot par défaut (licencié MIT avec le moteur), et embarquer plus tard une paire libre (ex. SIL OFL) validée par toi** | défaut : MIT | OUI (défaut) | fallback accents FR à tester | esthétique | police par défaut assumée PARTIAL |
| Images générées | **concepts/moodboards UNIQUEMENT** (§0.2 bible) | génération contrôlée si demandée par toi | n/a | jamais dans le build | — | confusion concept/capture INTERDITE | planches descriptives texte |

## Mise à jour 2026-08-05 — coursier d'assets (AD-001 rouvert par l'utilisateur)

Le workflow `asset-courier.yml` (runner GitHub, seul à avoir le réseau) a livré
**6 packs Kenney** dans `source_assets/external/` : Mini Arena (CC0 — colonnes,
murs, statue, bannière, râtelier, épée, lance : kit donjon/camp §10.2), sons de
locomotion/impact/ambience (MIT), sprites VFX sparkle/smoke/burst. Licences
lues et consignées dans `ATTRIBUTIONS.md`. Échecs documentés : KayLousberg
(packs absents de son GitHub), Quaternius (site seulement — packs déjà au
dépôt), kenney.nl direct (404, URLs à empreinte). Promotion vers `assets/`
manuelle, au moment de l'usage.

## Décision structurante soumise (recommandation appliquée par défaut)

**Toute la production Phase H reste sur le trépied : Quaternius CC0 retouché +
procédural scripté + shaders maison.** Aucun achat, aucun compte, aucun
téléchargement de pack non vérifié. Conséquence honnête : certains plafonds de
la bible (héros 45-70k tris, painterly complet) ne seront PAS atteints — les
éléments concernés sortiront `PARTIAL` documenté, jamais `final` menteur.
Le Gate H visera le maximum atteignable sur cette voie ; le solde sera chiffré.
