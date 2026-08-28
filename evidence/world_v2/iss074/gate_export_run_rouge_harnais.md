# Portail d'export de la garnison — run ROUGE du 2026-08-28, et sa cause

`GATE_EXPORT_GARNISON : ROUGE (2 échec(s))`, `RC=1`, sur la build
`sha_git_teste = fbf2b524aa1c`, arbre propre (`fichiers_sales: 0`).

Ce document existe pour une raison précise : **les deux échecs ne portaient sur
aucune affirmation du jeu.** Toutes les assertions de fond sont passées. Les
deux `FAIL` étaient la même étape du harnais — la demande de fermeture de
fenêtre — et la seconde était causée par la première.

## Ce que le run a affiché

```
== G1 ==  PASS  build liée au commit courant (fbf2b524…)
== G2/G3 ==
  PASS  quatre gardes posés, aucun déjà tombé
  PASS  un garde a VU le héros arriver : garrison.ember_camp.blue.01
  PASS  le héros a RÉELLEMENT marché : 73.73 m depuis son point de reprise
  PASS  aucun modèle ni ressource manquant dans le PCK
== G4 ==
  PASS  quatre gardes, pas huit — aucune duplication
  PASS  le bâtisseur n'a construit QU'UNE fois dans ce processus
== G5 ==
  PASS  deux gardes seulement : les deux morts du slot ne reviennent pas
  FAIL  le jeu n'a pas quitté (G5)
== G6 ==
  PASS  « Continuer » route vers l'antichambre
  FAIL  le jeu n'a pas quitté (G6)
  PASS  une écriture a RÉELLEMENT eu lieu (horodatage : 2026-08-28 20:43:03)
  PASS  l'inventaire est INTACT après la reprise dans l'antichambre (ISS-080)
```

L'horodatage de G6 mérite d'être noté : il est **frais**, pas la graine figée
`2026-08-28T00:00:00`. La garde d'écriture ajoutée après la contre-revue a donc
fonctionné comme prévu — le gate n'aurait pas pu verdir sans écriture réelle.

## La cause, mesurée et non déduite

`evidence/world_v2/iss074/mesure_fermeture_fenetre.log` rejoue les deux
scénarios **seuls sur la machine**, et chronomètre la mort du processus après
l'envoi de `WM_DELETE_WINDOW` :

| scénario | cache de shaders | mort après |
|---|---|---:|
| G5 — vallée complète, profil neuf | froid | **32 s** |
| G6 — antichambre, profil neuf | froid | **2 s** |

L'ancien budget du harnais était de **30 s**. Il manquait deux secondes.

Le premier rendu llvmpipe d'une vallée complète occupe la boucle principale ;
l'événement X n'est lu qu'ensuite. Le budget ne mesurait donc pas la fermeture,
il mesurait la compilation des shaders. G4 passait parce qu'il réutilisait le
profil déjà chauffé par G2/G3 — 24 Mo de cache déjà écrits.

## Pourquoi G6 est tombé avec G5

`fermer_fenetre` rendait 1 **sans tuer le processus** et sans vider `PID_JEU`.
Le jeu de G5, encore vivant, gardait llvmpipe à fond et sa fenêtre visible.
L'étape G6 héritait d'une machine chargée — et d'une fenêtre parasite que
`xdotool … | tail -1` pouvait désigner à la place de la sienne.

Un seul défaut, deux échecs affichés.

## Ce qui a été corrigé, dans le harnais seulement

Aucune ligne de code de jeu n'a bougé.

1. `DELAI_FERMETURE=180` au lieu de 30, et **l'attente réelle est publiée à
   chaque appel** : le jour où elle dérive, on le lira au lieu de le subir.
2. En cas de dépassement, le processus est **tué puis attendu**, et `PID_JEU`
   vidé : plus jamais d'orphelin qui empoisonne l'étape suivante.
3. La fenêtre est choisie **par son PID**, jamais par `tail -1`.
