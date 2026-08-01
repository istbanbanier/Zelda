# RAPPORT DE VALIDATION MANUELLE — Gate A

Procédure : `docs/MANUAL_GATE_A.md`.

- **Opérateur** : propriétaire du projet
- **Date** : 2026-08-01
- **Commit testé** : `5085127` (paquet `EclatsDOrage_GateA_5085127.zip`)
- **Machine** : Mac (modèle non consigné)
- **Disposition clavier système** : AZERTY

> ## Nature de ce rapport — à lire avant de s'y fier
>
> Les résultats ci-dessous sont **déclarés par l'opérateur en conversation**, sans
> capture d'écran ni journal archivé. Ils valent comme témoignage, pas comme preuve
> au sens de §0.7, qui exige un artefact reproductible.
>
> `tools/manual_validation_kit.sh --finalize` sort donc toujours en **3 (BLOQUÉ)** :
> aucun fichier de preuve n'est présent. C'est cohérent et voulu — le manifeste ne
> doit pas certifier ce qu'il n'a pas vu.

---

## Étape 4.1 — Lancement Boot → MainMenu
- Observé : le menu s'affiche, tous les boutons sont cliquables, **aucun message
  d'erreur**.
- Réserve levée : l'opérateur se demandait si « le jeu se lance » — à la Phase A le
  menu **est** l'aboutissement attendu, aucun monde n'existe derrière. Le document
  a été corrigé pour le dire explicitement.
- **Verdict** : PASS *(déclaré, sans capture archivée)*

## Étape 4.2 — Clavier AZERTY, `Q` = gauche
- Déclaré vérifié via `InputAudit`.
- **Verdict** : PASS *(déclaré, sans capture archivée)*
- Non consigné faute de capture : le libellé exact du bandeau de disposition, et
  l'état final du verdict verrouillé « Q n'active jamais lock_on ».

## Étape 4.3 — Manette
- **Aucune manette disponible.**
- **Verdict** : **NON VÉRIFIÉ**
- §23.1 exige « clavier AZERTY **et** manette fonctionnels ». Ce critère ne peut
  pas être déduit du clavier : les liaisons manette sont des événements distincts
  (`InputEventJoypadButton`, `InputEventJoypadMotion`) et le mapping dépend de la
  base SDL du modèle branché. Les tests automatiques vérifient que chaque action
  **possède** une liaison manette ; ils ne peuvent pas presser un bouton.

## Étapes 4.4 à 4.8 — Navigation, focus, boutons désactivés, confirmation, lisibilité
- Déclaré vérifié : navigation du menu conforme, aucun message d'erreur.
- **Verdict** : PASS *(déclaré, sans capture archivée)*
- Non consigné faute de détail : tenue au redimensionnement, et jugement de
  lisibilité — y compris ce qui paraît austère, qui aurait sa place ici.

## Étape 5 — Reprise dans une session neuve
- **Non réalisée.**
- **Verdict** : **NON VÉRIFIÉ**
- C'est la réserve principale du Gate 0 (D-006) : le critère « une session neuve
  reprend en moins de 5 minutes » n'a jamais été mesuré, seulement estimé par
  relecture.

## Étape 6 — Archivage des preuves
- Aucun fichier déposé dans `evidence/gateA/`.
- **Verdict** : **NON VÉRIFIÉ**

---

## Verdict global du Gate A

Le plus faible des étapes, jamais la moyenne (§0.7).

**GATE A : `EN ATTENTE`** — ni `PASS`, ni `FAIL`.

Quatre étapes sur six sont rapportées conformes, ce qui est un bon signal : rien
de ce qui a été essayé n'a échoué. Mais deux critères restent `NON VÉRIFIÉ`, dont
un — la manette — est explicitement exigé par §23.1.

### Ce qui manque pour conclure

1. **Manette** (§4.3) : brancher n'importe quelle manette reconnue par macOS.
2. **Reprise en session neuve** (§5) : ~5 minutes chronométrées.
3. *(souhaitable)* Quelques captures, pour que ces résultats deviennent des
   preuves plutôt que des témoignages.
