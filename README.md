# Manuel Technique - My Mobility Services

## Crédits et Transparence IA

> **IMPORTANT** : Ce manuel technique et une partie du code source ont été générés avec l'assistance de **ChatGPT-5** pour optimiser la productivité et la qualité de la documentation.

### Processus de Développement Hybride

1. **Génération IA** : Utilisation de ChatGPT-5 pour la génération initiale de code et documentation
2. **Révision humaine** : Analyse et adaptation par l'équipe de développement
3. **Tests et validation** : Vérification du fonctionnement et de la conformité
4. **Intégration** : Mise en production après validation complète

### Éléments Générés par IA

- Documentation technique et manuel utilisateur
- Structure de base des services et modèles de données
- Templates d'écrans et composants UI


### Approche de Développeur Moderne

> **PHILOSOPHIE** : En tant que développeurs modernes, nous utilisons tous les outils disponibles pour maximiser notre productivité et la qualité de notre code. L'IA n'est pas un remplacement de nos compétences, mais un amplificateur de notre expertise.

> **AVANTAGES** : Cette approche nous permet de nous concentrer sur les aspects créatifs et stratégiques du développement tout en automatisant les tâches répétitives.

> **EFFICACITÉ** : L'utilisation de ChatGPT-5 nous permet de développer plus rapidement tout en maintenant des standards de qualité élevés et une architecture propre.


---

