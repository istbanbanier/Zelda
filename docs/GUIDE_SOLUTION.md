# GUIDE DE SOLUTION — « Éclats d'Orage »

**Du premier écran jusqu'à l'écran de victoire.**

Ce guide a été écrit en lisant le code du jeu, pas la documentation. Chaque
étape est vérifiable dans les scripts (les chemins de fichiers sont donnés).

> Tout ce qui porte la mention **`À VÉRIFIER EN JEU`** a été déduit du code
> sans avoir pu lancer le jeu. C'est probablement juste, mais ce n'est pas
> prouvé.

---

## 0. Avant de commencer

1. Ouvrir le projet dans **Godot 4.7.1** et appuyer sur **F5**
   (ou lancer `godot --path .` dans un terminal).
2. Le jeu démarre sur un écran de test technique, puis affiche le **menu principal**.
3. Cliquer sur **« Nouvelle partie »**.
   - Si une sauvegarde existe déjà, une confirmation est demandée avant de l'écraser.
   - **« Continuer »** est grisé tant qu'aucune partie n'a été sauvegardée.
4. Le chargement de la vallée peut être **long** (jusqu'à une minute selon la
   machine). C'est normal : une barre cyan et un pourcentage s'affichent.
   Un écran noir prolongé **sans** barre serait, lui, un problème.

---

## 1. Les touches (clavier AZERTY)

Le jeu utilise les *positions physiques* des touches : sur un clavier AZERTY,
cela donne bien **ZQSD**.

| Ce que je veux faire | Touche |
|---|---|
| Avancer | **Z** |
| Aller à gauche | **Q** |
| Reculer | **S** |
| Aller à droite | **D** |
| Regarder autour | **souris** |
| Sauter | **Espace** |
| Courir vite (sprint) | **Maj gauche** (maintenue) |
| Interagir / parler / ouvrir / prendre / poser | **E** |
| Coup léger | **clic gauche** |
| Coup lourd | **R** |
| Viser / se garder | **clic droit** (maintenu) |
| Tirer une flèche | **clic droit maintenu + clic gauche** |
| Esquiver (roulade) | **Ctrl gauche** |
| Verrouiller une cible | **C** |
| Cible précédente / suivante | **X** / **V** |
| Inventaire | **Tab** |
| Manger un plat déjà cuisiné | **F** |
| Pause / options | **Échap** |
| Onde du Bracelet (« Pulse ») | **A** |
| Focus du Bracelet | **G** |
| Mise à la terre du Bracelet | **T** |

> **Attention** : la touche du Bracelet est bien le **A** de l'AZERTY
> (elle est déclarée comme la position « Q » d'un clavier QWERTY).

Aucune de ces touches n'est indispensable pour finir le jeu, **sauf**
Z/Q/S/D, la souris, **E**, **Espace**, **clic gauche**, **clic droit** et **Ctrl**.

---

## 2. Le départ : où suis-je, que dois-je voir ?

- **Position de départ : `x = 0`, `y = 32,3`, `z = 146`** — sur la crête,
  32 mètres au-dessus du fond de la vallée.
- Le héros est **de dos** et **regarde déjà dans la bonne direction**.
  (Fichier : `scenes/world/valley/ValleyWorld.tscn`, nœud `SpawnPoint`.)

Ce que vous devez voir, **droit devant vous** :

1. Au premier plan, une **pente d'herbe** qui descend.
2. Au milieu à droite, une **colonne de fumée** qui monte : c'est le
   **camp ennemi** (à environ 90 m).
3. Plus loin à droite, un **pylône** dressé.
4. **Au centre de l'horizon**, une **énorme silhouette de pierre** surmontée
   d'une flèche : la **Citadelle de l'Œil-Tempête**. C'est votre but final.
   Elle est à **environ 350 mètres** de vous.

**Règle simple pour tout le jeu : la citadelle est toujours « tout droit
devant » depuis le point de départ. Ne vous retournez jamais.**

Au bout de quelques secondes, un message apparaît :
« De la fumée s'élève au loin — un campement ? ». Il ne s'affiche qu'une fois,
sur une partie neuve.

---

## 3. La route jusqu'au donjon (≈ 350 m)

Voici la route complète. Les distances sont mesurées **en ligne droite**,
depuis le point de départ.

| Étape | Distance parcourue | Ce que vous croisez |
|---|---|---|
| 1. Descendre la pente d'herbe droit devant | 0 → 86 m | pente douce de 30 m de dénivelé |
| 2. Arrivée dans la plaine du sud | 86 m | terrain plat, herbe |
| 3. Franchir la **rivière** | ≈ 136 m | berges en pente : on descend et on remonte **à pied**, partout |
| 4. Traverser la plaine du nord | 136 → 256 m | **ruines**, un **poste de garde**, des pillards |
| 5. Monter la **grande rampe de pierre** | 256 → 311 m | rampe de 16 m de large, 32 m de montée |
| 6. Traverser le plateau de la citadelle | 311 → 343 m | trois marches basses |
| 7. **Porte de la citadelle** | ≈ 350 m | masse noire encadrée de cyan |

### Détails utiles pendant la descente

- **N'appuyez pas sur Maj (sprint) contre un mur, un arbre ou une maison.**
  Le héros s'accroche automatiquement aux parois si vous poussez contre elles
  en marchant : c'est un défaut connu (`KNOWN_ISSUES.md`, « L'escalade se
  déclenche sans intention »). Si vous vous retrouvez collé à un tronc,
  **relâchez toutes les touches de direction** : vous retombez.
