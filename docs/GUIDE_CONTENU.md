# Guide du contenu — Éclats d'Orage

**Pour qui : le propriétaire du projet, qui n'a jamais fait de jeu vidéo.**

Ce document dit ce que le jeu contient **réellement aujourd'hui**. Chaque chiffre
a été relevé dans le code source ou dans les fichiers de données, pas dans la
documentation. Quand quelque chose existe dans le code mais que le joueur ne peut
pas le rencontrer en jouant normalement, c'est écrit noir sur blanc dans la
dernière section.

- Commit vérifié : `fbfd7bb`
- Dépôt propre au moment de la lecture (aucune modification en attente)
- Moteur : Godot 4.7, rendu Forward+, physique Jolt

---

## 1. Comment le jeu démarre

Le jeu commence par la scène `scenes/boot/Boot.tscn`, qui mène au **menu
principal**. Le menu propose exactement quatre entrées :

| Bouton | Ce qu'il fait vraiment |
|---|---|
| Continuer | recharge la sauvegarde et part dans la Vallée |
| Nouvelle partie | efface la sauvegarde (avec confirmation) et part dans la Vallée |
| Options | sensibilité de la souris, inversion du regard, 3 volumes, rappel des touches |
| Quitter | ferme le jeu |

Un cinquième bouton, « Debug — Audit d'entrée », **n'apparaît pas** sauf si on
lance le jeu avec la variable d'environnement `ECLATS_DEBUG_MENU=1`.

**Le parcours complet du jeu** (chaque flèche = une porte à franchir avec `E`) :

```
Menu → Vallée de Néris
        → (porte de la Citadelle, à x=0, y=37, z=-197,9)
     → Vestibule de la Citadelle
        → Salle 1 (initiation)
     → Salle centrale
        → Salle 2 (puits vertical) / Salle 3 (relais) / Salle 4 (batterie)
     → Antichambre (feu de cuisine + coffre + baies)
     → Arène du Gardien de l'Orage
     → Écran de victoire
```

Le joueur apparaît dans la vallée en `(0 ; 32,3 ; 146)`, sur la crête, dos
tourné vers la citadelle qui est loin devant lui (au nord, vers z négatif).

---

## 2. Le héros et ses commandes

Le héros est un modèle 3D animé (`Male_Ranger`, avec 16 animations : marche,
course, sprint, saut, roulade, coups d'épée, coups reçus, mort, escalade,
interaction, repas…). Il mesure 1,80 m, a **100 points de vie** et **100 points
d'endurance**.

Il commence chaque partie avec **une Épée usée** et **8 flèches**.

### Les touches (clavier AZERTY)

| Action | Touche | Détail |
|---|---|---|
| Se déplacer | Z Q S D | `Q` est bien à gauche |
| Sauter | Espace | saut de ~1,4 m |
| Sprinter | Maj gauche | coûte 12 d'endurance par seconde |
| Interagir (ouvrir, ramasser, cuisiner, actionner) | E | portée 2,2 m, il faut regarder l'objet |
| Attaque légère | Clic gauche | enchaîne 3 coups |
| Attaque lourde | R | coûte 20 d'endurance |
| Garder / parer | Clic droit maintenu (arme de mêlée) | voir plus bas |
| Viser à l'arc | Clic droit (arc équipé) | puis clic gauche pour tirer |
| Esquiver (roulade) | Ctrl gauche | coûte 15 d'endurance, invincible de 0,02 s à 0,27 s |
| Verrouiller une cible | C ou clic molette | |
| Arme précédente / suivante | X / V ou molette | quand aucune cible n'est verrouillée |
| Inventaire | Tab | met vraiment le jeu en pause |
| Manger un plat rapide | F | prend le premier plat de la réserve |
| Pause | Échap | |
| **Bracelet — onde de détection (Pulse)** | **A** | |
| **Bracelet — viser** | **G maintenu** | |
| **Bracelet — agir sur la cible visée** | **G + clic gauche** | |
| **Bracelet — repousser au lieu d'attirer** | **G + Maj + clic gauche** | |
| **Bracelet — mise à la terre (Ground)** | **T** | |

La manette est câblée pour toutes ces actions.

### L'endurance, en détail

| Ce qui la dépense | Coût |
|---|---|
| Sprint | 12 par seconde |
| Escalade verticale | 18 par seconde |
| Escalade latérale | 16 par seconde |
| Saut en escalade | 20 d'un coup |
| Esquive | 15 d'un coup |
| Attaque lourde | 20 d'un coup |
| Arc Step (Bracelet) | 20 d'un coup |

Elle remonte au bout d'1 seconde sans effort, à 22 par seconde. À zéro, le héros
est bloqué 0,45 s et ne peut plus sprinter avant d'avoir récupéré 20 points.

### La garde et la parade

Tenir le clic droit avec une arme de mêlée met le héros en garde, sur un arc de
135° devant lui.

- **Parade parfaite** : si le coup arrive dans les **0,12 première seconde** après
  l'appui, il est renvoyé (40 de dégâts de poise à l'attaquant) et le héros gagne
  0,35 s de « Clarté ». L'**Épée usée** est la seule arme qui allonge cette
  fenêtre (+0,04 s, soit 0,16 s au total).
- **Blocage ordinaire** : si le bouton était déjà tenu, le coup passe à 20 % de
  ses dégâts mais coûte de l'endurance (au moins 6 points).

### La chute et le sauvetage

Si le joueur tombe sous l'altitude −6, le jeu le replace automatiquement au
dernier endroit où il était debout (enregistré toutes les 2 secondes), avec un
fondu à l'écran. Il n'y a pas de mort par chute dans le vide.

