# Cercle Bleu

## Rapport d'analyse complet de l'application

Ce document est une analyse complète de l'application telle qu'elle existe dans le code du projet.

Il est basé uniquement sur les fichiers présents dans le dépôt, sans supposer de fonctionnalités non implémentées.

---

## A. Résumé exécutif

`Cercle Bleu` est une application Flutter connectée à Firebase pour la collecte, la consultation, l'export et la supervision de données scientifiques liées au crabe bleu.

L'application couvre deux chaînes métier principales :
- la saisie terrain
- la saisie laboratoire

Elle distingue deux rôles utilisateurs réels :
- `admin`
- `chercheur`

Le backend n'est pas un serveur HTTP classique. Il repose directement sur :
- `Firebase Authentication`
- `Cloud Firestore`
- `Firebase Storage`

Les exports sont générés côté application en :
- `CSV`
- `PDF`

Preuves principales :
- [lib/main.dart](lib/main.dart)
- [lib/auth/auth_gate.dart](lib/auth/auth_gate.dart)
- [pubspec.yaml](pubspec.yaml)
- [firebase.json](firebase.json)

---

## 1. Vue générale de l'application

### 1.1 But principal

L'application sert à :
- créer des formulaires terrain
- créer des formulaires laboratoire
- sauvegarder les données dans Firestore
- ajouter des photos et audios liés aux formulaires
- exporter les données
- permettre à un administrateur de superviser chercheurs, formulaires, statistiques et pièces jointes

Sources :
- [lib/screens/chercheur/chercheur_dashboard.dart](lib/screens/chercheur/chercheur_dashboard.dart)
- [lib/screens/admin/admin_dashboard.dart](lib/screens/admin/admin_dashboard.dart)
- [docs/pfe_analyse_conception_cercle_bleu.txt](docs/pfe_analyse_conception_cercle_bleu.txt)

### 1.2 Type d'application

Type réel identifié dans le code :
- application Flutter
- usage mobile Android prioritaire
- support Web configuré
- support iOS, Windows, Linux, macOS présent dans le repo mais partiellement configuré côté Firebase

Sources :
- [pubspec.yaml](pubspec.yaml)
- [lib/firebase_options.dart](lib/firebase_options.dart)

### 1.3 Grandes parties du projet

Le projet est structuré en :
- authentification
- dashboards admin et chercheur
- module terrain
- module laboratoire
- module pièces jointes
- exports CSV/PDF
- règles Firestore/Storage
- scripts de seed Firestore

Sources :
- [lib/services](lib/services)
- [lib/screens](lib/screens)
- [firestore.rules](firestore.rules)
- [storage.rules](storage.rules)
- [scripts/seed_firestore.js](scripts/seed_firestore.js)

### 1.4 Architecture globale

#### Frontend

Application Flutter avec navigation mixte :
- routes nommées pour auth, login, register, profile
- `MaterialPageRoute` pour la plupart des écrans métier

Source :
- [lib/routes/app_routes.dart](lib/routes/app_routes.dart)

#### Authentification

Basée sur `FirebaseAuth`.

Source :
- [lib/services/auth_service.dart](lib/services/auth_service.dart)

#### Base de données

Basée sur `Cloud Firestore`, base `default`.

Collections réellement utilisées :
- `users`
- `terrain_forms`
- `lab_forms`
- `attachments_files`
- `app_settings`
- `debug_tests`

Source :
- [lib/services/firestore_db.dart](lib/services/firestore_db.dart)
- [lib/services/user_service.dart](lib/services/user_service.dart)
- [lib/services/terrain_form_service.dart](lib/services/terrain_form_service.dart)
- [lib/services/lab_form_service.dart](lib/services/lab_form_service.dart)
- [lib/services/attachment_service.dart](lib/services/attachment_service.dart)
- [lib/services/export_service.dart](lib/services/export_service.dart)

#### Stockage fichiers

Basé sur `Firebase Storage` avec fallback partiel dans Firestore en cas d'échec upload.

Sources :
- [lib/services/attachment_service.dart](lib/services/attachment_service.dart)
- [storage.rules](storage.rules)

#### Services externes

Services utilisés :
- Firebase Auth
- Firestore
- Firebase Storage
- partage local de fichiers
- génération PDF
- sauvegarde locale sur appareil

Sources :
- [pubspec.yaml](pubspec.yaml)
- [lib/services/export_service.dart](lib/services/export_service.dart)
- [lib/services/csv_export_service.dart](lib/services/csv_export_service.dart)

---

## 2. Liste complète des rôles

### 2.1 Admin

Le rôle admin est reconnu par la valeur Firestore `role = "admin"`.

Sources :
- [lib/auth/auth_gate.dart](lib/auth/auth_gate.dart)
- [lib/screens/admin/widgets/admin_role_guard.dart](lib/screens/admin/widgets/admin_role_guard.dart)
- [firestore.rules](firestore.rules)

