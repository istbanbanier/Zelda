# Build EXPÉRIMENTALE T1 — la reprise de partie (à ne PAS jouer lundi)

Commit exact : `@@SHA_LONG@@` (court : `@@SHA_COURT@@`), branche
`claude/world-v2-t1-persistance`.

**Lundi, joue la CANDIDATE, pas cette build.** La candidate est
`world-v2-candidate-iss073-98cbaf0` et son protocole est
`PLAYTEST_ISS073.md`. La build T1 existe pour un essai SÉPARÉ, quand tu veux,
après ou avant — mais ne mélange pas les deux verdicts : lundi mesure le jeu,
cette build mesure une fonctionnalité de la veille.

## Ce que cette build ajoute, en une phrase

Quand tu quittes le jeu — par le menu, par la croix de la fenêtre, ou même si
le jeu s'arrête brutalement (au pire tu perds la dernière minute) — ta
position, ton orientation et l'endroit où tu en étais sont retenus, et
« Continuer » te remet exactement là.

## L'essai, dix minutes

1. **Nouvelle partie.** Marche une ou deux minutes, éloigne-toi bien du point
   de départ. Tourne-toi dans une direction que tu reconnaîtras.
2. **Ferme le jeu par la CROIX de la fenêtre** (exprès — c'est le geste qu'on
   teste).
3. Relance. **Continuer.** → Tu dois être LÀ OÙ TU ÉTAIS, tourné comme tu
   l'étais. Si tu réapparais au point de départ sur la crête : c'est un
   échec, dis-le.
4. Rejoue un peu, va jusqu'au donjon si tu veux : si tu atteins
   l'antichambre (la salle avant le boss), quitte par le menu, relance,
   **Continuer** → tu dois revenir DANS l'antichambre, pas dans la vallée.
5. Si tu meurs quelque part : « Réessayer » doit te remettre au dernier
   endroit où tu étais vivant ET sauvegardé — jamais à l'endroit exact de ta
   mort, jamais au point de départ de la carte.

## Ce qu'on sait déjà (et que tu n'as pas besoin de re-prouver)

- Dix contrats automatiques couvrent position, orientation, lieu de reprise,
  sauvegardes anciennes (elles repartent au point de départ, c'est voulu),
  sauvegardes corrompues (le jeu refuse proprement) et la protection de ta
  progression (`boss vaincu` ne peut pas être perdu par une sauvegarde).
- Un point CONNU et assumé : si tu reprends dans l'antichambre, ton
  inventaire revient au kit de base (ISS-080, défaut plus ancien que cette
  build). Le coffre de l'antichambre se re-loote — tu n'es pas bloqué.

## Ce qui nous intéresse dans ton retour

- La reprise t'a-t-elle remis au bon endroit, tourné du bon côté ?
- As-tu perdu quelque chose (objet, progression) en quittant/reprenant ?
- Un moment où « Continuer » t'a surpris — mauvais endroit, mauvaise scène ?
