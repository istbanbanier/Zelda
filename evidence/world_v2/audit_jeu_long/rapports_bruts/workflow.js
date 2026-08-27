export const meta = {
  name: 'audit-v2-jeu-long',
  description: 'Audit exhaustif de la V2 face à l ambition 30-50h / 80-120h / 200h+, 18 sujets, chacun réfuté',
  phases: [
    { title: 'Audit', detail: 'un agent par sujet, lecture seule du dépôt' },
    { title: 'Refuter', detail: 'sceptique par sujet : attaquer les notes « fonctionnel »' },
    { title: 'Synthese', detail: 'dépendances, chemin critique, angles morts' },
  ],
}

const SOCLE = `
CONTEXTE. Dépôt /home/user/Zelda — « Éclats d'Orage », action-aventure 3D,
Godot 4.7.1-stable, GDScript typé. Tu auditzs en LECTURE SEULE. Tu ne modifies
AUCUN fichier. Tu ne lances NI Godot NI aucune suite de tests (interdit : le
moteur est verrouillé par un verrou de dépôt et une suite dure ~20 min).

Tu peux et dois : lire les fichiers, grep, compter, lire les tests, lire
docs/STATUS.md, docs/PROGRESS.md, docs/KNOWN_ISSUES.md, docs/ROADMAP.md,
docs/MASTER_SPEC.md, docs/PROMPT2_SPEC.md, docs/VISUAL_ASSET_BIBLE.md.

L'AMBITION OFFICIELLE NOUVELLE, qui est l'étalon de ton audit :
  - campagne principale : 30 à 50 heures
  - complétion : 80 à 120 heures
  - potentiel de jeu durable : 200 heures et plus
  - la V2 actuelle est le PILOTE DE LA PREMIÈRE RÉGION, pas un jeu complet
  - identité centrale : l'orage et la résonance
  - boucle : observer -> préparer -> maîtriser -> restaurer

RÈGLES DE VÉRITÉ DU DÉPÔT, non négociables, elles gouvernent ton vocabulaire :
  - « présent »      = le fichier/le code existe et est raccordé
  - « fonctionnel »  = testé dans une scène exécutable ; exige une PREUVE
                       (un test nommé, une scène, une entrée d'evidence/)
  - « prototypé »    = existe mais sans preuve d'exécution, ou en placeholder
  - « absent »       = rien
  - Toute affirmation sans preuve est NON VÉRIFIÉ, jamais « réussi ».
  - Ne JAMAIS inventer un chemin de fichier, un nom de test, un chiffre.
    Si tu n'as pas vérifié, écris-le.
  - Cite des ANCRES STABLES : chemins de fichiers, noms de symboles exportés,
    noms de tests. JAMAIS un numéro de ligne, JAMAIS un compteur que tu n'as
    pas mesuré toi-même à l'instant.

MÉTHODE ATTENDUE. Commence par cartographier ton domaine (find/grep/ls), lis
ce qui compte, puis JUGE. Un audit qui liste des fichiers sans dire ce qui
manque pour 30-50 h ne vaut rien. Le but n'est pas de flatter le dépôt : il
est de dire, sans ménagement et sans exagération, la distance entre ce qui
existe et l'ambition.
`

