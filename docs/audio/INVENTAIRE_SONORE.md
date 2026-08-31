# Inventaire sonore d'Éclats d'Orage — ISS-087

**Document VIVANT.** Réserve **D-066**. Mesuré sur l'arbre `8c6955c6`, branche
`claude/world-v2-iss087-soundscape-research`.

Tout chiffre de ce document est reproductible par une commande citée. Aucun
verdict d'écoute n'y figure : ce conteneur n'a pas de périphérique audio
(ISS-004), et aucun classement sonore ne peut donc en sortir.

---

## 1. Le défaut, énoncé exactement

**Aucune scène atteignable par le joueur ne démarre d'ambiance continue.**

Le chemin réel est `project.godot::run/main_scene` = `Boot.tscn` →
`boot.gd::_go_to_main_menu` → `MainMenu` → `main_menu.gd::WORLD_SCENE` =
`res://scenes/world_v2/WorldV2.tscn`. Le seul appelant de production de
`play_ambience` est `scripts/world/valley_world.gd::_ready`, et
`ValleyWorld.tscn` n'est plus le monde joué : **la fonction est morte.**

Les écrans ne sont pas muets pour autant — `hud_style.gd::attach_ui_audio` crée
un lecteur par écran, et les six sons d'interface jouent. Ce qui manque est le
**lit continu**, pas le retour d'action.

Aucun fichier `.tscn` du dépôt ne porte de nœud `Audio*` : tout le son est créé
par code.

---

## 2. Les fichiers, et ce que chacun devient à l'import

### 2.1 Les 21 sons courts — `assets/audio/sfx/*.wav`

WAV PCM 16 bits **mono 44 100 Hz**, tous. Durées de 0,045 s (`ui_move`) à
0,600 s (`death`), plus `amb_valley` à 4,000 s. Source disque : 651 ko cumulés.

Import : `compress/mode=2`, c'est-à-dire **Quite OK Audio**. Vérifié dans
`editor/import/resource_importer_wav.cpp`, dont l'énumération est
« PCM (Uncompressed), IMA ADPCM, Quite OK Audio ». Le type produit est
`AudioStreamWAV` de `format = FORMAT_QOA`.

**Licence** : générés par `tools/audio/make_placeholder_sfx.py`, versionné.
Domaine public de fait, entrée dans `ATTRIBUTIONS.md`. Aucun échantillon
externe. **Statut assumé : PLACEHOLDERS.**

### 2.2 Les 6 sons d'interface — `assets/audio/ui/*.ogg`

Ogg Vorbis, importés en `AudioStreamOggVorbis` avec `loop=false`. Kenney
Interface Sounds 1.0, **CC0 1.0**, renommés seulement (contenu intact).
Empreintes dans `evidence/full_visual_finish_20260812/promotions_ui.md`.

**Hors de portée de l'instrument de mesure** : `band_profile.py` ne décode pas
l'Ogg Vorbis.

### 2.3 Ce qui dort en quarantaine, utilisable

| Source | Contenu | Licence |
|---|---|---|
| `asset_library/inbox/kenney_interface_sounds_1_0/` | 100+ sons d'interface | **CC0 1.0** |
| `asset_library/inbox/kenney_rpg_audio_1_0/` | pas, tissu, portes, métal, livres | **CC0 1.0** |
| `source_assets/external/kenneynl_starter_kit_*/` | pas, sauts, impacts, moteur | MIT (notice à conserver) |
| `…city_builder/sounds/ambience.ogg` | **une vraie ambiance** — 1 197 592 o, stéréo 44,1 kHz | MIT |

L'`ambience.ogg` existant est le seul fichier d'ambiance déjà présent. Il pèse
**9 fois la banque entière des 21 sons courts**, il est stéréo, et c'est une
ambiance **urbaine** — mauvais monde. Cité pour mémoire, pas retenu.

### 2.4 Le modèle de coût, exact et vérifié

QOA groupe 20 échantillons en une tranche de 8 octets, 256 tranches par trame
(5 120 échantillons), avec 8 octets d'en-tête de trame, 16 octets d'état LMS
par canal, et 8 octets d'en-tête de fichier. D'où :

| | |
|---|---|
| Prédit pour `amb_valley` (176 400 trames mono) | **71 408 octets** |
| Mesuré par ISS-088 dans le moteur (`data.size()`) | **71 408 octets** |
| Écart | **0** |

