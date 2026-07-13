# Storage & Firestore Security (Pièces jointes)

## Chemins Firebase Storage

- Photo: `attachments/{formType}/{formId}/photos/{fileName}`
- Audio: `attachments/{formType}/{formId}/audio/{fileName}`
- `formType` autorisés: `terrain`, `lab`

## Collections Firestore

- Formulaires:
  - `terrain_forms/{formId}`
  - `lab_forms/{formId}`
- Métadonnées globales pièces jointes:
  - `attachments_files/{attachmentId}`
- Métadonnées par formulaire:
  - `terrain_forms/{formId}/attachments/{attachmentId}`
  - `lab_forms/{formId}/attachments/{attachmentId}`

## Politique d'accès

- Utilisateur non authentifié: aucun accès.
- Chercheur:
  - accès uniquement aux formulaires dont `ownerId == request.auth.uid`
  - accès uniquement aux pièces jointes liées à ses formulaires
  - accès uniquement aux docs `attachments_files` où `ownerId == request.auth.uid`
- Admin (`users/{uid}.role == "admin"`):
  - accès total lecture/écriture/suppression

## Validation Storage

- Photos autorisées: `image/jpeg`, `image/png`
- Audio autorisés: `audio/m4a`, `audio/mp4`, `audio/aac`, `audio/mpeg`
- Taille max:
  - photo: 10 MB
  - audio: 25 MB

## Tests recommandés

1. Connexion chercheur A:
   - upload photo/audio sur son formulaire => OK
   - lecture/suppression de ses fichiers => OK
2. Connexion chercheur B:
   - accès aux fichiers de A => refusé
3. Connexion admin:
   - lecture/suppression de tous les fichiers => OK
4. Vérifier en console Firebase:
   - objet présent dans Storage au bon chemin
   - doc présent dans Firestore sous `.../attachments/...`

## Déploiement des règles

- Firestore: `firebase deploy --only firestore:rules --project <projectId>`
- Storage: `firebase deploy --only storage --project <projectId>`