- La rivière se traverse **n'importe où** grâce aux berges en pente, **sauf**
  entre `x = -24` et `x = -4` (sous l'arche de pierre), où le lit est plus
  raide. Restez plutôt vers `x = 0` à `x = 20`.
- **Un colosse (le « Colosse des ravins ») garde l'axe de la rampe du donjon**,
  vers `x = 22, z = -64`. Il a **420 points de vie**. **Vous n'êtes pas obligé
  de le tuer.** Contournez-le largement par la gauche (vers `x = -20`) : il
  possède un territoire borné et abandonne la poursuite.
- Les pillards bleus (85 PV) et rouges (45 PV) rencontrés en chemin peuvent
  aussi être évités en courant.

### Adversaires posés sur la route (pour information)

| Où (x, z) | Qui | Points de vie |
|---|---|---|
| 58, 30 · 92, 16 | Pillard azur | 85 |
| 20, −49 · −24, −148 | Pillard braise | 45 |
| 15, −99 · 26, −118 | Pillard azur | 85 |
| **22, −64** | **Colosse des ravins** | **420** |
| −104, 62 (falaise ouest) | Briseur d'obsidienne | 150 |
| 150, 52 (loin à l'est) | Chasseur quadrupède — **facultatif** | 650 |

---

## 4. Ce qu'il FAUT ramasser avant d'entrer

Vous commencez avec : **une épée usée** (12 de dégâts, 24 utilisations)
et **8 flèches**. **Ce n'est pas suffisant.**

### Obligatoire — sinon le boss est très difficile

#### A. Des flèches. **Beaucoup.**

Au boss, deux cristaux doivent être détruits ; ils sont **à 3,9 m de haut sur
le dos du monstre** : **votre épée ne peut pas les atteindre**, seules les
flèches le peuvent. Chaque cristal a **60 points de vie** et une flèche fait
**9 dégâts** → **7 flèches par cristal, soit 14 flèches minimum**.

| Où | Quoi | Coordonnées |
|---|---|---|
| **Coffre du camp** | Hache lourde + **12 flèches** | `x = 49, y = 6, z = 63` |
| Coffre du gué | Lance + **6 flèches** | `x = 13, y = 2, z = 19` |
| Coffre du pylône | Gourdin + **14 flèches** | `x = 110, y = 18, z = −32` |
| Coffre de l'antichambre | Lame conductrice + **12 flèches** | juste avant le boss |

**Le plus simple : le coffre du camp (12 flèches) + le coffre de
l'antichambre (12 flèches) = 24 flèches**, et le camp est sur votre route.

#### B. Une bonne arme

- **Hache lourde** (22 de dégâts, 20 utilisations) — **coffre du camp**.
  C'est la seule arme dont le coup lourd **casse la garde** du boss.
- **Lame conductrice** (26 de dégâts, 16 utilisations) — offerte
  **gratuitement dans l'antichambre du boss**. Vous n'avez donc **pas** besoin
  d'aller la chercher au sommet de la falaise ouest (`x = −110, y = 14, z = 65`),
  où un Briseur d'obsidienne de 150 PV la garde.
- **Gardez toujours le gourdin de bois** si vous en trouvez un : il ne conduit
  pas l'électricité, et cela sert en phase 2 du boss (voir §11).
  Il y en a un au camp, au sol, en `x = 43, y = 6, z = 70`.

#### C. Des baies d'orage (résistance électrique)

Elles réduisent de **60 %** les dégâts électriques du boss. Elles sont
violet-bleu foncé, en grappes.

| Où | Coordonnées |
|---|---|
| Près du poste de garde, **sur la route** | `x = 14,2 · y = 2,1 · z = −101,7` |
| Près du pylône (détour à l'est) | `x = 96 · y = 2 · z = 4` |
| **Dans l'antichambre du boss : 4 baies** | garanties, sur une corniche |

**Les 4 baies de l'antichambre suffisent.** Vous n'êtes pas obligé de
détourner.

### Recommandé mais facultatif

- **Fruits de soin** sur la crête de départ, à quelques pas :
  `x = −9, z = 153` et `x = 7, z = 147`.
- **Viande** au camp (`x = 50, z = 60`) — sert à cuisiner une potion d'attaque.
- **Champignons** en forêt (`x = 68, z = 38` et `x = 80, z = 50`).
- **Herbe d'endurance** au premier palier de la descente (`x = 35, z = 109`).

### Comment ramasser

Approchez-vous à **moins de 2,2 mètres**, **regardez l'objet**, une invite
apparaît, appuyez sur **E**. Pour les coffres : **E** pour ouvrir, le contenu
part directement dans l'inventaire.

### Comment changer d'arme

**Tab** ouvre l'inventaire, cliquez sur l'arme, puis sur le bouton **« Équiper »**.

---

## 5. Entrer dans le donjon

1. Montez la grande rampe (`x` entre −8 et +8, de `z = −110` à `z = −165`).
2. Traversez le plateau tout droit, montez les **trois marches basses**.
3. Devant vous : une **masse noire encadrée de traits cyan**, sous une arche
   de pierre, entre deux braseros. C'est la porte
   (`x = 0, y = 37, z = −197,9`).
4. Placez-vous devant, à environ **2 mètres**, face à elle → l'invite
   **« Entrer »** apparaît → **E**.
5. Vous arrivez dans le **vestibule** : une salle à colonnes, éclairée
   d'ambre et de cyan.
6. Traversez le vestibule **tout droit** (26 m) jusqu'au fond.
7. Au fond, une seconde porte sombre à veine cyan :
   **E** → « **Entrer dans le donjon** ».

> Il n'y a **aucune énigme** pour ouvrir la citadelle. Elle est ouverte
> depuis le début. Si l'invite n'apparaît pas, c'est que vous êtes trop loin,
> ou pas assez face à la porte, ou qu'un décor bloque la vue.
>
> Pour ressortir à tout moment : la porte au **sud** du vestibule, invite
> « **Sortir** ».

---

## 6. SALLE 1 — L'initiation

**Fichier de référence : `scripts/dungeon/room1_initiation.gd`.**

### La règle

Le courant doit former **une chaîne ininterrompue** de la source jusqu'au
récepteur. Un **objet en métal** peut servir de maillon.

### Ce que vous voyez en entrant

- Vous arrivez au sud (`x = 0, z = 11`).
- À gauche, contre le mur ouest : un **socle qui pulse en cyan** = la **source**.
- Une **ligne de câbles cuivre au sol** part de la source vers le centre…
  **et s'arrête net**. Il y a **2,80 m de vide** entre deux plaques dressées.
- Au fond à droite, près de la porte : un **anneau ouvert** = le **récepteur**.
- **Devant vous, à 8 mètres : un gros cube de métal gris clair**
  (`x = 0, y = 0,8, z = 3`), posé entre **deux rails de cuivre au sol** et
  fléché par **trois chevrons**.

### LA SOLUTION

1. **Marchez** (n'utilisez pas le sprint) contre la face du cube, en poussant
   vers le fond de la salle (**Z** enfoncé).
2. **Poussez-le tout droit sur 7 mètres**, en suivant les rails.
   Vous poussez en **entrant simplement dedans en marchant** — il n'y a
   aucune touche à presser.
3. Une **butée de cuivre** l'arrête **exactement à la bonne place**, pile
   entre les deux plaques. Vous **ne pouvez pas** aller trop loin.
4. La ligne cyan se propage : source → câbles → plaque gauche → **le cube** →
   plaque droite → câbles → récepteur.
5. L'anneau du récepteur **se ferme**. Après **0,9 seconde**, la **porte du
   fond monte**.
6. Passez dessous, longez le couloir, et au bout :
   **E** → « **Entrer dans la salle centrale** ».

### Si ça coince

- **Le cube est parti de travers ?** Un **bouton de réinitialisation** est
  posé à gauche de l'entrée (`x = −3,6, z = 6`), sur une dalle ivoire.
  **E** dessus : le cube revient à son point de départ.
- Le cube pèse 40 kg et va **au maximum à 2,2 m/s** : c'est lent, c'est normal.
- **La porte, une fois ouverte, le reste pour toujours** — même après une
  sauvegarde ou un aller-retour.

---

## 7. LA SALLE CENTRALE (première visite)

**Fichier : `scripts/dungeon/central_hall.gd`.**

Grande salle de 30 × 30 m sur deux niveaux.

### Ce qu'il y a dedans

- **Trois piliers** portant chacun un **anneau ouvert** (récepteur), à
  `x = −9`, `x = 0` et `x = +9`.
- Sur le mur ouest, un **panneau à trois lignes** : c'est la « carte » du
  donjon. Chaque ligne s'allume quand un circuit est alimenté.
- **Quatre portes au sol** :
  - **Sud** (`z = +15,4`) : retour à la salle 1.
  - **Ouest** (`x = −15,4`) : « **Entrer dans le puits** » → **Salle 2**.
  - **Nord** (`z = −15,4`) : « **Entrer dans la salle des relais** » → **Salle 3**.
  - **Est** (`x = +15,4`) : « **Entrer dans la salle du canal** » → **Salle 4**.
- **Deux rampes inclinées**, à gauche et à droite (`x = ±12,5`), qui montent
  **6 mètres** vers une **galerie**.
- Sur la galerie : la **porte du boss**, énorme (8 m de large).

### Ce qui ouvre la porte du boss

**Les trois anneaux doivent être allumés en même temps.** Chaque anneau est
alimenté par **une salle résolue** :

| Anneau | Alimenté par |
|---|---|
| Ouest (`x = −9`) | **Salle 2** — le puits vertical |
| Nord (`x = 0`) | **Salle 3** — les relais rotatifs |
| Est (`x = +9`) | **Salle 4** — la batterie |

> **La salle 1 n'alimente aucun anneau.** Elle est simplement sur le chemin.
> C'est voulu et documenté dans le code.

**Il faut donc résoudre les salles 2, 3 et 4.** L'ordre n'a aucune importance.

---

## 8. SALLE 2 — Le puits vertical (porte OUEST)

**Fichier : `scripts/dungeon/room2_vertical.gd`.**

### La règle

Le courant part **dans les électrodes**. Il faut **le détourner vers
l'ascenseur** grâce à un levier situé **tout en haut**.

### Ce que vous voyez

- Un **puits de 22 mètres de haut**.
- **Contre le mur de gauche** (le mur ouest), **trois gros blocs de pierre
  décalés en escalier** :
  - **Bloc A** : haut de **5,5 m**, le plus proche de vous.
  - **Bloc B** : haut de **11 m**, décalé de 3 m vers le fond.
  - **Bloc C** : haut de **16,2 m**, encore 3 m plus loin.
  Des **repères de cuivre** marquent les prises.
- **Trois électrodes** cyan, une par bloc, qui **crépitent par intermittence**.
- Au sol au centre : une **plateforme d'ascenseur**, **immobile**.
- Tout en haut, une **mezzanine** avec un **levier**.
- Le mur de gauche et le mur de droite sont **inescaladables**. Seuls les
  **blocs** peuvent être grimpés.

### Le rythme des électrodes — le point clé

Chaque électrode suit **toujours le même cycle** :

- **1,1 seconde de décharge** (dangereux, impossible de grimper) ;
- **1,7 seconde de calme** (fenêtre de passage).
- Cycle complet : **2,8 secondes**.
- Les trois sont **décalées de 0,9 s** l'une par rapport à l'autre : elles ne
  crépitent jamais en même temps.

**Restez en bas, regardez, comptez.** Une électrode allumée rend son bloc
temporairement impossible à saisir.

### LA SOLUTION

1. Allez au **pied du bloc A**, contre le mur de gauche.
2. **Attendez que l'électrode A s'éteigne.**
3. **Marchez** (pas de sprint) contre la face du bloc en maintenant la
   direction **une bonne demi-seconde** : le héros s'accroche.
4. Montez avec **Z**. La montée coûte **18 points d'endurance par seconde** ;
   un bloc de 5,5 m prend ~2,8 s, soit **50 points sur 100**.
5. Arrivé en haut, le héros **se hisse tout seul** sur le sommet du bloc.
6. **Reposez-vous sur le sommet** : l'endurance remonte de 22 points par
   seconde, une jauge pleine en ~2,5 s.
7. Recommencez pour le **bloc B**, puis pour le **bloc C**, en attendant à
   chaque fois la fenêtre de calme.
8. Depuis le sommet du bloc C (16,2 m), **enjambez** vers la **mezzanine**
   (16,5 m) : c'est une marche de 30 cm, elle se franchit en marchant.
9. Sur la mezzanine, cherchez le **levier** (`x = −3,6, z = −2`).
   **E** → « **Rediriger le courant** ».
10. Immédiatement : les électrodes **s'éteignent définitivement**, la colonne
    de câbles de droite **s'allume**, l'**ascenseur démarre** et la **porte du
    fond s'ouvre** (0,8 s de délai).
11. Prenez le couloir au fond :
    **E** → « **Rejoindre la salle centrale** ».

### Si ça coince

- **Le levier n'est pas réversible.** Une fois basculé, la voie reste sûre
  dans les deux sens. **C'est voulu**, ce n'est pas un bug.
- **Vous tombez ?** Les blocs étant décalés, une chute vous rattrape en
  général sur le toit du bloc précédent (3 à 5 m, **sous le seuil de dégâts**).
- **Un bouton en bas** (`x = 4, z = 5,6`) : **E** → « **Rappeler l'ascenseur** »
  si la plateforme est restée en haut.
- **Endurance à zéro pendant l'escalade = vous lâchez le mur.** Reposez-vous
  toujours sur un sommet de bloc avant le segment suivant.
- **Une fois le levier basculé, l'ascenseur fait la navette** (1,8 m/s, avec
  2,5 s d'attente à chaque bout) : plus besoin de grimper pour revenir.

---

## 9. SALLE 3 — Les relais rotatifs (porte NORD)

**Fichier : `scripts/dungeon/room3_relays.gd`.**

### La règle

Chaque colonne porte **deux bras de cuivre en équerre** (un « coude »).
Le courant ne passe d'un segment au suivant **que si deux bras se font face**.
Chaque appui sur **E** fait tourner la colonne **d'un quart de tour**
(dans le même sens, toujours).

### Ce que vous voyez

Vous entrez par le sud. **Tournez-vous vers le fond de la salle**, et
gardez cette orientation pour tout ce qui suit :

- **À gauche** : la **source** qui pulse (`x = −7,6`).
- **À droite** : le **récepteur** et sa porte (`x = +6,6`).
- **Quatre colonnes** de métal, en carré, hautes de 2,2 m :

```
            FOND DE LA SALLE
   [ A ] ................... [ D ]     ← les deux colonnes du FOND
 source →                        → récepteur / porte

   [ B ] ................... [ C ]     ← les deux colonnes PROCHES

            ENTRÉE (vous)
```

- **A** = fond-gauche · **B** = proche-gauche · **C** = proche-droite ·
  **D** = fond-droite.
- Un **câble au sol relie** : source → A, puis A → B, puis B → C,
  puis C → D, puis D → récepteur.

### LA SOLUTION (vérifiée dans la géométrie du code)

Appuyez sur **E** le nombre de fois indiqué, sur chaque colonne :

| Colonne | Nombre d'appuis sur **E** | Orientation finale des deux bras |
|---|---|---|
| **A** (fond-gauche) | **2 fois** | un bras vers **la gauche**, un bras vers **l'entrée** |
| **B** (proche-gauche) | **3 fois** | un bras vers **le fond**, un bras vers **la droite** |
| **C** (proche-droite) | **1 fois** | un bras vers **le fond**, un bras vers **la gauche** |
| **D** (fond-droite) | **1 fois** | un bras vers **l'entrée**, un bras vers **la droite** |

*(Techniquement : positions finales `A=2, B=0, C=1, D=3` ; positions de
départ `A=0, B=1, C=0, D=2`.)*

**Il n'y a pas d'ordre imposé.** Faites-les dans l'ordre que vous voulez.

### Comment savoir que vous progressez

**La ligne cyan avance.** À chaque colonne correctement orientée, le
segment de câble suivant s'allume. **Si la lumière s'arrête à une colonne,
c'est celle-là qui est mal tournée.** C'est le seul indice dont vous avez
besoin.

Quand les quatre sont bonnes, l'anneau du récepteur se ferme, et la
**porte est** s'ouvre après 1 seconde.

### Si ça coince

- **Bouton de réinitialisation** à gauche de l'entrée (`x = −3, z = 8`) :
  **E** → « **Réinitialiser les colonnes** ». Les quatre colonnes reprennent
  leur position de départ, et vous pouvez recommencer le tableau ci-dessus.
- **Une seule rotation à la fois** : la colonne met 0,35 s à tourner et
  refuse un second appui pendant ce temps. Appuyez posément.
- **Aucun danger dans cette salle.** Se tromper ne coûte qu'un quart de tour.

---

## 10. SALLE 4 — La batterie et l'eau (porte EST)

**Fichier : `scripts/dungeon/room4_battery.gd`.**

### La règle

**L'eau conduit le courant.** Sous tension, elle blesse (12 points par
seconde). **Le côté droit de la salle n'a aucune source** : seule la
**batterie** peut y apporter le courant.

### Ce que vous voyez

- La salle est coupée en deux par un **canal de 6 m de large**, rempli d'eau
  sombre, avec un **petit îlot de pierre au milieu**.
- **Berge de gauche** (là où vous arrivez) :
  - la **batterie**, une caisse sombre (`x = −9,5, z = 2`) ;
  - un **berceau de charge** avec quatre montants (`x = −8, z = 0,5`) ;
  - la **source** et un **levier** (`x = −11,5, z = −6`) ;
  - une **planche de bois** (`x = −6, z = 3,5`) ;
  - un **bouton de réinitialisation** (`x = −11, z = 3`).
- **Berge de droite** :
  - un **second berceau** (`x = +7, z = −2`) ;
  - le **récepteur** et la **porte** (`x = +11` et `+13`).

### LA SOLUTION — dans cet ordre exact

1. **Prenez la batterie** : approchez-vous, **E** → le héros la porte devant lui.
2. **Portez-la jusqu'au berceau de charge** (`x = −8, z = 0,5`), placez-vous
   juste devant, face à lui, et **appuyez sur E pour la poser**.
   Elle se **cale toute seule** dans le berceau.
3. **Attendez environ 4 secondes.** La batterie **devient cyan et lumineuse** :
   elle est chargée (24 points de réserve par seconde, capacité 90).
4. **Reprenez la batterie** : **E**.
5. ⚠️ **MAINTENANT SEULEMENT**, allez au **levier** (`x = −11,5, z = −6`) :
   **E** → « **Couper le courant** ». **L'eau cesse d'être dangereuse.**
   *(Si vous coupez avant l'étape 3, la batterie ne se chargera pas.)*
6. **Traversez le canal en deux sauts** :
   - du **bord de la berge gauche** vers **l'îlot central** : **2,25 m** ;
   - de **l'îlot** vers la **berge droite** : **2,25 m**.
   Prenez un peu d'élan, **Espace**. Le héros saute largement plus loin que
   cela (environ 4 m en course).
7. **Portez la batterie jusqu'au second berceau** (`x = +7, z = −2`),
   placez-vous devant et **E** pour la poser.
8. Elle se cale, le **courant repart**, le **récepteur s'allume**, et la
   **porte de droite s'ouvre** (0,7 s).
9. Prenez le couloir :
   **E** → « **Rejoindre la salle centrale** ».

### Notes importantes

- **La batterie tient 90 secondes de décharge.** Vous avez tout le temps.
- **La porte, une fois ouverte, le reste** — même si vous reprenez la batterie.
- **Si la batterie tombe dans le canal**, elle **réapparaît toute seule**
  du côté de la charge après 1 à 2 secondes. Vous ne pouvez pas la perdre.
- **Bouton de réinitialisation** (`x = −11, z = 3`) : **E** →
  « **Rappeler la batterie** ».
- **La planche de bois** est censée offrir une seconde solution (un pont
  isolant). **En lisant le code, ses deux emplacements de pose sont
  positionnés du mauvais côté** : ils la placent **sur les berges**, pas
  au-dessus du canal (`room4_battery.gd`, `seat_offset = 1,125 × côté`,
  ce qui l'éloigne du canal au lieu de l'en rapprocher). **La planche ne
  forme donc probablement pas de pont.** `À VÉRIFIER EN JEU` — mais la
  méthode du saut par l'îlot, elle, fonctionne, alors **ignorez la planche**.
- **⚠️ Si vous tombez dans le canal** : il n'y a **aucun filet de sauvetage**
  dans le donjon. Le fond est à 1,40 m sous les berges — c'est exactement la
  hauteur maximale de votre saut. Deux façons de sortir : **sauter** vers
  l'îlot ou la berge, ou **s'accrocher à la paroi** (marcher contre elle et
  maintenir la direction, puis **Z** pour monter). **C'est pour cela qu'il
  faut couper le courant avant de traverser** : sans courant, l'eau est
  totalement inoffensive et vous avez tout le temps de remonter.

---

## 11. RETOUR À LA SALLE CENTRALE — Ouvrir la porte du boss

1. Une fois les **salles 2, 3 et 4** résolues, revenez dans la salle centrale.
2. **Regardez les trois piliers** : les **trois anneaux doivent être fermés
   et cyan**, et les **trois lignes du panneau mural** allumées.
3. La **porte du boss s'ouvre alors toute seule**, sur la galerie, 6 mètres
   plus haut (1,2 s de délai, puis 3 secondes de montée — c'est une porte
   monumentale, elle prend son temps).
4. **Montez par une des deux rampes inclinées** (`x = −12,5` ou `x = +12,5`).
   Elles font 37° : **on les monte en marchant**, il n'y a rien à escalader.
5. Sur la galerie, franchissez le seuil :
   **E** → « **Franchir le seuil** » → **l'antichambre**.

### Si les anneaux ne s'allument pas

La salle centrale **relit le fichier de sauvegarde** pour savoir quelles
salles sont résolues. Une salle compte comme résolue si elle a écrit
`solved`, `rerouted` **ou** `door_open`. Si un anneau reste éteint alors que
vous avez résolu la salle :

1. **Retournez dans la salle concernée** (les portes de la salle centrale y
   mènent toutes) et vérifiez que **sa porte est bien ouverte**.
2. Ressortez par la porte du fond, pas par celle de l'entrée.
3. Revenez dans la salle centrale : l'état est relu au chargement de la scène.

---

## 12. L'ANTICHAMBRE — la préparation (ne la ratez pas)

**Fichier : `scripts/dungeon/antechamber.gd`.**

C'est votre **dernier point de sauvegarde** avant le boss. Prenez le temps.

### Ce qu'il y a dedans

| Quoi | Où (coordonnées locales) |
|---|---|
| **Un coffre garanti** : **lame conductrice + 12 flèches** | `x = 5, z = 3` |
| **Un feu de cuisine** | `x = −3,5, z = 4,5` |
| **4 baies d'orage** sur une corniche | `x = 1,2 à 3,9 · z = 6,2` |
| **Une fresque** qui montre bois = isolant, métal = conducteur | mur de gauche |
| **Une baie vitrée** sur l'arène et ses 4 pylônes | mur du fond |
| Porte de retour vers la salle centrale | mur du sud |
| Porte vers l'arène | mur du fond, **à droite** |

### ⚠️ L'ORDRE EST IMPORTANT — piège réel dans le code

Le « point de reprise » (checkpoint) est écrit **en entrant** dans
l'antichambre, **et une seconde fois quand vous ouvrez le coffre** —
mais **pas quand vous cuisinez**. Or l'arène **restaure ce point de reprise**
et **écrase votre inventaire avec lui**.

**Conséquence : si vous cuisinez APRÈS avoir ouvert le coffre, votre plat
sera effacé en entrant dans l'arène.**

**Faites donc exactement ceci :**

1. **Ramassez les 4 baies d'orage** (**E** sur chacune).
2. **Allez au feu de cuisine** → **E** → « **Cuisiner** ».
3. Dans le menu : **cliquez sur les 4 baies d'orage** (1 à 5 ingrédients
   autorisés), puis **confirmez**.
   → Vous obtenez un **« Confit paratonnerre »** :
   **−60 % de dégâts électriques pendant 180 secondes**.
   *(Règle : 60 s de base + 30 s par ingrédient compatible.)*
   → **Ne mélangez pas** avec de la viande ou de la racine : deux familles
   d'effets différentes donnent un « **Ragoût instable** » sans aucun effet.
4. **Cuisinez un second plat si vous avez d'autres ingrédients**
   (fruits + champignons = soin pur, sans effet, mais utile).
5. **SEULEMENT MAINTENANT : ouvrez le coffre** (**E**) →
   lame conductrice + 12 flèches. **C'est cette action qui enregistre
   définitivement tout ce que vous portez.**
6. **Équipez-vous** : **Tab** → sélectionnez la **hache lourde** →
   « **Équiper** ».
   *(La hache est le meilleur départ ; on changera pour la lame conductrice
   quand le noyau du boss sera à nu.)*
7. **Vérifiez votre inventaire** : au moins **2 armes**, **14 flèches ou
   plus**, **1 plat de résistance électrique**.
8. Franchissez la porte du fond à droite :
   **E** → « **Entrer dans l'arène** ».

> Vous pouvez **revenir** dans l'antichambre depuis l'arène à tout moment
> (porte au sud de l'arène) pour cuisiner à nouveau. **Mais rouvrez alors le
> coffre… qui sera déjà ouvert.** `À VÉRIFIER EN JEU` : dans ce cas, le
> checkpoint ne sera peut-être pas réécrit et le nouveau plat sera perdu.
> **Le plus sûr reste de tout préparer du premier coup.**

---

## 13. LE BOSS — Le Gardien de l'Orage

**Fichiers : `scripts/boss/storm_guardian.gd` et `scripts/boss/boss_arena.gd`.**

### La bête

- **560 points de vie.**
- Quadrupède mécanique de **9,6 m de long**, **5,6 m de haut**.
- Il frappe de **22 à 33 points** par coup. Vous en avez **100**.
  **Quatre coups vous tuent.** Ne restez jamais planté devant lui.
- Il ne quitte jamais l'arène et ne peut pas vous pousser à travers le mur.

### L'arène

- Un **disque de 38 m de diamètre**, avec **trois zones au sol** de teintes
  différentes : le centre (0 à 6 m), l'anneau de combat (6 à 14 m) et la
  **marge extérieure (14 à 19 m) = zone de repli**.
- **Quatre pylônes** à 14 m du centre, en diagonale. Chacun a **un levier
  à son pied**.
- Vous entrez par le **sud** ; le Gardien vous attend au **nord**, à 23 m.
- **Les deux pylônes les plus proches de l'entrée sont sur votre chemin.**

### ⏱️ Les 5 premières secondes

Le Gardien joue une **animation d'éveil de 5 secondes**, puis vous accorde
**1,5 seconde de répit** supplémentaire.

**Utilisez ces 6,5 secondes pour dresser les DEUX pylônes du sud.**
Ils sont à `x ≈ +9,9, z ≈ +9,9` et `x ≈ −9,9, z ≈ +9,9`.

### Le mécanisme central : la MISE À LA TERRE

C'est **la clé de tout le combat**.

1. **Dressez deux pylônes** : allez au pied d'un pylône, **E** →
   « **Dresser le pylône** ». Le mât **se déploie** (6 m de haut) et son
   **noyau s'allume en cyan**. Répétez sur un second pylône.
2. **Placez-vous à 6-12 mètres du Gardien** — ni collé, ni très loin.
   *(Techniquement : entre 3,6 m et 14 m, il choisit son attaque « arc ».)*
3. **À sa prochaine décharge électrique**, l'arc part **dans les pylônes**
   au lieu de partir dans vous.
4. **Le Gardien s'écroule pendant 6 secondes.** Son **armure s'ouvre** et
   son **NOYAU CYAN s'allume au niveau de la poitrine, à l'AVANT**.
5. **Courez au noyau et frappez-le.**
   Le noyau prend **2,5 fois les dégâts**. Avec la **lame conductrice**
   (26 de dégâts), un coup léger fait environ **65 points**.
6. **Les deux pylônes se déchargent après chaque mise à la terre.**
   Il faut les **re-dresser** à chaque fois (les quatre sont disponibles).

**Boucle à répéter jusqu'à la victoire :**
> dresser 2 pylônes → se tenir à 6-12 m → l'arc part dans la terre →
> 6 secondes pour frapper le noyau → recommencer.

### Pourquoi ne pas simplement le frapper ?

Tant que l'**armure est intacte**, son corps ne prend que **20 %** des dégâts.
Avec la hache lourde (22), un coup lourd (× 2,0) ne lui fait que **8,8 points**
sur 560. **C'est perdu d'avance.** Le noyau, lui, encaisse **65 points par
coup**. Toute la difficulté du combat est là.

### Méthode de secours : casser sa garde (plus lente)

Si vous n'arrivez pas à déclencher la mise à la terre :

- **La hache lourde** (**R**, coup lourd) inflige **12 points de « posture »**.
- Sa jauge de posture est de **36** → **trois coups lourds de hache**
  enchaînés (sans laisser 5 secondes de répit entre eux) **brisent sa garde**.
- Le noyau s'expose alors **3,5 secondes** au lieu de 6.
- Chaque coup lourd coûte **20 points d'endurance**.

---

### PHASE 1 — de 100 % à 65 % de sa vie (560 → 364)

- **Ce qu'il fait** : une courte série de griffes au contact, un **arc
  électrique** à distance, et une frappe de zone.
- **Ce qui le rend vulnérable** : **la mise à la terre par deux pylônes.**
- **Vos armes** : la **hache lourde** pour la posture ; la **lame conductrice**
  quand le noyau est à nu.
- **Comment survivre** : ses attaques annoncent leur coup **0,75 à 1,25 s
  à l'avance**. **Esquivez (Ctrl) sur le côté** — vous êtes invulnérable de
  0,02 s à 0,27 s après l'appui. Ou **maintenez le clic droit** pour vous
  garder : vous ne prenez plus que **20 %** des dégâts.

### PHASE 2 — de 65 % à 30 % (364 → 168) : LA SURCHARGE

Une transition de 2 secondes, puis :

- **DEUX CRISTAUX CONDUCTEURS apparaissent sur son dos**, à **3,90 m de haut**.
- ⚠️ **Votre épée ne peut PAS les atteindre.** Ils sont hors de portée de
  toute attaque au corps à corps, même en sautant.
  **→ IL FAUT LES ABATTRE À L'ARC.**
  - Maintenez le **clic droit** (viser), puis **clic gauche** (tirer).
  - **60 points de vie chacun**, **9 points par flèche** → **7 flèches
    chacun, 14 au total.**
  - Reculez dans la marge extérieure (14-19 m) et tirez pendant qu'il
    approche.
- **Quand les DEUX cristaux sont détruits, son armure tombe DÉFINITIVEMENT**
  et le noyau reste exposé pour le reste du combat. **C'est le vrai
  tournant du combat.**
- ⚠️ **LA SURCHARGE** : toutes les 9 secondes environ, il entre en surcharge
  pendant 4 secondes (il crépite).
  **Le frapper avec une arme métallique pendant ce moment vous renvoie une
  décharge.**

  | Arme | Conductivité | Décharge subie |
  |---|---|---|
  | Lame conductrice | 1,00 | **14 points** |
  | Épée usée | 0,85 | 12 points |
  | Hache lourde | 0,80 | 11 points |
  | Lance | 0,70 | 10 points |
  | **Gourdin de bois** | **0,05** | **aucune** (seuil à 0,50) |

  **Deux parades** : soit **passer au gourdin de bois** pendant la surcharge,
  soit **avoir mangé le Confit paratonnerre** (−60 % → la décharge tombe à
  **5,6 points**), soit simplement **ne pas le frapper** pendant ces
  4 secondes.

- **La mise à la terre par les pylônes fonctionne toujours** en phase 2.

### PHASE 3 — sous 30 % (168 points restants) : LA TEMPÊTE

- Il devient **15 % plus rapide** (pas plus).
- Il charge, puis **frappe le sol**.
- **Des marques apparaissent au sol 0,85 seconde AVANT l'éclair.**
  **Dès que vous voyez une marque sous vos pieds : bougez.** C'est largement
  suffisant.
- Ses fenêtres d'attaque sont plus courtes, **mais elles existent toujours**.
- **Si vous avez détruit les deux cristaux, il n'a plus d'armure du tout** :
  frappez-le en continu, son corps encaisse alors 60 % des dégâts au lieu
  de 20 %.
- Si vous ne les avez pas détruits, **continuez la boucle des pylônes**.

### Si vous mourez

Un panneau s'affiche avec « **Réessayer** ».
**Cliquez dessus : vous recommencez le combat directement**, avec
**exactement l'équipement du point de reprise de l'antichambre** et
**toute votre vie**. Vous ne repartez **pas** de la vallée.

---

## 14. LA VICTOIRE

Quand les 560 points de vie tombent à zéro :

1. Tous les dangers et projectiles **s'arrêtent net**.
2. Le Gardien **s'écroule**.
3. **Le ciel s'apaise** progressivement pendant 6 secondes : la lumière
   redevient chaude, le brouillard tombe, le cyan s'éteint.
4. **Un coffre final apparaît au centre de l'arène**, à `x = 0, z = −2`,
   entouré d'un halo turquoise. Il contient une **lame conductrice** et
   **20 flèches**.
5. **Deux façons de déclencher l'écran de victoire :**
   - **attendre 12 secondes** en regardant la scène, **ou**
   - **ouvrir le coffre final** (**E**) — cela passe la fin immédiatement.
6. **L'ÉCRAN DE VICTOIRE s'affiche**, avec trois choix :
   - **Continuer l'exploration** → recharge la vallée, victoire conservée ;
   - **Recommencer** → efface la sauvegarde (confirmation demandée) ;
   - **Menu principal**.

**Vous avez fini le jeu.**

---

## 15. Où peut-on rester bloqué, et comment s'en sortir

### Les boutons de secours

| Salle | Bouton | Où | Ce qu'il fait |
|---|---|---|---|
| Salle 1 | « Réinitialiser » | `x = −3,6, z = 6` | ramène le cube à son départ |
| Salle 2 | « Rappeler l'ascenseur » | `x = 4, z = 5,6` | fait redescendre la plateforme |
| Salle 3 | « Réinitialiser les colonnes » | `x = −3, z = 8` | remet les 4 relais au départ |
| Salle 4 | « Rappeler la batterie » | `x = −11, z = 3` | ramène batterie et planche |

**Aucun bouton de réinitialisation ne referme jamais une porte déjà ouverte.**
C'est garanti dans le code : les portes se « verrouillent » en position ouverte.

### Les points de sauvegarde

- **Antichambre du boss** : sauvegarde automatique **en entrant** et
  **à l'ouverture du coffre**.
- **Chaque salle** enregistre son état dès qu'elle est résolue.
- **Chaque coffre ouvert** et **chaque arme ramassée** déclenchent une
  sauvegarde dans la vallée.
- **Mort** : un panneau « Réessayer » recharge **la scène où vous êtes**,
  pas la vallée (sauf dans le vestibule de la citadelle, qui renvoie
  à la vallée — `À VÉRIFIER EN JEU`).

### Les pièges connus, par ordre de gravité

1. **Cuisiner APRÈS avoir ouvert le coffre de l'antichambre**
   → votre plat est **effacé** en entrant dans l'arène. **Cuisinez d'abord.**
   *(Cause : `antechamber.gd` n'écrit le point de reprise qu'à l'entrée et à
   l'ouverture du coffre ; `boss_arena.gd::_restore_checkpoint()` écrase
   ensuite l'inventaire avec ce point.)*
2. **Entrer chez le boss avec moins de 14 flèches**
   → les cristaux de phase 2 sont **inatteignables autrement** et l'armure
   ne tombera jamais définitivement. Le combat reste gagnable par les
   pylônes seuls, mais devient **beaucoup** plus long.
3. **Tomber dans le canal de la salle 4 avec le courant allumé**
   → 12 dégâts par seconde et pas de filet de sauvetage dans le donjon.
   **Coupez toujours le courant avant de traverser.**
4. **S'accrocher involontairement à un arbre, un mur ou une maison**
   → défaut connu (`KNOWN_ISSUES.md`). Le héros reste suspendu et la caméra
   traverse le décor. **Relâchez les touches de direction** pour retomber.
   **N'approchez pas d'un mur en marchant lentement contre lui** si vous ne
   voulez pas grimper.
5. **La route crête → plaine nord** échoue à un test automatique du projet
   (`ISS-032` : 9 jalons atteints sur 11, le marcheur descend à `y = −0,50`).
   **Il existe donc peut-être un endroit où l'on s'enfonce dans le décor
   entre la crête et la plaine nord.** `À VÉRIFIER EN JEU`. Si cela arrive
   dans la **vallée**, un **filet de sauvetage automatique** vous ramène au
   dernier point sûr dès que vous passez sous `y = −6`.
6. **« Continuer » depuis le menu principal** : dans une version ancienne du
   code, la position n'était pas restaurée et le joueur repartait de la crête.
   Le code actuel prétend la restaurer (schéma de sauvegarde n° 4).
   `À VÉRIFIER EN JEU`.

### Le mode développeur (dépannage)

- **F3** : ouvre un panneau d'information et démarre un enregistrement.
- **F4** : pose un marqueur + capture d'écran.
- **F5** : capture d'écran.
- **F2** : mode « vol libre » (pour se dégager si vraiment coincé).

Ces outils **ne trichent pas** et **ne modifient aucune valeur de jeu**.
Le vol libre (**F2**), lui, permet de sortir d'un blocage : une fois activé,
**Espace** monte et **Ctrl** descend.

---

## 16. Résumé en 15 lignes

1. Nouvelle partie. Le héros regarde déjà la citadelle.
2. Descendre la pente droit devant (86 m).
3. Passer au **camp** (fumée, à droite) : **coffre = hache + 12 flèches**,
   **gourdin** au sol, **viande**.
4. Traverser la rivière (berges en pente, vers `x = 0` à `20`).
5. Contourner le **colosse** vers `z = −64`. Ne pas le combattre.
6. Ramasser la **baie d'orage** du poste de garde (`x = 14, z = −102`).
7. Monter la grande rampe, traverser le plateau, **E** sur la porte noire.
8. Vestibule : tout droit, **E** sur la porte du fond.
9. **Salle 1** : pousser le cube métallique 7 m tout droit. Porte ouverte.
10. **Salle centrale** : quatre portes. Faire les trois autres salles.
11. **Salle 2 (ouest)** : grimper les 3 blocs entre deux décharges,
    **E** sur le levier du sommet.
12. **Salle 3 (nord)** : **E** ×2 sur A, ×3 sur B, ×1 sur C, ×1 sur D.
13. **Salle 4 (est)** : charger la batterie, **puis** couper le courant,
    sauter par l'îlot, poser la batterie sur le berceau de droite.
14. **Antechambre** : baies → **cuisiner** → **puis** ouvrir le coffre →
    équiper la hache.
15. **Boss** : dresser 2 pylônes, rester à 6-12 m, il se met à la terre,
    frapper le **noyau** avec la lame ; en phase 2, **14 flèches** dans les
    **2 cristaux du dos** ; en phase 3, éviter les marques au sol et finir.
    Coffre final → **écran de victoire**.

---

*Guide établi par lecture du code aux fichiers : `valley_world.gd`,
`valley_terrain.gd`, `citadel_vestibule.gd`, `room1_initiation.gd`,
`room2_vertical.gd`, `room3_relays.gd`, `room4_battery.gd`, `central_hall.gd`,
`antechamber.gd`, `storm_guardian.gd`, `boss_arena.gd`, `grounding_pylon.gd`,
`electric_relay.gd`, `recipe_rules.gd`, `project.godot`.
Aucune étape n'a pu être rejouée dans le moteur : le conteneur d'écriture de
ce guide est sans écran ni GPU.*