#### Permissions

- accéder au dashboard admin
- consulter toutes les statistiques
- consulter tous les chercheurs
- consulter les détails d'un chercheur
- consulter tous les formulaires terrain et labo
- supprimer des formulaires
- supprimer des chercheurs côté Firestore
- consulter et télécharger les pièces jointes globales
- supprimer des pièces jointes
- modifier le template PDF
- créer aussi des formulaires terrain et labo

#### Restrictions

- aucune restriction métier forte visible côté UI sur les formulaires
- suppression du compte Firebase Auth d'un chercheur non prise en charge depuis le client

Source :
- [lib/screens/admin/admin_dashboard.dart](lib/screens/admin/admin_dashboard.dart)
- [lib/screens/admin/admin_researchers_screen.dart](lib/screens/admin/admin_researchers_screen.dart)

#### Pages accessibles

- dashboard admin
- gestion des enquêtes
- gestion des chercheurs
- détails chercheur
- template PDF
- dossier photos et audio
- profil
- écrans terrain/labo de création

#### Différences avec chercheur

- accès global à toutes les données
- pas limité à `ownerId`
- accès au template PDF
- accès aux chercheurs
- accès au dossier global de médias

### 2.2 Chercheur

Le rôle chercheur est reconnu par `role = "chercheur"`.

Sources :
- [lib/auth/auth_gate.dart](lib/auth/auth_gate.dart)
- [firestore.rules](firestore.rules)

#### Permissions

- accéder au dashboard chercheur
- créer des formulaires terrain
- créer des formulaires labo
- modifier ses propres formulaires
- supprimer ses propres formulaires
- consulter ses formulaires récents
- exporter ses formulaires
- ajouter photo/audio
- supprimer ses propres pièces jointes
- consulter ses statistiques
- consulter son profil

#### Restrictions

- lecture limitée à ses propres `terrain_forms` et `lab_forms`
- lecture limitée aux pièces jointes liées à ses formulaires
- pas d'accès aux écrans admin

#### Pages accessibles

- dashboard chercheur
- profil
- entrée terrain
- liste terrain
- hub terrain et pages d'étapes
- entrée labo
- liste labo
- hub labo et pages d'étapes
- écrans de pièces jointes

---

## 3. Tableau des fonctionnalités Admin

| Fonctionnalité | Description | Écran | Données utilisées | Actions |
|---|---|---|---|---|
| Tableau de bord admin | Vue globale + KPIs + filtres | [lib/screens/admin/admin_dashboard.dart](lib/screens/admin/admin_dashboard.dart) | `terrain_forms`, `lab_forms`, `users` via `StatsService` | consulter, filtrer |
| Gestion des enquêtes | Liste globale terrain/labo | [lib/screens/admin/admin_surveys_screen.dart](lib/screens/admin/admin_surveys_screen.dart) | `terrain_forms`, `lab_forms`, `users` | consulter, filtrer, ouvrir, supprimer, exporter |
| Gestion des chercheurs | Liste des chercheurs | [lib/screens/admin/admin_researchers_screen.dart](lib/screens/admin/admin_researchers_screen.dart) | `users`, `terrain_forms`, `lab_forms`, `attachments_files` | consulter, filtrer, exporter CSV, supprimer |
| Détail chercheur | Vue détaillée d'un chercheur et de ses formulaires | [lib/screens/admin/researcher_details_screen.dart](lib/screens/admin/researcher_details_screen.dart) | `users`, `terrain_forms`, `lab_forms` | consulter, filtrer, ouvrir |
| Dossier photos/audio | Vue admin globale des médias | [lib/screens/admin/admin_attachments_screen.dart](lib/screens/admin/admin_attachments_screen.dart) | `attachments_files`, Storage | filtrer, télécharger, télécharger en masse, supprimer, prévisualiser |
| Template PDF | Paramétrage du rendu PDF | [lib/screens/admin/admin_pdf_template_screen.dart](lib/screens/admin/admin_pdf_template_screen.dart) | `app_settings/pdf_template` | consulter, modifier, prévisualiser, enregistrer |

---

## 4. Tableau des fonctionnalités Chercheur

