import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_mobility_services/design/filters/date/lg_date_range_calendar.dart';
import 'package:my_mobility_services/design/filters/widgets/lg_chip.dart';
import 'package:my_mobility_services/design/filters/widgets/lg_radio_tile.dart';
import 'package:my_mobility_services/design/filters/widgets/lg_segmented_switch.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';
import 'package:my_mobility_services/data/models/reservation_filter.dart';

class TripsFiltersSheet extends StatefulWidget {
  final ReservationFilter currentFilter;
  final void Function(ReservationFilter) onApply;

  const TripsFiltersSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<TripsFiltersSheet> createState() => _TripsFiltersSheetState();
}

class _TripsFiltersSheetState extends State<TripsFiltersSheet> {
  int _tab = 0; // 0=Filtrer, 1=Trier
  DateTimeRange? _range;
  ReservationTypeFilter _type = ReservationTypeFilter.all;
  ReservationSortType _sort = ReservationSortType.dateDescending;

  @override
  void initState() {
    super.initState();
    _hydrateFromFilter(widget.currentFilter);
  }

  void _hydrateFromFilter(ReservationFilter f) {
    _type = f.typeFilter;
    if (f.startDate != null && f.endDate != null) {
      _range = DateTimeRange(start: f.startDate!, end: f.endDate!);
    } else {
      _range = null;
    }
    _sort = f.sortType;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        GestureDetector(onTap: () => Navigator.of(context).pop(), child: Container(color: Colors.black.withOpacity(0.4))),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: RepaintBoundary(
            child: Container(
              height: screenHeight * 0.86,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                boxShadow: t.glassShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: t.glassBlurBackground, sigmaY: t.glassBlurBackground),
                  child: Container(
                    color: t.glassTint,
                    child: Column(
                      children: [
                        _buildTopBar(t),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: t.spaceLg),
                          child: LgSegmentedSwitch(
                            values: const ['Filtrer', 'Trier'],
                            index: _tab,
                            onChanged: (i) => setState(() => _tab = i),
                          ),
                        ),
                        SizedBox(height: t.spaceLg),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: t.spaceLg),
                            child: _tab == 0 ? _buildFilterTab(t) : _buildSortTab(t),
                          ),
                        ),
                        _buildFooter(t),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(AppTokens t) {
    return Padding(
      padding: EdgeInsets.fromLTRB(t.spaceLg, t.spaceLg, t.spaceLg, t.spaceMd),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.glassTint.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.glassStroke.withOpacity(0.24)),
              ),
              child: Icon(Icons.close_rounded, color: t.textSecondary),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('Filtres', style: t.title2.copyWith(color: t.textPrimary, fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(width: 40), // Espace pour équilibrer
        ],
      ),
    );
  }

  Widget _buildFilterTab(AppTokens t) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Période
          Text('Période', style: t.body.copyWith(color: t.textPrimary, fontWeight: FontWeight.w600)),
          SizedBox(height: t.spaceSm),
          Container(
            padding: EdgeInsets.all(t.spaceMd),
            decoration: BoxDecoration(
              color: t.glassTint.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.glassStroke.withOpacity(0.24)),
            ),
            child: LgDateRangeCalendar(
              initialRange: _range,
              firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              onChanged: (r) => setState(() => _range = r),
            ),
          ),
          SizedBox(height: t.spaceLg),

          // Type de réservation
          Text('Type de réservation', style: t.body.copyWith(color: t.textPrimary, fontWeight: FontWeight.w600)),
          SizedBox(height: t.spaceSm),
          Wrap(
            spacing: t.spaceSm,
            runSpacing: t.spaceSm,
            children: [
              LgChip(label: 'Tous', selected: _type == ReservationTypeFilter.all, onTap: () => setState(() => _type = ReservationTypeFilter.all)),
              LgChip(label: 'Réservation normale', selected: _type == ReservationTypeFilter.reservation, onTap: () => setState(() => _type = ReservationTypeFilter.reservation)),
              LgChip(label: 'Offre personnalisée', selected: _type == ReservationTypeFilter.offer, onTap: () => setState(() => _type = ReservationTypeFilter.offer)),
            ],
          ),

          SizedBox(height: t.spaceXl),
        ],
      ),
    );
  }

  Widget _buildSortTab(AppTokens t) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Date', style: t.body.copyWith(color: t.textPrimary, fontWeight: FontWeight.w600)),
          SizedBox(height: t.spaceSm),
          LgRadioTile<ReservationSortType>(
            value: ReservationSortType.dateDescending,
            groupValue: _sort,
            label: 'Plus récent',
            onChanged: (v) => setState(() => _sort = v),
            leadingIcon: Icons.arrow_downward_rounded,
          ),
          SizedBox(height: t.spaceSm),
          LgRadioTile<ReservationSortType>(
            value: ReservationSortType.dateAscending,
            groupValue: _sort,
            label: 'Plus ancien',
            onChanged: (v) => setState(() => _sort = v),
            leadingIcon: Icons.arrow_upward_rounded,
          ),

          SizedBox(height: t.spaceLg),
          Text('Prix', style: t.body.copyWith(color: t.textPrimary, fontWeight: FontWeight.w600)),
          SizedBox(height: t.spaceSm),
          LgRadioTile<ReservationSortType>(
            value: ReservationSortType.priceAscending,
            groupValue: _sort,
            label: 'Prix croissant',
            onChanged: (v) => setState(() => _sort = v),
            leadingIcon: Icons.arrow_upward_rounded,
          ),
          SizedBox(height: t.spaceSm),
          LgRadioTile<ReservationSortType>(
            value: ReservationSortType.priceDescending,
            groupValue: _sort,
            label: 'Prix décroissant',
            onChanged: (v) => setState(() => _sort = v),
            leadingIcon: Icons.arrow_downward_rounded,
          ),

          SizedBox(height: t.spaceXl),
        ],
      ),
    );
  }

  Widget _buildFooter(AppTokens t) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(t.spaceLg, t.spaceMd, t.spaceLg, t.spaceLg),
        child: Row(
          children: [
            Expanded(
              child: _secondaryBtn(t, 'Réinitialiser', _reset),
            ),
            SizedBox(width: t.spaceMd),
            Expanded(
              child: _primaryBtn(t, 'Appliquer', _apply),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryBtn(AppTokens t, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.glassTint.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.glassStroke.withOpacity(0.24), width: 1),
        ),
        child: Text(label, style: t.body.copyWith(color: t.textPrimary, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _primaryBtn(AppTokens t, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [t.accent, t.accent.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label, style: t.body.copyWith(color: t.accentOn, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _reset() {
    setState(() {
      _range = null;
      _type = ReservationTypeFilter.all;
      _sort = ReservationSortType.dateDescending;
    });
    // Ne pas fermer le sheet, juste remettre à zéro l'interface
  }

  void _apply() {
    final f = widget.currentFilter.copyWith(
      typeFilter: _type,
      sortType: _sort,
      startDate: _range?.start,
      endDate: _range?.end == null
          ? null
          : DateTime(
              _range!.end.year,
              _range!.end.month,
              _range!.end.day,
              23,
              59,
              59,
            ),
    );
    widget.onApply(f);
    Navigator.of(context).pop();
  }
}