Une durée se chiffre donc **avant** que le son existe.

| durée | QOA 44,1 kHz | QOA 22,05 kHz |
|---|---|---|
| 8 s | 142 784 o | 71 408 o |
| 15 s | 267 728 o | 133 872 o |
| 30 s | 535 424 o | 267 728 o |
| 60 s | 1 070 816 o | 535 424 o |

Débit asymptotique : **17 847 o/s** en 44,1 kHz, **8 923 o/s** en 22,05 kHz.
Chaque voix en lecture ajoute **10 240 octets** de tampon de décodage.

> **Seuil à retenir** : au-delà d'environ **7,4 s** de clip cumulé en 44,1 kHz —
> **14,8 s** en 22,05 — l'ambiance pèse plus que **toute** la banque des 21 sons
> courts (132 144 octets).

Le budget de **voix**, lui, ne mord jamais : 11 voix simultanées sur 48
autorisées, 37 de marge. **Le budget audio de ce projet se compte en octets.**

---

## 3. Où l'énergie se trouve déjà — la contrainte de conception

Mesuré par `tools/audio/band_profile.py`, instrument validé contre cinq
réponses théoriques (`docs/audio/INSTRUMENT_BANDES.md`). Tableau complet :
`evidence/world_v2/iss087/bandes_sfx.csv`.

Occupation : un son « occupe » une bande s'il y met ≥ 20 % de son énergie.

| bande | occupants | lesquels |
|---|---|---|
| < 22 · 31,5 | 0 | — |
| 63 | 1 | `land_hard` |
| **125** | **7** | death, guard, hit_land, hit_taken, land_soft, refuse, step_stone_b |
| **250** | **5** | death, guard, step_stone_a, step_stone_b, weapon_break |
| 500 | 2 | chest_open, ui_accept |
| 1k | 4 | parry, pickup, swing, ui_move |
| **2k** | **1** | parry |
| 4k · 8k · 16k | 3 · 3 · 2 | **les trois pas sur l'herbe, et eux seuls** |

**Onze sons sur vingt** mettent ≥ 75 % de leur énergie dans 125-500 Hz. La règle
héritée — « creuser 125-500 Hz » — est donc fondée, et elle est confirmée par un
instrument juste après l'avoir été par un instrument faux.

### 3.1 Ce que l'acquis disait, et qui est FAUX

L'acquis transmis disait que la bande d'échappement est « au-dessus de 2 kHz ».
**Elle est occupée.** Les trois pas sur l'herbe y mettent plus de 60 % de leur
énergie, et ce sont les sons **les plus fréquents du jeu** : joués à chaque
foulée par `player_controller.gd::_tick_footsteps`, via un nom construit en `%`
— raison pour laquelle un `grep` du littéral ne les voit pas et les a fait
passer pour livrés sans appelant.

Y loger l'ambiance créerait une **seconde** collision, avec le seul son qu'un
joueur entend en permanence.

### 3.2 La bande réellement creuse

**707 - 2 828 Hz** (octaves 1k et 2k). Cinq occupants au total — `parry`,
`pickup`, `swing`, `ui_move` — tous rares et délibérés, aucun répété.

C'est le seul intervalle du spectre qui ne soit ni le domicile des impacts, ni
celui des pas.

---

## 4. L'arbitrage 22,05 kHz — éprouvé, et il change de nature

L'arbitrage m'a été posé ainsi : 22 050 Hz **halve le coût** et ne touche rien
entre 125 et 500 Hz, mais **ampute de plus de moitié la bande d'échappement
au-dessus de 2 kHz**, de 20 kHz à 9.

Mesuré, cela ne tient plus, parce que la bande amputée n'est pas une bande
d'échappement : **c'est la bande des pas sur l'herbe.**

| Ce que fait un Nyquist à 11 025 Hz | Mesure |
|---|---|
| La zone creuse 707-2 828 Hz survit-elle ? | **Oui, entièrement** — elle s'arrête à 25,7 % du Nyquist réduit |
| Que perd l'ambiance elle-même ? | **2,04 %** de l'énergie d'`amb_valley` |
| Qu'est-ce qui devient **inatteignable** par l'ambiance ? | tout ce qui est au-dessus de 11 025 Hz |

