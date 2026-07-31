# Éclats d'Orage

Action-aventure 3D stylisée — verticale jouable compacte.
Monde : **Vallée de Néris**. Donjon : **Citadelle de l'Œil-Tempête**.

> **État : Phase 0 (initialisation).** Aucun gameplay n'est encore implémenté.
> Ce dépôt contient à ce stade le cahier des charges, le système de continuité, la
> configuration du moteur et le pipeline d'assets vérifié. Voir `docs/STATUS.md`
> pour l'état exact, preuve par preuve.

---

## 1. Version exacte de Godot

**Godot 4.7.1-stable**, édition standard (sans .NET), commit
`a13da4feb8d8aefc283c3763d33a2f170a18d541`.

Jamais 4.8 dev/beta/RC. La version est vérifiée à l'exécution par
`tests/unit/test_smoke.gd`, qui échoue si le moteur n'est pas 4.7.1-stable.

## 2. Prérequis

| Outil | Version | Rôle |
|---|---|---|
| Godot | 4.7.1-stable | moteur |
| Blender | ≥ 4.0 (4.0.2 vérifié) | production des sources 3D |
| numpy | ≥ 1.26 | **requis** par l'exporter glTF de Blender |
| Python | ≥ 3.11 | outillage de validation |

Sur un poste normal, installer le binaire officiel de Godot.
Dans un environnement où `godotengine.org` est bloqué, `tools/setup_godot.sh`
compile la version exacte depuis la source (voir `docs/DECISIONS.md` D-001).

## 3. Ouvrir le projet

Ouvrir `project.godot` dans Godot, puis **F5** (lancer le projet) ou **F6**
(lancer la scène courante).

## 4. Lancement natif en ligne de commande

```bash
godot --path .                     # lancer le projet
godot --headless --path . --import # importer les ressources sans interface
```

## 5. Contrôles

**Non implémentés — Phase A.** L'InputMap arrivera avec la fondation.
La table cible est figée dans `docs/MASTER_SPEC.md` §8.5 ; invariant principal :
**AZERTY prioritaire, `Q` déplace à gauche** et n'est jamais utilisé pour le lock-on.

## 6. Export macOS / Windows / Linux

**Non configuré — Phase I.** Aucun preset d'export n'existe encore ; en annoncer un
serait une affirmation sans preuve.

## 7. Web

**Non disponible — Phase I**, et optionnel. Le build Web utilisera le renderer
Compatibility (WebGL 2), sans volumetric fog, SDFGI, SSIL, SSR, TAA, FSR2, decals ni
compute. Il ne sera jamais présenté comme identique au natif.

Rappel pour plus tard : un build Web se sert **via HTTP**, jamais en ouvrant
`index.html` en `file://` :

```bash
python3 -m http.server 8000 --directory builds/web
```

## 8. Architecture

```
docs/          cahier des charges, continuité, décisions, preuves écrites
scripts/       code GDScript par domaine (core, player, combat, ai, electricity…)
scenes/        scènes par domaine (boot, player, world, dungeon, ui, tests…)
resources/     données de jeu en Resource (armes, ingrédients, tuning…)
shaders/       shaders par famille
assets/        ressources importables (.glb validés)
source_assets/ sources de production (.blend) — hors res://
tools/         outillage de validation, capture, export
tests/         unit / integration / playthrough
evidence/      preuves datées reliées à un commit
```

Arborescence complète et justification : `docs/MASTER_SPEC.md` §5.5.

## 9. Sauvegardes

**Non implémentées — Phase E.** Format prévu : `user://`, schéma versionné,
écriture atomique, migrations. Voir §19.

## 10. Tests

```bash
tools/validate_fast.sh     # niveaux 1-3 : import, parse, tests unitaires
tools/validate_release.sh  # niveaux 4-7 : exige un rendu réel
tools/blender/run_export.sh # pipeline Blender -> glTF -> validation
```

`validate_release.sh` sort en **code 3 « BLOQUÉ »** dès qu'un de ses niveaux n'est
pas exécuté — y compris quand la capture réussit — au lieu de retourner un faux vert.
Dans l'état actuel du projet il sort **toujours** en 3, puisque les niveaux 4, 6 et 7
n'existent pas encore ; il sort en `1` si la capture elle-même échoue. Le code `0`
ne deviendra atteignable qu'une fois ces niveaux implémentés.

Codes de `capture_reference.gd` : `1` scène illisible · `2` aucun rendu ·
`3` écriture impossible · `4` image uniforme · `5` scène sans géométrie ·
`6` commit indéterminé.

## 11. Presets graphiques

**Non implémentés — Phase I.** Matrice cible : Web / Medium / High / Cinematic,
voir §17.6 et §20.8.

## 12. Limites honnêtes

- **Aucun gameplay.** Le projet est à la Phase 0 ; la boucle de jeu n'existe pas.
- **Aucun GPU ni affichage** sur la machine de développement actuelle
  (`docs/KNOWN_ISSUES.md` ISS-002). La capture fonctionne malgré tout via Xvfb +
  Mesa llvmpipe (rendu **logiciel**) : la régression visuelle est donc possible,
  mais **aucune mesure de performance n'en est tirable** et aucun score visuel
  n'est annoncé. Profilage, frame pacing, session longue et export restent bloqués.
- **Les binaires officiels de Godot et Blender ne sont pas téléchargeables** dans cet
  environnement (politique d'egress, ISS-001). Le moteur est compilé depuis la
  source ; compter ~60-120 min pour une session neuve.
- Le pipeline d'assets est vérifié côté **source** (Blender → `.glb` validé) ;
  la validation d'import côté moteur suit l'état décrit dans `docs/STATUS.md`.
- L'image de référence North Star n'est pas versionnée (ISS-003).

## 13. Propriété intellectuelle

Projet original. Aucun contenu Nintendo ni d'aucune autre œuvre : ni modèle, ni
texture, ni rig, ni animation, ni carte, ni interface, ni son, ni nom affiché.
Les noms `raider_red`, `raider_blue`, `raider_black`, `ravine_troll` et
`centaur_hunter` sont des identifiants internes. Voir `ATTRIBUTIONS.md`.
