# ISS-059 — la signature de sortie après R2B.3

`tools/validate_fast.sh` lancé **une seule fois**, à la fin de la passe, isolé
(`XDG_DATA_HOME=/tmp/ud_validate_fast`, verrou du dépôt), RC **1**.
Journal : `validate_fast_R2B3.log`.

**947 tests réussis, 0 échoué.** Le rouge vient exclusivement des diagnostics de
fin de processus, comme depuis l'ouverture du ticket.

## La signature s'est effondrée

| classe | R2B.2 (`ea93460`) | **R2B.3** | écart |
|---|---:|---:|---|
| tests réussis / échoués | 943 / 0 | **947 / 0** | +4 / 0 |
| `ObjectDB instances` | 5 203 | **1 003** | **−4 200** |
| `resources still in use` | 239 | **657** | +418 |
| **`DummyMaterial`** | **4 849** | **281** | **−4 568 (−94 %)** |
| `DummyShader` | 14 | **14** | **0** |
| `DummyMesh` | 42 | **214** | +172 |
| `DummyTexture` | 58 | **67** | +9 |

## Ce que cela veut dire, et ce que ça ne veut pas dire

**Le correctif de la voie B a produit l'essentiel de cette baisse.**
`WorldV2PlaceKit.scene_for()` chargeait ses scènes sans les retenir ; au
démontage la `PackedScene` perdait sa dernière référence, et le montage suivant
reconstruisait des matériaux de base neufs que les caches `static` ne pouvaient
plus retrouver — et gardaient. Mesuré en isolation avant la passe :
**+27 matériaux par cycle sur dix-neuf intervalles, sans plateau**.

**Le résidu qui reste est exactement celui que la bissection reproduit en 97
secondes.** Sonde C5/C6, 74 à 82 scènes instanciées puis démontées dans un seul
processus :

```
Material 281   Shader 14   Mesh 214   Texture 67
```

**Les quatre nombres tombent au chiffre près sur la suite complète.** Ce n'est
plus un faisceau : c'est la même fuite, isolée hors de la suite, rejouable en
une minute et demie au lieu d'une heure.

Identité énumérée à 82 scènes : 276 `StandardMaterial3D` + 4 `ShaderMaterial`,
214 `ArrayMesh`, 67 `Image` + 64 `CompressedTexture2D`, 107 `PackedScene` avec
autant de `SceneState`, **aucune avec `resource_path`**. Ce sont les
sous-ressources de scènes **épinglées par l'instanciation** — le chargement seul
n'en épingle aucune (bloc B de la bissection : 47 GLB chargés ajoutent zéro).

Localisation : tout apparaît **entre la 71ᵉ et la 74ᵉ scène** —
`WorldV2.tscn`, `WorldV2Bootstrap.tscn`, `ResonancePylon.tscn`. Les 70
précédentes sont innocentes, les 8 lieux POI n'ajoutent rien.

## Une prédiction de la bissection qui s'est révélée fausse, et je le dis

La bissection écrivait, en comparant sa sonde à la signature **de R2B.2** :
« la suite fuit 115 matériaux par maillage et la sonde 1,3 — ce n'est donc pas
la même fuite ». C'était juste **contre la signature d'avant**, et faux contre
celle d'après : la suite rend aujourd'hui 281/214 = **1,31**, exactement le
rapport de la sonde.

Autrement dit : la sonde décrivait déjà le résidu **post-correctif**, pendant
qu'elle était comparée à un chiffre **pré-correctif**. L'écart de SHA était
signalé dans son propre §0 comme « la limite d'attribution de tout ce qui
suit » — la limite était réelle, et c'est elle qui a produit la fausse
conclusion.

## Statut

**`PARTIAL`. ISS-059 reste OUVERT.**

Ce qui est **acquis** : une vraie fuite cumulative corrigée ; la signature
divisée par près de 18 sur `DummyMaterial` ; le résidu restant **caractérisé,
localisé à trois scènes, et rejouable en 97 s hors de la suite**.

Ce qui **manque encore**, et qui interdit de fermer : **quel objet retient les
`PackedScene` épinglées à l'instanciation**. La sonde le montre, elle ne le
nomme pas. Tant que ce nom n'est pas mesuré, il n'y a pas de causalité — et sans
causalité, pas de fermeture.

Le harness reste **ROUGE**, et il est rapporté comme tel.
