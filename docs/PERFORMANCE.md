# PERFORMANCE

> **Aucune mesure n'a été effectuée à ce jour.** La machine de développement n'a ni
> GPU ni affichage (`docs/KNOWN_ISSUES.md` ISS-002). Conformément à §20.1, aucun
> chiffre de FPS ou de temps de frame n'est annoncé tant qu'il n'est pas mesuré sur
> un matériel documenté. Ce fichier fixe le protocole pour que la mesure soit
> immédiate le jour où un GPU est disponible.

## 1. Matériel de référence — à documenter avant toute mesure

Aucune mesure n'est publiable sans ce tableau rempli.

| Champ | Valeur |
|---|---|
| CPU | *non renseigné* |
| GPU | *non renseigné* |
| RAM | *non renseigné* |
| OS / pilote | *non renseigné* |
| Résolution | *non renseigné* |
| Renderer | *non renseigné* |
| Preset | *non renseigné* |
| Build (commit) | *non renseigné* |

Cibles recommandées par §20.1 :
- **Recommended** : Apple M2 Pro ou PC proche RTX 2060 / RX 6600, 16 Go, 1080p High 60 FPS.
- **Base** : Apple M1 intégré ou équivalent, 1080p dynamique Medium 30-60 FPS.
- **Web** : matériel moderne, 900p Compatibility 30-60 FPS.

## 2. Budgets High 1080p (§20.2)

Ce sont des **budgets de départ à vérifier**, pas des résultats.

| Mesure | Cible | Mesuré |
|---|---:|---|
| Frame moyen | ≤ 16,6 ms | non mesuré |
| P95 | ≤ 18,5 ms | non mesuré |
| 1 % low | ≥ 50 FPS | non mesuré |
| Main thread | ≤ 8 ms | non mesuré |
| Render thread | ≤ 10 ms | non mesuré |
| GPU | ≤ 15,5 ms | non mesuré |
| Draw calls extérieur | ≤ 1 500 | non mesuré |
| Triangles visibles | ≤ 2,5-3,5 M | non mesuré |
| IA pleinement actives | ≤ 14 | non mesuré |
| Rigid bodies éveillés | ≤ 60 | non mesuré |
| Voix audio | ≤ 48 | non mesuré |

## 3. Scénarios reproductibles à construire (§20.11)

| Scénario | Contenu | État |
|---|---|---|
| `Perf_Vista` | caméra fixe, végétation, eau, fog, citadelle, éclair | à construire (Phase D) |
| `Perf_Camp` | maximum normal d'IA, feu, projectiles, impacts, loot | à construire (Phase D) |
| `Perf_Electric` | propagation maximale, eau, câbles, lumières, particules | à construire (Phase F) |
| `Perf_BossP3` | attaque la plus coûteuse, caméra et audio | à construire (Phase G) |
| `Perf_Traversal` | course prédéfinie traversant cellules, LOD, streaming | à construire (Phase D) |
| `Perf_Soak` | boucle 60 min avec sauvegardes, respawns, transitions | à construire (Phase I) |

## 4. Protocole obligatoire

1. Warm-up documenté (compilation de shaders et chargements terminés).
2. Enregistrer : build, commit, OS, CPU/GPU, pilote, renderer, preset, résolution,
   durée et seed.
3. **60 s minimum par scène.**
4. Relever : moyenne, p50/p95/p99, 1 % low, nombre de hitches > 33 ms, maximum,
   pic mémoire, cause dominante.
5. Comparer au dernier baseline. Une régression > 10 % sur le temps de frame
   dominant, une hausse mémoire persistante ou un nouveau hitch critique **bloque le
   gate** jusqu'à explication.
6. Mesurer séparément l'éditeur et le build exporté — **le verdict final vient du
   build**.

Ne jamais assouplir un seuil pour faire passer un test sans décision documentée
dans `docs/DECISIONS.md`.

## 5. Interdiction spécifique à cet environnement

Un rendu obtenu via Mesa **llvmpipe** (logiciel, sans GPU) peut servir à vérifier
qu'une scène produit une image non noire. Il ne constitue **jamais** une mesure de
performance et ne doit apparaître dans aucun budget de frame.

## 6. Journal des mesures

*(vide — aucune mesure effectuée)*
