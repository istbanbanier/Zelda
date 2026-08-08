# `tests/` — règles locales

Ne duplique pas le `CLAUDE.md` racine. Chaque piège ci-dessous est arrivé.

## Le piège qui échoue en silence : un test d'art aveugle après une passe de peinture

```gdscript
var stone: StandardMaterial3D = keep.material_override as StandardMaterial3D
check(stone != null and stone.albedo_color.r - stone.albedo_color.b >= 0.04, …)
```

La passe art a repeint la carte en `ShaderMaterial`. Le cast rend `null`, le
test affiche `r − b = 0.000` et **accuse l'art d'un défaut inexistant** : mesuré,
le shader portait `(0.285, 0.245, 0.205)`, soit `r − b = 0,080` — deux fois le
seuil. Le test a échoué pendant des jours pour rien (H-6, 2026-08-08).

Utiliser `_albedo_of()` de `test_phase_h_silhouettes.gd` : il lit l'albédo quelle
que soit la CLASSE, et rend `Color(-1, -1, -1)` quand rien n'est lisible — pour
que l'appelant échoue **explicitement** au lieu de comparer des zéros.

## La suite n'est pas déterministe — ISS-038

Deux passages du même code ont rendu **804/0** puis **802/2**. Les deux tests
fautifs passent en isolation.

Conséquence pratique : **un passage vert ne prouve pas qu'un test est sain.**
Avant de déclarer un intermittent « corrigé », le rejouer dans la suite
COMPLÈTE, plusieurs fois. En isolation, il sera vert de toute façon.

## Ce que le runner attrape déjà — ne pas le re-tester

`tools/godot/test_runner.gd` échoue déjà sur : un script qui n'étend pas
`GateTestCase`, une méthode de test **sans aucune assertion**, un script qui
redéfinit une méthode du contrat, un fichier qui ne s'instancie pas, une suite
vide, un test asynchrone non attendu.

Ce qui passe au travers, et qu'il faut chercher soi-même :

- **l'auto-comparaison** — attendre `WeaponDefinition.DEGATS_BASE` au lieu du
  littéral `26.0` : le test suit l'erreur au lieu de la dénoncer ;
- **l'assertion sautée** — `if node != null:` autour des seuls `check()` : si le
  nœud est renommé, le test reste vert et muet ;
- **la tolérance qui absout** — `check_approx(v, 6.0, 5.0)` accepte 1 à 11 ;
- **le `await` oublié** sur un helper asynchrone : ses assertions tombent hors
  de la méthode.

`test-coverage-auditor` (dans `.claude/agents/`) cherche exactement ces quatre-là.

## Corriger un bug par le test D'ABORD

Écrire le test, **vérifier qu'il échoue**, puis le plus petit changement qui le
rend vert. Un test qui n'a jamais rougi ne prouve rien.

## Ne jamais assouplir un seuil pour faire passer un test

Si un test échoue, la question est *que mesure-t-il vraiment ?* — pas *quel
seuil le ferait passer ?*. Deux échecs du 2026-08-08 venaient du **scénario**,
pas du critère : la caméra du boss était jugée sur une téléportation (§20.9 dit
qu'après une téléportation on réinitialise l'interpolation, on ne la juge pas).
Le scénario a été rendu physique ; **les trois seuils sont restés identiques.**

## Rejouer vite pendant le travail

`tools/gate_select.sh` ne rejoue que les tests liés au diff (2 min contre 15).
Il ne remplace pas `validate_fast.sh` : une régression hors du diff lui est
invisible par construction.
