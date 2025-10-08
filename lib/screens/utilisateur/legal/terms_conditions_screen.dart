import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/l10n/generated/app_localizations.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
          AppLocalizations.of(context).termsConditions,
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
              AppLocalizations.of(context).serviceDescription,
              AppLocalizations.of(context).serviceDescriptionText,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              AppLocalizations.of(context).userObligations,
              AppLocalizations.of(context).userObligationsText,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              AppLocalizations.of(context).companyObligations,
              AppLocalizations.of(context).companyObligationsText,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              AppLocalizations.of(context).paymentTerms,
              AppLocalizations.of(context).paymentTermsText,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              AppLocalizations.of(context).cancellationPolicy,
              AppLocalizations.of(context).cancellationPolicyText,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              AppLocalizations.of(context).liabilityLimitation,
              AppLocalizations.of(context).liabilityLimitationText,
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              AppLocalizations.of(context).disputeResolution,
              AppLocalizations.of(context).disputeResolutionText,
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
