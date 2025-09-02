# Structure Firestore - My Mobility Services

## Collection: `reservations`

### Document Structure
```json
{
  "id": "string",                    // ID unique de la réservation
  "userId": "string",                // ID de l'utilisateur (Firebase Auth UID)
  "vehicleName": "string",           // Nom du véhicule (ex: "Bolt", "Comfort")
  "departure": "string",             // Adresse de départ
  "destination": "string",           // Adresse de destination
  "selectedDate": "timestamp",       // Date sélectionnée
  "selectedTime": "string",          // Heure au format HH:mm
  "estimatedArrival": "string",      // Heure d'arrivée estimée
  "paymentMethod": "string",         // Méthode de paiement (ex: "Espèces", "Apple Pay")
  "totalPrice": "number",            // Prix total
  "status": "string",                // Statut: "pending", "confirmed", "inProgress", "completed", "cancelled"
  "createdAt": "timestamp",          // Date de création
  "updatedAt": "timestamp",          // Date de dernière mise à jour (optionnel)
  "departureCoordinates": {          // Coordonnées de départ (optionnel)
    "latitude": "number",
    "longitude": "number"
  },
  "destinationCoordinates": {        // Coordonnées de destination (optionnel)
    "latitude": "number",
    "longitude": "number"
  }
}
```

### Exemple de document
```json
{
  "id": "res_123456789",
  "userId": "user_abc123",
  "vehicleName": "Bolt",
  "departure": "Ma position actuelle",
  "destination": "Gare Montparnasse",
  "selectedDate": "2024-01-15T00:00:00Z",
  "selectedTime": "22:00",
  "estimatedArrival": "22:13",
  "paymentMethod": "Espèces",
  "totalPrice": 28.1,
  "status": "pending",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": null,
  "departureCoordinates": {
    "latitude": 48.8566,
    "longitude": 2.3522
  },
  "destinationCoordinates": {
    "latitude": 48.8584,
    "longitude": 2.2945
  }
}
```

## Règles de sécurité Firestore (à configurer)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Réservations - l'utilisateur peut lire/écrire ses propres réservations
    match /reservations/{reservationId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.auth.uid in resource.data.userId);
    }
    
    // Les conducteurs peuvent lire les réservations en attente
    match /reservations/{reservationId} {
      allow read: if request.auth != null && 
        resource.data.status == 'pending';
    }
  }
}
```

## Index Firestore requis

### Index composé pour les requêtes utilisateur
- Collection: `reservations`
- Champs: `userId` (Ascending), `createdAt` (Descending)

### Index composé pour les réservations en attente
- Collection: `reservations`
- Champs: `status` (Ascending), `createdAt` (Ascending)

## Statuts des réservations

1. **pending** - En attente (par défaut)
2. **confirmed** - Confirmée par un conducteur
3. **inProgress** - En cours (conducteur en route)
4. **completed** - Terminée
5. **cancelled** - Annulée

## Prochaines étapes

1. Configurer les règles de sécurité Firestore
2. Créer les index nécessaires
3. Implémenter l'authentification utilisateur
4. Créer l'interface conducteur pour voir les réservations en attente
5. Ajouter la géolocalisation en temps réel
6. Implémenter les notifications push