| Fonctionnalité | Description | Écran | Données utilisées | Actions |
|---|---|---|---|---|
| Connexion | Authentification email/mot de passe | [lib/screens/login_screen.dart](lib/screens/login_screen.dart) | Firebase Auth | se connecter |
| Inscription | Création compte et profil Firestore | [lib/screens/register_screen.dart](lib/screens/register_screen.dart) | Firebase Auth + `users` | créer compte |
| Dashboard chercheur | Accès principal, stats et raccourcis | [lib/screens/chercheur/chercheur_dashboard.dart](lib/screens/chercheur/chercheur_dashboard.dart) | `terrain_forms`, `lab_forms` via `StatsService` | consulter, filtrer, naviguer |
| Nouveau formulaire terrain | Création d'un brouillon terrain | [lib/screens/terrain/terrain_entry_choice_screen.dart](lib/screens/terrain/terrain_entry_choice_screen.dart) | `terrain_forms` | créer |
| Liste terrain | Consultation des formulaires terrain | [lib/screens/terrain/terrain_forms_list_screen.dart](lib/screens/terrain/terrain_forms_list_screen.dart) | `terrain_forms` | consulter, filtrer, ouvrir, supprimer, exporter |
| Nouveau formulaire labo | Création d'un brouillon labo | [lib/screens/labo/lab_entry_choice_screen.dart](lib/screens/labo/lab_entry_choice_screen.dart) | `lab_forms` | créer |
| Liste labo | Consultation des formulaires labo | [lib/screens/labo/lab_forms_list_screen.dart](lib/screens/labo/lab_forms_list_screen.dart) | `lab_forms` | consulter, filtrer, ouvrir, supprimer, exporter |
| Pièces jointes | Ajout photo/audio sur formulaire | [lib/screens/common/attachments_screen.dart](lib/screens/common/attachments_screen.dart) | sous-collection `attachments`, `attachments_files`, Storage | ajouter, lire, télécharger, supprimer |
| Profil | Vue profil utilisateur | [lib/screens/profile_screen.dart](lib/screens/profile_screen.dart) | `users` | consulter, se déconnecter |

---

## 5. Analyse complète des enquêtes

### 5.1 Types réels d'enquêtes

Le code ne manipule pas une collection métier unique `surveys` pour l'application courante.

Les objets métier réels sont :
- `terrain_forms`
- `lab_forms`

Sources :
- [lib/services/terrain_form_service.dart](lib/services/terrain_form_service.dart)
- [lib/services/lab_form_service.dart](lib/services/lab_form_service.dart)

### 5.2 Création d'une enquête terrain

Création via :
- [lib/screens/terrain/terrain_entry_choice_screen.dart](lib/screens/terrain/terrain_entry_choice_screen.dart)
- méthode `createNewForm()` de [lib/services/terrain_form_service.dart](lib/services/terrain_form_service.dart)

Payload créé :
- `ownerId`
- `ownerName`
- `role`
- `roleCreateur`
- `type = terrain`
- `title`
- `status = brouillon`
- `stepCompleted = 0`
- `data = {}`
- `createdAt`
- `updatedAt`
- `lastEditedAt`

### 5.3 Création d'une enquête labo

Création via :
- [lib/screens/labo/lab_entry_choice_screen.dart](lib/screens/labo/lab_entry_choice_screen.dart)
- méthode `createNewForm()` de [lib/services/lab_form_service.dart](lib/services/lab_form_service.dart)

Payload créé :
- `ownerId`
- `ownerName`
- `role`
- `roleCreateur`
- `type = lab`
- `title`
- `location`
- `status = brouillon`
- `stepCompleted = 0`
- `data = {}`
- `createdAt`
- `updatedAt`
- `lastEditedAt`

### 5.4 Statuts existants

Statuts réellement vus dans le code :
- `brouillon`
- `soumis`

Statuts non trouvés dans les flux actifs :
- `publiee`
- `terminee`
- `archivee`

Sources :
- [lib/services/terrain_form_service.dart](lib/services/terrain_form_service.dart)
- [lib/services/lab_form_service.dart](lib/services/lab_form_service.dart)

### 5.5 Gestion des questions / sections

Il n'existe pas de moteur générique de questionnaire dynamique.

Les formulaires sont codés en dur par écran.

#### Terrain

Étapes :
1. informations générales
2. suivi
3. capture
4. variables environnementales
5. remarques

Sources :
- [lib/screens/terrain/informations_generales_page.dart](lib/screens/terrain/informations_generales_page.dart)
- [lib/screens/terrain/suivi_page.dart](lib/screens/terrain/suivi_page.dart)
- [lib/screens/terrain/capture_page.dart](lib/screens/terrain/capture_page.dart)
- [lib/screens/terrain/variables_environnementales_page.dart](lib/screens/terrain/variables_environnementales_page.dart)
- [lib/screens/terrain/remarques_page.dart](lib/screens/terrain/remarques_page.dart)

#### Labo

Étapes :
1. analyse laboratoire
2. analyse crabe bleu
3. épibiontes
4. remarques

Sources :
- [lib/screens/labo/analyse_laboratoire_page1.dart](lib/screens/labo/analyse_laboratoire_page1.dart)
- [lib/screens/labo/analyse_crabe_bleu_page2.dart](lib/screens/labo/analyse_crabe_bleu_page2.dart)
- [lib/screens/labo/epibionts_page3.dart](lib/screens/labo/epibionts_page3.dart)
- [lib/screens/labo/remarques_page4.dart](lib/screens/labo/remarques_page4.dart)

