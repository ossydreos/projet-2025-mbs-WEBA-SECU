import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/data/services/admin_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../theme/glassmorphism_theme.dart';

class ContactLauncherService {
  final BuildContext context;
  final AdminService _adminService = AdminService();

  ContactLauncherService(this.context);

  Future<String?> _getAdminPhoneNumber() async {
    try {
      return await _adminService.getAdminPhoneNumber();
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.of(context).adminPhoneNotAvailable);
      return null;
    }
  }

  Future<void> launchPhoneCall() async {
    final phoneNumber = await _getAdminPhoneNumber();
    if (phoneNumber == null) return;

    // Utilise le système natif - Android/iOS affichera automatiquement les apps disponibles
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Impossible de lancer l\'application');
    }
  }

  Future<void> launchMessage() async {
    final phoneNumber = await _getAdminPhoneNumber();
    if (phoneNumber == null) return;

    // Utilise le système natif - Android/iOS affichera automatiquement les apps disponibles
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Impossible de lancer l\'application');
    }
  }

  void _showErrorSnackBar(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.hot),
      );
    }
  }
}