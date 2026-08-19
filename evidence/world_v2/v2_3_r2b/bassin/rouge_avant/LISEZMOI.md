# Rouge AVANT habillage — bassin conducteur (V2.3-A.R2B, agent C)

Journal : `r2b_basin_rouge.log` — commande :

    godot --headless --path . --script tools/godot/test_runner.gd -- --filter=r2b_basin

État mesuré au SHA de base 5f821e5 (+ le fichier de test neuf, non commité au
moment de la course ; regénéré à l'identique après commit si besoin) :

- `test_l_habillage_du_bassin_vient_du_kit_avec_uv` : **72 écarts** — tout
  l'habillage est en `stone_block` procéduraux (ArrayMesh sans chemin ni UV).
  C'est le rejet du lead (« des primitives ») rendu exécutable.
- `test_le_bassin_garde_comportement_et_contrat_dans_le_monde` : **2 écarts**
  — `Margelle_19/20` de l'ANCIENNE margelle procédurale rasent l'eau garantie
  de la nappe (ellipse de houle minimale). Le comportement canonique
  (classe, graphe enfant direct, récepteur qui attend, récompense, POI,
  appuis, colliders 1/0) ne porte AUCUN écart.
- `test_les_lampes_gardent_leur_noyau_et_l_habillage_n_emet_pas` : **2
  écarts** — Socle/Fût encore en BoxMesh (option B non appliquée).

Calibrage consigné : la mesure « rien dans le volume de baignade » pour les
MAILLAGES a été corrigée deux fois AVANT ce rouge (boîte canonique → boîte
rétrécie → ellipse d'eau garantie), parce que la boîte a des coins secs
au-delà du bord d'eau — la grandeur visée est l'obstruction, pas le surplomb.
Les COLLIDERS restent jugés sur la boîte canonique entière. Détail dans
l'en-tête du test.