const SCHEMA_AUDIT = {
  type: 'object',
  required: ['sujet', 'resume', 'etat', 'dette', 'importance_30_50h', 'tranche', 'preuve_acceptation', 'manques'],
  properties: {
    sujet: { type: 'string' },
    resume: { type: 'string', description: '3 à 6 phrases : où en est réellement ce domaine' },
    etat: {
      type: 'array',
      description: 'Un élément par capacité identifiée du domaine',
      items: {
        type: 'object',
        required: ['capacite', 'classement', 'ancre', 'preuve'],
        properties: {
          capacite: { type: 'string' },
          classement: { enum: ['present', 'fonctionnel', 'prototype', 'absent'] },
          ancre: { type: 'string', description: 'chemin de fichier ou symbole exporté, vérifié' },
          preuve: { type: 'string', description: 'test nommé / scène / evidence ; ou NON VÉRIFIÉ' },
        },
      },
    },
    dette: { type: 'array', items: { type: 'string' } },
    importance_30_50h: { enum: ['bloquant', 'majeur', 'moyen', 'mineur'] },
    justification_importance: { type: 'string' },
    tranche: { type: 'string', description: 'tranche recommandée : R1-a, R1-b, R2, differable...' },
    preuve_acceptation: { type: 'string', description: 'ce qui devra être vrai et mesurable pour accepter ce domaine' },
    manques: { type: 'array', items: { type: 'string' }, description: 'ce qui manque explicitement pour 30-50 h' },
    dependances: { type: 'array', items: { type: 'string' }, description: 'autres sujets dont celui-ci dépend' },
  },
}

const SCHEMA_REFUT = {
  type: 'object',
  required: ['surclassements', 'sousclassements', 'omissions', 'verdict'],
  properties: {
    surclassements: {
      type: 'array',
      description: 'capacités notées fonctionnel/present sans preuve qui tienne',
      items: {
        type: 'object',
        required: ['capacite', 'note_donnee', 'note_juste', 'pourquoi'],
        properties: {
          capacite: { type: 'string' },
          note_donnee: { type: 'string' },
          note_juste: { type: 'string' },
          pourquoi: { type: 'string' },
        },
      },
    },
    sousclassements: { type: 'array', items: { type: 'string' } },
    omissions: { type: 'array', items: { type: 'string' }, description: 'capacités du domaine que l audit a oubliées' },
    verdict: { enum: ['fiable', 'a_corriger', 'non_fiable'] },
  },
}

