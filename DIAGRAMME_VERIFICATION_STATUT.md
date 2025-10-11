# Diagramme de Vérification du Statut des Réservations

## Problème Identifié
L'admin peut accepter/refuser une réservation depuis la notification popup même si le client a déjà annulé entre temps.

## Solution Implémentée

### Avant (Problématique)
```
Notification Popup → Action Admin (Accepter/Refuser) → Mise à jour directe
                                                      ↑
                                              Pas de vérification
```

### Après (Sécurisé)
```
Notification Popup → Action Admin → Vérification Statut → Action Conditionnelle
                                      ↓
                              Statut = pending ? → OUI → Procéder à l'action
                                      ↓
                                      NON → Afficher erreur "Déjà traitée"
```

## Flux de Vérification

### 1. Acceptation de Réservation
```
_acceptReservation(reservationId)
    ↓
getReservationById(reservationId)
    ↓
reservation == null ? → OUI → Erreur "Réservation non trouvée"
    ↓
    NON
    ↓
reservation.status == pending ? → OUI → Procéder à l'acceptation
    ↓
    NON → Erreur "Cette réservation a déjà été traitée"
```

### 2. Refus de Réservation
```
_showRefusalOptions(reservation)
    ↓
_checkStatusAndDecline(reservationId)
    ↓
getReservationById(reservationId)
    ↓
reservation == null ? → OUI → Erreur "Réservation non trouvée"
    ↓
    NON
    ↓
reservation.status == pending ? → OUI → Procéder au refus
    ↓
    NON → Erreur "Cette réservation a déjà été traitée"
```

### 3. Contre-offre (Ouverture du dialogue)
```
_showCounterOfferDialog(reservation)
    ↓
_checkStatusAndShowCounterOffer(reservation)
    ↓
getReservationById(reservationId)
    ↓
reservation == null ? → OUI → Erreur "Réservation non trouvée"
    ↓
    NON
    ↓
reservation.status == pending ? → OUI → Afficher dialogue contre-offre
    ↓
    NON → Erreur "Cette réservation a déjà été traitée"
```

### 4. Contre-offre (Envoi effectif)
```
_sendCounterOffer(reservationId, newDate, newTime, message)
    ↓
getReservationById(reservationId)
    ↓
reservation == null ? → OUI → Erreur "Réservation non trouvée"
    ↓
    NON
    ↓
reservation.status == pending ? → OUI → Envoyer contre-offre
    ↓
    NON → Erreur "Cette réservation a déjà été traitée"
```

## Messages d'Erreur
- **Réservation non trouvée** : La réservation n'existe plus en base
- **Cette réservation a déjà été traitée** : Le statut n'est plus "pending"
- **Erreur lors de la vérification du statut** : Erreur technique lors de la vérification

## Avantages de la Solution
1. ✅ **Prévention des conflits** : Impossible d'accepter une réservation déjà annulée
2. ✅ **Feedback utilisateur** : Messages d'erreur clairs pour l'admin
3. ✅ **Robustesse** : Gestion des cas d'erreur (réservation supprimée, erreur réseau)
4. ✅ **Cohérence** : Même logique pour acceptation, refus et contre-offre
5. ✅ **Performance** : Vérification rapide avant action coûteuse

## Cas d'Usage Couverts
- ✅ Client annule → Admin essaie d'accepter → Erreur affichée
- ✅ Client annule → Admin essaie de refuser → Erreur affichée  
- ✅ Client annule → Admin essaie contre-offre → Erreur affichée
- ✅ Client annule → Admin ouvre dialogue contre-offre → Erreur affichée
- ✅ Client annule → Admin envoie contre-offre → Erreur affichée
- ✅ Réservation supprimée → Admin essaie action → Erreur affichée
- ✅ Erreur réseau → Admin essaie action → Erreur affichée
