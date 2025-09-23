import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../l10n/generated/app_localizations.dart';

enum CustomOfferStatus {
  pending, // En attente de réponse du chauffeur
  accepted, // Acceptée par le chauffeur avec prix fixé
  rejected, // Rejetée par le chauffeur
  confirmed, // Confirmée et payée par le client
  inProgress, // En cours
  completed, // Terminée
  cancelled, // Annulée
}

// Extension pour obtenir le statut localisé
extension CustomOfferStatusExtension on CustomOfferStatus {
  String getLocalizedStatus(context) {
    final localizations = AppLocalizations.of(context);
    switch (this) {
      case CustomOfferStatus.pending:
        return localizations.customOfferStatusPending;
      case CustomOfferStatus.accepted:
        return localizations.customOfferStatusAccepted;
      case CustomOfferStatus.rejected:
        return localizations.customOfferStatusRejected;
      case CustomOfferStatus.confirmed:
        return localizations.customOfferStatusConfirmed;
      case CustomOfferStatus.inProgress:
        return localizations.customOfferStatusInProgress;
      case CustomOfferStatus.completed:
        return localizations.customOfferStatusCompleted;
      case CustomOfferStatus.cancelled:
        return localizations.customOfferStatusCancelled;
    }
  }

  // Version legacy pour compatibilité
  String get statusInFrench {
    switch (this) {
      case CustomOfferStatus.pending:
        return 'En attente';
      case CustomOfferStatus.accepted:
        return 'Acceptée';
      case CustomOfferStatus.rejected:
        return 'Rejetée';
      case CustomOfferStatus.confirmed:
        return 'Confirmée';
      case CustomOfferStatus.inProgress:
        return 'En cours';
      case CustomOfferStatus.completed:
        return 'Terminée';
      case CustomOfferStatus.cancelled:
        return 'Annulée';
    }
  }
}

class CustomOffer {
  final String id;
  final String userId;
  final String? userName; // Nom de l'utilisateur
  final String departure;
  final String destination;
  final int durationHours; // Durée en heures
  final int durationMinutes; // Durée en minutes (0-59)
  final String? clientNote; // Note du client pour le chauffeur
  final CustomOfferStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? departureCoordinates;
  final Map<String, dynamic>? destinationCoordinates;
  
  // Champs ajoutés quand le chauffeur accepte
  final String? driverId; // ID du chauffeur qui accepte
  final String? driverName; // Nom du chauffeur
  final double? proposedPrice; // Prix proposé par le chauffeur
  final String? driverMessage; // Message du chauffeur
  final DateTime? acceptedAt; // Date d'acceptation par le chauffeur
  
  // Champs pour le paiement (une fois confirmé)
  final String? paymentMethod;
  final DateTime? confirmedAt; // Date de confirmation et paiement

  CustomOffer({
    required this.id,
    required this.userId,
    this.userName,
    required this.departure,
    required this.destination,
    required this.durationHours,
    required this.durationMinutes,
    this.clientNote,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.departureCoordinates,
    this.destinationCoordinates,
    this.driverId,
    this.driverName,
    this.proposedPrice,
    this.driverMessage,
    this.acceptedAt,
    this.paymentMethod,
    this.confirmedAt,
  });

  // Convertir en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'departure': departure,
      'destination': destination,
      'durationHours': durationHours,
      'durationMinutes': durationMinutes,
      'clientNote': clientNote,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'departureCoordinates': departureCoordinates,
      'destinationCoordinates': destinationCoordinates,
      'driverId': driverId,
      'driverName': driverName,
      'proposedPrice': proposedPrice,
      'driverMessage': driverMessage,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'paymentMethod': paymentMethod,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
    };
  }

  // Créer depuis un document Firebase
  factory CustomOffer.fromMap(Map<String, dynamic> map) {
    return CustomOffer(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'],
      departure: map['departure'] ?? '',
      destination: map['destination'] ?? '',
      durationHours: map['durationHours'] ?? 0,
      durationMinutes: map['durationMinutes'] ?? 0,
      clientNote: map['clientNote'],
      status: CustomOfferStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CustomOfferStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      departureCoordinates: map['departureCoordinates'],
      destinationCoordinates: map['destinationCoordinates'],
      driverId: map['driverId'],
      driverName: map['driverName'],
      proposedPrice: map['proposedPrice'] != null 
          ? (map['proposedPrice'] as num).toDouble() 
          : null,
      driverMessage: map['driverMessage'],
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      paymentMethod: map['paymentMethod'],
      confirmedAt: map['confirmedAt'] != null
          ? (map['confirmedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Copier avec modifications
  CustomOffer copyWith({
    String? id,
    String? userId,
    String? userName,
    String? departure,
    String? destination,
    int? durationHours,
    int? durationMinutes,
    String? clientNote,
    CustomOfferStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? departureCoordinates,
    Map<String, dynamic>? destinationCoordinates,
    String? driverId,
    String? driverName,
    double? proposedPrice,
    String? driverMessage,
    DateTime? acceptedAt,
    String? paymentMethod,
    DateTime? confirmedAt,
  }) {
    return CustomOffer(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      departure: departure ?? this.departure,
      destination: destination ?? this.destination,
      durationHours: durationHours ?? this.durationHours,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      clientNote: clientNote ?? this.clientNote,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      departureCoordinates: departureCoordinates ?? this.departureCoordinates,
      destinationCoordinates: destinationCoordinates ?? this.destinationCoordinates,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      driverMessage: driverMessage ?? this.driverMessage,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  // Obtenir le statut en français
  String get statusInFrench {
    switch (status) {
      case CustomOfferStatus.pending:
        return 'En attente';
      case CustomOfferStatus.accepted:
        return 'Acceptée';
      case CustomOfferStatus.rejected:
        return 'Rejetée';
      case CustomOfferStatus.confirmed:
        return 'Confirmée';
      case CustomOfferStatus.inProgress:
        return 'En cours';
      case CustomOfferStatus.completed:
        return 'Terminée';
      case CustomOfferStatus.cancelled:
        return 'Annulée';
    }
  }

  // Obtenir la durée formatée
  String get formattedDuration {
    if (durationHours > 0 && durationMinutes > 0) {
      return '${durationHours}h ${durationMinutes}min';
    } else if (durationHours > 0) {
      return '${durationHours}h';
    } else {
      return '${durationMinutes}min';
    }
  }
}
