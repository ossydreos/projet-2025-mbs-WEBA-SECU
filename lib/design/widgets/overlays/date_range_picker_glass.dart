import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DateRangePickerGlass {
  static Future<DateTimeRange?> showGlassDateRangePicker({
    required BuildContext context,
    DateTimeRange? initialRange,
    DateTime? firstDate,
    DateTime? lastDate,
    String? title,
  }) async {
    final now = DateTime.now();
    final defaultFirstDate = firstDate ?? DateTime(now.year - 5);
    final defaultLastDate = lastDate ?? DateTime(now.year + 5);

    if (Theme.of(context).platform == TargetPlatform.iOS || Platform.isMacOS) {
      // iOS/macOS: Cupertino style with Liquid Glass
      return await showCupertinoModalPopup<DateTimeRange>(
        context: context,
        builder: (BuildContext builderContext) {
          DateTime? tempStartDate = initialRange?.start;
          DateTime? tempEndDate = initialRange?.end;
          bool isValidRange = true;

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.3),
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
                        // Handle bar
                        Container(
                          margin: EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        
                        // Header
                        Container(
                          padding: EdgeInsets.all(24),
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
                                title ?? 'Sélectionner une période',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: Colors.white,
                                ),
                              ),
                              Spacer(),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: EdgeInsets.all(12),
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
                        ),
                        
                        // Date pickers
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                // Start date picker
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.06),
                                      width: 1,
                                    ),
                                  ),
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.date,
                                    initialDateTime: tempStartDate ?? now,
                                    minimumDate: defaultFirstDate,
                                    maximumDate: defaultLastDate,
                                    onDateTimeChanged: (DateTime newDate) {
                                      setState(() {
                                        tempStartDate = newDate;
                                        isValidRange = tempEndDate == null || !tempStartDate!.isAfter(tempEndDate!);
                                      });
                                    },
                                  ),
                                ),
                                
                                SizedBox(height: 16),
                                
                                Text(
                                  'Date de début',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                                
                                SizedBox(height: 24),
                                
                                // End date picker
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.06),
                                      width: 1,
                                    ),
                                  ),
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.date,
                                    initialDateTime: tempEndDate ?? tempStartDate ?? now,
                                    minimumDate: defaultFirstDate,
                                    maximumDate: defaultLastDate,
                                    onDateTimeChanged: (DateTime newDate) {
                                      setState(() {
                                        tempEndDate = newDate;
                                        isValidRange = tempStartDate == null || !tempStartDate!.isAfter(tempEndDate!);
                                      });
                                    },
                                  ),
                                ),
                                
                                SizedBox(height: 16),
                                
                                Text(
                                  'Date de fin',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                                
                                if (!isValidRange) ...[
                                  SizedBox(height: 16),
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'La date de fin doit être après la date de début',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        
                        // Action buttons
                        Container(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            16,
                            24,
                            24 + MediaQuery.of(context).padding.bottom,
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
                                  'Annuler',
                                  false,
                                  () => Navigator.of(context).pop(),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildActionButton(
                                  'Appliquer',
                                  true,
                                  isValidRange && tempStartDate != null && tempEndDate != null
                                      ? () => Navigator.of(context).pop(DateTimeRange(
                                            start: tempStartDate!,
                                            end: tempEndDate!,
                                          ))
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      // Android/Other: Material style with Liquid Glass theme
      final selectedRange = await showDateRangePicker(
        context: context,
        initialEntryMode: DatePickerEntryMode.calendarOnly,
        initialDateRange: initialRange,
        firstDate: defaultFirstDate,
        lastDate: defaultLastDate,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: Color(0xFF466EFF),
                onPrimary: Colors.white,
                onSurface: Colors.white,
                surface: Colors.black.withOpacity(0.8),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF466EFF),
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.08),
                    Colors.black.withOpacity(0.15),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.circular(24),
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
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: child!,
                ),
              ),
            ),
          );
        },
      );
      return selectedRange;
    }
  }

  static Widget _buildActionButton(String label, bool isPrimary, VoidCallback? onPressed) {
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
}