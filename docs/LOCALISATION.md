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

## Ce qui est migré — et rien de plus

Deux tranches. La **première** (2026-08-29) : le camp braise et les premiers
textes d'une partie neuve, neuf clés, listées ci-dessous. La **seconde**
(2026-08-31) : `scripts/ui/gameplay_shell.gd`, dont le détail vit dans
`docs/localisation/INVENTAIRE_gameplay_shell.md` et `docs/handoff/ISS-075.md`
plutôt qu'ici — un inventaire recopié en prose diverge du réel sans que
personne ne le remarque.

Les neuf clés de la première tranche :

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
**clé** sur `EventBus`, et c'est le HUD (`gameplay_shell._on_notification`) qui
la résout. Le script gelé portait déjà la note « le jour où une localisation
arrive, c'est le JSON qu'elle remplace, pas cette ligne » — c'est exactement ce
qui a été fait.

## Ce qui NE l'est pas — le compte exact

Mesuré le 2026-08-29 par `tools/inventaire_textes_joueur.py` — **le script est
committé**, donc le chiffre se rejoue. Une première rédaction de cette phrase
affirmait qu'il vivait dans `tools/` alors qu'il n'y était pas : c'était un
compteur en prose sans preuve, exactement ce que la règle d'ancrage du
`CLAUDE.md` interdit. Sortie datée :
`evidence/world_v2/camp_hardening/inventaire_textes_joueur.txt`.

```
python3 tools/inventaire_textes_joueur.py
```


| Catégorie | Littéraux | Fichiers |
|---|---:|---:|
| Texte joueur non migré | **200** | 54 |
| Texte diagnostic (journaux, `push_error`) — hors périmètre | 138 | 54 |
| Hors build joué (`scripts/tools/`, `scenes/tests/`) | 68 | 13 |

Les cinq plus gros porteurs annoncés : `gameplay_shell.gd` (39),
`training_grounds.gd` (26), `discovery_rewards.gd` (11), `options_panel.gd` (9),
`reward_anchor_audit.gd` (7).

> **CE COMPTEUR SOUS-COMPTE, et de beaucoup.** Mesuré le 2026-08-31 :
> `gameplay_shell.gd` porte **78** littéraux joueur, pas 39. `ACC` exige un
> caractère accentué ou typographique, si bien que « INVENTAIRE »,
> « Commandes », « Mains nues », « Surcharge », « Silence » — du français sans
> accent — ne sont pas vus. **Allonger `ACC` ne peut pas réparer cela** :
> « Cuisiner », « Surcharge » et « Silence » sont typographiquement identiques
> à « Plate », « Title » et « Detail ». L'information qui les sépare n'est pas
> dans la chaîne, elle est dans ce que le code EN FAIT.
>
> `tools/classer_textes_joueur.py` classe par **rôle syntaxique** et rend le
> nom de la règle appliquée à chaque littéral. Voir
> `docs/localisation/INVENTAIRE_gameplay_shell.md`. Les chiffres du tableau
> ci-dessus sont donc un **plancher**, pas un compte, tant que les autres
> fichiers n'ont pas été repassés au nouvel outil.

Le texte **diagnostic** ne sera pas traduit : un journal moteur s'adresse à qui
lit le code, pas au joueur.

## `meals[].name` — deux conceptions, aucune choisie

Les noms de plats de `scripts/cooking/recipe_rules.gd` (`EFFECT_NAMES` :
« Ragoût du guerrier », « Potée du rempart », « Sauté du grimpeur », « Confit
paratonnerre », plus les replis « Ragoût instable », « Plat simple », « Plat
mijoté ») restent du **français figé**. Ils ne sont pas dans la tranche ISS-075
voie B, et `RecipeRules` n'a pas été modifié.

La difficulté n'est pas de traduire sept chaînes. C'est que `name` **traverse
une sauvegarde** : `test_phase_e_chain.gd` vérifie qu'un plat survit à un
rechargement, et l'instantané porte le plat créé. Ce que la sauvegarde retient
décide de la conception.

**Conception A — la sauvegarde retient la CLÉ.** `RecipeRules` rend
`"name": "cuisine.plat.guerrier"`, et chaque affichage résout. Un joueur qui
change de langue voit ses plats déjà cuisinés changer de nom, ce qui est le
comportement attendu.
*Coût :* migration des sauvegardes existantes — un instantané d'avant porte du
français là où le code attendra une clé. `SaveSystem` a déjà un schéma versionné
et des migrations, donc le mécanisme existe ; il faut écrire la migration, et
elle doit traduire à l'envers (français → clé) pour les sauvegardes anciennes,
ce qui n'est fiable que tant que les sept chaînes sont uniques. Elles le sont
aujourd'hui.
*Risque :* une sauvegarde d'une version future portant un nom retiré de la table
afficherait ⟦clé⟧. Il faut décider si c'est acceptable ou si le repli garde le
dernier français connu.