## Table des matières
1. [Technologies et versions](#technologies-et-versions)
2. [Installation et déploiement](#installation-et-déploiement)
3. [Standards de développement](#standards-de-développement)
4. [Architecture de l'application](#architecture-de-lapplication)
5. [Correspondance entre le code et les fonctionnalités](#correspondance-entre-le-code-et-les-fonctionnalités)

---


### Stack Technologique Moderne

- **IA Générative** : ChatGPT-5 pour la génération de code et documentation
- **Framework** : Flutter 3.9+ avec Dart
- **Backend** : Firebase (Auth, Firestore, Storage)
- **Cartes** : Google Maps Flutter
- **Design** : Glassmorphism et Material Design 3
- **Déploiement** : Android studio emulateur avec apk


## Installation et déploiement

### Prérequis
1. **Flutter SDK** 3.9.0 ou supérieur
2. **Dart SDK** compatible
3. **Android Studio** ou **VS Code** avec extensions Flutter
4. **Git** pour le contrôle de version
5. **Compte Firebase** configuré

### Configuration Firebase
1. Le fichier `google-services.json` est présent dans `android/app/`
2. Les clés API Google Maps sont configurées dans `lib/constants.dart`
3. Les options Firebase sont dans `lib/firebase/firebase_options.dart`


## Tutoriel d'installation de A à Z

### **Étape 1 : Télécharger l'application**

#### **Option A : Depuis GitHub (Recommandé)**
1. Allez sur le repository GitHub : `https://github.com/esig-ge/projet-2025-mbs`
2. Cliquez sur l'onglet **"Releases"** (à droite de "Code")
3. Téléchargez le fichier **`app-release.apk`** de la dernière version
4. Sauvegardez le fichier dans un dossier facilement accessible (ex: Bureau)

#### **Option B : Depuis le dossier fourni**
1. Ouvrez le dossier fourni par l'équipe
2. Localisez le fichier **`app-release.apk`**
3. Copiez-le dans un dossier facilement accessible

---

### **Étape 2 : Installation d'Android Studio**

#### **2.1 Télécharger Android Studio**
1. Allez sur : `https://developer.android.com/studio`
2. Cliquez sur **"Download Android Studio"**
3. Acceptez les conditions d'utilisation
4. Téléchargez la version pour votre système (Windows/Mac/Linux)

#### **2.2 Installer Android Studio**
1. **Windows** : Exécutez le fichier `.exe` téléchargé
2. **Mac** : Ouvrez le fichier `.dmg` et glissez Android Studio dans Applications
3. **Linux** : Extrayez le fichier `.tar.gz` et suivez les instructions

#### **2.3 Configuration initiale**
1. Lancez Android Studio
2. Suivez l'assistant de configuration :
   - Acceptez les licences Android SDK
   - Choisissez "Standard" pour le type d'installation
   - Laissez les paramètres par défaut
3. Attendez la fin du téléchargement des composants (peut prendre 10-15 minutes)

---

### **Étape 3 : Créer un émulateur Android**

#### **3.1 Ouvrir le gestionnaire d'émulateurs**
1. Dans Android Studio, cliquez sur **"More Actions"** (ou les 3 points)
2. Sélectionnez **"Virtual Device Manager"** (ou AVD Manager)

#### **3.2 Créer un nouvel émulateur**
1. Cliquez sur **"Create Device"**
2. Choisissez un appareil (ex: **Pixel 6** ou **Pixel 7**)
3. Cliquez sur **"Next"**

#### **3.3 Sélectionner l'image système**
1. Choisissez **"API 34"** (Android 14) ou **"API 33"** (Android 13)
2. Si pas téléchargé, cliquez sur **"Download"** à côté de l'API
3. Cliquez sur **"Next"**

#### **3.4 Configuration finale**
1. Nommez votre émulateur (ex: "Pixel_6_Android_14")
2. Laissez les paramètres par défaut
3. Cliquez sur **"Finish"**

---

### **Étape 4 : Lancer l'émulateur et installer l'APK**

#### **4.1 Démarrer l'émulateur**
1. Dans le Virtual Device Manager, cliquez sur **Play** à côté de votre émulateur
2. Attendez que l'émulateur se lance complètement (2-3 minutes)
3. L'émulateur Android s'ouvrira dans une nouvelle fenêtre

#### **4.2 Installer l'application**
1. **Glissez-déposez** le fichier `app-release.apk` directement dans l'émulateur
2. OU : Cliquez sur l'icône **📁** dans la barre latérale de l'émulateur
3. Naviguez vers votre fichier APK et double-cliquez dessus
4. Suivez les instructions d'installation

#### **4.3 Lancer l'application**
1. Dans l'émulateur, trouvez l'icône **"My Mobility Services"**
2. Cliquez dessus pour lancer l'application
3. L'application se lancera avec l'écran de connexion

---

### **Dépannage courant**

#### **Problème : L'émulateur ne démarre pas**
- **Solution** : Vérifiez que la virtualisation est activée dans le BIOS
- **Windows** : Activez Hyper-V ou VirtualBox
- **Mac** : Aucune action requise
- **Linux** : Installez KVM

#### **Problème : L'APK ne s'installe pas**
- **Solution** : Activez "Sources inconnues" dans les paramètres Android
- Allez dans **Paramètres > Sécurité > Sources inconnues** et activez

#### **Problème : L'application se ferme au lancement**
- **Solution** : Vérifiez que l'émulateur a au moins 4GB de RAM
- Redémarrez l'émulateur et réessayez

---

### **Résumé des étapes**
1. Télécharger l'APK depuis GitHub ou le dossier fourni
2. Installer Android Studio
3. Créer un émulateur Android
4. Lancer l'émulateur
5. Glisser-déposer l'APK dans l'émulateur
6. Lancer l'application

**Félicitations ! Vous pouvez maintenant utiliser My Mobility Services !**

---

### Architecture

```
lib/
├── data/           # Modèles et services (M)
│   ├── models/     # Modèles de données
│   └── services/   # Services métier
├── screens/        # Vues (V)
│   ├── admin/      # Interface administrateur
│   ├── utilisateur/# Interface utilisateur
│   └── log_screen/ # Écrans d'authentification
├── widgets/        # Composants réutilisables (C)
├── theme/          # Thème et design system
└── constants.dart  # Constantes globales
```


### Design System
- **Thème** : Glassmorphism sombre avec couleurs définies dans `AppColors`
- **Police** : Poppins (Google Fonts)
- **Couleurs principales** :
  - Accent : `#7C9CFF` (periwinkle)
  - Accent2 : `#4FE5D2` (aqua mint)
  - Hot : `#FF9DB0` (warm highlight)
  - Background : `#0B0E13` (near-black blue)

### Gestion d'état
- Utilisation de `StatefulWidget` pour l'état local
- `StreamBuilder` pour les données Firebase en temps réel
- Services pour la logique métier

---


### Structure des données (Firestore)

#### Collection `users` `UserService._collection = 'users'`
```
users/
├── {userId}/
│   ├── uid: string                    # ID unique Firebase Auth (obligatoire)
│   ├── email: string                  # Email de connexion (obligatoire)
│   ├── name: string                   # Nom d'utilisateur (obligatoire)
│   ├── phone: string                  # Numéro de téléphone (obligatoire)
│   ├── countryCode: string            # Code pays (ex: "+33") (obligatoire)
│   ├── countryName: string            # Nom du pays (ex: "France") (obligatoire)
│   ├── emailVerified: boolean         # Email vérifié (obligatoire)
│   ├── provider: string               # Méthode d'authentification (ex: "password") (obligatoire)
│   ├── lastLoginAt: timestamp         # Dernière connexion (optionnel)
│   └── createdAt: timestamp           # Date de création (obligatoire)
```

#### Collection `reservations` `ReservationService._collection = 'reservations'`
```
reservations/
├── {reservationId}/
│   ├── id: string                     # ID unique de la réservation (obligatoire)
│   ├── userId: string                 # ID de l'utilisateur (obligatoire)
│   ├── userName: string               # Nom de l'utilisateur (obligatoire)
│   ├── vehicleName: string            # Nom du véhicule sélectionné (obligatoire)
│   ├── departure: string              # Adresse de départ (obligatoire)
│   ├── destination: string            # Adresse d'arrivée (obligatoire)
│   ├── selectedDate: timestamp        # Date sélectionnée (obligatoire)
│   ├── selectedTime: string           # Heure sélectionnée au format HH:mm (obligatoire)
│   ├── estimatedArrival: string       # Heure d'arrivée estimée (obligatoire)
│   ├── paymentMethod: string          # Méthode de paiement (ex: "Espèces") (obligatoire)
│   ├── totalPrice: number             # Prix total de la course (obligatoire)
│   ├── status: string                 # Statut de la réservation (ex: "cancelled") (obligatoire)
│   ├── clientNote: string             # Note du client pour le chauffeur (obligatoire)
│   ├── departureCoordinates: null     # Coordonnées GPS de départ (peut être null)
│   ├── destinationCoordinates: null   # Coordonnées GPS d'arrivée (peut être null)
│   ├── createdAt: timestamp           # Date de création (obligatoire)
│   └── updatedAt: timestamp           # Date de dernière modification (obligatoire)
```

#### Collection `vehicles` (Analyse du code : `VehicleService._collection = 'vehicles'`)
```
vehicles/
├── {vehicleId}/
│   ├── id: string                     # ID unique du véhicule (obligatoire)
│   ├── name: string                   # Nom du véhicule (obligatoire)
│   ├── category: string               # Catégorie du véhicule (ex: "luxe") (obligatoire)
│   ├── pricePerKm: number             # Prix par kilomètre pour ce véhicule (obligatoire)
│   ├── maxPassengers: number          # Nombre maximum de passagers (obligatoire)
│   ├── maxLuggage: number             # Nombre maximum de bagages (obligatoire)
│   ├── description: string            # Description du véhicule (obligatoire)
│   ├── icon: number                   # Code point de l'icône Material Design (obligatoire)
│   ├── imageUrl: string               # URL de l'image du véhicule (peut être vide) (obligatoire)
│   ├── isActive: boolean              # Si le véhicule est disponible (obligatoire)
│   ├── createdAt: timestamp           # Date de création (obligatoire)
│   └── updatedAt: timestamp           # Date de dernière modification (obligatoire)
  ```

#### Enums utilisés (Basés sur l'analyse du code)

**ReservationStatus** (défini dans `lib/data/models/reservation.dart`) :
- `pending` → "En attente"
- `confirmed` → "Confirmée"
- `inProgress` → "En cours"
- `completed` → "Terminée"
- `cancelled` → "Annulée"

**UserRole** (défini dans `lib/data/models/user_model.dart`) :
- `user` → "Utilisateur"
- `admin` → "Administrateur"

**VehicleCategory** (défini dans `lib/data/models/vehicule_type.dart`) :
- `luxe` → "Luxe"
- `van` → "Van"
- `economique` → "Économique"


#### Relations entre collections


##### 1. **users ↔ reservations** (Relation principale)
- **Type** : 1:N (Un utilisateur peut avoir plusieurs réservations)
- **Liaison** : `reservations.userId` → `users.uid`
- **Code** : `ReservationService.getUserReservations(userId)` (ligne 25-38)
- **Enrichissement** : `_enrichReservationWithUserName()` récupère les infos utilisateur (lignes 185-221)
- **Streams** : `getUserReservationsStream()`, `getUserConfirmedReservationsStream()`, `getUserCompletedReservationsStream()`

##### 2. **vehicles** (Collection autonome)
- **Type** : Collection autonome avec enum hardcodé
- **Liaison** : Pas de relation externe, utilise l'enum `VehicleCategory` hardcodé
- **Code** : `VehicleService.getVehiclesByCategory(category)` (lignes 191-206)
- **Filtrage** : Filtrage par `isActive` et `category` (enum)
- **Streams** : `getVehiclesStream()` pour les mises à jour en temps réel

##### 3. **reservations ↔ vehicles** (Relation de sélection)
- **Type** : N:1 (Plusieurs réservations peuvent utiliser le même type de véhicule)
- **Liaison** : `reservations.vehicleName` → `vehicles.name` (string)
- **Code** : Stockage du nom du véhicule dans la réservation (pas de relation directe)
- **Note** : Relation indirecte via le nom du véhicule



### Services principaux
- **ReservationService** : Gestion des réservations
- **UserService** : Gestion des utilisateurs
- **VehicleService** : Gestion des véhicules
- **AdminService** : Fonctionnalités administrateur
- **SessionService** : Gestion des sessions
- **NotificationService** : Notifications
- **DirectionsService** : Calcul d'itinéraires

---

## Correspondance entre le code et les fonctionnalités

### Authentification et comptes

| Fonctionnalité | Fichier | Lignes | Description |
|---|---|---|---|
| **Interface création compte** | `lib/screens/log_screen/welcome_login_screen.dart` | 1-50 | Écran d'accueil avec options de connexion/inscription |
| **Page connexion** | `lib/screens/log_screen/login_form.dart` | 81-166 | Interface de connexion avec Firebase Auth |
| **Page inscription** | `lib/screens/log_screen/signup_form.dart` | 103-200 | Interface d'inscription avec validation |
| **Rendre log in/sign up effectif** | `lib/data/services/user_service.dart` | 1-50 | Service d'authentification Firebase |
| **Gestion des sessions utilisateur** | `lib/data/services/session_service.dart` | 1-52 | Validation et gestion des sessions utilisateur |
| **Adapter messages d'erreur** | `lib/screens/log_screen/login_form.dart` | 125-156 | Snackbars d'erreur personnalisées |

### Réservation et localisation

| Fonctionnalité | Fichier | Lignes | Description |
|---|---|---|---|
| **Choix de la date et de l'heure** | `lib/screens/utilisateur/reservation/scheduling_screen.dart` | 55-131 | Sélecteur de date/heure avec timezone |
| **Sélection point départ/arrivée** | `lib/screens/utilisateur/reservation/localisation_recherche_screen.dart` | 1-100 | Interface de recherche d'adresses |
| **Liste de suggestions trajets** | `lib/screens/utilisateur/reservation/localisation_recherche_screen.dart` | 200-400 | Autocomplétion des adresses |
| **Montrer trajets favoris** | `lib/screens/utilisateur/reservation/localisation_recherche_screen.dart` | 500-600 | Historique des adresses fréquentes |
| **Position départ par défaut** | `lib/screens/utilisateur/reservation/acceuil_res_screen.dart` | 1-100 | Géolocalisation automatique |
| **Bouton recentrer localisation** | `lib/screens/utilisateur/reservation/acceuil_res_screen.dart` | 200-300 | Recentrage sur position utilisateur |
| **Affichage maps dès l'entrée** | `lib/screens/utilisateur/reservation/acceuil_res_screen.dart` | 100-200 | Carte Google Maps intégrée |
| **Suggestion du pays localisé** | `lib/screens/utilisateur/reservation/localisation_recherche_screen.dart` | 300-500 | Détection automatique du pays |

### Calcul et paiement

| Fonctionnalité | Fichier | Lignes | Description |
|---|---|---|---|
| **Calcul du prix** | `lib/screens/utilisateur/reservation/trip_summary_screen.dart` | 208-271 | Calcul basé sur distance et type véhicule |
| **Afficher prix total par type** | `lib/screens/utilisateur/reservation/booking_screen.dart` | 815-830 | Affichage des prix pour chaque véhicule |
| **Calculer km lors choix trajets** | `lib/data/services/directions_service.dart` | 1-100 | Service de calcul d'itinéraires |
| **Multiplier km par prix/km** | `lib/screens/utilisateur/reservation/booking_screen.dart` | 110-127 | Logique de calcul des tarifs |
| **Choix du véhicule** | `lib/screens/utilisateur/reservation/booking_screen.dart` | 880-893 | Sélection du type de véhicule |
| **Donner taille véhicule** | `lib/data/models/vehicule_type.dart` | 1-134 | Modèle de données des véhicules |
| **Système de paiement sécurisé** | `lib/screens/utilisateur/reservation/trip_summary_screen.dart` | 273-350 | Interface de paiement |
| **Sélectionner paiement par cash** | `lib/screens/utilisateur/reservation/trip_summary_screen.dart` | 40-50 | Option de paiement en espèces |

### Planification et suivi

| Fonctionnalité | Fichier | Lignes | Description |
|---|---|---|---|
| **Date heure par défaut actuelle** | `lib/screens/utilisateur/reservation/scheduling_screen.dart` | 40-55 | Initialisation avec heure actuelle + 30min |
| **Estimer heure d'arrivée** | `lib/screens/utilisateur/reservation/scheduling_screen.dart` | 55-96 | Calcul basé sur heure sélectionnée |
| **Estimation temps de trajet** | `lib/screens/utilisateur/reservation/trip_summary_screen.dart` | 50-60 | Affichage durée estimée |
| **Bouton modifier heure/date/lieu** | `lib/screens/utilisateur/reservation/trip_summary_screen.dart` | 400-500 | Redirection vers écrans de modification |

### Interface utilisateur

| Fonctionnalité | Fichier | Lignes | Description |
|---|---|---|---|
| **Interface avant course** | `lib/screens/utilisateur/reservation/reservation_detail_screen.dart` | 1-100 | Affichage carte avec tracé |
| **Affichage map avec tracé** | `lib/screens/utilisateur/reservation/reservation_detail_screen.dart` | 200-300 | Carte avec itinéraire tracé |
| **Bouton raccourci supprimer adresse** | `lib/screens/utilisateur/reservation/localisation_recherche_screen.dart` | 600-700 | Suppression rapide d'adresses |
| **Page offres personnalisées** | `lib/screens/utilisateur/offres/offres_personnalisees_screen.dart` | 1-50 | Interface des offres spéciales |

### Gestion des véhicules

| Fonctionnalité | Fichier | Lignes | Description |
|---|---|---|---|
| **Mettre à jour parc véhicules** | `lib/screens/admin/gestion/vehicle_management_screen.dart` | 1-100 | Interface admin de gestion |
| **Rendre véhicule impossible** | `lib/screens/admin/gestion/vehicle_management_screen.dart` | 200-400 | Désactivation de véhicules |
| **Véhicule lié à BDD** | `lib/data/services/vehicle_service.dart` | 1-50 | Service de gestion des véhicules |

### Communication

| Fonctionnalité | Fichier | Lignes | Description |
|---|---|---|---|
| **Contact rapide au client** | `lib/screens/utilisateur/reservation/reservation_detail_screen.dart` | 300-400 | Boutons d'appel/SMS |
| **Contact rapide au chauffeur** | `lib/screens/utilisateur/reservation/reservation_detail_screen.dart` | 400-500 | Communication avec chauffeur |
| **Voir mode de paiement client** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | 200-300 | Affichage info paiement |

### Administration

| Fonctionnalité | Fichier | Lignes | Description |
|---|---|---|---|
| **Planning des courses à venir** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | 1-100 | Vue admin des réservations |
| **Pastille nav demande avec nb res** | `lib/screens/admin/reception/admin_reception_screen.dart` | 1-50 | Indicateur de demandes |
| **Affichage nb res en attente** | `lib/screens/admin/reception/admin_reception_screen.dart` | 100-200 | Compteurs de statuts |
| **Res accepter/refuser** | `lib/screens/admin/reception/admin_reception_screen.dart` | 200-400 | Actions sur réservations |
| **Res avec récap complète** | `lib/screens/admin/reception/admin_reception_screen.dart` | 400-600 | Détails complets des réservations |
| **Récap complet res confirmées** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | 300-500 | Détails des réservations confirmées |
| **Bouton changer statut course** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | 500-700 | Modification statut (terminer/annuler) |
| **Récap complet course terminée** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | 700-900 | Détails des courses terminées |
| **Afficher que celles terminées** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | 100-200 | Filtrage par statut |
| **Voir note client** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | 800-900 | Affichage des notes |

### Historique et suivi

| Fonctionnalité | Fichier | Lignes | Description |
|---|---|---|---|
| **Historique trajets passés client** | `lib/screens/utilisateur/trajets/trajets_screen.dart` | 1-100 | Historique des réservations |
| **Possibilité voir historique courses** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | 900-1000 | Vue admin de l'historique |
| **Trier historique trajet croissant** | `lib/screens/utilisateur/trajets/trajets_screen.dart` | 100-200 | Tri chronologique |
| **Afficher info compte** | `lib/screens/utilisateur/profile/profile_screen.dart` | 1-100 | Profil utilisateur |


### Fonctionnalités avancées

| Fonctionnalité | Fichier | Lignes | Description |
|---|---|---|---|
| **Possible ajouter note** | `lib/screens/utilisateur/reservation/trip_summary_screen.dart` | 45-50 | Champ de note pour chauffeur |
| **Réservation impossible tant que pas accepté** | `lib/screens/utilisateur/reservation/reservation_detail_screen.dart` | 100-200 | Logique de validation |
| **Changer état réservation** | `lib/data/services/reservation_service.dart` | 1-50 | Service de mise à jour statut |
| **Annulation de la course** | `lib/screens/utilisateur/reservation/reservation_detail_screen.dart` | 200-300 | Fonction d'annulation |
| **Bouton déconnexion** | `lib/screens/admin/profile/admin_profile_screen.dart` | 1-50 | Déconnexion admin |


| Fonctionnalité | Fichier | Lignes | Description |
|---|---|---|---|
| **Point d'entrée principal** | `lib/widgets/authgate.dart` | 1-91 | Gestion authentification et redirection |
| **Container utilisateur** | `lib/screens/utilisateur/reservation/home_shell.dart` | 1-108 | Navigation entre onglets utilisateur |
| **Préchargement Google Maps** | `lib/screens/utilisateur/reservation/home_shell.dart` | 47-74 | Optimisation performance cartes |
| **Gestion navigation** | `lib/screens/utilisateur/reservation/home_shell.dart` | 30-37 | Système de verrouillage navigation |

---

## Configurations a prendre en compte

### Configuration requise
1. **Clés API Google Maps** : Configurer dans `lib/constants.dart`
2. **Firebase** : Vérifier la configuration dans `lib/firebase/`
3. **Permissions** : Android manifest configuré pour géolocalisation et appels, adapter pour plus d'autorisations

### Design System
- Utiliser exclusivement les composants `GlassContainer`, `GlassButton`, etc.
- Respecter la palette de couleurs `AppColors`
- Police Poppins obligatoire via `AppConstants.defaultTextStyle`


### Navigation
- Routes définies dans `main.dart`
- Navigation conditionnelle selon le rôle utilisateur
- Gestion des états de navigation

### Sécurité
- Authentification Firebase
- Validation des rôles utilisateur
- Gestion des sessions persistantes