Et c'est ce dernier point qui renverse. Un flux à 22,05 kHz ne porte **aucune**
énergie au-dessus de 11 025 Hz. Donc toute énergie de son court située là est
**mécaniquement à l'abri du masquage** :

| son | énergie > 11 025 Hz, donc à l'abri |
|---|---|
| `step_grass_a` | **22,39 %** |
| `step_grass_b` | **18,90 %** |
| `step_grass_c` | **26,06 %** |
| `step_stone_a` | 1,98 % |
| `hit_taken` | 0,17 % |

**Conclusion soumise** : à 22,05 kHz, l'ambiance coûte moitié moins, conserve
intégralement la seule bande creuse, perd 2 % d'elle-même, et met environ un
cinquième de chaque pas sur l'herbe hors d'atteinte du masquage. Ce n'est plus
un compromis, c'est le meilleur des deux termes.

**Ce que cette conclusion ne dit pas** : si la perte de 2 % s'entend. Elle est
en énergie, pas en perception. Aucune mesure de ce conteneur ne peut trancher
cela — c'est une question pour le protocole d'écoute, et elle y figure.

### 4.1 PIÈGE : ne jamais obtenir 22,05 kHz par `force/max_rate`

`AudioStreamWAV::load_from_file` ré-échantillonne par **interpolation cubique
sans aucun filtre anti-repliement** — c'est le défaut exact qui rendait
l'ancien `band_profile.py` faux, et il est ici dans le moteur.

