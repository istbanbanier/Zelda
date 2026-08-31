# Localisation — ISS-075

**VIVANT.** Décrit le mécanisme en place et ce qu'il ne couvre pas encore.
Quand ce document et le code divergent, c'est le code qui a raison : rejouer
`tools/lancer_godot.sh --path . --script tools/godot/test_runner.gd -- --filter=localisation_iss075`
et corriger ici.

## Ce qui existe

| Pièce | Chemin |
|---|---|
| Le résolveur | `scripts/localisation/textes.gd` (`class_name Textes`) |
| Langue source | `resources/localisation/fr.json` |
| Locale témoin | `resources/localisation/en.json` |
| Le contrat exécutable | `tests/integration/test_localisation_iss075.gd` |

```gdscript
Textes.t("camp.braise.libere")            # -> "Le camp est libéré. Le feu se rallume."
Textes.traduire_si_cle(texte)             # traduit SI c'est une clé, laisse passer sinon
Textes.definir_locale(&"en")              # bascule
Textes.cles_sans_traduction(&"en")        # couverture d'une locale
```

## Les deux règles, et pourquoi elles diffèrent

**Une clé absente de `fr` est une FAUTE.** `push_error`, et le joueur voit
`⟦la.cle⟧` — visiblement cassé, donc remonté. C'est l'inverse exact du `tr()`
de Godot, qui rend la clé nue et se tait : sur un écran, `camp.braise.libere`
ressemble à un choix de mise en page et personne ne le signale.

**Une clé absente d'une AUTRE locale n'en est pas une.** Elle retombe sur le
français et se compte. « Le texte n'existe pas » et « la traduction n'est pas
faite » sont deux problèmes ; les confondre est la façon habituelle de ne
jamais voir le premier.

## La forme d'une clé, et ce qu'elle permet

`camp.braise.libere` : minuscules, chiffres, soulignés, points ; **première
lettre alphabétique** ; au moins un point ; ni point au bord, ni point double.

Cette forme n'est pas cosmétique. C'est elle qui permet au HUD de traduire une
clé **sans toucher** aux 200 textes bruts encore en place, donc de migrer
message par message. `test_localisation_iss075.gd` vérifie les deux bras : les
clés de la table sont reconnues, et des textes joueur réels ne le sont pas.

> La contrainte « première lettre alphabétique » vient du premier passage
> ROUGE, pas d'une relecture : sans elle, `"0.5"` était une clé valide, et une
> notification portant un nombre serait partie chercher une traduction pour
> afficher `⟦0.5⟧`.

## Pourquoi pas `TranslationServer`

1. `tr()` rend la clé quand elle manque, **silencieusement**. Il faudrait de
   toute façon une couche par-dessus pour retrouver l'échec — donc la couche
   est le vrai mécanisme.
2. Un `Translation` est une `Resource` que le serveur retient jusqu'à la fin du
   processus. Le résidu de fin de processus est **épinglé** par
   `docs/contrats/residu_cache_moteur.json`, lui-même **gelé** : deux locales =
   deux ressources = enveloppe à rouvrir et gel à régénérer. Une table en
   `Dictionary` n'est ni objet ni ressource ; elle n'apparaît nulle part dans
   ce comptage.
3. Aucun autoload de plus. La racine en porte six et `restore_root()` compte
   dessus.

Ce qu'on perd, dit franchement : la traduction automatique du `text` des
`Control` posés en scène. Cette passe ne migre que du texte **émis par code**,
donc la perte est nulle aujourd'hui. Le jour où un `.tscn` devra être traduit,
tous les appels passent déjà par `t()` : le changement tiendra dans un fichier.

## Ce qui est migré

Deux tranches, dans cet ordre.

**Tranche 1 — le camp braise et les premiers textes d'une partie neuve.** Neuf
clés, migrées le 2026-08-29.

| Clé | Où |
|---|---|
| `camp.braise.libere` | donnée du camp, `textes/victoire` |
| `camp.braise.recompense` | donnée du camp, `textes/recompense_posee` |
| `camp.braise.foyer_tenu` | `campfire.gd::refus_cle()` — message NEUF, jamais écrit en dur |
| `vallee.premiere.fumee` | `valley_world.gd` — la première notification d'une partie |
| `interaction.rien_a_portee` | `player_controller.gd::_refuse_interaction()` |
| `menu.options.sous_titre` | `main_menu.gd` |
| `menu.sauvegarde.ecraser` | `main_menu.gd` |
| `menu.sauvegarde.confirmer` | `main_menu.gd` |
| `menu.sauvegarde.echec` | `main_menu.gd` |

