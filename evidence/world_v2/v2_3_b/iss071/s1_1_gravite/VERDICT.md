# S1.1 — verdict : `BLOQUÉ`

Date : 2026-08-27. Contrat préenregistré : `docs/contrats/s1_1_gravite.md`.
Sujet : archive publiée `EclatsDOrage_Linux_x86_64_05d0760.zip`, sha256
`302643c7a5b59418d767121641f798ef0728d8358d6c0b8befec2e1241a8f91e`, vérifiée
avant lancement puis **binaire extrait de cette archive-là**.

## Verdict

| | |
|---|---|
| S1.1 — gravité de la build publiée | **`BLOQUÉ`** |
| Gravité du jeu | **`NON VÉRIFIÉ`** — ni réussite ni échec démontré |
| `GO_V2_3_B_LOT2` | **`FALSE`** |
| Nouvelle release | **aucune** |
| Release `world-v2-playtest-lot1r2-05d0760` | **publiée et inchangée** |

## Cause exacte

L'horloge que le moteur donne aux scripts est décrochée du temps mural du
harnais. Mesure, par l'échantillonneur automatique de `DevMode` — un
événement `position` par seconde de temps moteur :

| Exécution | Mural | `position` | Rapport | F4 |
|---|---:|---:|---:|---:|
| Campagne complète (3 répétitions + contrôle négatif) | 152 s | 2 | **0,013** | 111 |
| Sonde dédiée, **aucun F4** | 120 s | 7 | **0,058** | 0 |

Le moteur annonce dans le même temps **7,3–7,7 FPS** et aucune image au-delà
de 150 ms. Les deux ne peuvent pas être vrais ensemble.

Conséquence : une consigne émise « toutes les 1,5 s » n'arrive pas toutes les
1,5 s **de jeu**. Les phases de repos, longues de 2,3 s murales, valent
quelques centièmes de seconde de jeu — le héros n'a pas atterri quand on le
mesure « au repos ». D'où un contrôle négatif qui rend **6 marqueurs élevés
sur 23 sans le moindre appui sur Espace**, ce que le contrat préenregistré
classe explicitement en `BLOQUÉ`, jamais en `PASS`.

## Une hypothèse posée puis réfutée

« Le décrochage vient de `mark()`, qui fait une relecture GPU par marqueur. »
Sonde à une seule variable — zéro `F4` : rapport **0,058**. Le décrochage est
là sans une seule capture. **Hypothèse fausse.**

## Ce qui a quand même été observé, sans le surclasser

Piste d'altitude de la sonde, échantillonnée par le moteur :

    repos, aucune entrée   24,0  24,0
    sauts                  25,1  25,1  25,1
    repos, aucune entrée   24,0  24,0

Excursions de la campagne complète : **1,4 / 1,5 / 1,4 m**, autour de l'apex
nominal de **1,401 m** dérivé de `resources/tuning/locomotion_default.tres`
(`jump_velocity = 8.2`, `gravity = 24.0`). État `locomotion` de bout en bout.

C'est une **observation encourageante, pas un `PASS`** : sept échantillons ne
satisfont ni le critère 2c (≥ 20 marqueurs par campagne) ni les trois
répétitions, et aucune affirmation temporelle n'est tirable d'une horloge
décrochée d'un facteur 17.

## Aucun seuil déplacé

Les tolérances du contrat — bruit ≤ 0,10 m, excursion ≥ 0,50 m, retour
≤ 0,20 m, 3 répétitions sur 3, contrôle négatif à zéro — sont **inchangées**
depuis leur écriture, avant toute mesure. Les deux amendements ne portent que
sur l'instrument (cadence mesurée, puis échantillonnage par battement), et le
troisième constate la fermeture.

## Où la vérification appartient

`CLAUDE.md` le disait déjà : rendu logiciel, *« utilisable pour la régression
visuelle, jamais pour une mesure »*. Le saut se vérifie sur une vraie machine,
par `docs/MANUAL_VALIDATION.md`. Le propriétaire dispose du mode dev — `F3`
pour enregistrer, `F4` pour signaler — et son journal porte la position Y du
héros : un aller-retour au sol y sera lisible en quelques secondes, sur une
horloge qui, elle, sera juste.

## Fichiers

- `run3_battement/` — campagne complète : verdict initial du harnais,
  journal DevMode brut, rejugement hors ligne par la logique corrigée (code 3)
- `sonde_horloge_sans_f4/` — sonde à une variable, script, journal, sortie
- `diagnostic/` — cadence de l'appareil mesurée à trois résolutions, sonde
  menu contre monde monté, exécutions bloquées antérieures
