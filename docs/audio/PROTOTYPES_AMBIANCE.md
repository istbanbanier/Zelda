# Trois prototypes d'ambiance — ISS-087

**Document VIVANT.** Réserve **D-066**.

**Aucun de ces trois prototypes n'est déclaré meilleur qu'un autre.** Ce
conteneur n'a pas de périphérique audio (ISS-004). Ce document est un choix
**instrumenté à soumettre**, pas un choix fait. Le seul juge est
`docs/audio/PROTOCOLE_ECOUTE.md`.

---

## 0. La décision d'architecture, tranchée

### Prérequis d'intégration — non négociable

**Aucun prototype ne s'intègre avant que `72e081a6` (ISS-088) soit dans l'arbre
porteur.** Sans lui, `play_ambience` pose encore `loop_end = data.size() / 2`,
une borne comptée en octets sur une charge utile QOA à débit variable : P1
reboucle alors sur **6,07 s de ses 30**, P2 sur 3,04 s de chacun de ses lits de
15 s, P3 sur 4,05 s de ses 20 — **et en silence**, aucune garde du moteur ne se
déclenche dans ce régime (`loop_begin < loop_end < frames`).

Un essai d'écoute mené sur cet arbre-là mesurerait fidèlement ce défaut et
condamnerait le choix de durée de boucle par un accident de fusion. La question
2 du protocole (« as-tu entendu quelque chose se répéter ? ») répondrait
« oui, au bout de six secondes » pour un lit qui en dure trente.

Vérification en une ligne, depuis l'arbre porteur :

```bash
git merge-base --is-ancestor 72e081a6 HEAD && echo OUI || echo NON
```


**Question** : un second mécanisme d'ambiance à côté de `play_ambience`, ou
l'extension de `play_ambience` ?

**Verdict : étendre. Pas de second mécanisme.**

La crainte qui avait motivé un prototype autonome — qu'un script sous
`experiments/` pollue le contrat de résidu — **ne tient pas** : un script y est
chargé une fois par `--check-only`, dans un processus séparé, jamais par la
course de la suite. Le refus de mutualiser retombe donc sur ses seuls mérites,
et il n'en a aucun :

`play_ambience` porte déjà quatre acquis, chacun payé par une issue :

| Acquis | Origine |
|---|---|
| lecteur unique — deux ambiances ne se superposent jamais | conception |
| propriété + reddition (`stop_ambience_owned_by`) | **ISS-086** |
| boucle posée sur une **copie**, bornée en **trames** | **ISS-088** |
| routage vers le bus `Ambience` | conception |

Un second mécanisme devrait les regagner tous les quatre. ISS-088 montre à quel
point c'est traître : la borne de boucle se comptait en octets sous un
commentaire qui décrivait le fichier source et non la ressource importée, et
l'ambiance rebouclait sur ses 0,81 premières secondes d'un fichier de 4,00 s —
**en silence**. Deux mécanismes concurrents, c'est la divergence que
`PROMPT4_METHOD` §8 demande d'éviter.

**Et l'extension est presque nulle** : deux des trois prototypes ci-dessous ne
demandent **aucune** modification d'`AudioManager`.

---

## 1. Le budget, décidé avant tout choix de son

Le modèle de coût QOA est exact (0 octet d'écart sur `amb_valley`,
`docs/audio/INVENTAIRE_SONORE.md` §2.4). La durée est donc **le seul paramètre
libre**, et elle se fixe en premier.

**Plafond posé : 500 000 octets** pour tout l'audio d'ambiance, soit 3,8 fois la
banque des 21 sons courts (132 144 o). À 22 050 Hz mono (8 923 o/s), cela
autorise **56 s** de clip cumulé.

**Les trois prototypes dépensent le MÊME budget — 30 s de matière — autrement.**
C'est délibéré : la comparaison à l'écoute porte alors sur la *façon de
dépenser*, et non sur la quantité.

| | contenu | total | octets | × la banque |
|---|---|---|---|---|
| **P1** | 1 lit de 30 s | 30,0 s | **267 728** | 2,03 |
| **P2** | 2 lits de 15 s | 30,0 s | **267 744** | 2,03 |
| **P3** | 1 lit de 20 s + 4 événements de 2,5 s | 30,0 s | **267 808** | 2,03 |

Écart maximal entre les trois : **80 octets**. À 44 100 Hz, le même contenu
coûterait 535 424 o — le double, pour les raisons de §4 de l'inventaire.

Tampon de décodage : 10 240 o par voix jouante. P1 et P3 en tiennent une, P2 en
tient deux s'il fond l'un dans l'autre.

> Rappel du seuil : au-delà de **7,4 s** de clip cumulé en 44,1 kHz — **14,8 s**
> en 22,05 — l'ambiance pèse plus que toute la banque des sons courts. Les trois
> prototypes sont **au-dessus** de ce seuil, en connaissance de cause : le coût
> est assumé et plafonné, pas subi.

