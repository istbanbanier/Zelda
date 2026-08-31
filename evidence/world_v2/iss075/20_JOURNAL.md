# ISS-075 voie B — journal de la passe

Arbre `wt-B`, branche `claude/world-v2-iss075-gameplay-shell`, base `8c6955c6`.
Moteur : Godot v4.7.1.stable.custom_build.a13da4feb.

## 1. Le compteur était faux, et le réparer était la précondition

`tools/inventaire_textes_joueur.py` annonce **39** littéraux joueur pour
`scripts/ui/gameplay_shell.gd`. Il y en a **78**.

Le critère de l'ancien outil est la FORME : un caractère de sa constante `ACC`
doit être présent. `ACC` porte l'apostrophe typographique mais ni le tiret
cadratin ni l'apostrophe droite, et surtout elle exige un accent — si bien que
« INVENTAIRE », « Commandes », « Mains nues », « Surcharge », « Silence » ne
sont pas vus. Ce ne sont pas des cas tordus : ce sont les plus ordinaires.

**`ACC` n'a pas été allongée**, parce que c'est le mauvais axe et que c'est
démontrable plutôt qu'opinable : « Cuisiner », « Surcharge » et « Silence » sont
typographiquement IDENTIQUES à « Plate », « Title » et « Detail » — mêmes
lettres ASCII, même casse, même absence d'accent. Les premiers vont à l'écran,
les seconds nomment des nœuds. Aucune règle portant sur les caractères ne peut
les séparer.

`tools/classer_textes_joueur.py` décide sur le **rôle syntaxique** : à quoi le
littéral est affecté, passé ou retourné. Chaque littéral sort avec le NOM de la
règle qui l'a classé.

| Classe | Compte |
|---|---:|
| `J_JOUEUR` | 69 |
| `C_HORS_TRANCHE` (chemin par frame) | 9 |
| `A_ARBITRER` | 3 |
| `N_NON_JOUEUR` | 219 |
| total | 300 |

**69 + 9 = 78.** Ce nombre a été atteint par une méthode entièrement différente
de celle qui l'avait mesuré la première fois. C'est le seul recoupement
disponible, et il vaut mieux que la répétition d'un même calcul.

### La classe `A_ARBITRER` a servi, et voilà à quoi

À la première exécution elle portait **24** entrées. Six étaient des DÉFAUTS DE
MES PROPRES RÈGLES, pas des cas indécidables :

| Défaut | Ce qu'il laissait passer |
|---|---|
| `J-NOTIFY` sans la parenthèse ouvrante | les deux `_on_notification("…")` |
| `find_children("*", "X", …)` : nom de classe en **2e** argument | `PlayerController`, `StormGuardian` |
| point fixe `_set_label` monoligne | les deux fabricants de libellés de Résonance |
| pas de flot intra-fonction | tout l'aperçu de cuisine, construit par `+=` |
| pas de règle `match` | les étiquettes de branche de `_effect_display_name` |
| pas de règle « liste de boucle » | `PausePanel`, `DeathPanel`, `InventoryPanel` |

Sans le bucket, ces six seraient partis silencieusement du côté « pas du texte
joueur » — le mode de panne exact de l'outil remplacé. Il en reste **3**, et ce
sont de vraies indécisions (voir l'inventaire).

### Vérification contre le mode de panne inverse

Un classement par rôle peut cacher du texte joueur dans `N_NON_JOUEUR` aussi
facilement qu'un classement par forme. Balayage des 219 à la recherche d'un
accent ou d'un espace entre deux mots minuscules : **2 suspects**, tous deux le
tiret cadratin employé comme marque de valeur vide dans un `Label`. Classés
`N-GABARIT` — règle nommée, donc contestable.

## 2. Les trois défauts, et un quatrième trouvé en chemin

| # | Défaut | Correction |
|---|---|---|
| 1 | `_charger` posait `_charge = true` AVANT le balayage : un `DirAccess.open` nul mémoïsait l'échec en succès pour tout le processus (forme d'ISS-071) | le drapeau se pose APRÈS un chargement ayant produit au moins une table ; le balayage est extrait en `_charger_depuis(chemin)`, visible par un test |
| 2 | `_tables.get(demandee, {})` : le littéral `{}` est une EXPRESSION, compilée en `OPCODE_CONSTRUCT_DICTIONARY` et évaluée à chaque appel | `if not _tables.has(demandee): return ""` |
| 3 | `_refresh_weapon_text` et `_refresh_buff_label` réécrivaient `.text` dix fois par seconde sans garde | routées par `_set_label`, qui compare avant d'écrire |
| **4** | **`_refresh_boss_bar` faisait exactement la même chose et n'était nommée nulle part** | même correction |

