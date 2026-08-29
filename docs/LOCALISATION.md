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

9 clés. Le camp braise, et les premiers textes d'une partie neuve.

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

Mesuré le 2026-08-29 (`tools/` porte le script d'inventaire) :

| Catégorie | Littéraux | Fichiers |
|---|---:|---:|
| Texte joueur non migré | **200** | 54 |
| Texte diagnostic (journaux, `push_error`) — hors périmètre | 138 | 54 |
| Hors build joué (`scripts/tools/`, `scenes/tests/`) | 68 | 13 |

Les cinq plus gros porteurs : `gameplay_shell.gd` (39), `training_grounds.gd`
(26), `discovery_rewards.gd` (11), `options_panel.gd` (9),
`reward_anchor_audit.gd` (7).

Le texte **diagnostic** ne sera pas traduit : un journal moteur s'adresse à qui
lit le code, pas au joueur.

## La loi, et ce qu'elle ne couvre pas

`test_localisation_iss075.gd::test_aucune_nouvelle_porte_notify_...` interdit
qu'un **nouveau** texte joueur écrit en dur passe par `call("notify", "…")`.
Plafond par fichier, dette mesurée, « ça ne monte pas ». Descendre est libre.

La porte `notify` est choisie parce qu'elle est **indiscutable** : tout ce qui
la franchit finit sur l'écran. Restent **non couvertes** : `prompt_verb()`, le
`text` posé en `.tscn`, `display_name` des `.tres`. Un garde-fou qui devinerait
produirait des faux rouges, et un garde-fou à faux rouges finit désarmé
(PROMPT4 §1.2). Elles sont comptées ci-dessus, pas gardées.

Contrôle négatif joué : un `bus.call("notify", "Un texte joueur tout neuf,
écrit en dur.")` ajouté dans `reset_button.gd` rend la loi ROUGE, et elle
seule.

## Prochaine tranche, si elle est demandée

`gameplay_shell.gd` : 39 littéraux, dont quatre tables `StringName -> String`
de 35 entrées. C'est le plus gros gain par fichier, et les tables sont déjà de
la donnée — les basculer en clés est mécanique.
