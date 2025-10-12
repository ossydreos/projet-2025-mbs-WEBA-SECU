import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';
import 'package:my_mobility_services/design/widgets/primitives/glass_container.dart';
import 'package:my_mobility_services/data/models/reservation.dart';
import 'package:my_mobility_services/data/models/reservation_filter.dart';
import 'package:my_mobility_services/data/services/reservation_service.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';
import 'package:my_mobility_services/screens/ride_chat/ride_chat_screen.dart';
import 'package:my_mobility_services/design/filters/trips_filters_sheet.dart';
import 'package:my_mobility_services/screens/utilisateur/trips/widgets/trip_card_v2.dart';
import 'package:my_mobility_services/screens/utilisateur/trips/widgets/trip_export_bar.dart';
import 'package:my_mobility_services/screens/utilisateur/trips/widgets/optimized_trips_list.dart';
import 'package:my_mobility_services/screens/utilisateur/trips/widgets/trips_skeleton.dart';
import 'package:my_mobility_services/screens/utilisateur/trips/state/trip_selection_controller.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

/// AAA-grade iOS 26 Liquid Glass Trips Screen
/// Features: Large title, segmented control, glass cards, smooth animations
class TripsScreenRefined extends StatefulWidget {
  final Function(int)? onNavigate;
  final bool showBottomBar;

  const TripsScreenRefined({
    super.key,
    this.onNavigate,
    this.showBottomBar = true,
  });

  @override
  State<TripsScreenRefined> createState() => _TripsScreenRefinedState();
}