**Conception B — la sauvegarde retient le FRANÇAIS RENDU.** `RecipeRules` résout
à la création et stocke le texte. Aucune migration : les sauvegardes existantes
sont déjà au bon format.
*Coût :* un plat cuisiné avant une bascule de langue garde son ancien nom pour
toujours. Le joueur voit un inventaire à deux langues.
*Risque :* aucun sur la donnée ; le défaut est visible et permanent à l'écran.

**Ce qui n'est PAS un départage :** le nombre de chaînes (sept dans les deux
cas) et l'effort d'écriture (comparable). Le départage est la question « un plat
déjà cuisiné doit-il changer de nom quand la langue change ? ». C'est une
décision de produit, et elle appartient au propriétaire.

## La loi, et ce qu'elle ne couvre pas

`test_localisation_iss075.gd::test_aucune_nouvelle_porte_notify_...` interdit
qu'un **nouveau** texte joueur écrit en dur passe par `call("notify", "…")`.
Plafond par fichier, dette mesurée, « ça ne monte pas ». Descendre est libre.

La porte `notify` est choisie parce qu'elle est **indiscutable** : tout ce qui
la franchit finit sur l'écran. Restent **non couvertes** : `prompt_verb()`, le
`text` posé en `.tscn`, `display_name` des `.tres`. Un garde-fou qui devinerait
produirait des faux rouges, et un garde-fou à faux rouges finit désarmé
(PROMPT4 §1.2). Elles sont comptées ci-dessus, pas gardées.

**Ce que la loi `notify` ne voit pas, mesuré le 2026-08-31.** Elle ne garde que
`call("notify", "…")`. Elle ne voit **aucune** affectation `.text =`, ni les
tables de libellés. `gameplay_shell.gd` portait ainsi des dictionnaires entiers
hors de sa portée : noms de buffs, phases de boss, motifs de refus de Résonance.
Le cliquet n'a **pas** été étendu à ces sites : une porte `.text =` est
syntaxiquement banale, et l'étendre produirait des faux rouges sur les gabarits
sans mot (`"%s  %d/%d"`) — un garde-fou à faux rouges finit désarmé. Les sites
sont épinglés un par un à la place, par `tests/unit/test_textes_iss075.gd`.

### L'angle mort DANS la porte gardée, et il est vivant

Le scanner ne lit qu'un littéral placé sur **la même ligne** que `"notify"`.
Trois formes lui échappent, et la contre-revue en a trouvé une **en service** :

| Forme | Exemple réel |
|---|---|
| un **enrobage** qui relaie | `scripts/tools/dev_mode.gd` — `_notify()` fait `bus.call("notify", text)` ; ses trois textes français crus comptent **zéro** |
| le littéral porté par une variable | `bus.call("notify", message)` |
| l'appel réparti sur deux lignes | `bus.call("notify",\n\t"…")` |

`dev_mode.gd` ne part pas dans un build joué, donc l'impact est nul aujourd'hui
— mais l'angle mort, lui, est général. Le déclarer vaut mieux que de laisser
croire que la porte est étanche : **la loi empêche la dette de croître par le
chemin direct, pas par un enrobage.** Fermer l'enrobage demanderait de suivre
les appels, ce qu'un scan textuel ne fait pas sans faux positifs.

Contrôle négatif joué : un `bus.call("notify", "Un texte joueur tout neuf,
écrit en dur.")` ajouté dans `reset_button.gd` rend la loi ROUGE, et elle
seule.

## Prochaine tranche, si elle est demandée

`gameplay_shell.gd` **est fait** (2026-08-31). La note qui tenait cette place
annonçait « 39 littéraux, dont quatre tables `StringName -> String` de
35 entrées » : le compte était faux — il y en avait **78** — et « les basculer
en clés est mécanique » l'était aussi. La bascule mécanique a produit **deux
défauts silencieux**, tous deux attrapés par un contrat et non par relecture :
un échappement `\n` non décodé sur trois libellés, et une clé qui a reçu la
mauvaise valeur parce qu'une ligne portait deux littéraux. Le détail est dans
`evidence/world_v2/iss075/20_JOURNAL.md`.

**La tranche suivante n'est pas un fichier, c'est une règle.** Le classeur
`tools/classer_textes_joueur.py` ne couvre pas encore les **dictionnaires en
ligne** (`{"title": "…", "key": "…"}`), l'idiome de `training_grounds.gd`,
`options_panel.gd`, `valley_relics.gd` et de la plupart des bâtisseurs de
monde. Sans elle, aucun compte de dette n'est publiable, et migrer reviendrait
à travailler à l'aveugle. Voir `docs/handoff/ISS-075.md`, « Prochaine action
exacte ».
