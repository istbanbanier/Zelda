## Sélecteur d'essai d'ambiance — ISS-087, D-066.
##
## LE SEUL point que le lead fait varier entre les quatre builds de l'essai
## d'écoute (`docs/audio/PROTOCOLE_ECOUTE.md`). Aucun autre fichier ne change
## d'un build à l'autre : la comparaison porte sur la variante, pas sur le code.
##
## Valeurs légales :
##   &"D"  — témoin MUET : aucune ambiance ne démarre (comportement historique,
##           valeur committée par défaut) ;
##   &"P1" — lit unique de 30 s (`amb_p1_lit`) ;
##   &"P2" — deux lits de 15 s commutés par région (`amb_p2_ouvert` /
##           `amb_p2_ferme`, lecteur `scripts/audio/lecteur_zones_p2.gd`) ;
##   &"P3" — lit de 20 s (`amb_p3_lit`) + événements rares (`amb_evt_1..4`)
##           toutes les 20 à 45 s.
##
## SANS `class_name`, à dessein : chaque `class_name` s'épingle au cache moteur
## et fait dériver le contrat de résidu. Chargé par `preload()` depuis
## `scripts/ui/gameplay_shell.gd`.
extends RefCounted

const VARIANTE: StringName = &"D"