### 5.6 Types de questions

Types de saisie trouvés :
- texte libre
- numérique
- choix via dropdown
- choix conditionnel `Autre`
- booléen via checkbox
- date
- heure
- sélection d'identifiant d'observation

### 5.7 Sauvegarde des réponses

La sauvegarde fonctionne ainsi :
- autosave différé avec `scheduleFullDataSave`
- sauvegarde complète via `updateFormData`
- progression mémorisée avec `stepCompleted`

Sources :
- [lib/services/terrain_form_service.dart](lib/services/terrain_form_service.dart)
- [lib/services/lab_form_service.dart](lib/services/lab_form_service.dart)

### 5.8 Qui peut répondre

Dans le modèle actuel :
- un admin peut créer et modifier des formulaires
- un chercheur peut créer et modifier ses formulaires

Il n'existe pas de rôle “répondant externe”.

### 5.9 Qui peut voir les résultats

- chercheur : ses propres formulaires
- admin : tous les formulaires

Source :
- [firestore.rules](firestore.rules)

### 5.10 Calcul des statistiques

Les statistiques sont calculées côté client par `StatsService`.

Mesures calculées :
- nombre total formulaires terrain
- nombre total formulaires labo
- nombre de ports uniques
- total de crabes via `cap_abondance`
- top 5 ports
- top 5 espèces

Source :
- [lib/services/stats_service.dart](lib/services/stats_service.dart)

### 5.11 Règles métier notables

- un formulaire possède un `ownerId`
- les formulaires sont sauvegardés en brouillon dès leur création
- l'ID observation terrain est auto-généré à partir de plusieurs champs
- certains champs deviennent obligatoires si `Autre` est sélectionné
- le labo dépend d'un `idObservation` venant du terrain
- les pièces jointes doivent référencer `formId` et `formType`

Sources :
- [lib/screens/terrain/informations_generales_page.dart](lib/screens/terrain/informations_generales_page.dart)
- [lib/screens/terrain/suivi_page.dart](lib/screens/terrain/suivi_page.dart)
- [lib/screens/terrain/capture_page.dart](lib/screens/terrain/capture_page.dart)
- [lib/screens/terrain/variables_environnementales_page.dart](lib/screens/terrain/variables_environnementales_page.dart)
- [lib/services/attachment_service.dart](lib/services/attachment_service.dart)

---

## 6. Tableau des pages et routes

### 6.1 Routes nommées

| Route | Écran réel |
|---|---|
| `/auth` | `AuthGate` |
| `/login` | `LoginScreen` |
| `/register` | `RegisterScreen` |
| `/home` | `AuthGate` |
| `/dashboard` | `DashboardScreen` legacy |
| `/admin-dashboard` | `AuthGate` |
| `/chercheur-dashboard` | `AuthGate` |
| `/profile` | `ProfileScreen` |

Source :
- [lib/routes/app_routes.dart](lib/routes/app_routes.dart)

### 6.2 Pages métier principales

#### Authentification
- [lib/screens/splash_screen.dart](lib/screens/splash_screen.dart)
- [lib/screens/login_screen.dart](lib/screens/login_screen.dart)
- [lib/screens/register_screen.dart](lib/screens/register_screen.dart)
- [lib/auth/auth_gate.dart](lib/auth/auth_gate.dart)

#### Admin
- [lib/screens/admin/admin_dashboard.dart](lib/screens/admin/admin_dashboard.dart)
- [lib/screens/admin/admin_surveys_screen.dart](lib/screens/admin/admin_surveys_screen.dart)
- [lib/screens/admin/admin_researchers_screen.dart](lib/screens/admin/admin_researchers_screen.dart)
- [lib/screens/admin/researcher_details_screen.dart](lib/screens/admin/researcher_details_screen.dart)
- [lib/screens/admin/admin_attachments_screen.dart](lib/screens/admin/admin_attachments_screen.dart)
- [lib/screens/admin/admin_pdf_template_screen.dart](lib/screens/admin/admin_pdf_template_screen.dart)

#### Chercheur
- [lib/screens/chercheur/chercheur_dashboard.dart](lib/screens/chercheur/chercheur_dashboard.dart)
- [lib/screens/profile_screen.dart](lib/screens/profile_screen.dart)

