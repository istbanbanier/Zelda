# Rapport de sélection — bibliothèque mondiale complémentaire

## Méthode

La recherche a couvert : terrain et routes, roches, végétation, eau, architecture,
ruines, villages, grottes, donjon, camp, props, nourriture, faune, personnages,
animations, armes, VFX, lumière, UI, audio et outils de production. Chaque candidat
a été classé selon licence, redistribution, format Godot, cohérence stylisée,
duplication du dépôt, poids et usage précis dans `docs/POI_MAP.md`.

## Résultat

- **11 packs landed** : libres CC0, transport automatisable, forte couverture des
  manques et budget borné ;
- **plus de 40 candidats catalogués** : utiles mais déjà présents, soumis à un flux
  de téléchargement manuel, redondants, lourds ou nécessitant une décision de scope ;
- **4 familles rejetées** : contenus Nintendo, licences mixtes non auditées, packs
  commerciaux non redistribuables et dumps sans provenance.

La sélection landed couvre 490+ modèles annoncés, 150 sons et plus de 300 masques
ou sprites VFX. Ces nombres viennent des pages des auteurs et ne valent pas inventaire
du dépôt : `INVENTORY.csv`, produit après téléchargement, est la seule vérité locale.

## Pourquoi ne pas tout copier

Le dépôt pèse déjà plusieurs centaines de mégaoctets et n'utilise pas Git LFS.
Copier tous les formats de tous les packs multiplierait FBX, OBJ et glTF identiques,
forcerait Godot à importer des milliers de fichiers et rendrait la prochaine passe
plus lente. Le coursier conserve le format exploitable le plus léger et un catalogue
référencé garde le reste accessible. Cette bibliothèque maximise les choix sans
transformer GitHub en archive incontrôlée.

## Garde-fous

- aucun asset n'est dans `assets/` ;
- aucune scène jouable ni configuration Godot n'est modifiée ;
- une licence/provenance existe par pack ;
- empreinte SHA-256 de chaque archive et fichier ;
- budget dur 120 Mio, fichier dur 50 Mio, 6000 fichiers maximum ;
- aucun pack Nintendo ou asset extrait d'une œuvre commerciale ;
- Poly Haven reste surtout une source de bake/lookdev : ses modèles réalistes peuvent
  atteindre plusieurs millions de triangles et contredisent souvent le style visé ;
- Terrain3D et les plugins restent des **outils candidats**, jamais installés sans
  audit de code, compatibilité Godot 4.7.1 et test isolé.