**Les durées sont des hypothèses, pas des mesures.** Je ne peux pas entendre si
une boucle de 15 s se trahit. C'est exactement ce que la question 2 du protocole
d'écoute va chercher.

---

## 2. Contrainte commune : qui démarre, qui rend

C'est le point où ISS-086 se rouvrirait. **Un producteur qui démarre sans rendre
laisse une ambiance que personne ne peut plus arrêter.**

Et le portail le dirait **mal**. Une ressource audio survivante ne sort pas en
`Resource still in use:` — la copie d'ISS-088 n'entre jamais dans
`ResourceCache::resources`. Elle ne sort pas non plus en `Leaked instance:` sans
`--verbose`, que `validate_fast` ne passe pas. Elle ferait simplement passer
`objets fuités` de 140 à 141, et rougirait en
**`ENGINE_SCRIPT_CACHE_TELEMETRY : DÉRIVE`** — sous une bannière dont le texte
dit que ce n'est *pas* une fuite du projet et propose d'entériner. C'est mesuré,
c'est D-064, et c'est le piège le plus coûteux de ce périmètre.

> **Règle** : ne jamais entériner une dérive d'`objets fuités` sans avoir passé
> `tools/gate_fuite_composition.sh`, seul mode qui **nomme** la ressource.

### Le porteur : `GameplayShell`, et pourquoi pas `world_v2_root`

Le propriétaire naturel — `scripts/world_v2/world_v2_root.gd`, qui a déjà
`_ready()` et `_exit_tree()` — est **gelé par empreinte** dans
`docs/contrats/gel_v2_3_b.sha256`. Intouchable.

`scripts/ui/gameplay_shell.gd` n'est pas gelé, porte déjà
`class_name GameplayShell` — donc **aucun `class_name` neuf** — et il est
instancié dans **dix scènes jouables** : `WorldV2`, `ValleyWorld`, `BossArena`,
`CitadelVestibule` et les cinq salles du donjon. Il a `_ready()` ; il lui manque
`_exit_tree()`.

**Un seul porteur couvre donc tout le jeu jouable, et la scène existe déjà dix
fois.** Le corollaire hérité — « il n'existe aucune scène pour lancer un
prototype » — est faux.

```
_ready()      -> AudioManager.play_ambience(<son>, self)
_exit_tree()  -> AudioManager.stop_ambience_owned_by(self)
```

`stop_ambience_owned_by` ne fait rien si quelqu'un d'autre est propriétaire :
une scène qui sort tard — `queue_free()` diffère la sortie à la fin de la frame
— ne coupe pas l'ambiance que la scène suivante vient de démarrer. C'est le
contrat `tests/integration/test_ambience_ownership_iss086.gd`.

---

## 3. P1 — Lit unique

**Question posée** : un lit continu, seul, suffit-il à retirer l'impression de
projet inachevé ?

| | |
|---|---|
| Contenu | 1 boucle de **30 s**, 22 050 Hz mono |
| Coût | **267 728 o** + 10 240 o de tampon |
| Zones | aucune |
| Démarre | `GameplayShell::_ready()` |
| Rend | `GameplayShell::_exit_tree()` |
| Modification d'`AudioManager` | **aucune** |
| Travail | ~8 lignes dans `gameplay_shell.gd` · 1 générateur · 1 `.wav` · 1 entrée `ATTRIBUTIONS.md` |