Le camp est un cas particulier instructif : `world_v2_camp_liberation.gd` est
**gelé**, donc son `_annoncer()` ne peut pas appeler `Textes.t()`. Il publie la
**clé** sur `EventBus`, et c'est le HUD (`gameplay_shell._on_notification`) qui la
résout. Le script gelé portait déjà la note « le jour où une localisation arrive,
c'est le JSON qu'elle remplace, pas cette ligne » — c'est exactement ce qui a été
fait.

**Tranche 2 — l'écran de jeu.** `scripts/ui/gameplay_shell.gd`, migré le
2026-08-31. Le fichier ne porte plus **aucun** texte joueur écrit en dur, et le
plafond du détecteur épingle ce zéro : y remettre un texte fait rougir la suite.

Les quatre tables `StringName -> String` du fichier — libellés de buff, phases du
boss, actions et refus de Résonance — sont passées en clés. Leur **repli** reste
en revanche le jeton technique BRUT et ne traverse jamais le résolveur : voir
`## Les replis, et pourquoi ils ne sont pas traduits` ci-dessous.

Le contrat de cette tranche est un fichier à lui seul,
`tests/integration/test_localisation_iss075_gameplay_shell.gd` : il vérifie que
chaque clé rend le français historique, que la locale témoin couvre toute la
tranche, que les paramètres de format sont identiques dans les deux langues, que
l'unicode traverse la table intact, que le changement de langue à chaud change
réellement l'écran, et qu'aucune clé nue ne paraît sur les chemins d'exécution
réellement pilotés.

## Les replis, et pourquoi ils ne sont pas traduits

Quand une table est interrogée avec un jeton qu'elle ne connaît pas, elle rend ce
jeton **brut**, jamais un appel au résolveur. C'est délibéré : un repli qui
passerait par `t()` afficherait le marqueur d'erreur `⟦…⟧` au joueur pour une
cause qui n'est pas une faute de localisation — un jeton inattendu venu du
gameplay. Le contrat vérifie les deux bras : le repli sort brut, et toutes les
valeurs des quatre tables résolvent bien dans la langue source.

## Ce qui NE l'est pas, et comment le compter

**Le compte ne vit pas dans cette page.** Il vit dans l'outil, et sa sortie datée
vit dans les preuves — c'est la règle d'ancrage du `CLAUDE.md` racine, et cette
section a déjà été prise en défaut deux fois pour l'avoir enfreinte.

```
python3 tools/inventaire_textes_joueur.py
```

Sortie de référence de la tranche 2 :
`evidence/world_v2/iss075/inventaire_officiel_apres.txt`. Elle porte trois
catégories — texte joueur, texte diagnostic, hors build joué — puis le détail par
fichier, du plus gros porteur au plus petit. **Rejouer la commande plutôt que de
citer cette page.**

Ordre de grandeur, à la date de la tranche 2 et pour situer seulement : le texte
joueur non migré se compte en **quelques centaines de littéraux répartis sur
plusieurs dizaines de fichiers**, l'écrasante majorité hors de l'écran de jeu. Les
plus gros porteurs restants sont, dans l'ordre, `scripts/world/training_grounds.gd`,
`scripts/ui/options_panel.gd`, `scenes/ui/GameplayShell.tscn` et
`scripts/world/discovery_rewards.gd`.

Le texte **diagnostic** ne sera pas traduit : un journal moteur s'adresse à qui lit
le code, pas au joueur. Le **hors build joué** non plus.

### Le compteur annonçait un SOUS-ENSEMBLE STRICT, et il a fallu le refondre

Cette page a annoncé « `gameplay_shell.gd` (39) » et présenté ce nombre comme le
compte exact. Il ne l'était pas : l'outil ne retenait un littéral **que s'il
portait un caractère accentué**. Ce n'était donc pas un compte de texte joueur,
mais un compte de texte joueur **accentué** — un sous-ensemble strict, démontré
comme tel : appliquer l'ancien filtre à l'inventaire complet redonne exactement le
chiffre annoncé.

Trois défauts du jeu de caractères, tous mesurés :

| Défaut | Conséquence |
|---|---|
| le tiret cadratin `—` en était **absent** | `"E — %s"`, `"Arc Link — relier"`, `"%s — soigne %d PV"` invisibles, alors que le dépôt en met partout |
| tout **français sans accent** était invisible | `INVENTAIRE`, `Mains nues`, `Cuisiner`, `Reprendre`, `Attaque`, `Aucune cible`, `Trop loin`, `Lien rompu`, `Arc Step`… |
| l'apostrophe typographique `’` y figurait alors que le dépôt n'en contient **aucune** | entrée morte — et piège : « améliorer » la typographie aurait fait MONTER le compte sans qu'un seul texte soit ajouté |