#### Terrain
- [lib/screens/terrain/terrain_entry_choice_screen.dart](lib/screens/terrain/terrain_entry_choice_screen.dart)
- [lib/screens/terrain/terrain_forms_list_screen.dart](lib/screens/terrain/terrain_forms_list_screen.dart)
- [lib/screens/terrain/matrice1_home.dart](lib/screens/terrain/matrice1_home.dart)
- [lib/screens/terrain/informations_generales_page.dart](lib/screens/terrain/informations_generales_page.dart)
- [lib/screens/terrain/suivi_page.dart](lib/screens/terrain/suivi_page.dart)
- [lib/screens/terrain/capture_page.dart](lib/screens/terrain/capture_page.dart)
- [lib/screens/terrain/variables_environnementales_page.dart](lib/screens/terrain/variables_environnementales_page.dart)
- [lib/screens/terrain/remarques_page.dart](lib/screens/terrain/remarques_page.dart)
- [lib/screens/terrain/terrain_attachments_screen.dart](lib/screens/terrain/terrain_attachments_screen.dart)

#### Laboratoire
- [lib/screens/labo/lab_entry_choice_screen.dart](lib/screens/labo/lab_entry_choice_screen.dart)
- [lib/screens/labo/lab_forms_list_screen.dart](lib/screens/labo/lab_forms_list_screen.dart)
- [lib/screens/labo/donnees_laboratoire_home.dart](lib/screens/labo/donnees_laboratoire_home.dart)
- [lib/screens/labo/analyse_laboratoire_page1.dart](lib/screens/labo/analyse_laboratoire_page1.dart)
- [lib/screens/labo/analyse_crabe_bleu_page2.dart](lib/screens/labo/analyse_crabe_bleu_page2.dart)
- [lib/screens/labo/epibionts_page3.dart](lib/screens/labo/epibionts_page3.dart)
- [lib/screens/labo/remarques_page4.dart](lib/screens/labo/remarques_page4.dart)
- [lib/screens/labo/lab_attachments_screen.dart](lib/screens/labo/lab_attachments_screen.dart)

---

## 7. Analyse backend / API

### 7.1 Constats

Le projet n'expose pas d'API HTTP REST.

Le backend effectif est le SDK Firebase utilisé depuis le client Flutter.

### 7.2 Opérations principales

#### Auth

- `signIn(email, password)` : [lib/services/auth_service.dart](lib/services/auth_service.dart)
- `register(email, password)` : [lib/services/auth_service.dart](lib/services/auth_service.dart)
- `signOut()` : [lib/services/auth_service.dart](lib/services/auth_service.dart)

#### Firestore `users`

- création profil : `createUserProfile()`
- lecture profil : `getUserProfile()`
- stream profil : `watchUserProfile()`
- mise à jour `lastLoginAt`

Source :
- [lib/services/user_service.dart](lib/services/user_service.dart)

#### Firestore `terrain_forms`

- création brouillon
- watch d'un formulaire
- update complet
- watch des formulaires utilisateur
- suppression
- passage à `soumis` via `submitForm()` non utilisé

Source :
- [lib/services/terrain_form_service.dart](lib/services/terrain_form_service.dart)

#### Firestore `lab_forms`

Même logique que terrain.

Source :
- [lib/services/lab_form_service.dart](lib/services/lab_form_service.dart)

#### Firestore `attachments_files` et sous-collections `attachments`

- upload photo/audio
- watch des médias
- delete média
- lecture bytes fallback Firestore

Source :
- [lib/services/attachment_service.dart](lib/services/attachment_service.dart)

#### Export

- récupération bulk Firestore
- génération CSV
- génération PDF
- sauvegarde locale

Sources :
- [lib/services/export_service.dart](lib/services/export_service.dart)
- [lib/services/csv_export_service.dart](lib/services/csv_export_service.dart)

---

## 8. Tableau des tables / modèles / collections

### 8.1 `users`

Rôle :
- profils applicatifs
- rôle métier
- métadonnées de connexion

Champs visibles :
- `email`
- `fullName`
- `role`
- `createdAt`
- `updatedAt`
- `lastLoginAt`

Modèle :
- [lib/models/app_user.dart](lib/models/app_user.dart)

### 8.2 `terrain_forms`

Rôle :
- formulaires terrain

Champs racine :
- `ownerId`
- `ownerName`
- `role`
- `roleCreateur`
- `type`
- `title`
- `status`
- `stepCompleted`
- `data`
- `createdAt`
- `updatedAt`
- `lastEditedAt`
- `submittedAt` parfois

Source :
- [lib/services/terrain_form_service.dart](lib/services/terrain_form_service.dart)

### 8.3 `lab_forms`

Rôle :
- formulaires laboratoire

Champs racine :
- mêmes champs que `terrain_forms`
- plus `location` à la création

Source :
- [lib/services/lab_form_service.dart](lib/services/lab_form_service.dart)

### 8.4 Sous-collections `attachments`

Localisation :
- `terrain_forms/{formId}/attachments`
- `lab_forms/{formId}/attachments`

Rôle :
- liste locale des pièces jointes rattachées au formulaire

Source :
- [lib/services/attachment_service.dart](lib/services/attachment_service.dart)

### 8.5 `attachments_files`

