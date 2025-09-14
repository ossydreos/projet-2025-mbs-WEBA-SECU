# Manuel Technique - My Mobility Services

## Crédits et Transparence IA

> **⚠️ IMPORTANT** : Ce manuel technique et une partie du code source ont été générés avec l'assistance de **ChatGPT-5** pour optimiser la productivité et la qualité de la documentation.
> 
> **Adaptation humaine** : Tous les éléments générés ont été soigneusement adaptés, testés et validés par Youri Sanchez et Poumin Mali pour s'assurer de leur conformité avec les standards du projet et les bonnes pratiques de développement Flutter.
> 
> **🎯 OBJECTIF** : Cette approche hybride (IA + expertise humaine) permet d'accélérer le développement tout en maintenant la qualité et la cohérence du code.

### 🔄 Processus de Développement Hybride

1. **Génération IA** : Utilisation de ChatGPT-5 pour la génération initiale de code et documentation
2. **Révision humaine** : Analyse et adaptation par l'équipe de développement
3. **Tests et validation** : Vérification du fonctionnement et de la conformité
4. **Intégration** : Mise en production après validation complète

### 📋 Éléments Générés par IA

- Documentation technique et manuel utilisateur
- Structure de base des services et modèles de données
- Templates d'écrans et composants UI
- Configuration Firebase et intégrations
- Tests unitaires et de validation

### 🛠️ Éléments Développés Manuellement

- Logique métier spécifique au projet
- Intégrations personnalisées
- Optimisations de performance
- Corrections de bugs et améliorations
- Déploiement et configuration production

### 🚀 Approche de Développeur Moderne

> **💡 PHILOSOPHIE** : En tant que développeurs modernes, nous utilisons tous les outils disponibles pour maximiser notre productivité et la qualité de notre code. L'IA n'est pas un remplacement de nos compétences, mais un amplificateur de notre expertise.

> **🎯 AVANTAGES** : Cette approche nous permet de nous concentrer sur les aspects créatifs et stratégiques du développement tout en automatisant les tâches répétitives et la génération de code boilerplate.

> **⚡ EFFICACITÉ** : L'utilisation de ChatGPT-5 nous permet de développer 3x plus rapidement tout en maintenant des standards de qualité élevés et une architecture propre.

### 🛠️ Stack Technologique Moderne

- **IA Générative** : ChatGPT-5 pour la génération de code et documentation
- **Framework** : Flutter 3.9+ avec Dart
- **Backend** : Firebase (Auth, Firestore, Storage)
- **Cartes** : Google Maps Flutter
- **Design** : Glassmorphism et Material Design 3
- **État** : StatefulWidget + StreamBuilder
- **Tests** : Flutter Test + Integration Tests
- **Déploiement** : CI/CD avec GitHub Actions

---

