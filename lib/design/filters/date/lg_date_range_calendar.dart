import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_mobility_services/design/tokens/app_tokens.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';

class LgDateRangeCalendar extends StatefulWidget {
  final DateTimeRange? initialRange;
  final ValueChanged<DateTimeRange?> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;

  const LgDateRangeCalendar({
    super.key,
    this.initialRange,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<LgDateRangeCalendar> createState() => _LgDateRangeCalendarState();
}

class _LgDateRangeCalendarState extends State<LgDateRangeCalendar> {
  late DateTime _visibleMonth;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
    _visibleMonth = DateTime((_start ?? DateTime.now()).year, (_start ?? DateTime.now()).month);
  }

  @override
  void didUpdateWidget(LgDateRangeCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRange != oldWidget.initialRange) {
      _start = widget.initialRange?.start;
      _end = widget.initialRange?.end;
      if (_start != null) {
        _visibleMonth = DateTime(_start!.year, _start!.month);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(t),
        SizedBox(height: t.spaceSm),
        _buildWeekdays(t),
        SizedBox(height: t.spaceSm),
        _buildGrid(t),
        SizedBox(height: t.spaceSm),
        _buildSummary(t),
      ],
    );
  }

  Widget _buildHeader(AppTokens t) {
    final monthLabel = DateFormat.yMMMM('fr').format(_visibleMonth);
    return Row(
      children: [
        _navBtn(t, Icons.chevron_left_rounded, _goPrevMonth),
        Expanded(
          child: Center(
            child: Text(
              monthLabel[0].toUpperCase() + monthLabel.substring(1),
              style: t.body.copyWith(fontWeight: FontWeight.w600, color: t.textPrimary),
            ),
          ),
        ),
        _navBtn(t, Icons.chevron_right_rounded, _goNextMonth),
      ],
    );
  }

  Widget _navBtn(AppTokens t, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: t.glassTint.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.glassStroke.withOpacity(0.24)),
        ),
        child: Icon(icon, color: t.textSecondary),
      ),
    );
  }

  Widget _buildWeekdays(AppTokens t) {
    final fmt = DateFormat.E('fr');
    final monday = _startOfWeek(DateTime.now());
    final days = List.generate(7, (i) => fmt.format(monday.add(Duration(days: i))).substring(0, 2).toUpperCase());
    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Center(
              child: Text(
                d,
                style: t.caption.copyWith(color: t.textSecondary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGrid(AppTokens t) {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final startWeekday = (firstDay.weekday % 7); // Monday=1 -> 1
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final totalCells = 42;
    return Column(
      children: [
        for (int row = 0; row < 6; row++)
          Row(
            children: [
              for (int col = 0; col < 7; col++)
                Expanded(child: _buildCell(t, row * 7 + col, startWeekday, daysInMonth, row)),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(AppTokens t, int index, int startWeekday, int daysInMonth, int row) {
    final dayNumber = index - (startWeekday - 1);
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return SizedBox(height: 44);
    }
    final date = DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber);
    final bool inRange = _isInRange(date);
    final bool isEdge = _isEdge(date);
    final Color bg = inRange ? t.accent.withOpacity(0.18) : Colors.transparent;
    final Color text = inRange ? t.accentOn : t.textPrimary;

    return GestureDetector(
      onTap: () => _onTapDay(date),
      child: Container(
        height: 44,
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(isEdge ? 12 : 8),
        ),
        alignment: Alignment.center,
        child: Text('$dayNumber', style: t.body.copyWith(color: text)),
      ),
    );
  }

  Widget _buildSummary(AppTokens t) {
    String value;
    if (_start == null || _end == null) {
      value = 'Aucune période sélectionnée';
    } else {
      final f = DateFormat('dd MMM yyyy', 'fr');
      value = 'du ${f.format(_start!)} au ${f.format(_end!)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).selectedPeriod, style: t.caption.copyWith(color: t.textSecondary)),
        SizedBox(height: t.spaceXxs),
        Text(value, style: t.body.copyWith(color: t.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _goPrevMonth() => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1));
  void _goNextMonth() => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1));

  void _onTapDay(DateTime date) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = date;
        _end = null;
      } else {
        if (date.isBefore(_start!)) {
          _end = _start;
          _start = date;
        } else {
          _end = date;
        }
        widget.onChanged(_start != null && _end != null ? DateTimeRange(start: _start!, end: _end!) : null);
      }
    });
  }

  bool _isInRange(DateTime d) {
    if (_start == null) return false;
    if (_end == null) return _sameDay(d, _start!);
    return !d.isBefore(_start!) && !d.isAfter(_end!);
  }

  bool _isEdge(DateTime d) {
    if (_start == null) return false;
    if (_end == null) return _sameDay(d, _start!);
    return _sameDay(d, _start!) || _sameDay(d, _end!);
  }

  DateTime _startOfWeek(DateTime d) => d.subtract(Duration(days: (d.weekday + 6) % 7));
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}


