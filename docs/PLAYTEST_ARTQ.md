# Playtest ART-Q — première passe d'assets de production (Quaternius CC0)

Essai humain (MASTER_SPEC §21.9) sur la nuit ART-Q0→Q7 : héros et pillards
riggés/animés, props et architecture de production, biome nature composé.
**Package SANS archive** (ordre de nuit V3) : le dépôt EST le package —
cloner, ouvrir, jouer.

> **Consigne d'or** : jouez d'abord (10–15 minutes, librement). Le verdict
> ESTHÉTIQUE (V4) vous appartient — les tests automatiques prouvent le
> montage et le pilotage, jamais la qualité perçue.

---

## 1. Reproductibilité

| Élément | Valeur |
|---|---|
| Dépôt / branche | `istbanbanier/Zelda` · `claude/phase-0-gate-0-setup-t72ibt` |
| Commit du code jouable | `git rev-parse --short HEAD` après checkout (les lots : `d55b0d4` Q0 → `ed39f8e` Q6, corrections Q7 au-dessus) |
| Godot | **4.7.1-stable**, édition standard (sans .NET) — jamais 4.8 |
| Intégrité (optionnel) | `tools/validate_fast.sh` → `VALIDATE_FAST : VERT` (compte de tests : voir `docs/TEST_REPORT.md`) |

```bash
git clone <dépôt> && cd Zelda
git checkout claude/phase-0-gate-0-setup-t72ibt
git pull    # les lots de la nuit
```

## 2. Lancement

1. Ouvrir `project.godot` avec Godot 4.7.1 (premier import ~1-2 min : les
   nouveaux assets et leurs textures se compressent).
2. **F5** → menu principal → **« Nouvelle partie »**.
3. Contrôles inchangés : voir `docs/PLAYTEST_D1R.md` §3 (AZERTY, souris
   capturée, Échap = pause).

## 3. Ce qui est NOUVEAU à regarder (et juger)

| Où | Quoi | Question pour vous |
|---|---|---|
| Dès le spawn | **Le héros de production** : rôdeur encapuchonné, accents turquoise (épaulière, sangles) — animations réelles (idle, marche, course, sprint, saut, chute, réception, esquive, attaques, dégât, mort) | La silhouette de dos vous plaît-elle ? Le turquoise « répond »-il à la citadelle ? |
| En combat | L'épée VIVANTE dans la main droite (plus de pivot d'épaule), combos animés, roulade | La prise de l'arme est-elle crédible en mouvement ? |
| Au camp (45, 6, 65) | **Pillards animés** (paysans braise, gourdin en main), coffre de production qui S'OUVRE par son couvercle, caisses, tonneaux, anneau de galets au feu | Les pillards lisent-ils « ennemis » ? Le télégraphe rouge avant leurs coups reste-t-il clair ? |
| Forêt sud-est | **Vrais arbres** (2 essences, tailles/orientations variées) sur les mêmes obstacles | La forêt a-t-elle un rythme, ou sent-elle la grille ? |
| Vallée | Phrases végétales : buissons en lisière, galets au coude de rivière, rochers au pied de la falaise | Remarquez-vous les groupes, ou du bruit ? |
| Citadelle + vestibule | Arche de pierre au seuil (dehors ET dedans), piliers modulaires de brique entre braseros ambre et veine cyan | La matière pierre « tient »-elle l'échelle monumentale ? |

## 4. Ce qui reste GRAYBOX (assumé, documenté)

- **Tentes** du camp (aucune tente dans les 7 packs — prismes conservés).
- **Feu de camp** (cylindres + lumière ; les galets de production l'entourent).
- Terrain, falaises, rivière, citadelle en masses : la Phase H (art) et les
  passes suivantes les traiteront.
- La **capuche du héros reste verte** : la teinte multiplicative ne crée pas
  de bleu dans une texture qui n'en a pas — re-texturer est une décision
  d'art humaine (Phase H), consignée.

## 5. Après la partie — verdict

Notez librement, puis répondez :

1. Quel moment vous a semblé le plus « vrai jeu » ?
2. Quel élément casse l'illusion en premier ?
3. Le héros : gardez / ajustez (quoi ?) / refusez.
4. Les pillards : gardez / ajustez / refusez.
5. La pierre de la citadelle : gardez / ajustez / refusez.
6. Un bug ? (quoi, où, reproduisible ?)

Verdict global par famille (héros / ennemis / props / nature /
architecture) : **VALIDÉ ARTISTIQUEMENT** ou **À REPRENDRE** — ce verdict
est le vôtre ; rien ne sera déclaré « validé » sans lui (§0.2).
