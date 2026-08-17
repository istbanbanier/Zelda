# Les contrôles du candidat, reproduits par l'intégrateur

**FAIT REPRODUIT.** Ces chiffres ne sont pas rapportés par un agent : ils sortent
du journal de **ma propre exécution** de la chaîne officielle, run 1, dans le
worktree isolé `determinisme` sur `e0e7567`. Journal source :
`run1_export_depuis_e0e7567.log` et le journal de génération qu'il cite.

Ils font passer le tableau anti-régression du lot collerette de *RAPPORTÉ PAR UN
AGENT* à *FAIT REPRODUIT*.

## Générateur, sur le candidat `cc3596c5`

| critère | mesuré | seuil | verdict |
|---|---:|---:|---|
| trois masses, azimut 55, entaille 0,90 | **3 / 3**, ratio d'emprises **2,16** | 3 · ≥ 2,00 | PASS |
| trois masses, azimut 100, entaille 0,90 | **3 / 3**, ratio **2,33** | 3 · ≥ 2,00 | PASS |
| trois masses, azimut 225, entaille 0,90 | **3 / 3**, ratio **2,25** | 3 · ≥ 2,00 | PASS |
| budget de triangles | **20 090** | [12 000 ; 25 000] | PASS |
| plage plane au-dessus du sol | **8,35 m²** | ≤ 12,00 | PASS |
| **plage plane en façade** | **3,06 m²** | ≤ 6,00 | PASS |
| **épaisseur de paroi** | **0,87 m** | ≥ 0,80 | PASS |
| **épaisseur au linteau** | **1,15 m** | ≥ 0,60 | PASS |
| gabarit joueur | capsule r 0,45 h 1,85 **passe aux 7 stations** du chemin | — | PASS |
| bande utile par station (m) | 0:2,65 · 1:2,65 · 2:1,95 · 3:3,15 · 4:3,45 · 5:4,00 · 6:2,85 | — | — |
| plancher | 54 points sondés **vers le bas**, **0 faute** | 0 | PASS |
| aucun jour | 25 rayons verticaux, croisements pairs et ≥ 2 | — | PASS |
| inspection glTF | `=== VALIDE ===` | — | PASS |

Les points d'épaisseur minimale sont localisés par le générateur : paroi à la
station 6, azimut 32°, `z 1,26` ; collerette à la station 0, même azimut, même
altitude.

## Oracle de plancher indépendant des stations, sur le même candidat

`tools/audit_cave_floor_columns.py --pas 0.25` — il ne connaît ni `CAVITE_ASYM`,
ni `facteur_lateral`, ni `u`. **RC 0.**

```
colonnes balayees                    : 4148
colonnes portant un vide habitable   : 420
VIDES OUVERTS A HAUTEUR DE PLANCHER  : 0
roche sous le vide, minimum          : 2.520 m en (0.48 ; -1.14)
vides dont la roche sous le sol < 0.30 m : 0 sur 420
VERDICT : PASS
```

**Aucune régression du plancher réel** — c'est l'item du gate technique, et il est
tenu par un instrument qui ne partage aucun placement avec le générateur.

Progression du nombre de colonnes coiffées, même instrument, même pas :

| géométrie | colonnes coiffées |
|---|---:|
| `8bc8b9f9` — avant collerette | 358 |
| première visière *(état écrasé)* | 400 |
| **`cc3596c5` — candidat final** | **420** |

Les 62 colonnes gagnées sont de la roche réellement coiffée **et** planchéiée,
apparue devant le porche. Aucune n'est perdue ailleurs.

## Ce que ces chiffres ne disent pas

Ils viennent du générateur et de mon oracle de plancher. **Ils ne remplacent ni
la suite adverse, ni l'oracle global d'étanchéité, ni la calibration des
instruments de collerette** — trois chantiers en cours dont le gate technique
dépend aussi. Un générateur qui valide sa propre sortie reste un juge partial ;
c'est précisément pourquoi les autres existent.

Et aucun de ces chiffres ne dit quoi que ce soit de l'**image**. Le verdict
visuel appartient au lead.
