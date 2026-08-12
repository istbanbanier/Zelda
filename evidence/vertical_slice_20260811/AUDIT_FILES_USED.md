# Fichiers de l'audit Codex réellement consultés — session du 2026-08-11

**HISTORIQUE.** Ce fichier liste ce qui a été OUVERT pendant la session, pas ce
qui existe. L'existence d'un fichier ne prouve pas qu'il a été regardé ; ne
figure ici que ce qui l'a été, et la colonne « usage » dit ce qui en a été fait.

## Rapports et CSV — lus intégralement

| Fichier | Usage |
|---|---|
| `AUDIT_EXHAUSTIF_ZELADA_20260811.md` | lu en entier en début de session ; a fixé le périmètre des lots et les mesures de départ (sondage 96,8 % plat, 815/1024 sur deux plaines) |
| `PROMPT_REPRISE_CLAUDE_APRES_AUDIT.md` | instruction principale de la session |
| `DEFAUTS_PRIORISES.csv` | lu en entier (27 lignes) ; colonne vertébrale de `AUDIT_TRACEABILITY.csv` |
| `LIEUX_VERDICTS.csv` | lu en entier (33 lieux) ; reporté ligne à ligne dans la matrice |
| `DONJON_VERDICTS.csv` | lu en entier (8 scènes) ; reporté dans la matrice |
| `INTERFACES_VERDICTS.csv` | lu en entier (19 états) ; reporté dans la matrice ; UI-001/002 rattachés au lot F |
| `MANIFESTE_AUDIT.json` | lu (commit audité, couverture, baseline 820/0) ; a révélé l'écart de SHA traité en début de session |
| `RESUME_1_PAGE.md` / `README.md` du pack | parcourus en début de session |
| `inventaire_monde.json` | structure et compteurs lus (nœuds, cellules, POI) — pas les 3 445 lignes une à une |
| `sondage_sol_16m.csv` / `.json` | statistiques utilisées (pente, matériaux) — pas les 1 024 lignes une à une |
| `marqueurs_inacheves_code.txt` | non exploité cette session (constats de code, pas d'image) — au backlog |
| `metriques_images.csv`, `densite_64m.csv`, `SHA256SUMS.txt` | non exploités cette session — au backlog |
| journaux `tests_*.log`, `validation_complete*.log`, `capture_*.log` | parcourus pour la baseline 820/0 et le contexte Blender absent |

## Les douze atlas — TOUS ouverts et inspectés

| Atlas | Constat principal retenu |
|---|---|
| `atlas_defauts_representatifs.jpg` | ouvert en début de session ; a orienté les lots (mine, gorge, cascade en coques ; salles du donjon cubiques ; Options 720p) |
| `atlas_vallee_grille_verticale_8x8.jpg` | deux plaines uniformes confirmées vues du ciel ; contenu concentré en bande centrale |
| `atlas_vallee_grille_oblique_8x8.jpg` | lecture des silhouettes : anneau en peigne, talus verts saturés, mesas orange |
| `atlas_lieux_360_partie_1.jpg` (lieux 1-11) | murs bruns/orange géants écrasant patrol_run, cemetery, crystal_hollow ; aqueduc et bassin lisibles |
| `atlas_lieux_360_partie_2.jpg` (lieux 12-22) | coques vertes du sanctuaire forestier ; belvédère en gros blocs bruns ; hameau et village lisibles |
| `atlas_lieux_360_partie_3.jpg` (lieux 23-33) | bois courbé invisible derrière ses murs ; chute du Voile dominée par sa coque orange ; gorge = parois unies |
| `atlas_grottes.jpg` | boîtes à plafond plat confirmées (15 vues) — hors tranche, reporté |
| `atlas_souterrains.jpg` | même coque partagée (19 vues) — hors tranche, reporté |
| `atlas_donjon_complet.jpg` | 88 vues ; pierre/ambre cohérents, mécanismes cubiques — hors tranche, reporté |
| `atlas_interfaces_complet.jpg` | 19 états ; débordement Options visible ; menus/victoire abstraits — UI-001/002 au lot F, reste au backlog |
| `atlas_parcours_initial.jpg` | 20 vues du parcours joué : c'est le chemin que la tranche doit transformer |
| `atlas_mesures_vallee.jpg` | carte des pentes (quasi uniforme) et densité 64 m — appuie ISS-045 |

## Captures brutes examinées individuellement, par lot

| Capture | Lot / usage |
|---|---|
| `parcours_initial/001_depart.png` | référence du cadrage d'ouverture (lot A) |
| `parcours_initial/003_descente_16s.png` | lecture de la descente et du plan moyen (lots A/B) |
| `parcours_initial/010_vol_altitude.png` | vue d'ensemble des masses (lot B) |
| `evidence/vslice/baseline/01_vista.png` (dépôt) | baseline mesurée : violation §1.5 au commit audité (lot A) |

Les autres captures brutes des zips 01/02/03 (grilles, lieux, donjon,
interfaces) ont été examinées via leurs ATLAS, pas fichier par fichier.

## Constats utilisés dans cette session

- V-010 (valeurs trop claires) → lot A, mesuré avant/après.
- V-001/V-003 (masses et anneau) → lot B, partiel — citadelle restante.
- V-005 (bandes posées) → sous-défaut « rampe repeinte » corrigé ; forme au lot C.
- V-006 (camp fantôme) → lot D.
- La baseline 820/0 du manifeste → référence pour l'enquête « suite double ».

## Constats reportés

Tout le reste — 33 lieux, grottes, souterrains, 8 scènes du donjon, 17 des 19
états d'interface, densité/vie de la périphérie — est `REPORTÉ AU BACKLOG`
dans `AUDIT_TRACEABILITY.csv`, ligne à ligne, avec justification. Aucun
constat n'est déclaré résolu silencieusement.
