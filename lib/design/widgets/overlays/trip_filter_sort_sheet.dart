import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';
import 'package:my_mobility_services/design/widgets/primitives/glass_container.dart';
import 'package:my_mobility_services/design/widgets/overlays/date_range_picker_glass.dart';
import 'package:my_mobility_services/data/models/reservation_filter.dart';
import 'package:intl/intl.dart';

/// Unified filter and sort sheet for trips
class TripFilterSortSheet extends StatefulWidget {
  final ReservationFilter currentFilter;
  final Function(ReservationFilter) onApplyFilter;
  final Function(TripSortOption) onApplySort;

  const TripFilterSortSheet({
    super.key,
    required this.currentFilter,
    required this.onApplyFilter,
    required this.onApplySort,
  });

  @override
  State<TripFilterSortSheet> createState() => _TripFilterSortSheetState();
}

class _TripFilterSortSheetState extends State<TripFilterSortSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  ReservationFilter _workingFilter = const ReservationFilter();
  TripSortOption? _selectedSortOption;
  bool _hasFilterChanges = false;
  bool _hasSortChanges = false;
  int _currentTab = 0; // 0 = Filter, 1 = Sort
  String _selectedReservationType = 'tous'; // 'tous', 'simple', 'personnalisee'

  @override
  void initState() {
    super.initState();
    _workingFilter = widget.currentFilter;
    _initializeState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          height: screenHeight * 0.8,
          child: Stack(
            children: [
              // Backdrop
              GestureDetector(
                onTap: _closeSheet,
                child: Container(
                  color: Colors.black.withOpacity(0.3 * _fadeAnimation.value),
                ),
              ),
              
              // Sheet content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(0, screenHeight * 0.8 * _slideAnimation.value),
                  child: RepaintBoundary(
                    child: GlassContainer(
                      margin: EdgeInsets.zero,
                      radius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: Container(
                        height: screenHeight * 0.8,
                        child: Column(
                          children: [
                            // Handle bar
                            _buildHandleBar(t),
                            
                            // Header with tabs
                            _buildHeader(t),
                            
                            // Tab content
                            Expanded(
                              child: _currentTab == 0 ? _buildFilterContent(t) : _buildSortContent(t),
                            ),
                            
                            // Actions
                            _buildActions(t),
                          ],
                        ),
                      ),
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

  Widget _buildHandleBar(AppTokens t) {
    return Container(
      margin: EdgeInsets.only(top: t.spaceSm),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: t.textTertiary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(AppTokens t) {
    return Container(
      padding: EdgeInsets.all(t.spaceLg),
      decoration: BoxDecoration(
        color: t.glassTint.withOpacity(0.12),
        border: Border(
          bottom: BorderSide(
            color: t.glassStroke.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _currentTab == 0 ? 'Filtrer les trajets' : 'Trier les trajets',
                  style: t.title2.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _closeSheet,
                child: Container(
                  padding: EdgeInsets.all(t.spaceSm),
                  decoration: BoxDecoration(
                    color: t.glassTint.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: t.glassStroke.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: t.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: t.spaceXl),
          // Tab selector
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: t.glassTint.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: t.glassStroke.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentTab = 0),
                    child: AnimatedContainer(
                      duration: t.motionFast,
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(vertical: t.spaceMd),
                      decoration: BoxDecoration(
                        color: _currentTab == 0 
                            ? t.accent 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _currentTab == 0 ? [
                          BoxShadow(
                            color: t.accent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          'Filtrer',
                          style: t.body.copyWith(
                            color: _currentTab == 0 ? Colors.white : t.textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentTab = 1),
                    child: AnimatedContainer(
                      duration: t.motionFast,
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(vertical: t.spaceMd),
                      decoration: BoxDecoration(
                        color: _currentTab == 1 
                            ? t.accent 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _currentTab == 1 ? [
                          BoxShadow(
                            color: t.accent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          'Trier',
                          style: t.body.copyWith(
                            color: _currentTab == 1 ? Colors.white : t.textPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterContent(AppTokens t) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: t.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range filter
          _buildDateRangeFilter(t),
          
          SizedBox(height: t.spaceXl),
          
          // Vehicle type filter
          _buildVehicleTypeFilter(t),
          
          SizedBox(height: t.spaceXl),
          
        ],
      ),
    );
  }

  Widget _buildSortContent(AppTokens t) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: t.spaceLg),
      child: Column(
        children: [
          // Date sorting
          _buildSortSection(
            'Date',
            [
              _buildSortOption(
                'Plus récent',
                TripSortOption.dateDesc,
                Icons.arrow_downward_rounded,
                t,
              ),
              _buildSortOption(
                'Plus ancien',
                TripSortOption.dateAsc,
                Icons.arrow_upward_rounded,
                t,
              ),
            ],
            t,
          ),
          
          SizedBox(height: t.spaceXl),
          
          // Price sorting
          _buildSortSection(
            'Prix',
            [
              _buildSortOption(
                'Prix croissant',
                TripSortOption.priceAsc,
                Icons.arrow_upward_rounded,
                t,
              ),
              _buildSortOption(
                'Prix décroissant',
                TripSortOption.priceDesc,
                Icons.arrow_downward_rounded,
                t,
              ),
            ],
            t,
          ),
          
          SizedBox(height: t.spaceXl),
          
        ],
      ),
    );
  }

  Widget _buildDateRangeFilter(AppTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Période',
          style: t.title2.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: t.spaceMd),
        GestureDetector(
          onTap: _selectDateRange,
          child: AnimatedContainer(
            duration: t.motionBase,
            curve: Curves.easeInOut,
            padding: EdgeInsets.all(t.spaceLg),
            decoration: BoxDecoration(
              color: t.glassTint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: t.glassStroke.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 30,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.08),
                  blurRadius: 1,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: t.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color: t.accent,
                      ),
                    ),
                    SizedBox(width: t.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Période sélectionnée',
                            style: t.caption.copyWith(
                              color: t.textSecondary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: t.spaceXxs),
                          Text(
                            _getDateRangeText(),
                            style: t.body.copyWith(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: t.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getDateRangeText() {
    if (_workingFilter.startDate == null || _workingFilter.endDate == null) {
      return 'Aucune période sélectionnée';
    }
    
    final start = _workingFilter.startDate!;
    final end = _workingFilter.endDate!;
    
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return 'Le ${_formatDate(start)}';
    }
    
    return 'du ${_formatDate(start)} au ${_formatDate(end)}';
  }
  
  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy', 'fr');
    return formatter.format(date);
  }
  
  Future<void> _selectDateRange() async {
    final selectedRange = await DateRangePickerGlass.showGlassDateRangePicker(
      context: context,
      initialRange: _workingFilter.startDate != null && _workingFilter.endDate != null
          ? DateTimeRange(start: _workingFilter.startDate!, end: _workingFilter.endDate!)
          : null,
      title: 'Période',
    );
    
    if (selectedRange != null) {
      setState(() {
        _workingFilter = _workingFilter.copyWith(
          filterType: ReservationFilterType.dateRange,
          startDate: selectedRange.start,
          endDate: selectedRange.end,
        );
        _hasFilterChanges = _workingFilter != widget.currentFilter;
      });
      HapticFeedback.lightImpact();
    }
  }

  Widget _buildVehicleTypeFilter(AppTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de réservation',
          style: t.title2.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: t.spaceMd),
        Wrap(
          spacing: t.spaceSm,
          runSpacing: t.spaceSm,
          children: [
            _buildTypeChip('Tous', 'tous', t),
            _buildTypeChip('Demande simple', 'simple', t),
            _buildTypeChip('Offre personnalisée', 'personnalisee', t),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(String label, String typeValue, AppTokens t) {
    final isSelected = _selectedReservationType == typeValue;
    
    return GestureDetector(
      onTap: () => _updateReservationType(typeValue),
      child: AnimatedContainer(
        duration: t.motionFast,
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: t.spaceSm, horizontal: t.spaceMd),
        decoration: BoxDecoration(
          color: isSelected 
              ? t.accent.withOpacity(0.12) 
              : t.glassTint.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? t.accent.withOpacity(0.4) 
                : t.glassStroke.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: t.accent.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: t.caption.copyWith(
            color: isSelected ? t.accent : t.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }


  Widget _buildSortSection(String title, List<Widget> options, AppTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: t.title2.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: t.spaceMd),
        ...options,
      ],
    );
  }

  Widget _buildSortOption(String label, TripSortOption option, IconData icon, AppTokens t) {
    final isSelected = _selectedSortOption == option;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSortOption = option;
          _hasSortChanges = true;
        });
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: t.motionFast,
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(bottom: t.spaceSm),
        padding: EdgeInsets.symmetric(
          vertical: t.spaceLg,
          horizontal: t.spaceLg,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? t.accent.withOpacity(0.12) 
              : t.glassTint.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? t.accent.withOpacity(0.4) 
                : t.glassStroke.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: t.accent.withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? t.accent.withOpacity(0.15) 
                    : t.glassTint.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? t.accent : t.textSecondary,
              ),
            ),
            SizedBox(width: t.spaceMd),
            Expanded(
              child: Text(
                label,
                style: t.body.copyWith(
                  color: isSelected ? t.accent : t.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(AppTokens t) {
    final hasChanges = _hasFilterChanges || _hasSortChanges;
    
    return Container(
      padding: EdgeInsets.all(t.spaceLg),
      decoration: BoxDecoration(
        color: t.glassTint.withOpacity(0.08),
        border: Border(
          top: BorderSide(
            color: t.glassStroke.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: hasChanges ? _resetAll : null,
              child: AnimatedContainer(
                duration: t.motionFast,
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(vertical: t.spaceLg),
                decoration: BoxDecoration(
                  color: hasChanges 
                      ? t.glassTint.withOpacity(0.12) 
                      : t.glassTint.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasChanges 
                        ? t.glassStroke.withOpacity(0.3) 
                        : t.glassStroke.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Réinitialiser',
                  textAlign: TextAlign.center,
                  style: t.body.copyWith(
                    color: hasChanges ? t.textPrimary : t.textTertiary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: t.spaceMd),
          Expanded(
            child: GestureDetector(
              onTap: hasChanges ? _applyAll : null,
              child: AnimatedContainer(
                duration: t.motionFast,
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(vertical: t.spaceLg),
                decoration: BoxDecoration(
                  color: hasChanges 
                      ? t.accent 
                      : t.accent.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: hasChanges ? [
                    BoxShadow(
                      color: t.accent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: Text(
                  'Appliquer',
                  textAlign: TextAlign.center,
                  style: t.body.copyWith(
                    color: hasChanges ? Colors.white : t.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _initializeState() {
    // Initialize reservation type from current filter
    if (_workingFilter.typeFilter == ReservationTypeFilter.simple) {
      _selectedReservationType = 'simple';
    } else if (_workingFilter.typeFilter == ReservationTypeFilter.customOffer) {
      _selectedReservationType = 'personnalisee';
    } else {
      _selectedReservationType = 'tous';
    }
  }

  void _updateReservationType(String typeValue) {
    setState(() {
      _selectedReservationType = typeValue;
      _hasFilterChanges = true;
    });
    HapticFeedback.lightImpact();
  }



  void _resetAll() {
    setState(() {
      _workingFilter = const ReservationFilter();
      _selectedSortOption = null;
      _selectedReservationType = 'tous';
      _hasFilterChanges = false;
      _hasSortChanges = false;
    });
    HapticFeedback.lightImpact();
  }

  void _applyAll() {
    if (_hasFilterChanges) {
      // Update filter with selected reservation type
      ReservationTypeFilter typeFilter;
      switch (_selectedReservationType) {
        case 'simple':
          typeFilter = ReservationTypeFilter.simple;
          break;
        case 'personnalisee':
          typeFilter = ReservationTypeFilter.customOffer;
          break;
        default:
          typeFilter = ReservationTypeFilter.all;
      }
      
      final updatedFilter = _workingFilter.copyWith(typeFilter: typeFilter);
      widget.onApplyFilter(updatedFilter);
    }
    if (_hasSortChanges && _selectedSortOption != null) {
      widget.onApplySort(_selectedSortOption!);
    }
    _closeSheet();
  }

  void _closeSheet() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }
}

/// Sort options for trips
enum TripSortOption {
  dateAsc,
  dateDesc,
  priceAsc,
  priceDesc,
  distanceAsc,
  distanceDesc,
}

