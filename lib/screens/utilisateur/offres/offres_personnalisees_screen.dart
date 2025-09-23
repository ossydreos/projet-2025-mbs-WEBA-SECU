import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/custom_offer_creation_screen.dart';
import '../../../l10n/generated/app_localizations.dart';

class OffresPersonnaliseesScreen extends StatelessWidget {
  final Function(int) onNavigate;
  final bool showBottomBar;

  const OffresPersonnaliseesScreen({
    super.key,
    required this.onNavigate,
    this.showBottomBar = true,
  });

  void _openCustomOfferCreation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomOfferCreationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(title: AppLocalizations.of(context).offers),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // En-tête
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.star_outline,
                      size: 60,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).customOffer,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez une demande personnalisée pour un chauffeur privé',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bouton de création
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openCustomOfferCreation(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    AppLocalizations.of(context).createCustomOffer,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Informations
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Comment ça marche ?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Définissez votre trajet et la durée souhaitée\n'
                      '2. Ajoutez une note pour le chauffeur\n'
                      '3. Les chauffeurs verront votre demande\n'
                      '4. Un chauffeur acceptera et proposera un prix\n'
                      '5. Vous confirmez et payez',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
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
  }
}