Rôle :
- index global admin des pièces jointes
- fallback de stockage Firestore chunké

Champs visibles :
- `type`
- `fileName`
- `collection`
- `formId`
- `formType`
- `place`
- `ownerId`
- `storagePath`
- `downloadUrl`
- `contentType`
- `createdAt`
- `createdBy`
- `createdByName`
- `sizeBytes`
- parfois `chunksCount`

Source :
- [lib/services/attachment_service.dart](lib/services/attachment_service.dart)
- [lib/models/attachment_item.dart](lib/models/attachment_item.dart)

### 8.6 `attachments_files/{id}/chunks`

Rôle :
- stockage des fichiers découpés dans Firestore si l'upload Storage échoue

Source :
- [lib/services/attachment_service.dart](lib/services/attachment_service.dart)

### 8.7 `app_settings/pdf_template`

Rôle :
- paramètres du template PDF

Champs :
- `appName`
- `subtitle`
- `footer`
- `updatedAt`

Source :
- [lib/screens/admin/admin_pdf_template_screen.dart](lib/screens/admin/admin_pdf_template_screen.dart)

### 8.8 `debug_tests`

Rôle :
- test de connectivité Firestore

Source :
- [lib/services/firestore_test_service.dart](lib/services/firestore_test_service.dart)

---

## 9. Analyse authentification et sécurité

### 9.1 Connexion

La connexion utilise `FirebaseAuth.signInWithEmailAndPassword`.

Source :
- [lib/services/auth_service.dart](lib/services/auth_service.dart)

### 9.2 Inscription

L'inscription :
1. crée le compte Auth
2. crée le document `users/{uid}`
3. stocke `fullName`, `email`, `role`

Source :
- [lib/screens/register_screen.dart](lib/screens/register_screen.dart)

### 9.3 Sessions

La session est gérée par Firebase via `authStateChanges()`.

Source :
- [lib/auth/auth_gate.dart](lib/auth/auth_gate.dart)

### 9.4 Vérification des rôles

Le rôle est lu dans Firestore, pas dans des custom claims.

Source :
- [lib/auth/auth_gate.dart](lib/auth/auth_gate.dart)
- [lib/screens/admin/widgets/admin_role_guard.dart](lib/screens/admin/widgets/admin_role_guard.dart)

### 9.5 Routes protégées

Protection UI :
- `AuthGate`
- `AdminRoleGuard`

Protection data :
- `firestore.rules`
- `storage.rules`

### 9.6 Risques et failles

#### Problème critique 1

Le PIN admin `0000` est côté client.

Sources :
- [lib/screens/register_screen.dart](lib/screens/register_screen.dart)
- [lib/auth/auth_gate.dart](lib/auth/auth_gate.dart)

#### Problème critique 2

La règle `users/{uid}` autorise `create` si `isSelf(uid)`, sans bloquer explicitement un rôle admin demandé par le client.

Source :
- [firestore.rules](firestore.rules)

#### Problème important 3

Les formulaires sont finalisés côté UI sans appel réel à `submitForm()`.

Sources :
- [lib/services/terrain_form_service.dart](lib/services/terrain_form_service.dart)
- [lib/services/lab_form_service.dart](lib/services/lab_form_service.dart)
- [lib/screens/terrain/remarques_page.dart](lib/screens/terrain/remarques_page.dart)
- [lib/screens/labo/remarques_page4.dart](lib/screens/labo/remarques_page4.dart)

#### Problème important 4

La page labo charge tous les `terrain_forms` pour récupérer les IDs d'observation, ce qui peut entrer en conflit avec les règles d'accès par propriétaire.

Source :
- [lib/screens/labo/analyse_laboratoire_page1.dart](lib/screens/labo/analyse_laboratoire_page1.dart)
- [firestore.rules](firestore.rules)

### 9.7 Améliorations sécurité recommandées

- déplacer la gestion du rôle admin côté backend
- utiliser des custom claims ou une Cloud Function
- interdire la promotion admin depuis le client
- filtrer les requêtes labo par `ownerId` ou créer une collection dédiée d'observations partageables
- implémenter une vraie soumission finale
- ajouter suppression serveur cascade

---

## 10. Analyse des composants frontend

### Composants principaux réutilisés

#### `FormsFilterBar`

Rôle :
- barre de filtres générique pour listes de formulaires

Source :
- [lib/widgets/forms_filter_bar.dart](lib/widgets/forms_filter_bar.dart)

#### `AttachmentsScreen`

Rôle :
- composant principal de gestion photo/audio d'un formulaire

Source :
- [lib/screens/common/attachments_screen.dart](lib/screens/common/attachments_screen.dart)

#### `AdminRoleGuard`

Rôle :
- garde de sécurité UI pour pages admin

Source :
- [lib/screens/admin/widgets/admin_role_guard.dart](lib/screens/admin/widgets/admin_role_guard.dart)

