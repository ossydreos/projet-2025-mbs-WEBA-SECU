# 🌍 Guide d'internationalisation - My Mobility Services

## ✅ Configuration terminée avec succès

L'internationalisation a été entièrement configurée et est prête à fonctionner. Voici comment l'utiliser :

---

## 📱 Fonctionnement automatique

L'application détecte automatiquement la langue de l'appareil :
- **Français** → Interface en français
- **Anglais** → Interface en anglais
- **Autre langue** → Fallback vers français

---

## 🔧 Comment utiliser la localisation

### Dans les widgets Flutter :

```dart
import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Column(
      children: [
        Text(localizations.welcome), // "Bienvenue" ou "Welcome"
        ElevatedButton(
          onPressed: () {},
          child: Text(localizations.login), // "Se connecter" ou "Login"
        ),
        Text(localizations.loading), // "Chargement..." ou "Loading..."
      ],
    );
  }
}
```

### Avec le helper utilitaire :

```dart
import '../utils/localization_helper.dart';

// Formatage des prix
String price = LocalizationHelper.formatPrice(context, 25.50);
// FR: "25,50 €" | EN: "€25.50"

// Formatage des durées
String duration = LocalizationHelper.formatDuration(context, 90);
// FR: "Temps estimé 1h 30min" | EN: "Estimated time 1h 30min"

// Vérifier la langue actuelle
if (LocalizationHelper.isFrench(context)) {
  // Code spécifique au français
}
```

### Extensions localisées pour les enums :

```dart
// Statuts de réservation
String status = reservation.status.getLocalizedStatus(context);
// FR: "En attente" | EN: "Pending"

// Catégories de véhicules
String category = vehicle.category.getLocalizedCategory(context);
// FR: "Luxe" | EN: "Luxury"

// Rôles utilisateur
String role = user.getLocalizedRole(context);
// FR: "Administrateur" | EN: "Administrator"
```

---

## 📝 Textes disponibles

### Navigation et actions
- `appTitle` - Titre de l'app
- `welcome` - Message de bienvenue
- `login` / `signup` - Connexion/Inscription
- `home`, `reservations`, `trips`, `profile`, `offers` - Navigation
- `bookNow`, `cancel`, `confirm` - Actions

### Statuts de réservation
- `reservationStatusPending` - En attente / Pending
- `reservationStatusConfirmed` - Confirmée / Confirmed
- `reservationStatusInProgress` - En cours / In Progress
- `reservationStatusCompleted` - Terminée / Completed
- `reservationStatusCancelled` - Annulée / Cancelled

### Catégories de véhicules
- `vehicleCategoryLuxe` - Luxe / Luxury
- `vehicleCategoryVan` - Van / Van
- `vehicleCategoryEconomique` - Économique / Economy

### Messages d'erreur
- `errorInvalidEmail` - Email invalide / Invalid email
- `errorEmptyField` - Champ vide / Empty field
- `errorNetworkError` - Erreur réseau / Network error
- Et bien d'autres...

### Messages de succès
- `successReservationCreated` - Réservation créée / Reservation created
- `successProfileUpdated` - Profil mis à jour / Profile updated
- Et d'autres...

---

## 🔄 Ajouter de nouvelles traductions

### 1. Ajouter dans `lib/l10n/app_fr.arb` :
```json
{
  "newText": "Nouveau texte",
  "@newText": {
    "description": "Description du nouveau texte"
  }
}
```

### 2. Ajouter dans `lib/l10n/app_en.arb` :
```json
{
  "newText": "New text",
  "@newText": {
    "description": "Description of the new text"
  }
}
```

### 3. Régénérer les fichiers :
```bash
flutter gen-l10n
```

### 4. Utiliser dans le code :
```dart
Text(localizations.newText)
```

---

## 📱 Textes avec paramètres

### Définition dans les ARB :
```json
{
  "welcomeUser": "Bienvenue {userName}",
  "@welcomeUser": {
    "description": "Message de bienvenue personnalisé",
    "placeholders": {
      "userName": {
        "type": "String"
      }
    }
  }
}
```

### Utilisation :
```dart
Text(localizations.welcomeUser("Jean"))
// FR: "Bienvenue Jean"
// EN: "Welcome Jean"
```

---

## 🎯 Bonnes pratiques

### 1. **Toujours utiliser les localisations**
```dart
// ❌ Éviter
Text("Réserver maintenant")

// ✅ Préférer
Text(localizations.bookNow)
```

### 2. **Utiliser le helper pour les formats**
```dart
// ❌ Format codé en dur
Text("${price.toStringAsFixed(2)} €")

// ✅ Format localisé
Text(LocalizationHelper.formatPrice(context, price))
```

### 3. **Extensions pour les enums**
```dart
// ❌ Switch manuel
String getStatusText(ReservationStatus status) {
  switch (status) {
    case ReservationStatus.pending:
      return "En attente";
    // ...
  }
}

// ✅ Extension localisée
Text(reservation.status.getLocalizedStatus(context))
```

---

## 🚀 Avantages obtenus

- ✅ **Détection automatique** de la langue
- ✅ **Support complet** français/anglais
- ✅ **Formatage intelligent** des prix et durées
- ✅ **Extensions pratiques** pour les enums
- ✅ **Helper utilitaire** pour les cas complexes
- ✅ **Fallback sécurisé** vers le français
- ✅ **Performance optimisée** (génération à la compilation)

---

## 🔧 Résolution de problèmes

### Si les traductions ne s'affichent pas :
1. Vérifier que `AppLocalizations.of(context)` ne retourne pas null
2. S'assurer que `MaterialApp` a les `localizationsDelegates` configurés
3. Régénérer avec `flutter gen-l10n`

### Pour ajouter une nouvelle langue :
1. Créer `lib/l10n/app_XX.arb` (XX = code langue)
2. Ajouter `Locale('XX', '')` dans `supportedLocales`
3. Régénérer les fichiers

---

## 📊 Fichiers modifiés

- ✅ `pubspec.yaml` - Dépendances ajoutées
- ✅ `l10n.yaml` - Configuration
- ✅ `lib/main.dart` - Configuration MaterialApp
- ✅ `lib/l10n/app_fr.arb` - Traductions françaises
- ✅ `lib/l10n/app_en.arb` - Traductions anglaises
- ✅ `lib/utils/localization_helper.dart` - Helper utilitaire
- ✅ `lib/data/models/*.dart` - Extensions localisées

L'internationalisation est maintenant **complètement fonctionnelle** ! 🎉
