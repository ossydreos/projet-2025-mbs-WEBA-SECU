import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart'; // Import du nouveau thème
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';
import 'package:my_mobility_services/widgets/authgate.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 3;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GlassBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const Authgate();
        }

        return GlassBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: GlassAppBar(
              title: 'Compte',
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                Expanded(child: _buildContent(user)),
                AdminBottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: _handleNavigation,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(User user) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(user),
            const SizedBox(height: 20),
            _buildUpdateAccountCard(),
            const SizedBox(height: 20),
            _buildAdminFeaturesCard(),
            const SizedBox(height: 20),
            _buildLogoutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(User user) {
    return SizedBox(
      // Correction ligne 111: Remplacer width par SizedBox
      width: double.infinity,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.accent.withOpacity(0.2),
              child: Icon(
                Icons.admin_panel_settings,
                size: 50,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName ?? user.email?.split('@')[0] ?? 'Administrateur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email ?? 'admin@example.com',
              style: TextStyle(fontSize: 16, color: AppColors.text),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent),
              ),
              child: Text(
                'ADMINISTRATEUR',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateAccountCard() {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, color: AppColors.accent, size: 24),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Mettez à jour vos informations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Gérez vos informations personnelles et vos préférences de compte.',
            style: TextStyle(fontSize: 14, color: AppColors.textWeak),
          ),
          const SizedBox(height: 16),
          GlassButton(
            label: 'Modifier le profil',
            icon: Icons.edit,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fonctionnalité à implémenter'),
                  backgroundColor: AppColors.accent,
                ),
              );
            },
            primary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminFeaturesCard() {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: AppColors.accent, size: 24),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Fonctionnalités administrateur',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAdminFeatureItem(
            icon: Icons.directions_car,
            title: 'Gestion de la flotte',
            subtitle: 'Gérer les véhicules disponibles',
            onTap: () =>
                Navigator.pushReplacementNamed(context, '/admin/gestion'),
          ),
          const SizedBox(height: 12),
          _buildAdminFeatureItem(
            icon: Icons.schedule,
            title: 'Réservations en attente',
            subtitle: 'Confirmer ou refuser les demandes',
            onTap: () => Navigator.pushReplacementNamed(context, '/admin/home'),
          ),
          const SizedBox(height: 12),
          _buildAdminFeatureItem(
            icon: Icons.local_offer,
            title: 'Codes promotionnels',
            subtitle: 'Créer et gérer les offres',
            onTap: () =>
                Navigator.pushReplacementNamed(context, '/admin/gestion'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassStroke, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 12),
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
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: AppColors.textWeak),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textWeak),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutCard() {
    // Correction ligne 331: Utilisation d'un Container séparé avec decoration personnalisée
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hot.withOpacity(0.3)),
        // Ajout de l'effet glassmorphism manuel
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.logout, color: AppColors.hot, size: 24),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Déconnexion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Se déconnecter de votre compte administrateur.',
            style: TextStyle(fontSize: 14, color: AppColors.textWeak),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _performLogout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.hot,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  void _performLogout() async {
    try {
      await _auth.signOut();
      print('Déconnexion admin réussie');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Authgate()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: AppColors.hot,
          ),
        );
      }
    }
  }

  void _handleNavigation(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/admin/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/admin/trajets');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/admin/gestion');
        break;
      case 3:
        break;
    }
  }
}
