import 'package:cloud_firestore/cloud_firestore.dart';

enum ReservationStatus {
  pending, // En attente
  confirmed, // Confirmée
  counterOffered, // Contre-offre proposée
  waitingPayment, // En attente de paiement
  inProgress, // En cours
  completed, // Terminée
  cancelled, // Annulée
}

// Extension pour obtenir le statut en français
extension ReservationStatusExtension on ReservationStatus {
  String get statusInFrench {
    switch (this) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      case ReservationStatus.counterOffered:
        return 'Contre-offre proposée';
      case ReservationStatus.waitingPayment:
        return 'En attente de paiement';
      case ReservationStatus.inProgress:
        return 'En cours';
      case ReservationStatus.completed:
        return 'Terminée';
      case ReservationStatus.cancelled:
        return 'Annulée';
    }
  }
}

class Reservation {
  final String id;
  final String userId;
  final String? userName; // Nom de l'utilisateur
  final String vehicleName;
  final String departure;
  final String destination;
  final DateTime selectedDate;
  final String selectedTime; // Format HH:mm
  final String estimatedArrival;
  final String paymentMethod;
  final double totalPrice;
  final ReservationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? departureCoordinates;
  final Map<String, dynamic>? destinationCoordinates;
  final String? clientNote; // Note du client pour le chauffeur
  final bool contreoffre; // 🆕 Champ contre-offre ajouté

  Reservation({
    required this.id,
    required this.userId,
    this.userName,
    required this.vehicleName,
    required this.departure,
    required this.destination,
    required this.selectedDate,
    required this.selectedTime,
    required this.estimatedArrival,
    required this.paymentMethod,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.departureCoordinates,
    this.destinationCoordinates,
    this.clientNote,
    this.contreoffre = false, // 🆕 Valeur par défaut : false
  });

  // Convertir en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'vehicleName': vehicleName,
      'departure': departure,
      'destination': destination,
      'selectedDate': Timestamp.fromDate(selectedDate),
      'selectedTime': selectedTime,
      'estimatedArrival': estimatedArrival,
      'paymentMethod': paymentMethod,
      'totalPrice': totalPrice,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'departureCoordinates': departureCoordinates,
      'destinationCoordinates': destinationCoordinates,
      'clientNote': clientNote,
      'contreoffre': contreoffre, // 🆕 Ajouté dans le mapping
    };
  }

  // Créer depuis un document Firebase
  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'],
      vehicleName: map['vehicleName'] ?? '',
      departure: map['departure'] ?? '',
      destination: map['destination'] ?? '',
      selectedDate: (map['selectedDate'] as Timestamp).toDate(),
      selectedTime: map['selectedTime'] ?? '',
      estimatedArrival: map['estimatedArrival'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReservationStatus.pending,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      departureCoordinates: map['departureCoordinates'],
      destinationCoordinates: map['destinationCoordinates'],
      clientNote: map['clientNote'],
      contreoffre:
          map['contreoffre'] ?? false, // 🆕 Ajouté avec valeur par défaut
    );
  }

  // Copier avec modifications
  Reservation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? vehicleName,
    String? departure,
    String? destination,
    DateTime? selectedDate,
    String? selectedTime,
    String? estimatedArrival,
    String? paymentMethod,
    double? totalPrice,
    ReservationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? departureCoordinates,
    Map<String, dynamic>? destinationCoordinates,
    String? clientNote,
    bool? contreoffre, // 🆕 Ajouté dans copyWith
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      vehicleName: vehicleName ?? this.vehicleName,
      departure: departure ?? this.departure,
      destination: destination ?? this.destination,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      departureCoordinates: departureCoordinates ?? this.departureCoordinates,
      destinationCoordinates:
          destinationCoordinates ?? this.destinationCoordinates,
      clientNote: clientNote ?? this.clientNote,
      contreoffre: contreoffre ?? this.contreoffre, // 🆕 Ajouté dans copyWith
    );
  }

  // Obtenir le statut en français
  String get statusInFrench {
    switch (status) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      case ReservationStatus.counterOffered:
        return 'Contre-offre proposée';
      case ReservationStatus.waitingPayment:
        return 'En attente de paiement';
      case ReservationStatus.inProgress:
        return 'En cours';
      case ReservationStatus.completed:
        return 'Terminée';
      case ReservationStatus.cancelled:
        return 'Annulée';
    }
  }

  // 🆕 Getter pour vérifier si une contre-offre a été envoyée
  bool get hasCounterOffer => contreoffre;
}