class _TripsScreenRefinedState extends State<TripsScreenRefined>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0; // 0: Upcoming, 1: Completed
  
  // Services
  final ReservationService _reservationService = ReservationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Filters
  ReservationFilter _upcomingFilter = const ReservationFilter(isUpcoming: true);
  ReservationFilter _completedFilter = const ReservationFilter(isUpcoming: false);
  ReservationSortType? _currentSortOption;
  
  // Selection controller for Export Mode (local-only UI state)
  final TripSelectionController _selection = TripSelectionController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _selection.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      // Exit export mode and clear selection when changing tabs
      _selection.clear();
    }
  }

  /// Toggle Export Mode for PDF export
  void _toggleSelectionMode() {
    _selection.toggleExportMode();
    print('Export Mode toggled: ${_selection.exportMode}');
  }

  /// Toggle selection of a reservation
  void _toggleReservationSelection(String reservationId) {
    _selection.toggle(reservationId);
  }

  /// Export selected reservations to PDF
  void _exportToPDF() async {
    if (_selection.selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).selectAtLeastOneReservation),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).generatingPdf(_selection.count)),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Get selected reservations data
      final selectedReservations = await _getSelectedReservationsData(_selection.selectedIds.toList());
      
      if (selectedReservations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).noDataFound),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Generate and show PDF
      await _generateAndShowPDF(selectedReservations);
      
      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pdfExportedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
      
      // Exit export mode after export
      _selection.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).exportError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Get selected reservations data from Firestore
  Future<List<Reservation>> _getSelectedReservationsData(List<String> ids) async {
    try {
      final currentFilter = _selectedTabIndex == 0 ? _upcomingFilter : _completedFilter;
      final allReservations = await _reservationService.getUserReservationsWithFilter(
        _auth.currentUser!.uid,
        currentFilter,
      );
      
      return allReservations
          .where((reservation) => ids.contains(reservation.id))
          .toList();
    } catch (e) {
      print('Error fetching selected reservations: $e');
      return [];
    }
  }

  /// Generate and show PDF with selected reservations
  Future<void> _generateAndShowPDF(List<Reservation> reservations) async {
    final pdf = pw.Document();
    
    // Add pages for each reservation
    for (int i = 0; i < reservations.length; i++) {
      final reservation = reservations[i];
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return _buildPDFPage(reservation, i + 1, reservations.length);
          },
        ),
      );
    }
    
    // Show PDF preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Réservations_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
  }

  /// Build a single PDF page for a reservation
  pw.Widget _buildPDFPage(Reservation reservation, int pageNumber, int totalPages) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Réservation #${reservation.id.substring(0, 8)}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                'Page $pageNumber/$totalPages',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.blue700,
                ),
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        // Reservation details
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Type and status
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    reservation.type == ReservationType.offer 
                        ? 'Offre personnalisée' 
                        : 'Réservation normale',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: reservation.type == ReservationType.offer 
                          ? PdfColors.orange700 
                          : PdfColors.blue700,
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: _getStatusColor(reservation.status),
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(
                      _getStatusText(reservation.status),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 16),
              
              // Vehicle and price
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Véhicule: ${reservation.vehicleName}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    '${reservation.totalPrice.toStringAsFixed(0)}€',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700,
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 16),
              
              // Addresses
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Départ:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    reservation.departure,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Arrivée:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    reservation.destination,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 16),
              
              // Date and time
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Date de départ:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          DateFormat('dd/MM/yyyy à HH:mm').format(reservation.selectedDate),
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  if (reservation.type == ReservationType.offer) ...[
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Date d\'arrivée:',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.Text(
                            _calculateEndTime(reservation) != null
                                ? DateFormat('dd/MM/yyyy à HH:mm').format(_calculateEndTime(reservation)!)
                                : 'Non spécifiée',
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              
              pw.SizedBox(height: 16),
              
              // Payment
              pw.Row(
                children: [
                  pw.Text(
                    'Paiement: ',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    reservation.paymentMethod,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        pw.SizedBox(height: 20),
        
        // Footer
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Get status color for PDF
  PdfColor _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return PdfColors.orange600;
      case ReservationStatus.confirmed:
        return PdfColors.blue600;
      case ReservationStatus.inProgress:
        return PdfColors.purple600;
      case ReservationStatus.completed:
        return PdfColors.green600;
      case ReservationStatus.cancelled:
        return PdfColors.red600;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final t = context.tokens;
    
    return AnimatedBuilder(
      animation: _selection,
      builder: (context, _) {
        final bool exportMode = _selection.exportMode;
        final media = MediaQuery.of(context);
        final bottomInset = media.viewPadding.bottom;
        const double barHeight = 84; // Match TripExportBar height for spacer
        // Add extra content spacer to keep scrolled content clear of the export bar and the bottom nav gap
        final double bottomSpacer = exportMode ? (barHeight + bottomInset + 24) : 0;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
              // Large Title Navigation Bar
              _buildLargeTitleNavBar(t),
              
          // Segmented Control
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(t.spaceMd, t.spaceSm, t.spaceMd, t.spaceSm),
              child: _buildSegmentedControl(t),
            ),
          ),
          
          // Extra space to fix overflow
          SliverToBoxAdapter(
            child: SizedBox(height: 7),
          ),
              
              // Content based on selected tab
              _selectedTabIndex == 0 ? _buildUpcomingContent(t) : _buildCompletedContent(t),

                  // Add bottom spacer so content never hides behind the export bar
                  SliverToBoxAdapter(
                    child: SizedBox(height: bottomSpacer),
                  ),
            ],
              ),
              
              // Dark scrim when in Export Mode (non-interactive so taps pass through)
              IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  opacity: exportMode ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Container(color: Colors.black),
                ),
              ),

              // Sticky bottom export bar
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  offset: exportMode ? Offset.zero : const Offset(0, 1),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: exportMode ? 1.0 : 0.0,
                    child: TripExportBar(
                      count: _selection.count,
                      onCancel: () {
                        _selection.clear();
                      },
                      onExport: _exportToPDF,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Large Title Navigation Bar with glass panel
  Widget _buildLargeTitleNavBar(AppTokens t) {
    return SliverAppBar(
      expandedHeight: 90,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: RepaintBoundary(
          child: GlassContainer(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            radius: BorderRadius.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 4),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: t.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          // Large Title
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).trips,
                              style: t.title1.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: t.textPrimary,
                              ),
                            ),
                          ),
                          
                          // Top-right export icon toggles Export Mode
                          _buildActionButtons(t),
                        ],
                      ),
                      // The bottom sticky bar shows selection count and actions
                    ],
                  ),
                ),
                SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Action buttons (filter & sort unified, export)
  Widget _buildActionButtons(AppTokens t) {
    return AnimatedBuilder(
      animation: _selection,
      builder: (context, _) {
        final bool exportMode = _selection.exportMode;
        return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.tune_rounded,
          onPressed: _showFilterSortSheet,
          tooltip: 'Filtrer & Trier',
          t: t,
        ),
        SizedBox(width: t.spaceXs),
        _buildActionButton(
          icon: exportMode ? Icons.close_rounded : Icons.picture_as_pdf_rounded,
          onPressed: _toggleSelectionMode,
          tooltip: exportMode ? 'Annuler l\'export' : 'Exporter en PDF',
          t: t,
        ),
      ],
    );
      },
    );
  }

  /// Selection controls when in selection mode
  Widget _buildSelectionControls(AppTokens t) {
    return AnimatedBuilder(
      animation: _selection,
      builder: (context, _) {
        return Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selection count - made more compact
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: t.spaceSm, vertical: t.spaceXs),
                  decoration: BoxDecoration(
                    color: t.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.accent.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${_selection.count}',
                    style: t.caption.copyWith(
                      color: t.accent,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: t.spaceXs),
              // Cancel selection
              _buildActionButton(
                icon: Icons.close_rounded,
                onPressed: _toggleSelectionMode,
                tooltip: 'Annuler',
                t: t,
              ),
              SizedBox(width: t.spaceXs),
              // Export selected
              _buildActionButton(
                icon: Icons.download_rounded,
                onPressed: _selection.count > 0 ? _exportToPDF : null,
                tooltip: 'Exporter en PDF',
                t: t,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String? tooltip,
    required AppTokens t,
  }) {
    final button = GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: t.glassTint.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.glassStroke),
        ),
        child: Icon(
          icon,
          color: t.textPrimary,
          size: 20,
        ),
      ),
    );
    
    return tooltip != null
        ? Tooltip(message: tooltip!, child: button)
        : button;
  }

  /// Segmented Control for Upcoming/Completed
  Widget _buildSegmentedControl(AppTokens t) {
    return RepaintBoundary(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: t.glassTint.withOpacity(0.3),
          borderRadius: t.glassRadius,
          border: Border.all(color: t.glassStroke),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSegmentedOption(
                'À venir',
                0,
                t,
              ),
            ),
            Expanded(
              child: _buildSegmentedOption(
                'Terminés',
                1,
                t,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Individual segmented option
  Widget _buildSegmentedOption(String label, int index, AppTokens t) {
    final isSelected = _selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: t.motionBase,
        curve: Curves.easeInOut,
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? t.glassTint : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: t.glassStroke) : null,
          boxShadow: isSelected ? [
            BoxShadow(
              color: t.accent.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: t.caption.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? t.textPrimary : t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// Upcoming trips content
  Widget _buildUpcomingContent(AppTokens t) {
    final currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      return _buildNotLoggedInState(t);
    }

    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.getUserUpcomingReservationsStreamWithFilter(
        currentUser.uid,
        _upcomingFilter,
      ),
      initialData: const [],
      builder: (context, snapshot) {
        final reservations = snapshot.data ?? const <Reservation>[];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && reservations.isEmpty;
        
        if (isLoading) {
          return _buildSkeletonList(t);
        }
        
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), t);
        }
        
        if (reservations.isEmpty) {
          return _buildEmptyUpcomingState(t);
        }
        
        // Apply sorting if needed
        final sortedReservations = _applySorting(reservations);
        
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: t.spaceMd),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final reservation = sortedReservations[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: t.spaceSm),
                  child: TripCardV2(
                    type: reservation.type,
                    vehicleTitle: reservation.vehicleName,
                    fromAddress: reservation.departure,
                    toAddress: reservation.destination,
                    startAt: reservation.selectedDate,
                    endAt: reservation.driverProposedDate ?? _calculateEndTime(reservation),
                    status: _getStatusText(reservation.status),
                    paymentLabel: reservation.paymentMethod,
                    priceFormatted: '${reservation.totalPrice.toStringAsFixed(0)}€',
                    isUpcoming: true,
                    isSelected: _selection.exportMode && _selection.isSelected(reservation.id),
                    isSelectionMode: _selection.exportMode,
                    onSelectionToggle: _selection.exportMode ? () => _toggleReservationSelection(reservation.id) : null,
                    onTap: () => _handleTripTap(reservation),
                    onChat: () => _openChat(reservation),
                  ),
                );
              },
              childCount: sortedReservations.length,
            ),
          ),
        );
      },
    );
  }

  /// Completed trips content - OPTIMISÉ
  Widget _buildCompletedContent(AppTokens t) {
    final currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      return _buildNotLoggedInState(t);
    }

    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.getUserCompletedReservationsStreamWithFilter(
        currentUser.uid,
        _completedFilter,
      ),
      initialData: const [],
      builder: (context, snapshot) {
        final reservations = snapshot.data ?? const <Reservation>[];
        final isLoading = snapshot.connectionState == ConnectionState.waiting && reservations.isEmpty;
        
        if (isLoading) {
          return const TripsSkeleton(itemCount: 5);
        }
        
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), t);
        }
        
        if (reservations.isEmpty) {
          return _buildEmptyCompletedState(t);
        }
        
        // Apply sorting if needed
        final sortedReservations = _applySorting(reservations);
        
        return OptimizedTripsList(
          reservations: sortedReservations,
          isUpcoming: false,
          selectionController: _selection,
          onTripTap: _handleTripTap,
          onChat: _openChat,
          onRebook: _rebookTrip,
          onShowReceipt: _showReceipt,
        );
      },
    );
  }

  /// Skeleton loading state
  Widget _buildSkeletonList(AppTokens t) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: t.spaceMd),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: EdgeInsets.only(bottom: t.spaceSm),
            child: _TripCardSkeleton(),
          ),
          childCount: 5,
        ),
      ),
    );
  }

  /// Empty upcoming state
  Widget _buildEmptyUpcomingState(AppTokens t) {
    return SliverFillRemaining(
      child: _EmptyUpcoming(
        onBookTrip: () => widget.onNavigate?.call(0),
      ),
    );
  }

  /// Empty completed state
  Widget _buildEmptyCompletedState(AppTokens t) {
    return SliverFillRemaining(
      child: _EmptyCompleted(
        onExploreOffers: () => widget.onNavigate?.call(1),
      ),
    );
  }

  /// Not logged in state
  Widget _buildNotLoggedInState(AppTokens t) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_rounded,
              size: 80,
              color: t.textTertiary,
            ),
            SizedBox(height: t.spaceLg),
            Text(
              'Connectez-vous pour voir vos trajets',
              style: t.title2.copyWith(color: t.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Error state
  Widget _buildErrorState(String error, AppTokens t) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: t.textTertiary,
            ),
            SizedBox(height: t.spaceLg),
            Text(
              'Erreur de connexion',
              style: t.title2.copyWith(color: t.textSecondary),
            ),
            SizedBox(height: t.spaceSm),
            Text(
              error,
              style: t.caption.copyWith(color: t.textTertiary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: t.spaceLg),
            _buildPrimaryButton(
              label: 'Réessayer',
              onPressed: () => setState(() {}),
              t: t,
            ),
          ],
        ),
      ),
    );
  }

  // Action handlers
  void _showFilterSortSheet() {
    final current = _selectedTabIndex == 0 ? _upcomingFilter : _completedFilter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TripsFiltersSheet(
        currentFilter: current,
        onApply: (filter) {
          setState(() {
            if (_selectedTabIndex == 0) {
              _upcomingFilter = filter.copyWith(isUpcoming: true);
            } else {
              _completedFilter = filter.copyWith(isUpcoming: false);
            }
            // also map to old _currentSortOption if still used elsewhere
            switch (filter.sortType) {
              case ReservationSortType.dateAscending:
                _currentSortOption = ReservationSortType.dateAscending;
                break;
              case ReservationSortType.dateDescending:
                _currentSortOption = ReservationSortType.dateDescending;
                break;
              case ReservationSortType.priceAscending:
                _currentSortOption = ReservationSortType.priceAscending;
                break;
              case ReservationSortType.priceDescending:
                _currentSortOption = ReservationSortType.priceDescending;
                break;
            }
          });
        },
      ),
    );
  }

  void _showOverflowMenu() {
    // Show overflow menu
  }

  void _handleTripTap(Reservation reservation) {
    // Handle trip tap
  }

  void _openChat(Reservation reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideChatScreen(
          reservationId: reservation.id,
        ),
      ),
    );
  }

  void _rebookTrip(Reservation reservation) {
    // Handle rebook
  }

  void _showReceipt(Reservation reservation) {
    // Show receipt
  }

  String _getStatusText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.confirmed:
        return 'Confirmé';
      case ReservationStatus.inProgress:
        return 'En cours';
      case ReservationStatus.completed:
        return 'Terminé';
      case ReservationStatus.cancelled:
        return 'Annulé';
    }
  }

  DateTime? _calculateEndTime(Reservation reservation) {
    // Pour les offres personnalisées, on calcule l'heure d'arrivée basée sur l'heure de départ + durée estimée
    if (reservation.type == ReservationType.offer) {
      // Si on a une heure d'arrivée estimée dans estimatedArrival, on l'utilise
      if (reservation.estimatedArrival.isNotEmpty) {
        try {
          // Parse l'heure d'arrivée estimée (format HH:mm)
          final timeParts = reservation.estimatedArrival.split(':');
          if (timeParts.length == 2) {
            final hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            return DateTime(
              reservation.selectedDate.year,
              reservation.selectedDate.month,
              reservation.selectedDate.day,
              hour,
              minute,
            );
          }
        } catch (e) {
          // Si le parsing échoue, on calcule une durée par défaut
        }
      }
      
      // Calcul par défaut : départ + 2 heures pour les offres personnalisées
      final startTime = DateTime(
        reservation.selectedDate.year,
        reservation.selectedDate.month,
        reservation.selectedDate.day,
        int.parse(reservation.selectedTime.split(':')[0]),
        int.parse(reservation.selectedTime.split(':')[1]),
      );
      return startTime.add(const Duration(hours: 2));
    }
    
    return null;
  }

  List<Reservation> _applySorting(List<Reservation> reservations) {
    if (_currentSortOption == null) return reservations;
    
    List<Reservation> sorted = List.from(reservations);
    
    switch (_currentSortOption!) {
      case ReservationSortType.dateAscending:
        sorted.sort((a, b) => a.selectedDate.compareTo(b.selectedDate));
        break;
      case ReservationSortType.dateDescending:
        sorted.sort((a, b) => b.selectedDate.compareTo(a.selectedDate));
        break;
      case ReservationSortType.priceAscending:
        sorted.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
        break;
      case ReservationSortType.priceDescending:
        sorted.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
        break;
    }
    
    return sorted;
  }

  Widget _buildPrimaryButton({
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    required AppTokens t,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: t.spaceMd,
          vertical: t.spaceSm,
        ),
        decoration: BoxDecoration(
          color: t.accent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.accent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: t.accentOn),
              SizedBox(width: t.spaceXs),
            ],
            Text(
              label,
              style: t.caption.copyWith(
                color: t.accentOn,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtleButton({
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    required AppTokens t,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: t.spaceMd,
          vertical: t.spaceSm,
        ),
        decoration: BoxDecoration(
          color: t.glassTint.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.glassStroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: t.textPrimary),
              SizedBox(width: t.spaceXs),
            ],
            Text(
              label,
              style: t.caption.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Skeleton loading card
class _TripCardSkeleton extends StatefulWidget {
  @override
  State<_TripCardSkeleton> createState() => _TripCardSkeletonState();
}

class _TripCardSkeletonState extends State<_TripCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return GlassContainer(
          padding: EdgeInsets.all(t.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header skeleton
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: t.textTertiary.withOpacity(_animation.value),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(width: t.spaceSm),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: t.textTertiary.withOpacity(_animation.value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 20,
                    decoration: BoxDecoration(
                      color: t.textTertiary.withOpacity(_animation.value),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: t.spaceSm),
              
              // Route skeleton
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: t.textTertiary.withOpacity(_animation.value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  SizedBox(width: t.spaceSm),
                  Container(
                    width: 40,
                    height: 16,
                    decoration: BoxDecoration(
                      color: t.textTertiary.withOpacity(_animation.value),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(width: t.spaceSm),
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: t.textTertiary.withOpacity(_animation.value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: t.spaceMd),
              
              // Meta rows skeleton
              ...List.generate(3, (index) => Padding(
                padding: EdgeInsets.only(bottom: t.spaceXs),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: t.textTertiary.withOpacity(_animation.value),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: t.spaceXs),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: t.textTertiary.withOpacity(_animation.value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(width: t.spaceXs),
                    Expanded(
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: t.textTertiary.withOpacity(_animation.value),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}

/// Empty upcoming state
class _EmptyUpcoming extends StatelessWidget {
  final VoidCallback? onBookTrip;

  const _EmptyUpcoming({this.onBookTrip});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(t.spaceXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 80,
              color: t.textTertiary,
            ),
            SizedBox(height: t.spaceLg),
            Text(
              'Aucun trajet à venir',
              style: t.title1.copyWith(color: t.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: t.spaceSm),
            Text(
              'Quand vous réservez, ils apparaissent ici.',
              style: t.body.copyWith(color: t.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: t.spaceXl),
            _buildPrimaryButton(
              label: 'Réserver un trajet',
              icon: Icons.add_rounded,
              onPressed: onBookTrip,
              t: t,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    required AppTokens t,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: t.spaceMd,
          vertical: t.spaceSm,
        ),
        decoration: BoxDecoration(
          color: t.accent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.accent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: t.accentOn),
              SizedBox(width: t.spaceXs),
            ],
            Text(
              label,
              style: t.caption.copyWith(
                color: t.accentOn,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty completed state
class _EmptyCompleted extends StatelessWidget {
  final VoidCallback? onExploreOffers;

  const _EmptyCompleted({this.onExploreOffers});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(t.spaceXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: t.textTertiary,
            ),
            SizedBox(height: t.spaceLg),
            Text(
              'Aucun trajet terminé',
              style: t.title1.copyWith(color: t.textPrimary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: t.spaceSm),
            Text(
              'Vos trajets passés se rangeront ici.',
              style: t.body.copyWith(color: t.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: t.spaceXl),
            _buildSubtleButton(
              label: 'Explorer les offres',
              icon: Icons.explore_rounded,
              onPressed: onExploreOffers,
              t: t,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtleButton({
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
    required AppTokens t,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: t.spaceMd,
          vertical: t.spaceSm,
        ),
        decoration: BoxDecoration(
          color: t.glassTint.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.glassStroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: t.textPrimary),
              SizedBox(width: t.spaceXs),
            ],
            Text(
              label,
              style: t.caption.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


