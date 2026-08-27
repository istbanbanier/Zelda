# Éclats d'Orage — checkpoint jouable Lot 1.R.2

**Ce document s'adresse à Istvan.** Il n'y a rien à installer, rien à compiler,
et aucune connaissance technique n'est nécessaire.

| | |
|---|---|
| Version | checkpoint **Lot 1.R.2** |
| `PLAYABLE_SHA` | `@@SHA_LONG@@` <!-- rempli par la CI au moment de la Release, depuis le commit réellement construit --> |
| Court | `@@SHA_COURT@@` <!-- idem — la même valeur que celle du tag --> |
| Dépôt propre à la construction | `repo_dirty: false` |
| Moteur | Godot 4.7.1-stable — **embarqué dans le build, rien à installer** |

## Ce qui est nouveau dans cette version

Les **six lieux du lot 1** ont reçu le verdict visuel et sont désormais **gelés** :
tour de guet, belvédère, champ des mille fleurs, source aux reflets, sanctuaire
forestier, cimetière du tertre. Les trois derniers viennent d'être repris :

- **la source** a gagné une vraie présence — une arrivée d'eau *verticale*, deux
  rives et un déversoir, au lieu d'un cercle de blocs autour d'une flaque ;
- **le sanctuaire** a fait pivoter son axe pour que le seuil, l'allée et le cœur
  se voient dans la même image, sans que l'arbre s'interpose ;
- **le cimetière** a un tertre qui domine, une entrée, et un coffre qui ne vole
  plus la vedette aux pierres.

## 1. Lancer le jeu

### Windows

Décompresser l'archive `EclatsDOrage_Windows_*.zip`, puis double-cliquer sur
`EclatsDOrage.exe`. Windows peut afficher un avertissement « éditeur inconnu » :
c'est normal pour un jeu non signé — *Informations complémentaires* puis
*Exécuter quand même*.

### macOS

Décompresser `EclatsDOrage_macOS_*.zip`. **Clic droit** sur l'application puis
*Ouvrir* (un double-clic simple sera refusé par macOS : le jeu n'est pas signé).

### Linux

Décompresser `EclatsDOrage_Linux_*.zip`, puis :

```bash
chmod +x EclatsDOrage.x86_64
./EclatsDOrage.x86_64
```

### Le projet Godot (facultatif)

`EclatsDOrage_Projet_*.zip` contient les sources. Il faut Godot **4.7.1-stable**
exactement pour l'ouvrir. Ce n'est utile que pour inspecter le projet.

## 2. Les touches — clavier AZERTY

| Action | Touche |
|---|---|
| Avancer / reculer | `Z` / `S` |
| Gauche / droite | `Q` / `D` |
| Regarder | souris |
| Sauter | `Espace` |
| Sprint | `Maj gauche` |
| Interagir | `E` |
| Pause | `Échap` |

Manette prise en charge : stick gauche pour marcher, stick droit pour regarder.

## 3. Ce qu'il y a à voir

Les six lieux du lot 1 sont posés dans la Vallée de Néris et se visitent
librement. Ce sont eux qui viennent d'être travaillés ; le reste du monde est
l'état connu des passes précédentes.

## 4. Ce qui n'est PAS fini — à savoir avant de jouer

C'est un **checkpoint de travail**, pas une démo finie.

- **Réserves de finition connues, consignées et assumées** : la matière de la
  berge de la source reste ambiguë et son voile d'eau montre un jour vu de
  trois-quarts ; l'allée du sanctuaire est visible mais discrète ; l'entrée du
  cimetière est peu affirmée et son coffre reste l'objet le plus coloré du
  cadre. Ces points sont **volontairement** laissés en l'état.
- **25 lieux sur 31 n'ont pas encore été repris** — ils sont dans leur état
  antérieur.
- Il n'y a **ni combat, ni cuisine, ni donjon, ni boss** dans cette version.
- La fluidité n'a **pas** été mesurée sur un vrai PC : ce conteneur n'a pas de
  carte graphique. Si le jeu rame chez vous, c'est une information utile, pas
  une surprise.

## 5. Comment me dire ce qui ne va pas

Ce qui aide le plus : **où** vous étiez, **ce que vous faisiez**, et ce que vous
avez vu. Une capture d'écran vaut dix explications.

- **Windows** : `Win + Impr. écran`, l'image va dans *Images/Captures d'écran*.
- **macOS** : `Cmd + Maj + 4` puis sélectionner la zone.
- **Linux** : touche `Impr. écran`.

Les remarques les plus utiles du projet ont toujours été les plus simples —
« les murs ne sont pas fermés », « je trouve le jeu pas très jouable ». Aucune
compétence technique n'est requise pour signaler ce qui cloche.
