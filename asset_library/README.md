# Bibliothèque mondiale complémentaire — 2026-08-12

Cette bibliothèque prépare la future passe « toute la carte » de **Zelda / Éclats
d'Orage**. Elle est volontairement séparée du build : `.gdignore` empêche Godot
d'importer des centaines de candidats tant qu'un lot visuel ne les a pas choisis,
inspectés, renommés et testés.

## Ce qui est réellement livré

- `inbox/` : packs CC0 téléchargés par GitHub Actions depuis la liste verrouillée ;
- `INVENTORY.csv` et `SHA256SUMS.txt` : inventaire octet par octet généré ;
- `SOURCE_ARCHIVE_SHA256.csv` : empreinte de chaque archive réellement reçue ;
- `ASSET_CATALOG.csv` : recherche large, y compris les candidats non déposés ;
- `MAP_COVERAGE.md` : correspondance entre packs et lieux de la vallée ;
- `CLAUDE_USAGE_PROMPT.md` : protocole prêt à joindre au prochain prompt Claude.

Les archives ne sont pas conservées. Pour les modèles, le coursier garde glTF/GLB,
textures et licences ; pour l'audio, OGG/WAV et licences ; pour les VFX, PNG et
licences. Les FBX, OBJ, fichiers Unity, PSD, sources vectorielles et aperçus
redondants sont élagués. Budget dur : **120 Mio**, aucun fichier de plus de 50 Mio.

## Ce que cette bibliothèque ne signifie pas

Un fichier dans `inbox/` n'est ni importé, ni validé visuellement, ni autorisé à
entrer tel quel dans `assets/`. Claude doit sélectionner le minimum utile par lieu,
inscrire la promotion dans `ATTRIBUTIONS.md` et `docs/assets/ASSET_MANIFEST.csv`,
passer `tools/gltf_inspect.py`, vérifier l'échelle, la palette, les collisions et
l'import Godot. Les assets complètent une composition ; ils ne remplacent pas le
terrain, les macro-formes ou le level design.

## Reproduction

Le workflow `.github/workflows/world-asset-library.yml` exécute :

```bash
python3 asset_library/scripts/fetch_locked_assets.py
```

Il ne se déclenche automatiquement que sur la branche de cette bibliothèque et ne
modifie jamais la branche du jeu. Une nouvelle exécution est idempotente : `inbox/`
et les manifestes générés sont reconstruits depuis `SOURCES.lock.csv`.
