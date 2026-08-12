# Extension de la bibliothèque d'assets — 2026-08-12

Référence durable : `asset_library/README.md`.

Cette passe ne modifie ni scène, ni gameplay, ni build. Elle fournit une quarantaine
CC0 reproductible pour la future production de toute la Vallée de Néris et conserve
séparément un catalogue plus large. Les choix ont été confrontés aux lieux réels de
`docs/POI_MAP.md` et aux constats de `docs/WORLD_ATLAS.md`.

Fichiers de décision :

- `asset_library/ASSET_CATALOG.csv` — existant, landed, candidat et rejeté ;
- `asset_library/MAP_COVERAGE.md` — couverture de chaque lieu ;
- `asset_library/SELECTION_REPORT.md` — critères et garde-fous ;
- `asset_library/CLAUDE_USAGE_PROMPT.md` — annexe du prochain prompt de production ;
- `asset_library/SOURCES.lock.csv` — entrées réellement téléchargées ;
- `.github/workflows/world-asset-library.yml` — atterrissage automatisé et borné.

La branche ne doit pas être fusionnée aveuglément dans une branche de livraison :
Claude l'intègre à sa branche de production, puis promeut seulement les fichiers
justifiés par un lieu et un défaut visuel mesuré.
