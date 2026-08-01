# Playtest D.1 — retour humain n° 1 (2026-08-01)

Package : `EclatsDOrage_D1_Playtest_329b55e.zip` · code jouable `316e4dd`.
Verdict propriétaire : **D.1 n'est pas une expérience jouable** — C.5 et toute
passe artistique suspendus jusqu'à une version corrective rejouable (D.1R).

## Observé par le TESTEUR (verbatim consolidé)

Le testeur a lancé la vallée et l'a explorée. Défauts bloquants :

1. Caméra beaucoup trop lente.
2. Souris non capturée — le curseur quitte la fenêtre avant de pouvoir regarder autour.
3. Le joueur et les pillards se traversent.
4. Les pillards se superposent entre eux.
5. Aucun HUD (vie, endurance invisibles).
6. Armes ramassées versées silencieusement dans un inventaire inaccessible.
7. Aucun moyen compréhensible d'équiper/sélectionner/intervertir les armes.
8. Coffres et armes au sol sans invite d'interaction ni confirmation claire.
9. On peut quitter le terrain et tomber dans le vide.
10. Les structures (citadelle comprise) n'ont ni entrée ni intérieur.
11. Ni menu pause ni réglage de sensibilité.
12. Combat illisible : pas d'arme visible, pas d'animation, pas de télégraphe visuel.

## Découvert par AUDIT DU CODE (fourni avec le retour — causes vérifiées)

- `ValleyWorld` ne passe jamais `Input.MOUSE_MODE_CAPTURED` (seuls les labos le font).
- Delta souris multiplié par `MOUSE_LOOK_SCALE` PUIS re-multiplié par
  `camera_stick_speed * delta` dans `CameraRig.apply_look()` — unités souris et
  stick mélangées (≈ ÷25 sur la rotation).
- `Player.tscn` masque 1, `RaiderRed.tscn` masque 1 : personne ne collisionne
  qu'avec le décor — jamais entre corps.
- `_try_interact()` : distance + cône seulement, aucune ligne de vue (§14.2 violé).
- Aucun `CanvasLayer` de gameplay dans la vallée ; `GameState.set_paused()` jamais
  appelé ; filet de chute tardif (−20, 1 s) ; « Continuer » n'applique rien ;
  mort sans retry ; aucun test sur capture souris, conversion delta, séparation
  des corps, interaction à travers mur.

## Triage (fréquence × gravité × coût — §21.9)

Tout est S2 sauf mention : contrôle caméra (1, 2, 11) → **D.1R.1** ; corps
traversables (3, 4) → **D.1R.2** ; lisibilité/HUD/inventaire/invites (5–8, 12)
→ **D.1R.3** ; monde/mort/structures (9, 10 — S3) → **D.1R.4** ; honnêteté de
« Continuer » → **D.1R.5**.
