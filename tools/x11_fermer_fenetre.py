#!/usr/bin/env python3
"""Envoie le VRAI événement de la croix — WM_DELETE_WINDOW — à une fenêtre X.

POURQUOI CE FICHIER EXISTE. Sous un Xvfb nu, il n'y a AUCUN gestionnaire de
fenêtres : `wmctrl -c` (qui parle au WM par _NET_CLOSE_WINDOW) ne trouve
personne pour agir, et `xdotool windowclose` DÉTRUIT la fenêtre par
XDestroyWindow — le client ne reçoit jamais la demande de fermeture, Godot ne
voit aucun NOTIFICATION_WM_CLOSE_REQUEST, et le portail T1 a mesuré le
résultat : processus vivant, aucune sauvegarde de fermeture. Le seul geste
fidèle à la croix est le ClientMessage WM_PROTOCOLS/WM_DELETE_WINDOW envoyé
directement au client — c'est ce que fait un WM réel, et c'est ce que fait ce
script.

Usage : DISPLAY=:NN python3 tools/x11_fermer_fenetre.py <id_fenetre_decimal>
Code retour : 0 = message envoyé ; 2 = argument/erreur X.
"""
import sys

from Xlib import display, protocol


def main() -> int:
    if len(sys.argv) != 2:
        print("usage : x11_fermer_fenetre.py <id_fenetre_decimal>", file=sys.stderr)
        return 2
    try:
        wid = int(sys.argv[1], 0)
    except ValueError:
        print("id de fenêtre illisible : %r" % sys.argv[1], file=sys.stderr)
        return 2
    d = display.Display()
    try:
        fenetre = d.create_resource_object("window", wid)
        wm_protocols = d.intern_atom("WM_PROTOCOLS")
        wm_delete = d.intern_atom("WM_DELETE_WINDOW")
        evenement = protocol.event.ClientMessage(
            window=fenetre, client_type=wm_protocols,
            data=(32, [wm_delete, 0, 0, 0, 0]))
        fenetre.send_event(evenement, event_mask=0)
        d.flush()
        print("WM_DELETE_WINDOW envoyé à %d" % wid)
        return 0
    except Exception as e:  # erreur X : fenêtre morte, display absent…
        print("échec d'envoi : %s" % e, file=sys.stderr)
        return 2
    finally:
        d.close()


if __name__ == "__main__":
    sys.exit(main())
