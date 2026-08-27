# RECTIFICATIF — la checklist de S1 n'était pas « 17/17 »

Date : 2026-08-27. Portée : ce dossier de preuves, et les mentions qui le
citaient dans `docs/STATUS.md` et `docs/PROGRESS.md`.

## Ce qui est faux

`checklist/fumee_checklist.log` se termine par :

    === 17 points observés, 0 FAIL ===

et `contexte.json` porte `"checklist 17 points, 0 FAIL"`. **Les deux sont
exacts.** Ce qui est faux, c'est ce que j'en ai tiré : j'ai relayé « 17/17 »,
ce qui laisse entendre 17 `PASS`. Le lot contenait **16 `PASS` et un
`PARTIAL`** — le point « saut puis retour au sol ».

La ligne de résumé ne comptait que les `FAIL`, et le code de sortie faisait de
même (`return 1 if echecs else 0`) : un `PARTIAL` tombait dans le `else 0`. Le
harnais imprimait de surcroît, **même en `PARTIAL`**, la phrase codée en dur
« la vue s'écarte puis revient : le sol arrête la chute » — une affirmation
qui énonçait précisément ce que la mesure venait de nier.

Le produit n'a jamais menti. L'appareil et mon compte rendu, si.

## Ce qui a été corrigé

- `tools/fumee_build_exportee.py` : tout verdict différent de `PASS` rend un
  code non nul ; `BLOQUÉ` et `NON VÉRIFIÉ` gardent le code **3**, distinct ;
  le résumé nomme chaque classe de verdict et liste les points non-`PASS` ;
  autotest de 9 cas dont *« un seul `PARTIAL` parmi des `PASS` »* → code **1**.
- La phrase affirmative codée en dur est **supprimée**.
- Le verdict de gravité au pixel est **retiré** — pas réparé : le critère
  comparait des captures espacées de 3,35 s, pendant lesquelles le tapis de
  fleurs animé dérive plus que le saut ne déplace la vue. Il mesurait le vent.
- `lieux_poses` est désormais analysé numériquement et comparé au littéral 15.

## Ce que ce dossier NE prouve PAS

Le fichier `fumee_checklist.log` **n'est pas réécrit** : c'est l'archive de ce
que l'outil a réellement imprimé ce jour-là, et la falsifier serait pire que
l'erreur qu'elle documente. Il faut le lire avec ce rectificatif à côté.

La gravité de la build publiée reste **`NON VÉRIFIÉ`**. La mesure de
remplacement (S1.1, sur la position Y réelle du héros) s'est close en
**`BLOQUÉ`** : l'horloge du moteur est décrochée du temps mural d'un facteur
17 à 76 dans ce conteneur. Détail et preuves :
`docs/contrats/s1_1_gravite.md` et `../s1_1_gravite/`.
