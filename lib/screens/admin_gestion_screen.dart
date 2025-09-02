import 'package:flutter/material.dart';
import '../theme/theme_app.dart';
import '../widgets/admin_navbar.dart';

class AdminGestionScreen extends StatefulWidget {
  const AdminGestionScreen({super.key});

  @override
  State<AdminGestionScreen> createState() => _AdminGestionScreenState();
}

class _AdminGestionScreenState extends State<AdminGestionScreen> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Gestion',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 80,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent),
            ),
            child: Text(
              'ADMIN',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Contenu principal
          Expanded(
            child: _buildContent(),
          ),
          // Barre de navigation en bas
          AdminBottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _handleNavigation,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSection(
              title: 'Gestion de la flotte',
              icon: Icons.directions_car,
              children: [
                _buildMenuItem(
                  icon: Icons.add_circle,
                  title: 'Ajouter un véhicule',
                  subtitle: 'Ajouter un nouveau véhicule à la flotte',
                  onTap: () => _showAddVehicleDialog(),
                ),
                _buildMenuItem(
                  icon: Icons.list,
                  title: 'Liste des véhicules',
                  subtitle: 'Voir et gérer tous les véhicules',
                  onTap: () => _showVehicleList(),
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'Configuration véhicules',
                  subtitle: 'Activer/désactiver des véhicules',
                  onTap: () => _showVehicleSettings(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Codes promotionnels',
              icon: Icons.local_offer,
              children: [
                _buildMenuItem(
                  icon: Icons.add_circle,
                  title: 'Créer un code promo',
                  subtitle: 'Générer un nouveau code promotionnel',
                  onTap: () => _showCreatePromoDialog(),
                ),
                _buildMenuItem(
                  icon: Icons.list,
                  title: 'Codes actifs',
                  subtitle: 'Voir et gérer les codes promotionnels',
                  onTap: () => _showPromoCodesList(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'Administration',
              icon: Icons.admin_panel_settings,
              children: [
                _buildMenuItem(
                  icon: Icons.people,
                  title: 'Gestion utilisateurs',
                  subtitle: 'Voir et gérer les utilisateurs',
                  onTap: () => _showUserManagement(),
                ),
                _buildMenuItem(
                  icon: Icons.analytics,
                  title: 'Statistiques',
                  subtitle: 'Voir les statistiques de l\'application',
                  onTap: () => _showStatistics(),
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'Paramètres système',
                  subtitle: 'Configuration générale de l\'application',
                  onTap: () => _showSystemSettings(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.accent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppColors.accent,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  void _showAddVehicleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Ajouter un véhicule',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Fonctionnalité à implémenter',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  void _showVehicleList() {
    _showFeatureDialog('Liste des véhicules');
  }

  void _showVehicleSettings() {
    _showFeatureDialog('Configuration véhicules');
  }

  void _showCreatePromoDialog() {
    _showFeatureDialog('Créer un code promo');
  }

  void _showPromoCodesList() {
    _showFeatureDialog('Codes promotionnels');
  }

  void _showUserManagement() {
    _showFeatureDialog('Gestion utilisateurs');
  }

  void _showStatistics() {
    _showFeatureDialog('Statistiques');
  }

  void _showSystemSettings() {
    _showFeatureDialog('Paramètres système');
  }

  void _showFeatureDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          feature,
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Cette fonctionnalité sera bientôt disponible.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Accueil
        Navigator.pushReplacementNamed(context, '/admin/home');
        break;
      case 1: // Trajets
        Navigator.pushReplacementNamed(context, '/admin/trajets');
        break;
      case 2: // Gestion (déjà sur cette page)
        break;
      case 3: // Compte
        Navigator.pushReplacementNamed(context, '/admin/profile');
        break;
    }
  }
}
