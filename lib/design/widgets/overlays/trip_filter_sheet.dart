import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';
import 'package:my_mobility_services/design/widgets/overlays/date_range_picker_glass.dart';
import 'package:my_mobility_services/data/models/reservation_filter.dart';
import 'package:intl/intl.dart';

/// Trip filter sheet with iOS 26 Liquid Glass aesthetic
class TripFilterSheet extends StatefulWidget {
  final ReservationFilter currentFilter;
  final Function(ReservationFilter) onApplyFilter;

  const TripFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onApplyFilter,
  });

  @override
  State<TripFilterSheet> createState() => _TripFilterSheetState();
}

class _TripFilterSheetState extends State<TripFilterSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _breathingController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _breathingAnimation;
  
  ReservationFilter _workingFilter = const ReservationFilter();
  String _selectedReservationType = 'tous';
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _workingFilter = widget.currentFilter;
    _initializeState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _breathingController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    _breathingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Backdrop
            GestureDetector(
              onTap: _closeSheet,
              child: Container(
                color: Colors.black.withOpacity(0.4 * _fadeAnimation.value),
              ),
            ),
            
            // Sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Transform.translate(
                offset: Offset(0, screenHeight * 0.7 * _slideAnimation.value),
                child: RepaintBoundary(
                  child: _buildLiquidGlassSheet(t, screenHeight),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLiquidGlassSheet(AppTokens t, double screenHeight) {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _breathingAnimation.value,
          child: Container(
            height: screenHeight * 0.7,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.08),
                  Colors.black.withOpacity(0.15),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 40,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Column(
                  children: [
                    _buildHandleBar(t),
                    _buildHeader(t),
                    Expanded(
                      child: _buildContent(t),
                    ),
                    _buildActionBar(t),
                  ],
                ),
              ),
            ),
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
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(AppTokens t) {
    return Container(
      padding: EdgeInsets.all(t.spaceXl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Text(
            'Filtrer les trajets',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: Colors.white,
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: _closeSheet,
            child: Container(
              padding: EdgeInsets.all(t.spaceSm),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppTokens t) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: t.spaceXl),
      child: Column(
        children: [
          _buildPeriodSection(t),
          SizedBox(height: t.spaceXl),
          _buildReservationTypeSection(t),
          SizedBox(height: t.spaceXl),
        ],
      ),
    );
  }

  Widget _buildPeriodSection(AppTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PÉRIODE',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        SizedBox(height: t.spaceSm),
        GestureDetector(
          onTap: _selectDateRange,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            height: 64,
            padding: EdgeInsets.all(t.spaceLg),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF5A8CFF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: Color(0xFF5A8CFF),
                  ),
                ),
                SizedBox(width: t.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Période sélectionnée',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _getDateRangeText(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReservationTypeSection(AppTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TYPE DE RÉSERVATION',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        SizedBox(height: t.spaceSm),
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
        duration: Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(vertical: t.spaceSm, horizontal: t.spaceMd),
        decoration: BoxDecoration(
          color: isSelected 
              ? Color(0xFF466EFF).withOpacity(0.18)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Color(0xFF5A8CFF).withOpacity(0.25)
                : Colors.white.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Color(0xFF5A8CFF).withOpacity(0.25),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected 
                ? Colors.white
                : Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(AppTokens t) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        t.spaceXl,
        t.spaceLg,
        t.spaceXl,
        t.spaceXl + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Réinitialiser',
              false,
              _resetAll,
              t,
            ),
          ),
          SizedBox(width: t.spaceMd),
          Expanded(
            child: _buildActionButton(
              'Appliquer',
              true,
              _applyFilter,
              t,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, bool isPrimary, VoidCallback onPressed, AppTokens t) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        height: 48,
        decoration: BoxDecoration(
          gradient: isPrimary ? LinearGradient(
            colors: [
              Color(0xFF466EFF),
              Color(0xFF8B5CF6),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ) : null,
          color: isPrimary ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary 
                ? Colors.transparent
                : Colors.white.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: Color(0xFF466EFF).withOpacity(0.3),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isPrimary 
                  ? Colors.white
                  : Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ),
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
          ? DateTimeRange(
              start: _workingFilter.startDate!,
              end: _workingFilter.endDate!,
            )
          : null,
    );
    
    if (selectedRange != null) {
      setState(() {
        _workingFilter = _workingFilter.copyWith(
          startDate: selectedRange.start,
          endDate: selectedRange.end,
        );
        _hasChanges = _workingFilter != widget.currentFilter;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _initializeState() {
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
      _hasChanges = true;
    });
    HapticFeedback.lightImpact();
  }

  void _resetAll() {
    setState(() {
      _workingFilter = const ReservationFilter();
      _selectedReservationType = 'tous';
      _hasChanges = false;
    });
    HapticFeedback.lightImpact();
  }

  void _applyFilter() {
    if (_hasChanges) {
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
    _closeSheet();
  }

  void _closeSheet() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }
}