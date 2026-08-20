# R2B.3.1 — rapport de passe

Base `06b865b`. Godot `4.7.1.stable.custom_build.a13da4feb`. Conteneur Linux
headless, sans GPU. **Aucune géométrie touchée** : ni la ferme, ni les débris,
ni l'arbre, ni aucun autre lieu. `SM_Farm_Ruins.glb` reste à
`ead79105e3deaf70…`, octet pour octet.

Organisation : le lead a tenu le verrou Godot et pris toutes les mesures
lui-même. Trois agents ont travaillé **sans jamais lancer le moteur** — audit
statique des points d'entrée, analyse statique des rétentions, fabrication des
planches — chacun suivi d'une contre-épreuve dont la mission était de le
réfuter. Les six rapports sont conservés ; ce que la contre-épreuve a corrigé
est signalé comme tel plutôt que fondu dans le résultat.

---

## §1 — ISS-059 : la chaîne causale est nommée

**La question ouverte était : quel objet retient les `PackedScene` épinglées ?**
Réponse mesurée : **trois variables `static` de GDScript sans propriétaire ni
fin de vie.**

```
WorldV2PlaceKit._scene_cache     89 PackedScene → SceneState → ArrayMesh · Material · Image
AssetRegistry._model_cache       21 PackedScene   (3 communes avec la précédente)
WorldV2PlaceKit._material_cache  98 StandardMaterial3D dupliqués par apply_tone()
```

`89 + 21 − 3 = **107**`, exactement le compte de `PackedScene` de la bissection.
La contre-épreuve a vérifié plus fort : la **différence symétrique** entre
l'union des chemins des deux caches et l'ensemble des `PackedScene` fuitées est
**VIDE**.

Le reproducteur passe de 97 s à **22 s** : `WorldV2.tscn` **seule** porte la
signature entière ; `ResonancePylon.tscn` est innocente ; toute combinaison
contenant `WorldV2` donne le même chiffre — une allocation qui **sature**.

**Stable, pas cumulatif** : deux cycles dans le même processus donnent
`objets=2875 ressources=861` aux deux, à l'unité près.

**Le correctif est à la source, et ce n'est pas la suppression du cache.** La
rétention est voulue : sans elle, la fuite reprend à `+27 matériaux par cycle,
sans palier`. Ce qui manquait, c'était la **fin de vie** :
`static func liberer_caches()` sur onze porteurs, inscrite par `_static_init()`
auprès de `StaticResourceCaches`, appelée par `SceneFlow._exit_tree()` à
l'extinction du moteur.

| après correctif | ObjectDB | resources | Material | Shader | Mesh | Texture |
|---|---:|---:|---:|---:|---:|---:|
| avant | 951 | 626 | **281** | **11** | **214** | **65** |
| après | **104** | **55** | **0** | **0** | **0** | **0** |

**Trois affirmations du dossier sont corrigées**, dont deux qui étaient fausses :
les `static` GDScript ne sont PAS libérés avant le rapport ; le moteur n'imprime
JAMAIS le `resource_path` d'une ressource, donc l'observation qui excluait les
caches était un artefact de format ; et `WorldV2Bootstrap` n'est pas un
montage/démontage. Les deux dernières viennent de la contre-épreuve.

Détail : `iss059/CHAINE_CAUSALE.md`.

---

## §2 — ISS-063 : le correctif ne dépend plus du lanceur

**Dette comptée avant le geste** : 13 fichiers, 35 sites, dont **11 fichiers
sans verrou ni cloison**. Un mécanisme unique, `tools/lib/godot_env.sh`, et
**onze fichiers convertis** — dont `validate_fast.sh` (qui ne se sérialisait
avec rien), `.githooks/pre-push` (un moteur par `.gd` sur chaque `git push`) et
`tools/blackbox_player/server.py` (démarré par `.mcp.json`, invisible à tout
garde-fou de commande).

Ce qui ne dépend plus de la discipline :
`test_tout_lancement_godot_prend_verrou_et_cloison`. Cycle rouge d'abord tenu.

Détail, et ce qui reste ouvert (Blender, commande à la volée, `kill` hors
verrou) : `iss063/CORRECTIF.md`.

---

## §3 — dossier visuel léger

Quatre planches JPEG dérivées des PNG existants, **sans relancer un seul
rendu** : `revue_legere/`.

| planche | dimensions | octets | plafond 900 000 |
|---|---|---:|---|
| `ab_leger_debris_a_proche.jpg` | 1280 × 1730 | 576 211 | marge 323 789 |
| `ab_leger_debris_b_proche.jpg` | 1280 × 1730 | 563 094 | marge 336 906 |
| `ab_leger_ferme_laterale.jpg` | 1280 × 1730 | 669 562 | marge 230 438 |
| `ab_leger_ferme_orb090.jpg` | 1280 × 1730 | 706 681 | marge 193 319 |

Contraintes vérifiées **par un contrôleur indépendant, mesurées et non
déduites** : recadrage littéralement identique des deux côtés (une constante
unique par vue, `(0,0,1280,720)`, appliquée aux deux) ; aucune retouche
différentielle, vérifiée dans le code ET sur les pixels (écart moyen à la source
1,368 contre 1,353 — symétrique) ; huit SHA-256 recalculés et conformes ;
déterminisme confirmé par relance octet à octet.

**Deux défauts trouvés par le contrôleur, corrigés ici** : le garde-fou de poids
du script était réglé à `900 × 1024 = 921 600` alors que la contrainte est
900 000 — il aurait laissé passer une planche de 921 599 octets en la déclarant
conforme, et les marges annoncées étaient surestimées de 21 600 octets chacune ;
et le pied de page portant la provenance mesurait 11 à 14 px d'encre, soit 0,68
à 0,86 % de la hauteur — l'information la plus petite de la planche était celle
qui permet de remonter à la source. Police du pied portée de 13 à 28 px, hachage
replié sur deux lignes de 32 caractères sans rien tronquer : l'encre passe à
19–25 px.

**Ces planches ne remplacent pas les preuves originales** : les 11 montages PNG
pleine résolution de R2B.3 restent la référence.

---

## Ce que cette passe n'a PAS fait

- Aucune géométrie, aucun rendu, aucune capture nouvelle.
- Aucune propagation aux 31 POI. `GO_V2_3_B` reste `FALSE`.
- Aucune release jouable, aucun lancement de V2.3-B.
- **Aucun verdict artistique.** Le tas de débris n'a été vu par personne ici :
  ce conteneur n'a pas de GPU. Le verdict appartient à Codex/Istvan.
