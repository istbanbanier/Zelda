# La circularité qui bloque la qualification, et elle est contractuelle

Statut : **contradiction contractuelle**, l'une des conditions d'arrêt que le lead
a nommées lui-même. Constatée le 2026-08-17, sur mesure, pas sur lecture.

## Les trois faits

**1. Un seul portail est rouge dans toute la chaîne.**

Journal complet de la chaîne sur le candidat réparé
(`r2a356_agentB/B6_reparation/04_export_apres.log`) :

| contrôle | verdict |
|---|---|
| connexité | 1 composante, avant et après soustraction |
| épaisseur aux stations | **0,87 m en paroi, 1,15 m au linteau** — au-dessus de 0,80 |
| gabarit | capsule `r=0,45 h=1,85` passe **aux 7 stations** |
| plancher | 54 points sondés, **0 faute** |
| aucun jour | 25 rayons, croisements pairs et ≥ 2 |
| ancres de sol | 4 mesures, écarts `+0,001` à `−0,045` m pour 0,25 de tolérance |
| export glTF | `RC_EXPORT=0` |
| inspection hors moteur | `RC_INSPECT=0`, `=== VALIDE ===` |
| **épaisseur sur le domaine** | **ROUGE — 29 plaques, la plus mince 0,114 m** |

`RC_MAKE=2` vient **uniquement** de la dernière ligne.

**2. Ce portail est déjà déclassé, par un contrat gelé.**

`docs/CONTRAT_COQUE_STRUCTURELLE.md`, figé à `cca1778`, et
`docs/CODEX_HANDOFF.md` §34.2 :

> **balayage vertical** : **conservé, déclassé en télémétrie** de non-régression.
> Motif mesuré : il rend 326 plaques sur R2a-3.4 déjà validée visuellement contre
> 167 sur le candidat — un critère qui condamne plus fort la référence que le
> sujet ne peut pas décider seul.

La décision est prise et gelée. **Le code ne l'applique pas** : dans la pile
candidate, `controle_epaisseur_domaine()` appelle toujours `franchir()` et rend 2.

*Précision que j'ai dû vérifier au lieu de la supposer, et elle durcit le
constat :* la fonction **n'existe ni dans le générateur de `504ecbe`, ni dans
celui du tronc actuel** — `grep -c` rend 0 dans les deux. Elle ne vit que dans
les arbres candidats.

Donc intégrer la pile candidate n'introduit pas seulement une meilleure
géométrie : elle **introduit aussi un portail qui n'existe pas aujourd'hui, et
qu'elle échoue**. C'est le portail lui-même qui est neuf, pas le défaut qu'il
signale.

**3. La directive interdit d'appliquer la décision maintenant.**

R2a-3.5.6 §6 : le déclassement de `controle_epaisseur_domaine()` **uniquement
dans un commit de politique séparé, après qualification verte**.

## La circularité

```
la chaîne ne peut pas devenir verte    tant que le portail n'est pas déclassé
le portail ne peut pas être déclassé   tant que la chaîne n'est pas verte
```

Aucune géométrie ne dénoue cela, parce que ce n'est pas un problème de
géométrie. **Il n'existe pas de sculpture qui rende ce portail vert** : il compte
comme faute de la roche qui n'est pas la coque de la cavité, et la mesure de
l'agent B le prouve sur la seule référence disponible.

## Ce que la mesure ajoute au motif déjà écrit dans le contrat

Le contrat justifiait le déclassement par 326 contre 167. Trois mesures neuves,
faites par deux agents et trois instruments, vont dans le même sens et plus loin.

| critère | livré R2a-3.4 | candidat corrigé |
|---|---:|---:|
| plaques sous 0,80 m | **320** | 29 |
| la plus mince | **0,051 m** | 0,114 m |
| plaques à plus de 4 m de la lèvre | **204**, jusqu'à 9,67 m | 1 |
| déficit `LOI-R` à l'argmin | **0,7758 m** | 0,1000 m |

Et un fait qui n'était pas connu quand le contrat a été écrit :

> **`controle_epaisseur_domaine()` n'existe pas dans le générateur de R2a-3.4.**
> `grep -c` rend 0 ; le chargement échoue sur `AttributeError`. La porte a été
> écrite **après** la livraison.

« Elle n'a jamais été verte » n'est donc pas une figure de style : elle n'existait
pas quand cette géométrie a été validée et livrée au propriétaire. Exiger du
candidat ce que le livré manque onze fois plus fort, sur un critère né après lui,
serait un plancher fabriqué — exactement ce que `tools/CLAUDE.md` nomme *« un
seuil calibré sur une géométrie ensuite rejetée n'est pas un plancher de qualité,
c'est un plancher du défaut »*.

## Les emplacements ne coïncident pas — donc ce n'est pas un déplacement

Seules **8 des 29** plaques du candidat ont une homologue R2a-3.4 à moins de
0,35 m. Le candidat n'a pas déplacé les plaques du livré : il en a supprimé
l'immense majorité et garde un noyau resserré à la bouche — 26 sur 29 à moins de
2 m de la lèvre.

Contrôle de non-effet, gratuit : **29 plaques avant la réparation de `MASSIF`,
29 après, aux mêmes coordonnées au millimètre.** Cohérent avec `SM_` inchangé au
bit près — la porte lit le maillage visuel, pas la collision.

## Ce que je ne fais pas

Je **n'applique pas** le déclassement. La directive l'interdit ici, et c'est une
décision de barre de qualité : elle appartient au propriétaire, pas à la session
(`PROMPT4_METHOD` §13). Les seuils restent identiques —
`EPAISSEUR_MIN_M = 0,80` vérifié identique à `504ecbe`, avec les treize autres.

Je ne franchis pas non plus le portail en diagnostic pour déclarer vert : le
`--diagnostic` sert à mesurer l'aval, il ne qualifie rien, et `RC_MAKE=2` est le
comportement correct.

## La décision qui revient au lead, en une phrase

**Ou bien le déclassement déjà gelé au contrat est appliqué au code — et la
qualification devient possible — ou bien la passe reste `PARTIAL` et aucune
géométrie ne peut plus la débloquer.**

Il n'y a pas de troisième issue qui ne soit pas un mensonge de portail.
