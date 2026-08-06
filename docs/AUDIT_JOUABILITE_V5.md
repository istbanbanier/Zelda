# AUDIT DE JOUABILITÉ V5 — ce que douze regards ont trouvé

**Date** : 2026-08-06 · **Déclencheur** : « je trouve le jeu pas très jouable
encore », puis « il y a tout le reste aussi », puis « envoie une armée
d'agents ».

**Méthode** : un joueur en boîte noire qui joue réellement à l'image seule
(aucun accès au code), plus onze auditeurs en lecture seule, chacun sur un
périmètre distinct : première minute · déplacement/caméra · lisibilité du
combat · orientation dans la vallée · donjon et boss · milieu de partie ·
ennemis et rencontres · grandes formes de la carte · son · Bracelet de
Résonance · reprise et checkpoints · confort et accessibilité · API Godot.

**Statut des constats** : chaque ligne ci-dessous cite un `fichier:ligne` du
dépôt et a été rapportée par un auditeur qui l'a lue. Ce qui est marqué
`VU` a en plus été observé dans une capture réelle du jeu. Ce qui n'a pas pu
être vérifié sans écran est marqué `À VÉRIFIER` — jamais présenté comme
acquis.

---

## Les dix constats les plus lourds, classés

### 1. La caméra de jeu tournait à 102° de champ — un fisheye · `VU` · **CORRIGÉ**

`Camera3D.keep_aspect` vaut `KEEP_HEIGHT` par défaut (source Godot 4.7.1,
`scene/3d/camera_3d.h:76`), donc `fov` est un angle **vertical**. Le projet
écrivait 70, en croyant écrire l'horizontal de §8.3 : soit **102,5°** réels.
Le sol s'écrasait, le héros rapetissait, et l'herbe — qui ne mesure pourtant
que 0,56 m — remplissait 40 % du bas de l'écran.

La caméra de composition, elle, avait la bonne valeur : **les captures de
référence n'ont jamais montré la caméra avec laquelle on joue.**

Pire : `tests/integration/test_camera_rig.gd:313` comparait la valeur
verticale à la fourchette horizontale de la spec. **Le test EXIGEAIT le
défaut qu'il croyait interdire.**

### 2. L'inventaire est remis à zéro à chaque changement de scène · **NON CORRIGÉ — le plus grave**

Aucune scène du donjon ne restaure l'inventaire ; chacune instancie un
`Player.tscn` neuf avec l'épée de départ (`scenes/player/Player.tscn:179-182`).
Puis `scripts/dungeon/antechamber.gd:55` écrit le checkpoint **depuis
`_ready()`**, donc avant que le joueur ait pu ouvrir le coffre garanti — et
`scripts/boss/boss_arena.gd:291` restaure ce checkpoint en effaçant tout.

Conséquence chiffrée : on affronte 560 points de vie avec ~257 de dégâts
potentiels, contre ~755 supposés par le calcul de solvabilité. `À VÉRIFIER`
en jeu, mais l'écart est de l'ordre du triple.

Le test de parcours appelle `_write_checkpoint()` **à la main** après avoir
ouvert le coffre (`tests/playthrough/test_boss_run.gd:129`) : il valide un
geste qu'aucun joueur ne peut faire.

### 3. Rien n'oblige jamais à jouer le jeu · **NON CORRIGÉ**

8 ennemis dans 512 × 512 m. Aucun n'est sur la route naturelle : l'écart
latéral minimal est de 30 m pour 22 à 35 m de portée de vision. Deux segments
de la traversée — 0 → 183 m puis 192 → 349 m — ne permettent
**géométriquement aucune détection**. On atteint le boss sans avoir porté un
seul coup.

Et ils ne bougent pas : `patrol_offsets` (`scripts/enemies/enemy_base.gd:64`)
n'est renseigné **nulle part**, donc l'état reste `IDLE`, donc `_face()` n'est
jamais appelé. Huit cônes de vision gravés dans la carte.

### 4. L'horizon est un mur de rectangles, à cause d'un drapeau inversé · `VU` · **CORRIGÉ**

