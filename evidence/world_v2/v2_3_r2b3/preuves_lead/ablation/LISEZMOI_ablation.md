# Ablation des deux tas de gravats — mesure et son plancher

Date 2026-08-20. Branche `claude/world-v2-reconstruction`, HEAD `4857c088`.
Godot 4.7.1, rendu LOGICIEL llvmpipe.

**Ces PNG sont des IMAGES DE MESURE, pas des preuves visuelles.** Le vent y est
GELÉ (`sway_amplitude = 0`), ce qui n'est pas l'état du jeu. Aucune de ces
images ne doit être versée comme capture de rendu.

## Ce qui a été réparé avant de pouvoir mesurer

Le gel du vent que portait `capture_sans_noeuds.gd` **n'a jamais fonctionné**.
Il appelait `get_surface_override_material_count()` sur une variable typée
`GeometryInstance3D` ; or (vérifié par `ClassDB`) cette méthode est propre à
`MeshInstance3D` et absente de `MultiMeshInstance3D` — qui est justement ce
qu'est l'herbe de WorldV2.

Une erreur GDScript n'arrête pas le `SceneTree` : `_run()` mourait, `quit()`
n'était jamais atteint, le processus tournait jusqu'au kill externe, et
**aucun png n'était écrit** — après avoir imprimé une ligne « TÉMOIN »
parfaitement rassurante. C'est la famille ISS-018 : un journal crédible sur un
travail qui n'a pas eu lieu.

Corrigé dans `tools/godot/capture_sans_noeuds.gd` : les surfaces ne sont lues
que sur `MeshInstance3D`, le `MultiMesh` est traité par son propre maillage, et
`material_override` reste couvert. Le gel interroge désormais le **code du
shader** et non `get_shader_parameter()`, qui rend `null` lorsqu'un matériau se
contente de la valeur par défaut du shader — un feuillage laissé par défaut
aurait continué à balancer pendant qu'on annonce « vent gelé ».

## Le plancher A/A — la mesure qui rend le reste interprétable

`--paires --masquer=AUCUN` : même scène, même processus, même état, rendu deux
fois à une trame d'écart.

**0 pixel changé sur les onze vues, au seuil 1 comme au seuil 8 comme au seuil
32.** Les deux trames sont bit-à-bit identiques.

Le plancher n'est donc pas « petit », il est nul, et il n'y a aucune vue où le
signal soit du même ordre que lui. Les trois campagnes précédentes (0,57–5,45 %,
0,90–6,44 %, 0,84–4,94 %) mesuraient le vent, pas les gravats.

Contrôle de non-aveuglement : le MÊME chemin de code rend un signal non nul dès
qu'on éteint les deux maillages. Le zéro du plancher est donc une propriété de
la scène, pas un instrument mort.

## Deux instruments, une seule réponse

`diff_paires.py` (référence, double boucle Python) et `verif_croisee_diff.py`
(chemin indépendant, `ImageChops` en C) donnent des comptes **identiques au
pixel** au seuil 8 sur les onze vues. Les deux ont d'abord été étalonnés sur une
paire synthétique à réponse connue (5 000 px au seuil 8, 0 au seuil 32).

## Fichiers

- `plancher_aa/` — 11 paires, témoin A/A
- `signal_debris/` — 11 paires, `SM_Farm_Debris_A` + `SM_Farm_Debris_B` éteints
- `resultats_diff_paires.txt` — outil de référence
- `resultats_verif_croisee.txt` — vérification croisée, 3 seuils
- `densite_boites.txt` — compacité, pour ne pas sur-lire un petit compte
- `journal_*.log`, `rc.txt` — RC et sorties brutes
