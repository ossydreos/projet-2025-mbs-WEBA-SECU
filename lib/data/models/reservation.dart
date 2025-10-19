import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../l10n/generated/app_localizations.dart';

enum ReservationStatus {
  pending, // En attente
  confirmed, // Confirmée
  inProgress, // En cours
  completed, // Terminée
  cancelled, // Annulée
  cancelledAfterPayment, // Annulée après paiement
}

enum ReservationType {
  reservation, // Réservation normale
  offer, // Offre personnalisée
}

// Extension pour obtenir le statut localisé
extension ReservationStatusExtension on ReservationStatus {
  String getLocalizedStatus(context) {
    final localizations = AppLocalizations.of(context);
    switch (this) {
      case ReservationStatus.pending:
        return localizations.reservationStatusPending;
      case ReservationStatus.confirmed:
        return localizations.reservationStatusConfirmed;
      case ReservationStatus.inProgress:
        return localizations.reservationStatusInProgress;
      case ReservationStatus.completed:
        return localizations.reservationStatusCompleted;
      case ReservationStatus.cancelled:
        return localizations.reservationStatusCancelled;
      case ReservationStatus.cancelledAfterPayment:
        return localizations.reservationStatusCancelled;
    }
  }

  // Version legacy pour compatibilité
  String get statusInFrench {
    switch (this) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      case ReservationStatus.inProgress:
        return 'En cours';
      case ReservationStatus.completed:
        return 'Terminée';
      case ReservationStatus.cancelled:
        return 'Annulée';
      case ReservationStatus.cancelledAfterPayment:
        return 'Annulée après paiement';
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
  final bool hasCounterOffer; // Indique si une contre-offre a été proposée
  final DateTime? driverProposedDate; // Date proposée par le chauffeur
  final String? driverProposedTime; // Heure proposée par le chauffeur
  final String? adminMessage; // Message de l'admin pour la contre-offre
  // Promo
  final String? promoCode; // code appliqué
  final double? discountAmount; // montant de la remise en devise
  final ReservationType type; // Type de réservation (reservation ou offer)
  final bool? waitingForPayment; // en attente de paiement
  final bool isPaid; // Course payée par le client
  final bool isCompleted; // Course terminée (bouton terminer appuyé)
  final bool adminDismissed; // Notification admin déjà masquée
  final bool adminPending; // Réservation mise en attente par l'admin
  final DateTime? customStartDate; // Date effective pour les offres perso
  final String? customStartTime; // Heure effective pour les offres perso

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
    this.hasCounterOffer = false, // Valeur par défaut : false
    this.driverProposedDate,
    this.driverProposedTime,
    this.adminMessage,
    this.promoCode,
    this.discountAmount,
    this.type = ReservationType.reservation, // Valeur par défaut : réservation normale
    this.waitingForPayment,
    this.isPaid = false, // Valeur par défaut : false
    this.isCompleted = false, // Valeur par défaut : false
    this.adminDismissed = false, // Valeur par défaut : false
    this.adminPending = false, // Valeur par défaut : false
    this.customStartDate,
    this.customStartTime,
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
      'hasCounterOffer': hasCounterOffer,
      'driverProposedDate': driverProposedDate != null
          ? Timestamp.fromDate(driverProposedDate!)
          : null,
      'driverProposedTime': driverProposedTime,
      'adminMessage': adminMessage,
      'promoCode': promoCode,
      'discountAmount': discountAmount,
      'type': type.name,
      'waitingForPayment': waitingForPayment,
      'isPaid': isPaid,
      'isCompleted': isCompleted,
      'adminDismissed': adminDismissed,
      'adminPending': adminPending,
      'customStartDate': customStartDate != null
          ? Timestamp.fromDate(customStartDate!)
          : null,
      'customStartTime': customStartTime,
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
      selectedDate: map['selectedDate'] is Timestamp
          ? (map['selectedDate'] as Timestamp).toDate()
          : map['selectedDate'] as DateTime,
      selectedTime: map['selectedTime'] ?? '',
      estimatedArrival: map['estimatedArrival'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      status: ReservationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReservationStatus.pending,
      ),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] as DateTime,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
                ? (map['updatedAt'] as Timestamp).toDate()
                : map['updatedAt'] as DateTime)
          : null,
      departureCoordinates: map['departureCoordinates'],
      destinationCoordinates: map['destinationCoordinates'],
      clientNote: map['clientNote'],
      hasCounterOffer: map['hasCounterOffer'] ?? false,
      driverProposedDate: map['driverProposedDate'] != null
          ? (map['driverProposedDate'] is Timestamp
                ? (map['driverProposedDate'] as Timestamp).toDate()
                : map['driverProposedDate'] as DateTime)
          : null,
      driverProposedTime: map['driverProposedTime'],
      adminMessage: map['adminMessage'],
      promoCode: map['promoCode'],
      discountAmount: (map['discountAmount'] ?? 0.0) == 0.0
          ? null
          : (map['discountAmount'] as num).toDouble(),
      type: ReservationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReservationType.reservation,
      ),
      waitingForPayment: map['waitingForPayment'],
      isPaid: map['isPaid'] ?? false,
      isCompleted: map['isCompleted'] ?? false,
      adminDismissed: map['adminDismissed'] ?? false,
      adminPending: map['adminPending'] ?? false,
      customStartDate: map['customStartDate'] != null
          ? (map['customStartDate'] is Timestamp
                ? (map['customStartDate'] as Timestamp).toDate()
                : map['customStartDate'] as DateTime)
          : null,
      customStartTime: map['customStartTime'],
    );
  }

  DateTime get effectiveStartDateTime {
    if (type == ReservationType.offer && customStartDate != null) {
      return _combineDateWithOptionalTime(
        customStartDate!,
        customStartTime ?? _extractTimeFromDate(selectedDate) ?? selectedTime,
      );
    }

    return _combineDateWithOptionalTime(
      selectedDate,
      _extractTimeFromDate(selectedDate) ?? selectedTime,
    );
  }

  bool get isFutureRide => effectiveStartDateTime.isAfter(DateTime.now());

  DateTime _combineDateWithOptionalTime(DateTime date, String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return date;
    }

    final matches = RegExp(r'\d+').allMatches(timeString).toList();
    int hour = matches.isNotEmpty ? int.tryParse(matches[0].group(0)!) ?? 0 : 0;
    int minute = matches.length > 1 ? int.tryParse(matches[1].group(0)!) ?? 0 : 0;

    hour = hour % 24;
    minute = minute % 60;

    final lower = timeString.toLowerCase();
    if (lower.contains('pm') && hour < 12) {
      hour += 12;
    } else if (lower.contains('am') && hour == 12) {
      hour = 0;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  String? _extractTimeFromDate(DateTime date) {
    if (date.hour == 0 && date.minute == 0) {
      return null;
    }
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _dateHasTimeComponent(DateTime date) {
    return date.hour != 0 ||
        date.minute != 0 ||
        date.second != 0 ||
        date.millisecond != 0 ||
        date.microsecond != 0;
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
    bool? hasCounterOffer,
    DateTime? driverProposedDate,
    String? driverProposedTime,
    String? adminMessage,
    String? promoCode,
    double? discountAmount,
    ReservationType? type,
    bool? waitingForPayment,
    bool? isPaid,
    bool? isCompleted,
    bool? adminDismissed,
    bool? adminPending,
    DateTime? customStartDate,
    String? customStartTime,
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
      hasCounterOffer: hasCounterOffer ?? this.hasCounterOffer,
      driverProposedDate: driverProposedDate ?? this.driverProposedDate,
      driverProposedTime: driverProposedTime ?? this.driverProposedTime,
      adminMessage: adminMessage ?? this.adminMessage,
      promoCode: promoCode ?? this.promoCode,
      discountAmount: discountAmount ?? this.discountAmount,
      type: type ?? this.type,
      waitingForPayment: waitingForPayment ?? this.waitingForPayment,
      isPaid: isPaid ?? this.isPaid,
      isCompleted: isCompleted ?? this.isCompleted,
      adminDismissed: adminDismissed ?? this.adminDismissed,
      adminPending: adminPending ?? this.adminPending,
      customStartDate: customStartDate ?? this.customStartDate,
      customStartTime: customStartTime ?? this.customStartTime,
    );
  }

  // Obtenir le statut en français
  String get statusInFrench {
    switch (status) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.confirmed:
        return 'Confirmée';
      case ReservationStatus.inProgress:
        return 'En cours';
      case ReservationStatus.completed:
        return 'Terminée';
      case ReservationStatus.cancelled:
        return 'Annulée';
      case ReservationStatus.cancelledAfterPayment:
        return 'Annulée après paiement';
    }
  }
}
