# Guide des Icônes Personnalisées pour les Marqueurs de Carte

## Vue d'ensemble

Ce guide explique comment personnaliser les icônes de marqueurs sur les cartes Google Maps dans l'application My Mobility Services.

## Fonctionnalités

### Icônes par défaut personnalisées
- **Localisation utilisateur** : Cercle bleu avec icône de localisation
- **Destination** : Cercle rouge avec icône de drapeau
- **Départ** : Cercle vert avec icône de lecture

### Support des icônes personnalisées
- Support des images PNG personnalisées
- Redimensionnement automatique (60x60 pixels)
- Fallback vers les icônes par défaut si l'asset n'est pas trouvé

## Utilisation

### 1. Icônes par défaut (recommandé)

```dart
// Initialisation dans initState()
Future<void> _initializeCustomIcons() async {
  _userLocationIcon = await CustomMarkerService.createUserLocationIcon(
    backgroundColor: const Color(0xFF2196F3), // Bleu
    iconColor: Colors.white,
  );
  _destinationIcon = await CustomMarkerService.createDestinationIcon(
    backgroundColor: const Color(0xFFE53E3E), // Rouge
    iconColor: Colors.white,
  );
}

// Utilisation dans les marqueurs
gmaps.Marker(
  markerId: const gmaps.MarkerId('user'),
  position: gmaps.LatLng(lat, lng),
  icon: _userLocationIcon ?? gmaps.BitmapDescriptor.defaultMarkerWithHue(
    gmaps.BitmapDescriptor.hueAzure,
  ),
)
```

### 2. Icônes personnalisées à partir d'assets

```dart
// Ajouter l'asset dans pubspec.yaml
flutter:
  assets:
    - assets/icons/user_location.png
    - assets/icons/destination.png

// Utilisation
_userLocationIcon = await CustomMarkerService.createUserLocationIcon(
  customIconPath: 'assets/icons/user_location.png',
);
```

### 3. Personnalisation des couleurs

```dart
// Icône de localisation avec couleurs personnalisées
_userLocationIcon = await CustomMarkerService.createUserLocationIcon(
  backgroundColor: const Color(0xFF10B981), // Vert
  iconColor: const Color(0xFFFFFFFF), // Blanc
);

// Icône de destination avec couleurs personnalisées
_destinationIcon = await CustomMarkerService.createDestinationIcon(
  backgroundColor: const Color(0xFF8B5CF6), // Violet
  iconColor: const Color(0xFFFFFFFF), // Blanc
);
```

## Spécifications techniques

### Taille des icônes
- **Taille par défaut** : 60x60 pixels
- **Format recommandé** : PNG avec transparence
- **Redimensionnement** : Automatique

### Couleurs par défaut
- **Localisation utilisateur** : `#2196F3` (Bleu)
- **Destination** : `#E53E3E` (Rouge)
- **Départ** : `#10B981` (Vert)

### Structure des fichiers
```
assets/
  icons/
    user_location.png      # Icône personnalisée pour la localisation
    destination.png        # Icône personnalisée pour la destination
    departure.png          # Icône personnalisée pour le départ
```

## Exemples d'implémentation

### Écran principal de réservation
```dart
class AccueilScreen extends StatefulWidget {
  // ...
  
  gmaps.BitmapDescriptor? _userLocationIcon;
  gmaps.BitmapDescriptor? _destinationIcon;
  
  @override
  void initState() {
    super.initState();
    _initializeCustomIcons();
    // ...
  }
  
  Future<void> _initializeCustomIcons() async {
    _userLocationIcon = await CustomMarkerService.createUserLocationIcon();
    _destinationIcon = await CustomMarkerService.createDestinationIcon();
  }
}
```

### Écran de réservation
```dart
class BookingScreen extends StatefulWidget {
  // ...
  
  gmaps.BitmapDescriptor? _departureIcon;
  gmaps.BitmapDescriptor? _destinationIcon;
  
  Future<void> _initializeCustomIcons() async {
    _departureIcon = await CustomMarkerService.createDepartureIcon();
    _destinationIcon = await CustomMarkerService.createDestinationIcon();
  }
}
```

## Bonnes pratiques

1. **Initialisation** : Toujours initialiser les icônes dans `initState()`
2. **Fallback** : Utiliser l'opérateur `??` pour fournir un fallback
3. **Performance** : Les icônes sont mises en cache automatiquement
4. **Cohérence** : Utiliser les mêmes couleurs dans toute l'application
5. **Assets** : Optimiser les images PNG pour de meilleures performances

## Dépannage

### L'icône ne s'affiche pas
- Vérifier que l'asset est déclaré dans `pubspec.yaml`
- Vérifier le chemin de l'asset
- Utiliser le fallback par défaut

### L'icône est floue
- Utiliser des images haute résolution (120x120 pour 60x60 affiché)
- Éviter les images trop petites

### Performance lente
- Les icônes sont mises en cache après la première création
- Éviter de recréer les icônes à chaque rebuild

## Personnalisation avancée

Pour des besoins spécifiques, vous pouvez modifier directement le service `CustomMarkerService` :

```dart
// Modifier la taille des icônes
static const double _markerSize = 80.0; // Au lieu de 60.0

// Ajouter de nouveaux styles d'icônes
static Future<BitmapDescriptor> createCustomIcon({
  required String iconType,
  required Color backgroundColor,
  required Color iconColor,
}) async {
  // Implémentation personnalisée
}
```