Conception spectrale : énergie logée dans **707-2 828 Hz**, la seule bande
creuse (§3.2 de l'inventaire). Creux délibéré en 125-500 Hz, où onze des vingt
sons courts vivent. Rien au-dessus de 11 025 Hz — c'est gratuit à 22,05 kHz.

C'est la référence à battre. **Si P2 et P3 ne se distinguent pas de P1 à
l'écoute, P1 gagne**, parce qu'il est le moins de code.

---

## 4. P2 — Deux lits, bascule par région

**Question posée** : le joueur perçoit-il qu'il change de lieu ?

| | |
|---|---|
| Contenu | 2 boucles de **15 s** — « ouvert » et « fermé » |
| Coût | **267 744 o** + 10 240 o (coupe franche) ou 20 480 o (fondu) |
| Zones | groupe `&"world_v2_regions"`, métadonnée `bounds` |
| Démarre | `GameplayShell::_ready()` |
| Rend | `GameplayShell::_exit_tree()` |
| Modification d'`AudioManager` | **aucune** en coupe franche ; un second lecteur si fondu |
| Travail | ~8 lignes dans `gameplay_shell.gd` · ~80 lignes de lecteur de zone · 2 `.wav` |

Le lecteur de zone va dans **`scripts/audio/`** — répertoire neuf, hors du gel et
hors du glob `ls scripts/world_v2/*.gd`. **Sans `class_name`** : chargé par
`preload(...).new()`.

### Les deux cas qui ne sont pas des cas limites

L'acquis mesuré est sans ambiguïté : **19,3 %** du disque jouable n'appartient à
aucune région, et il y a **onze recouvrements de boîtes pour dix paires de
régions**. Un producteur piloté par région doit donc définir :

- **aucune région** — 19,3 % du monde : **garder le lit précédent**, jamais le
  silence. Le silence par trou de découpage serait pire que pas d'ambiance du
  tout, parce qu'il paraîtrait cassé.
- **deux régions** — les recouvrements : **premier match dans l'ordre déclaré**,
  ordre stable, donc résultat reproductible.
- **hystérésis** : ne basculer qu'après **2 s** passées dans la nouvelle
  région. Sans cela, marcher le long d'une frontière fait battre le son.

Deux formes de `bounds` à gérer, sous peine de laisser la bordure muette :
`{x, z}` pour douze boîtes, **`{ring_radius_m}` pour `r11`**.

`world_v2_layout.json` est gelé : **aucune donnée de zone ne peut y être
ajoutée.** Le rattachement région → lit se fait par une table dans le script.

C'est le prototype le plus coûteux en code, et le seul dont la valeur dépend
d'une perception que je ne peux pas mesurer.

---

## 5. P3 — Lit + événements espacés

**Question posée** : pour un même budget, quatre événements rares donnent-ils
plus de vie que dix secondes de lit en plus ?

| | |
|---|---|
| Contenu | 1 boucle de **20 s** + 4 sons de **2,5 s** |
| Coût | **267 808 o** + 10 240 o de tampon |
| Zones | aucune |
| Démarre le lit | `GameplayShell::_ready()` |
| Rend le lit | `GameplayShell::_exit_tree()` |
| Événements | `AudioManager.play_sfx()` — **rien à rendre** |
| Modification d'`AudioManager` | **aucune** |
| Travail | ~8 lignes + ~15 lignes de minuterie · 1 générateur · 5 `.wav` |

Les événements passent par le pool de huit voix existant : ils sont
« tire-et-oublie », donc **ils n'ajoutent aucun risque de propriété**. C'est
l'argument principal de P3 face à P2.

Intervalle proposé : **20 à 45 s**, tiré au sort. Le garde `SFX_MIN_INTERVAL`
(0,045 s) et le tour de rôle destructif du pool sont sans effet à cette échelle.

Conception spectrale : le lit dans 707-2 828 Hz comme P1 ; les événements
peuvent monter plus haut **parce qu'ils sont rares** — un événement toutes les
30 s qui masque brièvement un pas ne coûte pas ce que coûterait un lit continu
au même endroit.

---

## 6. Ce qu'il faut corriger quel que soit le prototype retenu

`AudioManager::_restore_saved_volumes()` ne parcourt que `Master`, `Music` et
`SFX`. **Le bus `Ambience` n'est jamais restauré** — non plus que `UI` et
`Voice`. Un joueur qui baisserait l'ambiance la retrouverait à son niveau par
défaut au lancement suivant, curseur affichant le contraire : exactement le
défaut qu'ISS-085 avait corrigé pour les trois autres bus, laissé incomplet.

Correction d'une ligne, indépendante des trois prototypes. **Sans elle, aucun
prototype n'est réglable par le joueur**, ce qui invalide en partie le protocole
d'écoute.

---

## 7. Production des sons : la règle qui prime

**Produire les sources directement à 22 050 Hz.** Ne jamais passer par
`force/max_rate` dans un `.import` : `AudioStreamWAV::load_from_file`
ré-échantillonne par interpolation cubique **sans filtre anti-repliement**, et
un ton de 16 kHz s'y replie **intégralement** à 6 050 Hz (mesure et méthode dans
`docs/audio/INVENTAIRE_SONORE.md` §4.1).

Générer par script versionné, comme `make_placeholder_sfx.py` : la provenance
est le script, la licence est triviale, et le résultat est reproductible.

---

## 8. Chiffrage total du travail d'intégration

| Élément | P1 | P2 | P3 |
|---|---|---|---|
| Lignes dans `gameplay_shell.gd` | ~8 | ~8 | ~23 |
| Script neuf sous `scripts/audio/` | — | ~80 | — |
| Modification d'`AudioManager` | — | 0 ou ~30 (fondu) | — |
| Fichiers `.wav` à produire | 1 | 2 | 5 |
| Correction du bus `Ambience` | 1 ligne (commune) | | |
| Fichier gelé touché | **aucun** | **aucun** | **aucun** |
| `class_name` neuf | **aucun** | **aucun** | **aucun** |
| `.gd` dans `scripts/world_v2/` | **aucun** | **aucun** | **aucun** |

Aucun des trois ne touche au gel, n'ajoute de `class_name` — donc aucun risque
de `+1 GDScript` au contrat de résidu — ni ne dépose de `.gd` dans le répertoire
dont le gel globe le contenu.