Le quatrième a été trouvé en lisant `_process`, pas en lisant la consigne :
l'accumulateur `HUD_TEXT_REFRESH` garde **trois** appels, pas deux.

## 3. L'interdiction dure a été respectée, et rendue vérifiable

`_refresh_resonance_hud` court à chaque frame et n'a reçu **aucun** `Textes.t()`.
Les 9 littéraux joueur de ce chemin sont `C_HORS_TRANCHE`, à dessein.

Ce n'est pas une promesse : `test_textes_iss075.gd::B4` **calcule** la clôture
transitive des appels depuis `_refresh_resonance_hud` en lisant la source, et
exige qu'aucune fonction atteinte ne contienne `Textes.t(`. Une liste écrite à
la main dirait la même chose aujourd'hui et se périmerait au premier appel
déplacé.

## 4. Le ROUGE non planifié — et pourquoi il valait la passe

`B5` compare le français rendu à quatorze valeurs **transcrites à la main**.
Il a rougi du premier coup, sur `cuisine.apercu.instable` :

```
attendu (mélange instable : …)   ← un vrai saut de ligne
obtenu  \n(mélange instable : …) ← deux caractères
```

**C'était une vraie régression, pas un artefact de test.** La table `fr` est
GÉNÉRÉE depuis les littéraux du fichier d'origine — et un littéral GDScript
porte ses ÉCHAPPEMENTS. `"\n(mélange…"` est une séquence de deux caractères
dans la source, que le moteur décode en un saut de ligne. Recopiée telle quelle
dans du JSON, elle redevenait deux caractères. **Trois libellés** étaient
touchés, dont tout le panneau de détail d'une arme
(`Dégâts %.0f\nPortée %.1f m\nDurabilité %d / %d`) : le joueur aurait lu les
trois lignes sur une seule, avec deux `\n` visibles.

Une comparaison de la table à sa propre source ne l'aurait **jamais** vu : les
deux auraient porté la même erreur. C'est exactement l'auto-comparaison décrite
dans `tests/CLAUDE.md`, et la transcription manuelle est ce qui l'a évitée.

Corrigé, et gardé par un cas neuf (`test_aucune_valeur_ne_porte_un_echappement_non_decode`)
qui balaie les 74 valeurs de `fr.json`.

## 5. Les 23 pins préexistants

Rejoués explicitement — `gate_select.sh` ne sélectionne rien sur un diff de
`.json` et sort en 0, donc les fichiers sont nommés :

```bash
tools/lancer_godot.sh --path . --script tools/godot/test_runner.gd -- \
  --filter=hud_and_inventory,interaction_reachable,resonance_hud,cooking_ui,\
phase_e_chain,interact_is_never_silent,hud_style,localisation_iss075,bow_fires
```

**44 réussis, 0 échoué, 0 erreur de script.** Aucun pin n'a été ajusté.

Le cas qui comptait le plus est
`test_resonance_hud::test_an_unknown_verdict_is_shown_raw_rather_than_swallowed` :
il prouve que le repli sur l'identifiant brut a survécu au passage des tables
en clés. `_libelle` le conserve, et `B7` l'épingle à son tour.

## 6. Ce que la passe N'A PAS fait

- **`meals[].name`** : non traduit. Deux conceptions chiffrées dans
  `docs/LOCALISATION.md`, aucune choisie. `RecipeRules` non modifié.
- **Le pluriel** : `"Impulsion — %d cible%s révélée%s"` cuit la règle du pluriel
  français dans le gabarit. Aucune clé ne répare cela. Laissé `A_ARBITRER`.
- **Les 4 gabarits sans mot** : `"%s%s\n%d/%d"`, `"%s  %d/%d"`,
  `"%.4f rad/px"`, `"%s  ×%d"`. Rien à traduire.
- **Le cliquet `PLAFOND_NOTIFY`** : **non étendu** aux `.text =`. Une porte
  `.text =` est syntaxiquement banale ; l'étendre produirait des faux rouges sur
  les gabarits sans mot, et un garde-fou à faux rouges finit désarmé
  (PROMPT4 §1.2). Les sites sont épinglés un par un à la place.
- **La persistance de la locale** : appartient à `UserSettings`. Hors tranche.
- **L'ancien scanner** : laissé intact, il sert ailleurs. `docs/LOCALISATION.md`
  porte désormais l'avertissement qu'il sous-compte.

