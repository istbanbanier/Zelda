# Revue contradictoire du Gate C — 2026-08-01

Passe **unique** (décision propriétaire), contexte frais, code jugé : commit
`78f2b9a`. Le réviseur a REJOUÉ les commandes (validate_fast, import, parse des
75 scripts, scan exhaustif des chemins `res://`) et construit ses propres sondes.

## Verdicts par critère (rendus par le réviseur)

| Critère | Preuve rejouée | Verdict |
|---|---|---|
| Combat gagnable | validate_fast VERT RC=0, 214/214 ; `test_combat_exchange` (mannequin 45 PV mort, joueur vivant) ; `test_raider` (duel réel) | **PASS** (volet automatique) — voir D1 |
| Une touche par swing | `test_an_overlapping_swing_hits_exactly_once` (30 frames → 1 coup) + second swing + deux mannequins + flèche à victime unique ; lecture du set `_already_hit` et de la revérification `_active` par cible ; aucun contre-exemple trouvé | **PASS** |
| Aucune référence invalide | import RC=0 ; 75 scripts parsés sans erreur ; scan des `res://` de scenes/resources/scripts/tests/tools → 0 manquant | **PASS** |
| Esquive avec i-frames | `test_dodge` vert ; fenêtre 0,02–0,27 = 0,25 s dans l'enveloppe §10.2 ; logs Y1/Y2 prouvent que ces tests savent rougir | **PASS** |

## Constats et traitement (le jour même, sans nouvelle boucle)

| # | Sévérité | Constat du réviseur | Traitement |
|---|---|---|---|
| D1 | S2 | **La mort du joueur n'existe pas** : le coup fatal déclenche HURT (signal émis avant `take_damage`), le cadavre court à 6 m/s, attaque, esquive ; le pillard frappe le cadavre indéfiniment (`_target_valid` et la perception ignorent la mort). Trou non consigné. | **Corrigé** : `Mode.DEAD` (immobile, sourd aux intentions, verrouillage libéré, recul fatal annulé) ; pillard : cadavre invalide comme cible ET comme perception. Régression : `test_player_death.gd` rejoue la sonde du réviseur — 2 tests, 13 assertions. Checkpoint/retry : Phase E, consigné dans STATUS. |
| D2 | S3 | 13 des 25 logs de contrôles négatifs (séries W/X/Y) portent `RC=0` avec des tests en échec : la ligne `RC=` y capture le code du pipeline grep, pas celui du runner (qui fait bien `quit(1)` depuis A.2, vérifié par sonde). | **Annoté** dans `README.md` (section ci-dessous) : ces 13 lignes `RC=` sont invalides comme preuve de propagation du code retour ; le CONTENU des échecs listés reste valide. Pas de régénération (décision propriétaire : pas de nouvelle boucle de contrôles). Les séries Z et AA capturent le bon code (`PIPESTATUS[0]`), convention corrigée depuis C.3. |
| D3 | S4 | `player_controller.gd` : `_weapon_hitbox.get_node("CollisionShape3D")` déréférencé hors garde `!= null`. | **Corrigé** : lecture de la forme déplacée dans la garde, `get_node_or_null`. |
| D4 | note | Preuves de l'étape 1 non commitées au lancement de la passe ; commit `a9004cb` (preuves seules) apparu en cours de revue. | Acté : le log commité (14:29) est antérieur au replay du réviseur et concorde avec lui. À l'avenir : commettre les preuves AVANT de lancer la passe. |

## Dettes d'environnement (hors verdict, passe finale)

Ressenti §10.6/§10.8 (session humaine à l'aveugle), manette (CONTROLLER-001),
AZERTY physique (VALIDATION-B-001), hit-stop/VFX/sons non implémentés.

## Verdict

Volet automatique : quatre critères **PASS** rejoués ; D1 et D3 corrigés et
prouvés le jour même (216/216 après correction) ; D2 annoté. Les essais humains
n'ont pas eu lieu : le verdict ne peut pas dépasser le plafond d'environnement.

**Gate C : ACCEPTÉ POUR CONTINUATION AVEC VALIDATION HUMAINE DIFFÉRÉE**
(décision propriétaire D-024, même régime que D-021 pour le Gate B).
