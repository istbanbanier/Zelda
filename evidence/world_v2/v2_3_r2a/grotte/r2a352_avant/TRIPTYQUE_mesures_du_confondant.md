# Triptyque de diagnostic — décomposer le confondant d'éclairage (7.3)

## Le problème, en une phrase

Entre le côté AVANT et le côté APRÈS, **la géométrie n'est pas la seule chose
qui change** : les deux sources lumineuses de la grotte se déplacent. Publier
l'A/B tel quel remettrait au lead une image qui ne peut pas répondre à la
question qu'elle prétend poser.

## Ce qui change exactement — relu, pas déduit

`git diff 179806b e0e7567 -- scripts/world_v2/poi/waterfall_cave_place.gd`

**Deux lignes de lampe, et deux seulement** :

```gdscript
# OmniLight3D "JourDuSeuil"  — portée 5,5 m, ombres actives
- seuil.position = Vector3(0.20, 1.50, -2.60)
+ seuil.position = Vector3(0.15, 1.50, -1.20)

# OmniLight3D "CielReplie"   — portée 6,5 m, ombres actives
- salle.position = Vector3(0.20, 1.90, -7.20)
+ salle.position = Vector3(2.70, 1.90, -3.35)
```

> **Correction au message du lead : il y a DEUX lignes de lampe, pas quatre.**
> Les deux autres lignes déplacées du même diff — `voisin` et `MODELE_NICHE` —
> ne sont **pas** des sources : ce sont les positions de deux champignons posés
> par `_habiller()`, dont celui de la récompense. Les appliquer ferait bouger la
> récompense dans le plan B et **détruirait l'isolation** que le triptyque
> cherche. On applique strictement les deux lignes ci-dessus.

## Pourquoi ça mord précisément sur Q2

Dans ce repère la galerie va vers −Z. `JourDuSeuil` passe de `z = −2,60` à
`z = −1,20` : elle se rapproche de la bouche de **1,40 m**. Avec 5,5 m de portée
et `shadow_enabled = true`, son halo atteignait `z = +2,9` et atteint désormais
`z = +4,3` — soit **4,3 m à l'extérieur de la bouche**. Elle éclaire donc la
sous-face de la visière depuis l'intérieur, et pas de la même façon des deux
côtés. C'est exactement la zone de la vue 10.

`CielReplie` fait un bond de 3,85 m vers la bouche et de 2,50 m latéralement.

## Le triptyque

| plan | géométrie | lampes | arbre | statut |
|---|---|---|---|---|
| **A** | R2a-3.4 `8bf1a1b3` | anciennes | tronc `179806b`, committé propre | **PREUVE** |
| **B** | R2a-3.4 `8bf1a1b3` | **nouvelles** | `visuel_diag`, arbre sale | **DIAGNOSTIC** |
| **C** | candidat `cc3596c5` | nouvelles | tronc après intégration, committé propre | **PREUVE** |

- **A → B isole l'éclairage** : même maillage aux octets près, seules les lampes bougent.
- **B → C isole la géométrie** : mêmes lampes, seul le maillage change.

Vues au minimum : **10** (visière par-dessous, celle qui porte Q2).
Si le budget de verrou le permet : **3-4** (seuil) et **11** (intérieur).

## Base épinglée : `179806b` — pour A ET pour B

Le lead avait écrit « détaché sur `d25fadc` ». Le tronc a depuis avancé deux
fois, jusqu'à **`179806b`**, et le plan **A** en viendra. Pour que A → B
n'isole que les lampes, **B doit partir de la même base que A**.

Vérifié : `d25fadc..179806b` ne touche que `docs/CODEX_HANDOFF.md`,
`docs/KNOWN_ISSUES.md` et `evidence/…` — **rien de ce qui est rendu**, et le
GLB est toujours `8bf1a1b309aee79f…`. Le lead s'engage à ce que ses commits
restent documentaires jusqu'aux captures AVANT.

**Base retenue et à inscrire dans les deux manifestes : `179806b`.**

## Procédure

