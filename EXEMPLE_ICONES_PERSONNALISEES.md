# Exemple d'Utilisation des Icônes Personnalisées

## Icône Actuelle
Vous utilisez actuellement l'icône `man-walking_1f6b6-200d-2642-fe0f.png` pour la localisation de l'utilisateur.

## Comment ajouter d'autres icônes personnalisées

### 1. Pour la destination
```dart
_destinationIcon = await CustomMarkerService.createDestinationIcon(
  customIconPath: 'assets/icons/destination-icon.png',
);
```

### 2. Pour le départ
```dart
_departureIcon = await CustomMarkerService.createDepartureIcon(
  customIconPath: 'assets/icons/departure-icon.png',
);
```

### 3. Mélange d'icônes personnalisées et par défaut
```dart
Future<void> _initializeCustomIcons() async {
  // Icône personnalisée pour la localisation utilisateur
  _userLocationIcon = await CustomMarkerService.createUserLocationIcon(
    customIconPath: 'assets/icons/man-walking_1f6b6-200d-2642-fe0f.png',
  );
  
  // Icône par défaut pour la destination (cercle rouge)
  _destinationIcon = await CustomMarkerService.createDestinationIcon(
    backgroundColor: const Color(0xFFE53E3E),
    iconColor: Colors.white,
  );
}
```

## Recommandations pour les icônes

### Taille recommandée
- **Format** : PNG avec transparence
- **Taille** : 120x120 pixels (pour un affichage net à 60x60)
- **Style** : Icônes simples et reconnaissables

### Suggestions d'icônes
- **Localisation utilisateur** : Personne qui marche, point de localisation, avatar
- **Destination** : Drapeau, maison, bâtiment, étoile
- **Départ** : Flèche, point de départ, cercle avec flèche

## Test de l'icône actuelle

Votre icône `man-walking_1f6b6-200d-2642-fe0f.png` devrait maintenant s'afficher sur la carte à la place de l'icône de localisation par défaut. L'icône sera automatiquement redimensionnée à 60x60 pixels pour l'affichage sur la carte.
