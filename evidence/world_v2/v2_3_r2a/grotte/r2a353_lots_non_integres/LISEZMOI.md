# Ce que R2a-3.5.3 n'a PAS versé au tronc, et pourquoi

Les instruments de la passe **sont** versés — suite adverse 10/10, banc de
mutations, outils de toit, topologie, connexité. Ce dossier ne contient que ce
qui **reste dehors**, avec la raison.

## Le patch de cette passe

| fichier | plage | contenu |
|---|---|---|
| `agentA_controle_epaisseur_domaine.patch` | `507ef6a..bf09e15` | `controle_epaisseur_domaine()` dans le générateur — **257 lignes ajoutées, 0 supprimée**, 4 constantes neuves, **aucun seuil existant touché** |

`git apply --check` sur le socle : **OK**.

Les patches de géométrie de la passe précédente restent valides et sont dans
`../r2a352_lots_non_integres/` : base R2a-3.5.2, source collerette, quatre
commits d'instruments.

## Pourquoi le contrôle étendu n'est pas versé

**Ce n'est pas parce qu'il rougit.** Il rougit, et c'est correct : il voit un
défaut réel que le contrôle précédent ne pouvait pas voir, faute de domaine.
Refuser d'intégrer un test parce qu'il est rouge serait le neutraliser, ce que
la directive interdit et que ce dépôt ne fait pas.

C'est parce qu'il **ne peut pas être versé seul**. Il est écrit contre le
générateur R2a-3.5.2, absent du tronc. Le verser exige donc de verser aussi la
base et la source collerette — et l'ensemble donnerait un dépôt où :

- la **source** dit R2a-3.5.2 ;
- l'**artefact** livré est R2a-3.4 ;
- la **chaîne refuse de les réconcilier**, parce que le contrôle étendu rend
  `RC=1` sur les trois géométries.

Un tronc dont le `.py` ne peut pas produire son propre `.glb`, et qui n'annonce
nulle part que c'est le cas, **ment sur lui-même**. C'est pire qu'un tronc
incomplet, parce que l'incomplétude se voit et le mensonge non.

Le rouge, lui, est publié : `../r2a353_a_toit/chaine_avec_controle_domaine.log`.

## L'arbitrage qui débloque

Le contrat `EPAISSEUR_MIN_M = 0,80 m` n'est tenu par **aucune** géométrie sur le
domaine complet :

| géométrie | roche mince **sur la galerie jouable** |
|---|---:|
| candidat `cc3596c5` | **205** colonnes |
| `BASE352` | **276** |
| **R2a-3.4, la géométrie LIVRÉE** | **202** |

Corriger la seule lame de `(0,50 ; 5,80)` changerait **1 colonne sur 205**. Ce
n'est plus une correction de lame, c'est une refonte d'enveloppe — hors du cadre
de R2a-3.5.3, et hors de ce qu'un agent peut décider seul.

Trois lectures possibles, aucune tranchée ici :

1. **`EPAISSEUR_MIN_M` n'a jamais visé le toit.** Historiquement
   `controle_epaisseur` mesure la **paroi** — aux stations, selon la normale. Le
   balayage vertical sur tout le massif est une *autre* mesure qui réutilise la
   même constante. Il faudrait alors un contrat de toit **nommé séparément**,
   avec son propre seuil — qui ne peut pas être fixé ici sans le calibrer sur la
   géométrie qu'on juge, ce que `tools/CLAUDE.md` interdit explicitement.
2. **Le contrat vaut aussi pour le toit.** Alors la correction à faire est très
   supérieure à ce que cette passe a cadré.
3. **Le domaine contractuel se restreint** à la roche séparant le trajet réel du
   joueur de l'extérieur. Défendable, mais c'est un choix, pas une mesure.

## Comment reprendre

```sh
# la geometrie, dans cet ordre imposé
git apply evidence/.../r2a352_lots_non_integres/base/source_202d849_vers_c79341e.patch
git apply evidence/.../r2a352_lots_non_integres/collerette/source_c79341e_vers_e0e7567.patch
# puis le controle etendu
git apply evidence/.../r2a353_lots_non_integres/agentA_controle_epaisseur_domaine.patch
```

L'ordre n'est pas cosmétique : le contrôle suppose les tables de stations de la
base. L'appliquer sans elle, c'est mesurer un maillage avec les cotes d'un
autre — l'erreur exacte qui a coûté un tour complet à un agent, documentée au
§22 du handoff.

Le GLB candidat se reconstruit depuis la source seule, byte-identique — mesuré
quatre fois, la dernière avec les instruments en place
(`../r2a353_socle/`). Empreinte attendue :
`cc3596c5d68cbfd8060987604aad6d5356772df18086f3f76f5aa8dbf8a73f49`.

## Statut

`CANDIDAT EN ATTENTE D'ARBITRAGE` — pas `REJETÉ`. Rien dans ces patches n'est
faux ; ce qui manque est une décision sur le niveau à atteindre.
