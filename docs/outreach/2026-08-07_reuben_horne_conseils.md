# Lettre à Reuben Horne — demande de conseils

**Destinataire** : reuben.horne93@gmail.com
**Qui** : Reuben Horne, il dirige *World of ClaudeCraft*
(<https://github.com/levy-street/world-of-claudecraft>), chez Levy Street
(Wellington). MMO navigateur construit en un week-end avec Claude, puis
grossi à ~9 900 commits, 2,1k étoiles, 653 forks.
**Rédigée le** : 2026-08-07 · **État** : prête à envoyer, non envoyée
(cette session n'a aucun outil d'envoi d'e-mail).

## Pourquoi ces questions-là

Leur simulation est déterministe et n'importe ni DOM ni Three.js : elle est
donc **testable par construction**, et ils ont même un environnement
d'apprentissage par renforcement qui tourne dedans. Nos défauts à nous sont
exactement ceux qu'un conteneur sans écran ne peut pas voir (ISS-002) — d'où
les quatre questions.

Chiffres cités, vérifiés le 2026-08-07 : 165 commits, 312 fichiers `.gd`,
73 730 lignes, 748 tests, premier commit le 2026-08-04.

---

## Texte de l'e-mail (anglais)

**Objet** : `A question about World of ClaudeCraft, from someone building a Godot game the same way`

Hi Reuben,

I've been reading World of ClaudeCraft's `CLAUDE.md` instead of playing the
game — the architecture tests that scan for forbidden imports and clock calls,
`gate_select.mjs`, "fix bugs test-first, in isolation." It's the most serious
answer I've found to the problem I'm stuck on.

Context, so you know who's asking: I'm a complete beginner. Not a developer —
I can't read a diff or judge a shader. Three days ago I pointed Claude Code at
a spec for a 3D action-adventure in Godot 4.7. It's now 312 GDScript files,
~74k lines, 748 passing tests, and a playable loop from valley to dungeon to
boss. I genuinely don't know whether that's impressive or whether I've built a
beautiful pile of scaffolding.

Where we differ is the part I can't solve. Your sim is deterministic and has
zero DOM imports, so it's testable by construction — same seed, same world,
and you can train an agent inside it. My failure modes are the ones a headless
container can't see: the camera feels wrong, the grass is the wrong scale, a
wall doesn't close, the art doesn't cohere. My container has no GPU and no
screen. So the agent works blind, and I'm the only pair of eyes — and I don't
know what I'm looking at.

Four questions. A two-line answer to any one of them would be more than I'm
owed:

1. **Did the headless RL environment ever pay for itself as a bug-finder?**
   Not as research — did agents playing the game surface softlocks,
   unreachable states or degenerate strategies you hadn't found by hand?
   That's the idea I'd steal first.

2. **Visual changes require before/after screenshots in your PRs. Who
   actually judges them?** When the model both makes the change and grades
   the screenshot, how do you stop it marking its own homework?

3. **~9,900 commits and 291 open PRs — how many agents run at once, and what
   keeps them from diverging?** I lost a full day to two parallel sessions
   that split my game in half without anyone noticing. Is "mergeable PR,
   green gate" enough, or do you serialize?

4. **What would you set up on day one, knowing it goes to ten thousand
   commits?** I still have a window where retrofitting is cheap, and I
   probably can't tell which foundation matters.

No obligation at all — I know unsolicited mail is a tax. If it's any trade,
I'm an odd data point: a non-programmer, and a project that has grown a fairly
paranoid evidence regime (a banned-vocabulary list, an adversarial-QA
reviewer, a rule that untested means unverified) because the failure I kept
hitting was the agent telling me things were done when they weren't. Happy to
send what that looks like if it's ever useful.

Congratulations on the launch. Building it in a weekend is the least
interesting thing about it.

Best,
Istvan Banier
istvan.banier@gmail.com

---

## Traduction française (pour relecture)

Bonjour Reuben,

J'ai passé plus de temps à lire le `CLAUDE.md` de World of ClaudeCraft qu'à
jouer au jeu — les tests d'architecture qui traquent les imports interdits et
les appels à l'horloge, `gate_select.mjs`, « corriger les bugs par le test
d'abord, en isolation ». C'est la réponse la plus sérieuse que j'aie trouvée au
problème sur lequel je bute.

Le contexte, pour savoir qui vous écrit : je suis débutant complet. Pas
développeur — je ne sais ni lire un diff ni juger un shader. Il y a trois
jours, j'ai lancé Claude Code sur un cahier des charges d'action-aventure 3D
sous Godot 4.7. Ça fait aujourd'hui 312 fichiers GDScript, ~74 000 lignes,
748 tests au vert, et une boucle jouable de la vallée au donjon jusqu'au boss.
Je suis sincèrement incapable de dire si c'est impressionnant ou si j'ai bâti
un magnifique tas d'échafaudages.

Là où nous différons, c'est précisément ce que je n'arrive pas à résoudre.
Votre simulation est déterministe et n'importe rien du DOM : elle est testable
par construction — même graine, même monde, et vous pouvez entraîner un agent
dedans. Mes défauts à moi sont ceux qu'un conteneur sans écran ne voit pas : la
caméra est désagréable, l'herbe est à la mauvaise échelle, un mur ne ferme pas,
l'ensemble visuel ne tient pas debout. Mon conteneur n'a ni GPU ni écran.
L'agent travaille donc en aveugle, je suis la seule paire d'yeux — et je ne
sais pas ce que je regarde.

Quatre questions. Deux lignes sur n'importe laquelle serait déjà plus que ce
que je mérite :

1. **L'environnement d'apprentissage par renforcement s'est-il rentabilisé
   comme détecteur de bugs ?** Pas comme recherche — est-ce que des agents en
   train de jouer ont fait remonter des blocages, des états inatteignables ou
   des stratégies dégénérées que vous n'aviez pas trouvés à la main ? C'est
   l'idée que je volerais en premier.

2. **Vos PR exigent des captures avant/après pour tout changement visuel. Qui
   les juge réellement ?** Quand le modèle fait le changement *et* note la
   capture, qu'est-ce qui l'empêche de corriger sa propre copie ?

3. **~9 900 commits et 291 PR ouvertes — combien d'agents tournent en même
   temps, et qu'est-ce qui les empêche de diverger ?** J'ai perdu une journée
   entière à cause de deux sessions parallèles qui ont coupé mon jeu en deux
   sans que personne le remarque. « PR fusionnable, portail au vert », ça
   suffit, ou vous sérialisez ?

4. **Que mettriez-vous en place dès le premier jour, sachant que ça ira à dix
   mille commits ?** J'ai encore une fenêtre où revenir en arrière coûte peu,
   et je ne sais probablement pas repérer quelle fondation compte.

Aucune obligation — je sais qu'un e-mail non sollicité est un impôt. Si ça peut
faire échange, je suis un cas curieux : non-programmeur, avec un projet qui
s'est doté d'un régime de preuve assez paranoïaque (vocabulaire interdit,
relecteur contradictoire, règle du « non testé = non vérifié ») parce que la
panne que je rencontrais sans cesse, c'était l'agent m'annonçant que les choses
étaient faites alors qu'elles ne l'étaient pas. Je vous envoie volontiers à
quoi ça ressemble si ça peut servir.

Félicitations pour la sortie. L'avoir construit en un week-end est le détail le
moins intéressant de l'histoire.

Bien à vous,
Istvan Banier
