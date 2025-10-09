import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';

/// Trip sort sheet with iOS 26 Liquid Glass aesthetic
class TripSortSheet extends StatefulWidget {
  final TripSortOption? currentSort;
  final Function(TripSortOption) onApplySort;

  const TripSortSheet({
    super.key,
    required this.currentSort,
    required this.onApplySort,
  });

  @override
  State<TripSortSheet> createState() => _TripSortSheetState();
}

class _TripSortSheetState extends State<TripSortSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _breathingController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _breathingAnimation;
  
  TripSortOption? _selectedSort;

  @override
  void initState() {
    super.initState();
    _selectedSort = widget.currentSort;
    
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
                offset: Offset(0, screenHeight * 0.6 * _slideAnimation.value),
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
            height: screenHeight * 0.6,
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
            'Trier les trajets',
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
          _buildSortSection(
            'DATE',
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
          
          _buildSortSection(
            'PRIX',
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
          
          _buildSortSection(
            'DISTANCE',
            [
              _buildSortOption(
                'Plus court',
                TripSortOption.distanceAsc,
                Icons.arrow_upward_rounded,
                t,
              ),
              _buildSortOption(
                'Plus long',
                TripSortOption.distanceDesc,
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

  Widget _buildSortSection(String title, List<Widget> options, AppTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        SizedBox(height: t.spaceSm),
        ...options,
      ],
    );
  }

  Widget _buildSortOption(String label, TripSortOption option, IconData icon, AppTokens t) {
    final isSelected = _selectedSort == option;
    
    return GestureDetector(
      onTap: () => _selectOption(option),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        margin: EdgeInsets.only(bottom: t.spaceSm),
        height: 56,
        padding: EdgeInsets.symmetric(horizontal: t.spaceLg),
        decoration: BoxDecoration(
          color: isSelected 
              ? Color(0xFF466EFF).withOpacity(0.18)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected 
                ? Color(0xFF5A8CFF).withOpacity(0.25)
                : Colors.white.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Color(0xFF5A8CFF).withOpacity(0.25),
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
                    ? Color(0xFF5A8CFF).withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected 
                    ? Color(0xFF5A8CFF)
                    : Colors.white.withOpacity(0.6),
              ),
            ),
            SizedBox(width: t.spaceMd),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected 
                      ? Colors.white
                      : Colors.white.withOpacity(0.8),
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color(0xFF5A8CFF),
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
              _applySort,
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

  void _selectOption(TripSortOption option) {
    setState(() {
      _selectedSort = option;
    });
    HapticFeedback.lightImpact();
  }

  void _resetAll() {
    setState(() {
      _selectedSort = null;
    });
    HapticFeedback.lightImpact();
  }

  void _applySort() {
    if (_selectedSort != null) {
      widget.onApplySort(_selectedSort!);
    }
    _closeSheet();
  }

  void _closeSheet() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }
}

enum TripSortOption {
  dateAsc,
  dateDesc,
  priceAsc,
  priceDesc,
  distanceAsc,
  distanceDesc,
}