const SUJETS = [
  { id: 'exploration', titre: 'Exploration et structure du monde',
    piste: 'scripts/world_v2/, scripts/world/, resources/world_v2_layout.json, régions, routes, POI, limites, verticalité, densité, raccourcis, points de vue. Combien de lieux réels ? Quelle surface ? Combien d heures de contenu cela peut-il porter ?' },
  { id: 'deplacement', titre: 'Déplacement et sensation de contrôle',
    piste: 'scripts/player/, scripts/components/, resources/tuning/locomotion_default.tres, escalade, mantle, endurance, caméra, Arc Step, vault, slide, buffers, coyote time. Le mouvement est-il agréable SANS objectif ?' },
  { id: 'combat', titre: 'Combat, ennemis et boss',
    piste: 'scripts/combat/, scripts/enemies/, scripts/boss/, hitbox/hurtbox, AttackDefinition, garde, déviation, esquive, posture, poise, familles d ennemis, phases de boss.' },
  { id: 'progression', titre: 'Progression, équipement et builds',
    piste: 'scripts/inventory/, resources/weapons/, durabilité, armes, fragments, propriétés fortes, absence de grind, courbe sur 30-50 h. Y a-t-il seulement une progression ?' },
  { id: 'resonance', titre: 'Pouvoirs d orage et de résonance (mécanique signature)',
    piste: 'scripts/reaction/, scripts/electricity/, Bracelet de Résonance, Pulse, Arc Link, Polarité, Arc Step, Ground, MaterialProfile, ReactionSystem. C EST L IDENTITÉ CENTRALE : mesure l écart entre PROMPT2_SPEC §3 et le code réel.' },
  { id: 'quetes', titre: 'Quêtes, narration et personnages',
    piste: 'grep quête/quest/dialogue/PNJ/npc dans scripts/ et resources/. Y a-t-il un système de quêtes ? un PNJ ? un dialogue ? Sans cela, 30-50 h est impossible — dis-le.' },
  { id: 'donjons', titre: 'Donjons, sanctuaires et énigmes',
    piste: 'scripts/dungeon/, scripts/electricity/, les quatre salles, graphe électrique, salle centrale, antichambre, reset, anti-softlock, solveur. Combien de contenu d énigme existe RÉELLEMENT ?' },
  { id: 'economie', titre: 'Économie, ressources, cuisine et artisanat',
    piste: 'scripts/cooking/, scripts/inventory/, resources/ingredients, meals, récolte, respawn, artisanat. Boucle économique tenable sur 30-50 h ?' },
  { id: 'recompenses', titre: 'Récompenses et secrets',
    piste: 'coffres, RewardAnchor, loot tables, secrets, découvertes, densité de récompense. grep Recompense/RewardAnchor/coffre/chest.' },
  { id: 'rejouabilite', titre: 'Variété à long terme et rejouabilité',
    piste: 'Qu est-ce qui donne 200 h ? contenu procédural, new game+, défis, variantes, endgame. Probablement quasi absent : mesure-le honnêtement.' },
  { id: 'sauvegarde', titre: 'Sauvegarde et reprise',
    piste: 'scripts/save/, docs/WORLD_V2_SAVE_MIGRATION.md, schéma versionné, migrations, IDs persistants, écriture atomique, tests d intégration de save.' },
  { id: 'difficulte', titre: 'Difficulté et équilibrage',
    piste: 'profils Histoire/Aventure/Maîtrise, dégâts, fenêtres, solvabilité du boss, tuning data-driven dans resources/tuning/.' },
  { id: 'ia', titre: 'Intelligence artificielle',
    piste: 'scripts/ai/, scripts/enemies/, perception, LOS, machine à états, utility, tokens de coordination, navigation, budget CPU. Un seul fichier dans scripts/ai/ : que vaut-il ?' },
  { id: 'ui', titre: 'Interface, accessibilité et manette',
    piste: 'scripts/ui/, InputMap dans project.godot, AZERTY Q=gauche, remapping, glyphes, daltonisme, sous-titres, taille UI, options.' },
  { id: 'perf', titre: 'Performances et export multiplateforme',
    piste: 'docs/PERFORMANCE.md, docs/BUILD_ENVIRONMENT.md, presets export, MultiMesh, LOD, HLOD, culling, budgets. Ce qui est MESURÉ vs annoncé. Attention : ce conteneur est headless sans GPU, donc presque rien n est mesurable ici.' },
  { id: 'pipeline', titre: 'Pipeline de contenu',
    piste: 'tools/blender/, source_assets/, docs/assets/ASSET_MANIFEST.csv, chaîne .blend -> .glb -> Godot, gel des assets, coût de production d un lieu. CLÉ POUR 30-50 h : combien de temps coûte un lieu aujourd hui ?' },
  { id: 'qualite', titre: 'Télémétrie, tests et contrôle qualité',
    piste: 'tests/, tools/validate_fast.sh, tools/validate_release.sh, .claude/hooks/, scripts/tools/dev_mode.gd, evidence/. Quelle est la vraie couverture ? Quels portails existent ?' },
  { id: 'monde_regions', titre: 'Passage d une région à un monde multi-régions',
    piste: 'Le monde V2 est UNE région. Que faudrait-il pour en avoir 4 à 6 ? streaming, chargement, transitions, budget mémoire, réutilisation du pipeline, coût. Lis scripts/world_v2/ et docs/WORLD_V2_MASTERPLAN.md.' },
]

phase('Audit')