L'arête d'un `PrismMesh` est **horizontale**. Alignée « dans l'axe du mur »,
elle présente de face un segment plat — et 242 prismes plats à des hauteurs
différentes dessinent exactement la skyline de blocs qu'on voulait éviter.
La face triangulaire doit regarder la vallée, pas le ciel.

### 5. Le jeu est muet · **NON CORRIGÉ**

`assets/audio/{ambience,music,combat}/` sont vides. 9 sons couvrent ~40
événements de gameplay. Aucun pas, aucun atterrissage, aucune ambiance,
aucune musique. La déviation parfaite — le geste le plus difficile du jeu —
ne produit **rien** (`scripts/player/player_controller.gd:889`).

Deux fonctions manquantes gardent la porte de tout le reste : il n'existe
**aucun** `AudioStreamPlayer3D` dans le dépôt, et rien pour jouer une boucle.
Gisement dormant : 44 fichiers `.ogg` sous licence MIT déjà présents et déjà
attribués, invisibles de Godot à cause de `source_assets/.gdignore`.

### 6. Le Colosse et le Chasseur sont des statues muettes · **NON CORRIGÉ**

Ni animation, ni télégraphe, ni flash de dégât, ni mort visible :
`_collect_model_materials()` (`scripts/enemies/enemy_base.gd:176-188`) ne lit
que les `surface_override_material`, absents sur ces deux créatures. Tout le
retour visuel de combat passe par un tableau qui reste vide. Le rocher lancé
par le Colosse part **sans avertissement**.

### 7. Le flash de dégât du héros est peint sur un maillage invisible · **NON CORRIGÉ**

`player_controller.gd:1182-1196` écrit l'émission sur `VisualRoot/BodyMesh`,
que `player_visual_driver.gd:46-50` a rendu invisible dès que le modèle riggé
est monté. Et il n'existe **aucune secousse de caméra** dans le projet.
Entre 0,6 s et 0,85 s après un coup, un second coup inflige la totalité de
ses dégâts sans son, sans flash, sans recul.

### 8. La barre de chargement ment · **PARTIELLEMENT CORRIGÉ**

Elle est pilotée par `ResourceLoader` (`scripts/core/scene_flow.gd:129`), qui
a fini son travail bien avant que le monde ne soit bâti. Le monde, lui, se
construit d'un bloc dans un seul `_ready()`.

Cause probable identifiée et corrigée : `AssetRegistry.model()` **jetait la
référence** au `PackedScene` après chaque placement, si bien que le même
`.glb` était relu du disque à chaque objet posé. Reste à mesurer.

### 9. Le monde ne dit jamais rien · **PARTIELLEMENT CORRIGÉ**

33 lieux nommés, et le signal `discovered` n'avait **aucun abonné**. Aucune
boussole, aucun objectif, aucune carte. La seule phrase d'orientation du jeu
dure 3 secondes et n'apparaît qu'en partie neuve.

Le chemin de terre censé montrer la sortie de la crête est **enterré 8 m sous
le sol** (`scripts/world/valley_terrain.gd:1519`, table posée à y=24 pour un
sol monté à y=32) ; trois autres bandes flottent jusqu'à 3,5 m au-dessus de
la rivière. Le test correspondant compte les bandes sans jamais comparer leur
altitude au terrain.

### 10. La mécanique signature est invisible · **PARTIELLEMENT CORRIGÉ**

Les cinq opérations du Bracelet sont câblées, fonctionnelles, et n'étaient
listées dans **aucun écran du jeu**. Aucun refus n'a de retour : on appuie,
rien ne se passe, on conclut que la touche ne sert à rien.

Pire, elles n'ont presque aucune cible : **zéro** ancrage pour Arc Step dans
tout le monde jouable, deux ports pour Arc Link, une seule cible de Polarité
réellement utilisable. Et **aucune** dans le donjon ni chez le boss : le jeu
se termine sans en utiliser une seule.

---

## Ce qui est corrigé dans cette passe