---

## 3. Les six armes

Toutes vivent dans `resources/weapons/`. La durabilité se compte en **coups qui
touchent réellement** (frapper dans le vide n'use rien).

| Arme | Dégâts | Durabilité | Portée | Conductivité | Ce qui la rend différente |
|---|---:|---:|---:|---:|---|
| **Gourdin bois** | 8 | 18 | 1,6 m | 0,05 | Sa lourde **projette** : recul de 7 (le plus fort du jeu). Presque pas conductrice → sûre en zone électrique. |
| **Épée usée** | 12 | 24 | 1,7 m | 0,85 | La seule qui **allonge la fenêtre de parade** (+0,04 s). Lourde équilibrée. |
| **Lance** | 10 | 30 | **2,7 m** | 0,70 | La plus longue portée et la plus grande durabilité. Sa lourde **perce vite** (amorce 0,26 s) mais met longtemps à se remettre. |
| **Hache lourde** | 22 | 20 | 1,9 m | 0,80 | Sa lourde **brise les gardes** : 12 de dégâts de posture, assez pour vider la garde d'un Briseur d'un seul coup. Amorce très longue (0,55 s). |
| **Arc simple** | 9 | 28 tirs | à distance | 0,20 | Flèches à 48 m/s avec chute. Une flèche par 0,6 s. |
| **Lame conductrice** | **26** | **16** | 1,8 m | **1,00** | La plus puissante, la plus fragile. Sa lourde **décharge de l'électricité**. Dangereuse près de l'eau ou du boss en surcharge. |

**Attention, un point important** : les trois coups légers (le combo au clic
gauche) sont **identiques pour les cinq armes de mêlée** — c'est le même jeu
d'animations d'épée. Ce qui diffère vraiment entre les armes, c'est **l'attaque
lourde (R)** et les chiffres du tableau.

Le héros peut porter **8 armes maximum**, plus les flèches, les ingrédients et
jusqu'à **6 plats**.

**Quand une arme casse** : sa zone de frappe est coupée, l'exemplaire disparaît
et l'arme suivante est équipée automatiquement. Deux exemplaires d'une même arme
ne partagent jamais leur usure.

---

## 4. Le Bracelet de Résonance — les cinq opérations

C'est la mécanique signature du jeu. Le Bracelet **ne crée jamais d'énergie** :
il déplace ce qui existe déjà.

| Opération | Touche | Ce qu'elle fait | Portée / coût |
|---|---|---|---|
| **Pulse** (onde de détection) | `A` | Fait briller pendant 3 s tout ce qui réagit au Bracelet autour de vous. Ne traverse pas les murs. Fait du **bruit** (les ennemis peuvent l'entendre à 9 m). | 10 m, recharge 1,5 s |
| **Focus** (viser) | `G` maintenu | Sélectionne une cible dans l'axe du regard. `X`/`V` change de cible. Un viseur s'affiche à l'écran (anneau qui se referme sur la cible, losange doublé quand un premier port est retenu, viseur barré en cas de refus). | 18 m, cône de ~75° |
| **Arc Link** (relier) | `G` + clic sur une source, puis `G` + clic sur un récepteur | Crée un fil d'électricité visible entre deux prises. Refuse s'il y a un mur entre les deux. **Un seul lien à la fois** : un nouveau remplace l'ancien. | sélection 16 m, écart max 14 m |
| **Polarité** (attirer / repousser) | `G` + clic (attirer) · `G` + Maj + clic (repousser) | Déplace un objet **en métal et chargé** sans le toucher. Refuse si l'objet est trop lourd (plus de 90 kg), pas en métal, pas chargé, ou trop loin. | 12 m, dure 2,5 s |
| **Arc Step** (bond) | `G` + clic sur un ancrage | Bond physique court vers un ancrage. Vérifie tout le trajet à l'avance : refuse s'il y a un obstacle ou pas de sol à l'arrivée. | 10 m, **20 d'endurance** |
| **Ground** (mise à la terre) | `T` | Vide la charge de l'objet chargé le plus proche. Il faut être **au sol** et **immobile 0,35 s**. Un coup reçu annule l'opération. | 3 m |

Quand une opération est refusée, le jeu dit pourquoi (« hors portée »,
« pas de métal », « trop lourd », « pas de vue », « pas de sol »…).

⚠️ **Voir la section 15** : dans une partie normale, **Arc Step n'a aucune cible**
et **Arc Link n'en a qu'une seule** (le bassin conducteur). Ces opérations ne
sont réellement jouables que dans le terrain d'entraînement, qui n'est pas
accessible depuis le menu.

---

## 5. Les trois Fragments de Résonance

Trois éclats facultatifs, posés chacun près du lieu qui enseigne l'opération
correspondante. Le boss reste battable sans aucun d'eux.

| Fragment | Où le trouver | Ce qu'il change |
|---|---|---|
| **Flux** | Sur l'autel du **Sanctuaire forestier**, site `(34 ; 2 ; 94)` | Une mise à la terre réussie sur une charge significative (≥ 2) **rend 15 points d'endurance**, une fois toutes les 10 s. |
| **Élan** | Au **Pont magnétique**, site `(−34 ; 3 ; 44)` | Un Arc Step conserve **35 %** de sa vitesse à l'arrivée, pour enchaîner. |
| **Écho** | Au **Bassin conducteur**, site `(16 ; 2 ; 28)` | Le Pulse indique la direction du **dernier bruit entendu** (dans les 8 dernières secondes). |

Une fois ramassé, un Fragment est enregistré dans la sauvegarde et ne réapparaît
jamais.

⚠️ **Élan** dépend d'Arc Step, qui n'a pas de cible dans la vallée → il n'a aucun
effet en partie normale. **Écho** émet bien sa direction, mais **rien à l'écran
ne l'affiche** : le signal n'a aucun destinataire dans l'interface.

---

## 6. Les cinq familles d'ennemis

Leurs chiffres vivent dans `resources/enemies/`.

| Famille (nom de code) | Vie | Résistance aux coups (poise) | Vue | Ouïe | Vitesse de poursuite | Ce qui la distingue vraiment |
|---|---:|---:|---|---:|---:|---|
| **Pillard braise** (`raider_red`) | 45 | 20 | 22 m / 95° | 15 m | 5,2 m/s | Le plus faible. **Un seul coup** de gourdin. Recule quand vous esquivez son attaque. **Fuit** quand un allié meurt près de lui. |
| **Pillard azur** (`raider_blue`) | 85 | 30 | 30 m / 105° | 20 m | 5,8 m/s | Lance (portée 2,4 m). **Contourne** au lieu de foncer. **Alerte ses alliés à 14 m**. Ressort de la mêlée entre deux coups. **Esquive** vos attaques lourdes (une fois toutes les 8 s). Le seul à utiliser le module de décision « utility ». |
| **Briseur d'obsidienne** (`raider_black`) | 150 | **60** | 26 m / 90° | 22 m | 5,0 m/s | **Garde frontale** sur 60° qui absorbe 75 % des dégâts, jusqu'à ce que sa jauge de 12 se brise. Combo de 2-3 coups de masse. Très dur à faire chanceler. |
| **Colosse des ravins** (`ravine_troll`) | **420** | **100** | 35 m / 115° | 30 m | 4,8 m/s | ~3,8 m de haut. Tourne très lentement (c'est sa faiblesse). Balayage → frappe verticale enchaînés. **Coup au sol avec onde de choc** (évitable en sautant). **Lance des rochers** entre 6 et 16 m. **Point faible dans le dos : dégâts ×2.** Trop large pour les passages étroits. |
| **Chasseur quadrupède** (`centaur_hunter`) | **650** | 80 | **48 m / 130°** | 38 m | **11 m/s** | Le plus fort, et **facultatif**. **Crie** 0,8 s avant chaque attaque majeure. **Charge en ligne droite** à 15 m/s. **Salve de 3 flèches** puis long repos. Tourne en cercle à moyenne distance. Abandonne la poursuite à la frontière de son territoire. |

Le Colosse et le Chasseur utilisent une **seconde carte de navigation** taillée
pour leur carrure : ils ne peuvent pas emprunter les passages des pillards.

Un « coordinateur de combat » limite le nombre d'ennemis qui attaquent en même
temps.

### Où sont-ils posés, exactement

**12 ennemis** existent dans la vallée. Trois sont dans la scène du camp, neuf
sont posés par le code (`valley_world.gd`, fonction `_spawn_bestiary`). Chacun
fait une petite ronde autour de sa position.

| Ennemi | Position (x ; y ; z) | Où c'est |
|---|---|---|
| Pillard braise ×3 | camp `(45 ; 6 ; 65)`, décalés | Le camp ennemi, sur sa terrasse |
| Pillard azur | `(92 ; 2,1 ; 16)` | Plaine est, vers le pylône |
| Pillard azur | `(58 ; 2,1 ; 30)` | Entre le camp et la rivière |
| Briseur d'obsidienne | `(−104 ; 14,1 ; 62)` | **Sommet de la falaise ouest**, gardien du coffre de la Lame conductrice |
| Colosse des ravins | `(22 ; 2,1 ; −64)` | **Sur l'axe de la rampe du donjon** : impossible de monter sans le voir |
| Chasseur quadrupède | `(150 ; 2,1 ; 52)` | Loin à l'est, à l'écart du chemin |
| Pillard azur | `(26 ; 2,1 ; −118)` | Route du donjon |
| Pillard braise | `(−24 ; 2,1 ; −148)` | Route du donjon, plus au nord |
| Pillard azur | `(15 ; 2,1 ; −99)` | Dans le poste de garde |
| Pillard braise | `(20 ; 2,1 ; −49)` | Dans l'avant-poste |

Un commentaire dans le code explique pourquoi ils sont là : un audit avait montré
qu'on pouvait aller du départ jusqu'au boss **sans jamais croiser un ennemi**.

---

## 7. Les sept ingrédients

Dans `resources/ingredients/`. Le « soin » est le nombre de points de vie rendus.

| Ingrédient | Soin | Famille d'effet | Pile max |
|---|---:|---|---:|
| Fruit de soin | 15 | aucune | 10 |
| Champignon de soin | 10 | aucune | 10 |
| Viande | 20 | **attaque** | 5 |
| Herbe d'endurance | 4 | **endurance** | 10 |
| Racine défensive | 6 | **défense** | 8 |
| Baie de résistance | 5 | **résistance électrique** | 8 |
| Épice rare | 2 | aucune (allonge la durée) | 4 |

### Où ils sont posés dans la vallée

Douze sont posés directement par le code :

| Ingrédient | Position | Lieu |
|---|---|---|
| Fruit de soin ×2 | `(−9 ; 24 ; 153)` et `(7 ; 24 ; 147)` | La crête de départ |
| Herbe d'endurance | `(35 ; 16 ; 109)` | Le palier de la descente |
| Viande | `(50 ; 6 ; 60)` | Le camp ennemi |
| Champignon ×2 | `(68 ; 2 ; 38)` et `(80 ; 2 ; 50)` | La forêt |
| Racine défensive | `(4 ; 2 ; −44)` | Les ruines centrales |
| Baie de résistance | `(96 ; 2 ; 4)` | Près du pylône |
| Épice rare | `(−108 ; 14 ; 62)` | Sommet de la falaise (récompense d'ascension) |
| Viande | `(21,5 ; 2,1 ; −52,5)` | Intérieur de l'avant-poste |
| Fruit de soin | `(−30,4 ; 2,1 ; 22,6)` | Intérieur de l'abri du pêcheur |
| Baie de résistance | `(14,2 ; 2,1 ; −101,7)` | Intérieur du poste de garde |

Neuf autres sont posés comme **récompense de découverte** dans les lieux (voir
section 9), et **quatre baies de résistance** attendent dans l'antichambre du
boss.

Un ingrédient ramassé ne réapparaît jamais.

---

## 8. La cuisine et les plats

Le feu de cuisine du camp est en `(44,6 ; 6,1 ; 63,2)`. Il y en a un second dans
l'antichambre du boss. On y sélectionne **1 à 5 ingrédients**.

### Les règles, au chiffre près

- **Soin** = somme des soins des ingrédients, plafonné à **100**.
- **Effet** = la famille d'effet présente. **Deux familles différentes = « Ragoût
  instable »** : soin réduit à 30 %, aucun effet.
- **Durée** = 60 s + 30 s par ingrédient de la bonne famille + 45 s par épice,
  plafonné à **300 s**.
- Un seul effet actif à la fois : un nouveau plat **remplace** l'ancien.
- La minuterie se suspend quand le jeu est vraiment en pause (inventaire, menu).

### Les six plats possibles

| Nom du plat | Comment l'obtenir | Effet |
|---|---|---|
| **Ragoût du guerrier** | ingrédients « attaque » (viande) | +25 % de dégâts |
| **Potée du rempart** | ingrédients « défense » (racine) | −25 % de dégâts subis |
| **Sauté du grimpeur** | ingrédients « endurance » (herbe) | endurance qui remonte 1,6× plus vite |
| **Confit paratonnerre** | ingrédients « résistance » (baie d'orage) | **−60 % de dégâts électriques** |
| **Plat simple** | seulement des ingrédients sans effet (fruit, champignon, épice) | soigne, rien d'autre |
| **Ragoût instable** | deux familles d'effet mélangées | soigne peu, rien d'autre |

Le Confit paratonnerre est le plat à préparer avant le boss.

---

## 9. Les lieux de la vallée — 33 endroits nommés

Le monde fait 512 × 512 mètres. Chaque lieu se déclare au « journal des
découvertes » quand on y entre pour la première fois : une ligne s'affiche
(« Découvert : … »), une seule fois par partie, et c'est enregistré dans la
sauvegarde.

**31 de ces lieux portent une récompense décrite ligne à ligne dans le code**
(`discovery_rewards.gd`) ; les 2 derniers (Pont magnétique et Bassin conducteur)
reçoivent un coffre par défaut contenant 10 flèches — mais portent chacun un
Fragment de Résonance.

### Villages et hameaux (3)

| Lieu | Position | Récompense |
|---|---|---|
| Village de la rivière | `(−70 ; 2 ; 36)` | **Épée usée** au sol |
| Hameau des bûcherons | `(110 ; 2 ; 40)` | **Gourdin bois** au sol |
| Poste minier de la falaise | `(−68 ; 2 ; 86)` | Coffre, 12 flèches |

### Ruines (4)

| Lieu | Position | Récompense |
|---|---|---|
| Tour de guet effondrée | `(−128 ; 14 ; 82)` | Coffre, 15 flèches |
| Aqueduc ancien | `(−12 ; 2 ; 10)` | **Fragment d'histoire** « Le canal mort » |
| Ferme abandonnée | `(−16 ; 2 ; 78)` | Fruit de soin |
| Caravane foudroyée | `(−38 ; 2 ; −120)` | Coffre, **Lance** |

### Vestiges (6)

| Lieu | Position | Récompense |
|---|---|---|
| Observatoire en ruine | `(76 ; 2 ; 128)` | **Fragment d'histoire** « Relevés de l'orage » |
| Cimetière du tertre | `(58 ; 2 ; −78)` | Coffre, **Hache lourde** |
| Courtine effondrée | `(−104 ; 2 ; −138)` | Coffre, 15 flèches |
| Sanctuaire forestier | `(34 ; 2 ; 94)` | Épice rare + **Fragment Flux** |
| **Pont magnétique** | `(−34 ; 3 ; 44)` | Coffre (10 flèches) + **Fragment Élan** — c'est l'école de la Polarité |
| **Bassin conducteur** | `(16 ; 2 ; 28)` | Coffre (10 flèches) + **Fragment Écho** — c'est l'école de l'Arc Link |

### Grottes (3) — de vrais espaces où l'on entre

| Lieu | Position | Récompense |
|---|---|---|
| Grotte de la cascade | `(−118 ; 2 ; 26)` | Champignon de soin |
| Mine abandonnée | `(160 ; 2 ; −70)` | **Hache lourde** au sol |
| Crypte oubliée | `(−60 ; 2 ; −90)` | Coffre, **Lame conductrice** |

### Souterrains (2)

| Lieu | Position | Récompense |
|---|---|---|
| Passage dérobé de l'Éperon | `(−134 ; 2 ; 122)` | Coffre, 20 flèches — c'est un vrai raccourci : un boyau de 22 m qui monte de 9 m |
| Cavité de cristal | `(−140 ; 2 ; −150)` | Coffre, 20 flèches |

### Repères naturels (5)

| Lieu | Position | Récompense |
|---|---|---|
| L'Arbre doyen | `(−96 ; 2 ; −62)` | Épice rare |
| La Source aux reflets | `(−72 ; 2 ; 78)` | Fruit de soin |
| Le Champ des mille fleurs | `(−34 ; 2 ; 112)` | Herbe d'endurance |
| L'Arche de pierre | `(−21 ; 0 ; 10)` | **Fragment d'histoire** « La marque du passeur » |
| Le Belvédère du guetteur | `(168 ; 0 ; 40)` | **Arc simple** au sol |

### Merveilles (5)

| Lieu | Position | Récompense |
|---|---|---|
| La Chute du Voile (cascade) | `(150 ; 2 ; 118)` | Coffre, 12 flèches |
| Le Cercle des Veilleurs | `(−132 ; 2 ; −28)` | **Fragment d'histoire** « Le cercle qui écoute » |
| La Gorge du Vent (passage) | `(68 ; 2 ; −96)` | Herbe d'endurance |
| Le Bois Courbé | `(−8 ; 2 ; −152)` | Baie de résistance |
| L'Arbre foudroyé | `(−92 ; 2 ; 148)` | Épice rare |

### Territoires ennemis (5)

| Lieu | Position | Récompense |
|---|---|---|
| Camps des pillards braise | `(72 ; 2 ; 112)` | Coffre, **Gourdin bois** |
| Ronde des pillards azur | `(78 ; 2 ; −78)` | Coffre, 20 flèches |
| Bastion des briseurs d'obsidienne | `(−140 ; 2 ; −60)` | Coffre, **Hache lourde** |
| Tanière du colosse des ravins | `(150 ; 2 ; −140)` | Coffre, **Lame conductrice** |
| Territoire du chasseur | `(128 ; 2 ; 150)` | Coffre, **Arc simple** |

⚠️ **Ces cinq « territoires » ne contiennent aucun ennemi.** Ce sont des décors
(camps, bastion, tanière) construits et meublés, mais les douze ennemis du jeu
sont posés ailleurs (voir section 6). Leurs coffres portent la mention
« récompense de combat » dans le code, mais **rien ne les verrouille** : on peut
les ouvrir sans combattre. Le code le reconnaît explicitement
(`deferred_gates()`).

---

## 10. Les coffres, les armes au sol et les autres récompenses

### Les 4 coffres posés à la main dans la vallée

| Coffre | Position | Contenu |
|---|---|---|
| Coffre du camp | `(49 ; 6 ; 63)` | **Hache lourde** + 12 flèches |
| Coffre de la rive | `(13 ; 2 ; 19)` | **Lance** + 6 flèches |
| Coffre du sommet de falaise | `(−110 ; 14 ; 65)` | **Lame conductrice** (gardé par le Briseur) |
| Coffre du pylône | `(110 ; 18 ; −32)` | **Gourdin bois** + 14 flèches |

Plus une **arme au sol** dans le camp : un Gourdin bois en `(43 ; 6 ; 70)`.

### Décompte total du butin

| Type | Nombre |
|---|---:|
| Coffres dans la vallée | **20** (4 posés à la main + 16 sur les lieux) |
| Coffres dans le donjon | **1** (antichambre) |
| Coffre final (après le boss) | **1** |
| Armes posées au sol | **5** |
| Ingrédients à récolter (vallée) | **21** |
| Baies de résistance (antichambre) | **4** |
| Fragments d'histoire à lire | **4** |
| Fragments de Résonance | **3** |

Un coffre ouvert reste ouvert après sauvegarde. Si l'inventaire est plein,
l'ouverture est **refusée entièrement** : rien n'est perdu ni dupliqué.

---

## 11. Le donjon — la Citadelle de l'Œil-Tempête

Six salles, chacune une scène séparée reliée par des portes (`E` pour entrer).

### Le vestibule

Une salle de 22 × 26 m à six colonnes et quatre braseros. Deux portes : le retour
vers la vallée, et la Salle 1.

### Salle 1 — Initiation : « lire une chaîne »

**Ce qu'il faut faire** : une source électrique à l'ouest, un récepteur au nord,
et entre les deux **2,8 m de vide** que le câble ne franchit pas. Il faut
**pousser un bloc de métal de 40 kg** dans le couloir jusqu'à ce qu'il touche les
deux plaques. La lumière cyan parcourt alors le circuit et la porte s'ouvre après
0,9 seconde.

Un bouton de remise à zéro remet le bloc à son point de départ. Des rails
empêchent le bloc de sortir. **La solution est impossible à perdre.**

### Salle 2 — Circuit vertical : « monter et rediriger »

**Ce qu'il faut faire** : l'ascenseur ne marche pas. Il faut grimper le puits par
**trois blocs de pierre décalés** le long du mur ouest, en évitant **trois
électrodes** qui se déchargent 1,1 s puis se taisent 1,7 s (rythme décalé,
observable d'en bas). En haut, un **interrupteur** ferme la branche de
l'ascenseur et coupe celle des électrodes.

Le sommet de chaque bloc sert de corniche de repos. Une jauge d'endurance pleine
suffit. Une chute retombe sur le bloc précédent (3 à 5 m, pas de dégâts).
**L'interrupteur est irréversible** — une fois le courant redirigé, la voie reste
sûre dans les deux sens.

Cette salle alimente le **récepteur ouest** de la salle centrale.

### Salle 3 — Relais rotatifs : « orienter »

**Ce qu'il faut faire** : **quatre colonnes** en carré, chacune avec deux bras de
cuivre qui montrent où sont ses prises. On les fait tourner par quarts de tour.
La ligne cyan s'arrête net au premier relais mal tourné, ce qui dit exactement où
est l'erreur.

Aucun danger dans cette salle : se tromper coûte un quart de tour. Un test
automatique parcourt les 256 configurations possibles et prouve qu'au moins une
résout — et que celle du départ n'en est pas une.

Cette salle alimente le **récepteur nord**.

### Salle 4 — Batterie transportable : « transporter et se protéger »

**Ce qu'il faut faire** : **charger une batterie** à la source, puis la **porter**
jusqu'au socle de la porte, de l'autre côté d'une **nappe d'eau**. Sous tension,
l'eau frappe en continu (12 points par seconde — elle ne tue pas d'un coup).

**Deux solutions marchent** : couper le courant avec le levier (l'eau s'éteint),
ou poser **une planche de bois isolante** sur les berceaux et passer au-dessus.

La batterie qui tombe hors du monde réapparaît **du côté de la charge**. Aucune
porte ne l'enferme du mauvais côté.

Cette salle alimente le **récepteur est**.

### Salle centrale

Trois piliers, trois anneaux, trois récepteurs — **un par salle 2, 3 et 4**. La
salle 1 n'alimente rien : elle est simplement sur le chemin. Une carte murale à
trois lignes s'allume, une par circuit résolu. Quand les **trois** sont
alimentés, la porte du boss monte pour de vrai, sur une galerie six mètres plus
haut atteinte par deux rampes.

### Antichambre du boss

- Un **point de sauvegarde** (l'entrée sauvegarde automatiquement)
- Un **coffre garanti** : Lame conductrice + 12 flèches
- Un **feu de cuisine**
- **Quatre baies de résistance** sur la corniche
- Une **fresque** qui montre, sans un mot : le bâton de bois laisse la ligne
  éteinte, la barre de métal la laisse passer
- Une baie vitrée qui donne sur l'arène et ses quatre pylônes
- La porte du retour n'est jamais verrouillée

---

## 12. Le boss — le Gardien de l'Orage

Un quadrupède mécanique de pierre et de bronze, **560 points de vie**, dans une
arène circulaire de **38 m de diamètre** avec **quatre pylônes de mise à la
terre** à 45°, 135°, 225° et 315°.

Ces 560 PV ne sont pas inventés : un test automatique vérifie que le boss reste
battable avec le seul butin garanti (Lame conductrice, Épée usée, Gourdin), avec
une marge de 35 %. Une première valeur de 900 PV rendait le combat
mathématiquement impossible et a été rejetée.

### Ses trois attaques

| Attaque | Amorce | Dégâts | Poise | Recul | Portée |
|---|---:|---:|---:|---:|---|
| **Griffe** (`combo`) | 0,75 s | ×1,0 | 30 | 4 | 6 m |
| **Arc électrique** (`arc`) | 1,00 s | ×1,3 | 40 | 5 | 3,6 à 14 m — **élément électrique** |
| **Frappe au sol** (`frappe_sol`) | 1,25 s | ×1,5 | 60 | 8 | 6 m — **phase 3 uniquement** |

Le choix des attaques passe par un « directeur » : il ne répète jamais deux fois
la même si une autre est possible, respecte les temps de recharge, et rejoue
exactement la même séquence avec la même graine aléatoire (pour reproduire un
bug).

Après l'introduction, le joueur a **1,5 seconde de répit garanti** avant la
première attaque.

### Les trois phases

**Introduction (5 s)** — animation d'entrée, aucun danger.

**Phase 1 — Armure chargée (100 % → 65 %)**
L'armure divise les dégâts par **5**. Pour la percer, il faut **dresser deux
pylônes** (avec le levier de chaque pylône, touche `E`). Le mât se déploie, son
sabot de cuivre descend sur le rail de terre — c'est un vrai contact physique,
pas un compteur. À la prochaine décharge du Gardien, l'arc part dans la terre :
il s'écroule **6 secondes**, noyau à nu.

*Alternative plus lente* : le boss porte une jauge de **posture de 36**. Trois
attaques lourdes de hache (12 de posture chacune) sans laisser 5 s de répit la
brisent, et exposent le noyau **3,5 secondes**.

**Phase 2 — Surcharge (65 % → 30 %)**
**Deux cristaux conducteurs** poussent sur son dos (**60 PV chacun**). Tant qu'ils
vivent, le Gardien entre en surcharge **4 secondes toutes les 9 secondes**.
Frapper pendant la surcharge avec une **arme conductrice** (Lame conductrice,
Épée usée) **renvoie une décharge sur vous**. Le **bois ne renvoie rien**. Les
cristaux tombent à l'arc ou au corps à corps.

**Phase 3 — Tempête (sous 30 %)**
Vitesse **+15 %**. Charge suivie d'une frappe au sol. Des marques d'impact
apparaissent au sol **0,85 seconde avant l'éclair**. Les fenêtres raccourcissent
sans disparaître.

### Après la victoire

Tous les dangers s'arrêtent, le ciel s'apaise sur 6 secondes (le soleil
réchauffe, l'orage se dissipe), et un **coffre final** apparaît :
**Lame conductrice + 20 flèches**. Au bout de 12 secondes — ou dès qu'on ouvre le
coffre — l'écran de victoire arrive, avec trois choix :

- **Continuer l'exploration** : recharge la vallée, victoire conservée
- **Recommencer** : efface la sauvegarde (confirmation demandée)
- **Menu principal**

En cas de mort, un panneau propose de réessayer : ça recharge **l'arène**, pas la
vallée.

---

## 13. La sauvegarde

Un seul emplacement (`slot0`). Le jeu sauvegarde **tout seul** à chaque : coffre
ouvert, arme ramassée, ingrédient récolté, plat cuisiné ou mangé, effet appliqué
ou expiré, changement de scène.

Ce qui est enregistré :

- position et orientation du héros (le **dernier sol foulé**, jamais une position
  en pleine chute ou dans un mur)
- vie et endurance restantes
- les 8 armes avec leur usure exacte, l'arme équipée, les flèches
- les ingrédients, les plats, l'effet en cours et son temps restant
- les coffres ouverts, les objets ramassés, les ingrédients récoltés
- les lieux découverts
- les Fragments de Résonance détenus
- la victoire sur le boss

Recharger ne soigne pas gratuitement, et un coffre ouvert ne se remplit jamais
une seconde fois.

---

## 14. Les lois de la matière (le « système de réaction »)

Huit profils de matériau pilotent tout ce qui réagit :

| Matériau | Conductivité | Stocke la charge | Inflammable | Fragile |
|---|---:|---:|---:|---:|
| Eau | **1,00** | 0 | non | non |
| Métal | 0,90 | **10** | non | non |
| Terre conductrice | 0,60 | **4** | non | non |
| Organique | 0,20 | 0 | 0,5 | un peu |
| Bois | 0,05 | 0 | **0,8** | 0,4 |
| Pierre | 0,00 | 0 | non | non |
| Céramique | 0,00 | 0 | non | **0,9** |
| Isolant | 0,00 | 0 | 0,1 | 0,3 |

Les états qu'un objet peut porter : mouillé, chargé, mis à la terre, en surcharge,
en feu, fracturé.

---

## 15. ⚠️ Présent dans le code, mais que le joueur ne rencontre PAS en jouant

C'est la section la plus importante de ce document. Tout ce qui suit **existe et
fonctionne**, mais n'est **pas accessible** dans une partie normale lancée depuis
le menu.

### 15.1 Le terrain d'entraînement (confirmé)

`scenes/world/TrainingGrounds.tscn` — une scène qui enseigne **les cinq
opérations du Bracelet côte à côte**, chacune avec un panneau qui donne la
touche, le pourquoi et le comment, et une **lampe de réussite** branchée sur le
vrai signal de l'opération.

**Aucun bouton du menu n'y mène.** Le seul moyen d'y aller est la ligne de
commande :
```
godot --path . scenes/world/TrainingGrounds.tscn
```
C'est le seul endroit du jeu où les cinq opérations du Bracelet sont réellement
utilisables et expliquées.

### 15.2 La monture (confirmé)

`scripts/world/mount.gd` — une monture qui galope à **14 m/s** (contre 9 m/s en
sprint), qu'on enfourche avec `E`, avec descente sécurisée (elle refuse de vous
déposer dans un mur). Elle est instanciée **uniquement** dans
`training_grounds.gd` (ligne 462). Elle n'existe nulle part dans la vallée.

Le code lui-même l'assume : « GRAYBOX ASSUMÉ : la silhouette est faite de
primitives. Aucun quadrupède n'existe dans les kits. »

### 15.3 Le vol libre (confirmé)

`scripts/tools/dev_fly_mode.gd` — la touche **F2** gèle le héros et donne une
caméra libre à 18 m/s (63 m/s en sprint), avec redescente au sol validée. Il est
instancié **uniquement** dans `training_grounds.gd` (ligne 477).

La touche F2 est bien déclarée dans les réglages du jeu, mais **dans la vallée
elle ne fait rien** : aucun nœud `DevFlyMode` n'y est présent pour l'écouter.

### 15.4 Arc Step n'a aucune cible dans le jeu (nouveau)

L'opération Arc Step ne fonctionne que sur des « ancrages » (`arc_anchor`).
Recherche exhaustive dans tout le code : ces ancrages n'existent que dans
**`training_grounds.gd`** et **`resonance_lab.gd`** (une scène de test).

**Il n'y en a aucun dans la vallée, aucun dans les six salles du donjon, aucun
dans l'arène du boss.** L'opération est donc injouable en partie normale, et son
coût de 20 d'endurance ne sera jamais payé.

### 15.5 Le Fragment « Élan » est sans effet (conséquence)

Il conserve 35 % de l'élan **d'un Arc Step**. Puisque Arc Step n'a pas de cible
(15.4), ce Fragment ne change rien en partie normale, même une fois ramassé.

### 15.6 Le Fragment « Écho » n'a pas d'affichage (nouveau)

Le code émet bien un signal `echo_trace` avec la direction du dernier bruit
entendu. Recherche dans toute l'interface : **aucun élément n'écoute ce signal**.
Le Fragment fonctionne, mais **rien à l'écran ne montre la direction**.

### 15.7 Le Bracelet ne fait rien dans le donjon ni chez le boss (nouveau)

Pour qu'une chose soit visée ou révélée par le Bracelet, elle doit porter un
composant `ResonanceTargetComponent`. Recherche exhaustive : ce composant
n'existe que dans 6 fichiers, et **aucun n'appartient au donjon ou à l'arène du
boss**.

Conséquence concrète :

| Opération | Dans la vallée | Dans le donjon | Chez le boss |
|---|---|---|---|
| Pulse (`A`) | révèle les caisses de métal des camps, le tablier du pont magnétique, les nœuds du bassin, le cœur de l'autel | **ne révèle rien** | **ne révèle rien** |
| Focus (`G`) | ces mêmes cibles | **aucune cible** | **aucune cible** |
| Arc Link | **un seul endroit** : le Bassin conducteur | **impossible** | **impossible** |
| Polarité | caisses de métal des camps + tablier du pont magnétique | **impossible** | **impossible** |
| Arc Step | **impossible** | **impossible** | **impossible** |
| Ground (`T`) | cœur de l'autel, tablier, caisses chargées | seulement la planche de la salle 4 | non |

Le donjon et le boss se résolvent donc entièrement avec `E` (leviers, blocs,
batterie) et le combat — jamais avec le Bracelet.

### 15.8 Le pylône de la vallée est un décor (nouveau)

La colonne cyan de 24 m en `(115 ; 18 ; −25)`, censée être « l'école de l'Arc
Link », est faite de six cylindres et d'une sphère. Elle **ne porte aucun nœud
électrique, aucune cible de Résonance, aucune interaction**. On ne peut rien en
faire à part la regarder et ouvrir le coffre posé à côté.

### 15.9 Les cinq territoires ennemis sont vides (nouveau)

Les cinq lieux nommés d'après les familles d'ennemis (Camps des pillards braise,
Ronde des pillards azur, Bastion des briseurs, Tanière du colosse, Territoire du
chasseur) sont bâtis et meublés, mais **`valley_territories.gd` n'instancie aucun
ennemi** — zéro occurrence. Leurs cinq coffres, marqués « récompense de combat »,
**ne sont verrouillés par rien** : on les ouvre en arrivant.

### 15.10 Les quatorze scènes de laboratoire (nouveau)

Elles existent et sont lançables une par une en ligne de commande, mais **aucune
n'est accessible depuis le jeu** : `CombatLab`, `ResonanceLab`, `TraversalCourse`,
`TraversalPlayground`, `TraversalSandbox`, `PhysicsSandbox`, `PipelineLab`,
`AssetGallery`, `AssetCalibration`, `BestiaryLineup`, `SilhouetteLineup`,
`CharacterTurntable`, `CombatDummy`, `HeroShotLab`, `StabilityDolly`,
`VillageShot`, `RewardAnchorShot`, `WeaponShowcase`, `InputAudit`.

### 15.11 Autres écarts constatés

| Constat | Détail |
|---|---|
| **Les combos légers sont identiques** | Les cinq armes de mêlée partagent le même jeu de trois coups légers (l'épée). Seule l'attaque lourde diffère vraiment. |
| **Un seul coffre dans le donjon** | Il est dans l'antichambre. Les salles 1, 2, 3, 4 et la salle centrale n'en contiennent aucun. |
| **Quatre effets de repas, pas cinq** | attaque, défense, endurance, résistance électrique. L'effet « vitalité temporaire » n'existe pas dans le code. |
| **Aucune musique** | Le dossier `assets/audio/music/` est vide. Le jeu contient 21 sons courts (pas, sauts, impacts, coffre, parade, rupture d'arme, interface) et **une** ambiance de vallée. |
| **Une seule icône d'arme** | Seule l'Épée usée a une icône. Les cinq autres n'en ont pas. |
| **Le module de décision « utility »** | Il n'est branché que sur le Pillard azur. Les quatre autres familles ne l'utilisent pas. |

---

## 16. Le mode développement (F3 / F4 / F5)

Il tourne dans **toutes** les scènes du jeu, y compris la vallée. Il est éteint
par défaut.

| Touche | Effet |
|---|---|
| **F3** | ouvre/ferme le panneau et **démarre/arrête l'enregistrement** |
| **F4** | pose un marqueur « ce que je viens de voir ne va pas » + capture d'écran |
| **F5** | capture d'écran seule |

Il enregistre : la scène en cours, la position et l'état du héros, sa vie, son
endurance, les changements de scène, les messages du jeu, les chutes de fluidité
(toute image de plus de 100 ms), les marqueurs, et la configuration matérielle.
Tout part dans `user://dev_sessions/<date-heure>/`, sur votre machine seulement.

Il **ne triche pas** : pas de téléportation, pas d'invincibilité, aucune valeur
de jeu modifiée.

---

## 17. Récapitulatif chiffré

| Élément | Compté |
|---|---:|
| Armes jouables | 6 |
| Familles d'ennemis | 5 |
| Ennemis posés dans la vallée | 12 |
| Opérations du Bracelet | 5 (dont 1 sans aucune cible en jeu) |
| Fragments de Résonance | 3 (dont 1 sans effet, 1 sans affichage) |
| Ingrédients | 7 |
| Plats possibles | 6 |
| Lieux nommés dans la vallée | 33 |
| Coffres au total | 22 |
| Armes posées au sol | 5 |
| Fragments d'histoire à lire | 4 |
| Salles de donjon | 6 |
| Phases de boss | 3 (+ intro, étourdissement, transitions, mort) |
| Attaques du boss | 3 |
| Profils de matériau | 8 |
| Sons | 21 + 1 ambiance, 0 musique |
| Scènes jouables reliées au menu | 9 (menu, vallée, vestibule, 4 salles, salle centrale, antichambre, arène, victoire) |
| Scènes de laboratoire non reliées | 19 |
| Fichiers de test automatiques | 140 |

---

*Document établi par lecture directe du code au commit `fbfd7bb`. Toute
affirmation ci-dessus peut être retrouvée dans un fichier `.gd` ou `.tres` du
dépôt. Aucun chiffre ne vient de la documentation.*