#### `showModernLogoutDialog` / snackbar succès

Rôle :
- feedback UI transversal

Source :
- [lib/widgets/app_feedback.dart](lib/widgets/app_feedback.dart)

### Composants legacy / peu utiles

- [lib/widgets/custom_button.dart](lib/widgets/custom_button.dart)
- [lib/widgets/custom_textfield.dart](lib/widgets/custom_textfield.dart)
- [lib/widgets/big_action_card.dart](lib/widgets/big_action_card.dart)
- [lib/screens/home_screen.dart](lib/screens/home_screen.dart)
- [lib/screens/dashboard_screen.dart](lib/screens/dashboard_screen.dart)

Ils ne participent pas au flux principal actuel.

---

## 11. Flux métier détaillés

### 11.1 Connexion admin

1. l'utilisateur saisit email et mot de passe
2. Firebase Auth authentifie
3. `AuthGate` lit `users/{uid}`
4. si `role == admin`, redirection vers `AdminDashboard`

Sources :
- [lib/screens/login_screen.dart](lib/screens/login_screen.dart)
- [lib/auth/auth_gate.dart](lib/auth/auth_gate.dart)

### 11.2 Connexion chercheur

Même flux, avec redirection vers `ChercheurDashboard`.

### 11.3 Création d'une enquête terrain

1. dashboard chercheur ou admin
2. navigation vers `TerrainEntryChoiceScreen`
3. clic sur nouveau formulaire
4. création Firestore `terrain_forms/{id}`
5. ouverture `Matrice1Home`
6. progression par sections
7. autosave continu

Sources :
- [lib/screens/terrain/terrain_entry_choice_screen.dart](lib/screens/terrain/terrain_entry_choice_screen.dart)
- [lib/services/terrain_form_service.dart](lib/services/terrain_form_service.dart)

### 11.4 Publication / soumission d'une enquête

Flux incomplet dans le code actuel.

`submitForm()` existe dans les services mais n'est pas appelé par les pages de fin.

Sources :
- [lib/services/terrain_form_service.dart](lib/services/terrain_form_service.dart)
- [lib/services/lab_form_service.dart](lib/services/lab_form_service.dart)

### 11.5 Réponse à une enquête

Dans ce projet, “répondre” signifie remplir un formulaire terrain ou labo en tant qu'utilisateur connecté.

Il n'existe pas de répondant externe public.

### 11.6 Consultation des résultats

- chercheur : listes récentes + exports + stats perso
- admin : listes globales + stats globales + détail chercheur

### 11.7 Gestion des utilisateurs

Réellement implémenté :
- consultation
- filtrage
- export CSV
- suppression Firestore + données liées

Non implémenté :
- création admin d'un chercheur depuis un écran dédié
- modification d'un chercheur
- suppression du compte Auth Firebase

Source :
- [lib/screens/admin/admin_researchers_screen.dart](lib/screens/admin/admin_researchers_screen.dart)

### 11.8 Suppression ou archivage

Implémenté :
- suppression de formulaires
- suppression de chercheurs

Non implémenté :
- archivage
- restauration
- workflow de validation/rejet

---

## 12. Problèmes détectés, incohérences et code mort

### 12.1 Bugs / incohérences probables

- élévation de privilège admin possible via rôle client
- soumission finale non branchée
- récupération globale des IDs terrain en labo potentiellement bloquée par règles
- suppression de formulaire sans suppression cascade des médias
- repo multi-plateforme mais `firebase_options.dart` limité à Android/Web

### 12.2 Code mort ou legacy

- collection `surveys` et ses sous-objets dans `firestore.rules` et indexes, non utilisée par l'application active
- `lek_forms` dans règles seulement
- `DashboardScreen` legacy avec données mock
- `HomeScreen` legacy
- `mock_users`, `user_mock`, widgets anciens
- `widget_test.dart` encore sur le compteur Flutter par défaut

Sources :
- [firestore.rules](firestore.rules)
- [firestore.indexes.json](firestore.indexes.json)
- [lib/screens/dashboard_screen.dart](lib/screens/dashboard_screen.dart)
- [lib/screens/home_screen.dart](lib/screens/home_screen.dart)
- [test/widget_test.dart](test/widget_test.dart)

### 12.3 Contradictions frontend / backend

- le frontend courant utilise `terrain_forms` / `lab_forms`, alors que les règles et indexes gardent aussi un ancien modèle `surveys`
- la fin des formulaires donne un ressenti “succès” sans changement de statut métier

---

## 13. Fonctionnalités manquantes ou à améliorer

### 13.1 Manques fonctionnels

- workflow de soumission final réel
- validation/rejet admin
- historique d'état
- édition du profil
- création/gestion utilisateur plus complète
- archivage des formulaires
- cascade de suppression propre

### 13.2 Améliorations UX/UI

