# Revue contradictoire ART-Q — nuit du 2026-08-02

Réviseur : adversarial-qa, contexte frais. Périmètre : f9a0e0d..ed39f8e
(E.2 fondations + ART-Q0→Q6). Commandes REJOUÉES sur HEAD ed39f8e propre.

## Verdicts par lot

| Lot | Verdict |
|---|---|
| E.2 fondations (RecipeRules, StatusEffectComponent) | PASS |
| ART-Q0 acquisition + ingestion (7 archives, SHA-256 = digests GitHub recoupés INDÉPENDAMMENT via l'API) | PASS |
| ART-Q1 héros riggé (audit root motion rejoué : node_motion=false 12/12, drift boucles max 0,0000588) | PASS |
| ART-Q2 pillard + variantes (capsule 1,6 m intacte, assertions renforcées) | PASS |
| ART-Q3 coffre/camp (mark_opened_silently sans loot, modèle ≠ collision) | PASS |
| ART-Q4 forêt (collisions de troncs STRICTEMENT identiques au diff) | PASS |
| ART-Q5 vestibule (SceneDoors intactes, retenue de réception purement visuelle) | PASS |
| ART-Q6 teinte sélective (peau non teintée, paquet 4 PNG + 4 JSON) | PASS |

## Règles de l'ordre de nuit

MIN_TESTS strictement croissant 285→312, validate_fast rejoué VERT 312/312 ;
aucune archive ni blob > 20 Mo dans l'historique du périmètre ; diff
resources/weapons + resources/combat VIDE (stats intangibles) ; capsules
1,8/1,6 m inchangées ; 21 glTF/GLB tous au manifeste + ATTRIBUTIONS ;
17 PNG / 17 JSON appariés ; zéro usage de la référence V4 comme asset ;
zéro terme Nintendo ; zéro root motion de nœud. **Toutes : PASS.**

## Défauts (AUCUN S0-S3)

| ID | Sévérité | Constat | Traitement |
|---|---|---|---|
| QA-ARTQ-01 | S4 | Manifestes de capture au commit PARENT avec repo_dirty:true (capture avant commit) | `capture_reference.gd` : dirty = fichiers SUIVIS seulement ; paquet de référence RECAPTURÉ après commit (evidence/artQ7/) |
| QA-ARTQ-02 | S4 | bbox de gltf_inspect non fiable sur les meshes SKINNÉS (premier mesh seulement) | consigné KNOWN_ISSUES (ISS-013) — outillage, pas une preuve invalidée |
| QA-ARTQ-03 | S4 | couture WEAPON_GRIP_EULER/OFFSET (env) sur le chemin runtime | consigné KNOWN_ISSUES (ISS-014) : à retirer en Phase I (build final) |
| QA-ARTQ-04 | S4 | raider_anim_audit.json daté du commit Q1 (bake antérieur au lot) | audits RÉGÉNÉRÉS après le commit Q7 |

## Verdict global : **PASS**

Cité du réviseur : « le dossier d'acquisition Quaternius est recoupable
indépendamment (digests GitHub identiques), et l'audit root-motion est un
vrai garde-fou qui fait échouer le bake, pas un JSON décoratif. »
