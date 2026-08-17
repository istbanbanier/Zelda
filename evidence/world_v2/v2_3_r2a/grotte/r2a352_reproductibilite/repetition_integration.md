# Répétition de l'intégration, à blanc, hors du tronc

**FAIT REPRODUIT.** La séquence d'intégration a été jouée **entièrement** dans un
worktree jetable avant de toucher le tronc, et elle aboutit.

Ce que cette répétition établit et que la mesure du checkpoint 1 n'établissait
**pas** : le checkpoint 1 prouvait que la chaîne reproduit `cc3596c5` **depuis
l'arbre du lot** `e0e7567`. Il ne disait rien de ce qu'elle produirait **depuis le
tronc**, dont tous les autres fichiers diffèrent — à commencer par le kit de
modules que le générateur importe.

## Protocole

Worktree `/home/user/zelda-r2a352/repetition`, détaché sur le tronc `179806b`,
arbre propre. Commits locaux jetables, jamais poussés.

| étape | commande | résultat |
|---|---|---|
| commit 0 | `git checkout c79341e -- <9 fichiers>` | `9 files changed, 2687 insertions(+), 221 deletions(-)` |
| commit 2 | `git checkout e0e7567 -- <py> <blend> <2 sondes>` | `4 files changed, 848 insertions(+)` |
| chaîne | `tools/blender/export_architecture.sh waterfall_cave` | **RC 0**, `=== VALIDE ===`, 20 970 tri |
| restauration | `git checkout e0e7567 -- <blend>` | seul le `.glb` reste modifié |
| commit 3 | `git add <glb>` puis commit | `Bin 1506684 → 1489928`, **arbre propre** |

## Le résultat

```
GLB produit depuis l'arbre TRONC + base + collerette :
  cc3596c5d68cbfd8060987604aad6d5356772df18086f3f76f5aa8dbf8a73f49
attendu :
  cc3596c5d68cbfd8060987604aad6d5356772df18086f3f76f5aa8dbf8a73f49
```

**Byte-identique.** Les autres fichiers du tronc — kit de modules compris —
n'influencent pas la géométrie produite. La quatrième étape de l'ordre
d'intégration aboutira, et le commit d'export portera légitimement l'empreinte
attendue.

## Le contrôle final, sur les deltas et non sur le vide

Un `git diff` vide entre le tronc et `c79341e` ne prouverait que l'égalité finale,
pas l'absence de contenu tiers. Le contrôle compare donc **deux patches** :

```
git diff c79341e HEAD      -- make_waterfall_cave.py   >  A
git diff c79341e e0e7567   -- make_waterfall_cave.py   >  B
diff A B  →  identiques
```

→ **le générateur sur le tronc simulé porte exactement le delta collerette**, ni
plus ni moins.

Et les six fichiers de base que **personne ne touche** sont bien à leur état
`c79341e`, vérifiés par comparaison de blob :

```
OK  scripts/world_v2/poi/waterfall_cave_place.gd
OK  tools/plot_cave_section.py
OK  tools/probe_cave_selftest.py
OK  tools/probe_cave_negative_control.py
OK  tools/blender/diag_cave_etapes.py
OK  assets/environment/caves/prototypes/SM_WaterfallCave_BASE352.glb
```

## Ce que la répétition ne couvre pas

**Le commit 1 — les instruments — n'a pas été répété**, parce que son contenu
bouge encore : l'arbre `c_instruments` est en cours de modification par l'agent
qui le tient. La liste de fichiers devra être **relue au moment d'appliquer**, et
non reprise d'un relevé antérieur.

La répétition ne dit rien non plus des **gates de qualité** — épreuves adverses,
oracle d'étanchéité, calibration. Elle prouve la **mécanique** de l'intégration,
pas le droit de l'exécuter.

## Trace

Worktree `repetition` conservé jusqu'à l'intégration réelle, avec trois commits
locaux jetables (`08a2967`, `1b8e62b`, `b3e468c`). Il ne sera **jamais** poussé et
n'a aucun lien avec la branche. Journal de chaîne :
`scratchpad/r2a352/repetition/chaine_depuis_le_tronc.log`.

Aucun seuil modifié. Aucune géométrie versée au tronc par cette répétition.
