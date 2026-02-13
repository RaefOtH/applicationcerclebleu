
# Firebase Admin init + Firestore deploy

## 1) Pré-requis
- Avoir un projet Firebase (Firestore activé).
- Télécharger un **Service Account** JSON depuis Firebase Console:
  Project Settings → Service accounts → Generate new private key.

## 2) Où placer le service account
Place le fichier ici:
```
scripts/serviceAccountKey.json
```

Ajoute ce fichier au `.gitignore` (si pas déjà fait):
```
serviceAccountKey.json
scripts/serviceAccountKey.json
```

## 3) Installer Firebase Admin SDK
Depuis la racine du projet:
```
npm init -y
npm install firebase-admin
```

## 4) Lancer le seed Firestore
```
node scripts/seed_firestore.js
```

## 5) Initialiser Firestore via Firebase CLI
```
firebase login
firebase init firestore
```
- Choisis ton projet.
- Utilise les fichiers:
  - `firestore.rules`
  - `firestore.indexes.json`

## 6) Déployer règles + indexes
```
firebase deploy --only firestore
```

## 7) Vérifier
- Firebase Console → Firestore → Data
- Tu dois voir users, surveys et leurs sous-collections.
