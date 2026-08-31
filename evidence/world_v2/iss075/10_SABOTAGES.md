# ISS-075 voie B — preuve par SABOTAGE que chaque contrat rougirait

Un contrat vert ne prouve rien tant qu'on n'a pas vu ce qui le fait rougir.

**Deux passes au lieu de six, et pourquoi.** Le verrou `heavy_tools.lock` est
partagé par tout le dépôt ; une suite complète voisine l'a tenu 45 minutes
pendant cette session. Six lancements isolés auraient demandé six attentes de
cet ordre. Les six sabotages sont donc groupés en **deux passes de trois**,
choisies pour que les trois défauts d'une même passe visent des fichiers et des
fonctions DISJOINTS, et que les trois contrats attendus ROUGES lisent des
choses différentes. Une passe est concluante si **exactement** ses trois cas
rougissent et que les sept autres restent verts : un contrat qui répondrait au
défaut d'un autre se verrait immédiatement.

Ce que ce groupage ne prouve pas, dit franchement : il n'exclut pas qu'un
contrat réponde à deux défauts de la MÊME passe. Il exclut qu'il soit inerte,
et il exclut qu'il réponde à un défaut de l'AUTRE passe.


## PASSE 1 — S1 drapeau posé avant le travail · S3 étiquette 10 Hz sans garde · S5 valeur française altérée d'une espace

Cas attendus ROUGES : `test_le_drapeau_de_cache_se_pose_apres_le_travail_jamais_avant`, `test_les_etiquettes_rafraichies_en_boucle_passent_par_la_garde`, `test_le_francais_rendu_est_inchange`

```
=== RÉSULTAT: 9 réussi(s), 3 échoué(s) ===
test_textes_iss075.gd::test_le_drapeau_de_cache_se_pose_apres_le_travail_jamais_avant — B1 — `_charge = true` doit v
test_textes_iss075.gd::test_les_etiquettes_rafraichies_en_boucle_passent_par_la_garde — B3 — `_refresh_buff_label` 
test_textes_iss075.gd::test_le_francais_rendu_est_inchange — B5 — « boss.phase.dead » doit rendre EXACTEMENT le te
  ÉCHEC: test_textes_iss075.gd::test_le_drapeau_de_cache_se_pose_apres_le_travail_jamais_avant — B1 — `_charge = tr
  ÉCHEC: test_textes_iss075.gd::test_les_etiquettes_rafraichies_en_boucle_passent_par_la_garde — B3 — `_refresh_buf
  ÉCHEC: test_textes_iss075.gd::test_le_francais_rendu_est_inchange — B5 — « boss.phase.dead » doit rendre EXACTE
```

## PASSE 2 — S2 `{}` construit à chaque appel · S4 traduction sur le chemin par frame · S6 le défaut RÉEL de la migration (§8)

Cas attendus ROUGES : `test_brut_ne_construit_pas_un_dictionnaire_a_chaque_appel`, `test_le_chemin_par_frame_ne_porte_aucune_traduction`, `test_le_francais_restant_est_confine_au_chemin_par_frame`

```
=== RÉSULTAT: 9 réussi(s), 5 échoué(s) ===
test_textes_iss075.gd::test_brut_ne_construit_pas_un_dictionnaire_a_chaque_appel — B2 — `brut()` ne doit plus porter
test_textes_iss075.gd::test_brut_ne_construit_pas_un_dictionnaire_a_chaque_appel — B2 — et le remplacement est bien 
test_textes_iss075.gd::test_le_chemin_par_frame_ne_porte_aucune_traduction — B4 — `_resonance_state_line` est attein
test_textes_iss075.gd::test_le_francais_restant_est_confine_au_chemin_par_frame — B10 — « Cuisiné : %s » (portée
test_textes_iss075.gd::test_le_francais_restant_est_confine_au_chemin_par_frame — B10 — tout le français restant (9
  ÉCHEC: test_textes_iss075.gd::test_brut_ne_construit_pas_un_dictionnaire_a_chaque_appel — B2 — `brut()` ne doit p
  ÉCHEC: test_textes_iss075.gd::test_brut_ne_construit_pas_un_dictionnaire_a_chaque_appel — B2 — et le remplacement
  ÉCHEC: test_textes_iss075.gd::test_le_chemin_par_frame_ne_porte_aucune_traduction — B4 — `_resonance_state_line` 
  ÉCHEC: test_textes_iss075.gd::test_le_francais_restant_est_confine_au_chemin_par_frame — B10 — « Cuisiné : %s 
  ÉCHEC: test_textes_iss075.gd::test_le_francais_restant_est_confine_au_chemin_par_frame — B10 — tout le français 
```

## Comment lire les deux comptes ci-dessus

Le runner compte les **méthodes** réussies mais liste les **assertions**
échouées. « 9 réussi(s), 5 échoué(s) » de la passe 2 n'est donc pas
14 méthodes : c'est 9 méthodes vertes et **trois** méthodes rouges, dont deux
ont manqué deux assertions chacune (`B2` et `B10`). Le fichier porte
12 méthodes ; 9 + 3 = 12 dans les deux passes.

| Passe | méthodes rouges | attendues | verdict |
|---|---|---|---|
| 1 | `B1` (structure), `B3`, `B5` | les mêmes trois | conforme |
| 2 | `B2`, `B4`, `B10` | les mêmes trois | conforme |

**Aucun contrat n'a rougi hors de sa passe**, et les neuf autres sont restés
verts à chaque fois. Un contrat inerte se serait vu : il serait resté vert
pendant que son défaut était en place.

> Les messages d'échec ci-dessus sont **tronqués** : le journal les coupe à
> 120 colonnes. La troncature a coupé deux caractères multi-octets en deux et
> rendu le fichier non décodable ; les deux octets orphelins ont été retirés.
> Un fichier de preuve qu'on ne peut pas lire n'est pas une preuve — et
> `cut -c` compte des OCTETS, pas des caractères.

## Le VERT final, tout sabotage retiré

Dix fichiers nommés explicitement — `gate_select.sh` ne sélectionne rien
sur un diff de `.json` et sort en 0.

```
erreurs de script dans le journal : 0
=== RÉSULTAT: 56 réussi(s), 0 échoué(s) ===
```

## Retrait intégral du sabotage

```
$ git diff --stat -- scripts/ resources/
 resources/localisation/fr.json |  89 +++++++++++++++--
 scripts/localisation/textes.gd |  51 ++++++++--
 scripts/ui/gameplay_shell.gd   | 215 ++++++++++++++++++++++++++---------------
 3 files changed, 262 insertions(+), 93 deletions(-)
```
