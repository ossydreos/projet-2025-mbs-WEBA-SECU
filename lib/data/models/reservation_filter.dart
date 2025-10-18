import 'package:my_mobility_services/data/models/reservation.dart';

/// Enum pour les types de filtres de réservation
enum ReservationFilterType {
  all, // Toutes les réservations
  demand, // Demandes de réservation (pending)
  counterOffer, // Contre-offres (confirmed avec hasCounterOffer = true)
  dateRange, // Filtrage par plage de dates
}

/// Enum pour les types de tri
enum ReservationSortType {
  dateAscending, // Plus ancienne à plus récente
  dateDescending, // Plus récente à plus ancienne
  priceAscending, // Prix croissant
  priceDescending, // Prix décroissant
}

/// Enum pour les types de réservation (pour le filtrage)
enum ReservationTypeFilter {
  all, // Tous les types
  reservation, // Réservation normale
  offer, // Offre personnalisée
}

/// Classe pour gérer les filtres de réservation
class ReservationFilter {
  static const Object _noValue = Object();
  final ReservationFilterType filterType;
  final ReservationSortType sortType;
  final ReservationTypeFilter typeFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool
  isUpcoming; // true pour les courses à venir, false pour les terminées

  const ReservationFilter({
    this.filterType = ReservationFilterType.all,
    ReservationSortType? sortType,
    this.typeFilter = ReservationTypeFilter.all,
    this.startDate,
    this.endDate,
    bool isUpcoming = true,
  })  : isUpcoming = isUpcoming,
        sortType = sortType ??
            (isUpcoming
                ? ReservationSortType.dateAscending
                : ReservationSortType.dateDescending);

  /// Créer une copie avec des modifications
  ReservationFilter copyWith({
    ReservationFilterType? filterType,
    ReservationSortType? sortType,
    ReservationTypeFilter? typeFilter,
    Object? startDate = _noValue,
    Object? endDate = _noValue,
    bool? isUpcoming,
  }) {
    return ReservationFilter(
      filterType: filterType ?? this.filterType,
      sortType: sortType ?? this.sortType,
      typeFilter: typeFilter ?? this.typeFilter,
      startDate: startDate == _noValue ? this.startDate : startDate as DateTime?,
      endDate: endDate == _noValue ? this.endDate : endDate as DateTime?,
      isUpcoming: isUpcoming ?? this.isUpcoming,
    );
  }

  /// Vérifier si un filtre est actif
  bool get hasActiveFilter {
    return filterType != ReservationFilterType.all ||
        typeFilter != ReservationTypeFilter.all ||
        startDate != null ||
        endDate != null;
  }

  /// Obtenir le texte descriptif du filtre
  String getFilterDescription() {
    final List<String> descriptions = [];

    if (filterType == ReservationFilterType.demand) {
      descriptions.add('Demandes de réservation');
    } else if (filterType == ReservationFilterType.counterOffer) {
      descriptions.add('Contre-offres');
    }

    if (typeFilter != ReservationTypeFilter.all) {
      descriptions.add('Type: ${_getTypeText(typeFilter)}');
    }

    if (startDate != null || endDate != null) {
      final start = startDate != null
          ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
          : 'Début';
      final end = endDate != null
          ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
          : 'Fin';
      descriptions.add('Période: $start - $end');
    }

    if (descriptions.isEmpty) {
      return 'Tous les filtres';
    }

    return descriptions.join(', ');
  }

  /// Obtenir le texte du tri
  String getSortDescription() {
    if (isUpcoming) {
      // Descriptions pour les courses à venir
      switch (sortType) {
        case ReservationSortType.dateAscending:
          return 'Départ (proche → lointain)';
        case ReservationSortType.dateDescending:
          return 'Départ (lointain → proche)';
        case ReservationSortType.priceAscending:
          return 'Prix (bas → élevé)';
        case ReservationSortType.priceDescending:
          return 'Prix (élevé → bas)';
      }
    } else {
      // Descriptions pour les courses terminées
      switch (sortType) {
        case ReservationSortType.dateAscending:
          return 'Création (ancienne → récente)';
        case ReservationSortType.dateDescending:
          return 'Création (récente → ancienne)';
        case ReservationSortType.priceAscending:
          return 'Prix (bas → élevé)';
        case ReservationSortType.priceDescending:
          return 'Prix (élevé → bas)';
      }
    }
  }

  String _getTypeText(ReservationTypeFilter type) {
    switch (type) {
      case ReservationTypeFilter.all:
        return 'Tous';
      case ReservationTypeFilter.reservation:
        return 'Réservation normale';
      case ReservationTypeFilter.offer:
        return 'Offre personnalisée';
    }
  }

