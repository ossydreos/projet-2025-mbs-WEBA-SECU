import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).privacyPolicy,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              AppLocalizations.of(context).dataCollection,
              AppLocalizations.of(context).dataCollectionDescription,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              AppLocalizations.of(context).dataUsage,
              AppLocalizations.of(context).dataUsageDescription,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              AppLocalizations.of(context).dataSharing,
              AppLocalizations.of(context).dataSharingDescription,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              AppLocalizations.of(context).dataSecurity,
              AppLocalizations.of(context).dataSecurityDescription,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              AppLocalizations.of(context).userRights,
              AppLocalizations.of(context).userRightsDescription,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              AppLocalizations.of(context).contactInfo,
              AppLocalizations.of(context).contactInfoDescription,
            ),
            const SizedBox(height: 30),
            _buildLastUpdated(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdated(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.update, color: AppColors.accent, size: 20),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context).lastUpdated,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '15 Janvier 2025',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