## 7. La locale témoin, et pourquoi elle n'a pas été complétée

`en.json` dit d'elle-même ce qu'elle est : « elle n'est pas là pour livrer le
jeu en anglais, elle est là pour PROUVER que la clé traverse une vraie
indirection ». La compléter ne prouverait rien de plus et coûterait 65
traductions qu'aucun test ne lirait.

Chiffres mesurés sur l'arbre de cette passe :

| | |
|---|---:|
| clés de `fr.json` (hors `_doc`) | 74 |
| clés de `en.json` | 8 |
| clés qui retomberont sur le français | 66 |

C'est une **couverture**, pas une alarme : `Textes.t()` distingue « la
traduction n'est pas faite » (repli silencieux, compté) de « le texte n'existe
pas » (`push_error` et ⟦clé⟧ à l'écran). Le premier chiffre monte sans rien
casser ; le second doit rester à zéro, et `B6` l'y tient.

Le trou volontaire de `menu.options.sous_titre` est **intact** :
`test_localisation_iss075.gd::A5` en dépend pour faire courir le chemin de
repli, et le combler rendrait ce chemin non testé.

## 8. Le SECOND défaut de ma propre migration, et le contrat qui manquait

Trouvé en vérifiant, après coup, qu'aucun français ne restait dans le fichier
migré. Il en restait neuf littéraux — et huit étaient les `C_HORS_TRANCHE`
attendus. Le neuvième ne l'était pas :

```gdscript
_on_notification("Cuisiné : %s" % String(result.get("name", "Plat")))
```

**Cette ligne portait DEUX littéraux joueur.** Ma carte clé→littéral était
indexée par NUMÉRO DE LIGNE, donc le second écrasait le premier. Résultat : la
clé `cuisine.plat_cuisine` a reçu **« Plat »** au lieu du gabarit du message, et
le vrai texte affiché est resté écrit en dur.

**Aucun contrat ne rougissait**, et c'est le point intéressant :

| Contrat | Pourquoi il laissait passer |
|---|---|
| `B5` | il n'épingle que 14 valeurs transcrites, et pas celle-là |
| `B6` | il vérifie que la clé EXISTE et résout — « Plat » existe et résout |
| `B7` | il ne regarde que les trois tables `const` |
| A8 (`PLAFOND_NOTIFY`) | il ne garde que `call("notify", …)`, pas `_on_notification(` |

Le contrat qui manquait est `B10`, et il n'est pas une liste gelée : il
**dérive** l'autorisation. Du français peut rester dans ce fichier, mais
**seulement là où `B4` interdit précisément de le traduire** — le chemin par
frame. Partout ailleurs, un littéral français est du travail non fait, pas une
exception. Mesuré après correction : les 9 littéraux français restants sont
exactement les 9 `C_HORS_TRANCHE`, et aucun autre.

Portée du défaut, mesurée plutôt que supposée : **une seule ligne** du fichier
portait plusieurs littéraux joueur (la ligne 1169 d'origine). L'autre ligne à
deux littéraux porte les deux `"s"` du pluriel, qui n'étaient pas migrés.

### Ce que j'en retiens pour la relecture

Deux défauts de cette passe ont été trouvés par un contrat, pas par relecture :
l'échappement `\n` non décodé (§4) et celui-ci. Les deux étaient **silencieux** —
la clé existait, elle résolvait, rien ne plantait, et le joueur lisait autre
chose que prévu. C'est exactement le mode de panne que la localisation
introduit : elle remplace une erreur bruyante (le texte manque) par une erreur
muette (le texte est faux). Les contrats qui comptent sont donc ceux qui
comparent le RENDU à une source indépendante, pas ceux qui vérifient qu'une clé
existe.

## 9. Les preuves rejouables, et ce que chacune vaut

| Commande | Ce qu'elle établit | Ce qu'elle N'établit PAS |
|---|---|---|
| `python3 evidence/world_v2/iss075/preuve_identite.py` | les 65 valeurs de cette passe se retrouvent mot pour mot dans `8c6955c6:scripts/ui/gameplay_shell.gd` | rien sur une erreur commise PENDANT la génération : les échappements `\n` étaient faux des deux côtés, donc invisibles ici |
| `python3 evidence/world_v2/iss075/preuve_b10.py` | la règle de `B10` discrimine : 0 sur la version corrigée, 1 sur la version buguée | rien sur la fidélité de sa transcription en GDScript — c'est `S6` qui le prouve |
| `git show 8c6955c6:scripts/ui/gameplay_shell.gd > /tmp/avant.gd && python3 tools/classer_textes_joueur.py /tmp/avant.gd _refresh_resonance_hud sortie.md` | l'inventaire se régénère à l'octet près | rien sur la justesse des règles — elles sont nommées pour être contestées |
| `tools/lancer_godot.sh --path . --script tools/godot/test_runner.gd -- --filter=textes_iss075` | les dix contrats dans le moteur | rien sans les sabotages : un contrat vert dont on n'a pas vu le rouge ne prouve rien |

Le bras qui a réellement attrapé les deux défauts silencieux de cette passe
n'est aucun des trois premiers : c'est **`FRANCAIS_ATTENDU`**, quatorze valeurs
transcrites à la main dans `tests/unit/test_textes_iss075.gd`. Une preuve
dérivée de la même source que ce qu'elle vérifie ne peut pas voir une erreur
présente dans les deux. C'est le coût, et l'intérêt, d'une troisième copie
écrite séparément.

## 10. Le résultat, et ce que la contention du verrou a coûté

**Vert final : 56 réussis, 0 échoué, 0 erreur de script** — les 12 contrats de
`test_textes_iss075.gd` plus les 44 cas des neuf fichiers déjà épinglés. Aucun
pin n'a été ajusté. `tests/unit/test_textes_iss075.gd.uid` est généré (les
22 autres tests unitaires en ont un committé ; le mien manquait).

**La preuve par sabotage a été réorganisée en cours de route, et il faut le
dire.** Le plan initial était six lancements isolés. Le verrou
`heavy_tools.lock` est partagé par tout le dépôt, et une suite complète voisine
l'a tenu **72 minutes**. Pire : `tools/lancer_godot.sh` attend par défaut
`--attente=3000` (50 min) puis **abandonne** — mon premier lancement était à
2 738 s d'attente quand je l'ai arrêté, soit à quatre minutes d'un abandon qui
aurait journalisé un `=== RÉSULTAT` vide et fait passer « le verrou n'a jamais
été obtenu » pour « le contrat n'a pas rougi ».

La chaîne a donc été relancée en **quatre prises de verrou** au lieu de neuf,
avec `--attente=9000`, et les six sabotages groupés en deux passes de trois
visant des fichiers et des fonctions disjoints. Ce que ce groupage prouve et ne
prouve pas est écrit dans `10_SABOTAGES.md`.

**La leçon, pour la prochaine session :** le défaut de `--attente` est calibré
pour un dépôt où personne d'autre ne tourne. Dès qu'une voie voisine lance une
suite complète, il est trop court, et son expiration ne ressemble pas à une
panne — elle ressemble à un test qui passe.

## 10. Le résultat, et ce que la contention du verrou a coûté

**Vert final : 56 réussis, 0 échoué, 0 erreur de script** — les 12 méthodes de
`test_textes_iss075.gd` plus les 44 cas des neuf fichiers déjà épinglés. Aucun
pin n'a été ajusté. `tests/unit/test_textes_iss075.gd.uid` est généré : les
22 autres tests unitaires en ont un committé, le mien manquait.

**Sabotage : deux passes de trois, et il faut dire pourquoi.** Le plan était six
lancements isolés. Le verrou `heavy_tools.lock` est partagé par tout le dépôt,
et une suite complète voisine l'a tenu **72 minutes**. Pire :
`tools/lancer_godot.sh` attend par défaut `--attente=3000` (50 min) puis
**abandonne** — mon premier lancement était à 2 738 s d'attente quand je l'ai
arrêté, soit à quatre minutes d'un abandon qui aurait journalisé un
`=== RÉSULTAT` vide. « Le verrou n'a jamais été obtenu » aurait alors ressemblé
trait pour trait à « le contrat n'a pas rougi ».

La chaîne a donc été relancée en **quatre prises de verrou** au lieu de neuf,
avec `--attente=9000`, les six sabotages groupés en deux passes de trois visant
des fichiers et des fonctions disjoints. Résultat : trois méthodes rouges par
passe, exactement les attendues, neuf vertes à chaque fois.

**Deux leçons pour la prochaine session :**

1. Le défaut `--attente=3000` est calibré pour un dépôt où personne d'autre ne
   tourne. Dès qu'une voie voisine lance une suite complète, il est trop court,
   et son expiration **ne ressemble pas à une panne** — elle ressemble à un
   test qui passe.
2. `cut -c` compte des **octets**, pas des caractères. Il a coupé deux
   caractères accentués en deux et rendu le journal non décodable. Corrigé,
   mais le geste est à éviter dans un fichier de preuve.