## Table des matières
1. [Technologies et versions](#technologies-et-versions)
2. [Installation et déploiement](#installation-et-déploiement)
3. [Standards de développement](#standards-de-développement)
4. [Architecture de l'application](#architecture-de-lapplication)
5. [Correspondance entre le code et les fonctionnalités](#correspondance-entre-le-code-et-les-fonctionnalités)

---

## Technologies et versions

### Framework principal
- **Flutter** : SDK ^3.9.0
- **Dart** : Version compatible avec Flutter 3.9.0

### Backend et base de données
- **Firebase Core** : ^4.0.0
- **Cloud Firestore** : ^6.0.0 (Base de données NoSQL)
- **Firebase Auth** : ^6.0.0 (Authentification)

### Cartes et géolocalisation
- **Google Maps Flutter** : ^2.9.0
- **Flutter Map** : ^6.1.0
- **Geolocator** : ^11.0.0
- **Geocoding** : ^2.1.1
- **Latlong2** : ^0.9.0

### UI et design
- **Google Fonts** : ^6.2.1 (Police Poppins)
- **Font Awesome Flutter** : ^10.7.0
- **Glassmorphism** : ^3.0.0
- **Flutter SVG** : ^2.2.0

### Utilitaires
- **HTTP** : ^1.1.0
- **Shared Preferences** : ^2.2.2
- **Permission Handler** : ^11.3.1
- **URL Launcher** : ^6.2.2
- **Timezone** : ^0.9.2
- **Country Code Picker** : ^3.0.0

### Outils de développement
- **Flutter Lints** : ^5.0.0
- **Flutter Native Splash** : ^2.4.0

---

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

### Installation
```bash
# Cloner le projet
git clone [URL_DU_REPOSITORY]
cd projet-2025-mbs

# Installer les dépendances
flutter pub get

# Générer les fichiers de configuration
flutter packages pub run build_runner build

# Lancer l'application
flutter run
```

### Déploiement
```bash
# Build Android
flutter build apk --release

# Build iOS
flutter build ios --release

# Build Web
flutter build web --release
```

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
│   ├── displayName: string?           # Nom affiché (optionnel)
│   ├── phoneNumber: string?           # Numéro de téléphone (optionnel)
│   ├── role: "user" | "admin"         # Rôle utilisateur (enum UserRole)
│   ├── createdAt: timestamp           # Date de création (obligatoire)
│   ├── updatedAt: timestamp?          # Date de dernière modification (optionnel)
│   └── isActive: boolean              # Statut actif/inactif (défaut: true)
```

#### Collection `reservations` `ReservationService._collection = 'reservations'`
```
reservations/
├── {reservationId}/
│   ├── id: string                     # ID unique de la réservation (obligatoire)
│   ├── userId: string                 # ID de l'utilisateur (obligatoire)
│   ├── userName: string?              # Nom de l'utilisateur (optionnel, enrichi dynamiquement)
│   ├── vehicleName: string            # Nom du véhicule sélectionné (obligatoire)
│   ├── departure: string              # Adresse de départ (obligatoire)
│   ├── destination: string            # Adresse d'arrivée (obligatoire)
│   ├── selectedDate: timestamp        # Date sélectionnée (obligatoire)
│   ├── selectedTime: string           # Heure sélectionnée au format HH:mm (obligatoire)
│   ├── estimatedArrival: string       # Heure d'arrivée estimée (obligatoire)
│   ├── paymentMethod: string          # Méthode de paiement (obligatoire)
│   ├── totalPrice: number             # Prix total de la course (obligatoire)
│   ├── status: "pending" | "confirmed" | "inProgress" | "completed" | "cancelled"  # Statut (enum ReservationStatus)
│   ├── createdAt: timestamp           # Date de création (obligatoire)
│   ├── updatedAt: timestamp?          # Date de dernière modification (optionnel)
│   ├── departureCoordinates: object?  # Coordonnées GPS de départ (optionnel)
│   ├── destinationCoordinates: object? # Coordonnées GPS d'arrivée (optionnel)
│   ├── clientNote: string?            # Note du client pour le chauffeur (optionnel)
│   ├── hasCounterOffer: boolean       # Indique si une contre-offre a été proposée (défaut: false)
│   ├── driverProposedDate: timestamp? # Date proposée par le chauffeur (optionnel)
│   ├── driverProposedTime: string?    # Heure proposée par le chauffeur (optionnel)
│   └── adminMessage: string?          # Message de l'admin pour la contre-offre (optionnel)
```

#### Collection `vehicles` (Analyse du code : `VehicleService._collection = 'vehicles'`)
```
vehicles/
├── {vehicleId}/
│   ├── id: string                     # ID unique du véhicule (obligatoire)
│   ├── name: string                   # Nom du véhicule (obligatoire)
│   ├── category: "luxe" | "van" | "economique"  # Catégorie (enum VehicleCategory)
│   ├── pricePerKm: number             # Prix par kilomètre pour ce véhicule (obligatoire)
│   ├── maxPassengers: number          # Nombre maximum de passagers (obligatoire)
│   ├── maxLuggage: number             # Nombre maximum de bagages (obligatoire)
│   ├── description: string            # Description du véhicule (obligatoire)
│   ├── imageUrl: string               # URL de l'image du véhicule (optionnel) // plus tard changer pour l'icon
│   ├── icon: number                   # Code point de l'icône Material Design (obligatoire)
│   ├── isActive: boolean              # Si le véhicule est disponible (défaut: true)
│   ├── createdAt: timestamp           # Date de création (obligatoire)
│   └── updatedAt: timestamp?          # Date de dernière modification (optionnel)
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

| Fonctionnalité | Fichier | Description |
|---|---|---|
| **Interface création compte** | `lib/screens/log_screen/welcome_login_screen.dart` | Écran d'accueil avec options de connexion/inscription |
| **Page connexion** | `lib/screens/log_screen/welcome_login_screen.dart` | Interface de connexion avec Firebase Auth |
| **Rendre log in/sign up effectif** | `lib/data/services/user_service.dart` | Service d'authentification Firebase |
| **Bouton rester connecté effectif** | `lib/data/services/session_service.dart` | Gestion de la persistance de session |
| **Adapter messages d'erreur** | `lib/screens/log_screen/welcome_login_screen.dart` | Snackbars d'erreur personnalisées |
| **Set up Google log in Facebook** | `lib/screens/log_screen/welcome_login_screen.dart` | Intégration des providers sociaux |

### Réservation et localisation

| Fonctionnalité | Fichier | Description |
|---|---|---|
| **Choix de la date et de l'heure** | `lib/screens/utilisateur/reservation/scheduling_screen.dart` | Sélecteur de date/heure avec timezone |
| **Sélection point départ/arrivée** | `lib/screens/utilisateur/reservation/localisation_recherche_screen.dart` | Interface de recherche d'adresses |
| **Liste de suggestions trajets** | `lib/screens/utilisateur/reservation/localisation_recherche_screen.dart` | Autocomplétion des adresses |
| **Montrer trajets favoris** | `lib/screens/utilisateur/reservation/localisation_recherche_screen.dart` | Historique des adresses fréquentes |
| **Position départ par défaut** | `lib/screens/utilisateur/reservation/acceuil_res_screen.dart` | Géolocalisation automatique |
| **Bouton recentrer localisation** | `lib/screens/utilisateur/reservation/acceuil_res_screen.dart` | Recentrage sur position utilisateur |
| **Affichage maps dès l'entrée** | `lib/screens/utilisateur/reservation/acceuil_res_screen.dart` | Carte Google Maps intégrée |
| **Suggestion du pays localisé** | `lib/screens/utilisateur/reservation/localisation_recherche_screen.dart` | Détection automatique du pays |

### 💰 Calcul et paiement

| Fonctionnalité | Fichier | Description |
|---|---|---|
| **Calcul du prix** | `lib/screens/utilisateur/reservation/booking_screen.dart` | Calcul basé sur distance et type véhicule |
| **Afficher prix total par type** | `lib/screens/utilisateur/reservation/booking_screen.dart` | Affichage des prix pour chaque véhicule |
| **Calculer km lors choix trajets** | `lib/data/services/directions_service.dart` | Service de calcul d'itinéraires |
| **Multiplier km par prix/km** | `lib/screens/utilisateur/reservation/booking_screen.dart` | Logique de calcul des tarifs |
| **Choix du véhicule** | `lib/screens/utilisateur/reservation/booking_screen.dart` | Sélection du type de véhicule |
| **Donner taille véhicule** | `lib/data/models/vehicule_type.dart` | Modèle de données des véhicules |
| **Système de paiement sécurisé** | `lib/screens/utilisateur/reservation/trip_summary_screen.dart` | Interface de paiement |
| **Sélectionner paiement par cash** | `lib/screens/utilisateur/reservation/trip_summary_screen.dart` | Option de paiement en espèces |

### 📅 Planification et suivi

| Fonctionnalité | Fichier | Description |
|---|---|---|
| **Date heure par défaut actuelle** | `lib/screens/utilisateur/reservation/scheduling_screen.dart` | Initialisation avec heure actuelle + 30min |
| **Estimer heure d'arrivée** | `lib/screens/utilisateur/reservation/scheduling_screen.dart` | Calcul basé sur heure sélectionnée |
| **Estimation temps de trajet** | `lib/screens/utilisateur/reservation/trip_summary_screen.dart` | Affichage durée estimée |
| **Bouton modifier heure/date/lieu** | `lib/screens/utilisateur/reservation/trip_summary_screen.dart` | Redirection vers écrans de modification |

### 📱 Interface utilisateur

| Fonctionnalité | Fichier | Description |
|---|---|---|
| **Interface avant course** | `lib/screens/utilisateur/reservation/reservation_detail_screen.dart` | Affichage carte avec tracé |
| **Affichage map avec tracé** | `lib/screens/utilisateur/reservation/reservation_detail_screen.dart` | Carte avec itinéraire tracé |
| **Bouton raccourci supprimer adresse** | `lib/screens/utilisateur/reservation/localisation_recherche_screen.dart` | Suppression rapide d'adresses |
| **Page offres personnalisées** | `lib/screens/utilisateur/offres/offres_personnalisees_screen.dart` | Interface des offres spéciales |

### 🚗 Gestion des véhicules

| Fonctionnalité | Fichier | Description |
|---|---|---|
| **Mettre à jour parc véhicules** | `lib/screens/admin/gestion/vehicle_management_screen.dart` | Interface admin de gestion |
| **Rendre véhicule impossible** | `lib/screens/admin/gestion/vehicle_management_screen.dart` | Désactivation de véhicules |
| **Véhicule lié à BDD** | `lib/data/services/vehicle_service.dart` | Service de gestion des véhicules |

### 📞 Communication

| Fonctionnalité | Fichier | Description |
|---|---|---|
| **Contact rapide au client** | `lib/screens/utilisateur/reservation/reservation_detail_screen.dart` | Boutons d'appel/SMS |
| **Contact rapide au chauffeur** | `lib/screens/utilisateur/reservation/reservation_detail_screen.dart` | Communication avec chauffeur |
| **Voir mode de paiement client** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | Affichage info paiement |

### 📊 Administration

| Fonctionnalité | Fichier | Description |
|---|---|---|
| **Planning des courses à venir** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | Vue admin des réservations |
| **Pastille nav demande avec nb res** | `lib/screens/admin/reception/admin_reception_screen.dart` | Indicateur de demandes |
| **Affichage nb res en attente** | `lib/screens/admin/reception/admin_reception_screen.dart` | Compteurs de statuts |
| **Res accepter/refuser** | `lib/screens/admin/reception/admin_reception_screen.dart` | Actions sur réservations |
| **Res avec récap complète** | `lib/screens/admin/reception/admin_reception_screen.dart` | Détails complets des réservations |
| **Récap complet res confirmées** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | Détails des réservations confirmées |
| **Bouton changer statut course** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | Modification statut (terminer/annuler) |
| **Récap complet course terminée** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | Détails des courses terminées |
| **Afficher que celles terminées** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | Filtrage par statut |
| **Voir note client** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | Affichage des notes |

### 📈 Historique et suivi

| Fonctionnalité | Fichier | Description |
|---|---|---|
| **Historique trajets passés client** | `lib/screens/utilisateur/trajets/trajets_screen.dart` | Historique des réservations |
| **Possibilité voir historique courses** | `lib/screens/admin/trajets/admin_trajets_screen.dart` | Vue admin de l'historique |
| **Trier historique trajet croissant** | `lib/screens/utilisateur/trajets/trajets_screen.dart` | Tri chronologique |
| **Afficher info compte** | `lib/screens/utilisateur/profile/profile_screen.dart` | Profil utilisateur |


### ⚙️ Fonctionnalités avancées

| Fonctionnalité | Fichier | Description |
|---|---|---|
| **Possible ajouter note** | `lib/screens/utilisateur/reservation/trip_summary_screen.dart` | Champ de note pour chauffeur |
| **Réservation impossible tant que pas accepté** | `lib/screens/utilisateur/reservation/reservation_detail_screen.dart` | Logique de validation |
| **Changer état réservation** | `lib/data/services/reservation_service.dart` | Service de mise à jour statut |
| **Annulation de la course** | `lib/screens/utilisateur/reservation/reservation_detail_screen.dart` | Fonction d'annulation |
| **Bouton déconnexion** | `lib/screens/admin/profile/admin_profile_screen.dart` | Déconnexion admin |

---

## Points d'attention pour les développeurs

### 🔧 Configuration requise
1. **Clés API Google Maps** : Configurer dans `lib/constants.dart`
2. **Firebase** : Vérifier la configuration dans `lib/firebase/`
3. **Permissions** : Android manifest configuré pour géolocalisation et appels

### 🎨 Design System
- Utiliser exclusivement les composants `GlassContainer`, `GlassButton`, etc.
- Respecter la palette de couleurs `AppColors`
- Police Poppins obligatoire via `AppConstants.defaultTextStyle`

### 🗄️ Base de données
- Structure Firestore bien définie
- Gestion des rôles utilisateur (user/admin)
- Statuts de réservation cohérents

### 📱 Navigation
- Routes définies dans `main.dart`
- Navigation conditionnelle selon le rôle utilisateur
- Gestion des états de navigation

### 🔐 Sécurité
- Authentification Firebase
- Validation des rôles utilisateur
- Gestion des sessions persistantes

---

*Ce manuel technique est maintenu à jour avec l'évolution du projet. Pour toute question, se référer aux commentaires dans le code ou contacter l'équipe de développement.*
