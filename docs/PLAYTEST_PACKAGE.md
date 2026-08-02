# Package de playtest — Éclats d'Orage (nuit V4)

Le package de playtest EST le dépôt à ce commit : il ne contient ni les
archives Quaternius (elles restent dans la Release
`asset-inbox-quaternius-free-v1`), ni aucun fichier > 100 Mo. Un
`git archive HEAD` pèse ~310 Mo et se suffit : la sélection d'assets est
committée, et `docs/assets/PROMOTIONS.csv` + `tools/promote_quaternius.py`
permettent de reconstruire la promotion depuis la Release au besoin.

## 1. Obtenir

```bash
git clone <depot> Zelda && cd Zelda
git checkout claude/phase-0-gate-0-setup-t72ibt
```

## 2. Prérequis

- **Godot 4.7.1-stable exactement** (`godot --version` doit répondre
  `4.7.1.stable...`). Sans binaire : `tools/setup_godot.sh` (~90 min).
- Un poste AVEC écran, clavier AZERTY et si possible manette — c'est
  précisément ce que le conteneur de développement ne peut pas valider.

## 3. Importer puis vérifier

```bash
export GODOT_BIN=/usr/local/bin/godot   # adapter
"$GODOT_BIN" --headless --path . --import        # premier import (long)
tools/validate_fast.sh                            # attendu : VERT, ≥325 tests
```

## 4. Lancer

```bash
"$GODOT_BIN" --path .        # Boot → MainMenu → Nouvelle partie → Vallée
```

Scènes de contrôle directes (F6 dans l'éditeur) :

| Scène | Ce qu'elle montre |
|---|---|
| `scenes/world/valley/ValleyWorld.tscn` | la vallée complète habillée |
| `scenes/tests/SilhouetteLineup.tscn` | héros + 3 pillards (SILHOUETTE_FLAT=1 : aplats) |
| `scenes/tests/AssetGallery.tscn` | galerie paginée (GALLERY_CATEGORY/PAGE) |
| `scenes/tests/CombatLab.tscn` | combat instrumenté |

## 5. Protocole humain

Suivre `docs/MANUAL_VALIDATION.md` (protocole §21.4 prêt à jouer) :
`Q` réellement à gauche en AZERTY, manette, caméra contre les murs,
lisibilité. Points ajoutés par la passe V4 à contrôler des yeux :

1. Vista d'ouverture : citadelle lisible, couloir central dégagé.
2. Descente → camp : le camp semble HABITÉ (chaudron, table, abri).
3. Les quatre structures pénétrables : avant-poste route nord (22,−52),
   abri de rivière (−30,22), sanctuaire de falaise (−108,62 en haut),
   poste de garde citadelle (13,−102) — entrer, prendre la récompense,
   ressortir sans accroc de porte ni de caméra.
4. Silhouettes : les trois pillards se distinguent en jeu, le héros a la
   capuche turquoise de dos.
5. Franchissement (mantle) : le geste ClimbUp_1m se joue, sans glissade.
6. Plat rapide (F) : le geste de consommation se joue à l'arrêt.

## 6. Limites connues de ce package

- Gates dépendant d'un humain : `EN ATTENTE` (jamais déclarés PASS ici).
- Navmesh pré-cuit : les collisions des abris (lot 12) n'y sont pas —
  aucune IA ne fréquente ces zones aujourd'hui.
- Pignons ouverts sous les toits des abris (aucune pièce de gable dans
  les packs) — visible en levant la caméra à l'intérieur.
- Niveaux 6-7 (perf GPU, soak, export) : non exécutables dans le
  conteneur de développement ; aucun FPS annoncé.
