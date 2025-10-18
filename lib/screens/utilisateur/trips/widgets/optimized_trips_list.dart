import 'package:flutter/material.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/screens/utilisateur/trips/widgets/trip_card_v2.dart';
import 'package:my_mobility_services/screens/utilisateur/trips/state/trip_selection_controller.dart';

/// Liste optimisée des trajets avec pagination et lazy loading
class OptimizedTripsList extends StatefulWidget {
  final List<Reservation> reservations;
  final bool isUpcoming;
  final TripSelectionController selectionController;
  final Function(Reservation)? onTripTap;
  final Function(Reservation)? onChat;
  final Function(Reservation)? onRebook;
  final Function(Reservation)? onShowReceipt;

  const OptimizedTripsList({
    super.key,
    required this.reservations,
    required this.isUpcoming,
    required this.selectionController,
    this.onTripTap,
    this.onChat,
    this.onRebook,
    this.onShowReceipt,
  });

  @override
  State<OptimizedTripsList> createState() => _OptimizedTripsListState();
}

class _OptimizedTripsListState extends State<OptimizedTripsList> {
  static const int _itemsPerPage = 20;
  int _currentPage = 0;
  late List<Reservation> _displayedReservations;

  @override
  void initState() {
    super.initState();
    _updateDisplayedReservations();
  }

  @override
  void didUpdateWidget(OptimizedTripsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reservations != widget.reservations) {
      _currentPage = 0;
      _updateDisplayedReservations();
    }
  }

  void _updateDisplayedReservations() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, widget.reservations.length);
    _displayedReservations = widget.reservations.sublist(0, endIndex);
  }

  void _loadMore() {
    if (_displayedReservations.length < widget.reservations.length) {
      setState(() {
        _currentPage++;
        _updateDisplayedReservations();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: t.spaceMd),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Load more items when approaching the end
            if (index == _displayedReservations.length - 5) {
              _loadMore();
            }
            
            if (index >= _displayedReservations.length) {
              return null;
            }
            
            final reservation = _displayedReservations[index];
            return RepaintBoundary(
              child: Padding(
                padding: EdgeInsets.only(bottom: t.spaceSm),
                child: TripCardV2(
                  key: ValueKey('${reservation.id}_${widget.selectionController.exportMode}'),
                  type: reservation.type,
                  reservationId: reservation.id,
                  vehicleTitle: reservation.vehicleName,
                  fromAddress: reservation.departure,
                  toAddress: reservation.destination,
                  startAt: reservation.selectedDate,
                  endAt: reservation.driverProposedDate ?? _calculateEndTime(reservation),
                  status: _getStatusText(reservation.status),
                  paymentLabel: reservation.paymentMethod,
                  priceFormatted: '${reservation.totalPrice.toStringAsFixed(0)}€',
                  isUpcoming: widget.isUpcoming,
                  isSelected: widget.selectionController.exportMode && 
                             widget.selectionController.isSelected(reservation.id),
                  isSelectionMode: widget.selectionController.exportMode,
                  onSelectionToggle: widget.selectionController.exportMode 
                      ? () => widget.selectionController.toggle(reservation.id)
                      : null,
                  onTap: () => widget.onTripTap?.call(reservation),
                  onChat: () => widget.onChat?.call(reservation),
                ),
              ),
            );
          },
          childCount: _displayedReservations.length,
        ),
      ),
    );
  }

  DateTime? _calculateEndTime(Reservation reservation) {
    // Logique de calcul de l'heure de fin
    return reservation.selectedDate.add(const Duration(hours: 1));
  }

  String _getStatusText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppLocalizations.of(context).pending;
      case ReservationStatus.confirmed:
        return AppLocalizations.of(context).confirmed;
      case ReservationStatus.completed:
        return AppLocalizations.of(context).completed;
      case ReservationStatus.cancelled:
        return AppLocalizations.of(context).cancelled;
      default:
        return AppLocalizations.of(context).unknown;
    }
  }
}
