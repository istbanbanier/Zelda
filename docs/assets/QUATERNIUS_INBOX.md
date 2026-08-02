# Boîte d'entrée Quaternius — état d'acquisition (nuit du 2026-08-02)

Ordre de nuit : intégrer les packs Quaternius Standard (CC0). **Aucune archive
n'est accessible depuis ce conteneur cette nuit** — les quatre canaux prévus
ont été tentés et sont consignés ci-dessous, avec les commandes et erreurs
exactes. Rien n'a été falsifié ; l'infrastructure d'intégration a été
construite avec replis (voir `AssetRegistry`, `CharacterVisual`,
`AssetCalibration.tscn`) pour brancher les modèles À L'ARRIVÉE des archives.

## Canaux tentés

1. **Pièces jointes de session / dossier d'upload du conteneur**
   (`/root/.claude/uploads/...`) : ne contient que le prompt maître et le pack
   V4. Aucune archive Quaternius. Vérifié par listage + recherche
   `find / -iname "*quaternius*"` → zéro résultat.
2. **`~/Downloads`** : aucun dossier `Downloads` n'existe sur ce conteneur
   (session cloud — le dossier est sur le poste du propriétaire).
3. **Routes du Godot Asset Store** (commandes exactes de l'ordre) :

   ```bash
   curl --fail --location --retry 3 --retry-delay 2 \
     --output "$ASSET_TMP/nature_standard.zip" \
     "https://store.godotengine.org/asset/quaternius/stylized-nature-megakit/download/31/"
   # → curl: (22) The requested URL returned error: 403
   # idem pour fantasy-props-megakit/download/141/,
   # medieval-village-megakit/download/142/,
   # universal-animation-library/download/44/
   ```

   Cause vérifiée au proxy (`$HTTPS_PROXY/__agentproxy/status`) :
   `connect_rejected — gateway answered 403 to CONNECT (policy denial)` pour
   `store.godotengine.org:443`. **Le refus est au niveau de la politique
   réseau du conteneur, pas de l'URL** — même blocage que les binaires
   godotengine.org en Phase 0 (D-001).
4. **GitHub Release `asset-inbox-quaternius-free-v1`** : `list_releases` sur
   `istbanbanier/Zelda` → **aucune release** sur le dépôt.

## Voies d'arrivée qui fonctionneront

- **Release GitHub** : créer `asset-inbox-quaternius-free-v1` sur le dépôt et y
  attacher les ZIP — github.com est accessible depuis le conteneur (le clone
  du moteur l'a prouvé). C'est la voie recommandée.
- **Pièce jointe de conversation** : fonctionne (le pack V4 est arrivé ainsi),
  dans la limite de taille des attachements.

## À l'arrivée des archives (procédure prête)

1. `file` (vrai ZIP, pas une page HTML) ; 2. `unzip -t` ; 3. SHA-256 ;
4. extraction hors dépôt ; 5. **confirmation CC0 depuis les documents INCLUS**
   (la licence n'est pas présumée ici — elle sera vérifiée sur pièce) ;
6. inventaire (formats, comptes, tailles) ; 7. import sélectif des seuls
   fichiers utilisés, entrée `ASSET_MANIFEST.csv` + `ATTRIBUTIONS.md` avec
   empreintes ; jamais les archives complètes dans Git.

Les IDs de branchement sont déjà réservés dans `AssetRegistry.CATALOG`
(`char.hero`, `char.raider`, `env.*`, `prop.*`) : déposer les scènes aux
chemins prévus suffit à les faire apparaître partout où le repli graybox est
aujourd'hui affiché.
