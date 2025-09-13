import 'package:flutter/material.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';

class AdminGestionScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final bool showBottomBar;

  const AdminGestionScreen({super.key, this.onNavigate, this.showBottomBar = true});

  @override
  State<AdminGestionScreen> createState() => _AdminGestionScreenState();
}

class _AdminGestionScreenState extends State<AdminGestionScreen> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: 'Gestion',
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
            Expanded(child: _buildContent()),
            // Barre de navigation en bas
            if (widget.showBottomBar)
              AdminBottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _handleNavigation,
              ),
          ],
        ),
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
                  icon: Icons.category,
                  title: 'Gestion des véhicules',
                  subtitle: 'Gérer les catégories, prix et disponibilité des véhicules',
                  onTap: () => _navigateToVehicleManagement(),
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
              ],
            ),
            const SizedBox(height: 100), // Espace pour la navbar
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
          // Titre de section avec effet glass
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.accent, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textStrong,
                  ),
                ),
              ],
            ),
          ),

          // Container principal des éléments
          GlassContainer(
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: children.asMap().entries.map((entry) {
                int index = entry.key;
                Widget child = entry.value;

                return Column(
                  children: [
                    child,
                    if (index < children.length - 1)
                      Divider(
                        color: AppColors.glassStroke,
                        thickness: 1,
                        height: 1,
                      ),
                  ],
                );
              }).toList(),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône avec container glass
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 16),

              // Textes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: AppColors.textWeak),
                    ),
                  ],
                ),
              ),

              // Flèche
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textWeak,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToVehicleManagement() {
    Navigator.pushNamed(context, '/admin/vehicle-management');
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

  void _showFeatureDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                feature,
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cette fonctionnalité sera bientôt disponible.',
                style: TextStyle(color: AppColors.textWeak),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GlassButton(
                    label: 'OK',
                    onPressed: () => Navigator.pop(context),
                    primary: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNavigation(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
      return;
    }

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
