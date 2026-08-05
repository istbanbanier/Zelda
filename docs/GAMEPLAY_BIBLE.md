# GAMEPLAY_BIBLE — piliers, émotions et contrats de design (Prompt 2)

Créée le 2026-08-05 (P2-1). Ce document fixe les décisions de game design du
Prompt 2 ; le tuning chiffré vit dans `resources/tuning/`, jamais ici ni dans
les scènes. Tout écart observé en playtest se corrige d'abord ici (décision),
puis dans les données.

## 1. Cinq piliers (P2 §2.1) — application à ce projet

1. **Le monde écoute** — les lois matériaux/états/paquets (`ReactionSystem`,
   P2-2) remplacent les logiques par salle du donjon ; héros, ennemis, props et
   circuits passeront par les mêmes règles.
2. **Le mouvement est une expression** — coyote/buffer/mantle déjà en place et
   instrumentés (sonde de latence P2-1) ; Arc Step ajoutera la route verticale
   personnelle.
3. **Le combat est physique et tactique** — distance/masse/recul existent
   (knockback, hit-stop, mercy) ; la défense expressive (garde/déviation/
   posture) arrive en P2-3.
4. **La curiosité remplace la checklist** — 31 lieux audités, guidage S3
   (verrouillé) ; les POI Bracelet-dépendants viennent en P2-4.
5. **La difficulté est honnête** — télégraphes stables, fenêtre mercy prouvée ;
   aucun changement secret de règles après un échec.

## 2. Matrice MDA (P2 §2.2)

| Émotion | Dynamique vécue | Mécaniques responsables (état) |
|---|---|---|
| Émerveillement | voir la citadelle, choisir une route, l'atteindre | vista North Star (H), 3 routes (P2-4), Arc Step (P2-2) |
| Ingéniosité | combiner conductivité/eau/masse | graphe électrique (F, acquis), lois communes (P2-2) |
| Maîtrise | réussir mieux une action comprise | esquive i-frames (C, acquis), déviation parfaite (P2-3) |
| Tension | engager endurance/durabilité/exposition | stamina + durabilité (C/E, acquis), bruit (P2-4) |
| Soulagement/fierté | comprendre l'échec, reprendre vite | checkpoints + retry < 20 s (G, acquis) |
| Appartenance | mêmes règles partout | ReactionSystem (P2-2), migration donjon/boss (P2-5) |
| Curiosité | une réponse ouvre une question | Pulse (P2-2), fresques donjon (F, acquis) |

Règle d'admission : toute nouvelle fonctionnalité doit nommer sa ligne dans
cette matrice, sinon elle n'entre pas.

## 3. Bracelet de Résonance — décisions d'architecture (P2-2)

**État 2026-08-05 : le cœur des cinq opérations est prouvé** (fail-first,
suites `test_resonance_*`) — Pulse (LOS, cooldown, bruit), Arc Link (nœud
CABLE du graphe du Gate F), Polarité (impulsions bornées), Arc Step (sweep
intégral + validation d'arrivée), Ground (startup immobile, drainage entier
ou rien), et le **focus/sélection est jouable** : G tenu = focus (candidats
par axe de visée + LOS, hystérésis au cycle molette), clic = confirmation
DISPATCHÉE par nature de cible (ancrage→Arc Step, port→lien en deux temps,
métal chargé→Polarité, matériau→Ground), épée/lock-on suspendus pendant le
maintien ; T = Ground direct sur l'objet chargé le plus proche. Manquent :
la présentation (VFX/audio), le ResonanceLab et la persistance des liaisons.

### 3.1 Composants (P2 §3.1)

- `MaterialProfile` (Resource immuable) : conductivité, isolation, masse
  logique, inflammabilité, fragilité, tags, réactions autorisées.
