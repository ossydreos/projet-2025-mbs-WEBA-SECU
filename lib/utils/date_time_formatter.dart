import 'package:flutter/material.dart';

/// Utilitaire centralisé pour le formatage des dates et heures
/// Remplace tous les _formatDate/_formatTime dupliqués
class DateTimeFormatter {
  // Constantes partagées pour éviter la duplication
  static const List<String> _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  static const List<String> _weekdays = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 
    'Vendredi', 'Samedi', 'Dimanche',
  ];

  /// Formate une date avec style court (Aujourd'hui, Demain, ou Jour/Mois)
  static String formatDateShort(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == today) {
      return 'Aujourd\'hui';
    } else if (selectedDay == today.add(const Duration(days: 1))) {
      return 'Demain';
    } else {
      final difference = now.difference(selectedDay);
      if (difference.inDays > 0) {
        return '${difference.inDays}j';
      } else {
        return '${selectedDay.day}/${selectedDay.month}';
      }
    }
  }

  /// Formate une date avec jour complet (Lundi, 15 janv.)
  static String formatDateLong(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == now.subtract(const Duration(days: 1))) {
      return 'Hier, ${date.day} ${_months[date.month - 1]}';
    } else if (selectedDay == today) {
      return 'Aujourd\'hui, ${date.day} ${_months[date.month - 1]}';
    } else if (selectedDay == today.add(const Duration(days: 1))) {
      return 'Demain, ${date.day} ${_months[date.month - 1]}';
    } else {
      final weekday = _weekdays[date.weekday - 1];
      final month = _months[date.month - 1];
      return '$weekday, ${date.day} $month';
    }
  }

  /// Formate une heure (HH:MM)
  static String formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Formate DateTime complet (DD/MM/YYYY HH:MM)
  static String formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year $hour:$minute';
  }

  /// Formate date avec fuseau horaire pour admin
  static String formatDateTimeWithTimezone(DateTime date, String time) {
    final formattedDate = 
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    return 'Départ prévu: $formattedDate, $time (CEST)';
  }

  /// Formate temps relatif (il y a X jours/heures)
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'Maintenant';
    }
  }
}
