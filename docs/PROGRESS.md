# PROGRESS — journal chronologique et handoff

Ordre **anti-chronologique** : l'entrée la plus récente est en haut. La dernière
entrée fait office de handoff et doit indiquer **exactement** la prochaine action.

---

## 2026-08-31 — ISS-088 fermée : la boucle d'ambiance se compte en trames

**Branche `claude/world-v2-iss088-qoa-loop`, poussée et vérifiée au SHA `259dd62b`**
(correctif `72e081a6`, sa preuve juste après). Base `8c6955c6`.

`play_ambience` posait `loop_end = data.size() / 2` sur une ressource QOA, où
`data` n'a aucun rapport avec le compte de trames : 71408 octets pour 176400
trames, donc une borne à 35704 au lieu de 176399. **L'ambiance rebouclait sur ses
0,81 premières secondes d'un clip de 4,00 s.** Corrigé par
`get_length() * mix_rate - 1`, posé sur une copie mémorisée plutôt que sur
l'exemplaire partagé du cache.

Rouge d'abord — 0 réussi, 8 échoué, avec les chiffres du défaut dans les
messages. Vert ensuite — 3 réussi, 0 échoué, 23 assertions. Le bouclage est
**mesuré** : le pilote audio muet mixe réellement, et la lecture plafonnait à
0,7459 s sous ablation. `validate_fast.sh` VERT sur l'arbre committé : 1049
tests, gel 46/46, et **enveloppe de résidu inchangée, 140/76 contre contrat
140/76** — la copie ne fuit pas, ISS-086 n'est pas rouverte.

Décision **D-064**. Ouvre **ISS-089** : quarante erreurs d'arêtes de navigation
s'impriment à chaque course depuis au moins le 26 août, dans 1798 journaux
archivés, et aucun filtre de portail du dépôt ne contient le mot `WARNING`.

**`NON VÉRIFIÉ` — personne n'a écouté.** Aucun périphérique audio ici (ISS-004).
Et ce lot ne rend **aucune ambiance audible au joueur** : `ValleyWorld.tscn`
n'est plus le monde joué, aucune scène atteignable ne démarre d'ambiance
continue. C'est ISS-087, toujours ouverte.

### Une réinitialisation de conteneur a détruit deux tranches

