# §11 — la release vérifiée DEPUIS GitHub, pas depuis le disque local

Release : world-v2-playtest-lot1r2-05d0760 (run Actions 33085639174, succès).

1. **Les quatre archives retéléchargées** depuis la page de release :
   tailles au octet près et SHA-256 conformes, doublement — contre
   `SHA256SUMS.txt` et contre chaque `.sha256` individuel
   (`verification_tailles_sha256.txt`).
2. **Le guide `PLAYTEST_LOT1R2.md` publié** porte le SHA long et court du
   commit construit (`05d0760d05dc…`), remplis par la CI — plus aucun
   placeholder.
3. **Le binaire Linux retéléchargé a été LANCÉ** (fumee_vues_six_lieux.py) :
   13 points, 0 FAIL, 0 BLOQUÉ — menu, « Nouvelle partie », monde monté,
   manifeste 215/215 + 160/160 chargeables, six vues distinctes en
   1920x1080 comparées aux références éditeur (RMSE 0,015-0,089, tous sous
   leurs seuils calibrés). C'est le binaire construit par le RUNNER, pas la
   copie locale : la chaîne de livraison entière est éprouvée.

Le ZIP porte un binaire différent de l'export local (horodatages
d'empaquetage, runner différent) — c'est attendu ; ce qui compte est qu'il
passe la même batterie, et il la passe.