const resultats = await pipeline(
  SUJETS,
  (s) => agent(
    `${SOCLE}

TON SUJET : ${s.titre}

PISTES DE DÉPART (non limitatives — explore au-delà si le domaine l exige) :
${s.piste}

TRAVAIL :
1. Cartographie ton domaine dans le dépôt. Compte ce qui est comptable.
2. Lis les fichiers qui décident, pas tous les fichiers.
3. Pour CHAQUE capacité du domaine, classe : present / fonctionnel / prototype
   / absent, avec une ANCRE vérifiée et une PREUVE (ou « NON VÉRIFIÉ »).
4. Liste la dette technique réelle.
5. Juge l importance pour une campagne de 30-50 h et JUSTIFIE.
6. Recommande une tranche.
7. Écris la preuve d acceptation future : ce qui devra être mesurable.
8. Liste les MANQUES explicites pour 30-50 h. C est la partie la plus utile :
   sois précis et chiffré quand tu peux.

Sois impitoyable et exact. Un domaine quasi vide doit être dit quasi vide.`,
    { label: `audit:${s.id}`, phase: 'Audit', schema: SCHEMA_AUDIT }
  ),
  (audit, s) => {
    if (!audit) return null
    return agent(
      `${SOCLE}

RÔLE : SCEPTIQUE. Un auditeur a rendu le rapport ci-dessous sur « ${s.titre} ».
Ta mission n est PAS de le confirmer : c est de le RÉFUTER là où il exagère.

RAPPORT À ATTAQUER :
${JSON.stringify(audit, null, 2)}

VÉRIFIE, fichier par fichier, en lecture seule :
1. Chaque ancre existe-t-elle vraiment ? (le chemin, le symbole)
2. Chaque capacité notée « fonctionnel » a-t-elle une PREUVE qui tienne —
   un test qui ÉCHOUERAIT en cas de régression, une scène exécutable, une
   entrée d evidence/ ? Un fichier présent n est PAS une preuve d exécution.
   Un test dont le nom évoque le sujet n est pas une preuve s il ne teste
   qu une construction d objet.
3. Chaque capacité notée « present » l est-elle réellement RACCORDÉE, ou
   s agit-il d un script orphelin que rien n instancie ?
4. L auditeur a-t-il OUBLIÉ des capacités du domaine ? Cherche-les.
5. A-t-il au contraire SOUS-classé quelque chose qui marche vraiment ?

Défaut par défaut : si tu ne trouves pas la preuve, le classement est un
SURCLASSEMENT. Rends la note juste.`,
      { label: `refuter:${s.id}`, phase: 'Refuter', schema: SCHEMA_REFUT }
    ).then((r) => ({ sujet: s, audit, refutation: r }))
  }
)

const propres = resultats.filter(Boolean)
log(`${propres.length}/${SUJETS.length} sujets audités et réfutés`)

phase('Synthese')

const synthese = await agent(
  `${SOCLE}

Tu reçois 18 audits, chacun déjà passé par un sceptique. Ta mission : la
SYNTHÈSE TRANSVERSALE que personne n a pu faire depuis son sujet.

DONNÉES :
${JSON.stringify(propres, null, 2)}

PRODUIS, en français, en Markdown, sans préambule ni conclusion bavarde :

1. VERDICT GLOBAL — en 5 phrases : où en est réellement ce projet face à
   30-50 h de campagne. Pas de flatterie, pas de catastrophisme.

2. LE GOUFFRE — les 5 à 8 manques qui, à eux seuls, rendent 30-50 h
   impossible aujourd hui. Classés par gravité. Chacun chiffré si possible.

3. CE QUI EST SOLIDE — ce sur quoi on peut réellement bâtir, avec preuve.
   Sois honnête : s il n y a que 3 choses, dis 3 choses.

4. GRAPHE DES DÉPENDANCES — au format mermaid (graph TD), reliant les 18
   sujets par leurs vraies dépendances techniques. Noeuds courts.

5. CHEMIN CRITIQUE — la chaîne de tranches qui gouverne la date. Explique
   pourquoi c est ce chemin et pas un autre.

6. COÛT DE PRODUCTION D UNE RÉGION — à partir de l audit du pipeline et de
   celui du monde, estime honnêtement ce que coûte une région, et ce que
   coûteraient 4 à 6 régions. Marque clairement ce qui est une ESTIMATION.

7. TROIS SCÉNARIOS DE PORTÉE — ambitieux / réaliste / réduit, avec ce que
   chacun sacrifie. Recommande-en un, et dis pourquoi.

8. ANGLES MORTS — ce que ni les 18 audits ni toi n avez pu vérifier depuis
   ce conteneur headless sans GPU, et qui exige une vraie machine.`,
  { label: 'synthese-transversale', phase: 'Synthese' }
)

return { audits: propres, synthese }
