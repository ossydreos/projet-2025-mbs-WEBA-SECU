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
  simple, // Demande simple
  customOffer, // Offre personnalisée
  counterOffer, // Contre offre
}

/// Classe pour gérer les filtres de réservation
class ReservationFilter {
  final ReservationFilterType filterType;
  final ReservationSortType sortType;
  final ReservationTypeFilter typeFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool
  isUpcoming; // true pour les courses à venir, false pour les terminées

  const ReservationFilter({
    this.filterType = ReservationFilterType.all,
    this.sortType = ReservationSortType.dateDescending, // Plus récents en haut par défaut
    this.typeFilter = ReservationTypeFilter.all,
    this.startDate,
    this.endDate,
    this.isUpcoming = true,
  });

  /// Créer une copie avec des modifications
  ReservationFilter copyWith({
    ReservationFilterType? filterType,
    ReservationSortType? sortType,
    ReservationTypeFilter? typeFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool? isUpcoming,
  }) {
    return ReservationFilter(
      filterType: filterType ?? this.filterType,
      sortType: sortType ?? this.sortType,
      typeFilter: typeFilter ?? this.typeFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
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
          return 'Création (ancienne → récente)';
        case ReservationSortType.dateDescending:
          return 'Création (récente → ancienne)';
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
      case ReservationTypeFilter.simple:
        return 'Demande simple';
      case ReservationTypeFilter.customOffer:
        return 'Offre personnalisée';
      case ReservationTypeFilter.counterOffer:
        return 'Contre offre';
    }
  }

  /// Appliquer le filtre à une liste de réservations
  List<Reservation> applyFilter(List<Reservation> reservations) {
    List<Reservation> filtered = List.from(reservations);

    // Filtrer selon la nouvelle logique métier (isPaid/isCompleted)
    if (isUpcoming) {
      // Pour les courses à venir : SEULEMENT les courses avec paiement confirmé (inProgress)
      print(
        '🔍 Filtrage des courses à venir - Total avant filtre: ${filtered.length}',
      );
      filtered = filtered
          .where(
            (r) => r.status == ReservationStatus.inProgress && !r.isCompleted,
          )
          .toList();
      print('🔍 Courses à venir après filtre: ${filtered.length}');
      print(
        '🔍 Statuts des courses filtrées: ${filtered.map((r) => r.status.name).toList()}',
      );
    } else {
      // Pour les courses terminées : SEULEMENT les courses terminées (pas les annulées)
      filtered = filtered
          .where(
            (r) => r.isCompleted || r.status == ReservationStatus.completed,
          )
          .toList();
    }

    // Filtrer par type de réservation
    switch (filterType) {
      case ReservationFilterType.all:
        break;
      case ReservationFilterType.demand:
        filtered = filtered
            .where((r) => r.status == ReservationStatus.pending)
            .toList();
        break;
      case ReservationFilterType.counterOffer:
        filtered = filtered.where((r) => r.hasCounterOffer).toList();
        break;
      case ReservationFilterType.dateRange:
        if (startDate != null) {
          filtered = filtered
              .where(
                (r) =>
                    r.selectedDate.isAfter(startDate!) ||
                    r.selectedDate.isAtSameMomentAs(startDate!),
              )
              .toList();
        }
        if (endDate != null) {
          filtered = filtered
              .where(
                (r) =>
                    r.selectedDate.isBefore(endDate!) ||
                    r.selectedDate.isAtSameMomentAs(endDate!),
              )
              .toList();
        }
        break;
    }

    // Filtrer par type de réservation
    if (typeFilter != ReservationTypeFilter.all) {
      switch (typeFilter) {
        case ReservationTypeFilter.simple:
          filtered = filtered
              .where(
                (r) =>
                    !r.hasCounterOffer && r.status == ReservationStatus.pending,
              )
              .toList();
          break;
        case ReservationTypeFilter.customOffer:
          filtered = filtered.where((r) => r.hasCounterOffer).toList();
          break;
        case ReservationTypeFilter.counterOffer:
          filtered = filtered
              .where(
                (r) =>
                    r.hasCounterOffer &&
                    r.status == ReservationStatus.confirmed,
              )
              .toList();
          break;
        case ReservationTypeFilter.all:
          break;
      }
    }

    // Appliquer le tri
    switch (sortType) {
      case ReservationSortType.dateAscending:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ReservationSortType.dateDescending:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
}
