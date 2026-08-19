# Checkpoint GM4 — publié et validé depuis l'asset TÉLÉCHARGÉ

- Release publique : https://github.com/istbanbanier/Zelda/releases/tag/world-v2-playtest-r2a-gm4-5f821e5
- Téléchargement direct : https://github.com/istbanbanier/Zelda/releases/download/world-v2-playtest-r2a-gm4-5f821e5/Projet_Godot_WorldV2_R2a_GM4_5f821e5.zip
- Fichier : Projet_Godot_WorldV2_R2a_GM4_5f821e5.zip — 426 184 998 octets
- SHA-256 : 556458d7dcbc95125faf78b935e57f933842f792fd0b7401a515374847f77a09
  (identique au digest annoncé par GitHub sur l'asset, vérifié après
  téléchargement réel par le lead)
- Commit empaqueté : 5f821e586853f2dabdda868df2f5a5f46b0c43e0 (workflow run 32210249267, succès)

## Validation faite sur l'ASSET PUBLIÉ (pas sur une copie locale)

1. téléchargé (426 184 998 octets, sha vérifiée) ;
2. extrait dans un dossier neuf ;
3. grotte active du paquet : sha256 5ff4ec6e… (R2a-3.5.8, GM4) ;
4. import Godot 4.7.1 headless : RC=0 (import_rel.log) ;
5. lancement réel Boot → Menu → Nouvelle partie → WorldV2 : 23 assertions
   vertes (caméra POV par égalité d'identité, HUD, 64 chunks, 9 lieux),
   RC=0 (boot_rel.log) ;
6. guide COMMENT_JOUER.md sain, commit estampillé.

## Écart consigné

Mon premier zip local pesait 798 804 octets de PLUS que l'asset : mes
arbres portaient des __pycache__ non suivis que le checkout du runner n'a
pas. La validation a donc été REFAITE sur l'asset téléchargé (celle qui
compte), et make_playable_zip.sh purge désormais __pycache__ pour que la
comparaison octet à octet tienne à l'avenir.

## Lancer (pour Istvan)

1. Télécharger le ZIP (lien direct ci-dessus) et le décompresser.
2. Installer Godot 4.7.1-stable standard : godotengine.org/download/archive
3. Ouvrir Godot → Importer → choisir project.godot → attendre l'import → F5.
4. Menu → Nouvelle partie → vallée World V2, caméra à l'épaule.
