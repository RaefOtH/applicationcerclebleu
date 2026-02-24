# Firestore Seed (Cercle Bleu)

Ce script insere 2 documents complets:
- `terrain_forms` (1 document)
- `lab_forms` (1 document)

## Prerequis
- Le fichier `scripts/serviceAccountKey.json` doit exister.
- Firestore `(default)` doit etre cree dans le projet `cercle-bleu-enquetes`.

## Installation
Depuis la racine du projet:

```bash
npm install
```

## Execution

```bash
node scripts/seed_firestore.js
```

ou

```bash
npm run seed:firestore
```

## Logs attendus
- `OK terrain_forms cree: <docId>`
- `OK lab_forms cree: <docId>`
- `OK verification lecture: terrain=true lab=true`

En cas d'erreur:
- le script affiche `code` + `message`
- pour `NOT_FOUND`, il affiche: `Cree Firestore (default) dans Firebase Console`
- code de sortie non zero
