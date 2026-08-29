# Build expérimentale « camp libéré » — 15 à 25 minutes

**VIVANT.** Ce guide accompagne la préversion `world-v2-camp-exp-<SHA>`.
Il ne remplace pas `docs/GUIDE_JOUEUR.md` (installation, commandes) : il dit
seulement **quoi essayer**, dans quel ordre, et **ce qu'il faut regarder**.

---

## Ce qui est nouveau, et rien d'autre

Trois choses, et elles sont toutes au **camp**, sur la terrasse au sud du point
de départ :

1. **Le camp est tenu par quatre pillards.** Trois au gourdin, un à la lance
   qui monte la garde plus au sud.
2. **Son foyer est éteint** tant qu'ils le tiennent.
3. **Le libérer rallume le feu et laisse une caisse** — une épée usée et dix
   flèches.

Le reste du monde est inchangé.

---

## Le parcours, en 15 à 25 minutes

### 1. Descendre vers le camp — 3 à 5 min

Depuis le point de départ, descendez plein sud. Le camp est la terrasse
dégagée en contrebas ; on le repère à sa palissade et à ses toiles.

**À regarder** : le foyer est **froid**. Pas de flamme, pas de lueur. C'est
voulu — il dit que le camp n'est pas à vous.

### 2. Approcher, et se faire voir — 1 à 2 min

Approchez sans vous presser. Les gardes ont un cône de vision et une portée
d'ouïe ; ils ne vous voient pas de dos et pas à travers la palissade.

**À regarder** : lequel vous repère en premier, et à quelle distance. Ils ne
doivent JAMAIS vous voir à travers un mur.

### 3. Le combat — 5 à 10 min

Attaque légère au **clic gauche**, esquive au **Ctrl gauche**.

**À regarder, et c'est le point le plus utile de cette build** :

- deux pillards au plus vous attaquent en même temps — les autres tournent,
  menacent, se replacent ;
- si vous **reculez loin du camp**, ils abandonnent et rentrent. Ils ne doivent
  pas vous suivre indéfiniment. Une flèche tirée de très loin ne doit pas
  non plus les faire sortir de leur camp : c'est une correction de cette
  passe, et c'est exactement ce qu'il faut essayer de mettre en défaut ;
- s'ils vous tuent, **Réessayer** vous ramène au camp de départ. Ceux que vous
  aviez déjà abattus **restent morts**.

### 4. Le camp libéré — 2 à 3 min

Au dernier garde tombé :

- un message apparaît en haut de l'écran ;
- **le feu se rallume** ;
- **une caisse est là**, près du foyer.

**À regarder** : ouvrez la caisse avec **E**. Vous récupérez l'épée usée et dix
flèches. Changez d'arme et frappez un tonneau ou une jarre pour sentir la
différence avec le gourdin.

### 5. La reprise — 3 à 5 min, et c'est le vrai test

Quittez le jeu par la **croix de la fenêtre**, puis relancez et faites
**Continuer**.

**À regarder, dans cet ordre** :

- le feu est **toujours allumé** — le camp reste libéré ;
- les quatre pillards **ne sont pas revenus** ;
- la caisse que vous avez ouverte est **toujours ouverte, et vide**. Elle ne
  redonne pas une seconde épée.

**Et la variante qui compte autant** : refaites le parcours, mais cette fois
**libérez le camp SANS ouvrir la caisse**, quittez, relancez, revenez.
La caisse doit être là, **fermée**, avec son contenu intact. Repartir sans sa
récompense ne doit jamais la faire disparaître.

---

## Ce qu'il faut nous signaler en priorité

Par ordre de gravité, du plus grave au moins grave :

1. **Un pillard qui vous suit hors du camp sans jamais renoncer.**
2. **Une caisse qui redonne une arme une seconde fois** après un rechargement.
3. **Un camp qui redevient occupé** après avoir été libéré.
4. **Un feu qui reste éteint** alors que les quatre gardes sont tombés.
5. Un garde qui vous voit à travers la palissade.
6. Tout ce qui vous bloque : chute hors du monde, coincé dans un décor,
   impossible de sortir d'un menu.

Une remarque vague est utile aussi. « Je ne comprenais pas où aller » ou
« le combat m'a paru mou » valent mieux que rien : c'est exactement le genre
d'observation que les tests automatiques ne peuvent pas produire.

---

## Ce que cette build n'est PAS

- Ce n'est pas une version jouable de bout en bout : le donjon et le boss sont
  là, mais ce n'est pas ce qu'on vous demande d'essayer.
- **Aucune mesure de performance n'a de sens ici** au-delà de « ça rame ou ça
  ne rame pas » : les chiffres du dépôt viennent d'un conteneur sans carte
  graphique, en rendu logiciel. Votre machine est le seul juge honnête de la
  fluidité, et votre ressenti nous intéresse plus qu'un compteur.
- Ce n'est pas une release officielle. C'est une **préversion expérimentale**,
  faite pour être cassée.