Le compte réel a ensuite été établi par **deux voies indépendantes** — un miroir
Python du détecteur côté écrivain, un automate à états lisant caractère par
caractère côté contre-analyse — qui se réconcilient au littéral près, **zéro vrai
manqué de part et d'autre**. L'outil a été refondu sur ce constat.

**L'enseignement dépasse la localisation** : un instrument de mesure qui filtre
avant de compter mesure son filtre, pas la grandeur. Le chiffre paraissait précis
et il l'était — sur la mauvaise population.

## La loi : la dette ne remonte pas

`tests/integration/test_localisation_iss075.gd::test_aucun_nouveau_texte_joueur_ecrit_en_dur_dans_le_code`
porte un **plafond par fichier**, mesuré, avec une seule règle : ça ne monte pas.
Descendre est libre. Un fichier migré tombe à zéro et y reste — c'est le cas de
`scripts/ui/gameplay_shell.gd`.

Le détecteur qui l'alimente s'appelle **A9**. Il a remplacé un scanner qui ne
regardait qu'une seule porte d'affichage et qu'une seule ligne à la fois. A9 voit
désormais :

- le texte **sans aucun accent** — c'est le défaut qui a coûté le compteur ;
- les tables `const` **et** `var` ;
- les chaînes multilignes, simples ou triples ;
- le littéral posé dans une variable puis affiché plus loin ;
- le texte rendu par `prompt_verb()` ;
- l'appel d'affichage réparti sur **deux lignes** — la forme qui échappait au
  scanner historique, et dont un sabotage confirme qu'A9 la rattrape.

### Ce que la loi NE couvre pas, dit franchement

**Trois surfaces sont comptées mais pas gardées** :

1. le `text` posé en `.tscn` — `scenes/ui/GameplayShell.tscn` en porte une
   quinzaine, dont **deux doublent un texte du code** (`Mains nues`, `Reprendre`).
   Conséquence connue : le même bouton peut être français au démarrage puis traduit
   au premier rafraîchissement, vocabulaire scindé dans un même panneau ;
2. les verbes de `prompt_verb()` sur les interactables — cinq verbes distincts qui
   remplissent le gabarit `"E — %s"`. Migrer le gabarit sans les verbes laisserait
   l'invite à moitié française : les deux vont ensemble ou aucun ;
3. le `display_name` des `.tres`.

**Trois angles morts subsistent DANS la porte gardée**, mesurés et déclarés plutôt
que devinés : un mot unique en minuscules sans accent hors d'une porte
d'affichage ; une valeur de table seule sur sa ligne ; et le cas symétrique d'un
enrobage qui relaie un appel. Un garde-fou qui devinerait produirait des faux
rouges, et un garde-fou à faux rouges finit désarmé (`PROMPT4_METHOD` §1.2).

### Ce que « couvert » veut dire pour les chemins d'exécution

Le contrat de tranche ne se contente pas de vérifier que les clés existent en
table : il **pilote l'écran réel** et vérifie qu'aucune clé nue n'y paraît. La
distinction a coûté une reprise, et elle mérite d'être retenue.

Une première rédaction annonçait que les clés restantes étaient « tenues par le
contrat ». La contre-revue l'a réfutée par sabotage : deux clés dé-enrobées
traversaient le portail entier **au vert**. Elles étaient épinglées **en table**,
pas gardées **au site d'appel** — deux propriétés différentes, dont une seule
protège l'écran.

La formulation juste, et la seule à employer désormais : les clés de phase du boss
ne sont pas pilotées, parce qu'elles exigent un Gardien vivant ; **leurs valeurs
sont vérifiées en table, leur affichage au site d'appel ne l'est pas.** Toutes les
autres clés de la tranche sont pilotées sur un chemin d'exécution réel.

## Prochaine tranche, si elle est demandée

`scripts/world/training_grounds.gd`, plus gros porteur restant, puis
`scripts/ui/options_panel.gd`. L'ordre et les volumes se relisent dans la sortie
de l'outil, pas ici.

Deux dossiers sont à ouvrir avec la tranche suivante, parce qu'ils la rendront
plus coûteuse s'ils attendent :

- **les `text=` de `scenes/ui/GameplayShell.tscn`**, dont deux doublent déjà un
  texte migré du code. C'est aujourd'hui la seule incohérence de vocabulaire
  visible à l'écran ;
- **les rappels de touches figés dans le texte traduit** — `"Fermer (Tab)"`,
  `"E — %s"`, `"Polarité (Maj : repousser)"`. Ces glyphes dépendent de l'`InputMap`
  et sont aujourd'hui gelés dans la langue source. Une locale qui les traduirait
  mentirait sur le clavier ; une locale qui ne les traduit pas laisse de l'anglais
  d'interface dans une phrase française. Le mécanisme de clés ne tranche pas ce
  problème : il faudra une décision.
