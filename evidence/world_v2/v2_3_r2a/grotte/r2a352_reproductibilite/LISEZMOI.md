# Le GLB candidat est reproductible byte-identique — mesuré deux fois, plus un contrôle négatif

**Ce dossier ne valide aucune livraison.** Il répond à une seule question, qui est
la principale condition d'arrêt de la passe R2a-3.5.2 :

> « Le GLB produit doit être byte-identique au candidat attendu et retrouver le
> SHA256 complet commençant par `cc3596c5`. Si le hash diffère : arrête
> l'intégration. »

**La réponse est oui.** La condition d'arrêt ne se déclenche pas.

## Protocole

Worktree isolé `/home/user/zelda-r2a352/determinisme`, créé sur `e0e7567`
(HEAD du lot collerette), arbre propre. Chaîne officielle, sous verrou global :

```
tools/blender/export_architecture.sh waterfall_cave
```

Elle régénère le `.blend` depuis `make_waterfall_cave.py`, exporte le `.glb`,
puis l'inspecte hors moteur. Ses deux garde-fous sont actifs : `--python-exit-code 1`
et le jeton de fraîcheur qui refuse de valider un `.glb` non réécrit.

## Les trois passages

| | source | RC | GLB produit |
|---|---|---:|---|
| **run 1** | `e0e7567` — avec collerette | **0** | `cc3596c5d68cbfd8060987604aad6d5356772df18086f3f76f5aa8dbf8a73f49` |
| **run 2** | idem, relancé | **0** | `cc3596c5d68cbfd8060987604aad6d5356772df18086f3f76f5aa8dbf8a73f49` |
| **run 3** | `c79341e` — **sans** collerette | **1** | aucun — la chaîne refuse |

Les deux premiers rendent la **même empreinte à 64 caractères**, et elle est
celle du candidat versionné dans `b_collerette`. `git status` ne voit aucune
modification du `.glb` : la reproduction est exacte du point de vue de Git aussi.

Chaque passage imprime `20970 triangles` et `=== VALIDE ===` à l'inspection glTF.

## Le contrôle négatif — et il prouve deux choses à la fois

Le run 3 bascule **uniquement** le fichier source sur la version d'avant la
collerette, tout le reste inchangé. Résultat : le générateur sort **non-zéro**,
la chaîne passe au **ROUGE**, et **aucun `.glb` n'est écrit**.

Cause imprimée par le générateur lui-même :

```
[grotte] collerette la plus mince : station 0, azimut 32°, z 1.26
[grotte] ERREUR: station 0, azimut 39° — 0 croisement(s) seulement : le rayon sort par un JOUR
[grotte] ERREUR: station 0, azimut 45° — 0 croisement(s) seulement : le rayon sort par un JOUR
[grotte] ERREUR: station 0, azimut 51° — 0 croisement(s) seulement : le rayon sort par un JOUR
[grotte] ERREUR: station 0, azimut 58° — 0 croisement(s) seulement : le rayon sort par un JOUR
[grotte] ERREUR: station 0, azimut 64° — 0 croisement(s) seulement : le rayon sort par un JOUR
```

C'est **exactement** le défaut que le lot collerette a corrigé, reproduit ici par
le générateur du tronc, sans instrument tiers : au porche, sur une partie du
pourtour, **le rayon ne rencontre aucune roche du tout**.

Ce que le contrôle établit :

1. **le `.glb` dépend réellement de la source** — un `.py` différent ne rend pas
   le même fichier, il ne rend aucun fichier ;
2. **la reproduction des runs 1 et 2 n'est pas un artefact de chaîne inerte.**
   Sans ce troisième passage, « la chaîne rend `cc3596c5` » aurait pu vouloir
   dire « la chaîne n'a rien fait et le fichier d'hier est resté là ». Le piège
   est documenté dans `tools/CLAUDE.md` : *exporter à la main après une chaîne
   interrompue rend l'ANCIEN maillage — nouveau nom, nouvelle date, octets
   identiques.* Le jeton de fraîcheur l'a d'ailleurs attrapé ici : la chaîne est
   passée au rouge au lieu de revalider le fichier présent.

## Le `.blend`, lui, n'est PAS reproductible — et cela a une conséquence

| | sha256 |
|---|---|
| versionné à `e0e7567` | `c29131661550d558edf37182a4e0bae6e95a104937e2120a1747d5d9da4edeef` |
| après run 1 | `3c19d05ebbde9d053f1ee3b3458750e63f29e8fdc164433a6936e000fdde71c0` |
| après run 2 | `b468b665874815824d319d022b5e6aefa138e1dd0943cab45dafcda5ba247eb7` |

Trois empreintes pour la même entrée. C'est le comportement documenté de Blender
(`tools/blender/run_export.sh` : « Blender ne réécrit pas un `.blend` octet pour
octet à l'identique »).

**Conséquence opérationnelle pour l'intégration** : après chaque passage de la
chaîne, l'arbre sera **sale sur le `.blend`** et propre sur le `.glb`. La séquence
d'intégration doit donc comporter un `git checkout -- <blend>` explicite **après**
l'export et **avant** le commit du GLB, faute de quoi aucune capture ne pourra
être prise d'un arbre propre.

Autrement dit : le `.blend` est un **conteneur**, pas la source. La source est le
`.py`, et c'est lui qui détermine la géométrie.

## Fichiers

| fichier | contenu |
|---|---|
| `run1_export_depuis_e0e7567.log` | premier passage, sortie intégrale, RC |
| `run2_export_depuis_e0e7567.log` | second passage, idem |
| `run3_controle_negatif_source_sans_collerette.log` | le passage qui doit rougir, et rougit |
| `run3_generateur.log` | le journal du générateur, avec les cinq azimuts qui sortent par un jour |

Worktree restauré à l'état `e0e7567` après mesure : `git status` vide, les trois
empreintes (`.py`, `.blend`, `.glb`) conformes au commit.

Aucun seuil modifié. Aucune géométrie intégrée par ce dossier.