  /// Appliquer le filtre à une liste de réservations
  List<Reservation> applyFilter(List<Reservation> reservations) {
    List<Reservation> filtered = List.from(reservations);

    // Filtrer selon la nouvelle logique métier (isPaid/isCompleted)
    if (isUpcoming) {
      // Pour les courses à venir : SEULEMENT les courses avec paiement confirmé (inProgress)
      filtered = filtered
          .where(
            (r) => r.status == ReservationStatus.inProgress && !r.isCompleted,
          )
          .toList();
    } else {
      // Pour les courses terminées : SEULEMENT les courses terminées (pas les annulées)
      filtered = filtered
          .where(
            (r) => r.isCompleted || r.status == ReservationStatus.completed,
          )
          .toList();
    }

    // Filtrer par type de réservation
    switch (typeFilter) {
      case ReservationTypeFilter.all:
        break;
      case ReservationTypeFilter.reservation:
        filtered = filtered
            .where((r) => r.type == ReservationType.reservation)
            .toList();
        break;
      case ReservationTypeFilter.offer:
        filtered = filtered
            .where((r) => r.type == ReservationType.offer)
            .toList();
        break;
    }

    // Filtrer par plage de dates (toujours appliqué si startDate ou endDate est défini)
    if (startDate != null) {
      // Normaliser startDate au début de la journée
      final startOfDay = DateTime(startDate!.year, startDate!.month, startDate!.day);
      filtered = filtered
          .where(
            (r) => r.selectedDate.isAfter(startOfDay) ||
                   r.selectedDate.isAtSameMomentAs(startOfDay),
          )
          .toList();
    }
    if (endDate != null) {
      // Normaliser endDate à la fin de la journée (23:59:59)
      final endOfDay = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
      filtered = filtered
          .where(
            (r) => r.selectedDate.isBefore(endOfDay) ||
                   r.selectedDate.isAtSameMomentAs(endOfDay),
          )
          .toList();
    }

    // Filtrer par type de réservation
    if (typeFilter != ReservationTypeFilter.all) {
      switch (typeFilter) {
        case ReservationTypeFilter.reservation:
          // Réservation normale
          filtered = filtered
              .where((r) => r.type == ReservationType.reservation)
              .toList();
          break;
        case ReservationTypeFilter.offer:
          // Offre personnalisée
          filtered = filtered
              .where((r) => r.type == ReservationType.offer)
              .toList();
          break;
        case ReservationTypeFilter.all:
          break;
      }
    }

    // Appliquer le tri
    final reference = DateTime.now();

    switch (sortType) {
      case ReservationSortType.dateAscending:
        filtered.sort(
          (a, b) => _compareReservationStartDateTime(a, b, reference),
        );
        break;
      case ReservationSortType.dateDescending:
        filtered.sort(
          (a, b) => _compareReservationStartDateTime(b, a, reference),
        );
        break;
      case ReservationSortType.priceAscending:
        filtered.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
        break;
      case ReservationSortType.priceDescending:
        filtered.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
        break;
    }

    return filtered;
  }

  DateTime _reservationStartDateTime(Reservation reservation) {
    if (reservation.driverProposedDate != null) {
      return _combineDateWithOptionalTime(
        reservation.driverProposedDate!,
        reservation.driverProposedTime,
      );
    }

    final DateTime selectedDate = reservation.selectedDate;
    if (_dateHasTimeComponent(selectedDate)) {
      return selectedDate;
    }

    return _combineDateWithOptionalTime(
      selectedDate,
      reservation.selectedTime.isNotEmpty ? reservation.selectedTime : null,
    );
  }

  int _compareReservationStartDateTime(
    Reservation a,
    Reservation b,
    DateTime reference,
  ) {
    final first = _reservationStartDateTime(a);
    final second = _reservationStartDateTime(b);

    final firstDelta = first.difference(reference);
    final secondDelta = second.difference(reference);

    final firstIsFuture = firstDelta >= Duration.zero;
    final secondIsFuture = secondDelta >= Duration.zero;

    if (firstIsFuture && !secondIsFuture) {
      return -1;
    }
    if (!firstIsFuture && secondIsFuture) {
      return 1;
    }

    final firstMagnitude = firstDelta.abs();
    final secondMagnitude = secondDelta.abs();

    final magnitudeComparison = firstMagnitude.compareTo(secondMagnitude);
    if (magnitudeComparison != 0) {
      return magnitudeComparison;
    }

    final startComparison = first.compareTo(second);
    if (startComparison != 0) {
      return startComparison;
    }

    return a.createdAt.compareTo(b.createdAt);
  }

  DateTime _combineDateWithOptionalTime(DateTime date, String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return date;
    }

    final _TimeComponents time = _parseTimeString(timeString);
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  bool _dateHasTimeComponent(DateTime date) {
    return date.hour != 0 ||
        date.minute != 0 ||
        date.second != 0 ||
        date.millisecond != 0 ||
        date.microsecond != 0;
  }

  _TimeComponents _parseTimeString(String? value) {
    if (value == null || value.isEmpty) {
      return const _TimeComponents(hour: 0, minute: 0);
    }

    final matches = RegExp(r'\d+').allMatches(value).toList();
    int hour = matches.isNotEmpty ? int.tryParse(matches[0].group(0)!) ?? 0 : 0;
    int minute = matches.length > 1 ? int.tryParse(matches[1].group(0)!) ?? 0 : 0;

    hour = hour % 24;
    minute = minute % 60;

    final lower = value.toLowerCase();
    if (lower.contains('pm') && hour < 12) {
      hour += 12;
    } else if (lower.contains('am') && hour == 12) {
      hour = 0;
    }

    return _TimeComponents(hour: hour, minute: minute);
  }
}

class _TimeComponents {
  final int hour;
  final int minute;

  const _TimeComponents({required this.hour, required this.minute});
}
