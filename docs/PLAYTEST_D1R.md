# Playtest D.1R — Vallée de Néris (graybox corrigée) — package reproductible

Deuxième essai humain (MASTER_SPEC §21.9), sur la version corrective issue du
retour n° 1 (`evidence/gateD/playtest01/FORMULAIRE.md`). Ce document est
**auto-suffisant** : installation, lancement, contrôles, limites, formulaire.
Ne pas expliquer le jeu au testeur pendant qu'il joue (§21.9).

> **Consigne d'or** : jouez d'abord (10–15 minutes, librement, sans lire la
> section « Après la partie »). Remplissez le formulaire APRÈS.

---

## 1. Reproductibilité

| Élément | Valeur |
|---|---|
| Dépôt / branche | `istbanbanier/Zelda` · `claude/phase-0-gate-0-setup-t72ibt` |
| Commit du code jouable | **voir le nom du ZIP** `EclatsDOrage_D1R_Playtest_<sha>.zip` — ou `git rev-parse --short HEAD` après checkout |
| Godot | **4.7.1-stable**, édition standard (sans .NET) — binaire officiel depuis godotengine.org. Jamais 4.8 dev/beta/RC |
| Vérification moteur | `godot --version` doit afficher `4.7.1.stable` |
| Intégrité (optionnel, macOS/Linux) | `tools/validate_fast.sh` → doit finir `VALIDATE_FAST : VERT`, 251 tests |

```bash
git clone <dépôt> && cd Zelda
git checkout claude/phase-0-gate-0-setup-t72ibt
git rev-parse --short HEAD    # à consigner dans le formulaire
```

## 2. Lancement (3 étapes)

1. Ouvrir `project.godot` avec Godot 4.7.1 (l'import initial prend ~1 min).
2. **F5** → menu principal.
3. **« Nouvelle partie »** → la vallée se charge, vous êtes sur la crête.
   (« Continuer » reprend maintenant réellement votre partie — voir §4.)

## 3. Contrôles — clavier AZERTY (§8.5)

La souris est **capturée** en jeu ; Échap la libère (pause).

| Action | Touche | État réel |
|---|---|---|
| Avancer / gauche / reculer / droite | **Z / Q / S / D** | ✔ |
| Caméra | souris | ✔ capturée, 360°, sensibilité réglable dans le menu pause (persistée) |
| Saut | **Espace** | ✔ (coyote time, buffer) |
| Sprint | **Maj gauche** (maintenu) | ✔ — draine l'endurance (**visible au HUD**) |
| Interaction | **E** | ✔ — invite « E — Verbe » à l'écran, ligne de vue exigée (un mur bloque l'invite) |
| Attaque légère (combo ×3) | **clic gauche** | ✔ — arme visible en main, pose d'attaque |
| Attaque lourde | **R** | ✔ — coûte 20 d'endurance, refusée à jauge basse |
| Viser / tirer à l'arc | **clic droit** maintenu / **clic gauche** | ✔ — réticule en visée, compteur de flèches au HUD |
| Esquive (i-frames) | **Ctrl gauche** | ✔ — coûte 15 d'endurance |
| Verrouillage de cible | **C** ou clic molette | ✔ — indicateur au HUD ; jamais à travers un mur |
| Changer d'ARME | **molette** (hors verrouillage) | ✔ nouveau |
| Changer de CIBLE | **molette** ou **X / V** (verrouillé) | ✔ — pas de conflit avec le changement d'arme |
| Inventaire | **Tab** | ✔ nouveau — 8 cases, équiper, monter/descendre (réordonner) ; met le jeu en pause |
| Pause | **Échap** | ✔ nouveau — suspend réellement le jeu ; curseur de sensibilité souris |
| Escalade | marcher CONTRE une paroi raide | ✔ auto-accroche ; **Z/Q/S/D** grimper, **Espace** saut de paroi, sommet automatique |
| Plat rapide | F | ✘ liée, aucun effet (cuisine Phase E) |
| Manette | — | ✘ jamais validée (CONTROLLER-001) : clavier/souris exigé |

## 4. Nouveau depuis le retour n° 1

Chaque constat du playtest n° 1 a une réponse jouable :

- **Caméra** : souris capturée, vitesse corrigée (le ÷25 est mort), 360° de
  lacet, sensibilité réglable et persistée.
- **Corps** : on ne traverse plus les pillards, ils ne se superposent plus.
- **HUD** : vie, endurance, flèches, arme équipée + durabilité, verrouillage,
  réticule de visée, notifications de butin.
- **Invites** : « E — Ouvrir / Ramasser / Entrer / Sortir » au centre bas,
  seulement à portée ET en ligne de vue.
- **Inventaire (Tab)** : voir ses 8 cases, équiper, réordonner ; la molette
  change d'arme en jeu.
- **Coffres** : 4 au total — camp, rivière, falaise d'apprentissage, terrasse
  du pylône (butin fixe, notifications).
- **Monde clos** : anneau montagneux infranchissable ; une chute est rattrapée
  TÔT (fondu) et vous ramène au dernier point sûr.
- **Mort** : écran avec « Réessayer » (reprise au monde-checkpoint) et retour
  menu — plus besoin de relancer le projet.
- **Citadelle** : la porte s'ouvre — vestibule graybox explorable (colonnes,
  lumière cyan, porte du donjon **scellée honnêtement** : les quatre salles
  électriques sont la Phase F). « Sortir » vous remet devant la porte.
- **« Continuer »** : restaure armes + durabilités, arme équipée, flèches et
  coffres ouverts. Reprise au spawn de la crête (checkpoints riches : Phase E).
- **Combat lisible** : arme colorée visible en main, pose d'attaque, télégraphe
  ROUGE du pillard avant son coup, flash à l'impact, stagger et mort visibles.

## 5. Limites connues — ce ne sont pas des bugs à rapporter

- **Graybox intégral** : capsules et blocs colorés, zéro modèle définitif,
  zéro animation squelettique, **zéro son** (silence complet, c'est normal).
- Le lit de rivière n'a **pas d'eau** ; pylône et citadelle restent des
  masses aux bonnes places, pas de l'art. Pas de cuisine, pas de boss.
- Reprise après mort et « Continuer » ramènent au spawn de la crête (point de
  reprise documenté) — les checkpoints intermédiaires arrivent en Phase E.
- Performance non mesurée sur GPU réel : notez votre ressenti (fluidité,
  saccades) dans le formulaire.

## 6. La partie

Jouez **10 à 15 minutes, sans but imposé**. Vérifiez librement — sans vous y
limiter — ce qui vous avait bloqué la première fois : caméra, combat au camp,
coffres, inventaire, citadelle, une mort volontaire, puis « Continuer ».

## 7. Après la partie — formulaire

Copier `evidence/gateD/playtest02/FORMULAIRE.md`, le remplir, le déposer dans
`evidence/gateD/playtest02/` avec vos captures (**de VOTRE machine, jamais
retouchées**).

## 8. Après le retour

Triage §21.9 (fréquence × gravité × coût). **C.5 (caméra/lumière/matériaux/
végétation sur la crête réelle) reste suspendu jusqu'à l'analyse de ce
retour** — décision propriétaire.
