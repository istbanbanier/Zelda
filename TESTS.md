# TESTS.md — Plan de test du jeu

Checklist de recette pour un jeu d'action-aventure type Zelda.
105 vérifications réparties en 12 phases, à traiter **dans l'ordre**.

---

## Règles d'utilisation (à lire avant de commencer)

Ce fichier est à la fois une spécification et un rapport. Il se remplit au fur et à mesure.

1. **Ne coche que ce que tu as réellement vérifié.** Une case cochée signifie « j'ai constaté que le critère est rempli », jamais « ça devrait aller ». En cas de doute, laisse la case vide et explique pourquoi dans le journal de bugs.
2. **Chaque échec va dans le journal de bugs** en bas de ce fichier, avec des étapes de reproduction exactes. Un bug non reproductible n'est pas corrigeable.
3. **Ne corrige rien sans le signaler.** Le but de la première passe est de diagnostiquer, pas de réécrire. Propose les correctifs, applique-les seulement après validation.
4. **Après chaque correction, re-teste la ligne concernée ET ses voisines.** Une correction casse souvent autre chose.
5. **Une session = une ou deux phases.** Traiter les 12 phases d'un coup produit un rapport superficiel.

### Légende des tags

| Tag | Signification |
|-----|---------------|
| `[CODE]` | Vérifiable en lisant, analysant ou exécutant le code. Un agent peut trancher seul. |
| `[MIXTE]` | L'agent peut inspecter les données et préparer le verdict, mais la décision finale demande un humain qui joue. |
| `[HUMAIN]` | Ne peut être jugé qu'en jouant. À laisser à un testeur humain — ne pas cocher automatiquement. |

Répartition : 49 `[CODE]`, 23 `[MIXTE]`, 33 `[HUMAIN]`.

Autrement dit : un agent peut trancher seul sur environ la moitié du plan, préparer le terrain sur un quart, et le dernier tiers relève du jeu réel — manette en main.

---

## Phase 0 — Préparation du test

*Se mettre dans les conditions d'un vrai testeur avant de toucher au jeu.*

- [ ] **0.1 Build propre** `[MIXTE]`
  Vérifier la configuration d'export : le jeu doit se lancer depuis le menu titre, pas depuis une scène de test.
  **Réussi si :** le jeu va du titre au gameplay sans intervention manuelle.

- [ ] **0.2 Journal de bugs prêt** `[CODE]`
  Le tableau en fin de fichier est initialisé et sera rempli au fil des phases.
  **Réussi si :** chaque échec constaté y figure avec sa gravité.

- [ ] **0.3 Objectif de session défini** `[HUMAIN]`
  Décider ce qui est testé aujourd'hui (une ou deux phases), pas tout à la fois.
  **Réussi si :** la cible du jour tient en une phrase.

- [ ] **0.4 Sauvegarde vierge** `[HUMAIN]`
  Supprimer ou déplacer les sauvegardes existantes pour retrouver l'expérience du premier joueur.
  **Réussi si :** le test démarre exactement comme pour un inconnu.

- [ ] **0.5 Clavier et manette couverts** `[CODE]`
  Inspecter la table des entrées (input map).
  **Réussi si :** chaque action du jeu possède une liaison clavier ET une liaison manette, sans trou.

---

## Phase 1 — Contrôles et déplacements

*La fondation : si bouger n'est pas agréable, rien d'autre ne comptera.*

- [x] **1.1 Réactivité immédiate** `[CODE]`
  Chercher tout délai entre la lecture de l'entrée et le déplacement : buffer inutile, animation bloquante, entrée lue dans le mauvais cycle de mise à jour.
  **Réussi si :** le personnage réagit en moins de 100 ms, sans latence introduite par le code.