| Correction | Fichier |
|---|---|
| Champ de vision ramené de 102° à 71° horizontal | `resources/tuning/locomotion_*` |
| `keep_aspect` posé explicitement, plus jamais implicite | `scripts/player/camera_rig.gd` |
| Test du FOV converti puis jugé sur l'angle réellement vu | `tests/integration/test_camera_rig.gd` |
| Sensibilité souris par défaut divisée par ~2 | `scripts/core/user_settings.gd` |
| Contrôle aérien rendu à sa valeur de spec (le facteur était appliqué deux fois) | `scripts/player/player_controller.gd` |
| Horizon : la face triangulaire des 242 pics regarde enfin la vallée | `scripts/world/valley_terrain.gd` |
| Nuage d'orage rendu éclairé au lieu d'un aplat noir | `scripts/world/storm_cell.gd` |
| Bouton « Commandes » en pause, et les touches du Bracelet y figurent | `scripts/ui/gameplay_shell.gd`, `options_panel.gd` |
| Échap ferme la cuisine et les commandes (c'étaient des culs-de-sac) | `scripts/ui/gameplay_shell.gd` |
| Aperçu de cuisine : effet, durée, et noms lisibles au lieu d'identifiants | `scripts/ui/gameplay_shell.gd` |
| Réserve de plats affichée au HUD avec sa touche | `scripts/ui/gameplay_shell.gd` |
| Inventaire navigable au clavier et à la manette | `scripts/ui/gameplay_shell.gd` |
| Avertissement d'usure d'arme enfin branché (§11.2) | `scripts/player/player_controller.gd` |
| Découverte d'un lieu annoncée à l'écran | `scripts/world/valley_world.gd` |
| Modèles gardés en mémoire au lieu d'être relus du disque | `scripts/core/asset_registry.gd` |
| Volumes audio restaurés au lancement | `scripts/core/audio_manager.gd` |
| Texte du jeu porté à 24 px et interface mise à l'échelle | `project.godot` |
| **La sauvegarde écrit le dernier SOL foulé** — on ne peut plus recharger dans un trou | `scripts/player/player_controller.gd`, `scripts/world/valley_world.gd` |
| On ne s'accroche plus à une paroi en courant ; seuil d'intention 0,22 → 0,40 s | `scripts/player/player_controller.gd`, `resources/tuning/climb_tuning.gd` |
| Le checkpoint de l'antichambre se réécrit à l'ouverture du coffre | `scripts/dungeon/antechamber.gd` |
| Mourir dans une salle du donjon y renvoie, au lieu de rejeter dans la vallée | 6 scènes de `scenes/dungeon/rooms/` |
| Le Colosse et le Chasseur retrouvent télégraphe, flash et mort visible | `scripts/enemies/enemy_base.gd` |
| Le flash de dégât se peint sur le modèle VISIBLE du héros | `scripts/player/player_controller.gd` |
| **Secousse de caméra** — le jeu n'en avait aucune ; angulaire, additive, réglable | `scripts/player/camera_rig.gd` |
| Un coup pendant la grâce anti-stunlock n'est plus muet | `scripts/player/player_controller.gd` |
| Quatre adversaires posés sur la route, et les neuf font une ronde | `scripts/world/valley_world.gd` |

## Ce qui reste, par ordre de gravité

1. **L'inventaire à travers les scènes** et le checkpoint de l'antichambre —
   c'est ce qui rend la fin de partie probablement infaisable.
2. **Le son** — deux fonctions à écrire, puis 40 points d'appel déjà
   identifiés.
3. **Le retour de coup** — matériaux des créatures, flash sur le bon
   maillage, secousse de caméra, VFX au point de contact.
4. **Des adversaires sur la route**, et des ennemis qui bougent.
5. **Mourir dans le donjon ramène dans la vallée** — sept lignes à ajouter.
6. **Les cibles du Bracelet**, et au moins un verrou qui l'exige.
7. **Les chemins enterrés**, et un repère d'orientation.
8. **Le découpage du chargement**, après mesure.

---

## Ce que cet audit ne prouve pas

Aucune de ces observations n'est une mesure de performance : ce conteneur n'a
pas de GPU. Aucun jugement de « ça fait quoi manette en main » n'est possible
ici non plus. Les onze auditeurs ont lu le code ; le douzième a joué, à
l'image seule, en rendu logiciel. Tout ce qui dépend d'un écran, d'un clavier
physique ou d'une carte graphique reste `À VÉRIFIER` sur un vrai poste.
