# Protocole d'écoute — quatre essais à l'aveugle

**Document VIVANT.** Réserve **D-066** (ISS-087).

Ce protocole existe parce que **le conteneur de développement n'a aucun
périphérique audio** (ISS-004). Tout ce qui a été mesuré côté machine est de
l'énergie dans des bandes de fréquence — jamais du son entendu. **Les réponses
d'Istvan sont les seuls verdicts sonores de ce projet.** Rien d'autre ne peut
en tenir lieu.

---

## PARTIE 1 — POUR ISTVAN

Il y a quatre essais du jeu, appelés **A**, **B**, **C** et **D**. Ils sont
identiques sauf sur un point : ce qu'on entend en se promenant.

**Personne ne te dira lequel est lequel avant la fin.** C'est voulu : si tu
savais, tu entendrais ce qu'on t'a annoncé au lieu de ce qu'il y a.

Il n'y a pas de bonne réponse. Si un essai te paraît mauvais, dis-le. Si deux
te paraissent pareils, dis-le aussi — **c'est même le résultat le plus utile.**

### Avant de commencer

1. Mets le son de ton ordinateur à un niveau confortable.
2. **Ne le change plus jusqu'à la fin des quatre essais.** Si tu le montes entre
   deux essais, la comparaison ne veut plus rien dire.
3. Si tu as un casque, garde le même du début à la fin.

### Pour chaque essai, dans l'ordre qu'on te donne

Joue **trois minutes environ**, en faisant ceci — l'ordre n'a pas d'importance :

- marche un moment sur l'herbe ;
- cours ;
- saute et retombe deux ou trois fois ;
- donne quelques coups ;
- si tu croises un coffre, ouvre-le ;
- **mets le jeu en pause, attends deux secondes, reprends.**

Si à un moment quelque chose te surprend ou te déplaît, appuie sur **F4**. Pas
besoin d'expliquer sur le moment.

Puis arrête, et réponds aux six questions ci-dessous **tout de suite**, avant
de lancer l'essai suivant.

### Les six questions

Réponds en tes mots. Les notes vont de 1 à 5 ; 1 = pas du tout, 5 = beaucoup.

| | Question | Réponse |
|---|---|---|
| 1 | Pendant que tu te promenais, le jeu t'a paru **vivant** ou **éteint** ? (1 = éteint, 5 = vivant) | |
| 2 | As-tu entendu **quelque chose se répéter** ? Si oui, au bout de combien de temps, à peu près ? | |
| 3 | Tes **pas** s'entendaient-ils bien ? (1 = je ne les entendais plus, 5 = très nets) | |
| 4 | Tes **coups** et le **coffre** s'entendaient-ils bien ? (1 = étouffés, 5 = très nets) | |
| 5 | Y a-t-il eu un moment où le son a **coupé** ou **changé d'un coup** ? Quand ? | |
| 6 | Quelque chose t'a-t-il **gêné** ou **fatigué** au bout de trois minutes ? | |

### À la toute fin, une fois les quatre essais faits

| | Question | Réponse |
|---|---|---|
| 7 | Lequel garderais-tu ? Pourquoi, en tes mots ? | |
| 8 | Lequel jetterais-tu ? | |
| 9 | Y en a-t-il un où tu n'as **rien entendu du tout** en te promenant ? Lequel ? | |

La question 9 est importante. **Ne cherche pas à deviner** : si tu n'es pas sûr,
écris « je ne sais pas ». C'est une réponse qui compte autant que les autres.

### Ce qu'on ne te demande pas

Ni de juger si c'est « bien mixé », ni de comparer à un autre jeu, ni de dire
quel réglage technique il faudrait changer. Seulement ce que tu as entendu et
ce que ça t'a fait.

---

## PARTIE 2 — POUR CELUI QUI FAIT PASSER L'ESSAI

### Ce qu'il faut préparer

Quatre archives, nommées **seulement** `A`, `B`, `C`, `D`. Rien d'autre ne doit
les distinguer : ni le nom du fichier, ni la taille annoncée, ni un mot dans le
message d'envoi.

| Étiquette | Contenu réel |
|---|---|
| l'une des quatre | **P1** — lit unique de 30 s |
| l'une des quatre | **P2** — deux lits de 15 s, bascule par région |
| l'une des quatre | **P3** — lit de 20 s + 4 événements espacés |
| l'une des quatre | **TÉMOIN — aucune ambiance**, c'est-à-dire le jeu d'aujourd'hui |

**Le témoin muet n'est pas optionnel.** Sans lui, « ça paraît plus vivant » n'a
aucun point de comparaison, et le défaut qu'on cherche à corriger est
précisément l'absence totale d'ambiance. Si Istvan ne distingue pas le témoin
des trois autres, **aucun des trois prototypes ne mérite d'être intégré** — et
c'est un résultat, pas un échec.

**Mélanger l'ordre au tirage au sort, noter la correspondance, et ne la révéler
qu'après la question 9.**

### Les règles à tenir

- **Ne rien expliquer avant.** Pas de « celui-là a des zones », pas de « tu
  devrais entendre… ». Une attente annoncée devient une réponse.
- **Ne pas commenter pendant.** Même un « ah oui ? » oriente.
- Ne pas relancer sur une réponse vague : « je ne sais pas » est une donnée.
- Si Istvan est bloqué dans le jeu, l'aider sur le **déplacement** uniquement,
  et le noter — un essai où il a passé deux minutes coincé n'est pas comparable.
- Aucune étape ne doit demander un terminal, un drapeau ou un chemin.
  Si le protocole en exige un, il est mal écrit : le corriger.

### Ce que ces réponses décident

| Question | Ce qu'elle mesure vraiment |
|---|---|
| 1 | si le défaut d'ISS-087 est réellement perçu, et par quel prototype il est comblé |
| 2 | **si la durée de boucle choisie se trahit.** 30 s, 15 s et 20 s sont des hypothèses de budget, jamais entendues |
| 3 | le masquage des pas sur l'herbe — 18,9 à 26,1 % de leur énergie est au-dessus de 11 025 Hz |
| 4 | le masquage en 125-500 Hz, où onze des vingt sons courts vivent |
| 5 | le fondu d'un tampon à chaque pause et à chaque transition, et — pour P2 — le battement aux frontières de région |
| 6 | la fatigue, que rien d'automatique ne mesure |
| 9 | **la validité de tout l'essai.** Si le témoin muet n'est pas repéré, le reste ne veut rien dire |

### Ce qu'il ne faut pas conclure

- Ne pas transformer une préférence en verdict de conception. Si P2 gagne, cela
  dit que les zones s'entendent — pas que le découpage en régions est bon.
- Ne pas conclure sur la question du **22 050 Hz**. Les quatre essais sont tous à
  22 050 Hz : l'essai ne compare pas les fréquences d'échantillonnage. La perte
  mesurée de 2,04 % d'énergie au-dessus de 11 025 Hz reste **`NON VÉRIFIÉ`** à
  l'oreille, et le resterait même si Istvan aimait les quatre essais.
- Ne pas moyenner les quatre notes en un score. **Le verdict est le plus faible
  des critères, pas leur moyenne.**

### Où atterrissent les réponses

Les six réponses par essai, plus les trois finales, vont dans
`docs/PLAYTESTS.md`, avec la date, la correspondance étiquette → prototype
révélée après coup, et les dossiers de session produits par F3/F4
(`docs/MODE_DEV.md`). Tant que ce document n'est pas rempli, **le choix d'un
prototype reste `NON VÉRIFIÉ`**, quel que soit ce que disent les mesures de
bandes.