Preuve, en rejouant l'algorithme du moteur à l'identique
(`Math::cubic_interpolate`, même ordre d'arguments) sur un sinus pur de
16 000 Hz, puis en mesurant avec l'instrument validé :

| | octave dominante |
|---|---|
| avant, à 44,1 kHz | **16k à 100,00 %** |
| après le ré-échantillonnage du moteur, à 22,05 kHz | **8k à 100,00 %** (5 657-11 025 Hz) |

Le ton s'est replié à 22 050 − 16 000 = **6 050 Hz** au lieu de disparaître. Un
ré-échantillonnage correct rendrait ~0 % partout.

> **Règle** : produire la source **directement à 22 050 Hz**. Ne jamais poser
> `force/max_rate` dans un `.import` pour y arriver.

---

## 5. La carte des zones sonores existe déjà

`world_v2_markers_builder.gd::build` crée un `Node3D` par région, l'ajoute au
groupe `&"world_v2_regions"` et lui pose `set_meta(&"bounds", …)`. **Rien à
introduire.**

Onze régions, dans `resources/world_v2/world_v2_layout.json` :

| id | nom | boîtes |
|---|---|---|
| r01 | Crête de l'Aube | 1 |
| r02 | Prairie des Mille Fleurs | 1 |
| r03 | Val de Néris (rivière) | **2** |
| r04 | Falaises du Couchant | 1 |
| r05 | Terrasse du Camp | 1 |
| r06 | Bois du Levant | 1 |
| r07 | Hauteurs de l'Orient | 1 |
| r08 | Steppe du Nord et Contreforts | 1 |
| r09 | Ruines du Cœur | 1 |
| r10 | Marche de l'Orage | **2** |
| r11 | Anneau frontalier | 1, **en anneau** |

Deux pièges, tous deux vérifiés :

1. **`bounds` est un TABLEAU de dictionnaires**, pas un dictionnaire. Treize
   boîtes pour onze régions.
2. **`r11` porte `ring_radius_m: [235, 292]`**, pas `x`/`z`. Tout consommateur
   doit gérer les deux formes, sous peine de laisser la bordure sans ambiance.

Deux propriétés héritées de l'acquis, que je ne redécouvre pas :
**19,3 %** du disque jouable n'appartient à aucune région, et il y a **onze
recouvrements de boîtes pour dix paires de régions distinctes** (r03 a deux
boîtes qui coupent toutes deux r08).

> Conséquence de conception : un producteur d'ambiance piloté par région **doit**
> avoir un comportement défini pour « aucune région » (19,3 % du monde) et pour
> « deux régions à la fois » (les recouvrements). Ni l'un ni l'autre n'est un cas
> limite rare.

`world_v2_layout.json` est **gelé par empreinte** : aucune donnée de zone
sonore ne peut y être ajoutée. Les zones doivent se dériver des métadonnées
déjà posées.

---

## 6. Cycle de vie : pause, transition, mort, sauvegarde

### 6.1 Pause — vérifié dans la source du moteur

`AudioManager` ne pose aucun `process_mode` : il hérite, et un autoload enfant
de la racine se résout donc en **`PROCESS_MODE_PAUSABLE`**. Comportement hérité,
jamais décidé.

`AudioStreamPlayerInternal::_notification` traite `NOTIFICATION_PAUSED` : si le
nœud ne peut pas traiter, il appelle `set_stream_paused(true)`, sous le
commentaire du moteur lui-même *« Node can't process so we start fading out to
silence »*. `AudioServer::set_playback_paused` pose alors l'état
`FADE_OUT_TO_PAUSE` ; le pas de mixage suivant force le volume à zéro
(`bus_details.volume[idx][channel_idx] = AudioFrame(0, 0)`) puis bascule en
`PAUSED`.

**Le fondu dure donc exactement un tampon de mixage**, et il se produit à chaque
pause. Par contraste, `hud_style.gd::attach_ui_audio` pose explicitement
`PROCESS_MODE_ALWAYS` : les sons d'interface, eux, survivent à la pause.

### 6.2 Transition de scène

`scene_flow.gd::go_to` pose `get_tree().paused = true` pendant le chargement.
Toute transition déclenche donc le même fondu d'un tampon, **en plus** du
changement de scène.

`SceneFlow` lui-même est `PROCESS_MODE_ALWAYS`.

### 6.3 Mort, sauvegarde, fermeture

`world_v2_root.gd` sauvegarde sur `NOTIFICATION_WM_CLOSE_REQUEST` et sur
`transition_started`, et déconnecte son signal dans `_exit_tree` — « un autoload
survit à la scène ». La même discipline s'applique à une ambiance : **qui
démarre doit rendre dans `_exit_tree`.**

### 6.4 Le bus `Ambience` n'est jamais restauré

`AudioManager::_restore_saved_volumes()` ne parcourt que `Master`, `Music` et
`SFX`. **`Ambience`, `UI` et `Voice` ne sont pas restaurés** : un joueur qui
baisserait l'ambiance la retrouverait à son niveau par défaut au lancement
suivant. Le défaut est celui qu'ISS-085 avait corrigé pour les trois autres bus,
laissé incomplet.

C'est une correction d'une ligne, indépendante de tout prototype, et elle
devrait être faite quel que soit le prototype retenu.

---

## 7. Où l'ambiance peut vivre — la contrainte de gel

Le gel `docs/contrats/gel_v2_3_b.sha256` couvre **46 fichiers** et son intégrité
est vérifiée (49/49 lignes `OK`). Il contient **les seize** scripts de
`scripts/world_v2/*.gd`, y compris `world_v2_root.gd`.

**Le propriétaire naturel est donc intouchable.** `world_v2_root.gd` a `_ready()`
et `_exit_tree()`, la symétrie exacte qu'exige ISS-086 — et son empreinte est
figée.

Ce qui reste ouvert, et qui vaut mieux :

| Porteur candidat | Gelé ? | Portée |
|---|---|---|
| `scripts/world_v2/world_v2_root.gd` | **OUI** | WorldV2 seulement |
| `scenes/world_v2/WorldV2.tscn` | non | WorldV2 seulement |
| `scripts/ui/gameplay_shell.gd` | **non** | **dix scènes jouables** |

`GameplayShell` est instancié dans `WorldV2.tscn`, `ValleyWorld.tscn`,
`BossArena.tscn`, `CitadelVestibule.tscn` et les **cinq** salles du donjon. Il
porte déjà `class_name GameplayShell` — donc aucun `class_name` neuf — et il a
`_ready()`. Il lui manque `_exit_tree()`, à ajouter.

> **Le corollaire « il n'existe aucune scène pour lancer un prototype » tombe.**
> La scène existe, dix fois. Le travail d'intégration n'est pas d'écrire des
> scènes : c'est d'ajouter un propriétaire à un script déjà présent partout.
> Chiffrage dans la fiche des prototypes.

---

## 8. Reproduire ce document

```
python3 tools/audio/band_profile.py --valider
python3 tools/audio/band_profile.py --csv assets/audio/sfx/*.wav
sha256sum -c docs/contrats/gel_v2_3_b.sha256
```