```sh
L=/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad/r2a352/eclats_godot_blender.lock
V=/tmp/claude-0/-home-user-Zelda/3f49d367-f832-522e-bb57-a1c4a650c5ad/scratchpad/r2a352/visuel
W=/home/user/zelda-r2a352/visuel_diag

# 1. worktree jetable, avec son filet de retrait
git -C /home/user/Zelda worktree add --detach "$W" 179806b
trap 'git -C /home/user/Zelda worktree remove --force "$W"' EXIT INT TERM

# 2. les DEUX lignes de lampe, et rien d'autre.
#    `str.replace` silencieux est interdit ici (tools/CLAUDE.md) : on
#    vérifie la présence AVANT, et on relit l'endroit exact APRÈS.
F="$W/scripts/world_v2/poi/waterfall_cave_place.gd"
grep -c 'seuil.position = Vector3(0.20, 1.50, -2.60)' "$F"   # doit rendre 1
grep -c 'salle.position = Vector3(0.20, 1.90, -7.20)' "$F"   # doit rendre 1
sed -i 's/seuil\.position = Vector3(0\.20, 1\.50, -2\.60)/seuil.position = Vector3(0.15, 1.50, -1.20)/' "$F"
sed -i 's/salle\.position = Vector3(0\.20, 1\.90, -7\.20)/salle.position = Vector3(2.70, 1.90, -3.35)/' "$F"
grep -n 'seuil.position\|salle.position' "$F"                # relire l'endroit exact
git -C "$W" diff --stat                                      # doit montrer 1 fichier, 2 lignes

# 3. import OBLIGATOIRE — worktree neuf, aucun `.godot/`
#    (l'essai du 2026-08-16 a prouvé que le garde-fou de fraîcheur mord
#    pour de vrai : BLOQUÉ 3 sur trois prototypes non importés)
flock "$L" sh -c "godot --headless --path $W --import > $V/diag/import.log 2>&1; \
  echo \"RC=\$?\" >> $V/diag/import.log"

# 4. plan B, mêmes caméras, même résolution, même exposition
flock "$L" sh -c "xvfb-run -a --server-args='-screen 0 1280x720x24' \
  godot --path $W --rendering-driver opengl3 \
  --script tools/godot/capture_poi_batch.gd -- \
  --scene=res://scenes/world_v2/WorldV2.tscn \
  --shots=$V/plans/shots_r2a352.json --out-dir=$V/diag/plan_B --size=1280x720 \
  --provenance=geometrie:assets/environment/caves/SM_WaterfallCave.glb,lieu:scripts/world_v2/poi/waterfall_cave_place.gd \
  > $V/diag/capture.log 2>&1; echo \"RC=\$?\" >> $V/diag/capture.log"

# 5. manifeste : l'arbre est sale PAR CONSTRUCTION, on le dit
python3 $V/outils/enrichir_manifeste.py --arbre "$W" \
  --manifeste $V/diag/plan_B/manifest.json \
  --sortie $V/diag/plan_B/manifest_enrichi.json \
  --cote "B — DIAGNOSTIC : geometrie R2a-3.4, lampes R2a-3.5.2, arbre SALE, non probant comme livrable" \
  --tolerer-sale

# 6. retrait (le trap le fait aussi si la session tombe)
git -C /home/user/Zelda worktree remove --force "$W"
```

## Statut du plan B — à répéter partout où il apparaît

`repo_dirty: true` **par construction**, et c'est voulu : le plan B existe pour
séparer deux causes, pas pour être livré. Il est étiqueté
**`DIAGNOSTIC — arbre sale, non probant comme livrable`** dans son manifeste,
dans son nom de dossier et sur la planche. Seuls **A** et **C** sont versés
comme preuve.

C'est la même discipline que le handoff impose à `BASE352` : un état
intermédiaire de diagnostic ne se présente jamais comme une baseline livrée
sans être explicitement étiqueté.

## Ce que le triptyque ne couvre pas

- Les silhouettes **5-7 sont immunisées** — `capture_silhouette.gd` remplace
  tous les matériaux par un unshaded, neutralise les `WorldEnvironment` et
  n'ajoute aucune lumière. **Q4 n'est pas touchée par le confondant.**
- Les vues **1-2** (approche) et **8-9** (visière face, profil) sont peu
  affectées : elles regardent la roche extérieure au soleil, pas la sous-face.
  Peu affectées n'est pas « pas affectées » — `JourDuSeuil` déborde de 4,3 m.
- `APPUIS_MODELE` change aussi entre les deux arbres (8 points sur 8). Ce sont
  des points d'appui déclarés, pas de la géométrie visible ; **NON VÉRIFIÉ**
  qu'ils n'aient aucun effet d'image.

---

# RÉSULTAT — le confondant mesuré, et il est bien plus gros qu'annoncé

Plan A : tronc `1152c92`, GLB `8bf1a1b3`, arbre propre, `repo_dirty: false`.
Plan B : worktree `visuel_diag` sur la même base, **deux lignes de lampe**,
`repo_dirty: true`, étiqueté `DIAGNOSTIC … NON PROBANT comme livrable`.
Même GLB `8bf1a1b3` des deux côtés — **la géométrie est identique aux octets
près**. Tout écart entre A et B est donc **l'éclairage, et rien d'autre**.

Worktree retiré par son filet après capture (`git worktree list` : absent).

## Part des pixels changés par L'ÉCLAIRAGE SEUL

| vue | pixels changés | écart max |
|---|---:|---:|
| `04_interieur_sortie` | **83,97 %** | 152/255 |
| `03_gros_plan_seuil` | **61,20 %** | 84/255 |
| `11_orteil_pied` | 26,33 % | 121/255 |
| `10_visiere_dessous` | **14,77 %** | 98/255 |
| `08_visiere_face` | 8,41 % | 85/255 |
| `02_approche_joueur` | 5,78 % | 90/255 |
| `09_visiere_profil` | 1,25 % | 164/255 |

## Ce que ces chiffres disent

1. **Les deux vues intérieures sont DOMINÉES par l'éclairage** — 84 % et 61 %
   des pixels. Les publier comme un A/B « de géométrie » aurait attribué au
   surplomb l'essentiel d'un changement de lampe. Le triptyque n'était pas une
   précaution : sans lui, ces deux planches auraient été fausses.
2. **La vue de Q2 change de 14,77 %.** C'est bien assez pour qu'une ombre
   différente sous le surplomb soit lue comme un défaut de géométrie. Q2 n'est
   répondable que par B → C.
3. **`09_visiere_profil` est quasi immune, à 1,25 %.** Le trois-quarts extérieur
   à l'azimut 100 répond donc à Q1 presque proprement — c'est un argument de
   plus pour cette vue, découvert après coup et non recherché.
4. Les silhouettes restent **totalement** immunes : unshaded, sans lumière.

## Lecture des planches

- A → B : **l'éclairage seul**. Tout écart y est une lampe.
- B → C : **la géométrie seule**. Tout écart y est la visière.
- A → C : les deux ensemble — à ne jamais présenter seul sur `03`, `04`, `10`.