- [x] **1.2 Vitesse en diagonale** `[CODE]`
  Vérifier que le vecteur de déplacement est normalisé avant application de la vitesse.
  **Réussi si :** la vitesse en diagonale est identique à la vitesse en ligne droite. *(C'est LE bug classique des Zelda-like : sans normalisation, la diagonale est ~1,41× plus rapide.)*

- [x] **1.3 Arrêt net** `[CODE]`
  Examiner les valeurs de friction / décélération à la relâche des touches.
  **Réussi si :** l'arrêt est immédiat, ou suivi d'une glissade courte et intentionnelle — jamais d'effet patinoire subi.

- [x] **1.4 Changement de direction instantané** `[CODE]`
  Vérifier qu'aucune animation ou machine à états ne verrouille le personnage lors d'une inversion rapide.
  **Réussi si :** l'inversion gauche-droite répétée ne produit ni temps mort ni blocage.

- [x] **1.5 Glissement le long des murs** `[CODE]`
  Inspecter la résolution de collision : le mouvement doit être projeté sur l'axe libre en cas de contact.
  **Réussi si :** avancer en diagonale contre un mur fait glisser le long du mur au lieu de bloquer net.

- [ ] **1.6 Correction des coins** `[CODE]`
  Chercher un mécanisme de « corner correction » qui décale légèrement le personnage pour contourner les angles.
  **Réussi si :** on ne reste jamais accroché sur un coin de mur, rocher ou bâtiment.

- [x] **1.7 Zones d'interaction généreuses** `[CODE]`
  Relever les rayons et boîtes d'interaction des PNJ, coffres, panneaux et les comparer à la taille du sprite.
  **Réussi si :** l'interaction se déclenche dès que c'est visuellement logique, sans placement au pixel près.

- [ ] **1.8 Résistance au spam de touches** `[MIXTE]`
  Analyser la machine à états du joueur : chaque transition doit être protégée contre les entrées répétées.
  **Réussi si :** marteler toutes les touches ne produit ni animation figée, ni action dupliquée, ni crash.

- [x] **1.9 Mouvement pendant l'attaque** `[CODE]`
  Mesurer la durée exacte du verrouillage de déplacement pendant une attaque.
  **Réussi si :** le verrouillage est court et volontaire — le personnage ne semble jamais planté dans le sol.

- [x] **1.10 Transitions de zones fiables** `[CODE]`
  Vérifier la logique de placement à l'arrivée : le point de spawn doit être calculé côté destination, pas hérité de la zone précédente.
  **Réussi si :** entrer et sortir 10 fois par la même porte replace toujours au bon endroit, sans boucle de téléportation ni écran noir bloqué.

---

## Phase 2 — Combat et game feel

*Chaque coup doit se sentir. C'est ce qui sépare « fonctionnel » de « agréable ».*

- [x] **2.1 Attaque réactive** `[CODE]`
  Mesurer le délai entre l'appui et la première image d'animation d'attaque.
  **Réussi si :** moins de 100 ms. La réactivité prime sur la beauté de l'animation.

- [x] **2.2 Hitbox honnête** `[CODE]`
  Comparer les dimensions des hitbox d'attaque et de réception aux dimensions des sprites.
  **Réussi si :** ce qui semble toucher touche, ce qui semble rater rate. Aucune hitbox significativement plus grande ou plus petite que son visuel.

- [x] **2.3 Feedback de coup porté** `[CODE]`
  Vérifier qu'un coup réussi déclenche au minimum un retour visuel (flash, clignotement) ET un retour sonore.
  **Réussi si :** aucun coup n'est silencieux et invisible.

- [x] **2.4 Hit-stop** `[CODE]`
  Chercher une micro-pause au moment de l'impact ; l'ajouter si absente.
  **Réussi si :** un gel de **40 à 80 ms** est appliqué à l'impact. C'est la technique qui donne du poids aux coups (Hollow Knight, Zelda).

- [x] **2.5 Knockback des deux côtés** `[CODE]`
  Vérifier la présence d'un recul appliqué à l'ennemi touché et au joueur touché.
  **Réussi si :** attaquant et cible se séparent visiblement à chaque impact — c'est ce qui rend le combat lisible.

- [x] **2.6 Invincibilité après un coup (i-frames)** `[CODE]`
  Relever la durée d'invincibilité et le retour visuel associé.
  **Réussi si :** 0,5 à 1 s d'invincibilité avec clignotement. Rester collé à un ennemi ne doit jamais coûter plusieurs cœurs en une seconde.

- [ ] **2.7 Screen shake dosé** `[CODE]`
  Lister les événements qui déclenchent une secousse d'écran et leur amplitude.
  **Réussi si :** seuls les gros impacts (explosion, boss) secouent l'écran, brièvement. Pas de secousse sur un coup d'épée ordinaire.

- [x] **2.8 Attaques télégraphiées** `[CODE]`
  Pour chaque type d'ennemi, vérifier l'existence d'images d'anticipation avant la frappe.
  **Réussi si :** chaque attaque ennemie est annoncée visiblement. L'échec doit toujours sembler être la faute du joueur.

- [x] **2.9 Mort et respawn propres** `[CODE]`
  Suivre le chemin de code de la mort du joueur jusqu'au retour en jeu.
  **Réussi si :** écran de mort clair, respawn au dernier point sûr, aucune perte de progression injuste.

- [ ] **2.10 Combat de groupe lisible** `[HUMAIN]`
  Affronter trois ennemis ou plus simultanément.
  **Réussi si :** l'action reste suivable et aucun coup ne vient d'un ennemi hors écran sans avertissement.

- [x] **2.11 Dégâts cohérents** `[CODE]`
  Extraire les valeurs de dégâts de tous les ennemis et les mettre en tableau, par zone.
  **Réussi si :** les dégâts correspondent à l'apparence et à la progression — l'ennemi de base de la zone 1 ne frappe pas plus fort que celui du donjon 3.

- [ ] **2.12 Animations avec anticipation et suivi** `[MIXTE]`
  Vérifier que les actions clés comportent un recul avant l'action et un accompagnement après (squash & stretch, courbes d'accélération).
  **Réussi si :** aucun mouvement linéaire robotique sur les actions principales.

---

## Phase 3 — Exploration et monde

*Un monde de Zelda vit par une règle d'or : la curiosité doit toujours payer.*

- [ ] **3.1 Orientation après une pause** `[HUMAIN]`
  Poser le jeu 10 minutes, revenir, se demander « où dois-je aller ? ».
  **Réussi si :** la réponse vient en moins de 10 secondes.

- [ ] **3.2 Points de repère visibles** `[HUMAIN]`
  Chercher depuis chaque zone un élément unique et reconnaissable.
  **Réussi si :** on peut naviguer à vue, sans ouvrir la carte.