- `MaterialStateComponent` (Node) : états d'instance `Wet/Charged/Grounded/
  Overloaded/Burning/Fractured`, signaux typés, application idempotente.
- `ElementPacket` (RefCounted) : composantes `kinetic/electric/heat/wetness/
  noise` + source, instigateur, chaîne causale (anti-boucle).
- `ReactionSystem` : **nœud de scène, PAS un autoload** — chaque monde et
  chaque lab instancie le sien (groupe `reaction_system`, helper statique
  `ReactionSystem.locate(tree)`). Raison : hermétisme des tests (R-017 — l'état
  ne survit jamais à une scène) et liste d'autoloads inchangée (CLAUDE.md).
- `ResonanceController` (sur le joueur) : les cinq opérations.
- `ResonanceTargetComponent` / `ResonancePort` : cibles et points de connexion,
  interfaces communes avec les nœuds électriques existants du donjon (migration
  en P2-5, pas de doublon définitif).
- `ResonanceActionDefinition` (Resource) : portée, coût, timing, filtres,
  annulation — une par opération, sous `resources/tuning/`.

### 3.2 Les cinq opérations — valeurs de départ (à tuner en lab)

| Opération | Valeurs initiales | Interdits durs |
|---|---|---|
| Pulse | rayon 10 m, focus 18 m, cooldown 1,5 s, révélation 2-4 s | jamais à travers un mur ; audible par les ennemis |
| Arc Link | portée 14 m, LOS obligatoire, 1 lien actif | aucune énergie créée — transport seulement |
| Polarité | force bornée, masse plafonnée | jamais de téléport d'un RigidBody3D actif ; forces/impulsions Jolt seulement |
| Arc Step | portée 7-12 m, coût 20 endurance, cooldown 0,35 s | sweep de capsule sur TOUT le trajet + validation d'arrivée ; annulation vers le dernier état sûr |
| Ground | startup 0,35 s, immobilité brève | point de terre réellement connecté ; pas d'immunité permanente |

### 3.3 InputMap (proposition, AZERTY audité — remappable)

Libres après audit : `A`, `T`, `G`, `B`. Pris : ZQSD, E, R, F, C, X, V, Tab,
Espace, Maj, Ctrl, Échap, clics.

CÂBLÉ (2026-08-05) :
- `resonance_pulse` : **A** (physique 81) + d-pad haut ;
- `resonance_ground` : **T** (physique 84) + d-pad gauche ;
- `resonance_focus` : **G** (physique 71, maintien) + L1 ;
- confirmation = clic G **en focus uniquement** (l'épée est suspendue) ;
- cycle = molette en focus (armes et lock-on suspendus pendant le maintien).

`Q` reste gauche — invariant absolu. Manette : à valider machine utilisateur ;
le mode bascule (vs maintien) du focus viendra avec les options §12.3.

### 3.4 Progression d'apprentissage (P2 §3.7) sur NOTRE vallée

1. Pulse : dès la crête de spawn (0, 32, 146).
2. Arc Link : au pylône (115, 18, −25), état `Dormant→Linked`.
3. Polarité : pont magnétique de la route des ruines (POI P2-4).
4. Arc Step : entrée du donjon (0, 34, −210), ancrages visibles.
5. Ground : salle 2 du donjon (circuit vertical), espace sûr dédié.
6. Boss : combinaison — jamais la perfection exigée en difficulté Aventure.

### 3.5 Ce que le Bracelet ne fait JAMAIS

Créer de l'énergie, révéler à travers un mur, résoudre une énigme à la place
du joueur, traverser une collision, casser un objet essentiel, fonctionner
pendant `HURT/DEAD`, coûter zéro.

## 4. Latences — contrat mesuré (P2-1, acquis)

- Deux instruments complémentaires (D-048) : `LatencyInstrument` (B.5,
  campagnes intention injectée → mouvement) et `LatencyProbe` (P2-1, chaîne
  réelle événement → reader → état, au fil de l'eau).
- Réception marquée au front d'événement (`PlayerInputReader._input`),
  consommation au changement d'état réel (`LatencyProbe`).
- **Prouvé** (test `test_p2_latency.gd`) : saut et attaque légère légaux
  consommés à ≤ 1 tick physique après réception, via la vraie chaîne
  `Input.parse_input_event` → `_input` → intent → tick.
- Le critère est en ticks logiques, jamais en ms (R-017 : les ms sous llvmpipe
  ne prouvent rien). Overlay : `LabOverlay` dans TraversalPlayground et
  CombatLab (latences, refus expliqués, endurance, mode, vitesse).
- Une action bufferisée affiche > 1 tick : intentionnel (§10.6), le buffer
  honore l'appui à la première fenêtre légale.

## 5. Fragments de Résonance (P2 §2.4) — cadrage

Trois maximum, facultatifs, boss solvable sans : `Écho` (trace directionnelle
de la dernière source sonore), `Flux` (remboursement d'endurance sur mise à la
terre réussie, cooldown), `Élan` (conservation bornée de l'élan d'Arc Step).
Aucun ne court-circuite un puzzle critique ; tout raccourci ouvert est
intentionnel et testé. Implémentation en P2-4, après les lois.

## 6. Stratégie dominante — seuil de veille (P2 §7.7)

Si une boucle simple produit > 70 % des victoires sans raison contextuelle :
analyse (sécurité ? coût ? lisibilité ?) avant tout nerf. Les données locales
de playtest (télémétrie P2 §14.4, désactivable, sans réseau) arrivent avec
P2-3 ; d'ici là, l'observation manuelle des sessions utilisateur fait foi.

## 7. Défense expressive (P2-3) — contrats

### 7.1 Acquis (tranche 1, 2026-08-05)

Garde = clic D tenu avec une arme de mêlée (l'arc vise — un seul geste,
deux métiers selon l'outil). Cône frontal 135°. Blocage : 20 % de dégâts
résiduels contre endurance — `GuardBreak` à jauge vide. Déviation parfaite
(appui < 0,12 s avant l'impact) : zéro dégât, zéro endurance, Clarity
0,35 s, la poise de l'attaquant encaisse 40 par le composant. Un coup
bloqué ne déclenche ni HURT ni mercy. Mécanisme : `damage_gate` générique
de la hurtbox — réutilisable par la garde du Briseur (§14.3).

### 7.2 À faire — les trois jauges (P2 §7.4, décision d'architecture)

- **poise** (existe) : résistance INSTANTANÉE au stagger d'une action —
  RefCounted du moment, se recharge vite ;
- **posture** (à faire) : jauge TACTIQUE des porteurs de garde (Briseur,
  boss) — nourrie par lourdes et déviations parfaites (`posture_damage`
  à ajouter sur DamageEvent/AttackDefinition), sa rupture ouvre une
  fenêtre POSITIONNELLE courte, jamais une cinématique ;
- **santé** : la survie. Aucune des trois ne se déduit des autres.

Règle de dispatch d'une déviation parfaite : si la cible porte une
`PostureComponent`, c'est la posture qui encaisse (les gardiens plient
avant de rompre) ; sinon la poise (les légers sont étourdis net).

### 7.3 Matrice menace × réponse (P2 §7.4) — état d'implémentation

| Menace | Garde | Déviation | Esquive | Systémique |
|---|---|---|---|---|
| légère | ✅ sûre, coûteuse | ✅ forte (poise 40) | ✅ i-frames | interruption (P2-3.3) |
| lourde | ✅ gros coût (×0,8 dégâts) | tag `deflectable` à poser (P2-3.2) | ✅ | sortir de l'axe |
| brise-garde | tag à poser (P2-3.2) | interdite | ✅ | hauteur/impact |
| imblocable | tag à poser | non | ✅ | Arc Step ✅ |
| projectile | selon arme (P2-3.3) | renvoi (P2-3.3) | ✅ | couverture/Polarité ✅ |
| arc électrique | risque métal (lois ✅) | Ground contextuel ✅ | ✅ | isolant/eau (lois ✅) |

Les tags `blockable/deflectable/dodgeable/interruptible` entrent dans
`AttackDefinition` à la tranche 2 — data, jamais des `if` par ennemi.