- afficher clairement brouillon vs soumis
- indiquer les champs obligatoires restants
- ajouter confirmation explicite de fin de formulaire
- améliorer la lisibilité des filtres admin médias

### 13.3 Améliorations backend

- Cloud Functions pour opérations sensibles
- suppression Auth serveur
- normalisation des schémas
- séparation observation terrain / analyse labo

### 13.4 Améliorations sécurité

- suppression du PIN admin côté client
- gestion des rôles sécurisée serveur
- réduction des lectures globales
- nettoyage des règles legacy

### 13.5 Améliorations base de données

- collection dédiée aux observations terrain publiables au labo
- schéma plus strict pour `data`
- conventions de nommage homogènes

---

## 14. Conclusion générale

Le projet est une application Flutter/Firebase fonctionnelle et déjà structurée autour d'un vrai usage métier :
- collecte terrain
- analyse laboratoire
- supervision admin
- export
- pièces jointes

Les modules principaux sont opérationnels, mais plusieurs écarts importants restent présents :
- sécurité des rôles insuffisante
- ancien modèle `surveys` encore dans les règles
- cycle de vie des formulaires incomplet
- suppression non totalement propre

Avant une mise en production, les priorités devraient être :
1. sécuriser la gestion des rôles
2. finaliser la soumission métier des formulaires
3. nettoyer les règles et le code legacy
4. fiabiliser les suppressions et la liaison terrain/labo

---

## Annexes - Fichiers de preuve principaux

### Authentification et rôles
- [lib/auth/auth_gate.dart](lib/auth/auth_gate.dart)
- [lib/services/auth_service.dart](lib/services/auth_service.dart)
- [lib/services/user_service.dart](lib/services/user_service.dart)
- [lib/screens/admin/widgets/admin_role_guard.dart](lib/screens/admin/widgets/admin_role_guard.dart)

### Dashboards
- [lib/screens/admin/admin_dashboard.dart](lib/screens/admin/admin_dashboard.dart)
- [lib/screens/chercheur/chercheur_dashboard.dart](lib/screens/chercheur/chercheur_dashboard.dart)

### Terrain
- [lib/services/terrain_form_service.dart](lib/services/terrain_form_service.dart)
- [lib/screens/terrain/matrice1_home.dart](lib/screens/terrain/matrice1_home.dart)
- [lib/screens/terrain/informations_generales_page.dart](lib/screens/terrain/informations_generales_page.dart)
- [lib/screens/terrain/suivi_page.dart](lib/screens/terrain/suivi_page.dart)
- [lib/screens/terrain/capture_page.dart](lib/screens/terrain/capture_page.dart)
- [lib/screens/terrain/variables_environnementales_page.dart](lib/screens/terrain/variables_environnementales_page.dart)
- [lib/screens/terrain/remarques_page.dart](lib/screens/terrain/remarques_page.dart)

### Laboratoire
- [lib/services/lab_form_service.dart](lib/services/lab_form_service.dart)
- [lib/screens/labo/donnees_laboratoire_home.dart](lib/screens/labo/donnees_laboratoire_home.dart)
- [lib/screens/labo/analyse_laboratoire_page1.dart](lib/screens/labo/analyse_laboratoire_page1.dart)
- [lib/screens/labo/analyse_crabe_bleu_page2.dart](lib/screens/labo/analyse_crabe_bleu_page2.dart)
- [lib/screens/labo/epibionts_page3.dart](lib/screens/labo/epibionts_page3.dart)
- [lib/screens/labo/remarques_page4.dart](lib/screens/labo/remarques_page4.dart)

### Admin
- [lib/screens/admin/admin_surveys_screen.dart](lib/screens/admin/admin_surveys_screen.dart)
- [lib/screens/admin/admin_researchers_screen.dart](lib/screens/admin/admin_researchers_screen.dart)
- [lib/screens/admin/researcher_details_screen.dart](lib/screens/admin/researcher_details_screen.dart)
- [lib/screens/admin/admin_attachments_screen.dart](lib/screens/admin/admin_attachments_screen.dart)
- [lib/screens/admin/admin_pdf_template_screen.dart](lib/screens/admin/admin_pdf_template_screen.dart)

### Médias et export
- [lib/services/attachment_service.dart](lib/services/attachment_service.dart)
- [lib/services/attachment_download_service.dart](lib/services/attachment_download_service.dart)
- [lib/services/export_service.dart](lib/services/export_service.dart)
- [lib/services/csv_export_service.dart](lib/services/csv_export_service.dart)

### Sécurité et configuration
- [firestore.rules](firestore.rules)
- [storage.rules](storage.rules)
- [firebase.json](firebase.json)
- [firestore.indexes.json](firestore.indexes.json)
- [lib/firebase_options.dart](lib/firebase_options.dart)
#   C e r c l e - B l e u  
 