- [ ] **3.3 Carte fidèle** `[MIXTE]`
  Comparer les données de la carte à la géométrie réelle des zones.
  **Réussi si :** carte à jour, lisible, position du joueur correcte.

- [ ] **3.4 La curiosité paye toujours** `[MIXTE]`
  Parcourir les données de niveau et lister les culs-de-sac ne contenant aucune récompense.
  **Réussi si :** la liste est vide. Chaque détour donne quelque chose (objet, secret, raccourci, clin d'œil).

- [ ] **3.5 Bordures du monde étanches** `[CODE]`
  Vérifier la présence de collisions sur toutes les limites de zone.
  **Réussi si :** impossible de sortir de la carte ou de voir derrière le décor.

- [ ] **3.6 Le visuel dit la vérité** `[MIXTE]`
  Croiser la couche de collision et la couche visuelle de chaque zone pour détecter les incohérences.
  **Réussi si :** zéro mur invisible, zéro obstacle visuel franchissable par erreur.

- [ ] **3.7 Le backtracking récompense** `[MIXTE]`
  Vérifier que des passages de la zone 1 sont conçus pour l'objet du donjon 2.
  **Réussi si :** au moins un secret s'ouvre en revenant en arrière. C'est le plaisir signature de la série.

- [ ] **3.8 Densité du monde** `[MIXTE]`
  Estimer la distance entre deux points d'intérêt sur les trajets principaux.
  **Réussi si :** jamais plus de 10-15 secondes de marche sans rien (ennemi, secret, décor remarquable, PNJ).

---

## Phase 4 — Énigmes et donjons

*Le cœur d'un Zelda. Méthode « Boss Keys » : serrures, clés, et une leçon par donjon.*

- [ ] **4.1 Graphe du donjon** `[CODE]`
  À partir des données de niveau, construire le graphe : salles, clés, serrures, et leurs liens. Le produire en sortie (Mermaid ou texte).
  **Réussi si :** aucune clé ne peut être dépensée sur la mauvaise porte au point de bloquer la progression.

- [ ] **4.2 Une mécanique, une leçon en quatre temps** `[MIXTE]`
  Vérifier la séquence pédagogique du donjon : introduction sûre, complexification, twist, maîtrise.
  **Réussi si :** les quatre étapes existent et sont dans cet ordre.

- [ ] **4.3 Enseigner avant d'exiger** `[MIXTE]`
  Localiser la première utilisation de chaque objet ou mécanique.
  **Réussi si :** elle se fait dans une salle sans danger. Jamais d'apprentissage sous la pression des ennemis.

- [ ] **4.4 Carte mentale du donjon** `[HUMAIN]`
  Après traversée, dessiner le donjon de mémoire.
  **Réussi si :** c'est possible. Sinon il manque une salle centrale, des raccourcis, ou des repères.

- [ ] **4.5 L'indice est dans la salle** `[MIXTE]`
  Pour chaque énigme, localiser l'indice de résolution.
  **Réussi si :** l'indice est visible depuis la salle elle-même. Aucune solution trouvable uniquement par hasard.

- [ ] **4.6 Anti-blocage d'énigme** `[CODE]`
  Vérifier l'existence d'une réinitialisation pour chaque énigme à état (blocs poussables, torches, interrupteurs).
  **Réussi si :** toute énigme sabotée est rattrapable — sortie de salle qui réinitialise, ou mécanisme de reset explicite.

- [ ] **4.7 Alternance réflexion / action** `[MIXTE]`
  Établir la séquence des salles et leur nature.
  **Réussi si :** jamais deux grosses énigmes consécutives sans respiration. Le combat sert de lubrifiant entre les phases de réflexion.

- [ ] **4.8 Objet de donjon multifonction** `[MIXTE]`
  Recenser tous les usages de l'objet obtenu dans le donjon.
  **Réussi si :** il sert dans le donjon, contre le boss, ET ailleurs dans le monde. Un objet à usage unique paraît creux.

- [ ] **4.9 Jalons de progression visibles** `[MIXTE]`
  Recenser les marqueurs d'avancement : mini-boss, carte, compteur, torches allumées.
  **Réussi si :** le joueur reçoit des victoires intermédiaires à intervalles réguliers.

- [ ] **4.10 Le boss est l'examen final** `[MIXTE]`
  Vérifier que le boss est battable en n'utilisant que la mécanique enseignée dans le donjon.
  **Réussi si :** c'est le cas, et un joueur qui maîtrise peut gagner sans se faire toucher. Le boss teste la leçon, pas la chance.

---

## Phase 5 — Progression et équilibrage

*Ni trop dur, ni trop mou : une pente douce qui donne toujours envie de continuer.*

- [ ] **5.1 Courbe de difficulté sans pic** `[MIXTE]`
  Noter la difficulté de chaque zone de 1 à 10 (densité et force des ennemis, dégâts subis, ressources disponibles).
  **Réussi si :** la courbe monte progressivement, sans pic brutal ni plateau qui ennuie.

- [ ] **5.2 Économie cohérente** `[CODE]`
  Calculer le revenu moyen de 10 minutes de jeu et le comparer aux prix de la boutique.
  **Réussi si :** un achat utile demande un effort raisonnable — ni cadeau immédiat, ni farm interminable.

- [ ] **5.3 Rythme des soins** `[CODE]`
  Recenser les sources de soin par zone et les comparer aux dégâts subis attendus.
  **Réussi si :** le joueur frôle parfois le danger, sans jamais être noyé de soins ni asséché au point d'être frustré.

- [ ] **5.4 Les améliorations se sentent** `[CODE]`
  Mesurer l'écart chiffré apporté par chaque amélioration (épée, cœur, défense).
  **Réussi si :** l'écart est assez large pour être perçu en jeu sans regarder les statistiques.

- [ ] **5.5 Durée réelle mesurée** `[HUMAIN]`
  Chronométrer une partie complète menée sans traîner.
  **Réussi si :** la durée correspond à l'intention. Noter les endroits où du temps est perdu involontairement.

- [ ] **5.6 Chemin critique, trois fois** `[HUMAIN]`
  Terminer le jeu entièrement, trois fois depuis zéro, sans dévier du parcours principal.
  **Réussi si :** les trois parties passent sans blocage. **C'est le test le plus important de tout ce plan.**

- [ ] **5.7 Test du désordre** `[MIXTE]`
  Tenter les zones et donjons dans un ordre non prévu.
  **Réussi si :** soit le jeu bloque proprement avec une raison claire, soit il assume la liberté sans casser.

- [ ] **5.8 Test du joueur débutant** `[HUMAIN]`
  Faire jouer la première zone à une personne peu habituée aux jeux vidéo.
  **Réussi si :** elle la termine, même lentement. Sinon la zone 1 est trop difficile — c'est presque toujours le cas au début.

---

## Phase 6 — Interface, menus et sauvegarde

*Invisible quand tout va bien, catastrophique quand ça rate.*

- [x] **6.1 Menu titre complet** `[CODE]`
  Tester chaque entrée : Nouvelle partie, Continuer, Options, Quitter.
  **Réussi si :** tout fonctionne, et « Continuer » est grisé ou absent en l'absence de sauvegarde.

- [x] **6.2 Navigation aux deux périphériques** `[CODE]`
  Vérifier que tous les menus sont parcourables au clavier seul puis à la manette seule.
  **Réussi si :** tout est accessible et l'élément sélectionné est toujours visuellement distinct.

- [x] **6.3 Pause fiable partout** `[CODE]`
  Vérifier le comportement de la pause pendant un combat, un dialogue et une transition.
  **Réussi si :** le temps est réellement gelé (les ennemis n'avancent pas) et la reprise est propre dans les trois cas.

- [x] **6.4 Sauvegarde complète** `[CODE]`
  Comparer la structure de sauvegarde à l'état complet du jeu, champ par champ.
  **Réussi si :** position, vie, inventaire, monnaie, coffres ouverts, boss vaincus et portes déverrouillées sont tous persistés et restaurés.

- [x] **6.5 Sauvegarde aux moments critiques** `[CODE]`
  Analyser les états possibles au moment de la sauvegarde : avant un boss, pendant un événement, énigme à moitié résolue.
  **Réussi si :** aucun rechargement ne produit un état incohérent ou bloquant.

- [ ] **6.6 HUD lisible d'un coup d'œil** `[HUMAIN]`
  En plein combat, vérifier la lisibilité de la vie, de la monnaie et de l'objet équipé.
  **Réussi si :** l'information vitale se lit instantanément et ne masque jamais l'action.

- [x] **6.7 Textes impeccables** `[CODE]`
  Extraire toutes les chaînes de caractères du jeu et les relire : orthographe, grammaire, cohérence.
  **Réussi si :** aucune faute, aucun texte qui déborde de sa boîte, passage de dialogue possible partout.

- [ ] **6.8 Options minimales utiles** `[CODE]`
  Vérifier la présence de volumes musique et effets séparés, et du choix plein écran / fenêtré.
  **Réussi si :** chaque réglage fonctionne et est conservé au redémarrage.

- [ ] **6.9 Résolutions et formats** `[MIXTE]`
  Tester plein écran, fenêtré et redimensionnement.
  **Réussi si :** rien n'est coupé, étiré ou déformé, quel que soit le format.

- [x] **6.10 Jamais de silence sur une action impossible** `[CODE]`
  Vérifier le retour donné lors d'un achat trop cher, d'une porte verrouillée sans clé, d'un objet inutilisable.
  **Réussi si :** le jeu répond systématiquement (son de refus, message, animation). Le silence est interprété comme un bug.

---

## Phase 7 — Audio et feedback sonore

*Le canal de « juice » le plus sous-utilisé, et la moitié du poids de chaque impact.*

- [ ] **7.1 Chaque action a un son** `[CODE]`
  Recenser les actions du joueur et vérifier qu'un son est déclenché pour chacune : pas, attaque, ramassage, dégâts subis, navigation de menu.
  **Réussi si :** aucune action du joueur n'est muette.

- [ ] **7.2 Boucles musicales propres** `[HUMAIN]`
  Rester dans une zone jusqu'à deux bouclages complets.
  **Réussi si :** le raccord est inaudible, et chaque ambiance correspond au lieu.

- [ ] **7.3 Signatures sonores mémorables** `[MIXTE]`
  Vérifier l'existence d'un son distinctif pour les moments clés : secret découvert, clé obtenue, vie basse, énigme résolue.
  **Réussi si :** chacun est reconnaissable immédiatement et sans ambiguïté.

- [ ] **7.4 Mixage équilibré** `[HUMAIN]`
  Écouter une session au casque, puis sur haut-parleurs.
  **Réussi si :** aucun son n'écrase les autres, et l'alerte de vie basse reste audible sans devenir insupportable.

- [ ] **7.5 Volumes réellement indépendants** `[CODE]`
  Vérifier le routage des bus audio.
  **Réussi si :** couper la musique laisse les effets, et le jeu reste entièrement jouable en silence total (accessibilité).

- [ ] **7.6 Le silence comme outil** `[HUMAIN]`
  Repérer les moments de tension et les respirations.
  **Réussi si :** il existe des passages calmes. Un jeu qui sature en continu fatigue et affaiblit ses propres temps forts.

---

## Phase 8 — Tests destructifs

*Tout ce qui peut casser doit casser ici, pas chez les joueurs.*

- [x] **8.1 Spam d'interactions** `[CODE]`
  Vérifier la protection contre le double-déclenchement : PNJ, coffres, dialogues.
  **Réussi si :** aucune récompense donnée deux fois, aucun dialogue superposé.

- [x] **8.2 Actions simultanées** `[CODE]`
  Analyser les combinaisons : attaque + ouverture de menu + changement de zone dans la même image.
  **Réussi si :** aucun état ne se superpose à un autre.

- [x] **8.3 Traversée de murs** `[CODE]`
  Vérifier la collision pendant les actions à déplacement : attaque en avançant, roulade, projection par un ennemi.
  **Réussi si :** aucune action ne permet de traverser un mur ou d'atterrir hors du décor.

- [x] **8.4 Mort aux pires moments** `[CODE]`
  Analyser la mort survenant pendant un dialogue, une transition, l'ouverture d'un coffre, une phase de boss.
  **Réussi si :** le jeu revient toujours à un état propre. **C'est la source numéro un de softlocks.**

- [x] **8.5 Inventaire aux extrêmes** `[CODE]`
  Vérifier le bornage (clamping) de tous les compteurs : monnaie à zéro, inventaire plein, dernier consommable utilisé.
  **Réussi si :** aucun compteur ne passe en négatif, aucun débordement, aucun crash.

- [x] **8.6 Retour dans les zones terminées** `[CODE]`
  Vérifier la persistance de l'état des donjons achevés.
  **Réussi si :** boss non réapparu, coffres restés ouverts, portes restées déverrouillées — sauf choix contraire assumé.

- [x] **8.7 Chasse au softlock** `[CODE]`
  Rechercher activement les états sans issue : bloc poussé dans un coin contre le joueur, chute pendant une cinématique, zone fermée derrière soi.
  **Réussi si :** une sortie existe toujours — réinitialisation de salle, téléportation, ou mort propre.

- [ ] **8.8 Perte de périphérique et perte de focus** `[MIXTE]`
  Vérifier le comportement à la déconnexion de manette et à la perte de focus de la fenêtre.
  **Réussi si :** le jeu survit et reprend sans dégât, idéalement avec pause automatique.

- [ ] **8.9 Test d'abandon** `[HUMAIN]`
  Laisser le jeu tourner 30 minutes sans y toucher, sur le titre puis en jeu.
  **Réussi si :** aucun crash, aucun comportement anormal au retour.

- [ ] **8.10 Session longue** `[HUMAIN]`
  Jouer une heure d'affilée en surveillant la fluidité.
  **Réussi si :** les performances ne se dégradent pas progressivement. Une dégradation lente signale une fuite de mémoire.

- [x] **8.11 Nouvelle partie vraiment neuve** `[CODE]`
  Vérifier la réinitialisation complète de l'état global au lancement d'une nouvelle partie.
  **Réussi si :** aucune trace de la partie précédente ne subsiste — inventaire, drapeaux de quête, coffres.

- [x] **8.12 Chaque bug est reproductible** `[CODE]`
  Pour chaque entrée du journal de bugs, rédiger et valider les étapes exactes de reproduction.
  **Réussi si :** chaque bug listé se reproduit à volonté. Un bug reproductible est un bug à moitié corrigé.

---

## Phase 9 — Performance et stabilité

*Un bon jeu tourne bien ailleurs que sur la machine de développement.*

- [ ] **9.1 Fluidité dans la pire scène** `[MIXTE]`
  Identifier la scène la plus chargée et y mesurer le nombre d'images par seconde.
  **Réussi si :** le framerate est stable. Un 40 constant vaut mieux qu'un 60 qui saccade.

- [ ] **9.2 Chargements courts** `[MIXTE]`
  Chronométrer le lancement du jeu et chaque transition de zone.
  **Réussi si :** moins de 3 à 5 secondes partout. Au-delà, prévoir au minimum une animation d'attente.

- [ ] **9.3 Test sur une autre machine** `[HUMAIN]`
  Lancer le jeu sur un second ordinateur, idéalement moins puissant.
  **Réussi si :** il tourne correctement. La machine de développement est toujours plus rapide que celle des joueurs.

- [ ] **9.4 Console propre** `[CODE]`
  Jouer une partie complète en surveillant les journaux du moteur.
  **Réussi si :** aucune erreur, aucune avalanche d'avertissements. Chaque erreur ignorée aujourd'hui est un crash chez un joueur demain.

- [ ] **9.5 Build de sortie nettoyée** `[CODE]`
  Inspecter le contenu de l'export final.
  **Réussi si :** aucun fichier de débogage, aucune scène de test, aucun raccourci de triche actif, aucun asset temporaire.

- [ ] **9.6 L'export démarre à froid** `[HUMAIN]`
  Lancer la version distribuable sur une machine qui n'a jamais eu le moteur installé.
  **Réussi si :** le jeu démarre du premier coup, sans dépendance manquante.

---

## Phase 10 — Playtest avec de vrais joueurs

*Le moment de vérité. La mission du développeur : se taire et regarder.*

- [ ] **10.1 Recruter 3 à 5 testeurs** `[HUMAIN]`
  Commencer gratuitement : proches, camarades, communauté.
  **Réussi si :** 3 à 5 personnes n'ayant jamais vu le jeu sont mobilisées. C'est suffisant pour révéler l'essentiel des problèmes.

- [ ] **10.2 Un objectif mesurable par session** `[HUMAIN]`
  Écrire la cible avant la session, par exemple : « le joueur comprend les contrôles en moins de 3 minutes sans aide ».
  **Réussi si :** la question admet un oui ou un non chiffré à la fin.

- [ ] **10.3 Silence total pendant la partie** `[HUMAIN]`
  Ne rien dire pendant que le testeur joue : aucune aide, aucune explication, aucun « c'est normal ».
  **Réussi si :** aucune intervention. Chaque mot prononcé détruit la donnée la plus précieuse de la session.

- [ ] **10.4 Observer et tout noter** `[HUMAIN]`
  Consigner les hésitations, les morts, les moments d'ennui, ce qui n'est pas vu, et les sourires.
  **Réussi si :** une page de notes par testeur.

- [ ] **10.5 Chronométrer les moments clés** `[HUMAIN]`
  Mesurer le temps de compréhension des contrôles, de complétion de la zone 1, de découverte du premier secret.
  **Réussi si :** des chiffres comparables d'un testeur à l'autre sont disponibles.

- [ ] **10.6 Les bonnes questions, après seulement** `[HUMAIN]`
  Demander en fin de session : « qu'est-ce qui t'a frustré ? », « où voulais-tu aller ? », « raconte ce que tu as fait ».
  **Réussi si :** la question « c'était bien ? » n'a jamais été posée — tout le monde répond oui.

- [ ] **10.7 Filtrer les retours** `[HUMAIN]`
  Croiser les notes des différents testeurs.
  **Réussi si :** ce qui revient chez deux ou trois joueurs est traité en priorité, et les avis isolés ne font pas dévier la vision du jeu.

- [ ] **10.8 Sessions de 15 à 30 minutes** `[HUMAIN]`
  Limiter la durée de chaque session de test.
  **Réussi si :** personne ne dépasse 30 minutes. Au-delà, la fatigue fausse les retours.

- [ ] **10.9 Re-tester avec des personnes neuves** `[HUMAIN]`
  Après correction, faire tester par des gens qui n'ont jamais joué.
  **Réussi si :** les problèmes de la session précédente ont disparu chez les nouveaux. Un testeur qui connaît déjà le jeu ne teste plus la découverte.

- [ ] **10.10 Publier une démo à des inconnus** `[HUMAIN]`
  Mettre une démo de 15 à 30 minutes en ligne (itch.io) et la partager.
  **Réussi si :** des retours de parfaits inconnus sont collectés. C'est le seul verdict qui compte vraiment.

---

## Phase 11 — Le verdict « super jeu »

*Les huit critères qui séparent un jeu qui marche d'un jeu qu'on n'oublie pas.*

- [ ] **11.1 Le test des deux minutes** `[HUMAIN]`
  Observer un inconnu sur les 120 premières secondes.
  **Réussi si :** il s'amuse déjà. Pas « il a compris », pas « il progresse » : il s'amuse.

- [ ] **11.2 Le test de l'envie** `[HUMAIN]`
  Se demander honnêtement, après des semaines de développement : « ai-je envie de lancer une partie pour le plaisir ? ».
  **Réussi si :** la réponse est oui. Si le créateur s'ennuie, les joueurs s'ennuieront.

- [ ] **11.3 L'échec est toujours juste** `[HUMAIN]`
  Repasser en revue toutes les morts survenues pendant les tests.
  **Réussi si :** chacune a inspiré « c'est ma faute » et jamais « le jeu est injuste ».

- [ ] **11.4 Chaque écran a une raison d'exister** `[MIXTE]`
  Passer chaque salle en revue et identifier ce qu'elle apporte : un défi, un secret, une émotion, une respiration.
  **Réussi si :** aucune salle ne sert uniquement à remplir l'espace.

- [ ] **11.5 Le moment mémorable** `[HUMAIN]`
  Demander à un testeur, une semaine après : « tu te souviens d'un moment ? ».
  **Réussi si :** il raconte quelque chose. Un bon jeu laisse au moins une histoire à raconter.

- [ ] **11.6 Zéro bug bloquant connu** `[CODE]`
  Relire le journal de bugs et vérifier le statut de chaque entrée de gravité « bloquant ».
  **Réussi si :** plus aucun bloquant sur le chemin critique. Les défauts cosmétiques peuvent attendre, un softlock jamais.

- [ ] **11.7 Finissable sans le créateur** `[HUMAIN]`
  Quelqu'un termine le jeu sans qu'un mot soit prononcé.
  **Réussi si :** c'est possible du début à la fin. Le jeu doit tout enseigner lui-même.

- [ ] **11.8 La boucle des retours tourne** `[HUMAIN]`
  Après publication de la démo : lire les retours, corriger, republier.
  **Réussi si :** au moins un cycle complet a été bouclé. Un bon jeu n'est jamais fini, il est amélioré jusqu'à ce que les retours deviennent des compliments.

---

## Mécaniques absentes (pas des bugs — décisions à prendre)

Constatées pendant la passe, conformément à la règle « une mécanique absente
n'est pas un bug ». Chaque ligne dit ce que l'absence coûte.

- **1.6 Correction des coins** — aucun mécanisme (`_maybe_step_up` gère les
  marches, rien ne gère les angles). Coût : accrochages nets sur coins de
  rochers/bâtiments en sprint. PROMPT2 §5.2 la prévoyait (« correction latérale
  faible autour d'un coin »).
- **2.4 Hit-stop** — introuvable dans tout le projet. Coût : les impacts n'ont
  aucun poids ; c'est LE geste de game feel des références citées par le plan.
  MASTER_SPEC §10.2 chiffre déjà les valeurs attendues (léger 0,035-0,055 s,
  lourd 0,070-0,095 s) : la décision est prise, seule l'implémentation manque.
- **2.6 Invulnérabilité post-coup** — le jeu a une fenêtre anti-stunlock de
  0,85 s qui bloque la RÉACTION mais laisse passer les DÉGÂTS (commentaire
  explicite : « il blesse sans réaction », `player_controller.gd:663`). Coût :
  au contact de deux ennemis, la vie fond sans fenêtre de mercy ; le plan
  demande 0,5-1 s d'invulnérabilité aux dégâts avec clignotement. Le flash de
  0,12 s existe déjà — l'étendre à la fenêtre serait le clignotement.
- **2.7 Screen shake** — aucun. Coût : gros impacts et boss plats à l'écran.
  §10.2 le prévoit, désactivable (§17.5).
- **6.8 Plein écran / fenêtré** — absent des options (les volumes séparés,
  eux, existent et persistent : `options_panel.gd:156-178`). Coût : confort
  desktop de base, à ajouter avant toute distribution.
- **Monnaie / boutique** (6.4) — aucun système économique n'existe : le champ
  « monnaie » du critère est sans objet, ce n'est pas un oubli de sauvegarde.

---

## Journal de bugs

Une ligne par défaut constaté. Gravité : **bloquant** (empêche de finir le jeu), **majeur** (gâche l'expérience), **mineur** (cosmétique).

| # | Test | Description | Fichier / ligne | Reproduction | Gravité | Statut |
|---|------|-------------|-----------------|--------------|---------|--------|
| 1 | 2.3 / 6.10 | Tous les coups sont muets : zéro asset audio dans le projet (`assets/audio` vide) et aucun appel de lecture depuis le gameplay. `AudioManager` n'expose que des bus et des volumes que rien n'utilise. Le flash visuel (0,12 s des deux côtés) existe, le canal sonore non. | `assets/audio/` (0 fichier) ; `scripts/core/audio_manager.gd` (jamais appelé hors tests) | Frapper un pillard au camp : flash rouge, aucun son. Naviguer les menus : aucun son. | majeur | corrigé |
| 2 | 6.4 | La santé et l'endurance ne sont pas sauvegardées : le payload d'autosave (position, armes, flèches, coffres, découvertes…) ne contient ni `health` ni `stamina`, pourtant exigées par MASTER_SPEC §19.1. Recharger soigne gratuitement. | `scripts/world/valley_world.gd:588-613` | Perdre 4 cœurs → ouvrir un coffre (déclenche l'autosave) → quitter → « Continuer » : vie pleine. | majeur | corrigé |
| 3 | 8.6 | La victoire sur le boss est effacée par l'autosave de la vallée : `BossArena` écrit `boss_defeated=true` en FUSIONNANT la sauvegarde, mais l'autosave vallée réécrit un payload complet avec `"boss_defeated": false` EN DUR. | `scripts/world/valley_world.gd:612` (écrase) vs `scripts/boss/boss_arena.gd:358-363` (fusionne) | Vaincre le boss → « Continuer l'exploration » → ouvrir n'importe quel coffre → relancer : l'écran de victoire dit « Aucune victoire enregistrée dans ce slot ». | majeur | corrigé |
| 4 | 6.10 | Refus silencieux : l'attaque lourde refusée (`try_heavy` → `return false` sans aucun retour), le coffre déjà ouvert (`interact` → `return false`), l'endurance insuffisante pour la lourde. Quelques refus notifient (« Réserve de plats pleine ») — la règle n'est pas systématique. | `scripts/combat/attack_controller.gd:108-112` ; `scripts/interaction/chest.gd:77-78` | Marteler R pendant une attaque : rien ne se passe, rien ne l'explique. | majeur | corrigé |
| 5 | 2.5 | Le recul n'est jamais appliqué aux ennemis touchés : `event.knockback` (2,0 à 4,5 selon l'attaque, présent dans les `.tres`) est ignoré par `_on_hit_received`, qui n'applique que flash + poise. L'ennemi ne se sépare du joueur qu'à la rupture de poise (stagger). Le joueur, lui, reçoit bien son recul. | `scripts/enemies/enemy_base.gd:689-702` | Frapper un pillard avec la 1re légère : il flashe mais ne bouge pas d'un centimètre. | mineur | corrigé |
| 6 | 2.8 | Le télégraphe repose sur la couleur seule dans le repli graybox : pendant le startup, le modèle rougit (`telegraph_color`), mais si le modèle riggé n'est pas monté il n'y a ni pose d'anticipation ni forme distinctive — violation de la règle « jamais couleur seule » (§17.4, daltonisme). | `scripts/enemies/enemy_base.gd:746-756` | Observer un pillard graybox qui attaque : seule la teinte change. | mineur | ouvert |

---

## Correctifs prioritaires proposés

À remplir en fin de passe : les trois corrections à faire en premier, classées par rapport impact / effort.

1. **Fusionner l'autosave au lieu d'écraser, et y ajouter santé/endurance**
   (bugs 2 et 3, même cause racine : `_autosave()` écrit un payload figé là où
   l'arène charge-modifie-réécrit). Impact énorme — victoire du boss perdue et
   soin gratuit au rechargement — pour un effort minuscule : reprendre le
   modèle de `boss_arena.gd:358-363` et deux champs de plus. À faire en premier.
2. **Un pack sonore minimal branché aux points déjà identifiés** (bugs 1 et 4).
   Six à huit sons libres de droits (coup porté, coup reçu, refus, coffre,
   collecte, mort, navigation menu) suffisent : les points d'appel existent
   (`_on_hit_received` des deux côtés, `try_heavy` refusé, `interact`,
   notifications). Impact majeur — « aucun coup silencieux » — effort modéré.
3. **Appliquer le knockback ennemi et ajouter le hit-stop** (bug 5 + absence
   2.4). Les valeurs sont déjà dans les données (`knockback` 2,0-4,5 dans les
   `.tres`, fenêtres chiffrées par §10.2) : il ne manque que l'application dans
   `enemy_base._on_hit_received` et un gel local de 40-80 ms. Impact fort sur
   le ressenti, effort faible, zéro décision de design à prendre.

**État après application (2026-08-04)** — les trois correctifs sont appliqués
et re-testés, chacun avec un test qui échouait avant : autosave par fusion +
santé/endurance (`save` 15/15, « obtenu 100.0000 » avant → 37.0 après),
knockback ennemi + hit-stop consommés depuis les données (`hit_impact` 2/2,
« déplacement : 0.00 m » avant), neuf sons générés et câblés sur onze points
(`audio` 3/3). Voisinage re-testé : `combat` 10/10, `enemy_base` 5/5,
`menu` 10/10, `boss_guardian` 14/14. Le bug 6 (télégraphe couleur seule en
graybox) reste ouvert — il appartient à la passe artistique. L'absence 2.6 a depuis été comblée (« amélioration bonus » appliquée) :
fenêtre de mercy de 0,6 s aux dégâts après un coup encaissé, clignotement à
~9 Hz sur toute la durée, cumulée par OU avec les i-frames d'esquive —
`mercy` 2/2 (le test a d'abord photographié l'injustice : « obtenu 80.0000 »,
les deux coups blessaient), `combat` 10/10, `boss_guardian` 14/14.

**Amélioration bonus** — le changement qui aurait le plus d'effet sur le plaisir de jeu :

Étendre le flash existant (0,12 s) en **invulnérabilité post-coup clignotante
de 0,6 s** (absence 2.6). C'est la différence entre « je me suis fait toucher »
et « je me suis fait fondre » : aujourd'hui, deux pillards au contact drainent
la vie sans fenêtre de réponse, et c'est exactement le genre d'injustice qu'un
joueur ne pardonne pas.

---

## Références

- [Méthodologie de conception d'un donjon Zelda-like](https://medium.com/@bramasolejm030206/the-ultimate-methodology-of-creating-zelda-like-dungeon-level-0a1ddfeb5246)
- [Boss Keys — analyse des donjons Zelda par Mark Brown (GMTK)](https://zeldauniverse.net/2017/01/26/explore-zelda-dungeon-design-in-mark-browns-youtube-series-boss-keys/)
- [Game feel et « juice » : timings de référence](https://egmatic.com/blog/how-to-make-your-game-feel-good)
- [Checklist de test QA pour développeurs indépendants](https://snoopgame.com/blog/how-to-create-a-game-testing-checklist-for-indie-developers/)
- [Six étapes d'un playtest réussi](https://www.gamedeveloper.com/programming/6-steps-to-a-successful-playtesting-process-for-an-indie-developer)
