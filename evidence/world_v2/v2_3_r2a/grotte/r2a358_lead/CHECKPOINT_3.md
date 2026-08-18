# R2a-3.5.8 — checkpoint 3 : le zéro est atteint en it.0 + it.1, reproduit par le lead

Date : 2026-08-18.

## 1. Résultat de l'agent A — `cav×env` 4 → 0

GLB `5ff4ec6ee7a5bb6f…`, 1 488 700 octets, obtenu en **it.0 (gratuite) + it.1** ;
l'it.2 et la réserve n'ont pas servi. **Budget consommé : 1 itération sur 3.**

L'it.0 a d'abord **reproduit exactement** les 4 paires (`258/640`, `258/681`,
`261/640`, `261/681`) au même repli `0,243436 m` sur l'état complet fusionné —
jamais exporté auparavant — avec le `COL` d'entrée bit-identique au final 3.5.7.
L'arbitrage des couches (checkpoint 2) a été appliqué : hunks `soustraire()` de
`massif_lissage` exclus, appel ET définition, `_triplet_colineaire_exact`
vérifié sans autre appelant ; candidat ré-épinglé `102cc33d…`, source finale
`28535fb3…`, delta de passe 259 l (`750151d5…`).

## 2. La cause réelle — et elle inverse le diagnostic de départ

Ce n'était pas l'alcôve de la cavité : **la queue de l'enveloppe (st7-9,
az9-11) revendiquait comme roche une bande que le visible donne au vide de la
niche** — deux repères de section se disputaient la bande. Deux directions de
correction sont mortes avec leurs mesures (vers l'axe : le besoin CROÎT de
0,2065 à 0,2546 sur 6 tours ; le long du radial sortant : première roche à
1,82-3 m pour des besoins de 0,02-0,15 m), toutes deux consignées dans le pavé
de `_reconstruire_alcove_col()`. Mécanisme retenu : **enfouissement au plus
court derrière la surface visible** (marges 0,06/0,03 m, échantillons de faces
compris). Convergence en 2 tours, 9 sommets, déplacement max 0,2065 m.

**Le sens du correctif est intrinsèquement sûr pour la jouabilité** : le
collider recule HORS du vide, vers la roche. Il rend du dégagement au joueur ;
il n'en prend jamais.

## 3. Reproduction personnelle du lead — toutes les revendications décisives

| revendication | vérification du lead | verdict |
|---|---|---|
| fichier `5ff4ec6e…`, 1 488 700 o | sha256 + taille | ✓ |
| `SM_` bit-identique à `40714c46` | mon instrument : `dd3ea5c6bf9cee3b` == baseline | ✓ |
| `COL_` : zéro pénétration | juge COMMITTÉ du tronc, exécuté par moi, `RC=0` : `PENETRATIONS REELLES : 0`, 0 aire nulle, 0 sous 1e-9, 6 631 paires examinées | ✓ |
| « exactement 9 sommets, tous enveloppe de queue » | multiset des 442 positions soudées 3.5.7↔final : **9 disparues / 9 apparues**, toutes en bande `ay` modèle 5,3–7,0 — aucune à la bouche, aucune dans la poche | ✓ |
| poche d'alcôve intacte (plancher 0,524) | zéro position de cavité modifiée (les 9 sont en queue) ; confirmation finale = jauge de l'agent B | ✓ (contre-pouvoir B en cours) |
| topologie `COL` | V=442 E=1320 F=880, χ=2, 1 composante, 0 bord libre, 0 non-manifold | ✓ |

Les 6 pénétrations propres du `SM_` à 0,000612 m : préexistantes, 33× sous le
seuil, jugées non réelles en 3.5.7 — inchangées puisque `SM_` est bit-identique.

## 4. Garde-fous : tenus, avec une transparence à noter

- **Garde-fou 2 (poche ≥ 0,524)** : tenu par le plus fort des moyens — zéro
  retrait de cavité.
- **Garde-fou 1 (saillie)** : métrique tenue — **71 → 69**, max inchangé
  2,718 m. L'agent signale lui-même l'écart lettre/métrique : les deux
  saillants de la fenêtre ONT été déplacés — **enfouis**, c'est-à-dire dans le
  sens que la règle voulait empêcher d'aggraver et qu'ils améliorent. Accepté :
  l'intention de la règle était « ne jamais avancer » ; enfouir fait décroître
  la saillie. Les 69 restants = dette préexistante hors fenêtre, ticket
  inchangé.

## 5. Découverte transverse

`atlas_correctif_v1.json` (11:33) **prédate la mise à l'échelle `CAVITE_ASYM`**
(12:01) : positions d'alcôve périmées jusqu'à 0,229 m. Relayé à l'agent B —
l'atlas de référence est `atlas_col_it1.json`, vérifié 0/0 contre le GLB livré.

## 6. En cours

- **Agent B** : T1/T2/T3 finaux sur `5ff4ec6e` (canonique aller-retour, capsule
  4 lieux × 2 rayons × 2 maillages, champ paroi invisible, jauge de poche avec
  plancher 0,524) — le contre-pouvoir du plafond.
- **Agent C** : double verdict — conformité du générateur fusionné (procédure
  §2b sur `102cc33d`/`28535fb3`) et identité visuelle avec SON outil
  (`e6a4bdb0` attendu), fermant la boucle à trois instruments.

Limite honnête inchangée : le portail préexistant `controle_epaisseur_domaine`
reste ROUGE (28 plaques, min 0,114 — identique à l'avant-passe, `SM` intouché) ;
son déclassement en télémétrie est décidé (contrat `cca1778`, politique
`28fa140`) et s'appliquera au commit d'intégration (tâche dédiée).
