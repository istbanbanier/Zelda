# ISS-075 voie B — rapport intermédiaire : le scanner est réparé

**Écrit AVANT la migration, à dessein.** Le conteneur a déjà été réinitialisé
une fois pendant cette vague ; ce fichier existe pour que le constat survive
même si la suite ne survit pas.

## Ce qui est fait

| | |
|---|---|
| Outil | `tools/classer_textes_joueur.py` — classe par RÔLE SYNTAXIQUE |
| Inventaire | `docs/localisation/INVENTAIRE_gameplay_shell.md` — généré, déterministe |
| Ancien outil | `tools/inventaire_textes_joueur.py` — **laissé intact**, il sert ailleurs |

## Le compte

| Classe | Compte |
|---|---:|
| `J_JOUEUR` | 69 |
| `C_HORS_TRANCHE` (par frame) | 9 |
| `A_ARBITRER` | 3 |
| `N_NON_JOUEUR` | 219 |
| **total littéraux** | **300** |

**69 + 9 = 78 littéraux joueur.** L'ancien compteur en annonce **39**.
Le 78 a été atteint par une méthode entièrement différente de celle qui l'avait
mesuré la première fois — classement par rôle contre comptage manuel — et les
deux tombent sur le même nombre. C'est le seul recoupement disponible ici, et
il vaut mieux que la répétition d'un même calcul.

## Pourquoi `ACC` n'a pas été allongé

Parce que c'est le mauvais axe, et c'est démontrable plutôt qu'opinable :
« Cuisiner », « Surcharge », « Silence » sont typographiquement IDENTIQUES à
« Plate », « Title », « Detail » — mêmes lettres ASCII, même casse, même
absence d'accent. Les premiers vont à l'écran, les seconds nomment des nœuds.
Aucune règle portant sur les caractères ne peut les séparer, parce que
l'information qui les sépare n'est pas dans la chaîne : elle est dans ce que le
code EN FAIT du littéral.

## Ce que la classe `A_ARBITRER` a réellement servi à

Elle n'est pas décorative : à la première exécution elle contenait **24**
entrées, et six d'entre elles étaient des DÉFAUTS DE MES PROPRES RÈGLES, pas
des cas indécidables — `J-NOTIFY` avait oublié la parenthèse ouvrante,
`find_children("*", "StormGuardian", …)` passe son nom de classe en DEUXIÈME
argument, le point fixe « cette fonction alimente un Label » ratait la forme
multi-ligne de `_set_label`. Sans le bucket, ces six seraient partis
silencieusement du côté « pas du texte joueur » — le mode de panne exact de
l'outil qu'on remplace.

Il en reste **3**, et ce sont de vraies indécisions :

| Ligne | Texte | Pourquoi c'est indécidable |
|---:|---|---|
| 1169 | `Plat` | valeur par DÉFAUT d'un `.get("name", "Plat")` sur un chemin d'affichage : elle atteint l'écran, mais seulement si la donnée est déjà cassée |
| 1549 | `s` ×2 | la marque du pluriel est CUITE dans le gabarit `%d cible%s révélée%s`. Ce n'est pas une chaîne traduisible, c'est une règle de grammaire française écrite en dur — un vrai problème de localisation, qui ne se résout pas en ajoutant une clé |

## Le chemin PAR FRAME est dérivé, pas déclaré

La clôture transitive des appels depuis `_refresh_resonance_hud` est
**calculée** par l'outil. Elle attrape `_resonance_action_line`,
`_resonance_state_line` et la table `RESONANCE_ACTIONS` — soit les 9 littéraux
`C_HORS_TRANCHE`. Une liste écrite à la main aurait dit la même chose
aujourd'hui et se serait périmée en silence au premier appel déplacé.

## Vérification faite contre le mode de panne inverse

Un classement par rôle peut cacher du texte joueur dans `N_NON_JOUEUR` aussi
facilement qu'un classement par forme. Balayage des 219 `N_NON_JOUEUR` à la
recherche d'un accent ou d'un espace entre deux mots minuscules : **2 suspects**,
tous deux le tiret cadratin `—` employé comme marque de valeur vide dans un
`Label` (`_refresh_detail`, `_rebuild_cooking_panel`). Classés `N-GABARIT`
(aucune lettre, donc rien à traduire) — règle nommée, donc contestable.

## Ce qui reste, dans l'ordre

1. les trois défauts mesurés (`_charger` mémoïse un échec, `brut()` alloue, deux
   étiquettes réécrites sans garde) — contrats ROUGES d'abord ;
2. la migration des 69 `J_JOUEUR`, sens français octet pour octet identique ;
3. D-065 et les deux conceptions de `meals[].name`.
