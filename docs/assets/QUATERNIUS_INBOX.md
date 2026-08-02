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

---

# ACQUISITION RÉUSSIE — Release GitHub (ordre de nuit V3, 2026-08-02)

Le propriétaire a déposé les SEPT archives dans la Release
`asset-inbox-quaternius-free-v1` du dépôt du projet. Canal : API GitHub
(MCP `get_release_by_tag`) + `curl --fail --location --retry 3` sur les
`browser_download_url`. Zone de travail HORS dépôt :
`/tmp/eclats-quaternius.X2JMwF/` (archives + extraction). Les archives ne
sont **jamais** entrées dans le dépôt.

## Vérifications par archive (§4 de l'ordre)

Les sept archives : `file` = « Zip archive data » (aucune page HTML),
`unzip -tq` = OK, `zipinfo -1` = **aucun** chemin absolu, lettre de lecteur
ni `..`. SHA-256 locales **identiques** aux digests publiés par GitHub :

| Archive | Octets | SHA-256 |
|---|---:|---|
| Stylized.Nature.MegaKit.Standard.zip | 104 088 529 | `298f6732b872e4cf7b30e6e7abf9641c7f6dc6b326df37ac089533ed7e3d58c9` |
| Fantasy.Props.MegaKit.Standard.zip | 150 213 360 | `8b6f7e806d222e585478f0e1bdc6b271bbc7bc6f84dd6af8ca703a7c64f0cb1e` |
| Medieval.Village.MegaKit.Standard.zip | 161 003 471 | `e60dea67c10f30dccccfbff92a7933f5ea5cfe99be0e2a0fa5118cceabeec5c4` |
| Universal.Base.Characters.Standard.zip | 128 968 391 | `fdbf1804c90dfc1ea03e992bff7da2dfd1a79318e13270a660180f9308455f40` |
| Modular.Character.Outfits.-.Fantasy.Standard.zip | 294 347 394 | `c3468b18871cc8c8f05ab14df7712baf22cb9f389cbd870babf130e595187f70` |
| Universal.Animation.Library.Standard.zip | 15 904 933 | `cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724` |
| Universal.Animation.Library.2.Standard.zip | 18 735 003 | `4008ea208a604773a2b2177d965f0f5d3195498b5bf838c3f5785d68e95f2a68` |

## Licence

**CC0 1.0 Universal**, confirmée sur le fichier `License*.txt` présent dans
CHACUNE des sept archives (pas déduite d'une page web). Auteur : Quaternius
(https://quaternius.com). Éditions « Standard » gratuites — sous-ensembles
des éditions payantes, ce qui est documenté dans les licences elles-mêmes.

## Contenu utile constaté

- **Nature** : 68 modèles glTF (arbres, pins, rochers, buissons, herbes,
  fleurs, champignons) + textures 2K.
- **Fantasy Props** : 94 props glTF (coffre, caisse, tonneau, chaudron,
  torche, mobilier) sur 2 trimsheets 2K.
- **Medieval Village** : 176 modules glTF (murs, portes, arches, toits,
  escaliers, piliers) sur trimsheets 2K.
- **Base Characters** : 2 corps riggés (export « Godot - UE ») + coiffures.
- **Modular Outfits Fantasy** : 4 tenues complètes riggées + pièces
  modulaires, textures 4K/2K.
- **UAL 1 & 2** : 43 + 44 clips sur mannequin riggé, `.glb` « Unreal-Godot »,
  en double version : **in-place** (`UAL*_Standard.glb`) et root motion
  (`*_RM.glb`).

## Vérification de compatibilité décisive (risque Q1 levé)

Squelettes comparés par noms d'os (script, pas à l'œil) :
`Male_Ranger` (tenues) = **65 os**, UAL1 = **65 os**, UAL2 = **65 os**,
différences ensemblistes **vides dans les deux sens**. Le retargeting est
donc un branchement direct, pas une adaptation.

## Éléments SANS candidat dans les sept packs

- `prop.tent` — aucune tente dans les packs (vérifié sur les 900+ entrées).
- `prop.campfire` — aucun feu de camp (la torche et le chaudron existent ;
  un feu composé torche+pierres est une option ART-Q3, à défaut le graybox
  reste).

## Sélection ART-Q0 (12 modèles sur ~900)

Voir `docs/assets/ASSET_MANIFEST.csv` (lignes du 2026-08-02) : 5 nature,
3 props, 3 architecture, 1 personnage (candidat). Copie à l'octet près,
textures partagées dédupliquées par dossier. ~101 Mo ajoutés au dépôt,
aucun fichier > 13 Mo (LFS indisponible — vérifié, limite 100 Mo/fichier
respectée).
