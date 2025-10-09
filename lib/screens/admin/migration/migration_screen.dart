import 'package:flutter/material.dart';
import '../../../data/services/migration_service.dart';
import '../../../theme/glassmorphism_theme.dart';

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  bool _isMigrating = false;
  bool _needsMigration = false;
  bool _isChecking = true;
  String _migrationStatus = '';

  @override
  void initState() {
    super.initState();
    _checkMigrationStatus();
  }

  Future<void> _checkMigrationStatus() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final needsMigration = await MigrationService.needsMigration();
      setState(() {
        _needsMigration = needsMigration;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _migrationStatus = 'Erreur lors de la vérification: $e';
        _isChecking = false;
      });
    }
  }

  Future<void> _runMigration() async {
    setState(() {
      _isMigrating = true;
      _migrationStatus = 'Migration en cours...';
    });

    try {
      await MigrationService.migrateReservations();
      setState(() {
        _migrationStatus = 'Migration terminée avec succès !';
        _needsMigration = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Migration terminée avec succès !'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _migrationStatus = 'Erreur lors de la migration: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Migration des Données',
          style: TextStyle(
            color: AppColors.textStrong,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textStrong),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.update, color: AppColors.accent, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Migration des Réservations',
                        style: TextStyle(
                          color: AppColors.textStrong,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cette migration ajoute les champs isPaid et isCompleted aux réservations existantes pour corriger le système d\'historique.',
                    style: TextStyle(color: AppColors.textWeak, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Statut de migration
            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statut de Migration',
                    style: TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_isChecking) ...[
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Vérification en cours...',
                          style: TextStyle(color: AppColors.textWeak),
                        ),
                      ],
                    ),
                  ] else if (_needsMigration) ...[
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'Migration nécessaire',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Les réservations existantes doivent être mises à jour.',
                      style: TextStyle(color: AppColors.textWeak),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        const Text(
                          'Migration à jour',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Toutes les réservations sont à jour.',
                      style: TextStyle(color: AppColors.textWeak),
                    ),
                  ],
                ],
              ),
            ),

            if (_migrationStatus.isNotEmpty) ...[
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(12),
                child: Text(
                  _migrationStatus,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Bouton de migration
            if (_needsMigration && !_isMigrating)
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  label: 'Lancer la Migration',
                  onPressed: _runMigration,
                  primary: true,
                ),
              ),

            if (_isMigrating)
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  label: 'Migration en cours...',
                  onPressed: null,
                  primary: true,
                ),
              ),

            if (!_needsMigration && !_isChecking)
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  label: 'Vérifier à nouveau',
                  onPressed: _checkMigrationStatus,
                  primary: false,
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }
}
