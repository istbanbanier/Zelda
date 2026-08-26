# ISS-071 — contre-revue de l'agent C : ce qui a été trouvé, ce qui a été fait

Statut : **appliqué**. Date : 2026-08-26.

L'agent C a reçu le correctif, le portail et les preuves dans un contexte
frais, avec pour seule mission de démontrer que le gate échoue. Il n'a trouvé
**aucun défaut dans le correctif lui-même** — son oracle Python indépendant a
comparé 1 125 couples nom→chemin sans une divergence, 24 index de collision
simulés ont montré une priorité inchangée, 167 entrées passées en force n'ont
produit aucun contre-exemple au garde `vus`, et 750 entrées d'index ont été
confrontées au disque sans une faute.

Il a en revanche trouvé **huit défauts dans l'appareil de mesure et dans la
rédaction des preuves**. Un appareil de mesure trop indulgent est plus
dangereux qu'un bug : il transforme un rouge en vert sans que personne ne le
sache. Les huit sont traités ci-dessous.

## C4 — `NON VÉRIFIÉ` n'affectait ni le verdict ni le code de sortie · *bloquant*

`Rapport.verdict()` ne connaissait que `BLOQUÉ` et `ROUGE`. Un contrôle
déclaré `NON VÉRIFIÉ` retombait donc dans le `return "VERT"` final, et
`code_sortie()` rendait 0. Le portail pouvait annoncer la parité atteinte en
n'ayant pas tout mesuré — l'interdit explicite de PROMPT4_METHOD §12.

Pire : l'autotest **ratifiait** ce comportement. Son scénario « état sain »
passait `source=None`, ce qui laisse I8 en `NON VÉRIFIÉ`, et attendait `VERT`.

Corrigé : `NON VÉRIFIÉ` rend désormais le code 3, l'autotest fournit la vraie
racine des sources, et un onzième scénario épingle le cas — tout est vert sauf
un contrôle non exécuté, le portail ne doit pas rendre `VERT`. L'autotest
vérifie maintenant **aussi le code de sortie**, pas seulement le libellé.

## C5 — la chargeabilité ne vérifiait pas sa propre couverture

La branche `chargeabilite` comparait `load_reussi` à `chemins`, sans jamais
comparer `chemins` à la taille de l'index. Une régression qui n'aurait éprouvé
qu'un seul chemin aurait rendu « 1/1 chargés », donc vert.

Corrigé : la couverture est exigée sur la totalité de l'index publié.
Mutation de contrôle : `chemins=1` sur un index de 215 → **ROUGE**, cause
« COUVERTURE PARTIELLE : 1 éprouvé(s) contre 215 indexé(s) ».

## C7 — le contrôle I4/I5 ne portait que sur l'export

`controle_i4_i5(ex, rapport)` : le manifeste éditeur n'était jamais passé, bien
que la preuve écrite affirmât « des deux côtés ». Corrigé : appelé une fois par
environnement, libellés préfixés par le rôle. Mutation : un chemin rendu non
chargeable **côté éditeur seulement** → **ROUGE** (il passait avant).

## C6 — six contrôles verdissaient sur des ensembles vides

I1, I7 et les deux différences §4 (`DEMANDÉS`, `CHARGÉS`) concluaient
« 0 différence » entre deux ensembles vides. C'est le vert-sur-rien que I2/I3
refusait déjà correctement une ligne plus bas. Corrigé par la même doctrine.
Mutation « index vides des deux côtés » : **8 contrôles passent en
`NON VÉRIFIÉ`**, et le portail rend 1 au lieu de 0.

## C1 — I7 se servait de sa propre valeur comme oracle

`test_iss071_normalisation.gd` lisait `MODULE_DIRS` / `MODEL_DIRS` depuis le
script, s'en servait comme vue d'export, puis n'exigeait que `size() >= 6`. La
constante était comparée à elle-même. Permuter deux répertoires — ce qui change
la **priorité de résolution**, le kit gardant le premier et le registre le
dernier — passait au vert. La troisième mutation de C (M3) l'a démontré.

Corrigé : les douze chemins sont écrits en littéraux dans le test, comparés
position par position, sur le modèle de `PINS_SOURCE` qui épingle déjà I8.

## C2 — la justification écrite du garde `vus` était fausse

Les deux résolveurs affirmaient en commentaire que sans ce garde, une collision
croisée serait publiée deux fois côté éditeur. C'est faux, et le code juste
dessous le montre : la collision n'est publiée que si le chemin déjà indexé
**diffère**. Revisiter le même chemin ne publie rien et réécrit la même valeur.

Le garde est conservé — il borne le balayage aux sources réelles — mais son
commentaire dit désormais ce qu'il fait vraiment, et dit explicitement qu'il
n'est *pas* ce qui rend les deux manifestes comparables.

## C8 — une empreinte que rien ne reproduisait

`docs/DECISIONS.md` citait `275954a71a2eb5c5` à l'appui de « le correctif est un
no-op en éditeur ». Aucun outil du dépôt ne la recalculait. La canonicalisation
indépendante de C donnait `931edf1fc7667fa8`.

L'affirmation était **vraie** ; c'est le nombre qui était mort. Corrigé par
`tools/iss071_empreinte_manifeste.py`, qui déclare en clair les champs retirés
et leur raison. Les quatre manifestes éditeur archivés rendent la même
empreinte `931edf1fc7667fa8`.

## Hors périmètre, consigné plutôt que corrigé

C relève que **33 fichiers `.gltf`/`.glb` d'`assets/` vivent hors des huit
répertoires indexés** — armes 6, `characters/parts` 5, `architecture/*` 10,
grottes 5, divers 7. Ils échappent aux deux résolveurs, donc au portail comme à
l'oracle de C : c'est un angle mort **partagé**, et non une régression
d'ISS-071. Ces modèles sont chargés par chemin explicite ailleurs, ce qui est
le mode de résolution qui fonctionne dans les deux environnements. Aucune
action dans cette passe ; consigné pour qu'une passe ultérieure décide s'ils
doivent entrer dans un index ou rester résolus par chemin.

## Ce que ces corrections ne changent PAS

Rejoué sur les manifestes archivés, avec toutes les règles durcies :

```
VERDICT ISS-071 : VERT  (code 0)
32 contrôle(s) exécutés · 0 ROUGE · 0 BLOQUÉ · 0 NON VÉRIFIÉ
```

Le verdict de parité tient. C'était l'enjeu : un durcissement qui ferait
rougir la mesure réelle signalerait que le vert précédent était faux ; un
durcissement qui la laisse verte, tout en faisant rougir six mutations
délibérées, dit que la mesure était bonne et que l'appareil, lui, était laxiste.
