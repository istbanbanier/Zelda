# Preuves du jalon F.3 — salle 2, circuit vertical (§15.6)

Captures produites par `tools/godot/capture_reference.gd` depuis le
renderer réel, en **rendu logiciel** (Xvfb + Mesa llvmpipe) : lisibilité et
régression visuelle seulement, **jamais** une mesure de performance.

| Fichier | Ce qu'il montre |
|---|---|
| `room2_shaft.png` / `.json` | Le puits vu de l'entrée : l'escalier de pierre décalé le long du mur ouest avec ses marques de prise, la ligne cyan du circuit qui part vers les électrodes, l'ascenseur immobile, la source à droite |
| `room2_mezzanine.png` / `.json` | Le haut, après redirection : le levier basculé et allumé, l'anneau du récepteur FERMÉ, la porte ouverte sur le couloir, le câble de la branche ascenseur sous tension |

`--call=capture_state_mezzanine` bascule le levier — le geste exact du
joueur — puis pose le héros là où l'escalade le mène. La suite (courant,
anneau, délai, mécanisme) se déroule seule par le chemin normal.

## Ce que ces images ne prouvent pas

- **Aucune mesure de performance** : llvmpipe, rendu logiciel.
- **Aucun verdict esthétique** : graybox ; l'art est Phase H.
- **Ni l'ergonomie de l'escalade, ni la lisibilité du rythme des
  électrodes** — cela demande un œil et une main humaine. Protocole :
  `docs/MANUAL_VALIDATION.md`. Tant qu'il n'a pas eu lieu, ces critères
  restent `NON VÉRIFIÉ`.
