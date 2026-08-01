# Playtest D.1 — Vallée de Néris (graybox) — package reproductible

Premier essai humain du monde (MASTER_SPEC §21.9). Ce document est
**auto-suffisant** : installation, lancement, contrôles, limites, et le
formulaire de retour. Le testeur n'a besoin de rien d'autre — et surtout pas
qu'on lui explique le jeu pendant qu'il joue (§21.9 : « ne pas expliquer
pendant le test »).

> **Consigne d'or** : jouez d'abord (10–15 minutes, librement, sans lire la
> section « Après la partie »). Remplissez le formulaire APRÈS.

---

## 1. Reproductibilité

| Élément | Valeur |
|---|---|
| Dépôt / branche | `istbanbanier/Zelda` · `claude/phase-0-gate-0-setup-t72ibt` |
| Commit du code jouable | **`316e4dd`** (les commits suivants n'ajoutent que preuves et documents — vérifiez avec `git log --oneline` que rien sous `scripts/`, `scenes/`, `resources/` n'a bougé depuis) |
| Godot | **4.7.1-stable**, édition standard (sans .NET) — binaire officiel depuis godotengine.org. Jamais 4.8 dev/beta/RC |
| Vérification moteur | `godot --version` doit afficher `4.7.1.stable` |
| Intégrité (optionnel, macOS/Linux) | `tools/validate_fast.sh` → doit finir `VALIDATE_FAST : VERT`, 225 tests |

```bash
git clone <dépôt> && cd Zelda
git checkout claude/phase-0-gate-0-setup-t72ibt
git rev-parse --short HEAD    # à consigner dans le formulaire
```

## 2. Lancement

1. Ouvrir `project.godot` avec Godot 4.7.1 (l'import initial prend ~1 min).
2. **F5** (lancer le projet) → menu principal.
3. **« Nouvelle partie »** → la vallée se charge, vous êtes sur la crête.

En ligne de commande : `godot --path .` puis F5, ou directement
`godot --path . res://scenes/boot/Boot.tscn`.

## 3. Contrôles — clavier AZERTY (§8.5)

| Action | Touche | État réel |
|---|---|---|
| Avancer / gauche / reculer / droite | **Z / Q / S / D** | ✔ |
| Caméra | souris | ✔ |
| Saut | **Espace** | ✔ (coyote time, buffer) |
| Sprint | **Maj gauche** (maintenu) | ✔ — draine l'endurance (invisible, voir limites) |
| Interaction (coffre, arme au sol) | **E** | ✔ — portée ~2 m, face à l'objet, **aucune invite à l'écran** |
| Attaque légère (combo ×3) | **clic gauche** | ✔ |
| Attaque lourde | **R** | ✔ — coûte 20 d'endurance, refusée à jauge basse |
| Viser / tirer à l'arc | **clic droit** maintenu / **clic gauche** | ✔ — 8 flèches au départ, compteur invisible |
| Esquive (i-frames) | **Ctrl gauche** | ✔ — coûte 15 d'endurance |
| Verrouillage de cible | **C** ou clic molette | ✔ — bascule ; jamais à travers un mur |
| Cible précédente / suivante | **X / V** ou molette | ✔ (verrouillé seulement) |
| Escalade | marcher CONTRE une paroi raide | ✔ auto-accroche ; **Z/Q/S/D** pour grimper, **Espace** saut de paroi, sommet franchi automatiquement en poussant vers le haut |
| Inventaire | Tab | ✘ liée, **aucun effet** (UI §17.3 à venir) |
| Plat rapide | F | ✘ liée, aucun effet (cuisine Phase E) |
| Pause | Échap | ✘ **aucun effet** — pas de pause en D.1 |
| Manette | — | ✘ liée mais **jamais validée** (CONTROLLER-001) : clavier/souris exigé pour ce playtest |

## 4. Ce qu'il y a dans ce build — et ce qu'il n'y a PAS

**Il y a** : une vallée graybox de 512 × 512 m avec du relief, un camp occupé
par trois pillards (IA de poursuite sur navmesh, télégraphes, repli sur
esquive réussie), un coffre, une arme à ramasser, six armes définies
(dégâts/portée/durabilité réels — les armes CASSENT), l'arc, l'endurance,
l'escalade, la vue d'ouverture composée depuis la crête.

**Limites connues — ce ne sont pas des bugs à rapporter** :

- **Graybox intégral** : capsules et blocs colorés, zéro modèle, zéro
  animation, **zéro son** (silence complet, c'est normal).
- **Aucun HUD** : santé, endurance, flèches, durabilité — tout est invisible.
  Le sprint qui « cale », l'esquive ou la lourde refusées, la paroi lâchée en
  pleine montée : c'est l'endurance vide, pas une panne.
- **La mort est définitive** : écran de mort et retry arrivent en Phase E —
  si vous mourez, relancez (F5) et reprenez « Nouvelle partie ».
- **« Continuer » repart du spawn** : l'application de la sauvegarde arrive en
  Phase E.
- **Changement d'arme automatique uniquement** (à la rupture) — aucune touche
  de sélection d'arme.
- **Pas de bords de monde** : au-delà des dalles, on tombe — un filet vous
  repêche au spawn après ~1 s.
- Le lit de rivière n'a **pas d'eau** ; pylône et citadelle sont des **proxys**
  (masses à la bonne place, pas de l'art).
- Performance non mesurée sur GPU réel : notez votre ressenti (fluidité,
  saccades) dans le formulaire, il n'y a aucun budget annoncé.

## 5. La partie

Jouez **10 à 15 minutes, sans but imposé**. C'est tout le test : ce que vous
comprenez, tentez, trouvez — ou pas — est exactement la donnée recherchée
(§21.9 : « comprennent-ils déplacement, objectif et chemin ? »).

## 6. Après la partie — formulaire

Copier `evidence/gateD/playtest01/FORMULAIRE.md`, le remplir, et le déposer
dans `evidence/gateD/playtest01/` avec vos captures d'écran éventuelles
(**captures de VOTRE machine — jamais retouchées**). Le formulaire demande :
contexte machine, chronologie libre, les cinq questions de §21.9, les
questions propres à D.1 (lecture de la vallée, camp, combat, falaise), et un
tableau de bugs avec sévérité.

## 7. Après le retour

Triage §21.9 : fréquence × gravité × coût, blocages et incompréhensions
d'abord. **C.5 (caméra/lumière/matériaux/végétation sur la crête) ne démarre
qu'après l'analyse de ce premier retour** — décision propriétaire.
