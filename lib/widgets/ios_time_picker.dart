import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import '../theme/glassmorphism_theme.dart';

class IOSTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final TimeOfDay? minimumTime;
  final Function(TimeOfDay) onTimeChanged;
  final String title;
  final String subtitle;

  const IOSTimePicker({
    super.key,
    required this.initialTime,
    this.minimumTime,
    required this.onTimeChanged,
    this.title = 'Sélectionner l\'heure',
    this.subtitle = 'Choisissez l\'heure de prise en charge',
  });

  @override
  State<IOSTimePicker> createState() => _IOSTimePickerState();
}

class _IOSTimePickerState extends State<IOSTimePicker> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime(
      2024,
      1,
      1,
      widget.initialTime.hour,
      widget.initialTime.minute,
    );
  }

  void _onDateTimeChanged(DateTime dateTime) {
    final newTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);

    // Vérifier les contraintes de temps minimum
    if (widget.minimumTime != null) {
      final minimumDateTime = DateTime(
        2024,
        1,
        1,
        widget.minimumTime!.hour,
        widget.minimumTime!.minute,
      );

      if (dateTime.isBefore(minimumDateTime)) {
        return; // Ne pas permettre la sélection d'une heure antérieure
      }
    }

    setState(() {
      _selectedDateTime = dateTime;
    });

    widget.onTimeChanged(newTime);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: AppColors.bgElev,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.glassStroke, width: 1),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textWeak,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.accent,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textWeak,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),

          // Time display
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, color: AppColors.accent, size: 20),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),

          // iOS Picker Wheel
          Expanded(
            child: Platform.isIOS ? _buildIOSPicker() : _buildAndroidPicker(),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: GlassButton(
                label: 'Confirmer',
                onPressed: () {
                  final selectedTime = TimeOfDay(
                    hour: _selectedDateTime.hour,
                    minute: _selectedDateTime.minute,
                  );
                  Navigator.of(context).pop(selectedTime);
                },
                icon: Icons.check,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSPicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.glass.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: CupertinoTheme(
        data: CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          brightness: Brightness.dark,
        ),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          initialDateTime: _selectedDateTime,
          minimumDate: widget.minimumTime != null
              ? DateTime(
                  2024,
                  1,
                  1,
                  widget.minimumTime!.hour,
                  widget.minimumTime!.minute,
                )
              : null,
          maximumDate: DateTime(2024, 1, 1, 23, 59),
          use24hFormat: true,
          onDateTimeChanged: _onDateTimeChanged,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildAndroidPicker() {
    // Pour Android, on utilise une interface similaire avec des colonnes
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.glass.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Row(
        children: [
          // Heures
          Expanded(
            child: _buildNumberPicker(
              value: _selectedDateTime.hour,
              minValue: widget.minimumTime?.hour ?? 0,
              maxValue: 23,
              onChanged: (hour) {
                final newDateTime = DateTime(
                  2024,
                  1,
                  1,
                  hour,
                  _selectedDateTime.minute,
                );
                _onDateTimeChanged(newDateTime);
              },
              suffix: 'h',
            ),
          ),

          // Séparateur
          Container(width: 2, height: 100, color: AppColors.glassStroke),

          // Minutes
          Expanded(
            child: _buildNumberPicker(
              value: _selectedDateTime.minute,
              minValue: 0,
              maxValue: 59,
              onChanged: (minute) {
                final newDateTime = DateTime(
                  2024,
                  1,
                  1,
                  _selectedDateTime.hour,
                  minute,
                );
                _onDateTimeChanged(newDateTime);
              },
              suffix: 'min',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPicker({
    required int value,
    required int minValue,
    required int maxValue,
    required Function(int) onChanged,
    required String suffix,
  }) {
    return SizedBox(
      height: 200,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 40,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          onChanged(minValue + index);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: maxValue - minValue + 1,
          builder: (context, index) {
            final number = minValue + index;
            final isSelected = number == value;

            return Container(
              alignment: Alignment.center,
              child: Text(
                '${number.toString().padLeft(2, '0')} $suffix',
                style: TextStyle(
                  fontSize: isSelected ? 20 : 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.accent : AppColors.textWeak,
                  fontFamily: 'Poppins',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Fonction utilitaire pour afficher le picker
Future<TimeOfDay?> showIOSTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  TimeOfDay? minimumTime,
  String title = 'Sélectionner l\'heure',
  String subtitle = 'Choisissez l\'heure de prise en charge',
}) async {
  return await showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => IOSTimePicker(
      initialTime: initialTime,
      minimumTime: minimumTime,
      title: title,
      subtitle: subtitle,
      onTimeChanged: (time) {
        // La valeur est gérée par le widget lui-même
      },
    ),
  );
}