Le même jour, le conteneur a été réinitialisé et **tout le travail local non
poussé a été perdu** : la tranche ISS-075 (localisation de `gameplay_shell.gd`,
78 littéraux migrés, quatorze contrats, scanner réparé) et la recherche ISS-087
(inventaire sonore, trois prototypes, protocole d'écoute). Rien n'avait été
poussé — c'était la règle — donc **rien n'a été perdu au distant**, et les
artefacts protégés sont intacts. Mais les deux tranches sont à refaire.

**Leçon, à appliquer désormais : pousser tôt et souvent.** Une tranche qui tient
se commite et se pousse, sans attendre que le lot entier soit fini.

### Prochaine action, exactement

1. Refaire la tranche **ISS-075** sur `claude/world-v2-iss075-gameplay-shell`
   (arbre déjà remonté sur `8c6955c6`). Précondition bloquante : le scanner
   `tools/inventaire_textes_joueur.py` annonce 39 littéraux là où il y en a 78 —
   sa constante `ACC` exige un accent, et « Cuisiner » ressemble à « Plate ». Il
   doit décider sur le RÔLE syntaxique, pas sur la forme. Un compteur faux ne
   peut pas servir de portail.
2. Refaire la recherche **ISS-087**. Trois faits déjà établis à ne pas
   redécouvrir : `ValleyWorld` n'est plus atteignable par le joueur ; la carte
   des zones sonores existe déjà (`world_v2_markers_builder.gd`, groupe
   `world_v2_regions`, métadonnée `bounds`) ; et le budget se compte en octets,
   pas en voix — 17852 octets par seconde de mono 44,1 kHz, contre 37 voix de
   marge sur 48.
3. **Aucune écoute n'a eu lieu.** Aucun prototype sonore ne peut être déclaré
   meilleur qu'un autre sans Istvan devant un vrai haut-parleur.

---

## 2026-08-30 — ISS-086 fermée : l'ambiance appartient à qui l'a demandée

**Branche** `claude/world-v2-iss086-ambiance`, depuis `1c5374c8`. Cinq commits.
La candidate de lundi et la prérelease `2cb48dd6` n'ont pas été touchées.

### Ce qui était cassé, et comment on l'a prouvé plutôt que supposé

Le lecteur d'ambiance est un enfant de l'autoload `AudioManager` : il survit à
toutes les scènes. `ValleyWorld._ready()` démarrait `amb_valley` et **rien** ne
la reprenait. En fin de processus, le moteur le disait :

```
Leaked instance: AudioStreamPlaybackWAV — Reference count: 1
Leaked instance: AudioStreamWAV — Reference count: 1
Resource still in use: res://assets/audio/sfx/amb_valley.wav
```

**L'attribution est épinglée au SHA de base**, pas déduite d'un arbre
postérieur : rejouée dans un worktree DÉTACHÉ à `2cb48dd6`, aucun fichier
modifié, les trois conditions réunies.

### Le correctif : propriété, pas arrêt global

`play_ambience(sound, owner)` — le propriétaire est **obligatoire** — enregistre
une référence faible. `stop_ambience_owned_by(owner)` n'arrête que si l'appelant
est bien celui qui a demandé. La vallée revendique en entrant, reprend en
sortant.

**Pourquoi pas le `stop_ambience()` global que la fiche proposait.** Sur le
chemin de production il aurait suffi — la source du moteur, présente dans ce
conteneur, le dit. Mais `queue_free()` diffère la sortie d'arbre à la fin de la
frame, et l'ablation B le MESURE : avec un arrêt global, l'ambiance que le
suivant vient de démarrer est coupée.

### Neuf mesures, dans l'ordre où elles ont été produites

| Ce qui a été mesuré | Résultat |
|---|---|
| attribution au SHA de base, worktree intact | les 3 conditions réunies |
| contrat AVANT correctif | **12 assertions rouges** |
| contrat APRÈS correctif, en `--verbose` | 3/3, 26 assertions, 0 fuite |
| ablation A — arrêt retiré | 12 rouges à nouveau |
| ablation B — arrêt GLOBAL | le son d'autrui coupé |
| ablation C — `stream = null` retiré | 0 fuite : `stop()` seul suffit |
| contrôle apparié, reproducteur EXACT de l'étape 1 | **0 fuite** |
| non-régression ciblée | 27/0 |
| composition sur l'arbre committé | 1045/0 · `PROJECT_RESOURCE_LEAK_GATE` **VERT** |

Puis l'entérinement du SEUL terme légitime (139/75 → 140/76, D-063), le gel
régénéré ENSUITE (46 intacts, deux lignes de diff), et **`VALIDATE_FAST : VERT`**
sur `2d318931` — la première validation entièrement verte de cette ligne de
travail. L'agrégat rend exactement 140 contre un contrat de 140.

### Trois fois où je me suis trompé, et ce que ça a coûté

1. **J'ai écrit que la source du moteur était absente de ce conteneur.** Elle est
   à `/opt/src/godot`, au tag 4.7.1-stable. Elle tranchait d'ailleurs la question
   que je croyais indécidable.
2. **J'ai écrit que `stop()` seul n'aurait pas suffi.** L'ablation C mesure le
   contraire. `stream = null` est de l'hygiène, pas la cause.
3. **J'ai livré un journal nommé « contrat vert » qui portait la signature du
   défaut.** La cause n'était pas dans le jeu : le recyclage d'une lecture audio
   est asynchrone, et une course FILTRÉE se termine avant que le fil de mixage
   n'ait eu son tour. Le contrat laisse désormais cette fenêtre.

Les trois ont été trouvées par des revues à contexte frais, pas par moi. Les
deux premières étaient déjà commitées : corrigées dans le code et dans les
fiches avant d'être recopiées.

### Deux défauts trouvés en chemin, consignés et NON corrigés

- **ISS-087** — le monde réellement joué n'a **aucun** fond sonore.
  `play_ambience` n'a qu'un appelant, la vallée V1, qui n'est plus le monde
  qu'on atteint en jouant. Le jeu livré est silencieux de bout en bout.
- **ISS-088** — `loop_end` est calculé en « octets / 2 » alors que la ressource
  importée est en QOA. La boucle existe, mais pas là où le code le croit.

Les fermer serait modifier du contenu, ce que la directive interdisait ici.

### Un piège de portail, payé une fois

J'ai committé un journal de preuve ENTRE le portail d'export qui exporte et
celui qui mesure. Le second a refusé, à juste titre : « la build vient de
`2d318931`, le dépôt est à `28015db2` ». Les deux se rejouent en chaîne, jamais
avec un commit au milieu.

### Travaux parallèles, sur branches indépendantes, non intégrés

Conformément à la directive, rien de ceci n'est entré dans la branche ISS-086,
pour garder une attribution causale propre. Les dossiers sont dans les rapports
de session :

- **portails d'export** — trois de leurs quatre dépendances manquaient encore et
  chacune faisait accuser le JEU au lieu de l'outil ; `xdotool`, ImageMagick et
  le module Python `Xlib` réinstallés, le template d'export reconstruit. Un
  pré-vol qui nomme l'outil manquant reste à écrire ;
- **ISS-075, tranche `gameplay_shell.gd`** — plan complet, et un défaut de mon
  propre outil de comptage : son jeu de caractères accentués ignore le tiret
  cadratin et l'apostrophe droite, donc il annonce 39 littéraux là où il y en a
  ~62 ;
- **variante visuelle du camp** — audit `PARTIAL` : rien de gelé touché, A/B
  neutre, mais aucun document de continuité ne pointe vers cette branche et
  `actif` vaut `true` par défaut.

### La contre-revue à contexte frais a rendu PARTIAL, et a eu raison cinq fois

Elle a rejoué le contrat et le contrôle apparié ELLE-MÊME, et vérifié le point
que je n'avais pas su prouver seul : `tests/integration/test_phase_e_chain.gd`
ne contient aucun `stop_ambience`, aucun accès à `AudioManager`, et démonte la
vallée par `queue_free()` sans nettoyage. Le portail est donc vert parce que la
fuite est fermée, pas parce que la suite efface sa propre trace.

Puis elle a trouvé cinq choses :

1. **« Propriétaire obligatoire » n'était vrai que dans la signature.** Le seul
   appelant de production passe par `Object.call()`, où le typage ne protège
   rien. D-062 déclarait la règle, le code la tolérait. `play_ambience` refuse
   désormais un appel sans propriétaire ; le cas F du contrat rougissait avant.
2. **Le journal de la course qui fait foi n'était pas archivé** : les chiffres
   que je citais venaient du journal de la course diagnostic. Ils étaient justes
   — la n°2 les porte à l'identique — mais je ne les avais pas sourcés. Archivé.
3. **D-063 citait 4 317 s**, la durée de la course n°1. La n°2 dit 4 318 s.
4. **Le README revendiquait un bloc de provenance sur « tous » les journaux.**
   Faux pour ceux du portail de composition, qui n'en émet aucun.
5. **Deux citations périmées `E5`** au lieu de `E4`.

### État final, mesuré sur l'arbre livré `da0b3e83`

`VALIDATE_FAST : VERT` — gel 46/46, 472 scripts, suite **1046/0**, contrôles
négatifs 12/12, résidu agrégé **140 contre un contrat de 140**,
`PROJECT_RESOURCE_LEAK_GATE` vert. Les deux portails d'export verts sur le même
SHA, enchaînés sans aucun commit entre eux. Le commit de preuve qui suit ne
change rien au PCK : `evidence/` est exclu de l'export.

**Prochaine action exacte** : rien n'est en vol. Trois décisions appartiennent au
propriétaire — (1) ISS-087, donner un fond sonore au monde réellement joué, ce
qui refermerait aussi ISS-088 ; (2) la variante visuelle du camp, à voir sur un
écran avant de décider de la fusionner ; (3) la tranche ISS-075 suivante, dont
le plan est prêt et dont le compteur de littéraux doit être corrigé d'abord —
il annonce 39 là où il y en a ~62.
