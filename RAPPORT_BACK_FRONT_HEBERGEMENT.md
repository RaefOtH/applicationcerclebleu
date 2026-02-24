# Rapport Resume - Application Cercle Bleu (Front / Back / Hebergement)

Date: 23/02/2026

## 1) Vue d'ensemble
- Type d'application: Flutter multi-plateforme (Android, iOS, Web/Desktop possibles).
- Frontend: interface Flutter (ecrans login, dashboards admin/chercheur, saisie formulaires Terrain/Labo/LEK).
- Backend: backend managé Firebase (pas de serveur API custom dans le repo).
- Base de donnees: Cloud Firestore (`databaseId: default`) avec controle d'acces via regles Firestore.
- Authentification: Firebase Authentication (email/mot de passe).
- Exports: CSV/PDF generes cote application, sauvegarde locale/appareil.

## 2) Architecture Frontend
- Entree app: `lib/main.dart` (initialise Firebase puis lance `SplashScreen`).
- Routage: `lib/routes/app_routes.dart`.
- Controle d'acces: `lib/auth/auth_gate.dart` redirige vers:
  - `AdminDashboard` si role = `admin`
  - `ChercheurDashboard` si role = `chercheur`
- Ecrans principaux:
  - Auth: `lib/screens/login_screen.dart`, `lib/screens/register_screen.dart`
  - Admin: `lib/screens/admin/admin_dashboard.dart`
  - Chercheur: `lib/screens/chercheur/chercheur_dashboard.dart`
  - Gestion enquetes admin: `lib/screens/admin/admin_surveys_screen.dart`
  - Gestion chercheurs admin: `lib/screens/admin/admin_researchers_screen.dart`
  - Template PDF admin: `lib/screens/admin/admin_pdf_template_screen.dart`

## 3) Architecture Backend (Firebase)
- Firestore access centralise: `lib/services/firestore_db.dart`
- Auth service: `lib/services/auth_service.dart`
- Profil utilisateur: `lib/services/user_service.dart`
- Services formulaires:
  - Terrain: `lib/services/terrain_form_service.dart`
  - Labo: `lib/services/lab_form_service.dart`
  - LEK: `lib/services/lek_form_service.dart`
- Statistiques dashboard: `lib/services/stats_service.dart`
- Export CSV/PDF: `lib/services/csv_export_service.dart`, `lib/services/export_service.dart`

## 4) Modele de donnees Firestore
Collections principales:
- `users`
- `terrain_forms`
- `lab_forms`
- `lek_forms`
- `app_settings` (doc `pdf_template`)
- `debug_tests` (tests techniques)

Autres structures de regles presentes:
- `surveys` avec sous-collections `responses`, `lab_data`, `lek_responses`, `comments`, `status_history`

Indexes declares: `firestore.indexes.json` (surveys, lab_forms, terrain_forms).

## 5) Securite et controle d'acces
- Regles Firestore dans `firestore.rules`:
  - Role-based access (`admin`, `chercheur`)
  - Restriction de lecture/ecriture selon proprietaire (`ownerId`) et role
- Garde admin UI: `lib/screens/admin/widgets/admin_role_guard.dart`

Points sensibles a corriger avant production:
- PIN admin statique `0000` dans:
  - `lib/screens/register_screen.dart`
  - `lib/auth/auth_gate.dart`
- Android release signe avec cle debug (`android/app/build.gradle.kts`), non conforme production.
- `applicationId` encore en `com.example.applicationstagepfe` (a personnaliser).

## 6) Dependances techniques
- Flutter SDK Dart: `^3.10.0` (`pubspec.yaml`)
- Firebase Flutter:
  - `firebase_core`
  - `firebase_auth`
  - `cloud_firestore`
- Export/stockage:
  - `pdf`, `printing`, `share_plus`
  - `permission_handler`, `media_store_plus`, `path_provider`
- Script seed Firestore (Node.js):
  - `scripts/seed_firestore.js`
  - `firebase-admin` via `package.json`

## 7) Etat configuration plateforme
- Android:
  - Firebase configure via `android/app/google-services.json`
  - Plugin Google services actif dans `android/app/build.gradle.kts`
- iOS:
  - `GoogleService-Info.plist` non present dans le repo (a ajouter pour build iOS avec Firebase)
- Web:
  - Pas de `firebase_options.dart` ni config web explicite dans `lib/main.dart`
  - A valider si hebergement web est scope (sinon mobile-only)

## 8) Hebergement / Deploiement recommande

### Option A - Mobile only (recommande si usage terrain)
- Backend: Firebase Auth + Firestore (deja en place)
- Distribution Android:
  - Corriger signature release
  - Generer AAB/APK release
  - Publier via canal interne / Play Console
- Distribution iOS:
  - Ajouter config Firebase iOS
  - Build IPA + distribution TestFlight/App Store

### Option B - Ajouter Web
- Build Flutter web (`flutter build web`)
- Heberger sur Firebase Hosting ou autre hebergeur statique
- Verifier la configuration Firebase Web avant ouverture (init Firebase web)

## 9) Operations et exploitation
- Seed donnees: `npm run seed:firestore` (necessite `scripts/serviceAccountKey.json`)
- Deploiement regles/index Firestore:
  - `firebase deploy --only firestore`
- Monitoring recommande:
  - Firebase Auth logs
  - Firestore usage / quotas / latence / erreurs permissions

## 10) Qualite et tests
- Test auto actuel: uniquement template Flutter (`test/widget_test.dart`), non aligne avec l'app reelle.
- Pas de suite de tests metier backend/front robuste dans le repo.
- Recommande avant mise en production:
  - tests de flux auth + role
  - tests CRUD formulaires
  - tests export CSV/PDF
  - tests de regles Firestore (emulator)

## 11) Checklist pre-hebergement (courte)
- [ ] Remplacer PIN admin hardcode et definir vrai processus d'attribution role admin.
- [ ] Configurer signature Android release.
- [ ] Definir `applicationId` final.
- [ ] Ajouter config Firebase iOS (`GoogleService-Info.plist`) si iOS cible.
- [ ] Valider besoin Web et config Firebase Web si hebergement web.
- [ ] Deployer `firestore.rules` + `firestore.indexes.json`.
- [ ] Verifier comptes, roles et permissions sur donnees de preproduction.
- [ ] Mettre en place sauvegarde/export operationnel + procedure incident.

## 12) Conclusion
L'application est principalement une app Flutter connectee a Firebase, sans backend serveur custom. Elle est deja exploitable pour un hebergement mobile avec peu d'infrastructure, mais necessite quelques corrections de securite et de release engineering avant une mise en production formelle.
